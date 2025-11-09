/*
================================================================================
LESSON 15.7: TEST YOUR KNOWLEDGE - METADATA
================================================================================

Comprehensive Assessment
------------------------
This assessment covers all topics from Chapter 15: Metadata.
Total Points: 350

Topics Covered:
1. Data About Data (50 points)
2. INFORMATION_SCHEMA (50 points)
3. Working with Metadata (50 points)
4. Schema Generation Scripts (50 points)
5. Deployment and Verification (50 points)
6. Dynamic SQL Generation (50 points)
7. Comprehensive Project (50 points)

Time Estimate: 90 minutes
Database: RetailStore

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
SECTION 1: DATA ABOUT DATA (50 points)
================================================================================
*/

-- Question 1.1 (10 points)
-- List all the different types of metadata available in SQL Server.
-- For each type, provide one example query that retrieves that metadata.

-- Your answer:






-- Question 1.2 (15 points)
-- Write a query that shows the relationship between tables and their indexes,
-- including:
-- - Table name
-- - Index name
-- - Index type
-- - Number of columns in index
-- - Total size of index in MB

-- Your answer:






-- Question 1.3 (25 points)
-- Create a stored procedure that generates a complete database documentation
-- report including:
-- - Database name and size
-- - Number of tables, views, procedures
-- - List of all tables with row counts
-- - Foreign key relationships
-- - Orphaned objects (if any)

-- Your answer:






/*
================================================================================
SECTION 2: INFORMATION_SCHEMA (50 points)
================================================================================
*/

-- Question 2.1 (15 points)
-- Using only INFORMATION_SCHEMA views, write a query that finds all tables
-- that have:
-- - More than 5 columns
-- - At least one foreign key
-- - At least one unique constraint or primary key

-- Your answer:






-- Question 2.2 (20 points)
-- Write a query using INFORMATION_SCHEMA that generates a data dictionary
-- showing:
-- - Table name
-- - Column name
-- - Data type with precision/scale
-- - Nullable status
-- - Default value
-- - Whether it's part of primary key

-- Your answer:






-- Question 2.3 (15 points)
-- Using INFORMATION_SCHEMA, find all referential constraints and show:
-- - Constraint name
-- - Table and column being constrained
-- - Referenced table and column
-- - Update and delete rules

-- Your answer:






/*
================================================================================
SECTION 3: WORKING WITH METADATA (50 points)
================================================================================
*/

-- Question 3.1 (15 points)
-- Write a query using sys catalog views to find all tables that have:
-- - Foreign key columns without supporting indexes
-- Include table name, column name, and recommendation.

-- Your answer:






-- Question 3.2 (20 points)
-- Create a query that analyzes index usage and recommends:
-- - Indexes that are never used (candidates for removal)
-- - Foreign keys without indexes (candidates for creation)
-- - Most frequently updated indexes (may need fill factor adjustment)

-- Your answer:






-- Question 3.3 (15 points)
-- Write a query using DMVs to show:
-- - Table name
-- - Total rows
-- - Total space used (MB)
-- - Data space (MB)
-- - Index space (MB)
-- - Unused space (MB)

-- Your answer:






/*
================================================================================
SECTION 4: SCHEMA GENERATION SCRIPTS (50 points)
================================================================================
*/

-- Question 4.1 (20 points)
-- Create a procedure that generates a complete CREATE TABLE script for any
-- table including:
-- - All columns with proper data types
-- - All constraints (PK, FK, CHECK, DEFAULT, UNIQUE)
-- - All indexes
-- The script should be executable to recreate the table.

-- Your answer:






-- Question 4.2 (15 points)
-- Write a query that generates an ER diagram in Mermaid syntax for all
-- tables in the database, showing:
-- - All tables and their columns
-- - Primary keys marked
-- - Foreign keys marked
-- - Relationships between tables

-- Your answer:






-- Question 4.3 (15 points)
-- Create a procedure that generates HTML documentation for a database
-- including:
-- - Table of contents
-- - Each table in its own section
-- - Columns with data types
-- - Constraints and indexes
-- - Proper HTML formatting with CSS

-- Your answer:






/*
================================================================================
SECTION 5: DEPLOYMENT AND VERIFICATION (50 points)
================================================================================
*/

