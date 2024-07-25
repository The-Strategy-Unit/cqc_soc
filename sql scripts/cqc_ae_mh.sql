/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh; 

SELECT case
		when [Age_At_Arrival] < 18 then cast('0-17' as varchar)
		when [Age_At_Arrival] between 18 AND 21 then cast('18-21' as varchar)
		when [Age_At_Arrival] between 20 AND 34 then cast('22-39' as varchar)
		when [Age_At_Arrival] between 35 AND 59 then cast('40-64' as varchar)
		when [Age_At_Arrival] between 60 AND 74 then cast('65-74' as varchar)
		when [Age_At_Arrival] >= 75 then cast('75+' as varchar)
		else NULL end as age_group
      ,b.ICB23CD
	  ,b.ICB23NM
      ,[Index_Of_Multiple_Deprivation_Decile]
      ,f.ruralurban_class_2 as rural_urban
      ,case
		when a.[Sex] = '1' then 'male'
		when a.[Sex] = '2' then 'female'
		else NULL end as gender
      ,case
		when left([Ethnic_Category],1) in ('A','B','C') then 'white'
		when left([Ethnic_Category],1) in ('D','E','F','G') then 'mixed'
		when left([Ethnic_Category],1) in ('H','J','K','L') then 'asian'
		when left([Ethnic_Category],1) in ('M','N','P') then 'black'
		when left([Ethnic_Category],1) in ('R','S') then 'other'
		else NULL end as ethnic_category
      ,[EC_Department_Type]
      ,case
		when [EC_Arrival_Mode_SNOMED_CT] = '1048071000000103' then 'own_tran'
		when [EC_Arrival_Mode_SNOMED_CT] in ('1048031000000100','1048041000000109','1048021000000102','1048051000000107','1048081000000101') then 'amb_tran'
		when [EC_Arrival_Mode_SNOMED_CT] = '1048061000000105' then 'pub_tran'
		else NULL end as arrival_mode
      ,case when [EC_Decision_To_Admit_Date] is not NULL then cast('1' as varchar) else cast('0' as varchar) end as admit_decision
      ,case
		when [Discharge_Destination_SNOMED_CT] = '306689006' then 'home'
		when [Discharge_Destination_SNOMED_CT] in ('306689006','1066331000000109') then 'ward'
		when [Discharge_Destination_SNOMED_CT] = '1066341000000100' then 'sdec'
		else 'other' end as disch_dest
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end as mh_snomed -- mh disorder-related snomed code yes or no
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end as mhsds_flag -- link to MHSDS for 'known' patients
      ,a.[Der_Financial_Year]

	  ,count(distinct a.[EC_Ident]) as attends
      ,sum(case when [SUS_Final_Price] = 0 OR [SUS_Final_Price] is NULL then 86 else [SUS_Final_Price] end) as cost

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh

  FROM [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SUS_EC] a

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_LSOA2011_to_ICB2023] b
  on a.Der_Postcode_LSOA_2011_Code = b.LSOA11CD

  left outer join (select distinct [Der_Pseudo_NHS_Number]
					FROM NHSE_MHSDS.dbo.MHS001MPI) c
  on a.Der_Pseudo_NHS_Number = c.Der_Pseudo_NHS_Number

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_mh_snomed_ct] d
  on a.EC_Chief_Complaint_SNOMED_CT = d.[conceptId]
  and d.[keep] = 1

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_mh_snomed_ct] e
  on a.EC_Chief_Complaint_SNOMED_CT = e.[id]
  and e.[keep] = 1
  
  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[rural_urban_lsoa_2011] f
  on a.Der_Postcode_LSOA_2011_Code = f.lsoa_2011_cd collate database_default

  left outer join [dbo].[tbl_Data_SUS_EC_Diagnosis] g
  on a.ec_ident = g.ec_ident
  and a.der_financial_year = g.der_financial_year

  left outer join [NHSE_Sandbox_StrategyUnit].[dbo].[ref_mh_snomed_ct] h
  on g.EC_Diagnosis_01 = h.[conceptId]
  and h.[keep] = 1

  where Finished_Indicator = 1 -- concluded attendance only
  and Arrival_Date between '2019-04-01' AND '2024-03-31' -- study period
  and Age_At_Arrival < 115 --remove DQ ages
  and EC_AttendanceCategory in ('1','2','3') -- unplanned only
  and [Der_Dupe_Flag] = 0 -- exclude any duplicate records
  and left(Der_Postcode_LSOA_2011_Code,1) = 'E' --English patient only

  group by case
		when [Age_At_Arrival] < 18 then cast('0-17' as varchar)
		when [Age_At_Arrival] between 18 AND 21 then cast('18-21' as varchar)
		when [Age_At_Arrival] between 20 AND 34 then cast('22-39' as varchar)
		when [Age_At_Arrival] between 35 AND 59 then cast('40-64' as varchar)
		when [Age_At_Arrival] between 60 AND 74 then cast('65-74' as varchar)
		when [Age_At_Arrival] >= 75 then cast('75+' as varchar)
		else NULL end
      ,b.ICB23CD
	  ,b.ICB23NM
      ,[Index_Of_Multiple_Deprivation_Decile]
      ,f.ruralurban_class_2
      ,case
		when a.[Sex] = '1' then 'male'
		when a.[Sex] = '2' then 'female'
		else NULL end
      ,case
		when left([Ethnic_Category],1) in ('A','B','C') then 'white'
		when left([Ethnic_Category],1) in ('D','E','F','G') then 'mixed'
		when left([Ethnic_Category],1) in ('H','J','K','L') then 'asian'
		when left([Ethnic_Category],1) in ('M','N','P') then 'black'
		when left([Ethnic_Category],1) in ('R','S') then 'other'
		else NULL end
      ,[EC_Department_Type]
      ,case
		when [EC_Arrival_Mode_SNOMED_CT] = '1048071000000103' then 'own_tran'
		when [EC_Arrival_Mode_SNOMED_CT] in ('1048031000000100','1048041000000109','1048021000000102','1048051000000107','1048081000000101') then 'amb_tran'
		when [EC_Arrival_Mode_SNOMED_CT] = '1048061000000105' then 'pub_tran'
		else NULL end
      ,case when [EC_Decision_To_Admit_Date] is not NULL then cast('1' as varchar) else cast('0' as varchar) end
      ,case
		when [Discharge_Destination_SNOMED_CT] = '306689006' then 'home'
		when [Discharge_Destination_SNOMED_CT] in ('306689006','1066331000000109') then 'ward'
		when [Discharge_Destination_SNOMED_CT] = '1066341000000100' then 'sdec'
		else 'other' end
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end
      ,a.[Der_Financial_Year]


Select *
from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh
