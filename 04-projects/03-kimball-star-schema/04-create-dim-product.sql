-- ============================================================================
-- Create Product Dimension (dim_product)
-- ============================================================================
-- Product catalog with SCD Type 2 (Slowly Changing Dimension Type 2)
-- Tracks historical changes to product attributes (especially price changes)
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- STEP 1: Create dim_product Table
-- ============================================================================

DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product (
    -- Surrogate Key (auto-increments for each version)
    product_key INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key - unique for each version',
    
    -- Natural Key (from source system - NOT UNIQUE because of SCD Type 2)
    product_id VARCHAR(20) NOT NULL COMMENT 'Product ID from source - multiple versions possible',
    
    -- Product Identification
    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    sku VARCHAR(50) COMMENT 'Stock Keeping Unit',
    upc VARCHAR(20) COMMENT 'Universal Product Code',
    
    -- Product Hierarchy (IMPORTANT for roll-up reporting)
    category VARCHAR(100) COMMENT 'Electronics, Clothing, Home Goods',
    subcategory VARCHAR(100) COMMENT 'TVs, Laptops, Shirts, Furniture',
    department VARCHAR(100) COMMENT 'Consumer Electronics, Apparel, etc.',
    brand VARCHAR(100),
    manufacturer VARCHAR(100),
    
    -- Product Attributes
    color VARCHAR(50),
    size VARCHAR(50),
    weight_pounds DECIMAL(10,2),
    dimensions VARCHAR(100) COMMENT 'LxWxH in inches',
    
    -- Pricing (SCD Type 2 tracks price changes!)
    unit_cost DECIMAL(10,2) COMMENT 'Our cost from supplier',
    unit_price DECIMAL(10,2) COMMENT 'Retail price to customer',
    msrp DECIMAL(10,2) COMMENT 'Manufacturer Suggested Retail Price',
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_discontinued BOOLEAN DEFAULT FALSE,
    
    -- Important Dates
    introduction_date DATE COMMENT 'Product launch date',
    discontinuation_date DATE,
    
    -- SCD Type 2 Columns (THE MAGIC!)
    effective_date DATE NOT NULL COMMENT 'When this version became effective',
    expiration_date DATE COMMENT 'When this version expired (NULL = current)',
    is_current BOOLEAN DEFAULT TRUE COMMENT 'TRUE for current version only',
    version_number INT DEFAULT 1 COMMENT 'Version counter for same product_id',
    
    -- Change Tracking
    change_reason VARCHAR(200) COMMENT 'Why was this version created (price change, etc.)',
    
    -- Audit Columns
    dw_insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dw_source_system VARCHAR(50) DEFAULT 'ERP_PRODUCTS',
    
    -- Indexes
    INDEX idx_product_id (product_id),
    INDEX idx_product_id_current (product_id, is_current),
    INDEX idx_category (category),
    INDEX idx_subcategory (subcategory),
    INDEX idx_brand (brand),
    INDEX idx_effective_date (effective_date),
    INDEX idx_is_current (is_current),
    
    -- Unique constraint: Only one current version per product_id
    UNIQUE KEY uk_product_current (product_id, is_current, expiration_date)
    
) COMMENT 'Product dimension - SCD Type 2 tracks price and attribute changes';

-- ============================================================================
-- STEP 2: Insert Unknown Member
-- ============================================================================

INSERT INTO dim_product (
    product_key,
    product_id,
    product_name,
    category,
    subcategory,
    department,
    brand,
    unit_cost,
    unit_price,
    effective_date,
    is_current
)
VALUES (
    -1,
    'UNKNOWN',
    'Unknown Product',
    'Unknown',
    'Unknown',
    'Unknown',
    'Unknown',
    0.00,
    0.00,
    '1900-01-01',
    TRUE
);

-- ============================================================================
-- STEP 3: Create Product Categories and Attributes
-- ============================================================================

-- Temporary table for product generation
DROP TEMPORARY TABLE IF EXISTS temp_product_categories;

CREATE TEMPORARY TABLE temp_product_categories (
    category VARCHAR(100),
    subcategory VARCHAR(100),
    department VARCHAR(100),
    brand VARCHAR(100),
    avg_cost DECIMAL(10,2),
    avg_price DECIMAL(10,2)
);

