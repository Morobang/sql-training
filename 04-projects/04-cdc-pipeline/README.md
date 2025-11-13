# Project 4: Change Data Capture (CDC) Pipeline

## Overview
Build a **real-time Change Data Capture (CDC) system** that automatically tracks and replicates database changes. This is how modern data platforms keep data warehouses in sync with operational databases.

## What You'll Learn
- **CDC patterns**: Capture INSERT, UPDATE, DELETE operations
- **Temporal tables**: Built-in SQL Server CDC
- **Trigger-based CDC**: Custom change tracking
- **Incremental loading**: Only process new/changed data
- **Real-time sync**: Keep data warehouse current
- **Audit trails**: Track who changed what and when

## Why CDC?

### Traditional Batch Loading (Nightly ETL)
```
Operational DB → Export at midnight → Load to warehouse
```
❌ **Problems:**
- Data is stale (up to 24 hours old)
- Full table scans are expensive
- Increased system load during business hours
- Can't detect deletions easily

### CDC Pattern (Real-time)
```
Operational DB → Capture changes as they happen → Stream to warehouse
```
✅ **Benefits:**
- Near real-time data (seconds to minutes)
- Only process changed rows (efficient)
- Minimal impact on source system
- Track all change types (INSERT/UPDATE/DELETE)

## Business Case
You're building a CDC pipeline for **TechStore's** operational systems:
- **Orders database**: Must sync to analytics warehouse within 5 minutes
- **Inventory system**: Real-time stock levels for website
- **Customer data**: Profile updates reflected immediately
- **Product catalog**: Price changes visible to analysts right away

## CDC Architectures

### Architecture 1: SQL Server Change Tracking
Built-in feature that tracks row changes
```sql
-- Enable change tracking on database
ALTER DATABASE TechStore
SET CHANGE_TRACKING = ON;

-- Enable on specific table
ALTER TABLE Orders
ENABLE CHANGE_TRACKING
WITH (TRACK_COLUMNS_UPDATED = ON);

-- Query changes since last sync
SELECT * 
FROM CHANGETABLE(CHANGES Orders, @last_sync_version) AS CT;
```

### Architecture 2: Temporal Tables (System-Versioned)
Automatic history tracking with time travel
```sql
-- Create temporal table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(200),
    Price DECIMAL(10,2),
    -- Period columns (auto-maintained by SQL Server)
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON);

-- Query current data
SELECT * FROM Products;

-- Query historical data
SELECT * FROM Products FOR SYSTEM_TIME AS OF '2024-03-01';
```

### Architecture 3: Trigger-Based CDC
Custom solution using triggers
```sql
-- Create CDC log table
CREATE TABLE cdc_orders (
    cdc_id INT IDENTITY PRIMARY KEY,
    operation CHAR(1),  -- 'I', 'U', 'D'
    order_id INT,
    customer_id INT,
    total_amount DECIMAL(10,2),
    captured_at DATETIME DEFAULT GETDATE(),
    captured_by VARCHAR(100) DEFAULT SYSTEM_USER
);

-- Trigger on INSERT
CREATE TRIGGER trg_orders_insert
ON Orders AFTER INSERT
AS
INSERT INTO cdc_orders (operation, order_id, customer_id, total_amount)
SELECT 'I', OrderID, CustomerID, TotalAmount FROM inserted;
```

## Project Structure

### Phase 1: SQL Server Change Tracking
1. `01-cdc-setup.md` - Understand CDC concepts
2. `02-enable-change-tracking.sql` - Enable built-in tracking
3. `03-capture-changes.sql` - Query change tables
4. `04-incremental-load.sql` - Sync only changed rows
5. `05-change-tracking-cleanup.sql` - Manage retention

### Phase 2: Temporal Tables
6. `06-create-temporal-tables.sql` - System-versioned tables
7. `07-temporal-queries.sql` - Time travel queries
8. `08-history-analysis.sql` - Analyze change patterns
9. `09-restore-historical-data.sql` - Rollback to previous state

### Phase 3: Custom Trigger-Based CDC
10. `10-create-cdc-tables.sql` - CDC log tables
11. `11-create-cdc-triggers.sql` - INSERT/UPDATE/DELETE triggers
12. `12-process-cdc-log.sql` - Read and apply changes
13. `13-cdc-to-warehouse.sql` - Replicate to target database

### Phase 4: Real-World Patterns
14. `14-cdc-orchestration.sql` - Scheduled CDC processing
15. `15-conflict-resolution.sql` - Handle update conflicts
16. `16-monitoring-alerts.sql` - CDC lag monitoring

## CDC Pattern Examples

### Pattern 1: Watermark-Based Incremental Load
Track last processed timestamp
```sql
-- Source table
CREATE TABLE source_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    total_amount DECIMAL(10,2),
    modified_at DATETIME DEFAULT GETDATE()
);

-- Target table
CREATE TABLE target_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    total_amount DECIMAL(10,2),
    loaded_at DATETIME
);

-- Watermark table (tracks last sync)
CREATE TABLE cdc_watermark (
    table_name VARCHAR(100) PRIMARY KEY,
    last_sync_time DATETIME
);

-- Incremental load query
DECLARE @last_sync DATETIME;
SELECT @last_sync = last_sync_time FROM cdc_watermark WHERE table_name = 'orders';

-- Load only new/changed rows
INSERT INTO target_orders
SELECT order_id, customer_id, total_amount, GETDATE()
FROM source_orders
WHERE modified_at > @last_sync;

-- Update watermark
UPDATE cdc_watermark
SET last_sync_time = GETDATE()
WHERE table_name = 'orders';
```

