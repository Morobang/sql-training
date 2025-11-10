-- ========================================
-- Sort Direction: ASC vs DESC
-- ========================================

USE TechStore;

-- ASC (Ascending): Low to High - Default
SELECT ProductName, StockQuantity
FROM Products
ORDER BY StockQuantity ASC;  -- Lowest stock first

-- DESC (Descending): High to Low
SELECT ProductName, StockQuantity
FROM Products
ORDER BY StockQuantity DESC;  -- Highest stock first

-- Sort sales by newest first
SELECT SaleID, SaleDate, TotalAmount
FROM Sales
ORDER BY SaleDate DESC;  -- Most recent first

-- Sort sales by oldest first
SELECT SaleID, SaleDate, TotalAmount
FROM Sales
ORDER BY SaleDate ASC;  -- Oldest first
