/*
================================================================================
LESSON 16.9: LAG AND LEAD FUNCTIONS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use LAG() to access previous row values
2. Use LEAD() to access next row values
3. Calculate period-over-period changes
4. Detect gaps and sequences
5. Compare values across time periods
6. Build sequential analysis queries

Business Context:
-----------------
LAG and LEAD are essential for time-series analysis, allowing you to compare
current values with previous or future values without self-joins. They power
growth calculations, trend detection, and sequential pattern analysis.

Database: RetailStore
Complexity: Intermediate to Advanced
Estimated Time: 55 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: LAG BASICS
================================================================================

LAG(column, offset, default) returns the value from a row offset rows
before the current row within the partition.
*/

-- Example 1: Simple LAG
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    -- Previous sale amount
    LAG(SaleAmount) OVER(ORDER BY SaleDate) AS PreviousSaleAmount,
    -- Previous sale date
    LAG(SaleDate) OVER(ORDER BY SaleDate) AS PreviousSaleDate
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   PreviousSaleAmount  PreviousSaleDate
------  ----------  -----------  ------------------  ----------------
1       2024-01-15  6499.95      NULL                NULL
2       2024-01-20  299.90       6499.95             2024-01-15
3       2024-02-10  2099.97      299.90              2024-01-20
4       2024-02-15  179.98       2099.97             2024-02-10
5       2024-03-05  10399.92     179.98              2024-02-15

First row has NULL (no previous row)!
*/

-- Example 2: LAG with offset and default
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    -- 1 row back (default offset)
    LAG(SaleAmount, 1) OVER(ORDER BY SaleDate) AS Lag1,
    -- 2 rows back
    LAG(SaleAmount, 2) OVER(ORDER BY SaleDate) AS Lag2,
    -- 3 rows back with default value 0
    LAG(SaleAmount, 3, 0) OVER(ORDER BY SaleDate) AS Lag3WithDefault
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   Lag1        Lag2        Lag3WithDefault
------  ----------  -----------  ----------  ----------  ---------------
1       2024-01-15  6499.95      NULL        NULL        0.00
2       2024-01-20  299.90       6499.95     NULL        0.00
3       2024-02-10  2099.97      299.90      6499.95     0.00
4       2024-02-15  179.98       2099.97     299.90      6499.95
5       2024-03-05  10399.92     179.98      2099.97     299.90

Default value fills in for missing rows!
*/

-- Example 3: LAG within partitions
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    LAG(SaleAmount) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS PrevRegionalSale,
    LAG(SaleDate) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS PrevRegionalDate
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleDate;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   PrevRegionalSale  PrevRegionalDate
-------  ----------  -----------  ----------------  ----------------
Central  2024-04-01  2799.96      NULL              NULL
Central  2024-04-05  299.94       2799.96           2024-04-01
Central  2024-04-10  12999.90     299.94            2024-04-05
East     2024-01-15  6499.95      NULL              NULL
East     2024-01-20  299.90       6499.95           2024-01-15
East     2024-03-05  10399.92     299.90            2024-01-20

LAG resets for each partition!
*/

/*
================================================================================
PART 2: LEAD BASICS
================================================================================

LEAD(column, offset, default) returns the value from a row offset rows
after the current row within the partition.
*/

-- Example 1: Simple LEAD
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    -- Next sale amount
    LEAD(SaleAmount) OVER(ORDER BY SaleDate) AS NextSaleAmount,
    -- Next sale date
    LEAD(SaleDate) OVER(ORDER BY SaleDate) AS NextSaleDate
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   NextSaleAmount  NextSaleDate
------  ----------  -----------  --------------  ------------
1       2024-01-15  6499.95      299.90          2024-01-20
2       2024-01-20  299.90       2099.97         2024-02-10
3       2024-02-10  2099.97      179.98          2024-02-15
...
14      2024-05-02  179.98       NULL            NULL

Last row has NULL (no next row)!
*/

