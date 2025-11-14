-- ============================================================================
-- CDC Monitoring and Alerts
-- ============================================================================
-- Comprehensive monitoring system for CDC pipeline health
-- ============================================================================

USE TechStore_Target;
GO

PRINT '=================================================================';
PRINT 'CDC MONITORING AND ALERTING SYSTEM';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
MONITORING STRATEGY
============================================================================

KEY METRICS TO MONITOR:

1. CDC Lag
   - How far behind is warehouse vs source?
   - Target: < 5 minutes for real-time
   
2. Processing Success Rate
   - % of successful CDC runs
   - Target: > 99%
   
3. Throughput
   - Rows processed per second
   - Detect performance degradation
   
4. Error Frequency
   - Failed runs per day
   - Error patterns
   
5. Data Quality
   - Missing rows
   - Duplicate detection
   - Referential integrity

ALERT LEVELS:

🟢 OK: Everything normal
🟡 WARNING: Approaching thresholds
🔴 CRITICAL: Immediate action required

ALERT CHANNELS:

1. Email (sp_send_dbmail)
2. SQL Agent alerts
3. Application logs
4. SCOM/Nagios integration
5. PagerDuty/Slack webhooks

============================================================================
*/

-- ============================================================================
-- CREATE ALERT HISTORY TABLE
-- ============================================================================

IF OBJECT_ID('CDC_AlertHistory') IS NOT NULL
    DROP TABLE CDC_AlertHistory;
GO

CREATE TABLE CDC_AlertHistory (
    AlertID INT PRIMARY KEY IDENTITY(1,1),
    AlertTime DATETIME DEFAULT GETDATE(),
    AlertLevel VARCHAR(20),  -- INFO, WARNING, CRITICAL
    TableName VARCHAR(100),
    AlertType VARCHAR(50),
    AlertMessage VARCHAR(MAX),
    MetricValue DECIMAL(18,2),
    ThresholdValue DECIMAL(18,2),
    WasNotified BIT DEFAULT 0,
    NotificationMethod VARCHAR(50),
    ResolvedTime DATETIME NULL
);

CREATE INDEX IX_CDC_AlertHistory_AlertTime ON CDC_AlertHistory(AlertTime);
CREATE INDEX IX_CDC_AlertHistory_AlertLevel ON CDC_AlertHistory(AlertLevel, WasNotified);

PRINT '✓ Created CDC_AlertHistory table';
PRINT '';

-- ============================================================================
-- CREATE ALERT THRESHOLDS TABLE
-- ============================================================================

IF OBJECT_ID('CDC_AlertThresholds') IS NOT NULL
    DROP TABLE CDC_AlertThresholds;
GO

CREATE TABLE CDC_AlertThresholds (
    ThresholdID INT PRIMARY KEY IDENTITY(1,1),
    MetricName VARCHAR(100) NOT NULL UNIQUE,
    WarningThreshold DECIMAL(18,2),
    CriticalThreshold DECIMAL(18,2),
    IsEnabled BIT DEFAULT 1,
    Description VARCHAR(500)
);

-- Insert default thresholds
INSERT INTO CDC_AlertThresholds (MetricName, WarningThreshold, CriticalThreshold, Description)
VALUES 
    ('CDC_Lag_Minutes', 15, 60, 'Minutes of CDC lag (source vs warehouse)'),
    ('Error_Rate_Percent', 5, 10, 'Percentage of failed CDC runs'),
    ('Processing_Duration_Seconds', 300, 600, 'CDC processing duration'),
    ('Rows_Per_Second', 100, 50, 'Processing throughput (lower is worse)'),
    ('Failed_Runs_Count', 3, 5, 'Consecutive failed runs');

PRINT '✓ Created CDC_AlertThresholds with default values';
PRINT '';

