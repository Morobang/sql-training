-- ========================================
-- Aggregate Window Functions
-- Running Totals, Moving Averages, Frames
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Simple Running Total
-- =============================================

-- Running total of sales by date
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 2: Running Total with PARTITION BY
-- =============================================

-- Running total per customer
SELECT 
    CustomerID,
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY SaleDate
    ) AS CustomerRunningTotal
FROM Sales
ORDER BY CustomerID, SaleDate;
GO

-- =============================================
-- Example 3: Multiple Aggregates
-- =============================================

-- Running totals, averages, counts
SELECT 
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal,
    AVG(TotalAmount) OVER (ORDER BY SaleDate) AS RunningAvg,
    COUNT(*) OVER (ORDER BY SaleDate) AS RunningCount,
    MIN(TotalAmount) OVER (ORDER BY SaleDate) AS MinToDate,
    MAX(TotalAmount) OVER (ORDER BY SaleDate) AS MaxToDate
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 4: Moving Average (ROWS frame)
-- =============================================

-- 7-row moving average
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7
FROM Sales
ORDER BY SaleDate;
GO

-- 30-row moving average
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS MovingAvg30
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 5: Centered Moving Average
-- =============================================

-- 5-row centered window (2 before, current, 2 after)
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS CenteredAvg5
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 6: ROWS vs RANGE
-- =============================================

-- ROWS: Exactly N physical rows
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS AvgRows3
FROM Sales
ORDER BY SaleDate;
GO

-- RANGE: Logical range (includes all rows with same SaleDate)
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS AvgRange
FROM Sales
ORDER BY SaleDate;
GO

-- Demonstrate difference with ties
SELECT 
    ProductID,
    Price,
    ROW_NUMBER() OVER (ORDER BY Price) AS RowNum,
    COUNT(*) OVER (
        ORDER BY Price 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CountRows,
    COUNT(*) OVER (
        ORDER BY Price 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CountRange
FROM Products
ORDER BY Price, ProductID;
-- CountRows increments by 1, CountRange includes all ties
GO

-- =============================================
-- Example 7: Frame Boundaries
-- =============================================

-- All preceding rows
SELECT 
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Sales
ORDER BY SaleDate;
GO

-- All rows in partition (grand total)
SELECT 
    CustomerID,
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID
    ) AS CustomerGrandTotal,
    TotalAmount * 100.0 / SUM(TotalAmount) OVER (PARTITION BY CustomerID) AS PercentOfCustomerTotal
FROM Sales
ORDER BY CustomerID, SaleDate;
GO

-- Current row only
SELECT 
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN CURRENT ROW AND CURRENT ROW
    ) AS CurrentRowOnly  -- Same as TotalAmount
FROM Sales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 8: Year-to-Date Calculations
-- =============================================

-- YTD sales by customer
SELECT 
    CustomerID,
    YEAR(SaleDate) AS SaleYear,
    MONTH(SaleDate) AS SaleMonth,
    SUM(TotalAmount) AS MonthlyTotal,
    SUM(SUM(TotalAmount)) OVER (
        PARTITION BY CustomerID, YEAR(SaleDate) 
        ORDER BY MONTH(SaleDate)
    ) AS YTDTotal
FROM Sales
GROUP BY CustomerID, YEAR(SaleDate), MONTH(SaleDate)
ORDER BY CustomerID, SaleYear, SaleMonth;
GO

-- =============================================
-- Example 9: Percentage of Total
-- =============================================

-- Each sale as percentage of all sales
SELECT 
    SaleID,
    CustomerID,
    TotalAmount,
    SUM(TotalAmount) OVER () AS GrandTotal,
    TotalAmount * 100.0 / SUM(TotalAmount) OVER () AS PercentOfTotal
FROM Sales
ORDER BY TotalAmount DESC;
GO

-- Each sale as percentage of customer total
SELECT 
    CustomerID,
    SaleID,
    TotalAmount,
    SUM(TotalAmount) OVER (PARTITION BY CustomerID) AS CustomerTotal,
    TotalAmount * 100.0 / SUM(TotalAmount) OVER (PARTITION BY CustomerID) AS PercentOfCustomer
FROM Sales
ORDER BY CustomerID, TotalAmount DESC;
GO

-- =============================================
-- Example 10: Product Category Analysis
-- =============================================

-- Category totals and product percentages
SELECT 
    Category,
    ProductName,
    Price,
    SUM(Price) OVER (PARTITION BY Category) AS CategoryTotal,
    AVG(Price) OVER (PARTITION BY Category) AS CategoryAvg,
    Price * 100.0 / SUM(Price) OVER (PARTITION BY Category) AS PercentOfCategory,
    Price - AVG(Price) OVER (PARTITION BY Category) AS DiffFromCategoryAvg
