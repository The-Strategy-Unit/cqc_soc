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
  "tidyverse",
  "readODS",
  "patchwork"))

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# End this file with a list of target objects.
list(
  # LSOA to ICBs
  tar_target(
    url_lsoa_2011,
    "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA11_SICBL22_ICB22_LAD22_EN_LU/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
  ),
  tar_target(
    url_lsoa_2021,
    "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA21_SICBL23_ICB23_LAD23_EN_LU/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"
  ),
  tar_target(
    lsoa_to_icb,
    get_lsoa_to_icb_map(url_lsoa_2011, url_lsoa_2021)
  ),

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

  # specific query data files
  tar_target(snomed_mh,
             load_snomed("data/ref_mh_snomed_ct.csv") |>
               select(2,3,5,6,8,13,16,19,20,23,49,61)),

  tar_target(ae_times,
             load_ae_times("data/ae_waits_icb.csv")),
  tar_target(ae_diag,
             load_ae_times("data/ae_diag_icb.csv") |>
               left_join(snomed_mh, by = c("ec_diagnosis_01" = "concept_id"))),
  tar_target(ae_freq,
             load_ae_times("data/ae_freqfly_icb.csv")),


  #### Plots ####

  tar_target(ae_times_plot,
             ed_times_plot(ae_times)),
  tar_target(ae_freq_boxplot,
             ed_freq_boxplot(ae_freq))


  )
