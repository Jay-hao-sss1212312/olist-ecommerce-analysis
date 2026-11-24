-- 用户级验证：首单延迟是否伴随更低复购
CREATE OR REPLACE TABLE late_vs_repeat AS
WITH d AS (
  SELECT customer_unique_id, order_id, purchase_ts, late_flag
  FROM order_wide
  WHERE order_status = 'delivered'
    AND customer_unique_id IS NOT NULL
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY customer_unique_id ORDER BY purchase_ts, order_id
  ) AS rn
  FROM d
),
first_order AS (
  SELECT customer_unique_id, late_flag AS first_late
  FROM ranked WHERE rn = 1
),
u AS (
  SELECT customer_unique_id, MAX(rn) AS n_orders
  FROM ranked GROUP BY 1
)
SELECT
  f.first_late,
  COUNT(*)                                                   AS users,
  SUM(CASE WHEN u.n_orders >= 2 THEN 1 ELSE 0 END)            AS repeat_users,
  ROUND(AVG(CASE WHEN u.n_orders >= 2 THEN 1 ELSE 0 END), 4)  AS repeat_rate
FROM first_order f
JOIN u USING (customer_unique_id)
GROUP BY 1
ORDER BY 1;

-- 稳健性：排除观察期末 90 天内首单的用户（他们没有足够时间产生第二单）
-- 把 first_order 的 WHERE 改成：
--   WHERE rn = 1
--     AND purchase_ts < (SELECT MAX(purchase_ts) - INTERVAL 90 DAY FROM d)
-- 两个版本方向若一致，结论才站得住