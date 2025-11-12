-- ========================================
-- Advanced Window Functions - cohorts, retention, percentiles
-- ========================================

USE TechStore;
GO

-- 1) Cohort analysis: customer cohort by first purchase month, retention by month
WITH FirstPurchase AS (
    SELECT
        CustomerID,
        MIN(CAST(SaleDate AS DATE)) AS FirstPurchaseDate,
        DATEFROMPARTS(YEAR(MIN(SaleDate)), MONTH(MIN(SaleDate)), 1) AS CohortMonth
    FROM Sales
    GROUP BY CustomerID
),
MonthlyPurchases AS (
    SELECT
        fp.CustomerID,
        fp.CohortMonth,
        DATEFROMPARTS(YEAR(s.SaleDate), MONTH(s.SaleDate), 1) AS PurchaseMonth
    FROM Sales s
    JOIN FirstPurchase fp ON s.CustomerID = fp.CustomerID
),
CohortCounts AS (
    SELECT
        CohortMonth,
        PurchaseMonth,
        COUNT(DISTINCT CustomerID) AS ActiveCustomers
    FROM MonthlyPurchases
    GROUP BY CohortMonth, PurchaseMonth
)
SELECT
    CohortMonth,
    PurchaseMonth,
    ActiveCustomers,
    DATEDIFF(MONTH, CohortMonth, PurchaseMonth) AS MonthsSinceCohort
FROM CohortCounts
ORDER BY CohortMonth, PurchaseMonth;
GO

-- 2) Retention matrix (pivot) using window functions for completeness
-- Build retention percentages per cohort
WITH Cohort AS (
    SELECT
        CustomerID,
        DATEFROMPARTS(YEAR(MIN(SaleDate)), MONTH(MIN(SaleDate)), 1) AS CohortMonth
    FROM Sales
    GROUP BY CustomerID
),
Activity AS (
    SELECT
        c.CohortMonth,
        DATEFROMPARTS(YEAR(s.SaleDate), MONTH(s.SaleDate), 1) AS ActivityMonth,
        c.CustomerID
    FROM Sales s
    JOIN Cohort c ON s.CustomerID = c.CustomerID
    GROUP BY c.CohortMonth, DATEFROMPARTS(YEAR(s.SaleDate), MONTH(s.SaleDate), 1), c.CustomerID
),
CohortSize AS (
    SELECT CohortMonth, COUNT(DISTINCT CustomerID) AS CohortSize FROM Cohort GROUP BY CohortMonth
),
MonthlyActive AS (
    SELECT CohortMonth, ActivityMonth, COUNT(DISTINCT CustomerID) AS ActiveCount
    FROM Activity
    GROUP BY CohortMonth, ActivityMonth
)
SELECT
    m.CohortMonth,
    m.ActivityMonth,
    m.ActiveCount,
    cs.CohortSize,
    CAST(m.ActiveCount * 100.0 / cs.CohortSize AS DECIMAL(5,2)) AS RetentionPct
FROM MonthlyActive m
JOIN CohortSize cs ON m.CohortMonth = cs.CohortMonth
ORDER BY m.CohortMonth, m.ActivityMonth;
GO

-- 3) Percentile calculation (customer LTV percentile) using NTILE and analytic aggregates
WITH CustomerLTV AS (
    SELECT CustomerID, SUM(TotalAmount) AS LifetimeValue
    FROM Sales
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    LifetimeValue,
    NTILE(100) OVER (ORDER BY LifetimeValue DESC) AS PercentileRank,
    PERCENT_RANK() OVER (ORDER BY LifetimeValue DESC) AS PercentRankDecimal
FROM CustomerLTV
ORDER BY LifetimeValue DESC;
GO

-- 4) Gaps and Islands: identify continuous purchase streaks (> or =) per customer
WITH CustomerDates AS (
    SELECT DISTINCT CustomerID, CAST(SaleDate AS DATE) AS d
    FROM Sales
),
Numbered AS (
    SELECT
        CustomerID,
        d,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY d) AS rn
    FROM CustomerDates
),
Islands AS (
    SELECT
        CustomerID,
        d,
        DATEADD(DAY, -rn, d) AS IslandKey
    FROM Numbered
)
SELECT CustomerID, MIN(d) AS StartDate, MAX(d) AS EndDate, COUNT(*) AS Streak
FROM Islands
GROUP BY CustomerID, IslandKey
ORDER BY CustomerID, StartDate;
GO

-- 5) Complex frame - moving average over variable window (preceding 2 rows, following 1)
WITH DailySales AS (
    SELECT CAST(SaleDate AS DATE) AS SaleDate, SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY CAST(SaleDate AS DATE)
)
SELECT
    SaleDate,
    Revenue,
    AVG(Revenue) OVER (ORDER BY SaleDate ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING) AS MovingAvg_4day
FROM DailySales
ORDER BY SaleDate;
GO

-- 6) Use CASE with FIRST_VALUE/LAST_VALUE to detect baseline vs current
WITH MonthlySales AS (
    SELECT DATEFROMPARTS(YEAR(SaleDate), MONTH(SaleDate), 1) AS SaleMonth, SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY DATEFROMPARTS(YEAR(SaleDate), MONTH(SaleDate), 1)
)
SELECT
    SaleMonth,
    Revenue,
    FIRST_VALUE(Revenue) OVER (ORDER BY SaleMonth ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS Baseline,
    Revenue - FIRST_VALUE(Revenue) OVER (ORDER BY SaleMonth ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DiffFromBaseline
FROM MonthlySales
ORDER BY SaleMonth;
GO

-- Key takeaways:
-- - Combine grouping sets and advanced windows for rich reporting
-- - Use cohort patterns for retention and LTV analysis
-- - Use NTILE/PERCENT_RANK for segmentation
-- - Materialize expensive aggregates when needed
-- - Test with edge cases: empty cohorts, single-customer cohorts, sparse months
