# Lesson 05: INTERSECT Operator - Visual Guide

## What You'll Learn
- Finding common elements between sets
- INTERSECT vs INNER JOIN
- Multiple set intersections
- Real-world overlap patterns

---

## What is INTERSECT?

**INTERSECT** returns only rows that appear in **BOTH** result sets.

```
┌────────────────────────────────────────────────────┐
│              INTERSECT Visualization               │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A (Electronics):   Set B (Expensive):         │
│  ┌───────────┐          ┌───────────┐            │
│  │ Laptop    │          │ Laptop    │            │
│  │ Mouse     │          │ Diamond   │            │
│  │ Monitor   │          │ Watch     │            │
│  │ Keyboard  │          │ Camera    │            │
│  │ Camera    │          │ Novel     │            │
│  └───────────┘          └───────────┘            │
│        ↓                      ↓                     │
│        └───── INTERSECT ──────┘                    │
│                  ↓                                  │
│            ┌──────────┐                            │
│            │ Laptop   │ ← In BOTH sets            │
│            │ Camera   │                            │
│            └──────────┘                            │
│                                                     │
│  Only items that are:                              │
│  • Electronic (in Set A) AND                       │
│  • Expensive (in Set B)                            │
└────────────────────────────────────────────────────┘
```

### Venn Diagram

```
┌────────────────────────────────────────────────────┐
│               INTERSECT Venn Diagram               │
├────────────────────────────────────────────────────┤
│                                                     │
│        Set A              Set B                    │
│      ╭─────────╮       ╭─────────╮                │
│      │         │       │         │                │
│      │    A    │███████│    B    │                │
│      │   only  │███████│   only  │                │
│      │         │███████│         │                │
│      ╰─────────╯███████╰─────────╯                │
│              Only the                              │
│            overlap area                            │
│          (A ∩ B) returned                          │
│                                                     │
│  ⚫ A only: Discarded                              │
│  ⚫ B only: Discarded                              │
│  █ Both A and B: RETURNED ✓                       │
└────────────────────────────────────────────────────┘
```

---

## INTERSECT vs AND Clause

These look similar but work differently!

```
┌────────────────────────────────────────────────────┐
│         INTERSECT vs AND Comparison                │
├────────────────────────────────────────────────────┤
│                                                     │
│  INTERSECT (comparing entire rows):                │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT ProductID FROM Products       │         │
│  │ WHERE CategoryID = 1                 │         │
│  │ INTERSECT                             │         │
│  │ SELECT ProductID FROM OrderDetails   │         │
│  │                                       │         │
│  │ Meaning:                              │         │
│  │ "Products that are electronics        │         │
│  │  AND have been ordered"               │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  AND (single query with multiple conditions):     │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT ProductID FROM Products       │         │
│  │ WHERE CategoryID = 1                 │         │
│  │   AND Price > 100                    │         │
│  │                                       │         │
│  │ Meaning:                              │         │
│  │ "Products that are electronics        │         │
│  │  AND cost over $100"                  │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Key Difference:                                   │
│  • INTERSECT: Compares two separate result sets   │
│  • AND: Multiple conditions on same rows          │
└────────────────────────────────────────────────────┘
```

---

## Finding Common Customers

```
┌────────────────────────────────────────────────────┐
│          Loyal Customer Analysis                   │
├────────────────────────────────────────────────────┤
│                                                     │
│  Customers in 2024:       Customers in 2025:       │
│  ┌────────────┐          ┌────────────┐           │
│  │ C001 John  │          │ C001 John  │ ← Both    │
│  │ C002 Sarah │          │ C003 Mike  │ ← Both    │
│  │ C003 Mike  │          │ C005 Lisa  │           │
│  │ C004 Anna  │          └────────────┘           │
│  └────────────┘                                     │
│        ↓                      ↓                     │
│        └───── INTERSECT ──────┘                    │
│                  ↓                                  │
│          ┌────────────┐                            │
│          │ C001 John  │ Ordered both years!       │
│          │ C003 Mike  │                            │
│          └────────────┘                            │
│                                                     │
│  Query:                                            │
│  SELECT CustomerID FROM Orders                     │
│  WHERE YEAR(OrderDate) = 2024                      │
│  INTERSECT                                         │
│  SELECT CustomerID FROM Orders                     │
│  WHERE YEAR(OrderDate) = 2025                      │
└────────────────────────────────────────────────────┘
```

