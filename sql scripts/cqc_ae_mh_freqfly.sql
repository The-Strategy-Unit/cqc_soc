/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_freqfly', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_freqfly; 

SELECT a.Der_Pseudo_NHS_Number
	  ,b.ICB23CD
	  ,b.ICB23NM
      ,a.[Der_Financial_Year]
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end as mh_attend
	  ,count(distinct a.[EC_Ident]) as attends

into #1

  FROM [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SUS_EC] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.Der_Postcode_LSOA_2011_Code = b.lsoa11cd

  left outer join (select distinct [Der_Pseudo_NHS_Number]
					FROM NHSE_MHSDS.dbo.MHS001MPI) c
  on a.Der_Pseudo_NHS_Number = c.Der_Pseudo_NHS_Number

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_mh_snomed_ct] d
  on a.EC_Chief_Complaint_SNOMED_CT = d.[conceptId]
  and d.[keep] = 1

  left outer join [dbo].[tbl_Data_SUS_EC_Diagnosis] g
  on a.ec_ident = g.ec_ident
  and a.der_financial_year = g.der_financial_year

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_mh_snomed_ct] h
  on g.EC_Diagnosis_01 = h.[conceptId]

  where Finished_Indicator = 1 -- concluded attendance only
  and Arrival_Date between '2019-04-01' AND '2024-03-31' -- study period
  and Age_At_Arrival < 115 --remove DQ ages
  and EC_AttendanceCategory in ('1','2','3') -- unplanned only
  and [Der_Dupe_Flag] = 0 -- exclude any duplicate records
  and left(Der_Postcode_LSOA_2011_Code,1) = 'E' --English patient only
  and EC_department_type not in ('02','2') -- exclude mono specialty

  group by a.Der_Pseudo_NHS_Number
	  ,b.ICB23CD
	  ,b.ICB23NM
      ,a.[Der_Financial_Year]
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end

--	Select top 10000 *
--	from #1

Select ICB23CD
	  ,ICB23NM
	  ,Der_Financial_Year
	  ,count(distinct der_pseudo_nhs_number) as all_pats
	  ,sum(attends) as all_attends
	  ,sum(case when mh_attend = 1 then 1 else 0 end) as mh_pats
	  ,sum(case when mh_attend = 1 then attends else 0 end) as mh_attends
	  ,sum(case when mh_attend = 1 AND attends >= 5 then 1 else 0 end) as mh_freqfly
	  ,sum(case when mh_attend = 1 AND attends >= 5 then attends else 0 end) as mh_freqfly_attends
into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_freqfly
from #1

group by ICB23CD
	  ,ICB23NM
	  ,Der_Financial_Year

drop table #1

Select *
	from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_freqfly
	order by ICB23CD, der_financial_year
