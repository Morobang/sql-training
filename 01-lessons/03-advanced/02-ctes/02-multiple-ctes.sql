-- ========================================
-- Multiple CTEs in One Query
-- ========================================

USE TechStore;

-- 1. Multiple CTEs for complex analysis
WITH 
CategoryStats AS (
    SELECT 
        Category,
        COUNT(*) AS ProductCount,
        AVG(Price) AS AvgPrice,
        SUM(StockQuantity) AS TotalStock
    FROM Products
    GROUP BY Category
),
SalesStats AS (
    SELECT 
        p.Category,
        COUNT(s.SaleID) AS SalesCount,
        SUM(s.TotalAmount) AS Revenue
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.Category
)
SELECT 
    cs.Category,
    cs.ProductCount,
    cs.AvgPrice,
    cs.TotalStock,
    ISNULL(ss.SalesCount, 0) AS SalesCount,
    ISNULL(ss.Revenue, 0) AS Revenue
FROM CategoryStats cs
LEFT JOIN SalesStats ss ON cs.Category = ss.Category
ORDER BY Revenue DESC;

-- 2. Customer segmentation with multiple CTEs
WITH 
CustomerPurchases AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent,
        MAX(SaleDate) AS LastPurchase
    FROM Sales
    GROUP BY CustomerID
),
CustomerTiers AS (
    SELECT 
        CustomerID,
        OrderCount,
        TotalSpent,
        LastPurchase,
        CASE 
            WHEN TotalSpent >= 1000 THEN 'VIP'
            WHEN TotalSpent >= 500 THEN 'Gold'
            WHEN TotalSpent >= 100 THEN 'Silver'
            ELSE 'Bronze'
        END AS Tier
    FROM CustomerPurchases
),
TierStats AS (
    SELECT 
        Tier,
        COUNT(*) AS CustomerCount,
        AVG(TotalSpent) AS AvgSpending,
        AVG(OrderCount) AS AvgOrders
    FROM CustomerTiers
    GROUP BY Tier
)
SELECT 
    c.CustomerName,
    ct.Tier,
    ct.OrderCount,
    ct.TotalSpent,
    ct.LastPurchase,
    ts.CustomerCount AS CustomersInTier,
    ts.AvgSpending AS TierAvgSpending
FROM Customers c
INNER JOIN CustomerTiers ct ON c.CustomerID = ct.CustomerID
INNER JOIN TierStats ts ON ct.Tier = ts.Tier
ORDER BY 
    CASE ct.Tier
        WHEN 'VIP' THEN 1
        WHEN 'Gold' THEN 2
        WHEN 'Silver' THEN 3
        ELSE 4
    END,
    ct.TotalSpent DESC;

-- 3. Product performance analysis
WITH 
ProductSales AS (
    SELECT 
        ProductID,
        COUNT(*) AS TimesSold,
        SUM(Quantity) AS TotalQtySold,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY ProductID
),
ProductCosts AS (
    SELECT 
        ProductID,
        Cost,
        Price,
        Price - Cost AS ProfitPerUnit
    FROM Products
),
ProductPerformance AS (
    SELECT 
        ps.ProductID,
        ps.Revenue,
        ps.TotalQtySold,
        pc.ProfitPerUnit,
        ps.TotalQtySold * pc.ProfitPerUnit AS TotalProfit,
        RANK() OVER (ORDER BY ps.Revenue DESC) AS RevenueRank
    FROM ProductSales ps
    INNER JOIN ProductCosts pc ON ps.ProductID = pc.ProductID
)
SELECT 
    p.ProductName,
    p.Category,
    pp.Revenue,
    pp.TotalQtySold,
    pp.TotalProfit,
    pp.RevenueRank
FROM Products p
INNER JOIN ProductPerformance pp ON p.ProductID = pp.ProductID
WHERE pp.RevenueRank <= 10
ORDER BY pp.RevenueRank;
