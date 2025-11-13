-- ========================================
-- Isolation Levels
-- Demonstrating READ UNCOMMITTED, READ COMMITTED,
-- REPEATABLE READ, SERIALIZABLE, SNAPSHOT
-- ========================================

USE TechStore;
GO

-- =============================================
-- Setup: Enable Snapshot Isolation
-- =============================================

-- Required for SNAPSHOT isolation level
ALTER DATABASE TechStore 
SET ALLOW_SNAPSHOT_ISOLATION ON;

ALTER DATABASE TechStore 
SET READ_COMMITTED_SNAPSHOT OFF;  -- Use traditional locking-based READ COMMITTED
GO

-- =============================================
-- Example 1: READ UNCOMMITTED (Dirty Reads)
-- =============================================

-- SESSION 1 (Run this first):
-- Start transaction but don't commit
BEGIN TRANSACTION;
    UPDATE Products SET Price = 9999 WHERE ProductID = 1;
    -- Don't commit yet! Price = 9999 is uncommitted
    WAITFOR DELAY '00:00:10';  -- Hold lock for 10 seconds
ROLLBACK TRANSACTION;  -- Rollback the change
GO

-- SESSION 2 (Run while Session 1 is waiting):
-- Read uncommitted data (DIRTY READ)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT ProductID, ProductName, Price 
FROM Products 
WHERE ProductID = 1;
-- Shows Price = 9999 even though it's not committed!
-- This is a DIRTY READ - reading uncommitted data

-- Reset isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- =============================================
-- Example 2: READ COMMITTED (Default - No Dirty Reads)
-- =============================================

-- SESSION 1:
BEGIN TRANSACTION;
    UPDATE Products SET Price = 9999 WHERE ProductID = 1;
    WAITFOR DELAY '00:00:10';
ROLLBACK TRANSACTION;
GO

-- SESSION 2 (Run while Session 1 is waiting):
-- Wait for commit (NO DIRTY READ)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;  -- SQL Server default
SELECT ProductID, ProductName, Price 
FROM Products 
WHERE ProductID = 1;
-- BLOCKS until Session 1 commits or rolls back
-- Never sees Price = 9999 (the uncommitted value)
GO

-- =============================================
-- Example 3: Non-Repeatable Reads (READ COMMITTED)
-- =============================================

-- SESSION 1:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

    -- First read
    SELECT ProductID, ProductName, Price 
    FROM Products 
    WHERE ProductID = 1;
    -- Shows Price = 100 (example)
    
    WAITFOR DELAY '00:00:05';  -- Wait 5 seconds
    
    -- Second read (within same transaction)
    SELECT ProductID, ProductName, Price 
    FROM Products 
    WHERE ProductID = 1;
    -- May show different price if another session updated it!
    -- This is a NON-REPEATABLE READ

COMMIT TRANSACTION;
GO

-- SESSION 2 (Run after Session 1's first read):
-- Update the row between reads
UPDATE Products SET Price = 200 WHERE ProductID = 1;
GO

-- =============================================
-- Example 4: REPEATABLE READ (No Non-Repeatable Reads)
-- =============================================

-- SESSION 1:
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

    -- First read
    SELECT ProductID, ProductName, Price 
    FROM Products 
    WHERE ProductID = 1;
    -- Shows Price = 100
    
    WAITFOR DELAY '00:00:05';
    
    -- Second read
    SELECT ProductID, ProductName, Price 
    FROM Products 
    WHERE ProductID = 1;
    -- GUARANTEED to show same price (100)
    -- Shared lock held until transaction ends

COMMIT TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- SESSION 2 (Try to update while Session 1 holds lock):
UPDATE Products SET Price = 200 WHERE ProductID = 1;
-- BLOCKS until Session 1 commits!
GO

-- =============================================
-- Example 5: Phantom Reads (REPEATABLE READ)
-- =============================================

-- SESSION 1:
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

    -- First read (count of electronics)
    SELECT COUNT(*) AS ElectronicsCount 
    FROM Products 
    WHERE Category = 'Electronics';
    -- Shows count = 5 (example)
    
    WAITFOR DELAY '00:00:05';
    
    -- Second read
    SELECT COUNT(*) AS ElectronicsCount 
    FROM Products 
    WHERE Category = 'Electronics';
    -- May show count = 6 if another session inserted a row!
    -- This is a PHANTOM READ (new rows appeared)

COMMIT TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- SESSION 2 (Insert new row between reads):
INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, SupplierID)
VALUES ('New Electronics Item', 'Electronics', 299.99, 150, 10, 1);
-- Succeeds even though Session 1 has REPEATABLE READ lock!
GO

-- =============================================
-- Example 6: SERIALIZABLE (No Phantom Reads)
-- =============================================

-- SESSION 1:
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

    -- First read
    SELECT COUNT(*) AS ElectronicsCount 
    FROM Products 
    WHERE Category = 'Electronics';
    -- Shows count = 5
    
    WAITFOR DELAY '00:00:05';
    
    -- Second read
    SELECT COUNT(*) AS ElectronicsCount 
    FROM Products 
    WHERE Category = 'Electronics';
    -- GUARANTEED to show same count (5)
    -- Range lock prevents inserts

