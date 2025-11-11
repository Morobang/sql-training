-- ========================================
-- Query Hints and Table Hints
-- OPTION clauses, JOIN hints, Table hints
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: OPTION (RECOMPILE)
-- =============================================

-- Problem: Query plan cached from first execution may not be optimal for all parameters
CREATE OR ALTER PROCEDURE usp_GetProductsByPrice
    @MinPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Without RECOMPILE (plan cached and reused)
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Price >= @MinPrice;
END;
GO

-- First execution (high price, few rows)
EXEC usp_GetProductsByPrice @MinPrice = 1000;  -- Likely Index Seek
GO

-- Second execution (low price, many rows)
EXEC usp_GetProductsByPrice @MinPrice = 10;  -- May still use Seek (inefficient!)
GO

-- ✅ Solution: OPTION (RECOMPILE)
CREATE OR ALTER PROCEDURE usp_GetProductsByPrice_Recompile
    @MinPrice DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Price >= @MinPrice
    OPTION (RECOMPILE);  -- Recompile every time
END;
GO

-- Each execution gets optimal plan for its parameters
EXEC usp_GetProductsByPrice_Recompile @MinPrice = 1000;  -- Index Seek
EXEC usp_GetProductsByPrice_Recompile @MinPrice = 10;    -- Index Scan (better for many rows)
GO

-- =============================================
-- Example 2: OPTION (OPTIMIZE FOR)
-- =============================================

-- Scenario: 90% of queries use a specific value
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Optimize plan for 'Electronics' (most common value)
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE Category = @Category
    OPTION (OPTIMIZE FOR (@Category = 'Electronics'));
END;
GO

-- Plan optimized for 'Electronics' even if first call is different
EXEC usp_GetProductsByCategory @Category = 'Books';         -- Uses 'Electronics' plan
EXEC usp_GetProductsByCategory @Category = 'Electronics';   -- Optimal
GO

-- =============================================
-- Example 3: OPTION (OPTIMIZE FOR UNKNOWN)
-- =============================================

-- Use average selectivity (density vector) instead of sniffed parameter
CREATE OR ALTER PROCEDURE usp_GetSalesByCustomer
    @CustomerID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Uses average selectivity (good for varying distributions)
    SELECT SaleID, SaleDate, TotalAmount
    FROM Sales
    WHERE CustomerID = @CustomerID
    OPTION (OPTIMIZE FOR (@CustomerID UNKNOWN));
END;
GO

-- All executions use same "average" plan
EXEC usp_GetSalesByCustomer @CustomerID = 1;    -- Customer with 1000 sales
EXEC usp_GetSalesByCustomer @CustomerID = 100;  -- Customer with 1 sale
GO

-- =============================================
-- Example 4: OPTION (MAXDOP)
-- =============================================

-- Limit parallelism to reduce CXPACKET waits
SELECT 
    Category,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCnt
FROM Products
GROUP BY Category
OPTION (MAXDOP 1);  -- No parallelism
GO

-- Use 4 cores only
SELECT 
    YEAR(SaleDate) AS SaleYear,
    SUM(TotalAmount) AS TotalRevenue
FROM Sales
GROUP BY YEAR(SaleDate)
OPTION (MAXDOP 4);
GO

-- Inherit server default (use server-configured MAXDOP)
SELECT * FROM Products
OPTION (MAXDOP 0);  -- 0 = use server default
GO

-- =============================================
-- Example 5: OPTION (FORCE ORDER)
-- =============================================

-- Force join order as written (left to right)
SELECT 
    c.CustomerName,
    s.SaleID,
    p.ProductName
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
OPTION (FORCE ORDER);  -- Join in this exact order
GO

