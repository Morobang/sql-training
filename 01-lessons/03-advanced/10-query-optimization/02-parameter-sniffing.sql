-- ========================================
-- Parameter Sniffing
-- Understanding, Detecting, and Solving
-- ========================================

USE TechStore;
GO

-- =============================================
-- What is Parameter Sniffing?
-- =============================================

/*
Parameter sniffing occurs when SQL Server compiles a stored procedure
using the FIRST parameter values it receives, then reuses that plan
for ALL subsequent executions—even if later parameters would benefit
from a different plan.

GOOD Parameter Sniffing: Plan works well for all parameter values
BAD Parameter Sniffing: Plan is inefficient for some parameter values
*/

-- =============================================
-- Example 1: Demonstrating Parameter Sniffing
-- =============================================

-- Create procedure without any hints
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Category = @Category;
END;
GO

-- Clear plan cache to start fresh
DBCC FREEPROCCACHE;
GO

-- First execution: Category with FEW rows (e.g., 'Specialty' has 5 rows)
EXEC usp_GetProductsByCategory @Category = 'Specialty';
-- Plan compiled with Index Seek (good for few rows)
GO

-- Check cached plan
SELECT 
    cp.usecounts,
    cp.cacheobjtype,
    cp.objtype,
    st.text AS QueryText,
    qp.query_plan
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
WHERE st.text LIKE '%GetProductsByCategory%'
AND st.text NOT LIKE '%sys.dm_exec%';
GO

-- Second execution: Category with MANY rows (e.g., 'Electronics' has 1000 rows)
EXEC usp_GetProductsByCategory @Category = 'Electronics';
-- Still uses Index Seek plan (inefficient for many rows - should scan)
-- This is BAD parameter sniffing!
GO

-- Check execution stats
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

EXEC usp_GetProductsByCategory @Category = 'Electronics';  -- Inefficient
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- =============================================
-- Example 2: Good Parameter Sniffing
-- =============================================

-- Scenario: All categories have similar row counts (good sniffing)

-- Insert balanced data
/*
INSERT INTO Products (ProductName, Category, Price, Cost, StockQuantity, SupplierID)
SELECT 'Product ' + CAST(n AS VARCHAR(10)), 
       CASE n % 3 WHEN 0 THEN 'Books' WHEN 1 THEN 'Toys' ELSE 'Games' END,
       100, 50, 10, 1
FROM (SELECT TOP 900 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n 
      FROM sys.objects a CROSS JOIN sys.objects b) nums;
*/

-- Now all categories have ~300 rows each
CREATE OR ALTER PROCEDURE usp_GetBalancedCategories
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE Category = @Category;
END;
GO

-- First call
EXEC usp_GetBalancedCategories @Category = 'Books';  -- Plan for ~300 rows
GO

-- Subsequent calls work well (all have ~300 rows)
EXEC usp_GetBalancedCategories @Category = 'Toys';   -- Same plan works
EXEC usp_GetBalancedCategories @Category = 'Games';  -- Same plan works
-- This is GOOD parameter sniffing!
GO

-- =============================================
-- Example 3: Bad Parameter Sniffing Detection
-- =============================================

-- Query to find procedures with parameter sniffing issues
SELECT 
    OBJECT_NAME(st.objectid) AS ProcedureName,
    qs.execution_count AS ExecutionCnt,
    qs.total_worker_time / qs.execution_count AS AvgCPU,
    qs.min_worker_time AS MinCPU,
    qs.max_worker_time AS MaxCPU,
    qs.total_elapsed_time / qs.execution_count AS AvgDuration,
    qs.min_elapsed_time AS MinDuration,
    qs.max_elapsed_time AS MaxDuration,
    qs.total_logical_reads / qs.execution_count AS AvgLogicalReads,
    qs.min_logical_reads AS MinLogicalReads,
    qs.max_logical_reads AS MaxLogicalReads,
    -- Variance indicators
    CASE 
        WHEN qs.max_worker_time > qs.min_worker_time * 10 THEN 'High CPU Variance'
        WHEN qs.max_logical_reads > qs.min_logical_reads * 10 THEN 'High IO Variance'
        ELSE 'Normal'
    END AS SniffingIndicator
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.objectid IS NOT NULL
AND qs.execution_count > 5  -- Must have multiple executions
ORDER BY 
    CASE 
        WHEN qs.max_worker_time > qs.min_worker_time * 10 THEN 1
        WHEN qs.max_logical_reads > qs.min_logical_reads * 10 THEN 1
        ELSE 2
    END,
    qs.total_worker_time DESC;
