-- ============================================================================
-- Exercise 03: JOINs -- the most important section.
-- Goal: teach correct table relationships. Always JOIN a foreign key to
-- the primary key it points to, and always write the ON condition
-- immediately after the JOIN. See docs/common-pitfalls.md before starting.
-- ============================================================================

-- Q1. INNER JOIN orders to customers on customer_id. Return order_id,
--     customer_name, order_date, total_amount. Use short, meaningful table
--     aliases (o, c) -- not t1/t2.

-- Q2. Extend Q1 with a second INNER JOIN to employees on employee_id, so
--     each row also shows which employee_name sold that order.

-- Q3. Find every customer who has placed ZERO orders. (Hint: this needs a
--     JOIN that keeps unmatched rows, plus a check for what "unmatched"
--     looks like on the joined side. There are exactly two such customers
--     in this dataset -- if your query returns a different number, your
--     JOIN or your WHERE placement is wrong. Re-read Common Pitfall #3.)

-- Q4. For every order, compute the running LineTotal (quantity * unit_price)
--     for each line item, and show which product it belongs to. You'll
--     need a three-table JOIN: orders -> order_details -> products.

-- Q5. THE TRAP. The support_tickets table comes from a legacy helpdesk
--     export that only ever recorded the customer's typed NAME -- it has
--     no customer_id column at all. Someone on your team wants ticket
--     counts broken out by customer, so they join it to customers the
--     only way this table allows:
--
--         SELECT t.ticket_id, t.customer_name, c.customer_id
--         FROM support_tickets t
--         INNER JOIN customers c
--             ON t.customer_name = c.customer_name;
--
--     Run it. Then run SELECT COUNT(*) FROM support_tickets by itself, and
--     compare it to COUNT(*) from the joined query above. They should be
--     equal (one ticket = one row) -- are they? Find the specific
--     ticket_id that is duplicated, and explain in a comment WHY: which
--     two customer_id values does it now match, and what real-world
--     customer_name collision in this dataset caused it (you identified
--     this exact collision back in Exercise 03 -- or look at
--     docs/common-pitfalls.md if you need a hint). Finally, explain why
--     there is no clean one-line SQL fix here -- what's actually needed is
--     upstream: getting the helpdesk system to export customer_id, not a
--     smarter JOIN.
