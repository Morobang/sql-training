# Indexes and Performance

## Introduction

Indexes are database structures that improve query performance by allowing faster data retrieval. Think of them like a book's index - instead of scanning every page to find a topic, you look it up in the index and jump directly to the relevant pages.

However, indexes come with trade-offs:
- **Benefits**: Faster SELECT queries, improved WHERE/JOIN performance, efficient sorting
- **Costs**: Slower INSERT/UPDATE/DELETE operations, additional storage space, maintenance overhead

## Index Types

### 1. Clustered Index
- **Physical ordering**: Rows are stored in the order of the clustered index key
- **One per table**: Only one clustered index allowed (because data can only be physically ordered one way)
- **Default on PRIMARY KEY**: SQL Server automatically creates clustered index on primary key
- **Use for**: Columns frequently used in range queries (dates, IDs with sequential access)

```sql
-- Primary key automatically gets clustered index
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,  -- Clustered by default
    CustomerID INT,
    OrderDate DATE
);

-- Explicit clustered index on different column
CREATE CLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate);
```

### 2. Nonclustered Index
- **Separate structure**: Index stored separately from table data
- **Multiple allowed**: Can have up to 999 nonclustered indexes per table
- **Pointer to data**: Contains index key + row locator (clustered key or RID)
- **Use for**: Frequently searched columns, foreign keys, columns in WHERE/JOIN clauses

```sql
CREATE NONCLUSTERED INDEX IX_Customers_City ON Customers(City);
```

### 3. Covering Index (Included Columns)
- **All columns included**: Index contains all columns needed by query
- **No table lookup**: Query can be satisfied entirely from index (index seek + key lookup eliminated)
- **INCLUDE clause**: Add non-key columns to leaf level of index

```sql
-- Query: SELECT ProductName, Price FROM Products WHERE Category = 'Electronics'
-- Covering index includes ProductName and Price
CREATE NONCLUSTERED INDEX IX_Products_Category_Covering
ON Products(Category)
INCLUDE (ProductName, Price);
```

### 4. Unique Index
- **Enforces uniqueness**: No duplicate values allowed in indexed column(s)
- **Automatic on constraints**: Created automatically for PRIMARY KEY and UNIQUE constraints
- **Can be clustered or nonclustered**

```sql
CREATE UNIQUE NONCLUSTERED INDEX IX_Customers_Email ON Customers(Email);
```

### 5. Filtered Index
- **Partial index**: Index only a subset of rows using WHERE clause
- **Smaller size**: Less storage and maintenance overhead
- **Targeted queries**: Perfect for queries with common filter predicates

```sql
-- Only index active products
CREATE NONCLUSTERED INDEX IX_Products_ActiveOnly
ON Products(Category, Price)
WHERE IsActive = 1;
```

### 6. Composite Index (Multi-Column)
- **Multiple columns**: Index on 2+ columns
- **Column order matters**: Most selective column should be first
- **Left-prefix rule**: Can be used for queries filtering on leading columns

```sql
-- Can be used for: (City), (City, State), or (City, State, ZipCode)
-- Cannot be used for: (State) or (ZipCode) alone
CREATE NONCLUSTERED INDEX IX_Customers_Location 
ON Customers(City, State, ZipCode);
```

## Clustered vs Nonclustered Comparison

| Feature | Clustered | Nonclustered |
|---------|-----------|--------------|
| Physical order | Yes - data rows stored in index order | No - separate structure |
| Per table | Only 1 | Up to 999 |
| Storage | Data pages ARE the leaf level | Leaf level contains key + row locator |
| Default on | PRIMARY KEY | UNIQUE constraint, manual creation |
| Table lookup | Not needed (data is in index) | May need key lookup to get other columns |
| Best for | Range queries, ORDER BY | Point lookups, covering indexes |
| Performance impact | Slower writes (must maintain order) | Slower writes (must update index) |

## How Indexes Work

### Index Seek vs Table Scan

```sql
-- Without index: Table Scan (reads all rows)
SELECT * FROM Products WHERE Category = 'Electronics';  
-- Scans entire table

-- With index: Index Seek (jumps to relevant rows)
CREATE INDEX IX_Products_Category ON Products(Category);
SELECT * FROM Products WHERE Category = 'Electronics';  
-- Seeks directly to 'Electronics' rows
```

### Key Lookup

When a nonclustered index doesn't cover all columns needed:

```sql
-- Query needs ProductName (not in index)
CREATE INDEX IX_Products_Price ON Products(Price);

SELECT ProductName, Price FROM Products WHERE Price > 100;
-- 1. Index seek on IX_Products_Price (finds matching rows)
-- 2. Key lookup to clustered index (gets ProductName)
-- 3. Results combined

-- Eliminate key lookup with covering index
CREATE INDEX IX_Products_Price_Covering ON Products(Price) INCLUDE (ProductName);
-- Now: Index seek only, no key lookup needed!
```

## Index Design Guidelines

### 1. Selectivity
- **High selectivity** = Few rows match (good for indexes)
  - Example: Email address, CustomerID
- **Low selectivity** = Many rows match (bad for indexes)
  - Example: Gender (M/F), Boolean flags

