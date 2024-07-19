# To create the % MH attendances or % MH known table by financial year and ICB,
# coloured by value:
get_icb_breakdown_table <- function(data, key){
  table <- data |>
    dplyr::left_join(key, "icb_code") |>
    dplyr::select("ICB" = icb_name, der_financial_year, value) |>
    dplyr::mutate(value = janitor::round_half_up(value, 2)) |>
    dplyr::arrange(der_financial_year) |>
    tidyr::pivot_wider(names_from = der_financial_year,
                       values_from = value) |>
    dplyr::arrange(desc(`2023/24`)) |>
    create_dt()

  return(table)
}




get_icb_breakdown_table_111 <- function(data, key){
  table <- data |>
    dplyr::left_join(key, "icb_code") |>
    dplyr::select("ICB" = icb_name, der_financial_year, value) |>
    dplyr::mutate(value = janitor::round_half_up(value, 2)) |>
    dplyr::filter(!is.na(ICB)) |> # think because have 2022 ICBs
    dplyr::arrange(der_financial_year) |>
    tidyr::pivot_wider(names_from = der_financial_year,
                       values_from = value) |>
    dplyr::arrange(desc(`2021/22`)) |>
    create_dt()

  return(table)
}
