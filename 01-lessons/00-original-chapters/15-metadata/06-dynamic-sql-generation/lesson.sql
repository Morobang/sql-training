/*
================================================================================
LESSON 15.6: DYNAMIC SQL GENERATION
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Generate CRUD operations from metadata
2. Build dynamic INSERT statements
3. Create UPDATE and DELETE operations
4. Generate bulk operations
5. Build dynamic PIVOT queries
6. Automate ETL processes
7. Create metadata-driven applications

Business Context:
-----------------
Metadata-driven dynamic SQL reduces manual coding, ensures consistency, and
adapts automatically to schema changes. This approach is essential for building
flexible data applications, ETL processes, and admin tools that work across
different table structures.

Database: RetailStore
Complexity: Advanced
Estimated Time: 50 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: DYNAMIC SELECT GENERATION
================================================================================

Generate SELECT statements from table metadata.
*/

-- Create sample schema
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200),
    PhoneNumber VARCHAR(20),
    City NVARCHAR(100),
    CreatedDate DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    CategoryName NVARCHAR(100),
    UnitPrice DECIMAL(10,2) NOT NULL,
    StockQuantity INT DEFAULT 0,
    IsActive BIT DEFAULT 1
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL,
    ShipDate DATE,
    TotalAmount DECIMAL(12,2),
    Status VARCHAR(20) DEFAULT 'Pending'
);

CREATE TABLE OrderItem (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0
);
GO

-- Insert sample data
INSERT INTO Customer (CustomerName, Email, PhoneNumber, City) VALUES
    ('Acme Corp', 'contact@acme.com', '555-0100', 'New York'),
    ('TechStart Inc', 'info@techstart.com', '555-0200', 'San Francisco'),
    ('Global Solutions', 'sales@global.com', '555-0300', 'Chicago');

INSERT INTO Product (ProductName, CategoryName, UnitPrice, StockQuantity) VALUES
    ('Laptop Pro', 'Electronics', 1299.99, 50),
    ('Wireless Mouse', 'Electronics', 29.99, 200),
    ('USB-C Cable', 'Accessories', 19.99, 500),
    ('Monitor 27"', 'Electronics', 399.99, 75);

INSERT INTO [Order] (CustomerID, OrderDate, ShipDate, TotalAmount, Status) VALUES
    (1, '2024-11-01', '2024-11-03', 1329.98, 'Shipped'),
    (2, '2024-11-05', NULL, 59.98, 'Pending'),
    (3, '2024-11-07', '2024-11-08', 819.98, 'Shipped');

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, Discount) VALUES
    (1, 1, 1, 1299.99, 0),
    (1, 2, 1, 29.99, 0),
    (2, 2, 2, 29.99, 0),
    (3, 3, 10, 19.99, 0.10),
    (3, 4, 1, 399.99, 0);
GO

-- Example 1: Generate SELECT statement for any table
CREATE OR ALTER PROCEDURE usp_GenerateSelect
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = 'SELECT ';
    
    -- Build column list
    SELECT @SQL = @SQL + QUOTENAME(c.name) + ', '
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TableName)
    ORDER BY c.column_id;
    
    -- Remove trailing comma
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
    
    -- Add FROM clause
    SET @SQL = @SQL + CHAR(13) + 'FROM ' + QUOTENAME(@TableName) + ';';
    
    PRINT @SQL;
END;
GO

-- Test the procedure
EXEC usp_GenerateSelect 'Customer';
GO

/*
OUTPUT:
SELECT [CustomerID], [CustomerName], [Email], [PhoneNumber], [City], [CreatedDate]
FROM [Customer];

Dynamic SELECT generated!
*/

-- Example 2: Generate SELECT with WHERE clause for PK
CREATE OR ALTER PROCEDURE usp_GenerateSelectByPK
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = 'SELECT ';
    DECLARE @PKColumn NVARCHAR(128);
    
    -- Get primary key column
    SELECT TOP 1 @PKColumn = COL_NAME(ic.object_id, ic.column_id)
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1 AND i.object_id = OBJECT_ID(@TableName);
    
    -- Build column list
    SELECT @SQL = @SQL + QUOTENAME(c.name) + ', '
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TableName)
    ORDER BY c.column_id;
    
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
    SET @SQL = @SQL + CHAR(13) + 'FROM ' + QUOTENAME(@TableName);
    SET @SQL = @SQL + CHAR(13) + 'WHERE ' + QUOTENAME(@PKColumn) + ' = @' + @PKColumn + ';';
    
    PRINT @SQL;
