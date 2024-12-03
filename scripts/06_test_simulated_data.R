#### Preamble ####
# Purpose: Tests the structure and validity of the Simulated Data
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: Run 00-simulate_data.R 
# Any other information needed? None.

#### Workspace setup ####

library(testthat)
library(tidyverse)

simulated_data <- read_csv("data/simulated_data/simulated.csv")

# Test if the data was successfully loaded
if (exists("simulated_data")) {
  message("Test Passed: The dataset was successfully loaded.")
} else {
  stop("Test Failed: The dataset could not be loaded.")
}

#### Test Simulated Speeding Data ####

# Expected values
expected_speed_bins <- c("[55,60)", "[10,15)", "[35,40)", "[30,35)", "[15,20)", "[85,90)", "[25,30)", "[60,65)", 
                         "[40,45)", "[5,10)", "[100,)", "[50,55)", "[45,50)", "[20,25)", "[75,80)", "[80,85)", 
                         "[90,95)", "[95,100)", "[70,75)", "[65,70)")
expected_wards <- 1:25  # Toronto wards
expected_speed_limits <- c(30, 40, 50, 60)

# Test 1: Ensure there are no missing values
stopifnot(!any(is.na(simulated_data)))

# Test 2: Ensure `speed_bin` contains only valid bins
stopifnot(all(simulated_data$speed_bin %in% expected_speed_bins))

# Test 3: Ensure `ward_no` contains valid ward numbers
stopifnot(all(simulated_data$ward_no %in% expected_wards))

# Test 4: Ensure `longitude` and `latitude` are within Toronto’s approximate bounds
stopifnot(all(simulated_data$longitude > -80 & simulated_data$longitude < -78))
stopifnot(all(simulated_data$latitude > 43 & simulated_data$latitude < 44))

# Test 5: Ensure `speed_limit` contains valid speed limits
stopifnot(all(simulated_data$speed_limit %in% expected_speed_limits))

# Test 6: Ensure `volume` is a positive integer
stopifnot(all(simulated_data$volume > 0))
stopifnot(is.numeric(simulated_data$volume))

# Test 7: Ensure `no_camera_in_radius` is a boolean
stopifnot(is.logical(simulated_data$no_camera_in_radius))

# Test 8: Check for duplicates
stopifnot(nrow(simulated_data) == nrow(distinct(simulated_data)))

# Test 9: Check for extreme speeding cases
extreme_speeds <- simulated_data %>% filter(speed_bin == "[100,)")
stopifnot(nrow(extreme_speeds) / nrow(simulated_data) <= 0.01)  # Should be ≤ 1% of the data

# Test 10: Check speed bin distribution
speed_bin_distribution <- simulated_data %>% 
  count(speed_bin) %>% 
  mutate(proportion = n / sum(n))

# Ensure bins above "[85,90)" are under 3% of the total data
stopifnot(all(speed_bin_distribution$proportion[speed_bin_distribution$speed_bin %in% c("[85,90)", "[90,95)", "[95,100)")] < 0.03))

# Test 11: Check for realistic longitude and latitude pairs
# Ensure that the average longitude and latitude correspond to Toronto's geographic center
avg_long <- mean(simulated_data$longitude)
avg_lat <- mean(simulated_data$latitude)
stopifnot(avg_long > -79.65 & avg_long < -79.0)
stopifnot(avg_lat > 43.6 & avg_lat < 43.8)

# Test 12: Ensure columns are of correct data types
stopifnot(is.numeric(simulated_data$longitude))
stopifnot(is.numeric(simulated_data$latitude))
stopifnot(is.character(simulated_data$speed_bin))
stopifnot(is.numeric(simulated_data$speed_limit))
stopifnot(is.numeric(simulated_data$volume))
stopifnot(is.logical(simulated_data$no_camera_in_radius))

# Test 13: Validate ward-specific high-speed bin probabilities
ward_high_speed <- simulated_data %>% 
  filter(speed_bin %in% c("[85,90)", "[90,95)", "[95,100)")) %>%
  group_by(ward_no) %>%
  summarize(high_speed_count = n(), total_count = nrow(simulated_data)) %>%
  mutate(proportion = high_speed_count / total_count)

# Ensure high-speed bins are not overrepresented (e.g., < 20% in any ward)
stopifnot(all(ward_high_speed$proportion < 0.2))
