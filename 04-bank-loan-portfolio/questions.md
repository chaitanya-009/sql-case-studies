# Bank Loan Portfolio Analysis


1.For each month (by disbursement_date), compute the number of loans issued, total loan_amount disbursed, average interest_rate and default rate (percent of loans with loan_status = 'Default').

2.List the top 10 customers by total exposure (SUM(loan_amount)), include customer_id, total_exposure, number_of_loans, average_credit_score and rank them by total_exposure.

3.Create credit_score bands (300-579, 580-669, 670-739, 740-799, 800-900). For each band and loan_purpose, calculate count of loans, average emi_amount, average monthly_income, and default rate.

4.Calculate loan-to-income ratio defined as loan_amount / (monthly_income * 12). Return all loans where loan_to_income_ratio > 1 and credit_score < 600, showing loan_id, customer_id, loan_amount, monthly_income, credit_score, loan_to_income_ratio.

5.For each customer, show their most recent loan (latest disbursement_date) along with that loan's emi_amount, loan_amount and a running total of that customer’s cumulative exposure (SUM(loan_amount) over partition by customer ordered by disbursement_date).

6.Compute EMI coverage ratio = monthly_income / emi_amount. For each loan_purpose, produce the distribution: average, median, and percentage of loans with coverage < 1.5 and coverage < 1.0.

7.Assume LGD = 40% for all loans. Using historical default rates by credit_score band (as in question 3), estimate expected loss per band = default_rate * LGD * average_loan_amount. Produce a table showing credit_score_band, default_rate, average_loan_amount, and estimated_expected_loss.