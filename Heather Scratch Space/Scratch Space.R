library(readr)

#Install packages and setup

install.packages("readr")
library(readr)

data <- read.csv("Z:/Strategic Analytics/Projects 2024/CQC CYP MH/cyp_DTT.csv")

saveRDS(data, file = "data/cyp_dtt_data.rds")


tar_make()
library(targets)
tar_make()