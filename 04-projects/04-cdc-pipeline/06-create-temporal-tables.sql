-- ============================================================================
-- Create Temporal (System-Versioned) Tables
-- ============================================================================
-- Enable automatic history tracking with point-in-time queries
-- ============================================================================

/*
============================================================================
TEMPORAL TABLES OVERVIEW
============================================================================

WHAT ARE TEMPORAL TABLES?
- System-versioned tables that automatically track ALL changes
- SQL Server maintains complete history in separate history table
- Enable "time travel" queries (query data as it existed at any point)

HOW IT WORKS:
┌─────────────────┐         ┌──────────────────────┐
│  Current Table  │────────▶│    History Table     │
│ (Latest Values) │         │ (All Past Versions)  │
└─────────────────┘         └──────────────────────┘
     ProductID=1                ProductID=1
     Price=99.99                Price=89.99  (2024-01-01 to 2024-02-01)
     (2024-02-01+)              Price=79.99  (2023-12-01 to 2024-01-01)

BENEFITS:
✅ Zero-code history tracking (fully automatic!)
✅ Point-in-time queries: "Show me orders as of last Friday"
✅ Audit compliance: Who changed what, when?
✅ Rollback capability: Restore deleted/corrupted data
✅ Change analysis: Price changes, inventory trends

VS CHANGE TRACKING:
┌─────────────────────────┬──────────────────────────────┐
│   Change Tracking       │      Temporal Tables         │
├─────────────────────────┼──────────────────────────────┤
│ Tracks WHICH rows       │ Tracks WHAT changed          │
│ Lightweight (10 bytes)  │ Full history (doubles space) │
│ Best for: CDC sync      │ Best for: Audit, compliance  │
│ Retention: Days         │ Retention: Forever*          │
│ No old values stored    │ Complete old values          │
└─────────────────────────┴──────────────────────────────┘

USE CASES:
1. Regulatory compliance (SOX, HIPAA, GDPR)
2. Forensic analysis (security investigations)
3. Trend analysis (pricing, inventory over time)
4. Accidental change recovery
5. SLA verification (when did issue start?)

STORAGE IMPACT:
- History table grows with every UPDATE/DELETE
- Example: Update product price 10x → 10 rows in history
- Compression recommended for history table
- Archive old history to cheaper storage

============================================================================
*/

USE master;
GO

-- Create database for temporal table demo
IF DB_ID('TechStore_Temporal') IS NOT NULL
    DROP DATABASE TechStore_Temporal;
GO

CREATE DATABASE TechStore_Temporal;
GO

USE TechStore_Temporal;
GO

PRINT '=================================================================';
PRINT 'CREATING TEMPORAL TABLES';
PRINT '=================================================================';
PRINT '';

-- ============================================================================
-- CREATE TEMPORAL TABLE: Products
-- ============================================================================

PRINT 'Creating temporal Products table...';

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT DEFAULT 0,
    Supplier VARCHAR(100),
    ModifiedBy VARCHAR(50) DEFAULT SYSTEM_USER,
    
    -- REQUIRED for temporal tables
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory));

PRINT '  ✓ Created Products (current) table';
PRINT '  ✓ Created ProductsHistory (automatic) table';
PRINT '';

-- Verify temporal table creation
SELECT 
    t.name AS TableName,
    t.temporal_type_desc AS TemporalType,
    OBJECT_NAME(t.history_table_id) AS HistoryTable
FROM sys.tables t
WHERE t.name = 'Products';

PRINT '';

-- ============================================================================
-- CREATE TEMPORAL TABLE: PriceChanges (Focused History)
-- ============================================================================

PRINT 'Creating temporal PriceChanges table...';

CREATE TABLE PriceChanges (
    ChangeID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    OldPrice DECIMAL(10,2),
    NewPrice DECIMAL(10,2) NOT NULL,
    ChangeReason VARCHAR(200),
    ChangedBy VARCHAR(50) DEFAULT SYSTEM_USER,
    
    -- Temporal columns
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PriceChangesHistory));

PRINT '  ✓ Created PriceChanges temporal table';
PRINT '';

-- ============================================================================
-- CREATE TEMPORAL TABLE: Inventory
-- ============================================================================

PRINT 'Creating temporal Inventory table...';

