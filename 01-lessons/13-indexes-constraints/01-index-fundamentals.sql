/*
================================================================================
LESSON 13.1: INDEX FUNDAMENTALS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will understand:
1. What indexes are and why they are important
2. How indexes work internally (B-Tree structure)
3. The benefits and costs of using indexes
4. Clustered vs. nonclustered indexes
5. When to use indexes and when not to
6. How indexes affect query performance
7. Index storage and organization

Business Context:
-----------------
Imagine a library with thousands of books. Without a catalog or organized 
system, finding a specific book would require searching through every shelf. 
An index card catalog makes finding books nearly instantaneous.

Database indexes work the same way - they provide quick access paths to data,
dramatically improving query performance. Understanding indexes is crucial for
building high-performance applications.

Database: RetailStore
Complexity: Beginner to Intermediate
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT ARE INDEXES?
================================================================================

An index is a database object that provides quick access to rows in a table.
Think of it like an index in a book - it helps you find information quickly
without reading every page.

Key Points:
-----------
- Indexes are separate structures from the table data
- They contain sorted copies of column(s) with pointers to actual rows
- SQL Server automatically maintains indexes when data changes
- Indexes speed up SELECT queries but slow down INSERT/UPDATE/DELETE

*/

-- Let's start by creating a table to demonstrate index concepts
DROP TABLE IF EXISTS Customer;
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1),
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    Email NVARCHAR(100),
    City NVARCHAR(50),
    Country NVARCHAR(50),
    DateOfBirth DATE,
    AccountBalance DECIMAL(10,2),
    RegistrationDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
GO

-- Insert sample data (10,000 customers for realistic demonstration)
DECLARE @i INT = 1;
WHILE @i <= 10000
BEGIN
    INSERT INTO Customer (FirstName, LastName, Email, City, Country, DateOfBirth, AccountBalance)
    VALUES (
        'FirstName' + CAST(@i AS VARCHAR(10)),
        'LastName' + CAST(@i AS VARCHAR(10)),
        'customer' + CAST(@i AS VARCHAR(10)) + '@email.com',
        CASE (@i % 10) 
            WHEN 0 THEN 'New York'
            WHEN 1 THEN 'Los Angeles'
            WHEN 2 THEN 'Chicago'
            WHEN 3 THEN 'Houston'
            WHEN 4 THEN 'Phoenix'
            WHEN 5 THEN 'Philadelphia'
            WHEN 6 THEN 'San Antonio'
            WHEN 7 THEN 'San Diego'
            WHEN 8 THEN 'Dallas'
            ELSE 'San Jose'
        END,
        CASE (@i % 5)
            WHEN 0 THEN 'USA'
            WHEN 1 THEN 'Canada'
            WHEN 2 THEN 'Mexico'
            WHEN 3 THEN 'UK'
            ELSE 'Australia'
        END,
        DATEADD(YEAR, -(@i % 50 + 18), GETDATE()),
        (@i * 10.50) % 10000
    );
    SET @i = @i + 1;
END
GO

-- Check the data
SELECT TOP 10 * FROM Customer;
GO

/*
OUTPUT (sample):
CustomerID  FirstName    LastName     Email                   City        Country
----------  -----------  -----------  ---------------------   ----------  --------
1           FirstName1   LastName1    customer1@email.com     Los Angeles Canada
2           FirstName2   LastName2    customer2@email.com     Chicago     Mexico
3           FirstName3   LastName3    customer3@email.com     Houston     UK
...
*/

/*
================================================================================
PART 2: HOW INDEXES WORK - B-TREE STRUCTURE
================================================================================

Indexes use a B-Tree (Balanced Tree) structure:

Visual Representation:
----------------------
                    [M]
                   /   \
                  /     \
              [E-L]     [N-T]
             /  |  \   /  |  \
           [A] [F] [J][N][Q][U]
           
Each node contains:
1. Key values (sorted)
2. Pointers to child nodes or actual data rows

Benefits of B-Tree:
- Balanced: All paths from root to leaf have same length
- Logarithmic search: O(log n) performance
- Self-maintaining: Automatically reorganizes on changes

*/

-- Example: Search WITHOUT an index (Table Scan)
-- This query must read EVERY row to find matching records

-- Enable actual execution plan (Ctrl+M in SSMS) to see the difference
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT * 
FROM Customer 
WHERE LastName = 'LastName5000';
GO

