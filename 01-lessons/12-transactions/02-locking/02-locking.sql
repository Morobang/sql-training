/*
============================================================================
Lesson 12.02 - Locking
============================================================================

Description:
Master database locking mechanisms in SQL Server. Learn about different
lock types, lock modes, compatibility, duration, and deadlock scenarios.
Understand how SQL Server uses locks to manage concurrent access.

Topics Covered:
• Purpose of locking
• Lock types (Shared, Exclusive, Update, Intent)
• Lock compatibility matrix
• Lock duration and scope
• Lock hints
• Deadlocks and resolution
• Monitoring locks
• Best practices

Prerequisites:
• Lesson 12.01 (Multiuser Databases)

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Purpose of Locking
============================================================================
*/

-- Example 1.1: Why Locks Are Needed
/*
WITHOUT LOCKS:
┌──────────────────────────────────────────────────────────┐
│ Time  User A                    User B                   │
├──────────────────────────────────────────────────────────┤
│ T1    READ Balance = 1000                                │
│ T2                               READ Balance = 1000     │
│ T3    Balance = Balance - 100                            │
│ T4                               Balance = Balance - 200 │
│ T5    WRITE Balance = 900                                │
│ T6                               WRITE Balance = 800     │
└──────────────────────────────────────────────────────────┘
Result: Balance = 800 (Lost Update! Should be 700)

WITH LOCKS:
┌──────────────────────────────────────────────────────────┐
│ Time  User A                    User B                   │
├──────────────────────────────────────────────────────────┤
│ T1    LOCK + READ Balance = 1000                         │
│ T2                               WAIT (locked)...        │
│ T3    Balance = Balance - 100                            │
│ T4                               WAIT...                 │
│ T5    WRITE Balance = 900                                │
│ T6    UNLOCK                                             │
│ T7                               LOCK + READ Balance = 900│
│ T8                               Balance = Balance - 200 │
│ T9                               WRITE Balance = 700     │
│ T10                              UNLOCK                  │
└──────────────────────────────────────────────────────────┘
Result: Balance = 700 (Correct!)

Locks ensure:
• Serialized access to data
• Prevention of lost updates
• Data consistency
• Isolation between transactions
*/

-- Example 1.2: Locks in Action
CREATE TABLE #AccountsDemo (
    AccountID INT PRIMARY KEY,
    Balance DECIMAL(10,2)
);

INSERT INTO #AccountsDemo VALUES (1, 1000.00);

-- View current locks on the table
SELECT 
    resource_type,
    resource_description,
    request_mode,
    request_status
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID('RetailStore');


/*
============================================================================
PART 2: Lock Types and Modes
============================================================================
*/

-- Example 2.1: Shared Locks (S)
/*
SHARED LOCK (S):
• Acquired when reading data
• Multiple transactions can hold shared locks simultaneously
• Prevents modifications while reading
• Released after read (default) or held until transaction ends

Symbol: [S]
Purpose: "I'm reading this, don't change it"
*/

-- Acquire shared lock
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WHERE AccountID = 1;
    -- Shared lock acquired on the row
    
    -- Check locks
    SELECT request_mode, request_status
    FROM sys.dm_tran_locks
    WHERE resource_database_id = DB_ID('RetailStore')
    AND request_session_id = @@SPID;
    
    -- Lock released when SELECT completes (READ COMMITTED isolation)
COMMIT TRANSACTION;

-- Hold shared lock longer
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (HOLDLOCK) WHERE AccountID = 1;
    -- Shared lock held until transaction ends
    
    WAITFOR DELAY '00:00:05';  -- Lock still held
    
COMMIT TRANSACTION;  -- Lock released here


-- Example 2.2: Exclusive Locks (X)
/*
EXCLUSIVE LOCK (X):
• Acquired when modifying data (INSERT, UPDATE, DELETE)
• Only one transaction can hold exclusive lock
• No other locks allowed simultaneously
• Held until transaction commits or rolls back

Symbol: [X]
Purpose: "I'm changing this, nobody else can read or write"
*/

-- Acquire exclusive lock
BEGIN TRANSACTION;
    UPDATE #AccountsDemo 
    SET Balance = Balance - 100 
    WHERE AccountID = 1;
    -- Exclusive lock acquired
    
    -- Check locks
    SELECT resource_type, request_mode, request_status
    FROM sys.dm_tran_locks
    WHERE resource_database_id = DB_ID('RetailStore')
    AND request_session_id = @@SPID;
    
    WAITFOR DELAY '00:00:03';  -- Lock held
    
COMMIT TRANSACTION;  -- Lock released