-- Example 2: LEAD with multiple offsets
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    LEAD(SaleAmount, 1) OVER(ORDER BY SaleDate) AS Next1,
    LEAD(SaleAmount, 2) OVER(ORDER BY SaleDate) AS Next2,
    LEAD(SaleAmount, 3, -1) OVER(ORDER BY SaleDate) AS Next3WithDefault
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
================================================================================
PART 3: PERIOD-OVER-PERIOD CALCULATIONS
================================================================================

LAG and LEAD excel at calculating changes between periods.
*/

-- Example 1: Sale-over-sale change
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    LAG(SaleAmount) OVER(ORDER BY SaleDate) AS PreviousSale,
    -- Absolute change
    SaleAmount - LAG(SaleAmount) OVER(ORDER BY SaleDate) AS AbsoluteChange,
    -- Percentage change
    (SaleAmount - LAG(SaleAmount) OVER(ORDER BY SaleDate)) * 100.0 / 
        NULLIF(LAG(SaleAmount) OVER(ORDER BY SaleDate), 0) AS PctChange
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   PreviousSale  AbsoluteChange  PctChange
------  ----------  -----------  ------------  --------------  ---------
1       2024-01-15  6499.95      NULL          NULL            NULL
2       2024-01-20  299.90       6499.95       -6200.05        -95.39
3       2024-02-10  2099.97      299.90        1800.07         600.29
4       2024-02-15  179.98       2099.97       -1919.99        -91.43
5       2024-03-05  10399.92     179.98        10219.94        5677.79

Dramatic fluctuations visible!
*/

-- Example 2: Month-over-month comparison
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        DATENAME(MONTH, SaleDate) AS MonthName,
        SUM(SaleAmount) AS MonthTotal
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
    GROUP BY YEAR(SaleDate), MONTH(SaleDate), DATENAME(MONTH, SaleDate)
)
SELECT 
    SaleYear,
    MonthName,
    MonthTotal,
    LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) AS PreviousMonth,
    MonthTotal - LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) AS MoMChange,
    (MonthTotal - LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth)) * 100.0 / 
        NULLIF(LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth), 0) AS MoMChangePct,
    CASE 
        WHEN MonthTotal > LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) 
        THEN 'Growing'
        WHEN MonthTotal < LAG(MonthTotal) OVER(ORDER BY SaleYear, SaleMonth) 
        THEN 'Declining'
        ELSE 'Flat'
    END AS Trend
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

/*
OUTPUT:
SaleYear  MonthName  MonthTotal   PreviousMonth  MoMChange    MoMChangePct  Trend
--------  ---------  -----------  -------------  -----------  ------------  ---------
2024      January    6799.85      NULL           NULL         NULL          Flat
2024      February   2279.95      6799.85        -4519.90     -66.47        Declining
2024      March      12449.73     2279.95        10169.78     446.07        Growing
2024      April      16099.80     12449.73       3650.07      29.31         Growing
2024      May        599.80       16099.80       -15500.00    -96.27        Declining

Month-over-month trends!
*/

-- Example 3: Year-over-year comparison
-- Note: Would need multiple years of data for true YoY
-- This example shows the technique
WITH YearlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        SUM(SaleAmount) AS YearTotal
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
    GROUP BY YEAR(SaleDate)
)
SELECT 
    SaleYear,
    YearTotal,
    LAG(YearTotal) OVER(ORDER BY SaleYear) AS PreviousYear,
    YearTotal - LAG(YearTotal) OVER(ORDER BY SaleYear) AS YoYChange,
    (YearTotal - LAG(YearTotal) OVER(ORDER BY SaleYear)) * 100.0 / 
        NULLIF(LAG(YearTotal) OVER(ORDER BY SaleYear), 0) AS YoYGrowthPct
FROM YearlySales
ORDER BY SaleYear;
GO

/*
================================================================================
PART 4: GAP DETECTION AND TIME ANALYSIS
================================================================================

LAG helps identify gaps in sequences or unusual time intervals.
*/

