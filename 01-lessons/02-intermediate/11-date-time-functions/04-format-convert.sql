-- ========================================
-- Date Functions: FORMAT and CONVERT
-- ========================================

USE TechStore;

-- FORMAT: Custom date formatting
SELECT 
    SaleDate,
    FORMAT(SaleDate, 'yyyy-MM-dd') AS ISO_Format,
    FORMAT(SaleDate, 'MM/dd/yyyy') AS US_Format,
    FORMAT(SaleDate, 'MMMM dd, yyyy') AS LongFormat,
    FORMAT(SaleDate, 'MMM dd') AS ShortFormat
FROM Sales;

-- CONVERT: Convert date to string
SELECT 
    SaleDate,
    CONVERT(VARCHAR, SaleDate, 101) AS US_Style,
    CONVERT(VARCHAR, SaleDate, 103) AS UK_Style,
    CONVERT(VARCHAR, SaleDate, 120) AS ISO_Style
FROM Sales;

-- Practical: Create readable date labels
SELECT 
    SaleID,
    FORMAT(SaleDate, 'MMMM dd, yyyy') AS SaleDate,
    TotalAmount
FROM Sales
ORDER BY SaleDate DESC;
