-- ========================================
-- String Functions: SUBSTRING and LEFT/RIGHT
-- ========================================

USE TechStore;

-- SUBSTRING: Extract part of string
-- SUBSTRING(string, start_position, length)
SELECT 
    ProductName,
    SUBSTRING(ProductName, 1, 8) AS First8Chars
FROM Products;

-- LEFT: Get leftmost characters
SELECT 
    CustomerName,
    LEFT(CustomerName, 4) AS FirstName
FROM Customers;

-- RIGHT: Get rightmost characters
SELECT 
    ProductName,
    RIGHT(ProductName, 3) AS Last3Chars
FROM Products;

-- Practical: Extract category prefix
SELECT 
    ProductName,
    LEFT(ProductName, 10) AS ShortName
FROM Products;
