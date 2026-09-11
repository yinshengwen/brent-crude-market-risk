# ============================================================
# Brent Crude Oil Trading & Market Risk Analytics
# ============================================================

# 1. Setup
# ============================================================
install.packages(c(
  "tidyverse",
  "lubridate",
  "scales",
  "zoo",
  "randomForest"
))

library(tidyverse)
library(lubridate)
library(scales)
library(zoo)
library(randomForest)

dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

# ============================================================
# 2. Data Collection
# ============================================================
brent_url <- "https://fred.stlouisfed.org/graph/fredgraph.csv?id=DCOILBRENTEU"

wti_url <- "https://fred.stlouisfed.org/graph/fredgraph.csv?id=DCOILWTICO"

brent <- read_csv(brent_url)
wti <- read_csv(wti_url)

brent <- brent %>%
  rename(
    date = observation_date,   # Rename date column
    brent = DCOILBRENTEU       # Rename price column to 'brent'
  )

wti <- wti %>%
  rename(
    date = observation_date,   # Rename date column
    wti = DCOILWTICO           # Rename price column to 'wti'
  )

# ============================================================
# 3. Data Cleaning
# ============================================================

## 3.1 Convert date format
# ----------------------------------------------------------------------------
brent <- brent %>%
  mutate(
    date = as.Date(date)
  )

wti <- wti %>%
  mutate(
    date = as.Date(date)
  )

## 3.2 Remove missing values
# ----------------------------------------------------------------------------

### 3.2.1 Clean Brent data
brent <- brent %>%
  filter(!is.na(brent))   # Remove rows where Brent price is missing

### 3.2.2 Clean WTI data

wti <- wti %>%
  filter(!is.na(wti))  # Remove rows where WTI price is missing


## 3.3 Merge Brent and WTI by date
# ----------------------------------------------------------------------------

oil <- brent %>%
  inner_join(wti, by = "date")  # Merge on the 'date' column

# ============================================================
# 4. Market Analysis
# ============================================================

## 4.1 Brent-WTI Spread
# ----------------------------------------------------------------------------
oil <- oil %>%
  mutate(
    brent_wti_spread = brent - wti
  )

## 4.2 Returns
# ----------------------------------------------------------------------------
oil <- oil %>%
  arrange(date) %>%
  mutate(
    brent_return = brent / lag(brent) - 1,
    wti_return = wti / lag(wti) - 1,
    spread_change = brent_wti_spread -
      lag(brent_wti_spread)
  )

oil <- oil %>%
  filter(!is.na(brent_return),
         !is.na(wti_return))

## 4.4 Figures
# ----------------------------------------------------------------------------
p_brent <- ggplot(oil, aes(x = date, y = brent)) +
  geom_line() +
  labs(
    title = "Brent Crude Oil Price",
    x = "Date",
    y = "USD/barrel"
  ) +
  theme_minimal()

p_brent

ggsave(
  "figures/brent_price.png",
  p_brent,
  width = 10,
  height = 6,
  dpi = 300
)

p_spread <- ggplot(oil, aes(x = date, y = brent_wti_spread)) +
  geom_line() +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Brent-WTI Price Spread",
    x = "Date",
    y = "USD/barrel"
  ) +
  theme_minimal()

p_spread

ggsave(
  "figures/brent_wti_spread.png",
  p_spread,
  width = 10,
  height = 6,
  dpi = 300
)

# ============================================================
# 5. Position & P&L
# ============================================================
#Position size
#Daily P&L
#Cumulative P&L
## 5.1 Position size
# ----------------------------------------------------------------------------
position_brent <- 100000

## 5.2 Daily P&L
# ----------------------------------------------------------------------------
oil <- oil %>%
  mutate(
    brent_price_change = brent - lag(brent),
    brent_pnl = position_brent * brent_price_change
  )

p_daily_pnl <- ggplot(
  oil %>% filter(!is.na(brent_pnl)),
  aes(x = date, y = brent_pnl)
) +
  geom_line() +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Daily P&L — 100,000 bbl Brent Long Position",
    x = "Date",
    y = "Daily P&L (USD)"
  ) +
  scale_y_continuous(labels = dollar) +
  theme_minimal()

p_daily_pnl

