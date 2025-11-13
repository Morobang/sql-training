# Triggers in SQL Server

## What is a Trigger?

A **trigger** is a special type of stored procedure that automatically executes when specific events occur in the database. Triggers are fired automatically by SQL Server in response to DML (Data Manipulation Language) or DDL (Data Definition Language) events.

## Types of Triggers

### 1. **DML Triggers** (Data Modification)
- **AFTER Triggers**: Execute after INSERT, UPDATE, or DELETE completes
- **INSTEAD OF Triggers**: Execute in place of INSERT, UPDATE, or DELETE

### 2. **DDL Triggers** (Schema Changes)
- Fire on CREATE, ALTER, DROP statements
- Database-level or server-level
- Used for auditing and preventing schema changes

### 3. **LOGON Triggers**
- Fire when user logs into SQL Server
- Used for session tracking and connection limits

## DML Trigger Syntax

```sql
CREATE TRIGGER TriggerName
ON TableName
AFTER INSERT, UPDATE, DELETE  -- or INSTEAD OF
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Trigger logic here
    -- Access inserted/deleted pseudo-tables
END;
```

## Special Tables in Triggers

### INSERTED Table
- Contains new rows for INSERT and UPDATE
- Virtual table (not physical storage)
- Structure mirrors the trigger table

### DELETED Table
- Contains old rows for DELETE and UPDATE
- Virtual table (not physical storage)
- Structure mirrors the trigger table

| Operation | INSERTED | DELETED |
|-----------|----------|---------|
| **INSERT** | New rows | Empty |
| **UPDATE** | New values | Old values |
| **DELETE** | Empty | Deleted rows |

## When to Use Triggers

### ✅ Good Use Cases

1. **Auditing and Logging**
   - Track who changed what and when
   - Maintain history tables

2. **Enforcing Business Rules**
   - Complex validation across tables
   - Rules that cannot be enforced with constraints

3. **Maintaining Derived Data**
   - Update summary tables automatically
   - Keep denormalized data in sync

4. **Preventing Invalid Operations**
   - Block dangerous DELETE operations
   - Enforce workflow rules

### ❌ Avoid Triggers For

1. **Simple Validation** - Use CHECK constraints instead
2. **Referential Integrity** - Use FOREIGN KEY constraints instead
3. **Complex Business Logic** - Use stored procedures instead
4. **Performance-Critical Operations** - Triggers add overhead
5. **Cascading Changes** - Can lead to unexpected behavior

## AFTER Triggers

Execute after the DML operation completes:

```sql
CREATE TRIGGER trg_AfterInsert
ON Sales
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update customer total purchases
    UPDATE c
    SET TotalPurchases = TotalPurchases + i.TotalAmount
    FROM Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
END;
```

## INSTEAD OF Triggers

Replace the DML operation entirely:

```sql
CREATE TRIGGER trg_InsteadOfDelete
ON Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Soft delete: Mark as inactive instead of deleting
    UPDATE Products
    SET IsActive = 0
    WHERE ProductID IN (SELECT ProductID FROM deleted);
    
    PRINT 'Products marked as inactive instead of deleted';
END;
```

## DDL Triggers

Monitor and control schema changes:

```sql
CREATE TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'Table drops are not allowed in this database';
    ROLLBACK;
END;
```

## Best Practices

### 1. ✅ Keep Triggers Simple and Fast
```sql
-- Good: Simple, focused logic
CREATE TRIGGER trg_UpdateTimestamp
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products SET LastModified = GETDATE()
    WHERE ProductID IN (SELECT ProductID FROM inserted);
END;

-- Bad: Complex, slow operations
CREATE TRIGGER trg_SlowTrigger
ON Products
AFTER INSERT
AS
BEGIN
    -- Avoid: Complex joins, external calls, loops
    WAITFOR DELAY '00:00:05';  -- Never do this!
END;
```

### 2. ✅ Always Use SET NOCOUNT ON
```sql
CREATE TRIGGER trg_Example
ON TableName
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;  -- Prevents extra "rows affected" messages
    -- Trigger logic
END;
```

### 3. ✅ Handle Multiple Rows
```sql
-- Good: Set-based operation
CREATE TRIGGER trg_MultipleRows
ON Sales
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE c
    SET TotalPurchases = TotalPurchases + TotalAmount
    FROM Customers c
    INNER JOIN inserted i ON c.CustomerID = i.CustomerID;
END;

-- Bad: Cursor/loop (assumes single row)
CREATE TRIGGER trg_SingleRowBad
ON Sales
AFTER INSERT
AS
BEGIN
    DECLARE @CustomerID INT;
    SELECT @CustomerID = CustomerID FROM inserted;  -- Only gets first row!
    -- ...
END;
```

