-- ========================================
-- Locking Mechanisms
-- Lock Types, Compatibility, Hints, Monitoring
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Lock Types Overview
-- =============================================

/*
SQL Server Lock Types:
- S (Shared): Read locks - multiple allowed
- X (Exclusive): Write locks - exclusive
- U (Update): Intent to update - prevents deadlocks
- IS (Intent Shared): Intent to acquire S lock at finer granularity
- IX (Intent Exclusive): Intent to acquire X lock at finer granularity
- SIX (Shared with Intent Exclusive): S lock + IX lock
- Sch-S (Schema Stability): Prevents DDL changes
- Sch-M (Schema Modification): Exclusive for DDL
*/

-- =============================================
-- Example 2: Shared Locks (Read)
-- =============================================

-- Start transaction with read
BEGIN TRANSACTION;
    
    -- Acquires shared lock
    SELECT * FROM Products WHERE ProductID = 1;
    
    -- Check locks
    SELECT 
        resource_type,
        resource_description,
        request_mode,
        request_status
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID;
    -- Shows S (Shared) locks on KEY and PAGE
    
COMMIT TRANSACTION;
-- Shared locks released immediately (in READ COMMITTED)
GO

-- =============================================
-- Example 3: Exclusive Locks (Write)
-- =============================================

BEGIN TRANSACTION;
    
    -- Acquires exclusive lock
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    
    -- Check locks
    SELECT 
        resource_type,
        resource_description,
        request_mode,
        request_status
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID;
    -- Shows X (Exclusive) locks on KEY and IX on PAGE/TABLE
    
COMMIT TRANSACTION;
-- Exclusive locks released on commit
GO

-- =============================================
-- Example 4: Update Locks (Prevent Deadlocks)
-- =============================================

-- Without UPDLOCK (potential deadlock):
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- S lock
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 100 WHERE ProductID = 1;  -- Needs X lock
COMMIT;
GO

-- SESSION 2 (run simultaneously - deadlock risk):
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- S lock
    UPDATE Products SET Price = 200 WHERE ProductID = 1;  -- Needs X lock (DEADLOCK!)
COMMIT;
GO

-- With UPDLOCK (no deadlock):
BEGIN TRANSACTION;
    SELECT Price FROM Products WITH (UPDLOCK) 
    WHERE ProductID = 1;  -- U lock (not S)
    -- Other sessions blocked from getting U lock
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 100 WHERE ProductID = 1;  -- U → X conversion
COMMIT;
GO

-- =============================================
-- Example 5: Lock Compatibility Matrix
-- =============================================

-- Create demonstration
CREATE TABLE LockDemo (ID INT PRIMARY KEY, Value INT);
INSERT INTO LockDemo VALUES (1, 100);
GO

-- Test 1: S + S = Compatible (multiple reads allowed)
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT * FROM LockDemo WITH (HOLDLOCK) WHERE ID = 1;  -- S lock held
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2 (run while Session 1 holds S lock):
SELECT * FROM LockDemo WHERE ID = 1;  -- Also gets S lock (no blocking)
GO

-- Test 2: S + X = Incompatible (read blocks write)
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT * FROM LockDemo WITH (HOLDLOCK) WHERE ID = 1;  -- S lock
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2:
UPDATE LockDemo SET Value = 200 WHERE ID = 1;  -- BLOCKS (needs X lock)
GO

-- Test 3: X + S = Incompatible (write blocks read)
-- SESSION 1:
BEGIN TRANSACTION;
    UPDATE LockDemo SET Value = 300 WHERE ID = 1;  -- X lock
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2:
SELECT * FROM LockDemo WHERE ID = 1;  -- BLOCKS (S incompatible with X)
GO

-- Test 4: X + X = Incompatible (write blocks write)
-- SESSION 1:
BEGIN TRANSACTION;
    UPDATE LockDemo SET Value = 400 WHERE ID = 1;  -- X lock
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2:
UPDATE LockDemo SET Value = 500 WHERE ID = 1;  -- BLOCKS (X incompatible with X)
GO

-- Cleanup
DROP TABLE LockDemo;
GO

-- =============================================
-- Example 6: Lock Granularity
-- =============================================

/*
Lock Granularity Hierarchy (fine to coarse):
1. RID (Row ID) - heap row
2. KEY - index row
3. PAGE - 8KB page
4. EXTENT - 8 pages (64KB)
5. HoBT - heap or B-tree
6. TABLE - entire table
7. DATABASE - entire database
*/

