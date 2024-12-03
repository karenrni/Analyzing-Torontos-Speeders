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

test_that("Check for proportion of extreme speed bins", {
  extreme_speeds <- final_filtered_data %>%
    filter(speed_bin == "[100,)")
  expect_true(nrow(extreme_speeds) / nrow(final_filtered_data) <= 0.01, 
              info = "Extreme speed bins exceed 1% of the data.")
  
  high_speed_bins <- c("[85,90)", "[90,95)", "[95,100)")
  high_speed_proportion <- final_filtered_data %>%
    filter(speed_bin %in% high_speed_bins) %>%
    nrow() / nrow(final_filtered_data)
  expect_true(high_speed_proportion < 0.03, 
              info = "High-speed bins exceed 3% of the data.")
})

test_that("Ensure speed bins are valid and present", {
  valid_speed_bins <- c("[55,60)", "[10,15)", "[35,40)", "[30,35)", "[15,20)", 
                        "[85,90)", "[25,30)", "[60,65)", "[40,45)", "[5,10)", 
                        "[100,)", "[50,55)", "[45,50)", "[20,25)", "[75,80)", 
                        "[80,85)", "[90,95)", "[95,100)", "[70,75)", "[65,70)")
  expect_true(all(final_filtered_data$speed_bin %in% valid_speed_bins), 
              info = "Invalid or missing speed_bin values found.")
})

test_that("Check for correctness of over_speed_limit calculation", {
  # Check if over_speed_limit is non-negative
  expect_true(all(final_filtered_data$over_speed_limit >= 0), 
              info = "over_speed_limit contains negative values.")
  
  # Check if over_speed_limit matches lower speed_bin - speed_limit for sample rows
  sample_data <- final_filtered_data %>%
    slice_sample(n = 10)  # Take 10 random rows for testing
  
  sample_data <- sample_data %>%
    mutate(
      expected_over_speed_limit = pmax(as.numeric(gsub("\\[|,.*", "", speed_bin)) - speed_limit, 0)
    )
  
  # Ensure calculated and expected values match
  expect_true(all(sample_data$over_speed_limit == sample_data$expected_over_speed_limit),
              info = "over_speed_limit calculation does not match expected values.")
})

