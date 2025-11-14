# CDC Pipeline - Execution Guide

## 🚀 Quick Start

This guide provides step-by-step instructions for executing the CDC Pipeline project.

---

## 📋 Prerequisites

### Required Software
- **SQL Server 2016** or later (Enterprise, Standard, or Developer Edition)
- **SQL Server Management Studio (SSMS)** 18.0+
- **Permissions**: CREATE DATABASE, ALTER DATABASE, CREATE TABLE, CREATE TRIGGER

### Recommended Resources
- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Disk**: 2+ GB free space

---

## 📁 Execution Order

### Phase 1: SQL Server Change Tracking (Core CDC)

#### Step 1: Foundation Setup (15-20 minutes)

```sql
-- File: 01-cdc-setup.sql
-- Creates: TechStore_Source, TechStore_Target databases
-- Creates: CDC infrastructure (watermark, execution log)
```

**What to expect:**
- 2 databases created
- 6 tables (3 source, 3 target)
- CDC metadata tables
- Sample data inserted
- Monitoring views created

**Verification:**

```sql
-- Check databases exist
SELECT name FROM sys.databases WHERE name LIKE 'TechStore%';

-- Check tables created
USE TechStore_Target;
SELECT name FROM sys.tables ORDER BY name;

-- Verify sample data
SELECT COUNT(*) FROM Orders;  -- Should be 5
```

#### Step 2: Enable Change Tracking (10 minutes)

```sql
-- File: 02-enable-change-tracking.sql
-- Enables: SQL Server Change Tracking feature
```

**What to expect:**
- Change Tracking enabled at database level
- Change Tracking enabled on Orders, Customers, Products
- Initial watermark version captured
- Test changes recorded

**Verification:**

```sql
USE TechStore_Source;

-- Verify Change Tracking enabled
SELECT is_auto_cleanup_on, retention_period 
FROM sys.change_tracking_databases 
WHERE database_id = DB_ID();

-- Check tables being tracked
SELECT 
    OBJECT_NAME(t.object_id) AS TableName,
    ct.is_track_columns_updated_on
FROM sys.tables t
JOIN sys.change_tracking_tables ct ON t.object_id = ct.object_id;
```

#### Step 3: Incremental Load Pipeline (15 minutes)

```sql
-- File: 04-incremental-load.sql
-- Creates: sp_CDC_IncrementalLoad_Orders/Customers/Products
-- Creates: sp_CDC_RunAll (master orchestration)
```

**What to expect:**
- 3 incremental load stored procedures
- 1 master orchestration procedure
- Initial load executed
- Test changes processed

**Verification:**

```sql
USE TechStore_Target;

-- Check procedures created
SELECT name FROM sys.procedures WHERE name LIKE 'sp_CDC%';

-- Verify data loaded
SELECT COUNT(*) AS Orders FROM Orders WHERE DW_IsDeleted = 0;
SELECT COUNT(*) AS Customers FROM Customers WHERE DW_IsDeleted = 0;

-- Check execution log
SELECT * FROM CDC_ExecutionLog ORDER BY StartTime DESC;

-- View CDC lag
SELECT * FROM vw_CDC_Lag;
```

#### Step 4: Cleanup and Maintenance (10 minutes)

```sql
-- File: 05-change-tracking-cleanup.sql
-- Creates: sp_CDC_FullRefresh, sp_CDC_Maintenance
-- Configures: Retention policies
```

**What to expect:**
- Retention period set to 5 days
- Full refresh procedure created
- Maintenance checks executed

**Verification:**

```sql
-- Run maintenance check
EXEC sp_CDC_Maintenance;

-- Verify no data loss risk
SELECT * FROM CDC_Watermark;
```

---

### Phase 2: Temporal Tables (Complete History)

#### Step 5: Create Temporal Tables (10 minutes)

```sql
-- File: 06-create-temporal-tables.sql
-- Creates: TechStore_Temporal database
-- Creates: System-versioned tables with history
```

