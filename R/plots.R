# summary of ED waits for England

ed_times_plot <- function(tarobj){

  plot1 <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(attends)
              ,assess_time = sum(assess_time_total)) |>
    mutate(assess_avg = assess_time/attends) |>
    ggplot(aes(x=der_financial_year, y=assess_avg, group = mh_snomed)) +
      geom_line(aes(colour = as.factor(mh_snomed))) +
      scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
      scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
      theme_minimal() +
      labs(title = "Average wait (mins) between arrival and assessment",
           subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
           x = "Financial Year",
           y = "Wait in Minutes")

  plot2 <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(attends)
              ,decadm_time = sum(assess_to_dec)) |>
    mutate(decadm_avg = decadm_time/attends) |>
    ggplot(aes(x=der_financial_year, y=decadm_avg, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(title = "Average wait (mins) between assessment and decision to treat",
         subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
         x = "Financial Year",
         y = "Wait in Minutes")

  plot3 <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(attends)
              ,treat_time = sum(dec_to_treat)) |>
    mutate(treat_avg = treat_time/attends) |>
    ggplot(aes(x=der_financial_year, y=treat_avg, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(title = "Average wait (mins) between decision to treat and first treatment",
         subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
         x = "Financial Year",
         y = "Wait in Minutes")

  plot4 <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(attends)
              ,depart_time = sum(treat_to_depart)) |>
    mutate(depart_avg = depart_time/attends) |>
    ggplot(aes(x=der_financial_year, y=depart_avg, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(title = "Average wait (mins) between treatment and departure",
         subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
         x = "Financial Year",
         y = "Wait in Minutes")

  plot5 <-(plot1 + plot2) / (plot3 + plot4) + plot_layout(axis_titles = "collect")

  return(plot5)
}

ed_freq_boxplot <- function(tarobj){

  plot <- tarobj |>
    group_by(icb23nm, der_financial_year) |>
    summarise(mh_pats = sum(mh_pats)
              ,mh_freqfly = sum(mh_freqfly)) |>
    mutate(perc_freq = round(mh_freqfly/mh_pats*100,2)) |>
    ggplot(aes(x=der_financial_year, y=perc_freq)) +
    geom_boxplot() +
    geom_point(colour = "salmon", alpha = 0.6) +
    theme_minimal() +
    labs(title = "Percentage of MH ED patients attending 5+ times / year",
         subtitle = "All Type 1 attendances in England 2019/20 to 2023/24 by ICB",
         colour = NULL,
         x = "Financial Year",
         y = "Percent")

  return(plot)
}

# To get standard boxplot:
get_standard_boxplot <- function(data){
  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(der_financial_year, value)) +
    ggplot2::geom_boxplot() +
    ggplot2::geom_point(colour = "salmon", alpha = 0.6) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Financial Year",
         y = "Percent",
         title = "Percentage of attendances with MH as primary reason",
         subtitle = "All Type 3 and 4 attendances in England 2019/20 to 2023/24 by ICB")

  return(plot)
}

# To get a boxplot of percentage of MH attendances by financial year with points
# for ICB on top:
get_perc_mh_attends_boxplot <- function(data){
  plot <- data |>
    get_standard_boxplot() +
    ggplot2::labs(x = "Financial Year",
                  y = "Percent",
                  title = "Percentage of attendances with MH as primary reason",
                  subtitle = "All Type 3 and 4 attendances in England 2019/20 to 2023/24 by ICB")
}

# To get a boxplot of percentage of MH attendances by financial year with points
# for ICB on top:
get_perc_mh_known_boxplot <- function(data){
  plot <- data |>
    get_standard_boxplot() +
    ggplot2::labs(x = "Financial Year",
                  y = "Percent",
                  title = "Percentage of attendances with MH known to specialist services",
                  subtitle = "All Type 3 and 4 attendances in England 2019/20 to 2023/24 by ICB")
}

get_ed_transp_colplot <- function(tarobj){
  plot <- tarobj|>
    ggplot(aes(x=arrival_mode, y=perc, fill = as.factor(mh_snomed))) +
    geom_bar(position="dodge", stat="identity") +
    scale_fill_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    theme_minimal() +
    labs(x = "Arrival Mode",
         y = "Percent",
         title = "Percentage of attendances by arrival mode",
         subtitle = "All Type 1 attendances in England 2023/24")

  return(plot)
}

get_standard_line_for_breakdowns <- function(data, group){
  name_of_dataset <- deparse(substitute(data))

  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(der_financial_year,
                                 value,
                                 group = !!rlang::sym(group),
                                 col = !!rlang::sym(group))) +
    ggplot2::geom_line() +
    ggplot2::scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Financial Year",
                  y = "Rate per 100,000 population")

  return(plot)

}
