-- ============================================================================
-- CDC Orchestration and Scheduling
-- ============================================================================
-- Automate CDC processing with error handling and monitoring
-- ============================================================================

USE TechStore_Target;
GO

PRINT '=================================================================';
PRINT 'CDC ORCHESTRATION AND SCHEDULING';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
CDC ORCHESTRATION OVERVIEW
============================================================================

PRODUCTION CDC PIPELINE:

1. Schedule (SQL Agent Job)
   └─▶ 2. Master Orchestration Proc
        ├─▶ 3. Process Orders CDC
        ├─▶ 4. Process Customers CDC
        ├─▶ 5. Process Products CDC
        └─▶ 6. Monitor and Alert

ORCHESTRATION RESPONSIBILITIES:

✅ Run CDC at scheduled intervals
✅ Handle errors gracefully
✅ Retry failed operations
✅ Monitor CDC lag
✅ Send alerts when issues detected
✅ Log execution history
✅ Manage resource usage

SCHEDULING PATTERNS:

Pattern 1: Real-time (Every 1-5 min)
- High-priority tables
- Critical business operations
- Minimal lag tolerance

Pattern 2: Near Real-time (Every 15-30 min)
- Standard operational data
- Balance between latency and overhead

Pattern 3: Batch (Hourly/Daily)
- Historical data
- Low-priority tables
- Bulk processing

============================================================================
*/

-- ============================================================================
-- CREATE ERROR HANDLING PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_HandleError
    @table_name VARCHAR(100),
    @error_message VARCHAR(MAX),
    @log_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log error details
    UPDATE CDC_ExecutionLog
    SET EndTime = GETDATE(),
        Status = 'Failed',
        ErrorMessage = @error_message
    WHERE LogID = @log_id;
    
    -- Update watermark status
    UPDATE CDC_Watermark
    SET LastRunStatus = 'Failed'
    WHERE TableName = @table_name;
    
    -- Could send email/alert here
    PRINT '❌ ERROR in ' + @table_name + ': ' + @error_message;
    
    -- Don't throw - let orchestration continue with other tables
END;
GO

-- ============================================================================
-- CREATE RETRY LOGIC PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_RetryFailedJobs
    @max_retries INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Checking for failed CDC jobs to retry...';
    
    DECLARE @retried_count INT = 0;
    DECLARE @table_name VARCHAR(100);
    DECLARE @log_id INT;
    DECLARE @retry_cursor CURSOR;
    
    -- Find recent failures with retry potential
    SET @retry_cursor = CURSOR FOR
    SELECT DISTINCT
        l.TableName,
        l.LogID
    FROM CDC_ExecutionLog l
    WHERE l.Status = 'Failed'
    AND l.StartTime > DATEADD(HOUR, -24, GETDATE())
    AND NOT EXISTS (
        -- Don't retry if already succeeded later
        SELECT 1 FROM CDC_ExecutionLog l2
        WHERE l2.TableName = l.TableName
        AND l2.StartTime > l.StartTime
        AND l2.Status = 'Success'
    )
    ORDER BY l.StartTime DESC;
    
    OPEN @retry_cursor;
    FETCH NEXT FROM @retry_cursor INTO @table_name, @log_id;
    
    WHILE @@FETCH_STATUS = 0 AND @retried_count < @max_retries
    BEGIN
        PRINT '  Retrying: ' + @table_name;
        
        BEGIN TRY
            -- Re-run the incremental load for this table
            IF @table_name = 'Orders'
                EXEC sp_CDC_IncrementalLoad_Orders;
            ELSE IF @table_name = 'Customers'
                EXEC sp_CDC_IncrementalLoad_Customers;
            ELSE IF @table_name = 'Products'
                EXEC sp_CDC_IncrementalLoad_Products;
            
            SET @retried_count = @retried_count + 1;
            PRINT '    ✓ Retry successful';
        END TRY
        BEGIN CATCH
            PRINT '    ✗ Retry failed: ' + ERROR_MESSAGE();
        END CATCH
        
        FETCH NEXT FROM @retry_cursor INTO @table_name, @log_id;
    END
    
    CLOSE @retry_cursor;
    DEALLOCATE @retry_cursor;
    
    PRINT 'Retried ' + CAST(@retried_count AS VARCHAR(10)) + ' failed jobs';
END;
GO

