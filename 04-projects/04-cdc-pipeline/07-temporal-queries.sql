-- ============================================================================
-- Temporal Table Queries (Time Travel)
-- ============================================================================
-- Query data as it existed at any point in time
-- ============================================================================

USE TechStore_Temporal;
GO

PRINT '=================================================================';
PRINT 'TEMPORAL TABLE TIME TRAVEL QUERIES';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
TEMPORAL QUERY SYNTAX
============================================================================

Standard SQL: SELECT * FROM Products WHERE Price > 50

Temporal SQL: SELECT * FROM Products 
              FOR SYSTEM_TIME AS OF '2024-01-15'
              WHERE Price > 50

TIME TRAVEL CLAUSES:

1. AS OF <date>
   - Point-in-time snapshot
   - "Show me the data exactly as it was on January 15"
   
2. FROM <start> TO <end>
   - Range query (EXCLUSIVE of end)
   - "Show me all versions between Jan 1 and Jan 15"
   
3. BETWEEN <start> AND <end>
   - Range query (INCLUSIVE of both)
   - "Show me all versions from Jan 1 through Jan 15"
   
4. CONTAINED IN (<start>, <end>)
   - Versions that existed entirely within period
   - "Show me versions that started AND ended in this range"
   
5. ALL
   - Everything (current + all history)
   - "Show me every version that ever existed"

============================================================================
*/

-- ============================================================================
-- 1. AS OF - Point-in-Time Query
-- ============================================================================

PRINT '1. POINT-IN-TIME QUERIES (AS OF)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

-- Get current state first
PRINT 'Current Products (right now):';
SELECT ProductID, ProductName, Price, StockQuantity
FROM Products
ORDER BY ProductID;

PRINT '';

-- Query as of 5 seconds ago
DECLARE @five_seconds_ago DATETIME2 = DATEADD(SECOND, -5, SYSDATETIME());

PRINT 'Products as of 5 seconds ago:';
PRINT 'Query: SELECT * FROM Products FOR SYSTEM_TIME AS OF @five_seconds_ago';

SELECT ProductID, ProductName, Price, StockQuantity, ValidFrom, ValidTo
FROM Products FOR SYSTEM_TIME AS OF @five_seconds_ago
ORDER BY ProductID;

PRINT '';

-- Find what the wireless mouse price was before recent changes
PRINT 'Original Wireless Mouse price (before any updates):';

SELECT TOP 1
    ProductID,
    ProductName,
    Price AS OriginalPrice,
    ValidFrom AS PriceEffectiveDate
FROM Products FOR SYSTEM_TIME ALL
WHERE ProductID = 1
ORDER BY ValidFrom ASC;

PRINT '';

-- ============================================================================
-- 2. FOR SYSTEM_TIME ALL - Complete History
-- ============================================================================

PRINT '2. COMPLETE HISTORY (FOR SYSTEM_TIME ALL)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Every version of ProductID = 1 (Wireless Mouse):';

SELECT 
    ProductID,
    ProductName,
    Price,
    StockQuantity,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' THEN '✓ Current'
        ELSE 'Historical'
    END AS Status,
    DATEDIFF(SECOND, ValidFrom, ValidTo) AS ValidForSeconds
FROM Products FOR SYSTEM_TIME ALL
WHERE ProductID = 1
ORDER BY ValidFrom;

PRINT '';

-- ============================================================================
-- 3. BETWEEN - Date Range Queries
-- ============================================================================

PRINT '3. DATE RANGE QUERIES (BETWEEN)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

DECLARE @start_time DATETIME2 = DATEADD(MINUTE, -5, SYSDATETIME());
DECLARE @end_time DATETIME2 = SYSDATETIME();

PRINT 'All price changes in last 5 minutes:';
PRINT 'Query: FOR SYSTEM_TIME BETWEEN @start AND @end';

SELECT 
    ProductID,
    ProductName,
    Price,
    ValidFrom,
    ValidTo
FROM Products FOR SYSTEM_TIME BETWEEN @start_time AND @end_time
ORDER BY ValidFrom;

PRINT '';

-- ============================================================================
-- 4. Price Change Analysis
-- ============================================================================

PRINT '4. PRICE CHANGE ANALYSIS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Price history with change detection:';

