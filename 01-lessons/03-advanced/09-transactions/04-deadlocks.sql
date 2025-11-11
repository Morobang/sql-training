-- ========================================
-- Deadlocks
-- Detection, Prevention, Resolution
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Classic Deadlock Scenario
-- =============================================

-- SESSION 1 (Run this first):
BEGIN TRANSACTION;
    
    -- Lock Product 1
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    PRINT 'Session 1: Locked Product 1';
    
    WAITFOR DELAY '00:00:05';  -- Wait 5 seconds
    
    -- Try to lock Product 2 (deadlock!)
    UPDATE Products SET Price = 200 WHERE ProductID = 2;
    PRINT 'Session 1: Locked Product 2';
    
COMMIT;
PRINT 'Session 1: Committed';
GO

-- SESSION 2 (Run this 2 seconds after Session 1):
WAITFOR DELAY '00:00:02';

BEGIN TRANSACTION;
    
    -- Lock Product 2
    UPDATE Products SET Price = 200 WHERE ProductID = 2;
    PRINT 'Session 2: Locked Product 2';
    
    WAITFOR DELAY '00:00:05';
    
    -- Try to lock Product 1 (DEADLOCK!)
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    PRINT 'Session 2: Locked Product 1';
    
COMMIT;
PRINT 'Session 2: Committed';
GO

-- Result: One session becomes deadlock victim (rolled back)
-- Error 1205: Transaction was deadlocked

-- =============================================
-- Example 2: Deadlock with Multiple Tables
-- =============================================

-- SESSION 1:
BEGIN TRANSACTION;
    
    -- Lock Customers table
    UPDATE Customers SET TotalPurchases = 1000 WHERE CustomerID = 1;
    PRINT 'Session 1: Updated Customer';
    
    WAITFOR DELAY '00:00:05';
    
    -- Try to lock Sales table
    UPDATE Sales SET TotalAmount = 500 WHERE SaleID = 1;
    PRINT 'Session 1: Updated Sale';
    
COMMIT;
GO

-- SESSION 2:
WAITFOR DELAY '00:00:02';

BEGIN TRANSACTION;
    
    -- Lock Sales table
    UPDATE Sales SET TotalAmount = 500 WHERE SaleID = 1;
    PRINT 'Session 2: Updated Sale';
    
    WAITFOR DELAY '00:00:05';
    
    -- Try to lock Customers table (DEADLOCK!)
    UPDATE Customers SET TotalPurchases = 1000 WHERE CustomerID = 1;
    PRINT 'Session 2: Updated Customer';
    
COMMIT;
GO

-- =============================================
-- Example 3: Preventing Deadlocks - Consistent Order
-- =============================================

-- ✅ SOLUTION 1: Access tables in same order

-- Both sessions access tables in same order: Customers → Sales
-- SESSION 1:
BEGIN TRANSACTION;
    UPDATE Customers SET TotalPurchases = 1000 WHERE CustomerID = 1;
    WAITFOR DELAY '00:00:05';
    UPDATE Sales SET TotalAmount = 500 WHERE SaleID = 1;
COMMIT;
PRINT 'Session 1: Completed (no deadlock)';
GO

-- SESSION 2:
WAITFOR DELAY '00:00:02';
BEGIN TRANSACTION;
    UPDATE Customers SET TotalPurchases = 2000 WHERE CustomerID = 2;
    -- Waits for Session 1 to release Customers table
    UPDATE Sales SET TotalAmount = 600 WHERE SaleID = 2;
COMMIT;
PRINT 'Session 2: Completed (no deadlock)';
GO

-- =============================================
-- Example 4: Preventing Deadlocks - UPDLOCK Hint
-- =============================================

-- ❌ Without UPDLOCK (can deadlock):
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Shared lock
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 100 WHERE ProductID = 1;  -- Needs exclusive
COMMIT;
GO

-- SESSION 2:
WAITFOR DELAY '00:00:02';
BEGIN TRANSACTION;
    SELECT Price FROM Products WHERE ProductID = 1;  -- Shared lock
    UPDATE Products SET Price = 200 WHERE ProductID = 1;  -- DEADLOCK!
