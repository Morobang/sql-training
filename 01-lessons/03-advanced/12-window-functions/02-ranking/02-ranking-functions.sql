-- ========================================
-- Ranking Window Functions
-- ROW_NUMBER, RANK, DENSE_RANK, NTILE
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: ROW_NUMBER - Unique Sequential Numbers
-- =============================================

-- Assign unique row numbers
SELECT 
    ProductID,
    ProductName,
    Price,
    ROW_NUMBER() OVER (ORDER BY Price DESC) AS RowNum
FROM Products
ORDER BY Price DESC;
GO

-- Row numbers per category
SELECT 
    Category,
    ProductName,
    Price,
    ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Price DESC) AS CategoryRowNum
FROM Products
ORDER BY Category, Price DESC;
GO

-- =============================================
-- Example 2: RANK - With Gaps for Ties
-- =============================================

-- Olympic-style ranking (1, 2, 2, 4...)
SELECT 
    ProductName,
    Price,
    RANK() OVER (ORDER BY Price DESC) AS PriceRank
FROM Products
ORDER BY Price DESC;
-- If two products have same price: 1, 2, 2, 4, 5 (rank 3 skipped)
GO

-- Rank products within each category
SELECT 
    Category,
    ProductName,
    Price,
    RANK() OVER (PARTITION BY Category ORDER BY Price DESC) AS CategoryRank
FROM Products
ORDER BY Category, Price DESC;
GO

-- =============================================
-- Example 3: DENSE_RANK - No Gaps for Ties
-- =============================================

-- Continuous ranking (1, 2, 2, 3...)
SELECT 
    ProductName,
    Price,
    DENSE_RANK() OVER (ORDER BY Price DESC) AS DenseRank
FROM Products
ORDER BY Price DESC;
-- If two products have same price: 1, 2, 2, 3, 4 (no gaps)
GO

-- Dense rank by category
SELECT 
    Category,
    ProductName,
    Price,
    DENSE_RANK() OVER (PARTITION BY Category ORDER BY Price DESC) AS CategoryDenseRank
FROM Products
ORDER BY Category, Price DESC;
GO

-- =============================================
-- Example 4: Comparing Ranking Functions
-- =============================================

-- All three ranking functions side-by-side
SELECT 
    ProductName,
    Price,
    ROW_NUMBER() OVER (ORDER BY Price DESC) AS RowNum,
    RANK() OVER (ORDER BY Price DESC) AS Rank,
    DENSE_RANK() OVER (ORDER BY Price DESC) AS DenseRank
FROM Products
ORDER BY Price DESC;
GO

-- Visualize difference with duplicate prices
SELECT 
    Category,
    Price,
    COUNT(*) AS ProductCnt,
    ROW_NUMBER() OVER (ORDER BY Price DESC) AS RowNum,
    RANK() OVER (ORDER BY Price DESC) AS Rank,
    DENSE_RANK() OVER (ORDER BY Price DESC) AS DenseRank
FROM Products
GROUP BY Category, Price
ORDER BY Price DESC;
GO

-- =============================================
-- Example 5: NTILE - Divide into Buckets
-- =============================================

-- Divide products into 4 price quartiles
SELECT 
    ProductName,
    Price,
    NTILE(4) OVER (ORDER BY Price) AS PriceQuartile
FROM Products
ORDER BY Price;
GO

-- Quartile labels
SELECT 
    ProductName,
    Price,
    NTILE(4) OVER (ORDER BY Price) AS Quartile,
    CASE NTILE(4) OVER (ORDER BY Price)
        WHEN 1 THEN 'Bottom 25%'
        WHEN 2 THEN 'Lower Middle 25%'
        WHEN 3 THEN 'Upper Middle 25%'
        WHEN 4 THEN 'Top 25%'
    END AS QuartileLabel
FROM Products
ORDER BY Price;
GO

-- Deciles (10 buckets)
SELECT 
    ProductName,
    Price,
    NTILE(10) OVER (ORDER BY Price) AS PriceDecile
FROM Products
ORDER BY Price;
GO

-- =============================================
-- Example 6: Top-N Per Group
-- =============================================

-- Top 3 most expensive products per category
WITH RankedProducts AS (
    SELECT 
        Category,
        ProductName,
        Price,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Price DESC) AS Rank
    FROM Products
)
SELECT Category, ProductName, Price
FROM RankedProducts
WHERE Rank <= 3
ORDER BY Category, Rank;
GO

-- Top 5 customers by total purchases
WITH RankedCustomers AS (
    SELECT 
        CustomerID,
        CustomerName,
        TotalPurchases,
        ROW_NUMBER() OVER (ORDER BY TotalPurchases DESC) AS Rank
    FROM Customers
)
SELECT CustomerID, CustomerName, TotalPurchases
FROM RankedCustomers
WHERE Rank <= 5
ORDER BY Rank;
GO

