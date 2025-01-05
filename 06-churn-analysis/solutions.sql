-- solutions.sql

-- 1 Monthly churn rate by cohort
SELECT
  cohort_month,
  COUNT(*)                                    AS total_customers,
  SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(100.0 * SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS churn_rate_pct
FROM customers
GROUP BY cohort_month
ORDER BY cohort_month;

-- 2 Activity vs churn by txn_count buckets
SELECT
  CASE
    WHEN txn_count BETWEEN 0 AND 5 THEN '0-5'
    WHEN txn_count BETWEEN 6 AND 15 THEN '6-15'
    WHEN txn_count BETWEEN 16 AND 30 THEN '16-30'
    ELSE '31+'
  END AS txn_bucket,
  COUNT(*) AS customers,
  SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(100.0 * SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS churn_rate_pct
FROM customers
GROUP BY txn_bucket
ORDER BY CASE txn_bucket WHEN '0-5' THEN 1 WHEN '6-15' THEN 2 WHEN '16-30' THEN 3 ELSE 4 END;

-- 3 City-wise performance
SELECT
  city,
  ROUND(AVG(txn_count)::numeric,2)        AS avg_txn_count,
  ROUND(AVG(avg_txn_amount)::numeric,2)   AS avg_amount,
  ROUND(100.0 * SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS churn_rate_pct
FROM customers
GROUP BY city
ORDER BY churn_rate_pct DESC;

-- 4 Recency vs churn
SELECT
  ROUND(AVG(CASE WHEN is_churned = 1 THEN days_since_last_txn END)::numeric,2) AS avg_days_churned,
  ROUND(AVG(CASE WHEN is_churned = 0 THEN days_since_last_txn END)::numeric,2) AS avg_days_active,
  ROUND(
    (AVG(CASE WHEN is_churned = 1 THEN days_since_last_txn END) /
     NULLIF(AVG(CASE WHEN is_churned = 0 THEN days_since_last_txn END),0)
    )::numeric, 2) AS ratio_churned_to_active
FROM customers;

-- 5 Revenue impact of churn (estimated lost revenue)
SELECT
  city,
  gender,
  ROUND(SUM(txn_count * avg_txn_amount)::numeric,2) AS total_revenue_lost
FROM customers
WHERE is_churned = 1
GROUP BY city, gender
ORDER BY total_revenue_lost DESC;

-- 6 High-value customer churn
WITH hv AS (
  SELECT *,
    CASE WHEN avg_txn_amount > 2000 AND txn_count > 10 THEN 1 ELSE 0 END AS is_high_value
  FROM customers
)
SELECT
  SUM(CASE WHEN is_high_value = 1 THEN 1 ELSE 0 END) AS total_high_value,
  SUM(CASE WHEN is_high_value = 1 AND is_churned = 1 THEN 1 ELSE 0 END) AS churned_high_value,
  ROUND(
    100.0 * SUM(CASE WHEN is_high_value = 1 AND is_churned = 1 THEN 1 ELSE 0 END) /
    NULLIF(SUM(CASE WHEN is_high_value = 1 THEN 1 ELSE 0 END),0)
  ,2) AS churn_rate_pct_high_value
FROM hv;

-- 7 Cohort retention categories
SELECT
  cohort_month,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN days_since_last_txn <= 30 THEN 1 ELSE 0 END) AS active_count,
  SUM(CASE WHEN days_since_last_txn BETWEEN 31 AND 180 THEN 1 ELSE 0 END) AS at_risk_count,
  SUM(CASE WHEN days_since_last_txn > 180 THEN 1 ELSE 0 END) AS churned_count,
  ROUND(100.0 * SUM(CASE WHEN days_since_last_txn <= 30 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS pct_active,
  ROUND(100.0 * SUM(CASE WHEN days_since_last_txn BETWEEN 31 AND 180 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS pct_at_risk,
  ROUND(100.0 * SUM(CASE WHEN days_since_last_txn > 180 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS pct_churned
FROM customers
GROUP BY cohort_month
ORDER BY cohort_month;

-- 8 Churn probability indicators (compare averages)
SELECT
  'txn_count' AS metric,
  ROUND(AVG(CASE WHEN is_churned = 1 THEN txn_count END)::numeric,2) AS churned_avg,
  ROUND(AVG(CASE WHEN is_churned = 0 THEN txn_count END)::numeric,2) AS active_avg,
  ROUND(ABS(AVG(CASE WHEN is_churned = 1 THEN txn_count END) - AVG(CASE WHEN is_churned = 0 THEN txn_count END))::numeric,2) AS diff
FROM customers
UNION ALL
SELECT
  'avg_txn_amount',
  ROUND(AVG(CASE WHEN is_churned = 1 THEN avg_txn_amount END)::numeric,2),
  ROUND(AVG(CASE WHEN is_churned = 0 THEN avg_txn_amount END)::numeric,2),
  ROUND(ABS(AVG(CASE WHEN is_churned = 1 THEN avg_txn_amount END) - AVG(CASE WHEN is_churned = 0 THEN avg_txn_amount END))::numeric,2)
FROM customers
UNION ALL
SELECT
  'age',
  ROUND(AVG(CASE WHEN is_churned = 1 THEN age END)::numeric,2),
  ROUND(AVG(CASE WHEN is_churned = 0 THEN age END)::numeric,2),
  ROUND(ABS(AVG(CASE WHEN is_churned = 1 THEN age END) - AVG(CASE WHEN is_churned = 0 THEN age END))::numeric,2)
FROM customers;

-- 9 Survival analysis (approx, months since cohort)
SELECT
  months_since_cohort,
  COUNT(*) AS customers_in_bucket,
  SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) AS churn_count,
  SUM(CASE WHEN is_churned = 0 THEN 1 ELSE 0 END) AS active_count,
  ROUND(100.0 * SUM(CASE WHEN is_churned = 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS survival_rate_pct
FROM (
  SELECT *,
    FLOOR(EXTRACT(EPOCH FROM (DATE '2024-01-01' - cohort_month))/30)::int AS months_since_cohort
  FROM customers
) t
GROUP BY months_since_cohort
ORDER BY months_since_cohort;

-- 10 Customer segmentation and churn
SELECT
  segment,
  COUNT(*) AS customers,
  SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) AS churned,
  ROUND(100.0 * SUM(CASE WHEN is_churned = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) AS churn_rate_pct,
  ROUND(AVG(days_since_last_txn)::numeric,2) AS avg_days_since_last_txn
FROM (
  SELECT *,
    CASE
      WHEN txn_count > 20 AND avg_txn_amount > 2500 THEN 'Premium'
      WHEN txn_count BETWEEN 5 AND 20 THEN 'Regular'
      ELSE 'Low-Engagement'
    END AS segment
  FROM customers
) s
GROUP BY segment
ORDER BY CASE WHEN segment='Premium' THEN 1 WHEN segment='Regular' THEN 2 ELSE 3 END;
