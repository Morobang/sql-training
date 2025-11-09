/*
============================================================================
Lesson 12.08 - Test Your Knowledge
============================================================================

Chapter: 12 - Transactions
Total Points: 400
Time Limit: 90 minutes
Passing Score: 70% (280 points)

Instructions:
• Read each question carefully
• Write your answers in the designated solution areas
• Test your code to verify correctness
• All questions use the RetailStore database
• Some questions build on previous answers

Topics Covered:
• Multi-user database concepts
• Locking mechanisms
• Lock granularities
• ACID properties
• Transaction lifecycle
• Starting and ending transactions
• Savepoints
• Error handling
• Real-world scenarios

Good luck!
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
SECTION 1: Multiple Choice Questions (100 points, 10 points each)
============================================================================
*/

-- Question 1 (10 points)
-- What does the "A" in ACID stand for?
/*
A) Accuracy
B) Atomicity
C) Authorization
D) Availability

YOUR ANSWER: 
*/


-- Question 2 (10 points)
-- Which isolation level provides the highest data integrity but lowest concurrency?
/*
A) READ UNCOMMITTED
B) READ COMMITTED
C) REPEATABLE READ
D) SERIALIZABLE

YOUR ANSWER: 
*/


-- Question 3 (10 points)
-- What happens when you execute ROLLBACK in a nested transaction?
/*
A) Only the innermost transaction is rolled back
B) The entire transaction is rolled back
C) An error occurs
D) Nothing happens

YOUR ANSWER: 
*/


-- Question 4 (10 points)
-- Which lock type allows multiple readers but no writers?
/*
A) Exclusive (X)
B) Shared (S)
C) Update (U)
D) Intent (I)

YOUR ANSWER: 
*/


-- Question 5 (10 points)
-- What is the default transaction mode in SQL Server?
/*
A) Explicit transactions
B) Implicit transactions
C) Auto-commit transactions
D) Distributed transactions

YOUR ANSWER: 
*/


-- Question 6 (10 points)
-- When does lock escalation typically occur?
/*
A) When a single row is locked
B) When approximately 5,000 locks are acquired on a single table
C) When a transaction commits
D) When using READ UNCOMMITTED isolation level

YOUR ANSWER: 
*/


-- Question 7 (10 points)
-- Which statement about savepoints is TRUE?
/*
A) Savepoints increment @@TRANCOUNT
B) Rolling back to a savepoint commits the transaction
C) Savepoints allow partial rollback within a transaction
D) Savepoints can be used outside of transactions

YOUR ANSWER: 
*/


-- Question 8 (10 points)
-- What does @@TRANCOUNT return when no transaction is active?
/*
A) NULL
B) 0
C) 1
D) -1

YOUR ANSWER: 
*/


-- Question 9 (10 points)
-- Which ACID property ensures that committed transactions survive system crashes?
/*
A) Atomicity
B) Consistency
C) Isolation
D) Durability

YOUR ANSWER: 
*/


-- Question 10 (10 points)
-- What is the finest level of lock granularity in SQL Server?
/*
A) Database
B) Table
C) Page
D) Row

YOUR ANSWER: 
*/


/*
============================================================================
SECTION 2: True/False Questions (50 points, 5 points each)
============================================================================
*/

-- Question 11 (5 points)
-- A transaction can have multiple savepoints with the same name. (T/F)
-- YOUR ANSWER: 


-- Question 12 (5 points)
-- The NOLOCK hint completely eliminates the possibility of dirty reads. (T/F)
-- YOUR ANSWER: 


-- Question 13 (5 points)
-- COMMIT TRANSACTION decrements @@TRANCOUNT by 1. (T/F)
-- YOUR ANSWER: 


-- Question 14 (5 points)
-- Page-level locks lock all rows on an 8 KB page. (T/F)
-- YOUR ANSWER: 


-- Question 15 (5 points)
-- Implicit transactions automatically commit after each statement. (T/F)
-- YOUR ANSWER: 


-- Question 16 (5 points)
-- The transaction log is written BEFORE data pages (write-ahead logging). (T/F)
-- YOUR ANSWER: 


