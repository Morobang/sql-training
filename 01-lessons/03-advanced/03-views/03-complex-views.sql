-- ========================================
-- Complex Views: Multiple Tables and Aggregations
-- ========================================

USE TechStore;
GO

-- Drop existing views if they exist
DROP VIEW IF EXISTS vw_CustomerOrderDetails;
DROP VIEW IF EXISTS vw_CategorySalesSummary;
DROP VIEW IF EXISTS vw_ProductPerformanceReport;
DROP VIEW IF EXISTS vw_CustomersWithAboveAvgSpending;
DROP VIEW IF EXISTS vw_CustomerSegmentation;
DROP VIEW IF EXISTS vw_MonthlySalesReport;
DROP VIEW IF EXISTS vw_ProductRankings;
DROP VIEW IF EXISTS vw_AllTransactionSummary;
GO

-- =============================================
-- Example 1: View with JOIN (Multiple Tables)
-- =============================================

CREATE VIEW vw_CustomerOrderDetails AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.State,
    s.SaleID,
    s.SaleDate,
    p.ProductName,
    p.Category,
    s.Quantity,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID;
GO

-- Query the view
SELECT * FROM vw_CustomerOrderDetails
WHERE State = 'CA'
ORDER BY SaleDate DESC;

SELECT CustomerName, COUNT(*) AS OrderCount
FROM vw_CustomerOrderDetails
GROUP BY CustomerName
ORDER BY OrderCount DESC;

-- =============================================
-- Example 2: Aggregated View (GROUP BY)
-- =============================================

CREATE VIEW vw_CategorySalesSummary AS
SELECT 
    p.Category,
    COUNT(DISTINCT s.SaleID) AS TotalOrders,
    SUM(s.Quantity) AS TotalUnitsSold,
    SUM(s.TotalAmount) AS TotalRevenue,
    AVG(s.TotalAmount) AS AvgOrderValue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.Category;
GO

SELECT * FROM vw_CategorySalesSummary
ORDER BY TotalRevenue DESC;

-- Further aggregate the view
SELECT 
    SUM(TotalRevenue) AS GrandTotal,
    AVG(AvgOrderValue) AS OverallAvgOrder
FROM vw_CategorySalesSummary;

-- =============================================
-- Example 3: View with Multiple JOINs and Calculations
-- =============================================

CREATE VIEW vw_ProductPerformanceReport AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.Price,
    p.Cost,
    p.StockQuantity,
    ISNULL(SUM(s.Quantity), 0) AS TotalSold,
    ISNULL(SUM(s.TotalAmount), 0) AS TotalRevenue,
    ISNULL(SUM(s.Quantity * p.Cost), 0) AS TotalCost,
    ISNULL(SUM(s.TotalAmount) - SUM(s.Quantity * p.Cost), 0) AS TotalProfit,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.Price, p.Cost, p.StockQuantity;
GO

SELECT * FROM vw_ProductPerformanceReport
WHERE TotalProfit > 100
ORDER BY TotalProfit DESC;

-- =============================================
-- Example 4: View with Subqueries
-- =============================================

CREATE VIEW vw_CustomersWithAboveAvgSpending AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.State,
    SUM(s.TotalAmount) AS TotalSpent,
    (SELECT AVG(TotalAmount) FROM Sales) AS AvgOrderValue,
    COUNT(s.SaleID) AS OrderCount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.State
HAVING SUM(s.TotalAmount) > (SELECT AVG(TotalAmount) * 3 FROM Sales);
GO

SELECT * FROM vw_CustomersWithAboveAvgSpending
ORDER BY TotalSpent DESC;

-- =============================================
-- Example 5: View with CASE Statements
-- =============================================

