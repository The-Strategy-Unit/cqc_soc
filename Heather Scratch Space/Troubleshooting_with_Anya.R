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
tar_make()


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


