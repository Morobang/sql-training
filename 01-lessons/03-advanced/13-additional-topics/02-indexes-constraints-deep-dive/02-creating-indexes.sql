/*
================================================================================
LESSON 13.2: CREATING INDEXES
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Create single-column indexes
2. Create composite (multi-column) indexes
3. Understand and create unique indexes
4. Implement covering indexes for query optimization
5. Create filtered indexes for specific scenarios
6. Use INCLUDE clause for optimal performance
7. Choose appropriate index types for different situations

Business Context:
-----------------
An e-commerce platform needs to optimize database performance for various
query patterns: product searches, order lookups, customer searches, and
reporting queries. Proper index design can reduce query time from seconds
to milliseconds, directly improving user experience and system capacity.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 50 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: SINGLE-COLUMN INDEXES
================================================================================

Single-column indexes are the simplest and most common type of index.
They index one column and are ideal for queries that filter or sort by
that specific column.

Syntax:
-------
CREATE [UNIQUE] [CLUSTERED | NONCLUSTERED] INDEX index_name
ON table_name (column_name)
[WITH options];

*/

-- Ensure we have our Customer table from previous lesson
-- If not, we'll recreate it

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customer')
BEGIN
    CREATE TABLE Customer (
        CustomerID INT IDENTITY(1,1) PRIMARY KEY,
        FirstName NVARCHAR(50),
        LastName NVARCHAR(50),
        Email NVARCHAR(100),
        Phone NVARCHAR(20),
        City NVARCHAR(50),
        State NVARCHAR(50),
        Country NVARCHAR(50),
        PostalCode NVARCHAR(10),
        DateOfBirth DATE,
        AccountBalance DECIMAL(10,2),
        RegistrationDate DATETIME DEFAULT GETDATE(),
        IsActive BIT DEFAULT 1
    );
    
    -- Insert sample data
    DECLARE @i INT = 1;
    WHILE @i <= 10000
    BEGIN
        INSERT INTO Customer (FirstName, LastName, Email, Phone, City, State, Country, PostalCode, DateOfBirth, AccountBalance)
        VALUES (
            'FirstName' + CAST(@i AS VARCHAR(10)),
            'LastName' + CAST(@i AS VARCHAR(10)),
            'customer' + CAST(@i AS VARCHAR(10)) + '@email.com',
            '555-' + RIGHT('000' + CAST(@i AS VARCHAR), 4),
            CASE (@i % 10) 
                WHEN 0 THEN 'New York' WHEN 1 THEN 'Los Angeles'
                WHEN 2 THEN 'Chicago' WHEN 3 THEN 'Houston'
                WHEN 4 THEN 'Phoenix' WHEN 5 THEN 'Philadelphia'
                WHEN 6 THEN 'San Antonio' WHEN 7 THEN 'San Diego'
                WHEN 8 THEN 'Dallas' ELSE 'San Jose'
            END,
            CASE (@i % 5)
                WHEN 0 THEN 'CA' WHEN 1 THEN 'TX'
                WHEN 2 THEN 'NY' WHEN 3 THEN 'FL'
                ELSE 'IL'
            END,
            CASE (@i % 5)
                WHEN 0 THEN 'USA' WHEN 1 THEN 'Canada'
                WHEN 2 THEN 'Mexico' WHEN 3 THEN 'UK'
                ELSE 'Australia'
            END,
            RIGHT('00000' + CAST(@i AS VARCHAR), 5),
            DATEADD(YEAR, -(@i % 50 + 18), GETDATE()),
            (@i * 10.50) % 10000
        );
        SET @i = @i + 1;
    END
END
GO

-- Example 1: Create index on frequently searched column
-- Common query: Search customers by last name

-- First, let's see the query performance WITHOUT an index
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE LastName = 'LastName5000';
GO

/*
OUTPUT (without index):
Table 'Customer'. Scan count 1, logical reads 150-200
CPU time = X ms

Execution Plan: Table Scan (bad performance)
*/

-- Create single-column index on LastName
CREATE NONCLUSTERED INDEX IX_Customer_LastName
ON Customer(LastName);
GO

