-- ========================================
-- Practical View Applications
-- ========================================

USE TechStore;
GO

-- Drop existing views
DROP VIEW IF EXISTS vw_SalesDashboard;
DROP VIEW IF EXISTS vw_InventoryAlert;
DROP VIEW IF EXISTS vw_CustomerLifetimeValue;
DROP VIEW IF EXISTS vw_ProductPerformanceKPIs;
DROP VIEW IF EXISTS vw_SalesTeamMetrics;
DROP VIEW IF EXISTS vw_MonthlyRevenueReport;
GO

-- =============================================
-- Pattern 1: Executive Dashboard View
-- =============================================

CREATE VIEW vw_SalesDashboard AS
SELECT 
    -- Overall metrics
    COUNT(DISTINCT s.SaleID) AS TotalOrders,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT s.ProductID) AS ProductsSold,
    SUM(s.TotalAmount) AS TotalRevenue,
    AVG(s.TotalAmount) AS AvgOrderValue,
    
    -- Today's metrics
    COUNT(DISTINCT CASE WHEN CAST(s.SaleDate AS DATE) = CAST(GETDATE() AS DATE) THEN s.SaleID END) AS OrdersToday,
    SUM(CASE WHEN CAST(s.SaleDate AS DATE) = CAST(GETDATE() AS DATE) THEN s.TotalAmount ELSE 0 END) AS RevenueToday,
    
    -- This month's metrics
    COUNT(DISTINCT CASE WHEN YEAR(s.SaleDate) = YEAR(GETDATE()) AND MONTH(s.SaleDate) = MONTH(GETDATE()) THEN s.SaleID END) AS OrdersThisMonth,
    SUM(CASE WHEN YEAR(s.SaleDate) = YEAR(GETDATE()) AND MONTH(s.SaleDate) = MONTH(GETDATE()) THEN s.TotalAmount ELSE 0 END) AS RevenueThisMonth,
    
    -- Payment method breakdown
    SUM(CASE WHEN s.PaymentMethod = 'Credit Card' THEN s.TotalAmount ELSE 0 END) AS CreditCardRevenue,
    SUM(CASE WHEN s.PaymentMethod = 'Cash' THEN s.TotalAmount ELSE 0 END) AS CashRevenue,
    SUM(CASE WHEN s.PaymentMethod = 'PayPal' THEN s.TotalAmount ELSE 0 END) AS PayPalRevenue
FROM Sales s;
GO

-- Single query for entire dashboard
SELECT * FROM vw_SalesDashboard;

-- =============================================
-- Pattern 2: Inventory Management Alert View
-- =============================================

CREATE VIEW vw_InventoryAlert AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.StockQuantity,
    ISNULL(SUM(s.Quantity), 0) AS TotalSold,
    CASE 
        WHEN p.StockQuantity = 0 THEN 'CRITICAL - OUT OF STOCK'
        WHEN p.StockQuantity < 10 THEN 'URGENT - LOW STOCK'
        WHEN p.StockQuantity < 25 THEN 'WARNING - REORDER SOON'
        ELSE 'OK'
    END AS AlertLevel,
    CASE 
        WHEN ISNULL(SUM(s.Quantity), 0) > 0 
        THEN CAST(p.StockQuantity * 1.0 / SUM(s.Quantity) AS DECIMAL(10,2))
        ELSE 999
    END AS DaysOfInventory,
    p.Price * p.StockQuantity AS InventoryValue
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID 
    AND s.SaleDate >= DATEADD(MONTH, -1, GETDATE())  -- Last 30 days
WHERE p.IsActive = 1
GROUP BY p.ProductID, p.ProductName, p.Category, p.StockQuantity, p.Price;
GO

-- Critical alerts only
SELECT * FROM vw_InventoryAlert
WHERE AlertLevel LIKE 'CRITICAL%' OR AlertLevel LIKE 'URGENT%'
ORDER BY 
    CASE AlertLevel
        WHEN 'CRITICAL - OUT OF STOCK' THEN 1
        WHEN 'URGENT - LOW STOCK' THEN 2
        WHEN 'WARNING - REORDER SOON' THEN 3
        ELSE 4
    END;

-- =============================================
-- Pattern 3: Customer Lifetime Value (CLV)
-- =============================================