COMMIT;
GO

-- ✅ With UPDLOCK (no deadlock):
-- SESSION 1:
BEGIN TRANSACTION;
    SELECT Price FROM Products WITH (UPDLOCK) WHERE ProductID = 1;  -- Update lock
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 100 WHERE ProductID = 1;  -- Converts to exclusive
COMMIT;
PRINT 'Session 1: Completed';
GO

-- SESSION 2:
WAITFOR DELAY '00:00:02';
BEGIN TRANSACTION;
    SELECT Price FROM Products WITH (UPDLOCK) WHERE ProductID = 1;  -- BLOCKS (waits)
    UPDATE Products SET Price = 200 WHERE ProductID = 1;
COMMIT;
PRINT 'Session 2: Completed (no deadlock, just waited)';
GO

-- =============================================
-- Example 5: Preventing Deadlocks - Keep Transactions Short
-- =============================================

-- ❌ BAD: Long transaction (higher deadlock risk)
BEGIN TRANSACTION;
    SELECT * FROM Products;  -- Locks acquired
    
    -- Complex calculations (holds locks)
    DECLARE @Total DECIMAL(10,2);
    SELECT @Total = SUM(Price * StockQuantity) FROM Products;
    
    WAITFOR DELAY '00:00:30';  -- Simulate long operation
    
    UPDATE Products SET Price = Price * 1.1;
COMMIT;
GO

-- ✅ GOOD: Short transaction
-- Do calculations OUTSIDE transaction
DECLARE @Total DECIMAL(10,2);
SELECT @Total = SUM(Price * StockQuantity) FROM Products;

-- Complex processing here (no locks held)
WAITFOR DELAY '00:00:30';

-- Quick transaction only for updates
BEGIN TRANSACTION;
    UPDATE Products SET Price = Price * 1.1;
COMMIT;
GO

-- =============================================
-- Example 6: Deadlock with Retry Logic
-- =============================================

CREATE OR ALTER PROCEDURE usp_UpdateProductWithRetry
    @ProductID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RetryCount INT = 0;
    DECLARE @MaxRetries INT = 3;
    DECLARE @Success BIT = 0;
    
    WHILE @RetryCount < @MaxRetries AND @Success = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
                
                UPDATE Products 
                SET Price = @NewPrice,
                    LastModified = GETDATE()
                WHERE ProductID = @ProductID;
                
            COMMIT TRANSACTION;
            
            SET @Success = 1;
            PRINT 'Update successful';
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Check if deadlock error
            IF ERROR_NUMBER() = 1205  -- Deadlock
            BEGIN
                SET @RetryCount = @RetryCount + 1;
                PRINT 'Deadlock detected. Retry ' + CAST(@RetryCount AS VARCHAR(10));
                
                -- Wait before retry (exponential backoff)
                WAITFOR DELAY '00:00:01';
            END
            ELSE
            BEGIN
                -- Not a deadlock, throw error
                THROW;
            END
        END CATCH;
    END
    
    IF @Success = 0
        THROW 50001, 'Update failed after maximum retries', 1;
END;
GO

-- Test the procedure
EXEC usp_UpdateProductWithRetry @ProductID = 1, @NewPrice = 99.99;
GO

-- =============================================
-- Example 7: Monitoring Deadlocks with Extended Events
-- =============================================

-- Create Extended Event session to capture deadlocks
CREATE EVENT SESSION DeadlockMonitor ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report
ADD TARGET package0.event_file(SET filename=N'C:\Temp\Deadlocks.xel')
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS);
GO

-- Start the session
ALTER EVENT SESSION DeadlockMonitor ON SERVER STATE = START;
GO

-- Later, stop the session
-- ALTER EVENT SESSION DeadlockMonitor ON SERVER STATE = STOP;
-- DROP EVENT SESSION DeadlockMonitor ON SERVER;

-- =============================================
-- Example 8: Reading Deadlock Graph from System Health
-- =============================================

