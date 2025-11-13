# Project 5: Data Quality Monitoring & Observability

## Overview
Build a **production-grade data quality monitoring system** that automatically validates data, detects anomalies, and alerts teams when data issues occur. This is critical for maintaining trust in your data warehouse.

## What You'll Learn
- **Data quality dimensions**: Completeness, accuracy, consistency, timeliness
- **Automated validation**: SQL-based quality checks
- **Anomaly detection**: Detect unusual patterns (volume drops, distribution changes)
- **Data profiling**: Understand data characteristics
- **Alerting & monitoring**: Notify teams of quality issues
- **Quality scorecards**: Track data health over time

## Why Data Quality Monitoring?

### Without Monitoring
```
Bad data enters warehouse → Analysts use bad data → Wrong business decisions → 💸
```
❌ **Problems:**
- Discover data issues weeks later
- No automated detection
- Manual quality checks (error-prone)
- Loss of trust in data

### With Data Quality Monitoring
```
Bad data enters → Automated checks fail → Alert sent → Fix before anyone notices → ✅
```
✅ **Benefits:**
- Catch issues within minutes
- Automated, consistent checks
- Proactive alerts to data teams
- Trust in data increases

## Business Case
You're the data engineer at **TechStore**. The executive dashboard showed "$0 revenue" yesterday because:
1. ETL job failed silently
2. No one noticed for 12 hours
3. CEO made decisions on stale data

**Your mission**: Build a monitoring system that prevents this from happening again.

## Data Quality Dimensions

### 1. Completeness
Are all expected records present?
```sql
-- Check if any orders are missing
SELECT 
    'Completeness Check' AS check_name,
    COUNT(*) AS actual_count,
    (SELECT expected_daily_orders FROM metadata.expectations) AS expected_count,
    CASE 
        WHEN COUNT(*) < (SELECT expected_daily_orders FROM metadata.expectations) * 0.8 
        THEN 'FAIL' ELSE 'PASS' 
    END AS status
FROM Orders
WHERE OrderDate = CAST(GETDATE() AS DATE);
```

### 2. Accuracy
Are values correct and valid?
```sql
-- Check for invalid data
SELECT 
    'Accuracy Check' AS check_name,
    COUNT(*) AS invalid_records
FROM Orders
WHERE TotalAmount < 0               -- Negative amounts
   OR TotalAmount > 100000          -- Suspiciously high
   OR CustomerID IS NULL            -- Missing customer
   OR OrderDate > GETDATE();        -- Future orders
```

### 3. Consistency
Do values align across tables?
```sql
-- Check if all order products exist in product catalog
SELECT 
    'Consistency Check' AS check_name,
    COUNT(*) AS orphaned_orders
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1 FROM Products p WHERE p.ProductID = o.ProductID
);
```

### 4. Timeliness
Is data fresh enough?
```sql
-- Check data freshness
SELECT 
    'Freshness Check' AS check_name,
    MAX(LoadedAt) AS last_loaded,
    DATEDIFF(MINUTE, MAX(LoadedAt), GETDATE()) AS minutes_ago,
    CASE 
        WHEN DATEDIFF(MINUTE, MAX(LoadedAt), GETDATE()) > 60 
        THEN 'STALE' ELSE 'FRESH' 
    END AS status
FROM Orders;
```

### 5. Uniqueness
Are duplicate records present?
```sql
-- Check for duplicate orders
SELECT 
    'Uniqueness Check' AS check_name,
    COUNT(*) - COUNT(DISTINCT OrderID) AS duplicate_count
FROM Orders;
```

### 6. Distribution
Are statistical patterns normal?
```sql
-- Check if distribution is anomalous
WITH daily_stats AS (
    SELECT 
        CAST(OrderDate AS DATE) AS date,
        COUNT(*) AS order_count,
        AVG(TotalAmount) AS avg_amount
    FROM Orders
    WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY CAST(OrderDate AS DATE)
)
SELECT 
    'Distribution Check' AS check_name,
    AVG(order_count) AS avg_daily_orders,
    STDEV(order_count) AS stdev_orders,
    -- Today is anomalous if more than 2 std devs from mean
    CASE 
        WHEN ABS((SELECT COUNT(*) FROM Orders WHERE OrderDate = CAST(GETDATE() AS DATE)) - AVG(order_count)) 
             > 2 * STDEV(order_count)
        THEN 'ANOMALY' ELSE 'NORMAL'
    END AS status
FROM daily_stats;
```

