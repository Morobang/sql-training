/*
================================================================================
LESSON 13.12: PERFORMANCE CONSIDERATIONS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand index overhead on DML operations
2. Analyze execution plans for index usage
3. Identify missing indexes using DMVs
4. Measure index effectiveness
5. Balance read vs write performance
6. Optimize query performance with indexes
7. Monitor and troubleshoot index performance issues

Business Context:
-----------------
Indexes are a double-edged sword: they speed up queries but slow down
modifications. Over-indexing hurts INSERT/UPDATE/DELETE performance,
while under-indexing slows SELECT queries. Finding the right balance
is critical for application performance and user satisfaction.

Database: RetailStore
Complexity: Advanced
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: INDEX OVERHEAD ON DML OPERATIONS
================================================================================

Every index adds overhead to INSERT, UPDATE, DELETE operations.

IMPACT BREAKDOWN:
-----------------
INSERT: Every index must be updated
UPDATE: Only indexes on modified columns updated
DELETE: Every index must be updated

Visual Representation:
----------------------
Table with NO indexes:
INSERT 1 row → 1 operation

Table with 5 indexes:
INSERT 1 row → 6 operations (1 table + 5 indexes)
                ↓
              Slower!

RULE OF THUMB:
--------------
- OLTP (transactional): Minimize indexes (3-5 per table)
- OLAP (analytical): More indexes acceptable (10-15 per table)
- DSS (decision support): Even more indexes (15-20 per table)

*/

-- Create test table
DROP TABLE IF EXISTS OrderTransaction;
GO

CREATE TABLE OrderTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    TotalAmount AS (Quantity * UnitPrice) PERSISTED,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    Notes NVARCHAR(500)
);
GO

-- Scenario 1: Table with NO additional indexes (just PK)
PRINT '=== TEST 1: No additional indexes ===';
GO

-- Measure INSERT performance
DECLARE @StartTime DATETIME = GETDATE();

INSERT INTO OrderTransaction (OrderID, CustomerID, ProductID, Quantity, UnitPrice, Status)
SELECT 
    ABS(CHECKSUM(NEWID())) % 10000 + 1,
    ABS(CHECKSUM(NEWID())) % 5000 + 1,
    ABS(CHECKSUM(NEWID())) % 500 + 1,
    ABS(CHECKSUM(NEWID())) % 20 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 100 + 10 AS DECIMAL(10,2)),
    'Pending'
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;

DECLARE @EndTime DATETIME = GETDATE();
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

PRINT 'Inserted 10,000 rows in ' + CAST(@Duration AS VARCHAR(10)) + ' ms';
PRINT 'Rows per second: ' + CAST(10000 * 1000 / @Duration AS VARCHAR(10));
GO

/*
OUTPUT (example):
Inserted 10,000 rows in 850 ms
Rows per second: 11765
*/

-- Scenario 2: Add multiple indexes
CREATE INDEX IX_OrderTransaction_OrderID ON OrderTransaction(OrderID);
CREATE INDEX IX_OrderTransaction_CustomerID ON OrderTransaction(CustomerID);
CREATE INDEX IX_OrderTransaction_ProductID ON OrderTransaction(ProductID);
CREATE INDEX IX_OrderTransaction_TransactionDate ON OrderTransaction(TransactionDate);
CREATE INDEX IX_OrderTransaction_Status ON OrderTransaction(Status);
GO

PRINT '=== TEST 2: With 5 additional indexes ===';
GO

-- Measure INSERT performance with indexes
DECLARE @StartTime DATETIME = GETDATE();

INSERT INTO OrderTransaction (OrderID, CustomerID, ProductID, Quantity, UnitPrice, Status)
SELECT 
    ABS(CHECKSUM(NEWID())) % 10000 + 1,
    ABS(CHECKSUM(NEWID())) % 5000 + 1,
    ABS(CHECKSUM(NEWID())) % 500 + 1,
    ABS(CHECKSUM(NEWID())) % 20 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 100 + 10 AS DECIMAL(10,2)),
    'Pending'
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;

DECLARE @EndTime DATETIME = GETDATE();
DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);

