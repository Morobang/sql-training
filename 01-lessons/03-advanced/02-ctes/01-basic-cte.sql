-- ========================================
-- Basic CTE Examples
-- ========================================

USE TechStore;

-- 1. Simple CTE - Category averages
WITH CategoryAvg AS (
    SELECT 
        Category,
        AVG(Price) AS AvgPrice,
        COUNT(*) AS ProductCount
    FROM Products
    GROUP BY Category
)
SELECT 
    Category,
    AvgPrice,
    ProductCount
FROM CategoryAvg
ORDER BY AvgPrice DESC;

-- 2. Find products above category average
WITH CategoryStats AS (
    SELECT 
        Category,
        AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY Category
)
SELECT 
    p.ProductName,
    p.Category,
    p.Price,
    cs.AvgPrice,
    p.Price - cs.AvgPrice AS DiffFromAvg
FROM Products p
INNER JOIN CategoryStats cs ON p.Category = cs.Category
WHERE p.Price > cs.AvgPrice
ORDER BY p.Category, p.Price DESC;

-- 3. Customer purchase summary
WITH CustomerSales AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent,
        AVG(TotalAmount) AS AvgOrderValue,
        MAX(SaleDate) AS LastPurchase
    FROM Sales
    GROUP BY CustomerID
)
SELECT 
    c.CustomerName,
    c.City,
    cs.OrderCount,
    cs.TotalSpent,
    cs.AvgOrderValue,
    cs.LastPurchase,
    DATEDIFF(DAY, cs.LastPurchase, GETDATE()) AS DaysSinceLastOrder
FROM Customers c
INNER JOIN CustomerSales cs ON c.CustomerID = cs.CustomerID
ORDER BY cs.TotalSpent DESC;

-- 4. Product sales performance
WITH ProductSales AS (
    SELECT 
        ProductID,
        COUNT(*) AS TimesSold,
        SUM(Quantity) AS TotalQuantitySold,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY ProductID
)
SELECT 
    p.ProductName,
    p.Category,
    p.Price,
    ps.TimesSold,
    ps.TotalQuantitySold,
    ps.Revenue,
    ROUND(ps.Revenue / ps.TimesSold, 2) AS AvgRevenuePerSale
FROM Products p
LEFT JOIN ProductSales ps ON p.ProductID = ps.ProductID
ORDER BY ps.Revenue DESC;
