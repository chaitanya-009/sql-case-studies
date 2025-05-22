1. Category-wise Performance Summary

For each product category, calculate:

total revenue

average price

total units sold

average rating
Sort categories by total revenue in descending order.

2. Best & Worst Performing Products

Find the top 10 products by revenue and the bottom 10 by units_sold.
Return product_name, category, revenue, units_sold.

3. High Return-Rate Products

Identify products with return_rate_pct greater than 10% and revenue above the dataset median.
Sort by return_rate_pct descending.

4. Pricing Impact on Ratings

Check whether higher-priced products tend to have higher ratings.
Group products into price bands:

Low: < 1000

Medium: 1000–5000

High: 5001–15000

Premium: >15000

For each band, find the average rating and average return_rate_pct.

5. New vs Old Products Analysis

Classify products based on launch_date:

New (launched in last 1.5 years)

Old (launched earlier)

Compare: average revenue, average rating, average return_rate_pct.