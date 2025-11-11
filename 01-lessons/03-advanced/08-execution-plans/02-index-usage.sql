-- ========================================
-- Index Usage in Execution Plans
-- Seeks, Scans, Lookups, and Optimization
-- ========================================

USE TechStore;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- =============================================
-- Example 1: Table Scan - No Index
-- =============================================

-- Create demo table without indexes (except PK)
DROP TABLE IF EXISTS ProductsNoIndex;
GO

CREATE TABLE ProductsNoIndex (
    ProductID INT PRIMARY KEY NONCLUSTERED,  -- Heap table
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2),
    StockQuantity INT
);
GO

-- Insert sample data
INSERT INTO ProductsNoIndex (ProductID, ProductName, Category, Price, StockQuantity)
SELECT ProductID, ProductName, Category, Price, StockQuantity
FROM Products;
GO

-- Query on non-indexed column = Table Scan
SELECT ProductName, Price
FROM ProductsNoIndex
WHERE Category = 'Electronics';

-- Execution plan: Table Scan (reads all rows)
-- Logical reads: HIGH
-- Cost: 100% (or close to it)
GO

-- =============================================
-- Example 2: Clustered Index Scan
-- =============================================

-- Query on clustered index without WHERE
SELECT ProductID, ProductName, Category
FROM Products;  -- Has clustered index on ProductID

-- Execution plan: Clustered Index Scan
-- Reads entire clustered index (all rows)
-- Different from Table Scan (heap), but still reads everything
GO

-- With WHERE clause on clustered key = Seek
SELECT ProductID, ProductName, Category
FROM Products
WHERE ProductID = 1;

-- Execution plan: Clustered Index Seek
-- Jumps directly to row (very efficient)
GO

-- =============================================
-- Example 3: Nonclustered Index Seek
-- =============================================

-- Create nonclustered index
CREATE NONCLUSTERED INDEX IX_Products_Category ON Products(Category);
GO

-- Selective query = Index Seek
SELECT ProductID, Category
FROM Products
WHERE Category = 'Electronics';

-- Execution plan: Index Seek on IX_Products_Category
-- Logical reads: Low (only matching rows)
GO

-- Non-selective query = Index Scan
SELECT ProductID, Category
FROM Products
WHERE Category IS NOT NULL;  -- Most/all rows match

-- Execution plan: Index Scan (reads entire index)
-- SQL Server chooses scan because most rows match
GO

-- =============================================
-- Example 4: Key Lookup Demonstration
-- =============================================

-- Query needs columns NOT in index
SELECT ProductName, Category, Price, StockQuantity
FROM Products
WHERE Category = 'Electronics';

-- Execution plan shows:
-- 1. Index Seek (IX_Products_Category) - Find matching rows
-- 2. Key Lookup (Clustered) - Get ProductName, Price, StockQuantity
-- 3. Nested Loops Join - Combine results
-- Key Lookup is expensive! One lookup per row.
GO

-- =============================================
-- Example 5: Eliminate Key Lookup with Covering Index
-- =============================================

-- Drop simple index
DROP INDEX IX_Products_Category ON Products;
GO

-- Create covering index
CREATE NONCLUSTERED INDEX IX_Products_Category_Covering
ON Products(Category)
INCLUDE (ProductName, Price, StockQuantity);
GO

-- Same query, no key lookup
SELECT ProductName, Category, Price, StockQuantity
FROM Products
WHERE Category = 'Electronics';

-- Execution plan: Index Seek ONLY
-- No Key Lookup! All columns in index.
-- Logical reads: Much lower
GO

-- =============================================
-- Example 6: Index Seek with Residual Predicate
-- =============================================

-- Multiple WHERE conditions
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics'  -- Seek Predicate (uses index)
    AND Price > 100;  -- Residual Predicate (filter after seek)

-- Execution plan:
-- Index Seek (Category) + Filter (Price > 100)
-- Better: composite index on both columns
GO

-- Create composite index
CREATE NONCLUSTERED INDEX IX_Products_Category_Price
ON Products(Category, Price)
INCLUDE (ProductName);
GO

-- Same query, both predicates in seek
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' AND Price > 100;

-- Execution plan: Index Seek (both conditions used)
-- No Filter operator
GO

