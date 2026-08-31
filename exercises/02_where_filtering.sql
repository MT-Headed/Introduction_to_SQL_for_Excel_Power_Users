-- ============================================================================
-- Exercise 02: Filtering with WHERE
-- Goal: control row selection precisely -- the SQL equivalent of AutoFilter.
-- ============================================================================

-- Q1. Find all orders placed on or after 2024-01-01 with a total_amount
--     greater than 1000. (This is the exact example from the course
--     syllabus.) Use the ISO date format 'YYYY-MM-DD' -- see
--     docs/common-pitfalls.md, Error #4.

-- Q2. Find all customers located in either 'USA' or 'Canada' using IN
--     instead of chained OR conditions.

-- Q3. Find all orders that have NOT shipped yet (ship_date IS NULL).
--     Remember: NULL is not a value you can compare with '=' -- see
--     docs/common-pitfalls.md, Error #3.

-- Q4. Find all products priced between $50 and $150 (inclusive) using
--     BETWEEN.

-- Q5. Find all customers whose email address contains "johnson" using
--     LIKE. Then answer in a comment: does this also match "Johnson"
--     (capital J)? Why or why not, in SQLite specifically? (Case
--     sensitivity of LIKE is engine-dependent -- SQL Server's default
--     collation is case-insensitive, SQLite's LIKE is case-insensitive
--     only for ASCII by default. Verify what you see instead of assuming.)
