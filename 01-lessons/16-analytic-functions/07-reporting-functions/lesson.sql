/*
================================================================================
LESSON 16.7: REPORTING FUNCTIONS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use aggregate functions as window functions (SUM, AVG, COUNT OVER)
2. Calculate running totals and cumulative sums
3. Create moving averages and rolling calculations
4. Compute YTD, QTD, and MTD metrics
5. Compare current values to aggregates
6. Build sophisticated analytical reports

Business Context:
-----------------
Aggregate window functions are essential for reporting and analysis. Running
totals show cumulative progress, moving averages smooth out fluctuations, and
comparisons to totals show relative performance. These functions power
dashboards, financial reports, and KPI tracking.

Database: RetailStore
Complexity: Intermediate to Advanced
Estimated Time: 55 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: BASIC AGGREGATE WINDOW FUNCTIONS
================================================================================

Aggregate functions (SUM, AVG, COUNT, MIN, MAX) can be used as window
functions with OVER(). Unlike GROUP BY, they don't collapse rows.
*/

-- Example 1: Compare individual values to totals
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    Region,
    -- Total across all rows
    SUM(SaleAmount) OVER() AS GrandTotal,
    -- Percentage of total
    SaleAmount * 100.0 / SUM(SaleAmount) OVER() AS PctOfTotal,
    -- Average across all rows
    AVG(SaleAmount) OVER() AS OverallAvg,
    -- Comparison to average
    SaleAmount - AVG(SaleAmount) OVER() AS DiffFromAvg
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleAmount DESC;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   Region   GrandTotal   PctOfTotal  OverallAvg   DiffFromAvg
------  ----------  -----------  -------  -----------  ----------  -----------  -----------
10      2024-04-10  12999.90     Central  37809.38     34.39       3150.78      9849.12
5       2024-03-05  10399.92     East     37809.38     27.51       3150.78      7249.14
1       2024-01-15  6499.95      East     37809.38     17.19       3150.78      3349.17
8       2024-04-01  2799.96      Central  37809.38     7.41        3150.78      -350.82
3       2024-02-10  2099.97      West     37809.38     5.55        3150.78      -1050.81
...

Each row shows its relation to the whole!
*/

-- Example 2: Aggregates within partitions
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    -- Regional totals and averages
    SUM(SaleAmount) OVER(PARTITION BY Region) AS RegionTotal,
    AVG(SaleAmount) OVER(PARTITION BY Region) AS RegionAvg,
    COUNT(*) OVER(PARTITION BY Region) AS RegionSalesCount,
    -- Percentage within region
    SaleAmount * 100.0 / SUM(SaleAmount) OVER(PARTITION BY Region) AS PctOfRegion
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleDate;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionTotal  RegionAvg    RegionSalesCount  PctOfRegion
-------  ----------  -----------  -----------  -----------  ----------------  -----------
Central  2024-04-01  2799.96      16099.80     5366.60      3                 17.39
Central  2024-04-05  299.94       16099.80     5366.60      3                 1.86
Central  2024-04-10  12999.90     16099.80     5366.60      3                 80.75
East     2024-01-15  6499.95      18799.68     3759.94      5                 34.57
East     2024-01-20  299.90       18799.68     3759.94      5                 1.60
East     2024-03-05  10399.92     18799.68     3759.94      5                 55.32
East     2024-03-10  1599.96      18799.68     3759.94      5                 8.51
...

Each region shows its own aggregates!
*/

-- Example 3: Multiple aggregates for statistical analysis
SELECT 
    p.ProductName,
    s.SaleAmount,
    COUNT(*) OVER(PARTITION BY p.ProductID) AS TransactionCount,
    SUM(s.SaleAmount) OVER(PARTITION BY p.ProductID) AS TotalSales,
    AVG(s.SaleAmount) OVER(PARTITION BY p.ProductID) AS AvgSale,
    MIN(s.SaleAmount) OVER(PARTITION BY p.ProductID) AS MinSale,
    MAX(s.SaleAmount) OVER(PARTITION BY p.ProductID) AS MaxSale,
    MAX(s.SaleAmount) OVER(PARTITION BY p.ProductID) - 
    MIN(s.SaleAmount) OVER(PARTITION BY p.ProductID) AS SaleRange
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
ORDER BY p.ProductName, s.SaleAmount;
GO

