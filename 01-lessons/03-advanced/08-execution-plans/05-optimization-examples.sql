-- ========================================
-- Real-World Query Optimization Examples
-- Using Execution Plans to Solve Problems
-- ========================================

USE TechStore;
GO

-- =============================================
-- Problem 1: Slow Dashboard Query
-- =============================================

PRINT '=== PROBLEM 1: Slow Dashboard Query ===';
GO

-- Initial slow query (table scans, no covering indexes)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    c.CustomerName,
    c.City,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS TotalRevenue,
    MAX(s.SaleDate) AS LastOrderDate,
    AVG(s.TotalAmount) AS AvgOrderValue
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.City IN ('Chicago', 'New York', 'Los Angeles')
GROUP BY c.CustomerID, c.CustomerName, c.City
HAVING COUNT(s.SaleID) > 0
ORDER BY TotalRevenue DESC;

-- Check execution plan: Likely shows key lookups, scans
PRINT 'Before optimization - check logical reads above';
GO

-- Optimization 1: Create covering indexes
CREATE NONCLUSTERED INDEX IX_Customers_City_Covering
ON Customers(City)
INCLUDE (CustomerName);

CREATE NONCLUSTERED INDEX IX_Sales_Customer_Summary
ON Sales(CustomerID)
INCLUDE (SaleDate, TotalAmount);
GO

-- Optimized query (same query, but uses covering indexes)
SELECT 
    c.CustomerName,
    c.City,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS TotalRevenue,
    MAX(s.SaleDate) AS LastOrderDate,
    AVG(s.TotalAmount) AS AvgOrderValue
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.City IN ('Chicago', 'New York', 'Los Angeles')
GROUP BY c.CustomerID, c.CustomerName, c.City
HAVING COUNT(s.SaleID) > 0
ORDER BY TotalRevenue DESC;

PRINT 'After optimization - check logical reads above (should be much lower)';
GO

-- =============================================
-- Problem 2: Report with Implicit Conversion
-- =============================================

PRINT '=== PROBLEM 2: Implicit Conversion Issue ===';
GO

-- Query with data type mismatch (ProductID is INT)
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Products
WHERE ProductID = '5';  -- VARCHAR compared to INT column

-- Execution plan shows: CONVERT_IMPLICIT warning
-- Index cannot be used efficiently
PRINT 'Check execution plan for CONVERT_IMPLICIT warning';
GO

-- Fixed query (correct data type)
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Products
WHERE ProductID = 5;  -- INT compared to INT

PRINT 'Fixed: No conversion, index used efficiently';
GO

-- =============================================
-- Problem 3: Non-SARGable WHERE Clause
-- =============================================

PRINT '=== PROBLEM 3: Non-SARGable Predicate ===';
GO

-- Non-SARGable: Function on indexed column
SELECT 
    ProductName,
    Price,
    Cost
FROM Products
WHERE YEAR(LastModified) = 2024;  -- Function on column

-- Execution plan: Table scan or index scan (cannot seek)
PRINT 'Non-SARGable: Function on column = scan';
GO

-- SARGable: Range on column directly
SELECT 
    ProductName,
    Price,
    Cost
FROM Products
WHERE LastModified >= '2024-01-01' 
    AND LastModified < '2025-01-01';

-- Execution plan: Index seek possible
PRINT 'SARGable: Range on column = seek possible';
GO

-- =============================================
-- Problem 4: Missing Index on Foreign Key
-- =============================================

PRINT '=== PROBLEM 4: Missing Foreign Key Index ===';
GO

-- Drop foreign key index for demonstration
DROP INDEX IF EXISTS IX_Sales_ProductID ON Sales;
GO

-- Join without index on foreign key
SELECT 
    p.ProductName,
    COUNT(s.SaleID) AS SalesCount,
    SUM(s.TotalAmount) AS TotalRevenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
WHERE p.Category = 'Electronics'
GROUP BY p.ProductName;

-- Execution plan: Hash join or nested loops with scan
PRINT 'Without index: Hash join or inefficient nested loops';
GO

-- Add index on foreign key
CREATE NONCLUSTERED INDEX IX_Sales_ProductID ON Sales(ProductID)
INCLUDE (SaleDate, TotalAmount);
GO

-- Same query with index
SELECT 
    p.ProductName,
    COUNT(s.SaleID) AS SalesCount,
    SUM(s.TotalAmount) AS TotalRevenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
WHERE p.Category = 'Electronics'
GROUP BY p.ProductName;

-- Execution plan: Nested loops with index seek
PRINT 'With index: Efficient nested loops with seeks';
GO

-- =============================================
-- Problem 5: Excessive Key Lookups
-- =============================================

PRINT '=== PROBLEM 5: Key Lookup Performance Hit ===';
GO

-- Query causing key lookups
DROP INDEX IF EXISTS IX_Products_Category_Covering ON Products;
GO

CREATE NONCLUSTERED INDEX IX_Products_Category_Simple
ON Products(Category);
GO

