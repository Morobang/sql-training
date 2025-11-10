/*
============================================================================
Lesson 10.10 - Join Performance Optimization
============================================================================

Description:
Master the art of optimizing join queries. Learn about join algorithms,
execution plans, index strategies, and techniques to improve query
performance. Essential for working with large datasets.

Topics Covered:
• Join algorithms (Nested Loop, Merge, Hash)
• Execution plan analysis
• Index strategies for joins
• Query optimization techniques
• Statistics and cardinality
• Common performance pitfalls

Prerequisites:
• Lessons 10.01-10.09
• Basic understanding of indexes

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Join Algorithms
============================================================================
*/

/*
THREE MAIN JOIN ALGORITHMS:

1. NESTED LOOPS JOIN:
   - Outer loop through first table
   - Inner loop through second table for each outer row
   - Best for: Small outer table, indexed inner table
   - Cost: O(n × m)

2. MERGE JOIN:
   - Both inputs sorted on join key
   - Scan both simultaneously
   - Best for: Large sorted tables, equality joins
   - Cost: O(n + m) plus sort cost

3. HASH JOIN:
   - Build hash table from smaller input
   - Probe with larger input
   - Best for: Large unsorted tables, equality joins
   - Cost: O(n + m) plus hash cost
*/

-- Example 1.1: Force Nested Loops (for demonstration)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER LOOP JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 5;
-- Good when: Small customer set, Orders indexed on CustomerID

-- Example 1.2: Force Merge Join
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER MERGE JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID;
-- Good when: Both tables sorted/indexed on CustomerID

-- Example 1.3: Force Hash Join
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER HASH JOIN Orders o ON c.CustomerID = o.CustomerID;
-- Good when: Large tables, no suitable indexes

-- Example 1.4: Let optimizer choose (remove hints)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
-- Usually best: Let SQL Server decide


/*
============================================================================
PART 2: Execution Plan Analysis
============================================================================
*/

-- Enable execution plans
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
SET SHOWPLAN_TEXT OFF;  -- Use graphical plan in SSMS

-- Example 2.1: Analyze simple join
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

/*
Look for in execution plan:
• Join type chosen (Nested Loops, Merge, Hash)
• Index usage (Index Seek vs Index Scan vs Table Scan)
• Estimated vs Actual rows (large difference = statistics issue)
• Warnings (missing indexes, implicit conversions)
• Costly operations (>50% of query cost)
*/

-- Example 2.2: Compare different approaches
-- Approach 1: Join then filter
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01';

-- Approach 2: Filter then join (same result, may have different plan)
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN (
    SELECT * FROM Orders WHERE OrderDate >= '2024-01-01'
) o ON c.CustomerID = o.CustomerID;

-- Example 2.3: Key metrics from STATISTICS IO
/*
Output shows:
• Logical reads: Pages read from buffer cache (memory)
• Physical reads: Pages read from disk (slow!)
• Read-ahead reads: Pre-fetched pages
Goal: Minimize reads, especially physical reads
*/

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*
============================================================================
PART 3: Index Strategies for Joins
============================================================================
*/

-- Strategy 3.1: ✅ Index foreign key columns
/*
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);
*/

-- Benefits: Nested loop joins can seek instead of scan

-- Strategy 3.2: ✅ Covering indexes for frequently joined columns
/*
CREATE INDEX IX_Orders_CustomerID_Include 
ON Orders(CustomerID) 
INCLUDE (OrderDate, TotalAmount);
*/
-- Benefits: Avoids key lookups, all data in index

-- Strategy 3.3: ✅ Composite indexes for multi-column joins
/*
-- If you frequently join on CustomerID and OrderDate:
CREATE INDEX IX_Orders_CustomerID_OrderDate 
ON Orders(CustomerID, OrderDate);
*/

-- Strategy 3.4: Check missing index suggestions
/*
SELECT 
    migs.avg_user_impact,
    migs.avg_total_user_cost,
    migs.user_seeks,
    mid.statement,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig 
    ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid 
    ON mig.index_handle = mid.index_handle
WHERE migs.avg_user_impact > 50  -- High impact
ORDER BY migs.avg_user_impact DESC;
*/


/*
============================================================================
PART 4: Query Optimization Techniques
============================================================================
*/

-- Technique 4.1: Filter early
-- ❌ Bad: Large join then filter
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE c.Country = 'USA'
  AND o.OrderDate >= '2024-01-01'
  AND o.TotalAmount > 100;

-- ✅ Better: Filter first with CTEs or subqueries
WITH USACustomers AS (
    SELECT CustomerID, CustomerName 
    FROM Customers 
    WHERE Country = 'USA'
),
RecentLargeOrders AS (
    SELECT CustomerID, OrderID, TotalAmount
    FROM Orders
    WHERE OrderDate >= '2024-01-01' 
      AND TotalAmount > 100
)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM USACustomers c
INNER JOIN RecentLargeOrders o ON c.CustomerID = o.CustomerID;

