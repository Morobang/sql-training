-- ============================================================================
-- CDC Pipeline Project - Setup & Foundation
-- ============================================================================
-- Change Data Capture (CDC) automatically tracks database changes
-- This project demonstrates 3 CDC patterns:
--   1. SQL Server Change Tracking (built-in)
--   2. Temporal Tables (system-versioned)
--   3. Custom Trigger-Based CDC
-- ============================================================================

/*
============================================================================
WHAT IS CHANGE DATA CAPTURE (CDC)?
============================================================================

CDC = Automatically detecting and capturing changes to data

PROBLEM IT SOLVES:
Traditional batch ETL loads entire tables nightly (SLOW, WASTEFUL)
CDC loads only changed rows in near real-time (FAST, EFFICIENT)

EXAMPLE SCENARIO:
- Orders table has 10 million rows
- Yesterday: 1,000 new orders, 500 order updates
- Traditional: Load all 10 million rows (99.98% unchanged!)
- CDC: Load only 1,500 changed rows (99.98% savings!)

REAL-WORLD BENEFITS:
✅ Near real-time data (seconds vs hours)
✅ 100x-1000x faster (only process changes)
✅ Lower source system impact (no full scans)
✅ Complete audit trail (who changed what when)
✅ Event-driven processing (trigger actions on changes)

============================================================================
CDC PATTERN COMPARISON
============================================================================

Pattern 1: SQL SERVER CHANGE TRACKING
- Built-in SQL Server feature
- Tracks WHICH rows changed (not what changed)
- Lightweight, easy to setup
- Best for: Simple sync scenarios, small changes
- Limitation: Doesn't store old values

Pattern 2: TEMPORAL TABLES (SYSTEM-VERSIONED)
- Automatic history table maintained by SQL Server
- Stores complete history of all changes
- Point-in-time queries ("time travel")
- Best for: Audit requirements, compliance, rollback
- Limitation: Doubles storage (current + history)

Pattern 3: TRIGGER-BASED CDC
- Custom solution using INSERT/UPDATE/DELETE triggers
- Full control over what to capture
- Can store old and new values
- Best for: Complex business logic, cross-system sync
- Limitation: Performance overhead, custom code to maintain

============================================================================
WHEN TO USE EACH PATTERN
============================================================================

SQL SERVER CHANGE TRACKING:
✅ Simple incremental load to data warehouse
✅ Only need to know IF row changed (not WHAT changed)
✅ Minimize storage overhead
❌ Don't use if you need full history or old values

TEMPORAL TABLES:
✅ Compliance/audit requirements (track everything)
✅ Need to query historical state ("as of" date)
✅ Rollback capability (undo changes)
❌ Don't use if storage is constrained (doubles size)

TRIGGER-BASED CDC:
✅ Complex business rules (e.g., only track price changes)
✅ Need old AND new values
✅ Cross-database or cross-system replication
❌ Don't use if performance is critical (triggers add overhead)

============================================================================
INDUSTRY USE CASES
============================================================================

E-COMMERCE:
- Real-time inventory sync (prevent overselling)
- Order status updates to analytics
- Price change tracking for competitive analysis
- Customer profile updates across systems

BANKING:
- Fraud detection (real-time transaction monitoring)
- Regulatory compliance (audit trail of all changes)
- Account balance updates
- Credit score recalculation triggers

SAAS PLATFORMS:
- Multi-tenant data sync
- Real-time usage analytics
- Subscription changes → billing system
- User activity tracking

HEALTHCARE:
- Patient record updates (HIPAA compliance)
- Medication changes → alerts
- Lab result tracking
- Audit trail for EHR systems

============================================================================
*/

-- ============================================================================
-- STEP 1: Create Source Database (Operational System)
-- ============================================================================

-- Drop existing databases if they exist
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'TechStore_Source')
    DROP DATABASE TechStore_Source;

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'TechStore_Target')
    DROP DATABASE TechStore_Target;
GO

-- Create source database (simulates operational OLTP system)
CREATE DATABASE TechStore_Source;
GO

USE TechStore_Source;
GO

PRINT '✓ Created TechStore_Source database (operational system)';

-- ============================================================================
-- STEP 2: Create Source Tables (Operational Data)
-- ============================================================================

-- Orders table (high-change volume)
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL,
    OrderStatus VARCHAR(50) DEFAULT 'Pending',
    ShippingAddress VARCHAR(500),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(100) DEFAULT SYSTEM_USER
);

