# Lesson 03: Inner Joins - Visual Guide

## What You'll Learn
- Deep dive into INNER JOIN mechanics
- Filtering joined results
- Aggregating across joined tables
- Real-world INNER JOIN patterns

---

## What is an INNER JOIN?

An **INNER JOIN** returns only rows where there is a **match in BOTH tables**.

```
┌────────────────────────────────────────────────────────┐
│                 INNER JOIN Behavior                    │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Table A (Products):         Table B (Categories):     │
│  ┌────┬──────────┬────┐    ┌────┬──────────────┐     │
│  │ ID │   Name   │Cat │    │ ID │     Name     │     │
│  ├────┼──────────┼────┤    ├────┼──────────────┤     │
│  │ 1  │  Laptop  │ 1  │────→│ 1  │ Electronics  │ ✓  │
│  │ 2  │  Mouse   │ 1  │────→│ 2  │ Books        │ ✓  │
│  │ 3  │  Novel   │ 2  │────→│ 3  │ Clothing     │    │
│  │ 4  │  Shirt   │ 3  │────→                          │
│  │ 5  │  Camera  │NULL│  ✗ No match! Excluded        │
│  └────┴──────────┴────┘                                │
│                                                         │
│  INNER JOIN Result (4 rows):                           │
│  ┌────┬──────────┬──────────────┐                     │
│  │ ID │   Name   │  CategoryName│                     │
│  ├────┼──────────┼──────────────┤                     │
│  │ 1  │  Laptop  │ Electronics  │ ← Match found      │
│  │ 2  │  Mouse   │ Electronics  │ ← Match found      │
│  │ 3  │  Novel   │ Books        │ ← Match found      │
│  │ 4  │  Shirt   │ Clothing     │ ← Match found      │
│  └────┴──────────┴──────────────┘                     │
│                                                         │
│  Camera excluded: CategoryID = NULL (no match)         │
│  Clothing in Categories but no products (not shown)    │
└────────────────────────────────────────────────────────┘
```

---

## INNER JOIN: Only the Overlap

```
┌────────────────────────────────────────┐
│        Venn Diagram Representation     │
├────────────────────────────────────────┤
│                                         │
│      Table A          Table B          │
│        ╭─────╮     ╭─────╮            │
│        │     │     │     │             │
│        │  A  │     │  B  │             │
│        │     │     │     │             │
│        ╰──┬──╯     ╰──┬──╯             │
│           │   ████    │                │
│           └───████────┘                │
│              INNER                     │
│              JOIN                      │
│         (only overlap)                 │
│                                         │
│  INNER JOIN = Where A meets B          │
│                                         │
│  • Rows in A but not B → Excluded     │
│  • Rows in B but not A → Excluded     │
│  • Only matching rows → Included      │
└────────────────────────────────────────┘
```

---

## Step-by-Step: How INNER JOIN Works

### Step 1: Start with Table 1

```
Products Table:
┌───────────┬──────────┬───────┬────────────┐
│ ProductID │   Name   │ Price │ CategoryID │
├───────────┼──────────┼───────┼────────────┤
│     1     │  Laptop  │  800  │      1     │
│     2     │  Mouse   │   25  │      1     │
│     3     │  Novel   │   15  │      2     │
│     4     │  Camera  │  500  │    NULL    │
└───────────┴──────────┴───────┴────────────┘
```

### Step 2: Look at Table 2

```
Categories Table:
┌────────────┬──────────────┐
│ CategoryID │     Name     │
├────────────┼──────────────┤
│      1     │ Electronics  │
│      2     │ Books        │
│      3     │ Clothing     │
└────────────┴──────────────┘
```

### Step 3: Match on Join Condition

```sql
ON p.CategoryID = c.CategoryID
```

```
Matching Process:

Product 1: CategoryID = 1
  → Find Category 1 ✓ (Electronics)
  → Include in result

Product 2: CategoryID = 1
  → Find Category 1 ✓ (Electronics)
  → Include in result

Product 3: CategoryID = 2
  → Find Category 2 ✓ (Books)
  → Include in result

Product 4: CategoryID = NULL
  → No match (NULL doesn't equal anything)
  → Exclude from result

Category 3: (Clothing)
  → No products reference it
  → Exclude from result
```

### Step 4: Combine Results

