# Lesson 10: Query Optimization & 30x Performance Tips

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll master:
1. 30 proven performance optimization techniques
2. Query rewriting for better execution plans
3. Index optimization strategies
4. Avoiding common performance pitfalls
5. Using query hints strategically
6. Database design for performance

---

## 🚀 30 Performance Tips

### **Category 1: Indexing (Tips 1-8)**

#### 1. Index Foreign Keys
```sql
-- BAD: No index on FK
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT  -- No index
);

-- GOOD: Index FK
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
```

#### 2. Use Covering Indexes
```sql
-- Query needs: CustomerID, OrderDate, Total
CREATE INDEX IX_Orders_Customer_Covering
ON Orders(CustomerID)
INCLUDE (OrderDate, TotalAmount);
```

#### 3. Index Column Order Matters
```sql
-- Most selective column first
CREATE INDEX IX_Orders_Date_Customer
ON Orders(OrderDate, CustomerID);  -- If filtering by date more often
```

#### 4. Use Filtered Indexes
```sql
-- Index only active records
CREATE INDEX IX_Customers_Active
ON Customers(LastName, FirstName)
WHERE IsActive = 1;
```

#### 5. Remove Unused Indexes
```sql
-- Find unused indexes
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    user_seeks, user_scans, user_lookups, user_updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE user_seeks = 0 AND user_scans = 0 AND user_lookups = 0
  AND OBJECT_NAME(s.object_id) NOT LIKE 'sys%';
```

#### 6. Rebuild Fragmented Indexes
```sql
-- Fragmentation > 30%: rebuild
ALTER INDEX ALL ON Orders REBUILD;
```

#### 7. Update Statistics Regularly
```sql
UPDATE STATISTICS Orders WITH FULLSCAN;
```

#### 8. Avoid Functions on Indexed Columns
```sql
-- BAD: Function prevents index use
WHERE YEAR(OrderDate) = 2024;

-- GOOD: Sargable (can use index)
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
```

---

### **Category 2: Query Writing (Tips 9-16)**

#### 9. SELECT Only Needed Columns
```sql
-- BAD
SELECT * FROM Orders;

-- GOOD
SELECT OrderID, CustomerID, TotalAmount FROM Orders;
```

#### 10. Use EXISTS Instead of IN for Subqueries
```sql
-- BAD: IN with subquery
SELECT * FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM Orders);

-- GOOD: EXISTS (stops at first match)
SELECT * FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);
```

#### 11. Avoid OR - Use UNION Instead
```sql
-- BAD: OR prevents index usage
SELECT * FROM Products WHERE CategoryID = 1 OR CategoryID = 5;

-- GOOD: UNION uses indexes
SELECT * FROM Products WHERE CategoryID = 1
UNION
SELECT * FROM Products WHERE CategoryID = 5;
```

#### 12. Use WHERE Instead of HAVING When Possible
```sql
-- BAD: HAVING filters after grouping
SELECT CustomerID, COUNT(*)
FROM Orders
GROUP BY CustomerID
HAVING CustomerID > 100;

-- GOOD: WHERE filters before grouping
SELECT CustomerID, COUNT(*)
FROM Orders
WHERE CustomerID > 100
GROUP BY CustomerID;
```

#### 13. Avoid NOT IN with NULLs
```sql
-- BAD: NOT IN fails with NULLs
SELECT * FROM Products
WHERE CategoryID NOT IN (SELECT CategoryID FROM Categories WHERE IsActive = 0);

-- GOOD: NOT EXISTS
SELECT * FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM Categories c 
    WHERE c.CategoryID = p.CategoryID AND c.IsActive = 0
);
```

#### 14. Use TOP/LIMIT for Large Result Sets
```sql
-- BAD: Return millions of rows
SELECT * FROM Orders ORDER BY OrderDate DESC;

-- GOOD: Limit results
SELECT TOP 100 * FROM Orders ORDER BY OrderDate DESC;
```

#### 15. Avoid SELECT DISTINCT if Possible
```sql
-- BAD: DISTINCT is expensive
SELECT DISTINCT CustomerID FROM Orders;

-- GOOD: GROUP BY if you need aggregates anyway
SELECT CustomerID, COUNT(*) FROM Orders GROUP BY CustomerID;
```

#### 16. Use UNION ALL Instead of UNION
```sql
-- BAD: UNION removes duplicates (expensive)
SELECT Name FROM Customers
UNION
SELECT Name FROM Suppliers;

-- GOOD: UNION ALL (no deduplication)
SELECT Name FROM Customers
UNION ALL
SELECT Name FROM Suppliers;
```

---

### **Category 3: Data Types (Tips 17-20)**

#### 17. Use Appropriate Data Types
```sql
-- BAD: Oversized types
CREATE TABLE Products (
    ProductID INT,
    Price DECIMAL(38,10),  -- Too large
    InStock BIT
);

-- GOOD: Right-sized types
CREATE TABLE Products (
    ProductID INT,
    Price DECIMAL(10,2),
    InStock BIT
);
```

#### 18. Avoid Implicit Conversions
```sql
-- BAD: VARCHAR compared to NVARCHAR
SELECT * FROM Customers WHERE Email = 'test@example.com';  -- Email is NVARCHAR

-- GOOD: Match types
SELECT * FROM Customers WHERE Email = N'test@example.com';
```

#### 19. Use INT for Primary Keys (Not GUID)
```sql
-- BAD: GUID causes fragmentation
CREATE TABLE Orders (
    OrderID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY
);

-- GOOD: INT is sequential
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY
);
```

