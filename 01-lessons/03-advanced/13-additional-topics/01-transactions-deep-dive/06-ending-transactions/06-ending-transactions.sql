/*
============================================================================
Lesson 12.06 - Ending Transactions
============================================================================

Description:
Master how to properly end transactions in SQL Server. Learn about COMMIT
TRANSACTION, ROLLBACK TRANSACTION, error handling with TRY...CATCH,
automatic rollback, transaction recovery, and best practices for ensuring
data integrity.

Topics Covered:
• COMMIT TRANSACTION
• ROLLBACK TRANSACTION
• Automatic rollback scenarios
• Error handling with TRY...CATCH
• @@ERROR and XACT_ABORT
• Transaction recovery
• Best practices for ending transactions

Prerequisites:
• Lesson 12.05 (Starting Transactions)

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: COMMIT TRANSACTION
============================================================================
*/

-- Example 1.1: COMMIT Syntax
/*
SYNTAX:
COMMIT [ TRAN | TRANSACTION ] [ transaction_name ]

Variations:
• COMMIT
• COMMIT TRANSACTION
• COMMIT TRAN
• COMMIT TRANSACTION TransactionName
*/

-- Example 1.2: Basic COMMIT
CREATE TABLE #Account (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(100),
    Balance DECIMAL(10,2)
);

INSERT INTO #Account VALUES
(1, 'Alice', 1000),
(2, 'Bob', 500);

BEGIN TRANSACTION;
    UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
    UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;
    
    -- Everything successful, make changes permanent
COMMIT TRANSACTION;

SELECT * FROM #Account;

-- Example 1.3: COMMIT Effects
/*
WHEN YOU COMMIT:

1. All changes become PERMANENT
   ┌──────────────────────────────────┐
   │ Transaction Log                  │
   │ [Changes marked as committed]    │
   └──────────────────────────────────┘

2. All locks are RELEASED
   ┌──────────────────────────────────┐
   │ Other users can now access data  │
   └──────────────────────────────────┘

3. @@TRANCOUNT decremented
   @@TRANCOUNT: 1 → 0

4. Cannot undo changes
   No going back!

5. Data visible to other transactions
   Changes now part of database state
*/

-- Example 1.4: Conditional COMMIT
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = Balance - 50 WHERE AccountID = 1;
    
    -- Check if update successful
    DECLARE @RowsAffected INT = @@ROWCOUNT;
    
    IF @RowsAffected > 0
    BEGIN
        PRINT 'Update successful, committing...';
        COMMIT TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT 'Update failed, rolling back...';
        ROLLBACK TRANSACTION;
    END

