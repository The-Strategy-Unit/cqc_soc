USE NHSE_MHSDS
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess; 

----## Person spell, start and end dates (for assessment scores)
Select der_person_id, der_spell_id, count(*) as episodes
, min(StartDateMHActLegalStatusClass) as spell_start_date
, max(pseudo_EndDateMHActLegalStatusClass) as spell_end_date
into #1
from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full
where AgeRepPeriodStart < 25
group by der_person_id, der_spell_id
order by der_person_id, der_spell_id

--select top 1000 * from #1 order by Der_Person_ID, der_spell_id

----61692 spell rows

----# pick a person for testing
--select top 100 * from #1
--order by Der_Person_ID, spell_start_date, spell_end_date

----## all CYP patients from MHA episodes and all their assessments
Select a.*
into #2a
from [NHSE_MHSDS].[dbo].[MHS607CodedScoreAssessmentAct] a
inner join(
		select distinct der_person_id
		from #1
		--where Der_Person_ID = '016XUUZDCSCNIDG' -- comment out line once sure this works!
		) b
		on a.Der_Person_ID = b.Der_Person_ID

---- 6,268,591 assessment rows

--select top 1000 * from #2a order by der_person_id, RecordNumber, Effective_From

----## dating the assessments

select a.*, b.CareContDate
into #2b
from #2a a
inner join [NHSE_MHSDS].[dbo].[MHS201CareContact] b
	on a.Der_Person_ID = b.Der_Person_ID
	and a.UniqServReqID = b.UniqServReqID
	and a.RecordNumber = b.RecordNumber
	and a.UniqCareContID = b.UniqCareContID

--select top 1000 * from #2b order by der_person_id, RecordNumber, CareContDate

----## assessments during MHA spells
select a.*, b.RecordNumber, b.UniqServReqID, b.UniqCareActID, b.UniqCareContID, b.CodedAssToolType, b.PersScore
,b.CareContDate
, row_number () over (partition by a.der_person_id, a.der_spell_id, codedasstooltype, carecontdate order by uniqcarecontid) as assess_row
into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess
from #1 a
inner join #2b b
on a.Der_Person_ID = b.Der_Person_ID
and b.CareContDate between a.spell_start_date AND a.spell_end_date

---- 2,186,872 rows (some duplicates with different record numbers and/or contact ID - can filter on assess_row = 1 for truly distinct)

----## codes used during MHA spells
select CodedAssToolType, count(*) as freq
from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess
where assess_row = 1
group by CodedAssToolType
order by freq desc

----## clean up
drop table #1
drop table #2a
drop table #2b