##install.packages(c("readxl", "ggplot2"))

# TOMMY JOHN SURGERY PREDICTION MODEL
# Garrett Jones and Sam Herdlick
# Creighton University

# 1. Load packages
library(readxl)
library(ggplot2)

# 2. Import Excel dataset

# Opens a window to select your Excel file
file <- file.choose()

# Read the selected Excel file
data <- read_excel(
  file,
  sheet = "MLB Pitchers 2018-2023 TJ"
)

# Check that the data loaded
head(data)

# 3. Rename columns for easier use
names(data)[names(data) == "Player"] <- "Player"
names(data)[names(data) == "Age"] <- "Age"
names(data)[names(data) == "ERA - Before"] <- "ERA_Before"
names(data)[names(data) == "ERA - After"] <- "ERA_After"
names(data)[names(data) == "FIP - Before"] <- "FIP_Before"
names(data)[names(data) == "FIP - After"] <- "FIP_After"
names(data)[names(data) == "K-BB% - Before"] <- "KBB_Before"
names(data)[names(data) == "K-BB% - After"] <- "KBB_After"
names(data)[names(data) == "Innings Pitched - Before"] <- "IP_Before"
names(data)[names(data) == "Innings Pitched - After"] <- "IP_After"

# Convert baseball innings notation to true innings
# Example: 65.2 means 65 and 2/3 innings
convert_ip <- function(x) {
  whole <- floor(x)
  fraction <- round((x - whole) * 10)
  whole + fraction / 3
}

data$IP_Before <- convert_ip(
  as.numeric(data$IP_Before)
)
data$IP_After <- convert_ip(
  as.numeric(data$IP_After)
)

# 4. Select model variables
columns <- c(
  "Age", "ERA_Before", "FIP_Before",
  "KBB_Before", "IP_Before",
  "ERA_After", "FIP_After",
  "KBB_After", "IP_After"
)

model_data <- data[, columns]

# Convert columns to numeric
model_data[] <- lapply(
  model_data, function(x) suppressWarnings(as.numeric(x))
)

# Remove rows with missing or invalid values
model_data <- model_data[complete.cases(model_data), ]

model_data <- model_data[
  model_data$IP_Before > 0 &
    model_data$IP_After > 0 &
    model_data$ERA_Before >= 0 &
    model_data$ERA_After >= 0 &
    model_data$FIP_Before >= 0 &
    model_data$FIP_After >= 0, ]

cat("Usable pitchers:", nrow(model_data), "\n")

# 5. Split data: 80% training, 20% testing
set.seed(123)

train_index <- sample(
  seq_len(nrow(model_data)),
  size = floor(0.8 * nrow(model_data))
)

train <- model_data[train_index, ]
test <- model_data[-train_index, ]

# 6. Train multiple linear regression models
predictors <- paste(
  c("Age", "ERA_Before", "FIP_Before",
    "KBB_Before", "IP_Before"),
  collapse = " + "
)

targets <- c(
  "ERA_After", "FIP_After",
  "KBB_After", "IP_After"
)

models <- lapply(targets, function(target) {
  formula <- as.formula(
    paste(target, "~", predictors)
  )
  lm(formula, data = train)
})

names(models) <- targets

# 7. Predict test-set performance
predictions <- lapply(
  models, predict, newdata = test
)

# 8. Calculate model accuracy
accuracy <- data.frame()

for (target in targets) {
  actual <- test[[target]]
  predicted <- predictions[[target]]
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  r2 <- if (sum((actual - mean(actual))^2) > 0) {
    1 - sum((actual - predicted)^2) /
      sum((actual - mean(actual))^2)
  } else {
    NA_real_
  }
  
  accuracy <- rbind(
    accuracy,
    data.frame(
      Statistic = target,
      MAE = round(mae, 4),
      RMSE = round(rmse, 4),
      Test_R2 = round(r2, 4)
    )
  )
}

print(accuracy)

# 9. Generate actual vs predicted graphs
dir.create("graphs", showWarnings = FALSE)

for (target in targets) {
  plot_data <- data.frame(
    Actual = test[[target]],
    Predicted = as.numeric(predictions[[target]])
  )
  
  graph <- ggplot(
    plot_data,
    aes(x = Actual, y = Predicted)
  ) +
    geom_point(color = "#006747", size = 2.5) +
    geom_abline(
      slope = 1, intercept = 0,
      linetype = "dashed"
    ) +
    labs(
      title = paste("Actual vs Predicted", target),
      x = "Actual Post-Surgery Value",
      y = "Predicted Post-Surgery Value"
    ) +
    theme_minimal(base_size = 13)
  
  print(graph)
  
  ggsave(
    paste0("graphs/", target, ".png"),
    plot = graph,
    width = 7,
    height = 5,
    dpi = 300
  )
}

