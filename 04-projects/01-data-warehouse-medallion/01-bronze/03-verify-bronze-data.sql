-- ========================================
-- Verify Bronze Layer Data Quality
-- ========================================
-- Purpose: Analyze the messy data we loaded to understand quality issues
-- This helps us plan what to fix in the Silver layer
-- ========================================

USE TechStore_Warehouse;
GO

PRINT '========================================';
PRINT 'BRONZE LAYER DATA QUALITY ANALYSIS';
PRINT '========================================';
PRINT '';

-- ========================================
-- 1. Record Counts
-- ========================================
PRINT '1. RECORD COUNTS';
PRINT '----------------------------------------';

SELECT 
    'bronze.customers' AS table_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_count
FROM bronze.customers
UNION ALL
SELECT 
    'bronze.inventory',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id)
FROM bronze.inventory
UNION ALL
SELECT 
    'bronze.orders',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id)
FROM bronze.orders;
GO

PRINT '';
PRINT '2. CUSTOMER DATA QUALITY ISSUES';
PRINT '----------------------------------------';

-- Missing/Empty Values
SELECT 
    'Missing Customer IDs' AS issue_type,
    COUNT(*) AS record_count
FROM bronze.customers
WHERE customer_id IS NULL OR customer_id = ''
UNION ALL
SELECT 
    'Invalid Emails (NULL)',
    COUNT(*)
FROM bronze.customers
WHERE email IS NULL
UNION ALL
SELECT 
    'Invalid Emails (missing @)',
    COUNT(*)
FROM bronze.customers
WHERE email NOT LIKE '%@%' AND email IS NOT NULL
UNION ALL
SELECT 
    'Missing Phone Numbers',
    COUNT(*)
FROM bronze.customers
WHERE phone IS NULL OR phone = ''
UNION ALL
SELECT 
    'Empty Customer Tier',
    COUNT(*)
FROM bronze.customers
WHERE customer_tier = '' OR customer_tier IS NULL
UNION ALL
SELECT 
    'Duplicate Records',
    COUNT(*) - COUNT(DISTINCT customer_id)
FROM bronze.customers;
GO

-- Name Format Variations
PRINT '';
PRINT 'Customer Name Format Analysis:';
SELECT 
    CASE 
        WHEN full_name LIKE '%, %' THEN 'Last, First format'
        WHEN full_name LIKE '% %' THEN 'First Last format'
        ELSE 'Single name only'
    END AS name_format,
    COUNT(*) AS count
FROM bronze.customers
GROUP BY 
    CASE 
        WHEN full_name LIKE '%, %' THEN 'Last, First format'
        WHEN full_name LIKE '% %' THEN 'First Last format'
        ELSE 'Single name only'
    END
ORDER BY count DESC;
GO

PRINT '';
PRINT '3. INVENTORY DATA QUALITY ISSUES';
PRINT '----------------------------------------';

SELECT 
    'Products with $ in price' AS issue_type,
    COUNT(*) AS record_count
FROM bronze.inventory
WHERE sell_price LIKE '%$%'
UNION ALL
SELECT 
    'Products with comma in price',
    COUNT(*)
FROM bronze.inventory
WHERE cost_price LIKE '%,%'
UNION ALL
SELECT 
    'Negative Stock Quantity',
    COUNT(*)
FROM bronze.inventory
WHERE TRY_CAST(stock_quantity AS INT) < 0
UNION ALL
SELECT 
    'Non-numeric Stock Quantity',
    COUNT(*)
FROM bronze.inventory
WHERE stock_quantity NOT LIKE '%[0-9]%' OR stock_quantity LIKE '%[^0-9-]%'
UNION ALL
SELECT 
    'Empty is_active Flag',
    COUNT(*)
FROM bronze.inventory
WHERE is_active = '' OR is_active IS NULL;
GO

-- is_active variations
PRINT '';
PRINT 'is_active Value Variations:';
SELECT 
    is_active,
    COUNT(*) AS count
FROM bronze.inventory
GROUP BY is_active
ORDER BY count DESC;
GO

PRINT '';
PRINT '4. ORDER DATA QUALITY ISSUES';
PRINT '----------------------------------------';

SELECT 
    'Orders with Missing Customer ID' AS issue_type,
    COUNT(*) AS record_count