-- Example 1.5: COMMIT with Validation
BEGIN TRANSACTION;
    UPDATE #Account 
    SET Balance = Balance - 200 
    WHERE AccountID = 1;
    
    -- Verify no negative balances
    IF EXISTS (SELECT 1 FROM #Account WHERE Balance < 0)
    BEGIN
        PRINT 'ERROR: Negative balance detected!';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT 'Validation passed, committing...';
        COMMIT TRANSACTION;
    END

SELECT * FROM #Account;


/*
============================================================================
PART 2: ROLLBACK TRANSACTION
============================================================================
*/

-- Example 2.1: ROLLBACK Syntax
/*
SYNTAX:
ROLLBACK [ TRAN | TRANSACTION ] [ transaction_name | savepoint_name ]

Variations:
• ROLLBACK
• ROLLBACK TRANSACTION
• ROLLBACK TRAN
• ROLLBACK TRANSACTION TransactionName
• ROLLBACK TRANSACTION SavepointName
*/

-- Example 2.2: Basic ROLLBACK
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 999999 WHERE AccountID = 1;
    UPDATE #Account SET Balance = 999999 WHERE AccountID = 2;
    
    -- Changed our mind, undo everything
ROLLBACK TRANSACTION;

-- Check: Balances unchanged
SELECT * FROM #Account;

-- Example 2.3: ROLLBACK Effects
/*
WHEN YOU ROLLBACK:

1. All changes are UNDONE
   ┌──────────────────────────────────┐
   │ Data restored to pre-transaction │
   │ state using transaction log      │
   └──────────────────────────────────┘

2. All locks are RELEASED
   ┌──────────────────────────────────┐
   │ Other users can access data      │
   └──────────────────────────────────┘

3. @@TRANCOUNT set to 0
   @@TRANCOUNT: 1 → 0 (always!)

4. Changes discarded
   Nothing persisted to database

5. Transaction aborted
   Cannot continue transaction
*/

-- Example 2.4: ROLLBACK Demonstration
BEGIN TRANSACTION;
    PRINT 'Before updates:';
    SELECT * FROM #Account WHERE AccountID = 1;
    
    -- Make changes
    UPDATE #Account SET Balance = 5000 WHERE AccountID = 1;
    INSERT INTO #Account VALUES (3, 'Charlie', 1500);
    DELETE FROM #Account WHERE AccountID = 2;
    
    PRINT 'After updates (before rollback):';
    SELECT * FROM #Account;
    
    -- Undo everything
ROLLBACK TRANSACTION;

PRINT 'After rollback:';
SELECT * FROM #Account;  -- Original data restored!

-- Example 2.5: When to ROLLBACK
/*
ROLLBACK SCENARIOS:

1. Error detected
   IF @@ERROR <> 0
       ROLLBACK;

2. Business rule violation
   IF @TotalAmount > @CreditLimit
       ROLLBACK;

3. Validation failure
   IF NOT EXISTS (SELECT ...)
       ROLLBACK;

4. Exception caught
   CATCH
       ROLLBACK;

5. User cancellation
   IF @UserCancelled = 1
       ROLLBACK;
*/


/*
============================================================================
PART 3: Error Handling with TRY...CATCH
============================================================================
*/

-- Example 3.1: Basic TRY...CATCH Pattern
BEGIN TRY
    BEGIN TRANSACTION;
        
        UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
        UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;
        
    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully';
END TRY
BEGIN CATCH
    -- Error occurred, rollback
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Transaction rolled back due to error:';
    PRINT ERROR_MESSAGE();
END CATCH;

-- Example 3.2: Handling Constraint Violations
CREATE TABLE #Employee (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(100),
    Salary DECIMAL(10,2) CHECK (Salary > 0)
);

BEGIN TRY
    BEGIN TRANSACTION;
        
        INSERT INTO #Employee VALUES (1, 'John', 50000);
        INSERT INTO #Employee VALUES (2, 'Jane', -1000);  -- Violates CHECK
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Error Details:';
    PRINT '  Message: ' + ERROR_MESSAGE();
    PRINT '  Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT '  State: ' + CAST(ERROR_STATE() AS VARCHAR);
    PRINT '  Line: ' + CAST(ERROR_LINE() AS VARCHAR);
END CATCH;

SELECT * FROM #Employee;  -- Empty (rolled back)

-- Example 3.3: Nested TRY...CATCH
BEGIN TRY
    BEGIN TRANSACTION;
        
        UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
        
        -- Inner operation with its own error handling
        BEGIN TRY
            UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;
        END TRY
        BEGIN CATCH
            PRINT 'Inner error: ' + ERROR_MESSAGE();
            THROW;  -- Re-throw to outer catch
        END CATCH;
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Outer error handler: ' + ERROR_MESSAGE();
END CATCH;

-- Example 3.4: Error Information Functions
BEGIN TRY
    BEGIN TRANSACTION;
        
        -- Force divide by zero error
        DECLARE @Result INT = 10 / 0;
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_LINE() AS ErrorLine,
        ERROR_PROCEDURE() AS ErrorProcedure;
END CATCH;

