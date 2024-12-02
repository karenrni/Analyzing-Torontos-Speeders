#### Preamble ####
# Purpose: Cleans the raw marriage data into an analysis dataset
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: Need to have downloaded the data
# Any other information needed? None.

#### Workspace setup ####
library(tidyverse)
library(arrow)
library(sf)

#### Clean data ####

# Read the raw data
raw_data_cams <- read_csv("data/raw_data/raw_data_cameras.csv")
raw_data_speeds <- read_csv("data/raw_data/raw_data_speeds.csv")
speed_counts_data_raw <- read_csv("data/raw_data/raw_data_speeding_count.csv")

# Check the structure and sample values of the geometry column for cameras
print(head(raw_data_cams$geometry))
print(class(raw_data_cams$geometry))

#### Step 1: Handle camera data with geometry in c(...) format ####
extract_camera_coordinates <- function(geometry) {
  # Remove "c(" and ")" from the string, then split into longitude and latitude
  coords <- str_remove_all(geometry, "c\\(|\\)") %>%
    str_split(",\\s*") %>%
    unlist() %>%
    as.numeric()
  tibble(longitude = coords[1], latitude = coords[2])
}

# Extract coordinates and create sf object for cameras
cams_coords <- raw_data_cams %>%
  filter(!is.na(geometry)) %>%  # Remove rows with missing geometry
  mutate(extracted = map(geometry, extract_camera_coordinates)) %>%
  unnest_wider(extracted) %>%  # Expand coordinates into longitude and latitude columns
  filter(!is.na(longitude) & !is.na(latitude))  # Remove rows with missing coordinates

cams_sf <- st_as_sf(cams_coords, coords = c("longitude", "latitude"), crs = 4326)

#### Step 2: Parse geometry column to extract coordinates for speed data ####
extract_coordinates <- function(geometry) {
  # Use regular expressions to extract the coordinate values from the JSON-like string
  coords <- str_match(geometry, "\\[\\[(-?\\d+\\.\\d+),\\s*(-?\\d+\\.\\d+)\\]\\]")
  tibble(longitude = as.numeric(coords[, 2]), latitude = as.numeric(coords[, 3]))
}

# Apply extraction to speeds data
speeds_coords <- raw_data_speeds %>%
  filter(!is.na(geometry)) %>%  # Remove rows with missing geometry
  mutate(extracted = map(geometry, extract_coordinates)) %>%
  unnest_wider(extracted) %>%
  filter(!is.na(longitude) & !is.na(latitude))  # Remove rows with missing coordinates

speeds_sf <- st_as_sf(speeds_coords, coords = c("longitude", "latitude"), crs = 4326)

#### Step 3: Clean data (Remove duplicates and outliers) ####
# Remove duplicates
cams_sf <- cams_sf %>% distinct()
speeds_sf <- speeds_sf %>% distinct()

# Filter out outliers based on Toronto's approximate longitude and latitude ranges
cams_sf <- cams_sf %>%
  filter(st_coordinates(.)[, 1] > -80 & st_coordinates(.)[, 1] < -78 &
           st_coordinates(.)[, 2] > 43 & st_coordinates(.)[, 2] < 44)

speeds_sf <- speeds_sf %>%
  filter(st_coordinates(.)[, 1] > -80 & st_coordinates(.)[, 1] < -78 &
           st_coordinates(.)[, 2] > 43 & st_coordinates(.)[, 2] < 44)

#### Step 4: Transform to a projected CRS ####
# Transform both datasets to UTM Zone 17N for accurate distance calculations
cams_sf <- st_transform(cams_sf, crs = 32617)
speeds_sf <- st_transform(speeds_sf, crs = 32617)

#### Step 5: Perform spatial join with a 500m threshold ####
distance_threshold <- 500  # Distance in meters
joined_data <- cams_sf %>%
  st_join(speeds_sf, join = st_is_within_distance, dist = distance_threshold)

# Track school zones without cameras
joined_data <- joined_data %>%
  mutate(no_camera_in_radius = ifelse(is.na(sign_id), TRUE, FALSE))  # Use `sign_id` to track camera presence

#### Step 6: Convert geometry back into longitude and latitude columns #### 
joined_data <- joined_data %>%
  mutate(longitude = st_coordinates(.)[, 1],  # Extract X (longitude)
         latitude = st_coordinates(.)[, 2]) %>%  # Extract Y (latitude)
  st_drop_geometry()  # Remove the geometry column

#### Step 7: Use Stratified Random Sampling on Speed Count Data #### 
speed_counts_data_cleaned <- speed_counts_data_raw %>%
  select(sign_id, datetime_bin, speed_bin, volume) %>%  # Select relevant columns
  group_by(sign_id) %>%          # Group by `sign_id`
  sample_frac(0.01) %>%          # Take 1% per group
  ungroup()

#### Step 8: Join Speed Counts with Joined Camera and Speed data #### 
# Perform an inner join to ensure no NA values in `sign_id`
final_joined_data <- joined_data %>%
  inner_join(speed_counts_data_cleaned, by = "sign_id", relationship = "many-to-many")  # Specify many-to-many relationship

#### Step 9: Filter Dates and Select Specific Columns ####

# Filter the data
final_filtered_data <- final_joined_data %>%
  filter(as.Date(end_date) >= as.Date("2023-01-01"),          # Keep rows with end_date in 2023 or later
         !grepl("^2024", as.character(start_date))) %>%       # Exclude rows with start_date starting with 2024
  select(sign_id, X_id, longitude, latitude,                 # Select relevant columns
         speed_limit, volume, speed_bin, no_camera_in_radius)

#### Step 10: Save Results ####

# Save the final filtered data as a Parquet file
arrow::write_parquet(final_filtered_data, "data/analysis_data/analysis_data.parquet")
