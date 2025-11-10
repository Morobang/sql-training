/*
============================================================================
Lesson 12.07 - Transaction Savepoints
============================================================================

Description:
Master the use of savepoints for partial transaction rollback. Learn how
to create savepoints, rollback to savepoints, use them in nested scenarios,
handle errors with savepoints, and implement complex multi-step transactions
with checkpoint recovery.

Topics Covered:
• What are savepoints
• Creating savepoints (SAVE TRANSACTION)
• Rolling back to savepoints
• Multiple savepoints
• Savepoints vs nested transactions
• Error handling with savepoints
• Savepoint limitations
• Best practices

Prerequisites:
• Lesson 12.06 (Ending Transactions)

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Introduction to Savepoints
============================================================================
*/

-- Example 1.1: What is a Savepoint?
/*
SAVEPOINT:
A marker within a transaction that allows partial rollback

┌─────────────────────────────────────────────────────────┐
│ BEGIN TRANSACTION                                       │
│   Statement 1                                           │
│   Statement 2                                           │
│   SAVE TRANSACTION SP1  ← Savepoint marker             │
│   Statement 3                                           │
│   Statement 4                                           │
│   ROLLBACK TRANSACTION SP1  ← Rollback to marker       │
│   Statement 5                                           │
│ COMMIT TRANSACTION                                      │
└─────────────────────────────────────────────────────────┘

Result:
✓ Statements 1, 2 kept
✗ Statements 3, 4 undone (rolled back)
✓ Statement 5 kept
✓ Transaction committed

WITHOUT SAVEPOINT:
ROLLBACK would undo ALL statements (1-5)
*/

-- Example 1.2: SAVE TRANSACTION Syntax
/*
SYNTAX:
SAVE { TRAN | TRANSACTION } savepoint_name

Examples:
• SAVE TRANSACTION MySavepoint
• SAVE TRAN sp1
*/

-- Example 1.3: Basic Savepoint Example
CREATE TABLE #Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2),
    Status VARCHAR(20)
);

BEGIN TRANSACTION;
    -- Step 1: Create order
    INSERT INTO #Orders VALUES (1, 101, GETDATE(), 0, 'New');
    PRINT 'Order created';
    
    -- Create savepoint before details
    SAVE TRANSACTION BeforeDetails;
    
    -- Step 2: Add details (might fail)
    UPDATE #Orders SET TotalAmount = 500 WHERE OrderID = 1;
    UPDATE #Orders SET TotalAmount = -100 WHERE OrderID = 1;  -- Invalid!
    
    -- Oops, error! Rollback just the details
    ROLLBACK TRANSACTION BeforeDetails;
    PRINT 'Details rolled back, but order still exists';
    
    -- Continue with valid data
    UPDATE #Orders SET TotalAmount = 300, Status = 'Confirmed' WHERE OrderID = 1;
    
COMMIT TRANSACTION;

SELECT * FROM #Orders;  -- Order exists with TotalAmount = 300

-- Example 1.4: Why Use Savepoints?
/*
USE CASES:

1. Partial Rollback
   ✓ Keep successful parts
   ✗ Undo failed parts
   
2. Complex Multi-Step Transactions
   ✓ Checkpoint after each step
   ✗ Rollback to last good checkpoint
   
3. Error Recovery
   ✓ Retry failed operation
   ✗ Without losing all progress
   
4. Batch Processing
   ✓ Process in chunks
   ✗ Rollback only failed chunk
   
5. Nested Logic
   ✓ Alternative to nested transactions
   ✗ Safer rollback behavior
*/


/*
============================================================================
PART 2: Creating and Using Savepoints
============================================================================
*/

-- Example 2.1: Creating Multiple Savepoints
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (2, 102, GETDATE(), 100, 'New');
    SAVE TRANSACTION AfterInsert;
    
    UPDATE #Orders SET Status = 'Processing' WHERE OrderID = 2;
    SAVE TRANSACTION AfterUpdate;
    
    UPDATE #Orders SET TotalAmount = 200 WHERE OrderID = 2;
    SAVE TRANSACTION AfterAmount;
    
    -- Rollback to middle savepoint
    ROLLBACK TRANSACTION AfterUpdate;
    
COMMIT TRANSACTION;

SELECT * FROM #Orders WHERE OrderID = 2;
-- Result: Order exists with Status = 'Processing', Amount = 100

