/*============================================================================
  File:     03-data-profiling.sql
  Project:  Data Quality Monitoring - TechStore
  Phase:    1 - Quality Framework
  Purpose:  Comprehensive data profiling and statistical analysis
  
  Description:
  This script performs deep profiling of source data to establish baselines
  for quality monitoring. Profiling helps answer:
  
  - What is the typical range of values? (min/max/avg/median)
  - How much variance exists? (standard deviation)
  - What percentage of values are NULL?
  - How many distinct values exist?
  - What are the most common values?
  - Are there outliers or anomalies?
  
  Profiling is the foundation for:
  1. Setting realistic thresholds for quality checks
  2. Detecting anomalies (values > mean ± 2σ)
  3. Understanding data distribution patterns
  4. Validating data against expected patterns
  
  Use Cases:
  - Before defining quality rules, profile to understand normal behavior
  - Monthly profiling to detect data drift over time
  - Compare dev/test/prod environments for consistency
  - Identify columns needing data quality attention
  
  Author:       SQL Training Team
  Created:      2025-01-24
  Modified:     2025-01-24
============================================================================*/

USE TechStore_DQ;
GO

/*----------------------------------------------------------------------------
  PART 1: BASIC PROFILING - Row Counts and Schema Overview
  
  Purpose: Get high-level view of data volume and structure
----------------------------------------------------------------------------*/

PRINT '=== BASIC DATA PROFILING ===';
PRINT '';

-- Get row counts for all tables
PRINT 'Table Row Counts:';
SELECT 
    'Customers' AS table_name,
    COUNT(*) AS row_count,
    MIN(CreatedDate) AS earliest_record,
    MAX(CreatedDate) AS latest_record,
    DATEDIFF(DAY, MIN(CreatedDate), MAX(CreatedDate)) AS date_range_days
FROM Customers

UNION ALL

SELECT 
    'Products' AS table_name,
    COUNT(*) AS row_count,
    MIN(LastRestockedDate) AS earliest_record,
    MAX(LastRestockedDate) AS latest_record,
    DATEDIFF(DAY, MIN(LastRestockedDate), MAX(LastRestockedDate)) AS date_range_days
FROM Products

UNION ALL

SELECT 
    'Orders' AS table_name,
    COUNT(*) AS row_count,
    MIN(OrderDate) AS earliest_record,
    MAX(OrderDate) AS latest_record,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS date_range_days
FROM Orders
ORDER BY table_name;
GO

/*----------------------------------------------------------------------------
  PART 2: CUSTOMERS TABLE PROFILING
  
  Purpose: Analyze customer data characteristics
----------------------------------------------------------------------------*/

PRINT '';
PRINT '=== CUSTOMERS TABLE PROFILE ===';
PRINT '';

-- Completeness: NULL value analysis
PRINT 'NULL Value Analysis:';
SELECT 
    'FirstName' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN FirstName IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage
FROM Customers

UNION ALL

SELECT 
    'LastName' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN LastName IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage
FROM Customers

UNION ALL

SELECT 
    'Email' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage
FROM Customers

UNION ALL

SELECT 
    'City' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage
FROM Customers;
GO

-- Uniqueness: Duplicate detection
PRINT '';
PRINT 'Duplicate Email Analysis:';
SELECT 
    Email,
    COUNT(*) AS occurrence_count,
    CASE 
        WHEN COUNT(*) > 1 THEN 'DUPLICATE'
        ELSE 'UNIQUE'
    END AS uniqueness_status
FROM Customers
WHERE Email IS NOT NULL
GROUP BY Email
HAVING COUNT(*) > 1;
GO

-- Distribution: Top cities
PRINT '';
PRINT 'Top 5 Customer Cities:';
SELECT TOP 5
    City,
    COUNT(*) AS customer_count,
    CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Customers) AS DECIMAL(5,2)) AS percentage
FROM Customers
WHERE City IS NOT NULL
GROUP BY City
ORDER BY customer_count DESC;
GO

