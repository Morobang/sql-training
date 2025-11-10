# Lesson 4: Stored Procedures

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Create and execute stored procedures
2. Use input and output parameters
3. Return result sets and return values
4. Implement error handling with TRY/CATCH
5. Understand when to use stored procedures vs ad-hoc queries

---

## Part 1: Creating a Stored Procedure

```sql
CREATE PROCEDURE usp_GetProductsByCategory
    @CategoryID INT
AS
BEGIN
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE CategoryID = @CategoryID
    ORDER BY ProductName;
END;
```

### Executing

```sql
EXEC usp_GetProductsByCategory @CategoryID = 1;
-- or
EXECUTE usp_GetProductsByCategory 1;
```

---

## Part 2: Input Parameters

```sql
CREATE PROCEDURE usp_SearchProducts
    @MinPrice DECIMAL(10,2) = 0,
    @MaxPrice DECIMAL(10,2) = 999999,
    @ProductName NVARCHAR(100) = NULL
AS
BEGIN
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE Price BETWEEN @MinPrice AND @MaxPrice
      AND (@ProductName IS NULL OR ProductName LIKE '%' + @ProductName + '%')
    ORDER BY Price;
END;

-- Call with all parameters
EXEC usp_SearchProducts @MinPrice = 10, @MaxPrice = 100, @ProductName = 'Widget';

-- Call with defaults
EXEC usp_SearchProducts @ProductName = 'Widget';
```

---

## Part 3: Output Parameters

```sql
CREATE PROCEDURE usp_GetOrderStats
    @CustomerID INT,
    @OrderCount INT OUTPUT,
    @TotalRevenue DECIMAL(10,2) OUTPUT
AS
BEGIN
    SELECT 
        @OrderCount = COUNT(*),
        @TotalRevenue = SUM(TotalAmount)
    FROM Orders
    WHERE CustomerID = @CustomerID;
END;

-- Execute with output
DECLARE @Count INT, @Revenue DECIMAL(10,2);
EXEC usp_GetOrderStats 
    @CustomerID = 5, 
    @OrderCount = @Count OUTPUT, 
    @TotalRevenue = @Revenue OUTPUT;
SELECT @Count AS OrderCount, @Revenue AS Revenue;
```

---

## Part 4: Return Values

```sql
CREATE PROCEDURE usp_InsertProduct
    @ProductName NVARCHAR(100),
    @Price DECIMAL(10,2),
    @CategoryID INT
AS
BEGIN
    -- Validation
    IF @Price < 0
        RETURN -1; -- Error code
    
    IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @CategoryID)
        RETURN -2; -- Invalid category
    
    INSERT INTO Products (ProductName, Price, CategoryID)
    VALUES (@ProductName, @Price, @CategoryID);
    
    RETURN 0; -- Success
END;

-- Execute and check return
DECLARE @Result INT;
EXEC @Result = usp_InsertProduct 
    @ProductName = 'New Product', 
    @Price = 99.99, 
    @CategoryID = 1;
IF @Result = 0
    PRINT 'Success';
ELSE
    PRINT 'Error code: ' + CAST(@Result AS VARCHAR);
```

---

## Part 5: Error Handling with TRY/CATCH

```sql
CREATE PROCEDURE usp_TransferFunds
    @FromAccount INT,
    @ToAccount INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Debit
        UPDATE Accounts
        SET Balance = Balance - @Amount
        WHERE AccountID = @FromAccount;
        
        IF @@ROWCOUNT = 0
            THROW 50001, 'Source account not found', 1;
        
        -- Credit
        UPDATE Accounts
        SET Balance = Balance + @Amount
        WHERE AccountID = @ToAccount;
        
        IF @@ROWCOUNT = 0
            THROW 50002, 'Destination account not found', 1;
        
        COMMIT TRANSACTION;
        PRINT 'Transfer completed';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH;
END;
```

---

## Part 6: Multiple Result Sets

```sql
CREATE PROCEDURE usp_CustomerSummary
    @CustomerID INT
AS
BEGIN
    -- Result set 1: Customer info
    SELECT CustomerID, CustomerName, Email
    FROM Customers
    WHERE CustomerID = @CustomerID;
    
    -- Result set 2: Order history
    SELECT OrderID, OrderDate, TotalAmount
    FROM Orders
    WHERE CustomerID = @CustomerID
    ORDER BY OrderDate DESC;
    
    -- Result set 3: Summary stats
    SELECT 
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Orders
    WHERE CustomerID = @CustomerID;
END;
```