-- Example 1: Days between sales
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    LAG(SaleDate) OVER(ORDER BY SaleDate) AS PreviousSaleDate,
    DATEDIFF(DAY, 
        LAG(SaleDate) OVER(ORDER BY SaleDate), 
        SaleDate
    ) AS DaysSincePreviousSale,
    CASE 
        WHEN DATEDIFF(DAY, LAG(SaleDate) OVER(ORDER BY SaleDate), SaleDate) > 10 
        THEN 'Gap Detected'
        ELSE 'Normal'
    END AS GapFlag
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   PreviousSaleDate  DaysSincePreviousSale  GapFlag
------  ----------  -----------  ----------------  ---------------------  -------------
1       2024-01-15  6499.95      NULL              NULL                   Normal
2       2024-01-20  299.90       2024-01-15        5                      Normal
3       2024-02-10  2099.97      2024-01-20        21                     Gap Detected
4       2024-02-15  179.98       2024-02-10        5                      Normal
5       2024-03-05  10399.92     2024-02-15        19                     Gap Detected

Long gaps flagged!
*/

-- Example 2: Customer purchase frequency
SELECT 
    c.CustomerName,
    s.SaleDate,
    s.SaleAmount,
    LAG(s.SaleDate) OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS PreviousPurchaseDate,
    DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    ) AS DaysSincePrevious,
    AVG(DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    )) OVER(PARTITION BY c.CustomerID) AS AvgDaysBetweenPurchases
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, s.SaleDate;
GO

/*
OUTPUT:
CustomerName    SaleDate    SaleAmount   PreviousPurchaseDate  DaysSincePrevious  AvgDaysBetweenPurchases
--------------  ----------  -----------  --------------------  -----------------  -----------------------
Acme Corp       2024-01-15  6499.95      NULL                  NULL               53
Acme Corp       2024-01-20  299.90       2024-01-15            5                  53
Acme Corp       2024-05-01  299.90       2024-01-20            102                53

Average purchase frequency per customer!
*/

-- Example 3: Sequential value analysis
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    LAG(SaleAmount, 1) OVER(ORDER BY SaleDate) AS Prev1,
    LAG(SaleAmount, 2) OVER(ORDER BY SaleDate) AS Prev2,
    LEAD(SaleAmount, 1) OVER(ORDER BY SaleDate) AS Next1,
    LEAD(SaleAmount, 2) OVER(ORDER BY SaleDate) AS Next2,
    -- Is this a local peak?
    CASE 
        WHEN SaleAmount > LAG(SaleAmount) OVER(ORDER BY SaleDate) 
         AND SaleAmount > LEAD(SaleAmount) OVER(ORDER BY SaleDate) 
        THEN 'Peak'
        WHEN SaleAmount < LAG(SaleAmount) OVER(ORDER BY SaleDate) 
         AND SaleAmount < LEAD(SaleAmount) OVER(ORDER BY SaleDate) 
        THEN 'Valley'
        ELSE 'Normal'
    END AS Pattern
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   Prev1       Prev2       Next1       Next2       Pattern
------  ----------  -----------  ----------  ----------  ----------  ----------  -------
1       2024-01-15  6499.95      NULL        NULL        299.90      2099.97     Peak
2       2024-01-20  299.90       6499.95     NULL        2099.97     179.98      Valley
3       2024-02-10  2099.97      299.90      6499.95     179.98      10399.92    Peak
4       2024-02-15  179.98       2099.97     299.90      10399.92    1599.96     Valley

Peaks and valleys identified!
*/

/*
================================================================================
PART 5: COMBINING LAG AND LEAD
================================================================================

Use both together for comprehensive sequential analysis.
*/