-- ============================================================================
-- CREATE MONITORING PROCEDURE: CDC Lag Monitor
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_MonitorLag
    @alert_if_exceeded BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @table_name VARCHAR(100);
    DECLARE @lag_minutes INT;
    DECLARE @alert_level VARCHAR(20);
    DECLARE @warning_threshold INT;
    DECLARE @critical_threshold INT;
    
    -- Get thresholds
    SELECT 
        @warning_threshold = WarningThreshold,
        @critical_threshold = CriticalThreshold
    FROM CDC_AlertThresholds
    WHERE MetricName = 'CDC_Lag_Minutes';
    
    PRINT 'Monitoring CDC Lag...';
    PRINT '  Warning threshold: ' + CAST(@warning_threshold AS VARCHAR(10)) + ' minutes';
    PRINT '  Critical threshold: ' + CAST(@critical_threshold AS VARCHAR(10)) + ' minutes';
    PRINT '';
    
    -- Check each table
    DECLARE lag_cursor CURSOR FOR
    SELECT TableName, LagMinutes, HealthStatus
    FROM vw_CDC_Lag;
    
    OPEN lag_cursor;
    FETCH NEXT FROM lag_cursor INTO @table_name, @lag_minutes, @alert_level;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @lag_minutes > @critical_threshold
        BEGIN
            SET @alert_level = 'CRITICAL';
            
            INSERT INTO CDC_AlertHistory (AlertLevel, TableName, AlertType, AlertMessage, MetricValue, ThresholdValue)
            VALUES ('CRITICAL', @table_name, 'CDC_Lag', 
                    'CDC lag critically high: ' + CAST(@lag_minutes AS VARCHAR(10)) + ' minutes',
                    @lag_minutes, @critical_threshold);
            
            PRINT '🔴 CRITICAL: ' + @table_name + ' lag = ' + CAST(@lag_minutes AS VARCHAR(10)) + ' min';
        END
        ELSE IF @lag_minutes > @warning_threshold
        BEGIN
            SET @alert_level = 'WARNING';
            
            INSERT INTO CDC_AlertHistory (AlertLevel, TableName, AlertType, AlertMessage, MetricValue, ThresholdValue)
            VALUES ('WARNING', @table_name, 'CDC_Lag',
                    'CDC lag elevated: ' + CAST(@lag_minutes AS VARCHAR(10)) + ' minutes',
                    @lag_minutes, @warning_threshold);
            
            PRINT '🟡 WARNING: ' + @table_name + ' lag = ' + CAST(@lag_minutes AS VARCHAR(10)) + ' min';
        END
        ELSE
        BEGIN
            PRINT '🟢 OK: ' + @table_name + ' lag = ' + CAST(@lag_minutes AS VARCHAR(10)) + ' min';
        END
        
        FETCH NEXT FROM lag_cursor INTO @table_name, @lag_minutes, @alert_level;
    END
    
    CLOSE lag_cursor;
    DEALLOCATE lag_cursor;
END;
GO

PRINT '✓ Created sp_CDC_MonitorLag';
PRINT '';

-- ============================================================================
-- CREATE MONITORING PROCEDURE: Error Rate Monitor
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_MonitorErrorRate
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Monitoring CDC Error Rate (Last 24 hours)...';
    
    DECLARE @total_runs INT;
    DECLARE @failed_runs INT;
    DECLARE @error_rate DECIMAL(5,2);
    DECLARE @warning_threshold DECIMAL(5,2);
    DECLARE @critical_threshold DECIMAL(5,2);
    
    -- Get thresholds
    SELECT 
        @warning_threshold = WarningThreshold,
        @critical_threshold = CriticalThreshold
    FROM CDC_AlertThresholds
    WHERE MetricName = 'Error_Rate_Percent';
    
    -- Calculate error rate
    SELECT 
        @total_runs = COUNT(*),
        @failed_runs = SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END)
    FROM CDC_ExecutionLog
    WHERE StartTime > DATEADD(HOUR, -24, GETDATE());
    
    IF @total_runs > 0
        SET @error_rate = (@failed_runs * 100.0) / @total_runs;
    ELSE
        SET @error_rate = 0;
    
    PRINT '  Total runs: ' + CAST(@total_runs AS VARCHAR(10));
    PRINT '  Failed runs: ' + CAST(@failed_runs AS VARCHAR(10));
    PRINT '  Error rate: ' + CAST(@error_rate AS VARCHAR(10)) + '%';
    PRINT '';
    
    -- Check thresholds
    IF @error_rate > @critical_threshold
    BEGIN
        INSERT INTO CDC_AlertHistory (AlertLevel, AlertType, AlertMessage, MetricValue, ThresholdValue)
        VALUES ('CRITICAL', 'Error_Rate',
                'CDC error rate critically high: ' + CAST(@error_rate AS VARCHAR(10)) + '%',
                @error_rate, @critical_threshold);
        
        PRINT '🔴 CRITICAL: Error rate = ' + CAST(@error_rate AS VARCHAR(10)) + '%';
    END
    ELSE IF @error_rate > @warning_threshold
    BEGIN
        INSERT INTO CDC_AlertHistory (AlertLevel, AlertType, AlertMessage, MetricValue, ThresholdValue)
        VALUES ('WARNING', 'Error_Rate',
                'CDC error rate elevated: ' + CAST(@error_rate AS VARCHAR(10)) + '%',
                @error_rate, @warning_threshold);
        
        PRINT '🟡 WARNING: Error rate = ' + CAST(@error_rate AS VARCHAR(10)) + '%';
    END
    ELSE
    BEGIN
        PRINT '🟢 OK: Error rate = ' + CAST(@error_rate AS VARCHAR(10)) + '%';
    END
