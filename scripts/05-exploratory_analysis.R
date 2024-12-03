#### Preamble ####
# Purpose:  Exploratory Data Analysis for Cleaned Dataset
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









# Calculate statistics for speeds over 100 km/h
speeding_stats <- raw_data %>%
  summarise(
    # Number of rows with any occurrence of speeding over 100
    rows_with_speeding = sum(spd_100_and_above > 0, na.rm = TRUE),
    
    # Total occurrences of speeding over 100 summed across all rows
    total_speeding_count = sum(spd_100_and_above, na.rm = TRUE)
  )
print(speeding_stats)


view by ward... need ward data though

]
library(leaflet)

# Create a Leaflet map
leaflet(data = filtered_data) %>%
  addTiles() %>%
  addCircles(
    lng = ~longitude, lat = ~latitude, weight = 1,
    radius = ~volume * 10,  # Adjust radius based on traffic volume
    color = "red", fillColor = "red", fillOpacity = 0.5
  ) %>%
  addLegend(
    "bottomright", pal = colorNumeric("YlOrRd", domain = NULL), 
    values = ~volume, title = "Traffic Volume"
  ) %>%
  setView(lng = -79.3832, lat = 43.6532, zoom = 12)  # Centered on Toronto


speeding_data <- final_filtered_data %>%
  mutate(speeding_over_limit = as.numeric(gsub("[^0-9]", "", gsub("\\)|\\]", "", speed_bin))) - speed_limit) %>%
  filter(speeding_over_limit > 0) %>%
  group_by(ward_no) %>%
  summarize(proportion_speeding = n() / nrow(final_filtered_data))

ggplot(speeding_data, aes(x = reorder(ward_no, proportion_speeding), y = proportion_speeding)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(
    title = "Proportion of Speeding Incidents by Ward",
    x = "Ward",
    y = "Proportion of Speeding"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


