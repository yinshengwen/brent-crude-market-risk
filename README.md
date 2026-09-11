# Brent Crude Market & Risk Analytics

A practical commodity market and risk analytics project using **R**, focused on Brent crude oil and its relationship with WTI.

The project was designed to demonstrate how market data can be translated into **position-level P&L, hedging and risk measures** relevant to commodity trading and risk analysis.

## Project Report

[**View the HTML Project Report**](https://yinshengwen.github.io/brent-crude-market-risk/)

The report presents the analysis in a business-oriented format, including market analysis, P&L, hedging, VaR, stress testing, EWMA volatility and model evaluation.

## Interactive Dashboard

**[Open the Shiny Dashboard](https://yinshengwen.shinyapps.io/Brent_Market_Risk_Dashboard/)**

The Shiny dashboard provides an interactive view of the main market, P&L, risk and machine-learning results.

> The HTML report is the primary project presentation. The Shiny dashboard is an additional interactive demonstration.

## Key Results

| Metric | Result |
|---|---:|
| Illustrative Brent position | 100,000 bbl |
| WTI hedge position | 28,794 bbl |
| Brent–WTI return correlation | 0.482 |
| Regression-based hedge ratio | 0.288 |
| Unhedged daily volatility | 2.54% |
| Hedged daily volatility | 2.23% |
| Unhedged 95% historical VaR | $201K |
| Hedged 95% historical VaR | $166.7K |
| VaR reduction | **17.1%** |

## Project Workflow

```text
Brent & WTI market data
        ↓
Data cleaning
        ↓
Market relationship
        ↓
Position P&L
        ↓
Brent–WTI hedging
        ↓
Historical VaR
        ↓
Stress testing
        ↓
EWMA volatility
        ↓
Random Forest evaluation
```

## Analysis

### 1. Market Analysis

- Brent crude oil price
- Brent–WTI price spread
- Daily returns
- 60-day rolling correlation

### 2. P&L Analysis

An illustrative **100,000 bbl long Brent position** is used to calculate:

- Daily P&L
- Cumulative P&L

### 3. Hedging

A regression of Brent returns on WTI returns is used to obtain an **illustrative regression-based hedge ratio**.

The resulting hedge is a short WTI position against the long Brent position.

### 4. Risk Analysis

The project calculates:

- Historical 95% one-day VaR
- Unhedged vs. hedged volatility
- VaR reduction
- Scenario-based stress testing

### 5. EWMA Volatility

An EWMA volatility measure with `lambda = 0.94` is used to monitor changes in recent Brent volatility.

### 6. Machine Learning

A Random Forest model tests whether lagged market variables and recent volatility can improve prediction of the next-day Brent return.

The model is evaluated using a chronological 80/20 train-test split.

The Random Forest **did not outperform the naive zero-return benchmark in out-of-sample RMSE**, so it is treated as a secondary modeling exercise rather than a trading signal.

## Technical Skills

**Programming & Tools:** R, Excel, MATLAB, Stata, SQL

**Econometrics & Modeling:** Regression, Time Series Analysis, Forecasting, ARMA, GARCH/EGARCH, Factor Models, PCA

**Commodity & Risk Analysis:** Commodity Pricing, P&L Analysis, Hedging, VaR, Stress Testing, EWMA Volatility

## Data

The project uses publicly available daily crude-oil price series from the Federal Reserve Bank of St. Louis FRED:

- Brent: `DCOILBRENTEU`
- WTI: `DCOILWTICO`

The analysis script retrieves the series directly from FRED.

## Repository Structure

```text
brent-crude-market-risk/
│
├── README.md
├── Brent_Crude_Market_Risk_Report.Rmd
├── Brent_Crude_Market_Risk_Report.html
│
├── R/
│   ├── brent_market_risk.R
│   └── analysis2.R
│
├── figures/
│   ├── brent_price.png
│   ├── brent_wti_spread.png
│   ├── daily_pnl.png
│   ├── cumulative_pnl.png
│   ├── hedged_vs_unhedged.png
│   ├── rolling_correlation.png
│   ├── ewma_volatility.png
│   └── random_forest_feature_importance.png
│
├── results/
│   ├── risk_summary.csv
│   ├── stress.csv
│   └── ml_model_comparison.csv
│
└── Brent_Market_Risk_Dashboard/
    └── app.R
```

## Reproducing the Report

The report is intentionally separated from the heavier analysis workflow.

The analysis scripts perform the calculations and export the key results to `results/` and figures to `figures/`.

The R Markdown report then reads those pre-computed results, so **knitting the report does not rerun the Random Forest or redownload the full FRED dataset**.

### Required R packages

```r
install.packages(c(
  "rmarkdown",
  "knitr",
  "tidyverse",
  "scales"
))
```

### Render the HTML report

Run:

```r
rmarkdown::render(
  "Brent_Crude_Market_Risk_Report.Rmd",
  output_file = "Brent_Crude_Market_Risk_Report.html"
)
```

The generated HTML file can then be opened locally in a browser or published through GitHub Pages.

## GitHub Pages

To make the HTML report publicly accessible:

1. Push the repository to GitHub.
2. Open **Settings → Pages** in the repository.
3. Under **Build and deployment**, choose **Deploy from a branch**.
4. Select the `main` branch and `/ (root)`.
5. Save.
6. GitHub will provide a public Pages URL.

The report can then be linked from a resume as:

```text
Project Report
```

while the GitHub repository remains the source-code and project-evidence link.

## Disclaimer

This is an illustrative educational portfolio project using publicly available market data. The assumed position and hedge are hypothetical and do not represent actual trades or investment advice.