SELECT 
    ProductName,
    Category,
    Price,
    Cost,
    StockQuantity,
    SupplierID
FROM Products
WHERE Category = 'Electronics';

-- Execution plan: Index seek + key lookup + nested loop
PRINT 'Many key lookups = performance hit';
GO

-- Fix: Covering index
CREATE NONCLUSTERED INDEX IX_Products_Category_FullCovering
ON Products(Category)
INCLUDE (ProductName, Price, Cost, StockQuantity, SupplierID);
GO

-- Same query, no key lookups
SELECT 
    ProductName,
    Category,
    Price,
    Cost,
    StockQuantity,
    SupplierID
FROM Products
WHERE Category = 'Electronics';

-- Execution plan: Index seek only
PRINT 'Covering index: No key lookups';
GO

-- =============================================
-- Problem 6: Sort Operator Overhead
-- =============================================

PRINT '=== PROBLEM 6: Expensive Sort Operation ===';
GO

-- Query with ORDER BY on non-indexed column
SELECT 
    ProductName,
    Category,
    Price,
    StockQuantity
FROM Products
WHERE Category = 'Electronics'
ORDER BY StockQuantity DESC;

-- Execution plan: Sort operator (expensive)
PRINT 'Sort operator required (not in index)';
GO

-- Fix: Index matching ORDER BY
DROP INDEX IF EXISTS IX_Products_Category_Simple ON Products;
GO

CREATE NONCLUSTERED INDEX IX_Products_Category_Stock_Desc
ON Products(Category, StockQuantity DESC)
INCLUDE (ProductName, Price);
GO

-- Same query, no sort needed
SELECT 
    ProductName,
    Category,
    Price,
    StockQuantity
FROM Products
WHERE Category = 'Electronics'
ORDER BY StockQuantity DESC;

-- Execution plan: Index seek, no sort
PRINT 'Data already sorted in index';
GO

-- =============================================
-- Problem 7: Outdated Statistics
-- =============================================

PRINT '=== PROBLEM 7: Inaccurate Statistics ===';
GO

-- Check estimated vs actual rows
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Look at actual execution plan:
-- Hover over operators - check Estimated Rows vs Actual Rows
-- Large difference? Statistics may be outdated
PRINT 'Check estimated vs actual rows in execution plan';
GO

-- Update statistics
UPDATE STATISTICS Customers WITH FULLSCAN;
UPDATE STATISTICS Sales WITH FULLSCAN;
GO

-- Run query again - estimates should be more accurate
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

PRINT 'After statistics update - check if estimates improved';
GO

-- =============================================
-- Problem 8: OR Condition Performance
-- =============================================

PRINT '=== PROBLEM 8: OR Condition Causing Scan ===';
GO

-- OR condition may prevent index usage
SELECT 
    ProductName,
    Category,
    Price
FROM Products
WHERE Category = 'Electronics' OR Price > 500;

-- Execution plan: May show scan (cannot efficiently use index)
PRINT 'OR condition: May cause scan';
GO

-- Fix Option 1: UNION with separate indexes
SELECT 
    ProductName,
    Category,
    Price
FROM Products
WHERE Category = 'Electronics'

UNION

SELECT 
    ProductName,
    Category,
    Price
FROM Products
WHERE Price > 500 AND Category <> 'Electronics';

-- Each part can use appropriate index
PRINT 'UNION: Each part can use index';
GO

-- Fix Option 2: If one condition very selective, filter first
SELECT 
    ProductName,
    Category,
    Price
FROM Products
WHERE Category = 'Electronics' OR ProductID IN (
    SELECT ProductID FROM Products WHERE Price > 500
);

PRINT 'Subquery approach (depends on data distribution)';
GO

-- =============================================
-- Problem 9: Scalar Subquery in SELECT List
-- =============================================

PRINT '=== PROBLEM 9: Scalar Subquery Performance ===';
GO

-- Scalar subquery executed for each row
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.Category = p1.Category) AS CategoryAvgPrice
FROM Products p1
WHERE Category IN ('Electronics', 'Books');

-- Execution plan: Subquery executed repeatedly
PRINT 'Scalar subquery: Executed per row (slow)';
GO

-- Fix: JOIN or window function
SELECT 
    p.ProductName,
    p.Price,
    AVG(p.Price) OVER (PARTITION BY p.Category) AS CategoryAvgPrice
FROM Products p
WHERE p.Category IN ('Electronics', 'Books');

-- Window function: Single scan
PRINT 'Window function: More efficient';
GO

-- =============================================
-- Problem 10: Complex JOIN Order
-- =============================================

PRINT '=== PROBLEM 10: Suboptimal Join Order ===';
GO

-- Query with multiple joins
SELECT 
    c.CustomerName,
    p.ProductName,
    s.SaleDate,
    s.TotalAmount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE c.City = 'Chicago'
    AND p.Category = 'Electronics'
    AND s.SaleDate >= '2024-01-01';

