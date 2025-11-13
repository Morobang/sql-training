-- ========================================
-- GROUP BY: Group Rows for Aggregation
-- ========================================

USE TechStore;

-- Count products per category
SELECT 
    Category,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY Category;

-- Total sales per customer
SELECT 
    CustomerID,
    COUNT(SaleID) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Sales
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

-- Average salary per department
SELECT 
    DepartmentID,
    COUNT(*) AS EmployeeCount,
    AVG(Salary) AS AvgSalary,
    MIN(Salary) AS MinSalary,
    MAX(Salary) AS MaxSalary
FROM Employees
GROUP BY DepartmentID;

-- Sales summary by payment method
SELECT 
    PaymentMethod,
    COUNT(*) AS TransactionCount,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AvgTransaction
FROM Sales
GROUP BY PaymentMethod;