PRINT 'Inserted 10,000 rows in ' + CAST(@Duration AS VARCHAR(10)) + ' ms';
PRINT 'Rows per second: ' + CAST(10000 * 1000 / @Duration AS VARCHAR(10));
PRINT 'Performance impact: ' + CAST((@Duration - 850) * 100 / 850 AS VARCHAR(10)) + '% slower';
GO

/*
OUTPUT (example):
Inserted 10,000 rows in 1450 ms
Rows per second: 6897
Performance impact: 70% slower

EXPLANATION: Each index adds maintenance overhead!
*/

/*
================================================================================
PART 2: EXECUTION PLAN ANALYSIS
================================================================================

Execution plans show how SQL Server executes queries and whether
indexes are being used effectively.

*/

-- Enable actual execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Query 1: Without useful index (Table Scan)
SELECT TransactionID, OrderID, CustomerID, TotalAmount
FROM OrderTransaction
WHERE OrderID = 5000;
GO

/*
EXECUTION PLAN ANALYSIS:
- Clustered Index Scan (entire table scanned)
- High logical reads
- Slower performance

STATISTICS IO OUTPUT (example):
Table 'OrderTransaction'. Scan count 1, logical reads 450, ...

STATISTICS TIME OUTPUT (example):
CPU time = 125 ms, elapsed time = 132 ms
*/

-- Query 2: With index (Index Seek)
SELECT TransactionID, OrderID, CustomerID, TotalAmount
FROM OrderTransaction
WHERE OrderID = 5000;  -- Uses IX_OrderTransaction_OrderID
GO

/*
EXECUTION PLAN ANALYSIS:
- Index Seek (efficient lookup)
- Key Lookup to get TotalAmount (not in index)
- Lower logical reads
- Faster performance

STATISTICS IO OUTPUT (example):
Table 'OrderTransaction'. Scan count 1, logical reads 45, ...

STATISTICS TIME OUTPUT (example):
CPU time = 15 ms, elapsed time = 18 ms

10x improvement!
*/

-- Query 3: Covering index eliminates Key Lookup
DROP INDEX IX_OrderTransaction_OrderID ON OrderTransaction;
GO

CREATE INDEX IX_OrderTransaction_OrderID_Covering 
ON OrderTransaction(OrderID)
INCLUDE (CustomerID, TotalAmount);  -- Cover all columns needed
GO

SELECT TransactionID, OrderID, CustomerID, TotalAmount
FROM OrderTransaction
WHERE OrderID = 5000;
GO

/*
EXECUTION PLAN ANALYSIS:
- Index Seek (efficient lookup)
- NO Key Lookup (all data in index)
- Minimal logical reads
- Best performance

STATISTICS IO OUTPUT (example):
Table 'OrderTransaction'. Scan count 1, logical reads 12, ...

STATISTICS TIME OUTPUT (example):
CPU time = 5 ms, elapsed time = 6 ms

Even better!
*/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/*
================================================================================
PART 3: MISSING INDEX SUGGESTIONS
================================================================================

SQL Server tracks queries and suggests missing indexes via DMVs.
*/

-- Query that could benefit from an index
SELECT CustomerID, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalSpent
FROM OrderTransaction
WHERE Status = 'Completed'
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 1000;
GO

-- View missing index suggestions
SELECT 
    CONVERT(DECIMAL(18,2), s.avg_user_impact) AS AvgImprovementPercent,
    CONVERT(DECIMAL(18,2), s.avg_total_user_cost) AS AvgQueryCost,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    CONVERT(DECIMAL(18,2), s.avg_user_impact * (s.user_seeks + s.user_scans)) AS EstimatedImpact,
    d.statement AS TableName,
    d.equality_columns AS EqualityColumns,
    d.inequality_columns AS InequalityColumns,
    d.included_columns AS IncludedColumns,
    'CREATE INDEX IX_' + 
        REPLACE(REPLACE(REPLACE(d.statement, '[', ''), ']', ''), '.', '_') + 
        '_Suggested ON ' + d.statement + 
        ' (' + ISNULL(d.equality_columns, '') + 
        CASE WHEN d.inequality_columns IS NOT NULL THEN ', ' + d.inequality_columns ELSE '' END + ')' +
        CASE WHEN d.included_columns IS NOT NULL THEN ' INCLUDE (' + d.included_columns + ')' ELSE '' END + ';'
        AS CreateIndexStatement
