/*
============================================================================
Lesson 12.05 - Starting Transactions
============================================================================

Description:
Master the different ways to start transactions in SQL Server. Learn about
implicit vs explicit transactions, auto-commit mode, BEGIN TRANSACTION
syntax, transaction naming, nesting, and the @@TRANCOUNT variable.

Topics Covered:
• Auto-commit transactions
• Explicit transactions (BEGIN TRANSACTION)
• Implicit transactions (SET IMPLICIT_TRANSACTIONS ON)
• Transaction naming
• Nested transactions
• @@TRANCOUNT variable
• Transaction modes comparison

Prerequisites:
• Lesson 12.04 (What is a Transaction)

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Auto-commit Transactions (Default Mode)
============================================================================
*/

-- Example 1.1: Auto-commit Behavior
/*
AUTO-COMMIT MODE (Default in SQL Server):
Each statement is automatically wrapped in a transaction

What you write:
    UPDATE Products SET Price = 100;

What SQL Server executes:
    BEGIN TRANSACTION;
        UPDATE Products SET Price = 100;
    COMMIT TRANSACTION;

Each statement = separate transaction!
*/

-- Example 1.2: Auto-commit Demo
CREATE TABLE #Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);

-- Each INSERT is a separate auto-commit transaction
INSERT INTO #Products VALUES (1, 'Laptop', 1000);     -- Transaction 1
INSERT INTO #Products VALUES (2, 'Mouse', 25);        -- Transaction 2
INSERT INTO #Products VALUES (3, 'Keyboard', 75);     -- Transaction 3

-- Each statement committed immediately
SELECT * FROM #Products;

-- Example 1.3: Auto-commit Limitation
/*
PROBLEM: Cannot rollback previous statements
*/

INSERT INTO #Products VALUES (4, 'Monitor', 300);    -- Committed ✓
INSERT INTO #Products VALUES (5, 'Speakers', 100);   -- Committed ✓

-- Oops, made a mistake! Want to undo...
-- CANNOT ROLLBACK! Already committed

-- Only way: Manually undo
DELETE FROM #Products WHERE ProductID IN (4, 5);

-- Example 1.4: When Auto-commit Fails
INSERT INTO #Products VALUES (6, 'Webcam', 150);     -- Succeeds, commits
-- System crashes here!
INSERT INTO #Products VALUES (7, 'Headset', 80);     -- Never executes

-- Result: Partial data (only product 6 inserted)
-- No atomicity across statements!

-- Example 1.5: When Auto-commit is Appropriate
/*
USE AUTO-COMMIT FOR:
✓ Single, independent statements
✓ Simple queries
✓ No relationship between statements
✓ Quick ad-hoc operations

EXAMPLES:
*/
SELECT * FROM #Products;                             -- Query
UPDATE #Products SET Price = 110 WHERE ProductID = 1; -- Single update
DELETE FROM #Products WHERE ProductID = 6;           -- Single delete


/*
============================================================================
PART 2: Explicit Transactions
============================================================================
*/

-- Example 2.1: BEGIN TRANSACTION Syntax
/*
SYNTAX:
BEGIN { TRAN | TRANSACTION } [ transaction_name ]

Variations:
• BEGIN TRANSACTION
• BEGIN TRAN                    (abbreviated)
• BEGIN TRANSACTION TransferMoney  (with name)
*/

-- Example 2.2: Basic Explicit Transaction
BEGIN TRANSACTION;
    INSERT INTO #Products VALUES (8, 'USB Cable', 10);
    INSERT INTO #Products VALUES (9, 'SD Card', 30);
    UPDATE #Products SET Price = Price * 1.1 WHERE ProductID < 5;
COMMIT TRANSACTION;

-- All three statements = one atomic unit

-- Example 2.3: Explicit Transaction with Rollback
BEGIN TRANSACTION;
    DELETE FROM #Products WHERE ProductID = 1;
    DELETE FROM #Products WHERE ProductID = 2;
    
    -- Oops, changed our mind!
ROLLBACK TRANSACTION;  -- Undo both deletes

