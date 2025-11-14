/*============================================================================
  File:     04-quality-rules.sql
  Project:  Data Quality Monitoring - TechStore
  Phase:    1 - Quality Framework
  Purpose:  Define comprehensive business validation rules
  
  Description:
  This script populates the metadata.quality_checks table with validation
  rules covering all 6 data quality dimensions:
  
  1. COMPLETENESS - Are all expected records present?
  2. ACCURACY - Are values correct and valid?
  3. CONSISTENCY - Do values align across tables?
  4. TIMELINESS - Is data fresh enough?
  5. UNIQUENESS - Are there unwanted duplicates?
  6. DISTRIBUTION - Are statistical patterns normal?
  
  Each rule includes:
  - SQL query to execute validation
  - Threshold value for pass/fail determination
  - Severity level (critical/warning/info)
  - Human-readable description
  
  These rules are metadata-driven: Add/modify rules here without changing
  the execution engine code.
  
  Author:       SQL Training Team
  Created:      2025-01-24
  Modified:     2025-01-24
============================================================================*/

USE TechStore_DQ;
GO

-- Clear existing quality checks (idempotent)
DELETE FROM metadata.quality_checks;
DBCC CHECKIDENT ('metadata.quality_checks', RESEED, 0);
GO

PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║          DEFINING DATA QUALITY VALIDATION RULES                 ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';

/*----------------------------------------------------------------------------
  DIMENSION 1: COMPLETENESS CHECKS
  
  Purpose: Ensure all expected records are present and required fields populated
  
  Use Cases:
  - ETL job failed, only loaded 10% of expected orders
  - Source API returned partial data
  - Required fields have NULL values (FirstName, Email, etc.)
----------------------------------------------------------------------------*/

PRINT 'Creating COMPLETENESS quality checks...';

-- Check 1: Daily order volume (expected 100-1000 per day)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Daily Order Volume - Minimum',
    'Orders', 'OrderID', 'completeness',
    'SELECT COUNT(*) FROM Orders WHERE CAST(OrderDate AS DATE) = CAST(GETDATE() AS DATE)',
    100,  -- Minimum 100 orders expected per day
    '>=',
    'critical',
    'Validates that at least 100 orders were received today. Fewer orders indicate ETL failure or business issue.',
    1
);

-- Check 2: NULL FirstName in Customers
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Customer FirstName Completeness',
    'Customers', 'FirstName', 'completeness',
    'SELECT COUNT(*) FROM Customers WHERE FirstName IS NULL',
    0,  -- No NULL FirstNames allowed
    '=',
    'critical',
    'Ensures all customers have a first name. NULL values indicate incomplete registration data.',
    1
);

-- Check 3: NULL LastName in Customers
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Customer LastName Completeness',
    'Customers', 'LastName', 'completeness',
    'SELECT COUNT(*) FROM Customers WHERE LastName IS NULL',
    0,  -- No NULL LastNames allowed
    '=',
    'critical',
    'Ensures all customers have a last name. NULL values indicate incomplete registration data.',
    1
);

-- Check 4: NULL Email in Customers
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Customer Email Completeness',
    'Customers', 'Email', 'completeness',
    'SELECT COUNT(*) FROM Customers WHERE Email IS NULL',
    0,  -- No NULL emails allowed
    '=',
    'critical',
    'Ensures all customers have an email address. Required for notifications and password resets.',
    1
);

-- Check 5: Product Price completeness
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Product Price Completeness',
    'Products', 'Price', 'completeness',
    'SELECT COUNT(*) FROM Products WHERE Price IS NULL',
    0,  -- No NULL prices allowed
    '=',
    'critical',
    'Ensures all products have a price. NULL prices prevent ordering and revenue calculation.',
    1
);

PRINT 'Created 5 COMPLETENESS checks';
PRINT '';

/*----------------------------------------------------------------------------
  DIMENSION 2: ACCURACY CHECKS
  
  Purpose: Validate that values are correct, within expected ranges, and follow format rules
  
  Use Cases:
  - Negative prices or stock quantities
  - Ages over 150 years
  - Invalid email formats
  - Dates in the future
----------------------------------------------------------------------------*/

PRINT 'Creating ACCURACY quality checks...';

