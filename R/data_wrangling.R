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
    dplyr::mutate(lsoa_year = ifelse(as.numeric(year) < 2021, # LSOAs can change with a new
                                     # census, so this ensures that we
                                     # use the correct LSOA to ICB map.
                                     # ICBs can also change over time,
                                     # but this has already been
                                     # accounted for and detailed in
                                     # get_lsoa_to_icb_map() above.
                                     "2011", "2021")) |>
    dplyr::left_join(lsoa_to_icb, by = c("lsoa_code", "lsoa_year")) |>
    dplyr::summarise(count = sum(count),
                     .by = c(year, icb_code, !!rlang::sym(group)))

  return(summarised_data)
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

# Add financial year
add_financial_year <- function(data) {
  data <- data |>
    dplyr::mutate(
      year_plus_one = stringr::str_sub(as.numeric(year) + 1, 3, 4),
      fin_year = glue::glue("{year}/{year_plus_one}")
    )

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
    summarise(
      all = sum(attends),
      mh = sum(if_else(mh_snomed == 1, attends, 0)),
      all_cost = sum(cost),
      mh_cost = sum(if_else(mh_snomed == 1, cost, 0))
    ) |>
    mutate(mh_perc = round(mh / all * 100, 2))

  return(data)
}

get_uec_summary <- function(tarobj) {
  data <-  tarobj |>
    filter(ec_department_type %in% c('03','04')) |>
    group_by(der_financial_year) |>
    summarise(
      all = sum(attends),
      mh = sum(if_else(mh_snomed == 1, attends, 0)),
      all_cost = sum(cost),
      mh_cost = sum(if_else(mh_snomed == 1, cost, 0))
    ) |>
    mutate(mh_perc = round(mh / all * 100, 2))

  return(data)
}

get_ae_summ_transp <- function(tarobj, type = "01") {

  tarobj |>
    filter(der_financial_year == '2023/24',
           arrival_mode != 'NULL',
           ec_department_type %in% type) |>
    group_by(mh_snomed, arrival_mode) |>
    summarise(attends = sum(attends)) |>
    group_by(mh_snomed) |>
    mutate(perc = attends / sum(attends) * 100)
}

get_ae_amb_trends <- function(tarobj, type = "01") {
  tarobj |>
    filter(arrival_mode != 'NULL',
           ec_department_type %in% type) |>
    group_by(mh_snomed, arrival_mode, der_financial_year) |>
    summarise(attends = sum(attends)) |>
    group_by(mh_snomed, der_financial_year) |>
    mutate(perc = attends / sum(attends) * 100)
}


# To get Type 3 and Type 4 attendances:
get_uec_activity <- function(data) {
  filtered <- data |>
    dplyr::filter(ec_department_type %in% c("03", "04")) |>
    dplyr::rename(icb_code = icb23cd, icb_name = icb23nm)

  return(filtered)

}

# To get percentage of MH attendances by ICB and financial year:
get_perc_mh_attends <- function(data) {
  mh_attends <- data |>
    dplyr::summarise(
      mh_attends = sum(if_else(mh_snomed == 1, attends, 0)),
      attends = sum(attends),
      .by = c(icb_code, der_financial_year)
    ) |>
    PHEindicatormethods::phe_proportion(mh_attends, attends, multiplier = 100)

  return(mh_attends)
}

# To get percentage of MH attendances that were known to specialist services by
# ICB and financial year:
get_perc_mh_known <- function(data) {
  mh_known <- data |>
    dplyr::filter(mh_snomed == 1) |> # attends due to MH
    dplyr::summarise(
      mh_known = sum(dplyr::if_else(mhsds_flag == 1, attends, 0)),
      attends = sum(attends),
      .by = c(icb_code, der_financial_year)
    ) |>
    PHEindicatormethods::phe_proportion(mh_known, attends, multiplier = 100)

  return(mh_known)
}

# To create a key from ICB codes to names:
get_icb_codes_names <- function(data) {
  key <- data |>
    select(icb_code, icb_name) |>
    distinct()

  return(key)
}

# Total ICB population with 23/24 imputed (from 22/23)
get_icb_pop_total <- function(tarobj) {
  data <- tarobj |>
    summarise(pop = sum(count), .by = c(icb_code, fin_year))

  return(data)

}

