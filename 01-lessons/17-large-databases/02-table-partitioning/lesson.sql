/*
================================================================================
LESSON 17.2: TABLE PARTITIONING
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Create partition functions in SQL Server
2. Create partition schemes and map to filegroups
3. Build partitioned tables
4. Add and query data in partitioned tables
5. View partition metadata
6. Understand partition alignment

Business Context:
-----------------
Table partitioning is the implementation of partitioning concepts. This lesson
provides hands-on experience creating and managing partitioned tables, essential
for handling very large tables efficiently.

Database: We'll create a new demo database for partitioning
Complexity: Advanced
Estimated Time: 60 minutes

================================================================================
*/

-- Create a demo database for partitioning examples
USE master;
GO

IF DB_ID('PartitioningDemo') IS NOT NULL
    DROP DATABASE PartitioningDemo;
GO

CREATE DATABASE PartitioningDemo;
GO

USE PartitioningDemo;
GO

/*
================================================================================
PART 1: CREATING PARTITION FUNCTIONS
================================================================================

A partition function defines the boundary values that determine how data
is distributed across partitions.
*/

-- Example 1: Yearly partition function (RANGE RIGHT)
CREATE PARTITION FUNCTION pfYearly (DATE)
AS RANGE RIGHT FOR VALUES 
    ('2022-01-01', '2023-01-01', '2024-01-01', '2025-01-01');
GO

/*
RANGE RIGHT means boundary value belongs to RIGHT partition:

Partition 1: Date < 2022-01-01         (before 2022)
Partition 2: 2022-01-01 <= Date < 2023-01-01  (2022)
Partition 3: 2023-01-01 <= Date < 2024-01-01  (2023)
Partition 4: 2024-01-01 <= Date < 2025-01-01  (2024)
Partition 5: Date >= 2025-01-01        (2025 and later)

Note: 4 boundary values create 5 partitions!
*/

-- Example 2: Monthly partition function for current year
CREATE PARTITION FUNCTION pfMonthly2024 (DATE)
AS RANGE RIGHT FOR VALUES 
    ('2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01',
     '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01',
     '2024-09-01', '2024-10-01', '2024-11-01', '2024-12-01');
GO

/*
Creates 13 partitions:
- Partition 1: before Jan 2024
- Partitions 2-13: Jan through Dec 2024
*/

-- Example 3: RANGE LEFT (boundary belongs to LEFT partition)
CREATE PARTITION FUNCTION pfYearlyLeft (DATE)
AS RANGE LEFT FOR VALUES 
    ('2022-12-31', '2023-12-31', '2024-12-31');
GO

/*
RANGE LEFT means boundary value belongs to LEFT partition:

Partition 1: Date <= 2022-12-31        (2022 and before)
Partition 2: 2022-12-31 < Date <= 2023-12-31  (2023)
Partition 3: 2023-12-31 < Date <= 2024-12-31  (2024)
Partition 4: Date > 2024-12-31         (2025 and later)
*/

-- Example 4: Regional partition function (numeric)
CREATE PARTITION FUNCTION pfRegions (INT)
AS RANGE RIGHT FOR VALUES (10, 20, 30, 40);
GO

/*
For RegionID column:
Partition 1: RegionID < 10
Partition 2: 10 <= RegionID < 20
Partition 3: 20 <= RegionID < 30
Partition 4: 30 <= RegionID < 40
Partition 5: RegionID >= 40
*/

-- View partition function metadata
SELECT 
    pf.name AS PartitionFunction,
    pf.type_desc AS DataType,
    pf.fanout AS NumberOfPartitions,
    prv.value AS BoundaryValue,
    prv.boundary_id
FROM sys.partition_functions pf
LEFT JOIN sys.partition_range_values prv 
    ON pf.function_id = prv.function_id
WHERE pf.name = 'pfYearly'
ORDER BY prv.boundary_id;
GO

