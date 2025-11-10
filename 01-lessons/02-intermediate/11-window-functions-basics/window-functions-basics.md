# Lesson 11: Window Functions - Basics

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Understand what window functions are and how they differ from aggregates
2. Use the OVER() clause to define windows
3. Use PARTITION BY to create groups within windows
4. Use ORDER BY within OVER() for running calculations
5. Understand when to use window functions vs GROUP BY

---

## Part 1: What Are Window Functions?

Window functions perform calculations across a set of rows related to the current row, **without collapsing rows** like GROUP BY does.

```sql
-- GROUP BY collapses rows
SELECT CategoryID, AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID;  -- One row per category

-- Window function keeps all rows
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    AVG(Price) OVER(PARTITION BY CategoryID) AS AvgCategoryPrice
FROM Products;  -- All rows preserved, with category average added
```

---

## Part 2: The OVER() Clause

The OVER() clause defines the "window" of rows for the calculation.

```sql
-- Calculate overall average (no partitioning)
SELECT 
    ProductName,
    Price,
    AVG(Price) OVER() AS OverallAvgPrice
FROM Products;
```

---

## Part 3: PARTITION BY

PARTITION BY divides rows into groups (like GROUP BY), but keeps all rows.

```sql
-- Average price per category, shown on every row
SELECT 
    ProductName,
    CategoryID,
    Price,
    AVG(Price) OVER(PARTITION BY CategoryID) AS AvgCategoryPrice,
    Price - AVG(Price) OVER(PARTITION BY CategoryID) AS PriceDiff
FROM Products;
```

---

## Part 4: ORDER BY Within OVER()

ORDER BY in the window creates running/cumulative calculations.

```sql
-- Running total of sales
SELECT 
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER(ORDER BY OrderDate) AS RunningTotal
FROM Orders
ORDER BY OrderDate;
```

---

## Part 5: Combining PARTITION BY and ORDER BY

```sql
-- Running total per customer
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS CustomerRunningTotal
FROM Orders
ORDER BY CustomerID, OrderDate;
```

---

## Part 6: Window Functions vs Aggregates

| Feature | GROUP BY + Aggregate | Window Function |
|---------|---------------------|-----------------|
| Row count | Collapses rows | Preserves all rows |
| Use case | Summary reports | Row-level calculations with context |
| Mix with non-aggregated columns | No (error) | Yes |

---

## Part 7: Common Use Cases

### Compare each row to group average

```sql
SELECT 
    ProductName,
    Price,
    AVG(Price) OVER() AS OverallAvg,
    Price - AVG(Price) OVER() AS Difference
FROM Products;
```

### Running count

```sql
SELECT 
    OrderDate,
    COUNT(*) OVER(ORDER BY OrderDate) AS CumulativeOrderCount
FROM Orders;
```

---

## Part 8: Practical Examples

### Example 1: Sales vs Category Average

```sql
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    AVG(p.Price) OVER(PARTITION BY p.CategoryID) AS AvgCategoryPrice,
    CASE 
        WHEN p.Price > AVG(p.Price) OVER(PARTITION BY p.CategoryID) THEN 'Above Average'
        ELSE 'Below Average'
    END AS PricePosition
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Example 2: Customer Running Total

```sql
SELECT 
    CustomerID,
    OrderID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS LifetimeValue
FROM Orders
ORDER BY CustomerID, OrderDate;
```

---

## Part 9: Performance Considerations

- Window functions can be expensive on large datasets
- Index columns used in PARTITION BY and ORDER BY
- Avoid recalculating the same window multiple times; use CTEs or subqueries

```sql
-- Inefficient: recalculates window twice
SELECT 
    ProductName,
    Price,
    AVG(Price) OVER(PARTITION BY CategoryID) AS Avg1,
    AVG(Price) OVER(PARTITION BY CategoryID) AS Avg2
FROM Products;

-- Better: calculate once in CTE
WITH ProductAvg AS (
    SELECT 
        ProductName,
        Price,
        AVG(Price) OVER(PARTITION BY CategoryID) AS AvgPrice
    FROM Products
)
SELECT ProductName, Price, AvgPrice, AvgPrice AS Avg2
FROM ProductAvg;
```

---

## Practice Exercises

1. Show each employee's salary and the average salary for their department (preserve all rows).
2. Calculate a running total of order amounts ordered by OrderDate.
3. For each product, show its price and the maximum price in its category.

---

## Key Takeaways

- Window functions calculate across rows without collapsing
- OVER() defines the window
- PARTITION BY groups rows; ORDER BY creates running calculations
- Use when you need row-level detail + aggregate context

---

## Next Lesson

Continue to [Lesson 12: Window Functions - Aggregates & Frames](../12-window-functions-aggregates/window-functions-aggregates.md).
