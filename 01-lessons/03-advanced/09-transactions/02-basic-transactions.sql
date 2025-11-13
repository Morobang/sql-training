-- ========================================
-- Basic Transactions
-- BEGIN TRAN, COMMIT, ROLLBACK, Savepoints
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Simple Transaction - COMMIT
-- =============================================

-- Start transaction
BEGIN TRANSACTION;

    -- Make changes
    UPDATE Products 
    SET Price = Price * 1.1 
    WHERE Category = 'Electronics';
    
    -- Check changes (not yet committed)
    SELECT ProductName, Price 
    FROM Products 
    WHERE Category = 'Electronics';
    
-- Make changes permanent
COMMIT TRANSACTION;

PRINT 'Transaction committed - price increases are permanent';
GO

-- =============================================
-- Example 2: Simple Transaction - ROLLBACK
-- =============================================

-- Start transaction
BEGIN TRANSACTION;

    -- Make changes
    UPDATE Products 
    SET Price = 0 
    WHERE ProductID = 1;
    
    -- Check change
    SELECT ProductName, Price FROM Products WHERE ProductID = 1;
    -- Shows Price = 0 within transaction
    
-- Undo all changes
ROLLBACK TRANSACTION;

-- Verify rollback
SELECT ProductName, Price FROM Products WHERE ProductID = 1;
-- Price is back to original value

PRINT 'Transaction rolled back - no changes persisted';
GO

-- =============================================
-- Example 3: Transaction with Error Handling
-- =============================================

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Valid update
        UPDATE Products 
        SET StockQuantity = StockQuantity - 5 
        WHERE ProductID = 1;
        
        -- Invalid update (negative stock)
        UPDATE Products 
        SET StockQuantity = -100 
        WHERE ProductID = 2;
        
    COMMIT TRANSACTION;
    PRINT 'Transaction committed';
    
END TRY
BEGIN CATCH
    -- Error occurred, rollback
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Transaction rolled back';
END CATCH;
GO

-- =============================================
-- Example 4: Check @@TRANCOUNT
-- =============================================

PRINT 'Transaction count: ' + CAST(@@TRANCOUNT AS VARCHAR(10));
-- Should be 0 (no active transaction)

BEGIN TRANSACTION;
PRINT 'After BEGIN: ' + CAST(@@TRANCOUNT AS VARCHAR(10));
-- Should be 1

    BEGIN TRANSACTION;  -- Nested
    PRINT 'After nested BEGIN: ' + CAST(@@TRANCOUNT AS VARCHAR(10));
    -- Should be 2
    
    COMMIT;  -- Commits innermost only
    PRINT 'After first COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR(10));
    -- Should be 1

COMMIT;  -- Commits outer transaction
PRINT 'After final COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR(10));
-- Should be 0
GO

-- =============================================
-- Example 5: Savepoints for Partial Rollback
-- =============================================

BEGIN TRANSACTION;

    -- First update
    UPDATE Products SET Price = Price + 10 WHERE Category = 'Books';
    PRINT 'Increased book prices by $10';
    
    -- Create savepoint
    SAVE TRANSACTION SavePoint1;
    
    -- Second update
    UPDATE Products SET StockQuantity = 0 WHERE Category = 'Books';
    PRINT 'Set all book stock to 0';
    
    -- Oops! That was a mistake. Rollback to savepoint
    ROLLBACK TRANSACTION SavePoint1;
    PRINT 'Rolled back stock change, but kept price change';
    
    -- Verify: Price changed, but stock not changed
    SELECT ProductName, Price, StockQuantity 
    FROM Products 
    WHERE Category = 'Books';

COMMIT TRANSACTION;
PRINT 'Transaction committed with savepoint rollback';
GO

-- =============================================
-- Example 6: Multiple Savepoints
-- =============================================

