
----## find max number of episodes in spell, all ages (n=14)

select *
, row_number() over (partition by Der_Person_ID, der_spell_id order by pat_row_id) as orderinspell
into #1
from NHSE_Sandbox_StrategyUnit.dbo.cqc_mha_epi_full
order by Der_Person_ID, pat_row_id

--Select orderinspell, count(*)
--from #1
--group by orderinspell
--order by orderinspell

----## table of patients and spells with sep column for each section of act in episodes (up to 14)

Select a.der_person_id, a.der_spell_id, a.AgeRepPeriodStart, a.LegalStatusCode as section_1
,sec_2.LegalStatusCode as section_2
,sec_3.LegalStatusCode as section_3
,sec_4.LegalStatusCode as section_4
,sec_5.LegalStatusCode as section_5
,sec_6.LegalStatusCode as section_6
,sec_7.LegalStatusCode as section_7
,sec_8.LegalStatusCode as section_8
,sec_9.LegalStatusCode as section_9
,sec_10.LegalStatusCode as section_10
,sec_11.LegalStatusCode as section_11
,sec_12.LegalStatusCode as section_12
,sec_13.LegalStatusCode as section_13
,sec_14.LegalStatusCode as section_14
into #2
from #1 a
left outer join #1 sec_2
	on a.Der_Person_ID = sec_2.Der_Person_ID
	and a.der_spell_id = sec_2.der_spell_id
	and sec_2.orderinspell = 2
left outer join #1 sec_3
	on a.Der_Person_ID = sec_3.Der_Person_ID
	and a.der_spell_id = sec_3.der_spell_id
	and sec_3.orderinspell = 3
left outer join #1 sec_4
	on a.Der_Person_ID = sec_4.Der_Person_ID
	and a.der_spell_id = sec_4.der_spell_id
	and sec_4.orderinspell = 4
left outer join #1 sec_5
	on a.Der_Person_ID = sec_5.Der_Person_ID
	and a.der_spell_id = sec_5.der_spell_id
	and sec_5.orderinspell = 5
left outer join #1 sec_6
	on a.Der_Person_ID = sec_6.Der_Person_ID
	and a.der_spell_id = sec_6.der_spell_id
	and sec_6.orderinspell = 6
left outer join #1 sec_7
	on a.Der_Person_ID = sec_7.Der_Person_ID
	and a.der_spell_id = sec_7.der_spell_id
	and sec_7.orderinspell = 7
left outer join #1 sec_8
	on a.Der_Person_ID = sec_8.Der_Person_ID
	and a.der_spell_id = sec_8.der_spell_id
	and sec_8.orderinspell = 8
left outer join #1 sec_9
	on a.Der_Person_ID = sec_9.Der_Person_ID
	and a.der_spell_id = sec_9.der_spell_id
	and sec_9.orderinspell = 9
left outer join #1 sec_10
	on a.Der_Person_ID = sec_10.Der_Person_ID
	and a.der_spell_id = sec_10.der_spell_id
	and sec_10.orderinspell = 10
left outer join #1 sec_11
	on a.Der_Person_ID = sec_11.Der_Person_ID
	and a.der_spell_id = sec_11.der_spell_id
	and sec_11.orderinspell = 11
left outer join #1 sec_12
	on a.Der_Person_ID = sec_12.Der_Person_ID
	and a.der_spell_id = sec_12.der_spell_id
	and sec_12.orderinspell = 12
left outer join #1 sec_13
	on a.Der_Person_ID = sec_13.Der_Person_ID
	and a.der_spell_id = sec_13.der_spell_id
	and sec_13.orderinspell = 13
left outer join #1 sec_14
	on a.Der_Person_ID = sec_14.Der_Person_ID
	and a.der_spell_id = sec_14.der_spell_id
	and sec_14.orderinspell = 14

where a.mha_spell_start_flag_final = 1

Select *
, concat_ws('-',section_1, section_2, section_3, section_4, section_5, section_6, section_7, section_8, section_9, section_10, section_11, section_12, section_13, section_14) as sections_all
into #3
from #2
where AgeRepPeriodStart < 25

Select sections_all, count(*) as mha_spells
from #3
group by sections_all
order by count(*) desc
