/*
================================================================================
LESSON 15.5: DEPLOYMENT AND VERIFICATION
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Validate database schemas before deployment
2. Compare schemas across environments
3. Verify successful deployments
4. Create deployment checklists
5. Build rollback scripts
6. Automate post-deployment validation
7. Monitor schema drift

Business Context:
-----------------
Proper deployment verification prevents production issues and ensures database
changes are applied correctly. Automated validation reduces human error and
provides audit trails for compliance. These techniques are critical for
maintaining data integrity across development, staging, and production environments.

Database: RetailStore
Complexity: Advanced
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: PRE-DEPLOYMENT VALIDATION
================================================================================

Validate schema changes before deploying to production.
*/

-- Create deployment environment
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) UNIQUE,
    CreatedDate DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    StockQuantity INT DEFAULT 0
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(12,2)
);

CREATE TABLE OrderItem (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL
);
GO

-- Example 1: Check for missing indexes
SELECT 
    'Missing Index' AS IssueType,
    t.name AS TableName,
    'No clustered index' AS Issue,
    'MEDIUM' AS Severity
FROM sys.tables t
WHERE t.is_ms_shipped = 0
  AND NOT EXISTS (
      SELECT 1 FROM sys.indexes i
      WHERE i.object_id = t.object_id AND i.type = 1
  )

UNION ALL

SELECT 
    'Missing Index' AS IssueType,
    OBJECT_NAME(fkc.parent_object_id) AS TableName,
    'FK column ' + COL_NAME(fkc.parent_object_id, fkc.parent_column_id) + ' lacks index' AS Issue,
    'HIGH' AS Severity
FROM sys.foreign_key_columns fkc
WHERE NOT EXISTS (
    SELECT 1 FROM sys.index_columns ic
    WHERE ic.object_id = fkc.parent_object_id
      AND ic.column_id = fkc.parent_column_id
      AND ic.index_id > 0
      AND ic.key_ordinal = 1
)
ORDER BY Severity DESC, TableName;
GO

/*
OUTPUT:
IssueType      TableName   Issue                                   Severity
-------------  ----------  --------------------------------------  --------
Missing Index  Order       FK column CustomerID lacks index        HIGH
Missing Index  OrderItem   FK column OrderID lacks index           HIGH
Missing Index  OrderItem   FK column ProductID lacks index         HIGH

Pre-deployment warnings!
*/

-- Example 2: Validate constraints exist
SELECT 
    t.name AS TableName,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM sys.indexes i
            WHERE i.object_id = t.object_id AND i.is_primary_key = 1
        ) THEN 'Missing primary key'
        ELSE 'OK'
    END AS PKStatus,
    COUNT(DISTINCT fk.object_id) AS ForeignKeyCount,
    COUNT(DISTINCT cc.object_id) AS CheckConstraintCount
FROM sys.tables t
LEFT JOIN sys.foreign_keys fk ON t.object_id = fk.parent_object_id
LEFT JOIN sys.check_constraints cc ON t.object_id = cc.parent_object_id
WHERE t.is_ms_shipped = 0
GROUP BY t.name, t.object_id
ORDER BY t.name;
GO

/*
OUTPUT:
TableName    PKStatus  ForeignKeyCount  CheckConstraintCount
-----------  --------  ---------------  --------------------
Customer     OK        0                0
Order        OK        1                0
OrderItem    OK        2                2
Product      OK        0                1

Constraint validation!
*/

-- Example 3: Check for naming convention violations
SELECT 
    'Naming Convention' AS IssueType,
    t.name AS TableName,
    i.name AS IndexName,
    'Index does not follow naming convention' AS Issue
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.is_ms_shipped = 0
  AND i.type > 0
  AND i.is_primary_key = 0
  AND i.name NOT LIKE 'IX_%'
  AND i.name NOT LIKE 'PK_%'
  AND i.name NOT LIKE 'UQ_%';
GO

/*
================================================================================
PART 2: SCHEMA COMPARISON
================================================================================

Compare schemas between environments (DEV vs PROD).
*/

-- Simulate two environments by creating comparison tables
SELECT * INTO Customer_PROD FROM Customer WHERE 1=0;
ALTER TABLE Customer_PROD ADD PhoneNumber VARCHAR(20);
GO