-- Check 6: Negative product prices
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Product Price - No Negatives',
    'Products', 'Price', 'accuracy',
    'SELECT COUNT(*) FROM Products WHERE Price < 0',
    0,  -- No negative prices allowed
    '=',
    'critical',
    'Detects products with negative prices, which are invalid and would cause revenue calculation errors.',
    1
);

-- Check 7: Negative stock quantities
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Product Stock - No Negatives',
    'Products', 'StockQuantity', 'accuracy',
    'SELECT COUNT(*) FROM Products WHERE StockQuantity < 0',
    0,  -- No negative stock allowed
    '=',
    'critical',
    'Detects products with negative stock quantities, indicating data quality or inventory management issues.',
    1
);

-- Check 8: Suspiciously high order amounts (> $10,000)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Order Amount - Suspicious High',
    'Orders', 'TotalAmount', 'accuracy',
    'SELECT COUNT(*) FROM Orders WHERE TotalAmount > 10000',
    5,  -- Tolerate up to 5 high-value orders per day
    '<=',
    'warning',
    'Flags orders exceeding $10,000 as potentially fraudulent or data entry errors. Manual review recommended.',
    1
);

-- Check 9: Negative order amounts
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Order Amount - No Negatives',
    'Orders', 'TotalAmount', 'accuracy',
    'SELECT COUNT(*) FROM Orders WHERE TotalAmount < 0',
    0,  -- No negative amounts allowed
    '=',
    'critical',
    'Detects orders with negative amounts, which are invalid and skew revenue reporting.',
    1
);

-- Check 10: Invalid email format (basic check - missing @)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Customer Email - Valid Format',
    'Customers', 'Email', 'accuracy',
    'SELECT COUNT(*) FROM Customers WHERE Email NOT LIKE ''%@%'' AND Email IS NOT NULL',
    0,  -- No invalid emails allowed
    '=',
    'warning',
    'Validates email format by checking for @ symbol. Invalid emails cause notification failures.',
    1
);

PRINT 'Created 5 ACCURACY checks';
PRINT '';

/*----------------------------------------------------------------------------
  DIMENSION 3: CONSISTENCY CHECKS
  
  Purpose: Ensure data aligns across tables and maintains referential integrity
  
  Use Cases:
  - Orders referencing deleted customers (orphan records)
  - Sum of line items ≠ order total
  - Shipping date before order date
----------------------------------------------------------------------------*/

PRINT 'Creating CONSISTENCY quality checks...';

-- Check 11: Orders with invalid CustomerID (orphans)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Order-Customer Referential Integrity',
    'Orders', 'CustomerID', 'consistency',
    'SELECT COUNT(*) FROM Orders o WHERE NOT EXISTS (SELECT 1 FROM Customers c WHERE c.CustomerID = o.CustomerID)',
    0,  -- No orphan orders allowed
    '=',
    'critical',
    'Detects orders referencing non-existent customers, indicating referential integrity violation.',
    1
);

-- Check 12: Orders with invalid ProductID (orphans)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Order-Product Referential Integrity',
    'Orders', 'ProductID', 'consistency',
    'SELECT COUNT(*) FROM Orders o WHERE NOT EXISTS (SELECT 1 FROM Products p WHERE p.ProductID = o.ProductID)',
    0,  -- No orphan orders allowed
    '=',
    'critical',
    'Detects orders referencing non-existent products, indicating catalog data sync issues.',
    1
);

PRINT 'Created 2 CONSISTENCY checks';
PRINT '';

/*----------------------------------------------------------------------------
  DIMENSION 4: TIMELINESS/FRESHNESS CHECKS
  
  Purpose: Ensure data is loaded within acceptable SLA timeframes
  
  Use Cases:
  - Dashboard showing yesterday's data at 3 PM
  - ETL job delayed > 1 hour
  - Stock levels not updated for days
----------------------------------------------------------------------------*/

PRINT 'Creating TIMELINESS quality checks...';

-- Check 13: Orders data freshness (SLA: < 1 hour)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Orders Data Freshness - SLA 1 Hour',
    'Orders', 'LoadedAt', 'timeliness',
    'SELECT DATEDIFF(MINUTE, MAX(LoadedAt), GETDATE()) FROM Orders',
    60,  -- Data must be < 60 minutes old
    '<=',
    'critical',
    'Ensures order data is refreshed within 1-hour SLA. Stale data impacts real-time dashboards.',
    1
);