-- Check execution plan: Join order
-- Optimizer should start with most selective filter
PRINT 'Check join order in execution plan';
GO

-- If optimizer chooses poorly, can hint (use sparingly)
SELECT 
    c.CustomerName,
    p.ProductName,
    s.SaleDate,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE c.City = 'Chicago'
    AND p.Category = 'Electronics'
    AND s.SaleDate >= '2024-01-01'
OPTION (FORCE ORDER);

-- Forces joins in FROM clause order
PRINT 'Forced join order (use only if optimizer wrong)';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- =============================================
-- Problem 11: Parameter Sniffing
-- =============================================

PRINT '=== PROBLEM 11: Parameter Sniffing Issue ===';
GO

-- Create procedure that may suffer from parameter sniffing
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductName,
        Price,
        StockQuantity
    FROM Products
    WHERE Category = @Category
    ORDER BY Price DESC;
END;
GO

-- First execution (Electronics - few rows)
EXEC usp_GetProductsByCategory 'Electronics';
-- Plan optimized for few rows (index seek + nested loop)
GO

-- Second execution (Books - many rows)
EXEC usp_GetProductsByCategory 'Books';
-- Uses cached plan from first execution (may not be optimal)
GO

-- Fix Option 1: OPTION (RECOMPILE)
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductName,
        Price,
        StockQuantity
    FROM Products
    WHERE Category = @Category
    ORDER BY Price DESC
    OPTION (RECOMPILE);  -- Generate new plan each time
END;
GO

-- Fix Option 2: OPTION (OPTIMIZE FOR)
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductName,
        Price,
        StockQuantity
    FROM Products
    WHERE Category = @Category
    ORDER BY Price DESC
    OPTION (OPTIMIZE FOR (@Category = 'UNKNOWN'));  -- Optimize for average case
END;
GO

-- =============================================
-- Optimization Checklist
-- =============================================

/*
When analyzing slow queries:

1. ✅ Enable actual execution plan (Ctrl+M)
2. ✅ Check SET STATISTICS IO (logical reads)
3. ✅ Find highest cost operators (> 30% of query)
4. ✅ Look for table/index scans (should be seeks)
5. ✅ Check for key lookups (add covering indexes)
6. ✅ Verify estimated vs actual rows (update statistics if different)
7. ✅ Look for implicit conversions (fix data types)
8. ✅ Check for sorts (add indexes matching ORDER BY)
9. ✅ Verify foreign keys are indexed
10. ✅ Review missing index suggestions (test before implementing)
11. ✅ Check for non-SARGable predicates (rewrite)
12. ✅ Look for warnings (memory spills, missing stats)
13. ✅ Verify join strategy is appropriate
14. ✅ Check for parameter sniffing in procedures
15. ✅ Test optimization impact before production

Common Fixes:
- Table scan → Add index on WHERE/JOIN columns
- Key lookup → Add covering index with INCLUDE
- Sort operator → Add index matching ORDER BY
- Hash join → Add index on foreign key
- Implicit conversion → Fix data types in WHERE clause
- Non-SARGable → Rewrite predicate (no functions on columns)
- Outdated statistics → UPDATE STATISTICS WITH FULLSCAN
- Parameter sniffing → OPTION (RECOMPILE) or OPTIMIZE FOR
*/

-- =============================================
-- Cleanup
-- =============================================

DROP PROCEDURE IF EXISTS usp_GetProductsByCategory;
DROP INDEX IF EXISTS IX_Customers_City_Covering ON Customers;
DROP INDEX IF EXISTS IX_Sales_Customer_Summary ON Sales;
DROP INDEX IF EXISTS IX_Products_Category_Simple ON Products;
DROP INDEX IF EXISTS IX_Products_Category_FullCovering ON Products;
DROP INDEX IF EXISTS IX_Products_Category_Stock_Desc ON Products;
GO

-- Restore standard indexes
CREATE NONCLUSTERED INDEX IX_Sales_CustomerID ON Sales(CustomerID);
CREATE NONCLUSTERED INDEX IX_Sales_ProductID ON Sales(ProductID);
GO

-- 💡 Key Takeaways:
-- - Always check execution plans for slow queries
-- - Look for high-cost operators (table scans, sorts, key lookups)
-- - Compare estimated vs actual rows (statistics accuracy)
-- - Index foreign keys and frequently filtered columns
-- - Use covering indexes to eliminate key lookups
-- - Avoid functions on indexed columns (non-SARGable)
-- - Fix implicit conversions (match data types)
-- - Update statistics after bulk data changes
-- - Test optimizations (before/after comparison)
-- - Don't over-index (balance read vs write performance)
-- - Parameter sniffing affects procedures (use RECOMPILE if needed)
-- - UNION may be better than OR for index usage
-- - Window functions often better than scalar subqueries
-- - Let optimizer choose join order (unless proven wrong)
-- - Document why indexes exist (for future maintenance)
