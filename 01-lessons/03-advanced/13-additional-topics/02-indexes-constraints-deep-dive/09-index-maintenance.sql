/*
================================================================================
LESSON 13.9: INDEX MAINTENANCE
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand index fragmentation and its impact
2. Monitor fragmentation using DMVs
3. Rebuild indexes to eliminate fragmentation
4. Reorganize indexes for minor fragmentation
5. Update statistics for query optimization
6. Implement index maintenance strategies
7. Monitor index usage and identify unused indexes

Business Context:
-----------------
Over time, as data is inserted, updated, and deleted, indexes become
fragmented. Fragmented indexes slow down queries, waste storage space,
and reduce performance. Regular maintenance keeps databases running
efficiently, improving user experience and reducing infrastructure costs.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: UNDERSTANDING INDEX FRAGMENTATION
================================================================================

INDEX FRAGMENTATION occurs when the logical order of index pages doesn't
match the physical order on disk, or when pages have excessive empty space.

TYPES OF FRAGMENTATION:
-----------------------
1. EXTERNAL (Logical) Fragmentation
   - Pages out of order on disk
   - Causes extra I/O operations
   - Measured by avg_fragmentation_in_percent

2. INTERNAL Fragmentation
   - Wasted space within pages
   - Pages not full
   - Measured by avg_page_space_used_in_percent

Visual Representation:
----------------------

HEALTHY INDEX (No Fragmentation):
Logical Order:  [Page 1] -> [Page 2] -> [Page 3] -> [Page 4]
Physical Disk:  [Page 1]    [Page 2]    [Page 3]    [Page 4]
                100% full   100% full   100% full   100% full

FRAGMENTED INDEX:
Logical Order:  [Page 1] -> [Page 2] -> [Page 3] -> [Page 4]
Physical Disk:  [Page 1]    [Page 4]    [Page 2]    [Page 3]
                60% full    40% full    70% full    50% full
                ↑           ↑           ↑           ↑
            External      Internal    External    Internal
          Fragmentation  Fragmentation

CAUSES OF FRAGMENTATION:
------------------------
1. INSERT operations with random key values
2. UPDATE operations changing variable-length columns
3. DELETE operations leaving gaps
4. Page splits when inserting into full pages

IMPACT OF FRAGMENTATION:
------------------------
- Slower query performance (more I/O)
- Wasted storage space
- Inefficient memory usage (buffer pool)
- Longer backup/restore times

*/

-- Create sample table to demonstrate fragmentation
DROP TABLE IF EXISTS SalesTransaction;
GO

CREATE TABLE SalesTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    TransactionGUID UNIQUEIDENTIFIER DEFAULT NEWID(),  -- Random values cause fragmentation
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    TotalAmount AS (Quantity * UnitPrice),
    TransactionDate DATETIME DEFAULT GETDATE(),
    Notes NVARCHAR(500)
);
GO

-- Create additional indexes
CREATE INDEX IX_SalesTransaction_CustomerID ON SalesTransaction(CustomerID);
CREATE INDEX IX_SalesTransaction_ProductID ON SalesTransaction(ProductID);
CREATE INDEX IX_SalesTransaction_TransactionDate ON SalesTransaction(TransactionDate);
CREATE UNIQUE INDEX IX_SalesTransaction_GUID ON SalesTransaction(TransactionGUID);
GO

-- Insert initial data
INSERT INTO SalesTransaction (CustomerID, ProductID, Quantity, UnitPrice, Notes)
SELECT 
    ABS(CHECKSUM(NEWID())) % 1000 + 1 AS CustomerID,
    ABS(CHECKSUM(NEWID())) % 100 + 1 AS ProductID,
    ABS(CHECKSUM(NEWID())) % 10 + 1 AS Quantity,
    CAST(ABS(CHECKSUM(NEWID())) % 100 + 10 AS DECIMAL(10,2)) AS UnitPrice,
    'Transaction ' + CAST(number AS VARCHAR(10)) AS Notes
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;
GO

/*
================================================================================
PART 2: MONITORING INDEX FRAGMENTATION
================================================================================
*/

-- View fragmentation for all indexes in current database
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.index_id,
    ips.avg_fragmentation_in_percent AS [Fragmentation %],
    ips.page_count AS [Page Count],
    ips.avg_page_space_used_in_percent AS [Page Fullness %],
    ips.record_count AS [Record Count],
    ips.fragment_count AS [Fragment Count]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i 
    ON ips.object_id = i.object_id 
    AND ips.index_id = i.index_id