/*
OUTPUT:
Table 'Customer'. Scan count 1, logical reads 50-100+
CPU time = X ms, elapsed time = Y ms

EXPLANATION:
- Scan count 1: Table scanned once
- Logical reads: Number of 8KB pages read from memory
- Without index, SQL Server must scan entire table
*/

-- Now let's see the execution plan details
-- In SSMS: Click "Display Estimated Execution Plan" or press Ctrl+L

/*
Execution Plan (WITHOUT INDEX):
-------------------------------
[Table Scan] - Cost: 100%
├── Operator: Table Scan
├── Object: Customer
├── Estimated Rows: 10,000
└── Actual Rows Read: 10,000

The query engine reads ALL 10,000 rows to find the matching record(s).
*/

/*
================================================================================
PART 3: BENEFITS AND COSTS OF INDEXES
================================================================================

BENEFITS:
---------
✅ Faster SELECT queries (especially with WHERE, JOIN, ORDER BY)
✅ Quicker sorting and grouping operations
✅ Faster MIN, MAX, and aggregate calculations
✅ Enforces uniqueness (UNIQUE indexes)
✅ Supports constraints (PRIMARY KEY, FOREIGN KEY)

COSTS:
------
❌ Additional disk space (each index stores data copy)
❌ Slower INSERT operations (must update indexes)
❌ Slower UPDATE operations (if indexed columns change)
❌ Slower DELETE operations (must remove from indexes)
❌ Maintenance overhead (fragmentation, rebuilds)

*/

-- Let's measure the impact of indexes on different operations

-- Create a table to track performance metrics
DROP TABLE IF EXISTS PerformanceTest;
GO

CREATE TABLE PerformanceTest (
    TestID INT IDENTITY(1,1),
    Operation VARCHAR(50),
    HasIndex BIT,
    DurationMS INT,
    LogicalReads INT,
    TestDate DATETIME DEFAULT GETDATE()
);
GO

-- Test 1: SELECT without index
DECLARE @StartTime DATETIME = GETDATE();
SELECT * FROM Customer WHERE Email = 'customer5000@email.com';
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());

INSERT INTO PerformanceTest (Operation, HasIndex, DurationMS)
VALUES ('SELECT by Email', 0, @Duration);
GO

-- Test 2: INSERT without additional indexes (only default constraints)
DECLARE @StartTime DATETIME = GETDATE();
INSERT INTO Customer (FirstName, LastName, Email, City, Country, DateOfBirth, AccountBalance)
VALUES ('Test', 'User', 'testuser@email.com', 'Seattle', 'USA', '1990-01-01', 100.00);
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());

INSERT INTO PerformanceTest (Operation, HasIndex, DurationMS)
VALUES ('INSERT', 0, @Duration);
GO

-- Delete the test record
DELETE FROM Customer WHERE Email = 'testuser@email.com';
GO

/*
We'll compare these metrics after adding indexes in the next parts.
*/

/*
================================================================================
PART 4: CLUSTERED INDEXES
================================================================================

CLUSTERED INDEX:
----------------
- Determines the physical order of data in the table
- Only ONE clustered index per table
- Leaf nodes contain the actual data rows
- Often created on the primary key

Visual Representation:
----------------------
Clustered Index on CustomerID:

Level 2 (Root):        [5000]
                      /      \
Level 1:         [2500]      [7500]
                 /    \      /    \
Level 0 (Data): [1..2499] [2500..4999] [5000..7499] [7500..10000]
                [Actual    [Actual      [Actual      [Actual
                 Rows]      Rows]        Rows]        Rows]

The data IS the leaf level of the index!
*/

-- By default, PRIMARY KEY creates a clustered index
ALTER TABLE Customer
ADD CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (CustomerID);
GO

-- Let's verify what indexes now exist
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id 
    AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Customer')
ORDER BY i.name;
GO

/*
OUTPUT:
IndexName      IndexType    IsUnique  ColumnName
-------------  ----------   --------  -----------
PK_Customer    CLUSTERED    1         CustomerID

EXPLANATION:
- PK_Customer is the constraint name
- CLUSTERED means it controls physical data order
- IsUnique = 1 because primary keys are unique
- Built on CustomerID column
*/