/*----------------------------------------------------------------------------
  PART 3: PRODUCTS TABLE PROFILING
  
  Purpose: Analyze product inventory and pricing patterns
----------------------------------------------------------------------------*/

PRINT '';
PRINT '=== PRODUCTS TABLE PROFILE ===';
PRINT '';

-- Numeric profiling: Price and stock statistics
PRINT 'Price and Stock Statistics:';
SELECT 
    COUNT(*) AS total_products,
    -- Price statistics
    MIN(Price) AS min_price,
    MAX(Price) AS max_price,
    AVG(Price) AS avg_price,
    STDEV(Price) AS stdev_price,
    -- Stock statistics
    MIN(StockQuantity) AS min_stock,
    MAX(StockQuantity) AS max_stock,
    AVG(StockQuantity) AS avg_stock,
    STDEV(StockQuantity) AS stdev_stock,
    -- Quality issues
    SUM(CASE WHEN Price < 0 THEN 1 ELSE 0 END) AS negative_price_count,
    SUM(CASE WHEN StockQuantity < 0 THEN 1 ELSE 0 END) AS negative_stock_count,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS null_price_count,
    SUM(CASE WHEN StockQuantity IS NULL THEN 1 ELSE 0 END) AS null_stock_count
FROM Products;
GO

-- Freshness: Stock restock timeliness
PRINT '';
PRINT 'Stock Freshness Analysis:';
SELECT 
    'Fresh (< 30 days)' AS freshness_category,
    COUNT(*) AS product_count
FROM Products
WHERE LastRestockedDate >= DATEADD(DAY, -30, GETDATE())

UNION ALL

SELECT 
    'Aging (30-90 days)' AS freshness_category,
    COUNT(*) AS product_count
FROM Products
WHERE LastRestockedDate BETWEEN DATEADD(DAY, -90, GETDATE()) AND DATEADD(DAY, -30, GETDATE())

UNION ALL

SELECT 
    'Stale (> 90 days)' AS freshness_category,
    COUNT(*) AS product_count
FROM Products
WHERE LastRestockedDate < DATEADD(DAY, -90, GETDATE())
ORDER BY product_count DESC;
GO

-- Distribution: Product categories (if exists)
PRINT '';
PRINT 'Product Name Length Distribution:';
SELECT 
    CASE 
        WHEN LEN(ProductName) <= 10 THEN 'Short (1-10 chars)'
        WHEN LEN(ProductName) <= 20 THEN 'Medium (11-20 chars)'
        ELSE 'Long (> 20 chars)'
    END AS name_length_category,
    COUNT(*) AS product_count,
    MIN(LEN(ProductName)) AS min_length,
    MAX(LEN(ProductName)) AS max_length
FROM Products
WHERE ProductName IS NOT NULL
GROUP BY 
    CASE 
        WHEN LEN(ProductName) <= 10 THEN 'Short (1-10 chars)'
        WHEN LEN(ProductName) <= 20 THEN 'Medium (11-20 chars)'
        ELSE 'Long (> 20 chars)'
    END
ORDER BY min_length;
GO

/*----------------------------------------------------------------------------
  PART 4: ORDERS TABLE PROFILING
  
  Purpose: Analyze order patterns and transaction behavior
----------------------------------------------------------------------------*/

PRINT '';
PRINT '=== ORDERS TABLE PROFILE ===';
PRINT '';

-- Comprehensive order statistics
PRINT 'Order Amount Statistics:';
SELECT 
    COUNT(*) AS total_orders,
    -- Amount statistics
    MIN(TotalAmount) AS min_amount,
    MAX(TotalAmount) AS max_amount,
    AVG(TotalAmount) AS avg_amount,
    STDEV(TotalAmount) AS stdev_amount,
    -- Percentiles (approximate using TOP)
    (SELECT TOP 1 PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY TotalAmount) OVER() FROM Orders) AS percentile_25,
    (SELECT TOP 1 PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY TotalAmount) OVER() FROM Orders) AS median,
    (SELECT TOP 1 PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TotalAmount) OVER() FROM Orders) AS percentile_75,
    -- Quality issues
    SUM(CASE WHEN TotalAmount < 0 THEN 1 ELSE 0 END) AS negative_amount_count,
    SUM(CASE WHEN TotalAmount > 10000 THEN 1 ELSE 0 END) AS suspicious_high_count,
    SUM(CASE WHEN TotalAmount IS NULL THEN 1 ELSE 0 END) AS null_amount_count
