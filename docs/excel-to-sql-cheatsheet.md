# Excel → SQL Cheatsheet

The course syllabus calls this section "the anchor" — if you remember nothing else, remember these translations. Every other concept in this course is built on top of them.

| Excel term | SQL term | The translation |
|---|---|---|
| Worksheet | **Table** | A SQL table is like a worksheet — but without formatting, merged cells, or formulas. |
| Field (column header) | **Column** | A column represents a single piece of information, like `CustomerName` or `OrderDate`. |
| Row | **Record** | Each row is one complete record — one customer, one order, one transaction. |
| Filter | **`WHERE`** | The `WHERE` clause is the SQL equivalent of applying a filter in Excel. |
| XLOOKUP / VLOOKUP | **`JOIN`** | JOINs combine related tables — similar to XLOOKUP, but faster, safer, and able to handle one-to-many relationships. |
| Power Query merge | **`JOIN`** | If Power Query merges make sense to you, JOINs will make sense — they're the same idea. |
| `IFERROR(XLOOKUP(...), "")` | **`LEFT JOIN`** | A LEFT JOIN keeps every row from the left table even when nothing matches on the right — exactly what wrapping a lookup in `IFERROR` is compensating for. |
| Power Query inner join | **`INNER JOIN`** | Keeps only the rows where both sides match — nothing is kept unless there's a match on both sides. |
| Power Query left outer join | **`LEFT JOIN`** | Same idea, same name, same behavior. |
| Renaming a calculated column header | **`AS` (alias)** | `Quantity * UnitPrice AS LineTotal` — this is how you give a calculated column a name someone else can understand. |
| Excel Data Model / Power Pivot relationships | **Normalization + `JOIN`** | In Excel, the relationship between fact and dimension tables is defined once, persistently, and visually. In SQL, that same relationship must be expressed explicitly, in every query, via `JOIN ... ON`. |
| `IF(ISBLANK(x), 0, x)` | **`COALESCE(x, 0)`** | Substitutes a default value when SQL encounters `NULL`. |
| A truly blank cell | **`NULL`** | Not the same as an empty string `''`. See `docs/common-pitfalls.md`, Error #3. |
| Dragging a formula down a column | **(nothing — it's automatic)** | SQL expressions apply to every row by default; there's no equivalent of "drag to fill," because there's no such thing as applying a formula to only some rows. |

## The one line to remember

> **`ON` answers how tables relate. `WHERE` answers which rows you want.**

Every JOIN mistake in `docs/common-pitfalls.md` ultimately comes back to mixing these two questions up.

## Worked example, side by side

**Excel / Power Query mental model:** "Look up each order's customer name with XLOOKUP, wrapped in IFERROR in case the customer record is missing."

**SQL:**

```sql
SELECT
    o.OrderID,
    o.TotalAmount,
    c.CustomerName
FROM dbo.Orders o
LEFT JOIN dbo.Customers c
    ON o.CustomerID = c.CustomerID;
```

`LEFT JOIN` is the `IFERROR` here: if a customer record is missing, the query still returns the order row, just with `CustomerName` coming back `NULL` instead of erroring out or dropping the row entirely.
