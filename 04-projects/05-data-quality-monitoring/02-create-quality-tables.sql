-- ============================================================================
-- Data Quality Monitoring - Database Setup
-- ============================================================================
-- Create infrastructure for comprehensive data quality monitoring
-- ============================================================================

/*
============================================================================
DATA QUALITY MONITORING OVERVIEW
============================================================================

WHAT IS DATA QUALITY?

Data quality is the degree to which data meets business requirements for:
- Accuracy: Values are correct and valid
- Completeness: All expected data is present
- Consistency: Data agrees across systems
- Timeliness: Data is current and fresh
- Uniqueness: No duplicate records
- Validity: Data conforms to business rules

WHY MONITOR DATA QUALITY?

WITHOUT MONITORING:
┌─────────────────┐
│  Bad Data In    │
│       ↓         │
│  No Detection   │
│       ↓         │
│ Business Uses   │
│       ↓         │
│ Wrong Decisions │
│       ↓         │
│  💸 Loss of     │
│     Trust       │
└─────────────────┘

WITH MONITORING:
┌─────────────────┐
│  Bad Data In    │
│       ↓         │
│ Automated Check │
│       ↓         │
│  Alert Sent     │
│       ↓         │
│  Fix Quickly    │
│       ↓         │
│ ✅ Trust Built  │
└─────────────────┘

REAL-WORLD IMPACT:

Case 1: E-commerce Company
- Issue: ETL dropped 30% of orders silently
- Impact: $2M revenue reported missing
- Detection: Manual review 3 days later
- Solution: Automated volume checks catch in 5 minutes

Case 2: Healthcare System
- Issue: Patient records duplicated
- Impact: Incorrect treatment decisions
- Detection: Audit found 6 months later
- Solution: Uniqueness checks prevent duplicates

Case 3: Financial Services
- Issue: Currency exchange rates stale (24 hours old)
- Impact: Wrong pricing, customer complaints
- Detection: Customer reported issue
- Solution: Freshness checks enforce SLA

MONITORING FRAMEWORK:

1. Define Quality Rules
   - What should be checked?
   - What are acceptable thresholds?

2. Execute Checks
   - Run automated validation queries
   - Log results with timestamps

3. Evaluate Results
   - Pass/Fail/Warning status
   - Compare against baselines

4. Alert on Failures
   - Email, Slack, PagerDuty
   - Escalate critical issues

5. Track Over Time
   - Quality scorecards
   - Trend analysis
   - Root cause investigation

============================================================================
*/

USE master;
GO

-- Create database for sample data
IF DB_ID('TechStore_DQ') IS NOT NULL
    DROP DATABASE TechStore_DQ;
GO

CREATE DATABASE TechStore_DQ;
GO

USE TechStore_DQ;
GO

PRINT '=================================================================';
PRINT 'DATA QUALITY MONITORING - DATABASE SETUP';
PRINT '=================================================================';
PRINT '';

-- ============================================================================
-- CREATE SOURCE TABLES (Sample Business Data)
-- ============================================================================

PRINT 'Creating source tables...';
PRINT '';

-- Orders table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    ShipDate DATETIME NULL,
    TotalAmount DECIMAL(12,2) NOT NULL,
    OrderStatus VARCHAR(20) DEFAULT 'Pending',
    LoadedAt DATETIME DEFAULT GETDATE(),
    SourceSystem VARCHAR(50) DEFAULT 'OLTP'
);

-- Customers table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    Country VARCHAR(50),
    RegistrationDate DATETIME DEFAULT GETDATE(),
    LoadedAt DATETIME DEFAULT GETDATE()
);

-- Products table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2),
    StockQuantity INT DEFAULT 0,
    LastRestockedDate DATETIME,
    LoadedAt DATETIME DEFAULT GETDATE()
);

PRINT '✓ Created Orders, Customers, Products tables';
PRINT '';

