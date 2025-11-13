# Phase 1: Bronze Layer (Raw Data Landing Zone)

## Overview
The Bronze layer stores **raw, unprocessed data** exactly as received from source systems. Think of it as your "data vault" - a complete historical record of incoming data.

## Objectives
- Load data "as-is" without transformation
- Preserve all source data (even bad data)
- Track metadata (when loaded, from where)
- Prepare for Silver layer cleaning

## Files in This Phase

### 1. Setup & Concepts
- `README.md` (this file) - Bronze layer concepts

### 2. Table Creation
- `01-create-bronze-tables.sql` - Create all bronze tables with VARCHAR columns

### 3. Data Loading
- `02-generate-sample-data.sql` - Generate realistic messy data
- `03-load-bronze-orders.sql` - Load orders with data quality issues
- `04-load-bronze-customers.sql` - Load customers with duplicates
- `05-load-bronze-inventory.sql` - Load inventory with format issues
- `06-load-bronze-sales.sql` - Load sales transactions

### 4. Verification
- `07-verify-bronze-data.sql` - Check data loaded correctly and contains expected issues

## Bronze Layer Principles

### ✅ DO:
- Store everything as VARCHAR (prevent load failures)
- Add metadata columns (loaded_at, source_file)
- Keep all records (even duplicates and bad data)
- Use append-only pattern
- Track data lineage

### ❌ DON'T:
- Clean or validate data
- Remove duplicates
- Enforce constraints (no foreign keys)
- Transform data types
- Filter out "bad" records

## Data Quality Issues You'll See

Our sample data intentionally includes:
- **Missing values**: Empty customer IDs, null emails
- **Duplicates**: Same customer appears multiple times
- **Format inconsistencies**: "2024-01-15" vs "01/15/2024"
- **Invalid data**: Negative quantities, future dates
- **Data type issues**: "$99.99" in amount fields
- **Typos**: Product names with misspellings

**Why keep bad data?** 
1. Audit trail (prove what source sent us)
2. Can re-process if cleaning logic changes
3. Analyze patterns in data quality issues

## Expected Outcomes

After completing this phase:
- ✅ 4 bronze tables created (orders, customers, inventory, sales)
- ✅ ~66,000 rows of messy sample data loaded
- ✅ All data quality issues preserved in bronze
- ✅ Metadata tracking in place
- ✅ Ready to move to Silver layer for cleaning

## Next Phase
Once bronze is complete, move to **Phase 2: Silver Layer** where you'll:
- Convert VARCHAR to proper data types
- Handle NULL values
- Deduplicate records
- Standardize formats
- Validate business rules

## Time Estimate
2-3 hours to complete all bronze layer files
