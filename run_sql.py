"""一键运行 Olist 数据质量检查与宽表构建。

用法：
    python run_sql.py

执行内容：
1. sql/01_data_quality.sql
2. sql/02_order_wide.sql
3. sql/03_user_summary.sql
4. 将 order_wide 导出到 data/processed/order_wide.csv，供 Power BI 使用

sql/04_analysis.sql 是探索性查询，建议在 Notebook 或 DuckDB 中逐条运行。
"""

from pathlib import Path

import duckdb


ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "olist.duckdb"
PROCESSED_DIR = ROOT / "data" / "processed"

SQL_FILES = [
    "sql/01_data_quality.sql",
    "sql/02_order_wide.sql",
    "sql/03_user_summary.sql",
]


def main() -> None:
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    con = duckdb.connect(str(DB_PATH))

    for rel_path in SQL_FILES:
        sql_path = ROOT / rel_path
        print(f"Running {rel_path} ...")
        con.execute(sql_path.read_text(encoding="utf-8"))

    order_count = con.sql("SELECT COUNT(*) FROM order_wide").fetchall()[0][0]
    user_count = con.sql("SELECT COUNT(*) FROM user_summary").fetchall()[0][0]

    export_path = PROCESSED_DIR / "order_wide.csv"
    con.execute(
        f"COPY order_wide TO '{export_path.as_posix()}' (HEADER, DELIMITER ',')"
    )

    print(f"order_wide rows: {order_count}")
    print(f"user_summary rows: {user_count}")
    print(f"exported: {export_path}")
    print(f"database: {DB_PATH}")


if __name__ == "__main__":
    main()