# 10. Example pitcher prediction
new_pitcher <- data.frame(
  Age = 27,
  ERA_Before = 3.50,
  FIP_Before = 3.70,
  KBB_Before = 0.18,
  IP_Before = 150
)

cat("\nExample pitcher predictions:\n")

for (target in targets) {
  value <- predict(
    models[[target]],
    newdata = new_pitcher
  )
  
  cat(target, ":", round(value, 3), "\n")
}

# 11. Save models and results
saveRDS(models, "tommy_john_models.rds")
write.csv(
  accuracy,
  "model_accuracy.csv",
  row.names = FALSE
)

cat("\nModel complete! Files saved.\n")

##--------------------------------------------------##

# CHECK FOR EXTREME POST-SURGERY STATISTICS

# Summary of post-surgery ERA
summary(model_data$ERA_After)

# Summary of post-surgery FIP
summary(model_data$FIP_After)

# Summary of post-surgery innings pitched
summary(model_data$IP_After)

# Show pitchers with the highest post-surgery ERA
head(
  model_data[
    order(-model_data$ERA_After),
    c("ERA_After", "FIP_After", "IP_After")
  ],
  10
)

# Count pitchers with fewer than 20 innings after surgery
sum(model_data$IP_After < 20)

# Count pitchers with ERA above 10
sum(model_data$ERA_After > 10)

##-----------------------------------------------------------------##

# MODEL 2: MINIMUM 20 POST-SURGERY INNINGS

# Keep original training/test split
train2 <- train[train$IP_After >= 20, ]
test2 <- test[test$IP_After >= 20, ]

cat("Model 2 training pitchers:", nrow(train2), "\n")
cat("Model 2 testing pitchers:", nrow(test2), "\n")

# Train second set of regression models
models2 <- lapply(targets, function(target) {
  formula <- as.formula(
    paste(target, "~", predictors)
  )
  lm(formula, data = train2)
})

names(models2) <- targets

# Evaluate both models on the SAME test pitchers
comparison <- data.frame()

for (target in targets) {
  
  actual <- test2[[target]]
  
  pred_original <- as.numeric(
    predict(models[[target]], newdata = test2)
  )
  
  pred_filtered <- as.numeric(
    predict(models2[[target]], newdata = test2)
  )
  
  calculate_metrics <- function(predicted) {
    c(
      MAE = mean(abs(actual - predicted)),
      RMSE = sqrt(mean((actual - predicted)^2)),
      R2 = 1 - sum((actual - predicted)^2) /
        sum((actual - mean(actual))^2)
    )
  }
  
  original_metrics <- calculate_metrics(pred_original)
  filtered_metrics <- calculate_metrics(pred_filtered)
  
  comparison <- rbind(
    comparison,
    data.frame(
      Statistic = target,
      Model = "Original",
      t(original_metrics)
    ),
    data.frame(
      Statistic = target,
      Model = "Filtered_20IP",
      t(filtered_metrics)
    )
  )
}

comparison$MAE <- round(comparison$MAE, 4)
comparison$RMSE <- round(comparison$RMSE, 4)
comparison$R2 <- round(comparison$R2, 4)

print(comparison)

write.csv(
  comparison,
  "model_comparison.csv",
  row.names = FALSE
)

##----------------------------------------------------------------##
##install.packages("ranger")

# MODEL 3: RANDOM FOREST
library(ranger)

# Use the same training and testing pitchers
# as our original regression

rf_models <- list()
rf_results <- data.frame()

set.seed(123)

for (target in targets) {
  
  formula <- as.formula(
    paste(target, "~", predictors)
  )
  
  # Train random forest
  rf <- ranger(
    formula,
    data = as.data.frame(train),
    num.trees = 500,
    mtry = 2,
    min.node.size = 5,
    seed = 123
  )
  
  rf_models[[target]] <- rf
  
  # Predict on the original test set
  predicted <- predict(
    rf,
    data = as.data.frame(test)
  )$predictions
  
  actual <- test[[target]]
  
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  
  r2 <- 1 -
    sum((actual - predicted)^2) /
    sum((actual - mean(actual))^2)
  
  rf_results <- rbind(
    rf_results,
    data.frame(
      Statistic = target,
      MAE = round(mae, 4),
      RMSE = round(rmse, 4),
      Test_R2 = round(r2, 4)
    )
  )
}