-- Test the same query again
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE LastName = 'LastName5000';
GO

/*
OUTPUT (with index):
Table 'Customer'. Scan count 1, logical reads 3-5
CPU time = Y ms (much faster)

Execution Plan: Index Seek → Key Lookup
*/

-- Example 2: Create index on Email (another frequently searched column)
CREATE NONCLUSTERED INDEX IX_Customer_Email
ON Customer(Email);
GO

-- Test query
SELECT * FROM Customer WHERE Email = 'customer7500@email.com';
GO

/*
PERFORMANCE IMPROVEMENT:
- Reduced logical reads by 95%+
- Query time reduced from 20ms to <1ms
*/

-- Example 3: Create index on date column for date range queries
CREATE NONCLUSTERED INDEX IX_Customer_RegistrationDate
ON Customer(RegistrationDate);
GO

-- Test with date range query
SELECT CustomerID, FirstName, LastName, RegistrationDate
FROM Customer
WHERE RegistrationDate >= '2024-01-01'
  AND RegistrationDate < '2024-02-01';
GO

/*
EXPLANATION:
Index helps with range queries (BETWEEN, >, <, >=, <=)
SQL Server can efficiently scan just the relevant portion of the index
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/*
================================================================================
PART 2: COMPOSITE (MULTI-COLUMN) INDEXES
================================================================================

Composite indexes include multiple columns in a specific order.
They're powerful for queries that filter or sort by multiple columns.

Key Concept: Column Order Matters!
----------------------------------
Index on (LastName, FirstName) ≠ Index on (FirstName, LastName)

The first column in the index is the PRIMARY sort/search column.

Visual Representation:
----------------------
Index on (LastName, FirstName):

LastName       FirstName      Row Pointer
----------     -----------    -----------
Anderson       Alice          → Row 1
Anderson       Bob            → Row 2
Anderson       Charlie        → Row 3
Brown          David          → Row 4
Brown          Emma           → Row 5

This index helps queries filtering by:
✅ LastName alone
✅ LastName + FirstName together
❌ FirstName alone (not helpful)

*/

-- Example 1: Composite index for common search pattern
-- Common query: Search by last name and first name together

-- Create composite index
CREATE NONCLUSTERED INDEX IX_Customer_Name
ON Customer(LastName, FirstName);
GO

-- This index helps this query (both columns)
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE LastName = 'LastName1000'
  AND FirstName = 'FirstName1000';
GO

/*
Execution Plan: Index Seek on IX_Customer_Name
└── Very efficient! Uses both columns in the seek
*/

-- This index also helps this query (first column only)
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE LastName = 'LastName1000';
GO

/*
Execution Plan: Index Seek on IX_Customer_Name
└── Still efficient! Can use just the leading column
*/

-- But this query does NOT benefit from IX_Customer_Name
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE FirstName = 'FirstName1000';
GO

/*
Execution Plan: May use Index Scan or Table Scan
└── Can't efficiently seek on second column alone
*/

-- Example 2: Composite index for geographic queries
-- Common pattern: Filter by Country, then State, then City

CREATE NONCLUSTERED INDEX IX_Customer_Location
ON Customer(Country, State, City);
GO

-- Query helped by all three columns
SELECT CustomerID, FirstName, LastName, City, State, Country
FROM Customer
WHERE Country = 'USA'
  AND State = 'CA'
  AND City = 'Los Angeles';
GO

-- Query helped by first two columns
SELECT CustomerID, FirstName, LastName, City, State, Country
FROM Customer
WHERE Country = 'USA'
  AND State = 'CA';
GO

-- Query helped by first column only
SELECT CustomerID, FirstName, LastName, City, State, Country
FROM Customer
WHERE Country = 'USA';
GO

/*
COLUMN ORDER RULE OF THUMB:
1. Most selective column first (fewest duplicates)
2. Most frequently queried column first
3. Columns used in equality (=) before range conditions
*/

-- Example 3: Composite index with sorting considerations
-- Common query: Orders by customer, sorted by date

DROP TABLE IF EXISTS [Order];
GO

CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATETIME,
    TotalAmount DECIMAL(10,2),
    Status VARCHAR(20)
);
GO

-- Insert sample orders
DECLARE @i INT = 1;
WHILE @i <= 50000
BEGIN
    INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount, Status)
    VALUES (
        (@i % 10000) + 1,
        DATEADD(DAY, -(@i % 730), GETDATE()),
        (@i * 1.5) % 1000,
        CASE (@i % 4)
            WHEN 0 THEN 'Pending' WHEN 1 THEN 'Shipped'
            WHEN 2 THEN 'Delivered' ELSE 'Cancelled'
        END
    );
    SET @i = @i + 1;
END
GO

-- Create composite index for customer + date queries
CREATE NONCLUSTERED INDEX IX_Order_Customer_Date
ON [Order](CustomerID, OrderDate DESC);  -- DESC for most recent first
GO

-- Query: Get recent orders for a customer
SELECT OrderID, OrderDate, TotalAmount, Status
FROM [Order]
WHERE CustomerID = 5000
ORDER BY OrderDate DESC;
GO

/*
Execution Plan: Index Seek on IX_Order_Customer_Date
└── Perfect match! Filter by CustomerID and already sorted by OrderDate DESC
└── No additional sorting needed - data already in correct order
*/

/*
================================================================================
PART 3: UNIQUE INDEXES
================================================================================

Unique indexes enforce uniqueness while also improving query performance.
They prevent duplicate values in the indexed column(s).

Key Points:
-----------
- Automatically created for PRIMARY KEY and UNIQUE constraints
- Can be created explicitly for performance + uniqueness
- Allow one NULL value (multiple NULLs in SQL Server)
- Can be clustered or nonclustered

*/

-- Example 1: Unique index on Email (emails must be unique)
-- First, let's drop the existing non-unique index on Email

DROP INDEX IX_Customer_Email ON Customer;
GO

-- Create unique index
CREATE UNIQUE NONCLUSTERED INDEX IX_Customer_Email_Unique
ON Customer(Email);
GO

/*
Now email values must be unique!
*/

-- Test: Try to insert duplicate email
INSERT INTO Customer (FirstName, LastName, Email, City, Country, DateOfBirth, AccountBalance)
VALUES ('Test', 'User', 'customer1@email.com', 'Seattle', 'USA', '1990-01-01', 100.00);
GO

/*
ERROR:
Cannot insert duplicate key row in object 'dbo.Customer' with unique index 'IX_Customer_Email_Unique'.

EXPLANATION:
The unique index prevents duplicate emails
*/

-- Example 2: Composite unique index
-- Business rule: Same person can't register multiple accounts with same name and DOB

CREATE UNIQUE NONCLUSTERED INDEX IX_Customer_UniquePerson
ON Customer(LastName, FirstName, DateOfBirth);
GO

-- Test: Try to insert duplicate person
INSERT INTO Customer (FirstName, LastName, Email, City, Country, DateOfBirth, AccountBalance)
VALUES ('FirstName1', 'LastName1', 'newemail@test.com', 'Seattle', 'USA', 
        (SELECT DateOfBirth FROM Customer WHERE CustomerID = 1), 100.00);
GO

/*
ERROR:
Violation of UNIQUE KEY constraint

EXPLANATION:
Same FirstName + LastName + DateOfBirth combination already exists
*/

-- Example 3: Unique index with NULLs
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    SSN CHAR(11),  -- May be NULL for pending employees
    Email NVARCHAR(100)
);
GO

-- Create unique index allowing NULLs
CREATE UNIQUE NONCLUSTERED INDEX IX_Employee_SSN
ON Employee(SSN)
WHERE SSN IS NOT NULL;  -- Filtered index - only index non-NULL values
GO

-- Insert employees
INSERT INTO Employee (FirstName, LastName, SSN, Email)
VALUES 
    ('John', 'Doe', '123-45-6789', 'john@company.com'),
    ('Jane', 'Smith', NULL, 'jane@company.com'),  -- NULL SSN allowed
    ('Bob', 'Johnson', NULL, 'bob@company.com');  -- Multiple NULLs allowed
