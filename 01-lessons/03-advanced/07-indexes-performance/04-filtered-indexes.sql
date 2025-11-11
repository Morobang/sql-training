-- ========================================
-- Filtered Indexes
-- Indexing Subsets of Data
-- ========================================

USE TechStore;
GO

-- =============================================
-- Understanding Filtered Indexes
-- =============================================

/*
Filtered Index = Index with a WHERE clause
Benefits:
✅ Smaller index size (only indexes subset of rows)
✅ Lower maintenance cost (fewer rows to update)
✅ More accurate statistics
✅ Improved query performance for common filters

Best For:
- Columns with skewed distribution (few common values)
- Queries with consistent WHERE clauses
- Active/Inactive flags
- Status codes
- NULL/NOT NULL filtering
*/

-- =============================================
-- Example 1: Basic Filtered Index
-- =============================================

-- Regular index (indexes ALL products)
CREATE NONCLUSTERED INDEX IX_Products_Category_All
ON Products(Category, Price);
GO

-- Filtered index (indexes only active products)
CREATE NONCLUSTERED INDEX IX_Products_Category_ActiveOnly
ON Products(Category, Price)
WHERE IsActive = 1;
GO

-- Compare index sizes
SELECT 
    i.name AS IndexName,
    SUM(ps.used_page_count) * 8 / 1024.0 AS SizeMB,
    SUM(ps.row_count) AS RowCnt
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Products')
    AND i.name IN ('IX_Products_Category_All', 'IX_Products_Category_ActiveOnly')
GROUP BY i.name;
-- Filtered index is smaller!
GO

-- Query matching filter uses filtered index
SET STATISTICS IO ON;

SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' AND IsActive = 1;
-- Uses IX_Products_Category_ActiveOnly (smaller, faster)

SET STATISTICS IO OFF;
GO

-- Query NOT matching filter uses regular index
SET STATISTICS IO ON;

SELECT ProductName, Category, Price
FROM Products
WHERE Category = 'Electronics' AND IsActive = 0;
-- Uses IX_Products_Category_All or table scan

SET STATISTICS IO OFF;
GO

-- =============================================
-- Example 2: Filtered Index on NULL Values
-- =============================================

-- Add nullable column for testing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'DiscontinuedDate')
BEGIN
    ALTER TABLE Products ADD DiscontinuedDate DATE NULL;
END;
GO

-- Index only current products (DiscontinuedDate IS NULL)
CREATE NONCLUSTERED INDEX IX_Products_Current
ON Products(Category, ProductName)
WHERE DiscontinuedDate IS NULL;
GO

-- Query for current products uses filtered index
SELECT ProductName, Category
FROM Products
WHERE Category = 'Electronics' AND DiscontinuedDate IS NULL;
-- Efficient: small index covering only current products
GO

-- Index only discontinued products
CREATE NONCLUSTERED INDEX IX_Products_Discontinued
ON Products(DiscontinuedDate)
INCLUDE (ProductName, Category)
WHERE DiscontinuedDate IS NOT NULL;
GO

-- Historical query uses discontinued index
SELECT ProductName, Category, DiscontinuedDate
FROM Products
WHERE DiscontinuedDate BETWEEN '2023-01-01' AND '2023-12-31';
GO

-- =============================================
-- Example 3: Filtered Index on Low Selectivity Column
-- =============================================

-- Example: Most sales are 'Complete', few are 'Pending' or 'Cancelled'
-- Add Status column for demo
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Sales') AND name = 'Status')
BEGIN
    ALTER TABLE Sales ADD Status VARCHAR(20) DEFAULT 'Complete';
    UPDATE Sales SET Status = 'Complete';
    
    -- Mark a few as pending (simulate real data)
    UPDATE TOP (5) Sales SET Status = 'Pending';
END;
GO

-- Don't index Status directly (low selectivity for 'Complete')
-- Instead, create filtered index for minority cases

-- Index pending sales only
CREATE NONCLUSTERED INDEX IX_Sales_Pending
ON Sales(SaleDate, CustomerID)
INCLUDE (ProductID, TotalAmount)
WHERE Status = 'Pending';
GO

-- Efficient query for pending sales
SELECT SaleDate, CustomerID, ProductID, TotalAmount
FROM Sales
WHERE Status = 'Pending'
ORDER BY SaleDate;
-- Small index (only pending rows)
GO

-- =============================================
-- Example 4: Filtered Index with Multiple Conditions
-- =============================================