cat("\nRANDOM FOREST RESULTS:\n")
print(rf_results)

cat("\nORIGINAL REGRESSION RESULTS:\n")
print(accuracy)

# Save random forest models
saveRDS(
  rf_models,
  "tommy_john_random_forest.rds"
)

write.csv(
  rf_results,
  "random_forest_accuracy.csv",
  row.names = FALSE
)

##--------------------------------------------------------------##
##install.packages("glmnet")

# MODEL 4: RIDGE REGRESSION

library(glmnet)

# Use the SAME original training/test split
features <- c(
  "Age", "ERA_Before", "FIP_Before",
  "KBB_Before", "IP_Before"
)

x_train <- as.matrix(train[, features])
x_test <- as.matrix(test[, features])

ridge_models <- list()
ridge_results <- data.frame()

set.seed(123)

for (target in targets) {
  
  y_train <- train[[target]]
  y_test <- test[[target]]
  
  # Choose penalty using cross-validation
  ridge <- cv.glmnet(
    x = x_train,
    y = y_train,
    alpha = 0,
    nfolds = 5,
    standardize = TRUE
  )
  
  ridge_models[[target]] <- ridge
  
  # Predict held-out pitchers
  predicted <- as.numeric(
    predict(
      ridge,
      newx = x_test,
      s = "lambda.1se"
    )
  )
  
  # Baseline: training-set mean
  baseline <- rep(mean(y_train), length(y_test))
  
  calculate_metrics <- function(pred) {
    c(
      MAE = mean(abs(y_test - pred)),
      RMSE = sqrt(mean((y_test - pred)^2)),
      R2 = 1 - sum((y_test - pred)^2) /
        sum((y_test - mean(y_test))^2)
    )
  }
  
  ridge_metrics <- calculate_metrics(predicted)
  baseline_metrics <- calculate_metrics(baseline)
  
  ridge_results <- rbind(
    ridge_results,
    data.frame(
      Statistic = target,
      Model = "Ridge",
      t(ridge_metrics)
    ),
    data.frame(
      Statistic = target,
      Model = "Baseline_Mean",
      t(baseline_metrics)
    )
  )
}

ridge_results[, 3:5] <- round(
  ridge_results[, 3:5], 4
)

cat("\nRIDGE VS BASELINE RESULTS:\n")
print(ridge_results)

saveRDS(
  ridge_models,
  "tommy_john_ridge_models.rds"
)

write.csv(
  ridge_results,
  "ridge_results.csv",
  row.names = FALSE
)

# CHECK SAMPLE SIZES AT DIFFERENT INNINGS THRESHOLDS

thresholds <- c(0, 10, 20, 30, 50, 75, 100)

sample_sizes <- data.frame(
  Minimum_IP = thresholds,
  Pitchers = sapply(thresholds, function(n) {
    sum(
      model_data$IP_Before >= n &
        model_data$IP_After >= n
    )
  })
)

print(sample_sizes)

# Check relationships between pre- and post-surgery stats
correlations <- data.frame(
  Statistic = c("ERA", "FIP", "K-BB%", "IP"),
  Correlation = c(
    cor(model_data$ERA_Before, model_data$ERA_After),
    cor(model_data$FIP_Before, model_data$FIP_After),
    cor(model_data$KBB_Before, model_data$KBB_After),
    cor(model_data$IP_Before, model_data$IP_After)
  )
)

print(correlations)

##--------------------------------------------------------##

# MODEL 5: PREDICT CHANGES IN PERFORMANCE

library(glmnet)

stats <- c("ERA", "FIP", "KBB")

change_results <- data.frame()
change_models <- list()

x_train <- as.matrix(train[, features])
x_test <- as.matrix(test[, features])

set.seed(123)

