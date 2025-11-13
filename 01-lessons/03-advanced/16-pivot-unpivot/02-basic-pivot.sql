-- ========================================
-- PIVOT: Basic Examples
-- ========================================

USE TechStore;

-- =============================================
-- Example 1: Simple PIVOT - Sales by Category and Month
-- =============================================

-- Before PIVOT: Traditional GROUP BY
SELECT 
    p.Category,
    DATENAME(MONTH, s.SaleDate) AS Month,
    SUM(s.TotalAmount) AS Revenue
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.Category, DATENAME(MONTH, s.SaleDate)
ORDER BY p.Category, Month;

-- After PIVOT: Months as columns
SELECT *
FROM (
    SELECT 
        p.Category,
        DATENAME(MONTH, s.SaleDate) AS Month,
        s.TotalAmount
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([January], [February], [March], [April], [May], [June], 
                  [July], [August], [September], [October], [November], [December])
) AS PivotTable
ORDER BY Category;

-- 💡 PIVOT transforms rows into columns for easier reading

-- =============================================
-- Example 2: Sales by State and PaymentMethod
-- =============================================

-- Source query
SELECT 
    c.State,
    s.PaymentMethod,
    s.TotalAmount
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID;

-- PIVOT: Payment methods as columns
SELECT 
    State,
    ISNULL([Credit Card], 0) AS CreditCard,
    ISNULL([Cash], 0) AS Cash,
    ISNULL([PayPal], 0) AS PayPal,
    ISNULL([Credit Card], 0) + ISNULL([Cash], 0) + ISNULL([PayPal], 0) AS Total
FROM (
    SELECT 
        c.State,
        s.PaymentMethod,
        s.TotalAmount
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR PaymentMethod IN ([Credit Card], [Cash], [PayPal])
) AS PivotTable
ORDER BY State;

-- =============================================
-- Example 3: Product Count by Category and Price Range
-- =============================================

SELECT *
FROM (
    SELECT 
        Category,
        CASE 
            WHEN Price < 100 THEN 'Under $100'
            WHEN Price BETWEEN 100 AND 500 THEN '$100-$500'
            WHEN Price > 500 THEN 'Over $500'
        END AS PriceRange,
        ProductID
    FROM Products
) AS SourceData
PIVOT (
    COUNT(ProductID)
    FOR PriceRange IN ([Under $100], [$100-$500], [Over $500])
) AS PivotTable
ORDER BY Category;

-- =============================================
-- Example 4: Customer Purchase Patterns
-- =============================================

-- Show which customers bought from which categories
SELECT 
    CustomerName,
    ISNULL([Electronics], 0) AS Electronics,
    ISNULL([Clothing], 0) AS Clothing,
    ISNULL([Books], 0) AS Books,
    ISNULL([Toys], 0) AS Toys
FROM (
    SELECT 
        c.CustomerName,
        p.Category,
        s.SaleID
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
    INNER JOIN Products p ON s.ProductID = p.ProductID
) AS SourceData
PIVOT (
    COUNT(SaleID)
    FOR Category IN ([Electronics], [Clothing], [Books], [Toys])
) AS PivotTable
ORDER BY CustomerName;

-- =============================================
-- Example 5: Quarterly Revenue Report
-- =============================================

SELECT *
FROM (
    SELECT 
        YEAR(SaleDate) AS Year,
        'Q' + CAST(DATEPART(QUARTER, SaleDate) AS VARCHAR) AS Quarter,
        TotalAmount
    FROM Sales
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS PivotTable
ORDER BY Year;

-- =============================================
-- Example 6: Average Prices by Category and Supplier
-- =============================================

SELECT 
    Category,
    ISNULL([1], 0) AS Supplier1,
    ISNULL([2], 0) AS Supplier2,
    ISNULL([3], 0) AS Supplier3
FROM (
    SELECT 
        Category,
        SupplierID,
        Price
    FROM Products
    WHERE SupplierID IS NOT NULL
) AS SourceData
PIVOT (
    AVG(Price)
    FOR SupplierID IN ([1], [2], [3])
) AS PivotTable
ORDER BY Category;

-- =============================================
-- Example 7: Customer Activity Matrix
-- =============================================

-- Show order count per customer per month
SELECT 
    CustomerName,
    ISNULL([November], 0) AS Nov,
    ISNULL([December], 0) AS Dec,
    ISNULL([January], 0) AS Jan
FROM (
    SELECT 
        c.CustomerName,
        DATENAME(MONTH, s.SaleDate) AS Month,
        s.SaleID
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
) AS SourceData
PIVOT (
    COUNT(SaleID)
    FOR Month IN ([November], [December], [January])
) AS PivotTable
ORDER BY CustomerName;

-- 💡 Key Points:
-- - PIVOT requires aggregation (SUM, COUNT, AVG, etc.)
-- - Column list must be explicitly specified in IN clause
-- - Use ISNULL to handle NULL values in pivot results
-- - Source query determines which data gets pivoted
-- - Great for reports and cross-tabulation