-- =============================================
-- Example 7: Bookmark Lookup (RID Lookup)
-- =============================================

-- RID Lookup occurs on heap tables
-- Query on heap with nonclustered index

SELECT ProductName, Price
FROM ProductsNoIndex
WHERE ProductName = 'Laptop';

-- Without index: Table Scan
GO

-- Create nonclustered index on heap
CREATE NONCLUSTERED INDEX IX_ProductsNoIndex_ProductName 
ON ProductsNoIndex(ProductName);
GO

SELECT ProductName, Price
FROM ProductsNoIndex
WHERE ProductName = 'Laptop';

-- Execution plan:
-- Index Seek + RID Lookup (goes to heap for Price)
-- RID Lookup is worse than Key Lookup
GO

-- Fix: Add clustered index or covering index
CREATE CLUSTERED INDEX IX_ProductsNoIndex_ProductID 
ON ProductsNoIndex(ProductID);
GO

-- Now RID Lookup becomes Key Lookup (better)
GO

-- =============================================
-- Example 8: Index Intersection
-- =============================================

-- Create two separate indexes
DROP INDEX IF EXISTS IX_Products_Category_Covering ON Products;
DROP INDEX IF EXISTS IX_Products_Category_Price ON Products;
GO

CREATE NONCLUSTERED INDEX IX_Products_Category2 ON Products(Category);
CREATE NONCLUSTERED INDEX IX_Products_Price2 ON Products(Price);
GO

-- Query using both indexed columns
SELECT ProductID, Category, Price
FROM Products
WHERE Category = 'Electronics' AND Price > 100;

-- SQL Server may use:
-- Option 1: One index + filter
-- Option 2: Index Intersection (use both indexes, combine results)
-- Check actual execution plan
GO

-- Single composite index is usually better
CREATE NONCLUSTERED INDEX IX_Products_Category_Price2 
ON Products(Category, Price);
GO

SELECT ProductID, Category, Price
FROM Products
WHERE Category = 'Electronics' AND Price > 100;

-- Single index seek (more efficient than intersection)
GO

-- =============================================
-- Example 9: Missing Index Recommendation
-- =============================================

-- Query without optimal index
DROP INDEX IF EXISTS IX_Products_Category2 ON Products;
DROP INDEX IF EXISTS IX_Products_Price2 ON Products;
DROP INDEX IF EXISTS IX_Products_Category_Price2 ON Products;
GO

SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Products
WHERE IsActive = 1 
    AND StockQuantity < 20
ORDER BY Price;

-- Execution plan shows green text:
-- "Missing Index (Impact: XX%)"
-- Right-click the plan, select "Missing Index Details"

-- Example suggestion:
/*
CREATE NONCLUSTERED INDEX IX_Products_Missing
ON Products(IsActive, StockQuantity)
INCLUDE (ProductName, Price);
*/
GO

-- =============================================
-- Example 10: SARGable vs Non-SARGable
-- =============================================

-- SARGable (Search ARGument ABLE) - Can use index
SELECT ProductName, Price
FROM Products
WHERE Price > 100;  -- Simple comparison
-- Index Seek possible
GO

-- Non-SARGable - Cannot use index efficiently
SELECT ProductName, Price
FROM Products
WHERE Price * 1.1 > 110;  -- Function on indexed column
-- Index Scan (must evaluate function for every row)
GO

-- Rewrite as SARGable
SELECT ProductName, Price
FROM Products
WHERE Price > 110 / 1.1;  -- Calculation on constant, not column
-- Index Seek possible
GO

-- =============================================
-- Example 11: Index Selectivity Impact
-- =============================================

-- High selectivity (few rows) = Seek
SELECT ProductName, Price
FROM Products
WHERE ProductID = 5;  -- Only 1 row
-- Clustered Index Seek
GO

-- Low selectivity (many rows) = Scan
CREATE NONCLUSTERED INDEX IX_Products_IsActive ON Products(IsActive);
GO

SELECT ProductName, Price
FROM Products
WHERE IsActive = 1;  -- Most products active
-- May choose Clustered Index Scan instead of nonclustered index
-- SQL Server decides scan is cheaper than seek + lookups
GO

