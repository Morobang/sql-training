-- ========================================
-- Table Partitioning Basics
-- Partition Functions, Schemes, and Tables
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Simple Partition Function (RANGE RIGHT)
-- =============================================

-- Create partition function for yearly partitions
CREATE PARTITION FUNCTION pfSalesYear (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01');
GO

-- This creates 4 partitions:
-- Partition 1: < 2023-01-01
-- Partition 2: 2023-01-01 to < 2024-01-01
-- Partition 3: 2024-01-01 to < 2025-01-01
-- Partition 4: >= 2025-01-01

-- Check which partition a value belongs to
SELECT $PARTITION.pfSalesYear('2022-06-15') AS PartitionNum;  -- 1
SELECT $PARTITION.pfSalesYear('2023-06-15') AS PartitionNum;  -- 2
SELECT $PARTITION.pfSalesYear('2024-06-15') AS PartitionNum;  -- 3
SELECT $PARTITION.pfSalesYear('2025-06-15') AS PartitionNum;  -- 4
GO

-- =============================================
-- Example 2: Partition Scheme
-- =============================================

-- Create partition scheme (all partitions on PRIMARY filegroup)
CREATE PARTITION SCHEME psSalesYear
AS PARTITION pfSalesYear
ALL TO ([PRIMARY]);
GO

-- Alternative: Map partitions to different filegroups
-- CREATE PARTITION SCHEME psSalesYear
-- AS PARTITION pfSalesYear
-- TO ([FG2022], [FG2023], [FG2024], [FG2025]);

-- =============================================
-- Example 3: Create Partitioned Table
-- =============================================

-- Create partitioned sales table
CREATE TABLE PartitionedSales (
    SaleID INT NOT NULL,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    SaleDate DATE NOT NULL,
    Quantity INT NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_PartitionedSales PRIMARY KEY (SaleID, SaleDate)
) ON psSalesYear(SaleDate);
GO

-- NOTE: Partition key (SaleDate) must be in PRIMARY KEY!

-- =============================================
-- Example 4: Insert Data into Partitioned Table
-- =============================================

-- Insert sample data across different partitions
INSERT INTO PartitionedSales (SaleID, CustomerID, ProductID, SaleDate, Quantity, TotalAmount)
VALUES 
    (1, 101, 1, '2022-06-15', 2, 1000.00),  -- Partition 1
    (2, 102, 2, '2023-03-20', 1, 500.00),   -- Partition 2
    (3, 103, 3, '2023-09-10', 3, 1500.00),  -- Partition 2
    (4, 104, 4, '2024-01-15', 1, 750.00),   -- Partition 3
    (5, 105, 5, '2024-06-20', 2, 1200.00),  -- Partition 3
    (6, 106, 1, '2025-02-10', 1, 600.00),   -- Partition 4
    (7, 107, 2, '2025-08-25', 4, 2000.00);  -- Partition 4
GO

-- =============================================
-- Example 5: Query Partition Metadata
-- =============================================

-- View partition function details
SELECT 
    pf.name AS PartitionFunction,
    pf.type_desc AS PartitionType,
    pf.fanout AS PartitionCount
FROM sys.partition_functions pf
WHERE pf.name = 'pfSalesYear';
GO

-- View partition boundaries
SELECT 
    pf.name AS PartitionFunction,
    prv.boundary_id,
    prv.value AS BoundaryValue
FROM sys.partition_functions pf
JOIN sys.partition_range_values prv ON prv.function_id = pf.function_id
WHERE pf.name = 'pfSalesYear'
ORDER BY prv.boundary_id;
GO

-- =============================================
-- Example 6: View Partition Scheme Details
-- =============================================

-- View partition scheme
SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    ds.name AS Filegroup,
    dds.destination_id AS PartitionNumber
FROM sys.partition_schemes ps
JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id
JOIN sys.data_spaces ds ON ds.data_space_id = dds.data_space_id
WHERE ps.name = 'psSalesYear'
ORDER BY dds.destination_id;
GO

-- =============================================
-- Example 7: Check Partition Row Counts
-- =============================================

-- Row count per partition using $PARTITION
SELECT 
    $PARTITION.pfSalesYear(SaleDate) AS PartitionNum,
    MIN(SaleDate) AS MinDate,
    MAX(SaleDate) AS MaxDate,
    COUNT(*) AS RowCnt,
    SUM(TotalAmount) AS TotalRevenue
FROM PartitionedSales
GROUP BY $PARTITION.pfSalesYear(SaleDate)
ORDER BY PartitionNum;
GO

-- Row count using sys.partitions
SELECT 
    p.partition_number AS PartitionNum,
    p.rows AS RowCnt,
    prv.value AS BoundaryValue
FROM sys.partitions p
LEFT JOIN sys.partition_range_values prv 
    ON prv.function_id = (SELECT function_id FROM sys.partition_functions WHERE name = 'pfSalesYear')
    AND prv.boundary_id = p.partition_number
WHERE p.object_id = OBJECT_ID('PartitionedSales')
    AND p.index_id IN (0, 1)  -- Heap or clustered index
ORDER BY p.partition_number;
GO

-- =============================================
-- Example 8: Query with Partition Elimination
-- =============================================

-- Query 2024 data only (partition 3)
SELECT 
    SaleID,
    SaleDate,
    TotalAmount
FROM PartitionedSales
WHERE SaleDate >= '2024-01-01' AND SaleDate < '2025-01-01';
GO

-- Check execution plan: Should show "Actual Partition Count: 1"
-- This is partition elimination in action!

-- =============================================
-- Example 9: Monthly Partition Function
-- =============================================

-- Create monthly partition function
CREATE PARTITION FUNCTION pfSalesMonth (DATE)
AS RANGE RIGHT FOR VALUES (
    '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01',
    '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01',
    '2024-09-01', '2024-10-01', '2024-11-01', '2024-12-01',
    '2025-01-01'
);
GO

-- This creates 14 partitions (12 months + before + after)

CREATE PARTITION SCHEME psSalesMonth
AS PARTITION pfSalesMonth
ALL TO ([PRIMARY]);
GO

-- =============================================
-- Example 10: Integer Range Partition
-- =============================================

-- Partition by customer ID ranges
CREATE PARTITION FUNCTION pfCustomerID (INT)
AS RANGE RIGHT FOR VALUES (1000, 2000, 3000, 4000, 5000);
GO

-- This creates 7 partitions:
-- Partition 1: < 1000
-- Partition 2: 1000-1999
-- Partition 3: 2000-2999
-- Partition 4: 3000-3999
-- Partition 5: 4000-4999
-- Partition 6: >= 5000

CREATE PARTITION SCHEME psCustomerID
AS PARTITION pfCustomerID
ALL TO ([PRIMARY]);
GO

-- =============================================
-- Example 11: RANGE LEFT vs RANGE RIGHT
-- =============================================

-- RANGE LEFT: Upper boundary in left partition
CREATE PARTITION FUNCTION pfRangeLeft (INT)
AS RANGE LEFT FOR VALUES (100, 200, 300);
GO

-- Partitions:
-- 1: <= 100
-- 2: 101-200
-- 3: 201-300
-- 4: > 300

SELECT $PARTITION.pfRangeLeft(100) AS PartitionNum;  -- 1 (boundary in left)
SELECT $PARTITION.pfRangeLeft(200) AS PartitionNum;  -- 2
SELECT $PARTITION.pfRangeLeft(300) AS PartitionNum;  -- 3
GO

-- RANGE RIGHT: Upper boundary in right partition
CREATE PARTITION FUNCTION pfRangeRight (INT)
AS RANGE RIGHT FOR VALUES (100, 200, 300);
GO

-- Partitions:
-- 1: < 100
-- 2: 100-199
-- 3: 200-299
-- 4: >= 300

SELECT $PARTITION.pfRangeRight(100) AS PartitionNum;  -- 2 (boundary in right)
SELECT $PARTITION.pfRangeRight(200) AS PartitionNum;  -- 3
SELECT $PARTITION.pfRangeRight(300) AS PartitionNum;  -- 4
GO

-- =============================================
-- Example 12: Add Partition Boundary (SPLIT)
-- =============================================

-- Add new boundary to partition function
ALTER PARTITION FUNCTION pfSalesYear()
SPLIT RANGE ('2026-01-01');
GO

-- Now we have 5 partitions instead of 4

-- Verify new boundary
SELECT 
    prv.boundary_id,
    prv.value AS BoundaryValue
FROM sys.partition_range_values prv
JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
WHERE pf.name = 'pfSalesYear'
ORDER BY prv.boundary_id;
GO

-- =============================================
-- Example 13: Remove Partition Boundary (MERGE)
-- =============================================

-- Remove a boundary (must be empty or move data first)
-- MERGE combines two adjacent partitions

-- First, check if partition is empty
SELECT 
    $PARTITION.pfSalesYear(SaleDate) AS PartitionNum,
    COUNT(*) AS RowCnt
FROM PartitionedSales
GROUP BY $PARTITION.pfSalesYear(SaleDate)
ORDER BY PartitionNum;
GO

-- If partition 1 is empty, merge it
ALTER PARTITION FUNCTION pfSalesYear()
MERGE RANGE ('2023-01-01');
GO

-- Verify boundary removed
SELECT 
    prv.boundary_id,
    prv.value AS BoundaryValue
FROM sys.partition_range_values prv
JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
WHERE pf.name = 'pfSalesYear'
ORDER BY prv.boundary_id;
GO

-- =============================================
-- Example 14: Partition-Aligned Index
-- =============================================

-- Create index on same partition scheme (aligned)
CREATE NONCLUSTERED INDEX IX_PartitionedSales_CustomerDate
ON PartitionedSales(CustomerID, SaleDate)
ON psSalesYear(SaleDate);
GO

-- Aligned indexes:
-- - Easier maintenance
-- - Support partition switching
-- - Same partition scheme as table

-- =============================================
-- Example 15: Non-Aligned Index
-- =============================================

-- Create index on PRIMARY filegroup (non-aligned)
CREATE NONCLUSTERED INDEX IX_PartitionedSales_Product
ON PartitionedSales(ProductID)
ON [PRIMARY];
GO

-- Non-aligned indexes:
-- - More flexible
-- - Cannot switch partitions with this index
-- - Different partition scheme or no partitioning

-- =============================================
-- Example 16: Computed Column for Hash Partitioning
-- =============================================

-- Add computed column for simulated hash partitioning
ALTER TABLE PartitionedSales
ADD HashKey AS (SaleID % 4) PERSISTED;
GO

-- Create hash partition function
CREATE PARTITION FUNCTION pfHash (INT)
AS RANGE RIGHT FOR VALUES (1, 2, 3);
GO

-- Creates 4 partitions (0, 1, 2, 3)

CREATE PARTITION SCHEME psHash
AS PARTITION pfHash
ALL TO ([PRIMARY]);
GO

-- =============================================
-- Example 17: View All Partitioned Tables
-- =============================================

SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    i.name AS IndexName,
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    p.partition_number AS PartitionNum,
    p.rows AS RowCnt
FROM sys.partitions p
JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
WHERE p.object_id = OBJECT_ID('PartitionedSales')
ORDER BY TableName, IndexName, PartitionNum;
GO

-- =============================================
-- Example 18: Partition Statistics
-- =============================================

-- Detailed partition statistics
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    i.name AS IndexName,
    p.partition_number AS PartitionNum,
    p.rows AS RowCnt,
    au.total_pages * 8 / 1024.0 AS TotalSizeMB,
    au.used_pages * 8 / 1024.0 AS UsedSizeMB,
    au.data_pages * 8 / 1024.0 AS DataSizeMB
FROM sys.partitions p
JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units au ON au.container_id = p.partition_id
WHERE p.object_id = OBJECT_ID('PartitionedSales')
    AND i.index_id IN (0, 1)  -- Heap or clustered index
ORDER BY p.partition_number;
GO

-- =============================================
-- Example 19: Find Partition for Specific Value
-- =============================================

-- Find which partition a specific date belongs to
DECLARE @TestDate DATE = '2024-06-15';

SELECT 
    @TestDate AS TestDate,
    $PARTITION.pfSalesYear(@TestDate) AS PartitionNum,
    (SELECT MIN(value) 
     FROM sys.partition_range_values prv
     JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
     WHERE pf.name = 'pfSalesYear' 
     AND prv.boundary_id = $PARTITION.pfSalesYear(@TestDate)
    ) AS PartitionStart,
    (SELECT MIN(value) 
     FROM sys.partition_range_values prv
     JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
     WHERE pf.name = 'pfSalesYear' 
     AND prv.boundary_id = $PARTITION.pfSalesYear(@TestDate) + 1
    ) AS PartitionEnd;
GO

-- =============================================
-- Example 20: Comprehensive Partition Report
-- =============================================

-- Complete partition analysis
WITH PartitionInfo AS (
    SELECT 
        p.partition_number AS PartitionNum,
        p.rows AS RowCnt,
        au.total_pages * 8 / 1024.0 AS SizeMB,
        prv.value AS BoundaryValue
    FROM sys.partitions p
    JOIN sys.allocation_units au ON au.container_id = p.partition_id
    LEFT JOIN sys.partition_range_values prv 
        ON prv.function_id = (SELECT function_id FROM sys.partition_functions WHERE name = 'pfSalesYear')
        AND prv.boundary_id = p.partition_number
    WHERE p.object_id = OBJECT_ID('PartitionedSales')
        AND p.index_id IN (0, 1)
)
SELECT 
    PartitionNum,
    BoundaryValue AS PartitionStart,
    LEAD(BoundaryValue) OVER (ORDER BY PartitionNum) AS PartitionEnd,
    RowCnt,
    SizeMB,
    CAST(RowCnt * 100.0 / SUM(RowCnt) OVER () AS DECIMAL(5,2)) AS RowPct,
    CAST(SizeMB * 100.0 / SUM(SizeMB) OVER () AS DECIMAL(5,2)) AS SizePct
FROM PartitionInfo
ORDER BY PartitionNum;
GO

-- =============================================
-- Cleanup (commented out - uncomment to clean up)
-- =============================================

/*
-- Drop objects in correct order
DROP INDEX IF EXISTS IX_PartitionedSales_CustomerDate ON PartitionedSales;
DROP INDEX IF EXISTS IX_PartitionedSales_Product ON PartitionedSales;
DROP TABLE IF EXISTS PartitionedSales;
DROP PARTITION SCHEME psSalesYear;
DROP PARTITION SCHEME psSalesMonth;
DROP PARTITION SCHEME psCustomerID;
DROP PARTITION SCHEME psHash;
DROP PARTITION FUNCTION pfSalesYear;
DROP PARTITION FUNCTION pfSalesMonth;
DROP PARTITION FUNCTION pfCustomerID;
DROP PARTITION FUNCTION pfRangeLeft;
DROP PARTITION FUNCTION pfRangeRight;
DROP PARTITION FUNCTION pfHash;
GO
*/

-- 💡 Key Takeaways:
--
-- PARTITION FUNCTION:
-- - Defines HOW to partition (ranges/boundaries)
-- - RANGE RIGHT: Boundary value in right partition (most common)
-- - RANGE LEFT: Boundary value in left partition
-- - Creates N+1 partitions for N boundary values
-- - Use SPLIT to add boundary, MERGE to remove
--
-- PARTITION SCHEME:
-- - Defines WHERE to store partitions (filegroups)
-- - Maps partition function to physical storage
-- - ALL TO ([PRIMARY]) or specific filegroups per partition
--
-- PARTITIONED TABLE:
-- - Created ON partition scheme with partition key
-- - Partition key MUST be in PRIMARY KEY or unique constraint
-- - Appears as single table to applications
--
-- $PARTITION FUNCTION:
-- - Returns partition number for a value
-- - Useful for queries and monitoring
-- - Syntax: $PARTITION.FunctionName(value)
--
-- PARTITION ELIMINATION:
-- - SQL Server scans only relevant partitions
-- - Requires filter on partition key
-- - Check execution plan for "Actual Partition Count"
-- - Dramatic performance improvement for large tables
--
-- ALIGNED vs NON-ALIGNED INDEXES:
-- - Aligned: Same partition scheme as table (recommended)
-- - Non-Aligned: Different scheme or none (more flexible)
-- - Only aligned indexes support partition switching
--
-- SPLIT and MERGE:
-- - SPLIT: Add new boundary (creates new partition)
-- - MERGE: Remove boundary (combines two partitions)
-- - Partition must be empty before MERGE
-- - Use in sliding window pattern
--
-- METADATA QUERIES:
-- - sys.partition_functions: Function details
-- - sys.partition_schemes: Scheme mappings
-- - sys.partition_range_values: Boundary values
-- - sys.partitions: Row counts per partition
-- - sys.allocation_units: Size per partition
--
-- BEST PRACTICES:
-- - Use RANGE RIGHT for date-based partitioning
-- - Include partition key in all unique constraints
-- - Use aligned indexes for easier maintenance
-- - Monitor partition sizes and row distribution
-- - Document partition strategy clearly
-- - Test queries for partition elimination
-- - Plan for growth (SPLIT new partitions)
-- - Archive old data (SWITCH + MERGE pattern)
