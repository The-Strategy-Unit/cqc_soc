-- Length of stay of a MHA detention spell
-- Details (for example age) can change during a spell, so have summed los by spell, then joined details from end of spell on afterwards

DROP TABLE IF EXISTS #lengthofstay

SELECT
der_spell_id,
SUM(pseudo_mha_ep_los) AS los

INTO #lengthofstay

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full

WHERE AgeRepPeriodStart < 25

GROUP BY der_spell_id

SELECT details.ICB23CD,
	CAST(YEAR(DATEADD(MONTH, -3, details.pseudo_EndDateMHActLegalStatusClass)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, details.pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) AS fin_year,
	CASE
		WHEN details.[AgeRepPeriodStart] < 18 THEN CAST('0-17' AS varchar)
		WHEN details.[AgeRepPeriodStart] BETWEEN 18 AND 24 THEN CAST('18-24' AS varchar)
		ELSE NULL END AS age_group,
	details.imd_2019_decile,
	CASE
		WHEN details.[gender] = '1' THEN 'male'
		WHEN details.[gender] = '2' THEN 'female'
		ELSE NULL END AS gender,
	CASE
		WHEN LEFT(details.[EthnicCategory], 1) IN ('A','B','C') THEN 'white'
		WHEN LEFT(details.[EthnicCategory], 1) IN ('D','E','F','G') THEN 'mixed'
		WHEN LEFT(details.[EthnicCategory], 1) IN ('H','J','K','L') THEN 'asian'
		WHEN LEFT(details.[EthnicCategory], 1) IN ('M','N','P') THEN 'black'
		WHEN LEFT(details.[EthnicCategory], 1) IN ('R','S') THEN 'other'
		ELSE NULL END AS Ethnic_Category,
	firstdetention.LegalStatusCode AS first_legal_status_code,
	details.LegalStatusCode AS last_legal_status_code,
	details.der_spell_id,
	los

FROM #lengthofstay AS los

INNER JOIN [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full AS details
	ON los.der_spell_id = details.der_spell_id
	AND details.mha_spell_end_flag_final = 1
	AND details.pseudo_EndDateMHActLegalStatusClass BETWEEN '2019-04-01' AND '2024-03-31'

LEFT JOIN [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full AS firstdetention
	ON los.der_spell_id = firstdetention.der_spell_id
	AND firstdetention.mha_spell_start_flag_final = 1

ORDER BY los DESC