-- Example 2.2: Savepoint Stack Behavior
/*
SAVEPOINTS ARE STACK-BASED:

┌─────────────────────────────────────┐
│ BEGIN TRANSACTION                   │
│   Work A                            │
│   SAVE TRANSACTION SP1              │ ← Savepoint 1
│     Work B                          │
│     SAVE TRANSACTION SP2            │ ← Savepoint 2
│       Work C                        │
│       SAVE TRANSACTION SP3          │ ← Savepoint 3
│         Work D                      │
│       ROLLBACK TRANSACTION SP2  ←───┘ Rollback to SP2
│     Work E                          │
│   COMMIT                            │
└─────────────────────────────────────┘

Result:
✓ Work A: Kept
✓ Work B: Kept
✗ Work C: Undone (rolled back)
✗ Work D: Undone (rolled back)
✗ SP3: Destroyed (savepoint removed)
✓ Work E: Kept

Note: Rolling back to SP2 destroys SP3!
*/

-- Example 2.3: Demonstrating Stack Behavior
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (3, 103, GETDATE(), 100, 'New');
    PRINT 'A: Order 3 created';
    
    SAVE TRANSACTION SP1;
    UPDATE #Orders SET Status = 'Processing' WHERE OrderID = 3;
    PRINT 'B: Status updated to Processing';
    
    SAVE TRANSACTION SP2;
    UPDATE #Orders SET Status = 'Shipped' WHERE OrderID = 3;
    PRINT 'C: Status updated to Shipped';
    
    SAVE TRANSACTION SP3;
    UPDATE #Orders SET Status = 'Delivered' WHERE OrderID = 3;
    PRINT 'D: Status updated to Delivered';
    
    -- Rollback to SP2 (removes SP3)
    ROLLBACK TRANSACTION SP2;
    PRINT 'Rolled back to SP2 (work C and D undone, SP3 destroyed)';
    
    -- Try to rollback to SP3 (will ERROR - SP3 no longer exists!)
    -- ROLLBACK TRANSACTION SP3;  -- Uncommenting this causes error
    
    -- Continue with more work
    UPDATE #Orders SET TotalAmount = 300 WHERE OrderID = 3;
    PRINT 'E: Amount updated';
    
COMMIT TRANSACTION;

SELECT * FROM #Orders WHERE OrderID = 3;
-- Status = 'Processing' (work B kept, C and D rolled back)

-- Example 2.4: Reusing Savepoint Names
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (4, 104, GETDATE(), 100, 'New');
    SAVE TRANSACTION Checkpoint;
    
    UPDATE #Orders SET Status = 'Processing' WHERE OrderID = 4;
    SAVE TRANSACTION Checkpoint;  -- Replaces previous savepoint
    
    UPDATE #Orders SET Status = 'ERROR' WHERE OrderID = 4;
    
    -- Rollback to latest 'Checkpoint'
    ROLLBACK TRANSACTION Checkpoint;
    
COMMIT TRANSACTION;

SELECT * FROM #Orders WHERE OrderID = 4;
-- Status = 'Processing' (last savepoint)

-- Example 2.5: Savepoint Naming Rules
/*
SAVEPOINT NAME RULES:
• Must be valid identifier
• Case-sensitive (in some collations)
• Max 32 characters
• Can be variable

Examples:
*/
DECLARE @SavepointName VARCHAR(50) = 'DynamicSavepoint_' + CAST(GETDATE() AS VARCHAR);

BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (5, 105, GETDATE(), 100, 'New');
    
    -- Dynamic savepoint name
    SAVE TRANSACTION @SavepointName;
    
    UPDATE #Orders SET Status = 'Processing' WHERE OrderID = 5;
    
    -- Rollback using variable
    ROLLBACK TRANSACTION @SavepointName;
    
COMMIT TRANSACTION;


/*
============================================================================
PART 3: Savepoints vs Nested Transactions
============================================================================
*/

-- Example 3.1: Problem with Nested Transactions
/*
NESTED TRANSACTION PROBLEM:
ROLLBACK in nested transaction rolls back ENTIRE transaction

┌─────────────────────────────────────────┐
│ BEGIN TRANSACTION  -- Outer             │
│   Work A                                │
│   BEGIN TRANSACTION  -- Inner           │
│     Work B                              │
│     ROLLBACK TRANSACTION  ← Oops!       │
│   -- Entire transaction aborted!        │
│   COMMIT  ← ERROR: No active transaction│
└─────────────────────────────────────────┘

Result: Work A AND Work B both rolled back
*/

-- Demonstration
BEGIN TRANSACTION;  -- Outer
    INSERT INTO #Orders VALUES (10, 110, GETDATE(), 100, 'New');
    PRINT 'Outer: Order 10 created';
    
    BEGIN TRANSACTION;  -- Inner
        UPDATE #Orders SET Status = 'Processing' WHERE OrderID = 10;
        PRINT 'Inner: Status updated';
        
        -- This rolls back EVERYTHING!
        ROLLBACK TRANSACTION;
        PRINT 'Inner: Rolled back';
        
    -- Transaction is now aborted, cannot continue!
    -- This will ERROR:
    -- COMMIT TRANSACTION;

