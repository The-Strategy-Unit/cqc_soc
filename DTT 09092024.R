# DTT 09/09/2024

tar_read(travel_distance_plot)
tar_read(travel_distance_raw)
tar_read(travel_distance_clean)
tar_read(travel_distance_summary_by_icb)

tar_target(
  travel_distance_raw,
  read_csv("data/cyp_DTT.csv"), # Ensure this path is correct
  format = "file"
)

tar_make()

tar_source()

tar_read(DTT) %>% colnames()

tar_read(travel_distance_summary_by_icb)

tar_target(
  travel_distance_summary_by_icb,
  travel_distance_clean %>%
    group_by(ICB23NM, FIN_YEAR) %>%
    summarise(
      total_distance = sum(TOTAL_DISTANCE),
      total_admissions = sum(ADMISSIONS),
      avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
    )
)

tar_read(travel_distance_summary_by_icb)



tar_read(travel_distance_clean)

str(tar_read(travel_distance_summary_by_icb))

tar_invalidate(travel_distance_clean, travel_distance_summary_by_icb)
tar_make()

targets::tar_meta(fields = error, complete_only = TRUE)

tar_read(travel_distance_clean)


tar_invalidate(everything())
tar_make()

summarised_travel_distance_icb %>%
  count(ICB23NM, FIN_YEAR)


# 08. DTT (Heather) -------------------------------------------------------------------

# Define file path
tarchetypes::tar_file(DTT_filepath, "data/cyp_DTT.csv"),

# Load the data using read_csv()
tar_target(DTT, read_csv(DTT_filepath)),

# Process the data using get_table_DTT_FY
tar_target(table_DTT_FY, get_table_DTT_FY(DTT)),

# Preprocess travel distance data
tar_target(
  clean_travel_distance,
  DTT %>%
    mutate(
      Average_Distance_Per_Admission = TOTAL_DISTANCE / ADMISSIONS
    ) %>%
    filter(!is.na(Average_Distance_Per_Admission))
),

# Aggregate the data by ICB and Financial Year
tar_target(
  summarised_travel_distance_icb,
  clean_travel_distance %>%
    mutate(FIN_YEAR = factor(FIN_YEAR, levels = unique(FIN_YEAR))) %>%
    group_by(ICB23NM, FIN_YEAR) %>%
    summarise(
      total_distance = sum(TOTAL_DISTANCE),
      total_admissions = sum(ADMISSIONS),
      avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
    )
),

# Create the plot using the travel_distance_plot function
tar_target(
  travel_distance_plot_obj,
  travel_distance_plot(summarised_travel_distance_icb)
),

# Save the plot
tar_target(
  save_travel_distance_plot,
  ggsave("plots/travel_distance_plot.png", travel_distance_plot_obj, width = 10, height = 6),
  format = "file"
)