---

## Multiple Column INTERSECT

ALL columns must match for the row to be included.

```
┌────────────────────────────────────────────────────┐
│         Multi-Column INTERSECT                     │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A (High Value Orders):                        │
│  ┌────────────┬──────────┐                        │
│  │ CustomerID │   City   │                        │
│  ├────────────┼──────────┤                        │
│  │    C001    │   NYC    │ ← Match!               │
│  │    C002    │   LA     │                        │
│  │    C003    │   NYC    │                        │
│  └────────────┴──────────┘                        │
│                                                     │
│  Set B (Recent Orders):                            │
│  ┌────────────┬──────────┐                        │
│  │ CustomerID │   City   │                        │
│  ├────────────┼──────────┤                        │
│  │    C001    │   NYC    │ ← Match!               │
│  │    C001    │   CHI    │ (Different city)       │
│  │    C004    │   NYC    │ (Different customer)   │
│  └────────────┴──────────┘                        │
│                                                     │
│  INTERSECT Result:                                 │
│  ┌────────────┬──────────┐                        │
│  │ CustomerID │   City   │                        │
│  ├────────────┼──────────┤                        │
│  │    C001    │   NYC    │ ← BOTH columns match!  │
│  └────────────┴──────────┘                        │
│                                                     │
│  Why only one row?                                 │
│  • (C002, LA) only in Set A                       │
│  • (C003, NYC) only in Set A                      │
│  • (C001, CHI) only in Set B (city differs)       │
│  • (C004, NYC) only in Set B (customer differs)   │
│  • Only (C001, NYC) in BOTH!                      │
└────────────────────────────────────────────────────┘
```

---

## INTERSECT with Three Sets

```
┌────────────────────────────────────────────────────┐
│           Three-Way INTERSECT                      │
├────────────────────────────────────────────────────┤
│                                                     │
│  Jan Orders    Feb Orders    Mar Orders            │
│  ┌─────┐      ┌─────┐      ┌─────┐               │
│  │ C01 │      │ C01 │      │ C01 │ ← All 3!       │
│  │ C02 │      │ C02 │      │ C03 │               │
│  │ C03 │      │ C04 │      │ C05 │               │
│  └─────┘      └─────┘      └─────┘               │
│     ↓            ↓            ↓                     │
│     └────────────┴───INTERSECT──┘                 │
│                  ↓                                  │
│              ┌─────┐                               │
│              │ C01 │ Ordered ALL 3 months!         │
│              └─────┘                               │
│                                                     │
│  Visual Venn (3 sets):                             │
│        ╭───────╮                                    │
│       ╱  Jan   ╲                                    │
│      │    ╭─────────╮                              │
│      │   ╱│  Feb    ╲                              │
│      │  │ │    ╭─────────╮                         │
│      │  │ │   ╱│  Mar    │                         │
│      │  │ │  │ │█████    │                         │
│      │  │ │  │ │█████    │                         │
│       ╲ │ ╲  │  ╲████   ╱                          │
│        ╲│  ╲  │   ╲───╱                            │
│         ╰───╰──┴─────╯                             │
│              █ = Center overlap (all 3)            │
│                                                     │
│  Query:                                            │
│  SELECT CustomerID FROM Orders WHERE MONTH = 1     │
│  INTERSECT                                         │
│  SELECT CustomerID FROM Orders WHERE MONTH = 2     │
│  INTERSECT                                         │
│  SELECT CustomerID FROM Orders WHERE MONTH = 3     │
└────────────────────────────────────────────────────┘
```

---

## INTERSECT vs INNER JOIN

Both find common elements, but differently!

