library(targets)
# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(data_summary) to view the results.

# Set target options:
tar_option_set(packages = c(# Packages that your targets need for their tasks.
  "janitor",
  "gt",
  "tidyverse",
  "readODS",
  "patchwork",
  "PHEindicatormethods",
  "sf"))

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# End this file with a list of target objects.
list(
  #### Data loading and initial wrangling ####

  # LSOA to ICBs
  tar_target(lsoa_11_to_icb_23,
             load_csv("data/LSOA2011_to_ICB2023.csv")),
  tar_target(lsoa_21_to_icb_23,
             load_csv("data/LSOA2021_to_ICB2023.csv")),
  tar_target(
    lsoa_to_icb,
    get_lsoa_to_icb_key(lsoa_11_to_icb_23, lsoa_21_to_icb_23)
  ),

  # ICB codes and names
  tar_target(icb_codes_names,
             get_icb_codes_names(lsoa_to_icb)),

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

  # Reading in population data
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
      population_2018_persons,
      population_2019_persons,
      population_2020_persons,
      population_2021,
      population_2022
    )
  ),

  # IMD decile totals by ICB
  tar_target(imd_url,
             "https://assets.publishing.service.gov.uk/media/5d8b3abded915d0373d3540f/File_1_-_IMD2019_Index_of_Multiple_Deprivation.xlsx"),
  tar_target(imd_by_icb,
             get_imd_totals(imd_url, population_by_lsoa, lsoa_to_icb)),

  # Rural and Urban totals by ICB
  tar_target(rural_url,
             "https://assets.publishing.service.gov.uk/media/611bc076e90e0705464fa420/Rural_Urban_Classification_2011_lookup_tables_for_small_area_geographies.ods"),
  tar_target(rural_by_icb,
             get_rural_totals(rural_url, population_by_lsoa, lsoa_to_icb)),

  # Ethnicity By ICB

  # import and wrangle 2011 ethnicity data
  tar_target(ethnicity2011_by_icb2024,
             create2011ethnicities()),
  # import and wrangle 2021 ethnicity data
  tar_target(ethnicity2021_by_icb2024,
             create2021ethnicities()),
  # join two data sets
  tar_target(ethnicity_by_icb,
             join_ethnicity(ethnicity2011_by_icb2024,
                            ethnicity2021_by_icb2024)),
  # impute ethnicity data for every year
  tar_target(ethnicity_by_icb_by_year,
             impute_annual_ethnicity(ethnicity_by_icb) |>
              dplyr::rename(ethnic_category = Ethnicity,
                            fin_year = der_financial_year,
                            count = Count) |>
              dplyr::mutate(ethnic_category = tolower(ethnic_category))),

  # specific query data files
  tar_target(snomed_mh,
             load_csv("data/ref_mh_snomed_ct.csv") |>
               select(2,3,5,6,8,13,16,19,20,23,49,61)),

  tar_target(ae_times,
             load_csv("data/ae_waits_icb.csv")),
  tar_target(ae_diag,
             load_csv("data/ae_diag_icb.csv") |>
               left_join(snomed_mh, by = c("ec_diagnosis_01" = "concept_id"))),
  tar_target(ae_freq,
             load_csv("data/ae_freqfly_icb.csv")),

  # Full extracts
  tar_target(data_ae,
             load_csv("data/ae_extract_full.csv") |>
               dplyr::rename(imd_decile = index_of_multiple_deprivation_decile)),

  tar_target(data_111,
             load_csv("data/111_extract_full.csv")),

  # Summary from full extracts
  tar_target(ae_summary,
             get_ae_summary(data_ae)),

  tar_target(ae_summ_transp,
             get_ae_summ_transp(data_ae)),

  # Type 1 ED activity
  tar_target(data_ed,
             get_ed_activity(data_ae)),

  # MH attends breakdowns
  tar_target(type1_mh_attends,
             filter_mh_attends(data_ed)),
  tar_target(type1_mh_attends_gender,
             get_breakdown(type1_mh_attends, gender_by_icb, "gender")),
  tar_target(type1_mh_attends_imd,
             get_breakdown(type1_mh_attends, imd_by_icb, "imd_decile")),
  tar_target(type1_mh_attends_age,
             get_breakdown(type1_mh_attends, age_by_icb, "age_group")),
  tar_target(type1_mh_attends_rural,
             get_breakdown(type1_mh_attends, rural_by_icb, "rural_urban")),
  tar_target(type1_mh_attends_ethnic,
             get_breakdown(type1_mh_attends, ethnicity_by_icb_by_year, "ethnic_category")),

  #### UEC activity ####
  tar_target(data_uec,
             get_uec_activity(data_ae)),

  # MH attends
  tar_target(uec_perc_mh_attends,
             get_perc_mh_attends(data_uec)),
  tar_target(uec_mh_attends_boxplot,
             get_perc_mh_attends_boxplot(uec_perc_mh_attends)),
  tar_target(uec_mh_attends_table,
             get_uec_table(uec_perc_mh_attends, icb_codes_names)),

  # MH attends breakdowns
  tar_target(uec_mh_attends,
             filter_mh_attends(data_uec)),
  tar_target(uec_mh_attends_gender,
             get_breakdown(uec_mh_attends, gender_by_icb, "gender")),
  tar_target(uec_mh_attends_imd,
             get_breakdown(uec_mh_attends, imd_by_icb, "imd_decile")),
  tar_target(uec_mh_attends_age,
             get_breakdown(uec_mh_attends, age_by_icb, "age_group")),
  tar_target(uec_mh_attends_rural,
             get_breakdown(uec_mh_attends, rural_by_icb, "rural_urban")),
  tar_target(uec_mh_attends_ethnic,
             get_breakdown(uec_mh_attends, ethnicity_by_icb_by_year, "ethnic_category")),


  # MH known
  tar_target(uec_perc_mh_known,
             get_perc_mh_known(data_uec)),
  tar_target(uec_mh_known_boxplot,
             get_perc_mh_known_boxplot(uec_perc_mh_known)),
  tar_target(uec_mh_known_table,
             get_uec_table(uec_perc_mh_known, icb_codes_names)),

  #### Plots ####

  tar_target(ae_times_plot,
             ed_times_plot(ae_times)),
  tar_target(ae_freq_boxplot,
             ed_freq_boxplot(ae_freq)),
  tar_target(ae_trans_barplot,
             get_ed_transp_colplot(ae_summ_transp)),

  # ICB total populations
  tar_target(pop_by_icb,
             get_icb_pop_total(gender_by_icb)),
  tar_target(icb_rates_ed,
             get_icb_att_rates(data_ed,pop_by_icb)),
  tar_target(icb_rates_uec,
             get_icb_att_rates(data_uec,pop_by_icb)),

  # Breakdowns
  tar_target(uec_mh_attends_gender_plot,
             get_standard_line_for_breakdowns(uec_mh_attends_gender, "gender")),
  tar_target(uec_mh_attends_age_plot,
             get_standard_line_for_breakdowns(uec_mh_attends_age, "age_group")),

  tar_target(uec_mh_attends_imd_plot,
             get_standard_line_for_breakdowns(uec_mh_attends_imd, "imd_decile")),

  tar_target(uec_mh_attends_rural_plot,
             get_standard_line_for_breakdowns(uec_mh_attends_rural, "rural_urban")),

  tar_target(uec_mh_attends_ethnic_plot,
             get_standard_line_for_breakdowns(uec_mh_attends_ethnic, "ethnic_category")),

  tar_target(type1_mh_attends_gender_plot,
             get_standard_line_for_breakdowns(type1_mh_attends_gender, "gender")),
  tar_target(type1_mh_attends_age_plot,
             get_standard_line_for_breakdowns(type1_mh_attends_age, "age_group")),

  tar_target(type1_mh_attends_imd_plot,
             get_standard_line_for_breakdowns(type1_mh_attends_imd, "imd_decile")),

  tar_target(type1_mh_attends_rural_plot,
             get_standard_line_for_breakdowns(type1_mh_attends_rural, "rural_urban")),

  tar_target(type1_mh_attends_ethnic_plot,
             get_standard_line_for_breakdowns(type1_mh_attends_ethnic, "ethnic_category")),

#### Map layers and map plots ####

  # load icb april 2023 boundaries
  tar_target(icb_boundary,
             get_icb_map("https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Integrated_Care_Boards_April_2023_EN_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson")),

  # 23/24 mh attendance rate ED by ICB map
  tar_target(icb_ed_map_2324,
             map_icb_allmh(icb_boundary,icb_rates_ed)),
  tar_target(icb_uec_map_2324,
             map_icb_allmh_uec(icb_boundary,icb_rates_uec))

  )