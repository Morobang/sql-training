# Functions in SQL Server

## What is a Function?

A **function** is a database object that accepts parameters, performs an operation, and returns a result. Functions must return a value and can be used in SELECT statements, WHERE clauses, and other SQL expressions.

## Types of Functions

### 1. **Scalar Functions**
- Returns a single value (INT, VARCHAR, DECIMAL, etc.)
- Can be used anywhere an expression is allowed
- Examples: Calculations, string manipulations, date formatting

### 2. **Table-Valued Functions (TVF)**
- Returns a table (result set)
- Can be used in FROM clause like a view or table
- Two subtypes:
  - **Inline TVF**: Single SELECT statement (fast, acts like view)
  - **Multi-statement TVF**: Multiple statements with table variable (slower)

## Functions vs. Stored Procedures

| Feature | Function | Stored Procedure |
|---------|----------|------------------|
| **Must Return Value** | Yes (single value or table) | Optional (OUTPUT params, result sets) |
| **DML Operations** | Not allowed | INSERT, UPDATE, DELETE allowed |
| **Transaction Control** | Not allowed | BEGIN TRAN, COMMIT, ROLLBACK allowed |
| **Call from SELECT** | Yes | No |
| **Error Handling** | Limited | Full TRY...CATCH support |
| **Performance** | Can be slower (inline TVF exception) | Generally faster for complex operations |
| **Use Case** | Calculations, transformations, reusable queries | Complex business logic, data modifications |

## Scalar Function Syntax

```sql
CREATE FUNCTION dbo.FunctionName
(
    @Parameter1 DataType,
    @Parameter2 DataType
)
RETURNS ReturnDataType
AS
BEGIN
    DECLARE @Result ReturnDataType;
    
    -- Logic here
    SET @Result = SomeCalculation;
    
    RETURN @Result;
END;
```

## Inline Table-Valued Function Syntax

```sql
CREATE FUNCTION dbo.FunctionName
(
    @Parameter DataType
)
RETURNS TABLE
AS
RETURN
(
    SELECT Column1, Column2
    FROM TableName
    WHERE Column = @Parameter
);
```

## Multi-Statement Table-Valued Function Syntax

```sql
CREATE FUNCTION dbo.FunctionName
(
    @Parameter DataType
)
RETURNS @ResultTable TABLE
(
    Column1 DataType,
    Column2 DataType
)
AS
BEGIN
    -- Multiple statements
    INSERT INTO @ResultTable
    SELECT Column1, Column2
    FROM TableName
    WHERE Column = @Parameter;
    
    -- More logic...
    
    RETURN;
END;
```

## Best Practices

### 1. ✅ Use Functions for Calculations and Transformations
```sql
-- Good: Pure calculation
CREATE FUNCTION fn_CalculateTax(@Amount DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @Amount * 0.08;  -- 8% tax
END;
```

### 2. ✅ Prefer Inline TVF Over Multi-Statement TVF
```sql
-- Good: Inline (fast, optimized like view)
CREATE FUNCTION fn_GetActiveProducts()
RETURNS TABLE
AS
RETURN
(
    SELECT * FROM Products WHERE IsActive = 1
);

-- Slower: Multi-statement (avoid if possible)
CREATE FUNCTION fn_GetActiveProducts_Slow()
RETURNS @Products TABLE (ProductID INT, ProductName NVARCHAR(100))
AS
BEGIN
    INSERT INTO @Products
    SELECT ProductID, ProductName FROM Products WHERE IsActive = 1;
    RETURN;
END;
```

### 3. ✅ Use Schema Prefix (dbo.)
```sql
CREATE FUNCTION dbo.fn_FunctionName ...
-- Always specify schema for clarity
```

### 4. ✅ Keep Functions Deterministic When Possible
```sql
-- Deterministic (same inputs = same output)
CREATE FUNCTION fn_Add(@A INT, @B INT) RETURNS INT
AS BEGIN
    RETURN @A + @B;
END;

-- Non-deterministic (output can vary)
CREATE FUNCTION fn_CurrentDate() RETURNS DATE
AS BEGIN
    RETURN GETDATE();  -- Changes every call
END;
```

