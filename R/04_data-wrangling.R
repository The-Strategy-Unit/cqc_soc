# Type 1 ED and UEC activity ---------------------------------------------------
# AE summary tables
get_ae_summary <- function(tarobj) {
  data <-  tarobj |>
    filter(ec_department_type == '01') |>
    group_by(der_financial_year) |>
    summarise(
      all = sum(attends),
      mh = sum(if_else(mh_snomed == 1, attends, 0)),
      all_cost = sum(cost),
      mh_cost = sum(if_else(mh_snomed == 1, cost, 0))
    ) |>
    mutate(mh_perc = round(mh / all * 100, 2))

  return(data)
}

get_uec_summary <- function(tarobj) {
  data <-  tarobj |>
    filter(ec_department_type %in% c('03','04')) |>
    group_by(der_financial_year) |>
    summarise(
      all = sum(attends),
      mh = sum(if_else(mh_snomed == 1, attends, 0)),
      all_cost = sum(cost),
      mh_cost = sum(if_else(mh_snomed == 1, cost, 0))
    ) |>
    mutate(mh_perc = round(mh / all * 100, 2))

  return(data)
}

get_ae_summ_transp <- function(tarobj, type = "01") {

  tarobj |>
    filter(der_financial_year == '2023/24',
           arrival_mode != 'NULL',
           ec_department_type %in% type) |>
    group_by(mh_snomed, arrival_mode) |>
    summarise(attends = sum(attends)) |>
    group_by(mh_snomed) |>
    mutate(perc = attends / sum(attends) * 100)
}

get_ae_amb_trends <- function(tarobj, type = "01") {
  tarobj |>
    filter(arrival_mode != 'NULL',
           ec_department_type %in% type) |>
    group_by(mh_snomed, arrival_mode, der_financial_year) |>
    summarise(attends = sum(attends)) |>
    group_by(mh_snomed, der_financial_year) |>
    mutate(perc = attends / sum(attends) * 100)
}


# To get Type 3 and Type 4 attendances:
get_uec_activity <- function(data) {
  filtered <- data |>
    dplyr::filter(ec_department_type %in% c("03", "04")) |>
    dplyr::rename(icb_code = icb23cd, icb_name = icb23nm)

  return(filtered)

}

# To get percentage of MH attendances by ICB and financial year:
get_perc_mh_attends <- function(data) {
  mh_attends <- data |>
    dplyr::summarise(
      mh_attends = sum(if_else(mh_snomed == 1, attends, 0)),
      attends = sum(attends),
      .by = c(icb_code, der_financial_year)
    ) |>
    PHEindicatormethods::phe_proportion(mh_attends, attends, multiplier = 100)

  return(mh_attends)
}

# To get percentage of MH attendances that were known to specialist services by
# ICB and financial year:
get_perc_mh_known <- function(data) {
  mh_known <- data |>
    dplyr::filter(mh_snomed == 1) |> # attends due to MH
    dplyr::summarise(
      mh_known = sum(dplyr::if_else(mhsds_flag == 1, attends, 0)),
      attends = sum(attends),
      .by = c(icb_code, der_financial_year)
    ) |>
    PHEindicatormethods::phe_proportion(mh_known, attends, multiplier = 100)

  return(mh_known)
}



# To get Type 1 attendances:
get_ed_activity <- function(data) {
  filtered <- data |>
    dplyr::filter(ec_department_type == "01") |>
    dplyr::rename(icb_code = icb23cd, icb_name = icb23nm)

  return(filtered)

}

