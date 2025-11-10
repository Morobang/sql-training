-- ========================================
-- SELF JOIN: Join a Table to Itself
-- ========================================

USE TechStore;

-- Find employees in the same department
SELECT 
    e1.EmployeeID AS Employee1_ID,
    e2.EmployeeID AS Employee2_ID,
    e1.DepartmentID
FROM Employees e1
INNER JOIN Employees e2 ON e1.DepartmentID = e2.DepartmentID
WHERE e1.EmployeeID < e2.EmployeeID  -- Avoid duplicates
ORDER BY e1.DepartmentID;

-- Find products in the same category
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    p1.Category
FROM Products p1
INNER JOIN Products p2 ON p1.Category = p2.Category
WHERE p1.ProductID < p2.ProductID
ORDER BY p1.Category;

-- Find customers in the same city
SELECT 
    c1.CustomerName AS Customer1,
    c2.CustomerName AS Customer2,
    c1.City
FROM Customers c1
INNER JOIN Customers c2 ON c1.City = c2.City
WHERE c1.CustomerID < c2.CustomerID
ORDER BY c1.City;