-- Technique 4.2: Avoid functions on join columns
-- ❌ Bad: Function prevents index usage
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON CAST(c.CustomerID AS VARCHAR(10)) = CAST(o.CustomerID AS VARCHAR(10));

-- ✅ Good: Direct comparison
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Technique 4.3: Proper data types
-- ❌ Bad: Data type mismatch causes conversions
/*
-- If CustomerID is INT but you have VARCHAR:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID_VARCHAR;
*/

-- ✅ Good: Matching data types
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Technique 4.4: Limit result set
-- ❌ Bad: Join everything then TOP
SELECT TOP 100
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
ORDER BY o.OrderDate DESC;

-- ✅ Better: Limit early
WITH RecentOrders AS (
    SELECT TOP 100
        OrderID,
        CustomerID,
        TotalAmount,
        OrderDate
    FROM Orders
    ORDER BY OrderDate DESC
)
SELECT 
    c.CustomerName,
    ro.OrderID,
    ro.TotalAmount
FROM RecentOrders ro
INNER JOIN Customers c ON ro.CustomerID = c.CustomerID
ORDER BY ro.OrderDate DESC;


/*
============================================================================
PART 5: Statistics and Cardinality
============================================================================
*/

-- Example 5.1: Check statistics on join columns
DBCC SHOW_STATISTICS('Orders', 'IX_Orders_CustomerID');
-- Shows: Histogram, density, last update time

-- Example 5.2: Update statistics
UPDATE STATISTICS Orders;
UPDATE STATISTICS Customers;

-- Example 5.3: Check outdated statistics
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated,
    sp.rows AS RowCount,
    sp.modification_counter AS ModificationCount
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE OBJECT_NAME(s.object_id) IN ('Orders', 'Customers', 'OrderDetails')
ORDER BY LastUpdated;

-- Example 5.4: Force statistics update if needed
/*
UPDATE STATISTICS Orders WITH FULLSCAN;
UPDATE STATISTICS Customers WITH FULLSCAN;
*/


/*
============================================================================
PART 6: Common Performance Pitfalls
============================================================================
*/

-- Pitfall 6.1: ❌ Implicit conversions
-- Shows warning in execution plan
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = CAST(o.CustomerID AS VARCHAR(10));
-- Fix: Use same data types

-- Pitfall 6.2: ❌ OR in join conditions
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID 
    OR c.CustomerName = o.ShipName;
-- Fix: Split into UNION or use different approach

-- Pitfall 6.3: ❌ Functions in WHERE on joined tables
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE YEAR(o.OrderDate) = 2024;  -- Prevents index usage

-- ✅ Better:
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01' 
  AND o.OrderDate < '2025-01-01';

-- Pitfall 6.4: ❌ SELECT * in large joins
SELECT *
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- Returns all columns (wasteful)

-- ✅ Better: Select only needed columns
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    od.Quantity
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;

-- Pitfall 6.5: ❌ Multiple OR conditions
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount = 100 
   OR o.TotalAmount = 200 
   OR o.TotalAmount = 300;

-- ✅ Better: Use IN
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount IN (100, 200, 300);


/*
============================================================================
PART 7: Benchmarking and Testing
============================================================================
*/

-- Benchmark 7.1: Compare query approaches
DECLARE @StartTime DATETIME2;
DECLARE @EndTime DATETIME2;

-- Approach 1:
SET @StartTime = SYSDATETIME();
SELECT COUNT(*)
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01';
SET @EndTime = SYSDATETIME();
PRINT 'Approach 1: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR(10)) + ' ms';

-- Approach 2:
SET @StartTime = SYSDATETIME();
SELECT COUNT(*)
FROM Customers c
INNER JOIN (
    SELECT CustomerID FROM Orders WHERE OrderDate >= '2024-01-01'
) o ON c.CustomerID = o.CustomerID;
SET @EndTime = SYSDATETIME();
PRINT 'Approach 2: ' + CAST(DATEDIFF(MILLISECOND, @StartTime, @EndTime) AS VARCHAR(10)) + ' ms';

-- Benchmark 7.2: I/O statistics comparison
SET STATISTICS IO ON;

-- Query 1:
SELECT c.CustomerName, COUNT(o.OrderID)
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Query 2: Different approach
SELECT 
    c.CustomerName,
    ISNULL(OrderCounts.OrderCount, 0) AS OrderCount
FROM Customers c
LEFT JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
) OrderCounts ON c.CustomerID = OrderCounts.CustomerID;

SET STATISTICS IO OFF;


/*
============================================================================
PART 8: Advanced Optimization Patterns
============================================================================
*/

-- Pattern 8.1: Use EXISTS instead of JOIN + DISTINCT
-- ❌ Slower:
SELECT DISTINCT c.CustomerID, c.CustomerName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- ✅ Faster:
SELECT c.CustomerID, c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);

