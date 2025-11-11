-- ========================================
-- Statistics Management
-- Creating, Updating, and Analyzing Statistics
-- ========================================

USE TechStore;
GO

-- =============================================
-- What Are Statistics?
-- =============================================

/*
Statistics are metadata about data distribution in columns and indexes.
The query optimizer uses statistics to:
- Estimate row counts (cardinality estimation)
- Choose optimal execution plans
- Decide between index seek vs scan
- Choose join strategies (nested loops, hash, merge)

Statistics contain:
1. HEADER: Rows, pages, last update date
2. DENSITY VECTOR: Uniqueness measures (selectivity)
3. HISTOGRAM: Distribution of values (up to 200 steps)
*/

-- =============================================
-- Example 1: Viewing Statistics
-- =============================================

-- Show all statistics on Products table
SELECT 
    s.name AS StatName,
    s.stats_id AS StatID,
    s.auto_created,
    s.user_created,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    sp.rows AS TotalRows,
    sp.rows_sampled AS RowsSampled,
    sp.modification_counter AS ModificationCnt
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE s.object_id = OBJECT_ID('Products')
ORDER BY s.name;
GO

-- View statistics details (header, density, histogram)
DBCC SHOW_STATISTICS('Products', 'PK_Products');  -- Replace with actual index name
GO

-- =============================================
-- Example 2: Understanding DBCC SHOW_STATISTICS
-- =============================================

-- Create index for demo
CREATE NONCLUSTERED INDEX IX_Products_Price ON Products (Price);
GO

-- View statistics
DBCC SHOW_STATISTICS('Products', 'IX_Products_Price');
GO

/*
Result set 1: HEADER
- Rows: Total rows in table
- Rows Sampled: Rows scanned to build stats
- Steps: Histogram buckets (max 200)
- Density: 1 / distinct values (selectivity)
- Average Key Length: Bytes per key value
- Updated: Last update timestamp
- Modification Counter: Changes since last update

Result set 2: DENSITY VECTOR
- All Density: Overall uniqueness
- Average Length: Bytes for column(s)
- Columns: Which columns included

Result set 3: HISTOGRAM
- RANGE_HI_KEY: Upper bound of histogram step
- RANGE_ROWS: Rows between this step and previous (exclusive)
- EQ_ROWS: Rows equal to RANGE_HI_KEY
- DISTINCT_RANGE_ROWS: Distinct values in range
- AVG_RANGE_ROWS: Average rows per distinct value
*/

-- =============================================
-- Example 3: Auto-Created Statistics
-- =============================================

-- SQL Server auto-creates statistics when:
-- 1. Column used in WHERE clause
-- 2. No existing statistics on that column
-- 3. AUTO_CREATE_STATISTICS is ON (default)

-- Check database setting
SELECT name, is_auto_create_stats_on
FROM sys.databases
WHERE name = 'TechStore';
GO

-- Force auto-create by querying non-indexed column
SELECT * FROM Products
WHERE StockQuantity > 50;
-- SQL Server creates statistics on StockQuantity
GO

-- View auto-created statistics
SELECT 
    s.name AS StatName,
    s.auto_created,
    COL_NAME(sc.object_id, sc.column_id) AS ColumnName
FROM sys.stats s
INNER JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
WHERE s.object_id = OBJECT_ID('Products')
AND s.auto_created = 1;
GO

-- =============================================
-- Example 4: Creating Manual Statistics
-- =============================================

-- Create single-column statistics
CREATE STATISTICS Stats_Category 
ON Products (Category);
GO

-- Create multi-column statistics (correlation)
CREATE STATISTICS Stats_Category_Price 
ON Products (Category, Price)
WITH FULLSCAN;  -- Scan all rows (most accurate)
GO

-- Create statistics with sampling
CREATE STATISTICS Stats_StockQuantity 
ON Products (StockQuantity)
WITH SAMPLE 50 PERCENT;  -- Sample 50% of rows
GO

-- Create filtered statistics (subset of data)
CREATE STATISTICS Stats_ActiveProducts 
ON Products (Price)
WHERE IsActive = 1;  -- Only for active products
GO

