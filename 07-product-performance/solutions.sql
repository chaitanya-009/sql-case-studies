-- solutions.sql

-- 1 Category-wise performance summary
SELECT
  category,
  SUM(revenue)                         AS total_revenue,
  ROUND(AVG(price)::numeric, 2)        AS avg_price,
  SUM(units_sold)                      AS total_units_sold,
  ROUND(AVG(avg_rating)::numeric, 2)   AS avg_rating
FROM products
GROUP BY category
ORDER BY total_revenue DESC;

-- 2 Best & worst performing products
-- top 10 by revenue
SELECT product_id, product_name, category, revenue, units_sold
FROM products
ORDER BY revenue DESC
LIMIT 10;

-- bottom 10 by units_sold
SELECT product_id, product_name, category, revenue, units_sold
FROM products
ORDER BY units_sold ASC
LIMIT 10;

-- 3 High return-rate products (return_rate_pct > 10% and revenue > median)
WITH med AS (
  SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY revenue) AS rev_median FROM products
)
SELECT p.product_id, p.product_name, p.category, p.return_rate_pct, p.revenue
FROM products p
CROSS JOIN med
WHERE p.return_rate_pct > 10
  AND p.revenue > med.rev_median
ORDER BY p.return_rate_pct DESC, p.revenue DESC;

-- 4 Pricing impact on ratings (price bands)
SELECT
  CASE
    WHEN price < 1000 THEN 'Low'
    WHEN price BETWEEN 1000 AND 5000 THEN 'Medium'
    WHEN price BETWEEN 5001 AND 15000 THEN 'High'
    ELSE 'Premium'
  END AS price_band,
  COUNT(*)                             AS cnt,
  ROUND(AVG(avg_rating)::numeric, 2)   AS avg_rating,
  ROUND(AVG(return_rate_pct)::numeric, 2) AS avg_return_rate
FROM products
GROUP BY price_band
ORDER BY
  CASE price_band WHEN 'Low' THEN 1 WHEN 'Medium' THEN 2 WHEN 'High' THEN 3 ELSE 4 END;

-- 5 New vs old products analysis
WITH flagged AS (
  SELECT *,
    CASE WHEN launch_date >= (current_date - INTERVAL '18 months') THEN 'New' ELSE 'Old' END AS age_group
  FROM products
)
SELECT
  age_group,
  COUNT(*)                             AS cnt,
  ROUND(AVG(revenue)::numeric, 2)      AS avg_revenue,
  ROUND(AVG(avg_rating)::numeric, 2)   AS avg_rating,
  ROUND(AVG(return_rate_pct)::numeric, 2) AS avg_return_rate
FROM flagged
GROUP BY age_group
ORDER BY age_group;