CREATE VIEW vw_CustomerLifetimeValue AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.State,
    c.JoinDate,
    DATEDIFF(DAY, c.JoinDate, GETDATE()) AS DaysSinceJoined,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS LifetimeValue,
    AVG(s.TotalAmount) AS AvgOrderValue,
    MAX(s.SaleDate) AS LastPurchaseDate,
    DATEDIFF(DAY, MAX(s.SaleDate), GETDATE()) AS DaysSinceLastPurchase,
    CASE 
        WHEN SUM(s.TotalAmount) >= 1000 THEN 'VIP'
        WHEN SUM(s.TotalAmount) >= 500 THEN 'Gold'
        WHEN SUM(s.TotalAmount) >= 250 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerTier,
    CASE 
        WHEN DATEDIFF(DAY, MAX(s.SaleDate), GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(DAY, MAX(s.SaleDate), GETDATE()) <= 90 THEN 'At Risk'
        ELSE 'Churned'
    END AS CustomerStatus
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.State, c.JoinDate;
GO

-- VIP customers at risk of churning
SELECT * FROM vw_CustomerLifetimeValue
WHERE CustomerTier = 'VIP' 
    AND CustomerStatus IN ('At Risk', 'Churned')
ORDER BY LifetimeValue DESC;

-- =============================================
-- Pattern 4: Product Performance KPIs
-- =============================================

CREATE VIEW vw_ProductPerformanceKPIs AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.Price,
    p.Cost,
    p.StockQuantity,
    
    -- Sales metrics
    ISNULL(COUNT(s.SaleID), 0) AS OrderCount,
    ISNULL(SUM(s.Quantity), 0) AS UnitsSold,
    ISNULL(SUM(s.TotalAmount), 0) AS Revenue,
    
    -- Profitability
    ISNULL(SUM(s.Quantity * p.Cost), 0) AS TotalCost,
    ISNULL(SUM(s.TotalAmount) - SUM(s.Quantity * p.Cost), 0) AS GrossProfit,
    CASE 
        WHEN ISNULL(SUM(s.TotalAmount), 0) > 0 
        THEN CAST((SUM(s.TotalAmount) - SUM(s.Quantity * p.Cost)) * 100.0 / SUM(s.TotalAmount) AS DECIMAL(5,2))
        ELSE 0
    END AS ProfitMarginPercent,
    
    -- Performance indicators
    CASE 
        WHEN ISNULL(SUM(s.Quantity), 0) = 0 THEN 'No Sales'
        WHEN ISNULL(SUM(s.Quantity), 0) < 5 THEN 'Poor Seller'
        WHEN ISNULL(SUM(s.Quantity), 0) < 20 THEN 'Moderate Seller'
        ELSE 'Best Seller'
    END AS SalesPerformance,
    
    -- Inventory turnover
    CASE 
        WHEN p.StockQuantity > 0 AND ISNULL(SUM(s.Quantity), 0) > 0
        THEN CAST(ISNULL(SUM(s.Quantity), 0) * 1.0 / p.StockQuantity AS DECIMAL(10,2))
        ELSE 0
    END AS InventoryTurnoverRatio
    
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
WHERE p.IsActive = 1
GROUP BY p.ProductID, p.ProductName, p.Category, p.Price, p.Cost, p.StockQuantity;
GO

-- Best performers by profit margin
SELECT TOP 10 * FROM vw_ProductPerformanceKPIs
WHERE OrderCount > 0
ORDER BY ProfitMarginPercent DESC, Revenue DESC;

-- Products needing attention (poor sales or high inventory)
SELECT * FROM vw_ProductPerformanceKPIs
WHERE SalesPerformance IN ('No Sales', 'Poor Seller')
    AND StockQuantity > 20
ORDER BY StockQuantity DESC;

-- =============================================
-- Pattern 5: Monthly Revenue Reporting
-- =============================================

CREATE VIEW vw_MonthlyRevenueReport AS
SELECT 
    YEAR(s.SaleDate) AS Year,
    MONTH(s.SaleDate) AS MonthNum,
    DATENAME(MONTH, s.SaleDate) AS MonthName,
    
    -- Revenue metrics
    COUNT(DISTINCT s.SaleID) AS TotalOrders,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers,
    SUM(s.TotalAmount) AS TotalRevenue,
    AVG(s.TotalAmount) AS AvgOrderValue,
    
    -- Category breakdown
    SUM(CASE WHEN p.Category = 'Electronics' THEN s.TotalAmount ELSE 0 END) AS ElectronicsRevenue,
    SUM(CASE WHEN p.Category = 'Clothing' THEN s.TotalAmount ELSE 0 END) AS ClothingRevenue,
    SUM(CASE WHEN p.Category = 'Home & Garden' THEN s.TotalAmount ELSE 0 END) AS HomeGardenRevenue,
    SUM(CASE WHEN p.Category = 'Books' THEN s.TotalAmount ELSE 0 END) AS BooksRevenue,
    
    -- Growth calculation (using window function)
    SUM(s.TotalAmount) - LAG(SUM(s.TotalAmount)) OVER (ORDER BY YEAR(s.SaleDate), MONTH(s.SaleDate)) AS MonthOverMonthGrowth,
    CASE 
        WHEN LAG(SUM(s.TotalAmount)) OVER (ORDER BY YEAR(s.SaleDate), MONTH(s.SaleDate)) > 0
        THEN CAST((SUM(s.TotalAmount) - LAG(SUM(s.TotalAmount)) OVER (ORDER BY YEAR(s.SaleDate), MONTH(s.SaleDate))) * 100.0 
             / LAG(SUM(s.TotalAmount)) OVER (ORDER BY YEAR(s.SaleDate), MONTH(s.SaleDate)) AS DECIMAL(5,2))
        ELSE NULL
    END AS GrowthPercent
    
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate), DATENAME(MONTH, s.SaleDate);
GO