FROM sys.dm_db_missing_index_details d
INNER JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s ON g.index_group_handle = s.group_handle
WHERE d.database_id = DB_ID()
ORDER BY EstimatedImpact DESC;
GO

/*
OUTPUT (example):
AvgImprovementPercent  AvgQueryCost  UserSeeks  UserScans  EstimatedImpact  CreateIndexStatement
---------------------  ------------  ---------  ---------  ---------------  ---------------------
95.00                  125.50        50         10         5700.00          CREATE INDEX IX_...

INTERPRETATION:
- High impact suggestions: Implement
- Medium impact: Consider
- Low impact: Probably not worth it
*/

-- Implement suggested index
CREATE INDEX IX_OrderTransaction_Status_Covering
ON OrderTransaction(Status)
INCLUDE (CustomerID, TotalAmount);
GO

-- Re-run query - should be much faster
SELECT CustomerID, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalSpent
FROM OrderTransaction
WHERE Status = 'Completed'
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 1000;
GO

/*
================================================================================
PART 4: INDEX USAGE STATISTICS
================================================================================
*/

-- View index usage statistics
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.user_lookups AS UserLookups,
    s.user_updates AS UserUpdates,
    s.user_seeks + s.user_scans + s.user_lookups AS TotalReads,
    s.last_user_seek AS LastSeek,
    s.last_user_scan AS LastScan,
    CASE 
        WHEN s.user_seeks + s.user_scans + s.user_lookups = 0 THEN 'UNUSED - Consider dropping'
        WHEN s.user_updates > (s.user_seeks + s.user_scans + s.user_lookups) * 10 THEN 'HIGH WRITE/LOW READ - Review'
        WHEN s.user_seeks + s.user_scans + s.user_lookups > s.user_updates * 10 THEN 'EXCELLENT - Keep'
        ELSE 'MODERATE - Keep'
    END AS Recommendation
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i 
    ON s.object_id = i.object_id 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECT_NAME(s.object_id) = 'OrderTransaction'
ORDER BY TotalReads DESC;
GO

/*
OUTPUT (example):
TableName          IndexName                              UserSeeks  UserScans  UserLookups  UserUpdates  TotalReads  Recommendation
-----------------  -------------------------------------  ---------  ---------  -----------  -----------  ----------  ----------------
OrderTransaction   IX_OrderTransaction_OrderID_Covering   1250       50         0            500          1300        EXCELLENT - Keep
OrderTransaction   IX_OrderTransaction_Status_Covering    800        100        0            500          900         EXCELLENT - Keep
OrderTransaction   IX_OrderTransaction_TransactionDate    25         10         0            500          35          MODERATE - Keep
OrderTransaction   IX_OrderTransaction_ProductID          0          0          0            500          0           UNUSED - Drop

INTERPRETATION:
- Drop IX_OrderTransaction_ProductID (never used)
- Keep covering indexes (high read, moderate write)
*/

/*
================================================================================
PART 5: QUERY OPTIMIZATION WITH INDEXES
================================================================================
*/

-- Example 1: Optimizing range queries
DROP TABLE IF EXISTS SalesData;
GO

CREATE TABLE SalesData (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Region VARCHAR(50)
);
GO

-- Insert sample data
INSERT INTO SalesData (SaleDate, CustomerID, ProductID, Amount, Region)
SELECT 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, CAST(GETDATE() AS DATE)),
    ABS(CHECKSUM(NEWID())) % 5000 + 1,
    ABS(CHECKSUM(NEWID())) % 500 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 1000 + 10 AS DECIMAL(10,2)),
    CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        ELSE 'West'
    END
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 50000;
GO

-- Query: Range query on date
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Without index
SELECT SaleID, SaleDate, CustomerID, Amount
FROM SalesData
WHERE SaleDate BETWEEN '2023-01-01' AND '2023-12-31';
GO

