-- ============================================================================
-- Create Customer Dimension (dim_customer)
-- ============================================================================
-- Customer demographics and segmentation attributes
-- SCD Type 1 (overwrite for most changes) + Type 2 for loyalty tier changes
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- STEP 1: Create dim_customer Table
-- ============================================================================

DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer (
    -- Surrogate Key
    customer_key INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key',
    
    -- Natural Key
    customer_id VARCHAR(20) NOT NULL UNIQUE COMMENT 'Customer ID from source system',
    
    -- Customer Identification
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    email VARCHAR(200),
    phone VARCHAR(20),
    
    -- Demographics
    date_of_birth DATE,
    age_range VARCHAR(20) COMMENT '18-24, 25-34, 35-44, 45-54, 55-64, 65+',
    gender VARCHAR(20) COMMENT 'Male, Female, Other, Prefer not to say',
    marital_status VARCHAR(20) COMMENT 'Single, Married, Divorced, Widowed',
    
    -- Location
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(100),
    state_province VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    region VARCHAR(50) COMMENT 'Customer region (West, East, etc.)',
    
    -- Customer Segmentation
    customer_segment VARCHAR(50) COMMENT 'VIP, Regular, Occasional, New',
    loyalty_tier VARCHAR(50) COMMENT 'Platinum, Gold, Silver, Bronze',
    loyalty_points INT DEFAULT 0,
    
    -- Household Information
    household_income_range VARCHAR(50) COMMENT '<25K, 25-50K, 50-75K, 75-100K, 100K+',
    household_size TINYINT,
    has_children BOOLEAN,
    
    -- Preferences
    preferred_contact_method VARCHAR(50) COMMENT 'Email, Phone, SMS, Mail',
    email_opt_in BOOLEAN DEFAULT FALSE,
    sms_opt_in BOOLEAN DEFAULT FALSE,
    
    -- Important Dates
    first_purchase_date DATE COMMENT 'Date of first purchase',
    last_purchase_date DATE COMMENT 'Date of most recent purchase',
    registration_date DATE COMMENT 'Account creation date',
    
    -- Customer Metrics (Updated by ETL processes)
    total_lifetime_value DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Total amount spent all-time',
    total_order_count INT DEFAULT 0 COMMENT 'Number of orders placed',
    average_order_value DECIMAL(10,2) DEFAULT 0.00,
    days_since_last_purchase INT COMMENT 'Recency metric for RFM',
    
    -- Status Flags
    is_active BOOLEAN DEFAULT TRUE,
    is_loyalty_member BOOLEAN DEFAULT FALSE,
    account_status VARCHAR(50) DEFAULT 'Active' COMMENT 'Active, Inactive, Suspended, Closed',
    
    -- Audit Columns
    dw_insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dw_source_system VARCHAR(50) DEFAULT 'CRM_CUSTOMERS',
    
    -- Indexes
    INDEX idx_customer_id (customer_id),
    INDEX idx_email (email),
    INDEX idx_last_name (last_name),
    INDEX idx_customer_segment (customer_segment),
    INDEX idx_loyalty_tier (loyalty_tier),
    INDEX idx_postal_code (postal_code),
    INDEX idx_is_active (is_active),
    INDEX idx_registration_date (registration_date)
    
) COMMENT 'Customer dimension - demographics and segmentation';

-- ============================================================================
-- STEP 2: Insert Unknown Member
-- ============================================================================

INSERT INTO dim_customer (
    customer_key,
    customer_id,
    first_name,
    last_name,
    full_name,
    customer_segment,
    loyalty_tier,
    account_status
)
VALUES (
    -1,
    'UNKNOWN',
    'Unknown',
    'Customer',
    'Unknown Customer',
    'Unknown',
    'None',
    'Unknown'
);

-- ============================================================================
-- STEP 3: Generate 10,000 Customers
-- ============================================================================

-- Create temporary name tables
DROP TEMPORARY TABLE IF EXISTS temp_first_names;
CREATE TEMPORARY TABLE temp_first_names (first_name VARCHAR(100));

INSERT INTO temp_first_names VALUES
('James'), ('Mary'), ('John'), ('Patricia'), ('Robert'), ('Jennifer'), ('Michael'), ('Linda'),
('William'), ('Barbara'), ('David'), ('Elizabeth'), ('Richard'), ('Susan'), ('Joseph'), ('Jessica'),
('Thomas'), ('Sarah'), ('Christopher'), ('Karen'), ('Charles'), ('Nancy'), ('Daniel'), ('Lisa'),
('Matthew'), ('Betty'), ('Anthony'), ('Margaret'), ('Mark'), ('Sandra'), ('Donald'), ('Ashley'),
('Steven'), ('Kimberly'), ('Andrew'), ('Emily'), ('Paul'), ('Donna'), ('Joshua'), ('Michelle'),
('Kenneth'), ('Carol'), ('Kevin'), ('Amanda'), ('Brian'), ('Dorothy'), ('George'), ('Melissa'),
('Timothy'), ('Deborah');

