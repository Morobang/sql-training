# Lesson 3: SQL Joins - Advanced

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson, you will be able to:
1. Use LEFT, RIGHT, and FULL OUTER JOINs and understand NULL behavior
2. Use CROSS JOIN and SELF JOIN patterns
3. Use APPLY (CROSS APPLY / OUTER APPLY) where supported
4. Find gaps and orphaned records with outer joins
5. Avoid common outer-join pitfalls (ON vs WHERE)
6. Rewrite RIGHT JOIN as LEFT JOIN for clarity

---

## Part 1: LEFT OUTER JOIN

### Purpose

LEFT JOIN returns all rows from the left table, and matching rows from the right table. Non-matching right-side columns are NULL.

```sql
SELECT p.ProductName, s.SupplierName
FROM Products p
LEFT JOIN Suppliers s ON p.SupplierID = s.SupplierID;
```

**Use case:** Show all products even when they have no supplier.

### Find gaps (no related rows)

```sql
-- Find customers who have not placed orders
SELECT c.CustomerID, c.CustomerName
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL; -- No matching order
```

---

## Part 2: RIGHT OUTER JOIN

### Purpose

RIGHT JOIN returns all rows from the right table, and matching rows from the left table. It's the mirror of LEFT JOIN.

```sql
SELECT s.SupplierName, p.ProductName
FROM Products p
RIGHT JOIN Suppliers s ON p.SupplierID = s.SupplierID;
```

**Note:** RIGHT JOIN is less common; prefer LEFT JOIN by switching table order for readability.

---

## Part 3: FULL OUTER JOIN

### Purpose

FULL OUTER JOIN returns all rows from both tables, matching where possible and filling with NULL where not.

```sql
SELECT p.ProductName, s.SupplierName
FROM Products p
FULL OUTER JOIN Suppliers s ON p.SupplierID = s.SupplierID;
```

**Use case:** Compare two lists to find differences (audit, reconciliation).

---

## Part 4: CROSS JOIN

### Purpose

CROSS JOIN produces the Cartesian product of two tables (every combination). Rare in production; useful for test data, matrix generation.

```sql
SELECT p.ProductName, c.Country
FROM Products p
CROSS JOIN Countries c; -- All product × country combinations
```

**Warning:** Size = rows(A) × rows(B)

---

## Part 5: SELF JOIN

### Purpose

Join a table to itself to compare rows, build hierarchies, or find related records within the same table.

```sql
-- Find manager and direct reports (employees table with ManagerID FK)
SELECT e.EmployeeName AS Employee, m.EmployeeName AS Manager
FROM Employees e
LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID;
```

---

## Part 6: APPLY (SQL Server)

### CROSS APPLY / OUTER APPLY

APPLY is like a join for table-valued functions or correlated subqueries. CROSS APPLY acts like INNER JOIN; OUTER APPLY acts like LEFT JOIN.

```sql
-- Top 3 orders per customer (SQL Server)
SELECT c.CustomerID, c.CustomerName, t.OrderID, t.TotalAmount
FROM Customers c
CROSS APPLY (
    SELECT TOP 3 OrderID, TotalAmount
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) t;
```

---

## Part 7: ON vs WHERE in Outer Joins

### Important distinction

- Conditions in ON determine which right-side rows match.
- Conditions in WHERE filter the final result and can convert an outer join into an inner join.

```sql
-- Preserves customers with no orders (correct)
SELECT c.CustomerID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID AND o.OrderDate >= '2024-01-01'
WHERE o.OrderID IS NULL; -- Find customers with NO recent orders

-- If you move the date filter to WHERE, customers with only old orders will be excluded entirely:
SELECT c.CustomerID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01' OR o.OrderID IS NULL; -- different semantics
```

---

## Part 8: Practical Patterns

- Use LEFT JOIN + WHERE right_col IS NULL to find missing relationships (anti-join)
- Use EXISTS/NOT EXISTS as alternatives for semi/anti-joins
- Prefer LEFT JOIN over RIGHT JOIN for readability
- Avoid functions on join columns (prevents index use)

---

## Practice Exercises

1. Rewrite a RIGHT JOIN as a LEFT JOIN (show both versions).
2. Find products never ordered using LEFT JOIN + WHERE od.OrderID IS NULL.
3. Use OUTER APPLY to return the latest order per customer (SQL Server).

---

## Key Takeaways

- LEFT/RIGHT/FULL control preservation of rows
- ON vs WHERE matters for outer joins
- CROSS JOIN = Cartesian product
- SELF JOIN for intra-table relationships
- APPLY for correlated result sets (SQL Server)

---

## Next Lesson

Continue to [Lesson 4: Set Operators](../04-set-operators/set-operators.md).
