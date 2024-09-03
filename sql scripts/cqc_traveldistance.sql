-- Setup
	DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_HH_traveldistance]
	DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_HH_traveldistance_clean]
	DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_HH_traveldistance_calculations]

--Data Quality Check
	SELECT COUNT(*) - COUNT(WardLocDistanceHome) AS null_count
	FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_ward_dist_full;
	--55917

	SELECT
		WardLocDistanceHome,
		COUNT(*) AS occurrence_count
	FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_ward_dist_full
	GROUP BY WardLocDistanceHome
	Order by WardLocDistanceHome
	--NULL	55917
	--0	12029
	-- of 334056 records

--CLEANING
--Reducing to one record per event
	SELECT *
		, row_number() over (partition by der_person_id, uniqhospprovspellid
							 order by startdatewardstay, mhs502uniqid)
							 as order_in_spell
		INTO #1
		FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_ward_dist_full

	SELECT COUNT(*)
		--INTO [NHSE_Sandbox_StrategyUnit].[dbo].cqc_HH_traveldistance
		FROM #1
		WHERE order_in_spell = 1
	--gives 199501 results
	--when the null distances are dropped the count goes down to 168,846

	SELECT *
		INTO [NHSE_Sandbox_StrategyUnit].[dbo].cqc_HH_traveldistance
		FROM #1
		WHERE order_in_spell = 1

--CHECKING
SELECT COUNT(*)
	FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_HH_traveldistance

--Working version
SELECT
	ICB23CD,
	ICB23NM,
 -- UniqHospProvSpellID,
	Der_Person_ID,
    CAST(YEAR(DATEADD(MONTH, -3, EndDateWardStay)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, EndDateWardStay))AS VARCHAR) AS fin_year,
    CASE
        WHEN [AgeRepPeriodStart] < 18 THEN CAST('0-17' AS varchar)
        WHEN [AgeRepPeriodStart] BETWEEN 18 AND 24 THEN CAST('18-24' AS varchar)
        ELSE NULL END AS age_group,
    imd_2019_decile,
    CASE
        WHEN [Gender] = '1' THEN 'male'
        WHEN [Gender] = '2' THEN 'female'
        ELSE NULL END AS gender_desc,
    CASE
        WHEN LEFT([EthnicCategory], 1) IN ('A','B','C') THEN 'white'
        WHEN LEFT([EthnicCategory], 1) IN ('D','E','F','G') THEN 'mixed'
        WHEN LEFT([EthnicCategory], 1) IN ('H','J','K','L') THEN 'asian'
        WHEN LEFT([EthnicCategory], 1) IN ('M','N','P') THEN 'black'
        WHEN LEFT([EthnicCategory], 1) IN ('R','S') THEN 'other'
        ELSE NULL END AS Ethnic_Category,
	WardLocDistanceHome

INTO [NHSE_Sandbox_StrategyUnit].dbo.cqc_HH_traveldistance_clean

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_HH_traveldistance

WHERE
   WardLocDistanceHome IS NOT NULL
   and order_in_spell = 1

GROUP BY
	ICB23CD,
	ICB23NM,
	Der_Person_ID,
    --UniqHospProvSpellID,
    CAST(YEAR(DATEADD(MONTH, -3, EndDateWardStay)) AS VARCHAR) + '-' + CAST(YEAR(DATEADD(MONTH, 9, EndDateWardStay))AS VARCHAR),
    CASE
        WHEN [AgeRepPeriodStart] < 18 THEN CAST('0-17' AS varchar)
        WHEN [AgeRepPeriodStart] BETWEEN 18 AND 24 THEN CAST('18-24' AS varchar)
        ELSE NULL END,
    imd_2019_decile,
    CASE
        WHEN [Gender] = '1' THEN 'male'
        WHEN [Gender] = '2' THEN 'female'
        ELSE NULL END,
    CASE
        WHEN LEFT([EthnicCategory], 1) IN ('A','B','C') THEN 'white'
        WHEN LEFT([EthnicCategory], 1) IN ('D','E','F','G') THEN 'mixed'
        WHEN LEFT([EthnicCategory], 1) IN ('H','J','K','L') THEN 'asian'
        WHEN LEFT([EthnicCategory], 1) IN ('M','N','P') THEN 'black'
        WHEN LEFT([EthnicCategory], 1) IN ('R','S') THEN 'other'
        ELSE NULL END,
	WardLocDistanceHome