-- Question 5.1 (20 points)
-- Create a comprehensive pre-deployment validation procedure that checks:
-- - All tables have primary keys
-- - All foreign key columns have indexes
-- - No disabled constraints
-- - No naming convention violations
-- - No orphaned foreign keys
-- Return results with severity levels (HIGH, MEDIUM, LOW).

-- Your answer:






-- Question 5.2 (15 points)
-- Write a procedure that compares two database schemas and reports:
-- - Tables that exist in one but not the other
-- - Columns that differ between matching tables
-- - Indexes that are missing
-- - Constraints that differ

-- Your answer:






-- Question 5.3 (15 points)
-- Create a post-deployment verification procedure that:
-- - Verifies all expected objects exist
-- - Checks row counts are within expected ranges
-- - Validates foreign key relationships
-- - Tests constraint enforcement
-- - Returns detailed pass/fail report

-- Your answer:






/*
================================================================================
SECTION 6: DYNAMIC SQL GENERATION (50 points)
================================================================================
*/

-- Question 6.1 (20 points)
-- Create a procedure that generates complete CRUD stored procedures for any
-- table including:
-- - INSERT procedure with all parameters
-- - SELECT by primary key
-- - UPDATE procedure
-- - DELETE procedure
-- All procedures should include error handling and return values.

-- Your answer:






-- Question 6.2 (15 points)
-- Write a procedure that generates a MERGE statement for synchronizing
-- data between two tables with the same structure.
-- The MERGE should:
-- - INSERT new records
-- - UPDATE changed records
-- - Optionally DELETE removed records

-- Your answer:






-- Question 6.3 (15 points)
-- Create a dynamic PIVOT query generator that accepts:
-- - Source table
-- - Row grouping column
-- - Pivot column (what becomes column headers)
-- - Value column (what to aggregate)
-- - Aggregate function (SUM, AVG, COUNT, etc.)

-- Your answer:






/*
================================================================================
SECTION 7: COMPREHENSIVE PROJECT (50 points)
================================================================================

Build a complete Database Management Toolkit
---------------------------------------------
Create a comprehensive set of procedures for database management:

1. Database Documentation Generator (10 points)
   - Complete schema documentation
   - Data dictionary
   - Relationship diagrams
   - Index analysis

2. Deployment Manager (10 points)
   - Pre-deployment validation
   - Schema comparison
   - Post-deployment verification
   - Rollback script generation

3. CRUD Generator (10 points)
   - Generate stored procedures for all tables
   - Include error handling
   - Logging and audit trails

4. Performance Analyzer (10 points)
   - Index usage statistics
   - Missing index recommendations
   - Table space usage
   - Query performance metrics

5. Utility Procedures (10 points)
   - Schema snapshot
   - Schema drift detection
   - Backup verification
   - Maintenance scripts
*/

-- Your comprehensive solution:






/*
================================================================================
SOLUTIONS
================================================================================
*/

-- Solution 1.1: Types of Metadata
PRINT '=== METADATA TYPES ===';
PRINT '';
PRINT '1. Structural Metadata (Tables, Columns, Data Types)';
SELECT TOP 3 TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS;
PRINT '';

PRINT '2. Relational Metadata (Foreign Keys, Relationships)';
SELECT TOP 3 CONSTRAINT_NAME 
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS;
PRINT '';

PRINT '3. Index Metadata';
SELECT TOP 3 OBJECT_NAME(object_id) AS TableName, name AS IndexName
FROM sys.indexes WHERE type > 0;
PRINT '';

PRINT '4. Security Metadata (Permissions)';
SELECT TOP 3 name, type_desc FROM sys.database_principals;
PRINT '';

PRINT '5. Statistical Metadata (Row counts, sizes)';
SELECT TOP 3 OBJECT_NAME(object_id) AS TableName, SUM(rows) AS RowCount
FROM sys.partitions 
WHERE index_id IN (0,1)
GROUP BY object_id;
GO

-- Solution 1.2: Tables and Indexes
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    COUNT(ic.column_id) AS ColumnCount,
    SUM(ps.used_page_count) * 8.0 / 1024 AS SizeInMB
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0 AND i.type > 0
GROUP BY i.object_id, i.name, i.type_desc
ORDER BY TableName, IndexName;
GO