GO

-- Try to insert duplicate SSN
INSERT INTO Employee (FirstName, LastName, SSN, Email)
VALUES ('Mike', 'Williams', '123-45-6789', 'mike@company.com');
GO

/*
ERROR:
Cannot insert duplicate key

EXPLANATION:
Unique index prevents duplicate SSNs, but allows multiple NULLs
*/

/*
================================================================================
PART 4: COVERING INDEXES
================================================================================

A covering index includes ALL columns needed by a query, eliminating the
need for key lookups. This provides maximum query performance.

Concept:
--------
If an index contains all columns in SELECT, WHERE, ORDER BY, and GROUP BY,
SQL Server can satisfy the query entirely from the index without accessing
the base table.

Visual Representation:
----------------------
Without Covering Index:
[Index Seek] → [Key Lookup] → [Nested Loops Join]
    ↓              ↓
  Name Index    Base Table (expensive!)

With Covering Index:
[Index Seek] → Results
    ↓
  Covering Index (all needed columns present)

*/

-- Example 1: Query with Key Lookup (not covered)

-- Common query: Get customer name and email by last name
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE LastName = 'LastName1000';
GO

/*
Current Execution Plan:
[Index Seek on IX_Customer_Name] → [Key Lookup on PK_Customer] → Join

KEY LOOKUP occurs because index doesn't include Email column
This is expensive - requires separate lookup to base table
*/

-- Create covering index with INCLUDE clause
CREATE NONCLUSTERED INDEX IX_Customer_Name_Covering
ON Customer(LastName)
INCLUDE (FirstName, Email);  -- Non-key columns included for coverage
GO

-- Test the same query
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE LastName = 'LastName1000';
GO

/*
New Execution Plan:
[Index Seek on IX_Customer_Name_Covering] → Results

NO KEY LOOKUP! Much faster!
All needed columns are in the index
*/

-- Example 2: Covering index for complex query

-- Common reporting query
SELECT 
    CustomerID,
    FirstName,
    LastName,
    City,
    State,
    AccountBalance
FROM Customer
WHERE State = 'CA'
  AND IsActive = 1
ORDER BY AccountBalance DESC;
GO

/*
Without covering index: Multiple lookups needed
*/

-- Create covering index
CREATE NONCLUSTERED INDEX IX_Customer_ActiveCA_Covering
ON Customer(State, IsActive, AccountBalance DESC)
INCLUDE (FirstName, LastName, City);
GO

-- Test query again
SELECT 
    CustomerID,
    FirstName,
    LastName,
    City,
    State,
    AccountBalance
FROM Customer
WHERE State = 'CA'
  AND IsActive = 1
ORDER BY AccountBalance DESC;
GO

/*
Execution Plan: Single Index Seek - fully covered!
└── All filtering, sorting, and data retrieval from one index
└── Optimal performance
*/

/*
KEY vs INCLUDED COLUMNS:
------------------------
Key columns (in index definition):
- Used for searching and sorting
- Part of all index levels (root, intermediate, leaf)
- Limited to 16 columns, 900 bytes max

Included columns (in INCLUDE clause):
- Only stored at leaf level
- Not searchable or sortable
- No limit on size or number
- Perfect for covering queries

RULE OF THUMB:
- Key columns: WHERE, JOIN, ORDER BY, GROUP BY columns
- Included columns: SELECT list columns
*/

/*
================================================================================
PART 5: FILTERED INDEXES
================================================================================

Filtered indexes include only a subset of rows based on a WHERE clause.
They're smaller, faster, and more efficient for queries on specific subsets.

Benefits:
---------
✅ Smaller index size (less storage, less maintenance)
✅ Faster queries on filtered subset
✅ Better statistics for specific scenarios
✅ Reduced index maintenance overhead

Common Use Cases:
-----------------
- Active vs inactive records
- Recent vs historical data
- Specific categories or types
- Non-NULL values only

*/

-- Example 1: Index on active customers only

