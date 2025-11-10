# Lesson 10: Aggregate Functions & GROUP BY

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Use aggregate functions: COUNT, SUM, AVG, MIN, MAX
2. Group data with GROUP BY and understand its rules
3. Filter grouped results with HAVING
4. Distinguish between WHERE and HAVING
5. Use GROUP BY with multiple columns
6. Understand NULL handling in aggregates

---

## Part 1: The Five Basic Aggregates

```sql
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(ProductID) AS NonNullProducts,
    SUM(Price) AS TotalValue,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products;
```

### COUNT variations

- COUNT(*) counts all rows (including NULLs)
- COUNT(column) counts non-NULL values
- COUNT(DISTINCT column) counts unique non-NULL values

---

## Part 2: GROUP BY Basics

```sql
-- Total sales per category
SELECT CategoryID, SUM(Price * Stock) AS TotalValue
FROM Products
GROUP BY CategoryID;
```

**Rule:** Columns in SELECT must be in GROUP BY or wrapped in aggregate function.

---

## Part 3: Multiple GROUP BY Columns

```sql
-- Sales by year and month
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS MonthlySales
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year DESC, Month DESC;
```

---

## Part 4: HAVING Clause

HAVING filters groups *after* aggregation; WHERE filters rows *before* aggregation.

```sql
-- Categories with more than 10 products
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 10;
```

### WHERE vs HAVING

```sql
-- Correct: filter rows before grouping, then filter groups
SELECT CategoryID, AVG(Price) AS AvgPrice
FROM Products
WHERE Stock > 0  -- Filter individual rows first
GROUP BY CategoryID
HAVING AVG(Price) > 50;  -- Then filter groups
```

---

## Part 5: DISTINCT with Aggregates

```sql
-- Count unique customers who placed orders
SELECT COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders;

-- Total unique products sold
SELECT COUNT(DISTINCT ProductID) AS UniqueProducts
FROM OrderDetails;
```

---

## Part 6: Aggregates and NULL

Most aggregates ignore NULL:

```sql
-- AVG ignores NULL ratings
SELECT AVG(Rating) AS AvgRating FROM Products; -- NULLs excluded

-- COUNT(*) includes NULLs; COUNT(Rating) excludes them
SELECT COUNT(*), COUNT(Rating) FROM Products;
```

---

## Part 7: GROUP BY with Expressions

```sql
-- Group by calculated column
SELECT 
    CASE 
        WHEN Price < 20 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceRange,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY 
    CASE 
        WHEN Price < 20 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END;
```

---

## Part 8: Practical Examples

### Example 1: Customer Lifetime Value

```sql
SELECT 
    CustomerID,
    COUNT(OrderID) AS TotalOrders,
    SUM(TotalAmount) AS LifetimeValue,
    AVG(TotalAmount) AS AvgOrderValue,
    MAX(OrderDate) AS LastOrderDate
FROM Orders
GROUP BY CustomerID
HAVING COUNT(OrderID) >= 5  -- Active customers only
ORDER BY LifetimeValue DESC;
```

### Example 2: Product Performance

```sql
SELECT 
    p.CategoryID,
    c.CategoryName,
    COUNT(DISTINCT p.ProductID) AS ProductCount,
    SUM(od.Quantity) AS TotalUnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY p.CategoryID, c.CategoryName
HAVING SUM(od.Quantity * od.UnitPrice) > 10000
ORDER BY TotalRevenue DESC;
```

### Example 3: Monthly Growth

```sql
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
WHERE OrderDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;
```

---

## Part 9: Common Pitfalls

### Pitfall 1: Column not in GROUP BY

```sql
-- ERROR: ProductName not in GROUP BY or aggregate
SELECT CategoryID, ProductName, COUNT(*)
FROM Products
GROUP BY CategoryID;

-- FIX: Add to GROUP BY or remove
SELECT CategoryID, COUNT(*)
FROM Products
GROUP BY CategoryID;
```

### Pitfall 2: WHERE on aggregate

```sql
-- ERROR: Can't use WHERE on aggregate
SELECT CategoryID, AVG(Price)
FROM Products
WHERE AVG(Price) > 50
GROUP BY CategoryID;

-- FIX: Use HAVING
SELECT CategoryID, AVG(Price)
FROM Products
GROUP BY CategoryID
HAVING AVG(Price) > 50;
```

---

## Part 10: Performance Tips

- Use WHERE to filter rows before grouping (reduces data volume)
- Index columns used in GROUP BY
- Avoid GROUP BY on large text columns; use ID instead
- Consider indexed views for frequently used aggregations

---

## Practice Exercises

1. Find the top 5 customers by total revenue using SUM and GROUP BY.
2. Show categories with average product price > $50 using HAVING.
3. Count orders per month for the current year, showing month name.

---

## Key Takeaways

- Aggregates: COUNT, SUM, AVG, MIN, MAX
- GROUP BY creates groups; SELECT columns must be grouped or aggregated
- WHERE filters rows; HAVING filters groups
- Most aggregates ignore NULL
- Use DISTINCT for unique counts

---

## Next Lesson

Continue to [Lesson 11: Window Functions - Basics](../11-window-functions-basics/11-window-functions-basics.md).
