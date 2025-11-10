-- ========================================
-- Basic ORDER BY: Sort by One Column
-- ========================================

USE TechStore;

-- Sort products by price (cheapest first)
SELECT ProductName, Price
FROM Products
ORDER BY Price;

-- Sort products by price (most expensive first)
SELECT ProductName, Price
FROM Products
ORDER BY Price DESC;

-- Sort products alphabetically by name
SELECT ProductName, Price
FROM Products
ORDER BY ProductName;
