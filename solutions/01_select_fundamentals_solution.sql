-- ============================================================================
-- Solutions: 01_select_fundamentals.sql
-- ============================================================================

-- Q1
SELECT
    customer_name,
    city
FROM customers;

-- Q2
SELECT
    product_name,
    unit_price AS Price
FROM products;

-- Q3
SELECT DISTINCT
    country
FROM customers;

-- Q4
SELECT
    order_id,
    order_date,
    total_amount AS OrderTotal
FROM orders;

-- Q5
SELECT
    employee_name,
    title
FROM employees
ORDER BY employee_name ASC;