-- Now test the same query with clustered index
SELECT * 
FROM Customer 
WHERE CustomerID = 5000;
GO

/*
Execution Plan (WITH CLUSTERED INDEX on CustomerID):
----------------------------------------------------
[Clustered Index Seek] - Cost: 0.003%
├── Operator: Clustered Index Seek
├── Object: PK_Customer
├── Seek Predicates: CustomerID = 5000
├── Estimated Rows: 1
└── Actual Rows Read: 1

HUGE IMPROVEMENT! Only 1 row read instead of 10,000!
*/

/*
================================================================================
PART 5: NONCLUSTERED INDEXES
================================================================================

NONCLUSTERED INDEX:
-------------------
- Separate structure from the table data
- Can have multiple nonclustered indexes per table (up to 999)
- Leaf nodes contain index keys + row locator (pointer to data)
- Don't change physical data order

Visual Representation:
----------------------
Nonclustered Index on LastName:

Level 2 (Root):           [LastName5000]
                         /              \
Level 1:        [LastName2500]      [LastName7500]
                /              \    /              \
Leaf Level: [LastName1→]  [LastName2501→] [LastName5001→] [LastName7501→]
            [Pointers to   [Pointers to    [Pointers to    [Pointers to
             actual rows]   actual rows]    actual rows]    actual rows]

The leaf level contains pointers to data, not the data itself!
*/

-- Create a nonclustered index on LastName
CREATE NONCLUSTERED INDEX IX_Customer_LastName
ON Customer(LastName);
GO

-- Test the query again
SELECT * 
FROM Customer 
WHERE LastName = 'LastName5000';
GO

/*
Execution Plan (WITH NONCLUSTERED INDEX on LastName):
-----------------------------------------------------
[Index Seek] → [Key Lookup]
     ↓              ↓
[IX_Customer_  [PK_Customer]
 LastName]

Two operations:
1. Index Seek: Find matching entry in nonclustered index
2. Key Lookup: Use pointer to fetch full row from clustered index

Still much faster than table scan, but not as fast as clustered index seek!
*/

-- Let's see all indexes now
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id 
    AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Customer')
ORDER BY i.name, ic.key_ordinal;
GO

/*
OUTPUT:
IndexName                IndexType         IsUnique  ColumnName
----------------------   ---------------   --------  -----------
IX_Customer_LastName     NONCLUSTERED      0         LastName
PK_Customer              CLUSTERED         1         CustomerID
*/

/*
================================================================================
PART 6: CLUSTERED VS NONCLUSTERED COMPARISON
================================================================================

Feature                  CLUSTERED                NONCLUSTERED
--------------------     -------------------      --------------------
Quantity per table       1                        Up to 999
Data organization        Physical sort order      Logical sort order
Leaf level contains      Actual data rows         Index keys + pointers
Space overhead           None (is the data)       Additional space
Insert performance       Can be slow              Faster inserts
Update performance       Slow if key changes      Slow if indexed col changes
Range queries            Excellent                Good
Point queries            Excellent                Good (requires lookup)
Best for                 Primary key, ranges      Foreign keys, lookups

*/

-- Practical example: Range queries with clustered vs nonclustered

-- Range query on CustomerID (clustered index)
SELECT * 
FROM Customer 
WHERE CustomerID BETWEEN 1000 AND 1100
ORDER BY CustomerID;
GO

/*
Execution Plan:
[Clustered Index Seek] - Very efficient!
└── Rows are already in CustomerID order
*/

-- Range query on LastName (nonclustered index)
SELECT * 
FROM Customer 
WHERE LastName BETWEEN 'LastName1000' AND 'LastName1100'
ORDER BY LastName;
GO

/*
Execution Plan:
[Index Seek] → [Key Lookup] (repeated 100+ times)
└── Must look up each row individually - less efficient
*/

/*
================================================================================
PART 7: WHEN TO USE INDEXES
================================================================================

GOOD CANDIDATES FOR INDEXES:
-----------------------------
✅ Primary key columns (usually automatic)
✅ Foreign key columns (for joins)
✅ Columns frequently used in WHERE clauses
✅ Columns used in ORDER BY clauses
✅ Columns used in GROUP BY clauses
✅ Columns with high selectivity (many unique values)

POOR CANDIDATES FOR INDEXES:
-----------------------------
❌ Small tables (< 1000 rows) - table scan is fine
❌ Columns with low selectivity (e.g., Gender with M/F)
❌ Columns rarely used in queries
❌ Tables with heavy INSERT/UPDATE/DELETE workload
❌ Very wide columns (large VARCHAR, NVARCHAR)
❌ Columns that change frequently

*/