-- Check: Order 10 does NOT exist (everything rolled back)
SELECT * FROM #Orders WHERE OrderID = 10;  -- Empty

-- Example 3.2: Solution with Savepoints
/*
SAVEPOINT SOLUTION:
ROLLBACK to savepoint only undoes work after savepoint

┌─────────────────────────────────────────┐
│ BEGIN TRANSACTION                       │
│   Work A                                │
│   SAVE TRANSACTION InnerSavepoint       │
│     Work B                              │
│     ROLLBACK TRANSACTION InnerSavepoint │
│   Work C                                │
│   COMMIT  ← SUCCESS                     │
└─────────────────────────────────────────┘

Result: Work A and C committed, only Work B rolled back
*/

BEGIN TRANSACTION;  -- Outer
    INSERT INTO #Orders VALUES (11, 111, GETDATE(), 100, 'New');
    PRINT 'Outer: Order 11 created';
    
    SAVE TRANSACTION InnerSavepoint;  -- Savepoint instead of BEGIN TRAN
        UPDATE #Orders SET Status = 'Processing' WHERE OrderID = 11;
        PRINT 'Inner: Status updated';
        
        -- Rollback to savepoint (only inner work)
        ROLLBACK TRANSACTION InnerSavepoint;
        PRINT 'Inner: Rolled back to savepoint';
        
    -- Transaction still active, can continue!
    UPDATE #Orders SET Status = 'Confirmed' WHERE OrderID = 11;
    PRINT 'Outer: Continued after savepoint rollback';
    
COMMIT TRANSACTION;  -- SUCCESS!

-- Check: Order 11 exists with Status = 'Confirmed'
SELECT * FROM #Orders WHERE OrderID = 11;

-- Example 3.3: Comparison Table
/*
┌─────────────────────┬────────────────────┬─────────────────────┐
│     Feature         │ Nested Transaction │   Savepoint         │
├─────────────────────┼────────────────────┼─────────────────────┤
│ Syntax              │ BEGIN TRAN         │ SAVE TRAN name      │
│ @@TRANCOUNT         │ Increments         │ No change           │
│ Partial Rollback    │ NO ✗               │ YES ✓               │
│ ROLLBACK Scope      │ All levels         │ To savepoint        │
│ After ROLLBACK      │ Transaction aborted│ Can continue        │
│ COMMIT Required     │ Matching count     │ Only outermost      │
│ Use Case            │ Call stack tracking│ Partial rollback    │
│ Recommended         │ Avoid              │ Use for nested logic│
└─────────────────────┴────────────────────┴─────────────────────┘
*/


/*
============================================================================
PART 4: Error Handling with Savepoints
============================================================================
*/

-- Example 4.1: Try-Catch with Savepoints
CREATE PROCEDURE ProcessOrderWithSavepoints
    @OrderID INT,
    @CustomerID INT,
    @InitialAmount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Step 1: Create order
            INSERT INTO #Orders (OrderID, CustomerID, OrderDate, TotalAmount, Status)
            VALUES (@OrderID, @CustomerID, GETDATE(), @InitialAmount, 'New');
            PRINT 'Step 1: Order created';
            
            SAVE TRANSACTION AfterOrderCreation;
            
            -- Step 2: Apply discount (might fail)
            BEGIN TRY
                UPDATE #Orders 
                SET TotalAmount = TotalAmount * 0.9 
                WHERE OrderID = @OrderID;
                
                -- Simulate validation error
                IF @InitialAmount < 100
                    RAISERROR('Discount requires minimum $100', 16, 1);
                    
                PRINT 'Step 2: Discount applied';
            END TRY
            BEGIN CATCH
                -- Rollback only the discount
                ROLLBACK TRANSACTION AfterOrderCreation;
                PRINT 'Step 2: Discount failed, using original amount';
            END CATCH;
            
            -- Step 3: Confirm order (always executes)
            UPDATE #Orders SET Status = 'Confirmed' WHERE OrderID = @OrderID;
            PRINT 'Step 3: Order confirmed';
            
        COMMIT TRANSACTION;
        PRINT 'Transaction committed successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;

-- Test with amount >= $100 (discount applies)
EXEC ProcessOrderWithSavepoints 20, 120, 200;

-- Test with amount < $100 (discount fails, order still created)
EXEC ProcessOrderWithSavepoints 21, 121, 50;

SELECT * FROM #Orders WHERE OrderID IN (20, 21);