-- Row-level lock
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    
    SELECT 
        resource_type,
        resource_description,
        request_mode
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    ORDER BY resource_type;
    -- Shows KEY (row), PAGE, OBJECT (table)
COMMIT;
GO

-- Force table-level lock
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (TABLOCK);
    
    SELECT 
        resource_type,
        request_mode
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID;
    -- Shows OBJECT (table) lock
COMMIT;
GO

-- =============================================
-- Example 7: Lock Escalation
-- =============================================

-- Lock escalation: Converting many fine-grained locks to fewer coarse-grained locks
-- Default: Escalates to TABLE when > 5000 locks on table

-- Disable lock escalation for testing
ALTER TABLE Products SET (LOCK_ESCALATION = DISABLE);
GO

-- Update many rows (would normally escalate)
BEGIN TRANSACTION;
    UPDATE Products SET Price = Price * 1.01;  -- Update all rows
    
    -- Check locks (many row/page locks)
    SELECT 
        resource_type,
        COUNT(*) AS LockCnt
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    GROUP BY resource_type;
COMMIT;
GO

-- Re-enable lock escalation
ALTER TABLE Products SET (LOCK_ESCALATION = TABLE);
GO

-- Now escalation occurs
BEGIN TRANSACTION;
    UPDATE Products SET Price = Price * 1.01;
    
    -- Check locks (escalated to table lock)
    SELECT 
        resource_type,
        COUNT(*) AS LockCnt
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    GROUP BY resource_type;
    -- Likely shows OBJECT (table) lock instead of many KEY locks
COMMIT;
GO

-- =============================================
-- Example 8: Lock Hints - ROWLOCK
-- =============================================

-- Force row-level locking
BEGIN TRANSACTION;
    
    UPDATE Products WITH (ROWLOCK) 
    SET Price = 100 
    WHERE Category = 'Electronics';
    
    SELECT 
        resource_type,
        COUNT(*) AS LockCnt
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    GROUP BY resource_type;
    -- Shows KEY (row) locks, no table escalation
    
COMMIT;
GO

-- =============================================
-- Example 9: Lock Hints - XLOCK (Exclusive)
-- =============================================

-- Acquire exclusive lock immediately (even for reads)
BEGIN TRANSACTION;
    
    SELECT * FROM Products WITH (XLOCK, ROWLOCK) 
    WHERE ProductID = 1;
    -- Exclusive lock on row (not shared)
    
    -- Other sessions blocked from reading this row
    WAITFOR DELAY '00:00:05';
    
COMMIT;
GO

-- =============================================
-- Example 10: Lock Hints - READPAST
-- =============================================

-- SESSION 1 (Lock some rows):
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID IN (1, 2, 3);
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2 (Skip locked rows):
SELECT * FROM Products WITH (READPAST)
WHERE ProductID <= 10;
-- Returns rows 4-10 only (skips locked rows 1-3)
-- No blocking!
GO

-- Use case: Queue processing
BEGIN TRANSACTION;
    -- Get next available queue item (skip locked ones)
    DECLARE @SaleID INT;
    
    SELECT TOP 1 @SaleID = SaleID
    FROM Sales WITH (READPAST, UPDLOCK, ROWLOCK)
    WHERE PaymentMethod = 'Pending'
    ORDER BY SaleDate;
    
    -- Process this sale (other sessions skip it)
    IF @SaleID IS NOT NULL
        UPDATE Sales SET PaymentMethod = 'Processed' WHERE SaleID = @SaleID;
        
COMMIT;
GO

-- =============================================
-- Example 11: Monitoring Locks
-- =============================================

-- View all locks in database
SELECT 
    l.request_session_id AS SessionID,
    DB_NAME(l.resource_database_id) AS DatabaseName,
    l.resource_type AS ResourceType,
    l.resource_description AS ResourceDesc,
    l.request_mode AS LockMode,
    l.request_status AS LockStatus,
    OBJECT_NAME(p.object_id) AS ObjectName
FROM sys.dm_tran_locks l
LEFT JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id
WHERE l.resource_database_id = DB_ID('TechStore')
ORDER BY l.request_session_id;
GO

-- View blocking sessions
SELECT 
    blocking.session_id AS BlockingSessionID,
    blocked.session_id AS BlockedSessionID,
    OBJECT_NAME(blocked_locks.resource_associated_entity_id) AS BlockedObject,
    blocked_locks.resource_type AS BlockedResource,
    blocked_text.text AS BlockedQuery,
    blocking_text.text AS BlockingQuery
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_tran_locks blocked_locks 
    ON blocked.session_id = blocked_locks.request_session_id
