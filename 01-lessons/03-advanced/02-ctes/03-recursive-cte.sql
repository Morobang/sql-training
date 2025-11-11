-- ========================================
-- Recursive CTEs
-- ========================================

USE TechStore;

-- 1. Generate number sequence
WITH Numbers AS (
    -- Anchor: Start with 1
    SELECT 1 AS Num
    
    UNION ALL
    
    -- Recursive: Add 1 until we reach 10
    SELECT Num + 1
    FROM Numbers
    WHERE Num < 10
)
SELECT Num
FROM Numbers;

-- 2. Date range generator
WITH DateRange AS (
    -- Anchor: Start date
    SELECT CAST('2024-11-01' AS DATE) AS SaleDate
    
    UNION ALL
    
    -- Recursive: Add one day
    SELECT DATEADD(DAY, 1, SaleDate)
    FROM DateRange
    WHERE SaleDate < '2024-11-10'
)
SELECT 
    dr.SaleDate,
    ISNULL(SUM(s.TotalAmount), 0) AS DailyRevenue
FROM DateRange dr
LEFT JOIN Sales s ON CAST(s.SaleDate AS DATE) = dr.SaleDate
GROUP BY dr.SaleDate
ORDER BY dr.SaleDate;

-- 3. Running total with recursive CTE
WITH SalesSequence AS (
    -- Anchor: First sale
    SELECT 
        SaleID,
        SaleDate,
        TotalAmount,
        TotalAmount AS RunningTotal,
        1 AS RowNum
    FROM (
        SELECT 
            SaleID,
            SaleDate,
            TotalAmount,
            ROW_NUMBER() OVER (ORDER BY SaleDate, SaleID) AS RN
        FROM Sales
    ) AS Numbered
    WHERE RN = 1
    
    UNION ALL
    
    -- Recursive: Add each subsequent sale
    SELECT 
        s.SaleID,
        s.SaleDate,
        s.TotalAmount,
        ss.RunningTotal + s.TotalAmount,
        ss.RowNum + 1
    FROM SalesSequence ss
    INNER JOIN (
        SELECT 
            SaleID,
            SaleDate,
            TotalAmount,
            ROW_NUMBER() OVER (ORDER BY SaleDate, SaleID) AS RN
        FROM Sales
    ) AS s ON s.RN = ss.RowNum + 1
)
SELECT 
    SaleID,
    SaleDate,
    TotalAmount,
    RunningTotal
FROM SalesSequence
ORDER BY SaleDate, SaleID;

-- 4. Price tier hierarchy (conceptual example)
-- Create a temp table to demonstrate hierarchy
CREATE TABLE #PriceTiers (
    TierID INT,
    TierName NVARCHAR(50),
    MinPrice DECIMAL(10,2),
    MaxPrice DECIMAL(10,2),
    ParentTierID INT
);

INSERT INTO #PriceTiers VALUES
(1, 'All Products', 0, 99999, NULL),
(2, 'Budget', 0, 50, 1),
(3, 'Mid-Range', 50, 150, 1),
(4, 'Premium', 150, 99999, 1),
(5, 'Ultra-Budget', 0, 25, 2),
(6, 'Value', 25, 50, 2);

-- Recursive CTE to show hierarchy
WITH TierHierarchy AS (
    -- Anchor: Root level
    SELECT 
        TierID,
        TierName,
        MinPrice,
        MaxPrice,
        ParentTierID,
        0 AS Level,
        CAST(TierName AS NVARCHAR(500)) AS Path
    FROM #PriceTiers
    WHERE ParentTierID IS NULL
    
    UNION ALL
    
    -- Recursive: Child tiers
    SELECT 
        pt.TierID,
        pt.TierName,
        pt.MinPrice,
        pt.MaxPrice,
        pt.ParentTierID,
        th.Level + 1,
        CAST(th.Path + ' > ' + pt.TierName AS NVARCHAR(500))
    FROM #PriceTiers pt
    INNER JOIN TierHierarchy th ON pt.ParentTierID = th.TierID
)
SELECT 
    REPLICATE('  ', Level) + TierName AS Hierarchy,
    MinPrice,
    MaxPrice,
    Level,
    Path
FROM TierHierarchy
ORDER BY Path;

DROP TABLE #PriceTiers;

-- 💡 Note: Use MAXRECURSION hint for deep hierarchies
-- OPTION (MAXRECURSION 1000)