-- Query system health session for deadlocks
SELECT 
    CAST(target_data AS XML) AS DeadlockGraph
FROM sys.dm_xe_session_targets st
JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
WHERE s.name = 'system_health'
AND st.target_name = 'ring_buffer';
GO

-- Parse deadlock XML (simplified)
WITH DeadlockData AS (
    SELECT 
        CAST(target_data AS XML) AS DeadlockXML
    FROM sys.dm_xe_session_targets st
    JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
    WHERE s.name = 'system_health'
    AND st.target_name = 'ring_buffer'
)
SELECT 
    event_data.value('(@timestamp)[1]', 'datetime') AS DeadlockTime,
    event_data.value('(data[@name="xml_report"]/value)[1]', 'varchar(max)') AS DeadlockGraph
FROM DeadlockData
CROSS APPLY DeadlockXML.nodes('//RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEvent(event_data);
GO

-- =============================================
-- Example 9: Deadlock Priority
-- =============================================

-- Set deadlock priority (victim selection)
-- Range: -10 to 10 (lower = more likely to be victim)

-- SESSION 1 (Low priority - likely victim):
SET DEADLOCK_PRIORITY LOW;  -- -5
BEGIN TRANSACTION;
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 200 WHERE ProductID = 2;
COMMIT;
GO

-- SESSION 2 (High priority - less likely victim):
SET DEADLOCK_PRIORITY HIGH;  -- 5
WAITFOR DELAY '00:00:02';
BEGIN TRANSACTION;
    UPDATE Products SET Price = 200 WHERE ProductID = 2;
    WAITFOR DELAY '00:00:05';
    UPDATE Products SET Price = 100 WHERE ProductID = 1;
COMMIT;
GO

-- Result: Session 1 (low priority) chosen as victim

-- Reset priority
SET DEADLOCK_PRIORITY NORMAL;  -- 0
GO

-- =============================================
-- Example 10: Avoiding Deadlocks with ROWLOCK
-- =============================================

-- Use row-level locks to reduce contention
BEGIN TRANSACTION;
    UPDATE Products WITH (ROWLOCK) 
    SET Price = 100 
    WHERE ProductID = 1;
    -- Only locks row 1, not entire page or table
COMMIT;
GO

-- =============================================
-- Example 11: Deadlock from Index Scans
-- =============================================

-- Scenario: Index scans can cause lock escalation and deadlocks

-- Create non-selective index
CREATE NONCLUSTERED INDEX IX_Products_IsActive 
ON Products (IsActive);
GO

-- SESSION 1 (Scans many rows):
BEGIN TRANSACTION;
    UPDATE Products 
    SET Price = Price * 1.1 
    WHERE IsActive = 1;  -- Locks many rows
    WAITFOR DELAY '00:00:05';
COMMIT;
GO

-- SESSION 2 (Tries to lock same rows):
WAITFOR DELAY '00:00:02';
BEGIN TRANSACTION;
    UPDATE Products 
    SET Price = Price * 0.9 
    WHERE IsActive = 1;  -- DEADLOCK risk
COMMIT;
GO

DROP INDEX IX_Products_IsActive ON Products;
GO

-- ✅ Prevention: Use WHERE clause to minimize rows locked

-- =============================================
-- Example 12: Handling Deadlocks in Application
-- =============================================

CREATE OR ALTER PROCEDURE usp_ProcessSale
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;  -- Handle errors explicitly
    
    DECLARE @RetryCount INT = 0;
    
    RETRY:
    BEGIN TRY
        BEGIN TRANSACTION;
        
            -- Update stock (acquire lock in consistent order)
            UPDATE Products 
            SET StockQuantity = StockQuantity - @Quantity 
            WHERE ProductID = @ProductID;
            
            IF @@ROWCOUNT = 0
                THROW 50001, 'Product not found', 1;
            
            -- Check sufficient stock
            IF EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID AND StockQuantity < 0)
                THROW 50002, 'Insufficient stock', 1;
            
            -- Insert sale
            INSERT INTO Sales (CustomerID, ProductID, Quantity, SaleDate, TotalAmount, PaymentMethod)
            SELECT @CustomerID, @ProductID, @Quantity, GETDATE(), 
                   Price * @Quantity, 'Credit Card'
            FROM Products 
            WHERE ProductID = @ProductID;
            
            -- Update customer total
            UPDATE Customers 
            SET TotalPurchases = TotalPurchases + (SELECT TotalAmount FROM Sales WHERE SaleID = SCOPE_IDENTITY())
            WHERE CustomerID = @CustomerID;
            
        COMMIT TRANSACTION;
        
        PRINT 'Sale processed successfully';
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Deadlock retry logic
        IF ERROR_NUMBER() = 1205 AND @RetryCount < 3
        BEGIN
            SET @RetryCount = @RetryCount + 1;
            PRINT 'Deadlock detected. Retry attempt ' + CAST(@RetryCount AS VARCHAR(10));
            
            -- Random delay (1-3 seconds)
            DECLARE @Delay VARCHAR(8) = '00:00:0' + CAST((ABS(CHECKSUM(NEWID())) % 3) + 1 AS VARCHAR(1));
            WAITFOR DELAY @Delay;
            
            GOTO RETRY;
        END
        ELSE
        BEGIN
            -- Not a deadlock or max retries exceeded
            PRINT 'Error: ' + ERROR_MESSAGE();
            RETURN -1;
        END
    END CATCH;
