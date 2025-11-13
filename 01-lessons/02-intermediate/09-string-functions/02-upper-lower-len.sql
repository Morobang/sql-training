-- ========================================
-- String Functions: UPPER, LOWER, LEN
-- ========================================

USE TechStore;

-- UPPER: Convert to uppercase
SELECT 
    CustomerName,
    UPPER(CustomerName) AS UpperCase
FROM Customers;

-- LOWER: Convert to lowercase
SELECT 
    ProductName,
    LOWER(ProductName) AS LowerCase
FROM Products;

-- LEN: Get string length
SELECT 
    ProductName,
    LEN(ProductName) AS NameLength
FROM Products;

-- Practical: Standardize data
SELECT 
    UPPER(City) AS City,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY UPPER(City);
