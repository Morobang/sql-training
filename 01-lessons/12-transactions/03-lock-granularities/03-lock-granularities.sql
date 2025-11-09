/*
============================================================================
Lesson 12.03 - Lock Granularities
============================================================================

Description:
Master different levels of lock granularity in SQL Server. Learn about
row-level, page-level, table-level, and database-level locks. Understand
lock escalation, performance implications, and how to choose appropriate
granularity.

Topics Covered:
• Lock granularity levels
• Row-level locks
• Page-level locks
• Table-level locks
• Database-level locks
• Lock escalation
• Performance vs concurrency trade-offs
• Controlling granularity

Prerequisites:
• Lesson 12.02 (Locking)

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Lock Granularity
============================================================================
*/

-- Example 1.1: Lock Granularity Hierarchy
/*
LOCK GRANULARITY LEVELS (from finest to coarsest):

Database
   ↓
Table (or Heap/B-Tree)
   ↓
Extent (8 pages = 64 KB)
   ↓
Page (8 KB)
   ↓
Row (or Index Key)

┌─────────────────────────────────────────────────────────────┐
│                      GRANULARITY TRADE-OFFS                 │
├─────────────────┬───────────────────┬───────────────────────┤
│   Granularity   │   Concurrency     │    Overhead          │
├─────────────────┼───────────────────┼───────────────────────┤
│ ROW             │ High (many users) │ High (many locks)    │
│ PAGE            │ Medium            │ Medium               │
│ TABLE           │ Low (one user)    │ Low (one lock)       │
│ DATABASE        │ Very Low          │ Very Low             │
└─────────────────┴───────────────────┴───────────────────────┘

PRINCIPLE:
Finer granularity → Higher concurrency but more overhead
Coarser granularity → Lower concurrency but less overhead
*/

-- Example 1.2: Why Granularity Matters
/*
SCENARIO: 100 users updating different rows in same table

WITH ROW-LEVEL LOCKS:
┌──────────────────────────────────────┐
│ User 1 → Row 1 [X]                   │
│ User 2 → Row 2 [X]                   │
│ User 3 → Row 3 [X]                   │
│ ...                                  │
│ User 100 → Row 100 [X]               │
└──────────────────────────────────────┘
Result: All users work simultaneously (high concurrency)
Overhead: 100 locks to manage

WITH TABLE-LEVEL LOCK:
┌──────────────────────────────────────┐
│ User 1 → Entire Table [X]            │
│ User 2 → WAITING...                  │
│ User 3 → WAITING...                  │
│ ...                                  │
│ User 100 → WAITING...                │
└──────────────────────────────────────┘
Result: Users wait in queue (low concurrency)
Overhead: 1 lock to manage (efficient)
*/


/*
============================================================================
PART 2: Row-Level Locks
============================================================================
*/

-- Example 2.1: Row-Level Locking
CREATE TABLE #CustomerData (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100),
    Balance DECIMAL(10,2)
);

INSERT INTO #CustomerData VALUES
(1, 'Alice', 1000),
(2, 'Bob', 2000),
(3, 'Charlie', 3000),
(4, 'David', 4000);

-- Update single row (row-level lock)
BEGIN TRANSACTION;
    UPDATE #CustomerData 
    SET Balance = Balance + 100 
    WHERE CustomerID = 1;
    -- Only Row 1 is locked
    
    -- Check lock granularity
    SELECT 
        resource_type,
        resource_description,
        request_mode,
        request_status
    FROM sys.dm_tran_locks
    WHERE resource_database_id = DB_ID()
    AND request_session_id = @@SPID
    AND resource_type IN ('RID', 'KEY', 'PAGE', 'OBJECT');
    
COMMIT TRANSACTION;

-- Example 2.2: Forcing Row-Level Locks
BEGIN TRANSACTION;
    -- Explicit row-level lock hint
    UPDATE #CustomerData WITH (ROWLOCK)
    SET Balance = Balance + 50
    WHERE CustomerID IN (1, 2);
    
    -- Check locks
    SELECT 
        resource_type,
        request_mode
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    AND resource_type = 'RID';
    
COMMIT TRANSACTION;

