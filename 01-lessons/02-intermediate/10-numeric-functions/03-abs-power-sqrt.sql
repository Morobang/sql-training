-- ========================================
-- Numeric Functions: ABS, POWER, SQRT
-- ========================================

USE TechStore;

-- ABS: Absolute value (remove negative sign)
SELECT 
    ProductName,
    Price,
    Cost,
    Price - Cost AS Profit,
    ABS(Price - Cost) AS AbsoluteProfit
FROM Products;

-- POWER: Raise to power
SELECT 
    ProductName,
    StockQuantity,
    POWER(StockQuantity, 2) AS QuantitySquared
FROM Products;

-- SQRT: Square root
SELECT 
    ProductName,
    StockQuantity,
    SQRT(StockQuantity) AS SquareRoot
FROM Products;

-- Practical: Calculate percentage difference
SELECT 
    ProductName,
    Price,
    Cost,
    ROUND(((Price - Cost) / Cost) * 100, 2) AS ProfitPercentage
FROM Products
WHERE Cost > 0;