SELECT * FROM #Products;  -- Products 1 and 2 still exist

-- Example 2.4: Conditional Commit/Rollback
BEGIN TRANSACTION;
    UPDATE #Products SET Price = Price - 50 WHERE ProductID = 1;
    
    -- Check if update valid
    IF EXISTS (SELECT 1 FROM #Products WHERE ProductID = 1 AND Price < 0)
    BEGIN
        PRINT 'Error: Negative price detected';
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        PRINT 'Update successful';
        COMMIT TRANSACTION;
    END

-- Example 2.5: Explicit Transaction Benefits
/*
ADVANTAGES:
✓ Atomicity across multiple statements
✓ Can rollback before commit
✓ Full control over transaction
✓ Can inspect state before committing
✓ Error handling integration

WHEN TO USE:
• Multiple related statements
• Need all-or-nothing guarantee
• Complex business logic
• Error recovery needed
*/


/*
============================================================================
PART 3: Transaction Naming
============================================================================
*/

-- Example 3.1: Named Transactions
-- Syntax: BEGIN TRANSACTION transaction_name
BEGIN TRANSACTION UpdatePrices;
    UPDATE #Products SET Price = Price * 1.05;
COMMIT TRANSACTION UpdatePrices;

-- Example 3.2: Transaction Names in Logs
-- Named transactions easier to identify in error messages
BEGIN TRANSACTION OrderProcessing;
    BEGIN TRY
        INSERT INTO #Products VALUES (10, 'Test', 100);
        -- Error: Duplicate key
        INSERT INTO #Products VALUES (10, 'Duplicate', 200);
    END TRY
    BEGIN CATCH
        PRINT 'Error in transaction: OrderProcessing';
        PRINT ERROR_MESSAGE();
        ROLLBACK TRANSACTION OrderProcessing;
    END CATCH;

-- Example 3.3: Transaction Name Rules
/*
RULES FOR TRANSACTION NAMES:
• Must follow identifier rules
• Max 32 characters
• Only first 32 characters used
• Case-sensitive (in case-sensitive collations)
• Names don't nest (only outermost name matters)
• Optional with COMMIT/ROLLBACK
*/

BEGIN TRANSACTION MyVeryLongTransactionNameThatExceeds32Characters;
    -- Only first 32 chars used
    SELECT 'Transaction started';
COMMIT;  -- Name optional on COMMIT

-- Example 3.4: Benefits of Naming
/*
BENEFITS:
✓ Better error messages
✓ Easier debugging
✓ Self-documenting code
✓ Clearer logs
✓ Improved readability

EXAMPLE ERROR:
"Transaction 'OrderProcessing' aborted due to constraint violation"
vs
"Transaction aborted due to constraint violation"
*/


/*
============================================================================
PART 4: The @@TRANCOUNT Variable
============================================================================
*/

-- Example 4.1: What is @@TRANCOUNT?
/*
@@TRANCOUNT:
Returns the number of active transactions for current connection

┌────────────────────────────────────────┐
│ @@TRANCOUNT Values                     │
├────────────────────────────────────────┤
│ 0 = No active transaction              │
│ 1 = One active transaction             │
│ 2+ = Nested transactions               │
└────────────────────────────────────────┘
*/

-- Example 4.2: @@TRANCOUNT Demo
PRINT 'Initial @@TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

BEGIN TRANSACTION;
    PRINT 'After BEGIN TRAN: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
    INSERT INTO #Products VALUES (11, 'Item A', 50);
    PRINT 'During transaction: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
COMMIT TRANSACTION;
PRINT 'After COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Example 4.3: @@TRANCOUNT with Rollback
BEGIN TRANSACTION;
    PRINT 'Transaction started: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
    UPDATE #Products SET Price = 999 WHERE ProductID = 1;
    
ROLLBACK TRANSACTION;
PRINT 'After ROLLBACK: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Example 4.4: Using @@TRANCOUNT for Safety Checks
CREATE PROCEDURE SafeUpdate
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    -- Check if already in transaction
    IF @@TRANCOUNT = 0
        BEGIN TRANSACTION;
    
    UPDATE #Products 
    SET Price = @NewPrice 
    WHERE ProductID = @ProductID;
    
    -- Only commit if WE started the transaction
    IF @@TRANCOUNT = 1
        COMMIT TRANSACTION;
END;

-- Example 4.5: @@TRANCOUNT Best Practice
/*
SAFE TRANSACTION PATTERN:
*/
CREATE PROCEDURE ProcessOrder
    @OrderID INT
AS
BEGIN
    DECLARE @TranStarted BIT = 0;
    
    -- Start transaction if not already in one
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @TranStarted = 1;
    END
    
    BEGIN TRY
        -- Business logic here
        UPDATE Orders SET Status = 'Processed' WHERE OrderID = @OrderID;
        
        -- Commit if we started the transaction
        IF @TranStarted = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback if we started the transaction
        IF @TranStarted = 1
            ROLLBACK TRANSACTION;
            
        -- Re-throw error
        THROW;
    END CATCH;
END;


/*
============================================================================
PART 5: Nested Transactions
============================================================================
*/

-- Example 5.1: Nested Transaction Basics
/*
NESTED TRANSACTIONS:
BEGIN TRANSACTION can be called multiple times

┌─────────────────────────────────────────────┐
│ BEGIN TRAN        @@TRANCOUNT = 1           │
│   BEGIN TRAN      @@TRANCOUNT = 2           │
│     BEGIN TRAN    @@TRANCOUNT = 3           │
│     COMMIT        @@TRANCOUNT = 2           │
│   COMMIT          @@TRANCOUNT = 1           │
│ COMMIT            @@TRANCOUNT = 0 ← COMMITS │
└─────────────────────────────────────────────┘

IMPORTANT: Only outermost COMMIT actually commits!
*/

-- Example 5.2: Nested Transaction Demo
BEGIN TRANSACTION;  -- Outer transaction
    PRINT 'Outer BEGIN: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
    INSERT INTO #Products VALUES (12, 'Outer', 100);
    
    BEGIN TRANSACTION;  -- Inner transaction
        PRINT 'Inner BEGIN: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 2
        
        INSERT INTO #Products VALUES (13, 'Inner', 200);
        
    COMMIT TRANSACTION;  -- Inner commit
    PRINT 'Inner COMMIT: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
COMMIT TRANSACTION;  -- Outer commit (actual commit!)
PRINT 'Outer COMMIT: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Both inserts committed together at outer COMMIT
SELECT * FROM #Products WHERE ProductID IN (12, 13);

-- Example 5.3: Nested Rollback Behavior
/*
CRITICAL BEHAVIOR:
Any ROLLBACK rolls back ENTIRE transaction (all levels)!

┌─────────────────────────────────────────────┐
│ BEGIN TRAN                                  │
│   INSERT Row 1                              │
│   BEGIN TRAN                                │
│     INSERT Row 2                            │
│     ROLLBACK  ← Rolls back Row 1 AND Row 2!│
│ -- Transaction aborted!                     │
└─────────────────────────────────────────────┘
*/

BEGIN TRANSACTION;  -- Outer
    INSERT INTO #Products VALUES (14, 'Will Rollback', 100);
    
    BEGIN TRANSACTION;  -- Inner
        INSERT INTO #Products VALUES (15, 'Also Rollback', 200);
        
        ROLLBACK TRANSACTION;  -- Rolls back EVERYTHING!
        
    -- Cannot continue, transaction aborted!
    -- This will error: COMMIT TRANSACTION;
    
-- Check: Neither row 14 nor 15 exists
SELECT * FROM #Products WHERE ProductID IN (14, 15);  -- Empty

-- Example 5.4: Safe Nested Transaction Pattern
CREATE PROCEDURE InnerProc
AS
BEGIN
    DECLARE @TranCount INT = @@TRANCOUNT;
    
    IF @TranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION InnerProc;  -- Savepoint instead of nested tran
    
    BEGIN TRY
        -- Do work
        UPDATE #Products SET Price = Price + 10 WHERE ProductID = 1;
        
        IF @TranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @TranCount = 0
            ROLLBACK TRANSACTION;
        ELSE
            ROLLBACK TRANSACTION InnerProc;  -- Rollback to savepoint
            
        THROW;
    END CATCH;
END;

-- Example 5.5: Nested Transaction Pitfalls
/*
COMMON MISTAKES:

Mistake 1: Assuming inner COMMIT commits data
*/
BEGIN TRANSACTION;
    INSERT INTO #Products VALUES (16, 'Test', 100);
    
    BEGIN TRANSACTION;
        INSERT INTO #Products VALUES (17, 'Test2', 200);
    COMMIT;  -- ← Does NOT commit! Just decrements @@TRANCOUNT
    
    -- Data still not committed!
    -- Can still rollback
ROLLBACK;  -- Rolls back both inserts!
/*

Mistake 2: Not handling rollback properly
*/
BEGIN TRANSACTION;
    -- Some work...
    
    BEGIN TRANSACTION;
        -- Some work...
        ROLLBACK;  -- ← Aborts entire transaction!
    
    COMMIT;  -- ← ERROR! No active transaction
/*

BEST PRACTICE:
Avoid nesting when possible. Use savepoints instead (next lesson).
*/


/*
============================================================================
PART 6: Implicit Transactions
============================================================================
*/

-- Example 6.1: SET IMPLICIT_TRANSACTIONS ON
/*
IMPLICIT TRANSACTION MODE:
Automatically starts transaction before statements
But you must manually COMMIT or ROLLBACK
*/

-- Enable implicit transactions
SET IMPLICIT_TRANSACTIONS ON;

-- These statements automatically start transactions
UPDATE #Products SET Price = 50 WHERE ProductID = 1;  -- Auto-BEGIN TRAN
PRINT '@@TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1

-- Must manually commit
COMMIT TRANSACTION;
PRINT '@@TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Turn off implicit transactions
SET IMPLICIT_TRANSACTIONS OFF;

-- Example 6.2: Implicit Transaction Triggers
/*
STATEMENTS THAT AUTO-START TRANSACTION (when implicit mode on):
• ALTER TABLE
• CREATE
• DELETE
• DROP
• FETCH
• GRANT
• INSERT
• OPEN
• REVOKE
• SELECT (some cases)
• TRUNCATE TABLE
• UPDATE
*/

SET IMPLICIT_TRANSACTIONS ON;

DELETE FROM #Products WHERE ProductID = 11;
PRINT 'Transaction started: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1

INSERT INTO #Products VALUES (18, 'Implicit', 100);
PRINT 'Still in transaction: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1

COMMIT;  -- Must commit manually

SET IMPLICIT_TRANSACTIONS OFF;

-- Example 6.3: Implicit Transaction Pitfalls
/*
DANGEROUS PATTERN:
*/
SET IMPLICIT_TRANSACTIONS ON;

-- User runs query
SELECT * FROM #Products;  -- Transaction started!

-- Walks away from keyboard...
-- Transaction still open! (holding locks)

-- Other users blocked!

-- Hours later... comes back
COMMIT;  -- Finally releases locks
/*

PROBLEM: Easy to forget to commit
SOLUTION: Usually avoid implicit transactions
*/

-- Example 6.4: Checking Current Mode
SELECT 
    CASE 
        WHEN (@@OPTIONS & 2) = 2 THEN 'IMPLICIT_TRANSACTIONS ON'
        ELSE 'IMPLICIT_TRANSACTIONS OFF (Auto-commit)'
    END AS TransactionMode;


/*
============================================================================
PART 7: Comparing Transaction Modes
============================================================================
*/

-- Example 7.1: Mode Comparison Table
/*
┌──────────────────┬──────────────┬──────────────┬─────────────────┐
│     Feature      │ Auto-commit  │  Explicit    │   Implicit      │
├──────────────────┼──────────────┼──────────────┼─────────────────┤
│ How Started      │ Automatic    │ BEGIN TRAN   │ Automatic       │
│ How Ended        │ Automatic    │ COMMIT/      │ Manual COMMIT/  │
│                  │              │ ROLLBACK     │ ROLLBACK        │
│ Scope            │ Single stmt  │ Multi-stmt   │ Multi-stmt      │
│ Control          │ None         │ Full         │ Partial         │
│ Rollback Ability │ No           │ Yes          │ Yes             │
│ Lock Duration    │ Short        │ Long         │ Long            │
│ Forget to Commit │ N/A          │ Warning      │ Dangerous!      │
│ Default Mode     │ YES ✓        │ No           │ No              │
│ Recommended      │ Simple ops   │ Complex ops  │ Rarely          │
└──────────────────┴──────────────┴──────────────┴─────────────────┘
*/

-- Example 7.2: Auto-commit Example
-- Default mode - each statement separate transaction
UPDATE #Products SET Price = 100 WHERE ProductID = 1;  -- Transaction 1
UPDATE #Products SET Price = 200 WHERE ProductID = 2;  -- Transaction 2
-- Cannot rollback first update

-- Example 7.3: Explicit Transaction Example
BEGIN TRANSACTION;  -- Start manually
    UPDATE #Products SET Price = 100 WHERE ProductID = 1;
    UPDATE #Products SET Price = 200 WHERE ProductID = 2;
    -- Can inspect, decide to rollback
    IF @@ROWCOUNT < 2
        ROLLBACK;
    ELSE
        COMMIT;  -- End manually

-- Example 7.4: Implicit Transaction Example
SET IMPLICIT_TRANSACTIONS ON;
    UPDATE #Products SET Price = 100 WHERE ProductID = 1;  -- Auto-starts transaction
    UPDATE #Products SET Price = 200 WHERE ProductID = 2;  -- Same transaction continues
    COMMIT;  -- Must commit manually
SET IMPLICIT_TRANSACTIONS OFF;

-- Example 7.5: Recommendation
/*
RECOMMENDED APPROACH:

1. Keep IMPLICIT_TRANSACTIONS OFF (default)
2. Use auto-commit for simple, independent statements
3. Use explicit BEGIN TRANSACTION for complex operations

Example:
*/

-- Simple query: use auto-commit
SELECT * FROM #Products;

-- Complex operation: use explicit transaction
BEGIN TRANSACTION;
    -- Multiple related operations
    DELETE FROM OrderDetails WHERE OrderID = 123;
    DELETE FROM Orders WHERE OrderID = 123;
    INSERT INTO OrderArchive SELECT * FROM Orders WHERE OrderID = 123;
COMMIT TRANSACTION;


/*
============================================================================
PART 8: Best Practices for Starting Transactions
============================================================================
*/

-- Example 8.1: Always Use TRY...CATCH
BEGIN TRANSACTION;
BEGIN TRY
    -- Your code here
    UPDATE #Products SET Price = 150 WHERE ProductID = 1;
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    -- Log error
    PRINT 'Error: ' + ERROR_MESSAGE();
    
    -- Re-throw if needed
    THROW;
END CATCH;

-- Example 8.2: Check @@TRANCOUNT Before Commit/Rollback
IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END

BEGIN TRANSACTION;
    -- ... operations ...
    
    IF @@TRANCOUNT > 0  -- Safety check
        COMMIT TRANSACTION;

-- Example 8.3: Keep Transactions Short
-- BAD: Long transaction
BEGIN TRANSACTION;
    -- Heavy computation
    WAITFOR DELAY '00:01:00';  -- 1 minute delay (holds locks!)
    UPDATE #Products SET Price = 100 WHERE ProductID = 1;
COMMIT;

-- GOOD: Short transaction
-- Do computation first (outside transaction)
WAITFOR DELAY '00:01:00';  -- Computation

-- Then quick transaction
BEGIN TRANSACTION;
    UPDATE #Products SET Price = 100 WHERE ProductID = 1;
COMMIT;

-- Example 8.4: Name Transactions for Clarity
-- Unclear
BEGIN TRANSACTION;
    -- ... operations ...
COMMIT;

-- Clear
BEGIN TRANSACTION UpdateInventory;
    UPDATE Products SET Quantity = Quantity - 5 WHERE ProductID = 1;
COMMIT TRANSACTION UpdateInventory;

-- Cleanup
DROP TABLE #Products;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Compare auto-commit, explicit, and implicit transaction modes
2. Demonstrate proper use of @@TRANCOUNT
3. Explain nested transaction behavior and pitfalls
4. Write a procedure that safely handles transactions
5. Create examples showing when to use each transaction mode

Solutions below ↓
*/

-- Solution 1: Transaction Mode Comparison
/*
MODE COMPARISON:

AUTO-COMMIT (Default):
*/
-- Each statement is separate transaction
INSERT INTO Products VALUES (1, 'Item1', 100);  -- Commits immediately
INSERT INTO Products VALUES (2, 'Item2', 200);  -- Commits immediately
-- Cannot rollback previous statements

/*
Pros:
✓ Simple, automatic
✓ No forgotten transactions
✓ Good for simple operations

Cons:
✗ No atomicity across statements
✗ Cannot rollback
✗ Not suitable for complex operations

EXPLICIT TRANSACTION:
*/
BEGIN TRANSACTION;  -- Manual start
    INSERT INTO Products VALUES (1, 'Item1', 100);
    INSERT INTO Products VALUES (2, 'Item2', 200);
    -- Can inspect, validate, decide
COMMIT TRANSACTION;  -- Manual commit
-- Or ROLLBACK TRANSACTION;

/*
Pros:
✓ Full control
✓ Atomicity across statements
✓ Can rollback before commit
✓ Error handling integration

Cons:
✗ Manual management
✗ Can forget to commit
✗ Holds locks longer

IMPLICIT TRANSACTION:
*/
SET IMPLICIT_TRANSACTIONS ON;
INSERT INTO Products VALUES (1, 'Item1', 100);  -- Auto-starts transaction
-- Transaction still open!
COMMIT;  -- Must remember to commit
SET IMPLICIT_TRANSACTIONS OFF;

/*
Pros:
✓ Automatic transaction start
✓ Multi-statement transactions

Cons:
✗ Easy to forget to commit
✗ Dangerous (locks held indefinitely)
✗ Not recommended

WHEN TO USE EACH:
• Auto-commit: Simple, independent statements
• Explicit: Complex operations, multiple statements
• Implicit: Rarely (compatibility with other DBs)
*/

-- Solution 2: @@TRANCOUNT Usage
PRINT 'Example: @@TRANCOUNT Monitoring';

-- Check initial state
PRINT '1. Initial @@TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Start transaction
BEGIN TRANSACTION;
PRINT '2. After BEGIN TRAN: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1

-- Nested transaction
BEGIN TRANSACTION;
PRINT '3. After nested BEGIN: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 2

-- Inner commit
COMMIT;
PRINT '4. After inner COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1

-- Outer commit
COMMIT;
PRINT '5. After outer COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Safe procedure using @@TRANCOUNT
CREATE PROCEDURE SafeProcedure
AS
BEGIN
    DECLARE @LocalTranStarted BIT = 0;
    
    -- Start transaction only if not already in one
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
        PRINT 'Procedure started transaction';
    END
    ELSE
    BEGIN
        PRINT 'Procedure joined existing transaction';
    END
    
    BEGIN TRY
        -- Do work
        UPDATE Products SET Price = 100 WHERE ProductID = 1;
        
        -- Commit only if we started the transaction
        IF @LocalTranStarted = 1
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'Procedure committed transaction';
        END
    END TRY
    BEGIN CATCH
        -- Rollback only if we started the transaction
        IF @LocalTranStarted = 1
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Procedure rolled back transaction';
        END
        
        THROW;  -- Re-throw error
    END CATCH;
END;

-- Solution 3: Nested Transaction Behavior
/*
NESTED TRANSACTION BEHAVIOR:

Key Points:
1. @@TRANCOUNT increments with each BEGIN TRANSACTION
2. Only outermost COMMIT actually commits data
3. Any ROLLBACK rolls back entire transaction
*/

-- Demonstration:
PRINT 'Nested Transaction Demo:';

BEGIN TRANSACTION;  -- Level 1
    PRINT 'Level 1: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
    INSERT INTO TempTable VALUES (1, 'Level 1');
    
    BEGIN TRANSACTION;  -- Level 2
        PRINT 'Level 2: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 2
        
        INSERT INTO TempTable VALUES (2, 'Level 2');
        
        BEGIN TRANSACTION;  -- Level 3
            PRINT 'Level 3: @@TRANCOUNT = ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 3
            
            INSERT INTO TempTable VALUES (3, 'Level 3');
            
        COMMIT;  -- Decrements to 2
        PRINT 'After Level 3 COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 2
        
    COMMIT;  -- Decrements to 1
    PRINT 'After Level 2 COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1
    
COMMIT;  -- Decrements to 0 and COMMITS all changes
PRINT 'After Level 1 COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

/*
PITFALL: ROLLBACK in nested transaction
*/
BEGIN TRANSACTION;  -- Outer
    INSERT INTO TempTable VALUES (4, 'Outer');
    
    BEGIN TRANSACTION;  -- Inner
        INSERT INTO TempTable VALUES (5, 'Inner');
        
        ROLLBACK TRANSACTION;  -- ← Rolls back EVERYTHING!
        
    -- Transaction is aborted! Cannot continue
    -- This will error:
    -- COMMIT;
    
-- Rows 4 and 5 both rolled back

-- SOLUTION: Use savepoints instead
BEGIN TRANSACTION;  -- Outer
    INSERT INTO TempTable VALUES (6, 'Outer');
    
    SAVE TRANSACTION InnerSavepoint;  -- Savepoint instead of nested BEGIN
        INSERT INTO TempTable VALUES (7, 'Inner');
        
        -- Can rollback to savepoint
        ROLLBACK TRANSACTION InnerSavepoint;  -- Only rolls back row 7
        
    -- Can continue!
    INSERT INTO TempTable VALUES (8, 'After rollback');
    
COMMIT;  -- Rows 6 and 8 committed, row 7 not

-- Solution 4: Safe Transaction Handling Procedure
CREATE PROCEDURE ProcessOrderSafely
    @OrderID INT,
    @CustomerID INT,
    @TotalAmount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Track if this procedure started the transaction
    DECLARE @TranStarted BIT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    
    -- Start transaction if not already in one
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @TranStarted = 1;
    END
    
    BEGIN TRY
        -- Validate inputs
        IF @OrderID IS NULL OR @CustomerID IS NULL OR @TotalAmount <= 0
        BEGIN
            RAISERROR('Invalid input parameters', 16, 1);
        END
        
        -- Insert order
        INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount)
        VALUES (@OrderID, @CustomerID, GETDATE(), @TotalAmount);
        
        -- Update customer stats
        UPDATE Customers 
        SET TotalOrders = TotalOrders + 1,
            TotalSpent = TotalSpent + @TotalAmount
        WHERE CustomerID = @CustomerID;
        
        -- Verify changes
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Customer not found', 16, 1);
        END
        
        -- Log the transaction
        INSERT INTO OrderLog (OrderID, LogDate, Action)
        VALUES (@OrderID, GETDATE(), 'Created');
        
        -- Commit only if we started the transaction
        IF @TranStarted = 1
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'Order processed successfully';
        END
        
        RETURN 0;  -- Success
    END TRY
    BEGIN CATCH
        -- Capture error details
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        
        -- Rollback only if we started the transaction
        IF @TranStarted = 1 AND @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT 'Transaction rolled back due to error';
        END
        
        -- Log error
        PRINT 'Error processing order: ' + @ErrorMessage;
        
        -- Re-throw error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        
        RETURN -1;  -- Failure
    END CATCH;
