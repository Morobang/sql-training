-- ========================================
-- Bronze Layer: Create Raw Tables
-- ========================================
-- Purpose: Create bronze tables to store raw data from source systems
-- Key Principle: Store data "as-is" with minimal validation
-- ========================================

USE TechStore;
GO

-- ========================================
-- Bronze Table 1: Orders (from website CSV)
-- ========================================
-- Source: Daily CSV exports from e-commerce platform
-- Issues: Missing customer IDs, inconsistent date formats, bad data
-- Strategy: Load everything as VARCHAR to prevent failures

IF OBJECT_ID('bronze_orders', 'U') IS NOT NULL
    DROP TABLE bronze_orders;
GO

CREATE TABLE bronze_orders (
    -- Source columns (all VARCHAR to handle any format)
    order_id VARCHAR(50),
    customer_id VARCHAR(50),         -- Can be NULL or empty
    product_id VARCHAR(50),
    product_name VARCHAR(200),
    quantity VARCHAR(50),            -- Might contain "N/A" or negative numbers
    order_date VARCHAR(50),          -- Multiple date formats: "2024-01-15", "01/15/2024"
    total_amount VARCHAR(50),        -- Might include "$" or commas
    payment_method VARCHAR(50),
    order_status VARCHAR(50),
    
    -- Bronze metadata columns
    bronze_loaded_at DATETIME DEFAULT GETDATE(),
    bronze_source_file VARCHAR(255),
    bronze_row_number INT IDENTITY(1,1)
);
GO

-- Create index on load timestamp for tracking
CREATE INDEX idx_bronze_orders_loaded 
ON bronze_orders(bronze_loaded_at);
GO

-- ========================================
-- Bronze Table 2: Customers (from CRM)
-- ========================================
-- Source: Customer relationship management system
-- Issues: Duplicate records, invalid emails, mixed name formats
-- Strategy: Keep all duplicates, clean in Silver

IF OBJECT_ID('bronze_customers', 'U') IS NOT NULL
    DROP TABLE bronze_customers;
GO

CREATE TABLE bronze_customers (
    -- Source columns
    customer_id VARCHAR(50),
    full_name VARCHAR(200),          -- Sometimes "First Last", sometimes "Last, First"
    email VARCHAR(255),              -- Not always valid format
    phone VARCHAR(50),               -- Various formats: (555)555-5555, 555-555-5555
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),            -- Sometimes 5 digits, sometimes 9
    join_date VARCHAR(50),           -- Mixed formats
    customer_tier VARCHAR(50),       -- "Gold", "Silver", "Bronze", sometimes empty
    
    -- Bronze metadata
    bronze_loaded_at DATETIME DEFAULT GETDATE(),
    bronze_source_system VARCHAR(100) DEFAULT 'CRM',
    bronze_row_number INT IDENTITY(1,1)
);
GO

CREATE INDEX idx_bronze_customers_loaded 
ON bronze_customers(bronze_loaded_at);
GO

-- ========================================
-- Bronze Table 3: Inventory (from warehouse API)
-- ========================================
-- Source: JSON from warehouse management system API
-- Issues: Nested JSON, quantity can be negative, price inconsistencies
-- Strategy: Store flattened JSON, all as VARCHAR

IF OBJECT_ID('bronze_inventory', 'U') IS NOT NULL
    DROP TABLE bronze_inventory;
GO

CREATE TABLE bronze_inventory (
    -- Source columns (flattened from JSON)
    product_id VARCHAR(50),
    product_code VARCHAR(100),       -- Sometimes includes special characters
    product_name VARCHAR(200),
    category VARCHAR(100),
    supplier_id VARCHAR(50),
    supplier_name VARCHAR(200),
    cost_price VARCHAR(50),          -- From JSON, might have decimals or currency symbols
    sell_price VARCHAR(50),
    stock_quantity VARCHAR(50),      -- Can be negative (oversold)
    reorder_level VARCHAR(50),
    warehouse_location VARCHAR(100),
    last_restocked VARCHAR(50),      -- Timestamp from API
    is_active VARCHAR(10),           -- "true", "false", "1", "0", or empty
    
    -- Bronze metadata
    bronze_loaded_at DATETIME DEFAULT GETDATE(),
    bronze_api_endpoint VARCHAR(255),
    bronze_api_response_time_ms INT,
    bronze_row_number INT IDENTITY(1,1)
);
GO

CREATE INDEX idx_bronze_inventory_loaded 
ON bronze_inventory(bronze_loaded_at);
GO

-- ========================================
-- Bronze Table 4: Sales Transactions
-- ========================================
-- Source: Point of sale system
-- Issues: Duplicate transactions, refunds mixed with sales
-- Strategy: Keep everything, identify refunds in Silver

IF OBJECT_ID('bronze_sales', 'U') IS NOT NULL
    DROP TABLE bronze_sales;
GO

CREATE TABLE bronze_sales (
    -- Source columns
    transaction_id VARCHAR(50),
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    customer_id VARCHAR(50),
    quantity_sold VARCHAR(50),       -- Can be negative for refunds
    unit_price VARCHAR(50),
    discount_amount VARCHAR(50),
    tax_amount VARCHAR(50),
    total_amount VARCHAR(50),
    transaction_date VARCHAR(50),
    transaction_type VARCHAR(50),    -- "SALE", "RETURN", "EXCHANGE"
    
    -- Bronze metadata
    bronze_loaded_at DATETIME DEFAULT GETDATE(),
    bronze_source_system VARCHAR(100) DEFAULT 'POS',
    bronze_row_number INT IDENTITY(1,1)
);
GO

CREATE INDEX idx_bronze_sales_loaded 
ON bronze_sales(bronze_loaded_at);
GO

-- ========================================
-- Verification Queries
-- ========================================

-- Check table structures
SELECT 
    TABLE_NAME,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_NAME LIKE 'bronze_%'
ORDER BY TABLE_NAME;
GO

-- Show columns for each bronze table
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'bronze_%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

-- ========================================
-- Key Takeaways
-- ========================================

-- ✅ All source columns stored as VARCHAR
-- ✅ No data type constraints (prevents load failures)
-- ✅ No foreign keys or NOT NULL constraints
-- ✅ Metadata columns track load time and source
-- ✅ Identity columns for unique row tracking
-- ✅ Indexes only on metadata (not business columns)

-- Next Steps:
-- 1. Load sample data into bronze tables (files 03-05)
-- 2. Verify data quality issues exist in bronze
-- 3. Move to Silver layer for cleaning and validation
