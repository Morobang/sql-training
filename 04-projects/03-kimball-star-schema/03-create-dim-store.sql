-- ============================================================================
-- Create Store Dimension (dim_store)
-- ============================================================================
-- Store locations, regions, formats, and operational attributes
-- SCD Type 1: Overwrite changes (store manager, phone, etc.)
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- STEP 1: Create dim_store Table
-- ============================================================================

DROP TABLE IF EXISTS dim_store;

CREATE TABLE dim_store (
    -- Surrogate Key
    store_key INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key',
    
    -- Natural Key (from source system)
    store_id VARCHAR(20) NOT NULL UNIQUE COMMENT 'Store ID from source system',
    
    -- Store Identification
    store_name VARCHAR(100) NOT NULL COMMENT 'Store name (RetailChain Downtown Seattle)',
    store_number VARCHAR(20) COMMENT 'Store number/code',
    store_format VARCHAR(50) COMMENT 'Superstore, Standard, Express, Outlet',
    
    -- Location Attributes
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(100),
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    
    -- Geographic Hierarchy (IMPORTANT for roll-up reporting)
    region VARCHAR(50) COMMENT 'West, East, Central, South',
    district VARCHAR(50) COMMENT 'Pacific Northwest, Northeast, etc.',
    market VARCHAR(50) COMMENT 'Seattle Metro, Boston Metro, etc.',
    
    -- Store Characteristics
    square_footage INT COMMENT 'Total square footage',
    department_count TINYINT COMMENT 'Number of departments',
    has_pharmacy BOOLEAN DEFAULT FALSE,
    has_electronics BOOLEAN DEFAULT FALSE,
    has_grocery BOOLEAN DEFAULT FALSE,
    has_auto_center BOOLEAN DEFAULT FALSE,
    
    -- Operational Attributes
    store_manager VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    
    -- Status Flags
    is_active BOOLEAN DEFAULT TRUE COMMENT 'FALSE if store closed',
    
    -- Important Dates
    open_date DATE COMMENT 'Store opening date',
    close_date DATE COMMENT 'Store closing date (if applicable)',
    last_remodel_date DATE,
    
    -- Audit Columns
    dw_insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dw_source_system VARCHAR(50) DEFAULT 'ERP_STORES',
    
    -- Indexes
    INDEX idx_store_id (store_id),
    INDEX idx_region (region),
    INDEX idx_district (district),
    INDEX idx_city_state (city, state_province),
    INDEX idx_is_active (is_active)
    
) COMMENT 'Store dimension - SCD Type 1 (overwrite changes)';

-- ============================================================================
-- STEP 2: Insert Unknown Member (Default Row for Missing Data)
-- ============================================================================

INSERT INTO dim_store (
    store_key,
    store_id,
    store_name,
    store_format,
    city,
    state_province,
    country,
    region,
    district,
    market,
    is_active
)
VALUES (
    -1,
    'UNKNOWN',
    'Unknown Store',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    FALSE
);

-- ============================================================================
-- STEP 3: Load Sample Store Data (500 stores)
-- ============================================================================

-- Create temporary table for store data generation
DROP TEMPORARY TABLE IF EXISTS temp_store_generator;

CREATE TEMPORARY TABLE temp_store_generator (
    id INT AUTO_INCREMENT PRIMARY KEY,
    store_format VARCHAR(50),
    region VARCHAR(50),
    state VARCHAR(50),
    city VARCHAR(100)
);

-- Insert store configurations (500 stores across US)
-- West Region (150 stores)
INSERT INTO temp_store_generator (store_format, region, state, city)
SELECT 
    CASE 
        WHEN n <= 60 THEN 'Superstore'
        WHEN n <= 110 THEN 'Standard'
        WHEN n <= 140 THEN 'Express'
        ELSE 'Outlet'
    END AS store_format,
    'West' AS region,
    CASE 
        WHEN n % 5 = 0 THEN 'California'
        WHEN n % 5 = 1 THEN 'Washington'
        WHEN n % 5 = 2 THEN 'Oregon'
        WHEN n % 5 = 3 THEN 'Nevada'
        ELSE 'Arizona'
    END AS state,
    CASE 
        WHEN n % 5 = 0 THEN CONCAT('CA City ', n)
        WHEN n % 5 = 1 THEN CONCAT('Seattle Area ', n)
        WHEN n % 5 = 2 THEN CONCAT('Portland Area ', n)
        WHEN n % 5 = 3 THEN CONCAT('Las Vegas Area ', n)
        ELSE CONCAT('Phoenix Area ', n)
    END AS city
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
         (SELECT @row := 0) r
    LIMIT 150
) nums;