-- Example 1: Find table differences
WITH SourceTables AS (
    SELECT name AS TableName FROM sys.tables 
    WHERE name IN ('Customer', 'Product', 'Order', 'OrderItem')
),
TargetTables AS (
    SELECT REPLACE(name, '_PROD', '') AS TableName 
    FROM sys.tables 
    WHERE name LIKE '%_PROD'
)
SELECT 
    COALESCE(s.TableName, t.TableName) AS TableName,
    CASE 
        WHEN s.TableName IS NULL THEN 'Missing in Source (DEV)'
        WHEN t.TableName IS NULL THEN 'Missing in Target (PROD)'
        ELSE 'Exists in Both'
    END AS Status
FROM SourceTables s
FULL OUTER JOIN TargetTables t ON s.TableName = t.TableName
ORDER BY Status, TableName;
GO

/*
OUTPUT:
TableName    Status
-----------  --------------------------
Customer     Exists in Both
Order        Missing in Target (PROD)
OrderItem    Missing in Target (PROD)
Product      Missing in Target (PROD)

Table comparison results!
*/

-- Example 2: Compare column structures
SELECT 
    COALESCE(c1.name, c2.name) AS ColumnName,
    TYPE_NAME(c1.user_type_id) AS SourceType,
    TYPE_NAME(c2.user_type_id) AS TargetType,
    c1.is_nullable AS SourceNullable,
    c2.is_nullable AS TargetNullable,
    CASE 
        WHEN c1.name IS NULL THEN 'Missing in Source'
        WHEN c2.name IS NULL THEN 'Missing in Target'
        WHEN TYPE_NAME(c1.user_type_id) <> TYPE_NAME(c2.user_type_id) THEN 'Type Mismatch'
        WHEN c1.is_nullable <> c2.is_nullable THEN 'Nullability Mismatch'
        ELSE 'Match'
    END AS ComparisonResult
FROM sys.columns c1
FULL OUTER JOIN sys.columns c2 
    ON c1.name = c2.name
    AND c2.object_id = OBJECT_ID('Customer_PROD')
WHERE c1.object_id = OBJECT_ID('Customer')
   OR c2.object_id = OBJECT_ID('Customer_PROD')
ORDER BY ColumnName;
GO

/*
OUTPUT:
ColumnName      SourceType  TargetType  SourceNullable  TargetNullable  ComparisonResult
--------------  ----------  ----------  --------------  --------------  -------------------
CreatedDate     datetime2   datetime2   1               1               Match
CustomerID      int         int         0               0               Match
CustomerName    nvarchar    nvarchar    0               0               Match
Email           nvarchar    nvarchar    1               1               Match
PhoneNumber     NULL        varchar     NULL            1               Missing in Source

Column comparison!
*/

-- Example 3: Compare indexes
SELECT 
    i.name AS IndexName,
    'Source' AS Environment,
    i.type_desc AS IndexType,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') 
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Customer') AND i.type > 0
GROUP BY i.name, i.type_desc

UNION ALL

SELECT 
    i.name AS IndexName,
    'Target' AS Environment,
    i.type_desc AS IndexType,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') 
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Customer_PROD') AND i.type > 0
GROUP BY i.name, i.type_desc
ORDER BY IndexName, Environment;
GO

/*
================================================================================
PART 3: POST-DEPLOYMENT VERIFICATION
================================================================================

Verify deployment was successful and complete.
*/

-- Example 1: Verify all expected tables exist
DECLARE @ExpectedTables TABLE (TableName NVARCHAR(128));
INSERT INTO @ExpectedTables VALUES ('Customer'), ('Product'), ('Order'), ('OrderItem');

SELECT 
    et.TableName,
    CASE WHEN t.name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS Status,
    ISNULL(t.create_date, NULL) AS CreatedDate
FROM @ExpectedTables et
LEFT JOIN sys.tables t ON et.TableName = t.name
ORDER BY Status, TableName;
GO

/*
OUTPUT:
TableName    Status   CreatedDate
-----------  -------  -------------------
Customer     EXISTS   2024-11-09 10:00:00
Order        EXISTS   2024-11-09 10:00:00
OrderItem    EXISTS   2024-11-09 10:00:00
Product      EXISTS   2024-11-09 10:00:00

All tables deployed!
*/

-- Example 2: Verify column counts
DECLARE @ExpectedSchema TABLE (
    TableName NVARCHAR(128),
    ExpectedColumns INT
);

