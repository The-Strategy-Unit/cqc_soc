#Running Targets
tar_make()
get_table_DTT_FY()
print(colnames(DTT))

print(unique(data$Total_Admissions))
print(unique(data$Average_Distance))

tar_read(table_DTT_gender_FY_with_admissions)



# 1: General Setup ################################################################
# Load necessary libraries
library(ggplot2)
library(dplyr)
library(readr)
library(janitor)

# Define your color scheme
su_yellow <- '#f9bf07'
su_red <- '#ec6555'
su_blue <- '#5881c1'
su_grey <- '#686f73'
su_black <- '#2c2825'
su_light_yellow <- '#ffe699'
su_light_red <- '#f4a39a'
su_light_blue <- '#b4c6e6'
su_light_grey <- '#d9d9d9'

# Define SU color palette
su_colors <- c(su_yellow, su_red, su_blue, su_grey, su_black,
               su_light_yellow, su_light_red, su_light_blue, su_light_grey)

# Read in the CSV file (update the path as needed)
DTT <- read_csv("data/cyp_DTT.csv")

# 2: Average Travel Distance over Time #############################################
# Preprocess the data: calculate average distance per admission and ensure no NA values in FIN_YEAR
clean_travel_distance <- DTT %>%
  mutate(Average_Distance_Per_Admission = TOTAL_DISTANCE / ADMISSIONS) %>%
  filter(!is.na(Average_Distance_Per_Admission)) %>%
  mutate(FIN_YEAR = ifelse(is.na(FIN_YEAR) | FIN_YEAR == "" | FIN_YEAR == "NA", NA, FIN_YEAR)) %>%
  filter(!is.na(FIN_YEAR))  # Remove rows where FIN_YEAR is NA

# Define the order of the financial years explicitly
fin_year_order <- c("2017-2018", "2018-2019", "2019-2020", "2020-2021",
                    "2021-2022", "2022-2023", "2023-2024", "2024-2025")

# Convert FIN_YEAR to a factor and set the levels in chronological order
clean_travel_distance <- clean_travel_distance %>%
  mutate(FIN_YEAR = factor(FIN_YEAR, levels = fin_year_order))

# Summarise the average distance per admission by Financial Year
avg_distance_by_year <- clean_travel_distance %>%
  group_by(FIN_YEAR) %>%
  summarise(
    avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
  )

# Final filtering: Remove rows where FIN_YEAR is NA
avg_distance_by_year <- avg_distance_by_year %>%
  filter(!is.na(FIN_YEAR))  # This ensures no NA in the final table

# Create the plot with the SU color palette
ggplot(avg_distance_by_year, aes(x = FIN_YEAR, y = avg_distance, group = 1)) +
  geom_line(aes(color = "Average Distance"), linewidth = 1) +  # Using linewidth instead of size
  geom_point(aes(color = "Average Distance"), size = 3) +  # Keeping size for points
  scale_color_manual(values = c(su_blue)) +  # Using SU blue color for the line
  theme_minimal() +
  labs(
    title = "Average Travel Distance Per Admission Over Time",
    subtitle = "All ICBs 2017/18 to 2024/25",
    x = "Financial Year",
    y = "Average Distance (km)"
  ) +
  theme(
    legend.position = "none",  # Remove the legend if unnecessary
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Optionally, save the plot to a file
ggsave("plots/avg_distance_over_time_plot.png", width = 10, height = 6)

# 3: Average Travel Distance by Gender ############################################

# Summarise the average distance per admission by Financial Year and Gender
avg_distance_by_gender <- clean_travel_distance %>%
  filter(!is.na(gender_desc) & gender_desc != "NULL") %>%  # Remove rows where gender_desc is NA or NULL
  group_by(FIN_YEAR, gender_desc) %>%  # Ensure gender_desc is the correct column for gender
  summarise(
    avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
  )

# Final filtering: Remove rows where FIN_YEAR or gender_desc is NA
avg_distance_by_gender <- avg_distance_by_gender %>%
  filter(!is.na(FIN_YEAR) & !is.na(gender_desc))  # Ensure no missing FIN_YEAR or gender_desc

# Create the plot with lines for each gender using SU color palette
ggplot(avg_distance_by_gender, aes(x = FIN_YEAR, y = avg_distance, group = gender_desc, color = gender_desc)) +
  geom_line(linewidth = 1) +  # Using linewidth for lines
  geom_point(size = 3) +  # Points for each year and gender
  scale_color_manual(values = c(su_blue, su_red)) +  # Assign SU blue and red for genders
  theme_minimal() +
  labs(
    title = "Average Travel Distance Per Admission by Gender Over Time",
    subtitle = "2017/18 to 2024/25",
    x = "Financial Year",
    y = "Average Distance (km)",  # Added the unit "km" back to the y-axis label
    color = "Gender"  # Legend title for gender
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)  # Rotate x-axis labels
  )

# Optionally, save the plot to a file
ggsave("plots/avg_distance_by_gender_over_time_plot.png", width = 10, height = 6)

# 4: Average Travel Distance by IMD ############################################

