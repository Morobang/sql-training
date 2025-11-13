-- ========================================
-- Partition Maintenance
-- Rebuild, Statistics, Monitoring
-- ========================================

USE TechStore;
GO

-- =============================================
-- Setup: Use existing partition from previous examples
-- =============================================

-- Assuming pfSlidingWindow partition function exists
-- If not, run 01-partition-basics.sql and 02-sliding-window.sql first

-- =============================================
-- Example 1: Rebuild Specific Partition
-- =============================================

-- Rebuild partition 3 only (much faster than entire table)
ALTER INDEX PK_SalesHistory ON SalesHistory
REBUILD PARTITION = 3
WITH (ONLINE = OFF);
GO

-- ONLINE = ON for Enterprise Edition (no downtime)
-- ONLINE = OFF for Standard Edition

-- =============================================
-- Example 2: Rebuild All Partitions
-- =============================================

-- Rebuild all partitions
ALTER INDEX PK_SalesHistory ON SalesHistory
REBUILD PARTITION = ALL
WITH (ONLINE = OFF);
GO

-- Or rebuild specific partitions in loop
DECLARE @PartitionNum INT = 1;
DECLARE @MaxPartition INT = 13;

WHILE @PartitionNum <= @MaxPartition
BEGIN
    PRINT 'Rebuilding partition ' + CAST(@PartitionNum AS VARCHAR(10));
    
    DECLARE @SQL NVARCHAR(500);
    SET @SQL = N'ALTER INDEX PK_SalesHistory ON SalesHistory REBUILD PARTITION = ' 
        + CAST(@PartitionNum AS VARCHAR(10)) + ' WITH (ONLINE = OFF)';
    
    EXEC sp_executesql @SQL;
    
    SET @PartitionNum = @PartitionNum + 1;
END;
GO

-- =============================================
-- Example 3: Update Statistics Per Partition
-- =============================================

-- Update statistics on specific partition
UPDATE STATISTICS SalesHistory
WITH FULLSCAN;
GO

-- For individual partitions, use filtered statistics
-- Create filtered statistic for partition 3
CREATE STATISTICS ST_SalesHistory_P3
ON SalesHistory(SaleDate, CustomerID)
WHERE SaleDate >= '2024-03-01' AND SaleDate < '2024-04-01'
WITH FULLSCAN;
GO

-- =============================================
-- Example 4: Monitor Index Fragmentation Per Partition
-- =============================================

SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.partition_number AS PartitionNum,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent AS FragmentationPct,
    ips.page_count,
    ips.record_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS Action
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID('SalesHistory'), 
    NULL, 
    NULL, 
    'DETAILED'
) ips
JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE ips.index_id > 0  -- Exclude heap
ORDER BY ips.partition_number, i.name;
GO

-- =============================================
-- Example 5: Reorganize Fragmented Partitions
-- =============================================

-- Reorganize partition 5 (if fragmented 10-30%)
ALTER INDEX PK_SalesHistory ON SalesHistory
REORGANIZE PARTITION = 5;
GO

-- Reorganize is online operation, but slower than rebuild

-- =============================================
-- Example 6: Verify Partition Elimination
-- =============================================

-- Query with partition elimination
SET STATISTICS IO ON;
SET STATISTICS XML ON;

SELECT 
    SaleID,
    SaleDate,
    TotalAmount
FROM SalesHistory
WHERE SaleDate >= '2024-06-01' AND SaleDate < '2024-07-01';
GO

SET STATISTICS IO OFF;
SET STATISTICS XML OFF;
GO

-- Check execution plan:
-- - Look for "Actual Partition Count"
-- - Should be 1 (partition 7)
-- - "Partition Ids Accessed: [7]"

-- =============================================
-- Example 7: Partition Elimination Report
-- =============================================

-- Test various queries for partition elimination
DECLARE @StartDate DATE = '2024-06-01';
DECLARE @EndDate DATE = '2024-07-01';

-- Good: Partition elimination works
SELECT 'Good - Single partition' AS QueryType, COUNT(*) AS RowCnt
FROM SalesHistory
WHERE SaleDate >= @StartDate AND SaleDate < @EndDate;