-- Example 3.5: Re-throwing Errors
BEGIN TRY
    BEGIN TRANSACTION;
        
        UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
        
        -- Simulate error
        RAISERROR('Custom error', 16, 1);
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Transaction rolled back';
    
    -- Re-throw error to caller
    THROW;  -- Preserves original error
END CATCH;


/*
============================================================================
PART 4: Automatic Rollback Scenarios
============================================================================
*/

-- Example 4.1: Connection Termination
/*
AUTOMATIC ROLLBACK WHEN:

1. Connection closed with open transaction
   ┌──────────────────────────────────────┐
   │ BEGIN TRANSACTION                    │
   │   UPDATE ...                         │
   │ [Connection lost] ← Auto ROLLBACK   │
   └──────────────────────────────────────┘

2. Timeout expires
   ┌──────────────────────────────────────┐
   │ BEGIN TRANSACTION                    │
   │   Long-running query...              │
   │ [Timeout] ← Auto ROLLBACK           │
   └──────────────────────────────────────┘

3. Deadlock detected
   ┌──────────────────────────────────────┐
   │ BEGIN TRANSACTION                    │
   │   [Deadlock victim] ← Auto ROLLBACK │
   └──────────────────────────────────────┘

4. System crash (on recovery)
   ┌──────────────────────────────────────┐
   │ Uncommitted transactions rolled back │
   │ during database recovery             │
   └──────────────────────────────────────┘
*/

-- Example 4.2: XACT_ABORT Setting
/*
SET XACT_ABORT ON:
Automatically rollback on error
*/

SET XACT_ABORT OFF;  -- Default
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    UPDATE #Account SET InvalidColumn = 100;  -- Error!
    -- Transaction still open (@@TRANCOUNT = 1)
ROLLBACK TRANSACTION;  -- Must manually rollback

SET XACT_ABORT ON;  -- Auto-rollback on error
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    UPDATE #Account SET InvalidColumn = 100;  -- Error!
    -- Transaction automatically rolled back (@@TRANCOUNT = 0)

SET XACT_ABORT OFF;  -- Reset to default

-- Example 4.3: Demonstrating XACT_ABORT
-- Without XACT_ABORT
PRINT 'Without XACT_ABORT:';
SET XACT_ABORT OFF;

BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 200 WHERE AccountID = 1;  -- Succeeds
    PRINT '  @@TRANCOUNT after success: ' + CAST(@@TRANCOUNT AS VARCHAR);
    
    UPDATE #Account SET Balance = 'Invalid';  -- Error!
    PRINT '  @@TRANCOUNT after error: ' + CAST(@@TRANCOUNT AS VARCHAR);
    -- Still 1! Transaction not auto-rolled back
IF @@TRANCOUNT > 0
    ROLLBACK;

-- With XACT_ABORT
PRINT 'With XACT_ABORT:';
SET XACT_ABORT ON;

BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 200 WHERE AccountID = 1;  -- Succeeds
    UPDATE #Account SET Balance = 'Invalid';  -- Error! Auto-rollback
    -- Never reaches here
IF @@TRANCOUNT > 0
    ROLLBACK;

SET XACT_ABORT OFF;

-- Example 4.4: Uncommitted Transaction Warning
/*
UNCOMMITTED TRANSACTION WARNING:

SQL Server Management Studio shows warning:
"There are uncommitted transactions. Do you wish to commit?"

Example:
*/
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    -- Forgot to commit...
    -- Close window → SQL Server prompts to commit or rollback


/*
============================================================================
PART 5: Transaction States During Commit/Rollback
============================================================================
*/

-- Example 5.1: Transaction State Monitoring
SELECT 
    session_id,
    transaction_id,
    CASE transaction_state
        WHEN 0 THEN 'Initializing'
        WHEN 1 THEN 'Initialized'
        WHEN 2 THEN 'Active'
        WHEN 3 THEN 'Ended (Read-only)'
        WHEN 4 THEN 'Commit Started'
        WHEN 5 THEN 'Prepared'
        WHEN 6 THEN 'Committed'
        WHEN 7 THEN 'Rolling Back'
        WHEN 8 THEN 'Rolled Back'
    END AS TransactionState