-- Example 1: Three-period view
SELECT 
    SaleDate,
    LAG(SaleAmount) OVER(ORDER BY SaleDate) AS Previous,
    SaleAmount AS Current,
    LEAD(SaleAmount) OVER(ORDER BY SaleDate) AS Next,
    -- Average of three periods
    (
        ISNULL(LAG(SaleAmount) OVER(ORDER BY SaleDate), 0) +
        SaleAmount +
        ISNULL(LEAD(SaleAmount) OVER(ORDER BY SaleDate), 0)
    ) / 3.0 AS ThreePeriodAvg,
    -- Trend direction
    CASE 
        WHEN SaleAmount > LAG(SaleAmount) OVER(ORDER BY SaleDate) 
         AND LEAD(SaleAmount) OVER(ORDER BY SaleDate) > SaleAmount 
        THEN 'Uptrend'
        WHEN SaleAmount < LAG(SaleAmount) OVER(ORDER BY SaleDate) 
         AND LEAD(SaleAmount) OVER(ORDER BY SaleDate) < SaleAmount 
        THEN 'Downtrend'
        ELSE 'Mixed'
    END AS TrendDirection
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

-- Example 2: Forward and backward percentage changes
SELECT 
    SaleDate,
    SaleAmount,
    -- Backward change
    (SaleAmount - LAG(SaleAmount) OVER(ORDER BY SaleDate)) * 100.0 / 
        NULLIF(LAG(SaleAmount) OVER(ORDER BY SaleDate), 0) AS BackwardChangePct,
    -- Forward change
    (LEAD(SaleAmount) OVER(ORDER BY SaleDate) - SaleAmount) * 100.0 / 
        NULLIF(SaleAmount, 0) AS ForwardChangePct,
    -- Volatility indicator
    ABS((SaleAmount - LAG(SaleAmount) OVER(ORDER BY SaleDate)) * 100.0 / 
        NULLIF(LAG(SaleAmount) OVER(ORDER BY SaleDate), 0)) +
    ABS((LEAD(SaleAmount) OVER(ORDER BY SaleDate) - SaleAmount) * 100.0 / 
        NULLIF(SaleAmount, 0)) AS TotalVolatility
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
================================================================================
PART 6: PRACTICAL APPLICATIONS
================================================================================
*/

-- Application 1: Customer churn risk
SELECT 
    c.CustomerName,
    s.SaleDate AS LastPurchaseDate,
    s.SaleAmount AS LastPurchaseAmount,
    LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate) AS PreviousPurchaseDate,
    DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    ) AS DaysBetweenPurchases,
    AVG(DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    )) OVER(PARTITION BY c.CustomerID) AS AvgDaysBetween,
    DATEDIFF(DAY, s.SaleDate, GETDATE()) AS DaysSinceLastPurchase,
    CASE 
        WHEN DATEDIFF(DAY, s.SaleDate, GETDATE()) > 
             AVG(DATEDIFF(DAY,
                 LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
                 s.SaleDate
             )) OVER(PARTITION BY c.CustomerID) * 2 
        THEN 'High Risk'
        WHEN DATEDIFF(DAY, s.SaleDate, GETDATE()) > 
             AVG(DATEDIFF(DAY,
                 LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
                 s.SaleDate
             )) OVER(PARTITION BY c.CustomerID) 
        THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS ChurnRisk
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
    AND s.SaleDate = (SELECT MAX(SaleDate) FROM Sales s2 WHERE s2.CustomerID = c.CustomerID)
ORDER BY ChurnRisk DESC, c.CustomerName;
GO

-- Application 2: Product price trend analysis
SELECT 
    p.ProductName,
    s.SaleDate,
    s.SaleAmount / s.Quantity AS EffectivePrice,
    LAG(s.SaleAmount / s.Quantity) OVER(
        PARTITION BY p.ProductID 
        ORDER BY s.SaleDate
    ) AS PreviousPrice,
    (s.SaleAmount / s.Quantity - LAG(s.SaleAmount / s.Quantity) OVER(
        PARTITION BY p.ProductID 
        ORDER BY s.SaleDate
    )) * 100.0 / NULLIF(LAG(s.SaleAmount / s.Quantity) OVER(
        PARTITION BY p.ProductID 
        ORDER BY s.SaleDate
    ), 0) AS PriceChangePct
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY p.ProductName, s.SaleDate;
GO

