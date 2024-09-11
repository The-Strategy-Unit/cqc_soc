# Summary ######################################################################

#Libraries:
library(readr)
library(tidyverse)
library(targets)
library(sf)


#Step 2: Sync with project
#Start of each day
#Open R studio
# go to main
# pull the latest
# go to my branch
# merge the latest
usethis::pr_merge_main ()

#Step 3:
data <- tar_read(DTT)

#Step 4:
tar_make()


#{r redetentions_gender_plot}
##| label: fig-redetentions-gender
##| fig-cap: Rates per 100,000 population of the number of MHA redetentions within 12 months by gender.
#tar_read(gender_plot)$cyp_redetentions

# Targets script line 641
tar_target(
  gender_plot,
  purrr::map(
    gender_breakdowns,
    ~ get_standard_line_for_breakdowns(., pop_by_icb, group = "gender")
  )
)

# Help from Anya 10/09/2024 ####################################################

#if pipeline stopped working - take the function and what's going into it
#read in the DTT target
get_table_DTT_gender_FY(DTT)

#Step 1:
DTT <- tar_read(DTT)

#targets for: read raw data, tidy the data (or a subset), a target to create the table, then for the plot

#Testing Space
#Take part of function out to test

avg_distance_by_gender <- DTT %>%
  filter(!is.na(gender_desc) & gender_desc != "NULL") %>%  # Remove rows where gender_desc is NA or NULL
  group_by(fin_year, gender_desc) %>%  # Group by financial year and gender
  summarise(
    avg_distance = mean(average_distance_per_admission, na.rm = TRUE)
  ) %>%
  filter(!is.na(fin_year) & !is.na(gender_desc))  # Final filtering for NA values
#create two functions - one that creates an average distance by gender and then one that creates the plot
#identify whether issue with table or data

# Gender Chart
# Function to create the chart for average distance by gender and financial year
get_chart_prestep_DTT_gender_FY <- function(data) {
  avg_distance_by_gender <- data %>%
    filter(!is.na(gender_desc) & gender_desc != "NULL") %>%  # Remove rows where gender_desc is NA or NULL
    group_by(fin_year, gender_desc) %>%  # Group by financial year and gender
    summarise(
      avg_distance = mean(average_distance_per_admission, na.rm = TRUE)
    ) %>%
    filter(!is.na(fin_year) & !is.na(gender_desc))  # Final filtering for NA values
  #create two functions - one that creates an average distance by gender and then one that creates the plot
  #identify whether issue with table or data

  return(plot)
}


get_table_DTT_gender_FY(DTT)





avg_distance_by_gender <- data %>%
  filter(!is.na(gender_desc) & gender_desc != "NULL") %>%  # Remove rows where gender_desc is NA or NULL
  group_by(fin_year, gender_desc) %>%  # Group by financial year and gender
  summarise(
    avg_distance = mean(average_distance_per_admission, na.rm = TRUE)
  ) %>%
  filter(!is.na(fin_year) & !is.na(gender_desc))  # Final filtering for NA values
#create two functions - one that creates an average distance by gender and then one that creates the plot
#identify whether issue with table or data






################################################################################
#Anya helping troubleshoot

library(targets)
tar_make()

#runs the targets pipeline
#creates all the objects so I can read them

#"run the targets" = running line 3

install.packages("janitor")
install.packages("DT")
install.packages("tidyverse")
install.packages("readODS")
install.packages("patchwork")
install.packages("PHEindicatormethods")
install.packages("sf")
install.packages("readr")

#Step 1:
library(targets)
library(sf)

#Step 2:
tar_make()


#Start of each day
#Open R studio
# go to main
# pull the latest
# go to my branch
# merge the latest
usethis::pr_merge_main ()

#Run the targets
library(targets)
tar_make()

#render the quarto report (check that you broke something, not inhereted something broken)


#Learings:
#control enter runs a line :)

#Attempting to solve an issue:
#unlink("C:/Users/Heather.humphreys/AppData/Local/R/win-library/4.4/00LOCK")
#solution from Tom was to delete that folder


#Read the data
data <- read.csv("data/cyp_DTT.csv")

#From general R
# load specific reference and query files
load_csv <- function(fileloc) {
  data <- read.csv(fileloc) |>
    janitor::clean_names()
}

#use a function already have:
data <- load_csv("data/cyp_DTT.csv")

#now move stuff into taregts so I don't have to do the above every time
#go to the targets R script and add - don't forget the comma should look like:

#,
#rename seciton below:
# 07. Maps -------------------------------------------------------------------
#add your stuff here

#)
#remove the comma if no other things at end

#Check to make sure it worked
tar_make()


data2 <- tar_read (DTT)

#so now next time I log in use:
data <- tar_read(DTT)


#Make something to put in the quarto report
#this is in the quarto formatting file
DTT_FY <- data |>
  dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                   .by = fin_year) |>
  mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) |>
  create_dt()

#to see it:
DTT_FY

#Create a function:
#GIve it a new name - start with a verb word like round or plot or get
get_table_DTT_FY <- function (data){ DTT_FY <- data |>
  dplyr::summarise(Average_Distance = mean(average_distance_per_admission),
                   .by = fin_year) |>
  mutate(Average_Distance = janitor::round_half_up(Average_Distance, 1)) |>
  create_dt()
return (DTT_FY) # do the return because some functions do more than one thing

}

