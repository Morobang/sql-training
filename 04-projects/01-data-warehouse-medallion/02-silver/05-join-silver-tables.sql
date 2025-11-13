-- ========================================
-- Join Silver Tables & Add Foreign Keys
-- ========================================

USE TechStore;
GO

PRINT 'Establishing relationships between silver tables...';

-- ========================================
-- Update customer_key and product_key in orders
-- ========================================

UPDATE o
SET 
    o.customer_key = c.customer_key,
    o.product_key = p.product_key
FROM silver_orders o
LEFT JOIN silver_customers c ON o.customer_id = c.customer_id
LEFT JOIN silver_products p ON o.product_id = p.product_id;
GO

-- ========================================
-- Add Foreign Key Constraints
-- ========================================

ALTER TABLE silver_orders
ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customer_key) REFERENCES silver_customers(customer_key);
GO

ALTER TABLE silver_orders
ADD CONSTRAINT fk_orders_product 
FOREIGN KEY (product_key) REFERENCES silver_products(product_key);
GO

PRINT 'Relationships established!';
PRINT '';
PRINT 'Verification:';

SELECT 
    'Total Orders' AS metric,
    COUNT(*) AS value
FROM silver_orders
UNION ALL
SELECT 
    'Orders with Customer Match',
    COUNT(*)
FROM silver_orders
WHERE customer_key IS NOT NULL
UNION ALL
SELECT 
    'Orders with Product Match',
    COUNT(*)
FROM silver_orders
WHERE product_key IS NOT NULL;
GO
