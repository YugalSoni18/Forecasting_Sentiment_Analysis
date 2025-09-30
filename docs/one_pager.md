# Forecasting & Sentiment Analysis — One-Pager
**Author:** Yugal Soni · MSc Business Analytics & Decision Science, University of Leeds

## Objective
Blend **macroeconomic forecasting** and **customer sentiment analysis** to show how analytics drives better decisions:
1) Forecast **US Personal Consumption Expenditure (PCE)** to support planning and reporting.  
2) Analyse **2,000 hotel reviews** to identify drivers of satisfaction and pain points.

## Data
- **PCE.csv** — Monthly US PCE time series (1959–2025).  
- **HotelsData.csv** — Hotel reviews with text and ratings (cleaned for analysis).

## Methods
**Forecasting**
- Models: **Naïve**, **ETS**, **ARIMA** (`auto.arima()`), with train/test validation (2024 holdout).
- Diagnostics: ACF/PACF, residual checks (Ljung–Box), prediction intervals.
- Metrics: **MAPE**, **MAE**, **RMSE**.

**Sentiment NLP**
- Tokenisation, stopword removal, bigrams, wordcloud.
- Lexicons: **BING** & **AFINN**; aggregation by theme/term frequency.

## Results (Headline)
- **ARIMA** performed best with **MAPE < 0.2%**; **ETS** close; **Naïve** worst baseline.  
- **2025 PCE** shows continued growth with clear 80%/95% intervals for scenario planning (~**5% YoY** indicative).  
- Reviews are **predominantly positive**; strongest positive drivers: **clean**, **friendly**, **location**, **helpful**, **modern**.  
- Negative terms cluster around **service issues** and **bathroom/heat** complaints.

## Recommendations
- **Finance/Strategy:** Use ARIMA forecast midpoint for budget planning and stress‑test with lower/upper interval bands.  
- **Hospitality Ops:** Prioritise **cleanliness and staff training**; highlight **location** advantages in marketing copy; monitor recurring issues (e.g., temperature/bathroom) via monthly sentiment dashboards.

## How to Reproduce
```r
# install.packages(c("forecast","tseries","ggplot2","tidyverse","tidytext","textdata","tm","wordcloud","zoo"))
# Run:
#   1) code/forecasting_analysis.R
#   2) code/nlp_sentiment.R
```
Outputs are saved to **/outputs** and referenced in the README.

## Repo Map
- `code/` — Full R scripts (forecasting + NLP)  
- `data/` — CSVs used by the scripts  
- `outputs/` — Visuals used in README (9 figures)  
- `docs/` — This one‑pager only  