-- =============================================
-- Example 12: Covering Index Performance
-- =============================================

-- Test 1: Non-covering index
DROP INDEX IF EXISTS IX_Products_IsActive ON Products;
GO

CREATE NONCLUSTERED INDEX IX_Products_Category_Simple 
ON Products(Category);
GO

DECLARE @StartTime DATETIME = GETDATE();

SELECT ProductName, Category, Price, Cost, StockQuantity
FROM Products
WHERE Category = 'Electronics';

PRINT 'Time with key lookups: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + 'ms';
-- Index Seek + Key Lookup
GO

-- Test 2: Covering index
CREATE NONCLUSTERED INDEX IX_Products_Category_Covering2
ON Products(Category)
INCLUDE (ProductName, Price, Cost, StockQuantity);
GO

DECLARE @StartTime DATETIME = GETDATE();

SELECT ProductName, Category, Price, Cost, StockQuantity
FROM Products
WHERE Category = 'Electronics';

PRINT 'Time with covering index: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS VARCHAR(10)) + 'ms';
-- Index Seek only (faster)
GO

-- =============================================
-- Example 13: Index Usage with JOIN
-- =============================================

-- Foreign key without index
DROP INDEX IF EXISTS IX_Sales_CustomerID ON Sales;
GO

SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- Execution plan: Hash Match Join (no index on foreign key)
-- or Nested Loops with Table Scan
GO

-- Add index on foreign key
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID2 ON Sales(CustomerID);
GO

SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- Execution plan: Nested Loops Join with Index Seek
-- Much faster
GO

-- =============================================
-- Example 14: Filtered Index Usage
-- =============================================

-- Filtered index for active products only
CREATE NONCLUSTERED INDEX IX_Products_Active_Category
ON Products(Category)
INCLUDE (ProductName, Price)
WHERE IsActive = 1;
GO

-- Query matching filter
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' AND IsActive = 1;
-- Uses filtered index (smaller, faster)
GO

-- Query NOT matching filter
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' AND IsActive = 0;
-- Cannot use filtered index (uses different index or scan)
GO

-- =============================================
-- Example 15: Index Seek vs Scan Decision
-- =============================================

-- Query with different selectivity
-- Seek: Very selective
SELECT ProductName, Price
FROM Products
WHERE ProductID = 1;
-- Clustered Index Seek (1 row)
GO

-- Scan: Not selective
SELECT ProductName, Price
FROM Products
WHERE ProductID > 0;  -- All rows
-- Clustered Index Scan (reads all rows)
GO

-- Tipping point: SQL Server chooses based on statistics
-- Usually around 5-20% of rows (depends on data)
SELECT ProductName, Price
FROM Products
WHERE ProductID BETWEEN 1 AND 10;
-- May be Seek or Scan depending on table size
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- =============================================
-- Cleanup
-- =============================================

DROP TABLE IF EXISTS ProductsNoIndex;
DROP INDEX IF EXISTS IX_Products_Category_Simple ON Products;
DROP INDEX IF EXISTS IX_Products_Category_Covering2 ON Products;
DROP INDEX IF EXISTS IX_Sales_CustomerID2 ON Sales;
DROP INDEX IF EXISTS IX_Products_Active_Category ON Products;
GO

-- Restore standard indexes
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
GO

-- 💡 Key Takeaways:
-- - Table Scan = reads entire table (worst case for large tables)
-- - Clustered Index Scan = reads entire clustered index (still expensive)
-- - Index Seek = jumps to specific rows (best case)
-- - Index Scan = reads entire nonclustered index
-- - Key Lookup = goes to clustered index for missing columns (expensive)
-- - RID Lookup = heap equivalent of key lookup (even worse)
-- - Covering index eliminates key lookups (INCLUDE columns)
-- - Composite index better than index intersection
-- - Foreign keys should always be indexed
-- - SARGable predicates allow index usage (no functions on columns)
-- - Selectivity affects seek vs scan choice
-- - Missing index hints are suggestions (test before implementing)
-- - Filtered indexes for common subsets
-- - Check execution plan after creating indexes
-- - Compare logical reads before/after optimization
-- - Thick arrows in plan = many rows (potential bottleneck)
