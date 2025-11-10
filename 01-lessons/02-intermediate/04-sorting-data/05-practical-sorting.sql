-- ========================================
-- Practical Sorting Examples
-- ========================================

USE TechStore;

-- Top 5 most expensive products
SELECT TOP 5 ProductName, Price
FROM Products
ORDER BY Price DESC;

-- Customers sorted by join date (newest members first)
SELECT CustomerName, JoinDate
FROM Customers
ORDER BY JoinDate DESC;

-- Employees sorted by salary (highest paid first)
SELECT EmployeeID, DepartmentID, Salary
FROM Employees
ORDER BY Salary DESC;

-- Sales sorted by amount (biggest sales first)
SELECT SaleID, CustomerID, TotalAmount, SaleDate
FROM Sales
ORDER BY TotalAmount DESC;