BEGIN TRANSACTION;

    -- Step 1: Update prices
    UPDATE Products SET Price = Price * 1.05 WHERE Category = 'Electronics';
    SAVE TRANSACTION Step1;
    PRINT 'Step 1: Prices increased 5%';
    
    -- Step 2: Update stock
    UPDATE Products SET StockQuantity = StockQuantity + 10 WHERE Category = 'Electronics';
    SAVE TRANSACTION Step2;
    PRINT 'Step 2: Stock increased by 10';
    
    -- Step 3: Update supplier (error!)
    UPDATE Products SET SupplierID = 999 WHERE Category = 'Electronics';
    PRINT 'Step 3: Supplier updated (but supplier 999 may not exist)';
    
    -- Rollback just step 3
    ROLLBACK TRANSACTION Step2;
    PRINT 'Rolled back to Step 2 (undid supplier change and stock change)';
    
    -- Verify: Price changed, stock and supplier unchanged
    SELECT ProductName, Price, StockQuantity, SupplierID 
    FROM Products 
    WHERE Category = 'Electronics';

COMMIT TRANSACTION;
PRINT 'Committed transaction keeping only price changes';
GO

-- =============================================
-- Example 7: SET XACT_ABORT ON
-- =============================================

-- Without XACT_ABORT (default behavior)
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    UPDATE Products SET Price = 1/0 WHERE ProductID = 2;  -- Division by zero error
    -- Transaction remains open after error!
    PRINT 'This line executes even after error';
ROLLBACK TRANSACTION;  -- Must explicitly rollback
GO

-- With XACT_ABORT ON (recommended)
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE Products SET Price = 100 WHERE ProductID = 1;
        UPDATE Products SET Price = 1/0 WHERE ProductID = 2;  -- Division by zero error
        -- Transaction automatically rolled back
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT 'Error caught: ' + ERROR_MESSAGE();
    PRINT 'Transaction auto-rolled back due to XACT_ABORT';
END CATCH;

SET XACT_ABORT OFF;
GO

-- =============================================
-- Example 8: XACT_STATE Function
-- =============================================

/*
XACT_STATE() returns:
-1 = Uncommittable transaction (must rollback)
 0 = No active transaction
 1 = Committable transaction
*/

BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE Products SET Price = Price + 1;
        
        -- Check transaction state
        IF XACT_STATE() = 1
            PRINT 'Transaction is active and committable';
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() = -1
    BEGIN
        PRINT 'Transaction is uncommittable - must rollback';
        ROLLBACK TRANSACTION;
    END
    ELSE IF XACT_STATE() = 1
    BEGIN
        PRINT 'Transaction is committable - can commit or rollback';
        COMMIT TRANSACTION;
    END
END CATCH;
GO

-- =============================================
-- Example 9: Implicit Transactions
-- =============================================

-- Set implicit transaction mode (not recommended)
SET IMPLICIT_TRANSACTIONS ON;

-- Any DML starts a transaction automatically
UPDATE Products SET Price = 100 WHERE ProductID = 1;
-- Transaction is now open!

PRINT 'Transaction count: ' + CAST(@@TRANCOUNT AS VARCHAR(10));
-- Shows 1 (implicit transaction started)

-- Must explicitly commit
COMMIT;

SET IMPLICIT_TRANSACTIONS OFF;
GO

-- =============================================
-- Example 10: Transaction Isolation and Locks
-- =============================================

-- Transaction holds locks until commit/rollback
BEGIN TRANSACTION;

    -- Acquire exclusive lock on Product 1
    UPDATE Products SET Price = 999 WHERE ProductID = 1;
    
    -- Lock is held here...
    PRINT 'Lock acquired on Product 1';
    
    -- Simulate work (in reality, keep transactions short!)
    WAITFOR DELAY '00:00:02';
    
    -- Lock released on commit
COMMIT TRANSACTION;

PRINT 'Lock released after commit';
GO

-- =============================================
-- Example 11: Transaction with Multiple Tables
-- =============================================

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Insert into Sales
        INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
        VALUES (1, 1, 2, GETDATE(), 199.98, 'Credit Card');
        
        DECLARE @SaleID INT = SCOPE_IDENTITY();
        
        -- Update customer total purchases
        UPDATE Customers 
        SET TotalPurchases = TotalPurchases + 199.98 
        WHERE CustomerID = 1;
        
        -- Update product stock
        UPDATE Products 
        SET StockQuantity = StockQuantity - 2 
        WHERE ProductID = 1;
        
    COMMIT TRANSACTION;
    PRINT 'Multi-table transaction committed successfully';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'All changes rolled back';
END CATCH;
GO

-- =============================================
-- Example 12: Nested Transactions (Be Careful!)
-- =============================================

