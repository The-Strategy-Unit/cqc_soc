-- Admissions within 12 months of a MHA detention

-- Setup
DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_readmissions]
DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_readmissions_agg]

----## base table of spells and dates

Select distinct der_person_id, der_spell_id, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass,
CAST(YEAR(DATEADD(MONTH, -3, pseudo_EndDateMHActLegalStatusClass)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) AS fin_year,
dateadd(DAY,365,pseudo_EndDateMHActLegalStatusClass) as detend_plus_365
into #base
from [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full
where mha_spell_end_flag_final = 1
and AgeRepPeriodStart < 25
order by Der_Person_ID, der_spell_id, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass

----## Classification of some patient variables

SELECT a.*,
b.ICB23CD,
CASE
	WHEN [AgeRepPeriodStart] < 18 THEN CAST('0-17' AS varchar)
	WHEN [AgeRepPeriodStart] BETWEEN 18 AND 24 THEN CAST('18-24' AS varchar)
	ELSE NULL END AS age_group,
imd_2019_decile,
CASE
	WHEN b.[gender] = '1' THEN 'male'
	WHEN b.[gender] = '2' THEN 'female'
	ELSE NULL END AS gender,
CASE
	WHEN LEFT([EthnicCategory], 1) IN ('A','B','C') THEN 'white'
	WHEN LEFT([EthnicCategory], 1) IN ('D','E','F','G') THEN 'mixed'
	WHEN LEFT([EthnicCategory], 1) IN ('H','J','K','L') THEN 'asian'
	WHEN LEFT([EthnicCategory], 1) IN ('M','N','P') THEN 'black'
	WHEN LEFT([EthnicCategory], 1) IN ('R','S') THEN 'other'
	ELSE NULL END AS Ethnic_Category

INTO #1

FROM #base a
left outer join [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full AS b
on a.der_person_id = b.der_person_id
and a.der_spell_id = b.der_spell_id
and b.mha_spell_end_flag_final = 1


----## Getting readmissions

Select a.*,
x.HospProvSpellID, x.StartDateHospProvSpell, x.DischDateHospProvSpell,
CASE WHEN x.Der_person_ID IS NOT NULL THEN 1 ELSE 0 END AS readmissions_365_day

into [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions

from #1 a

LEFT OUTER JOIN(SELECT DISTINCT
                Der_person_ID,
                HospProvSpellID,
                StartDateHospProvSpell,
                DischDateHospProvSpell

                FROM [NHSE_MHSDS].[dbo].[MHS501HospProvSpell]
				where StartDateHospProvSpell is not NULL AND DischDateHospProvSpell is not NULL) AS x --completed admissions only

				on a.der_person_id = x.der_person_id
				and x.StartDateHospProvSpell between a.pseudo_EndDateMHActLegalStatusClass and a.detend_plus_365

WHERE a.pseudo_EndDateMHActLegalStatusClass BETWEEN '2019-04-01' AND '2023-03-31'

order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass, StartDateHospProvSpell, DischDateHospProvSpell, der_spell_id

---- ## addtional rule here to take out any admissions that happen after another re-detention has happened:
Select *
, LEAD(Der_Person_ID, 1, Der_Person_ID) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass, StartDateHospProvSpell, DischDateHospProvSpell, der_spell_id) as [lead_person_id]
, LEAD(pseudo_EndDateMHActLegalStatusClass, 1, pseudo_EndDateMHActLegalStatusClass) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass, StartDateHospProvSpell, DischDateHospProvSpell, der_spell_id) as [lead_det_end_date]
, LEAD(StartDateHospProvSpell, 1, StartDateHospProvSpell) over (order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass, StartDateHospProvSpell, DischDateHospProvSpell, der_spell_id) as [lead_adm_date]
into #2
from [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions
order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass, StartDateHospProvSpell, DischDateHospProvSpell, der_spell_id

Select *
, case
		when hospprovspellid is NULL then 0
		when der_person_id = lead_person_id AND lead_adm_date > lead_det_end_date then 0 else readmissions_365_day end as readmission_flag_final
into #3
from #2
order by Der_Person_ID, StartDateMHActLegalStatusClass, pseudo_EndDateMHActLegalStatusClass, StartDateHospProvSpell, DischDateHospProvSpell, der_spell_id

--## Now aggregating
SELECT ICB23CD,
fin_year,
gender, Ethnic_Category, imd_2019_decile, age_group,
count(distinct der_spell_id) as detentions,
sum(case when readmission_flag_final = 1 then 1 else 0 end) as readmissions

INTO [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions_agg

FROM #3

GROUP BY ICB23CD, fin_year, gender, Ethnic_Category, imd_2019_decile, age_group

--## clean up
DROP TABLE #base
DROP TABLE #1
DROP TABLE #2
DROP TABLE #3

--## full extract to take to R
SELECT *

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions_agg

ORDER BY ICB23CD, fin_year, gender, Ethnic_Category, imd_2019_decile, age_group