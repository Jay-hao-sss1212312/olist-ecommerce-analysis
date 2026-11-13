-- 用户级汇总（DuckDB）
-- 先运行 02_order_wide.sql

CREATE OR REPLACE TABLE user_summary AS
WITH delivered AS (
  SELECT *
  FROM order_wide
  WHERE order_status = 'delivered'
),
max_date AS (
  SELECT MAX(purchase_ts) AS snapshot_ts
  FROM delivered
),
user_agg AS (
  SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS order_count,
    MIN(purchase_ts) AS first_order_ts,
    MAX(purchase_ts) AS last_order_ts,
    SUM(COALESCE(item_revenue, 0) + COALESCE(freight_value, 0)) AS total_revenue,
    AVG(review_score) AS avg_review_score,
    AVG(late_flag) AS late_rate
  FROM delivered
  WHERE customer_unique_id IS NOT NULL
  GROUP BY 1
)
SELECT
  u.customer_unique_id,
  u.order_count,
  u.first_order_ts,
  u.last_order_ts,
  u.total_revenue,
  u.avg_review_score,
  u.late_rate,
  DATE_DIFF('day', u.last_order_ts, m.snapshot_ts) AS recency_days,
  CASE WHEN u.order_count >= 2 THEN 1 ELSE 0 END AS is_repeat
FROM user_agg u
CROSS JOIN max_date m;