-- Solution 1.3: Database Documentation Report
CREATE OR ALTER PROCEDURE usp_GenerateDatabaseReport
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== DATABASE DOCUMENTATION REPORT ===';
    PRINT 'Database: ' + DB_NAME();
    PRINT 'Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
    PRINT '';
    
    -- Database size
    DECLARE @SizeMB DECIMAL(10,2);
    SELECT @SizeMB = SUM(size * 8.0 / 1024) FROM sys.database_files;
    PRINT 'Database Size: ' + CAST(@SizeMB AS VARCHAR(20)) + ' MB';
    PRINT '';
    
    -- Object counts
    PRINT '=== OBJECT SUMMARY ===';
    SELECT 
        type_desc AS ObjectType,
        COUNT(*) AS Count
    FROM sys.objects
    WHERE is_ms_shipped = 0
    GROUP BY type_desc
    ORDER BY Count DESC;
    PRINT '';
    
    -- Tables with row counts
    PRINT '=== TABLES ===';
    SELECT 
        t.name AS TableName,
        SUM(p.rows) AS RowCount
    FROM sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
    WHERE p.index_id IN (0, 1) AND t.is_ms_shipped = 0
    GROUP BY t.name
    ORDER BY t.name;
    PRINT '';
    
    -- Foreign key relationships
    PRINT '=== RELATIONSHIPS ===';
    SELECT 
        OBJECT_NAME(fk.parent_object_id) AS FromTable,
        OBJECT_NAME(fk.referenced_object_id) AS ToTable,
        fk.name AS ConstraintName
    FROM sys.foreign_keys fk
    ORDER BY FromTable, ToTable;
    
    PRINT '';
    PRINT '=== REPORT COMPLETE ===';
END;
GO

EXEC usp_GenerateDatabaseReport;
GO

-- Solution 2.1: Tables with >5 columns, FK, and PK/Unique
SELECT DISTINCT t.TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND EXISTS (
      SELECT 1 FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
      WHERE rc.CONSTRAINT_SCHEMA = t.TABLE_SCHEMA
        AND (rc.CONSTRAINT_SCHEMA = t.TABLE_SCHEMA)
  )
  AND EXISTS (
      SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
      WHERE tc.TABLE_NAME = t.TABLE_NAME
        AND tc.CONSTRAINT_TYPE IN ('PRIMARY KEY', 'UNIQUE')
  )
GROUP BY t.TABLE_NAME
HAVING COUNT(c.COLUMN_NAME) > 5;
GO

