# Chapter 12: Transactions

## Overview
Master database transactions and concurrency control in SQL Server. Learn how to ensure data integrity, handle multi-user environments, implement locking strategies, and use ACID properties to maintain database consistency.

## Learning Objectives
By the end of this chapter, you will be able to:
- Understand multi-user database challenges
- Implement proper locking mechanisms
- Work with different lock granularities
- Define and use transactions effectively
- Start, commit, and rollback transactions
- Use savepoints for partial rollbacks
- Handle transaction isolation levels
- Prevent common concurrency issues

## Chapter Contents

### 01. Multiuser Databases
- Concurrent access challenges
- Race conditions
- Lost updates problem
- Dirty reads
- Non-repeatable reads
- Phantom reads
- Importance of concurrency control

**Key Concepts:**
- Multi-user scenarios
- Concurrency anomalies
- Data integrity issues
- Need for transactions

### 02. Locking
- Purpose of locking
- Shared locks (S)
- Exclusive locks (X)
- Update locks (U)
- Intent locks
- Lock compatibility matrix
- Lock duration
- Deadlocks

**Key Concepts:**
- Lock types
- Lock modes
- Lock compatibility
- Deadlock detection and resolution

### 03. Lock Granularities
- Row-level locks
- Page-level locks
- Table-level locks
- Database-level locks
- Lock escalation
- Performance implications
- Choosing appropriate granularity

**Key Concepts:**
- Granularity levels
- Lock escalation
- Performance vs. concurrency trade-offs

### 04. What is a Transaction
- ACID properties
  - Atomicity
  - Consistency
  - Isolation
  - Durability
- Transaction boundaries
- Transaction states
- Transaction log
- Real-world examples

**Key Concepts:**
- ACID compliance
- All-or-nothing execution
- Transaction lifecycle
- Write-ahead logging

### 05. Starting Transactions
- Implicit transactions
- Explicit transactions
- BEGIN TRANSACTION
- Transaction nesting
- @@TRANCOUNT
- Autocommit mode
- Transaction isolation levels
  - READ UNCOMMITTED
  - READ COMMITTED
  - REPEATABLE READ
  - SERIALIZABLE
  - SNAPSHOT

**Key Concepts:**
- Transaction initiation
- Isolation levels
- Transaction nesting
- Default behaviors

### 06. Ending Transactions
- COMMIT TRANSACTION
- ROLLBACK TRANSACTION
- Implicit rollback
- Transaction duration
- Error handling with transactions
- TRY...CATCH with transactions
- Best practices

**Key Concepts:**
- Successful completion
- Rollback scenarios
- Error handling
- Transaction cleanup

### 07. Transaction Savepoints
- SAVE TRANSACTION
- Partial rollbacks
- Savepoint naming
- Nested savepoints
- Use cases
- Performance considerations
- Best practices

**Key Concepts:**
- Savepoint creation
- Rolling back to savepoints
- Complex transaction management
- Long-running transactions

### 08. Test Your Knowledge
- Comprehensive assessment
- Multi-user scenarios
- Locking strategies
- Transaction implementation
- Error handling
- Performance optimization
- Real-world problems

## Quick Reference

### Transaction Commands
```sql
-- Start transaction
BEGIN TRANSACTION;
BEGIN TRAN;

-- Commit (save changes)
COMMIT TRANSACTION;
COMMIT TRAN;
COMMIT;

-- Rollback (undo changes)
ROLLBACK TRANSACTION;
ROLLBACK TRAN;
ROLLBACK;

-- Savepoint
SAVE TRANSACTION SavepointName;
SAVE TRAN SavepointName;

-- Rollback to savepoint
ROLLBACK TRANSACTION SavepointName;

-- Check transaction count
SELECT @@TRANCOUNT;

-- Set isolation level
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

### ACID Properties
| Property | Description |
|----------|-------------|
| **Atomicity** | All or nothing - entire transaction succeeds or fails |
| **Consistency** | Database moves from one valid state to another |
| **Isolation** | Concurrent transactions don't interfere |
| **Durability** | Committed changes are permanent |

### Isolation Levels
| Level | Dirty Reads | Non-Repeatable Reads | Phantom Reads |
|-------|-------------|----------------------|---------------|
| READ UNCOMMITTED | Yes | Yes | Yes |
| READ COMMITTED | No | Yes | Yes |
| REPEATABLE READ | No | No | Yes |
| SERIALIZABLE | No | No | No |
| SNAPSHOT | No | No | No |

### Lock Types
```sql
-- Shared lock (reading)
SELECT * FROM Orders WITH (HOLDLOCK);

