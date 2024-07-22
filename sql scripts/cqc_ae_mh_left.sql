USE NHSE_SUSPlus_Live
GO

IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_left', 'U') IS NOT NULL 
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_left; 

select b.ICB23CD
	  ,b.ICB23NM
      ,a.[Der_Financial_Year]
	  ,EC_Department_Type
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end as mh_snomed -- mh disorder-related snomed code yes or no
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end as mhsds_flag -- link to MHSDS for 'known' patients
	  ,count(*) as attends
	  ,sum(case when a.EC_Discharge_Status_SNOMED_CT in ('1066301000000103','1066321000000107','1066311000000101') then 1 else 0 end) as [left_b4_completion]

into [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_left
from [NHSE_SUSPlus_Live].[dbo].[tbl_Data_SUS_EC] a

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
  and EC_department_type not in ('02','2') -- exclude mono specialty

  group by b.ICB23CD
	  ,b.ICB23NM
      ,a.[Der_Financial_Year]
	  ,EC_Department_Type
      ,case when d.[term] is not NULL OR h.[term] is not NULL then 1 else 0 end
      ,case when c.[Der_Pseudo_NHS_Number] is not NULL then 1 else 0 end 

  select * from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_ae_mh_left