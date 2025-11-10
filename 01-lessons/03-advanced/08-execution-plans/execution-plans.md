# Lesson 8: Execution Plans

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Read and interpret graphical execution plans
2. Identify performance bottlenecks (scans, lookups, sorts)
3. Understand operators (seek, scan, join types, aggregates)
4. Use execution plan statistics to optimize queries
5. Compare estimated vs actual execution plans
6. Analyze query costs and identify expensive operations

---

## Part 1: What Are Execution Plans?

Execution plans show how SQL Server executes a query - the steps, order, and cost of each operation.

### Enabling Execution Plans (SSMS)

```sql
-- Show estimated plan (Ctrl+L)
-- or
SET SHOWPLAN_XML ON;

-- Show actual plan (Ctrl+M then run query)
-- or
SET STATISTICS XML ON;
```

---

## Part 2: Reading Plans (Right to Left, Top to Bottom)

```
Query Cost: 100%
├── SELECT (Cost: 0%)
└── Nested Loops Join (Cost: 50%)           ← Start here (rightmost)
    ├── Index Seek (Cost: 10%)             ← Inner (bottom)
    └── Clustered Index Scan (Cost: 40%)   ← Outer (top)
```

**Flow:** Right → Left, Bottom → Top

---

## Part 3: Common Operators

### Table Scan (⚠️ Slow)
```sql
-- Reads EVERY row in table
SELECT * FROM Orders WHERE ShipDate = '2024-01-01';
-- No index on ShipDate → Table Scan

-- Cost: High (proportional to table size)
```

### Clustered Index Scan (⚠️ Slow for large tables)
```sql
-- Reads all rows via clustered index
SELECT * FROM Orders WHERE Status = 'Pending';
-- No index on Status → Clustered Index Scan
```

### Index Seek (✅ Fast)
```sql
-- Jumps directly to matching rows
SELECT * FROM Orders WHERE OrderID = 1000;
-- Primary key index → Index Seek

-- Cost: Low (logarithmic)
```

### Index Scan (⚠️ Moderate)
```sql
-- Scans entire non-clustered index
SELECT CustomerID FROM Orders;
-- Covered by index → Index Scan (better than table scan)
```

---

## Part 4: Join Operators

### Nested Loops Join
```sql
-- Best for: Small datasets, indexed join columns
-- Cost: O(n * m) but fast with indexes

SELECT o.OrderID, c.CustomerName
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderID = 100;
-- Small result set → Nested Loops
```

### Hash Match Join
```sql
-- Best for: Large datasets, no indexes
-- Cost: O(n + m) + hash overhead

SELECT o.OrderID, p.ProductName
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;
-- Large tables, complex join → Hash Match
```

### Merge Join
```sql
-- Best for: Both inputs sorted, large datasets
-- Cost: O(n + m)

SELECT o.OrderID, od.ProductID
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
ORDER BY o.OrderID;
-- Both sorted on OrderID → Merge Join
```

---

## Part 5: Warnings and Issues

### Yellow Exclamation Mark (⚠️)
- **Missing index**
- **Implicit conversion**
- **Missing statistics**
- **Operator warnings**

### Red Text
- **High cost operation** (examine closely)

### Thick Arrows
- **Large row counts** flowing between operators

---

## Part 6: Key Metrics

### Cost Percentage
```
Nested Loops (Cost: 85%)  ← 85% of total query cost
```

### Estimated vs Actual Rows
```
Estimated Rows: 10
Actual Rows: 10,000  ⚠️ Bad estimate (update statistics!)
```

### Logical Reads
```sql
SET STATISTICS IO ON;
-- Table 'Orders'. Scan count 1, logical reads 1500
-- Lower is better
```

---

## Part 7: Identifying Problems

### Problem 1: Table/Index Scan on Large Table

```sql
-- BAD: Table Scan
SELECT * FROM Orders WHERE Status = 'Pending';

-- FIX: Add index
CREATE INDEX IX_Orders_Status ON Orders(Status);
```

### Problem 2: Key Lookup (Bookmark Lookup)

```sql
-- BAD: Index Seek + Key Lookup (extra table access)
SELECT OrderID, CustomerID, TotalAmount
FROM Orders
WHERE CustomerID = 100;
-- Index on CustomerID exists, but TotalAmount not included

-- FIX: Covering index
CREATE INDEX IX_Orders_CustomerID 
ON Orders(CustomerID)
INCLUDE (TotalAmount);
```

### Problem 3: Sort Operation

```sql
-- BAD: Explicit Sort (expensive)
SELECT * FROM Orders ORDER BY OrderDate DESC;
-- No index on OrderDate → Sort operator

-- FIX: Index supports ORDER BY
CREATE INDEX IX_Orders_OrderDate ON Orders(OrderDate DESC);
```

