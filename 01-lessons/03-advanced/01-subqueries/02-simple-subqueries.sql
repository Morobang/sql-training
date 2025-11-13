-- ========================================
-- Simple Subqueries in WHERE Clause
-- ========================================

USE TechStore;

-- 1. Find products priced above average
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products)
ORDER BY Price DESC;

-- 2. Find most expensive product in each category
SELECT 
    ProductName,
    Category,
    Price
FROM Products p1
WHERE Price = (
    SELECT MAX(Price)
    FROM Products p2
    WHERE p2.Category = p1.Category
);

-- 3. Find customers who spent more than average
SELECT 
    CustomerName,
    TotalPurchases
FROM Customers
WHERE TotalPurchases > (
    SELECT AVG(TotalPurchases)
    FROM Customers
    WHERE TotalPurchases > 0
);

-- 4. Find employees with above-average salary
SELECT 
    EmployeeID,
    DepartmentID,
    Salary
FROM Employees
WHERE Salary > (SELECT AVG(Salary) FROM Employees)
ORDER BY Salary DESC;
