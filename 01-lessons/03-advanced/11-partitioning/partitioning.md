# Lesson 11: Partitioning & Sharding

**Timeline:** 21:22:29 - 21:43:39  
**Duration:** ~21 minutes  
**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll understand:
1. When and why to partition tables
2. How to create partition functions and schemes
3. Partitioning strategies (range, list, hash)
4. Partition maintenance operations
5. Sharding concepts and strategies
6. Performance implications of partitioning

---

## Part 1: What is Partitioning?

Partitioning divides large tables into smaller, manageable pieces while treating them as a single logical table.

### Benefits
- **Performance**: Query only relevant partitions
- **Maintenance**: Rebuild/reorganize individual partitions
- **Archival**: Move old data efficiently (partition switching)
- **Parallel processing**: Multiple partitions processed simultaneously

### When to Partition
- Tables > 50GB
- Clear partitioning key (date, region, etc.)
- Queries filter by partition key
- Need fast archival/purging

---

## Part 2: Range Partitioning (Most Common)

Partition by ranges of values (typically dates).

### Step 1: Create Partition Function

```sql
-- Partition by year
CREATE PARTITION FUNCTION pf_OrderYear (DATE)
AS RANGE RIGHT FOR VALUES ('2022-01-01', '2023-01-01', '2024-01-01', '2025-01-01');

-- Creates 5 partitions:
-- P1: < 2022-01-01
-- P2: >= 2022-01-01 AND < 2023-01-01
-- P3: >= 2023-01-01 AND < 2024-01-01
-- P4: >= 2024-01-01 AND < 2025-01-01
-- P5: >= 2025-01-01
```

**RANGE RIGHT vs LEFT:**
- `RANGE RIGHT`: Boundary value belongs to right partition
- `RANGE LEFT`: Boundary value belongs to left partition

### Step 2: Create Partition Scheme

```sql
-- Map partitions to filegroups
CREATE PARTITION SCHEME ps_OrderYear
AS PARTITION pf_OrderYear
TO ([FG_2021], [FG_2022], [FG_2023], [FG_2024], [PRIMARY]);

-- Or map all to PRIMARY
CREATE PARTITION SCHEME ps_OrderYear
AS PARTITION pf_OrderYear
ALL TO ([PRIMARY]);
```

### Step 3: Create Partitioned Table

```sql
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1),
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2)
) ON ps_OrderYear(OrderDate);  -- Partition on OrderDate
```

### Step 4: Create Aligned Indexes

```sql
-- Aligned index (same partition scheme)
CREATE CLUSTERED INDEX IX_Orders_OrderDate
ON Orders(OrderDate) ON ps_OrderYear(OrderDate);

-- Non-clustered index
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON Orders(CustomerID) ON ps_OrderYear(OrderDate);
```

---

## Part 3: Viewing Partition Information

### Check Partition Ranges

```sql
SELECT 
    ps.name AS PartitionScheme,
    pf.name AS PartitionFunction,
    prv.value AS BoundaryValue,
    prv.boundary_id
FROM sys.partition_schemes ps
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
INNER JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id
ORDER BY prv.boundary_id;
```

### Check Row Distribution

```sql
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    p.partition_number,
    p.rows AS RowCount,
    prv.value AS BoundaryValue
FROM sys.partitions p
LEFT JOIN sys.partition_range_values prv 
    ON p.partition_number = prv.boundary_id
WHERE p.object_id = OBJECT_ID('Orders')
  AND p.index_id IN (0, 1)  -- Heap or clustered index
ORDER BY p.partition_number;
```

---

## Part 4: Partition Maintenance

### Add New Partition (Split)

```sql
-- Add 2026 partition
ALTER PARTITION SCHEME ps_OrderYear
NEXT USED [PRIMARY];  -- Specify filegroup for new partition

ALTER PARTITION FUNCTION pf_OrderYear()
SPLIT RANGE ('2026-01-01');
```

### Remove Partition (Merge)

```sql
-- Merge 2021 partition into 2022
ALTER PARTITION FUNCTION pf_OrderYear()
MERGE RANGE ('2022-01-01');
```

### Partition Switching (Fast Archival)

```sql
-- Create staging table with same structure
CREATE TABLE Orders_Archive_2021 (
    OrderID INT NOT NULL,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2)
) ON [FG_Archive];

-- Switch partition 1 to staging table
ALTER TABLE Orders
SWITCH PARTITION 1 TO Orders_Archive_2021;

-- Now Orders partition 1 is empty, archive table has data
-- Archive or drop Orders_Archive_2021
```

---

## Part 5: Partitioning Strategies

### Monthly Partitioning

```sql
CREATE PARTITION FUNCTION pf_OrderMonth (DATE)
AS RANGE RIGHT FOR VALUES 
('2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01', 
 '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01',
 '2024-09-01', '2024-10-01', '2024-11-01', '2024-12-01');
```

### Sliding Window Pattern

Automatically maintain fixed number of partitions (e.g., keep last 12 months).

```sql
-- Monthly job: Add next month, remove oldest month
-- 1. Add new partition
ALTER PARTITION SCHEME ps_OrderMonth NEXT USED [PRIMARY];
ALTER PARTITION FUNCTION pf_OrderMonth() SPLIT RANGE ('2025-01-01');

-- 2. Archive oldest partition
ALTER TABLE Orders SWITCH PARTITION 1 TO Orders_Archive;

-- 3. Merge oldest boundary
ALTER PARTITION FUNCTION pf_OrderMonth() MERGE RANGE ('2024-01-01');
```

