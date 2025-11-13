-- ========================================
-- Join Silver Tables & Add Foreign Keys
-- ========================================

USE TechStore_Warehouse;
GO

PRINT 'Establishing relationships between silver tables...';

-- ========================================
-- Update customer_key and product_key in orders
-- ========================================

UPDATE o
SET 
    o.customer_key = c.customer_key,
    o.product_key = p.product_key
FROM silver.orders o
LEFT JOIN silver.customers c ON o.customer_id = c.customer_id
LEFT JOIN silver.products p ON o.product_id = p.product_id;
GO

-- ========================================
-- Add Foreign Key Constraints
-- ========================================

ALTER TABLE silver.orders
ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customer_key) REFERENCES silver.customers(customer_key);
GO

ALTER TABLE silver.orders
ADD CONSTRAINT fk_orders_product 
FOREIGN KEY (product_key) REFERENCES silver.products(product_key);
GO

PRINT 'Relationships established!';
PRINT '';
PRINT 'Verification:';

SELECT 
    'Total Orders' AS metric,
    COUNT(*) AS value
FROM silver.orders
UNION ALL
SELECT 
    'Orders with Customer Match',
    COUNT(*)
FROM silver.orders
WHERE customer_key IS NOT NULL
UNION ALL
SELECT 
    'Orders with Product Match',
    COUNT(*)
FROM silver.orders
WHERE product_key IS NOT NULL;
GO
