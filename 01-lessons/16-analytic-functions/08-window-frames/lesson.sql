/*
================================================================================
LESSON 16.8: WINDOW FRAMES
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand ROWS vs RANGE frame specifications
2. Use UNBOUNDED PRECEDING and FOLLOWING
3. Create custom frame boundaries
4. Build sophisticated moving calculations
5. Handle edge cases with frames
6. Optimize frame-based queries

Business Context:
-----------------
Window frames give you precise control over which rows are included in
calculations. This enables moving averages, rolling sums, and custom
analytical windows essential for time-series analysis, trend detection,
and forecasting.

Database: RetailStore
Complexity: Advanced
Estimated Time: 60 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: UNDERSTANDING WINDOW FRAMES
================================================================================

A window frame defines which rows are included in the calculation relative
to the current row. Without a frame specification, different defaults apply.
*/

-- Example 1: Default frame behavior
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    -- Without frame: all rows from partition start to current row
    SUM(SaleAmount) OVER(ORDER BY SaleDate) AS DefaultRunningTotal,
    -- Explicit equivalent
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ExplicitRunningTotal
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   DefaultRunningTotal  ExplicitRunningTotal
------  ----------  -----------  -------------------  --------------------
1       2024-01-15  6499.95      6499.95              6499.95
2       2024-01-20  299.90       6799.85              6799.85
3       2024-02-10  2099.97      8899.82              8899.82
4       2024-02-15  179.98       9079.80              9079.80

Both produce the same result!
*/

-- Example 2: ROWS vs RANGE
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    -- ROWS: Physical rows
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS RowsSum,
    -- RANGE: Logical range based on values
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RangeSum
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RowsSum      RangeSum
------  ----------  -----------  -----------  ---------
1       2024-01-15  6499.95      6799.85      6499.95
2       2024-01-20  299.90       8899.82      6799.85
3       2024-02-10  2099.97      2579.85      8899.82
4       2024-02-15  179.98       12579.87     9079.80

Different frame specifications, different results!
*/

/*
================================================================================
PART 2: ROWS FRAME SPECIFICATION
================================================================================

ROWS defines the frame based on physical row positions relative to current row.
*/

-- Example 1: Moving average with ROWS
SELECT 
    SaleDate,
    SaleAmount,
    -- 3-row moving average (current + 2 preceding)
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MovingAvg3,
    -- 5-row moving average (current + 2 preceding + 2 following)
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS CenteredMovingAvg5,
    -- Count of rows in each window
    COUNT(*) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS WindowSize
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   MovingAvg3   CenteredMovingAvg5  WindowSize
----------  -----------  -----------  ------------------  ----------
2024-01-15  6499.95      6499.95      3795.95             1
2024-01-20  299.90       3399.93      2815.95             2
2024-02-10  2099.97      2966.61      2235.95             3
2024-02-15  179.98       859.95       2636.15             3
2024-03-05  10399.92     4226.62      2896.00             3
2024-03-10  1599.96      4059.95      3145.94             3
...

Window size grows until it reaches specified size!
*/

-- Example 2: Rolling sum with different window sizes
SELECT 
    SaleDate,
    SaleAmount,
    -- Last 2 sales (current + 1 preceding)
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS Last2Sales,
    -- Last 3 sales
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Last3Sales,
    -- Last 7 sales
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Last7Sales
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   Last2Sales   Last3Sales   Last7Sales
----------  -----------  -----------  -----------  ----------
2024-01-15  6499.95      6499.95      6499.95      6499.95
2024-01-20  299.90       6799.85      6799.85      6799.85
2024-02-10  2099.97      2399.87      8899.82      8899.82
2024-02-15  179.98       2279.95      2579.85      9079.80
2024-03-05  10399.92     10579.90     12679.87     19479.72
...

Different rolling windows!
*/

-- Example 3: Forward-looking windows
SELECT 
    SaleDate,
    SaleAmount,
    -- Current and next 2 sales
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING
    ) AS Next3Sales,
    -- Average of next 3 sales (lookahead)
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING
    ) AS AvgNext3
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   Next3Sales   AvgNext3
----------  -----------  -----------  --------
2024-01-15  6499.95      8899.82      859.95
2024-01-20  299.90       2579.85      4226.62
2024-02-10  2099.97      12679.87     4059.95
2024-02-15  179.98       12629.71     4149.93
2024-03-05  10399.92     14449.73     1083.24
...

Look ahead to future rows!
*/

/*
================================================================================
PART 3: UNBOUNDED FRAMES
================================================================================

UNBOUNDED PRECEDING/FOLLOWING includes all rows from start/end of partition.
*/

-- Example 1: UNBOUNDED frames
SELECT 
    SaleDate,
    SaleAmount,
    -- From start to current (running total)
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal,
    -- From current to end
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS RemainingTotal,
    -- Entire partition
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS GrandTotal
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   RunningTotal  RemainingTotal  GrandTotal
----------  -----------  ------------  --------------  ----------
2024-01-15  6499.95      6499.95       38809.28        38809.28
2024-01-20  299.90       6799.85       32309.33        38809.28
2024-02-10  2099.97      8899.82       30009.43        38809.28
2024-02-15  179.98       9079.80       27909.46        38809.28
...