END;
GO

-- Test the procedure
EXEC usp_ProcessSale @CustomerID = 1, @ProductID = 1, @Quantity = 2;
GO

-- =============================================
-- Example 13: Deadlock from Trigger
-- =============================================

-- Create trigger that can cause deadlocks
CREATE OR ALTER TRIGGER trg_Products_Update
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update related sales (can cause deadlock if Sales is locked)
    UPDATE Sales
    SET TotalAmount = i.Price * Sales.Quantity
    FROM inserted i
    WHERE Sales.ProductID = i.ProductID;
END;
GO

-- ✅ Prevention: Keep triggers simple, avoid cross-table updates

-- Better approach: Handle in application logic
DROP TRIGGER trg_Products_Update;
GO

-- =============================================
-- Example 14: Trace Flag 1222 (Deadlock Information)
-- =============================================

-- Enable deadlock trace flag (writes to error log)
DBCC TRACEON (1222, -1);  -- -1 = global
GO

-- Generate deadlock (same as Example 1)
-- Check error log for detailed deadlock graph
EXEC sp_readerrorlog;
GO

-- Disable trace flag
DBCC TRACEOFF (1222, -1);
GO

-- =============================================
-- Example 15: Best Practices Summary
-- =============================================

-- ✅ PRACTICE 1: Access objects in same order
CREATE OR ALTER PROCEDURE usp_UpdateSaleAndCustomer
    @SaleID INT,
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
        -- Always update in same order: Customers → Sales
        UPDATE Customers SET TotalPurchases = TotalPurchases + 100 WHERE CustomerID = @CustomerID;
        UPDATE Sales SET TotalAmount = TotalAmount + 100 WHERE SaleID = @SaleID;
    COMMIT;
END;
GO

-- ✅ PRACTICE 2: Keep transactions short
CREATE OR ALTER PROCEDURE usp_QuickUpdate
AS
BEGIN
    -- Calculate outside transaction
    DECLARE @AvgPrice DECIMAL(10,2);
    SELECT @AvgPrice = AVG(Price) FROM Products;
    
    -- Short transaction
    BEGIN TRANSACTION;
        UPDATE Products SET Price = @AvgPrice WHERE StockQuantity = 0;
    COMMIT;
END;
GO

-- ✅ PRACTICE 3: Use appropriate isolation level
CREATE OR ALTER PROCEDURE usp_GetSalesReport
AS
BEGIN
    -- Read-only report, use SNAPSHOT to avoid blocking
    SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
    
    SELECT 
        YEAR(SaleDate) AS SaleYear,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate);
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END;
GO

