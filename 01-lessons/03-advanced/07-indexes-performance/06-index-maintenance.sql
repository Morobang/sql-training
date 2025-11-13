-- ========================================
-- Index Maintenance and Statistics
-- Keeping Indexes Healthy
-- ========================================

USE TechStore;
GO

-- =============================================
-- Understanding Index Fragmentation
-- =============================================

/*
Fragmentation Types:
1. Logical Fragmentation (External):
   - Logical page order doesn't match physical order
   - Causes inefficient I/O (disk head jumping)
   
2. Internal Fragmentation:
   - Pages not fully utilized (wasted space)
   - Caused by page splits

Fragmentation Levels:
- <10%: No action needed
- 10-30%: REORGANIZE
- >30%: REBUILD
*/

-- =============================================
-- Example 1: Check Index Fragmentation
-- =============================================

-- View fragmentation for all indexes
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.index_type_desc AS IndexStructure,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount,
    ips.avg_page_space_used_in_percent AS AvgPageFullness,
    ips.fragment_count AS FragmentCount
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100  -- Only indexes with significant size
    AND OBJECT_NAME(ips.object_id) IN ('Products', 'Customers', 'Sales')
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- =============================================
-- Example 2: Reorganize vs Rebuild Decision
-- =============================================

-- Script to get recommended maintenance action
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'No Action'
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 'REORGANIZE'
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
    END AS RecommendedAction,
    CASE 
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 
        THEN 'ALTER INDEX ' + i.name + ' ON ' + OBJECT_NAME(ips.object_id) + ' REORGANIZE;'
        WHEN ips.avg_fragmentation_in_percent > 30 
        THEN 'ALTER INDEX ' + i.name + ' ON ' + OBJECT_NAME(ips.object_id) + ' REBUILD;'
        ELSE 'No action needed'
    END AS MaintenanceCommand
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100
    AND i.index_id > 0  -- Exclude heaps
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- =============================================
-- Example 3: Reorganize Indexes
-- =============================================

-- Reorganize specific index
ALTER INDEX PK__Products__B40CC6CDA8E3A7E1 ON Products REORGANIZE;
GO

-- Reorganize all indexes on a table
ALTER INDEX ALL ON Products REORGANIZE;
GO

/*
REORGANIZE characteristics:
✅ Online operation (no locking)
✅ Low resource usage
✅ Can be stopped and resumed
✅ Defragments leaf level only
❌ Less thorough than REBUILD
❌ Doesn't update statistics automatically
*/

-- =============================================
-- Example 4: Rebuild Indexes
-- =============================================

-- Rebuild specific index (offline by default)
ALTER INDEX PK__Customers__A4AE64D8F8A47A7B ON Customers REBUILD;
GO

-- Rebuild with options
ALTER INDEX PK__Products__B40CC6CDA8E3A7E1 ON Products REBUILD
WITH (
    FILLFACTOR = 90,  -- Leave 10% free space
    SORT_IN_TEMPDB = ON,  -- Use tempdb for sort operations
    STATISTICS_NORECOMPUTE = OFF,  -- Update statistics after rebuild
    ONLINE = OFF  -- Offline rebuild (Enterprise Edition supports ONLINE=ON)
);
GO

-- Rebuild all indexes on table
ALTER INDEX ALL ON Sales REBUILD;
GO

/*
REBUILD characteristics:
✅ Completely recreates index (like DROP + CREATE)
✅ Removes all fragmentation
✅ Compacts pages (better space utilization)
✅ Updates statistics automatically
❌ Resource intensive (CPU, I/O, temp space)
❌ Locks table (unless ONLINE=ON in Enterprise Edition)
❌ Takes longer than REORGANIZE
*/

-- =============================================
-- Example 5: FILLFACTOR
-- =============================================

-- Create index with FILLFACTOR
CREATE NONCLUSTERED INDEX IX_Products_Price_FillFactor
ON Products(Price)
WITH (FILLFACTOR = 80);  -- Leave 20% free space on each page
GO

/*
FILLFACTOR Guidelines:
- 100: No free space (good for read-only data)
- 90-95: Minimal free space (good for mostly read operations)
- 80-85: Moderate free space (balanced read/write)
- 70-75: Significant free space (frequent inserts/updates)

Use Case:
- High FILLFACTOR (95-100): Static reference tables
- Low FILLFACTOR (70-80): High transaction tables with frequent page splits
*/

