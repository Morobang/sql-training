-- ============================================================================
-- History Analysis and Change Pattern Detection
-- ============================================================================
-- Analyze temporal data for trends, patterns, and insights
-- ============================================================================

USE TechStore_Temporal;
GO

PRINT '=================================================================';
PRINT 'TEMPORAL DATA ANALYSIS';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
HISTORY ANALYSIS OVERVIEW
============================================================================

WHAT CAN WE LEARN FROM TEMPORAL DATA?

1. Change Frequency
   - Which products change most often?
   - When do most changes occur?
   
2. Price Trends
   - Price volatility analysis
   - Discount patterns
   
3. User Activity
   - Who makes the most changes?
   - Change patterns by time of day
   
4. Data Quality
   - Flip-flopping (A→B→A)
   - Rapid successive changes
   
5. Business Intelligence
   - Seasonal pricing
   - Inventory turnover
   - Cost trends

============================================================================
*/

-- ============================================================================
-- 1. Change Frequency Analysis
-- ============================================================================

PRINT '1. CHANGE FREQUENCY ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Products ranked by number of changes:';

WITH ChangeCount AS (
    SELECT 
        ProductID,
        ProductName,
        COUNT(*) - 1 AS NumberOfChanges,  -- Subtract 1 for initial insert
        MIN(ValidFrom) AS FirstVersion,
        MAX(ValidFrom) AS LastChange
    FROM Products FOR SYSTEM_TIME ALL
    GROUP BY ProductID, ProductName
)
SELECT 
    ProductID,
    ProductName,
    NumberOfChanges,
    FirstVersion,
    LastChange,
    DATEDIFF(SECOND, FirstVersion, LastChange) AS LifetimeSeconds,
    CASE 
        WHEN NumberOfChanges = 0 THEN 'Never Changed'
        WHEN NumberOfChanges <= 2 THEN 'Low Activity'
        WHEN NumberOfChanges <= 5 THEN 'Medium Activity'
        ELSE 'High Activity'
    END AS ActivityLevel
FROM ChangeCount
ORDER BY NumberOfChanges DESC;

PRINT '';

-- ============================================================================
-- 2. Price Volatility Analysis
-- ============================================================================

PRINT '2. PRICE VOLATILITY ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Price statistics per product:';

WITH PriceStats AS (
    SELECT 
        ProductID,
        ProductName,
        MIN(Price) AS MinPrice,
        MAX(Price) AS MaxPrice,
        AVG(Price) AS AvgPrice,
        STDEV(Price) AS StdDevPrice,
        COUNT(DISTINCT Price) AS UniquePrices
    FROM Products FOR SYSTEM_TIME ALL
    GROUP BY ProductID, ProductName
)
SELECT 
    ProductID,
    ProductName,
    CAST(MinPrice AS DECIMAL(10,2)) AS MinPrice,
    CAST(MaxPrice AS DECIMAL(10,2)) AS MaxPrice,
    CAST(AvgPrice AS DECIMAL(10,2)) AS AvgPrice,
    CAST(MaxPrice - MinPrice AS DECIMAL(10,2)) AS PriceRange,
    CAST(((MaxPrice - MinPrice) / MinPrice * 100) AS DECIMAL(5,2)) AS VolatilityPercent,
    UniquePrices,
    CASE 
        WHEN ((MaxPrice - MinPrice) / MinPrice * 100) > 50 THEN '🔴 High Volatility'
        WHEN ((MaxPrice - MinPrice) / MinPrice * 100) > 20 THEN '🟡 Medium Volatility'
        ELSE '🟢 Low Volatility'
    END AS VolatilityRating
FROM PriceStats
ORDER BY VolatilityPercent DESC;

PRINT '';

-- ============================================================================
-- 3. Change Timeline
-- ============================================================================

PRINT '3. CHANGE TIMELINE (When do changes occur?)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Chronological change log:';

SELECT 
    ValidFrom AS ChangeTimestamp,
    ProductID,
    ProductName,
    Price,
    ModifiedBy,
    DATEDIFF(SECOND, 
        LAG(ValidFrom) OVER (PARTITION BY ProductID ORDER BY ValidFrom),
        ValidFrom
    ) AS SecondsSinceLastChange
FROM Products FOR SYSTEM_TIME ALL
WHERE ValidFrom < '9999-12-31'  -- Exclude current version
ORDER BY ValidFrom;

PRINT '';

-- ============================================================================
-- 4. Detect Flip-Flopping (Data Quality Issue)
-- ============================================================================

PRINT '4. FLIP-FLOP DETECTION (A→B→A pattern)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Detecting price flip-flops (same price appears multiple times):';

