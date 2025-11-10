# Lesson 14: Window Functions - Value Functions

**Timeline:** 12:13:17 - 13:27:29  
**Duration:** ~74 minutes  
**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Use LAG and LEAD to access previous/next row values
2. Use FIRST_VALUE and LAST_VALUE for frame boundaries
3. Calculate period-over-period changes
4. Build comparison columns (previous day, previous month, etc.)
5. Handle edge cases and NULL values in value functions

---

## Part 1: LAG

Access the value from a previous row.

```sql
SELECT 
    OrderDate,
    TotalAmount,
    LAG(TotalAmount) OVER(ORDER BY OrderDate) AS PreviousDayAmount
FROM DailySales
ORDER BY OrderDate;
```

### With offset and default

```sql
-- 2 rows back, default to 0 if not available
SELECT 
    OrderDate,
    TotalAmount,
    LAG(TotalAmount, 2, 0) OVER(ORDER BY OrderDate) AS TwoDaysAgo
FROM DailySales;
```

---

## Part 2: LEAD

Access the value from a following row.

```sql
SELECT 
    OrderDate,
    TotalAmount,
    LEAD(TotalAmount) OVER(ORDER BY OrderDate) AS NextDayAmount
FROM DailySales
ORDER BY OrderDate;
```

---

## Part 3: Period-over-Period Change

```sql
-- Day-over-day change
SELECT 
    OrderDate,
    TotalAmount,
    LAG(TotalAmount) OVER(ORDER BY OrderDate) AS PrevAmount,
    TotalAmount - LAG(TotalAmount) OVER(ORDER BY OrderDate) AS DayOverDayChange,
    CASE 
        WHEN LAG(TotalAmount) OVER(ORDER BY OrderDate) IS NULL THEN NULL
        ELSE ((TotalAmount - LAG(TotalAmount) OVER(ORDER BY OrderDate)) * 100.0 
              / LAG(TotalAmount) OVER(ORDER BY OrderDate))
    END AS PercentChange
FROM DailySales
ORDER BY OrderDate;
```

---

## Part 4: FIRST_VALUE

Returns the first value in the window frame.

```sql
-- Compare each day to the first day of the month
SELECT 
    OrderDate,
    TotalAmount,
    FIRST_VALUE(TotalAmount) OVER(
        PARTITION BY YEAR(OrderDate), MONTH(OrderDate) 
        ORDER BY OrderDate
    ) AS FirstDayAmount
FROM DailySales
ORDER BY OrderDate;
```

---

## Part 5: LAST_VALUE

Returns the last value in the window frame.

**Important:** Default frame ends at CURRENT ROW, so LAST_VALUE often needs explicit frame.

```sql
-- WRONG: LAST_VALUE with default frame (returns current row)
SELECT 
    OrderDate,
    TotalAmount,
    LAST_VALUE(TotalAmount) OVER(
        PARTITION BY YEAR(OrderDate), MONTH(OrderDate) 
        ORDER BY OrderDate
    ) AS LastValue  -- This is just TotalAmount!
FROM DailySales;

-- CORRECT: Extend frame to end of partition
SELECT 
    OrderDate,
    TotalAmount,
    LAST_VALUE(TotalAmount) OVER(
        PARTITION BY YEAR(OrderDate), MONTH(OrderDate) 
        ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LastDayAmount
FROM DailySales
ORDER BY OrderDate;
```

---

## Part 6: Practical Examples

### Example 1: Customer Purchase Patterns

```sql
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount,
    LAG(OrderDate) OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS PrevOrderDate,
    DATEDIFF(day, LAG(OrderDate) OVER(PARTITION BY CustomerID ORDER BY OrderDate), OrderDate) AS DaysSinceLast
FROM Orders
ORDER BY CustomerID, OrderDate;
```

### Example 2: Stock Price Analysis

```sql
SELECT 
    TradeDate,
    ClosePrice,
    LAG(ClosePrice, 1) OVER(ORDER BY TradeDate) AS PrevClose,
    ClosePrice - LAG(ClosePrice, 1) OVER(ORDER BY TradeDate) AS DailyChange,
    FIRST_VALUE(ClosePrice) OVER(
        ORDER BY TradeDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS YearOpen,
    LAST_VALUE(ClosePrice) OVER(
        ORDER BY TradeDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS YearClose
FROM StockPrices
WHERE YEAR(TradeDate) = 2024
ORDER BY TradeDate;
```