-- View user-created statistics
SELECT 
    s.name AS StatName,
    s.user_created,
    s.has_filter,
    s.filter_definition,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated
FROM sys.stats s
WHERE s.object_id = OBJECT_ID('Products')
AND s.user_created = 1;
GO

-- =============================================
-- Example 5: Updating Statistics
-- =============================================

-- Update all statistics on table (default sampling)
UPDATE STATISTICS Products;
GO

-- Update all statistics with FULLSCAN
UPDATE STATISTICS Products WITH FULLSCAN;
-- Scans 100% of rows (most accurate, slowest)
GO

-- Update all statistics with specific sampling
UPDATE STATISTICS Products WITH SAMPLE 25 PERCENT;
GO

-- Update specific statistics
UPDATE STATISTICS Products IX_Products_Price WITH FULLSCAN;
GO

-- Update all statistics in database
EXEC sp_updatestats;  -- Updates all stats in current database
GO

-- =============================================
-- Example 6: Auto-Update Statistics
-- =============================================

-- Check auto-update setting
SELECT name, is_auto_update_stats_on, is_auto_update_stats_async_on
FROM sys.databases
WHERE name = 'TechStore';
GO

-- Auto-update threshold:
-- Table < 500 rows: Updates after 500 changes
-- Table >= 500 rows: Updates after 500 + 20% of rows change

-- Example: Table with 1000 rows needs 500 + (1000 * 0.2) = 700 changes

-- View modification counter
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatName,
    sp.modification_counter AS ModificationsSinceUpdate,
    sp.rows AS TotalRows,
    CASE 
        WHEN sp.rows < 500 THEN 500
        ELSE 500 + (sp.rows * 0.2)
    END AS UpdateThreshold,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE s.object_id = OBJECT_ID('Products')
ORDER BY sp.modification_counter DESC;
GO

-- =============================================
-- Example 7: Histogram Analysis
-- =============================================

-- Create table variable to capture histogram
DECLARE @Histogram TABLE (
    RANGE_HI_KEY SQL_VARIANT,
    RANGE_ROWS FLOAT,
    EQ_ROWS FLOAT,
    DISTINCT_RANGE_ROWS BIGINT,
    AVG_RANGE_ROWS FLOAT
);

-- Capture histogram (manual process - query result set 3)
-- DBCC SHOW_STATISTICS('Products', 'IX_Products_Price');

-- Analyze histogram manually:
-- 1. Check if histogram is up to date (Updated timestamp)
-- 2. Check if steps cover entire range (200 steps max)
-- 3. Check for skewed data (high EQ_ROWS in specific steps)
-- 4. Check for ascending key problem (newest data not in histogram)

-- =============================================
-- Example 8: Statistics and Cardinality Estimation
-- =============================================

-- Enable actual execution plan to see estimates

-- Query 1: Exact match (uses histogram EQ_ROWS)
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT * FROM Products
WHERE Price = 99.99;
-- Estimated rows should match EQ_ROWS from histogram
GO

-- Query 2: Range query (uses RANGE_ROWS and AVG_RANGE_ROWS)
SELECT * FROM Products
WHERE Price BETWEEN 100 AND 200;
-- Estimated rows calculated from histogram steps
GO

-- Query 3: Inequality (uses density and histogram)
SELECT * FROM Products
WHERE Price > 500;
-- Uses histogram steps above 500
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Compare estimated vs actual rows in execution plan
-- Large differences indicate stale or inaccurate statistics

-- =============================================
-- Example 9: Identifying Stale Statistics
-- =============================================

-- Find statistics not updated recently
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) AS DaysSinceUpdate,
    sp.modification_counter AS Modifications,
    sp.rows AS TotalRows
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE s.object_id = OBJECT_ID('Products')
AND STATS_DATE(s.object_id, s.stats_id) IS NOT NULL
ORDER BY DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) DESC;
GO

-- Find statistics with high modification count
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatName,
    sp.modification_counter AS Modifications,
    sp.rows AS TotalRows,
    CAST(sp.modification_counter AS FLOAT) / sp.rows AS ModificationPct,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE s.object_id = OBJECT_ID('Products')
