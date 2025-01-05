1. Monthly Churn Rate

Calculate the churn rate for each cohort_month.
Show: cohort_month, total_customers, churned_customers, churn_rate%.

2. Activity vs Churn

Find the relationship between customer activity and churn.
Group customers into buckets based on txn_count:

0–5

6–15

16–30

31+

For each bucket, compute churn_rate%.

3. City-wise Performance

For each city, calculate:

average_txn_count

average_amount

churn_rate
Sort cities by highest churn rate.

4. Recency vs Churn

Calculate the average days_since_last_txn for churned vs non-churned customers.
Also compute the ratio:
avg_days_churned / avg_days_active.

5. Revenue Impact of Churn

Estimate lost revenue by churned customers using:
txn_count * avg_txn_amount

Return total_revenue_lost grouped by city and gender.

6. High-Value Customer Churn

A customer is high-value if:
avg_txn_amount > 2000 AND txn_count > 10.

Find:

total high-value customers

churned among them

churn rate of high-value customers.

7. Cohort Retention Curve

For each cohort_month, classify customers into:

Active (days_since_last_txn ≤ 30)

At-Risk (31–180)

Churned (>180)

Return counts and percentages for all three categories per cohort_month.

8. Churn Probability Indicators

Find statistical signals:
Compute the correlation-like metrics (using SQL aggregations):

avg(txn_count) for churned vs active

avg(avg_txn_amount) for churned vs active

avg(age) for churned vs active
Which variable shows the biggest difference?

9. Survival Analysis (SQL Approximation)

Bucket customers based on cohort age:
months_since_cohort = datediff(month, cohort_month, '2024-01-01')
For each month since acquisition, find:

active customers remaining

churn count

survival_rate%.

10. Customer Segmentation

Create simple customer segments:

“Premium”: txn_count > 20 AND avg_txn_amount > 2500

“Regular”: txn_count BETWEEN 5 AND 20

“Low-Engagement”: txn_count < 5

For each segment, compute churn_rate and avg_days_since_last_txn.