-- Without FORCE ORDER, optimizer may reorder:
-- Products → Sales → Customers (if optimizer thinks it's better)

-- =============================================
-- Example 6: JOIN Hints (LOOP, HASH, MERGE)
-- =============================================

-- Force nested loops join (good for small outer, indexed inner)
SELECT 
    c.CustomerName,
    s.TotalAmount
FROM Customers c
INNER LOOP JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE c.CustomerID = 1;
-- Nested loops: For each customer row, seek in Sales
GO

-- Force hash join (good for large unindexed sets)
SELECT 
    c.CustomerName,
    s.TotalAmount
FROM Customers c
INNER HASH JOIN Sales s ON c.CustomerID = s.CustomerID;
-- Hash join: Build hash table from Customers, probe with Sales
GO

-- Force merge join (good for both sorted)
SELECT 
    c.CustomerID,
    s.SaleID
FROM Customers c
INNER MERGE JOIN Sales s ON c.CustomerID = s.CustomerID
ORDER BY c.CustomerID;
-- Merge join: Both sorted by join key, merge in order
GO

-- =============================================
-- Example 7: NOLOCK Hint (READ UNCOMMITTED)
-- =============================================

-- Read uncommitted data (dirty reads allowed)
SELECT 
    Category,
    COUNT(*) AS ProductCnt
FROM Products WITH (NOLOCK)
GROUP BY Category;
-- ⚠️ May read uncommitted or phantom rows!
GO

-- Equivalent to:
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT Category, COUNT(*) AS ProductCnt FROM Products GROUP BY Category;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- Use case: Reporting queries where dirty reads acceptable
SELECT 
    YEAR(SaleDate) AS SaleYear,
    SUM(TotalAmount) AS Revenue
FROM Sales WITH (NOLOCK)
GROUP BY YEAR(SaleDate);
GO

-- =============================================
-- Example 8: UPDLOCK Hint (Prevent Deadlocks)
-- =============================================

-- Read-then-update pattern (prevent deadlock)
BEGIN TRANSACTION;
    
    DECLARE @CurrentPrice DECIMAL(10,2);
    
    -- Acquire update lock immediately (not shared lock)
    SELECT @CurrentPrice = Price
    FROM Products WITH (UPDLOCK, ROWLOCK)
    WHERE ProductID = 1;
    
    -- No other session can get update lock (prevents deadlock)
    UPDATE Products 
    SET Price = @CurrentPrice * 1.1 
    WHERE ProductID = 1;
    
COMMIT;
PRINT 'Update successful (no deadlock risk)';
GO

-- =============================================
-- Example 9: ROWLOCK / PAGLOCK / TABLOCK
-- =============================================

-- Force row-level locking
UPDATE Products WITH (ROWLOCK)
SET Price = Price * 1.01
WHERE Category = 'Electronics';
-- Locks individual rows (may escalate if many rows)
GO

-- Force page-level locking
UPDATE Products WITH (PAGLOCK)
SET Price = Price * 1.01
WHERE ProductID = 1;
-- Locks 8KB page containing row
GO

-- Force table-level lock
SELECT * FROM Products WITH (TABLOCK);
-- Shared lock on entire table (blocks updates)
GO

-- =============================================
-- Example 10: INDEX Hint (Force Specific Index)
-- =============================================

-- Create test indexes
CREATE NONCLUSTERED INDEX IX_Products_Category ON Products (Category);
CREATE NONCLUSTERED INDEX IX_Products_Price ON Products (Price);
GO

-- Force use of specific index
SELECT ProductID, ProductName, Price
FROM Products WITH (INDEX(IX_Products_Category))
WHERE Category = 'Electronics' AND Price > 100;
-- Uses IX_Products_Category even if optimizer prefers IX_Products_Price
GO

-- Force use of PRIMARY KEY (clustered index)
SELECT ProductID, ProductName
FROM Products WITH (INDEX(PK_Products))  -- Assuming PK is clustered
WHERE ProductID > 100;
GO

-- Cleanup
DROP INDEX IX_Products_Category ON Products;
DROP INDEX IX_Products_Price ON Products;
GO

-- =============================================
-- Example 11: FORCESEEK Hint
-- =============================================

-- Force index seek (prevent index scan)
SELECT ProductID, ProductName, Price
FROM Products WITH (FORCESEEK)
WHERE Price > 100;
-- Must use seek operation (errors if not possible)
GO

-- ⚠️ Will fail if seek not possible:
-- SELECT * FROM Products WITH (FORCESEEK);
-- Error: Cannot use FORCESEEK (no WHERE clause)

-- =============================================
-- Example 12: READPAST Hint (Skip Locked Rows)
-- =============================================

-- Skip locked rows (queue processing)
SELECT TOP 10 *
FROM Sales WITH (READPAST, UPDLOCK, ROWLOCK)
WHERE PaymentMethod = 'Pending'
ORDER BY SaleDate;
-- Returns only unlocked rows (no blocking)
GO

-- Use case: Queue processing with multiple workers
BEGIN TRANSACTION;
    
    DECLARE @SaleID INT;
    
    -- Get next unlocked item
    SELECT TOP 1 @SaleID = SaleID
    FROM Sales WITH (READPAST, UPDLOCK, ROWLOCK)
    WHERE PaymentMethod = 'Pending'
    ORDER BY SaleDate;
    
    -- Process this item (other workers skip it)
    IF @SaleID IS NOT NULL
        UPDATE Sales SET PaymentMethod = 'Processing' WHERE SaleID = @SaleID;
        
COMMIT;
GO

-- =============================================
-- Example 13: HOLDLOCK Hint (REPEATABLE READ)
-- =============================================

-- Hold shared locks until transaction ends
BEGIN TRANSACTION;
    
    -- Shared lock held until COMMIT
    SELECT Price FROM Products WITH (HOLDLOCK) WHERE ProductID = 1;
    
    WAITFOR DELAY '00:00:05';
    
    -- Same price guaranteed (no non-repeatable read)
    SELECT Price FROM Products WHERE ProductID = 1;
    
COMMIT;
-- Equivalent to SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
GO

-- =============================================
-- Example 14: READCOMMITTEDLOCK Hint
-- =============================================

-- Use locking-based READ COMMITTED (not snapshot)
SELECT * FROM Products WITH (READCOMMITTEDLOCK);
-- Even if READ_COMMITTED_SNAPSHOT is enabled at database level
GO

-- =============================================
-- Example 15: Combining Multiple Hints
-- =============================================

-- Multiple table hints
SELECT * FROM Products 
WITH (NOLOCK, INDEX(IX_Products_Category))
WHERE Category = 'Electronics';
GO

-- Multiple query hints
SELECT 
    c.CustomerName,
    COUNT(s.SaleID) AS SaleCnt
FROM Customers c
INNER JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName
OPTION (RECOMPILE, MAXDOP 1);
-- Both RECOMPILE and MAXDOP applied
GO

-- Complex hint combination
SELECT 
    p.ProductName,
    s.TotalAmount
FROM Products p WITH (UPDLOCK, ROWLOCK, INDEX(IX_Products_Category))
INNER HASH JOIN Sales s WITH (NOLOCK) ON p.ProductID = s.ProductID
WHERE p.Category = 'Electronics'
OPTION (OPTIMIZE FOR (@Category = 'Electronics'), MAXDOP 4);
GO

-- =============================================
-- Example 16: FAST Hint (Return First N Rows Quickly)
-- =============================================

-- Optimize for returning first 10 rows quickly
SELECT TOP 100 
    ProductName,
    Price
FROM Products
WHERE Category = 'Electronics'
ORDER BY Price DESC
OPTION (FAST 10);  -- Optimize plan for first 10 rows
GO

-- =============================================
-- Example 17: QUERYTRACEON Hint (Enable Trace Flag)
-- =============================================

-- Enable trace flag 4199 (query optimizer fixes) for this query only
SELECT 
    Category,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY Category
OPTION (QUERYTRACEON 4199);
GO

-- Trace flag 2453 (use table variable deferred compilation)
DECLARE @ProductIDs TABLE (ProductID INT);
INSERT INTO @ProductIDs VALUES (1), (2), (3);

SELECT p.* 
FROM Products p
INNER JOIN @ProductIDs pid ON p.ProductID = pid.ProductID
OPTION (QUERYTRACEON 2453);
GO

-- =============================================
-- Example 18: USE PLAN Hint (Force Specific Plan XML)
-- =============================================

-- Get plan XML (copy from actual execution plan in SSMS)
-- Then force that exact plan:

/*
SELECT * FROM Products
WHERE ProductID = 1
OPTION (USE PLAN N'<ShowPlanXML>...</ShowPlanXML>');
*/

-- ⚠️ Brittle and hard to maintain - use Query Store plan forcing instead

-- =============================================
-- Example 19: Real-World Scenarios
-- =============================================

-- Scenario 1: Reporting query (use NOLOCK)
CREATE OR ALTER PROCEDURE usp_GetSalesReport
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        YEAR(s.SaleDate) AS SaleYear,
        MONTH(s.SaleDate) AS SaleMonth,
        c.City,
        SUM(s.TotalAmount) AS Revenue,
        COUNT(s.SaleID) AS SaleCnt
    FROM Sales s WITH (NOLOCK)
    INNER JOIN Customers c WITH (NOLOCK) ON s.CustomerID = c.CustomerID
    GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate), c.City
    OPTION (MAXDOP 4);  -- Limit parallelism
