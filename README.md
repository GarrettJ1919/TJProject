Measuring the Impact of Tommy John Surgery on MLB Pitching Performance

Authors: Garrett Jones and Sam Herdlick
Institution: Creighton University
Course: Data Science Capstone

Project Overview

This project investigates how MLB pitchers' performance changes before and after Tommy John surgery. We also explore whether pre-surgery statistics can help predict post-surgery performance.

Data Collection and Cleaning

We analyzed MLB pitchers who underwent Tommy John surgery between 2018 and 2023.

Using Python, we collected and organized pitching statistics from Baseball-Reference, examining up to three seasons before and three seasons after surgery while excluding the surgery year.

Our primary statistics were ERA, FIP, K-BB%, and innings pitched.

Statistical Analysis

We compared pitching performance before and after surgery using innings-weighted differences.

Our results showed:

Statistic

Weighted Change

ERA

+0.319

FIP

+0.374

K-BB%

-3.29 percentage points

These results indicate worse average performance after surgery in our analyzed sample, although they do not establish that surgery caused the changes.

Predictive Modeling

Using RStudio, we trained and evaluated three regression algorithms:

Multiple Linear Regression

Random Forest Regression

Ridge Regression

We used five predictors: Age, ERA Before, FIP Before, K-BB% Before, and Innings Pitched Before.

The modeling dataset contained 127 eligible pitchers, split into 101 training observations and 26 testing observations.

Model Results

Multiple Linear Regression was selected as our final model.

Its strongest result was predicting post-surgery innings pitched, with a test-set R² of 0.551 and MAE of approximately 49.8 innings.

Predicting ERA, FIP, and K-BB% was more difficult, with negative test-set R² values across all three algorithms.

Tools Used

Python — data collection and cleaning

Microsoft Excel — before-and-after statistical analysis

RStudio — predictive modeling and visualization

GitHub — version control and project organization

Limitations

Our analysis was limited by the available sample size, differences in pitchers' post-surgery playing time, and extreme statistics among pitchers with very few innings.

Our predictive models also only included pitchers with recorded post-surgery playing time.

Conclusion

Our analysis found an average decline in pitching performance after Tommy John surgery across ERA, FIP, and K-BB%. Predictive modeling showed that innings pitched was more predictable than the other performance statistics, although prediction accuracy remained limited.

This project highlights both the potential and limitations of using historical baseball statistics to understand pitching performance following surgery.
