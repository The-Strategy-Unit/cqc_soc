-- Setup
DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_redetentions]
DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_redetentions_agg]

-- Getting redetentionsissions
SELECT 
	a.Der_person_ID, 
	der_spell_id, 
	StartDateMHActLegalStatusClass, 
	pseudo_EndDateMHActLegalStatusClass, 
	ICB23CD,
	CAST(YEAR(DATEADD(MONTH, -3, a.pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, a.pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) AS fin_year,
	b.der_spell_id2, 
	b.StartDateMHActLegalStatusClass2, 
	b.pseudo_EndDateMHActLegalStatusClass2,
	CASE WHEN b.Der_person_ID is not NULL THEN 1 ELSE 0 END AS redetentions_365_day, 
	gender, EthnicCategory, imd_2019_decile

INTO [NHSE_Sandbox_StrategyUnit].dbo.cqc_redetentions

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full AS a

LEFT OUTER JOIN(SELECT 
					Der_person_ID, 
					der_spell_id AS der_spell_id2, 
					StartDateMHActLegalStatusClass AS StartDateMHActLegalStatusClass2, 
					pseudo_EndDateMHActLegalStatusClass AS pseudo_EndDateMHActLegalStatusClass2

				FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full
				) b
	ON a.Der_person_ID = b.Der_person_ID
	AND DATEDIFF(dd, a.pseudo_EndDateMHActLegalStatusClass, b.StartDateMHActLegalStatusClass2) BETWEEN 0 AND 365

WHERE a.AgeRepPeriodStart < 25 -- Would this be right?
	AND a.mha_spell_end_flag_final = 1
	AND a.pseudo_EndDateMHActLegalStatusClass < '2023-04-01'

--## Now aggregating and making binary indicator for redetentionsission
SELECT 
	ICB23CD, 
	fin_year, 
	der_spell_id,
	gender, EthnicCategory, imd_2019_decile

INTO #1

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_redetentions

GROUP BY ICB23CD, fin_year, der_spell_id, gender, EthnicCategory, imd_2019_decile

SELECT
	ICB23CD, 
	fin_year, 
	der_spell_id,
	gender, EthnicCategory, imd_2019_decile, 
	SUM(CASE WHEN der_spell_id2 IS NULL THEN 0 ELSE 1 END) AS redetentions

INTO #2

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_redetentions

GROUP BY ICB23CD, fin_year, der_spell_id, gender, EthnicCategory, imd_2019_decile

SELECT 
	a.*, 
	CASE WHEN b.redetentions > 0 THEN 1 ELSE 0 END AS redetentions

INTO #3

FROM #1 a

LEFT OUTER JOIN #2 b
	ON a.ICB23CD = b.ICB23CD
	AND a.fin_year = b.fin_year
	AND a.der_spell_id = b.der_spell_id

SELECT 
	ICB23CD, 
	fin_year,
	gender, EthnicCategory, imd_2019_decile,
	COUNT(distinct der_spell_id) AS detentions,
	SUM(redetentions) AS redetentions

INTO [NHSE_Sandbox_StrategyUnit].dbo.cqc_redetentions_agg

FROM #3

GROUP BY ICB23CD, fin_year, gender, EthnicCategory, imd_2019_decile

ORDER BY ICB23CD, fin_year

--## clean up
DROP TABLE #1
DROP TABLE #2
DROP TABLE #3

--## full extract to take to R
SELECT *

FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_redetentions_agg

ORDER BY ICB23CD, fin_year

----## testing the (national) time series for scale and consistency
--SELECT 
--	fin_year, 
--	SUM(detentions) AS detentions, 
--	SUM(redetentions) AS redetentions,
--	SUM(CAST(redetentions AS FLOAT))/SUM(CAST(detentions AS FLOAT)) * 1.0

--FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_redetentions_agg

--GROUP BY fin_year

--ORDER BY fin_year