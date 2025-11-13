-- ========================================
-- Window Functions: ROW_NUMBER, RANK, DENSE_RANK
-- ========================================

USE TechStore;

-- ROW_NUMBER: Unique sequential number
SELECT 
    ProductName,
    Price,
    ROW_NUMBER() OVER(ORDER BY Price DESC) AS RowNum
FROM Products;

-- RANK: Same rank for ties, skips numbers
SELECT 
    ProductName,
    Price,
    RANK() OVER(ORDER BY Price DESC) AS PriceRank
FROM Products;

-- DENSE_RANK: Same rank for ties, no gaps
SELECT 
    ProductName,
    Price,
    DENSE_RANK() OVER(ORDER BY Price DESC) AS DenseRank
FROM Products;

-- Compare all three
SELECT 
    ProductName,
    Price,
    ROW_NUMBER() OVER(ORDER BY Price DESC) AS RowNum,
    RANK() OVER(ORDER BY Price DESC) AS Rank,
    DENSE_RANK() OVER(ORDER BY Price DESC) AS DenseRank
FROM Products;

-- Rank within categories
SELECT 
    ProductName,
    Category,
    Price,
    RANK() OVER(PARTITION BY Category ORDER BY Price DESC) AS RankInCategory
FROM Products
ORDER BY Category, RankInCategory;