ggsave(
  "figures/daily_pnl.png",
  p_daily_pnl,
  width = 10,
  height = 6,
  dpi = 300
)

## 5.3 Cumulative P&L
# ----------------------------------------------------------------------------
oil <- oil %>%
  mutate(
    cumulative_pnl = cumsum(
      replace_na(brent_pnl, 0)
    )
  )

p_cumulative_pnl <- ggplot(oil, aes(x = date, y = cumulative_pnl)) +
  geom_line() +
  labs(
    title = "Cumulative P&L — Brent Long Position",
    x = "Date",
    y = "Cumulative P&L (USD)"
  ) +
  scale_y_continuous(labels = dollar) +
  theme_minimal()

p_cumulative_pnl

ggsave(
  "figures/cumulative_pnl.png",
  p_cumulative_pnl,
  width = 10,
  height = 6,
  dpi = 300
)

# ============================================================
# 6. Hedging Analysis
# ============================================================

## 6.1 Brent - WTI Correlation
# ----------------------------------------------------------------------------
cor(
  oil$brent_return,
  oil$wti_return,
  use = "complete.obs"
)

## 6.2 Brent - WTI Rolling Correlation
# ----------------------------------------------------------------------------
install.packages("zoo")
library(zoo)
library(tidyverse)
oil <- oil %>%
  mutate(
    rolling_corr = rollapply(
      data = cbind(brent_return, wti_return),
      width = 60,
      FUN = function(x) cor(x[,1], x[,2], use = "complete.obs"),
      by.column = FALSE,
      fill = NA
    )
  )

p_rolling_corr <- ggplot(
  oil,
  aes(x = date, y = rolling_corr)
) +
  geom_line() +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "60-Day Rolling Brent-WTI Return Correlation",
    x = "Date",
    y = "Correlation"
  ) +
  theme_minimal()

p_rolling_corr

ggsave(
  "figures/rolling_correlation.png",
  p_rolling_corr,
  width = 10,
  height = 6,
  dpi = 300
)

## 6.3 Minimum variance hedge ratio
# ----------------------------------------------------------------------------
hedge_model <- lm(
  brent_return ~ wti_return,
  data = oil
)

summary(hedge_model)

hedge_ratio <- coef(hedge_model)[["wti_return"]]

## 6.4 Hedge position  #Long Brent + Short WTI
# ----------------------------------------------------------------------------
oil <- oil %>%
  mutate(
    hedged_return =
      brent_return -
      hedge_ratio * wti_return
  )

## 6.5 Hedged vs Unhedged volatility
# ----------------------------------------------------------------------------
unhedged_vol <- sd(
  oil$brent_return,
  na.rm = TRUE
)

hedged_vol <- sd(
  oil$hedged_return,
  na.rm = TRUE
)

unhedged_vol
hedged_vol

vol_reduction <- 
  1 - hedged_vol / unhedged_vol

vol_reduction

wti_position <- position_brent * hedge_ratio

oil <- oil %>%
  mutate(
    wti_price_change = wti - lag(wti),
    
    wti_pnl =
      -wti_position * wti_price_change,
    
    hedged_pnl =
      brent_pnl + wti_pnl
  )

#png
library(scales)
p_hedge <- ggplot(
  oil %>%
    select(date, brent_pnl, hedged_pnl) %>%
    pivot_longer(
      cols = c(brent_pnl, hedged_pnl),
      names_to = "position",
      values_to = "pnl"
    ),
  aes(x = date, y = pnl, linetype = position, color = position)
) +
  geom_line() +
  #scale_linetype_manual(
    #values = c("hedged_pnl" = "solid", "brent_pnl" = "dashed")  
  #) +
  scale_color_manual(
    values = c(
      "brent_pnl" = "#F4A261",   # 浅蓝色（半透明感）
      "hedged_pnl" = "#2A4D69"   # 深蓝色（接近海军蓝）
    )
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "Unhedged vs Hedged Daily P&L",
    x = "Date",
    y = "Daily P&L (USD)",
    linetype = "Position",
    color = "Position"
  ) +
  scale_y_continuous(labels = dollar) +
  theme_minimal()

p_hedge