-- Question 17 (5 points)
-- A deadlock occurs when two transactions wait for each other's locks. (T/F)
-- YOUR ANSWER: 


-- Question 18 (5 points)
-- XACT_ABORT ON causes automatic rollback on any error. (T/F)
-- YOUR ANSWER: 


-- Question 19 (5 points)
-- Consistency ensures that only valid data is written to the database. (T/F)
-- YOUR ANSWER: 


-- Question 20 (5 points)
-- Lock escalation can be disabled at the table level. (T/F)
-- YOUR ANSWER: 


/*
============================================================================
SECTION 3: Short Answer Questions (100 points, 20 points each)
============================================================================
*/

-- Question 21 (20 points)
-- Explain the four ACID properties with a brief example for each.
/*
YOUR ANSWER:







*/


-- Question 22 (20 points)
-- Describe the difference between shared (S) and exclusive (X) locks.
-- When is each type used?
/*
YOUR ANSWER:






*/


-- Question 23 (20 points)
-- What is the difference between COMMIT and ROLLBACK? When would you use each?
/*
YOUR ANSWER:






*/


-- Question 24 (20 points)
-- Explain what savepoints are and provide a scenario where they are useful.
/*
YOUR ANSWER:






*/


-- Question 25 (20 points)
-- Describe the three transaction modes (auto-commit, explicit, implicit)
-- and when you would use each.
/*
YOUR ANSWER:







*/


/*
============================================================================
SECTION 4: Coding Questions (150 points)
============================================================================
*/

-- Setup for coding questions
CREATE TABLE #Account (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(100),
    Balance DECIMAL(10,2) CHECK (Balance >= 0),
    LastModified DATETIME DEFAULT GETDATE()
);

CREATE TABLE #TransactionLog (
    LogID INT IDENTITY PRIMARY KEY,
    AccountID INT,
    TransactionType VARCHAR(20),
    Amount DECIMAL(10,2),
    TransactionDate DATETIME DEFAULT GETDATE()
);

INSERT INTO #Account (AccountID, AccountHolder, Balance) VALUES
(1, 'Alice', 1000),
(2, 'Bob', 500),
(3, 'Charlie', 1500);


-- Question 26 (30 points)
-- Write a transaction that transfers $200 from Alice (AccountID = 1) to 
-- Bob (AccountID = 2). Include proper error handling with TRY...CATCH.
-- The transaction should rollback if Alice has insufficient funds.

-- YOUR SOLUTION:




-- Question 27 (30 points)
-- Create a stored procedure named UpdateAccountBalance that:
-- • Takes @AccountID and @Amount as parameters
-- • Uses a savepoint named BalanceUpdate
-- • Updates the account balance
-- • Rolls back to savepoint if balance would go negative
-- • Logs the transaction in #TransactionLog
-- • Returns 0 for success, -1 for failure

-- YOUR SOLUTION:




-- Question 28 (30 points)
-- Write a transaction that demonstrates all four ACID properties:
-- • Atomicity: Multiple updates that succeed or fail together
-- • Consistency: Enforce the CHECK constraint (Balance >= 0)
-- • Isolation: Use appropriate isolation level
-- • Durability: Properly commit the transaction
-- Include comments explaining each property.

-- YOUR SOLUTION:




-- Question 29 (30 points)
-- Create a procedure that processes a batch of account updates.
-- The procedure should:
-- • Start a transaction
-- • Process 3 account updates
-- • Use savepoints for each update
-- • If an update fails, rollback only that update and continue
-- • Log all attempts (success and failure) to #TransactionLog
-- • Commit at the end

-- YOUR SOLUTION:




-- Question 30 (30 points)
-- Write code that demonstrates the difference between:
-- a) Nested transactions (BEGIN TRAN inside BEGIN TRAN)
-- b) Savepoints (SAVE TRANSACTION)
-- Show what happens when you ROLLBACK in each case.
-- Use #Account table for your demonstration.

-- YOUR SOLUTION:




/*
============================================================================
SECTION 5: Scenario-Based Questions (Bonus: 50 points)
============================================================================
*/

