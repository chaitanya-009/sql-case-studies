-- Q1
SELECT
  c.customer_id,
  COALESCE(card_cnt,0)                     AS total_cards,
  COALESCE(txn_cnt,0)                      AS total_txns,
  COALESCE(total_spend,0)::numeric(12,2)   AS total_spend,
  COALESCE(fraud_cnt,0)                    AS fraud_count,
  ROUND(100.0 * COALESCE(fraud_cnt,0) / NULLIF(txn_cnt,0), 2) AS fraud_rate_pct
FROM customers c
LEFT JOIN (
  SELECT customer_id, COUNT(DISTINCT card_id) AS card_cnt
  FROM cards
  GROUP BY customer_id
) cd ON cd.customer_id = c.customer_id
LEFT JOIN (
  SELECT customer_id,
         COUNT(*) AS txn_cnt,
         SUM(amount) AS total_spend,
         SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_cnt
  FROM transactions
  GROUP BY customer_id
) t ON t.customer_id = c.customer_id
WHERE COALESCE(txn_cnt,0) >= 5
ORDER BY fraud_rate_pct DESC, fraud_count DESC
LIMIT 20;

-- Q2
SELECT
  t.card_id,
  c.customer_id,
  c.issuer_bank,
  c.is_active,
  tx.summary_txn_count,
  tx.summary_total_amount::numeric(12,2) AS total_amount,
  tx.summary_fraud_count,
  tx.last_txn_date
FROM cards c
JOIN (
  SELECT card_id,
         COUNT(*) AS summary_txn_count,
         SUM(amount) AS summary_total_amount,
         SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS summary_fraud_count,
         MAX(txn_date) AS last_txn_date
  FROM transactions
  GROUP BY card_id
) tx ON tx.card_id = c.card_id
ORDER BY tx.summary_total_amount DESC
LIMIT 10;

-- Q3
SELECT
  day_hour::date                                  AS day,
  EXTRACT(HOUR FROM day_hour)                     AS hour,
  total_txns,
  fraud_txns,
  ROUND(100.0 * fraud_txns / NULLIF(total_txns,0), 2) AS fraud_rate_pct
FROM (
  SELECT
    date_trunc('hour', txn_date) AS day_hour,
    COUNT(*)                     AS total_txns,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_txns
  FROM transactions
  GROUP BY date_trunc('hour', txn_date)
) s
WHERE total_txns >= 10
ORDER BY fraud_rate_pct DESC
LIMIT 20;

-- Q4
SELECT
  merchant,
  COUNT(*)                                    AS total_txns,
  SUM(amount)::numeric(14,2)                  AS total_revenue,
  SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_txns,
  ROUND(100.0 * SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS fraud_rate_pct,
  ROUND(100.0 * SUM(CASE WHEN country <> 'IN' THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 2) AS pct_foreign_txns
FROM transactions
GROUP BY merchant
HAVING COUNT(*) >= 50
  AND SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) > 0.05
ORDER BY fraud_rate_pct DESC, total_txns DESC;

-- Q5
SELECT
  t.txn_id,
  t.txn_date,
  t.card_id,
  t.customer_id,
  c.issuer_bank,
  t.amount,
  t.mins_since_prev_card,
  t.txns_last_24h_card,
  t.is_fraud
FROM transactions t
LEFT JOIN cards c ON c.card_id = t.card_id
WHERE t.mins_since_prev_card < 2
  AND t.txns_last_24h_card >= 5
ORDER BY t.txn_date DESC;

-- Q6
WITH card_stats AS (
  SELECT
    card_id,
    AVG(amount)                          AS avg_amount,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
    STDDEV(amount)                       AS stddev_amount,
    SUM(CASE WHEN txn_date >= (SELECT MAX(txn_date) - INTERVAL '30 days' FROM transactions) THEN 1 ELSE 0 END) AS txns_last_30d,
    SUM(CASE WHEN country <> 'IN' THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*),0) AS prop_foreign,
    SUM(CASE WHEN status = 'Chargeback' THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(*),0) AS prop_chargeback,
    COUNT(*)                             AS total_txns
  FROM transactions
  GROUP BY card_id
)
SELECT
  s.card_id,
  s.total_txns,
  ROUND(s.avg_amount::numeric,2)       AS avg_amount,
  ROUND(s.median_amount::numeric,2)    AS median_amount,
  ROUND(COALESCE(s.stddev_amount,0)::numeric,2) AS stddev_amount,
  s.txns_last_30d,
  ROUND(100.0 * s.prop_foreign,2)      AS pct_foreign,
  ROUND(100.0 * s.prop_chargeback,2)   AS pct_chargeback,
  CASE WHEN (s.prop_chargeback > 0.02 OR s.prop_foreign > 0.10 OR s.txns_last_30d > 20) THEN 1 ELSE 0 END AS risk_flag,
  c.customer_id,
  cust.name,
  cust.city,
  c.issuer_bank
FROM card_stats s
JOIN cards c ON c.card_id = s.card_id
LEFT JOIN customers cust ON cust.customer_id = c.customer_id
WHERE CASE WHEN (s.prop_chargeback > 0.02 OR s.prop_foreign > 0.10 OR s.txns_last_30d > 20) THEN 1 ELSE 0 END = 1
ORDER BY s.txns_last_30d DESC, s.prop_chargeback DESC;

-- Q7
SELECT
  is_fraud,
  ROUND(AVG(amount)::numeric,2)                           AS avg_amount,
  ROUND(STDDEV(amount)::numeric,2)                        AS sd_amount,
  ROUND(AVG(mins_since_prev_card)::numeric,2)             AS avg_mins_since_prev,
  ROUND(STDDEV(mins_since_prev_card)::numeric,2)          AS sd_mins_since_prev,
  ROUND(AVG(txns_last_24h_card)::numeric,2)               AS avg_txns_last_24h,
  ROUND(STDDEV(txns_last_24h_card)::numeric,2)            AS sd_txns_last_24h,
  ROUND(AVG(amount_over_card_mean)::numeric,2)            AS avg_amt_over_mean,
  ROUND(STDDEV(amount_over_card_mean)::numeric,2)         AS sd_amt_over_mean,
  ROUND(AVG(coalesce(cust.risk_score,0))::numeric,2)      AS avg_customer_risk_score,
  ROUND(STDDEV(coalesce(cust.risk_score,0))::numeric,2)   AS sd_customer_risk_score
FROM transactions t
LEFT JOIN cards c ON c.card_id = t.card_id
LEFT JOIN customers cust ON cust.customer_id = c.customer_id
GROUP BY is_fraud
ORDER BY is_fraud DESC;

-- Q8
SELECT
  c.card_id,
  c.customer_id,
  c.issued_date,
  MIN(t.txn_date)                                 AS first_txn_date,
  COUNT(t.txn_id)                                 AS txn_count,
  CASE WHEN to_date(c.issued_date, 'YYYY-MM-DD') > MIN(t.txn_date) THEN 1 ELSE 0 END AS issued_after_first_txn_flag
FROM cards c
LEFT JOIN transactions t ON t.card_id = c.card_id
GROUP BY c.card_id, c.customer_id, c.issued_date
HAVING MIN(t.txn_date) IS NOT NULL
  AND to_date(c.issued_date, 'YYYY-MM-DD') > MIN(t.txn_date)
ORDER BY first_txn_date;
