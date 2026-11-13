# SQL 文件说明

本项目使用 DuckDB，直接读取 `data/raw/` 下的 CSV。

| 文件 | 作用 |
|---|---|
| `01_data_quality.sql` | 数据体检：行数、状态、缺失、重复 |
| `02_order_wide.sql` | 构建订单级宽表 `order_wide` |
| `03_user_summary.sql` | 构建用户级汇总表 `user_summary` |
| `04_analysis.sql` | 经营、履约、评分、复购分析查询 |

运行顺序不能颠倒。`02` 和 `03` 会创建表，后续可以直接查询。

最简单的方式是在项目根目录运行：

```bash
python run_sql.py
```

它会自动执行 `01`、`02`、`03`，并导出 `data/processed/order_wide.csv`。`04_analysis.sql` 留给 Notebook 逐条探索。
