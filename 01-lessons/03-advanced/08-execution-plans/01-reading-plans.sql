-- ========================================
-- Reading Execution Plans
-- Understanding Plan Operators
-- ========================================

USE TechStore;
GO

-- =============================================
-- Enable Execution Plans and Statistics
-- =============================================

-- Show actual execution plan (Ctrl+M in SSMS)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- =============================================
-- Example 1: Table Scan vs Index Seek
-- =============================================

-- Table scan (reads entire table)
SELECT ProductID, ProductName, Price
FROM Products
WHERE ProductName = 'Laptop';
-- Check execution plan: Clustered Index Scan (if no index on ProductName)
-- Logical reads: High (entire table scanned)
GO

-- Create index for comparison
CREATE NONCLUSTERED INDEX IX_Products_ProductName ON Products(ProductName);
GO

-- Index seek (jumps to specific rows)
SELECT ProductID, ProductName, Price
FROM Products
WHERE ProductName = 'Laptop';
-- Check execution plan: Index Seek on IX_Products_ProductName
-- Logical reads: Low (only relevant rows)
GO

-- =============================================
-- Example 2: Index Seek + Key Lookup
-- =============================================

-- Query needs columns not in index
SELECT ProductID, ProductName, Price, Cost, StockQuantity
FROM Products
WHERE ProductName LIKE 'L%';

-- Execution plan shows:
-- 1. Index Seek (IX_Products_ProductName) - Find matching rows
-- 2. Key Lookup (Clustered) - Get Price, Cost, StockQuantity
-- 3. Nested Loops Join - Combine results
-- This pattern indicates need for covering index
GO

-- =============================================
-- Example 3: Covering Index Eliminates Lookup
-- =============================================

-- Drop and recreate as covering index
DROP INDEX IX_Products_ProductName ON Products;
GO

CREATE NONCLUSTERED INDEX IX_Products_ProductName_Covering
ON Products(ProductName)
INCLUDE (Price, Cost, StockQuantity);
GO

-- Same query, no key lookup
SELECT ProductID, ProductName, Price, Cost, StockQuantity
FROM Products
WHERE ProductName LIKE 'L%';

-- Execution plan shows:
-- 1. Index Seek (IX_Products_ProductName_Covering) - All data in index
-- No key lookup! Much faster.
GO

-- =============================================
-- Example 4: Index Scan vs Index Seek
-- =============================================

-- Create index on Category
CREATE NONCLUSTERED INDEX IX_Products_Category ON Products(Category);
GO

-- Selective query (few rows) = Index Seek
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics';
-- Index Seek (efficient)
GO

-- Non-selective query (many rows) = Index Scan
SELECT ProductName, Category, Price
FROM Products
WHERE Category LIKE '%';  -- Matches everything
-- Index Scan or Table Scan (reads entire index/table)
GO

-- =============================================
-- Example 5: Implicit Conversion Warning
-- =============================================

-- ProductID is INT
-- Query with VARCHAR causes implicit conversion

SELECT ProductName, Price
FROM Products
WHERE ProductID = '1';  -- VARCHAR compared to INT column
-- Warning in execution plan: CONVERT_IMPLICIT
-- Index cannot be used efficiently
-- Fix: Use correct data type
GO

-- Correct query (no conversion)
SELECT ProductName, Price
FROM Products
WHERE ProductID = 1;  -- INT compared to INT
-- No warning, index used efficiently
GO

-- =============================================
-- Example 6: Sort Operator
-- =============================================

-- Query with ORDER BY on non-indexed column
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE Category = 'Electronics'
ORDER BY StockQuantity DESC;

-- Execution plan shows:
-- 1. Index Seek (Category)
-- 2. Sort (ORDER BY StockQuantity) - Expensive!
-- 3. Select
GO

-- Create index matching ORDER BY
CREATE NONCLUSTERED INDEX IX_Products_Category_Stock
ON Products(Category, StockQuantity DESC)
INCLUDE (ProductName, Price);
GO

-- Same query, no sort operator
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE Category = 'Electronics'
ORDER BY StockQuantity DESC;

-- Execution plan shows:
-- 1. Index Seek (data already in correct order)
-- No Sort operator!
GO

-- =============================================
-- Example 7: Filter vs Index Predicate
-- =============================================

-- Predicate pushed to index (SARGable)
SELECT ProductName, Price
FROM Products
WHERE Price > 100;  -- Simple comparison
-- Seek Predicate: Price > 100 (efficient)
GO

-- Predicate cannot be pushed (non-SARGable)
SELECT ProductName, Price
FROM Products
WHERE YEAR(JoinDate) = 2024;  -- Function on column
-- Execution plan shows Filter operator (less efficient)
-- All rows scanned, then filtered
GO

-- Better: SARGable predicate
SELECT ProductName, Price
FROM Products
WHERE JoinDate >= '2024-01-01' AND JoinDate < '2025-01-01';
-- Can use index efficiently
GO

-- =============================================
-- Example 8: Nested Loops Join
-- =============================================

-- Small inner table, indexed join column
SELECT 
    c.CustomerName,
    s.SaleDate,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.City = 'Chicago';

-- Execution plan typically shows:
-- Nested Loops Join (efficient for small result sets)
-- For each customer in Chicago, seek sales using index
GO

-- =============================================
-- Example 9: Hash Match Join
-- =============================================

-- Large tables, no suitable index
DROP INDEX IF EXISTS IX_Sales_CustomerID ON Sales;
GO

SELECT 
    c.CustomerName,
    COUNT(*) AS OrderCount,
    SUM(s.TotalAmount) AS TotalRevenue
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- Execution plan shows:
-- Hash Match Join (builds hash table)
-- Used when no index available or large datasets
GO