ggsave(
  "figures/hedged_vs_unhedged.png",
  p_hedge,
  width = 10,
  height = 6,
  dpi = 300
)

# ============================================================
# 7. VaR & Stress Testing
# ============================================================

## 7.1 VaR
# ----------------------------------------------------------------------------

pnl_data <- oil %>%
  filter(!is.na(brent_pnl),
         !is.na(hedged_pnl))

#unhedged 95% VaR
VaR_95_unhedged <- 
  -quantile(
    pnl_data$brent_pnl,
    probs = 0.05
  )
#hedged 95% VaR
VaR_95_hedged <- 
  -quantile(
    pnl_data$hedged_pnl,
    probs = 0.05
  )

VaR_reduction <-
  1 -
  VaR_95_hedged /
  VaR_95_unhedged

VaR_reduction

## 7.2 Stress Testing
# ----------------------------------------------------------------------------
###Stress Scenario
stress <- tibble(
  scenario = c(
    "Brent -10%",
    "Brent -20%",
    "WTI -10%",
    "Brent -20% / WTI -15%"
  ),
  
  brent_change = c(
    -0.10,
    -0.20,
    0,
    -0.20
  ),
  
  wti_change = c(
    0,
    0,
    -0.10,
    -0.15
  )
)
###Unhedged/Hedged P&L
current_brent <- tail(oil$brent, 1)
current_wti <- tail(oil$wti, 1)

stress <- stress %>%
  mutate(
    brent_pnl =
      position_brent *
      current_brent *
      brent_change,
    
    wti_pnl =
      -wti_position *
      current_wti *
      wti_change,
    
    hedged_pnl =
      brent_pnl + wti_pnl
  )

stress

write_csv(
  stress,
  "results/stress.csv"
)

# ============================================================
# 8. EWMA Volatility
# ============================================================

lambda <- 0.94

returns <- na.omit(oil$brent_return)

ewma_var <- numeric(length(returns))

ewma_var[1] <- var(returns)

for(i in 2:length(returns)) {
  
  ewma_var[i] <-
    lambda * ewma_var[i-1] +
    (1-lambda) * returns[i-1]^2
  
}

ewma_vol <- sqrt(ewma_var)

ewma_data <- tibble(
  date = oil$date[!is.na(oil$brent_return)],
  ewma_vol = ewma_vol
)

p_ewma <- ggplot(
  ewma_data,
  aes(x = date, y = ewma_vol)
) +
  geom_line() +
  labs(
    title = "Brent EWMA Volatility",
    x = "Date",
    y = "Volatility"
  ) +
  scale_y_continuous(
    labels = percent
  ) +
  theme_minimal()

p_ewma

ggsave(
  "figures/ewma_volatility.png",
  p_ewma,
  width = 10,
  height = 6,
  dpi = 300
)

# ============================================================
# 9. Machine Learning
# ============================================================
# Feature engineering
# Time-series split
# Random Forest
# Test prediction
# RMSE
# Directional accuracy
# Feature importance
## 9.1 Install Packages
# ----------------------------------------------------------------------------
install.packages("randomForest")
library(randomForest)

## 9.2 Build ML dataset
# ----------------------------------------------------------------------------
ml_data <- oil %>%
  arrange(date) %>%
  mutate(
    brent_lag1 = lag(brent_return, 1), #yesterday's Brent return
    brent_lag2 = lag(brent_return, 2),
    brent_lag5 = lag(brent_return, 5),
    
    wti_lag1 = lag(wti_return, 1),
    wti_lag2 = lag(wti_return, 2),
    
    spread_change_lag1 = lag(spread_change, 1),
    
    volatility_20d = rollapply(
      brent_return,
      width = 20,
      FUN = sd,
      fill = NA,
      align = "right"
    ),
    
    target = lead(brent_return, 1) #tomorrow's Brent return
  ) %>%
  drop_na()

#check data
head(ml_data)

## 9.3 Time-series split
# ----------------------------------------------------------------------------
#前80% training
#后20% test
split_point <- floor(0.8 * nrow(ml_data))

train_data <- ml_data[1:split_point, ]

test_data <- ml_data[
  (split_point + 1):nrow(ml_data),
]

#check
min(train_data$date)
max(train_data$date)

