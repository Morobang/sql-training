-- ============================================================================
-- Dashboard Views for BI Tools
-- ============================================================================
-- Pre-built views optimized for Power BI, Tableau, Looker
-- Denormalized, performant, business-friendly
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- VIEW 1: Sales Dashboard (Daily Metrics)
-- ============================================================================

DROP VIEW IF EXISTS vw_sales_dashboard;

CREATE VIEW vw_sales_dashboard AS
SELECT 
    -- Date Attributes
    d.full_date AS sale_date,
    d.year_number AS sale_year,
    d.quarter_number AS sale_quarter,
    d.month_number AS sale_month,
    d.month_name,
    d.day_of_week,
    d.day_of_week_name,
    d.is_weekend,
    d.is_holiday,
    d.holiday_name,
    
    -- Store Attributes
    s.store_id,
    s.store_name,
    s.store_format,
    s.city AS store_city,
    s.state_province AS store_state,
    s.region AS store_region,
    s.district AS store_district,
    
    -- Product Attributes
    p.product_id,
    p.product_name,
    p.category AS product_category,
    p.subcategory AS product_subcategory,
    p.brand AS product_brand,
    p.department AS product_department,
    
    -- Customer Attributes
    c.customer_id,
    c.customer_segment,
    c.loyalty_tier,
    c.region AS customer_region,
    c.age_range AS customer_age,
    c.gender AS customer_gender,
    
    -- Transaction Attributes
    f.transaction_id,
    f.payment_method,
    f.promotion_applied,
    f.is_return,
    
    -- Measures
    f.quantity_sold,
    f.gross_sales_amount,
    f.discount_amount,
    f.net_sales_amount,
    f.tax_amount,
    f.total_amount,
    f.cost_amount,
    f.gross_profit_amount,
    f.profit_margin_percent,
    f.loyalty_points_earned
    
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_store s ON f.store_key = s.store_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_customer c ON f.customer_key = c.customer_key;

-- Test the view
SELECT * FROM vw_sales_dashboard LIMIT 10;

-- ============================================================================
-- VIEW 2: Product Performance Summary
-- ============================================================================

DROP VIEW IF EXISTS vw_product_performance;

CREATE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.department,
    p.unit_price AS current_price,
    p.unit_cost AS current_cost,
    p.is_active,
    
    -- Aggregated Metrics
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    SUM(f.quantity_sold) AS total_units_sold,
    SUM(f.net_sales_amount) AS total_revenue,
    SUM(f.gross_profit_amount) AS total_profit,
    AVG(f.profit_margin_percent) AS avg_profit_margin,
    
    -- Calculated Metrics
    SUM(f.net_sales_amount) / NULLIF(SUM(f.quantity_sold), 0) AS avg_selling_price,
    SUM(f.discount_amount) / NULLIF(SUM(f.gross_sales_amount), 0) * 100 AS avg_discount_rate
    
FROM dim_product p
LEFT JOIN fact_sales f ON p.product_key = f.product_key
WHERE p.is_current = TRUE
GROUP BY 
    p.product_id, p.product_name, p.category, p.subcategory,
    p.brand, p.department, p.unit_price, p.unit_cost, p.is_active;

-- Test the view
SELECT * FROM vw_product_performance ORDER BY total_revenue DESC LIMIT 10;

-- ============================================================================
-- VIEW 3: Store Performance Summary
-- ============================================================================

DROP VIEW IF EXISTS vw_store_performance;

CREATE VIEW vw_store_performance AS
SELECT 
    s.store_id,
    s.store_name,
    s.store_format,
    s.city,
    s.state_province,
    s.region,
    s.district,
    s.square_footage,
    s.is_active,
    
    -- Aggregated Metrics
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
    SUM(f.quantity_sold) AS total_units_sold,
    SUM(f.net_sales_amount) AS total_revenue,
    SUM(f.gross_profit_amount) AS total_profit,
    
    -- Calculated Metrics
    SUM(f.net_sales_amount) / NULLIF(COUNT(DISTINCT f.transaction_id), 0) AS avg_transaction_value,
    SUM(f.net_sales_amount) / NULLIF(s.square_footage, 0) AS revenue_per_sqft,
    SUM(f.gross_profit_amount) / NULLIF(SUM(f.net_sales_amount), 0) * 100 AS profit_margin_pct
    
