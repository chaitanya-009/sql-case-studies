# E-commerce Sales Analysis

## Problem statement

You are provided with a dataset of transactions/users/orders. Use SQL to answer business questions.

1.Monthly Portfolio Analysis
For each month, calculate the number of loans disbursed, total loan amount, average credit score, and default rate. Rank the months by total disbursement volume.

2.Risk-Based Segmentation
Categorize customers into credit score buckets (300–579, 580–669, 670–739, 740–799, 800–900). For each bucket, compute the average loan amount, average EMI, and the proportion of loans that defaulted.

3.Customer Exposure Summary
For every customer, compute their total outstanding exposure (sum of loan_amount), their earliest and latest loan disbursement dates, and count how many of their loans are currently in default.

4.High-Risk Income-to-EMI Analysis
Identify loans where EMI > 40% of monthly income (income-to-EMI stress). For these high-risk cases, return customer_id, loan_id, credit_score, loan_purpose, and whether the loan has defaulted.

5.Loan Purpose Profitability
For each loan purpose, calculate the average interest rate, average EMI, median loan amount, and default rate. Rank the loan purposes by default rate descending.

6.Time-to-Default Study
For loans that defaulted, calculate the number of days between disbursement_date and today. Find the average time-to-default by loan_purpose.

7.Customer Loan Progression
For each customer, list all their loans sorted by disbursement_date along with a running total of their cumulative sanctioned amount across loan history.