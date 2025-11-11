-- ========================================
-- ERROR Functions: Detailed Information
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: All ERROR Functions Overview
-- =============================================

BEGIN TRY
    -- Cause an error
    UPDATE Products 
    SET Price = 'not a number'  -- Type conversion error
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,          -- Unique error ID
        ERROR_MESSAGE() AS ErrorMessage,        -- Error description
        ERROR_SEVERITY() AS ErrorSeverity,      -- Severity level (1-25)
        ERROR_STATE() AS ErrorState,            -- Error state code
        ERROR_LINE() AS ErrorLine,              -- Line number where error occurred
        ERROR_PROCEDURE() AS ErrorProcedure;    -- Stored procedure name (if applicable)
END CATCH;

-- =============================================
-- Example 2: ERROR_NUMBER() - Identifying Specific Errors
-- =============================================

BEGIN TRY
    -- Try to insert duplicate PRIMARY KEY
    INSERT INTO Customers (CustomerID, CustomerName, City, State, JoinDate)
    VALUES (1, 'Test', 'Test City', 'CA', GETDATE());
END TRY
BEGIN CATCH
    DECLARE @ErrorNum INT = ERROR_NUMBER();
    
    -- Handle specific error numbers
    IF @ErrorNum = 2627  -- Primary key violation
        PRINT '❌ Duplicate key error: Record already exists';
    ELSE IF @ErrorNum = 547  -- Foreign key violation
        PRINT '❌ Foreign key error: Referenced record not found';
    ELSE IF @ErrorNum = 515  -- Cannot insert NULL
        PRINT '❌ NULL value error: Required field is missing';
    ELSE
        PRINT '❌ Unknown error ' + CAST(@ErrorNum AS VARCHAR) + ': ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Example 3: ERROR_MESSAGE() - Error Descriptions
-- =============================================

BEGIN TRY
    DECLARE @BadValue INT;
    SET @BadValue = CAST('ABC' AS INT);  -- Cannot convert string to int
END TRY
BEGIN CATCH
    DECLARE @Message NVARCHAR(4000) = ERROR_MESSAGE();
    
    PRINT 'Full Error Message:';
    PRINT @Message;
    
    -- Extract and display parts
    PRINT '';
    PRINT 'Error Summary: Attempted invalid type conversion';
    PRINT 'System Message: ' + @Message;
END CATCH;

-- =============================================
-- Example 4: ERROR_SEVERITY() - Understanding Error Levels
-- =============================================

/*
Severity Levels:
0-10:  Informational messages
11-16: User errors (can be corrected by user)
17-19: Resource/system errors
20-25: Fatal/system errors (connection terminated)
*/

BEGIN TRY
    RAISERROR('This is a warning', 10, 1);  -- Severity 10 (informational)
END TRY
BEGIN CATCH
    -- This won't catch it (severity too low)
    PRINT 'Caught error';
END CATCH;

-- Severity 11+ will be caught
BEGIN TRY
    RAISERROR('This is an error', 16, 1);  -- Severity 16 (user error)
END TRY
BEGIN CATCH
    PRINT 'Severity Level: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    
    IF ERROR_SEVERITY() >= 16
        PRINT '⚠️ This is a serious error requiring attention';
    ELSE
        PRINT 'ℹ️ This is an informational message';
END CATCH;

-- =============================================
-- Example 5: ERROR_STATE() - Error State Codes
-- =============================================

-- State is used for multiple instances of same error
BEGIN TRY
    -- First instance: state 1
    IF EXISTS (SELECT 1 FROM Products WHERE Price < 0)
        RAISERROR('Negative price found', 16, 1);
    
    -- Second instance: state 2
    IF EXISTS (SELECT 1 FROM Products WHERE Cost < 0)
        RAISERROR('Negative cost found', 16, 2);
END TRY
BEGIN CATCH
    PRINT 'Error State: ' + CAST(ERROR_STATE() AS VARCHAR);
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    
    -- Use state to identify which check failed
    IF ERROR_STATE() = 1
        PRINT 'Problem: Price validation failed';
    ELSE IF ERROR_STATE() = 2
        PRINT 'Problem: Cost validation failed';
END CATCH;

-- =============================================
-- Example 6: ERROR_LINE() - Locating the Error
-- =============================================

BEGIN TRY
    PRINT 'Line 1: Starting process';
    PRINT 'Line 2: Checking data';
    
    DECLARE @Value INT = 10;
    SET @Value = @Value / 0;  -- Error occurs here (line ~171)
    
    PRINT 'Line 5: This will not execute';
