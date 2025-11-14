-- ============================================================================
-- Create CDC Tables for Trigger-Based Tracking
-- ============================================================================
-- Manual CDC implementation using log tables
-- ============================================================================

/*
============================================================================
TRIGGER-BASED CDC OVERVIEW
============================================================================

WHY CUSTOM TRIGGERS vs BUILT-IN CDC?

SQL Server Change Tracking:
✅ Built-in, lightweight
✅ Minimal configuration
❌ Only tracks WHICH rows changed (not WHAT changed)
❌ No old values

Temporal Tables:
✅ Complete history automatically
✅ Point-in-time queries
❌ Doubles storage (current + history)
❌ Limited control over what's tracked

Trigger-Based CDC:
✅ Complete control over what to capture
✅ Old AND new values stored
✅ Custom business logic (only track meaningful changes)
✅ Capture user context, application name
✅ Cross-database replication
❌ Requires custom code
❌ Performance overhead (each DML fires trigger)

USE CASES FOR CUSTOM TRIGGERS:

1. Selective Tracking
   - Only log price changes > 10%
   - Ignore automated system updates
   
2. Business Context
   - Capture username, reason for change
   - Link to approval workflow
   
3. Cross-System Sync
   - Replicate to non-SQL systems
   - Feed message queues (Kafka, RabbitMQ)
   
4. Compliance Requirements
   - Specific regulatory logging
   - Cannot modify source tables for temporal

============================================================================
*/

USE master;
GO

IF DB_ID('TechStore_CDC') IS NOT NULL
    DROP DATABASE TechStore_CDC;
GO

CREATE DATABASE TechStore_CDC;
GO

USE TechStore_CDC;
GO

PRINT '=================================================================';
PRINT 'CREATING TRIGGER-BASED CDC INFRASTRUCTURE';
PRINT '=================================================================';
PRINT '';

-- ============================================================================
-- CREATE SOURCE TABLES (Standard OLTP Tables)
-- ============================================================================

PRINT 'Creating source tables...';

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2),  -- Vendor cost
    StockQuantity INT DEFAULT 0,
    MinStockLevel INT DEFAULT 10,
    Supplier VARCHAR(100),
    IsActive BIT DEFAULT 1,
    ModifiedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(50) DEFAULT SYSTEM_USER
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(12,2) NOT NULL,
    OrderStatus VARCHAR(20) DEFAULT 'Pending',
    ModifiedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(50) DEFAULT SYSTEM_USER
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100),
    LoyaltyPoints INT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    ModifiedBy VARCHAR(50) DEFAULT SYSTEM_USER
);

PRINT '  ✓ Created Products, Orders, Customers';
PRINT '';

-- ============================================================================
-- CREATE CDC LOG TABLES
-- ============================================================================

PRINT 'Creating CDC log tables...';

-- Generic CDC log for Products
CREATE TABLE CDC_Products (
    CDC_ID BIGINT PRIMARY KEY IDENTITY(1,1),
    OperationType CHAR(1) NOT NULL,  -- 'I'nsert, 'U'pdate, 'D'elete
    OperationDate DATETIME DEFAULT GETDATE(),
    
    -- Captured Data (Before and After)
    ProductID INT,
    
    -- OLD VALUES (for UPDATE and DELETE)
    Old_ProductName VARCHAR(100),
    Old_Category VARCHAR(50),
    Old_Price DECIMAL(10,2),
    Old_Cost DECIMAL(10,2),
    Old_StockQuantity INT,
    Old_IsActive BIT,
    
    -- NEW VALUES (for INSERT and UPDATE)
    New_ProductName VARCHAR(100),
    New_Category VARCHAR(50),
    New_Price DECIMAL(10,2),
    New_Cost DECIMAL(10,2),
    New_StockQuantity INT,
    New_IsActive BIT,
    
    -- Audit Context
    ChangedBy VARCHAR(50) DEFAULT SYSTEM_USER,
    ApplicationName VARCHAR(100) DEFAULT APP_NAME(),
    HostName VARCHAR(100) DEFAULT HOST_NAME(),
    DatabaseName VARCHAR(50) DEFAULT DB_NAME(),
    
    -- CDC Processing
    IsProcessed BIT DEFAULT 0,
    ProcessedDate DATETIME NULL
);

-- CDC log for Orders
CREATE TABLE CDC_Orders (
    CDC_ID BIGINT PRIMARY KEY IDENTITY(1,1),
    OperationType CHAR(1) NOT NULL,
    OperationDate DATETIME DEFAULT GETDATE(),
    
    OrderID INT,
    
    -- Old values
    Old_CustomerID INT,
    Old_TotalAmount DECIMAL(12,2),
    Old_OrderStatus VARCHAR(20),
    
    -- New values
    New_CustomerID INT,
    New_TotalAmount DECIMAL(12,2),
    New_OrderStatus VARCHAR(20),
    
    -- Audit
    ChangedBy VARCHAR(50) DEFAULT SYSTEM_USER,
    ApplicationName VARCHAR(100) DEFAULT APP_NAME(),
    IsProcessed BIT DEFAULT 0,
    ProcessedDate DATETIME NULL
);

