-- ============================================================================
-- Kimball Star Schema Project - Setup & Database Creation
-- ============================================================================
-- Project: Retail Analytics Data Warehouse
-- Pattern: Kimball Dimensional Modeling (Star Schema)
-- Business: RetailChain - 500 stores selling electronics, clothing, home goods
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Database
-- ============================================================================

DROP DATABASE IF EXISTS RetailChain_DW;
CREATE DATABASE RetailChain_DW
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE RetailChain_DW;

-- ============================================================================
-- KIMBALL METHODOLOGY OVERVIEW
-- ============================================================================

/*
KIMBALL STAR SCHEMA DESIGN PRINCIPLES:

1. FACT TABLES (Center of Star)
   - Store MEASUREMENTS (quantitative data)
   - Grain: "One row per transaction" or "One row per snapshot"
   - Contain FOREIGN KEYS to dimensions
   - Contain MEASURES (quantities, amounts, counts)
   - Examples: fact_sales, fact_inventory, fact_returns

2. DIMENSION TABLES (Points of Star)
   - Store DESCRIPTIVE ATTRIBUTES (qualitative data)
   - Used for FILTERING, GROUPING, LABELING
   - Denormalized (wide tables with many columns)
   - Examples: dim_date, dim_product, dim_customer, dim_store

3. STAR SCHEMA STRUCTURE
                    dim_date
                        |
                        |
    dim_store ----------+---------- fact_sales ----------+---------- dim_product
                        |                                 |
                        |                                 |
                   dim_customer                      dim_promotion

4. SURROGATE KEYS
   - Every dimension has a SURROGATE KEY (auto-increment integer)
   - Why? Protects against source system changes, enables SCD Type 2
   - Natural keys (product_id, customer_id) stored as attributes

5. SLOWLY CHANGING DIMENSIONS (SCD)
   - Type 0: Never changes (original value retained)
   - Type 1: Overwrite (lose history)
   - Type 2: Add new row with effective dates (track full history) ← Most common
   - Type 3: Add new column (limited history)

6. CONFORMED DIMENSIONS
   - Same dimension used by multiple fact tables
   - Example: dim_date used by fact_sales, fact_inventory, fact_returns
   - Ensures consistent reporting across business processes

7. GRAIN (Most Important Decision!)
   - Atomic grain: Lowest level of detail (recommended)
   - Example: One row per individual sale item
   - Can always aggregate up, can't drill down from summary

8. FACT TABLE TYPES
   - Transaction Fact: One row per event (fact_sales)
   - Periodic Snapshot: One row per time period (fact_inventory_daily)
   - Accumulating Snapshot: One row per process instance (fact_order_fulfillment)
*/

-- ============================================================================
-- STEP 2: Create Schema Documentation
-- ============================================================================

CREATE TABLE metadata_schema_documentation (
    schema_name VARCHAR(100) PRIMARY KEY,
    description TEXT,
    owner VARCHAR(100),
    created_date DATE,
    last_modified DATE
);

INSERT INTO metadata_schema_documentation VALUES
('RetailChain_DW', 
 'Kimball Star Schema for Retail Chain analytics. Includes sales, inventory, and customer dimensions for business intelligence reporting.',
 'Data Engineering Team',
 CURDATE(),
 CURDATE());

-- ============================================================================
-- STEP 3: Create Metadata Tables
-- ============================================================================

-- Track ETL runs
CREATE TABLE metadata_etl_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(100),
    process_name VARCHAR(100),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    rows_inserted INT,
    rows_updated INT,
    rows_deleted INT,
    status ENUM('success', 'failed', 'running'),
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Track data quality metrics
CREATE TABLE metadata_data_quality (
    quality_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(100),
    check_name VARCHAR(200),
    check_type ENUM('null_check', 'duplicate_check', 'range_check', 'referential_integrity'),
    records_checked INT,
    records_failed INT,
    check_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pass', 'fail', 'warning')
);

-- ============================================================================
-- STEP 4: Create Audit Columns (Standard for all tables)
-- ============================================================================

/*
STANDARD AUDIT COLUMNS:
- dw_insert_date: When row was first inserted into warehouse
- dw_update_date: When row was last updated
- source_system: Which system the data came from
- batch_id: ETL batch identifier

These columns are added to ALL dimension and fact tables
*/

-- ============================================================================
-- STEP 5: Business Rules & Definitions
-- ============================================================================

CREATE TABLE metadata_business_rules (
    rule_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(100),
    column_name VARCHAR(100),
    rule_description TEXT,
    rule_sql TEXT,
    created_date DATE
);

INSERT INTO metadata_business_rules (table_name, column_name, rule_description, rule_sql, created_date)
VALUES
('fact_sales', 'total_amount', 'Total must equal (quantity * unit_price) - discount + tax', 
 'total_amount = (quantity_sold * unit_price) - discount_amount + tax_amount', CURDATE()),
('fact_sales', 'quantity_sold', 'Quantity must be positive', 
 'quantity_sold > 0', CURDATE()),
('dim_product', 'cost_price', 'Cost price must be less than retail price', 
 'cost_price < retail_price', CURDATE()),
('dim_date', 'date_key', 'Date key format is YYYYMMDD as integer', 
 'date_key = YEAR(full_date) * 10000 + MONTH(full_date) * 100 + DAY(full_date)', CURDATE());

-- ============================================================================
-- STEP 6: Data Mart Definition
-- ============================================================================