INNER JOIN sys.dm_exec_connections blocked_conn 
    ON blocked.session_id = blocked_conn.session_id
CROSS APPLY sys.dm_exec_sql_text(blocked_conn.most_recent_sql_handle) blocked_text
LEFT JOIN sys.dm_exec_requests blocking 
    ON blocked.blocking_session_id = blocking.session_id
LEFT JOIN sys.dm_exec_connections blocking_conn 
    ON blocking.session_id = blocking_conn.session_id
OUTER APPLY sys.dm_exec_sql_text(blocking_conn.most_recent_sql_handle) blocking_text
WHERE blocked.blocking_session_id > 0;
GO

-- =============================================
-- Example 12: sp_lock (Deprecated but useful)
-- =============================================

-- Start a transaction
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    
    -- View locks for this session
    EXEC sp_lock @@SPID;
    
ROLLBACK;
GO

-- =============================================
-- Example 13: Lock Timeout
-- =============================================

-- Set lock timeout (milliseconds)
SET LOCK_TIMEOUT 5000;  -- 5 seconds

BEGIN TRY
    -- This may timeout if row is locked
    SELECT * FROM Products WHERE ProductID = 1;
    PRINT 'Query succeeded';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 1222  -- Lock timeout error
        PRINT 'Lock timeout occurred';
    ELSE
        PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- Reset to wait indefinitely
SET LOCK_TIMEOUT -1;
GO

-- =============================================
-- Example 14: Intent Locks
-- =============================================

-- Intent locks indicate future locking at finer granularity

BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    
    -- Check intent locks
    SELECT 
        resource_type,
        request_mode,
        CASE request_mode
            WHEN 'IS' THEN 'Intent Shared'
            WHEN 'IX' THEN 'Intent Exclusive'
            WHEN 'SIX' THEN 'Shared with Intent Exclusive'
            WHEN 'S' THEN 'Shared'
            WHEN 'X' THEN 'Exclusive'
            WHEN 'U' THEN 'Update'
        END AS LockType
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID;
    -- Shows IX on PAGE/OBJECT, X on KEY
COMMIT;
GO

-- =============================================
-- Example 15: Schema Locks
-- =============================================

-- Schema Stability lock (Sch-S)
BEGIN TRANSACTION;
    SELECT * FROM Products;
    
    -- Holds Sch-S lock (prevents DDL changes)
    SELECT * FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID 
    AND request_mode = 'Sch-S';
COMMIT;
GO

-- Try to alter table while query runs (will block)
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT * FROM Products;
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2:
ALTER TABLE Products ADD TempColumn INT;  -- BLOCKS (needs Sch-M lock)
ALTER TABLE Products DROP COLUMN TempColumn;
GO

-- =============================================
-- Example 16: Lock Compatibility Examples
-- =============================================

-- S lock + S lock = Compatible
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (HOLDLOCK) WHERE ProductID = 1;
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2 (No blocking):
SELECT * FROM Products WHERE ProductID = 1;
GO

-- U lock + U lock = Incompatible (prevents deadlocks)
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (UPDLOCK) WHERE ProductID = 1;
    WAITFOR DELAY '00:00:10';
COMMIT;
GO

-- SESSION 2 (BLOCKS):
SELECT * FROM Products WITH (UPDLOCK) WHERE ProductID = 1;
GO

-- =============================================
-- Example 17: Optimistic vs Pessimistic Locking
-- =============================================

-- Pessimistic locking (traditional locking)
BEGIN TRANSACTION;
    -- Lock row immediately
    SELECT * FROM Products WITH (UPDLOCK, HOLDLOCK) WHERE ProductID = 1;
    
    -- Do work...
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
COMMIT;
GO

-- Optimistic locking (row versioning with timestamp/version column)
ALTER TABLE Products ADD RowVersion ROWVERSION;
GO

-- Read without locks
DECLARE @RowVer BINARY(8);
SELECT @RowVer = RowVersion FROM Products WHERE ProductID = 1;

-- Later, update only if version hasn't changed
UPDATE Products 
SET Price = 100 
WHERE ProductID = 1 AND RowVersion = @RowVer;

IF @@ROWCOUNT = 0
    PRINT 'Row was modified by another user. Update failed.';
ELSE
    PRINT 'Update succeeded';
GO

ALTER TABLE Products DROP COLUMN RowVersion;
GO

-- =============================================
-- Example 18: Lock Partitioning (Advanced)
-- =============================================

-- SQL Server can partition locks across CPU schedulers
-- Reduces lock contention on highly concurrent systems

-- Enable lock partitioning (automatic on Enterprise Edition)
-- Partitions locks for tables with > 15M rows