-- Example: Good index candidate (high selectivity)
SELECT 
    Email,
    COUNT(*) AS OccurrenceCount
FROM Customer
GROUP BY Email
HAVING COUNT(*) > 1;
GO

/*
OUTPUT:
(0 rows affected)

EXPLANATION:
Every email is unique - HIGH selectivity (10,000 unique values in 10,000 rows)
This is a GREAT candidate for an index!
*/

-- Example: Poor index candidate (low selectivity)
SELECT 
    Country,
    COUNT(*) AS CustomerCount
FROM Customer
GROUP BY Country;
GO

/*
OUTPUT:
Country      CustomerCount
-----------  -------------
USA          2000
Canada       2000
Mexico       2000
UK           2000
Australia    2000

EXPLANATION:
Only 5 distinct values in 10,000 rows - LOW selectivity
An index might not help much here.
*/

-- Create index on high-selectivity column
CREATE NONCLUSTERED INDEX IX_Customer_Email
ON Customer(Email);
GO

-- Test query performance
SELECT * 
FROM Customer 
WHERE Email = 'customer7500@email.com';
GO

/*
Execution Plan:
[Index Seek on IX_Customer_Email] → [Key Lookup]
└── Very fast! Found exact match quickly
*/

-- Don't create index on low-selectivity column (it's wasteful)
-- This is just for demonstration - we'll drop it immediately
CREATE NONCLUSTERED INDEX IX_Customer_Country
ON Customer(Country);
GO

SELECT * 
FROM Customer 
WHERE Country = 'USA';
GO

/*
Execution Plan may still use:
[Index Scan] or even [Table Scan]
└── Returns 2,000 rows (20% of table) - index may not be optimal
*/

-- Drop the inefficient index
DROP INDEX IX_Customer_Country ON Customer;
GO

/*
================================================================================
PART 8: INDEX STORAGE AND ORGANIZATION
================================================================================

Understanding how indexes are stored helps optimize database design.

Index Pages:
------------
- SQL Server stores data in 8KB pages
- Each page contains multiple rows (depending on row size)
- Pages are organized into extents (8 consecutive pages = 64KB)

*/

-- View index storage details
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ps.used_page_count AS UsedPages,
    ps.used_page_count * 8 AS UsedSpaceKB,
    ps.row_count AS RowCount,
    ps.used_page_count * 8.0 / 1024 AS UsedSpaceMB
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps
    ON i.object_id = ps.object_id
    AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Customer')
ORDER BY ps.used_page_count DESC;
GO

/*
OUTPUT (example):
IndexName              IndexType      UsedPages  UsedSpaceKB  RowCount  UsedSpaceMB
--------------------   ------------   ---------  -----------  --------  -----------
PK_Customer            CLUSTERED      245        1960         10000     1.91
IX_Customer_Email      NONCLUSTERED   89         712          10000     0.69
IX_Customer_LastName   NONCLUSTERED   89         712          10000     0.69

EXPLANATION:
- Clustered index is largest (contains all data)
- Nonclustered indexes are smaller (just key + pointer)
- Each nonclustered index adds ~0.7MB overhead
*/

/*
================================================================================
PART 9: INDEX IMPACT ON DML OPERATIONS
================================================================================

Every INSERT, UPDATE, DELETE must maintain all indexes.
Let's measure the actual impact.

*/

-- Measure INSERT performance with multiple indexes

-- Test INSERT with current indexes (3 total)
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @i INT = 1;

WHILE @i <= 1000
BEGIN
    INSERT INTO Customer (FirstName, LastName, Email, City, Country, DateOfBirth, AccountBalance)
    VALUES ('Bulk', 'Insert', 'bulk' + CAST(@i AS VARCHAR) + '@test.com', 
            'TestCity', 'TestCountry', '1995-01-01', 500.00);
    SET @i = @i + 1;
END

DECLARE @DurationWith INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
PRINT '1000 INSERTs with 3 indexes: ' + CAST(@DurationWith AS VARCHAR) + ' ms';
GO

