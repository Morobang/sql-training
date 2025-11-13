-- ========================================
-- Transactions in Stored Procedures
-- ========================================

USE TechStore;
GO

-- Drop existing procedures
DROP PROCEDURE IF EXISTS usp_TransferStock;
DROP PROCEDURE IF EXISTS usp_PlaceOrder;
DROP PROCEDURE IF EXISTS usp_SafeUpdatePrice;
DROP PROCEDURE IF EXISTS usp_BatchInsertProducts;
DROP PROCEDURE IF EXISTS usp_ProcessSaleWithLogging;
DROP PROCEDURE IF EXISTS usp_UpdateInventoryTransaction;
GO

-- =============================================
-- Example 1: Basic Transaction
-- =============================================

CREATE PROCEDURE usp_TransferStock
    @FromProductID INT,
    @ToProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Deduct from source product
        UPDATE Products
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductID = @FromProductID;
        
        -- Check if update was successful
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Source product not found', 16, 1);
            RETURN -1;
        END;
        
        -- Add to destination product
        UPDATE Products
        SET StockQuantity = StockQuantity + @Quantity
        WHERE ProductID = @ToProductID;
        
        -- Check if update was successful
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Destination product not found', 16, 1);
            RETURN -1;
        END;
        
        COMMIT TRANSACTION;
        PRINT 'Stock transfer completed successfully';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO

-- Test stock transfer
EXEC usp_TransferStock @FromProductID = 1, @ToProductID = 2, @Quantity = 5;

-- Verify changes
SELECT ProductID, ProductName, StockQuantity 
FROM Products 
WHERE ProductID IN (1, 2);
GO

-- =============================================
-- Example 2: Complex Transaction with Multiple Tables
-- =============================================

CREATE PROCEDURE usp_PlaceOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @PaymentMethod NVARCHAR(50),
    @NewSaleID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;  -- Auto-rollback on errors
    
    DECLARE @Price DECIMAL(10,2);
    DECLARE @TotalAmount DECIMAL(10,2);
    DECLARE @AvailableStock INT;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Step 1: Validate stock
        SELECT 
            @Price = Price,
            @AvailableStock = StockQuantity
        FROM Products
        WHERE ProductID = @ProductID AND IsActive = 1;
        
        IF @Price IS NULL
        BEGIN
            RAISERROR('Product not found or inactive', 16, 1);
            RETURN -1;
        END;
        
        IF @AvailableStock < @Quantity
        BEGIN
            RAISERROR('Insufficient stock available', 16, 1);
            RETURN -1;
        END;
        
        -- Step 2: Calculate total
        SET @TotalAmount = @Price * @Quantity;
        
        -- Step 3: Insert sale record
        INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
        VALUES (@CustomerID, @ProductID, @Quantity, GETDATE(), @TotalAmount, @PaymentMethod);
        
        SET @NewSaleID = SCOPE_IDENTITY();
        
        -- Step 4: Update product stock
        UPDATE Products
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductID = @ProductID;
        
        -- Step 5: Update customer total purchases
        UPDATE Customers
        SET TotalPurchases = TotalPurchases + @TotalAmount
        WHERE CustomerID = @CustomerID;
        
        COMMIT TRANSACTION;
        
        PRINT 'Order placed successfully';
        PRINT 'Sale ID: ' + CAST(@NewSaleID AS NVARCHAR(10));
        PRINT 'Total Amount: $' + CAST(@TotalAmount AS NVARCHAR(20));
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Order failed: ' + ERROR_MESSAGE();
        SET @NewSaleID = NULL;
        RETURN -1;
    END CATCH;
END;
GO

-- Place an order
DECLARE @SaleID INT;
EXEC usp_PlaceOrder
    @CustomerID = 1,
    @ProductID = 1,
    @Quantity = 2,
    @PaymentMethod = 'Credit Card',
    @NewSaleID = @SaleID OUTPUT;