-- Check current FILLFACTOR
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.fill_factor AS FillFactorValue
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('Products')
    AND i.name IS NOT NULL
ORDER BY i.name;
GO

DROP INDEX IX_Products_Price_FillFactor ON Products;
GO

-- =============================================
-- Example 6: Statistics Overview
-- =============================================

-- View statistics for table
SELECT 
    s.name AS StatName,
    s.stats_id AS StatID,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    s.auto_created AS AutoCreated,
    s.user_created AS UserCreated,
    s.no_recompute AS NoAutoUpdate,
    STRING_AGG(c.name, ', ') AS ColumnNames
FROM sys.stats s
INNER JOIN sys.stats_columns sc ON s.object_id = sc.object_id AND s.stats_id = sc.stats_id
INNER JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
WHERE s.object_id = OBJECT_ID('Products')
GROUP BY s.name, s.stats_id, s.object_id, s.auto_created, s.user_created, s.no_recompute
ORDER BY s.name;
GO

-- =============================================
-- Example 7: Update Statistics
-- =============================================

-- Update statistics for specific table
UPDATE STATISTICS Products;
GO

-- Update statistics for specific index
UPDATE STATISTICS Products PK__Products__B40CC6CDA8E3A7E1;
GO

-- Update statistics with full scan (most accurate)
UPDATE STATISTICS Products WITH FULLSCAN;
GO

-- Update statistics with sample
UPDATE STATISTICS Products WITH SAMPLE 50 PERCENT;
GO

-- Update all statistics in database (use with caution!)
-- EXEC sp_updatestats;

-- =============================================
-- Example 8: View Statistics Details
-- =============================================

-- Show detailed statistics information
DBCC SHOW_STATISTICS('Products', 'PK__Products__B40CC6CDA8E3A7E1');
GO

/*
DBCC SHOW_STATISTICS output:
1. Statistics Header: Update date, rows, sample percentage
2. Density Vector: Uniqueness of column combinations
3. Histogram: Distribution of values (up to 200 steps)
*/

-- =============================================
-- Example 9: Automatic Statistics
-- =============================================

-- Check auto-create and auto-update settings
SELECT 
    name AS DatabaseName,
    is_auto_create_stats_on AS AutoCreateStats,
    is_auto_update_stats_on AS AutoUpdateStats,
    is_auto_update_stats_async_on AS AutoUpdateStatsAsync
FROM sys.databases
WHERE database_id = DB_ID();
GO

-- Enable/disable automatic statistics (database level)
-- ALTER DATABASE TechStore SET AUTO_CREATE_STATISTICS ON;
-- ALTER DATABASE TechStore SET AUTO_UPDATE_STATISTICS ON;
-- ALTER DATABASE TechStore SET AUTO_UPDATE_STATISTICS_ASYNC ON;

-- Disable auto-update for specific statistics (not recommended)
-- UPDATE STATISTICS Products IX_Products_Category WITH NORECOMPUTE;

-- =============================================
-- Example 10: Comprehensive Maintenance Script
-- =============================================

-- Maintenance script with fragmentation-based logic
DECLARE @TableName VARCHAR(255);
DECLARE @IndexName VARCHAR(255);
DECLARE @Fragmentation FLOAT;
DECLARE @PageCount INT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE index_cursor CURSOR FOR
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100  -- Only significant indexes
    AND i.index_id > 0  -- Exclude heaps
    AND i.is_disabled = 0
    AND OBJECT_NAME(ips.object_id) IN ('Products', 'Customers', 'Sales');

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation, @PageCount;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
    BEGIN
        -- Rebuild for high fragmentation
        SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@TableName) + ' REBUILD WITH (FILLFACTOR = 90);';
        PRINT 'REBUILD: ' + @SQL;
        EXEC sp_executesql @SQL;
    END
    ELSE IF @Fragmentation > 10
    BEGIN
        -- Reorganize for moderate fragmentation
        SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@TableName) + ' REORGANIZE;';
        PRINT 'REORGANIZE: ' + @SQL;
        EXEC sp_executesql @SQL;
    END
    ELSE
    BEGIN
        PRINT 'No action needed for ' + @TableName + '.' + @IndexName + ' (Fragmentation: ' + CAST(@Fragmentation AS VARCHAR(10)) + '%)';
    END
    
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation, @PageCount;
END;

CLOSE index_cursor;
DEALLOCATE index_cursor;

PRINT 'Index maintenance completed';
GO

