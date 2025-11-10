# Lesson 16.1: Analytic Concepts

## Introduction

Analytic functions, also known as **window functions** or **OVER functions**, are among the most powerful features in modern SQL. They allow you to perform calculations across sets of rows that are related to the current row—all while maintaining the detail of individual rows in your result set.

**Estimated Time:** 45 minutes  
**Complexity:** Intermediate-Advanced  
**Prerequisites:** Understanding of GROUP BY, aggregate functions, and JOIN operations

## What Are Analytic Functions?

Analytic functions perform calculations across a set of rows called a **window** that is somehow related to the current row. Unlike GROUP BY, which collapses rows into summary values, analytic functions **preserve row-level detail** while adding calculated columns.

### The Problem with GROUP BY

Consider this common scenario: You want to see each sale alongside the total sales for that product's category.

**With GROUP BY (loses detail):**
```sql
SELECT 
    CategoryID,
    SUM(SalesAmount) AS TotalSales
FROM Sales
GROUP BY CategoryID;
```
**Result:** One row per category (detail lost)

**With Analytic Functions (keeps detail):**
```sql
SELECT 
    SaleID,
    ProductName,
    CategoryID,
    SalesAmount,
    SUM(SalesAmount) OVER(PARTITION BY CategoryID) AS CategoryTotal
FROM Sales;
```
**Result:** All original rows PLUS category total on each row

## The OVER() Clause

The `OVER()` clause defines the **window** of rows for the function to operate on. It's what transforms a regular aggregate function into a window function.

### Basic Syntax

```sql
function_name(...) OVER (
    [PARTITION BY partition_column(s)]
    [ORDER BY sort_column(s)]
    [ROWS|RANGE window_frame]
)
```

### Components

1. **PARTITION BY** (Optional)
   - Divides the result set into partitions
   - Similar to GROUP BY, but doesn't collapse rows
   - The function applies within each partition

2. **ORDER BY** (Optional)
   - Defines the logical order of rows within each partition
   - Required for ranking and offset functions
   - Affects the result of aggregate window functions

3. **Window Frame** (Optional)
   - Defines which rows to include in the calculation
   - Uses ROWS or RANGE with PRECEDING/FOLLOWING
   - We'll cover this in detail in Lesson 8

## PARTITION BY vs GROUP BY

Understanding the difference is crucial:

### GROUP BY
- **Collapses rows** into summary groups
- **Reduces** the number of rows in output
- Returns **only grouped columns** and aggregates
- Cannot mix detail and summary in same row

```sql
-- GROUP BY Example
SELECT 
    Department,
    COUNT(*) AS EmployeeCount,
    AVG(Salary) AS AvgSalary
FROM Employees
GROUP BY Department;
```
**Output:** 3 rows (one per department)

### PARTITION BY (in window functions)
- **Preserves all rows** in the result set
- **Maintains** row-level detail
- Can show **both detail and calculated values**
- More flexible for analysis

```sql
-- PARTITION BY Example
SELECT 
    EmployeeID,
    EmployeeName,
    Department,
    Salary,
    AVG(Salary) OVER(PARTITION BY Department) AS DeptAvgSalary,
    Salary - AVG(Salary) OVER(PARTITION BY Department) AS DiffFromAvg
FROM Employees;
```
**Output:** All employee rows with department averages

## Common Analytic Functions

### 1. Ranking Functions
Calculate ranks, row numbers, and percentiles.

- **ROW_NUMBER()** - Unique sequential number
- **RANK()** - Ranking with gaps for ties
- **DENSE_RANK()** - Ranking without gaps
- **NTILE(n)** - Divide rows into n buckets

```sql
SELECT 
    ProductName,
    Sales,
    ROW_NUMBER() OVER(ORDER BY Sales DESC) AS RowNum,
    RANK() OVER(ORDER BY Sales DESC) AS Rank,
    DENSE_RANK() OVER(ORDER BY Sales DESC) AS DenseRank
FROM Products;
```

### 2. Aggregate Window Functions
Traditional aggregates used with OVER().

- **SUM()** - Running or windowed totals
- **AVG()** - Moving averages
- **COUNT()** - Running counts
- **MIN()/MAX()** - Windowed min/max

```sql
SELECT 
    OrderDate,
    OrderAmount,
    SUM(OrderAmount) OVER(ORDER BY OrderDate) AS RunningTotal,
    AVG(OrderAmount) OVER(ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MovingAvg3
FROM Orders;
```

### 3. Offset Functions
Access values from other rows.

