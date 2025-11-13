-- ========================================
-- Window Functions: ORDER BY in Window
-- ========================================

USE TechStore;

-- ORDER BY creates cumulative/running calculations
SELECT 
    ProductName,
    Category,
    Price,
    ROW_NUMBER() OVER(ORDER BY Price) AS PriceRank
FROM Products;

-- Order within partition
SELECT 
    ProductName,
    Category,
    Price,
    ROW_NUMBER() OVER(PARTITION BY Category ORDER BY Price DESC) AS RankInCategory
FROM Products;

-- Running total (cumulative sum)
SELECT 
    SaleDate,
    TotalAmount,
    SUM(TotalAmount) OVER(ORDER BY SaleDate) AS RunningTotal
FROM Sales
ORDER BY SaleDate;

-- Running average
SELECT 
    SaleDate,
    TotalAmount,
    AVG(TotalAmount) OVER(ORDER BY SaleDate) AS RunningAverage
FROM Sales
ORDER BY SaleDate;
