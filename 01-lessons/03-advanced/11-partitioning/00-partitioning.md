# Table Partitioning

## Overview

Table partitioning is a database design technique that divides a large table into smaller, more manageable pieces called **partitions**, while maintaining the appearance of a single table to applications. Each partition is stored separately but queried as a single logical table.

## Why Partition Tables?

### Performance Benefits
- **Query Performance**: Partition elimination allows queries to scan only relevant partitions
- **Parallel Processing**: Multiple partitions can be processed simultaneously
- **Index Maintenance**: Rebuild indexes on individual partitions instead of entire table
- **Statistics Updates**: Update statistics per partition for faster maintenance

### Manageability Benefits
- **Archival Operations**: Move old data to archive tables with metadata-only operations
- **Data Loading**: Load new data into specific partitions without affecting others
- **Backup/Restore**: Backup and restore individual partitions
- **Storage Management**: Place partitions on different filegroups/drives

### When to Partition
- Table size > 1 GB (general guideline)
- Clear partitioning key (date, region, category)
- Queries filter on partition key
- Historical data archival needs
- Large data loads/deletes on specific ranges

## Partitioning Concepts

### Partition Function
Defines **how** to partition data - the ranges or values that determine partition placement.

**Types:**
- **RANGE LEFT**: Upper boundary belongs to left partition (most common for dates)
- **RANGE RIGHT**: Upper boundary belongs to right partition

**Example:**
```sql
-- RANGE RIGHT: Boundary values go to right partition
CREATE PARTITION FUNCTION pfSales (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01');

-- Creates 4 partitions:
-- Partition 1: < 2023-01-01
-- Partition 2: 2023-01-01 to < 2024-01-01
-- Partition 3: 2024-01-01 to < 2025-01-01
-- Partition 4: >= 2025-01-01
```

### Partition Scheme
Defines **where** to store partitions - maps partition function to filegroups.

**Example:**
```sql
CREATE PARTITION SCHEME psSales
AS PARTITION pfSales
TO ([PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY]);
-- Or: ALL TO ([PRIMARY])
```

### Partitioned Table
A table created using a partition scheme.

**Example:**
```sql
CREATE TABLE PartitionedSales (
    SaleID INT,
    SaleDate DATE,
    Amount DECIMAL(10,2)
) ON psSales(SaleDate);
```

## Partition Function Types

| Type | Boundary Placement | Use Case |
|------|-------------------|----------|
| **RANGE LEFT** | Upper boundary in left partition | Less common |
| **RANGE RIGHT** | Upper boundary in right partition | Most common for dates |

**RANGE RIGHT Example:**
```
Values: (100, 200, 300)
Partition 1: < 100
Partition 2: 100 to < 200
Partition 3: 200 to < 300
Partition 4: >= 300
```

**RANGE LEFT Example:**
```
Values: (100, 200, 300)
Partition 1: <= 100
Partition 2: > 100 to <= 200
Partition 3: > 200 to <= 300
Partition 4: > 300
```

## Partitioning Strategies

### Date-Based Partitioning (Most Common)
Partition by year, month, quarter, or day.

**Use Cases:**
- Sales transactions by month
- Log tables by day
- Historical data archival

**Example:**
```sql
-- Monthly partitions
CREATE PARTITION FUNCTION pfMonthly (DATE)
AS RANGE RIGHT FOR VALUES 
    ('2024-01-01', '2024-02-01', '2024-03-01', ..., '2025-01-01');
```

### Range-Based Partitioning
Partition by numeric ranges.

**Use Cases:**
- Customer ID ranges
- Price ranges
- Account balance ranges

**Example:**
```sql
-- Customer ID ranges (1M per partition)
CREATE PARTITION FUNCTION pfCustomerID (INT)
AS RANGE RIGHT FOR VALUES (1000000, 2000000, 3000000);
```

### Hash/List Partitioning
SQL Server doesn't support hash partitioning directly, but you can simulate it.

**Simulated Hash:**
```sql
-- Computed column for hash
ALTER TABLE Sales
ADD PartitionKey AS (SaleID % 10) PERSISTED;

CREATE PARTITION FUNCTION pfHash (INT)
AS RANGE RIGHT FOR VALUES (1, 2, 3, 4, 5, 6, 7, 8, 9);
```

## Sliding Window Pattern

The **sliding window** is the most common partitioning maintenance pattern. It involves:
1. **SPLIT**: Add new partition for incoming data
2. **SWITCH OUT**: Move old partition to archive table (metadata-only operation)
3. **MERGE**: Remove empty old partition from function

**Benefits:**
- Near-instant archival (metadata operation)
- No downtime
- Minimal logging
- Maintains historical data

