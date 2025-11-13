# Query Optimization

## Introduction

Query optimization is the process of improving SQL query performance through various techniques including query hints, plan guides, statistics management, and understanding parameter sniffing. This guide covers advanced optimization strategies beyond basic indexing.

## Query Hints

Query hints are directives you provide to the SQL Server query optimizer to influence execution plan generation.

### Common Query Hints

| Hint | Purpose | Use Case |
|------|---------|----------|
| `OPTION (RECOMPILE)` | Recompile query every execution | Parameter sniffing issues, volatile data |
| `OPTION (OPTIMIZE FOR)` | Optimize for specific parameter value | Known common values |
| `OPTION (OPTIMIZE FOR UNKNOWN)` | Use density vector (average) | Varying parameters |
| `OPTION (MAXDOP n)` | Limit parallelism | Reduce CXPACKET waits |
| `OPTION (FORCE ORDER)` | Use join order as written | Optimizer choosing wrong order |
| `OPTION (LOOP JOIN)` | Force nested loops | Small datasets with indexes |
| `OPTION (HASH JOIN)` | Force hash join | Large datasets without indexes |
| `OPTION (MERGE JOIN)` | Force merge join | Sorted datasets |

### Table Hints

| Hint | Effect | Risk |
|------|--------|------|
| `NOLOCK` | READ UNCOMMITTED (dirty reads) | Uncommitted/phantom data |
| `UPDLOCK` | Update lock (prevents deadlocks) | None (recommended for read-then-update) |
| `ROWLOCK` | Force row-level locks | Lock escalation still possible |
| `INDEX(index_name)` | Force specific index | Optimizer may know better |
| `FORCESEEK` | Force index seek (no scan) | May fail if seek not possible |

## Parameter Sniffing

### What Is Parameter Sniffing?

Parameter sniffing occurs when SQL Server compiles a stored procedure using the **first** parameter values it receives, then reuses that plan for all subsequent executions—even if later parameters would benefit from a different plan.

### Example Scenario

```sql
CREATE PROCEDURE usp_GetProducts @Category VARCHAR(50)
AS
    SELECT * FROM Products WHERE Category = @Category;
```

- **First execution**: `@Category = 'Electronics'` (10,000 rows) → Plan uses Index Scan
- **Cached plan used for**: `@Category = 'Specialty'` (5 rows) → Scan still used (inefficient!)

### Good vs Bad Parameter Sniffing

| Scenario | Result |
|----------|--------|
| **Good**: All parameters have similar distribution | One plan works well for all |
| **Bad**: Parameters have wildly different distributions | One plan is inefficient for some |

### Solutions

1. **OPTION (RECOMPILE)**: Recompile every time (accurate but CPU overhead)
2. **OPTION (OPTIMIZE FOR)**: Optimize for specific value (if one value dominates)
3. **OPTION (OPTIMIZE FOR UNKNOWN)**: Use average selectivity (safe middle ground)
4. **Local variables**: Break parameter sniffing (uses density vector)
5. **Plan guides**: Apply hints without changing code

## Statistics

### What Are Statistics?

Statistics are metadata about data distribution in columns and indexes. The query optimizer uses statistics to estimate row counts and choose execution plans.

### Key Concepts

- **Histogram**: Distribution of values (up to 200 steps)
- **Density**: Uniqueness measure (1/distinct values)
- **Selectivity**: Percentage of rows matching predicate
- **Cardinality Estimation**: Predicting rows returned

### When Statistics Become Outdated

- Large data modifications (> 500 + 20% of rows)
- Statistics auto-update threshold reached
- Table truncated/rebuilt
- Index rebuilt (statistics automatically updated)

### Viewing Statistics

```sql
DBCC SHOW_STATISTICS('TableName', 'IndexName');
```

Shows three result sets:
1. **Header**: Rows, pages, last update date
2. **Density Vector**: Uniqueness measures
3. **Histogram**: Value distribution

## Plan Guides

Plan guides allow you to apply query hints to queries without modifying application code.

### Types of Plan Guides

| Type | Purpose |
|------|---------|
| **OBJECT** | Apply hints to stored procedures/functions |
| **SQL** | Apply hints to ad-hoc SQL statements |
| **TEMPLATE** | Apply hints to parameterized queries |

### When to Use Plan Guides

