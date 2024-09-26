# load icb 2022 boundaries
get_icb_map <- function(mapurl){
  icb_map <- st_read(mapurl)
}

# maps of attendances 23/24

map_icb_allmh <- function(layer, data){

  map <- layer |>
    left_join(data |> filter(der_financial_year == '2023/24'),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
        geom_sf(aes(fill = value), lwd=0.2) +
        scale_fill_distiller(name = waiver(),
                       type = "seq",
                       palette = "Blues",
                       direction = 1,
                       aesthetics = "fill") +
        theme_void() +
        labs(title = "Mental Health-specific attendances to Emergency Department",
         subtitle = "All ICB in England, 2023/24, rate per 100,000 population",
         fill = "Rate / 100,000")

  return(map)
}

map_icb_allmh_uec <- function(layer, data){

  map <- layer |>
    left_join(data |> filter(der_financial_year == '2023/24'),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
    geom_sf(aes(fill = value), lwd=0.2) +
    scale_fill_distiller(name = waiver(),
                         type = "seq",
                         palette = "Blues",
                         direction = 1,
                         aesthetics = "fill") +
    theme_void() +
    labs(title = "Mental Health-specific attendances to UCC or WIC",
         subtitle = "All ICB in England, 2023/24, rate per 100,000 population",
         fill = "Rate / 100,000")

  return(map)
}

map_icb_allmh_111 <- function(layer, data, year){

  map <- layer |>
    left_join(data |> filter(der_financial_year == year),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
    geom_sf(aes(fill = value), lwd=0.2) +
    scale_fill_distiller(name = waiver(),
                         type = "seq",
                         palette = "Blues",
                         direction = 1,
                         aesthetics = "fill") +
    theme_void() +
    labs(title = "Mental Health-specific calls to NHS 111",
         subtitle = "All ICB in England, 2020/21, rate per 100,000 population",
         fill = "Rate / 100,000")

  return(map)
}

get_map_of_conversion_path <- function(layer, data, path){

  map <- layer |>
    left_join(data |>
                dplyr::filter(conversion_desc == path),
              by = c("ICB23CD" = "icb_code")) |>
    ggplot() +
    geom_sf(aes(fill = value), lwd=0.2) +
    scale_fill_distiller(name = waiver(),
                         type = "seq",
                         palette = "Blues",
                         direction = 1,
                         aesthetics = "fill",
                         limits = c(0, ceiling(max(data$value)))) +
    theme_void() +
    labs(title = glue::glue("Percentage of conversion pathways containing '{path}'"),
         subtitle = "Completed detentions by ICB, 2018/19 to 2023/24",
         fill = "Percentage")

  return(map)
}