# Kimball Star Schema - Execution Guide

## Quick Start (5 Minutes)

Execute these files in order to build the complete data warehouse:

### Step 1: Foundation (1 minute)
```sql
-- Run in MySQL Workbench or command line
SOURCE 01-kimball-setup.sql;
```
**Creates**: Database, metadata tables, helper functions

### Step 2: Dimension Tables (2 minutes)
```sql
SOURCE 02-create-dim-date.sql;      -- 4,018 dates (2020-2030)
SOURCE 03-create-dim-store.sql;     -- 500 stores
SOURCE 04-create-dim-product.sql;   -- 1,000 products
SOURCE 05-create-dim-customer.sql;  -- 10,000 customers
```
**Creates**: All dimension tables with sample data

### Step 3: Fact Tables (30 seconds)
```sql
SOURCE 06-create-fact-sales.sql;      -- Sales fact table structure
SOURCE 07-create-fact-inventory.sql;  -- Inventory fact table structure
```
**Creates**: Fact table structures (empty, ready for data)

### Step 4: Load Data (2-3 minutes)
```sql
SOURCE 08-load-sales-data.sql;
```
**Loads**: 20,000 transactions → ~80,000 sales fact rows
**Note**: This takes 2-3 minutes to generate realistic data

### Step 5: Analytics & Views (30 seconds)
```sql
SOURCE 10-basic-analytics.sql;   -- Run analytical queries
SOURCE 14-scd-type2.sql;         -- Price change examples
SOURCE 16-dashboard-views.sql;   -- Create BI views
```
**Creates**: 6 pre-built views for Power BI/Tableau

---

## Verification Checklist

After running all scripts, verify your data warehouse:

```sql
-- 1. Check all tables exist
SHOW TABLES FROM RetailChain_DW;
-- Should show: dim_date, dim_store, dim_product, dim_customer, 
--              fact_sales, fact_inventory, metadata tables

-- 2. Check row counts
SELECT 'dim_date' AS table_name, COUNT(*) AS rows FROM dim_date
UNION ALL
SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;

-- Expected results:
-- dim_date: ~4,018 rows
-- dim_store: 501 rows (500 + 1 unknown member)
-- dim_product: 1,001 rows (1,000 + 1 unknown member)
-- dim_customer: 10,001 rows (10,000 + 1 unknown member)
-- fact_sales: ~80,000 rows

-- 3. Test a simple query
SELECT 
    d.month_name,
    COUNT(*) AS sales_count,
    SUM(f.net_sales_amount) AS revenue
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.month_number, d.month_name
ORDER BY d.month_number;

-- 4. Check views exist
SHOW FULL TABLES FROM RetailChain_DW WHERE table_type = 'VIEW';
-- Should show 6 views: vw_sales_dashboard, vw_product_performance, etc.
```

---

## File Summary

| File | Description | Execution Time | Output |
|------|-------------|----------------|--------|
| `01-kimball-setup.sql` | Database & metadata | 5 seconds | RetailChain_DW database |
| `02-create-dim-date.sql` | Date dimension | 10 seconds | 4,018 date records |
| `03-create-dim-store.sql` | Store dimension | 5 seconds | 501 store records |
| `04-create-dim-product.sql` | Product dimension | 10 seconds | 1,001 product records |
| `05-create-dim-customer.sql` | Customer dimension | 20 seconds | 10,001 customer records |
| `06-create-fact-sales.sql` | Sales fact structure | 2 seconds | Empty fact table |
| `07-create-fact-inventory.sql` | Inventory fact structure | 2 seconds | Empty fact table |
| `08-load-sales-data.sql` | Generate sales data | **2-3 minutes** | ~80,000 sales records |
| `10-basic-analytics.sql` | Run analytics queries | 5 seconds | Query results |
| `14-scd-type2.sql` | SCD Type 2 examples | 5 seconds | Price change tracking |
| `16-dashboard-views.sql` | Create BI views | 3 seconds | 6 views created |

**Total Execution Time**: ~5 minutes

---

## Troubleshooting

### Issue: "Unknown database RetailChain_DW"
**Solution**: Run `01-kimball-setup.sql` first

### Issue: "Table doesn't exist"
**Solution**: Run files in order (01 → 02 → 03 → etc.)

### Issue: "Foreign key constraint fails"
**Solution**: Ensure dimension tables are loaded before fact tables

### Issue: "Function fn_date_to_datekey doesn't exist"
**Solution**: Run `01-kimball-setup.sql` which creates helper functions

### Issue: Data loading is slow
**Solution**: 
- File `08-load-sales-data.sql` intentionally generates realistic data
- Takes 2-3 minutes to create 80,000+ records
- This is normal - grab coffee! ☕

---

## What Each File Does

### Foundation Files
- **01-kimball-setup.sql**: Creates database, metadata infrastructure, helper functions
  - `metadata_etl_log`: Tracks all data loads
  - `metadata_data_quality`: Monitors data quality
  - `metadata_business_rules`: Documents validation rules
  - `fn_date_to_datekey()`: Converts DATE → YYYYMMDD integer
  - `fn_datekey_to_date()`: Converts YYYYMMDD → DATE

### Dimension Files (The "Who, What, When, Where")
- **02-create-dim-date.sql**: Calendar dimension with:
  - 11 years of dates (2020-2030)
  - Day/week/month/quarter/year attributes
  - Fiscal periods, holidays, business day indicators
  - **Most important dimension** - used by all facts

