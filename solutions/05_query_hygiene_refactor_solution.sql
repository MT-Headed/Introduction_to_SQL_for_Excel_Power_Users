-- ============================================================================
-- Solution: 05_query_hygiene_refactor.sql
-- ============================================================================

-- Refactored query:

-- Orders over $500, used for the weekly "large orders" review.
-- NOTE: the $500 threshold is a placeholder business rule -- confirm with
-- whoever owns this report before relying on it; it is not defined
-- anywhere in the source schema.
SELECT
    o.order_id,
    o.order_date,
    o.total_amount,
    c.customer_name
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.total_amount > 500;

-- Problems in the original query:
--   1. SELECT * instead of explicit columns -- fragile against future
--      schema changes and pulls unnecessary columns.
--   2. Implicit comma-join ("FROM orders t1, customers t2 WHERE ...")
--      instead of an explicit INNER JOIN ... ON -- this is functionally
--      an old, deprecated join syntax. It still works, but it buries the
--      relationship inside the WHERE clause where it's easy to miss or
--      accidentally delete, which is how Cartesian products happen (see
--      docs/common-pitfalls.md, Pitfall #2).
--   3. Aliases t1/t2 convey nothing -- o (orders) and c (customers) tell
--      the reader what each alias means without needing to scroll up.
--   4. Single unformatted line -- one clause/column per line with
--      capitalized keywords makes the JOIN structure and filter logic
--      visible at a glance, which is the whole point of formatting (it's
--      not cosmetic).
--   5. No comment explaining the business meaning of ">500" -- a bare
--      magic number in a WHERE clause is a maintenance trap for whoever
--      inherits this query.
