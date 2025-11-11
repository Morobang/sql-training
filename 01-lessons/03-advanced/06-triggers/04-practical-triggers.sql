-- ========================================
-- Practical Trigger Examples
-- Real-World Trigger Implementations
-- ========================================

USE TechStore;
GO

-- =============================================
-- Setup: Create Supporting Tables
-- =============================================

-- Comprehensive audit trail
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditTrail')
BEGIN
    CREATE TABLE AuditTrail (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        TableName VARCHAR(100),
        RecordID INT,
        Action VARCHAR(20),
        FieldName VARCHAR(100),
        OldValue VARCHAR(MAX),
        NewValue VARCHAR(MAX),
        ChangedBy VARCHAR(100),
        ChangedDate DATETIME,
        IPAddress VARCHAR(50)
    );
END;
GO

-- Sales summary denormalized table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CustomerSalesSummary')
BEGIN
    CREATE TABLE CustomerSalesSummary (
        CustomerID INT PRIMARY KEY,
        TotalOrders INT DEFAULT 0,
        TotalRevenue DECIMAL(18,2) DEFAULT 0,
        LastPurchaseDate DATETIME NULL,
        AverageOrderValue DECIMAL(10,2) DEFAULT 0,
        LastUpdated DATETIME
    );
    
    -- Initialize with existing data
    INSERT INTO CustomerSalesSummary (CustomerID, TotalOrders, TotalRevenue, LastPurchaseDate, AverageOrderValue, LastUpdated)
    SELECT 
        c.CustomerID,
        COUNT(s.SaleID) AS TotalOrders,
        ISNULL(SUM(s.TotalAmount), 0) AS TotalRevenue,
        MAX(s.SaleDate) AS LastPurchaseDate,
        AVG(s.TotalAmount) AS AverageOrderValue,
        GETDATE()
    FROM Customers c
    LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerID;
END;
GO

-- Inventory alerts
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InventoryAlerts')
BEGIN
    CREATE TABLE InventoryAlerts (
        AlertID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT,
        AlertType VARCHAR(50),
        CurrentStock INT,
        Message VARCHAR(500),
        CreatedDate DATETIME,
        IsResolved BIT DEFAULT 0
    );
END;
GO

-- Price history tracking
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PriceHistory')
BEGIN
    CREATE TABLE PriceHistory (
        HistoryID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT,
        OldPrice DECIMAL(10,2),
        NewPrice DECIMAL(10,2),
        PriceChange DECIMAL(10,2),
        PercentChange DECIMAL(5,2),
        ChangedBy VARCHAR(100),
        ChangedDate DATETIME
    );
END;
GO

-- Drop existing triggers
DROP TRIGGER IF EXISTS trg_ComprehensiveAudit;
DROP TRIGGER IF EXISTS trg_MaintainSalesSummary;
DROP TRIGGER IF EXISTS trg_InventoryAlerts;
DROP TRIGGER IF EXISTS trg_PriceChangeTracking;
DROP TRIGGER IF EXISTS trg_CascadingUpdates;
DROP TRIGGER IF EXISTS trg_BusinessRuleEnforcement;
GO

-- =============================================
-- Example 1: Comprehensive Audit Trail
-- =============================================

CREATE TRIGGER trg_ComprehensiveAudit
ON Products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action VARCHAR(20);
    DECLARE @User VARCHAR(100) = SUSER_SNAME();
    
    -- Determine action type
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = 'INSERT';
    ELSE
        SET @Action = 'DELETE';
    
    -- Log INSERT operations
    IF @Action = 'INSERT'
    BEGIN
        INSERT INTO AuditTrail (TableName, RecordID, Action, FieldName, NewValue, ChangedBy, ChangedDate)
        SELECT 
            'Products',
            ProductID,
            'INSERT',
            'ALL_FIELDS',
            'ProductName: ' + ProductName + ', Price: ' + CAST(Price AS VARCHAR(20)),
            @User,
            GETDATE()
        FROM inserted;
    END;
    
    -- Log DELETE operations
    IF @Action = 'DELETE'
    BEGIN
        INSERT INTO AuditTrail (TableName, RecordID, Action, FieldName, OldValue, ChangedBy, ChangedDate)
        SELECT 
            'Products',
            ProductID,
            'DELETE',
            'ALL_FIELDS',
            'ProductName: ' + ProductName + ', Price: ' + CAST(Price AS VARCHAR(20)),
            @User,
            GETDATE()
        FROM deleted;
    END;
    
    -- Log UPDATE operations (field-level tracking)
    IF @Action = 'UPDATE'
    BEGIN
        -- Track Price changes
        INSERT INTO AuditTrail (TableName, RecordID, Action, FieldName, OldValue, NewValue, ChangedBy, ChangedDate)
        SELECT 
            'Products',
            i.ProductID,
            'UPDATE',
            'Price',
            CAST(d.Price AS VARCHAR(20)),
            CAST(i.Price AS VARCHAR(20)),
            @User,
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE d.Price <> i.Price;
        
        -- Track Stock changes
        INSERT INTO AuditTrail (TableName, RecordID, Action, FieldName, OldValue, NewValue, ChangedBy, ChangedDate)
        SELECT 
            'Products',
            i.ProductID,
            'UPDATE',
            'StockQuantity',
            CAST(d.StockQuantity AS VARCHAR(20)),
            CAST(i.StockQuantity AS VARCHAR(20)),
            @User,
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE d.StockQuantity <> i.StockQuantity;
    END;
