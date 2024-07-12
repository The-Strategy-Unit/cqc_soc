# To create the % MH attendances or % MH known table by financial year and ICB,
# coloured by value:
get_uec_table <- function(data, key){
  table <- data |>
    dplyr::left_join(key, "icb_code") |>
    dplyr::select("ICB" = icb_name, der_financial_year, value) |>
    dplyr::mutate(value = janitor::round_half_up(value, 2)) |>
    tidyr::pivot_wider(names_from = der_financial_year,
                       values_from = value) |>
    select(1:3,6,5,4) |>
    arrange(desc(`2023/24`)) |>
    gt::gt() |>
    gt::data_color(columns = tidyselect::starts_with("20"),
                   method = "numeric",
                   palette = "PuBu")

  return(table)
}