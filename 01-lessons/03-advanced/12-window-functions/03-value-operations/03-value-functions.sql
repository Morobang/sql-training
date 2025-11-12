-- ========================================
-- Value Window Functions
-- LAG, LEAD, FIRST_VALUE, LAST_VALUE
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: LAG - Access Previous Row
-- =============================================

-- Previous sale amount
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    LAG(TotalAmount) OVER (ORDER BY SaleDate) AS PrevAmount
FROM Sales
ORDER BY SaleDate;
GO

-- Previous sale per customer
SELECT 
    CustomerID,
    SaleDate,
    TotalAmount,
    LAG(TotalAmount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS PrevAmount
FROM Sales
ORDER BY CustomerID, SaleDate;
GO

-- =============================================
-- Example 2: LAG with Offset and Default
-- =============================================

-- 2 rows back, default to 0
SELECT 
    SaleDate,
    TotalAmount,
    LAG(TotalAmount, 1, 0) OVER (ORDER BY SaleDate) AS Prev1,
    LAG(TotalAmount, 2, 0) OVER (ORDER BY SaleDate) AS Prev2,
    LAG(TotalAmount, 3, 0) OVER (ORDER BY SaleDate) AS Prev3
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 3: LEAD - Access Next Row
-- =============================================

-- Next sale amount
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    LEAD(TotalAmount) OVER (ORDER BY SaleDate) AS NextAmount
FROM Sales
ORDER BY SaleDate;
GO

-- Next sale per customer
SELECT 
    CustomerID,
    SaleDate,
    TotalAmount,
    LEAD(TotalAmount) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS NextAmount
FROM Sales
ORDER BY CustomerID, SaleDate;
GO

-- =============================================
-- Example 4: LAG and LEAD Together
-- =============================================

-- Previous, current, next
SELECT 
    SaleDate,
    TotalAmount,
    LAG(TotalAmount) OVER (ORDER BY SaleDate) AS PrevAmount,
    TotalAmount AS CurrentAmount,
    LEAD(TotalAmount) OVER (ORDER BY SaleDate) AS NextAmount
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 5: Period-over-Period Change
-- =============================================

-- Day-over-day change
SELECT 
    SaleDate,
    TotalAmount,
    LAG(TotalAmount) OVER (ORDER BY SaleDate) AS PrevDayAmount,
    TotalAmount - LAG(TotalAmount) OVER (ORDER BY SaleDate) AS DayOverDayChange,
    CASE 
        WHEN LAG(TotalAmount) OVER (ORDER BY SaleDate) IS NULL THEN NULL
        WHEN LAG(TotalAmount) OVER (ORDER BY SaleDate) = 0 THEN NULL
        ELSE ((TotalAmount - LAG(TotalAmount) OVER (ORDER BY SaleDate)) * 100.0 
              / LAG(TotalAmount) OVER (ORDER BY SaleDate))
    END AS PercentChange
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 6: Month-over-Month Growth
-- =============================================

WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    SaleYear,
    SaleMonth,
    Revenue,
    LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth) AS PrevMonthRevenue,
    Revenue - LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth) AS MoMChange,
    CASE 
        WHEN LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth) IS NULL THEN NULL
        ELSE ((Revenue - LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth)) * 100.0 
              / LAG(Revenue) OVER (ORDER BY SaleYear, SaleMonth))
    END AS MoMGrowthPct
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

-- =============================================
-- Example 7: Year-over-Year Comparison
-- =============================================

WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    SaleYear,
    SaleMonth,
    Revenue,
    LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth) AS SameMonthLastYear,
    Revenue - LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth) AS YoYChange,
    CASE 
        WHEN LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth) IS NULL THEN NULL
        ELSE ((Revenue - LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth)) * 100.0 
              / LAG(Revenue, 12) OVER (ORDER BY SaleYear, SaleMonth))
    END AS YoYGrowthPct
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

-- =============================================
-- Example 8: FIRST_VALUE - First in Window
-- =============================================

-- Compare each sale to first sale of month
SELECT 
    SaleDate,
    TotalAmount,
    FIRST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
    ) AS FirstSaleOfMonth,
    TotalAmount - FIRST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
    ) AS DiffFromFirst
