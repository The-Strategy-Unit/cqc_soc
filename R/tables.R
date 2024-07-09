# To create the % MH attendances table by financial year and ICB, coloured by
# value:
get_mh_attends_table <- function(data, key){
  table <- data |>
    dplyr::left_join(key, "icb22cd") |>
    dplyr::select("ICB" = icb22nm, der_financial_year, value) |>
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