END;
GO

-- Test audit trail
UPDATE Products SET Price = Price + 10 WHERE ProductID = 1;
UPDATE Products SET StockQuantity = StockQuantity - 5 WHERE ProductID = 1;

SELECT TOP 5 * FROM AuditTrail ORDER BY ChangedDate DESC;
GO

-- =============================================
-- Example 2: Maintain Denormalized Summary
-- =============================================

CREATE TRIGGER trg_MaintainSalesSummary
ON Sales
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get affected customers from both inserted and deleted
    DECLARE @AffectedCustomers TABLE (CustomerID INT);
    
    INSERT INTO @AffectedCustomers (CustomerID)
    SELECT DISTINCT CustomerID FROM inserted
    UNION
    SELECT DISTINCT CustomerID FROM deleted;
    
    -- Recalculate summary for affected customers
    UPDATE css
    SET 
        TotalOrders = ISNULL(s.OrderCount, 0),
        TotalRevenue = ISNULL(s.TotalRev, 0),
        LastPurchaseDate = s.LastPurchase,
        AverageOrderValue = CASE WHEN s.OrderCount > 0 THEN s.TotalRev / s.OrderCount ELSE 0 END,
        LastUpdated = GETDATE()
    FROM CustomerSalesSummary css
    INNER JOIN @AffectedCustomers ac ON css.CustomerID = ac.CustomerID
    LEFT JOIN (
        SELECT 
            CustomerID,
            COUNT(*) AS OrderCount,
            SUM(TotalAmount) AS TotalRev,
            MAX(SaleDate) AS LastPurchase
        FROM Sales
        GROUP BY CustomerID
    ) s ON css.CustomerID = s.CustomerID;
    
    -- Insert new customers if needed
    INSERT INTO CustomerSalesSummary (CustomerID, TotalOrders, TotalRevenue, LastPurchaseDate, AverageOrderValue, LastUpdated)
    SELECT 
        ac.CustomerID,
        ISNULL(s.OrderCount, 0),
        ISNULL(s.TotalRev, 0),
        s.LastPurchase,
        CASE WHEN s.OrderCount > 0 THEN s.TotalRev / s.OrderCount ELSE 0 END,
        GETDATE()
    FROM @AffectedCustomers ac
    LEFT JOIN (
        SELECT 
            CustomerID,
            COUNT(*) AS OrderCount,
            SUM(TotalAmount) AS TotalRev,
            MAX(SaleDate) AS LastPurchase
        FROM Sales
        GROUP BY CustomerID
    ) s ON ac.CustomerID = s.CustomerID
    WHERE NOT EXISTS (SELECT 1 FROM CustomerSalesSummary WHERE CustomerID = ac.CustomerID);
END;
GO

-- Test summary maintenance
SELECT * FROM CustomerSalesSummary WHERE CustomerID = 1;

INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES (1, 1, 1, GETDATE(), 99.99, 'Cash');

SELECT * FROM CustomerSalesSummary WHERE CustomerID = 1;
GO

-- =============================================
-- Example 3: Inventory Alert System
-- =============================================