-- Add index back
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
GO

-- =============================================
-- Example 10: Merge Join
-- =============================================

-- Both inputs sorted on join column
SELECT 
    c.CustomerID,
    c.CustomerName,
    s.SaleID,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
ORDER BY c.CustomerID;

-- May show Merge Join (both inputs sorted by CustomerID)
-- Efficient for sorted data
GO

-- =============================================
-- Example 11: Stream Aggregate vs Hash Aggregate
-- =============================================

-- GROUP BY on indexed column (sorted)
SELECT 
    Category,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY Category;

-- If IX_Products_Category exists, may show:
-- Stream Aggregate (data already sorted)
GO

-- GROUP BY on non-indexed column
SELECT 
    LEFT(ProductName, 1) AS FirstLetter,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY LEFT(ProductName, 1);

-- Shows:
-- Hash Aggregate (unsorted data)
GO

-- =============================================
-- Example 12: Parallelism
-- =============================================

-- Large aggregation (may trigger parallelism)
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Sales
GROUP BY CustomerID;

-- Execution plan may show:
-- Parallelism (multiple arrows) - Query runs on multiple CPUs
-- Good for large queries, overhead for small queries
GO

-- Disable parallelism for comparison
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Sales
GROUP BY CustomerID
OPTION (MAXDOP 1);  -- Single CPU

-- No parallelism operators
GO

-- =============================================
-- Example 13: Missing Index Hint
-- =============================================

-- Query that would benefit from index
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Products
WHERE StockQuantity < 20 AND IsActive = 1
ORDER BY StockQuantity;

-- Execution plan shows:
-- Green text: "Missing Index (Impact: XX%)"
-- Right-click to see suggested index
-- Example: CREATE INDEX ... ON Products(IsActive, StockQuantity) INCLUDE (ProductName, Price)
GO

-- =============================================
-- Example 14: Compute Scalar
-- =============================================

-- Calculations in SELECT
SELECT 
    ProductName,
    Price,
    Cost,
    (Price - Cost) AS Profit,
    ((Price - Cost) / Price) * 100 AS ProfitMarginPercent
FROM Products
WHERE Category = 'Electronics';

-- Execution plan shows:
-- Compute Scalar operator (calculates expressions)
-- Usually low cost
GO

-- =============================================
-- Example 15: Comparing Estimated vs Actual
-- =============================================

-- Run with actual execution plan (Ctrl+M)
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- In execution plan, hover over operators:
-- Check: Estimated Rows vs Actual Rows
-- Large difference? Statistics may be outdated
GO

-- Update statistics to improve estimates
UPDATE STATISTICS Customers;
UPDATE STATISTICS Sales;
GO

-- Run query again and compare estimates
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;
-- Estimated rows should be closer to actual
GO

-- =============================================
-- Example 16: Index Spool
-- =============================================

-- Query with multiple lookups on same table
SELECT 
    s1.SaleID,
    s1.TotalAmount,
    (SELECT AVG(TotalAmount) FROM Sales s2 WHERE s2.CustomerID = s1.CustomerID) AS CustomerAvg
FROM Sales s1
WHERE s1.TotalAmount > 100;

-- May show Index Spool or Table Spool
-- Temporary index created for performance
GO

-- =============================================
-- Example 17: Top Operator
-- =============================================

-- TOP N query
SELECT TOP 10
    ProductName,
    Price
FROM Products
ORDER BY Price DESC;

-- Shows Top operator (stops after N rows)
-- Very efficient with proper index
GO

-- =============================================
-- View Execution Plan Metrics
-- =============================================

-- Disable for readability
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Summary of execution plan operators:
/*
✅ GOOD Operators (want to see):
- Index Seek (Nonclustered/Clustered)
- Nested Loops Join (small datasets)
- Stream Aggregate (sorted data)
- Top (with index)

⚠️ CAUTION Operators (acceptable in some cases):
- Index Scan (small tables)
- Hash Match Join (large datasets, no index)
- Merge Join (sorted data)
- Parallelism (large queries)

❌ BAD Operators (try to eliminate):
- Table Scan / Clustered Index Scan (large tables)
- Key Lookup (add covering index)
- RID Lookup (add clustered index)
- Sort (add index matching ORDER BY)
- Filter (make predicate SARGable)
- Hash Aggregate (add index on GROUP BY)
- Implicit conversions (fix data types)
*/

-- =============================================
-- Cleanup
-- =============================================

DROP INDEX IF EXISTS IX_Products_ProductName_Covering ON Products;
DROP INDEX IF EXISTS IX_Products_Category ON Products;
DROP INDEX IF EXISTS IX_Products_Category_Stock ON Products;
GO

-- 💡 Key Takeaways:
-- - Read execution plans right-to-left, top-to-bottom
-- - Index Seek = good, Table Scan = bad (for large tables)
-- - Key Lookup = add covering index with INCLUDE
-- - Sort operator = add index matching ORDER BY
-- - Estimated vs Actual rows = check statistics
-- - Implicit conversions = fix data type mismatches
-- - Green "Missing Index" = consider creating suggested index
-- - Thick arrows = many rows flowing through
-- - High % cost operators = focus optimization here
-- - Enable actual execution plan (Ctrl+M) for real metrics
-- - Use SET STATISTICS IO/TIME for detailed metrics
-- - Compare plans before/after optimization
-- - SARGable predicates use indexes efficiently
-- - Nested Loops = small datasets, Hash Match = large datasets
-- - Parallelism good for large queries, overhead for small