-- Full report with trends
SELECT * FROM vw_MonthlyRevenueReport
ORDER BY Year DESC, MonthNum DESC;

-- Year-over-year comparison
SELECT 
    MonthName,
    SUM(CASE WHEN Year = 2024 THEN TotalRevenue ELSE 0 END) AS Revenue2024,
    SUM(CASE WHEN Year = 2023 THEN TotalRevenue ELSE 0 END) AS Revenue2023,
    SUM(CASE WHEN Year = 2024 THEN TotalRevenue ELSE 0 END) - 
    SUM(CASE WHEN Year = 2023 THEN TotalRevenue ELSE 0 END) AS YoYGrowth
FROM vw_MonthlyRevenueReport
GROUP BY MonthName, MonthNum
ORDER BY MonthNum;

-- =============================================
-- Pattern 6: Security - Role-Based Data Access
-- =============================================

-- View for sales team (limited customer data)
DROP VIEW IF EXISTS vw_SalesTeamCustomerView;
GO

CREATE VIEW vw_SalesTeamCustomerView AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.State,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS TotalSpent,
    MAX(s.SaleDate) AS LastPurchase
    -- Excludes: join date, detailed demographics, etc.
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.State;
GO

-- View for finance team (aggregate only)
DROP VIEW IF EXISTS vw_FinanceRevenueView;
GO

CREATE VIEW vw_FinanceRevenueView AS
SELECT 
    CAST(s.SaleDate AS DATE) AS SaleDate,
    COUNT(s.SaleID) AS OrderCount,
    SUM(s.TotalAmount) AS DailyRevenue,
    p.Category
    -- No customer names or individual order details
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
GROUP BY CAST(s.SaleDate AS DATE), p.Category;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP VIEW IF EXISTS vw_SalesDashboard;
DROP VIEW IF EXISTS vw_InventoryAlert;
DROP VIEW IF EXISTS vw_CustomerLifetimeValue;
DROP VIEW IF EXISTS vw_ProductPerformanceKPIs;
DROP VIEW IF EXISTS vw_MonthlyRevenueReport;
DROP VIEW IF EXISTS vw_SalesTeamCustomerView;
DROP VIEW IF EXISTS vw_FinanceRevenueView;
*/

-- 💡 Key Points:
-- - Views simplify complex reporting and dashboards
-- - Use for inventory alerts and KPI tracking
-- - Calculate customer metrics (CLV, churn risk)
-- - Implement role-based data access (security)
-- - Combine multiple aggregations in single view
-- - Add window functions for trends and comparisons
-- - Views provide consistent business logic across applications
-- - Update automatically when base data changes
