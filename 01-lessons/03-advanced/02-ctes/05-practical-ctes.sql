-- ========================================
-- Practical CTE Applications with TechStore
-- ========================================

USE TechStore;

-- =============================================
-- 1. Sales Performance Dashboard
-- =============================================
WITH 
DailySales AS (
    SELECT 
        CAST(SaleDate AS DATE) AS SaleDay,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS DailyRevenue,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE)
),
SalesMetrics AS (
    SELECT 
        SaleDay,
        DailyRevenue,
        OrderCount,
        AvgOrderValue,
        SUM(DailyRevenue) OVER (ORDER BY SaleDay) AS RunningTotal,
        AVG(DailyRevenue) OVER (ORDER BY SaleDay ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Moving3DayAvg
    FROM DailySales
)
SELECT 
    SaleDay,
    DailyRevenue,
    OrderCount,
    AvgOrderValue,
    RunningTotal,
    Moving3DayAvg,
    DailyRevenue - Moving3DayAvg AS VarianceFromAvg
FROM SalesMetrics
ORDER BY SaleDay DESC;

-- =============================================
-- 2. Customer Lifetime Value Analysis
-- =============================================
WITH 
CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.State,
        COUNT(s.SaleID) AS TotalOrders,
        SUM(s.TotalAmount) AS LifetimeValue,
        MIN(s.SaleDate) AS FirstPurchase,
        MAX(s.SaleDate) AS LastPurchase,
        DATEDIFF(DAY, MIN(s.SaleDate), MAX(s.SaleDate)) AS CustomerLifespanDays
    FROM Customers c
    LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerID, c.CustomerName, c.State
),
CustomerSegments AS (
    SELECT 
        *,
        CASE 
            WHEN LifetimeValue >= 1000 THEN 'VIP'
            WHEN LifetimeValue >= 500 THEN 'Gold'
            WHEN LifetimeValue >= 100 THEN 'Silver'
            WHEN LifetimeValue > 0 THEN 'Bronze'
            ELSE 'Inactive'
        END AS Segment,
        CASE 
            WHEN TotalOrders > 0 THEN LifetimeValue / TotalOrders
            ELSE 0
        END AS AvgOrderValue,
        DATEDIFF(DAY, LastPurchase, GETDATE()) AS DaysSinceLastPurchase
    FROM CustomerMetrics
),
SegmentStats AS (
    SELECT 
        Segment,
        COUNT(*) AS CustomerCount,
        AVG(LifetimeValue) AS AvgLifetimeValue,
        AVG(AvgOrderValue) AS AvgOrderValue,
        SUM(LifetimeValue) AS TotalRevenue
    FROM CustomerSegments
    GROUP BY Segment
)
SELECT 
    cs.CustomerName,
    cs.State,
    cs.Segment,
    cs.TotalOrders,
    cs.LifetimeValue,
    cs.AvgOrderValue,
    cs.DaysSinceLastPurchase,
    ss.CustomerCount AS PeersInSegment,
    ss.AvgLifetimeValue AS SegmentAvgLTV
FROM CustomerSegments cs
INNER JOIN SegmentStats ss ON cs.Segment = ss.Segment
ORDER BY cs.LifetimeValue DESC;