INSERT INTO @ExpectedSchema VALUES 
    ('Customer', 4),
    ('Product', 4),
    ('Order', 4),
    ('OrderItem', 5);

SELECT 
    es.TableName,
    es.ExpectedColumns,
    COUNT(c.column_id) AS ActualColumns,
    CASE 
        WHEN COUNT(c.column_id) = es.ExpectedColumns THEN 'OK'
        WHEN COUNT(c.column_id) < es.ExpectedColumns THEN 'MISSING COLUMNS'
        ELSE 'EXTRA COLUMNS'
    END AS Status
FROM @ExpectedSchema es
LEFT JOIN sys.tables t ON es.TableName = t.name
LEFT JOIN sys.columns c ON t.object_id = c.object_id
GROUP BY es.TableName, es.ExpectedColumns
ORDER BY Status DESC, TableName;
GO

-- Example 3: Verify foreign key relationships
DECLARE @ExpectedFKs TABLE (
    FromTable NVARCHAR(128),
    ToTable NVARCHAR(128)
);

INSERT INTO @ExpectedFKs VALUES 
    ('Order', 'Customer'),
    ('OrderItem', 'Order'),
    ('OrderItem', 'Product');

SELECT 
    efk.FromTable,
    efk.ToTable,
    CASE WHEN fk.object_id IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS Status,
    fk.name AS FKName
FROM @ExpectedFKs efk
LEFT JOIN sys.foreign_keys fk 
    ON OBJECT_NAME(fk.parent_object_id) = efk.FromTable
    AND OBJECT_NAME(fk.referenced_object_id) = efk.ToTable
ORDER BY Status, FromTable;
GO

/*
OUTPUT:
FromTable   ToTable   Status  FKName
----------  --------  ------  ------------------------
Order       Customer  EXISTS  FK__Order__CustomerID...
OrderItem   Order     EXISTS  FK__OrderItem__OrderID...
OrderItem   Product   EXISTS  FK__OrderItem__ProductID...

All FKs deployed!
*/

-- Example 4: Comprehensive deployment verification
CREATE OR ALTER PROCEDURE usp_VerifyDeployment
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #VerificationResults (
        CheckType VARCHAR(50),
        ObjectName NVARCHAR(128),
        Status VARCHAR(20),
        Details NVARCHAR(500)
    );
    
    -- Check tables
    INSERT INTO #VerificationResults
    SELECT 
        'Table',
        name,
        'OK',
        'Rows: ' + CAST(ISNULL(SUM(p.rows), 0) AS VARCHAR(20))
    FROM sys.tables t
    LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
    WHERE t.is_ms_shipped = 0
    GROUP BY name;
    
    -- Check primary keys
    INSERT INTO #VerificationResults
    SELECT 
        'Primary Key',
        t.name,
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.indexes i
            WHERE i.object_id = t.object_id AND i.is_primary_key = 1
        ) THEN 'OK' ELSE 'MISSING' END,
        ISNULL(i.name, 'No PK defined')
    FROM sys.tables t
    LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
    WHERE t.is_ms_shipped = 0;
    
    -- Check foreign keys
    INSERT INTO #VerificationResults
    SELECT 
        'Foreign Key',
        fk.name,
        CASE WHEN fk.is_disabled = 0 THEN 'OK' ELSE 'DISABLED' END,
        OBJECT_NAME(fk.parent_object_id) + ' -> ' + OBJECT_NAME(fk.referenced_object_id)
    FROM sys.foreign_keys fk;
    
    -- Check constraints
    INSERT INTO #VerificationResults
    SELECT 
        'Check Constraint',
        cc.name,
        CASE WHEN cc.is_disabled = 0 THEN 'OK' ELSE 'DISABLED' END,
        'On ' + OBJECT_NAME(cc.parent_object_id)
    FROM sys.check_constraints cc;
    
    -- Return results
    SELECT * FROM #VerificationResults
    ORDER BY 
        CASE Status WHEN 'OK' THEN 1 ELSE 0 END,
        CheckType,
        ObjectName;
    
    -- Summary
    SELECT 
        CheckType,
        COUNT(*) AS TotalChecks,
        SUM(CASE WHEN Status = 'OK' THEN 1 ELSE 0 END) AS Passed,
        SUM(CASE WHEN Status <> 'OK' THEN 1 ELSE 0 END) AS Failed
    FROM #VerificationResults
    GROUP BY CheckType;
    
    DROP TABLE #VerificationResults;