FROM dim_store s
LEFT JOIN fact_sales f ON s.store_key = f.store_key
GROUP BY 
    s.store_id, s.store_name, s.store_format, s.city, s.state_province,
    s.region, s.district, s.square_footage, s.is_active;

-- Test the view
SELECT * FROM vw_store_performance ORDER BY total_revenue DESC LIMIT 10;

-- ============================================================================
-- VIEW 4: Customer Summary
-- ============================================================================

DROP VIEW IF EXISTS vw_customer_summary;

CREATE VIEW vw_customer_summary AS
SELECT 
    c.customer_id,
    c.full_name,
    c.email,
    c.customer_segment,
    c.loyalty_tier,
    c.region,
    c.city,
    c.state_province,
    c.age_range,
    c.gender,
    c.registration_date,
    c.is_active,
    
    -- Purchase Metrics
    COUNT(DISTINCT f.transaction_id) AS total_purchases,
    SUM(f.quantity_sold) AS total_items_bought,
    SUM(f.net_sales_amount) AS lifetime_value,
    SUM(f.gross_profit_amount) AS total_profit_generated,
    MAX(d.full_date) AS last_purchase_date,
    MIN(d.full_date) AS first_purchase_date,
    DATEDIFF(CURDATE(), MAX(d.full_date)) AS days_since_last_purchase,
    
    -- Calculated Metrics
    SUM(f.net_sales_amount) / NULLIF(COUNT(DISTINCT f.transaction_id), 0) AS avg_order_value,
    SUM(f.loyalty_points_earned) AS total_loyalty_points
    
FROM dim_customer c
LEFT JOIN fact_sales f ON c.customer_key = f.customer_key
LEFT JOIN dim_date d ON f.date_key = d.date_key
WHERE c.customer_key > 0  -- Exclude unknown customers
GROUP BY 
    c.customer_id, c.full_name, c.email, c.customer_segment, c.loyalty_tier,
    c.region, c.city, c.state_province, c.age_range, c.gender,
    c.registration_date, c.is_active;

-- Test the view
SELECT * FROM vw_customer_summary ORDER BY lifetime_value DESC LIMIT 10;

-- ============================================================================
-- VIEW 5: Monthly Sales Summary (Pre-Aggregated for Performance)
-- ============================================================================

DROP VIEW IF EXISTS vw_monthly_sales_summary;

CREATE VIEW vw_monthly_sales_summary AS
SELECT 
    d.year_number,
    d.month_number,
    d.month_name,
    s.region,
    s.store_format,
    p.category,
    
    -- Aggregated Metrics
    COUNT(DISTINCT f.transaction_id) AS transactions,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
    SUM(f.quantity_sold) AS units_sold,
    SUM(f.gross_sales_amount) AS gross_sales,
    SUM(f.discount_amount) AS discounts,
    SUM(f.net_sales_amount) AS net_sales,
    SUM(f.tax_amount) AS sales_tax,
    SUM(f.total_amount) AS total_amount,
    SUM(f.cost_amount) AS total_cost,
    SUM(f.gross_profit_amount) AS gross_profit,
    AVG(f.profit_margin_percent) AS avg_margin
    
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_store s ON f.store_key = s.store_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY 
    d.year_number, d.month_number, d.month_name,
    s.region, s.store_format, p.category;

-- Test the view
SELECT * FROM vw_monthly_sales_summary 
ORDER BY year_number, month_number 
LIMIT 20;

-- ============================================================================
-- VIEW 6: RFM Analysis (Recency, Frequency, Monetary)
-- ============================================================================

DROP VIEW IF EXISTS vw_customer_rfm;