-- Exclusive lock (writing)
UPDATE Orders SET Status = 'Shipped' WHERE OrderID = 1;

-- Update lock
SELECT * FROM Orders WITH (UPDLOCK) WHERE OrderID = 1;

-- Table lock
SELECT * FROM Orders WITH (TABLOCK);

-- No lock (dirty read)
SELECT * FROM Orders WITH (NOLOCK);
```

## Common Patterns

### Pattern 1: Basic Transaction
```sql
BEGIN TRANSACTION;

    UPDATE Accounts 
    SET Balance = Balance - 100 
    WHERE AccountID = 1;
    
    UPDATE Accounts 
    SET Balance = Balance + 100 
    WHERE AccountID = 2;
    
    IF @@ERROR = 0
        COMMIT TRANSACTION;
    ELSE
        ROLLBACK TRANSACTION;
```

### Pattern 2: Transaction with Error Handling
```sql
BEGIN TRY
    BEGIN TRANSACTION;
    
        -- Multiple operations
        INSERT INTO Orders (...) VALUES (...);
        UPDATE Inventory SET Quantity = Quantity - 1;
        
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Log or handle error
    THROW;
END CATCH
```

### Pattern 3: Savepoint Usage
```sql
BEGIN TRANSACTION;

    INSERT INTO Orders (...) VALUES (...);
    
    SAVE TRANSACTION AfterInsert;
    
    UPDATE Inventory SET Quantity = Quantity - 1;
    
    IF (SELECT Quantity FROM Inventory WHERE ProductID = 1) < 0
    BEGIN
        ROLLBACK TRANSACTION AfterInsert;
        -- Adjust and retry
    END
    
COMMIT TRANSACTION;
```

### Pattern 4: Isolation Level Setting
```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRANSACTION;

    SELECT Balance FROM Accounts WHERE AccountID = 1;
    
    -- Simulate processing time
    WAITFOR DELAY '00:00:05';
    
    -- Balance won't change even if other transactions update it
    SELECT Balance FROM Accounts WHERE AccountID = 1;
    