/*
OUTPUT:
ProductName       SaleAmount   TransactionCount  TotalSales   AvgSale      MinSale     MaxSale      SaleRange
----------------  -----------  ----------------  -----------  -----------  ----------  -----------  ---------
Keyboard Mech     449.85       1                 449.85       449.85       449.85      449.85       0.00
Laptop Basic      4899.93      1                 4899.93      4899.93      4899.93     4899.93      0.00
Laptop Pro        6499.95      4                 29899.77     7474.94      6499.95     12999.90     6499.95
Laptop Pro        10399.92     4                 29899.77     7474.94      6499.95     12999.90     6499.95
Laptop Pro        10399.92     4                 29899.77     7474.94      6499.95     12999.90     6499.95
Laptop Pro        12999.90     4                 29899.77     7474.94      6499.95     12999.90     6499.95
...

Statistical summary for each product!
*/

/*
================================================================================
PART 2: RUNNING TOTALS AND CUMULATIVE CALCULATIONS
================================================================================

Running totals accumulate values row by row. Essential for financial reports,
progress tracking, and trend analysis.
*/

-- Example 1: Simple running total with ORDER BY
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(ORDER BY SaleDate) AS RunningTotal
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RunningTotal
------  ----------  -----------  ------------
1       2024-01-15  6499.95      6499.95
2       2024-01-20  299.90       6799.85
3       2024-02-10  2099.97      8899.82
4       2024-02-15  179.98       9079.80
5       2024-03-05  10399.92     19479.72
6       2024-03-10  1599.96      21079.68
7       2024-03-20  449.85       21529.53
8       2024-04-01  2799.96      24329.49
9       2024-04-05  299.94       24629.43
10      2024-04-10  12999.90     37629.33

Cumulative sum grows with each row!
*/

-- Example 2: Running totals within partitions
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS RegionRunningTotal,
    -- Also show overall running total for comparison
    SUM(SaleAmount) OVER(ORDER BY SaleDate) AS OverallRunningTotal
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleDate;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionRunningTotal  OverallRunningTotal
-------  ----------  -----------  ------------------  -------------------
Central  2024-04-01  2799.96      2799.96             24329.49
Central  2024-04-05  299.94       3099.90             24629.43
Central  2024-04-10  12999.90     16099.80            37629.33
East     2024-01-15  6499.95      6499.95             6499.95
East     2024-01-20  299.90       6799.85             6799.85
East     2024-03-05  10399.92     17199.77            19479.72
East     2024-03-10  1599.96      18799.73            21079.68
East     2024-05-01  299.90       19099.63            38229.23
West     2024-02-10  2099.97      2099.97             8899.82
West     2024-02-15  179.98       2279.95             9079.80
...

Running totals restart per region!
*/

-- Example 3: Running count and running average
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    COUNT(*) OVER(ORDER BY SaleDate) AS TransactionNumber,
    SUM(SaleAmount) OVER(ORDER BY SaleDate) AS RunningTotal,
    AVG(SaleAmount) OVER(ORDER BY SaleDate) AS RunningAverage,
    -- Current value vs running average
    SaleAmount - AVG(SaleAmount) OVER(ORDER BY SaleDate) AS DiffFromRunningAvg
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   TransactionNumber  RunningTotal  RunningAverage  DiffFromRunningAvg
------  ----------  -----------  -----------------  ------------  --------------  ------------------
1       2024-01-15  6499.95      1                  6499.95       6499.95         0.00
2       2024-01-20  299.90       2                  6799.85       3399.93         -3100.03
3       2024-02-10  2099.97      3                  8899.82       2966.61         -866.64
4       2024-02-15  179.98       4                  9079.80       2269.95         -2089.97
5       2024-03-05  10399.92     5                  19479.72      3895.94         6503.98
...

Running average changes with each new transaction!
*/

/*
================================================================================
PART 3: MOVING AVERAGES AND ROLLING CALCULATIONS
================================================================================

Moving averages smooth out short-term fluctuations to show trends.
We'll cover this more in Lesson 16.8 on Window Frames.
*/