WITH PriceHistory AS (
    SELECT 
        ProductID,
        ProductName,
        Price,
        ValidFrom,
        ValidTo,
        LAG(Price) OVER (PARTITION BY ProductID ORDER BY ValidFrom) AS PreviousPrice
    FROM Products FOR SYSTEM_TIME ALL
)
SELECT 
    ProductID,
    ProductName,
    PreviousPrice,
    Price AS CurrentPrice,
    Price - PreviousPrice AS PriceChange,
    CASE 
        WHEN Price > PreviousPrice THEN '📈 Increase'
        WHEN Price < PreviousPrice THEN '📉 Decrease'
        ELSE '─ No Change'
    END AS Trend,
    CAST(((Price - PreviousPrice) / PreviousPrice * 100) AS DECIMAL(5,2)) AS PercentChange,
    ValidFrom AS ChangeDate
FROM PriceHistory
WHERE PreviousPrice IS NOT NULL
ORDER BY ProductID, ValidFrom;

PRINT '';

-- ============================================================================
-- 5. Inventory Change Tracking
-- ============================================================================

PRINT '5. INVENTORY CHANGE TRACKING';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Inventory changes over time:';

SELECT 
    ProductID,
    WarehouseLocation,
    QuantityOnHand,
    QuantityReserved,
    QuantityOnHand - QuantityReserved AS QuantityAvailable,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' THEN 'Current'
        ELSE 'Historical'
    END AS Status
FROM Inventory FOR SYSTEM_TIME ALL
ORDER BY ProductID, ValidFrom;

PRINT '';

-- ============================================================================
-- 6. Audit Trail - Who Changed What When
-- ============================================================================

PRINT '6. AUDIT TRAIL';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Complete audit log of all product changes:';

SELECT 
    ProductID,
    ProductName,
    Price,
    ModifiedBy,
    ValidFrom AS ChangeTimestamp,
    CASE 
        WHEN ValidTo = '9999-12-31 23:59:59.9999999' THEN 'Current Version'
        ELSE 'Changed at ' + CAST(ValidTo AS VARCHAR(30))
    END AS Status
FROM Products FOR SYSTEM_TIME ALL
ORDER BY ProductID, ValidFrom;

PRINT '';

-- ============================================================================
-- 7. Time Travel Join - Multiple Tables
-- ============================================================================

PRINT '7. TIME TRAVEL JOINS (Cross-Table Consistency)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Products and Inventory as they existed 3 seconds ago:';

DECLARE @three_sec_ago DATETIME2 = DATEADD(SECOND, -3, SYSDATETIME());

SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    i.QuantityOnHand,
    i.QuantityReserved,
    i.QuantityOnHand - i.QuantityReserved AS QuantityAvailable,
    p.Price * (i.QuantityOnHand - i.QuantityReserved) AS InventoryValue
FROM Products FOR SYSTEM_TIME AS OF @three_sec_ago p
LEFT JOIN Inventory FOR SYSTEM_TIME AS OF @three_sec_ago i
    ON p.ProductID = i.ProductID
ORDER BY p.ProductID;

PRINT '';

-- ============================================================================
-- 8. Detect Deleted Rows
-- ============================================================================

PRINT '8. DETECTING DELETED ROWS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

-- Simulate a deletion
PRINT 'Simulating deletion of ProductID = 3...';
DELETE FROM Products WHERE ProductID = 3;
PRINT '  ✓ Product deleted from current table';
PRINT '';

WAITFOR DELAY '00:00:01';

-- Query current table (row is gone)
PRINT 'Current Products (row deleted):';
SELECT ProductID, ProductName, Price
FROM Products
WHERE ProductID = 3;

IF @@ROWCOUNT = 0
    PRINT '  (No rows - product was deleted)';

PRINT '';

-- Query historical data (row still exists!)
PRINT 'Historical Products (row still exists in history):';
SELECT 
    ProductID,
    ProductName,
    Price,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo < '9999-12-31' THEN '🗑️ DELETED'
        ELSE 'Active'
    END AS RowStatus
FROM Products FOR SYSTEM_TIME ALL
WHERE ProductID = 3
ORDER BY ValidFrom;

PRINT '';

-- ============================================================================
-- 9. Recovery - Restore Deleted Data
-- ============================================================================

PRINT '9. DATA RECOVERY (Restore Deleted Row)';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

PRINT 'Restoring deleted ProductID = 3 from history...';

-- Need to disable system versioning temporarily
ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);

-- Get last known good version
INSERT INTO Products (ProductID, ProductName, Category, Price, StockQuantity, Supplier, ModifiedBy)
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    StockQuantity,
    Supplier,
    ModifiedBy + ' (RESTORED)'
FROM ProductsHistory
WHERE ProductID = 3
AND ValidTo = (SELECT MAX(ValidTo) FROM ProductsHistory WHERE ProductID = 3);

PRINT '  ✓ Product restored from history';

-- Re-enable system versioning
ALTER TABLE Products SET (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
);

