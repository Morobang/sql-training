-- ========================================
-- Covering Indexes and Key Lookups
-- Eliminating Expensive Lookups
-- ========================================

USE TechStore;
GO

-- =============================================
-- Understanding Covering Indexes
-- =============================================

/*
A covering index contains ALL columns needed by a query.
This eliminates the need for "key lookups" to the clustered index.

Key Lookup = expensive operation where SQL Server must:
1. Find row in nonclustered index
2. Use row locator to jump to clustered index
3. Retrieve additional columns not in nonclustered index
4. Combine results

Covering Index = all data in the index, no lookup needed!
*/

-- =============================================
-- Example 1: Query WITHOUT Covering Index
-- =============================================

-- Create simple nonclustered index
CREATE NONCLUSTERED INDEX IX_Products_Category ON Products(Category);
GO

-- Enable execution plan and IO statistics
SET STATISTICS IO ON;
SET SHOWPLAN_TEXT OFF;  -- Use graphical plan in SSMS

-- Query needs columns not in index
SELECT ProductID, ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics';

SET STATISTICS IO OFF;

-- Check execution plan:
-- 1. Index Seek on IX_Products_Category (finds matching rows)
-- 2. Key Lookup (Clustered) to get ProductName and Price
-- 3. Nested Loop Join to combine results
-- Result: 2 operations instead of 1
GO

-- =============================================
-- Example 2: CREATE Covering Index
-- =============================================

-- Drop simple index
DROP INDEX IX_Products_Category ON Products;
GO

-- Create covering index with INCLUDE
CREATE NONCLUSTERED INDEX IX_Products_Category_Covering
ON Products(Category)
INCLUDE (ProductName, Price);
GO

SET STATISTICS IO ON;

-- Same query now uses covering index only
SELECT ProductID, ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics';

SET STATISTICS IO OFF;

-- Check execution plan:
-- 1. Index Seek on IX_Products_Category_Covering
-- That's it! No key lookup needed.
-- ProductID comes from clustered key included in every nonclustered index
GO

-- =============================================
-- Example 3: INCLUDE vs Key Columns
-- =============================================

-- Two approaches to cover the same query:

-- Approach 1: All columns as key columns (BAD)
CREATE NONCLUSTERED INDEX IX_Products_AllKeys
ON Products(Category, ProductName, Price);
GO

-- Approach 2: Filter columns as keys, select columns as INCLUDE (GOOD)
CREATE NONCLUSTERED INDEX IX_Products_Covering
ON Products(Category)
INCLUDE (ProductName, Price);
GO

-- Why Approach 2 is better:
-- - Smaller index size (non-key columns only at leaf level)
-- - Faster index traversal (smaller B-tree)
-- - Same query coverage
-- - ProductName and Price don't need to be sorted/unique

SELECT 
    i.name AS IndexName,
    SUM(ps.used_page_count) * 8 / 1024.0 AS SizeMB
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Products')
    AND i.name IN ('IX_Products_AllKeys', 'IX_Products_Covering')
GROUP BY i.name;
-- IX_Products_Covering is typically smaller
GO

-- Cleanup
DROP INDEX IX_Products_AllKeys ON Products;
DROP INDEX IX_Products_Covering ON Products;
GO

-- =============================================
-- Example 4: Multiple Covering Indexes
-- =============================================

-- Different queries need different covering indexes

-- Query 1: Category + basic info
CREATE NONCLUSTERED INDEX IX_Products_Category_Basic
ON Products(Category)
INCLUDE (ProductName, Price);
GO

-- Query 2: Price range + details
CREATE NONCLUSTERED INDEX IX_Products_Price_Details
ON Products(Price)
INCLUDE (ProductName, Category, StockQuantity);
GO

-- Query 3: Stock alerts
CREATE NONCLUSTERED INDEX IX_Products_Stock_Info
ON Products(StockQuantity)
INCLUDE (ProductName, Category, Price)
WHERE IsActive = 1;  -- Filtered for active products only
GO

-- Test each covering index
SET STATISTICS IO ON;

-- Uses IX_Products_Category_Basic
SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics';
PRINT '--- Query 1 Complete ---';

-- Uses IX_Products_Price_Details
SELECT ProductName, Category, Price, StockQuantity
FROM Products
WHERE Price BETWEEN 50 AND 200
ORDER BY Price;
PRINT '--- Query 2 Complete ---';

