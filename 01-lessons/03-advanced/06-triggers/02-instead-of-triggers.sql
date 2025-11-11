-- ========================================
-- INSTEAD OF Triggers
-- ========================================

USE TechStore;
GO

-- Drop existing triggers
DROP TRIGGER IF EXISTS trg_SoftDeleteProducts;
DROP TRIGGER IF EXISTS trg_ValidateBeforeInsert;
DROP TRIGGER IF EXISTS trg_UpdateableView;
DROP TRIGGER IF EXISTS trg_ConditionalDelete;
GO

-- =============================================
-- Example 1: Soft Delete Pattern
-- =============================================

-- Add IsDeleted column if not exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE Products ADD IsDeleted BIT DEFAULT 0;
    UPDATE Products SET IsDeleted = 0 WHERE IsDeleted IS NULL;
END;
GO

CREATE TRIGGER trg_SoftDeleteProducts
ON Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Mark as deleted instead of actual deletion
    UPDATE p
    SET IsDeleted = 1,
        LastModified = GETDATE()
    FROM Products p
    INNER JOIN deleted d ON p.ProductID = d.ProductID;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' products marked as deleted';
END;
GO

-- Test soft delete
SELECT ProductID, ProductName, IsDeleted FROM Products WHERE ProductID = 2;

DELETE FROM Products WHERE ProductID = 2;  -- Executes soft delete

SELECT ProductID, ProductName, IsDeleted FROM Products WHERE ProductID = 2;

-- Restore soft-deleted product
UPDATE Products SET IsDeleted = 0 WHERE ProductID = 2;
GO

-- =============================================
-- Example 2: Data Validation Before Insert
-- =============================================

CREATE TRIGGER trg_ValidateBeforeInsert
ON Sales
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation 1: Check product stock availability
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN Products p ON i.ProductID = p.ProductID
        WHERE i.Quantity > p.StockQuantity
    )
    BEGIN
        RAISERROR('Insufficient stock for one or more products', 16, 1);
        RETURN;
    END;
    
    -- Validation 2: Check product is active
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN Products p ON i.ProductID = p.ProductID
        WHERE p.IsActive = 0 OR ISNULL(p.IsDeleted, 0) = 1
    )
    BEGIN
        RAISERROR('Cannot sell inactive or deleted products', 16, 1);
        RETURN;
    END;
    
    -- Validation 3: Ensure TotalAmount matches
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN Products p ON i.ProductID = p.ProductID
        WHERE ABS(i.TotalAmount - (i.Quantity * p.Price)) > 0.01
    )
    BEGIN
        RAISERROR('Total amount does not match quantity * price', 16, 1);
        RETURN;
    END;
    
    -- All validations passed - perform actual insert
    INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
    SELECT CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod
    FROM inserted;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' sales inserted after validation';
END;
GO

-- Test validation (should fail - insufficient stock)
BEGIN TRY
    INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
    VALUES (1, 1, 9999, GETDATE(), 99990.00, 'Cash');
END TRY
BEGIN CATCH
    PRINT 'Insert rejected: ' + ERROR_MESSAGE();
END CATCH;

-- Test validation (should succeed)
DECLARE @ProductPrice DECIMAL(10,2);
SELECT @ProductPrice = Price FROM Products WHERE ProductID = 1;

INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
VALUES (1, 1, 1, GETDATE(), @ProductPrice, 'Cash');
GO

-- =============================================
-- Example 3: Make View Updatable
-- =============================================

-- Create view combining multiple tables
DROP VIEW IF EXISTS vw_ProductSales;
GO

CREATE VIEW vw_ProductSales AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.StockQuantity,
    ISNULL(SUM(s.Quantity), 0) AS TotalSold,
    ISNULL(SUM(s.TotalAmount), 0) AS TotalRevenue
FROM Products p
LEFT JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName, p.Price, p.StockQuantity;
GO

