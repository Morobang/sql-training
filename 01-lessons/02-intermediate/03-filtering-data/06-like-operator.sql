-- ========================================
-- LIKE Operator: Pattern Matching
-- ========================================

USE TechStore;

-- % = any number of characters
-- _ = single character

-- Starts with 'Wireless'
SELECT ProductName, Price
FROM Products
WHERE ProductName LIKE 'Wireless%';

-- Ends with 'Pro'
SELECT ProductName, Price
FROM Products
WHERE ProductName LIKE '%Pro';

-- Contains 'USB'
SELECT ProductName, Category
FROM Products
WHERE ProductName LIKE '%USB%';

-- Customers whose name starts with 'J'
SELECT CustomerName, City
FROM Customers
WHERE CustomerName LIKE 'J%';

-- NOT LIKE: Exclude pattern
SELECT ProductName
FROM Products
WHERE ProductName NOT LIKE '%Pro%';