```
┌───────────┬──────────┬───────┬──────────────┐
│ ProductID │   Name   │ Price │ CategoryName │
├───────────┼──────────┼───────┼──────────────┤
│     1     │  Laptop  │  800  │ Electronics  │
│     2     │  Mouse   │   25  │ Electronics  │
│     3     │  Novel   │   15  │ Books        │
└───────────┴──────────┴───────┴──────────────┘

3 rows (Camera and Clothing category excluded)
```

---

## INNER JOIN with WHERE Clause

```sql
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;
```

### Two Filtering Stages

```
Stage 1: INNER JOIN (match on CategoryID)
┌────┬──────────┬───────┬──────────────┐
│ ID │   Name   │ Price │ CategoryName │
├────┼──────────┼───────┼──────────────┤
│ 1  │  Laptop  │  800  │ Electronics  │ ← Keep
│ 2  │  Mouse   │   25  │ Electronics  │ ← Remove (Price ≤ 100)
│ 3  │  Novel   │   15  │ Books        │ ← Remove (Price ≤ 100)
│ 4  │  Monitor │  350  │ Electronics  │ ← Keep
└────┴──────────┴───────┴──────────────┘
        ↓
Stage 2: WHERE p.Price > 100
┌────┬──────────┬───────┬──────────────┐
│ ID │   Name   │ Price │ CategoryName │
├────┼──────────┼───────┼──────────────┤
│ 1  │  Laptop  │  800  │ Electronics  │
│ 4  │  Monitor │  350  │ Electronics  │
└────┴──────────┴───────┴──────────────┘

Final Result: 2 rows
```

---

## ON vs WHERE: What's the Difference?

### ON Clause (Join Condition)

```sql
-- ON: Determines which rows to match
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
                           ↑
                    How tables relate
```

### WHERE Clause (Filter Results)

```sql
-- WHERE: Filters the joined result
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;
      ↑
   Filter after joining
```

### Visual Difference

```
┌─────────────────────────────────────────────────┐
│         ON vs WHERE in INNER JOIN               │
├─────────────────────────────────────────────────┤
│                                                  │
│  Products → INNER JOIN → Categories             │
│             (ON CategoryID)                      │
│                  ↓                               │
│          Matched rows (all)                      │
│                  ↓                               │
│            WHERE Price > 100                     │
│                  ↓                               │
│          Final filtered result                   │
│                                                  │
│  Order: JOIN first, then FILTER                 │
└─────────────────────────────────────────────────┘
```

---

## Multiple Conditions in ON Clause

```sql
SELECT *
FROM Products p
INNER JOIN Categories c 
    ON p.CategoryID = c.CategoryID 
    AND p.Price > 100;  -- Additional condition in ON
```

### For INNER JOIN: Same as WHERE

```sql
-- These are equivalent for INNER JOIN:

-- Version 1: Condition in ON
SELECT *
FROM Products p
INNER JOIN Categories c 
    ON p.CategoryID = c.CategoryID 
    AND p.Price > 100;

-- Version 2: Condition in WHERE
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;

Both return same result!

⚠️ But different for LEFT/RIGHT JOIN! (covered later)
```

---

## Aggregating Across Joins

### Count Products per Category

```sql
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount
FROM Categories c
INNER JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName;
```

### Visual Process

```
Categories:                Products:
┌────┬──────────────┐    ┌────┬──────────┬────┐
│ ID │     Name     │    │ ID │   Name   │Cat │
├────┼──────────────┤    ├────┼──────────┼────┤
│ 1  │ Electronics  │←───│ 1  │  Laptop  │ 1  │
│ 2  │ Books        │    │ 2  │  Mouse   │ 1  │
│ 3  │ Clothing     │    │ 3  │  Monitor │ 1  │
└────┴──────────────┘    │ 4  │  Novel   │ 2  │
                         │ 5  │  Book2   │ 2  │
                         └────┴──────────┴────┘

GROUP BY c.CategoryName, COUNT:

Electronics: Laptop, Mouse, Monitor = 3
Books: Novel, Book2 = 2
Clothing: (no products) = 0 ← NOT SHOWN (INNER JOIN excludes)

Result:
┌──────────────┬──────────────┐
│ CategoryName │ ProductCount │
├──────────────┼──────────────┤
│ Electronics  │      3       │
│ Books        │      2       │
└──────────────┴──────────────┘

Clothing excluded because INNER JOIN requires match!
```

---

## Calculating Totals

```sql
SELECT 
    c.Name AS Customer,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Name;
```

### Breakdown

