-- ============================================================================
-- Create Sales Fact Table (fact_sales)
-- ============================================================================
-- Transaction-level sales data (ATOMIC GRAIN)
-- Each row = One product on one transaction
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- STEP 1: Create fact_sales Table
-- ============================================================================

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
    -- Fact Table Surrogate Key (optional but recommended)
    sales_key BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key for fact table',
    
    -- Foreign Keys to Dimensions (THE MAGIC!)
    date_key INT NOT NULL COMMENT 'FK to dim_date',
    store_key INT NOT NULL COMMENT 'FK to dim_store',
    product_key INT NOT NULL COMMENT 'FK to dim_product',
    customer_key INT NOT NULL COMMENT 'FK to dim_customer',
    
    -- Degenerate Dimensions (dimensions stored in fact table)
    transaction_id VARCHAR(50) NOT NULL COMMENT 'Transaction/Order ID',
    line_item_number SMALLINT COMMENT 'Line number within transaction (1, 2, 3...)',
    
    -- Quantitative Measures (FACTS - The Numbers We Analyze!)
    quantity_sold INT NOT NULL COMMENT 'Number of units sold',
    unit_price DECIMAL(10,2) NOT NULL COMMENT 'Price per unit at time of sale',
    unit_cost DECIMAL(10,2) NOT NULL COMMENT 'Cost per unit at time of sale',
    
    -- Calculated Measures (derived but stored for performance)
    gross_sales_amount DECIMAL(12,2) NOT NULL COMMENT 'quantity * unit_price',
    discount_amount DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Total discount applied',
    net_sales_amount DECIMAL(12,2) NOT NULL COMMENT 'gross_sales - discount',
    tax_amount DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Sales tax',
    total_amount DECIMAL(12,2) NOT NULL COMMENT 'net_sales + tax',
    
    cost_amount DECIMAL(12,2) NOT NULL COMMENT 'quantity * unit_cost',
    gross_profit_amount DECIMAL(12,2) NOT NULL COMMENT 'net_sales - cost',
    profit_margin_percent DECIMAL(5,2) COMMENT 'Profit margin percentage',
    
    -- Additional Facts
    loyalty_points_earned INT DEFAULT 0 COMMENT 'Loyalty points from this sale',
    
    -- Transaction Attributes (could be separate dimension, but kept here)
    payment_method VARCHAR(50) COMMENT 'Cash, Credit Card, Debit Card, Gift Card',
    promotion_applied VARCHAR(100) COMMENT 'Promotion code if any',
    is_return BOOLEAN DEFAULT FALSE COMMENT 'TRUE if this is a return transaction',
    return_reason VARCHAR(200) COMMENT 'Reason for return if applicable',
    
    -- Timestamps (actual transaction time - different from date_key)
    transaction_timestamp TIMESTAMP NOT NULL COMMENT 'Exact time of transaction',
    
    -- Audit Columns
    dw_insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dw_source_system VARCHAR(50) DEFAULT 'POS_TRANSACTIONS',
    
    -- Foreign Key Constraints (enforce referential integrity)
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    
    -- Indexes for Query Performance
    INDEX idx_date_key (date_key),
    INDEX idx_store_key (store_key),
    INDEX idx_product_key (product_key),
    INDEX idx_customer_key (customer_key),
    INDEX idx_transaction_id (transaction_id),
    INDEX idx_transaction_timestamp (transaction_timestamp),
    INDEX idx_date_store (date_key, store_key),
    INDEX idx_date_product (date_key, product_key),
    INDEX idx_date_customer (date_key, customer_key),
    
    -- Composite index for common queries
    INDEX idx_date_store_product (date_key, store_key, product_key)
    
) COMMENT 'Sales fact table - atomic grain (one row per line item)';

-- ============================================================================
-- UNDERSTANDING FACT TABLES
-- ============================================================================
/*
FACT TABLE DESIGN PRINCIPLES:

1. GRAIN (MOST IMPORTANT!)
   - Grain = The level of detail
   - Our grain: One row per product per transaction
   - Example: Order #12345 with 3 products = 3 rows in fact_sales
   
2. FACTS (Measurements)
   - Numeric values we want to analyze
   - Additive: Can be summed (quantity_sold, sales_amount)
   - Semi-additive: Can be summed across some dimensions (inventory levels)
   - Non-additive: Cannot be summed (ratios, percentages)
   
3. FOREIGN KEYS (Dimensions)
   - Every fact row links to dimension rows
   - These are the "by" columns (sales BY date, BY store, BY product)
   - Enable drill-down and slice-and-dice analysis
   
4. DEGENERATE DIMENSIONS
   - Dimension attributes stored in fact table (transaction_id)
   - No separate dimension table needed
   
5. DESIGN FOR QUERIES, NOT STORAGE
   - Pre-calculate derived values (gross_profit)
   - Storage is cheap, query time is expensive
   - Denormalize for performance

EXAMPLE QUERIES THIS DESIGN ENABLES:
- Total sales by date, store, product, customer
- Average order value by customer segment
- Profit margin by product category
- Year-over-year sales growth
- Top 10 products by revenue
- Customer lifetime value
- Sales by day of week, hour of day
- Store performance rankings
*/

-- ============================================================================
-- STEP 2: Verification Queries (Table is empty, just structure)
-- ============================================================================

-- Verify foreign key relationships
SELECT 
    'dim_date' AS dimension,
    COUNT(*) AS row_count,
    MIN(date_key) AS min_key,
    MAX(date_key) AS max_key
FROM dim_date
WHERE date_key != -1

UNION ALL

SELECT 
    'dim_store' AS dimension,
    COUNT(*) AS row_count,
    MIN(store_key) AS min_key,
    MAX(store_key) AS max_key
FROM dim_store
WHERE store_key != -1

UNION ALL

SELECT 
    'dim_product' AS dimension,
    COUNT(*) AS row_count,
    MIN(product_key) AS min_key,
    MAX(product_key) AS max_key
FROM dim_product
WHERE product_key != -1

UNION ALL

SELECT 
    'dim_customer' AS dimension,
    COUNT(*) AS row_count,
    MIN(customer_key) AS min_key,
    MAX(customer_key) AS max_key
FROM dim_customer
WHERE customer_key != -1;

-- Show fact table structure
DESCRIBE fact_sales;

-- Count (should be 0)
SELECT COUNT(*) AS row_count FROM fact_sales;

/*
============================================================================
FACT_SALES TABLE COMPLETE!
============================================================================

✅ Atomic grain (one row per line item)
✅ Foreign keys to all dimensions (date, store, product, customer)
✅ Quantitative measures (quantity, amount, profit, margin)
✅ Degenerate dimensions (transaction_id, line_item_number)
✅ Performance indexes on all foreign keys
✅ Referential integrity constraints
✅ Ready for data loading

STAR SCHEMA VISUALIZATION:

                    dim_date
                        |
                        |
    dim_customer --- fact_sales --- dim_store
                        |
                        |
                    dim_product

This is a STAR SCHEMA:
- Fact table in center (fact_sales)
- Dimension tables around it (like points of a star)
- Simple 1-level joins (fact → dimension)
- Fast queries, business-friendly

Next: 07-create-fact-inventory.sql
============================================================================
*/
