-- ========================================
-- Indexed Views (Materialized Views)
-- ========================================

USE TechStore;
GO

-- =============================================
-- What are Indexed Views?
-- =============================================

-- Indexed views (materialized views) physically store the result set
-- They can significantly improve query performance for:
-- - Expensive aggregations
-- - Complex joins
-- - Frequently accessed data

-- Requirements for indexed views:
-- 1. Must use WITH SCHEMABINDING
-- 2. First index must be UNIQUE CLUSTERED
-- 3. Cannot use: *, OUTER JOIN, DISTINCT, TOP, subqueries in SELECT
-- 4. All referenced tables must use two-part names (schema.table)
-- 5. COUNT_BIG(*) instead of COUNT(*)

-- =============================================
-- Example 1: Simple Indexed View
-- =============================================

-- Regular view (not indexed)
DROP VIEW IF EXISTS vw_CategorySales;
GO

CREATE VIEW vw_CategorySales
WITH SCHEMABINDING
AS
SELECT 
    p.Category,
    COUNT_BIG(*) AS TotalOrders,
    SUM(s.Quantity) AS TotalQuantity,
    SUM(s.TotalAmount) AS TotalRevenue
FROM dbo.Products p
INNER JOIN dbo.Sales s ON p.ProductID = s.ProductID
GROUP BY p.Category;
GO

-- Create unique clustered index (materializes the view)
CREATE UNIQUE CLUSTERED INDEX IX_CategorySales_Category
ON vw_CategorySales (Category);
GO

-- Query the indexed view (fast!)
SELECT * FROM vw_CategorySales
ORDER BY TotalRevenue DESC;

-- View is now materialized - data stored physically
EXEC sp_helpindex 'vw_CategorySales';

-- =============================================
-- Example 2: Indexed View with Multiple Indexes
-- =============================================

DROP VIEW IF EXISTS vw_ProductSalesStats;
GO

CREATE VIEW vw_ProductSalesStats
WITH SCHEMABINDING
AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    COUNT_BIG(*) AS OrderCount,
    SUM(s.Quantity) AS TotalQuantitySold,
    SUM(s.TotalAmount) AS TotalRevenue,
    AVG(s.TotalAmount) AS AvgOrderValue
FROM dbo.Products p
INNER JOIN dbo.Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category;
GO

-- Create unique clustered index on ProductID
CREATE UNIQUE CLUSTERED INDEX IX_ProductSalesStats_ProductID
ON vw_ProductSalesStats (ProductID);
GO

-- Add non-clustered index for category queries
CREATE NONCLUSTERED INDEX IX_ProductSalesStats_Category
ON vw_ProductSalesStats (Category)
INCLUDE (TotalRevenue, OrderCount);
GO

-- Fast queries using the materialized view
SELECT * FROM vw_ProductSalesStats
WHERE Category = 'Electronics'
ORDER BY TotalRevenue DESC;

SELECT Category, SUM(TotalRevenue) AS CategoryRevenue
FROM vw_ProductSalesStats
GROUP BY Category;

-- =============================================
-- Example 3: Indexed View for Date-based Aggregation
-- =============================================

DROP VIEW IF EXISTS vw_DailySalesSummary;
GO

CREATE VIEW vw_DailySalesSummary
WITH SCHEMABINDING
AS
SELECT 
    CAST(s.SaleDate AS DATE) AS SaleDate,
    COUNT_BIG(*) AS OrderCount,
    SUM(s.TotalAmount) AS DailyRevenue,
    AVG(s.TotalAmount) AS AvgOrderValue,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers
FROM dbo.Sales s
GROUP BY CAST(s.SaleDate AS DATE);
GO

CREATE UNIQUE CLUSTERED INDEX IX_DailySales_SaleDate
ON vw_DailySalesSummary (SaleDate);
GO

-- Fast date-based queries
SELECT * FROM vw_DailySalesSummary
WHERE SaleDate >= '2024-01-01'
ORDER BY SaleDate DESC;

