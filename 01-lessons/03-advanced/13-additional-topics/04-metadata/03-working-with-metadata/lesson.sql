/*
================================================================================
LESSON 15.3: WORKING WITH METADATA
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Query sys catalog views effectively
2. Use system stored procedures
3. Find object dependencies
4. Query index and constraint metadata
5. Work with dynamic management views (DMVs)
6. Compare sys views vs INFORMATION_SCHEMA
7. Build comprehensive metadata queries

Business Context:
-----------------
SQL Server's sys catalog views provide detailed metadata beyond what
INFORMATION_SCHEMA offers. These views are essential for database administration,
performance tuning, and automation. Understanding sys views enables advanced
database management and monitoring tasks.

Database: RetailStore
Complexity: Intermediate-Advanced
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: SYS.TABLES - TABLE METADATA
================================================================================

sys.tables provides comprehensive table information including SQL Server-specific
features not available in INFORMATION_SCHEMA.
*/

-- Create sample tables
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200),
    CreatedDate DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    StockQuantity INT DEFAULT 0
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(12,2)
);

CREATE TABLE OrderItem (
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
);
GO

-- Insert sample data
INSERT INTO Customer (CustomerName, Email) VALUES
    ('Acme Corp', 'contact@acme.com'),
    ('TechStart', 'info@techstart.com');

INSERT INTO Product (ProductName, UnitPrice, StockQuantity) VALUES
    ('Laptop', 999.99, 50),
    ('Mouse', 29.99, 200);

INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount) VALUES
    (1, '2024-11-01', 1029.98),
    (2, '2024-11-05', 59.98);

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice) VALUES
    (1, 1, 1, 999.99),
    (1, 2, 1, 29.99),
    (2, 2, 2, 29.99);
GO

-- Example 1: List all user tables with detailed info
SELECT 
    name AS TableName,
    object_id AS ObjectID,
    create_date AS Created,
    modify_date AS LastModified,
    DATEDIFF(DAY, create_date, GETDATE()) AS DaysOld
FROM sys.tables
WHERE is_ms_shipped = 0  -- Exclude system tables
ORDER BY name;
GO

/*
OUTPUT:
TableName    ObjectID    Created              LastModified         DaysOld
-----------  ----------  -------------------  -------------------  -------
Customer     245575913   2024-11-09 10:00:00  2024-11-09 10:00:00  0
Order        277576027   2024-11-09 10:00:00  2024-11-09 10:00:00  0
OrderItem    309576141   2024-11-09 10:00:00  2024-11-09 10:00:00  0
Product      341576255   2024-11-09 10:00:00  2024-11-09 10:00:00  0

Complete table metadata with timestamps!
*/

-- Example 2: Find recently modified tables
SELECT 
    name AS TableName,
    modify_date AS LastModified
FROM sys.tables
WHERE is_ms_shipped = 0
  AND modify_date >= DATEADD(DAY, -7, GETDATE())
ORDER BY modify_date DESC;
GO

-- Example 3: Table properties
SELECT 
    t.name AS TableName,
    t.type_desc AS Type,
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.is_tracked_by_cdc AS ChangeDataCapture,
    t.lock_on_bulk_load AS BulkLoadLocking,
    t.is_replicated AS IsReplicated
FROM sys.tables t
WHERE t.is_ms_shipped = 0
ORDER BY t.name;
GO

/*
================================================================================
PART 2: SYS.COLUMNS - COLUMN METADATA
================================================================================

Detailed column information with SQL Server-specific attributes.
*/

-- Example 1: Comprehensive column information
SELECT 
    OBJECT_NAME(c.object_id) AS TableName,
    c.name AS ColumnName,
    c.column_id AS Position,
    TYPE_NAME(c.user_type_id) AS DataType,
    c.max_length AS MaxBytes,
    c.precision AS Precision,
    c.scale AS Scale,
    c.is_nullable AS IsNullable,
    c.is_identity AS IsIdentity,
    c.is_computed AS IsComputed
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY OBJECT_NAME(c.object_id), c.column_id;
GO

