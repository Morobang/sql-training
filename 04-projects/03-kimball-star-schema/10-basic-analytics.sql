-- ============================================================================
-- Basic Analytics Queries
-- ============================================================================
-- Demonstrate the power of star schema for business analysis
-- Simple joins, fast queries, business-friendly
-- ============================================================================

USE RetailChain_DW;

-- ============================================================================
-- REVENUE ANALYSIS
-- ============================================================================

-- Total Revenue by Month
SELECT 
    d.year_number,
    d.month_name,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    SUM(f.quantity_sold) AS total_units_sold,
    CONCAT('$', FORMAT(SUM(f.gross_sales_amount), 2)) AS gross_revenue,
    CONCAT('$', FORMAT(SUM(f.discount_amount), 2)) AS total_discounts,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS net_revenue,
    CONCAT('$', FORMAT(SUM(f.gross_profit_amount), 2)) AS gross_profit,
    CONCAT(ROUND(AVG(f.profit_margin_percent), 2), '%') AS avg_profit_margin,
    CONCAT('$', FORMAT(AVG(f.total_amount), 2)) AS avg_transaction_value
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year_number, d.month_number, d.month_name
ORDER BY d.year_number, d.month_number;

-- Daily Sales Trend (Last 30 Days)
SELECT 
    d.full_date,
    d.day_of_week_name,
    d.is_weekend,
    d.is_holiday,
    d.holiday_name,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount) / COUNT(DISTINCT f.transaction_id), 2)) AS avg_transaction
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
WHERE d.full_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY d.full_date, d.day_of_week_name, d.is_weekend, d.is_holiday, d.holiday_name
ORDER BY d.full_date;

-- Revenue by Day of Week
SELECT 
    d.day_of_week_name,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS total_revenue,
    CONCAT('$', FORMAT(AVG(f.total_amount), 2)) AS avg_transaction_value,
    ROUND(SUM(f.net_sales_amount) * 100.0 / (SELECT SUM(net_sales_amount) FROM fact_sales), 2) AS pct_of_total_revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.day_of_week, d.day_of_week_name
ORDER BY d.day_of_week;

-- ============================================================================
-- PRODUCT ANALYSIS
-- ============================================================================

-- Top 20 Products by Revenue
SELECT 
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(f.gross_profit_amount), 2)) AS profit,
    CONCAT(ROUND(AVG(f.profit_margin_percent), 2), '%') AS avg_margin,
    ROUND(SUM(f.net_sales_amount) * 100.0 / (SELECT SUM(net_sales_amount) FROM fact_sales), 2) AS pct_of_total
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_name, p.category, p.subcategory, p.brand
ORDER BY SUM(f.net_sales_amount) DESC
LIMIT 20;

-- Revenue by Product Category
SELECT 
    p.category,
    p.department,
    COUNT(DISTINCT p.product_key) AS product_count,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(f.gross_profit_amount), 2)) AS profit,
    CONCAT(ROUND(AVG(f.profit_margin_percent), 2), '%') AS avg_margin,
    ROUND(SUM(f.net_sales_amount) * 100.0 / (SELECT SUM(net_sales_amount) FROM fact_sales), 2) AS pct_of_total
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category, p.department
ORDER BY SUM(f.net_sales_amount) DESC;

-- Brand Performance
SELECT 
    p.brand,
    COUNT(DISTINCT p.product_key) AS products,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(AVG(f.unit_price), 2)) AS avg_price_point,
    CONCAT(ROUND(AVG(f.profit_margin_percent), 2), '%') AS avg_margin
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.brand
ORDER BY SUM(f.net_sales_amount) DESC
LIMIT 15;

-- ============================================================================
-- STORE ANALYSIS
-- ============================================================================

-- Top 20 Stores by Revenue
SELECT 
    s.store_name,
    s.city,
    s.state_province,
    s.region,
    s.store_format,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount) / COUNT(DISTINCT f.transaction_id), 2)) AS avg_transaction,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount) / s.square_footage, 2)) AS revenue_per_sqft
FROM fact_sales f
JOIN dim_store s ON f.store_key = s.store_key
GROUP BY s.store_key, s.store_name, s.city, s.state_province, s.region, s.store_format, s.square_footage
ORDER BY SUM(f.net_sales_amount) DESC
LIMIT 20;

-- Revenue by Region
SELECT 
    s.region,
    COUNT(DISTINCT s.store_key) AS store_count,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(f.gross_profit_amount), 2)) AS profit,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount) / COUNT(DISTINCT s.store_key), 2)) AS avg_revenue_per_store
FROM fact_sales f
JOIN dim_store s ON f.store_key = s.store_key
GROUP BY s.region
ORDER BY SUM(f.net_sales_amount) DESC;

-- Store Format Performance
SELECT 
    s.store_format,
    COUNT(DISTINCT s.store_key) AS store_count,
    ROUND(AVG(s.square_footage), 0) AS avg_sqft,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS total_revenue,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount) / COUNT(DISTINCT s.store_key), 2)) AS revenue_per_store,
    CONCAT('$', FORMAT(AVG(f.total_amount), 2)) AS avg_transaction_value
