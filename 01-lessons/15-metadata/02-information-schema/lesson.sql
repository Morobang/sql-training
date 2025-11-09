/*
================================================================================
LESSON 15.2: INFORMATION_SCHEMA
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Query INFORMATION_SCHEMA views effectively
2. Understand standard metadata views
3. Work with TABLES, COLUMNS, CONSTRAINTS views
4. Query routines and view definitions
5. Build portable metadata queries
6. Compare schemas across databases
7. Apply best practices for metadata queries

Business Context:
-----------------
INFORMATION_SCHEMA provides ANSI-standard metadata views that work across
different database systems (SQL Server, MySQL, PostgreSQL, Oracle). This
portability is valuable for multi-database environments and migrations.
Understanding these views is essential for database documentation and automation.

Database: RetailStore
Complexity: Beginner-Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: INFORMATION_SCHEMA.TABLES
================================================================================

Lists all tables and views in the database.
*/

-- Create sample tables for examples
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200),
    Region NVARCHAR(50),
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE)
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

-- Create a view for examples
CREATE VIEW CustomerOrders AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customer c
INNER JOIN [Order] o ON c.CustomerID = o.CustomerID;
GO

-- Example 1: List all tables
SELECT 
    TABLE_CATALOG AS DatabaseName,
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS TableName,
    TABLE_TYPE AS Type
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_NAME;
GO

/*
OUTPUT:
DatabaseName    SchemaName  TableName    Type
--------------  ----------  -----------  ----------
RetailStore     dbo         Customer     BASE TABLE
RetailStore     dbo         CustomerOrders VIEW
RetailStore     dbo         Order        BASE TABLE
RetailStore     dbo         OrderItem    BASE TABLE
RetailStore     dbo         Product      BASE TABLE

Shows both tables (BASE TABLE) and views (VIEW)!
*/

-- Example 2: List only tables (no views)
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

/*
OUTPUT:
TABLE_SCHEMA  TABLE_NAME
------------  ----------
dbo           Customer
dbo           Order
dbo           OrderItem
dbo           Product
*/

-- Example 3: List only views
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'VIEW'
ORDER BY TABLE_NAME;
GO

/*
OUTPUT:
TABLE_SCHEMA  TABLE_NAME
------------  --------------
dbo           CustomerOrders
*/

-- Example 4: Count tables by schema
SELECT 
    TABLE_SCHEMA,
    COUNT(*) AS TableCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
GROUP BY TABLE_SCHEMA
ORDER BY TableCount DESC;
GO

/*
================================================================================
PART 2: INFORMATION_SCHEMA.COLUMNS
================================================================================

Provides detailed information about all columns in tables and views.
*/

-- Example 1: List all columns for a specific table
SELECT 
    ORDINAL_POSITION AS Position,
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS Nullable,
    COLUMN_DEFAULT AS DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customer'
ORDER BY ORDINAL_POSITION;
GO

/*
OUTPUT:
Position  ColumnName     DataType    MaxLength  Nullable  DefaultValue
--------  -------------  ----------  ---------  --------  -----------------
1         CustomerID     int         NULL       NO        NULL
2         CustomerName   nvarchar    200        NO        NULL
3         Email          nvarchar    200        YES       NULL
4         Region         nvarchar    50         YES       NULL
5         CreatedDate    date        NULL       YES       (getdate())

Complete column metadata!
*/

-- Example 2: Find all NVARCHAR columns
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CHARACTER_MAXIMUM_LENGTH AS Length
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE = 'nvarchar'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

/*
OUTPUT:
TABLE_NAME   COLUMN_NAME      Length
-----------  ---------------  ------
Customer     CustomerName     200
Customer     Email            200
Customer     Region           50
Product      ProductName      200
*/

-- Example 3: Find all nullable columns
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE IS_NULLABLE = 'YES'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO

/*
OUTPUT:
TABLE_NAME   COLUMN_NAME     DATA_TYPE
-----------  --------------  ---------
Customer     Email           nvarchar
Customer     Region          nvarchar
Customer     CreatedDate     date
Order        TotalAmount     decimal
*/

