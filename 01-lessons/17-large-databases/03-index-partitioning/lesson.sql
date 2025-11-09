/*
================================================================================
LESSON 17.3: INDEX PARTITIONING
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand aligned vs non-aligned indexes
2. Create partitioned indexes
3. Optimize queries with partition elimination
4. Rebuild indexes on partitioned tables
5. Choose appropriate index partitioning strategies

Business Context:
-----------------
Index partitioning is critical for maintaining query performance on very large
tables. Proper index partitioning enables fast queries, efficient maintenance,
and partition-level operations like switching and archiving.

Database: PartitioningDemo (from previous lesson)
Complexity: Advanced
Estimated Time: 55 minutes

================================================================================
*/

USE PartitioningDemo;
GO

/*
================================================================================
PART 1: ALIGNED VS NON-ALIGNED INDEXES
================================================================================

ALIGNED INDEX:
- Uses same partition function/scheme as table
- Each index partition corresponds to table partition
- Enables partition-level operations (switching, archiving)
- Required for most partition maintenance

NON-ALIGNED INDEX:
- Different partitioning (or not partitioned at all)
- Stored separately from table partitions
- Cannot participate in partition switching
- May be useful for queries that don't benefit from table partitioning
*/

-- Create sample table for demonstration
CREATE TABLE SalesOrders (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    RegionID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    TotalAmount AS (Quantity * UnitPrice) PERSISTED,
    OrderStatus VARCHAR(20),
    CONSTRAINT PK_SalesOrders PRIMARY KEY CLUSTERED (OrderID, OrderDate)
) ON psYearly(OrderDate);
GO

-- Insert sample data
INSERT INTO SalesOrders (OrderDate, CustomerID, RegionID, ProductID, Quantity, UnitPrice, OrderStatus)
VALUES
    -- 2022
    ('2022-03-15', 100, 1, 501, 10, 25.00, 'Completed'),
    ('2022-06-20', 101, 2, 502, 5, 50.00, 'Completed'),
    ('2022-09-10', 102, 1, 503, 20, 15.00, 'Completed'),
    -- 2023
    ('2023-01-12', 103, 3, 501, 8, 26.00, 'Completed'),
    ('2023-04-25', 104, 1, 504, 15, 35.00, 'Completed'),
    ('2023-08-30', 105, 2, 502, 12, 52.00, 'Completed'),
    -- 2024
    ('2024-02-14', 106, 4, 505, 25, 18.00, 'Completed'),
    ('2024-05-18', 107, 3, 501, 30, 27.00, 'Pending'),
    ('2024-09-22', 108, 1, 506, 10, 45.00, 'Shipped'),
    -- 2025
    ('2025-01-05', 109, 2, 503, 18, 16.00, 'Processing'),
    ('2025-02-10', 110, 4, 507, 22, 38.00, 'Pending');
GO

/*
================================================================================
PART 2: CREATING ALIGNED INDEXES
================================================================================
*/

-- Example 1: Aligned non-clustered index on CustomerID
CREATE NONCLUSTERED INDEX IX_SalesOrders_CustomerID_Aligned
ON SalesOrders (CustomerID, OrderDate)
INCLUDE (TotalAmount)
ON psYearly(OrderDate);  -- Same partition scheme as table
GO

/*
Benefits of aligned index:
1. Each index partition matches table partition
2. Partition elimination works for both table and index
3. Can switch partitions (move data between tables)
4. Parallel operations possible per partition
*/

-- Example 2: Aligned covering index for common query
CREATE NONCLUSTERED INDEX IX_SalesOrders_RegionDate_Aligned
ON SalesOrders (RegionID, OrderDate)
INCLUDE (CustomerID, ProductID, TotalAmount, OrderStatus)
ON psYearly(OrderDate);
GO

-- Example 3: Aligned index on product
CREATE NONCLUSTERED INDEX IX_SalesOrders_ProductID_Aligned
ON SalesOrders (ProductID, OrderDate)
INCLUDE (Quantity, UnitPrice)
ON psYearly(OrderDate);
GO

