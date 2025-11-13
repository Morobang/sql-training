-- ========================================
-- Subqueries in SELECT Clause
-- ========================================

USE TechStore;

-- 1. Show each product with category average
SELECT 
    ProductName,
    Category,
    Price,
    (SELECT AVG(Price) 
     FROM Products p2 
     WHERE p2.Category = p1.Category) AS CategoryAvg,
    Price - (SELECT AVG(Price) 
             FROM Products p2 
             WHERE p2.Category = p1.Category) AS DiffFromAvg
FROM Products p1
ORDER BY Category, Price DESC;

-- 2. Show customer purchase count
SELECT 
    CustomerName,
    City,
    (SELECT COUNT(*) 
     FROM Sales s 
     WHERE s.CustomerID = c.CustomerID) AS TotalOrders,
    (SELECT SUM(TotalAmount) 
     FROM Sales s 
     WHERE s.CustomerID = c.CustomerID) AS TotalSpent
FROM Customers c
ORDER BY TotalSpent DESC;

-- 3. Show product with sales count
SELECT 
    ProductName,
    Price,
    StockQuantity,
    (SELECT COUNT(*) 
     FROM Sales s 
     WHERE s.ProductID = p.ProductID) AS TimesSold,
    (SELECT SUM(Quantity) 
     FROM Sales s 
     WHERE s.ProductID = p.ProductID) AS TotalQuantitySold
FROM Products p
ORDER BY TimesSold DESC;

-- 4. Department employee statistics
SELECT 
    DepartmentName,
    Location,
    (SELECT COUNT(*) 
     FROM Employees e 
     WHERE e.DepartmentID = d.DepartmentID) AS EmployeeCount,
    (SELECT AVG(Salary) 
     FROM Employees e 
     WHERE e.DepartmentID = d.DepartmentID) AS AvgSalary
FROM Departments d;
