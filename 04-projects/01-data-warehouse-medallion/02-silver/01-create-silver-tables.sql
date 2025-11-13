-- ========================================
-- Create Silver Layer Tables
-- ========================================
-- Purpose: Define silver tables with PROPER DATA TYPES
-- Key Difference from Bronze: Strong typing, constraints, relationships
-- ========================================

USE TechStore;
GO

-- ========================================
-- Silver Table 1: Customers (Cleaned)
-- ========================================

IF OBJECT_ID('silver_customers', 'U') IS NOT NULL
    DROP TABLE silver_customers;
GO

CREATE TABLE silver_customers (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,  -- Surrogate key
    customer_id VARCHAR(50) NOT NULL UNIQUE,     -- Business key
    
    -- Cleaned and parsed name fields
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200) NOT NULL,
    
    -- Validated contact information
    email VARCHAR(255),
    phone VARCHAR(20),                            -- Standardized format
    
    -- Address
    city VARCHAR(100),
    state CHAR(2),
    zip_code VARCHAR(10),                         -- 5 or 9 digits
    
    -- Customer attributes
    join_date DATE,                               -- Proper DATE type
    customer_tier VARCHAR(20) DEFAULT 'Standard', -- Standardized values
    
    -- Metadata
    silver_created_at DATETIME DEFAULT GETDATE(),
    silver_updated_at DATETIME DEFAULT GETDATE(),
    bronze_row_id INT                             -- Link back to bronze
);
GO

-- Indexes for common queries
CREATE INDEX idx_silver_customers_email ON silver_customers(email);
CREATE INDEX idx_silver_customers_tier ON silver_customers(customer_tier);
CREATE INDEX idx_silver_customers_city ON silver_customers(city);
GO

-- ========================================
-- Silver Table 2: Products/Inventory (Cleaned)
-- ========================================

IF OBJECT_ID('silver_products', 'U') IS NOT NULL
    DROP TABLE silver_products;
GO

CREATE TABLE silver_products (
    product_key INT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate key
    product_id VARCHAR(50) NOT NULL UNIQUE,      -- Business key
    
    -- Product information
    product_code VARCHAR(100),
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    
    -- Supplier
    supplier_id VARCHAR(50),
    supplier_name VARCHAR(200),
    
    -- Pricing (proper DECIMAL types)
    cost_price DECIMAL(10,2),
    sell_price DECIMAL(10,2),
    profit_margin AS (sell_price - cost_price) PERSISTED,  -- Computed column
    margin_percentage AS (
        CASE 
            WHEN cost_price > 0 
            THEN ((sell_price - cost_price) / cost_price * 100)
            ELSE 0 
        END
    ) PERSISTED,
    
    -- Inventory
    stock_quantity INT DEFAULT 0,
    reorder_level INT DEFAULT 10,
    warehouse_location VARCHAR(100),
    last_restocked DATE,
    
    -- Status
    is_active BIT DEFAULT 1,                      -- Proper boolean
    
    -- Metadata
    silver_created_at DATETIME DEFAULT GETDATE(),
    silver_updated_at DATETIME DEFAULT GETDATE(),
    bronze_row_id INT
);
GO

-- Indexes
CREATE INDEX idx_silver_products_category ON silver_products(category);
CREATE INDEX idx_silver_products_supplier ON silver_products(supplier_id);
CREATE INDEX idx_silver_products_active ON silver_products(is_active);
GO

-- ========================================
-- Silver Table 3: Orders (Cleaned)
-- ========================================

IF OBJECT_ID('silver_orders', 'U') IS NOT NULL
    DROP TABLE silver_orders;
GO

CREATE TABLE silver_orders (
    order_key INT IDENTITY(1,1) PRIMARY KEY,     -- Surrogate key
    order_id VARCHAR(50) NOT NULL UNIQUE,        -- Business key
    
    -- Foreign keys
    customer_key INT,                             -- Will link to silver_customers
    product_key INT,                              -- Will link to silver_products
    customer_id VARCHAR(50),                      -- Also keep business keys
    product_id VARCHAR(50),
    
    -- Order details
    product_name VARCHAR(200),
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2),                     -- Calculated from total_amount / quantity
    total_amount DECIMAL(10,2) NOT NULL,
    
    -- Order metadata
    order_date DATE NOT NULL,
    payment_method VARCHAR(50),
    order_status VARCHAR(50),
    
    -- Metadata
    silver_created_at DATETIME DEFAULT GETDATE(),
    silver_updated_at DATETIME DEFAULT GETDATE(),
    bronze_row_id INT,
    
    -- Constraints
    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_amount CHECK (total_amount >= 0)
);
GO

-- Indexes
CREATE INDEX idx_silver_orders_customer ON silver_orders(customer_key);
CREATE INDEX idx_silver_orders_product ON silver_orders(product_key);
CREATE INDEX idx_silver_orders_date ON silver_orders(order_date);
CREATE INDEX idx_silver_orders_status ON silver_orders(order_status);
GO

-- ========================================
-- Add Foreign Key Relationships
-- (After data is loaded and keys are established)
-- ========================================
-- These will be added in 05-join-silver-tables.sql
-- after we populate the tables

-- ========================================
-- Verification
-- ========================================

SELECT 
    TABLE_NAME,
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = t.TABLE_NAME) AS column_count
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_NAME LIKE 'silver_%'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

-- Show columns with proper data types
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'silver_%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

PRINT 'Silver tables created successfully!';
PRINT 'Next: Run 02-clean-customers.sql to populate silver_customers';
GO