-- View aligned indexes
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ps_table.name AS TablePartitionScheme,
    ps_index.name AS IndexPartitionScheme,
    CASE 
        WHEN i.data_space_id = t.data_space_id THEN 'Aligned'
        ELSE 'Not Aligned'
    END AS AlignmentStatus
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
LEFT JOIN sys.partition_schemes ps_table ON t.data_space_id = ps_table.data_space_id
LEFT JOIN sys.partition_schemes ps_index ON i.data_space_id = ps_index.data_space_id
WHERE t.name = 'SalesOrders'
ORDER BY i.index_id;
GO

/*
OUTPUT:
TableName     IndexName                                IndexType              AlignmentStatus
SalesOrders   PK_SalesOrders                          CLUSTERED              Aligned
SalesOrders   IX_SalesOrders_CustomerID_Aligned       NONCLUSTERED           Aligned
SalesOrders   IX_SalesOrders_RegionDate_Aligned       NONCLUSTERED           Aligned
SalesOrders   IX_SalesOrders_ProductID_Aligned        NONCLUSTERED           Aligned
*/

/*
================================================================================
PART 3: NON-ALIGNED INDEXES
================================================================================

When to use non-aligned indexes:
- Query patterns don't align with table partitioning
- Need global index across all partitions
- Specific filegroup requirements
*/

-- Example 1: Non-aligned index on OrderStatus (stored on PRIMARY)
CREATE NONCLUSTERED INDEX IX_SalesOrders_Status_NonAligned
ON SalesOrders (OrderStatus)
INCLUDE (OrderID, OrderDate, TotalAmount)
ON [PRIMARY];  -- Different from table partition scheme
GO

/*
Use case: Queries filtering by status need to scan all partitions anyway,
so a global index on PRIMARY may be more efficient.
*/

-- Example 2: Non-aligned index for administrative queries
CREATE NONCLUSTERED INDEX IX_SalesOrders_CustomerProduct_NonAligned
ON SalesOrders (CustomerID, ProductID)
ON [PRIMARY];
GO

-- Verify non-aligned indexes
SELECT 
    i.name AS IndexName,
    i.type_desc,
    fg.name AS Filegroup,
    CASE 
        WHEN i.data_space_id = t.data_space_id THEN 'Aligned'
        ELSE 'Not Aligned'
    END AS Alignment
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
LEFT JOIN sys.filegroups fg ON i.data_space_id = fg.data_space_id
WHERE t.name = 'SalesOrders'
    AND i.name LIKE '%NonAligned%';
GO

/*
================================================================================
PART 4: PARTITION ELIMINATION WITH INDEXES
================================================================================

Partition elimination: SQL Server scans only relevant partitions
*/

-- Enable actual execution plan to see partition elimination
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Query 1: With partition elimination (uses partition key)
SELECT 
    OrderID,
    OrderDate,
    CustomerID,
    TotalAmount
FROM SalesOrders
WHERE OrderDate >= '2024-01-01' 
    AND OrderDate < '2025-01-01'
    AND CustomerID = 107;
GO

/*
Execution plan shows:
- Clustered Index Seek
- Only Partition 4 accessed
- Very efficient!

Check STATISTICS IO output - only one partition scanned
*/

-- Query 2: Without partition elimination (no partition key)
SELECT 
    OrderID,
    OrderDate,
    CustomerID,
    TotalAmount
FROM SalesOrders
WHERE CustomerID = 107;
GO

/*
Execution plan shows:
- Index Seek on IX_SalesOrders_CustomerID_Aligned
- ALL partitions scanned (because no date filter)
- More I/O than Query 1

BUT: Still uses aligned index, so benefits from partitioned structure
*/

-- Query 3: Using non-aligned index
SELECT 
    OrderID,
    OrderDate,
    TotalAmount
FROM SalesOrders
WHERE OrderStatus = 'Pending';
GO

