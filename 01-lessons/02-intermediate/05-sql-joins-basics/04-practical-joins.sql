-- ========================================
-- Practical JOIN Examples with TechStore
-- ========================================

USE TechStore;

-- 1. Customer purchase summary
SELECT 
    c.CustomerName,
    c.State,
    COUNT(s.SaleID) AS TotalOrders,
    SUM(s.TotalAmount) AS TotalSpent
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName, c.State
ORDER BY TotalSpent DESC;

-- 2. Product sales performance
SELECT 
    p.ProductName,
    p.Category,
    COUNT(s.SaleID) AS TimesSold,
    SUM(s.Quantity) AS TotalQuantitySold,
    SUM(s.TotalAmount) AS Revenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductName, p.Category
ORDER BY Revenue DESC;

-- 3. Department employee count and total salary
SELECT 
    d.DepartmentName,
    d.Location,
    COUNT(e.EmployeeID) AS EmployeeCount,
    SUM(e.Salary) AS TotalSalary,
    AVG(e.Salary) AS AvgSalary
FROM Departments d
INNER JOIN Employees e ON d.DepartmentID = e.DepartmentID
GROUP BY d.DepartmentName, d.Location;