-- Example 2.3: Row Lock Advantages
/*
ADVANTAGES OF ROW-LEVEL LOCKS:
✓ Maximum concurrency
✓ Minimal blocking
✓ Different users can modify different rows simultaneously
✓ Ideal for OLTP (Online Transaction Processing)

DISADVANTAGES:
✗ Higher memory overhead (many locks)
✗ More CPU for lock management
✗ Can escalate to page/table locks
*/


/*
============================================================================
PART 3: Page-Level Locks
============================================================================
*/

-- Example 3.1: Page-Level Locking
/*
PAGE:
• Fixed size: 8 KB (8,192 bytes)
• Contains multiple rows
• Locking a page locks all rows on that page

Page Structure:
┌─────────────────────────────────────┐
│ Page Header (96 bytes)              │
├─────────────────────────────────────┤
│ Row 1                               │
│ Row 2                               │
│ Row 3                               │
│ ...                                 │
│ Row N                               │
├─────────────────────────────────────┤
│ Row Offset Array                    │
└─────────────────────────────────────┘

Locking the page locks ALL rows on it!
*/

-- Example 3.2: Forcing Page-Level Locks
BEGIN TRANSACTION;
    -- Explicit page-level lock hint
    UPDATE #CustomerData WITH (PAGLOCK)
    SET Balance = Balance + 25
    WHERE CustomerID = 1;
    
    -- Check locks
    SELECT 
        resource_type,
        resource_description,
        request_mode
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    AND resource_type IN ('PAGE', 'OBJECT');
    
COMMIT TRANSACTION;

-- Example 3.3: Page Lock Impact
/*
SCENARIO: Page contains rows 1-10

User A updates row 1:
┌──────────────────────────────────┐
│ Page 1 [X]                       │
│   Row 1  (being modified)        │
│   Row 2  (also locked!)          │
│   Row 3  (also locked!)          │
│   ...                            │
│   Row 10 (also locked!)          │
└──────────────────────────────────┘

User B tries to update row 5:
Must WAIT even though modifying different row!

ADVANTAGES:
✓ Less overhead than row locks
✓ Good for range scans

DISADVANTAGES:
✗ Locks more than necessary
✗ Reduces concurrency
*/


/*
============================================================================
PART 4: Table-Level Locks
============================================================================
*/

-- Example 4.1: Table-Level Locking
BEGIN TRANSACTION;
    -- Explicit table-level lock
    SELECT * FROM #CustomerData WITH (TABLOCK);
    
    -- Check locks
    SELECT 
        resource_type,
        resource_description,
        request_mode
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    AND resource_type = 'OBJECT';
    
COMMIT TRANSACTION;

-- Example 4.2: Exclusive Table Lock
BEGIN TRANSACTION;
    -- Exclusive table lock
    SELECT * FROM #CustomerData WITH (TABLOCKX);
    
    -- Entire table is exclusively locked
    -- No other users can read or write!
    
    WAITFOR DELAY '00:00:05';
    
COMMIT TRANSACTION;

-- Example 4.3: When Table Locks Are Used
/*
AUTOMATIC TABLE LOCKS:
• Bulk operations (BULK INSERT, SELECT INTO)
• Table scans on small tables
• ALTER TABLE, DROP TABLE
• TRUNCATE TABLE
• Some aggregate queries

MANUAL TABLE LOCKS:
• WITH (TABLOCK) - shared table lock
• WITH (TABLOCKX) - exclusive table lock

ADVANTAGES:
✓ Minimal overhead
✓ Fast for bulk operations
✓ Simple lock management

DISADVANTAGES:
✗ Blocks all other users
✗ Poor concurrency
✗ Not suitable for OLTP
*/

-- Example 4.4: Table Lock Scenarios
-- Bulk insert with table lock
BEGIN TRANSACTION;
    -- Acquire exclusive table lock for bulk operation
    SELECT * FROM #CustomerData WITH (TABLOCKX);
    
    -- Fast bulk insert (no row-by-row locking)
    INSERT INTO #CustomerData 
    SELECT CustomerID + 100, 'User' + CAST(CustomerID AS VARCHAR), 1000
    FROM #CustomerData
    WHERE CustomerID <= 4;
    