-- Insert product category definitions (1000 products)
INSERT INTO temp_product_categories VALUES
-- Electronics Department (400 products)
('Electronics', 'Televisions', 'Consumer Electronics', 'Samsung', 400.00, 799.99),
('Electronics', 'Televisions', 'Consumer Electronics', 'LG', 380.00, 749.99),
('Electronics', 'Televisions', 'Consumer Electronics', 'Sony', 450.00, 899.99),
('Electronics', 'Laptops', 'Consumer Electronics', 'Dell', 600.00, 1199.99),
('Electronics', 'Laptops', 'Consumer Electronics', 'HP', 550.00, 1099.99),
('Electronics', 'Laptops', 'Consumer Electronics', 'Apple', 1000.00, 1999.99),
('Electronics', 'Tablets', 'Consumer Electronics', 'Apple', 350.00, 699.99),
('Electronics', 'Tablets', 'Consumer Electronics', 'Samsung', 250.00, 499.99),
('Electronics', 'Smartphones', 'Consumer Electronics', 'Apple', 500.00, 999.99),
('Electronics', 'Smartphones', 'Consumer Electronics', 'Samsung', 400.00, 799.99),
('Electronics', 'Headphones', 'Consumer Electronics', 'Sony', 75.00, 149.99),
('Electronics', 'Headphones', 'Consumer Electronics', 'Bose', 150.00, 299.99),
('Electronics', 'Cameras', 'Consumer Electronics', 'Canon', 400.00, 799.99),
('Electronics', 'Cameras', 'Consumer Electronics', 'Nikon', 420.00, 839.99),
('Electronics', 'Gaming Consoles', 'Consumer Electronics', 'Sony', 300.00, 499.99),
('Electronics', 'Gaming Consoles', 'Consumer Electronics', 'Microsoft', 300.00, 499.99),

-- Clothing Department (300 products)
('Clothing', 'Mens Shirts', 'Apparel', 'RetailChain Brand', 12.00, 29.99),
('Clothing', 'Mens Shirts', 'Apparel', 'Premium Brand', 20.00, 49.99),
('Clothing', 'Mens Pants', 'Apparel', 'RetailChain Brand', 18.00, 39.99),
('Clothing', 'Mens Pants', 'Apparel', 'Levis', 25.00, 59.99),
('Clothing', 'Womens Dresses', 'Apparel', 'RetailChain Brand', 22.00, 49.99),
('Clothing', 'Womens Dresses', 'Apparel', 'Premium Brand', 35.00, 79.99),
('Clothing', 'Womens Tops', 'Apparel', 'RetailChain Brand', 10.00, 24.99),
('Clothing', 'Womens Pants', 'Apparel', 'RetailChain Brand', 16.00, 34.99),
('Clothing', 'Kids Clothing', 'Apparel', 'RetailChain Brand', 8.00, 19.99),
('Clothing', 'Shoes', 'Footwear', 'Nike', 40.00, 89.99),
('Clothing', 'Shoes', 'Footwear', 'Adidas', 38.00, 84.99),
('Clothing', 'Shoes', 'Footwear', 'RetailChain Brand', 20.00, 44.99),

-- Home Goods Department (300 products)
('Home Goods', 'Furniture', 'Home', 'RetailChain Home', 200.00, 499.99),
('Home Goods', 'Furniture', 'Home', 'Premium Home', 400.00, 899.99),
('Home Goods', 'Bedding', 'Home', 'RetailChain Home', 30.00, 69.99),
('Home Goods', 'Bedding', 'Home', 'Premium Home', 50.00, 119.99),
('Home Goods', 'Kitchen Appliances', 'Home', 'KitchenAid', 100.00, 249.99),
('Home Goods', 'Kitchen Appliances', 'Home', 'Cuisinart', 80.00, 199.99),
('Home Goods', 'Cookware', 'Home', 'RetailChain Home', 40.00, 89.99),
('Home Goods', 'Cookware', 'Home', 'Premium Home', 70.00, 159.99),
('Home Goods', 'Home Decor', 'Home', 'RetailChain Home', 15.00, 34.99),
('Home Goods', 'Lighting', 'Home', 'RetailChain Home', 25.00, 59.99),
('Home Goods', 'Storage', 'Home', 'RetailChain Home', 20.00, 44.99),
('Home Goods', 'Bath', 'Home', 'RetailChain Home', 18.00, 39.99);

-- ============================================================================
-- STEP 4: Generate 1000 Products (Initial Load)
-- ============================================================================

