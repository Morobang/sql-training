# Execution Plans

## Introduction

An execution plan is SQL Server's roadmap for executing a query. It shows:
- How tables are accessed (scan vs seek)
- Which indexes are used
- How tables are joined
- Estimated vs actual row counts
- Cost of each operation
- Warnings and missing indexes

Understanding execution plans is **essential** for query optimization and troubleshooting performance issues.

## Types of Execution Plans

### 1. Estimated Execution Plan
- **Generated before execution**: SQL Server estimates what it will do
- **No actual data**: Based on statistics and table metadata
- **Fast to generate**: Doesn't run the query
- **Use for**: Analyzing query logic without executing expensive queries
- **Shortcut**: Ctrl+L in SSMS

### 2. Actual Execution Plan
- **Generated during execution**: Captures what actually happened
- **Real metrics**: Actual row counts, execution time, I/O
- **Runs the query**: Executes the full query to get real data
- **Use for**: Comparing estimated vs actual (find inaccurate statistics)
- **Shortcut**: Ctrl+M in SSMS (Include Actual Execution Plan)

### 3. Live Query Statistics
- **Real-time progress**: Watch query execution as it happens
- **Visual feedback**: See data flowing through operators
- **Long-running queries**: Identify bottlenecks while query runs
- **Use for**: Debugging slow queries in progress

## Reading Execution Plans

### Flow Direction
- **Right to left**: Execution starts from rightmost operator
- **Top to bottom**: When operators at same level, top executes first
- **Arrows**: Show data flow (thickness = row count estimate)

### Key Metrics
- **Estimated Row Count**: SQL Server's guess based on statistics
- **Actual Row Count**: Real number of rows (actual plan only)
- **Estimated Cost**: Relative cost (percentage of batch)
- **Estimated Subtree Cost**: Cumulative cost including children
- **I/O Cost**: Disk reads/writes
- **CPU Cost**: Processing time

## Common Operators

### Table Access Operators

#### Table Scan (Clustered Index Scan)
- **What**: Reads entire table/clustered index
- **When**: No index available, or WHERE clause filters many rows
- **Cost**: High for large tables
- **Icon**: Table with right arrow
- **Fix**: Add index, improve WHERE clause

#### Index Scan (Nonclustered)
- **What**: Reads entire nonclustered index
- **When**: Index exists but not selective enough
- **Cost**: Medium (smaller than table scan)
- **Fix**: Add more selective index or covering index

#### Index Seek
- **What**: Jumps directly to relevant rows using index
- **When**: Index exists and query is selective
- **Cost**: Low (best option)
- **Icon**: Index with pointer
- **Goal**: Aim for index seeks in queries

#### Key Lookup (Clustered)
- **What**: Goes to clustered index to get columns not in nonclustered index
- **When**: Nonclustered index doesn't cover all needed columns
- **Cost**: High (one lookup per row)
- **Fix**: Add covering index with INCLUDE columns

#### RID Lookup
- **What**: Like key lookup but for heap tables (no clustered index)
- **When**: Heap table + nonclustered index used
- **Cost**: Very high (worse than key lookup)
- **Fix**: Add clustered index or covering index

### Join Operators

#### Nested Loops Join
- **How**: For each row in outer table, scan inner table
- **Best for**: Small datasets, joining on indexed columns
- **Cost**: Outer rows × Inner rows
- **When**: Good with index seeks on inner table

#### Merge Join
- **How**: Sorts both inputs, then merges sorted results
- **Best for**: Large datasets, both inputs sorted
- **Cost**: Sort cost + merge cost
- **When**: JOIN columns are indexed and sorted

#### Hash Match Join
- **How**: Builds hash table from smaller input, probes with larger
- **Best for**: Large datasets without suitable indexes
- **Cost**: Memory to build hash table + probe cost
- **When**: No indexes available or large many-to-many joins

### Aggregation Operators

#### Stream Aggregate
- **How**: Processes sorted input in one pass
- **Best for**: Data already sorted by GROUP BY columns
- **Cost**: Low (efficient)
- **Requires**: Sorted input

#### Hash Aggregate
- **How**: Builds hash table to group rows
- **Best for**: Unsorted data
- **Cost**: Higher (memory for hash table)
- **When**: No suitable index for sorting

### Other Operators

#### Sort
- **What**: Sorts data for ORDER BY, joins, aggregations
- **Cost**: High for large datasets
- **Fix**: Add index matching sort order

#### Filter
- **What**: Applies WHERE clause conditions
- **When**: Residual predicates after index seek
- **Cost**: Depends on selectivity

#### Compute Scalar
- **What**: Calculates expressions (CAST, math, CONCAT)
- **Cost**: Usually low

## Operator Costs

Understanding relative costs:

| Operator | Relative Cost | Impact |
|----------|---------------|--------|
| Clustered Index Seek | Very Low | ⭐⭐⭐⭐⭐ Best |
| Nonclustered Index Seek | Low | ⭐⭐⭐⭐ Excellent |
| Nonclustered Index Scan | Medium | ⭐⭐⭐ OK for small tables |
| Key Lookup | High | ⭐⭐ Avoid if possible |
| Clustered Index Scan | High | ⭐⭐ Avoid for large tables |
| Table Scan (Heap) | Very High | ⭐ Worst case |
| RID Lookup | Very High | ⭐ Add clustered index |