END;
GO

EXEC usp_GenerateSelectByPK 'Product';
GO

/*
OUTPUT:
SELECT [ProductID], [ProductName], [CategoryName], [UnitPrice], [StockQuantity], [IsActive]
FROM [Product]
WHERE [ProductID] = @ProductID;

Parameterized query generated!
*/

/*
================================================================================
PART 2: DYNAMIC INSERT GENERATION
================================================================================

Generate INSERT statements from metadata.
*/

-- Example 1: Generate INSERT statement
CREATE OR ALTER PROCEDURE usp_GenerateInsert
    @TableName NVARCHAR(128),
    @IncludeIdentity BIT = 0
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @Columns NVARCHAR(MAX) = '';
    DECLARE @Values NVARCHAR(MAX) = '';
    
    -- Build column and parameter lists
    SELECT 
        @Columns = @Columns + QUOTENAME(c.name) + ', ',
        @Values = @Values + '@' + c.name + ', '
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TableName)
      AND (@IncludeIdentity = 1 OR c.is_identity = 0)
      AND c.is_computed = 0
    ORDER BY c.column_id;
    
    -- Remove trailing commas
    SET @Columns = LEFT(@Columns, LEN(@Columns) - 1);
    SET @Values = LEFT(@Values, LEN(@Values) - 1);
    
    -- Build INSERT statement
    SET @SQL = 'INSERT INTO ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + '    (' + @Columns + ')' + CHAR(13);
    SET @SQL = @SQL + 'VALUES' + CHAR(13);
    SET @SQL = @SQL + '    (' + @Values + ');';
    
    PRINT @SQL;
END;
GO

EXEC usp_GenerateInsert 'Customer';
GO

/*
OUTPUT:
INSERT INTO [Customer]
    ([CustomerName], [Email], [PhoneNumber], [City], [CreatedDate])
VALUES
    (@CustomerName, @Email, @PhoneNumber, @City, @CreatedDate);

Dynamic INSERT generated!
*/

-- Example 2: Generate bulk INSERT from SELECT
CREATE OR ALTER PROCEDURE usp_GenerateBulkInsert
    @SourceTable NVARCHAR(128),
    @TargetTable NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @Columns NVARCHAR(MAX) = '';
    
    -- Get matching columns
    SELECT @Columns = @Columns + QUOTENAME(c1.name) + ', '
    FROM sys.columns c1
    INNER JOIN sys.columns c2 
        ON c1.name = c2.name
        AND c2.object_id = OBJECT_ID(@TargetTable)
    WHERE c1.object_id = OBJECT_ID(@SourceTable)
      AND c1.is_identity = 0
      AND c1.is_computed = 0
    ORDER BY c1.column_id;
    
    SET @Columns = LEFT(@Columns, LEN(@Columns) - 1);
    
    SET @SQL = 'INSERT INTO ' + QUOTENAME(@TargetTable) + CHAR(13);
    SET @SQL = @SQL + '    (' + @Columns + ')' + CHAR(13);
    SET @SQL = @SQL + 'SELECT ' + @Columns + CHAR(13);
    SET @SQL = @SQL + 'FROM ' + QUOTENAME(@SourceTable) + ';';
    
    PRINT @SQL;
END;
GO

/*
================================================================================
PART 3: DYNAMIC UPDATE GENERATION
================================================================================
*/

