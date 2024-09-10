#DTT Things for Targets to grab#################################################

#Summary Tables ################################################################
#Overview:
get_table_DTT_FY <- function (data){ DTT_FY <- data |>
  filter(!is.na(fin_year) & fin_year != "NULL") %>%
  dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                   .by = fin_year) |>
  mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) #|>
  #create_dt()
return (DTT_FY) # do the return because some functions do more than one thing
}

#Gender
get_table_DTT_gender_FY <- function(data) {
  DTT_gender_FY <- data %>%
    filter(!is.na(gender_desc) & gender_desc != "NULL") %>%
    dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                     .by = c(gender_desc, fin_year)) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) #%>%
    #create_dt()
  return(DTT_gender_FY)
}

# Age Group
get_table_DTT_age_group_FY <- function(data) {
  DTT_age_group_FY <- data %>%
    filter(!is.na(age_group) & age_group != "NULL") %>%
    dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                     .by = c(age_group, fin_year)) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) #%>%
    #create_dt()
  return(DTT_age_group_FY)
}

# Ethnic Category
get_table_DTT_ethnic_FY <- function(data) {
  DTT_ethnic_FY <- data %>%
    filter(!is.na(ethnic_category) & ethnic_category != "NULL") %>%
    dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                     .by = c(ethnic_category, fin_year)) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) #%>%
    #create_dt()
  return(DTT_ethnic_FY)
}

# IMD (Index of Multiple Deprivation)
get_table_DTT_IMD_FY <- function(data) {
  DTT_IMD_FY <- data %>%
    filter(!is.na(imd_2019_decile) & imd_2019_decile != "NULL") %>%
    dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                     .by = c(imd_2019_decile, fin_year)) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1))%>%
    mutate(imd_2019_decile = factor(imd_2019_decile, levels = as.character(1:10)))
    # Order IMD from 1-10
    #create_dt()
  return(DTT_IMD_FY)
}

#Charts ########################################################################
# Overview Chart
get_chart_DTT_FY <- function(data, su_colours) {
  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance, group = 1)) +
    geom_line(aes(color = "Average Distance"), linewidth = 1) +
    geom_point(aes(color = "Average Distance"), size = 2) +
    scale_color_manual(values = su_colours["su_blue"]) +
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)"
    ) +
    theme(legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1))
  return(plot)
}

# Gender Chart
get_chart_DTT_gender_FY <- function(data, overall_data, su_colours) {
  gender_levels <- unique(data$gender_desc)
  gender_colours <- setNames(su_colours[1:length(gender_levels)], gender_levels)
  gender_colours["Overall"] <- "black"  # Add overall line as black

  # Combine gender data with overall data
  overall_data <- overall_data %>%
    mutate(gender_desc = "Overall")  # Add "Overall" label
  combined_data <- bind_rows(data, overall_data)  # Combine the data

  # Create the plot
  plot <- ggplot(combined_data, aes(x = fin_year, y = Average_Distance, group = gender_desc)) +
    geom_line(aes(color = gender_desc, linetype = ifelse(gender_desc == "Overall", "dashed", "solid")), linewidth = 1) +
    geom_point(aes(color = gender_desc), size = 2) +
    scale_color_manual(values = gender_colours) +
    scale_linetype_identity() +
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by Gender Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Gender",
      linetype = "Line Type"
    ) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1))
  return(plot)
}

# Age Group Chart
get_chart_DTT_age_group_FY <- function(data, overall_data, su_colours) {
  age_levels <- unique(data$age_group)
  age_colours <- setNames(su_colours[1:length(age_levels)], age_levels)
  age_colours["Overall"] <- "black"  # Add overall line as black

  # Combine age group data with overall data
  overall_data <- overall_data %>%
    mutate(age_group = "Overall")  # Add "Overall" label
  combined_data <- bind_rows(data, overall_data)  # Combine the data

  # Create the plot
  plot <- ggplot(combined_data, aes(x = fin_year, y = Average_Distance, group = age_group)) +
    geom_line(aes(color = age_group, linetype = ifelse(age_group == "Overall", "dashed", "solid")), linewidth = 1) +
    geom_point(aes(color = age_group), size = 2) +
    scale_color_manual(values = age_colours) +
    scale_linetype_identity() +
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by Age Group Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Age Group",
      linetype = "Line Type"
    ) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1))
  return(plot)
}

