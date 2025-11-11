-- ========================================
-- AFTER Triggers (DML Triggers)
-- ========================================

USE TechStore;
GO

-- Drop existing triggers
DROP TRIGGER IF EXISTS trg_UpdateCustomerPurchases;
DROP TRIGGER IF EXISTS trg_UpdateProductStock;
DROP TRIGGER IF EXISTS trg_AuditProductChanges;
DROP TRIGGER IF EXISTS trg_PreventNegativeStock;
DROP TRIGGER IF EXISTS trg_UpdateTimestamp;
GO

-- Create audit table (if not exists)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductAuditLog')
BEGIN
    CREATE TABLE ProductAuditLog (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT,
        Action VARCHAR(20),
        OldPrice DECIMAL(10,2),
        NewPrice DECIMAL(10,2),
        OldStock INT,
        NewStock INT,
        ChangedBy VARCHAR(100),
        ChangedDate DATETIME
    );
END;
GO

-- =============================================
-- Example 1: AFTER INSERT - Update Summary Data
-- =============================================

CREATE TRIGGER trg_UpdateCustomerPurchases
ON Sales
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update customer total purchases
    UPDATE c
    SET TotalPurchases = TotalPurchases + i.TotalAmount
    FROM Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
    
    PRINT 'Customer total purchases updated';
END;
GO

-- Test the trigger
SELECT CustomerID, CustomerName, TotalPurchases FROM Customers WHERE CustomerID = 1;

INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES (1, 1, 1, GETDATE(), 99.99, 'Credit Card');

SELECT CustomerID, CustomerName, TotalPurchases FROM Customers WHERE CustomerID = 1;
GO

-- =============================================
-- Example 2: AFTER INSERT/DELETE - Maintain Stock
-- =============================================

CREATE TRIGGER trg_UpdateProductStock
ON Sales
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Decrease stock for new sales
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE p
        SET StockQuantity = StockQuantity - i.Quantity
        FROM Products p
        INNER JOIN inserted i ON p.ProductID = i.ProductID;
    END;
    
    -- Increase stock for deleted sales (returns)
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE p
        SET StockQuantity = StockQuantity + d.Quantity
        FROM Products p
        INNER JOIN deleted d ON p.ProductID = d.ProductID;
    END;
END;
GO

-- Test stock update
SELECT ProductID, ProductName, StockQuantity FROM Products WHERE ProductID = 1;

-- Insert sale (stock decreases)
INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES (1, 1, 2, GETDATE(), 199.98, 'Cash');

SELECT ProductID, ProductName, StockQuantity FROM Products WHERE ProductID = 1;

-- Delete sale (stock increases - simulating return)
DELETE FROM Sales WHERE SaleID = (SELECT MAX(SaleID) FROM Sales);

SELECT ProductID, ProductName, StockQuantity FROM Products WHERE ProductID = 1;
GO

-- =============================================
-- Example 3: AFTER UPDATE - Audit Changes
-- =============================================

CREATE TRIGGER trg_AuditProductChanges
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log price and stock changes
    INSERT INTO ProductAuditLog (
        ProductID, 
        Action, 
        OldPrice, 
        NewPrice, 
        OldStock, 
        NewStock,
        ChangedBy, 
        ChangedDate
    )
    SELECT 
        i.ProductID,
        'UPDATE',
        d.Price AS OldPrice,
        i.Price AS NewPrice,
        d.StockQuantity AS OldStock,
        i.StockQuantity AS NewStock,
        SUSER_SNAME(),  -- Current user
        GETDATE()
    FROM inserted i
    INNER JOIN deleted d ON i.ProductID = d.ProductID
    WHERE d.Price <> i.Price OR d.StockQuantity <> i.StockQuantity;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' changes logged to audit table';
END;
GO

-- Test audit trigger
UPDATE Products SET Price = 159.99 WHERE ProductID = 1;
UPDATE Products SET StockQuantity = StockQuantity + 10 WHERE ProductID = 1;

-- View audit log
SELECT * FROM ProductAuditLog ORDER BY ChangedDate DESC;
GO

-- =============================================
-- Example 4: AFTER UPDATE - Prevent Invalid Data
-- =============================================

