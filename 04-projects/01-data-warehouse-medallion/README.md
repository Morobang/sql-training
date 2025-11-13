# Project 1: Data Warehouse (Medallion Architecture)

## Overview
Build a complete data warehouse using the **Medallion Architecture** (Bronze → Silver → Gold). This project teaches you how to transform raw, messy data into clean, business-ready analytics datasets.

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

### Bronze Layer (Raw/Landing Zone)
**Goal**: Ingest raw data from all sources without transformation

Files to complete in order:
1. `01-bronze-setup.md` - Understand the bronze layer concept
2. `02-create-bronze-tables.sql` - Create bronze tables for raw data
3. `03-load-bronze-orders.sql` - Load orders CSV into bronze
4. `04-load-bronze-inventory.sql` - Load inventory JSON into bronze
5. `05-load-bronze-customers.sql` - Load customer data into bronze

**Key Concepts**: Raw data, schema-on-read, data lake principles

### Silver Layer (Cleaned & Validated)
**Goal**: Clean, validate, deduplicate, and standardize data

Files to complete:
1. `06-silver-setup.md` - Understand data quality requirements
2. `07-clean-orders.sql` - Fix date formats, handle nulls, standardize
3. `08-clean-customers.sql` - Deduplicate, validate emails, parse names
4. `09-clean-inventory.sql` - Normalize product codes, fix quantities
5. `10-silver-joins.sql` - Join cleaned tables into unified datasets

**Key Concepts**: Data validation, deduplication, standardization, data quality

### Gold Layer (Business Analytics)
**Goal**: Create business-ready datasets optimized for reporting

Files to complete:
1. `11-gold-setup.md` - Understand business metrics
2. `12-customer-summary.sql` - Customer lifetime value, RFM analysis
3. `13-product-performance.sql` - Sales metrics, inventory turnover
4. `14-monthly-sales.sql` - Time-series revenue tracking
5. `15-executive-dashboard.sql` - Top-level KPIs for leadership

**Key Concepts**: Aggregation, business metrics, reporting optimization

## Dataset Information

### Bronze Tables
- `bronze_orders`: ~50,000 orders with messy data
- `bronze_customers`: ~10,000 customers with duplicates
- `bronze_inventory`: ~5,000 products with JSON structure

### Common Data Issues You'll Fix
- Missing customer IDs
- Duplicate customer records
- Inconsistent date formats (MM/DD/YYYY vs YYYY-MM-DD)
- Product name typos
- Invalid email addresses
- Negative quantities
- Future order dates
- NULL values in critical fields

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

Start with `01-bronze-setup.md`!
