-- ========================================
-- LEFT JOIN: All Records from Left Table
-- ========================================

USE TechStore;

-- All customers, even those who haven't made purchases
SELECT 
    c.CustomerName,
    c.City,
    s.SaleID,
    s.TotalAmount,
    s.SaleDate
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
ORDER BY c.CustomerName;

-- Find customers who NEVER made a purchase
SELECT 
    c.CustomerName,
    c.State,
    c.JoinDate
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE s.SaleID IS NULL;

-- All products, even those never sold
SELECT 
    p.ProductName,
    p.Price,
    COUNT(s.SaleID) AS TimesSold
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductName, p.Price
ORDER BY TimesSold DESC;