WHERE OBJECT_NAME(ips.object_id) = 'SalesTransaction'
    AND ips.index_id > 0  -- Exclude heap
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

/*
OUTPUT EXPLANATION:
-------------------
Fragmentation %          Action
-----------------------------------
< 10%                    No action needed
10% - 30%                Reorganize index
> 30%                    Rebuild index

Page Fullness %          Indication
-----------------------------------
< 70%                    High internal fragmentation
70% - 85%                Moderate
> 85%                    Good utilization
*/

-- Check fragmentation for specific table
SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'No Action Needed'
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 'Reorganize'
        ELSE 'Rebuild'
    END AS RecommendedAction,
    ips.avg_page_space_used_in_percent AS PageFullness
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID('SalesTransaction'), 
    NULL, 
    NULL, 
    'LIMITED'  -- Faster scan mode
) ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0;
GO

/*
SCAN MODES:
-----------
'LIMITED'   - Fast, basic stats (use for frequent checks)
'SAMPLED'   - Sample pages (balance speed and accuracy)
'DETAILED'  - Full scan (slow but accurate)
*/

/*
================================================================================
PART 3: REORGANIZING INDEXES
================================================================================

REORGANIZE is an ONLINE operation that:
- Defragments leaf level of index
- Compacts pages
- Minimal blocking
- Always online
- Use for 10-30% fragmentation

*/

-- Reorganize a single index
ALTER INDEX IX_SalesTransaction_CustomerID 
ON SalesTransaction 
REORGANIZE;
GO

PRINT 'Index reorganized successfully';
GO

-- Reorganize all indexes on a table
ALTER INDEX ALL 
ON SalesTransaction 
REORGANIZE;
GO

-- Check fragmentation after reorganize
SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.avg_page_space_used_in_percent AS PageFullness
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('SalesTransaction'), NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

/*
REORGANIZE CHARACTERISTICS:
---------------------------
✓ Online operation
✓ Minimal blocking
✓ Can be paused/resumed
✓ Uses minimal log space
✓ Good for moderate fragmentation
✗ Doesn't fully defragment
✗ Slower than rebuild
*/

/*
================================================================================
PART 4: REBUILDING INDEXES
================================================================================

REBUILD completely recreates the index:
- Removes all fragmentation
- Compacts pages to specified fill factor
- Can be online or offline (depends on edition)
- Use for >30% fragmentation

*/

-- Rebuild single index (offline)
ALTER INDEX IX_SalesTransaction_ProductID 
ON SalesTransaction 
REBUILD;
GO

PRINT 'Index rebuilt successfully';
GO

-- Rebuild with options
ALTER INDEX IX_SalesTransaction_TransactionDate 
ON SalesTransaction 
REBUILD 
WITH (
    FILLFACTOR = 80,           -- Leave 20% free space for inserts
    PAD_INDEX = ON,            -- Apply fill factor to intermediate pages
    SORT_IN_TEMPDB = ON,       -- Sort operations in tempdb (faster)
    STATISTICS_NORECOMPUTE = OFF,  -- Auto-update statistics
    ONLINE = OFF               -- Offline rebuild (Enterprise: can be ON)
);
GO

-- Rebuild all indexes on table
ALTER INDEX ALL 
ON SalesTransaction 
REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON);
GO

-- Check fragmentation after rebuild
SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.avg_page_space_used_in_percent AS PageFullness,
    ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('SalesTransaction'), NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0
ORDER BY i.name;
GO

/*
OUTPUT:
IndexName                          FragmentationPercent  PageFullness  PageCount
---------------------------------  --------------------  ------------  ---------
IX_SalesTransaction_CustomerID     0.00                  90.00         120
IX_SalesTransaction_GUID           0.00                  90.00         95
IX_SalesTransaction_ProductID      0.00                  90.00         85
IX_SalesTransaction_TransactionDate 0.00                 80.00         110
PK__SalesTra__7C66D8F512345678     0.00                 90.00         105

All indexes now 0% fragmented!
*/

/*
REBUILD OPTIONS:
----------------
FILLFACTOR         - Percentage of page fullness (default 100)
PAD_INDEX          - Apply fill factor to intermediate pages
SORT_IN_TEMPDB     - Use tempdb for sort (faster, needs space)
ONLINE             - Keep table accessible (Enterprise only)
MAXDOP             - Max degree of parallelism
DATA_COMPRESSION   - Enable compression (PAGE, ROW, NONE)
*/

