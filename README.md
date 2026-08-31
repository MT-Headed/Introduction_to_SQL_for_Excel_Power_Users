# SQL for Excel Power Users

A hands-on SQL course, originally delivered as a 2-hour live training session for Excel analysts (formulas, PivotTables, Power Query) moving into SQL Server. 

## Who this is for

Analysts who are strong in Excel — comfortable with formulas, PivotTables, and Power Query — and need to read and write basic, safe (read-only) SQL against a relational database. No prior programming background assumed.

## What's in this repo

| Path | What it is |
|---|---|
| `docs/syllabus.md` | The full course outline and learning objectives |
| `docs/excel-to-sql-cheatsheet.md` | The Excel → SQL mental-model translations the course is built around |
| `docs/common-pitfalls.md` | The JOIN pitfalls, query hygiene rules, and common errors section, with sources |
| `db/schema.sql` | Table definitions for the sample "sales" database (SQLite) |
| `db/seed_data.sql` | Deterministic sample data (customers, employees, products, orders, order line items, and a legacy support-ticket feed) |
| `scripts/generate_seed_data.py` | Regenerates `seed_data.sql` from scratch, deterministically |
| `scripts/build_db.py` | Builds a runnable `.db` file from the schema + seed data |
| `exercises/` | Six exercise sets, one per course section, as `.sql` files with the prompts written in as comments |
| `solutions/` | Fully worked solutions for every exercise, with explanatory comments |
| `tests/test_solutions.py` | Automated tests that verify every specific claim made in the docs and solutions against the real data |

## Why SQLite

The original course was taught against SQL Server (via SSMS / Azure Data Studio), and `docs/syllabus.md` preserves that framing. This repo's runnable code targets **SQLite** instead, on purpose: it ships with Python, needs no server, no install, and no credentials — clone the repo and everything below just works. The query logic (SELECT, WHERE, JOIN, COALESCE, etc.) is standard SQL and transfers directly to SQL Server, PostgreSQL, or any other relational engine; the handful of places where SQLite's behavior genuinely differs (type affinity, `LIKE` case-sensitivity, integer division) are called out explicitly in `docs/common-pitfalls.md` and in the exercises, not glossed over.

## Getting started

Requires Python 3.8+ only — no packages to install.

```bash
git clone <this-repo-url>
cd sql-for-excel-power-users

# Build the sample database from schema.sql + seed_data.sql
python3 scripts/build_db.py

# Open it with the sqlite3 CLI (ships with Python on most systems)
sqlite3 db/sql_power_users.db

# Or query it with the Python standard library
python3 -c "
import sqlite3
conn = sqlite3.connect('db/sql_power_users.db')
for row in conn.execute('SELECT customer_name, city FROM customers LIMIT 5'):
    print(row)
"
```

Then work through `exercises/01_select_fundamentals.sql` through `exercises/06_pitfalls_demo.sql` in order — each one builds on ideas from the last. Solutions live in `solutions/`, but the point is to write your own query first and only compare afterward.

To confirm everything in this repo is internally consistent (schema, seed data, and every worked solution actually produce the numbers the docs claim they do):

```bash
python3 -m unittest tests/test_solutions.py -v
```

## Sample schema at a glance

```
customers ──< orders ──< order_details >── products
    │
    └──< support_tickets   (legacy feed: name only, no customer_id —
                             see docs/common-pitfalls.md, Pitfall #1)

employees ──< orders
```

`orders.total_amount` is intentionally denormalized (pre-aggregated) to match the course's WHERE-clause examples, but it's generated to always reconcile exactly with `SUM(quantity * unit_price)` from `order_details` — verified in `tests/test_solutions.py`.

## Course outline

See [`docs/syllabus.md`](docs/syllabus.md) for the full breakdown. In short, the course covers:

1. **The SQL mindset** — thinking in tables and relationships instead of cells and formulas
2. **Tools & connectivity** — SQL Server architecture, and the Server → Database → Schema → Table hierarchy
3. **SELECT fundamentals** — column selection, aliasing, fully-qualified names
4. **Filtering with WHERE** — comparison/logical operators, `IN`, `BETWEEN`, `LIKE`, `NULL` handling
5. **JOINs** — normalization, primary/foreign keys, `INNER` vs `LEFT` JOIN, and the three most common JOIN mistakes
6. **Calculations & expressions** — row-by-row arithmetic, aliasing, `ROUND`, `COALESCE`, and NULL propagation
7. **Query hygiene** — why `SELECT *` and unreadable formatting cause real production bugs, not just style complaints

## A note on scope

This course — and every exercise in this repo — is deliberately restricted to `SELECT` (read-only data retrieval). It does not cover `INSERT`, `UPDATE`, `DELETE`, or schema changes. That's a feature of the original course design, not a limitation of the SQL language: it lets a beginner run anything here against a real database without any risk of damaging it.

## License

MIT — see [`LICENSE`](LICENSE).