WITH PriceSequence AS (
    SELECT 
        ProductID,
        ProductName,
        Price,
        ValidFrom,
        LAG(Price) OVER (PARTITION BY ProductID ORDER BY ValidFrom) AS PrevPrice,
        LAG(Price, 2) OVER (PARTITION BY ProductID ORDER BY ValidFrom) AS PrevPrice2
    FROM Products FOR SYSTEM_TIME ALL
)
SELECT 
    ProductID,
    ProductName,
    PrevPrice2 AS Price1,
    PrevPrice AS Price2,
    Price AS Price3,
    ValidFrom AS FlipFlopTimestamp,
    '⚠️ FLIP-FLOP DETECTED' AS DataQualityIssue
FROM PriceSequence
WHERE Price = PrevPrice2 
  AND Price != PrevPrice
ORDER BY ValidFrom;

IF @@ROWCOUNT = 0
    PRINT '  ✓ No flip-flops detected (good data quality)';

PRINT '';

-- ============================================================================
-- 5. Rapid Change Detection
-- ============================================================================

PRINT '5. RAPID CHANGE DETECTION';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Changes occurring within 5 seconds (potential errors):';

WITH ChangeSpeed AS (
    SELECT 
        ProductID,
        ProductName,
        Price,
        ValidFrom,
        DATEDIFF(SECOND, 
            LAG(ValidFrom) OVER (PARTITION BY ProductID ORDER BY ValidFrom),
            ValidFrom
        ) AS SecondsSincePrevious
    FROM Products FOR SYSTEM_TIME ALL
)
SELECT 
    ProductID,
    ProductName,
    Price,
    ValidFrom AS ChangeTime,
    SecondsSincePrevious,
    CASE 
        WHEN SecondsSincePrevious < 5 THEN '⚠️ VERY RAPID'
        WHEN SecondsSincePrevious < 60 THEN '🟡 Rapid'
        ELSE '🟢 Normal'
    END AS ChangeSpeed
FROM ChangeSpeed
WHERE SecondsSincePrevious IS NOT NULL
  AND SecondsSincePrevious < 300  -- Less than 5 minutes
ORDER BY SecondsSincePrevious;

PRINT '';

-- ============================================================================
-- 6. User Activity Analysis
-- ============================================================================

PRINT '6. USER ACTIVITY ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Changes by user:';

SELECT 
    ModifiedBy AS UserName,
    COUNT(*) AS TotalChanges,
    COUNT(DISTINCT ProductID) AS ProductsChanged,
    MIN(ValidFrom) AS FirstChange,
    MAX(ValidFrom) AS LastChange,
    CAST(AVG(CAST(Price AS FLOAT)) AS DECIMAL(10,2)) AS AvgPriceSet
FROM Products FOR SYSTEM_TIME ALL
WHERE ValidFrom < '9999-12-31'  -- Historical only
GROUP BY ModifiedBy
ORDER BY TotalChanges DESC;

PRINT '';

-- ============================================================================
-- 7. Inventory Turnover Analysis
-- ============================================================================

PRINT '7. INVENTORY TURNOVER ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Inventory changes over time:';

WITH InventoryChanges AS (
    SELECT 
        ProductID,
        WarehouseLocation,
        QuantityOnHand,
        ValidFrom,
        QuantityOnHand - LAG(QuantityOnHand) OVER (
            PARTITION BY ProductID, WarehouseLocation 
            ORDER BY ValidFrom
        ) AS QuantityChange
    FROM Inventory FOR SYSTEM_TIME ALL
)
SELECT 
    ProductID,
    WarehouseLocation,
    QuantityOnHand AS CurrentQuantity,
    QuantityChange,
    CASE 
        WHEN QuantityChange > 0 THEN '📦 Restocked (+ ' + CAST(QuantityChange AS VARCHAR) + ')'
        WHEN QuantityChange < 0 THEN '📤 Sold (' + CAST(QuantityChange AS VARCHAR) + ')'
        ELSE '─ No Change'
    END AS ChangeType,
    ValidFrom AS ChangeTimestamp
FROM InventoryChanges
WHERE QuantityChange IS NOT NULL
ORDER BY ProductID, ValidFrom;

PRINT '';

-- ============================================================================
-- 8. Price Change Impact Analysis
-- ============================================================================

PRINT '8. PRICE CHANGE IMPACT ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Correlation between price changes and inventory:';

WITH PriceInventory AS (
    SELECT 
        p.ValidFrom AS ChangeTime,
        p.ProductID,
        p.ProductName,
        p.Price,
        LAG(p.Price) OVER (PARTITION BY p.ProductID ORDER BY p.ValidFrom) AS PrevPrice,
        i.QuantityOnHand,
        LAG(i.QuantityOnHand) OVER (PARTITION BY i.ProductID ORDER BY i.ValidFrom) AS PrevQuantity
    FROM Products FOR SYSTEM_TIME ALL p
    LEFT JOIN Inventory FOR SYSTEM_TIME ALL i 
        ON p.ProductID = i.ProductID 
        AND p.ValidFrom = i.ValidFrom
)
SELECT 
    ProductID,
    ProductName,
    CAST(PrevPrice AS DECIMAL(10,2)) AS OldPrice,
    CAST(Price AS DECIMAL(10,2)) AS NewPrice,
    CAST(Price - PrevPrice AS DECIMAL(10,2)) AS PriceChange,
    PrevQuantity AS QuantityBefore,
    QuantityOnHand AS QuantityAfter,
    ChangeTime
