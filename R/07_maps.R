# load icb 2022 boundaries
get_icb_map <- function(mapurl) {
  icb_map <- st_read(mapurl)
}

# maps of attendances 23/24

map_icb_allmh <- function(layer, data) {
  map <- layer |>
    left_join(data |> filter(der_financial_year == '2023/24'),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
    geom_sf(aes(fill = value), lwd = 0.2) +
    scale_fill_distiller(
      name = waiver(),
      type = "seq",
      palette = "Blues",
      direction = 1,
      aesthetics = "fill"
    ) +
    theme_void() +
    labs(title = "Mental Health-specific attendances to Emergency Department",
         subtitle = "All ICB in England, 2023/24, rate per 100,000 population",
         fill = "Rate / 100,000")

  return(map)
}

map_icb_allmh_uec <- function(layer, data) {
  map <- layer |>
    left_join(data |> filter(der_financial_year == '2023/24'),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
    geom_sf(aes(fill = value), lwd = 0.2) +
    scale_fill_distiller(
      name = waiver(),
      type = "seq",
      palette = "Blues",
      direction = 1,
      aesthetics = "fill"
    ) +
    theme_void() +
    labs(title = "Mental Health-specific attendances to UCC or WIC",
         subtitle = "All ICB in England, 2023/24, rate per 100,000 population",
         fill = "Rate / 100,000")

  return(map)
}

map_icb_allmh_111 <- function(layer, data, year) {
  map <- layer |>
    left_join(data |> filter(der_financial_year == year),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
    geom_sf(aes(fill = value), lwd = 0.2) +
    scale_fill_distiller(
      name = waiver(),
      type = "seq",
      palette = "Blues",
      direction = 1,
      aesthetics = "fill"
    ) +
    theme_void() +
    labs(title = "Mental Health-specific calls to NHS 111",
         subtitle = "All ICB in England, 2020/21, rate per 100,000 population",
         fill = "Rate / 100,000")

  return(map)
}


get_conversions_from_map <- function(data, section_number, layer, ref) {
  converted <- get_number_converted_all(data,
                                        section_number,
                                        "icb23cd")

  total <- converted |>
    dplyr::summarise(total = sum(number), .by = icb23cd)

  if (section_number == "5(4)") {
    converted_to_2_or_3 <- converted |>
      dplyr::filter(
        first_two_sections == paste0(section_number, "-2") |
          first_two_sections == paste0(section_number, "-3") |
          first_two_sections == paste0(section_number, "-5(2)")
      )

    sections <- "Section 2, Section 3 or Section 5(2)"
  } else {
    converted_to_2_or_3 <- converted |>
      dplyr::filter(
        first_two_sections == paste0(section_number, "-2") |
          first_two_sections == paste0(section_number, "-3")
      )

    sections <- "Section 2 or Section 3"
  }

  converted_to_2_or_3 <- converted_to_2_or_3|>
    dplyr::summarise(number = sum(number), .by = icb23cd) |>
    dplyr::left_join(total, "icb23cd") |>
    dplyr::mutate(perc = number * 100 / total)

  table <- converted_to_2_or_3 |>
    dplyr::left_join(ref, by = c("icb23cd" = "icb_code")) |>
    select(icb_name, number, total, perc) |>
    dplyr::arrange(desc(perc))

  map <- layer |>
    left_join(converted_to_2_or_3, by = c("ICB23CD" = "icb23cd")) |>
    ggplot() +
    geom_sf(aes(fill = perc), lwd = 0.2) +
    scale_fill_distiller(
      name = waiver(),
      type = "seq",
      palette = "Blues",
      direction = 1,
      aesthetics = "fill",
      limits = c(0, 100)
    ) +
    theme_void() +
    labs(
      title = glue::glue(
        "Percentage of conversions from Section {section_number} to {sections}"
      ),
      subtitle = "Completed MHA detentions by ICB, 2019/20 to 2023/24",
      fill = "Percentage"
    )

  return(list(map = map, table = table))
}

get_perc_map_2_to_3 <- function(data, layer, ref) {

  total <- data |>
    dplyr::summarise(total = sum(spells), .by = icb23cd)

  contains_2_to_3 <- data |>
    dplyr::filter(grepl("2-3", sections_all)) |>
    dplyr::summarise(number = sum(spells), .by = icb23cd) |>
    dplyr::left_join(total, "icb23cd") |>
    dplyr::mutate(perc = number * 100 / total)

  table <- contains_2_to_3 |>
    dplyr::left_join(ref, by = c("icb23cd" = "icb_code")) |>
    select(icb_name, number, total, perc)

  map <- layer |>
    left_join(contains_2_to_3, by = c("ICB23CD" = "icb23cd")) |>
    ggplot() +
    geom_sf(aes(fill = perc), lwd = 0.2) +
    scale_fill_distiller(
      name = waiver(),
      type = "seq",
      palette = "Blues",
      direction = 1,
      aesthetics = "fill",
      limits = c(0, 100)
    ) +
    theme_void() +
    labs(
      title = "Percentage of spells containing a conversion from Section 2 to Section 3",
      subtitle = "Completed MHA detentions by ICB, 2019/20 to 2023/24",
      fill = "Percentage"
    )

  return(list(map = map, table = table))
}