/*
OUTPUT (example):
1000 INSERTs with 3 indexes: 450 ms
*/

-- Clean up test data
DELETE FROM Customer WHERE FirstName = 'Bulk';
GO

-- Drop nonclustered indexes temporarily
DROP INDEX IX_Customer_Email ON Customer;
DROP INDEX IX_Customer_LastName ON Customer;
GO

-- Test INSERT with only clustered index
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @i INT = 1;

WHILE @i <= 1000
BEGIN
    INSERT INTO Customer (FirstName, LastName, Email, City, Country, DateOfBirth, AccountBalance)
    VALUES ('Bulk', 'Insert', 'bulk' + CAST(@i AS VARCHAR) + '@test.com', 
            'TestCity', 'TestCountry', '1995-01-01', 500.00);
    SET @i = @i + 1;
END

DECLARE @DurationWithout INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
PRINT '1000 INSERTs with 1 index: ' + CAST(@DurationWithout AS VARCHAR) + ' ms';
GO

/*
OUTPUT (example):
1000 INSERTs with 1 index: 280 ms

COMPARISON:
- With 3 indexes: 450 ms
- With 1 index: 280 ms
- Overhead: ~60% slower with additional indexes!
*/

-- Clean up
DELETE FROM Customer WHERE FirstName = 'Bulk';
GO

-- Recreate the dropped indexes for future lessons
CREATE NONCLUSTERED INDEX IX_Customer_Email ON Customer(Email);
CREATE NONCLUSTERED INDEX IX_Customer_LastName ON Customer(LastName);
GO

/*
================================================================================
PART 10: REAL-WORLD EXAMPLE - E-COMMERCE ORDER SEARCH
================================================================================

Let's apply index fundamentals to a realistic scenario.
*/

-- Create Orders table
DROP TABLE IF EXISTS [Order];
GO

CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1),
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2),
    Status VARCHAR(20),
    ShippingAddress NVARCHAR(200)
);
GO

-- Insert 50,000 orders
DECLARE @i INT = 1;
WHILE @i <= 50000
BEGIN
    INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount, Status, ShippingAddress)
    VALUES (
        (@i % 10000) + 1,  -- CustomerID between 1-10000
        DATEADD(DAY, -(@i % 365), GETDATE()),  -- Orders from past year
        (@i * 1.5) % 1000,  -- Random amount
        CASE (@i % 4)
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'Shipped'
            WHEN 2 THEN 'Delivered'
            ELSE 'Cancelled'
        END,
        'Address ' + CAST(@i AS VARCHAR)
    );
    SET @i = @i + 1;
END
GO

-- Common query: Find all orders for a customer
-- WITHOUT indexes (except auto-created identity)

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * 
FROM [Order] 
WHERE CustomerID = 5000;
GO

/*
OUTPUT:
Table 'Order'. Scan count 1, logical reads 500+
CPU time = X ms, elapsed time = Y ms

Table scan - very slow!
*/

-- Add primary key (clustered index on OrderID)
ALTER TABLE [Order]
ADD CONSTRAINT PK_Order PRIMARY KEY CLUSTERED (OrderID);
GO

-- The query still doesn't benefit because we're searching by CustomerID
SELECT * 
FROM [Order] 
WHERE CustomerID = 5000;
GO

/*
Still slow - clustered index on OrderID doesn't help CustomerID lookups!
*/

-- Add nonclustered index on CustomerID (the column we're searching)
CREATE NONCLUSTERED INDEX IX_Order_CustomerID
ON [Order](CustomerID);
GO

-- Now the query is fast!
SELECT * 
FROM [Order] 
WHERE CustomerID = 5000;
GO

/*
OUTPUT:
Table 'Order'. Scan count 1, logical reads 10-20
CPU time = Y ms (much less), elapsed time = Y ms (much less)

Execution Plan:
[Index Seek on IX_Order_CustomerID] → [Key Lookup on PK_Order]
└── Fast lookup!
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Index Analysis
--------------------------
Write a query to find all indexes on the Customer table and display:
- Index name
- Index type (clustered/nonclustered)
- Column(s) indexed
- Space used

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Performance Comparison
----------------------------------
Create a new table called Product with 20,000 rows.
Measure SELECT performance before and after adding an index on ProductName.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Index Selection
---------------------------
Given a table with columns: EmployeeID, FirstName, LastName, DepartmentID, 
HireDate, Salary. Which columns should be indexed and why?

Write your analysis:
*/

-- Your analysis here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Index Analysis
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
    ps.used_page_count * 8 AS SpaceUsedKB
FROM sys.indexes i
INNER JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.dm_db_partition_stats ps
    ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Customer')
ORDER BY i.name, ic.key_ordinal;
GO

/*
OUTPUT:
IndexName              IndexType      ColumnName   SpaceUsedKB
--------------------   ------------   ----------   -----------
IX_Customer_Email      NONCLUSTERED   Email        712
IX_Customer_LastName   NONCLUSTERED   LastName     712
PK_Customer            CLUSTERED      CustomerID   1960
*/

-- Solution 2: Performance Comparison
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1),
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2)
);
GO

