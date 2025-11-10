-- ========================================
-- Window Functions: PARTITION BY
-- ========================================

USE TechStore;

-- PARTITION BY: Create separate windows per group
SELECT 
    ProductName,
    Category,
    Price,
    AVG(Price) OVER(PARTITION BY Category) AS AvgPriceInCategory
FROM Products
ORDER BY Category, Price;

-- Count products per category (keeps all rows)
SELECT 
    ProductName,
    Category,
    COUNT(*) OVER(PARTITION BY Category) AS ProductsInCategory
FROM Products;

-- Compare to category average
SELECT 
    ProductName,
    Category,
    Price,
    AVG(Price) OVER(PARTITION BY Category) AS CategoryAvg,
    Price - AVG(Price) OVER(PARTITION BY Category) AS DiffFromCategoryAvg
FROM Products
ORDER BY Category;

-- Multiple partitions
SELECT 
    c.CustomerName,
    c.State,
    s.TotalAmount,
    AVG(s.TotalAmount) OVER(PARTITION BY c.State) AS AvgSaleInState
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID;
