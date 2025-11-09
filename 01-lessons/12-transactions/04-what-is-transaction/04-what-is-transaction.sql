/*
============================================================================
Lesson 12.04 - What is a Transaction
============================================================================

Description:
Master the fundamentals of database transactions. Learn ACID properties,
transaction boundaries, transaction states, and the transaction log. 
Understand how transactions ensure data integrity and consistency in 
multi-user environments.

Topics Covered:
• What is a transaction
• ACID properties (Atomicity, Consistency, Isolation, Durability)
• Transaction boundaries
• Transaction states and lifecycle
• Transaction log
• Write-ahead logging
• Auto-commit vs explicit transactions

Prerequisites:
• Lesson 12.01 (Multi-user Databases)
• Lesson 12.02 (Locking)

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: What is a Transaction?
============================================================================
*/

-- Example 1.1: Transaction Definition
/*
TRANSACTION:
A logical unit of work that contains one or more SQL statements.
All statements in a transaction either:
• ALL succeed (COMMIT), or
• ALL fail (ROLLBACK)

ANALOGY: ATM Withdrawal
┌──────────────────────────────────────────────────────────┐
│ Transaction: Withdraw $100                               │
├──────────────────────────────────────────────────────────┤
│ Step 1: Check balance >= $100        ✓                  │
│ Step 2: Deduct $100 from account     ✓                  │
│ Step 3: Dispense $100 cash            ✗ (machine empty) │
├──────────────────────────────────────────────────────────┤
│ Result: ROLLBACK entire transaction                     │
│         (Money NOT deducted from account)               │
└──────────────────────────────────────────────────────────┘

If Step 3 fails, Step 2 MUST be undone!
This is what transactions guarantee.
*/

-- Example 1.2: Transaction Example
CREATE TABLE #Account (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(100),
    Balance DECIMAL(10,2)
);

INSERT INTO #Account VALUES
(1, 'Alice', 1000),
(2, 'Bob', 500);

-- Without transaction (DANGEROUS!)
UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
-- What if crash happens here? ←←← PROBLEM!
UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;

-- With transaction (SAFE!)
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
    -- If crash happens here, BOTH updates rolled back automatically
    UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;
COMMIT TRANSACTION;

SELECT * FROM #Account;

-- Example 1.3: Why Transactions Matter
/*
WITHOUT TRANSACTIONS:
┌─────────────────────────────────────────┐
│ Transfer $100: Account A → Account B   │
├─────────────────────────────────────────┤
│ Deduct $100 from A        ✓ (completed)│
│ System crash!             ✗            │
│ Add $100 to B             ✗ (not done) │
└─────────────────────────────────────────┘
Result: $100 vanished! 💸

WITH TRANSACTIONS:
┌─────────────────────────────────────────┐
│ BEGIN TRANSACTION                       │
│   Deduct $100 from A      ✓ (pending)  │
│   System crash!           ✗            │
│   Add $100 to B           ✗ (not done) │
│ AUTOMATIC ROLLBACK                      │
└─────────────────────────────────────────┘
Result: Both accounts unchanged ✓

TRANSACTION GUARANTEES:
• All-or-nothing execution
• Data consistency
• Crash recovery
• Concurrency control
*/


/*
============================================================================
PART 2: ACID Properties - Atomicity
============================================================================
*/

-- Example 2.1: Atomicity Explained
/*
ATOMICITY:
"All or nothing" - transaction is indivisible unit

┌─────────────────────────────────────────────────────────┐
│  ATOMIC TRANSACTION (cannot be split)                   │
├─────────────────────────────────────────────────────────┤
│  BEGIN TRANSACTION                                      │
│    Statement 1  ─┐                                      │
│    Statement 2   │  All must succeed                   │
│    Statement 3   ├─ or all must fail                   │
│    Statement 4   │                                      │
│    Statement 5  ─┘                                      │
│  COMMIT or ROLLBACK                                     │
└─────────────────────────────────────────────────────────┘

CANNOT have: Statement 1, 2 succeed but 3, 4, 5 fail
MUST have: All succeed OR all fail
*/

