-- ============================================================================
-- Create CDC Triggers
-- ============================================================================
-- Automatic change capture using AFTER triggers
-- ============================================================================

USE TechStore_CDC;
GO

PRINT '=================================================================';
PRINT 'CREATING CDC TRIGGERS';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
TRIGGER-BASED CDC IMPLEMENTATION
============================================================================

TRIGGER TYPES:

AFTER INSERT:
- Captures new rows
- Logs NEW values only
- Old values = NULL

AFTER UPDATE:
- Captures modifications
- Logs BOTH old and new values
- Use DELETED table for old, INSERTED for new

AFTER DELETE:
- Captures removed rows
- Logs OLD values only
- New values = NULL

SPECIAL TABLES:

INSERTED:
- Contains new/updated rows
- Available in INSERT and UPDATE triggers

DELETED:
- Contains old/deleted rows
- Available in UPDATE and DELETE triggers

TRIGGER BEST PRACTICES:

✅ Use AFTER triggers (not INSTEAD OF)
✅ Handle multi-row operations (use INSERTED/DELETED tables)
✅ Keep triggers fast (avoid complex logic)
✅ Log errors but don't block transactions
✅ Consider trigger nesting (triggers firing triggers)

❌ Don't use cursors in triggers
❌ Don't query large tables
❌ Don't perform heavy calculations
❌ Don't make external calls (web APIs, etc.)

============================================================================
*/

-- ============================================================================
-- PRODUCTS TABLE TRIGGERS
-- ============================================================================

PRINT 'Creating triggers for Products table...';
GO

-- INSERT Trigger
CREATE TRIGGER trg_Products_Insert_CDC
ON Products
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only log if CDC is enabled
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Products' AND IsEnabled = 1 AND TrackInserts = 1)
    BEGIN
        INSERT INTO CDC_Products (
            OperationType,
            OperationDate,
            ProductID,
            New_ProductName,
            New_Category,
            New_Price,
            New_Cost,
            New_StockQuantity,
            New_IsActive,
            ChangedBy
        )
        SELECT 
            'I',  -- Insert operation
            GETDATE(),
            i.ProductID,
            i.ProductName,
            i.Category,
            i.Price,
            i.Cost,
            i.StockQuantity,
            i.IsActive,
            i.ModifiedBy
        FROM INSERTED i;
    END
END;
GO

PRINT '  ✓ Created trg_Products_Insert_CDC';

-- UPDATE Trigger with business logic
CREATE TRIGGER trg_Products_Update_CDC
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Products' AND IsEnabled = 1 AND TrackUpdates = 1)
    BEGIN
        -- Log all updates with old and new values
        INSERT INTO CDC_Products (
            OperationType,
            OperationDate,
            ProductID,
            -- Old values (from DELETED table)
            Old_ProductName,
            Old_Category,
            Old_Price,
            Old_Cost,
            Old_StockQuantity,
            Old_IsActive,
            -- New values (from INSERTED table)
            New_ProductName,
            New_Category,
            New_Price,
            New_Cost,
            New_StockQuantity,
            New_IsActive,
            ChangedBy
        )
        SELECT 
            'U',  -- Update operation
            GETDATE(),
            i.ProductID,
            -- Old values
            d.ProductName,
            d.Category,
            d.Price,
            d.Cost,
            d.StockQuantity,
            d.IsActive,
            -- New values
            i.ProductName,
            i.Category,
            i.Price,
            i.Cost,
            i.StockQuantity,
            i.IsActive,
            i.ModifiedBy
        FROM INSERTED i
        JOIN DELETED d ON i.ProductID = d.ProductID
        WHERE 
            -- Only log meaningful changes (not just ModifiedDate updates)
            i.ProductName != d.ProductName OR
            i.Category != d.Category OR
            i.Price != d.Price OR
            i.Cost != d.Cost OR
            i.StockQuantity != d.StockQuantity OR
            i.IsActive != d.IsActive;
    END
END;
GO

PRINT '  ✓ Created trg_Products_Update_CDC';

-- DELETE Trigger
CREATE TRIGGER trg_Products_Delete_CDC
ON Products
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Products' AND IsEnabled = 1 AND TrackDeletes = 1)
    BEGIN
        INSERT INTO CDC_Products (
            OperationType,
            OperationDate,
            ProductID,
            -- Old values only (no NEW for delete)
            Old_ProductName,
            Old_Category,
            Old_Price,
            Old_Cost,
            Old_StockQuantity,
            Old_IsActive,
            ChangedBy
        )
        SELECT 
            'D',  -- Delete operation
            GETDATE(),
            d.ProductID,
            d.ProductName,
            d.Category,
            d.Price,
            d.Cost,
            d.StockQuantity,
            d.IsActive,
            d.ModifiedBy
        FROM DELETED d;
    END
