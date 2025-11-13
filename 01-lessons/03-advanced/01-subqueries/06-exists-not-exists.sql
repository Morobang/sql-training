-- ========================================
-- EXISTS and NOT EXISTS
-- ========================================

USE TechStore;

-- EXISTS: Check if subquery returns any rows
-- More efficient than IN for large datasets

-- 1. Find customers who have made purchases
SELECT 
    CustomerName,
    City,
    State
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Sales s
    WHERE s.CustomerID = c.CustomerID
);

-- 2. Find customers who have NOT made purchases
SELECT 
    CustomerName,
    City,
    JoinDate
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales s
    WHERE s.CustomerID = c.CustomerID
);

-- 3. Find products that have been sold
SELECT 
    ProductName,
    Category,
    Price
FROM Products p
WHERE EXISTS (
    SELECT 1
    FROM Sales s
    WHERE s.ProductID = p.ProductID
);

-- 4. Find products that have NEVER been sold
SELECT 
    ProductName,
    Category,
    Price,
    StockQuantity
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales s
    WHERE s.ProductID = p.ProductID
)
ORDER BY Category, Price DESC;

-- 5. Find departments with employees
SELECT 
    DepartmentName,
    Location
FROM Departments d
WHERE EXISTS (
    SELECT 1
    FROM Employees e
    WHERE e.DepartmentID = d.DepartmentID
);

-- 6. Find categories with expensive products (>$100)
SELECT DISTINCT Category
FROM Products p1
WHERE EXISTS (
    SELECT 1
    FROM Products p2
    WHERE p2.Category = p1.Category
    AND p2.Price > 100
);

-- Performance Tip:
-- EXISTS vs IN:
-- - EXISTS stops at first match (faster)
-- - IN checks all values
-- - Use EXISTS for correlated subqueries
