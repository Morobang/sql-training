/*
================================================================================
LESSON 15.4: SCHEMA GENERATION SCRIPTS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Generate CREATE TABLE scripts from metadata
2. Build data dictionaries automatically
3. Create documentation from database schema
4. Generate ER diagram data
5. Reverse engineer database schemas
6. Automate schema export
7. Build schema comparison tools

Business Context:
-----------------
Automating schema documentation and script generation saves time, ensures
accuracy, and enables version control of database structures. These techniques
are essential for database migrations, documentation, and disaster recovery.

Database: RetailStore
Complexity: Advanced
Estimated Time: 50 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: GENERATE CREATE TABLE SCRIPTS
================================================================================

Build CREATE TABLE statements from metadata for backup and version control.
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
    Email NVARCHAR(200) UNIQUE,
    PhoneNumber VARCHAR(20),
    CreatedDate DATETIME2 DEFAULT SYSDATETIME(),
    IsActive BIT DEFAULT 1
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    CategoryName NVARCHAR(100),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0),
    ReorderLevel INT DEFAULT 10
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ShipDate DATE,
    TotalAmount DECIMAL(12,2),
    Status VARCHAR(20) DEFAULT 'Pending',
    CONSTRAINT CHK_ShipDate CHECK (ShipDate >= OrderDate OR ShipDate IS NULL)
);

CREATE TABLE OrderItem (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED
);
GO

-- Create indexes
CREATE INDEX IX_Customer_Email ON Customer(Email);
CREATE INDEX IX_Product_Category ON Product(CategoryName);
CREATE INDEX IX_Order_Date ON [Order](OrderDate) INCLUDE (TotalAmount, Status);
CREATE INDEX IX_Order_Customer ON [Order](CustomerID, OrderDate);
GO

-- Insert sample data
INSERT INTO Customer (CustomerName, Email, PhoneNumber) VALUES
    ('Acme Corporation', 'contact@acme.com', '555-0100'),
    ('TechStart Inc', 'info@techstart.com', '555-0200'),
    ('Global Solutions', 'sales@global.com', '555-0300');

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

-- Example 1: Generate CREATE TABLE script for a single table
DECLARE @TableName NVARCHAR(128) = 'Customer';
DECLARE @SQL NVARCHAR(MAX) = '';

-- Start table creation
SET @SQL = 'CREATE TABLE ' + QUOTENAME(@TableName) + ' (' + CHAR(13);

-- Add columns
SELECT @SQL = @SQL + 
    '    ' + QUOTENAME(c.name) + ' ' +
    TYPE_NAME(c.user_type_id) +
    CASE 
        WHEN TYPE_NAME(c.user_type_id) IN ('varchar', 'nvarchar', 'char', 'nchar') THEN
            '(' + CASE WHEN c.max_length = -1 THEN 'MAX' 
                       ELSE CAST(CASE WHEN TYPE_NAME(c.user_type_id) LIKE 'n%' 
                                      THEN c.max_length / 2 
                                      ELSE c.max_length END AS VARCHAR(10)) 
                  END + ')'
        WHEN TYPE_NAME(c.user_type_id) IN ('decimal', 'numeric') THEN
            '(' + CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10)) + ')'
        WHEN TYPE_NAME(c.user_type_id) IN ('time', 'datetime2', 'datetimeoffset') THEN
            '(' + CAST(c.scale AS VARCHAR(10)) + ')'
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

-- Remove last comma
SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13);

-- Add constraints
DECLARE @Constraints NVARCHAR(MAX) = '';

-- Primary Key
SELECT @Constraints = @Constraints +
    '    CONSTRAINT ' + QUOTENAME(i.name) + ' PRIMARY KEY ' +
    CASE WHEN i.type = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END +
    ' (' + STRING_AGG(QUOTENAME(COL_NAME(ic.object_id, ic.column_id)), ', ') 
           WITHIN GROUP (ORDER BY ic.key_ordinal) + '),' + CHAR(13)
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID(@TableName) AND i.is_primary_key = 1
GROUP BY i.name, i.type;

-- Foreign Keys
SELECT @Constraints = @Constraints +
    '    CONSTRAINT ' + QUOTENAME(fk.name) + ' FOREIGN KEY (' +
    QUOTENAME(COL_NAME(fkc.parent_object_id, fkc.parent_column_id)) + ') ' +
    'REFERENCES ' + QUOTENAME(OBJECT_NAME(fk.referenced_object_id)) + '(' +
    QUOTENAME(COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id)) + '),' + CHAR(13)
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE fk.parent_object_id = OBJECT_ID(@TableName);

-- Check Constraints
SELECT @Constraints = @Constraints +
    '    CONSTRAINT ' + QUOTENAME(cc.name) + ' CHECK ' + cc.definition + ',' + CHAR(13)
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID(@TableName);

-- Add constraints if any exist
IF LEN(@Constraints) > 0
BEGIN
    SET @SQL = @SQL + ',' + CHAR(13) + @Constraints;
    -- Remove last comma
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13);
END

-- Close table definition
SET @SQL = @SQL + ');' + CHAR(13);

PRINT @SQL;
GO

/*
OUTPUT:
CREATE TABLE [Customer] (
    [CustomerID] int IDENTITY(1,1) NOT NULL,
    [CustomerName] nvarchar(200) NOT NULL,
    [Email] nvarchar(200) NULL,
    [PhoneNumber] varchar(20) NULL,
    [CreatedDate] datetime2(7) NULL DEFAULT (sysdatetime()),
    [IsActive] bit NULL DEFAULT ((1)),
    CONSTRAINT [PK__Customer__A4AE64B8...] PRIMARY KEY CLUSTERED ([CustomerID])
);

Complete CREATE TABLE script!
*/