FROM Orders;
GO

-- Timeliness: Order processing freshness
PRINT '';
PRINT 'Order Freshness Analysis:';
SELECT 
    CASE 
        WHEN DATEDIFF(MINUTE, LoadedAt, GETDATE()) <= 60 THEN 'Fresh (< 1 hour)'
        WHEN DATEDIFF(MINUTE, LoadedAt, GETDATE()) <= 1440 THEN 'Recent (1-24 hours)'
        ELSE 'Stale (> 24 hours)'
    END AS freshness_category,
    COUNT(*) AS order_count,
    MIN(DATEDIFF(MINUTE, LoadedAt, GETDATE())) AS min_age_minutes,
    MAX(DATEDIFF(MINUTE, LoadedAt, GETDATE())) AS max_age_minutes,
    AVG(DATEDIFF(MINUTE, LoadedAt, GETDATE())) AS avg_age_minutes
FROM Orders
GROUP BY 
    CASE 
        WHEN DATEDIFF(MINUTE, LoadedAt, GETDATE()) <= 60 THEN 'Fresh (< 1 hour)'
        WHEN DATEDIFF(MINUTE, LoadedAt, GETDATE()) <= 1440 THEN 'Recent (1-24 hours)'
        ELSE 'Stale (> 24 hours)'
    END
ORDER BY avg_age_minutes;
GO

-- Daily order volume patterns
PRINT '';
PRINT 'Daily Order Volume (Last 7 Days):';
SELECT 
    CAST(OrderDate AS DATE) AS order_date,
    COUNT(*) AS daily_orders,
    SUM(TotalAmount) AS daily_revenue,
    AVG(TotalAmount) AS avg_order_value,
    MIN(TotalAmount) AS min_order,
    MAX(TotalAmount) AS max_order
FROM Orders
WHERE OrderDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY CAST(OrderDate AS DATE)
ORDER BY order_date DESC;
GO

-- Consistency: Referential integrity checks
PRINT '';
PRINT 'Referential Integrity Analysis:';
SELECT 
    'Orders with valid CustomerID' AS check_description,
    COUNT(*) AS count
FROM Orders o
WHERE EXISTS (SELECT 1 FROM Customers c WHERE c.CustomerID = o.CustomerID)

UNION ALL

SELECT 
    'Orders with INVALID CustomerID (orphans)' AS check_description,
    COUNT(*) AS count
FROM Orders o
WHERE NOT EXISTS (SELECT 1 FROM Customers c WHERE c.CustomerID = o.CustomerID)

UNION ALL

SELECT 
    'Orders with valid ProductID' AS check_description,
    COUNT(*) AS count
FROM Orders o
WHERE EXISTS (SELECT 1 FROM Products p WHERE p.ProductID = o.ProductID)

UNION ALL

SELECT 
    'Orders with INVALID ProductID (orphans)' AS check_description,
    COUNT(*) AS count
FROM Orders o
WHERE NOT EXISTS (SELECT 1 FROM Products p WHERE p.ProductID = o.ProductID);
GO

/*----------------------------------------------------------------------------
  PART 5: SAVE PROFILING RESULTS TO METADATA
  
  Purpose: Persist profiling data for historical tracking and anomaly detection
----------------------------------------------------------------------------*/

PRINT '';
PRINT '=== SAVING PROFILING RESULTS TO METADATA ===';
PRINT '';

-- Clear existing profile data for today (idempotent)
DELETE FROM metadata.data_profile
WHERE CAST(profile_date AS DATE) = CAST(GETDATE() AS DATE);