FROM sys.dm_tran_session_transactions
WHERE session_id = @@SPID;

-- Example 5.2: Active Transactions
-- View all active transactions
SELECT 
    t.transaction_id,
    t.name AS TransactionName,
    t.transaction_begin_time,
    DATEDIFF(SECOND, t.transaction_begin_time, GETDATE()) AS DurationSeconds,
    s.session_id,
    s.login_name,
    s.program_name
FROM sys.dm_tran_active_transactions t
INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id
INNER JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
WHERE s.session_id = @@SPID;

-- Example 5.3: Monitoring Long-Running Transactions
-- Find transactions older than 1 minute
SELECT 
    t.transaction_id,
    s.session_id,
    t.transaction_begin_time,
    DATEDIFF(MINUTE, t.transaction_begin_time, GETDATE()) AS DurationMinutes,
    s.last_request_start_time,
    s.last_request_end_time,
    r.command,
    r.status,
    t.transaction_state
FROM sys.dm_tran_active_transactions t
INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id
INNER JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE DATEDIFF(MINUTE, t.transaction_begin_time, GETDATE()) > 1
ORDER BY DurationMinutes DESC;


/*
============================================================================
PART 6: Best Practices for Ending Transactions
============================================================================
*/

-- Example 6.1: Always Use TRY...CATCH
-- GOOD PATTERN
CREATE PROCEDURE TransferMoney
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Debit from account
            UPDATE #Account 
            SET Balance = Balance - @Amount 
            WHERE AccountID = @FromAccount;
            
            -- Credit to account
            UPDATE #Account 
            SET Balance = Balance + @Amount 
            WHERE AccountID = @ToAccount;
            
            -- Validate
            IF EXISTS (SELECT 1 FROM #Account WHERE Balance < 0)
                RAISERROR('Insufficient funds', 16, 1);
            
        COMMIT TRANSACTION;
        PRINT 'Transfer successful';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Transfer failed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;

-- Example 6.2: Check @@TRANCOUNT Before Rollback
-- SAFE PATTERN
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- Always check before rollback
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT ERROR_MESSAGE();
END CATCH;

-- Example 6.3: Keep Transactions Short
-- BAD: Long transaction holding locks
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    
    -- Long computation (holds locks!)
    WAITFOR DELAY '00:01:00';
    
    UPDATE #Account SET Balance = 200 WHERE AccountID = 2;
COMMIT TRANSACTION;

-- GOOD: Short transaction
-- Do work outside transaction
DECLARE @NewBalance DECIMAL(10,2);
-- Computation here
WAITFOR DELAY '00:01:00';
SET @NewBalance = 200;

-- Quick transaction
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    UPDATE #Account SET Balance = @NewBalance WHERE AccountID = 2;
COMMIT TRANSACTION;

-- Example 6.4: Explicit is Better Than Implicit
-- BAD: Unclear
UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
-- Is this in a transaction? Who knows!

-- GOOD: Clear
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
COMMIT TRANSACTION;
-- Obviously in transaction, explicitly committed

-- Example 6.5: Log Transaction Outcomes
CREATE TABLE #TransactionLog (
    LogID INT IDENTITY PRIMARY KEY,
    TransactionName VARCHAR(100),
    StartTime DATETIME,
    EndTime DATETIME,
    Outcome VARCHAR(20),
    ErrorMessage VARCHAR(MAX)
);

CREATE PROCEDURE LoggedTransaction
    @TransactionName VARCHAR(100)