-- Uses IX_Products_Stock_Info
SELECT ProductName, Category, Price, StockQuantity
FROM Products
WHERE StockQuantity < 20 AND IsActive = 1
ORDER BY StockQuantity;
PRINT '--- Query 3 Complete ---';

SET STATISTICS IO OFF;
GO

-- =============================================
-- Example 5: Covering Index for JOIN
-- =============================================

-- Create covering indexes for common join query
CREATE NONCLUSTERED INDEX IX_Sales_CustomerProduct
ON Sales(CustomerID, ProductID)
INCLUDE (Quantity, TotalAmount, SaleDate);
GO

CREATE NONCLUSTERED INDEX IX_Customers_ID
ON Customers(CustomerID)
INCLUDE (CustomerName, City);
GO

CREATE NONCLUSTERED INDEX IX_Products_ID
ON Products(ProductID)
INCLUDE (ProductName, Price);
GO

SET STATISTICS IO ON;

-- Efficient join with all covering indexes
SELECT 
    c.CustomerName,
    c.City,
    p.ProductName,
    s.Quantity,
    s.TotalAmount,
    s.SaleDate
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.SaleDate >= '2024-01-01'
ORDER BY s.SaleDate DESC;

SET STATISTICS IO OFF;
-- All data retrieved from indexes, no key lookups!
GO

-- =============================================
-- Example 6: Covering Index for Aggregation
-- =============================================

-- Create covering index for sales summary query
CREATE NONCLUSTERED INDEX IX_Sales_Summary
ON Sales(CustomerID)
INCLUDE (TotalAmount, SaleDate);
GO

SET STATISTICS IO ON;

-- Aggregation query covered by index
SELECT 
    CustomerID,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue,
    MAX(SaleDate) AS LastPurchaseDate
FROM Sales
WHERE SaleDate >= '2024-01-01'
GROUP BY CustomerID
HAVING COUNT(*) > 1;

SET STATISTICS IO OFF;
-- Data comes entirely from covering index
GO

-- =============================================
-- Example 7: Covering Index with ORDER BY
-- =============================================

-- Create covering index matching ORDER BY
CREATE NONCLUSTERED INDEX IX_Sales_DateDesc_Covering
ON Sales(SaleDate DESC)
INCLUDE (CustomerID, ProductID, Quantity, TotalAmount);
GO

SET STATISTICS IO ON;

-- Query with ORDER BY uses index order (no sort needed)
SELECT TOP 100
    SaleDate,
    CustomerID,
    ProductID,
    Quantity,
    TotalAmount
FROM Sales
WHERE SaleDate >= '2024-01-01'
ORDER BY SaleDate DESC;

SET STATISTICS IO OFF;
-- Index Seek, no Sort operation, no key lookup
GO

-- =============================================
-- Example 8: Too Many Included Columns
-- =============================================

-- Example of over-including (not recommended)
CREATE NONCLUSTERED INDEX IX_Products_OverIncluded
ON Products(Category)
INCLUDE (ProductName, Price, Cost, StockQuantity, SupplierID, IsActive);
-- Every column except Category! Index is now very wide.
GO

-- Check index size
SELECT 
    i.name AS IndexName,
    SUM(ps.used_page_count) * 8 / 1024.0 AS SizeMB,
    COUNT(ic.column_id) AS ColumnCount
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Products')
    AND i.name = 'IX_Products_OverIncluded'
GROUP BY i.name;
GO

DROP INDEX IX_Products_OverIncluded ON Products;
GO

-- Better approach: Create targeted covering indexes for specific queries
-- Don't try to cover every possible query with one massive index

-- =============================================
-- Example 9: Identify Key Lookups in Execution Plan
-- =============================================

-- Create index WITHOUT covering columns
DROP INDEX IF EXISTS IX_Products_Category_Covering ON Products;
GO

CREATE NONCLUSTERED INDEX IX_Products_Category_Simple ON Products(Category);
GO

-- Query that causes key lookups
SELECT ProductName, Category, Price, Cost, StockQuantity
FROM Products
WHERE Category = 'Electronics';
-- Look for "Key Lookup (Clustered)" in execution plan
-- This is the expensive operation we want to eliminate
GO

-- Add covering index
CREATE NONCLUSTERED INDEX IX_Products_Category_FullCover
ON Products(Category)
INCLUDE (ProductName, Price, Cost, StockQuantity);
GO