-- Example 2.3: Update Locks (U)
/*
UPDATE LOCK (U):
• Acquired when reading with intent to update
• Prevents deadlocks in read-then-update pattern
• Converts to exclusive lock when actually updating
• Only one update lock allowed per resource

Symbol: [U]
Purpose: "I'm reading this and might update it"

UPDATE LOCK SEQUENCE:
1. Acquire U lock (reading for update)
2. Convert to X lock (actually updating)
3. Release X lock (transaction commits)
*/

-- Acquire update lock
BEGIN TRANSACTION;
    -- Read with intent to update
    SELECT * FROM #AccountsDemo WITH (UPDLOCK) WHERE AccountID = 1;
    -- Update lock acquired
    
    -- Simulate decision-making
    WAITFOR DELAY '00:00:02';
    
    -- Update (U lock converts to X lock)
    UPDATE #AccountsDemo 
    SET Balance = Balance - 50 
    WHERE AccountID = 1;
    
COMMIT TRANSACTION;


-- Example 2.4: Intent Locks (IS, IX, IU)
/*
INTENT LOCKS:
Indicate that a transaction intends to acquire locks at a finer granularity.

• IS (Intent Shared): Intends to acquire S locks on rows
• IX (Intent Exclusive): Intends to acquire X locks on rows
• IU (Intent Update): Intends to acquire U locks on rows

Purpose: Prevent table-level locks when row-level locks exist

Hierarchy:
    Database
       ↓
    Table [IX]     ← Intent lock on table
       ↓
    Page
       ↓
    Row [X]        ← Actual lock on row
*/


/*
============================================================================
PART 3: Lock Compatibility Matrix
============================================================================
*/

-- Example 3.1: Lock Compatibility
/*
COMPATIBILITY MATRIX:
          Existing Lock
Request   │  S  │  U  │  X  │
Lock      ├─────┼─────┼─────┤
──────────┼─────┼─────┼─────┤
   S      │ YES │ YES │ NO  │
   U      │ YES │ NO  │ NO  │
   X      │ NO  │ NO  │ NO  │

Interpretation:
✓ YES = Compatible (both locks can coexist)
✗ NO  = Incompatible (second request must wait)

Examples:
• Multiple S locks: Compatible (everyone can read)
• S + U locks: Compatible (read while preparing to update)
• S + X locks: Incompatible (can't read while writing)
• U + U locks: Incompatible (only one can prepare to update)
• X + anything: Incompatible (exclusive means exclusive!)
*/

-- Example 3.2: Demonstrating Compatibility
-- Session 1: Shared lock
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (HOLDLOCK) WHERE AccountID = 1;
    PRINT 'Session 1: Acquired shared lock';
    
    WAITFOR DELAY '00:00:10';
    
COMMIT TRANSACTION;

-- Session 2: Another shared lock (in different window - COMPATIBLE)
/*
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (HOLDLOCK) WHERE AccountID = 1;
    PRINT 'Session 2: Acquired shared lock (no waiting!)';
COMMIT TRANSACTION;
*/

-- Session 3: Exclusive lock (in different window - INCOMPATIBLE)
/*
BEGIN TRANSACTION;
    UPDATE #AccountsDemo SET Balance = 500 WHERE AccountID = 1;
    PRINT 'Session 3: Trying to acquire exclusive lock (WAITING...)';
COMMIT TRANSACTION;
*/


/*
============================================================================
PART 4: Lock Duration
============================================================================
*/

-- Example 4.1: Lock Duration by Isolation Level
/*
ISOLATION LEVEL IMPACT ON LOCK DURATION:

READ UNCOMMITTED:
• No shared locks acquired
• Can read uncommitted data

READ COMMITTED (default):
• Shared locks acquired
• Released immediately after read

REPEATABLE READ:
• Shared locks acquired
• Held until transaction ends

SERIALIZABLE:
• Shared and range locks acquired
• Held until transaction ends
*/

-- READ COMMITTED (default)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo;  -- S lock acquired and released
    WAITFOR DELAY '00:00:02';     -- No lock held here
COMMIT;

-- REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo;  -- S lock acquired
    WAITFOR DELAY '00:00:02';     -- S lock still held
COMMIT;  -- S lock released


-- Example 4.2: Explicit Lock Duration Control
-- HOLDLOCK: Hold shared lock until transaction ends
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (HOLDLOCK) WHERE AccountID = 1;
    WAITFOR DELAY '00:00:05';  -- Lock still held
COMMIT;

-- UPDLOCK: Acquire update lock
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (UPDLOCK) WHERE AccountID = 1;
    WAITFOR DELAY '00:00:03';  -- Update lock held
