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

SELECT ICB23CD,
	CAST(YEAR(DATEADD(MONTH, -3, pseudo_EndDateMHActLegalStatusClass)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) AS fin_year,
	CASE
		WHEN [AgeRepPeriodStart] < 18 THEN CAST('0-17' AS varchar)
		WHEN [AgeRepPeriodStart] BETWEEN 18 AND 24 THEN CAST('18-24' AS varchar)
		ELSE NULL END AS age_group,
	imd_2019_decile,
	CASE
		WHEN [gender] = '1' THEN 'male'
		WHEN [gender] = '2' THEN 'female'
		ELSE NULL END AS gender,
	CASE
		WHEN LEFT([EthnicCategory], 1) IN ('A','B','C') THEN 'white'
		WHEN LEFT([EthnicCategory], 1) IN ('D','E','F','G') THEN 'mixed'
		WHEN LEFT([EthnicCategory], 1) IN ('H','J','K','L') THEN 'asian'
		WHEN LEFT([EthnicCategory], 1) IN ('M','N','P') THEN 'black'
		WHEN LEFT([EthnicCategory], 1) IN ('R','S') THEN 'other'
		ELSE NULL END AS Ethnic_Category,
	los

FROM #lengthofstay AS los

INNER JOIN [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full AS details
	ON los.der_spell_id = details.der_spell_id
	AND details.mha_spell_end_flag_final = 1
	AND pseudo_EndDateMHActLegalStatusClass BETWEEN '2019-04-01' AND '2024-03-31'