# Project 1: Data Warehouse (Medallion Architecture)

## Overview
Build a complete data warehouse using the **Medallion Architecture** (Bronze → Silver → Gold) with **professional schema-based organization**. This project teaches you how to transform raw, messy data into clean, business-ready analytics datasets.

## ✨ Architecture Improvements

This project uses **SQL Server schemas** to organize layers - a production best practice:

```sql
TechStore_Warehouse (Database)
├── bronze schema   -- Raw data landing zone
├── silver schema   -- Cleaned & validated data  
├── gold schema     -- Business-ready analytics
└── metadata schema -- Pipeline tracking & data quality logs
```

**Benefits of Schema-Based Architecture:**
- ✅ Clear layer separation (bronze.orders, silver.orders, gold.customer_360)
- ✅ Better security (grant permissions by schema)
- ✅ Easier navigation (schemas appear in object explorer)
- ✅ Production-ready pattern (used at Microsoft, AWS, Databricks)
- ✅ Automated metadata tracking

## What You'll Learn
- **Bronze Layer**: Raw data ingestion (as-is from source)
- **Silver Layer**: Data cleaning, validation, deduplication
- **Gold Layer**: Business-level aggregations and metrics
- **ETL/ELT concepts**: Extract, Transform, Load processes
- **Data quality patterns**: Handling nulls, duplicates, bad data

## Business Case
You're building a data warehouse for **TechStore**, an e-commerce company selling electronics. Data comes from multiple systems:
- Website orders (CSV files)
- Inventory management (JSON from warehouse API)
- Customer data (from CRM system)

## Project Structure

### 📂 01-bronze/ (Raw Data Landing Zone)
**Goal**: Ingest raw data from all sources without transformation

Files to complete in order:
1. `README.md` - Bronze layer concepts and principles
2. `01-create-bronze-tables.sql` - Create bronze tables (all VARCHAR)
3. `02-generate-sample-data.sql` - Generate 65K rows of messy realistic data
4. `03-verify-bronze-data.sql` - Analyze data quality issues

**Key Concepts**: Raw data, schema-on-read, data lake principles, append-only

### 📂 02-silver/ (Cleaned & Validated Data)
**Goal**: Transform bronze data into clean, validated, standardized format

Files to complete:
1. `README.md` - Data cleaning strategies and rules
2. `01-create-silver-tables.sql` - Create tables with proper data types
3. `02-clean-customers.sql` - Deduplicate, validate, standardize
4. `03-clean-inventory.sql` - Fix prices, handle negatives
5. `04-clean-orders.sql` - Fix dates, remove invalid records
6. `05-join-silver-tables.sql` - Establish foreign key relationships

**Key Concepts**: Type conversion, deduplication, validation, NULL handling

### 📂 03-gold/ (Business Analytics)
**Goal**: Create pre-aggregated, business-ready analytics tables

Files to complete:
1. `README.md` - Business metrics definitions
2. `01-customer-360.sql` - Complete customer profile with LTV
3. `02-customer-rfm.sql` - Recency, Frequency, Monetary segmentation
4. `03-product-performance.sql` - Sales rankings, profit margins
5. `04-monthly-sales.sql` - Time-series trends with growth rates
6. `05-executive-dashboard.sql` - Executive KPI dashboard view

**Key Concepts**: Denormalization, pre-aggregation, business metrics, BI optimization

## Dataset Information

### Sample Data (Auto-Generated)
- **~10,000 customers** with ~200 duplicates
- **~5,000 products** in 10 categories
- **~50,000 orders** spanning 2024

### Common Data Issues You'll Fix
- **Missing values**: Empty customer IDs, NULL emails
- **Duplicates**: Same customer appears multiple times
- **Format inconsistencies**: Multiple date formats (YYYY-MM-DD, MM/DD/YYYY, DD/MM/YYYY)
- **Invalid data**: Negative quantities, future dates, invalid emails
- **Data type issues**: "$99.99" in amount fields, "N/A" in quantity
- **Boolean variations**: "true/false/1/0/yes/no" for flags

## Expected Outcomes

By the end of this project, you will have:
1. ✅ Raw data safely stored in bronze tables
2. ✅ Clean, validated data in silver tables
3. ✅ Business-ready metrics in gold tables
4. ✅ Understanding of data quality patterns
5. ✅ Experience with multi-layer data architecture

## Progression Path
```
Raw CSV/JSON Files
    ↓
Bronze Layer (Raw storage)
    ↓
Silver Layer (Cleaned & validated)
    ↓
Gold Layer (Business aggregates)
    ↓
Reports & Dashboards
```

## Time Estimate
- Bronze Layer: 2-3 hours
- Silver Layer: 3-4 hours
- Gold Layer: 2-3 hours
- **Total**: 7-10 hours

## Prerequisites
- Complete all Intermediate lessons
- Understand JOINs, GROUP BY, CTEs
- Basic knowledge of data types

## Next Steps
After completing this project, move to:
- **Project 2**: Data Vault 2.0 (for historical tracking)
- **Project 3**: Kimball Star Schema (for business intelligence)

## How to Complete This Project

### Step 0: Database Setup (NEW!)
```sql
-- Run this FIRST to create database and schemas
00-setup-database.sql
```
This creates:
- `TechStore_Warehouse` database
- Schemas: `bronze`, `silver`, `gold`, `metadata`
- Metadata tracking tables for pipeline runs and data quality

### Step 1: Bronze Layer
```
cd 01-bronze/
```
1. Read `README.md` to understand raw data principles
2. Run `01-create-bronze-tables.sql` - Creates `bronze.orders`, `bronze.customers`, `bronze.inventory`
3. Run `02-generate-sample-data.sql` - Loads 65K rows (takes ~2 minutes)
4. Run `03-verify-bronze-data.sql` - See data quality issues

**Tables created**: `bronze.orders`, `bronze.customers`, `bronze.inventory`

### Step 2: Silver Layer
```
cd 02-silver/
```
1. Read `README.md` to understand cleaning strategies
2. Run `01-create-silver-tables.sql` - Creates `silver.customers`, `silver.products`, `silver.orders`
3. Run `02-clean-customers.sql` - Deduplicate and standardize
4. Run `03-clean-inventory.sql` - Fix prices and quantities  
5. Run `04-clean-orders.sql` - Remove invalid records
6. Run `05-join-silver-tables.sql` - Establish foreign keys

**Tables created**: `silver.customers`, `silver.products`, `silver.orders`

### Step 3: Gold Layer
```
cd 03-gold/
```
1. Read `README.md` to understand business metrics
2. Run `01-customer-360.sql` - Customer analytics (`gold.customer_360`)
3. Run `02-customer-rfm.sql` - RFM segmentation (`gold.customer_rfm`)
4. Run `03-product-performance.sql` - Product rankings (`gold.product_performance`)
5. Run `04-monthly-sales.sql` - Time-series trends (`gold.monthly_sales`)
6. Run `05-executive-dashboard.sql` - KPI dashboard (`gold.vw_executive_dashboard`)

**Tables/Views created**: `gold.customer_360`, `gold.customer_rfm`, `gold.product_performance`, `gold.monthly_sales`, `gold.vw_executive_dashboard`

### Step 4: Query & Analyze
```sql
-- Query gold tables for insights
SELECT * FROM gold.customer_rfm WHERE rfm_segment = 'Champions';
SELECT * FROM gold.product_performance ORDER BY total_revenue DESC;
SELECT * FROM gold.vw_executive_dashboard;

-- Check metadata
SELECT * FROM metadata.pipeline_runs ORDER BY start_time DESC;
SELECT * FROM metadata.data_lineage;
```
