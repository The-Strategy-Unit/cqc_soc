/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_111
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_symp', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_symp; 

SELECT b.ICB23CD
	  ,b.ICB23NM
	  ,dmicFinancialYear as [Der_Financial_Year]
	  ,e.[SG_SD_description]
	  ,count(distinct Der_Pseudo_Number) as pats
	  ,count(distinct [NHSE_GUID]) as calls

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_symp

  FROM [NHSE_111].[dbo].[111_Provider_Data] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.dmicLSOA_2011 = b.LSOA11CD

  inner join [NHSE_Sandbox_StrategyUnit].[dbo].[111_symptoms_mhflag] e
  on a.[Symptom_Group] = e.SG_SD
  and e.mh_related = 1

  where [Call_Connect_Date] between '2017-04-01' AND '2021-03-31' -- study period
  and AGE_AT_ACTIVITY_DATE < 115 --remove DQ ages
  and dmicCountry = 'England' --English patient only

  group by b.ICB23CD
	  ,b.ICB23NM
	  ,dmicFinancialYear
	  ,e.[SG_SD_description]

Select *
from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh_symp
order by ICB23CD, sg_sd_description, Der_Financial_Year