CREATE TABLE Inventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    WarehouseLocation VARCHAR(50),
    QuantityOnHand INT DEFAULT 0,
    QuantityReserved INT DEFAULT 0,
    QuantityAvailable AS (QuantityOnHand - QuantityReserved),
    LastRestockDate DATE,
    ModifiedBy VARCHAR(50) DEFAULT SYSTEM_USER,
    
    -- Temporal columns
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (
    HISTORY_TABLE = dbo.InventoryHistory,
    DATA_CONSISTENCY_CHECK = ON
));

PRINT '  ✓ Created Inventory temporal table';
PRINT '';

-- ============================================================================
-- INSERT SAMPLE DATA
-- ============================================================================

PRINT 'Inserting sample data...';

-- Insert products
INSERT INTO Products (ProductID, ProductName, Category, Price, StockQuantity, Supplier)
VALUES 
    (1, 'Wireless Mouse', 'Electronics', 29.99, 150, 'TechSupply Co'),
    (2, 'USB-C Cable', 'Accessories', 12.99, 500, 'CableWorld'),
    (3, 'Laptop Stand', 'Accessories', 49.99, 75, 'OfficeGear'),
    (4, '4K Monitor', 'Electronics', 399.99, 25, 'DisplayTech'),
    (5, 'Mechanical Keyboard', 'Electronics', 89.99, 100, 'KeyMaster');

PRINT '  ✓ Inserted 5 products';

-- Insert inventory records
INSERT INTO Inventory (ProductID, WarehouseLocation, QuantityOnHand, QuantityReserved, LastRestockDate)
VALUES
    (1, 'Warehouse-A', 150, 20, '2024-01-15'),
    (2, 'Warehouse-A', 500, 50, '2024-01-10'),
    (3, 'Warehouse-B', 75, 10, '2024-01-12'),
    (4, 'Warehouse-B', 25, 5, '2024-01-18'),
    (5, 'Warehouse-A', 100, 15, '2024-01-14');

PRINT '  ✓ Inserted 5 inventory records';
PRINT '';

-- Show current state
PRINT 'Current Products:';
SELECT ProductID, ProductName, Price, StockQuantity, ValidFrom, ValidTo
FROM Products;

PRINT '';
PRINT 'Current Inventory:';
SELECT ProductID, WarehouseLocation, QuantityOnHand, QuantityAvailable, ValidFrom, ValidTo
FROM Inventory;

PRINT '';

-- ============================================================================
-- MAKE SOME CHANGES (Create History)
-- ============================================================================

PRINT '=================================================================';
PRINT 'SIMULATING BUSINESS OPERATIONS (Creating History)';
PRINT '=================================================================';
PRINT '';

-- Pause to ensure different timestamps
WAITFOR DELAY '00:00:01';

-- Price increase on wireless mouse
PRINT 'DAY 1: Price increase on Wireless Mouse...';
UPDATE Products
SET Price = 34.99
WHERE ProductID = 1;

-- Log price change
INSERT INTO PriceChanges (ProductID, OldPrice, NewPrice, ChangeReason)
VALUES (1, 29.99, 34.99, 'Supplier cost increase');

WAITFOR DELAY '00:00:01';

-- Inventory update (sale)
PRINT 'DAY 1: Processing sales (inventory decrease)...';
UPDATE Inventory
SET QuantityOnHand = QuantityOnHand - 30,
    QuantityReserved = QuantityReserved - 20
WHERE ProductID = 1;

WAITFOR DELAY '00:00:01';

-- Another price change
PRINT 'DAY 2: Promotional pricing on USB-C Cable...';
UPDATE Products
SET Price = 9.99
WHERE ProductID = 2;

INSERT INTO PriceChanges (ProductID, OldPrice, NewPrice, ChangeReason)
VALUES (2, 12.99, 9.99, 'Holiday promotion');

WAITFOR DELAY '00:00:01';

-- Restock
PRINT 'DAY 2: Restocking Monitor inventory...';
UPDATE Inventory
SET QuantityOnHand = QuantityOnHand + 50,
    LastRestockDate = GETDATE()
WHERE ProductID = 4;

WAITFOR DELAY '00:00:01';

-- Price correction
PRINT 'DAY 3: Price correction on Keyboard...';
UPDATE Products
SET Price = 79.99
WHERE ProductID = 5;

