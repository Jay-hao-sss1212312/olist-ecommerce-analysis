-- 核心分析查询（DuckDB）
-- 先运行 02 和 03

-- 1. 月度经营趋势
SELECT
  DATE_TRUNC('month', purchase_ts) AS month,
  COUNT(DISTINCT order_id) AS orders,
  SUM(COALESCE(item_revenue, 0) + COALESCE(freight_value, 0)) AS gmv,
  AVG(COALESCE(item_revenue, 0) + COALESCE(freight_value, 0)) AS aov
FROM order_wide
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- 2. 各州履约表现
SELECT
  customer_state,
  COUNT(*) AS orders,
  AVG(late_flag) AS late_rate,
  AVG(delivery_days) AS avg_delivery_days,
  AVG(review_score) AS avg_review_score
FROM order_wide
WHERE order_status = 'delivered'
GROUP BY 1
HAVING COUNT(*) >= 100
ORDER BY late_rate DESC;

-- 3. 延迟 vs 评分
SELECT
  late_flag,
  COUNT(*) AS orders,
  AVG(review_score) AS avg_review_score
FROM order_wide
WHERE order_status = 'delivered'
  AND review_score IS NOT NULL
GROUP BY 1;

-- 4. 整体复购率
SELECT
  COUNT(*) AS users,
  SUM(is_repeat) AS repeat_users,
  AVG(is_repeat) AS repeat_rate
FROM user_summary;

-- 5. 品类延迟率
WITH category_orders AS (
  SELECT
    order_id,
    TRIM(UNNEST(STRING_SPLIT(product_categories, ','))) AS category,
    late_flag,
    review_score
  FROM order_wide
  WHERE order_status = 'delivered'
    AND product_categories IS NOT NULL
)
SELECT
  category,
  COUNT(*) AS orders,
  AVG(late_flag) AS late_rate,
  AVG(review_score) AS avg_review_score
FROM category_orders
GROUP BY 1
HAVING COUNT(*) >= 100
ORDER BY late_rate DESC;

-- 6. 高延迟卖家
WITH seller_orders AS (
  SELECT
    order_id,
    TRIM(UNNEST(STRING_SPLIT(seller_ids, ','))) AS seller_id,
    late_flag
  FROM order_wide
  WHERE order_status = 'delivered'
    AND seller_ids IS NOT NULL
)
SELECT
  seller_id,
  COUNT(*) AS orders,
  AVG(late_flag) AS late_rate
FROM seller_orders
GROUP BY 1
HAVING COUNT(*) >= 30
ORDER BY late_rate DESC
LIMIT 20;
