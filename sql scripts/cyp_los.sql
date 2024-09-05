SELECT
CAST(YEAR(DATEADD(MONTH, -3, pseudo_EndDateMHActLegalStatusClass)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, pseudo_EndDateMHActLegalStatusClass))AS VARCHAR) AS fin_year,
ICB23CD,
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
CASE
WHEN LegalStatusCode = '01' THEN 'Informal'
WHEN LegalStatusCode IN ('98', '99', 'XX', NULL) THEN 'Not known'
ELSE 'Formal' END AS legal_status,
mha_ep_los

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full

WHERE AgeRepPeriodStart < 25
AND mha_spell_end_flag_final = 1
AND pseudo_EndDateMHActLegalStatusClass BETWEEN '2019-04-01' AND '2024-03-31'