INSERT INTO PriceChanges (ProductID, OldPrice, NewPrice, ChangeReason)
VALUES (5, 89.99, 79.99, 'Price match competitor');

PRINT '';
PRINT '✓ Created history with 5 changes across 3 days';
PRINT '';

-- ============================================================================
-- VIEW HISTORY TABLES
-- ============================================================================

PRINT '=================================================================';
PRINT 'HISTORY TABLE CONTENTS';
PRINT '=================================================================';
PRINT '';

PRINT 'ProductsHistory (all past versions):';
SELECT 
    ProductID,
    ProductName,
    Price,
    ValidFrom,
    ValidTo,
    DATEDIFF(SECOND, ValidFrom, ValidTo) AS DurationSeconds
FROM ProductsHistory
ORDER BY ProductID, ValidFrom;

PRINT '';

PRINT 'InventoryHistory (all past versions):';
SELECT 
    ProductID,
    WarehouseLocation,
    QuantityOnHand,
    QuantityReserved,
    ValidFrom,
    ValidTo
FROM InventoryHistory
ORDER BY ProductID, ValidFrom;

PRINT '';

-- ============================================================================
-- TEMPORAL TABLE METADATA
-- ============================================================================

PRINT 'Temporal Table Configuration:';
SELECT 
    t.name AS TableName,
    t.temporal_type_desc AS Type,
    OBJECT_NAME(t.history_table_id) AS HistoryTable,
    c1.name AS PeriodStartColumn,
    c2.name AS PeriodEndColumn,
    CASE 
        WHEN t.history_retention_period = -1 THEN 'INFINITE'
        ELSE CAST(t.history_retention_period AS VARCHAR(10)) + ' ' + 
             t.history_retention_period_unit_desc
    END AS RetentionPolicy
FROM sys.tables t
JOIN sys.periods p ON t.object_id = p.object_id
JOIN sys.columns c1 ON p.start_column_id = c1.column_id AND c1.object_id = t.object_id
JOIN sys.columns c2 ON p.end_column_id = c2.column_id AND c2.object_id = t.object_id
WHERE t.temporal_type = 2  -- SYSTEM_VERSIONED_TEMPORAL_TABLE
ORDER BY t.name;

PRINT '';
PRINT '=================================================================';
PRINT 'TEMPORAL TABLES CREATED SUCCESSFULLY!';
PRINT '=================================================================';

/*
============================================================================
TEMPORAL TABLES SUMMARY
============================================================================

✅ Created 3 temporal tables:
   1. Products - Product catalog with price history
   2. PriceChanges - Dedicated price change log
   3. Inventory - Stock levels over time

✅ History tables created automatically:
   - ProductsHistory
   - PriceChangesHistory
   - InventoryHistory

✅ Generated sample history:
   - 5 price changes
   - 2 inventory updates
   - Multiple time points for queries

HOW TEMPORAL TABLES WORK:

1. PERIOD FOR SYSTEM_TIME Columns:
   - ValidFrom: When row became current
   - ValidTo: When row became historical (9999-12-31 = current)

2. Automatic History Management:
   - INSERT: Row goes to current table (ValidTo = 9999-12-31)
   - UPDATE: Old row → history, new row → current
   - DELETE: Row → history with ValidTo = deletion time

3. Query Patterns:
   - Current data: SELECT * FROM Products (normal query)
   - Historical: SELECT * FROM Products FOR SYSTEM_TIME AS OF '2024-01-01'
   - Changes: SELECT * FROM Products FOR SYSTEM_TIME BETWEEN x AND y

STORAGE CONSIDERATIONS:

Current Table:
- 5 products × ~100 bytes = 500 bytes

History Table (after 5 updates):
- 5 historical versions × ~100 bytes = 500 bytes

Total: 1 KB (minimal for demo, but scales with update frequency!)

BEST PRACTICES:

✅ Use for compliance, audit trails
✅ Enable page compression on history table
✅ Set retention policy for very active tables
✅ Partition history table by date for performance
✅ Archive old history to blob storage

❌ Don't use for high-frequency updates (log tables)
❌ Don't enable on temp staging tables
❌ Be aware of 2x storage requirement

Next: Querying temporal data with time travel!
============================================================================
*/