DROP TEMPORARY TABLE IF EXISTS temp_last_names;
CREATE TEMPORARY TABLE temp_last_names (last_name VARCHAR(100));

INSERT INTO temp_last_names VALUES
('Smith'), ('Johnson'), ('Williams'), ('Brown'), ('Jones'), ('Garcia'), ('Miller'), ('Davis'),
('Rodriguez'), ('Martinez'), ('Hernandez'), ('Lopez'), ('Gonzalez'), ('Wilson'), ('Anderson'), ('Thomas'),
('Taylor'), ('Moore'), ('Jackson'), ('Martin'), ('Lee'), ('Perez'), ('Thompson'), ('White'),
('Harris'), ('Sanchez'), ('Clark'), ('Ramirez'), ('Lewis'), ('Robinson'), ('Walker'), ('Young'),
('Allen'), ('King'), ('Wright'), ('Scott'), ('Torres'), ('Nguyen'), ('Hill'), ('Flores'),
('Green'), ('Adams'), ('Nelson'), ('Baker'), ('Hall'), ('Rivera'), ('Campbell'), ('Mitchell'),
('Carter'), ('Roberts');

-- Generate 10,000 customers
INSERT INTO dim_customer (
    customer_id,
    first_name,
    last_name,
    full_name,
    email,
    phone,
    date_of_birth,
    age_range,
    gender,
    marital_status,
    address_line1,
    city,
    state_province,
    postal_code,
    country,
    region,
    customer_segment,
    loyalty_tier,
    loyalty_points,
    household_income_range,
    household_size,
    has_children,
    preferred_contact_method,
    email_opt_in,
    sms_opt_in,
    registration_date,
    first_purchase_date,
    is_active,
    is_loyalty_member,
    account_status
)
SELECT 
    CONCAT('CUST-', LPAD(nums.n, 8, '0')) AS customer_id,
    fn.first_name,
    ln.last_name,
    CONCAT(fn.first_name, ' ', ln.last_name) AS full_name,
    LOWER(CONCAT(fn.first_name, '.', ln.last_name, nums.n, '@email.com')) AS email,
    CONCAT('555-', LPAD(FLOOR(100 + RAND() * 900), 3, '0'), '-', LPAD(FLOOR(1000 + RAND() * 9000), 4, '0')) AS phone,
    -- Birth date (ages 18-80)
    DATE_ADD('1945-01-01', INTERVAL FLOOR(RAND() * 23725) DAY) AS date_of_birth,
    -- Age range
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, DATE_ADD('1945-01-01', INTERVAL FLOOR(RAND() * 23725) DAY), CURDATE()) BETWEEN 18 AND 24 THEN '18-24'
        WHEN TIMESTAMPDIFF(YEAR, DATE_ADD('1945-01-01', INTERVAL FLOOR(RAND() * 23725) DAY), CURDATE()) BETWEEN 25 AND 34 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, DATE_ADD('1945-01-01', INTERVAL FLOOR(RAND() * 23725) DAY), CURDATE()) BETWEEN 35 AND 44 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, DATE_ADD('1945-01-01', INTERVAL FLOOR(RAND() * 23725) DAY), CURDATE()) BETWEEN 45 AND 54 THEN '45-54'
        WHEN TIMESTAMPDIFF(YEAR, DATE_ADD('1945-01-01', INTERVAL FLOOR(RAND() * 23725) DAY), CURDATE()) BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_range,
    -- Gender
    CASE FLOOR(RAND() * 10)
        WHEN 0 THEN 'Other'
        WHEN 1 THEN 'Prefer not to say'
        WHEN 2 THEN 'Female'
        WHEN 3 THEN 'Female'
        WHEN 4 THEN 'Female'
        WHEN 5 THEN 'Female'
        ELSE 'Male'
    END AS gender,
    -- Marital status
    CASE FLOOR(RAND() * 4)
        WHEN 0 THEN 'Single'
        WHEN 1 THEN 'Married'
        WHEN 2 THEN 'Divorced'
        ELSE 'Widowed'
    END AS marital_status,
    -- Address
    CONCAT(FLOOR(100 + RAND() * 9900), ' Main Street') AS address_line1,
    CONCAT('City-', FLOOR(1 + RAND() * 100)) AS city,
    CASE FLOOR(RAND() * 10)
        WHEN 0 THEN 'California'
        WHEN 1 THEN 'Texas'
        WHEN 2 THEN 'Florida'
        WHEN 3 THEN 'New York'
        WHEN 4 THEN 'Pennsylvania'
        WHEN 5 THEN 'Illinois'
        WHEN 6 THEN 'Ohio'
        WHEN 7 THEN 'Georgia'
        WHEN 8 THEN 'North Carolina'
        ELSE 'Washington'
    END AS state_province,
    LPAD(FLOOR(10000 + RAND() * 90000), 5, '0') AS postal_code,
    'USA' AS country,
    CASE FLOOR(RAND() * 4)
        WHEN 0 THEN 'West'
        WHEN 1 THEN 'East'
        WHEN 2 THEN 'Central'
        ELSE 'South'
    END AS region,
    -- Customer segment (based on purchase history - will be updated by ETL)
    CASE FLOOR(RAND() * 10)
        WHEN 0 THEN 'VIP'
        WHEN 1 THEN 'VIP'
        WHEN 2 THEN 'Regular'
        WHEN 3 THEN 'Regular'
        WHEN 4 THEN 'Regular'
        WHEN 5 THEN 'Regular'
        WHEN 6 THEN 'Occasional'
        WHEN 7 THEN 'Occasional'
        WHEN 8 THEN 'Occasional'
        ELSE 'New'
    END AS customer_segment,
    -- Loyalty tier
    CASE FLOOR(RAND() * 10)
        WHEN 0 THEN 'Platinum'
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Silver'
        WHEN 5 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier,
    -- Loyalty points
    FLOOR(RAND() * 10000) AS loyalty_points,
    -- Income range
    CASE FLOOR(RAND() * 5)
        WHEN 0 THEN '<25K'
        WHEN 1 THEN '25-50K'
        WHEN 2 THEN '50-75K'
        WHEN 3 THEN '75-100K'
        ELSE '100K+'
    END AS household_income_range,
    -- Household size
    FLOOR(1 + RAND() * 6) AS household_size,
    -- Has children
    RAND() > 0.6 AS has_children,
    -- Contact preferences
    CASE FLOOR(RAND() * 4)
        WHEN 0 THEN 'Email'
        WHEN 1 THEN 'Phone'
        WHEN 2 THEN 'SMS'
        ELSE 'Mail'
    END AS preferred_contact_method,
    RAND() > 0.3 AS email_opt_in,
    RAND() > 0.6 AS sms_opt_in,
    -- Registration date (2018-2024)
    DATE_ADD('2018-01-01', INTERVAL FLOOR(RAND() * 2555) DAY) AS registration_date,
    -- First purchase (within 30 days of registration)
    DATE_ADD(DATE_ADD('2018-01-01', INTERVAL FLOOR(RAND() * 2555) DAY), INTERVAL FLOOR(RAND() * 30) DAY) AS first_purchase_date,
    -- Active (95% active)
    RAND() > 0.05 AS is_active,
    -- Loyalty member (70%)
    RAND() > 0.3 AS is_loyalty_member,
    -- Account status
    CASE 
        WHEN RAND() > 0.95 THEN 'Inactive'
        WHEN RAND() > 0.99 THEN 'Suspended'
        ELSE 'Active'
    END AS account_status
