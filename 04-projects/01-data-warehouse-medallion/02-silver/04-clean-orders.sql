-- ========================================
-- Clean and Load Silver Orders
-- ========================================

USE TechStore_Warehouse;
GO

PRINT 'Cleaning orders data from bronze to silver...';

WITH cleaned_orders AS (
    SELECT 
        order_id,
        NULLIF(customer_id, '') AS customer_id,
        product_id,
        product_name,
        
        -- Clean quantity
        TRY_CAST(quantity AS INT) AS quantity_clean,
        
        -- Remove $ and convert amount
        TRY_CAST(REPLACE(REPLACE(total_amount, '$', ''), ',', '') AS DECIMAL(10,2)) AS amount_clean,
        
        -- Parse order date (multiple formats)
        TRY_CAST(order_date AS DATE) AS date_clean,
        
        payment_method,
        order_status,
        bronze_row_number
    FROM bronze.orders
    WHERE order_id IS NOT NULL
)
INSERT INTO silver.orders (
    order_id, customer_id, product_id, product_name, quantity, 
    unit_price, total_amount, order_date, payment_method, order_status, bronze_row_id
)
SELECT 
    order_id,
    customer_id,
    product_id,
    product_name,
    quantity_clean,
    amount_clean / NULLIF(quantity_clean, 0) AS unit_price,  -- Calculate unit price
    amount_clean,
    date_clean,
    payment_method,
    order_status,
    bronze_row_number
FROM cleaned_orders
WHERE quantity_clean > 0
  AND amount_clean > 0
  AND date_clean IS NOT NULL
  AND date_clean <= CAST(GETDATE() AS DATE)  -- No future dates
  AND customer_id IS NOT NULL;  -- Must have customer
GO

PRINT 'Orders cleaning complete!';
PRINT 'Bronze: ' + CAST((SELECT COUNT(*) FROM bronze.orders) AS VARCHAR);
PRINT 'Silver: ' + CAST((SELECT COUNT(*) FROM silver.orders) AS VARCHAR);
PRINT '';
GO
