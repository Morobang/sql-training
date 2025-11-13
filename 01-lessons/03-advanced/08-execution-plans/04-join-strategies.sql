-- ========================================
-- Join Strategies in Execution Plans
-- Nested Loops, Hash Match, Merge Join
-- ========================================

USE TechStore;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- =============================================
-- Understanding Join Operators
-- =============================================

/*
SQL Server chooses join strategy based on:
1. Table sizes
2. Available indexes
3. Join column selectivity
4. Statistics accuracy
5. Memory availability

Three main join types:
- Nested Loops: Best for small datasets, indexed joins
- Hash Match: Best for large datasets without indexes
- Merge Join: Best for large sorted datasets
*/

-- =============================================
-- Example 1: Nested Loops Join
-- =============================================

-- Small result set with index on join column
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
GO

-- Query with selective WHERE clause
SELECT 
    c.CustomerName,
    c.City,
    s.SaleDate,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.City = 'Chicago';

-- Execution plan: Nested Loops Join
-- How it works:
-- 1. Find customers in Chicago (outer loop)
-- 2. For each customer, seek sales using index (inner loop)
-- Efficient when outer result set is small
GO

-- =============================================
-- Example 2: Hash Match Join
-- =============================================

-- Large tables without suitable indexes
DROP INDEX IX_Sales_CustomerID ON Sales;
GO

-- Join without index on join column
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount,
    SUM(s.TotalAmount) AS TotalRevenue
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- Execution plan: Hash Match Join
-- How it works:
-- 1. Build phase: Create hash table from smaller input (Customers)
-- 2. Probe phase: Scan larger input (Sales), probe hash table
-- Used when no index available or large result sets
GO

-- =============================================
-- Example 3: Merge Join
-- =============================================

-- Both inputs sorted on join column
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
GO

-- Query where both sides sorted
SELECT 
    c.CustomerID,
    c.CustomerName,
    s.SaleID,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.CustomerID BETWEEN 1 AND 100
ORDER BY c.CustomerID;

-- Execution plan may show: Merge Join
-- How it works:
-- 1. Both inputs sorted by CustomerID
-- 2. Single pass through both datasets in parallel
-- 3. Match when keys equal, advance lower key when not
-- Efficient for large sorted datasets
GO

-- =============================================
-- Example 4: Join Strategy Comparison
-- =============================================

-- Create test scenario
DROP TABLE IF EXISTS SmallTable;
DROP TABLE IF EXISTS LargeTable;
GO

CREATE TABLE SmallTable (
    ID INT PRIMARY KEY,
    Value VARCHAR(50)
);

CREATE TABLE LargeTable (
    ID INT PRIMARY KEY,
    SmallID INT,
    Data VARCHAR(100)
);
GO

-- Insert data
INSERT INTO SmallTable (ID, Value)
SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), 'Value' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(10))
FROM sys.objects a CROSS JOIN sys.objects b;

INSERT INTO LargeTable (ID, SmallID, Data)
SELECT TOP 10000 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
    (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 100) + 1,
    'Data' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(10))
FROM sys.objects a CROSS JOIN sys.objects b;
GO

-- Scenario 1: Small outer, indexed inner = Nested Loops
CREATE NONCLUSTERED INDEX IX_LargeTable_SmallID ON LargeTable(SmallID);
GO

SELECT 
    s.ID,
    s.Value,
    l.Data
FROM SmallTable s
INNER JOIN LargeTable l ON s.ID = l.SmallID
WHERE s.ID <= 5;  -- Very selective

-- Nested Loops Join (small outer, index on inner)
GO

-- Scenario 2: No index = Hash Match
DROP INDEX IX_LargeTable_SmallID ON LargeTable;
GO

SELECT 
    s.Value,
    COUNT(l.ID) AS RowCnt
FROM SmallTable s
INNER JOIN LargeTable l ON s.ID = l.SmallID
GROUP BY s.Value;

-- Hash Match Join (no index, build hash on smaller table)
GO

-- Scenario 3: Both sorted = Merge Join
CREATE NONCLUSTERED INDEX IX_LargeTable_SmallID ON LargeTable(SmallID);
GO

SELECT 
    s.ID,
    l.ID AS LargeID
FROM SmallTable s
INNER JOIN LargeTable l ON s.ID = l.SmallID
ORDER BY s.ID;

-- May show Merge Join (both inputs sorted)
GO

-- =============================================
-- Example 5: Multiple Joins
-- =============================================

-- Three-table join
SELECT 
    c.CustomerName,
    p.ProductName,
    s.SaleDate,
    s.Quantity,
    s.TotalAmount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.SaleDate >= '2024-01-01';

-- Execution plan shows join order and operators:
-- Example: Sales → Customers (Nested Loops), then → Products (Nested Loops)
-- Join order matters for performance
GO

-- =============================================
-- Example 6: Join Order Impact
-- =============================================

-- Force different join order with hints
-- Option 1: Let optimizer decide (default)
SELECT 
    c.CustomerName,
    p.ProductName,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE c.City = 'Chicago';
-- Optimizer chooses join order based on statistics
GO

-- Option 2: Force specific order (rarely needed)
SELECT 
    c.CustomerName,
    p.ProductName,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE c.City = 'Chicago'
OPTION (FORCE ORDER);
-- Forces joins in FROM clause order (may be slower)
GO

-- =============================================
-- Example 7: LEFT JOIN vs INNER JOIN Plans
-- =============================================

-- INNER JOIN (only matching rows)
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;
-- Nested Loops or Hash Match
GO

-- LEFT JOIN (all customers, even without sales)
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;
-- LEFT OUTER JOIN in plan (preserves NULLs)
-- May use different strategy than INNER JOIN
GO

-- =============================================
-- Example 8: Hash Match Warning - Memory Spill
-- =============================================