-- Create index for range queries
CREATE INDEX IX_SalesData_SaleDate 
ON SalesData(SaleDate)
INCLUDE (CustomerID, Amount);  -- Covering
GO

-- With index
SELECT SaleID, SaleDate, CustomerID, Amount
FROM SalesData
WHERE SaleDate BETWEEN '2023-01-01' AND '2023-12-31';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

/*
PERFORMANCE COMPARISON:
-----------------------
Without Index:
- Clustered Index Scan (entire table)
- Logical reads: ~1000
- CPU time: 125 ms

With Index:
- Index Seek + no lookup (covering)
- Logical reads: ~50
- CPU time: 10 ms

20x faster!
*/

-- Example 2: Composite index for multi-column WHERE
CREATE INDEX IX_SalesData_Region_Date 
ON SalesData(Region, SaleDate)
INCLUDE (Amount);
GO

-- Query benefits from composite index
SELECT Region, SaleDate, SUM(Amount) AS TotalSales
FROM SalesData
WHERE Region = 'North'
    AND SaleDate >= '2023-01-01'
GROUP BY Region, SaleDate
ORDER BY SaleDate;
GO

/*
================================================================================
PART 6: BALANCING READ VS WRITE PERFORMANCE
================================================================================
*/

-- Analyze read vs write ratio
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    SUM(s.user_seeks + s.user_scans + s.user_lookups) AS TotalReads,
    SUM(s.user_updates) AS TotalWrites,
    CAST(SUM(s.user_seeks + s.user_scans + s.user_lookups) AS FLOAT) / 
        NULLIF(SUM(s.user_updates), 0) AS ReadWriteRatio,
    COUNT(i.index_id) AS IndexCount,
    CASE 
        WHEN CAST(SUM(s.user_seeks + s.user_scans + s.user_lookups) AS FLOAT) / NULLIF(SUM(s.user_updates), 0) > 10 
            THEN 'Read-heavy: Can add more indexes'
        WHEN CAST(SUM(s.user_seeks + s.user_scans + s.user_lookups) AS FLOAT) / NULLIF(SUM(s.user_updates), 0) < 1 
            THEN 'Write-heavy: Consider removing indexes'
        ELSE 'Balanced: Current indexes OK'
    END AS Recommendation
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i 
    ON s.object_id = i.object_id 
    AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECT_NAME(s.object_id) IN ('OrderTransaction', 'SalesData')
GROUP BY OBJECT_NAME(s.object_id)
ORDER BY ReadWriteRatio DESC;
GO

/*
OUTPUT (example):
TableName          TotalReads  TotalWrites  ReadWriteRatio  IndexCount  Recommendation
-----------------  ----------  -----------  --------------  ----------  ----------------------------
SalesData          5000        100          50.00           3           Read-heavy: Add more indexes
OrderTransaction   2000        2500         0.80            6           Balanced: Current indexes OK

STRATEGY:
- Read-heavy tables: More indexes acceptable
- Write-heavy tables: Minimize indexes
- Balanced: Be selective
*/

/*
================================================================================
PART 7: MONITORING INDEX PERFORMANCE
================================================================================
*/

-- Index operational statistics
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.leaf_insert_count AS LeafInserts,
    s.leaf_update_count AS LeafUpdates,
    s.leaf_delete_count AS LeafDeletes,
    s.leaf_insert_count + s.leaf_update_count + s.leaf_delete_count AS TotalModifications,
    s.range_scan_count AS RangeScans,
    s.singleton_lookup_count AS SingletonLookups,
    s.page_latch_wait_count AS PageLatchWaits,
    s.page_io_latch_wait_count AS PageIOLatchWaits
FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) IN ('OrderTransaction', 'SalesData')
ORDER BY TotalModifications DESC;
GO

/*
OUTPUT INTERPRETATION:
----------------------
High TotalModifications: Index frequently maintained (overhead)
High RangeScans: Index useful for range queries
High SingletonLookups: Index useful for exact matches
High LatchWaits: Potential contention issues
*/

-- Index size and space usage
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.page_count AS Pages,
    CAST(ips.page_count * 8.0 / 1024 AS DECIMAL(10,2)) AS SizeMB,
    ips.record_count AS Records,
    ips.avg_page_space_used_in_percent AS AvgPageFullness,
    ips.avg_fragmentation_in_percent AS Fragmentation