AS
BEGIN
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @LogID INT;
    
    -- Log start
    INSERT INTO #TransactionLog (TransactionName, StartTime, Outcome)
    VALUES (@TransactionName, @StartTime, 'PENDING');
    SET @LogID = SCOPE_IDENTITY();
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Business logic here
            UPDATE #Account SET Balance = Balance + 10;
            
        COMMIT TRANSACTION;
        
        -- Log success
        UPDATE #TransactionLog
        SET EndTime = GETDATE(),
            Outcome = 'COMMITTED'
        WHERE LogID = @LogID;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log failure
        UPDATE #TransactionLog
        SET EndTime = GETDATE(),
            Outcome = 'ROLLED BACK',
            ErrorMessage = ERROR_MESSAGE()
        WHERE LogID = @LogID;
        
        THROW;
    END CATCH;
END;


/*
============================================================================
PART 7: Common Mistakes and Solutions
============================================================================
*/

-- Example 7.1: Forgetting to Commit
-- MISTAKE
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    -- Forgot COMMIT!
    -- Locks held indefinitely!

-- Close connection → Auto-rollback (data lost!)

-- SOLUTION: Always commit or rollback
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
COMMIT TRANSACTION;  -- Don't forget!

-- Example 7.2: Committing After Error
-- MISTAKE
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    UPDATE #Account SET Balance = 'Invalid';  -- Error!
    COMMIT TRANSACTION;  -- Should not commit after error!

-- SOLUTION: Use TRY...CATCH
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
        UPDATE #Account SET Balance = 'Invalid';  -- Error!
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;  -- Proper rollback
END CATCH;

-- Example 7.3: Rolling Back Without Checking @@TRANCOUNT
-- MISTAKE
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
COMMIT TRANSACTION;

ROLLBACK TRANSACTION;  -- Error! No active transaction

-- SOLUTION: Always check
IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

-- Example 7.4: Not Handling Nested Transaction Rollback
-- MISTAKE
BEGIN TRANSACTION;  -- Outer
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    
    BEGIN TRANSACTION;  -- Inner
        UPDATE #Account SET Balance = 200 WHERE AccountID = 2;
        ROLLBACK TRANSACTION;  -- Rolls back EVERYTHING!
    
    COMMIT TRANSACTION;  -- ERROR! No active transaction

-- SOLUTION: Use savepoints
BEGIN TRANSACTION;  -- Outer
    UPDATE #Account SET Balance = 100 WHERE AccountID = 1;
    
    SAVE TRANSACTION InnerSavepoint;
        UPDATE #Account SET Balance = 200 WHERE AccountID = 2;
    ROLLBACK TRANSACTION InnerSavepoint;  -- Only inner work
    
COMMIT TRANSACTION;  -- Outer commit succeeds

-- Cleanup
DROP TABLE #Account;
DROP TABLE #Employee;
DROP TABLE #TransactionLog;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Write a transaction with proper error handling
2. Demonstrate the difference between COMMIT and ROLLBACK
3. Show automatic rollback scenarios
4. Create a procedure with complete transaction management
5. Implement transaction logging for audit purposes

Solutions below ↓
*/

-- Solution 1: Transaction with Proper Error Handling
CREATE TABLE #Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2)
);

CREATE TABLE #Inventory (
    ProductID INT PRIMARY KEY,
    Quantity INT CHECK (Quantity >= 0)
);

INSERT INTO #Inventory VALUES (1, 100);