# Ethnic Category Chart
get_chart_DTT_ethnic_FY <- function(data, overall_data, su_colours) {
  ethnic_levels <- unique(data$ethnic_category)
  ethnic_colours <- setNames(su_colours[1:length(ethnic_levels)], ethnic_levels)
  ethnic_colours["Overall"] <- "black"

  # Combine ethnic data with overall data
  overall_data <- overall_data %>%
    mutate(ethnic_category = "Overall")  # Add "Overall" label
  combined_data <- bind_rows(data, overall_data)  # Combine the data

  # Create the plot
  plot <- ggplot(combined_data, aes(x = fin_year, y = Average_Distance, group = ethnic_category)) +
    geom_line(aes(color = ethnic_category, linetype = ifelse(ethnic_category == "Overall", "dashed", "solid")), linewidth = 1) +
    geom_point(aes(color = ethnic_category), size = 2) +
    scale_color_manual(values = ethnic_colours) +
    scale_linetype_identity() +
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by Ethnic Category Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Ethnic Category",
      linetype = "Line Type"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  return(plot)
}

# IMD Chart
get_chart_DTT_IMD_FY <- function(data, imd_colours) {
  #IMD deciles as a factor
  data <- data %>%
    mutate(imd_2019_decile = factor(imd_2019_decile, levels = as.character(1:10)))

  #Create plot
    plot <- ggplot(data, aes(x = fin_year, y = Average_Distance, group = imd_2019_decile, color = imd_2019_decile)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_color_manual(values = imd_colours) +
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by IMD Decile Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "IMD Decile"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  return(plot)
}

#DTT Formatting ################################################################
get_custom_colours <- function() {
  # Define SU colour palette
  su_colours <- c(
    su_yellow = '#f9bf07',
    su_red = '#ec6555',
    su_blue = '#5881c1',
    su_grey = '#686f73',
    su_black = '#2c2825',
    su_light_yellow = '#ffe699',
    su_light_red = '#f4a39a',
    su_light_blue = '#b4c6e6',
    su_light_grey = '#d9d9d9')

  # Make colours for IMD
  imd_colours_custom <- colorRampPalette(c(su_colours["su_red"], su_colours["su_grey"], su_colours["su_light_blue"]))(10)

  # Return a list containing both colour sets
  return(list(
    su_colours = su_colours,
    imd_colours_custom = imd_colours_custom
  ))
}

# Admissions by DTT Overview #############################################################

# Admissions vs Travel Distance Table
get_table_DTT_FY_with_admissions <- function(data) {
  DTT_FY_with_admissions <- data %>%
    filter(!is.na(fin_year) & fin_year != "NULL") %>%
    dplyr::summarise(
      Average_Distance = mean(average_distance_per_admission, na.rm = TRUE),  # Average distance
      Total_Admissions = sum(admissions, na.rm = TRUE),  # Total admissions
      .by = fin_year
    ) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1))  # Rounding the average distance
  return(DTT_FY_with_admissions)
}

# Step 1: Data Preparation
prepare_admissions_distance_data <- function(data) {
  data_prepared <- data %>%
    mutate(
      category_fill = factor("Total Admissions", levels = c("Total Admissions")),
      category_line = factor("Average Distance", levels = c("Average Distance"))
    )

  # Debug: Print the structure of the data prepared
  print("Data Structure after preparing factors:")
  print(str(data_prepared))

  return(data_prepared)
}