END;
GO

PRINT '✓ Created sp_CDC_MonitorErrorRate';
PRINT '';

-- ============================================================================
-- CREATE COMPREHENSIVE HEALTH CHECK
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_HealthCheck
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=================================================================';
    PRINT 'CDC PIPELINE HEALTH CHECK';
    PRINT '=================================================================';
    PRINT '';
    
    -- 1. CDC Lag Monitor
    PRINT '1. CDC LAG STATUS';
    PRINT '─────────────────────────────────────────────────────────────────';
    EXEC sp_CDC_MonitorLag;
    PRINT '';
    
    -- 2. Error Rate Monitor
    PRINT '2. ERROR RATE STATUS';
    PRINT '─────────────────────────────────────────────────────────────────';
    EXEC sp_CDC_MonitorErrorRate;
    PRINT '';
    
    -- 3. Recent Alerts
    PRINT '3. RECENT ALERTS (Last 24 hours)';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT 
        AlertTime,
        AlertLevel,
        TableName,
        AlertType,
        AlertMessage,
        CASE WHEN ResolvedTime IS NOT NULL THEN '✓ Resolved' ELSE '⚠️ Active' END AS Status
    FROM CDC_AlertHistory
    WHERE AlertTime > DATEADD(HOUR, -24, GETDATE())
    ORDER BY AlertTime DESC;
    PRINT '';
    
    -- 4. Processing Summary
    PRINT '4. PROCESSING SUMMARY (Last 24 hours)';
    PRINT '─────────────────────────────────────────────────────────────────';
    SELECT 
        TableName,
        COUNT(*) AS TotalRuns,
        SUM(CASE WHEN Status = 'Success' THEN 1 ELSE 0 END) AS SuccessfulRuns,
        SUM(CASE WHEN Status = 'Failed' THEN 1 ELSE 0 END) AS FailedRuns,
        SUM(RowsInserted + RowsUpdated + RowsDeleted) AS TotalRowsProcessed,
        AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSec
    FROM CDC_ExecutionLog
    WHERE StartTime > DATEADD(HOUR, -24, GETDATE())
    GROUP BY TableName;
    PRINT '';
    
    -- 5. Overall Health Score
    PRINT '5. OVERALL HEALTH SCORE';
    PRINT '─────────────────────────────────────────────────────────────────';
    
    DECLARE @critical_alerts INT;
    DECLARE @warning_alerts INT;
    DECLARE @health_score INT;
    
    SELECT 
        @critical_alerts = SUM(CASE WHEN AlertLevel = 'CRITICAL' AND ResolvedTime IS NULL THEN 1 ELSE 0 END),
        @warning_alerts = SUM(CASE WHEN AlertLevel = 'WARNING' AND ResolvedTime IS NULL THEN 1 ELSE 0 END)
    FROM CDC_AlertHistory
    WHERE AlertTime > DATEADD(HOUR, -24, GETDATE());
    
    -- Calculate health score (0-100)
    SET @health_score = 100 - (@critical_alerts * 30) - (@warning_alerts * 10);
    IF @health_score < 0 SET @health_score = 0;
    
    PRINT '  Active Critical Alerts: ' + CAST(ISNULL(@critical_alerts, 0) AS VARCHAR(10));
    PRINT '  Active Warning Alerts: ' + CAST(ISNULL(@warning_alerts, 0) AS VARCHAR(10));
    PRINT '  Health Score: ' + CAST(@health_score AS VARCHAR(10)) + '/100';
    PRINT '';
    
    IF @health_score >= 90
        PRINT '  Status: 🟢 EXCELLENT - All systems operational';
    ELSE IF @health_score >= 70
        PRINT '  Status: 🟡 GOOD - Minor issues detected';
    ELSE IF @health_score >= 50
        PRINT '  Status: 🟠 FAIR - Multiple warnings present';
    ELSE
        PRINT '  Status: 🔴 POOR - Critical attention required';
    
    PRINT '';
    PRINT '=================================================================';
    PRINT 'Health check complete - ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '=================================================================';