-- East Region (150 stores)
INSERT INTO temp_store_generator (store_format, region, state, city)
SELECT 
    CASE 
        WHEN n <= 60 THEN 'Superstore'
        WHEN n <= 110 THEN 'Standard'
        WHEN n <= 140 THEN 'Express'
        ELSE 'Outlet'
    END AS store_format,
    'East' AS region,
    CASE 
        WHEN n % 5 = 0 THEN 'New York'
        WHEN n % 5 = 1 THEN 'Massachusetts'
        WHEN n % 5 = 2 THEN 'Pennsylvania'
        WHEN n % 5 = 3 THEN 'New Jersey'
        ELSE 'Florida'
    END AS state,
    CASE 
        WHEN n % 5 = 0 THEN CONCAT('NYC Area ', n)
        WHEN n % 5 = 1 THEN CONCAT('Boston Area ', n)
        WHEN n % 5 = 2 THEN CONCAT('Philadelphia Area ', n)
        WHEN n % 5 = 3 THEN CONCAT('Newark Area ', n)
        ELSE CONCAT('Miami Area ', n)
    END AS city
FROM (
    SELECT @row2 := @row2 + 1 AS n
    FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
         (SELECT @row2 := 0) r
    LIMIT 150
) nums;

-- Central Region (100 stores)
INSERT INTO temp_store_generator (store_format, region, state, city)
SELECT 
    CASE 
        WHEN n <= 40 THEN 'Superstore'
        WHEN n <= 75 THEN 'Standard'
        WHEN n <= 90 THEN 'Express'
        ELSE 'Outlet'
    END AS store_format,
    'Central' AS region,
    CASE 
        WHEN n % 4 = 0 THEN 'Illinois'
        WHEN n % 4 = 1 THEN 'Texas'
        WHEN n % 4 = 2 THEN 'Ohio'
        ELSE 'Michigan'
    END AS state,
    CASE 
        WHEN n % 4 = 0 THEN CONCAT('Chicago Area ', n)
        WHEN n % 4 = 1 THEN CONCAT('Dallas Area ', n)
        WHEN n % 4 = 2 THEN CONCAT('Columbus Area ', n)
        ELSE CONCAT('Detroit Area ', n)
    END AS city
FROM (
    SELECT @row3 := @row3 + 1 AS n
    FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
         (SELECT @row3 := 0) r
    LIMIT 100
) nums;

-- South Region (100 stores)
INSERT INTO temp_store_generator (store_format, region, state, city)
SELECT 
    CASE 
        WHEN n <= 40 THEN 'Superstore'
        WHEN n <= 75 THEN 'Standard'
        WHEN n <= 90 THEN 'Express'
        ELSE 'Outlet'
    END AS store_format,
    'South' AS region,
    CASE 
        WHEN n % 4 = 0 THEN 'Georgia'
        WHEN n % 4 = 1 THEN 'North Carolina'
        WHEN n % 4 = 2 THEN 'Tennessee'
        ELSE 'Louisiana'
    END AS state,
    CASE 
        WHEN n % 4 = 0 THEN CONCAT('Atlanta Area ', n)
        WHEN n % 4 = 1 THEN CONCAT('Charlotte Area ', n)
        WHEN n % 4 = 2 THEN CONCAT('Nashville Area ', n)
        ELSE CONCAT('New Orleans Area ', n)
    END AS city
FROM (
    SELECT @row4 := @row4 + 1 AS n
    FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
         (SELECT @row4 := 0) r
    LIMIT 100
) nums;

-- ============================================================================
-- STEP 4: Populate dim_store from temp table
-- ============================================================================