FROM fact_sales f
JOIN dim_store s ON f.store_key = s.store_key
GROUP BY s.store_format
ORDER BY SUM(f.net_sales_amount) DESC;

-- ============================================================================
-- CUSTOMER ANALYSIS
-- ============================================================================

-- Customer Segment Performance
SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_key) AS customer_count,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS total_revenue,
    CONCAT('$', FORMAT(AVG(f.total_amount), 2)) AS avg_transaction_value,
    ROUND(COUNT(DISTINCT f.transaction_id) * 1.0 / COUNT(DISTINCT c.customer_key), 2) AS avg_transactions_per_customer
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key > 0  -- Exclude unknown customers
GROUP BY c.customer_segment
ORDER BY SUM(f.net_sales_amount) DESC;

-- Loyalty Tier Analysis
SELECT 
    c.loyalty_tier,
    COUNT(DISTINCT c.customer_key) AS customers,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount) / COUNT(DISTINCT c.customer_key), 2)) AS revenue_per_customer,
    SUM(f.loyalty_points_earned) AS total_loyalty_points
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key > 0
GROUP BY c.loyalty_tier
ORDER BY SUM(f.net_sales_amount) DESC;

-- Top 20 Customers by Revenue
SELECT 
    c.customer_id,
    c.full_name,
    c.customer_segment,
    c.loyalty_tier,
    c.region,
    COUNT(DISTINCT f.transaction_id) AS total_purchases,
    SUM(f.quantity_sold) AS units_bought,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS lifetime_value,
    CONCAT('$', FORMAT(AVG(f.total_amount), 2)) AS avg_order_value,
    SUM(f.loyalty_points_earned) AS total_points
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key > 0
GROUP BY c.customer_key, c.customer_id, c.full_name, c.customer_segment, c.loyalty_tier, c.region
ORDER BY SUM(f.net_sales_amount) DESC
LIMIT 20;

-- ============================================================================
-- PAYMENT & PROMOTION ANALYSIS
-- ============================================================================

-- Revenue by Payment Method
SELECT 
    f.payment_method,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS revenue,
    CONCAT('$', FORMAT(AVG(f.total_amount), 2)) AS avg_transaction,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_sales), 2) AS pct_of_transactions
FROM fact_sales f
GROUP BY f.payment_method
ORDER BY SUM(f.net_sales_amount) DESC;

-- Promotion Effectiveness
SELECT 
    COALESCE(f.promotion_applied, 'No Promotion') AS promotion,
    COUNT(DISTINCT f.transaction_id) AS transactions,
    SUM(f.quantity_sold) AS units_sold,
    CONCAT('$', FORMAT(SUM(f.gross_sales_amount), 2)) AS gross_sales,
    CONCAT('$', FORMAT(SUM(f.discount_amount), 2)) AS discounts,
    CONCAT('$', FORMAT(SUM(f.net_sales_amount), 2)) AS net_sales,
    CONCAT('$', FORMAT(AVG(f.discount_amount), 2)) AS avg_discount,
    ROUND(SUM(f.discount_amount) * 100.0 / NULLIF(SUM(f.gross_sales_amount), 0), 2) AS discount_rate
FROM fact_sales f
GROUP BY f.promotion_applied
ORDER BY SUM(f.net_sales_amount) DESC;

-- Returns Analysis
SELECT 
    d.month_name,
    COUNT(DISTINCT CASE WHEN f.is_return THEN f.transaction_id END) AS return_transactions,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    ROUND(COUNT(DISTINCT CASE WHEN f.is_return THEN f.transaction_id END) * 100.0 / 
          COUNT(DISTINCT f.transaction_id), 2) AS return_rate,
    CONCAT('$', FORMAT(SUM(CASE WHEN f.is_return THEN f.net_sales_amount ELSE 0 END), 2)) AS return_value
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year_number, d.month_number, d.month_name
ORDER BY d.year_number, d.month_number;

/*
============================================================================
BASIC ANALYTICS COMPLETE!
============================================================================

✅ Revenue analysis (daily, monthly, by day of week)
✅ Product analysis (top sellers, categories, brands)
✅ Store analysis (regions, formats, top stores)
✅ Customer analysis (segments, loyalty, top customers)
✅ Payment and promotion analysis

KEY INSIGHTS FROM STAR SCHEMA:
1. Simple Joins: Only 1-2 joins per query (fact → dimension)
2. Fast Performance: Indexed foreign keys enable quick aggregation
3. Business-Friendly: Non-technical users can understand queries
4. Flexible: Easy to add new dimensions or measures
5. Scalable: Handles millions of fact rows efficiently

COMPARE TO NORMALIZED (3NF) DATABASE:
- Normalized: 5-10 joins typical, complex queries
- Star Schema: 1-3 joins typical, simple queries
- Result: 10-100x faster query performance!

Next: 11-time-intelligence.sql (advanced date analysis)
============================================================================
*/
