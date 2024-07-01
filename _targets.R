library(targets)
# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(data_summary) to view the results.

# Set target options:
tar_option_set(packages = c(# Packages that your targets need for their tasks.
  "tidyverse"))

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# End this file with a list of target objects.
list(
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
        dplyr::rename(lsoa_code = area_codes)
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
  # Population by gender
  tar_target(gender_totals,
             get_gender_totals(population_2018_females,
                               population_2018_males,
                               population_2019_females,
                               population_2019_males,
                               population_2020_females,
                               population_2020_males,
                               population_2021,
                               population_2022)
             ),
  # Population by age
  tar_target(age_totals,
             get_age_totals(population_2018_females,
                               population_2018_males,
                               population_2019_females,
                               population_2019_males,
                               population_2020_females,
                               population_2020_males,
                               population_2021,
                               population_2022
                               )
  )



)
