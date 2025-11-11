-- ========================================
-- Performance Comparison: #temp vs @table
-- ========================================

USE TechStore;

-- =============================================
-- Test Setup
-- =============================================

-- Create larger test dataset if needed
-- (Sales table should have enough data already)

SELECT COUNT(*) AS TotalSalesRecords FROM Sales;

-- =============================================
-- Test 1: Small Dataset (< 100 rows)
-- =============================================

PRINT '===== SMALL DATASET TEST =====';

-- Using Table Variable
DECLARE @StartTime1 DATETIME = GETDATE();

DECLARE @SmallTable TABLE (
    ProductID INT,
    TotalSales DECIMAL(10,2),
    OrderCount INT
);

INSERT INTO @SmallTable
SELECT TOP 50
    ProductID,
    SUM(TotalAmount) AS TotalSales,
    COUNT(*) AS OrderCount
FROM Sales
GROUP BY ProductID
ORDER BY SUM(TotalAmount) DESC;

SELECT * FROM @SmallTable WHERE TotalSales > 100;

DECLARE @TableVarTime1 INT = DATEDIFF(MILLISECOND, @StartTime1, GETDATE());
PRINT 'Table Variable Time: ' + CAST(@TableVarTime1 AS VARCHAR) + ' ms';

-- Using Temp Table
DECLARE @StartTime2 DATETIME = GETDATE();

CREATE TABLE #SmallTemp (
    ProductID INT,
    TotalSales DECIMAL(10,2),
    OrderCount INT
);

INSERT INTO #SmallTemp
SELECT TOP 50
    ProductID,
    SUM(TotalAmount) AS TotalSales,
    COUNT(*) AS OrderCount
FROM Sales
GROUP BY ProductID
ORDER BY SUM(TotalAmount) DESC;

SELECT * FROM #SmallTemp WHERE TotalSales > 100;

DECLARE @TempTableTime1 INT = DATEDIFF(MILLISECOND, @StartTime2, GETDATE());
PRINT 'Temp Table Time: ' + CAST(@TempTableTime1 AS VARCHAR) + ' ms';

DROP TABLE #SmallTemp;

-- Result: Table variables usually faster for small data

-- =============================================
-- Test 2: Large Dataset (> 1000 rows)
-- =============================================

PRINT '';
PRINT '===== LARGE DATASET TEST =====';

-- Using Table Variable
DECLARE @StartTime3 DATETIME = GETDATE();

DECLARE @LargeTable TABLE (
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    Amount DECIMAL(10,2)
);

INSERT INTO @LargeTable
SELECT 
    CustomerID,
    ProductID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount
FROM Sales;

SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(Amount) AS TotalSpent
FROM @LargeTable
GROUP BY CustomerID
HAVING SUM(Amount) > 500;

DECLARE @TableVarTime2 INT = DATEDIFF(MILLISECOND, @StartTime3, GETDATE());
PRINT 'Table Variable Time: ' + CAST(@TableVarTime2 AS VARCHAR) + ' ms';

-- Using Temp Table with Index
DECLARE @StartTime4 DATETIME = GETDATE();

CREATE TABLE #LargeTemp (
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    Amount DECIMAL(10,2),
    INDEX IX_Customer (CustomerID)  -- Index for better GROUP BY performance
);

INSERT INTO #LargeTemp
SELECT 
    CustomerID,
    ProductID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount
FROM Sales;

SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(Amount) AS TotalSpent
FROM #LargeTemp
GROUP BY CustomerID
HAVING SUM(Amount) > 500;

DECLARE @TempTableTime2 INT = DATEDIFF(MILLISECOND, @StartTime4, GETDATE());
PRINT 'Temp Table Time: ' + CAST(@TempTableTime2 AS VARCHAR) + ' ms';

DROP TABLE #LargeTemp;

-- Result: Temp tables usually faster for large data with indexes

-- =============================================
-- Test 3: Multiple Query Access
-- =============================================

PRINT '';
PRINT '===== MULTIPLE QUERY TEST =====';

-- Using Table Variable
DECLARE @StartTime5 DATETIME = GETDATE();

DECLARE @MultiQuery TABLE (
    Category NVARCHAR(50),
    AvgPrice DECIMAL(10,2),
    ProductCount INT
);

INSERT INTO @MultiQuery
SELECT 
    Category,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY Category;

-- Query 1
SELECT * FROM @MultiQuery WHERE AvgPrice > 100;

-- Query 2
SELECT * FROM @MultiQuery WHERE ProductCount > 5;

-- Query 3
SELECT AVG(AvgPrice) AS OverallAvg FROM @MultiQuery;

