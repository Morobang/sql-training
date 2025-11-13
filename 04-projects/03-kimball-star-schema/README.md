# Project 3: Kimball Star Schema - Retail Analytics

## Overview
Build a **Kimball-style dimensional model** (Star Schema) for a retail chain. This is THE standard pattern for business intelligence, analytics, and data visualization. If you're building dashboards in Power BI, Tableau, or Looker - you're using this pattern.

## What You'll Learn
- **Fact tables**: Measurable events (sales, inventory changes)
- **Dimension tables**: Descriptive context (who, what, when, where)
- **Star schema design**: Central fact table surrounded by dimensions
- **Slowly Changing Dimensions (SCD)**: Track historical changes
- **Conformed dimensions**: Share dimensions across fact tables
- **Aggregate tables**: Pre-computed summaries for performance

## Why Kimball vs Data Vault or Medallion?

| Feature | Kimball Star Schema | Data Vault 2.0 | Medallion |
|---------|---------------------|----------------|-----------|
| **Purpose** | Business analytics & BI | Compliance & audit | Data quality ETL |
| **Query Speed** | Fast (1-3 joins) | Slow (5-10 joins) | Medium |
| **Business User Friendly** | Excellent | Poor | Good |
| **Historical Tracking** | Limited (SCD Type 2) | Complete | Snapshot |
| **Schema Complexity** | Simple | Complex | Medium |
| **Best For** | Dashboards, reports | Regulatory | Data pipelines |

## Business Case
You're building an analytics warehouse for **RetailChain**, a company with 500 stores selling electronics, clothing, and home goods. Business users need:
- **Sales dashboards**: Revenue by store, product, time period
- **Inventory reports**: Stock levels, turnover rates
- **Customer analytics**: Purchase patterns, segmentation
- **Executive metrics**: Year-over-year growth, top performers

## Kimball Architecture

### Fact Tables (Measurements)
Store **quantitative metrics** at the lowest grain (transaction level)

**Example: fact_sales**
```sql
CREATE TABLE fact_sales (
    sale_id INT PRIMARY KEY,
    date_key INT,              -- FK to dim_date
    store_key INT,             -- FK to dim_store
    product_key INT,           -- FK to dim_product
    customer_key INT,          -- FK to dim_customer
    -- Measurements
    quantity_sold INT,
    unit_price DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2)
);
```

### Dimension Tables (Context)
Store **descriptive attributes** used for filtering and grouping

**Example: dim_product**
```sql
CREATE TABLE dim_product (
    product_key INT PRIMARY KEY,  -- Surrogate key
    product_id VARCHAR(50),       -- Natural key
    product_name VARCHAR(200),
    category VARCHAR(100),
    brand VARCHAR(100),
    supplier VARCHAR(200),
    cost_price DECIMAL(10,2),
    -- SCD Type 2 columns
    effective_date DATE,
    end_date DATE,
    is_current BIT
);
```

## Project Structure

### Phase 1: Dimension Tables
1. `01-kimball-setup.md` - Understand star schema concepts
2. `02-create-dim-date.sql` - Date dimension (most important!)
3. `03-create-dim-store.sql` - Store locations & attributes
4. `04-create-dim-product.sql` - Product catalog with SCD Type 2
5. `05-create-dim-customer.sql` - Customer demographics

### Phase 2: Fact Tables
6. `06-create-fact-sales.sql` - Sales transactions (main fact)
7. `07-create-fact-inventory.sql` - Inventory snapshots
8. `08-load-dimensions.sql` - Populate dimension tables
9. `09-load-facts.sql` - Populate fact tables

### Phase 3: Analytical Queries
10. `10-basic-analytics.sql` - Revenue by product, store, time
11. `11-time-intelligence.sql` - YoY growth, rolling averages
12. `12-customer-analytics.sql` - RFM analysis, cohorts
13. `13-product-analytics.sql` - Top sellers, inventory turnover

### Phase 4: Advanced Patterns
14. `14-scd-type2.sql` - Handle product price changes over time
15. `15-aggregate-tables.sql` - Pre-compute monthly summaries
16. `16-dashboard-views.sql` - Business-friendly views for BI tools

## Star Schema Visualization

```
         dim_date
             |
             |
dim_store ---+--- fact_sales ---+--- dim_product
             |                   |
             |                   |
        dim_customer         dim_promotion
```

**Simple queries:**
```sql
-- Monthly sales by category
SELECT 
    d.year,
    d.month_name,
    p.category,
    SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY d.year, d.month_name, p.category
ORDER BY d.year, d.month_order, revenue DESC;
```

## Kimball Design Patterns