-- =============================================
-- Example 7: Bottom-N Per Group
-- =============================================

-- 3 cheapest products per category
WITH RankedProducts AS (
    SELECT 
        Category,
        ProductName,
        Price,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Price ASC) AS Rank
    FROM Products
)
SELECT Category, ProductName, Price
FROM RankedProducts
WHERE Rank <= 3
ORDER BY Category, Rank;
GO

-- =============================================
-- Example 8: Pagination with ROW_NUMBER
-- =============================================

-- Page 1 (rows 1-10)
WITH Paginated AS (
    SELECT 
        ProductID,
        ProductName,
        Price,
        ROW_NUMBER() OVER (ORDER BY ProductName) AS RowNum
    FROM Products
)
SELECT ProductID, ProductName, Price
FROM Paginated
WHERE RowNum BETWEEN 1 AND 10
ORDER BY RowNum;
GO

-- Page 2 (rows 11-20)
WITH Paginated AS (
    SELECT 
        ProductID,
        ProductName,
        Price,
        ROW_NUMBER() OVER (ORDER BY ProductName) AS RowNum
    FROM Products
)
SELECT ProductID, ProductName, Price
FROM Paginated
WHERE RowNum BETWEEN 11 AND 20
ORDER BY RowNum;
GO

-- Generic pagination function
DECLARE @PageNumber INT = 2;
DECLARE @PageSize INT = 10;

WITH Paginated AS (
    SELECT 
        ProductID,
        ProductName,
        Price,
        ROW_NUMBER() OVER (ORDER BY ProductName) AS RowNum,
        COUNT(*) OVER () AS TotalRows
    FROM Products
)
SELECT 
    ProductID,
    ProductName,
    Price,
    RowNum,
    TotalRows,
    CEILING(CAST(TotalRows AS FLOAT) / @PageSize) AS TotalPages
FROM Paginated
WHERE RowNum BETWEEN (@PageNumber - 1) * @PageSize + 1 AND @PageNumber * @PageSize
ORDER BY RowNum;
GO

-- =============================================
-- Example 9: OFFSET/FETCH Pagination (SQL 2012+)
-- =============================================

-- Page 1 (rows 1-10)
SELECT ProductID, ProductName, Price
FROM Products
ORDER BY ProductName
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
GO

-- Page 2 (rows 11-20)
SELECT ProductID, ProductName, Price
FROM Products
ORDER BY ProductName
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
GO

-- Generic pagination
DECLARE @PageNum INT = 3;
DECLARE @PageSz INT = 10;

SELECT ProductID, ProductName, Price
FROM Products
ORDER BY ProductName
OFFSET (@PageNum - 1) * @PageSz ROWS 
FETCH NEXT @PageSz ROWS ONLY;
GO

-- =============================================
-- Example 10: Deduplication with ROW_NUMBER
-- =============================================

-- Find duplicate customers by email (keep most recent)
WITH DuplicateCustomers AS (
    SELECT 
        CustomerID,
        CustomerName,
        City,
        JoinDate,
        ROW_NUMBER() OVER (PARTITION BY CustomerName ORDER BY JoinDate DESC) AS RowNum
    FROM Customers
)
SELECT * FROM DuplicateCustomers
WHERE RowNum > 1;  -- Show duplicates
GO

-- Delete duplicates (keep most recent)
/*
WITH DuplicateCustomers AS (
    SELECT 
        CustomerID,
        ROW_NUMBER() OVER (PARTITION BY CustomerName ORDER BY JoinDate DESC) AS RowNum
    FROM Customers
)
DELETE FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID FROM DuplicateCustomers WHERE RowNum > 1
);
*/

-- =============================================
-- Example 11: Monthly Top Sellers
-- =============================================

-- Top 3 products each month by revenue
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        ProductID,
        SUM(TotalAmount) AS MonthlyRevenue,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(SaleDate), MONTH(SaleDate) 
            ORDER BY SUM(TotalAmount) DESC
        ) AS MonthlyRank
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate), ProductID
)
SELECT 
    SaleYear,
    SaleMonth,
    ProductID,
    MonthlyRevenue,
    MonthlyRank
FROM MonthlySales
WHERE MonthlyRank <= 3
ORDER BY SaleYear, SaleMonth, MonthlyRank;
GO

-- =============================================
-- Example 12: Customer Segmentation with NTILE
-- =============================================