-- Example 4.2: Batch Processing with Savepoints
CREATE PROCEDURE ProcessBatch
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @OrderID INT = 100;
    DECLARE @SavepointName VARCHAR(50);
    
    BEGIN TRANSACTION;
    BEGIN TRY
        
        WHILE @OrderID <= 105
        BEGIN
            -- Create savepoint for this iteration
            SET @SavepointName = 'Batch_' + CAST(@OrderID AS VARCHAR);
            SAVE TRANSACTION @SavepointName;
            
            BEGIN TRY
                -- Process this order
                INSERT INTO #Orders (OrderID, CustomerID, OrderDate, TotalAmount, Status)
                VALUES (@OrderID, @OrderID, GETDATE(), @OrderID * 10, 'New');
                
                -- Simulate random failure
                IF @OrderID % 2 = 1  -- Odd numbers fail
                    RAISERROR('Simulated error for testing', 16, 1);
                
                PRINT 'Order ' + CAST(@OrderID AS VARCHAR) + ' processed successfully';
            END TRY
            BEGIN CATCH
                -- Rollback just this order
                ROLLBACK TRANSACTION @SavepointName;
                PRINT 'Order ' + CAST(@OrderID AS VARCHAR) + ' failed: ' + ERROR_MESSAGE();
            END CATCH;
            
            SET @OrderID = @OrderID + 1;
        END
        
        COMMIT TRANSACTION;
        PRINT 'Batch processing completed';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Batch failed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;

-- Execute batch
EXEC ProcessBatch;

-- Check results: Even numbered orders succeed, odd ones fail
SELECT * FROM #Orders WHERE OrderID BETWEEN 100 AND 105;

-- Example 4.3: Savepoint for Optional Operations
BEGIN TRANSACTION;
    INSERT INTO #Orders VALUES (30, 130, GETDATE(), 500, 'New');
    
    -- Optional operation: Apply VIP discount
    SAVE TRANSACTION BeforeVIPDiscount;
    
    BEGIN TRY
        -- Try to apply VIP discount
        UPDATE #Orders SET TotalAmount = TotalAmount * 0.8 WHERE OrderID = 30;
        
        -- Validate VIP status (simulated check)
        DECLARE @IsVIP BIT = 0;  -- Not VIP
        
        IF @IsVIP = 0
            RAISERROR('Customer is not VIP', 16, 1);
        
        PRINT 'VIP discount applied';
    END TRY
    BEGIN CATCH
        -- Not VIP, rollback discount
        ROLLBACK TRANSACTION BeforeVIPDiscount;
        PRINT 'VIP discount not applicable, using regular price';
    END CATCH;
    
COMMIT TRANSACTION;

SELECT * FROM #Orders WHERE OrderID = 30;  -- Original price


/*
============================================================================
PART 5: Complex Multi-Step Transactions
============================================================================
*/

-- Example 5.1: Multi-Stage Order Processing
CREATE TABLE #OrderSteps (
    OrderID INT,
    StepName VARCHAR(50),
    StepStatus VARCHAR(20),
    CompletedAt DATETIME
);

CREATE PROCEDURE ComplexOrderProcessing
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Stage 1: Create Order
            INSERT INTO #Orders (OrderID, CustomerID, OrderDate, TotalAmount, Status)
            VALUES (@OrderID, 1, GETDATE(), 1000, 'New');
            INSERT INTO #OrderSteps VALUES (@OrderID, 'Create', 'Success', GETDATE());
            SAVE TRANSACTION AfterCreate;
            
            -- Stage 2: Validate Inventory
            BEGIN TRY
                -- Simulate inventory check
                IF @OrderID % 3 = 0
                    RAISERROR('Out of stock', 16, 1);
                    
                INSERT INTO #OrderSteps VALUES (@OrderID, 'Inventory', 'Success', GETDATE());
                SAVE TRANSACTION AfterInventory;
            END TRY
            BEGIN CATCH
                INSERT INTO #OrderSteps VALUES (@OrderID, 'Inventory', 'Failed', GETDATE());
                ROLLBACK TRANSACTION AfterCreate;
                PRINT 'Inventory check failed, order cancelled';
                COMMIT TRANSACTION;
                RETURN;
            END CATCH;
            
            -- Stage 3: Process Payment
            BEGIN TRY
                -- Simulate payment processing
                IF @OrderID % 5 = 0
                    RAISERROR('Payment declined', 16, 1);
                    
                INSERT INTO #OrderSteps VALUES (@OrderID, 'Payment', 'Success', GETDATE());
                SAVE TRANSACTION AfterPayment;
            END TRY
            BEGIN CATCH
                INSERT INTO #OrderSteps VALUES (@OrderID, 'Payment', 'Failed', GETDATE());
                ROLLBACK TRANSACTION AfterInventory;
                PRINT 'Payment failed, inventory released';
                COMMIT TRANSACTION;
                RETURN;
            END CATCH;
            
            -- Stage 4: Finalize Order
            UPDATE #Orders SET Status = 'Completed' WHERE OrderID = @OrderID;
            INSERT INTO #OrderSteps VALUES (@OrderID, 'Finalize', 'Success', GETDATE());
            
        COMMIT TRANSACTION;
        PRINT 'Order ' + CAST(@OrderID AS VARCHAR) + ' completed successfully';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Order processing failed: ' + ERROR_MESSAGE();
    END CATCH;