COMMIT TRANSACTION;

SELECT * FROM #CustomerData;


/*
============================================================================
PART 5: Lock Escalation
============================================================================
*/

-- Example 5.1: What is Lock Escalation?
/*
LOCK ESCALATION:
Automatic conversion of many fine-grained locks to fewer coarse-grained locks

Process:
┌──────────────────────────────────────────────────────────┐
│ 1. Transaction acquires many row locks                  │
│    Row 1 [X], Row 2 [X], Row 3 [X], ... Row 5000 [X]   │
│                                                          │
│ 2. Lock count exceeds threshold (~5000 locks)           │
│                                                          │
│ 3. SQL Server escalates to table lock                   │
│    Entire Table [X]                                     │
│                                                          │
│ 4. Individual row locks released                        │
└──────────────────────────────────────────────────────────┘

ESCALATION TRIGGERS:
• More than 5,000 locks on a single table
• Memory pressure
• Lock memory exceeds 40% of buffer pool
*/

-- Example 5.2: Demonstrating Lock Escalation
CREATE TABLE #LargeTable (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Value VARCHAR(100)
);

-- Insert many rows
INSERT INTO #LargeTable (Value)
SELECT TOP 10000 'Data' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR)
FROM sys.objects a CROSS JOIN sys.objects b;

-- Update many rows (may trigger escalation)
BEGIN TRANSACTION;
    UPDATE #LargeTable 
    SET Value = Value + '_Updated'
    WHERE ID <= 6000;  -- Updating 6000 rows
    
    -- Check if escalated to table lock
    SELECT 
        resource_type,
        COUNT(*) AS LockCount
    FROM sys.dm_tran_locks
    WHERE request_session_id = @@SPID
    AND resource_database_id = DB_ID()
    GROUP BY resource_type;
    
COMMIT TRANSACTION;

DROP TABLE #LargeTable;

-- Example 5.3: Controlling Lock Escalation
-- Disable lock escalation on table
CREATE TABLE #NoEscalation (
    ID INT,
    Value VARCHAR(100)
);

ALTER TABLE #NoEscalation 
SET (LOCK_ESCALATION = DISABLE);

-- Check setting
SELECT 
    name,
    lock_escalation_desc
FROM sys.tables
WHERE name = '#NoEscalation';

-- Options:
-- TABLE (default) - escalate to table level
-- AUTO - escalate to partition level (if partitioned) or table
-- DISABLE - prevent escalation

DROP TABLE #NoEscalation;

-- Example 5.4: Lock Escalation Impact
/*
BEFORE ESCALATION:
User A: Updating rows 1-6000
User B: Can still read/update rows 6001-10000 ✓

AFTER ESCALATION:
User A: Holds table lock
User B: BLOCKED on entire table ✗

MANAGING ESCALATION:
1. Batch large updates (commit in chunks)
2. Use ROWLOCK hint (prevents escalation)
3. Disable escalation on table
4. Partition large tables
5. Increase lock memory
*/


/*
============================================================================
PART 6: Performance vs Concurrency Trade-offs
============================================================================
*/

-- Example 6.1: Scenario Analysis
/*
SCENARIO 1: High-Concurrency OLTP System
Requirements:
• 1000s of users
• Short transactions
• Updating different rows

Best Choice: ROW-LEVEL LOCKS
┌────────────────────────────────────┐
│ User 1 → Row 15 [X]                │
│ User 2 → Row 892 [X]               │
│ User 3 → Row 43 [X]                │
│ User 4 → Row 1567 [X]              │
└────────────────────────────────────┘
Result: All users work simultaneously

SCENARIO 2: Batch Data Warehouse Load
Requirements:
• Single process
• Bulk insert millions of rows
• No concurrent access needed

Best Choice: TABLE-LEVEL LOCKS
┌────────────────────────────────────┐
│ ETL Process → Entire Table [X]    │
│ (Inserting 1M rows)                │
└────────────────────────────────────┘
Result: Fastest load, no lock overhead

SCENARIO 3: Reporting Query
Requirements:
• Read-only
• Scan entire table
• Can tolerate dirty reads

Best Choice: NOLOCK (no locks)
┌────────────────────────────────────┐
│ Report → Table (no locks)          │
│ (Reads uncommitted data)           │
└────────────────────────────────────┘
Result: Fastest query, doesn't block writers
*/

