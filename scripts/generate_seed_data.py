#!/usr/bin/env python3
"""
generate_seed_data.py

Regenerates db/seed_data.sql from scratch, deterministically (fixed random
seed), so the sample dataset is reproducible instead of hand-typed.

The dataset is deliberately NOT "clean" -- it bakes in the exact situations
the course (and the exercises/solutions in this repo) call out:

  * Two different customers share the same customer_name ("Sarah Johnson"),
    to demonstrate why joining on a name instead of an ID is dangerous.
  * Two customers have zero orders, to demonstrate LEFT JOIN and the
    "filtering in WHERE silently turns a LEFT JOIN into an INNER JOIN" trap.
  * Several employees have a NULL commission (salaried staff), to
    demonstrate COALESCE and NULL propagation in arithmetic.
  * Some orders have a NULL ship_date (not yet shipped), to demonstrate
    IS NULL / IS NOT NULL.
  * orders.total_amount is computed FROM the generated order_details, so the
    denormalized total always reconciles with SUM(quantity * unit_price) --
    the sample data can't accidentally contradict itself.

Run it with: python3 scripts/generate_seed_data.py
"""
import random
from pathlib import Path

random.seed(20260831)  # deterministic output

OUT_PATH = Path(__file__).resolve().parent.parent / "db" / "seed_data.sql"

FIRST_NAMES = [
    "Sarah", "James", "Maria", "David", "Linda", "Robert", "Patricia", "John",
    "Jennifer", "Michael", "Susan", "William", "Karen", "Thomas", "Nancy",
    "Charles", "Lisa", "Daniel", "Betty", "Paul",
]
LAST_NAMES = [
    "Johnson", "Smith", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
    "Wilson", "Anderson", "Taylor", "Thomas", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Clark",
]
CITIES = [
    ("Columbus", "USA"), ("Cleveland", "USA"), ("Cincinnati", "USA"),
    ("Pittsburgh", "USA"), ("Indianapolis", "USA"), ("Louisville", "USA"),
    ("Detroit", "USA"), ("Chicago", "USA"), ("Toronto", "Canada"),
    ("Montreal", "Canada"),
]
PRODUCTS = [
    ("Standing Desk Converter", "Office Furniture", 189.99),
    ("Ergonomic Mesh Chair", "Office Furniture", 249.50),
    ("27in 4K Monitor", "Electronics", 329.00),
    ("Mechanical Keyboard", "Electronics", 89.99),
    ("Wireless Mouse", "Electronics", 34.99),
    ("USB-C Docking Station", "Electronics", 159.00),
    ("LED Desk Lamp", "Office Supplies", 42.75),
    ("Noise-Cancelling Headset", "Electronics", 199.99),
    ("Whiteboard 4x6", "Office Supplies", 74.25),
    ("Filing Cabinet 3-Drawer", "Office Furniture", 139.00),
    ("Laptop Stand", "Office Supplies", 29.99),
    ("Surge Protector", "Electronics", 24.50),
    ("Bookshelf 5-Tier", "Office Furniture", 119.99),
    ("Conference Room Speakerphone", "Electronics", 279.00),
    ("Paper Shredder", "Office Supplies", 94.99),
]
EMPLOYEE_TITLES = [
    ("Account Executive", True),
    ("Senior Account Executive", True),
    ("Sales Development Rep", True),
    ("Sales Operations Analyst", False),
    ("Sales Manager", False),
    ("Customer Success Manager", False),
]


def esc(s):
    return s.replace("'", "''")


def build_customers(n=20):
    rows = []
    used_names = set()
    for cid in range(1, n + 1):
        # Force a duplicate name on purpose: customer_id 4 and 15 are both
        # "Sarah Johnson" but are two different people/accounts.
        if cid == 4:
            name = "Sarah Johnson"
        elif cid == 15:
            name = "Sarah Johnson"
        else:
            while True:
                name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
                if name not in used_names or name == "Sarah Johnson":
                    used_names.add(name)
                    break
        city, country = random.choice(CITIES)
        email = f"{name.lower().replace(' ', '.')}{cid}@example.com"
        rows.append((cid, name, city, country, email))
    return rows


def build_employees():
    rows = []
    for eid, (title, has_commission) in enumerate(EMPLOYEE_TITLES, start=1):
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        hire_year = random.randint(2018, 2023)
        hire_date = f"{hire_year}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
        commission = round(random.uniform(0.02, 0.08), 3) if has_commission else None
        rows.append((eid, name, title, hire_date, commission))
    return rows


def build_products():
    return [(i, name, cat, price) for i, (name, cat, price) in enumerate(PRODUCTS, start=1)]


def random_date(start_year=2023, start_month=6, end_year=2024, end_month=12):
    import datetime
    start = datetime.date(start_year, start_month, 1)
    end = datetime.date(end_year, end_month, 28)
    delta_days = (end - start).days
    return start + datetime.timedelta(days=random.randint(0, delta_days))