-- Example 4: Generate data dictionary
SELECT 
    c.TABLE_NAME AS [Table],
    c.COLUMN_NAME AS [Column],
    c.DATA_TYPE AS [Type],
    CASE 
        WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL 
        THEN c.DATA_TYPE + '(' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ')'
        WHEN c.DATA_TYPE IN ('decimal', 'numeric')
        THEN c.DATA_TYPE + '(' + CAST(c.NUMERIC_PRECISION AS VARCHAR(10)) + ',' + 
             CAST(c.NUMERIC_SCALE AS VARCHAR(10)) + ')'
        ELSE c.DATA_TYPE
    END AS [FullType],
    c.IS_NULLABLE AS [Nullable],
    ISNULL(c.COLUMN_DEFAULT, '') AS [Default]
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t 
    ON c.TABLE_NAME = t.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
GO

/*
OUTPUT:
Table       Column         Type      FullType        Nullable  Default
----------  -------------  --------  --------------  --------  --------
Customer    CustomerID     int       int             NO        
Customer    CustomerName   nvarchar  nvarchar(200)   NO        
Customer    Email          nvarchar  nvarchar(200)   YES       
Customer    Region         nvarchar  nvarchar(50)    YES       
Customer    CreatedDate    date      date            YES       (getdate())
...

Professional data dictionary!
*/

-- Example 5: Find columns by pattern
SELECT 
    TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%ID'  -- All ID columns
ORDER BY TABLE_NAME, COLUMN_NAME;
GO

/*
OUTPUT:
TABLE_NAME   COLUMN_NAME
-----------  ------------
Customer     CustomerID
Order        CustomerID
Order        OrderID
OrderItem    OrderID
OrderItem    OrderItemID
OrderItem    ProductID
Product      ProductID

All primary and foreign key columns!
*/

/*
================================================================================
PART 3: INFORMATION_SCHEMA.CONSTRAINTS
================================================================================

Information about table constraints (PK, FK, UNIQUE, CHECK, DEFAULT).
*/

-- Example 1: List all constraints
SELECT 
    CONSTRAINT_CATALOG AS DatabaseName,
    CONSTRAINT_SCHEMA AS SchemaName,
    CONSTRAINT_NAME AS ConstraintName,
    TABLE_NAME AS TableName,
    CONSTRAINT_TYPE AS Type
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;
GO

/*
OUTPUT:
DatabaseName  SchemaName  ConstraintName                 TableName    Type
------------  ----------  -----------------------------  -----------  ------------
RetailStore   dbo         PK__Customer__A4AE64B8...       Customer     PRIMARY KEY
RetailStore   dbo         FK__Order__CustomerID__...     Order        FOREIGN KEY
RetailStore   dbo         PK__Order__C3905BAF...         Order        PRIMARY KEY
RetailStore   dbo         FK__OrderItem__OrderID__...    OrderItem    FOREIGN KEY
RetailStore   dbo         FK__OrderItem__ProductID__...  OrderItem    FOREIGN KEY
RetailStore   dbo         PK__OrderItem__57ED06A1...     OrderItem    PRIMARY KEY
RetailStore   dbo         PK__Product__B40CC6ED...       Product      PRIMARY KEY

All constraint types listed!
*/

-- Example 2: Find all primary keys
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY TABLE_NAME;
GO

/*
OUTPUT:
TABLE_NAME   CONSTRAINT_NAME
-----------  ---------------------------
Customer     PK__Customer__A4AE64B8...
Order        PK__Order__C3905BAF...
OrderItem    PK__OrderItem__57ED06A1...
Product      PK__Product__B40CC6ED...
*/

-- Example 3: Find all foreign keys
SELECT 
    tc.TABLE_NAME AS TableName,
    tc.CONSTRAINT_NAME AS ForeignKeyName,
    rc.UNIQUE_CONSTRAINT_NAME AS ReferencesConstraint
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
    ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
ORDER BY tc.TABLE_NAME;
GO

/*
OUTPUT:
TableName    ForeignKeyName                  ReferencesConstraint
-----------  ------------------------------  -----------------------
Order        FK__Order__CustomerID__...      PK__Customer__A4AE...
OrderItem    FK__OrderItem__OrderID__...     PK__Order__C3905BAF...
OrderItem    FK__OrderItem__ProductID__...   PK__Product__B40CC6ED...

Foreign key relationships!
*/