-- Example 1: Simple moving average preview (detailed in next lesson)
SELECT 
    SaleDate,
    SaleAmount,
    -- Average of current and previous 2 rows (3-day moving average)
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Day
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   MovingAvg3Day
----------  -----------  -------------
2024-01-15  6499.95      6499.95        -- Only 1 row
2024-01-20  299.90       3399.93        -- Average of 2 rows
2024-02-10  2099.97      2966.61        -- Average of 3 rows
2024-02-15  179.98       859.95         -- Average of 3 rows
2024-03-05  10399.92     4226.62        -- Average of 3 rows
...

Smooths out fluctuations!
*/

/*
================================================================================
PART 4: YEAR-TO-DATE, QUARTER-TO-DATE, MONTH-TO-DATE
================================================================================

Period-to-date calculations are essential for financial reporting.
*/

-- Example 1: Month-to-Date (MTD) calculations
SELECT 
    SaleDate,
    SaleAmount,
    YEAR(SaleDate) AS SaleYear,
    MONTH(SaleDate) AS SaleMonth,
    -- MTD total
    SUM(SaleAmount) OVER(
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
    ) AS MTDTotal,
    -- MTD count
    COUNT(*) OVER(
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
    ) AS MTDCount
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   SaleYear  SaleMonth  MTDTotal     MTDCount
----------  -----------  --------  ---------  -----------  --------
2024-01-15  6499.95      2024      1          6499.95      1
2024-01-20  299.90       2024      1          6799.85      2
2024-02-10  2099.97      2024      2          2099.97      1        -- Resets for Feb
2024-02-15  179.98       2024      2          2279.95      2
2024-03-05  10399.92     2024      3          10399.92     1        -- Resets for Mar
2024-03-10  1599.96      2024      3          11999.88     2
2024-03-20  449.85       2024      3          12449.73     3
2024-04-01  2799.96      2024      4          2799.96      1        -- Resets for Apr
...

Resets each month!
*/

-- Example 2: Quarter-to-Date (QTD) calculations
SELECT 
    SaleDate,
    SaleAmount,
    YEAR(SaleDate) AS SaleYear,
    DATEPART(QUARTER, SaleDate) AS SaleQuarter,
    -- QTD total
    SUM(SaleAmount) OVER(
        PARTITION BY YEAR(SaleDate), DATEPART(QUARTER, SaleDate) 
        ORDER BY SaleDate
    ) AS QTDTotal,
    -- QTD average
    AVG(SaleAmount) OVER(
        PARTITION BY YEAR(SaleDate), DATEPART(QUARTER, SaleDate) 
        ORDER BY SaleDate
    ) AS QTDAverage
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   SaleYear  SaleQuarter  QTDTotal     QTDAverage
----------  -----------  --------  -----------  -----------  ----------
2024-01-15  6499.95      2024      1            6499.95      6499.95
2024-01-20  299.90       2024      1            6799.85      3399.93
2024-02-10  2099.97      2024      1            8899.82      2966.61
2024-02-15  179.98       2024      1            9079.80      2269.95
2024-03-05  10399.92     2024      1            19479.72     3895.94
2024-03-10  1599.96      2024      1            21079.68     3513.28
2024-03-20  449.85       2024      1            21529.53     3075.65
2024-04-01  2799.96      2024      2            2799.96      2799.96    -- Resets for Q2
...

Accumulates across entire quarter!
*/

-- Example 3: Year-to-Date (YTD) with comparisons
SELECT 
    SaleDate,
    SaleAmount,
    Region,
    -- YTD total
    SUM(SaleAmount) OVER(
        PARTITION BY YEAR(SaleDate) 
        ORDER BY SaleDate
    ) AS YTDTotal,
    -- YTD by region
    SUM(SaleAmount) OVER(
        PARTITION BY YEAR(SaleDate), Region 
        ORDER BY SaleDate
    ) AS YTDRegionTotal,
    -- Percent of YTD total
    SaleAmount * 100.0 / SUM(SaleAmount) OVER(
        PARTITION BY YEAR(SaleDate) 
        ORDER BY SaleDate
    ) AS PctOfYTD
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
================================================================================
PART 5: COMPARING TO AGGREGATES
================================================================================

Window functions let you compare individual values to group statistics
without collapsing rows.
*/