-- =============================================
-- Example 11: Update Statistics for All Tables
-- =============================================

-- Update statistics for key tables
UPDATE STATISTICS Products WITH FULLSCAN;
UPDATE STATISTICS Customers WITH FULLSCAN;
UPDATE STATISTICS Sales WITH FULLSCAN;
GO

PRINT 'Statistics updated for all tables';
GO

-- =============================================
-- Example 12: Monitor Index Maintenance Jobs
-- =============================================

-- Check when indexes were last rebuilt/reorganized (indirectly via stats date)
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    STATS_DATE(s.object_id, s.stats_id) AS LastStatsUpdate,
    DATEDIFF(DAY, STATS_DATE(s.object_id, s.stats_id), GETDATE()) AS DaysSinceUpdate
FROM sys.stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.stats_id = i.index_id
WHERE i.object_id IN (OBJECT_ID('Products'), OBJECT_ID('Customers'), OBJECT_ID('Sales'))
    AND i.index_id > 0
ORDER BY DaysSinceUpdate DESC;
GO

-- =============================================
-- Example 13: Page Splits Monitoring
-- =============================================

-- Check for page splits (indicates need for lower FILLFACTOR or maintenance)
-- This requires starting a trace or using Extended Events in production

-- Indirect check: high fragmentation on recently maintained index = page splits
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    STATS_DATE(i.object_id, i.index_id) AS LastMaintenance,
    CASE 
        WHEN STATS_DATE(i.object_id, i.index_id) > DATEADD(DAY, -7, GETDATE()) 
             AND ips.avg_fragmentation_in_percent > 15
        THEN 'Possible page splits - consider lower FILLFACTOR'
        ELSE 'Normal'
    END AS Analysis
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100;
GO

-- =============================================
-- Example 14: Maintenance Best Practices
-- =============================================

/*
Index Maintenance Schedule Recommendations:

DAILY:
- Check for high fragmentation on critical indexes
- Update statistics on high-transaction tables

WEEKLY:
- REORGANIZE indexes with 10-30% fragmentation
- Update statistics on all user tables

MONTHLY:
- REBUILD indexes with >30% fragmentation
- Full statistics update with FULLSCAN
- Review unused indexes for potential removal

Ad-hoc:
- After bulk data loads (rebuild + update stats)
- After significant data changes
- Before important reports/operations

Automation:
- Use SQL Server Maintenance Plans
- Use Ola Hallengren's scripts (industry standard)
- Schedule during low-activity windows
*/

-- =============================================
-- Example 15: Cost of Maintenance
-- =============================================

-- Estimate rebuild time and resources needed
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    SUM(ps.used_page_count) * 8 / 1024.0 AS SizeMB,
    SUM(ps.row_count) AS RowCnt,
    CASE 
        WHEN SUM(ps.used_page_count) * 8 / 1024.0 < 100 THEN '< 1 minute'
        WHEN SUM(ps.used_page_count) * 8 / 1024.0 < 1000 THEN '1-5 minutes'
        ELSE '> 5 minutes'
    END AS EstimatedRebuildTime
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id IN (OBJECT_ID('Products'), OBJECT_ID('Customers'), OBJECT_ID('Sales'))
    AND i.index_id > 0
GROUP BY OBJECT_NAME(i.object_id), i.name, i.object_id, i.index_id
ORDER BY SizeMB DESC;
GO

-- 💡 Key Takeaways:
-- - Fragmentation < 10%: No action needed
-- - Fragmentation 10-30%: REORGANIZE (online, low impact)
-- - Fragmentation > 30%: REBUILD (offline unless Enterprise ONLINE option)
-- - REORGANIZE: Online, defragments leaf level, doesn't update stats
-- - REBUILD: Offline, complete recreation, updates stats automatically
-- - FILLFACTOR: Lower = more free space, fewer page splits, larger index
-- - Update statistics after bulk data changes
-- - Auto-update statistics triggers after ~20% of rows change
-- - FULLSCAN most accurate, but slower than sampling
-- - Check STATS_DATE() to see last statistics update
-- - Use sys.dm_db_index_physical_stats to monitor fragmentation
-- - Schedule maintenance during low-activity windows
-- - Rebuild clustered index also rebuilds all nonclustered indexes
-- - Use Ola Hallengren's scripts for production maintenance
-- - Monitor page splits to tune FILLFACTOR
-- - Consider SORT_IN_TEMPDB for large rebuilds