END;
GO

-- Scenario 2: Critical transaction (use UPDLOCK, HOLDLOCK)
CREATE OR ALTER PROCEDURE usp_ProcessPayment
    @CustomerID INT,
    @Amount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
        
        DECLARE @CurrentBalance DECIMAL(10,2);
        
        -- Lock row for update (prevent deadlock)
        SELECT @CurrentBalance = TotalPurchases
        FROM Customers WITH (UPDLOCK, ROWLOCK, HOLDLOCK)
        WHERE CustomerID = @CustomerID;
        
        -- Validate sufficient funds
        IF @CurrentBalance >= @Amount
        BEGIN
            UPDATE Customers 
            SET TotalPurchases = TotalPurchases - @Amount
            WHERE CustomerID = @CustomerID;
            
            PRINT 'Payment processed';
        END
        ELSE
        BEGIN
            PRINT 'Insufficient funds';
        END
        
    COMMIT;
END;
GO

-- Scenario 3: Queue processing (use READPAST)
CREATE OR ALTER PROCEDURE usp_ProcessNextSale
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SaleID INT;
    
    BEGIN TRANSACTION;
        
        -- Get next available item (skip locked)
        SELECT TOP 1 @SaleID = SaleID
        FROM Sales WITH (READPAST, UPDLOCK, ROWLOCK)
        WHERE PaymentMethod = 'Pending'
        ORDER BY SaleDate;
        
        IF @SaleID IS NOT NULL
        BEGIN
            -- Process sale
            UPDATE Sales 
            SET PaymentMethod = 'Completed' 
            WHERE SaleID = @SaleID;
            
            PRINT 'Processed SaleID: ' + CAST(@SaleID AS VARCHAR(10));
        END
        ELSE
        BEGIN
            PRINT 'No sales to process';
        END
        
    COMMIT;
