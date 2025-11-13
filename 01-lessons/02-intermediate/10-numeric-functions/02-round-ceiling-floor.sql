-- ========================================
-- Numeric Functions: ROUND, CEILING, FLOOR
-- ========================================

USE TechStore;

-- ROUND: Round to specified decimal places
SELECT 
    ProductName,
    Price,
    ROUND(Price, 0) AS RoundedPrice,
    ROUND(Price, 1) AS RoundedTo1Decimal
FROM Products;

-- CEILING: Round up to nearest integer
SELECT 
    ProductName,
    Price,
    CEILING(Price) AS RoundedUp
FROM Products;

-- FLOOR: Round down to nearest integer
SELECT 
    ProductName,
    Price,
    FLOOR(Price) AS RoundedDown
FROM Products;

-- Practical: Calculate tax (rounded)
SELECT 
    SaleID,
    TotalAmount,
    ROUND(TotalAmount * 0.08, 2) AS Tax,
    ROUND(TotalAmount * 1.08, 2) AS TotalWithTax
FROM Sales;