```
┌────────────────────────────────────────────────────┐
│         INTERSECT vs INNER JOIN                    │
├────────────────────────────────────────────────────┤
│                                                     │
│  INTERSECT (set-based):                            │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT ProductID FROM Products       │         │
│  │ WHERE CategoryID = 1                 │         │
│  │ INTERSECT                             │         │
│  │ SELECT ProductID FROM OrderDetails   │         │
│  │                                       │         │
│  │ Returns: Distinct ProductIDs         │         │
│  │ ┌───────────┐                        │         │
│  │ │ ProductID │                        │         │
│  │ ├───────────┤                        │         │
│  │ │     1     │                        │         │
│  │ │     5     │                        │         │
│  │ │     7     │                        │         │
│  │ └───────────┘                        │         │
│  │ One row per product (DISTINCT)       │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  INNER JOIN (relational):                          │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT DISTINCT p.ProductID          │         │
│  │ FROM Products p                       │         │
│  │ INNER JOIN OrderDetails od            │         │
│  │   ON p.ProductID = od.ProductID      │         │
│  │ WHERE p.CategoryID = 1                │         │
│  │                                       │         │
│  │ Returns: Same result but different    │         │
│  │          execution plan               │         │
│  │ ┌───────────┐                        │         │
│  │ │ ProductID │                        │         │
│  │ ├───────────┤                        │         │
│  │ │     1     │                        │         │
│  │ │     5     │                        │         │
│  │ │     7     │                        │         │
│  │ └───────────┘                        │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  When to use INTERSECT:                            │
│  • Comparing complete rows                         │
│  • Simpler syntax for set comparisons              │
│  • When you think in terms of sets                │
│                                                     │
│  When to use INNER JOIN:                           │
│  • Need columns from multiple tables               │
│  • Complex relationships                           │
│  • Better performance (usually)                    │
└────────────────────────────────────────────────────┘
```

---

## NULL Handling in INTERSECT

INTERSECT treats NULL = NULL (different from WHERE clause!)

```
┌────────────────────────────────────────────────────┐
│             NULL in INTERSECT                      │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A:                  Set B:                    │
│  ┌──────────┐          ┌──────────┐               │
│  │  Value   │          │  Value   │               │
│  ├──────────┤          ├──────────┤               │
│  │    1     │          │    1     │               │
│  │   NULL   │          │   NULL   │               │
│  │    3     │          │    5     │               │
│  └──────────┘          └──────────┘               │
│        ↓                      ↓                     │
│        └───── INTERSECT ──────┘                    │
│                  ↓                                  │
│            ┌──────────┐                            │
│            │  Value   │                            │
│            ├──────────┤                            │
│            │    1     │                            │
│            │   NULL   │ ← NULLs match!            │
│            └──────────┘                            │
│                                                     │
│  Important:                                        │
│  • WHERE clause: NULL = NULL → UNKNOWN (false)    │
│  • INTERSECT:    NULL = NULL → TRUE ✓             │
│                                                     │
│  Example:                                          │
│  SELECT Email FROM Customers -- Includes NULLs    │
│  INTERSECT                                         │
│  SELECT Email FROM Prospects -- Includes NULLs    │
│                                                     │
│  Result: NULL emails will match!                   │
└────────────────────────────────────────────────────┘
```

---

## Real-World Use Cases

### Use Case 1: Products in Multiple Segments

```
┌────────────────────────────────────────────────────┐
│        Cross-Segment Product Analysis              │
├────────────────────────────────────────────────────┤
│                                                     │
│  Goal: Find products popular in multiple segments  │
│                                                     │
│  High-Value Customers:   Corporate Customers:      │
│  ┌───────────────┐      ┌───────────────┐        │
│  │ Laptop        │      │ Laptop        │ ← Both  │
│  │ Monitor       │      │ Monitor       │ ← Both  │
│  │ Luxury Watch  │      │ Office Chair  │        │
│  └───────────────┘      └───────────────┘        │
│                                                     │
│  Query:                                            │
│  -- Products ordered by high-value customers       │
│  SELECT DISTINCT ProductID                         │
│  FROM OrderDetails od                              │
│  JOIN Orders o ON od.OrderID = o.OrderID           │
│  WHERE o.TotalAmount > 1000                        │
│  INTERSECT                                         │
│  -- Products ordered by corporate customers        │
│  SELECT DISTINCT ProductID                         │
│  FROM OrderDetails od                              │
│  JOIN Orders o ON od.OrderID = o.OrderID           │
│  JOIN Customers c ON o.CustomerID = c.CustomerID   │
│  WHERE c.CustomerType = 'Corporate'                │
│                                                     │
│  Result: Products appealing to BOTH segments       │
│  → Target for cross-promotion!                     │
└────────────────────────────────────────────────────┘
```

### Use Case 2: Finding Overlapping Skills