def build_orders_and_details(customers, employees, products, n_orders=60):
    orders = []
    details = []
    detail_id = 1

    # Customers 19 and 20 deliberately get ZERO orders -- this is what makes
    # the LEFT JOIN / "customers with no orders" exercises meaningful.
    ordering_customers = [c for c in customers if c[0] not in (19, 20)]

    for order_id in range(1, n_orders + 1):
        customer = random.choice(ordering_customers)
        employee = random.choice(employees)
        order_date = random_date()

        # ~20% of orders haven't shipped yet.
        if random.random() < 0.20:
            ship_date = None
        else:
            ship_delay = random.randint(1, 10)
            ship_date = order_date + __import__("datetime").timedelta(days=ship_delay)

        n_lines = random.randint(1, 4)
        chosen_products = random.sample(products, k=n_lines)
        order_total = 0.0
        order_lines = []
        for product in chosen_products:
            pid, _, _, unit_price = product
            qty = random.randint(1, 10)
            line_total = round(qty * unit_price, 2)
            order_total += line_total
            order_lines.append((detail_id, order_id, pid, qty, unit_price))
            detail_id += 1

        order_total = round(order_total, 2)
        orders.append((
            order_id, customer[0], employee[0],
            order_date.isoformat(),
            ship_date.isoformat() if ship_date else None,
            order_total,
        ))
        details.extend(order_lines)

    # Sanity check (not a mutation): the syllabus's WHERE example is
    # `OrderDate >= '2024-01-01' AND TotalAmount > 1000`. With 60 randomly
    # generated orders spread across 2023-06..2024-12 this condition is
    # satisfied naturally many times over -- verified by
    # tests/test_solutions.py -- so we deliberately do NOT hand-patch a row
    # here. Every total_amount is a real SUM(quantity * unit_price) of its
    # own order_details, with no exceptions.
    assert any(o[3] >= "2024-01-01" and o[5] > 1000 for o in orders), (
        "regenerate with a different seed: no order satisfies the WHERE demo"
    )

    return orders, details


ISSUE_TYPES = [
    "Billing question", "Shipping delay", "Damaged item", "Login issue",
    "Return request", "Product question", "Invoice request",
]


def build_support_tickets(customers, n=25):
    """
    Simulates a legacy helpdesk export that only ever captured the
    customer's NAME, never their customer_id. Deliberately includes at
    least one ticket for "Sarah Johnson" -- the name shared by two
    different customer_id values -- so joining this table to customers on
    customer_name (instead of an ID that doesn't exist in this feed)
    demonstrably produces duplicated rows.
    """
    rows = []
    names = [c[1] for c in customers]
    # Guarantee at least one ticket explicitly for the ambiguous name.
    forced = [(1, "Sarah Johnson", "Billing question", "2024-02-10")]
    rows.extend(forced)
    for ticket_id in range(2, n + 1):
        name = random.choice(names)
        issue = random.choice(ISSUE_TYPES)
        d = random_date(2023, 6, 2024, 12)
        rows.append((ticket_id, name, issue, d.isoformat()))
    return rows


def sql_value(v):
    if v is None:
        return "NULL"
    if isinstance(v, str):
        return f"'{esc(v)}'"
    if isinstance(v, float):
        return f"{v:.2f}"
    return str(v)


def render_inserts(table, columns, rows):
    lines = []
    for row in rows:
        values = ", ".join(sql_value(v) for v in row)
        lines.append(f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({values});")
    return "\n".join(lines)


def main():
    customers = build_customers()
    employees = build_employees()
    products = build_products()
    orders, details = build_orders_and_details(customers, employees, products)
    tickets = build_support_tickets(customers)

    sql = []
    sql.append("-- ============================================================================")
    sql.append("-- seed_data.sql")
    sql.append("-- Deterministically generated sample data. Do not hand-edit -- regenerate with")
    sql.append("-- scripts/generate_seed_data.py if you need to change the dataset.")
    sql.append("-- ============================================================================\n")

    sql.append("-- Customers (note: customer_id 4 and 15 share the SAME name on purpose --")
    sql.append("-- see docs/common-pitfalls.md, Pitfall #1: joining on the wrong key).")
    sql.append(render_inserts(
        "customers", ["customer_id", "customer_name", "city", "country", "email"], customers
    ))
    sql.append("")

    sql.append("-- Employees (commission is NULL for salaried roles -- see the COALESCE exercise).")
    sql.append(render_inserts(
        "employees", ["employee_id", "employee_name", "title", "hire_date", "commission"], employees
    ))
    sql.append("")

    sql.append("-- Products.")
    sql.append(render_inserts(
        "products", ["product_id", "product_name", "category", "unit_price"], products
    ))
    sql.append("")

    sql.append("-- Orders (customer_id 19 and 20 deliberately have NO orders -- see the")
    sql.append("-- LEFT JOIN and 'filtering in WHERE vs ON' exercises).")
    sql.append(render_inserts(
        "orders",
        ["order_id", "customer_id", "employee_id", "order_date", "ship_date", "total_amount"],
        orders,
    ))
    sql.append("")

    sql.append("-- Order details (Quantity * UnitPrice is the running LineTotal example).")
    sql.append(render_inserts(
        "order_details",
        ["order_detail_id", "order_id", "product_id", "quantity", "unit_price"],
        details,
    ))
    sql.append("")

    sql.append("-- Support tickets: name-only legacy feed, no customer_id available.")
    sql.append("-- Ticket 1 is deliberately for the ambiguous 'Sarah Johnson' -- see")
    sql.append("-- exercises/03_joins.sql, Q5.")
    sql.append(render_inserts(
        "support_tickets",
        ["ticket_id", "customer_name", "issue_type", "opened_date"],
        tickets,
    ))
    sql.append("")

    OUT_PATH.write_text("\n".join(sql) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_PATH} ({len(customers)} customers, {len(employees)} employees, "
          f"{len(products)} products, {len(orders)} orders, {len(details)} order lines, "
          f"{len(tickets)} support tickets)")


if __name__ == "__main__":
    main()
