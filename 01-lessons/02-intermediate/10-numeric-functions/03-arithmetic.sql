-- ========================================
-- Numeric Functions: Arithmetic Operations
-- ========================================

USE TechStore;

-- Basic arithmetic: +, -, *, /
SELECT 
    ProductName,
    Price,
    Quantity,
    Price * Quantity AS Subtotal,
    Price * Quantity * 0.08 AS Tax,
    Price * Quantity * 1.08 AS Total
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID;

-- Modulo: % (remainder after division)
SELECT 
    ProductID,
    ProductID % 2 AS Remainder,
    CASE 
        WHEN ProductID % 2 = 0 THEN 'Even'
        ELSE 'Odd'
    END AS EvenOrOdd
FROM Products;

-- Practical: Calculate profit margin
SELECT 
    ProductName,
    Price,
    Cost,
    Price - Cost AS Profit,
    ROUND(((Price - Cost) / Price) * 100, 2) AS MarginPercentage
FROM Products
WHERE Price > 0;