-- Example 6.2: Benchmarking Different Granularities
CREATE TABLE #BenchmarkData (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Value VARCHAR(100)
);

INSERT INTO #BenchmarkData (Value)
SELECT TOP 1000 'Data'
FROM sys.objects;

-- Test 1: Row-level locks
DECLARE @Start1 DATETIME = GETDATE();
BEGIN TRANSACTION;
    UPDATE #BenchmarkData WITH (ROWLOCK)
    SET Value = Value + '_1';
COMMIT;
DECLARE @End1 DATETIME = GETDATE();
PRINT 'Row locks: ' + CAST(DATEDIFF(MILLISECOND, @Start1, @End1) AS VARCHAR) + ' ms';

-- Test 2: Page-level locks
DECLARE @Start2 DATETIME = GETDATE();
BEGIN TRANSACTION;
    UPDATE #BenchmarkData WITH (PAGLOCK)
    SET Value = Value + '_2';
COMMIT;
DECLARE @End2 DATETIME = GETDATE();
PRINT 'Page locks: ' + CAST(DATEDIFF(MILLISECOND, @Start2, @End2) AS VARCHAR) + ' ms';

-- Test 3: Table-level locks
DECLARE @Start3 DATETIME = GETDATE();
BEGIN TRANSACTION;
    UPDATE #BenchmarkData WITH (TABLOCK)
    SET Value = Value + '_3';
COMMIT;
DECLARE @End3 DATETIME = GETDATE();
PRINT 'Table locks: ' + CAST(DATEDIFF(MILLISECOND, @Start3, @End3) AS VARCHAR) + ' ms';

DROP TABLE #BenchmarkData;


/*
============================================================================
PART 7: Choosing Appropriate Granularity
============================================================================
*/

-- Example 7.1: Decision Matrix
/*
LOCK GRANULARITY DECISION GUIDE:

┌──────────────────┬─────────────┬──────────────┬─────────────┐
│   Scenario       │   Users     │   Operation  │  Granularity│
├──────────────────┼─────────────┼──────────────┼─────────────┤
│ OLTP Insert      │ Many        │ Single row   │ ROW         │
│ OLTP Update      │ Many        │ Few rows     │ ROW         │
│ Batch Update     │ One         │ Many rows    │ PAGE/TABLE  │
│ Bulk Insert      │ One         │ Many rows    │ TABLE       │
│ Index Rebuild    │ One         │ Entire table │ TABLE       │
│ Quick Lookup     │ Many        │ Single row   │ ROW         │
│ Range Scan       │ Many        │ Many rows    │ PAGE        │
│ Full Table Scan  │ One         │ All rows     │ TABLE       │
└──────────────────┴─────────────┴──────────────┴─────────────┘
*/

-- Example 7.2: Applying Granularity Hints
-- OLTP transaction (use row locks)
BEGIN TRANSACTION;
    UPDATE #CustomerData WITH (ROWLOCK)
    SET Balance = Balance - 100
    WHERE CustomerID = 1;
COMMIT;

-- Batch operation (use table lock)
BEGIN TRANSACTION;
    UPDATE #CustomerData WITH (TABLOCK)
    SET Balance = Balance * 1.05;  -- 5% increase for all
COMMIT;

-- Range update (use page locks)
BEGIN TRANSACTION;
    UPDATE #CustomerData WITH (PAGLOCK)
    SET Balance = Balance + 10
    WHERE CustomerID BETWEEN 1 AND 2;
COMMIT;

-- Example 7.3: Dynamic Granularity Selection
CREATE PROCEDURE UpdateCustomerBalances
    @CustomerID INT = NULL,
    @BulkUpdate BIT = 0
