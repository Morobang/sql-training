# Lesson 04: UNION Operator - Visual Guide

## What You'll Learn
- Combining results from multiple queries
- UNION vs UNION ALL differences
- Column compatibility requirements
- Real-world UNION patterns

---

## What is UNION?

**UNION** combines results from two or more queries into a single result set, automatically removing duplicates.

```
┌────────────────────────────────────────────────────┐
│                 UNION Visualization                │
├────────────────────────────────────────────────────┤
│                                                     │
│  Query A Results:        Query B Results:          │
│  ┌──────────┐           ┌──────────┐              │
│  │ Laptop   │           │ Novel    │              │
│  │ Mouse    │           │ Cookbook │              │
│  │ Keyboard │           │ Monitor  │              │
│  └──────────┘           └──────────┘              │
│        ↓                      ↓                     │
│        └──────── UNION ───────┘                    │
│                  ↓                                  │
│         ┌──────────────┐                           │
│         │ Laptop       │                           │
│         │ Mouse        │                           │
│         │ Keyboard     │                           │
│         │ Novel        │                           │
│         │ Cookbook     │                           │
│         │ Monitor      │                           │
│         └──────────────┘                           │
│         All unique values                          │
└────────────────────────────────────────────────────┘
```

---

## UNION vs UNION ALL

The key difference: **duplicate handling**

```
┌────────────────────────────────────────────────────┐
│           UNION vs UNION ALL                       │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A: {1, 2, 3}                                 │
│  Set B: {2, 3, 4}                                 │
│                                                     │
│  UNION (removes duplicates):                       │
│  ┌─────────────────────────────────┐              │
│  │  A ∪ B = {1, 2, 3, 4}          │              │
│  │                                  │              │
│  │  Values 2 and 3 appear once     │              │
│  │  (duplicates removed)            │              │
│  └─────────────────────────────────┘              │
│                                                     │
│  UNION ALL (keeps duplicates):                     │
│  ┌─────────────────────────────────┐              │
│  │  Result = {1, 2, 3, 2, 3, 4}   │              │
│  │                                  │              │
│  │  Values 2 and 3 appear twice    │              │
│  │  (duplicates kept)               │              │
│  └─────────────────────────────────┘              │
│                                                     │
│  Performance:                                      │
│  • UNION: Slower (sorts to remove duplicates)     │
│  • UNION ALL: Faster (no duplicate check)         │
└────────────────────────────────────────────────────┘
```

### Visual Example

```
Query A: CategoryID from Products WHERE CategoryID = 1
┌────────────┐
│ CategoryID │
├────────────┤
│      1     │
│      1     │
│      1     │
└────────────┘

Query B: CategoryID from Products WHERE CategoryID = 1
┌────────────┐
│ CategoryID │
├────────────┤
│      1     │
│      1     │
│      1     │
└────────────┘

UNION:              UNION ALL:
┌────────────┐     ┌────────────┐
│ CategoryID │     │ CategoryID │
├────────────┤     ├────────────┤
│      1     │     │      1     │
└────────────┘     │      1     │
   1 row            │      1     │
                    │      1     │
                    │      1     │
                    │      1     │
                    └────────────┘
                       6 rows
```

---

## UNION Requirements

All queries in a UNION must follow these rules:

```
┌────────────────────────────────────────────────────┐
│              UNION Requirements                    │
├────────────────────────────────────────────────────┤
│                                                     │
│  ✅ REQUIRED:                                      │
│  1. Same number of columns                         │
│  2. Compatible data types (column-by-column)       │
│  3. Same column order                              │
│                                                     │
│  ❌ NOT REQUIRED:                                  │
│  • Same table names                                │
│  • Same column names                               │
│  • Same WHERE conditions                           │
│                                                     │
│  Column Names:                                     │
│  • Taken from FIRST query only                     │
│  • Second query's names ignored                    │
└────────────────────────────────────────────────────┘
```

### Examples

```
✅ VALID: Same column count and compatible types

SELECT ProductID, ProductName FROM Products
         ↓           ↓
       INT       VARCHAR
UNION
SELECT CategoryID, CategoryName FROM Categories
         ↓             ↓
       INT         VARCHAR

Result columns: ProductID (INT), ProductName (VARCHAR)


❌ INVALID: Different column counts

SELECT ProductID, ProductName, Price FROM Products
         3 columns
UNION
SELECT CategoryID, CategoryName FROM Categories
         2 columns
ERROR: Column count doesn't match!


✅ FIX: Add placeholder column

SELECT ProductID, ProductName, Price FROM Products
UNION
SELECT CategoryID, CategoryName, NULL AS Price FROM Categories
                                   ↑ Placeholder
```

---

## Combining Different Tables

