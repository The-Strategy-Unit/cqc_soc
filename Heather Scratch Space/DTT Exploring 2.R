#Exploring

#By FY
FY_data <- data |>
  group_by(FIN_YEAR) |>
  summarize(average_distance_per_admission = mean(average_distance_per_admission, na.rm = TRUE))

ggplot(FY_data, aes(x = FIN_YEAR, y = average_distance_per_admission)) +
  geom_col(fill = su_colours_top_5_expanded) +
  geom_text(aes(label = round(average_distance_per_admission, 0), vjust = -0.5, hjust = 0.5)) +
  labs(title = "Average Distance per Admission by Financial Year",
       x = "Financial Year",
       y = "Average Distance per Admission") +
  theme_minimal() +
  scale_x_discrete(limits = levels(p1_data$FIN_YEAR))
ggsave("Heather Scratch Space/plotFY.png", plot = last_plot(), width = 8, height = 6)

#By Age Group

AG_data <- data |>
  filter(FIN_YEAR == "2024-2025") |>
  group_by(age_group) |>
  summarize(average_distance_per_admission = mean(average_distance_per_admission, na.rm = TRUE))

ggplot(AG_data, aes(x = age_group, y = average_distance_per_admission)) +
  geom_col(fill = su_colours_top_2) +
  geom_text(aes(label = round(average_distance_per_admission, 0), vjust = -0.5, hjust = 0.5)) +
  labs(title = "Average Distance per Admission by Age Group",
       x = "Age Group",
       y = "Average Distance per Admission") +
  theme_minimal() +
  scale_x_discrete(limits = levels(Age_data$age_group))

ggsave("Heather Scratch Space/plotAG.png", plot = last_plot(), width = 8, height = 6)

#IMD
IMD_data <- data |>
  filter(FIN_YEAR == "2024-2025" & imd_2019_decile != "NULL") |>
  group_by(imd_2019_decile) |>
  summarize(average_distance_per_admission = mean(average_distance_per_admission, na.rm = TRUE))

ggplot(IMD_data, aes(x = imd_2019_decile, y = average_distance_per_admission)) +
  geom_col(fill = su_colours_top_5_expanded) +
  geom_text(aes(label = round(average_distance_per_admission, 0), vjust = -0.5, hjust = 0.5)) +
  labs(title = "Average Distance per Admission by IMD",
       x = "IMD",
       y = "Average Distance per Admission") +
  theme_minimal() #+
 # scale_x_discrete(limits = levels(Age_data$age_group))

ggsave("Heather Scratch Space/plotIMD.png", plot = last_plot(), width = 8, height = 6)

FY_IMD_data <- data |>
  filter(imd_2019_decile != "NULL") |>
  group_by(imd_2019_decile) |>
  summarize(average_distance_per_admission = mean(average_distance_per_admission, na.rm = TRUE))

ggplot(IMD_data, aes(x = imd_2019_decile, y = average_distance_per_admission)) +
  geom_line() +
  geom_point() +
  labs(title = "Average Distance per Admission by IMD Decile",
       x = "IMD Decile",
       y = "Average Distance per Admission") +
  theme_minimal()