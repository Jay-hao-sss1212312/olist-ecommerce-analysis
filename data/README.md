# 数据目录说明

将 Olist 原始 CSV 放到 `data/raw/`，文件名保持不变。

| 文件 | 行数 |
|---|---:|
| `olist_orders_dataset.csv` | 99,441 |
| `olist_order_items_dataset.csv` | 112,650 |
| `olist_customers_dataset.csv` | 99,441 |
| `olist_products_dataset.csv` | 32,951 |
| `olist_order_reviews_dataset.csv` | 99,224 |
| `olist_sellers_dataset.csv` | 3,095 |
| `olist_order_payments_dataset.csv` | 103,886 |
| `product_category_name_translation.csv` | 71 |
| `olist_geolocation_dataset.csv` | 1,000,163 |

## 注意

- `customer_id` 是一次订单的身份，`customer_unique_id` 才是同一个用户；复购分析必须用后者。
- 支付表可能一单多行，先聚合再 join。
- 评价表可能一单多条，先聚合再 join。
- 商品明细一单多行，先聚合到订单级。
- `olist_geolocation_dataset.csv` 有 100 万行，14 天版可以不用；地区分析用 `customers.customer_state` 即可。
- 原始数据不提交到 GitHub，`data/processed/` 也不提交。