IF @SaleID IS NOT NULL
    PRINT 'Success! Sale ID: ' + CAST(@SaleID AS NVARCHAR(10));
GO

-- =============================================
-- Example 3: Transaction with Savepoints
-- =============================================

CREATE PROCEDURE usp_SafeUpdatePrice
    @ProductID INT,
    @NewPrice DECIMAL(10,2),
    @NewCost DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @OldPrice DECIMAL(10,2);
    DECLARE @OldCost DECIMAL(10,2);
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Save original values
        SELECT 
            @OldPrice = Price,
            @OldCost = Cost
        FROM Products
        WHERE ProductID = @ProductID;
        
        IF @OldPrice IS NULL
        BEGIN
            RAISERROR('Product not found', 16, 1);
            RETURN -1;
        END;
        
        -- Create savepoint before price update
        SAVE TRANSACTION PriceUpdate;
        
        -- Update price
        UPDATE Products
        SET Price = @NewPrice
        WHERE ProductID = @ProductID;
        
        PRINT 'Price updated: $' + CAST(@OldPrice AS NVARCHAR(20)) + ' -> $' + CAST(@NewPrice AS NVARCHAR(20));
        
        -- Update cost if provided
        IF @NewCost IS NOT NULL
        BEGIN
            -- Create savepoint before cost update
            SAVE TRANSACTION CostUpdate;
            
            UPDATE Products
            SET Cost = @NewCost
            WHERE ProductID = @ProductID;
            
            PRINT 'Cost updated: $' + CAST(@OldCost AS NVARCHAR(20)) + ' -> $' + CAST(@NewCost AS NVARCHAR(20));
            
            -- Validate profit margin
            IF @NewPrice < @NewCost
            BEGIN
                PRINT 'Warning: Price is less than cost (negative margin)';
                PRINT 'Rolling back cost update only';
                ROLLBACK TRANSACTION CostUpdate;
            END;
        END;
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO

-- Test with valid values
EXEC usp_SafeUpdatePrice @ProductID = 1, @NewPrice = 149.99, @NewCost = 75.00;

-- Test with invalid cost (higher than price)
EXEC usp_SafeUpdatePrice @ProductID = 1, @NewPrice = 149.99, @NewCost = 200.00;
GO

-- =============================================
-- Example 4: Nested Transactions (Transaction Counter)
-- =============================================

CREATE PROCEDURE usp_BatchInsertProducts
    @ProductCount INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Counter INT = 1;
    DECLARE @TranCount INT;
    
    -- Check if already in transaction
    SET @TranCount = @@TRANCOUNT;
    
    IF @TranCount = 0
        BEGIN TRANSACTION;
    
    BEGIN TRY
        WHILE @Counter <= @ProductCount
        BEGIN
            INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, IsActive)
            VALUES (
                'Test Product ' + CAST(@Counter AS NVARCHAR(10)),
                'Test Category',
                10.00 * @Counter,
                5.00 * @Counter,
                100,
                1
            );
            
            SET @Counter = @Counter + 1;
        END;
        
        -- Only commit if we started the transaction
        IF @TranCount = 0
            COMMIT TRANSACTION;
        
        PRINT CAST(@ProductCount AS NVARCHAR(10)) + ' products inserted successfully';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Only rollback if we started the transaction
        IF @TranCount = 0 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Error inserting products: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO

-- Test batch insert
EXEC usp_BatchInsertProducts @ProductCount = 3;

-- Verify
SELECT * FROM Products WHERE ProductName LIKE 'Test Product%';

-- Cleanup test products
DELETE FROM Products WHERE ProductName LIKE 'Test Product%';
GO

-- =============================================
-- Example 5: Transaction with @@TRANCOUNT Check
-- =============================================

