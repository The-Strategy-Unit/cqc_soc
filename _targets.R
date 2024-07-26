library(targets)
# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(data_summary) to view the results.

# Set target options:
tar_option_set(
  packages = c(
    # Packages that your targets need for their tasks.
    "janitor",
    "DT",
    "tidyverse",
    "readODS",
    "patchwork",
    "PHEindicatormethods",
    "sf"
  )
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# End this file with a list of target objects.
list(
  #### Data loading and initial wrangling ####

  # LSOA to ICBs
  tar_target(lsoa_11_to_icb_23, load_csv("data/LSOA2011_to_ICB2023.csv")),
  tar_target(lsoa_21_to_icb_23, load_csv("data/LSOA2021_to_ICB2023.csv")),
  tar_target(
    lsoa_to_icb,
    get_lsoa_to_icb_key(lsoa_11_to_icb_23, lsoa_21_to_icb_23)
  ),

  # ICB codes and names
  tar_target(icb_codes_names, get_icb_codes_names(lsoa_to_icb)),

  # URLs for population data
  tar_target(
    url_population_2021_22,
    "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2021andmid2022/sapelsoasyoatablefinal.xlsx"
  ),
  tar_target(
    url_population_2020,
    "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2020sape23dt2/sape23dt2mid2020lsoasyoaestimatesunformatted.xlsx"
  ),
  tar_target(
    url_population_2019,
    "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2019sape22dt2/sape22dt2mid2019lsoasyoaestimatesunformatted.zip"
  ),
  tar_target(
    url_population_2018,
    "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2018sape21dt1a/sape21dt1amid2018on2019lalsoasyoaestimatesformatted.zip"
  ),
  tar_target(
    url_population_2017,
    "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2017/sape20dt1mid2017lsoasyoaestimatesformatted.zip"
    )
  ,

  # Reading in population data
  tarchetypes::tar_map(
    list(sheetnames = c("persons", "females", "males")),
    tar_target(
      population_2017,
      scrape_zipped_xls(
        url_population_2017,
        paste0("Mid-2017 ", stringr::str_to_title(sheetnames)),
        4
      ) |>
        dplyr::rename(lsoa_code = area_codes,
                      lsoa = x3) |>
        dplyr::filter(!is.na(lsoa)) # area_codes contains lsoa and lad codes, so
      # removing the lad codes here
    )
  ),
  tarchetypes::tar_map(
    list(sheetnames = c("persons", "females", "males")),
    tar_target(
      population_2018,
      scrape_zipped_xls(
        url_population_2018,
        paste0("Mid-2018 ", stringr::str_to_title(sheetnames)),
        4
      ) |>
        dplyr::rename(lsoa_code = area_codes) |>
        dplyr::filter(!is.na(lsoa)) # area_codes contains lsoa and lad codes, so
      # removing the lad codes here
    )
  ),
  tarchetypes::tar_map(
    list(sheetnames = c("persons", "females", "males")),
    tar_target(
      population_2019,
      scrape_zipped_xls(
        url_population_2019,
        paste0("Mid-2019 ", stringr::str_to_title(sheetnames)),
        4
      )
    )
  ),
  tarchetypes::tar_map(
    list(sheetnames = c("persons", "females", "males")),
    tar_target(population_2020, scrape_xls(
      url_population_2020,
      paste0("Mid-2020 ", stringr::str_to_title(sheetnames)),
      4
    ))
  ),
  tar_target(
    population_2021,
    scrape_xls(url_population_2021_22, "Mid-2021 LSOA 2021", 3)
  ),
  tar_target(
    population_2022,
    scrape_xls(url_population_2021_22, "Mid-2022 LSOA 2021", 3)
  ),

  # Population by gender and icb
  tar_target(
    gender_by_icb,
    get_gender_totals(
      population_2017_females,
      population_2017_males,
      population_2018_females,
      population_2018_males,
      population_2019_females,
      population_2019_males,
      population_2020_females,
      population_2020_males,
      population_2021,
      population_2022,
      lsoa_to_icb
    )
  ),

  # Population by age and icb
  tar_target(
    age_by_icb,
    get_age_totals(
      population_2017_females,
      population_2017_males,
      population_2018_females,
      population_2018_males,
      population_2019_females,
      population_2019_males,
      population_2020_females,
      population_2020_males,
      population_2021,
      population_2022,
      lsoa_to_icb
    )
  ),

  # Population by lsoa
  tar_target(
    population_by_lsoa,
    get_population_totals(
      population_2017_persons,
      population_2018_persons,
      population_2019_persons,
      population_2020_persons,
      population_2021,
      population_2022
    )
  ),

  # IMD decile totals by ICB
  tar_target(
    imd_url,
    "https://assets.publishing.service.gov.uk/media/5d8b3abded915d0373d3540f/File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx"
  ),
  tar_target(
    imd_by_icb,
    get_imd_totals(imd_url, population_by_lsoa, lsoa_to_icb)
  ),

  # Rural and Urban totals by ICB
  tar_target(
    rural_url,
    "https://assets.publishing.service.gov.uk/media/611bc076e90e0705464fa420/Rural_Urban_Classification_2011_lookup_tables_for_small_area_geographies.ods"
  ),
  tar_target(
    rural_by_icb,
    get_rural_totals(rural_url, population_by_lsoa, lsoa_to_icb)
  ),

  # Ethnicity By ICB

  # import and wrangle 2011 ethnicity data
  tar_target(ethnicity2011_by_icb2024, create2011ethnicities()),
  # import and wrangle 2021 ethnicity data
  tar_target(ethnicity2021_by_icb2024, create2021ethnicities()),
  # join two data sets
  tar_target(
    ethnicity_by_icb,
    join_ethnicity(ethnicity2011_by_icb2024, ethnicity2021_by_icb2024)
  ),
  # impute ethnicity data for every year
  tar_target(
    ethnicity_by_icb_by_year,
    impute_annual_ethnicity(ethnicity_by_icb) |>
      dplyr::rename(
        ethnic_category = Ethnicity,
        fin_year = der_financial_year,
        count = Count
      ) |>
      dplyr::mutate(ethnic_category = tolower(ethnic_category))
  ),

  # specific query data files
  tar_target(
    snomed_mh,
    load_csv("data/ref_mh_snomed_ct.csv") |>
      select(2, 3, 5, 6, 8, 13, 16, 19, 20, 23, 49, 61)
  ),

  tar_target(ae_times
             , load_csv("data/ae_waits_icb.csv")),
  tar_target(ae_diag,
    load_csv("data/ae_diag_icb.csv") |>
      left_join(snomed_mh, by = c("ec_diagnosis_01" = "concept_id"))
  ),
  tar_target(ae_freq,
             load_csv("data/ae_freqfly_icb.csv")
  ),
  tar_target(ae_left,
             load_csv("data/ae_left_icb.csv")
  ),
  tar_target(ae_toa,
             load_csv("data/ae_toa_icb.csv")
  ),
  tar_target(nhs111_toa,
             load_csv("data/111_toa_icb.csv")
  ),
  tar_target(nhs111_freq,
             load_csv("data/111_freqfly_icb.csv")
  ),
  tar_target(nhs111_disposition,
             load_csv("data/111_symptoms_mhflag.csv")
  ),

  # Full extracts
  tar_target(
    data_ae,
    load_csv("data/ae_extract_full.csv") |>
      dplyr::rename(imd_decile = index_of_multiple_deprivation_decile) |>
      dplyr::mutate(imd_decile = factor(imd_decile,
                                        levels = as.character(1:10)))
  ),

  tar_target(
    data_111,
    load_csv("data/111_extract_full.csv") |>
      dplyr::rename(icb_code = icb23cd) |>
      dplyr::mutate(imd_decile = factor(imd_decile,
                                        levels = as.character(1:10)))
  )
  ,

  # Summary from other extracts
  tar_target(ae_summary, get_ae_summary(data_ae)),

  tar_target(ae_summ_transp, get_ae_summ_transp(data_ae)),
  tar_target(ae_transp_trends, get_ae_amb_trends(data_ae)),

  tar_target(uec_summ_transp, get_ae_summ_transp(data_uec, c("03", "04"))),
  tar_target(uec_transp_trends, get_ae_amb_trends(data_uec, c("03", "04"))),

  tar_target(ae_toa_summary, ae_toa_grouped(ae_toa)),
  tar_target(uec_toa_summary, ae_toa_grouped(ae_toa, c("3", "4"))),

  tar_target(ae_left_summary, ae_left_grouped(ae_left)),
  tar_target(uec_left_summary, ae_left_grouped(ae_left, c("3", "4"))),

  #### Type 1 ED activity ####
  tar_target(data_ed, get_ed_activity(data_ae)),

  # MH attends
  tar_target(type1_mh_attends, filter_mh_attends(data_ed)),
  tar_target(type1_perc_mh_attends, get_perc_mh_attends(data_ed)),
  tar_target(
    type1_mh_attends_boxplot,
    get_perc_mh_attends_boxplot(type1_perc_mh_attends, "Type 1")
  ),
  tar_target(
    type1_mh_attends_table,
    get_icb_breakdown_table(type1_perc_mh_attends, icb_codes_names)
  ),

  # MH known
  tar_target(type1_mh_known, filter_mh_known(data_ed)),
  tar_target(type1_perc_mh_known, get_perc_mh_known(data_ed)),
  tar_target(
    type1_mh_known_boxplot,
    get_perc_mh_known_boxplot(type1_perc_mh_known, "Type 1")
  ),
  tar_target(
    type1_mh_known_table,
    get_icb_breakdown_table(type1_perc_mh_known, icb_codes_names)
  ),

  # Arrival mode
  tar_target(type1_arrival_mode, filter_arrival_mode(data_ed)),
  tar_target(uec_arrival_mode, filter_arrival_mode(data_uec)),

  #### UEC activity ####
  tar_target(data_uec, get_uec_activity(data_ae)),

  # MH attends
  tar_target(uec_mh_attends, filter_mh_attends(data_uec)),
  tar_target(uec_perc_mh_attends, get_perc_mh_attends(data_uec)),
  tar_target(
    uec_mh_attends_boxplot,
    get_perc_mh_attends_boxplot(uec_perc_mh_attends, "Type 3 and 4")
  ),
  tar_target(
    uec_mh_attends_table,
    get_icb_breakdown_table(uec_perc_mh_attends, icb_codes_names)
  ),

  # MH known
  tar_target(uec_mh_known, filter_mh_known(data_uec)),
  tar_target(uec_perc_mh_known, get_perc_mh_known(data_uec)),
  tar_target(
    uec_mh_known_boxplot,
    get_perc_mh_known_boxplot(uec_perc_mh_known, "Type 3 and 4")
  ),
  tar_target(
    uec_mh_known_table,
    get_icb_breakdown_table(uec_perc_mh_known, icb_codes_names)
  ),

  #### Breakdowns ####
  tar_target(
    data_for_breakdowns,
    list(
      uec_mh_attends = uec_mh_attends,
      uec_mh_known = uec_mh_known,
      type1_mh_attends = type1_mh_attends,
      type1_mh_known = type1_mh_known,
      nhs111_mh_calls = nhs111_mh_calls |>
        dplyr::rename(attends = calls)
    )
  ),
  tar_target(gender_breakdowns,
             get_breakdowns(data_for_breakdowns,
                            type1_arrival_mode,
                            uec_arrival_mode,
                            gender_by_icb,
                            "gender")),
  tar_target(age_breakdowns,
             get_breakdowns(data_for_breakdowns,
                            type1_arrival_mode,
                            uec_arrival_mode,
                            age_by_icb,
                            "age_group")),
  tar_target(imd_breakdowns,
             get_breakdowns(data_for_breakdowns,
                            type1_arrival_mode,
                            uec_arrival_mode,
                            imd_by_icb,
                            "imd_decile")),
  tar_target(rural_breakdowns,
             get_breakdowns(data_for_breakdowns,
                            type1_arrival_mode,
                            uec_arrival_mode,
                            rural_by_icb,
                            "rural_urban")),
  tar_target(ethnic_breakdowns,
             get_breakdowns(data_for_breakdowns,
                            type1_arrival_mode,
                            uec_arrival_mode,
                            ethnicity_by_icb_by_year,
                            "ethnic_category")),

  #### Plots ####
  tar_target(ae_times_assess_plot, ed_times_assess_plot(ae_times)),
  tar_target(ae_times_treat_plot, ed_times_treat_plot(ae_times)),
  tar_target(ae_times_conclude_plot, ed_times_conclude_plot(ae_times)),
  tar_target(ae_times_depart_plot, ed_times_depart_plot(ae_times)),

  # frequent fliers
  tar_target(ae_freq_boxplot, ed_freq_boxplot(ae_freq)),
  tar_target(nhs111_freq_boxplot,
             ed_freq_boxplot(nhs111_freq,
                             "NHS 111 calls",
                             "patients calling for MH related reasons")),

  # arrival mode
  tar_target(ae_trans_barplot, get_ed_transp_colplot(ae_summ_transp)),
  tar_target(ae_trans_trends, get_ed_transp_trends(ae_transp_trends)),
  tar_target(uec_trans_barplot, get_ed_transp_colplot(uec_summ_transp, "UEC")),
  tar_target(uec_trans_trends, get_ed_transp_trends(uec_transp_trends, "UEC")),

  tar_target(ed_left_chart, ed_left_plot(ae_left_summary)),
  tar_target(uec_left_chart, ed_left_plot(uec_left_summary, "UEC")),
  # Overlayed bar chart for time of arrival to AE
  tar_target(ae_toa_plot, get_overlay_barchart_toa(ae_toa_summary)),
  tar_target(uec_toa_plot, get_overlay_barchart_toa(uec_toa_summary, "UEC")),

  # ICB total populations
  tar_target(pop_by_icb, get_icb_pop_total(gender_by_icb)),
  tar_target(icb_rates_ed, get_icb_att_rates(data_ed, pop_by_icb)),
  tar_target(icb_rates_uec, get_icb_att_rates(data_uec, pop_by_icb)),

  # New IMD plots
  tar_target(ae_attends_imd, imd_plot2(imd_breakdowns$type1_mh_attends)),
  tar_target(uec_attends_imd, imd_plot2(imd_breakdowns$uec_mh_attends)),
  tar_target(nhs111_calls_imd, imd_plot2(imd_breakdowns$nhs111_mh_calls)),

  # Breakdowns
  tar_target(
    gender_plot,
    purrr::map(
      gender_breakdowns,
      ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "gender")
    )
  ),
  tar_target(
    age_plot,
    purrr::map(
      age_breakdowns,
      ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "age_group")
    )
  ),
  tar_target(
    imd_plot,
    purrr::map(
      imd_breakdowns,
      ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "imd_decile")
    )
  ),
  tar_target(
    rural_plot,
    purrr::map(
      rural_breakdowns,
      ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "rural_urban")
    )
  ),
  tar_target(
    ethnic_plot,
    purrr::map(
      ethnic_breakdowns,
      ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "ethnic_category")
    )
  ),
  #### Map layers and map plots ####

  # load icb april 2023 boundaries
  tar_target(
    icb_boundary,
    get_icb_map(
      "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Integrated_Care_Boards_April_2023_EN_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
    )
  ),
  # 23/24 mh attendance rate ED by ICB map
  tar_target(icb_ed_map_2324,
             map_icb_allmh(icb_boundary, icb_rates_ed)),
  tar_target(icb_uec_map_2324,
             map_icb_allmh_uec(icb_boundary, icb_rates_uec)),
  tar_target(icb_111_map_2122,
             map_icb_allmh_111(icb_boundary, nhs111_mh_calls_rate, "2020/21")),

  #### NHS 111 ####
  tar_target(nhs111_mh_calls, filter_mh_calls(data_111)),
  tar_target(nhs111_mh_calls_rate, get_icb_111_rates(data_111, pop_by_icb)),
  tar_target(nhs111_perc_mh_calls, get_perc_mh_calls(data_111)),
  tar_target(
    nhs111_mh_calls_boxplot,
    get_perc_mh_calls_boxplot(nhs111_perc_mh_calls)
  ),
  tar_target(
    nhs111_mh_calls_table,
    get_icb_breakdown_table_111(nhs111_perc_mh_calls, icb_codes_names)
  ),
  tar_target(nhs111_perc_mh_calls_toa, get_overlay_barchart_toa_111(nhs111_toa))

)