## Project Structure

### Phase 1: Quality Framework
1. `01-data-quality-setup.md` - Understand quality concepts
2. `02-create-quality-tables.sql` - Metadata and logging tables
3. `03-data-profiling.sql` - Analyze data characteristics
4. `04-quality-rules.sql` - Define business rules

### Phase 2: Automated Checks
5. `05-completeness-checks.sql` - Record count validations
6. `06-accuracy-checks.sql` - Value range and format checks
7. `07-consistency-checks.sql` - Referential integrity checks
8. `08-freshness-checks.sql` - Data timeliness monitoring
9. `09-uniqueness-checks.sql` - Duplicate detection
10. `10-distribution-checks.sql` - Anomaly detection

### Phase 3: Monitoring & Alerting
11. `11-quality-dashboard.sql` - Real-time quality scorecard
12. `12-trend-analysis.sql` - Track quality over time
13. `13-alert-configuration.sql` - Define alert thresholds
14. `14-email-alerts.sql` - Send notifications on failures

### Phase 4: Production Patterns
15. `15-scheduled-monitoring.sql` - Automated check execution
16. `16-remediation-workflows.sql` - Auto-fix common issues
17. `17-quality-reports.sql` - Executive quality summaries

## Monitoring Architecture

### Quality Check Framework
```sql
-- Metadata: Define all quality checks
CREATE TABLE metadata.quality_checks (
    check_id INT PRIMARY KEY IDENTITY,
    check_name VARCHAR(200),
    table_name VARCHAR(100),
    check_type VARCHAR(50),  -- 'completeness', 'accuracy', etc.
    sql_query NVARCHAR(MAX),
    threshold_value DECIMAL(10,2),
    severity VARCHAR(20),    -- 'critical', 'warning', 'info'
    is_active BIT DEFAULT 1
);

-- Log: Record check results
CREATE TABLE metadata.quality_results (
    result_id INT PRIMARY KEY IDENTITY,
    check_id INT,
    run_date DATETIME DEFAULT GETDATE(),
    status VARCHAR(20),      -- 'pass', 'fail', 'warning'
    actual_value DECIMAL(18,2),
    expected_value DECIMAL(18,2),
    error_message NVARCHAR(MAX)
);

-- Alerts: Track notifications sent
CREATE TABLE metadata.quality_alerts (
    alert_id INT PRIMARY KEY IDENTITY,
    check_id INT,
    alert_date DATETIME DEFAULT GETDATE(),
    alert_level VARCHAR(20),
    recipients VARCHAR(500),
    message NVARCHAR(MAX),
    resolved BIT DEFAULT 0
);
```

### Check Execution Pattern
```sql
-- Execute all active checks
CREATE PROCEDURE sp_run_quality_checks
AS
BEGIN
    DECLARE @check_id INT, @sql NVARCHAR(MAX), @threshold DECIMAL(10,2);
    DECLARE @actual_value DECIMAL(18,2), @status VARCHAR(20);

    DECLARE check_cursor CURSOR FOR
    SELECT check_id, sql_query, threshold_value
    FROM metadata.quality_checks
    WHERE is_active = 1;

    OPEN check_cursor;
    FETCH NEXT FROM check_cursor INTO @check_id, @sql, @threshold;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Execute check query
        EXEC sp_executesql @sql, N'@result DECIMAL(18,2) OUTPUT', @actual_value OUTPUT;

        -- Evaluate against threshold
        SET @status = CASE WHEN @actual_value > @threshold THEN 'fail' ELSE 'pass' END;

        -- Log result
        INSERT INTO metadata.quality_results (check_id, status, actual_value, expected_value)
        VALUES (@check_id, @status, @actual_value, @threshold);

        -- Send alert if failed
        IF @status = 'fail'
            EXEC sp_send_quality_alert @check_id, @actual_value;

        FETCH NEXT FROM check_cursor INTO @check_id, @sql, @threshold;
    END;

    CLOSE check_cursor;
    DEALLOCATE check_cursor;
END;
```

## Real-World Quality Checks