END;

-- Process multiple orders
EXEC ComplexOrderProcessing 40;  -- Success
EXEC ComplexOrderProcessing 42;  -- Success  
EXEC ComplexOrderProcessing 45;  -- Fails at payment (45 % 5 = 0)

-- View results
SELECT * FROM #Orders WHERE OrderID IN (40, 42, 45);
SELECT * FROM #OrderSteps WHERE OrderID IN (40, 42, 45) ORDER BY OrderID, CompletedAt;


/*
============================================================================
PART 6: Savepoint Limitations and Best Practices
============================================================================
*/

-- Example 6.1: Savepoint Limitations
/*
LIMITATIONS:

1. Not compatible with distributed transactions
   ✗ Cannot use with BEGIN DISTRIBUTED TRANSACTION

2. Savepoint destroyed by:
   • Rollback to earlier savepoint
   • Full rollback
   • Commit

3. Cannot rollback to non-existent savepoint
   ✗ Error if savepoint doesn't exist

4. @@TRANCOUNT not affected
   • SAVE TRANSACTION doesn't increment @@TRANCOUNT
   • Only BEGIN TRANSACTION increments it

5. No savepoint across batches
   • Savepoints don't survive GO statements
   • Must be in same batch as transaction
*/

-- Example 6.2: Savepoint Doesn't Affect @@TRANCOUNT
PRINT 'Initial @@TRANCOUNT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

BEGIN TRANSACTION;
PRINT 'After BEGIN TRAN: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 1

SAVE TRANSACTION SP1;
PRINT 'After SAVE TRAN: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- Still 1!

SAVE TRANSACTION SP2;
PRINT 'After 2nd SAVE: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- Still 1!

COMMIT TRANSACTION;
PRINT 'After COMMIT: ' + CAST(@@TRANCOUNT AS VARCHAR);  -- 0

-- Example 6.3: Best Practices
/*
SAVEPOINT BEST PRACTICES:

1. Use Descriptive Names
   ✓ SAVE TRANSACTION AfterPaymentProcessing
   ✗ SAVE TRANSACTION SP1

2. Document Rollback Points
   -- Savepoint allows rollback of discount without losing order
   SAVE TRANSACTION BeforeOptionalDiscount;

3. Handle Errors at Each Checkpoint
   BEGIN TRY
       -- Work
   END TRY
   BEGIN CATCH
       ROLLBACK TRANSACTION SavepointName;
   END CATCH;

4. Don't Overuse
   • Too many savepoints → Complex code
   • Use for logical checkpoints only

5. Clean Up
   • Savepoints removed on commit
   • No explicit cleanup needed

6. Test Rollback Scenarios
   • Verify data state after rollback
   • Ensure business logic correct
*/

-- Example 6.4: Recommended Pattern
CREATE PROCEDURE SafeSavepointPattern
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SavepointName VARCHAR(50) = 'SP_Order_' + CAST(@OrderID AS VARCHAR);
    
    BEGIN TRY
        -- Must be in a transaction
        IF @@TRANCOUNT = 0
            RAISERROR('Must be called within transaction', 16, 1);
        
        -- Create savepoint
        SAVE TRANSACTION @SavepointName;
        
        -- Do work
        INSERT INTO #Orders (OrderID, CustomerID, OrderDate, TotalAmount, Status)
        VALUES (@OrderID, 1, GETDATE(), 100, 'New');
        
        -- Validation
        IF @OrderID < 0
            RAISERROR('Invalid OrderID', 16, 1);
        
        PRINT 'Order processed successfully';
        
    END TRY
    BEGIN CATCH
        -- Rollback to savepoint
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION @SavepointName;
        
        PRINT 'Error: ' + ERROR_MESSAGE();
        PRINT 'Rolled back to savepoint: ' + @SavepointName;
        
        -- Don't re-throw, allow caller to continue
    END CATCH;
END;

-- Usage
BEGIN TRANSACTION;
    EXEC SafeSavepointPattern 50;  -- Success
    EXEC SafeSavepointPattern -1;  -- Fails, rolls back to savepoint
    EXEC SafeSavepointPattern 51;  -- Success
COMMIT TRANSACTION;

SELECT * FROM #Orders WHERE OrderID IN (50, 51);  -- Both exist


-- Cleanup
DROP TABLE #Orders;
DROP TABLE #OrderSteps;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a procedure using savepoints for multi-step processing
2. Demonstrate the difference between savepoints and nested transactions
3. Implement batch processing with savepoint recovery
4. Build a complex workflow with multiple checkpoint savepoints
5. Create error handling framework using savepoints