## MH attendance rates total by ICB
get_icb_att_rates <- function(tarobj1, tarobj2) {
  tarobj1 |>
    filter(mh_snomed == 1) |>
    summarise(attends = sum(attends),
              .by = c(icb_code, der_financial_year)) |>
    left_join(tarobj2,
              by = c("icb_code" = "icb_code", "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = pop,
      confidence = 0.95,
      multiplier = 100000
    )

}

# To filter for MH attendances:
filter_mh_attends <- function(data) {
  data_filtered <- data |>
    dplyr::filter(mh_snomed == 1)

  return(data_filtered)
}

# To filter for MH attendances where the patient is known to MH services:
filter_mh_known <- function(data) {
  data_filtered <- data |>
    dplyr::filter(mhsds_flag == 1 & mh_snomed == 1)

  return(data_filtered)
}

# To filter for MH attendances and arrival modes:
filter_arrival_mode <- function(data) {
  data_filtered <- data |>
    dplyr::filter(arrival_mode != 'NULL', mh_snomed == 1)

  return(data_filtered)
}

# create df of AE attendances by hour
ae_toa_grouped <- function(tarobj, type = "1") {
  data <- tarobj |>
    dplyr::filter(der_financial_year == '2023/24',
                  ec_department_type %in% type) |>
    dplyr::group_by(mh_snomed, toa) |>
    dplyr::summarise(attends = sum(attends)) |>
    dplyr::group_by(mh_snomed) |>
    dplyr::mutate(perc = attends/sum(attends)*100)

  return(data)
}

# create df % of AE attendances left before completion
ae_left_grouped <- function(tarobj, type = "1") {
  data <- tarobj |>
    dplyr::filter(ec_department_type %in% type) |>
    dplyr::group_by(mh_snomed, der_financial_year) |>
    dplyr::summarise(attends = sum(attends),
              left = sum(left_b4_completion)) |>
    dplyr::ungroup() |>
    PHEindicatormethods::phe_proportion(x=left, n=attends, multiplier = 100)

  return(data)
}

# summary of ED waits for England
get_ed_times_assess <- function(tarobj){
  data <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(assess_attends)
              ,
              time = sum(assess_time_total)) |>
    mutate(avg_time = time / attends)

  return(data)
}

get_ed_times_treat <- function(tarobj){
  data <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(treat_attends)
              ,
              time = sum(treat_time_total)) |>
    mutate(avg_time = time / attends)

  return(data)
}

get_ed_times_conclude <- function(tarobj){

  data <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(conclude_attends)
              ,
              time = sum(conclude_time_total)) |>
    mutate(avg_time = time / attends)

  return(data)
}

get_ed_times_depart <- function(tarobj){

  data <- tarobj |>
    group_by(mh_snomed, der_financial_year) |>
    summarise(attends = sum(depart_attends)
              ,
              time = sum(depart_time_total)) |>
    mutate(avg_time = time / attends)

  return(data)
}

get_ed_freq_data <- function(tarobj){
  data <- tarobj |>
    group_by(icb23nm, icb23cd, der_financial_year) |>
    summarise(mh_pats = sum(mh_pats)
              ,
              mh_freqfly = sum(mh_freqfly)) |>
    mutate(perc_freq = round(mh_freqfly / mh_pats * 100, 2))

  return(data)
}

get_perc_toa_111 <- function(tarobj) {
  data <- tarobj |>
    filter(der_financial_year == '2021/22') |>
    group_by(mh_snomed, toa) |>
    summarise(total = sum(attends)) |>
    group_by(mh_snomed) |>
    mutate(perc = total/sum(total)*100) |>
    ungroup()

  return(data)
}

# To combine the ED waiting times into one table:
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

# NHS111 calls -----------------------------------------------------------------
# To filter for MH calls from NHS 111 data:
filter_mh_calls <- function(data) {
  data_filtered <- data |>
    dplyr::filter(mh_symptom == 1)

  return(data_filtered)
}

## MH call rates to 111, total by ICB
get_icb_111_rates <- function(tarobj1, tarobj2) {
  tarobj1 |>
    filter(mh_symptom == 1) |>
    summarise(attends = sum(calls),
              .by = c(icb_code, der_financial_year)) |>
    left_join(tarobj2,
              by = c("icb_code" = "icb_code", "der_financial_year" = "fin_year")) |>
    PHEindicatormethods::phe_rate(
      x = attends,
      n = pop,
      confidence = 0.95,
      multiplier = 100000
    )

}

