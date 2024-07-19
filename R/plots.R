# summary of ED waits for England

ed_times_assess_plot <- function(tarobj) {
  plot <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(assess_attends)
              ,
              time = sum(assess_time_total)) |>
    mutate(avg_time = time / attends) |>
    ggplot(aes(x = der_financial_year, y = avg_time, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(
      title = "Average wait (mins) between arrival and assessment",
      subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
      x = "Financial Year",
      y = "Wait in Minutes"
    )
  return(plot)
}

ed_times_treat_plot <- function(tarobj) {
  plot <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(treat_attends)
              ,
              time = sum(treat_time_total)) |>
    mutate(avg_time = time / attends) |>
    ggplot(aes(x = der_financial_year, y = avg_time, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(
      title = "Average wait (mins) between arrival and first treatment",
      subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
      x = "Financial Year",
      y = "Wait in Minutes"
    )
  return(plot)
}

ed_times_conclude_plot <- function(tarobj) {
  plot <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(conclude_attends)
              ,
              time = sum(conclude_time_total)) |>
    mutate(avg_time = time / attends) |>
    ggplot(aes(x = der_financial_year, y = avg_time, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(
      title = "Average wait (mins) between arrival and conclusion",
      subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
      x = "Financial Year",
      y = "Wait in Minutes"
    )
  return(plot)
}

ed_times_depart_plot <- function(tarobj) {
  plot <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(depart_attends)
              ,
              time = sum(depart_time_total)) |>
    mutate(avg_time = time / attends) |>
    ggplot(aes(x = der_financial_year, y = avg_time, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(
      title = "Average wait (mins) between arrival and departure",
      subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
      x = "Financial Year",
      y = "Wait in Minutes"
    )
  return(plot)
}

ed_freq_boxplot <- function(tarobj) {
  plot <- tarobj |>
    group_by(icb23nm, der_financial_year) |>
    summarise(mh_pats = sum(mh_pats)
              ,
              mh_freqfly = sum(mh_freqfly)) |>
    mutate(perc_freq = round(mh_freqfly / mh_pats * 100, 2)) |>
    ggplot(aes(x = der_financial_year, y = perc_freq)) +
    geom_boxplot() +
    geom_point(colour = "salmon", alpha = 0.6) +
    theme_minimal() +
    labs(
      title = "Percentage of MH ED patients attending 5+ times / year",
      subtitle = "All Type 1 attendances in England 2019/20 to 2023/24 by ICB",
      colour = NULL,
      x = "Financial Year",
      y = "Percent"
    )

  return(plot)
}

# To get standard boxplot:
get_standard_boxplot <- function(data) {
  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(der_financial_year, value)) +
    ggplot2::geom_boxplot() +
    ggplot2::geom_point(colour = "salmon", alpha = 0.6) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Financial Year",
      y = "Percent",
      title = "Percentage of attendances with MH as primary reason",
      subtitle = "All Type 3 and 4 attendances in England 2019/20 to 2023/24 by ICB"
    ) +
    StrategyUnitTheme::su_theme()

  return(plot)
}

# To get a boxplot of percentage of MH attendances by financial year with points
# for ICB on top:
get_perc_mh_attends_boxplot <- function(data, type) {
  plot <- data |>
    get_standard_boxplot() +
    ggplot2::labs(
      x = "Financial Year",
      y = "Percent",
      title = "Percentage of attendances with MH as primary reason",
      subtitle = glue::glue("All {type} attendances in England 2019/20 to 2023/24 by ICB")
    )
}

# To get a boxplot of percentage of MH attendances by financial year with points
# for ICB on top:
get_perc_mh_known_boxplot <- function(data, type) {
  plot <- data |>
    get_standard_boxplot() +
    ggplot2::labs(
      x = "Financial Year",
      y = "Percent",
      title = "Percentage of attendances with MH known to specialist services",
      subtitle = glue::glue("All {type} attendances in England 2019/20 to 2023/24 by ICB")
    )
}

get_ed_transp_colplot <- function(tarobj) {
  plot <- tarobj |>
    ggplot(aes(
      x = arrival_mode,
      y = perc,
      fill = as.factor(mh_snomed)
    )) +
    geom_bar(position = "dodge", stat = "identity") +
    scale_fill_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    theme_minimal() +
    labs(
      x = "Arrival Mode",
      y = "Percent",
      title = "Percentage of attendances by arrival mode",
      subtitle = "All Type 1 attendances in England 2023/24"
    )

  return(plot)
}

get_ed_transp_trends <- function(tarobj){
  plot <- tarobj|>
    filter(arrival_mode != 'pub_tran') |>
    ggplot(aes(x=der_financial_year, y=perc, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    facet_wrap(~ arrival_mode, ncol = 1) +
    theme_minimal() +
    labs(title = "Arrival mode to Type 1 A&E attendances",
         subtitle = "All attendances in England 2019/20 to 2023/24",
         x = "Financial Year",
         y = "Percentage of all")

  return(plot)
}

get_standard_line_for_breakdowns <- function(data, group) {
  name_of_dataset <- deparse(substitute(data))

  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(
      der_financial_year,
      value,
      group = !!rlang::sym(group),
      col = !!rlang::sym(group)
    )) +
    ggplot2::geom_line() +
    ggplot2::scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Financial Year", y = "Rate per 100,000 population",
                  caption = "95% confidence intervals are shown in dashed lines") +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = lowercl,
        ymax = uppercl,
        fill = !!rlang::sym(group)
      ),
      alpha = 0.05,
      linetype = 2
    ) +
    StrategyUnitTheme::su_theme()

  return(plot)

}

get_overlay_barchart_toa <- function(tarobj) {
  plot <- tarobj |>
    ggplot(aes(
      x = toa,
      y = perc,
      fill = as.factor(mh_snomed)
    )) +
    geom_bar(stat = "identity",
             position = "identity",
             alpha = .6) +
    scale_fill_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    theme_minimal() +
    labs(
      x = "Time of arrival (24hr)",
      y = "Percent of attendances",
      title = "Percentage of attendances to A&E by hour of arrival",
      subtitle = "All Type 1 attendances in England, 2023/24"
    )

  return(plot)
}

ed_left_plot <- function(tarobj) {
  plot <- tarobj |>
    ggplot(aes(x = der_financial_year, y = value, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(
      title = "Percentage of patients leaving before assessment or treatment",
      subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
      x = "Financial Year",
      y = "% of all attendances"
    )
  return(plot)
}

imd_plot2 <- function(tarobj){
  plot <- tarobj |>
    ggplot(aes(x=as.numeric(imd_decile), y=value)) +
    geom_smooth(method = "lm", level = 0.9, alpha = 0.5, linewidth = 0.5, linetype = "dashed",colour = "#686f73") +
    geom_point(shape = 21, size = 2, fill = "#F9BF07") +
    scale_x_discrete(name = 'IMD decile (1=most deprived)', limits = c(1:10)) +
    facet_wrap(~ der_financial_year) +
    theme_minimal() +
    labs(subtitle = "all of England, rate per 100,000"
         ,x = 'IMD decile (1=most deprived)'
         ,y = "Crude rate per 100,000")

}
