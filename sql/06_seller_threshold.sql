-- 卖家履约门槛敏感性：门槛从 30 提到 100，覆盖率掉多少
CREATE OR REPLACE TABLE seller_threshold_sensitivity AS
WITH seller_orders AS (
  SELECT
    order_id,
    TRIM(UNNEST(STRING_SPLIT(seller_ids, ','))) AS seller_id,
    late_flag
  FROM order_wide
  WHERE order_status = 'delivered'
    AND seller_ids IS NOT NULL
),
agg AS (
  SELECT
    seller_id,
    COUNT(*)        AS orders,
    SUM(late_flag)  AS late_orders,
    AVG(late_flag)  AS late_rate
  FROM seller_orders
  GROUP BY 1
),
total AS (
  SELECT SUM(orders) AS all_orders, SUM(late_orders) AS all_late FROM agg
),
thr AS (SELECT UNNEST([30, 50, 100, 200]) AS threshold)
SELECT
  t.threshold,
  COUNT(*) FILTER (WHERE a.orders >= t.threshold) AS sellers_in_scope,
  SUM(a.orders) FILTER (WHERE a.orders >= t.threshold) AS orders_covered,
  ROUND(100.0 * SUM(a.orders) FILTER (WHERE a.orders >= t.threshold)
        / tot.all_orders, 1)                        AS pct_orders,
  SUM(a.late_orders) FILTER (WHERE a.orders >= t.threshold) AS late_covered,
  ROUND(100.0 * SUM(a.late_orders) FILTER (WHERE a.orders >= t.threshold)
        / tot.all_late, 1)                          AS pct_late
FROM agg a
CROSS JOIN thr t
CROSS JOIN total tot
GROUP BY t.threshold, tot.all_orders, tot.all_late
ORDER BY t.threshold;