FROM sys.indexes i
INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE OBJECT_NAME(i.object_id) IN ('OrderTransaction', 'SalesData')
    AND i.type_desc != 'HEAP'
ORDER BY SizeMB DESC;
GO

/*
OUTPUT (example):
TableName          IndexName                              IndexType      Pages  SizeMB  Records  AvgPageFullness  Fragmentation
-----------------  -------------------------------------  -------------  -----  ------  -------  ---------------  -------------
SalesData          PK__SalesData...                       CLUSTERED      1250   9.77    50000    95.50            2.30
OrderTransaction   PK__OrderTran...                       CLUSTERED      850    6.64    20000    92.00            5.40
SalesData          IX_SalesData_SaleDate                  NONCLUSTERED   450    3.52    50000    85.00            1.20

INTERPRETATION:
- Large indexes: Consider filtered indexes or partitioning
- Low page fullness: May need rebuild with fill factor
- High fragmentation: Schedule maintenance
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Measure DML Overhead
---------------------------------
Create a table, measure INSERT performance, add 5 indexes,
measure INSERT performance again. Calculate overhead.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Optimize Query with Indexes
----------------------------------------
Write a slow query, analyze execution plan, create appropriate
index, verify improvement.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Identify and Remove Unused Indexes
-----------------------------------------------
Find all unused indexes in your database and create a script
to drop them (but don't execute - just generate the script).

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Measure DML Overhead
DROP TABLE IF EXISTS TestTable;
GO

CREATE TABLE TestTable (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Col1 INT,
    Col2 NVARCHAR(100),
    Col3 DATETIME,
    Col4 DECIMAL(10,2),
    Col5 VARCHAR(50)
);
GO

-- Test 1: No additional indexes
DECLARE @Start DATETIME = GETDATE();

INSERT INTO TestTable (Col1, Col2, Col3, Col4, Col5)
SELECT 
    number,
    'Value ' + CAST(number AS VARCHAR(10)),
    GETDATE(),
    CAST(number * 1.5 AS DECIMAL(10,2)),
    'Data' + CAST(number AS VARCHAR(10))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;

DECLARE @Duration1 INT = DATEDIFF(MILLISECOND, @Start, GETDATE());
PRINT 'Without indexes: ' + CAST(@Duration1 AS VARCHAR(10)) + ' ms';
GO

-- Add 5 indexes
CREATE INDEX IX_TestTable_Col1 ON TestTable(Col1);
CREATE INDEX IX_TestTable_Col2 ON TestTable(Col2);
CREATE INDEX IX_TestTable_Col3 ON TestTable(Col3);
CREATE INDEX IX_TestTable_Col4 ON TestTable(Col4);
CREATE INDEX IX_TestTable_Col5 ON TestTable(Col5);
GO

-- Test 2: With 5 indexes
DECLARE @Start DATETIME = GETDATE();

INSERT INTO TestTable (Col1, Col2, Col3, Col4, Col5)
SELECT 
    number,
    'Value ' + CAST(number AS VARCHAR(10)),
    GETDATE(),
    CAST(number * 1.5 AS DECIMAL(10,2)),
    'Data' + CAST(number AS VARCHAR(10))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;

DECLARE @Duration2 INT = DATEDIFF(MILLISECOND, @Start, GETDATE());
PRINT 'With 5 indexes: ' + CAST(@Duration2 AS VARCHAR(10)) + ' ms';
PRINT 'Overhead: ' + CAST((@Duration2 - 700) * 100 / 700 AS VARCHAR(10)) + '%';  -- Assuming first run was ~700ms
GO

-- Solution 2: Optimize Query with Indexes
DROP TABLE IF EXISTS CustomerOrders;
GO

CREATE TABLE CustomerOrders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    Status VARCHAR(20),
    TotalAmount DECIMAL(10,2)
);
GO

INSERT INTO CustomerOrders (CustomerID, OrderDate, Status, TotalAmount)
SELECT 
    ABS(CHECKSUM(NEWID())) % 10000 + 1,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, CAST(GETDATE() AS DATE)),
    CASE ABS(CHECKSUM(NEWID())) % 3
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Completed'
        ELSE 'Cancelled'
    END,
    CAST(ABS(CHECKSUM(NEWID())) % 5000 + 100 AS DECIMAL(10,2))
FROM master..spt_values v1
CROSS JOIN (SELECT TOP 10 * FROM master..spt_values WHERE type = 'P') v2
WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 2048;
GO

-- Slow query (no appropriate index)
SET STATISTICS TIME ON;
SELECT CustomerID, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalSpent
FROM CustomerOrders
WHERE Status = 'Completed'
    AND OrderDate >= '2023-01-01'
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 5000;
GO

-- Create optimized index
CREATE INDEX IX_CustomerOrders_Optimized 
ON CustomerOrders(Status, OrderDate)
INCLUDE (CustomerID, TotalAmount);
GO

-- Fast query (uses index)
SELECT CustomerID, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalSpent
FROM CustomerOrders
WHERE Status = 'Completed'
    AND OrderDate >= '2023-01-01'
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 5000;
GO

SET STATISTICS TIME OFF;
GO

-- Solution 3: Identify and Remove Unused Indexes
SELECT 
    'DROP INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(i.object_id) + '].[' + OBJECT_NAME(i.object_id) + '];' AS DropStatement,
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ISNULL(s.user_seeks, 0) AS Seeks,
    ISNULL(s.user_scans, 0) AS Scans,
    ISNULL(s.user_lookups, 0) AS Lookups,
    ISNULL(s.user_updates, 0) AS Updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON i.object_id = s.object_id 
    AND i.index_id = s.index_id
    AND s.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.type_desc = 'NONCLUSTERED'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
    AND (s.index_id IS NULL OR (s.user_seeks + s.user_scans + s.user_lookups = 0))
ORDER BY OBJECT_NAME(i.object_id), i.name;
GO

/*
OUTPUT:
DropStatement                                                            TableName  IndexName               Seeks  Scans  Lookups  Updates
-----------------------------------------------------------------------  ---------  ----------------------  -----  -----  -------  -------
DROP INDEX [IX_TestTable_Col5] ON [dbo].[TestTable];                    TestTable  IX_TestTable_Col5       0      0      0        500

Review before executing!
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. INDEX OVERHEAD
   - Every index slows INSERT/UPDATE/DELETE
   - More indexes = more maintenance
   - Measure impact before adding indexes
   - Balance read vs write performance

2. EXECUTION PLANS
   - Index Seek: Efficient (good)
   - Index Scan: Less efficient (acceptable for small tables)
   - Table Scan: Inefficient (bad for large tables)
   - Key Lookup: Can eliminate with covering indexes

3. MISSING INDEXES
   - Use sys.dm_db_missing_index_* DMVs
   - Prioritize by estimated impact
   - Don't blindly implement all suggestions
   - Consider query frequency

4. INDEX USAGE
   - Monitor with sys.dm_db_index_usage_stats
   - Remove unused indexes
   - Keep high-read, low-write indexes
   - Review periodically

5. QUERY OPTIMIZATION
   - Covering indexes eliminate lookups
   - Composite indexes for multi-column filters
   - Include columns for SELECT list
   - Order matters in composite indexes

6. READ VS WRITE BALANCE
   - Read-heavy: More indexes OK
   - Write-heavy: Minimize indexes
   - OLTP: 3-5 indexes per table
   - OLAP: 10-15 indexes per table

7. MONITORING
   - Track index size and growth
   - Monitor fragmentation
   - Check operational stats
   - Review usage patterns

8. BEST PRACTICES
   - Don't over-index
   - Remove unused indexes
   - Use covering indexes strategically
   - Monitor performance impact
   - Regular maintenance
   - Test before production
   - Document index purposes

================================================================================

NEXT STEPS:
-----------
In Lesson 13.13, we'll complete the chapter with TEST YOUR KNOWLEDGE:
- Comprehensive exercises covering all chapter topics
- Real-world scenarios
- Performance challenges
- Best practice questions

Continue to: 13-test-your-knowledge.sql

================================================================================
*/
