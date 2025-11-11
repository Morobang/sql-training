-- ========================================
-- Error Handling with Transactions
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Basic Transaction with Error Handling
-- =============================================

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Operation 1: Update product price
        UPDATE Products 
        SET Price = Price * 1.1
        WHERE ProductID = 1;
        
        -- Operation 2: Insert sale record
        INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
        VALUES (1, 1, 2, GETDATE(), 200.00, 'Credit Card');
        
        PRINT '✅ Both operations successful';
    
    COMMIT TRANSACTION;
    PRINT '✅ Transaction committed';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT '❌ Transaction rolled back';
    END;
    
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 2: Multiple Updates with Rollback
-- =============================================

-- Show current state
SELECT ProductID, Price, StockQuantity 
FROM Products 
WHERE ProductID IN (1, 2, 3);

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Update 1
        UPDATE Products SET Price = 999.99 WHERE ProductID = 1;
        PRINT 'Updated Product 1';
        
        -- Update 2
        UPDATE Products SET Price = 899.99 WHERE ProductID = 2;
        PRINT 'Updated Product 2';
        
        -- Update 3 - This will fail (invalid value)
        UPDATE Products SET Price = 'invalid' WHERE ProductID = 3;
        PRINT 'Updated Product 3';  -- Won't execute
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT '❌ All updates rolled back due to error';
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- Verify rollback - prices should be unchanged
SELECT ProductID, Price, StockQuantity 
FROM Products 
WHERE ProductID IN (1, 2, 3);

-- =============================================
-- Example 3: Savepoints for Partial Rollback
-- =============================================

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- First operation
        UPDATE Products SET Price = 100.00 WHERE ProductID = 1;
        SAVE TRANSACTION SavePoint1;
        PRINT 'SavePoint1 created after Product 1 update';
        
        -- Second operation
        UPDATE Products SET Price = 200.00 WHERE ProductID = 2;
        SAVE TRANSACTION SavePoint2;
        PRINT 'SavePoint2 created after Product 2 update';
        
        -- Third operation fails
        UPDATE Products SET Price = 'bad' WHERE ProductID = 3;
    
    COMMIT TRANSACTION;
    
END TRY
BEGIN CATCH
    -- Rollback to last savepoint or entire transaction
    IF @@TRANCOUNT > 0
    BEGIN
        -- Option 1: Rollback everything
        ROLLBACK TRANSACTION;
        PRINT 'Rolled back entire transaction';
        
        -- Option 2: Rollback to specific savepoint (if you catch earlier)
        -- ROLLBACK TRANSACTION SavePoint2;
        -- COMMIT TRANSACTION;
    END;
    
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 4: Nested Transactions
-- =============================================

DECLARE @TranCount INT;

BEGIN TRY
    SET @TranCount = @@TRANCOUNT;
    PRINT 'Initial TRANCOUNT: ' + CAST(@TranCount AS VARCHAR);
    
    BEGIN TRANSACTION;  -- Outer transaction
    PRINT 'Outer transaction started. TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);
    
        UPDATE Products SET Price = 150.00 WHERE ProductID = 1;
        
        BEGIN TRANSACTION;  -- Inner transaction (increases count)
        PRINT 'Inner transaction started. TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);
        
            UPDATE Products SET Price = 250.00 WHERE ProductID = 2;
            
            -- Error in inner transaction
            SELECT 1 / 0;
        
        COMMIT TRANSACTION;  -- Inner commit
    
    COMMIT TRANSACTION;  -- Outer commit
    
END TRY
BEGIN CATCH
    PRINT 'Error occurred. TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);
    
    -- Rollback all nested transactions
    WHILE @@TRANCOUNT > @TranCount
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT 'Rolled back transaction. TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);
    END;
    
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 5: XACT_ABORT Setting
-- =============================================

-- Default behavior (XACT_ABORT OFF)
PRINT '=== Test with XACT_ABORT OFF ===';
SET XACT_ABORT OFF;

BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    PRINT 'Update 1 complete';
    
    -- This will error but transaction continues
    INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
    VALUES (1, 'Duplicate', 'City', 'CA', GETDATE());  -- Duplicate key
    PRINT 'This line executes even after error!';
    
    UPDATE Products SET Price = 200 WHERE ProductID = 2;
    PRINT 'Update 2 complete';