DECLARE @TableVarTime3 INT = DATEDIFF(MILLISECOND, @StartTime5, GETDATE());
PRINT 'Table Variable Time: ' + CAST(@TableVarTime3 AS VARCHAR) + ' ms';

-- Using Temp Table with Statistics
DECLARE @StartTime6 DATETIME = GETDATE();

CREATE TABLE #MultiQueryTemp (
    Category NVARCHAR(50),
    AvgPrice DECIMAL(10,2),
    ProductCount INT
);

INSERT INTO #MultiQueryTemp
SELECT 
    Category,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY Category;

-- Create statistics for better query optimization
CREATE STATISTICS Stats_AvgPrice ON #MultiQueryTemp(AvgPrice);
CREATE STATISTICS Stats_Count ON #MultiQueryTemp(ProductCount);

-- Query 1
SELECT * FROM #MultiQueryTemp WHERE AvgPrice > 100;

-- Query 2
SELECT * FROM #MultiQueryTemp WHERE ProductCount > 5;

-- Query 3
SELECT AVG(AvgPrice) AS OverallAvg FROM #MultiQueryTemp;

DECLARE @TempTableTime3 INT = DATEDIFF(MILLISECOND, @StartTime6, GETDATE());
PRINT 'Temp Table Time: ' + CAST(@TempTableTime3 AS VARCHAR) + ' ms';

DROP TABLE #MultiQueryTemp;

-- Result: Temp tables with statistics perform better for multiple queries

-- =============================================
-- Test 4: JOIN Performance
-- =============================================

PRINT '';
PRINT '===== JOIN PERFORMANCE TEST =====';

-- Using Table Variable
DECLARE @StartTime7 DATETIME = GETDATE();

DECLARE @CategorySummary TABLE (
    Category NVARCHAR(50),
    TotalRevenue DECIMAL(10,2)
);

INSERT INTO @CategorySummary
SELECT 
    p.Category,
    SUM(s.TotalAmount) AS TotalRevenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.Category;

SELECT 
    p.ProductName,
    p.Category,
    cs.TotalRevenue AS CategoryRevenue
FROM Products p
INNER JOIN @CategorySummary cs ON p.Category = cs.Category
WHERE p.Price > 100;

DECLARE @TableVarTime4 INT = DATEDIFF(MILLISECOND, @StartTime7, GETDATE());
PRINT 'Table Variable Time: ' + CAST(@TableVarTime4 AS VARCHAR) + ' ms';

-- Using Temp Table
DECLARE @StartTime8 DATETIME = GETDATE();

CREATE TABLE #CategorySummaryTemp (
    Category NVARCHAR(50) PRIMARY KEY,
    TotalRevenue DECIMAL(10,2)
);

INSERT INTO #CategorySummaryTemp
SELECT 
    p.Category,
    SUM(s.TotalAmount) AS TotalRevenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.Category;

SELECT 
    p.ProductName,
    p.Category,
    cs.TotalRevenue AS CategoryRevenue
FROM Products p
INNER JOIN #CategorySummaryTemp cs ON p.Category = cs.Category
WHERE p.Price > 100;

DECLARE @TempTableTime4 INT = DATEDIFF(MILLISECOND, @StartTime8, GETDATE());
PRINT 'Temp Table Time: ' + CAST(@TempTableTime4 AS VARCHAR) + ' ms';

DROP TABLE #CategorySummaryTemp;

-- Result: Temp table with PRIMARY KEY faster for JOINs

-- =============================================
-- Performance Summary
-- =============================================

PRINT '';
PRINT '===== PERFORMANCE GUIDELINES =====';
PRINT '';
PRINT 'Use Table Variables (@table) when:';
PRINT '  ✅ Small datasets (< 100 rows)';
PRINT '  ✅ Single query usage';
PRINT '  ✅ Simple operations';
PRINT '  ✅ Stored procedure local scope';
PRINT '';
PRINT 'Use Temp Tables (#temp) when:';
PRINT '  ✅ Large datasets (> 100 rows)';
PRINT '  ✅ Multiple queries against same data';
PRINT '  ✅ Need indexes for performance';
PRINT '  ✅ Complex JOINs';
PRINT '  ✅ Need statistics for optimization';
PRINT '';

-- 💡 Key Takeaways:
-- - @table: Low overhead, good for small data and simple operations
-- - #temp: Better optimization, good for large data and complex queries
-- - #temp supports indexes and statistics for performance
-- - @table has fixed cardinality estimate (usually 1 row)
-- - For production: test both and measure actual performance