AND sp.rows > 0
ORDER BY CAST(sp.modification_counter AS FLOAT) / sp.rows DESC;
GO

-- =============================================
-- Example 10: Statistics on Computed Columns
-- =============================================

-- Add computed column
ALTER TABLE Products ADD DiscountedPrice AS (Price * 0.9);
GO

-- Create statistics on computed column
CREATE STATISTICS Stats_DiscountedPrice 
ON Products (DiscountedPrice)
WITH FULLSCAN;
GO

-- Query uses statistics
SELECT * FROM Products
WHERE DiscountedPrice < 100;
GO

-- Cleanup
ALTER TABLE Products DROP COLUMN DiscountedPrice;
GO

-- =============================================
-- Example 11: Incremental Statistics (Partitioned Tables)
-- =============================================

-- For partitioned tables, incremental statistics update only changed partitions
-- (Feature available in Enterprise Edition)

/*
-- Create partitioned table (example)
CREATE STATISTICS Stats_SaleDate 
ON Sales (SaleDate)
WITH INCREMENTAL = ON;

-- When partition changes, only that partition's stats updated
UPDATE STATISTICS Sales Stats_SaleDate 
WITH RESAMPLE ON PARTITIONS(5);  -- Update only partition 5
*/

-- =============================================
-- Example 12: Statistics and Query Performance
-- =============================================

-- Demonstrate impact of stale statistics

-- Create test table
CREATE TABLE #StatsDemo (
    ID INT PRIMARY KEY,
    Value INT,
    Category VARCHAR(50)
);

-- Insert 1000 rows with Category = 'A'
INSERT INTO #StatsDemo (ID, Value, Category)
SELECT TOP 1000 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
    ABS(CHECKSUM(NEWID())) % 1000,
    'A'
FROM sys.objects a CROSS JOIN sys.objects b;

-- Create statistics
CREATE STATISTICS Stats_Category ON #StatsDemo (Category) WITH FULLSCAN;
GO

-- Query with good statistics
SET STATISTICS IO ON;
SELECT * FROM #StatsDemo WHERE Category = 'A';
-- Should estimate ~1000 rows (accurate)
SET STATISTICS IO OFF;
GO

-- Now insert 10000 rows with Category = 'B' (without updating stats)
INSERT INTO #StatsDemo (ID, Value, Category)
SELECT TOP 10000 
    1000 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
    ABS(CHECKSUM(NEWID())) % 1000,
    'B'
FROM sys.objects a CROSS JOIN sys.objects b CROSS JOIN sys.objects c;
GO

