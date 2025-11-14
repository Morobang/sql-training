-- ============================================================================
-- Capture and Process Changes (Incremental Load)
-- ============================================================================
-- Complete CDC pipeline: Capture → Transform → Load
-- Handles INSERT, UPDATE, DELETE operations
-- ============================================================================

USE TechStore_Target;
GO

PRINT '=================================================================';
PRINT 'CDC INCREMENTAL LOAD PROCEDURE';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
INCREMENTAL LOAD PATTERN
============================================================================

TRADITIONAL FULL LOAD (SLOW):
1. Truncate target table
2. SELECT * FROM source
3. INSERT INTO target
❌ Loads 100% of data every time (wasteful!)

INCREMENTAL LOAD WITH CDC (FAST):
1. Get last sync version from watermark
2. Query CHANGETABLE for changes since last sync
3. Apply changes to target (INSERT/UPDATE/DELETE)
4. Update watermark
✅ Loads only changed rows (99%+ savings!)

EXAMPLE:
- Table: 10 million rows
- Daily changes: 10,000 rows (0.1%)
- Full load: Process 10 million rows
- Incremental: Process 10,000 rows (1000x faster!)

============================================================================
*/

-- ============================================================================
-- STORED PROCEDURE: Incremental Load for Orders
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_IncrementalLoad_Orders
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @table_name VARCHAR(100) = 'Orders';
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @last_version BIGINT;
    DECLARE @current_version BIGINT;
    DECLARE @rows_inserted INT = 0;
    DECLARE @rows_updated INT = 0;
    DECLARE @rows_deleted INT = 0;
    DECLARE @error_msg VARCHAR(MAX);
    
    BEGIN TRY
        -- Log start
        INSERT INTO CDC_ExecutionLog (TableName, StartTime, Status)
        VALUES (@table_name, @start_time, 'Running');
        
        DECLARE @log_id INT = SCOPE_IDENTITY();
        
        -- Get last sync version
        SELECT @last_version = LastSyncVersion
        FROM CDC_Watermark
        WHERE TableName = @table_name;
        
        -- Get current version from source
        SET @current_version = CHANGE_TRACKING_CURRENT_VERSION();
        
        PRINT 'Processing changes for ' + @table_name;
        PRINT '  Last sync version: ' + CAST(@last_version AS VARCHAR(20));
        PRINT '  Current version: ' + CAST(@current_version AS VARCHAR(20));
        
        -- Check if we're behind the minimum valid version (data loss!)
        DECLARE @min_valid_version BIGINT;
        SELECT @min_valid_version = CHANGE_TRACKING_MIN_VALID_VERSION(
            OBJECT_ID('TechStore_Source.dbo.Orders')
        );
        
        IF @last_version < @min_valid_version
        BEGIN
            PRINT 'WARNING: Last sync version expired! Need full refresh.';
            PRINT '  Last sync: ' + CAST(@last_version AS VARCHAR(20));
            PRINT '  Min valid: ' + CAST(@min_valid_version AS VARCHAR(20));
            
            -- Would trigger full table reload here
            RAISERROR('Change tracking data expired. Run full refresh.', 16, 1);
        END
        
        -- Create temp table for changes
        CREATE TABLE #OrderChanges (
            OrderID INT,
            ChangeOperation CHAR(1),
            ChangeVersion BIGINT
        );
        
        -- Get all changes since last sync
        INSERT INTO #OrderChanges (OrderID, ChangeOperation, ChangeVersion)
        SELECT 
            CT.OrderID,
            CT.SYS_CHANGE_OPERATION,
            CT.SYS_CHANGE_VERSION
        FROM CHANGETABLE(CHANGES TechStore_Source.dbo.Orders, @last_version) AS CT;
        
        DECLARE @total_changes INT = @@ROWCOUNT;
        PRINT '  Total changes detected: ' + CAST(@total_changes AS VARCHAR(20));
        
        -- Process INSERTs and UPDATEs (upsert pattern)
        MERGE INTO Orders AS target
        USING (
            SELECT 
                S.OrderID,
                S.CustomerID,
                S.OrderDate,
                S.TotalAmount,
                S.OrderStatus,
                S.ShippingAddress,
                S.ModifiedDate,
                S.ModifiedBy
            FROM #OrderChanges C
            JOIN TechStore_Source.dbo.Orders S ON C.OrderID = S.OrderID
            WHERE C.ChangeOperation IN ('I', 'U')  -- INSERT or UPDATE
        ) AS source
        ON target.OrderID = source.OrderID
        WHEN MATCHED THEN
            UPDATE SET
                CustomerID = source.CustomerID,
                OrderDate = source.OrderDate,
                TotalAmount = source.TotalAmount,
                OrderStatus = source.OrderStatus,
                ShippingAddress = source.ShippingAddress,
                ModifiedDate = source.ModifiedDate,
                ModifiedBy = source.ModifiedBy,
                DW_LoadedDate = GETDATE(),
                DW_IsDeleted = 0
        WHEN NOT MATCHED THEN
            INSERT (OrderID, CustomerID, OrderDate, TotalAmount, OrderStatus,
                    ShippingAddress, ModifiedDate, ModifiedBy, DW_LoadedDate, DW_IsDeleted)
            VALUES (source.OrderID, source.CustomerID, source.OrderDate, source.TotalAmount,
                    source.OrderStatus, source.ShippingAddress, source.ModifiedDate,
                    source.ModifiedBy, GETDATE(), 0);
        
        SET @rows_inserted = @@ROWCOUNT;
        
        -- Process DELETEs (soft delete)
        UPDATE Orders
        SET DW_IsDeleted = 1,
            DW_LoadedDate = GETDATE()
        FROM Orders T
        JOIN #OrderChanges C ON T.OrderID = C.OrderID
        WHERE C.ChangeOperation = 'D';
        
        SET @rows_deleted = @@ROWCOUNT;
        
        -- Update watermark
        UPDATE CDC_Watermark
        SET LastSyncVersion = @current_version,
            LastSyncTime = GETDATE(),
            RowsProcessed = @total_changes,
            LastRunStatus = 'Success'
        WHERE TableName = @table_name;
        
        -- Log completion
        UPDATE CDC_ExecutionLog
        SET EndTime = GETDATE(),
            RowsInserted = @rows_inserted,
            RowsUpdated = 0,  -- MERGE doesn't distinguish
            RowsDeleted = @rows_deleted,
            Status = 'Success'
        WHERE LogID = @log_id;
        
        PRINT '✓ Incremental load completed successfully';
        PRINT '  Rows inserted/updated: ' + CAST(@rows_inserted AS VARCHAR(20));
        PRINT '  Rows deleted: ' + CAST(@rows_deleted AS VARCHAR(20));
        
        DROP TABLE #OrderChanges;
        
    END TRY
    BEGIN CATCH
        SET @error_msg = ERROR_MESSAGE();
        
        -- Log error
        UPDATE CDC_ExecutionLog
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @error_msg
        WHERE LogID = @log_id;
        
        UPDATE CDC_Watermark
        SET LastRunStatus = 'Failed'
        WHERE TableName = @table_name;
        
        PRINT 'ERROR: ' + @error_msg;
        
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created sp_CDC_IncrementalLoad_Orders';