-- Check if lock partitioning is enabled
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    lock_escalation_desc
FROM sys.tables
WHERE name = 'Products';
GO

-- =============================================
-- Example 19: Application Locks (Custom Locks)
-- =============================================

-- Create custom application lock
BEGIN TRANSACTION;
    
    -- Acquire exclusive application lock
    DECLARE @Result INT;
    EXEC @Result = sp_getapplock 
        @Resource = 'ProcessSales',
        @LockMode = 'Exclusive',
        @LockOwner = 'Transaction',
        @LockTimeout = 5000;  -- 5 seconds
    
    IF @Result >= 0
    BEGIN
        PRINT 'Lock acquired';
        
        -- Do exclusive work (only one session can do this)
        UPDATE Sales SET PaymentMethod = 'Processed' WHERE PaymentMethod = 'Pending';
        
        -- Release lock
        EXEC sp_releaseapplock @Resource = 'ProcessSales', @LockOwner = 'Transaction';
    END
    ELSE
        PRINT 'Failed to acquire lock';
        
COMMIT;
GO

-- =============================================
-- Example 20: Best Practices Summary
-- =============================================

-- ✅ GOOD: Minimize lock duration
BEGIN TRANSACTION;
    -- Quick, specific update
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
COMMIT;
GO

-- ❌ BAD: Long-held locks
/*
BEGIN TRANSACTION;
    SELECT * FROM Products WITH (HOLDLOCK);
    WAITFOR DELAY '00:05:00';  -- Holds locks for 5 minutes!
    UPDATE Products SET Price = 100;
COMMIT;
*/

-- ✅ GOOD: Use appropriate isolation level
-- For reports, use NOLOCK or SNAPSHOT
SELECT Category, COUNT(*) AS ProductCnt
FROM Products WITH (NOLOCK)
GROUP BY Category;
GO

-- ✅ GOOD: Use UPDLOCK for read-then-update
BEGIN TRANSACTION;
    SELECT Price FROM Products WITH (UPDLOCK, ROWLOCK) WHERE ProductID = 1;
    -- Prevents deadlocks
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
COMMIT;
GO

-- ✅ GOOD: Use READPAST for queue processing
SELECT TOP 1 * 
FROM Sales WITH (READPAST, UPDLOCK, ROWLOCK)
WHERE PaymentMethod = 'Pending';
-- Skips locked items, no blocking
GO

-- 💡 Key Takeaways:
--
-- LOCK TYPES:
-- - S (Shared): Read locks, multiple allowed
-- - X (Exclusive): Write locks, one at a time
-- - U (Update): Intent to update, prevents deadlocks
-- - IS/IX: Intent locks at finer granularity
-- - Sch-S/Sch-M: Schema stability/modification
--
-- LOCK COMPATIBILITY:
-- - S + S = Compatible (multiple reads)
-- - S + X = Incompatible (read blocks write)
-- - X + X = Incompatible (write blocks write)
-- - U + U = Incompatible (prevents deadlocks)
--
-- LOCK HINTS:
-- - UPDLOCK: Acquire update lock (prevent deadlocks)
-- - HOLDLOCK: Hold lock until transaction ends (like REPEATABLE READ)
-- - ROWLOCK/PAGLOCK/TABLOCK: Control granularity
-- - READPAST: Skip locked rows (queue processing)
-- - NOLOCK: No shared locks (dirty reads)
-- - XLOCK: Exclusive lock (even for reads)
--
-- LOCK GRANULARITY (fine → coarse):
-- RID/KEY (row) → PAGE → EXTENT → TABLE → DATABASE
--
-- LOCK ESCALATION:
-- - Automatic conversion to coarser locks (> 5000 locks → table lock)
-- - Reduces lock overhead but decreases concurrency
-- - Can disable with LOCK_ESCALATION = DISABLE
--
-- MONITORING:
-- - sys.dm_tran_locks: View all locks
-- - sys.dm_exec_requests: View blocking
-- - sp_lock: Deprecated but simple
-- - sp_who2: View session blocking
--
-- BEST PRACTICES:
-- - Keep transactions SHORT
-- - Use appropriate isolation level
-- - Use UPDLOCK for read-then-update patterns
-- - Use READPAST for queue processing
-- - Avoid long-held locks (no I/O in transactions)
-- - Monitor blocking with DMVs
-- - Use application locks for custom resources
-- - Consider SNAPSHOT isolation for long reports
-- - Access objects in consistent order (prevent deadlocks)
-- - Use row-level hints when appropriate (ROWLOCK)
