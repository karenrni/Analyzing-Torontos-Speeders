#### Preamble ####
# Purpose: Downloads and processes data from Open Data Toronto
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: None
# Any other information needed: As of this date, the Speed Program API download has issues with mismatched column lengths for topics and formats. A secondary option is provided for future compatibility.

#### Workspace setup ####
library(opendatatoronto)
library(tidyverse)
library(janitor)

#### Download data ####

### Speed program data ###
## Download csv directly from provided OpenDataToronto link
speed_data_raw <- read_csv("https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/642efeca-1258-4c23-8e86-d9affca26001/resource/866701b9-9e1f-4c39-92df-e1ec9e20cbbe/download/Stationary%20Sign%20locations%20-%204326.csv")

### Traffic camera data ###
# get package
packageTraffic <- show_package("a3309088-5fd4-4d34-8297-77c8301840ac")
packageTraffic

# get all resources for this package
resourcesTraffic <- list_package_resources("a3309088-5fd4-4d34-8297-77c8301840ac")

# identify datastore resources
datastore_resourcesTraffic <- filter(resourcesTraffic, tolower(format) %in% c('csv', 'geojson'))

# load the first datastore resource as a sample
camera_data_raw <- filter(datastore_resourcesTraffic, row_number() == 1) %>% get_resource()
camera_data_raw

### Speeding count data ###

##Step 1: Download ZIP ##
# URL for the ZIP file
zip_url <- "https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/d7522ce7-68b1-4f93-991a-0eb2f9ec7de5/resource/3f818b52-b4bb-4ddf-8d68-e6de8bc60d51/download/Stationary%20count%20detailed%202023.zip"

# Directory for downloaded ZIP and extracted CSVs
zip_dir <- "data/raw_data/zips/"
output_dir <- "data/raw_data/speed_data/"

# Create directories if they don't exist
dir.create(zip_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Path to save the ZIP file
zip_path <- file.path(zip_dir, "Stationary_Count_Detailed_2023.zip")

# Download the ZIP file
download.file(zip_url, destfile = zip_path, mode = "wb")

## Step 2: Unzip Files ##
# Extract all files from the ZIP to the output directory
unzip(zip_path, exdir = output_dir)

## Step 3: Combine CSV Files ##
# List all CSV files in the output directory
csv_files <- list.files(output_dir, pattern = "\\.csv$", full.names = TRUE)

speed_counts_data_raw <- csv_files %>%
  map_dfr(read_csv)  # Read and combine all CSV files

#### Save data ####
write_csv(camera_data_raw, "data/raw_data/raw_data_cameras.csv")
write_csv(speed_data_raw, "data/raw_data/raw_data_speeds.csv")
write_csv(speed_counts_data_raw, "data/raw_data/raw_data_speeding_count.csv")