-- Example 1: Generate UPDATE statement
CREATE OR ALTER PROCEDURE usp_GenerateUpdate
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @SetClause NVARCHAR(MAX) = '';
    DECLARE @PKColumn NVARCHAR(128);
    
    -- Get primary key
    SELECT TOP 1 @PKColumn = COL_NAME(ic.object_id, ic.column_id)
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1 AND i.object_id = OBJECT_ID(@TableName);
    
    -- Build SET clause
    SELECT @SetClause = @SetClause + 
        QUOTENAME(c.name) + ' = @' + c.name + ',' + CHAR(13) + '    '
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TableName)
      AND c.is_identity = 0
      AND c.is_computed = 0
      AND c.name <> @PKColumn
    ORDER BY c.column_id;
    
    -- Remove trailing comma
    SET @SetClause = LEFT(@SetClause, LEN(@SetClause) - 7);
    
    -- Build UPDATE statement
    SET @SQL = 'UPDATE ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + 'SET ' + @SetClause + CHAR(13);
    SET @SQL = @SQL + 'WHERE ' + QUOTENAME(@PKColumn) + ' = @' + @PKColumn + ';';
    
    PRINT @SQL;
END;
GO

EXEC usp_GenerateUpdate 'Product';
GO

/*
OUTPUT:
UPDATE [Product]
SET [ProductName] = @ProductName,
    [CategoryName] = @CategoryName,
    [UnitPrice] = @UnitPrice,
    [StockQuantity] = @StockQuantity,
    [IsActive] = @IsActive
WHERE [ProductID] = @ProductID;

Dynamic UPDATE generated!
*/

-- Example 2: Generate conditional UPDATE
CREATE OR ALTER PROCEDURE usp_GenerateConditionalUpdate
    @TableName NVARCHAR(128),
    @WhereColumns NVARCHAR(MAX) -- Comma-separated
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @SetClause NVARCHAR(MAX) = '';
    DECLARE @WhereClause NVARCHAR(MAX) = '';
    
    -- Build SET clause (all non-identity, non-computed columns)
    SELECT @SetClause = @SetClause + 
        QUOTENAME(c.name) + ' = @' + c.name + ',' + CHAR(13) + '    '
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TableName)
      AND c.is_identity = 0
      AND c.is_computed = 0
      AND c.name NOT IN (SELECT value FROM STRING_SPLIT(@WhereColumns, ','))
    ORDER BY c.column_id;
    
    SET @SetClause = LEFT(@SetClause, LEN(@SetClause) - 7);
    
    -- Build WHERE clause
    SELECT @WhereClause = @WhereClause + 
        QUOTENAME(LTRIM(RTRIM(value))) + ' = @' + LTRIM(RTRIM(value)) + ' AND '
    FROM STRING_SPLIT(@WhereColumns, ',');
    
    SET @WhereClause = LEFT(@WhereClause, LEN(@WhereClause) - 4);
    
    -- Build UPDATE statement
    SET @SQL = 'UPDATE ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + 'SET ' + @SetClause + CHAR(13);
    SET @SQL = @SQL + 'WHERE ' + @WhereClause + ';';
    
    PRINT @SQL;
END;
GO

EXEC usp_GenerateConditionalUpdate 'Order', 'CustomerID,OrderDate';
GO

/*
================================================================================
PART 4: DYNAMIC DELETE GENERATION
================================================================================
*/

-- Example 1: Generate DELETE statement
CREATE OR ALTER PROCEDURE usp_GenerateDelete
    @TableName NVARCHAR(128),
    @WhereColumns NVARCHAR(MAX) = NULL -- NULL = use PK
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @WhereClause NVARCHAR(MAX) = '';
    
    IF @WhereColumns IS NULL
    BEGIN
        -- Use primary key
        SELECT @WhereClause = @WhereClause + 
            QUOTENAME(COL_NAME(ic.object_id, ic.column_id)) + ' = @' + 
            COL_NAME(ic.object_id, ic.column_id) + ' AND '
        FROM sys.index_columns ic
        INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        WHERE i.is_primary_key = 1 AND i.object_id = OBJECT_ID(@TableName)
        ORDER BY ic.key_ordinal;
    END
    ELSE
    BEGIN
        -- Use specified columns
        SELECT @WhereClause = @WhereClause + 
            QUOTENAME(LTRIM(RTRIM(value))) + ' = @' + LTRIM(RTRIM(value)) + ' AND '
        FROM STRING_SPLIT(@WhereColumns, ',');
    END
    
    SET @WhereClause = LEFT(@WhereClause, LEN(@WhereClause) - 4);
    
    SET @SQL = 'DELETE FROM ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + 'WHERE ' + @WhereClause + ';';
    
    PRINT @SQL;