GO

-- =============================================
-- Solution 1: OPTION (RECOMPILE)
-- =============================================

-- Recompile every execution (accurate plans, CPU cost)
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory_Recompile
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Category = @Category
    OPTION (RECOMPILE);  -- New plan every time
END;
GO

-- Clear cache
DBCC FREEPROCCACHE;
GO

-- Each execution gets optimal plan
EXEC usp_GetProductsByCategory_Recompile @Category = 'Specialty';    -- Seek plan
EXEC usp_GetProductsByCategory_Recompile @Category = 'Electronics';  -- Scan plan
GO

-- Verify no plan cached
SELECT 
    cp.usecounts,
    st.text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.text LIKE '%GetProductsByCategory_Recompile%'
AND st.text NOT LIKE '%sys.dm_exec%';
-- Shows usecounts = 0 or no results (compiled but not cached)
GO

-- ✅ Use when: Parameters have widely varying distributions
-- ❌ Avoid when: High execution frequency (compilation CPU cost)

-- =============================================
-- Solution 2: OPTION (OPTIMIZE FOR)
-- =============================================

-- Optimize for specific value (most common parameter)
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory_OptimizeFor
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Category = @Category
    OPTION (OPTIMIZE FOR (@Category = 'Electronics'));
    -- Plan optimized for 'Electronics' even if first call is different
END;
GO

DBCC FREEPROCCACHE;
GO

-- All executions use plan optimized for 'Electronics'
EXEC usp_GetProductsByCategory_OptimizeFor @Category = 'Books';        -- Uses Electronics plan
EXEC usp_GetProductsByCategory_OptimizeFor @Category = 'Electronics';  -- Optimal
EXEC usp_GetProductsByCategory_OptimizeFor @Category = 'Specialty';    -- Uses Electronics plan
GO

-- ✅ Use when: One parameter value accounts for 80%+ of executions
-- ❌ Avoid when: Parameters evenly distributed

-- =============================================
-- Solution 3: OPTION (OPTIMIZE FOR UNKNOWN)
-- =============================================

-- Use average selectivity (density vector)
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory_Unknown
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Category = @Category
    OPTION (OPTIMIZE FOR (@Category UNKNOWN));
    -- Uses average selectivity, not sniffed parameter
END;
GO

DBCC FREEPROCCACHE;
GO

-- All executions use same "average" plan
EXEC usp_GetProductsByCategory_Unknown @Category = 'Specialty';    -- Average plan
EXEC usp_GetProductsByCategory_Unknown @Category = 'Electronics';  -- Average plan
GO

-- ✅ Use when: Parameters have varying distributions, but average plan acceptable
-- ❌ Avoid when: Extreme skew (one value has 99% of data)

-- =============================================
-- Solution 4: Local Variable (Breaks Sniffing)
-- =============================================

