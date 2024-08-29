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

  return(data)
}

# To get the population average for breakdown plots by arrival mode:
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