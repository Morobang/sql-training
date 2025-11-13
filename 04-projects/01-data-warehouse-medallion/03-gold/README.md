# Phase 3: Gold Layer (Business-Ready Analytics)

## Overview
The Gold layer contains **aggregated, business-ready datasets** optimized for reporting and analytics. This is what business users and dashboards query.

## Objectives
- Create customer summary metrics (lifetime value, RFM scores)
- Build product performance analytics
- Generate time-series sales trends
- Create pre-aggregated tables for fast queries
- Build executive dashboard views

## Files in This Phase

### 1. Setup
- `README.md` (this file) - Gold layer concepts

### 2. Customer Analytics
- `01-customer-360.sql` - Complete customer profile with purchase history
- `02-customer-rfm.sql` - RFM (Recency, Frequency, Monetary) analysis
- `03-customer-segments.sql` - Customer segmentation (VIP, regular, at-risk)

### 3. Product Analytics
- `04-product-performance.sql` - Sales metrics by product
- `05-inventory-analysis.sql` - Stock turnover, reorder alerts

### 4. Sales Analytics
- `06-daily-sales.sql` - Daily sales trends
- `07-monthly-sales.sql` - Monthly aggregations
- `08-sales-by-category.sql` - Category performance

### 5. Executive Dashboards
- `09-executive-summary.sql` - Key metrics for leadership
- `10-create-gold-views.sql` - Materialized views for BI tools

## Gold Layer Patterns

### Pattern 1: Denormalized Fact Tables
```sql
-- Combine dimensions into flat structure for easy querying
SELECT 
    order_date,
    customer_name,
    customer_tier,
    product_name,
    category,
    quantity,
    total_amount
FROM orders
JOIN customers
JOIN products
```

### Pattern 2: Pre-Aggregated Summaries
```sql
-- Daily sales (not recalculated every query)
CREATE TABLE gold_daily_sales AS
SELECT 
    order_date,
    COUNT(*) AS order_count,
    SUM(total_amount) AS revenue
FROM silver_orders
GROUP BY order_date
```

### Pattern 3: Business Metrics
```sql
-- Customer Lifetime Value
SELECT 
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_amount) AS lifetime_value,
    AVG(total_amount) AS avg_order_value
```

### Pattern 4: Time Intelligence
```sql
-- Year-over-year growth
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(total_amount) AS revenue,
    LAG(SUM(total_amount)) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS prev_month,
    (SUM(total_amount) - LAG(SUM(total_amount)) OVER (...)) / LAG(...) * 100 AS growth_pct
```

## Business Metrics Definitions

### Customer Metrics
- **Lifetime Value (LTV)**: Total revenue from customer
- **Average Order Value (AOV)**: Total revenue / order count
- **Recency**: Days since last purchase
- **Frequency**: Number of purchases
- **Monetary**: Total amount spent
- **RFM Score**: Combined 1-5 score for segmentation

### Product Metrics
- **Units Sold**: Total quantity sold
- **Revenue**: Total sales amount
- **Profit Margin**: (sell_price - cost_price) / sell_price
- **Inventory Turnover**: Units sold / avg stock
- **Stock Days**: Current stock / avg daily sales

### Sales Metrics
- **Daily/Monthly Revenue**: Sum of sales
- **Order Count**: Number of transactions
- **AOV**: Revenue / order count
- **Growth Rate**: (Current - Previous) / Previous
- **YoY Growth**: Year-over-year comparison

## Expected Outcomes

After completing this phase:
- ✅ Customer 360° view tables
- ✅ RFM segmentation for marketing
- ✅ Product performance rankings
- ✅ Time-series sales trends
- ✅ Executive dashboard views
- ✅ Ready for Power BI/Tableau connection

## Performance Optimization

Gold tables are query-optimized:
- Pre-aggregated (no GROUP BY needed)
- Denormalized (fewer JOINs)
- Indexed on common filters
- Materialized views for complex calculations

## Next Steps

Connect BI tools to gold layer:
- Power BI → Query gold views
- Tableau → Connect to gold tables
- Excel → Export gold summaries

## Time Estimate
2-3 hours to complete all gold layer files