---

## Part 6: List Partitioning (SQL Server 2022+)

Partition by discrete values (regions, categories).

```sql
-- Partition by region
CREATE PARTITION FUNCTION pf_Region (VARCHAR(50))
AS RANGE LEFT FOR VALUES ('East', 'West', 'North', 'South');

-- Each region in separate partition
```

---

## Part 7: Performance Considerations

### Partition Elimination (Query Optimization)

```sql
-- GOOD: Query filters on partition key
SELECT * FROM Orders
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2024-02-01';
-- Only scans 2024-01 partition

-- BAD: No partition key filter
SELECT * FROM Orders WHERE CustomerID = 100;
-- Scans all partitions
```

### Check Partition Elimination in Execution Plan

Look for "Actual Partition Count" vs "Estimated Partition Count" in plan properties.

### Index Alignment

```sql
-- Aligned index (recommended)
CREATE INDEX IX_Orders_Customer
ON Orders(CustomerID) ON ps_OrderYear(OrderDate);

-- Non-aligned index (all partitions in one filegroup)
CREATE INDEX IX_Orders_Customer
ON Orders(CustomerID) ON [PRIMARY];
```

**Aligned indexes:**
- Easier maintenance (rebuild single partition)
- Partition switching supported
- Better query performance

---

## Part 8: Sharding (Horizontal Partitioning Across Servers)

Distribute data across multiple databases/servers.

### Sharding Strategies

**1. Range-based Sharding**
```sql
-- Server 1: CustomerID 1-1,000,000
-- Server 2: CustomerID 1,000,001-2,000,000
-- Server 3: CustomerID 2,000,001+
```

**2. Hash-based Sharding**
```sql
-- Distribute evenly by hashing CustomerID
-- Hash(CustomerID) % 4 → Server 1, 2, 3, or 4
```

**3. Geographic Sharding**
```sql
-- US-East: East region customers
-- US-West: West region customers
-- EU: European customers
```

### Sharding Challenges
- **Cross-shard queries**: Expensive, complex
- **Distributed transactions**: Difficult to maintain consistency
- **Rebalancing**: Moving data between shards
- **Application complexity**: Routing logic

### Azure SQL Elastic Database Tools
```csharp
// .NET example
ShardMapManager smm = ShardMapManagerFactory.GetSqlShardMapManager(connectionString);
RangeShardMap<int> shardMap = smm.GetRangeShardMap<int>("CustomerShardMap");

// Query specific shard
int customerID = 1234;
using (SqlConnection conn = shardMap.OpenConnectionForKey(customerID, connectionString))
{
    // Query customer data
}
```

---

## Part 9: Vertical Partitioning

Split table by columns (not rows).

```sql
-- Original wide table
CREATE TABLE Products (
    ProductID INT,
    Name VARCHAR(100),
    Description VARCHAR(MAX),  -- Large
    Price DECIMAL(10,2),
    Image VARBINARY(MAX)  -- Large
);

-- Split into two tables
CREATE TABLE Products_Core (
    ProductID INT PRIMARY KEY,
    Name VARCHAR(100),
    Price DECIMAL(10,2)
);

CREATE TABLE Products_Details (
    ProductID INT PRIMARY KEY,
    Description VARCHAR(MAX),
    Image VARBINARY(MAX)
);

-- Query only core data (faster)
SELECT * FROM Products_Core;
```

---

## Part 10: Practical Example

```sql
-- Create yearly partitioned sales table
CREATE PARTITION FUNCTION pf_SalesYear (DATE)
AS RANGE RIGHT FOR VALUES ('2020-01-01', '2021-01-01', '2022-01-01', 
                            '2023-01-01', '2024-01-01');

CREATE PARTITION SCHEME ps_SalesYear
AS PARTITION pf_SalesYear ALL TO ([PRIMARY]);

CREATE TABLE Sales (
    SaleID INT IDENTITY(1,1),
    SaleDate DATE NOT NULL,
    CustomerID INT,
    Amount DECIMAL(10,2),
    CONSTRAINT PK_Sales PRIMARY KEY (SaleID, SaleDate)  -- Include partition key in PK
) ON ps_SalesYear(SaleDate);

-- Create aligned index
CREATE INDEX IX_Sales_Customer
ON Sales(CustomerID) ON ps_SalesYear(SaleDate);

-- Query benefits from partition elimination
SELECT SUM(Amount)
FROM Sales
WHERE SaleDate >= '2024-01-01' AND SaleDate < '2025-01-01';
```

---

## Practice Exercises

1. Create a monthly partitioned Orders table for the current year.
2. Write a query to view row distribution across partitions.
3. Implement a sliding window pattern to maintain 12 months of data.
4. Use partition switching to archive data from 2021.
5. Compare query performance with and without partition elimination.

---

## Key Takeaways

- Partition large tables (>50GB) by a logical key (usually date)
- Use RANGE RIGHT for date ranges
- Align indexes to partition scheme for easier maintenance
- Partition switching is extremely fast for archival
- Always filter queries by partition key for partition elimination
- Sharding distributes data across servers (horizontal partitioning)
- Vertical partitioning splits columns into separate tables

---

## Next Lesson

Continue to [Lesson 12: Advanced Analytics & AI with SQL](../12-advanced-analytics/).