-- CDC log for Customers
CREATE TABLE CDC_Customers (
    CDC_ID BIGINT PRIMARY KEY IDENTITY(1,1),
    OperationType CHAR(1) NOT NULL,
    OperationDate DATETIME DEFAULT GETDATE(),
    
    CustomerID INT,
    
    -- Old values
    Old_FirstName VARCHAR(50),
    Old_LastName VARCHAR(50),
    Old_Email VARCHAR(100),
    Old_LoyaltyPoints INT,
    
    -- New values
    New_FirstName VARCHAR(50),
    New_LastName VARCHAR(50),
    New_Email VARCHAR(100),
    New_LoyaltyPoints INT,
    
    -- Audit
    ChangedBy VARCHAR(50) DEFAULT SYSTEM_USER,
    IsProcessed BIT DEFAULT 0,
    ProcessedDate DATETIME NULL
);

PRINT '  ✓ Created CDC_Products, CDC_Orders, CDC_Customers';
PRINT '';

-- ============================================================================
-- CREATE CDC METADATA TABLES
-- ============================================================================

PRINT 'Creating CDC metadata tables...';

-- Track CDC processing status
CREATE TABLE CDC_ProcessingLog (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    TableName VARCHAR(100) NOT NULL,
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME,
    RecordsProcessed INT DEFAULT 0,
    RecordsInserted INT DEFAULT 0,
    RecordsUpdated INT DEFAULT 0,
    RecordsDeleted INT DEFAULT 0,
    Status VARCHAR(20) DEFAULT 'Running',
    ErrorMessage VARCHAR(MAX)
);

-- Configuration for CDC processing
CREATE TABLE CDC_Configuration (
    ConfigID INT PRIMARY KEY IDENTITY(1,1),
    TableName VARCHAR(100) NOT NULL UNIQUE,
    IsEnabled BIT DEFAULT 1,
    TrackInserts BIT DEFAULT 1,
    TrackUpdates BIT DEFAULT 1,
    TrackDeletes BIT DEFAULT 1,
    RetentionDays INT DEFAULT 30,  -- How long to keep CDC logs
    LastProcessedID BIGINT DEFAULT 0,
    LastProcessedDate DATETIME
);

-- Insert configuration for our tables
INSERT INTO CDC_Configuration (TableName, RetentionDays)
VALUES 
    ('Products', 30),
    ('Orders', 90),      -- Keep longer for financial compliance
    ('Customers', 365);  -- Keep 1 year for GDPR/compliance

PRINT '  ✓ Created CDC_ProcessingLog, CDC_Configuration';
PRINT '';

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

PRINT 'Creating indexes...';

-- CDC log table indexes
CREATE INDEX IX_CDC_Products_IsProcessed 
    ON CDC_Products(IsProcessed, CDC_ID);

CREATE INDEX IX_CDC_Products_OperationDate 
    ON CDC_Products(OperationDate);

CREATE INDEX IX_CDC_Products_ProductID 
    ON CDC_Products(ProductID, CDC_ID);

CREATE INDEX IX_CDC_Orders_IsProcessed 
    ON CDC_Orders(IsProcessed, CDC_ID);

CREATE INDEX IX_CDC_Customers_IsProcessed 
    ON CDC_Customers(IsProcessed, CDC_ID);

PRINT '  ✓ Created indexes for CDC log tables';
PRINT '';

-- ============================================================================
-- CREATE CDC VIEWS FOR EASY QUERYING
-- ============================================================================

PRINT 'Creating CDC views...';
GO

-- View: Unprocessed Product Changes
CREATE VIEW vw_CDC_Products_Unprocessed AS
SELECT 
    CDC_ID,
    OperationType,
    OperationDate,
    ProductID,
    Old_Price,
    New_Price,
    New_Price - Old_Price AS PriceChange,
    Old_StockQuantity,
    New_StockQuantity,
    New_StockQuantity - Old_StockQuantity AS StockChange,
    ChangedBy,
    ApplicationName
FROM CDC_Products
WHERE IsProcessed = 0;
GO

-- View: Significant Price Changes (>10%)
CREATE VIEW vw_CDC_SignificantPriceChanges AS
SELECT 
    CDC_ID,
    ProductID,
    New_ProductName AS ProductName,
    Old_Price,
    New_Price,
    New_Price - Old_Price AS PriceChange,
    CAST(((New_Price - Old_Price) / Old_Price * 100) AS DECIMAL(5,2)) AS PercentChange,
    OperationDate,
    ChangedBy