-- Most queries only care about active customers
SELECT COUNT(*) AS TotalCustomers,
       SUM(CASE WHEN IsActive = 1 THEN 1 ELSE 0 END) AS ActiveCustomers,
       SUM(CASE WHEN IsActive = 0 THEN 1 ELSE 0 END) AS InactiveCustomers
FROM Customer;
GO

/*
OUTPUT:
TotalCustomers  ActiveCustomers  InactiveCustomers
--------------  ---------------  -----------------
10000          10000            0
*/

-- Deactivate some customers for demonstration
UPDATE Customer SET IsActive = 0 WHERE CustomerID % 10 = 0;
GO

-- Create filtered index for active customers only
CREATE NONCLUSTERED INDEX IX_Customer_Active_Email
ON Customer(Email)
WHERE IsActive = 1;
GO

-- Query that benefits from filtered index
SELECT CustomerID, FirstName, LastName, Email
FROM Customer
WHERE Email = 'customer1001@email.com'
  AND IsActive = 1;
GO

/*
Execution Plan: Index Seek on IX_Customer_Active_Email
└── Smaller index (only 90% of rows)
└── Faster seeks and scans
└── Better statistics for active customers
*/

-- Comparison: Full index vs filtered index size
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.has_filter AS IsFiltered,
    i.filter_definition AS FilterDefinition,
    ps.row_count AS RowCount,
    ps.used_page_count AS Pages,
    ps.used_page_count * 8 AS SpaceKB
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps
    ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Customer')
  AND i.name LIKE '%Email%'
ORDER BY i.name;
GO

/*
OUTPUT:
IndexName                    IsFiltered  FilterDefinition     RowCount  Pages  SpaceKB
--------------------------   ----------  -------------------  --------  -----  -------
IX_Customer_Active_Email     1           ([IsActive]=(1))     9000      72     576
IX_Customer_Email_Unique     0           NULL                 10000     80     640

SAVINGS: ~10% smaller index
*/

-- Example 2: Filtered index for recent orders

-- Create index only on orders from last 90 days
CREATE NONCLUSTERED INDEX IX_Order_Recent
ON [Order](OrderDate, CustomerID)
WHERE OrderDate >= DATEADD(DAY, -90, GETDATE());
GO

-- Query for recent orders is very fast
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM [Order]
WHERE CustomerID = 5000
  AND OrderDate >= DATEADD(DAY, -90, GETDATE())
ORDER BY OrderDate DESC;
GO

/*
Benefits:
- Much smaller index (only ~12% of all orders)
- Faster maintenance (only recent data)
- Better for active operational queries
*/

-- Example 3: Filtered index for specific statuses

-- Most queries care about non-cancelled orders
CREATE NONCLUSTERED INDEX IX_Order_Active
ON [Order](CustomerID, OrderDate)
WHERE Status IN ('Pending', 'Shipped', 'Delivered');
GO

-- Query benefits from filtered index
SELECT OrderID, OrderDate, Status, TotalAmount
FROM [Order]
WHERE CustomerID = 5000
  AND Status IN ('Pending', 'Shipped', 'Delivered')
ORDER BY OrderDate DESC;
GO

/*
FILTERED INDEX BEST PRACTICES:
1. Use for well-defined subsets (active records, recent data)
2. Filter definition should match common query patterns
3. Don't create too many filtered indexes (maintenance overhead)
4. Keep filter predicates simple (SQL Server limitations)
5. Monitor usage with DMVs
*/

/*
================================================================================
PART 6: INDEX CREATION OPTIONS
================================================================================

SQL Server provides various options when creating indexes to control
behavior, performance, and maintenance.
*/

-- Example 1: Online index creation (Enterprise Edition)
-- Allows table to remain accessible during index creation

/*
-- Note: ONLINE option requires Enterprise Edition
CREATE NONCLUSTERED INDEX IX_Customer_Phone
ON Customer(Phone)
WITH (ONLINE = ON);
GO
*/

-- For Standard Edition, use regular creation (table locked)
CREATE NONCLUSTERED INDEX IX_Customer_Phone
ON Customer(Phone);
GO

-- Example 2: Fill Factor
-- Controls how full index pages are (leaves space for future INSERTs)

