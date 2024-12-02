#### Preamble ####
# Purpose: Downloads and saves the data from Open Data Toronto
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: None
# Any other information needed: As of this date, the Speed Program API download does not properly load the data and has issues with mismatched column lengths for topics and formats. Thus I provided a secondary option in case it does not work in the future. 

#### Workspace setup ####
library(opendatatoronto)
library(tidyverse)

#### Download data ####

### Speed program data ###
## OPTION 1: Download csv directly from provided OpenDataToronto link
speed_data_raw<- read_csv("https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/642efeca-1258-4c23-8e86-d9affca26001/resource/866701b9-9e1f-4c39-92df-e1ec9e20cbbe/download/Stationary%20Sign%20locations%20-%204326.csv")


##OPTION 2 (As of this date, this does not work): Download for Developers from OpenDataToronto
# get package
packageSpeed <- show_package("642efeca-1258-4c23-8e86-d9affca26001")
packageSpeed

# get all resources for this package
resourcesSpeed <- list_package_resources("642efeca-1258-4c23-8e86-d9affca26001")

# identify datastore resources; by default, Toronto Open Data sets datastore resource format to CSV for non-geospatial and GeoJSON for geospatial resources
datastore_resourcesSpeed <- filter(resourcesSpeed, tolower(format) %in% c('csv', 'geojson'))

# load the first datastore resource as a sample
speed_data_raw <- filter(datastore_resourcesSpeed, row_number()==1) %>% get_resource()
speed_data_raw


### Traffic camera data ###
# get package
packageTraffic <- show_package("a3309088-5fd4-4d34-8297-77c8301840ac")
packageTraffic

# get all resources for this package
resourcesTraffic <- list_package_resources("a3309088-5fd4-4d34-8297-77c8301840ac")

# identify datastore resources; by default, Toronto Open Data sets datastore resource format to CSV for non-geospatial and GeoJSON for geospatial resources
datastore_resourcesTraffic <- filter(resourcesTraffic, tolower(format) %in% c('csv', 'geojson'))

# load the first datastore resource as a sample
camera_data_raw <- filter(datastore_resourcesTraffic, row_number()==1) %>% get_resource()
camera_data_raw

#### Save data ####
write_csv(camera_data_raw, "data/raw_data/raw_data_cameras.csv")
write_csv(speed_data_raw, "data/raw_data/raw_data_speeds.csv")