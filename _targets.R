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
    "sf",
    "stringr"
  )
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# End this file with a list of target objects.
list(
  # 01. LSOA and ICBs ----------------------------------------------------------
  # LSOA to ICB
  tar_target(lsoa_11_to_icb_23, load_csv("data/LSOA2011_to_ICB2023.csv")),
  tar_target(lsoa_21_to_icb_23, load_csv("data/LSOA2021_to_ICB2023.csv")),
  tar_target(
    lsoa_to_icb,
    get_lsoa_to_icb_key(lsoa_11_to_icb_23, lsoa_21_to_icb_23)
  ),

  # ICB codes and names
  tar_target(icb_codes_names, get_icb_codes_names(lsoa_to_icb)),

  # 02. Population data including by subgroups ---------------------------------
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
        dplyr::rename(lsoa_code = area_codes, lsoa = x3) |>
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
      lsoa_to_icb,
      "soc"
    )
  ),

  # Population by age and icb for the CYP report - different age groupings
  tar_target(
    cyp_age_by_icb,
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
      lsoa_to_icb,
      "cyp"
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

  # 03. SQL data extracts ------------------------------------------------------
  # specific query data files
  tarchetypes::tar_file(snomed_mh_filepath, "data/ref_mh_snomed_ct.csv"),
  tar_target(
    snomed_mh,
    load_csv(snomed_mh_filepath) |>
      select(2, 3, 5, 6, 8, 13, 16, 19, 20, 23, 49, 61)
  ),

  tarchetypes::tar_file(ae_times_filepath, "data/ae_waits_icb.csv"),
  tar_target(ae_times, load_csv(ae_times_filepath)),

  tarchetypes::tar_file(ae_diag_filepath, "data/ae_diag_icb.csv"),
  tar_target(
    ae_diag,
    load_csv(ae_diag_filepath) |>
      left_join(snomed_mh, by = c("ec_diagnosis_01" = "concept_id"))
  ),

  tarchetypes::tar_file(ae_freq_filepath, "data/ae_freqfly_icb.csv"),
  tar_target(ae_freq, load_csv(ae_freq_filepath)),

  tarchetypes::tar_file(ae_left_filepath, "data/ae_left_icb.csv"),
  tar_target(ae_left, load_csv(ae_left_filepath)),

  tarchetypes::tar_file(ae_toa_filepath, "data/ae_toa_icb.csv"),
  tar_target(ae_toa, load_csv(ae_toa_filepath)),

  tarchetypes::tar_file(nhs111_toa_filepath, "data/111_toa_icb.csv"),
  tar_target(nhs111_toa, load_csv(nhs111_toa_filepath)),

  tarchetypes::tar_file(nhs111_freq_filepath, "data/111_freqfly_icb.csv"),
  tar_target(nhs111_freq, load_csv(nhs111_freq_filepath)),

  tarchetypes::tar_file(nhs111_disposition_filepath, "data/111_symptoms_mhflag.csv"),
  tar_target(nhs111_disposition, load_csv(nhs111_disposition_filepath)),

  tarchetypes::tar_file(nhs111_diagnosis_filepath, "data/111_sympt_icb.csv"),
  tar_target(nhs111_diagnosis, load_csv(nhs111_diagnosis_filepath)),

  # Full extracts
  tarchetypes::tar_file(data_ae_filepath, "data/ae_extract_full.csv"),
  tar_target(
    data_ae,
    load_csv(data_ae_filepath) |>
      dplyr::rename(imd_decile = index_of_multiple_deprivation_decile) |>
      dplyr::mutate(imd_decile = factor(imd_decile, levels = as.character(1:10)))
  ),

  tarchetypes::tar_file(data_111_filepath, "data/111_extract_full.csv"),
  tar_target(
    data_111,
    load_csv(data_111_filepath) |>
      dplyr::rename(icb_code = icb23cd) |>
      dplyr::mutate(imd_decile = factor(imd_decile, levels = as.character(1:10)))
  ),
  tarchetypes::tar_file(cyp_redetentions_filepath, "data/cyp_redetentions.csv"),
  tar_target(
    cyp_redetentions,
    load_csv(cyp_redetentions_filepath) |>
      dplyr::rename(
        der_financial_year = fin_year,
        icb_code = icb23cd,
        attends = redetentions,
        imd_decile = imd_2019_decile
      ) |>
      dplyr::mutate(
        der_financial_year =
          stringr::str_replace_all(der_financial_year, "-20", "/"),
        imd_decile = factor(imd_decile, levels = as.character(1:10))
      )
  ),
  tarchetypes::tar_file(cyp_readmissions_filepath, "data/cyp_readmissions.csv"),
  tar_target(
    cyp_readmissions,
    load_csv(cyp_readmissions_filepath) |>
      dplyr::rename(
        der_financial_year = fin_year,
        icb_code = icb23cd,
        attends = readmissions,
        imd_decile = imd_2019_decile
      ) |>
      dplyr::mutate(
        der_financial_year =
          stringr::str_replace_all(der_financial_year, "-20", "/"),
        imd_decile = factor(imd_decile, levels = as.character(1:10))
      )
  ),
  tarchetypes::tar_file(cyp_los_filepath, "data/cyp_los.csv"),
  tar_target(
    cyp_los,
    load_csv(cyp_los_filepath) |>
      dplyr::rename(
        der_financial_year = fin_year,
        icb_code = icb23cd,
        imd_decile = imd_2019_decile
      ) |>
      dplyr::mutate(
        der_financial_year =
          stringr::str_replace_all(der_financial_year, "-20", "/"),
        imd_decile = factor(imd_decile, levels = as.character(1:10))
      )
  ),
  tarchetypes::tar_file(mha_conversion_filepath, "data/cyp_mha_conversions.csv"),
  tar_target(cyp_conversions, load_csv(mha_conversion_filepath)),
  tarchetypes::tar_file(cyp_honos_filepath, "data/cyp_honos_scores.csv"),
  tar_target(cyp_honos, load_csv(cyp_honos_filepath)),
  tarchetypes::tar_file(cyp_honos_summary_filepath, "data/cyp_honos_summary.csv"),
  tar_target(cyp_honos_summary, load_csv(cyp_honos_summary_filepath)),

  # Summary from other extracts
  tar_target(ae_summary, get_ae_summary(data_ae)),
  tar_target(uec_summary, get_uec_summary(data_uec)),
  tar_target(nhs111_summary, get_111_summary(data_111)),

  tar_target(ae_summ_transp, get_ae_summ_transp(data_ae)),
  tar_target(ae_transp_trends, get_ae_amb_trends(data_ae)),

  tar_target(uec_summ_transp, get_ae_summ_transp(data_uec, c("03", "04"))),
  tar_target(uec_transp_trends, get_ae_amb_trends(data_uec, c("03", "04"))),

  tar_target(ae_toa_summary, ae_toa_grouped(ae_toa)),
  tar_target(uec_toa_summary, ae_toa_grouped(ae_toa, c("3", "4"))),

  tar_target(ae_left_summary, ae_left_grouped(ae_left)),
  tar_target(uec_left_summary, ae_left_grouped(ae_left, c("3", "4"))),

  tar_target(
    nhs111_sympt_summary,
    get_111_symptom_summary(nhs111_diagnosis)
  ),

  # 04. Data wrangling ---------------------------------------------------------

  ## Type 1 ED activity ---------------------------------------------------------
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

  ### Arrival mode
  tar_target(type1_arrival_mode, filter_arrival_mode(data_ed)),
  tar_target(uec_arrival_mode, filter_arrival_mode(data_uec)),

  ## UEC activity ---------------------------------------------------------------
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

  ## NHS 111 --------------------------------------------------------------------
  tar_target(nhs111_mh_calls, filter_mh_calls(data_111)),
  tar_target(
    nhs111_mh_calls_rate,
    get_icb_111_rates(data_111, pop_by_icb)
  ),
  tar_target(nhs111_perc_mh_calls, get_perc_mh_calls(data_111)),
  tar_target(
    nhs111_mh_calls_boxplot,
    get_perc_mh_calls_boxplot(nhs111_perc_mh_calls)
  ),
  tar_target(
    nhs111_mh_calls_table,
    get_icb_breakdown_table_111(nhs111_perc_mh_calls, icb_codes_names)
  ),

  tar_target(nhs111_perc_toa, get_perc_toa_111(nhs111_toa)),
  tar_target(
    nhs111_perc_mh_calls_toa,
    get_overlay_barchart_toa_111(nhs111_perc_toa)
  ),

  # disposition
  tar_target(
    nhs111_disposition_summary,
    get_disposition_summary(data_111)
  ),
  tar_target(
    nhs111_disposition_bar,
    get_disposition_bar_chart(nhs111_disposition_summary)
  ),
  tar_target(nhs111_disposition_trends, get_disposition_trends(data_111)),
  tar_target(
    nhs111_disposition_trends_chart,
    get_nhs111_disposition_trends_chart(nhs111_disposition_trends)
  ),
  tar_target(nhs111_mh_known_summary, get_111_mh_known(data_111)),

  ## MHA Redetentions ----------------------------------------------------------
  tar_target(
    cyp_redetentions_perc,
    get_cyp_redetentions_line(cyp_redetentions)
  ),
  tarchetypes::tar_map(
    list(
      group = c(
        "icb_code",
        "gender",
        "age_group",
        "imd_decile",
        "ethnic_category"
      )
    ),
    tar_target(
      cyp_redetentions_perc,
      get_perc_redetentions(cyp_redetentions, group)
    )
  ),
  # by icb
  tar_target(
    cyp_redetentions_perc_boxplot,
    get_standard_boxplot(cyp_redetentions_perc_icb_code)
  ),
  tar_target(
    cyp_redetentions_perc_table,
    get_icb_breakdown_table_redetentions(cyp_redetentions_perc_icb_code, icb_codes_names)
  ),
  # by formal or informal
  tar_target(
    cyp_redetentions_legal_status,
    get_perc_redetentions(cyp_redetentions, "legal_status") |>
      dplyr::arrange(der_financial_year, legal_status)
  ),
  tar_target(
    cyp_redetentions_formal_table,
    get_cyp_redetentions_formal_table(cyp_redetentions_legal_status)
  ),
  # by group
  tar_target(
    cyp_redetentions_plot_gender,
    get_cyp_redetentions_line_by_group(cyp_redetentions_perc_gender, "gender")
  ),
  tar_target(
    cyp_redetentions_plot_ethnic_category,
    get_cyp_redetentions_line_by_group(cyp_redetentions_perc_ethnic_category, "ethnic_category")
  ),
  tar_target(
    cyp_redetentions_plot_age_group,
    get_cyp_redetentions_line_by_group(cyp_redetentions_perc_age_group, "age_group")
  ),
  tar_target(
    cyp_redetentions_plot_imd_decile,
    get_cyp_redetentions_line_by_group(cyp_redetentions_perc_imd_decile, "imd_decile")
  ),
  # Readmissions
  tar_target(
    cyp_readmissions_perc,
    get_cyp_readmissions_perc(cyp_readmissions)
  ),
  tar_target(
    cyp_readmissions_perc_icb_code,
    get_perc_redetentions(cyp_readmissions, "icb_code") |>
      dplyr::filter(icb_code != "NULL")
  ),
  tar_target(
    cyp_readmissions_perc_boxplot,
    get_standard_boxplot(cyp_readmissions_perc_icb_code)
  ),
  tar_target(
    cyp_readmissions_perc_table,
    get_icb_breakdown_table_redetentions(cyp_readmissions_perc_icb_code, icb_codes_names)
  ),
  ## LOS - MHA detentions ------------------------------------------------------
  # Histogram for 22/23
  tar_target(cyp_los_histo, get_cyp_los_histo(cyp_los)),
  tar_target(cyp_los_histo_zoomed, get_cyp_los_histo_zoomed(cyp_los)),

  # Boxplot and table for median LOS
  tar_target(
    cyp_los_median,
    cyp_los |>
      dplyr::summarise(
        value = median(los),
        .by = c(der_financial_year, icb_code)
      )
  ),
  tar_target(cyp_los_boxplot, get_standard_boxplot(cyp_los_median)),
  tar_target(
    cyp_los_median_table,
    get_icb_breakdown_table(cyp_los_median, icb_codes_names)
  ),
  # Median LOS by group
  tar_target(cyp_los_plot_overview, get_cyp_los_line(cyp_los)),
  tarchetypes::tar_map(
    list(
      group = c("gender", "age_group", "imd_decile", "ethnic_category")
    ),
    tar_target(cyp_los_plot, get_cyp_los_line_by_group(cyp_los, group))
  ),

  # perc llos
  tar_target(cyp_llos_perc, get_llos_perc(cyp_los, 365)),

  # LOS by section
  tar_target(cyp_los_135_136, get_cyp_los_by_section(cyp_los, c(19, 20))),
  tar_target(cyp_los_histo_135_136, get_cyp_los_histo(cyp_los_135_136)),
  tar_target(cyp_llos_perc_135_136, get_llos_perc(cyp_los_135_136, 1)),
  tar_target(
    cyp_los_median_135_136,
    cyp_los_135_136 |>
      dplyr::summarise(
        value = median(los),
        .by = c(der_financial_year, icb_code)
      )
  ),
  tar_target(
    cyp_los_boxplot_135_136,
    get_standard_boxplot(cyp_los_median_135_136 |>
                           dplyr::filter(value < 5))
  ),
  tar_target(
    cyp_los_median_table_135_136,
    get_icb_breakdown_table(cyp_los_median_135_136, icb_codes_names)
  ),

  tar_target(cyp_los_2, get_cyp_los_by_section(cyp_los, c(2))),
  tar_target(cyp_los_histo_2, get_cyp_los_histo(cyp_los_2)),
  tar_target(cyp_llos_perc_2, get_llos_perc(cyp_los_2, 28)),
  tar_target(
    cyp_los_median_2,
    cyp_los_2 |>
      dplyr::summarise(
        value = median(los),
        .by = c(der_financial_year, icb_code)
      )
  ),
  tar_target(
    cyp_los_boxplot_2,
    get_standard_boxplot(cyp_los_median_2 |>
                           dplyr::filter(value < 50))
  ),
  tar_target(
    cyp_los_median_table_2,
    get_icb_breakdown_table(cyp_los_median_2, icb_codes_names)
  ),

  tar_target(cyp_los_3, get_cyp_los_by_section(cyp_los, c(3))),
  tar_target(cyp_los_histo_3, get_cyp_los_histo(cyp_los_3)),
  tar_target(cyp_llos_perc_3, get_llos_perc(cyp_los_3, 365)),
  tar_target(
    cyp_los_median_3,
    cyp_los_3 |>
      dplyr::summarise(
        value = median(los),
        .by = c(der_financial_year, icb_code)
      )
  ),
  tar_target(cyp_los_boxplot_3, get_standard_boxplot(cyp_los_median_3)),
  tar_target(
    cyp_los_median_table_3,
    get_icb_breakdown_table(cyp_los_median_3, icb_codes_names)
  ),



  ## Conversions ---------------------------------------------------------------
  #Mapping the key section transitions to text
  tar_target(conversion_map, get_conversions_mapped(cyp_conversions)),
  tar_target(
    conversion_map_cyp,
    get_conversions_mapped(cyp_conversions) |>
      filter(age_group != '25+')
  ),


  # Tables and plots for section conversions
  tar_target(
    mha_conv_age_tab,
    mha_conversion_table(conversion_map, age_group, "age_group")
  ),
  tar_target(
    mha_conv_age_plot,
    mha_conversion_bar_plot(mha_conv_age_tab, age_group, "age_group", "age group")
  ),

  tar_target(
    mha_conv_sex_tab,
    mha_conversion_table(conversion_map_cyp, gender, "gender")
  ),
  tar_target(
    mha_conv_sex_plot,
    mha_conversion_bar_plot(mha_conv_sex_tab, gender, "gender", "gender")
  ),

  tar_target(
    mha_conv_eth_tab,
    mha_conversion_table(conversion_map_cyp, ethnic_category, "ethnic_category")
  ),
  tar_target(
    mha_conv_eth_plot,
    mha_conversion_bar_plot(
      mha_conv_eth_tab,
      ethnic_category,
      "ethnic_category",
      "ethnic category"
    )
  ),

  tar_target(
    mha_conv_imd_tab,
    mha_conversion_table(conversion_map_cyp, imd_quintile, "imd_quintile")
  ),
  tar_target(
    mha_conv_imd_plot,
    mha_conversion_bar_plot(
      mha_conv_imd_tab,
      imd_quintile,
      "imd_quintile",
      "IMD quintile (2019)"
    )
  ),


  ## HONOS ---------------------------------------------------------------------
  tar_target(honos_flow_perc, get_honos_flow_perc(cyp_honos_summary)),
  tar_target(
    honos_flowchart,
    get_honos_numbers_flowchart(honos_flow_perc)
  ),
  tar_target(honos_histo, get_honos_histo(cyp_honos)),
  tar_target(honos_perc_worse, get_honos_perc_worse(cyp_honos)),
  tar_target(honos_scatter, get_honos_scatter(cyp_honos)),

  # 05. Breakdowns -------------------------------------------------------------
  tar_target(
    data_for_breakdowns,
    list(
      uec_mh_attends = uec_mh_attends,
      uec_mh_known = uec_mh_known,
      type1_mh_attends = type1_mh_attends,
      type1_mh_known = type1_mh_known,
      nhs111_mh_calls = nhs111_mh_calls |>
        dplyr::rename(attends = calls),
      cyp_redetentions = cyp_redetentions
    )
  ),
  tar_target(
    gender_breakdowns,
    get_breakdowns(
      data_for_breakdowns,
      type1_arrival_mode,
      uec_arrival_mode,
      gender_by_icb,
      "gender"
    )
  ),
  tar_target(
    age_breakdowns,
    get_breakdowns(
      data_for_breakdowns[!grepl("cyp", names(data_for_breakdowns))],
      type1_arrival_mode,
      uec_arrival_mode,
      age_by_icb,
      "age_group"
    )
  ),
  #  tar_target(cyp_age_breakdowns,
  #             get_breakdowns(data_for_breakdowns[grepl("cyp",
  #                                                       names(
  #                                                         data_for_breakdowns))],
  #                            type1_arrival_mode,
  #                            uec_arrival_mode,
  #                            cyp_age_by_icb,
  #                            "age_group")),
  tar_target(
    imd_breakdowns,
    get_breakdowns(
      data_for_breakdowns,
      type1_arrival_mode,
      uec_arrival_mode,
      imd_by_icb,
      "imd_decile"
    )
  ),
  tar_target(
    rural_breakdowns,
    #
    get_breakdowns(
      data_for_breakdowns[!grepl("redetentions", names(data_for_breakdowns))],
      type1_arrival_mode,
      uec_arrival_mode,
      rural_by_icb,
      "rural_urban"
    )
  ),
  tar_target(
    ethnic_breakdowns,
    # NHS111 data does not have ethnic category, so
    # have excluded this from the list
    get_breakdowns(
      data_for_breakdowns[!grepl("nhs111", names(data_for_breakdowns))],
      type1_arrival_mode,
      uec_arrival_mode,
      ethnicity_by_icb_by_year,
      "ethnic_category"
    )
  ),

  # 06. Plots ------------------------------------------------------------------
  ## ED waiting times ----------------------------------------------------------
  tar_target(ae_times_assess, get_ed_times_assess(ae_times)),
  tar_target(ae_times_treat, get_ed_times_treat(ae_times)),
  tar_target(ae_times_conclude, get_ed_times_conclude(ae_times)),
  tar_target(ae_times_depart, get_ed_times_depart(ae_times)),
  tar_target(
    ae_times_table,
    get_ae_times_table(
      ae_times_assess,
      ae_times_treat,
      ae_times_conclude,
      ae_times_depart
    )
  ),

  tar_target(ae_times_assess_plot, ed_times_assess_plot(ae_times_assess)),
  tar_target(ae_times_treat_plot, ed_times_treat_plot(ae_times_treat)),
  tar_target(
    ae_times_conclude_plot,
    ed_times_conclude_plot(ae_times_conclude)
  ),
  tar_target(ae_times_depart_plot, ed_times_depart_plot(ae_times_depart)),

  ## Frequent fliers -----------------------------------------------------------
  tar_target(ae_freq_data, get_ed_freq_data(ae_freq)),
  tar_target(ae_freq_boxplot, ed_freq_boxplot(ae_freq_data)),
  tar_target(
    ae_freq_table,
    get_icb_breakdown_table(
      ae_freq_data |>
        ungroup() |>
        rename(icb_code = icb23cd, value = perc_freq),
      icb_codes_names
    )
  ),

  tar_target(nhs111_freq_data, get_ed_freq_data(nhs111_freq)),
  tar_target(
    nhs111_freq_boxplot,
    ed_freq_boxplot(
      nhs111_freq_data,
      "NHS 111 calls",
      "patients calling for MH related reasons"
    )
  ),
  tar_target(
    nhs111_freq_table,
    get_icb_breakdown_table_111(
      nhs111_freq_data |>
        ungroup() |>
        rename(icb_code = icb23cd, value = perc_freq),
      icb_codes_names
    )
  ),

  ## Arrival mode --------------------------------------------------------------
  tar_target(ae_trans_barplot, get_ed_transp_colplot(ae_summ_transp)),
  tar_target(ae_trans_trends, get_ed_transp_trends(ae_transp_trends)),
  tar_target(
    uec_trans_barplot,
    get_ed_transp_colplot(uec_summ_transp, "UEC")
  ),
  tar_target(
    uec_trans_trends,
    get_ed_transp_trends(uec_transp_trends, "UEC")
  ),

  tar_target(ed_left_chart, ed_left_plot(ae_left_summary)),
  tar_target(uec_left_chart, ed_left_plot(uec_left_summary, "UEC")),

  # Overlayed bar chart for time of arrival to AE
  tar_target(ae_toa_plot, get_overlay_barchart_toa(ae_toa_summary)),
  tar_target(
    uec_toa_plot,
    get_overlay_barchart_toa(uec_toa_summary, "UEC")
  ),

  ## Breakdowns ----------------------------------------------------------------
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
  #  tar_target(
  #    cyp_age_plot,
  #    purrr::map(
  #      cyp_age_breakdowns,
  #      ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "age_group")
  #    )
  #  ),
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

  # New IMD plots
  tar_target(ae_attends_imd, imd_plot2(imd_breakdowns$type1_mh_attends)),
  tar_target(uec_attends_imd, imd_plot2(imd_breakdowns$uec_mh_attends)),
  tar_target(nhs111_calls_imd, imd_plot2(imd_breakdowns$nhs111_mh_calls)),
  tar_target(
    cyp_redetentions_imd,
    imd_plot2(imd_breakdowns$cyp_redetentions)
  ),



  ## Average attendance rate per 100000 ----------------------------------------
  # Type 1
  tar_target(
    avg_type1_mh_attends_rate,
    get_pop_average(pop_by_icb, type1_mh_attends)
  ),
  tar_target(
    avg_type1_mh_attends_rate_plot,
    get_avg_mh_attends_rate_plot(avg_type1_mh_attends_rate)
  ),

  # UEC
  tar_target(
    avg_uec_mh_attends_rate,
    get_pop_average(pop_by_icb, uec_mh_attends)
  ),
  tar_target(
    avg_uec_mh_attends_rate_plot,
    get_avg_mh_attends_rate_plot(avg_uec_mh_attends_rate)
  ),

  # NHS111
  tar_target(
    avg_nhs111_mh_calls_rate,
    get_pop_average(pop_by_icb, nhs111_mh_calls |>
                      dplyr::rename(attends = calls))
  ),
  tar_target(
    avg_nhs111_mh_calls_rate_plot,
    get_avg_mh_attends_rate_plot(avg_nhs111_mh_calls_rate)
  ),

  # redetentions
  tar_target(
    cyp_avg_redetentions_rate,
    get_pop_average(pop_by_icb, cyp_redetentions)
  ),
  tar_target(
    cyp_avg_redetentions_rate_plot,
    get_avg_mh_attends_rate_plot(cyp_avg_redetentions_rate)
  ),

  # 07. Maps -------------------------------------------------------------------

  # ICB total populations
  tar_target(pop_by_icb, get_icb_pop_total(gender_by_icb)),
  tar_target(icb_rates_ed, get_icb_att_rates(data_ed, pop_by_icb)),
  tar_target(icb_rates_uec, get_icb_att_rates(data_uec, pop_by_icb)),

  # load icb april 2023 boundaries
  tar_target(
    icb_boundary,
    get_icb_map(
      "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Integrated_Care_Boards_April_2023_EN_BGC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
    )
  ),
  # 23/24 mh attendance rate ED by ICB map
  tar_target(icb_ed_map_2324, map_icb_allmh(icb_boundary, icb_rates_ed)),
  tar_target(
    icb_uec_map_2324,
    map_icb_allmh_uec(icb_boundary, icb_rates_uec)
  ),
  tar_target(
    icb_111_map_2122,
    map_icb_allmh_111(icb_boundary, nhs111_mh_calls_rate, "2020/21")
  )
  ,

  # 08. DTT (Heather) -------------------------------------------------------------------
  tarchetypes::tar_file(DTT_filepath, "data/cyp_DTT.csv"),

  tar_target(DTT, load_csv(DTT_filepath)),

  tar_target(custom_colours, get_custom_colours()),

  # Add the original FY target
  tar_target(table_DTT_FY, get_table_DTT_FY(DTT)),
  # DTT here not data b/c that's what it's called in tar_read() function

  # Add the gender target
  tar_target(DTT_gender_FY, get_table_DTT_gender_FY(DTT)),

  # Add the age group target
  tar_target(DTT_age_group_FY, get_table_DTT_age_group_FY(DTT)),

  # Add the ethnic category target
  tar_target(DTT_ethnic_FY, get_table_DTT_ethnic_FY(DTT)),

  # Add the IMD target
  tar_target(DTT_IMD_FY, get_table_DTT_IMD_FY(DTT)),

  #For the charts - pull the name from the table above into the target

  #Chart for Overview
  tar_target(chart_DTT_FY, get_chart_DTT_FY(table_DTT_FY)),
  #, custom_colours$su_colours)),

  #Chart for gender
  tar_target(
    chart_DTT_gender_FY,
    get_chart_DTT_gender_FY(DTT_gender_FY, table_DTT_FY, custom_colours$su_colours)
  ),

  #Chart for age group
  tar_target(
    chart_DTT_age_group_FY,
    get_chart_DTT_age_group_FY(DTT_age_group_FY, table_DTT_FY, custom_colours$su_colours)
  ),

  #Chart for ethnic category
  tar_target(
    chart_DTT_ethnic_FY,
    get_chart_DTT_ethnic_FY(DTT_ethnic_FY, table_DTT_FY, custom_colours$su_colours)
  ),

  #Chart for IMD
  tar_target(
    chart_DTT_IMD_FY,
    get_chart_DTT_IMD_FY(DTT_IMD_FY, custom_colours$imd_colours_custom)
  ),

  #Chart 2 for Overall
  tar_target(
    table_DTT_FY_with_admissions,
    get_table_DTT_FY_with_admissions(DTT)
  ),

  tar_target(
    chart_admissions_vs_distance,
    get_chart_admissions_vs_distance(table_DTT_FY_with_admissions, custom_colours$su_colours)
  ),

  #Subgroups tables
  tar_target(
    table_DTT_gender_FY_with_admissions,
    get_table_DTT_gender_FY_with_admissions(DTT)
  ),

  tar_target(
    table_DTT_age_group_FY_with_admissions,
    get_table_DTT_age_group_FY_with_admissions(DTT)
  ),

  tar_target(
    table_DTT_ethnic_FY_with_admissions,
    get_table_DTT_ethnic_FY_with_admissions(DTT)
  ),

  tar_target(
    table_DTT_IMD_FY_with_admissions,
    get_table_DTT_IMD_FY_with_admissions(DTT)
  ),

  #Charts
  tar_target(
    chart_DTT_gender_FY_with_admissions,
    get_chart_admissions_vs_distance_gender(
      table_DTT_gender_FY_with_admissions,
      custom_colours$su_colours
    )
  ),

  tar_target(
    chart_DTT_age_group_FY_with_admissions,
    get_chart_admissions_vs_distance_age(
      table_DTT_age_group_FY_with_admissions,
      custom_colours$su_colours
    )
  ),

  tar_target(
    chart_DTT_ethnic_FY_with_admissions,
    get_chart_admissions_vs_distance_ethnic(
      table_DTT_ethnic_FY_with_admissions,
      custom_colours$su_colours
    )
  ),

  tar_target(
    chart_DTT_IMD_FY_with_admissions,
    get_chart_admissions_vs_distance_IMD(table_DTT_IMD_FY_with_admissions)
  ),

  #DTT Part 2
  #Make a table with columns ICB, FY, and Average Distance
  tar_target(DTT_ICB_FY, get_table_DTT_ICB_FY(DTT)),

  #Make a table of average DTT and admissions by age group and gender by FY
  tar_target(
    DTT_admissions_gender_age_group_FY,
    get_table_DTT_admissions_gender_age_group_FY(DTT)
  ),

  #Make a table of average DTT by age group and gender by FY
  tar_target(
    DTT_gender_age_group_IMD_FY,
    get_table_DTT_gender_age_group_IMD_FY(DTT)
  ),

  #Make a table of average DTT over last 5 years by age group and gender
  tar_target(
    DTT_admissions_gender_age_group_over_5_years,
    get_table_DTT_admissions_gender_age_group_over_5_years(DTT)
  ),

  #Make a table of average DTT over last 5 years by age group gender ethnicity and IMD
  tar_target(
    DTT_admissions_gender_age_group_ethnicity_IMD_over_5_years,
    get_table_DTT_admissions_gender_age_group_ethnicity_IMD_over_5_years(DTT)
  ),

  #Make a heatmap of the subgroups
  tar_target(
    heatmap_DTT_subgroups,
    get_heatmap_DTT_subgroups(DTT_admissions_gender_age_group_ethnicity_IMD_over_5_years)
  ),

  # CYP versions of everything as required -------------------------------------

  # Population by gender and icb
  tar_target(
    cyp_gender_by_icb,
    cyp_get_gender_totals(
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
    cyp_population_by_lsoa,
    cyp_get_population_totals(
      population_2017_persons,
      population_2018_persons,
      population_2019_persons,
      population_2020_persons,
      population_2021,
      population_2022
    )
  ),

  tar_target(
    cyp_imd_by_icb,
    get_imd_totals(imd_url, cyp_population_by_lsoa, lsoa_to_icb)
  ),

  tar_target(
    cyp_rural_by_icb,
    get_rural_totals(rural_url, cyp_population_by_lsoa, lsoa_to_icb)
  ),

  # Ethnicity By ICB

  # import and wrangle 2011 ethnicity data
  tar_target(cyp_ethnicity2011_by_icb2024, cyp_create2011ethnicities()),
  # import and wrangle 2021 ethnicity data
  tar_target(cyp_ethnicity2021_by_icb2024, cyp_create2021ethnicities()),
  # join two data sets
  tar_target(
    cyp_ethnicity_by_icb,
    join_ethnicity(cyp_ethnicity2011_by_icb2024, cyp_ethnicity2021_by_icb2024)
  ),
  # impute ethnicity data for every year
  tar_target(
    cyp_ethnicity_by_icb_by_year,
    impute_annual_ethnicity(cyp_ethnicity_by_icb) |>
      dplyr::rename(
        ethnic_category = Ethnicity,
        fin_year = der_financial_year,
        count = Count
      ) |>
      dplyr::mutate(ethnic_category = tolower(ethnic_category))
  ),


  tarchetypes::tar_file(cyp_ae_times_filepath, "data/cyp_ae_waits_icb.csv"),
  tar_target(cyp_ae_times, load_csv(cyp_ae_times_filepath)),

  tarchetypes::tar_file(cyp_ae_diag_filepath, "data/cyp_ae_diag_icb.csv"),
  tar_target(
    cyp_ae_diag,
    load_csv(cyp_ae_diag_filepath) |>
      left_join(snomed_mh, by = c("ec_diagnosis_01" = "concept_id"))
  ),

  tarchetypes::tar_file(cyp_ae_freq_filepath, "data/cyp_ae_freqfly_icb.csv"),
  tar_target(cyp_ae_freq, load_csv(cyp_ae_freq_filepath)),

  tarchetypes::tar_file(cyp_ae_left_filepath, "data/cyp_ae_left_icb.csv"),
  tar_target(cyp_ae_left, load_csv(cyp_ae_left_filepath)),

  tarchetypes::tar_file(cyp_ae_toa_filepath, "data/cyp_ae_toa_icb.csv"),
  tar_target(cyp_ae_toa, load_csv(cyp_ae_toa_filepath)),

  # Full extracts
  tarchetypes::tar_file(cyp_data_ae_filepath, "data/cyp_ae_extract_full.csv"),
  tar_target(
    cyp_data_ae,
    load_csv(cyp_data_ae_filepath) |>
      dplyr::rename(imd_decile = index_of_multiple_deprivation_decile) |>
      dplyr::mutate(imd_decile = factor(imd_decile, levels = as.character(1:10))) |>
      # everything here is the new addition
      mutate(age_group = ifelse(
        test = age_group == "18-24",
        yes = "18-24",
        no = "0-17"
      )) |>
      group_by(
        age_group,
        icb23cd,
        icb23nm,
        imd_decile,
        rural_urban,
        gender,
        ethnic_category,
        ec_department_type,
        arrival_mode,
        admit_decision,
        disch_dest,
        mh_snomed,
        mhsds_flag,
        der_financial_year
      ) |>
      summarise(attends = sum(attends), cost = sum(cost)) |>
      ungroup()
  ),

  # Summary from other extracts
  tar_target(cyp_ae_summary, get_ae_summary(cyp_data_ae)),
  tar_target(cyp_uec_summary, get_uec_summary(cyp_data_uec)),

  tar_target(cyp_ae_summ_transp, get_ae_summ_transp(cyp_data_ae)),
  tar_target(cyp_ae_transp_trends, get_ae_amb_trends(cyp_data_ae)),

  tar_target(cyp_uec_summ_transp, get_ae_summ_transp(cyp_data_uec, c("03", "04", "3", "4"))),
  tar_target(cyp_uec_transp_trends, get_ae_amb_trends(cyp_data_uec, c("03", "04", "3", "4"))),

  tar_target(cyp_ae_toa_summary, ae_toa_grouped(cyp_ae_toa)),
  tar_target(cyp_uec_toa_summary, ae_toa_grouped(cyp_ae_toa, c("3", "4"))),

  tar_target(cyp_ae_left_summary, ae_left_grouped(cyp_ae_left)),
  tar_target(cyp_uec_left_summary, ae_left_grouped(cyp_ae_left, c("3", "4"))),

  ## Type 1 ED activity ---------------------------------------------------------
  tar_target(cyp_data_ed, get_ed_activity(cyp_data_ae)),

  # MH attends
  tar_target(cyp_type1_mh_attends, filter_mh_attends(cyp_data_ed)),
  tar_target(cyp_type1_perc_mh_attends, get_perc_mh_attends(cyp_data_ed)),
  tar_target(
    cyp_type1_mh_attends_boxplot,
    get_perc_mh_attends_boxplot(cyp_type1_perc_mh_attends, "Type 1")
  ),
  tar_target(
    cyp_type1_mh_attends_table,
    get_icb_breakdown_table(cyp_type1_perc_mh_attends, icb_codes_names)
  ),

  # MH known
  tar_target(cyp_type1_mh_known, filter_mh_known(cyp_data_ed)),
  tar_target(cyp_type1_perc_mh_known, get_perc_mh_known(cyp_data_ed)),
  tar_target(
    cyp_type1_mh_known_boxplot,
    get_perc_mh_known_boxplot(cyp_type1_perc_mh_known, "Type 1")
  ),
  tar_target(
    cyp_type1_mh_known_table,
    get_icb_breakdown_table(cyp_type1_perc_mh_known, icb_codes_names)
  ),

  ### Arrival mode
  tar_target(cyp_type1_arrival_mode, filter_arrival_mode(cyp_data_ed)),
  tar_target(cyp_uec_arrival_mode, filter_arrival_mode(cyp_data_uec)),

  ## UEC activity ---------------------------------------------------------------
  tar_target(cyp_data_uec, get_uec_activity(cyp_data_ae)),

  # MH attends
  tar_target(cyp_uec_mh_attends, filter_mh_attends(cyp_data_uec)),
  tar_target(cyp_uec_perc_mh_attends, get_perc_mh_attends(cyp_data_uec)),
  tar_target(
    cyp_uec_mh_attends_boxplot,
    get_perc_mh_attends_boxplot(cyp_uec_perc_mh_attends, "Type 3 and 4")
  ),
  tar_target(
    cyp_uec_mh_attends_table,
    get_icb_breakdown_table(cyp_uec_perc_mh_attends, icb_codes_names)
  ),

  # MH known
  tar_target(cyp_uec_mh_known, filter_mh_known(cyp_data_uec)),
  tar_target(cyp_uec_perc_mh_known, get_perc_mh_known(cyp_data_uec)),
  tar_target(
    cyp_uec_mh_known_boxplot,
    get_perc_mh_known_boxplot(cyp_uec_perc_mh_known, "Type 3 and 4")
  ),
  tar_target(
    cyp_uec_mh_known_table,
    get_icb_breakdown_table(cyp_uec_perc_mh_known, icb_codes_names)
  ),
  tar_target(
    cyp_data_for_breakdowns,
    list(
      uec_mh_attends = cyp_uec_mh_attends,
      uec_mh_known = cyp_uec_mh_known,
      type1_mh_attends = cyp_type1_mh_attends,
      type1_mh_known = cyp_type1_mh_known,
      cyp_redetentions = cyp_redetentions
    )
  ),

  tar_target(
    cyp_gender_breakdowns,
    get_breakdowns(
      cyp_data_for_breakdowns,
      cyp_type1_arrival_mode,
      cyp_uec_arrival_mode,
      cyp_gender_by_icb,
      "gender"
    )
  ),
  tar_target(
    cyp_age_breakdowns,
    get_breakdowns(
      cyp_data_for_breakdowns[!grepl("redetentions", names(cyp_data_for_breakdowns))],
      cyp_type1_arrival_mode,
      cyp_uec_arrival_mode,
      cyp_age_by_icb,
      "age_group"
    )
  ),
  tar_target(
    cyp_imd_breakdowns,
    get_breakdowns(
      cyp_data_for_breakdowns,
      cyp_type1_arrival_mode,
      cyp_uec_arrival_mode,
      cyp_imd_by_icb,
      "imd_decile"
    )
  ),
  tar_target(
    cyp_rural_breakdowns,
    get_breakdowns(
      cyp_data_for_breakdowns[!grepl("redetentions", names(cyp_data_for_breakdowns))],
      cyp_type1_arrival_mode,
      cyp_uec_arrival_mode,
      cyp_rural_by_icb,
      "rural_urban"
    )
  ),
  tar_target(
    cyp_ethnic_breakdowns,
    # NHS111 data does not have ethnic category, so
    # have excluded this from the list
    get_breakdowns(
      cyp_data_for_breakdowns[!grepl("nhs111", names(cyp_data_for_breakdowns))],
      cyp_type1_arrival_mode,
      cyp_uec_arrival_mode,
      cyp_ethnicity_by_icb_by_year,
      "ethnic_category"
    )
  ),

  ## ED waiting times ----------------------------------------------------------
  tar_target(cyp_ae_times_assess, get_ed_times_assess(cyp_ae_times)),
  tar_target(cyp_ae_times_treat, get_ed_times_treat(cyp_ae_times)),
  tar_target(cyp_ae_times_conclude, get_ed_times_conclude(cyp_ae_times)),
  tar_target(cyp_ae_times_depart, get_ed_times_depart(cyp_ae_times)),
  tar_target(
    cyp_ae_times_table,
    get_ae_times_table(
      cyp_ae_times_assess,
      cyp_ae_times_treat,
      cyp_ae_times_conclude,
      cyp_ae_times_depart
    )
  ),

  tar_target(
    cyp_ae_times_assess_plot,
    ed_times_assess_plot(cyp_ae_times_assess)
  ),
  tar_target(
    cyp_ae_times_treat_plot,
    ed_times_treat_plot(cyp_ae_times_treat)
  ),
  tar_target(
    cyp_ae_times_conclude_plot,
    ed_times_conclude_plot(cyp_ae_times_conclude)
  ),
  tar_target(
    cyp_ae_times_depart_plot,
    ed_times_depart_plot(cyp_ae_times_depart)
  ),

  ## Frequent fliers -----------------------------------------------------------
  tar_target(cyp_ae_freq_data, get_ed_freq_data(cyp_ae_freq)),
  tar_target(cyp_ae_freq_boxplot, ed_freq_boxplot(cyp_ae_freq_data)),
  tar_target(
    cyp_ae_freq_table,
    get_icb_breakdown_table(
      cyp_ae_freq_data |>
        ungroup() |>
        rename(icb_code = icb23cd, value = perc_freq),
      icb_codes_names
    )
  ),

  ## Arrival mode --------------------------------------------------------------
  tar_target(
    cyp_ae_trans_barplot,
    get_ed_transp_colplot(cyp_ae_summ_transp)
  ),
  tar_target(
    cyp_ae_trans_trends,
    get_ed_transp_trends(cyp_ae_transp_trends)
  ),
  tar_target(
    cyp_uec_trans_barplot,
    get_ed_transp_colplot(cyp_uec_summ_transp, "UEC")
  ),
  tar_target(
    cyp_uec_trans_trends,
    get_ed_transp_trends(cyp_uec_transp_trends, "UEC")
  ),

  tar_target(cyp_ed_left_chart, ed_left_plot(cyp_ae_left_summary)),
  tar_target(
    cyp_uec_left_chart,
    ed_left_plot(cyp_uec_left_summary, "UEC")
  ),

  # Overlayed bar chart for time of arrival to AE
  tar_target(
    cyp_ae_toa_plot,
    get_overlay_barchart_toa(cyp_ae_toa_summary)
  ),
  tar_target(
    cyp_uec_toa_plot,
    get_overlay_barchart_toa(cyp_uec_toa_summary, "UEC")
  ),

  ## Breakdowns ----------------------------------------------------------------
  tar_target(
    cyp_gender_plot,
    purrr::map(
      cyp_gender_breakdowns,
      ~ get_standard_line_for_breakdowns(., cyp_pop_by_icb, group = "gender")
    )
  ),
  tar_target(
    cyp_age_plot,
    purrr::map(
      cyp_age_breakdowns,
      ~ get_standard_line_for_breakdowns(., cyp_pop_by_icb, group = "age_group")
    )
  ),
  tar_target(
    cyp_imd_plot,
    purrr::map(
      cyp_imd_breakdowns,
      ~ get_standard_line_for_breakdowns(., cyp_pop_by_icb, group = "imd_decile")
    )
  ),
  tar_target(
    cyp_rural_plot,
    purrr::map(
      cyp_rural_breakdowns,
      ~ get_standard_line_for_breakdowns(., cyp_pop_by_icb, group = "rural_urban")
    )
  ),
  tar_target(
    cyp_ethnic_plot,
    purrr::map(
      cyp_ethnic_breakdowns,
      ~ get_standard_line_for_breakdowns(., cyp_pop_by_icb, group = "ethnic_category")
    )
  ),

  # New IMD plots
  tar_target(
    cyp_ae_attends_imd,
    imd_plot2(cyp_imd_breakdowns$type1_mh_attends)
  ),
  tar_target(
    cyp_uec_attends_imd,
    imd_plot2(cyp_imd_breakdowns$uec_mh_attends)
  ),

  ## Average attendance rate per 100000 ----------------------------------------
  # Type 1
  tar_target(
    cyp_avg_type1_mh_attends_rate,
    get_pop_average(cyp_pop_by_icb, cyp_type1_mh_attends)
  ),
  tar_target(
    cyp_avg_type1_mh_attends_rate_plot,
    get_avg_mh_attends_rate_plot(cyp_avg_type1_mh_attends_rate)
  ),

  # UEC
  tar_target(
    cyp_avg_uec_mh_attends_rate,
    get_pop_average(cyp_pop_by_icb, cyp_uec_mh_attends)
  ),
  tar_target(
    cyp_avg_uec_mh_attends_rate_plot,
    get_avg_mh_attends_rate_plot(cyp_avg_uec_mh_attends_rate)
  ),

  # ICB total populations
  tar_target(cyp_pop_by_icb, get_icb_pop_total(cyp_gender_by_icb)),
  tar_target(
    cyp_icb_rates_ed,
    get_icb_att_rates(cyp_data_ed, cyp_pop_by_icb)
  ),
  tar_target(
    cyp_icb_rates_uec,
    get_icb_att_rates(cyp_data_uec, cyp_pop_by_icb)
  ),

  # 23/24 mh attendance rate ED by ICB map
  tar_target(
    cyp_icb_ed_map_2324,
    map_icb_allmh(icb_boundary, cyp_icb_rates_ed)
  ),
  tar_target(
    cyp_icb_uec_map_2324,
    map_icb_allmh_uec(icb_boundary, cyp_icb_rates_uec)
  )
)