```sql
-- Good: High selectivity
CREATE INDEX IX_Customers_Email ON Customers(Email);

-- Bad: Low selectivity (use filtered index instead)
CREATE INDEX IX_Products_IsActive ON Products(IsActive);  -- Not useful

-- Better: Filtered index for common case
CREATE INDEX IX_Products_Active ON Products(Category, Price) WHERE IsActive = 1;
```

### 2. Column Order in Composite Indexes
- **Equality first**: Columns in WHERE = condition
- **Range second**: Columns in range conditions (>, <, BETWEEN)
- **Sort last**: Columns in ORDER BY

```sql
-- Query: WHERE City = 'Chicago' AND State = 'IL' ORDER BY ZipCode
CREATE INDEX IX_Customers_Location ON Customers(City, State, ZipCode);
```

### 3. INCLUDE Columns
- **Non-key columns**: Add frequently selected columns
- **Avoid wide keys**: Don't make every column a key column
- **Leaf level only**: INCLUDE columns only stored at leaf level (not in B-tree)

```sql
-- Key: Category (used in WHERE)
-- Include: ProductName, Price (used in SELECT)
CREATE INDEX IX_Products_Category ON Products(Category) 
INCLUDE (ProductName, Price);
```

## Index Maintenance

### Fragmentation

As data changes, indexes become fragmented:
- **Internal fragmentation**: Pages not filled to capacity (wasted space)
- **External fragmentation**: Logical order doesn't match physical order

```sql
-- Check fragmentation
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
ORDER BY ips.avg_fragmentation_in_percent DESC;
```

### Rebuild vs Reorganize

| Operation | Fragmentation Level | Action | Impact |
|-----------|---------------------|--------|--------|
| REORGANIZE | 10-30% | Defragment leaf level, online operation | Low - minimal blocking |
| REBUILD | > 30% | Drop and recreate index | High - table locked (unless ONLINE=ON) |

```sql
-- Reorganize (online, low impact)
ALTER INDEX IX_Products_Category ON Products REORGANIZE;

-- Rebuild (offline by default, complete defragmentation)
ALTER INDEX IX_Products_Category ON Products REBUILD;

-- Rebuild online (Enterprise Edition)
ALTER INDEX IX_Products_Category ON Products REBUILD WITH (ONLINE = ON);

-- Rebuild all indexes on table
ALTER INDEX ALL ON Products REBUILD;
```

### Statistics

Statistics help SQL Server estimate row counts and choose optimal execution plans:
- **Auto-created**: On indexed columns
- **Auto-updated**: When ~20% of rows change
- **Manual updates**: Recommended after large data changes

```sql
-- Update statistics
UPDATE STATISTICS Products;

-- Update specific index statistics
UPDATE STATISTICS Products IX_Products_Category;

-- View statistics information
DBCC SHOW_STATISTICS('Products', 'IX_Products_Category');
```

## Performance Best Practices

### 1. Start with These Indexes
- **Primary key**: Clustered index on ID column
- **Foreign keys**: Nonclustered indexes for JOIN performance
- **WHERE clauses**: Index frequently filtered columns
- **ORDER BY**: Index columns used in sorting

### 2. Monitor and Tune
- **Missing index DMVs**: SQL Server tracks missing indexes
- **Unused indexes**: Remove indexes that aren't used
- **Execution plans**: Identify index seeks vs scans

```sql
-- Find missing indexes
SELECT 
    migs.avg_user_impact,
    migs.user_seeks,
    mid.statement,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
ORDER BY migs.avg_user_impact DESC;

-- Find unused indexes
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc,
    ius.user_seeks,
    ius.user_scans,
    ius.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.index_id > 0  -- Exclude heap
    AND ius.user_seeks IS NULL  -- Never used for seeks
    AND ius.user_scans IS NULL;  -- Never used for scans
```

### 3. Avoid Over-Indexing
- **Write penalty**: Each index slows INSERT/UPDATE/DELETE
- **Storage cost**: Indexes require disk space
- **Maintenance overhead**: More indexes to rebuild/reorganize
- **Rule of thumb**: Start with 3-5 indexes per table, add based on actual queries

### 4. Use Covering Indexes Strategically
- **Frequently executed queries**: Cover your top 10-20 queries
- **Report queries**: Covering indexes eliminate key lookups
- **Balance**: Don't create covering index for every possible query

## Common Pitfalls

❌ **Don't**:
- Index low-selectivity columns (Gender, IsActive)
- Create duplicate indexes (same columns in same order)
- Over-index small tables (< 1000 rows)
- Index every column "just in case"
- Ignore fragmentation and statistics

✅ **Do**:
- Index foreign keys
- Use filtered indexes for common subsets
- Monitor missing index DMVs
- Regularly rebuild/reorganize fragmented indexes
- Drop unused indexes
- Update statistics after bulk operations
- Test index changes in non-production first

## Next Steps

Practice creating and analyzing indexes in the accompanying SQL files:
1. `01-clustered-indexes.sql` - Clustered index fundamentals
2. `02-nonclustered-indexes.sql` - Nonclustered index patterns
3. `03-covering-indexes.sql` - Covering indexes and key lookups
4. `04-filtered-indexes.sql` - Filtered index optimization
5. `05-index-maintenance.sql` - Fragmentation, rebuild, reorganize, statistics
