-- ========================================
-- Correlated Subqueries
-- ========================================

USE TechStore;

-- 1. Find products priced above their category average
SELECT 
    ProductName,
    Category,
    Price,
    (SELECT AVG(Price) 
     FROM Products p2 
     WHERE p2.Category = p1.Category) AS CategoryAvg
FROM Products p1
WHERE Price > (
    SELECT AVG(Price)
    FROM Products p2
    WHERE p2.Category = p1.Category
)
ORDER BY Category, Price DESC;

-- 2. Customers who spent more than their state average
SELECT 
    CustomerName,
    State,
    TotalPurchases,
    (SELECT AVG(TotalPurchases) 
     FROM Customers c2 
     WHERE c2.State = c1.State) AS StateAvg
FROM Customers c1
WHERE TotalPurchases > (
    SELECT AVG(TotalPurchases)
    FROM Customers c2
    WHERE c2.State = c1.State
    AND TotalPurchases > 0
);

-- 3. Products with above-average sales in their category
SELECT 
    p.ProductName,
    p.Category,
    (SELECT COUNT(*) 
     FROM Sales s 
     WHERE s.ProductID = p.ProductID) AS SalesCount
FROM Products p
WHERE (
    SELECT COUNT(*)
    FROM Sales s
    WHERE s.ProductID = p.ProductID
) > (
    SELECT AVG(SaleCount)
    FROM (
        SELECT COUNT(*) AS SaleCount
        FROM Sales s2
        INNER JOIN Products p2 ON s2.ProductID = p2.ProductID
        WHERE p2.Category = p.Category
        GROUP BY s2.ProductID
    ) AS CategorySales
);

-- 4. Employees earning more than department average
SELECT 
    e1.EmployeeID,
    e1.DepartmentID,
    e1.Salary,
    (SELECT AVG(Salary) 
     FROM Employees e2 
     WHERE e2.DepartmentID = e1.DepartmentID) AS DeptAvgSalary
FROM Employees e1
WHERE e1.Salary > (
    SELECT AVG(Salary)
    FROM Employees e2
    WHERE e2.DepartmentID = e1.DepartmentID
)
ORDER BY e1.DepartmentID, e1.Salary DESC;
