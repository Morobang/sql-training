-- ============================================================================
-- SCD Type 2 Implementation Examples
-- ============================================================================
-- Demonstrates Slowly Changing Dimension Type 2
-- Track historical changes to dimension attributes (especially prices)
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- UNDERSTANDING SCD TYPE 2
-- ============================================================================
/*
SCD TYPE 2: Track Full History

SCENARIO: Product price changes over time
- We want to track historical prices
- Sales transactions must reflect price AT TIME OF SALE
- Need to preserve entire history for analysis

EXAMPLE:
Product: "Samsung 55-inch TV"
- Jan 1, 2024: Price = $799.99  (version 1)
- Jun 1, 2024: Price = $699.99  (version 2) - PRICE DROP!
- Nov 1, 2024: Price = $749.99  (version 3) - PRICE INCREASE

SCD Type 2 Solution:
product_id | product_name      | price   | effective_date | expiration_date | is_current | version
PROD-00123 | Samsung 55" TV    | 799.99  | 2024-01-01     | 2024-05-31      | FALSE      | 1
PROD-00123 | Samsung 55" TV    | 699.99  | 2024-06-01     | 2024-10-31      | FALSE      | 2
PROD-00123 | Samsung 55" TV    | 749.99  | 2024-11-01     | NULL            | TRUE       | 3

KEY POINTS:
1. product_id is NOT unique (multiple versions)
2. product_key IS unique (one per version)
3. is_current = TRUE only for latest version
4. expiration_date = NULL for current version
5. effective_date/expiration_date determine valid period
*/

-- ============================================================================
-- STEP 1: Create Procedure to Add New Product Version
-- ============================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_update_product_price$$

CREATE PROCEDURE sp_update_product_price(
    IN p_product_id VARCHAR(20),
    IN p_new_price DECIMAL(10,2),
    IN p_effective_date DATE,
    IN p_change_reason VARCHAR(200)
)
BEGIN
    DECLARE v_current_product_key INT;
    DECLARE v_new_version_number INT;
    
    -- Get current version
    SELECT product_key, version_number + 1
    INTO v_current_product_key, v_new_version_number
    FROM dim_product
    WHERE product_id = p_product_id
      AND is_current = TRUE
    LIMIT 1;
    
    -- Expire current version
    UPDATE dim_product
    SET expiration_date = DATE_SUB(p_effective_date, INTERVAL 1 DAY),
        is_current = FALSE,
        dw_update_date = NOW()
    WHERE product_key = v_current_product_key;
    
    -- Insert new version (copy all attributes from current version)
    INSERT INTO dim_product (
        product_id, product_name, product_description, sku, upc,
        category, subcategory, department, brand, manufacturer,
        color, size, weight_pounds, dimensions,
        unit_cost, unit_price, msrp,
        is_active, is_discontinued,
        introduction_date, discontinuation_date,
        effective_date, expiration_date, is_current, version_number,
        change_reason
    )
    SELECT 
        product_id, product_name, product_description, sku, upc,
        category, subcategory, department, brand, manufacturer,
        color, size, weight_pounds, dimensions,
        unit_cost,
        p_new_price AS unit_price,  -- NEW PRICE
        p_new_price * 1.1 AS msrp,  -- Updated MSRP
        is_active, is_discontinued,
        introduction_date, discontinuation_date,
        p_effective_date AS effective_date,
        NULL AS expiration_date,
        TRUE AS is_current,
        v_new_version_number AS version_number,
        p_change_reason AS change_reason
    FROM dim_product
    WHERE product_key = v_current_product_key;
    
    SELECT CONCAT('Created version ', v_new_version_number, ' for product ', p_product_id) AS result;
    
END$$

DELIMITER ;

-- ============================================================================
-- STEP 2: Example - Simulate Price Changes
-- ============================================================================

-- Example 1: Lower price on a popular TV (seasonal discount)
CALL sp_update_product_price(
    'PROD-000001',
    599.99,
    '2024-11-01',
    'Black Friday promotion - 25% price reduction'
);

-- Example 2: Increase price due to supply chain issues
CALL sp_update_product_price(
    'PROD-000002',
    899.99,
    '2024-10-15',
    'Supply chain cost increase'
);

-- Example 3: New model year pricing
CALL sp_update_product_price(
    'PROD-000003',
    1299.99,
    '2024-09-01',
    'New model year launch'
);

-- ============================================================================
-- STEP 3: Query Historical Product Prices
-- ============================================================================

-- View all versions of specific products
SELECT 
    product_id,
    product_name,
    CONCAT('$', FORMAT(unit_price, 2)) AS price,
    effective_date,
    expiration_date,
    CASE WHEN is_current THEN 'CURRENT' ELSE 'Historical' END AS status,
    version_number,
    change_reason
FROM dim_product
WHERE product_id IN ('PROD-000001', 'PROD-000002', 'PROD-000003')
ORDER BY product_id, version_number;

-- Products with price changes
SELECT 
    p.product_id,
    p.product_name,
    COUNT(*) AS version_count,
    MIN(p.unit_price) AS lowest_price,
    MAX(p.unit_price) AS highest_price,
    (SELECT unit_price FROM dim_product WHERE product_id = p.product_id AND is_current = TRUE) AS current_price
FROM dim_product p
WHERE p.product_key > 0
GROUP BY p.product_id, p.product_name
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- ============================================================================
-- STEP 4: Point-in-Time Queries (Historical Accuracy!)
-- ============================================================================

-- What was the product catalog on June 1, 2024?
SELECT 
    product_id,
    product_name,
    category,
    brand,
    CONCAT('$', FORMAT(unit_price, 2)) AS price,
    effective_date,
    expiration_date,
    version_number