/*
WARNING: SQL Server doesn't truly support nested transactions.
Only the outermost COMMIT actually commits.
Inner COMMITs just decrement @@TRANCOUNT.
Any ROLLBACK rolls back the entire transaction!
*/

BEGIN TRANSACTION;  -- Outer
PRINT 'Outer transaction started. @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(10));

    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    
    BEGIN TRANSACTION;  -- Inner
    PRINT 'Inner transaction started. @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(10));
    
        UPDATE Products SET Price = 200 WHERE ProductID = 2;
        
    COMMIT;  -- Inner commit (just decrements count)
    PRINT 'Inner commit. @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(10));

COMMIT;  -- Outer commit (actually commits)
PRINT 'Outer commit. @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR(10));

-- Both updates are committed
SELECT ProductID, Price FROM Products WHERE ProductID IN (1, 2);
GO

-- =============================================
-- Example 13: Transaction Timeout
-- =============================================

-- Set lock timeout (milliseconds)
SET LOCK_TIMEOUT 5000;  -- 5 seconds

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- This might timeout if another session holds locks
        UPDATE Products SET Price = 100 WHERE ProductID = 1;
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 1222  -- Lock timeout error
        PRINT 'Transaction timed out waiting for lock';
    ELSE
        PRINT 'Error: ' + ERROR_MESSAGE();
        
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;

SET LOCK_TIMEOUT -1;  -- Reset to wait indefinitely
GO

-- =============================================
-- Example 14: Transaction Best Practices
-- =============================================

-- ✅ GOOD: Short transaction, error handling, XACT_ABORT
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Do all calculations BEFORE transaction
        DECLARE @NewPrice DECIMAL(10,2);
        SELECT @NewPrice = Price * 1.1 FROM Products WHERE ProductID = 1;
        
        -- Quick updates only
        UPDATE Products SET Price = @NewPrice WHERE ProductID = 1;
        UPDATE Products SET LastModified = GETDATE() WHERE ProductID = 1;
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SET XACT_ABORT OFF;
GO

-- ❌ BAD: Long transaction with I/O
/*
BEGIN TRANSACTION;
    -- Don't do this!
    EXEC sp_send_dbmail ...;  -- External I/O
    WAITFOR DELAY '00:01:00';  -- Long wait
    SELECT * FROM VeryLargeTable;  -- Expensive query
COMMIT;
*/

-- =============================================
-- Example 15: Checking Transaction Status
-- =============================================

-- Create procedure to safely handle transactions
CREATE OR ALTER PROCEDURE usp_SafeUpdate
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRY
        -- Check if already in transaction
        DECLARE @TranStarted BIT = 0;
        
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TranStarted = 1;
        END
        
        -- Do work
        UPDATE Products 
        SET Price = @NewPrice,
            LastModified = GETDATE()
        WHERE ProductID = @ProductID;
        
        -- Commit only if we started it
        IF @TranStarted = 1
            COMMIT TRANSACTION;
            
    END TRY
    BEGIN CATCH
        -- Rollback only if we started transaction
        IF @TranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH;
END;
GO

-- Test the procedure
EXEC usp_SafeUpdate @ProductID = 1, @NewPrice = 149.99;
GO

-- =============================================
-- Cleanup
-- =============================================

DROP PROCEDURE IF EXISTS usp_SafeUpdate;
GO

-- 💡 Key Takeaways:
-- - BEGIN TRANSACTION starts, COMMIT saves, ROLLBACK undoes
-- - Always use TRY...CATCH with transactions
-- - Check @@TRANCOUNT before ROLLBACK
-- - Use SET XACT_ABORT ON for automatic rollback on errors
-- - XACT_STATE() shows transaction state (-1, 0, 1)
-- - Savepoints allow partial rollback within transaction
-- - Keep transactions SHORT (don't do I/O or long calculations inside)
-- - SQL Server "nested transactions" aren't truly nested
-- - Any ROLLBACK rolls back entire transaction (not just inner)
-- - Only outermost COMMIT actually commits
-- - Use SCOPE_IDENTITY() to get inserted IDs within transaction
-- - Transaction holds locks until COMMIT or ROLLBACK
-- - Set reasonable LOCK_TIMEOUT to prevent indefinite blocking
-- - Do calculations before BEGIN TRANSACTION
-- - Avoid IMPLICIT_TRANSACTIONS (explicit is better)
