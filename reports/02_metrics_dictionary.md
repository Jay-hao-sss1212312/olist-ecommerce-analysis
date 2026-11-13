# 02\_metrics\_dictionary

# 指标字典（Day 2）

> 全项目唯一的事实来源：所有图表、报告、README、简历里的同一个指标，都必须能追到这张表。口径写死后不再改；若确需修改，同步改本文件、`README.md` 第 3 节和相关 SQL。
>
> 定稿日期：**年\_\_****月\_\_****日　　有效订单数：**　　观察期：\_\_\_\_ 至 \_\_\_\_

## 一、核心指标

| 指标 | 定义 | SQL 表达式 | 分母 / 过滤条件 | 本项目取值 |
| --- | --- | --- | --- | --- |
| 有效订单 | 已送达订单 | `WHERE order_status = 'delivered'` | 全部订单 99,441 | \_\_\_\_ |
| GMV | 商品金额 + 运费 | `SUM(COALESCE(item_revenue,0) + COALESCE(freight_value,0))` | 有效订单 | \_\_\_\_ |
| 客单价 AOV | 单均 GMV | `AVG(COALESCE(item_revenue,0) + COALESCE(freight_value,0))` | 有效订单 | \_\_\_\_ |
| 配送天数 | 下单到送达的自然日 | `DATE_DIFF('day', purchase_ts, delivered_ts)` | 有送达时间的订单 | \_\_\_\_ |
| 延迟交付 | 实际送达晚于预计送达 | `delivered_ts > estimated_ts` | 两个时间都非空 | \_\_\_\_ |
| 延迟率 | 延迟订单占比 | `AVG(late_flag)` | 有效订单，且两个时间非空 | \_\_\_\_ |
| 平均评分 | 订单评分均值 | `AVG(review_score)` | `review_score IS NOT NULL` | \_\_\_\_ |
| 复购用户 | 有 ≥2 笔有效订单的用户 | `CASE WHEN order_count >= 2 THEN 1 ELSE 0 END` | `user_summary` | \_\_\_\_ |
| 复购率 | 复购用户占比 | `AVG(is_repeat)` | `user_summary` 全部用户 | \_\_\_\_ |
| 复购观察窗口 | 统一口径 | 本项目按全观察期统计，不另设窗口 | 全部有效订单，2016-09 至 2018-10 | 全观察期 |

## 二、口径决策记录

| 决策点 | 选了什么 | 为什么 | 若换口径会怎样 |
| --- | --- | --- | --- |
| GMV 用商品金额还是支付金额 | 商品金额 + 运费 | 支付表存在一单多条、部分订单无支付记录 | 换支付口径会少算无支付订单，金额不可比 |
| 复购用 `customer_id` 还是 `customer_unique_id` | `customer_unique_id` | 前者是"一次订单的身份" | 用前者复购率几乎为 0 |
| 复购是否限定 90/180 天窗口 | 全观察期 | Olist 数据跨度约 2 年，短窗口会低估 | 报告里必须声明，不能与别的项目直接比 |
| 评分是否先去重 | 按 `order_id` 平均后再用 | 个别订单有多条评价 | 不去重会放大这些订单的权重 |
| 州/品类/卖家分组的最小样本 | 州 ≥100 单、品类 ≥100 单、卖家 ≥30 单 | 小样本分组率值波动大 | 门槛太低会出现虚假的"最高延迟率" |

## 三、分组与分层规则

| 规则 | 阈值 | 用途 |
| --- | --- | --- |
| 州级排名 | `HAVING COUNT(*) >= 100` | `04_analysis.sql` 第 2 条 |
| 品类延迟排名 | `HAVING COUNT(*) >= 100` | 第 5 条 |
| 高延迟卖家 | `HAVING COUNT(*) >= 30`，取 Top20 | 第 6 条 |
| RFM 分层 | R：≤90 / \>180 天；F：order\_count；M：total\_revenue | Day 4，阈值需写清理由 |

## 四、引用方式

写报告或简历时统一引用本文件，例如：

> 延迟率 = 有效订单中 `delivered_ts > estimated_ts` 的占比（口径见 `reports/02_metrics_dictionary.md`）。

> 填法：Day 2 在 DataGrip 里跑完复核 SQL 后填"本项目取值"列，数字必须真实跑出，不要估算。
