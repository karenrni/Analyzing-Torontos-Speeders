#### Preamble ####
# Purpose: Sanity check of the data
# Author: Karen Riani
# Date: 1 December 2024
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

# Define tests
test_that("Check for valid date ranges", {
  # Ensure `end_date` is in the correct range
  expect_true(all(as.Date(final_filtered_data$end_date) >= as.Date("2023-01-01")))
  # Ensure `start_date` does not contain 2024 dates
  expect_false(any(grepl("^2024", as.character(final_filtered_data$start_date))))
})

test_that("Check for missing values", {
  # Ensure no missing values in critical columns
  critical_cols <- c("sign_id", "X_id", "longitude", "latitude", "speed_limit", "volume", "speed_bin", "no_camera_in_radius")
  expect_true(all(sapply(critical_cols, function(col) !any(is.na(final_filtered_data[[col]])))))
})

test_that("Check for coordinate validity", {
  # Ensure longitude and latitude are not NA
  expect_true(all(!is.na(final_filtered_data$longitude)), info = "Longitude contains NA values.")
  expect_true(all(!is.na(final_filtered_data$latitude)), info = "Latitude contains NA values.")
  
  # Ensure longitude and latitude are within Toronto's approximate bounds
  expect_true(all(final_filtered_data$longitude > -80 & final_filtered_data$longitude < -78), 
              info = "Longitude values are out of bounds.")
  expect_true(all(final_filtered_data$latitude > 43 & final_filtered_data$latitude < 44), 
              info = "Latitude values are out of bounds.")
})


test_that("Check for valid speed limits and volumes", {
  # Speed limits and volumes should be non-negative
  expect_true(all(final_filtered_data$speed_limit >= 0))
  expect_true(all(final_filtered_data$volume >= 0))
})

test_that("Verify `no_camera_in_radius` logic", {
  # Ensure `no_camera_in_radius` is TRUE only when `sign_id` is NA
  expect_true(all(final_filtered_data$no_camera_in_radius == is.na(final_filtered_data$sign_id)))
})
