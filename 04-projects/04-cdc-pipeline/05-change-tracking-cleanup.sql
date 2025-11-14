-- ============================================================================
-- Change Tracking Cleanup and Maintenance
-- ============================================================================
-- Manage retention, cleanup old changes, optimize storage
-- ============================================================================

USE TechStore_Source;
GO

PRINT '=================================================================';
PRINT 'CHANGE TRACKING CLEANUP AND MAINTENANCE';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
CHANGE TRACKING RETENTION MANAGEMENT
============================================================================

STORAGE IMPACT:
- Change Tracking stores ~10 bytes per changed row
- Example: 100,000 changes/day × 3 days = 300,000 rows
- Storage: 300,000 × 10 bytes = 3 MB (minimal!)

RETENTION POLICY:
- Too short: Risk data loss if CDC job fails for hours
- Too long: Wastes storage on old changes
- Sweet spot: 2-3 days (enough time to recover from failures)

AUTO CLEANUP:
- SQL Server automatically purges old changes
- Based on CHANGE_RETENTION setting
- Runs in background, no manual intervention needed

MANUAL CLEANUP:
- Use sp_flush_commit_table (emergency only!)
- Forces immediate cleanup
- Can cause data loss if CDC is behind

MIN VALID VERSION:
- Oldest change version still available
- If last_sync < min_valid → DATA LOSS!
- Must do full table refresh

============================================================================
*/

-- ============================================================================
-- CHECK CURRENT RETENTION SETTINGS
-- ============================================================================

PRINT 'Current Change Tracking Configuration:';
PRINT '';

SELECT 
    DB_NAME() AS DatabaseName,
    is_auto_cleanup_on AS AutoCleanup,
    retention_period AS RetentionDays,
    retention_period_units_desc AS RetentionUnit,
    CASE 
        WHEN is_auto_cleanup_on = 1 THEN 'Automatic cleanup enabled'
        ELSE 'WARNING: Manual cleanup required!'
    END AS CleanupStatus
FROM sys.change_tracking_databases
WHERE database_id = DB_ID();

PRINT '';

-- ============================================================================
-- CHECK TABLE-LEVEL TRACKING STATUS
-- ============================================================================

PRINT 'Change Tracking Status by Table:';
PRINT '';

SELECT 
    OBJECT_NAME(t.object_id) AS TableName,
    ct.is_track_columns_updated_on AS TrackColumnChanges,
    CHANGE_TRACKING_MIN_VALID_VERSION(t.object_id) AS MinValidVersion,
    CHANGE_TRACKING_CURRENT_VERSION() AS CurrentVersion,
    CHANGE_TRACKING_CURRENT_VERSION() - CHANGE_TRACKING_MIN_VALID_VERSION(t.object_id) 
        AS VersionRange,
    CASE 
        WHEN CHANGE_TRACKING_MIN_VALID_VERSION(t.object_id) IS NOT NULL 
        THEN 'Tracking Enabled'
        ELSE 'Not Tracked'
    END AS Status
FROM sys.tables t
LEFT JOIN sys.change_tracking_tables ct ON t.object_id = ct.object_id
WHERE t.name IN ('Orders', 'Customers', 'Products')
ORDER BY t.name;

PRINT '';

-- ============================================================================
-- CHECK FOR POTENTIAL DATA LOSS
-- ============================================================================

PRINT 'Checking for CDC Data Loss Risk:';
PRINT '';

USE TechStore_Target;

-- Check if any watermarks are behind the minimum valid version
SELECT 
    w.TableName,
    w.LastSyncVersion,
    CHANGE_TRACKING_MIN_VALID_VERSION(OBJECT_ID('TechStore_Source.dbo.' + w.TableName)) 
        AS MinValidVersion,
    CHANGE_TRACKING_CURRENT_VERSION() AS CurrentVersion,
    DATEDIFF(MINUTE, w.LastSyncTime, GETDATE()) AS MinutesSinceLastSync,
    w.LastRunStatus,
    CASE 
        WHEN w.LastSyncVersion < CHANGE_TRACKING_MIN_VALID_VERSION(
            OBJECT_ID('TechStore_Source.dbo.' + w.TableName)
        ) 
        THEN '❌ DATA LOSS! Need full refresh!'
        WHEN DATEDIFF(HOUR, w.LastSyncTime, GETDATE()) > 48
        THEN '⚠️  WARNING: Last sync > 48 hours ago'
        WHEN DATEDIFF(HOUR, w.LastSyncTime, GETDATE()) > 24
        THEN '⚠️  CAUTION: Last sync > 24 hours ago'
        ELSE '✓ OK'
    END AS HealthStatus
FROM CDC_Watermark w;

PRINT '';

-- ============================================================================
-- ADJUST RETENTION PERIOD (IF NEEDED)
-- ============================================================================

PRINT 'Adjusting Retention Period:';
PRINT '';

USE TechStore_Source;

-- Example: Increase retention to 5 days
ALTER DATABASE TechStore_Source
SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 5 DAYS, AUTO_CLEANUP = ON);

