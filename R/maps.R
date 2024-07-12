# load icb 2022 boundaries
get_icb_map <- function(mapurl){
  icb_map <- st_read(mapurl)
}

# map of type 1 attendances 23/24

map_icb_allmh <- function(layer, data){

  map <- layer |>
    left_join(data |> filter(der_financial_year == '2023/24'),
              by = c("ICB23CD" = "icb23cd")) |>
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