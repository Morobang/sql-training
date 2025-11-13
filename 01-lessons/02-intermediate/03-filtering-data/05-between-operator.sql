-- ========================================
-- BETWEEN Operator: Range Filtering
-- ========================================

USE TechStore;

-- Find products in a price range
SELECT ProductName, Price
FROM Products
WHERE Price BETWEEN 50 AND 150;

-- Find products with stock between ranges
SELECT ProductName, StockQuantity
FROM Products
WHERE StockQuantity BETWEEN 20 AND 60;

-- Date range filtering
SELECT SaleID, SaleDate, TotalAmount
FROM Sales
WHERE SaleDate BETWEEN '2024-11-01' AND '2024-11-05';

-- NOT BETWEEN
SELECT ProductName, Price
FROM Products
WHERE Price NOT BETWEEN 50 AND 150;