PRINT '✓ Updated retention to 5 days';
PRINT '';

-- Verify new setting
SELECT 
    'Updated Retention' AS Setting,
    retention_period AS Days,
    is_auto_cleanup_on AS AutoCleanup
FROM sys.change_tracking_databases
WHERE database_id = DB_ID();

PRINT '';

-- ============================================================================
-- MANUAL CLEANUP (USE WITH CAUTION!)
-- ============================================================================

PRINT 'Manual Cleanup Options:';
PRINT '';

/*
EMERGENCY CLEANUP (RARELY NEEDED):

-- Force immediate cleanup of all expired changes
EXEC sys.sp_flush_commit_table @table_name = 'Orders';

⚠️  WARNING: This can cause data loss!
   Only use if:
   - Change tracking storage is consuming excessive space
   - You've verified all CDC jobs are caught up
   - You understand the risk

SAFER APPROACH:
- Reduce retention period temporarily
- Let auto cleanup handle it
- Then restore original retention
*/

PRINT '-- To force cleanup (CAUTION!):';
PRINT '-- EXEC sys.sp_flush_commit_table @table_name = ''Orders'';';
PRINT '';
PRINT '❌ Manual cleanup disabled (too risky!)';
PRINT '✓ Recommend using automatic cleanup instead';
PRINT '';

-- ============================================================================
-- STORAGE ANALYSIS
-- ============================================================================

PRINT 'Change Tracking Storage Analysis:';
PRINT '';

-- Estimate storage used by change tracking
SELECT 
    t.name AS TableName,
    p.rows AS ChangeCount,
    (p.reserved_page_count * 8) / 1024.0 AS StorageMB,
    CASE 
        WHEN (p.reserved_page_count * 8) / 1024.0 < 10 THEN '✓ Low'
        WHEN (p.reserved_page_count * 8) / 1024.0 < 100 THEN 'Moderate'
        ELSE '⚠️  High - Consider cleanup'
    END AS StorageLevel
FROM sys.internal_tables it
JOIN sys.tables t ON it.parent_object_id = t.object_id
JOIN sys.dm_db_partition_stats p ON it.object_id = p.object_id
WHERE it.internal_type_desc = 'CHANGE_TRACKING_INTERNAL_TABLE'
ORDER BY StorageMB DESC;

PRINT '';

-- ============================================================================
-- FULL REFRESH PROCEDURE (RECOVERY FROM DATA LOSS)
-- ============================================================================

USE TechStore_Target;
GO

CREATE OR ALTER PROCEDURE sp_CDC_FullRefresh
    @table_name VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=================================================================';
    PRINT 'FULL REFRESH FOR: ' + @table_name;
    PRINT '=================================================================';
    
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @current_version BIGINT;
    
    BEGIN TRY
        -- Get current version
        SET @current_version = CHANGE_TRACKING_CURRENT_VERSION();
        
        PRINT 'Starting full refresh at version: ' + CAST(@current_version AS VARCHAR(20));
        
        -- Truncate target table
        SET @sql = 'TRUNCATE TABLE ' + @table_name;
        EXEC sp_executesql @sql;
        PRINT '  ✓ Truncated target table';
        
        -- Full load from source
        IF @table_name = 'Orders'
        BEGIN
            INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, 
                OrderStatus, ShippingAddress, ModifiedDate, ModifiedBy, DW_LoadedDate)
            SELECT OrderID, CustomerID, OrderDate, TotalAmount, 
                OrderStatus, ShippingAddress, ModifiedDate, ModifiedBy, GETDATE()
            FROM TechStore_Source.dbo.Orders;
            
            PRINT '  ✓ Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' orders';
        END
        ELSE IF @table_name = 'Customers'
        BEGIN
            INSERT INTO Customers (CustomerID, FirstName, LastName, Email, Phone,
                LoyaltyTier, CreatedDate, ModifiedDate, ModifiedBy, DW_LoadedDate)
            SELECT CustomerID, FirstName, LastName, Email, Phone,
                LoyaltyTier, CreatedDate, ModifiedDate, ModifiedBy, GETDATE()
            FROM TechStore_Source.dbo.Customers;
            
            PRINT '  ✓ Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' customers';
        END
        ELSE IF @table_name = 'Products'
        BEGIN
            INSERT INTO Products (ProductID, ProductName, Category, Price,
                StockQuantity, ModifiedDate, ModifiedBy, DW_LoadedDate)
            SELECT ProductID, ProductName, Category, Price,
                StockQuantity, ModifiedDate, ModifiedBy, GETDATE()
            FROM TechStore_Source.dbo.Products;
            
            PRINT '  ✓ Loaded ' + CAST(@@ROWCOUNT AS VARCHAR(20)) + ' products';
        END
        
        -- Reset watermark to current version
        UPDATE CDC_Watermark
        SET LastSyncVersion = @current_version,
            LastSyncTime = GETDATE(),
            LastRunStatus = 'Full Refresh'
        WHERE TableName = @table_name;
        
        PRINT '  ✓ Updated watermark to version: ' + CAST(@current_version AS VARCHAR(20));
        PRINT '';
        PRINT '✓ Full refresh completed successfully!';
        
    END TRY
    BEGIN CATCH
        PRINT 'ERROR during full refresh: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created sp_CDC_FullRefresh procedure';
