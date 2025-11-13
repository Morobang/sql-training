-- ========================================
-- Nonclustered Indexes
-- Separate Index Structures
-- ========================================

USE TechStore;
GO

-- =============================================
-- Understanding Nonclustered Indexes
-- =============================================

-- View all nonclustered indexes on Customers table
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') AS IndexedColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Customers')
    AND i.type_desc = 'NONCLUSTERED'
GROUP BY i.name, i.type_desc, i.is_unique
ORDER BY i.name;
GO

-- =============================================
-- Example 1: Basic Nonclustered Index
-- =============================================

-- Create index on frequently searched column
CREATE NONCLUSTERED INDEX IX_Customers_City ON Customers(City);
GO

-- Test index usage
SET STATISTICS IO ON;

-- Query uses nonclustered index
SELECT CustomerID, CustomerName, City
FROM Customers
WHERE City = 'Chicago';

SET STATISTICS IO OFF;
-- Check execution plan: Index Seek on IX_Customers_City + Key Lookup
GO

-- =============================================
-- Example 2: Composite Nonclustered Index
-- =============================================

-- Create multi-column index (column order matters!)
CREATE NONCLUSTERED INDEX IX_Customers_CityState ON Customers(City, State);
GO

-- Query patterns and index usage:

-- ✅ Uses index: Filters on City (leading column)
SELECT CustomerID, CustomerName
FROM Customers
WHERE City = 'Chicago';

-- ✅ Uses index: Filters on City and State (both columns)
SELECT CustomerID, CustomerName
FROM Customers
WHERE City = 'Chicago' AND State = 'IL';

-- ❌ Table scan: Filters only on State (non-leading column)
SELECT CustomerID, CustomerName
FROM Customers
WHERE State = 'IL';
-- Index can't be used efficiently because State is not the leading column
GO

-- =============================================
-- Example 3: Index on Foreign Key
-- =============================================

-- Foreign keys should almost always be indexed
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
CREATE NONCLUSTERED INDEX IX_Sales_ProductID ON Sales(ProductID);
GO

-- Test join performance
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Efficient join using foreign key indexes
SELECT 
    c.CustomerName,
    p.ProductName,
    s.Quantity,
    s.TotalAmount,
    s.SaleDate
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE c.City = 'Chicago'
    AND s.SaleDate >= '2024-01-01';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- =============================================
-- Example 4: Unique Nonclustered Index
-- =============================================

