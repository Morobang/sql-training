-- ========================================
-- String Functions: REPLACE and CHARINDEX
-- ========================================

USE TechStore;

-- REPLACE: Replace substring
SELECT 
    ProductName,
    REPLACE(ProductName, 'Pro', 'Professional') AS UpdatedName
FROM Products;

-- CHARINDEX: Find position of substring
SELECT 
    ProductName,
    CHARINDEX('USB', ProductName) AS USBPosition
FROM Products;

-- Practical: Standardize product names
SELECT 
    ProductName,
    REPLACE(ProductName, 'Wireless', 'WiFi') AS StandardizedName
FROM Products
WHERE ProductName LIKE '%Wireless%';

-- Check if string contains substring
SELECT 
    ProductName,
    CASE 
        WHEN CHARINDEX('Pro', ProductName) > 0 THEN 'Professional Product'
        ELSE 'Standard Product'
    END AS ProductTier
FROM Products;
