# Query Hygiene & Common Pitfalls

This is the most important reference document in the repo. Every claim below is either demonstrated live against the sample database in `exercises/06_pitfalls_demo.sql` / `solutions/06_pitfalls_demo_solution.sql`, checked automatically in `tests/test_solutions.py`, or backed by a linked primary source. Nothing here is asserted on vibes.

## Why hygiene matters

In Excel, messy formulas still calculate — they're just painful to maintain. SQL is the same. Queries get shared, copy-pasted, and outlive their original author. Most SQL errors in production are not syntax errors; they're logic errors caused by poor habits.

### Best practice 1: always list columns explicitly

`SELECT *` is convenient and is also one of the most common causes of broken reports: columns can be added to a table later, column order can change, performance suffers from pulling unneeded data, and downstream tools can break silently when the result set's shape changes without warning. Write SQL as if someone else depends on the column order, because they usually do.

### Best practice 2: use short, meaningful table aliases

As soon as you JOIN more than one table, fully-qualified names become unreadable. `o` for `orders`, `c` for `customers` — short, intuitive, consistent. Aliases like `t1`, `t2`, `x` don't help anyone reading the query later.

### Best practice 3: format queries cleanly

This isn't cosmetic — formatting makes JOIN structure, WHERE logic, and column lineage visible at a glance. One column per line, keywords capitalized, JOINs aligned, indentation reflecting logic. If your SQL is hard to read, it's hard to trust.

### Best practice 4: comment your SQL

Comments should explain *why* something exists, not *what* it does (the code already says what). Use comments to explain business logic, call out assumptions, and warn about edge cases — the same instinct as annotating a complex Excel formula.

## Pitfall 1: joining on the wrong key

The most common JOIN error is technically valid SQL that produces logically wrong data. Typical causes: joining on names instead of IDs, joining on non-unique fields, or joining on partially-matching data. The rule: **always join on stable, unique identifiers** — if you wouldn't use a column as a primary key in Excel, don't join on it in SQL.

This repo proves the failure mode rather than just describing it. `db/schema.sql` includes a `support_tickets` table modeled on a real, common situation: a legacy helpdesk export that only ever recorded the customer's typed name, never a `customer_id`. Two different customers in the sample data are both named "Sarah Johnson" (`customer_id` 4 and 15). Joining `support_tickets` to `customers` on `customer_name` — the only join this legacy feed allows — causes every ticket for "Sarah Johnson" to match *both* customer rows, silently inflating the joined result: 25 source tickets become 28 joined rows. See `exercises/03_joins.sql` Q5 and `solutions/03_joins_solution.sql`, verified by `tests/test_solutions.py::test_join_on_name_produces_more_rows_than_source_tickets`.

## Pitfall 2: Cartesian products

A Cartesian product happens when SQL matches every row in one table to every row in another — typically caused by a missing JOIN condition, an incorrect `ON` clause, or a JOIN with no relationship at all. SQL will happily do this; it assumes you meant it. 10,000 rows joined to 5,000 rows becomes 50 million rows, with no error or warning.

Demonstrated in `exercises/06_pitfalls_demo.sql` Q1: `employees CROSS JOIN products` on this dataset (6 employees, 15 products) produces exactly 90 meaningless rows — verified in `tests/test_solutions.py::test_cartesian_product_row_count`. If your row count explodes unexpectedly, suspect a Cartesian product; the preventive habit is to always write the JOIN condition immediately after the JOIN.

## Pitfall 3: filtering in `WHERE` vs. `ON` (the most subtle one)

**`ON` controls how tables relate. `WHERE` controls which rows survive after the join.** Filtering the *right-hand table of a LEFT JOIN* in the `WHERE` clause silently turns it back into an `INNER JOIN`, because `WHERE` evaluates after the join has already produced its `NULL`-filled rows for unmatched records — and a condition like `orders.order_date >= '2024-01-01'` is never true for a `NULL` value, so those "no match" rows get discarded along with everything else that fails the filter.

This repo proves the effect with real numbers, not just an explanation. In `exercises/06_pitfalls_demo.sql` Q2 / `solutions/06_pitfalls_demo_solution.sql`, filtering "orders placed in 2024" inside the `ON` clause correctly keeps all 20 customers in the result (including the ones with zero qualifying orders); moving the identical filter into `WHERE` drops 4 of those 20 customers from the result set entirely, with no error. Verified by `tests/test_solutions.py::test_on_clause_filter_preserves_left_join` and `::test_where_clause_filter_breaks_left_join`. The fix: filters on the right table of a LEFT JOIN usually belong in the `ON` clause, not `WHERE`.