/*
OUTPUT:
PartitionFunction  DataType  NumberOfPartitions  BoundaryValue  boundary_id
pfYearly           DATE      5                   2022-01-01     1
pfYearly           DATE      5                   2023-01-01     2
pfYearly           DATE      5                   2024-01-01     3
pfYearly           DATE      5                   2025-01-01     4
*/

/*
================================================================================
PART 2: CREATING PARTITION SCHEMES
================================================================================

A partition scheme maps partitions to filegroups (storage locations).
*/

-- Example 1: Simple partition scheme (all partitions on PRIMARY)
CREATE PARTITION SCHEME psYearly
AS PARTITION pfYearly
ALL TO ([PRIMARY]);
GO

/*
ALL TO ([PRIMARY]) means all partitions stored on PRIMARY filegroup.
Simple, but doesn't leverage multiple filegroups.
*/

-- Example 2: Partition scheme with multiple filegroups
-- First, create filegroups (in production, these would be on different drives)
ALTER DATABASE PartitioningDemo ADD FILEGROUP FG2022;
ALTER DATABASE PartitioningDemo ADD FILEGROUP FG2023;
ALTER DATABASE PartitioningDemo ADD FILEGROUP FG2024;
ALTER DATABASE PartitioningDemo ADD FILEGROUP FG2025;
GO

-- Add files to filegroups
ALTER DATABASE PartitioningDemo 
ADD FILE (NAME = 'FG2022_Data', FILENAME = 'C:\Temp\FG2022.ndf', SIZE = 10MB) 
TO FILEGROUP FG2022;

ALTER DATABASE PartitioningDemo 
ADD FILE (NAME = 'FG2023_Data', FILENAME = 'C:\Temp\FG2023.ndf', SIZE = 10MB) 
TO FILEGROUP FG2023;

ALTER DATABASE PartitioningDemo 
ADD FILE (NAME = 'FG2024_Data', FILENAME = 'C:\Temp\FG2024.ndf', SIZE = 10MB) 
TO FILEGROUP FG2024;

ALTER DATABASE PartitioningDemo 
ADD FILE (NAME = 'FG2025_Data', FILENAME = 'C:\Temp\FG2025.ndf', SIZE = 10MB) 
TO FILEGROUP FG2025;
GO

-- Create partition scheme mapping partitions to specific filegroups
CREATE PARTITION SCHEME psYearlyMultiFG
AS PARTITION pfYearly
TO ([PRIMARY], FG2022, FG2023, FG2024, FG2025);
GO

/*
Maps partitions to filegroups:
Partition 1 (< 2022)     -> PRIMARY
Partition 2 (2022)       -> FG2022
Partition 3 (2023)       -> FG2023
Partition 4 (2024)       -> FG2024
Partition 5 (>= 2025)    -> FG2025

Benefits:
- Distribute I/O across different drives
- Archive old data to slower/cheaper storage
- Separate active from historical data
*/

-- View partition scheme metadata
SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    fg.name AS Filegroup,
    dds.destination_id AS PartitionNumber
FROM sys.partition_schemes ps
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
INNER JOIN sys.destination_data_spaces dds ON ps.data_space_id = dds.partition_scheme_id
INNER JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
WHERE ps.name = 'psYearlyMultiFG'
ORDER BY dds.destination_id;
GO

/*
================================================================================
PART 3: CREATING PARTITIONED TABLES
================================================================================
*/

-- Example 1: Simple partitioned table
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    OrderAmount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(20),
    CONSTRAINT PK_Orders PRIMARY KEY (OrderID, OrderDate)
) ON psYearly(OrderDate);
GO

/*
Key points:
1. Table created ON partition scheme
2. Partition key (OrderDate) specified in parentheses
3. Partition key MUST be in PRIMARY KEY or UNIQUE constraint
4. Creates 5 physical partitions based on pfYearly
*/

