#!/usr/bin/env python3
"""
test_solutions.py

Every specific number and claim in docs/common-pitfalls.md and in
solutions/*.sql is checked here against the actual built database. This
exists so the repo's teaching claims are provably true, not just asserted
in prose -- if you regenerate the seed data and one of these breaks, that's
the signal to update the docs, not to ignore the test.

Run with:
    python3 -m unittest tests/test_solutions.py -v
or simply:
    python3 tests/test_solutions.py
"""
import sqlite3
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import build_db  # noqa: E402


class SqlPowerUsersTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Always rebuild from source so tests reflect schema.sql +
        # seed_data.sql exactly as committed, not a stale local .db file.
        build_db.build()
        cls.conn = sqlite3.connect(build_db.DB_PATH)
        cls.conn.row_factory = sqlite3.Row

    @classmethod
    def tearDownClass(cls):
        cls.conn.close()

    def q(self, sql, params=()):
        return self.conn.execute(sql, params).fetchall()

    def scalar(self, sql, params=()):
        return self.conn.execute(sql, params).fetchone()[0]

    # -- Data integrity ------------------------------------------------

    def test_row_counts_are_nonzero_and_expected(self):
        counts = {
            "customers": 20,
            "employees": 6,
            "products": 15,
            "orders": 60,
            "support_tickets": 25,
        }
        for table, expected in counts.items():
            with self.subTest(table=table):
                self.assertEqual(self.scalar(f"SELECT COUNT(*) FROM {table}"), expected)

    def test_total_amount_reconciles_with_order_details(self):
        mismatches = self.scalar("""
            SELECT COUNT(*) FROM orders o
            WHERE ABS(o.total_amount - (
                SELECT COALESCE(SUM(od.quantity * od.unit_price), 0)
                FROM order_details od WHERE od.order_id = o.order_id
            )) > 0.01
        """)
        self.assertEqual(mismatches, 0,
            "orders.total_amount must always equal SUM(quantity * unit_price) "
            "for its own order_details -- the dataset must not contradict itself")

    # -- Fixtures that specific exercises depend on ---------------------

    def test_exactly_one_duplicate_customer_name_exists(self):
        dupes = self.q("""
            SELECT customer_name, COUNT(*) AS n
            FROM customers GROUP BY customer_name HAVING n > 1
        """)
        self.assertEqual(len(dupes), 1)
        self.assertEqual(dupes[0]["customer_name"], "Sarah Johnson")
        self.assertEqual(dupes[0]["n"], 2)

        ids = [r["customer_id"] for r in self.q(
            "SELECT customer_id FROM customers WHERE customer_name = 'Sarah Johnson'"
        )]
        self.assertEqual(sorted(ids), [4, 15])

    def test_exactly_two_customers_have_never_ordered(self):
        rows = self.q("""
            SELECT c.customer_id FROM customers c
            LEFT JOIN orders o ON c.customer_id = o.customer_id
            WHERE o.order_id IS NULL
        """)
        ids = sorted(r["customer_id"] for r in rows)
        self.assertEqual(ids, [19, 20])

    def test_at_least_one_employee_has_null_commission(self):
        n = self.scalar("SELECT COUNT(*) FROM employees WHERE commission IS NULL")
        self.assertGreaterEqual(n, 1)

    def test_syllabus_where_example_matches_at_least_one_order(self):
        n = self.scalar("""
            SELECT COUNT(*) FROM orders
            WHERE order_date >= '2024-01-01' AND total_amount > 1000
        """)
        self.assertGreaterEqual(n, 1)

    def test_some_orders_are_unshipped(self):
        n = self.scalar("SELECT COUNT(*) FROM orders WHERE ship_date IS NULL")
        self.assertGreaterEqual(n, 1)

    # -- Exercise 06: Cartesian product ----------------------------------

    def test_cartesian_product_row_count(self):
        employees = self.scalar("SELECT COUNT(*) FROM employees")
        products = self.scalar("SELECT COUNT(*) FROM products")
        cross = self.scalar("SELECT COUNT(*) FROM employees CROSS JOIN products")
        self.assertEqual(cross, employees * products)

    # -- Exercise 06: ON vs WHERE trap ------------------------------------

    def test_on_clause_filter_preserves_left_join(self):
        # Every customer must still appear -- LEFT JOIN's whole point.
        total_customers = self.scalar("SELECT COUNT(*) FROM customers")
        appearing = self.scalar("""
            SELECT COUNT(DISTINCT c.customer_id) FROM customers c
            LEFT JOIN orders o
                ON c.customer_id = o.customer_id
                AND o.order_date >= '2024-01-01'
        """)
        self.assertEqual(appearing, total_customers)

    def test_where_clause_filter_breaks_left_join(self):
        total_customers = self.scalar("SELECT COUNT(*) FROM customers")
        appearing = self.scalar("""
            SELECT COUNT(DISTINCT c.customer_id) FROM customers c
            LEFT JOIN orders o ON c.customer_id = o.customer_id
            WHERE o.order_date >= '2024-01-01'
        """)
        # This is the whole point of the exercise: putting the filter in
        # WHERE instead of ON silently drops customers with no matching
        # 2024 order from the result set entirely.
        self.assertLess(appearing, total_customers)

    # -- Exercise 03 Q5: join on name duplicates rows ---------------------

    def test_join_on_name_produces_more_rows_than_source_tickets(self):
        total_tickets = self.scalar("SELECT COUNT(*) FROM support_tickets")
        joined_rows = self.scalar("""
            SELECT COUNT(*) FROM support_tickets t
            INNER JOIN customers c ON t.customer_name = c.customer_name
        """)
        self.assertGreater(joined_rows, total_tickets,
            "joining on the ambiguous customer_name must produce MORE rows "
            "than tickets exist, proving the duplication bug is real")

    def test_ticket_one_matches_both_ambiguous_customers(self):
        matches = self.q("""
            SELECT c.customer_id FROM support_tickets t
            INNER JOIN customers c ON t.customer_name = c.customer_name
            WHERE t.ticket_id = 1
        """)
        ids = sorted(r["customer_id"] for r in matches)
        self.assertEqual(ids, [4, 15])

    # -- Exercise 04: NULL propagation / COALESCE -------------------------

    def test_null_commission_propagates_without_coalesce(self):
        rows = self.q("""
            SELECT e.employee_id,
                   SUM(o.total_amount) * e.commission AS projected
            FROM employees e
            LEFT JOIN orders o ON e.employee_id = o.employee_id
            WHERE e.commission IS NULL
            GROUP BY e.employee_id
        """)
        self.assertTrue(len(rows) >= 1)
        for r in rows:
            self.assertIsNone(r["projected"])

    def test_coalesce_fixes_null_propagation(self):
        rows = self.q("""
            SELECT e.employee_id,
                   SUM(o.total_amount) * COALESCE(e.commission, 0) AS projected
            FROM employees e
            LEFT JOIN orders o ON e.employee_id = o.employee_id
            WHERE e.commission IS NULL
            GROUP BY e.employee_id
        """)
        self.assertTrue(len(rows) >= 1)
        for r in rows:
            self.assertEqual(r["projected"], 0)

    # -- Exercise 04: integer vs decimal division --------------------------

    def test_integer_division_truncates(self):
        self.assertEqual(self.scalar("SELECT 7 / 2"), 3)

    def test_decimal_division_does_not_truncate(self):
        self.assertAlmostEqual(self.scalar("SELECT 7.0 / 2"), 3.5)


if __name__ == "__main__":
    unittest.main()
