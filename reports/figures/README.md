# 图表目录规范

所有分析图与 Dashboard 截图都放这个目录，**不要散落在 notebook 或项目根目录**。文件名固定后，README 和报告里的引用路径才不会失效。

## 命名规则

`两位数序号_内容_维度.png`，全小写英文 + 下划线，不用中文、不用空格。看板截图用 `dashboard_<页名>.png`。

## 图表清单

| 文件名 | 来源 | 图表类型 | 口径 / 注意 |
|---|---|---|---|
| `01_monthly_gmv.png` | `04_analysis.sql` 第 1 条 | GMV 与订单量双轴折线 | 仅 `delivered`，n=96,478；GMV = 商品金额 + 运费（千 BRL，左轴），订单量读右轴；**首尾月不完整**，2016-11 无订单 |
| `02_late_rate_by_state.png` | `04_analysis.sql` 第 2 条 | 各州延迟率 Top10 横向条形 | 订单级分组，`HAVING COUNT(*) >= 100`；可与整体 8.11% 直接相减 |
| `03_review_by_late.png` | `04_analysis.sql` 第 3 条 | 延迟 / 非延迟平均评分对比柱状 | `review_score IS NOT NULL`，有效样本 95,832 单；差 1.73 分是**伴随关系**，非因果 |
| `04_late_rate_by_category.png` | `04_analysis.sql` 第 5 条 | 品类延迟率 Top10 条形 | `UNNEST` 拆品类，分母是「品类-订单对」，**不可与 8.11% 相减**；`unknown` 为翻译表未匹配的兜底值，非真实品类 |
| `05_high_late_sellers.png` | `04_analysis.sql` 第 6 条 | 高延迟卖家 Top20 条形 | `HAVING COUNT(*) >= 30`；`n` 是「卖家-订单对」，18/20 家不足 100 单；卖家 ID 为哈希、图上仅显示前 8 位 |
| `06_repeat_rate_by_state.png` | `04_analysis.sql` 第 4 条 + 手册 4.2 的 JOIN | 各州复购率横向条形 | 分母为去重用户 `customer_unique_id`（93,358 人），各州 ≥100 用户；虚线为整体 3.00% |
| `07_rfm_segments.png` | 手册 4.3 | 各层人数与收入占比双面板 | R ≤90 / >180 天、F ≥2、M >500 / >300 绝对阈值；红色为手册指定的召回目标层 |
| `dashboard_overview.png` | Power BI 第 1 页 | 看板截图 | 经营总览；README 首屏引用这一张 |
| `dashboard_delivery.png` | Power BI 第 2 页 | 看板截图 | 履约体验 |
| `dashboard_retention.png` | Power BI 第 3 页 | 看板截图 | 用户复购 |

## 出图要求

- 分辨率：`dpi=150`，宽度 10—12 英寸，保证 GitHub 上点开清晰。
- 中文标题：matplotlib 需先设字体，Windows 下用 `plt.rcParams['font.sans-serif'] = ['Microsoft YaHei']`，否则中文显示成方块。
- 每张图必须带**标题 + 单位 + 数据口径注释**（如"仅 delivered 订单，n=xx"），分组排名图每条标注 `n`。
- 图里不放结论文字，结论写进 `reports/olist_analysis_memo.md`。
- Notebook 在 `notebooks/` 下，保存路径写 `../reports/figures/<文件名>.png`；写成 `reports/figures/...` 会多建一层空目录。

## 提交说明

- `.png` 不在 `.gitignore` 中，会被正常提交；`.pbix` 被排除，所以 Dashboard **只交三张截图和 `dashboard/README.md`**。
- 提交前跑 `git status`，确认 `*.csv`、`olist.duckdb`、`.pbix`、原始 CSV 都没混进来。
