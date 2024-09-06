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