-- Example 1: Compare sales to regional averages
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    Region,
    AVG(SaleAmount) OVER(PARTITION BY Region) AS RegionAvg,
    SaleAmount - AVG(SaleAmount) OVER(PARTITION BY Region) AS DiffFromRegionAvg,
    CASE 
        WHEN SaleAmount > AVG(SaleAmount) OVER(PARTITION BY Region) 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS Performance
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleAmount DESC;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   Region   RegionAvg    DiffFromRegionAvg  Performance
------  ----------  -----------  -------  -----------  -----------------  --------------
10      2024-04-10  12999.90     Central  5366.60      7633.30            Above Average
8       2024-04-01  2799.96      Central  5366.60      -2566.64           Below Average
9       2024-04-05  299.94       Central  5366.60      -5066.66           Below Average
5       2024-03-05  10399.92     East     3759.94      6639.98            Above Average
1       2024-01-15  6499.95      East     3759.94      2740.01            Above Average
...

Each sale compared to its region!
*/

-- Example 2: Top performers by percentage above average
SELECT 
    c.CustomerName,
    SUM(s.SaleAmount) AS TotalSpent,
    AVG(SUM(s.SaleAmount)) OVER() AS OverallAvg,
    SUM(s.SaleAmount) - AVG(SUM(s.SaleAmount)) OVER() AS DiffFromAvg,
    (SUM(s.SaleAmount) - AVG(SUM(s.SaleAmount)) OVER()) * 100.0 / 
        AVG(SUM(s.SaleAmount)) OVER() AS PctAboveAvg,
    CASE 
        WHEN SUM(s.SaleAmount) > AVG(SUM(s.SaleAmount)) OVER() * 1.5 
        THEN 'Top Tier'
        WHEN SUM(s.SaleAmount) > AVG(SUM(s.SaleAmount)) OVER() 
        THEN 'Above Average'
        ELSE 'Standard'
    END AS CustomerTier
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpent DESC;
GO

/*
OUTPUT:
CustomerName    TotalSpent   OverallAvg   DiffFromAvg  PctAboveAvg  CustomerTier
--------------  -----------  -----------  -----------  -----------  -------------
Enterprise LLC  12999.90     7774.95      5224.95      67.20        Above Average
Acme Corp       7099.75      7774.95      -675.20      -8.68        Standard
Global Traders  4899.93      7774.95      -2875.02     -36.98       Standard
...

Customers classified by spending relative to average!
*/

-- Example 3: Product performance matrix
SELECT 
    p.ProductName,
    p.Category,
    SUM(s.SaleAmount) AS TotalSales,
    SUM(s.Quantity) AS TotalQuantity,
    -- Compare to category averages
    AVG(SUM(s.SaleAmount)) OVER(PARTITION BY p.Category) AS CategoryAvgSales,
    AVG(SUM(s.Quantity)) OVER(PARTITION BY p.Category) AS CategoryAvgQuantity,
    -- Performance vs category
    CASE 
        WHEN SUM(s.SaleAmount) >= AVG(SUM(s.SaleAmount)) OVER(PARTITION BY p.Category) 
         AND SUM(s.Quantity) >= AVG(SUM(s.Quantity)) OVER(PARTITION BY p.Category) 
        THEN 'Star in Category'
        WHEN SUM(s.SaleAmount) >= AVG(SUM(s.SaleAmount)) OVER(PARTITION BY p.Category) 
        THEN 'High Revenue'
        WHEN SUM(s.Quantity) >= AVG(SUM(s.Quantity)) OVER(PARTITION BY p.Category) 
        THEN 'High Volume'
        ELSE 'Below Average'
    END AS CategoryPerformance
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY p.Category, TotalSales DESC;
GO

/*
================================================================================
PART 6: PRACTICAL REPORTING APPLICATIONS
================================================================================
*/