-- Copy parameter to local variable (optimizer can't sniff)
CREATE OR ALTER PROCEDURE usp_GetProductsByCategory_LocalVar
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Copy to local variable
    DECLARE @LocalCategory VARCHAR(50) = @Category;
    
    SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Category = @LocalCategory;
    -- Uses density vector (average selectivity)
END;
GO

DBCC FREEPROCCACHE;
GO

EXEC usp_GetProductsByCategory_LocalVar @Category = 'Electronics';
-- Plan based on average, not actual parameter
GO

-- ⚠️ This is the "old" way (pre-SQL 2016)
-- Better to use OPTION (OPTIMIZE FOR UNKNOWN) for clarity
-- But still works and sometimes useful

-- =============================================
-- Solution 5: Multiple Procedures (Split Logic)
-- =============================================

-- Create separate procedures for different scenarios
CREATE OR ALTER PROCEDURE usp_GetFewProducts
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Optimized for few rows (use seek)
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE Category = @Category;
END;
GO

CREATE OR ALTER PROCEDURE usp_GetManyProducts
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Optimized for many rows (use scan)
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE Category = @Category;
END;
GO

-- Wrapper procedure chooses appropriate one
CREATE OR ALTER PROCEDURE usp_GetProductsSmart
    @Category VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Determine expected row count
    DECLARE @ExpectedRows INT;
    
    SELECT @ExpectedRows = COUNT(*)
    FROM Products
    WHERE Category = @Category;
    
    -- Route to appropriate procedure
    IF @ExpectedRows < 100
        EXEC usp_GetFewProducts @Category;
    ELSE
        EXEC usp_GetManyProducts @Category;
END;
GO

-- Test
EXEC usp_GetProductsSmart @Category = 'Specialty';    -- Routes to usp_GetFewProducts
EXEC usp_GetProductsSmart @Category = 'Electronics';  -- Routes to usp_GetManyProducts
GO

-- ✅ Use when: Clear threshold between "few" and "many" rows
-- ❌ Avoid when: Adds complexity, maintenance overhead

-- =============================================
-- Solution 6: Plan Guides
-- =============================================

-- Apply hints without modifying procedure code
-- Useful for third-party apps where you can't change code

-- Create plan guide
EXEC sp_create_plan_guide 
    @name = N'PlanGuide_GetProductsByCategory',
    @stmt = N'SELECT ProductID, ProductName, Price, StockQuantity
    FROM Products
    WHERE Category = @Category',
    @type = N'OBJECT',
    @module_or_batch = N'usp_GetProductsByCategory',
    @params = NULL,
    @hints = N'OPTION (RECOMPILE)';
GO

-- Now procedure uses RECOMPILE without code change
EXEC usp_GetProductsByCategory @Category = 'Electronics';
GO

-- View plan guides
SELECT * FROM sys.plan_guides
WHERE name = 'PlanGuide_GetProductsByCategory';
GO

-- Drop plan guide
EXEC sp_control_plan_guide @operation = N'DROP', @name = N'PlanGuide_GetProductsByCategory';
GO

-- ✅ Use when: Can't modify application code
-- ❌ Avoid when: Can modify code (hints in code are clearer)

-- =============================================
-- Solution 7: Query Store Plan Forcing (SQL 2016+)
-- =============================================

-- Enable Query Store
ALTER DATABASE TechStore SET QUERY_STORE = ON;
GO

-- Execute procedure multiple times
EXEC usp_GetProductsByCategory @Category = 'Specialty';    -- Good plan
EXEC usp_GetProductsByCategory @Category = 'Electronics';  -- Bad plan
GO

-- Query Query Store to find best plan
SELECT 
    q.query_id,
    qt.query_sql_text,
    p.plan_id,
    p.query_plan,
    rs.avg_duration,
    rs.avg_logical_io_reads
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE qt.query_sql_text LIKE '%GetProductsByCategory%'
ORDER BY rs.avg_duration;
GO

-- Force best plan (use plan_id from above query)
-- EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 1;

-- View forced plans
SELECT * FROM sys.query_store_plan WHERE is_forced_plan = 1;
GO

-- Unforce plan
-- EXEC sp_query_store_unforce_plan @query_id = 1, @plan_id = 1;

-- =============================================
-- Example 8: Real-World Scenario
-- =============================================

-- Sales report with date range parameter sniffing
CREATE OR ALTER PROCEDURE usp_GetSalesReport
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Problem: First call might be 1 day range, next call 1 year range
    -- Solution: RECOMPILE for accurate cardinality estimates
    SELECT 
        c.CustomerName,
        SUM(s.TotalAmount) AS TotalRevenue,
        COUNT(s.SaleID) AS SaleCnt
    FROM Sales s
    INNER JOIN Customers c ON s.CustomerID = c.CustomerID
    WHERE s.SaleDate >= @StartDate AND s.SaleDate < @EndDate
    GROUP BY c.CustomerName
    OPTION (RECOMPILE);
END;
GO

-- Test with varying ranges
EXEC usp_GetSalesReport @StartDate = '2024-01-01', @EndDate = '2024-01-02';  -- 1 day
EXEC usp_GetSalesReport @StartDate = '2023-01-01', @EndDate = '2024-01-01';  -- 1 year
-- Each gets appropriate plan
GO

-- =============================================
-- Example 9: Monitoring Parameter Sniffing
-- =============================================

-- Create Extended Event to capture parameter values
CREATE EVENT SESSION ParameterSniffing ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.plan_handle, sqlserver.query_hash, sqlserver.sql_text)
    WHERE sqlserver.database_name = 'TechStore'
)
ADD TARGET package0.event_file(SET filename=N'C:\Temp\ParameterSniffing.xel')
WITH (MAX_MEMORY=4096 KB);
GO