/*
================================================================================
PART 5: UPDATING STATISTICS
================================================================================

Statistics help the query optimizer choose efficient execution plans.
Update statistics regularly, especially after significant data changes.

*/

-- Update statistics for single index
UPDATE STATISTICS SalesTransaction IX_SalesTransaction_CustomerID;
GO

-- Update statistics for all indexes on table
UPDATE STATISTICS SalesTransaction;
GO

-- Update with full scan (most accurate but slower)
UPDATE STATISTICS SalesTransaction WITH FULLSCAN;
GO

-- Update with sample (faster)
UPDATE STATISTICS SalesTransaction WITH SAMPLE 50 PERCENT;
GO

-- View statistics information
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatisticName,
    sp.last_updated AS LastUpdated,
    sp.rows AS [Rows],
    sp.rows_sampled AS RowsSampled,
    sp.modification_counter AS RowsModified,
    sp.steps AS HistogramSteps
FROM sys.stats s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) sp
WHERE OBJECT_NAME(s.object_id) = 'SalesTransaction'
ORDER BY s.name;
GO

/*
OUTPUT:
TableName          StatisticName                       LastUpdated          Rows   RowsSampled  RowsModified  HistogramSteps
-----------------  ----------------------------------  -------------------  -----  -----------  ------------  --------------
SalesTransaction   IX_SalesTransaction_CustomerID      2024-01-15 12:00:00  10000  10000        0             200
SalesTransaction   IX_SalesTransaction_GUID            2024-01-15 12:00:00  10000  10000        0             200
SalesTransaction   IX_SalesTransaction_ProductID       2024-01-15 12:00:00  10000  10000        0             200
SalesTransaction   PK__SalesTra...                     2024-01-15 12:00:00  10000  10000        0             200
*/

-- Show statistics details with histogram
DBCC SHOW_STATISTICS('SalesTransaction', 'IX_SalesTransaction_CustomerID');
GO

/*
================================================================================
PART 6: INDEX USAGE STATISTICS
================================================================================
*/

-- View index usage statistics
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks AS [User Seeks],
    s.user_scans AS [User Scans],
    s.user_lookups AS [User Lookups],
    s.user_updates AS [User Updates],
    s.last_user_seek AS [Last Seek],
    s.last_user_scan AS [Last Scan]
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i 
    ON s.object_id = i.object_id 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECT_NAME(s.object_id) = 'SalesTransaction'
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;
GO

/*
METRICS EXPLANATION:
--------------------
User Seeks    - Singleton lookups (WHERE col = value)
User Scans    - Range scans or full index scans
User Lookups  - Bookmark lookups (RID/Key lookups)
User Updates  - Modifications (INSERT, UPDATE, DELETE)

High updates but low seeks/scans = candidate for removal
*/

-- Find unused indexes (candidates for removal)
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ISNULL(s.user_seeks, 0) AS [User Seeks],
    ISNULL(s.user_scans, 0) AS [User Scans],
    ISNULL(s.user_lookups, 0) AS [User Lookups],
    ISNULL(s.user_updates, 0) AS [User Updates],
    CASE 
        WHEN s.index_id IS NULL THEN 'Never Used'
        WHEN s.user_seeks + s.user_scans + s.user_lookups = 0 THEN 'Write Only'
        ELSE 'In Use'
    END AS UsageStatus
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON i.object_id = s.object_id 
    AND i.index_id = s.index_id
    AND s.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.type_desc != 'HEAP'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
ORDER BY UsageStatus, TableName, IndexName;
GO

/*
================================================================================
PART 7: INDEX MAINTENANCE SCRIPT
================================================================================

Comprehensive maintenance script for production use.
*/

-- Dynamic index maintenance based on fragmentation
DECLARE @TableName NVARCHAR(128) = 'SalesTransaction';
DECLARE @IndexName NVARCHAR(128);
DECLARE @Fragmentation FLOAT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE index_cursor CURSOR FOR
SELECT 
    i.name,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@TableName), NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0
    AND ips.page_count > 100  -- Only maintain indexes with >100 pages