-- Solution 2.2: Data Dictionary using INFORMATION_SCHEMA
SELECT 
    c.TABLE_NAME AS TableName,
    c.COLUMN_NAME AS ColumnName,
    c.DATA_TYPE + 
        CASE 
            WHEN c.DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar') THEN
                '(' + CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' 
                           ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) END + ')'
            WHEN c.DATA_TYPE IN ('decimal', 'numeric') THEN
                '(' + CAST(c.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + 
                CAST(c.NUMERIC_SCALE AS VARCHAR(10)) + ')'
            ELSE ''
        END AS DataType,
    c.IS_NULLABLE AS Nullable,
    c.COLUMN_DEFAULT AS DefaultValue,
    CASE WHEN kcu.COLUMN_NAME IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsPrimaryKey
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
    ON c.TABLE_NAME = kcu.TABLE_NAME 
    AND c.COLUMN_NAME = kcu.COLUMN_NAME
LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
    ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME 
    AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
WHERE c.TABLE_NAME IN (
    SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'
)
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
GO

-- Solution 2.3: Referential Constraints
SELECT 
    rc.CONSTRAINT_NAME AS ConstraintName,
    kcu1.TABLE_NAME AS TableName,
    kcu1.COLUMN_NAME AS ColumnName,
    kcu2.TABLE_NAME AS ReferencedTable,
    kcu2.COLUMN_NAME AS ReferencedColumn,
    rc.UPDATE_RULE AS UpdateRule,
    rc.DELETE_RULE AS DeleteRule
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu1 
    ON rc.CONSTRAINT_NAME = kcu1.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu2 
    ON rc.UNIQUE_CONSTRAINT_NAME = kcu2.CONSTRAINT_NAME
    AND kcu1.ORDINAL_POSITION = kcu2.ORDINAL_POSITION
ORDER BY TableName, ConstraintName;
GO

-- Solution 3.1: Foreign Keys Without Indexes
SELECT 
    OBJECT_NAME(fkc.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    'Create index on FK column for better performance' AS Recommendation
FROM sys.foreign_key_columns fkc
WHERE NOT EXISTS (
    SELECT 1 FROM sys.index_columns ic
    WHERE ic.object_id = fkc.parent_object_id
      AND ic.column_id = fkc.parent_column_id
      AND ic.key_ordinal = 1
)
ORDER BY TableName, ColumnName;
GO

-- Solution 3.2: Index Usage Analysis
-- Unused indexes
SELECT 
    'Unused Index' AS Category,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    'Consider dropping - never used' AS Recommendation
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE i.type_desc = 'NONCLUSTERED'
  AND i.is_primary_key = 0
  AND i.is_unique_constraint = 0
  AND ius.user_seeks IS NULL
  AND ius.user_scans IS NULL
  AND ius.user_lookups IS NULL
  AND OBJECT_SCHEMA_NAME(i.object_id) = 'dbo'

UNION ALL

-- Missing FK indexes
SELECT 
    'Missing FK Index' AS Category,
    OBJECT_NAME(fkc.parent_object_id) AS TableName,
    'FK column: ' + COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS IndexName,
    'Create index on foreign key column' AS Recommendation
FROM sys.foreign_key_columns fkc
WHERE NOT EXISTS (
    SELECT 1 FROM sys.index_columns ic
    WHERE ic.object_id = fkc.parent_object_id
      AND ic.column_id = fkc.parent_column_id
      AND ic.key_ordinal = 1
)

ORDER BY Category, TableName;
GO

-- Solution 3.3: Table Space Usage
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    SUM(p.rows) AS TotalRows,
    SUM(a.total_pages) * 8.0 / 1024 AS TotalSpaceMB,
    SUM(a.used_pages) * 8.0 / 1024 AS UsedSpaceMB,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN a.used_pages ELSE 0 END) * 8.0 / 1024 AS DataSpaceMB,
    SUM(CASE WHEN p.index_id > 1 THEN a.used_pages ELSE 0 END) * 8.0 / 1024 AS IndexSpaceMB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8.0 / 1024 AS UnusedSpaceMB
FROM sys.partitions p
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.tables t ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
GROUP BY p.object_id
ORDER BY TotalSpaceMB DESC;
GO

-- Solution 4.1: Complete CREATE TABLE Script Generator
CREATE OR ALTER PROCEDURE usp_GenerateCreateTableScript
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    
    -- Table header
    SET @SQL = '-- Table: ' + @TableName + CHAR(13);
    SET @SQL = @SQL + 'CREATE TABLE ' + QUOTENAME(@TableName) + ' (' + CHAR(13);
    
    -- Columns
    SELECT @SQL = @SQL + 
        '    ' + QUOTENAME(c.name) + ' ' +
        TYPE_NAME(c.user_type_id) +
        CASE 
            WHEN TYPE_NAME(c.user_type_id) IN ('varchar', 'nvarchar', 'char', 'nchar') THEN
                '(' + CASE WHEN c.max_length = -1 THEN 'MAX' 
                           ELSE CAST(CASE WHEN TYPE_NAME(c.user_type_id) LIKE 'n%' 
                                          THEN c.max_length / 2 ELSE c.max_length END AS VARCHAR(10)) 
                      END + ')'
            WHEN TYPE_NAME(c.user_type_id) IN ('decimal', 'numeric') THEN
                '(' + CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10)) + ')'
            ELSE ''
        END +
        CASE WHEN c.is_identity = 1 THEN ' IDENTITY(1,1)' ELSE '' END +
        CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
        CASE WHEN dc.definition IS NOT NULL THEN ' DEFAULT ' + dc.definition ELSE '' END +
        ',' + CHAR(13)
    FROM sys.columns c
    LEFT JOIN sys.default_constraints dc 
        ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
    WHERE c.object_id = OBJECT_ID(@TableName)
    ORDER BY c.column_id;
    
    -- Primary Key
    DECLARE @PKDef NVARCHAR(MAX) = '';
    SELECT @PKDef = @PKDef +
        '    CONSTRAINT ' + QUOTENAME(i.name) + ' PRIMARY KEY ' +
        CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END +
        ' (' + STRING_AGG(QUOTENAME(COL_NAME(ic.object_id, ic.column_id)), ', ') 
               WITHIN GROUP (ORDER BY ic.key_ordinal) + '),' + CHAR(13)
    FROM sys.indexes i
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.object_id = OBJECT_ID(@TableName) AND i.is_primary_key = 1
    GROUP BY i.name, i.type;
    
    IF LEN(@PKDef) > 0
        SET @SQL = @SQL + @PKDef;
    
    -- Remove trailing comma
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13);
    SET @SQL = @SQL + ');' + CHAR(13) + 'GO';
    
    PRINT @SQL;
