/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_diag', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_diag; 

SELECT b.ICB23CD
	  ,b.ICB23NM
      ,a.[Der_Financial_Year]
	  ,a.EC_Department_Type
	  ,g.EC_Diagnosis_01
	  ,count(distinct der_pseudo_nhs_number) as pats
	  ,count(distinct a.[EC_Ident]) as attends

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_diag

  FROM [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SUS_EC] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.Der_Postcode_LSOA_2011_Code = b.LSOA11CD

  left outer join [dbo].[tbl_Data_SUS_EC_Diagnosis] g
  on a.ec_ident = g.ec_ident
  and a.der_financial_year = g.der_financial_year

  inner join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_mh_snomed_ct] h
  on g.EC_Diagnosis_01 = h.[conceptId]

  where Finished_Indicator = 1 -- concluded attendance only
  and Arrival_Date between '2019-04-01' AND '2024-03-31' -- study period
  and Age_At_Arrival < 115 --remove DQ ages
  and EC_AttendanceCategory in ('1','2','3') -- unplanned only
  and [Der_Dupe_Flag] = 0 -- exclude any duplicate records
  and left(Der_Postcode_LSOA_2011_Code,1) = 'E' --English patient only
  and EC_department_type not in ('02','2') -- exclude mono specialty
  and h.[keep] = 1 -- only MH diagnosis

  group by b.ICB23CD
	  ,b.ICB23NM
      ,a.[Der_Financial_Year]
	  ,a.EC_Department_Type
	  ,g.EC_Diagnosis_01

Select *
	from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_diag
	order by ICB23CD, EC_Diagnosis_01, Der_Financial_Year
