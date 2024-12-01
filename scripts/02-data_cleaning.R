#### Preamble ####
# Purpose: Cleans the raw marriage data into an analysis dataset
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: Need to have downloaded the data
# Any other information needed? None.

#### Workspace setup ####
library(tidyverse)

#### Clean data ####
raw_data <- read_csv("data/raw_data/raw_data.csv")

cleaned_data <-
  raw_data |>
  janitor::clean_names() |> 
  separate(col = time_period,
            into = c("year", "month"),
            sep = "-") |> 
  mutate(date = lubridate::ymd(paste(year, month, "01", sep = "-"))
         )
  
#### Save data ####
write_csv(cleaned_data, "data/analysis_data/analysis_data.csv")
