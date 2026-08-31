-- ============================================================================
-- schema.sql
-- Sample "sales" database for the "Introduction to SQL for Excel Power Users"
-- course. Modeled on the schema used in the live course materials
-- (dbo.Customers, dbo.Orders, dbo.OrderDetails, dbo.Employees), flattened to
-- SQLite so it runs anywhere with zero setup.
--
-- If you're following along in SQL Server / Azure Data Studio instead, the
-- only real differences are: no schema prefix (dbo.), TEXT instead of
-- NVARCHAR, and REAL instead of DECIMAL. The query logic is identical.
-- ============================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- Dimension table: one row per customer.
CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   TEXT NOT NULL,
    city            TEXT NOT NULL,
    country         TEXT NOT NULL,
    email           TEXT
);

-- Dimension table: one row per employee. commission is intentionally NULL
-- for salaried staff -- this is what powers the COALESCE exercises.
CREATE TABLE employees (
    employee_id     INTEGER PRIMARY KEY,
    employee_name   TEXT NOT NULL,
    title           TEXT NOT NULL,
    hire_date       TEXT NOT NULL,   -- ISO-8601 'YYYY-MM-DD'
    commission      REAL             -- NULL = no commission plan (salaried)
);

-- Dimension table: one row per sellable product.
CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category        TEXT NOT NULL,
    unit_price      REAL NOT NULL
);

-- Fact table: one row per order header. total_amount is denormalized here
-- (pre-aggregated) on purpose, to match the course's WHERE-clause examples
-- ("TotalAmount > 1000") without requiring a JOIN + GROUP BY on day one.
CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers(customer_id),
    employee_id     INTEGER NOT NULL REFERENCES employees(employee_id),
    order_date      TEXT NOT NULL,   -- ISO-8601 'YYYY-MM-DD'
    ship_date       TEXT,            -- NULL = not yet shipped
    total_amount    REAL NOT NULL
);

-- Fact table: one row per line item on an order. Quantity * unit_price is
-- the running example used throughout the "Calculations & Expressions"
-- section (LineTotal).
CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id),
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    quantity        INTEGER NOT NULL,
    unit_price      REAL NOT NULL
);

-- Support tickets, imported from a fictional legacy helpdesk system that
-- only ever exported the customer's typed NAME, never a customer_id. This
-- table exists specifically to make Exercise 03, Q5 (joining on the wrong
-- key) reproducible on real, realistic data instead of a contrived example
-- -- this is exactly how the "join on name" mistake happens in practice:
-- someone is handed a feed that simply doesn't have the ID.
CREATE TABLE support_tickets (
    ticket_id       INTEGER PRIMARY KEY,
    customer_name   TEXT NOT NULL,   -- NOTE: name only, no customer_id
    issue_type      TEXT NOT NULL,
    opened_date     TEXT NOT NULL
);

-- Index every foreign key. SQLite does NOT do this automatically (unlike
-- the primary key side), and an un-indexed foreign key is one of the most
-- common causes of a slow JOIN once a table grows past toy size.
CREATE INDEX idx_orders_customer_id       ON orders(customer_id);
CREATE INDEX idx_orders_employee_id       ON orders(employee_id);
CREATE INDEX idx_order_details_order_id   ON order_details(order_id);
CREATE INDEX idx_order_details_product_id ON order_details(product_id);
