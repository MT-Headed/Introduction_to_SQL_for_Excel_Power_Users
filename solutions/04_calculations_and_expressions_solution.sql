-- ============================================================================
-- Solutions: 04_calculations_and_expressions.sql
-- ============================================================================

-- Q1
SELECT
    order_detail_id,
    order_id,
    quantity,
    unit_price,
    quantity * unit_price AS LineTotal
FROM order_details;

-- Q2
SELECT
    ROUND(AVG(unit_price), 2) AS AvgPrice
FROM products;

-- Q3
SELECT
    employee_name,
    COALESCE(commission, 0) AS Commission
FROM employees;

-- Q4a: without COALESCE -- any employee with a NULL commission ends up
-- with a NULL projected earnings, even though they clearly sold real
-- orders (their total_sales is a real number). This is NULL propagation:
-- real_number * NULL = NULL, always.
SELECT
    e.employee_name,
    e.commission,
    SUM(o.total_amount) AS total_sales,
    SUM(o.total_amount) * e.commission AS projected_earnings_no_coalesce
FROM employees e
LEFT JOIN orders o
    ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.employee_name, e.commission;

-- Q4b: with COALESCE -- salaried employees (NULL commission) now correctly
-- show 0 projected commission earnings instead of NULL.
SELECT
    e.employee_name,
    e.commission,
    SUM(o.total_amount) AS total_sales,
    SUM(o.total_amount) * COALESCE(e.commission, 0) AS projected_earnings
FROM employees e
LEFT JOIN orders o
    ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.employee_name, e.commission;

-- Q5
SELECT 7 / 2 AS integer_division;      -- returns 3 (truncated, not rounded)
SELECT 7.0 / 2 AS decimal_division;    -- returns 3.5
SELECT CAST(7 AS REAL) / 2 AS decimal_division_via_cast;  -- also 3.5

-- Explanation: SQLite is dynamically typed per-value. When BOTH operands
-- of "/" are integers, the result is computed as integer division and the
-- fractional part is discarded (not rounded) -- 7/2 is 3, not 3.5 and not
-- 4. As soon as EITHER operand is a real number (7.0, or an explicit
-- CAST ... AS REAL), the whole expression is evaluated as real-number
-- division. This matches the general SQL behavior described in the course
-- ("Common Gotchas": integer vs decimal division) -- T-SQL/SQL Server
-- behaves the same way based on the declared column types (INT vs
-- DECIMAL/FLOAT). Reference: SQLite datatype rules,
-- https://sqlite.org/datatype3.html#operators