-- Check 14: Product restock timeliness (warning if > 90 days)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Product Restock Freshness - 90 Days',
    'Products', 'LastRestockedDate', 'timeliness',
    'SELECT COUNT(*) FROM Products WHERE DATEDIFF(DAY, LastRestockedDate, GETDATE()) > 90',
    2,  -- Tolerate up to 2 stale products
    '<=',
    'warning',
    'Flags products not restocked in 90+ days as potentially discontinued or slow-moving inventory.',
    1
);

PRINT 'Created 2 TIMELINESS checks';
PRINT '';

/*----------------------------------------------------------------------------
  DIMENSION 5: UNIQUENESS CHECKS
  
  Purpose: Detect duplicate records that violate business key uniqueness
  
  Use Cases:
  - Same customer registered twice
  - Duplicate order IDs from source system
  - Same email used for multiple accounts
----------------------------------------------------------------------------*/

PRINT 'Creating UNIQUENESS quality checks...';

-- Check 15: Duplicate customer emails
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Customer Email Uniqueness',
    'Customers', 'Email', 'uniqueness',
    'SELECT COUNT(*) FROM (SELECT Email FROM Customers WHERE Email IS NOT NULL GROUP BY Email HAVING COUNT(*) > 1) AS duplicates',
    0,  -- No duplicate emails allowed
    '=',
    'critical',
    'Detects duplicate email addresses, which cause confusion and duplicate marketing communications.',
    1
);

-- Check 16: Duplicate order IDs (if OrderID not primary key)
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Order ID Uniqueness',
    'Orders', 'OrderID', 'uniqueness',
    'SELECT COUNT(*) FROM (SELECT OrderID FROM Orders GROUP BY OrderID HAVING COUNT(*) > 1) AS duplicates',
    0,  -- No duplicate order IDs allowed
    '=',
    'critical',
    'Detects duplicate order IDs, indicating data import errors or source system issues.',
    1
);

PRINT 'Created 2 UNIQUENESS checks';
PRINT '';

/*----------------------------------------------------------------------------
  DIMENSION 6: DISTRIBUTION/ANOMALY CHECKS
  
  Purpose: Detect statistical outliers and unusual patterns
  
  Use Cases:
  - Daily orders drop from 500 to 50 (90% decrease)
  - Average order value spikes from $100 to $5,000
  - Sudden surge in new customer registrations (bot attack?)
  
  Method: Compare current value to historical average ± 2 standard deviations
----------------------------------------------------------------------------*/

PRINT 'Creating DISTRIBUTION quality checks...';

-- Check 17: Daily order volume anomaly detection
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Daily Order Volume - Anomaly Detection',
    'Orders', 'OrderID', 'distribution',
    'WITH today AS (
        SELECT COUNT(*) AS today_count
        FROM Orders
        WHERE CAST(OrderDate AS DATE) = CAST(GETDATE() AS DATE)
    ),
    baseline AS (
        SELECT 
            AVG(daily_count) AS avg_count,
            STDEV(daily_count) AS stdev_count
        FROM (
            SELECT COUNT(*) AS daily_count
            FROM Orders
            WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())
              AND OrderDate < CAST(GETDATE() AS DATE)
            GROUP BY CAST(OrderDate AS DATE)
        ) hist
    )
    SELECT 
        CASE 
            WHEN ABS(t.today_count - b.avg_count) > 2 * b.stdev_count THEN 1
            ELSE 0
        END AS is_anomaly
    FROM today t
    CROSS JOIN baseline b',
    0,  -- Expect 0 anomalies (normal distribution)
    '=',
    'warning',
    'Detects unusual daily order volumes using 2-sigma statistical threshold. Flags potential ETL failures or business disruptions.',
    1
);

