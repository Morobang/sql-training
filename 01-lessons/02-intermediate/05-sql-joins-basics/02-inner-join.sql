-- ========================================
-- INNER JOIN Basics: Combine Two Tables
-- ========================================

USE TechStore;

-- Join Sales with Customers
SELECT 
    s.SaleID,
    c.CustomerName,
    s.TotalAmount,
    s.SaleDate
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID;

-- Join Sales with Products
SELECT 
    s.SaleID,
    p.ProductName,
    s.Quantity,
    s.TotalAmount
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID;

-- Join Employees with Departments
SELECT 
    e.EmployeeID,
    d.DepartmentName,
    e.Salary
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID;
