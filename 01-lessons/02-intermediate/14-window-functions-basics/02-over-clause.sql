-- ========================================
-- Window Functions: OVER Clause Basics
-- ========================================

USE TechStore;

-- OVER(): Apply function across all rows
SELECT 
    ProductName,
    Price,
    AVG(Price) OVER() AS AvgPriceAllProducts
FROM Products;

-- Compare each product to average
SELECT 
    ProductName,
    Category,
    Price,
    AVG(Price) OVER() AS OverallAvg,
    Price - AVG(Price) OVER() AS DifferenceFromAvg
FROM Products;

-- Count with OVER
SELECT 
    ProductName,
    Category,
    COUNT(*) OVER() AS TotalProductCount
FROM Products;

-- Window function vs GROUP BY:
-- GROUP BY collapses rows
-- OVER() keeps all rows
