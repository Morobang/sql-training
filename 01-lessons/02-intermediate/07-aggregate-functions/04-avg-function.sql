-- ========================================
-- AVG: Average of Numeric Values
-- ========================================

USE TechStore;

-- Average product price
SELECT AVG(Price) AS AveragePrice
FROM Products;

-- Average employee salary
SELECT AVG(Salary) AS AverageSalary
FROM Employees;

-- Average sale amount
SELECT AVG(TotalAmount) AS AverageSaleAmount
FROM Sales;

-- Average by group
SELECT 
    Category,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY Category;

-- Average with rounding
SELECT 
    Category,
    ROUND(AVG(Price), 2) AS AvgPrice
FROM Products
GROUP BY Category;