-- Example 2.2: Atomicity in Action
BEGIN TRANSACTION;
    -- Order processing (all steps must succeed)
    INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
    VALUES (1, GETDATE(), 250.00);
    
    DECLARE @OrderID INT = SCOPE_IDENTITY();
    
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
    VALUES (@OrderID, 101, 2, 100.00);
    
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
    VALUES (@OrderID, 102, 1, 50.00);
    
    UPDATE Products SET StockQuantity = StockQuantity - 2 WHERE ProductID = 101;
    UPDATE Products SET StockQuantity = StockQuantity - 1 WHERE ProductID = 102;
    
    -- All statements succeed or all fail together
COMMIT TRANSACTION;

-- Example 2.3: Atomicity Violation (Without Transaction)
/*
WITHOUT TRANSACTION:
*/
-- Step 1: Create order
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
VALUES (1, GETDATE(), 250.00);

DECLARE @OrderID INT = SCOPE_IDENTITY();

-- Step 2: Add order details
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
VALUES (@OrderID, 101, 2, 100.00);

-- CRASH HERE! ← System fails

-- Step 3: Never executed
UPDATE Products SET StockQuantity = StockQuantity - 2 WHERE ProductID = 101;
/*
RESULT: Order exists but inventory not updated! 😱
This violates atomicity.
*/


/*
============================================================================
PART 3: ACID Properties - Consistency
============================================================================
*/

-- Example 3.1: Consistency Explained
/*
CONSISTENCY:
Database must move from one valid state to another valid state
All integrity constraints must be satisfied

┌─────────────────────────────────────────────────────────┐
│  VALID STATE (Before Transaction)                       │
│  • All constraints satisfied                            │
│  • All business rules enforced                          │
│  • Data relationships intact                            │
└─────────────────────────────────────────────────────────┘
                          ↓
          ┌─────────────────────────────┐
          │     TRANSACTION             │
          └─────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  VALID STATE (After Transaction)                        │
│  • All constraints still satisfied                      │
│  • All business rules still enforced                    │
│  • Data relationships still intact                      │
└─────────────────────────────────────────────────────────┘

NEVER allowed in INVALID STATE
*/

-- Example 3.2: Consistency Enforcement
CREATE TABLE #BankAccount (
    AccountID INT PRIMARY KEY,
    Balance DECIMAL(10,2) CHECK (Balance >= 0)  -- Constraint
);

INSERT INTO #BankAccount VALUES (1, 500);

-- This transaction maintains consistency
BEGIN TRANSACTION;
    UPDATE #BankAccount 
    SET Balance = Balance - 100 
    WHERE AccountID = 1;
    -- Balance = 400 (valid, >= 0)
COMMIT;

-- This transaction violates consistency
BEGIN TRANSACTION;
    UPDATE #BankAccount 
    SET Balance = Balance - 600  -- Would make balance = -100
    WHERE AccountID = 1;
    -- ERROR: CHECK constraint violation
ROLLBACK;  -- Automatic rollback preserves consistency

SELECT * FROM #BankAccount;  -- Still 400 (consistent state)

-- Example 3.3: Business Rule Consistency
-- Business rule: Total order amount must equal sum of order details

CREATE TABLE #OrderHeader (
    OrderID INT PRIMARY KEY,
    TotalAmount DECIMAL(10,2)
);

CREATE TABLE #OrderLines (
    OrderLineID INT PRIMARY KEY,
    OrderID INT,
    Amount DECIMAL(10,2)
);

-- Correct transaction (maintains consistency)
BEGIN TRANSACTION;
    INSERT INTO #OrderHeader VALUES (1, 150.00);
    INSERT INTO #OrderLines VALUES (1, 1, 100.00);
    INSERT INTO #OrderLines VALUES (2, 1, 50.00);
    -- 100 + 50 = 150 ✓ Consistent!
COMMIT;