-- Example 2: Partitioned table with computed column
CREATE TABLE SalesTransactions (
    TransactionID BIGINT IDENTITY(1,1),
    TransactionDate DATETIME2 NOT NULL,
    TransactionMonth AS DATEADD(MONTH, DATEDIFF(MONTH, 0, TransactionDate), 0) PERSISTED,
    Amount DECIMAL(18,2) NOT NULL,
    ProductID INT NOT NULL,
    CONSTRAINT PK_SalesTransactions PRIMARY KEY (TransactionID, TransactionMonth)
) ON psMonthly2024(TransactionMonth);
GO

/*
Uses computed column for monthly partitioning:
- TransactionDate stores exact time
- TransactionMonth (computed) used for partitioning
- Keeps data in monthly partitions regardless of time component
*/

-- Example 3: Partitioned table with clustered index
CREATE TABLE WebLogs (
    LogID BIGINT IDENTITY(1,1),
    LogDate DATE NOT NULL,
    UserID INT,
    PageURL VARCHAR(500),
    ResponseTime INT,
    INDEX IX_WebLogs_Clustered CLUSTERED (LogDate, LogID)
) ON psYearly(LogDate);
GO

/*
Clustered index includes partition key for alignment
*/

/*
================================================================================
PART 4: INSERTING DATA INTO PARTITIONED TABLES
================================================================================
*/

-- Insert data spanning multiple years
INSERT INTO Orders (OrderDate, CustomerID, OrderAmount, Status) VALUES
    -- 2021 data (Partition 1)
    ('2021-06-15', 100, 1500.00, 'Completed'),
    ('2021-12-20', 101, 2500.00, 'Completed'),
    -- 2022 data (Partition 2)
    ('2022-03-10', 102, 3200.00, 'Completed'),
    ('2022-08-22', 103, 1800.00, 'Completed'),
    ('2022-11-05', 104, 4500.00, 'Completed'),
    -- 2023 data (Partition 3)
    ('2023-01-15', 105, 2100.00, 'Completed'),
    ('2023-06-30', 106, 3800.00, 'Completed'),
    ('2023-09-12', 107, 1200.00, 'Cancelled'),
    -- 2024 data (Partition 4)
    ('2024-02-28', 108, 5000.00, 'Completed'),
    ('2024-07-04', 109, 2700.00, 'Pending'),
    ('2024-10-18', 110, 3300.00, 'Completed'),
    -- 2025 data (Partition 5)
    ('2025-01-10', 111, 4200.00, 'Pending'),
    ('2025-03-25', 112, 1900.00, 'Completed');
GO

-- Data automatically goes to correct partition based on OrderDate!

/*
================================================================================
PART 5: QUERYING PARTITIONED TABLES
================================================================================
*/