/*
================================================================================
PART 2: GENERATE ALL TABLE SCRIPTS
================================================================================
*/

-- Example 2: Generate CREATE TABLE for all user tables
DECLARE @AllTablesSQL NVARCHAR(MAX) = '';
DECLARE @CurrentTable NVARCHAR(128);

DECLARE table_cursor CURSOR FOR
SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @CurrentTable;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @AllTablesSQL = @AllTablesSQL + '-- ========================================' + CHAR(13);
    SET @AllTablesSQL = @AllTablesSQL + '-- Table: ' + @CurrentTable + CHAR(13);
    SET @AllTablesSQL = @AllTablesSQL + '-- ========================================' + CHAR(13);
    
    -- (Code to generate table script would go here - simplified for brevity)
    SET @AllTablesSQL = @AllTablesSQL + 'CREATE TABLE ' + QUOTENAME(@CurrentTable) + ' (...);' + CHAR(13);
    SET @AllTablesSQL = @AllTablesSQL + 'GO' + CHAR(13) + CHAR(13);
    
    FETCH NEXT FROM table_cursor INTO @CurrentTable;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

PRINT @AllTablesSQL;
GO

/*
================================================================================
PART 3: DATA DICTIONARY GENERATION
================================================================================

Create comprehensive data dictionary for documentation.
*/

-- Example 1: Column-level data dictionary
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    c.column_id AS Position,
    TYPE_NAME(c.user_type_id) AS DataType,
    CASE 
        WHEN TYPE_NAME(c.user_type_id) IN ('varchar', 'nvarchar', 'char', 'nchar') THEN
            CASE WHEN c.max_length = -1 THEN 'MAX' 
                 ELSE CAST(CASE WHEN TYPE_NAME(c.user_type_id) LIKE 'n%' 
                                THEN c.max_length / 2 
                                ELSE c.max_length END AS VARCHAR(10)) 
            END
        WHEN TYPE_NAME(c.user_type_id) IN ('decimal', 'numeric') THEN
            CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10))
        ELSE ''
    END AS Size,
    CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS Nullable,
    CASE WHEN c.is_identity = 1 THEN 'Yes' ELSE 'No' END AS IsIdentity,
    CASE WHEN pk.column_id IS NOT NULL THEN 'PK' ELSE '' END AS PrimaryKey,
    CASE WHEN fk.parent_column_id IS NOT NULL 
         THEN OBJECT_NAME(fk.referenced_object_id) ELSE '' END AS ForeignKeyTable,
    ISNULL(dc.definition, '') AS DefaultValue,
    ISNULL(cc.definition, '') AS CheckConstraint
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
LEFT JOIN sys.foreign_key_columns fk 
    ON c.object_id = fk.parent_object_id AND c.column_id = fk.parent_column_id
LEFT JOIN sys.default_constraints dc 
    ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