CREATE NONCLUSTERED INDEX IX_Customer_PostalCode
ON Customer(PostalCode)
WITH (FILLFACTOR = 80);  -- 80% full, 20% free space per page
GO

/*
FILLFACTOR Explanation:
- 100 = Pages completely full (default for most indexes)
- 80 = Pages 80% full, 20% free for future inserts
- Lower values reduce page splits but increase storage

WHEN TO USE:
- High FILLFACTOR (90-100): Read-heavy tables, rarely modified
- Medium FILLFACTOR (70-80): Balanced read/write workload
- Low FILLFACTOR (50-60): Write-heavy tables, frequent inserts
*/

-- Example 3: Pad Index
-- Applies fill factor to intermediate index levels (not just leaf level)

CREATE NONCLUSTERED INDEX IX_Customer_City
ON Customer(City)
WITH (FILLFACTOR = 80, PAD_INDEX = ON);
GO

-- Example 4: Sort in TempDB
-- Performs sorting in TempDB instead of user database (can improve performance)

CREATE NONCLUSTERED INDEX IX_Customer_Country
ON Customer(Country)
WITH (SORT_IN_TEMPDB = ON);
GO

/*
Benefits of SORT_IN_TEMPDB:
- Parallel sorting on different disks
- Doesn't fill up user database transaction log
- Faster index creation on large tables
*/

-- Example 5: Drop Existing
-- Drops and recreates index in single atomic operation

CREATE NONCLUSTERED INDEX IX_Customer_State
ON Customer(State)
WITH (DROP_EXISTING = ON);
GO

-- If index already exists, this recreates it
CREATE NONCLUSTERED INDEX IX_Customer_State
ON Customer(State)
WITH (DROP_EXISTING = ON, FILLFACTOR = 70);
GO

/*
================================================================================
PART 7: CHOOSING THE RIGHT INDEX TYPE
================================================================================

Decision Matrix for Index Selection:
*/

-- Scenario 1: Primary key lookups
-- Solution: Clustered index (automatic with PRIMARY KEY)
-- Already exists: PK_Customer on CustomerID

-- Scenario 2: Foreign key joins
-- Solution: Nonclustered index on foreign key column

DROP TABLE IF EXISTS OrderDetail;
GO

CREATE TABLE OrderDetail (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,  -- Foreign key
    ProductID INT,  -- Foreign key
    Quantity INT,
    UnitPrice DECIMAL(10,2)
);
GO

-- Create indexes on foreign keys for better join performance
CREATE NONCLUSTERED INDEX IX_OrderDetail_OrderID ON OrderDetail(OrderID);
CREATE NONCLUSTERED INDEX IX_OrderDetail_ProductID ON OrderDetail(ProductID);
GO

-- Scenario 3: Unique business constraint
-- Solution: Unique index

-- Email must be unique (already created)
-- SSN must be unique (if exists) - created earlier on Employee table

-- Scenario 4: Frequently searched together
-- Solution: Composite index

-- Searching by City AND State
CREATE NONCLUSTERED INDEX IX_Customer_CityState
ON Customer(City, State);
GO

-- Scenario 5: Covering frequently used query
-- Solution: Covering index with INCLUDE

-- Common dashboard query
CREATE NONCLUSTERED INDEX IX_Customer_Dashboard
ON Customer(Country, State)
INCLUDE (City, AccountBalance, RegistrationDate);
GO

-- Scenario 6: Subset-specific queries
-- Solution: Filtered index

-- Already created: IX_Customer_Active_Email for active customers
-- Already created: IX_Order_Recent for recent orders

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Single-Column Index
-------------------------------
Create an index on the Customer.Phone column.
Test its performance with a query searching for a specific phone number.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Composite Index
---------------------------
Create a composite index on [Order] table for (Status, OrderDate).
Write queries that benefit from this index and queries that don't.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Covering Index
--------------------------
Analyze this query and create an optimal covering index:

SELECT CustomerID, FirstName, LastName, Email, City
FROM Customer
WHERE Country = 'USA'
  AND State = 'CA'
