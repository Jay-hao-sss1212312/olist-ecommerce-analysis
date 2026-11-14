# 02\_metrics\_dictionary

# 指标字典（Day 2 定稿）

> 全项目唯一的事实来源：所有图表、报告、README、简历里的同一个指标，都必须能追到这张表。口径写死后不再改；若确需修改，同步改本文件、`README.md` 第 3 节和相关 SQL。
>
> 定稿日期：2026-11-14　｜　有效订单数：96,478　｜　观察期：2016-09-04 至 2018-10-17

## 一、核心指标

| 指标         | 定义                   | SQL 表达式                                                  | 分母 / 过滤条件                                              | 本项目取值              |
| ------------ | ---------------------- | ----------------------------------------------------------- | ------------------------------------------------------------ | ----------------------- |
| 有效订单     | 已送达订单             | `WHERE order_status = 'delivered'`                          | 全部订单 99,441                                              | **96,478 单**（97.02%） |
| GMV          | 商品金额 + 运费        | `SUM(COALESCE(item_revenue,0) + COALESCE(freight_value,0))` | 有效订单                                                     | **15,419,773.75**       |
| 客单价 AOV   | 单均 GMV               | `AVG(COALESCE(item_revenue,0) + COALESCE(freight_value,0))` | 有效订单                                                     | **159.83**              |
| 平均配送天数 | 下单到送达的自然日     | `AVG(delivery_days)`                                        | `delivered`，且 `delivered_ts IS NOT NULL`                   | **12.5**）              |
| 延迟订单数   | `late_flag = 1` 的订单 | `SUM(late_flag)`                                            | 有效订单                                                     | **7,826 单**            |
| 延迟率       | 延迟订单占比           | `AVG(late_flag)`                                            | 有效订单 **96,478**（缺时间订单因 `late_flag = 0` 计入分母） | **8.11%**               |
| 平均评分     | 订单评分均值           | `AVG(review_score)`                                         | `review_score IS NOT NULL`                                   | **4.09 / 5**            |
| 复购用户     | 有 ≥2 笔有效订单的用户 | `SUM(is_repeat)`                                            | `user_summary` 全部用户 93,358                               | **2,801 人**            |
| 复购率       | 复购用户占比           | `AVG(is_repeat)`                                            | `user_summary` 全部用户 93,358                               | **3.00%**               |
| 复购观察窗口 | 统一口径               | 本项目按全观察期统计，不另设窗口                            | 全部有效订单，2016-09 至 2018-10                             | **全观察期**            |

> **数字格式约定**：金额保留两位小数并加千分位，比率统一写成百分比两位小数，评分两位小数，天数一位小数。不要把 SQL 结果里的长小数直接贴进来（如 `0.08112366538820359`），既带浮点尾巴也不利于阅读；`15,419,773.749999037` 是浮点累加误差，正确写法是 `15,419,773.75`。

## 二、口径决策记录

| 决策点                                         | 选了什么                                          | 为什么                                                                                                          | 若换口径会怎样                                                                                                                                                            |
| ---------------------------------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GMV 用商品金额还是支付金额                     | 商品金额 + 运费                                   | 支付表存在一单多条、部分订单无支付记录                                                                          | 换支付口径会少算无支付订单，金额不可比                                                                                                                                    |
| 复购用 `customer_id` 还是 `customer_unique_id` | `customer_unique_id`                              | 前者是"一次订单的身份"                                                                                          | 用前者复购率几乎为 0                                                                                                                                                      |
| 复购是否限定 90/180 天窗口                     | 全观察期                                          | Olist 数据跨度约 2 年，短窗口会低估                                                                             | 报告里必须声明，不能与别的项目直接比                                                                                                                                      |
| 评分是否先去重                                 | 按 `order_id` 平均后再用                          | 个别订单有多条评价                                                                                              | 不去重会放大这些订单的权重                                                                                                                                                |
| 州/品类/卖家分组的最小样本                     | 州 ≥100 单、品类 ≥100 单、卖家 ≥30 单             | 小样本分组率值波动大                                                                                            | 门槛太低会出现虚假的"最高延迟率"                                                                                                                                          |
| **延迟率分母用 96,478 还是 96,470**            | **96,478**（`AVG(late_flag)` 只过滤 `delivered`） | `04_analysis.sql` 第 2 条、各州排名图、延迟 vs 评分对比全部基于这条口径；缺时间订单 `late_flag = 0`，视作未延迟 | 用"两个时间都非空"的严格口径，分母 96,470、延迟率 8.1124%，四舍五入同样是 **8.11%**，不影响任何图表与结论；但字典里只能保留一个口径，否则报告和简历会出现两个"官方"延迟率 |

## 三、分组与分层规则

| 规则 | 阈值 | 用途 |
| --- | --- | --- |
| 州级排名 | `HAVING COUNT(*) >= 100` | `04_analysis.sql` 第 2 条 |
| 品类延迟排名 | `HAVING COUNT(*) >= 100` | 第 5 条 |
| 高延迟卖家 | `HAVING COUNT(*) >= 30`，取 Top20 | 第 6 条 |
| RFM 分层 | R：≤90 / \>180 天；F：order\_count；M：total\_revenue | Day 4，阈值需写清理由 |

## 四、引用方式

写报告统一引用本文件，例如：

> 延迟率 = 有效订单中 `delivered_ts > estimated_ts` 的占比（口径见 `reports/02_metrics_dictionary.md`）。

## 五、复现 SQL

所有取值都能用下面几条查询重新跑出来（DataGrip 连 `olist.duckdb` 后逐条执行）：

```sql
SELECT COUNT(*) FROM order_wide WHERE order_status = 'delivered';

SELECT
  SUM(COALESCE(item_revenue,0) + COALESCE(freight_value,0)) AS gmv,
  AVG(COALESCE(item_revenue,0) + COALESCE(freight_value,0)) AS aov
FROM order_wide WHERE order_status = 'delivered';

SELECT AVG(delivery_days) FROM order_wide
WHERE order_status = 'delivered' AND delivered_ts IS NOT NULL;

SELECT SUM(late_flag) AS late_orders, AVG(late_flag) AS late_rate
FROM order_wide WHERE order_status = 'delivered';

SELECT AVG(review_score) FROM order_wide
WHERE order_status = 'delivered' AND review_score IS NOT NULL;

SELECT SUM(is_repeat) AS repeat_users, AVG(is_repeat) AS repeat_rate
FROM user_summary;

-- 严格口径复核（仅用于解释口径差异，不写进报告）
SELECT COUNT(*) AS strict_denominator
FROM order_wide
WHERE order_status = 'delivered'
  AND delivered_ts IS NOT NULL
  AND estimated_ts IS NOT NULL;
```