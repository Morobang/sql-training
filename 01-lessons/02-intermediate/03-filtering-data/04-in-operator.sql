-- ========================================
-- IN Operator: Match Multiple Values
-- ========================================

USE TechStore;

-- Find products in specific categories
SELECT ProductName, Category, Price
FROM Products
WHERE Category IN ('Peripherals', 'Storage', 'Audio');

-- Find customers in specific states
SELECT CustomerName, State, City
FROM Customers
WHERE State IN ('CA', 'TX', 'IL');

-- NOT IN: Exclude specific values
SELECT ProductName, Category
FROM Products
WHERE Category NOT IN ('Accessories');

-- IN with numbers
SELECT ProductName, Price
FROM Products
WHERE ProductID IN (1, 3, 5, 7);