```
┌────────────────────────────────────────────────────┐
│         Combining Heterogeneous Data               │
├────────────────────────────────────────────────────┤
│                                                     │
│  Customers Table:       Products Table:            │
│  ┌────┬─────────┐      ┌────┬──────────┐         │
│  │ ID │  Name   │      │ ID │   Name   │         │
│  ├────┼─────────┤      ├────┼──────────┤         │
│  │ 1  │  John   │      │ 1  │  Laptop  │         │
│  │ 2  │  Sarah  │      │ 2  │  Mouse   │         │
│  └────┴─────────┘      └────┴──────────┘         │
│                                                     │
│  Add Type Indicator:                               │
│  SELECT ID, Name, 'Customer' AS Type               │
│  FROM Customers                                    │
│  UNION                                             │
│  SELECT ID, Name, 'Product'                        │
│  FROM Products                                     │
│                                                     │
│  Result:                                           │
│  ┌────┬──────────┬──────────┐                    │
│  │ ID │   Name   │   Type   │                    │
│  ├────┼──────────┼──────────┤                    │
│  │ 1  │  John    │ Customer │                    │
│  │ 2  │  Sarah   │ Customer │                    │
│  │ 1  │  Laptop  │ Product  │                    │
│  │ 2  │  Mouse   │ Product  │                    │
│  └────┴──────────┴──────────┘                    │
└────────────────────────────────────────────────────┘
```

---

## UNION with NULL Handling

```
┌────────────────────────────────────────────────────┐
│              Handling Missing Columns              │
├────────────────────────────────────────────────────┤
│                                                     │
│  Products have Price, Customers don't:             │
│                                                     │
│  SELECT                                            │
│      ProductID AS ID,                              │
│      ProductName AS Name,                          │
│      Price,                    ← Has value        │
│      NULL AS Email             ← No email         │
│  FROM Products                                     │
│  UNION                                             │
│  SELECT                                            │
│      CustomerID,                                   │
│      FirstName + ' ' + LastName,                   │
│      NULL AS Price,            ← No price         │
│      Email                     ← Has value        │
│  FROM Customers                                    │
│                                                     │
│  Result:                                           │
│  ┌────┬──────────┬───────┬──────────────┐        │
│  │ ID │   Name   │ Price │    Email     │        │
│  ├────┼──────────┼───────┼──────────────┤        │
│  │ 1  │  Laptop  │  800  │    NULL      │        │
│  │ 2  │  Mouse   │   25  │    NULL      │        │
│  │ 1  │  John    │ NULL  │ john@co.com  │        │
│  │ 2  │  Sarah   │ NULL  │ sara@co.com  │        │
│  └────┴──────────┴───────┴──────────────┘        │
└────────────────────────────────────────────────────┘
```

---

## Performance: UNION vs UNION ALL

```
┌────────────────────────────────────────────────────┐
│           Performance Comparison                   │
├────────────────────────────────────────────────────┤
│                                                     │
│  Scenario: 1000 rows in each query                │
│                                                     │
│  UNION:                                            │
│  ┌─────────────────────────────────────┐          │
│  │ Step 1: Execute Query A   (0.01s)   │          │
│  │ Step 2: Execute Query B   (0.01s)   │          │
│  │ Step 3: Combine results   (0.02s)   │          │
│  │ Step 4: Sort for DISTINCT (0.15s)   │          │
│  │ Step 5: Remove duplicates (0.08s)   │          │
│  │ ─────────────────────────────────    │          │
│  │ Total:                     0.27s     │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  UNION ALL:                                        │
│  ┌─────────────────────────────────────┐          │
│  │ Step 1: Execute Query A   (0.01s)   │          │
│  │ Step 2: Execute Query B   (0.01s)   │          │
│  │ Step 3: Combine results   (0.02s)   │          │
│  │ ─────────────────────────────────    │          │
│  │ Total:                     0.04s     │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  UNION ALL is ~6-7x faster!                        │
│  (Skips sorting and duplicate removal)             │
└────────────────────────────────────────────────────┘
```

### When to Use Each

```
Use UNION when:
✓ You need unique rows only
✓ Duplicates would cause problems
✓ Combining master lists
✓ Data integrity is critical

Use UNION ALL when:
✓ No duplicates possible (different time periods)
✓ Duplicates are acceptable
✓ Performance is priority
✓ Large datasets (millions of rows)
```

---

## ORDER BY with UNION

