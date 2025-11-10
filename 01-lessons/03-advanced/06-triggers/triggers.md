# Lesson 6: Triggers

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Create DML triggers (AFTER and INSTEAD OF)
2. Create DDL triggers for schema changes
3. Use inserted and deleted tables
4. Implement audit logging with triggers
5. Understand trigger performance and best practices

---

## Part 1: What Are Triggers?

Triggers are special stored procedures that execute automatically in response to events (INSERT, UPDATE, DELETE, DDL changes).

---

## Part 2: AFTER Triggers (DML)

Execute after the triggering action completes.

```sql
CREATE TRIGGER trg_Products_AfterInsert
ON Products
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Log new products to audit table
    INSERT INTO ProductAudit (ProductID, Action, ActionDate, UserName)
    SELECT ProductID, 'INSERT', GETDATE(), SUSER_SNAME()
    FROM inserted;
END;
```

---

## Part 3: inserted and deleted Tables

- **inserted:** Contains new rows (INSERT, UPDATE)
- **deleted:** Contains old rows (DELETE, UPDATE)

```sql
-- Audit UPDATE: capture old and new values
CREATE TRIGGER trg_Products_AfterUpdate
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ProductAudit (ProductID, OldPrice, NewPrice, ActionDate, UserName)
    SELECT 
        i.ProductID,
        d.Price AS OldPrice,
        i.Price AS NewPrice,
        GETDATE(),
        SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d ON i.ProductID = d.ProductID
    WHERE i.Price <> d.Price; -- Only log price changes
END;
```

---

## Part 4: DELETE Trigger

```sql
CREATE TRIGGER trg_Products_AfterDelete
ON Products
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Archive deleted products
    INSERT INTO ProductsArchive (ProductID, ProductName, Price, DeletedDate)
    SELECT ProductID, ProductName, Price, GETDATE()
    FROM deleted;
END;
```

---

## Part 5: INSTEAD OF Triggers

Replace the triggering action with custom logic.

```sql
CREATE TRIGGER trg_Products_InsteadOfDelete
ON Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Soft delete: mark as deleted instead of removing row
    UPDATE Products
    SET IsDeleted = 1, DeletedDate = GETDATE()
    WHERE ProductID IN (SELECT ProductID FROM deleted);
END;
```

---

## Part 6: Multiple DML Operations

```sql
-- Handle INSERT, UPDATE, DELETE in one trigger
CREATE TRIGGER trg_Products_Audit
ON Products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(10);
    
    -- Determine action
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Action = 'INSERT';
    ELSE
        SET @Action = 'DELETE';
    
    -- Log action
    INSERT INTO AuditLog (TableName, Action, ActionDate, UserName)
    VALUES ('Products', @Action, GETDATE(), SUSER_SNAME());
END;
```

---

## Part 7: Enforce Business Rules

```sql
-- Prevent price reduction > 50%
CREATE TRIGGER trg_Products_ValidatePrice
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON i.ProductID = d.ProductID
        WHERE i.Price < (d.Price * 0.5)
    )
    BEGIN
        RAISERROR('Price reduction cannot exceed 50%', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
```

---

## Part 8: DDL Triggers

Respond to schema changes (CREATE, ALTER, DROP).

```sql
-- Prevent table drops in production
CREATE TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'Table drops are not allowed in this database.';
    ROLLBACK;
END;

-- Audit schema changes
CREATE TRIGGER trg_AuditSchemaChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO SchemaAudit (EventType, ObjectName, EventDate, UserName, EventData)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(256)'),
        GETDATE(),
        SUSER_SNAME(),
        @EventData
    );
END;
```

---

## Part 9: Trigger Order

When multiple triggers exist on same event, use sp_settriggerorder.

```sql
EXEC sp_settriggerorder 
    @triggername = 'trg_Products_AfterInsert', 
    @order = 'First', 
    @stmttype = 'INSERT';
```

---

## Part 10: Practical Examples

### Example 1: Stock Management

```sql
-- Update product stock after order
CREATE TRIGGER trg_OrderDetails_AfterInsert
ON OrderDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Products
    SET Stock = Stock - i.Quantity
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    -- Alert if stock low
    INSERT INTO Alerts (ProductID, Message, AlertDate)
    SELECT p.ProductID, 'Low stock: ' + p.ProductName, GETDATE()
    FROM Products p
    INNER JOIN inserted i ON p.ProductID = i.ProductID
    WHERE p.Stock < 10;
END;
```

### Example 2: Cascade Soft Delete

```sql
-- When customer is soft-deleted, soft-delete their orders
CREATE TRIGGER trg_Customers_AfterUpdate
ON Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- If IsDeleted changed to 1
    IF UPDATE(IsDeleted)
    BEGIN
        UPDATE Orders
        SET IsDeleted = 1, DeletedDate = GETDATE()
        WHERE CustomerID IN (
            SELECT CustomerID FROM inserted WHERE IsDeleted = 1
        );
    END;
END;
```

### Example 3: Prevent Orphan Records

```sql
-- Prevent deleting category with products
CREATE TRIGGER trg_Categories_InsteadOfDelete
ON Categories
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM Products p
        INNER JOIN deleted d ON p.CategoryID = d.CategoryID
    )
    BEGIN
        RAISERROR('Cannot delete category with existing products', 16, 1);
        RETURN;
    END;
    
    -- Safe to delete
    DELETE FROM Categories
    WHERE CategoryID IN (SELECT CategoryID FROM deleted);
END;
```

---

## Part 11: Performance Considerations

- Triggers add overhead to DML operations
- Keep trigger logic minimal and fast
- Avoid complex queries or nested triggers
- Don't call external resources (web services, etc.)
- Use SET NOCOUNT ON to suppress messages
- Index columns used in trigger queries

### Trigger Risks

- **Performance:** Slows down DML
- **Hidden logic:** Developers may not expect side effects
- **Recursive triggers:** Can cause infinite loops
- **Transaction blocking:** Long-running triggers hold locks

---

## Part 12: Disabling and Dropping Triggers

```sql
-- Disable
DISABLE TRIGGER trg_Products_AfterInsert ON Products;

-- Enable
ENABLE TRIGGER trg_Products_AfterInsert ON Products;

-- Drop
DROP TRIGGER trg_Products_AfterInsert;

-- Disable all triggers on table
ALTER TABLE Products DISABLE TRIGGER ALL;

-- Enable all triggers on table
ALTER TABLE Products ENABLE TRIGGER ALL;
```

---

## Part 13: Best Practices

- Document trigger behavior clearly
- Keep triggers simple and fast
- Use naming convention (trg_TableName_Event)
- Avoid nested triggers (SET RECURSIVE_TRIGGERS OFF)
- Log errors in triggers, don't silently fail
- Test thoroughly (triggers can cause unexpected rollbacks)
- Consider alternatives (constraints, computed columns, procedures)
- Use DDL triggers sparingly (can interfere with deployments)

---

## Practice Exercises

1. Create an AFTER INSERT trigger to log new customer registrations.
2. Build an INSTEAD OF DELETE trigger for soft deletes on Orders table.
3. Create a trigger to enforce that OrderDate cannot be updated.
4. Implement a DDL trigger to audit all ALTER TABLE statements.

---

## Key Takeaways

- AFTER triggers execute after DML completes
- INSTEAD OF triggers replace the DML action
- Use inserted/deleted tables to access row data
- DDL triggers respond to schema changes
- Triggers have performance cost; use judiciously
- Document and test triggers thoroughly

---

## Next Lesson

Continue to [Lesson 7: Indexes & Performance](../07-indexes-performance/indexes-performance.md).