-- Large hash join may spill to tempdb
SELECT 
    c.CustomerID,
    c.CustomerName,
    s.SaleID,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
OPTION (HASH JOIN);  -- Force hash join

-- Check execution plan for warnings:
-- Exclamation mark on Hash Match = memory grant issue or spill
-- Spill to tempdb = slower performance
GO

-- =============================================
-- Example 9: Nested Loops with Lookup
-- =============================================

-- Nested loops with key lookup on inner table
DROP INDEX IF EXISTS IX_Sales_ProductID ON Sales;
GO

SELECT 
    p.ProductName,
    s.SaleDate,
    s.Quantity,
    s.TotalAmount
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
WHERE p.Category = 'Electronics';

-- Execution plan may show:
-- Nested Loops Join
--   → Products: Index Seek (Category)
--   → Sales: Clustered Index Seek (ProductID) + possible lookup
GO

-- Add covering index on inner table
CREATE NONCLUSTERED INDEX IX_Sales_ProductID_Covering
ON Sales(ProductID)
INCLUDE (SaleDate, Quantity, TotalAmount);
GO

-- Same query, more efficient inner loop
SELECT 
    p.ProductName,
    s.SaleDate,
    s.Quantity,
    s.TotalAmount
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
WHERE p.Category = 'Electronics';
-- No lookup on inner table
GO

-- =============================================
-- Example 10: Cross Join (Cartesian Product)
-- =============================================

-- Cross join without WHERE clause
SELECT 
    c.CustomerName,
    p.ProductName
FROM Customers c
CROSS JOIN Products p;
-- Cartesian product: every customer × every product
-- Execution plan: Nested Loops (Cartesian)
-- WARNING: Can be huge! Rows = Customers × Products
GO

-- Usually indicates missing join condition (accidental)
SELECT 
    c.CustomerName,
    p.ProductName,
    s.TotalAmount
FROM Customers c
CROSS JOIN Products p
INNER JOIN Sales s ON c.CustomerID = s.CustomerID;  -- Missing: s.ProductID = p.ProductID
-- Likely a bug! Missing join condition causes Cartesian product
GO

-- =============================================
-- Example 11: Join Hints (Use Sparingly)
-- =============================================

-- Force nested loops
SELECT 
    c.CustomerName,
    s.TotalAmount
FROM Customers c
INNER LOOP JOIN Sales s ON c.CustomerID = s.CustomerID;
-- Forces nested loops (may not be optimal)
GO

-- Force hash join
SELECT 
    c.CustomerName,
    s.TotalAmount
FROM Customers c
INNER HASH JOIN Sales s ON c.CustomerID = s.CustomerID;
-- Forces hash match
GO

-- Force merge join
SELECT 
    c.CustomerName,
    s.TotalAmount
FROM Customers c
INNER MERGE JOIN Sales s ON c.CustomerID = s.CustomerID;
-- Forces merge join (may add sort operators)
GO

-- Note: Let optimizer choose unless you have specific reason!

-- =============================================
-- Example 12: Adaptive Join (SQL 2017+)
-- =============================================

-- SQL Server 2017+ can switch join strategy at runtime
-- Based on actual row counts during execution

SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- In SQL 2017+, may show "Adaptive Join"
-- Starts as nested loops, switches to hash if too many rows
-- Check actual execution plan for adaptive join operator
GO

-- =============================================
-- Example 13: Join Performance Comparison
-- =============================================

-- Benchmark different join strategies
DECLARE @StartTime DATETIME;

-- Test 1: With indexes (likely nested loops)
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID_Test ON Sales(CustomerID);
CREATE NONCLUSTERED INDEX IX_Sales_ProductID_Test ON Sales(ProductID);
GO

SET @StartTime = GETDATE();

SELECT 
    c.CustomerName,
    p.ProductName,
    COUNT(*) AS SalesCount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerName, p.ProductName;

PRINT 'With indexes: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + 'ms';
GO

-- Test 2: Without indexes (likely hash join)
DROP INDEX IX_Sales_CustomerID_Test ON Sales;
DROP INDEX IX_Sales_ProductID_Test ON Sales;
GO

DECLARE @StartTime DATETIME = GETDATE();

SELECT 
    c.CustomerName,
    p.ProductName,
    COUNT(*) AS SalesCount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerName, p.ProductName;

PRINT 'Without indexes: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + 'ms';
GO

-- Restore indexes
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
CREATE NONCLUSTERED INDEX IX_Sales_ProductID ON Sales(ProductID);
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- =============================================
-- Cleanup
-- =============================================

DROP TABLE IF EXISTS SmallTable;
DROP TABLE IF EXISTS LargeTable;
DROP INDEX IF EXISTS IX_Sales_ProductID_Covering ON Sales;
GO

-- 💡 Key Takeaways:
-- - Nested Loops: Small outer, index on inner (best for small datasets)
-- - Hash Match: Large tables, no index (builds hash table)
-- - Merge Join: Both inputs sorted (efficient for large sorted data)
-- - Join order matters: Optimizer usually gets it right
-- - Index foreign keys: Dramatically improves join performance
-- - LEFT JOIN preserves NULLs: May use different strategy than INNER
-- - Memory spills: Hash joins need sufficient memory
-- - Cross joins: Usually indicate missing join condition (bug)
-- - Adaptive joins (SQL 2017+): Switch strategy at runtime
-- - Covering indexes: Eliminate lookups in inner table
-- - Force joins sparingly: Let optimizer decide
-- - Missing join conditions: Causes Cartesian product (huge result)
-- - Check execution plan: Hover over join operators for details
-- - Estimated vs actual rows: Large difference = statistics issue
-- - Thick arrows: Many rows flowing through (potential bottleneck)