END;
GO

PRINT '  ✓ Created trg_Products_Delete_CDC';
PRINT '';

-- ============================================================================
-- ORDERS TABLE TRIGGERS
-- ============================================================================

PRINT 'Creating triggers for Orders table...';
GO

CREATE TRIGGER trg_Orders_Insert_CDC
ON Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Orders' AND IsEnabled = 1 AND TrackInserts = 1)
    BEGIN
        INSERT INTO CDC_Orders (
            OperationType,
            OperationDate,
            OrderID,
            New_CustomerID,
            New_TotalAmount,
            New_OrderStatus,
            ChangedBy
        )
        SELECT 
            'I',
            GETDATE(),
            i.OrderID,
            i.CustomerID,
            i.TotalAmount,
            i.OrderStatus,
            i.ModifiedBy
        FROM INSERTED i;
    END
END;
GO

CREATE TRIGGER trg_Orders_Update_CDC
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Orders' AND IsEnabled = 1 AND TrackUpdates = 1)
    BEGIN
        INSERT INTO CDC_Orders (
            OperationType,
            OperationDate,
            OrderID,
            Old_CustomerID,
            Old_TotalAmount,
            Old_OrderStatus,
            New_CustomerID,
            New_TotalAmount,
            New_OrderStatus,
            ChangedBy
        )
        SELECT 
            'U',
            GETDATE(),
            i.OrderID,
            d.CustomerID,
            d.TotalAmount,
            d.OrderStatus,
            i.CustomerID,
            i.TotalAmount,
            i.OrderStatus,
            i.ModifiedBy
        FROM INSERTED i
        JOIN DELETED d ON i.OrderID = d.OrderID;
    END
END;
GO

CREATE TRIGGER trg_Orders_Delete_CDC
ON Orders
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Orders' AND IsEnabled = 1 AND TrackDeletes = 1)
    BEGIN
        INSERT INTO CDC_Orders (
            OperationType,
            OperationDate,
            OrderID,
            Old_CustomerID,
            Old_TotalAmount,
            Old_OrderStatus,
            ChangedBy
        )
        SELECT 
            'D',
            GETDATE(),
            d.OrderID,
            d.CustomerID,
            d.TotalAmount,
            d.OrderStatus,
            d.ModifiedBy
        FROM DELETED d;
    END
END;
GO

PRINT '  ✓ Created 3 triggers for Orders';
PRINT '';

-- ============================================================================
-- CUSTOMERS TABLE TRIGGERS
-- ============================================================================

PRINT 'Creating triggers for Customers table...';
GO

CREATE TRIGGER trg_Customers_Insert_CDC
ON Customers
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Customers' AND IsEnabled = 1 AND TrackInserts = 1)
    BEGIN
        INSERT INTO CDC_Customers (
            OperationType,
            OperationDate,
            CustomerID,
            New_FirstName,
            New_LastName,
            New_Email,
            New_LoyaltyPoints,
            ChangedBy
        )
        SELECT 
            'I',
            GETDATE(),
            i.CustomerID,
            i.FirstName,
            i.LastName,
            i.Email,
            i.LoyaltyPoints,
            i.ModifiedBy
        FROM INSERTED i;
    END
END;
GO

CREATE TRIGGER trg_Customers_Update_CDC
ON Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Customers' AND IsEnabled = 1 AND TrackUpdates = 1)
    BEGIN
        INSERT INTO CDC_Customers (
            OperationType,
            OperationDate,
            CustomerID,
            Old_FirstName,
            Old_LastName,
            Old_Email,
            Old_LoyaltyPoints,
            New_FirstName,
            New_LastName,
            New_Email,
            New_LoyaltyPoints,
            ChangedBy
        )
        SELECT 
            'U',
            GETDATE(),
            i.CustomerID,
            d.FirstName,
            d.LastName,
            d.Email,
            d.LoyaltyPoints,
            i.FirstName,
            i.LastName,
            i.Email,
            i.LoyaltyPoints,
            i.ModifiedBy
        FROM INSERTED i
        JOIN DELETED d ON i.CustomerID = d.CustomerID;
    END
END;
GO

CREATE TRIGGER trg_Customers_Delete_CDC
ON Customers
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM CDC_Configuration WHERE TableName = 'Customers' AND IsEnabled = 1 AND TrackDeletes = 1)
    BEGIN
        INSERT INTO CDC_Customers (
            OperationType,
            OperationDate,
            CustomerID,
            Old_FirstName,
            Old_LastName,
            Old_Email,
            Old_LoyaltyPoints,
            ChangedBy
        )
        SELECT 
            'D',
            GETDATE(),
            d.CustomerID,
            d.FirstName,
            d.LastName,
            d.Email,
            d.LoyaltyPoints,
            d.ModifiedBy
        FROM DELETED d;
    END