-- Good: Partition elimination works (2 partitions)
SELECT 'Good - Two partitions' AS QueryType, COUNT(*) AS RowCnt
FROM SalesHistory
WHERE SaleDate >= '2024-06-01' AND SaleDate < '2024-08-01';

-- Bad: No partition elimination (scans all partitions)
SELECT 'Bad - No elimination' AS QueryType, COUNT(*) AS RowCnt
FROM SalesHistory
WHERE YEAR(SaleDate) = 2024 AND MONTH(SaleDate) = 6;  -- Function on column!

-- Good: Use BETWEEN with partition key
SELECT 'Good - BETWEEN' AS QueryType, COUNT(*) AS RowCnt
FROM SalesHistory
WHERE SaleDate BETWEEN '2024-06-01' AND '2024-06-30';
GO

-- =============================================
-- Example 8: Partition Size Monitoring
-- =============================================

-- Monitor partition sizes over time
SELECT 
    GETDATE() AS CheckDate,
    p.partition_number AS PartitionNum,
    prv.value AS BoundaryValue,
    p.rows AS RowCnt,
    au.total_pages * 8 / 1024.0 AS TotalSizeMB,
    au.used_pages * 8 / 1024.0 AS UsedSizeMB,
    au.data_pages * 8 / 1024.0 AS DataSizeMB,
    (au.total_pages - au.used_pages) * 8 / 1024.0 AS UnusedSizeMB
FROM sys.partitions p
JOIN sys.allocation_units au ON au.container_id = p.partition_id
LEFT JOIN sys.partition_range_values prv 
    ON prv.function_id = (SELECT function_id FROM sys.partition_functions WHERE name = 'pfSlidingWindow')
    AND prv.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('SalesHistory')
    AND p.index_id IN (0, 1)
ORDER BY p.partition_number;
GO

-- Save this to a monitoring table for trend analysis

-- =============================================
-- Example 9: Partition Compression
-- =============================================

-- Compress partition 1 (old data - less frequently accessed)
ALTER INDEX PK_SalesHistory ON SalesHistory
REBUILD PARTITION = 1
WITH (DATA_COMPRESSION = PAGE);
GO

-- Compress partitions 1-3 with different compression levels
ALTER INDEX PK_SalesHistory ON SalesHistory
REBUILD PARTITION = 1
WITH (DATA_COMPRESSION = PAGE);  -- Older data: PAGE compression

ALTER INDEX PK_SalesHistory ON SalesHistory
REBUILD PARTITION = 2
WITH (DATA_COMPRESSION = ROW);  -- Recent data: ROW compression

ALTER INDEX PK_SalesHistory ON SalesHistory
REBUILD PARTITION = 3
WITH (DATA_COMPRESSION = NONE);  -- Current data: No compression
GO

-- =============================================
-- Example 10: Check Compression Status
-- =============================================

SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    i.name AS IndexName,
    p.partition_number AS PartitionNum,
    p.data_compression_desc AS CompressionType,
    p.rows AS RowCnt,
    au.total_pages * 8 / 1024.0 AS SizeMB
FROM sys.partitions p
JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units au ON au.container_id = p.partition_id
WHERE p.object_id = OBJECT_ID('SalesHistory')
    AND p.index_id IN (0, 1)
ORDER BY p.partition_number;
GO

-- =============================================
-- Example 11: Partition Lock Escalation
-- =============================================

-- Set lock escalation to partition level (not table level)
ALTER TABLE SalesHistory
SET (LOCK_ESCALATION = AUTO);  -- AUTO, TABLE, or DISABLE
GO

-- AUTO: Lock escalation to partition level for partitioned tables
-- Reduces contention on large tables

-- =============================================
-- Example 12: Partition-Level Backup
-- =============================================

-- SQL Server doesn't support partition-level backup directly
-- But you can switch partition to separate table and backup that

-- Example: Backup partition 1
-- 1. Create staging table
CREATE TABLE SalesHistory_Backup (
    SaleID INT NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Quantity INT NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_SalesHistory_Backup PRIMARY KEY (SaleID, SaleDate)
) ON [PRIMARY];
GO

-- 2. Switch partition to staging (if needed)
-- ALTER TABLE SalesHistory SWITCH PARTITION 1 TO SalesHistory_Backup;

-- 3. Backup staging table
-- BACKUP DATABASE TechStore TABLE SalesHistory_Backup TO DISK = 'path';