/*
OUTPUT:
TableName   ColumnName     Position  DataType   MaxBytes  Precision  Scale  IsNullable  IsIdentity  IsComputed
----------  -------------  --------  ---------  --------  ---------  -----  ----------  ----------  ----------
Customer    CustomerID     1         int        4         10         0      0           1           0
Customer    CustomerName   2         nvarchar   400       0          0      0           0           0
Customer    Email          3         nvarchar   400       0          0      1           0           0
Customer    CreatedDate    4         datetime2  8         27         7      1           0           0
...

Rich column metadata!
*/

-- Example 2: Find identity columns
SELECT 
    OBJECT_NAME(c.object_id) AS TableName,
    c.name AS IdentityColumn,
    CAST(IDENT_SEED(OBJECT_NAME(c.object_id)) AS BIGINT) AS Seed,
    CAST(IDENT_INCR(OBJECT_NAME(c.object_id)) AS BIGINT) AS Increment,
    CAST(IDENT_CURRENT(OBJECT_NAME(c.object_id)) AS BIGINT) AS CurrentValue
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.is_identity = 1
  AND t.is_ms_shipped = 0
ORDER BY TableName;
GO

/*
OUTPUT:
TableName    IdentityColumn  Seed  Increment  CurrentValue
-----------  --------------  ----  ---------  ------------
Customer     CustomerID      1     1          2
Order        OrderID         1     1          2
OrderItem    OrderItemID     1     1          3
Product      ProductID       1     1          2

Identity column tracking!
*/

-- Example 3: Find computed columns
SELECT 
    OBJECT_NAME(c.object_id) AS TableName,
    c.name AS ComputedColumn,
    cc.definition AS Formula,
    c.is_persisted AS IsPersisted
FROM sys.columns c
INNER JOIN sys.computed_columns cc ON c.object_id = cc.object_id 
    AND c.column_id = cc.column_id
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0;
GO

/*
================================================================================
PART 3: SYS.INDEXES - INDEX METADATA
================================================================================

Complete index information for performance tuning.
*/

-- Create some indexes
CREATE INDEX IX_Customer_Email ON Customer(Email);
CREATE INDEX IX_Product_Name ON Product(ProductName);
CREATE INDEX IX_Order_Date ON [Order](OrderDate) INCLUDE (TotalAmount);
GO

-- Example 1: List all indexes
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique_constraint AS IsUniqueConstraint,
    i.fill_factor AS FillFactor
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND i.type > 0  -- Exclude heaps
ORDER BY OBJECT_NAME(i.object_id), i.name;
GO

/*
OUTPUT:
TableName   IndexName              IndexType        IsUnique  IsPrimaryKey  IsUniqueConstraint  FillFactor
----------  --------------------   --------------   --------  ------------  ------------------  ----------
Customer    IX_Customer_Email      NONCLUSTERED     0         0             0                   0
Customer    PK__Customer...        CLUSTERED        1         1             0                   0
Order       IX_Order_Date          NONCLUSTERED     0         0             0                   0
Order       PK__Order...           CLUSTERED        1         1             0                   0
OrderItem   PK__OrderItem...       CLUSTERED        1         1             0                   0
Product     IX_Product_Name        NONCLUSTERED     0         0             0                   0
Product     PK__Product...         CLUSTERED        1         1             0                   0

Complete index inventory!
*/

-- Example 2: Index columns with included columns
SELECT 
    OBJECT_NAME(ic.object_id) AS TableName,
    i.name AS IndexName,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
    ic.key_ordinal AS KeyPosition,
    ic.is_descending_key AS IsDescending,
    ic.is_included_column AS IsIncluded
FROM sys.index_columns ic
INNER JOIN sys.indexes i ON ic.object_id = i.object_id 
    AND ic.index_id = i.index_id
INNER JOIN sys.tables t ON ic.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND i.type > 0
ORDER BY OBJECT_NAME(ic.object_id), i.name, ic.key_ordinal, ic.is_included_column;
GO

