# Stored Procedures in SQL Server

## What is a Stored Procedure?

A **stored procedure** is a saved collection of SQL statements that can be executed as a unit. It's like a function or method in programming languages, but for database operations.

## Why Use Stored Procedures?

### 1. **Code Reusability**
- Write once, use many times
- Consistent business logic across applications

### 2. **Performance**
- Compiled and cached execution plans
- Reduced network traffic (send procedure name instead of full SQL)
- Faster execution for complex operations

### 3. **Security**
- Grant execute permission without granting table access
- Prevent SQL injection attacks
- Encapsulate business logic

### 4. **Maintainability**
- Centralize business rules in database
- Change logic once, affects all applications
- Easier to debug and test

## Basic Syntax

```sql
CREATE PROCEDURE ProcedureName
    @Parameter1 DataType,
    @Parameter2 DataType = DefaultValue  -- Optional with default
AS
BEGIN
    -- SQL statements here
    SELECT * FROM TableName WHERE Column = @Parameter1;
END;
GO

-- Execute the procedure
EXEC ProcedureName @Parameter1Value, @Parameter2Value;
```

## Key Components

### Parameters
- **Input Parameters**: Pass data TO the procedure
- **Output Parameters**: Return data FROM the procedure  
- **Default Values**: Optional parameters with defaults

### Return Values
- `RETURN` statement returns integer status code
- 0 = success (by convention)
- Non-zero = error codes

### Variables
- Declare with `DECLARE @VariableName DataType;`
- Set with `SET @Variable = Value;` or `SELECT @Variable = Value;`

## Stored Procedure vs. Functions

| Feature | Stored Procedure | Function |
|---------|-----------------|----------|
| **Return Value** | Optional (OUTPUT params, result sets) | Must return a value |
| **RETURN** | Integer only | Any data type |
| **DML Operations** | INSERT, UPDATE, DELETE allowed | Not allowed (except in table-valued functions) |
| **Call from SELECT** | No | Yes (scalar/table-valued) |
| **Transaction Control** | Yes (BEGIN/COMMIT/ROLLBACK) | Limited |
| **Error Handling** | TRY...CATCH supported | Limited |
| **Use Case** | Complex business logic, data modifications | Calculations, data transformations |

## Best Practices

### 1. ✅ Use Meaningful Names
```sql
-- Good
CREATE PROCEDURE usp_GetCustomerOrders ...
CREATE PROCEDURE usp_UpdateProductPrice ...

-- Naming convention: usp_ (user stored procedure)
```

### 2. ✅ Always Use BEGIN...END
```sql
CREATE PROCEDURE usp_Example
AS
BEGIN
    -- Always wrap in BEGIN/END, even for single statements
    SELECT * FROM Products;
END;
```

### 3. ✅ SET NOCOUNT ON
```sql
CREATE PROCEDURE usp_Example
AS
BEGIN
    SET NOCOUNT ON;  -- Prevents "rows affected" messages
    -- Your logic here
END;
```

### 4. ✅ Use Parameters, Not Dynamic SQL When Possible
```sql
-- Good (parameterized)
CREATE PROCEDURE usp_GetProduct
    @ProductID INT
AS
BEGIN
    SELECT * FROM Products WHERE ProductID = @ProductID;
END;

-- Bad (SQL injection risk)
CREATE PROCEDURE usp_GetProduct_Bad
    @ProductID NVARCHAR(50)
AS
BEGIN
    EXEC('SELECT * FROM Products WHERE ProductID = ' + @ProductID);
END;
```

### 5. ✅ Include Error Handling
```sql
CREATE PROCEDURE usp_UpdateProduct
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Products SET Price = @NewPrice WHERE ProductID = @ProductID;
    END TRY
    BEGIN CATCH
        -- Log error or re-throw
        THROW;
    END CATCH;
END;
```

### 6. ✅ Use Transactions for Multiple Operations
```sql
CREATE PROCEDURE usp_TransferStock
    @FromProductID INT,
    @ToProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Products SET StockQuantity = StockQuantity - @Quantity 
        WHERE ProductID = @FromProductID;
        
        UPDATE Products SET StockQuantity = StockQuantity + @Quantity 
        WHERE ProductID = @ToProductID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

## Common Patterns

### Pattern 1: CRUD Operations
```sql
-- Create
CREATE PROCEDURE usp_InsertCustomer
    @CustomerName NVARCHAR(100),
    @State NVARCHAR(50)
AS
BEGIN
    INSERT INTO Customers (CustomerName, State) VALUES (@CustomerName, @State);
    SELECT SCOPE_IDENTITY() AS NewCustomerID;
END;

-- Read
CREATE PROCEDURE usp_GetCustomer
    @CustomerID INT
AS
BEGIN
    SELECT * FROM Customers WHERE CustomerID = @CustomerID;
END;

-- Update
CREATE PROCEDURE usp_UpdateCustomer
    @CustomerID INT,
    @CustomerName NVARCHAR(100)
AS
BEGIN
    UPDATE Customers SET CustomerName = @CustomerName WHERE CustomerID = @CustomerID;
END;

-- Delete
CREATE PROCEDURE usp_DeleteCustomer
    @CustomerID INT
AS
BEGIN
    DELETE FROM Customers WHERE CustomerID = @CustomerID;
END;
```

### Pattern 2: Search with Optional Parameters
```sql
CREATE PROCEDURE usp_SearchProducts
    @Category NVARCHAR(50) = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL
AS
BEGIN
    SELECT * FROM Products
    WHERE (@Category IS NULL OR Category = @Category)
      AND (@MinPrice IS NULL OR Price >= @MinPrice)
      AND (@MaxPrice IS NULL OR Price <= @MaxPrice);
END;
```

### Pattern 3: Pagination
```sql
CREATE PROCEDURE usp_GetProductsPaged
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SELECT * FROM Products
    ORDER BY ProductID
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
```

## Managing Stored Procedures

```sql
-- Create or replace
CREATE OR ALTER PROCEDURE usp_Example AS ...

-- Drop procedure
DROP PROCEDURE IF EXISTS usp_Example;

-- Rename procedure
EXEC sp_rename 'OldProcedureName', 'NewProcedureName';

-- View procedure definition
EXEC sp_helptext 'usp_Example';

-- List all stored procedures
SELECT name, create_date, modify_date
FROM sys.procedures
ORDER BY name;
```

## Execution Methods

```sql
-- Method 1: EXEC with named parameters
EXEC usp_GetProduct @ProductID = 1;

-- Method 2: EXEC with positional parameters
EXEC usp_GetProduct 1;

-- Method 3: EXECUTE (full keyword)
EXECUTE usp_GetProduct @ProductID = 1;

-- Method 4: With OUTPUT parameter
DECLARE @Result INT;
EXEC usp_SomeProc @OutputParam = @Result OUTPUT;
SELECT @Result;
```

## Summary

Stored procedures are essential for:
- 🚀 **Performance** - Precompiled execution plans
- 🔒 **Security** - Encapsulation and permission control
- 🔄 **Reusability** - Centralized business logic
- 🛡️ **Data Integrity** - Transaction control

In the practice files, you'll learn to create, execute, and optimize stored procedures using the TechStore database.