```
Customers:              Orders:
┌────┬────────┐        ┌────┬────┬────────┐
│ ID │  Name  │        │ ID │Cust│ Amount │
├────┼────────┤        ├────┼────┼────────┤
│ 1  │  John  │←───────│ 1  │ 1  │  $100  │
│ 2  │  Sarah │        │ 2  │ 1  │  $200  │
│ 3  │  Mike  │        │ 3  │ 2  │  $150  │
└────┴────────┘        └────┴────┴────────┘

GROUP BY Customer:

John: Orders 1, 2 → COUNT = 2, SUM = $300
Sarah: Order 3 → COUNT = 1, SUM = $150
Mike: (no orders) → NOT IN RESULT (INNER JOIN)

Result:
┌──────────┬─────────────┬────────────┐
│ Customer │ TotalOrders │ TotalSpent │
├──────────┼─────────────┼────────────┤
│  John    │      2      │   $300     │
│  Sarah   │      1      │   $150     │
└──────────┴─────────────┴────────────┘
```

---

## Joining with Calculated Columns

```sql
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.Price * 0.9 AS DiscountedPrice,
    p.Price - (p.Price * 0.9) AS Savings
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 50;
```

### Result

```
┌─────────────┬─────────────┬───────┬──────────────┬─────────┐
│ ProductName │CategoryName │ Price │ Discounted   │ Savings │
├─────────────┼─────────────┼───────┼──────────────┼─────────┤
│  Laptop     │ Electronics │  800  │     720      │   80    │
│  Monitor    │ Electronics │  350  │     315      │   35    │
│  Camera     │ Electronics │  500  │     450      │   50    │
└─────────────┴─────────────┴───────┴──────────────┴─────────┘

Calculations performed AFTER join
```

---

## Real-World Pattern: Order Report

```sql
SELECT 
    c.Name AS CustomerName,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    p.Price AS UnitPrice,
    od.Quantity * p.Price AS LineTotal
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
ORDER BY o.OrderDate, c.Name;
```

### Four-Table Join Visualization

```
Customers → Orders → OrderDetails → Products
    1          *           *            1

c.CustomerID = o.CustomerID ✓
o.OrderID = od.OrderID ✓
od.ProductID = p.ProductID ✓

Result:
┌────────────┬────────────┬─────────────┬────┬──────┬──────┐
│  Customer  │   Date     │   Product   │Qty │Price │Total │
├────────────┼────────────┼─────────────┼────┼──────┼──────┤
│  John      │ 2025-01-15 │   Laptop    │ 1  │ 800  │ 800  │
│  John      │ 2025-01-15 │   Mouse     │ 2  │  25  │  50  │
│  Sarah     │ 2025-01-20 │   Monitor   │ 1  │ 350  │ 350  │
└────────────┴────────────┴─────────────┴────┴──────┴──────┘
```

---

## Common Patterns

### Pattern 1: Lookup Details

```sql
-- Show product with category name
SELECT p.ProductName, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Pattern 2: Aggregation

```sql
-- Count items per group
SELECT c.CategoryName, COUNT(p.ProductID) AS Count
FROM Categories c
INNER JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName;
```

### Pattern 3: Filtering

```sql
-- Find specific matches
SELECT *
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.City = 'New York' AND o.OrderDate > '2025-01-01';
```

---

## Key Takeaways

```
✅ INNER JOIN Returns:
  • Only matching rows from BOTH tables
  • Excludes NULLs in join columns
  • Excludes unmatched rows

✅ Use INNER JOIN When:
  • You only want matching data
  • Both tables must have a relationship
  • You want to exclude orphaned records

✅ ON Clause:
  • Specifies join condition (how tables relate)
  • Usually Foreign Key = Primary Key
  • Can include multiple conditions (AND/OR)

✅ WHERE Clause:
  • Filters result AFTER join
  • For INNER JOIN: same as adding to ON
  • Applied after all joins complete
```

---

## Quick Reference

### Basic INNER JOIN

```sql
SELECT columns
FROM table1 alias1
INNER JOIN table2 alias2 ON alias1.fk = alias2.pk
WHERE filter_conditions
ORDER BY columns;
```

### With Aggregation

```sql
SELECT 
    alias1.column,
    COUNT(alias2.column) AS count,
    SUM(alias2.column) AS total
FROM table1 alias1
INNER JOIN table2 alias2 ON alias1.pk = alias2.fk
GROUP BY alias1.column;
```

---

**Next:** [Lesson 04 - ANSI Join Syntax](../04-ansi-join-syntax/04-ansi-join-syntax.sql)
