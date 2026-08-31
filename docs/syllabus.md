# Course Syllabus: Introduction to SQL for Excel Power Users

**Format:** 2-hour live session (recorded)
**Audience:** Excel developers/analysts — formulas, PivotTables, and Power Query familiarity assumed
**Outcome:** Attendees can connect to a SQL Server database and write simple, reliable data-retrieval queries

## Learning objectives

By the end of the session, participants can:

- Understand what SQL is and when to use it instead of Excel
- Connect to a SQL Server database using SSMS or Azure Data Studio
- Write basic `SELECT` statements
- Retrieve specific columns from tables
- Filter data using the `WHERE` clause
- Join multiple tables correctly
- Perform simple calculations and aliases
- Read and reason about existing SQL queries

## 1. The SQL mindset: thinking in tables, not cells

Coming from Excel, you already understand data well — SQL just asks you to think about it differently. Excel encourages thinking in cells and formulas; SQL encourages thinking in tables and relationships. This is a shift in mental model, not a jump in difficulty.

**What SQL is (and isn't).** SQL — Structured Query Language — is a language for asking questions of structured data. It is not a general-purpose programming language like Python or C#, and it is not procedural: you don't tell it *how* to loop through rows. SQL is declarative — you describe the result set you want, and the database engine figures out how to produce it.

**Why this course is read-only.** In production, SQL is powerful enough to modify or delete millions of rows in seconds. This course intentionally restricts scope to `SELECT` statements: you're learning data retrieval, not data manipulation, so nothing here can put real data at risk.

**SQL vs. Excel vs. Power Query.** These three sit at different points in the data pipeline. Excel is best for exploration, modeling, and presentation — formula-driven, and data is often duplicated or imported. Power Query is excellent for shaping and transforming data, pulling it into Excel or Power BI — but it still operates *after* the data has been extracted. SQL works at the source: it asks the database for exactly the rows and columns you need, reducing data movement and duplication. SQL is where you go when you want fewer rows, fewer columns, and cleaner data before it ever hits Excel.

**Tables, rows, and columns ≠ sheets and cells.** A table is not a worksheet — it's a structured list. A row has no inherent order unless you explicitly ask for one (there is no such thing as "row 5" until you `ORDER BY` something). A column represents a single attribute across all rows.

**The core Excel-to-SQL analogies** (the anchor of this whole course — see `docs/excel-to-sql-cheatsheet.md` for the full version):

| Excel concept | SQL concept |
|---|---|
| Worksheet | Table |
| Field / column header | Column |
| Record / row | Row |
| Filter | `WHERE` clause |
| XLOOKUP / VLOOKUP, Power Query merge | `JOIN` |

## 2. Tools & connectivity overview

**SQL Server architecture, at a high level.** Think of SQL Server as a secure, centralized filing cabinet for structured data. The *engine* is the service running somewhere (on-prem or cloud) that stores data and executes queries. A single server hosts many *databases*, usually grouped by application, department, or purpose. *Tables* inside those databases are where the actual data lives. You are not connecting to "a server full of raw files" — you're connecting to a managed system designed to safely answer questions, the way a shared, protected, enterprise workbook lets thousands of people read the same data at once.

**Databases, schemas, and tables.** The hierarchy, top-down: **Server** hosts many **databases**; a **database** is a logical container for related data; a **schema** is a namespace (a "folder") inside the database; a **table** is where rows and columns live. Naming follows `schema.TableName` — `dbo.Customers` and `sales.Orders` are not "two tables," they're one table each, qualified with a schema. Schemas are organizational, not a security boundary by default.

**Live demo walkthrough** (as delivered in the original session): connect to a server using Windows Authentication; expand a database and confirm you're in the correct one before writing any query; locate a table under "Tables"; view its column list and data types to understand what fields exist — you don't need to memorize data types on day one, just what columns are available.

## 3. SELECT fundamentals

**Goal:** write a correct, readable `SELECT` query.

```sql
SELECT column1, column2
FROM schema.TableName;
```

Key concepts: why `SELECT *` is tempting but discouraged; column order matters in the result set; fully-qualified names (`schema.table`); aliasing columns with `AS`.

```sql
SELECT
    CustomerID,
    CustomerName,
    City
FROM dbo.Customers;
```

*Excel tie-in:* this is the SQL equivalent of choosing which columns are visible in a table.

## 4. Filtering with `WHERE`

**Goal:** control row selection precisely.

Core concepts: `WHERE` clause order of execution; comparison operators (`=`, `<>`, `>`, `<`); logical operators (`AND`, `OR`); `IN`, `BETWEEN`, `LIKE`; handling `NULL`s (`IS NULL`, `IS NOT NULL`).

```sql
SELECT
    OrderID,
    OrderDate,
    TotalAmount
FROM dbo.Orders
WHERE OrderDate >= '2024-01-01'
  AND TotalAmount > 1000;
```

*Excel analogies:* AutoFilter; `IF` + logical tests; text filters (begins with, contains).

## 5. JOINs — the most important section

JOINs aren't an advanced feature; they're the core of relational databases. Once JOINs click, SQL starts to feel very similar to Excel data models and Power Pivot.

**Why tables are split (normalization).** SQL databases intentionally split data across multiple tables: each table stores one type of thing, repeated information is stored once, and relationships connect the tables. Instead of storing the customer name on every order row, customers live in one table and orders in another. This reduces duplication, prevents inconsistencies, and improves performance — normalization trades convenience for correctness, and JOINs give the convenience back.

**The Excel data model parallel.** If you've built an Excel Data Model, used Power Pivot, or worked with a cube, you already understand normalization: fact tables (Orders, Transactions) and dimension tables (Customers, Products, Dates), with relationships and measures on top. A SQL JOIN is the manual equivalent of the relationship you define once in an Excel data model — in Excel, relationships are persistent and visual; in SQL, they're expressed explicitly in every query.

**Primary keys vs. foreign keys.** A primary key uniquely identifies a row in a table (`CustomerID`, `OrderID`, `ProductID`). A foreign key is how one table points to another (`Orders.CustomerID → Customers.CustomerID`). You almost always join from a foreign key to a primary key.

**One-to-many relationships.** One customer can have many orders; one order belongs to exactly one customer. When you JOIN these tables, the result set grows based on the "many" side — JOINs don't just add columns, they can multiply rows.

**JOIN types covered:**
- **INNER JOIN** returns only rows where both tables match (analogous to an XLOOKUP where a match exists, or a Power Query inner join).
- **LEFT JOIN** (most common) keeps everything from the left table, even with no match on the right (analogous to XLOOKUP wrapped in `IFERROR`, or a Power Query left outer join). *If you're ever unsure which JOIN to use, start with LEFT JOIN.*
- **When not to JOIN at all** — exploring a single table, validating row counts, or profiling columns don't need a JOIN. Unnecessary JOINs are a common source of slow queries and incorrect results.

```sql
SELECT
    o.OrderID,
    c.CustomerName,
    o.TotalAmount
FROM dbo.Orders o
INNER JOIN dbo.Customers c
    ON o.CustomerID = c.CustomerID;
```

`FROM` establishes the base table; `JOIN` adds related data; `ON` defines how rows match. **`ON` answers how tables relate. `WHERE` answers which rows you want** — conflating the two is the single most common JOIN mistake, and it's covered in full in `docs/common-pitfalls.md`.

## 6. Basic calculations & expressions

Still read-only, still safe — this section is about shaping data, not writing it back anywhere.

**Calculations happen per row.** In SQL, expressions are evaluated row by row unless you explicitly aggregate — there's no dragging formulas or cell references, an expression just applies uniformly across every row, the way one Excel formula would if it auto-applied to an entire table at once.

```sql
SELECT
    OrderID,
    Quantity * UnitPrice AS LineTotal
FROM dbo.OrderDetails;
```

This does not store the value anywhere — the calculated column exists only in the query's result set (presentation logic, not storage). Aliases (`AS`) give calculated columns meaningful names instead of an unreadable default, and are effectively required for any downstream tool (Excel, Power BI) consuming the result.

**Functions covered:**
- `ROUND(expression, decimal_places)` — exactly Excel's `ROUND`.
- `COALESCE(expression, default)` — substitutes a default value when SQL encounters `NULL`. `NULL` is not zero; it means "no value exists," and any arithmetic involving `NULL` returns `NULL`. `COALESCE` is the SQL equivalent of `IFERROR` / `IF(ISBLANK())`, and is how you make SQL behave more like Excel when data is incomplete.

**Common gotchas** (time-permitting in the original session, covered in depth in `docs/common-pitfalls.md` and Exercise 04 here): division by zero, integer vs. decimal division, and NULL propagation.

## 7. Query hygiene & common mistakes

At this point you can already write working SQL — this section is about writing SQL that other people (including future you) can understand and trust. Good hygiene doesn't make queries faster by itself, but it makes them safer, easier to debug, and easier to reuse. Most SQL errors in practice are not syntax errors; they're logic errors caused by poor habits.

Covered in full, with runnable proof, in `docs/common-pitfalls.md`:

- Always list columns explicitly (never `SELECT *`)
- Use short, meaningful table aliases
- Format queries so JOIN structure and filter logic are visible at a glance
- Comment SQL to explain *why*, not *what*
- The most common JOIN errors: missing JOIN conditions (Cartesian products), filtering joined tables in the wrong clause, confusing `NULL` with empty strings, and date literals vs. text