- Third-party applications (can't modify code)
- ORM-generated queries
- Dynamic SQL where hints can't be embedded
- Testing hints without code deployment

### Limitations

- Requires exact query text match
- Difficult to maintain
- Can break with SQL Server updates
- Query Store query hints (SQL 2022+) are easier alternative

## Query Store

Query Store captures query execution history and performance metrics, enabling:

- **Historical analysis**: Track plan changes over time
- **Plan forcing**: Force specific execution plan
- **Regression detection**: Identify plan changes causing slowdowns
- **A/B testing**: Compare plan performance

### Key Features

- Automatic plan regression detection
- Query wait statistics
- Plan forcing without plan guides
- Runtime statistics aggregation

## Common Optimization Techniques

### 1. **Eliminate Implicit Conversions**

```sql
-- BAD: CustomerID is INT, parameter is VARCHAR
WHERE CustomerID = @CustomerID  -- Implicit conversion

-- GOOD: Match data types
DECLARE @CustomerID INT = 1;
WHERE CustomerID = @CustomerID
```

### 2. **Avoid Non-SARGable Predicates**

SARGable = "Search ARGument ABLE" (can use indexes)

```sql
-- NON-SARGABLE (functions on column):
WHERE YEAR(SaleDate) = 2023
WHERE UPPER(CustomerName) = 'JOHN'
WHERE Salary * 1.1 > 50000

-- SARGABLE (rewrite):
WHERE SaleDate >= '2023-01-01' AND SaleDate < '2024-01-01'
WHERE CustomerName = 'John'  -- If case-insensitive collation
WHERE Salary > 50000 / 1.1
```

### 3. **Use Covering Indexes**

Include all query columns in index (no key lookups).

```sql
CREATE NONCLUSTERED INDEX IX_Covering 
ON Sales (CustomerID) 
INCLUDE (SaleDate, TotalAmount);
```

### 4. **Update Statistics Regularly**

```sql
UPDATE STATISTICS TableName WITH FULLSCAN;
```

### 5. **Limit Parallelism When Needed**

```sql
-- Reduce CXPACKET waits
OPTION (MAXDOP 1)
```

### 6. **Use Appropriate Isolation Level**

- **Reports**: READ UNCOMMITTED or SNAPSHOT (no blocking)
- **OLTP**: READ COMMITTED (default)
- **Critical transactions**: SERIALIZABLE

## Monitoring Query Performance

### Key DMVs

| DMV | Purpose |
|-----|---------|
| `sys.dm_exec_query_stats` | Aggregated query statistics |
| `sys.dm_exec_procedure_stats` | Stored procedure performance |
| `sys.dm_exec_cached_plans` | Plans in cache |
| `sys.dm_db_missing_index_details` | Missing index recommendations |
| `sys.dm_db_index_usage_stats` | Index usage patterns |

### Key Metrics

- **Logical reads**: Pages read from cache (lower is better)
- **Physical reads**: Pages read from disk (should be minimal)
- **CPU time**: CPU milliseconds (lower is better)
- **Duration**: Total elapsed time
- **Execution count**: Plan reuse

### Baseline Queries

```sql
-- Find expensive queries by CPU
SELECT TOP 10 
    total_worker_time / execution_count AS AvgCPU,
    total_elapsed_time / execution_count AS AvgDuration,
    execution_count,
    SUBSTRING(text, (statement_start_offset/2)+1, 
              ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(text) 
                ELSE statement_end_offset END - statement_start_offset)/2) + 1) AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle)
ORDER BY total_worker_time / execution_count DESC;
```

## Best Practices

### ✅ DO

1. **Use OPTION (RECOMPILE)** for queries with widely varying parameters
2. **Update statistics** after large data modifications
3. **Monitor Query Store** for plan regressions
4. **Test hints** in development before production
5. **Use covering indexes** to eliminate key lookups
6. **Keep statistics current** (auto-update enabled)
7. **Baseline performance** before optimization

### ❌ DON'T

1. **Over-use hints** (let optimizer do its job when possible)
2. **Force specific indexes** without testing (INDEX hint)
3. **Ignore implicit conversions** (check execution plans)
4. **Leave statistics outdated** (especially after bulk loads)
5. **Use NOLOCK blindly** (understand dirty read risks)
6. **Optimize prematurely** (measure first, optimize second)
7. **Forget to test under load** (production-like concurrency)

## Common Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Functions on indexed columns | Not SARGable | Rewrite without functions |
| SELECT * | Retrieves unnecessary columns | Specify columns explicitly |
| Implicit conversions | Index not used, CPU overhead | Match data types |
| Missing WHERE clause | Table scan | Add filtering |
| OR conditions | Often causes scans | UNION or separate queries |
| Scalar subqueries in SELECT | Row-by-row execution | JOIN or window functions |
| Cursors | RBAR (Row By Agonizing Row) | Set-based operations |

## Optimization Workflow

1. **Identify slow queries** (DMVs, Query Store, user reports)
2. **Analyze execution plan** (scans, lookups, warnings)
3. **Check statistics** (outdated? Missing?)
4. **Review indexes** (missing? Unused?)
5. **Test fixes** (indexes, hints, rewrites)
6. **Measure improvement** (before/after metrics)
7. **Monitor in production** (regression detection)

## Tools

- **SQL Server Management Studio**: Execution plans, deadlock graphs
- **Database Engine Tuning Advisor**: Index recommendations
- **Query Store**: Historical analysis, plan forcing
- **Extended Events**: Detailed tracing
- **sys.dm_* views**: Performance metrics
- **sp_BlitzCache**: Brent Ozar's query analysis tool
- **Plan Explorer**: SentryOne's free plan analysis tool

## Next Steps

Practice query optimization techniques in:
- **01-query-hints.sql**: OPTION clauses and table hints
- **02-parameter-sniffing.sql**: Demonstrations and solutions
- **03-statistics-management.sql**: Viewing and maintaining statistics

## Further Reading

- [Query Hints (Microsoft Docs)](https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query)
- [Plan Guides (Microsoft Docs)](https://learn.microsoft.com/en-us/sql/relational-databases/performance/plan-guides)
- [Query Store Best Practices](https://learn.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store)
- Brent Ozar's blog: First Responder Kit
- SQL Server Execution Plans by Grant Fritchey
