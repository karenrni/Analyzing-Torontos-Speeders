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

# Step 1: Remove rows with missing or invalid geometry
raw_data_cams <- raw_data_cams %>%
  filter(!is.na(geometry) & str_detect(geometry, "\\[\\[.*\\]\\]"))

raw_data_speeds <- raw_data_speeds %>%
  filter(!is.na(geometry) & str_detect(geometry, "\\[\\[.*\\]\\]"))

# Step 2: Parse geometry column to extract coordinates
extract_coordinates <- function(geometry) {
  # Use regular expressions to extract the coordinate values from the JSON-like string
  coords <- str_match(geometry, "\\[\\[(-?\\d+\\.\\d+),\\s*(-?\\d+\\.\\d+)\\]\\]")
  tibble(longitude = as.numeric(coords[, 2]), latitude = as.numeric(coords[, 3]))
}

# Apply extraction to cameras data
cams_coords <- raw_data_cams %>%
  filter(!is.na(geometry)) %>%  # Remove rows with missing geometry
  mutate(extracted = map(geometry, extract_coordinates)) %>%
  unnest_wider(extracted) %>%
  filter(!is.na(longitude) & !is.na(latitude))  # Remove rows with missing coordinates

# Apply extraction to speeds data
speeds_coords <- raw_data_speeds %>%
  filter(!is.na(geometry)) %>%  # Remove rows with missing geometry
  mutate(extracted = map(geometry, extract_coordinates)) %>%
  unnest_wider(extracted) %>%
  filter(!is.na(longitude) & !is.na(latitude))  # Remove rows with missing coordinates

# Print results for debugging
print(head(cams_coords))
print(head(speeds_coords))

# Step 4: Remove duplicates

cams_coords <- cams_coords %>%
  distinct()

speeds_coords <- speeds_coords %>%
  distinct()

# Step 5: Filter out outliers based on Toronto's expected range
cams_coords <- cams_coords %>%
  filter(longitude > -80 & longitude < -78, latitude > 43 & latitude < 44)

speeds_coords <- speeds_coords %>%
  filter(longitude > -80 & longitude < -78, latitude > 43 & latitude < 44)

# Step 6: Convert to sf objects using extracted coordinates
cams_sf <- st_as_sf(cams_coords, coords = c("longitude", "latitude"), crs = 4326)
speeds_sf <- st_as_sf(speeds_coords, coords = c("longitude", "latitude"), crs = 4326)

# Transform to a projected CRS for accurate distance calculations
cams_sf <- st_transform(cams_sf, crs = 32617)  # Example: UTM Zone 17N
speeds_sf <- st_transform(speeds_sf, crs = 32617)

# Perform spatial join within a distance threshold (e.g., 500 meters)
distance_threshold <- 500  # 500 meters
joined_data <- cams_sf %>%
  st_join(speeds_sf, join = st_is_within_distance, dist = distance_threshold)

# Save the resulting spatial object
write_parquet(joined_data, "data/analysis_data/analysis_data.parquet")