-- Create INSTEAD OF UPDATE trigger on view
CREATE TRIGGER trg_UpdateableView
ON vw_ProductSales
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Only allow updates to Price and StockQuantity
    UPDATE p
    SET 
        Price = i.Price,
        StockQuantity = i.StockQuantity
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    PRINT 'View update redirected to Products table';
END;
GO

-- Test view update
SELECT * FROM vw_ProductSales WHERE ProductID = 1;

UPDATE vw_ProductSales SET Price = 189.99, StockQuantity = 75 WHERE ProductID = 1;

SELECT * FROM vw_ProductSales WHERE ProductID = 1;
GO

-- =============================================
-- Example 4: Conditional Delete Logic
-- =============================================

DROP TRIGGER IF EXISTS trg_ConditionalDelete;
GO

CREATE TRIGGER trg_ConditionalDelete
ON Customers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Customers with no sales: allow deletion
    DELETE FROM Customers
    WHERE CustomerID IN (
        SELECT d.CustomerID 
        FROM deleted d
        WHERE NOT EXISTS (
            SELECT 1 FROM Sales s WHERE s.CustomerID = d.CustomerID
        )
    );
    
    DECLARE @DeletedCount INT = @@ROWCOUNT;
    
    -- Customers with sales: mark inactive or archive
    UPDATE Customers
    SET CustomerName = CustomerName + ' (ARCHIVED)'
    WHERE CustomerID IN (
        SELECT d.CustomerID 
        FROM deleted d
        WHERE EXISTS (
            SELECT 1 FROM Sales s WHERE s.CustomerID = d.CustomerID
        )
    );
    
    DECLARE @ArchivedCount INT = @@ROWCOUNT;
    
    PRINT CAST(@DeletedCount AS VARCHAR(10)) + ' customers deleted';
    PRINT CAST(@ArchivedCount AS VARCHAR(10)) + ' customers archived';
END;
GO

-- Test conditional delete
SELECT CustomerID, CustomerName FROM Customers WHERE CustomerID IN (1, 2);

DELETE FROM Customers WHERE CustomerID = 1;  -- Has sales - will be archived

SELECT CustomerID, CustomerName FROM Customers WHERE CustomerID IN (1, 2);
GO

-- =============================================
-- Example 5: Complex Insert with Defaults
-- =============================================

DROP TRIGGER IF EXISTS trg_EnhancedInsert;
GO

CREATE TRIGGER trg_EnhancedInsert
ON Products
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Insert with business logic enhancements
    INSERT INTO Products (
        ProductName, 
        Category, 
        Price, 
        Cost,
        StockQuantity, 
        SupplierID, 
        IsActive,
        LastModified,
        IsDeleted
    )
    SELECT 
        UPPER(LEFT(ProductName, 1)) + LOWER(SUBSTRING(ProductName, 2, LEN(ProductName))),  -- Capitalize
        UPPER(Category),  -- Category uppercase
        Price,
        ISNULL(Cost, Price * 0.6),  -- Default cost if not provided
        ISNULL(StockQuantity, 0),  -- Default stock
        SupplierID,
        ISNULL(IsActive, 1),  -- Default active
        GETDATE(),  -- Auto timestamp
        0  -- Not deleted
    FROM inserted;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' products inserted with defaults';
END;
GO

-- Test enhanced insert (cost will default to 60% of price)
INSERT INTO Products (ProductName, Category, Price, SupplierID)
VALUES ('wireless mouse', 'electronics', 29.99, 1);

SELECT ProductID, ProductName, Category, Cost, IsActive, LastModified 
FROM Products 
WHERE ProductName LIKE 'Wireless mouse%';
GO

-- =============================================
-- Example 6: Prevent Duplicate Insert
-- =============================================

DROP TRIGGER IF EXISTS trg_PreventDuplicates;
GO