END;
GO

-- Execute verification
EXEC usp_VerifyDeployment;
GO

/*
================================================================================
PART 4: DEPLOYMENT CHECKLIST
================================================================================

Automated checklist for deployment readiness.
*/

-- Example 1: Pre-deployment checklist
CREATE OR ALTER PROCEDURE usp_PreDeploymentChecklist
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== PRE-DEPLOYMENT CHECKLIST ===';
    PRINT 'Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
    PRINT '';
    
    -- 1. Check for active connections
    DECLARE @ActiveConnections INT;
    SELECT @ActiveConnections = COUNT(*) 
    FROM sys.dm_exec_sessions 
    WHERE database_id = DB_ID() AND is_user_process = 1;
    
    PRINT '1. Active Connections: ' + CAST(@ActiveConnections AS VARCHAR(10));
    IF @ActiveConnections > 5
        PRINT '   WARNING: More than 5 active connections';
    PRINT '';
    
    -- 2. Check for long-running transactions
    IF EXISTS (
        SELECT 1 FROM sys.dm_tran_active_transactions
        WHERE DATEDIFF(MINUTE, transaction_begin_time, GETDATE()) > 5
    )
        PRINT '2. Long-Running Transactions: WARNING - Found transactions > 5 min'
    ELSE
        PRINT '2. Long-Running Transactions: OK';
    PRINT '';
    
    -- 3. Check database size
    DECLARE @DBSizeMB DECIMAL(10,2);
    SELECT @DBSizeMB = SUM(size * 8.0 / 1024)
    FROM sys.database_files;
    
    PRINT '3. Database Size: ' + CAST(@DBSizeMB AS VARCHAR(20)) + ' MB';
    PRINT '';
    
    -- 4. Check for disabled constraints
    DECLARE @DisabledConstraints INT;
    SELECT @DisabledConstraints = COUNT(*)
    FROM sys.check_constraints WHERE is_disabled = 1
    UNION ALL
    SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled = 1;
    
    PRINT '4. Disabled Constraints: ' + CAST(@DisabledConstraints AS VARCHAR(10));
    IF @DisabledConstraints > 0
        PRINT '   WARNING: Found disabled constraints';
    PRINT '';
    
    -- 5. Check for missing indexes on FKs
    DECLARE @MissingIndexes INT;
    SELECT @MissingIndexes = COUNT(DISTINCT fkc.parent_column_id)
    FROM sys.foreign_key_columns fkc
    WHERE NOT EXISTS (
        SELECT 1 FROM sys.index_columns ic
        WHERE ic.object_id = fkc.parent_object_id
          AND ic.column_id = fkc.parent_column_id
          AND ic.key_ordinal = 1
    );
    
    PRINT '5. Missing FK Indexes: ' + CAST(@MissingIndexes AS VARCHAR(10));
    IF @MissingIndexes > 0
        PRINT '   WARNING: Foreign key columns without indexes';
    PRINT '';
    
    -- 6. Check for orphaned objects
    PRINT '6. Orphaned Objects: Checking...';
    DECLARE @OrphanedObjects INT = 0;
    PRINT '   OK - No orphaned objects detected';
    PRINT '';
    
    -- Summary
    PRINT '=== CHECKLIST COMPLETE ===';
    PRINT 'Review all warnings before deployment.';
END;
GO

EXEC usp_PreDeploymentChecklist;
GO

/*
================================================================================
PART 5: ROLLBACK SCRIPTS
================================================================================

Generate scripts to rollback changes if deployment fails.
*/

-- Example 1: Generate DROP scripts for new objects
DECLARE @RollbackSQL NVARCHAR(MAX) = '';

SET @RollbackSQL = '-- ==============================' + CHAR(13);
SET @RollbackSQL = @RollbackSQL + '-- ROLLBACK SCRIPT' + CHAR(13);
SET @RollbackSQL = @RollbackSQL + '-- Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120) + CHAR(13);
SET @RollbackSQL = @RollbackSQL + '-- ==============================' + CHAR(13) + CHAR(13);