-- Pattern 8.2: Partition for parallel processing
-- Large table joins can benefit from partitioning
/*
-- Partition Orders by date range
CREATE PARTITION FUNCTION PF_OrderDate (DATE)
AS RANGE RIGHT FOR VALUES 
('2023-01-01', '2023-04-01', '2023-07-01', '2023-10-01', '2024-01-01');

CREATE PARTITION SCHEME PS_OrderDate
AS PARTITION PF_OrderDate
ALL TO ([PRIMARY]);
*/

-- Pattern 8.3: Materialized views for frequent joins
/*
-- If you frequently join these tables:
CREATE VIEW vw_CustomerOrders
WITH SCHEMABINDING
AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT_BIG(*) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent
FROM dbo.Customers c
INNER JOIN dbo.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Create clustered index (materializes the view)
CREATE UNIQUE CLUSTERED INDEX IX_CustomerOrders 
ON vw_CustomerOrders(CustomerID);
*/

-- Pattern 8.4: Query hints (use sparingly)
-- Force specific join algorithm
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER LOOP JOIN Orders o ON c.CustomerID = o.CustomerID
OPTION (MAXDOP 1);  -- Force serial execution
-- Only use when you know better than optimizer


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Analyze execution plan for a 3-table join and identify the costliest operation
2. Create appropriate indexes for CustomerID and OrderID foreign keys
3. Rewrite a query to filter before joining instead of after
4. Compare NESTED LOOP vs HASH join for a specific query
5. Find and update outdated statistics on join columns

Solutions below ↓
*/

-- Solution 1:
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID,
    od.Quantity
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- View graphical execution plan in SSMS
-- Look for operations with highest cost percentage

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- Solution 2:
/*
-- Create indexes on foreign keys
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);

-- Include commonly selected columns
CREATE INDEX IX_Orders_CustomerID_Include 
ON Orders(CustomerID) 
INCLUDE (OrderDate, TotalAmount);
*/

-- Solution 3:
-- Before (filter after join):
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.Country = 'USA' AND o.OrderDate >= '2024-01-01';

-- After (filter before join):
WITH USACustomers AS (
    SELECT CustomerID, CustomerName FROM Customers WHERE Country = 'USA'
),
RecentOrders AS (
    SELECT CustomerID, OrderID FROM Orders WHERE OrderDate >= '2024-01-01'
)
SELECT c.CustomerName, o.OrderID
FROM USACustomers c
INNER JOIN RecentOrders o ON c.CustomerID = o.CustomerID;

-- Solution 4:
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Nested loop:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER LOOP JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Hash join:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER HASH JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Compare execution times and I/O

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- Solution 5:
-- Check statistics age:
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdated
FROM sys.stats s
WHERE OBJECT_NAME(s.object_id) IN ('Orders', 'Customers')
ORDER BY LastUpdated;

-- Update if outdated:
/*
UPDATE STATISTICS Orders;
UPDATE STATISTICS Customers;
*/


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ JOIN ALGORITHMS:
  • Nested Loops: Small outer, indexed inner
  • Merge Join: Large sorted tables
  • Hash Join: Large unsorted tables
  • Usually let optimizer choose

✓ EXECUTION PLANS:
  • Always analyze for slow queries
  • Look for scans vs seeks
  • Check estimated vs actual rows
  • Find warnings (conversions, missing indexes)
  • Focus on costly operations

✓ INDEXING:
  • Index ALL foreign key columns
  • Covering indexes for frequent queries
  • Composite indexes for multi-column joins
  • Monitor missing index suggestions
  • Don't over-index (write performance cost)

✓ OPTIMIZATION TECHNIQUES:
  • Filter early (WHERE, CTEs, subqueries)
  • Avoid functions on join columns
  • Use matching data types
  • Select only needed columns
  • Limit result sets early

✓ STATISTICS:
  • Keep statistics updated
  • Check for stale statistics
  • Update after large data changes
  • Affects query plan choices

✓ COMMON PITFALLS:
  • Implicit conversions (data type mismatch)
  • Functions in WHERE/ON clauses
  • SELECT * with large tables
  • OR in join conditions
  • Missing indexes on FKs

✓ PERFORMANCE MONITORING:
  • SET STATISTICS TIME ON
  • SET STATISTICS IO ON
  • Actual execution plans
  • Benchmark different approaches
  • Test with production-like data

✓ BEST PRACTICES:
  • Start with optimizer's choice
  • Index strategically
  • Update statistics regularly
  • Test with realistic data volumes
  • Monitor slow query log
  • Use covering indexes for hot queries
  • Avoid query hints unless necessary

============================================================================
NEXT: Lesson 10.11 - Join vs Subquery
Learn when to use joins vs subqueries for optimal performance.
============================================================================
*/
