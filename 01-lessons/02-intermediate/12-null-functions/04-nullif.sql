-- ========================================
-- NULL Functions: NULLIF
-- ========================================

USE TechStore;

-- NULLIF: Return NULL if two values are equal
-- NULLIF(value1, value2)
-- Returns NULL if value1 = value2, otherwise returns value1

-- Convert 0 to NULL
SELECT 
    ProductName,
    StockQuantity,
    NULLIF(StockQuantity, 0) AS StockOrNull
FROM Products;

-- Prevent division by zero
SELECT 
    ProductName,
    Price,
    Cost,
    Price / NULLIF(Cost, 0) AS PriceTocosta
FROM Products;

-- Practical: Handle empty strings
SELECT 
    EmployeeID,
    NULLIF(Email, '') AS Email  -- Convert empty string to NULL
FROM Employees;

-- Combined with COALESCE
SELECT 
    ProductName,
    COALESCE(NULLIF(SupplierID, 0), 999) AS SupplierID
FROM Products;
-- If SupplierID is 0, convert to NULL, then replace with 999