get_table_DTT_FY (data)

#now we have something - we want to write a target so we don't have to keep doing it
#have to do this after every step so that we can call save object as part of target pipeline

#test it worked:
tar_make()
tar_read(table_DTT_FY)


#Libraries:
library(readr)
library(tidyverse)


get_chart_DTT_IMD_FY <- function(data) {
  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance,
                           group = imd_2019_decile, color = imd_2019_decile)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = imd_colors_custom) +  # Use the custom IMD color palette
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by IMD Decile Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "IMD"
    ) + theme(
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  return(plot)
}


get_chart_DTT_ethnic_FY <- function(data, su_colours) {
  ethnic_levels <- unique(data$ethnic_category)
  ethnic_colours <- setNames(su_colours[1:length(ethnic_levels)], ethnic_levels)
  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance, group = ethnic_category, color = ethnic_category)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = ethnic_colours) +  # Map ethnic category to specific SU colours
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by Ethnic Category Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Ethnic Category"
    ) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  return(plot)
}




# Chart for Age Group
get_chart_DTT_age_group_FY_with_admissions <- function(data, su_colours) {
  age_levels <- unique(data$age_group)
  age_colours <- setNames(su_colours[1:length(age_levels)], age_levels)

  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance, group = age_group, color = age_group)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = age_colours) +
    geom_bar(aes(x = fin_year, y = Total_Admissions, fill = "Total Admissions"), stat = "identity", alpha = 0.5) +
    scale_fill_manual(values = su_colours["su_yellow"]) +
    theme_minimal() +
    labs(
      title = "Comparison of Total Admissions and Travel Distance by Age Group Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Age Group"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(plot)
}

# Chart for Ethnic Category
get_chart_DTT_ethnic_FY_with_admissions <- function(data, su_colours) {
  ethnic_levels <- unique(data$ethnic_category)
  ethnic_colours <- setNames(su_colours[1:length(ethnic_levels)], ethnic_levels)

  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance, group = ethnic_category, color = ethnic_category)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = ethnic_colours) +
    geom_bar(aes(x = fin_year, y = Total_Admissions, fill = "Total Admissions"), stat = "identity", alpha = 0.5) +
    scale_fill_manual(values = su_colours["su_yellow"]) +
    theme_minimal() +
    labs(
      title = "Comparison of Total Admissions and Travel Distance by Ethnic Category Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Ethnic Category"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(plot)
}

# Chart for IMD
get_chart_DTT_IMD_FY_with_admissions <- function(data, imd_colours) {
  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance,
                           group = imd_2019_decile, color = as.factor(imd_2019_decile))) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = imd_colours) +
    geom_bar(aes(x = fin_year, y = Total_Admissions, fill = "Total Admissions"), stat = "identity", alpha = 0.5) +
    scale_fill_manual(values = su_colours["su_yellow"]) +
    theme_minimal() +
    labs(
      title = "Comparison of Total Admissions and Travel Distance by IMD Decile Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "IMD"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  return(plot)
}

tar_target(
  table_DTT_gender_FY_with_admissions,
  get_table_DTT_gender_FY_with_admissions(DTT)
),

tar_target(
  table_DTT_age_group_FY_with_admissions,
  get_table_DTT_age_group_FY_with_admissions(DTT)
),

tar_target(DTT_ethnic_FY_with_admissions,
           get_table_DTT_ethnic_FY_with_admissions(DTT)),

tar_target(
  table_DTT_IMD_FY_with_admissions,
  get_table_DTT_IMD_FY_with_admissions(DTT)
),

tar_target(chart_DTT_gender_FY_with_admissions,
           get_chart_DTT_gender_FY_with_admissions(DTT_gender_FY_with_admissions, custom_colours$su_colours)),

tar_target(chart_DTT_age_group_FY_with_admissions,
           get_chart_DTT_age_group_FY_with_admissions(DTT_age_group_FY_with_admissions, custom_colours$su_colours)),

tar_target(chart_DTT_ethnic_FY_with_admissions,
           get_chart_DTT_ethnic_FY_with_admissions(DTT_ethnic_FY_with_admissions, custom_colours$su_colours)),

tar_target(chart_DTT_IMD_FY_with_admissions,
           get_chart_DTT_IMD_FY_with_admissions(DTT_IMD_FY_with_admissions, custom_colours$imd_colours_custom))

# Admissions by DTT Subgroups Charts ##################################################
# Chart for Gender
get_chart_DTT_gender_FY_with_admissions <- function(data, su_colours) {
  gender_levels <- unique(data$gender_desc)
  gender_colours <- setNames(su_colours[1:length(gender_levels)], gender_levels)
  plot <- ggplot(data, aes(x = fin_year, y = Average_Distance, group = gender_desc, color = gender_desc)) +
    geom_line(linewidth = 1) +
    geom_point(size = 3) +
    scale_color_manual(values = gender_colours) +  # Map gender to specific SU colours
    theme_minimal() +
    labs(
      title = "Average Travel Distance Per Admission by Gender Over Time",
      subtitle = "2017/18 to 2024/25",
      x = "Financial Year",
      y = "Average Distance (km)",
      color = "Gender"
    ) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  return(plot)
}

#subgroups charts

tar_target(chart_DTT_gender_FY_with_admissions,
           get_chart_DTT_gender_FY_with_admissions(DTT_gender_FY_with_admissions, custom_colours$su_colours))