-- ============================================================================
-- CREATE METADATA SCHEMA FOR QUALITY FRAMEWORK
-- ============================================================================

PRINT 'Creating metadata schema...';
GO

CREATE SCHEMA metadata;
GO

PRINT '✓ Created metadata schema';
PRINT '';

-- ============================================================================
-- METADATA TABLE: Quality Check Definitions
-- ============================================================================

PRINT 'Creating quality check metadata tables...';

CREATE TABLE metadata.quality_checks (
    check_id INT PRIMARY KEY IDENTITY(1,1),
    check_name VARCHAR(200) NOT NULL,
    check_description VARCHAR(500),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NULL,
    check_type VARCHAR(50) NOT NULL,  -- 'completeness', 'accuracy', 'consistency', etc.
    check_category VARCHAR(50) NOT NULL,  -- 'critical', 'important', 'info'
    sql_query NVARCHAR(MAX) NOT NULL,
    threshold_operator VARCHAR(10),   -- '>', '<', '=', '!=', 'between'
    threshold_value DECIMAL(18,2),
    threshold_value2 DECIMAL(18,2) NULL,  -- For BETWEEN
    severity VARCHAR(20) DEFAULT 'warning',  -- 'critical', 'warning', 'info'
    is_active BIT DEFAULT 1,
    created_date DATETIME DEFAULT GETDATE(),
    modified_date DATETIME DEFAULT GETDATE(),
    created_by VARCHAR(50) DEFAULT SYSTEM_USER
);

PRINT '  ✓ Created metadata.quality_checks';

-- ============================================================================
-- METADATA TABLE: Quality Check Results (Historical Log)
-- ============================================================================

CREATE TABLE metadata.quality_results (
    result_id BIGINT PRIMARY KEY IDENTITY(1,1),
    check_id INT NOT NULL,
    run_date DATETIME DEFAULT GETDATE(),
    execution_duration_ms INT,
    status VARCHAR(20) NOT NULL,  -- 'pass', 'fail', 'warning', 'error'
    actual_value DECIMAL(18,2),
    expected_value DECIMAL(18,2),
    threshold_value DECIMAL(18,2),
    pass_rate DECIMAL(5,2),  -- Percentage 0-100
    fail_count INT DEFAULT 0,
    warning_count INT DEFAULT 0,
    error_message NVARCHAR(MAX),
    details NVARCHAR(MAX),
    FOREIGN KEY (check_id) REFERENCES metadata.quality_checks(check_id)
);

CREATE INDEX IX_quality_results_check_date ON metadata.quality_results(check_id, run_date);
CREATE INDEX IX_quality_results_status ON metadata.quality_results(status, run_date);

PRINT '  ✓ Created metadata.quality_results';

-- ============================================================================
-- METADATA TABLE: Quality Alerts
-- ============================================================================

CREATE TABLE metadata.quality_alerts (
    alert_id BIGINT PRIMARY KEY IDENTITY(1,1),
    check_id INT NOT NULL,
    result_id BIGINT,
    alert_date DATETIME DEFAULT GETDATE(),
    alert_level VARCHAR(20) NOT NULL,  -- 'critical', 'warning', 'info'
    alert_status VARCHAR(20) DEFAULT 'open',  -- 'open', 'acknowledged', 'resolved', 'suppressed'
    recipients VARCHAR(500),
    subject VARCHAR(200),
    message NVARCHAR(MAX),
    sent_via VARCHAR(50),  -- 'email', 'slack', 'pagerduty'
    acknowledged_by VARCHAR(100),
    acknowledged_date DATETIME,
    resolved_by VARCHAR(100),
    resolved_date DATETIME,
    resolution_notes NVARCHAR(MAX),
    FOREIGN KEY (check_id) REFERENCES metadata.quality_checks(check_id),
    FOREIGN KEY (result_id) REFERENCES metadata.quality_results(result_id)
);

CREATE INDEX IX_quality_alerts_status ON metadata.quality_alerts(alert_status, alert_date);

