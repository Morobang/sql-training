# Error Handling in SQL Server

## 📚 Overview

Error handling allows you to gracefully manage runtime errors, log failures, and ensure data integrity. SQL Server provides TRY...CATCH blocks similar to other programming languages for robust error management.

---

## 🎯 What You'll Learn

- TRY...CATCH block syntax
- ERROR functions (ERROR_MESSAGE, ERROR_NUMBER, etc.)
- THROW vs RAISERROR
- Transaction rollback with errors
- Custom error messages
- Logging errors
- Practical applications with TechStore

---

## 💡 Key Concepts

### **Basic TRY...CATCH:**
```sql
BEGIN TRY
    -- Code that might cause an error
    INSERT INTO Products (ProductID, ProductName)
    VALUES (1, 'Test');  -- Might violate PK
END TRY
BEGIN CATCH
    -- Handle the error
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine;
END CATCH;
```

### **With Transactions:**
```sql
BEGIN TRY
    BEGIN TRANSACTION;
    
    UPDATE Products SET Price = Price * 1.10 WHERE Category = 'Peripherals';
    UPDATE Inventory SET Quantity = Quantity - 10;  -- Might fail
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    THROW;  -- Re-throw the error
END CATCH;
```

### **THROW vs RAISERROR:**
```sql
-- THROW (modern, recommended)
THROW 50001, 'Custom error message', 1;

-- RAISERROR (older, more options)
RAISERROR('Custom error: %s', 16, 1, 'details');
```

---

## 📋 ERROR Functions

| Function | Returns |
|----------|---------|
| **ERROR_NUMBER()** | Error number |
| **ERROR_MESSAGE()** | Error message text |
| **ERROR_SEVERITY()** | Error severity (1-25) |
| **ERROR_STATE()** | Error state |
| **ERROR_PROCEDURE()** | Name of stored procedure/trigger |
| **ERROR_LINE()** | Line number where error occurred |

---

## 🎯 Error Severity Levels

- **0-10**: Informational
- **11-16**: User errors (can be corrected)
- **17-19**: Software/hardware errors
- **20-25**: Fatal errors (connection terminated)

---

## 🔄 Common Error Patterns

### **1. Constraint Violations:**
```sql
BEGIN TRY
    INSERT INTO Products (ProductID, ProductName, Price)
    VALUES (1, 'Duplicate', 99.99);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 2627  -- Primary key violation
        PRINT 'Duplicate key error - product already exists';
    ELSE
        THROW;
END CATCH;
```

### **2. Division by Zero:**
```sql
BEGIN TRY
    SELECT 10 / 0;
END TRY
BEGIN CATCH
    SELECT 'Cannot divide by zero!' AS ErrorMessage;
END CATCH;
```

### **3. Foreign Key Violations:**
```sql
BEGIN TRY
    DELETE FROM Customers WHERE CustomerID = 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 547  -- FK constraint violation
        PRINT 'Cannot delete - customer has orders';
    ELSE
        THROW;
END CATCH;
```

---

## 📊 Best Practices

### ✅ **DO:**
- Always use TRY...CATCH for critical operations
- Log errors to a table
- Rollback transactions in CATCH block
- Use THROW to re-raise errors
- Provide meaningful custom error messages
- Test error handling paths

### ❌ **DON'T:**
- Swallow errors silently
- Use RAISERROR instead of THROW (new code)
- Forget to check @@TRANCOUNT before rollback
- Put entire procedures in one TRY block
- Ignore ERROR_PROCEDURE and ERROR_LINE

---

## 🔗 Practice Files

Work through these SQL files in order:

1. `01-basic-try-catch.sql` - TRY...CATCH fundamentals
2. `02-error-functions.sql` - Using ERROR_* functions
3. `03-transactions-errors.sql` - Rollback with errors
4. `04-throw-raiserror.sql` - Raising custom errors
5. `05-error-logging.sql` - Logging errors to tables
6. `06-practical-error-handling.sql` - Real-world examples

---

## 💡 Pro Tips

- Create an error log table for production systems
- Use xp_logevent to write to Windows event log
- Set up email alerts for critical errors
- Use ERROR_LINE() to find exact failure point
- Test both success and failure paths
- Document expected errors and handling

---

**Ready to master error handling? Start with `01-basic-try-catch.sql`! 🚀**