CREATE VIEW vw_customer_rfm AS
SELECT 
    c.customer_id,
    c.full_name,
    c.customer_segment,
    c.loyalty_tier,
    
    -- Recency (days since last purchase)
    DATEDIFF(CURDATE(), MAX(d.full_date)) AS recency_days,
    CASE 
        WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 30 THEN 5
        WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 60 THEN 4
        WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 90 THEN 3
        WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 180 THEN 2
        ELSE 1
    END AS recency_score,
    
    -- Frequency (number of purchases)
    COUNT(DISTINCT f.transaction_id) AS frequency_count,
    CASE 
        WHEN COUNT(DISTINCT f.transaction_id) >= 20 THEN 5
        WHEN COUNT(DISTINCT f.transaction_id) >= 10 THEN 4
        WHEN COUNT(DISTINCT f.transaction_id) >= 5 THEN 3
        WHEN COUNT(DISTINCT f.transaction_id) >= 2 THEN 2
        ELSE 1
    END AS frequency_score,
    
    -- Monetary (total spend)
    SUM(f.net_sales_amount) AS monetary_value,
    CASE 
        WHEN SUM(f.net_sales_amount) >= 5000 THEN 5
        WHEN SUM(f.net_sales_amount) >= 2000 THEN 4
        WHEN SUM(f.net_sales_amount) >= 1000 THEN 3
        WHEN SUM(f.net_sales_amount) >= 500 THEN 2
        ELSE 1
    END AS monetary_score,
    
    -- Combined RFM Score
    CONCAT(
        CASE 
            WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 30 THEN 5
            WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 60 THEN 4
            WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 90 THEN 3
            WHEN DATEDIFF(CURDATE(), MAX(d.full_date)) <= 180 THEN 2
            ELSE 1
        END,
        CASE 
            WHEN COUNT(DISTINCT f.transaction_id) >= 20 THEN 5
            WHEN COUNT(DISTINCT f.transaction_id) >= 10 THEN 4
            WHEN COUNT(DISTINCT f.transaction_id) >= 5 THEN 3
            WHEN COUNT(DISTINCT f.transaction_id) >= 2 THEN 2
            ELSE 1
        END,
        CASE 
            WHEN SUM(f.net_sales_amount) >= 5000 THEN 5
            WHEN SUM(f.net_sales_amount) >= 2000 THEN 4
            WHEN SUM(f.net_sales_amount) >= 1000 THEN 3
            WHEN SUM(f.net_sales_amount) >= 500 THEN 2
            ELSE 1
        END
    ) AS rfm_score
    
FROM dim_customer c
JOIN fact_sales f ON c.customer_key = f.customer_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE c.customer_key > 0
GROUP BY c.customer_id, c.full_name, c.customer_segment, c.loyalty_tier;

-- Test the view
SELECT * FROM vw_customer_rfm ORDER BY rfm_score DESC LIMIT 20;

/*
============================================================================
DASHBOARD VIEWS COMPLETE!
============================================================================

✅ 6 pre-built views for BI tools
✅ Denormalized for easy drag-and-drop in Power BI/Tableau
✅ Pre-calculated metrics for performance
✅ Business-friendly column names
✅ RFM analysis for customer segmentation

HOW TO USE THESE VIEWS:

1. POWER BI:
   - Connect to MySQL database
   - Import these views (not base tables)
   - Create relationships if needed (though views are denormalized)
   - Build visualizations by dragging fields

2. TABLEAU:
   - Connect to MySQL data source
   - Select these views
   - Create calculated fields as needed
   - Build dashboards

3. EXCEL:
   - Use Power Query to connect
   - Import view data
   - Create pivot tables and charts

4. LOOKER / METABASE / SUPERSET:
   - Point to these views
   - Define dimensions and measures
   - Build dashboards

PERFORMANCE TIPS:
- Views are virtual tables (no storage)
- For better performance on large datasets:
  * Create materialized tables from these views
  * Add indexes on commonly filtered columns
  * Use aggregate tables (monthly summaries)
  * Consider partitioning by date

NEXT STEPS:
1. Connect your BI tool to RetailChain_DW database
2. Import these views
3. Build dashboards for:
   - Executive summary (revenue, profit, trends)
   - Store operations (performance by location)
   - Product analytics (best sellers, inventory)
   - Customer insights (segments, loyalty, RFM)

The star schema makes this EASY!
============================================================================
*/