ORDER BY ips.avg_fragmentation_in_percent DESC;

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-------------------------------------';
    PRINT 'Index: ' + @IndexName;
    PRINT 'Fragmentation: ' + CAST(@Fragmentation AS VARCHAR(10)) + '%';
    
    IF @Fragmentation < 10
    BEGIN
        PRINT 'Action: No maintenance needed';
    END
    ELSE IF @Fragmentation BETWEEN 10 AND 30
    BEGIN
        PRINT 'Action: Reorganizing...';
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REORGANIZE;';
        EXEC sp_executesql @SQL;
        
        -- Update statistics after reorganize
        SET @SQL = 'UPDATE STATISTICS [' + @TableName + '] [' + @IndexName + '];';
        EXEC sp_executesql @SQL;
        
        PRINT 'Completed: Index reorganized and statistics updated';
    END
    ELSE
    BEGIN
        PRINT 'Action: Rebuilding...';
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD WITH (FILLFACTOR = 90, SORT_IN_TEMPDB = ON);';
        EXEC sp_executesql @SQL;
        
        PRINT 'Completed: Index rebuilt';
    END
    
    FETCH NEXT FROM index_cursor INTO @IndexName, @Fragmentation;
END

CLOSE index_cursor;
DEALLOCATE index_cursor;

PRINT '-------------------------------------';
PRINT 'Index maintenance completed!';
GO

/*
================================================================================
PART 8: MONITORING WITH DMVs
================================================================================
*/

-- Find missing indexes (indexes SQL Server suggests)
SELECT 
    OBJECT_NAME(d.object_id) AS TableName,
    d.equality_columns AS EqualityColumns,
    d.inequality_columns AS InequalityColumns,
    d.included_columns AS IncludedColumns,
    s.avg_user_impact AS AvgUserImpact,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.avg_user_impact * (s.user_seeks + s.user_scans) AS EstimatedImpact
FROM sys.dm_db_missing_index_details d
INNER JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s ON g.index_group_handle = s.group_handle
WHERE d.database_id = DB_ID()
ORDER BY EstimatedImpact DESC;
GO

-- Index operational stats (I/O statistics)
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.leaf_insert_count AS LeafInserts,
    s.leaf_update_count AS LeafUpdates,
    s.leaf_delete_count AS LeafDeletes,
    s.range_scan_count AS RangeScans,
    s.singleton_lookup_count AS SingletonLookups,
    s.page_latch_wait_count AS PageLatchWaits,
    s.page_io_latch_wait_count AS PageIOLatchWaits
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) = 'SalesTransaction'
ORDER BY s.range_scan_count + s.singleton_lookup_count DESC;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Monitor and Fix Fragmentation
------------------------------------------
1. Create a table with 50,000 rows
2. Check fragmentation
3. If fragmented >10%, fix it appropriately
4. Verify fragmentation reduced

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Index Maintenance Strategy
---------------------------------------
Create a script that:
1. Lists all indexes with >30% fragmentation
2. Rebuilds those indexes
3. Updates their statistics
4. Reports completion

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Usage Analysis
--------------------------
Write a query to find:
1. Indexes never used
2. Indexes with high updates but low reads
3. Recommend which to drop

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Monitor and Fix Fragmentation
DROP TABLE IF EXISTS TestFragmentation;
GO

CREATE TABLE TestFragmentation (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    RandomGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
    Value INT,
    Description NVARCHAR(100)
);
GO

CREATE INDEX IX_TestFragmentation_RandomGUID ON TestFragmentation(RandomGUID);
GO

-- Insert 50,000 rows
INSERT INTO TestFragmentation (Value, Description)
SELECT 
    ABS(CHECKSUM(NEWID())) % 1000,
    'Test Row ' + CAST(number AS VARCHAR(10))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 2048;
GO 25  -- Repeat to get ~50,000 rows

-- Check fragmentation
SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount,
    CASE 
        WHEN ips.avg_fragmentation_in_percent < 10 THEN 'No Action'
        WHEN ips.avg_fragmentation_in_percent BETWEEN 10 AND 30 THEN 'Reorganize'
        ELSE 'Rebuild'
    END AS Action
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('TestFragmentation'), NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0;
GO

-- Fix based on fragmentation level
ALTER INDEX ALL ON TestFragmentation REBUILD WITH (FILLFACTOR = 90);
GO

-- Verify improvement
SELECT 
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('TestFragmentation'), NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0;
GO

-- Solution 2: Index Maintenance Strategy
DECLARE @SQL NVARCHAR(MAX);

