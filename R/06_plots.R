# summary of ED waits for England

ed_times_assess_plot <- function(tarobj) {
  plot <-  tarobj |>
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

ed_freq_boxplot <- function(tarobj, type = "Type 1 attendances", title = "MH ED patients attending") {
  plot <- tarobj|>
    ggplot(aes(x = der_financial_year, y = perc_freq)) +
    geom_boxplot() +
    geom_point(colour = "salmon", alpha = 0.6) +
    theme_minimal() +
    labs(
      title = glue::glue("Percentage of {title} 5+ times / year"),
      subtitle = glue::glue("All {type} in England 2019/20 to 2023/24 by ICB"),
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
    )

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

  return(plot)
}

# To get a boxplot of percentage of MH attendances by financial year with points
# for ICB on top:
get_perc_mh_known_boxplot <- function(data, type) {
  plot <- data |>
    get_standard_boxplot() +
    ggplot2::labs(
      x = "Financial Year",
      y = "Percent",
      title = "Percentage of MH attendances known to MH services",
      subtitle = glue::glue("All {type} attendances in England 2019/20 to 2023/24 by ICB")
    )

  return(plot)
}

get_ed_transp_colplot <- function(tarobj, type = "Type 1") {
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
      subtitle = glue::glue("All {type} attendances in England 2023/24")
    )

  return(plot)
}

get_ed_transp_trends <- function(tarobj, type = "Type 1"){
  plot <- tarobj|>
    filter(arrival_mode != 'pub_tran') |>
    ggplot(aes(x=der_financial_year, y=perc, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    facet_wrap(~ arrival_mode, ncol = 1) +
    theme_minimal() +
    labs(title = glue::glue("Arrival mode to {type} A&E attendances"),
         subtitle = "All attendances in England 2019/20 to 2023/24",
         x = "Financial Year",
         y = "Percentage of all")

  return(plot)
}

# To get a standard line plot for the breakdowns:
get_standard_line_for_breakdowns <- function(data, pop_by_icb, group) {
  if (sum(grepl("arrival", colnames(data))) > 0) {
    pop_data <- get_pop_average_arrival_mode(pop_by_icb, data)
  } else {
    pop_data <- get_pop_average(pop_by_icb, data)
  }

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
    ggplot2::labs(x = "Financial Year",
                  y = "Rate per 100,000 population",
                  caption = "Dotted lines are 95% confidence intervals. \n Black dashed line is the sub-group average.") +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = lowercl,
        ymax = uppercl,
        fill = !!rlang::sym(group)
      ),
      alpha = 0.05,
      linetype = "dotted"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(der_financial_year,
                   value,
                   group = 1),
      colour = "black",
      linetype = "longdash",
      data = pop_data
    )

  return(plot)

}

get_overlay_barchart_toa <- function(tarobj, type = "Type 1") {
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
      subtitle = glue::glue("All {type} attendances in England, 2023/24")
    )

  return(plot)
}

get_overlay_barchart_toa_111 <- function(tarobj) {
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
      x = "Time of call (24hr)",
      y = "Percent of calls",
      title = "Percentage of calls to NHS 111 by hour of call",
      subtitle = "All NHS111 calls in England, 2021/22"
    )

  return(plot)
}

ed_left_plot <- function(tarobj, type = "Type 1") {
  plot <- tarobj |>
    ggplot(aes(x = der_financial_year, y = value, group = mh_snomed)) +
    geom_line(aes(colour = as.factor(mh_snomed))) +
    scale_color_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    theme_minimal() +
    labs(
      title = "Percentage of patients leaving before assessment or treatment",
      subtitle = glue::glue("All {type} attendances in England 2019/20 to 2023/24"),
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


# To get a boxplot of percentage of MH NHS 111 calls by financial year with
# points for ICB on top:
get_perc_mh_calls_boxplot <- function(data) {
  plot <- data |>
    get_standard_boxplot() +
    ggplot2::labs(
      x = "Financial Year",
      y = "Percent",
      title = "Percentage of calls being MH-related",
      subtitle = "All NHS 111 calls in England 2019/20 to 2023/24 by ICB"
    )

  return(plot)
}

# To get a bar chart of the disposition of NHS 111 calls:
get_disposition_bar_chart <- function(data){
  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(
      x = disposition,
      y = perc,
      fill = as.factor(mh_symptom)
    )) +
    ggplot2::geom_bar(position = "dodge", stat = "identity") +
    ggplot2::scale_fill_manual(values = c("#333739", "#f9bf07"), name = "MH presentation") +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Disposition",
      y = "Percent",
      title = "Percentage of calls by disposition",
      subtitle = "All NHS 111 calls in England 2021/22"
    )

  return(plot)
}

# To get line plot of nhs111 call dispositions over time:
get_nhs111_disposition_trends_chart <- function(data){
  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(x=der_financial_year, y=perc, group = mh_symptom)) +
    ggplot2::geom_line(ggplot2::aes(colour = as.factor(mh_symptom))) +
    ggplot2::scale_color_manual(values=c("#333739","#f9bf07"), name = "MH presentation") +
    ggplot2::scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    ggplot2::facet_wrap(~ disposition, ncol = 1, scales = "free") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Call Disposition",
                  subtitle = "All NHS 111 calls in England 2019/20 to 2023/24",
                  x = "Financial Year",
                  y = "Percentage of all")

  return(plot)}

# To plot the avg_mh_attends_rate:
get_avg_mh_attends_rate_plot <- function(data){
  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(
      der_financial_year,
      value,
      group = 1
    )) +
    ggplot2::geom_line() +
    ggplot2::scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Financial Year",
                  y = "Rate per 100,000 population",
                  caption = "Dotted lines are 95% confidence intervals.") +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = lowercl,
        ymax = uppercl
      ),
      alpha = 0.05,
      linetype = "dotted"
    )

  return(plot)
}