-- Start session
-- ALTER EVENT SESSION ParameterSniffing ON SERVER STATE = START;

-- Later, stop and drop
-- ALTER EVENT SESSION ParameterSniffing ON SERVER STATE = STOP;
-- DROP EVENT SESSION ParameterSniffing ON SERVER;

-- =============================================
-- Example 10: Testing Different Solutions
-- =============================================

-- Create test harness to compare solutions
CREATE OR ALTER PROCEDURE usp_CompareSniffingSolutions
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2;
    DECLARE @EndTime DATETIME2;
    DECLARE @Duration INT;
    
    PRINT 'Testing Parameter Sniffing Solutions';
    PRINT REPLICATE('-', 50);
    
    -- Test 1: Default (with sniffing)
    DBCC FREEPROCCACHE;
    SET @StartTime = SYSDATETIME();
    EXEC usp_GetProductsByCategory @Category = 'Electronics';
    SET @EndTime = SYSDATETIME();
    SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    PRINT 'Default (with sniffing): ' + CAST(@Duration AS VARCHAR(10)) + ' ms';
    
    -- Test 2: OPTION (RECOMPILE)
    SET @StartTime = SYSDATETIME();
    EXEC usp_GetProductsByCategory_Recompile @Category = 'Electronics';
    SET @EndTime = SYSDATETIME();
    SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    PRINT 'OPTION (RECOMPILE): ' + CAST(@Duration AS VARCHAR(10)) + ' ms';
    
    -- Test 3: OPTION (OPTIMIZE FOR)
    SET @StartTime = SYSDATETIME();
    EXEC usp_GetProductsByCategory_OptimizeFor @Category = 'Electronics';
    SET @EndTime = SYSDATETIME();
    SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    PRINT 'OPTION (OPTIMIZE FOR): ' + CAST(@Duration AS VARCHAR(10)) + ' ms';
    
    -- Test 4: OPTION (OPTIMIZE FOR UNKNOWN)
    SET @StartTime = SYSDATETIME();
    EXEC usp_GetProductsByCategory_Unknown @Category = 'Electronics';
    SET @EndTime = SYSDATETIME();
    SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    PRINT 'OPTION (OPTIMIZE FOR UNKNOWN): ' + CAST(@Duration AS VARCHAR(10)) + ' ms';
    
    PRINT REPLICATE('-', 50);
END;
GO

-- Run comparison
EXEC usp_CompareSniffingSolutions;
GO

-- =============================================
-- Cleanup
-- =============================================