-- Ensure email addresses are unique
CREATE UNIQUE NONCLUSTERED INDEX IX_Customers_Email_Unique ON Customers(CustomerName);
-- Note: Using CustomerName as proxy for Email (Email column doesn't exist in demo)
GO

-- Test uniqueness enforcement
BEGIN TRY
    -- Insert duplicate should fail
    INSERT INTO Customers (CustomerName, City, State, JoinDate, TotalPurchases)
    VALUES ('John Smith', 'Boston', 'MA', GETDATE(), 0);
    
    -- Duplicate insert (should fail)
    INSERT INTO Customers (CustomerName, City, State, JoinDate, TotalPurchases)
    VALUES ('John Smith', 'Seattle', 'WA', GETDATE(), 0);
END TRY
BEGIN CATCH
    PRINT 'Uniqueness violation: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Drop unique index for next examples
DROP INDEX IX_Customers_Email_Unique ON Customers;
GO

-- =============================================
-- Example 5: Index with Included Columns
-- =============================================

-- Create covering index for specific query
-- Query: SELECT ProductName, Price FROM Products WHERE Category = 'Electronics'

CREATE NONCLUSTERED INDEX IX_Products_Category_Covering
ON Products(Category)
INCLUDE (ProductName, Price);
GO

SET STATISTICS IO ON;

-- This query is "covered" by the index (no key lookup needed)
SELECT ProductName, Price
FROM Products
WHERE Category = 'Electronics';

SET STATISTICS IO OFF;
-- Check plan: Index Seek, NO key lookup (all data in index)
GO

-- Compare with non-covered query
SET STATISTICS IO ON;

-- This needs columns not in index (requires key lookup)
SELECT ProductName, Price, Cost, StockQuantity  -- Cost and StockQuantity not in index
FROM Products
WHERE Category = 'Electronics';

SET STATISTICS IO OFF;
-- Check plan: Index Seek + Key Lookup (to get Cost and StockQuantity)
GO

-- =============================================
-- Example 6: Filtered Nonclustered Index
-- =============================================

-- Create index only for active products
CREATE NONCLUSTERED INDEX IX_Products_Active_CategoryPrice
ON Products(Category, Price)
WHERE IsActive = 1;  -- Only index active products
GO

-- Index is used when query matches filter
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' 
    AND IsActive = 1  -- Matches index filter
ORDER BY Price;
-- Uses filtered index (smaller, faster)
GO

-- Index NOT used when filter doesn't match
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' 
    AND IsActive = 0;  -- Doesn't match index filter
-- Uses different index or table scan
GO

-- =============================================
-- Example 7: Index for Sorting (ORDER BY)
-- =============================================

-- Create index to eliminate sort operations
CREATE NONCLUSTERED INDEX IX_Sales_SaleDate_Desc ON Sales(SaleDate DESC);
GO

SET STATISTICS IO ON;

-- Query with ORDER BY uses index (no sort operation needed)
SELECT SaleID, CustomerID, TotalAmount, SaleDate
FROM Sales
WHERE SaleDate >= '2024-01-01'
ORDER BY SaleDate DESC;

SET STATISTICS IO OFF;
-- Check plan: Index Seek, no Sort operator (data already in order)
GO

-- =============================================
-- Example 8: Multiple Indexes on Same Table
-- =============================================

-- Drop existing indexes first
DROP INDEX IF EXISTS IX_Products_Category_Covering ON Products;
DROP INDEX IF EXISTS IX_Products_Active_CategoryPrice ON Products;
GO

-- Create multiple indexes for different query patterns
CREATE NONCLUSTERED INDEX IX_Products_Category ON Products(Category);
CREATE NONCLUSTERED INDEX IX_Products_Price ON Products(Price);
CREATE NONCLUSTERED INDEX IX_Products_StockQuantity ON Products(StockQuantity);
GO

-- Query 1: Uses IX_Products_Category
SELECT * FROM Products WHERE Category = 'Electronics';

-- Query 2: Uses IX_Products_Price
SELECT * FROM Products WHERE Price > 100;

-- Query 3: Uses IX_Products_StockQuantity
SELECT * FROM Products WHERE StockQuantity < 10;

-- Query 4: May use index intersection (combines multiple indexes)
SELECT * FROM Products 
WHERE Category = 'Electronics' 
    AND Price > 100;
GO

-- =============================================
-- Example 9: Index Usage Statistics
-- =============================================

-- View index usage for Products table
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks AS Seeks,
    s.user_scans AS Scans,
    s.user_lookups AS Lookups,
    s.user_updates AS Updates,
    s.last_user_seek AS LastSeek,
    s.last_user_scan AS LastScan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECT_NAME(s.object_id) = 'Products'
    AND i.type_desc = 'NONCLUSTERED'
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;
GO

-- =============================================
-- Example 10: Find Missing Indexes
-- =============================================

-- SQL Server tracks potential missing indexes
SELECT TOP 10
    OBJECT_NAME(mid.object_id) AS TableName,
    mid.equality_columns AS EqualityColumns,
    mid.inequality_columns AS InequalityColumns,
    mid.included_columns AS IncludedColumns,
    migs.avg_user_impact AS AvgImpact,
    migs.user_seeks AS Seeks,
    migs.avg_total_user_cost AS AvgCost,
    'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(mid.object_id) + '_Suggested ON ' + 
    mid.statement + ' (' + ISNULL(mid.equality_columns, '') + 
    CASE WHEN mid.inequality_columns IS NOT NULL THEN ', ' + mid.inequality_columns ELSE '' END + ')' +
    CASE WHEN mid.included_columns IS NOT NULL THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END AS CreateStatement
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact DESC;
GO

-- =============================================
-- Example 11: Unused Indexes
-- =============================================

-- Find indexes that are never used
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ISNULL(s.user_seeks, 0) AS Seeks,
    ISNULL(s.user_scans, 0) AS Scans,
    ISNULL(s.user_lookups, 0) AS Lookups,
    ISNULL(s.user_updates, 0) AS Updates,
    'DROP INDEX ' + i.name + ' ON ' + OBJECT_NAME(i.object_id) AS DropStatement
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON i.object_id = s.object_id 
    AND i.index_id = s.index_id 
    AND s.database_id = DB_ID()
WHERE i.object_id = OBJECT_ID('Products')
    AND i.type_desc = 'NONCLUSTERED'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
    AND ISNULL(s.user_seeks, 0) = 0
    AND ISNULL(s.user_scans, 0) = 0
ORDER BY ISNULL(s.user_updates, 0) DESC;
-- High updates but no seeks/scans = index causing overhead without benefit
GO

-- =============================================
-- Example 12: Index Size and Row Count
-- =============================================

-- View index sizes
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    SUM(ps.used_page_count) * 8 / 1024.0 AS SizeMB,
    SUM(ps.row_count) AS RowCnt
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Products', 'Customers', 'Sales')
    AND i.type_desc = 'NONCLUSTERED'
GROUP BY OBJECT_NAME(i.object_id), i.name, i.type_desc
ORDER BY SizeMB DESC;
GO

-- =============================================
-- Example 13: Disable and Enable Indexes
-- =============================================

-- Disable index (useful during bulk loading)
ALTER INDEX IX_Products_Category ON Products DISABLE;
GO

-- Try to use disabled index (will not be used)
SELECT * FROM Products WHERE Category = 'Electronics';
-- Uses table scan or different index
GO

-- Re-enable index
ALTER INDEX IX_Products_Category ON Products REBUILD;
GO

-- =============================================
-- Example 14: Drop Indexes
-- =============================================

-- Drop indexes created in this demo
DROP INDEX IF EXISTS IX_Customers_City ON Customers;
DROP INDEX IF EXISTS IX_Customers_CityState ON Customers;
DROP INDEX IF EXISTS IX_Sales_CustomerID ON Sales;
DROP INDEX IF EXISTS IX_Sales_ProductID ON Sales;
DROP INDEX IF EXISTS IX_Products_Category ON Products;
DROP INDEX IF EXISTS IX_Products_Price ON Products;
DROP INDEX IF EXISTS IX_Products_StockQuantity ON Products;
DROP INDEX IF EXISTS IX_Sales_SaleDate_Desc ON Sales;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
-- Remove all nonclustered indexes created in this session
-- Be careful with this in production!
*/

-- 💡 Key Takeaways:
-- - Nonclustered indexes are separate structures from table data
-- - Can have up to 999 nonclustered indexes per table
-- - Index + Include columns = covering index (eliminates key lookups)
-- - Filtered indexes reduce size and maintenance for common subsets
-- - Foreign keys should almost always be indexed
-- - Column order matters in composite indexes (left-prefix rule)
-- - Monitor index usage with sys.dm_db_index_usage_stats
-- - Check for missing indexes with missing index DMVs
-- - Remove unused indexes (high updates, zero seeks/scans)
-- - Each index has overhead on INSERT/UPDATE/DELETE
-- - Balance read performance vs write overhead
-- - Use INCLUDE for frequently selected non-filtered columns
-- - Unique indexes enforce data integrity
-- - ORDER BY performance improved by matching index order
