-- ========================================
-- THROW vs RAISERROR
-- ========================================

USE TechStore;

-- =============================================
-- Example 1: Basic RAISERROR
-- =============================================

BEGIN TRY
    -- RAISERROR syntax: message, severity, state
    RAISERROR('This is a custom error message', 16, 1);
END TRY
BEGIN CATCH
    PRINT 'Caught RAISERROR:';
    PRINT ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 2: Basic THROW
-- =============================================

BEGIN TRY
    -- THROW syntax (simpler): just the message
    THROW 50001, 'This is a custom error with THROW', 1;
END TRY
BEGIN CATCH
    PRINT 'Caught THROW:';
    PRINT ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 3: RAISERROR with Parameters
-- =============================================

DECLARE @ProductID INT = 123;
DECLARE @StockLevel INT = 5;

BEGIN TRY
    -- RAISERROR supports printf-style formatting
    RAISERROR('Product %d has low stock: %d units remaining', 16, 1, @ProductID, @StockLevel);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    -- Output: "Product 123 has low stock: 5 units remaining"
END CATCH;

-- =============================================
-- Example 4: THROW with Formatted Message
-- =============================================

DECLARE @ProdID INT = 123;
DECLARE @Stock INT = 5;

BEGIN TRY
    -- THROW requires pre-formatted message
    DECLARE @ErrorMsg NVARCHAR(2048);
    SET @ErrorMsg = 'Product ' + CAST(@ProdID AS VARCHAR) + ' has low stock: ' + CAST(@Stock AS VARCHAR) + ' units remaining';
    
    THROW 50001, @ErrorMsg, 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 5: Re-throwing Errors with THROW
-- =============================================

BEGIN TRY
    BEGIN TRY
        -- Original error
        SELECT 1 / 0;
    END TRY
    BEGIN CATCH
        PRINT 'Inner CATCH: Logging error...';
        
        -- Re-throw without parameters (preserves original error)
        THROW;
    END CATCH;
END TRY
BEGIN CATCH
    PRINT 'Outer CATCH: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH;

-- =============================================
-- Example 6: RAISERROR Cannot Re-throw
-- =============================================

BEGIN TRY
    BEGIN TRY
        SELECT 1 / 0;
    END TRY
    BEGIN CATCH
    -- RAISERROR creates NEW error (loses original error number)
    -- Use formatted RAISERROR to include the original message
    RAISERROR('%s', 16, 1, ERROR_MESSAGE());
    END CATCH;
END TRY
BEGIN CATCH
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);  -- Will be 50000, not 8134
    PRINT 'Message: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 7: Severity Levels
-- =============================================

-- RAISERROR: Full control over severity
BEGIN TRY
    RAISERROR('Warning message', 10, 1);  -- Severity 10 (not caught)
END TRY
BEGIN CATCH
    PRINT 'This will not print';
END CATCH;

BEGIN TRY
    RAISERROR('Error message', 16, 1);  -- Severity 16 (caught)
END TRY
BEGIN CATCH
    PRINT 'This will print';
END CATCH;

-- THROW: Always severity 16
BEGIN TRY
    THROW 50001, 'THROW always uses severity 16', 1;
END TRY
BEGIN CATCH
    PRINT 'Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);  -- Always 16
END CATCH;

-- =============================================
-- Example 8: Transaction Handling Differences
-- =============================================

-- RAISERROR with XACT_ABORT OFF (default)
SET XACT_ABORT OFF;
BEGIN TRANSACTION;
    PRINT 'Transaction started';
    
    BEGIN TRY
        INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
        VALUES (999, 'Test', 'Test', 'CA', GETDATE());
        
        RAISERROR('Error with RAISERROR', 16, 1);
        
        -- Transaction is still open (can continue)
        PRINT 'After RAISERROR - Transaction state: ' + CAST(@@TRANCOUNT AS VARCHAR);
    END TRY
    BEGIN CATCH
        PRINT 'Error caught, transaction still active';
        ROLLBACK TRANSACTION;
    END CATCH;