-- ✅ PRACTICE 4: Use UPDLOCK for read-then-update
CREATE OR ALTER PROCEDURE usp_UpdateWithLock
    @ProductID INT
AS
BEGIN
    BEGIN TRANSACTION;
        DECLARE @Price DECIMAL(10,2);
        
        -- Acquire update lock immediately
        SELECT @Price = Price 
        FROM Products WITH (UPDLOCK, ROWLOCK) 
        WHERE ProductID = @ProductID;
        
        -- No other session can get update lock (no deadlock)
        UPDATE Products 
        SET Price = @Price * 1.1 
        WHERE ProductID = @ProductID;
        
    COMMIT;
END;
GO

-- ✅ PRACTICE 5: Implement retry logic
-- See Example 6: usp_UpdateProductWithRetry

-- =============================================
-- Cleanup
-- =============================================

DROP PROCEDURE IF EXISTS usp_UpdateProductWithRetry;
DROP PROCEDURE IF EXISTS usp_ProcessSale;
DROP PROCEDURE IF EXISTS usp_UpdateSaleAndCustomer;
DROP PROCEDURE IF EXISTS usp_QuickUpdate;
DROP PROCEDURE IF EXISTS usp_GetSalesReport;
DROP PROCEDURE IF EXISTS usp_UpdateWithLock;
GO

-- 💡 Key Takeaways:
--
-- WHAT IS A DEADLOCK?
-- - Circular wait: Session A waits for Session B's lock, Session B waits for Session A's lock
-- - SQL Server detects automatically and rolls back one session (victim)
-- - Error 1205: "Transaction was deadlocked"
--
-- COMMON CAUSES:
-- - Accessing tables in different order
-- - Read-then-update pattern (S lock → X lock conversion)
-- - Long transactions holding locks
-- - Index scans locking many rows
-- - Triggers updating related tables
-- - Lock escalation (row → page → table)
--
-- PREVENTION STRATEGIES:
-- 1. Access objects in same order (Customers → Sales, always)
-- 2. Keep transactions SHORT (minimize lock duration)
-- 3. Use UPDLOCK hint for read-then-update patterns
-- 4. Use appropriate isolation level (SNAPSHOT for reports)
-- 5. Use row-level locks (ROWLOCK hint)
-- 6. Avoid triggers that update multiple tables
-- 7. Create proper indexes (reduce scan locks)
-- 8. Access tables in consistent order across all procedures
--
-- DETECTION & MONITORING:
-- - Extended Events (xml_deadlock_report)
-- - System Health session (ring buffer)
-- - Trace Flag 1222 (error log)
-- - sp_readerrorlog (view error log)
-- - Deadlock graph in SSMS (XML)
--
-- RESOLUTION:
-- 1. Implement retry logic with exponential backoff
-- 2. Set DEADLOCK_PRIORITY (victim selection)
-- 3. Refactor code to access objects in same order
-- 4. Use SNAPSHOT isolation for read-only queries
-- 5. Keep transactions short (no I/O inside transaction)
--
-- RETRY PATTERN:
-- - Catch error 1205 (deadlock)
-- - Retry 3-5 times with random delay
-- - Exponential or random backoff (1-3 seconds)
-- - Log and alert if max retries exceeded
--
-- DEADLOCK PRIORITY:
-- - Range: -10 (most likely victim) to 10 (least likely)
-- - LOW = -5, NORMAL = 0, HIGH = 5
-- - Use for batch jobs (set LOW) vs. user transactions (NORMAL/HIGH)
--
-- BEST PRACTICES:
-- - Access tables in alphabetical order (Customers → Products → Sales)
-- - Use UPDLOCK for read-then-update (prevents conversion deadlock)
-- - Keep transactions under 1 second
-- - Use SNAPSHOT isolation for long reports
-- - Implement retry logic in application
-- - Monitor deadlocks with Extended Events
-- - Create proper indexes (reduce lock escalation)
-- - Avoid nested triggers and cross-table triggers
-- - Test under high concurrency before production
