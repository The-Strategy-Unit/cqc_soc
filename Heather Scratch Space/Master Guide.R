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

# Step 2: Sync with project
# Open R studio --> go to main --> pull the latest --> go to my branch
#--> merge the latest by running:
  usethis::pr_merge_main ()

#Step 3:
data <- tar_read(DTT)

#Step 4:
tar_make()



install.packages("magick")