-- Question 31 (25 points)
-- SCENARIO: An e-commerce application is experiencing deadlocks between
-- order processing and inventory updates. 
-- 
-- Write SQL code that demonstrates:
-- a) How the deadlock might occur (simulate two sessions)
-- b) How to prevent it using proper locking hints or transaction ordering
-- c) How to detect deadlocks using sys.dm_tran_locks

-- YOUR SOLUTION:




-- Question 32 (25 points)
-- SCENARIO: You need to import 10,000 records from a staging table.
-- If any record fails validation, that record should be skipped but 
-- the import should continue. All valid records should be committed together.
--
-- Create a solution using savepoints that:
-- • Processes records one by one
-- • Validates each record (Balance must be > 0)
-- • Uses savepoints to skip invalid records
-- • Provides a summary of successes and failures

-- YOUR SOLUTION:




/*
============================================================================
ANSWER KEY
============================================================================

SECTION 1: Multiple Choice
1. B (Atomicity)
2. D (SERIALIZABLE)
3. B (The entire transaction is rolled back)
4. B (Shared - S)
5. C (Auto-commit transactions)
6. B (When approximately 5,000 locks are acquired)
7. C (Savepoints allow partial rollback)
8. B (0)
9. D (Durability)
10. D (Row)

SECTION 2: True/False
11. True (but latest one replaces previous)
12. False (NOLOCK can still have dirty reads)
13. True (decrements by 1)
14. True (all rows on page are locked)
15. False (implicit transactions require manual commit)
16. True (write-ahead logging)
17. True (mutual waiting creates deadlock)
18. True (auto-rollback on error)
19. True (validates constraints and rules)
20. True (ALTER TABLE SET LOCK_ESCALATION)

SECTION 3: Short Answer
See detailed solutions below

SECTION 4: Coding Questions
See detailed solutions below

SECTION 5: Bonus
See detailed solutions below

============================================================================
*/


/*
============================================================================
DETAILED SOLUTIONS
============================================================================
*/

-- SECTION 3 SOLUTIONS

-- Question 21 Solution
/*
ACID PROPERTIES:

A - ATOMICITY: "All or nothing"
Example: Money transfer either completes fully (debit AND credit) or not at all.
If debit succeeds but credit fails, debit is rolled back.

C - CONSISTENCY: Valid state to valid state
Example: Database enforces Balance >= 0 constraint. Transaction cannot violate
this rule. If attempted, transaction is rolled back.

I - ISOLATION: Transactions don't interfere
Example: User A updating Account 1 doesn't see User B's uncommitted changes
to the same account. Each transaction operates as if alone.

D - DURABILITY: Committed changes persist
Example: Once transfer commits, changes survive system crash. Transaction log
ensures recovery even if power fails immediately after commit.
*/

-- Question 22 Solution
/*
SHARED (S) LOCKS:
• Allows multiple readers
• Prevents writers
• Used for SELECT statements
• Compatible with other shared locks
• Released when data is read (unless higher isolation level)

Example: SELECT * FROM Account WHERE AccountID = 1
→ Acquires shared lock on row

EXCLUSIVE (X) LOCKS:
• Allows only one transaction
• Prevents all other access (read and write)
• Used for INSERT, UPDATE, DELETE
• Not compatible with any other locks
• Released when transaction ends

Example: UPDATE Account SET Balance = 500 WHERE AccountID = 1
→ Acquires exclusive lock on row

DIFFERENCE:
Shared: Many readers, no writers (read-only)
Exclusive: One writer, no readers or writers (modification)
*/

-- Question 23 Solution
/*
COMMIT:
• Makes all changes permanent
• Releases all locks
• Changes visible to other transactions
• Cannot be undone

Use when: All operations successful, data is valid

Example:
BEGIN TRANSACTION;
    UPDATE Account SET Balance = 500;
    -- All good
COMMIT TRANSACTION; ← Makes change permanent

ROLLBACK:
• Undoes all changes
• Restores pre-transaction state
• Releases all locks
• Nothing persisted

Use when: Error occurred, validation failed, user cancelled

Example:
BEGIN TRANSACTION;
    UPDATE Account SET Balance = -100;
    IF @@ERROR <> 0
        ROLLBACK TRANSACTION; ← Undo invalid change
*/

