-- ========================================
-- NULL Functions: ISNULL
-- ========================================

USE TechStore;

-- ISNULL: Replace NULL with default value
-- ISNULL(column, replacement_value)

-- Replace NULL email with default
SELECT 
    EmployeeID,
    DepartmentID,
    ISNULL(Email, 'No Email') AS Email
FROM Employees;

-- Replace NULL phone with default
SELECT 
    EmployeeID,
    ISNULL(Phone, 'No Phone') AS Phone
FROM Employees;

-- Replace NULL numeric values
SELECT 
    ProductName,
    ISNULL(SupplierID, 0) AS SupplierID
FROM Products;

-- Practical: Display customer info with defaults
SELECT 
    CustomerName,
    ISNULL(City, 'Unknown') AS City,
    ISNULL(State, 'N/A') AS State,
    ISNULL(TotalPurchases, 0) AS TotalPurchases
FROM Customers;
