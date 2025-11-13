-- ========================================
-- Clean and Load Silver Products
-- ========================================

USE TechStore_Warehouse;
GO

PRINT 'Cleaning inventory data from bronze to silver...';

WITH cleaned_inventory AS (
    SELECT 
        product_id,
        product_code,
        product_name,
        category,
        supplier_id,
        supplier_name,
        
        -- Remove $ and commas from prices, convert to DECIMAL
        TRY_CAST(REPLACE(REPLACE(REPLACE(cost_price, '$', ''), ',', ''), ' ', '') AS DECIMAL(10,2)) AS cost_clean,
        TRY_CAST(REPLACE(REPLACE(REPLACE(sell_price, '$', ''), ',', ''), ' ', '') AS DECIMAL(10,2)) AS price_clean,
        
        -- Handle negative quantities (set to 0)
        CASE 
            WHEN TRY_CAST(stock_quantity AS INT) < 0 THEN 0
            WHEN TRY_CAST(stock_quantity AS INT) IS NULL THEN 0
            ELSE TRY_CAST(stock_quantity AS INT)
        END AS quantity_clean,
        
        TRY_CAST(reorder_level AS INT) AS reorder_clean,
        warehouse_location,
        TRY_CAST(last_restocked AS DATE) AS restocked_clean,
        
        -- Standardize is_active to BIT
        CASE 
            WHEN is_active IN ('true', '1', 'yes', 'True', 'YES') THEN 1
            WHEN is_active IN ('false', '0', 'no', 'False', 'NO', '') THEN 0
            ELSE 1  -- Default to active
        END AS active_clean,
        
        bronze_row_number
    FROM bronze.inventory
    WHERE product_id IS NOT NULL
)
INSERT INTO silver.products (
    product_id, product_code, product_name, category, supplier_id, supplier_name,
    cost_price, sell_price, stock_quantity, reorder_level, warehouse_location,
    last_restocked, is_active, bronze_row_id
)
SELECT 
    product_id, product_code, product_name, category, supplier_id, supplier_name,
    cost_clean, price_clean, quantity_clean, reorder_clean, warehouse_location,
    restocked_clean, active_clean, bronze_row_number
FROM cleaned_inventory
WHERE cost_clean IS NOT NULL
  AND price_clean IS NOT NULL
  AND price_clean > 0;
GO

PRINT 'Inventory cleaning complete!';
PRINT 'Bronze: ' + CAST((SELECT COUNT(*) FROM bronze.inventory) AS VARCHAR);
PRINT 'Silver: ' + CAST((SELECT COUNT(*) FROM silver.products) AS VARCHAR);
PRINT '';
GO