# To get Type 1 attendances:
get_ed_activity <- function(data) {
  filtered <- data |>
    dplyr::filter(ec_department_type == "01") |>
    dplyr::rename(icb_code = icb23cd, icb_name = icb23nm)

  return(filtered)

}

## MH attendance rates total by ICB
get_icb_att_rates <- function(tarobj1, tarobj2) {
  tarobj1 |>
    filter(mh_snomed == 1) |>
    summarise(attends = sum(attends),
              .by = c(icb_code, der_financial_year)) |>
    left_join(tarobj2,
              by = c("icb_code" = "icb_code", "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = pop,
      confidence = 0.95,
      multiplier = 100000
    )

}

## MH call rates to 111, total by ICB
get_icb_111_rates <- function(tarobj1, tarobj2) {
  tarobj1 |>
    filter(mh_symptom == 1) |>
    summarise(attends = sum(calls),
              .by = c(icb_code, der_financial_year)) |>
    left_join(tarobj2,
              by = c("icb_code" = "icb_code", "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = pop,
      confidence = 0.95,
      multiplier = 100000
    )

}

# To get a breakdown by a specified group:
get_breakdown_one_group <- function(data_filtered,
                                    data_population,
                                    group,
                                    multiplier = 100000) {
  name_of_dataset <- deparse(substitute(data_filtered))

  data_population_agg <- data_population |> # currently at ICB level
    dplyr::summarise(count = sum(count),
                     .by = c(fin_year, !!rlang::sym(group)))

  data <- data_filtered |>
    dplyr::filter(!!rlang::sym(group) != "NULL") |>
    dplyr::summarise(attends = sum(attends),
                     .by = c(der_financial_year, !!rlang::sym(group))) |>
    dplyr::left_join(data_population_agg,
                     by = c(group, "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = count,
      confidence = 0.95,
      multiplier = multiplier
    )

  return(data)

}

# To get a breakdown by a two groups:
get_breakdown_two_groups <- function(data_filtered,
                                     data_population,
                                     group_population,
                                     group_other) {
  name_of_dataset <- deparse(substitute(data_filtered))

  data_population_agg <- data_population |> # currently at ICB level
    dplyr::summarise(count = sum(count),
                     .by = c(fin_year, !!rlang::sym(group_population)))

  data <- data_filtered |>
    dplyr::filter(!!rlang::sym(group_population) != "NULL") |>
    dplyr::summarise(
      attends = sum(attends),
      .by = c(
        der_financial_year,
        !!rlang::sym(group_population),
        !!rlang::sym(group_other)
      )
    ) |>
    dplyr::left_join(data_population_agg,
                     by = c(group_population, "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = count,
      confidence = 0.95,
      multiplier = 100000
    )

  return(data)

}

# To get the breakdowns for each dataset by a group:
get_breakdowns <- function(data,
                           type1_arrival_mode,
                           uec_arrival_mode,
                           data_population,
                           group) {
  if (group == "ethnic_category") {
    # NHS 111 data does not have ethnic category
    data <- data[!grepl("nhs111", names(data))]
  }

  most <- purrr::map(data,
                     ~ get_breakdown_one_group(., data_population, group))

  type1_arrival_mode <- get_breakdown_two_groups(type1_arrival_mode,
                                           data_population,
                                           group,
                                           "arrival_mode")

  uec_arrival_mode <- get_breakdown_two_groups(uec_arrival_mode,
                                           data_population,
                                           group,
                                           "arrival_mode")

  all <- append(most, list(type1_arrival_mode = type1_arrival_mode,
                           uec_arrival_mode = uec_arrival_mode))

  return(all)
}

# To filter for MH attendances:
filter_mh_attends <- function(data) {
  data_filtered <- data |>
    dplyr::filter(mh_snomed == 1)

  return(data_filtered)
}

# To filter for MH attendances where the patient is known to MH services:
filter_mh_known <- function(data) {
  data_filtered <- data |>
    dplyr::filter(mhsds_flag == 1 & mh_snomed == 1)

  return(data_filtered)
}

# To filter for MH attendances and arrival modes:
filter_arrival_mode <- function(data) {
  data_filtered <- data |>
    dplyr::filter(arrival_mode != 'NULL', mh_snomed == 1)

  return(data_filtered)
}

# To filter for MH calls from NHS 111 data:
filter_mh_calls <- function(data) {
  data_filtered <- data |>
    dplyr::filter(mh_symptom == 1)

  return(data_filtered)
}

# create df of AE attendances by hour
ae_toa_grouped <- function(tarobj, type = "1") {
  data <- tarobj |>
    dplyr::filter(der_financial_year == '2023/24',
                  ec_department_type %in% type) |>
    dplyr::group_by(mh_snomed, toa) |>
    dplyr::summarise(attends = sum(attends)) |>
    dplyr::group_by(mh_snomed) |>
    dplyr::mutate(perc = attends/sum(attends)*100)

  return(data)
}

# create df % of AE attendances left before completion
ae_left_grouped <- function(tarobj, type = "1") {
  data <- tarobj |>
    dplyr::filter(ec_department_type %in% type) |>
    dplyr::group_by(mh_snomed, der_financial_year) |>
    dplyr::summarise(attends = sum(attends),
              left = sum(left_b4_completion)) |>
    dplyr::ungroup() |>
    PHEindicatormethods::phe_proportion(x=left, n=attends, multiplier = 100)

  return(data)
}

# To get % of calls being mh-related:
get_perc_mh_calls <- function(data) {
  mh_calls <- data |>
    dplyr::summarise(
      mh_calls = sum(dplyr::if_else(mh_symptom == 1, calls, 0)),
      calls = sum(calls),
      .by = c(icb_code, der_financial_year)
    ) |>
    PHEindicatormethods::phe_proportion(mh_calls, calls, multiplier = 100)

  return(mh_calls)
}

# To get the population average for breakdown plots:
get_pop_average <- function(data_population,
                            data_filtered,
                            multiplier = 100000) {
  data_population_agg <- data_population |> # currently at ICB level
    dplyr::summarise(count = sum(pop), .by = c(fin_year))

  data <- data_filtered |>
    dplyr::summarise(attends = sum(attends),
                     .by = c(der_financial_year)) |>
    dplyr::left_join(data_population_agg,
                     by = c("der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = count,
      confidence = 0.95,
      multiplier = multiplier
    )
}

#To get the population average for breakdown plots by arrival mode:
get_pop_average_arrival_mode <- function(data_population,
                                         data_filtered,
                                         multiplier = 100000) {
  data_population_agg <- data_population |> # currently at ICB level
    dplyr::summarise(count = sum(pop), .by = c(fin_year))

  pop_data <- data_filtered |>
    dplyr::summarise(attends = sum(attends),
                     .by = c(der_financial_year, arrival_mode)) |>
    dplyr::left_join(data_population_agg,
                     by = c("der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = count,
      confidence = 0.95,
      multiplier = multiplier
    )

  return(pop_data)
}

# To group dispositions in NHS11 calls:
group_dispositions <- function(data){

  data_grouped <- data |>
    dplyr::mutate(
      disposition = dplyr::case_when(
        grepl("Ambulance", mds_primary_split) ~ "Ambulance",
        grepl("Primary", mds_primary_split) |
          grepl("Home Care", mds_primary_split) ~ "Primary or \n Community Care",
        mds_primary_split == "Not Recommended to Attend Other Service" |
          mds_primary_split == "NULL"
        ~ "No other service",
        mds_primary_split == "Recommended to Attend A&E" ~ "A&E department",
        grepl("Other Service", mds_primary_split) ~ "Other Service",
        .default = "gssdg"
      )
    )

  return(data_grouped)
}

# To get summary of NHS 111 calls by disposition:
get_disposition_summary <- function(data){
  summary <- data |>
    dplyr::filter(der_financial_year == "2021/22") |>
    group_dispositions() |>
    dplyr::summarise(calls = sum(calls), .by = c(disposition, mh_symptom)) |>
    dplyr::mutate(perc = calls / sum(calls) * 100, .by = mh_symptom)

  return(summary)
}

# To get trends for NHS 111 calls by disposition:
get_disposition_trends <- function(data) {
  trends <- data |>
    group_dispositions() |>
    dplyr::summarise(
      calls = sum(calls),
      .by = c(disposition, mh_symptom, der_financial_year)
    ) |>
    dplyr::mutate(perc = calls / sum(calls) * 100,
                  .by = c(mh_symptom, der_financial_year),
                  disposition = stringr::str_replace(disposition, "\n", ""))

  return(trends)
}