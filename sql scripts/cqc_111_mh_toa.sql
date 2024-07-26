USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_toa', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_toa; 

select b.ICB23CD
	  ,b.ICB23NM
      ,dmicFinancialYear as [Der_Financial_Year]
	  ,datepart(hh,Call_Connect_Time) as toa
      ,case when e.SG_SD is not NULL then 1 else 0 end as mh_snomed -- mh disorder-related snomed code yes or no
	  ,count(*) as attends
	  
into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_toa
from [NHSE_111].[dbo].[111_Provider_Data] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.dmicLSOA_2011 = b.lsoa11cd

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[111_symptoms_mhflag] e
  on a.[Symptom_Group] = e.SG_SD

    where [Call_Connect_Date] between '2017-04-01' AND '2024-03-31' -- study period
  and AGE_AT_ACTIVITY_DATE < 115 --remove DQ ages
  and dmicCountry = 'England' --English patient only

  group by b.ICB23CD
	  ,b.ICB23NM
      ,dmicFinancialYear
	  ,datepart(hh,Call_Connect_Time)
      ,case when e.SG_SD is not NULL then 1 else 0 end 

  select * from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_toa