FROM Sales
ORDER BY SaleDate;
GO

-- First product price per category
SELECT 
    Category,
    ProductName,
    Price,
    FIRST_VALUE(ProductName) OVER (
        PARTITION BY Category 
        ORDER BY Price DESC
    ) AS MostExpensiveProduct,
    FIRST_VALUE(Price) OVER (
        PARTITION BY Category 
        ORDER BY Price DESC
    ) AS HighestPrice
FROM Products
ORDER BY Category, Price DESC;
GO

-- =============================================
-- Example 9: LAST_VALUE - Last in Window
-- =============================================

-- ⚠️ WRONG: LAST_VALUE with default frame
SELECT 
    SaleDate,
    TotalAmount,
    LAST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
    ) AS WrongLastValue  -- This is just current row!
FROM Sales
ORDER BY SaleDate;
GO

-- ✅ CORRECT: LAST_VALUE with explicit frame
SELECT 
    SaleDate,
    TotalAmount,
    LAST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LastSaleOfMonth
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 10: FIRST_VALUE and LAST_VALUE Together
-- =============================================

-- Compare each sale to first and last of month
SELECT 
    SaleDate,
    TotalAmount,
    FIRST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS FirstOfMonth,
    LAST_VALUE(TotalAmount) OVER (
        PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LastOfMonth
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 11: Customer Purchase Patterns
-- =============================================

-- Days between customer purchases
SELECT 
    CustomerID,
    SaleDate,
    TotalAmount,
    LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS PrevPurchaseDate,
    DATEDIFF(DAY, 
        LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate), 
        SaleDate
    ) AS DaysSinceLastPurchase
FROM Sales
ORDER BY CustomerID, SaleDate;
GO

-- Customer purchase frequency analysis
WITH PurchaseGaps AS (
    SELECT 
        CustomerID,
        SaleDate,
        DATEDIFF(DAY, 
            LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate), 
            SaleDate
        ) AS DaysBetweenPurchases
    FROM Sales
)
SELECT 
    CustomerID,
    COUNT(*) AS PurchaseCnt,
    AVG(DaysBetweenPurchases) AS AvgDaysBetween,
    MIN(DaysBetweenPurchases) AS MinDaysBetween,
    MAX(DaysBetweenPurchases) AS MaxDaysBetween
FROM PurchaseGaps
WHERE DaysBetweenPurchases IS NOT NULL
GROUP BY CustomerID
ORDER BY AvgDaysBetween;
GO

-- =============================================
-- Example 12: Product Price Changes
-- =============================================

-- Track price changes (if you have price history)
-- Simulated with current prices
SELECT 
    ProductID,
    ProductName,
    Price AS CurrentPrice,
    LAG(Price) OVER (PARTITION BY ProductID ORDER BY LastModified) AS PrevPrice,
    Price - LAG(Price) OVER (PARTITION BY ProductID ORDER BY LastModified) AS PriceChange,
    CASE 
        WHEN LAG(Price) OVER (PARTITION BY ProductID ORDER BY LastModified) IS NULL THEN NULL
        ELSE ((Price - LAG(Price) OVER (PARTITION BY ProductID ORDER BY LastModified)) * 100.0 
              / LAG(Price) OVER (PARTITION BY ProductID ORDER BY LastModified))
    END AS PriceChangePct
FROM Products
ORDER BY ProductID;
GO

-- =============================================
-- Example 13: Session Gap Analysis
-- =============================================

-- Find session gaps (> 30 minutes between sales)
WITH SaleGaps AS (
    SELECT 
        CustomerID,
        SaleDate,
        LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate) AS PrevSaleDate,
        DATEDIFF(MINUTE, 
            LAG(SaleDate) OVER (PARTITION BY CustomerID ORDER BY SaleDate), 
            SaleDate
        ) AS MinutesSinceLast
    FROM Sales
)
SELECT 
    CustomerID,
    SaleDate,
    PrevSaleDate,
    MinutesSinceLast,
    CASE 
        WHEN MinutesSinceLast IS NULL THEN 'First Sale'
        WHEN MinutesSinceLast > 30 THEN 'New Session'
        ELSE 'Same Session'
    END AS SessionFlag