COMMIT TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- SESSION 2 (Try to insert while Session 1 holds range lock):
INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, SupplierID)
VALUES ('Another Electronics Item', 'Electronics', 399.99, 200, 5, 1);
-- BLOCKS until Session 1 commits!
GO

-- =============================================
-- Example 7: SNAPSHOT Isolation
-- =============================================

-- SESSION 1:
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

    -- First read
    SELECT ProductID, ProductName, Price 
    FROM Products 
    WHERE ProductID = 1;
    -- Shows Price = 100 (row version at transaction start)
    
    WAITFOR DELAY '00:00:05';
    
    -- Second read
    SELECT ProductID, ProductName, Price 
    FROM Products 
    WHERE ProductID = 1;
    -- STILL shows Price = 100 (same row version)
    -- No blocking! Uses row versioning in tempdb

COMMIT TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- SESSION 2 (Update while Session 1 is reading):
UPDATE Products SET Price = 300 WHERE ProductID = 1;
-- Succeeds immediately (no blocking)
-- Session 1 doesn't see this change (sees old version)
GO

-- =============================================
-- Example 8: Snapshot Update Conflict
-- =============================================

-- SESSION 1:
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;

    -- Read current price
    DECLARE @CurrentPrice DECIMAL(10,2);
    SELECT @CurrentPrice = Price FROM Products WHERE ProductID = 1;
    
    WAITFOR DELAY '00:00:05';
    
    -- Try to update based on old value
    UPDATE Products 
    SET Price = @CurrentPrice + 10 
    WHERE ProductID = 1;
    -- ERROR! Update conflict (row modified by another transaction)

ROLLBACK TRANSACTION;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- SESSION 2 (Update the same row):
UPDATE Products SET Price = 200 WHERE ProductID = 1;
-- Succeeds, causing Session 1 to fail
GO

-- =============================================
-- Example 9: Isolation Level Comparison
-- =============================================

-- Create test table
CREATE TABLE IsolationTest (
    ID INT PRIMARY KEY,
    Value INT
);

INSERT INTO IsolationTest (ID, Value) VALUES (1, 100), (2, 200), (3, 300);
GO

-- READ UNCOMMITTED: Fastest, but allows dirty reads
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM IsolationTest;
-- No locks acquired, can read uncommitted data
GO

-- READ COMMITTED: Default, prevents dirty reads
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM IsolationTest;
-- Shared locks acquired and released immediately
GO

-- REPEATABLE READ: Prevents dirty and non-repeatable reads
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM IsolationTest;
    -- Shared locks held until transaction ends
COMMIT;
GO

-- SERIALIZABLE: Highest isolation, prevents all anomalies
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM IsolationTest WHERE Value > 150;
    -- Range locks prevent inserts/updates in range
COMMIT;
GO

-- SNAPSHOT: Optimistic concurrency, no blocking reads
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT * FROM IsolationTest;
    -- No locks, uses row versions from tempdb
COMMIT;
GO

-- Reset
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DROP TABLE IsolationTest;
GO

-- =============================================
-- Example 10: NOLOCK Hint (Same as READ UNCOMMITTED)
-- =============================================

-- These are equivalent:

-- Method 1: Set isolation level
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM Products;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- Method 2: Use NOLOCK hint
SELECT * FROM Products WITH (NOLOCK);
-- Same effect: allows dirty reads, no shared locks
GO

-- ⚠️ Warning: NOLOCK can read uncommitted and phantom rows!

-- =============================================
-- Example 11: UPDLOCK Hint (Prevent Deadlocks)
-- =============================================

-- Scenario: Two sessions both read then update (classic deadlock)

-- SESSION 1 (Without UPDLOCK - can deadlock):
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Shared lock
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 100 WHERE ProductID = 1;  -- Needs exclusive lock
COMMIT;
GO

-- SESSION 2 (Run simultaneously - can deadlock):
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Shared lock
    UPDATE Products SET Price = 200 WHERE ProductID = 1;  -- Needs exclusive lock (DEADLOCK!)
COMMIT;
GO

-- Better approach: Use UPDLOCK
BEGIN TRANSACTION;
    SELECT Price FROM Products WITH (UPDLOCK) WHERE ProductID = 1;  -- Update lock
    -- Other sessions can't get UPDLOCK (prevents deadlock)
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
COMMIT;
GO

-- =============================================
-- Example 12: ROWLOCK vs PAGLOCK vs TABLOCK
-- =============================================

-- Row-level lock (most granular)
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (ROWLOCK, UPDLOCK) WHERE ProductID = 1;
    -- Locks only 1 row
COMMIT;
GO

-- Page-level lock
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (PAGLOCK, UPDLOCK) WHERE ProductID = 1;
    -- Locks entire page (8KB) containing the row
COMMIT;
GO

-- Table-level lock
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (TABLOCK, UPDLOCK);
    -- Locks entire table