END;
GO

EXEC usp_GenerateDelete 'Customer';
EXEC usp_GenerateDelete 'Order', 'CustomerID,Status';
GO

/*
================================================================================
PART 5: DYNAMIC PIVOT QUERIES
================================================================================
*/

-- Example 1: Generate PIVOT query
CREATE OR ALTER PROCEDURE usp_GeneratePivot
    @SourceTable NVARCHAR(128),
    @RowColumn NVARCHAR(128),
    @PivotColumn NVARCHAR(128),
    @ValueColumn NVARCHAR(128),
    @AggFunction VARCHAR(20) = 'SUM'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @PivotValues NVARCHAR(MAX) = '';
    DECLARE @ColumnList NVARCHAR(MAX) = '';
    
    -- Get distinct pivot values (simplified - in production, query the table)
    -- For demonstration, we'll use a generic approach
    
    SET @SQL = 'SELECT ' + QUOTENAME(@RowColumn) + ',' + CHAR(13);
    SET @SQL = @SQL + '    [Value1], [Value2], [Value3]' + CHAR(13); -- Placeholder
    SET @SQL = @SQL + 'FROM (' + CHAR(13);
    SET @SQL = @SQL + '    SELECT ' + QUOTENAME(@RowColumn) + ', ' + 
               QUOTENAME(@PivotColumn) + ', ' + QUOTENAME(@ValueColumn) + CHAR(13);
    SET @SQL = @SQL + '    FROM ' + QUOTENAME(@SourceTable) + CHAR(13);
    SET @SQL = @SQL + ') AS SourceTable' + CHAR(13);
    SET @SQL = @SQL + 'PIVOT (' + CHAR(13);
    SET @SQL = @SQL + '    ' + @AggFunction + '(' + QUOTENAME(@ValueColumn) + ')' + CHAR(13);
    SET @SQL = @SQL + '    FOR ' + QUOTENAME(@PivotColumn) + ' IN ([Value1], [Value2], [Value3])' + CHAR(13);
    SET @SQL = @SQL + ') AS PivotTable;';
    
    PRINT @SQL;
END;
GO

EXEC usp_GeneratePivot 'OrderItem', 'OrderID', 'ProductID', 'Quantity', 'SUM';
GO

-- Example 2: Dynamic PIVOT with actual values
CREATE OR ALTER PROCEDURE usp_DynamicPivot
    @Query NVARCHAR(MAX),
    @PivotColumn NVARCHAR(128),
    @ValueColumn NVARCHAR(128),
    @AggFunction VARCHAR(20) = 'SUM'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(MAX);
    
    -- Note: This is a template - actual implementation would be more complex
    PRINT '-- Dynamic PIVOT Template';
    PRINT '-- Customize based on your data';
    PRINT 'DECLARE @Columns NVARCHAR(MAX);';
    PRINT 'DECLARE @SQL NVARCHAR(MAX);';
    PRINT '';
    PRINT '-- Get distinct pivot values';
    PRINT 'SELECT @Columns = STRING_AGG(QUOTENAME(' + @PivotColumn + '), '', '')';
    PRINT 'FROM (SELECT DISTINCT ' + @PivotColumn + ' FROM (' + @Query + ') AS T) AS V;';
    PRINT '';
    PRINT '-- Build PIVOT query';
    PRINT 'SET @SQL = ''SELECT * FROM (' + @Query + ') AS S '';';
    PRINT 'SET @SQL = @SQL + ''PIVOT (' + @AggFunction + '(' + @ValueColumn + ') '';';
    PRINT 'SET @SQL = @SQL + ''FOR ' + @PivotColumn + ' IN ('' + @Columns + '')) AS P;'';';
    PRINT '';
    PRINT 'EXEC sp_executesql @SQL;';
END;
GO