COMMIT TRANSACTION;
```

## Best Practices

### ✅ DO
- **Keep transactions short** - Minimize lock duration
- **Use appropriate isolation levels** - Balance consistency and performance
- **Handle errors properly** - Always use TRY...CATCH
- **Check @@TRANCOUNT** - Ensure proper nesting
- **Commit or rollback explicitly** - Don't rely on implicit behavior
- **Use savepoints for complex logic** - Enable partial rollbacks
- **Test concurrent scenarios** - Verify multi-user behavior
- **Monitor deadlocks** - Use SQL Profiler or Extended Events
- **Index appropriately** - Reduce lock contention

### ❌ DON'T
- **Don't hold locks unnecessarily** - Avoid long-running transactions
- **Don't use lower isolation when higher needed** - Can cause data corruption
- **Don't ignore transaction count** - Can cause nested transaction issues
- **Don't mix implicit and explicit** - Choose one approach
- **Don't forget to commit/rollback** - Always close transactions
- **Don't use NOLOCK carelessly** - Can read inconsistent data
- **Don't update without WHERE** - Locks entire table
- **Don't ignore deadlocks** - Implement retry logic
- **Don't nest transactions deeply** - Keep structure simple

## Performance Tips

1. **Minimize Transaction Scope**
   - Include only necessary operations
   - Move non-critical operations outside transaction

2. **Optimize Query Performance**
   - Use indexes effectively
   - Avoid table scans in transactions

3. **Choose Right Isolation Level**
   - READ UNCOMMITTED: Fastest, least consistent
   - READ COMMITTED: Default, good balance
   - REPEATABLE READ: Stronger consistency
   - SERIALIZABLE: Strongest, slowest
   - SNAPSHOT: No locks, uses versioning

4. **Batch Operations**
   - Process in smaller chunks
   - Commit periodically for long operations

5. **Avoid Deadlocks**
   - Access objects in same order
   - Keep transactions short
   - Use lower isolation levels when possible
   - Implement retry logic

## Common Pitfalls

### Pitfall 1: Uncommitted Transactions
```sql
-- BAD: Transaction left open
BEGIN TRANSACTION;
UPDATE Products SET Price = Price * 1.1;
-- Oops! Forgot to COMMIT
```

### Pitfall 2: Nested Transaction Confusion
```sql
-- CONFUSING: Nested transactions in SQL Server
BEGIN TRANSACTION;  -- @@TRANCOUNT = 1
    BEGIN TRANSACTION;  -- @@TRANCOUNT = 2
        UPDATE Products SET Price = 100;
    COMMIT;  -- @@TRANCOUNT = 1 (doesn't actually commit!)
ROLLBACK;  -- Rolls back everything!
```

### Pitfall 3: Deadlock Scenario
```sql
-- Session 1
BEGIN TRANSACTION;
UPDATE Orders SET Status = 'Processing' WHERE OrderID = 1;
-- Waiting...
UPDATE Customers SET LastOrder = GETDATE() WHERE CustomerID = 1;
COMMIT;

-- Session 2 (simultaneously)
BEGIN TRANSACTION;
UPDATE Customers SET Status = 'Active' WHERE CustomerID = 1;
-- Waiting...
UPDATE Orders SET Priority = 1 WHERE OrderID = 1;
COMMIT;
-- DEADLOCK! One transaction will be chosen as victim
```

### Pitfall 4: Long-Running Transaction
```sql
-- BAD: Holds locks too long
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Shipped';  -- Locks all rows
    WAITFOR DELAY '00:10:00';  -- Waits 10 minutes!
    UPDATE Products SET LastShipped = GETDATE();
COMMIT;
```

## Troubleshooting

### Check Active Transactions
```sql
-- View active transactions
SELECT * FROM sys.dm_tran_active_transactions;

-- Check locks
SELECT * FROM sys.dm_tran_locks;

-- See blocking
SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id > 0;
```

### Kill Blocking Session
```sql
-- Identify blocker
SELECT blocking_session_id, wait_type, wait_time
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

-- Kill blocking process (use carefully!)
KILL 53;  -- Replace with actual SPID
```

### Deadlock Information
```sql
-- Enable deadlock trace flag
DBCC TRACEON (1222, -1);

-- View deadlock graph in SQL Server Error Log
```

## Prerequisites
- Understanding of SELECT, INSERT, UPDATE, DELETE
- Knowledge of database constraints
- Familiarity with error handling
- Basic understanding of multi-user scenarios

## Estimated Time
- **Total Chapter:** 4-5 hours
- **Individual Lessons:** 25-40 minutes each
- **Test:** 90 minutes

## Next Steps
After completing this chapter, you should:
1. Practice implementing transactions in real scenarios
2. Experiment with different isolation levels
3. Understand your application's concurrency requirements
4. Learn about optimistic vs. pessimistic locking
5. Move to Chapter 13: Indexes and Constraints

## Additional Resources
- SQL Server Books Online: Transactions
- Microsoft Docs: Transaction Isolation Levels
- ACID Properties Deep Dive
- Deadlock Resolution Strategies
- Transaction Log Architecture

---

**Ready to begin?** Start with [Lesson 01: Multiuser Databases](01-multiuser-databases/01-multiuser-databases.sql)

**Need help?** Review prerequisite chapters on data modification and error handling.

**Quick test?** Jump to [Lesson 08: Test Your Knowledge](08-test-your-knowledge/08-test-your-knowledge.sql)