-- Complex filter: Active electronics under $500
CREATE NONCLUSTERED INDEX IX_Products_AffordableElectronics
ON Products(Price)
INCLUDE (ProductName, StockQuantity)
WHERE Category = 'Electronics' AND IsActive = 1 AND Price < 500;
GO

-- Query matching all filter conditions
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE Category = 'Electronics' 
    AND IsActive = 1 
    AND Price < 500
    AND Price > 100
ORDER BY Price;
-- Uses filtered index
GO

-- =============================================
-- Example 5: Filtered Index for Date Ranges
-- =============================================

-- Index only recent sales (last 90 days)
-- This is for demo - in production, use a variable date or partition
CREATE NONCLUSTERED INDEX IX_Sales_Recent
ON Sales(SaleDate DESC)
INCLUDE (CustomerID, ProductID, TotalAmount)
WHERE SaleDate >= '2024-01-01';  -- Adjust date for your data
GO

-- Recent sales query
SELECT SaleDate, CustomerID, ProductID, TotalAmount
FROM Sales
WHERE SaleDate >= '2024-01-01'
ORDER BY SaleDate DESC;
-- Fast access to recent sales
GO

-- =============================================
-- Example 6: Filtered Index vs Indexed View
-- =============================================

-- Scenario: Frequently query active products with stock > 0

-- Option 1: Filtered Index
CREATE NONCLUSTERED INDEX IX_Products_InStock
ON Products(Category, Price)
INCLUDE (ProductName)
WHERE IsActive = 1 AND StockQuantity > 0;
GO

-- Option 2: Indexed View (more restrictive, see Views lesson)
-- Not shown here, but filtered indexes are often simpler

-- Test filtered index performance
SET STATISTICS IO ON;

SELECT ProductName, Category, Price
FROM Products
WHERE IsActive = 1 AND StockQuantity > 0 AND Category = 'Electronics';

SET STATISTICS IO OFF;
GO

-- =============================================
-- Example 7: Filtered Index Limitations
-- =============================================

/*
Filtered Index Restrictions:
❌ Cannot use:
   - Computed columns
   - Subqueries
   - Comparison operators between columns
   - Complex expressions
   - OR conditions (use UNION or separate indexes)

✅ Can use:
   - Simple comparison operators (=, <, >, <=, >=, <>)
   - AND (not OR)
   - IS NULL / IS NOT NULL
   - IN with literal values
*/

-- Valid filtered index examples:
CREATE NONCLUSTERED INDEX IX_Valid1 ON Products(Price) WHERE IsActive = 1;
CREATE NONCLUSTERED INDEX IX_Valid2 ON Products(Category) WHERE Price > 100;
CREATE NONCLUSTERED INDEX IX_Valid3 ON Products(StockQuantity) WHERE DiscontinuedDate IS NULL;
CREATE NONCLUSTERED INDEX IX_Valid4 ON Products(Price) WHERE Category IN ('Electronics', 'Books');
GO

-- Drop demo indexes
DROP INDEX IX_Valid1 ON Products;
DROP INDEX IX_Valid2 ON Products;
DROP INDEX IX_Valid3 ON Products;
DROP INDEX IX_Valid4 ON Products;
GO

-- Invalid examples (commented out - will not compile):
/*
-- Cannot compare two columns
CREATE INDEX IX_Invalid1 ON Products(ProductName) WHERE Price > Cost;

-- Cannot use OR
CREATE INDEX IX_Invalid2 ON Products(Category) WHERE IsActive = 1 OR StockQuantity > 0;

-- Cannot use subquery
CREATE INDEX IX_Invalid3 ON Products(Price) WHERE CustomerID IN (SELECT CustomerID FROM Customers WHERE City = 'Chicago');
*/

-- =============================================
-- Example 8: Filtered Index Maintenance
-- =============================================

-- Filtered indexes have less maintenance overhead

-- Check fragmentation
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('Products'), NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE i.name LIKE 'IX_Products_%'
ORDER BY ips.page_count DESC;
GO

-- Reorganize filtered index (faster due to fewer pages)
ALTER INDEX IX_Products_Category_ActiveOnly ON Products REORGANIZE;
GO

-- Rebuild filtered index
ALTER INDEX IX_Products_Category_ActiveOnly ON Products REBUILD;
GO

-- Update statistics on filtered index
UPDATE STATISTICS Products IX_Products_Category_ActiveOnly;
GO

-- =============================================
-- Example 9: Real-World Filtered Index Patterns
-- =============================================

-- Pattern 1: Low inventory alerts (small subset)
CREATE NONCLUSTERED INDEX IX_Products_LowStock
ON Products(StockQuantity)
INCLUDE (ProductName, Category)
WHERE IsActive = 1 AND StockQuantity < 20;
GO

