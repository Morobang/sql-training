-- ========================================
-- Gold: Product Performance Analytics
-- ========================================

USE TechStore_Warehouse;
GO

IF OBJECT_ID('gold.product_performance', 'U') IS NOT NULL
    DROP TABLE gold.product_performance;
GO

CREATE TABLE gold.product_performance (
    product_key INT PRIMARY KEY,
    product_id VARCHAR(50),
    product_name VARCHAR(200),
    category VARCHAR(100),
    
    -- Sales metrics
    units_sold INT,
    total_revenue DECIMAL(18,2),
    total_profit DECIMAL(18,2),
    avg_unit_price DECIMAL(10,2),
    
    -- Profitability
    cost_price DECIMAL(10,2),
    sell_price DECIMAL(10,2),
    profit_margin_pct DECIMAL(5,2),
    
    -- Inventory metrics
    current_stock INT,
    reorder_level INT,
    stock_status VARCHAR(20),  -- In-Stock, Low-Stock, Out-of-Stock
    days_of_stock_remaining INT,
    
    -- Rankings
    revenue_rank INT,
    units_sold_rank INT,
    profit_rank INT,
    
    gold_created_at DATETIME DEFAULT GETDATE()
);
GO

WITH product_sales AS (
    SELECT 
        p.product_key,
        p.product_id,
        p.product_name,
        p.category,
        p.cost_price,
        p.sell_price,
        p.stock_quantity,
        p.reorder_level,
        
        -- Sales aggregations
        COALESCE(SUM(o.quantity), 0) AS units_sold,
        COALESCE(SUM(o.total_amount), 0) AS total_revenue,
        COALESCE(AVG(o.unit_price), p.sell_price) AS avg_unit_price
        
    FROM silver.products p
    LEFT JOIN silver.orders o ON p.product_key = o.product_key
    GROUP BY 
        p.product_key, p.product_id, p.product_name, p.category,
        p.cost_price, p.sell_price, p.stock_quantity, p.reorder_level
),
with_profit AS (
    SELECT 
        *,
        (sell_price - cost_price) * units_sold AS total_profit,
        CASE 
            WHEN sell_price > 0 
            THEN ((sell_price - cost_price) / sell_price * 100)
            ELSE 0
        END AS profit_margin_pct,
        
        -- Stock status
        CASE 
            WHEN stock_quantity = 0 THEN 'Out-of-Stock'
            WHEN stock_quantity <= reorder_level THEN 'Low-Stock'
            ELSE 'In-Stock'
        END AS stock_status,
        
        -- Days of stock (assuming avg 10 units/day sold)
        CASE 
            WHEN units_sold > 0 
            THEN stock_quantity / (units_sold / 365.0)
            ELSE 999
        END AS days_of_stock
    FROM product_sales
)
INSERT INTO gold.product_performance
SELECT 
    product_key,
    product_id,
    product_name,
    category,
    units_sold,
    total_revenue,
    total_profit,
    avg_unit_price,
    cost_price,
    sell_price,
    profit_margin_pct,
    stock_quantity,
    reorder_level,
    stock_status,
    CAST(days_of_stock AS INT),
    
    -- Rankings
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    ROW_NUMBER() OVER (ORDER BY units_sold DESC) AS units_sold_rank,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank,
    
    GETDATE()
FROM with_profit;
GO

PRINT 'Product performance analytics complete!';
SELECT TOP 10 
    product_name,
    category,
    units_sold,
    total_revenue,
    profit_margin_pct,
    stock_status
FROM gold.product_performance
ORDER BY total_revenue DESC;
GO