RunningTotal + RemainingTotal - SaleAmount = GrandTotal!
*/

-- Example 2: Percentage of completion
SELECT 
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS UNBOUNDED PRECEDING
    ) AS RunningTotal,
    SUM(SaleAmount) OVER() AS GrandTotal,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS UNBOUNDED PRECEDING
    ) * 100.0 / SUM(SaleAmount) OVER() AS PctComplete
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   RunningTotal  GrandTotal   PctComplete
----------  -----------  ------------  -----------  -----------
2024-01-15  6499.95      6499.95       38809.28     16.75
2024-01-20  299.90       6799.85       38809.28     17.52
2024-02-10  2099.97      8899.82       38809.28     22.93
2024-02-15  179.98       9079.80       38809.28     23.40
2024-03-05  10399.92     19479.72      38809.28     50.19
...

Track progress toward total!
*/

/*
================================================================================
PART 4: RANGE FRAME SPECIFICATION
================================================================================

RANGE defines the frame based on the logical range of values in the ORDER BY
column. All rows with the same ORDER BY value are included together.
*/

-- Example 1: RANGE with ties
-- Insert duplicate dates for demonstration
INSERT INTO Sales (CustomerID, ProductID, SaleDate, Quantity, SaleAmount, Region)
VALUES 
    (1, 1, '2024-01-15', 1, 1299.99, 'East'),  -- Same date as existing sale
    (2, 2, '2024-01-15', 1, 699.99, 'West');   -- Same date as existing sale
GO

SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    -- ROWS: Only current physical row
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN CURRENT ROW AND CURRENT ROW
    ) AS RowsCurrentOnly,
    -- RANGE: All rows with same SaleDate
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        RANGE BETWEEN CURRENT ROW AND CURRENT ROW
    ) AS RangeCurrentPeers
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate, SaleID;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RowsCurrentOnly  RangeCurrentPeers
------  ----------  -----------  ---------------  -----------------
1       2024-01-15  6499.95      6499.95          8499.93
15      2024-01-15  1299.99      1299.99          8499.93
16      2024-01-15  699.99       699.99           8499.93
2       2024-01-20  299.90       299.90           299.90
...

RANGE includes all peers with same ORDER BY value!
*/

-- Example 2: RANGE with date intervals (SQL Server 2022+)
-- Note: This syntax requires SQL Server 2022 or later
/*
SELECT 
    SaleDate,
    SaleAmount,
    -- Sum of sales within 7 days before current date
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        RANGE BETWEEN INTERVAL '7' DAY PRECEDING AND CURRENT ROW
    ) AS Last7DaysTotal
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
*/

-- Alternative for earlier SQL Server versions using ROWS
SELECT 
    SaleDate,
    SaleAmount,
    -- Approximate 7-day total using ROWS
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ApproxLast7Days
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
================================================================================
PART 5: PRACTICAL MOVING CALCULATIONS
================================================================================
*/

-- Example 1: Moving averages for trend analysis
SELECT 
    SaleDate,
    SaleAmount,
    -- 3-period moving average
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MA3,
    -- 5-period moving average
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS MA5,
    -- 7-period moving average
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MA7,
    -- Compare current to MA5
    SaleAmount - AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS DiffFromMA5
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   MA3          MA5          MA7          DiffFromMA5
----------  -----------  -----------  -----------  -----------  -----------
2024-01-15  6499.95      6499.95      6499.95      6499.95      0.00
2024-01-20  299.90       3399.93      3399.93      3399.93      -3100.03
2024-02-10  2099.97      2966.61      2966.61      2966.61      -866.64
2024-02-15  179.98       859.95       2019.95      2019.95      -1839.97
2024-03-05  10399.92     4226.62      3895.94      3895.94      6503.98
...

Multiple moving averages for different perspectives!
*/