for (stat in stats) {
  
  before <- paste0(stat, "_Before")
  after <- paste0(stat, "_After")
  
  # Calculate observed change in training data
  y_change <- train[[after]] - train[[before]]
  
  # Train model to predict change
  change_model <- cv.glmnet(
    x_train,
    y_change,
    alpha = 0,
    nfolds = 5
  )
  
  change_models[[stat]] <- change_model
  
  # Predict change for test pitchers
  predicted_change <- as.numeric(
    predict(
      change_model,
      newx = x_test,
      s = "lambda.1se"
    )
  )
  
  # Convert back to post-surgery predictions
  predicted_after <- test[[before]] + predicted_change
  
  actual_after <- test[[after]]
  
  mae <- mean(abs(actual_after - predicted_after))
  
  rmse <- sqrt(
    mean((actual_after - predicted_after)^2)
  )
  
  r2 <- 1 -
    sum((actual_after - predicted_after)^2) /
    sum((actual_after - mean(actual_after))^2)
  
  change_results <- rbind(
    change_results,
    data.frame(
      Statistic = stat,
      MAE = round(mae, 4),
      RMSE = round(rmse, 4),
      Test_R2 = round(r2, 4)
    )
  )
}

cat("\nCHANGE MODEL RESULTS:\n")
print(change_results)

saveRDS(
  change_models,
  "tommy_john_change_models.rds"
)

##----------------------------------------------------##
# FINAL MODEL EXPORT AND PREDICTION FUNCTION

# Save the original linear regression models
saveRDS(
  models,
  "tommy_john_final_models.rds"
)

# Load saved models
models <- readRDS("tommy_john_final_models.rds")

# Function to predict post-surgery statistics
predict_tommy_john <- function(
    age,
    era,
    fip,
    kbb,
    ip
) {
  
  new_pitcher <- data.frame(
    Age = age,
    ERA_Before = era,
    FIP_Before = fip,
    KBB_Before = kbb / 100,
    IP_Before = ip
  )
  
  predictions <- sapply(
    models,
    function(model) {
      as.numeric(
        predict(model, newdata = new_pitcher)
      )
    }
  )
  
  return(round(predictions, 3))
}

# Example: 27-year-old pitcher
# 3.50 ERA, 3.70 FIP, 18% K-BB, 150 IP

example <- predict_tommy_john(
  age = 27,
  era = 3.50,
  fip = 3.70,
  kbb = 18,
  ip = 150
)

cat("\nFINAL MODEL PREDICTIONS:\n")
print(example)

##--------------------------------------------------##
# ==========================================
# FINAL PRESENTATION GRAPHS
# ==========================================

library(ggplot2)

# Create folder for presentation graphs
dir.create("final_graphs", showWarnings = FALSE)

# GRAPH 1: Model comparison (Test R-squared)

# Create consistent columns for all three models
linear_comparison <- data.frame(
  Model = "Linear Regression",
  Statistic = accuracy$Statistic,
  Test_R2 = accuracy$Test_R2
)

forest_comparison <- data.frame(
  Model = "Random Forest",
  Statistic = rf_results$Statistic,
  Test_R2 = rf_results$Test_R2
)

ridge_only <- ridge_results[
  ridge_results$Model == "Ridge",
]

ridge_comparison <- data.frame(
  Model = "Ridge Regression",
  Statistic = ridge_only$Statistic,
  Test_R2 = ridge_only$R2
)

# Combine results
comparison <- rbind(
  linear_comparison,
  forest_comparison,
  ridge_comparison
)

# Create graph
graph1 <- ggplot(
  comparison,
  aes(x = Model, y = Test_R2, fill = Model)
) +
  geom_col() +
  facet_wrap(~ Statistic, scales = "free_y") +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Predictive Performance by Model",
    subtitle = "Test-set R-squared for post-surgery statistics",
    x = "",
    y = "Test R-squared"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(
      angle = 25,
      hjust = 1
    ),
    legend.position = "none"
  )

print(graph1)

ggsave(
  "final_graphs/model_comparison.png",
  plot = graph1,
  width = 11,
  height = 7,
  dpi = 300
)

# GRAPH 2: Actual vs Predicted Innings Pitched

ip_predictions <- data.frame(
  Actual = test$IP_After,
  Predicted = as.numeric(
    predict(models[["IP_After"]], newdata = test)
  )
)

ggplot(ip_predictions,
       aes(x = Actual, y = Predicted)) +
  geom_point(color = "#0072B2", size = 3, alpha = 0.75) +
  geom_abline(
    slope = 1, intercept = 0,
    linetype = "dashed", color = "red"
  ) +
  labs(
    title = "Actual vs Predicted Innings Pitched",
    subtitle = "Multiple Linear Regression",
    x = "Actual Post-Surgery Innings",
    y = "Predicted Post-Surgery Innings"
  ) +
  theme_minimal(base_size = 14)

ggsave(
  "final_graphs/innings_predictions.png",
  width = 9, height = 6, dpi = 300
)