-- Question 24 Solution
/*
SAVEPOINTS:
Markers within a transaction that allow partial rollback.

SAVE TRANSACTION savepoint_name
ROLLBACK TRANSACTION savepoint_name

SCENARIO: Order Processing
You're processing an order with multiple items. If one item is out of stock,
you want to:
• Keep the order header
• Skip the out-of-stock item
• Continue with other items

BEGIN TRANSACTION;
    INSERT INTO Orders... ← Create order
    SAVE TRANSACTION AfterOrder; ← Savepoint
    
    TRY:
        INSERT INTO OrderDetails... ← Add item 1
    CATCH:
        ROLLBACK TRANSACTION AfterOrder; ← Only undo item 1
    
    INSERT INTO OrderDetails... ← Add item 2 (continues)
COMMIT; ← Commit order with item 2 only

Without savepoints, entire order would rollback!
*/

-- Question 25 Solution
/*
TRANSACTION MODES:

1. AUTO-COMMIT (default):
   • Each statement is its own transaction
   • Automatic BEGIN/COMMIT
   • No rollback capability
   
   Use: Simple, independent statements
   Example: SELECT * FROM Account;

2. EXPLICIT:
   • Manual BEGIN TRANSACTION
   • Manual COMMIT or ROLLBACK
   • Full control over scope
   
   Use: Complex operations, need atomicity
   Example:
   BEGIN TRANSACTION;
       UPDATE Account...
       UPDATE TransactionLog...
   COMMIT;

3. IMPLICIT:
   • SET IMPLICIT_TRANSACTIONS ON
   • Auto-starts transaction
   • Manual COMMIT required
   
   Use: Rarely (compatibility with other databases)
   Example:
   SET IMPLICIT_TRANSACTIONS ON;
   UPDATE Account... ← Auto-starts transaction
   COMMIT; ← Must commit manually

RECOMMENDATION: Use explicit for complex operations, auto-commit for simple.
*/


-- SECTION 4 SOLUTIONS

