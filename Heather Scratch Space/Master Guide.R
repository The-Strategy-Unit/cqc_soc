# Master Guide on What to Do
# Summary of notes for myself on what I need to know

# Running Targets
tar_make()


# At the start of everyday: ####################################################

# Load the relevant libraries:
library(readr)
library(tidyverse)
library(targets)
library(sf)
library(magick)
library(DiagrammeR)

# Step 2: Sync with project
# Open R studio --> go to main --> pull the latest --> go to my branch
#--> merge the latest by running:
  usethis::pr_merge_main ()

#Step 3:
data <- tar_read(DTT)

#Step 4:
tar_make()



install.packages("magick")
install.packages("DiagrammeR")

tar_load(icb_boundary)
str(icb_boundary)

tar_load(icb_boundary)
names(icb_boundary)

# Check the column names of the new DTT table
tar_load(table_DTT_ICB_FY_new)
names(table_DTT_ICB_FY_new)

# Check unique ICB codes in icb_boundary
icb_boundary_codes <- icb_boundary %>%
  mutate(ICB23CD = tolower(ICB23CD)) %>%
  distinct(ICB23CD)

# Check unique ICB codes in table_DTT_ICB_FY_new
dtt_icb_codes <- table_DTT_ICB_FY_new %>%
  distinct(icb23cd)

# Find any mismatches
setdiff(icb_boundary_codes$ICB23CD, dtt_icb_codes$icb23cd)
setdiff(dtt_icb_codes$icb23cd, icb_boundary_codes$ICB23CD)

