# Lesson 12: Window Functions - Aggregates & Frames

**Timeline:** 10:13:41 - 11:05:35  
**Duration:** ~52 minutes  
**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Use aggregate window functions (SUM, AVG, COUNT, MIN, MAX)
2. Define window frames (ROWS, RANGE)
3. Create moving averages and rolling calculations
4. Use UNBOUNDED PRECEDING and CURRENT ROW
5. Understand frame defaults and when to override them

---

## Part 1: Aggregate Window Functions

All standard aggregates work as window functions.

```sql
SELECT 
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER(ORDER BY OrderDate) AS RunningTotal,
    AVG(TotalAmount) OVER(ORDER BY OrderDate) AS RunningAvg,
    MIN(TotalAmount) OVER(ORDER BY OrderDate) AS MinToDate,
    MAX(TotalAmount) OVER(ORDER BY OrderDate) AS MaxToDate,
    COUNT(*) OVER(ORDER BY OrderDate) AS OrderCountToDate
FROM Orders;
```

---

## Part 2: Window Frames

Frames define which rows within the partition are included in the calculation.

### Default frame

When you use ORDER BY without a frame, the default is:
```
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

This gives you a running total from the start to the current row.

---

## Part 3: ROWS vs RANGE

- **ROWS**: Physical rows
- **RANGE**: Logical range (includes ties)

```sql
-- ROWS: Exactly 3 physical rows
SELECT 
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER(ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvg3
FROM Orders;

-- RANGE: All rows with same OrderDate value (handles ties)
SELECT 
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER(ORDER BY OrderDate RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningAvg
FROM Orders;
```

---

## Part 4: Frame Boundaries

Common frame specifications:

```sql
-- Last 7 days (ROWS)
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

-- All preceding rows
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Current row only
ROWS BETWEEN CURRENT ROW AND CURRENT ROW

-- 3 before and 3 after (centered window)
ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING

-- All rows in partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
```

---

## Part 5: Moving Averages

```sql
-- 7-day moving average
SELECT 
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER(
        ORDER BY OrderDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7Day
FROM DailySales
ORDER BY OrderDate;
```

---

## Part 6: Partition + Frame

```sql
-- 3-order moving average per customer
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount,
    AVG(TotalAmount) OVER(
        PARTITION BY CustomerID 
        ORDER BY OrderDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Orders
FROM Orders
ORDER BY CustomerID, OrderDate;
```

---

## Part 7: Practical Examples

### Example 1: Sales Trend Analysis

```sql
SELECT 
    OrderDate,
    DailySales,
    AVG(DailySales) OVER(
        ORDER BY OrderDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS WeeklyMovingAvg,
    AVG(DailySales) OVER(
        ORDER BY OrderDate 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS MonthlyMovingAvg
FROM (
    SELECT OrderDate, SUM(TotalAmount) AS DailySales
    FROM Orders
    GROUP BY OrderDate
) AS Daily
ORDER BY OrderDate;
```

### Example 2: Running Min/Max

```sql
SELECT 
    ProductID,
    OrderDate,
    UnitPrice,
    MIN(UnitPrice) OVER(
        PARTITION BY ProductID 
        ORDER BY OrderDate 
        ROWS UNBOUNDED PRECEDING
    ) AS LowestPriceToDate,
    MAX(UnitPrice) OVER(
        PARTITION BY ProductID 
        ORDER BY OrderDate 
        ROWS UNBOUNDED PRECEDING
    ) AS HighestPriceToDate
FROM OrderDetails
ORDER BY ProductID, OrderDate;
```

### Example 3: Percentage of Total

```sql
SELECT 
    CategoryName,
    Revenue,
    SUM(Revenue) OVER() AS TotalRevenue,
    (Revenue * 100.0 / SUM(Revenue) OVER()) AS PercentOfTotal
FROM CategorySales
ORDER BY Revenue DESC;
```

---

## Part 8: Frame Defaults

| Scenario | Default Frame |
|----------|---------------|
| No ORDER BY | All rows in partition |
| ORDER BY present | RANGE UNBOUNDED PRECEDING TO CURRENT ROW |
| Explicit ROWS/RANGE | As specified |

---

## Part 9: Performance Tips

- Frames can be expensive; avoid unnecessarily large frames
- Index columns in ORDER BY
- Use ROWS instead of RANGE when possible (ROWS is usually faster)
- Materialize intermediate results in temp tables/CTEs for complex calculations

---

## Practice Exercises

1. Calculate a 5-day moving average of sales.
2. Show running total and running average of employee salaries ordered by hire date.
3. Compute percentage each product contributes to its category total.

---

## Key Takeaways

- Window frames define which rows are included in aggregate
- ROWS = physical; RANGE = logical
- Default frame with ORDER BY: RANGE UNBOUNDED PRECEDING TO CURRENT ROW
- Use frames for moving averages, running totals, sliding windows

---

## Next Lesson

Continue to [Lesson 13: Window Functions - Ranking](../13-window-functions-ranking/).