AS
BEGIN
    IF @BulkUpdate = 1
    BEGIN
        -- Bulk operation: use table lock
        BEGIN TRANSACTION;
            UPDATE #CustomerData WITH (TABLOCK)
            SET Balance = Balance + 100;
        COMMIT;
    END
    ELSE IF @CustomerID IS NOT NULL
    BEGIN
        -- Single customer: use row lock
        BEGIN TRANSACTION;
            UPDATE #CustomerData WITH (ROWLOCK)
            SET Balance = Balance + 100
            WHERE CustomerID = @CustomerID;
        COMMIT;
    END
    ELSE
    BEGIN
        -- Multiple customers: default (let SQL decide)
        BEGIN TRANSACTION;
            UPDATE #CustomerData
            SET Balance = Balance + 100;
        COMMIT;
    END
END;

-- Cleanup
DROP TABLE #CustomerData;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Explain when row-level locks are better than table-level locks
2. Describe lock escalation and how to prevent it
3. Design a scenario where page-level locks are optimal
4. Write queries to monitor lock granularity in real-time
5. Create a strategy for choosing lock granularity in different scenarios

Solutions below ↓
*/

-- Solution 1: Row vs Table Locks
/*
ROW-LEVEL LOCKS ARE BETTER WHEN:
✓ High concurrent user activity
✓ Users modifying different rows
✓ OLTP workload (many small transactions)
✓ Need maximum concurrency
✓ Examples:
  - E-commerce checkout (different customers)
  - Banking transactions (different accounts)
  - Ticket booking (different seats)

TABLE-LEVEL LOCKS ARE BETTER WHEN:
✓ Single-user or batch operations
✓ Modifying large percentage of rows
✓ Bulk data loads
✓ Maintenance operations
✓ Examples:
  - Nightly ETL process
  - Index rebuild
  - Mass price update
  - Data archival

RULE OF THUMB:
If updating > 20% of table rows → Consider table lock
If updating < 1% of table rows → Use row locks
*/

-- Solution 2: Lock Escalation Management
/*
LOCK ESCALATION EXPLAINED:
• Threshold: ~5,000 locks per table
• Reason: Reduce memory consumption
• Process: Row/Page locks → Table lock
• Impact: Reduced concurrency

PREVENTION STRATEGIES:

1. Batch Processing:
*/
DECLARE @BatchSize INT = 1000;
WHILE EXISTS (SELECT 1 FROM #LargeTable WHERE Processed = 0)
BEGIN
    BEGIN TRANSACTION;
        UPDATE TOP (@BatchSize) #LargeTable
        SET Processed = 1
        WHERE Processed = 0;
    COMMIT;
END;
/*

2. Disable Escalation:
*/
ALTER TABLE MyTable SET (LOCK_ESCALATION = DISABLE);
/*

3. Use ROWLOCK Hint:
*/
UPDATE MyTable WITH (ROWLOCK)
SET Column = Value;
/*

4. Partition Large Tables:
*/
-- Partitioning spreads locks across partitions
CREATE PARTITION FUNCTION pf_Range (INT)
AS RANGE RIGHT FOR VALUES (1000, 2000, 3000);
/*

5. Increase Lock Memory:
*/
sp_configure 'locks', 0;  -- 0 = dynamic allocation
/*
*/

-- Solution 3: Page-Level Lock Scenario
/*
OPTIMAL PAGE-LEVEL LOCK SCENARIO:

Scenario: Customer Service Application
• Representatives update customer records in batches
• Records are geographically clustered (sorted by ZIP code)
• Processing 10-50 customers in same area

Table Design:
*/
CREATE TABLE Customers (
    CustomerID INT,
    ZipCode VARCHAR(10),
    -- Clustered index on ZipCode
    INDEX IX_Zip CLUSTERED (ZipCode)
);
/*

Query Pattern:
*/
-- Update customers in same ZIP (likely on same pages)
BEGIN TRANSACTION;
    UPDATE Customers WITH (PAGLOCK)
    SET LastContactDate = GETDATE()
    WHERE ZipCode = '12345';
    -- All affected rows likely on 1-2 pages
COMMIT;
/*

Why Page Locks Are Optimal:
✓ Records geographically clustered on same pages
✓ Updating multiple rows on same page
✓ Less overhead than row locks (fewer locks)
✓ Better than table lock (other ZIPs can be updated)
*/

-- Solution 4: Monitor Lock Granularity
-- Real-time lock monitoring
SELECT 
    CASE resource_type
        WHEN 'RID' THEN 'Row (Heap)'
        WHEN 'KEY' THEN 'Row (Index)'
        WHEN 'PAGE' THEN 'Page'
        WHEN 'OBJECT' THEN 'Table'
        WHEN 'DATABASE' THEN 'Database'
        ELSE resource_type
    END AS LockGranularity,
    request_mode AS LockMode,
    COUNT(*) AS LockCount,
    SUM(CASE WHEN request_status = 'WAIT' THEN 1 ELSE 0 END) AS WaitingLocks
FROM sys.dm_tran_locks
WHERE resource_database_id = DB_ID()
GROUP BY resource_type, request_mode
ORDER BY LockCount DESC;

-- Lock escalation events
SELECT 
    object_name(object_id) AS TableName,
    escalated_lock_count
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL)
WHERE escalated_lock_count > 0;

