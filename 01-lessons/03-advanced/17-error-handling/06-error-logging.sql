-- ========================================
-- Error Logging Systems
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Create Error Log Table
-- =============================================

-- Drop if exists
IF OBJECT_ID('ErrorLog', 'U') IS NOT NULL
    DROP TABLE ErrorLog;

-- Create comprehensive error log
CREATE TABLE ErrorLog (
    ErrorLogID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorNumber INT,
    ErrorSeverity INT,
    ErrorState INT,
    ErrorProcedure NVARCHAR(128),
    ErrorLine INT,
    ErrorMessage NVARCHAR(4000),
    ErrorUser NVARCHAR(128) DEFAULT SUSER_NAME(),
    ErrorHost NVARCHAR(128) DEFAULT HOST_NAME(),
    ErrorDatabase NVARCHAR(128) DEFAULT DB_NAME(),
    ErrorTimestamp DATETIME DEFAULT GETDATE(),
    AdditionalInfo NVARCHAR(MAX) NULL
);

PRINT '✅ ErrorLog table created';

-- =============================================
-- Example 2: Simple Error Logging Procedure
-- =============================================

CREATE OR ALTER PROCEDURE LogError
    @AdditionalInfo NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ErrorLog (
        ErrorNumber,
        ErrorSeverity,
        ErrorState,
        ErrorProcedure,
        ErrorLine,
        ErrorMessage,
        AdditionalInfo
    )
    VALUES (
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        @AdditionalInfo
    );
    
    SELECT SCOPE_IDENTITY() AS LoggedErrorID;
END;
GO

-- Test error logging
BEGIN TRY
    SELECT 1 / 0;
END TRY
BEGIN CATCH
    EXEC LogError @AdditionalInfo = 'Testing error logging';
END CATCH;

-- View logged errors
SELECT * FROM ErrorLog ORDER BY ErrorTimestamp DESC;

-- =============================================
-- Example 3: Procedure with Built-in Logging
-- =============================================

CREATE OR ALTER PROCEDURE UpdateProductPrice
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validation
        IF @NewPrice <= 0
            THROW 50001, 'Price must be positive', 1;
        
        IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
        BEGIN
            DECLARE @Msg NVARCHAR(100);
            SET @Msg = 'Product ID ' + CAST(@ProductID AS VARCHAR) + ' not found';
            THROW 50002, @Msg, 1;
        END;
        
        -- Update price
        UPDATE Products 
        SET Price = @NewPrice
        WHERE ProductID = @ProductID;
        
        PRINT '✅ Price updated successfully';
        
    END TRY
    BEGIN CATCH
        -- Log the error
        DECLARE @Info NVARCHAR(500);
        SET @Info = 'ProductID: ' + CAST(@ProductID AS VARCHAR) + ', NewPrice: ' + CAST(@NewPrice AS VARCHAR);
        
        EXEC LogError @AdditionalInfo = @Info;
        
        -- Display error to user
        PRINT '❌ Price update failed - error logged';
        PRINT 'Error: ' + ERROR_MESSAGE();
        
        -- Re-throw
        THROW;
    END CATCH;
END;
GO

-- Test with errors
EXEC UpdateProductPrice @ProductID = 1, @NewPrice = 599.99;     -- Success
EXEC UpdateProductPrice @ProductID = 999, @NewPrice = 100.00;   -- Not found (logged)
EXEC UpdateProductPrice @ProductID = 1, @NewPrice = -50.00;     -- Invalid (logged)

-- View error log
SELECT 
    ErrorLogID,
    ErrorNumber,
    ErrorMessage,
    ErrorProcedure,
    AdditionalInfo,
    ErrorTimestamp
FROM ErrorLog
ORDER BY ErrorTimestamp DESC;

-- =============================================
-- Example 4: Categorized Error Logging
-- =============================================

-- Add error categories
ALTER TABLE ErrorLog ADD ErrorCategory NVARCHAR(50) NULL;

CREATE OR ALTER PROCEDURE LogCategorizedError
    @Category NVARCHAR(50),
    @AdditionalInfo NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ErrorLog (
        ErrorNumber,
        ErrorSeverity,
        ErrorState,
        ErrorProcedure,
        ErrorLine,
        ErrorMessage,
        ErrorCategory,
        AdditionalInfo
    )
    VALUES (
        ERROR_NUMBER(),
        ERROR_SEVERITY(),
        ERROR_STATE(),
        ERROR_PROCEDURE(),
        ERROR_LINE(),
        ERROR_MESSAGE(),
        @Category,
        @AdditionalInfo
    );
END;
GO

-- Test categorized logging
BEGIN TRY
    INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
    VALUES (1, 'Duplicate', 'City', 'CA', GETDATE());
END TRY
BEGIN CATCH
    EXEC LogCategorizedError 
        @Category = 'Data Integrity',
        @AdditionalInfo = 'Attempted to insert duplicate customer';
END CATCH;

-- =============================================
-- Example 5: Error Summary Report
-- =============================================

-- View error summary by category
SELECT 
    ErrorCategory,
    COUNT(*) AS ErrorCount,
    MIN(ErrorTimestamp) AS FirstOccurrence,
    MAX(ErrorTimestamp) AS LastOccurrence
FROM ErrorLog
WHERE ErrorCategory IS NOT NULL
GROUP BY ErrorCategory
ORDER BY ErrorCount DESC;

-- View most common errors
SELECT TOP 5
    ErrorNumber,
    ErrorMessage,
    COUNT(*) AS Occurrences,
    MAX(ErrorTimestamp) AS LastOccurred
