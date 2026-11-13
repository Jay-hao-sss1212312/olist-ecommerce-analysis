# 01\_data\_quality

# 数据体检记录（Day 1）

记录日期：2026-11-13　｜　数据来源：Kaggle Olist Brazilian E-Commerce Public Dataset（9 个 CSV）　｜　复现方式：项目根目录运行 `python run_sql.py` 后，按本文第 1 节的 SQL 在 DataGrip 中逐条复核。

## 一、七项检查结果

| # | 检查项 | SQL 取数口径 | 本次结果 | 说明与影响 |
| --- | --- | --- | --- | --- |
| 1 | 订单状态分布 | `order_wide` 按 `order_status` 计数 | delivered **96,478**；其余状态合计 **2,963** | 只有 delivered 计入有效订单，占 **97.02%**；其余 2.98% 全部排除。原填 2,958，补回 `created` 的 5 单后为 2,963 |
| 2 | 订单时间范围 | `MIN/MAX(purchase_ts)` | **2016-09-04 21:15:19** 至 **2018-10-17 17:30:18** | 跨度约 25 个月；首尾月份不完整，趋势图按月聚合时要标注，不做首尾环比 |
| 3 | 送达时间缺失 | `delivered_ts IS NULL` 的订单数 | **2,965** 单 | 占全部订单 2.98%。这些单无法计算配送天数，`late_flag` 因两个时间不全而记为 0 |
| 4 | 唯一用户数 | `COUNT(DISTINCT customer_unique_id)` from `user_summary` | **93,358** 人 | 复购分析的分母。该表只含 delivered 有效订单且 `customer_unique_id` 非空的用户，因此小于 `customers` 表全量独立用户数 |
| 5 | 有评分的订单数 | `review_score IS NOT NULL` | **98,673** 单 | 覆盖 99.23%，评分分析样本充足；**768** 单无评价，算均分时必须排除 |
| 6 | 一单多条评价 | `MAX(review_count)` | **3** | 确实存在一单 3 条评价，`02_order_wide.sql` 已先按 `order_id` 聚合取均值再连接，避免了重复加权 |
| 7 | 有支付记录的订单数 | `payment_value IS NOT NULL` | **99,440** 单 | 仅 1 单无支付记录；支付表 103,886 行对应 99,440 单，说明一单多条支付，GMV 不能用支付金额口径 |

### 填完后的三项自检结果

1. **第 1 项**：96,478 + 2,963 = 99,441，与订单总数一致。初次填写为 2,958（合计 99,436，差 5 单），原因是状态分布里 `created` 的 5 单未计入，已修正。
2. **第 4 项口径**：93,358 是 `user_summary` 的有效订单口径，不是 `customers` 表全量独立用户数（约 9.6 万）。这是 `03_user_summary.sql` 先过滤 `delivered` 再按用户分组的结果，不是跑错；报告与简历里凡出现"复购分母"都指这个数。
3. **第 3、7 项**：2,965 单缺送达时间、1 单无支付记录，均已在第 3 节口径中声明为排除项或已知处理方式，延迟率与 GMV 的分母不会被质疑。

## 二、体检结论

**能否继续做分析**：能，但下面三条限制要带进后面每一步。

99,441 笔订单里只有 96,478 笔是 delivered，占 97.02%。剩下 2,963 笔是 shipped、canceled 这类没送完的单，后面 GMV、客单价、延迟率都只算这 96,478 笔。

缺送达时间的 2,965 单主要是本来就没送完的订单，不是数据出错。真正 delivered 却缺送达时间的只有极少数；`late_flag` 要求送达和预计两个时间都非空才算延迟，这几单被记成 0，占比极小，不影响州级排名，但报告口径里必须写一句。延迟率的分母按 `04_analysis.sql` 第 2 条的 `WHERE order_status = 'delivered'` 走，即 96,478 单，不拿 99,441 减 2,965。

