# Modifications for arrival mode breakdown plots:
modify_arrival_mode_plots <- function(plot){

  plot +
    ggplot2::facet_wrap(~arrival_mode, scales = "free") +
    ggplot2::theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))

}

# To format table and add a Copy button:
create_dt <- function(x) {
  DT::datatable(
    x,
    extensions = "Buttons",
    rownames = FALSE,
    options = list(
      dom = "Blfrtip",
      lengthChange = FALSE,
      autoWidth = TRUE,
      searching = FALSE,
      paging = FALSE,
      bInfo = FALSE,
      class = 'cell-border stripe',
      buttons = c("copy"),
      columnDefs = list(list(className = 'dt-left', targets = 0)),
      lengthMenu = list(c(10, 25, 50, -1), c(10, 25, 50, "All"))
    )
  )
}

# To get a standard table for the breakdowns:
get_standard_table_for_breakdowns <- function(data, group){

  table <- data |>
    dplyr::select(1:7) |>
    dplyr::arrange(!!rlang::sym(group), der_financial_year) |>
    dplyr::mutate(across(where(is.numeric), ~janitor::round_half_up(., 2)))

  return(table)
}

# To colour cells according to their value:
color_gradient <- function(dt, column_names, breaks) {

  for(i in column_names){
    dt <- dt |>
      DT::formatStyle(i,
                      backgroundColor = DT::styleInterval(
                        breaks,
                        RColorBrewer::brewer.pal(9, name = "Blues")
                      )
      )
  }

  return(dt)
}


get_quantiles_and_mean <- function(data) {
  table <- data |>
    dplyr::summarise(as_tibble_row(quantile(value)),
                     mean = mean(value),
                     .by = der_financial_year) |>
    create_dt()

  return(table)
}