CREATE TRIGGER trg_PreventDuplicates
ON Customers
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for duplicates by name and city
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN Customers c ON i.CustomerName = c.CustomerName AND i.City = c.City
    )
    BEGIN
        RAISERROR('Customer with same name and city already exists', 16, 1);
        RETURN;
    END;
    
    -- No duplicates - proceed with insert
    INSERT INTO Customers (CustomerName, City, State, JoinDate, TotalPurchases)
    SELECT 
        CustomerName, 
        City, 
        State, 
        ISNULL(JoinDate, GETDATE()),  -- Default join date
        ISNULL(TotalPurchases, 0)
    FROM inserted;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' customers inserted';
END;
GO

-- Test duplicate prevention
BEGIN TRY
    -- First insert (should succeed)
    INSERT INTO Customers (CustomerName, City, State)
    VALUES ('Test Customer', 'Chicago', 'IL');
    
    -- Duplicate insert (should fail)
    INSERT INTO Customers (CustomerName, City, State)
    VALUES ('Test Customer', 'Chicago', 'IL');
END TRY
BEGIN CATCH
    PRINT 'Duplicate rejected: ' + ERROR_MESSAGE();
END CATCH;
GO

-- =============================================
-- Example 7: Audit Before Delete
-- =============================================

-- Create deleted records archive table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DeletedProductsArchive')
BEGIN
    CREATE TABLE DeletedProductsArchive (
        ArchiveID INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT,
        ProductName VARCHAR(100),
        Category VARCHAR(50),
        Price DECIMAL(10,2),
        DeletedBy VARCHAR(100),
        DeletedDate DATETIME
    );
END;
GO

DROP TRIGGER IF EXISTS trg_ArchiveBeforeDelete;
GO

CREATE TRIGGER trg_ArchiveBeforeDelete
ON Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Archive to history table
    INSERT INTO DeletedProductsArchive (ProductID, ProductName, Category, Price, DeletedBy, DeletedDate)
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        SUSER_SNAME(),
        GETDATE()
    FROM deleted;
    
    -- Perform actual delete
    DELETE FROM Products
    WHERE ProductID IN (SELECT ProductID FROM deleted);
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' products deleted and archived';
END;
GO

-- Test archive before delete
SELECT COUNT(*) AS ArchiveCountBefore FROM DeletedProductsArchive;

-- Create test product to delete
INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, SupplierID, IsActive)
VALUES ('Test Product to Delete', 'TEST', 9.99, 5.00, 0, 1, 0);

DECLARE @TestProductID INT = SCOPE_IDENTITY();

DELETE FROM Products WHERE ProductID = @TestProductID;

SELECT COUNT(*) AS ArchiveCountAfter FROM DeletedProductsArchive;
SELECT * FROM DeletedProductsArchive ORDER BY DeletedDate DESC;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP TRIGGER IF EXISTS trg_SoftDeleteProducts;
DROP TRIGGER IF EXISTS trg_ValidateBeforeInsert;
DROP TRIGGER IF EXISTS trg_UpdateableView;
DROP TRIGGER IF EXISTS trg_ConditionalDelete;
DROP TRIGGER IF EXISTS trg_EnhancedInsert;
DROP TRIGGER IF EXISTS trg_PreventDuplicates;
DROP TRIGGER IF EXISTS trg_ArchiveBeforeDelete;

DROP VIEW IF EXISTS vw_ProductSales;
DROP TABLE IF EXISTS DeletedProductsArchive;
ALTER TABLE Products DROP COLUMN IF EXISTS IsDeleted;
*/

-- 💡 Key Points:
-- - INSTEAD OF triggers replace the original INSERT/UPDATE/DELETE
-- - Must explicitly perform the operation if desired
-- - Ideal for soft deletes, validation, complex business logic
-- - Can make views updatable
-- - Only one INSTEAD OF trigger per action per table/view
-- - Use inserted and deleted tables same as AFTER triggers
-- - Complete control over what actually happens
-- - Great for data transformation before storage
-- - Can prevent operations by not executing them
-- - Remember to handle all rows (set-based operations)