**Example Workflow:**
```sql
-- 1. SPLIT: Add partition for new month
ALTER PARTITION FUNCTION pfSales() SPLIT RANGE ('2025-02-01');

-- 2. SWITCH: Move old data to archive (metadata operation!)
ALTER TABLE Sales SWITCH PARTITION 1 TO ArchiveSales;

-- 3. MERGE: Remove old boundary
ALTER PARTITION FUNCTION pfSales() MERGE RANGE ('2023-01-01');
```

## Partition Elimination

When a query filters on the partition key, SQL Server can **eliminate** partitions from the scan, dramatically improving performance.

**Example:**
```sql
-- Only scans partition 3 (2024 data)
SELECT * FROM PartitionedSales
WHERE SaleDate >= '2024-01-01' AND SaleDate < '2025-01-01';
```

**Check Execution Plan:**
- Look for "Actual Partitions Accessed"
- Should be fewer than total partitions

## Partition-Aligned Indexes

**Aligned Indexes**: Use same partition scheme as table
- Easier maintenance
- Support partition switching
- Required for clustered indexes

**Non-Aligned Indexes**: Use different scheme or no scheme
- More flexible
- Cannot switch partitions
- More complex maintenance

**Best Practice:** Use aligned indexes unless you have a specific reason not to.

## Limitations and Considerations

### Limitations
- Maximum 15,000 partitions per table
- Partition key must be part of unique constraints/primary keys
- Cannot partition across databases
- SWITCH requires identical structure and indexes
- All partitions must be on accessible filegroups

### Design Considerations
- **Partition Key**: Choose carefully - changing is difficult
- **Partition Size**: Balance between too many (overhead) and too few (not granular enough)
- **Filegroups**: Consider using multiple filegroups for I/O distribution
- **Statistics**: Auto-update statistics per partition
- **Queries**: Ensure queries filter on partition key

### Performance Considerations
- Partition elimination requires filter on partition key
- Too many partitions can slow metadata operations
- Non-aligned indexes prevent partition switching
- Parallelism works best with multiple partitions

## Monitoring Partitions

### Key Queries
```sql
-- Partition row counts
SELECT 
    $PARTITION.pfSales(SaleDate) AS PartitionNum,
    COUNT(*) AS RowCount
FROM PartitionedSales
GROUP BY $PARTITION.pfSales(SaleDate);

-- Partition details
SELECT 
    p.partition_number,
    p.rows,
    prv.value AS BoundaryValue
FROM sys.partitions p
JOIN sys.partition_functions pf ON pf.name = 'pfSales'
JOIN sys.partition_range_values prv ON prv.function_id = pf.function_id
WHERE p.object_id = OBJECT_ID('PartitionedSales');
```

## Best Practices

**DO:**
- ✅ Partition tables > 1 GB with clear partition key
- ✅ Use RANGE RIGHT for date-based partitioning
- ✅ Implement sliding window for data archival
- ✅ Use aligned indexes for easier maintenance
- ✅ Monitor partition sizes and row distribution
- ✅ Test SWITCH operations thoroughly
- ✅ Filter queries on partition key for elimination
- ✅ Document partition strategy and maintenance schedule

**DON'T:**
- ❌ Partition small tables (< 1 GB)
- ❌ Use too many partitions (diminishing returns)
- ❌ Forget to include partition key in constraints
- ❌ Change partition function without planning
- ❌ Use non-aligned indexes unless necessary
- ❌ Ignore partition elimination in queries
- ❌ Archive without testing SWITCH operations
- ❌ Mix aligned and non-aligned indexes unnecessarily

## Common Patterns

### Monthly Archival
```sql
-- Keep 12 months of data, archive older
-- Monthly: SPLIT new month, SWITCH old month, MERGE boundary
```

### Yearly Partitions
```sql
-- One partition per year
-- Good for historical data with yearly analysis
```

### Daily Partitions for Logs
```sql
-- High-volume logs
-- Daily partitions, archive after 30 days
```

### Hot/Warm/Cold Storage
```sql
-- Recent partitions on fast storage (SSD)
-- Older partitions on slower storage (HDD)
-- Archived partitions on cheapest storage
```

## Next Steps

Practice partitioning with these files:
- **01-partition-basics.sql**: Create partition functions, schemes, and partitioned tables
- **02-sliding-window.sql**: Implement sliding window archival pattern
- **03-partition-maintenance.sql**: Rebuild, statistics, and monitoring

## Additional Resources

- **sys.partitions**: Partition metadata
- **sys.partition_functions**: Partition function details
- **sys.partition_schemes**: Partition scheme mappings
- **$PARTITION function**: Determine partition number for a value
- **Execution plans**: Check for partition elimination