PRINT '  ✓ Created metadata.quality_alerts';

-- ============================================================================
-- METADATA TABLE: Data Profiling Statistics
-- ============================================================================

CREATE TABLE metadata.data_profile (
    profile_id BIGINT PRIMARY KEY IDENTITY(1,1),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    profile_date DATETIME DEFAULT GETDATE(),
    row_count BIGINT,
    null_count BIGINT,
    null_percentage DECIMAL(5,2),
    distinct_count BIGINT,
    distinct_percentage DECIMAL(5,2),
    min_value NVARCHAR(MAX),
    max_value NVARCHAR(MAX),
    avg_value DECIMAL(18,2),
    median_value DECIMAL(18,2),
    stdev_value DECIMAL(18,2),
    top_values NVARCHAR(MAX),  -- JSON array of top 10 values
    sample_values NVARCHAR(MAX)  -- JSON array of sample values
);

CREATE INDEX IX_data_profile_table_column ON metadata.data_profile(table_name, column_name, profile_date);

PRINT '  ✓ Created metadata.data_profile';

-- ============================================================================
-- METADATA TABLE: Quality Scorecard (Daily Summary)
-- ============================================================================

CREATE TABLE metadata.quality_scorecard (
    scorecard_id INT PRIMARY KEY IDENTITY(1,1),
    scorecard_date DATE DEFAULT CAST(GETDATE() AS DATE),
    table_name VARCHAR(100),
    total_checks INT,
    passed_checks INT,
    failed_checks INT,
    warning_checks INT,
    error_checks INT,
    quality_score DECIMAL(5,2),  -- 0-100
    critical_failures INT,
    total_records BIGINT,
    invalid_records BIGINT,
    duplicate_records BIGINT,
    missing_records BIGINT,
    freshness_minutes INT,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE INDEX IX_quality_scorecard_date ON metadata.quality_scorecard(scorecard_date, table_name);

PRINT '  ✓ Created metadata.quality_scorecard';

-- ============================================================================
-- METADATA TABLE: Quality Expectations (Baselines)
-- ============================================================================

CREATE TABLE metadata.quality_expectations (
    expectation_id INT PRIMARY KEY IDENTITY(1,1),
    table_name VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    expected_min DECIMAL(18,2),
    expected_max DECIMAL(18,2),
    expected_avg DECIMAL(18,2),
    expected_stdev DECIMAL(18,2),
    warning_threshold_pct DECIMAL(5,2) DEFAULT 10,  -- % deviation
    critical_threshold_pct DECIMAL(5,2) DEFAULT 30,
    is_active BIT DEFAULT 1,
    created_date DATETIME DEFAULT GETDATE(),
    UNIQUE (table_name, metric_name)
);

-- Insert baseline expectations
INSERT INTO metadata.quality_expectations (table_name, metric_name, expected_min, expected_max, expected_avg)
VALUES 
    ('Orders', 'daily_order_count', 100, 1000, 500),
    ('Orders', 'avg_order_amount', 50, 500, 150),
    ('Customers', 'daily_new_customers', 10, 100, 50),
    ('Products', 'in_stock_percentage', 80, 100, 95);

PRINT '  ✓ Created metadata.quality_expectations';
PRINT '';

-- ============================================================================
-- INSERT SAMPLE DATA (Including Quality Issues!)
-- ============================================================================

PRINT 'Inserting sample data with intentional quality issues...';
PRINT '';

-- Insert customers
INSERT INTO Customers (FirstName, LastName, Email, Phone, Country, RegistrationDate)
VALUES 
    ('John', 'Doe', 'john.doe@email.com', '555-0101', 'USA', '2024-01-15'),
    ('Jane', 'Smith', 'jane.smith@email.com', '555-0102', 'Canada', '2024-01-16'),
    ('Bob', 'Johnson', 'bob.j@email.com', '555-0103', 'USA', '2024-01-17'),
    (NULL, NULL, 'incomplete@email.com', NULL, NULL, '2024-01-18'),  -- ❌ Missing names
    ('Alice', 'Williams', 'alice@email.com', '555-0105', 'UK', '2024-01-19'),
    ('Charlie', 'Brown', 'charlie@email.com', '555-0106', 'USA', '2024-01-20'),
    ('Diana', 'Prince', 'diana@email.com', '555-0107', 'USA', '2024-01-21'),
    ('John', 'Doe', 'john.doe@email.com', '555-0101', 'USA', '2024-01-22');  -- ❌ Duplicate

PRINT '  ✓ Inserted 8 customers (2 with quality issues)';

-- Insert products
INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, LastRestockedDate)
VALUES 
    ('Laptop Pro', 'Electronics', 1299.99, 900, 50, '2024-01-10'),
    ('Wireless Mouse', 'Accessories', 29.99, 15, 200, '2024-01-12'),
    ('USB-C Cable', 'Accessories', 12.99, 5, 500, '2024-01-11'),
    ('Monitor 27"', 'Electronics', 399.99, 250, 75, '2024-01-09'),
    ('Keyboard', 'Accessories', 89.99, 50, -10, '2024-01-13'),  -- ❌ Negative stock!
    ('Headphones', 'Accessories', -49.99, 25, 100, '2024-01-14'),  -- ❌ Negative price!
    ('Webcam HD', 'Electronics', 79.99, 40, 0, '2023-06-01'),  -- ❌ Stale restock date
    ('Mouse Pad', 'Accessories', 9.99, 3, 1000, '2024-01-15');

