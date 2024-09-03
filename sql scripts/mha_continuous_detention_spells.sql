USE NHSE_MHSDS
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full; 

----## find a complex patient to test on

--Select der_person_id, count(distinct UniqMHActEpisodeID) as MHA_eps
--from [NHSE_MHSDS].[dbo].[MHS401MHActPeriod]
--where StartDateMHActLegalStatusClass between '2022-04-01' AND '2023-03-31'
--group by der_person_id
--order by MHA_eps desc

----## 'Live' records from DB
SELECT [MHS401UniqID]
      ,[Person_ID]
      ,[OrgIDProv]
      ,[UniqSubmissionID]
      ,[UniqMonthID]
      ,[RecordNumber]
      ,[RowNumber]
      ,[MHActLegalStatusClassPeriodId]
      ,[StartDateMHActLegalStatusClass]
      ,[StartTimeMHActLegalStatusClass]
      ,[LegalStatusClassPeriodStartReason]
      ,[ExpiryDateMHActLegalStatusClass]
      ,[ExpiryTimeMHActLegalStatusClass]
      ,[EndDateMHActLegalStatusClass]
      ,[EndTimeMHActLegalStatusClass]
      ,[LegalStatusClassPeriodEndReason]
      ,[LegalStatusCode]
      ,[MentalCat]
      ,[UniqMHActEpisodeID]
      ,[RecordStartDate]
      ,[RecordEndDate]
      ,[NHSDLegalStatus]
      ,[InactTimeMHAPeriod]
      ,[NHSEUniqSubmissionID]
      ,[Effective_From]
      ,[Der_Person_ID]
 
 into #1
 FROM [NHSE_MHSDS].[dbo].[MHS401MHActPeriod]

  where Effective_From is not NULL --'live' records only
  and StartDateMHActLegalStatusClass >= '2005-01-01' -- detentions last 20 years only
  and (ExpiryDateMHActLegalStatusClass is not NULL OR EndDateMHActLegalStatusClass is not NULL) -- must have an end or expiry date
  and (left(ExpiryDateMHActLegalStatusClass,4) != '9999' AND left(EndDateMHActLegalStatusClass,4) != '9999' )  -- both invalid expiry/end dates

  --select * from #1 order by UniqMHActEpisodeID,StartDateMHActLegalStatusClass, RecordNumber, MHS401UniqID --check what data looks like

  ----## Step to remove duplicates where multiple start and end dates

Select a.*
into #1b 
from #1 a
inner join(
		select der_person_id, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass, max(MHS401UniqID) as max_uniqid
		from #1
		group by der_person_id, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass
		) b
	on a.der_person_id = b.der_person_id
	and a.StartDateMHActLegalStatusClass = b.StartDateMHActLegalStatusClass
	and a.MHS401UniqID = b.max_uniqid

  ----## Assign row numbers to records in each distinct MHA episode
  select *
  ,ROW_NUMBER() over (PARTITION BY UniqMHActEpisodeID ORDER BY NHSEUniqSubmissionID desc) as rownum
  into #2
  from #1b
  order by UniqMHActEpisodeID,StartDateMHActLegalStatusClass, RecordNumber, MHS401UniqID

   -- select top 1000 * from #2 order by UniqMHActEpisodeID, rownum desc --check what data looks like

 ----## Calculate max number of records and fill in NULL end dates
Select a.*,
b.max_rownum,
case when EndDateMHActLegalStatusClass is NULL then ExpiryDateMHActLegalStatusClass else EndDateMHActLegalStatusClass end as pseudo_enddate
into #3
from #2 a
left outer join (select UniqMHActEpisodeID, max(rownum) as max_rownum
						from #2
						group by UniqMHActEpisodeID) b
			on a.UniqMHActEpisodeID = b.UniqMHActEpisodeID

 --select top 1000 * from #3 where rownum = 1 order by startdateMHActLegalStatusClass, pseudo_enddate, rownum desc --check what filtered data looks like

 ----## Trim superfluous fields, add lag variables to aid flagging of consecutive mha episodes
 Select mhs401UniqID, UniqMHActEpisodeID, Person_ID, Der_Person_ID, OrgIDProv, RecordNumber
 , StartDateMHActLegalStatusClass, ExpiryDateMHActLegalStatusClass, EndDateMHActLegalStatusClass, pseudo_enddate
 , case when datediff(dd, StartDateMHActLegalStatusClass, pseudo_enddate) = 0 then 0.5 else datediff(dd, StartDateMHActLegalStatusClass, pseudo_enddate) end as mha_ep_los
 , LegalStatusClassPeriodStartReason, LegalStatusClassPeriodEndReason, LegalStatusCode
 , LAG(Der_Person_ID, 1, Der_Person_ID) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass) as [lag_person_id]
, LAG(OrgIDProv, 1, OrgIDProv) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass) as [lag_orgidprov]
, LAG(StartDateMHActLegalStatusClass, 1, StartDateMHActLegalStatusClass) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass) as [lag_startdate]
, LAG(pseudo_enddate, 1, pseudo_enddate) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass) as [lag_enddate]
, LEAD(StartDateMHActLegalStatusClass, 1, StartDateMHActLegalStatusClass) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass) as [lead_startdate]
, LEAD(Der_Person_ID, 1, Der_Person_ID) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, EndDateMHActLegalStatusClass) as [lead_person_id]

