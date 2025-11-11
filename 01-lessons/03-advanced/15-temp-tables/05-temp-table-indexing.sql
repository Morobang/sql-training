-- ========================================
-- Indexing Temporary Tables for Performance
-- ========================================

USE TechStore;

-- =============================================
-- Example 1: Temp Table WITHOUT Index
-- =============================================

-- Create temp table without index
CREATE TABLE #SalesNoIndex (
    SaleID INT,
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    TotalAmount DECIMAL(10,2)
);

-- Insert all sales data
INSERT INTO #SalesNoIndex
SELECT 
    SaleID,
    CustomerID,
    ProductID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount
FROM Sales;

-- Query without index (table scan - slow for large data)
SELECT * FROM #SalesNoIndex WHERE CustomerID = 5;

-- Check execution plan: Table Scan
-- SET STATISTICS IO ON;
-- Previous query will show high logical reads

DROP TABLE #SalesNoIndex;

-- =============================================
-- Example 2: Temp Table WITH Index
-- =============================================

-- Method 1: Create index after data insertion
CREATE TABLE #SalesWithIndex (
    SaleID INT,
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    TotalAmount DECIMAL(10,2)
);

INSERT INTO #SalesWithIndex
SELECT 
    SaleID,
    CustomerID,
    ProductID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount
FROM Sales;

-- Create index after loading data (usually faster)
CREATE INDEX IX_Customer ON #SalesWithIndex(CustomerID);
CREATE INDEX IX_Product ON #SalesWithIndex(ProductID);
CREATE INDEX IX_Date ON #SalesWithIndex(SaleDate);

-- Query with index (index seek - fast!)
SELECT * FROM #SalesWithIndex WHERE CustomerID = 5;

-- Check execution plan: Index Seek
-- Much fewer logical reads than non-indexed version

DROP TABLE #SalesWithIndex;

-- =============================================
-- Example 3: Index at Creation Time
-- =============================================

-- Method 2: Define indexes during table creation
CREATE TABLE #SalesIndexed (
    SaleID INT PRIMARY KEY,              -- Clustered index
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    TotalAmount DECIMAL(10,2),
    INDEX IX_Customer (CustomerID),      -- Non-clustered index
    INDEX IX_Product (ProductID),        -- Non-clustered index
    INDEX IX_Date (SaleDate)             -- Non-clustered index
);

INSERT INTO #SalesIndexed
SELECT 
    SaleID,
    CustomerID,
    ProductID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount
FROM Sales;

-- Fast lookups on any indexed column
SELECT * FROM #SalesIndexed WHERE CustomerID = 5;
SELECT * FROM #SalesIndexed WHERE ProductID = 10;
SELECT * FROM #SalesIndexed WHERE SaleDate = '2024-11-01';

DROP TABLE #SalesIndexed;

-- =============================================
-- Example 4: Composite Index for Complex Queries
-- =============================================

CREATE TABLE #CustomerPurchases (
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    Amount DECIMAL(10,2),
    -- Composite index: CustomerID + SaleDate
    INDEX IX_CustomerDate (CustomerID, SaleDate)
);

INSERT INTO #CustomerPurchases
SELECT 
    CustomerID,
    ProductID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount
FROM Sales;

-- Query benefits from composite index
SELECT 
    CustomerID,
    SaleDate,
    SUM(Amount) AS DailyTotal
FROM #CustomerPurchases
WHERE CustomerID = 5 AND SaleDate >= '2024-11-01'
GROUP BY CustomerID, SaleDate;

-- Composite index provides efficient filtering and grouping

DROP TABLE #CustomerPurchases;

-- =============================================
-- Example 5: When to Index vs When NOT to Index
-- =============================================

-- ✅ CREATE INDEX when:
-- - Large temp table (> 1000 rows)
-- - Multiple queries against same table
-- - JOIN operations
-- - WHERE clause filtering
-- - ORDER BY / GROUP BY operations

-- ❌ DON'T CREATE INDEX when:
-- - Small temp table (< 100 rows)
-- - Single query (full scan is fine)
-- - One-time data load and export
-- - Index creation overhead > query benefit

-- Example: Small table - NO index needed
CREATE TABLE #SmallLookup (
    ID INT,
    Name NVARCHAR(50)
);

INSERT INTO #SmallLookup VALUES
    (1, 'Category A'),
    (2, 'Category B'),
    (3, 'Category C');

-- Table scan is fine for 3 rows
SELECT * FROM #SmallLookup WHERE ID = 2;

DROP TABLE #SmallLookup;

-- Example: Large table - INDEX recommended
CREATE TABLE #LargeAnalysis (
    CustomerID INT,
    Month DATE,
    Revenue DECIMAL(10,2),
    OrderCount INT,
    INDEX IX_Customer (CustomerID),
    INDEX IX_Month (Month)
);

