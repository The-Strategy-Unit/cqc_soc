library(targets)
# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(data_summary) to view the results.

# Set target options:
tar_option_set(
  packages = c( # Packages that your targets need for their tasks.
    "tidyverse"
  )
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# End this file with a list of target objects.
list(
  tar_target(population_2021_22_url,
             "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2021andmid2022/sapelsoasyoatablefinal.xlsx"),
  tar_target(population_2020_url,
             "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2020sape23dt2/sape23dt2mid2020lsoasyoaestimatesunformatted.xlsx"),
  tar_target(population_2019_url,
             "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2019sape22dt2/sape22dt2mid2019lsoasyoaestimatesunformatted.zip"),
  tar_target(population_2018_url,
             "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/mid2018sape21dt1a/sape21dt1amid2018on2019lalsoasyoaestimatesformatted.zip"),

  tar_target(pop_2018,
             get_pop_by_gender_2018(population_2018_url)),
  tar_target(pop_2019,
             get_pop_by_gender_2019(population_2019_url, "2019")),
  tar_target(pop_2020,
             get_pop_by_gender_2020(population_2020_url, "2020")),
  tar_target(pop_2021,
             get_pop_by_gender_2021_22(population_2021_22_url, "2021")
             ),
  tar_target(pop_2022,
             get_pop_by_gender_2021_22(population_2021_22_url, "2022")),
  tar_target(pop,
             rbind(pop_2018,
                   pop_2019,
                   pop_2020,
                   pop_2021,
                   pop_2020))

)
