
# packages
library(tidyverse)

# create 2011 ethnicities by ICB ----

# import ethnicity by 2011 lsoa data
ethn_2011_by_lsoa.data <- read.csv("data/ethnicity_by_LSOA11_data.CSV")

# import the headings for the ethnicity by 2011 lsoa data
# only keeping the vars i want from it as a lookup
ethn_2011_by_lsoa.heads <- read.csv("data/ethnicity_by_LSOA11_headings.CSV")[, c(1,4)]

# next task is to rename the column headers in the ethnicity by 2011 lsoa data
# note that it only has names for the actual ethnicities, ignoring the LSOA name, so I'm adding that in manually to the list so that I can crudely link the two by order - I have manually checked that this works, but it is obviously janky
colnames(ethn_2011_by_lsoa.data) = c("LSOA11CD", ethn_2011_by_lsoa.heads$ColumnVariableDescription)
# this should be improved, so that this happens via lookup rather than just relying on the order of the variables (see https://stackoverflow.com/questions/43742369/rename-variables-via-lookup-table-in-r/43742442#43742442)

# drop some columns from the ethnicity by lsoa data so that everything is more manageable
ethn_2011_by_lsoa.data2 <- ethn_2011_by_lsoa.data %>%
  transmute(LSOA11CD = LSOA11CD,
            All_Ethnicities = `All categories: Age, All categories: Ethnic group`,
            White = `All categories: Age, White: Total`,
            Mixed = `All categories: Age, Mixed/multiple ethnic group: Total`,
            Asian = `All categories: Age, Asian/Asian British: Total`,
            Black = `All categories: Age, Black/African/Caribbean/Black British: Total`,
            Other = `All categories: Age, Other ethnic group: Total`)

# import 2011 to ICB data lookup
lsoa11_to_ICB22 <- read.csv("data/LSOA2011_to_ICB.csv") %>%
  # drop some variables to make it neater
  select(c("LSOA11CD", "LSOA11NM",
           "ICB22CD", "ICB22NM"))

# join lsoa to icb lookup
ethnicity_by_lsoa_by_icb <- inner_join(x = ethn_2011_by_lsoa.data2, y = lsoa11_to_ICB22,
                                      by = "LSOA11CD")
# n of rows of lsoas is 32844, which is correct for n of lsoas in england during 2011

ethnicity2011_by_icb2022 <- ethnicity_by_lsoa_by_icb %>%
  # pivot longer for ease of wrangling
  pivot_longer(cols = c(2:7),
               names_to = "Ethnicity",
               values_to = "Count") %>%
  # create aggregate count of each ethnic group
  group_by(ICB22CD, ICB22NM, Ethnicity) %>%
  summarise(Count = sum(Count)) %>%
  # ok so this is a stupid way of doing it
  # but this is to calculate icb level percentage
  pivot_wider(names_from = Ethnicity,
              values_from = Count) %>%
  pivot_longer(cols = c(4:8),
               names_to = "Ethnicity",
               values_to = "Count") %>%
  # create new variables
  mutate(ICB_Percentage = Count/All_Ethnicities,
         Year = 2011,
         ICB23CD = case_when(
           ICB22CD == "E54000052" ~ "E54000063",
           ICB22CD == "E54000053" ~ "E54000064",
           .default = ICB22CD
         ))

# create 2021 ethnicities by ICB ----

# join datasets

# impute annual data

# impute financial year data