## Error: confusing `NULL` with an empty string

`NULL` means "no value exists." An empty string `''` means "a value exists, but it's empty." These are not the same thing, and `NULL = ''` is never true — in fact `NULL` compared to *anything* with `=`, including another `NULL`, evaluates to `UNKNOWN` rather than `TRUE` or `FALSE`, which is why `WHERE column = NULL` silently returns zero rows instead of raising an error. Use `IS NULL` / `IS NOT NULL` to test for it, and `COALESCE` to substitute a default when arithmetic or display needs a real value instead.

> "No two null values are equal. Comparisons between two null values, or between a null value and any other value, return unknown because the value of each NULL is unknown. [...] To test for null values in a query, use IS NULL or IS NOT NULL in the WHERE clause." — [NULL and UNKNOWN (Transact-SQL), Microsoft Learn](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/null-and-unknown-transact-sql)

## Error: date literals vs. text

Dates look like text, but they aren't, and typing one as a plain string invites regional-format ambiguity and silent implicit-conversion errors (is `03/04/2024` March 4th or April 3rd?). The safe habit is to always use the unseparated or hyphenated ISO 8601 format, `YYYY-MM-DD`, which every mainstream SQL engine interprets consistently regardless of server language or locale settings.

> "yyyy-MM-dd [and] yyyyMMdd [...] Same as the SQL standard. This format is the only format defined as an international standard. [...] A six-digit or eight-digit string is always interpreted as ymd [regardless of locale]." — [date (Transact-SQL), Microsoft Learn](https://learn.microsoft.com/en-us/sql/t-sql/data-types/date-transact-sql)

## Engine-specific gotcha: `LIKE` case sensitivity

This course's exercises run on SQLite, and SQLite's default `LIKE` case-sensitivity is a real (if minor) trap if you assume it behaves identically everywhere:

> "SQLite only understands upper/lower case for ASCII characters by default. The LIKE operator is case sensitive by default for unicode characters that are beyond the ASCII range. For example, the expression `'a' LIKE 'A'` is TRUE but `'æ' LIKE 'Æ'` is FALSE." — [SQL As Understood By SQLite: Expressions, sqlite.org](https://www.sqlite.org/lang_expr.html)

In practice: `LIKE '%johnson%'` will match "Johnson" in SQLite (ASCII letters are case-folded), which is convenient here — but don't assume that generalizes. SQL Server's `LIKE` case-sensitivity depends on the column/database collation, and PostgreSQL's `LIKE` is case-sensitive by default (it provides a separate `ILIKE` for case-insensitive matching). Verify against the actual engine you're connected to.

## Engine-specific gotcha: comparing mismatched column types

SQLite is dynamically typed per value rather than strictly typed per column, which changes what "wrong" looks like when you make a type-mismatched join mistake. Comparing an `INTEGER`-affinity column to a `TEXT`-affinity column does not raise an error in SQLite — SQLite instead applies numeric affinity to the text side of the comparison, and if that text can't be converted to a number, the comparison is simply false for every row (not "wrong matches," just zero matches):

> "If one operand has INTEGER, REAL or NUMERIC affinity and the other operand has TEXT or BLOB or no affinity then NUMERIC affinity is applied to the other operand. [...] An INTEGER or REAL value is less than any TEXT or BLOB value." — [Datatypes In SQLite, sqlite.org](https://sqlite.org/datatype3.html)

This is worth knowing precisely because it's a case where SQLite's forgiving type system produces a *quieter* failure (a query that just returns nothing) than a strictly-typed engine would (which would typically raise a type-mismatch error at parse time). Either way, the lesson from Pitfall 1 stands: don't join on a column that wasn't designed to be a unique identifier.

## Integer vs. decimal division

When both operands of `/` are integers, SQL engines commonly perform integer division and truncate (not round) the fractional part: `7 / 2` returns `3`, not `3.5`. Making one operand a decimal/real value (`7.0 / 2`, or an explicit `CAST`) restores normal decimal division. Verified in `tests/test_solutions.py::test_integer_division_truncates` and `::test_decimal_division_does_not_truncate`; see `exercises/04_calculations_and_expressions.sql` Q5.