-- 4. Switch back or restore

-- =============================================
-- Example 13: Maintenance Procedure
-- =============================================

CREATE PROCEDURE usp_PartitionMaintenance
    @TableName NVARCHAR(128),
    @FragmentationThreshold DECIMAL(5,2) = 10.0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get fragmented partitions
    DECLARE @PartitionNum INT;
    DECLARE @FragmentationPct DECIMAL(5,2);
    DECLARE @IndexName NVARCHAR(128);
    
    DECLARE PartitionCursor CURSOR FOR
    SELECT 
        i.name,
        ips.partition_number,
        ips.avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(
        DB_ID(), 
        OBJECT_ID(@TableName), 
        NULL, 
        NULL, 
        'LIMITED'
    ) ips
    JOIN sys.indexes i ON i.object_id = ips.object_id AND i.index_id = ips.index_id
    WHERE ips.avg_fragmentation_in_percent >= @FragmentationThreshold
        AND ips.index_id > 0
    ORDER BY ips.partition_number;
    
    OPEN PartitionCursor;
    FETCH NEXT FROM PartitionCursor INTO @IndexName, @PartitionNum, @FragmentationPct;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @SQL NVARCHAR(500);
        DECLARE @Action NVARCHAR(20);
        
        -- Decide action based on fragmentation
        IF @FragmentationPct >= 30
            SET @Action = 'REBUILD';
        ELSE
            SET @Action = 'REORGANIZE';
        
        -- Build and execute SQL
        IF @Action = 'REBUILD'
            SET @SQL = N'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@TableName) 
                + ' REBUILD PARTITION = ' + CAST(@PartitionNum AS VARCHAR(10)) 
                + ' WITH (ONLINE = OFF)';
        ELSE
            SET @SQL = N'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@TableName) 
                + ' REORGANIZE PARTITION = ' + CAST(@PartitionNum AS VARCHAR(10));
        
        PRINT @Action + ' partition ' + CAST(@PartitionNum AS VARCHAR(10)) 
            + ' (fragmentation: ' + CAST(@FragmentationPct AS VARCHAR(10)) + '%)';
        
        EXEC sp_executesql @SQL;
        
        FETCH NEXT FROM PartitionCursor INTO @IndexName, @PartitionNum, @FragmentationPct;
    END;
    
    CLOSE PartitionCursor;
    DEALLOCATE PartitionCursor;
    
    PRINT 'Partition maintenance completed';
END;
GO

-- Execute maintenance
-- EXEC usp_PartitionMaintenance @TableName = 'SalesHistory', @FragmentationThreshold = 10.0;

-- =============================================
-- Example 14: Partition Health Report
-- =============================================

CREATE PROCEDURE usp_PartitionHealthReport
    @TableName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.partition_number AS PartitionNum,
        prv.value AS BoundaryValue,
        p.rows AS RowCnt,
        au.total_pages * 8 / 1024.0 AS SizeMB,
        p.data_compression_desc AS Compression,
        ips.avg_fragmentation_in_percent AS FragmentationPct,
        CASE 
            WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD RECOMMENDED'
            WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE RECOMMENDED'
            ELSE 'OK'
        END AS MaintenanceAction,
        CASE 
            WHEN p.rows > 1000000 THEN 'LARGE'
            WHEN p.rows > 100000 THEN 'MEDIUM'
            ELSE 'SMALL'
        END AS PartitionSize
    FROM sys.partitions p
    JOIN sys.allocation_units au ON au.container_id = p.partition_id
    LEFT JOIN sys.partition_range_values prv 
        ON prv.function_id = (SELECT TOP 1 function_id FROM sys.partition_functions)
        AND prv.boundary_id = p.partition_number
    LEFT JOIN sys.dm_db_index_physical_stats(
        DB_ID(), 
        OBJECT_ID(@TableName), 
        NULL, 
        NULL, 
        'LIMITED'
    ) ips ON ips.partition_number = p.partition_number AND ips.index_id = p.index_id
    WHERE p.object_id = OBJECT_ID(@TableName)
        AND p.index_id IN (0, 1)
    ORDER BY p.partition_number;
END;
GO

-- Run health report
EXEC usp_PartitionHealthReport @TableName = 'SalesHistory';
GO

-- =============================================
-- Example 15: Partition Access Patterns
-- =============================================

