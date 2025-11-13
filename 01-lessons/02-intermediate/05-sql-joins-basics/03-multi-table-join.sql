-- ========================================
-- Join Three Tables: Sales + Customers + Products
-- ========================================

USE TechStore;

-- Complete sales report with customer and product details
SELECT 
    s.SaleID,
    c.CustomerName,
    c.City,
    p.ProductName,
    p.Category,
    s.Quantity,
    s.TotalAmount,
    s.SaleDate
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
ORDER BY s.SaleDate DESC;

-- Find which customers bought which categories
SELECT 
    c.CustomerName,
    p.Category,
    COUNT(*) AS PurchaseCount,
    SUM(s.TotalAmount) AS TotalSpent
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerName, p.Category
ORDER BY c.CustomerName;
