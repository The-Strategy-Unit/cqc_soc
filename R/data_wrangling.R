# To get data from a xls file at a URL. Default is to read sheet 1, but can
# specify other sheet and to not skip any rows.
scrape_xls <- function(url, sheet = 1, skip = 0) {
  tmp = tempfile(fileext = "")

  download.file(url = url,
                destfile = tmp,
                mode = "wb")

  data <- readxl::read_excel(path = tmp,
                             sheet = sheet,
                             skip = skip) |>
    janitor::clean_names()

  return(data)

}

# To get data from the first excel file in a zipped folder at a URL. Default is
# to read sheet 1 and to not skip any rows.
scrape_zipped_xls <- function(url, sheet = 1, skip = 0) {
  download.file(url, "zippeddata.zip")
  unzip("zippeddata.zip")

  filename <- unzip("zippeddata.zip", list = TRUE) |>
    dplyr::select(Name) |>
    dplyr::pull()

  data <- readxl::read_excel(filename,
                             sheet = sheet,
                             skip = skip) |>
    janitor::clean_names()

  unlink("zippeddata.zip", recursive = TRUE)
  unlink(filename)

  return(data)

}



wrangle_gender_totals_18_20 <- function(data){

  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  gender <- name |>
    stringr::str_sub(17)

  wrangled_data <- data |>
    dplyr::mutate(year = year,
                  gender = gender) |>
    dplyr::select(year, lsoa_code, gender, count = all_ages)

  return(wrangled_data)
}

wrangle_gender_totals_21_22 <- function(data){

  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  wrangled_data <- data |>
    dplyr::mutate(
      females = raster::rowSums(dplyr::across(tidyselect::starts_with("f"))),
      males = raster::rowSums(dplyr::across(tidyselect::starts_with("m"))),
      year = year
    ) |>
    dplyr::select(year, lsoa_code = lsoa_2021_code, females, males) |>
    tidyr::pivot_longer(names_to = "gender",
                        values_to = "count",
                        cols = c(females, males))

  return(wrangled_data)

}

get_gender_totals <- function(population_2018_females,
                              population_2018_males,
                              population_2019_females,
                              population_2019_males,
                              population_2020_females,
                              population_2020_males,
                              population_2021,
                              population_2022) {

  combined <- rbind(wrangle_gender_totals_18_20(population_2018_females),
             wrangle_gender_totals_18_20(population_2018_males),
             wrangle_gender_totals_18_20(population_2019_females),
             wrangle_gender_totals_18_20(population_2019_males),
             wrangle_gender_totals_18_20(population_2020_females),
             wrangle_gender_totals_18_20(population_2020_males),
             wrangle_gender_totals_21_22(population_2021),
             wrangle_gender_totals_21_22(population_2022)
  )

  return(combined)
}


wrangle_age_totals_18_20 <- function(data){

  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  wrangled_data <- data |>
    tidyr::pivot_longer(names_to = "age",
                        values_to = "count",
                        cols = tidyselect::starts_with("x")) |>
    dplyr::mutate(age = readr::parse_number(age),
                  age_group = dplyr::case_when(age < 18 ~ "0-17",
                                               age < 22 ~ "18-21",
                                               age < 40 ~ "22-39",
                                               age < 65 ~ "40-64",
                                               age < 75 ~ "65-74",
                                               age < 120 ~ "75+",
                                               .default = "error"),
                  year = year) |>
    dplyr::summarise(count = sum(count), .by = c(year, lsoa_code, age_group)) |>
    dplyr::select(year, lsoa_code, age_group, count)

  return(wrangled_data)

}

wrangle_age_totals_21_22 <- function(data){

  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)


  wrangled_data <- data |>
    tidyr::pivot_longer(names_to = "category",
                        values_to = "count",
                        cols = tidyselect::starts_with(c("f", "m"))) |>
    dplyr::mutate(age = readr::parse_number(category),
                  age_group = dplyr::case_when(age < 18 ~ "0-17",
                                               age < 22 ~ "18-21",
                                               age < 40 ~ "22-39",
                                               age < 65 ~ "40-64",
                                               age < 75 ~ "65-74",
                                               age < 120 ~ "75+",
                                               .default = "error"),
                  year = year) |>
    dplyr::summarise(count = sum(count),
                     .by = c(year, age_group, lsoa_2021_code)) |>
    dplyr::select(year, lsoa_code = lsoa_2021_code, age_group, count)

  return(wrangled_data)
}