-- Customers table (medium-change volume)
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(200) UNIQUE,
    Phone VARCHAR(20),
    LoyaltyTier VARCHAR(50) DEFAULT 'Bronze',
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(100) DEFAULT SYSTEM_USER
);

-- Products table (low-change volume)
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(200) NOT NULL,
    Category VARCHAR(100),
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT DEFAULT 0,
    ModifiedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(100) DEFAULT SYSTEM_USER
);

PRINT '✓ Created source tables (Orders, Customers, Products)';

-- ============================================================================
-- STEP 3: Insert Sample Data
-- ============================================================================

-- Insert sample customers
INSERT INTO Customers (FirstName, LastName, Email, Phone, LoyaltyTier)
VALUES 
    ('John', 'Smith', 'john.smith@email.com', '555-0101', 'Gold'),
    ('Jane', 'Doe', 'jane.doe@email.com', '555-0102', 'Platinum'),
    ('Bob', 'Johnson', 'bob.j@email.com', '555-0103', 'Silver'),
    ('Alice', 'Williams', 'alice.w@email.com', '555-0104', 'Bronze'),
    ('Charlie', 'Brown', 'charlie.b@email.com', '555-0105', 'Gold');

-- Insert sample products
INSERT INTO Products (ProductName, Category, Price, StockQuantity)
VALUES 
    ('Laptop Pro 15', 'Electronics', 1299.99, 50),
    ('Wireless Mouse', 'Electronics', 29.99, 200),
    ('USB-C Cable', 'Accessories', 19.99, 500),
    ('External SSD 1TB', 'Storage', 149.99, 100),
    ('Laptop Bag', 'Accessories', 49.99, 150);

-- Insert sample orders
INSERT INTO Orders (CustomerID, TotalAmount, OrderStatus, ShippingAddress)
VALUES 
    (1, 1329.98, 'Shipped', '123 Main St, Seattle, WA 98101'),
    (2, 1299.99, 'Processing', '456 Oak Ave, Portland, OR 97201'),
    (3, 79.98, 'Delivered', '789 Pine Rd, San Francisco, CA 94102'),
    (1, 149.99, 'Pending', '123 Main St, Seattle, WA 98101'),
    (4, 29.99, 'Shipped', '321 Elm St, Austin, TX 78701');

PRINT '✓ Inserted sample data';
PRINT '  - 5 customers';
PRINT '  - 5 products';  
PRINT '  - 5 orders';

-- ============================================================================
-- STEP 4: Create Target Database (Data Warehouse)
-- ============================================================================

CREATE DATABASE TechStore_Target;
GO

USE TechStore_Target;
GO

PRINT '✓ Created TechStore_Target database (data warehouse)';

-- Create target tables (same structure as source for this demo)
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2) NOT NULL,
    OrderStatus VARCHAR(50),
    ShippingAddress VARCHAR(500),
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(100),
    -- CDC metadata
    DW_LoadedDate DATETIME DEFAULT GETDATE(),
    DW_IsDeleted BIT DEFAULT 0
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(200),
    Phone VARCHAR(20),
    LoyaltyTier VARCHAR(50),
    CreatedDate DATETIME,
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(100),
    -- CDC metadata
    DW_LoadedDate DATETIME DEFAULT GETDATE(),
    DW_IsDeleted BIT DEFAULT 0
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(200) NOT NULL,
    Category VARCHAR(100),
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT,
    ModifiedDate DATETIME,
    ModifiedBy VARCHAR(100),
    -- CDC metadata
    DW_LoadedDate DATETIME DEFAULT GETDATE(),
    DW_IsDeleted BIT DEFAULT 0
);

PRINT '✓ Created target tables with CDC metadata columns';

-- ============================================================================
-- STEP 5: Create CDC Metadata Tables
-- ============================================================================

-- Watermark table (tracks last sync point)
CREATE TABLE CDC_Watermark (
    TableName VARCHAR(100) PRIMARY KEY,
    LastSyncTime DATETIME NOT NULL,
    LastSyncVersion BIGINT,
    RowsProcessed INT DEFAULT 0,
    LastRunStatus VARCHAR(50),
    UpdatedDate DATETIME DEFAULT GETDATE()
);