PRINT '';

-- ============================================================================
-- MAINTENANCE STORED PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_Maintenance
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=================================================================';
    PRINT 'CDC MAINTENANCE CHECK';
    PRINT '=================================================================';
    PRINT '';
    
    -- Check for tables needing full refresh
    DECLARE @needs_refresh TABLE (TableName VARCHAR(100));
    
    INSERT INTO @needs_refresh (TableName)
    SELECT w.TableName
    FROM CDC_Watermark w
    WHERE w.LastSyncVersion < CHANGE_TRACKING_MIN_VALID_VERSION(
        OBJECT_ID('TechStore_Source.dbo.' + w.TableName)
    );
    
    IF EXISTS (SELECT 1 FROM @needs_refresh)
    BEGIN
        PRINT '❌ CRITICAL: The following tables need full refresh:';
        SELECT TableName FROM @needs_refresh;
        PRINT '';
        PRINT 'Run: EXEC sp_CDC_FullRefresh @table_name = ''TableName''';
    END
    ELSE
    BEGIN
        PRINT '✓ All tables are within valid change tracking range';
    END
    
    PRINT '';
    
    -- Check CDC lag
    PRINT 'Current CDC Lag Status:';
    SELECT * FROM vw_CDC_Lag;
    
    PRINT '';
    
    -- Check for failed runs
    IF EXISTS (SELECT 1 FROM CDC_ExecutionLog 
               WHERE Status = 'Failed' 
               AND EndTime > DATEADD(HOUR, -24, GETDATE()))
    BEGIN
        PRINT '⚠️  WARNING: Failed CDC runs in last 24 hours:';
        SELECT TableName, StartTime, ErrorMessage
        FROM CDC_ExecutionLog
        WHERE Status = 'Failed'
        AND EndTime > DATEADD(HOUR, -24, GETDATE())
        ORDER BY StartTime DESC;
    END
    ELSE
    BEGIN
        PRINT '✓ No failed CDC runs in last 24 hours';
    END
    
    PRINT '';
    PRINT 'Maintenance check complete.';
END;
GO

PRINT '✓ Created sp_CDC_Maintenance procedure';
PRINT '';

-- ============================================================================
-- TEST MAINTENANCE PROCEDURES
-- ============================================================================

PRINT '=================================================================';
PRINT 'RUNNING MAINTENANCE CHECK';
PRINT '=================================================================';
PRINT '';

EXEC sp_CDC_Maintenance;

PRINT '';
PRINT '=================================================================';
PRINT 'CHANGE TRACKING CLEANUP COMPLETE!';
PRINT '=================================================================';

/*
============================================================================
MAINTENANCE SUMMARY
============================================================================

✅ AUTOMATIC CLEANUP:
   - Enabled with AUTO_CLEANUP = ON
   - Runs in background
   - Retention: 5 days (adjustable)
   - No manual intervention needed

✅ MONITORING PROCEDURES:
   - sp_CDC_Maintenance: Check health status
   - vw_CDC_Lag: Monitor sync lag
   - CDC_ExecutionLog: Track run history

✅ RECOVERY PROCEDURES:
   - sp_CDC_FullRefresh: Recover from data loss
   - Use when last_sync < min_valid_version

BEST PRACTICES:

1. Monitor CDC Lag Daily
   EXEC sp_CDC_Maintenance;

2. Alert on Failed Runs
   SELECT * FROM CDC_ExecutionLog WHERE Status = 'Failed';

3. Adjust Retention Based on CDC Frequency
   - CDC every 5 min → 2-3 days retention sufficient
   - CDC every hour → 5-7 days retention safer

4. Full Refresh Only When Necessary
   - Automatic when data loss detected
   - Manual for schema changes

SCHEDULED MAINTENANCE:

-- Daily maintenance check (SQL Agent Job)
USE msdb;
EXEC sp_add_job @job_name = 'CDC_Daily_Maintenance';
EXEC sp_add_jobstep
    @job_name = 'CDC_Daily_Maintenance',
    @command = 'EXEC TechStore_Target.dbo.sp_CDC_Maintenance';
EXEC sp_add_schedule
    @schedule_name = 'Daily_At_2AM',
    @freq_type = 4,  -- Daily
    @active_start_time = 020000;  -- 2:00 AM

CLEANUP SCENARIOS:

❌ DON'T manually cleanup if:
   - CDC jobs are running normally
   - Storage usage is acceptable
   - No performance issues

✅ DO consider cleanup if:
   - Change tracking storage > 1 GB
   - Retention period too long for your needs
   - Database maintenance window available

Next Phase: Temporal Tables for complete history tracking!
============================================================================
*/