PRINT '  ✓ System versioning re-enabled';
PRINT '';

-- Verify restoration
PRINT 'Restored product:';
SELECT ProductID, ProductName, Price, ModifiedBy
FROM Products
WHERE ProductID = 3;

PRINT '';

-- ============================================================================
-- 10. Performance Considerations
-- ============================================================================

PRINT '10. PERFORMANCE TIPS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

-- Check history table size
PRINT 'History table statistics:';

SELECT 
    t.name AS TableName,
    p.rows AS RowCount,
    (SUM(a.total_pages) * 8) / 1024.0 AS TotalSpaceMB,
    (SUM(a.used_pages) * 8) / 1024.0 AS UsedSpaceMB,
    (SUM(a.data_pages) * 8) / 1024.0 AS DataSpaceMB
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name IN ('Products', 'ProductsHistory', 'Inventory', 'InventoryHistory')
GROUP BY t.name, p.rows
ORDER BY t.name;

PRINT '';

-- ============================================================================
-- 11. Common Query Patterns
-- ============================================================================

PRINT '11. COMMON QUERY PATTERNS';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

-- Pattern 1: "What was the price last Friday?"
PRINT 'Pattern 1: Point-in-time lookup';
PRINT 'Use Case: "What was the Wireless Mouse price last Friday?"';
PRINT 'Query: FOR SYSTEM_TIME AS OF ''2024-01-19''';
PRINT '';

-- Pattern 2: "Show me all price changes this month"
PRINT 'Pattern 2: Change detection';
PRINT 'Use Case: "Show me all products that changed price this month"';
PRINT 'Query: FOR SYSTEM_TIME BETWEEN start_of_month AND end_of_month';
PRINT '';

-- Pattern 3: "Restore accidentally deleted record"
PRINT 'Pattern 3: Data recovery';
PRINT 'Use Case: "Recover product deleted by mistake"';
PRINT 'Query: SELECT * FROM ProductsHistory WHERE ProductID = X AND ValidTo = MAX(ValidTo)';
PRINT '';

-- Pattern 4: "Audit who changed inventory yesterday"
PRINT 'Pattern 4: Audit trail';
PRINT 'Use Case: "Who changed inventory between 9 AM and 5 PM yesterday?"';
PRINT 'Query: FOR SYSTEM_TIME BETWEEN ''2024-01-20 09:00'' AND ''2024-01-20 17:00''';
PRINT '';

PRINT '=================================================================';
PRINT 'TEMPORAL QUERIES DEMONSTRATED SUCCESSFULLY!';
PRINT '=================================================================';

/*
============================================================================
TEMPORAL QUERY SUMMARY
============================================================================

✅ DEMONSTRATED QUERIES:

1. AS OF - Point-in-time snapshots
   SELECT * FROM table FOR SYSTEM_TIME AS OF '2024-01-01'

2. ALL - Complete history
   SELECT * FROM table FOR SYSTEM_TIME ALL

3. BETWEEN - Date ranges
   SELECT * FROM table FOR SYSTEM_TIME BETWEEN x AND y

4. Price Change Analysis
   - Trend detection (increase/decrease)
   - Percentage change calculations

5. Inventory Tracking
   - Stock level history
   - Availability over time

6. Audit Trails
   - Who changed what
   - When changes occurred

7. Time Travel Joins
   - Consistent point-in-time across multiple tables

8. Deleted Row Detection
   - Find rows that were deleted
   - When deletion occurred

9. Data Recovery
   - Restore deleted rows
   - Rollback to previous version

10. Performance Analysis
    - History table size
    - Row counts

REAL-WORLD USE CASES:

📊 Business Intelligence:
   - "What was our inventory value last quarter?"
   - "Show pricing trends over last 6 months"

🔍 Forensics:
   - "Who deleted customer record #12345?"
   - "When did product price drop below cost?"

📜 Compliance:
   - "Prove data state for SOX audit"
   - "HIPAA: Show patient record at time of complaint"

🛡️ Data Protection:
   - "Restore accidentally deleted records"
   - "Rollback corrupted data to last known good"

📈 Trend Analysis:
   - "Price volatility analysis"
   - "Inventory turnover patterns"

PERFORMANCE BEST PRACTICES:

✅ Index ValidFrom/ValidTo columns on history table
✅ Use page compression on history table
✅ Partition history table by date
✅ Set retention policy for very active tables
✅ Archive old history to blob storage

❌ Avoid SELECT * on history tables
❌ Don't query ALL without WHERE clause
❌ Don't use for real-time CDC (use Change Tracking)

Next: History analysis and change patterns!
============================================================================
*/
