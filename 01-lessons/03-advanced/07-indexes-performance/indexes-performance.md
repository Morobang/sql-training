# Lesson 7: Indexes & Performance

**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Understand index types (clustered, non-clustered, unique, filtered)
2. Design effective indexing strategies
3. Use covering indexes and included columns
4. Identify and fix missing index issues
5. Balance index benefits vs overhead
6. Monitor and maintain indexes

---

## Part 1: What Are Indexes?

Indexes are data structures that improve query performance by providing fast lookup paths to data.

**Analogy:** Like a book index - find topics quickly without scanning every page.

### Without Index
```sql
-- Table scan: reads ALL rows
SELECT * FROM Customers WHERE CustomerID = 1000;
-- Cost: O(n) - must check every row
```

### With Index
```sql
-- Index seek: jumps directly to row
CREATE INDEX IX_Customers_CustomerID ON Customers(CustomerID);
SELECT * FROM Customers WHERE CustomerID = 1000;
-- Cost: O(log n) - binary search
```

---

## Part 2: Clustered Indexes

Clustered index determines the physical order of data in the table. **One per table only.**

```sql
-- Primary key creates clustered index by default
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,  -- Clustered index on OrderID
    CustomerID INT,
    OrderDate DATE
);

-- Explicit clustered index
CREATE CLUSTERED INDEX IX_Orders_OrderDate ON Orders(OrderDate);
```

**Key Points:**
- Data rows stored in index order
- Fast range queries on clustered column
- Leaf nodes contain actual data rows
- Choose wisely - can't change easily with large data

---

## Part 3: Non-Clustered Indexes

Non-clustered indexes create separate structures pointing to data rows. **Multiple allowed per table.**

```sql
-- Non-clustered index on CustomerID
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID 
ON Orders(CustomerID);

-- Composite index (multiple columns)
CREATE INDEX IX_Orders_Customer_Date 
ON Orders(CustomerID, OrderDate);
```

**Structure:**
- Leaf nodes contain pointers (not data)
- Can have up to 999 non-clustered indexes per table
- Each adds overhead to DML operations

---

## Part 4: Unique Indexes

Enforce uniqueness while providing index benefits.

```sql
-- Unique constraint creates unique index
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    Email NVARCHAR(100) UNIQUE  -- Unique index created
);

-- Explicit unique index
CREATE UNIQUE INDEX IX_Employees_Email ON Employees(Email);
```

---

## Part 5: Filtered Indexes

Index only a subset of rows (SQL Server 2008+).

```sql
-- Index only active customers
CREATE INDEX IX_Customers_Active 
ON Customers(LastName, FirstName)
WHERE IsActive = 1;

-- Index only recent orders
CREATE INDEX IX_Orders_Recent 
ON Orders(CustomerID, OrderDate)
WHERE OrderDate >= '2024-01-01';
```

**Benefits:**
- Smaller index size
- Faster maintenance
- Targeted performance improvement

---

## Part 6: Covering Indexes

Index that contains all columns needed by a query (no table lookup required).

```sql
-- Query needs: CustomerID, OrderDate, TotalAmount
SELECT CustomerID, OrderDate, TotalAmount
FROM Orders
WHERE CustomerID = 100;

-- Covering index with INCLUDE
CREATE INDEX IX_Orders_CustomerID_Covering
ON Orders(CustomerID)
INCLUDE (OrderDate, TotalAmount);
```

**Benefits:**
- No bookmark lookup (table access)
- Fastest possible query
- Index-only scan

---

## Part 7: Index Column Order Matters

**Left-to-right rule:** Index on (A, B, C) helps queries filtering on:
- A
- A, B
- A, B, C

But NOT queries filtering only on B or C.

```sql
CREATE INDEX IX_Orders_Customer_Date_Amount
ON Orders(CustomerID, OrderDate, TotalAmount);

-- Uses index efficiently
SELECT * FROM Orders WHERE CustomerID = 100;
SELECT * FROM Orders WHERE CustomerID = 100 AND OrderDate = '2024-01-01';

-- Does NOT use index efficiently
SELECT * FROM Orders WHERE OrderDate = '2024-01-01';  -- OrderDate not first
```

**Design Rule:** Most selective column first (unless range queries involved).

---

## Part 8: Missing Index Suggestions

SQL Server tracks missing indexes via DMVs.

```sql
-- Find missing index suggestions
SELECT 
    OBJECT_NAME(d.object_id) AS TableName,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.avg_user_impact,
    s.user_seeks,
    s.user_scans
FROM sys.dm_db_missing_index_details d
INNER JOIN sys.dm_db_missing_index_groups g ON d.index_handle = g.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats s ON g.index_group_handle = s.group_handle
ORDER BY s.avg_user_impact * s.user_seeks DESC;
```

