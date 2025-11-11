-- ========================================
-- Global Temporary Tables (##temp)
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Creating and Using ##temp Tables
-- =============================================

-- Global temp table visible to ALL sessions
CREATE TABLE ##SharedSalesData (
    SaleID INT,
    SaleDate DATE,
    TotalAmount DECIMAL(10,2),
    ProcessedBy NVARCHAR(128),
    ProcessedAt DATETIME
);

-- Insert data
INSERT INTO ##SharedSalesData (SaleID, SaleDate, TotalAmount, ProcessedBy, ProcessedAt)
SELECT 
    SaleID,
    CAST(SaleDate AS DATE) AS SaleDate,
    TotalAmount,
    SUSER_NAME() AS ProcessedBy,
    GETDATE() AS ProcessedAt
FROM Sales;

-- Any session can now access this data
SELECT TOP 10 * FROM ##SharedSalesData;

-- Difference from #temp: Other users/sessions can see ##SharedSalesData
-- ##temp tables are deleted when ALL sessions that reference them close

DROP TABLE ##SharedSalesData;

-- =============================================
-- Example 2: Sharing Data Across Procedures
-- =============================================

-- Procedure 1: Creates global temp table
CREATE OR ALTER PROCEDURE CreateSharedReport
AS
BEGIN
    -- Check if table already exists (another session might have created it)
    IF OBJECT_ID('tempdb..##DailySalesReport') IS NOT NULL
        DROP TABLE ##DailySalesReport;
    
    CREATE TABLE ##DailySalesReport (
        SaleDate DATE,
        TotalOrders INT,
        TotalRevenue DECIMAL(10,2),
        TopCategory NVARCHAR(50)
    );
    
    INSERT INTO ##DailySalesReport
    SELECT 
        CAST(s.SaleDate AS DATE) AS SaleDate,
        COUNT(s.SaleID) AS TotalOrders,
        SUM(s.TotalAmount) AS TotalRevenue,
        (
            SELECT TOP 1 p.Category
            FROM Sales s2
            INNER JOIN Products p ON s2.ProductID = p.ProductID
            WHERE CAST(s2.SaleDate AS DATE) = CAST(s.SaleDate AS DATE)
            GROUP BY p.Category
            ORDER BY COUNT(*) DESC
        ) AS TopCategory
    FROM Sales s
    GROUP BY CAST(s.SaleDate AS DATE);
    
    SELECT 'Report created successfully' AS Status;
END;
GO

-- Procedure 2: Reads from global temp table
CREATE OR ALTER PROCEDURE ReadSharedReport
AS
BEGIN
    IF OBJECT_ID('tempdb..##DailySalesReport') IS NULL
    BEGIN
        SELECT 'Report not found. Run CreateSharedReport first.' AS ErrorMessage;
        RETURN;
    END;
    
    SELECT * FROM ##DailySalesReport ORDER BY SaleDate DESC;
END;
GO

-- Test workflow
EXEC CreateSharedReport;
EXEC ReadSharedReport;

-- Clean up
DROP TABLE IF EXISTS ##DailySalesReport;
DROP PROCEDURE IF EXISTS CreateSharedReport;
DROP PROCEDURE IF EXISTS ReadSharedReport;

-- =============================================
-- Example 3: Coordination Table Pattern
-- =============================================

-- Use global temp as a coordination mechanism
CREATE TABLE ##ProcessStatus (
    ProcessID INT IDENTITY(1,1) PRIMARY KEY,
    ProcessName NVARCHAR(100),
    Status NVARCHAR(50),
    StartTime DATETIME,
    EndTime DATETIME,
    RecordsProcessed INT
);

-- Simulated background process 1
INSERT INTO ##ProcessStatus (ProcessName, Status, StartTime, RecordsProcessed)
VALUES ('CustomerDataRefresh', 'Running', GETDATE(), 0);

DECLARE @ProcessID1 INT = SCOPE_IDENTITY();

-- Simulate work...
WAITFOR DELAY '00:00:02';

UPDATE ##ProcessStatus 
SET Status = 'Completed', EndTime = GETDATE(), RecordsProcessed = 150
WHERE ProcessID = @ProcessID1;

-- Simulated background process 2
INSERT INTO ##ProcessStatus (ProcessName, Status, StartTime, RecordsProcessed)
VALUES ('SalesDataRefresh', 'Running', GETDATE(), 0);

DECLARE @ProcessID2 INT = SCOPE_IDENTITY();

-- Simulate work...
WAITFOR DELAY '00:00:01';

UPDATE ##ProcessStatus 
SET Status = 'Completed', EndTime = GETDATE(), RecordsProcessed = 320
WHERE ProcessID = @ProcessID2;

-- Monitor all processes
SELECT 
    ProcessName,
    Status,
    StartTime,
    EndTime,
    DATEDIFF(SECOND, StartTime, ISNULL(EndTime, GETDATE())) AS DurationSeconds,
    RecordsProcessed
FROM ##ProcessStatus
ORDER BY ProcessID;

DROP TABLE ##ProcessStatus;

-- =============================================
-- Example 4: When to Use ##temp vs #temp
-- =============================================

-- Use #temp (local) when:
-- ✅ Data is session-specific
-- ✅ Multiple users should NOT see each other's data
-- ✅ Security/isolation is important
-- ✅ 99% of use cases!

-- Use ##temp (global) when:
-- ✅ Sharing data across procedures in same batch
-- ✅ Coordination between processes
-- ✅ Building shared lookup/reference data
-- ⚠️ Be careful with concurrent access!

-- Example: Shared lookup table
CREATE TABLE ##ProductCategories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50)
);

INSERT INTO ##ProductCategories (CategoryName)
SELECT DISTINCT Category FROM Products ORDER BY Category;

-- Multiple procedures can reference this
SELECT * FROM ##ProductCategories;

DROP TABLE ##ProductCategories;

-- =============================================
-- Example 5: Concurrency Considerations
-- =============================================

-- Problem: Multiple sessions might try to create same ##temp table

-- Solution 1: Check before creating
IF OBJECT_ID('tempdb..##SharedConfig') IS NULL
BEGIN
    CREATE TABLE ##SharedConfig (
        ConfigKey NVARCHAR(50),
        ConfigValue NVARCHAR(500)
    );
    
    INSERT INTO ##SharedConfig VALUES 
        ('Environment', 'Development'),
        ('Version', '1.0'),
        ('EnableDebug', 'True');
END;

SELECT * FROM ##SharedConfig;

-- Solution 2: Use unique names per session
DECLARE @SessionID NVARCHAR(50) = CAST(@@SPID AS NVARCHAR);
DECLARE @TableName NVARCHAR(100) = '##ProcessData_' + @SessionID;
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = 'CREATE TABLE ' + @TableName + ' (ID INT, DataValue NVARCHAR(100))';
EXEC(@SQL);

-- Each session gets its own table: ##ProcessData_52, ##ProcessData_53, etc.

-- Clean up
DROP TABLE IF EXISTS ##SharedConfig;

-- 💡 Key Points:
-- - ##temp tables are visible across ALL sessions
-- - Deleted when last session referencing them closes
-- - Use for sharing data between procedures
-- - Avoid for session-specific data (use #temp instead)
-- - Check existence before creating to avoid errors
-- - Be careful with concurrent access and naming conflicts