-- Calculate weekly totals from daily data
SELECT 
    DATEPART(YEAR, SaleDate) AS Year,
    DATEPART(WEEK, SaleDate) AS Week,
    SUM(DailyRevenue) AS WeeklyRevenue,
    SUM(OrderCount) AS WeeklyOrders
FROM vw_DailySalesSummary
GROUP BY DATEPART(YEAR, SaleDate), DATEPART(WEEK, SaleDate)
ORDER BY Year DESC, Week DESC;

-- =============================================
-- Example 4: Performance Comparison
-- =============================================

-- Query without indexed view (recalculates every time)
SELECT 
    Category,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY Category;

-- Query with indexed view (uses stored results)
SELECT 
    Category,
    TotalOrders,
    TotalRevenue
FROM vw_CategorySales;

-- View execution plan to see difference
-- SET STATISTICS IO ON;
-- SET STATISTICS TIME ON;

-- =============================================
-- Example 5: Indexed View Maintenance
-- =============================================

-- When base tables are updated, indexed views are automatically updated
-- This adds overhead to INSERT/UPDATE/DELETE operations

-- Insert new sale (indexed views updated automatically)
INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES (1, 1, 2, GETDATE(), 199.98, 'Credit Card');

-- Check updated view
SELECT * FROM vw_CategorySales;
SELECT * FROM vw_ProductSalesStats WHERE ProductID = 1;

-- Indexed views add overhead to DML operations
-- Trade-off: Faster SELECT, slower INSERT/UPDATE/DELETE

-- =============================================
-- Example 6: View Metadata and Information
-- =============================================

-- Check if view is indexed
SELECT 
    OBJECT_NAME(v.object_id) AS ViewName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique,
    i.is_primary_key
FROM sys.views v
INNER JOIN sys.indexes i ON v.object_id = i.object_id
WHERE v.name LIKE 'vw_%'
ORDER BY ViewName, IndexName;

-- View size and row count
SELECT 
    OBJECT_NAME(i.object_id) AS ViewName,
    i.name AS IndexName,
    ps.row_count AS RowCnt,
    ps.reserved_page_count * 8 / 1024.0 AS ReservedMB,
    ps.used_page_count * 8 / 1024.0 AS UsedMB
FROM sys.dm_db_partition_stats ps
INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
WHERE OBJECT_NAME(i.object_id) LIKE 'vw_%'
ORDER BY ViewName;

-- =============================================
-- Example 7: Rebuilding Indexed Views
-- =============================================

-- Rebuild index on view (reorganizes data)
ALTER INDEX IX_CategorySales_Category
ON vw_CategorySales REBUILD;

-- Rebuild all indexes on a view
ALTER INDEX ALL ON vw_ProductSalesStats REBUILD;

-- Update statistics
UPDATE STATISTICS vw_CategorySales;

-- =============================================
-- Example 8: Dropping Indexed Views
-- =============================================

-- Must drop indexes before dropping view
/*
DROP INDEX IX_ProductSalesStats_Category ON vw_ProductSalesStats;
DROP INDEX IX_ProductSalesStats_ProductID ON vw_ProductSalesStats;
DROP VIEW vw_ProductSalesStats;

-- Or drop view with all indexes
DROP VIEW IF EXISTS vw_ProductSalesStats;
*/

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP VIEW IF EXISTS vw_CategorySales;
DROP VIEW IF EXISTS vw_ProductSalesStats;
DROP VIEW IF EXISTS vw_DailySalesSummary;
*/

-- 💡 Key Points:
-- - Indexed views store results physically (materialized)
-- - Require WITH SCHEMABINDING and UNIQUE CLUSTERED INDEX
-- - Significant performance improvement for expensive aggregations
-- - Automatically maintained when base tables change
-- - Trade-off: faster SELECT, slower INSERT/UPDATE/DELETE
-- - Use for frequently queried, slowly changing data
-- - Must use COUNT_BIG(*), two-part names (schema.table)
-- - Cannot use: *, OUTER JOIN, DISTINCT, TOP, subqueries