FROM dim_product
WHERE '2024-06-01' BETWEEN effective_date AND COALESCE(expiration_date, '9999-12-31')
ORDER BY category, product_name
LIMIT 20;

-- Price changes in October 2024
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    CONCAT('$', FORMAT(p.unit_price, 2)) AS new_price,
    p.effective_date,
    p.change_reason,
    CONCAT('$', FORMAT(prev.unit_price, 2)) AS old_price,
    CONCAT(ROUND((p.unit_price - prev.unit_price) * 100.0 / prev.unit_price, 2), '%') AS price_change_pct
FROM dim_product p
JOIN dim_product prev ON p.product_id = prev.product_id 
                      AND p.version_number = prev.version_number + 1
WHERE p.effective_date BETWEEN '2024-10-01' AND '2024-10-31'
ORDER BY ABS(p.unit_price - prev.unit_price) DESC;

-- ============================================================================
-- STEP 5: Join Sales to Correct Product Version (THE MAGIC!)
-- ============================================================================

-- Sales by product with CORRECT historical price
-- This ensures we use the price that was active AT TIME OF SALE
SELECT 
    p.product_name,
    p.version_number,
    CONCAT('$', FORMAT(p.unit_price, 2)) AS catalog_price,
    p.effective_date,
    p.expiration_date,
    COUNT(*) AS sales_count,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
WHERE p.product_id IN ('PROD-000001', 'PROD-000002', 'PROD-000003')
GROUP BY p.product_key, p.product_name, p.version_number, p.unit_price, p.effective_date, p.expiration_date
ORDER BY p.product_id, p.version_number;

-- Revenue impact of price changes
WITH price_changes AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.version_number,
        p.unit_price,
        p.effective_date,
        p.expiration_date,
        LAG(p.unit_price) OVER (PARTITION BY p.product_id ORDER BY p.version_number) AS previous_price
    FROM dim_product p
    WHERE p.product_key > 0
)
SELECT 
    pc.product_name,
    pc.version_number,
    CONCAT('$', FORMAT(pc.previous_price, 2)) AS old_price,
    CONCAT('$', FORMAT(pc.unit_price, 2)) AS new_price,
    CONCAT(ROUND((pc.unit_price - pc.previous_price) * 100.0 / pc.previous_price, 2), '%') AS change_pct,
    pc.effective_date,
    COUNT(f.sales_key) AS sales_after_change,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue_after_change
FROM price_changes pc
LEFT JOIN dim_product p ON pc.product_id = p.product_id 
                        AND p.version_number = pc.version_number
LEFT JOIN fact_sales f ON f.product_key = p.product_key
WHERE pc.previous_price IS NOT NULL  -- Only show products with changes
GROUP BY pc.product_id, pc.product_name, pc.version_number, pc.previous_price, 
         pc.unit_price, pc.effective_date
ORDER BY ABS(pc.unit_price - pc.previous_price) DESC
LIMIT 20;

-- ============================================================================
-- STEP 6: SCD Type 2 Best Practices
-- ============================================================================
/*
BEST PRACTICES:

1. ALWAYS JOIN ON SURROGATE KEY (product_key)
   - ❌ WRONG: JOIN ... ON f.product_id = p.product_id
   - ✅ RIGHT: JOIN ... ON f.product_key = p.product_key
   
2. USE EFFECTIVE/EXPIRATION DATES FOR POINT-IN-TIME QUERIES
   - WHERE @query_date BETWEEN effective_date AND COALESCE(expiration_date, '9999-12-31')
   
3. CURRENT VERSION QUERIES
   - WHERE is_current = TRUE
   - WHERE expiration_date IS NULL
   
4. NEVER DELETE OLD VERSIONS
   - Historical accuracy depends on preserving all versions
   - Disk space is cheap, lost history is expensive
   
5. DOCUMENT CHANGE REASONS
   - change_reason field explains WHY version was created
   - Critical for auditing and analysis

WHEN TO USE SCD TYPE 2:
✅ Product prices (track price history)
✅ Customer addresses (track moves)
✅ Employee job titles/salaries (track promotions)
✅ Supplier contracts (track terms changes)
✅ Tax rates (track historical rates)

WHEN NOT TO USE:
❌ Frequently changing attributes (100s of changes/day)
❌ Attributes that don't impact analysis
❌ Real-time operational data (use Type 1 or Type 3)

ALTERNATIVE: SCD TYPES
- Type 0: Never changes (original values only)
- Type 1: Overwrite (current values only, no history)
- Type 2: Track full history (what we implemented)
- Type 3: Track previous + current (limited history)
- Type 4: Separate history table (advanced)
- Type 6: Hybrid (combine Types 1, 2, 3)
*/

/*
============================================================================
SCD TYPE 2 IMPLEMENTATION COMPLETE!
============================================================================

✅ Stored procedure to create new product versions
✅ Example price changes with reasons
✅ Historical price tracking
✅ Point-in-time queries (what was price on specific date?)
✅ Correct historical joins (sales → product version active at time)
✅ Price change impact analysis

KEY BENEFITS:
1. Historical Accuracy: Sales reflect actual prices at time of transaction
2. Trend Analysis: Track how price changes impact sales volume
3. Audit Trail: Complete history of all changes with reasons
4. Regulatory Compliance: Can recreate business state at any point in time

REAL-WORLD USE CASES:
- "What were our prices during Q4 2023?"
- "How did the June price increase impact sales?"
- "Show me all products that had price changes last quarter"
- "Calculate revenue using historical prices vs current prices"

This is THE POWER of dimensional modeling!
============================================================================
*/
