# Lesson 9: Transactions Deep Dive

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Master ACID properties in practice
2. Use isolation levels strategically
3. Prevent deadlocks and handle them gracefully
4. Use savepoints for partial rollbacks
5. Understand locking and blocking
6. Implement transaction best practices

---

## Part 1: ACID Properties Deep Dive

### Atomicity
All operations in a transaction succeed or all fail.

```sql
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;
    -- Both succeed or both roll back
COMMIT TRANSACTION;
```

### Consistency
Database moves from one valid state to another.

```sql
-- Constraint enforces consistency
ALTER TABLE Accounts ADD CONSTRAINT CK_Balance CHECK (Balance >= 0);

BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 200 WHERE AccountID = 1;
    -- If balance goes negative, constraint violation → ROLLBACK
COMMIT TRANSACTION;
```

### Isolation
Concurrent transactions don't interfere.

### Durability
Committed changes persist (survive crashes).

---

## Part 2: Isolation Levels

Control how transactions interact with each other.

### READ UNCOMMITTED (Lowest Isolation)

```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Orders;  -- May read uncommitted (dirty) data
COMMIT;
```

**Problems:**
- **Dirty reads**: Read uncommitted changes from other transactions
- **Non-repeatable reads**: Same query returns different results
- **Phantom reads**: Rows appear/disappear between reads

**Use case:** Reporting where approximate data is acceptable

### READ COMMITTED (Default)

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM Orders;  -- Only reads committed data
COMMIT;
```

**Prevents:** Dirty reads  
**Allows:** Non-repeatable reads, phantom reads

### REPEATABLE READ

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM Orders WHERE CustomerID = 100;
    -- Other transactions can't modify these rows until commit
    WAITFOR DELAY '00:00:05';
    SELECT * FROM Orders WHERE CustomerID = 100;  -- Same results
COMMIT;
```

**Prevents:** Dirty reads, non-repeatable reads  
**Allows:** Phantom reads (new rows can be inserted)

### SERIALIZABLE (Highest Isolation)

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM Orders WHERE CustomerID = 100;
    -- Locks entire range, prevents inserts
    WAITFOR DELAY '00:00:05';
    SELECT * FROM Orders WHERE CustomerID = 100;  -- Identical results
COMMIT;
```

**Prevents:** All concurrency issues  
**Cost:** Highest locking, lowest concurrency

### SNAPSHOT (Optimistic)

```sql
-- Enable snapshot isolation (database level)
ALTER DATABASE YourDB SET ALLOW_SNAPSHOT_ISOLATION ON;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
    SELECT * FROM Orders;  -- Reads snapshot from start of transaction
COMMIT;
```

**Benefits:**
- No read locks (writers don't block readers)
- Consistent view of data
- Uses row versioning in tempdb

---

## Part 3: Deadlocks

Two transactions wait for each other, creating a cycle.

### Deadlock Example

```sql
-- Transaction 1
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processed' WHERE OrderID = 1;
    WAITFOR DELAY '00:00:02';
    UPDATE Customers SET Points = Points + 10 WHERE CustomerID = 1;
COMMIT;

-- Transaction 2 (runs simultaneously)
BEGIN TRANSACTION;
    UPDATE Customers SET Points = Points + 5 WHERE CustomerID = 1;  -- Waits for T1
    WAITFOR DELAY '00:00:02';
    UPDATE Orders SET Status = 'Shipped' WHERE OrderID = 1;  -- Waits for T1 → DEADLOCK
COMMIT;
```

### Preventing Deadlocks

1. **Access resources in same order**
```sql
-- Both transactions update Orders first, then Customers
```

2. **Keep transactions short**
```sql
BEGIN TRANSACTION;
    -- Do work quickly
    UPDATE ...
COMMIT;  -- Release locks ASAP
```

3. **Use appropriate isolation level**
```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

4. **Handle deadlocks gracefully**
```sql
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE Orders SET Status = 'Processed' WHERE OrderID = 1;
        UPDATE Customers SET Points = Points + 10 WHERE CustomerID = 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    IF ERROR_NUMBER() = 1205  -- Deadlock error
    BEGIN
        WAITFOR DELAY '00:00:01';  -- Wait briefly
        -- Retry logic here
    END
    ELSE
        THROW;
END CATCH;
```

---

## Part 4: Savepoints

Create checkpoints within a transaction for partial rollbacks.

```sql
BEGIN TRANSACTION;
    INSERT INTO Orders (CustomerID, OrderDate) VALUES (1, GETDATE());
    SAVE TRANSACTION SavePoint1;
    
    INSERT INTO OrderDetails (OrderID, ProductID, Quantity) VALUES (1, 10, 2);
    -- Error occurs
    
    ROLLBACK TRANSACTION SavePoint1;  -- Rolls back to savepoint
    -- Orders insert preserved, OrderDetails rolled back
COMMIT TRANSACTION;
```

---