Solutions below ↓
*/

-- Solution 1: Multi-Step Processing with Savepoints
CREATE TABLE #Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    Stock INT
);

CREATE TABLE #OrderItems (
    OrderItemID INT PRIMARY KEY IDENTITY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(10,2)
);

INSERT INTO #Products VALUES (1, 'Laptop', 1000, 10);
INSERT INTO #Products VALUES (2, 'Mouse', 25, 50);

CREATE PROCEDURE ProcessOrderWithItems
    @OrderID INT,
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Step 1: Create Order Header
            CREATE TABLE #TempOrders (
                OrderID INT, CustomerID INT, OrderDate DATETIME, 
                TotalAmount DECIMAL(10,2), Status VARCHAR(20)
            );
            
            INSERT INTO #TempOrders VALUES (@OrderID, @CustomerID, GETDATE(), 0, 'New');
            PRINT 'Step 1: Order header created';
            SAVE TRANSACTION AfterHeader;
            
            -- Step 2: Add Item 1
            BEGIN TRY
                DECLARE @ProductID1 INT = 1, @Quantity1 INT = 2;
                
                -- Check stock
                IF (SELECT Stock FROM #Products WHERE ProductID = @ProductID1) < @Quantity1
                    RAISERROR('Insufficient stock for product 1', 16, 1);
                
                INSERT INTO #OrderItems (OrderID, ProductID, Quantity, UnitPrice)
                SELECT @OrderID, @ProductID1, @Quantity1, Price FROM #Products WHERE ProductID = @ProductID1;
                
                UPDATE #Products SET Stock = Stock - @Quantity1 WHERE ProductID = @ProductID1;
                PRINT 'Step 2: Item 1 added';
                SAVE TRANSACTION AfterItem1;
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION AfterHeader;
                PRINT 'Item 1 failed: ' + ERROR_MESSAGE();
                THROW;
            END CATCH;
            
            -- Step 3: Add Item 2 (optional)
            BEGIN TRY
                DECLARE @ProductID2 INT = 2, @Quantity2 INT = 3;
                
                IF (SELECT Stock FROM #Products WHERE ProductID = @ProductID2) < @Quantity2
                    RAISERROR('Insufficient stock for product 2', 16, 1);
                
                INSERT INTO #OrderItems (OrderID, ProductID, Quantity, UnitPrice)
                SELECT @OrderID, @ProductID2, @Quantity2, Price FROM #Products WHERE ProductID = @ProductID2;
                
                UPDATE #Products SET Stock = Stock - @Quantity2 WHERE ProductID = @ProductID2;
                PRINT 'Step 3: Item 2 added';
                SAVE TRANSACTION AfterItem2;
            END TRY
            BEGIN CATCH
                -- Item 2 is optional, just log and continue
                ROLLBACK TRANSACTION AfterItem1;
                PRINT 'Item 2 skipped: ' + ERROR_MESSAGE();
            END CATCH;
            
            -- Step 4: Calculate Total
            UPDATE #TempOrders 
            SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM #OrderItems WHERE OrderID = @OrderID),
                Status = 'Completed'
            WHERE OrderID = @OrderID;
            PRINT 'Step 4: Order finalized';
            
        COMMIT TRANSACTION;
        PRINT 'Order processed successfully';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Order processing failed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH;
END;

-- Test
EXEC ProcessOrderWithItems 1000, 5001;

-- View results
SELECT * FROM #OrderItems WHERE OrderID = 1000;
SELECT * FROM #Products;

-- Solution 2: Savepoints vs Nested Transactions
PRINT '=== NESTED TRANSACTION BEHAVIOR ===';
CREATE TABLE #Test1 (ID INT, Value VARCHAR(50));

BEGIN TRANSACTION;
    INSERT INTO #Test1 VALUES (1, 'Outer A');
    
    BEGIN TRANSACTION;  -- Nested (@@TRANCOUNT = 2)
        INSERT INTO #Test1 VALUES (2, 'Inner B');
        ROLLBACK TRANSACTION;  -- Rolls back EVERYTHING!
    
    -- Transaction aborted, cannot continue
    -- This would error: COMMIT TRANSACTION;

SELECT * FROM #Test1;  -- Empty! Both inserts rolled back

PRINT '';
PRINT '=== SAVEPOINT BEHAVIOR ===';
CREATE TABLE #Test2 (ID INT, Value VARCHAR(50));

BEGIN TRANSACTION;
    INSERT INTO #Test2 VALUES (1, 'Outer A');
    
    SAVE TRANSACTION InnerSavepoint;  -- Savepoint (@@TRANCOUNT still 1)
        INSERT INTO #Test2 VALUES (2, 'Inner B');
        ROLLBACK TRANSACTION InnerSavepoint;  -- Only rolls back to savepoint
    
    -- Can continue!
    INSERT INTO #Test2 VALUES (3, 'Outer C');
    
COMMIT TRANSACTION;  -- Success!

SELECT * FROM #Test2;  -- Contains 1 and 3 (2 was rolled back)

DROP TABLE #Test1;
DROP TABLE #Test2;

-- Solution 3: Batch Processing with Savepoint Recovery
CREATE TABLE #ImportData (
    RecordID INT PRIMARY KEY,
    DataValue VARCHAR(100),
    Status VARCHAR(20)
);

CREATE PROCEDURE ImportBatchWithRecovery
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RecordID INT = 1;
    DECLARE @SavepointName VARCHAR(50);
    DECLARE @SuccessCount INT = 0;
    DECLARE @FailCount INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            WHILE @RecordID <= 10
            BEGIN
                SET @SavepointName = 'Record_' + CAST(@RecordID AS VARCHAR);
                SAVE TRANSACTION @SavepointName;
                
                BEGIN TRY
                    -- Simulate data import
                    INSERT INTO #ImportData (RecordID, DataValue, Status)
                    VALUES (@RecordID, 'Data_' + CAST(@RecordID AS VARCHAR), 'Pending');
                    
                    -- Simulate validation (fails on multiples of 3)
                    IF @RecordID % 3 = 0
                        RAISERROR('Validation failed', 16, 1);
                    
                    UPDATE #ImportData SET Status = 'Success' WHERE RecordID = @RecordID;
                    SET @SuccessCount = @SuccessCount + 1;
                    
                END TRY
                BEGIN CATCH
                    -- Rollback just this record
                    ROLLBACK TRANSACTION @SavepointName;
                    SET @FailCount = @FailCount + 1;
                    PRINT 'Record ' + CAST(@RecordID AS VARCHAR) + ' failed: ' + ERROR_MESSAGE();
                END CATCH;
                
                SET @RecordID = @RecordID + 1;
            END
            
        COMMIT TRANSACTION;
        
        PRINT 'Batch import completed';
        PRINT 'Success: ' + CAST(@SuccessCount AS VARCHAR);
        PRINT 'Failed: ' + CAST(@FailCount AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT 'Batch failed: ' + ERROR_MESSAGE();
    END CATCH;
END;

EXEC ImportBatchWithRecovery;

-- View results (records 3, 6, 9 should be missing)
SELECT * FROM #ImportData ORDER BY RecordID;

-- Solution 4: Complex Workflow with Multiple Checkpoints
CREATE TABLE #WorkflowSteps (
    WorkflowID INT,
    StepNumber INT,
    StepName VARCHAR(50),
    StepStatus VARCHAR(20),
    ExecutedAt DATETIME
);

CREATE PROCEDURE ComplexWorkflow
    @WorkflowID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
            -- Checkpoint 1: Initialize
            INSERT INTO #WorkflowSteps VALUES (@WorkflowID, 1, 'Initialize', 'Running', GETDATE());
            UPDATE #WorkflowSteps SET StepStatus = 'Completed' 
            WHERE WorkflowID = @WorkflowID AND StepNumber = 1;
            SAVE TRANSACTION Checkpoint1;
            
            -- Checkpoint 2: Validate
            INSERT INTO #WorkflowSteps VALUES (@WorkflowID, 2, 'Validate', 'Running', GETDATE());
            BEGIN TRY
                IF @WorkflowID < 0
                    RAISERROR('Invalid workflow ID', 16, 1);
                UPDATE #WorkflowSteps SET StepStatus = 'Completed' 
                WHERE WorkflowID = @WorkflowID AND StepNumber = 2;
                SAVE TRANSACTION Checkpoint2;
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION Checkpoint1;
                THROW;
            END CATCH;
            
            -- Checkpoint 3: Process (optional)
            INSERT INTO #WorkflowSteps VALUES (@WorkflowID, 3, 'Process', 'Running', GETDATE());
            BEGIN TRY
                -- Optional processing
                IF @WorkflowID % 2 = 1
                    RAISERROR('Processing not available', 16, 1);
                UPDATE #WorkflowSteps SET StepStatus = 'Completed' 
                WHERE WorkflowID = @WorkflowID AND StepNumber = 3;
                SAVE TRANSACTION Checkpoint3;
            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION Checkpoint2;
                UPDATE #WorkflowSteps SET StepStatus = 'Skipped' 
                WHERE WorkflowID = @WorkflowID AND StepNumber = 3;
                PRINT 'Step 3 skipped: ' + ERROR_MESSAGE();
            END CATCH;
            
            -- Checkpoint 4: Finalize
            INSERT INTO #WorkflowSteps VALUES (@WorkflowID, 4, 'Finalize', 'Running', GETDATE());
            UPDATE #WorkflowSteps SET StepStatus = 'Completed' 
            WHERE WorkflowID = @WorkflowID AND StepNumber = 4;
            
        COMMIT TRANSACTION;
        PRINT 'Workflow ' + CAST(@WorkflowID AS VARCHAR) + ' completed';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT 'Workflow failed: ' + ERROR_MESSAGE();
    END CATCH;
END;

-- Execute workflows
EXEC ComplexWorkflow 100;  -- Even: All steps complete
EXEC ComplexWorkflow 101;  -- Odd: Step 3 skipped

SELECT * FROM #WorkflowSteps ORDER BY WorkflowID, StepNumber;

-- Solution 5: Error Handling Framework with Savepoints
CREATE PROCEDURE ErrorHandlingFramework
    @OperationName VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SavepointName VARCHAR(100) = 'SP_' + @OperationName;
    DECLARE @InTransaction BIT = 0;
    
    -- Check if we're in a transaction
    IF @@TRANCOUNT > 0
    BEGIN
        SET @InTransaction = 1;
        SAVE TRANSACTION @SavepointName;
        PRINT 'Savepoint created: ' + @SavepointName;
    END
    ELSE
    BEGIN
        BEGIN TRANSACTION;
        PRINT 'Transaction started for: ' + @OperationName;
    END
    
    BEGIN TRY
        -- Simulate work
        PRINT 'Executing: ' + @OperationName;
        
        -- Simulate random error
        IF RAND() > 0.5
            RAISERROR('Simulated error in operation', 16, 1);
        
        -- Success
        IF @InTransaction = 0
        BEGIN
            COMMIT TRANSACTION;
            PRINT 'Transaction committed: ' + @OperationName;
        END
        ELSE
        BEGIN
            PRINT 'Work completed: ' + @OperationName;
        END
        
    END TRY
    BEGIN CATCH
        -- Handle error based on transaction state
        IF @InTransaction = 1
        BEGIN
            -- We're part of larger transaction, rollback to savepoint
            IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRANSACTION @SavepointName;
                PRINT 'Rolled back to savepoint: ' + @SavepointName;
            END
        END
        ELSE
        BEGIN
            -- We started the transaction, rollback completely
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
                PRINT 'Transaction rolled back: ' + @OperationName;
            END
        END
        
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        
        -- Don't re-throw if we used savepoint (let caller continue)
        IF @InTransaction = 0
            THROW;
    END CATCH;
END;

-- Test standalone
EXEC ErrorHandlingFramework 'StandaloneOperation';

-- Test within transaction
BEGIN TRANSACTION;
    EXEC ErrorHandlingFramework 'Operation1';
    EXEC ErrorHandlingFramework 'Operation2';
    EXEC ErrorHandlingFramework 'Operation3';
COMMIT TRANSACTION;

-- Cleanup
DROP TABLE #Products;
DROP TABLE #OrderItems;
DROP TABLE #ImportData;
DROP TABLE #WorkflowSteps;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SAVEPOINTS:
  • Markers for partial rollback
  • Syntax: SAVE TRANSACTION name
  • Allow rollback to specific point
  • Don't affect @@TRANCOUNT

✓ ROLLBACK TO SAVEPOINT:
  • Syntax: ROLLBACK TRANSACTION savepoint_name
  • Only undoes work after savepoint
  • Transaction remains active
  • Can continue after rollback

✓ MULTIPLE SAVEPOINTS:
  • Stack-based behavior
  • Rolling back destroys later savepoints
  • Can reuse savepoint names
  • Latest name takes precedence

✓ VS NESTED TRANSACTIONS:
  • Savepoints: Partial rollback ✓
  • Nested: Full rollback only ✗
  • Savepoints: Transaction continues ✓
  • Nested: Transaction aborted ✗

✓ ERROR HANDLING:
  • Use with TRY...CATCH
  • Rollback to savepoint on error
  • Continue processing
  • Ideal for batch operations

✓ USE CASES:
  • Multi-step transactions
  • Batch processing
  • Optional operations
  • Error recovery
  • Complex workflows

✓ LIMITATIONS:
  • No distributed transactions
  • Destroyed by commit/rollback
  • Same batch only
  • No effect on @@TRANCOUNT

✓ BEST PRACTICES:
  • Use descriptive names
  • Document rollback points
  • Handle errors at checkpoints
  • Don't overuse
  • Test rollback scenarios
  • Keep transaction logic clear

============================================================================
NEXT: Lesson 12.08 - Test Your Knowledge
Comprehensive assessment of transaction concepts.
============================================================================
*/