FROM SaleGaps
ORDER BY CustomerID, SaleDate;
GO

-- =============================================
-- Example 14: Running Difference
-- =============================================

-- Daily sales change
WITH DailySales AS (
    SELECT 
        CAST(SaleDate AS DATE) AS SaleDate,
        SUM(TotalAmount) AS DailyRevenue
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE)
)
SELECT 
    SaleDate,
    DailyRevenue,
    LAG(DailyRevenue) OVER (ORDER BY SaleDate) AS PrevDayRevenue,
    DailyRevenue - LAG(DailyRevenue) OVER (ORDER BY SaleDate) AS DailyChange,
    CASE 
        WHEN DailyRevenue > LAG(DailyRevenue) OVER (ORDER BY SaleDate) THEN 'Increase'
        WHEN DailyRevenue < LAG(DailyRevenue) OVER (ORDER BY SaleDate) THEN 'Decrease'
        WHEN DailyRevenue = LAG(DailyRevenue) OVER (ORDER BY SaleDate) THEN 'No Change'
        ELSE 'N/A'
    END AS Trend
FROM DailySales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 15: Comparison to Baseline
-- =============================================

-- Compare each month to first month (baseline)
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    SaleYear,
    SaleMonth,
    Revenue,
    FIRST_VALUE(Revenue) OVER (
        ORDER BY SaleYear, SaleMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS BaselineRevenue,
    Revenue - FIRST_VALUE(Revenue) OVER (
        ORDER BY SaleYear, SaleMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS ChangeFromBaseline,
    ((Revenue - FIRST_VALUE(Revenue) OVER (
        ORDER BY SaleYear, SaleMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )) * 100.0 / FIRST_VALUE(Revenue) OVER (
        ORDER BY SaleYear, SaleMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )) AS PctChangeFromBaseline
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

-- =============================================
-- Example 16: Stock Level Changes
-- =============================================

-- Track stock changes over time (simulated)
SELECT 
    ProductID,
    ProductName,
    StockQuantity AS CurrentStock,
    LAG(StockQuantity) OVER (PARTITION BY ProductID ORDER BY LastModified) AS PrevStock,
    StockQuantity - LAG(StockQuantity) OVER (PARTITION BY ProductID ORDER BY LastModified) AS StockChange,
    CASE 
        WHEN StockQuantity > LAG(StockQuantity) OVER (PARTITION BY ProductID ORDER BY LastModified) THEN 'Restocked'
        WHEN StockQuantity < LAG(StockQuantity) OVER (PARTITION BY ProductID ORDER BY LastModified) THEN 'Sold'
        WHEN StockQuantity = LAG(StockQuantity) OVER (PARTITION BY ProductID ORDER BY LastModified) THEN 'No Change'
        ELSE 'Initial Stock'
    END AS StockEvent
FROM Products
ORDER BY ProductID;
GO

-- =============================================
-- Example 17: Handling NULLs
-- =============================================

-- Provide default for missing values
SELECT 
    SaleDate,
    TotalAmount,
    LAG(TotalAmount, 1, 0) OVER (ORDER BY SaleDate) AS PrevAmount,  -- Default to 0
    COALESCE(
        TotalAmount - LAG(TotalAmount) OVER (ORDER BY SaleDate),
        TotalAmount  -- First row: change = current amount
    ) AS ChangeFromPrev
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 18: Multiple LAG Comparisons
-- =============================================

-- Compare to previous 3 periods
WITH DailySales AS (
    SELECT 
        CAST(SaleDate AS DATE) AS SaleDate,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE)
)
SELECT 
    SaleDate,
    Revenue,
    LAG(Revenue, 1) OVER (ORDER BY SaleDate) AS Prev1Day,
    LAG(Revenue, 7) OVER (ORDER BY SaleDate) AS Prev1Week,
    LAG(Revenue, 30) OVER (ORDER BY SaleDate) AS Prev1Month,
    Revenue - LAG(Revenue, 1) OVER (ORDER BY SaleDate) AS Change1Day,
    Revenue - LAG(Revenue, 7) OVER (ORDER BY SaleDate) AS Change1Week,
    Revenue - LAG(Revenue, 30) OVER (ORDER BY SaleDate) AS Change1Month
FROM DailySales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 19: Combining All Value Functions
-- =============================================

-- Comprehensive analysis
WITH DailySales AS (
    SELECT 
        CAST(SaleDate AS DATE) AS SaleDate,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE)
)
SELECT 
    SaleDate,
    Revenue,
    -- Previous and next
    LAG(Revenue) OVER (ORDER BY SaleDate) AS PrevDay,
    LEAD(Revenue) OVER (ORDER BY SaleDate) AS NextDay,
    -- First and last
    FIRST_VALUE(Revenue) OVER (
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS FirstDay,
    LAST_VALUE(Revenue) OVER (
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS LastDay,
    -- Comparisons
    Revenue - LAG(Revenue) OVER (ORDER BY SaleDate) AS ChangeFromPrev,
    Revenue - FIRST_VALUE(Revenue) OVER (
        ORDER BY SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS ChangeFromFirst
FROM DailySales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 20: Performance vs Self-Join
-- =============================================

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Window function (efficient)
SELECT 
    s1.SaleDate,
    s1.TotalAmount,
    LAG(s1.TotalAmount) OVER (ORDER BY s1.SaleDate) AS PrevAmount
FROM Sales s1
ORDER BY s1.SaleDate;
GO

-- Self-join (inefficient)
SELECT 
    s1.SaleDate,
    s1.TotalAmount,
    s2.TotalAmount AS PrevAmount
FROM Sales s1
LEFT JOIN Sales s2 ON s2.SaleDate = (
    SELECT MAX(SaleDate) 
    FROM Sales 
    WHERE SaleDate < s1.SaleDate
)
ORDER BY s1.SaleDate;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
-- Window functions are much faster!
GO

-- 💡 Key Takeaways:
--
-- VALUE FUNCTIONS:
-- - LAG(column, offset, default): Access previous row
-- - LEAD(column, offset, default): Access next row
-- - FIRST_VALUE(column): First value in window frame
-- - LAST_VALUE(column): Last value in window frame (needs explicit frame!)
--
-- COMMON PARAMETERS:
-- - offset: How many rows back/forward (default 1)
-- - default: Value when row doesn't exist (default NULL)
--
-- USE CASES:
-- - Period-over-period comparisons (day-over-day, month-over-month, year-over-year)
-- - Customer purchase patterns (days between purchases)
-- - Price change tracking
-- - Session gap analysis
-- - Trend analysis (increase/decrease)
-- - Comparison to baseline (first month, first sale)
--
-- LAG vs LEAD:
-- - LAG: Look backward (previous rows)
-- - LEAD: Look forward (next rows)
-- - Both support offset and default
-- - Use PARTITION BY for per-group analysis
--
-- FIRST_VALUE vs LAST_VALUE:
-- - FIRST_VALUE: Works with default frame
-- - LAST_VALUE: Needs explicit frame (ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
-- - Default frame: RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--
-- PERIOD-OVER-PERIOD CALCULATIONS:
-- - Day-over-day: LAG(value, 1)
-- - Week-over-week: LAG(value, 7)
-- - Month-over-month: LAG(value) with monthly grouping
-- - Year-over-year: LAG(value, 12) with monthly grouping
--
-- HANDLING NULLs:
-- - Use default parameter: LAG(value, 1, 0)
-- - Use COALESCE: COALESCE(value - LAG(value), value)
-- - Check for NULL before calculations
-- - Document NULL meaning (first row, missing data, etc.)
--
-- PERFORMANCE:
-- - Window functions faster than self-joins
-- - Index PARTITION BY and ORDER BY columns
-- - Use CTEs to avoid recalculating windows
-- - Materialize daily/monthly aggregates for complex analyses
--
-- BEST PRACTICES:
-- - Always specify explicit frame for LAST_VALUE
-- - Use meaningful default values (0, NULL, etc.)
-- - Handle NULL cases in percentage calculations (divide by zero)
-- - Document period comparisons (day-over-day, etc.)
-- - Use CTEs for readability
-- - Test with edge cases (first row, last row, NULLs)
-- - Index appropriately for performance
-- - Prefer window functions over self-joins