- **LAG()** - Value from previous row(s)
- **LEAD()** - Value from next row(s)
- **FIRST_VALUE()** - First value in window
- **LAST_VALUE()** - Last value in window

```sql
SELECT 
    Month,
    Revenue,
    LAG(Revenue) OVER(ORDER BY Month) AS PreviousMonth,
    Revenue - LAG(Revenue) OVER(ORDER BY Month) AS MonthOverMonthChange
FROM MonthlySales;
```

## When to Use Analytic Functions

### Ideal Use Cases

1. **Running Totals and Cumulative Calculations**
   ```sql
   SUM(Amount) OVER(ORDER BY Date)
   ```

2. **Rankings and Top-N Analysis**
   ```sql
   RANK() OVER(PARTITION BY Category ORDER BY Sales DESC)
   ```

3. **Period-over-Period Comparisons**
   ```sql
   Revenue - LAG(Revenue) OVER(ORDER BY Month)
   ```

4. **Moving Averages**
   ```sql
   AVG(Price) OVER(ORDER BY Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
   ```

5. **Showing Detail with Aggregates**
   ```sql
   Salary, AVG(Salary) OVER(PARTITION BY Department)
   ```

### When NOT to Use

- When you only need summary data (use GROUP BY)
- When performance is critical and simpler alternatives exist
- For very large datasets without proper indexing

## Advantages of Analytic Functions

### 1. Eliminates Self-Joins
**Old way (self-join for running total):**
```sql
SELECT 
    t1.Date,
    t1.Amount,
    SUM(t2.Amount) AS RunningTotal
FROM Transactions t1
JOIN Transactions t2 ON t2.Date <= t1.Date
GROUP BY t1.Date, t1.Amount;
```

**New way (window function):**
```sql
SELECT 
    Date,
    Amount,
    SUM(Amount) OVER(ORDER BY Date) AS RunningTotal
FROM Transactions;
```
✓ Cleaner code  
✓ Better performance  
✓ More readable

### 2. Simplifies Complex Queries
**Old way (subquery for each calculation):**
```sql
SELECT 
    e.Name,
    e.Salary,
    (SELECT AVG(Salary) FROM Employees e2 WHERE e2.Dept = e.Dept) AS DeptAvg,
    (SELECT MAX(Salary) FROM Employees e2 WHERE e2.Dept = e.Dept) AS DeptMax
FROM Employees e;
```

**New way (single pass with window functions):**
```sql
SELECT 
    Name,
    Salary,
    AVG(Salary) OVER(PARTITION BY Dept) AS DeptAvg,
    MAX(Salary) OVER(PARTITION BY Dept) AS DeptMax
FROM Employees;
```

### 3. Enables Advanced Analytics
- Moving averages for trend analysis
- Percentile calculations
- Gap and island detection
- Sessionization
- Cohort analysis

## Performance Considerations

### Advantages
- **Single table scan** instead of multiple subqueries or self-joins
- **Efficient sorting** algorithms
- Can use indexes effectively

### Considerations
- Requires **sorting** (may use tempdb)
- Large partitions can use significant **memory**
- **Multiple window functions** with same specification share computation

### Optimization Tips

1. **Index partition and order columns**
   ```sql
   CREATE INDEX IX_Sales_CategoryDate 
   ON Sales(CategoryID, SaleDate);
   
   -- Used by:
   SUM(Amount) OVER(PARTITION BY CategoryID ORDER BY SaleDate)
   ```

2. **Group identical window specifications**
   ```sql
   -- Efficient (same window spec)
   SELECT 
       SUM(Amount) OVER(PARTITION BY Category ORDER BY Date) AS RunTotal,
       AVG(Amount) OVER(PARTITION BY Category ORDER BY Date) AS RunAvg
   FROM Sales;
   ```

3. **Filter before windowing**
   ```sql
   -- Filter first, then calculate
   SELECT 
       SUM(Amount) OVER(ORDER BY Date) AS RunningTotal
   FROM Sales
   WHERE Year = 2024;  -- Filter reduces data for window function
   ```

## Conceptual Examples

### Example 1: Department Analysis

**Scenario:** Show each employee's salary alongside department statistics.

```sql
SELECT 
    EmployeeName,
    Department,
    Salary,
    -- Department aggregates without losing employee detail
    AVG(Salary) OVER(PARTITION BY Department) AS DeptAvgSalary,
    MAX(Salary) OVER(PARTITION BY Department) AS DeptMaxSalary,
    COUNT(*) OVER(PARTITION BY Department) AS DeptEmployeeCount,
    -- How does this employee compare?
    Salary - AVG(Salary) OVER(PARTITION BY Department) AS DiffFromDeptAvg
FROM Employees;
```

