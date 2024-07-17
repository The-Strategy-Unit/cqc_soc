modify_arrival_mode_plots <- function(plot){

  plot +
    ggplot2::facet_wrap(~arrival_mode, scales = "free") +
    ggplot2::theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))

}