-- ========================================
-- Date Functions: GETDATE, YEAR, MONTH, DAY
-- ========================================

USE TechStore;

-- GETDATE: Current date and time
SELECT GETDATE() AS CurrentDateTime;

-- YEAR: Extract year
SELECT 
    SaleDate,
    YEAR(SaleDate) AS SaleYear
FROM Sales;

-- MONTH: Extract month
SELECT 
    SaleDate,
    MONTH(SaleDate) AS SaleMonth
FROM Sales;

-- DAY: Extract day
SELECT 
    SaleDate,
    DAY(SaleDate) AS SaleDay
FROM Sales;

-- Practical: Group sales by year and month
SELECT 
    YEAR(SaleDate) AS Year,
    MONTH(SaleDate) AS Month,
    COUNT(*) AS TotalSales,
    SUM(TotalAmount) AS Revenue
FROM Sales
GROUP BY YEAR(SaleDate), MONTH(SaleDate)
ORDER BY Year, Month;