-- Example 1: Simple query (application doesn't need to know about partitions)
SELECT OrderID, OrderDate, CustomerID, OrderAmount
FROM Orders
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
GO

/*
Partition elimination in action:
- Query only scans Partition 4 (2024 data)
- Other partitions not touched
- Much faster than scanning entire table
*/

-- Example 2: Query without partition key (scans all partitions)
SELECT OrderID, OrderDate, CustomerID, OrderAmount
FROM Orders
WHERE CustomerID = 105;
GO

-- No partition elimination - all partitions scanned

-- Example 3: Aggregation with partition key
SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalAmount
FROM Orders
WHERE OrderDate >= '2023-01-01'
GROUP BY YEAR(OrderDate);
GO

-- Only scans partitions 3, 4, 5 (2023 and later)

/*
================================================================================
PART 6: VIEWING PARTITION METADATA
================================================================================
*/

-- View which rows are in which partitions
SELECT 
    $PARTITION.pfYearly(OrderDate) AS PartitionNumber,
    OrderID,
    OrderDate,
    OrderAmount
FROM Orders
ORDER BY PartitionNumber, OrderDate;
GO

/*
OUTPUT:
PartitionNumber  OrderID  OrderDate    OrderAmount
1                1        2021-06-15   1500.00
1                2        2021-12-20   2500.00
2                3        2022-03-10   3200.00
2                4        2022-08-22   1800.00
...

$PARTITION function shows which partition each row is in
*/

-- Get row count and size per partition
SELECT 
    p.partition_number AS PartitionNum,
    p.rows AS RowCount,
    au.total_pages * 8 / 1024.0 AS SizeMB,
    au.used_pages * 8 / 1024.0 AS UsedMB,
    prv.value AS BoundaryValue
FROM sys.partitions p
INNER JOIN sys.allocation_units au 
    ON p.partition_id = au.container_id
LEFT JOIN sys.partition_range_values prv 
    ON p.partition_number = prv.boundary_id + 1
    AND prv.function_id = (
        SELECT function_id 
        FROM sys.partition_functions 
        WHERE name = 'pfYearly'
    )
WHERE p.object_id = OBJECT_ID('Orders')
    AND p.index_id IN (0, 1)  -- Heap or clustered index
ORDER BY p.partition_number;
GO

/*
OUTPUT:
PartitionNum  RowCount  SizeMB   UsedMB   BoundaryValue
1             2         0.0156   0.0078   NULL
2             3         0.0156   0.0078   2022-01-01
3             3         0.0156   0.0078   2023-01-01
4             3         0.0156   0.0078   2024-01-01
5             2         0.0156   0.0078   2025-01-01
*/

-- Get filegroup for each partition
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    p.partition_number AS PartitionNum,
    p.rows AS RowCount,
    fg.name AS Filegroup
FROM sys.partitions p
INNER JOIN sys.allocation_units au 
    ON p.partition_id = au.container_id
INNER JOIN sys.filegroups fg 
    ON au.data_space_id = fg.data_space_id
WHERE p.object_id = OBJECT_ID('Orders')
    AND p.index_id IN (0, 1)
ORDER BY p.partition_number;
GO

/*
================================================================================
PART 7: PARTITION ALIGNMENT
================================================================================

Indexes on partitioned tables should be "aligned" with the table's
partition scheme for optimal performance.
*/

-- Example 1: Aligned non-clustered index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON Orders (CustomerID, OrderDate)
ON psYearly(OrderDate);
GO

/*
Aligned index:
- Uses same partition scheme as table
- Each index partition corresponds to table partition
- Enables partition-level operations
- Required for partition switching
*/

-- Example 2: Non-aligned index (different partition scheme)
-- Note: Creates separate index structure
CREATE NONCLUSTERED INDEX IX_Orders_Status
ON Orders (Status)
ON [PRIMARY];  -- Not partitioned
GO

/*
Non-aligned index:
- Different storage than table
- Cannot participate in partition switching
- Use sparingly - has implications for maintenance
*/

-- View index partition alignment
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ds.name AS PartitionScheme,
    CASE 
        WHEN i.data_space_id = t.data_space_id THEN 'Aligned'
        ELSE 'Not Aligned'
    END AS Alignment
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
LEFT JOIN sys.partition_schemes ds ON i.data_space_id = ds.data_space_id
WHERE i.object_id = OBJECT_ID('Orders')
ORDER BY i.index_id;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Create Quarterly Partitioned Table
-----------------------------------------------
Create a partitioned table for quarterly sales data:
- Partition function: quarterly boundaries for 2024
- Partition scheme: all on PRIMARY
- Table: QuarterlySales with columns SaleID, SaleDate, Amount
- Insert test data for each quarter
- Query to show row count per partition

TRY IT YOURSELF!
*/

-- Your solution here:






/*
Exercise 2: Regional Partitioning
----------------------------------
Create a partitioned table for geographic data:
- Partition function: RegionID values 1, 2, 3, 4
- Partition scheme: separate filegroup per region
- Table: CustomersByRegion with CustomerID, RegionID, Name
- Insert customers across all regions
- Query showing which filegroup stores which regions

TRY IT YOURSELF!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Quarterly Partitioned Table
-- Step 1: Create partition function
CREATE PARTITION FUNCTION pfQuarterly2024 (DATE)
AS RANGE RIGHT FOR VALUES 
    ('2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01');
GO

-- Step 2: Create partition scheme
CREATE PARTITION SCHEME psQuarterly2024
AS PARTITION pfQuarterly2024
ALL TO ([PRIMARY]);
GO

-- Step 3: Create table
CREATE TABLE QuarterlySales (
    SaleID INT IDENTITY(1,1),
    SaleDate DATE NOT NULL,
    Amount DECIMAL(10,2),
    CONSTRAINT PK_QuarterlySales PRIMARY KEY (SaleID, SaleDate)
) ON psQuarterly2024(SaleDate);
GO

-- Step 4: Insert test data
INSERT INTO QuarterlySales (SaleDate, Amount) VALUES
    ('2023-12-15', 1000.00),  -- Before 2024
    ('2024-02-10', 1500.00),  -- Q1
    ('2024-05-20', 2000.00),  -- Q2
    ('2024-08-15', 1800.00),  -- Q3
    ('2024-11-01', 2200.00);  -- Q4
GO

-- Step 5: Row count per partition
SELECT 
    p.partition_number,
    p.rows,
    prv.value AS BoundaryValue
FROM sys.partitions p
LEFT JOIN sys.partition_range_values prv 
    ON p.partition_number = prv.boundary_id + 1
WHERE p.object_id = OBJECT_ID('QuarterlySales')
    AND p.index_id IN (0, 1)
ORDER BY p.partition_number;
GO

-- Solution 2: Regional Partitioning
-- (Simplified - filegroups already exist or use PRIMARY)
CREATE PARTITION FUNCTION pfRegional (INT)
AS RANGE RIGHT FOR VALUES (2, 3, 4);
GO

CREATE PARTITION SCHEME psRegional
AS PARTITION pfRegional
ALL TO ([PRIMARY]);
GO

CREATE TABLE CustomersByRegion (
    CustomerID INT IDENTITY(1,1),
    RegionID INT NOT NULL,
    CustomerName VARCHAR(100),
    CONSTRAINT PK_CustomersByRegion PRIMARY KEY (CustomerID, RegionID)
) ON psRegional(RegionID);
GO

INSERT INTO CustomersByRegion (RegionID, CustomerName) VALUES
    (1, 'Customer A'), (2, 'Customer B'), (3, 'Customer C'), 
    (4, 'Customer D'), (5, 'Customer E');
GO

SELECT $PARTITION.pfRegional(RegionID) AS Partition, *
FROM CustomersByRegion;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. PARTITION FUNCTION
   - Defines boundary values
   - RANGE RIGHT: boundary in right partition
   - RANGE LEFT: boundary in left partition
   - N boundaries create N+1 partitions

2. PARTITION SCHEME
   - Maps partitions to filegroups
   - ALL TO ([PRIMARY]): simple, all on one filegroup
   - Individual mapping: better I/O distribution

3. PARTITIONED TABLES
   - Created ON partition scheme
   - Partition key must be in PK or unique constraint
   - Data automatically routed to correct partition

4. QUERYING
   - Transparent to applications
   - Partition elimination when key in WHERE
   - $PARTITION function shows partition number

5. ALIGNMENT
   - Aligned indexes: same partition scheme
   - Enables partition-level operations
   - Required for partition switching

6. METADATA
   - sys.partitions: row counts per partition
   - sys.partition_functions: boundary values
   - sys.partition_schemes: filegroup mappings

================================================================================

NEXT STEPS:
-----------
Continue to Lesson 17.3: Index Partitioning
Learn how to optimize indexes on partitioned tables.

================================================================================
*/