END;

-- Solution 5: When to Use Each Transaction Mode
/*
SCENARIO-BASED EXAMPLES:

SCENARIO 1: Simple query
Use: Auto-commit (default)
*/
SELECT * FROM Products WHERE Price > 100;
/*

SCENARIO 2: Single update
Use: Auto-commit (default)
*/
UPDATE Products SET Price = 150 WHERE ProductID = 1;
/*

SCENARIO 3: Money transfer (multiple related updates)
Use: Explicit transaction
*/
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 500 WHERE AccountID = 1;
    UPDATE Accounts SET Balance = Balance + 500 WHERE AccountID = 2;
    
    -- Verify balances are correct
    IF EXISTS (SELECT 1 FROM Accounts WHERE Balance < 0)
        ROLLBACK;
    ELSE
        COMMIT;
/*

SCENARIO 4: Order processing (multiple tables, integrity critical)
Use: Explicit transaction
*/
BEGIN TRANSACTION;
BEGIN TRY
    -- Insert order header
    INSERT INTO Orders (CustomerID, OrderDate) VALUES (1, GETDATE());
    DECLARE @OrderID INT = SCOPE_IDENTITY();
    
    -- Insert order details
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity)
    VALUES (@OrderID, 101, 5);
    
    -- Update inventory
    UPDATE Products SET Stock = Stock - 5 WHERE ProductID = 101;
    
    -- All or nothing!
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    THROW;
END CATCH;
/*

SCENARIO 5: Bulk data load (performance critical)
Use: Explicit transaction with batch commits
*/
DECLARE @BatchSize INT = 1000;
DECLARE @Counter INT = 0;

