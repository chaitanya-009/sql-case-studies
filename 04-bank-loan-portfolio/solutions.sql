-- solutions.sql

-- Q1
SELECT
  date_trunc('month', disbursement_date)             AS month,
  COUNT(*)                                           AS loans_issued,
  SUM(loan_amount)                                   AS total_disbursed,
  ROUND(AVG(interest_rate)::numeric, 2)              AS avg_interest_rate,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS default_rate_pct
FROM loans
GROUP BY 1
ORDER BY 1;

-- Q2
SELECT
  customer_id,
  SUM(loan_amount)            AS total_exposure,
  COUNT(*)                    AS number_of_loans,
  ROUND(AVG(credit_score)::numeric, 1) AS average_credit_score,
  RANK() OVER (ORDER BY SUM(loan_amount) DESC) AS exposure_rank
FROM loans
GROUP BY customer_id
ORDER BY total_exposure DESC
LIMIT 10;

-- Q3
SELECT
  credit_band,
  loan_purpose,
  COUNT(*)                                     AS loan_count,
  ROUND(AVG(emi_amount)::numeric, 2)           AS avg_emi,
  ROUND(AVG(monthly_income)::numeric, 2)       AS avg_monthly_income,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS default_rate_pct
FROM (
  SELECT *,
    CASE
      WHEN credit_score BETWEEN 300 AND 579 THEN '300-579'
      WHEN credit_score BETWEEN 580 AND 669 THEN '580-669'
      WHEN credit_score BETWEEN 670 AND 739 THEN '670-739'
      WHEN credit_score BETWEEN 740 AND 799 THEN '740-799'
      WHEN credit_score BETWEEN 800 AND 900 THEN '800-900'
      ELSE 'unknown' END AS credit_band
  FROM loans
) t
GROUP BY credit_band, loan_purpose
ORDER BY credit_band, loan_purpose;

-- Q4
SELECT
  loan_id,
  customer_id,
  loan_amount,
  monthly_income,
  credit_score,
  ROUND((loan_amount::numeric / NULLIF(monthly_income * 12,0))::numeric, 3) AS loan_to_income_ratio
FROM loans
WHERE (loan_amount::numeric / NULLIF(monthly_income * 12,0)) > 1
  AND credit_score < 600
ORDER BY loan_to_income_ratio DESC;

-- Q5
WITH ordered AS (
  SELECT
    customer_id,
    loan_id,
    disbursement_date,
    emi_amount,
    loan_amount,
    SUM(loan_amount) OVER (PARTITION BY customer_id ORDER BY disbursement_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_exposure,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY disbursement_date DESC, loan_id DESC) AS rn
  FROM loans
)
SELECT
  customer_id,
  loan_id,
  disbursement_date,
  emi_amount,
  loan_amount,
  cumulative_exposure
FROM ordered
WHERE rn = 1
ORDER BY customer_id;

-- Q6
WITH cov AS (
  SELECT
    loan_purpose,
    (monthly_income::numeric / NULLIF(emi_amount,0)) AS coverage
  FROM loans
)
SELECT
  loan_purpose,
  ROUND(AVG(coverage)::numeric, 2) AS avg_coverage,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY coverage) AS median_coverage,
  ROUND(100.0 * SUM(CASE WHEN coverage < 1.5 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS pct_below_1_5,
  ROUND(100.0 * SUM(CASE WHEN coverage < 1.0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS pct_below_1_0
FROM cov
GROUP BY loan_purpose
ORDER BY loan_purpose;

-- Q7
WITH bands AS (
  SELECT
    CASE
      WHEN credit_score BETWEEN 300 AND 579 THEN '300-579'
      WHEN credit_score BETWEEN 580 AND 669 THEN '580-669'
      WHEN credit_score BETWEEN 670 AND 739 THEN '670-739'
      WHEN credit_score BETWEEN 740 AND 799 THEN '740-799'
      WHEN credit_score BETWEEN 800 AND 900 THEN '800-900'
      ELSE 'unknown' END AS credit_band,
    loan_amount,
    CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END AS is_default
  FROM loans
),
agg AS (
  SELECT
    credit_band,
    AVG(loan_amount) AS avg_loan_amount,
    SUM(is_default)::numeric / NULLIF(COUNT(*),0) AS default_rate_decimal
  FROM bands
  GROUP BY credit_band
)
SELECT
  credit_band,
  ROUND(default_rate_decimal * 100, 2) AS default_rate_pct,
  ROUND(avg_loan_amount::numeric, 2) AS average_loan_amount,
  ROUND(default_rate_decimal * 0.4 * avg_loan_amount::numeric, 2) AS estimated_expected_loss
FROM agg
ORDER BY credit_band;