### 4. ✅ Use Proper Error Handling
```sql
CREATE TRIGGER trg_WithErrorHandling
ON Sales
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Trigger logic
        UPDATE Customers SET TotalPurchases = TotalPurchases + 100;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

### 5. ✅ Avoid Recursive Triggers
```sql
-- Prevent infinite loops
ALTER DATABASE YourDatabase SET RECURSIVE_TRIGGERS OFF;
```

### 6. ❌ Avoid Triggers That Modify Other Tables
```sql
-- Bad: Trigger cascade (hard to debug)
CREATE TRIGGER trg_CascadeChanges
ON TableA
AFTER UPDATE
AS
BEGIN
    UPDATE TableB SET ...;  -- Which might trigger another trigger
    UPDATE TableC SET ...;  -- And another trigger
END;
-- This creates unpredictable behavior and debugging nightmares
```

## Performance Considerations

### Triggers Add Overhead
- Executed automatically for every DML operation
- Can significantly slow down bulk operations
- Invisible to developers (hidden logic)

### Optimize Trigger Code
- Use set-based operations (no cursors/loops)
- Minimize table joins
- Avoid complex calculations
- Don't call stored procedures unnecessarily

### Disable Triggers for Bulk Operations
```sql
-- Disable trigger
ALTER TABLE Sales DISABLE TRIGGER trg_TriggerName;

-- Bulk operation
-- ...

-- Re-enable trigger
ALTER TABLE Sales ENABLE TRIGGER trg_TriggerName;
```

## Common Patterns

### Pattern 1: Audit Trail
```sql
CREATE TRIGGER trg_AuditProductChanges
ON Products
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ProductAuditLog (ProductID, Action, OldPrice, NewPrice, ChangedBy, ChangedDate)
    SELECT 
        ISNULL(i.ProductID, d.ProductID),
        CASE WHEN i.ProductID IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
        d.Price,
        i.Price,
        SUSER_SNAME(),
        GETDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.ProductID = d.ProductID;
END;
```

### Pattern 2: Prevent Deletion
```sql
CREATE TRIGGER trg_PreventCustomerDelete
ON Customers
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted d INNER JOIN Sales s ON d.CustomerID = s.CustomerID)
    BEGIN
        RAISERROR('Cannot delete customers with existing orders', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        DELETE FROM Customers WHERE CustomerID IN (SELECT CustomerID FROM deleted);
    END;
END;
```

### Pattern 3: Maintain Denormalized Data
```sql
CREATE TRIGGER trg_UpdateOrderCount
ON Sales
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update customer order count
    UPDATE c
    SET OrderCount = (SELECT COUNT(*) FROM Sales WHERE CustomerID = c.CustomerID)
    FROM Customers c
    WHERE c.CustomerID IN (SELECT CustomerID FROM inserted UNION SELECT CustomerID FROM deleted);
END;
```

## Managing Triggers

```sql
-- List all triggers
SELECT 
    name AS TriggerName,
    OBJECT_NAME(parent_id) AS TableName,
    is_disabled,
    create_date
FROM sys.triggers
WHERE type = 'TR'  -- DML triggers
ORDER BY name;

-- View trigger definition
EXEC sp_helptext 'trg_TriggerName';

-- Disable trigger
ALTER TABLE TableName DISABLE TRIGGER trg_TriggerName;

-- Enable trigger
ALTER TABLE TableName ENABLE TRIGGER trg_TriggerName;

-- Drop trigger
DROP TRIGGER IF EXISTS trg_TriggerName;

-- Disable all triggers on table
ALTER TABLE TableName DISABLE TRIGGER ALL;
```

## Debugging Triggers

```sql
-- Check if trigger fired
SELECT 
    name,
    object_name(parent_obj) AS TableName,
    is_disabled
FROM sys.triggers;

-- View trigger execution order
SELECT 
    name,
    object_name(parent_id) AS TableName,
    is_disabled,
    is_instead_of_trigger
FROM sys.triggers
ORDER BY object_name(parent_id);
```

## Summary

Triggers are powerful for:
- 🔍 **Auditing** - Track all changes automatically
- 🛡️ **Data Integrity** - Enforce complex business rules
- 🔄 **Automation** - Update related data automatically
- 🚫 **Prevention** - Block unwanted operations

Use with caution:
- ⚠️ Hidden logic (hard to debug)
- ⚠️ Performance overhead
- ⚠️ Can cause unexpected side effects
- ⚠️ Difficult to test and maintain

In the practice files, you'll learn to create and manage triggers using the TechStore database.