-- Track which partitions are accessed most
SELECT 
    ius.partition_number AS PartitionNum,
    ius.user_seeks AS Seeks,
    ius.user_scans AS Scans,
    ius.user_lookups AS Lookups,
    ius.user_updates AS Updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM sys.dm_db_index_usage_stats ius
WHERE ius.database_id = DB_ID()
    AND ius.object_id = OBJECT_ID('SalesHistory')
ORDER BY ius.partition_number;
GO

-- Use this to identify hot vs cold partitions

-- =============================================
-- Cleanup (commented out)
-- =============================================

/*
DROP PROCEDURE IF EXISTS usp_PartitionMaintenance;
DROP PROCEDURE IF EXISTS usp_PartitionHealthReport;
DROP STATISTICS SalesHistory.ST_SalesHistory_P3;
DROP TABLE IF EXISTS SalesHistory_Backup;
GO
*/

-- 💡 Key Takeaways:
--
-- INDEX MAINTENANCE:
-- - REBUILD: Recreates index, removes fragmentation, updates statistics
-- - REORGANIZE: Defragments index in-place, online operation
-- - Rebuild partition: ALTER INDEX idx REBUILD PARTITION = n
-- - Rebuild all: ALTER INDEX idx REBUILD PARTITION = ALL
-- - Threshold: Reorganize > 10%, Rebuild > 30%
--
-- STATISTICS:
-- - Update statistics per partition with filtered statistics
-- - CREATE STATISTICS with WHERE clause for partition range
-- - Auto-update statistics works per partition
-- - Manual update: UPDATE STATISTICS table WITH FULLSCAN
--
-- PARTITION ELIMINATION:
-- - SQL Server scans only relevant partitions
-- - Requires filter on partition key (SaleDate >= X AND SaleDate < Y)
-- - Check execution plan: "Actual Partition Count"
-- - Avoid functions on partition column: YEAR(SaleDate) prevents elimination
-- - Use BETWEEN or >= AND < for best elimination
--
-- FRAGMENTATION MONITORING:
-- - sys.dm_db_index_physical_stats: Check fragmentation per partition
-- - partition_number column shows which partition
-- - avg_fragmentation_in_percent: > 30% rebuild, > 10% reorganize
-- - Monitor regularly and maintain fragmented partitions
--
-- COMPRESSION:
-- - Compress older partitions (PAGE compression)
-- - Keep recent partitions uncompressed for performance
-- - ALTER INDEX REBUILD PARTITION = n WITH (DATA_COMPRESSION = PAGE)
-- - Check compression: sys.partitions.data_compression_desc
-- - Saves 50-80% space for old data
--
-- LOCK ESCALATION:
-- - SET (LOCK_ESCALATION = AUTO): Partition-level escalation
-- - Reduces contention on large partitioned tables
-- - Locks escalate to partition, not entire table
-- - Better concurrency for multi-partition operations
--
-- MAINTENANCE AUTOMATION:
-- - Create procedures for regular maintenance
-- - Monitor fragmentation and rebuild/reorganize as needed
-- - Schedule with SQL Agent (weekly, monthly)
-- - Log operations for auditing
-- - Health reports for monitoring
--
-- PERFORMANCE MONITORING:
-- - sys.dm_db_index_usage_stats: Track partition access patterns
-- - Identify hot vs cold partitions
-- - Hot partitions: More seeks/scans, keep on fast storage
-- - Cold partitions: Less accessed, move to slow storage or compress
--
-- BEST PRACTICES:
-- - Rebuild fragmented partitions individually (faster than whole table)
-- - Use partition elimination in queries (filter on partition key)
-- - Compress older partitions to save space
-- - Monitor partition sizes and fragmentation regularly
-- - Set lock escalation to AUTO for better concurrency
-- - Update statistics after rebuild
-- - Test queries with execution plans (verify elimination)
-- - Automate maintenance with stored procedures
-- - Document partition maintenance schedule
--
-- COMMON ISSUES:
-- - No partition elimination: Function on partition column, wrong filter
-- - High fragmentation: Rebuild partition instead of entire table
-- - Lock contention: Use AUTO lock escalation
-- - Large partitions: Consider splitting or archiving
-- - Slow queries: Check for partition elimination in execution plan