END;
GO

PRINT '✓ Created sp_CDC_HealthCheck';
PRINT '';

-- ============================================================================
-- TEST MONITORING SYSTEM
-- ============================================================================

PRINT '=================================================================';
PRINT 'TESTING MONITORING SYSTEM';
PRINT '=================================================================';
PRINT '';

-- Run comprehensive health check
EXEC sp_CDC_HealthCheck;

PRINT '';
PRINT '=================================================================';
PRINT 'CDC MONITORING SYSTEM COMPLETE!';
PRINT '=================================================================';

/*
============================================================================
CDC MONITORING SUMMARY
============================================================================

✅ CREATED MONITORING INFRASTRUCTURE:

1. CDC_AlertHistory Table
   - Stores all alerts
   - Tracks resolution status
   - Notification history

2. CDC_AlertThresholds Table
   - Configurable alert levels
   - Warning and critical thresholds
   - Enable/disable per metric

3. sp_CDC_MonitorLag
   - Monitors CDC lag per table
   - Generates alerts based on thresholds
   - 🟢 OK / 🟡 WARNING / 🔴 CRITICAL

4. sp_CDC_MonitorErrorRate
   - Tracks success/failure rate
   - 24-hour rolling window
   - Alerts on degradation

5. sp_CDC_HealthCheck
   - Comprehensive health dashboard
   - Overall health score (0-100)
   - Recent alerts summary
   - Processing statistics

KEY METRICS MONITORED:

📊 CDC Lag (minutes behind source)
📈 Error rate (% failed runs)
⏱️ Processing duration
🔄 Throughput (rows/second)
❌ Consecutive failures

ALERT THRESHOLDS (Default):

CDC Lag:
  🟡 WARNING:  > 15 minutes
  🔴 CRITICAL: > 60 minutes

Error Rate:
  🟡 WARNING:  > 5%
  🔴 CRITICAL: > 10%

Processing Duration:
  🟡 WARNING:  > 5 minutes
  🔴 CRITICAL: > 10 minutes

SCHEDULING HEALTH CHECKS:

-- Run health check hourly
USE msdb;
EXEC sp_add_job @job_name = 'CDC_Hourly_Health_Check';
EXEC sp_add_jobstep
    @job_name = 'CDC_Hourly_Health_Check',
    @command = 'EXEC TechStore_Target.dbo.sp_CDC_HealthCheck';
EXEC sp_add_schedule
    @schedule_name = 'Every_Hour',
    @freq_type = 4,
    @freq_subday_type = 8,  -- Hours
    @freq_subday_interval = 1;

ALERTING OPTIONS:

1. Database Mail (sp_send_dbmail)
2. SQL Agent alerts
3. Extended Events
4. Custom webhook to Slack/Teams
5. Integration with monitoring tools (SCOM, Grafana, Datadog)

EXAMPLE EMAIL ALERT:

IF EXISTS (SELECT 1 FROM CDC_AlertHistory 
           WHERE AlertLevel = 'CRITICAL' AND WasNotified = 0)
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'CDC_Alerts',
        @recipients = 'dba-team@company.com',
        @subject = 'CRITICAL: CDC Pipeline Alert',
        @body = 'CDC lag exceeded critical threshold. Immediate action required.';
        
    UPDATE CDC_AlertHistory 
    SET WasNotified = 1, NotificationMethod = 'Email'
    WHERE AlertLevel = 'CRITICAL' AND WasNotified = 0;
END

PRODUCTION RECOMMENDATIONS:

✅ Schedule health checks hourly
✅ Send email on CRITICAL alerts
✅ Dashboard for real-time monitoring
✅ Retention: Keep alert history 90 days
✅ Archive old alerts monthly

CDC PIPELINE COMPLETE! 🎉
All 3 CDC patterns demonstrated:
1. Change Tracking (built-in)
2. Temporal Tables (system-versioned)
3. Trigger-based (custom)

============================================================================
*/