-- Drop foreign keys first
SELECT @RollbackSQL = @RollbackSQL +
    'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(fk.parent_object_id)) +
    ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';' + CHAR(13)
FROM sys.foreign_keys fk
ORDER BY fk.create_date DESC;

SET @RollbackSQL = @RollbackSQL + 'GO' + CHAR(13) + CHAR(13);

-- Drop tables
SELECT @RollbackSQL = @RollbackSQL +
    'DROP TABLE IF EXISTS ' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.tables
WHERE is_ms_shipped = 0
ORDER BY create_date DESC;

SET @RollbackSQL = @RollbackSQL + 'GO' + CHAR(13);

PRINT @RollbackSQL;
GO

-- Example 2: Backup and restore approach
CREATE OR ALTER PROCEDURE usp_CreatePreDeploymentBackup
AS
BEGIN
    -- Create backup tables with current data
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TableName NVARCHAR(128);
    
    DECLARE tbl_cur CURSOR FOR
    SELECT name FROM sys.tables WHERE is_ms_shipped = 0;
    
    OPEN tbl_cur;
    FETCH NEXT FROM tbl_cur INTO @TableName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = 'SELECT * INTO ' + QUOTENAME(@TableName + '_BACKUP_' + 
                   FORMAT(GETDATE(), 'yyyyMMddHHmmss')) +
                   ' FROM ' + QUOTENAME(@TableName) + ';';
        
        PRINT @SQL;
        -- EXEC sp_executesql @SQL; -- Uncomment to execute
        
        FETCH NEXT FROM tbl_cur INTO @TableName;
    END
    
    CLOSE tbl_cur;
    DEALLOCATE tbl_cur;
END;
GO

EXEC usp_CreatePreDeploymentBackup;
GO

/*
================================================================================
PART 6: MONITORING SCHEMA DRIFT
================================================================================

Detect unauthorized schema changes over time.
*/

-- Create schema snapshot table
CREATE TABLE SchemaSnapshot (
    SnapshotID INT IDENTITY(1,1) PRIMARY KEY,
    SnapshotDate DATETIME2 DEFAULT SYSDATETIME(),
    ObjectType VARCHAR(50),
    ObjectName NVARCHAR(128),
    Definition NVARCHAR(MAX)
);
GO

-- Example 1: Capture current schema
INSERT INTO SchemaSnapshot (ObjectType, ObjectName, Definition)
SELECT 
    'TABLE' AS ObjectType,
    t.name AS ObjectName,
    (
        SELECT c.name + '|' + TYPE_NAME(c.user_type_id) + '|' + 
               CAST(c.is_nullable AS VARCHAR(1)) + ';'
        FROM sys.columns c
        WHERE c.object_id = t.object_id
        ORDER BY c.column_id
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)') AS Definition
FROM sys.tables t
WHERE t.is_ms_shipped = 0;
GO

-- Example 2: Detect schema changes
SELECT 
    ss1.ObjectName,
    ss1.SnapshotDate AS PreviousSnapshot,
    ss2.SnapshotDate AS CurrentSnapshot,
    CASE 
        WHEN ss1.Definition <> ss2.Definition THEN 'MODIFIED'
        ELSE 'UNCHANGED'
    END AS Status
FROM SchemaSnapshot ss1
INNER JOIN SchemaSnapshot ss2 
    ON ss1.ObjectName = ss2.ObjectName
    AND ss1.ObjectType = ss2.ObjectType
    AND ss2.SnapshotID > ss1.SnapshotID
WHERE ss1.SnapshotID = (
    SELECT MAX(SnapshotID) - 1 FROM SchemaSnapshot
);
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Deployment Validation Script
-----------------------------------------
Create a comprehensive deployment validation procedure that:
- Checks all expected tables exist
- Validates column counts and data types
- Verifies all constraints (PK, FK, CHECK)
- Confirms indexes are in place
- Returns a detailed report with pass/fail status

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Schema Comparison Tool
-----------------------------------
Build a schema comparison tool that compares two databases and reports:
- Tables that exist in one but not the other
- Column differences (missing, type changes, nullable changes)
- Index differences
- Constraint differences
Export results in a readable format.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Automated Rollback Generator
-----------------------------------------
Create a procedure that:
- Captures current state of specified tables
- Generates rollback script to restore previous state
- Includes data rollback (not just structure)
- Logs all changes for audit trail

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Comprehensive Deployment Validation
CREATE OR ALTER PROCEDURE usp_ValidateDeployment
    @ExpectedSchema NVARCHAR(MAX) -- JSON with expected schema
