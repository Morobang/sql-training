# Transactions

## Introduction

A **transaction** is a logical unit of work that must be executed as a single, atomic operation. Transactions ensure data integrity and consistency in multi-user database environments.

Think of a bank transfer: withdrawing from one account and depositing to another must both succeed or both fail - you can't have money disappear or duplicate!

## ACID Properties

Every transaction must satisfy four critical properties (ACID):

### Atomicity
- **All or nothing**: Either all operations in the transaction succeed, or none do
- No partial transactions
- If any operation fails, the entire transaction is rolled back

**Example**: Transfer $100
```sql
BEGIN TRANSACTION
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;  -- Withdraw
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;  -- Deposit
COMMIT;
```
If deposit fails, withdrawal is also rolled back (money doesn't disappear).

### Consistency
- **Valid state to valid state**: Database moves from one valid state to another
- All constraints, triggers, and rules are enforced
- Data integrity is maintained

**Example**: Cannot create order with negative quantity
```sql
BEGIN TRANSACTION
    INSERT INTO Orders (ProductID, Quantity) VALUES (1, -5);  -- Violates CHECK constraint
    -- Transaction fails, database remains consistent
ROLLBACK;
```

### Isolation
- **Transactions don't interfere**: Each transaction executes as if it's alone
- Prevents dirty reads, non-repeatable reads, phantom reads
- Controlled by isolation levels (READ UNCOMMITTED, READ COMMITTED, etc.)

**Example**: Two users updating the same product simultaneously
```sql
-- User 1 and User 2 both update Product ID 1
-- Isolation ensures changes don't conflict or get lost
```

### Durability
- **Permanent changes**: Once committed, changes survive system failures
- Saved to non-volatile storage (disk)
- Transaction log ensures recovery after crashes

**Example**: Power outage after COMMIT
```sql
BEGIN TRANSACTION
    UPDATE Products SET Price = 199.99 WHERE ProductID = 1;
COMMIT;  -- Guaranteed to persist even if server crashes immediately after
```

## Transaction Control Statements

### BEGIN TRANSACTION (BEGIN TRAN)
- Starts a new transaction
- Optional name for nested transactions

```sql
BEGIN TRANSACTION;
BEGIN TRANSACTION SalesUpdate;  -- Named transaction
BEGIN TRAN;  -- Shorthand
```

### COMMIT (COMMIT TRANSACTION)
- Makes all changes permanent
- Releases locks
- Ends the transaction successfully

```sql
COMMIT;
COMMIT TRANSACTION;
COMMIT TRAN;
```

### ROLLBACK (ROLLBACK TRANSACTION)
- Undoes all changes since BEGIN TRANSACTION
- Releases locks
- Ends the transaction unsuccessfully

```sql
ROLLBACK;
ROLLBACK TRANSACTION;
ROLLBACK TRAN;
```

### SAVE TRANSACTION (Savepoints)
- Creates a marker within a transaction
- Can rollback to savepoint without rolling back entire transaction

```sql
BEGIN TRANSACTION;
    UPDATE Products SET Price = Price * 1.1;
    SAVE TRANSACTION PriceUpdate;
    UPDATE Products SET StockQuantity = 0;  -- Oops, mistake!
    ROLLBACK TRANSACTION PriceUpdate;  -- Undo stock change, keep price change
COMMIT;
```

## Isolation Levels

Isolation levels control how transactions interact with each other. They balance between **consistency** (preventing anomalies) and **concurrency** (allowing parallel access).

### Isolation Level Anomalies

| Anomaly | Description |
|---------|-------------|
| **Dirty Read** | Read uncommitted data from another transaction (may be rolled back) |
| **Non-Repeatable Read** | Same query returns different results within same transaction (another transaction modified data) |
| **Phantom Read** | Same query returns additional rows (another transaction inserted data) |

### Isolation Levels Comparison

| Level | Dirty Reads | Non-Repeatable Reads | Phantom Reads | Locking Behavior |
|-------|-------------|----------------------|---------------|------------------|
| **READ UNCOMMITTED** | ✅ Possible | ✅ Possible | ✅ Possible | No read locks |
| **READ COMMITTED** | ❌ Prevented | ✅ Possible | ✅ Possible | Read locks released immediately |
| **REPEATABLE READ** | ❌ Prevented | ❌ Prevented | ✅ Possible | Read locks held until commit |
| **SERIALIZABLE** | ❌ Prevented | ❌ Prevented | ❌ Prevented | Range locks on queries |
| **SNAPSHOT** | ❌ Prevented | ❌ Prevented | ❌ Prevented | Row versioning (no read locks) |

### READ UNCOMMITTED (Lowest Isolation)
- **No read locks**: Reads data without locking
- **Dirty reads allowed**: Can see uncommitted changes from other transactions
- **Fastest**: No locking overhead
- **Use case**: Reporting where approximate data is acceptable

### READ COMMITTED (SQL Server Default)
- **Read locks**: Acquires shared locks while reading
- **Prevents dirty reads**: Only reads committed data
- **Releases locks immediately**: After each statement
- **Use case**: Most OLTP applications

### REPEATABLE READ
- **Holds read locks**: Until transaction commits
- **Prevents dirty and non-repeatable reads**: Same query returns same results
- **Phantom reads possible**: New rows can still appear
- **Use case**: Calculations requiring consistent data

### SERIALIZABLE (Highest Isolation)
- **Range locks**: Locks range of data, preventing inserts
- **Prevents all anomalies**: Complete isolation from other transactions
- **Slowest**: Maximum locking, minimum concurrency
- **Use case**: Financial transactions requiring absolute accuracy

### SNAPSHOT (Optimistic Concurrency)
- **Row versioning**: Keeps old versions of rows in tempdb
- **No read locks**: Readers don't block writers
- **Update conflicts detected**: Last writer wins or error
- **Use case**: High-read, low-write scenarios

## Locking

SQL Server uses locks to implement isolation levels and prevent conflicts.

### Lock Types

| Lock Type | Description | Compatibility |
|-----------|-------------|---------------|
| **Shared (S)** | Read lock - multiple readers allowed | Compatible with other shared locks |
| **Exclusive (X)** | Write lock - no other access allowed | Blocks all other locks |
| **Update (U)** | Intent to update - prevents deadlocks | Compatible with shared, blocks exclusive |
| **Intent (IS, IX, IU)** | Indicates locking at lower level | Allows lock escalation |
| **Schema (Sch-S, Sch-M)** | Prevents schema changes during queries | Blocks DDL operations |

### Lock Granularity

From finest to coarsest:
1. **Row (RID)**: Single row in heap table
2. **Key**: Single row in index
3. **Page**: 8KB page (multiple rows)
4. **Extent**: 8 pages (64KB)
5. **Table**: Entire table
6. **Database**: Entire database

### Lock Escalation
- SQL Server may escalate from row/page locks to table lock
- Reduces lock overhead when many rows affected
- Can be controlled with `ALTER TABLE ... SET (LOCK_ESCALATION = ...)`

## Deadlocks

A **deadlock** occurs when two or more transactions block each other, creating a circular dependency.

### Classic Deadlock Example
```
Transaction 1:                 Transaction 2:
1. Lock Table A                1. Lock Table B
2. Wait for Table B            2. Wait for Table A
   ⬇️                              ⬇️
   DEADLOCK! (circular wait)
```

### Deadlock Detection
- SQL Server automatically detects deadlocks
- Chooses a "deadlock victim" and rolls it back
- Victim selection based on transaction cost (typically least expensive)

### Preventing Deadlocks
✅ **Do**:
- Access tables in consistent order
- Keep transactions short
- Use appropriate isolation levels
- Use row-level locking (selective WHERE clauses)
- Use UPDLOCK hint to prevent conversion deadlocks

❌ **Don't**:
- Hold locks for long periods
- Access tables in different orders across transactions
- Use unnecessary high isolation levels
- Perform I/O within transactions

## Transaction Best Practices

### 1. Keep Transactions Short
```sql
-- ❌ Bad: Long transaction
BEGIN TRANSACTION
    SELECT @Data = LongCalculation();  -- Expensive operation
    UPDATE Table SET Value = @Data;
COMMIT;

-- ✅ Good: Do work outside transaction
SELECT @Data = LongCalculation();  -- Before transaction
BEGIN TRANSACTION
    UPDATE Table SET Value = @Data;
COMMIT;
```

### 2. Use Appropriate Isolation Level
```sql
-- ❌ Bad: Unnecessarily high isolation
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;  -- For simple read

-- ✅ Good: Lowest level that meets requirements
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

### 3. Handle Errors Properly
```sql
-- ✅ Good: Always handle errors
BEGIN TRY
    BEGIN TRANSACTION
        UPDATE Accounts SET Balance = Balance - 100 WHERE ID = 1;
        UPDATE Accounts SET Balance = Balance + 100 WHERE ID = 2;
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

### 4. Check Transaction State
```sql
-- @@TRANCOUNT: Number of active transactions
-- XACT_STATE(): -1 (uncommittable), 0 (no transaction), 1 (committable)

IF @@TRANCOUNT > 0
    ROLLBACK;

IF XACT_STATE() = 1
    COMMIT;
ELSE IF XACT_STATE() = -1
    ROLLBACK;
```

### 5. Use SET XACT_ABORT ON
```sql
SET XACT_ABORT ON;  -- Auto-rollback on error
BEGIN TRANSACTION
    UPDATE Table1 SET Value = 1;
    UPDATE Table2 SET Value = 1/0;  -- Error: auto-rollback
    -- No explicit error handling needed
COMMIT;
```

## Common Patterns

### Pattern 1: Simple Transaction
```sql
BEGIN TRANSACTION
    INSERT INTO Orders (CustomerID, Total) VALUES (1, 100);
    INSERT INTO OrderItems (OrderID, ProductID) VALUES (SCOPE_IDENTITY(), 5);
COMMIT;
```

### Pattern 2: Transaction with Error Handling
```sql
BEGIN TRY
    BEGIN TRANSACTION
        UPDATE Inventory SET Quantity = Quantity - 10;
        INSERT INTO Sales (ProductID, Quantity) VALUES (1, 10);
    COMMIT
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK;
    THROW;
END CATCH;
```

### Pattern 3: Savepoint for Partial Rollback
```sql
BEGIN TRANSACTION
    UPDATE Products SET Price = 100;
    SAVE TRANSACTION SavePoint1;
    UPDATE Products SET Stock = 0;  -- Mistake
    ROLLBACK TRANSACTION SavePoint1;  -- Undo stock, keep price
COMMIT;
```

### Pattern 4: Explicit Isolation Level
```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION
    DECLARE @Total DECIMAL(10,2);
    SELECT @Total = SUM(Amount) FROM Sales;
    INSERT INTO DailySummary (Date, Total) VALUES (GETDATE(), @Total);
COMMIT;
```

## Next Steps

Practice transaction concepts in the accompanying SQL files:
1. `01-basic-transactions.sql` - BEGIN, COMMIT, ROLLBACK, savepoints
2. `02-isolation-levels.sql` - READ UNCOMMITTED, COMMITTED, REPEATABLE READ, SERIALIZABLE, SNAPSHOT
3. `03-locking.sql` - Lock types, compatibility, hints, escalation
4. `04-deadlocks.sql` - Detecting, preventing, resolving deadlocks