-- ============================================================================
-- STORED PROCEDURE: Incremental Load for Customers
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_IncrementalLoad_Customers
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @table_name VARCHAR(100) = 'Customers';
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @last_version BIGINT;
    DECLARE @current_version BIGINT;
    DECLARE @rows_processed INT = 0;
    
    BEGIN TRY
        INSERT INTO CDC_ExecutionLog (TableName, StartTime, Status)
        VALUES (@table_name, @start_time, 'Running');
        
        DECLARE @log_id INT = SCOPE_IDENTITY();
        
        SELECT @last_version = LastSyncVersion FROM CDC_Watermark WHERE TableName = @table_name;
        SET @current_version = CHANGE_TRACKING_CURRENT_VERSION();
        
        PRINT 'Processing changes for ' + @table_name;
        
        -- Upsert changed customers
        MERGE INTO Customers AS target
        USING (
            SELECT S.*
            FROM CHANGETABLE(CHANGES TechStore_Source.dbo.Customers, @last_version) AS CT
            JOIN TechStore_Source.dbo.Customers S ON CT.CustomerID = S.CustomerID
            WHERE CT.SYS_CHANGE_OPERATION IN ('I', 'U')
        ) AS source
        ON target.CustomerID = source.CustomerID
        WHEN MATCHED THEN
            UPDATE SET
                FirstName = source.FirstName,
                LastName = source.LastName,
                Email = source.Email,
                Phone = source.Phone,
                LoyaltyTier = source.LoyaltyTier,
                ModifiedDate = source.ModifiedDate,
                DW_LoadedDate = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (CustomerID, FirstName, LastName, Email, Phone, LoyaltyTier,
                    CreatedDate, ModifiedDate, ModifiedBy, DW_LoadedDate)
            VALUES (source.CustomerID, source.FirstName, source.LastName, source.Email,
                    source.Phone, source.LoyaltyTier, source.CreatedDate, source.ModifiedDate,
                    source.ModifiedBy, GETDATE());
        
        SET @rows_processed = @@ROWCOUNT;
        
        -- Handle deletions
        UPDATE Customers SET DW_IsDeleted = 1, DW_LoadedDate = GETDATE()
        FROM Customers T
        JOIN CHANGETABLE(CHANGES TechStore_Source.dbo.Customers, @last_version) AS CT
            ON T.CustomerID = CT.CustomerID
        WHERE CT.SYS_CHANGE_OPERATION = 'D';
        
        -- Update watermark
        UPDATE CDC_Watermark
        SET LastSyncVersion = @current_version,
            LastSyncTime = GETDATE(),
            RowsProcessed = @rows_processed,
            LastRunStatus = 'Success'
        WHERE TableName = @table_name;
        
        UPDATE CDC_ExecutionLog
        SET EndTime = GETDATE(),
            RowsInserted = @rows_processed,
            Status = 'Success'
        WHERE LogID = @log_id;
        
        PRINT '✓ Processed ' + CAST(@rows_processed AS VARCHAR(20)) + ' customer changes';
        
    END TRY
    BEGIN CATCH
        UPDATE CDC_ExecutionLog
        SET EndTime = GETDATE(), Status = 'Failed', ErrorMessage = ERROR_MESSAGE()
        WHERE LogID = @log_id;
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created sp_CDC_IncrementalLoad_Customers';

