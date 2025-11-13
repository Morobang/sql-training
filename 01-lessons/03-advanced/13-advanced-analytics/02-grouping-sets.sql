-- ========================================
-- GROUPING SETS - TechStore examples
-- ========================================

USE TechStore;
GO

-- Sample dataset: Monthly category sales
WITH MonthlyCategorySales AS (
    SELECT
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        p.Category,
        SUM(s.TotalAmount) AS Revenue
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY YEAR(SaleDate), MONTH(SaleDate), p.Category
)
SELECT
    SaleYear,
    SaleMonth,
    Category,
    SUM(Revenue) AS Revenue
FROM MonthlyCategorySales
GROUP BY GROUPING SETS (
    (SaleYear, SaleMonth, Category),   -- detailed
    (SaleYear, SaleMonth),             -- subtotal by month
    (Category),                        -- subtotal by category across time
    ()                                  -- grand total
)
ORDER BY SaleYear, SaleMonth, Category;
GO

-- Use GROUPING() to label rows
SELECT
    SaleYear,
    SaleMonth,
    Category,
    SUM(Revenue) AS Revenue,
    GROUPING(SaleYear) AS IsYearTotal,
    GROUPING(SaleMonth) AS IsMonthTotal,
    GROUPING(Category) AS IsCategoryTotal
FROM MonthlyCategorySales
GROUP BY GROUPING SETS (
    (SaleYear, SaleMonth, Category),
    (SaleYear, SaleMonth),
    (Category),
    ()
)
ORDER BY SaleYear, SaleMonth, Category;
GO

-- Real-world reporting: combine with CASE for readable labels
SELECT
    CASE WHEN GROUPING(SaleYear)=1 AND GROUPING(SaleMonth)=1 AND GROUPING(Category)=1 THEN 'Grand Total'
         WHEN GROUPING(SaleYear)=1 AND GROUPING(SaleMonth)=1 THEN 'Category Total'
         WHEN GROUPING(Category)=1 THEN CONCAT('Month Total ', SaleYear, '-', SaleMonth)
         ELSE CONCAT('Detail ', SaleYear, '-', SaleMonth, ' - ', Category)
    END AS RowLabel,
    SUM(Revenue) AS Revenue
FROM MonthlyCategorySales
GROUP BY GROUPING SETS (
    (SaleYear, SaleMonth, Category),
    (SaleYear, SaleMonth),
    (Category),
    ()
)
ORDER BY RowLabel;
GO