-- Insert aggregated data (potentially thousands of rows)
INSERT INTO #LargeAnalysis
SELECT 
    CustomerID,
    DATEFROMPARTS(YEAR(SaleDate), MONTH(SaleDate), 1) AS Month,
    SUM(TotalAmount) AS Revenue,
    COUNT(*) AS OrderCount
FROM Sales
GROUP BY CustomerID, DATEFROMPARTS(YEAR(SaleDate), MONTH(SaleDate), 1);

-- Indexes make this query fast
SELECT * FROM #LargeAnalysis 
WHERE CustomerID = 5 
ORDER BY Month DESC;

DROP TABLE #LargeAnalysis;

-- =============================================
-- Example 6: Clustered vs Non-Clustered Index
-- =============================================

-- Clustered index: Physical order of data
CREATE TABLE #ClusteredExample (
    SaleDate DATE PRIMARY KEY,           -- Clustered index (only 1 per table)
    TotalRevenue DECIMAL(10,2),
    OrderCount INT
);

INSERT INTO #ClusteredExample
SELECT 
    CAST(SaleDate AS DATE) AS SaleDate,
    SUM(TotalAmount) AS TotalRevenue,
    COUNT(*) AS OrderCount
FROM Sales
GROUP BY CAST(SaleDate AS DATE);

-- Data physically ordered by SaleDate
SELECT * FROM #ClusteredExample 
WHERE SaleDate BETWEEN '2024-11-01' AND '2024-11-10';

-- Non-clustered indexes: Separate structure pointing to data
CREATE INDEX IX_Revenue ON #ClusteredExample(TotalRevenue);

SELECT * FROM #ClusteredExample 
WHERE TotalRevenue > 500
ORDER BY TotalRevenue DESC;

DROP TABLE #ClusteredExample;

-- =============================================
-- Example 7: Statistics on Temp Tables
-- =============================================

CREATE TABLE #ProductStats (
    ProductID INT,
    Category NVARCHAR(50),
    Revenue DECIMAL(10,2),
    UnitsSold INT
);

INSERT INTO #ProductStats
SELECT 
    p.ProductID,
    p.Category,
    SUM(s.TotalAmount) AS Revenue,
    SUM(s.Quantity) AS UnitsSold
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.Category;

-- Create statistics for better query optimization
CREATE STATISTICS Stats_Revenue ON #ProductStats(Revenue);
CREATE STATISTICS Stats_Category ON #ProductStats(Category);

-- Optimizer uses statistics to choose better execution plan
SELECT Category, SUM(Revenue) AS CategoryRevenue
FROM #ProductStats
WHERE Revenue > 100
GROUP BY Category;

DROP TABLE #ProductStats;

-- =============================================
-- Example 8: Index Strategy Comparison
-- =============================================

PRINT '===== INDEX STRATEGY COMPARISON =====';

-- Strategy 1: No indexes (baseline)
DECLARE @Start1 DATETIME = GETDATE();

CREATE TABLE #NoIndexes (
    CustomerID INT,
    ProductID INT,
    Amount DECIMAL(10,2)
);

INSERT INTO #NoIndexes
SELECT CustomerID, ProductID, TotalAmount FROM Sales;

SELECT CustomerID, SUM(Amount) 
FROM #NoIndexes 
WHERE CustomerID IN (1, 2, 3, 4, 5)
GROUP BY CustomerID;

PRINT 'No Indexes: ' + CAST(DATEDIFF(MILLISECOND, @Start1, GETDATE()) AS VARCHAR) + ' ms';
DROP TABLE #NoIndexes;

-- Strategy 2: With index on CustomerID
DECLARE @Start2 DATETIME = GETDATE();

CREATE TABLE #WithIndex (
    CustomerID INT,
    ProductID INT,
    Amount DECIMAL(10,2),
    INDEX IX_Customer (CustomerID)
);

INSERT INTO #WithIndex
SELECT CustomerID, ProductID, TotalAmount FROM Sales;

SELECT CustomerID, SUM(Amount) 
FROM #WithIndex 
WHERE CustomerID IN (1, 2, 3, 4, 5)
GROUP BY CustomerID;

PRINT 'With Index: ' + CAST(DATEDIFF(MILLISECOND, @Start2, GETDATE()) AS VARCHAR) + ' ms';
DROP TABLE #WithIndex;

-- 💡 Key Takeaways:
-- - Index temp tables for better query performance
-- - Create indexes AFTER bulk data load for faster insertion
-- - Use composite indexes for multi-column filters
-- - PRIMARY KEY creates clustered index automatically
-- - Don't over-index: each index has maintenance cost
-- - Statistics help optimizer choose better plans
-- - Test performance: sometimes table scan is faster than index for small data
