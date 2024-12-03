#### Preamble ####
# Purpose:  Checking and Fitting Models and Making Predictions
# Author: Karen Riani
# Date: 3 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: Run 02-data_cleaning.R script
# Any other information needed? None.

#### Workspace setup ####
library(tidyverse)
library(arrow)
library(testthat)

#### Test data ####

# Load the cleaned dataset
final_filtered_data <- arrow::read_parquet("data/analysis_data/analysis_data.parquet")


#### Save model ####
saveRDS(
  first_model,
  file = "models/first_model.rds"
)


