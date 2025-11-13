-- ========================================
-- Comparison Operators: =, <>, >, <, >=, <=
-- ========================================

USE TechStore;

-- Equal to (=)
SELECT ProductName, Price
FROM Products
WHERE Price = 149.99;

-- Not equal to (<>)
SELECT ProductName, Price
FROM Products
WHERE Price <> 149.99;

-- Greater than (>)
SELECT ProductName, Price
FROM Products
WHERE Price > 100;

-- Less than (<)
SELECT ProductName, Price
FROM Products
WHERE Price < 50;

-- Greater than or equal (>=)
SELECT ProductName, StockQuantity
FROM Products
WHERE StockQuantity >= 50;

-- Less than or equal (<=)
SELECT ProductName, StockQuantity
FROM Products
WHERE StockQuantity <= 20;