CREATE PROCEDURE usp_ProcessSaleWithLogging
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTranCount INT = @@TRANCOUNT;
    
    BEGIN TRY
        IF @StartTranCount = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION ProcessSale;
        
        -- Simulate sale processing
        DECLARE @Price DECIMAL(10,2);
        SELECT @Price = Price FROM Products WHERE ProductID = @ProductID;
        
        INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
        VALUES (@CustomerID, @ProductID, @Quantity, GETDATE(), @Price * @Quantity, 'Cash');
        
        PRINT 'Sale processed for Customer ' + CAST(@CustomerID AS NVARCHAR(10));
        
        -- Commit only if we started the transaction
        IF @StartTranCount = 0
            COMMIT TRANSACTION;
        
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Handle rollback based on transaction depth
        IF XACT_STATE() = -1  -- Uncommittable transaction
        BEGIN
            PRINT 'Transaction is uncommittable, rolling back';
            IF @StartTranCount = 0
                ROLLBACK TRANSACTION;
        END
        ELSE IF XACT_STATE() = 1  -- Committable transaction
        BEGIN
            PRINT 'Transaction is committable';
            IF @StartTranCount > 0
                ROLLBACK TRANSACTION ProcessSale;  -- Rollback to savepoint
            ELSE
                ROLLBACK TRANSACTION;
        END;
        
        PRINT 'Error: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;
GO

-- Test the procedure
EXEC usp_ProcessSaleWithLogging @CustomerID = 1, @ProductID = 1, @Quantity = 1;
GO

-- =============================================
-- Example 6: Transaction Isolation Level
-- =============================================

CREATE PROCEDURE usp_UpdateInventoryTransaction
    @ProductID INT,
    @QuantityChange INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;  -- Highest isolation
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @CurrentStock INT;
        
        -- Read current stock with lock
        SELECT @CurrentStock = StockQuantity
        FROM Products WITH (UPDLOCK)  -- Update lock
        WHERE ProductID = @ProductID;
        
        IF @CurrentStock IS NULL
        BEGIN
            RAISERROR('Product not found', 16, 1);
            RETURN -1;
        END;
        
        -- Check if new quantity would be negative
        IF @CurrentStock + @QuantityChange < 0
        BEGIN
            RAISERROR('Insufficient stock for this operation', 16, 1);
            RETURN -1;
        END;
        
        -- Update stock
        UPDATE Products
        SET StockQuantity = StockQuantity + @QuantityChange
        WHERE ProductID = @ProductID;
        
        PRINT 'Stock updated: ' + CAST(@CurrentStock AS NVARCHAR(10)) + 
              ' -> ' + CAST(@CurrentStock + @QuantityChange AS NVARCHAR(10));
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;
GO

-- Test inventory update
EXEC usp_UpdateInventoryTransaction @ProductID = 1, @QuantityChange = -5;
EXEC usp_UpdateInventoryTransaction @ProductID = 1, @QuantityChange = 10;
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP PROCEDURE IF EXISTS usp_TransferStock;
DROP PROCEDURE IF EXISTS usp_PlaceOrder;
DROP PROCEDURE IF EXISTS usp_SafeUpdatePrice;
DROP PROCEDURE IF EXISTS usp_BatchInsertProducts;
DROP PROCEDURE IF EXISTS usp_ProcessSaleWithLogging;
DROP PROCEDURE IF EXISTS usp_UpdateInventoryTransaction;
*/

-- 💡 Key Points:
-- - Always wrap DML in BEGIN TRANSACTION / COMMIT
-- - Use TRY...CATCH for error handling
-- - SET XACT_ABORT ON for automatic rollback
-- - Check @@TRANCOUNT to avoid nested transaction issues
-- - Use SAVE TRANSACTION for partial rollbacks
-- - XACT_STATE() returns: -1 (uncommittable), 0 (no transaction), 1 (committable)
-- - SET TRANSACTION ISOLATION LEVEL for concurrency control
-- - Use WITH (UPDLOCK) to prevent phantom reads
-- - Always ROLLBACK in CATCH block if transaction is open
-- - Test transactions with both success and failure scenarios