-- =============================================
-- 3. Inventory Optimization Report
-- =============================================
WITH 
ProductSalesVelocity AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        p.StockQuantity,
        COUNT(s.SaleID) AS SalesTransactions,
        SUM(s.Quantity) AS TotalUnitsSold,
        DATEDIFF(DAY, MIN(s.SaleDate), MAX(s.SaleDate)) AS SalesPeriodDays
    FROM Products p
    LEFT JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category, p.StockQuantity
),
InventoryAnalysis AS (
    SELECT 
        *,
        CASE 
            WHEN SalesPeriodDays > 0 
            THEN CAST(TotalUnitsSold AS FLOAT) / SalesPeriodDays
            ELSE 0
        END AS UnitsPerDay,
        CASE 
            WHEN TotalUnitsSold > 0 AND SalesPeriodDays > 0
            THEN StockQuantity / (CAST(TotalUnitsSold AS FLOAT) / SalesPeriodDays)
            ELSE 999
        END AS DaysOfInventory
    FROM ProductSalesVelocity
),
StockAlerts AS (
    SELECT 
        ProductName,
        Category,
        StockQuantity,
        TotalUnitsSold,
        UnitsPerDay,
        DaysOfInventory,
        CASE 
            WHEN DaysOfInventory < 7 THEN 'CRITICAL - Reorder Now'
            WHEN DaysOfInventory < 14 THEN 'LOW - Monitor Closely'
            WHEN DaysOfInventory < 30 THEN 'NORMAL - Adequate Stock'
            WHEN DaysOfInventory > 90 THEN 'OVERSTOCK - Reduce Orders'
            ELSE 'HEALTHY'
        END AS StockStatus,
        CASE 
            WHEN UnitsPerDay > 0
            THEN CEILING(UnitsPerDay * 30)
            ELSE 0
        END AS Recommended30DayStock
    FROM InventoryAnalysis
)
SELECT *
FROM StockAlerts
WHERE StockStatus IN ('CRITICAL - Reorder Now', 'LOW - Monitor Closely', 'OVERSTOCK - Reduce Orders')
ORDER BY 
    CASE StockStatus
        WHEN 'CRITICAL - Reorder Now' THEN 1
        WHEN 'LOW - Monitor Closely' THEN 2
        ELSE 3
    END,
    DaysOfInventory;

-- =============================================
-- 4. Product Profitability Matrix
-- =============================================
WITH 
ProductFinancials AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Price,
        p.Cost,
        p.Price - p.Cost AS ProfitPerUnit,
        SUM(s.Quantity) AS UnitsSold,
        SUM(s.TotalAmount) AS Revenue,
        SUM(s.Quantity * p.Cost) AS TotalCost
    FROM Products p
    LEFT JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category, p.Price, p.Cost
),
ProfitabilityMetrics AS (
    SELECT 
        *,
        Revenue - TotalCost AS TotalProfit,
        CASE 
            WHEN Revenue > 0
            THEN ((Revenue - TotalCost) / Revenue) * 100
            ELSE 0
        END AS ProfitMargin,
        CASE 
            WHEN TotalCost > 0
            THEN ((Revenue - TotalCost) / TotalCost) * 100
            ELSE 0
        END AS ROI
    FROM ProductFinancials
),
CategoryBenchmarks AS (
    SELECT 
        Category,
        AVG(ProfitMargin) AS AvgCategoryMargin,
        AVG(UnitsSold) AS AvgCategoryUnits
    FROM ProfitabilityMetrics
    WHERE UnitsSold > 0
    GROUP BY Category
)
SELECT 
    pm.ProductName,
    pm.Category,
    pm.UnitsSold,
    pm.Revenue,
    pm.TotalProfit,
    ROUND(pm.ProfitMargin, 2) AS ProfitMargin,
    ROUND(pm.ROI, 2) AS ROI,
    ROUND(cb.AvgCategoryMargin, 2) AS CategoryAvgMargin,
    CASE 
        WHEN pm.ProfitMargin > cb.AvgCategoryMargin AND pm.UnitsSold > cb.AvgCategoryUnits THEN 'Star Product'
        WHEN pm.ProfitMargin > cb.AvgCategoryMargin AND pm.UnitsSold <= cb.AvgCategoryUnits THEN 'High Margin Low Volume'
        WHEN pm.ProfitMargin <= cb.AvgCategoryMargin AND pm.UnitsSold > cb.AvgCategoryUnits THEN 'High Volume Low Margin'
        ELSE 'Underperformer'
    END AS ProductClassification
FROM ProfitabilityMetrics pm
INNER JOIN CategoryBenchmarks cb ON pm.Category = cb.Category
WHERE pm.UnitsSold > 0
ORDER BY pm.TotalProfit DESC;
