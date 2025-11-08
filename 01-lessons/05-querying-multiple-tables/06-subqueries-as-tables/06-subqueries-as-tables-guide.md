# Lesson 06: Subqueries as Tables (Derived Tables) - Visual Guide

## What You'll Learn
- Using subqueries in FROM clause
- Pre-aggregating data
- Derived tables vs regular tables
- Introduction to CTEs (Common Table Expressions)

---

## What is a Derived Table?

A **derived table** is a subquery in the FROM clause that acts like a temporary table.

```
┌──────────────────────────────────────────────────────┐
│              Derived Table Concept                   │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Normal Query:                                       │
│  SELECT * FROM Products;                             │
│         ↑                                            │
│    Physical table in database                        │
│                                                       │
│  Derived Table Query:                                │
│  SELECT * FROM (SELECT * FROM Products WHERE ...) AS p;
│                 └─────────────────────────────┘      │
│                          ↑                            │
│                  Subquery acts as table              │
│                  (temporary, exists only for query)  │
│                                                       │
│  The subquery result becomes a "virtual table"       │
└──────────────────────────────────────────────────────┘
```

---

## Basic Syntax

```sql
SELECT columns
FROM (
    SELECT ...  -- This is the derived table
    FROM table
    WHERE ...
) AS alias  -- Alias is REQUIRED!
WHERE ...;
```

### Visual Breakdown

```
┌────────────────────────────────────────────────────┐
│        Derived Table Query Structure               │
├────────────────────────────────────────────────────┤
│                                                     │
│  Outer Query:                                      │
│  SELECT dt.ProductName, dt.Price                   │
│  FROM (                                            │
│      ┌────────────────────────────────────┐       │
│      │  Inner Query (Derived Table):      │       │
│      │                                     │       │
│      │  SELECT ProductID,                 │       │
│      │         ProductName,                │       │
│      │         Price                       │       │
│      │  FROM Products                      │       │
│      │  WHERE Price > 100                  │       │
│      └────────────────────────────────────┘       │
│  ) AS dt  ← Required alias                        │
│  WHERE dt.Price < 500;                             │
│                                                     │
│  Execution:                                        │
│  1. Inner query runs → creates temp result        │
│  2. Outer query uses temp result as table         │
└────────────────────────────────────────────────────┘
```

---

## Why Use Derived Tables?

### Problem: Can't Reuse Calculated Columns

```sql
-- ❌ DOESN'T WORK: Can't use alias in same SELECT
SELECT 
    ProductName,
    Price * 0.9 AS DiscountPrice,
    DiscountPrice * 0.08 AS Tax  -- ❌ Error! DiscountPrice not recognized
FROM Products;
```

### Solution: Derived Table

```sql
-- ✅ WORKS: Calculate in derived table, reference in outer query
SELECT 
    ProductName,
    DiscountPrice,
    DiscountPrice * 0.08 AS Tax
FROM (
    SELECT 
        ProductName,
        Price * 0.9 AS DiscountPrice
    FROM Products
) AS dt;
```

### Visual Process

```
Step 1: Inner query calculates DiscountPrice
┌─────────────┬───────┬───────────────┐
│ ProductName │ Price │ DiscountPrice │
├─────────────┼───────┼───────────────┤
│  Laptop     │  800  │      720      │
│  Mouse      │   25  │       22.5    │
│  Monitor    │  350  │      315      │
└─────────────┴───────┴───────────────┘
        ↓
Step 2: Outer query uses DiscountPrice to calculate Tax
┌─────────────┬───────────────┬───────┐
│ ProductName │ DiscountPrice │  Tax  │
├─────────────┼───────────────┼───────┤
│  Laptop     │      720      │ 57.60 │
│  Mouse      │       22.5    │  1.80 │
│  Monitor    │      315      │ 25.20 │
└─────────────┴───────────────┴───────┘
```

---

## Pre-Aggregation Pattern

### Problem: Multiple Aggregation Levels

```
Need to find customers who spent more than average.

Can't do this in single query:
SELECT Name 
FROM Customers 
WHERE TotalSpent > AVG(TotalSpent)  -- ❌ Can't aggregate in WHERE
```

### Solution: Derived Table with Pre-Aggregation

```sql
SELECT 
    CustomerName,
    TotalSpent
FROM (
    SELECT 
        c.Name AS CustomerName,
        SUM(o.TotalAmount) AS TotalSpent
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.Name
) AS CustomerTotals
WHERE TotalSpent > (SELECT AVG(TotalSpent) FROM (
    SELECT SUM(o.TotalAmount) AS TotalSpent
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
) AS Averages);
```

### Visual Breakdown

```
Step 1: Calculate each customer's total
┌──────────────┬─────────────┐
│ CustomerName │ TotalSpent  │
├──────────────┼─────────────┤
│   John       │    $500     │
│   Sarah      │    $1200    │
│   Mike       │    $300     │
│   Emily      │    $800     │
└──────────────┴─────────────┘
        ↓
Step 2: Calculate average ($700)
        ↓
Step 3: Filter customers > average
┌──────────────┬─────────────┐
│ CustomerName │ TotalSpent  │
├──────────────┼─────────────┤
│   Sarah      │    $1200    │ ← > $700
│   Emily      │    $800     │ ← > $700
└──────────────┴─────────────┘
```