min(test_data$date)
max(test_data$date)

## 9.4 Defind features
# ----------------------------------------------------------------------------
features <- c(
  "brent_lag1",
  "brent_lag2",
  "brent_lag5",
  "wti_lag1",
  "wti_lag2",
  "spread_change_lag1",
  "volatility_20d"
)

## 9.5 Build Random Forest
# ----------------------------------------------------------------------------
set.seed(123)

rf_model <- randomForest(
  x = train_data[, features],
  y = train_data$target,
  ntree = 500,
  importance = TRUE
)
ntree = 500

print(rf_model)

## 9.6 Forest Test set
# ----------------------------------------------------------------------------
predictions <- predict(
  rf_model,
  newdata = test_data[, features]
)

test_data <- test_data %>%
  mutate(
    predicted_return = predictions
  )

## 9.7 Calculate RMSE
# ----------------------------------------------------------------------------
rf_rmse <- sqrt(
  mean(
    (test_data$target -
       test_data$predicted_return)^2
  )
)

rf_rmse  #Out-of-sample RMSE

## 9.8 Benchmark RMSE
# ----------------------------------------------------------------------------
#Naive Benchmark
#tomorrow's return = 0
benchmark_rmse <- sqrt(
  mean(
    test_data$target^2
  )
)

rf_rmse #compare
benchmark_rmse

## 9.9 Directional Accuracy
# ----------------------------------------------------------------------------
direction_accuracy <- mean(
  sign(test_data$target) ==
    sign(test_data$predicted_return)
)

direction_accuracy
percent(direction_accuracy)

## 9.10 Feature Importance
# ----------------------------------------------------------------------------
importance_df <- as.data.frame(
  importance(rf_model)
)

importance_df$Feature <- rownames(
  importance_df
)

importance_df

importance_df <- importance_df %>%
  arrange(desc(`%IncMSE`))

p_importance <- ggplot(
  importance_df,
  aes(
    x = reorder(Feature, `%IncMSE`),
    y = `%IncMSE`
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Random Forest Feature Importance",
    x = "Feature",
    y = "% Increase in MSE"
  ) +
  theme_minimal()

p_importance

ggsave(
  "figures/random_forest_feature_importance.png",
  p_importance,
  width = 10,
  height = 6,
  dpi = 300
)

## 9.11 ML Results
# ----------------------------------------------------------------------------
ml_results <- tibble(
  Model = c(
    "Naive Benchmark",
    "Random Forest"
  ),
  RMSE = c(
    benchmark_rmse,
    rf_rmse
  ),
  Directional_Accuracy = c(
    NA,
    direction_accuracy
  )
)

ml_results

write_csv(
  ml_results,
  "results/ml_model_comparison.csv"
)

# ============================================================
# 10. Export Results (risk dashboard)
# ============================================================

risk_summary <- tibble(
  Metric = c(
    "Brent Position",
    "WTI Hedge Position",
    "Unhedged Daily Volatility",
    "Hedged Daily Volatility",
    "Unhedged 95% VaR",
    "Hedged 95% VaR",
    "VaR Reduction"
  ),
  
  Value = c(
    position_brent,
    wti_position,
    unhedged_vol,
    hedged_vol,
    VaR_95_unhedged,
    VaR_95_hedged,
    VaR_reduction
  )
)

risk_summary

write_csv(
  risk_summary,
  "results/risk_summary.csv"
)

write_csv(
  ml_results,
  "results/ml_model_comparison.csv"
)

#============================================================
# Shiny data
#============================================================
shiny_data <- list(
  oil = oil,
  risk_summary = risk_summary,
  stress = stress,
  ewma_data = ewma_data,
  ml_results = ml_results,
  importance_df = importance_df,
  rf_model = rf_model,
  hedge_ratio = hedge_ratio,
  VaR_95_unhedged = VaR_95_unhedged,
  VaR_95_hedged = VaR_95_hedged,
  VaR_reduction = VaR_reduction,
  unhedged_vol = unhedged_vol,
  hedged_vol = hedged_vol,
  vol_reduction = vol_reduction
)

saveRDS(
  shiny_data,
  file = "Brent_Market_Risk_Dashboard/results/shiny_data.rds"
)