-- Query with stale statistics
SET STATISTICS IO ON;
SELECT * FROM #StatsDemo WHERE Category = 'B';
-- Estimate will be wrong (stats don't know about 'B')
SET STATISTICS IO OFF;
GO

-- Update statistics
UPDATE STATISTICS #StatsDemo WITH FULLSCAN;
GO

-- Query with fresh statistics
SET STATISTICS IO ON;
SELECT * FROM #StatsDemo WHERE Category = 'B';
-- Now estimate ~10000 rows (accurate)
SET STATISTICS IO OFF;
GO

DROP TABLE #StatsDemo;
GO

-- =============================================
-- Example 13: Trace Flag 2371 (Dynamic Update Threshold)
-- =============================================

/*
By default, auto-update threshold = 500 + (20% of rows)
For large tables (millions of rows), 20% is too high

Trace Flag 2371 (SQL 2016+):
- Uses dynamic threshold based on table size
- Larger tables have lower percentage threshold
- Example: 1M row table needs ~10% change instead of 20%

Enable globally:
DBCC TRACEON (2371, -1);

Or at database level (SQL 2016+):
ALTER DATABASE SCOPED CONFIGURATION SET AUTO_UPDATE_STATISTICS_ASYNC = ON;
*/

-- =============================================
-- Example 14: Asynchronous Statistics Update
-- =============================================

-- Enable async stats update
ALTER DATABASE TechStore SET AUTO_UPDATE_STATISTICS_ASYNC ON;
GO

/*
How it works:
1. Query finds stale statistics
2. Query uses OLD statistics (doesn't block)
3. Background thread updates statistics
4. Future queries use NEW statistics

Pros: Queries don't block waiting for stats update
Cons: First query after change uses stale stats
*/

-- Check setting
SELECT name, is_auto_update_stats_async_on
FROM sys.databases
WHERE name = 'TechStore';
GO

-- Disable (return to default)
ALTER DATABASE TechStore SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
GO

-- =============================================
-- Example 15: Maintenance Script for Statistics
-- =============================================

CREATE OR ALTER PROCEDURE usp_UpdateAllStatistics
    @SamplePercent INT = NULL,  -- NULL = default sampling
    @FullScan BIT = 0,
    @DatabaseName SYSNAME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use current database if not specified
    IF @DatabaseName IS NULL
        SET @DatabaseName = DB_NAME();
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TableName SYSNAME;
    DECLARE @SchemaName SYSNAME;
    DECLARE @StatName SYSNAME;
    DECLARE @UpdateOption NVARCHAR(50);
    
    -- Build update option
    IF @FullScan = 1
        SET @UpdateOption = 'WITH FULLSCAN';
    ELSE IF @SamplePercent IS NOT NULL
        SET @UpdateOption = 'WITH SAMPLE ' + CAST(@SamplePercent AS VARCHAR(10)) + ' PERCENT';
    ELSE
        SET @UpdateOption = '';  -- Default sampling
    
    -- Cursor through all statistics
    DECLARE StatsCursor CURSOR FOR
    SELECT 
        SCHEMA_NAME(t.schema_id) AS SchemaName,
        t.name AS TableName,
        s.name AS StatName
    FROM sys.stats s
    INNER JOIN sys.tables t ON s.object_id = t.object_id
    WHERE t.is_ms_shipped = 0  -- Exclude system tables
    ORDER BY t.name, s.name;
    
    OPEN StatsCursor;
    FETCH NEXT FROM StatsCursor INTO @SchemaName, @TableName, @StatName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @SQL = 'UPDATE STATISTICS [' + @SchemaName + '].[' + @TableName + '] [' + @StatName + '] ' + @UpdateOption;
            PRINT 'Updating: ' + @SchemaName + '.' + @TableName + '.' + @StatName;
            EXEC sp_executesql @SQL;
        END TRY
        BEGIN CATCH
            PRINT 'Error updating ' + @SchemaName + '.' + @TableName + '.' + @StatName + ': ' + ERROR_MESSAGE();
        END CATCH;
        
        FETCH NEXT FROM StatsCursor INTO @SchemaName, @TableName, @StatName;
    END
    
    CLOSE StatsCursor;
    DEALLOCATE StatsCursor;
    
    PRINT 'Statistics update completed';
END;
GO

-- Test the procedure
EXEC usp_UpdateAllStatistics @FullScan = 1;
GO

-- =============================================
-- Example 16: Identifying Missing Statistics
-- =============================================

-- Find columns without statistics (excluding indexed columns)
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    c.column_id
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name = 'Products'
AND c.column_id NOT IN (
    -- Exclude columns with statistics
    SELECT sc.column_id
    FROM sys.stats s
    INNER JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
    WHERE s.object_id = t.object_id
)
ORDER BY c.column_id;
GO

-- =============================================
-- Example 17: Statistics Sampling Accuracy
-- =============================================

-- Compare different sampling methods
CREATE STATISTICS Stats_Price_Default ON Products (Price);  -- Default
CREATE STATISTICS Stats_Price_Sample25 ON Products (Price) WITH SAMPLE 25 PERCENT;
CREATE STATISTICS Stats_Price_Sample50 ON Products (Price) WITH SAMPLE 50 PERCENT;
CREATE STATISTICS Stats_Price_FullScan ON Products (Price) WITH FULLSCAN;
GO

-- View sampling details
SELECT 
    s.name AS StatName,
    sp.rows AS TotalRows,
    sp.rows_sampled AS RowsSampled,
    CAST(sp.rows_sampled AS FLOAT) / sp.rows * 100 AS SamplePct,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE s.object_id = OBJECT_ID('Products')
AND s.name LIKE 'Stats_Price_%'
ORDER BY sp.rows_sampled;
GO

-- Cleanup
DROP STATISTICS Products.Stats_Price_Default;
DROP STATISTICS Products.Stats_Price_Sample25;
DROP STATISTICS Products.Stats_Price_Sample50;
DROP STATISTICS Products.Stats_Price_FullScan;
GO

-- =============================================
-- Cleanup
-- =============================================

IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID('Products') AND name = 'Stats_Category')
    DROP STATISTICS Products.Stats_Category;
IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID('Products') AND name = 'Stats_Category_Price')
    DROP STATISTICS Products.Stats_Category_Price;
IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID('Products') AND name = 'Stats_StockQuantity')
    DROP STATISTICS Products.Stats_StockQuantity;
IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID('Products') AND name = 'Stats_ActiveProducts')
    DROP STATISTICS Products.Stats_ActiveProducts;

DROP INDEX IF EXISTS IX_Products_Price ON Products;
DROP PROCEDURE IF EXISTS usp_UpdateAllStatistics;
GO

-- 💡 Key Takeaways:
--
-- WHAT ARE STATISTICS?
-- - Metadata about data distribution (histogram, density)
-- - Used by optimizer for cardinality estimation
-- - Critical for optimal execution plans
-- - Automatically created on indexes
-- - Auto-created on columns in WHERE clauses
--
-- STATISTICS COMPONENTS:
-- 1. HEADER: Row count, last update, modification counter
-- 2. DENSITY VECTOR: Uniqueness (1 / distinct values)
-- 3. HISTOGRAM: Distribution (up to 200 steps)
--
-- AUTO-CREATE/UPDATE:
-- - AUTO_CREATE_STATISTICS: ON by default (recommended)
-- - AUTO_UPDATE_STATISTICS: ON by default (recommended)
-- - Update threshold: 500 + (20% of rows)
-- - Use Trace Flag 2371 for dynamic threshold (large tables)
--
-- WHEN TO MANUALLY UPDATE:
-- - After bulk inserts/updates (> 20% of table)
-- - After index rebuilds (stats auto-updated)
-- - Scheduled maintenance (nightly/weekly)
-- - Query plans show estimate << actual rows
-- - New queries performing poorly
--
-- SAMPLING OPTIONS:
-- - Default: SQL Server chooses sample size
-- - SAMPLE n PERCENT: Specific percentage (faster, less accurate)
-- - FULLSCAN: 100% of rows (slowest, most accurate)
-- - RESAMPLE: Use previous sampling method
--
-- BEST PRACTICES:
-- - Enable AUTO_CREATE and AUTO_UPDATE (default)
-- - Update stats WITH FULLSCAN after bulk loads
-- - Create multi-column stats for correlated columns
-- - Use filtered stats for large tables with subsets
-- - Monitor stale stats (modification_counter)
-- - Check execution plans (estimated vs actual rows)
-- - Update stats before index maintenance (rebuild auto-updates)
-- - Consider async update for large tables (SQL 2016+)
-- - Use Trace Flag 2371 for large tables (dynamic threshold)
--
-- MONITORING:
-- - sys.stats: All statistics
-- - sys.dm_db_stats_properties: Statistics properties
-- - STATS_DATE(): Last update timestamp
-- - DBCC SHOW_STATISTICS: Detailed histogram
-- - Execution plans: Estimated vs actual rows
--
-- COMMANDS:
-- - CREATE STATISTICS: Manual statistics
-- - UPDATE STATISTICS: Refresh statistics
-- - sp_updatestats: Update all in database
-- - DBCC SHOW_STATISTICS: View details
-- - DROP STATISTICS: Remove manual stats
--
-- COMMON ISSUES:
-- - Stale statistics → Poor execution plans
-- - Ascending key problem → Newest data not in histogram
-- - Parameter sniffing → Cached plan with wrong estimates
-- - Missing multi-column stats → Correlation not captured
-- - Auto-update threshold too high → Large tables don't update
