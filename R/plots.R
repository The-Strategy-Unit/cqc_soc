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