-- Same query, no key lookup
SELECT ProductName, Category, Price, Cost, StockQuantity
FROM Products
WHERE Category = 'Electronics';
-- Key Lookup is gone!
GO

-- =============================================
-- Example 10: Covering Index Trade-offs
-- =============================================

/*
Covering Index Benefits:
✅ Faster queries (no key lookup)
✅ Reduced I/O (fewer page reads)
✅ Better concurrency (less locking)

Covering Index Costs:
❌ Larger index size (more columns stored)
❌ Slower writes (more data to update)
❌ More disk space
❌ Longer rebuild/reorg times

Decision Matrix:
- Frequently executed query? → Consider covering
- High-value report/dashboard? → Consider covering
- Rarely executed query? → Don't cover
- Very wide result set (10+ columns)? → Don't cover
- Columns frequently updated? → Be cautious
*/

-- Compare index sizes
SELECT 
    i.name AS IndexName,
    i.type_desc,
    SUM(ps.used_page_count) * 8 / 1024.0 AS SizeMB,
    (SELECT COUNT(*) FROM sys.index_columns ic 
     WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id) AS ColumnCount
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Products')
    AND i.type_desc = 'NONCLUSTERED'
GROUP BY i.name, i.type_desc, i.object_id, i.index_id
ORDER BY SizeMB DESC;
GO

-- =============================================
-- Example 11: Missing Index Suggestions
-- =============================================

-- SQL Server tracks missing covering indexes
-- Run some queries first
SELECT ProductName, Price FROM Products WHERE Category = 'Books';
SELECT CustomerName, City FROM Customers WHERE State = 'CA';
SELECT TotalAmount, SaleDate FROM Sales WHERE CustomerID = 1;
GO

-- View missing index recommendations (includes suggested INCLUDE columns)
SELECT TOP 5
    OBJECT_NAME(mid.object_id) AS TableName,
    mid.equality_columns AS KeyColumns,
    mid.included_columns AS IncludeColumns,
    migs.avg_user_impact AS ExpectedImprovement,
    migs.user_seeks AS Seeks,
    'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(mid.object_id) + '_Suggested' +
    CAST(migs.group_handle AS VARCHAR(20)) +
    ' ON ' + mid.statement + 
    ' (' + ISNULL(mid.equality_columns, '') + ')' +
    CASE WHEN mid.included_columns IS NOT NULL 
         THEN ' INCLUDE (' + mid.included_columns + ')' 
         ELSE '' 
    END AS CreateIndexStatement
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact DESC;
GO

-- =============================================
-- Cleanup
-- =============================================

DROP INDEX IF EXISTS IX_Products_Category_Covering ON Products;
DROP INDEX IF EXISTS IX_Products_Category_Basic ON Products;
DROP INDEX IF EXISTS IX_Products_Price_Details ON Products;
DROP INDEX IF EXISTS IX_Products_Stock_Info ON Products;
DROP INDEX IF EXISTS IX_Sales_CustomerProduct ON Sales;
DROP INDEX IF EXISTS IX_Customers_ID ON Customers;
DROP INDEX IF EXISTS IX_Products_ID ON Products;
DROP INDEX IF EXISTS IX_Sales_Summary ON Sales;
DROP INDEX IF EXISTS IX_Sales_DateDesc_Covering ON Sales;
DROP INDEX IF EXISTS IX_Products_Category_Simple ON Products;
DROP INDEX IF EXISTS IX_Products_Category_FullCover ON Products;
GO

-- 💡 Key Takeaways:
-- - Covering index eliminates expensive key lookups
-- - INCLUDE clause adds columns at leaf level only (smaller index)
-- - Use key columns for WHERE/JOIN, INCLUDE for SELECT
-- - One query may need multiple covering indexes
-- - Don't over-include (balance coverage vs size)
-- - Check execution plans for "Key Lookup (Clustered)"
-- - Missing index DMVs suggest INCLUDE columns
-- - Covering indexes = faster reads, slower writes
-- - Target your most frequent/expensive queries
-- - Monitor index usage and size
-- - Test performance before and after
-- - Consider filtered covering indexes for common subsets
-- - Each covering index has maintenance overhead
-- - Not every query needs a covering index
-- - Start with high-value queries (dashboards, reports)
