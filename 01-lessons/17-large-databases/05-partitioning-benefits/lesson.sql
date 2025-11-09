/*
================================================================================
LESSON 17.5: PARTITIONING BENEFITS AND PERFORMANCE
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Measure partition elimination performance gains
2. Quantify maintenance operation improvements
3. Understand parallel query execution benefits
4. Evaluate storage and I/O benefits
5. Make data-driven partitioning decisions

Business Context:
-----------------
Understanding the measurable benefits of partitioning helps justify the
implementation effort and guides optimization decisions. This lesson provides
concrete metrics and benchmarks.

Database: PartitioningDemo
Complexity: Advanced
Estimated Time: 50 minutes

================================================================================
*/

USE PartitioningDemo;
GO

/*
================================================================================
PART 1: QUERY PERFORMANCE BENEFITS
================================================================================

Primary benefit: PARTITION ELIMINATION
SQL Server scans only partitions needed for the query
*/

-- Create large test table (partitioned)
CREATE TABLE OrdersPartitioned (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    OrderAmount DECIMAL(18,2),
    OrderStatus VARCHAR(20),
    Region VARCHAR(50),
    CONSTRAINT PK_OrdersPartitioned PRIMARY KEY (OrderID, OrderDate)
) ON psYearly(OrderDate);
GO

-- Create index
CREATE NONCLUSTERED INDEX IX_OrdersPartitioned_Customer
ON OrdersPartitioned (CustomerID, OrderDate)
INCLUDE (OrderAmount, OrderStatus)
ON psYearly(OrderDate);
GO

-- Create equivalent non-partitioned table for comparison
CREATE TABLE OrdersNonPartitioned (
    OrderID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    OrderAmount DECIMAL(18,2),
    OrderStatus VARCHAR(20),
    Region VARCHAR(50)
);
GO

CREATE NONCLUSTERED INDEX IX_OrdersNonPartitioned_Customer
ON OrdersNonPartitioned (CustomerID, OrderDate)
INCLUDE (OrderAmount, OrderStatus);
GO