CREATE PROCEDURE ProcessOrderWithErrorHandling
    @OrderID INT,
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @UnitPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables for error handling
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    BEGIN TRY
        -- Start transaction
        BEGIN TRANSACTION;
            
            -- Create order
            INSERT INTO #Orders (OrderID, CustomerID, OrderDate, TotalAmount)
            VALUES (@OrderID, @CustomerID, GETDATE(), @Quantity * @UnitPrice);
            
            -- Update inventory
            UPDATE #Inventory
            SET Quantity = Quantity - @Quantity
            WHERE ProductID = @ProductID;
            
            -- Verify inventory didn't go negative
            IF EXISTS (SELECT 1 FROM #Inventory WHERE ProductID = @ProductID AND Quantity < 0)
            BEGIN
                RAISERROR('Insufficient inventory', 16, 1);
            END
            
            -- Verify order created
            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR('Product not found', 16, 1);
            END
            
        -- All validations passed, commit
        COMMIT TRANSACTION;
        
        PRINT 'Order processed successfully';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Error occurred, rollback if transaction active
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Transaction rolled back';
        END
        
        -- Capture error details
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        -- Log error (in production, log to table)
        PRINT 'ERROR: ' + @ErrorMessage;
        
        -- Re-throw error to caller
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        
        RETURN -1;
    END CATCH;
END;

-- Test successful order
EXEC ProcessOrderWithErrorHandling 
    @OrderID = 1,
    @CustomerID = 101,
    @ProductID = 1,
    @Quantity = 10,
    @UnitPrice = 25.00;

-- Test insufficient inventory
EXEC ProcessOrderWithErrorHandling 
    @OrderID = 2,
    @CustomerID = 102,
    @ProductID = 1,
    @Quantity = 1000,  -- More than available!
    @UnitPrice = 25.00;

-- Solution 2: COMMIT vs ROLLBACK Demonstration
PRINT '=== COMMIT Example ===';
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (100, 1, GETDATE(), 500);
    PRINT 'Before COMMIT: Order exists in transaction';
    SELECT * FROM #Orders WHERE OrderID = 100;
COMMIT TRANSACTION;

PRINT 'After COMMIT: Order permanently saved';
SELECT * FROM #Orders WHERE OrderID = 100;

PRINT '';
PRINT '=== ROLLBACK Example ===';
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (200, 2, GETDATE(), 1000);
    PRINT 'Before ROLLBACK: Order exists in transaction';
    SELECT * FROM #Orders WHERE OrderID = 200;
ROLLBACK TRANSACTION;

PRINT 'After ROLLBACK: Order removed';
SELECT * FROM #Orders WHERE OrderID = 200;  -- Empty result

-- Solution 3: Automatic Rollback Scenarios
PRINT '=== Scenario 1: Connection Termination ===';
/*
BEGIN TRANSACTION;
    UPDATE #Orders SET TotalAmount = 999;
-- If connection closed here → Automatic ROLLBACK
-- On reconnect, changes are gone
*/

PRINT '=== Scenario 2: XACT_ABORT ===';
SET XACT_ABORT ON;
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (300, 3, GETDATE(), 100);
    -- This error will cause automatic rollback
    INSERT INTO #Orders VALUES (300, 3, GETDATE(), 100);  -- Duplicate key!
    -- Transaction automatically rolled back
    -- @@TRANCOUNT = 0
SET XACT_ABORT OFF;

PRINT '=== Scenario 3: Deadlock Victim ===';
/*
Session 1:
BEGIN TRANSACTION;
    UPDATE #Orders SET TotalAmount = 100 WHERE OrderID = 1;
    -- Wait...
    UPDATE #Inventory SET Quantity = 50 WHERE ProductID = 1;
COMMIT;

Session 2:
BEGIN TRANSACTION;
    UPDATE #Inventory SET Quantity = 50 WHERE ProductID = 1;
    -- Wait...
    UPDATE #Orders SET TotalAmount = 100 WHERE OrderID = 1;
COMMIT;

Result: One session chosen as deadlock victim → Automatic ROLLBACK
*/

PRINT '=== Scenario 4: System Crash ===';
/*
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (400, 4, GETDATE(), 500);
    -- System crashes before COMMIT
    
On restart:
    -- SQL Server performs automatic crash recovery
    -- Uncommitted transaction rolled back
    -- Order 400 does not exist
*/

-- Solution 4: Complete Transaction Management Procedure
CREATE PROCEDURE CompleteTransactionExample
    @Operation VARCHAR(20),
    @OrderID INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Transaction control variables
    DECLARE @TranStarted BIT = 0;
    DECLARE @SavepointName VARCHAR(50) = 'SavePoint_' + CAST(@OrderID AS VARCHAR);
    
    -- Error handling variables
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @ErrorLine INT;
    
    BEGIN TRY
        -- Check if we need to start a transaction
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TranStarted = 1;
            PRINT 'Transaction started by procedure';
        END
        ELSE
        BEGIN
            -- Already in transaction, create savepoint
            SAVE TRANSACTION @SavepointName;
            PRINT 'Savepoint created: ' + @SavepointName;
        END
        
        -- Perform operation
        IF @Operation = 'INSERT'
        BEGIN
            INSERT INTO #Orders (OrderID, CustomerID, OrderDate, TotalAmount)
            VALUES (@OrderID, 1, GETDATE(), @Amount);
            PRINT 'Order inserted: ' + CAST(@OrderID AS VARCHAR);
        END
        ELSE IF @Operation = 'UPDATE'
        BEGIN
            UPDATE #Orders 
            SET TotalAmount = @Amount 
            WHERE OrderID = @OrderID;
            
            IF @@ROWCOUNT = 0
                RAISERROR('Order not found', 16, 1);
                
            PRINT 'Order updated: ' + CAST(@OrderID AS VARCHAR);
        END
        ELSE IF @Operation = 'DELETE'
        BEGIN
            DELETE FROM #Orders WHERE OrderID = @OrderID;
            PRINT 'Order deleted: ' + CAST(@OrderID AS VARCHAR);
        END
        ELSE
        BEGIN
            RAISERROR('Invalid operation', 16, 1);
        END
        
        -- Commit only if we started the transaction
        IF @TranStarted = 1
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'Transaction committed by procedure';
        END
        ELSE
        BEGIN
            PRINT 'Work completed within caller''s transaction';
        END
        
        RETURN 0;  -- Success
        
    END TRY
    BEGIN CATCH
        -- Capture error information
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
            @ErrorLine = ERROR_LINE();
        
        -- Rollback appropriately
        IF @TranStarted = 1
        BEGIN
            -- We started the transaction, roll it all back
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
                PRINT 'Transaction rolled back by procedure';
            END
        END
        ELSE
        BEGIN
            -- We didn't start it, rollback to savepoint
            IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRANSACTION @SavepointName;
                PRINT 'Rolled back to savepoint: ' + @SavepointName;
            END
        END
        
        -- Log error details
        PRINT 'ERROR at line ' + CAST(@ErrorLine AS VARCHAR) + ': ' + @ErrorMessage;
        
        -- Re-throw error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        
        RETURN -1;  -- Failure
    END CATCH;
END;

-- Test the procedure
EXEC CompleteTransactionExample 'INSERT', 500, 750.00;
EXEC CompleteTransactionExample 'UPDATE', 500, 800.00;
EXEC CompleteTransactionExample 'DELETE', 500, 0;

-- Solution 5: Transaction Logging for Audit
CREATE TABLE #TransactionAudit (
    AuditID INT IDENTITY PRIMARY KEY,
    TransactionName VARCHAR(100),
    StartTime DATETIME2,
    EndTime DATETIME2,
    DurationMS INT,
    RowsAffected INT,
    Status VARCHAR(20),
    ErrorMessage NVARCHAR(MAX),
    UserName VARCHAR(100),
    ApplicationName VARCHAR(100)
);

