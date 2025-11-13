-- ========================================
-- Sliding Window Pattern
-- Archive Old Data with Partition Switching
-- ========================================

USE TechStore;
GO

-- =============================================
-- Setup: Create Partition Function and Scheme
-- =============================================

-- Monthly partitions for 2024-2025
CREATE PARTITION FUNCTION pfSlidingWindow (DATE)
AS RANGE RIGHT FOR VALUES (
    '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01',
    '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01',
    '2024-09-01', '2024-10-01', '2024-11-01', '2024-12-01'
);
GO

-- Creates 13 partitions:
-- Partition 1: < 2024-01-01 (old data)
-- Partitions 2-13: Each month of 2024
-- Partition 14: >= 2025-01-01 (future data)

CREATE PARTITION SCHEME psSlidingWindow
AS PARTITION pfSlidingWindow
ALL TO ([PRIMARY]);
GO

-- =============================================
-- Example 1: Create Partitioned Table
-- =============================================

CREATE TABLE SalesHistory (
    SaleID INT NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Quantity INT NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_SalesHistory PRIMARY KEY (SaleID, SaleDate)
) ON psSlidingWindow(SaleDate);
GO

-- =============================================
-- Example 2: Insert Sample Data
-- =============================================

-- Insert data across multiple partitions
INSERT INTO SalesHistory (SaleID, CustomerID, ProductID, SaleDate, Quantity, TotalAmount)
VALUES 
    -- Old data (partition 1)
    (1, 101, 1, '2023-11-15', 2, 1000.00),
    (2, 102, 2, '2023-12-20', 1, 500.00),
    -- 2024 data (partitions 2-13)
    (3, 103, 3, '2024-01-10', 3, 1500.00),
    (4, 104, 4, '2024-02-15', 1, 750.00),
    (5, 105, 5, '2024-03-20', 2, 1200.00),
    (6, 106, 1, '2024-04-25', 1, 600.00),
    (7, 107, 2, '2024-05-30', 4, 2000.00),
    (8, 108, 3, '2024-06-05', 2, 900.00),
    (9, 109, 4, '2024-07-10', 3, 1350.00),
    (10, 110, 5, '2024-08-15', 1, 450.00),
    (11, 111, 1, '2024-09-20', 2, 800.00),
    (12, 112, 2, '2024-10-25', 1, 550.00),
    (13, 113, 3, '2024-11-30', 3, 1650.00),
    (14, 114, 4, '2024-12-05', 2, 950.00);
GO

-- =============================================
-- Example 3: View Current Partitions
-- =============================================

SELECT 
    $PARTITION.pfSlidingWindow(SaleDate) AS PartitionNum,
    MIN(SaleDate) AS MinDate,
    MAX(SaleDate) AS MaxDate,
    COUNT(*) AS RowCnt
FROM SalesHistory
GROUP BY $PARTITION.pfSlidingWindow(SaleDate)
ORDER BY PartitionNum;
GO

-- =============================================
-- Example 4: Create Archive Table
-- =============================================

-- Archive table must have IDENTICAL structure
CREATE TABLE SalesArchive (
    SaleID INT NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Quantity INT NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_SalesArchive PRIMARY KEY (SaleID, SaleDate)
) ON [PRIMARY];
GO

-- ⚠️ IMPORTANT: Archive table must have same constraints and indexes!

-- =============================================
-- Example 5: SWITCH Partition to Archive
-- =============================================

-- SWITCH partition 1 (old data) to archive table
-- This is a METADATA OPERATION - instant, no data movement!

-- Requirements for SWITCH:
-- 1. Same structure (columns, data types, nullability)
-- 2. Same constraints (check constraints, triggers must be disabled)
-- 3. Archive table on same filegroup as partition
-- 4. All indexes must be aligned

-- Check partition before switch
SELECT COUNT(*) AS BeforeSwitch FROM SalesHistory WHERE SaleDate < '2024-01-01';
SELECT COUNT(*) AS ArchiveBefore FROM SalesArchive;
GO

-- Perform the SWITCH
ALTER TABLE SalesHistory 
SWITCH PARTITION 1 TO SalesArchive;
GO

-- Verify switch
SELECT COUNT(*) AS AfterSwitch FROM SalesHistory WHERE SaleDate < '2024-01-01';
SELECT COUNT(*) AS ArchiveAfter FROM SalesArchive;
GO