-- Check 18: Average order amount anomaly detection
INSERT INTO metadata.quality_checks (
    check_name, table_name, column_name, check_type,
    sql_query, threshold_value, threshold_operator,
    severity, description, is_active
)
VALUES (
    'Average Order Amount - Anomaly Detection',
    'Orders', 'TotalAmount', 'distribution',
    'WITH today AS (
        SELECT AVG(TotalAmount) AS today_avg
        FROM Orders
        WHERE CAST(OrderDate AS DATE) = CAST(GETDATE() AS DATE)
          AND TotalAmount >= 0
    ),
    baseline AS (
        SELECT 
            AVG(avg_amount) AS avg_of_avgs,
            STDEV(avg_amount) AS stdev_of_avgs
        FROM (
            SELECT AVG(TotalAmount) AS avg_amount
            FROM Orders
            WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())
              AND OrderDate < CAST(GETDATE() AS DATE)
              AND TotalAmount >= 0
            GROUP BY CAST(OrderDate AS DATE)
        ) hist
    )
    SELECT 
        CASE 
            WHEN ABS(t.today_avg - b.avg_of_avgs) > 2 * b.stdev_of_avgs THEN 1
            ELSE 0
        END AS is_anomaly
    FROM today t
    CROSS JOIN baseline b',
    0,  -- Expect 0 anomalies
    '=',
    'warning',
    'Detects unusual average order amounts. Spikes may indicate pricing errors; drops may indicate discount issues.',
    1
);

PRINT 'Created 2 DISTRIBUTION checks';
PRINT '';

/*----------------------------------------------------------------------------
  SUMMARY & VERIFICATION
----------------------------------------------------------------------------*/

PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║          QUALITY RULES DEFINITION COMPLETE                      ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Quality Checks Summary:';

SELECT 
    check_type,
    COUNT(*) AS check_count,
    SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) AS critical_checks,
    SUM(CASE WHEN severity = 'warning' THEN 1 ELSE 0 END) AS warning_checks,
    SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_checks
FROM metadata.quality_checks
GROUP BY check_type
ORDER BY check_type;
GO

PRINT '';
PRINT 'Total Checks by Severity:';
SELECT 
    severity,
    COUNT(*) AS check_count
FROM metadata.quality_checks
GROUP BY severity
ORDER BY 
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        WHEN 'info' THEN 3
    END;
GO

PRINT '';
PRINT 'Sample Quality Checks:';
SELECT TOP 5
    check_id,
    check_name,
    table_name,
    check_type,
    severity,
    threshold_value,
    threshold_operator
FROM metadata.quality_checks
ORDER BY check_id;
GO

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║                    NEXT STEPS                                   ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Quality rules are now defined in metadata.quality_checks table.';
PRINT '';
PRINT 'Each rule includes:';
PRINT '- SQL query to execute';
PRINT '- Threshold value for pass/fail';
PRINT '- Severity level (critical/warning/info)';
PRINT '- Human-readable description';
PRINT '';
PRINT 'Next phase: Create automated check execution procedures';
PRINT 'Run script: 05-completeness-checks.sql';
PRINT '';
PRINT 'To view all rules:';
PRINT 'SELECT * FROM metadata.quality_checks ORDER BY check_type, check_id;';
PRINT '';

/*============================================================================
  APPENDIX: ADDING NEW QUALITY RULES
  
  To add a new quality check, use this template:
  
  INSERT INTO metadata.quality_checks (
      check_name, table_name, column_name, check_type,
      sql_query, threshold_value, threshold_operator,
      severity, description, is_active
  )
  VALUES (
      'Your Check Name',
      'TableName',
      'ColumnName',
      'completeness|accuracy|consistency|timeliness|uniqueness|distribution',
      'SELECT <metric> FROM <table> WHERE <condition>',
      <expected_value>,
      '=|>|<|>=|<=|between',
      'critical|warning|info',
      'Detailed description of what this check validates',
      1  -- Active
  );
  
  Example - Check for orders older than 7 days:
  
  INSERT INTO metadata.quality_checks (
      check_name, table_name, column_name, check_type,
      sql_query, threshold_value, threshold_operator,
      severity, description, is_active
  )
  VALUES (
      'Old Orders - 7 Days',
      'Orders',
      'OrderDate',
      'timeliness',
      'SELECT COUNT(*) FROM Orders WHERE DATEDIFF(DAY, OrderDate, GETDATE()) > 7',
      10,  -- Tolerate up to 10 old orders
      '<=',
      'warning',
      'Flags orders older than 7 days that may need archival or investigation',
      1
  );
  
============================================================================*/

/*============================================================================
  END OF SCRIPT
============================================================================*/
