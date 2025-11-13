-- ========================================
-- Gold: Customer 360° View
-- ========================================
-- Purpose: Complete customer profile for analytics
-- ========================================

USE TechStore_Warehouse;
GO

IF OBJECT_ID('gold.customer_360', 'U') IS NOT NULL
    DROP TABLE gold.customer_360;
GO

CREATE TABLE gold.customer_360 (
    customer_key INT PRIMARY KEY,
    customer_id VARCHAR(50),
    customer_name VARCHAR(200),
    email VARCHAR(255),
    phone VARCHAR(20),
    city VARCHAR(100),
    customer_tier VARCHAR(20),
    join_date DATE,
    
    -- Purchase behavior
    first_purchase_date DATE,
    last_purchase_date DATE,
    days_since_last_purchase INT,
    total_orders INT,
    total_items_purchased INT,
    
    -- Financial metrics
    lifetime_value DECIMAL(18,2),
    average_order_value DECIMAL(10,2),
    total_discount DECIMAL(10,2),
    
    -- Segmentation
    customer_status VARCHAR(20),  -- Active, At-Risk, Churned, New
    is_vip BIT,
    
    -- Metadata
    gold_created_at DATETIME DEFAULT GETDATE()
);
GO

INSERT INTO gold.customer_360
SELECT 
    c.customer_key,
    c.customer_id,
    c.full_name,
    c.email,
    c.phone,
    c.city,
    c.customer_tier,
    c.join_date,
    
    -- Purchase dates
    MIN(o.order_date) AS first_purchase_date,
    MAX(o.order_date) AS last_purchase_date,
    DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_purchase,
    
    -- Purchase counts
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.quantity) AS total_items_purchased,
    
    -- Financial
    SUM(o.total_amount) AS lifetime_value,
    AVG(o.total_amount) AS average_order_value,
    0 AS total_discount,  -- Placeholder for future discount tracking
    
    -- Segmentation
    CASE 
        WHEN DATEDIFF(DAY, MAX(o.order_date), GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(DAY, MAX(o.order_date), GETDATE()) <= 90 THEN 'At-Risk'
        WHEN DATEDIFF(DAY, MAX(o.order_date), GETDATE()) > 90 THEN 'Churned'
        ELSE 'New'
    END AS customer_status,
    
    CASE 
        WHEN SUM(o.total_amount) > 5000 OR COUNT(DISTINCT o.order_id) > 20 THEN 1
        ELSE 0
    END AS is_vip,
    
    GETDATE()
FROM silver.customers c
LEFT JOIN silver.orders o ON c.customer_key = o.customer_key
GROUP BY 
    c.customer_key, c.customer_id, c.full_name, c.email, c.phone,
    c.city, c.customer_tier, c.join_date;
GO

-- Create indexes
CREATE INDEX idx_gold_customer_status ON gold.customer_360(customer_status);
CREATE INDEX idx_gold_customer_tier ON gold.customer_360(customer_tier);
CREATE INDEX idx_gold_customer_vip ON gold.customer_360(is_vip);
GO

PRINT 'Customer 360° table created!';
SELECT TOP 10 * FROM gold.customer_360 ORDER BY lifetime_value DESC;
GO