-- Populate with sample data (simulate millions of rows with smaller dataset)
;WITH Numbers AS (
    SELECT TOP 10000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO OrdersPartitioned (OrderDate, CustomerID, OrderAmount, OrderStatus, Region)
SELECT 
    DATEADD(DAY, (Num % 1825), '2020-01-01') AS OrderDate,  -- 5 years of dates
    (Num % 1000) + 1 AS CustomerID,
    CAST((Num % 10000) / 100.0 AS DECIMAL(18,2)) AS OrderAmount,
    CASE (Num % 4)
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Shipped'
        ELSE 'Cancelled'
    END AS OrderStatus,
    CASE (Num % 5)
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        WHEN 3 THEN 'West'
        ELSE 'Central'
    END AS Region
FROM Numbers;
GO

-- Copy to non-partitioned table
INSERT INTO OrdersNonPartitioned (OrderDate, CustomerID, OrderAmount, OrderStatus, Region)
SELECT OrderDate, CustomerID, OrderAmount, OrderStatus, Region
FROM OrdersPartitioned;
GO

-- Update statistics
UPDATE STATISTICS OrdersPartitioned WITH FULLSCAN;
UPDATE STATISTICS OrdersNonPartitioned WITH FULLSCAN;
GO

/*
Test 1: Query Recent Data (Last 90 Days)
-----------------------------------------
This should show significant benefit from partition elimination
*/

-- Clear cache for fair comparison
CHECKPOINT;
DBCC DROPCLEANBUFFERS;  -- DON'T run in production!
DBCC FREEPROCCACHE;     -- DON'T run in production!
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Partitioned table query
DECLARE @StartDate DATE = DATEADD(DAY, -90, GETDATE());

SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalAmount
FROM OrdersPartitioned
WHERE OrderDate >= @StartDate
    AND OrderStatus = 'Completed'
GROUP BY CustomerID
HAVING SUM(OrderAmount) > 1000;
GO

/*
Note STATISTICS IO output:
- Only recent partition(s) scanned
- Fewer logical reads
- Faster execution
*/

-- Non-partitioned table query
DECLARE @StartDate DATE = DATEADD(DAY, -90, GETDATE());

SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalAmount
FROM OrdersNonPartitioned
WHERE OrderDate >= @StartDate
    AND OrderStatus = 'Completed'
GROUP BY CustomerID
HAVING SUM(OrderAmount) > 1000;
GO

/*
Note STATISTICS IO output:
- Entire table scanned
- More logical reads
- Slower execution
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Formal performance comparison
CREATE TABLE PerformanceResults (
    TestID INT IDENTITY(1,1),
    TestDate DATETIME DEFAULT GETDATE(),
    TableType VARCHAR(50),
    QueryType VARCHAR(100),
    LogicalReads BIGINT,
    ExecutionTimeMS INT,
    RowsAffected BIGINT
);
GO

-- Performance test procedure
CREATE PROCEDURE sp_ComparePerformance
    @TestDescription VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME;
    DECLARE @EndTime DATETIME;
    DECLARE @LogicalReads BIGINT;
    DECLARE @RowsAffected BIGINT;
    
    -- Test partitioned table
    CHECKPOINT;
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
    
    SET @StartTime = GETDATE();
    
    SELECT @RowsAffected = COUNT(*)
    FROM OrdersPartitioned
    WHERE OrderDate >= DATEADD(DAY, -90, GETDATE())
        AND OrderStatus = 'Completed';
    
    SET @EndTime = GETDATE();
    
    SELECT @LogicalReads = SUM(reads)
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    WHERE st.text LIKE '%OrdersPartitioned%'
        AND st.text NOT LIKE '%sys.dm_exec%';
    
    INSERT INTO PerformanceResults (TableType, QueryType, ExecutionTimeMS, RowsAffected)
    VALUES ('Partitioned', @TestDescription, DATEDIFF(MILLISECOND, @StartTime, @EndTime), @RowsAffected);
    
    -- Test non-partitioned table
    CHECKPOINT;
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
    
    SET @StartTime = GETDATE();
    
    SELECT @RowsAffected = COUNT(*)
    FROM OrdersNonPartitioned
    WHERE OrderDate >= DATEADD(DAY, -90, GETDATE())
        AND OrderStatus = 'Completed';
    
    SET @EndTime = GETDATE();
    
    INSERT INTO PerformanceResults (TableType, QueryType, ExecutionTimeMS, RowsAffected)
    VALUES ('Non-Partitioned', @TestDescription, DATEDIFF(MILLISECOND, @StartTime, @EndTime), @RowsAffected);
END;
GO

/*
================================================================================
PART 2: MAINTENANCE OPERATION BENEFITS
================================================================================

Partitioning dramatically improves index maintenance operations
*/

-- Test index rebuild performance
SET STATISTICS TIME ON;
GO

-- Rebuild entire non-partitioned index
ALTER INDEX IX_OrdersNonPartitioned_Customer
ON OrdersNonPartitioned
REBUILD;
-- Note: Time taken for ENTIRE table
GO

-- Rebuild single partition of partitioned index
ALTER INDEX IX_OrdersPartitioned_Customer
ON OrdersPartitioned
REBUILD PARTITION = 5;  -- Just current year
-- Note: Much faster - only ONE partition
GO

SET STATISTICS TIME OFF;
GO

-- Measure partition-level vs full rebuild
CREATE TABLE MaintenanceResults (
    TestID INT IDENTITY(1,1),
    TestDate DATETIME DEFAULT GETDATE(),
    Operation VARCHAR(100),
    Scope VARCHAR(50),
    DurationSeconds INT,
    PartitionNumber INT NULL
);
GO

-- Test full rebuild
DECLARE @Start DATETIME = GETDATE();

ALTER INDEX IX_OrdersPartitioned_Customer
ON OrdersPartitioned
REBUILD;

INSERT INTO MaintenanceResults (Operation, Scope, DurationSeconds)
VALUES ('Index Rebuild', 'All Partitions', DATEDIFF(SECOND, @Start, GETDATE()));
GO

-- Test partition-level rebuild
DECLARE @Start DATETIME = GETDATE();

ALTER INDEX IX_OrdersPartitioned_Customer
ON OrdersPartitioned
REBUILD PARTITION = 5;

INSERT INTO MaintenanceResults (Operation, Scope, DurationSeconds, PartitionNumber)
VALUES ('Index Rebuild', 'Single Partition', DATEDIFF(SECOND, @Start, GETDATE()), 5);
GO

-- View results
SELECT 
    Operation,
    Scope,
    DurationSeconds,
    CASE 
        WHEN Scope = 'All Partitions' THEN 100.0
        ELSE (DurationSeconds * 100.0) / 
             (SELECT DurationSeconds FROM MaintenanceResults WHERE Scope = 'All Partitions' AND Operation = 'Index Rebuild')
    END AS PercentOfFullRebuild
FROM MaintenanceResults
WHERE Operation = 'Index Rebuild'
ORDER BY TestID;
GO

/*
Typical results:
- Full rebuild: 100%
- Single partition: 10-20% (depending on partition count)
- Savings: 80-90% for active partition maintenance
*/

/*
================================================================================
PART 3: PARALLEL QUERY EXECUTION
================================================================================

Partitioning enables better parallelism
*/

-- Large aggregation query
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Partitioned table (can parallelize across partitions)
SELECT 
    YEAR(OrderDate) AS OrderYear,
    Region,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalRevenue,
    AVG(OrderAmount) AS AvgOrderValue,
    MIN(OrderAmount) AS MinOrder,
    MAX(OrderAmount) AS MaxOrder
FROM OrdersPartitioned
GROUP BY YEAR(OrderDate), Region
ORDER BY OrderYear, Region
OPTION (MAXDOP 4);  -- Allow parallelism
GO

-- View actual execution plan to see:
-- - Parallelism operators
-- - Partition distribution
-- - Thread allocation

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Analyze parallelism by partition
SELECT 
    p.partition_number,
    p.rows AS RowCount,
    au.total_pages * 8 / 1024 AS SizeMB,
    prv.value AS BoundaryValue
FROM sys.partitions p
INNER JOIN sys.allocation_units au ON p.partition_id = au.container_id
LEFT JOIN sys.partition_range_values prv 
    ON p.partition_number = prv.boundary_id + 1
    AND prv.function_id = (SELECT function_id FROM sys.partition_functions WHERE name = 'pfYearly')
WHERE p.object_id = OBJECT_ID('OrdersPartitioned')
    AND p.index_id = 1
ORDER BY p.partition_number;
GO

/*
Parallelism benefits:
- Each partition can be processed by different thread
- Better CPU utilization
- Faster query execution
- Especially beneficial for large aggregations
*/

/*
================================================================================
PART 4: DATA LOADING PERFORMANCE
================================================================================

Partition switching enables instant data loads
*/

-- Create staging table (same structure, same partition scheme)
CREATE TABLE OrdersStaging (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    OrderAmount DECIMAL(18,2),
    OrderStatus VARCHAR(20),
    Region VARCHAR(50),
    CONSTRAINT PK_OrdersStaging PRIMARY KEY (OrderID, OrderDate),
    CONSTRAINT CK_OrdersStaging_Date CHECK (OrderDate >= '2025-01-01' AND OrderDate < '2026-01-01')
) ON psYearly(OrderDate);
GO

-- Create matching index
CREATE NONCLUSTERED INDEX IX_OrdersStaging_Customer
ON OrdersStaging (CustomerID, OrderDate)
INCLUDE (OrderAmount, OrderStatus)
ON psYearly(OrderDate);
GO

-- Load data into staging
INSERT INTO OrdersStaging (OrderDate, CustomerID, OrderAmount, OrderStatus, Region)
SELECT 
    DATEADD(DAY, (n % 365), '2025-01-01'),
    (n % 1000) + 1,
    CAST((n % 5000) / 100.0 AS DECIMAL(18,2)),
    CASE (n % 4) WHEN 0 THEN 'Completed' WHEN 1 THEN 'Pending' WHEN 2 THEN 'Shipped' ELSE 'Cancelled' END,
    CASE (n % 5) WHEN 0 THEN 'North' WHEN 1 THEN 'South' WHEN 2 THEN 'East' WHEN 3 THEN 'West' ELSE 'Central' END
FROM (SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects a, sys.all_objects b) nums;
GO

-- Traditional INSERT (measured)
DECLARE @Start DATETIME = GETDATE();

INSERT INTO OrdersNonPartitioned (OrderDate, CustomerID, OrderAmount, OrderStatus, Region)
SELECT OrderDate, CustomerID, OrderAmount, OrderStatus, Region
FROM OrdersStaging;

PRINT 'Traditional INSERT took ' + CAST(DATEDIFF(MILLISECOND, @Start, GETDATE()) AS VARCHAR) + ' ms';
GO

-- Partition switch (measured)
DECLARE @Start DATETIME = GETDATE();

-- Switch staging partition into main table
-- Note: partition 5 corresponds to 2025 data
ALTER TABLE OrdersStaging 
SWITCH PARTITION 5 TO OrdersPartitioned PARTITION 5;

PRINT 'Partition SWITCH took ' + CAST(DATEDIFF(MILLISECOND, @Start, GETDATE()) AS VARCHAR) + ' ms';
GO

/*
Results:
- Traditional INSERT: Seconds to minutes (depending on size)
- Partition SWITCH: Milliseconds (metadata operation only!)
- Speed improvement: 100x - 1000x faster

Benefits of partition switching:
✓ Near-instant data loads
✓ Minimal logging
✓ No index rebuild needed
✓ Transactionally consistent
*/

/*
================================================================================
PART 5: STORAGE BENEFITS
================================================================================
*/

-- Analyze storage by partition
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    p.partition_number,
    p.rows AS RowCount,
    au.total_pages * 8 / 1024.0 AS TotalSizeMB,
    au.used_pages * 8 / 1024.0 AS UsedSizeMB,
    (au.total_pages - au.used_pages) * 8 / 1024.0 AS UnusedSizeMB,
    au.data_pages * 8 / 1024.0 AS DataSizeMB,
    prv.value AS BoundaryValue,
    fg.name AS Filegroup
FROM sys.partitions p
INNER JOIN sys.allocation_units au ON p.partition_id = au.container_id
LEFT JOIN sys.partition_range_values prv 
    ON p.partition_number = prv.boundary_id + 1
    AND prv.function_id = (SELECT function_id FROM sys.partition_functions WHERE name = 'pfYearly')
LEFT JOIN sys.destination_data_spaces dds ON p.partition_number = dds.destination_id
LEFT JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
WHERE p.object_id = OBJECT_ID('OrdersPartitioned')
    AND p.index_id IN (0, 1)
ORDER BY p.partition_number;
GO

/*
Storage benefits:
1. Old partitions can be on cheaper storage
2. Compression can vary by partition
3. Easier to archive/purge old data
4. Better space management
*/

-- Example: Compress old partitions
ALTER TABLE OrdersPartitioned
REBUILD PARTITION = 1  -- Old data
WITH (DATA_COMPRESSION = PAGE);
GO

ALTER TABLE OrdersPartitioned
REBUILD PARTITION = 5  -- Current data
WITH (DATA_COMPRESSION = NONE);  -- Keep uncompressed for performance
GO

-- Check compression savings
SELECT 
    p.partition_number,
    p.rows,
    p.data_compression_desc,
    au.total_pages * 8 / 1024.0 AS TotalSizeMB
FROM sys.partitions p
INNER JOIN sys.allocation_units au ON p.partition_id = au.container_id
WHERE p.object_id = OBJECT_ID('OrdersPartitioned')
    AND p.index_id = 1
ORDER BY p.partition_number;
GO

/*
================================================================================
PART 6: QUANTIFYING BENEFITS
================================================================================
*/

-- Create summary report of all benefits
CREATE VIEW vw_PartitioningBenefits AS
SELECT 
    'Query Performance' AS BenefitCategory,
    'Partition Elimination reduces I/O by 80-95% for date-range queries' AS Benefit,
    'High' AS Impact
UNION ALL
SELECT 'Maintenance', 'Single partition rebuild 10-20x faster than full table', 'High'
UNION ALL
SELECT 'Data Loading', 'Partition switching 100-1000x faster than INSERT', 'Very High'
UNION ALL
SELECT 'Parallelism', 'Better thread distribution improves query parallelism', 'Medium'
UNION ALL
SELECT 'Storage', 'Compress old partitions saves 50-80% storage', 'Medium'
UNION ALL
SELECT 'Archiving', 'Instant archiving via partition switch vs hours of DELETE', 'High'
UNION ALL
SELECT 'Availability', 'Partition-level operations reduce downtime', 'High';
GO

SELECT * FROM vw_PartitioningBenefits;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Measure Partition Elimination
------------------------------------------
Create a query that:
1. Queries 1 month of data from partitioned table
2. Queries same data from non-partitioned table
3. Compares logical reads and execution time
4. Calculates percentage improvement

TRY IT YOURSELF!
*/

-- Your solution here:






/*
Exercise 2: Compare Maintenance Operations
-------------------------------------------
Measure time for:
1. Full index rebuild (all partitions)
2. Single partition rebuild
3. Calculate time savings
4. Estimate monthly maintenance window reduction

TRY IT YOURSELF!
*/

-- Your solution here:






/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. QUERY PERFORMANCE
   - Partition elimination: 80-95% I/O reduction
   - Faster response times for date-range queries
   - Must include partition key in WHERE clause

2. MAINTENANCE BENEFITS
   - Single partition rebuild: 10-20x faster
   - Reduced maintenance windows
   - Less impact on production

3. DATA LOADING
   - Partition switching: 100-1000x faster than INSERT
   - Minimal logging
   - Enables efficient ETL processes

4. PARALLELISM
   - Better CPU utilization
   - Faster aggregation queries
   - Each partition processed independently

5. STORAGE SAVINGS
   - Compress old partitions: 50-80% savings
   - Tiered storage (SSD for active, HDD for archive)
   - Easier capacity planning

6. OVERALL VALUE
   - Performance: 10-100x improvements
   - Maintenance: 80-90% time reduction
   - Storage: 50-80% savings on old data
   - Availability: Less downtime
   - ROI: Very high for large tables (>100GB)

================================================================================

NEXT STEPS:
-----------
Continue to Lesson 17.6: Clustering
Learn about high availability with SQL Server clustering.

================================================================================
*/
