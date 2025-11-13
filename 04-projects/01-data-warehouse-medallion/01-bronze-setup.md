# Bronze Layer: Raw Data Landing Zone

## What is the Bronze Layer?

The **Bronze Layer** is the first stage of a data warehouse where you store **raw, unprocessed data** exactly as it comes from source systems. Think of it as your "digital archive" - a safety net that preserves the original data.

## Key Principles

### 1. Store Data "As-Is"
- **No transformations**: Load data exactly as received
- **Preserve original format**: Keep dates, strings, numbers in source format
- **Include all columns**: Even ones you don't plan to use
- **Keep bad data**: Don't filter out errors (you'll clean in Silver)

**Why?** If you make a mistake in transformation later, you can always go back to bronze and start over.

### 2. Append-Only Pattern
- **Never delete**: Bronze data should only grow
- **Add timestamps**: Track when each record was loaded
- **Preserve history**: Multiple versions of the same record can exist

### 3. Schema-on-Read
- **Flexible schema**: Can change as source systems evolve
- **Minimal validation**: Just check if data can be loaded
- **Fast ingestion**: Optimize for speed, not quality

## Real-World Example: TechStore Orders

### Source: Website Orders (CSV)
```csv
order_id,customer_id,product_name,qty,order_date,amount
1001,C001,Wireless Mouse,2,2024-01-15,59.98
1002,,Laptop Stand,1,15/01/2024,79.99
1003,C002,USB-C Cable,5,2024-99-99,49.95
```

**Problems in this data:**
- Missing customer_id (row 2)
- Inconsistent date formats (row 2)
- Invalid date (row 3: month 99)

**Bronze approach:** Load ALL of it! Don't fix anything yet.

## Bronze Table Structure

```sql
CREATE TABLE bronze_orders (
    -- Original columns from source
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    product_name VARCHAR(200),
    qty VARCHAR(50),           -- String! Not INT (handles "N/A")
    order_date VARCHAR(50),    -- String! Not DATE (handles formats)
    amount VARCHAR(50),        -- String! Not DECIMAL (handles "$59.99")
    
    -- Metadata columns
    bronze_loaded_at DATETIME DEFAULT GETDATE(),
    bronze_source_file VARCHAR(255)
);
```

**Notice**: Everything is `VARCHAR`! This prevents load failures from data type mismatches.

## Common Bronze Patterns

### Pattern 1: Full Load
Load entire dataset each time (small tables)
```sql
TRUNCATE TABLE bronze_customers;
INSERT INTO bronze_customers SELECT * FROM source;
```

### Pattern 2: Incremental Load
Only load new/changed records (large tables)
```sql
INSERT INTO bronze_orders
SELECT * FROM source
WHERE order_date > (SELECT MAX(order_date) FROM bronze_orders);
```

### Pattern 3: CDC (Change Data Capture)
Track inserts, updates, deletes with operation type
```sql
CREATE TABLE bronze_inventory (
    product_id VARCHAR(50),
    product_name VARCHAR(200),
    stock_qty VARCHAR(50),
    -- CDC metadata
    cdc_operation CHAR(1),  -- 'I'nsert, 'U'pdate, 'D'elete
    cdc_timestamp DATETIME
);
```

## Benefits of Bronze Layer

### ✅ **Data Lineage**
Always know where data came from and when it arrived

### ✅ **Recoverability**
Made a mistake in transformation? Go back to bronze and retry

### ✅ **Audit Trail**
Compliance teams can verify original source data

### ✅ **Flexibility**
Change your transformation logic without re-ingesting from source

### ✅ **Historical Record**
Keep multiple snapshots of changing source data

## Bronze Layer Anti-Patterns (What NOT to Do)

❌ **Don't clean data**: That's for Silver layer
❌ **Don't enforce constraints**: No foreign keys, no NOT NULL
❌ **Don't deduplicate**: Keep all records, even duplicates
❌ **Don't normalize**: Store denormalized, wide tables
❌ **Don't use strict data types**: Use VARCHAR to handle variations

## Bronze Layer Checklist

Before moving to Silver, ensure your Bronze layer has:
- [ ] Raw data loaded exactly as received
- [ ] Metadata columns (load timestamp, source file)
- [ ] All columns from source (don't drop any)
- [ ] No transformations applied
- [ ] Documented source system and load frequency

## Real-World Industry Examples

### E-commerce (TechStore)
- `bronze_orders` from website
- `bronze_inventory` from warehouse API
- `bronze_customers` from CRM

### Banking
- `bronze_transactions` from core banking system
- `bronze_customer_kyc` from compliance system
- `bronze_card_swipes` from payment processor

### Healthcare
- `bronze_patient_visits` from EMR system
- `bronze_lab_results` from LIMS
- `bronze_insurance_claims` from billing system

## Transition to Silver

Once bronze layer is stable, you'll move to **Silver Layer** where you:
1. Convert data types (VARCHAR → DATE, INT, DECIMAL)
2. Handle NULL values
3. Deduplicate records
4. Standardize formats
5. Validate business rules
6. Join related tables

## Next Steps

Complete these files in order:
1. ✅ `01-bronze-setup.md` (you are here)
2. ➡️ `02-create-bronze-tables.sql` - Create your bronze tables
3. `03-load-bronze-orders.sql` - Load orders data
4. `04-load-bronze-inventory.sql` - Load inventory data
5. `05-load-bronze-customers.sql` - Load customer data

Let's build your bronze layer! 🚀