-- Solution 5: Lock Granularity Strategy
/*
LOCK GRANULARITY STRATEGY FRAMEWORK:

1. ANALYZE WORKLOAD:
   - Number of concurrent users
   - Transaction size (rows affected)
   - Read vs write ratio
   - Transaction duration

2. CLASSIFY OPERATIONS:
   
   OLTP Operations → ROW LOCKS
   • Point lookups
   • Single-row updates
   • High concurrency
   
   Reporting Queries → NOLOCK or low isolation
   • Read-only
   • Can tolerate dirty reads
   • Don't block writers
   
   Batch Operations → TABLE LOCKS
   • Bulk inserts
   • Mass updates
   • Maintenance
   
   Range Operations → PAGE LOCKS
   • Range updates on clustered data
   • Moderate concurrency

3. IMPLEMENT HINTS:
*/
-- OLTP
UPDATE Orders WITH (ROWLOCK) 
SET Status = 'Shipped' 
WHERE OrderID = @OrderID;

-- Batch
INSERT INTO ArchiveTable WITH (TABLOCK)
SELECT * FROM ProductionTable 
WHERE ArchiveDate < @CutoffDate;

-- Range
UPDATE Products WITH (PAGLOCK)
SET Price = Price * 1.1
WHERE CategoryID = @CategoryID;
/*

4. MONITOR AND TUNE:
   - Watch for lock escalation
   - Monitor blocking
   - Adjust isolation levels
   - Partition large tables if needed

5. TEST CONCURRENCY:
   - Simulate concurrent users
   - Measure blocking time
   - Verify data integrity
   - Optimize as needed
*/


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ LOCK GRANULARITY LEVELS:
  • Row: Finest, highest concurrency
  • Page: Medium granularity (8 KB)
  • Table: Coarsest, lowest concurrency
  • Database: Entire database

✓ TRADE-OFFS:
  • Fine granularity: High concurrency, high overhead
  • Coarse granularity: Low concurrency, low overhead
  • Balance based on workload

✓ ROW-LEVEL LOCKS:
  • Best for OLTP
  • Maximum concurrency
  • Higher memory usage
  • Use ROWLOCK hint

✓ PAGE-LEVEL LOCKS:
  • 8 KB units
  • Good for range operations
  • Medium concurrency
  • Use PAGLOCK hint

✓ TABLE-LEVEL LOCKS:
  • Entire table locked
  • Best for bulk operations
  • Minimal overhead
  • Use TABLOCK/TABLOCKX hint

✓ LOCK ESCALATION:
  • Automatic: rows/pages → table
  • Threshold: ~5,000 locks
  • Can disable per table
  • Batch to prevent

✓ CHOOSING GRANULARITY:
  • OLTP: Row locks
  • Batch: Table locks
  • Range: Page locks
  • Monitor and adjust

✓ BEST PRACTICES:
  • Use appropriate hints
  • Batch large operations
  • Monitor escalation
  • Partition large tables
  • Test concurrency scenarios

============================================================================
NEXT: Lesson 12.04 - What is a Transaction
Learn about ACID properties and transaction fundamentals.
============================================================================
*/