### 5. ❌ Avoid Using Functions in WHERE Clauses on Large Tables
```sql
-- Bad: Function called for every row (slow)
SELECT * FROM Sales
WHERE dbo.fn_CalculateTax(TotalAmount) > 10;

-- Better: Calculate inline or use computed column
SELECT * FROM Sales
WHERE TotalAmount * 0.08 > 10;
```

### 6. ❌ Don't Modify Data in Functions
```sql
-- Not allowed: No INSERT, UPDATE, DELETE in functions
CREATE FUNCTION fn_BadExample() ...
AS
BEGIN
    UPDATE Products SET StockQuantity = 0;  -- ERROR!
    RETURN 1;
END;
```

## Common Use Cases

### 1. Calculations and Formatting
```sql
CREATE FUNCTION fn_FormatCurrency(@Amount DECIMAL(10,2))
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN '$' + CAST(@Amount AS VARCHAR(20));
END;

-- Usage
SELECT ProductName, dbo.fn_FormatCurrency(Price) AS FormattedPrice
FROM Products;
```

### 2. Data Validation
```sql
CREATE FUNCTION fn_IsValidEmail(@Email VARCHAR(100))
RETURNS BIT
AS
BEGIN
    IF @Email LIKE '%_@__%.__%'
        RETURN 1;
    RETURN 0;
END;

-- Usage
SELECT * FROM Customers
WHERE dbo.fn_IsValidEmail(Email) = 1;
```

### 3. Reusable Queries (Table-Valued)
```sql
CREATE FUNCTION fn_GetCustomerOrders(@CustomerID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT s.*, p.ProductName
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.CustomerID = @CustomerID
);

-- Usage
SELECT * FROM dbo.fn_GetCustomerOrders(1);
```

## Performance Considerations

### Scalar Functions Can Be Slow
- Called once per row
- Cannot use indexes effectively
- Consider computed columns or inline expressions

### Inline TVF vs Multi-Statement TVF
- **Inline**: Fast, optimized by query planner
- **Multi-Statement**: Slower, estimated row count often wrong
- Always prefer inline when possible

### Functions in WHERE Clauses
- Prevent index usage (non-sargable)
- Can cause table scans
- Use sparingly or refactor

## Managing Functions

```sql
-- Create or replace
CREATE OR ALTER FUNCTION dbo.fn_Example ...

-- Drop function
DROP FUNCTION IF EXISTS dbo.fn_Example;

-- View function definition
EXEC sp_helptext 'dbo.fn_Example';

-- List all functions
SELECT name, type_desc, create_date, modify_date
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')  -- FN=Scalar, IF=Inline TVF, TF=Multi-statement TVF
ORDER BY name;
```

## Limitations

- ❌ Cannot modify database state (no INSERT/UPDATE/DELETE)
- ❌ Cannot use TRY...CATCH
- ❌ Cannot call stored procedures
- ❌ Cannot use temporary tables
- ❌ Cannot return multiple result sets
- ❌ Cannot use dynamic SQL (EXEC)
- ✅ Can use table variables
- ✅ Can call other functions
- ✅ Can use CTEs, window functions

## Summary

Functions are best for:
- 🧮 **Calculations** - Tax, discounts, totals
- 🔄 **Transformations** - Formatting, parsing, conversions
- 📊 **Reusable Queries** - Inline table-valued functions
- ✔️ **Validation** - Email, phone, data integrity checks

Use stored procedures for:
- 💾 **Data Modifications** - INSERT, UPDATE, DELETE
- 🔒 **Transactions** - Multi-step operations
- 🛠️ **Complex Business Logic** - Error handling, logging
- 📦 **Batch Processing** - Large operations

In the practice files, you'll learn to create and optimize all types of functions using the TechStore database.