ROLLBACK TRANSACTION;

-- With XACT_ABORT ON
PRINT '';
PRINT '=== Test with XACT_ABORT ON ===';
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE Products SET Price = 100 WHERE ProductID = 1;
        PRINT 'Update 1 complete';
        
        -- This will error and immediately rollback
        INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
        VALUES (1, 'Duplicate', 'City', 'CA', GETDATE());
        
        PRINT 'This line does NOT execute';
        
        UPDATE Products SET Price = 200 WHERE ProductID = 2;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Transaction automatically aborted';
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

SET XACT_ABORT OFF;  -- Reset to default

-- =============================================
-- Example 6: Comprehensive Transaction Pattern
-- =============================================

CREATE OR ALTER PROCEDURE ProcessOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TranStarted BIT = 0;
    
    BEGIN TRY
        -- Start transaction
        BEGIN TRANSACTION;
        SET @TranStarted = 1;
        
        -- Check stock availability
        DECLARE @Available INT;
        SELECT @Available = StockQuantity 
        FROM Products 
        WHERE ProductID = @ProductID;
        
        IF @Available IS NULL
            THROW 50001, 'Product not found', 1;
        
        IF @Available < @Quantity
        BEGIN
            DECLARE @Msg NVARCHAR(200);
            SET @Msg = 'Insufficient stock. Available: ' + CAST(@Available AS VARCHAR) + ', Requested: ' + CAST(@Quantity AS VARCHAR);
            THROW 50002, @Msg, 1;
        END;
        
        -- Reduce stock
        UPDATE Products 
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductID = @ProductID;
        
        -- Create sale record
        DECLARE @Price DECIMAL(10,2);
        SELECT @Price = Price FROM Products WHERE ProductID = @ProductID;
        
        INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
        VALUES (@CustomerID, @ProductID, @Quantity, GETDATE(), @Price * @Quantity, 'Credit Card');
        
        -- Commit if all successful
        COMMIT TRANSACTION;
        SET @TranStarted = 0;
        
        PRINT '✅ Order processed successfully';
        
    END TRY
    BEGIN CATCH
        -- Rollback if error occurred
        IF @TranStarted = 1 AND @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT '❌ Order processing failed - rolled back';
        END;
        
        -- Log error details
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        
        PRINT 'Error ' + CAST(@ErrorNumber AS VARCHAR) + ' at line ' + CAST(@ErrorLine AS VARCHAR);
        PRINT 'Message: ' + @ErrorMessage;
        
        -- Re-throw to caller
        THROW;
    END CATCH;
END;
GO

-- Test the procedure
EXEC ProcessOrder @CustomerID = 1, @ProductID = 1, @Quantity = 2;     -- Success
EXEC ProcessOrder @CustomerID = 1, @ProductID = 999, @Quantity = 1;   -- Product not found
EXEC ProcessOrder @CustomerID = 1, @ProductID = 1, @Quantity = 1000;  -- Insufficient stock

DROP PROCEDURE ProcessOrder;

-- =============================================
-- Example 7: Transaction Isolation Levels
-- =============================================

-- Set isolation level for transaction
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
    SELECT * FROM Products WHERE ProductID = 1;
    -- Other sessions can read but not modify this row
COMMIT TRANSACTION;

-- Higher isolation to prevent dirty reads
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRY
    BEGIN TRANSACTION;
        SELECT * FROM Products WHERE Category = 'Electronics';
        -- No other sessions can modify these rows
        
        WAITFOR DELAY '00:00:02';  -- Simulate processing
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- Reset

-- 💡 Key Points:
-- - Always check @@TRANCOUNT before ROLLBACK
-- - Use TRY...CATCH to handle transaction errors
-- - COMMIT only when all operations succeed
-- - ROLLBACK on any error to maintain data integrity
-- - SET XACT_ABORT ON for automatic rollback
-- - Use SAVE TRANSACTION for partial rollback
-- - Track transaction start with flag variable
-- - Re-throw errors after cleanup for proper handling
