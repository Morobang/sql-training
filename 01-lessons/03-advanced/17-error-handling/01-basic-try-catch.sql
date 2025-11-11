-- ========================================
-- Basic TRY...CATCH Error Handling
-- ========================================

USE TechStore;

-- =============================================
-- Example 1: Simple TRY...CATCH
-- =============================================

BEGIN TRY
    -- This will cause an error (divide by zero)
    SELECT 10 / 0 AS Result;
    PRINT 'This line will not execute';
END TRY
BEGIN CATCH
    PRINT 'An error occurred!';
    PRINT 'Error Message: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 2: Catching INSERT Errors
-- =============================================

BEGIN TRY
    -- Try to insert duplicate CustomerID (violates PRIMARY KEY)
    INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
    VALUES (1, 'Duplicate Customer', 'Los Angeles', 'CA', GETDATE());
    
    PRINT 'Insert successful';
END TRY
BEGIN CATCH
    PRINT 'Insert failed!';
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
END CATCH;

-- =============================================
-- Example 3: All ERROR Functions
-- =============================================

BEGIN TRY
    -- Attempt an invalid UPDATE
    UPDATE Products 
    SET Price = 'invalid'  -- This will fail (cannot convert string to decimal)
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_LINE() AS ErrorLine,
        ERROR_PROCEDURE() AS ErrorProcedure;
END CATCH;

-- =============================================
-- Example 4: Handling NULL Constraint Violations
-- =============================================

BEGIN TRY
    -- Try to insert NULL into NOT NULL column
    INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity)
    VALUES (NULL, 'Electronics', 500.00, 300.00, 10);
    
    PRINT 'Product inserted';
END TRY
BEGIN CATCH
    PRINT '❌ Cannot insert NULL product name';
    PRINT 'Error Details: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 5: Foreign Key Violation
-- =============================================

BEGIN TRY
    -- Try to delete a product that has sales (FK violation)
    DELETE FROM Products WHERE ProductID = 1;
    PRINT 'Product deleted';
END TRY
BEGIN CATCH
    PRINT '❌ Cannot delete product - it has associated sales records';
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 6: Graceful Error Recovery
-- =============================================

DECLARE @ErrorOccurred BIT = 0;

BEGIN TRY
    -- Try to update a non-existent product
    UPDATE Products 
    SET Price = 999.99
    WHERE ProductID = 99999;  -- Doesn't exist
    
    IF @@ROWCOUNT = 0
    BEGIN
        -- Not an error, but no rows affected
        RAISERROR('Product ID 99999 not found', 16, 1);
    END;
    
    PRINT 'Update successful';
END TRY
BEGIN CATCH
    SET @ErrorOccurred = 1;
    PRINT '⚠️ Update failed: ' + ERROR_MESSAGE();
END CATCH;

IF @ErrorOccurred = 0
    PRINT '✅ Operation completed successfully';
ELSE
    PRINT '❌ Operation failed - review errors above';

-- =============================================
-- Example 7: Multiple Operations with Error Handling
-- =============================================

BEGIN TRY
    -- Operation 1: Update stock
    UPDATE Products 
    SET StockQuantity = StockQuantity - 5
    WHERE ProductID = 1;
    PRINT 'Stock updated';
    
    -- Operation 2: Log the transaction (simulated)
    PRINT 'Transaction logged';
    
    -- Operation 3: Attempt invalid operation
    SELECT 1 / 0;  -- This will fail
    
    PRINT 'This will not print';
END TRY
BEGIN CATCH
    PRINT 'Error in operation sequence';
    PRINT 'Failed at line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Error: ' + ERROR_MESSAGE();
    
    -- Rollback changes if needed (covered in transactions lesson)
    PRINT 'Rolling back changes...';
END CATCH;

-- =============================================
-- Example 8: Conditional Error Handling
-- =============================================

DECLARE @ProductID INT = 1;
DECLARE @Quantity INT = 100;  -- Trying to reduce stock by too much

BEGIN TRY
    -- Check if enough stock exists
    DECLARE @CurrentStock INT;
    SELECT @CurrentStock = StockQuantity 
    FROM Products 
    WHERE ProductID = @ProductID;
    
    IF @CurrentStock < @Quantity
    BEGIN
        RAISERROR('Insufficient stock: %d available, %d requested', 16, 1, @CurrentStock, @Quantity);
    END;
    
    -- If we get here, stock is sufficient
    UPDATE Products 
    SET StockQuantity = StockQuantity - @Quantity
    WHERE ProductID = @ProductID;
    
    PRINT 'Stock reduced successfully';
END TRY
BEGIN CATCH
    PRINT 'Stock update failed:';
    PRINT ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 9: Nested TRY...CATCH
-- =============================================

BEGIN TRY
    PRINT 'Outer TRY block';
    
    BEGIN TRY
        PRINT 'Inner TRY block';
        SELECT 10 / 0;  -- Error in inner block
    END TRY
    BEGIN CATCH
        PRINT 'Inner CATCH: ' + ERROR_MESSAGE();
        -- Re-throw the error to outer block
        THROW;
    END CATCH;
    
END TRY
BEGIN CATCH
    PRINT 'Outer CATCH: ' + ERROR_MESSAGE();
END CATCH;

-- 💡 Key Points:
-- - TRY...CATCH provides structured error handling
-- - Use ERROR_* functions to get error details
-- - Errors stop execution and jump to CATCH block
-- - RAISERROR creates custom errors
-- - THROW re-raises the current error
-- - Always handle or log errors appropriately
