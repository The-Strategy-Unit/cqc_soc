-- Setup
DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_readmissions]
DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_readmissions_agg]

-- Getting readmissions
SELECT
a.Der_person_ID,
der_spell_id,
StartDateMHActLegalStatusClass,
pseudo_EndDateMHActLegalStatusClass,
ICB23CD,
CAST(YEAR(DATEADD(MONTH, -3, a.pseudo_EndDateMHActLegalStatusClass)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, a.pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) AS fin_year,
b.HospProvSpellID,
b.StartDateHospProvSpell,
b.DischDateHospProvSpell,
CASE WHEN b.Der_person_ID IS NOT NULL THEN 1 ELSE 0 END AS readmissions_365_day,
CASE
WHEN [AgeRepPeriodStart] < 18 THEN CAST('0-17' AS varchar)
WHEN [AgeRepPeriodStart] BETWEEN 18 AND 24 THEN CAST('18-24' AS varchar)
ELSE NULL END AS age_group,
imd_2019_decile,
CASE
WHEN a.[gender] = '1' THEN 'male'
WHEN a.[gender] = '2' THEN 'female'
ELSE NULL END AS gender,
CASE
WHEN LEFT([EthnicCategory], 1) IN ('A','B','C') THEN 'white'
WHEN LEFT([EthnicCategory], 1) IN ('D','E','F','G') THEN 'mixed'
WHEN LEFT([EthnicCategory], 1) IN ('H','J','K','L') THEN 'asian'
WHEN LEFT([EthnicCategory], 1) IN ('M','N','P') THEN 'black'
WHEN LEFT([EthnicCategory], 1) IN ('R','S') THEN 'other'
ELSE NULL END AS Ethnic_Category,
CASE
WHEN LegalStatusCode = '01' THEN 'Informal'
WHEN LegalStatusCode IN ('98', '99', 'XX', NULL) THEN 'Not known'
ELSE 'Formal' END AS legal_status,
ROW_NUMBER ( )  -- used later to remove duplication caused by
				-- (for example) if a spell is 3 months after detention 1 and 1 month after detention 2
    OVER (PARTITION BY a.Der_Person_ID, b.StartDateHospProvSpell ORDER BY a.StartDateMHActLegalStatusClass)  AS rownumber

INTO [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full AS a

LEFT OUTER JOIN(SELECT DISTINCT
                x.Der_person_ID,
                x.HospProvSpellID,
                x.StartDateHospProvSpell,
                x.DischDateHospProvSpell

                FROM [NHSE_MHSDS].[dbo].[MHS501HospProvSpell] AS x

					LEFT JOIN (--List of all start detention dates by person
						SELECT StartDateMHActLegalStatusClass, Der_person_ID
						FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full
						WHERE AgeRepPeriodStart < 25
							AND mha_spell_end_flag_final = 1
							) as y
						ON x.StartDateHospProvSpell = y.StartDateMHActLegalStatusClass
							AND x.Der_person_ID = y.Der_Person_ID

				WHERE y.StartDateMHActLegalStatusClass IS NULL -- Remove if admission is same day as a detention
					AND x.DischDateHospProvSpell IS NOT NULL
) b
ON a.Der_person_ID = b.Der_person_ID
AND DATEDIFF(dd, a.pseudo_EndDateMHActLegalStatusClass, b.StartDateHospProvSpell) BETWEEN 0 AND 365

WHERE a.AgeRepPeriodStart < 25
AND a.mha_spell_end_flag_final = 1
AND a.pseudo_EndDateMHActLegalStatusClass BETWEEN '2019-04-01' AND '2023-03-31'

--## Now aggregating and making binary indicator for redetention
SELECT
ICB23CD,
fin_year,
der_spell_id,
gender, Ethnic_Category, imd_2019_decile, age_group, legal_status

INTO #1

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions

GROUP BY ICB23CD, fin_year, der_spell_id, gender, Ethnic_Category, imd_2019_decile, age_group, legal_status

SELECT
ICB23CD,
fin_year,
der_spell_id,
gender, Ethnic_Category, imd_2019_decile, age_group, legal_status,
SUM(CASE WHEN HospProvSpellID IS NOT NULL AND rownumber = 1 THEN 1 ELSE 0 END) AS readmissions

INTO #2

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions

GROUP BY ICB23CD, fin_year, der_spell_id, gender, Ethnic_Category, imd_2019_decile, age_group, legal_status

SELECT
a.*,
CASE WHEN b.readmissions > 0  THEN b.readmissions ELSE 0 END AS readmissions

INTO #3

FROM #1 a

LEFT OUTER JOIN #2 b
ON a.ICB23CD = b.ICB23CD
AND a.fin_year = b.fin_year
AND a.der_spell_id = b.der_spell_id

SELECT
ICB23CD,
fin_year,
gender, Ethnic_Category, imd_2019_decile, age_group, legal_status,
COUNT(distinct der_spell_id) AS detentions,
SUM(readmissions) AS readmissions

INTO [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions_agg

FROM #3

GROUP BY ICB23CD, fin_year, gender, Ethnic_Category, imd_2019_decile, age_group, legal_status

ORDER BY ICB23CD, fin_year

--## clean up
DROP TABLE #1
DROP TABLE #2
DROP TABLE #3

--## full extract to take to R
SELECT *

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_readmissions_agg

ORDER BY ICB23CD, fin_year