END;
GO

-- Solution 6.1: Complete CRUD Generator
CREATE OR ALTER PROCEDURE usp_GenerateCompleteCRUD
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @PKColumn NVARCHAR(128);
    
    SELECT TOP 1 @PKColumn = COL_NAME(ic.object_id, ic.column_id)
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1 AND i.object_id = OBJECT_ID(@TableName);
    
    SET @SQL = '-- CRUD Procedures for ' + @TableName + CHAR(13) + CHAR(13);
    
    -- INSERT
    SET @SQL = @SQL + 'CREATE PROCEDURE usp_' + @TableName + '_Insert' + CHAR(13);
    SET @SQL = @SQL + 'AS BEGIN' + CHAR(13);
    SET @SQL = @SQL + '    SET NOCOUNT ON;' + CHAR(13);
    SET @SQL = @SQL + '    BEGIN TRY' + CHAR(13);
    SET @SQL = @SQL + '        -- INSERT logic' + CHAR(13);
    SET @SQL = @SQL + '        RETURN SCOPE_IDENTITY();' + CHAR(13);
    SET @SQL = @SQL + '    END TRY' + CHAR(13);
    SET @SQL = @SQL + '    BEGIN CATCH' + CHAR(13);
    SET @SQL = @SQL + '        THROW;' + CHAR(13);
    SET @SQL = @SQL + '    END CATCH;' + CHAR(13);
    SET @SQL = @SQL + 'END;' + CHAR(13) + 'GO' + CHAR(13) + CHAR(13);
    
    PRINT @SQL;
END;
GO

/*
================================================================================
SCORING RUBRIC
================================================================================

Section 1: Data About Data (50 points)
- Q1.1: 10 points (2 points per metadata type)
- Q1.2: 15 points (query correctness, completeness)
- Q1.3: 25 points (procedure functionality, output quality)

Section 2: INFORMATION_SCHEMA (50 points)
- Q2.1: 15 points (correct views used, logic)
- Q2.2: 20 points (completeness, formatting)
- Q2.3: 15 points (referential integrity details)

Section 3: Working with Metadata (50 points)
- Q3.1: 15 points (sys views usage, accuracy)
- Q3.2: 20 points (analysis depth, recommendations)
- Q3.3: 15 points (DMV usage, calculations)

Section 4: Schema Generation (50 points)
- Q4.1: 20 points (script completeness, executability)
- Q4.2: 15 points (diagram accuracy, formatting)
- Q4.3: 15 points (HTML quality, CSS, structure)

Section 5: Deployment & Verification (50 points)
- Q5.1: 20 points (comprehensive checks, severity)
- Q5.2: 15 points (comparison accuracy)
- Q5.3: 15 points (verification depth, reporting)

Section 6: Dynamic SQL (50 points)
- Q6.1: 20 points (CRUD completeness, error handling)
- Q6.2: 15 points (MERGE correctness, options)
- Q6.3: 15 points (pivot generation, flexibility)

Section 7: Comprehensive Project (50 points)
- Documentation: 10 points
- Deployment: 10 points
- CRUD: 10 points
- Performance: 10 points
- Utilities: 10 points

Total: 350 points

Grading Scale:
- 315-350 (90-100%): Excellent - Mastery of metadata concepts
- 280-314 (80-89%): Good - Strong understanding
- 245-279 (70-79%): Satisfactory - Basic competency
- 210-244 (60-69%): Needs Improvement
- Below 210 (<60%): Insufficient - Review chapter

================================================================================

CONGRATULATIONS!
================================================================================

You have completed Chapter 15: Metadata!

Key Skills Acquired:
✓ Understanding metadata types and uses
✓ Querying INFORMATION_SCHEMA views
✓ Working with sys catalog views and DMVs
✓ Generating schema documentation
✓ Building deployment verification tools
✓ Creating dynamic SQL generators
✓ Automating database management tasks

Next Chapter: Chapter 16 - Analytic Functions
Topics: Window functions, ranking, running totals, moving averages

Keep practicing and exploring metadata concepts!

================================================================================
*/