get_111_summary <- function(tarobj) {
  data <-  tarobj |>
    group_by(der_financial_year) |>
    summarise(
      all = sum(calls),
      mh = sum(if_else(mh_symptom == 1, calls, 0)),
      all_cost = sum(cost),
      mh_cost = sum(if_else(mh_symptom == 1, cost, 0))
    ) |>
    mutate(mh_perc = round(mh / all * 100, 2))

  return(data)
}

get_111_symptom_summary <- function(tarobj) {
  data <-  tarobj |>
    group_by(der_financial_year, sg_sd_description) |>
    summarise(all = sum(calls))

  return(data)
}

# To get % of calls being mh-related:
get_perc_mh_calls <- function(data) {
  mh_calls <- data |>
    dplyr::summarise(
      mh_calls = sum(dplyr::if_else(mh_symptom == 1, calls, 0)),
      calls = sum(calls),
      .by = c(icb_code, der_financial_year)
    ) |>
    PHEindicatormethods::phe_proportion(mh_calls, calls, multiplier = 100)

  return(mh_calls)
}

# To group dispositions in NHS11 calls:
group_dispositions <- function(data){

  data_grouped <- data |>
    dplyr::mutate(
      disposition = dplyr::case_when(
        grepl("Ambulance", mds_primary_split) ~ "Ambulance",
        grepl("Primary", mds_primary_split) |
          grepl("Home Care", mds_primary_split) ~ "Primary or \n Community Care",
        mds_primary_split == "Not Recommended to Attend Other Service" |
          mds_primary_split == "NULL"
        ~ "No other service",
        mds_primary_split == "Recommended to Attend A&E" ~ "A&E department",
        grepl("Other Service", mds_primary_split) ~ "Other Service",
        .default = "gssdg"
      )
    )

  return(data_grouped)
}

# To get summary of NHS 111 calls by disposition:
get_disposition_summary <- function(data){
  summary <- data |>
    dplyr::filter(der_financial_year == "2021/22") |>
    group_dispositions() |>
    dplyr::summarise(calls = sum(calls), .by = c(disposition, mh_symptom)) |>
    dplyr::mutate(perc = calls / sum(calls) * 100, .by = mh_symptom)

  return(summary)
}

# To get trends for NHS 111 calls by disposition:
get_disposition_trends <- function(data) {
  trends <- data |>
    group_dispositions() |>
    dplyr::summarise(
      calls = sum(calls),
      .by = c(disposition, mh_symptom, der_financial_year)
    ) |>
    dplyr::mutate(perc = calls / sum(calls) * 100,
                  .by = c(mh_symptom, der_financial_year),
                  disposition = stringr::str_replace(disposition, "\n", ""))

  return(trends)
}

# get 111 callers known to services