DROP PROCEDURE IF EXISTS usp_GetProductsByCategory;
DROP PROCEDURE IF EXISTS usp_GetBalancedCategories;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory_Recompile;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory_OptimizeFor;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory_Unknown;
DROP PROCEDURE IF EXISTS usp_GetProductsByCategory_LocalVar;
DROP PROCEDURE IF EXISTS usp_GetFewProducts;
DROP PROCEDURE IF EXISTS usp_GetManyProducts;
DROP PROCEDURE IF EXISTS usp_GetProductsSmart;
DROP PROCEDURE IF EXISTS usp_GetSalesReport;
DROP PROCEDURE IF EXISTS usp_CompareSniffingSolutions;
GO

-- 💡 Key Takeaways:
--
-- WHAT IS PARAMETER SNIFFING?
-- - SQL Server compiles procedure using FIRST parameter values
-- - Plan cached and reused for ALL subsequent executions
-- - GOOD when all parameters have similar characteristics
-- - BAD when parameters have widely varying distributions
--
-- DETECTION:
-- - High variance in execution time/IO (min vs max > 10x)
-- - Query sys.dm_exec_query_stats for variance
-- - Extended Events to capture parameter values
-- - Query Store for plan performance comparison
--
-- SOLUTIONS:
-- ┌──────────────────────────┬─────────────────────────┬───────────────────────┐
-- │ Solution                 │ When to Use             │ Trade-off             │
-- ├──────────────────────────┼─────────────────────────┼───────────────────────┤
-- │ OPTION (RECOMPILE)       │ Varying distributions   │ CPU cost (compile)    │
-- │ OPTION (OPTIMIZE FOR)    │ One value dominates     │ Poor for other values │
-- │ OPTION (OPTIMIZE FOR     │ Varying, average ok     │ May not be optimal    │
-- │   UNKNOWN)               │                         │                       │
-- │ Local variable           │ Legacy (pre-SQL 2016)   │ Less clear intent     │
-- │ Multiple procedures      │ Clear threshold exists  │ Code complexity       │
-- │ Plan guides              │ Can't modify code       │ Hard to maintain      │
-- │ Query Store forcing      │ SQL 2016+, good plan    │ Plan may become stale │
-- └──────────────────────────┴─────────────────────────┴───────────────────────┘
--
-- DECISION TREE:
-- 1. Can you modify code?
--    NO → Use plan guides or Query Store plan forcing
--    YES → Continue to #2
--
-- 2. How many executions per second?
--    HIGH (>100/sec) → Avoid RECOMPILE (CPU cost)
--    LOW → OPTION (RECOMPILE) is fine
--
-- 3. Distribution of parameters?
--    One value = 80%+ → OPTION (OPTIMIZE FOR)
--    Evenly distributed → OPTION (OPTIMIZE FOR UNKNOWN)
--    Extreme variance → OPTION (RECOMPILE) or multiple procedures
--
-- 4. Date range parameters?
--    YES → OPTION (RECOMPILE) recommended (wildly varying ranges)
--
-- BEST PRACTICES:
-- - Prefer OPTION (OPTIMIZE FOR UNKNOWN) as safe default
-- - Use OPTION (RECOMPILE) for date range queries
-- - Use OPTION (OPTIMIZE FOR) when one value dominates
-- - Monitor with Query Store (automatic regression detection)
-- - Test solutions with production-like data distribution
-- - Document why hint is needed (code comment)
-- - Avoid local variable trick (use OPTIMIZE FOR UNKNOWN instead)
-- - Consider multiple procedures only when threshold is clear
-- - Use plan guides only when code can't be modified
--
-- MONITORING:
-- - sys.dm_exec_query_stats (execution variance)
-- - Query Store (plan performance history)
-- - Extended Events (parameter values captured)
-- - Execution plans (check estimated vs actual rows)
-- - SET STATISTICS TIME/IO (measure impact)