**What it does:**
- Shows every employee (all detail preserved)
- Adds department-level statistics to each row
- Enables employee-to-department comparisons

### Example 2: Sales Trends

**Scenario:** Track daily sales with running totals and moving averages.

```sql
SELECT 
    SaleDate,
    DailySales,
    -- Running total
    SUM(DailySales) OVER(ORDER BY SaleDate) AS CumulativeSales,
    -- 7-day moving average
    AVG(DailySales) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7Day,
    -- Compare to previous day
    LAG(DailySales) OVER(ORDER BY SaleDate) AS PreviousDaySales
FROM DailySalesData;
```

**What it shows:**
- Daily detail retained
- Cumulative progress tracked
- Trends smoothed with moving average
- Day-over-day comparisons

### Example 3: Product Rankings

**Scenario:** Rank products overall and within each category.

```sql
SELECT 
    ProductName,
    Category,
    UnitsSold,
    -- Overall ranking
    RANK() OVER(ORDER BY UnitsSold DESC) AS OverallRank,
    -- Ranking within category
    RANK() OVER(PARTITION BY Category ORDER BY UnitsSold DESC) AS CategoryRank
FROM Products;
```

**What it reveals:**
- Overall best sellers
- Best sellers per category
- Multi-dimensional rankings

## Common Patterns

### Pattern 1: Top N per Group
Find top 3 products per category by sales.

```sql
SELECT *
FROM (
    SELECT 
        Category,
        ProductName,
        Sales,
        ROW_NUMBER() OVER(PARTITION BY Category ORDER BY Sales DESC) AS rn
    FROM Products
) ranked
WHERE rn <= 3;
```

### Pattern 2: Running Percentage
Calculate percentage of cumulative total.

```sql
SELECT 
    Product,
    Sales,
    SUM(Sales) OVER(ORDER BY Sales DESC) AS RunningTotal,
    100.0 * SUM(Sales) OVER(ORDER BY Sales DESC) / 
            SUM(Sales) OVER() AS CumulativePercent
FROM Products;
```

### Pattern 3: Change Detection
Identify when values change from previous row.

```sql
SELECT 
    Date,
    Status,
    LAG(Status) OVER(ORDER BY Date) AS PreviousStatus,
    CASE 
        WHEN Status <> LAG(Status) OVER(ORDER BY Date) THEN 1 
        ELSE 0 
    END AS StatusChanged
FROM StatusHistory;
```

## Key Concepts Summary

### Window Functions...
✓ Perform calculations across related rows  
✓ Preserve row-level detail (unlike GROUP BY)  
✓ Use the OVER() clause to define windows  
✓ Can partition data (like GROUP BY)  
✓ Can order data within partitions  
✓ Support frames to fine-tune window boundaries  

### PARTITION BY...
✓ Divides data into groups  
✓ Functions operate independently per partition  
✓ Optional (omit for whole result set)  
✓ Can use multiple columns  

### ORDER BY (in OVER)...
✓ Defines logical order within partition  
✓ Required for ranking/offset functions  
✓ Affects aggregate function results  
✓ Can use multiple columns  

## Next Steps

In **Lesson 2: Data Windows**, you'll practice:
- Using PARTITION BY to divide data
- Applying ORDER BY within windows
- Combining multiple window specifications
- Handling NULLs in window functions

In **Lesson 3: Localized Sorting**, you'll learn:
- Sorting within partitions
- Multi-level sorting
- Managing sort direction per column

## Practice Mindset

As you work through the hands-on lessons:

1. **Compare with GROUP BY** - Notice when you preserve detail
2. **Experiment with partitions** - See how PARTITION BY divides calculations
3. **Observe ordering effects** - Notice how ORDER BY changes results
4. **Start simple** - Master basic patterns before complex ones
5. **Read query execution** - Understand what each OVER() does

## Conclusion

Analytic functions open up a new dimension of SQL capabilities. They bridge the gap between row-level detail and aggregate analysis, enabling sophisticated calculations that would be cumbersome or impossible with traditional SQL constructs.

**Key Takeaway:** Window functions let you answer questions like "Show me each sale along with how it compares to the average for its category" in a single, efficient query.

Ready to start practicing? Continue to **Lesson 2: Data Windows** to begin hands-on work with PARTITION BY and ORDER BY.

---

**Remember:** The best way to master window functions is through practice. Each lesson builds on the previous one, so take your time and experiment with the examples!