-- Divide customers into 5 tiers by lifetime value
WITH CustomerTiers AS (
    SELECT 
        CustomerID,
        CustomerName,
        TotalPurchases,
        NTILE(5) OVER (ORDER BY TotalPurchases DESC) AS Tier,
        CASE NTILE(5) OVER (ORDER BY TotalPurchases DESC)
            WHEN 1 THEN 'Platinum (Top 20%)'
            WHEN 2 THEN 'Gold (Next 20%)'
            WHEN 3 THEN 'Silver (Middle 20%)'
            WHEN 4 THEN 'Bronze (Next 20%)'
            WHEN 5 THEN 'Standard (Bottom 20%)'
        END AS TierLabel
    FROM Customers
)
SELECT 
    Tier,
    TierLabel,
    COUNT(*) AS CustomerCnt,
    AVG(TotalPurchases) AS AvgPurchases,
    MIN(TotalPurchases) AS MinPurchases,
    MAX(TotalPurchases) AS MaxPurchases
FROM CustomerTiers
GROUP BY Tier, TierLabel
ORDER BY Tier;
GO

-- =============================================
-- Example 13: ABC Analysis (Inventory)
-- =============================================

-- A items: Top 20% (high value)
-- B items: Next 30% (medium value)
-- C items: Bottom 50% (low value)

WITH ProductValue AS (
    SELECT 
        ProductID,
        ProductName,
        Price * StockQuantity AS TotalValue,
        SUM(Price * StockQuantity) OVER () AS GrandTotal
    FROM Products
),
ProductRanking AS (
    SELECT 
        *,
        SUM(TotalValue) OVER (ORDER BY TotalValue DESC) AS CumulativeValue,
        SUM(TotalValue) OVER (ORDER BY TotalValue DESC) * 100.0 / GrandTotal AS CumulativePct
    FROM ProductValue
)
SELECT 
    ProductID,
    ProductName,
    TotalValue,
    CumulativePct,
    CASE 
        WHEN CumulativePct <= 20 THEN 'A (Top 20%)'
        WHEN CumulativePct <= 50 THEN 'B (Next 30%)'
        ELSE 'C (Bottom 50%)'
    END AS ABCClass
FROM ProductRanking
ORDER BY TotalValue DESC;
GO

-- =============================================
-- Example 14: Employee Salary Rankings
-- =============================================

-- Rank employees by salary within department
SELECT 
    e.EmployeeID,
    d.DepartmentName,
    e.Salary,
    RANK() OVER (PARTITION BY e.DepartmentID ORDER BY e.Salary DESC) AS DeptRank,
    RANK() OVER (ORDER BY e.Salary DESC) AS CompanyRank,
    NTILE(4) OVER (PARTITION BY e.DepartmentID ORDER BY e.Salary) AS DeptQuartile
FROM Employees e
INNER JOIN Departments d ON e.DepartmentID = d.DepartmentID
ORDER BY d.DepartmentName, e.Salary DESC;
GO

-- =============================================
-- Example 15: Running Rank (Position Over Time)
-- =============================================

-- Track product rank changes over time
WITH DailySales AS (
    SELECT 
        CAST(SaleDate AS DATE) AS SaleDate,
        ProductID,
        SUM(Quantity) AS DailyQty
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE), ProductID
)
SELECT 
    SaleDate,
    ProductID,
    DailyQty,
    RANK() OVER (PARTITION BY SaleDate ORDER BY DailyQty DESC) AS DailyRank
FROM DailySales
ORDER BY SaleDate, DailyRank;
GO

-- =============================================
-- Example 16: Percentile Calculation
-- =============================================

-- What percentile is each product in terms of price?
SELECT 
    ProductName,
    Price,
    NTILE(100) OVER (ORDER BY Price) AS Percentile,
    CASE 
        WHEN NTILE(100) OVER (ORDER BY Price) >= 90 THEN 'Top 10%'
        WHEN NTILE(100) OVER (ORDER BY Price) >= 75 THEN 'Top 25%'
        WHEN NTILE(100) OVER (ORDER BY Price) >= 50 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END AS PercentileGroup
FROM Products
ORDER BY Price DESC;
GO

-- =============================================
-- Example 17: First and Last Per Group
-- =============================================

-- First and last sale for each customer
WITH RankedSales AS (
    SELECT 
        CustomerID,
        SaleID,
        SaleDate,
        TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY SaleDate ASC) AS FirstRank,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY SaleDate DESC) AS LastRank
    FROM Sales
)
SELECT 
    CustomerID,
    MAX(CASE WHEN FirstRank = 1 THEN SaleDate END) AS FirstSaleDate,
    MAX(CASE WHEN FirstRank = 1 THEN TotalAmount END) AS FirstSaleAmount,
    MAX(CASE WHEN LastRank = 1 THEN SaleDate END) AS LastSaleDate,
    MAX(CASE WHEN LastRank = 1 THEN TotalAmount END) AS LastSaleAmount
FROM RankedSales
WHERE FirstRank = 1 OR LastRank = 1
GROUP BY CustomerID
ORDER BY CustomerID;
GO