### Problem 4: Implicit Conversion

```sql
-- BAD: NVARCHAR column, VARCHAR search
SELECT * FROM Customers WHERE Email = 'test@example.com';
-- Email is NVARCHAR, literal is VARCHAR → Conversion → Scan

-- FIX: Match data types
SELECT * FROM Customers WHERE Email = N'test@example.com';
```

---

## Part 8: Estimated vs Actual Plans

### Estimated Plan
- Generated without running query
- Based on statistics
- Shows estimated row counts
- Fast to generate

### Actual Plan
- Generated after query execution
- Shows actual row counts
- Includes runtime statistics
- Reveals estimate accuracy

```sql
-- Get actual plan
SET STATISTICS XML ON;
SELECT * FROM Orders WHERE CustomerID = 100;
SET STATISTICS XML OFF;

-- Compare:
-- Estimated Rows: 10
-- Actual Rows: 500  ⚠️ Statistics out of date!
```

---

## Part 9: Query Tuning Workflow

1. **Enable actual execution plan** (Ctrl+M)
2. **Run query** and view plan
3. **Identify most expensive operator** (highest %)
4. **Look for warnings** (yellow !)
5. **Check for:**
   - Scans on large tables
   - Missing indexes
   - Key lookups
   - Implicit conversions
   - Bad estimates (actual vs estimated rows)
6. **Apply fix** (add index, rewrite query, update stats)
7. **Re-run and compare** plans

---

## Part 10: Practical Examples

### Example 1: Before Optimization

```sql
-- Query
SELECT c.CustomerName, SUM(o.TotalAmount) AS Revenue
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01'
GROUP BY c.CustomerName
ORDER BY Revenue DESC;

-- Plan shows:
-- 1. Table Scan on Orders (Cost: 50%)  ⚠️
-- 2. Hash Match Join (Cost: 30%)
-- 3. Sort (Cost: 15%)  ⚠️
-- Total Cost: 100
```

### Example 2: After Optimization

```sql
-- Add indexes
CREATE INDEX IX_Orders_Date_Customer 
ON Orders(OrderDate, CustomerID)
INCLUDE (TotalAmount);

CREATE INDEX IX_Customers_ID_Name 
ON Customers(CustomerID)
INCLUDE (CustomerName);

-- Re-run query
-- Plan now shows:
-- 1. Index Seek on Orders (Cost: 10%)  ✅
-- 2. Nested Loops Join (Cost: 5%)
-- 3. Stream Aggregate (Cost: 2%)  ✅ (no sort needed)
-- Total Cost: 20  (80% improvement!)
```

---

## Part 11: Advanced Techniques

### Using Query Hints

```sql
-- Force specific join type (use cautiously)
SELECT *
FROM Orders o
INNER LOOP JOIN OrderDetails od ON o.OrderID = od.OrderID;

-- Force index usage
SELECT *
FROM Orders WITH (INDEX(IX_Orders_CustomerID))
WHERE CustomerID = 100;
```

### Plan Guides (for queries you can't modify)

```sql
EXEC sp_create_plan_guide 
    @name = 'Guide1',
    @stmt = 'SELECT * FROM Orders WHERE CustomerID = @p1',
    @type = 'SQL',
    @hints = 'OPTION (OPTIMIZE FOR (@p1 = 100))';
```

---

## Part 12: Tools and DMVs

### Find expensive queries

```sql
SELECT TOP 10
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
    qs.total_elapsed_time / qs.execution_count AS avg_duration,
    qs.execution_count,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY avg_cpu_time DESC;
```

### Query Store (SQL Server 2016+)

```sql
-- Enable Query Store
ALTER DATABASE YourDB SET QUERY_STORE = ON;

-- View in SSMS: Database → Query Store → Top Resource Consuming Queries
```

---

## Part 13: Best Practices

- Always use **actual** execution plans for tuning
- Focus on **highest cost** operators first
- Watch for **estimate vs actual** row mismatches
- Update statistics regularly
- Avoid **table scans** on large tables
- Minimize **key lookups** with covering indexes
- Beware **implicit conversions**
- Test in **production-like environment**

---

## Practice Exercises

1. Generate execution plan for a slow query and identify the most expensive operator.
2. Find and fix a query causing a table scan with an index.
3. Identify a query with bad row estimates and update statistics to fix it.
4. Compare nested loops vs hash match join performance on a specific query.

---

## Key Takeaways

- Execution plans show query execution steps
- Read right-to-left, top-to-bottom
- Seek > Scan for performance
- Watch for warnings (yellow !)
- Compare estimated vs actual rows
- Focus on highest cost operators
- Missing indexes often show as warnings

---

## Next Lesson

Continue to [Lesson 9: Transactions Deep Dive](../09-transactions/09-transactions.md).
