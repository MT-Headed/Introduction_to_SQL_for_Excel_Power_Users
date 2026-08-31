-- ============================================================================
-- Exercise 04: Basic Calculations & Expressions
-- Goal: shape data with row-by-row expressions -- still read-only, still
-- safe. Nothing here writes anything back to the database.
-- ============================================================================

-- Q1. For every order line, compute LineTotal = quantity * unit_price.
--     Alias it as LineTotal. Remember: this value exists only in the
--     result set, not in the table.

-- Q2. Compute the average unit_price across all products, rounded to 2
--     decimal places using ROUND(). Alias the result as AvgPrice.

-- Q3. Every employee has a commission column, but it's NULL for salaried
--     staff. Select employee_name and commission, but use COALESCE to show
--     0 instead of NULL wherever commission is missing. Alias the result
--     as Commission.

-- Q4. Now go one step further: for every employee, compute their
--     "projected commission earnings" as the SUM of total_amount across
--     all the orders they've sold, multiplied by their commission rate.
--     Do this TWICE:
--       (a) without COALESCE -- watch what happens to salaried employees
--       (b) with COALESCE(commission, 0) -- confirm salaried employees now
--           show 0 instead of NULL
--     This demonstrates NULL propagation: any arithmetic touching a NULL
--     returns NULL, it does not treat NULL as zero.

-- Q5. Common gotcha: integer division. In SQLite (and most SQL engines),
--     dividing two INTEGER values truncates the decimal portion.
--     Demonstrate this by computing 7 / 2 directly (no table needed), then
--     compute it again as 7.0 / 2 or CAST(7 AS REAL) / 2. Compare the two
--     results in a comment.