FROM bronze.orders
WHERE customer_id IS NULL OR customer_id = ''
UNION ALL
SELECT 
    'Orders with $ in Amount',
    COUNT(*)
FROM bronze.orders
WHERE total_amount LIKE '%$%'
UNION ALL
SELECT 
    'Orders with Negative Quantity',
    COUNT(*)
FROM bronze.orders
WHERE TRY_CAST(quantity AS INT) < 0
UNION ALL
SELECT 
    'Orders with Non-numeric Quantity',
    COUNT(*)
FROM bronze.orders
WHERE quantity LIKE '%[^0-9-]%'
UNION ALL
SELECT 
    'Orders with Invalid Dates',
    COUNT(*)
FROM bronze.orders
WHERE TRY_CAST(order_date AS DATE) IS NULL;
GO

-- Date format variations
PRINT '';
PRINT 'Order Date Format Variations (sample):';
SELECT TOP 20
    order_date,
    COUNT(*) AS count,
    CASE 
        WHEN order_date LIKE '____-__-__' THEN 'YYYY-MM-DD'
        WHEN order_date LIKE '__/__/____' AND CHARINDEX('/', order_date, 1) = 3 THEN 'MM/DD/YYYY'
        WHEN order_date LIKE '__/__/____' AND CHARINDEX('/', order_date, 1) = 3 THEN 'DD/MM/YYYY'
        WHEN order_date LIKE '____-__-__ __:__:__' THEN 'YYYY-MM-DD HH:MM:SS'
        ELSE 'Unknown/Invalid'
    END AS likely_format
FROM bronze.orders
GROUP BY order_date
ORDER BY count DESC;
GO

PRINT '';
PRINT '5. CROSS-TABLE REFERENTIAL INTEGRITY';
PRINT '----------------------------------------';

-- Orphaned orders (customer doesn't exist)
SELECT 
    'Orders with Invalid Customer ID' AS issue_type,
    COUNT(*) AS record_count
FROM bronze.orders o
WHERE o.customer_id IS NOT NULL 
  AND o.customer_id <> ''
  AND NOT EXISTS (
      SELECT 1 FROM bronze.customers c 
      WHERE c.customer_id = o.customer_id
  );
GO

-- Orphaned orders (product doesn't exist)
SELECT 
    'Orders with Invalid Product ID' AS issue_type,
    COUNT(*) AS record_count
FROM bronze.orders o
WHERE o.product_id IS NOT NULL 
  AND NOT EXISTS (
      SELECT 1 FROM bronze.inventory i 
      WHERE i.product_id = o.product_id
  );
GO

PRINT '';
PRINT '6. DATA FRESHNESS';
PRINT '----------------------------------------';

SELECT 
    'bronze.customers' AS table_name,
    MIN(bronze_loaded_at) AS first_load,
    MAX(bronze_loaded_at) AS last_load,
    COUNT(*) AS total_records
FROM bronze.customers
UNION ALL
SELECT 
    'bronze.inventory',
    MIN(bronze_loaded_at),
    MAX(bronze_loaded_at),
    COUNT(*)
FROM bronze.inventory
UNION ALL
SELECT 
    'bronze.orders',
    MIN(bronze_loaded_at),
    MAX(bronze_loaded_at),
    COUNT(*)
FROM bronze.orders;
GO

PRINT '';
PRINT '========================================';
PRINT 'SUMMARY OF DATA QUALITY ISSUES';
PRINT '========================================';
PRINT '';
PRINT 'Issues Found:';
PRINT '✗ Duplicate customer records';
PRINT '✗ Missing customer IDs in orders';
PRINT '✗ Invalid email formats';
PRINT '✗ Inconsistent date formats (YYYY-MM-DD, MM/DD/YYYY, etc.)';
PRINT '✗ Currency symbols in numeric fields ($99.99)';
PRINT '✗ Negative quantities (oversold products)';
PRINT '✗ Non-numeric values in quantity fields (N/A)';
PRINT '✗ Multiple formats for boolean flags (true/false/1/0/yes/no)';
PRINT '✗ Orphaned records (orders without valid customers/products)';
PRINT '';
PRINT 'Next Steps:';
PRINT '→ Move to Silver layer (02-silver/)';
PRINT '→ Clean and standardize all data';
PRINT '→ Convert to proper data types';
PRINT '→ Handle duplicates and missing values';
PRINT '========================================';
GO