```
┌────────────────────────────────────────────────────┐
│              Sorting UNION Results                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  ❌ WRONG: ORDER BY in individual queries          │
│  SELECT * FROM Products                            │
│  WHERE CategoryID = 1                              │
│  ORDER BY ProductName  ← ERROR!                    │
│  UNION                                             │
│  SELECT * FROM Products                            │
│  WHERE CategoryID = 2                              │
│  ORDER BY ProductName  ← ERROR!                    │
│                                                     │
│  ✅ CORRECT: ORDER BY after all UNIONs             │
│  SELECT * FROM Products                            │
│  WHERE CategoryID = 1                              │
│  UNION                                             │
│  SELECT * FROM Products                            │
│  WHERE CategoryID = 2                              │
│  ORDER BY ProductName  ← At the end!               │
│                                                     │
│  Column Names:                                     │
│  • Use names from FIRST query                      │
│  • Or use column position (1, 2, 3...)            │
└────────────────────────────────────────────────────┘
```

---

## Real-World Example: Contact List

```
┌────────────────────────────────────────────────────┐
│          Unified Contact Directory                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  Goal: Merge customers and suppliers into one list│
│                                                     │
│  Query:                                            │
│  SELECT                                            │
│      FirstName + ' ' + LastName AS Name,           │
│      Email,                                        │
│      'Customer' AS Type,                           │
│      City                                          │
│  FROM Customers                                    │
│  WHERE Email IS NOT NULL                           │
│  UNION                                             │
│  SELECT                                            │
│      ContactName,                                  │
│      Email,                                        │
│      'Supplier',                                   │
│      City                                          │
│  FROM Suppliers                                    │
│  WHERE Email IS NOT NULL                           │
│  ORDER BY Type, Name                               │
│                                                     │
│  Result:                                           │
│  ┌──────────────┬───────────────┬──────────┬──────┐│
│  │     Name     │     Email     │   Type   │ City ││
│  ├──────────────┼───────────────┼──────────┼──────┤│
│  │ John Smith   │ john@co.com   │ Customer │ NYC  ││
│  │ Sarah Jones  │ sara@co.com   │ Customer │ LA   ││
│  │ ACME Corp    │ acme@corp.com │ Supplier │ TX   ││
│  │ Tech Supply  │ tech@sup.com  │ Supplier │ CA   ││
│  └──────────────┴───────────────┴──────────┴──────┘│
└────────────────────────────────────────────────────┘
```

---

## Common Patterns

### Pattern 1: Historical + Current Data

```
-- Combine archived and current orders
SELECT OrderID, OrderDate, TotalAmount, 'Archived' AS Status
FROM OrderHistory
UNION ALL
SELECT OrderID, OrderDate, TotalAmount, 'Current'
FROM Orders
ORDER BY OrderDate DESC;
```

### Pattern 2: Multiple Time Periods

```
-- Quarterly revenue report
SELECT 'Q1 2025' AS Period, SUM(TotalAmount) AS Revenue
FROM Orders WHERE MONTH(OrderDate) IN (1,2,3)
UNION ALL
SELECT 'Q2 2025', SUM(TotalAmount)
FROM Orders WHERE MONTH(OrderDate) IN (4,5,6)
UNION ALL
SELECT 'Q3 2025', SUM(TotalAmount)
FROM Orders WHERE MONTH(OrderDate) IN (7,8,9)
UNION ALL
SELECT 'Q4 2025', SUM(TotalAmount)
FROM Orders WHERE MONTH(OrderDate) IN (10,11,12);
```

### Pattern 3: Add Summary Row

```
-- Products with total at bottom
SELECT ProductName, Price FROM Products
UNION ALL
SELECT 'TOTAL', SUM(Price) FROM Products
ORDER BY Price;
```

---

## Key Takeaways

```
✅ UNION Basics:
  • Combines results from multiple queries
  • Removes duplicates by default
  • UNION ALL keeps duplicates (faster)

✅ Requirements:
  • Same number of columns
  • Compatible data types
  • Column names from first query
  • ORDER BY only at the end

✅ Best Practices:
  • Use UNION ALL when possible (performance)
  • Add type indicators for clarity
  • Filter before UNION (not after)
  • Use NULL for missing columns
  • Test with COUNT(*) first

✅ Common Mistakes:
  ❌ Different column counts
  ❌ ORDER BY in individual queries
  ❌ Assuming column names from second query
  ❌ Using UNION when UNION ALL works
```

---

## Quick Reference

```sql
-- Basic UNION (removes duplicates)
SELECT columns FROM table1
UNION
SELECT columns FROM table2
ORDER BY column1;

-- UNION ALL (keeps duplicates - faster)
SELECT columns FROM table1
UNION ALL
SELECT columns FROM table2;

-- With type indicator
SELECT col1, col2, 'Type A' AS Source FROM table1
UNION
SELECT col1, col2, 'Type B' FROM table2;

-- Handle NULL columns
SELECT col1, col2, col3, NULL AS col4 FROM table1
UNION
SELECT col1, col2, NULL, col4 FROM table2;
```

---

**Next:** [Lesson 05 - INTERSECT Operator](../05-intersect-operator/05-intersect-operator.sql)