CREATE TRIGGER trg_InventoryAlerts
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Low stock alert (below 10 units)
    INSERT INTO InventoryAlerts (ProductID, AlertType, CurrentStock, Message, CreatedDate)
    SELECT 
        i.ProductID,
        'LOW_STOCK',
        i.StockQuantity,
        'Product "' + i.ProductName + '" is low on stock: ' + CAST(i.StockQuantity AS VARCHAR(10)) + ' units remaining',
        GETDATE()
    FROM inserted i
    WHERE i.StockQuantity < 10 
      AND i.StockQuantity < (SELECT StockQuantity FROM deleted WHERE ProductID = i.ProductID);
    
    -- Out of stock alert
    INSERT INTO InventoryAlerts (ProductID, AlertType, CurrentStock, Message, CreatedDate)
    SELECT 
        i.ProductID,
        'OUT_OF_STOCK',
        i.StockQuantity,
        'CRITICAL: Product "' + i.ProductName + '" is OUT OF STOCK',
        GETDATE()
    FROM inserted i
    WHERE i.StockQuantity = 0 
      AND (SELECT StockQuantity FROM deleted WHERE ProductID = i.ProductID) > 0;
    
    -- Overstocked alert (above 1000 units)
    INSERT INTO InventoryAlerts (ProductID, AlertType, CurrentStock, Message, CreatedDate)
    SELECT 
        i.ProductID,
        'OVERSTOCKED',
        i.StockQuantity,
        'Product "' + i.ProductName + '" may be overstocked: ' + CAST(i.StockQuantity AS VARCHAR(10)) + ' units',
        GETDATE()
    FROM inserted i
    WHERE i.StockQuantity > 1000;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' inventory alerts generated';
END;
GO

-- Test inventory alerts
UPDATE Products SET StockQuantity = 5 WHERE ProductID = 2;  -- Low stock
UPDATE Products SET StockQuantity = 0 WHERE ProductID = 3;  -- Out of stock

SELECT * FROM InventoryAlerts WHERE IsResolved = 0 ORDER BY CreatedDate DESC;
GO

-- =============================================
-- Example 4: Price Change Tracking & Analysis
-- =============================================

CREATE TRIGGER trg_PriceChangeTracking
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only track actual price changes
    IF UPDATE(Price)
    BEGIN
        INSERT INTO PriceHistory (ProductID, OldPrice, NewPrice, PriceChange, PercentChange, ChangedBy, ChangedDate)
        SELECT 
            i.ProductID,
            d.Price AS OldPrice,
            i.Price AS NewPrice,
            i.Price - d.Price AS PriceChange,
            CASE WHEN d.Price > 0 THEN ((i.Price - d.Price) / d.Price) * 100 ELSE 0 END AS PercentChange,
            SUSER_SNAME(),
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE d.Price <> i.Price;
        
        -- Alert for significant price increases (>20%)
        DECLARE @SignificantIncreases INT;
        
        SELECT @SignificantIncreases = COUNT(*)
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE i.Price > d.Price * 1.2;
        
        IF @SignificantIncreases > 0
        BEGIN
            PRINT 'ALERT: ' + CAST(@SignificantIncreases AS VARCHAR(10)) + ' product(s) increased by more than 20%';
        END;
    END;
END;
GO

-- Test price tracking
UPDATE Products SET Price = 199.99 WHERE ProductID = 1;  -- Increase
UPDATE Products SET Price = 149.99 WHERE ProductID = 1;  -- Decrease

SELECT 
    p.ProductName,
    ph.OldPrice,
    ph.NewPrice,
    ph.PriceChange,
    ph.PercentChange,
    ph.ChangedDate
FROM PriceHistory ph
INNER JOIN Products p ON ph.ProductID = p.ProductID
ORDER BY ph.ChangedDate DESC;
GO

-- =============================================
-- Example 5: Cascading Updates
-- =============================================

CREATE TRIGGER trg_CascadingUpdates
ON Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- If customer name changes, update related records
    IF UPDATE(CustomerName)
    BEGIN
        -- Example: Update cached customer name in summary table
        UPDATE css
        SET LastUpdated = GETDATE()
        FROM CustomerSalesSummary css
        INNER JOIN inserted i ON css.CustomerID = i.CustomerID
        INNER JOIN deleted d ON i.CustomerID = d.CustomerID
        WHERE d.CustomerName <> i.CustomerName;
        
        -- Log the name change
        INSERT INTO AuditTrail (TableName, RecordID, Action, FieldName, OldValue, NewValue, ChangedBy, ChangedDate)
        SELECT 
            'Customers',
            i.CustomerID,
            'UPDATE',
            'CustomerName',
            d.CustomerName,
            i.CustomerName,
            SUSER_SNAME(),
            GETDATE()
        FROM inserted i
        INNER JOIN deleted d ON i.CustomerID = d.CustomerID
        WHERE d.CustomerName <> i.CustomerName;
    END;
END;
GO

-- =============================================
-- Example 6: Business Rule Enforcement
-- =============================================