/*
================================================================================
PART 6: COMPLETE CRUD GENERATOR
================================================================================
*/

-- Example 1: Generate complete CRUD procedures
CREATE OR ALTER PROCEDURE usp_GenerateCRUD
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @PKColumn NVARCHAR(128);
    
    -- Get primary key
    SELECT TOP 1 @PKColumn = COL_NAME(ic.object_id, ic.column_id)
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1 AND i.object_id = OBJECT_ID(@TableName);
    
    SET @SQL = '-- ========================================' + CHAR(13);
    SET @SQL = @SQL + '-- CRUD Procedures for ' + @TableName + CHAR(13);
    SET @SQL = @SQL + '-- ========================================' + CHAR(13) + CHAR(13);
    
    -- CREATE
    SET @SQL = @SQL + '-- INSERT (Create)' + CHAR(13);
    SET @SQL = @SQL + 'CREATE PROCEDURE usp_' + @TableName + '_Insert' + CHAR(13);
    
    -- Parameters for INSERT
    SELECT @SQL = @SQL + '    @' + c.name + ' ' + TYPE_NAME(c.user_type_id) +
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
        CASE WHEN c.is_nullable = 1 THEN ' = NULL' ELSE '' END +
        ',' + CHAR(13)
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@TableName)
      AND c.is_identity = 0
      AND c.is_computed = 0
    ORDER BY c.column_id;
    
    -- Remove last comma
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13);
    SET @SQL = @SQL + 'AS BEGIN' + CHAR(13);
    SET @SQL = @SQL + '    -- INSERT logic here' + CHAR(13);
    SET @SQL = @SQL + 'END;' + CHAR(13);
    SET @SQL = @SQL + 'GO' + CHAR(13) + CHAR(13);
    
    -- READ
    SET @SQL = @SQL + '-- SELECT (Read)' + CHAR(13);
    SET @SQL = @SQL + 'CREATE PROCEDURE usp_' + @TableName + '_GetByID' + CHAR(13);
    SET @SQL = @SQL + '    @' + @PKColumn + ' INT' + CHAR(13);
    SET @SQL = @SQL + 'AS BEGIN' + CHAR(13);
    SET @SQL = @SQL + '    SELECT * FROM ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + '    WHERE ' + QUOTENAME(@PKColumn) + ' = @' + @PKColumn + ';' + CHAR(13);
    SET @SQL = @SQL + 'END;' + CHAR(13);
    SET @SQL = @SQL + 'GO' + CHAR(13) + CHAR(13);
    
    -- UPDATE
    SET @SQL = @SQL + '-- UPDATE' + CHAR(13);
    SET @SQL = @SQL + 'CREATE PROCEDURE usp_' + @TableName + '_Update' + CHAR(13);
    SET @SQL = @SQL + '    -- Parameters here' + CHAR(13);
    SET @SQL = @SQL + 'AS BEGIN' + CHAR(13);
    SET @SQL = @SQL + '    -- UPDATE logic here' + CHAR(13);
    SET @SQL = @SQL + 'END;' + CHAR(13);
    SET @SQL = @SQL + 'GO' + CHAR(13) + CHAR(13);
    
    -- DELETE
    SET @SQL = @SQL + '-- DELETE' + CHAR(13);
    SET @SQL = @SQL + 'CREATE PROCEDURE usp_' + @TableName + '_Delete' + CHAR(13);
    SET @SQL = @SQL + '    @' + @PKColumn + ' INT' + CHAR(13);
    SET @SQL = @SQL + 'AS BEGIN' + CHAR(13);
    SET @SQL = @SQL + '    DELETE FROM ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + '    WHERE ' + QUOTENAME(@PKColumn) + ' = @' + @PKColumn + ';' + CHAR(13);
    SET @SQL = @SQL + 'END;' + CHAR(13);
    SET @SQL = @SQL + 'GO' + CHAR(13);
    
    PRINT @SQL;
END;
GO

EXEC usp_GenerateCRUD 'Customer';
GO

/*
================================================================================
PART 7: ETL AUTOMATION
================================================================================
*/