## Warnings in Execution Plans

### Missing Index
- **Warning**: Green text "Missing Index"
- **Meaning**: SQL Server suggests creating an index
- **Action**: Review suggestion, test before implementing
- **Note**: Suggestions not always optimal

### Implicit Conversion
- **Warning**: Orange exclamation mark
- **Meaning**: Data type mismatch causing conversion
- **Impact**: Index cannot be used efficiently
- **Fix**: Match data types in WHERE clause and columns

### High Estimate vs Actual Difference
- **Warning**: Large discrepancy in row counts
- **Meaning**: Statistics are outdated or inaccurate
- **Impact**: Wrong join order, wrong operator choice
- **Fix**: Update statistics

### Parallelism
- **Icon**: Multiple arrows/streams
- **Meaning**: Query runs on multiple CPUs
- **Good**: For large queries, faster execution
- **Bad**: Overhead for small queries (MAXDOP hint)

### Spills to TempDB
- **Warning**: Exclamation mark on hash/sort operators
- **Meaning**: Insufficient memory, spilled to disk
- **Impact**: Slow performance
- **Fix**: Increase memory grant, simplify query

## Analyzing Execution Plans

### Step-by-Step Analysis

1. **Find expensive operators** (highest % cost)
2. **Check for table scans** (replace with seeks)
3. **Look for key lookups** (add covering indexes)
4. **Compare estimated vs actual rows** (update statistics)
5. **Check for warnings** (implicit conversions, missing indexes)
6. **Verify join types** (nested loops, hash, merge)
7. **Check for sorts** (add indexes to avoid sorting)

### Questions to Ask

- Is a table scan/index scan necessary? (add index)
- Are there key lookups? (covering index)
- Is estimated row count accurate? (update statistics)
- Are joins using the best strategy? (check indexes)
- Are there implicit conversions? (fix data types)
- Is sorting happening? (index matches ORDER BY)
- Is query parallel when it shouldn't be? (MAXDOP)

## Tools for Execution Plans

### SQL Server Management Studio (SSMS)
- **Graphical plans**: Visual tree of operators
- **Ctrl+L**: Estimated execution plan
- **Ctrl+M**: Include actual execution plan
- **Right-click operator**: Properties for detailed metrics

### SET STATISTICS
```sql
SET STATISTICS IO ON;     -- Show logical reads, physical reads
SET STATISTICS TIME ON;   -- Show CPU time, elapsed time
SET SHOWPLAN_TEXT ON;     -- Text-based execution plan
```

### Dynamic Management Views (DMVs)
```sql
-- Find cached plans
sys.dm_exec_query_stats
sys.dm_exec_cached_plans
sys.dm_exec_query_plan

-- Missing indexes
sys.dm_db_missing_index_details
sys.dm_db_missing_index_group_stats
```

## Common Performance Patterns

### Pattern 1: Scan + Key Lookup
```
Index Scan → Key Lookup → Nested Loop
```
**Problem**: Reading entire index + lookups for each row
**Fix**: Create covering index

### Pattern 2: Table Scan
```
Clustered Index Scan (100% cost)
```
**Problem**: Reading entire table
**Fix**: Add index on WHERE/JOIN columns

### Pattern 3: Implicit Conversion
```
Filter (CONVERT_IMPLICIT on indexed column)
```
**Problem**: Data type mismatch prevents index use
**Fix**: Match WHERE clause data type to column

### Pattern 4: Sort Before Aggregate
```
Sort → Stream Aggregate
```
**Problem**: No index on GROUP BY columns
**Fix**: Add index on GROUP BY columns

### Pattern 5: Hash Join Instead of Nested Loops
```
Hash Match Join (large cost)
```
**Problem**: Missing index on join columns
**Fix**: Add index on foreign key

## Best Practices

### Query Writing
✅ **Do**:
- Use SARGable predicates (column = value, not function(column))
- Match data types in WHERE clause
- Select only needed columns
- Use EXISTS instead of IN for large subqueries
- Join on indexed columns

❌ **Don't**:
- Use functions on indexed columns in WHERE
- Use SELECT *
- Mix data types (INT vs VARCHAR)
- Use OR extensively (use UNION instead)
- Ignore execution plan warnings

### Index Strategy
✅ **Do**:
- Create indexes on foreign keys
- Use covering indexes for frequent queries
- Keep statistics updated
- Monitor missing index DMVs
- Remove unused indexes

❌ **Don't**:
- Over-index (slows writes)
- Ignore fragmentation
- Create duplicate indexes
- Index low-selectivity columns

### Monitoring
✅ **Do**:
- Review execution plans for slow queries
- Check actual vs estimated rows
- Monitor I/O statistics
- Update statistics regularly
- Use Query Store (SQL Server 2016+)

## Next Steps

Practice reading and optimizing execution plans:
1. `01-reading-plans.sql` - Understanding plan operators
2. `02-index-usage.sql` - Seeks vs scans, key lookups
3. `03-join-strategies.sql` - Nested loops, hash, merge joins
4. `04-optimization-examples.sql` - Real-world optimization scenarios
