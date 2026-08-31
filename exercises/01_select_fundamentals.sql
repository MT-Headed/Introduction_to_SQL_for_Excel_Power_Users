-- ============================================================================
-- Exercise 01: SELECT Fundamentals
-- Goal: write a correct, readable SELECT statement.
--
-- Run against: db/sql_power_users.db (build it first with scripts/build_db.py)
-- Reference tables: customers, employees, products, orders, order_details
--
-- Rule for every exercise in this repo: never use SELECT *. List columns
-- explicitly, the way the course teaches -- see docs/common-pitfalls.md.
-- ============================================================================

-- Q1. List every customer's name and city only (two columns, not the whole
--     table).

-- Q2. List every product's name and unit price. Alias unit_price as "Price"
--     so the output header is friendly to a non-technical reader.

-- Q3. List the distinct list of countries customers are located in (no
--     duplicates).

-- Q4. List every order's id, order date, and total amount. Alias
--     total_amount as "OrderTotal".

-- Q5. List every employee's name and title, in a single result set, sorted
--     alphabetically by employee_name (ORDER BY wasn't covered by name in
--     the syllabus, but it's the natural next question an Excel user asks:
--     "how do I sort this?" -- same idea as an Excel sort, applied at the
--     database instead of in the grid).