```
┌────────────────────────────────────────────────────┐
│          Employee Skill Overlap                    │
├────────────────────────────────────────────────────┤
│                                                     │
│  Project A Needs:        Project B Needs:          │
│  ┌──────────┐           ┌──────────┐             │
│  │  SQL     │           │  SQL     │ ← Both       │
│  │  Python  │           │  Python  │ ← Both       │
│  │  Java    │           │  React   │             │
│  └──────────┘           └──────────┘             │
│                                                     │
│  Find employees with BOTH skill sets:              │
│                                                     │
│  SELECT EmployeeID                                 │
│  FROM EmployeeSkills                               │
│  WHERE Skill IN ('SQL', 'Python', 'Java')          │
│  GROUP BY EmployeeID                               │
│  HAVING COUNT(DISTINCT Skill) = 3                  │
│  INTERSECT                                         │
│  SELECT EmployeeID                                 │
│  FROM EmployeeSkills                               │
│  WHERE Skill IN ('SQL', 'Python', 'React')         │
│  GROUP BY EmployeeID                               │
│  HAVING COUNT(DISTINCT Skill) = 3                  │
│                                                     │
│  Result: Employees qualified for BOTH projects!    │
└────────────────────────────────────────────────────┘
```

---

## Performance Considerations

```
┌────────────────────────────────────────────────────┐
│           INTERSECT Performance                    │
├────────────────────────────────────────────────────┤
│                                                     │
│  INTERSECT Process:                                │
│  ┌─────────────────────────────────────┐          │
│  │ 1. Execute first query    (Fast)    │          │
│  │ 2. Execute second query   (Fast)    │          │
│  │ 3. Remove duplicates      (Slow)    │          │
│  │ 4. Find matching rows     (Slow)    │          │
│  │ 5. Return results         (Fast)    │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  Optimization Tips:                                │
│  ✓ Filter early (WHERE in each query)             │
│  ✓ Use indexes on compared columns                │
│  ✓ Reduce columns (only what you need)            │
│  ✓ Consider INNER JOIN alternative                │
│                                                     │
│  Performance Comparison (1M rows):                 │
│  ┌────────────────────┬──────────┐                │
│  │     Method         │   Time   │                │
│  ├────────────────────┼──────────┤                │
│  │ INTERSECT          │  2.5s    │                │
│  │ INNER JOIN         │  0.8s    │ ← Faster!      │
│  │ EXISTS             │  1.2s    │                │
│  └────────────────────┴──────────┘                │
│                                                     │
│  Use INTERSECT when:                               │
│  • Logic is clearer                                │
│  • Comparing complete rows                         │
│  • Dataset is small/medium                         │
│                                                     │
│  Use INNER JOIN when:                              │
│  • Performance critical                            │
│  • Large datasets                                  │
│  • Need additional columns                         │
└────────────────────────────────────────────────────┘
```

---

## Key Takeaways

```
✅ INTERSECT Basics:
  • Returns only rows in BOTH sets
  • Automatically removes duplicates
  • ALL columns must match
  • NULL = NULL (special behavior)

✅ Comparison:
  • vs AND: Different queries vs conditions
  • vs INNER JOIN: Set logic vs relational
  • Usually slower than JOIN

✅ Use Cases:
  • Loyal customers (multi-period)
  • Cross-segment analysis
  • Common elements between lists
  • Overlap detection

✅ Best Practices:
  • Filter early with WHERE
  • Use indexes on compared columns
  • Consider JOIN for performance
  • Mind the NULL behavior
  • Test with small datasets first
```

---

## Quick Reference

```sql
-- Basic INTERSECT
SELECT columns FROM table1 WHERE condition1
INTERSECT
SELECT columns FROM table2 WHERE condition2;

-- Three-way INTERSECT
SELECT col FROM table WHERE year = 2023
INTERSECT
SELECT col FROM table WHERE year = 2024
INTERSECT
SELECT col FROM table WHERE year = 2025;

-- Multi-column INTERSECT
SELECT CustomerID, City FROM Orders WHERE Amount > 1000
INTERSECT
SELECT CustomerID, City FROM Orders WHERE Year = 2025;

-- INTERSECT vs INNER JOIN (same result)
-- INTERSECT approach:
SELECT ProductID FROM Products WHERE CategoryID = 1
INTERSECT
SELECT ProductID FROM OrderDetails;

-- JOIN approach (usually faster):
SELECT DISTINCT p.ProductID
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE p.CategoryID = 1;
```

---

**Next:** [Lesson 06 - EXCEPT Operator](../06-except-operator/06-except-operator.sql)