BEGIN TRANSACTION;
WHILE EXISTS (SELECT 1 FROM StagingTable WHERE Processed = 0)
BEGIN
    INSERT INTO MainTable
    SELECT TOP (@BatchSize) * FROM StagingTable WHERE Processed = 0;
    
    UPDATE TOP (@BatchSize) StagingTable SET Processed = 1 WHERE Processed = 0;
    
    SET @Counter = @Counter + @BatchSize;
    
    -- Commit every 10,000 rows
    IF @Counter >= 10000
    BEGIN
        COMMIT;
        BEGIN TRANSACTION;
        SET @Counter = 0;
    END
END
COMMIT;
/*

SCENARIO 6: Ad-hoc testing/development
Use: Auto-commit (easy, safe)
*/
-- Quick tests, no transaction management needed
SELECT COUNT(*) FROM Orders;
UPDATE Orders SET Status = 'Test' WHERE OrderID = 999;
DELETE FROM Orders WHERE OrderID = 999;
/*

SUMMARY:
• Auto-commit: Simple, independent operations
• Explicit: Complex, multi-step operations
• Implicit: Almost never (avoid)
*/


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ TRANSACTION MODES:
  • Auto-commit: Default, each statement separate
  • Explicit: BEGIN TRANSACTION...COMMIT/ROLLBACK
  • Implicit: SET IMPLICIT_TRANSACTIONS ON (rarely used)