# Step 2: Bar Plot (Admissions)
get_admissions_bar_plot <- function(data, su_colours) {
  bar_plot <- ggplot(data, aes(x = fin_year, y = Total_Admissions)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.7, fill = su_colours["su_yellow"]) +
    theme_minimal() +
    labs(
      y = "Total Admissions",
      fill = "Metric"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(bar_plot)
}

# Step 3: Line Plot (Average Distance)
get_distance_line_plot <- function(data, su_colours) {
  line_plot <- ggplot(data, aes(x = fin_year, y = Average_Distance * 1000, group = 1)) +
    geom_line(linewidth = 1, color = su_colours["su_blue"]) +  # Use `color` directly
    geom_point(size = 3, color = su_colours["su_blue"]) +
    theme_minimal() +
    labs(
      y = "Average Distance (km)",
      color = "Metric"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(line_plot)
}

# Step 4: Combine Bar and Line Plots
combine_admissions_distance_plot <- function(bar_plot, line_plot, data, su_colours) {
  combined_plot <- ggplot(data, aes(x = fin_year)) +

    # Add bar plot for total admissions
    geom_bar(aes(y = Total_Admissions), stat = "identity", position = "dodge", alpha = 0.7, fill = su_colours["su_yellow"]) +

    # Add line plot for average distance
    geom_line(aes(y = Average_Distance * 1000, group = 1), linewidth = 1, color = su_colours["su_blue"]) +
    geom_point(aes(y = Average_Distance * 1000), size = 3, color = su_colours["su_blue"]) +

    # Add dual axis (primary for total admissions, secondary for average distance)
    scale_y_continuous(
      name = "Total Admissions",
      sec.axis = sec_axis(~./1000, name = "Average Distance (km)")
    ) +

    theme_minimal() +
    labs(
      title = "Comparison of Total Admissions and Average Travel Distance Over Time",
      x = "Financial Year",
      fill = "Metric",
      color = "Metric"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(combined_plot)
}

# Step 5: Chart Function
get_chart_admissions_vs_distance <- function(data, su_colours) {
  # Step 1: Prepare Data
  data_prepared <- prepare_admissions_distance_data(data)

  # Step 2: Create Bar Plot
  bar_plot <- get_admissions_bar_plot(data_prepared, su_colours)

  # Step 3: Create Line Plot
  line_plot <- get_distance_line_plot(data_prepared, su_colours)

  # Step 4: Combine Plots
  combined_plot <- combine_admissions_distance_plot(bar_plot, line_plot, data_prepared, su_colours)

  return(combined_plot)
}

# Admissions by DTT Subgroups Tables ##################################################
# Table for Gender
get_table_DTT_gender_FY_with_admissions <- function(data) {
  DTT_gender_FY_with_admissions <- data %>%
    filter(!is.na(gender_desc) & gender_desc != "NULL") %>%
    dplyr::summarise(
      Average_Distance = mean(average_distance_per_admission, na.rm = TRUE),
      Total_Admissions = sum(admissions, na.rm = TRUE),
      .by = c(gender_desc, fin_year)
    ) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1))
  return(DTT_gender_FY_with_admissions)
}

#Table for Age Group
get_table_DTT_age_group_FY_with_admissions <- function(data) {
  DTT_age_group_FY_with_admissions <- data %>%
    filter(!is.na(age_group) & age_group != "NULL") %>%
    dplyr::summarise(
      Average_Distance = mean(average_distance_per_admission, na.rm = TRUE),
      Total_Admissions = sum(admissions, na.rm = TRUE),
      .by = c(age_group, fin_year)
    ) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1))
  return(DTT_age_group_FY_with_admissions)
}

#Table for Ethnic Category
get_table_DTT_ethnic_FY_with_admissions <- function(data) {
  DTT_ethnic_FY_with_admissions <- data %>%
    filter(!is.na(ethnic_category) & ethnic_category != "NULL") %>%
    dplyr::summarise(
      Average_Distance = mean(average_distance_per_admission, na.rm = TRUE),
      Total_Admissions = sum(admissions, na.rm = TRUE),
      .by = c(ethnic_category, fin_year)
    ) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1))
  return(DTT_ethnic_FY_with_admissions)
}