---

## Joining Derived Tables

```sql
SELECT 
    p.ProductName,
    p.Price,
    avg_prices.AvgPrice,
    p.Price - avg_prices.AvgPrice AS Difference
FROM Products p
CROSS JOIN (
    SELECT AVG(Price) AS AvgPrice
    FROM Products
) AS avg_prices
WHERE p.Price > avg_prices.AvgPrice;
```

### How It Works

```
Step 1: Calculate average price (derived table)
┌───────────┐
│ AvgPrice  │
├───────────┤
│   $250    │  ← Single row result
└───────────┘

Step 2: Join to Products
Products:                    avg_prices:
┌──────────┬───────┐        ┌───────────┐
│   Name   │ Price │        │ AvgPrice  │
├──────────┼───────┤        ├───────────┤
│  Laptop  │  800  │   ×    │   $250    │
│  Mouse   │   25  │   ×    │   $250    │
│  Monitor │  350  │   ×    │   $250    │
└──────────┴───────┘        └───────────┘

Step 3: Filter Price > AvgPrice
┌──────────┬───────┬──────────┬────────────┐
│   Name   │ Price │ AvgPrice │ Difference │
├──────────┼───────┼──────────┼────────────┤
│  Laptop  │  800  │   250    │    +550    │
│  Monitor │  350  │   250    │    +100    │
└──────────┴───────┴──────────┴────────────┘
```

---

## TOP N per Group Pattern

### Problem: Get top 3 products per category

```sql
SELECT 
    CategoryName,
    ProductName,
    Price
FROM (
    SELECT 
        c.CategoryName,
        p.ProductName,
        p.Price,
        ROW_NUMBER() OVER (
            PARTITION BY c.CategoryID 
            ORDER BY p.Price DESC
        ) AS PriceRank
    FROM Products p
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
) AS RankedProducts
WHERE PriceRank <= 3;
```

### Visual Process

```
Step 1: Rank products within each category
┌──────────────┬─────────────┬───────┬───────────┐
│ CategoryName │ ProductName │ Price │ PriceRank │
├──────────────┼─────────────┼───────┼───────────┤
│ Electronics  │  Laptop     │  800  │     1     │
│ Electronics  │  Monitor    │  350  │     2     │
│ Electronics  │  Mouse      │   25  │     3     │
│ Electronics  │  Cable      │   10  │     4     │
│ Books        │  Hardcover  │   50  │     1     │
│ Books        │  Paperback  │   15  │     2     │
│ Books        │  Magazine   │    5  │     3     │
└──────────────┴─────────────┴───────┴───────────┘
        ↓
Step 2: Filter WHERE PriceRank <= 3
┌──────────────┬─────────────┬───────┬───────────┐
│ CategoryName │ ProductName │ Price │ PriceRank │
├──────────────┼─────────────┼───────┼───────────┤
│ Electronics  │  Laptop     │  800  │     1     │
│ Electronics  │  Monitor    │  350  │     2     │
│ Electronics  │  Mouse      │   25  │     3     │
│ Books        │  Hardcover  │   50  │     1     │
│ Books        │  Paperback  │   15  │     2     │
│ Books        │  Magazine   │    5  │     3     │
└──────────────┴─────────────┴───────┴───────────┘

Top 3 products per category!
```

---

## Common Table Expressions (CTEs)

CTEs are a cleaner alternative to derived tables for complex queries.

### Derived Table (Nested)

```sql
-- Hard to read when nested
SELECT *
FROM (
    SELECT *
    FROM (
        SELECT * FROM Products WHERE Price > 100
    ) AS inner_query
    WHERE Price < 500
) AS outer_query;
```

### CTE (Clean)

```sql
-- Much easier to read!
WITH FilteredProducts AS (
    SELECT * FROM Products WHERE Price > 100
),
FinalProducts AS (
    SELECT * FROM FilteredProducts WHERE Price < 500
)
SELECT * FROM FinalProducts;
```

### Visual Comparison

```
┌────────────────────────────────────────────────────┐
│         Derived Table vs CTE                       │
├────────────────────────────────────────────────────┤
│                                                     │
│  Derived Table (Nested):                           │
│  ┌──────────────────────────────────┐             │
│  │  SELECT FROM (                   │             │
│  │    SELECT FROM (                 │             │
│  │      SELECT FROM (                │             │
│  │        ...                        │             │
│  │      )                            │             │
│  │    )                              │             │
│  │  )                                │             │
│  └──────────────────────────────────┘             │
│  ↑ Hard to read, nested deeply                     │
│                                                     │
│  CTE (Linear):                                     │
│  ┌──────────────────────────────────┐             │
│  │  WITH step1 AS (...)             │             │
│  │  ,    step2 AS (...)             │             │
│  │  ,    step3 AS (...)             │             │
│  │  SELECT * FROM step3;            │             │
│  └──────────────────────────────────┘             │
│  ↑ Easy to read, step-by-step                      │
└────────────────────────────────────────────────────┘
```