FROM PriceInventory
WHERE PrevPrice IS NOT NULL 
  AND Price != PrevPrice
ORDER BY ChangeTime;

PRINT '';

-- ============================================================================
-- 9. Version Lifetime Analysis
-- ============================================================================

PRINT '9. VERSION LIFETIME ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'How long did each version exist?';

SELECT 
    ProductID,
    ProductName,
    Price,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' 
        THEN DATEDIFF(SECOND, ValidFrom, SYSDATETIME())
        ELSE DATEDIFF(SECOND, ValidFrom, ValidTo)
    END AS LifetimeSeconds,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' THEN '✓ Current'
        ELSE 'Historical'
    END AS Status
FROM Products FOR SYSTEM_TIME ALL
ORDER BY ProductID, ValidFrom;

PRINT '';

-- ============================================================================
-- 10. Business Intelligence Dashboard Query
-- ============================================================================

PRINT '10. BI DASHBOARD SUMMARY';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Executive summary of temporal data:';

SELECT 
    'Total Products' AS Metric,
    COUNT(DISTINCT ProductID) AS Value,
    NULL AS Details
FROM Products

UNION ALL

SELECT 
    'Total Changes',
    COUNT(*) - (SELECT COUNT(DISTINCT ProductID) FROM Products),
    'All updates across all products'
FROM Products FOR SYSTEM_TIME ALL

UNION ALL

SELECT 
    'Most Changed Product',
    NULL,
    (
        SELECT TOP 1 ProductName 
        FROM (
            SELECT ProductID, ProductName, COUNT(*) AS Changes
            FROM Products FOR SYSTEM_TIME ALL
            GROUP BY ProductID, ProductName
        ) x
        ORDER BY Changes DESC
    )

UNION ALL

SELECT 
    'Average Price',
    CAST(AVG(Price) AS DECIMAL(10,2)),
    'Across all versions'
FROM Products FOR SYSTEM_TIME ALL

UNION ALL

SELECT 
    'Price Range',
    CAST(MAX(Price) - MIN(Price) AS DECIMAL(10,2)),
    'Min: ' + CAST(MIN(Price) AS VARCHAR) + ', Max: ' + CAST(MAX(Price) AS VARCHAR)
FROM Products FOR SYSTEM_TIME ALL;

PRINT '';

PRINT '=================================================================';
PRINT 'HISTORY ANALYSIS COMPLETE!';
PRINT '=================================================================';

/*
============================================================================
HISTORY ANALYSIS SUMMARY
============================================================================

✅ ANALYSIS PERFORMED:

1. Change Frequency
   - Ranked products by update frequency
   - Identified high/low activity products

2. Price Volatility
   - Min, max, average, standard deviation
   - Volatility rating (high/medium/low)

3. Change Timeline
   - Chronological change log
   - Time between changes

4. Data Quality Checks
   - Flip-flop detection (A→B→A)
   - Rapid successive changes

5. User Activity
   - Changes per user
   - Products affected per user

6. Inventory Turnover
   - Stock increases (restocking)
   - Stock decreases (sales)

7. Price-Inventory Correlation
   - Impact of price changes on inventory

8. Version Lifetime
   - How long each version existed
   - Current vs historical versions

9. Business Intelligence
   - Executive dashboard metrics
   - Summary statistics

INSIGHTS YOU CAN EXTRACT:

📊 Business Operations:
   - Which products change frequently? (unstable pricing?)
   - When do most changes occur? (batch updates? manual entry?)

📈 Pricing Strategy:
   - Price volatility indicates competitive pressure
   - Frequent price increases might signal demand
   - Frequent decreases might signal overstock

🔍 Data Quality:
   - Flip-flops indicate data entry errors
   - Rapid changes suggest automated processes or corrections

👥 User Behavior:
   - Power users making most changes
   - Training opportunities for low-activity users

📦 Inventory Management:
   - Correlation between price drops and inventory spikes
   - Seasonal patterns in restocking

NEXT STEPS WITH THIS DATA:

1. Create scheduled reports
2. Build Power BI dashboards
3. Set up alerts for anomalies
4. Archive old history to blob storage
5. Implement data quality rules

PRODUCTION RECOMMENDATIONS:

✅ Index ValidFrom, ValidTo on history tables
✅ Partition history by date (monthly/quarterly)
✅ Compress history table (PAGE compression)
✅ Set retention policy (e.g., 7 years for compliance)
✅ Archive to Azure Blob after retention period

Next: Data restoration procedures!
============================================================================
*/
