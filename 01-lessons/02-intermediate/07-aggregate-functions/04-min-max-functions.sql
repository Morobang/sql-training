-- ========================================
-- MIN and MAX: Find Smallest and Largest Values
-- ========================================

USE TechStore;

-- Cheapest and most expensive product
SELECT 
    MIN(Price) AS CheapestPrice,
    MAX(Price) AS MostExpensivePrice
FROM Products;

-- Lowest and highest salary
SELECT 
    MIN(Salary) AS LowestSalary,
    MAX(Salary) AS HighestSalary
FROM Employees;

-- First and last sale date
SELECT 
    MIN(SaleDate) AS FirstSale,
    MAX(SaleDate) AS LatestSale
FROM Sales;

-- MIN/MAX by group
SELECT 
    Category,
    MIN(Price) AS CheapestInCategory,
    MAX(Price) AS MostExpensiveInCategory
FROM Products
GROUP BY Category;
