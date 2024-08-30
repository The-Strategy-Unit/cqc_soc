-- Setup
	DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_traveldistance]
	DROP TABLE IF EXISTS [NHSE_Sandbox_StrategyUnit].dbo.[cqc_traveldistance_agg]

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

--Reducing to one record per event
SELECT *
	, row_number() over (partition by der_person_id, uniqhospprovspellid
						 order by startdatewardstay, mhs502uniqid)
						 as order_in_spell
	INTO #1
	FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_ward_dist_full

	SELECT COUNT(*)
	FROM #1
	WHERE order_in_spell = 1
--gives 199501 results
--when the null distances are dropped the count goes down to 168,846

--Working version
SELECT *
	, row_number() over (partition by der_person_id, uniqhospprovspellid
						 order by startdatewardstay, mhs502uniqid)
						 as order_in_spell
	INTO #1
	FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_ward_dist_full

SELECT
	ICB23CD,
	ICB23NM,
    UniqHospProvSpellID,
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
    AVG(WardLocDistanceHome) AS mean_distance,
    SUM(WardLocDistanceHome) AS total_distance,
    COUNT(UniqWardStayID) AS wardstay_count,
    COUNT(Der_Person_ID) AS person_ID_count

INTO #2

FROM #1

WHERE --AgeRepPeriodStart < 25
    --AND AgeRepPeriodStart < '2023-04-01'
   -- AND
   WardLocDistanceHome IS NOT NULL
   and order_in_spell = 1

GROUP BY
	ICB23CD,
	ICB23NM,
    UniqHospProvSpellID,
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
        ELSE NULL END

ORDER BY
	--mean_distance,
	wardstay_count DESC


--## Aggregate tables for extracts
SELECT
	ICB23CD,
	ICB23NM,
	fin_year,
	gender_desc,
	Ethnic_Category,
	imd_2019_decile,
	age_group,
	SUM(mean_distance) AS Travel_distance

--INTO #3

FROM #2

GROUP BY
	ICB23CD,
	ICB23NM,
	fin_year,
	gender_desc,
	Ethnic_Category,
	imd_2019_decile,
	age_group

--Test
SELECT
	ICB23CD,
	ICB23NM,
	fin_year,
	avg(mean_distance) AS Average_travel_distance,
	sum(mean_distance) AS Total_travel_distance,
	count(*) AS count_records_IGcheck
--INTO #4
FROM #2
GROUP BY
	ICB23CD,
	ICB23NM,
	fin_year
ORDER BY
	--mean_distance,
	count_records_IGcheck --,
	--Average_travel_distance DESC

SELECT
--	ICB23CD,
--	ICB23NM,
	fin_year,
	gender_desc,
--	Ethnic_Category,
--	imd_2019_decile,
--	age_group,
	avg(mean_distance) AS Average_travel_distance,
	sum(mean_distance) AS Total_travel_distance,
	count(*) AS count_records_IGcheck
--INTO #4
FROM #2
GROUP BY
--	ICB23CD,
--	ICB23NM,
	fin_year,
	gender_desc
--	Ethnic_Category,
--	imd_2019_decile,
--	age_group,

ORDER BY
	--mean_distance,
	count_records_IGcheck --,
	--Average_travel_distance DESC

--## clean up
DROP TABLE #1