COMMIT;

-- XLOCK: Acquire exclusive lock for reading
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (XLOCK) WHERE AccountID = 1;
    WAITFOR DELAY '00:00:03';  -- Exclusive lock on SELECT!
COMMIT;


/*
============================================================================
PART 5: Lock Hints
============================================================================
*/

-- Example 5.1: Common Lock Hints
/*
LOCK HINTS:
Allow you to override default locking behavior

┌──────────────┬─────────────────────────────────────────────┐
│    Hint      │              Description                    │
├──────────────┼─────────────────────────────────────────────┤
│ NOLOCK       │ No shared locks (dirty reads possible)      │
│ HOLDLOCK     │ Hold shared lock until transaction ends     │
│ UPDLOCK      │ Acquire update lock instead of shared       │
│ XLOCK        │ Acquire exclusive lock                      │
│ ROWLOCK      │ Use row-level locks                         │
│ PAGLOCK      │ Use page-level locks                        │
│ TABLOCK      │ Use table-level lock                        │
│ TABLOCKX     │ Exclusive table-level lock                  │
└──────────────┴─────────────────────────────────────────────┘
*/

-- NOLOCK: Read without locks (fastest, least safe)
SELECT * FROM #AccountsDemo WITH (NOLOCK);

-- HOLDLOCK: Keep shared lock
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WITH (HOLDLOCK);
    -- Lock held until COMMIT
COMMIT;

-- UPDLOCK: Prevent deadlocks in update scenarios
BEGIN TRANSACTION;
    DECLARE @Balance DECIMAL(10,2);
    
    SELECT @Balance = Balance 
    FROM #AccountsDemo WITH (UPDLOCK)
    WHERE AccountID = 1;
    
    IF @Balance >= 100
    BEGIN
        UPDATE #AccountsDemo 
        SET Balance = Balance - 100 
        WHERE AccountID = 1;
    END
COMMIT;

-- TABLOCK: Lock entire table
SELECT * FROM #AccountsDemo WITH (TABLOCK);


/*
============================================================================
PART 6: Deadlocks
============================================================================
*/

-- Example 6.1: What is a Deadlock?
/*
DEADLOCK:
Two or more transactions waiting for each other to release locks,
creating a circular dependency that cannot be resolved.

Classic Deadlock Scenario:
┌──────────────────────────────────────────────────────────┐
│ Time  Transaction 1              Transaction 2           │
├──────────────────────────────────────────────────────────┤
│ T1    LOCK Table A [X]                                   │
│ T2                                 LOCK Table B [X]      │
│ T3    Request LOCK Table B        ...                    │
│       (WAITING...)                                       │
│ T4    ...                          Request LOCK Table A  │
│                                    (WAITING...)          │
│ T5    ← Both waiting for each other = DEADLOCK! →       │
└──────────────────────────────────────────────────────────┘

SQL Server detects deadlock and chooses a "victim" to rollback.
*/

-- Example 6.2: Create Deadlock Scenario
CREATE TABLE #TableA (ID INT, Value VARCHAR(50));
CREATE TABLE #TableB (ID INT, Value VARCHAR(50));

INSERT INTO #TableA VALUES (1, 'Data A');
INSERT INTO #TableB VALUES (1, 'Data B');

-- Session 1:
BEGIN TRANSACTION;
    UPDATE #TableA SET Value = 'Updated A' WHERE ID = 1;
    PRINT 'Session 1: Locked Table A';
    
    WAITFOR DELAY '00:00:05';  -- Give Session 2 time to lock Table B
    
    UPDATE #TableB SET Value = 'Updated B' WHERE ID = 1;
    PRINT 'Session 1: Trying to lock Table B...';
COMMIT;

-- Session 2 (run in different window after starting Session 1):
/*
BEGIN TRANSACTION;
    UPDATE #TableB SET Value = 'Updated B2' WHERE ID = 1;
    PRINT 'Session 2: Locked Table B';
    
    WAITFOR DELAY '00:00:02';
    
    UPDATE #TableA SET Value = 'Updated A2' WHERE ID = 1;
    PRINT 'Session 2: Trying to lock Table A...';
COMMIT;

-- One session will be chosen as deadlock victim and rolled back!
-- Error: Transaction was deadlocked and has been chosen as the deadlock victim
*/

