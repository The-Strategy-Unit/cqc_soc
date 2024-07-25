/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_freqfly', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_freqfly; 

SELECT a.Der_Pseudo_Number
	  ,b.ICB23CD
	  ,b.ICB23NM
      ,a.dmicFinancialYear as [Der_Financial_Year]
      ,case when e.SG_SD is not NULL then 1 else 0 end as mh_call
	  ,count(distinct a.NHSE_GUID) as calls

into #1

  FROM [NHSE_111].[dbo].[111_Provider_Data] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.dmicLSOA_2011 = b.LSOA11CD

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[111_symptoms_mhflag] e
  on a.[Symptom_Group] = e.SG_SD

  where Call_Connect_Date between '2017-04-01' AND '2024-03-31' -- study period
  and left(dmicLSOA_2011,1) = 'E' --English patient only

  group by a.Der_Pseudo_Number
	  ,b.ICB23CD
	  ,b.ICB23NM
      ,a.dmicFinancialYear
      ,case when e.SG_SD is not NULL then 1 else 0 end

--Select top 10000 *
--	from #1

Select ICB23CD
	  ,ICB23NM
	  ,Der_Financial_Year
	  ,count(distinct der_pseudo_number) as all_pats
	  ,sum(calls) as all_calls
	  ,sum(case when mh_call = 1 then 1 else 0 end) as mh_pats
	  ,sum(case when mh_call = 1 then calls else 0 end) as mh_calls
	  ,sum(case when mh_call = 1 AND calls >= 5 then 1 else 0 end) as mh_freqfly
	  ,sum(case when mh_call = 1 AND calls >= 5 then calls else 0 end) as mh_freqfly_calls

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_freqfly
from #1

group by ICB23CD
	  ,ICB23NM
	  ,Der_Financial_Year

--drop table #1

Select *
	from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_freqfly
	order by ICB23CD, der_financial_year