-- Initialize watermarks
INSERT INTO CDC_Watermark (TableName, LastSyncTime, LastSyncVersion, LastRunStatus)
VALUES 
    ('Orders', '1900-01-01', 0, 'Initial'),
    ('Customers', '1900-01-01', 0, 'Initial'),
    ('Products', '1900-01-01', 0, 'Initial');

PRINT '✓ Created CDC_Watermark table';

-- CDC execution log (audit trail of CDC runs)
CREATE TABLE CDC_ExecutionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(100) NOT NULL,
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME,
    RowsInserted INT DEFAULT 0,
    RowsUpdated INT DEFAULT 0,
    RowsDeleted INT DEFAULT 0,
    Status VARCHAR(50),
    ErrorMessage VARCHAR(MAX),
    Duration_Seconds AS DATEDIFF(SECOND, StartTime, EndTime)
);

PRINT '✓ Created CDC_ExecutionLog table';

-- ============================================================================
-- STEP 6: Create Helper Views
-- ============================================================================

-- View to monitor CDC lag
CREATE VIEW vw_CDC_Lag AS
SELECT 
    w.TableName,
    w.LastSyncTime,
    DATEDIFF(MINUTE, w.LastSyncTime, GETDATE()) AS LagMinutes,
    w.RowsProcessed,
    w.LastRunStatus,
    CASE 
        WHEN DATEDIFF(MINUTE, w.LastSyncTime, GETDATE()) > 60 THEN 'CRITICAL'
        WHEN DATEDIFF(MINUTE, w.LastSyncTime, GETDATE()) > 15 THEN 'WARNING'
        ELSE 'OK'
    END AS HealthStatus
FROM CDC_Watermark w;
GO

PRINT '✓ Created vw_CDC_Lag monitoring view';

-- View for CDC execution history
CREATE VIEW vw_CDC_ExecutionHistory AS
SELECT 
    TableName,
    StartTime,
    EndTime,
    RowsInserted,
    RowsUpdated,
    RowsDeleted,
    Status,
    Duration_Seconds,
    ErrorMessage
FROM CDC_ExecutionLog
WHERE StartTime >= DATEADD(DAY, -7, GETDATE())  -- Last 7 days
;
GO

PRINT '✓ Created vw_CDC_ExecutionHistory view';

-- ============================================================================
-- STEP 7: Verification Queries
-- ============================================================================

PRINT '';
PRINT '=================================================================';
PRINT 'CDC SETUP COMPLETE!';
PRINT '=================================================================';
PRINT '';

-- Show source data
PRINT 'SOURCE DATABASE (TechStore_Source):';
USE TechStore_Source;
SELECT 'Orders' AS TableName, COUNT(*) AS RowCount FROM Orders
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products;

PRINT '';
PRINT 'TARGET DATABASE (TechStore_Target):';
USE TechStore_Target;
SELECT 'Orders' AS TableName, COUNT(*) AS RowCount FROM Orders
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Products;

PRINT '';
PRINT 'CDC METADATA:';
SELECT * FROM CDC_Watermark;

PRINT '';
PRINT '=================================================================';
PRINT 'NEXT STEPS:';
PRINT '=================================================================';
PRINT '1. Run 02-enable-change-tracking.sql - Enable SQL Server Change Tracking';
PRINT '2. Run 03-capture-changes.sql - Query change tables';
PRINT '3. Run 04-incremental-load.sql - Sync changed rows to warehouse';
PRINT '';

/*
============================================================================
SETUP COMPLETE!
============================================================================

✅ Created TechStore_Source (operational database)
   - Orders, Customers, Products tables
   - Sample data loaded

✅ Created TechStore_Target (data warehouse)
   - Same tables with CDC metadata columns
   - DW_LoadedDate, DW_IsDeleted

✅ Created CDC infrastructure
   - CDC_Watermark (tracks sync points)
   - CDC_ExecutionLog (audit trail)
   - Monitoring views

Ready to implement CDC patterns!

ARCHITECTURE OVERVIEW:

Source DB (OLTP)          CDC Layer              Target DB (DW)
┌─────────────┐          ┌──────────┐          ┌─────────────┐
│   Orders    │──────────▶│ Capture  │──────────▶│   Orders    │
│  Customers  │          │ Changes  │          │  Customers  │
│  Products   │          └──────────┘          │  Products   │
└─────────────┘                                └─────────────┘
                         ┌──────────┐
                         │Watermark │
                         │   Log    │
                         └──────────┘

Next: Enable Change Tracking!
============================================================================
*/