PRINT '  ✓ Inserted 8 products (3 with quality issues)';

-- Insert orders
DECLARE @i INT = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO Orders (CustomerID, ProductID, OrderDate, ShipDate, TotalAmount, OrderStatus, LoadedAt)
    VALUES (
        (@i % 8) + 1,  -- Cycle through customers
        (@i % 8) + 1,  -- Cycle through products
        DATEADD(DAY, -(@i % 30), GETDATE()),
        CASE WHEN @i % 5 = 0 THEN NULL ELSE DATEADD(DAY, -(@i % 30) + 1, GETDATE()) END,
        CASE 
            WHEN @i = 50 THEN -100.00  -- ❌ Negative amount
            WHEN @i = 75 THEN 999999.99  -- ❌ Suspiciously high
            ELSE ((@i % 10) + 1) * 29.99
        END,
        CASE 
            WHEN @i % 3 = 0 THEN 'Shipped'
            WHEN @i % 3 = 1 THEN 'Pending'
            ELSE 'Delivered'
        END,
        CASE 
            WHEN @i = 1 THEN DATEADD(HOUR, -25, GETDATE())  -- ❌ Stale data (25 hours old)
            ELSE GETDATE()
        END
    );
    SET @i = @i + 1;
END;

-- Insert orphan orders (referential integrity issue)
INSERT INTO Orders (CustomerID, ProductID, OrderDate, TotalAmount, OrderStatus)
VALUES 
    (999, 1, GETDATE(), 99.99, 'Pending'),  -- ❌ Invalid CustomerID
    (1, 999, GETDATE(), 49.99, 'Pending');  -- ❌ Invalid ProductID

PRINT '  ✓ Inserted 102 orders (5 with quality issues)';
PRINT '';

-- ============================================================================
-- CREATE VIEWS FOR QUALITY MONITORING
-- ============================================================================

PRINT 'Creating quality monitoring views...';
GO

-- View: Latest quality check results
CREATE VIEW metadata.vw_latest_quality_results AS
SELECT 
    qc.check_id,
    qc.check_name,
    qc.table_name,
    qc.check_type,
    qc.severity,
    qr.run_date,
    qr.status,
    qr.actual_value,
    qr.expected_value,
    qr.pass_rate,
    qr.error_message,
    DATEDIFF(MINUTE, qr.run_date, GETDATE()) AS minutes_since_check
