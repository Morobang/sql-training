# Window Functions

## Introduction

Window functions perform calculations across a set of table rows that are related to the current row. Unlike GROUP BY, window functions do not collapse rows—each row retains its identity while gaining access to aggregated or analytical values from related rows.

## Core Concepts

### What Are Window Functions?

Window functions operate on a "window" of rows defined by:
- **PARTITION BY**: Divides rows into groups (like GROUP BY, but doesn't collapse)
- **ORDER BY**: Defines row order within partitions
- **Frame specification**: Defines which rows within the partition to include

### Syntax

```sql
function_name (expression) OVER (
    [PARTITION BY partition_expression]
    [ORDER BY sort_expression]
    [frame_specification]
)
```

## Categories of Window Functions

| Category | Functions | Purpose |
|----------|-----------|---------|
| **Aggregate** | SUM, AVG, COUNT, MIN, MAX | Running totals, moving averages |
| **Ranking** | ROW_NUMBER, RANK, DENSE_RANK, NTILE | Assign ranks, top-N queries |
| **Value** | LAG, LEAD, FIRST_VALUE, LAST_VALUE | Access other rows, period comparisons |
| **Statistical** | PERCENT_RANK, CUME_DIST, PERCENTILE_CONT | Percentiles, distributions |

## Window Frame Specifications

### ROWS vs RANGE

| Type | Description | Use Case |
|------|-------------|----------|
| **ROWS** | Physical row count | Moving averages (exactly N rows) |
| **RANGE** | Logical range (includes ties) | All rows with same value |

### Frame Boundaries

```sql
-- Common frame specifications:

-- All preceding rows
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Last 7 rows (including current)
ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

-- Centered window (3 before, current, 3 after)
ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING

-- All rows in partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- Current row only
ROWS BETWEEN CURRENT ROW AND CURRENT ROW
```

### Default Frame

When ORDER BY is present without explicit frame:
```
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

## Aggregate Window Functions

### Running Totals

```sql
SELECT 
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal
FROM Sales;
```

### Moving Averages

```sql
-- 7-day moving average
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7Day
FROM Sales;
```

### Partition Examples

```sql
-- Running total per customer
SELECT 
    CustomerID,
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY SaleDate
    ) AS CustomerRunningTotal
FROM Sales;
```

## Ranking Functions

### ROW_NUMBER

Unique sequential number (arbitrary for ties).

```sql
SELECT 
    ProductName,
    Price,
    ROW_NUMBER() OVER (ORDER BY Price DESC) AS RowNum
FROM Products;
```

### RANK

Rank with gaps for ties (1, 2, 2, 4...).

```sql
SELECT 
    ProductName,
    Price,
    RANK() OVER (ORDER BY Price DESC) AS Rank
FROM Products;
```

### DENSE_RANK

Rank without gaps (1, 2, 2, 3...).

```sql
SELECT 
    ProductName,
    Price,
    DENSE_RANK() OVER (ORDER BY Price DESC) AS DenseRank
FROM Products;
```

### NTILE

Divides rows into N buckets.

```sql
-- Quartiles
SELECT 
    ProductName,
    Price,
    NTILE(4) OVER (ORDER BY Price) AS PriceQuartile
FROM Products;
```

### Comparison

| Function | Handles Ties | Sequential | Use Case |
|----------|--------------|------------|----------|
| ROW_NUMBER | Arbitrary order | Yes | Pagination, deduplication |
| RANK | Same rank, skip next | No | Olympic-style ranking |
| DENSE_RANK | Same rank, no skip | Yes | Continuous ranking |
| NTILE | Distributed evenly | Grouped | Percentiles, ABC analysis |

## Value Functions

### LAG and LEAD

Access previous/next row values.

```sql
-- Previous and next sale amounts
SELECT 
    SaleDate,
    TotalAmount,
    LAG(TotalAmount) OVER (ORDER BY SaleDate) AS PrevAmount,
    LEAD(TotalAmount) OVER (ORDER BY SaleDate) AS NextAmount
FROM Sales;

-- With offset and default
LAG(TotalAmount, 2, 0) OVER (ORDER BY SaleDate)  -- 2 rows back, default 0
```

### FIRST_VALUE and LAST_VALUE

```sql
-- First sale of each month
SELECT 
    SaleDate,
    TotalAmount,
    FIRST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate)
        ORDER BY SaleDate
    ) AS FirstSaleOfMonth
FROM Sales;

-- ⚠️ LAST_VALUE needs explicit frame!
SELECT 
    SaleDate,
    TotalAmount,
    LAST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate)
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LastSaleOfMonth
FROM Sales;
```

## Common Use Cases

### Top-N Per Group

```sql
-- Top 3 products per category by price
WITH Ranked AS (
    SELECT 
        ProductName,
        Category,
        Price,
        ROW_NUMBER() OVER (
            PARTITION BY Category 
            ORDER BY Price DESC
        ) AS Rank
    FROM Products
)
SELECT ProductName, Category, Price
FROM Ranked
WHERE Rank <= 3;
```

### Period-over-Period Analysis

```sql
-- Month-over-month growth
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS Year,
        MONTH(SaleDate) AS Month,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    Year,
    Month,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year, Month) AS PrevMonthRevenue,
    Revenue - LAG(Revenue) OVER (ORDER BY Year, Month) AS MoMChange,
    ((Revenue - LAG(Revenue) OVER (ORDER BY Year, Month)) * 100.0 
     / LAG(Revenue) OVER (ORDER BY Year, Month)) AS MoMGrowthPct