/*
Uses non-aligned index IX_SalesOrders_Status_NonAligned
- Single index structure on PRIMARY
- No partition elimination needed
- Efficient for this query pattern
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- View partition access for a specific index
-- (which partitions have data in the index)
SELECT 
    i.name AS IndexName,
    p.partition_number,
    p.rows AS RowsInPartition,
    au.total_pages AS TotalPages,
    fg.name AS Filegroup
FROM sys.indexes i
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units au ON p.partition_id = au.container_id
LEFT JOIN sys.filegroups fg ON au.data_space_id = fg.data_space_id
WHERE i.object_id = OBJECT_ID('SalesOrders')
    AND i.name = 'IX_SalesOrders_CustomerID_Aligned'
ORDER BY p.partition_number;
GO

/*
================================================================================
PART 5: INDEX MAINTENANCE ON PARTITIONED TABLES
================================================================================
*/

-- View index fragmentation by partition
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.partition_number,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    ips.record_count
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID('SalesOrders'), 
    NULL,  -- All indexes
    NULL,  -- All partitions
    'LIMITED'
) ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0  -- Exclude heap
ORDER BY ips.object_id, ips.index_id, ips.partition_number;
GO

-- Example 1: Rebuild ALL partitions of an index
ALTER INDEX IX_SalesOrders_CustomerID_Aligned
ON SalesOrders
REBUILD;
GO

/*
Rebuilds entire index across all partitions
- Can be time-consuming for large indexes
- Locks the table during rebuild (unless ONLINE = ON)
*/

-- Example 2: Rebuild SINGLE partition
ALTER INDEX IX_SalesOrders_CustomerID_Aligned
ON SalesOrders
REBUILD PARTITION = 4;  -- Rebuild only 2024 partition
GO

/*
Partition-level rebuild:
- Much faster than full rebuild
- Only affects one partition
- Other partitions remain available
- Great for maintaining current year partition
*/

-- Example 3: Reorganize partition (less intrusive)
ALTER INDEX IX_SalesOrders_ProductID_Aligned
ON SalesOrders
REORGANIZE PARTITION = 4;
GO

-- Example 4: Online index rebuild (Enterprise Edition)
ALTER INDEX IX_SalesOrders_RegionDate_Aligned
ON SalesOrders
REBUILD PARTITION = 4
WITH (ONLINE = ON);
GO

/*
Online rebuild:
- Table remains accessible during rebuild
- Minimal blocking
- Requires Enterprise Edition
- Uses more resources
*/

-- Example 5: Rebuild all partitions in parallel
ALTER INDEX IX_SalesOrders_CustomerID_Aligned
ON SalesOrders
REBUILD 
WITH (
    MAXDOP = 4,  -- Use 4 processors
    SORT_IN_TEMPDB = ON,
    ONLINE = ON
);
GO

-- Script to rebuild fragmented partitions only
DECLARE @TableName VARCHAR(100) = 'SalesOrders';
DECLARE @IndexName VARCHAR(200);
DECLARE @PartitionNum INT;
DECLARE @Fragmentation DECIMAL(5,2);
DECLARE @SQL NVARCHAR(MAX);

DECLARE partition_cursor CURSOR FOR
SELECT 
    i.name,
    ips.partition_number,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    OBJECT_ID(@TableName), 
    NULL, 
    NULL, 
    'LIMITED'
) ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30  -- Only highly fragmented
    AND ips.page_count > 1000  -- Only substantial indexes
    AND i.index_id > 0;

OPEN partition_cursor;

FETCH NEXT FROM partition_cursor INTO @IndexName, @PartitionNum, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
               ' ON ' + QUOTENAME(@TableName) + 
               ' REBUILD PARTITION = ' + CAST(@PartitionNum AS VARCHAR(10));
    
    PRINT 'Rebuilding ' + @IndexName + ' Partition ' + CAST(@PartitionNum AS VARCHAR(10)) + 
          ' (Fragmentation: ' + CAST(@Fragmentation AS VARCHAR(10)) + '%)';
    
    -- EXEC sp_executesql @SQL;  -- Uncomment to actually rebuild
    
    FETCH NEXT FROM partition_cursor INTO @IndexName, @PartitionNum, @Fragmentation;