**What to expect:**
- New database: TechStore_Temporal
- 3 temporal tables (Products, PriceChanges, Inventory)
- 3 history tables (automatic)
- Sample data with changes

**Verification:**

```sql
USE TechStore_Temporal;

-- Verify temporal tables
SELECT 
    t.name AS TableName,
    t.temporal_type_desc,
    OBJECT_NAME(t.history_table_id) AS HistoryTable
FROM sys.tables t
WHERE t.temporal_type = 2;

-- Check history exists
SELECT COUNT(*) FROM ProductsHistory;
```

#### Step 6: Time Travel Queries (15 minutes)

```sql
-- File: 07-temporal-queries.sql
-- Demonstrates: AS OF, BETWEEN, ALL queries
-- Demonstrates: Deleted row recovery
```

**What to expect:**
- Point-in-time queries
- Change detection
- Data recovery examples

**Verification:**

```sql
-- Query all product versions
SELECT * FROM Products FOR SYSTEM_TIME ALL 
WHERE ProductID = 1
ORDER BY ValidFrom;

-- Check deleted product recovery
SELECT * FROM Products WHERE ProductID = 3;  -- Should exist
```

#### Step 7: History Analysis (10 minutes)

```sql
-- File: 08-history-analysis.sql
-- Analyzes: Change frequency, price volatility, trends
```

**What to expect:**
- Change frequency analysis
- Price volatility metrics
- Flip-flop detection
- User activity reports

**Verification:**

```sql
-- View price volatility
SELECT * FROM (
    SELECT 
        ProductID,
        ProductName,
        MIN(Price) AS MinPrice,
        MAX(Price) AS MaxPrice
    FROM Products FOR SYSTEM_TIME ALL
    GROUP BY ProductID, ProductName
) x;
```

#### Step 8: Data Restoration (15 minutes)

```sql
-- File: 09-restore-historical-data.sql
-- Demonstrates: 5 restoration scenarios
-- Creates: sp_RestoreProductToPointInTime
```

**What to expect:**
- Deleted row recovery
- Bad update rollback
- Point-in-time restoration
- Selective column restore

**Verification:**

```sql
-- Test restore procedure
DECLARE @restore_time DATETIME2 = DATEADD(SECOND, -5, SYSDATETIME());
EXEC sp_RestoreProductToPointInTime @product_id = 1, @restore_datetime = @restore_time;
```

---

### Phase 3: Trigger-Based CDC (Custom Implementation)

#### Step 9: Create CDC Infrastructure (10 minutes)

```sql
-- File: 10-create-cdc-tables.sql
-- Creates: TechStore_CDC database
-- Creates: CDC log tables, metadata, views
```

**What to expect:**
- New database: TechStore_CDC
- CDC log tables (CDC_Products, CDC_Orders, CDC_Customers)
- Configuration and monitoring tables
- Performance indexes

**Verification:**

```sql
USE TechStore_CDC;

-- Check CDC tables created
SELECT name FROM sys.tables WHERE name LIKE 'CDC_%';

-- Verify configuration
SELECT * FROM CDC_Configuration;

-- Check views
SELECT name FROM sys.views WHERE name LIKE 'vw_CDC%';
```

#### Step 10: Create CDC Triggers (15 minutes)

```sql
-- File: 11-create-cdc-triggers.sql
-- Creates: 9 AFTER triggers (3 per table)
-- Tests: INSERT, UPDATE, DELETE operations
```

**What to expect:**
- 9 triggers created (INSERT, UPDATE, DELETE for each table)
- Test operations executed
- CDC logs populated

**Verification:**

```sql
-- Verify triggers created
SELECT 
    OBJECT_NAME(parent_id) AS TableName,
    name AS TriggerName,
    type_desc
FROM sys.triggers
WHERE parent_id IN (
    SELECT object_id FROM sys.tables 
    WHERE name IN ('Products', 'Orders', 'Customers')
)
ORDER BY parent_id, name;

-- Check CDC logs
SELECT 
    'Products' AS Table, COUNT(*) AS Changes FROM CDC_Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM CDC_Orders
UNION ALL
SELECT 'Customers', COUNT(*) FROM CDC_Customers;

-- View captured changes
SELECT * FROM vw_CDC_Products_Unprocessed;
```