-- Pattern 2: High-value sales (top 10%)
CREATE NONCLUSTERED INDEX IX_Sales_HighValue
ON Sales(TotalAmount DESC)
INCLUDE (CustomerID, ProductID, SaleDate)
WHERE TotalAmount >= 100;  -- Adjust threshold for your data
GO

-- Pattern 3: VIP customers (top tier)
-- Add CustomerTier column for demo
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'Tier')
BEGIN
    ALTER TABLE Customers ADD Tier VARCHAR(10) DEFAULT 'Standard';
    UPDATE TOP (5) Customers SET Tier = 'VIP';
END;
GO

CREATE NONCLUSTERED INDEX IX_Customers_VIP
ON Customers(CustomerName)
INCLUDE (City, State, TotalPurchases)
WHERE Tier = 'VIP';
GO

-- Pattern 4: Recent activity
CREATE NONCLUSTERED INDEX IX_Sales_ThisYear
ON Sales(SaleDate DESC, CustomerID)
INCLUDE (ProductID, TotalAmount)
WHERE SaleDate >= '2024-01-01';
GO

-- Test real-world patterns
SELECT ProductName, Category, StockQuantity FROM Products WHERE IsActive = 1 AND StockQuantity < 20;
SELECT SaleDate, TotalAmount FROM Sales WHERE TotalAmount >= 100 ORDER BY TotalAmount DESC;
SELECT CustomerName, TotalPurchases FROM Customers WHERE Tier = 'VIP';
SELECT SaleDate, TotalAmount FROM Sales WHERE SaleDate >= '2024-01-01' ORDER BY SaleDate DESC;
GO

-- =============================================
-- Example 10: Monitoring Filtered Index Usage
-- =============================================

-- View filtered index usage statistics
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.filter_definition AS FilterCondition,
    ius.user_seeks AS Seeks,
    ius.user_scans AS Scans,
    ius.user_updates AS Updates,
    ius.last_user_seek AS LastSeek
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id 
    AND i.index_id = ius.index_id 
    AND ius.database_id = DB_ID()
WHERE i.object_id IN (OBJECT_ID('Products'), OBJECT_ID('Sales'), OBJECT_ID('Customers'))
    AND i.has_filter = 1  -- Only filtered indexes
ORDER BY ius.user_seeks + ius.user_scans DESC;
GO

-- =============================================
-- Cleanup
-- =============================================

DROP INDEX IF EXISTS IX_Products_Category_All ON Products;
DROP INDEX IF EXISTS IX_Products_Category_ActiveOnly ON Products;
DROP INDEX IF EXISTS IX_Products_Current ON Products;
DROP INDEX IF EXISTS IX_Products_Discontinued ON Products;
DROP INDEX IF EXISTS IX_Sales_Pending ON Sales;
DROP INDEX IF EXISTS IX_Products_AffordableElectronics ON Products;
DROP INDEX IF EXISTS IX_Sales_Recent ON Sales;
DROP INDEX IF EXISTS IX_Products_InStock ON Products;
DROP INDEX IF EXISTS IX_Products_LowStock ON Products;
DROP INDEX IF EXISTS IX_Sales_HighValue ON Sales;
DROP INDEX IF EXISTS IX_Customers_VIP ON Customers;
DROP INDEX IF EXISTS IX_Sales_ThisYear ON Sales;
GO

-- Remove demo columns (optional)
/*
ALTER TABLE Products DROP COLUMN IF EXISTS DiscontinuedDate;
ALTER TABLE Sales DROP COLUMN IF EXISTS Status;
ALTER TABLE Customers DROP COLUMN IF EXISTS Tier;
*/

-- 💡 Key Takeaways:
-- - Filtered indexes index only subset of rows (WHERE clause)
-- - Much smaller than regular indexes (less storage, faster maintenance)
-- - Perfect for skewed data distributions
-- - Query must match filter to use filtered index
-- - Use for active/inactive, status codes, date ranges
-- - Cannot use OR, subqueries, column comparisons in filter
-- - Excellent for minority cases (pending orders, VIPs, low stock)
-- - Reduces write overhead (only updates matching rows)
-- - More accurate statistics for subset
-- - Check filter_definition in sys.indexes
-- - Monitor with sys.dm_db_index_usage_stats
-- - Combine with INCLUDE for covering filtered indexes
-- - Consider filtered index before full index on low-selectivity columns
-- - Filtered indexes are often better than indexed views
-- - Test query performance with SET STATISTICS IO ON
