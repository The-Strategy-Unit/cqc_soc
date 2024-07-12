# To get data from a xls file at a URL. Default is to read sheet 1 from row 1,
# but can specify other sheet number and number of rows to skip.
scrape_xls <- function(url, sheet = 1, skip = 0) {
  tmp <- tempfile(fileext = "")

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
# to read sheet 1 from row 1, but can specify other sheet number and number of
# rows to skip.
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

# To wrangle the gender data from the population files for 2018, 2019 and 2020:
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
get_gender_totals <- function(population_2018_females,
                              population_2018_males,
                              population_2019_females,
                              population_2019_males,
                              population_2020_females,
                              population_2020_males,
                              population_2021,
                              population_2022,
                              lsoa_to_icb) {
  combined <- rbind(
    wrangle_gender_totals_18_20(population_2018_females),
    wrangle_gender_totals_18_20(population_2018_males),
    wrangle_gender_totals_18_20(population_2019_females),
    wrangle_gender_totals_18_20(population_2019_males),
    wrangle_gender_totals_18_20(population_2020_females),
    wrangle_gender_totals_18_20(population_2020_males),
    wrangle_gender_totals_21_22(population_2021),
    wrangle_gender_totals_21_22(population_2022)
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
get_age_totals <- function(population_2018_females,
                           population_2018_males,
                           population_2019_females,
                           population_2019_males,
                           population_2020_females,
                           population_2020_males,
                           population_2021,
                           population_2022,
                           lsoa_to_icb) {
  combined <- rbind(
    wrangle_age_totals_18_20(population_2018_females),
    wrangle_age_totals_18_20(population_2018_males),
    wrangle_age_totals_18_20(population_2019_females),
    wrangle_age_totals_18_20(population_2019_males),
    wrangle_age_totals_18_20(population_2020_females),
    wrangle_age_totals_18_20(population_2020_males),
    wrangle_age_totals_21_22(population_2021),
    wrangle_age_totals_21_22(population_2022)
  ) |>
    remove_welsh_lsoas() |>
    summarise_by_icb(lsoa_to_icb, "age_group") |>
    add_financial_year() |>
    dplyr::select(fin_year, icb_code, age_group, count)

  return(combined)
}

# To wrangle the lsoa to icb data from the files for 2022 and 2023 icbs:
wrangle_lsoa <- function(url_name) {
  name <- deparse(substitute(url_name))

  year <- name |>
    stringr::str_sub(10, 13)

  data <- sf::st_read(url_name) |>
    tibble::tibble() |>
    janitor::clean_names() |>
    dplyr::mutate(lsoa_year = year)

}

# To create the key from lsoa to icb. Both 2011 and 2021 LSOAs are mapped to
# 2023 ICBs.
get_lsoa_to_icb_key <- function(lsoa_11_to_icb_23, lsoa_21_to_icb_23) {
  lsoa_11_to_icb_23_wrangled <- lsoa_11_to_icb_23 |>
    dplyr::mutate(lsoa_year = "2011") |>
    dplyr::select(
      lsoa_year,
      lsoa_code = lsoa11cd,
      icb_code = icb23cd,
      icb_name = icb23nm
    )

  lsoa_21_to_icb_23_wrangled <- lsoa_21_to_icb_23 |>
    dplyr::mutate(lsoa_year = "2021") |>
    dplyr::select(
      lsoa_year,
      lsoa_code = lsoa21cd,
      icb_code = icb23cd,
      icb_name = icb23nm
    )

  lsoa_to_icb <- lsoa_11_to_icb_23_wrangled |>
    rbind(lsoa_21_to_icb_23_wrangled)

  return(lsoa_to_icb)

}

# To summarise data across ICBs:
summarise_by_icb <- function(data, lsoa_to_icb, group) {
  summarised_data <- data |>
    dplyr::mutate(lsoa_year = ifelse(as.numeric(year) < 2021,
                                     # LSOAs can change with a new
                                     # census, so this ensures that we
                                     # use the correct LSOA to ICB map.
                                     # ICBs can also change over time,
                                     # but this has already been
                                     # accounted for and detailed in
                                     # get_lsoa_to_icb_map() above.
                                     "2011",
                                     "2021")) |>
    dplyr::left_join(lsoa_to_icb, by = c("lsoa_code", "lsoa_year")) |>
    dplyr::summarise(count = sum(count),
                     .by = c(year, icb_code, !!rlang::sym(group)))

  return(summarised_data)
}

# To wrangle the population data from the population files for 2018, 2019 and
# 2020:
wrangle_population_totals_18_20 <- function(data) {
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

# To put all the population total data together for years 2018 to 2022:
get_population_totals <- function(population_2018_persons,
                                  population_2019_persons,
                                  population_2020_persons,
                                  population_2021,
                                  population_2022) {
  combined <- rbind(
    wrangle_population_totals_18_20(population_2018_persons),
    wrangle_population_totals_18_20(population_2019_persons),
    wrangle_population_totals_18_20(population_2020_persons),
    wrangle_population_totals_21_22(population_2021),
    wrangle_population_totals_21_22(population_2022)
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
    dplyr::select(fin_year,
                  icb_code,
                  imd_decile = index_of_multiple_deprivation_imd_decile,
                  count) |>
    dplyr::mutate(imd_decile = as.character(imd_decile))

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
    dplyr::select(fin_year,
                  icb_code,
                  rural_urban = rural_urban_classification_2011_2_fold,
                  count)

  return(rural)

}

# Add financial year
add_financial_year <- function(data) {
  data <- data |>
    dplyr::mutate(year_plus_one = stringr::str_sub(as.numeric(year) + 1, 3, 4),
                  fin_year = glue::glue("{year}/{year_plus_one}"))

  return(data)
}

# load specific reference and query files
load_csv <- function(fileloc) {
  data <- read.csv(fileloc) |>
    janitor::clean_names()
}

# AE summary tables
get_ae_summary <- function(tarobj) {
  data <-  tarobj |>
    filter(ec_department_type == '01') |>
    group_by(der_financial_year) |>
    summarise(all = sum(attends),
              mh = sum(if_else(mh_snomed == 1, attends,0)),
              all_cost = sum(cost),
              mh_cost = sum(if_else(mh_snomed == 1, cost,0))) |>
    mutate(mh_perc = round(mh/all*100,2))

return(data)
}

get_ae_summ_transp <- function(tarobj) {
  tarobj |>
    filter(der_financial_year == '2023/24', arrival_mode != 'NULL', ec_department_type == '01') |>
    group_by(mh_snomed, arrival_mode) |>
    summarise(attends = sum(attends)) |>
    group_by(mh_snomed) |>
    mutate(perc = attends/sum(attends)*100)
}


# To get Type 3 and Type 4 attendances:
get_uec_activity <- function(data){

  filtered <- data |>
    dplyr::filter(ec_department_type %in% c("03", "04")) |>
    dplyr::rename(icb_code = icb23cd,
           icb_name = icb23nm)

  return(filtered)

}

# To get percentage of MH attendances by ICB and financial year:
get_perc_mh_attends <- function(data) {
  mh_attends <- data |>
    dplyr::summarise(mh_attends = sum(if_else(mh_snomed == 1, attends, 0)),
              attends = sum(attends),
              .by = c(icb_code, der_financial_year)) |>
    PHEindicatormethods::phe_proportion(mh_attends, attends, multiplier = 100)

  return(mh_attends)
}

# To get percentage of MH attendances that were known to specialist services by
# ICB and financial year:
get_perc_mh_known <- function(data) {
  mh_known <- data |>
    dplyr::filter(mh_snomed == 1) |> # attends due to MH
    dplyr::summarise(mh_known = sum(dplyr::if_else(mhsds_flag == 1, attends, 0)),
                     attends = sum(attends),
                     .by = c(icb_code, der_financial_year)) |>
    PHEindicatormethods::phe_proportion(mh_known, attends, multiplier = 100)

  get_perc_mh_attends_boxplot(mh_known)

  return(mh_known)}

# To create a key from ICB codes to names:
get_icb_codes_names <- function(data){
  key <- data |>
    select(icb_code, icb_name) |>
    distinct()

  return(key)
}

# Total ICB population with 23/24 imputed (from 22/23)
get_icb_pop_total <- function(tarobj){
  dat1 <- tarobj |>
    summarise(pop = sum(count),
              .by = c(icb_code, fin_year))
  dat2 <- tarobj |>
    summarise(pop = sum(count),
              .by = c(icb_code, fin_year)) |>
    filter(fin_year == '2022/23') |>
    mutate(fin_year = '2023/24')

  data <- rbind(dat1, dat2)

  return(data)

}

# To get Type 1 attendances:
get_ed_activity <- function(data){

  filtered <- data |>
    dplyr::filter(ec_department_type == "01")

  return(filtered)

}

## type 1 MH attendance rates total by ICB
get_icb_att_rates <- function(tarobj1,tarobj2){
  tarobj1 |>
    filter(mh_snomed == 1) |>
    summarise(attends = sum(attends),
              .by = c(icb23cd, der_financial_year)) |>
    left_join(tarobj2, by = c("icb23cd" = "icb_code", "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(x=attends, n=pop, confidence = 0.95, multiplier = 100000)

}

# To get a breakdown by a specified group:
get_breakdown <- function(data_filtered, data_population, group){
  data_population_agg <- data_population |> # currently at ICB level
    dplyr::summarise(count = sum(count),
              .by = c(fin_year, !!sym(group)))

  data <- data_filtered |>
    dplyr::filter(der_financial_year != "2023/24" & !!sym(group) != "NULL") |>
    dplyr::summarise(attends = sum(attends),
              .by = c(der_financial_year, !!sym(group))) |>
    dplyr::left_join(data_population_agg,
              by = c(group, "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = count,
      confidence = 0.95,
      multiplier = 100000
    )

  return(data)

}

# To filter for MH attendances:
filter_mh_attends <- function(data){
  data_filtered <- data |>
    dplyr::filter(mh_snomed == 1)

  return(data_filtered)
}