ORDER BY LastName, FirstName;

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 4: Filtered Index
--------------------------
Create a filtered index for high-value customers (AccountBalance > 5000)
on the Customer table. Include relevant columns.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Single-Column Index
-- The index already exists from earlier examples
-- Here's how to test it:

SET STATISTICS IO ON;

SELECT * FROM Customer WHERE Phone = '555-1000';

SET STATISTICS IO OFF;
GO

/*
With index: ~3-5 logical reads
Without index: 100+ logical reads
*/

-- Solution 2: Composite Index
CREATE NONCLUSTERED INDEX IX_Order_Status_Date
ON [Order](Status, OrderDate DESC);
GO

-- Query that benefits (uses both columns)
SELECT OrderID, Status, OrderDate, TotalAmount
FROM [Order]
WHERE Status = 'Pending'
  AND OrderDate >= '2024-01-01';
GO

-- Query that benefits (uses first column)
SELECT OrderID, Status, OrderDate, TotalAmount
FROM [Order]
WHERE Status = 'Shipped';
GO

-- Query that does NOT benefit (uses only second column)
SELECT OrderID, Status, OrderDate, TotalAmount
FROM [Order]
WHERE OrderDate >= '2024-01-01';  -- Can't use Status as leading column
GO

-- Solution 3: Covering Index
CREATE NONCLUSTERED INDEX IX_Customer_USA_CA_Covering
ON Customer(Country, State, LastName, FirstName)
INCLUDE (Email, City);
GO

-- Test the query
SELECT CustomerID, FirstName, LastName, Email, City
FROM Customer
WHERE Country = 'USA'
  AND State = 'CA'
ORDER BY LastName, FirstName;
GO

/*
Execution Plan: Single Index Seek (fully covered!)
- Filter on Country, State
- Sort by LastName, FirstName (already in index order)
- Retrieve Email, City from INCLUDE columns
- No key lookup needed
*/

-- Solution 4: Filtered Index for High-Value Customers
CREATE NONCLUSTERED INDEX IX_Customer_HighValue
ON Customer(AccountBalance DESC)
INCLUDE (FirstName, LastName, Email, City, Country)
WHERE AccountBalance > 5000;
GO

-- Query for high-value customers
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Email,
    AccountBalance
FROM Customer
WHERE AccountBalance > 5000
ORDER BY AccountBalance DESC;
GO

/*
Benefits:
- Smaller index (only ~50% of customers)
- Faster queries for high-value customers
- Useful for VIP customer reports
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. SINGLE-COLUMN INDEXES
   - Simplest and most common
   - Perfect for queries filtering on one column
   - Easy to understand and maintain

2. COMPOSITE INDEXES
   - Multiple columns in specific order
   - Column order is CRITICAL
   - First column is primary search/sort column
   - Benefits queries using leading columns

3. UNIQUE INDEXES
   - Enforce uniqueness + performance
   - Automatically created for constraints
   - Allow multiple NULLs (use filtered index to prevent)

4. COVERING INDEXES
   - Include all columns needed by query
   - Eliminate key lookups (huge performance gain)
   - Use INCLUDE clause for non-key columns
   - Balance coverage vs index size

5. FILTERED INDEXES
   - Index subset of rows (WHERE clause)
   - Smaller, faster, less maintenance
   - Perfect for active/recent/specific data
   - Must match query filter for benefit

6. INDEX OPTIONS
   - FILLFACTOR: Control page fullness
   - ONLINE: Keep table accessible (Enterprise)
   - SORT_IN_TEMPDB: Faster creation
   - DROP_EXISTING: Atomic rebuild

7. SELECTION STRATEGY
   - Analyze query patterns
   - Choose appropriate index type
   - Balance performance vs overhead
   - Test before and after

================================================================================

NEXT STEPS:
-----------
In Lesson 13.3, we'll explore INDEX DESIGN STRATEGIES:
- Choosing which columns to index
- Index selectivity analysis
- Balancing read vs write performance
- Index maintenance overhead considerations

Continue to: 03-index-design-strategies.sql

================================================================================
*/
