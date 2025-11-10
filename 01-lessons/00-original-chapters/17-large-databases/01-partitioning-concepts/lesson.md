# Lesson 17.1: Partitioning Concepts

## Overview

Database partitioning is a technique for dividing large tables into smaller, more manageable pieces while maintaining the logical structure of a single table. This lesson introduces partitioning fundamentals, explains when and why to use it, and establishes the foundation for implementing partitioning strategies.

**Learning Objectives:**
- Understand what partitioning is and why it's used
- Differentiate between horizontal and vertical partitioning
- Learn about partition keys and partition schemes
- Distinguish partitioning from sharding and clustering
- Identify when to partition a table
- Recognize common partitioning scenarios

**Estimated Time:** 45 minutes  
**Difficulty:** ⭐⭐ Intermediate

---

## What is Partitioning?

**Partitioning** divides a large table into smaller physical segments (partitions) based on a partition key, while maintaining a single logical table from the application perspective.

### The Restaurant Analogy

Imagine a restaurant filing cabinet:
- **Non-Partitioned:** All receipts in one huge drawer (hard to find anything)
- **Partitioned:** Receipts separated by month in different drawers (easy to find January receipts)

You still have "all receipts" (one logical table), but they're physically organized for faster access.

---

## Why Use Partitioning?

### Performance Benefits

1. **Partition Elimination**
   - Query only scans relevant partitions
   - Example: Query for January data only scans January partition
   - Can reduce I/O by 90%+ for time-based queries

2. **Parallel Processing**
   - Different partitions processed simultaneously
   - Leverages multiple CPU cores
   - Faster query execution

3. **Faster Maintenance**
   - Index rebuild on single partition
   - Statistics update per partition
   - Reduced maintenance windows

### Manageability Benefits

1. **Data Lifecycle Management**
   - Archive old partitions easily
   - Delete/purge partition-level data
   - Load new data into dedicated partition

2. **Storage Management**
   - Place partitions on different filegroups
   - Move historical data to cheaper storage
   - Balance I/O across storage devices

3. **High Availability**
   - Backup/restore individual partitions
   - Partition switching for near-zero downtime loads
   - Maintenance on one partition while others are online

---

## Horizontal vs Vertical Partitioning

### Horizontal Partitioning (Common)

**Divides rows** into different partitions based on a partition key.

```
Original Table: Sales (100M rows)
┌─────────────────────────────────────┐
│ SaleID | SaleDate    | Amount | ... │
│ 1      | 2022-01-15  | 100    | ... │
│ 2      | 2022-06-20  | 200    | ... │
│ 3      | 2023-03-10  | 150    | ... │
│ 4      | 2024-01-05  | 300    | ... │
└─────────────────────────────────────┘

Horizontally Partitioned by Year:

Partition 2022:
┌─────────────────────────────────────┐
│ SaleID | SaleDate    | Amount | ... │
│ 1      | 2022-01-15  | 100    | ... │
│ 2      | 2022-06-20  | 200    | ... │
└─────────────────────────────────────┘

Partition 2023:
┌─────────────────────────────────────┐
│ SaleID | SaleDate    | Amount | ... │
│ 3      | 2023-03-10  | 150    | ... │
└─────────────────────────────────────┘

Partition 2024:
┌─────────────────────────────────────┐
│ SaleID | SaleDate    | Amount | ... │
│ 4      | 2024-01-05  | 300    | ... │
└─────────────────────────────────────┘
```

**Use Cases:**
- Time-series data (orders by date)
- Geographic data (customers by region)
- Category data (products by type)

### Vertical Partitioning (Less Common)

**Divides columns** into different tables.

```
Original Table: Products
┌────────────────────────────────────────────────────────┐
│ ProductID | Name | Category | Price | Description | Image │
└────────────────────────────────────────────────────────┘

Vertically Partitioned:

Products_Core (frequently accessed):
┌──────────────────────────────────┐
│ ProductID | Name | Category | Price │
└──────────────────────────────────┘

Products_Extended (rarely accessed):
┌────────────────────────────────┐
│ ProductID | Description | Image │
└────────────────────────────────┘
```

**Use Cases:**
- Separate frequently vs rarely accessed columns
- Isolate large BLOBs
- Security separation

**Note:** This chapter focuses on **horizontal partitioning**, which is what most people mean by "partitioning."

---

## Partition Keys and Schemes

### Partition Key

The **partition key** is the column(s) used to determine which partition a row belongs to.

**Requirements for Good Partition Key:**
1. ✅ Frequently used in WHERE clauses
2. ✅ Distributes data reasonably evenly
3. ✅ Aligns with data lifecycle (archiving, purging)
4. ✅ Doesn't change frequently
5. ✅ Single column or small composite key