96,478 笔有效订单对应 93,358 个用户，人均 1.03 单，绝大多数人只买过一次。所以这个项目不回答"怎么提升复购"，只回答"复购的人有什么不一样、延迟交付是不是伴着更低的评分和更低的复购"。

## 三、由此确定的口径

| 指标 | 本项目口径 |
| --- | --- |
| 有效订单 | `order_status = 'delivered'`，共 96,478 单 |
| GMV | `SUM(item_revenue + freight_value)`，按 `order_id` 去重汇总；不使用 `payment_value` |
| 客单价 | `AVG(item_revenue + freight_value)`，分母为有效订单 |
| 延迟交付 | `delivered_ts > estimated_ts`，且两个时间都非空；否则 `late_flag = 0` |
| 延迟率分母 | `04_analysis.sql` 第 2 条实际为 `WHERE order_status = 'delivered'`，即 96,478 单；缺时间订单因 `late_flag = 0` 计入分母，占比极小 |
| 复购 | 同一 `customer_unique_id` 有 ≥2 笔有效订单，`user_summary.is_repeat = 1` |
| 复购观察窗口 | **全观察期（2016-09 至 2018-10），不另设 90/180 天窗口** |
| 评分 | 按 `order_id` 聚合去重后的 `review_score` 均值，排除无评价订单 |

> 窗口统一说明：`03_user_summary.sql` 没有做任何时间窗口过滤，是在全部有效订单上按用户分组的，所以本项目复购口径就是全观察期。若报告写"采用 90 天窗口"，会与 `user_summary` 的实际算法对不上。`reports/02_metrics_dictionary.md` 与本表一致。

### 复现用 SQL

```sql
-- 第 1 节七项检查（DataGrip 连 olist.duckdb 后逐条执行）
SELECT order_status, COUNT(*) AS order_count FROM order_wide GROUP BY 1 ORDER BY 2 DESC;
SELECT MIN(purchase_ts), MAX(purchase_ts) FROM order_wide;
SELECT COUNT(*) FILTER (WHERE delivered_ts IS NULL) AS missing_delivered FROM order_wide;
SELECT COUNT(DISTINCT customer_unique_id) FROM user_summary;
SELECT COUNT(*) FILTER (WHERE review_score IS NOT NULL) FROM order_wide;
SELECT MAX(review_count) FROM order_wide;
SELECT COUNT(*) FILTER (WHERE payment_value IS NOT NULL) FROM order_wide;

-- 若需采用"两个时间都非空"的严格口径，用它复核延迟率分母
SELECT COUNT(*) AS strict_late_denominator
FROM order_wide
WHERE order_status = 'delivered'
  AND delivered_ts IS NOT NULL
  AND estimated_ts IS NOT NULL;
```

## 四、发现的问题与处理方式

| 问题 | 处理方式 | 是否影响结论 |
| --- | --- | --- |
| 支付表一单多条（103,886 行 / 99,440 单） | 先按 `order_id` 求和再左连接 | 已处理；不影响金额，影响行数 |
| 评价表一单多条（最大 3 条） | 按 `order_id` 聚合取均值 | 已处理；不去重会放大这些订单的权重 |
| 商品明细一单多行（112,650 行 / 99,441 单） | 聚合到订单级，品类与卖家拼成字符串 | 已处理；不聚合会重复计算 GMV |
| 品类名部分缺失 | 统一归为 `unknown`，在报告中说明 | 不影响整体趋势 |
| 地理表 100 万行 | 本版不用，地区分析用 `customer_state` | 不影响 |
| 首尾月份订单量不完整 | 趋势图标注为不完整月份 | 影响环比解读，不影响绝对水平 |
| delivered 但缺送达时间的极少数订单 | `late_flag` 记为 0 | 占比极小，不影响州级延迟率排名 |
| 状态分布里 `created` 仅 5 单 | 计入"其余状态"合计 | 只影响自检，不影响任何分析指标 |