FROM MonthlySales;
```

### Deduplication

```sql
-- Remove duplicates, keeping most recent
WITH Duplicates AS (
    SELECT 
        CustomerID,
        Email,
        JoinDate,
        ROW_NUMBER() OVER (
            PARTITION BY Email 
            ORDER BY JoinDate DESC
        ) AS RowNum
    FROM Customers
)
DELETE FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID FROM Duplicates WHERE RowNum > 1
);
```

### Gaps and Islands

```sql
-- Find session gaps (> 30 minutes between actions)
WITH Sessions AS (
    SELECT 
        CustomerID,
        SaleDate,
        LAG(SaleDate) OVER (
            PARTITION BY CustomerID 
            ORDER BY SaleDate
        ) AS PrevSaleDate,
        DATEDIFF(MINUTE, 
            LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate), 
            SaleDate
        ) AS MinutesSinceLast
    FROM Sales
)
SELECT CustomerID, SaleDate, MinutesSinceLast
FROM Sessions
WHERE MinutesSinceLast > 30 OR MinutesSinceLast IS NULL;
```

## Performance Considerations

### Indexing

```sql
-- Index columns in ORDER BY and PARTITION BY
CREATE INDEX IX_Sales_CustomerDate ON Sales (CustomerID, SaleDate);
```

### Optimization Tips

1. **Use ROWS instead of RANGE** when possible (ROWS is faster)
2. **Avoid recalculating windows**: Use CTEs or variables
3. **Limit frame size**: Large frames (millions of rows) are expensive
4. **Index appropriately**: Index PARTITION BY and ORDER BY columns
5. **Materialize intermediate results**: For complex calculations

### Avoid Redundant Calculations

```sql
-- ❌ BAD: Recalculating same window
SELECT 
    SaleDate,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) * 0.1 AS RunningTax
FROM Sales;

-- ✅ GOOD: Calculate once, use CTE
WITH Totals AS (
    SELECT 
        SaleDate,
        TotalAmount,
        SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal
    FROM Sales
)
SELECT 
    SaleDate,
    RunningTotal,
    RunningTotal * 0.1 AS RunningTax
FROM Totals;
```

## Best Practices

### ✅ DO

1. **Index PARTITION BY and ORDER BY columns**
2. **Use CTEs to avoid recalculating windows**
3. **Use ROWS instead of RANGE when exact row count needed**
4. **Specify explicit frames for LAST_VALUE**
5. **Use LAG/LEAD instead of self-joins**
6. **Test with production-like data volumes**

### ❌ DON'T

1. **Don't use window functions for simple aggregates** (GROUP BY is faster)
2. **Don't create unnecessarily large frames**
3. **Don't forget default frame with ORDER BY** (RANGE UNBOUNDED PRECEDING TO CURRENT ROW)
4. **Don't use LAST_VALUE without explicit frame**
5. **Don't ignore NULL handling** (use COALESCE or default values)

## Common Patterns

### Pagination

```sql
-- ROW_NUMBER approach
WITH Paginated AS (
    SELECT 
        ProductID,
        ProductName,
        ROW_NUMBER() OVER (ORDER BY ProductName) AS RowNum
    FROM Products
)
SELECT ProductID, ProductName
FROM Paginated
WHERE RowNum BETWEEN 21 AND 30;  -- Page 3 (rows 21-30)

-- OFFSET/FETCH approach (SQL Server 2012+)
SELECT ProductID, ProductName
FROM Products
ORDER BY ProductName
OFFSET 20 ROWS FETCH NEXT 10 ROWS ONLY;
```

### Percentiles

```sql
-- Salary percentiles
SELECT 
    EmployeeID,
    Salary,
    NTILE(100) OVER (ORDER BY Salary) AS Percentile
FROM Employees;
```

### Running Differences

```sql
-- Daily change from previous day
SELECT 
    SaleDate,
    TotalAmount,
    TotalAmount - LAG(TotalAmount) OVER (ORDER BY SaleDate) AS DailyChange
FROM DailySales;
```

## Next Steps

Practice window functions in:
- **01-aggregate-windows.sql**: Running totals, moving averages, frames
- **02-ranking-functions.sql**: ROW_NUMBER, RANK, DENSE_RANK, NTILE, top-N
- **03-value-functions.sql**: LAG, LEAD, FIRST_VALUE, LAST_VALUE, comparisons

## Further Reading

- [SQL Server Window Functions](https://learn.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql)
- [Window Function Framing](https://www.postgresql.org/docs/current/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS)
- Itzik Ben-Gan: "T-SQL Querying" (Microsoft Press)
- Window Functions vs GROUP BY performance