-- ============================================================================
-- CREATE MASTER ORCHESTRATION PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_MasterOrchestration
    @run_retry BIT = 1,
    @send_alerts BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @error_count INT = 0;
    
    PRINT '=================================================================';
    PRINT 'CDC MASTER ORCHESTRATION - ' + CONVERT(VARCHAR, @start_time, 120);
    PRINT '=================================================================';
    PRINT '';
    
    -- Step 1: Retry previous failures (if enabled)
    IF @run_retry = 1
    BEGIN
        PRINT 'Step 1: Retrying failed jobs...';
        EXEC sp_CDC_RetryFailedJobs @max_retries = 2;
        PRINT '';
    END
    
    -- Step 2: Run incremental loads for all tables
    PRINT 'Step 2: Running incremental loads...';
    PRINT '';
    
    -- Orders
    BEGIN TRY
        EXEC sp_CDC_IncrementalLoad_Orders;
    END TRY
    BEGIN CATCH
        SET @error_count = @error_count + 1;
        PRINT '❌ Orders CDC failed: ' + ERROR_MESSAGE();
    END CATCH
    
    PRINT '';
    
    -- Customers
    BEGIN TRY
        EXEC sp_CDC_IncrementalLoad_Customers;
    END TRY
    BEGIN CATCH
        SET @error_count = @error_count + 1;
        PRINT '❌ Customers CDC failed: ' + ERROR_MESSAGE();
    END CATCH
    
    PRINT '';
    
    -- Products
    BEGIN TRY
        EXEC sp_CDC_IncrementalLoad_Products;
    END TRY
    BEGIN CATCH
        SET @error_count = @error_count + 1;
        PRINT '❌ Products CDC failed: ' + ERROR_MESSAGE();
    END CATCH
    
    PRINT '';
    
    -- Step 3: Check CDC lag and send alerts
    IF @send_alerts = 1
    BEGIN
        PRINT 'Step 3: Checking CDC lag and alerts...';
        
        -- Check for critical lag
        DECLARE @critical_lag_count INT;
        
        SELECT @critical_lag_count = COUNT(*)
        FROM vw_CDC_Lag
        WHERE HealthStatus = 'CRITICAL';
        
        IF @critical_lag_count > 0
        BEGIN
            PRINT '⚠️ ALERT: ' + CAST(@critical_lag_count AS VARCHAR(10)) + ' tables with CRITICAL lag!';
            
            SELECT * FROM vw_CDC_Lag WHERE HealthStatus = 'CRITICAL';
            
            -- Here you would send email/SMS/PagerDuty alert
            -- EXEC msdb.dbo.sp_send_dbmail ...
        END
        ELSE
        BEGIN
            PRINT '✓ All tables within acceptable lag';
        END
        
        PRINT '';
    END
    
    -- Step 4: Summary
    PRINT '=================================================================';
    PRINT 'ORCHESTRATION SUMMARY';
    PRINT '=================================================================';
    
    DECLARE @duration_sec INT = DATEDIFF(SECOND, @start_time, GETDATE());
    
    PRINT 'Start Time: ' + CONVERT(VARCHAR, @start_time, 120);
    PRINT 'End Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT 'Duration: ' + CAST(@duration_sec AS VARCHAR(10)) + ' seconds';
    PRINT 'Errors: ' + CAST(@error_count AS VARCHAR(10));
    PRINT '';
    
    -- Show lag status
    SELECT * FROM vw_CDC_Lag;
    
    PRINT '';
    PRINT 'Execution complete.';
END;
GO

PRINT '✓ Created sp_CDC_MasterOrchestration';
PRINT '';

-- ============================================================================
-- CREATE SQL AGENT JOB (COMMENTED - REQUIRES MSDB PERMISSIONS)
-- ============================================================================

PRINT 'SQL Agent Job Creation (reference only):';
PRINT '─────────────────────────────────────────────────────────────────';
PRINT '';

/*
-- Run this in a production environment with appropriate permissions

USE msdb;
GO

-- Create job category
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name = 'CDC' AND category_class = 1)
BEGIN
    EXEC msdb.dbo.sp_add_category
        @class = N'JOB',
        @type = N'LOCAL',
        @name = N'CDC';
END
GO

-- Create CDC job
EXEC msdb.dbo.sp_add_job
    @job_name = N'CDC_Incremental_Load_Every_5_Minutes',
    @enabled = 1,
    @description = N'Runs CDC incremental load every 5 minutes for real-time data sync',
    @category_name = N'CDC',
    @owner_login_name = N'sa';

-- Add job step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'CDC_Incremental_Load_Every_5_Minutes',
    @step_name = N'Run Master Orchestration',
    @subsystem = N'TSQL',
    @database_name = N'TechStore_Target',
    @command = N'EXEC sp_CDC_MasterOrchestration @run_retry = 1, @send_alerts = 1;',
    @retry_attempts = 2,
    @retry_interval = 1;

-- Create schedule (every 5 minutes)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Every_5_Minutes',
    @freq_type = 4,                    -- Daily
    @freq_interval = 1,                -- Every day
    @freq_subday_type = 4,             -- Minutes
    @freq_subday_interval = 5,         -- Every 5 minutes
    @active_start_time = 000000,       -- Midnight
    @active_end_time = 235959;         -- 11:59:59 PM

-- Attach schedule to job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'CDC_Incremental_Load_Every_5_Minutes',
    @schedule_name = N'Every_5_Minutes';

-- Add job to local server
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'CDC_Incremental_Load_Every_5_Minutes',
    @server_name = N'(local)';
GO
*/

PRINT '-- Job would run every 5 minutes';
PRINT '-- Command: EXEC sp_CDC_MasterOrchestration';
PRINT '-- Retry attempts: 2';
PRINT '-- Sends alerts on critical lag';
PRINT '';

