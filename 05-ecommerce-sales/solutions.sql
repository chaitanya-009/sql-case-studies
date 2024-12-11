-- solutions.sql

-- Q1
SELECT
  date_trunc('month', disbursement_date)              AS month,
  COUNT(*)                                            AS loans_issued,
  SUM(loan_amount)                                    AS total_disbursed,
  ROUND(AVG(credit_score)::numeric, 2)                AS avg_credit_score,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS default_rate_pct,
  RANK() OVER (ORDER BY SUM(loan_amount) DESC)        AS disbursement_rank
FROM loans
GROUP BY 1
ORDER BY disbursement_rank;

-- Q2
SELECT
  credit_band,
  ROUND(AVG(loan_amount)::numeric, 2)                  AS avg_loan_amount,
  ROUND(AVG(emi_amount)::numeric, 2)                   AS avg_emi,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS default_rate_pct
FROM (
  SELECT *,
    CASE
      WHEN credit_score BETWEEN 300 AND 579 THEN '300-579'
      WHEN credit_score BETWEEN 580 AND 669 THEN '580-669'
      WHEN credit_score BETWEEN 670 AND 739 THEN '670-739'
      WHEN credit_score BETWEEN 740 AND 799 THEN '740-799'
      WHEN credit_score BETWEEN 800 AND 900 THEN '800-900'
      ELSE 'unknown'
    END AS credit_band
  FROM loans
) t
GROUP BY credit_band
ORDER BY credit_band;

-- Q3
SELECT
  customer_id,
  SUM(loan_amount)                                    AS total_exposure,
  MIN(disbursement_date)                              AS first_disbursement,
  MAX(disbursement_date)                              AS last_disbursement,
  SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) AS defaults_count
FROM loans
GROUP BY customer_id
ORDER BY total_exposure DESC;

-- Q4
SELECT
  loan_id,
  customer_id,
  loan_amount,
  monthly_income,
  emi_amount,
  credit_score,
  loan_purpose,
  loan_status,
  ROUND((emi_amount::numeric / NULLIF(monthly_income,0))::numeric, 3) AS emi_to_income_ratio
FROM loans
WHERE emi_amount > 0.4 * NULLIF(monthly_income,0)
ORDER BY emi_to_income_ratio DESC;

-- Q5
SELECT
  loan_purpose,
  ROUND(AVG(interest_rate)::numeric, 2)                AS avg_interest_rate,
  ROUND(AVG(emi_amount)::numeric, 2)                   AS avg_emi,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY loan_amount) AS median_loan_amount,
  ROUND(100.0 * SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS default_rate_pct
FROM loans
GROUP BY loan_purpose
ORDER BY default_rate_pct DESC, avg_loan_amount DESC;

-- Q6
SELECT
  loan_purpose,
  COUNT(*)                                           AS defaults_count,
  ROUND(AVG((current_date - disbursement_date)::int)::numeric, 1) AS avg_days_to_default
FROM loans
WHERE loan_status = 'Default'
GROUP BY loan_purpose
ORDER BY avg_days_to_default DESC;

-- Q7
SELECT
  customer_id,
  loan_id,
  disbursement_date,
  loan_amount,
  emi_amount,
  SUM(loan_amount) OVER (PARTITION BY customer_id ORDER BY disbursement_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_exposure
FROM loans
ORDER BY customer_id, disbursement_date;