FROM ErrorLog
GROUP BY ErrorNumber, ErrorMessage
ORDER BY Occurrences DESC;

-- View errors by procedure
SELECT 
    ISNULL(ErrorProcedure, 'Ad-hoc Query') AS Source,
    COUNT(*) AS ErrorCount,
    MAX(ErrorTimestamp) AS LastError
FROM ErrorLog
GROUP BY ErrorProcedure
ORDER BY ErrorCount DESC;

-- =============================================
-- Example 6: Error Alert System
-- =============================================

CREATE OR ALTER PROCEDURE CheckCriticalErrors
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Count recent critical errors (last hour)
    DECLARE @CriticalCount INT;
    SELECT @CriticalCount = COUNT(*)
    FROM ErrorLog
    WHERE ErrorSeverity >= 16
        AND ErrorTimestamp >= DATEADD(HOUR, -1, GETDATE());
    
    IF @CriticalCount > 5
    BEGIN
        PRINT '⚠️ ALERT: ' + CAST(@CriticalCount AS VARCHAR) + ' critical errors in the last hour!';
        
        -- Show recent critical errors
        SELECT TOP 10
            ErrorLogID,
            ErrorNumber,
            ErrorMessage,
            ErrorProcedure,
            ErrorTimestamp
        FROM ErrorLog
        WHERE ErrorSeverity >= 16
            AND ErrorTimestamp >= DATEADD(HOUR, -1, GETDATE())
        ORDER BY ErrorTimestamp DESC;
    END
    ELSE
    BEGIN
        PRINT '✅ No unusual error activity detected';
    END;
END;
GO

-- Test alert system
EXEC CheckCriticalErrors;

-- =============================================
-- Example 7: Error Log Cleanup/Archival
-- =============================================

CREATE OR ALTER PROCEDURE CleanupErrorLog
    @DaysToKeep INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME = DATEADD(DAY, -@DaysToKeep, GETDATE());
    DECLARE @RowsDeleted INT;
    
    -- Archive old errors (in production, move to archive table)
    -- For this example, just delete
    DELETE FROM ErrorLog
    WHERE ErrorTimestamp < @CutoffDate;
    
    SET @RowsDeleted = @@ROWCOUNT;
    
    PRINT 'Deleted ' + CAST(@RowsDeleted AS VARCHAR) + ' error log entries older than ' + CAST(@DaysToKeep AS VARCHAR) + ' days';
END;
GO

-- Test cleanup (careful in production!)
-- EXEC CleanupErrorLog @DaysToKeep = 30;

-- =============================================
-- Example 8: Comprehensive Application Logging
-- =============================================

CREATE OR ALTER PROCEDURE ProcessOrderWithLogging
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate and process order
        DECLARE @StockQty INT, @Price DECIMAL(10,2);
        
        SELECT @StockQty = StockQuantity, @Price = Price
        FROM Products
        WHERE ProductID = @ProductID;
        
        IF @StockQty IS NULL
            THROW 50001, 'Product not found', 1;
        
        IF @StockQty < @Quantity
            THROW 50002, 'Insufficient stock', 1;
        
        -- Update stock
        UPDATE Products 
        SET StockQuantity = StockQuantity - @Quantity
        WHERE ProductID = @ProductID;
        
        -- Create sale
        INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
        VALUES (@CustomerID, @ProductID, @Quantity, GETDATE(), @Price * @Quantity, 'Credit Card');
        
        COMMIT TRANSACTION;
        PRINT '✅ Order processed successfully';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log with full context
        DECLARE @Context NVARCHAR(500);
        SET @Context = 'Order Processing Failed - CustomerID: ' + CAST(@CustomerID AS VARCHAR) + 
                       ', ProductID: ' + CAST(@ProductID AS VARCHAR) + 
                       ', Quantity: ' + CAST(@Quantity AS VARCHAR);
        
        EXEC LogCategorizedError 
            @Category = 'Order Processing',
            @AdditionalInfo = @Context;
        
        PRINT '❌ Order failed and logged';
        THROW;
    END CATCH;
END;
GO

-- Test comprehensive logging
EXEC ProcessOrderWithLogging @CustomerID = 1, @ProductID = 1, @Quantity = 2;
EXEC ProcessOrderWithLogging @CustomerID = 1, @ProductID = 999, @Quantity = 1;

-- View comprehensive error log
SELECT 
    ErrorLogID,
    ErrorCategory,
    ErrorMessage,
    ErrorProcedure,
    AdditionalInfo,
    ErrorTimestamp,
    ErrorUser
FROM ErrorLog
ORDER BY ErrorTimestamp DESC;

-- =============================================
-- Clean up procedures
-- =============================================
-- DROP PROCEDURE LogError;
-- DROP PROCEDURE UpdateProductPrice;
-- DROP PROCEDURE LogCategorizedError;
-- DROP PROCEDURE CheckCriticalErrors;
-- DROP PROCEDURE CleanupErrorLog;
-- DROP PROCEDURE ProcessOrderWithLogging;
-- DROP TABLE ErrorLog;

-- 💡 Key Error Logging Practices:
-- - Create dedicated error log table
-- - Capture all ERROR_* function outputs
-- - Add context (user, host, database, timestamp)
-- - Include additional info (parameters, state)
-- - Categorize errors for easier analysis
-- - Build summary reports for monitoring
-- - Implement cleanup/archival strategy
-- - Alert on critical error patterns
-- - Log errors before re-throwing
-- - Use error logs for troubleshooting and auditing