---

## Part 7: Dynamic SQL in Procedures

```sql
CREATE PROCEDURE usp_DynamicSort
    @SortColumn NVARCHAR(50) = 'ProductName'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Validate column to prevent SQL injection
    IF @SortColumn NOT IN ('ProductName', 'Price', 'CategoryID')
        SET @SortColumn = 'ProductName';
    
    SET @SQL = N'SELECT ProductID, ProductName, Price, CategoryID
                 FROM Products
                 ORDER BY ' + QUOTENAME(@SortColumn);
    
    EXEC sp_executesql @SQL;
END;
```

**Warning:** Always validate/sanitize inputs to prevent SQL injection.

---

## Part 8: Modifying and Dropping Procedures

```sql
-- Alter
ALTER PROCEDURE usp_GetProductsByCategory
    @CategoryID INT
AS
BEGIN
    SELECT ProductID, ProductName, Price, Stock
    FROM Products
    WHERE CategoryID = @CategoryID AND Stock > 0
    ORDER BY ProductName;
END;

-- Drop
DROP PROCEDURE usp_GetProductsByCategory;
```

---

## Part 9: Benefits of Stored Procedures

- **Performance:** Compiled and cached execution plans
- **Security:** Grant EXECUTE without table access
- **Maintainability:** Centralized business logic
- **Reduced network traffic:** Single call vs multiple queries
- **Consistency:** Enforce business rules

---

## Part 10: Practical Examples

### Example 1: Place Order

```sql
CREATE PROCEDURE usp_PlaceOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @OrderID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check stock
        DECLARE @Stock INT;
        SELECT @Stock = Stock FROM Products WHERE ProductID = @ProductID;
        
        IF @Stock < @Quantity
            THROW 50001, 'Insufficient stock', 1;
        
        -- Create order
        INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
        VALUES (@CustomerID, GETDATE(), 0);
        
        SET @OrderID = SCOPE_IDENTITY();
        
        -- Add order detail
        DECLARE @UnitPrice DECIMAL(10,2);
        SELECT @UnitPrice = Price FROM Products WHERE ProductID = @ProductID;
        
        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
        VALUES (@OrderID, @ProductID, @Quantity, @UnitPrice);
        
        -- Update order total
        UPDATE Orders
        SET TotalAmount = @Quantity * @UnitPrice
        WHERE OrderID = @OrderID;
        
        -- Reduce stock
        UPDATE Products
        SET Stock = Stock - @Quantity
        WHERE ProductID = @ProductID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

### Example 2: Cleanup Old Data

```sql
CREATE PROCEDURE usp_ArchiveOldOrders
    @DaysOld INT = 365,
    @RowsArchived INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CutoffDate DATE = DATEADD(DAY, -@DaysOld, GETDATE());
    
    BEGIN TRANSACTION;
    
    -- Copy to archive
    INSERT INTO OrdersArchive
    SELECT * FROM Orders WHERE OrderDate < @CutoffDate;
    
    SET @RowsArchived = @@ROWCOUNT;
    
    -- Delete from main table
    DELETE FROM Orders WHERE OrderDate < @CutoffDate;
    
    COMMIT TRANSACTION;
END;
```

---

## Part 11: Best Practices

- Use naming convention (usp_, sp_proc_)
- SET NOCOUNT ON to suppress row count messages
- Use TRY/CATCH for error handling
- Always validate input parameters
- Use QUOTENAME for dynamic SQL identifiers
- Document parameters and behavior
- Keep procedures focused (single responsibility)

---

## Practice Exercises

1. Create a procedure to update product prices with validation and error handling.
2. Build a procedure that returns customer info and their top 5 orders.
3. Write a procedure with output parameters to calculate order statistics.
4. Implement a procedure with dynamic SQL for flexible searching.

---

## Key Takeaways

- Stored procedures encapsulate SQL logic
- Use parameters (input, output, return values)
- TRY/CATCH for error handling
- Dynamic SQL requires careful validation
- Benefits: performance, security, maintainability

---

## Next Lesson

Continue to [Lesson 5: Functions (UDFs)](../05-functions/05-functions.md).