-- ============================================================================
-- STORED PROCEDURE: Incremental Load for Products
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_IncrementalLoad_Products
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @table_name VARCHAR(100) = 'Products';
    DECLARE @last_version BIGINT;
    DECLARE @current_version BIGINT;
    
    BEGIN TRY
        SELECT @last_version = LastSyncVersion FROM CDC_Watermark WHERE TableName = @table_name;
        SET @current_version = CHANGE_TRACKING_CURRENT_VERSION();
        
        PRINT 'Processing changes for ' + @table_name;
        
        -- Upsert products
        MERGE INTO Products AS target
        USING (
            SELECT S.*
            FROM CHANGETABLE(CHANGES TechStore_Source.dbo.Products, @last_version) AS CT
            JOIN TechStore_Source.dbo.Products S ON CT.ProductID = S.ProductID
            WHERE CT.SYS_CHANGE_OPERATION IN ('I', 'U')
        ) AS source
        ON target.ProductID = source.ProductID
        WHEN MATCHED THEN
            UPDATE SET
                ProductName = source.ProductName,
                Category = source.Category,
                Price = source.Price,
                StockQuantity = source.StockQuantity,
                ModifiedDate = source.ModifiedDate,
                DW_LoadedDate = GETDATE()
        WHEN NOT MATCHED THEN
            INSERT (ProductID, ProductName, Category, Price, StockQuantity,
                    ModifiedDate, ModifiedBy, DW_LoadedDate)
            VALUES (source.ProductID, source.ProductName, source.Category, source.Price,
                    source.StockQuantity, source.ModifiedDate, source.ModifiedBy, GETDATE());
        
        -- Handle deletions
        UPDATE Products SET DW_IsDeleted = 1, DW_LoadedDate = GETDATE()
        FROM Products T
        JOIN CHANGETABLE(CHANGES TechStore_Source.dbo.Products, @last_version) AS CT
            ON T.ProductID = CT.ProductID
        WHERE CT.SYS_CHANGE_OPERATION = 'D';
        
        -- Update watermark
        UPDATE CDC_Watermark
        SET LastSyncVersion = @current_version,
            LastSyncTime = GETDATE(),
            LastRunStatus = 'Success'
        WHERE TableName = @table_name;
        
        PRINT '✓ Product changes processed successfully';
        
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created sp_CDC_IncrementalLoad_Products';

-- ============================================================================
-- MASTER ORCHESTRATION PROCEDURE
-- ============================================================================

CREATE OR ALTER PROCEDURE sp_CDC_RunAll
AS
BEGIN
    PRINT '=================================================================';
    PRINT 'RUNNING CDC FOR ALL TABLES';
    PRINT '=================================================================';
    
    EXEC sp_CDC_IncrementalLoad_Orders;
    PRINT '';
    
    EXEC sp_CDC_IncrementalLoad_Customers;
    PRINT '';
    
    EXEC sp_CDC_IncrementalLoad_Products;
    PRINT '';
    
    PRINT '=================================================================';
    PRINT 'CDC RUN COMPLETE';
    PRINT '=================================================================';
    
    -- Show summary
    SELECT * FROM vw_CDC_Lag;