mha_conversion_table <- function(tar_obj, feature) {
  feature <- enquo(feature)

  table <- tar_obj |>
    dplyr::mutate(
      SECTION_54_to_52 = ifelse(grepl("5\\(4\\)-5\\(2\\)", sections_all), 1, 0),
      SECTION_135_136_to_5 = ifelse(
        grepl("135-5", sections_all) |
          grepl("136-5", sections_all),
        1,
        0
      ),
      SECTION_52_to_2 = ifelse(grepl("5\\(2\\)-2", sections_all), 1, 0),
      SECTION_52_to_3 = ifelse(grepl("5\\(2\\)-3", sections_all), 1, 0),
      SECTION_4_to_2 = ifelse(grepl("4-2", sections_all), 1, 0),
      SECTION_4_to_3 = ifelse(grepl("4-3", sections_all), 1, 0),
      SECTION_136_to_3 = ifelse(grepl("136-3", sections_all), 1, 0),
      SECTION_136_to_2 = ifelse(grepl("136-2", sections_all), 1, 0),
      SECTION_3_renewal = ifelse(grepl("3-3", sections_all), 1, 0)
    ) |>
    dplyr::summarise(
      dplyr::across(dplyr::starts_with("SECTION_"), ~ sum(.)),
      total = dplyr::n(),
      .by = !!feature
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::starts_with("SECTION"),
      names_to = "conversion_desc",
      values_to = "sum"
    ) |>
    dplyr::mutate(conversion_desc = str_replace_all(
      conversion_desc,
      c(
        "SECTION" = "Section",
        "to" = "to Section",
        "_" = " ",
        "54" = "5(4)",
        "52" = "5(2)",
        "135 136 to Section 5" = "135/136 to Section 5(2)/5(4)"
      )
    )) |>
    PHEindicatormethods::phe_proportion(
      x = sum,
      n = total,
      confidence = 0.95,
      multiplier = 100
    ) |>
    dplyr::select(!!feature,
                  conversion_desc,
                  sum,
                  total,
                  value,
                  lowercl,
                  uppercl) |>
    dplyr::arrange(!!feature, conversion_desc)

  return(table)

}


mha_conversion_bar_plot <- function(tar_obj, feature, feature_txt, title_txt){

  feature <- enquo(feature)

  ft_ct <- tar_obj |>
    summarise(val = ceiling(n_distinct(!!feature)/3))

  plot <- tar_obj |>
    filter(conversion_desc != "Other section pathways") |>
    ggplot(aes(x=conversion_desc, y=(value), group = 1)) +
    geom_col(aes(), fill = "#f9bf07", colour = "#333739", lwd = 0.2) +
    facet_wrap(feature_txt, nrow = ft_ct$val) +
    coord_flip() +
    theme_minimal() +
    labs(title = "Selected conversion pathways during MHA detention spells",
         subtitle = paste0("Completed detention by ", title_txt, ", 2019/20 to 2023/24"),
         x= "Conversion description",
         y= "Percentage of all detention spells")

  return(plot)
}


get_number_converted_all <- function(data, section_number, group) {
  if (grepl("\\(", section_number)) {
    start <- paste0(stringr::str_replace_all(section_number, c("\\(" = "\\\\(", "\\)" = "\\\\)")), "-")
  } else {
    start <- paste0(section_number, "-")
  }

  converted <- data |>
    dplyr::filter(stringr::str_starts(sections_all, start) |
                    sections_all == section_number) |>
    dplyr::mutate(first_two_sections = ifelse(
      grepl("-", sections_all),
      stringr::word(sections_all, 1, 2, sep = "-"),
      sections_all
    )) |>
    dplyr::summarise(number = sum(spells),
                     .by = c(first_two_sections, !!rlang::sym(group)))

  return(converted)
}

get_number_converted_table <- function(data, section_number) {
  total <- data |>
    dplyr::summarise(total = sum(number), .by = fin_year)

  summary <- data |>
    dplyr::mutate(
      desc = case_when(
        first_two_sections == section_number ~ "not_converted",
        first_two_sections == paste0(section_number, "-2") ~ "converted_to_2",
        first_two_sections == paste0(section_number, "-3") ~ "converted_to_3",
        .default = "converted_to_other"
      )
    ) |>
    dplyr::summarise(number = sum(number), .by = c(desc, fin_year)) |>
    dplyr::left_join(total, "fin_year") |>
    dplyr::mutate(perc = number * 100 / total, section = section_number) |>
    dplyr::relocate(section, fin_year)

  return(summary)
}

get_number_converted_plot <- function(data, section_number) {
  plot <- data |>
    ggplot2::ggplot(ggplot2::aes(fin_year, perc, group = desc, col = desc)) +
    ggplot2::geom_line() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Financial year",
      y = "Percentage converted",
      fill = "Type of conversion",
      title = glue::glue("Percentage of conversions from Section {section_number}"),
      subtitle = glue::glue(
        "All spells starting with Section {section_number} converted to Section 2, Section 3, another Section or not converted"
      )
    )

  return(plot)
}

get_conversions_from_section <- function(data, section_number, group = "fin_year") {
  overall <- get_number_converted_all(data, section_number, group)

  table <- get_number_converted_table(overall, section_number)

  plot <- get_number_converted_plot(table, section_number)

  summary <- overall |>
    dplyr::summarise(number = sum(number), .by = first_two_sections) |>
    dplyr::arrange(desc(number))

  return(list(
    table = table,
    plot = plot,
    summary = summary
  ))
}

