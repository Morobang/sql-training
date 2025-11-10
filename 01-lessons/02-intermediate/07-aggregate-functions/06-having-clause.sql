-- ========================================
-- HAVING: Filter Grouped Results
-- ========================================

USE TechStore;

-- Categories with more than 2 products
SELECT 
    Category,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY Category
HAVING COUNT(*) > 2;

-- Customers who spent more than $200
SELECT 
    CustomerID,
    SUM(TotalAmount) AS TotalSpent
FROM Sales
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 200
ORDER BY TotalSpent DESC;

-- Payment methods used more than once
SELECT 
    PaymentMethod,
    COUNT(*) AS UsageCount
FROM Sales
GROUP BY PaymentMethod
HAVING COUNT(*) > 1;

-- WHERE vs HAVING:
-- WHERE filters BEFORE grouping
-- HAVING filters AFTER grouping

-- Example: Categories with avg price > $100, only active products
SELECT 
    Category,
    AVG(Price) AS AvgPrice
FROM Products
WHERE IsActive = 1  -- Filter before grouping
GROUP BY Category
HAVING AVG(Price) > 100;  -- Filter after grouping