CREATE VIEW vw_CustomerSegmentation AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.State,
    COUNT(s.SaleID) AS OrderCount,
    SUM(s.TotalAmount) AS TotalSpent,
    CASE 
        WHEN SUM(s.TotalAmount) >= 1000 THEN 'VIP'
        WHEN SUM(s.TotalAmount) >= 500 THEN 'Gold'
        WHEN SUM(s.TotalAmount) >= 100 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerTier,
    CASE 
        WHEN DATEDIFF(DAY, MAX(s.SaleDate), GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(DAY, MAX(s.SaleDate), GETDATE()) <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.State;
GO

SELECT * FROM vw_CustomerSegmentation
WHERE CustomerTier IN ('VIP', 'Gold')
    AND ActivityStatus = 'Active'
ORDER BY TotalSpent DESC;

-- =============================================
-- Example 6: View with Date Calculations
-- =============================================

CREATE VIEW vw_MonthlySalesReport AS
SELECT 
    YEAR(s.SaleDate) AS Year,
    MONTH(s.SaleDate) AS Month,
    DATENAME(MONTH, s.SaleDate) AS MonthName,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS Revenue,
    AVG(s.TotalAmount) AS AvgOrderValue,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT s.ProductID) AS UniqueProducts
FROM Sales s
GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate), DATENAME(MONTH, s.SaleDate);
GO

SELECT * FROM vw_MonthlySalesReport
ORDER BY Year DESC, Month DESC;

-- Compare months
SELECT 
    MonthName,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue,
    Revenue - LAG(Revenue) OVER (ORDER BY Year, Month) AS MonthOverMonthGrowth
FROM vw_MonthlySalesReport;

-- =============================================
-- Example 7: View with Window Functions
-- =============================================

CREATE VIEW vw_ProductRankings AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    ISNULL(SUM(s.TotalAmount), 0) AS TotalRevenue,
    RANK() OVER (ORDER BY ISNULL(SUM(s.TotalAmount), 0) DESC) AS RevenueRank,
    RANK() OVER (PARTITION BY p.Category ORDER BY ISNULL(SUM(s.TotalAmount), 0) DESC) AS CategoryRank
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category;
GO

-- Top products overall
SELECT * FROM vw_ProductRankings
WHERE RevenueRank <= 5
ORDER BY RevenueRank;

-- Top product per category
SELECT * FROM vw_ProductRankings
WHERE CategoryRank = 1
ORDER BY TotalRevenue DESC;

-- =============================================
-- Example 8: View with UNION
-- =============================================

CREATE VIEW vw_AllTransactionSummary AS
SELECT 
    'Sale' AS TransactionType,
    s.SaleID AS TransactionID,
    s.SaleDate AS TransactionDate,
    c.CustomerName,
    s.TotalAmount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID

UNION ALL

SELECT 
    'Refund' AS TransactionType,
    s.SaleID AS TransactionID,
    s.SaleDate AS TransactionDate,
    c.CustomerName,
    -s.TotalAmount AS TotalAmount  -- Negative for refunds
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.PaymentMethod = 'Refund';  -- Simulated refund filter
GO

SELECT * FROM vw_AllTransactionSummary
ORDER BY TransactionDate DESC;

-- =============================================
-- Example 9: Complex View - NOT Updatable
-- =============================================

-- Complex views (with JOIN, GROUP BY, etc.) are read-only
BEGIN TRY
    UPDATE vw_CategorySalesSummary
    SET TotalRevenue = 5000
    WHERE Category = 'Electronics';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Complex views with aggregations are not updatable';
END CATCH;

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP VIEW IF EXISTS vw_CustomerOrderDetails;
DROP VIEW IF EXISTS vw_CategorySalesSummary;
DROP VIEW IF EXISTS vw_ProductPerformanceReport;
DROP VIEW IF EXISTS vw_CustomersWithAboveAvgSpending;
DROP VIEW IF EXISTS vw_CustomerSegmentation;
DROP VIEW IF EXISTS vw_MonthlySalesReport;
DROP VIEW IF EXISTS vw_ProductRankings;
DROP VIEW IF EXISTS vw_AllTransactionSummary;
*/

-- 💡 Key Points:
-- - Complex views join multiple tables
-- - Can include GROUP BY, aggregations, subqueries
-- - Window functions work in views
-- - Complex views are usually read-only (not updatable)
-- - Views can be queried and further aggregated
-- - Use for reporting, dashboards, and complex analysis
-- - Performance same as underlying query (no optimization)