FROM CDC_Products
WHERE OperationType = 'U'
  AND Old_Price IS NOT NULL
  AND New_Price IS NOT NULL
  AND ABS((New_Price - Old_Price) / Old_Price * 100) > 10;
GO

-- View: Order Status Changes
CREATE VIEW vw_CDC_OrderStatusChanges AS
SELECT 
    CDC_ID,
    OrderID,
    Old_OrderStatus,
    New_OrderStatus,
    Old_TotalAmount,
    New_TotalAmount,
    OperationDate,
    ChangedBy,
    CASE 
        WHEN New_OrderStatus = 'Completed' THEN '✓ Completed'
        WHEN New_OrderStatus = 'Cancelled' THEN '✗ Cancelled'
        WHEN New_OrderStatus = 'Shipped' THEN '📦 Shipped'
        ELSE New_OrderStatus
    END AS StatusDisplay
FROM CDC_Orders
WHERE OperationType = 'U'
  AND Old_OrderStatus != New_OrderStatus;
GO

PRINT '✓ Created CDC views';
PRINT '';

-- ============================================================================
-- INSERT SAMPLE DATA
-- ============================================================================

PRINT 'Inserting sample data...';

INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, MinStockLevel, Supplier)
VALUES 
    ('Laptop Pro 15', 'Electronics', 1299.99, 950.00, 50, 10, 'TechSupply Inc'),
    ('Wireless Mouse', 'Accessories', 29.99, 15.00, 200, 50, 'PeripheralsRUs'),
    ('USB-C Hub', 'Accessories', 49.99, 25.00, 150, 30, 'ConnectorWorld'),
    ('Monitor 27"', 'Electronics', 399.99, 280.00, 75, 15, 'DisplayTech'),
    ('Mechanical Keyboard', 'Accessories', 89.99, 50.00, 100, 20, 'KeyMaster');

INSERT INTO Customers (FirstName, LastName, Email, LoyaltyPoints)
VALUES 
    ('Alice', 'Johnson', 'alice@email.com', 500),
    ('Bob', 'Smith', 'bob@email.com', 1200),
    ('Carol', 'Williams', 'carol@email.com', 350);

INSERT INTO Orders (CustomerID, TotalAmount, OrderStatus)
VALUES 
    (1, 1329.98, 'Pending'),
    (2, 489.97, 'Shipped'),
    (3, 89.99, 'Completed');

PRINT '  ✓ Inserted 5 products, 3 customers, 3 orders';
PRINT '';

-- Show current state
PRINT 'Current Products:';
SELECT ProductID, ProductName, Price, StockQuantity FROM Products;

PRINT '';
PRINT '=================================================================';
PRINT 'CDC INFRASTRUCTURE CREATED SUCCESSFULLY!';
PRINT '=================================================================';

/*
============================================================================
TRIGGER-BASED CDC SUMMARY
============================================================================

✅ CREATED INFRASTRUCTURE:

1. Source Tables
   - Products (5 products)
   - Orders (3 orders)
   - Customers (3 customers)

2. CDC Log Tables
   - CDC_Products (captures INSERT/UPDATE/DELETE)
   - CDC_Orders
   - CDC_Customers
   
   Structure:
   - OperationType: I/U/D
   - Old_* columns: Values before change
   - New_* columns: Values after change
   - Audit context: Who, when, from where

3. Metadata Tables
   - CDC_ProcessingLog: Track CDC job runs
   - CDC_Configuration: Enable/disable tracking per table

4. Performance Indexes
   - IsProcessed (for incremental processing)
   - OperationDate (for time-based queries)
   - Primary keys (for joins)

5. Views
   - vw_CDC_Products_Unprocessed
   - vw_CDC_SignificantPriceChanges
   - vw_CDC_OrderStatusChanges

CDC LOG TABLE PATTERN:

For each source table, create CDC log with:
- CDC_ID: Auto-increment primary key
- OperationType: 'I', 'U', 'D'
- OperationDate: When change occurred
- Old_* columns: Before values (NULL for INSERT)
- New_* columns: After values (NULL for DELETE)
- Audit columns: Who, where, when
- IsProcessed: Has CDC been replicated?

BENEFITS OF THIS APPROACH:

✅ Complete audit trail (old + new values)
✅ Custom business logic possible
✅ Selective tracking (e.g., only price changes > 10%)
✅ Cross-system replication ready
✅ Detailed context (user, app, host)

VS SQL SERVER CDC:

SQL Server CDC (sys.sp_cdc_*):
- Built-in feature
- Uses transaction log
- Complex setup
- Not available in all editions

Custom Triggers:
- Full control
- Works in all editions
- Simpler setup
- More flexible

NEXT STEPS:

1. Create triggers (INSERT, UPDATE, DELETE)
2. Build processing procedures
3. Replicate to warehouse
4. Set up monitoring

Next file: 11-create-cdc-triggers.sql
============================================================================
*/