**Caution:** Don't blindly create all suggestions; analyze first.

---

## Part 9: Index Overhead

Every index has costs:

### Storage
- Disk space for index structure
- More indexes = more storage

### DML Performance
```sql
-- With 5 indexes, each INSERT/UPDATE/DELETE must:
-- 1. Update table data
-- 2. Update index 1
-- 3. Update index 2
-- 4. Update index 3
-- 5. Update index 4
-- 6. Update index 5
```

**Balance:** Enough indexes for reads, not too many to slow writes.

---

## Part 10: Index Fragmentation

Over time, indexes become fragmented (inefficient page usage).

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

### Fix Fragmentation

```sql
-- Reorganize (online, less resource intensive)
ALTER INDEX IX_Orders_CustomerID ON Orders REORGANIZE;

-- Rebuild (offline, complete rebuild)
ALTER INDEX IX_Orders_CustomerID ON Orders REBUILD;

-- Rebuild all indexes on table
ALTER INDEX ALL ON Orders REBUILD;
```

**Rules of Thumb:**
- 5-30% fragmentation: REORGANIZE
- >30% fragmentation: REBUILD

---

## Part 11: Index Statistics

SQL Server uses statistics to estimate query costs.

```sql
-- Update statistics manually
UPDATE STATISTICS Orders;

-- Update statistics on specific index
UPDATE STATISTICS Orders IX_Orders_CustomerID;

-- View statistics
DBCC SHOW_STATISTICS('Orders', 'IX_Orders_CustomerID');
```

**Auto-update:** Enabled by default, but manual updates may help performance.

---

## Part 12: Practical Examples

### Example 1: E-Commerce Order Queries

```sql
-- Orders table with common query patterns
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,  -- Clustered
    CustomerID INT,
    OrderDate DATE,
    ShipDate DATE,
    TotalAmount DECIMAL(10,2),
    Status NVARCHAR(20)
);

-- Index for customer order history
CREATE INDEX IX_Orders_Customer_Date 
ON Orders(CustomerID, OrderDate DESC)
INCLUDE (TotalAmount, Status);

-- Index for order status reports
CREATE INDEX IX_Orders_Status_Date 
ON Orders(Status, OrderDate)
INCLUDE (CustomerID, TotalAmount);

-- Filtered index for pending orders
CREATE INDEX IX_Orders_Pending 
ON Orders(OrderDate)
WHERE Status = 'Pending';
```

### Example 2: Search Optimization

```sql
-- Product search
CREATE INDEX IX_Products_Name 
ON Products(ProductName)
INCLUDE (Price, CategoryID);

-- Category browsing
CREATE INDEX IX_Products_Category_Price 
ON Products(CategoryID, Price DESC)
INCLUDE (ProductName, Stock);
```

---

## Part 13: Index Design Best Practices

1. **Index columns in WHERE, JOIN, ORDER BY**
2. **Keep indexes narrow** (fewer columns)
3. **Use INCLUDE for covering** (don't add to key)
4. **Avoid over-indexing** (5-10 indexes per table typically)
5. **Index foreign keys** (always)
6. **Consider query patterns** (read-heavy vs write-heavy)
7. **Monitor and maintain** (rebuild/reorganize regularly)
8. **Test impact** (measure before/after)

---

## Part 14: Index Maintenance Script

```sql
-- Monthly index maintenance
DECLARE @TableName NVARCHAR(255);
DECLARE @IndexName NVARCHAR(255);
DECLARE @Fragmentation FLOAT;

DECLARE index_cursor CURSOR FOR
SELECT 
    OBJECT_NAME(ips.object_id),
    i.name,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5 AND ips.page_count > 1000;

OPEN index_cursor;
FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
        EXEC('ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD');
    ELSE
        EXEC('ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REORGANIZE');
    
    FETCH NEXT FROM index_cursor INTO @TableName, @IndexName, @Fragmentation;
END;

CLOSE index_cursor;
DEALLOCATE index_cursor;
```

---

## Practice Exercises

1. Create a composite index and test query performance with/without it.
2. Identify missing indexes using DMV query and create appropriate indexes.
3. Check fragmentation on a large table and rebuild/reorganize as needed.
4. Design a covering index for a specific query.

---

## Key Takeaways

- Clustered index = physical order (1 per table)
- Non-clustered = separate structure (many allowed)
- Column order matters (left-to-right rule)
- INCLUDE for covering indexes
- Balance read performance vs write overhead
- Monitor fragmentation and statistics
- Test and measure impact

---

## Next Lesson

Continue to [Lesson 8: Execution Plans](../08-execution-plans/08-execution-plans.md).