FROM (
    SELECT @row6 := @row6 + 1 AS n
    FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t4,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t5,
         (SELECT @row6 := 0) r
    LIMIT 10000
) nums
CROSS JOIN (SELECT first_name FROM temp_first_names ORDER BY RAND() LIMIT 1) fn
CROSS JOIN (SELECT last_name FROM temp_last_names ORDER BY RAND() LIMIT 1) ln;

-- Log ETL
INSERT INTO metadata_etl_log (table_name, process_name, start_time, end_time, rows_inserted, status)
VALUES ('dim_customer', 'initial_load', NOW(), NOW(), (SELECT COUNT(*) - 1 FROM dim_customer), 'success');

-- ============================================================================
-- STEP 4: Verification Queries
-- ============================================================================

-- Customer segments
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dim_customer WHERE customer_key != -1), 2) AS percentage
FROM dim_customer
WHERE customer_key != -1
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- Loyalty tiers
SELECT 
    loyalty_tier,
    COUNT(*) AS customer_count,
    SUM(CASE WHEN is_loyalty_member THEN 1 ELSE 0 END) AS loyalty_members,
    ROUND(AVG(loyalty_points), 0) AS avg_points
FROM dim_customer
WHERE customer_key != -1
GROUP BY loyalty_tier
ORDER BY customer_count DESC;

-- Demographics
SELECT 
    age_range,
    gender,
    COUNT(*) AS customer_count
FROM dim_customer
WHERE customer_key != -1
GROUP BY age_range, gender
ORDER BY age_range, gender;

-- Regional distribution
SELECT 
    region,
    COUNT(*) AS customer_count,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_customers
FROM dim_customer
WHERE customer_key != -1
GROUP BY region
ORDER BY customer_count DESC;

-- Sample records
SELECT 
    customer_id,
    full_name,
    age_range,
    customer_segment,
    loyalty_tier,
    region,
    registration_date
FROM dim_customer
WHERE customer_key != -1
LIMIT 20;

/*
============================================================================
DIM_CUSTOMER COMPLETE!
============================================================================

✅ 10,000 customers + 1 unknown member
✅ Demographics (age, gender, location, income)
✅ Segmentation (VIP, Regular, Occasional, New)
✅ Loyalty program (Platinum, Gold, Silver, Bronze)
✅ Contact preferences and opt-ins
✅ Ready for RFM analysis and customer analytics

Next: 06-create-fact-sales.sql (THE FACT TABLE!)
============================================================================
*/