FROM Products
ORDER BY Category, Price DESC;
GO

-- =============================================
-- Example 11: Cumulative Distribution
-- =============================================

-- Cumulative percentage of sales
WITH OrderedSales AS (
    SELECT 
        SaleID,
        TotalAmount,
        SUM(TotalAmount) OVER (ORDER BY TotalAmount) AS CumulativeAmount,
        SUM(TotalAmount) OVER () AS GrandTotal
    FROM Sales
)
SELECT 
    SaleID,
    TotalAmount,
    CumulativeAmount,
    GrandTotal,
    CumulativeAmount * 100.0 / GrandTotal AS CumulativePercent
FROM OrderedSales
ORDER BY TotalAmount;
GO

-- =============================================
-- Example 12: Moving Sum (Sliding Window)
-- =============================================

-- 3-month moving sum
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(TotalAmount) AS MonthlyRevenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    SaleYear,
    SaleMonth,
    MonthlyRevenue,
    SUM(MonthlyRevenue) OVER (
        ORDER BY SaleYear, SaleMonth 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Rolling3MonthSum
FROM MonthlySales
ORDER BY SaleYear, SaleMonth;
GO

-- =============================================
-- Example 13: Product Stock Analysis
-- =============================================

-- Running totals and moving averages of stock
SELECT 
    ProductID,
    ProductName,
    StockQuantity,
    AVG(StockQuantity) OVER () AS OverallAvgStock,
    StockQuantity - AVG(StockQuantity) OVER () AS DiffFromAvg,
    SUM(StockQuantity) OVER (ORDER BY ProductID) AS RunningStockTotal,
    AVG(StockQuantity) OVER (
        ORDER BY ProductID 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS MovingAvg5Products
FROM Products
ORDER BY ProductID;
GO

-- =============================================
-- Example 14: Default Frame Behavior
-- =============================================

-- With ORDER BY, default frame is:
-- RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- These are equivalent:
SELECT 
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal1,
    SUM(TotalAmount) OVER (
        ORDER BY SaleDate 
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal2
FROM Sales
ORDER BY SaleDate;
-- Both columns show same result
GO

-- Without ORDER BY, default is all rows in partition:
SELECT 
    CustomerID,
    TotalAmount,
    SUM(TotalAmount) OVER (PARTITION BY CustomerID) AS CustomerTotal1,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS CustomerTotal2
FROM Sales
ORDER BY CustomerID;
-- Both columns show same result
GO

-- =============================================
-- Example 15: Complex Frame Example
-- =============================================

-- Product sales with multiple windows
SELECT 
    ProductID,
    SaleDate,
    Quantity,
    -- Running total
    SUM(Quantity) OVER (
        PARTITION BY ProductID 
        ORDER BY SaleDate
    ) AS RunningQty,
    -- 7-day moving average
    AVG(Quantity) OVER (
        PARTITION BY ProductID 
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7,
    -- All-time average for this product
    AVG(Quantity) OVER (
        PARTITION BY ProductID
    ) AS ProductAvgQty,
    -- Difference from product average
    Quantity - AVG(Quantity) OVER (PARTITION BY ProductID) AS DiffFromAvg
FROM Sales
ORDER BY ProductID, SaleDate;
GO

-- =============================================
-- Example 16: Daily Sales Trend
-- =============================================

-- Daily sales with trend analysis
WITH DailySales AS (
    SELECT 
        CAST(SaleDate AS DATE) AS SaleDate,
        SUM(TotalAmount) AS DailyRevenue,
        COUNT(*) AS DailyOrders
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE)
)
SELECT 
    SaleDate,
    DailyRevenue,
    DailyOrders,
    -- Running total
    SUM(DailyRevenue) OVER (ORDER BY SaleDate) AS RunningRevenue,
    -- 7-day moving average
    AVG(DailyRevenue) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7Day,
    -- 30-day moving average
    AVG(DailyRevenue) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS MovingAvg30Day,
    -- Compare to 7-day average
    DailyRevenue - AVG(DailyRevenue) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS DiffFrom7DayAvg
FROM DailySales
ORDER BY SaleDate;
GO

-- =============================================
-- Example 17: Customer Lifetime Value
-- =============================================

-- Customer LTV calculation
SELECT 
    c.CustomerID,
    c.CustomerName,
    s.SaleDate,
    s.TotalAmount,
    -- Cumulative spend
    SUM(s.TotalAmount) OVER (
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS LifetimeValue,
    -- Average order value to date
    AVG(s.TotalAmount) OVER (
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS AvgOrderValue,
    -- Order count to date
    COUNT(*) OVER (
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
    ) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
ORDER BY c.CustomerID, s.SaleDate;
GO

-- =============================================
-- Example 18: Performance Comparison
-- =============================================

-- Window function vs subquery for running total
-- Window function (efficient):
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal
FROM Sales
ORDER BY SaleDate;
GO

-- Subquery (inefficient):
SELECT 
    s1.SaleID,
    s1.SaleDate,
    s1.TotalAmount,
    (SELECT SUM(s2.TotalAmount) 
     FROM Sales s2 
     WHERE s2.SaleDate <= s1.SaleDate) AS RunningTotal
FROM Sales s1
ORDER BY s1.SaleDate;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
-- Window function is significantly faster!
GO

-- =============================================
-- Example 19: Multi-Level Aggregation
-- =============================================

-- Product, category, and grand totals
SELECT 
    Category,
    ProductName,
    Price * StockQuantity AS TotalValue,
    -- Category total
    SUM(Price * StockQuantity) OVER (PARTITION BY Category) AS CategoryTotal,
    -- Grand total
    SUM(Price * StockQuantity) OVER () AS GrandTotal,
    -- Percent of category
    (Price * StockQuantity) * 100.0 / 
        SUM(Price * StockQuantity) OVER (PARTITION BY Category) AS PctOfCategory,
    -- Percent of grand total
    (Price * StockQuantity) * 100.0 / 
        SUM(Price * StockQuantity) OVER () AS PctOfTotal
FROM Products
ORDER BY Category, TotalValue DESC;
GO

-- =============================================
-- Example 20: Best Practices
-- =============================================

-- ✅ GOOD: Use CTE to avoid recalculating window
WITH SalesWithWindows AS (
    SELECT 
        SaleID,
        SaleDate,
        TotalAmount,
        SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal
    FROM Sales
)
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    RunningTotal,
    RunningTotal * 0.1 AS RunningTax,
    RunningTotal * 0.05 AS RunningFee
FROM SalesWithWindows
ORDER BY SaleDate;
GO

-- ❌ BAD: Recalculating same window multiple times
/*
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) AS RunningTotal,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) * 0.1 AS RunningTax,
    SUM(TotalAmount) OVER (ORDER BY SaleDate) * 0.05 AS RunningFee
FROM Sales;
-- Window calculated 3 times unnecessarily!
*/

-- ✅ GOOD: Use ROWS instead of RANGE when exact count needed
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER (
        ORDER BY SaleDate 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS MovingAvg7
FROM Sales;
-- ROWS is faster than RANGE for moving averages
GO

-- 💡 Key Takeaways:
--
-- AGGREGATE WINDOW FUNCTIONS:
-- - SUM, AVG, COUNT, MIN, MAX work as window functions
-- - PARTITION BY divides data into groups (like GROUP BY but doesn't collapse rows)
-- - ORDER BY defines row order within partition
-- - Frame specification defines which rows to include
--
-- FRAMES (ROWS vs RANGE):
-- - ROWS: Physical row count (exact N rows)
-- - RANGE: Logical range (includes all rows with same ORDER BY value)
-- - ROWS is usually faster than RANGE
--
-- COMMON FRAMES:
-- - Running total: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- - Moving average: ROWS BETWEEN N PRECEDING AND CURRENT ROW
-- - Grand total: ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
-- - Centered window: ROWS BETWEEN N PRECEDING AND N FOLLOWING
--
-- DEFAULT FRAME:
-- - With ORDER BY: RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- - Without ORDER BY: All rows in partition
--
-- USE CASES:
-- - Running totals (cumulative sum)
-- - Moving averages (7-day, 30-day)
-- - Percentage of total
-- - Year-to-date calculations
-- - Trend analysis
-- - Customer lifetime value
--
-- PERFORMANCE:
-- - Index PARTITION BY and ORDER BY columns
-- - Use CTEs to avoid recalculating windows
-- - Use ROWS instead of RANGE when possible
-- - Window functions faster than correlated subqueries
-- - Materialize results for complex calculations
--
-- BEST PRACTICES:
-- - Use meaningful window frame specifications
-- - Document complex frame logic with comments
-- - Test with production-like data volumes
-- - Monitor query performance (execution plans)
-- - Use CTEs to make code readable
-- - Avoid recalculating same window multiple times