/*
DATA MART: Subject-oriented subset of data warehouse

RetailChain_DW contains multiple data marts:

1. SALES MART
   - fact_sales
   - dim_date, dim_product, dim_store, dim_customer, dim_promotion
   - Purpose: Analyze sales performance, trends, customer behavior

2. INVENTORY MART
   - fact_inventory
   - dim_date, dim_product, dim_store
   - Purpose: Track stock levels, reorder alerts, turnover rates

3. CUSTOMER MART
   - fact_sales (aggregated)
   - dim_customer, dim_date, dim_product
   - Purpose: Customer segmentation, RFM analysis, lifetime value

Each mart shares CONFORMED DIMENSIONS (dim_date, dim_product, etc.)
*/

-- ============================================================================
-- STEP 7: Naming Conventions
-- ============================================================================

/*
NAMING STANDARDS:

Tables:
- Fact tables: fact_{subject}        (fact_sales, fact_inventory)
- Dimension tables: dim_{subject}    (dim_product, dim_customer)
- Bridge tables: bridge_{subject}    (bridge_customer_group)
- Aggregate tables: agg_{grain}      (agg_sales_monthly)

Keys:
- Surrogate keys: {table}_key        (product_key, customer_key)
- Natural keys: {table}_id           (product_id, customer_id)
- Foreign keys: {dimension}_key      (date_key, store_key)

Columns:
- Measures: {measure}_{metric}       (quantity_sold, total_amount)
- Attributes: descriptive names      (product_name, store_city)
- Flags: is_{condition}              (is_current, is_active)
- Dates: {event}_date                (sale_date, ship_date)

Indexes:
- Primary keys: pk_{table}
- Foreign keys: fk_{table}_{dimension}
- Performance: idx_{table}_{columns}
*/

-- ============================================================================
-- STEP 8: Create Helper Functions
-- ============================================================================

-- Function: Convert date to date_key (YYYYMMDD format)
DELIMITER $$
CREATE FUNCTION fn_date_to_datekey(input_date DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN YEAR(input_date) * 10000 + MONTH(input_date) * 100 + DAY(input_date);
END$$
DELIMITER ;

-- Function: Convert date_key back to date
DELIMITER $$
CREATE FUNCTION fn_datekey_to_date(date_key INT)
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE year_part INT;
    DECLARE month_part INT;
    DECLARE day_part INT;
    
    SET year_part = date_key DIV 10000;
    SET month_part = (date_key MOD 10000) DIV 100;
    SET day_part = date_key MOD 100;
    
    RETURN STR_TO_DATE(CONCAT(year_part, '-', month_part, '-', day_part), '%Y-%m-%d');
END$$
DELIMITER ;

-- Test functions
SELECT fn_date_to_datekey('2024-03-15') AS date_key;  -- Returns: 20240315
SELECT fn_datekey_to_date(20240315) AS full_date;     -- Returns: 2024-03-15

-- ============================================================================
-- STEP 9: Create Unknown Members (Dimension Default Values)
-- ============================================================================

/*
UNKNOWN MEMBERS:
Every dimension needs a default "Unknown" row for:
- Missing/NULL foreign keys in fact tables
- Early-arriving facts (fact arrives before dimension is populated)
- Data quality issues

Surrogate key = -1 (or 0) is reserved for Unknown member
*/

-- Will be populated when dimensions are created:
-- INSERT INTO dim_product (product_key, product_id, product_name) VALUES (-1, 'UNKNOWN', 'Unknown Product');
-- INSERT INTO dim_customer (customer_key, customer_id, customer_name) VALUES (-1, 'UNKNOWN', 'Unknown Customer');

-- ============================================================================
-- STEP 10: Summary Statistics
-- ============================================================================

SELECT 'RetailChain_DW Database Created Successfully' AS status;

SELECT 
    'Next Steps:' AS step,
    '1. Run 02-create-dim-date.sql to create date dimension' AS instruction
UNION ALL
SELECT '', '2. Run 03-create-dim-store.sql to create store dimension'
UNION ALL
SELECT '', '3. Run 04-create-dim-product.sql to create product dimension'
UNION ALL
SELECT '', '4. Run 05-create-dim-customer.sql to create customer dimension'
UNION ALL
SELECT '', '5. Run 06-create-fact-sales.sql to create sales fact table'
UNION ALL
SELECT '', '6. Run 08-load-dimensions.sql to populate dimensions'
UNION ALL
SELECT '', '7. Run 09-load-facts.sql to populate fact tables'
UNION ALL
SELECT '', '8. Run analytical queries (10-16) for business insights';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Show all tables
SHOW TABLES;

-- Show helper functions
SHOW FUNCTION STATUS WHERE Db = 'RetailChain_DW';

-- Show metadata
SELECT * FROM metadata_schema_documentation;
SELECT * FROM metadata_business_rules;

/*
============================================================================
KIMBALL STAR SCHEMA - KEY TAKEAWAYS
============================================================================

1. ✅ Fact tables contain MEASUREMENTS (quantities, amounts, counts)
2. ✅ Dimension tables contain DESCRIPTIVE ATTRIBUTES (names, categories, dates)
3. ✅ Surrogate keys protect against source system changes
4. ✅ SCD Type 2 tracks historical changes with effective dates
5. ✅ Conformed dimensions are shared across fact tables
6. ✅ Atomic grain provides maximum flexibility
7. ✅ Star schema optimized for analytics (3-5 joins vs Data Vault's 10+)
8. ✅ Business users love star schemas (simple, intuitive)

============================================================================
READY TO BUILD DIMENSIONS!
Next: 02-create-dim-date.sql (The most important dimension!)
============================================================================
*/
