#### Preamble ####
# Purpose: Tests the structure and validity of the Simulated Data
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: Run 00-simulate_data.R 
# Any other information needed? None.

#### Workspace setup ####

library(testthat)

# Test for duplicates
test_that("Ensure no duplicate rows", {
  expect_true(nrow(data.frame(final_filtered_data)) == nrow(distinct(final_filtered_data)))
})

# Test for valid longitude and latitude ranges
test_that("Check for coordinate validity", {
  expect_true(all(final_filtered_data$longitude > -80 & final_filtered_data$longitude < -78), 
              info = "Longitude values are out of bounds.")
  expect_true(all(final_filtered_data$latitude > 43 & final_filtered_data$latitude < 44), 
              info = "Latitude values are out of bounds.")
})

# Test for valid speed limits
test_that("Check for speed limit validity", {
  expect_true(all(final_filtered_data$speed_limit %in% c(30, 40, 50, 60)), 
              info = "Speed limit contains invalid values.")
})

# Test for valid volumes
test_that("Check for valid volume values", {
  expect_true(all(final_filtered_data$volume > 0), info = "Volume contains zero or negative values.")
})

# Test for consistency in speed_bin
test_that("Check for valid speed_bin ranges", {
  valid_bins <- c("[0,10)", "[10,20)", "[20,30)", "[30,40)", "[40,50)", "[50,60)", "[60,70)", "[70,80)", "[80,90)", "[90,100)")
  expect_true(all(final_filtered_data$speed_bin %in% valid_bins), 
              info = "Speed_bin contains invalid ranges.")
})
