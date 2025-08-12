-- solutions.sql

-- 1) Total transaction volume and revenue by month
SELECT
  date_trunc('month', transaction_time) AS month,
  COUNT(*) AS transaction_count,
  SUM(amount) AS total_revenue
FROM transactions
GROUP BY 1
ORDER BY 1;

-- 2) Top 10 customers by total spending in the last 12 months
SELECT
  user_id,
  SUM(amount) AS total_spend
FROM transactions
WHERE transaction_time >= (current_date - INTERVAL '12 months')
GROUP BY user_id
ORDER BY total_spend DESC
LIMIT 10;

-- 3) Average transaction amount and median by merchant category
SELECT
  merchant_category,
  AVG(amount) AS avg_amount,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount
FROM transactions
GROUP BY merchant_category
ORDER BY merchant_category;

-- 4) Identify accounts with sudden spikes (>= 3x median) in daily spend
WITH daily AS (
  SELECT
    user_id,
    DATE(transaction_time) AS tx_date,
    SUM(amount) AS daily_sum
  FROM transactions
  GROUP BY user_id, DATE(transaction_time)
),
median_per_user AS (
  SELECT
    user_id,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY daily_sum) AS median_daily
  FROM daily
  GROUP BY user_id
)
SELECT
  d.user_id,
  d.tx_date,
  d.daily_sum,
  m.median_daily
FROM daily d
JOIN median_per_user m USING (user_id)
WHERE m.median_daily IS NOT NULL
  AND d.daily_sum >= 3 * m.median_daily
ORDER BY d.user_id, d.tx_date;

-- 5) Fraud-like heuristics: rapid multiple transactions from same card within 1 hour
SELECT
  card_id,
  transaction_id,
  user_id,
  transaction_time,
  amount,
  prev_tx_time,
  EXTRACT(EPOCH FROM (transaction_time - prev_tx_time))/60 AS minutes_since_prev
FROM (
  SELECT
    t.*,
    LAG(transaction_time) OVER (PARTITION BY card_id ORDER BY transaction_time) AS prev_tx_time,
    LAG(transaction_id) OVER (PARTITION BY card_id ORDER BY transaction_time) AS prev_tx_id
  FROM transactions t
) s
WHERE prev_tx_time IS NOT NULL
  AND transaction_time <= prev_tx_time + INTERVAL '1 hour'
ORDER BY card_id, transaction_time;

-- 6) Rolling 7-day total spend per customer (daily granularity)
SELECT
  user_id,
  DATE(transaction_time) AS tx_date,
  SUM(amount) AS daily_sum,
  SUM(SUM(amount)) OVER (
    PARTITION BY user_id
    ORDER BY DATE(transaction_time)
    RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW
  ) AS rolling_7d_sum
FROM transactions
GROUP BY user_id, DATE(transaction_time)
ORDER BY user_id, tx_date;

-- 7) Customer RFM buckets (Recency in days, Frequency count, Monetary sum) and 1-5 buckets
WITH rfm AS (
  SELECT
    user_id,
    EXTRACT(DAY FROM (current_date - MAX(transaction_time)))::INT AS recency_days,
    COUNT(*) AS frequency,
    SUM(amount) AS monetary
  FROM transactions
  GROUP BY user_id
),
rfm_buckets AS (
  SELECT
    user_id,
    recency_days,
    frequency,
    monetary,
    ntile(5) OVER (ORDER BY recency_days ASC) AS recency_bucket,
    ntile(5) OVER (ORDER BY frequency DESC) AS frequency_bucket,
    ntile(5) OVER (ORDER BY monetary DESC) AS monetary_bucket
  FROM rfm
)
SELECT
  user_id,
  recency_days,
  frequency,
  monetary,
  recency_bucket,
  frequency_bucket,
  monetary_bucket,
  (recency_bucket + frequency_bucket + monetary_bucket) AS rfm_score
FROM rfm_buckets
ORDER BY rfm_score DESC, monetary DESC;

-- 8) Identify foreign-transaction heavy users and count (users with >=50% foreign txns)
WITH tx_flags AS (
  SELECT
    user_id,
    CASE WHEN transaction_country IS NOT NULL AND billing_country IS NOT NULL AND transaction_country <> billing_country THEN 1 ELSE 0 END AS is_foreign
  FROM transactions
),
user_foreign AS (
  SELECT
    user_id,
    SUM(is_foreign) AS foreign_count,
    COUNT(*) AS total_count,
    SUM(is_foreign)::decimal / NULLIF(COUNT(*),0) AS foreign_ratio
  FROM tx_flags
  GROUP BY user_id
)
SELECT
  user_id,
  foreign_count,
  total_count,
  foreign_ratio
FROM user_foreign
WHERE foreign_ratio >= 0.5
ORDER BY foreign_ratio DESC, foreign_count DESC;

-- Extra: count of foreign-transaction heavy users
SELECT COUNT(*) AS heavy_foreign_user_count
FROM (
  SELECT
    user_id,
    SUM(CASE WHEN transaction_country IS NOT NULL AND billing_country IS NOT NULL AND transaction_country <> billing_country THEN 1 ELSE 0 END) AS foreign_count,
    COUNT(*) AS total_count
  FROM transactions
  GROUP BY user_id
  HAVING (SUM(CASE WHEN transaction_country IS NOT NULL AND billing_country IS NOT NULL AND transaction_country <> billing_country THEN 1 ELSE 0 END)::decimal / COUNT(*)) >= 0.5
) t;