END TRY
BEGIN CATCH
    PRINT 'Error occurred at line: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT 'Error was: ' + ERROR_MESSAGE();
    PRINT 'Debug: Check code around the reported line number';
END CATCH;

-- =============================================
-- Example 7: ERROR_PROCEDURE() - In Stored Procedures
-- =============================================

CREATE OR ALTER PROCEDURE TestErrorProcedure
AS
BEGIN
    BEGIN TRY
        -- Cause an error inside the procedure
        SELECT 1 / 0;
    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_PROCEDURE() AS ProcedureName,
            ERROR_LINE() AS LineInProcedure,
            ERROR_MESSAGE() AS ErrorDetails;
    END CATCH;
END;
GO

-- Execute and see procedure name in error
EXEC TestErrorProcedure;

DROP PROCEDURE TestErrorProcedure;

-- =============================================
-- Example 8: Comprehensive Error Logging
-- =============================================

-- Create error log table
CREATE TABLE #ErrorLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ErrorNumber INT,
    ErrorMessage NVARCHAR(4000),
    ErrorSeverity INT,
    ErrorState INT,
    ErrorLine INT,
    ErrorProcedure NVARCHAR(128),
    LoggedAt DATETIME DEFAULT GETDATE(),
    UserName NVARCHAR(128) DEFAULT SUSER_NAME()
);

-- Procedure that logs errors
CREATE OR ALTER PROCEDURE ProcessWithLogging
    @ProductID INT
AS
BEGIN
    BEGIN TRY
        -- Attempt to update product
        UPDATE Products 
        SET Price = Price * 1.1  -- 10% price increase
        WHERE ProductID = @ProductID;
        
        IF @@ROWCOUNT = 0
            RAISERROR('Product ID %d not found', 16, 1, @ProductID);
        
        PRINT 'Price updated successfully';
    END TRY
    BEGIN CATCH
        -- Log the error
        INSERT INTO #ErrorLog (ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ErrorLine, ErrorProcedure)
        VALUES (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_LINE(),
            ERROR_PROCEDURE()
        );
        
        -- Display error to user
        PRINT '❌ Error occurred - logged for review';
        PRINT 'Error ID: ' + CAST(SCOPE_IDENTITY() AS VARCHAR);
    END CATCH;
END;
GO

-- Test with invalid ProductID
EXEC ProcessWithLogging @ProductID = 99999;

-- View error log
SELECT * FROM #ErrorLog;

DROP PROCEDURE ProcessWithLogging;
DROP TABLE #ErrorLog;

-- =============================================
-- Example 9: Building Custom Error Messages
-- =============================================

BEGIN TRY
    DECLARE @ProductID INT = 99999;
    DECLARE @RequestedQty INT = 100;
    DECLARE @AvailableQty INT = 0;
    
    -- Check stock
    SELECT @AvailableQty = StockQuantity 
    FROM Products 
    WHERE ProductID = @ProductID;
    
    IF @AvailableQty IS NULL
    BEGIN
        DECLARE @Msg NVARCHAR(500);
        SET @Msg = 'Product ' + CAST(@ProductID AS VARCHAR) + ' does not exist';
        RAISERROR(@Msg, 16, 1);
    END;
    
    IF @AvailableQty < @RequestedQty
    BEGIN
        RAISERROR('Insufficient stock. Available: %d, Requested: %d', 16, 1, @AvailableQty, @RequestedQty);
    END;
END TRY
BEGIN CATCH
    -- Combine ERROR functions for detailed output
    PRINT '╔══════════════════════════════════════════╗';
    PRINT '║          ERROR DETAILS                   ║';
    PRINT '╠══════════════════════════════════════════╣';
    PRINT '║ Number:    ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '║ Severity:  ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT '║ State:     ' + CAST(ERROR_STATE() AS VARCHAR);
    PRINT '║ Line:      ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT '║ Message:   ' + ERROR_MESSAGE();
    PRINT '╚══════════════════════════════════════════╝';
END CATCH;

-- 💡 Key ERROR Functions:
-- - ERROR_NUMBER(): Numeric error code (e.g., 547, 2627)
-- - ERROR_MESSAGE(): Human-readable description
-- - ERROR_SEVERITY(): Importance level (11-25 are catchable)
-- - ERROR_STATE(): State code for same error in different contexts
-- - ERROR_LINE(): Line number where error occurred
-- - ERROR_PROCEDURE(): Stored procedure name (NULL if not in proc)
-- - Use these to build comprehensive error logging systems