-- Incorrect transaction (violates consistency)
BEGIN TRANSACTION;
    INSERT INTO #OrderHeader VALUES (2, 200.00);
    INSERT INTO #OrderLines VALUES (3, 2, 100.00);
    -- Only 100 but header says 200 ✗ Inconsistent!
    
    -- Should validate before commit
    IF (SELECT SUM(Amount) FROM #OrderLines WHERE OrderID = 2) 
       != (SELECT TotalAmount FROM #OrderHeader WHERE OrderID = 2)
    BEGIN
        PRINT 'Consistency violation detected!';
        ROLLBACK;  -- Maintain consistency
    END
    ELSE
        COMMIT;

SELECT * FROM #OrderHeader;
SELECT * FROM #OrderLines;


/*
============================================================================
PART 4: ACID Properties - Isolation
============================================================================
*/

-- Example 4.1: Isolation Explained
/*
ISOLATION:
Concurrent transactions execute as if they are alone
Each transaction isolated from effects of other transactions

WITHOUT ISOLATION:
┌─────────────────────────────────────────────────────────┐
│ User A: Read balance = $1000                            │
│ User B: Read balance = $1000                            │
│ User A: Withdraw $100 → Balance = $900                  │
│ User B: Withdraw $200 → Balance = $800 (should be $700!)│
└─────────────────────────────────────────────────────────┘
Lost update problem! 😱

WITH ISOLATION:
┌─────────────────────────────────────────────────────────┐
│ User A: BEGIN TRANSACTION                               │
│         Read balance = $1000                            │
│ User B: BEGIN TRANSACTION (must wait for A's lock)     │
│ User A: Withdraw $100 → Balance = $900                  │
│         COMMIT                                          │
│ User B: Read balance = $900 (sees A's changes)         │
│         Withdraw $200 → Balance = $700 ✓ Correct!      │
│         COMMIT                                          │
└─────────────────────────────────────────────────────────┘
*/

-- Example 4.2: Isolation Levels Demo
-- Session 1:
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = 999 WHERE AccountID = 1;
    WAITFOR DELAY '00:00:05';  -- Simulate long transaction
COMMIT;

-- Session 2 (different window) tries to read:
-- With READ UNCOMMITTED: Sees 999 (dirty read)
-- With READ COMMITTED: Waits, then sees committed value
-- With REPEATABLE READ: Waits, reads stay consistent
-- With SERIALIZABLE: Full isolation

-- Example 4.3: Isolation Importance
/*
ISOLATION PREVENTS:
• Lost Updates: Two transactions overwriting each other
• Dirty Reads: Reading uncommitted data
• Non-repeatable Reads: Same query returns different results
• Phantom Reads: New rows appear mid-transaction

ISOLATION ENSURES:
✓ Predictable behavior
✓ Data integrity
✓ Concurrent access safety
✓ Business logic correctness
*/


/*
============================================================================
PART 5: ACID Properties - Durability
============================================================================
*/

-- Example 5.1: Durability Explained
/*
DURABILITY:
Once transaction commits, changes are PERMANENT
Survive system crashes, power failures, etc.

┌─────────────────────────────────────────────────────────┐
│  User: BEGIN TRANSACTION                                │
│        INSERT INTO Orders VALUES (...)                  │
│        COMMIT  ← Transaction commits successfully       │
│                                                          │
│  ⚡ POWER FAILURE! (1 second later)                     │
│                                                          │
│  System Restart:                                        │
│        Orders table contains the inserted row ✓         │
│        (Data survived the crash)                        │
└─────────────────────────────────────────────────────────┘

GUARANTEE: Committed data never lost
*/

-- Example 5.2: How Durability Works
/*
WRITE-AHEAD LOGGING (WAL):

Step 1: Changes written to TRANSACTION LOG first
┌─────────────────────────────────────┐
│ Transaction Log (on disk)           │
│ [BEGIN TRAN]                        │
│ [INSERT Order ID=123]               │
│ [UPDATE Inventory -5]               │
│ [COMMIT]  ← Flushed to disk        │
└─────────────────────────────────────┘

Step 2: Changes written to DATA FILES (can be delayed)
┌─────────────────────────────────────┐
│ Data Files (on disk)                │
│ Orders Table                        │
│ Inventory Table                     │
└─────────────────────────────────────┘

If crash occurs after COMMIT but before data files updated:
→ SQL Server replays transaction log on restart
→ Changes recovered automatically
→ Durability guaranteed! ✓
*/

-- Example 5.3: Transaction Log
-- View transaction log activity
SELECT 
    [Current LSN],
    Operation,
    [Transaction ID],
    AllocUnitName
FROM fn_dblog(NULL, NULL)
WHERE Operation IN ('LOP_BEGIN_XACT', 'LOP_COMMIT_XACT', 'LOP_INSERT_ROWS');

-- Example 5.4: Durability Demonstration
BEGIN TRANSACTION;
    INSERT INTO #Account VALUES (999, 'Test Durability', 5000);
    -- At this point: Change in log but maybe not in data file
    
    COMMIT;  -- This ensures log flushed to disk
    -- Now: Change is DURABLE (survives crash)
    
    -- Even if server crashes now, data is safe!
SELECT * FROM #Account WHERE AccountID = 999;


/*
============================================================================
PART 6: Transaction States and Lifecycle
============================================================================
*/

-- Example 6.1: Transaction States
/*
TRANSACTION LIFECYCLE:

    ┌──────────┐
    │  ACTIVE  │ ← Transaction executing
    └─────┬────┘
          │
     ┌────┴─────┐
     │          │
┌────▼─────┐ ┌─▼────────┐
│ FAILED   │ │ COMMITTED│
└────┬─────┘ └─┬────────┘
     │         │
┌────▼─────┐ ┌─▼────────┐
│ ABORTED  │ │ COMMITTED│
└──────────┘ └──────────┘

States:
1. ACTIVE: Transaction executing
2. PARTIALLY COMMITTED: After last statement, before commit
3. COMMITTED: Transaction successfully completed
4. FAILED: Normal execution can't proceed
5. ABORTED: Transaction rolled back, database restored

HAPPY PATH: ACTIVE → PARTIALLY COMMITTED → COMMITTED
ERROR PATH: ACTIVE → FAILED → ABORTED
*/

-- Example 6.2: Observing Transaction States
BEGIN TRANSACTION;  -- State: ACTIVE
    INSERT INTO #Account VALUES (3, 'Carol', 1500);
    UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 1;
    DELETE FROM #Account WHERE AccountID = 999;
    
    -- Check transaction state
    SELECT 
        transaction_id,
        transaction_state,
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
        END AS state_description
    FROM sys.dm_tran_session_transactions
    WHERE session_id = @@SPID;
    
COMMIT;  -- State: COMMITTED

-- Example 6.3: Transaction Failure
BEGIN TRANSACTION;  -- State: ACTIVE
    BEGIN TRY
        INSERT INTO #Account VALUES (4, 'David', 2000);
        
        -- This will fail (negative balance constraint)
        UPDATE #Account SET Balance = -1000 WHERE AccountID = 1;
        
        COMMIT;  -- Never reached
    END TRY
    BEGIN CATCH
        -- State: FAILED → ABORTED
        PRINT 'Transaction failed: ' + ERROR_MESSAGE();
        ROLLBACK;  -- Explicit rollback
        -- State: ABORTED
    END CATCH;


/*
============================================================================
PART 7: Auto-commit vs Explicit Transactions
============================================================================
*/

-- Example 7.1: Auto-commit Mode (Default)
/*
AUTO-COMMIT:
Each individual statement is a transaction

Statement 1;  -- BEGIN TRAN → Execute → COMMIT automatically
Statement 2;  -- BEGIN TRAN → Execute → COMMIT automatically
Statement 3;  -- BEGIN TRAN → Execute → COMMIT automatically
*/

-- Each statement auto-commits
UPDATE #Account SET Balance = Balance + 10 WHERE AccountID = 1;
-- Automatically committed

UPDATE #Account SET Balance = Balance + 10 WHERE AccountID = 2;
-- Automatically committed

-- Example 7.2: Explicit Transactions
/*
EXPLICIT TRANSACTION:
You control BEGIN and COMMIT/ROLLBACK
*/

BEGIN TRANSACTION;  -- Manual start
    UPDATE #Account SET Balance = Balance + 10 WHERE AccountID = 1;
    -- Not committed yet
    
    UPDATE #Account SET Balance = Balance + 10 WHERE AccountID = 2;
    -- Still not committed
    
    -- Both statements together
COMMIT TRANSACTION;  -- Manual commit

-- Example 7.3: Auto-commit Problems
-- Problem: Partial completion
UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
-- ← Committed!

-- Crash here! 

UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;
-- ← Never executes

-- Result: Money lost! (First update committed, second never ran)

-- Example 7.4: Explicit Transaction Solution
BEGIN TRANSACTION;
    UPDATE #Account SET Balance = Balance - 100 WHERE AccountID = 1;
    -- Not committed yet
    
    -- Crash here!
    
    UPDATE #Account SET Balance = Balance + 100 WHERE AccountID = 2;
    -- Never executes
    
COMMIT;  -- Never reached

-- Result: Automatic rollback! Both updates undone. Data safe! ✓

-- Example 7.5: When to Use Each
/*
USE AUTO-COMMIT:
✓ Single statement operations
✓ Independent operations
✓ Simple queries
Example: UPDATE Products SET Price = 10 WHERE ID = 1;

USE EXPLICIT TRANSACTIONS:
✓ Multiple related statements
✓ Need all-or-nothing guarantee
✓ Complex business logic
Example: Transfer money between accounts

BEST PRACTICE:
When in doubt, use explicit transactions!
*/


/*
============================================================================
PART 8: Transaction Log Deep Dive
============================================================================
*/

-- Example 8.1: Transaction Log Purpose
/*
TRANSACTION LOG:
Sequential record of all transactions

┌─────────────────────────────────────────────────────────┐
│ Transaction Log                                          │
├─────────────────────────────────────────────────────────┤
│ LSN 100: BEGIN TRANSACTION                              │
│ LSN 101: INSERT Orders (OrderID=1)                      │
│ LSN 102: UPDATE Inventory (ProductID=5, Qty=-2)         │
│ LSN 103: COMMIT TRANSACTION                             │
│ LSN 104: BEGIN TRANSACTION                              │
│ LSN 105: DELETE Order (OrderID=99)                      │
│ LSN 106: ROLLBACK TRANSACTION                           │
└─────────────────────────────────────────────────────────┘

LSN = Log Sequence Number (unique, increasing)

USES:
1. Crash recovery (REDO/UNDO)
2. Point-in-time restore
3. Transaction replication
4. Audit trail
*/

-- Example 8.2: Viewing Transaction Log
-- Current transaction log info
SELECT 
    name,
    physical_name,
    (size * 8 / 1024) AS size_mb,
    (FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024) AS used_mb
FROM sys.database_files
WHERE type_desc = 'LOG';

-- Example 8.3: Write-Ahead Logging
/*
WAL PROTOCOL:

1. Change made in memory (buffer pool)
   ┌────────────────┐
   │ Buffer Pool    │ (RAM)
   │ [Modified]     │
   └────────────────┘

2. Log record written to log file
   ┌────────────────┐
   │ Transaction    │ (Disk)
   │ Log [Written]  │ ← FIRST
   └────────────────┘

3. Data page written to data file (later)
   ┌────────────────┐
   │ Data File      │ (Disk)
   │ [Written]      │ ← SECOND
   └────────────────┘

RULE: Log written BEFORE data
This enables recovery!
*/

-- Cleanup
DROP TABLE #Account;
DROP TABLE #OrderHeader;
DROP TABLE #OrderLines;
DROP TABLE #BankAccount;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Explain all four ACID properties with examples
2. Describe the transaction lifecycle and state transitions
3. Compare auto-commit vs explicit transactions
4. Explain how write-ahead logging ensures durability
5. Create a transaction that demonstrates all ACID properties

Solutions below ↓
*/

-- Solution 1: ACID Properties Explained
/*
A - ATOMICITY: All or Nothing
Example: Money transfer
*/
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 500 WHERE AccountID = 1;
    UPDATE Accounts SET Balance = Balance + 500 WHERE AccountID = 2;
    -- Both updates succeed or both fail (no partial transfer)
COMMIT;
/*

C - CONSISTENCY: Valid State → Valid State
Example: Enforce balance >= 0
*/
ALTER TABLE Accounts ADD CONSTRAINT CK_Balance CHECK (Balance >= 0);
-- Transaction cannot violate this constraint
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = -100 WHERE AccountID = 1;
    -- ERROR: Constraint violation
ROLLBACK;
/*

I - ISOLATION: Transactions don't interfere
Example: Two users updating same account
*/
-- User A:
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
    -- User B must wait (isolation)
COMMIT;

-- User B: (waits for A to complete)
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance + 50 WHERE AccountID = 1;
COMMIT;
/*

D - DURABILITY: Committed changes persist
Example: Survives system crash
*/
BEGIN TRANSACTION;
    INSERT INTO Orders VALUES (123, GETDATE(), 500);
COMMIT;  -- Written to transaction log (durable storage)
-- Even if system crashes now, order 123 is safe!
/*
*/

-- Solution 2: Transaction Lifecycle
/*
TRANSACTION STATE DIAGRAM:

START
  ↓
┌─────────────┐
│   ACTIVE    │ ← Executing statements
└──────┬──────┘
       │
  Statements
  executing...
       │
       ├─────────────┐
       │             │
    Success        Error
       │             │
┌──────▼──────┐ ┌───▼──────┐
│  PARTIALLY  │ │  FAILED  │
│  COMMITTED  │ └───┬──────┘
└──────┬──────┘     │
       │        Rollback
    COMMIT          │
       │       ┌────▼─────┐
┌──────▼──────┐│  ABORTED │
│  COMMITTED  │└──────────┘
└─────────────┘

Example flow:
*/
BEGIN TRANSACTION;              -- State: ACTIVE
    INSERT INTO Orders...;      -- State: ACTIVE
    UPDATE Inventory...;        -- State: ACTIVE
    -- All statements done      State: PARTIALLY COMMITTED
COMMIT;                         -- State: COMMITTED

-- Error flow:
BEGIN TRANSACTION;              -- State: ACTIVE
    INSERT INTO Orders...;      -- State: ACTIVE
    UPDATE Invalid...;          -- State: FAILED (error!)
ROLLBACK;                       -- State: ABORTED
/*
*/

-- Solution 3: Auto-commit vs Explicit
/*
AUTO-COMMIT MODE:

Characteristics:
• Default mode in SQL Server
• Each statement is its own transaction
• Automatic COMMIT after each statement
• Cannot roll back previous statements

Example:
*/
UPDATE Products SET Price = 10 WHERE ID = 1;  -- Auto-commits
UPDATE Products SET Price = 20 WHERE ID = 2;  -- Auto-commits
-- Cannot rollback first update!
/*

EXPLICIT TRANSACTION MODE:

Characteristics:
• Manual control with BEGIN TRANSACTION
• Multiple statements in one transaction
• Can COMMIT or ROLLBACK all together
• Recommended for complex operations

Example:
*/
BEGIN TRANSACTION;
    UPDATE Products SET Price = 10 WHERE ID = 1;
    UPDATE Products SET Price = 20 WHERE ID = 2;
    -- Can rollback BOTH updates if needed
    IF @@ERROR <> 0
        ROLLBACK;
    ELSE
        COMMIT;
/*

WHEN TO USE EACH:

Auto-commit:
✓ Single, independent operations
✓ Simple SELECT queries
✓ One-off updates
Example: UPDATE Settings SET Theme = 'Dark';

Explicit transactions:
✓ Multiple related changes
✓ Need atomicity guarantee
✓ Complex business operations
Example: Process order (create order, update inventory, charge payment)
*/

-- Solution 4: Write-Ahead Logging (WAL)
/*
HOW WAL ENSURES DURABILITY:

STEP-BY-STEP PROCESS:

1. User issues UPDATE
   ┌─────────────────────────────────────┐
   │ UPDATE Accounts                     │
   │ SET Balance = 1000                  │
   │ WHERE ID = 1                        │
   └─────────────────────────────────────┘

2. SQL Server modifies data page in MEMORY
   ┌─────────────────────────────────────┐
   │ Buffer Pool (RAM)                   │
   │ ┌─────────────────────────────────┐ │
   │ │ Page 123                        │ │
   │ │ AccountID=1, Balance=1000       │ │
   │ │ [Dirty = Modified]              │ │
   │ └─────────────────────────────────┘ │
   └─────────────────────────────────────┘

3. Log record written to LOG FILE (DISK) FIRST
   ┌─────────────────────────────────────┐
   │ Transaction Log (DISK)              │
   │ LSN 500: BEGIN TRAN                 │
   │ LSN 501: UPDATE Accounts ID=1      │ ← Written
   │          Old=500, New=1000          │
   │ LSN 502: COMMIT TRAN                │ ← Flushed to disk
   └─────────────────────────────────────┘

4. COMMIT returns to user
   User sees: "Command completed successfully"

5. Later (checkpoint), dirty page written to DATA FILE
   ┌─────────────────────────────────────┐
   │ Data File (DISK)                    │
   │ Accounts Table                      │
   │ ID=1, Balance=1000                  │ ← Written later
   └─────────────────────────────────────┘

CRASH SCENARIO:

If crash occurs after step 3 (log written) but before step 5 (data written):

Recovery Process:
1. SQL Server reads transaction log
2. Finds: LSN 502 (COMMIT) for transaction
3. Checks: Data file has old value (500)
4. Action: REDOs the update (applies 1000)
5. Result: Data recovered! ✓

KEY INSIGHT:
• Log on disk = Committed = Durable
• Data page can be written later
• Log enables reconstruction

This is why it's called "Write-Ahead" Logging:
Log must be written BEFORE data!
*/

-- Solution 5: Complete ACID Transaction
CREATE TABLE #BankAccounts (
    AccountID INT PRIMARY KEY,
    AccountHolder VARCHAR(100),
    Balance DECIMAL(10,2) CHECK (Balance >= 0),  -- Consistency rule
    LastModified DATETIME DEFAULT GETDATE()
);

INSERT INTO #BankAccounts VALUES
(101, 'Alice', 1000, GETDATE()),
(102, 'Bob', 500, GETDATE());

-- Transaction demonstrating ALL ACID properties
BEGIN TRANSACTION;  -- Start explicit transaction
BEGIN TRY
    -- ATOMICITY: Both updates or neither
    -- Transfer $300 from Alice to Bob
    
    UPDATE #BankAccounts 
    SET Balance = Balance - 300,
        LastModified = GETDATE()
    WHERE AccountID = 101;
    
    -- CONSISTENCY: Check constraint ensures Balance >= 0
    -- If Alice had only $200, this transaction would fail
    
    -- ISOLATION: Other transactions cannot see uncommitted balance
    -- Bob's balance doesn't change until COMMIT
    
    UPDATE #BankAccounts 
    SET Balance = Balance + 300,
        LastModified = GETDATE()
    WHERE AccountID = 102;
    
    -- Verify consistency (business rule)
    DECLARE @AliceBalance DECIMAL(10,2);
    SELECT @AliceBalance = Balance FROM #BankAccounts WHERE AccountID = 101;
    
    IF @AliceBalance < 0
    BEGIN
        RAISERROR('Consistency violation: Negative balance!', 16, 1);
    END
    
    -- All checks passed
    COMMIT TRANSACTION;  -- DURABILITY: Changes are permanent
    
    PRINT 'Transfer successful!';
    PRINT 'ACID properties demonstrated:';
    PRINT '  A - Atomicity: Both updates applied together';
    PRINT '  C - Consistency: Balance >= 0 enforced';
    PRINT '  I - Isolation: Changes not visible until commit';
    PRINT '  D - Durability: Committed changes survive crash';
    
END TRY
BEGIN CATCH
    -- ATOMICITY: On error, rollback everything
    ROLLBACK TRANSACTION;
    
    PRINT 'Transfer failed: ' + ERROR_MESSAGE();
    PRINT 'ATOMICITY: All changes rolled back';
END CATCH;

-- Verify final state
SELECT 
    AccountID,
    AccountHolder,
    Balance,
    LastModified
FROM #BankAccounts;
-- Alice: $700, Bob: $800 (transfer completed)

DROP TABLE #BankAccounts;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ TRANSACTION DEFINITION:
  • Logical unit of work
  • All-or-nothing execution
  • Ensures data integrity
  • Essential for multi-user systems

✓ ACID PROPERTIES:
  • Atomicity: All or nothing
  • Consistency: Valid state to valid state
  • Isolation: Concurrent transactions don't interfere
  • Durability: Committed changes persist

✓ ATOMICITY:
  • Indivisible unit
  • All statements succeed or all fail
  • No partial execution
  • Rollback on error

✓ CONSISTENCY:
  • Maintains database rules
  • Enforces constraints
  • Preserves relationships
  • Valid before and after

✓ ISOLATION:
  • Prevents interference
  • Controlled by isolation levels
  • Uses locking
  • Ensures predictable behavior

✓ DURABILITY:
  • Committed = permanent
  • Survives crashes
  • Write-ahead logging
  • Transaction log crucial

✓ TRANSACTION STATES:
  • Active: Executing
  • Partially Committed: Ready to commit
  • Committed: Successfully completed
  • Failed: Error occurred
  • Aborted: Rolled back

✓ AUTO-COMMIT vs EXPLICIT:
  • Auto: Each statement separate transaction
  • Explicit: Manual control
  • Use explicit for complex operations
  • Better control and safety

✓ TRANSACTION LOG:
  • Records all changes
  • Sequential LSN
  • Enables recovery
  • Write-ahead logging
  • Critical for durability

✓ BEST PRACTICES:
  • Use explicit transactions for complex operations
  • Keep transactions short
  • Handle errors properly
  • Verify constraints
  • Test crash recovery

============================================================================
NEXT: Lesson 12.05 - Starting Transactions
Learn how to properly start and configure transactions.
============================================================================
*/