# Summarise the average distance per admission by Financial Year and IMD
avg_distance_by_imd <- clean_travel_distance %>%
  filter(!is.na(imd_2019_decile) & imd_2019_decile != "NULL") %>%  # Remove rows where IMD is NA or NULL
  group_by(FIN_YEAR, imd_2019_decile) %>%  # Group by FIN_YEAR and IMD decile
  summarise(
    avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
  )

# Final filtering: Remove rows where FIN_YEAR or imd_2019_decile is NA
avg_distance_by_imd <- avg_distance_by_imd %>%
  filter(!is.na(FIN_YEAR) & !is.na(imd_2019_decile))  # Ensure no missing FIN_YEAR or IMD

# Create a custom color gradient with decile 5 as the midpoint
imd_colors_custom <- colorRampPalette(c(su_red, su_grey, su_light_blue))(10)  # 10 colors, with su_grey as midpoint

# Ensure IMD deciles are ordered correctly (from 1 to 10)
avg_distance_by_imd <- avg_distance_by_imd %>%
  mutate(imd_2019_decile = factor(imd_2019_decile, levels = as.character(1:10)))

# Create the plot with the new custom color palette for IMD deciles
ggplot(avg_distance_by_imd, aes(x = FIN_YEAR, y = avg_distance, group = imd_2019_decile, color = as.factor(imd_2019_decile))) +
  geom_line(linewidth = 1) +  # Using linewidth for lines
  geom_point(size = 3) +  # Points for each year and IMD decile
  scale_color_manual(values = imd_colors_custom) +  # Use the custom IMD color palette
  theme_minimal() +
  labs(
    title = "Average Travel Distance Per Admission by IMD Over Time",
    subtitle = "2017/18 to 2024/25",
    x = "Financial Year",
    y = "Average Distance (km)",
    color = "IMD Decile"  # Legend title for IMD decile
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)  # Rotate x-axis labels
  )

# Optionally, save the plot to a file
ggsave("plots/avg_distance_by_imd_over_time_plot.png", width = 10, height = 6)

# 5: Average Travel Distance by Age Group ############################################

# Summarise the average distance per admission by Financial Year and Age Group
avg_distance_by_age <- clean_travel_distance %>%
  filter(!is.na(age_group) & age_group != "NULL") %>%  # Remove rows where age_group is NA or NULL
  group_by(FIN_YEAR, age_group) %>%  # Group by FIN_YEAR and age_group
  summarise(
    avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
  )

# Final filtering: Remove rows where FIN_YEAR or age_group is NA
avg_distance_by_age <- avg_distance_by_age %>%
  filter(!is.na(FIN_YEAR) & !is.na(age_group))  # Ensure no missing FIN_YEAR or age_group

# Create the plot with lines for each age group using SU color palette
ggplot(avg_distance_by_age, aes(x = FIN_YEAR, y = avg_distance, group = age_group, color = as.factor(age_group))) +
  geom_line(linewidth = 1) +  # Using linewidth for lines
  geom_point(size = 3) +  # Points for each year and age group
  scale_color_manual(values = su_colors) +  # Use SU color palette
  theme_minimal() +
  labs(
    title = "Average Travel Distance Per Admission by Age Group Over Time",
    subtitle = "2017/18 to 2024/25",
    x = "Financial Year",
    y = "Average Distance (km)",
    color = "Age Group"  # Legend title for age group
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)  # Rotate x-axis labels
  )

# Optionally, save the plot to a file
ggsave("plots/avg_distance_by_age_over_time_plot.png", width = 10, height = 6)

# 6: Average Travel Distance by Ethnic Category ############################################

# Summarise the average distance per admission by Financial Year and Ethnic Category
avg_distance_by_ethnic_category <- clean_travel_distance %>%
  filter(!is.na(Ethnic_Category) & Ethnic_Category != "NULL") %>%  # Remove rows where Ethnic_Category is NA or NULL
  group_by(FIN_YEAR, Ethnic_Category) %>%  # Group by FIN_YEAR and Ethnic_Category
  summarise(
    avg_distance = mean(Average_Distance_Per_Admission, na.rm = TRUE)
  )

# Final filtering: Remove rows where FIN_YEAR or Ethnic_Category is NA
avg_distance_by_ethnic_category <- avg_distance_by_ethnic_category %>%
  filter(!is.na(FIN_YEAR) & !is.na(Ethnic_Category))  # Ensure no missing FIN_YEAR or Ethnic_Category

# Create the plot with lines for each ethnic category using SU color palette
ggplot(avg_distance_by_ethnic_category, aes(x = FIN_YEAR, y = avg_distance, group = Ethnic_Category, color = as.factor(Ethnic_Category))) +
  geom_line(linewidth = 1) +  # Using linewidth for lines
  geom_point(size = 3) +  # Points for each year and ethnic category
  scale_color_manual(values = su_colors) +  # Use SU color palette
  theme_minimal() +
  labs(
    title = "Average Travel Distance Per Admission by Ethnic Category Over Time",
    subtitle = "2017/18 to 2024/25",
    x = "Financial Year",
    y = "Average Distance (km)",
    color = "Ethnic Category"  # Legend title for ethnic category
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)  # Rotate x-axis labels
  )

# Optionally, save the plot to a file
ggsave("plots/avg_distance_by_ethnic_category_over_time_plot.png", width = 10, height = 6)



# End ##########################################################################