---

## Real-World Example: Monthly Sales Report

```sql
-- Calculate monthly totals, then find top months
SELECT 
    SaleMonth,
    TotalRevenue,
    OrderCount
FROM (
    SELECT 
        FORMAT(OrderDate, 'yyyy-MM') AS SaleMonth,
        SUM(TotalAmount) AS TotalRevenue,
        COUNT(OrderID) AS OrderCount
    FROM Orders
    WHERE OrderDate >= '2024-01-01'
    GROUP BY FORMAT(OrderDate, 'yyyy-MM')
) AS MonthlySales
WHERE TotalRevenue > 10000
ORDER BY TotalRevenue DESC;
```

### Breakdown

```
Step 1: Aggregate by month (derived table)
┌───────────┬───────────────┬────────────┐
│ SaleMonth │ TotalRevenue  │ OrderCount │
├───────────┼───────────────┼────────────┤
│ 2024-01   │    $8,500     │     45     │
│ 2024-02   │   $12,300     │     67     │
│ 2024-03   │   $15,800     │     82     │
│ 2024-04   │    $9,200     │     51     │
└───────────┴───────────────┴────────────┘
        ↓
Step 2: Filter months > $10,000
┌───────────┬───────────────┬────────────┐
│ SaleMonth │ TotalRevenue  │ OrderCount │
├───────────┼───────────────┼────────────┤
│ 2024-03   │   $15,800     │     82     │
│ 2024-02   │   $12,300     │     67     │
└───────────┴───────────────┴────────────┘

Only high-revenue months shown
```

---

## Performance Considerations

```
┌────────────────────────────────────────────────────┐
│         Derived Tables Performance                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  ✅ Good Use Cases:                                │
│    • Pre-aggregation before joining               │
│    • Filtering before complex operations           │
│    • Window functions (ROW_NUMBER, RANK)          │
│    • Reusing calculated columns                    │
│                                                     │
│  ⚠️ Watch Out For:                                  │
│    • Very large derived tables (materialize all)  │
│    • Derived tables with no WHERE filter          │
│    • Nested derived tables (use CTE instead)      │
│                                                     │
│  🔥 Optimization:                                   │
│    • Filter as early as possible                   │
│    • Index columns used in derived table WHERE    │
│    • Consider temp tables for very large results  │
└────────────────────────────────────────────────────┘
```

---

## Common Patterns

### Pattern 1: Calculate Then Filter

```sql
-- Calculate aggregates, then filter on them
SELECT *
FROM (
    SELECT 
        CategoryID,
        AVG(Price) AS AvgPrice,
        COUNT(*) AS ProductCount
    FROM Products
    GROUP BY CategoryID
) AS CategoryStats
WHERE AvgPrice > 100;
```

### Pattern 2: Combine Multiple Sources

```sql
-- Union results, then query combined data
SELECT *
FROM (
    SELECT 'Product' AS Type, ProductName AS Name, Price
    FROM Products
    UNION ALL
    SELECT 'Service' AS Type, ServiceName, Price
    FROM Services
) AS AllItems
WHERE Price > 50;
```

### Pattern 3: Ranking and Top N

```sql
-- Rank, then filter top N
SELECT *
FROM (
    SELECT 
        ProductName,
        Price,
        DENSE_RANK() OVER (ORDER BY Price DESC) AS PriceRank
    FROM Products
) AS Ranked
WHERE PriceRank <= 5;
```

---

## Key Takeaways

```
✅ Derived Tables:
  • Subquery in FROM clause
  • Must have alias
  • Acts like temporary table
  • Exists only for the query

✅ Use Cases:
  • Reusing calculated columns
  • Pre-aggregation before joins
  • Multiple aggregation levels
  • TOP N per group
  • Filtering on aggregate results

✅ Best Practices:
  • Use descriptive alias names
  • Consider CTEs for readability
  • Filter early (in derived table)
  • Don't nest too deeply
  • Index base tables appropriately
```

---

## Quick Reference

### Basic Derived Table

```sql
SELECT columns
FROM (
    SELECT ...
    FROM base_table
    WHERE ...
) AS alias
WHERE ...;
```

### CTE Alternative

```sql
WITH DerivedData AS (
    SELECT ...
    FROM base_table
    WHERE ...
)
SELECT columns
FROM DerivedData
WHERE ...;
```

### Pre-Aggregation Pattern

```sql
SELECT *
FROM (
    SELECT 
        GroupColumn,
        SUM(Value) AS Total,
        COUNT(*) AS Count
    FROM Table
    GROUP BY GroupColumn
) AS Aggregated
WHERE Total > 1000;
```

---

**Next:** [Lesson 07 - Using Same Table Twice](../07-using-same-table-twice/07-using-same-table-twice.sql)
