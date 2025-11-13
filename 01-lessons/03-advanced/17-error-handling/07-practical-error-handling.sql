-- ========================================
-- Practical Error Handling Patterns
-- ========================================

USE TechStore;
GO

-- =============================================
-- Pattern 1: Idempotent Operations
-- =============================================
-- Ensure running the same operation multiple times has the same effect

BEGIN TRY
    BEGIN TRANSACTION;

    -- Example: Safe upsert for inventory adjustment
    DECLARE @ProductID INT = 1;
    DECLARE @Delta INT = -5;

    IF EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        UPDATE Products
        SET StockQuantity = CASE WHEN StockQuantity + @Delta < 0 THEN 0 ELSE StockQuantity + @Delta END
        WHERE ProductID = @ProductID;
    END
    ELSE
    BEGIN
        INSERT INTO Products (ProductID, ProductName, Category, Price, Cost, StockQuantity)
        VALUES (@ProductID, 'Placeholder', 'Unknown', 0, 0, CASE WHEN @Delta < 0 THEN 0 ELSE @Delta END);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH;

-- =============================================
-- Pattern 2: Retry Loop for Transient Errors
-- =============================================
-- Retry a short-lived operation (e.g., deadlock, timeout)

DECLARE @Attempt INT = 1;
DECLARE @MaxAttempts INT = 3;
DECLARE @Succeeded BIT = 0;

WHILE @Attempt <= @MaxAttempts AND @Succeeded = 0
BEGIN
    BEGIN TRY
        -- Replace with idempotent work
        UPDATE Products SET Price = Price WHERE ProductID = 1; -- no-op example
        SET @Succeeded = 1;
    END TRY
    BEGIN CATCH
        PRINT 'Attempt ' + CAST(@Attempt AS VARCHAR) + ' failed: ' + ERROR_MESSAGE();
        SET @Attempt = @Attempt + 1;
        IF @Attempt <= @MaxAttempts
            WAITFOR DELAY '00:00:01'; -- Simple fixed delay between retries
        ELSE
            PRINT 'Retries exhausted';
    END CATCH;
END;

-- =============================================
-- Pattern 3: Centralized Logging and Re-throw
-- =============================================
-- Assumes ErrorLog table and LogError/LogCategorizedError exist (see previous files)

BEGIN TRY
    -- Simulate risky operation
    UPDATE Products SET Price = 'bad' WHERE ProductID = 1; -- will fail
END TRY
BEGIN CATCH
    DECLARE @Context NVARCHAR(500) = 'Operation: Update Product Price, ProductID: 1';
    -- Log categorized error
    EXEC LogCategorizedError @Category = 'Product Update', @AdditionalInfo = @Context;
    -- Re-throw for caller handling
    THROW;
END CATCH;

-- =============================================
-- Pattern 4: Graceful Degradation
-- =============================================
-- If a non-critical step fails, continue and record the failure

BEGIN TRY
    BEGIN TRANSACTION;

    -- Critical work
    UPDATE Products SET Price = Price * 1.02 WHERE Category = 'Electronics';

    -- Non-critical enrichment (best-effort)
    BEGIN TRY
        -- Example: update search index (simulated with a temp table insert)
        INSERT INTO #tmpIndexUpdate (ProductID) SELECT ProductID FROM Products WHERE Category = 'Electronics';
    END TRY
    BEGIN CATCH
        -- Log but don't abort main transaction
        EXEC LogError @AdditionalInfo = 'Index update failed during price refresh';
    END CATCH;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    EXEC LogError @AdditionalInfo = 'Critical failure during price refresh';
    THROW;
END CATCH;

-- =============================================
-- Pattern 5: User-Friendly Error Messages
-- =============================================
-- Do not expose raw system messages to end users; translate them

BEGIN TRY
    -- Simulate FK violation
    DELETE FROM Products WHERE ProductID = 1; -- may fail if Sales exist
END TRY
BEGIN CATCH
    DECLARE @ErrNum INT = ERROR_NUMBER();
    IF @ErrNum = 547 -- FK violation
        PRINT 'Cannot delete product: it has related sales records. Please archive the product instead.';
    ELSE
        PRINT 'An unexpected error occurred. Please contact support.';
    -- Log details for support
    EXEC LogError @AdditionalInfo = 'Delete Product failed for ProductID=1';
END CATCH;

-- =============================================
-- Pattern 6: Monitoring and Alerts (example)
-- =============================================
-- A scheduled job can run CheckCriticalErrors (created earlier) to alert on patterns

-- Example call
EXEC CheckCriticalErrors;

-- =============================================
-- Exercises (for learners):
-- 1) Implement a retry wrapper stored procedure that accepts a T-SQL batch and retries on deadlock
-- 2) Build a small table-driven alerting demo that emails (simulate) when ErrorLog shows > N critical errors
-- 3) Convert a multi-step ETL process into idempotent chunks and add logging

-- End of practical error handling patterns
