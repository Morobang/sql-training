-- ========================================
-- CTE vs Subquery: Side-by-Side Comparison
-- ========================================

USE TechStore;

-- =============================================
-- Example 1: Category Analysis
-- =============================================

-- Using SUBQUERY (harder to read, repeated logic)
SELECT 
    p.ProductName,
    p.Category,
    p.Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.Category = p.Category) AS CategoryAvg,
    p.Price - (SELECT AVG(Price) FROM Products p2 WHERE p2.Category = p.Category) AS DiffFromAvg
FROM Products p
WHERE p.Price > (SELECT AVG(Price) FROM Products p2 WHERE p2.Category = p.Category)
ORDER BY p.Category, p.Price DESC;

-- Using CTE (cleaner, more readable)
WITH CategoryStats AS (
    SELECT 
        Category,
        AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY Category
)
SELECT 
    p.ProductName,
    p.Category,
    p.Price,
    cs.AvgPrice AS CategoryAvg,
    p.Price - cs.AvgPrice AS DiffFromAvg
FROM Products p
INNER JOIN CategoryStats cs ON p.Category = cs.Category
WHERE p.Price > cs.AvgPrice
ORDER BY p.Category, p.Price DESC;

-- =============================================
-- Example 2: Customer Purchase Ranking
-- =============================================

-- Using SUBQUERY (nested, complex)
SELECT 
    c.CustomerName,
    (SELECT COUNT(*) FROM Sales s WHERE s.CustomerID = c.CustomerID) AS OrderCount,
    (SELECT SUM(TotalAmount) FROM Sales s WHERE s.CustomerID = c.CustomerID) AS TotalSpent,
    CASE 
        WHEN (SELECT SUM(TotalAmount) FROM Sales s WHERE s.CustomerID = c.CustomerID) >= 500 THEN 'VIP'
        ELSE 'Regular'
    END AS Tier
FROM Customers c
WHERE (SELECT COUNT(*) FROM Sales s WHERE s.CustomerID = c.CustomerID) > 0
ORDER BY (SELECT SUM(TotalAmount) FROM Sales s WHERE s.CustomerID = c.CustomerID) DESC;

-- Using CTE (organized, reusable)
WITH CustomerStats AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Sales
    GROUP BY CustomerID
)
SELECT 
    c.CustomerName,
    cs.OrderCount,
    cs.TotalSpent,
    CASE 
        WHEN cs.TotalSpent >= 500 THEN 'VIP'
        ELSE 'Regular'
    END AS Tier
FROM Customers c
INNER JOIN CustomerStats cs ON c.CustomerID = cs.CustomerID
ORDER BY cs.TotalSpent DESC;

-- =============================================
-- Example 3: Multi-Level Aggregation
-- =============================================

-- Using SUBQUERY (deeply nested, hard to debug)
SELECT 
    Category,
    ProductCount,
    TotalRevenue
FROM (
    SELECT 
        p.Category,
        COUNT(DISTINCT p.ProductID) AS ProductCount,
        SUM(s.TotalAmount) AS TotalRevenue
    FROM Products p
    LEFT JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.Category
) AS CategorySales
WHERE TotalRevenue > (
    SELECT AVG(Revenue)
    FROM (
        SELECT SUM(TotalAmount) AS Revenue
        FROM Sales
        GROUP BY ProductID
    ) AS ProductRevenue
);

-- Using CTE (step-by-step, clear logic)
WITH 
ProductRevenue AS (
    SELECT 
        ProductID,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY ProductID
),
AvgProductRevenue AS (
    SELECT AVG(Revenue) AS AvgRevenue
    FROM ProductRevenue
),
CategorySales AS (
    SELECT 
        p.Category,
        COUNT(DISTINCT p.ProductID) AS ProductCount,
        SUM(s.TotalAmount) AS TotalRevenue
    FROM Products p
    LEFT JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.Category
)
SELECT 
    cs.Category,
    cs.ProductCount,
    cs.TotalRevenue,
    apr.AvgRevenue AS AvgProductRevenue
FROM CategorySales cs
CROSS JOIN AvgProductRevenue apr
WHERE cs.TotalRevenue > apr.AvgRevenue;

-- 💡 Key Takeaways:
-- - CTEs are more readable for complex queries
-- - CTEs are easier to debug (test each CTE separately)
-- - Subqueries are fine for simple, one-time operations
-- - Performance is usually similar (optimizer handles both)
-- - Use CTEs when logic is reused multiple times