## Part 5: Locking and Blocking

### Lock Types

- **Shared (S)**: Read lock (multiple allowed)
- **Exclusive (X)**: Write lock (blocks all)
- **Update (U)**: Intent to update
- **Intent locks**: Table-level hints

### Viewing Locks

```sql
-- See active locks
SELECT 
    resource_type,
    resource_database_id,
    resource_associated_entity_id,
    request_mode,
    request_status
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;
```

### Handling Blocking

```sql
-- Find blocking sessions
SELECT 
    blocking_session_id,
    session_id,
    wait_type,
    wait_time,
    wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

-- Kill blocking session (use cautiously!)
KILL 52;  -- session_id
```

---

## Part 6: Transaction Best Practices

### 1. Keep Transactions Short
```sql
-- BAD: Long-running transaction
BEGIN TRANSACTION;
    SELECT * FROM LargeTable;  -- Long query
    -- User input/processing
    UPDATE Orders SET Status = 'Processed';
COMMIT;

-- GOOD: Minimal time in transaction
-- Do work outside transaction
SELECT * FROM LargeTable;
-- Process data
BEGIN TRANSACTION;
    UPDATE Orders SET Status = 'Processed';  -- Quick
COMMIT;
```

### 2. Avoid User Interaction
```sql
-- BAD
BEGIN TRANSACTION;
    UPDATE Inventory SET Quantity = Quantity - 1;
    -- Wait for user to confirm
COMMIT;

-- GOOD
-- Get user confirmation first
BEGIN TRANSACTION;
    UPDATE Inventory SET Quantity = Quantity - 1;
COMMIT;  -- Immediate
```

### 3. Handle Errors
```sql
BEGIN TRY
    BEGIN TRANSACTION;
        -- Operations
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

### 4. Use Appropriate Isolation Level
```sql
-- Don't always use SERIALIZABLE
-- Choose based on requirements:
-- - READ UNCOMMITTED: Fast, approximate reads
-- - READ COMMITTED: Default, good balance
-- - SNAPSHOT: No read locks, uses tempdb
```

---

## Part 7: Practical Examples

### Example 1: Money Transfer

```sql
CREATE PROCEDURE usp_TransferFunds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check sufficient funds
        DECLARE @FromBalance DECIMAL(10,2);
        SELECT @FromBalance = Balance FROM Accounts WHERE AccountID = @FromAccount;
        
        IF @FromBalance < @Amount
            THROW 50001, 'Insufficient funds', 1;
        
        -- Debit
        UPDATE Accounts SET Balance = Balance - @Amount WHERE AccountID = @FromAccount;
        
        -- Credit
        UPDATE Accounts SET Balance = Balance + @Amount WHERE AccountID = @ToAccount;
        
        -- Log transaction
        INSERT INTO TransactionLog (FromAccount, ToAccount, Amount, TransactionDate)
        VALUES (@FromAccount, @ToAccount, @Amount, GETDATE());
        
        COMMIT TRANSACTION;
        PRINT 'Transfer successful';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
```

### Example 2: Batch Processing with Savepoints

```sql
BEGIN TRANSACTION;
DECLARE @Counter INT = 1;

WHILE @Counter <= 1000
BEGIN
    SAVE TRANSACTION BatchSavepoint;
    
    BEGIN TRY
        -- Process record
        UPDATE Orders SET Status = 'Processed' WHERE OrderID = @Counter;
        
        SET @Counter = @Counter + 1;
    END TRY
    BEGIN CATCH
        -- Roll back this record only, continue with next
        ROLLBACK TRANSACTION BatchSavepoint;
        SET @Counter = @Counter + 1;
    END CATCH;
END;

COMMIT TRANSACTION;
```

---

## Part 8: Monitoring Transactions

```sql
-- Active transactions
SELECT 
    s.session_id,
    s.login_name,
    t.transaction_id,
    t.transaction_begin_time,
    DATEDIFF(SECOND, t.transaction_begin_time, GETDATE()) AS duration_sec
FROM sys.dm_tran_active_transactions t
INNER JOIN sys.dm_tran_session_transactions st ON t.transaction_id = st.transaction_id
INNER JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id;
```

---

## Practice Exercises

1. Create a transaction that transfers inventory between warehouses with proper error handling.
2. Demonstrate the difference between READ COMMITTED and SERIALIZABLE isolation.
3. Create a scenario that causes a deadlock, then fix it.
4. Use savepoints to partially roll back a multi-step operation.

---

## Key Takeaways

- ACID guarantees data integrity
- Isolation levels balance consistency vs concurrency
- Keep transactions short to avoid blocking
- Handle deadlocks gracefully (retry logic)
- Use savepoints for complex multi-step transactions
- Always wrap transactions in TRY/CATCH
- Choose isolation level based on requirements

---

## Next Lesson

Continue to [Lesson 10: Query Optimization & Performance Tips](../10-query-optimization/10-query-optimization.md).