get_age_totals <- function(population_2018_females,
                              population_2018_males,
                              population_2019_females,
                              population_2019_males,
                              population_2020_females,
                              population_2020_males,
                              population_2021,
                              population_2022
                           ) {

  combined <- rbind(wrangle_age_totals_18_20(population_2018_females),
                    wrangle_age_totals_18_20(population_2018_males),
                    wrangle_age_totals_18_20(population_2019_females),
                    wrangle_age_totals_18_20(population_2019_males),
                    wrangle_age_totals_18_20(population_2020_females),
                    wrangle_age_totals_18_20(population_2020_males),
                    wrangle_age_totals_21_22(population_2021),
                    wrangle_age_totals_21_22(population_2022)
  )

  return(combined)
}
# get_file_from_url_zipped <- function(url){
#
#   download.file(url, "zippeddata.zip")
#   unzip("zippeddata.zip")
#
#   filename <- unzip("zippeddata.zip", list = TRUE) |>
#     dplyr::select(Name) |>
#     dplyr::pull()
#
#   return(filename)
#
# }
#
# tidy_after_unzip <- function(filename){
#   unlink("zippeddata.zip", recursive = TRUE)
#   unlink(filename)
# }
#
# get_pop_by_gender_2018 <- function(url) {
#
#   filename <- get_file_from_url_zipped(url)
#
#   data <- data.frame()
#
#   for(i in c("Persons", "Females", "Males")) {
#
#     data_to_add <- readxl::read_excel(filename,
#                                       sheet = glue::glue("Mid-2018 {i}"),
#                                       skip = 4) |>
#       janitor::clean_names() |>
#       dplyr::mutate(type = i) |>
#       dplyr::filter(!is.na(lsoa)) |>
#       dplyr::select(lsoa_code = area_codes, all_ages, type)
#
#     data <- data |>
#       dplyr::bind_rows(data_to_add)
#   }
#
#   data <- data |>
#     tidyr::pivot_wider(names_from = "type",
#                        values_from = all_ages) |>
#     dplyr::mutate(year = "2018") |>
#     janitor::clean_names()
#
#   tidy_after_unzip(filename)
#
#   return(data)
#
# }
#
# get_pop_by_gender <- function(filename, year){
#
#   data <- data.frame()
#
#   for(i in c("Persons", "Females", "Males")) {
#     data_to_add <- readxl::read_excel(filename,
#                                       sheet = glue::glue("Mid-{year} {i}"),
#                                       skip = 4) |>
#       janitor::clean_names() |>
#       dplyr::mutate(type = i) |>
#       dplyr::select(lsoa_code, all_ages, type)
#
#     data <- data |>
#       dplyr::bind_rows(data_to_add)
#   }
#
#   data <- data |>
#     tidyr::pivot_wider(names_from = "type",
#                        values_from = all_ages) |>
#     dplyr::mutate(year = year) |>
#     janitor::clean_names()
#
#   return(data)
# }
#
# get_pop_by_gender_2019 <- function(url, year) {
#
#   filename <- get_file_from_url_zipped(url)
#
#   data <- get_pop_by_gender(filename, year)
#
#   tidy_after_unzip(filename)
#
#   return(data)
#
# }
#
# get_file_from_url <- function(url){
#   filename <- tempfile(fileext = "")
#
#   download.file(url = url,
#                 destfile = filename,
#                 mode = "wb")
#
#   return(filename)
# }
#
# get_pop_by_gender_2020 <- function(url, year) {
#   filename <- get_file_from_url(url)
#
#   data <- get_pop_by_gender(filename, year)
#
#   return(data)
#
# }
#
# get_pop_by_gender_2021_22 <- function(url, year){
#
#   filename <- get_file_from_url(url)
#
#   data <- readxl::read_excel(filename,
#                              sheet = glue::glue("Mid-{year} LSOA 2021"),
#                              skip = 3)  |>
#     janitor::clean_names() |>
#     dplyr::mutate(females = rowSums(dplyr::across(tidyselect::starts_with("f"))),
#                   males = rowSums(dplyr::across(tidyselect::starts_with("m"))),
#                   year = year) |>
#     dplyr::select(lsoa_code = lsoa_2021_code,
#                   "persons" = total,
#                   females,
#                   males,
#                   year)
#
# }
#
#
#
#
#
