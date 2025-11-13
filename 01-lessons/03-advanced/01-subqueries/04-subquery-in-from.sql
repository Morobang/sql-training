-- ========================================
-- Subqueries in FROM Clause (Derived Tables)
-- ========================================

USE TechStore;

-- 1. Category price statistics
SELECT 
    Category,
    AvgPrice,
    MinPrice,
    MaxPrice,
    ProductCount
FROM (
    SELECT 
        Category,
        AVG(Price) AS AvgPrice,
        MIN(Price) AS MinPrice,
        MAX(Price) AS MaxPrice,
        COUNT(*) AS ProductCount
    FROM Products
    GROUP BY Category
) AS CategoryStats
WHERE ProductCount > 1
ORDER BY AvgPrice DESC;

-- 2. Top customers ranked
SELECT 
    CustomerName,
    TotalSpent,
    OrderCount,
    AvgOrderValue
FROM (
    SELECT 
        c.CustomerName,
        SUM(s.TotalAmount) AS TotalSpent,
        COUNT(s.SaleID) AS OrderCount,
        AVG(s.TotalAmount) AS AvgOrderValue
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerName
) AS CustomerStats
WHERE TotalSpent > 100
ORDER BY TotalSpent DESC;

-- 3. Monthly sales summary
SELECT 
    SaleYear,
    SaleMonth,
    TotalRevenue,
    OrderCount
FROM (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(TotalAmount) AS TotalRevenue,
        COUNT(*) AS OrderCount
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
) AS MonthlySales
ORDER BY SaleYear DESC, SaleMonth DESC;

-- 4. Product profitability analysis
SELECT 
    ProductName,
    Revenue,
    TotalCost,
    Profit,
    ProfitMargin
FROM (
    SELECT 
        p.ProductName,
        SUM(s.TotalAmount) AS Revenue,
        SUM(s.Quantity * p.Cost) AS TotalCost,
        SUM(s.TotalAmount) - SUM(s.Quantity * p.Cost) AS Profit,
        ROUND(((SUM(s.TotalAmount) - SUM(s.Quantity * p.Cost)) / SUM(s.TotalAmount)) * 100, 2) AS ProfitMargin
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductName
) AS Profitability
WHERE Profit > 0
ORDER BY ProfitMargin DESC;