-- Example 6.3: Preventing Deadlocks
/*
DEADLOCK PREVENTION STRATEGIES:

1. Access objects in same order:
   Always UPDATE TableA before TableB in all transactions

2. Keep transactions short:
   Minimize lock duration

3. Use appropriate isolation level:
   Lower levels reduce lock contention

4. Use row-level locks:
   Reduce granularity to minimize conflicts

5. Use timeout:
   SET LOCK_TIMEOUT 5000;  -- 5 seconds

6. Implement retry logic:
   Catch deadlock errors and retry transaction
*/

-- Proper order (no deadlock):
BEGIN TRANSACTION;
    UPDATE #TableA SET Value = 'A1' WHERE ID = 1;
    UPDATE #TableB SET Value = 'B1' WHERE ID = 1;
COMMIT;

-- Both sessions do same order = no deadlock!

DROP TABLE #TableA;
DROP TABLE #TableB;


/*
============================================================================
PART 7: Monitoring Locks
============================================================================
*/

-- Example 7.1: View Current Locks
SELECT 
    tl.resource_type AS ResourceType,
    tl.resource_description AS Resource,
    tl.request_mode AS LockMode,
    tl.request_status AS Status,
    tl.request_session_id AS SessionID
FROM sys.dm_tran_locks tl
WHERE resource_database_id = DB_ID('RetailStore')
ORDER BY tl.request_session_id;

-- Example 7.2: View Blocking Sessions
SELECT 
    blocking.session_id AS BlockingSessionID,
    blocked.session_id AS BlockedSessionID,
    blocked.wait_time AS WaitTime_ms,
    blocked.wait_type,
    blocking_sql.text AS BlockingSQL,
    blocked_sql.text AS BlockedSQL
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_exec_requests blocking 
    ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blocking_sql
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_sql
WHERE blocked.blocking_session_id > 0;

-- Example 7.3: View Lock Waits
SELECT 
    session_id,
    wait_duration_ms,
    wait_type,
    blocking_session_id,
    resource_description
FROM sys.dm_os_waiting_tasks
WHERE blocking_session_id IS NOT NULL;

-- Example 7.4: Deadlock Information
-- Enable trace flag to log deadlocks
DBCC TRACEON (1222, -1);
-- Deadlock info written to SQL Server Error Log


/*
============================================================================
PART 8: Best Practices
============================================================================
*/

-- Example 8.1: Minimize Lock Duration
-- BAD: Long transaction holding locks
BEGIN TRANSACTION;
    SELECT * FROM #AccountsDemo WHERE AccountID = 1;
    
    -- Complex business logic here...
    WAITFOR DELAY '00:01:00';  -- 1 minute!
    
    UPDATE #AccountsDemo SET Balance = Balance - 10 WHERE AccountID = 1;
COMMIT;

-- GOOD: Short transaction
DECLARE @Balance DECIMAL(10,2);

-- Read outside transaction
SELECT @Balance = Balance FROM #AccountsDemo WHERE AccountID = 1;

-- Complex business logic here (no locks held)
-- ... calculations ...

-- Quick transaction
BEGIN TRANSACTION;
    UPDATE #AccountsDemo SET Balance = Balance - 10 WHERE AccountID = 1;
COMMIT;


-- Example 8.2: Use Appropriate Isolation Levels
-- For reports (read-only, consistency not critical)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM #AccountsDemo;  -- Fast, no locks

-- For financial transactions (consistency critical)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT Balance FROM #AccountsDemo WHERE AccountID = 1;
    -- Balance won't change during transaction
    UPDATE #AccountsDemo SET Balance = Balance - 100 WHERE AccountID = 1;
COMMIT;


-- Example 8.3: Access Resources in Consistent Order
-- All transactions should update in same order
PROCEDURE UpdateAccountsConsistently
AS
BEGIN
    BEGIN TRANSACTION;
        -- Always update in AccountID order
        UPDATE #AccountsDemo SET Balance = Balance - 10 WHERE AccountID = 1;
        UPDATE #AccountsDemo SET Balance = Balance + 10 WHERE AccountID = 2;
    COMMIT;
END;


-- Cleanup
DROP TABLE #AccountsDemo;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Explain why update locks exist and how they prevent deadlocks
2. Create a scenario demonstrating lock compatibility
3. Write a query to find all blocking sessions
4. Design a deadlock scenario and show how to prevent it
5. Explain when to use NOLOCK and when it's dangerous

Solutions below ↓
*/