FROM metadata.quality_checks qc
LEFT JOIN (
    SELECT check_id, MAX(result_id) AS latest_result_id
    FROM metadata.quality_results
    GROUP BY check_id
) latest ON qc.check_id = latest.check_id
LEFT JOIN metadata.quality_results qr ON latest.latest_result_id = qr.result_id
WHERE qc.is_active = 1;
GO

-- View: Open quality alerts
CREATE VIEW metadata.vw_open_alerts AS
SELECT 
    a.alert_id,
    a.alert_date,
    a.alert_level,
    qc.check_name,
    qc.table_name,
    a.message,
    DATEDIFF(HOUR, a.alert_date, GETDATE()) AS hours_open
FROM metadata.quality_alerts a
JOIN metadata.quality_checks qc ON a.check_id = qc.check_id
WHERE a.alert_status = 'open'
ORDER BY a.alert_level DESC, a.alert_date ASC;
GO

-- View: Quality scorecard summary
CREATE VIEW metadata.vw_quality_summary AS
SELECT 
    table_name,
    COUNT(*) AS total_checks,
    SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN status = 'fail' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN status = 'warning' THEN 1 ELSE 0 END) AS warnings,
    CAST(SUM(CASE WHEN status = 'pass' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS quality_score
FROM metadata.vw_latest_quality_results
GROUP BY table_name;
GO

PRINT '✓ Created 3 monitoring views';
PRINT '';

-- ============================================================================
-- VERIFY SETUP
-- ============================================================================

PRINT '=================================================================';
PRINT 'SETUP VERIFICATION';
PRINT '=================================================================';
PRINT '';

PRINT 'Tables Created:';
SELECT name AS TableName, create_date AS CreatedDate
FROM sys.tables
WHERE schema_id = SCHEMA_ID('dbo')
ORDER BY name;

PRINT '';
PRINT 'Metadata Tables Created:';
SELECT name AS MetadataTable, create_date AS CreatedDate
FROM sys.tables
WHERE schema_id = SCHEMA_ID('metadata')
ORDER BY name;

PRINT '';
PRINT 'Sample Data Counts:';
SELECT 'Customers' AS TableName, COUNT(*) AS RowCount FROM Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders;

PRINT '';
PRINT '=================================================================';
PRINT 'DATA QUALITY MONITORING INFRASTRUCTURE COMPLETE!';
PRINT '=================================================================';

/*
============================================================================
SETUP SUMMARY
============================================================================

✅ CREATED INFRASTRUCTURE:

1. Source Tables:
   - Orders (102 rows with 5 quality issues)
   - Customers (8 rows with 2 quality issues)
   - Products (8 rows with 3 quality issues)

2. Metadata Schema:
   - quality_checks: Define validation rules
   - quality_results: Historical check results
   - quality_alerts: Alert tracking
   - data_profile: Statistical profiling
   - quality_scorecard: Daily summary
   - quality_expectations: Baseline metrics

3. Monitoring Views:
   - vw_latest_quality_results
   - vw_open_alerts
   - vw_quality_summary

4. Quality Issues Inserted (For Testing):
   - Customers: Missing names, duplicates
   - Products: Negative stock, negative price, stale data
   - Orders: Negative amounts, invalid references, stale loads

QUALITY DIMENSIONS TO CHECK:

1. Completeness: NULL values, missing records
2. Accuracy: Invalid ranges, negative values
3. Consistency: Orphan records, referential integrity
4. Timeliness: Stale data, SLA breaches
5. Uniqueness: Duplicate records
6. Validity: Business rule violations

NEXT STEPS:

1. Profile data (03-data-profiling.sql)
2. Define quality rules (04-quality-rules.sql)
3. Build automated checks (05-10)
4. Create dashboards (11-12)
5. Configure alerts (13-14)

Production-ready data quality framework! 🎯
============================================================================
*/