CREATE TRIGGER trg_BusinessRuleEnforcement
ON Sales
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Rule 1: Minimum order value ($10)
    IF EXISTS (SELECT * FROM inserted WHERE TotalAmount < 10)
    BEGIN
        RAISERROR('Minimum order value is $10.00', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Rule 2: Maximum quantity per transaction (100 units)
    IF EXISTS (SELECT * FROM inserted WHERE Quantity > 100)
    BEGIN
        RAISERROR('Maximum quantity per transaction is 100 units', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Rule 3: No future-dated sales
    IF EXISTS (SELECT * FROM inserted WHERE SaleDate > GETDATE())
    BEGIN
        RAISERROR('Sale date cannot be in the future', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    -- Rule 4: Validate payment method
    IF EXISTS (
        SELECT * FROM inserted 
        WHERE PaymentMethod NOT IN ('Cash', 'Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer')
    )
    BEGIN
        RAISERROR('Invalid payment method', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
    
    PRINT 'Business rules validated successfully';
END;
GO

-- Test business rules
BEGIN TRY
    -- Should fail - amount too low
    INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
    VALUES (1, 1, 1, GETDATE(), 5.00, 'Cash');
END TRY
BEGIN CATCH
    PRINT 'Rule violation: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    -- Should fail - quantity too high
    INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
    VALUES (1, 1, 150, GETDATE(), 1500.00, 'Cash');
END TRY
BEGIN CATCH
    PRINT 'Rule violation: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =============================================
-- Monitoring & Reporting Queries
-- =============================================

-- View recent audit trail
SELECT TOP 20
    TableName,
    RecordID,
    Action,
    FieldName,
    OldValue,
    NewValue,
    ChangedBy,
    ChangedDate
FROM AuditTrail
ORDER BY ChangedDate DESC;
GO

-- View unresolved inventory alerts
SELECT 
    ia.AlertType,
    p.ProductName,
    ia.CurrentStock,
    ia.Message,
    ia.CreatedDate
FROM InventoryAlerts ia
INNER JOIN Products p ON ia.ProductID = p.ProductID
WHERE ia.IsResolved = 0
ORDER BY ia.CreatedDate DESC;
GO

-- Price change analysis
SELECT 
    p.ProductName,
    COUNT(*) AS ChangeCount,
    MIN(ph.OldPrice) AS LowestPrice,
    MAX(ph.NewPrice) AS HighestPrice,
    AVG(ph.PercentChange) AS AvgPercentChange
FROM PriceHistory ph
INNER JOIN Products p ON ph.ProductID = p.ProductID
GROUP BY p.ProductName
HAVING COUNT(*) > 1
ORDER BY ChangeCount DESC;
GO

-- Customer summary accuracy check
SELECT 
    c.CustomerID,
    c.CustomerName,
    css.TotalOrders,
    COUNT(s.SaleID) AS ActualOrders,
    css.TotalRevenue,
    ISNULL(SUM(s.TotalAmount), 0) AS ActualRevenue,
    CASE 
        WHEN css.TotalOrders = COUNT(s.SaleID) AND ABS(css.TotalRevenue - ISNULL(SUM(s.TotalAmount), 0)) < 0.01 
        THEN 'ACCURATE' 
        ELSE 'MISMATCH' 
    END AS Status
FROM Customers c
LEFT JOIN CustomerSalesSummary css ON c.CustomerID = css.CustomerID
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName, css.TotalOrders, css.TotalRevenue;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP TRIGGER IF EXISTS trg_ComprehensiveAudit;
DROP TRIGGER IF EXISTS trg_MaintainSalesSummary;
DROP TRIGGER IF EXISTS trg_InventoryAlerts;
DROP TRIGGER IF EXISTS trg_PriceChangeTracking;
DROP TRIGGER IF EXISTS trg_CascadingUpdates;
DROP TRIGGER IF EXISTS trg_BusinessRuleEnforcement;

DROP TABLE IF EXISTS AuditTrail;
DROP TABLE IF EXISTS CustomerSalesSummary;
DROP TABLE IF EXISTS InventoryAlerts;
DROP TABLE IF EXISTS PriceHistory;
*/

-- 💡 Production Best Practices:
-- - Comprehensive audit trail for compliance and troubleshooting
-- - Maintain denormalized summaries for performance
-- - Proactive alerts for inventory management
-- - Track historical data for analysis and reporting
-- - Enforce business rules at database level
-- - Use table variables for multi-row operations
-- - Keep trigger logic focused and efficient
-- - Test with bulk operations
-- - Monitor trigger performance impact
-- - Document business rules clearly
-- - Consider using separate audit database for high-volume systems
-- - Implement alert resolution workflow
-- - Regular cleanup of old audit data
-- - Use indexed views for complex summaries when appropriate