---

### Phase 4: Production Orchestration

#### Step 11: Orchestration & Scheduling (10 minutes)

```sql
-- File: 14-cdc-orchestration.sql
-- Creates: sp_CDC_MasterOrchestration, retry logic
-- Creates: sp_CDC_Dashboard
```

**What to expect:**
- Master orchestration procedure
- Retry failed jobs logic
- Dashboard for monitoring
- SQL Agent job template (commented)

**Verification:**

```sql
USE TechStore_Target;

-- Run orchestration manually
EXEC sp_CDC_MasterOrchestration @run_retry = 1, @send_alerts = 1;

-- View dashboard
EXEC sp_CDC_Dashboard;
```

#### Step 12: Monitoring & Alerts (10 minutes)

```sql
-- File: 16-monitoring-alerts.sql
-- Creates: Alert system, health checks
-- Creates: sp_CDC_HealthCheck
```

**What to expect:**
- Alert history table
- Configurable thresholds
- Lag monitoring
- Health score (0-100)

**Verification:**

```sql
-- Run health check
EXEC sp_CDC_HealthCheck;

-- View alert thresholds
SELECT * FROM CDC_AlertThresholds;

-- Check recent alerts
SELECT * FROM CDC_AlertHistory ORDER BY AlertTime DESC;
```

---

## 🧪 Testing the Complete Pipeline

### End-to-End Test

```sql
-- 1. Make changes in source
USE TechStore_Source;

INSERT INTO Orders (CustomerID, TotalAmount, OrderStatus)
VALUES (1, 599.99, 'Pending');

UPDATE Customers SET LoyaltyTier = 'Platinum' WHERE CustomerID = 2;

UPDATE Products SET Price = Price * 1.05 WHERE ProductID IN (1, 2, 3);

-- 2. Run CDC
USE TechStore_Target;
EXEC sp_CDC_RunAll;

-- 3. Verify sync
SELECT * FROM Orders ORDER BY OrderID DESC;
SELECT * FROM vw_CDC_Lag;
SELECT * FROM vw_CDC_ExecutionHistory;

-- 4. Check health
EXEC sp_CDC_HealthCheck;
```

### Expected Results

✅ Changes should appear in target within seconds
✅ CDC lag should be < 1 minute
✅ Execution log shows "Success" status
✅ Health score should be 90-100

---

## 🎯 Common Execution Patterns

### Pattern 1: Initial Setup (First Time)

```sql
-- Execute in this order:
01-cdc-setup.sql              -- Foundation
02-enable-change-tracking.sql -- Change Tracking
04-incremental-load.sql       -- Processing
05-change-tracking-cleanup.sql-- Maintenance

-- Then temporal tables:
06-create-temporal-tables.sql
07-temporal-queries.sql
08-history-analysis.sql
09-restore-historical-data.sql

-- Then trigger CDC:
10-create-cdc-tables.sql
11-create-cdc-triggers.sql

-- Finally orchestration:
14-cdc-orchestration.sql
16-monitoring-alerts.sql
```

### Pattern 2: Demo/Presentation

```sql
-- Show Change Tracking (fastest):
01-cdc-setup.sql
02-enable-change-tracking.sql
04-incremental-load.sql

-- Make changes and sync:
EXEC sp_CDC_RunAll;
SELECT * FROM vw_CDC_Lag;

-- Show temporal time travel:
USE TechStore_Temporal;
SELECT * FROM Products FOR SYSTEM_TIME ALL WHERE ProductID = 1;

-- Show trigger-based:
USE TechStore_CDC;
SELECT * FROM vw_CDC_SignificantPriceChanges;
```

### Pattern 3: Learning Path

**Day 1**: Change Tracking basics

- Files 01-02
- Understand CHANGETABLE()
- Practice watermark pattern