END;

CLOSE partition_cursor;
DEALLOCATE partition_cursor;
GO

/*
================================================================================
PART 6: INDEX PARTITIONING STRATEGIES
================================================================================
*/

-- Strategy 1: Align ALL indexes with table partitioning
-- Best for: Time-series data with date-based queries

-- Strategy 2: Mix aligned and non-aligned indexes
-- Example: Table partitioned by date, but some queries need global access

CREATE TABLE EventLogs (
    EventID BIGINT IDENTITY(1,1),
    EventDate DATE NOT NULL,
    EventTypeID INT NOT NULL,
    UserID INT,
    EventData VARCHAR(MAX),
    CONSTRAINT PK_EventLogs PRIMARY KEY (EventID, EventDate)
) ON psYearly(EventDate);
GO

-- Aligned: for date-range queries
CREATE INDEX IX_EventLogs_Date_Aligned
ON EventLogs (EventDate, EventTypeID)
ON psYearly(EventDate);
GO

-- Non-aligned: for user lookup across all dates
CREATE INDEX IX_EventLogs_User_NonAligned
ON EventLogs (UserID)
INCLUDE (EventID, EventDate, EventTypeID)
ON [PRIMARY];
GO

/*
This combination:
- Date queries: fast with partition elimination
- User queries: fast with dedicated non-aligned index
*/

-- Strategy 3: Columnstore indexes on partitioned tables
CREATE TABLE FactSales (
    SaleID BIGINT NOT NULL,
    SaleDate DATE NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL
) ON psYearly(SaleDate);
GO

-- Aligned columnstore index for analytics
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactSales
ON FactSales
ON psYearly(SaleDate);
GO

/*
Columnstore + partitioning:
- Excellent compression
- Fast analytical queries
- Partition elimination for date ranges
- Can rebuild individual partitions
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Analyze Index Alignment Impact
-------------------------------------------
Create two identical tables with different index strategies:
1. Table A: All aligned indexes
2. Table B: Mix of aligned and non-aligned indexes
Compare query performance for various scenarios.

TRY IT YOURSELF!
*/

-- Your solution here:






/*
Exercise 2: Partition-Level Index Maintenance
----------------------------------------------
Write a script that:
1. Identifies fragmented partitions (>30% fragmentation)
2. Rebuilds only those partitions
3. Logs the maintenance actions
4. Reports time saved vs full rebuild

TRY IT YOURSELF!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Index Alignment Comparison

-- Table A: All aligned
CREATE TABLE TestOrders_Aligned (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT,
    Amount DECIMAL(10,2),
    CONSTRAINT PK_TestOrders_Aligned PRIMARY KEY (OrderID, OrderDate)
) ON psYearly(OrderDate);

CREATE INDEX IX_TestOrders_Aligned_Customer
ON TestOrders_Aligned (CustomerID, OrderDate)
ON psYearly(OrderDate);  -- Aligned
GO

-- Table B: Non-aligned index
CREATE TABLE TestOrders_NonAligned (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT,
    Amount DECIMAL(10,2),
    CONSTRAINT PK_TestOrders_NonAligned PRIMARY KEY (OrderID, OrderDate)
) ON psYearly(OrderDate);

CREATE INDEX IX_TestOrders_NonAligned_Customer
ON TestOrders_NonAligned (CustomerID)
ON [PRIMARY];  -- Non-aligned
GO

-- Compare execution plans
SET STATISTICS IO ON;

-- Query with date filter (benefits from alignment)
SELECT * FROM TestOrders_Aligned
WHERE OrderDate >= '2024-01-01' AND CustomerID = 100;

SELECT * FROM TestOrders_NonAligned
WHERE OrderDate >= '2024-01-01' AND CustomerID = 100;

-- Query without date filter
SELECT * FROM TestOrders_Aligned WHERE CustomerID = 100;
SELECT * FROM TestOrders_NonAligned WHERE CustomerID = 100;

SET STATISTICS IO OFF;
GO

-- Solution 2: Smart Partition Rebuild Script
CREATE TABLE IndexMaintenanceLog (
    LogID INT IDENTITY(1,1),
    MaintenanceDate DATETIME DEFAULT GETDATE(),
    TableName VARCHAR(100),
    IndexName VARCHAR(200),
    PartitionNumber INT,
    FragmentationBefore DECIMAL(5,2),
    Action VARCHAR(50),
    DurationSeconds INT
);
GO

-- Maintenance procedure
CREATE PROCEDURE sp_RebuildFragmentedPartitions
    @TableName VARCHAR(100),
    @FragmentationThreshold DECIMAL(5,2) = 30.0,
    @MinPageCount INT = 1000
AS
BEGIN
    DECLARE @IndexName VARCHAR(200);
    DECLARE @PartitionNum INT;
    DECLARE @Fragmentation DECIMAL(5,2);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @StartTime DATETIME;
    DECLARE @Duration INT;
    
    DECLARE partition_cursor CURSOR FOR
    SELECT 
        i.name,
        ips.partition_number,
        ips.avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(
        DB_ID(), 
        OBJECT_ID(@TableName), 
        NULL, NULL, 'LIMITED'
    ) ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.avg_fragmentation_in_percent > @FragmentationThreshold
        AND ips.page_count > @MinPageCount
        AND i.index_id > 0;
    
    OPEN partition_cursor;
    FETCH NEXT FROM partition_cursor INTO @IndexName, @PartitionNum, @Fragmentation;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @StartTime = GETDATE();
        SET @SQL = 'ALTER INDEX ' + QUOTENAME(@IndexName) + 
                   ' ON ' + QUOTENAME(@TableName) + 
                   ' REBUILD PARTITION = ' + CAST(@PartitionNum AS VARCHAR(10));
        
        EXEC sp_executesql @SQL;
        
        SET @Duration = DATEDIFF(SECOND, @StartTime, GETDATE());
        
        INSERT INTO IndexMaintenanceLog 
            (TableName, IndexName, PartitionNumber, FragmentationBefore, Action, DurationSeconds)
        VALUES 
            (@TableName, @IndexName, @PartitionNum, @Fragmentation, 'REBUILD PARTITION', @Duration);
        
        FETCH NEXT FROM partition_cursor INTO @IndexName, @PartitionNum, @Fragmentation;
    END;
    
    CLOSE partition_cursor;
    DEALLOCATE partition_cursor;
    
    -- Report
    SELECT 
        TableName,
        IndexName,
        PartitionNumber,
        FragmentationBefore,
        DurationSeconds,
        MaintenanceDate
    FROM IndexMaintenanceLog
    WHERE MaintenanceDate >= DATEADD(HOUR, -1, GETDATE())
    ORDER BY MaintenanceDate DESC;
END;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. ALIGNED INDEXES
   - Same partition scheme as table
   - Enable partition elimination
   - Support partition switching
   - Required for most partition operations

2. NON-ALIGNED INDEXES
   - Different partition scheme or not partitioned
   - Useful for queries not aligned with table partitioning
   - Cannot participate in partition switching
   - Stored separately from table partitions

3. PARTITION ELIMINATION
   - Query optimizer scans only needed partitions
   - Requires partition key in WHERE clause
   - Works with aligned indexes
   - Dramatic performance improvement

4. INDEX MAINTENANCE
   - Can rebuild entire index or single partition
   - Partition-level rebuild much faster
   - REORGANIZE for less fragmentation
   - ONLINE rebuild keeps table accessible

5. STRATEGIES
   - Align indexes with table when query patterns match
   - Use non-aligned for global access patterns
   - Mix strategies based on workload
   - Columnstore works well with partitioning

6. BEST PRACTICES
   - Monitor fragmentation per partition
   - Rebuild only fragmented partitions
   - Use ONLINE for production systems
   - Consider MAXDOP for parallel rebuilds

================================================================================

NEXT STEPS:
-----------
Continue to Lesson 17.4: Partitioning Methods
Explore different partitioning approaches in depth.

================================================================================
*/