- **03-create-dim-store.sql**: Store locations with:
  - 500 stores across 4 regions
  - Geographic hierarchy (Region → District → Market → Store)
  - Store formats (Superstore, Standard, Express, Outlet)
  - SCD Type 1 (overwrites changes)

- **04-create-dim-product.sql**: Product catalog with:
  - 1,000 products across 3 categories
  - Product hierarchy (Category → Subcategory → Department)
  - **SCD Type 2** for price tracking
  - Multiple versions per product for historical accuracy

- **05-create-dim-customer.sql**: Customer demographics with:
  - 10,000 customers
  - Demographics (age, gender, location)
  - Segmentation (VIP, Regular, Occasional, New)
  - Loyalty tiers (Platinum, Gold, Silver, Bronze)

### Fact Files (The "How Many, How Much")
- **06-create-fact-sales.sql**: Transaction-level sales
  - Atomic grain: One row per product per transaction
  - Foreign keys to all 4 dimensions
  - 15+ measures (quantity, amounts, profit, margin)
  - Degenerate dimensions (transaction_id)

- **07-create-fact-inventory.sql**: Daily inventory snapshots
  - Periodic snapshot grain: One row per product per store per day
  - Semi-additive facts (inventory levels)
  - Inventory metrics (days of supply, reorder points)

### Data Loading Files
- **08-load-sales-data.sql**: Generates realistic sales data
  - 20,000 transactions
  - ~80,000 line items (avg 4 items per transaction)
  - Realistic patterns: quantities, prices, discounts, returns
  - Payment methods, promotions, timestamps

### Analytics Files
- **10-basic-analytics.sql**: Pre-built analytical queries
  - Revenue analysis (daily, monthly, by segment)
  - Product performance (top sellers, categories, brands)
  - Store performance (regions, formats, rankings)
  - Customer analysis (segments, loyalty, top customers)
  - **Copy these queries for your own analysis!**

- **14-scd-type2.sql**: Slowly Changing Dimension examples
  - Stored procedure to create price changes
  - Example price updates with reasons
  - Historical price tracking queries
  - Point-in-time queries (prices on specific dates)
  - Revenue impact analysis

- **16-dashboard-views.sql**: BI-ready views
  - `vw_sales_dashboard`: Denormalized sales data for Power BI
  - `vw_product_performance`: Product metrics summary
  - `vw_store_performance`: Store metrics summary
  - `vw_customer_summary`: Customer lifetime value
  - `vw_monthly_sales_summary`: Pre-aggregated monthly data
  - `vw_customer_rfm`: RFM segmentation (Recency, Frequency, Monetary)

---

## Next Steps After Execution

### 1. Explore the Data
```sql
-- Run queries from 10-basic-analytics.sql
-- Experiment with your own queries
-- Try joining facts to different dimensions
```

### 2. Connect a BI Tool
- **Power BI**: Get Data → MySQL → Select views
- **Tableau**: Connect to MySQL → Import vw_sales_dashboard
- **Excel**: Power Query → MySQL → Load to pivot table

### 3. Experiment with SCD Type 2
```sql
-- Create a price change
CALL sp_update_product_price('PROD-000001', 599.99, '2024-12-01', 'Holiday sale');

-- View price history
SELECT * FROM dim_product WHERE product_id = 'PROD-000001' ORDER BY version_number;
```

### 4. Build Your Own Analyses
Example ideas:
- Customer cohort analysis (signup month → lifetime value)
- Store cannibalization (new store impact on nearby stores)
- Product affinity (what products sell together)
- Seasonal patterns (holiday vs non-holiday sales)
- Promotion effectiveness (sales lift from promotions)

---

## Performance Tips

For production use with larger datasets:

1. **Add More Indexes**
```sql
-- Add indexes on frequently filtered columns
CREATE INDEX idx_sales_timestamp ON fact_sales(transaction_timestamp);
CREATE INDEX idx_customer_segment ON dim_customer(customer_segment);
```

2. **Create Aggregate Tables**
```sql
-- Pre-calculate monthly summaries
CREATE TABLE fact_sales_monthly AS
SELECT 
    date_key, store_key, product_key,
    SUM(quantity_sold) AS total_quantity,
    SUM(net_sales_amount) AS total_sales
FROM fact_sales
GROUP BY date_key, store_key, product_key;
```

3. **Partition Large Tables**
```sql
-- Partition by year (MySQL 8.0+)
ALTER TABLE fact_sales 
PARTITION BY RANGE (YEAR(transaction_timestamp)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025)
);
```

4. **Materialize Views**
```sql
-- Create physical tables from views for better performance
CREATE TABLE tbl_sales_dashboard AS SELECT * FROM vw_sales_dashboard;
```

---

## Success Criteria

You've successfully completed the project when:

✅ All 13 files execute without errors  
✅ Database contains 500+ stores, 1000+ products, 10,000+ customers  
✅ Fact tables contain 80,000+ sales records  
✅ Sample queries return results in < 1 second  
✅ Views are accessible from BI tools  
✅ You can explain the star schema design to others  

**Congratulations! You've built an enterprise-grade dimensional data warehouse!** 🎉

---

## Resources

- **README.md**: Project overview and learning objectives
- **PROJECT-SUMMARY.md**: Complete project documentation
- **SQL Files**: All implementation scripts with inline documentation

**Questions?** Review the inline comments in each SQL file - they explain every concept!

**Ready to learn more?** Check out the other projects:
- **01-data-warehouse-medallion**: Bronze → Silver → Gold ETL pipeline
- **02-data-vault-banking**: Hub-Link-Satellite compliance architecture