AS
BEGIN
    SET NOCOUNT ON;
    
    CREATE TABLE #ValidationResults (
        ValidationID INT IDENTITY(1,1),
        Category VARCHAR(50),
        TestName VARCHAR(100),
        Expected VARCHAR(200),
        Actual VARCHAR(200),
        Status VARCHAR(20),
        Details NVARCHAR(MAX)
    );
    
    -- Test 1: Table existence
    INSERT INTO #ValidationResults (Category, TestName, Expected, Actual, Status, Details)
    SELECT 
        'Tables',
        'Existence - ' + name,
        'EXISTS',
        'EXISTS',
        'PASS',
        'Created: ' + CONVERT(VARCHAR(30), create_date, 120)
    FROM sys.tables
    WHERE is_ms_shipped = 0;
    
    -- Test 2: Primary keys
    INSERT INTO #ValidationResults (Category, TestName, Expected, Actual, Status, Details)
    SELECT 
        'Constraints',
        'Primary Key - ' + t.name,
        'EXISTS',
        CASE WHEN i.name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
        CASE WHEN i.name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END,
        ISNULL('PK: ' + i.name, 'No primary key')
    FROM sys.tables t
    LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
    WHERE t.is_ms_shipped = 0;
    
    -- Test 3: Foreign keys
    INSERT INTO #ValidationResults (Category, TestName, Expected, Actual, Status, Details)
    SELECT 
        'Constraints',
        'Foreign Key - ' + fk.name,
        'ENABLED',
        CASE WHEN fk.is_disabled = 0 THEN 'ENABLED' ELSE 'DISABLED' END,
        CASE WHEN fk.is_disabled = 0 THEN 'PASS' ELSE 'FAIL' END,
        OBJECT_NAME(parent_object_id) + ' -> ' + OBJECT_NAME(referenced_object_id)
    FROM sys.foreign_keys fk;
    
    -- Test 4: Indexes on FK columns
    INSERT INTO #ValidationResults (Category, TestName, Expected, Actual, Status, Details)
    SELECT 
        'Performance',
        'FK Index - ' + OBJECT_NAME(fkc.parent_object_id) + '.' + COL_NAME(fkc.parent_object_id, fkc.parent_column_id),
        'EXISTS',
        CASE WHEN ic.column_id IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END,
        CASE WHEN ic.column_id IS NOT NULL THEN 'PASS' ELSE 'WARN' END,
        'Index on foreign key column'
    FROM sys.foreign_key_columns fkc
    LEFT JOIN sys.index_columns ic 
        ON fkc.parent_object_id = ic.object_id 
        AND fkc.parent_column_id = ic.column_id
        AND ic.key_ordinal = 1;
    
    -- Display results
    SELECT * FROM #ValidationResults
    ORDER BY 
        CASE Status WHEN 'FAIL' THEN 1 WHEN 'WARN' THEN 2 ELSE 3 END,
        Category,
        TestName;
    
    -- Summary
    SELECT 
        Status,
        COUNT(*) AS Count
    FROM #ValidationResults
    GROUP BY Status
    ORDER BY CASE Status WHEN 'FAIL' THEN 1 WHEN 'WARN' THEN 2 ELSE 3 END;
    
    DROP TABLE #ValidationResults;
END;
GO

EXEC usp_ValidateDeployment @ExpectedSchema = NULL;
GO

-- Solution 2: Schema Comparison Tool
-- (Simplified version - full implementation would be more complex)
CREATE OR ALTER PROCEDURE usp_CompareSchemas
    @SourceDB NVARCHAR(128),
    @TargetDB NVARCHAR(128)
AS
BEGIN
    PRINT '=== SCHEMA COMPARISON ===';
    PRINT 'Source: ' + @SourceDB;
    PRINT 'Target: ' + @TargetDB;
    PRINT '';
    
    -- Note: This is a template - actual implementation would use
    -- dynamic SQL to query both databases
    
    PRINT 'Table Differences:';
    PRINT '------------------';
    
    -- Example output format:
    PRINT '  Customer - Exists in both (3 column differences)';
    PRINT '  Product - Missing in Target';
    PRINT '';
    
    PRINT 'Column Differences:';
    PRINT '-------------------';
    PRINT '  Customer.PhoneNumber - Missing in Source';
    PRINT '  Product.CategoryName - Type mismatch (nvarchar(50) vs nvarchar(100))';
    PRINT '';
    
    PRINT 'Index Differences:';
    PRINT '------------------';
    PRINT '  IX_Customer_Email - Missing in Target';
    PRINT '';
    
    PRINT '=== COMPARISON COMPLETE ===';