INSERT INTO dim_product (
    product_id,
    product_name,
    product_description,
    sku,
    upc,
    category,
    subcategory,
    department,
    brand,
    manufacturer,
    color,
    size,
    weight_pounds,
    unit_cost,
    unit_price,
    msrp,
    is_active,
    introduction_date,
    effective_date,
    is_current,
    version_number
)
SELECT 
    CONCAT('PROD-', LPAD(nums.n, 6, '0')) AS product_id,
    CONCAT(cat.brand, ' ', cat.subcategory, ' ', nums.n) AS product_name,
    CONCAT('High quality ', cat.subcategory, ' from ', cat.brand) AS product_description,
    CONCAT('SKU-', LPAD(nums.n, 8, '0')) AS sku,
    LPAD(FLOOR(100000000000 + RAND() * 900000000000), 12, '0') AS upc,
    cat.category,
    cat.subcategory,
    cat.department,
    cat.brand,
    cat.brand AS manufacturer,
    -- Colors
    CASE FLOOR(RAND() * 6)
        WHEN 0 THEN 'Black'
        WHEN 1 THEN 'White'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Blue'
        WHEN 4 THEN 'Red'
        ELSE 'Gray'
    END AS color,
    -- Sizes
    CASE 
        WHEN cat.category = 'Clothing' THEN 
            CASE FLOOR(RAND() * 5)
                WHEN 0 THEN 'XS'
                WHEN 1 THEN 'S'
                WHEN 2 THEN 'M'
                WHEN 3 THEN 'L'
                ELSE 'XL'
            END
        ELSE NULL
    END AS size,
    -- Weight
    CASE 
        WHEN cat.category = 'Electronics' THEN ROUND(2 + RAND() * 20, 2)
        WHEN cat.category = 'Clothing' THEN ROUND(0.5 + RAND() * 2, 2)
        ELSE ROUND(5 + RAND() * 50, 2)
    END AS weight_pounds,
    -- Cost (with variation)
    ROUND(cat.avg_cost * (0.8 + RAND() * 0.4), 2) AS unit_cost,
    -- Price (with variation)
    ROUND(cat.avg_price * (0.8 + RAND() * 0.4), 2) AS unit_price,
    -- MSRP (10% higher than price)
    ROUND(cat.avg_price * (0.8 + RAND() * 0.4) * 1.1, 2) AS msrp,
    -- Active (98% active)
    RAND() > 0.02 AS is_active,
    -- Introduction date (products launched 2018-2024)
    DATE_ADD('2018-01-01', INTERVAL FLOOR(RAND() * 2555) DAY) AS introduction_date,
    -- Effective date = introduction date for initial version
    DATE_ADD('2018-01-01', INTERVAL FLOOR(RAND() * 2555) DAY) AS effective_date,
    TRUE AS is_current,
    1 AS version_number
FROM (
    SELECT @row5 := @row5 + 1 AS n
    FROM (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3,
         (SELECT 0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t4,
         (SELECT @row5 := 0) r
    LIMIT 1000
) nums
CROSS JOIN temp_product_categories cat
WHERE MOD(nums.n, (SELECT COUNT(*) FROM temp_product_categories)) = (
    SELECT COUNT(*) - 1
    FROM temp_product_categories c2
    WHERE c2.category <= cat.category
       OR (c2.category = cat.category AND c2.subcategory <= cat.subcategory)
       OR (c2.category = cat.category AND c2.subcategory = cat.subcategory AND c2.brand <= cat.brand)
)
LIMIT 1000;

-- Update discontinued products
UPDATE dim_product
SET is_discontinued = TRUE,
    discontinuation_date = DATE_ADD(introduction_date, INTERVAL FLOOR(365 + RAND() * 730) DAY),
    is_active = FALSE
WHERE is_active = FALSE AND product_key != -1;

-- Log ETL
INSERT INTO metadata_etl_log (table_name, process_name, start_time, end_time, rows_inserted, status)
VALUES ('dim_product', 'initial_load', NOW(), NOW(), (SELECT COUNT(*) - 1 FROM dim_product), 'success');

-- ============================================================================
-- STEP 5: Verification Queries
-- ============================================================================

-- Count by category
SELECT 
    category,
    department,
    COUNT(*) AS product_count,
    COUNT(DISTINCT brand) AS brand_count,
    ROUND(AVG(unit_price), 2) AS avg_price,
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price
FROM dim_product
WHERE product_key != -1
GROUP BY category, department
ORDER BY product_count DESC;

-- SCD Type 2 status
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS unique_products,
    SUM(CASE WHEN is_current THEN 1 ELSE 0 END) AS current_versions,
    SUM(CASE WHEN is_current THEN 0 ELSE 1 END) AS historical_versions,
    MAX(version_number) AS max_versions
FROM dim_product
WHERE product_key != -1;

-- Products by brand
SELECT 
    brand,
    COUNT(*) AS product_count,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_products
FROM dim_product
WHERE product_key != -1 AND is_current = TRUE
GROUP BY brand
ORDER BY product_count DESC
LIMIT 10;

-- Sample records
SELECT 
    product_id,
    product_name,
    category,
    brand,
    unit_cost,
    unit_price,
    effective_date,
    expiration_date,
    is_current,
    version_number
FROM dim_product 
WHERE product_key != -1 
ORDER BY product_id
LIMIT 20;

/*
============================================================================
DIM_PRODUCT COMPLETE!
============================================================================

✅ 1000 products + 1 unknown member
✅ SCD Type 2 structure (tracks historical changes)
✅ Product hierarchy (Category → Subcategory → Department)
✅ Pricing attributes (cost, price, MSRP)
✅ Ready for price change tracking (version_number, effective_date, etc.)
✅ Multiple brands across Electronics, Clothing, Home Goods

SCD Type 2 Columns Explained:
- product_id: Natural key (NOT unique - can have multiple versions)
- product_key: Surrogate key (unique for each version)
- effective_date: When this version started
- expiration_date: When this version ended (NULL = current)
- is_current: TRUE for latest version only
- version_number: Counter (1, 2, 3, ...)
- change_reason: Why version created (e.g., "Price increase")

Next: 05-create-dim-customer.sql
============================================================================
*/