-- Question 26 Solution
BEGIN TRY
    BEGIN TRANSACTION;
        
        -- Debit from Alice
        UPDATE #Account 
        SET Balance = Balance - 200,
            LastModified = GETDATE()
        WHERE AccountID = 1;
        
        -- Check if debit caused negative balance
        IF EXISTS (SELECT 1 FROM #Account WHERE AccountID = 1 AND Balance < 0)
        BEGIN
            RAISERROR('Insufficient funds in source account', 16, 1);
        END
        
        -- Credit to Bob
        UPDATE #Account 
        SET Balance = Balance + 200,
            LastModified = GETDATE()
        WHERE AccountID = 2;
        
        -- Log both transactions
        INSERT INTO #TransactionLog (AccountID, TransactionType, Amount)
        VALUES (1, 'Debit', 200);
        
        INSERT INTO #TransactionLog (AccountID, TransactionType, Amount)
        VALUES (2, 'Credit', 200);
        
    COMMIT TRANSACTION;
    PRINT 'Transfer completed successfully';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Transfer failed: ' + ERROR_MESSAGE();
END CATCH;

-- Verify
SELECT * FROM #Account WHERE AccountID IN (1, 2);


-- Question 27 Solution
CREATE PROCEDURE UpdateAccountBalance
    @AccountID INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Must be in transaction
        IF @@TRANCOUNT = 0
            RAISERROR('Must be called within a transaction', 16, 1);
        
        -- Create savepoint
        SAVE TRANSACTION BalanceUpdate;
        
        -- Update balance
        UPDATE #Account
        SET Balance = Balance + @Amount,
            LastModified = GETDATE()
        WHERE AccountID = @AccountID;
        
        -- Check if balance went negative
        IF EXISTS (SELECT 1 FROM #Account WHERE AccountID = @AccountID AND Balance < 0)
        BEGIN
            -- Rollback to savepoint
            ROLLBACK TRANSACTION BalanceUpdate;
            
            -- Log failed attempt
            INSERT INTO #TransactionLog (AccountID, TransactionType, Amount)
            VALUES (@AccountID, 'Failed', @Amount);
            
            PRINT 'Update failed: Balance cannot be negative';
            RETURN -1;
        END
        
        -- Log successful update
        INSERT INTO #TransactionLog (AccountID, TransactionType, Amount)
        VALUES (@AccountID, 
                CASE WHEN @Amount > 0 THEN 'Credit' ELSE 'Debit' END, 
                ABS(@Amount));
        
        PRINT 'Balance updated successfully';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Rollback to savepoint on error
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION BalanceUpdate;
        
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH;
END;

-- Test
BEGIN TRANSACTION;
    EXEC UpdateAccountBalance 1, -500;  -- Success
    EXEC UpdateAccountBalance 1, -600;  -- Fails (insufficient funds)
    EXEC UpdateAccountBalance 2, 100;   -- Success
COMMIT;


-- Question 28 Solution
BEGIN TRY
    BEGIN TRANSACTION;
        
        -- ========================================
        -- ATOMICITY: All updates succeed or all fail
        -- ========================================
        PRINT 'Demonstrating ATOMICITY:';
        
        UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
        UPDATE #Account SET Balance = Balance - 50 WHERE AccountID = 2;
        UPDATE #Account SET Balance = Balance + 150 WHERE AccountID = 3;
        
        -- If any update fails, ALL are rolled back (atomic unit)
        PRINT 'All updates executed atomically';
        
        -- ========================================
        -- CONSISTENCY: Enforce constraints
        -- ========================================
        PRINT 'Demonstrating CONSISTENCY:';
        
        -- This CHECK constraint enforces consistency: Balance >= 0
        -- Transaction will fail if we try to violate it
        IF EXISTS (SELECT 1 FROM #Account WHERE Balance < 0)
        BEGIN
            RAISERROR('Consistency violation: Negative balance detected', 16, 1);
        END
        
        PRINT 'Consistency validated: All balances >= 0';
        
        -- ========================================
        -- ISOLATION: Set appropriate isolation level
        -- ========================================
        PRINT 'Demonstrating ISOLATION:';
        
        -- Using READ COMMITTED (default) ensures:
        -- • No dirty reads (only see committed data)
        -- • Other transactions can't see our changes until COMMIT
        
        -- This transaction is isolated from other concurrent transactions
        PRINT 'Transaction isolated at READ COMMITTED level';
        
        -- ========================================
        -- DURABILITY: Commit makes changes permanent
        -- ========================================
        PRINT 'Demonstrating DURABILITY:';
        
    COMMIT TRANSACTION;
    -- After COMMIT, changes are written to transaction log
    -- Changes will survive system crash/restart
    
    PRINT 'Transaction committed - changes are DURABLE';
    PRINT 'All ACID properties demonstrated successfully';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Transaction failed: ' + ERROR_MESSAGE();
    PRINT 'ATOMICITY ensured: All changes rolled back';
END CATCH;


-- Question 29 Solution
CREATE PROCEDURE ProcessAccountBatch
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailCount INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Update 1: Alice -$50
            SAVE TRANSACTION Update1;
            BEGIN TRY
                UPDATE #Account SET Balance = Balance - 50 WHERE AccountID = 1;
                INSERT INTO #TransactionLog VALUES (1, 'Debit', 50, GETDATE());
                SET @SuccessCount = @SuccessCount + 1;
                PRINT 'Update 1: Success';
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION Update1;
                INSERT INTO #TransactionLog VALUES (1, 'Failed', 50, GETDATE());
                SET @FailCount = @FailCount + 1;
                PRINT 'Update 1: Failed - ' + ERROR_MESSAGE();
            END CATCH;
            
            -- Update 2: Bob -$1000 (will fail - insufficient funds)
            SAVE TRANSACTION Update2;
            BEGIN TRY
                UPDATE #Account SET Balance = Balance - 1000 WHERE AccountID = 2;
                
                IF EXISTS (SELECT 1 FROM #Account WHERE AccountID = 2 AND Balance < 0)
                    RAISERROR('Insufficient funds', 16, 1);
                
                INSERT INTO #TransactionLog VALUES (2, 'Debit', 1000, GETDATE());
                SET @SuccessCount = @SuccessCount + 1;
                PRINT 'Update 2: Success';
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION Update2;
                INSERT INTO #TransactionLog VALUES (2, 'Failed', 1000, GETDATE());
                SET @FailCount = @FailCount + 1;
                PRINT 'Update 2: Failed - ' + ERROR_MESSAGE();
            END CATCH;
            
            -- Update 3: Charlie +$100
            SAVE TRANSACTION Update3;
            BEGIN TRY
                UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 3;
                INSERT INTO #TransactionLog VALUES (3, 'Credit', 100, GETDATE());
                SET @SuccessCount = @SuccessCount + 1;
                PRINT 'Update 3: Success';
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION Update3;
                INSERT INTO #TransactionLog VALUES (3, 'Failed', 100, GETDATE());
                SET @FailCount = @FailCount + 1;
                PRINT 'Update 3: Failed - ' + ERROR_MESSAGE();
            END CATCH;
            
        COMMIT TRANSACTION;
        
        PRINT '';
        PRINT 'Batch processing completed';
        PRINT 'Successful updates: ' + CAST(@SuccessCount AS VARCHAR);
        PRINT 'Failed updates: ' + CAST(@FailCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Batch processing failed: ' + ERROR_MESSAGE();
    END CATCH;
END;

-- Execute
EXEC ProcessAccountBatch;


-- Question 30 Solution
PRINT '========================================';
PRINT 'NESTED TRANSACTIONS DEMONSTRATION';
PRINT '========================================';

-- Reset data
UPDATE #Account SET Balance = 1000 WHERE AccountID = 1;

BEGIN TRANSACTION;  -- Outer (@@TRANCOUNT = 1)
    PRINT 'Outer: Balance before = 1000';
    UPDATE #Account SET Balance = 900 WHERE AccountID = 1;
    PRINT 'Outer: Updated to 900';
    
    BEGIN TRANSACTION;  -- Inner (@@TRANCOUNT = 2)
        UPDATE #Account SET Balance = 800 WHERE AccountID = 1;
        PRINT 'Inner: Updated to 800';
        
        ROLLBACK TRANSACTION;  -- Rolls back EVERYTHING!
        PRINT 'Inner: ROLLBACK executed';
    
    -- Transaction is ABORTED! Cannot continue
    PRINT '@@TRANCOUNT after inner ROLLBACK: ' + CAST(@@TRANCOUNT AS VARCHAR);
    -- This would error: COMMIT TRANSACTION;

SELECT 'After nested ROLLBACK:' AS Demo, Balance FROM #Account WHERE AccountID = 1;
-- Balance = 1000 (BOTH updates rolled back!)

PRINT '';
PRINT '========================================';
PRINT 'SAVEPOINT DEMONSTRATION';
PRINT '========================================';

-- Reset data
UPDATE #Account SET Balance = 1000 WHERE AccountID = 1;

BEGIN TRANSACTION;
    PRINT 'Outer: Balance before = 1000';
    UPDATE #Account SET Balance = 900 WHERE AccountID = 1;
    PRINT 'Outer: Updated to 900';
    
    SAVE TRANSACTION InnerSavepoint;  -- Savepoint (@@TRANCOUNT still 1)
        UPDATE #Account SET Balance = 800 WHERE AccountID = 1;
        PRINT 'Inner: Updated to 800';
        
        ROLLBACK TRANSACTION InnerSavepoint;  -- Only rolls back to savepoint
        PRINT 'Inner: ROLLBACK to savepoint executed';
    
    -- Transaction still ACTIVE! Can continue
    PRINT '@@TRANCOUNT after savepoint ROLLBACK: ' + CAST(@@TRANCOUNT AS VARCHAR);
    UPDATE #Account SET Balance = 850 WHERE AccountID = 1;
    PRINT 'Outer: Continued, updated to 850';
    
COMMIT TRANSACTION;  -- Success!

SELECT 'After savepoint ROLLBACK:' AS Demo, Balance FROM #Account WHERE AccountID = 1;
-- Balance = 850 (Outer updates kept, inner rolled back!)

PRINT '';
PRINT 'KEY DIFFERENCE:';
PRINT '• Nested ROLLBACK: Aborts entire transaction';
PRINT '• Savepoint ROLLBACK: Only undoes work after savepoint';


-- SECTION 5 SOLUTIONS

-- Question 31 Solution
PRINT '========================================';
PRINT 'DEADLOCK DEMONSTRATION';
PRINT '========================================';

-- a) How deadlock occurs

/*
SESSION 1:
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processing' WHERE OrderID = 1;
    -- Holds lock on Orders
    
    WAITFOR DELAY '00:00:05';  -- Simulate processing
    
    UPDATE Inventory SET Quantity = Quantity - 1 WHERE ProductID = 1;
    -- Waits for lock on Inventory (held by Session 2)
COMMIT;

SESSION 2:
BEGIN TRANSACTION;
    UPDATE Inventory SET Quantity = Quantity - 1 WHERE ProductID = 1;
    -- Holds lock on Inventory
    
    WAITFOR DELAY '00:00:05';  -- Simulate processing
    
    UPDATE Orders SET Status = 'Processing' WHERE OrderID = 1;
    -- Waits for lock on Orders (held by Session 1)
COMMIT;

RESULT: DEADLOCK! Each waits for the other.
*/

-- b) Prevention: Use consistent locking order

PRINT 'PREVENTION SOLUTION:';
PRINT 'Always lock tables in same order: Orders THEN Inventory';

-- SESSION 1 (corrected):
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processing' WHERE OrderID = 1;  -- Lock Orders first
    UPDATE Inventory SET Quantity = Quantity - 1 WHERE ProductID = 1;  -- Then Inventory
COMMIT;

-- SESSION 2 (corrected):
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processing' WHERE OrderID = 2;  -- Lock Orders first
    UPDATE Inventory SET Quantity = Quantity - 1 WHERE ProductID = 2;  -- Then Inventory
COMMIT;

PRINT 'With consistent order, no deadlock!';

-- c) Detect deadlocks
PRINT '';
PRINT 'DETECT DEADLOCKS:';

-- View current locks
SELECT 
    tl.resource_type,
    tl.resource_database_id,
    tl.resource_associated_entity_id,
    tl.request_mode,
    tl.request_status,
    tl.request_session_id,
    er.blocking_session_id,
    er.wait_type,
    er.wait_time
FROM sys.dm_tran_locks tl
LEFT JOIN sys.dm_exec_requests er ON tl.request_session_id = er.session_id
WHERE tl.request_status = 'WAIT';

-- View deadlock graphs (requires trace)
-- Use SQL Server Profiler or Extended Events


-- Question 32 Solution
CREATE TABLE #StagingAccount (
    StagingID INT PRIMARY KEY IDENTITY,
    AccountID INT,
    AccountHolder VARCHAR(100),
    Balance DECIMAL(10,2),
    Processed BIT DEFAULT 0
);

-- Insert test data (some invalid)
INSERT INTO #StagingAccount (AccountID, AccountHolder, Balance) VALUES
(101, 'User 1', 100),
(102, 'User 2', -50),   -- Invalid: negative balance
(103, 'User 3', 200),
(104, 'User 4', 0),     -- Invalid: zero balance
(105, 'User 5', 300),
(106, 'User 6', -100),  -- Invalid: negative balance
(107, 'User 7', 150);

CREATE PROCEDURE ImportWithSavepoints
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StagingID INT;
    DECLARE @AccountID INT;
    DECLARE @AccountHolder VARCHAR(100);
    DECLARE @Balance DECIMAL(10,2);
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailCount INT = 0;
    DECLARE @SavepointName VARCHAR(50);
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            DECLARE staging_cursor CURSOR FOR
                SELECT StagingID, AccountID, AccountHolder, Balance
                FROM #StagingAccount
                WHERE Processed = 0;
            
            OPEN staging_cursor;
            FETCH NEXT FROM staging_cursor INTO @StagingID, @AccountID, @AccountHolder, @Balance;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @SavepointName = 'Record_' + CAST(@StagingID AS VARCHAR);
                SAVE TRANSACTION @SavepointName;
                
                BEGIN TRY
                    -- Validate
                    IF @Balance <= 0
                        RAISERROR('Balance must be greater than zero', 16, 1);
                    
                    -- Insert
                    INSERT INTO #Account (AccountID, AccountHolder, Balance)
                    VALUES (@AccountID, @AccountHolder, @Balance);
                    
                    -- Mark processed
                    UPDATE #StagingAccount SET Processed = 1 WHERE StagingID = @StagingID;
                    
                    SET @SuccessCount = @SuccessCount + 1;
                    PRINT 'Record ' + CAST(@StagingID AS VARCHAR) + ': Imported successfully';
                    
                END TRY
                BEGIN CATCH
                    -- Rollback only this record
                    ROLLBACK TRANSACTION @SavepointName;
                    SET @FailCount = @FailCount + 1;
                    PRINT 'Record ' + CAST(@StagingID AS VARCHAR) + ': Skipped - ' + ERROR_MESSAGE();
                END CATCH;
                
                FETCH NEXT FROM staging_cursor INTO @StagingID, @AccountID, @AccountHolder, @Balance;
            END
            
            CLOSE staging_cursor;
            DEALLOCATE staging_cursor;
            
        COMMIT TRANSACTION;
        
        PRINT '';
        PRINT 'Import completed:';
        PRINT '  Successful: ' + CAST(@SuccessCount AS VARCHAR);
        PRINT '  Failed: ' + CAST(@FailCount AS VARCHAR);
        PRINT '  Total: ' + CAST(@SuccessCount + @FailCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        IF CURSOR_STATUS('local', 'staging_cursor') >= 0
        BEGIN
            CLOSE staging_cursor;
            DEALLOCATE staging_cursor;
        END
        
        PRINT 'Import failed: ' + ERROR_MESSAGE();
    END CATCH;
END;

-- Execute import
EXEC ImportWithSavepoints;

-- View results
SELECT * FROM #Account WHERE AccountID >= 101;
SELECT * FROM #StagingAccount;


-- Cleanup
DROP TABLE #Account;
DROP TABLE #TransactionLog;
DROP TABLE #StagingAccount;


/*
============================================================================
SCORING RUBRIC
============================================================================

SECTION 1: Multiple Choice (100 points)
• 10 points per correct answer
• No partial credit

SECTION 2: True/False (50 points)
• 5 points per correct answer
• No partial credit

SECTION 3: Short Answer (100 points)
• 20 points per question
• Grading criteria:
  - Complete explanation: 20 points
  - Mostly correct: 15 points
  - Partially correct: 10 points
  - Minimal understanding: 5 points
  - Incorrect: 0 points

SECTION 4: Coding Questions (150 points)
• 30 points per question
• Grading criteria:
  - Working code: 20 points
  - Proper error handling: 5 points
  - Code quality: 5 points

SECTION 5: Bonus (50 points)
• 25 points per question
• Full credit for complete solution
• Partial credit for partial solution

TOTAL: 450 points (400 regular + 50 bonus)

PASSING: 280/400 (70%)

GRADE SCALE:
A: 360-400 (90-100%)
B: 320-359 (80-89%)
C: 280-319 (70-79%)
F: Below 280 (Below 70%)

============================================================================
CONGRATULATIONS!
============================================================================

You've completed the Transactions chapter! 

Key concepts mastered:
✓ Multi-user database challenges
✓ Locking mechanisms and granularities
✓ ACID properties
✓ Transaction lifecycle
✓ Starting and ending transactions
✓ Savepoints for partial rollback
✓ Error handling with TRY...CATCH
✓ Real-world transaction scenarios

Next steps:
• Review any questions you found challenging
• Practice implementing transactions in your own projects
• Study the performance implications of different isolation levels
• Learn about distributed transactions (advanced topic)

Keep practicing and building your SQL expertise!
============================================================================
*/