-- Find and fix fragmented indexes
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS Fragmentation,
    'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(ips.object_id) + '] REBUILD WITH (FILLFACTOR = 90);' AS RebuildCommand,
    'UPDATE STATISTICS [' + OBJECT_NAME(ips.object_id) + '] [' + i.name + '];' AS UpdateStatsCommand
INTO #FragmentedIndexes
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30
    AND ips.page_count > 100
    AND ips.index_id > 0;

-- Execute rebuilds
DECLARE rebuild_cursor CURSOR FOR
SELECT RebuildCommand, UpdateStatsCommand, TableName, IndexName FROM #FragmentedIndexes;

DECLARE @RebuildCmd NVARCHAR(MAX), @StatsCmd NVARCHAR(MAX), @Table NVARCHAR(128), @Index NVARCHAR(128);

OPEN rebuild_cursor;
FETCH NEXT FROM rebuild_cursor INTO @RebuildCmd, @StatsCmd, @Table, @Index;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Rebuilding: ' + @Table + '.' + @Index;
    EXEC sp_executesql @RebuildCmd;
    EXEC sp_executesql @StatsCmd;
    PRINT 'Completed!';
    
    FETCH NEXT FROM rebuild_cursor INTO @RebuildCmd, @StatsCmd, @Table, @Index;
END

CLOSE rebuild_cursor;
DEALLOCATE rebuild_cursor;

DROP TABLE #FragmentedIndexes;
PRINT 'All fragmented indexes rebuilt and statistics updated!';
GO

-- Solution 3: Usage Analysis
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ISNULL(s.user_seeks, 0) AS Seeks,
    ISNULL(s.user_scans, 0) AS Scans,
    ISNULL(s.user_lookups, 0) AS Lookups,
    ISNULL(s.user_updates, 0) AS Updates,
    ISNULL(s.user_seeks + s.user_scans + s.user_lookups, 0) AS TotalReads,
    CASE 
        WHEN s.index_id IS NULL THEN 'NEVER USED - CONSIDER DROPPING'
        WHEN s.user_seeks + s.user_scans + s.user_lookups = 0 AND s.user_updates > 0 
            THEN 'WRITE ONLY - CONSIDER DROPPING'
        WHEN s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups) * 10 
            THEN 'HIGH WRITE/LOW READ - REVIEW'
        ELSE 'IN USE - KEEP'
    END AS Recommendation
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON i.object_id = s.object_id 
    AND i.index_id = s.index_id
    AND s.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.type_desc != 'HEAP'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
ORDER BY 
    CASE Recommendation
        WHEN 'NEVER USED - CONSIDER DROPPING' THEN 1
        WHEN 'WRITE ONLY - CONSIDER DROPPING' THEN 2
        WHEN 'HIGH WRITE/LOW READ - REVIEW' THEN 3
        ELSE 4
    END,
    TotalReads;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. INDEX FRAGMENTATION
   - External: Pages out of order
   - Internal: Wasted space within pages
   - Causes: Random inserts, updates, deletes
   - Impact: Slower queries, wasted space

2. MONITORING
   - sys.dm_db_index_physical_stats - fragmentation levels
   - <10%: No action
   - 10-30%: Reorganize
   - >30%: Rebuild

3. REORGANIZE
   - Online operation
   - Minimal blocking
   - For moderate fragmentation (10-30%)
   - Less resource-intensive

4. REBUILD
   - Complete recreation
   - Removes all fragmentation
   - For heavy fragmentation (>30%)
   - More thorough but resource-intensive

5. STATISTICS
   - Help query optimizer
   - Update after data changes
   - Use FULLSCAN for accuracy
   - Auto-updated by default

6. INDEX USAGE
   - Monitor with sys.dm_db_index_usage_stats
   - Remove unused indexes
   - Balance reads vs writes
   - Review regularly

7. BEST PRACTICES
   - Schedule regular maintenance
   - Monitor fragmentation weekly
   - Rebuild during low-usage periods
   - Update statistics frequently
   - Remove unused indexes
   - Use SORT_IN_TEMPDB for large rebuilds
   - Set appropriate FILLFACTOR

8. AUTOMATION
   - Create maintenance scripts
   - Use SQL Agent jobs
   - Log maintenance activities
   - Alert on high fragmentation

================================================================================

NEXT STEPS:
-----------
In Lesson 13.10, we'll explore ADVANCED INDEX TYPES:
- Filtered indexes
- Columnstore indexes
- Full-text indexes
- Spatial indexes
- XML indexes

Continue to: 10-advanced-index-types.sql

================================================================================
*/