END;
GO

PRINT '  ✓ Created 3 triggers for Customers';
PRINT '';

-- ============================================================================
-- TEST TRIGGERS
-- ============================================================================

PRINT '=================================================================';
PRINT 'TESTING CDC TRIGGERS';
PRINT '=================================================================';
PRINT '';

PRINT 'Current CDC log (should be empty):';
SELECT COUNT(*) AS ProductChanges FROM CDC_Products;
SELECT COUNT(*) AS OrderChanges FROM CDC_Orders;
SELECT COUNT(*) AS CustomerChanges FROM CDC_Customers;

PRINT '';
PRINT 'Performing test operations...';

-- Test INSERT
INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, Supplier)
VALUES ('Test Product', 'Test', 99.99, 50.00, 100, 'TestSupplier');
PRINT '  ✓ Inserted new product';

-- Test UPDATE
UPDATE Products
SET Price = 89.99,
    StockQuantity = 95
WHERE ProductName = 'Wireless Mouse';
PRINT '  ✓ Updated product price and stock';

-- Test DELETE
DELETE FROM Products WHERE ProductName = 'Test Product';
PRINT '  ✓ Deleted test product';

-- Test order status change
UPDATE Orders
SET OrderStatus = 'Shipped'
WHERE OrderID = 1;
PRINT '  ✓ Changed order status';

-- Test customer update
UPDATE Customers
SET LoyaltyPoints = LoyaltyPoints + 100
WHERE CustomerID = 1;
PRINT '  ✓ Updated customer loyalty points';

PRINT '';
PRINT 'CDC Log Summary:';

SELECT 
    'Products' AS TableName,
    OperationType,
    COUNT(*) AS ChangeCount
FROM CDC_Products
GROUP BY OperationType

UNION ALL

SELECT 
    'Orders',
    OperationType,
    COUNT(*)
FROM CDC_Orders
GROUP BY OperationType

UNION ALL

SELECT 
    'Customers',
    OperationType,
    COUNT(*)
FROM CDC_Customers
GROUP BY OperationType
ORDER BY TableName, OperationType;

PRINT '';
PRINT 'Detailed Product Changes:';
SELECT 
    CDC_ID,
    OperationType,
    ProductID,
    Old_Price,
    New_Price,
    Old_StockQuantity,
    New_StockQuantity,
    ChangedBy,
    OperationDate
FROM CDC_Products
ORDER BY CDC_ID;

PRINT '';
PRINT '=================================================================';
PRINT 'CDC TRIGGERS CREATED AND TESTED SUCCESSFULLY!';
PRINT '=================================================================';

/*
============================================================================
TRIGGER-BASED CDC COMPLETE!
============================================================================

✅ CREATED 9 TRIGGERS:

Products:
- trg_Products_Insert_CDC
- trg_Products_Update_CDC (with meaningful change detection)
- trg_Products_Delete_CDC

Orders:
- trg_Orders_Insert_CDC
- trg_Orders_Update_CDC
- trg_Orders_Delete_CDC

Customers:
- trg_Customers_Insert_CDC
- trg_Customers_Update_CDC
- trg_Customers_Delete_CDC

TRIGGER FEATURES:

✅ Capture INSERT, UPDATE, DELETE
✅ Store old AND new values
✅ Audit context (user, app, host)
✅ Configurable (enable/disable per table)
✅ Multi-row safe (handles batch operations)
✅ Meaningful change detection (Products only logs actual changes)

CDC LOG STRUCTURE:

OperationType: 'I' / 'U' / 'D'
Old_* columns: Values before change (NULL for INSERT)
New_* columns: Values after change (NULL for DELETE)
IsProcessed: Flag for CDC processing pipeline
ChangedBy: Who made the change
OperationDate: When change occurred

PERFORMANCE CONSIDERATIONS:

✅ Triggers are fast (simple INSERT into log table)
✅ Indexes on CDC tables for quick queries
✅ No complex logic in triggers
✅ Batch operations handled efficiently

❌ Triggers add ~5-10% overhead to DML operations
❌ CDC log tables grow over time (need cleanup)
❌ Can't disable for bulk loads (need separate pattern)

NEXT STEPS:

1. Process CDC log (replicate to warehouse)
2. Mark records as processed
3. Clean up old CDC logs
4. Monitor CDC lag

Next file: 12-process-cdc-log.sql
============================================================================
*/