CREATE PROCEDURE AuditedTransaction
    @TransactionName VARCHAR(100),
    @Operation VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AuditID INT;
    DECLARE @StartTime DATETIME2 = SYSUTCDATETIME();
    DECLARE @RowsAffected INT;
    
    -- Log transaction start
    INSERT INTO #TransactionAudit (
        TransactionName, 
        StartTime, 
        Status, 
        UserName, 
        ApplicationName
    )
    VALUES (
        @TransactionName,
        @StartTime,
        'STARTED',
        SYSTEM_USER,
        APP_NAME()
    );
    
    SET @AuditID = SCOPE_IDENTITY();
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Execute the operation
            EXEC sp_executesql @Operation;
            SET @RowsAffected = @@ROWCOUNT;
            
        COMMIT TRANSACTION;
        
        -- Log successful commit
        UPDATE #TransactionAudit
        SET EndTime = SYSUTCDATETIME(),
            DurationMS = DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()),
            RowsAffected = @RowsAffected,
            Status = 'COMMITTED'
        WHERE AuditID = @AuditID;
        
        PRINT 'Transaction committed and logged';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log rollback
        UPDATE #TransactionAudit
        SET EndTime = SYSUTCDATETIME(),
            DurationMS = DATEDIFF(MILLISECOND, @StartTime, SYSUTCDATETIME()),
            Status = 'ROLLED BACK',
            ErrorMessage = ERROR_MESSAGE()
        WHERE AuditID = @AuditID;
        
        PRINT 'Transaction rolled back and logged';
        THROW;
    END CATCH;
