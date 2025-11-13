-- ========================================
-- NULL Functions: IS NULL, IS NOT NULL
-- ========================================

USE TechStore;

-- Find NULL values
SELECT 
    EmployeeID,
    DepartmentID,
    Email,
    Phone
FROM Employees
WHERE Email IS NULL;

-- Find non-NULL values
SELECT 
    EmployeeID,
    DepartmentID,
    Email
FROM Employees
WHERE Email IS NOT NULL;

-- Count NULLs
SELECT 
    COUNT(*) AS TotalEmployees,
    COUNT(Email) AS WithEmail,
    COUNT(*) - COUNT(Email) AS WithoutEmail
FROM Employees;

-- Filter products without supplier
SELECT 
    ProductName,
    Price,
    SupplierID
FROM Products
WHERE SupplierID IS NULL;