LEFT JOIN sys.check_constraints cc 
    ON c.object_id = cc.parent_object_id
WHERE t.is_ms_shipped = 0
ORDER BY t.name, c.column_id;
GO

/*
OUTPUT:
TableName  ColumnName      Position  DataType   Size     Nullable  IsIdentity  PrimaryKey  ForeignKeyTable  DefaultValue         CheckConstraint
---------  -------------   --------  ---------  -------  --------  ----------  ----------  ---------------  -------------------  ---------------
Customer   CustomerID      1         int                 No        Yes         PK
Customer   CustomerName    2         nvarchar   200      No        No
Customer   Email           3         nvarchar   200      Yes       No
Customer   PhoneNumber     4         varchar    20       Yes       No
Customer   CreatedDate     5         datetime2  7        Yes       No                                       (sysdatetime())
Customer   IsActive        6         bit                 Yes       No                                       ((1))
Order      OrderID         1         int                 No        Yes         PK
Order      CustomerID      2         int                 No        No                      Customer
Order      OrderDate       3         date                No        No                                       (CONVERT([date],getdate()))
...

Complete data dictionary!
*/

-- Example 2: Table-level summary
SELECT 
    t.name AS TableName,
    COUNT(c.column_id) AS ColumnCount,
    SUM(CASE WHEN c.is_nullable = 0 THEN 1 ELSE 0 END) AS RequiredColumns,
    SUM(CASE WHEN pk.column_id IS NOT NULL THEN 1 ELSE 0 END) AS PKColumns,
    COUNT(DISTINCT fk.constraint_object_id) AS ForeignKeyCount,
    COUNT(DISTINCT idx.index_id) - 1 AS IndexCount,  -- Subtract heap/PK
    ISNULL(SUM(p.rows), 0) AS RowCount
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
LEFT JOIN sys.foreign_key_columns fk ON c.object_id = fk.parent_object_id
LEFT JOIN sys.indexes idx ON t.object_id = idx.object_id AND idx.type > 0
LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE t.is_ms_shipped = 0
GROUP BY t.name
ORDER BY t.name;
GO

/*
OUTPUT:
TableName    ColumnCount  RequiredColumns  PKColumns  ForeignKeyCount  IndexCount  RowCount
-----------  -----------  ---------------  ---------  ---------------  ----------  --------
Customer     6            2                1          0                2           3
Order        7            3                1          1                3           3
OrderItem    7            4                1          2                1           5
Product      6            2                1          0                2           4

Table summary statistics!
*/

/*
================================================================================
PART 4: RELATIONSHIP DOCUMENTATION
================================================================================
*/

-- Example 1: Foreign key relationships with details
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS FromTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS FromColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ToTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ToColumn,
    fk.name AS ConstraintName,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate,
    CASE WHEN fk.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END AS Status
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY FromTable, ToTable;
GO

/*
OUTPUT:
FromTable  FromColumn   ToTable   ToColumn    ConstraintName              OnDelete   OnUpdate   Status
---------  -----------  --------  ----------  --------------------------  ---------  ---------  -------
Order      CustomerID   Customer  CustomerID  FK__Order__CustomerID...    NO_ACTION  NO_ACTION  ENABLED
OrderItem  OrderID      Order     OrderID     FK__OrderItem__OrderID...   NO_ACTION  NO_ACTION  ENABLED
OrderItem  ProductID    Product   ProductID   FK__OrderItem__ProductID... NO_ACTION  NO_ACTION  ENABLED

Complete relationship map!
*/

-- Example 2: Generate ER diagram data (Mermaid format)
DECLARE @Mermaid NVARCHAR(MAX) = 'erDiagram' + CHAR(13);

-- Add tables and columns
DECLARE @Table NVARCHAR(128);
DECLARE table_cur CURSOR FOR
SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name;

