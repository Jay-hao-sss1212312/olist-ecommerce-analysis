-- 订单级宽表（DuckDB）
-- 说明：
-- 1) 商品明细先聚合到订单级，避免一单多行导致金额重复
-- 2) 支付表先聚合，避免多次支付导致重复
-- 3) 评价表先聚合，避免一单多条评价
-- 4) 地理表暂不使用，地区分析用 customers.customer_state

CREATE OR REPLACE TABLE order_wide AS
WITH orders AS (
  SELECT
    order_id,
    customer_id,
    order_status,
    CAST(order_purchase_timestamp AS TIMESTAMP) AS purchase_ts,
    CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_ts,
    CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_ts
  FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
),
customers AS (
  SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
  FROM read_csv_auto('data/raw/olist_customers_dataset.csv')
),
item_detail AS (
  SELECT
    i.order_id,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    COALESCE(
      t.product_category_name_english,
      p.product_category_name,
      'unknown'
    ) AS product_category,
    s.seller_state
  FROM read_csv_auto('data/raw/olist_order_items_dataset.csv') i
  LEFT JOIN read_csv_auto('data/raw/olist_products_dataset.csv') p
    ON i.product_id = p.product_id
  LEFT JOIN read_csv_auto('data/raw/product_category_name_translation.csv') t
    ON p.product_category_name = t.product_category_name
  LEFT JOIN read_csv_auto('data/raw/olist_sellers_dataset.csv') s
    ON i.seller_id = s.seller_id
),
items AS (
  SELECT
    order_id,
    SUM(price) AS item_revenue,
    SUM(freight_value) AS freight_value,
    COUNT(*) AS item_count,
    STRING_AGG(DISTINCT product_category, ', ') AS product_categories,
    STRING_AGG(DISTINCT seller_id, ', ') AS seller_ids,
    STRING_AGG(DISTINCT seller_state, ', ') AS seller_states
  FROM item_detail
  GROUP BY order_id
),
payments AS (
  SELECT
    order_id,
    SUM(payment_value) AS payment_value,
    STRING_AGG(DISTINCT payment_type, ', ') AS payment_types,
    MAX(payment_installments) AS max_installments
  FROM read_csv_auto('data/raw/olist_order_payments_dataset.csv')
  GROUP BY order_id
),
reviews AS (
  SELECT
    order_id,
    AVG(review_score) AS review_score,
    COUNT(*) AS review_count
  FROM read_csv_auto('data/raw/olist_order_reviews_dataset.csv')
  GROUP BY order_id
)
SELECT
  o.order_id,
  c.customer_unique_id,
  c.customer_city,
  c.customer_state,
  o.order_status,
  o.purchase_ts,
  o.delivered_ts,
  o.estimated_ts,
  DATE_DIFF('day', o.purchase_ts, o.delivered_ts) AS delivery_days,
  CASE
    WHEN o.delivered_ts IS NOT NULL
     AND o.estimated_ts IS NOT NULL
     AND o.delivered_ts > o.estimated_ts
    THEN 1 ELSE 0
  END AS late_flag,
  i.item_revenue,
  i.freight_value,
  i.item_count,
  i.product_categories,
  i.seller_ids,
  i.seller_states,
  p.payment_value,
  p.payment_types,
  p.max_installments,
  r.review_score,
  r.review_count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN items i ON o.order_id = i.order_id
LEFT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN reviews r ON o.order_id = r.order_id;