-- Application 3: Regional momentum
WITH RegionalMonthly AS (
    SELECT 
        Region,
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(SaleAmount) AS MonthTotal
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
    GROUP BY Region, YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    Region,
    SaleYear,
    SaleMonth,
    MonthTotal,
    LAG(MonthTotal, 1) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) AS Prev1Month,
    LAG(MonthTotal, 2) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) AS Prev2Months,
    LAG(MonthTotal, 3) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) AS Prev3Months,
    -- 3-month momentum
    CASE 
        WHEN MonthTotal > LAG(MonthTotal, 1) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) 
         AND LAG(MonthTotal, 1) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) > 
             LAG(MonthTotal, 2) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) 
         AND LAG(MonthTotal, 2) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) > 
             LAG(MonthTotal, 3) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) 
        THEN 'Strong Upward'
        WHEN MonthTotal < LAG(MonthTotal, 1) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) 
         AND LAG(MonthTotal, 1) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) < 
             LAG(MonthTotal, 2) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) 
         AND LAG(MonthTotal, 2) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) < 
             LAG(MonthTotal, 3) OVER(PARTITION BY Region ORDER BY SaleYear, SaleMonth) 
        THEN 'Strong Downward'
        ELSE 'Mixed'
    END AS Momentum
FROM RegionalMonthly
ORDER BY Region, SaleYear, SaleMonth;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Growth Analysis
----------------------------
For each sale, calculate:
- Current and previous sale amount
- Absolute and percentage change
- Whether it's higher than the previous sale
- Running count of consecutive increases
- Classify as "Accelerating" if change % is increasing

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Customer Retention Metrics
---------------------------------------
For each customer's purchases, show:
- Purchase date and amount
- Days since previous purchase
- Average time between purchases
- Whether this purchase was faster or slower than average
- Flag customers whose last purchase was >60 days ago

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Price Momentum
---------------------------
For each product sale, calculate:
- Effective price per unit
- Price 1, 2, and 3 sales ago
- Average of last 3 prices
- Whether current price is above the 3-sale average
- Trend classification based on last 3 prices

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Growth Analysis
WITH SalesWithChanges AS (
    SELECT 
        SaleID,
        SaleDate,
        SaleAmount,
        LAG(SaleAmount) OVER(ORDER BY SaleDate) AS PrevAmount,
        SaleAmount - LAG(SaleAmount) OVER(ORDER BY SaleDate) AS AbsChange,
        (SaleAmount - LAG(SaleAmount) OVER(ORDER BY SaleDate)) * 100.0 / 
            NULLIF(LAG(SaleAmount) OVER(ORDER BY SaleDate), 0) AS PctChange,
        CASE WHEN SaleAmount > LAG(SaleAmount) OVER(ORDER BY SaleDate) THEN 1 ELSE 0 END AS IsIncrease
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
)
SELECT 
    *,
    CASE 
        WHEN PctChange > LAG(PctChange) OVER(ORDER BY SaleDate) 
         AND PctChange > 0 
        THEN 'Accelerating'
        ELSE 'Not Accelerating'
    END AS GrowthStatus
FROM SalesWithChanges
ORDER BY SaleDate;
GO

