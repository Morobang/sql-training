-- ========================================
-- Gold: Executive Dashboard View
-- ========================================
-- Purpose: Single view with all key metrics for leadership
-- ========================================

USE TechStore_Warehouse;
GO

IF OBJECT_ID('gold.vw_executive_dashboard', 'V') IS NOT NULL
    DROP VIEW gold.vw_executive_dashboard;
GO

CREATE VIEW gold.vw_executive_dashboard AS
WITH current_month AS (
    SELECT 
        SUM(total_amount) AS current_month_revenue,
        COUNT(DISTINCT order_id) AS current_month_orders,
        COUNT(DISTINCT customer_key) AS current_month_customers
    FROM silver.orders
    WHERE YEAR(order_date) = YEAR(GETDATE())
      AND MONTH(order_date) = MONTH(GETDATE())
),
prior_month AS (
    SELECT 
        SUM(total_amount) AS prior_month_revenue,
        COUNT(DISTINCT order_id) AS prior_month_orders,
        COUNT(DISTINCT customer_key) AS prior_month_customers
    FROM silver.orders
    WHERE YEAR(order_date) = YEAR(DATEADD(MONTH, -1, GETDATE()))
      AND MONTH(order_date) = MONTH(DATEADD(MONTH, -1, GETDATE()))
),
ytd AS (
    SELECT 
        SUM(total_amount) AS ytd_revenue,
        COUNT(DISTINCT order_id) AS ytd_orders,
        COUNT(DISTINCT customer_key) AS ytd_customers
    FROM silver.orders
    WHERE YEAR(order_date) = YEAR(GETDATE())
)
SELECT 
    -- Current Month
    COALESCE(cm.current_month_revenue, 0) AS current_month_revenue,
    COALESCE(cm.current_month_orders, 0) AS current_month_orders,
    COALESCE(cm.current_month_customers, 0) AS current_month_customers,
    
    -- Prior Month
    COALESCE(pm.prior_month_revenue, 0) AS prior_month_revenue,
    COALESCE(pm.prior_month_orders, 0) AS prior_month_orders,
    
    -- Growth
    COALESCE((cm.current_month_revenue - pm.prior_month_revenue) / NULLIF(pm.prior_month_revenue, 0) * 100, 0) AS revenue_growth_pct,
    
    -- YTD
    COALESCE(ytd.ytd_revenue, 0) AS ytd_revenue,
    COALESCE(ytd.ytd_orders, 0) AS ytd_orders,
    COALESCE(ytd.ytd_customers, 0) AS ytd_customers,
    
    -- Customer Metrics
    (SELECT COUNT(*) FROM gold.customer_360 WHERE customer_status = 'Active') AS active_customers,
    (SELECT COUNT(*) FROM gold.customer_360 WHERE is_vip = 1) AS vip_customers,
    (SELECT AVG(lifetime_value) FROM gold.customer_360) AS avg_customer_ltv,
    
    -- Product Metrics
    (SELECT COUNT(*) FROM silver.products WHERE is_active = 1) AS active_products,
    (SELECT COUNT(*) FROM gold.product_performance WHERE stock_status = 'Low-Stock') AS low_stock_products,
    (SELECT COUNT(*) FROM gold.product_performance WHERE stock_status = 'Out-of-Stock') AS out_of_stock_products,
    
    GETDATE() AS report_generated_at
FROM current_month cm
CROSS JOIN prior_month pm
CROSS JOIN ytd;
GO

PRINT 'Executive dashboard view created!';
SELECT * FROM gold.vw_executive_dashboard;
GO

PRINT '';
PRINT '========================================';
PRINT 'GOLD LAYER COMPLETE!';
PRINT '========================================';
PRINT 'Tables Created:';
PRINT '✓ gold.customer_360 - Complete customer profiles';
PRINT '✓ gold.customer_rfm - RFM segmentation';
PRINT '✓ gold.product_performance - Product analytics';
PRINT '✓ gold.monthly_sales - Time-series trends';
PRINT '✓ gold.vw_executive_dashboard - Executive KPIs';
PRINT '';
PRINT 'Ready for BI Tools:';
PRINT '→ Connect Power BI to these tables/views';
PRINT '→ Build Tableau dashboards';
PRINT '→ Export to Excel for ad-hoc analysis';
PRINT '========================================';
GO
