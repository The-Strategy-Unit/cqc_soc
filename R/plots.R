# summary of ED waits for England

ed_times_plot <- function(tarobj){

  plot1 <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(attends)
              ,treat_time = sum(treat_time_total)
              ,depart_time = sum(depart_time_total)) |>
    mutate(treat_avg = treat_time/attends,
           depart_avg = (depart_time/attends)-treat_avg) |>
    ggplot(aes(x=der_financial_year, y=treat_avg, group = mh_snomed)) +
      geom_line(aes(colour = as.factor(mh_snomed))) +
      scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
      scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
      theme_minimal() +
      labs(title = "Average wait (mins) between arrival and first treatment",
           subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
           x = "Financial Year",
           y = "Wait in Minutes")

  plot2 <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(attends)
              ,treat_time = sum(treat_time_total)
              ,depart_time = sum(depart_time_total)) |>
    mutate(treat_avg = treat_time/attends,
           depart_avg = (depart_time/attends)-treat_avg) |>
    ggplot(aes(x=der_financial_year, y=depart_avg, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(title = "Average time (mins) from first treatment to conclusion",
         subtitle = "All Type 1 attendances in England 2019/20 to 2023/24",
         x = "Financial Year",
         y = "Time in Minutes")

  plot3 <- plot1 / plot2 + plot_layout(axis_titles = "collect")

  return(plot3)
}

ed_freq_boxplot <- function(tarobj){

  plot <- tarobj |>
    group_by(icb22nm, der_financial_year) |>
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

# To get a boxplot of percentage of MH attendances by financial year with points
# for ICB on top:
get_perc_mh_attends_boxplot <- function(data){
  plot <- data |>
    ggplot(aes(der_financial_year, value)) +
    geom_boxplot() +
    geom_point(colour = "salmon", alpha = 0.6) +
    theme_minimal() +
    labs(x = "Financial Year",
         y = "Percent",
         title = "Percentage of attendances with MH as primary reason",
         subtitle = "All Type 3 and 4 attendances in England 2019/20 to 2023/24 by ICB")

  return(plot)
}

# To get a caterpillar of percentage of MH attendances by financial year and
# ICB:
get_mh_attends_caterpillar <- function(data, order_year){

  order <- data |>
    filter(der_financial_year == order_year) |>
    arrange(value) |>
    pull(icb22cd)

  medians <- data |>
    summarise(median = median(value), .by = der_financial_year)

  caterpillar <- data |>
    ggplot(aes(value, factor(icb22cd, order))) +
    geom_point() +
    geom_vline(aes(xintercept = median), data = medians, col = "red") +
    geom_segment(aes(x = lowercl, xend = uppercl, y = icb22cd, yend = icb22cd)) +
    facet_wrap(~der_financial_year) +
    labs(x = "Percentage",
         y = "ICB",
         title = "Percentage of attendances with MH as primary reason",
         subtitle = "All Type 3 and 4 attendances in England 2019/20 to 2023/24 by ICB",
         caption = "Red line for the median percentage in that financial year") +
    theme_bw()

  return(caterpillar)
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

