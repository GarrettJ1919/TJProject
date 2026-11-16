# Measuring the Impact of Tommy John Surgery on MLB Pitching Performance

**Authors:** Garrett Jones and Sam Herdlick  
**Institution:** Creighton University  
**Course:** Data Science Capstone

---

## Project Overview

This project investigates how Tommy John surgery relates to changes in MLB pitching performance. We compare pitching statistics before and after surgery and explore whether pre-surgery information can help predict post-surgery performance.

Our primary focus is on **ERA, FIP, K-BB%, and innings pitched (IP)**.

## Data Collection and Cleaning

We collected information on MLB pitchers who underwent Tommy John surgery between **2018 and 2023**.

Using **Python**, we collected and organized pitching statistics from Baseball-Reference.

Our data processing included:

- Collecting statistics from up to **three seasons before and after surgery**.
- Excluding the surgery year from the analysis.
- Matching pitchers across multiple seasons.
- Handling missing or incomplete records.
- Combining pitching statistics into before-and-after averages.
- Organizing the final data in Microsoft Excel.

## Statistical Analysis

We compared pitching performance before and after Tommy John surgery using an **innings-weighted analysis**.

Each pitcher's performance change was calculated as:

**Change = After Surgery - Before Surgery**

We weighted each pitcher's change using the smaller of their pre- and post-surgery innings totals.

### Innings-Weighted Results

| Statistic | Weighted Change | Interpretation |
|-----------|-----------------|----------------|
| ERA | +0.319 | Worse performance |
| FIP | +0.374 | Worse performance |
| K-BB% | -3.29 percentage points | Worse performance |

**Main Finding:** Our innings-weighted analysis showed worse average pitching performance after surgery across all three statistics.

These results describe changes in our sample and do not establish that surgery caused the changes.

## Predictive Modeling

Using **RStudio**, we developed machine learning models to predict post-surgery pitching performance based on pre-surgery information.

### Models Compared

1. **Model 1: Multiple Linear Regression (MLR)**
2. **Model 2: Random Forest Regression**
3. **Model 3: Ridge Regression**

### Model Inputs

We used five pre-surgery predictors:

- Age
- ERA Before
- FIP Before
- K-BB% Before
- Innings Pitched Before

### Model Outputs

Our models predicted four post-surgery statistics:

- ERA After
- FIP After
- K-BB% After
- Innings Pitched After

### Training and Testing

Our final modeling dataset contained **127 eligible MLB pitchers**.

- **Training Dataset:** 101 pitchers (approximately 80%)
- **Testing Dataset:** 26 pitchers (approximately 20%)

We evaluated model performance using:

- **MAE:** Mean Absolute Error
- **RMSE:** Root Mean Squared Error
- **R²:** R-Squared

## Model Evaluation Results

We compared the three models using their R² values on the testing dataset.

| Predicted Statistic | Linear Regression | Random Forest | Ridge Regression |
|---------------------|-------------------|---------------|------------------|
| ERA | -0.057 | -0.104 | -0.050 |
| FIP | -0.044 | -0.140 | -0.069 |
| K-BB% | -0.127 | -0.200 | -0.022 |
| Innings Pitched | **0.551** | 0.517 | 0.278 |

### Final Selected Model

**Model 1: Multiple Linear Regression (MLR)**

Multiple Linear Regression was selected as our final model because it performed best at predicting post-surgery innings pitched.

**Key Results:**

- **R²:** 0.551
- **MAE:** 49.8 innings
- **RMSE:** 67.6 innings

Our results suggest that **post-surgery innings pitched was more predictable than ERA, FIP, or K-BB%** using our available pre-surgery information.

All three models produced negative test-set R² values when predicting ERA, FIP, and K-BB%.

## Project Limitations

Our analysis had several limitations:

- The modeling dataset contained only 127 eligible pitchers.
- Some pitchers had very few innings after surgery, resulting in extreme performance statistics.
- Our models only included pitchers with recorded post-surgery playing time.
- Individual recovery and performance may be influenced by factors not included in our dataset.
- Our results do not establish a causal relationship between surgery and performance changes.

## Technologies Used

| Technology | Purpose |
|------------|---------|
| Python | Data collection and cleaning |
| Microsoft Excel | Statistical calculations and weighted comparisons |
| R / RStudio | Predictive modeling and visualization |
| GitHub | Version control and project organization |
| Overleaf / LaTeX | Final presentation |

## Project Files

- **`pull_pitcher_stats.py`** — Python data collection and cleaning script.
- **`pull_pitcher_stats_updated.py`** — Updated Python data processing script.
- **`tommy_john_model.R`** — RStudio predictive modeling code.
- **`TJ_Surgery_Innings_Weighted_Analysis.xlsx`** — Before-and-after pitching analysis.
- **`Tommy John Surgery List (@MLBPlayerAnalys).xlsx`** — Original Tommy John surgery dataset.

## Conclusion

Our project examined changes in MLB pitching performance following Tommy John surgery using statistical analysis and predictive modeling.

The innings-weighted analysis found average declines in performance across ERA, FIP, and K-BB%.

Our predictive modeling results showed that **Multiple Linear Regression performed best at predicting post-surgery innings pitched**, achieving an R² of approximately 0.55.

However, predicting ERA, FIP, and K-BB% remained difficult.

Overall, this project demonstrates both the usefulness and limitations of applying data science and machine learning to professional baseball performance data.

This project highlights both the potential and limitations of using historical baseball statistics to understand pitching performance following surgery.
