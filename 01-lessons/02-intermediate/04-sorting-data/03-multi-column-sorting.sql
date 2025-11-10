-- ========================================
-- ORDER BY Multiple Columns
-- ========================================

USE TechStore;

-- Sort by Category, then by Price within each category
SELECT ProductName, Category, Price
FROM Products
ORDER BY Category, Price;

-- Sort by Category (A-Z), then Price (high to low)
SELECT ProductName, Category, Price
FROM Products
ORDER BY Category ASC, Price DESC;

-- Sort customers by State, then by Name
SELECT CustomerName, State, City
FROM Customers
ORDER BY State, CustomerName;
