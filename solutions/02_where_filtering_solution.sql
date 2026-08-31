-- ============================================================================
-- Solutions: 02_where_filtering.sql
-- ============================================================================

-- Q1
SELECT
    order_id,
    order_date,
    total_amount
FROM orders
WHERE order_date >= '2024-01-01'
  AND total_amount > 1000;

-- Q2
SELECT
    customer_id,
    customer_name,
    country
FROM customers
WHERE country IN ('USA', 'Canada');

-- Q3
SELECT
    order_id,
    order_date,
    ship_date
FROM orders
WHERE ship_date IS NULL;

-- Q4
SELECT
    product_id,
    product_name,
    unit_price
FROM products
WHERE unit_price BETWEEN 50 AND 150;

-- Q5
SELECT
    customer_id,
    customer_name,
    email
FROM customers
WHERE email LIKE '%johnson%';

-- Answer: yes, this matches "Johnson" (capital J) too, in SQLite -- by
-- default SQLite's LIKE operator is case-insensitive for ASCII letters
-- (documented behavior: https://sqlite.org/lang_expr.html#the_like_glob_regexp_match_and_extract_operators).
-- Do NOT assume this generalizes: SQL Server's LIKE case-sensitivity
-- depends on the column/database collation, and other engines (e.g.
-- PostgreSQL) are case-sensitive by default and require ILIKE for this
-- behavior. Verify against the actual engine you're connected to rather
-- than porting an assumption from one database to another.
