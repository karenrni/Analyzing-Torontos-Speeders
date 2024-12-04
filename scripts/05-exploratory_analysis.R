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
library(corrplot)

#### Test data ####

# Load the datasets
final_filtered_data <- arrow::read_parquet("data/analysis_data/analysis_data.parquet")

# Plot proportion of general speeding across wards
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

# Add derived variables for speeding and extreme speeding
final_filtered_data <- final_filtered_data %>%
  mutate(
    speed_bin_numeric = as.numeric(gsub("\\D", "", speed_bin)) + 5,  # Approximate midpoint
    speeding = ifelse(speed_bin_numeric > speed_limit, 1, 0),  # Indicator for speeding
    extreme_speeding = ifelse(speed_bin_numeric > (speed_limit + 55), 1, 0),  # Extreme speeding
    speeding_volume = speeding * volume,  # Count of speeding cars
    extreme_speeding_volume = extreme_speeding * volume  # Count of extreme speeding cars
  )

# Summary statistics for speeding and volume
summary_stats <- final_filtered_data %>%
  summarize(
    total_speeding_cars = sum(speeding_volume, na.rm = TRUE),
    total_extreme_speeding_cars = sum(extreme_speeding_volume, na.rm = TRUE),
    avg_speed_limit = mean(speed_limit, na.rm = TRUE),
    avg_volume = mean(volume, na.rm = TRUE),
    max_volume = max(volume, na.rm = TRUE)
  )

# Display summary
summary_stats

# General Summary
summary(final_filtered_data)

# Summarize speeding and extreme speeding by ward
ward_speeding_summary <- final_filtered_data %>%
  group_by(ward_no) %>%
  summarize(
    total_speeding = sum(speeding_volume, na.rm = TRUE),
    total_extreme_speeding = sum(extreme_speeding_volume, na.rm = TRUE)
  )

# Plot speeding by ward
ggplot(ward_speeding_summary, aes(x = factor(ward_no), y = total_speeding, fill = total_speeding)) +
  geom_col() +
  scale_fill_gradient(low = "yellow", high = "red") +
  labs(
    title = "Total Speeding by Ward",
    x = "Ward Number",
    y = "Total Speeding Cars",
    fill = "Speeding Volume"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
                                     

# Summarize over speeding by ward
ward_speeding_summary <- final_filtered_data %>%
  group_by(ward_no) %>%
  summarize(
    total_over_speeding = sum(over_speed_limit > 0, na.rm = TRUE),
    avg_over_speeding = mean(over_speed_limit[over_speed_limit > 0], na.rm = TRUE)
  )

# Plot total over speeding by ward
ggplot(ward_speeding_summary, aes(x = factor(ward_no), y = total_over_speeding, fill = total_over_speeding)) +
  geom_col() +
  scale_fill_gradient(low = "yellow", high = "red") +
  labs(
    title = "Number of Vehicles Exceeding Speed Limits by Ward",
    x = "Ward Number",
    y = "Total Over Speeding Incidents",
    fill = "Over Speeding Volume"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Interactive map of speeding incidents
leaflet(final_filtered_data %>% filter(speeding == 1)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(
    lng = ~longitude, lat = ~latitude, weight = 1,
    radius = ~log(speeding_volume + 1) * 2,  # Size based on log(speeding volume)
    color = "red",
    popup = ~paste(
      "<b>Ward:</b>", ward_no, "<br>",
      "<b>Speed Limit:</b>", speed_limit, "<br>",
      "<b>Observed Speed:</b>", speed_bin_numeric, "<br>",
      "<b>Volume:</b>", volume
    )
  ) %>%
  addLegend(
    position = "bottomright",
    colors = "red",
    labels = "Speeding Incidents",
    title = "Speeding Heatmap"
  )

# Correlation matrix
cor_data <- final_filtered_data %>%
  select(speed_limit, speed_bin_numeric, volume, speeding_volume, extreme_speeding_volume) %>%
  cor(use = "complete.obs")

# Visualize correlations
corrplot(cor_data, method = "circle", type = "upper", tl.cex = 0.8)


# Aggregate data for heatmap
heatmap_data <- final_filtered_data %>%
  group_by(ward_no, over_speed_limit) %>%
  summarize(total_volume = sum(volume, na.rm = TRUE)) %>%
  ungroup()

# Create the heatmap
ggplot(heatmap_data, aes(x = factor(ward_no), y = over_speed_limit, fill = total_volume)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "lightblue", high = "red", name = "Total Volume") +
  labs(
    title = "Heatmap of Speeding Volume by Ward and Over Speed Limit",
    x = "Ward Number",
    y = "Over Speed Limit (km/h)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

### Explore camera density per ward
camera_density <- final_filtered_data %>%
  group_by(ward_no) %>%
  summarize(cameras_nearby = n_distinct(X_id), .groups = "drop")

ward_speed_analysis <- final_filtered_data %>%
  group_by(ward_no) %>%
  summarize(
    avg_speed_over_limit = mean(over_speed_limit, na.rm = TRUE),
    cameras_nearby = n_distinct(X_id),
    .groups = "drop"
  )

ggplot(ward_speed_analysis, aes(x = cameras_nearby, y = avg_speed_over_limit)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Camera Density vs. Speeding Behavior",
       x = "Number of Cameras Nearby",
       y = "Average Speed Over Limit")