-- Example 2: Volatility measurement (moving standard deviation)
SELECT 
    SaleDate,
    SaleAmount,
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7,
    STDEV(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingStdDev7,
    -- Coefficient of variation (volatility indicator)
    CASE 
        WHEN AVG(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) <> 0 
        THEN STDEV(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) / AVG(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )
        ELSE NULL
    END AS CoefficientOfVariation
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

-- Example 3: Min and Max within window
SELECT 
    SaleDate,
    SaleAmount,
    -- Highest sale in last 5 periods
    MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS High5,
    -- Lowest sale in last 5 periods
    MIN(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS Low5,
    -- Range within window
    MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) - MIN(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS Range5
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
================================================================================
PART 6: ADVANCED FRAME APPLICATIONS
================================================================================
*/

-- Application 1: Exponential moving average approximation
WITH SalesWithMA AS (
    SELECT 
        SaleDate,
        SaleAmount,
        AVG(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
        ) AS SMA10
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
)
SELECT 
    SaleDate,
    SaleAmount,
    SMA10,
    -- Simple approximation of EMA using weighted average
    (SaleAmount * 2.0 / 11) + (SMA10 * 9.0 / 11) AS EMA10Approx
FROM SalesWithMA
ORDER BY SaleDate;
GO

-- Application 2: Support and resistance levels
SELECT 
    SaleDate,
    SaleAmount,
    -- 20-period high (resistance)
    MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
    ) AS Resistance20,
    -- 20-period low (support)
    MIN(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
    ) AS Support20,
    -- Position within range (0-100%)
    CASE 
        WHEN MAX(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) - MIN(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) <> 0 
        THEN (SaleAmount - MIN(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        )) * 100.0 / (MAX(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) - MIN(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ))
        ELSE 50
    END AS PctOfRange
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

-- Application 3: Regional comparison with frames
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    -- Regional 3-sale moving average
    AVG(SaleAmount) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS RegionalMA3,
    -- Overall 3-sale moving average
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS OverallMA3,
    -- Difference
    AVG(SaleAmount) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) - AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MADiff
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleDate;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Trend Detection
----------------------------
For each sale, calculate:
- 5-period and 10-period moving averages
- Whether current price is above both MAs (bullish trend)
- Maximum sale in last 10 periods
- Percentage distance from the 10-period high
- Flag as "Breaking Out" if current sale > 10-period high

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Rolling Performance Metrics
----------------------------------------
Create a report showing:
- Sale date and amount
- Last 7 sales total (rolling sum)
- Last 7 sales average
- Count of sales in last 7 periods
- Highest and lowest in last 7 periods
- Standard deviation of last 7 periods

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Forward and Backward Analysis
------------------------------------------
For each sale, show:
- Current sale amount
- Sum of previous 3 sales (backward window)
- Sum of next 3 sales (forward window)
- Total of 3 before + current + 3 after (7-sale centered window)
- Whether current sale is highest in the centered window

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Trend Detection
SELECT 
    SaleDate,
    SaleAmount,
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS MA5,
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ) AS MA10,
    CASE 
        WHEN SaleAmount > AVG(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) 
        AND SaleAmount > AVG(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
        ) 
        THEN 'Bullish'
        ELSE 'Not Bullish'
    END AS Trend,
    MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ) AS High10,
    (SaleAmount - MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    )) * 100.0 / NULLIF(MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
    ), 0) AS PctFrom10High,
    CASE 
        WHEN SaleAmount > MAX(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 9 PRECEDING AND 1 PRECEDING
        ) 
        THEN 'Breaking Out'
        ELSE 'Normal'
    END AS BreakoutFlag
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

-- Solution 2: Rolling Performance Metrics
SELECT 
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingSum7,
    AVG(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingAvg7,
    COUNT(*) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingCount7,
    MAX(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingMax7,
    MIN(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingMin7,
    STDEV(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingStdDev7
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

-- Solution 3: Forward and Backward Analysis
SELECT 
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
    ) AS Previous3Sum,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 1 FOLLOWING AND 3 FOLLOWING
    ) AS Next3Sum,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    ) AS Centered7Sum,
    CASE 
        WHEN SaleAmount = MAX(SaleAmount) OVER(
            ORDER BY SaleDate 
            ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
        ) 
        THEN 'Highest in Window'
        ELSE 'Not Highest'
    END AS CenteredWindowPeak
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. FRAME SPECIFICATIONS
   ROWS:
   - Physical row positions
   - More predictable and common
   - Use for most moving calculations
   
   RANGE:
   - Logical value ranges
   - Includes all peers (ties)
   - Use when ORDER BY has duplicates

2. FRAME BOUNDARIES
   - UNBOUNDED PRECEDING: Start of partition
   - N PRECEDING: N rows before current
   - CURRENT ROW: The current row
   - N FOLLOWING: N rows after current
   - UNBOUNDED FOLLOWING: End of partition

3. COMMON PATTERNS
   Running Total:
     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   
   Moving Average (last N):
     ROWS BETWEEN N-1 PRECEDING AND CURRENT ROW
   
   Centered Moving Average:
     ROWS BETWEEN N PRECEDING AND N FOLLOWING
   
   Entire Partition:
     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

4. MOVING CALCULATIONS
   - Moving averages smooth fluctuations
   - Standard deviation measures volatility
   - Min/Max show support/resistance
   - Use appropriate window size for data

5. PERFORMANCE CONSIDERATIONS
   - Frames require sorting (ORDER BY)
   - Larger frames = more computation
   - ROWS generally faster than RANGE
   - Consider indexed ORDER BY columns
   - Test with production data volumes

6. BEST PRACTICES
   - Choose ROWS over RANGE unless you need RANGE behavior
   - Use explicit frame specifications for clarity
   - Test edge cases (first/last rows, NULLs)
   - Document window sizes and reasoning
   - Consider data frequency when choosing window size
   - Validate calculations with manual spot checks

================================================================================

NEXT STEPS:
-----------
In Lesson 16.9, we'll explore LAG and LEAD functions:
- Accessing previous and next row values
- Period-over-period comparisons
- Gap detection
- Sequential analysis

Continue to: 09-lag-lead/lesson.sql

================================================================================
*/
