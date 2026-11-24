-- 各州履约优先级：绝对数 + 综合分
-- 用法：在 02_order_wide、03_user_summary 之后运行

CREATE OR REPLACE TABLE state_priority AS
SELECT
  customer_state,
  COUNT(DISTINCT order_id)                        AS orders,
  SUM(late_flag)                                  AS late_orders,      -- 绝对数
  ROUND(AVG(late_flag), 4)                        AS late_rate,
  ROUND(SUM(late_flag) * AVG(late_flag), 1)       AS priority_score,   -- 绝对数 × 率
  ROUND(AVG(delivery_days), 2)                    AS avg_delivery_days,
  ROUND(AVG(review_score), 2)                     AS avg_review_score
FROM order_wide
WHERE order_status = 'delivered'
GROUP BY 1
HAVING COUNT(DISTINCT order_id) >= 100
ORDER BY late_orders DESC;

-- 对照：同样条件下按率排序，看两张榜前五名差多少
SELECT customer_state, orders, late_orders, late_rate
FROM state_priority
ORDER BY late_rate DESC
LIMIT 5;

-- 超额延迟单：实际 − 按整体平均率应有
WITH overall AS (
  SELECT AVG(late_flag) AS base_rate
  FROM order_wide WHERE order_status = 'delivered'
)
SELECT
  s.customer_state,
  s.orders,
  s.late_orders,
  s.late_rate,
  ROUND(s.orders * o.base_rate, 1)                  AS expected_late,
  ROUND(s.late_orders - s.orders * o.base_rate, 1)  AS excess_late,   -- 正数=差于平均
  s.priority_score
FROM state_priority s CROSS JOIN overall o
ORDER BY excess_late DESC
LIMIT 10;