#Table for IMD (Index of Multiple Deprivation)
get_table_DTT_IMD_FY_with_admissions <- function(data) {
  DTT_IMD_FY_with_admissions <- data %>%
    filter(!is.na(imd_2019_decile) & imd_2019_decile != "NULL") %>%
    dplyr::summarise(
      Average_Distance = mean(average_distance_per_admission, na.rm = TRUE),
      Total_Admissions = sum(admissions, na.rm = TRUE),
      .by = c(imd_2019_decile, fin_year)
    ) %>%
    mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) %>%
    mutate(imd_2019_decile = factor(imd_2019_decile, levels = as.character(1:10)))
  return(DTT_IMD_FY_with_admissions)
}

# Admissions by DTT Subgroups Charts - Gender ##################################################
# Chart for Gender with Admissions
# Step 1: Data Preparation by Gender
prepare_admissions_distance_data_gender <- function(data) {
  data_prepared <- data %>%
    mutate(
      category_fill = factor("Total Admissions", levels = c("Total Admissions")),
      category_line = factor("Average Distance", levels = c("Average Distance"))
    )

  # Debug: Print the structure of the data prepared
  print("Data Structure after preparing factors by Gender:")
  print(str(data_prepared))

  return(data_prepared)
}

# Step 2: Bar Plot (Admissions) by Gender
get_admissions_bar_plot_gender <- function(data, su_colours) {
  gender_levels <- unique(data$gender_desc)
  gender_colours <- setNames(su_colours[1:length(gender_levels)], gender_levels)

  bar_plot <- ggplot(data, aes(x = fin_year, y = Total_Admissions, fill = gender_desc)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.7) +
    scale_fill_manual(values = gender_colours) +
    theme_minimal() +
    labs(
      y = "Total Admissions",
      fill = "Gender"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(bar_plot)
}

# Step 3: Line Plot (Average Distance) by Gender
get_distance_line_plot_gender <- function(data, su_colours) {
  gender_levels <- unique(data$gender_desc)
  gender_colours <- setNames(su_colours[1:length(gender_levels)], gender_levels)

  line_plot <- ggplot(data, aes(x = fin_year, y = Average_Distance * 1000, group = gender_desc, color = gender_desc)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = gender_colours) +
    theme_minimal() +
    labs(
      y = "Average Distance (km)",
      color = "Gender"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(line_plot)
}

# Step 4: Combine Bar and Line Plots by Gender
combine_admissions_distance_plot_gender <- function(bar_plot, line_plot, data, su_colours) {
  gender_levels <- unique(data$gender_desc)
  gender_colours <- setNames(su_colours[1:length(gender_levels)], gender_levels)

  combined_plot <- ggplot(data, aes(x = fin_year)) +

    # Add bar plot for total admissions
    geom_bar(aes(y = Total_Admissions, fill = gender_desc), stat = "identity", position = "dodge", alpha = 0.7) +

    # Add line plot for average distance
    geom_line(aes(y = Average_Distance * 1000, group = gender_desc, color = gender_desc), linewidth = 1) +
    geom_point(aes(y = Average_Distance * 1000, color = gender_desc), size = 3) +

    # Add dual axis (primary for total admissions, secondary for average distance)
    scale_y_continuous(
      name = "Total Admissions",
      sec.axis = sec_axis(~./1000, name = "Average Distance (km)")
    ) +

    # Ensure consistent coloring by gender
    scale_fill_manual(values = gender_colours) +
    scale_color_manual(values = gender_colours) +

    theme_minimal() +
    labs(
      title = "Comparison of Total Admissions and Average Travel Distance by Gender Over Time",
      x = "Financial Year",
      fill = "Gender",
      color = "Gender"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(combined_plot)
}

# Step 5: Final Chart Function by Gender
get_chart_admissions_vs_distance_gender <- function(data, su_colours) {
  # Step 1: Prepare Data
  data_prepared <- prepare_admissions_distance_data_gender(data)

  # Step 2: Create Bar Plot
  bar_plot <- get_admissions_bar_plot_gender(data_prepared, su_colours)

  # Step 3: Create Line Plot
  line_plot <- get_distance_line_plot_gender(data_prepared, su_colours)

  # Step 4: Combine Plots
  combined_plot <- combine_admissions_distance_plot_gender(bar_plot, line_plot, data_prepared, su_colours)

  return(combined_plot)
}







# Admissions by DTT Subgroups Charts - Age Group ##################################################
# Chart for Age Group with Admissions
# Custom color generation based on number of unique age groups
generate_age_group_colours <- function(data, su_colours) {
  age_group_levels <- unique(data$age_group)  # Extract unique age groups
  n_age_groups <- length(age_group_levels)  # Get the number of unique age groups

  # Generate color palette based on SU colors (you can choose different colors if needed)
  age_group_colours <- colorRampPalette(c(su_colours["su_yellow"], su_colours["su_blue"]))(n_age_groups)

  # Create named vector for the palette
  names(age_group_colours) <- age_group_levels

  return(age_group_colours)
}

# Step 1: Data Preparation for Age Group
prepare_admissions_distance_data_age <- function(data) {
  data_prepared <- data %>%
    mutate(
      category_fill = factor("Total Admissions", levels = c("Total Admissions")),
      category_line = factor("Average Distance", levels = c("Average Distance")),
      age_group = factor(age_group, levels = unique(age_group))  # Correct factor levels for age_group
    )

  # Debug: Print the structure of the data prepared
  print("Data Structure after preparing factors by Age Group:")
  print(str(data_prepared))

  return(data_prepared)
}

# Step 2: Bar Plot for Total Admissions by Age Group
get_admissions_bar_plot_age <- function(data, age_group_colours) {
  bar_plot <- ggplot(data, aes(x = fin_year, y = Total_Admissions, fill = age_group)) +
    geom_bar(stat = "identity", position = "dodge", alpha = 0.7) +
    scale_fill_manual(values = age_group_colours) +
    theme_minimal() +
    labs(
      y = "Total Admissions",
      fill = "Age Group"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(bar_plot)
}

# Step 3: Line Plot for Average Distance by Age Group
get_distance_line_plot_age <- function(data, age_group_colours) {
  line_plot <- ggplot(data, aes(x = fin_year, y = Average_Distance * 1000, group = age_group, color = age_group)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = age_group_colours) +  # Explicit color mapping
    theme_minimal() +
    labs(
      y = "Average Distance (km)",
      color = "Age Group"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(line_plot)
}

# Step 4: Combine Bar and Line Plots for Age Group
combine_admissions_distance_plot_age <- function(bar_plot, line_plot, data, age_group_colours) {
  combined_plot <- ggplot(data, aes(x = fin_year)) +

    # Bar plot for total admissions, colored by age group
    geom_bar(aes(y = Total_Admissions, fill = age_group), stat = "identity", position = "dodge", alpha = 0.7) +

    # Line plot for average distance, colored by age group
    geom_line(aes(y = Average_Distance * 1000, color = age_group, group = age_group), linewidth = 1) +
    geom_point(aes(y = Average_Distance * 1000, color = age_group), size = 3) +

    # Set dual axis
    scale_y_continuous(
      name = "Total Admissions",
      sec.axis = sec_axis(~./1000, name = "Average Distance (km)")
    ) +

    scale_fill_manual(values = age_group_colours) +  # Fill for bars
    scale_color_manual(values = age_group_colours) +  # Color for lines

    theme_minimal() +
    labs(
      title = "Comparison of Total Admissions and Average Travel Distance by Age Group Over Time",
      x = "Financial Year",
      fill = "Age Group",
      color = "Age Group"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(combined_plot)
}

# Step 5: Chart Function for Age Group Breakdown
get_chart_admissions_vs_distance_age <- function(data, su_colours) {
  # Step 1: Prepare Data
  data_prepared <- prepare_admissions_distance_data_age(data)

  # Step 2: Generate colors for age groups based on the data
  age_group_colours <- generate_age_group_colours(data_prepared, su_colours)

  # Step 3: Create Bar Plot
  bar_plot <- get_admissions_bar_plot_age(data_prepared, age_group_colours)

  # Step 4: Create Line Plot
  line_plot <- get_distance_line_plot_age(data_prepared, age_group_colours)

  # Step 5: Combine Plots
  combined_plot <- combine_admissions_distance_plot_age(bar_plot, line_plot, data_prepared, age_group_colours)

  return(combined_plot)
}