/*
OUTPUT:
TableName  IndexName         ColumnName    KeyPosition  IsDescending  IsIncluded
---------  ----------------  -----------   -----------  ------------  ----------
Customer   IX_Customer_Email Email         1            0             0
Customer   PK__Customer...   CustomerID    1            0             0
Order      IX_Order_Date     OrderDate     1            0             0
Order      IX_Order_Date     TotalAmount   0            NULL          1
Order      PK__Order...      OrderID       1            0             0
...

Shows key and included columns!
*/

-- Example 3: Find tables without indexes (heaps)
SELECT 
    t.name AS TableName,
    'No clustered index (HEAP)' AS Issue
FROM sys.tables t
WHERE NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = t.object_id
    AND i.type = 1  -- Clustered index
)
AND t.is_ms_shipped = 0;
GO

/*
================================================================================
PART 4: SYS.FOREIGN_KEYS - FOREIGN KEY METADATA
================================================================================

Detailed foreign key constraint information.
*/

-- Example 1: List all foreign keys with details
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
ORDER BY TableName, ForeignKeyName;
GO

/*
OUTPUT:
ForeignKeyName             TableName   ColumnName  ReferencedTable  ReferencedColumn  OnDelete    OnUpdate    IsDisabled  IsNotTrusted
-------------------------  ----------  ----------  ---------------  ----------------  ----------  ----------  ----------  ------------
FK__Order__CustomerID...   Order       CustomerID  Customer         CustomerID        NO_ACTION   NO_ACTION   0           0
FK__OrderItem__OrderID...  OrderItem   OrderID     Order            OrderID           NO_ACTION   NO_ACTION   0           0
FK__OrderItem__ProductID.. OrderItem   ProductID   Product          ProductID         NO_ACTION   NO_ACTION   0           0

Complete FK metadata with cascade rules!
*/

-- Example 2: Find foreign keys referencing a specific table
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    fk.name AS ForeignKeyName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.referenced_object_id = OBJECT_ID('Customer')
ORDER BY ReferencingTable;
GO

/*
OUTPUT:
ReferencingTable  ForeignKeyName                Column
----------------  ----------------------------  ----------
Order             FK__Order__CustomerID...      CustomerID

Tables referencing Customer!
*/

/*
================================================================================
PART 5: SYS.OBJECTS - ALL DATABASE OBJECTS
================================================================================

Universal view for all database objects.
*/

-- Example 1: Count objects by type
SELECT 
    type_desc AS ObjectType,
    COUNT(*) AS Count
FROM sys.objects
WHERE is_ms_shipped = 0
GROUP BY type_desc
ORDER BY Count DESC;
GO

/*
OUTPUT:
ObjectType                   Count
---------------------------  -----
USER_TABLE                   4
PRIMARY_KEY_CONSTRAINT       4
FOREIGN_KEY_CONSTRAINT       3
SQL_INLINE_TABLE_VALUED_...  0
...

Object inventory by type!
*/

-- Example 2: Find objects by name pattern
SELECT 
    name AS ObjectName,
    type_desc AS Type,
    create_date AS Created,
    modify_date AS Modified
FROM sys.objects
WHERE name LIKE '%Customer%'
  AND is_ms_shipped = 0
ORDER BY type_desc, name;
GO

-- Example 3: Recently created objects
SELECT TOP 10
    name AS ObjectName,
    type_desc AS Type,
    create_date AS Created
FROM sys.objects
WHERE is_ms_shipped = 0
ORDER BY create_date DESC;
GO

/*
================================================================================
PART 6: SYSTEM STORED PROCEDURES
================================================================================

Built-in procedures for quick metadata access.
*/

-- Example 1: sp_help - General object information
EXEC sp_help 'Customer';
GO

/*
OUTPUT: Multiple result sets with:
- Table name, owner, type
- Columns with data types
- Identity columns
- Row GUID columns
- Filegroup info
- Indexes
- Constraints
*/

-- Example 2: sp_columns - Column details
EXEC sp_columns 'Customer';
GO

/*
OUTPUT:
Column details including:
- Column name
- Data type
- Precision
- Length
- Nullability
*/

-- Example 3: sp_helpindex - Index information
EXEC sp_helpindex 'Customer';
GO