-- Insert 20,000 products
DECLARE @i INT = 1;
WHILE @i <= 20000
BEGIN
    INSERT INTO Product (ProductName, Price)
    VALUES ('Product ' + CAST(@i AS VARCHAR), @i * 0.99);
    SET @i = @i + 1;
END
GO

-- Performance BEFORE index
SET STATISTICS TIME ON;
SELECT * FROM Product WHERE ProductName = 'Product 15000';
SET STATISTICS TIME OFF;
GO

-- Add index
CREATE NONCLUSTERED INDEX IX_Product_Name ON Product(ProductName);
GO

-- Performance AFTER index
SET STATISTICS TIME ON;
SELECT * FROM Product WHERE ProductName = 'Product 15000';
SET STATISTICS TIME OFF;
GO

/*
RESULTS:
Before index: 20-40 ms
After index: 1-2 ms
Improvement: 10-20x faster!
*/

-- Solution 3: Index Selection Analysis
/*
RECOMMENDED INDEXES:

1. EmployeeID:
   - PRIMARY KEY (clustered index)
   - Reason: Unique identifier, frequently used for lookups

2. DepartmentID:
   - NONCLUSTERED INDEX
   - Reason: Foreign key, used in joins and filtering by department

3. LastName + FirstName:
   - COMPOSITE NONCLUSTERED INDEX
   - Reason: Common search pattern (last name + first name)

4. HireDate:
   - NONCLUSTERED INDEX (maybe)
   - Reason: If date range queries are common

5. Salary:
   - Generally NO index
   - Reason: Continuously changing, not often used for exact matches

RATIONALE:
- Index primary and foreign keys always
- Index columns used frequently in WHERE, JOIN, ORDER BY
- Consider query patterns before indexing
- Don't over-index - balance read vs write performance
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. INDEXES ARE ESSENTIAL
   - Dramatically improve query performance
   - Critical for large tables and complex queries
   - Like a book index - provides quick access paths

2. B-TREE STRUCTURE
   - Balanced tree provides O(log n) performance
   - Self-maintaining and automatically reorganized
   - Efficient for both point and range queries

3. CLUSTERED VS NONCLUSTERED
   - Clustered: Only one per table, controls physical order
   - Nonclustered: Up to 999 per table, logical order
   - Choose clustered index wisely (usually primary key)

4. BENEFITS AND COSTS
   - Benefits: Faster SELECTs, better query optimization
   - Costs: Additional space, slower DML, maintenance overhead
   - Balance is key - too many or too few indexes both hurt performance

5. INDEX SELECTION STRATEGY
   - Index high-selectivity columns
   - Index foreign keys and primary keys
   - Index frequently queried columns
   - Avoid indexing low-selectivity or frequently changing columns

6. MEASURE PERFORMANCE
   - Use SET STATISTICS IO/TIME to measure impact
   - Check execution plans to verify index usage
   - Monitor before and after adding indexes
   - Remove unused or inefficient indexes

7. REAL-WORLD APPLICATION
   - Design indexes based on query patterns
   - Consider read vs write workload
   - Regular maintenance is essential
   - Test in development before production changes

================================================================================

NEXT STEPS:
-----------
In Lesson 13.2, we'll learn how to CREATE different types of indexes including:
- Single-column indexes
- Composite (multi-column) indexes
- Unique indexes
- Filtered indexes
- Covering indexes

Continue to: 02-creating-indexes.sql

================================================================================
*/
