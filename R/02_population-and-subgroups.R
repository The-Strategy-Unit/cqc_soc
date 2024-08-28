# To wrangle the gender data from the population files for 2018, 2019 and 2020:
wrangle_gender_totals_17_20 <- function(data) {
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

# To wrangle the gender data from the population files for 2021 and 2022:
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

# To put all the gender data together for financial years 2018/19 to 2022/13 and summarised
# by ICB:
get_gender_totals <- function(population_2017_females,
                              population_2017_males,
                              population_2018_females,
                              population_2018_males,
                              population_2019_females,
                              population_2019_males,
                              population_2020_females,
                              population_2020_males,
                              population_2021,
                              population_2022,
                              lsoa_to_icb) {
  # 2023 data not yet available, so currently use 2022:
  gender_totals_2023 <- wrangle_gender_totals_21_22(population_2022) |>
    dplyr::mutate(year = "2023")

  combined <- rbind(
    wrangle_gender_totals_17_20(population_2017_females),
    wrangle_gender_totals_17_20(population_2017_males),
    wrangle_gender_totals_17_20(population_2018_females),
    wrangle_gender_totals_17_20(population_2018_males),
    wrangle_gender_totals_17_20(population_2019_females),
    wrangle_gender_totals_17_20(population_2019_males),
    wrangle_gender_totals_17_20(population_2020_females),
    wrangle_gender_totals_17_20(population_2020_males),
    wrangle_gender_totals_21_22(population_2021),
    wrangle_gender_totals_21_22(population_2022),
    gender_totals_2023
  )  |>
    remove_welsh_lsoas() |>
    summarise_by_icb(lsoa_to_icb, "gender") |>
    add_financial_year() |>
    dplyr::select(fin_year, icb_code, gender, count) |>
    dplyr::mutate(gender = stringr::str_replace(gender, "males", "male"))

  return(combined)
}

remove_welsh_lsoas <- function(data) {
  filtered <- data |>
    dplyr::filter(!stringr::str_detect(lsoa_code, "W"))

  return(filtered)
}

# To wrangle the age data from the population files for 2018, 2019 and 2020:
wrangle_age_totals_17_20 <- function(data) {
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

# To wrangle the age data from the population files for 2021 and 2022:
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

# To put all the age group data together for financial years 2018/19 to 2022/13 and summarised
# by ICB:
get_age_totals <- function(population_2017_females,
                           population_2017_males,
                           population_2018_females,
                           population_2018_males,
                           population_2019_females,
                           population_2019_males,
                           population_2020_females,
                           population_2020_males,
                           population_2021,
                           population_2022,
                           lsoa_to_icb) {
  # 2023 data not yet available, so currently use 2022:
  age_totals_2023 <- wrangle_age_totals_21_22(population_2022) |>
    dplyr::mutate(year = "2023")

  combined <- rbind(
    wrangle_age_totals_17_20(population_2017_females),
    wrangle_age_totals_17_20(population_2017_males),
    wrangle_age_totals_17_20(population_2018_females),
    wrangle_age_totals_17_20(population_2018_males),
    wrangle_age_totals_17_20(population_2019_females),
    wrangle_age_totals_17_20(population_2019_males),
    wrangle_age_totals_17_20(population_2020_females),
    wrangle_age_totals_17_20(population_2020_males),
    wrangle_age_totals_21_22(population_2021),
    wrangle_age_totals_21_22(population_2022),
    age_totals_2023
  ) |>
    remove_welsh_lsoas() |>
    summarise_by_icb(lsoa_to_icb, "age_group") |>
    add_financial_year() |>
    dplyr::select(fin_year, icb_code, age_group, count)

  return(combined)
}

# To wrangle the population data from the population files for 2018, 2019 and
# 2020:
wrangle_population_totals_17_20 <- function(data) {
  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  wrangled_data <- data |>
    dplyr::mutate(year = year) |>
    dplyr::select(year, lsoa_code, count = all_ages)

  return(wrangled_data)

}

# To wrangle the population data from the population files for 2021 and 2022:
wrangle_population_totals_21_22 <- function(data) {
  name <- deparse(substitute(data))

  year <- name |>
    stringr::str_sub(12, 15)

  wrangled_data <- data |>
    dplyr::mutate(year = year) |>
    dplyr::select(year, lsoa_code = lsoa_2021_code, count = total)

  return(wrangled_data)

}

# To put all the population total data together for years 2017 to 2023:
get_population_totals <- function(population_2017_persons,
                                  population_2018_persons,
                                  population_2019_persons,
                                  population_2020_persons,
                                  population_2021,
                                  population_2022) {
  # 2023 data not yet available, so currently use 2022:
  population_totals_2023 <- wrangle_population_totals_21_22(population_2022) |>
    dplyr::mutate(year = "2023")

  combined <- rbind(
    wrangle_population_totals_17_20(population_2017_persons),
    wrangle_population_totals_17_20(population_2018_persons),
    wrangle_population_totals_17_20(population_2019_persons),
    wrangle_population_totals_17_20(population_2020_persons),
    wrangle_population_totals_21_22(population_2021),
    wrangle_population_totals_21_22(population_2022),
    population_totals_2023
  ) |>
    remove_welsh_lsoas()

  return(combined)
}

# To summarise IMD decile by ICB for financial years 2018/19 to 2022/13:
get_imd_totals <- function(imd_url, population_by_lsoa, lsoa_to_icb) {
  data <- imd_url |>
    scrape_xls("IMD2019") |>
    dplyr::rename(lsoa_code = lsoa_code_2011) |>
    dplyr::left_join(population_by_lsoa, "lsoa_code") |>
    summarise_by_icb(lsoa_to_icb, "index_of_multiple_deprivation_imd_decile") |>
    add_financial_year() |>
    dplyr::select(fin_year, icb_code, imd_decile = index_of_multiple_deprivation_imd_decile, count) |>
    dplyr::mutate(imd_decile = factor(imd_decile, levels = as.character(1:10)))

  return(data)
}

# To summarise rural vs urban by ICB for financial years 2018/19 to 2022/13:
get_rural_totals <- function(url, population_by_lsoa, lsoa_to_icb) {
  tmp <- tempfile(fileext = "")

  download.file(url = url,
                destfile = tmp,
                mode = "wb")

  rural <- readODS::read_ods(path = tmp,
                             sheet = "LSOA11",
                             skip = 2) |>
    janitor::clean_names() |>
    dplyr::rename(lsoa_code = lower_super_output_area_2011_code) |>
    dplyr::left_join(population_by_lsoa, "lsoa_code") |>
    remove_welsh_lsoas() |>
    summarise_by_icb(lsoa_to_icb, "rural_urban_classification_2011_2_fold") |>
    add_financial_year() |>
    dplyr::select(fin_year, icb_code, rural_urban = rural_urban_classification_2011_2_fold, count)

  return(rural)

}