-- Solution 2: Customer Retention Metrics
SELECT 
    c.CustomerName,
    s.SaleDate,
    s.SaleAmount,
    DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    ) AS DaysSincePrevious,
    AVG(DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
        s.SaleDate
    )) OVER(PARTITION BY c.CustomerID) AS AvgDaysBetween,
    CASE 
        WHEN DATEDIFF(DAY,
            LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
            s.SaleDate
        ) < AVG(DATEDIFF(DAY,
            LAG(s.SaleDate) OVER(PARTITION BY c.CustomerID ORDER BY s.SaleDate),
            s.SaleDate
        )) OVER(PARTITION BY c.CustomerID) 
        THEN 'Faster than Average'
        ELSE 'Slower than Average'
    END AS PurchaseSpeed,
    CASE 
        WHEN DATEDIFF(DAY, 
            MAX(s.SaleDate) OVER(PARTITION BY c.CustomerID), 
            GETDATE()) > 60 
        THEN 'At Risk'
        ELSE 'Active'
    END AS RetentionStatus
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, s.SaleDate;
GO

-- Solution 3: Price Momentum
SELECT 
    p.ProductName,
    s.SaleDate,
    s.SaleAmount / s.Quantity AS CurrentPrice,
    LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) AS Price1Ago,
    LAG(s.SaleAmount / s.Quantity, 2) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) AS Price2Ago,
    LAG(s.SaleAmount / s.Quantity, 3) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) AS Price3Ago,
    (
        s.SaleAmount / s.Quantity +
        ISNULL(LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate), 0) +
        ISNULL(LAG(s.SaleAmount / s.Quantity, 2) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate), 0)
    ) / 3.0 AS Avg3Prices,
    CASE 
        WHEN s.SaleAmount / s.Quantity > (
            s.SaleAmount / s.Quantity +
            ISNULL(LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate), 0) +
            ISNULL(LAG(s.SaleAmount / s.Quantity, 2) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate), 0)
        ) / 3.0 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS PricePosition,
    CASE 
        WHEN s.SaleAmount / s.Quantity > 
             LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) 
         AND LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) > 
             LAG(s.SaleAmount / s.Quantity, 2) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) 
        THEN 'Rising'
        WHEN s.SaleAmount / s.Quantity < 
             LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) 
         AND LAG(s.SaleAmount / s.Quantity, 1) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) < 
             LAG(s.SaleAmount / s.Quantity, 2) OVER(PARTITION BY p.ProductID ORDER BY s.SaleDate) 
        THEN 'Falling'
        ELSE 'Mixed'
    END AS TrendClassification
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY p.ProductName, s.SaleDate;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. LAG vs LEAD
   LAG():
   - Access previous rows
   - Historical comparisons
   - Change calculations
   
   LEAD():
   - Access future rows
   - Forward-looking analysis
   - Predictive patterns

2. SYNTAX
   LAG/LEAD(column, offset, default) OVER(...)
   - column: Which value to retrieve
   - offset: How many rows (default 1)
   - default: Value when no row exists (default NULL)

3. COMMON USE CASES
   - Period-over-period changes (MoM, YoY)
   - Gap detection in sequences
   - Customer purchase frequency
   - Trend identification
   - Peak and valley detection

4. BEST PRACTICES
   - Always specify PARTITION BY and ORDER BY
   - Use NULLIF to avoid division by zero
   - Provide defaults for edge cases
   - Test first/last rows in partition
   - Document offset reasoning

5. PERFORMANCE TIPS
   - LAG/LEAD require sorting
   - Index ORDER BY columns
   - Consider partitioning large datasets
   - Test with production volumes
   - Avoid complex calculations in LAG/LEAD expression

6. COMMON PATTERNS
   Month-over-Month:
     (Current - LAG(Current)) * 100 / LAG(Current)
   
   Gap Detection:
     DATEDIFF(unit, LAG(date), date)
   
   Trend Detection:
     Current > LAG(1) AND LAG(1) > LAG(2)
   
   Three-Period Average:
     (LAG(1) + Current + LEAD(1)) / 3

================================================================================

NEXT STEPS:
-----------
In Lesson 16.10, we'll explore COLUMN VALUE CONCATENATION:
- STRING_AGG with OVER clause
- Ordered concatenation within windows
- Building cumulative strings
- Practical text aggregation

Continue to: 10-column-value-concatenation/lesson.sql

================================================================================
*/
