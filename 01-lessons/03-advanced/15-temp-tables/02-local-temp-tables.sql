-- ========================================
-- Local Temporary Tables (#temp)
-- ========================================

USE TechStore;

-- =============================================
-- Example 1: Creating and Using #temp Tables
-- =============================================

-- Create temporary table for analysis
CREATE TABLE #CategorySales (
    Category NVARCHAR(50),
    TotalRevenue DECIMAL(10,2),
    TotalOrders INT,
    AvgOrderValue DECIMAL(10,2)
);

-- Populate with aggregated data
INSERT INTO #CategorySales (Category, TotalRevenue, TotalOrders, AvgOrderValue)
SELECT 
    p.Category,
    SUM(s.TotalAmount) AS TotalRevenue,
    COUNT(s.SaleID) AS TotalOrders,
    AVG(s.TotalAmount) AS AvgOrderValue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.Category;

-- Query the temporary table multiple times
SELECT * FROM #CategorySales ORDER BY TotalRevenue DESC;

SELECT 
    Category,
    TotalRevenue,
    TotalRevenue * 100.0 / (SELECT SUM(TotalRevenue) FROM #CategorySales) AS PctOfTotal
FROM #CategorySales;

-- Temporary tables automatically drop when session ends
DROP TABLE #CategorySales;

-- =============================================
-- Example 2: Complex Multi-Step Analysis
-- =============================================

-- Step 1: Identify top customers
CREATE TABLE #TopCustomers (
    CustomerID INT,
    CustomerName NVARCHAR(100),
    TotalSpent DECIMAL(10,2),
    OrderCount INT
);

INSERT INTO #TopCustomers
SELECT TOP 10
    c.CustomerID,
    c.CustomerName,
    SUM(s.TotalAmount) AS TotalSpent,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY SUM(s.TotalAmount) DESC;

-- Step 2: Get their purchase details
SELECT 
    tc.CustomerName,
    tc.TotalSpent,
    p.ProductName,
    s.SaleDate,
    s.TotalAmount
FROM #TopCustomers tc
INNER JOIN Sales s ON tc.CustomerID = s.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
ORDER BY tc.TotalSpent DESC, s.SaleDate DESC;

DROP TABLE #TopCustomers;

-- =============================================
-- Example 3: Using #temp for Data Transformation
-- =============================================

-- Create staging table
CREATE TABLE #SalesStaging (
    SaleID INT,
    CustomerName NVARCHAR(100),
    ProductName NVARCHAR(100),
    SaleDate DATE,
    Amount DECIMAL(10,2),
    Quarter NVARCHAR(10),
    Season NVARCHAR(20)
);

-- Transform and enrich data
INSERT INTO #SalesStaging
SELECT 
    s.SaleID,
    c.CustomerName,
    p.ProductName,
    CAST(s.SaleDate AS DATE) AS SaleDate,
    s.TotalAmount,
    'Q' + CAST(DATEPART(QUARTER, s.SaleDate) AS VARCHAR(1)) AS Quarter,
    CASE 
        WHEN MONTH(s.SaleDate) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(s.SaleDate) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(s.SaleDate) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS Season
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID;

-- Analyze by quarter and season
SELECT 
    Quarter,
    Season,
    COUNT(*) AS SalesCount,
    SUM(Amount) AS TotalRevenue
FROM #SalesStaging
GROUP BY Quarter, Season
ORDER BY Quarter, Season;

DROP TABLE #SalesStaging;

-- =============================================
-- Example 4: Breaking Down Complex Queries
-- =============================================

-- Instead of one complex query, break into steps

-- Step 1: Get product performance
CREATE TABLE #ProductPerformance (
    ProductID INT,
    ProductName NVARCHAR(100),
    UnitsSold INT,
    Revenue DECIMAL(10,2)
);

INSERT INTO #ProductPerformance
SELECT 
    p.ProductID,
    p.ProductName,
    SUM(s.Quantity) AS UnitsSold,
    SUM(s.TotalAmount) AS Revenue
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName;

-- Step 2: Calculate category averages
CREATE TABLE #CategoryAvg (
    Category NVARCHAR(50),
    AvgRevenue DECIMAL(10,2)
);

INSERT INTO #CategoryAvg
SELECT 
    p.Category,
    AVG(pp.Revenue) AS AvgRevenue
FROM Products p
INNER JOIN #ProductPerformance pp ON p.ProductID = pp.ProductID
GROUP BY p.Category;

-- Step 3: Compare products to category average
SELECT 
    pp.ProductName,
    p.Category,
    pp.Revenue,
    ca.AvgRevenue AS CategoryAvg,
    pp.Revenue - ca.AvgRevenue AS DiffFromAvg,
    CASE 
        WHEN pp.Revenue > ca.AvgRevenue THEN 'Above Average'
        WHEN pp.Revenue < ca.AvgReverage THEN 'Below Average'
        ELSE 'Average'
    END AS Performance
FROM #ProductPerformance pp
INNER JOIN Products p ON pp.ProductID = p.ProductID
INNER JOIN #CategoryAvg ca ON p.Category = ca.Category
ORDER BY p.Category, pp.Revenue DESC;

DROP TABLE #ProductPerformance;
DROP TABLE #CategoryAvg;

-- =============================================
-- Example 5: #temp Tables with Constraints
-- =============================================

-- Create temp table with primary key and indexes
CREATE TABLE #CustomerAnalysis (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100),
    TotalOrders INT,
    TotalSpent DECIMAL(10,2),
    AvgOrderValue DECIMAL(10,2),
    LastPurchaseDate DATE,
    INDEX IX_TotalSpent (TotalSpent DESC)
);

INSERT INTO #CustomerAnalysis
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS TotalSpent,
    AVG(s.TotalAmount) AS AvgOrderValue,
    MAX(s.SaleDate) AS LastPurchaseDate
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Fast lookup by CustomerID (primary key)
SELECT * FROM #CustomerAnalysis WHERE CustomerID = 1;

-- Fast sorting by TotalSpent (indexed)
SELECT TOP 5 * FROM #CustomerAnalysis ORDER BY TotalSpent DESC;

DROP TABLE #CustomerAnalysis;

-- 💡 Key Points:
-- - #temp tables are session-specific (isolated per connection)
-- - Automatically dropped when session ends or explicitly with DROP
-- - Support indexes, constraints, and all table features
-- - Stored in tempdb database
-- - Great for breaking complex queries into manageable steps
-- - Use for intermediate results that need multiple operations