-- Solution 1: Update Locks Explanation
/*
UPDATE LOCKS PREVENT DEADLOCKS:

Without Update Locks (Deadlock Possible):
Session 1:                        Session 2:
BEGIN TRAN                        BEGIN TRAN
SELECT ... [S lock]               SELECT ... [S lock]
-- Both have S locks (compatible)
UPDATE ... [wants X]              UPDATE ... [wants X]
-- DEADLOCK! Both waiting for other to release S lock

With Update Locks (No Deadlock):
Session 1:                        Session 2:
BEGIN TRAN                        BEGIN TRAN
SELECT ... WITH (UPDLOCK)         SELECT ... WITH (UPDLOCK)
[U lock acquired]                 [WAITING - U+U incompatible]
UPDATE ... [U→X conversion]       [Still waiting...]
COMMIT                            [Now can acquire U lock]
                                  UPDATE ...
                                  COMMIT

Update locks are incompatible with each other, so only one
transaction can acquire U lock, preventing circular dependency.
*/

-- Solution 2: Lock Compatibility Demo
CREATE TABLE #LockTest (ID INT, Value VARCHAR(50));
INSERT INTO #LockTest VALUES (1, 'Test');

-- Session 1: Shared lock
BEGIN TRANSACTION;
SELECT * FROM #LockTest WITH (HOLDLOCK);
PRINT 'Session 1: Shared lock acquired';
WAITFOR DELAY '00:00:10';
COMMIT;

-- Session 2: Another shared lock (COMPATIBLE - no wait)
/*
BEGIN TRANSACTION;
SELECT * FROM #LockTest WITH (HOLDLOCK);
PRINT 'Session 2: Shared lock acquired immediately';
COMMIT;
*/

-- Session 3: Exclusive lock (INCOMPATIBLE - waits)
/*
BEGIN TRANSACTION;
UPDATE #LockTest SET Value = 'Updated';
PRINT 'Session 3: Waiting for exclusive lock...';
COMMIT;
*/

DROP TABLE #LockTest;

-- Solution 3: Find Blocking Sessions
SELECT 
    blocked.session_id AS Blocked_SPID,
    blocking.session_id AS Blocking_SPID,
    blocked.wait_time / 1000 AS Wait_Seconds,
    blocked.wait_type,
    blocked.last_wait_type,
    DB_NAME(blocked.database_id) AS DatabaseName,
    blocking_text.text AS Blocking_Query,
    blocked_text.text AS Blocked_Query
FROM sys.dm_exec_requests blocked
INNER JOIN sys.dm_exec_requests blocking
    ON blocked.blocking_session_id = blocking.session_id
CROSS APPLY sys.dm_exec_sql_text(blocking.sql_handle) blocking_text
CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_text
WHERE blocked.blocking_session_id <> 0;

-- Solution 4: See Example 6.2 and 6.3

-- Solution 5: NOLOCK Usage
/*
WHEN TO USE NOLOCK:
✓ Reporting queries where approximate data is acceptable
✓ Dashboard metrics where speed > accuracy
✓ Historical data analysis
✓ Non-critical data previews

WHEN NOT TO USE NOLOCK:
✗ Financial transactions
✗ Inventory systems
✗ User-facing calculations
✗ Compliance reports
✗ Data that could show:
  - Uncommitted changes (dirty reads)
  - Duplicate rows
  - Missing rows
  - Inconsistent aggregates

Example of NOLOCK danger:
SELECT SUM(Balance) FROM Accounts WITH (NOLOCK);
-- Might include uncommitted transactions that get rolled back
-- Report shows $1M, actual balance is $800K
*/


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ LOCK TYPES:
  • Shared (S): Reading data
  • Exclusive (X): Modifying data
  • Update (U): Reading with intent to update
  • Intent (IS, IX, IU): Hierarchical locking

✓ LOCK COMPATIBILITY:
  • Multiple S locks: Compatible
  • S + U locks: Compatible
  • U + U locks: Incompatible
  • X + anything: Incompatible

✓ LOCK DURATION:
  • Depends on isolation level
  • Can be controlled with hints
  • Should be minimized

✓ DEADLOCKS:
  • Circular lock dependencies
  • SQL Server detects and resolves
  • One transaction chosen as victim
  • Preventable with proper design

✓ LOCK HINTS:
  • NOLOCK: Fast but risky
  • HOLDLOCK: Longer duration
  • UPDLOCK: Prevent deadlocks
  • TABLOCK: Table-level locking

✓ BEST PRACTICES:
  • Keep transactions short
  • Access resources in consistent order
  • Use appropriate isolation levels
  • Monitor and tune locking
  • Implement deadlock retry logic

✓ MONITORING:
  • sys.dm_tran_locks: Current locks
  • sys.dm_exec_requests: Blocking
  • sys.dm_os_waiting_tasks: Lock waits
  • Error log: Deadlock graphs

============================================================================
NEXT: Lesson 12.03 - Lock Granularities
Learn about row, page, and table-level locks.
============================================================================
*/