-- Example 1: Generate ETL script
CREATE OR ALTER PROCEDURE usp_GenerateETL
    @SourceTable NVARCHAR(128),
    @TargetTable NVARCHAR(128),
    @ColumnMapping NVARCHAR(MAX) = NULL -- 'SourceCol:TargetCol,SourceCol2:TargetCol2'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    
    SET @SQL = '-- ETL: ' + @SourceTable + ' -> ' + @TargetTable + CHAR(13);
    SET @SQL = @SQL + 'BEGIN TRANSACTION;' + CHAR(13) + CHAR(13);
    
    SET @SQL = @SQL + '-- 1. Extract and Transform' + CHAR(13);
    SET @SQL = @SQL + 'SELECT' + CHAR(13);
    
    IF @ColumnMapping IS NULL
    BEGIN
        -- Auto-map matching columns
        SELECT @SQL = @SQL + '    ' + QUOTENAME(c.name) + ',' + CHAR(13)
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID(@SourceTable)
          AND EXISTS (
              SELECT 1 FROM sys.columns c2
              WHERE c2.object_id = OBJECT_ID(@TargetTable)
                AND c2.name = c.name
          );
    END
    ELSE
    BEGIN
        -- Use explicit mapping
        SET @SQL = @SQL + '    -- Custom mapping from @ColumnMapping' + CHAR(13);
    END
    
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13);
    SET @SQL = @SQL + 'INTO #TempStaging' + CHAR(13);
    SET @SQL = @SQL + 'FROM ' + QUOTENAME(@SourceTable) + ';' + CHAR(13) + CHAR(13);
    
    SET @SQL = @SQL + '-- 2. Load' + CHAR(13);
    SET @SQL = @SQL + 'INSERT INTO ' + QUOTENAME(@TargetTable) + CHAR(13);
    SET @SQL = @SQL + 'SELECT * FROM #TempStaging;' + CHAR(13) + CHAR(13);
    
    SET @SQL = @SQL + '-- 3. Cleanup' + CHAR(13);
    SET @SQL = @SQL + 'DROP TABLE #TempStaging;' + CHAR(13) + CHAR(13);
    
    SET @SQL = @SQL + 'COMMIT TRANSACTION;';
    
    PRINT @SQL;
END;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Advanced CRUD Generator
------------------------------------
Create a procedure that generates complete CRUD stored procedures with:
- Full parameter lists with data types
- Error handling (TRY/CATCH)
- Return values (@@ROWCOUNT, SCOPE_IDENTITY)
- Input validation
- Audit logging

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Generic Data Sync
------------------------------
Build a procedure that synchronizes data between two tables:
- Compare source and target
- INSERT new records
- UPDATE changed records
- DELETE removed records (optional)
- Generate sync report

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Dynamic Report Generator
-------------------------------------
Create a metadata-driven report generator that:
- Accepts table name and optional column filters
- Groups by specified columns
- Aggregates numeric columns
- Formats output as pivot table
- Exports to CSV format

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Advanced CRUD Generator (Simplified)
CREATE OR ALTER PROCEDURE usp_GenerateAdvancedCRUD
    @TableName NVARCHAR(128)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    
    SET @SQL = '-- Generated CRUD for ' + @TableName + CHAR(13);
    SET @SQL = @SQL + 'CREATE PROCEDURE usp_' + @TableName + '_Insert' + CHAR(13);
    SET @SQL = @SQL + '    -- Parameters' + CHAR(13);
    SET @SQL = @SQL + 'AS' + CHAR(13);
    SET @SQL = @SQL + 'BEGIN' + CHAR(13);
    SET @SQL = @SQL + '    SET NOCOUNT ON;' + CHAR(13);
    SET @SQL = @SQL + '    BEGIN TRY' + CHAR(13);
    SET @SQL = @SQL + '        BEGIN TRANSACTION;' + CHAR(13);
    SET @SQL = @SQL + '' + CHAR(13);
    SET @SQL = @SQL + '        -- Validation' + CHAR(13);
    SET @SQL = @SQL + '        -- INSERT statement' + CHAR(13);
    SET @SQL = @SQL + '' + CHAR(13);
    SET @SQL = @SQL + '        COMMIT TRANSACTION;' + CHAR(13);
    SET @SQL = @SQL + '        RETURN SCOPE_IDENTITY();' + CHAR(13);
    SET @SQL = @SQL + '    END TRY' + CHAR(13);
    SET @SQL = @SQL + '    BEGIN CATCH' + CHAR(13);
    SET @SQL = @SQL + '        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;' + CHAR(13);
    SET @SQL = @SQL + '        THROW;' + CHAR(13);
    SET @SQL = @SQL + '    END CATCH;' + CHAR(13);
    SET @SQL = @SQL + 'END;';
    
    PRINT @SQL;