END;

-- Test audited transactions
EXEC AuditedTransaction 
    'Update Order Amount',
    N'UPDATE #Orders SET TotalAmount = 1000 WHERE OrderID = 1';

EXEC AuditedTransaction 
    'Invalid Update',
    N'UPDATE #Orders SET InvalidColumn = 1';  -- Will fail

-- View audit log
SELECT 
    AuditID,
    TransactionName,
    StartTime,
    EndTime,
    DurationMS,
    RowsAffected,
    Status,
    ErrorMessage,
    UserName
FROM #TransactionAudit
ORDER BY StartTime DESC;

-- Cleanup
DROP TABLE #Orders;
DROP TABLE #Inventory;
DROP TABLE #TransactionAudit;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ COMMIT TRANSACTION:
  • Makes changes permanent
  • Releases all locks
  • Decrements @@TRANCOUNT
  • Cannot undo after commit
  • Syntax: COMMIT [TRANSACTION] [name]

✓ ROLLBACK TRANSACTION:
  • Undoes all changes
  • Releases all locks
  • Sets @@TRANCOUNT to 0
  • Restores pre-transaction state
  • Syntax: ROLLBACK [TRANSACTION] [name]

✓ ERROR HANDLING:
  • Always use TRY...CATCH
  • Check @@TRANCOUNT before rollback
  • Capture error details
  • Re-throw when appropriate
  • Log errors for debugging

✓ AUTOMATIC ROLLBACK:
  • Connection termination
  • Timeout expiration
  • Deadlock victim
  • System crash (on recovery)
  • SET XACT_ABORT ON

✓ XACT_ABORT:
  • ON: Auto-rollback on error
  • OFF: Manual rollback required (default)
  • Recommended: ON for simplicity
  • Critical for error safety

✓ TRANSACTION STATES:
  • Monitor with sys.dm_tran_*
  • Track long-running transactions
  • Identify blocking issues
  • Audit transaction outcomes

✓ BEST PRACTICES:
  • Always use TRY...CATCH
  • Check @@TRANCOUNT before rollback
  • Keep transactions short
  • Be explicit with COMMIT
  • Log transaction outcomes
  • Handle nested transactions carefully
  • Use savepoints for partial rollback
  • Test error scenarios

✓ COMMON MISTAKES:
  • Forgetting to commit
  • Committing after error
  • Not checking @@TRANCOUNT
  • Long-running transactions
  • Improper nested transaction handling

✓ MONITORING:
  • sys.dm_tran_active_transactions
  • sys.dm_tran_session_transactions
  • Transaction audit logging
  • Performance metrics
  • Error tracking

============================================================================
NEXT: Lesson 12.07 - Transaction Savepoints
Learn how to use savepoints for partial transaction rollback.
============================================================================
*/
