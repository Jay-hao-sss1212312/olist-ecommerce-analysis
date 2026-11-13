-- Olist 数据质量检查（DuckDB）
-- 运行方式：duckdb olist.duckdb，然后 .read sql/01_data_quality.sql

-- 1. 订单状态分布
SELECT
  order_status,
  COUNT(*) AS order_count
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
GROUP BY 1
ORDER BY 2 DESC;

-- 2. 订单时间范围
SELECT
  MIN(CAST(order_purchase_timestamp AS TIMESTAMP)) AS min_purchase_ts,
  MAX(CAST(order_purchase_timestamp AS TIMESTAMP)) AS max_purchase_ts
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');

-- 3. 关键时间字段缺失
SELECT
  COUNT(*) AS order_count,
  SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_delivered,
  SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');

-- 4. 评价表是否一单多条
SELECT
  COUNT(*) AS review_rows,
  COUNT(DISTINCT order_id) AS reviewed_orders
FROM read_csv_auto('data/raw/olist_order_reviews_dataset.csv');

-- 5. 支付表是否一单多条
SELECT
  COUNT(*) AS payment_rows,
  COUNT(DISTINCT order_id) AS paid_orders
FROM read_csv_auto('data/raw/olist_order_payments_dataset.csv');

-- 6. 客户表唯一用户数
SELECT
  COUNT(*) AS customer_rows,
  COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM read_csv_auto('data/raw/olist_customers_dataset.csv');

-- 7. 商品品类缺失
SELECT
  COUNT(*) AS product_rows,
  SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category
FROM read_csv_auto('data/raw/olist_products_dataset.csv');