-- THROW immediately aborts transaction
BEGIN TRANSACTION;
    PRINT 'Transaction started';
    
    BEGIN TRY
        INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
        VALUES (998, 'Test2', 'Test', 'CA', GETDATE());
        
        THROW 50001, 'Error with THROW', 1;
        
        PRINT 'This will not execute';
    END TRY
    BEGIN CATCH
        PRINT 'Error caught';
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
    END CATCH;

-- =============================================
-- Example 9: When to Use RAISERROR vs THROW
-- =============================================

-- Use RAISERROR when:
-- ✅ Need formatted messages with parameters
-- ✅ Need specific severity levels (10, 11, etc.)
-- ✅ Working with older SQL Server (< 2012)
-- ✅ Want transaction to continue after error

-- Use THROW when:
-- ✅ Need to re-throw original error
-- ✅ Want simpler syntax
-- ✅ Want to immediately abort transaction
-- ✅ Working with SQL Server 2012+

-- Example: RAISERROR for formatted output
DECLARE @Count INT = 5;
BEGIN TRY
    IF @Count < 10
        RAISERROR('Count is %d, expected at least 10', 16, 1, @Count);
END TRY
BEGIN CATCH
    PRINT 'RAISERROR: ' + ERROR_MESSAGE();
END CATCH;

-- Example: THROW for simple errors
BEGIN TRY
    IF @Count < 10
    BEGIN
        DECLARE @Msg NVARCHAR(100) = 'Count is ' + CAST(@Count AS VARCHAR) + ', expected at least 10';
        THROW 50001, @Msg, 1;
    END;
END TRY
BEGIN CATCH
    PRINT 'THROW: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 10: Practical Error Handling Pattern
-- =============================================

CREATE OR ALTER PROCEDURE UpdateProductStock
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validation
        IF @Quantity <= 0
            THROW 50001, 'Quantity must be positive', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
        BEGIN
            DECLARE @ErrMsg NVARCHAR(100);
            SET @ErrMsg = 'Product ' + CAST(@ProductID AS VARCHAR) + ' not found';
            THROW 50002, @ErrMsg, 1;
        END;
        
        -- Check stock
        DECLARE @CurrentStock INT;
        SELECT @CurrentStock = StockQuantity FROM Products WHERE ProductID = @ProductID;
        
        IF @CurrentStock < @Quantity
            RAISERROR('Insufficient stock. Available: %d, Requested: %d', 16, 1, @CurrentStock, @Quantity);
        
        -- Update stock
        UPDATE Products 
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductID = @ProductID;
        
        PRINT '✅ Stock updated successfully';
        
    END TRY
    BEGIN CATCH
        -- Log error details
        PRINT '❌ Error in UpdateProductStock:';
        PRINT 'Error ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE();
        PRINT 'Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
        PRINT 'Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        
        -- Re-throw to calling code
        THROW;
    END CATCH;
END;
GO

-- Test the procedure
EXEC UpdateProductStock @ProductID = 1, @Quantity = 2;      -- Success
EXEC UpdateProductStock @ProductID = 999, @Quantity = 5;    -- Not found
EXEC UpdateProductStock @ProductID = 1, @Quantity = -5;     -- Invalid quantity
EXEC UpdateProductStock @ProductID = 1, @Quantity = 1000;   -- Insufficient stock

DROP PROCEDURE UpdateProductStock;

-- 💡 Key Differences:
-- ┌──────────────────┬────────────────────┬────────────────────┐
-- │ Feature          │ RAISERROR          │ THROW              │
-- ├──────────────────┼────────────────────┼────────────────────┤
-- │ SQL Version      │ All versions       │ 2012+              │
-- │ Syntax           │ Complex            │ Simple             │
-- │ Parameters       │ Printf-style       │ Pre-formatted      │
-- │ Severity         │ Configurable       │ Always 16          │
-- │ Re-throw         │ No (new error)     │ Yes (THROW;)       │
-- │ Transaction      │ Continues          │ Aborts             │
-- │ Error Number     │ 50000 (custom)     │ 50000+ (custom)    │
-- └──────────────────┴────────────────────┴────────────────────┘