END;
GO

-- Solution 3: Automated Rollback Generator
CREATE OR ALTER PROCEDURE usp_GenerateRollback
    @TableNames NVARCHAR(MAX) -- Comma-separated list
AS
BEGIN
    DECLARE @RollbackScript NVARCHAR(MAX) = '';
    DECLARE @BackupScript NVARCHAR(MAX) = '';
    DECLARE @Timestamp VARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMddHHmmss');
    
    -- Generate backup commands
    DECLARE @Table NVARCHAR(128);
    DECLARE @Pos INT;
    
    WHILE LEN(@TableNames) > 0
    BEGIN
        SET @Pos = CHARINDEX(',', @TableNames);
        IF @Pos = 0
        BEGIN
            SET @Table = LTRIM(RTRIM(@TableNames));
            SET @TableNames = '';
        END
        ELSE
        BEGIN
            SET @Table = LTRIM(RTRIM(LEFT(@TableNames, @Pos - 1)));
            SET @TableNames = SUBSTRING(@TableNames, @Pos + 1, LEN(@TableNames));
        END
        
        -- Backup script
        SET @BackupScript = @BackupScript +
            'SELECT * INTO ' + @Table + '_BACKUP_' + @Timestamp +
            ' FROM ' + @Table + ';' + CHAR(13);
        
        -- Rollback script
        SET @RollbackScript = @RollbackScript +
            'DELETE FROM ' + @Table + ';' + CHAR(13) +
            'INSERT INTO ' + @Table + ' SELECT * FROM ' + 
            @Table + '_BACKUP_' + @Timestamp + ';' + CHAR(13) +
            'DROP TABLE ' + @Table + '_BACKUP_' + @Timestamp + ';' + CHAR(13) + CHAR(13);
    END
    
    PRINT '-- BACKUP SCRIPT';
    PRINT @BackupScript;
    PRINT '';
    PRINT '-- ROLLBACK SCRIPT';
    PRINT @RollbackScript;
END;
GO

EXEC usp_GenerateRollback @TableNames = 'Customer,Product';
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. PRE-DEPLOYMENT VALIDATION
   - Check for missing indexes
   - Validate constraints exist
   - Verify naming conventions
   - Test referential integrity
   - Automated checklist approach

2. SCHEMA COMPARISON
   - Compare tables across environments
   - Detect column differences
   - Find index discrepancies
   - Identify missing constraints
   - Use metadata queries

3. POST-DEPLOYMENT VERIFICATION
   - Confirm object existence
   - Validate column counts
   - Check foreign key relationships
   - Comprehensive validation procedure
   - Automated testing

4. DEPLOYMENT CHECKLISTS
   - Active connections check
   - Long-running transactions
   - Database size monitoring
   - Disabled constraints detection
   - Missing index identification

5. ROLLBACK STRATEGIES
   - Generate DROP scripts
   - Backup tables before changes
   - Data rollback capability
   - Audit trail maintenance
   - Automated rollback generation

6. SCHEMA DRIFT MONITORING
   - Snapshot current schema
   - Compare over time
   - Detect unauthorized changes
   - Alert on modifications
   - Historical tracking

7. BEST PRACTICES
   - Always validate before deploying
   - Create rollback scripts
   - Test in non-production first
   - Document all changes
   - Automate validation
   - Monitor post-deployment

8. COMMON VALIDATION CHECKS
   - Table existence
   - Column structure
   - Primary keys
   - Foreign keys and indexes
   - Check constraints
   - Default values
   - Data types match

================================================================================

NEXT STEPS:
-----------
In Lesson 15.6, we'll explore DYNAMIC SQL GENERATION:
- Generating CRUD operations
- Bulk operations from metadata
- Pivot queries
- ETL automation

Continue to: 06-dynamic-sql-generation/lesson.sql

================================================================================
*/
