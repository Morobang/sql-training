# Lesson 5: User-Defined Functions (UDFs)

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Create scalar functions
2. Create inline table-valued functions
3. Create multi-statement table-valued functions
4. Understand performance implications of UDFs
5. Choose between functions, procedures, and views

---

## Part 1: Scalar Functions

Return a single value.

```sql
CREATE FUNCTION dbo.fn_CalculateTax
(
    @Amount DECIMAL(10,2),
    @TaxRate DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN @Amount * @TaxRate;
END;

-- Usage
SELECT 
    ProductName, 
    Price,
    dbo.fn_CalculateTax(Price, 0.08) AS Tax,
    Price + dbo.fn_CalculateTax(Price, 0.08) AS TotalPrice
FROM Products;
```

---

## Part 2: Inline Table-Valued Functions

Return a table (single SELECT statement).

```sql
CREATE FUNCTION dbo.fn_GetProductsByCategory
(
    @CategoryID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT ProductID, ProductName, Price, Stock
    FROM Products
    WHERE CategoryID = @CategoryID
);

-- Usage (like a parameterized view)
SELECT * FROM dbo.fn_GetProductsByCategory(1);

-- Join with other tables
SELECT p.*, c.CategoryName
FROM dbo.fn_GetProductsByCategory(1) p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

---

## Part 3: Multi-Statement Table-Valued Functions

Build and return a table using multiple statements.

```sql
CREATE FUNCTION dbo.fn_GetCustomerStats
(
    @CustomerID INT
)
RETURNS @Stats TABLE
(
    CustomerID INT,
    OrderCount INT,
    TotalRevenue DECIMAL(10,2),
    AvgOrderValue DECIMAL(10,2),
    LastOrderDate DATE
)
AS
BEGIN
    INSERT INTO @Stats
    SELECT 
        @CustomerID,
        COUNT(OrderID),
        SUM(TotalAmount),
        AVG(TotalAmount),
        MAX(OrderDate)
    FROM Orders
    WHERE CustomerID = @CustomerID;
    
    RETURN;
END;

-- Usage
SELECT * FROM dbo.fn_GetCustomerStats(5);
```

---

## Part 4: Functions in WHERE and Computed Columns

```sql
-- Scalar function in WHERE
SELECT ProductID, ProductName, Price
FROM Products
WHERE dbo.fn_CalculateTax(Price, 0.08) > 10;

-- Computed column
ALTER TABLE Products
ADD TaxAmount AS dbo.fn_CalculateTax(Price, 0.08) PERSISTED;
```

---

## Part 5: Deterministic vs Non-Deterministic

### Deterministic

Same inputs always produce same output. Can be indexed.

```sql
CREATE FUNCTION dbo.fn_FullName
(
    @FirstName NVARCHAR(50),
    @LastName NVARCHAR(50)
)
RETURNS NVARCHAR(101)
WITH SCHEMABINDING
AS
BEGIN
    RETURN @FirstName + ' ' + @LastName;
END;
```

### Non-Deterministic

Output varies (e.g., uses GETDATE(), NEWID()). Cannot be indexed.

```sql
CREATE FUNCTION dbo.fn_AgeInYears
(
    @BirthDate DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @BirthDate, GETDATE()); -- Non-deterministic
END;
```

---

## Part 6: Performance Considerations

### Inline table-valued functions

- **Fast:** Optimizer integrates into query plan
- Equivalent to parameterized view
- Recommended for table-returning functions

### Multi-statement table-valued functions

- **Slower:** Executes separately, optimizer has limited visibility
- Use only when logic requires multiple statements
- Consider stored procedures as alternative

### Scalar functions

- **Can be slow:** Executes per row when used in SELECT
- Avoid in WHERE on large tables (prevents sargability)
- Use inline expressions or computed columns when possible

```sql
-- SLOW: Scalar function per row
SELECT ProductName, dbo.fn_CalculateTax(Price, 0.08) AS Tax
FROM Products; -- Function called for every row

-- FASTER: Inline calculation
SELECT ProductName, Price * 0.08 AS Tax
FROM Products;
```

---

## Part 7: Practical Examples

### Example 1: Business Day Calculator

```sql
CREATE FUNCTION dbo.fn_IsBusinessDay
(
    @Date DATE
)
RETURNS BIT
AS
BEGIN
    DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @Date);
    
    -- Check if weekend (assuming Sunday=1, Saturday=7)
    IF @DayOfWeek IN (1, 7)
        RETURN 0;
    
    -- Check if holiday (simplified)
    IF EXISTS (SELECT 1 FROM Holidays WHERE HolidayDate = @Date)
        RETURN 0;
    
    RETURN 1;
END;

-- Usage
SELECT OrderDate, dbo.fn_IsBusinessDay(OrderDate) AS IsBusinessDay
FROM Orders;
```

### Example 2: Split String Function

```sql
CREATE FUNCTION dbo.fn_SplitString
(
    @String NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Result TABLE (Value NVARCHAR(500))
AS
BEGIN
    DECLARE @Pos INT = 1;
    DECLARE @NextPos INT;
    
    WHILE @Pos <= LEN(@String)
    BEGIN
        SET @NextPos = CHARINDEX(@Delimiter, @String, @Pos);
        IF @NextPos = 0
            SET @NextPos = LEN(@String) + 1;
        
        INSERT INTO @Result
        VALUES (SUBSTRING(@String, @Pos, @NextPos - @Pos));
        
        SET @Pos = @NextPos + 1;
    END;
    
    RETURN;
END;

-- Usage
SELECT * FROM dbo.fn_SplitString('apple,banana,cherry', ',');
```

**Note:** SQL Server 2016+ has built-in STRING_SPLIT function.

---

## Part 8: Functions vs Procedures vs Views

| Feature | Function (Scalar) | Function (Table) | Stored Procedure | View |
|---------|-------------------|------------------|------------------|------|
| Returns value | Single value | Table | Multiple result sets | Table |
| Use in SELECT | Yes | Yes (as table) | No | Yes |
| DML allowed | No | No | Yes | Limited |
| Parameters | Yes | Yes | Yes | No |
| Performance | Can be slow | Inline = fast, Multi = slower | Fast | Fast |

---

## Part 9: Modifying and Dropping Functions

```sql
-- Alter
ALTER FUNCTION dbo.fn_CalculateTax
(
    @Amount DECIMAL(10,2),
    @TaxRate DECIMAL(5,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN ROUND(@Amount * @TaxRate, 2);
END;

-- Drop
DROP FUNCTION dbo.fn_CalculateTax;
```

---

## Part 10: Best Practices

- Prefer inline table-valued functions over multi-statement
- Avoid scalar functions in WHERE or SELECT on large tables
- Use WITH SCHEMABINDING for deterministic functions
- Keep functions simple and focused
- Document expected inputs/outputs
- Consider alternatives (inline expressions, computed columns, CTEs)
- Use built-in functions when available (STRING_SPLIT, etc.)

---

## Practice Exercises

1. Create a scalar function to calculate discount amount based on customer tier.
2. Create an inline table-valued function to return top N products by revenue.
3. Build a multi-statement function that returns a calendar table for a given year.
4. Compare performance of a scalar function vs inline calculation on a large table.

---

## Key Takeaways

- Scalar functions return single values
- Inline table-valued functions are fast and flexible
- Multi-statement functions are slower; use sparingly
- Functions can be used in SELECT, WHERE, computed columns
- Performance matters: inline > multi-statement, expressions > scalar functions

---

## Next Lesson

Continue to [Lesson 6: Triggers](../06-triggers/triggers.md).
