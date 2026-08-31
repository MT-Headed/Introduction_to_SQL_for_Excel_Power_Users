-- ============================================================================
-- Solutions: 03_joins.sql
-- ============================================================================

-- Q1
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.total_amount
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id;

-- Q2
SELECT
    o.order_id,
    c.customer_name,
    e.employee_name,
    o.order_date,
    o.total_amount
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN employees e
    ON o.employee_id = e.employee_id;

-- Q3
-- LEFT JOIN keeps every customer, even those with no matching order. A
-- customer with no orders produces a row where every orders.* column,
-- including order_id, comes back NULL -- that's the signal to filter on.
-- Note the filter is on order_id IS NULL, checked AFTER the join executes
-- conceptually -- this is not the "filtering the right table of a LEFT
-- JOIN in WHERE" trap, because we are filtering on the ABSENCE of a match,
-- which only IS NULL can express, not filtering out a real value.
SELECT
    c.customer_id,
    c.customer_name
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Q4
SELECT
    o.order_id,
    p.product_name,
    od.quantity,
    od.unit_price,
    od.quantity * od.unit_price AS LineTotal
FROM orders o
INNER JOIN order_details od
    ON o.order_id = od.order_id
INNER JOIN products p
    ON od.product_id = p.product_id
ORDER BY o.order_id;

-- Q5: the name-only join, and proof it duplicates rows
SELECT
    t.ticket_id,
    t.customer_name,
    c.customer_id
FROM support_tickets t
INNER JOIN customers c
    ON t.customer_name = c.customer_name
ORDER BY t.ticket_id;

-- Row-count proof:
SELECT
    (SELECT COUNT(*) FROM support_tickets) AS total_tickets,
    (SELECT COUNT(*)
       FROM support_tickets t
       INNER JOIN customers c ON t.customer_name = c.customer_name) AS joined_rows;
-- total_tickets = 25, joined_rows = 28 -- three EXTRA rows appeared out of
-- nowhere. Every ticket for "Sarah Johnson" (there's at least one,
-- ticket_id 1, guaranteed by the seed generator) now matches BOTH
-- customer_id 4 and customer_id 15, because the join condition only
-- compares the name string and this dataset has two different customers
-- who happen to share that exact name (see Exercise 03, and
-- docs/common-pitfalls.md, Pitfall #1). Any COUNT(*) or SUM() built on top
-- of this join -- "tickets per customer," "total ticket volume" -- is now
-- silently wrong for both of those customers, with no error from SQL.
--
-- Why there's no clean SQL fix: customer_name is not a stable, unique
-- identifier in this dataset -- two real customers share it. No amount of
-- clever JOIN syntax can tell those two "Sarah Johnson"s apart using only
-- the name string, because the information that would disambiguate them
-- (which customer_id placed the ticket) was never captured by the
-- upstream helpdesk export. The correct fix is a data-engineering one:
-- get customer_id added to the ticket export at the source. Until then,
-- any join on customer_name should be flagged as provisional/unreliable
-- rather than "fixed" in SQL.