-- Application 1: Monthly sales report with YTD
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        DATENAME(MONTH, SaleDate) AS MonthName,
        SUM(SaleAmount) AS MonthTotal,
        COUNT(*) AS MonthTransactions
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
    GROUP BY YEAR(SaleDate), MONTH(SaleDate), DATENAME(MONTH, SaleDate)
)
SELECT 
    SaleYear,
    MonthName,
    MonthTotal,
    MonthTransactions,
    SUM(MonthTotal) OVER(
        PARTITION BY SaleYear 
        ORDER BY SaleMonth
    ) AS YTDTotal,
    SUM(MonthTransactions) OVER(
        PARTITION BY SaleYear 
        ORDER BY SaleMonth
    ) AS YTDTransactions,
    AVG(MonthTotal) OVER(
        PARTITION BY SaleYear 
        ORDER BY SaleMonth
    ) AS YTDAvgMonthly,
    MonthTotal * 100.0 / SUM(MonthTotal) OVER(PARTITION BY SaleYear) AS PctOfYearTotal
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

-- Application 2: Customer lifetime value tracking
SELECT 
    c.CustomerName,
    s.SaleDate,
    s.SaleAmount,
    ROW_NUMBER() OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate) AS PurchaseNumber,
    SUM(s.SaleAmount) OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS LifetimeValue,
    AVG(s.SaleAmount) OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS AvgPurchaseValue,
    COUNT(*) OVER(PARTITION BY c.CustomerID) AS TotalPurchases
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, s.SaleDate;
GO

/*
OUTPUT:
CustomerName    SaleDate    SaleAmount   PurchaseNumber  LifetimeValue  AvgPurchaseValue  TotalPurchases
--------------  ----------  -----------  --------------  -------------  ----------------  --------------
Acme Corp       2024-01-15  6499.95      1               6499.95        6499.95           3
Acme Corp       2024-01-20  299.90       2               6799.85        3399.93           3
Acme Corp       2024-05-01  299.90       3               7099.75        2366.58           3
...

Track customer value over time!
*/

-- Application 3: Regional performance dashboard
SELECT 
    Region,
    COUNT(*) AS SalesCount,
    SUM(SaleAmount) AS TotalRevenue,
    AVG(SaleAmount) AS AvgSale,
    -- Compare to overall metrics
    SUM(SaleAmount) * 100.0 / SUM(SUM(SaleAmount)) OVER() AS PctOfTotalRevenue,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS PctOfTotalTransactions,
    AVG(SaleAmount) - AVG(AVG(SaleAmount)) OVER() AS DiffFromOverallAvg,
    -- Regional performance grade
    CASE 
        WHEN SUM(SaleAmount) >= AVG(SUM(SaleAmount)) OVER() * 1.2 THEN 'A'
        WHEN SUM(SaleAmount) >= AVG(SUM(SaleAmount)) OVER() THEN 'B'
        WHEN SUM(SaleAmount) >= AVG(SUM(SaleAmount)) OVER() * 0.8 THEN 'C'
        ELSE 'D'
    END AS PerformanceGrade
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
GROUP BY Region
ORDER BY TotalRevenue DESC;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Product Performance Report
---------------------------------------
Create a comprehensive product report with:
- Product name and total sales
- Running total of sales (ordered by sales amount)
- Percentage of grand total
- Difference from average product sales
- Cumulative percentage (running % of total)
- Flag products contributing to top 80% of sales

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Customer Purchase Trends
-------------------------------------
For each customer purchase, show:
- Customer name, sale date, sale amount
- Purchase number for that customer
- Customer's running total (lifetime value)
- Customer's running average purchase
- Days since customer's previous purchase (use LAG)
- MTD count of purchases for that customer

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Monthly Trending Report
------------------------------------
Create a monthly report showing:
- Year, month, total sales, transaction count
- YTD total and YTD transaction count
- Month-over-month change (amount and percentage)
- 3-month moving average of sales
- Classify month as "Growing", "Stable", or "Declining" based on MoM change

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Product Performance Report
SELECT 
    p.ProductName,
    SUM(s.SaleAmount) AS TotalSales,
    SUM(SUM(s.SaleAmount)) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RunningTotal,
    SUM(s.SaleAmount) * 100.0 / SUM(SUM(s.SaleAmount)) OVER() AS PctOfTotal,
    SUM(s.SaleAmount) - AVG(SUM(s.SaleAmount)) OVER() AS DiffFromAvg,
    SUM(SUM(s.SaleAmount)) OVER(ORDER BY SUM(s.SaleAmount) DESC) * 100.0 / 
        SUM(SUM(s.SaleAmount)) OVER() AS CumulativePct,
    CASE 
        WHEN SUM(SUM(s.SaleAmount)) OVER(ORDER BY SUM(s.SaleAmount) DESC) * 100.0 / 
             SUM(SUM(s.SaleAmount)) OVER() <= 80 
        THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END AS SalesContribution
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName
ORDER BY TotalSales DESC;
GO

