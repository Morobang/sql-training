-- ============================================================================
-- Create Inventory Fact Table (fact_inventory)
-- ============================================================================
-- Daily inventory snapshots (PERIODIC SNAPSHOT GRAIN)
-- Each row = One product at one store on one date
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- STEP 1: Create fact_inventory Table
-- ============================================================================

DROP TABLE IF EXISTS fact_inventory;

CREATE TABLE fact_inventory (
    -- Fact Table Surrogate Key
    inventory_key BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key',
    
    -- Foreign Keys to Dimensions
    date_key INT NOT NULL COMMENT 'FK to dim_date (snapshot date)',
    store_key INT NOT NULL COMMENT 'FK to dim_store',
    product_key INT NOT NULL COMMENT 'FK to dim_product',
    
    -- Inventory Measures (SEMI-ADDITIVE FACTS)
    quantity_on_hand INT NOT NULL DEFAULT 0 COMMENT 'Current inventory level',
    quantity_allocated INT DEFAULT 0 COMMENT 'Reserved for orders',
    quantity_available INT DEFAULT 0 COMMENT 'Available to sell = on_hand - allocated',
    quantity_on_order INT DEFAULT 0 COMMENT 'Ordered from suppliers',
    quantity_in_transit INT DEFAULT 0 COMMENT 'Being shipped to store',
    
    -- Inventory Values
    unit_cost DECIMAL(10,2) NOT NULL COMMENT 'Cost per unit',
    inventory_value DECIMAL(12,2) NOT NULL COMMENT 'quantity_on_hand * unit_cost',
    
    -- Inventory Metrics
    days_of_supply DECIMAL(5,1) COMMENT 'Days until stockout (based on avg daily sales)',
    reorder_point INT COMMENT 'Trigger point for reordering',
    safety_stock_level INT COMMENT 'Minimum stock to maintain',
    
    -- Status Flags
    is_out_of_stock BOOLEAN DEFAULT FALSE COMMENT 'TRUE if quantity_on_hand = 0',
    is_low_stock BOOLEAN DEFAULT FALSE COMMENT 'TRUE if below reorder point',
    is_overstock BOOLEAN DEFAULT FALSE COMMENT 'TRUE if excess inventory',
    
    -- Audit Columns
    dw_insert_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    dw_source_system VARCHAR(50) DEFAULT 'ERP_INVENTORY',
    
    -- Foreign Key Constraints
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    
    -- Indexes
    INDEX idx_date_key (date_key),
    INDEX idx_store_key (store_key),
    INDEX idx_product_key (product_key),
    INDEX idx_date_store_product (date_key, store_key, product_key),
    
    -- Unique constraint: One snapshot per product per store per date
    UNIQUE KEY uk_inventory_snapshot (date_key, store_key, product_key)
    
) COMMENT 'Inventory fact table - periodic snapshots (daily)';

-- ============================================================================
-- UNDERSTANDING PERIODIC SNAPSHOT FACT TABLES
-- ============================================================================
/*
PERIODIC SNAPSHOT vs TRANSACTION FACT TABLES:

1. TRANSACTION FACT TABLE (fact_sales)
   - Grain: One event (e.g., one sale)
   - Sparse: Only rows when events occur
   - Example: Sales only when customers buy
   
2. PERIODIC SNAPSHOT FACT TABLE (fact_inventory)
   - Grain: Status at regular intervals (e.g., daily)
   - Dense: Rows exist even when nothing changes
   - Example: Inventory levels every day, even if no movement
   
3. ACCUMULATING SNAPSHOT FACT TABLE (not in this project)
   - Grain: Entire process lifecycle
   - Example: Order from placement → fulfillment → delivery
   - Rows updated as process progresses

SEMI-ADDITIVE FACTS:
- Inventory levels can be summed across products and stores
- But NOT across time (can't add Monday's inventory + Tuesday's inventory)
- Use AVG() or LAST_VALUE() for time-based aggregations
- Example: Average inventory level for October, not SUM()

EXAMPLE QUERIES THIS DESIGN ENABLES:
- Current inventory levels by store
- Inventory turnover rate by product
- Stock-out frequency
- Inventory value by category
- Overstock identification
- Days of supply analysis
*/

-- Show table structure
DESCRIBE fact_inventory;

-- Count (should be 0)
SELECT COUNT(*) AS row_count FROM fact_inventory;

/*
============================================================================
FACT_INVENTORY TABLE COMPLETE!
============================================================================

✅ Periodic snapshot grain (daily inventory levels)
✅ Semi-additive facts (inventory quantities)
✅ Foreign keys to date, store, product dimensions
✅ Unique constraint prevents duplicate snapshots
✅ Inventory metrics (days of supply, reorder points)
✅ Status flags (out of stock, low stock, overstock)

DUAL FACT TABLE ARCHITECTURE:

Our star schema now has TWO fact tables:
1. fact_sales: Transaction-level events (sparse)
2. fact_inventory: Daily snapshots (dense)

Both share conformed dimensions:
- dim_date (shared across both facts)
- dim_store (shared across both facts)
- dim_product (shared across both facts)

This enables cross-fact analysis:
- Compare sales velocity to inventory levels
- Calculate inventory turnover
- Identify fast-moving vs slow-moving products

Next: 08-load-dimensions.sql (populate with sample data!)
============================================================================
*/
