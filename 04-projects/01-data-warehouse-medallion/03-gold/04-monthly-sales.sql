-- ========================================
-- Gold: Monthly Sales Trends
-- ========================================

USE TechStore;
GO

IF OBJECT_ID('gold_monthly_sales', 'U') IS NOT NULL
    DROP TABLE gold_monthly_sales;
GO

CREATE TABLE gold_monthly_sales (
    month_key INT PRIMARY KEY IDENTITY,
    year INT,
    month INT,
    month_name VARCHAR(20),
    month_start_date DATE,
    
    -- Sales metrics
    order_count INT,
    unique_customers INT,
    total_revenue DECIMAL(18,2),
    avg_order_value DECIMAL(10,2),
    
    -- Growth metrics
    revenue_vs_prior_month DECIMAL(18,2),
    revenue_growth_pct DECIMAL(5,2),
    
    gold_created_at DATETIME DEFAULT GETDATE()
);
GO

WITH monthly_agg AS (
    SELECT 
        YEAR(order_date) AS year,
        MONTH(order_date) AS month,
        DATENAME(MONTH, order_date) AS month_name,
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month_start,
        COUNT(DISTINCT order_id) AS order_count,
        COUNT(DISTINCT customer_key) AS unique_customers,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value
    FROM silver_orders
    GROUP BY YEAR(order_date), MONTH(order_date), DATENAME(MONTH, order_date)
)
INSERT INTO gold_monthly_sales (
    year, month, month_name, month_start_date,
    order_count, unique_customers, total_revenue, avg_order_value,
    revenue_vs_prior_month, revenue_growth_pct
)
SELECT 
    year,
    month,
    month_name,
    month_start,
    order_count,
    unique_customers,
    total_revenue,
    avg_order_value,
    total_revenue - LAG(total_revenue) OVER (ORDER BY year, month) AS revenue_vs_prior,
    (total_revenue - LAG(total_revenue) OVER (ORDER BY year, month)) 
        / NULLIF(LAG(total_revenue) OVER (ORDER BY year, month), 0) * 100 AS growth_pct
FROM monthly_agg;
GO

PRINT 'Monthly sales trends created!';
SELECT * FROM gold_monthly_sales ORDER BY year DESC, month DESC;
GO