-- Solution 2: Customer Purchase Trends
SELECT 
    c.CustomerName,
    s.SaleDate,
    s.SaleAmount,
    ROW_NUMBER() OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate) AS PurchaseNumber,
    SUM(s.SaleAmount) OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS LifetimeValue,
    AVG(s.SaleAmount) OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS RunningAvgPurchase,
    DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    ) AS DaysSincePrevious,
    SUM(CASE 
        WHEN YEAR(s.SaleDate) = YEAR(s.SaleDate) 
         AND MONTH(s.SaleDate) = MONTH(s.SaleDate) 
        THEN 1 ELSE 0 
    END) OVER(
        PARTITION BY c.CustomerID, YEAR(s.SaleDate), MONTH(s.SaleDate) 
        ORDER BY s.SaleDate
    ) AS MTDPurchaseCount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, s.SaleDate;
GO

-- Solution 3: Monthly Trending Report
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        DATENAME(MONTH, SaleDate) AS MonthName,
        SUM(SaleAmount) AS MonthTotal,
        COUNT(*) AS MonthTransactions
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
    GROUP BY YEAR(SaleDate), MONTH(SaleDate), DATENAME(MONTH, SaleDate)
)
SELECT 
    SaleYear,
    MonthName,
    MonthTotal,
    MonthTransactions,
    SUM(MonthTotal) OVER(
        PARTITION BY SaleYear 
        ORDER BY SaleMonth
    ) AS YTDTotal,
    SUM(MonthTransactions) OVER(
        PARTITION BY SaleYear 
        ORDER BY SaleMonth
    ) AS YTDTransactions,
    MonthTotal - LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) AS MoMChange,
    (MonthTotal - LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth)) * 100.0 / 
        NULLIF(LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth), 0) AS MoMChangePct,
    AVG(MonthTotal) OVER(
        ORDER BY SaleYear, SaleMonth 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3Month,
    CASE 
        WHEN MonthTotal > LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) * 1.05 
        THEN 'Growing'
        WHEN MonthTotal < LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) * 0.95 
        THEN 'Declining'
        ELSE 'Stable'
    END AS Trend
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. AGGREGATE WINDOW FUNCTIONS
   - SUM, AVG, COUNT, MIN, MAX work with OVER()
   - Don't collapse rows like GROUP BY
   - Perfect for comparisons: individual vs aggregate
   - Use PARTITION BY for group-wise aggregates

2. RUNNING TOTALS
   - Requires ORDER BY in OVER clause
   - Accumulates values row by row
   - Essential for cumulative reports
   - Use PARTITION BY to restart per group

3. PERIOD-TO-DATE CALCULATIONS
   - MTD: PARTITION BY year, month
   - QTD: PARTITION BY year, quarter
   - YTD: PARTITION BY year
   - Always ORDER BY date within partition

4. COMPARING TO AGGREGATES
   - Calculate aggregate once with OVER()
   - Compare each row to the aggregate
   - No need for subqueries or self-joins
   - More efficient and readable

5. MOVING AVERAGES (Preview)
   - Smooth out fluctuations
   - Use ROWS BETWEEN for window frame
   - Detailed coverage in Lesson 16.8
   - Common: 3-day, 7-day, 30-day averages

6. BEST PRACTICES
   - Use meaningful partition columns
   - Always include ORDER BY for running totals
   - Test with edge cases (NULLs, ties, single row)
   - Consider performance on large datasets
   - Use CTEs to organize complex calculations

================================================================================

NEXT STEPS:
-----------
In Lesson 16.8, we'll explore WINDOW FRAMES in detail:
- ROWS vs RANGE specifications
- UNBOUNDED PRECEDING and FOLLOWING
- Custom frame boundaries
- Advanced moving calculations

Continue to: 08-window-frames/lesson.sql

================================================================================
*/