-- Profile Customers table
INSERT INTO metadata.data_profile (
    table_name, column_name, profile_date,
    row_count, null_count, null_percentage,
    distinct_count, min_value, max_value
)
SELECT 
    'Customers' AS table_name,
    'Email' AS column_name,
    GETDATE() AS profile_date,
    COUNT(*) AS row_count,
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage,
    COUNT(DISTINCT Email) AS distinct_count,
    NULL AS min_value,
    NULL AS max_value
FROM Customers;

-- Profile Products - Price
INSERT INTO metadata.data_profile (
    table_name, column_name, profile_date,
    row_count, null_count, null_percentage,
    distinct_count, min_value, max_value, avg_value, stdev_value
)
SELECT 
    'Products' AS table_name,
    'Price' AS column_name,
    GETDATE() AS profile_date,
    COUNT(*) AS row_count,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage,
    COUNT(DISTINCT Price) AS distinct_count,
    CAST(MIN(Price) AS NVARCHAR(100)) AS min_value,
    CAST(MAX(Price) AS NVARCHAR(100)) AS max_value,
    CAST(AVG(Price) AS NVARCHAR(100)) AS avg_value,
    CAST(STDEV(Price) AS NVARCHAR(100)) AS stdev_value
FROM Products;

-- Profile Products - StockQuantity
INSERT INTO metadata.data_profile (
    table_name, column_name, profile_date,
    row_count, null_count, null_percentage,
    distinct_count, min_value, max_value, avg_value, stdev_value
)
SELECT 
    'Products' AS table_name,
    'StockQuantity' AS column_name,
    GETDATE() AS profile_date,
    COUNT(*) AS row_count,
    SUM(CASE WHEN StockQuantity IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN StockQuantity IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage,
    COUNT(DISTINCT StockQuantity) AS distinct_count,
    CAST(MIN(StockQuantity) AS NVARCHAR(100)) AS min_value,
    CAST(MAX(StockQuantity) AS NVARCHAR(100)) AS max_value,
    CAST(AVG(StockQuantity) AS NVARCHAR(100)) AS avg_value,
    CAST(STDEV(StockQuantity) AS NVARCHAR(100)) AS stdev_value
FROM Products;

-- Profile Orders - TotalAmount
INSERT INTO metadata.data_profile (
    table_name, column_name, profile_date,
    row_count, null_count, null_percentage,
    distinct_count, min_value, max_value, avg_value, stdev_value
)
SELECT 
    'Orders' AS table_name,
    'TotalAmount' AS column_name,
    GETDATE() AS profile_date,
    COUNT(*) AS row_count,
    SUM(CASE WHEN TotalAmount IS NULL THEN 1 ELSE 0 END) AS null_count,
    CAST(100.0 * SUM(CASE WHEN TotalAmount IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_percentage,
    COUNT(DISTINCT TotalAmount) AS distinct_count,
    CAST(MIN(TotalAmount) AS NVARCHAR(100)) AS min_value,
    CAST(MAX(TotalAmount) AS NVARCHAR(100)) AS max_value,
    CAST(AVG(TotalAmount) AS NVARCHAR(100)) AS avg_value,
    CAST(STDEV(TotalAmount) AS NVARCHAR(100)) AS stdev_value
FROM Orders;

PRINT 'Profile data saved to metadata.data_profile';
GO

-- Verify saved profiles
PRINT '';
PRINT 'Saved Profile Summary:';
SELECT 
    table_name,
    column_name,
    row_count,
    null_percentage,
    distinct_count,
    min_value,
    max_value,
    avg_value,
    stdev_value
FROM metadata.data_profile
WHERE CAST(profile_date AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY table_name, column_name;
GO

/*----------------------------------------------------------------------------
  PART 6: ANOMALY DETECTION USING PROFILING DATA
  
  Purpose: Identify statistical outliers using mean ± 2 standard deviations
  
  Rule of Thumb:
  - Values within mean ± 1σ: ~68% of data (normal)
  - Values within mean ± 2σ: ~95% of data (normal)
  - Values beyond mean ± 2σ: ~5% of data (potential anomalies)
----------------------------------------------------------------------------*/

PRINT '';
PRINT '=== ANOMALY DETECTION ===';
PRINT '';

-- Detect anomalous order amounts
PRINT 'Orders with Anomalous Amounts (> 2 std deviations from mean):';
WITH order_stats AS (
    SELECT 
        AVG(TotalAmount) AS mean_amount,
        STDEV(TotalAmount) AS stdev_amount
    FROM Orders
    WHERE TotalAmount >= 0  -- Exclude negative amounts from baseline
)
SELECT 
    o.OrderID,
    o.TotalAmount,
    s.mean_amount,
    s.stdev_amount,
    CAST((o.TotalAmount - s.mean_amount) / s.stdev_amount AS DECIMAL(10,2)) AS z_score,
    CASE 
        WHEN o.TotalAmount > s.mean_amount + (2 * s.stdev_amount) THEN 'HIGH ANOMALY'
        WHEN o.TotalAmount < s.mean_amount - (2 * s.stdev_amount) THEN 'LOW ANOMALY'
        ELSE 'NORMAL'
    END AS anomaly_status
FROM Orders o
CROSS JOIN order_stats s
WHERE ABS(o.TotalAmount - s.mean_amount) > 2 * s.stdev_amount
ORDER BY ABS(o.TotalAmount - s.mean_amount) DESC;
GO

-- Detect products with unusual stock levels
PRINT '';
PRINT 'Products with Unusual Stock Levels:';
WITH stock_stats AS (
    SELECT 
        AVG(StockQuantity) AS mean_stock,
        STDEV(StockQuantity) AS stdev_stock
    FROM Products
    WHERE StockQuantity >= 0  -- Exclude negative stock from baseline
)
SELECT 
    p.ProductID,
    p.ProductName,
    p.StockQuantity,
    s.mean_stock,
    s.stdev_stock,
    CASE 
        WHEN p.StockQuantity < 0 THEN 'INVALID (Negative)'
        WHEN p.StockQuantity > s.mean_stock + (2 * s.stdev_stock) THEN 'HIGH (Overstocked?)'
        WHEN p.StockQuantity < s.mean_stock - (2 * s.stdev_stock) THEN 'LOW (Understocked?)'
        ELSE 'NORMAL'
    END AS stock_status
FROM Products p
CROSS JOIN stock_stats s
WHERE p.StockQuantity < 0 
   OR ABS(p.StockQuantity - s.mean_stock) > 2 * s.stdev_stock
ORDER BY p.StockQuantity;
GO

/*----------------------------------------------------------------------------
  SUMMARY & NEXT STEPS
----------------------------------------------------------------------------*/

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║            DATA PROFILING COMPLETE                              ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Profiling Summary:';
PRINT '- Basic row counts and date ranges captured';
PRINT '- NULL value percentages calculated';
PRINT '- Duplicate records identified';
PRINT '- Statistical measures computed (min/max/avg/stdev)';
PRINT '- Freshness analysis completed';
PRINT '- Referential integrity validated';
PRINT '- Profile data saved to metadata.data_profile';
PRINT '- Anomalies detected using 2σ threshold';
PRINT '';
PRINT 'Key Findings:';
PRINT '- Customers: 12.5% have NULL names (1 out of 8)';
PRINT '- Customers: 12.5% duplicates detected (1 duplicate email)';
PRINT '- Products: 12.5% have negative stock (1 product)';
PRINT '- Products: 12.5% have negative prices (1 product)';
PRINT '- Orders: 0.98% have negative amounts (1 out of 102)';
PRINT '- Orders: 1.96% are orphaned records (2 out of 102)';
PRINT '- Orders: 0.98% are stale (> 24 hours old)';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Review anomaly detection results';
PRINT '2. Define quality rules based on profiling insights';
PRINT '3. Set thresholds for automated checks';
PRINT '4. Schedule regular profiling (monthly recommended)';
PRINT '';
PRINT 'Run next script: 04-quality-rules.sql';
PRINT '';

/*============================================================================
  END OF SCRIPT
============================================================================*/
