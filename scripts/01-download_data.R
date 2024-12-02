#### Preamble ####
# Purpose: Downloads and saves the data from Open Data Toronto
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: None
# Any other information needed: As of this date, the API download does not properly load the data and has issues with mismatched column lengths for topics and formats. Thus I provided a secondary option in case it does not work in the future. 

#### Workspace setup ####
library(opendatatoronto)
library(tidyverse)

#### Download data ####

### Option 1: Load through direct link to csv
WYS_raw_data<- read_csv("https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/058236d2-d26e-4622-9665-941b9e7a5229/resource/969583a4-4e9e-44e8-be79-a1b6f1dbd74e/download/WYS%20Mobile%20Sign%20Summary.csv")

### Option 2: Load through API (Currently has issues with tibble)
# get package
package <- show_package("058236d2-d26e-4622-9665-941b9e7a5229")
package

# get all resources for this package
resources <- list_package_resources("058236d2-d26e-4622-9665-941b9e7a5229")

# identify datastore resources; by default, Toronto Open Data sets datastore resource format to CSV for non-geospatial and GeoJSON for geospatial resources
datastore_resources <- filter(resources, tolower(format) %in% c('csv', 'geojson'))

# load the first datastore resource as a sample
data <- filter(datastore_resources, row_number()==1) %>% get_resource()
data

#### Save data ####
write_csv(data, "data/raw_data/raw_data.csv")