✓ AUTO-COMMIT:
  • Each statement auto-commits
  • No rollback capability
  • Good for simple operations
  • Default SQL Server mode

✓ EXPLICIT TRANSACTIONS:
  • Full control over scope
  • Can rollback before commit
  • Use for complex operations
  • Best practice for critical operations

✓ BEGIN TRANSACTION:
  • Syntax: BEGIN TRAN [name]
  • Starts explicit transaction
  • Increments @@TRANCOUNT
  • Can be named for clarity

✓ @@TRANCOUNT:
  • Returns number of active transactions
  • 0 = no transaction
  • > 0 = in transaction
  • Use for safety checks

✓ NESTED TRANSACTIONS:
  • @@TRANCOUNT > 1
  • Only outermost COMMIT commits
  • Any ROLLBACK rolls back all levels
  • Use savepoints instead when possible

✓ IMPLICIT TRANSACTIONS:
  • Auto-starts, manual commit
  • Easy to forget COMMIT
  • Generally avoided
  • Can cause lock issues

✓ BEST PRACTICES:
  • Use explicit for complex operations
  • Always use TRY...CATCH
  • Check @@TRANCOUNT before commit/rollback
  • Keep transactions short
  • Name transactions for clarity
  • Avoid implicit mode
  • Handle errors properly

============================================================================
NEXT: Lesson 12.06 - Ending Transactions
Learn how to properly commit and rollback transactions.
============================================================================
*/
