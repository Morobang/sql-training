-- ========================================
-- String Functions: TRIM, LTRIM, RTRIM
-- ========================================

USE TechStore;

-- TRIM: Remove spaces from both sides
SELECT 
    '   Hello World   ' AS Original,
    TRIM('   Hello World   ') AS Trimmed;

-- LTRIM: Remove left spaces
SELECT 
    '   Hello' AS Original,
    LTRIM('   Hello') AS LeftTrimmed;

-- RTRIM: Remove right spaces
SELECT 
    'Hello   ' AS Original,
    RTRIM('Hello   ') AS RightTrimmed;

-- Practical: Clean customer names
SELECT 
    CustomerName,
    TRIM(CustomerName) AS CleanName
FROM Customers;
