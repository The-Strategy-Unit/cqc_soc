-- Full HONOS scores near the start and end of a MH spell
------------------------------------------------------------------------------
-- Setting up table for HONOS codes:
IF OBJECT_ID('[NHSE_Sandbox_StrategyUnit].[dbo].cqc_honos_codes', 'U') IS NOT NULL
  DROP TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_honos_codes;

CREATE TABLE [NHSE_Sandbox_StrategyUnit].[dbo].cqc_honos_codes (
    snomed_ct_cd varchar(20),
	snomed_ct_desc varchar(255),
	snomed_ct_group varchar(20)
)

INSERT INTO [NHSE_Sandbox_StrategyUnit].[dbo].cqc_honos_codes
VALUES
('979641000000103', '"Health of the Nation Outcome Scales for working age adults rating scale 1 score - overactive, aggressive, disruptive or agitated behaviour"', 'honos_waa'),
('979671000000109', 'Health of the Nation Outcome Scales for working age adults rating scale 4 score - cognitive problems', 'honos_waa'),
('979691000000108', 'Health of the Nation Outcome Scales for working age adults rating scale 6 score - problems associated with hallucinations and delusions', 'honos_waa'),
('979731000000102', 'Health of the Nation Outcome Scales for working age adults rating scale 10 score - problems with activities of daily living', 'honos_waa'),
('979651000000100', 'Health of the Nation Outcome Scales for working age adults rating scale 2 score - non-accidental self-injury', 'honos_waa'),
('979681000000106', 'Health of the Nation Outcome Scales for working age adults rating scale 5 score - physical illness or disability problems', 'honos_waa'),
('979721000000104', 'Health of the Nation Outcome Scales for working age adults rating scale 9 score - problems with relationships', 'honos_waa'),
('979711000000105', 'Health of the Nation Outcome Scales for working age adults rating scale 8 score - other mental and behavioural problems', 'honos_waa'),
('979661000000102', 'Health of the Nation Outcome Scales for working age adults rating scale 3 score - problem drinking or drug-taking', 'honos_waa'),
('979741000000106', 'Health of the Nation Outcome Scales for working age adults rating scale 11 score - problems with living conditions', 'honos_waa'),
('979701000000108', 'Health of the Nation Outcome Scales for working age adults rating scale 7 score - problems with depressed mood', 'honos_waa'),
('979751000000109', 'Health of the Nation Outcome Scales for working age adults rating scale 12 score - problems with occupation and activities', 'honos_waa'),
('989811000000106', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 3 score - non-accidental self injury', 'honos_caa_c'),
('989821000000100', '"Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 4 score - alcohol, substance/solvent misuse"', 'honos_caa_c'),
('989831000000103', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 5 score - scholastic or language skills', 'honos_caa_c'),
('989761000000104', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 10 score - peer relationships', 'honos_caa_c'),
('989841000000107', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 6 score - physical illness or disability problems', 'honos_caa_c'),
('989871000000101', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 9 score - emotional and related symptoms', 'honos_caa_c'),
('989861000000108', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 8 score - non-organic somatic symptoms', 'honos_caa_c'),
('989801000000109', '"Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 2 score - overactivity, attention and concentration"', 'honos_caa_c'),
('989791000000105', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 13 score - poor school attendance', 'honos_caa_c'),
('989851000000105', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 7 score - hallucinations and delusions', 'honos_caa_c'),
('989751000000102', '"Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 1 score - disruptive, antisocial or aggressive behaviour"', 'honos_caa_c'),
('989771000000106', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 11 score - self care and independence', 'honos_caa_c'),
('989781000000108', 'Health of the Nation Outcome Scales for Children and Adolescents - clinician-rated scale 12 score - family life and relationships', 'honos_caa_c')

------------------------------------------------------------------------------
-- isolate from the large table only the assessments that are HONOS:
SELECT der_spell_id, snomed_ct_group, CareContDate, PersScore

INTO #honos_assessments

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess AS assess

INNER JOIN [NHSE_Sandbox_StrategyUnit].[dbo].cqc_honos_codes AS honos_codes
	ON assess.CodedAssToolType = honos_codes.snomed_ct_cd

WHERE spell_end_date BETWEEN '2019-04-01' AND '2023-03-31'

------------------------------------------------------------------------------

-- Get ids and dates where a full assessment happened:
SELECT der_spell_id, snomed_ct_group, CareContDate, number

INTO #full_assess_ids

FROM (
	SELECT der_spell_id, snomed_ct_group, CareContDate, COUNT(*) AS number

	FROM #honos_assessments AS assess

	WHERE PersScore NOT IN ('Missi', '9', '9.0')

	GROUP BY der_spell_id, snomed_ct_group, CareContDate
	) AS sub

-- return only those where there are the full 12 (adult) / 13 (cyp) scores at the same time:
WHERE CASE
		WHEN snomed_ct_group = 'honos_waa' AND number = 12 THEN 1
		WHEN snomed_ct_group = 'honos_caa_c' AND number = 13 THEN 1
		ELSE 0 END = 1

-- Get the sum of the scores across the HONOS measures for full assessments only, by person and date
SELECT
	assess.der_spell_id,
	assess.CareContDate,
	-- add up the 12 / 13 scale scores to get a total for each HONOS assessment:
	SUM(CAST(assess.PersScore AS FLOAT)) AS Score

INTO #full_assessments

FROM  #honos_assessments AS assess

-- return only those where there are the full 12 (adult) / 13 (cyp) scores at the same time:
INNER JOIN #full_assess_ids AS ids
	ON ids.der_spell_id = assess.der_spell_id
	AND ids.CareContDate = assess.CareContDate

GROUP BY assess.der_spell_id, assess.CareContDate

------------------------------------------------------------------------------
-- further isolate those spells with a total HONOS score on or near start of spell
-- and another score on or near end of spell.

-- Getting unique spell dates:
SELECT DISTINCT
	spell.der_spell_id,
	spell_start_date,
	spell_end_date

INTO #spells

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess AS spell

-- Getting HONOS score near start of each spell:
SELECT
	der_spell_id,
	spell_start_date,
	spell_end_date,
	CareContDate AS first_assess_date,
	score AS first_score

INTO #first_assess

FROM(

	SELECT
		spell.der_spell_id,
		spell.spell_start_date,
		spell.spell_end_date,
		first_assess.CareContDate,
		first_assess.score,
		ROW_NUMBER () OVER (PARTITION BY spell.der_spell_id ORDER BY first_assess.CareContDate) AS row_first_assess

	FROM #spells AS spell

	LEFT JOIN #full_assessments AS first_assess
		ON first_assess.der_spell_id = spell.der_spell_id
		AND DATEDIFF(dd, spell.spell_start_date, first_assess.CareContDate) BETWEEN 0 AND 7

	WHERE first_assess.score IS NOT NULL

	) AS Sub

WHERE row_first_assess = 1

-- Getting HONOS score near end of each spell:
SELECT
	der_spell_id,
	CareContDate AS last_assess_date,
	score AS last_score

INTO #last_assess

FROM(

	SELECT
		spell.der_spell_id,
		spell.spell_start_date,
		spell.spell_end_date,
		last_assess.CareContDate,
		last_assess.score,
		ROW_NUMBER () OVER (PARTITION BY spell.der_spell_id ORDER BY last_assess.CareContDate) AS row_last_assess

	FROM #spells AS spell

	LEFT JOIN #full_assessments AS last_assess
		ON last_assess.der_spell_id = spell.der_spell_id
		AND DATEDIFF(dd, spell.spell_end_date, last_assess.CareContDate) BETWEEN 0 AND 7

	WHERE last_assess.score IS NOT NULL

	) AS Sub

WHERE row_last_assess = 1

-- Puting first and last HONOS scores per spell together:
SELECT
	spell_start_date,
	spell_end_date,
	first_assess_date,
	first_score,
	last_assess_date,
	last_score,
	last_score / first_score AS rate_of_change

INTO #final

FROM

#first_assess AS first

INNER JOIN #last_assess AS last

ON first.der_spell_id = last.der_spell_id
	AND first.first_assess_date != last.last_assess_date

SELECT * FROM #final

------------------------------------------------------------------------------
-- Get numbers of spells at each stage of this process:
SELECT
	'spells' AS stage,
	COUNT(DISTINCT(der_spell_id)) AS number

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_epi_full

WHERE AgeRepPeriodStart <= 25
AND pseudo_EndDateMHActLegalStatusClass between '2019-04-01' AND '2023-03-31'

UNION

SELECT
	'any_assessment' AS stage,
	COUNT(DISTINCT(der_spell_id)) AS number

FROM [NHSE_Sandbox_StrategyUnit].[dbo].cqc_mha_assess

UNION

SELECT
	'honos_assessments' AS stage,
	COUNT(DISTINCT(der_spell_id)) AS number

FROM #honos_assessments

UNION

SELECT
	'full_assessments' AS stage,
	COUNT(DISTINCT(der_spell_id)) AS number

FROM #full_assessments

UNION

SELECT
	'first_assessments' AS stage,
	COUNT(*) AS number

FROM #first_assess

UNION

SELECT
	'first_and_last_assessments' AS stage,
	COUNT(*) AS number

FROM #final

------------------------------------------------------------------------------
-- Tidy up
DROP TABLE #honos_assessments
DROP TABLE #full_assess_ids
DROP TABLE #full_assessments
DROP TABLE #spells
DROP TABLE #first_assess
DROP TABLE #last_assess
DROP TABLE #final