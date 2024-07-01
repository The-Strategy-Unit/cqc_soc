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

  data <- readxl::read_excel(filename, sheet = sheet, skip = skip) |>
    janitor::clean_names()

  unlink("zippeddata.zip", recursive = TRUE)
  unlink(filename)

  return(data)

}



wrangle_gender_totals_18_20 <- function(data) {
  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  gender <- name |>
    stringr::str_sub(17)

  wrangled_data <- data |>
    dplyr::mutate(year = year, gender = gender) |>
    dplyr::select(year, lsoa_code, gender, count = all_ages)

  return(wrangled_data)
}

wrangle_gender_totals_21_22 <- function(data) {
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
    tidyr::pivot_longer(
      names_to = "gender",
      values_to = "count",
      cols = c(females, males)
    )

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
  combined <- rbind(
    wrangle_gender_totals_18_20(population_2018_females),
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


wrangle_age_totals_18_20 <- function(data) {
  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  wrangled_data <- data |>
    tidyr::pivot_longer(
      names_to = "age",
      values_to = "count",
      cols = tidyselect::starts_with("x")
    ) |>
    dplyr::mutate(
      age = readr::parse_number(age),
      age_group = dplyr::case_when(
        age < 18 ~ "0-17",
        age < 22 ~ "18-21",
        age < 40 ~ "22-39",
        age < 65 ~ "40-64",
        age < 75 ~ "65-74",
        age < 120 ~ "75+",
        .default = "error"
      ),
      year = year
    ) |>
    dplyr::summarise(count = sum(count),
                     .by = c(year, lsoa_code, age_group)) |>
    dplyr::select(year, lsoa_code, age_group, count)

  return(wrangled_data)

}

wrangle_age_totals_21_22 <- function(data) {
  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  wrangled_data <- data |>
    tidyr::pivot_longer(
      names_to = "category",
      values_to = "count",
      cols = tidyselect::starts_with(c("f", "m"))
    ) |>
    dplyr::mutate(
      age = readr::parse_number(category),
      age_group = dplyr::case_when(
        age < 18 ~ "0-17",
        age < 22 ~ "18-21",
        age < 40 ~ "22-39",
        age < 65 ~ "40-64",
        age < 75 ~ "65-74",
        age < 120 ~ "75+",
        .default = "error"
      ),
      year = year
    ) |>
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
                           population_2022) {
  combined <- rbind(
    wrangle_age_totals_18_20(population_2018_females),
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

wrangle_lsoa <- function(url_name) {

  name <- deparse(substitute(url_name))

  year <- name |>
    stringr::str_sub(10, 13)

  data <- sf::st_read(url_name) |>
    tibble::tibble() |>
    janitor::clean_names() |>
    dplyr::mutate(lsoa_year = year)

}

get_lsoa_to_icb_map <- function(url_lsoa_2011, url_lsoa_2021){

  lsoa_2011 <- wrangle_lsoa(url_lsoa_2011) |>
    dplyr::mutate(icb = dplyr::case_when(icb22cd == "E54000052" ~ "E54000052",
                                         icb22cd == "E54000053" ~ "E54000064",
                                         .default = icb22cd
    )) |>
    dplyr::select(lsoa_year,
                  lsoa_code = lsoa11cd,
                  icb)

  lsoa_2021 <- wrangle_lsoa(url_lsoa_2021)  |>
    dplyr::select(lsoa_year,
                  lsoa_code = lsoa21cd,
                  icb = icb23cd)

  lsoa_to_icb <- rbind(lsoa_2011,
                       lsoa_2021)

  return(lsoa_to_icb)

}

summarise_by_icb <- function(data, lsoa_to_icb, group){
  data |>
    dplyr::mutate(lsoa_year = ifelse(as.numeric(year) < 2021,
                                     "2011",
                                     "2021")) |>
    dplyr::left_join(lsoa_to_icb, by = c("lsoa_code", "lsoa_year"))|>
    dplyr::summarise(count = sum(count),
                     .by = c(year, icb, !!rlang::sym(group)))
}