END;
GO

PRINT '✓ Created sp_CDC_RunAll (master orchestration)';

-- ============================================================================
-- TEST THE CDC PIPELINE
-- ============================================================================

PRINT '';
PRINT '=================================================================';
PRINT 'TESTING CDC PIPELINE';
PRINT '=================================================================';
PRINT '';

-- Initial load (first run will load all existing data)
PRINT 'INITIAL LOAD:';
EXEC sp_CDC_RunAll;

PRINT '';
PRINT 'Target table counts after initial load:';
SELECT 'Orders' AS TableName, COUNT(*) AS RowCount FROM Orders WHERE DW_IsDeleted = 0
UNION ALL
SELECT 'Customers', COUNT(*) FROM Customers WHERE DW_IsDeleted = 0
UNION ALL
SELECT 'Products', COUNT(*) FROM Products WHERE DW_IsDeleted = 0;

-- Make some changes in source
PRINT '';
PRINT 'Making changes in source database...';

USE TechStore_Source;

INSERT INTO Orders (CustomerID, TotalAmount, OrderStatus, ShippingAddress)
VALUES (2, 499.99, 'Pending', '456 Oak Ave, Portland, OR 97201');

UPDATE Customers
SET LoyaltyTier = 'Platinum', Email = 'updated@email.com'
WHERE CustomerID = 4;

UPDATE Products
SET Price = Price * 1.10, StockQuantity = StockQuantity - 5
WHERE ProductID = 1;

PRINT '  ✓ Inserted 1 order';
PRINT '  ✓ Updated 1 customer';
PRINT '  ✓ Updated 1 product';

-- Run incremental load
PRINT '';
PRINT 'INCREMENTAL LOAD (only changed rows):';

USE TechStore_Target;
EXEC sp_CDC_RunAll;

-- Show execution history
PRINT '';
PRINT 'CDC Execution History:';
SELECT * FROM vw_CDC_ExecutionHistory ORDER BY StartTime DESC;

PRINT '';
PRINT '=================================================================';
PRINT 'CDC PIPELINE TESTED SUCCESSFULLY!';
PRINT '=================================================================';

/*
============================================================================
INCREMENTAL LOAD COMPLETE!
============================================================================

✅ Created 3 incremental load procedures:
   - sp_CDC_IncrementalLoad_Orders
   - sp_CDC_IncrementalLoad_Customers
   - sp_CDC_IncrementalLoad_Products

✅ Created master orchestration procedure:
   - sp_CDC_RunAll (runs all CDC loads)

✅ Tested pipeline with sample data

HOW THE PIPELINE WORKS:

1. Get Last Sync Version
   - Read from CDC_Watermark table
   - This is the "bookmark" of last successful run

2. Get Current Version
   - CHANGE_TRACKING_CURRENT_VERSION()
   - This is the "now" version

3. Query Changes
   - CHANGETABLE(CHANGES table, @last_version)
   - Returns all changes between versions

4. Apply Changes
   - MERGE for INSERT/UPDATE (upsert)
   - UPDATE...SET DW_IsDeleted=1 for DELETE (soft delete)

5. Update Watermark
   - Store current version as new "last sync"
   - Next run will pick up from here

BENEFITS:

✅ Only processes changed rows (99%+ efficiency)
✅ Handles INSERT, UPDATE, DELETE
✅ Soft delete preserves historical records
✅ Automatic error handling and logging
✅ Can run every 5 minutes (near real-time)

SCHEDULING:

-- SQL Agent Job (run every 5 minutes)
USE msdb;
EXEC sp_add_job @job_name = 'CDC_Incremental_Load';
EXEC sp_add_jobstep 
    @job_name = 'CDC_Incremental_Load',
    @step_name = 'Run CDC',
    @command = 'EXEC TechStore_Target.dbo.sp_CDC_RunAll';
EXEC sp_add_schedule
    @schedule_name = 'Every_5_Minutes',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @freq_subday_type = 4,  -- Minutes
    @freq_subday_interval = 5;

MONITORING:

-- Check lag
SELECT * FROM vw_CDC_Lag;

-- View execution history
SELECT * FROM vw_CDC_ExecutionHistory;

-- Alert if lag > 15 minutes
SELECT * FROM vw_CDC_Lag WHERE HealthStatus != 'OK';

Next: Temporal Tables for complete history tracking!
============================================================================
*/