CREATE TRIGGER trg_PreventNegativeStock
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for negative stock
    IF EXISTS (SELECT * FROM inserted WHERE StockQuantity < 0)
    BEGIN
        RAISERROR('Stock quantity cannot be negative', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Check for negative price
    IF EXISTS (SELECT * FROM inserted WHERE Price < 0 OR Cost < 0)
    BEGIN
        RAISERROR('Price and cost cannot be negative', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    PRINT 'Product update validation passed';
END;
GO

-- Test validation (should fail)
BEGIN TRY
    UPDATE Products SET StockQuantity = -10 WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- Test validation (should succeed)
UPDATE Products SET StockQuantity = 100 WHERE ProductID = 1;
GO

-- =============================================
-- Example 5: AFTER INSERT/UPDATE - Auto Timestamp
-- =============================================

-- Add LastModified column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'LastModified')
BEGIN
    ALTER TABLE Products ADD LastModified DATETIME NULL;
END;
GO

CREATE TRIGGER trg_UpdateTimestamp
ON Products
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET LastModified = GETDATE()
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
END;
GO

-- Test timestamp update
SELECT ProductID, ProductName, LastModified FROM Products WHERE ProductID = 1;

UPDATE Products SET Price = 149.99 WHERE ProductID = 1;

SELECT ProductID, ProductName, LastModified FROM Products WHERE ProductID = 1;
GO

-- =============================================
-- Example 6: AFTER DELETE - Prevent Deletion
-- =============================================

DROP TRIGGER IF EXISTS trg_PreventProductDelete;
GO

CREATE TRIGGER trg_PreventProductDelete
ON Products
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if deleted products have sales history
    IF EXISTS (
        SELECT 1 
        FROM deleted d
        INNER JOIN Sales s ON d.ProductID = s.ProductID
    )
    BEGIN
        RAISERROR('Cannot delete products with sales history', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    PRINT 'Product deleted successfully';
END;
GO

-- Test deletion prevention
BEGIN TRY
    -- Try to delete product with sales
    DELETE FROM Products WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'Deletion prevented: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =============================================
-- Example 7: Multiple Row Handling
-- =============================================

DROP TRIGGER IF EXISTS trg_BulkSalesUpdate;
GO

CREATE TRIGGER trg_BulkSalesUpdate
ON Sales
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Correctly handle multiple rows (set-based operation)
    UPDATE c
    SET TotalPurchases = TotalPurchases + TotalSales
    FROM Customers c
    INNER JOIN (
        SELECT CustomerID, SUM(TotalAmount) AS TotalSales
        FROM inserted
        GROUP BY CustomerID
    ) i ON c.CustomerID = i.CustomerID;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' customers updated';
END;
GO

-- Test bulk insert (trigger handles all rows)
INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES 
    (1, 1, 1, GETDATE(), 99.99, 'Cash'),
    (1, 2, 2, GETDATE(), 49.98, 'Credit Card'),
    (2, 1, 1, GETDATE(), 99.99, 'PayPal');

PRINT 'Bulk insert completed';
GO

-- =============================================
-- Example 8: Conditional Trigger Logic
-- =============================================

DROP TRIGGER IF EXISTS trg_ConditionalAudit;
GO

CREATE TRIGGER trg_ConditionalAudit
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only log if price changed (not stock updates)
    IF UPDATE(Price)
    BEGIN
        INSERT INTO ProductAuditLog (ProductID, Action, OldPrice, NewPrice, ChangedBy, ChangedDate)
        SELECT 
            i.ProductID,
            'PRICE_CHANGE',
            d.Price,
            i.Price,
            SUSER_SNAME(),
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE d.Price <> i.Price;
        
        PRINT 'Price changes logged';
    END;
    
    -- Log stock changes separately
    IF UPDATE(StockQuantity)
    BEGIN
        INSERT INTO ProductAuditLog (ProductID, Action, OldStock, NewStock, ChangedBy, ChangedDate)
        SELECT 
            i.ProductID,
            'STOCK_CHANGE',
            d.StockQuantity,
            i.StockQuantity,
            SUSER_SNAME(),
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE d.StockQuantity <> i.StockQuantity;
        
        PRINT 'Stock changes logged';
    END;
END;
GO

-- Test conditional logic
UPDATE Products SET Price = 179.99 WHERE ProductID = 1;  -- Logs price change
UPDATE Products SET StockQuantity = StockQuantity + 5 WHERE ProductID = 1;  -- Logs stock change

SELECT * FROM ProductAuditLog ORDER BY ChangedDate DESC;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP TRIGGER IF EXISTS trg_UpdateCustomerPurchases;
DROP TRIGGER IF EXISTS trg_UpdateProductStock;
DROP TRIGGER IF EXISTS trg_AuditProductChanges;
DROP TRIGGER IF EXISTS trg_PreventNegativeStock;
DROP TRIGGER IF EXISTS trg_UpdateTimestamp;
DROP TRIGGER IF EXISTS trg_PreventProductDelete;
DROP TRIGGER IF EXISTS trg_BulkSalesUpdate;
DROP TRIGGER IF EXISTS trg_ConditionalAudit;

DROP TABLE IF EXISTS ProductAuditLog;
ALTER TABLE Products DROP COLUMN IF EXISTS LastModified;
*/

-- 💡 Key Points:
-- - AFTER triggers execute after INSERT/UPDATE/DELETE completes
-- - Use inserted and deleted pseudo-tables
-- - Always handle multiple rows (set-based operations)
-- - SET NOCOUNT ON prevents extra messages
-- - ROLLBACK TRANSACTION to prevent invalid data
-- - Use UPDATE(ColumnName) to check which columns changed
-- - Triggers fire once per statement (not per row)
-- - Keep logic simple and fast
-- - Ideal for audit logging, maintaining derived data, validation
-- - Test with bulk operations to ensure correctness
