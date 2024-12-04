#### Preamble ####
# Purpose:  Checking and Fitting Models and Making Predictions
# Author: Karen Riani
# Date: 3 December 2024
# Contact: karen.riani@mail.utoronto.ca
# Pre-requisites: Run 02-data_cleaning.R script
# Any other information needed? None.

#### Workspace setup ####
library(tidyverse)
library(tidymodels)
library(arrow)
library(rstanarm)
library(pROC)

# Load the cleaned dataset
final_filtered_data <- arrow::read_parquet("data/analysis_data/analysis_data.parquet")

# Convert `ward_no` to a factor for categorical analysis
final_filtered_data <- final_filtered_data %>%
  mutate(ward_no = factor(ward_no))


#### Test data ####

### Checking for collinearity in camera columns
# Calculate camera density
camera_density <- final_filtered_data %>%
  group_by(ward_no) %>%
  summarize(cameras_nearby = n_distinct(X_id), .groups = "drop")

# Add to the final_filtered_data
cam_filtered_data <- final_filtered_data %>%
  left_join(camera_density, by = "ward_no")

model_camera_density <- lm(
  over_speed_limit ~  speed_limit + volume + cameras_nearby + ward_no,
  data = cam_filtered_data
)

# View Collinearity
summary(model_camera_density)
vif(model_camera_density)


### Modelling without camera columns

## Set seed for reproducibility and split the data 
set.seed(777)
data_split <- initial_split(final_filtered_data, prop = 0.80) # 80-20 split
data_train <- training(data_split)
data_test <- testing(data_split)

# Ensure consistent levels for ward_no in training and test datasets
common_levels <- levels(factor(data_train$ward_no))
data_train <- data_train %>%
  mutate(ward_no = factor(ward_no, levels = common_levels))

data_test <- data_test %>%
  mutate(ward_no = factor(ward_no, levels = common_levels))

# Ensure no NA in critical columns for the test set
data_test <- data_test %>%
  filter(if_all(c("speed_limit", "volume", "ward_no", "X_id"), ~ !is.na(.)))

#### Model 1 ####
# Fit MLR model on the training dataset
model_1 <- lm(
  over_speed_limit ~ speed_limit + volume + ward_no,
  data = data_train
)

# View model summary and compute VIF
summary(model_1)
vif(model_1)

# Generate predictions on the test set and calculate metrics
predictions_1 <- predict(model_1, newdata = data_test)
rmse_1 <- sqrt(mean((data_test$over_speed_limit - predictions_1)^2))
mae_1 <- mean(abs(data_test$over_speed_limit - predictions_1))

#### Model 2 ####
# Fit the MLR model without ward_no
model_2 <- lm(
  over_speed_limit ~ speed_limit + volume,
  data = data_train
)

# View model summary and VIF
summary(model_2)
vif(model_2)

# Generate predictions on the test set and calculate metrics
predictions_2 <- predict(model_2, newdata = data_test)
rmse_2 <- sqrt(mean((data_test$over_speed_limit - predictions_2)^2))
mae_2 <- mean(abs(data_test$over_speed_limit - predictions_2))

#### Model 3 ####
# Fit MLR model with X_id
model_3 <- lm(
  over_speed_limit ~ speed_limit + volume + ward_no + X_id,
  data = data_train
)

# View model summary and compute VIF
summary(model_3)
vif(model_3)

# Generate predictions on the test set and calculate metrics
predictions_3 <- predict(model_1, newdata = data_test)
rmse_3 <- sqrt(mean((data_test$over_speed_limit - predictions_1)^2))
mae_3 <- mean(abs(data_test$over_speed_limit - predictions_1))

#### Additional Validation Checks ####
# Plot residuals for Model 1
plot(model_1, which = 1, main = "Residuals vs Fitted for Model 1")

# Residual diagnostics for Model 2
plot(model_2, which = 1, main = "Residuals vs Fitted for Model 2")

# Add comparison of residuals for both models
residuals_1 <- residuals(model_1)
residuals_2 <- residuals(model_2)

summary(residuals_1)
summary(residuals_2)

#### Save models ####
saveRDS(
  model_1,
  file = "models/first_model.rds"
)

saveRDS(
  model_2,
  file = "models/second_model.rds"
)