get_111_mh_known <- function(tarobj){

  data <- tarobj |>
    filter(mh_symptom == 1) |>
    group_by(der_financial_year, mhsds_flag) |>
    summarise(calls = sum(calls)) |>
    group_by(der_financial_year) |>
    mutate(perc = calls/sum(calls)*100) |>
    ungroup()

  return(data)
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

# Redetentions -----------------------------------------------------------------
# To create the % redetentions by financial year and ICB, coloured by value:
get_icb_breakdown_table_redetentions <- function(data, key){
  table <- data |>
    dplyr::left_join(key, "icb_code") |>
    dplyr::select("ICB" = icb_name, der_financial_year, value) |>
    dplyr::mutate(value = janitor::round_half_up(value, 2)) |>
    dplyr::arrange(der_financial_year) |>
    tidyr::pivot_wider(names_from = der_financial_year,
                       values_from = value) |>
    dplyr::arrange(desc(`2022/23`)) |>
    create_dt()

  return(table)
}

# To get the percentage of redetentions for a financial year:
get_perc_redetentions <- function(data, group){
  perc <- data |>
    dplyr::summarise(detentions = sum(detentions),
                     attends = sum(attends),
                     .by = c(der_financial_year, !!rlang::sym(group))) |>
    dplyr::mutate(value = attends * 100 / detentions) |>
    dplyr::filter(!!rlang::sym(group) != "NULL")

  return(perc)
}

# To get a line for % of redetentions
get_cyp_redetentions_line <- function(data){

  table <- data |>
    dplyr::summarise(detentions = sum(detentions),
                     attends = sum(attends),
                     .by = c(der_financial_year)) |>
    dplyr::mutate(perc = attends * 100 / detentions) |>
    dplyr::rename(redetentions = attends)

  plot <- table |>
    ggplot2::ggplot(ggplot2::aes(der_financial_year, perc, group = 1)) +
    ggplot2::geom_line(colour = "black",
                       linetype = "longdash") +
    ggplot2::labs(x = "Financial year",
                  y = "Percentage") +
    ggplot2::theme_minimal() +
    ggplot2::scale_y_continuous(expand = c(0, 0), limits = c(0, NA))

  return(list(plot = plot, table = table))
}

# To get a line for % of redetentions by group
get_cyp_redetentions_line_by_group <- function(data, group){

  table <- data |>
    dplyr::rename(redetentions = attends,
                  perc = value)

  plot <- get_cyp_redetentions_line(data)$plot +
    ggplot2::geom_line(ggplot2::aes(der_financial_year,
                                    perc,
                                    col = !!rlang::sym(group),
                                    group = !!rlang::sym(group)),
                       data = table) +
    ggplot2::labs(caption = "Black dashed line is the overall trend")

  return(list(plot = plot, table = table))
}

# To get % of readmissions
get_cyp_readmissions_perc <- function(data){
  wrangled <- data |>
    dplyr::summarise(detentions = sum(detentions),
                     readmissions = sum(attends),
                     .by = der_financial_year) |>
    mutate(perc = readmissions * 100 / detentions)

  return(wrangled)
}

# To get table for formal/informal redetentions
get_cyp_redetentions_formal_table <- function(data){
  wrangled <- data |>
    dplyr::summarise(redetentions = sum(attends),
                     .by = c(legal_status,
                             der_financial_year)) |>
    tidyr::pivot_wider(names_from = legal_status,
                       values_from = redetentions)

  return(wrangled)
}

# LOS - detentions -------------------------------------------------------------

# To get a line plot and table of LOS over time
get_cyp_los_line <- function(data){

  table <- data |>
    dplyr::summarise(value = median(los), .by = der_financial_year)

  plot <- table |>
    ggplot2::ggplot(ggplot2::aes(der_financial_year, value, group = 1)) +
    ggplot2::geom_line(colour = "black",
                       linetype = "longdash") +
    ggplot2::labs(x = "Financial year",
                  y = "Median length of MHA detention") +
    ggplot2::theme_minimal() +
    ggplot2::scale_y_continuous(expand = c(0, 0), limits = c(0, NA))

  return(list(plot = plot, table = table))
}

# To get a line plot and table of LOS over time by a group (gender, age, ...)
get_cyp_los_line_by_group <- function(data, group){

  table <- data |>
    dplyr::filter(!!rlang::sym(group) != "NULL") |>
    dplyr::summarise(value = median(los), .by = c(der_financial_year,
                                                  !!rlang::sym(group)))

  plot <- get_cyp_los_line(data)$plot +
    ggplot2::geom_line(ggplot2::aes(der_financial_year,
                                    value,
                                    col = !!rlang::sym(group),
                                    group = !!rlang::sym(group)),
                       data = table) +
    ggplot2::labs(caption = "Black dashed line is the overall trend")

  return(list(plot = plot, table = table))
}

# To get histogram of 23/24 los
get_cyp_los_histo <- function(data) {

  plot <- data |>
    dplyr::filter(der_financial_year == "2023/24") |>
    ggplot2::ggplot(ggplot2::aes(los)) +
    ggplot2::geom_histogram(fill = "#f9bf07") +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Length of Stay (days)")

  return(plot)
}

# To get histogram of 23/24 los < 50 days
get_cyp_los_histo_zoomed <- function(data) {

  plot <- data |>
    dplyr::filter(der_financial_year == "2023/24", los < 30) |>
    ggplot2::ggplot(ggplot2::aes(los)) +
    ggplot2::geom_histogram(fill = "#f9bf07", binwidth = 1) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Length of Stay (days)")

  return(plot)
}

# To filter cyp_los by certain sections:
get_cyp_los_by_section <- function(data, sections) {
  filtered <- data |>
    dplyr::filter(first_legal_status_code %in% c(sections))

  return(filtered)
}

# To get a percentage of spells over a specified number of days:
get_llos_perc <- function(data, llos_cutoff){

  llos_perc <- data |>
    dplyr::mutate(llos = ifelse(los > llos_cutoff, 1, 0)) |>
    summarise(count = dplyr::n(),
              perc_llos = sum(llos) * 100 / count)

  return(llos_perc)
}

# Working with conversions data ------------------------------------------------

# Identify different conversion types for MHA episodes as per Helen's list
get_conversions_mapped <- function(tar_obj) {

  data <- tar_obj |>
    mutate(conversion_desc = case_when(grepl("06-05", sections_all) ~ "Section 5(4) to Section 5(2)",
                                       grepl("19-05", sections_all) ~ "Section 135/136 to Section 5(2)/5(4) ",
                                       grepl("20-05", sections_all) ~ "Section 135/136 to Section 5(2)/5(4) ",
                                       grepl("19-06", sections_all) ~ "Section 135/136 to Section 5(2)/5(4) ",
                                       grepl("20-06", sections_all) ~ "Section 135/136 to Section 5(2)/5(4) ",
                                       grepl("05-02", sections_all) ~ "Section 5(2) to Section 2 ",
                                       grepl("05-03", sections_all) ~ "Section 5(2) to Section 3",
                                       grepl("20-02", sections_all) ~ "Section 136 to Section 2",
                                       grepl("20-03", sections_all) ~ "Section 136 to Section 3",
                                       grepl("04-02", sections_all) ~ "Section 4 to Section 2",
                                       grepl("04-03", sections_all) ~ "Section 4 to Section 3",
                                       grepl("03-03", sections_all) ~ "Section 3 renewal"),
           epi_count = stringr::str_count(sections_all,"-") + 1,
           ethnic_category = case_when(ethnic_category %in% c('A','B','C') ~ "white",
                                       ethnic_category %in% c('D','E','F','G') ~ "mixed",
                                       ethnic_category %in% c('H','J','K','L') ~ "asian",
                                       ethnic_category %in% c('M','N','P') ~ "black",
                                       ethnic_category %in% c('R','S') ~ "other",
                                       TRUE ~ "NULL"),
           imd_quintile = case_when(imd_2019_decile %in% c(1,2) ~ 1,
                                    imd_2019_decile %in% c(3,4) ~ 2,
                                    imd_2019_decile %in% c(5,6) ~ 3,
                                    imd_2019_decile %in% c(7,8) ~ 4,
                                    imd_2019_decile %in% c(9,10) ~ 5
                                    )
    )
}

# HONOS ------------------------------------------------------------------------
# To get perc of the numbers at each stage of the honos query:
get_honos_flow_perc <- function(data) {

  number_spells <- data |>
    dplyr::filter(stage == 'spells') |>
    dplyr::pull(number)

  perc <- data |>
    dplyr::mutate(perc = janitor::round_half_up(number * 100 / number_spells, 2))

  return(perc)
}

# To get a flowchart of the numbers at each stage of the honos query:
get_honos_numbers_flowchart <- function(data){

  number_spells <- data |>
    dplyr::filter(stage == 'spells') |>
    dplyr::pull(number)

  number_any_assess <- data |>
    dplyr::filter(stage == 'any_assessment') |>
    dplyr::pull(number)

  perc_any_assess <- data |>
    dplyr::filter(stage == 'any_assessment') |>
    dplyr::pull(perc)

  number_honos_assess <- data |>
    dplyr::filter(stage == 'honos_assessments') |>
    dplyr::pull(number)

  perc_honos_assess <- data |>
    dplyr::filter(stage == 'honos_assessments') |>
    dplyr::pull(perc)

  number_full_assess <- data |>
    dplyr::filter(stage == 'full_assessments') |>
    dplyr::pull(number)

  perc_full_assess <- data |>
    dplyr::filter(stage == 'full_assessments') |>
    dplyr::pull(perc)

  number_first_assess <- data |>
    dplyr::filter(stage == 'first_assessments') |>
    dplyr::pull(number)

  perc_first_assess <- data |>
    dplyr::filter(stage == 'first_assessments') |>
    dplyr::pull(perc)

  number_last_assess <- data |>
    dplyr::filter(stage == 'first_and_last_assessments') |>
    dplyr::pull(number)

  perc_last_assess <- data |>
    dplyr::filter(stage == 'first_and_last_assessments') |>
    dplyr::pull(perc)

  flowchart <- DiagrammeR::grViz("
  digraph test {
    graph []

    node [shape = box,
    style = filled,
    fillcolor = \"#f9bf07\",
    color = \"#333739\",
    fontname = Arial]

    A [label = '@@1']
    B [label = '@@2']
    C [label = '@@3']
    D [label = '@@4']
    E [label = '@@5']
    F [label = '@@6']

    A -> B
    B -> C
    C -> D
    D -> E
    E -> F

  }

  [1]: paste0('Number of CYP MH spells:', '\\n', number_spells)
  [2]: paste0('Number of CYP MH spells with at least 1 score in any assessment:', '\\n', number_any_assess, ' \\\\(', perc_any_assess, '\\\\%)')
  [3]: paste0('Number of CYP MH spells with at least 1 HONOS score:', '\\n', number_honos_assess, ' \\\\(', perc_honos_assess, '\\\\%)')
  [4]: paste0('Number of CYP MH spells with a complete HONOS assessment:', '\\n', number_full_assess, ' \\\\(', perc_full_assess, '\\\\%)')
  [5]: paste0('Number of CYP MH spells with a complete HONOS assessment \\n at the start of the spell:', '\\n', number_first_assess, ' \\\\(', perc_first_assess, '\\\\%)')
  [6]: paste0('Number of CYP MH spells with a complete HONOS assessment \\n at the start of the spell and another at the end of the spell:', '\\n', number_last_assess, ' \\\\(', perc_last_assess, '\\\\%)')
")

  return(flowchart)

}

# To get a histogram of the rates of change in honos scores:
get_honos_histo <- function(data){
  plot <- data |>
    dplyr::mutate(change = rate_of_change - 1) |>
    ggplot2::ggplot(ggplot2::aes(change)) +
    ggplot2::geom_histogram(fill = "#f9bf07") +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Relative change in HONOS scores",
                  y = "count") +
    ggplot2::geom_vline(ggplot2::aes(xintercept = 0),
                        colour = "black",
                        linetype = "longdash") +
    ggplot2::annotate("text",
                      x = c(-0.75, 0.75),
                      y = c(190, 190),
                      label = c("Improvement", "Worsening"),
                      color = "black",
                      size = 4,
                      fontface = "bold")

  return(plot)
}

# To get the perc of honos scores were rate of change > 1
get_honos_perc_worse <- function(data){

  perc <- data |>
    dplyr::mutate(worse = ifelse(rate_of_change > 1, 1, 0),
                  same = ifelse(rate_of_change == 1, 1, 0),
                  better = ifelse(rate_of_change < 1, 1, 0)) |>
    summarise(count = dplyr::n(),
              perc_worse = sum(worse) * 100 / count,
              perc_same = sum(same) * 100 / count,
              perc_better = sum(better) * 100 / count)

  return(perc)
}

# To get a scatter plot of HONOS diff against first:
get_honos_scatter <- function(data){
  plot <- data |>
    dplyr::mutate(change = rate_of_change - 1) |>
    ggplot2::ggplot(ggplot2::aes(change, first_score)) +
    ggplot2::geom_jitter(col = "salmon") +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Relative change in HONOS scores",
                  y = "HONOS score at start of spell")+
    ggplot2::geom_vline(ggplot2::aes(xintercept = 0),
                        colour = "black",
                        linetype = "longdash") +
    ggplot2::annotate("text",
                      x = c(-0.75, 0.75),
                      y = c(45, 45),
                      label = c("Improvement", "Worsening"),
                      color = "black",
                      size = 4,
                      fontface = "bold")

  return(plot)
}