into #4
from #3
where rownum = 1 
order by startdateMHActLegalStatusClass, pseudo_enddate

----## Identify isolated and connected MHA episodes, add consecutive ID for episodes (proxy for patient spell)
Select *
, ROW_NUMBER() over (PARTITION BY der_person_id ORDER BY startdateMHActLegalStatusClass, pseudo_enddate) as pat_row_id 
, case
	when der_person_id != [lag_person_id] then 1
	when der_person_id = [lag_person_id] AND startdateMHActLegalStatusClass > lag_enddate then 1 else 0 end as mha_spell_start_flag
	
, case
	when der_person_id = [lead_person_id] AND pseudo_enddate < lead_startdate then 1
	when der_person_id != [lead_person_id] then 1 else 0 end as mha_spell_end_flag
, case when der_person_id = [lag_person_id] AND startdateMHActLegalStatusClass = lag_enddate then 1 else 0 end as mha_cds_flag

into #5
from #4
order by startdateMHActLegalStatusClass, enddateMHActLegalStatusClass, pseudo_enddate

--select top 1000 * from #5 order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_enddate

Select *
,row_number() over (order by der_person_id, pat_row_id) as global_row_id
into #5b
from #5

----## Correct for weirdness of lag/lead:-) and re-do zero los for in-spell episodes - THIS IS THE MAIN TABLE OF DATA NOW
declare @maxid bigint
set @maxid = (select max(global_row_id) from #5b)

Select *
,case when mha_spell_start_flag = 0 and mha_cds_flag = 0 then 1 else mha_cds_flag end as mha_cds_flag2
,case when mha_spell_start_flag = 0 and mha_ep_los = 0.5 then 0 else mha_ep_los end as adj_mha_ep_los
,case when global_row_id = 1 then 1 else mha_spell_start_flag end as mha_spell_start_flag_final
,case when global_row_id = @maxid then 1 else mha_spell_end_flag end as mha_spell_end_flag_final
into #6
from #5b

--select * from #6 order by Der_Person_ID, pat_row_id

----## detecting initiating row id
select *,row_number() over (partition by der_person_id order by startdateMHActLegalStatusClass,pseudo_enddate) as [row]
into #7
from #6
where mha_spell_start_flag_final=1 OR (mha_spell_start_flag_final=0 AND mha_spell_end_flag_final = 1)

select a.*
,case when a.mha_spell_start_flag_final = 1 AND a.mha_spell_end_flag_final = 1 then a.[pat_row_id] else b.[pat_row_id] end as [end_rowid] 
into #8
from #7 A 
left outer join #7 B
on A.Der_Person_ID = b.Der_Person_ID
and
A.[row]+1=b.[row]

----## now remove non-start spell rows
select *
into #9
from #8
where mha_spell_start_flag_final = 1

--select * from #9 order by der_person_id, pat_row_id

----## join base table to spell start and end rowid's
select a.*, b.pat_row_id as spell_pat_row_id
into #10
from #6 a
left outer join #9 b
on a.Der_Person_ID = b.Der_Person_ID
and a.pat_row_id between b.pat_row_id and b.end_rowid

order by Der_Person_ID, a.pat_row_id

----## Linking to MPI for age, gender, ethnic category, ICB and hard save to file

Select a.*
,z.spell_pat_row_id
,a.Der_Person_ID + '_0000' + cast(z.spell_pat_row_id as varchar) as der_spell_id
,b.AgeRepPeriodStart, b.EthnicCategory, b.Gender, b.LSOA2011
,c.IndexofMultipleDeprivationIMDDecile as imd_2019_decile
,d.ICB23CD, d.ICB23NM
into #11
from #6 a
left outer join #10 z
on a.Der_Person_ID = z.Der_Person_ID
and a.pat_row_id = z.pat_row_id
left outer join [dbo].[MHS001MPI] b
on a.Der_Person_ID = b.Der_Person_ID
and a.RecordNumber = b.RecordNumber
left outer join [NHSE_Sandbox_Spec_Neurology].[dbo].[RefIMD2019] c
on b.LSOA2011 = c.LSOAcode2011 collate database_default
left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] d
on b.LSOA2011 = d.lsoa11cd collate database_default

order by Der_Person_ID, pat_row_id

select MHS401UniqID, UniqMHActEpisodeID, Person_ID, Der_Person_ID, RecordNumber, OrgIDProv, der_spell_id
, StartDateMHActLegalStatusClass, ExpiryDateMHActLegalStatusClass, pseudo_enddate as pseudo_EndDateMHActLegalStatusClass
, pat_row_id, global_row_id, spell_pat_row_id, mha_spell_start_flag_final, mha_spell_end_flag_final, adj_mha_ep_los as mha_ep_los
, LegalStatusCode, LegalStatusClassPeriodStartReason, LegalStatusClassPeriodEndReason
, AgeRepPeriodStart, EthnicCategory, gender, imd_2019_decile, ICB23CD, ICB23NM
into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full
from #11

----## Clean up session
drop table #1
drop table #1b
drop table #2
drop table #3
drop table #4
drop table #5
drop table #5b
drop table #6
drop table #7
drop table #8
drop table #9
drop table #10
drop table #11

----## quick check of records within age boundary

--Select a.*
--from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full a
--inner join (
--		Select distinct der_person_id
--		from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full
--		where AgeRepPeriodStart < 25) b
--on a.Der_Person_ID = b.Der_Person_ID

--order by a.Der_Person_ID, pat_row_id