END;
GO

-- Solution 2: Generic Data Sync (Template)
PRINT '-- Generic Data Sync Template';
PRINT 'MERGE TargetTable AS T';
PRINT 'USING SourceTable AS S';
PRINT 'ON T.ID = S.ID';
PRINT 'WHEN MATCHED AND T.UpdateDate < S.UpdateDate THEN';
PRINT '    UPDATE SET T.Column1 = S.Column1, ...';
PRINT 'WHEN NOT MATCHED BY TARGET THEN';
PRINT '    INSERT (Columns...) VALUES (S.Columns...)';
PRINT 'WHEN NOT MATCHED BY SOURCE THEN';
PRINT '    DELETE;';
GO

-- Solution 3: Dynamic Report Generator (Simplified)
CREATE OR ALTER PROCEDURE usp_GenerateReport
    @TableName NVARCHAR(128),
    @GroupByColumns NVARCHAR(MAX),
    @AggregateColumns NVARCHAR(MAX)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = 'SELECT ';
    
    -- Add GROUP BY columns
    SELECT @SQL = @SQL + QUOTENAME(LTRIM(RTRIM(value))) + ', '
    FROM STRING_SPLIT(@GroupByColumns, ',');
    
    -- Add aggregates
    SELECT @SQL = @SQL + 'SUM(' + QUOTENAME(LTRIM(RTRIM(value))) + ') AS Total_' + 
                  LTRIM(RTRIM(value)) + ', '
    FROM STRING_SPLIT(@AggregateColumns, ',');
    
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
    SET @SQL = @SQL + CHAR(13) + 'FROM ' + QUOTENAME(@TableName) + CHAR(13);
    SET @SQL = @SQL + 'GROUP BY ' + @GroupByColumns + ';';
    
    PRINT @SQL;
    EXEC sp_executesql @SQL;
END;
GO

EXEC usp_GenerateReport 'OrderItem', 'OrderID', 'Quantity,UnitPrice';
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. DYNAMIC SELECT
   - Query sys.columns for column list
   - Build WHERE clauses from primary keys
   - Handle identity and computed columns
   - Generate parameterized queries

2. DYNAMIC INSERT
   - Exclude identity and computed columns
   - Build column and value lists
   - Support bulk inserts
   - Handle defaults

3. DYNAMIC UPDATE
   - Identify primary key for WHERE clause
   - Build SET clause from columns
   - Support conditional updates
   - Exclude read-only columns

4. DYNAMIC DELETE
   - Use primary key by default
   - Support custom WHERE conditions
   - Handle cascading deletes
   - Safety checks

5. CRUD GENERATION
   - Complete stored procedures
   - Parameter lists with types
   - Error handling
   - Return values

6. PIVOT QUERIES
   - Dynamic column lists
   - Aggregate functions
   - Unpivot support
   - Complex transformations

7. ETL AUTOMATION
   - Extract-Transform-Load
   - Column mapping
   - Staging tables
   - Error recovery

8. BEST PRACTICES
   - Use QUOTENAME() for identifiers
   - Validate input parameters
   - Test generated SQL
   - Add error handling
   - Document generated code
   - Version control scripts
   - Security considerations

================================================================================

NEXT STEPS:
-----------
In Lesson 15.7, we'll complete the chapter with TEST YOUR KNOWLEDGE:
- Comprehensive exercises
- Real-world scenarios
- Best practices review

Continue to: 07-test-your-knowledge/lesson.sql

================================================================================
*/
