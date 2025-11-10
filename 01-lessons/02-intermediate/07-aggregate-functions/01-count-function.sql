-- ========================================
-- COUNT: Count Rows and Non-NULL Values
-- ========================================

USE TechStore;

-- Count all rows
SELECT COUNT(*) AS TotalProducts
FROM Products;

-- Count non-NULL values in a column
SELECT COUNT(Email) AS EmployeesWithEmail
FROM Employees;

-- Count with WHERE filter
SELECT COUNT(*) AS ExpensiveProducts
FROM Products
WHERE Price > 100;

-- Count distinct values
SELECT COUNT(DISTINCT Category) AS UniqueCategories
FROM Products;

-- Count by group
SELECT 
    Category,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY Category;
