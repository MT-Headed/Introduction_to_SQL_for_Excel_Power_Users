#!/usr/bin/env python3
"""
build_db.py

Builds db/sql_power_users.db from db/schema.sql + db/seed_data.sql.

Zero third-party dependencies -- sqlite3 ships in the Python standard
library, so this runs anywhere Python 3 runs (Windows, macOS, Linux),
with no server to install and nothing to configure.

Usage:
    python3 scripts/build_db.py
"""
import sqlite3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = REPO_ROOT / "db" / "schema.sql"
SEED_PATH = REPO_ROOT / "db" / "seed_data.sql"
DB_PATH = REPO_ROOT / "db" / "sql_power_users.db"


def build():
    if not SCHEMA_PATH.exists() or not SEED_PATH.exists():
        print(f"ERROR: expected {SCHEMA_PATH} and {SEED_PATH} to exist.", file=sys.stderr)
        sys.exit(1)

    # Start clean every time so this script is safely re-runnable.
    if DB_PATH.exists():
        DB_PATH.unlink()

    conn = sqlite3.connect(DB_PATH)
    try:
        conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
        conn.executescript(SEED_PATH.read_text(encoding="utf-8"))
        conn.commit()

        # Sanity check row counts so a silent failure doesn't go unnoticed.
        counts = {}
        for table in ("customers", "employees", "products", "orders", "order_details", "support_tickets"):
            counts[table] = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    finally:
        conn.close()

    print(f"Built {DB_PATH.relative_to(REPO_ROOT)}")
    for table, count in counts.items():
        print(f"  {table:<15} {count:>4} rows")


if __name__ == "__main__":
    build()