### Pattern 1: Date Dimension (The Most Important!)
Every fact table needs a date dimension
```sql
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,  -- 20240315 (YYYYMMDD format)
    full_date DATE,
    day_of_week VARCHAR(20),   -- Monday, Tuesday...
    day_name_short CHAR(3),    -- Mon, Tue...
    day_of_month INT,          -- 1-31
    day_of_year INT,           -- 1-366
    week_of_year INT,          -- 1-53
    month_name VARCHAR(20),    -- January, February...
    month_order INT,           -- 1-12
    quarter INT,               -- 1-4
    year INT,                  -- 2024
    is_weekend BIT,
    is_holiday BIT,
    fiscal_year INT,           -- If different from calendar year
    fiscal_quarter INT
);
```

### Pattern 2: Slowly Changing Dimensions (SCD Type 2)
Track historical changes with effective dates
```sql
-- Product price changed from $99.99 to $89.99 on 2024-03-01
product_key | product_id | product_name | price  | effective_date | end_date   | is_current
------------|------------|--------------|--------|----------------|------------|------------
1           | P001       | Laptop       | 99.99  | 2024-01-01     | 2024-02-29 | 0
2           | P001       | Laptop       | 89.99  | 2024-03-01     | 9999-12-31 | 1

-- Query: "What was the price on Feb 15?"
SELECT price 
FROM dim_product
WHERE product_id = 'P001'
  AND '2024-02-15' BETWEEN effective_date AND end_date;  -- Returns 99.99
```

### Pattern 3: Conformed Dimensions
Share dimensions across multiple fact tables
```sql
-- dim_date used by all fact tables
fact_sales       --+
fact_inventory   --+-- dim_date (shared)
fact_returns     --+
```

### Pattern 4: Aggregate Tables (Performance Optimization)
Pre-compute common aggregations
```sql
-- Instead of aggregating 50M rows every query...
CREATE TABLE fact_sales_monthly_agg (
    date_key INT,
    store_key INT,
    product_key INT,
    total_quantity INT,
    total_revenue DECIMAL(18,2),
    avg_transaction_size DECIMAL(10,2)
);
-- Query this table for monthly reports (500K rows vs 50M)
```

## Benefits of Kimball Star Schema

### ✅ **Simple for Business Users**
Easy to understand: "What happened (fact) in what context (dimensions)"

### ✅ **Fast Query Performance**
Minimal joins (3-5 tables) vs Data Vault (10+ tables)

### ✅ **BI Tool Friendly**
Power BI, Tableau, Looker love star schemas

### ✅ **Flexible Analytics**
Slice and dice by any dimension combination

### ✅ **Predictable Patterns**
Every star schema follows same structure

## Challenges & Solutions

### Challenge: Slowly Changing Dimensions
Products change prices, customers move cities

**Solution**: SCD Type 2 with effective dates
```sql
-- When product price changes, INSERT new row (don't UPDATE)
INSERT INTO dim_product (product_id, price, effective_date, is_current)
VALUES ('P001', 89.99, '2024-03-01', 1);

UPDATE dim_product 
SET end_date = '2024-02-29', is_current = 0
WHERE product_id = 'P001' AND is_current = 1;
```

### Challenge: Large Fact Tables
fact_sales can have billions of rows

**Solution**: Partition by date, create aggregates
```sql
-- Partition by year
CREATE TABLE fact_sales (...)
ON date_range_scheme(date_key);

-- Create monthly aggregates for common queries
CREATE TABLE fact_sales_monthly AS
SELECT date_key, store_key, SUM(total_amount)
FROM fact_sales
GROUP BY date_key, store_key;
```

## Industry Use Cases

### Retail (This Project)
- **Sales analysis**: Store performance, product trends
- **Inventory**: Stock levels, reorder alerts
- **Customer**: Purchase patterns, loyalty programs

### E-commerce
- **Web analytics**: Page views, conversions
- **Order analysis**: Cart size, delivery times
- **Marketing**: Campaign effectiveness, channel attribution

### Finance
- **Transaction analysis**: Account activity, fraud detection
- **Customer profitability**: Revenue per customer
- **Risk**: Credit scores, delinquency rates

## Expected Outcomes

By the end of this project:
1. ✅ Build complete star schema with 5 dimensions + 2 facts
2. ✅ Implement SCD Type 2 for historical tracking
3. ✅ Write analytical queries joining facts & dimensions
4. ✅ Create aggregate tables for performance
5. ✅ Understand when to use star schema vs other patterns

## Time Estimate
- Phase 1 (Dimensions): 3-4 hours
- Phase 2 (Facts): 2-3 hours
- Phase 3 (Analytics): 2-3 hours
- Phase 4 (Advanced): 2 hours
- **Total**: 9-12 hours

## Prerequisites
- Complete Medallion Architecture project
- Understand JOINs, GROUP BY, aggregation
- Basic knowledge of BI concepts

## Next Steps
After this project:
- Connect Power BI or Tableau to your star schema
- **Project 4**: CDC Pipeline (real-time data loading)
- **Project 5**: Data Quality Monitoring

Start with `01-kimball-setup.md`!