/*
OUTPUT:
index_name                 index_description
-------------------------  ---------------------------------
IX_Customer_Email          nonclustered located on PRIMARY
PK__Customer__A4AE64B8... clustered, unique, primary key...
*/

-- Example 4: sp_helpconstraint - Constraint details
EXEC sp_helpconstraint 'Customer';
GO

/*
OUTPUT:
- Table constraints (PK, FK, etc.)
- Referencing tables
- Referenced by tables
*/

-- Example 5: sp_depends - Object dependencies
EXEC sp_depends 'Customer';
GO

/*
OUTPUT: Objects that depend on Customer table
*/

-- Example 6: sp_spaceused - Table size information
EXEC sp_spaceused 'Customer';
GO

/*
OUTPUT:
name      rows  reserved  data     index_size  unused
--------  ----  --------  -------  ----------  ------
Customer  2     16 KB     8 KB     8 KB        0 KB

Table space usage!
*/

/*
================================================================================
PART 7: DYNAMIC MANAGEMENT VIEWS (DMVs)
================================================================================

Runtime and performance metadata.
*/

-- Example 1: Index usage statistics
SELECT 
    OBJECT_NAME(ius.object_id) AS TableName,
    i.name AS IndexName,
    ius.user_seeks AS Seeks,
    ius.user_scans AS Scans,
    ius.user_lookups AS Lookups,
    ius.user_updates AS Updates,
    ius.last_user_seek AS LastSeek,
    ius.last_user_scan AS LastScan
FROM sys.dm_db_index_usage_stats ius
INNER JOIN sys.indexes i ON ius.object_id = i.object_id 
    AND ius.index_id = i.index_id
WHERE database_id = DB_ID()
  AND OBJECT_NAME(ius.object_id) IN ('Customer', 'Product', 'Order', 'OrderItem')
ORDER BY TableName, IndexName;
GO

-- Example 2: Table sizes and row counts
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    SUM(p.rows) AS RowCount,
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM sys.partitions p
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.tables t ON p.object_id = t.object_id
WHERE t.is_ms_shipped = 0
  AND p.index_id IN (0, 1)  -- Heap or clustered index
GROUP BY p.object_id
ORDER BY TableName;
GO

/*
OUTPUT:
TableName    RowCount  TotalSpaceKB  UsedSpaceKB  UnusedSpaceKB
-----------  --------  ------------  -----------  -------------
Customer     2         16            8            8
Order        2         16            8            8
OrderItem    3         16            8            8
Product      2         16            8            8

Table storage statistics!
*/

-- Example 3: Missing indexes
SELECT 
    OBJECT_NAME(mid.object_id) AS TableName,
    mid.equality_columns AS EqualityColumns,
    mid.inequality_columns AS InequalityColumns,
    mid.included_columns AS IncludedColumns,
    migs.user_seeks AS Seeks,
    migs.user_scans AS Scans,
    migs.avg_user_impact AS AvgImpact
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig 
    ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs 
    ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact DESC;
GO

/*
================================================================================
PART 8: PRACTICAL METADATA QUERIES
================================================================================
*/

-- Query 1: Complete database schema report
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    TYPE_NAME(c.user_type_id) AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS Nullable,
    CASE 
        WHEN pk.column_id IS NOT NULL THEN 'PK'
        WHEN fk.parent_column_id IS NOT NULL THEN 'FK'
        ELSE ''
    END AS KeyType,
    fk_ref.ReferencedTable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    INNER JOIN sys.indexes i ON ic.object_id = i.object_id 
        AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) pk ON c.object_id = pk.object_id AND c.column_id = pk.column_id
LEFT JOIN sys.foreign_key_columns fk 
    ON c.object_id = fk.parent_object_id 
    AND c.column_id = fk.parent_column_id
LEFT JOIN (
    SELECT 
        fkc.parent_object_id,
        fkc.parent_column_id,
        OBJECT_NAME(fkc.referenced_object_id) AS ReferencedTable
    FROM sys.foreign_key_columns fkc
) fk_ref ON c.object_id = fk_ref.parent_object_id 
    AND c.column_id = fk_ref.parent_column_id