/*
================================================================================
PART 4: INFORMATION_SCHEMA.KEY_COLUMN_USAGE
================================================================================

Details about columns in constraints (which columns are part of keys).
*/

-- Example 1: Find primary key columns
SELECT 
    kcu.TABLE_NAME AS TableName,
    kcu.COLUMN_NAME AS PKColumn,
    kcu.CONSTRAINT_NAME AS ConstraintName
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY kcu.TABLE_NAME;
GO

/*
OUTPUT:
TableName    PKColumn       ConstraintName
-----------  -------------  ---------------------------
Customer     CustomerID     PK__Customer__A4AE64B8...
Order        OrderID        PK__Order__C3905BAF...
OrderItem    OrderItemID    PK__OrderItem__57ED06A1...
Product      ProductID      PK__Product__B40CC6ED...
*/

-- Example 2: Find foreign key columns with references
SELECT 
    kcu.TABLE_NAME AS TableName,
    kcu.COLUMN_NAME AS FKColumn,
    ccu.TABLE_NAME AS ReferencedTable,
    ccu.COLUMN_NAME AS ReferencedColumn
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
    ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
    ON rc.UNIQUE_CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
ORDER BY kcu.TABLE_NAME, kcu.COLUMN_NAME;
GO

/*
OUTPUT:
TableName    FKColumn      ReferencedTable  ReferencedColumn
-----------  ------------  ---------------  ----------------
Order        CustomerID    Customer         CustomerID
OrderItem    OrderID       Order            OrderID
OrderItem    ProductID     Product          ProductID

Complete foreign key mapping!
*/

/*
================================================================================
PART 5: INFORMATION_SCHEMA.ROUTINES
================================================================================

Information about stored procedures and functions.
*/

-- Create sample stored procedure
CREATE PROCEDURE usp_GetCustomerOrders
    @CustomerID INT
AS
BEGIN
    SELECT * FROM [Order]
    WHERE CustomerID = @CustomerID;
END;
GO

-- Create sample function
CREATE FUNCTION fn_GetCustomerOrderCount(@CustomerID INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM [Order] WHERE CustomerID = @CustomerID);
END;
GO

-- Example 1: List all routines
SELECT 
    ROUTINE_SCHEMA AS SchemaName,
    ROUTINE_NAME AS RoutineName,
    ROUTINE_TYPE AS Type,
    DATA_TYPE AS ReturnType,
    CREATED AS CreatedDate,
    LAST_ALTERED AS LastModified
FROM INFORMATION_SCHEMA.ROUTINES
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;
GO

/*
OUTPUT:
SchemaName  RoutineName                Type        ReturnType  CreatedDate  LastModified
----------  -------------------------  ----------  ----------  -----------  ------------
dbo         fn_GetCustomerOrderCount   FUNCTION    int         2024-11-09   2024-11-09
dbo         usp_GetCustomerOrders      PROCEDURE   NULL        2024-11-09   2024-11-09
*/

-- Example 2: Find procedures by name pattern
SELECT ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_NAME LIKE 'usp_Get%'
ORDER BY ROUTINE_NAME;
GO

/*
================================================================================
PART 6: INFORMATION_SCHEMA.VIEWS
================================================================================

Information about view definitions.
*/

-- Example 1: List all views
SELECT 
    TABLE_SCHEMA AS SchemaName,
    TABLE_NAME AS ViewName,
    VIEW_DEFINITION AS Definition
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME;
GO

/*
OUTPUT:
SchemaName  ViewName         Definition
----------  ---------------  --------------------------------
dbo         CustomerOrders   CREATE VIEW CustomerOrders AS...

View source code!
*/

-- Example 2: Find views that reference a specific table
SELECT DISTINCT TABLE_NAME AS ViewName
FROM INFORMATION_SCHEMA.VIEW_COLUMN_USAGE
WHERE VIEW_COLUMN_USAGE.TABLE_NAME IN ('Customer', 'Order')
ORDER BY ViewName;
GO

/*
================================================================================
PART 7: PRACTICAL METADATA QUERIES
================================================================================
*/