INSERT INTO dim_store (
    store_id,
    store_name,
    store_number,
    store_format,
    address_line1,
    city,
    state_province,
    postal_code,
    country,
    region,
    district,
    market,
    square_footage,
    department_count,
    has_pharmacy,
    has_electronics,
    has_grocery,
    has_auto_center,
    store_manager,
    phone_number,
    email,
    is_active,
    open_date,
    last_remodel_date
)
SELECT 
    CONCAT('STR-', LPAD(id, 5, '0')) AS store_id,
    CONCAT('RetailChain ', city) AS store_name,
    LPAD(id, 5, '0') AS store_number,
    store_format,
    CONCAT(100 + id * 10, ' Main Street') AS address_line1,
    city,
    state AS state_province,
    LPAD(FLOOR(10000 + RAND() * 90000), 5, '0') AS postal_code,
    'USA' AS country,
    region,
    -- District based on region
    CASE region
        WHEN 'West' THEN CASE 
            WHEN state IN ('California', 'Nevada') THEN 'Southwest District'
            ELSE 'Pacific Northwest District'
        END
        WHEN 'East' THEN CASE
            WHEN state IN ('New York', 'Massachusetts', 'New Jersey', 'Pennsylvania') THEN 'Northeast District'
            ELSE 'Southeast District'
        END
        WHEN 'Central' THEN 'Midwest District'
        ELSE 'Southern District'
    END AS district,
    -- Market = Major city metro area
    CONCAT(city, ' Metro') AS market,
    -- Square footage based on format
    CASE store_format
        WHEN 'Superstore' THEN FLOOR(150000 + RAND() * 50000)
        WHEN 'Standard' THEN FLOOR(80000 + RAND() * 40000)
        WHEN 'Express' THEN FLOOR(30000 + RAND() * 20000)
        ELSE FLOOR(50000 + RAND() * 30000)
    END AS square_footage,
    -- Department count based on format
    CASE store_format
        WHEN 'Superstore' THEN FLOOR(15 + RAND() * 10)
        WHEN 'Standard' THEN FLOOR(10 + RAND() * 5)
        WHEN 'Express' THEN FLOOR(5 + RAND() * 3)
        ELSE FLOOR(8 + RAND() * 4)
    END AS department_count,
    -- Features based on format
    store_format IN ('Superstore', 'Standard') AS has_pharmacy,
    TRUE AS has_electronics,
    store_format IN ('Superstore', 'Standard') AS has_grocery,
    store_format = 'Superstore' AS has_auto_center,
    -- Manager
    CONCAT('Manager-', LPAD(id, 3, '0')) AS store_manager,
    -- Phone
    CONCAT('555-', LPAD(FLOOR(100 + RAND() * 900), 3, '0'), '-', LPAD(FLOOR(1000 + RAND() * 9000), 4, '0')) AS phone_number,
    -- Email
    CONCAT('store', LPAD(id, 5, '0'), '@retailchain.com') AS email,
    -- Active (95% active, 5% closed)
    RAND() > 0.05 AS is_active,
    -- Open date (stores opened between 2015-2023)
    DATE_ADD('2015-01-01', INTERVAL FLOOR(RAND() * 3285) DAY) AS open_date,
    -- Last remodel (some stores remodeled in last 2 years)
    CASE 
        WHEN RAND() > 0.7 THEN DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND() * 730) DAY)
        ELSE NULL
    END AS last_remodel_date
FROM temp_store_generator
ORDER BY id;

-- Update close_date for inactive stores
UPDATE dim_store
SET close_date = DATE_ADD(open_date, INTERVAL FLOOR(365 + RAND() * 2555) DAY)
WHERE is_active = FALSE AND close_date IS NULL;

-- Log ETL
INSERT INTO metadata_etl_log (table_name, process_name, start_time, end_time, rows_inserted, status)
VALUES ('dim_store', 'initial_load', NOW(), NOW(), (SELECT COUNT(*) - 1 FROM dim_store), 'success');

-- ============================================================================
-- STEP 5: Verification Queries
-- ============================================================================

-- Count by format
SELECT 
    store_format,
    COUNT(*) AS store_count,
    ROUND(AVG(square_footage), 0) AS avg_sqft,
    ROUND(AVG(department_count), 1) AS avg_departments
FROM dim_store
WHERE store_key != -1
GROUP BY store_format
ORDER BY store_count DESC;

-- Count by region
SELECT 
    region,
    district,
    COUNT(*) AS store_count,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_stores,
    SUM(CASE WHEN is_active THEN 0 ELSE 1 END) AS closed_stores
FROM dim_store
WHERE store_key != -1
GROUP BY region, district
ORDER BY region, district;

-- Features summary
SELECT 
    SUM(CASE WHEN has_pharmacy THEN 1 ELSE 0 END) AS stores_with_pharmacy,
    SUM(CASE WHEN has_electronics THEN 1 ELSE 0 END) AS stores_with_electronics,
    SUM(CASE WHEN has_grocery THEN 1 ELSE 0 END) AS stores_with_grocery,
    SUM(CASE WHEN has_auto_center THEN 1 ELSE 0 END) AS stores_with_auto
FROM dim_store
WHERE store_key != -1;

-- Sample records
SELECT * FROM dim_store WHERE store_key != -1 LIMIT 10;

/*
============================================================================
DIM_STORE COMPLETE!
============================================================================

✅ 500 stores + 1 unknown member
✅ Geographic hierarchy (Region → District → Market → Store)
✅ Store formats (Superstore, Standard, Express, Outlet)
✅ Realistic attributes (square footage, departments, features)
✅ SCD Type 1 (overwrites changes)
✅ 95% active, 5% closed stores

Next: 04-create-dim-product.sql (with SCD Type 2!)
============================================================================
*/