-- Old data is now in archive table!

-- =============================================
-- Example 6: View Partitions After SWITCH
-- =============================================

SELECT 
    $PARTITION.pfSlidingWindow(SaleDate) AS PartitionNum,
    MIN(SaleDate) AS MinDate,
    MAX(SaleDate) AS MaxDate,
    COUNT(*) AS RowCnt
FROM SalesHistory
GROUP BY $PARTITION.pfSlidingWindow(SaleDate)
ORDER BY PartitionNum;
GO

-- Partition 1 is now empty

-- =============================================
-- Example 7: SPLIT - Add New Partition
-- =============================================

-- Add new partition for January 2025
ALTER PARTITION FUNCTION pfSlidingWindow()
SPLIT RANGE ('2025-01-01');
GO

-- Now we have 14 partitions:
-- Partition 1: < 2024-01-01 (empty after switch)
-- Partitions 2-13: 2024 months
-- Partition 14: 2025-01-01 to < next boundary
-- Partition 15: >= next boundary

-- Verify new boundary
SELECT 
    prv.boundary_id,
    prv.value AS BoundaryValue
FROM sys.partition_range_values prv
JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
WHERE pf.name = 'pfSlidingWindow'
ORDER BY prv.boundary_id;
GO

-- =============================================
-- Example 8: MERGE - Remove Empty Partition
-- =============================================

-- Merge partition 1 (now empty) back into partition 2
ALTER PARTITION FUNCTION pfSlidingWindow()
MERGE RANGE ('2024-01-01');
GO

-- Now we have 13 partitions instead of 14
-- The empty partition is removed

-- Verify boundary removed
SELECT 
    prv.boundary_id,
    prv.value AS BoundaryValue
FROM sys.partition_range_values prv
JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
WHERE pf.name = 'pfSlidingWindow'
ORDER BY prv.boundary_id;
GO

-- =============================================
-- Example 9: Complete Sliding Window Cycle
-- =============================================

-- Simulating monthly maintenance:
-- 1. SPLIT: Add new month (February 2025)
-- 2. SWITCH: Archive oldest data
-- 3. MERGE: Remove old boundary

-- Step 1: SPLIT for new month
ALTER PARTITION FUNCTION pfSlidingWindow()
SPLIT RANGE ('2025-02-01');
GO

-- Step 2: SWITCH oldest partition to archive
-- (In this case, partition 1 which now contains February 2024 data)
-- First, recreate archive table to match structure
TRUNCATE TABLE SalesArchive;
GO

-- If partition has data, switch it
-- ALTER TABLE SalesHistory SWITCH PARTITION 1 TO SalesArchive;
-- (Skipping since we already switched partition 1)

-- Step 3: MERGE old boundary
-- ALTER PARTITION FUNCTION pfSlidingWindow() MERGE RANGE ('2024-02-01');
-- (Commented to preserve example)

-- =============================================
-- Example 10: Automated Sliding Window Script
-- =============================================