-- Query 1: Complete table documentation
SELECT 
    t.TABLE_NAME AS TableName,
    c.COLUMN_NAME AS ColumnName,
    c.ORDINAL_POSITION AS Position,
    c.DATA_TYPE AS DataType,
    c.CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    c.IS_NULLABLE AS Nullable,
    CASE 
        WHEN pk.COLUMN_NAME IS NOT NULL THEN 'PK'
        WHEN fk.COLUMN_NAME IS NOT NULL THEN 'FK'
        ELSE ''
    END AS KeyType,
    c.COLUMN_DEFAULT AS DefaultValue
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_NAME = c.TABLE_NAME
LEFT JOIN (
    SELECT kcu.TABLE_NAME, kcu.COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
        ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
    WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
) pk ON c.TABLE_NAME = pk.TABLE_NAME AND c.COLUMN_NAME = pk.COLUMN_NAME
LEFT JOIN (
    SELECT kcu.TABLE_NAME, kcu.COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
        ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
    WHERE tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
) fk ON c.TABLE_NAME = fk.TABLE_NAME AND c.COLUMN_NAME = fk.COLUMN_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION;
GO

-- Query 2: Find tables without primary keys
SELECT t.TABLE_NAME AS TableWithoutPK
FROM INFORMATION_SCHEMA.TABLES t
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND NOT EXISTS (
      SELECT 1 
      FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
      WHERE tc.TABLE_NAME = t.TABLE_NAME
        AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
  )
ORDER BY t.TABLE_NAME;
GO

-- Query 3: Relationship diagram data
SELECT 
    fk.TABLE_NAME AS FromTable,
    kcu.COLUMN_NAME AS FromColumn,
    ccu.TABLE_NAME AS ToTable,
    ccu.COLUMN_NAME AS ToColumn,
    rc.UPDATE_RULE AS OnUpdate,
    rc.DELETE_RULE AS OnDelete
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS fk
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON fk.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
    ON fk.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
    ON rc.UNIQUE_CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
WHERE fk.CONSTRAINT_TYPE = 'FOREIGN KEY'
ORDER BY fk.TABLE_NAME, kcu.COLUMN_NAME;
GO

/*
OUTPUT:
FromTable    FromColumn   ToTable   ToColumn    OnUpdate      OnDelete
-----------  -----------  --------  ----------  ------------  ------------
Order        CustomerID   Customer  CustomerID  NO ACTION     NO ACTION
OrderItem    OrderID      Order     OrderID     NO ACTION     NO ACTION
OrderItem    ProductID    Product   ProductID   NO ACTION     NO ACTION

Complete relationship mapping!
*/

-- Query 4: Column statistics
SELECT 
    DATA_TYPE,
    COUNT(*) AS ColumnCount,
    COUNT(DISTINCT TABLE_NAME) AS TableCount
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_TYPE = 'BASE TABLE'
)
GROUP BY DATA_TYPE
ORDER BY ColumnCount DESC;
GO