COMMIT;
GO

-- =============================================
-- Example 13: READPAST Hint (Skip Locked Rows)
-- =============================================

-- SESSION 1 (Lock some rows):
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID IN (1, 2, 3);
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2 (Read unlocked rows only):
SELECT * FROM Products WITH (READPAST)
WHERE ProductID <= 10;
-- Returns only unlocked rows (skips 1, 2, 3)
-- No blocking!
GO

-- =============================================
-- Example 14: Monitoring Isolation Levels
-- =============================================

-- Check current isolation level
DBCC USEROPTIONS;
GO

-- Query sys.dm_exec_sessions
SELECT 
    session_id,
    transaction_isolation_level,
    CASE transaction_isolation_level 
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'READ UNCOMMITTED'
        WHEN 2 THEN 'READ COMMITTED'
        WHEN 3 THEN 'REPEATABLE READ'
        WHEN 4 THEN 'SERIALIZABLE'
        WHEN 5 THEN 'SNAPSHOT'
    END AS IsolationLevel
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID;
GO

-- =============================================
-- Example 15: Real-World Use Cases
-- =============================================

-- Use Case 1: Reporting queries (use NOLOCK or SNAPSHOT)
-- Dirty reads acceptable for fast reports
SELECT 
    Category, 
    COUNT(*) AS ProductCnt, 
    AVG(Price) AS AvgPrice
FROM Products WITH (NOLOCK)
GROUP BY Category;
GO

-- Use Case 2: Financial transactions (use SERIALIZABLE)
-- Must prevent all anomalies
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    DECLARE @Balance DECIMAL(10,2);
    SELECT @Balance = TotalPurchases FROM Customers WHERE CustomerID = 1;
    
    -- Ensure no concurrent modifications
    IF @Balance >= 1000
        UPDATE Customers SET TotalPurchases = @Balance + 500 WHERE CustomerID = 1;
        
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- Use Case 3: Queue processing (use READPAST)
-- Skip locked items in queue
SELECT TOP 1 * 
FROM Sales WITH (READPAST, UPDLOCK, ROWLOCK)
WHERE PaymentMethod = 'Pending'
ORDER BY SaleDate;
-- Process item (other sessions skip this one)
GO

-- Use Case 4: Long-running analytics (use SNAPSHOT)
-- No blocking, consistent read
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    -- Complex analytics that take several minutes
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        MONTH(SaleDate) AS SaleMonth,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate);
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- =============================================
-- Cleanup
-- =============================================

-- Reset to default
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- 💡 Key Takeaways:
-- 
-- ISOLATION LEVEL COMPARISON:
-- ┌────────────────────┬──────────────┬───────────────────┬──────────────┬─────────────┐
-- │ Isolation Level    │ Dirty Reads  │ Non-Repeatable    │ Phantom      │ Concurrency │
-- │                    │              │ Reads             │ Reads        │             │
-- ├────────────────────┼──────────────┼───────────────────┼──────────────┼─────────────┤
-- │ READ UNCOMMITTED   │ Yes          │ Yes               │ Yes          │ Highest     │
-- │ READ COMMITTED     │ No           │ Yes               │ Yes          │ High        │
-- │ REPEATABLE READ    │ No           │ No                │ Yes          │ Medium      │
-- │ SERIALIZABLE       │ No           │ No                │ No           │ Low         │
-- │ SNAPSHOT           │ No           │ No                │ No*          │ High        │
-- └────────────────────┴──────────────┴───────────────────┴──────────────┴─────────────┘
-- * SNAPSHOT prevents phantom reads but uses row versioning (optimistic)
--
-- WHEN TO USE:
-- - READ UNCOMMITTED: Reports where dirty reads acceptable, performance critical
-- - READ COMMITTED: Default, general-purpose OLTP
-- - REPEATABLE READ: Need consistent reads within transaction
-- - SERIALIZABLE: Financial transactions, no anomalies allowed
-- - SNAPSHOT: Long-running queries without blocking writers
--
-- LOCK HINTS:
-- - NOLOCK: Same as READ UNCOMMITTED (dirty reads)
-- - UPDLOCK: Prevent deadlocks (acquire update lock instead of shared)
-- - ROWLOCK/PAGLOCK/TABLOCK: Control lock granularity
-- - READPAST: Skip locked rows (queue processing)
-- - HOLDLOCK: Same as REPEATABLE READ for this query
-- - XLOCK: Exclusive lock (same as update intent)
--
-- BEST PRACTICES:
-- - Use READ COMMITTED for most OLTP workloads
-- - Use SNAPSHOT for long-running reports (no blocking)
-- - Use SERIALIZABLE only when absolutely necessary (lowest concurrency)
-- - Use NOLOCK/READ UNCOMMITTED for reports where dirty reads acceptable
-- - Use UPDLOCK to prevent deadlocks in read-then-update patterns
-- - Keep transactions SHORT regardless of isolation level
-- - Enable SNAPSHOT isolation at database level first
-- - Monitor blocking and deadlocks with Extended Events
