# Load necessary libraries
library(ggplot2)
library(dplyr)
library(readr)
library(janitor)

# Read in the CSV file (update the path as needed)
DTT <- read_csv("data/cyp_DTT.csv")

# Preprocess the data: calculate average distance per admission
clean_travel_distance <- DTT %>%
  mutate(Average_Distance_Per_Admission = TOTAL_DISTANCE / ADMISSIONS) %>%
  filter(!is.na(Average_Distance_Per_Admission))

# Define the order of the financial years explicitly
fin_year_order <- c("2017-2018", "2018-2019", "2019-2020", "2020-2021",
                    "2021-2022", "2022-2023", "2023-2024", "2024-2025")

# Convert FIN_YEAR to a factor and set the levels in chronological order
clean_travel_distance <- clean_travel_distance %>%
  mutate(FIN_YEAR = factor(FIN_YEAR, levels = fin_year_order))

# Summarise the data by ICB and Financial Year
summarised_travel_distance_icb <- clean_travel_distance %>%
  group_by(ICB23NM, FIN_YEAR) %>%
  summarise(
    total_distance = sum(TOTAL_DISTANCE),
    total_admissions = sum(ADMISSIONS),
    avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
  )

# Create the plot with ordered FIN_YEAR
ggplot(summarised_travel_distance_icb, aes(x = FIN_YEAR, y = avg_distance, group = ICB23NM)) +
  geom_line(aes(colour = as.factor(ICB23NM))) +
  geom_point(aes(colour = as.factor(ICB23NM))) +  # Add points for each year
  scale_color_manual(values = scales::hue_pal()(length(unique(summarised_travel_distance_icb$ICB23NM))), name = "ICB") +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  theme_minimal() +
  labs(
    title = "Average Travel Distance Per Admission by ICB",
    subtitle = "All ICBs 2017/18 to 2024/25",
    x = "Financial Year",
    y = "Average Distance (km)"
  ) +
  scale_x_discrete(guide = guide_axis(angle = 45))  # Rotate x-axis labels for readability

# Optionally, save the plot to a file
ggsave("travel_distance_plot.png", width = 10, height = 6)