/*
OUTPUT:
DATA_TYPE   ColumnCount  TableCount
----------  -----------  ----------
int         8            4
nvarchar    4            2
decimal     3            2
date        2            2

Data type usage statistics!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Schema Report
-------------------------
Create a comprehensive schema report showing:
- All tables
- Column count per table
- Primary key column(s)
- Foreign key count
- Row estimate (use sp_spaceused or similar)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Find Orphaned Indexes
----------------------------------
Write a query to find all indexes that are not:
- Primary keys
- Foreign keys
- Unique constraints

Use INFORMATION_SCHEMA views.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Data Type Validation
---------------------------------
Create a query that finds all columns with data types that might need review:
- NVARCHAR columns with MAX length
- TEXT/NTEXT columns (deprecated)
- VARCHAR vs NVARCHAR inconsistencies
- Columns with very large max lengths (> 1000)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Schema Report
SELECT 
    t.TABLE_NAME AS TableName,
    COUNT(DISTINCT c.COLUMN_NAME) AS ColumnCount,
    STRING_AGG(CASE WHEN tc.CONSTRAINT_TYPE = 'PRIMARY KEY' 
                    THEN kcu.COLUMN_NAME END, ', ') AS PrimaryKeyColumns,
    COUNT(DISTINCT CASE WHEN tc.CONSTRAINT_TYPE = 'FOREIGN KEY' 
                        THEN tc.CONSTRAINT_NAME END) AS ForeignKeyCount
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_NAME = c.TABLE_NAME
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
    ON c.TABLE_NAME = kcu.TABLE_NAME 
    AND c.COLUMN_NAME = kcu.COLUMN_NAME
LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
    ON kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
GROUP BY t.TABLE_NAME
ORDER BY t.TABLE_NAME;
GO

-- Solution 2: Find Orphaned Indexes
-- Note: INFORMATION_SCHEMA doesn't have index info
-- This would require sys.indexes - shown for educational purposes
PRINT 'Note: INFORMATION_SCHEMA does not expose index metadata.';
PRINT 'Index information requires sys.indexes (covered in next lesson).';
PRINT 'INFORMATION_SCHEMA is limited to constraints (PK, FK, UNIQUE).';
GO

-- What we CAN do with INFORMATION_SCHEMA:
SELECT 
    c.TABLE_NAME,
    c.COLUMN_NAME,
    'Not in any constraint' AS Status
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    WHERE kcu.TABLE_NAME = c.TABLE_NAME 
      AND kcu.COLUMN_NAME = c.COLUMN_NAME
)
AND c.TABLE_NAME IN (
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_TYPE = 'BASE TABLE'
)
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;
GO

-- Solution 3: Data Type Validation
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    CASE 
        WHEN DATA_TYPE IN ('text', 'ntext', 'image') 
            THEN 'Deprecated type - use VARCHAR(MAX)'
        WHEN DATA_TYPE IN ('varchar', 'nvarchar') 
             AND CHARACTER_MAXIMUM_LENGTH = -1 
            THEN 'Using MAX - review if necessary'
        WHEN DATA_TYPE IN ('varchar', 'nvarchar') 
             AND CHARACTER_MAXIMUM_LENGTH > 1000 
            THEN 'Very large max length - review'
        ELSE 'OK'
    END AS ValidationStatus
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
    DATA_TYPE IN ('text', 'ntext', 'image')
    OR (DATA_TYPE IN ('varchar', 'nvarchar') AND CHARACTER_MAXIMUM_LENGTH = -1)
    OR (DATA_TYPE IN ('varchar', 'nvarchar') AND CHARACTER_MAXIMUM_LENGTH > 1000)
ORDER BY ValidationStatus, TABLE_NAME, COLUMN_NAME;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. INFORMATION_SCHEMA VIEWS
   - ANSI-standard metadata views
   - Portable across database systems
   - Limited to basic schema information
   - Easy to understand and use

2. MAIN VIEWS
   - TABLES: List tables and views
   - COLUMNS: Column details and data types
   - TABLE_CONSTRAINTS: Constraint information
   - KEY_COLUMN_USAGE: Columns in constraints
   - REFERENTIAL_CONSTRAINTS: Foreign key details
   - ROUTINES: Stored procedures and functions
   - VIEWS: View definitions

3. COMMON PATTERNS
   - Filter by TABLE_TYPE ('BASE TABLE' vs 'VIEW')
   - Join multiple views for complete picture
   - Use ORDINAL_POSITION for column order
   - Check IS_NULLABLE for nullability
   - Combine with sys views for more details

4. LIMITATIONS
   - No index information
   - No performance statistics
   - Limited to schema metadata
   - Some SQL Server features not exposed
   - Use sys views for advanced features

5. BEST PRACTICES
   - Use for portable queries
   - Filter out system objects
   - Handle NULLs appropriately
   - Combine views for relationships
   - Cache results if querying repeatedly

6. PORTABILITY
   - Works on MySQL, PostgreSQL, Oracle
   - Same view names across platforms
   - Some column differences by platform
   - Test queries on target platform

7. WHEN TO USE
   - Cross-platform applications
   - Basic schema documentation
   - Simple metadata queries
   - Learning metadata concepts
   - Portable scripts

8. WHEN NOT TO USE
   - Need index information
   - Need performance statistics
   - SQL Server-specific features
   - Real-time operational data
   - Complex dependency analysis

================================================================================

NEXT STEPS:
-----------
In Lesson 15.3, we'll explore SQL Server-specific METADATA:
- sys catalog views
- Extended metadata
- Performance information
- Dependencies and more

Continue to: 03-working-with-metadata/lesson.sql

================================================================================
*/
