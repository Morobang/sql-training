-- ========================================
-- Practical Window Function Examples
-- ========================================

USE TechStore;

-- 1. Find top 3 products per category by price
SELECT *
FROM (
    SELECT 
        ProductName,
        Category,
        Price,
        RANK() OVER(PARTITION BY Category ORDER BY Price DESC) AS PriceRank
    FROM Products
) AS Ranked
WHERE PriceRank <= 3;

-- 2. Calculate percentage of total sales
SELECT 
    SaleID,
    TotalAmount,
    SUM(TotalAmount) OVER() AS TotalRevenue,
    ROUND((TotalAmount / SUM(TotalAmount) OVER()) * 100, 2) AS PercentOfTotal
FROM Sales;

-- 3. Compare each sale to category average
SELECT 
    s.SaleID,
    p.ProductName,
    p.Category,
    s.TotalAmount,
    AVG(s.TotalAmount) OVER(PARTITION BY p.Category) AS CategoryAvgSale,
    CASE 
        WHEN s.TotalAmount > AVG(s.TotalAmount) OVER(PARTITION BY p.Category) 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS Performance
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID;

-- 4. Customer purchase ranking
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS TotalSpent,
    RANK() OVER(ORDER BY SUM(s.TotalAmount) DESC) AS CustomerRank
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName
ORDER BY CustomerRank;