### Example 3: Session Gap Analysis

```sql
-- Find gaps > 30 minutes between user actions
WITH Sessions AS (
    SELECT 
        UserID,
        ActionTime,
        LAG(ActionTime) OVER(PARTITION BY UserID ORDER BY ActionTime) AS PrevAction,
        DATEDIFF(minute, 
            LAG(ActionTime) OVER(PARTITION BY UserID ORDER BY ActionTime), 
            ActionTime
        ) AS MinutesSinceLast
    FROM UserActivity
)
SELECT UserID, ActionTime, MinutesSinceLast
FROM Sessions
WHERE MinutesSinceLast > 30 OR MinutesSinceLast IS NULL
ORDER BY UserID, ActionTime;
```

### Example 4: Month-over-Month Growth

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(TotalAmount) AS Revenue
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    Year,
    Month,
    Revenue,
    LAG(Revenue) OVER(ORDER BY Year, Month) AS PrevMonthRevenue,
    Revenue - LAG(Revenue) OVER(ORDER BY Year, Month) AS MoMChange,
    CASE 
        WHEN LAG(Revenue) OVER(ORDER BY Year, Month) IS NULL THEN NULL
        ELSE ((Revenue - LAG(Revenue) OVER(ORDER BY Year, Month)) * 100.0 
              / LAG(Revenue) OVER(ORDER BY Year, Month))
    END AS MoMGrowthPercent
FROM MonthlySales
ORDER BY Year, Month;
```

---

## Part 7: Combining Value Functions

```sql
SELECT 
    ProductID,
    OrderDate,
    UnitPrice,
    LAG(UnitPrice) OVER(PARTITION BY ProductID ORDER BY OrderDate) AS PrevPrice,
    LEAD(UnitPrice) OVER(PARTITION BY ProductID ORDER BY OrderDate) AS NextPrice,
    FIRST_VALUE(UnitPrice) OVER(
        PARTITION BY ProductID ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS InitialPrice,
    LAST_VALUE(UnitPrice) OVER(
        PARTITION BY ProductID ORDER BY OrderDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS CurrentPrice
FROM PriceHistory
ORDER BY ProductID, OrderDate;
```

---

## Part 8: Performance Tips

- Index columns in ORDER BY and PARTITION BY
- Avoid recalculating same window; use CTEs
- LAG/LEAD are generally faster than self-joins
- Be careful with LAST_VALUE frame defaults

---

## Part 9: Handling NULLs

```sql
-- Provide default for missing values
SELECT 
    OrderDate,
    Revenue,
    LAG(Revenue, 1, 0) OVER(ORDER BY OrderDate) AS PrevRevenue,
    COALESCE(
        Revenue - LAG(Revenue) OVER(ORDER BY OrderDate),
        Revenue
    ) AS ChangeFromPrev
FROM DailySales;
```

---

## Practice Exercises

1. Calculate week-over-week sales change using LAG.
2. Show each employee's salary, previous salary, and next salary using LAG and LEAD.
3. Find the first and last order date for each customer using FIRST_VALUE and LAST_VALUE.
4. Calculate the number of days between consecutive logins per user.

---

## Key Takeaways

- LAG/LEAD access previous/next rows (offset, default)
- FIRST_VALUE/LAST_VALUE access frame boundaries
- LAST_VALUE needs explicit frame to avoid CURRENT ROW default
- Use for period-over-period comparisons, trend analysis
- Faster than self-joins for row comparisons

---

## Congratulations!

You've completed the **Intermediate Level** of the SQL course! 🎉

**Next Steps:**
- Review the [Intermediate README](../README.md) for a full lesson overview
- Continue to the [Advanced Level](../../03-advanced/) to master complex queries, optimization, stored procedures, and advanced database techniques
- Practice exercises from each lesson to reinforce your skills

---

## Additional Resources

- [SQL Window Functions Documentation](https://docs.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql)
- [Advanced SQL Patterns](https://www.postgresql.org/docs/current/tutorial-window.html)
- Practice datasets in `03-assets/sql-scripts/`