--ORDER BY
	--mean_distance,
	--wardstay_count DESC

--## Aggregate tables for extracts
--Gender by year and ICB
SELECT
	ICB23CD, ICB23NM,
	fin_year,
	gender_desc,
	AVG(WardLocDistanceHome) AS mean_distance,
    SUM(WardLocDistanceHome) AS total_distance,
    COUNT(Der_Person_ID) AS person_ID_count
	--PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY WardLocDistanceHome) OVER (PARTITION BY ICB23CD, ICB23NM, fin_year, gender_desc) AS median_distance
--INTO #3
FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_HH_traveldistance_clean
WHERE
   WardLocDistanceHome IS NOT NULL
   --and order_in_spell = 1
GROUP BY
	ICB23CD, ICB23NM,
	fin_year,
	gender_desc
	--WardLocDistanceHome

ORDER BY
	mean_distance DESC

--NOT RIGHT BELOW THIS POINT - CAN'T GET MEDIAN CALC TO WORK - GET WORKING FOR GENDER THEN APPLY BELOW
--Ethnicity by year and ICB
SELECT
	ICB23CD, ICB23NM,
	fin_year,
	Ethnic_Category,
	AVG(mean_distance) AS Average_travel_distance
	--, COUNT(Der_Person_ID) AS person_ID_count

--INTO #4
FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_HH_traveldistance_calculations

WHERE --AgeRepPeriodStart < 25
    --AND AgeRepPeriodStart < '2023-04-01' AND
   mean_distance IS NOT NULL
   --and order_in_spell = 1

GROUP BY
	ICB23CD, ICB23NM,
	fin_year,
	Ethnic_Category

ORDER BY
	--mean_distance,
	--wardstay_count DESC,
	--person_ID_count DESC,
	Average_travel_distance DESC

--IMD by year and ICB
SELECT
	ICB23CD, ICB23NM,
	fin_year,
	imd_2019_decile,
	AVG(mean_distance) AS Average_travel_distance
	--, COUNT(Der_Person_ID) AS person_ID_count

--INTO #5
FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_HH_traveldistance_calculations

WHERE --AgeRepPeriodStart < 25
    --AND AgeRepPeriodStart < '2023-04-01' AND
   mean_distance IS NOT NULL
   --and order_in_spell = 1

GROUP BY
	ICB23CD, ICB23NM,
	fin_year,
	imd_2019_decile

ORDER BY
	--mean_distance,
	--wardstay_count DESC,
	--person_ID_count DESC,
	Average_travel_distance DESC

--Age Group by year and ICB
SELECT
	ICB23CD, ICB23NM,
	fin_year,
	age_group,
	AVG(mean_distance) AS Average_travel_distance
	--, COUNT(Der_Person_ID) AS person_ID_count

--INTO #6
FROM [NHSE_Sandbox_StrategyUnit].dbo.cqc_HH_traveldistance_calculations

WHERE --AgeRepPeriodStart < 25
    --AND AgeRepPeriodStart < '2023-04-01' AND
   mean_distance IS NOT NULL
   --and order_in_spell = 1

GROUP BY
	ICB23CD, ICB23NM,
	fin_year,
	age_group

ORDER BY
	--mean_distance,
	--wardstay_count DESC,
	--person_ID_count DESC,
	Average_travel_distance DESC

--#Cleaning Up
DROP TABLE #1
DROP TABLE #2
DROP TABLE #3
DROP TABLE #4
DROP TABLE #5
DROP TABLE #6