# GRAPH 3: Pre- vs Post-Surgery Performance

performance <- data.frame(
  Statistic = rep(c("ERA", "FIP", "K-BB%"), each = 2),
  Period = rep(c("Before", "After"), 3),
  Value = c(
    mean(model_data$ERA_Before),
    mean(model_data$ERA_After),
    mean(model_data$FIP_Before),
    mean(model_data$FIP_After),
    mean(model_data$KBB_Before) * 100,
    mean(model_data$KBB_After) * 100
  )
)

ggplot(performance,
       aes(x = Period, y = Value, fill = Period)) +
  geom_col(width = 0.6) +
  facet_wrap(~ Statistic, scales = "free_y") +
  labs(
    title = "Pitching Performance Before and After Tommy John Surgery",
    subtitle = "Average statistics across 127 pitchers",
    x = "",
    y = "Average Value (K-BB% in percentage points)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")

ggsave(
  "final_graphs/before_after_performance.png",
  width = 11, height = 6, dpi = 300
)

cat("\nAll three presentation graphs saved!\n")



# ============================================================
# VIDEO DEMO - TOMMY JOHN SURGERY PREDICTIVE MODELING
# ============================================================

# STEP 1: SHOW THE DATA
# ------------------------------------------------------------

# Five pre-surgery predictors
predictors <- c(
  "Age",
  "ERA_Before",
  "FIP_Before",
  "KBB_Before",
  "IP_Before"
)

# Four post-surgery outcomes
outcomes <- c(
  "ERA_After",
  "FIP_After",
  "KBB_After",
  "IP_After"
)

# Display sample data
head(model_data[, c(predictors, outcomes)])

# Display dataset sizes
cat("Total pitchers:", nrow(model_data), "\n")
cat("Training pitchers:", nrow(train), "\n")
cat("Testing pitchers:", nrow(test), "\n")


# STEP 2: TRAIN THE FINAL LINEAR REGRESSION MODELS
# ------------------------------------------------------------

# Model 1: Multiple Linear Regression
# Predict four post-surgery statistics

demo_models <- lapply(outcomes, function(target) {
  formula <- as.formula(
    paste(target, "~", paste(predictors, collapse = " + "))
  )
  
  lm(formula, data = train)
})

names(demo_models) <- outcomes

cat("\nLinear Regression models trained successfully.\n")

# Show an example model summary
summary(demo_models[["IP_After"]])


# STEP 3: EVALUATE THE MODELS
# ------------------------------------------------------------

# Calculate prediction accuracy
evaluate_model <- function(actual, predicted) {
  mae <- mean(abs(actual - predicted))
  
  rmse <- sqrt(mean((actual - predicted)^2))
  
  r2 <- 1 - sum((actual - predicted)^2) /
    sum((actual - mean(actual))^2)
  
  data.frame(
    MAE = round(mae, 3),
    RMSE = round(rmse, 3),
    R_Squared = round(r2, 3)
  )
}

# Evaluate all four outcomes on the test set
demo_results <- do.call(rbind, lapply(outcomes, function(target) {
  predictions <- predict(
    demo_models[[target]],
    newdata = test
  )
  
  results <- evaluate_model(
    test[[target]],
    predictions
  )
  
  data.frame(
    Outcome = target,
    results
  )
}))

rownames(demo_results) <- NULL

print(demo_results)

# STEP 4: PREDICT A HYPOTHETICAL PITCHER
# ------------------------------------------------------------

# Example pre-surgery statistics
new_pitcher <- data.frame(
  Age = 27,
  ERA_Before = 3.50,
  FIP_Before = 3.70,
  KBB_Before = 0.18,
  IP_Before = 150
)

cat("\nExample pitcher inputs:\n")
print(new_pitcher)

# Predict all four post-surgery statistics
demo_prediction <- data.frame(
  Statistic = c(
    "ERA After",
    "FIP After",
    "K-BB% After",
    "Innings Pitched After"
  ),
  
  Prediction = c(
    predict(demo_models[["ERA_After"]], new_pitcher),
    predict(demo_models[["FIP_After"]], new_pitcher),
    predict(demo_models[["KBB_After"]], new_pitcher) * 100,
    predict(demo_models[["IP_After"]], new_pitcher)
  )
)

demo_prediction$Prediction <- round(
  demo_prediction$Prediction, 2
)

cat("\nPredicted post-surgery performance:\n")
print(demo_prediction)

# ============================================================
# END OF VIDEO DEMO
# ============================================================