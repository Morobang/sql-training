-- ========================================
-- NULL Filtering: IS NULL, IS NOT NULL
-- ========================================

USE TechStore;

-- Find employees without email
SELECT EmployeeID, DepartmentID, Email
FROM Employees
WHERE Email IS NULL;

-- Find employees with email
SELECT EmployeeID, DepartmentID, Email
FROM Employees
WHERE Email IS NOT NULL;

-- Find products without supplier
SELECT ProductName, SupplierID
FROM Products
WHERE SupplierID IS NULL;

-- Combining NULL check with other conditions
SELECT ProductName, Price, SupplierID
FROM Products
WHERE Price > 100 AND SupplierID IS NOT NULL;

-- ⚠️ WRONG: Cannot use = NULL
-- SELECT * FROM Employees WHERE Email = NULL;  -- This won't work!

-- ✅ CORRECT: Use IS NULL
SELECT * FROM Employees WHERE Email IS NULL;
