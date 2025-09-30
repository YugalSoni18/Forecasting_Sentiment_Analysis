#-------------------------------------------------------------------------------
# 1. Loading Libraries
#-------------------------------------------------------------------------------
library(ggplot2)
library(tidyverse)
library(forecast)
library(tseries)
library(imputeTS)
library(zoo)
#-------------------------------------------------------------------------------
# 2. Load and Prepare the Data
#-------------------------------------------------------------------------------
# Load CSV
pce_data <- read.csv("data/PCE.csv")
# Check for missing values
sum(is.na(pce_data))
# Impute missing values using Kalman Smoothing
pce_data$PCE <- na_kalman(pce_data$PCE, model = "StructTS", smooth = TRUE)
# Convert to time series object: Monthly data starting Jan 1959
pce_ts <- ts(pce_data$PCE, start = c(1959, 1), frequency = 12)
autoplot(pce_ts) +
  ggtitle("PCE Over Time") +
  ylab("Personal Consumption Expenditures (Billion $)") +
  xlab("Year")
#-------------------------------------------------------------------------------
# 3. Time Series Diagnostics
#-------------------------------------------------------------------------------
# Decomposition (full series)
decomp <- decompose(pce_ts)
autoplot(decomp) + ggtitle("Time Series Decomposition of PCE (1959–2025)")
# Seasonality analysis
ggseasonplot(pce_ts, year.labels = TRUE, main = "Seasonality in PCE") +
  ylab("PCE") + xlab("Month")
# Autocorrelation
ggAcf(pce_ts) + ggtitle("ACF of Full PCE Series")
#-------------------------------------------------------------------------------
# 4. Train-Test Split
#-------------------------------------------------------------------------------
# Train: Jan 1959 to Dec 2023 | Test: Jan 2024 to Dec 2024
train_ts <- window(pce_ts, end = c(2023, 12))
test_ts <- window(pce_ts, start = c(2024, 1))
#-------------------------------------------------------------------------------
# 5. Forecasting Models
#-------------------------------------------------------------------------------
## 5.1 Naive Forecast
naive_model <- naive(train_ts,h=12)
summary(naive_model)
## 5.2 ETS Forecast
ets_model <- ets(train_ts)
ets_forecast <- forecast(ets_model, h = 12)
summary(ets_forecast)
## 5.3 ARIMA Forecast
arima_model <- auto.arima(train_ts)
arima_forecast <- forecast(arima_model, h = 12)
summary(arima_forecast)
# Residual check
checkresiduals(arima_model)
#-------------------------------------------------------------------------------
# 6. Visual Comparison of Forecasts
#-------------------------------------------------------------------------------
## Focused time range for comparison (2015–2025)
recent_data <- window(pce_ts, start = c(2015, 1))
# Overlay actual data with forecasts from all three models
p <- autoplot(recent_data, series = "Actual") +
  autolayer(naive_model, series = "Naive") +
  autolayer(ets_forecast, series = "ETS") +
  autolayer(arima_forecast, series = "ARIMA") +
  ggtitle("Forecast Comparison: Naive vs ETS vs ARIMA") +
  ylab("PCE") + xlab("Year") +
  guides(colour = guide_legend(title = "Forecast Method")) +
  scale_color_manual(
  theme_minimal()
print(p)
# Create a time window starting from 2024
forecast_window <- window(pce_ts, start = c(2024, 1))
# Plot forecasts for 2024 only
autoplot(forecast_window, series = "Actual") +
  autolayer(naive_model$mean, series = "Naive", size = 1.1) +
  autolayer(ets_forecast$mean, series = "ETS", size = 1.1) +
  autolayer(arima_forecast$mean, series = "ARIMA", size = 1.1) +
  scale_color_manual(
  ggtitle("Forecast Comparison for 2024: Naive vs ETS vs ARIMA") +
  xlab("Month in 2024") +
  ylab("PCE (Billions USD)") +
  guides(colour = guide_legend(title = "Model")) +
  theme_minimal(base_size = 14) +
  theme(
#-------------------------------------------------------------------------------
# 7. forecast accuracy evaluation
# ------------------------------------------------------------------------------
# Compare model accuracy on the test set (jan 2024 to dec 2024)
naive_acc <- accuracy(naive_model, test_ts)
ets_acc   <- accuracy(ets_forecast, test_ts)
arima_acc <- accuracy(arima_forecast, test_ts)
# Combine results into a summary table
accuracy_table <- rbind(
print(round(accuracy_table, 2))
#-------------------------------------------------------------------------------
# 8. final forecast using best model
#-------------------------------------------------------------------------------
# Arima is the best, as seen in the accuracy table
final_model <- auto.arima(pce_ts)
final_forecast <- forecast(final_model, h = 12)
# Plot the final forecast for 2025
autoplot(final_forecast) +
  ggtitle("12-Month Forecast using ARIMA") +
  ylab("PCE (Billions)") +
  xlab("Year")
# Zoomed-in ARIMA Forecast from 2022 onwards
autoplot(window(pce_ts, start = c(2024, 1)), series = "Historical PCE") +
  autolayer(final_forecast$mean, series = "Forecast", size = 1.2) +
  autolayer(final_forecast$lower, series = "Lower 80/95%", linetype = "dashed", alpha = 0.4) +
  autolayer(final_forecast$upper, series = "Upper 80/95%", linetype = "dashed", alpha = 0.4) +
  scale_colour_manual(values = c("Historical PCE" = "black", "Forecast" = "red")) +
  labs(title = "Forecast of US PCE (2025)",
       subtitle = "2025 forecast using ARIMA model with 80% and 95% prediction intervals",
  theme_minimal(base_size = 13) +
  theme(
# Print forecasted values
print(final_forecast)
