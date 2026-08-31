-- ============================================================================
-- Solution: 06_pitfalls_demo.sql
-- Row counts below were verified against db/sql_power_users.db as built by
-- scripts/build_db.py from the seed data in this repo, and are re-checked
-- automatically in tests/test_solutions.py. If you regenerate the seed
-- data with a different random seed, these exact numbers may change --
-- the SHAPE of the result (fewer/zero rows in the WHERE version) will not.
-- ============================================================================

-- Q1: Cartesian product
SELECT COUNT(*) AS row_count
FROM employees
CROSS JOIN products;
-- Result: 90 (= 6 employees * 15 products). No relationship exists between
-- these two tables, so SQL matched every row to every row, exactly as
-- warned about in docs/common-pitfalls.md, Pitfall #2. Now imagine this
-- with 10,000 orders and 5,000 order_details instead of 6 and 15 -- that's
-- 50 million meaningless rows, computed silently, with no error.

-- Q2(a): filter in the ON clause -- correctly preserves the LEFT JOIN
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS order_count_2024
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name
HAVING order_count_2024 = 0;
-- Result: 4 customers (ids 4, 15, 19, 20) -- all 20 customers are still
-- present in the join; these four simply have zero rows meeting the 2024
-- filter (customers 19/20 have never ordered anything; customers 4/15
-- happen to have no orders dated 2024-01-01 or later in this dataset).

-- Q2(b): filter in the WHERE clause -- silently breaks the LEFT JOIN
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS order_count_2024
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name
HAVING order_count_2024 = 0;
-- Result: 0 rows returned -- and more importantly, only 16 of the 20
-- customers appear in this query's result set AT ALL (verify with
-- SELECT COUNT(DISTINCT customer_id) ... using the same WHERE clause).
-- The WHERE clause runs AFTER the join produces its NULL-filled rows for
-- unmatched customers, and "o.order_date >= '2024-01-01'" is false for a
-- NULL order_date -- so those rows, including all 4 customers with no
-- qualifying 2024 orders, are discarded before GROUP BY ever sees them.
-- The LEFT JOIN keyword is still sitting right there in the query, but the
-- WHERE clause has functionally turned it into an INNER JOIN. This is
-- exactly Common Pitfall #3: "filters on the right table of a LEFT JOIN
-- usually belong in the ON clause."