#### 20. Avoid VARCHAR(MAX) Unless Necessary
```sql
-- BAD: VARCHAR(MAX) can't be indexed properly
Notes VARCHAR(MAX)

-- GOOD: Fixed size if known
Notes VARCHAR(500)
```

---

### **Category 4: Joins (Tips 21-24)**

#### 21. Join on Indexed Columns
```sql
-- Ensure both join columns are indexed
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_Customers_CustomerID ON Customers(CustomerID);  -- PK already indexed

SELECT *
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID;
```

#### 22. Use INNER JOIN Instead of WHERE for Joins
```sql
-- BAD: Old-style join
SELECT * FROM Orders o, Customers c
WHERE o.CustomerID = c.CustomerID;

-- GOOD: ANSI standard
SELECT * FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID;
```

#### 23. Filter Early in JOINs
```sql
-- BAD: Filter after join
SELECT *
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= '2024-01-01';

-- GOOD: Filter in subquery/CTE first
SELECT *
FROM (SELECT * FROM Orders WHERE OrderDate >= '2024-01-01') o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID;
```

#### 24. Avoid Joining Large Tables Without Filters
```sql
-- BAD: Cartesian product risk
SELECT * FROM Orders o
CROSS JOIN Products p;

-- GOOD: Use proper join conditions
SELECT * FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;
```

---

### **Category 5: Advanced Techniques (Tips 25-30)**

#### 25. Use Temp Tables for Complex Queries
```sql
-- Break complex query into steps
SELECT OrderID, CustomerID, TotalAmount
INTO #TempOrders
FROM Orders
WHERE OrderDate >= '2024-01-01';

CREATE INDEX IX_Temp ON #TempOrders(CustomerID);

SELECT c.CustomerName, SUM(t.TotalAmount)
FROM #TempOrders t
INNER JOIN Customers c ON t.CustomerID = c.CustomerID
GROUP BY c.CustomerName;
```

#### 26. Use Table Variables for Small Datasets Only
```sql
-- GOOD: Small result set
DECLARE @RecentOrders TABLE (OrderID INT, TotalAmount DECIMAL(10,2));
INSERT INTO @RecentOrders
SELECT TOP 10 OrderID, TotalAmount FROM Orders ORDER BY OrderDate DESC;

-- BAD: Large result set (use temp table instead)
```

#### 27. Partition Large Tables
```sql
CREATE PARTITION FUNCTION pf_OrderDate (DATE)
AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01');

CREATE PARTITION SCHEME ps_OrderDate
AS PARTITION pf_OrderDate ALL TO ([PRIMARY]);

CREATE TABLE Orders (
    OrderID INT,
    OrderDate DATE,
    ...
) ON ps_OrderDate(OrderDate);
```

#### 28. Use NOLOCK Hint for Reporting (Carefully)
```sql
-- Read uncommitted data (no locks)
SELECT * FROM Orders WITH (NOLOCK)
WHERE OrderDate >= '2024-01-01';

-- WARNING: May read dirty data
```

#### 29. Batch Large DELETE/UPDATE Operations
```sql
-- BAD: Delete millions of rows at once
DELETE FROM Orders WHERE OrderDate < '2020-01-01';

-- GOOD: Batch delete
WHILE 1 = 1
BEGIN
    DELETE TOP (10000) FROM Orders WHERE OrderDate < '2020-01-01';
    IF @@ROWCOUNT < 10000 BREAK;
    WAITFOR DELAY '00:00:01';  -- Pause between batches
END;
```

#### 30. Use Computed Columns for Frequent Calculations
```sql
-- Computed column (persisted and indexed)
ALTER TABLE Orders
ADD TotalWithTax AS (TotalAmount * 1.08) PERSISTED;

CREATE INDEX IX_Orders_TotalWithTax ON Orders(TotalWithTax);

-- Now fast:
SELECT * FROM Orders WHERE TotalWithTax > 100;
```

---

## 📊 Performance Monitoring Queries

### Find Slowest Queries
```sql
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS avg_duration_ms,
    qs.execution_count,
    SUBSTRING(qt.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY avg_duration_ms DESC;
```

### Find Most CPU-Intensive Queries
```sql
SELECT TOP 10
    qs.total_worker_time / qs.execution_count AS avg_cpu_time,
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

---

## 🎯 Quick Performance Checklist

Before deploying a query, check:
- [ ] Indexes exist on filter/join columns?
- [ ] SELECT only needed columns?
- [ ] No functions on indexed columns in WHERE?
- [ ] Appropriate data types (no implicit conversion)?
- [ ] Execution plan reviewed?
- [ ] Statistics up to date?
- [ ] No table scans on large tables?
- [ ] Tested with production-like data volume?

---

## Practice Exercises

1. Rewrite a slow query using 5 tips from this lesson.
2. Find and fix the top 3 slowest queries in a database.
3. Create a performance baseline, apply optimizations, measure improvement.
4. Design an indexing strategy for a new table based on expected query patterns.

---

## Key Takeaways

- Index strategically (FKs, WHERE, JOIN columns)
- Write sargable queries (no functions on indexed columns)
- SELECT only needed columns
- Use EXISTS over IN for subqueries
- Batch large operations
- Monitor and measure performance regularly
- Test with realistic data volumes

---

## Next Lesson

Continue to [Lesson 11: Partitioning & Sharding](../11-partitioning/partitioning.md).
