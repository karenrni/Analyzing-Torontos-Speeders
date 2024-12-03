#### Preamble ####
# Purpose: Simulates data for speeding analysis
# Author: Karen Riani
# Date: 1 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: None
# Any other information needed? None

#### Workspace setup ####
library(tidyverse)
library(ggplot2)

#### Simulate data ####
set.seed(777)

# Define variables
wards <- 1:25  # Toronto ward numbers
speed_bins <- c("[55,60)", "[10,15)", "[35,40)", "[30,35)", "[15,20)", "[85,90)", "[25,30)", "[60,65)", "[40,45)", 
                "[5,10)", "[100,)", "[50,55)", "[45,50)", "[20,25)", "[75,80)", "[80,85)", "[90,95)", "[95,100)", 
                "[70,75)", "[65,70)")

# Custom probabilities for speed bins
speed_bin_probabilities <- c(
  "[55,60)" = 0.12,
  "[10,15)" = 0.10,
  "[35,40)" = 0.10,
  "[30,35)" = 0.10,
  "[15,20)" = 0.10,
  "[85,90)" = 0.01,  # Extremely unlikely
  "[25,30)" = 0.10,
  "[60,65)" = 0.12,
  "[40,45)" = 0.12,
  "[5,10)" = 0.08,
  "[100,)" = 0.005,  # Rare extreme speeds
  "[50,55)" = 0.12,
  "[45,50)" = 0.12,
  "[20,25)" = 0.10,
  "[75,80)" = 0.03,  # Less likely
  "[80,85)" = 0.02,  # Less likely
  "[90,95)" = 0.005, # Extremely unlikely
  "[95,100)" = 0.005, # Extremely unlikely
  "[70,75)" = 0.05,  # Less likely
  "[65,70)" = 0.08
)

# Normalize probabilities (to ensure they sum to 1)
speed_bin_probabilities <- speed_bin_probabilities / sum(speed_bin_probabilities)
ward_probabilities <- runif(length(wards), 0.1, 0.3)  # Probability of high-speed bins by ward

# Number of observations
num_observations <- 5000  

# Simulate data
simulated_data <- tibble(
  sign_id = sample(unique(final_filtered_data$sign_id), num_observations, replace = TRUE),  # Random sign IDs
  X_id = sample(unique(final_filtered_data$X_id), num_observations, replace = TRUE),  # Random camera IDs
  ward_no = sample(wards, num_observations, replace = TRUE),  # Random wards
  longitude = runif(num_observations, -79.65, -79.0),  # Toronto longitude range
  latitude = runif(num_observations, 43.6, 43.8),  # Toronto latitude range
  speed_limit = sample(c(30, 40, 50, 60), num_observations, replace = TRUE),  # Common speed limits
  volume = sample(1:100, num_observations, replace = TRUE),  # Traffic volume
  speed_bin = sample(speed_bins, num_observations, replace = TRUE),  # Initial speed bins
  no_camera_in_radius = sample(c(TRUE, FALSE), num_observations, replace = TRUE, prob = c(0.3, 0.7))  # Camera presence
)

# Adjust speed bins by ward-specific probabilities
ward_adjustments <- tibble(ward_no = wards, prob_high_speed = ward_probabilities)
simulated_data <- simulated_data %>%
  left_join(ward_adjustments, by = "ward_no") %>%
  mutate(
    speed_bin = ifelse(runif(n()) < prob_high_speed, "[85,90)", speed_bin)  # Assign higher speed bins in specific wards
  )

# Introduce outliers (e.g., extreme speeds in rare cases)
simulated_data <- simulated_data %>%
  mutate(
    speed_bin = ifelse(runif(n()) < 0.01, "[100,)", speed_bin)  # Add 1% extreme speeding cases
  )

#### Plots ####

# Mutate for simplified plot
simplified_data <- simulated_data %>%
  mutate(
    speed_bin = case_when(
      speed_bin %in% c("[5,10)", "[10,15)", "[15,20)") ~ "[5,20)",
      speed_bin %in% c("[20,25)", "[25,30)", "[30,35)") ~ "[20,35)",
      speed_bin %in% c("[35,40)", "[40,45)", "[45,50)") ~ "[35,50)",
      speed_bin %in% c("[50,55)", "[55,60)", "[60,65)") ~ "[50,65)",
      speed_bin %in% c("[65,70)", "[70,75)", "[75,80)") ~ "[65,80)",
      speed_bin %in% c("[80,85)", "[85,90)", "[90,95)") ~ "[80,95)",
      speed_bin %in% c("[95,100)", "[100,)") ~ "[95,100+)",
      TRUE ~ speed_bin  # Default case (if needed)
    )
  )

# Plot 1: Speed Bin Distribution by Ward
ggplot(simplified_data, aes(x = factor(ward_no), fill = speed_bin)) +
  geom_bar(position = "fill") +
  labs(title = "Speed Bin Distribution by Ward", x = "Ward", y = "Proportion") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set3") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Plot 2: Extreme Speeds by Ward
extreme_speed_data <- simulated_data %>% filter(speed_bin == "[100,)")
ggplot(extreme_speed_data, aes(x = factor(ward_no))) +
  geom_bar(fill = "red") +
  labs(title = "Frequency of Extreme Speeds by Ward", x = "Ward", y = "Count") +
  theme_minimal()

# Plot 3: Heatmap of extreme speeding

filtered_data <- simplified_data %>%
  filter(
    speed_bin %in% c("[80,85)", "[85,90)", "[90,95)", "[95,100+)")
  )

ggplot(filtered_data, aes(x = longitude, y = latitude)) +
  stat_density_2d(aes(fill = ..density..), geom = "raster", contour = FALSE) +
  scale_fill_gradient(low = "lightblue", high = "red") +  # Custom color palette
  labs(
    title = "Heatmap of Speeding Events Above 80 km/h",
    x = "Longitude",
    y = "Latitude",
    fill = "Density"
  ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),  # Remove grid lines for a cleaner look
    panel.background = element_rect(fill = "white")  # White background
  )

# Plot 4: Volume of Extreme Speeding 

# Parse speed bin and calculate observed speed
speeding_data <- simulated_data %>%
  mutate(
    # Extract the lower bound of the speed_bin (e.g., "[55,60)" -> 55)
    observed_speed = as.numeric(str_extract(speed_bin, "(?<=\\[)\\d+")),
    # Check if the observed speed exceeds the speed limit
    speeding_volume = ifelse(observed_speed > speed_limit, volume, 0)
  ) %>%
  filter(speeding_volume > 30)  # Keep only rows where extreme speeding occurred

# Aggregate total speeding volume by ward
ward_speeding_volume <- speeding_data %>%
  group_by(ward_no) %>%
  summarise(total_speeding_volume = sum(speeding_volume, na.rm = TRUE)) %>%
  arrange(desc(total_speeding_volume))

#### Plot Speeding Volume by Ward ####
ggplot(ward_speeding_volume, aes(x = factor(ward_no), y = total_speeding_volume, fill = total_speeding_volume)) +
  geom_col() +
  scale_fill_gradient(low = "lightblue", high = "red") +
  labs(
    title = "Traffic Volume of Vehicles Exceeding Speed Limit by Ward",
    x = "Ward",
    y = "Total Speeding Volume",
    fill = "Total Volume"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

#### Save Data ####

write_csv(simulated_data, file = "data/simulated_data/simulated.csv")