OPEN table_cur;
FETCH NEXT FROM table_cur INTO @Table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Mermaid = @Mermaid + '    ' + @Table + ' {' + CHAR(13);
    
    SELECT @Mermaid = @Mermaid + 
        '        ' + TYPE_NAME(c.user_type_id) + ' ' + c.name +
        CASE WHEN pk.column_id IS NOT NULL THEN ' PK' ELSE '' END +
        CASE WHEN fk.parent_column_id IS NOT NULL THEN ' FK' ELSE '' END +
        CHAR(13)
    FROM sys.columns c
    LEFT JOIN (
        SELECT ic.object_id, ic.column_id
        FROM sys.index_columns ic
        INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        WHERE i.is_primary_key = 1
    ) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
    LEFT JOIN sys.foreign_key_columns fk 
        ON c.object_id = fk.parent_object_id AND c.column_id = fk.parent_column_id
    WHERE c.object_id = OBJECT_ID(@Table)
    ORDER BY c.column_id;
    
    SET @Mermaid = @Mermaid + '    }' + CHAR(13);
    
    FETCH NEXT FROM table_cur INTO @Table;
END

CLOSE table_cur;
DEALLOCATE table_cur;

-- Add relationships
SELECT @Mermaid = @Mermaid +
    '    ' + OBJECT_NAME(fk.referenced_object_id) + 
    ' ||--o{ ' + OBJECT_NAME(fk.parent_object_id) + 
    ' : "' + fk.name + '"' + CHAR(13)
FROM sys.foreign_keys fk;

PRINT @Mermaid;
GO

/*
OUTPUT:
erDiagram
    Customer {
        int CustomerID PK
        nvarchar CustomerName
        nvarchar Email
        varchar PhoneNumber
        datetime2 CreatedDate
        bit IsActive
    }
    Order {
        int OrderID PK
        int CustomerID FK
        date OrderDate
        date ShipDate
        decimal TotalAmount
        varchar Status
    }
    OrderItem {
        int OrderItemID PK
        int OrderID FK
        int ProductID FK
        int Quantity
        decimal UnitPrice
        decimal Discount
        decimal LineTotal
    }
    Product {
        int ProductID PK
        nvarchar ProductName
        nvarchar CategoryName
        decimal UnitPrice
        int StockQuantity
        int ReorderLevel
    }
    Customer ||--o{ Order : "FK__Order__CustomerID..."
    Order ||--o{ OrderItem : "FK__OrderItem__OrderID..."
    Product ||--o{ OrderItem : "FK__OrderItem__ProductID..."

Mermaid ER diagram code!
*/

/*
================================================================================
PART 5: INDEX DOCUMENTATION
================================================================================
*/

-- Example 1: Complete index documentation
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    CASE WHEN i.is_unique = 1 THEN 'Yes' ELSE 'No' END AS IsUnique,
    CASE WHEN i.is_primary_key = 1 THEN 'Yes' ELSE 'No' END AS IsPrimaryKey,
    i.fill_factor AS FillFactor,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 0 
        THEN COL_NAME(ic.object_id, ic.column_id) +
             CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
        END, ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 1 
        THEN COL_NAME(ic.object_id, ic.column_id) 
        END, ', '
    ) AS IncludedColumns,
    ds.name AS Filegroup
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.data_spaces ds ON i.data_space_id = ds.data_space_id
WHERE t.is_ms_shipped = 0 AND i.type > 0
GROUP BY 
    i.object_id, i.name, i.type_desc, i.is_unique, i.is_primary_key, 
    i.fill_factor, ds.name
ORDER BY TableName, IndexName;
GO

/*
OUTPUT:
TableName  IndexName              IndexType     IsUnique  IsPrimaryKey  FillFactor  KeyColumns              IncludedColumns       Filegroup
---------  --------------------   ------------  --------  ------------  ----------  ----------------------  --------------------  ---------
Customer   IX_Customer_Email      NONCLUSTERED  No        No            0           Email ASC               NULL                  PRIMARY
Customer   PK__Customer...        CLUSTERED     Yes       Yes           0           CustomerID ASC          NULL                  PRIMARY
Order      IX_Order_Customer      NONCLUSTERED  No        No            0           CustomerID ASC,         NULL                  PRIMARY
                                                                                     OrderDate ASC
Order      IX_Order_Date          NONCLUSTERED  No        No            0           OrderDate ASC           TotalAmount, Status   PRIMARY
...

Complete index documentation!
*/

/*
================================================================================
PART 6: CONSTRAINT DOCUMENTATION
================================================================================
*/

-- Example 1: All constraints with definitions
SELECT 
    OBJECT_NAME(cc.parent_object_id) AS TableName,
    cc.name AS ConstraintName,
    'CHECK' AS ConstraintType,
    cc.definition AS Definition,
    CASE WHEN cc.is_disabled = 1 THEN 'DISABLED' ELSE 'ENABLED' END AS Status