**Day 2**: Incremental loads

- Files 04-05
- MERGE statements
- Error handling

**Day 3**: Temporal tables

- Files 06-09
- Time travel queries
- Data recovery

**Day 4**: Trigger CDC

- Files 10-11
- Custom business logic
- Performance testing

**Day 5**: Production

- Files 14, 16
- Orchestration
- Monitoring

---

## ⚠️ Troubleshooting

### Issue 1: "Change tracking not enabled"

**Error**: `CHANGETABLE` function returns empty

**Solution**:

```sql
-- Verify Change Tracking enabled
USE TechStore_Source;
SELECT * FROM sys.change_tracking_databases;

-- If not enabled, run 02-enable-change-tracking.sql again
```

### Issue 2: "CDC lag too high"

**Error**: vw_CDC_Lag shows > 60 minutes

**Solution**:

```sql
-- Check for failed runs
SELECT * FROM CDC_ExecutionLog WHERE Status = 'Failed';

-- Run full refresh if behind min valid version
EXEC sp_CDC_FullRefresh @table_name = 'Orders';

-- Verify watermark updated
SELECT * FROM CDC_Watermark;
```

### Issue 3: "Triggers not firing"

**Error**: CDC log tables empty after DML

**Solution**:

```sql
-- Check triggers exist
SELECT name, is_disabled FROM sys.triggers;

-- Verify CDC enabled in configuration
SELECT * FROM CDC_Configuration WHERE IsEnabled = 1;

-- Enable if disabled
UPDATE CDC_Configuration SET IsEnabled = 1 WHERE TableName = 'Products';
```

### Issue 4: "Temporal table error on restore"

**Error**: Cannot modify temporal table

**Solution**:

```sql
-- Must disable versioning first
ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);

-- Make changes
UPDATE Products SET Price = 99.99 WHERE ProductID = 1;

-- Re-enable versioning
ALTER TABLE Products SET (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
);
```

---

## 📊 Performance Tips

### For Large Tables (1M+ rows)

1. **Partition history tables**

```sql
-- Partition ProductsHistory by ValidFrom date
CREATE PARTITION FUNCTION pf_HistoryDate (DATETIME2)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01');
```

2. **Use page compression**

```sql
ALTER TABLE ProductsHistory REBUILD WITH (DATA_COMPRESSION = PAGE);
```

3. **Batch processing**

```sql
-- Process in batches of 10,000
WHILE EXISTS (SELECT 1 FROM CDC_Products WHERE IsProcessed = 0)
BEGIN
    -- Process top 10000
    UPDATE TOP (10000) CDC_Products SET IsProcessed = 1 ...;
END
```

---

## 🎓 Learning Checkpoints

After each phase, you should be able to:

**Phase 1**:

- [ ] Explain watermark pattern
- [ ] Use CHANGETABLE() function
- [ ] Implement MERGE for upserts
- [ ] Handle CDC failures

**Phase 2**:

- [ ] Create temporal tables
- [ ] Write AS OF queries
- [ ] Restore deleted data
- [ ] Analyze change patterns

**Phase 3**:

- [ ] Write AFTER triggers
- [ ] Capture old/new values
- [ ] Implement custom CDC logic

**Phase 4**:

- [ ] Schedule CDC jobs
- [ ] Monitor CDC health
- [ ] Set up alerting
- [ ] Troubleshoot issues

---

## 🚀 Next Steps

1. **Customize for your data**
   - Add your tables
   - Adjust retention periods
   - Tune performance

2. **Integrate with tools**
   - Power BI real-time datasets
   - Azure Data Factory
   - Apache Kafka

3. **Expand to production**
   - Add more CDC patterns
   - Implement cross-database CDC
   - Set up disaster recovery

---

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section
2. Review the PROJECT-SUMMARY.md
3. Verify prerequisites
4. Check SQL Server error log

---

**Total Execution Time**: 2-3 hours  
**Difficulty**: Intermediate  
**Prerequisites**: SQL Server 2016+, Basic T-SQL knowledge