END;
GO

-- =============================================
-- Example 20: When NOT to Use Hints
-- =============================================

-- ❌ BAD: Over-hinting
/*
SELECT * FROM Products 
WITH (NOLOCK, ROWLOCK, INDEX(IX_SomeIndex), FORCESEEK)
WHERE ProductID = 1
OPTION (RECOMPILE, MAXDOP 1, FORCE ORDER, FAST 10);
-- Too many hints! Let optimizer do its job.
*/

-- ✅ GOOD: Minimal hints, only when needed
SELECT * FROM Products 
WHERE ProductID = 1;
-- Optimizer handles it fine
GO

-- ✅ Use hints only after identifying specific issues:
-- - Parameter sniffing → OPTION (RECOMPILE)
-- - Deadlocks → UPDLOCK
-- - Blocking reports → NOLOCK or SNAPSHOT
-- - Queue processing → READPAST
-- - CXPACKET waits → MAXDOP

-- =============================================
-- Cleanup
-- =============================================

DROP PROCEDURE IF EXISTS usp_GetProductsByPrice;
DROP PROCEDURE IF EXISTS usp_GetProductsByPrice_Recompile;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory;
DROP PROCEDURE IF EXISTS usp_GetSalesByCustomer;
DROP PROCEDURE IF EXISTS usp_GetSalesReport;
DROP PROCEDURE IF EXISTS usp_ProcessPayment;
DROP PROCEDURE IF EXISTS usp_ProcessNextSale;
GO

-- 💡 Key Takeaways:
--
-- QUERY HINTS (OPTION clause):
-- - RECOMPILE: Recompile every time (parameter sniffing fix, CPU cost)
-- - OPTIMIZE FOR: Optimize for specific value (when one value dominates)
-- - OPTIMIZE FOR UNKNOWN: Use average (safe default for varying data)
-- - MAXDOP: Limit parallelism (reduce CXPACKET waits)
-- - FORCE ORDER: Use join order as written (when optimizer chooses poorly)
-- - FAST N: Optimize for first N rows (TOP queries)
-- - LOOP/HASH/MERGE JOIN: Force join strategy
--
-- TABLE HINTS (WITH clause):
-- - NOLOCK: READ UNCOMMITTED (dirty reads, good for reports)
-- - UPDLOCK: Update lock (prevents deadlocks in read-then-update)
-- - ROWLOCK/PAGLOCK/TABLOCK: Control lock granularity
-- - HOLDLOCK: REPEATABLE READ (hold shared lock)
-- - READPAST: Skip locked rows (queue processing)
-- - FORCESEEK: Force index seek (no scan)
-- - INDEX(index_name): Force specific index
--
-- WHEN TO USE:
-- - RECOMPILE: Parameter sniffing with varying distributions
-- - NOLOCK: Reports where dirty reads acceptable
-- - UPDLOCK: Read-then-update to prevent deadlocks
-- - READPAST: Queue processing with multiple workers
-- - MAXDOP: High CXPACKET waits
-- - OPTIMIZE FOR: One parameter value accounts for 80%+ of executions
--
-- WHEN NOT TO USE:
-- - Don't over-hint (let optimizer work)
-- - Test hints in dev first
-- - Use Query Store plan forcing instead of USE PLAN
-- - Avoid INDEX hint unless optimizer clearly wrong
-- - Don't use NOLOCK for critical data
--
-- BEST PRACTICES:
-- - Measure before adding hints (actual execution plan)
-- - Use minimum hints necessary
-- - Document why hint is needed (code comments)
-- - Test under production-like load
-- - Monitor after deployment (Query Store)
-- - Prefer OPTION (RECOMPILE) over local variable trick
-- - Use UPDLOCK for read-then-update patterns
-- - Use READPAST for queue processing
-- - Limit MAXDOP to # of cores in NUMA node