FROM sys.check_constraints cc
WHERE OBJECT_SCHEMA_NAME(cc.parent_object_id) = 'dbo'

UNION ALL

SELECT 
    OBJECT_NAME(dc.parent_object_id) AS TableName,
    dc.name AS ConstraintName,
    'DEFAULT' AS ConstraintType,
    COL_NAME(dc.parent_object_id, dc.parent_column_id) + ' = ' + dc.definition AS Definition,
    'ENABLED' AS Status
FROM sys.default_constraints dc
WHERE OBJECT_SCHEMA_NAME(dc.parent_object_id) = 'dbo'

UNION ALL

SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS ConstraintName,
    'UNIQUE' AS ConstraintType,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') 
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS Definition,
    'ENABLED' AS Status
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.is_unique_constraint = 1
  AND OBJECT_SCHEMA_NAME(i.object_id) = 'dbo'
GROUP BY i.object_id, i.name

ORDER BY TableName, ConstraintType, ConstraintName;
GO

/*
OUTPUT:
TableName   ConstraintName                ConstraintType  Definition                                        Status
----------  ----------------------------  --------------  ------------------------------------------------  -------
Customer    DF__Customer__Created...       DEFAULT         CreatedDate = (sysdatetime())                    ENABLED
Customer    DF__Customer__IsActiv...       DEFAULT         IsActive = ((1))                                 ENABLED
Order       CHK_ShipDate                   CHECK           ([ShipDate]>=[OrderDate] OR [ShipDate] IS NULL)  ENABLED
Order       DF__Order__OrderDate...        DEFAULT         OrderDate = (CONVERT([date],getdate()))          ENABLED
Order       DF__Order__Status...           DEFAULT         Status = ('Pending')                             ENABLED
OrderItem   DF__OrderItem__Discou...       DEFAULT         Discount = ((0))                                 ENABLED
Product     DF__Product__ReorderL...       DEFAULT         ReorderLevel = ((10))                            ENABLED
Product     DF__Product__StockQua...       DEFAULT         StockQuantity = ((0))                            ENABLED
...

Complete constraint documentation!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Complete Schema Export
-----------------------------------
Create a stored procedure that generates a complete database schema script
including:
- DROP TABLE statements (in correct order)
- CREATE TABLE statements with all columns, constraints
- CREATE INDEX statements
- Sample data INSERT statements (optional parameter)

The output should be executable SQL that recreates the database.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: HTML Data Dictionary
---------------------------------
Generate an HTML data dictionary with:
- Table of contents with links
- Each table in a separate section with:
  * Table description
  * Column list with data types
  * Primary and foreign keys highlighted
  * Indexes listed
  * Constraints documented

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Schema Comparison
------------------------------
Create queries that compare two schemas (simulate by creating backup tables):
- Find tables that exist in one but not the other
- Find columns that differ between same-named tables
- Find missing indexes
- Find constraint differences

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Complete Schema Export Procedure
CREATE OR ALTER PROCEDURE usp_GenerateSchemaScript
    @IncludeSampleData BIT = 0
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = '';
    
    -- Header
    SET @SQL = '/*' + CHAR(13);
    SET @SQL = @SQL + 'Database Schema Export' + CHAR(13);
    SET @SQL = @SQL + 'Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120) + CHAR(13);
    SET @SQL = @SQL + '*/' + CHAR(13) + CHAR(13);
    
    -- Drop tables in reverse FK dependency order
    SET @SQL = @SQL + '-- Drop tables in dependency order' + CHAR(13);
    
    WITH TableDependencies AS (
        SELECT DISTINCT
            OBJECT_NAME(fk.parent_object_id) AS TableName,
            0 AS Level
        FROM sys.foreign_keys fk
        WHERE NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys fk2
            WHERE fk2.referenced_object_id = fk.parent_object_id
        )
        UNION ALL
        SELECT DISTINCT
            OBJECT_NAME(fk.parent_object_id),
            td.Level + 1
        FROM sys.foreign_keys fk
        INNER JOIN TableDependencies td 
            ON OBJECT_NAME(fk.referenced_object_id) = td.TableName
    )
    SELECT @SQL = @SQL + 'DROP TABLE IF EXISTS ' + QUOTENAME(TableName) + ';' + CHAR(13)
    FROM (
        SELECT TableName, MAX(Level) AS MaxLevel
        FROM TableDependencies
        GROUP BY TableName
    ) t
    ORDER BY MaxLevel DESC;
    
    SET @SQL = @SQL + 'GO' + CHAR(13) + CHAR(13);
    
    -- Create tables
    DECLARE @TableName NVARCHAR(128);
    DECLARE table_cur CURSOR FOR
    SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name;
    
    OPEN table_cur;
    FETCH NEXT FROM table_cur INTO @TableName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = @SQL + '-- Table: ' + @TableName + CHAR(13);
        SET @SQL = @SQL + 'CREATE TABLE ' + QUOTENAME(@TableName) + ' (' + CHAR(13);
        
        -- Columns
        SELECT @SQL = @SQL + 
            '    ' + QUOTENAME(c.name) + ' ' +
            TYPE_NAME(c.user_type_id) +
            CASE 
                WHEN TYPE_NAME(c.user_type_id) IN ('varchar', 'nvarchar', 'char', 'nchar') THEN
                    '(' + CASE WHEN c.max_length = -1 THEN 'MAX' 
                               ELSE CAST(CASE WHEN TYPE_NAME(c.user_type_id) LIKE 'n%' 
                                              THEN c.max_length / 2 
                                              ELSE c.max_length END AS VARCHAR(10)) 
                          END + ')'
                WHEN TYPE_NAME(c.user_type_id) IN ('decimal', 'numeric') THEN
                    '(' + CAST(c.precision AS VARCHAR(10)) + ',' + CAST(c.scale AS VARCHAR(10)) + ')'
                ELSE ''
            END +
            CASE WHEN c.is_identity = 1 THEN ' IDENTITY(1,1)' ELSE '' END +
            CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
            ',' + CHAR(13)
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID(@TableName)
        ORDER BY c.column_id;
        
        -- Remove last comma
        SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13);
        SET @SQL = @SQL + ');' + CHAR(13);
        SET @SQL = @SQL + 'GO' + CHAR(13) + CHAR(13);
        
        FETCH NEXT FROM table_cur INTO @TableName;
    END
    
    CLOSE table_cur;
    DEALLOCATE table_cur;
    
    PRINT @SQL;
    
    -- Note: Full implementation would include constraints, indexes, and sample data
