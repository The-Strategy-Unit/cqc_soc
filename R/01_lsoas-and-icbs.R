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

# To summarise data across ICBs.
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