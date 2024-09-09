#This is an example thing I made with Anya - needs to be listed here for targets file to read

#First thing:
get_table_DTT_FY <- function (data){ DTT_FY <- data |>
  dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                   .by = fin_year) |>
  mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) |>
  create_dt()
return (DTT_FY) # do the return because some functions do more than one thing

}