-- =============================================
-- Example 18: Ranking with Multiple Criteria
-- =============================================

-- Rank products by price, then by stock (tie-breaker)
SELECT 
    ProductName,
    Price,
    StockQuantity,
    RANK() OVER (ORDER BY Price DESC, StockQuantity DESC) AS Rank
FROM Products
ORDER BY Rank;
GO

-- =============================================
-- Example 19: Performance: ROW_NUMBER vs Subquery
-- =============================================

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Window function (efficient)
WITH Ranked AS (
    SELECT 
        CustomerID,
        SaleDate,
        TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY SaleDate DESC) AS Rank
    FROM Sales
)
SELECT CustomerID, SaleDate, TotalAmount
FROM Ranked
WHERE Rank = 1;
GO

-- Subquery (inefficient)
SELECT s1.CustomerID, s1.SaleDate, s1.TotalAmount
FROM Sales s1
WHERE s1.SaleDate = (
    SELECT MAX(s2.SaleDate)
    FROM Sales s2
    WHERE s2.CustomerID = s1.CustomerID
);
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
-- ROW_NUMBER is much faster!
GO

-- =============================================
-- Example 20: Practical Application - Dashboard
-- =============================================

-- Executive dashboard: Top products, customers, categories
WITH TopProducts AS (
    SELECT 
        ProductID,
        SUM(TotalAmount) AS Revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(TotalAmount) DESC) AS Rank
    FROM Sales
    GROUP BY ProductID
),
TopCustomers AS (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS Revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(TotalAmount) DESC) AS Rank
    FROM Sales
    GROUP BY CustomerID
),
CategoryPerformance AS (
    SELECT 
        p.Category,
        SUM(s.TotalAmount) AS Revenue,
        RANK() OVER (ORDER BY SUM(s.TotalAmount) DESC) AS Rank
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY p.Category
)
SELECT 
    'Top 5 Products' AS Metric,
    (SELECT COUNT(*) FROM TopProducts WHERE Rank <= 5) AS Cnt
UNION ALL
SELECT 
    'Top 5 Customers',
    (SELECT COUNT(*) FROM TopCustomers WHERE Rank <= 5)
UNION ALL
SELECT 
    'Top 3 Categories',
    (SELECT COUNT(*) FROM CategoryPerformance WHERE Rank <= 3);
GO

-- 💡 Key Takeaways:
--
-- RANKING FUNCTIONS:
-- ┌─────────────┬───────────────────┬────────────┬─────────────────────────┐
-- │ Function    │ Ties Handling     │ Sequential │ Example (with ties)     │
-- ├─────────────┼───────────────────┼────────────┼─────────────────────────┤
-- │ ROW_NUMBER  │ Arbitrary order   │ Yes        │ 1, 2, 3, 4, 5           │
-- │ RANK        │ Same rank, skip   │ No         │ 1, 2, 2, 4, 5 (gap)     │
-- │ DENSE_RANK  │ Same rank, no skip│ Yes        │ 1, 2, 2, 3, 4 (no gap)  │
-- │ NTILE(N)    │ Distributed evenly│ Grouped    │ 1, 1, 2, 2, 3, 3        │
-- └─────────────┴───────────────────┴────────────┴─────────────────────────┘
--
-- USE CASES:
-- - ROW_NUMBER: Pagination, deduplication, unique sequential numbers
-- - RANK: Olympic-style ranking (gaps for ties)
-- - DENSE_RANK: Continuous ranking (no gaps)
-- - NTILE: Percentiles, quartiles, customer segmentation, ABC analysis
--
-- TOP-N PER GROUP:
-- - Use ROW_NUMBER() OVER (PARTITION BY group ORDER BY criteria)
-- - Filter WHERE Rank <= N
-- - Faster than correlated subqueries
--
-- PAGINATION:
-- - ROW_NUMBER + BETWEEN (works in all versions)
-- - OFFSET/FETCH (SQL Server 2012+, cleaner syntax)
-- - Include total row count for UI (COUNT(*) OVER ())
--
-- DEDUPLICATION:
-- - ROW_NUMBER() OVER (PARTITION BY key ORDER BY tiebreaker)
-- - Keep RowNum = 1, delete others
--
-- PERFORMANCE:
-- - Index PARTITION BY and ORDER BY columns
-- - ROW_NUMBER faster than correlated subqueries
-- - RANK/DENSE_RANK slightly slower than ROW_NUMBER
-- - NTILE can be expensive on very large datasets
--
-- BEST PRACTICES:
-- - Use meaningful ORDER BY (avoid arbitrary ranking)
-- - Document tie-breaking logic in comments
-- - Test pagination with various page sizes
-- - Use CTEs for readability
-- - Index appropriately for performance
-- - Prefer ROW_NUMBER if ties don't matter (faster)