-- Procedure to automate sliding window maintenance
CREATE PROCEDURE usp_SlidingWindowMaintenance
    @NewBoundary DATE,
    @OldBoundary DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Add new partition boundary
        DECLARE @SplitSQL NVARCHAR(500);
        SET @SplitSQL = N'ALTER PARTITION FUNCTION pfSlidingWindow() SPLIT RANGE (''' 
            + CONVERT(VARCHAR(10), @NewBoundary, 120) + ''')';
        EXEC sp_executesql @SplitSQL;
        PRINT 'SPLIT: Added boundary ' + CONVERT(VARCHAR(10), @NewBoundary, 120);
        
        -- Step 2: Switch out old partition
        -- First, get partition number for old boundary
        DECLARE @PartitionNum INT;
        SET @PartitionNum = $PARTITION.pfSlidingWindow(@OldBoundary);
        
        -- Verify partition has data
        DECLARE @RowCnt INT;
        DECLARE @CountSQL NVARCHAR(500);
        SET @CountSQL = N'SELECT @Cnt = COUNT(*) FROM SalesHistory WHERE $PARTITION.pfSlidingWindow(SaleDate) = @PNum';
        EXEC sp_executesql @CountSQL, N'@Cnt INT OUTPUT, @PNum INT', @Cnt = @RowCnt OUTPUT, @PNum = @PartitionNum;
        
        IF @RowCnt > 0
        BEGIN
            -- Clear archive table
            TRUNCATE TABLE SalesArchive;
            
            -- Switch partition
            DECLARE @SwitchSQL NVARCHAR(500);
            SET @SwitchSQL = N'ALTER TABLE SalesHistory SWITCH PARTITION ' 
                + CAST(@PartitionNum AS VARCHAR(10)) + ' TO SalesArchive';
            EXEC sp_executesql @SwitchSQL;
            PRINT 'SWITCH: Moved partition ' + CAST(@PartitionNum AS VARCHAR(10)) + ' (' + CAST(@RowCnt AS VARCHAR(10)) + ' rows) to archive';
            
            -- Step 3: Merge old boundary
            DECLARE @MergeSQL NVARCHAR(500);
            SET @MergeSQL = N'ALTER PARTITION FUNCTION pfSlidingWindow() MERGE RANGE (''' 
                + CONVERT(VARCHAR(10), @OldBoundary, 120) + ''')';
            EXEC sp_executesql @MergeSQL;
            PRINT 'MERGE: Removed boundary ' + CONVERT(VARCHAR(10), @OldBoundary, 120);
        END
        ELSE
        BEGIN
            PRINT 'SKIP: Partition ' + CAST(@PartitionNum AS VARCHAR(10)) + ' is empty';
        END
        
        COMMIT TRANSACTION;
        PRINT 'Sliding window maintenance completed successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- =============================================
-- Example 11: Execute Sliding Window Maintenance
-- =============================================

-- Add March 2025, archive data before March 2024
-- EXEC usp_SlidingWindowMaintenance 
--     @NewBoundary = '2025-03-01',
--     @OldBoundary = '2024-03-01';
-- GO

-- (Commented to preserve example structure)

-- =============================================
-- Example 12: Schedule Monthly Maintenance
-- =============================================

-- Example SQL Agent job to run monthly
-- (Pseudo-code - actual implementation would use SQL Agent)

/*
-- Job runs on 1st of each month
DECLARE @NewMonth DATE = DATEADD(MONTH, 2, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));
DECLARE @OldMonth DATE = DATEADD(MONTH, -12, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));

EXEC usp_SlidingWindowMaintenance 
    @NewBoundary = @NewMonth,
    @OldBoundary = @OldMonth;
*/

-- =============================================
-- Example 13: SWITCH with Check Constraints
-- =============================================

-- Archive table needs matching check constraints
ALTER TABLE SalesArchive
ADD CONSTRAINT CK_SalesArchive_Date CHECK (SaleDate < '2024-01-01');
GO

-- Main table needs constraint for partition to switch
ALTER TABLE SalesHistory
ADD CONSTRAINT CK_SalesHistory_Date CHECK (SaleDate >= '2024-01-01' OR SaleDate < '2024-01-01');
GO

-- This constraint is tautology but enables SWITCH

-- =============================================
-- Example 14: Monitor Partition Sizes
-- =============================================

-- Check partition sizes to plan archival
SELECT 
    p.partition_number AS PartitionNum,
    prv.value AS BoundaryValue,
    p.rows AS RowCnt,
    au.total_pages * 8 / 1024.0 AS SizeMB,
    CASE 
        WHEN p.rows > 100000 THEN 'Consider archiving'
        WHEN p.rows > 50000 THEN 'Monitor'
        ELSE 'OK'
    END AS Status
FROM sys.partitions p
JOIN sys.allocation_units au ON au.container_id = p.partition_id
LEFT JOIN sys.partition_range_values prv 
    ON prv.function_id = (SELECT function_id FROM sys.partition_functions WHERE name = 'pfSlidingWindow')
    AND prv.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('SalesHistory')
    AND p.index_id IN (0, 1)
ORDER BY p.partition_number;
GO

-- =============================================
-- Example 15: SWITCH with Indexes
-- =============================================

-- Create aligned index on partitioned table
CREATE NONCLUSTERED INDEX IX_SalesHistory_Customer
ON SalesHistory(CustomerID, SaleDate)
ON psSlidingWindow(SaleDate);
GO

-- Archive table must have IDENTICAL index
CREATE NONCLUSTERED INDEX IX_SalesArchive_Customer
ON SalesArchive(CustomerID, SaleDate)
ON [PRIMARY];
GO

-- Now SWITCH will work with indexes

-- =============================================
-- Example 16: Performance - SWITCH vs DELETE
-- =============================================

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Method 1: SWITCH (metadata operation - instant!)
-- ALTER TABLE SalesHistory SWITCH PARTITION 1 TO SalesArchive;

-- Method 2: DELETE (slow, fully logged)
-- DELETE FROM SalesHistory WHERE SaleDate < '2024-01-01';

-- SWITCH is 1000x faster for large tables!

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- =============================================
-- Cleanup (commented out)
-- =============================================

/*
DROP PROCEDURE IF EXISTS usp_SlidingWindowMaintenance;
DROP INDEX IF EXISTS IX_SalesHistory_Customer ON SalesHistory;
DROP INDEX IF EXISTS IX_SalesArchive_Customer ON SalesArchive;
DROP TABLE IF EXISTS SalesHistory;
DROP TABLE IF EXISTS SalesArchive;
DROP PARTITION SCHEME psSlidingWindow;
DROP PARTITION FUNCTION pfSlidingWindow;
DROP PARTITION FUNCTION pfRangeLeft;
DROP PARTITION FUNCTION pfRangeRight;
GO
*/

-- 💡 Key Takeaways:
--
-- SLIDING WINDOW PATTERN:
-- - Most common partitioning maintenance pattern
-- - SPLIT: Add new partition for incoming data
-- - SWITCH: Move old partition to archive (metadata operation)
-- - MERGE: Remove empty partition boundary
-- - Keeps fixed number of partitions (e.g., rolling 12 months)
--
-- SPLIT RANGE:
-- - Adds new boundary to partition function
-- - Creates new partition
-- - Syntax: ALTER PARTITION FUNCTION pfName() SPLIT RANGE (value)
-- - Use before new data arrives
--
-- SWITCH PARTITION:
-- - Metadata-only operation (instant, minimal logging)
-- - Moves entire partition to another table
-- - Requirements: identical structure, same filegroup, aligned indexes
-- - Syntax: ALTER TABLE table SWITCH PARTITION n TO archive_table
-- - 1000x faster than DELETE for large partitions
--
-- MERGE RANGE:
-- - Removes boundary from partition function
-- - Combines two adjacent partitions
-- - Syntax: ALTER PARTITION FUNCTION pfName() MERGE RANGE (value)
-- - Partition must be empty before MERGE
--
-- SWITCH REQUIREMENTS:
-- - Archive table must have IDENTICAL structure
-- - Same columns, data types, nullability, collation
-- - Same constraints (PRIMARY KEY, CHECK, FOREIGN KEY)
-- - Same indexes (aligned indexes must match)
-- - Both tables on same filegroup (or partition on same filegroup)
-- - Check constraints must allow switch (use tautology constraint)
-- - Triggers must be disabled during switch
--
-- AUTOMATION:
-- - Create stored procedure for maintenance
-- - Use dynamic SQL for SPLIT/SWITCH/MERGE
-- - Schedule with SQL Agent (monthly, weekly, daily)
-- - Monitor partition sizes and row counts
-- - Log operations for auditing
-- - Handle errors gracefully
--
-- PERFORMANCE BENEFITS:
-- - SWITCH is metadata operation (instant)
-- - DELETE is slow, fully logged, blocks table
-- - SWITCH allows near-zero downtime archival
-- - Maintains historical data in archive tables
-- - Archive tables can be on cheaper storage
--
-- BEST PRACTICES:
-- - Test SWITCH operations in dev environment first
-- - Verify archive table structure matches exactly
-- - Use check constraints to enable SWITCH
-- - Monitor partition sizes regularly
-- - Automate with stored procedures and jobs
-- - Keep fixed number of partitions (rolling window)
-- - Document partition strategy and schedule
-- - Archive to compressed tables for space savings
-- - Consider partitioned archive tables for large history
--
-- COMMON PATTERNS:
-- - Rolling 12 months: Keep last 12 months in main table
-- - Daily logs: Keep last 30 days, archive older
-- - Yearly archival: One partition per year
-- - Hot/Warm/Cold: Recent data on fast storage, archive on slow
--
-- TROUBLESHOOTING:
-- - "Partition cannot be switched": Check structure, indexes, constraints
-- - "Filegroup mismatch": Ensure same filegroup for partition and archive
-- - "CHECK constraint violation": Add matching constraint to archive table
-- - "Non-empty partition": SWITCH before MERGE, or move data first
