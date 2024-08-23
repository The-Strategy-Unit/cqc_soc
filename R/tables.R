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

# To create the % MH NHS 111 calls table by financial year and ICB, coloured by
# value:
get_icb_breakdown_table_111 <- function(data, key){
  table <- data |>
    dplyr::left_join(key, "icb_code") |>
    dplyr::select("ICB" = icb_name, der_financial_year, value) |>
    dplyr::mutate(value = janitor::round_half_up(value, 2)) |>
    dplyr::arrange(der_financial_year) |>
    tidyr::pivot_wider(names_from = der_financial_year,
                       values_from = value) |>
    dplyr::arrange(desc(`2021/22`)) |>
    create_dt()

  return(table)
}


get_ae_times_table <- function(assess, treat, conclude, depart){
  assess <- assess |>
    mutate(type = "assessment")

  treat <- treat |>
    mutate(type = "treatment")

  conclude <- conclude |>
    mutate(type = "conclusion")

  depart <- depart |>
    mutate(type = "departure")

  data <- assess |>
    rbind(treat, conclude, depart) |>
    dplyr::relocate(type)

  return(data)
}