WHERE t.is_ms_shipped = 0
ORDER BY t.name, c.column_id;
GO

-- Query 2: Find unused indexes
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    'Unused - consider dropping' AS Recommendation
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id 
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE i.object_id IN (
    SELECT object_id FROM sys.tables WHERE is_ms_shipped = 0
)
AND i.type_desc = 'NONCLUSTERED'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
AND (ius.user_seeks IS NULL 
     AND ius.user_scans IS NULL 
     AND ius.user_lookups IS NULL)
ORDER BY TableName, IndexName;
GO

-- Query 3: Foreign key dependency graph
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS FromTable,
    OBJECT_NAME(fk.referenced_object_id) AS ToTable,
    COUNT(*) AS FKCount
FROM sys.foreign_keys fk
GROUP BY fk.parent_object_id, fk.referenced_object_id
ORDER BY FromTable, ToTable;
GO

/*
OUTPUT:
FromTable    ToTable   FKCount
-----------  --------  -------
Order        Customer  1
OrderItem    Order     1
OrderItem    Product   1

Relationship graph data!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Database Health Check
----------------------------------
Create a query that reports:
- Tables without primary keys
- Tables without indexes (heaps)
- Foreign keys that are disabled
- Columns with large VARCHAR lengths (> 1000)
- Tables with low row counts (< 10 rows)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Index Analysis
---------------------------
Create a comprehensive index report showing:
- All indexes per table
- Index type and uniqueness
- Columns in each index (key + included)
- Index usage statistics (seeks, scans, updates)
- Recommendation (keep, review, drop)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Dependency Analysis
--------------------------------
For the Customer table, find:
- All foreign keys referencing it
- All views using it
- All stored procedures referencing it
- All functions using it

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Database Health Check
-- Tables without primary keys
SELECT 
    'No Primary Key' AS Issue,
    t.name AS TableName,
    'Consider adding PK' AS Recommendation
FROM sys.tables t
WHERE t.is_ms_shipped = 0
AND NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = t.object_id AND i.is_primary_key = 1
)

UNION ALL

-- Heap tables (no clustered index)
SELECT 
    'HEAP Table' AS Issue,
    t.name AS TableName,
    'Consider adding clustered index' AS Recommendation
FROM sys.tables t
WHERE t.is_ms_shipped = 0
AND NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    WHERE i.object_id = t.object_id AND i.type = 1
)

UNION ALL

-- Disabled foreign keys
SELECT 
    'Disabled FK' AS Issue,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    'FK: ' + fk.name + ' - Enable or drop' AS Recommendation
FROM sys.foreign_keys fk
WHERE fk.is_disabled = 1

UNION ALL

-- Large VARCHAR columns
SELECT 
    'Large VARCHAR' AS Issue,
    OBJECT_NAME(c.object_id) AS TableName,
    c.name + ' (' + CAST(c.max_length AS VARCHAR(10)) + ' bytes)' AS Recommendation
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.is_ms_shipped = 0
AND c.max_length > 2000  -- More than 1000 nvarchar chars
AND TYPE_NAME(c.user_type_id) LIKE '%varchar%'

ORDER BY Issue, TableName;
GO

-- Solution 2: Index Analysis
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 0 
        THEN COL_NAME(ic.object_id, ic.column_id) 
        END, ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 1 
        THEN COL_NAME(ic.object_id, ic.column_id) 
        END, ', '
    ) AS IncludedColumns,
    ISNULL(ius.user_seeks, 0) AS Seeks,
    ISNULL(ius.user_scans, 0) AS Scans,
    ISNULL(ius.user_updates, 0) AS Updates,
    CASE 
        WHEN i.is_primary_key = 1 THEN 'Keep - Primary Key'
        WHEN ius.user_seeks + ius.user_scans > 0 THEN 'Keep - Used'
        WHEN ius.user_seeks IS NULL AND ius.user_scans IS NULL THEN 'Review - No usage stats'
        ELSE 'Consider dropping - Unused'
    END AS Recommendation
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id 
    AND i.index_id = ic.index_id
INNER JOIN sys.tables t ON i.object_id = t.object_id
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id 
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE t.is_ms_shipped = 0 AND i.type > 0
GROUP BY 
    i.object_id, i.name, i.type_desc, i.is_unique, i.is_primary_key,
    ius.user_seeks, ius.user_scans, ius.user_updates
ORDER BY TableName, IndexName;
GO

-- Solution 3: Dependency Analysis
PRINT '=== Foreign Keys Referencing Customer ===';
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    fk.name AS ForeignKeyName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.referenced_object_id = OBJECT_ID('Customer');
GO

PRINT '=== Views Using Customer ===';
SELECT DISTINCT
    OBJECT_NAME(sed.referencing_id) AS ViewName,
    o.type_desc AS ObjectType
FROM sys.sql_expression_dependencies sed
INNER JOIN sys.objects o ON sed.referencing_id = o.object_id
WHERE sed.referenced_id = OBJECT_ID('Customer')
AND o.type = 'V';  -- Views
GO

PRINT '=== Stored Procedures Using Customer ===';
SELECT DISTINCT
    OBJECT_NAME(sed.referencing_id) AS ProcedureName,
    o.type_desc AS ObjectType
FROM sys.sql_expression_dependencies sed
INNER JOIN sys.objects o ON sed.referencing_id = o.object_id
WHERE sed.referenced_id = OBJECT_ID('Customer')
AND o.type = 'P';  -- Stored procedures
GO

PRINT '=== Functions Using Customer ===';
SELECT DISTINCT
    OBJECT_NAME(sed.referencing_id) AS FunctionName,
    o.type_desc AS ObjectType
FROM sys.sql_expression_dependencies sed
INNER JOIN sys.objects o ON sed.referencing_id = o.object_id
WHERE sed.referenced_id = OBJECT_ID('Customer')
AND o.type IN ('FN', 'IF', 'TF');  -- Functions
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. SYS CATALOG VIEWS
   - SQL Server-specific metadata
   - More detailed than INFORMATION_SCHEMA
   - Access to advanced features
   - Better performance metadata

2. KEY VIEWS
   - sys.tables: Table metadata
   - sys.columns: Column details
   - sys.indexes: Index information
   - sys.foreign_keys: FK constraints
   - sys.objects: All objects
   - sys.sql_expression_dependencies: Dependencies

3. SYSTEM PROCEDURES
   - sp_help: Quick object overview
   - sp_columns: Column details
   - sp_helpindex: Index info
   - sp_helpconstraint: Constraints
   - sp_spaceused: Size information
   - sp_depends: Dependencies

4. DYNAMIC MANAGEMENT VIEWS (DMVs)
   - Runtime and performance data
   - sys.dm_db_index_usage_stats: Index usage
   - sys.dm_db_partition_stats: Table sizes
   - sys.dm_db_missing_index_*: Missing indexes
   - Real-time operational metadata

5. BEST PRACTICES
   - Filter is_ms_shipped = 0 to exclude system objects
   - Use OBJECT_NAME() to convert IDs to names
   - Cache metadata for repeated queries
   - Combine sys views for complete picture
   - Use DMVs for performance analysis

6. ADVANTAGES OVER INFORMATION_SCHEMA
   - SQL Server-specific features
   - Index metadata
   - Performance statistics
   - Dependencies tracking
   - Extended properties
   - More object types

7. WHEN TO USE SYS VIEWS
   - SQL Server-only environments
   - Need index information
   - Performance tuning
   - Dependency analysis
   - Advanced features
   - DBA automation

8. COMMON PATTERNS
   - Join sys.tables + sys.columns for table structure
   - Join sys.indexes + sys.index_columns for index details
   - Use sys.foreign_keys for relationships
   - Query DMVs for performance data
   - Use system procedures for quick checks

================================================================================

NEXT STEPS:
-----------
In Lesson 15.4, we'll explore SCHEMA GENERATION SCRIPTS:
- Generating CREATE TABLE scripts
- Building data dictionaries
- Automating documentation
- Reverse engineering schemas

Continue to: 04-schema-generation-scripts/lesson.sql

================================================================================
*/
