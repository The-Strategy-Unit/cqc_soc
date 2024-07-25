/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_111
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh; 

SELECT case
		when [AGE_AT_ACTIVITY_DATE] < 18 then cast('0-17' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 18 AND 21 then cast('18-21' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 22 AND 39 then cast('22-39' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 40 AND 64 then cast('40-64' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 65 AND 74 then cast('65-74' as varchar)
		when [AGE_AT_ACTIVITY_DATE] >= 75 then cast('75+' as varchar)
		else NULL end as age_group
      ,b.ICB23CD
	  ,b.ICB23NM
      ,d.[IMD_Decile]
	  ,g.ruralurban_class_2 as [rural_urban]
      ,case
		when [PERSON_STATED_GENDER_CODE] = '1' then 'male'
		when [PERSON_STATED_GENDER_CODE] = '2' then 'female'
		else NULL end as gender

	  ,case when [Symptom_Group] is NULL then 0
		when e.[mh_related] = 1 then 1
		else 0 end as mh_symptom
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end as mhsds_flag -- link to MHSDS for 'known' patients
      ,dmicFinancialYear as [Der_Financial_Year]
	  ,f.[MDS_Primary_Split]

	  ,count(*) as calls
      ,sum(case when [NHSE_GUID] is not NULL then 12 else 0 end) as cost

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh

  FROM [NHSE_111].[dbo].[111_Provider_Data] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.dmicLSOA_2011 = b.LSOA11CD

  left outer join (select distinct [Der_Pseudo_NHS_Number]
					FROM NHSE_MHSDS.dbo.MHS001MPI) c
  on a.Der_Pseudo_Number = c.Der_Pseudo_NHS_Number

  left outer join [NHSE_UKHF].[Demography].[vw_Index_Of_Multiple_Deprivation_By_LSOA1] d
  on a.dmicLSOA_2011 = d.LSOA_Code collate database_default

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[111_symptoms_mhflag] e
  on a.[Symptom_Group] = e.SG_SD

  left outer join [NHSE_Reference].[dbo].[tbl_Ref_Other_111_MDS_Disposition] f
  on a.[NHS_Pathways_final_disposition_(Dx)_code] = f.[Kc_Look_Up]

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[rural_urban_lsoa_2011] g
  on a.dmicLSOA_2011 = g.lsoa_2011_cd collate database_default

  where [Call_Connect_Date] between '2017-04-01' AND '2024-03-31' -- study period
  and AGE_AT_ACTIVITY_DATE < 115 --remove DQ ages
  and dmicCountry = 'England' --English patient only

  group by case
		when [AGE_AT_ACTIVITY_DATE] < 18 then cast('0-17' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 18 AND 21 then cast('18-21' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 22 AND 39 then cast('22-39' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 40 AND 64 then cast('40-64' as varchar)
		when [AGE_AT_ACTIVITY_DATE] between 65 AND 74 then cast('65-74' as varchar)
		when [AGE_AT_ACTIVITY_DATE] >= 75 then cast('75+' as varchar)
		else NULL end
      ,b.ICB23CD
	  ,b.ICB23NM
      ,d.[IMD_Decile]
	  ,g.ruralurban_class_2
      ,case
		when [PERSON_STATED_GENDER_CODE] = '1' then 'male'
		when [PERSON_STATED_GENDER_CODE] = '2' then 'female'
		else NULL end

	  ,case when [Symptom_Group] is NULL then 0
		when e.[mh_related] = 1 then 1
		else 0 end
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end -- link to MHSDS for 'known' patients
      ,dmicFinancialYear
	  ,f.[MDS_Primary_Split]

	  Select *
	  from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_111_mh