### Pattern 2: Delta Detection with Hashing
Detect changes without modified_at column
```sql
-- Add hash column to track changes
ALTER TABLE target_orders
ADD row_hash VARBINARY(32);

-- Compute hash of current state
UPDATE target_orders
SET row_hash = HASHBYTES('SHA2_256', 
    CONCAT(customer_id, '|', total_amount));

-- Detect changes by comparing hashes
SELECT s.*
FROM source_orders s
LEFT JOIN target_orders t ON s.order_id = t.order_id
WHERE t.order_id IS NULL  -- New row
   OR HASHBYTES('SHA2_256', CONCAT(s.customer_id, '|', s.total_amount)) <> t.row_hash;  -- Changed row
```

### Pattern 3: SCD Type 2 with CDC
Automatically maintain slowly changing dimensions
```sql
-- When product price changes, trigger updates SCD
CREATE TRIGGER trg_product_price_change
ON source_products AFTER UPDATE
AS
BEGIN
    -- Expire old record
    UPDATE target_products
    SET end_date = GETDATE(), is_current = 0
    FROM inserted i
    WHERE target_products.product_id = i.product_id
      AND target_products.is_current = 1
      AND target_products.price <> i.price;  -- Only if price changed

    -- Insert new record
    INSERT INTO target_products (product_id, product_name, price, start_date, is_current)
    SELECT product_id, product_name, price, GETDATE(), 1
    FROM inserted i
    WHERE i.price <> (SELECT price FROM deleted WHERE product_id = i.product_id);
END;
```

## Benefits of CDC

### ✅ **Real-Time Data**
Analytics reflect current state (minutes vs hours)

### ✅ **Efficiency**
Process only changed rows (not full table scans)

### ✅ **Minimal Impact**
Lightweight compared to batch extracts

### ✅ **Complete Audit Trail**
Track all changes with timestamps and users

### ✅ **Event-Driven Architecture**
Trigger downstream processes when data changes

## Challenges & Solutions

### Challenge: High Change Volume
Millions of updates per hour overwhelm CDC

**Solution**: Batch CDC processing, use compression
```sql
-- Process CDC in micro-batches
DECLARE @batch_size INT = 10000;
WHILE EXISTS (SELECT 1 FROM cdc_orders WHERE processed = 0)
BEGIN
    -- Process batch
    UPDATE TOP (@batch_size) cdc_orders
    SET processed = 1
    WHERE processed = 0;
    
    WAITFOR DELAY '00:00:01';  -- Brief pause
END;
```

### Challenge: Schema Changes
New columns break CDC pipelines

**Solution**: Dynamic SQL, metadata-driven processing
```sql
-- Detect schema changes
IF COL_LENGTH('source_orders', 'new_column') IS NOT NULL
   AND COL_LENGTH('target_orders', 'new_column') IS NULL
BEGIN
    ALTER TABLE target_orders ADD new_column VARCHAR(100);
END;
```

### Challenge: Deleted Records
How to sync deletes to target?

**Solution**: Soft deletes or CDC DELETE tracking
```sql
-- Soft delete pattern
ALTER TABLE target_orders ADD is_deleted BIT DEFAULT 0;

-- Trigger marks as deleted instead of removing
CREATE TRIGGER trg_orders_delete
ON source_orders AFTER DELETE
AS
UPDATE target_orders
SET is_deleted = 1, deleted_at = GETDATE()
FROM deleted d
WHERE target_orders.order_id = d.order_id;
```

## Industry Use Cases

### E-commerce
- **Order sync**: Real-time order status to analytics
- **Inventory**: Live stock levels to website
- **Price changes**: Immediate catalog updates

### Banking
- **Transaction monitoring**: Fraud detection
- **Account balances**: Real-time customer balances
- **Regulatory**: Audit trail for compliance

### SaaS Applications
- **User activity**: Real-time usage analytics
- **Subscription changes**: Billing updates
- **Multi-tenant**: Sync data across environments

## Expected Outcomes

By the end of this project:
1. ✅ Implement SQL Server Change Tracking
2. ✅ Build temporal tables with time travel queries
3. ✅ Create custom trigger-based CDC
4. ✅ Handle INSERT, UPDATE, DELETE operations
5. ✅ Understand when to use each CDC pattern

## Time Estimate
- Phase 1 (Change Tracking): 2-3 hours
- Phase 2 (Temporal Tables): 2-3 hours
- Phase 3 (Trigger CDC): 3-4 hours
- Phase 4 (Advanced): 2 hours
- **Total**: 9-12 hours

## Prerequisites
- Complete Medallion Architecture project
- Understand triggers, indexes
- Basic knowledge of scheduling (SQL Agent)

## Next Steps
After this project:
- Integrate with streaming platforms (Kafka, Event Hub)
- **Project 5**: Data Quality Monitoring (validate CDC data)
- Build real-time dashboards with CDC feeds

Start with `01-cdc-setup.md`!
