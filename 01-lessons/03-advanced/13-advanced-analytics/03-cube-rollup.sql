-- ========================================
-- CUBE and ROLLUP examples - TechStore
-- ========================================

USE TechStore;
GO

-- ROLLUP example: Year -> Month -> Category hierarchy
SELECT
    YEAR(SaleDate) AS SaleYear,
    MONTH(SaleDate) AS SaleMonth,
    p.Category,
    SUM(s.TotalAmount) AS Revenue,
    GROUPING_ID(YEAR(SaleDate), MONTH(SaleDate), p.Category) AS gid
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY ROLLUP (YEAR(SaleDate), MONTH(SaleDate), p.Category)
ORDER BY SaleYear, SaleMonth, p.Category;
GO

-- CUBE example: Year, Category, PaymentMethod - all combinations
SELECT
    YEAR(SaleDate) AS SaleYear,
    p.Category,
    s.PaymentMethod,
    SUM(s.TotalAmount) AS Revenue,
    GROUPING_ID(YEAR(SaleDate), p.Category, s.PaymentMethod) AS gid
FROM Sales s
JOIN Products p ON s.ProductID = p.ProductID
GROUP BY CUBE (YEAR(SaleDate), p.Category, s.PaymentMethod)
ORDER BY SaleYear, p.Category, s.PaymentMethod;
GO

-- Decode grouping_id for readability (example for 3 columns)
SELECT
    SaleYear,
    Category,
    PaymentMethod,
    Revenue,
    gid,
    CASE WHEN (gid & 4) = 4 THEN 'Year_Agg' ELSE 'Year_Detail' END AS YearLevel,
    CASE WHEN (gid & 2) = 2 THEN 'Category_Agg' ELSE 'Category_Detail' END AS CategoryLevel,
    CASE WHEN (gid & 1) = 1 THEN 'Payment_Agg' ELSE 'Payment_Detail' END AS PaymentLevel
FROM (
    SELECT
        YEAR(SaleDate) AS SaleYear,
        p.Category,
        s.PaymentMethod,
        SUM(s.TotalAmount) AS Revenue,
        GROUPING_ID(YEAR(SaleDate), p.Category, s.PaymentMethod) AS gid
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY CUBE (YEAR(SaleDate), p.Category, s.PaymentMethod)
) t
ORDER BY gid, SaleYear, Category, PaymentMethod;
GO
