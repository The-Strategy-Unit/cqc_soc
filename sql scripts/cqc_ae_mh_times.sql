/****** Script for SelectTopNRows command from SSMS  ******/
USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_times', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_times; 

SELECT b.ICB23CD
	  ,b.ICB23NM
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end as mh_snomed -- mh disorder-related snomed code yes or no
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end as mhsds_flag -- link to MHSDS for 'known' patients
      ,a.[Der_Financial_Year]
	  ,sum(case when EC_Initial_Assessment_Time_Since_Arrival between 0 and 1440 then 1 else 0 end) as assess_attends
	  ,sum(case when EC_Initial_Assessment_Time_Since_Arrival between 0 and 1440 then EC_Initial_Assessment_Time_Since_Arrival else 0 end) as assess_time_total
	  ,sum(case when EC_Seen_For_Treatment_Time_Since_Arrival between 0 and 1440 then 1 else 0 end) as treat_attends
	  ,sum(case when EC_Seen_For_Treatment_Time_Since_Arrival between 0 and 1440 then [EC_Seen_For_Treatment_Time_Since_Arrival] else 0 end) as treat_time_total
	  ,sum(case when EC_Conclusion_Time_Since_Arrival between 0 and 1440 then 1 else 0 end) as conclude_attends
	  ,sum(case when EC_Conclusion_Time_Since_Arrival between 0 and 1440 then EC_Conclusion_Time_Since_Arrival else 0 end) as conclude_time_total
	  ,sum(case when EC_Departure_Time_Since_Arrival between 0 and 1440 then 1 else 0 end) as depart_attends
	  ,sum(case when EC_Departure_Time_Since_Arrival between 0 and 1440 then [EC_Departure_Time_Since_Arrival] else 0 end) as depart_time_total
	  ,sum(case when EC_Decision_To_Admit_Time_Since_Arrival between 0 and 1440 then 1 else 0 end) as decadm_attends
      ,sum(case when EC_Decision_To_Admit_Time_Since_Arrival between 0 and 1440 then [EC_Decision_To_Admit_Time_Since_Arrival] else 0 end) as decadm_time_total

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_times

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
  and h.[keep] = 1

  where Finished_Indicator = 1 -- concluded attendance only
  and Arrival_Date between '2019-04-01' AND '2024-03-31' -- study period
  and Age_At_Arrival < 115 --remove DQ ages
  and arrival_planned = 'False' -- unplanned only
  and [Der_Dupe_Flag] = 0 -- exclude any duplicate records
  and left(Der_Postcode_LSOA_2011_Code,1) = 'E' --English patient only
  and EC_department_type in ('01','1') -- ED only
  -- and ec_discharge_status_snomed_ct in ('182992009','1077781000000101') -- completed ed pathway only
  -- 1077041000000107 = streamed to MH service after assessment
  and Discharge_Destination_SNOMED_CT != '1066331000000109' -- exclude those admitted to short stay ED ward

  group by b.ICB23CD
	  ,b.ICB23NM
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end
      ,a.[Der_Financial_Year]

Select *
	from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_times
	order by ICB23CD, mh_snomed, mhsds_flag, der_financial_year