**Examples of Good Partition Keys:**
- `OrderDate` for orders table
- `TransactionDate` for financial transactions
- `Region` for geographically distributed data
- `Year` for historical data

**Examples of Poor Partition Keys:**
- `CustomerID` (if queries don't filter by it)
- `Status` (too few distinct values)
- `Amount` (random distribution, not in queries)

### Partition Scheme

A **partition scheme** defines:
1. How data is divided (the logic)
2. Where partitions are stored (filegroups)

**Components:**
- **Partition Function:** Defines boundary values
- **Partition Scheme:** Maps partitions to filegroups

---

## Partitioning Methods

### 1. Range Partitioning

Divides data based on value ranges.

**Example: Orders by Year**
```
Boundaries: 2022-01-01, 2023-01-01, 2024-01-01

Partition 1: OrderDate < 2022-01-01       (before 2022)
Partition 2: 2022-01-01 <= OrderDate < 2023-01-01  (2022)
Partition 3: 2023-01-01 <= OrderDate < 2024-01-01  (2023)
Partition 4: OrderDate >= 2024-01-01      (2024 and later)
```

**Best For:**
- Time-series data
- Sequential data
- Data with natural boundaries

**Pros:**
- Easy to understand
- Supports archiving
- Good for time-based queries

**Cons:**
- Can create uneven partitions
- Requires boundary management

### 2. List Partitioning

Divides data based on explicit value lists.

**Example: Customers by Region**
```
Partition 1: Region IN ('North', 'Northeast')
Partition 2: Region IN ('South', 'Southeast')
Partition 3: Region IN ('East', 'West')
Partition 4: Region IN ('Central', 'Midwest')
```

**Best For:**
- Categorical data
- Fixed value sets
- Geographic regions

**Pros:**
- Explicit control over distribution
- Easy to understand mappings

**Cons:**
- Must define all possible values
- Maintenance when new values appear

### 3. Hash Partitioning

Divides data using a hash function for even distribution.

**Example: Users by UserID Hash**
```
Hash(UserID) % 4:

Partition 1: Hash result = 0
Partition 2: Hash result = 1
Partition 3: Hash result = 2
Partition 4: Hash result = 3
```

**Best For:**
- Even data distribution
- Load balancing
- No natural partitioning key

**Pros:**
- Automatically balanced
- Simple implementation

**Cons:**
- No range queries
- Cannot target specific partitions
- Resharding is complex

### 4. Composite Partitioning

Combines multiple methods (e.g., range + hash).

**Example: Sales by Year, then by Region**
```
First: Partition by Year (range)
Then: Sub-partition by Region (list or hash)

Result: 2022-North, 2022-South, 2023-North, 2023-South, ...
```

**Best For:**
- Complex scenarios
- Very large tables
- Multiple access patterns

**Pros:**
- Maximum flexibility
- Can optimize for different query patterns

**Cons:**
- More complex to design
- Harder to maintain
- More partitions to manage

---

## Partitioning vs Sharding vs Clustering

### Partitioning
- **Scope:** Single database, single table
- **Storage:** Same server
- **Management:** Automatic (database handles it)
- **Query:** Transparent to application
- **Use Case:** Large tables, manageability, performance

### Sharding
- **Scope:** Multiple databases, distributed
- **Storage:** Multiple servers
- **Management:** Application-level logic required
- **Query:** Application must route to correct shard
- **Use Case:** Horizontal scaling beyond single server

### Clustering
- **Scope:** Multiple servers, same data (replicated)
- **Storage:** Data replicated across servers
- **Management:** Cluster management software
- **Query:** Load balancing across nodes
- **Use Case:** High availability, read scalability

**Visual Comparison:**

```
PARTITIONING (One Server):
Server 1:
  └─ Database
      └─ Table (split into partitions)
          ├─ Partition 1 (2022 data)
          ├─ Partition 2 (2023 data)
          └─ Partition 3 (2024 data)

SHARDING (Multiple Servers):
Server 1:
  └─ Database (Shard 1: Customers A-M)
Server 2:
  └─ Database (Shard 2: Customers N-Z)

CLUSTERING (Replicated):
Server 1 (Primary):
  └─ Database (full copy)
Server 2 (Secondary):
  └─ Database (full copy, synchronized)
```

---

## When to Partition a Table

### Good Candidates for Partitioning

✅ **Size Criteria:**
- Table > 100 GB
- Table growth > 10 GB/month
- Maintenance windows becoming too long

✅ **Query Pattern Criteria:**
- Queries filter by a consistent column (potential partition key)
- Range queries on dates or sequential values
- Historical data access is rare
- Need to archive/purge old data regularly

✅ **Operational Criteria:**
- Bulk loading large amounts of data
- Need for partition-level operations
- Data has clear lifecycle stages
- Backup/restore of full table is too slow

### Poor Candidates for Partitioning

❌ **Don't Partition If:**
- Table < 10 GB (overhead exceeds benefits)
- Queries are mostly random access (no partition elimination)
- No clear partition key
- Frequent cross-partition joins
- Data distributed very unevenly across partitions

---

## Common Partitioning Scenarios

### Scenario 1: Historical Data (Most Common)

**Problem:**
- Orders table has 10 years of data
- 90% of queries only need last 3 months
- Full table scans are slow

**Solution:**
```
Partition by OrderDate (monthly):
- Partition 1-117: Historical months (read-only)
- Partition 118-120: Recent 3 months (active)
- Partition 121: Current month (high activity)
```

**Benefits:**
- Queries on recent data only scan 3 partitions
- Archive old partitions to cheaper storage
- Drop partitions for data purges

### Scenario 2: Geographic Distribution

**Problem:**
- Customer table with global users
- Queries often filter by region
- Some regions much larger than others

**Solution:**
```
Partition by Region:
- Partition 1: North America
- Partition 2: Europe
- Partition 3: Asia
- Partition 4: Other
```

**Benefits:**
- Regional queries only scan one partition
- Can place partitions on different storage
- Easier regional data compliance

### Scenario 3: Data Lifecycle Management

**Problem:**
- Log table grows 100M rows/month
- Need to keep 6 months online
- Older data archived, then deleted

**Solution:**
```
Partition by LogDate (monthly):
- Rolling window: 6 partitions for current data
- Monthly: Archive oldest partition
- Monthly: Drop or truncate archived partition
```

**Benefits:**
- Partition switching for instant archiving
- Truncate partition instead of DELETE (much faster)
- No impact on current month queries

### Scenario 4: Product Catalog

**Problem:**
- Products table with millions of SKUs
- Different product types queried differently
- Need to separate active vs discontinued

**Solution:**
```
Partition by ProductStatus:
- Partition 1: Active products (90% of queries)
- Partition 2: Discontinued products (10% of queries)
- Partition 3: Future/Pending products
```

**Benefits:**
- Queries for active products don't scan discontinued
- Different maintenance schedules per partition
- Easy to report on each category

---

## Partition Elimination

**Partition elimination** (also called **partition pruning**) is when the query optimizer determines that only certain partitions need to be scanned.

**Example:**
```sql
-- Table partitioned by OrderDate (yearly)

-- BAD: Scans all partitions
SELECT * FROM Orders;

-- GOOD: Only scans 2024 partition
SELECT * FROM Orders
WHERE OrderDate >= '2024-01-01' 
  AND OrderDate < '2025-01-01';

-- GOOD: Only scans single partition
SELECT * FROM Orders
WHERE OrderDate = '2024-06-15';

-- BAD: Scans all partitions (partition key not in WHERE)
SELECT * FROM Orders
WHERE CustomerID = 12345;
```

**How to Verify Partition Elimination:**
1. View execution plan
2. Look for "Actual Partitions Accessed"
3. Should be less than total partitions

---

## Key Takeaways

1. **Partitioning Basics**
   - Divides large tables into smaller, manageable pieces
   - Improves query performance and manageability
   - Transparent to applications (mostly)

2. **When to Partition**
   - Large tables (> 100 GB)
   - Clear partition key
   - Queries benefit from partition elimination
   - Need for partition-level operations

3. **Partitioning Methods**
   - Range: Time-series, sequential data
   - List: Categorical, fixed values
   - Hash: Even distribution
   - Composite: Complex scenarios

4. **Benefits**
   - Faster queries (partition elimination)
   - Easier maintenance (partition-level operations)
   - Better data lifecycle management
   - Improved availability

5. **Important Distinctions**
   - Partitioning ≠ Sharding (same vs different servers)
   - Partitioning ≠ Clustering (split vs replicate)
   - Horizontal ≠ Vertical (rows vs columns)

---

## Self-Check Questions

1. What is the difference between horizontal and vertical partitioning?
2. What makes a good partition key?
3. When should you NOT partition a table?
4. How does partition elimination improve query performance?
5. What's the difference between partitioning and sharding?

## Next Steps

Now that you understand partitioning concepts, you're ready to:

**Next Lesson:** [17.2 - Table Partitioning](../02-table-partitioning/lesson.sql)  
Learn how to implement partitioning in SQL Server with practical examples.

---

## Additional Resources

- [Microsoft Docs: Partitioned Tables and Indexes](https://docs.microsoft.com/sql/relational-databases/partitions/)
- [Partitioning Best Practices](https://docs.microsoft.com/sql/relational-databases/partitions/partitioned-table-and-index-best-practices)
- SQL Server Partitioning Survival Guide (book)