### Check 1: Revenue Drop Detection
```sql
-- Alert if today's revenue is 30% lower than 7-day average
WITH revenue_stats AS (
    SELECT 
        AVG(daily_revenue) AS avg_revenue,
        STDEV(daily_revenue) AS stdev_revenue
    FROM (
        SELECT CAST(OrderDate AS DATE) AS date, SUM(TotalAmount) AS daily_revenue
        FROM Orders
        WHERE OrderDate >= DATEADD(DAY, -7, GETDATE())
        GROUP BY CAST(OrderDate AS DATE)
    ) sub
)
SELECT 
    SUM(TotalAmount) AS today_revenue,
    (SELECT avg_revenue FROM revenue_stats) AS avg_revenue,
    CASE 
        WHEN SUM(TotalAmount) < (SELECT avg_revenue FROM revenue_stats) * 0.7 
        THEN 'FAIL' ELSE 'PASS' 
    END AS status
FROM Orders
WHERE OrderDate = CAST(GETDATE() AS DATE);
```

### Check 2: Customer Orphan Detection
```sql
-- Find orders with invalid customer IDs
SELECT 
    COUNT(*) AS orphan_orders,
    CASE WHEN COUNT(*) > 0 THEN 'FAIL' ELSE 'PASS' END AS status
FROM Orders o
WHERE NOT EXISTS (SELECT 1 FROM Customers c WHERE c.CustomerID = o.CustomerID);
```

### Check 3: Price Spike Detection
```sql
-- Detect products with sudden price increases (>50%)
WITH price_changes AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Price AS current_price,
        LAG(p.Price) OVER (PARTITION BY p.ProductID ORDER BY p.ModifiedDate) AS previous_price
    FROM Products p
)
SELECT 
    ProductID,
    ProductName,
    previous_price,
    current_price,
    (current_price - previous_price) / previous_price * 100 AS pct_change
FROM price_changes
WHERE (current_price - previous_price) / previous_price > 0.5  -- 50% increase
  AND previous_price IS NOT NULL;
```

### Check 4: Data Freshness SLA
```sql
-- Alert if data is more than 1 hour old
SELECT 
    table_name,
    MAX(loaded_at) AS last_load,
    DATEDIFF(MINUTE, MAX(loaded_at), GETDATE()) AS minutes_old,
    CASE 
        WHEN DATEDIFF(MINUTE, MAX(loaded_at), GETDATE()) > 60 
        THEN 'SLA_BREACH' ELSE 'OK' 
    END AS status
FROM (
    SELECT 'Orders' AS table_name, LoadedAt AS loaded_at FROM Orders
    UNION ALL
    SELECT 'Products', LoadedAt FROM Products
    UNION ALL
    SELECT 'Customers', LoadedAt FROM Customers
) all_tables
GROUP BY table_name;
```

## Benefits of Data Quality Monitoring

### ✅ **Early Detection**
Catch issues before they impact business users

### ✅ **Automated Validation**
No manual checking - runs automatically

### ✅ **Trust in Data**
Users confident in data accuracy

### ✅ **Root Cause Analysis**
Historical logs help debug issues

### ✅ **SLA Compliance**
Prove data meets freshness/accuracy SLAs

## Industry Use Cases

### E-commerce
- **Order monitoring**: Detect missing orders
- **Inventory checks**: Negative stock alerts
- **Revenue validation**: Daily revenue trends

### Banking
- **Transaction integrity**: Balancing checks
- **Fraud detection**: Unusual transaction patterns
- **Compliance**: Data lineage tracking

### Healthcare
- **Patient records**: Completeness validation
- **Lab results**: Range checks
- **Billing**: Revenue cycle monitoring

## Expected Outcomes

By the end of this project:
1. ✅ Build automated data quality checks
2. ✅ Implement anomaly detection algorithms
3. ✅ Create quality scorecards and dashboards
4. ✅ Set up alerting for critical issues
5. ✅ Understand production data quality patterns

## Time Estimate
- Phase 1 (Framework): 2-3 hours
- Phase 2 (Checks): 3-4 hours
- Phase 3 (Monitoring): 2-3 hours
- Phase 4 (Production): 2 hours
- **Total**: 9-12 hours

## Prerequisites
- Complete at least one other project
- Understand stored procedures, dynamic SQL
- Basic statistics knowledge (mean, standard deviation)

## Next Steps
After this project:
- Integrate with incident management (PagerDuty, Slack)
- Build data catalog with quality metrics
- Implement automated remediation workflows

Start with `01-data-quality-setup.md`!
