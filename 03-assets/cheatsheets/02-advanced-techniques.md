# Advanced SQL Techniques Cheatsheet

Quick reference for intermediate and advanced SQL patterns used in data engineering and analytics.

---

## 📋 Table of Contents

1. [Advanced JOINs](#advanced-joins)
2. [Query Optimization](#query-optimization)
3. [Temporal Tables](#temporal-tables)
4. [JSON Processing](#json-processing)
5. [Dynamic SQL](#dynamic-sql)
6. [Stored Procedures](#stored-procedures)
7. [Error Handling](#error-handling)
8. [Performance Patterns](#performance-patterns)

---

## Advanced JOINs

### Lateral Joins (CROSS APPLY / OUTER APPLY)

```sql
-- Get top 3 orders per customer
SELECT 
    c.CustomerID,
    c.FirstName,
    oa.OrderID,
    oa.TotalAmount
FROM Customers c
OUTER APPLY (
    SELECT TOP 3 OrderID, TotalAmount
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) oa
ORDER BY c.CustomerID;
```

**When to use**:
- Top N per group
- Calling table-valued functions
- Correlated subqueries that return multiple rows

### Non-Equi JOINs

```sql
-- Find orders within price range
SELECT 
    o.OrderID,
    o.TotalAmount,
    pr.RangeName
FROM Orders o
INNER JOIN PriceRanges pr 
    ON o.TotalAmount BETWEEN pr.MinPrice AND pr.MaxPrice;
```

### Self-Referencing Hierarchies

```sql
-- Employee org chart with level
WITH EmployeeHierarchy AS (
    SELECT 
        EmployeeID,
        EmployeeName,
        ManagerID,
        0 AS Level,
        CAST(EmployeeName AS VARCHAR(1000)) AS Path
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    SELECT 
        e.EmployeeID,
        e.EmployeeName,
        e.ManagerID,
        eh.Level + 1,
        CAST(eh.Path + ' > ' + e.EmployeeName AS VARCHAR(1000))
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT * FROM EmployeeHierarchy
ORDER BY Path;
```

---

## Query Optimization

### Query Hints

```sql
-- Force index usage
SELECT * FROM Orders WITH (INDEX(IX_Orders_OrderDate))
WHERE OrderDate >= '2025-01-01';

-- Prevent table locks
SELECT * FROM Orders WITH (NOLOCK)
WHERE CustomerID = 123;

-- Force order of joins
SELECT * FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
OPTION (FORCE ORDER);
```

### Index Hints

```sql
-- Create covering index (include columns)
CREATE NONCLUSTERED INDEX IX_Orders_Covering
ON Orders(CustomerID, OrderDate)
INCLUDE (TotalAmount, Status);

-- Filtered index (for common WHERE conditions)
CREATE NONCLUSTERED INDEX IX_Orders_Active
ON Orders(OrderDate)
WHERE Status = 'Active';

-- Columnstore index (for analytics)
CREATE NONCLUSTERED COLUMNSTORE INDEX IX_Orders_Columnstore
ON Orders(OrderDate, CustomerID, TotalAmount);
```

### Statistics

```sql
-- Update statistics manually
UPDATE STATISTICS Orders;

-- Create statistics on specific columns
CREATE STATISTICS stat_orders_total ON Orders(TotalAmount);

-- View statistics
DBCC SHOW_STATISTICS('Orders', 'IX_Orders_OrderDate');
```

---

## Temporal Tables

### System-Versioned Tables

```sql
-- Create temporal table
CREATE TABLE Customers_Temporal (
    CustomerID INT PRIMARY KEY,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Email VARCHAR(100),
    -- Period columns
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Customers_History));

-- Query historical data
SELECT * FROM Customers_Temporal
FOR SYSTEM_TIME AS OF '2025-01-01';

-- Query all versions
SELECT * FROM Customers_Temporal
FOR SYSTEM_TIME ALL
WHERE CustomerID = 123;
```

---

## JSON Processing

### Parsing JSON

```sql
-- Parse JSON string
DECLARE @json NVARCHAR(MAX) = N'{
    "customer": {
        "name": "John Doe",
        "orders": [
            {"id": 1, "amount": 100.00},
            {"id": 2, "amount": 250.00}
        ]
    }
}';

-- Extract values
SELECT 
    JSON_VALUE(@json, '$.customer.name') AS CustomerName,
    JSON_VALUE(@json, '$.customer.orders[0].amount') AS FirstOrderAmount;

-- Parse JSON array
SELECT *
FROM OPENJSON(@json, '$.customer.orders')
WITH (
    id INT '$.id',
    amount DECIMAL(10,2) '$.amount'
);
```

### Generating JSON

```sql
-- Convert rows to JSON
SELECT 
    CustomerID,
    FirstName,
    LastName,
    (
        SELECT OrderID, TotalAmount
        FROM Orders o
        WHERE o.CustomerID = c.CustomerID
        FOR JSON PATH
    ) AS Orders
FROM Customers c
FOR JSON PATH;

-- Result:
-- [{"CustomerID":1,"FirstName":"John","Orders":[{"OrderID":101,"TotalAmount":99.99}]}]
```

---

## Dynamic SQL

### Building Dynamic Queries

```sql
-- Basic dynamic SQL
DECLARE @TableName NVARCHAR(128) = 'Orders';
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'SELECT * FROM ' + QUOTENAME(@TableName);
EXEC sp_executesql @SQL;

-- With parameters
DECLARE @MinAmount DECIMAL(10,2) = 100.00;
SET @SQL = N'SELECT * FROM Orders WHERE TotalAmount >= @MinAmount';
EXEC sp_executesql @SQL, N'@MinAmount DECIMAL(10,2)', @MinAmount;
```

### Dynamic Pivot

```sql
-- Generate pivot columns dynamically
DECLARE @Columns NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);

-- Get distinct categories
SELECT @Columns = STRING_AGG(QUOTENAME(Category), ',')
FROM (SELECT DISTINCT Category FROM Products) AS Categories;

-- Build dynamic PIVOT query
SET @SQL = N'
SELECT *
FROM (
    SELECT Category, ProductName, Price
    FROM Products
) AS Source
PIVOT (
    MAX(Price)
    FOR Category IN (' + @Columns + ')
) AS PivotTable';

EXEC sp_executesql @SQL;
```

---

## Stored Procedures

### Basic Procedure

```sql
CREATE OR ALTER PROCEDURE usp_GetCustomerOrders
    @CustomerID INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        o.OrderID,
        o.OrderDate,
        o.TotalAmount,
        o.Status
    FROM Orders o
    WHERE o.CustomerID = @CustomerID
      AND (@StartDate IS NULL OR o.OrderDate >= @StartDate)
      AND (@EndDate IS NULL OR o.OrderDate <= @EndDate)
    ORDER BY o.OrderDate DESC;
END;
GO

-- Execute
EXEC usp_GetCustomerOrders @CustomerID = 123, @StartDate = '2025-01-01';
```

### Output Parameters

```sql
CREATE OR ALTER PROCEDURE usp_GetOrderStats
    @CustomerID INT,
    @TotalOrders INT OUTPUT,
    @TotalRevenue DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        @TotalOrders = COUNT(*),
        @TotalRevenue = SUM(TotalAmount)
    FROM Orders
    WHERE CustomerID = @CustomerID;
END;
GO

-- Execute with output
DECLARE @OrderCount INT, @Revenue DECIMAL(10,2);
EXEC usp_GetOrderStats 
    @CustomerID = 123,
    @TotalOrders = @OrderCount OUTPUT,
    @TotalRevenue = @Revenue OUTPUT;
SELECT @OrderCount AS Orders, @Revenue AS Revenue;
```

### Table-Valued Functions

```sql
-- Inline table-valued function
CREATE OR ALTER FUNCTION fn_GetCustomerOrders(@CustomerID INT)
RETURNS TABLE
AS
RETURN (
    SELECT OrderID, OrderDate, TotalAmount
    FROM Orders
    WHERE CustomerID = @CustomerID
);
GO

-- Use like a table
SELECT * FROM fn_GetCustomerOrders(123);
```

---

## Error Handling

### TRY-CATCH Blocks

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Your operations
    UPDATE Accounts SET Balance = Balance - 100 WHERE AccountID = 1;
    UPDATE Accounts SET Balance = Balance + 100 WHERE AccountID = 2;
    
    COMMIT TRANSACTION;
    PRINT 'Transfer successful';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Log error details
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorLine INT = ERROR_LINE();
    
    PRINT 'Error on line ' + CAST(@ErrorLine AS VARCHAR(10));
    PRINT 'Message: ' + @ErrorMessage;
    
    -- Re-throw error
    THROW;
END CATCH;
```

### Custom Error Messages

```sql
-- Add custom error message
EXEC sp_addmessage 
    @msgnum = 50001,
    @severity = 16,
    @msgtext = 'Insufficient funds in account %d. Available: %s, Required: %s';

-- Raise custom error
RAISERROR(50001, 16, 1, 123, '50.00', '100.00');

-- Or use THROW (SQL Server 2012+)
THROW 50001, 'Custom error message', 1;
```

---

## Performance Patterns

### Batching Large Operations

```sql
-- Delete in batches to avoid lock escalation
DECLARE @BatchSize INT = 1000;
DECLARE @RowsDeleted INT = @BatchSize;

WHILE @RowsDeleted = @BatchSize
BEGIN
    DELETE TOP (@BatchSize)
    FROM Orders
    WHERE OrderDate < '2020-01-01';
    
    SET @RowsDeleted = @@ROWCOUNT;
    
    -- Pause to allow other queries
    WAITFOR DELAY '00:00:01';
END;
```

### Set-Based vs Cursor Operations

```sql
-- ❌ SLOW: Cursor approach
DECLARE @OrderID INT;
DECLARE order_cursor CURSOR FOR SELECT OrderID FROM Orders;
OPEN order_cursor;
FETCH NEXT FROM order_cursor INTO @OrderID;
WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE Orders SET Status = 'Processed' WHERE OrderID = @OrderID;
    FETCH NEXT FROM order_cursor INTO @OrderID;
END;
CLOSE order_cursor;
DEALLOCATE order_cursor;

-- ✅ FAST: Set-based approach
UPDATE Orders SET Status = 'Processed';
```

### Indexing Strategy

```sql
-- Analyze missing indexes
SELECT 
    OBJECT_NAME(mid.object_id) AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.avg_user_impact,
    migs.user_seeks
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
ORDER BY migs.avg_user_impact DESC;
```

### Query Execution Plan Analysis

```sql
-- Show actual execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM Orders WHERE CustomerID = 123;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- View plan cache
SELECT 
    qs.execution_count,
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.execution_count DESC;
```

---

## 🔥 Advanced Patterns

### Gap and Islands

```sql
-- Find consecutive date ranges
WITH DateSequence AS (
    SELECT 
        OrderDate,
        ROW_NUMBER() OVER (ORDER BY OrderDate) AS rn,
        DATEADD(DAY, -ROW_NUMBER() OVER (ORDER BY OrderDate), OrderDate) AS grp
    FROM (SELECT DISTINCT CAST(OrderDate AS DATE) AS OrderDate FROM Orders) d
)
SELECT 
    MIN(OrderDate) AS RangeStart,
    MAX(OrderDate) AS RangeEnd,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) + 1 AS ConsecutiveDays
FROM DateSequence
GROUP BY grp
ORDER BY RangeStart;
```

### Running Total with Reset

```sql
-- Running total that resets per customer
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Orders
ORDER BY CustomerID, OrderDate;
```

### Deduplication

```sql
-- Remove duplicates keeping most recent
WITH DuplicateCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY Email ORDER BY CreatedDate DESC) AS rn
    FROM Customers
)
DELETE FROM DuplicateCustomers WHERE rn > 1;
```

---

**Pro Tips**:
- Always test on non-production data first
- Use execution plans to identify bottlenecks
- Avoid cursors; use set-based operations
- Index foreign keys and frequently filtered columns
- Monitor query performance regularly

---

*Last Updated: November 14, 2025*