END;
GO

-- Execute the procedure
EXEC usp_GenerateSchemaScript @IncludeSampleData = 0;
GO

-- Solution 2: HTML Data Dictionary
DECLARE @HTML NVARCHAR(MAX) = '';

SET @HTML = '<html><head><style>
table { border-collapse: collapse; margin: 20px 0; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #4CAF50; color: white; }
.pk { background-color: #ffffcc; }
.fk { background-color: #ccffcc; }
h2 { color: #4CAF50; }
</style></head><body>';

SET @HTML = @HTML + '<h1>Database Data Dictionary</h1>';
SET @HTML = @HTML + '<p>Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120) + '</p>';

-- Table of contents
SET @HTML = @HTML + '<h2>Table of Contents</h2><ul>';
SELECT @HTML = @HTML + '<li><a href="#' + name + '">' + name + '</a></li>'
FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name;
SET @HTML = @HTML + '</ul>';

-- Each table
DECLARE @Table NVARCHAR(128);
DECLARE tbl_cur CURSOR FOR SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @Table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @HTML = @HTML + '<h2 id="' + @Table + '">' + @Table + '</h2>';
    SET @HTML = @HTML + '<table><tr><th>Column</th><th>Type</th><th>Nullable</th><th>Key</th></tr>';
    
    SELECT @HTML = @HTML + 
        '<tr class="' + 
        CASE WHEN pk.column_id IS NOT NULL THEN 'pk' 
             WHEN fk.parent_column_id IS NOT NULL THEN 'fk' 
             ELSE '' END + 
        '"><td>' + c.name + '</td><td>' + 
        TYPE_NAME(c.user_type_id) + '</td><td>' + 
        CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END + '</td><td>' +
        CASE WHEN pk.column_id IS NOT NULL THEN 'PK' 
             WHEN fk.parent_column_id IS NOT NULL THEN 'FK' 
             ELSE '' END + 
        '</td></tr>'
    FROM sys.columns c
    LEFT JOIN (
        SELECT ic.object_id, ic.column_id
        FROM sys.index_columns ic
        INNER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        WHERE i.is_primary_key = 1
    ) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
    LEFT JOIN sys.foreign_key_columns fk 
        ON c.object_id = fk.parent_object_id AND c.column_id = fk.parent_column_id
    WHERE c.object_id = OBJECT_ID(@Table)
    ORDER BY c.column_id;
    
    SET @HTML = @HTML + '</table>';
    
    FETCH NEXT FROM tbl_cur INTO @Table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SET @HTML = @HTML + '</body></html>';

PRINT @HTML;
GO

-- Solution 3: Schema Comparison
-- Create backup tables for comparison
SELECT * INTO Customer_Backup FROM Customer WHERE 1=0;
ALTER TABLE Customer_Backup ADD NewColumn VARCHAR(50);
GO

-- Find table differences
SELECT 'Missing in Target' AS Difference, name AS TableName
FROM sys.tables 
WHERE name LIKE 'Customer%' AND name NOT LIKE '%Backup'
  AND name NOT IN (SELECT REPLACE(name, '_Backup', '') FROM sys.tables WHERE name LIKE '%Backup')

UNION ALL

SELECT 'Missing in Source' AS Difference, REPLACE(name, '_Backup', '') AS TableName
FROM sys.tables 
WHERE name LIKE '%Backup'
  AND REPLACE(name, '_Backup', '') NOT IN (SELECT name FROM sys.tables WHERE name LIKE 'Customer%' AND name NOT LIKE '%Backup');
GO

-- Find column differences
SELECT 
    c1.name AS SourceColumn,
    c2.name AS TargetColumn,
    CASE 
        WHEN c2.name IS NULL THEN 'Missing in Target'
        WHEN c1.name IS NULL THEN 'Missing in Source'
        WHEN TYPE_NAME(c1.user_type_id) <> TYPE_NAME(c2.user_type_id) THEN 'Type Mismatch'
        ELSE 'Match'
    END AS Difference
FROM sys.columns c1
FULL OUTER JOIN sys.columns c2 
    ON c1.name = c2.name
    AND c2.object_id = OBJECT_ID('Customer_Backup')
WHERE c1.object_id = OBJECT_ID('Customer')
   OR c2.object_id = OBJECT_ID('Customer_Backup');
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. CREATE TABLE GENERATION
   - Query sys.tables + sys.columns for structure
   - Include data types with precision/scale
   - Add identity, nullable, default clauses
   - Append constraints (PK, FK, CHECK)
   - Format for readability

2. DATA DICTIONARY
   - Column-level: name, type, nullable, keys, constraints
   - Table-level: row counts, FK relationships
   - Index documentation
   - Constraint definitions
   - Export to various formats (HTML, Markdown, CSV)

3. RELATIONSHIP MAPPING
   - sys.foreign_keys for FK details
   - Cascade rules (ON DELETE, ON UPDATE)
   - Dependency graphs
   - ER diagram generation (Mermaid, GraphViz)

4. INDEX DOCUMENTATION
   - Key vs included columns
   - Clustered vs nonclustered
   - Unique and filter conditions
   - Fill factor and filegroup
   - Usage statistics

5. AUTOMATION BENEFITS
   - Version control database schemas
   - Quick disaster recovery
   - Consistent documentation
   - Schema comparison
   - Migration scripts

6. OUTPUT FORMATS
   - SQL scripts (.sql)
   - HTML documentation
   - Markdown files
   - CSV data dictionaries
   - ER diagram notations (Mermaid, PlantUML)

7. BEST PRACTICES
   - Order DROP statements by FK dependencies
   - Include GO batch separators
   - Add comments and headers
   - Test generated scripts
   - Keep documentation current
   - Version control metadata queries

8. COMMON USE CASES
   - Database migrations
   - Disaster recovery planning
   - Developer onboarding
   - Schema comparison
   - Audit and compliance
   - Documentation automation

================================================================================

NEXT STEPS:
-----------
In Lesson 15.5, we'll explore DEPLOYMENT AND VERIFICATION:
- Pre-deployment validation
- Schema comparison tools
- Post-deployment verification
- Rollback scripts

Continue to: 05-deployment-verification/lesson.sql

================================================================================
*/
