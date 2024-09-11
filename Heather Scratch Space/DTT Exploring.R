#Exploring the data
#Load Data into R
data <- read.csv("Z:/Strategic Analytics/Projects 2024/CQC CYP MH/DTT Extract.csv")

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

su_colors_expanded <- rep(su_colors, ceiling(23 / length(su_colors)))
su_colors_11 <- rep(su_colors, ceiling(11 / length(su_colors)))

su_colours_top_5 <- c(su_light_blue, su_grey, su_blue, su_red, su_yellow)
su_colours_top_4 <- c(su_grey, su_blue, su_red, su_yellow)
su_colours_top_3 <- c(su_blue, su_red, su_yellow)
su_colours_top_2 <- c(su_blue, su_red)

su_colours_top_5_expanded <- rep(su_colours_top_5, ceiling(10 / length(su_colours_top_5)))

#Check columns have headers
column_names <- colnames(data)
print(column_names)

#Add in a column for average distance per admission
    data$average_distance_per_admission <- data$TOTAL_DISTANCE / data$ADMISSIONS

    # Print the first few rows of the new data frame
    head(data)

#Explore
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

#Exploring other methods
    data |>
    dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                     .by = FIN_YEAR) |>
      mutate(Average_Distance = janitor::round_half_up(Average_Distance, 4)) |>
      create_dt()

    DTT_FY <- data |>
      dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                       .by = FIN_YEAR) |>
      mutate(Average_Distance = janitor::round_half_up(Average_Distance, 4)) |>
      create_dt()

    knitr::kable(DTT_FY)

    dtt_fy <- data |>
      summarise(Average_Distance = mean(average_distance_per_admission), .by = FIN_YEAR) |>
      arrange(desc(FIN_YEAR)) |>
      create_dt()

    knitr::kable(dtt_fy)


#Exploring Groupings
    Age_data <- data |>
      group_by(age_group) |>
      summarize(average_distance_per_admission = mean(average_distance_per_admission, na.rm = TRUE))

    ggplot(Age_data, aes(x = age_group, y = average_distance_per_admission)) +
      geom_col(fill = su_colors) +
      geom_text(aes(label = round(average_distance_per_admission, 0), vjust = -0.5, hjust = 0.5)) +
      labs(title = "Average Distance per Admission by Age Group",
           x = "Age Group",
           y = "Average Distance per Admission") +
      theme_minimal() +
      scale_x_discrete(limits = levels(Age_data$age_group))