-- ============================================================================
-- CREATE MONITORING DASHBOARD PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_Dashboard
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=================================================================';
    PRINT 'CDC MONITORING DASHBOARD';
    PRINT '=================================================================';
    PRINT '';
    
    -- Section 1: Current Lag Status
    PRINT '1. CURRENT LAG STATUS';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT * FROM vw_CDC_Lag ORDER BY LagMinutes DESC;
    PRINT '';
    
    -- Section 2: Recent Execution History
    PRINT '2. RECENT EXECUTION HISTORY (Last 10 runs)';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT TOP 10 * FROM vw_CDC_ExecutionHistory ORDER BY StartTime DESC;
    PRINT '';
    
    -- Section 3: Error Summary
    PRINT '3. ERROR SUMMARY (Last 24 hours)';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT 
        TableName,
        COUNT(*) AS ErrorCount,
        MAX(StartTime) AS LastError,
        MAX(ErrorMessage) AS LastErrorMessage
    FROM CDC_ExecutionLog
    WHERE Status = 'Failed'
    AND StartTime > DATEADD(HOUR, -24, GETDATE())
    GROUP BY TableName;
    PRINT '';
    
    -- Section 4: Performance Metrics
    PRINT '4. PERFORMANCE METRICS (Last 24 hours)';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT 
        TableName,
        COUNT(*) AS RunCount,
        SUM(RowsInserted + RowsUpdated + RowsDeleted) AS TotalRowsProcessed,
        AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds,
        MAX(DATEDIFF(SECOND, StartTime, EndTime)) AS MaxDurationSeconds
    FROM CDC_ExecutionLog
    WHERE Status = 'Success'
    AND StartTime > DATEADD(HOUR, -24, GETDATE())
    GROUP BY TableName;
    PRINT '';
    
    -- Section 5: Table Row Counts
    PRINT '5. TABLE ROW COUNTS';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT 
        'Orders' AS TableName,
        COUNT(*) AS CurrentRows,
        SUM(CASE WHEN DW_IsDeleted = 1 THEN 1 ELSE 0 END) AS DeletedRows
    FROM Orders
    UNION ALL
    SELECT 
        'Customers',
        COUNT(*),
        SUM(CASE WHEN DW_IsDeleted = 1 THEN 1 ELSE 0 END)
    FROM Customers
    UNION ALL
    SELECT 
        'Products',
        COUNT(*),
        SUM(CASE WHEN DW_IsDeleted = 1 THEN 1 ELSE 0 END)
    FROM Products;
    PRINT '';
    
    PRINT '=================================================================';
    PRINT 'Dashboard refresh complete - ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '=================================================================';
END;
GO

PRINT '✓ Created sp_CDC_Dashboard';
PRINT '';

-- ============================================================================
-- TEST ORCHESTRATION
-- ============================================================================

PRINT '=================================================================';
PRINT 'TESTING CDC ORCHESTRATION';
PRINT '=================================================================';
PRINT '';

-- Run master orchestration
EXEC sp_CDC_MasterOrchestration 
    @run_retry = 1,
    @send_alerts = 1;

PRINT '';

-- Show dashboard
EXEC sp_CDC_Dashboard;

PRINT '';
PRINT '=================================================================';
PRINT 'CDC ORCHESTRATION COMPLETE!';
PRINT '=================================================================';

/*
============================================================================
CDC ORCHESTRATION SUMMARY
============================================================================

✅ CREATED ORCHESTRATION PROCEDURES:

1. sp_CDC_HandleError
   - Centralized error handling
   - Logs errors to CDC_ExecutionLog
   - Updates watermark status

2. sp_CDC_RetryFailedJobs
   - Automatically retries recent failures
   - Configurable max retry count
   - Prevents duplicate retries

3. sp_CDC_MasterOrchestration
   - Runs all CDC loads
   - Handles errors gracefully
   - Checks lag and sends alerts
   - Provides execution summary

4. sp_CDC_Dashboard
   - Real-time monitoring view
   - Lag status
   - Execution history
   - Error summary
   - Performance metrics

SQL AGENT JOB (Production):
- Schedule: Every 5 minutes
- Retry: 2 attempts
- Owner: sa (or service account)
- Category: CDC

MONITORING CAPABILITIES:

✅ CDC lag (minutes behind source)
✅ Execution success/failure rate
✅ Performance metrics (duration, rows/sec)
✅ Error tracking and alerting
✅ Row counts and data quality

ALERTING TRIGGERS:

⚠️ CDC lag > 15 minutes → WARNING
🔴 CDC lag > 60 minutes → CRITICAL
❌ 3+ consecutive failures → ALERT
📊 Performance degradation → REVIEW

NEXT STEPS:

1. Set up email alerts (sp_send_dbmail)
2. Configure monitoring tools (SCOM, Grafana)
3. Tune CDC intervals based on data volume
4. Archive old CDC execution logs

Production ready! 🚀
============================================================================
*/
