# Chapter 17: Working with Large Databases - Practice Questions

## Overview
Master partitioning strategies, query optimization, archiving, purging, sharding, and handling millions/billions of rows efficiently.

---

## Table Partitioning

### Question 1: Partition Types and Strategies (Medium)
Explain RANGE, LIST, HASH, and KEY partitioning with use cases.

<details>
<summary>Click to see answer</summary>

**Answer:**

**RANGE Partitioning** - By value ranges (dates, IDs)
```sql
-- Partition by year
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    customer_id INT,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2)
)
PARTITION BY RANGE (YEAR(order_date)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Query only scans relevant partition
SELECT * FROM orders 
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';
-- Only scans p2024 partition

-- Check partition pruning
EXPLAIN PARTITIONS
SELECT * FROM orders WHERE order_date = '2024-06-15';
-- partitions: p2024 (only one partition accessed)
```

**Benefits:**
- Easy archiving (drop old partitions)
- Query pruning (only scan needed partitions)
- Faster deletes (truncate partition vs DELETE)

---

**LIST Partitioning** - By discrete values
```sql
-- Partition by region
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    country VARCHAR(2),
    region VARCHAR(20) NOT NULL
)
PARTITION BY LIST COLUMNS(region) (
    PARTITION p_north_america VALUES IN ('US', 'CA', 'MX'),
    PARTITION p_europe VALUES IN ('GB', 'FR', 'DE', 'IT', 'ES'),
    PARTITION p_asia VALUES IN ('CN', 'JP', 'IN', 'KR'),
    PARTITION p_other VALUES IN ('AU', 'BR', 'ZA', 'UNKNOWN')
);

-- Queries filtered by region only scan that partition
SELECT * FROM customers WHERE region = 'US';
-- Only scans p_north_america
```

**Use cases:**
- Geographic data
- Categories, status codes
- Known discrete values

---

**HASH Partitioning** - Distribute evenly across partitions
```sql
-- Partition by customer_id hash (8 partitions)
CREATE TABLE user_events (
    event_id BIGINT PRIMARY KEY,
    user_id INT NOT NULL,
    event_type VARCHAR(50),
    event_date DATETIME,
    data JSON
)
PARTITION BY HASH(user_id)
PARTITIONS 8;

-- Data distributed evenly across 8 partitions
-- Good for write distribution
```

**Benefits:**
- Even data distribution
- Prevents hotspots
- Good for high-write tables

**Drawbacks:**
- No partition pruning (must scan all for range queries)
- Use when primary access is by hash key

---

**KEY Partitioning** - Like HASH, but MySQL chooses algorithm
```sql
CREATE TABLE sessions (
    session_id VARCHAR(32) PRIMARY KEY,
    user_id INT,
    created_at TIMESTAMP
)
PARTITION BY KEY(session_id)
PARTITIONS 16;

-- Automatically hashes PRIMARY KEY if no column specified
```

---

**Comparison:**

| Type | Pruning | Use Case | Example |
|------|---------|----------|---------|
| **RANGE** | ✅ Excellent | Time-series, sequential IDs | Orders by date |
| **LIST** | ✅ Good | Known categories | Regions, statuses |
| **HASH** | ❌ Poor | Even distribution | High-write tables |
| **KEY** | ❌ Poor | Like HASH (auto) | Sessions, logs |

---

**Managing partitions:**
```sql
-- Add new partition (RANGE)
ALTER TABLE orders 
ADD PARTITION (PARTITION p2025 VALUES LESS THAN (2026));

-- Drop old partition (instant, vs DELETE)
ALTER TABLE orders DROP PARTITION p2020;
-- All 2020 data instantly deleted

-- Split partition
ALTER TABLE orders 
REORGANIZE PARTITION p_future INTO (
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- View partition info
SELECT 
    TABLE_NAME,
    PARTITION_NAME,
    PARTITION_METHOD,
    PARTITION_EXPRESSION,
    TABLE_ROWS,
    DATA_LENGTH / 1024 / 1024 AS data_mb
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_NAME = 'orders';
```

</details>

---

## Data Archiving

### Question 2: Implement Archiving Strategy (Hard)
Archive old orders to separate table with minimal production impact.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Strategy 1: Partition-based archiving (fastest)**

```sql
-- Active table (partitioned)
CREATE TABLE orders_active (
    order_id BIGINT PRIMARY KEY,
    customer_id INT,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
PARTITION BY RANGE (YEAR(order_date)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Archive table (same structure)
CREATE TABLE orders_archive LIKE orders_active;

-- Archive 2023 data (instant, no copying)
ALTER TABLE orders_active
EXCHANGE PARTITION p2023
WITH TABLE orders_archive;
-- Swaps metadata pointers, no data movement!

-- Drop archived partition from active table
ALTER TABLE orders_active DROP PARTITION p2023;
```

**Benefits:**
- Instant (metadata operation)
- No locks, no downtime
- Works with partitioned tables

---

**Strategy 2: Batch archiving (for non-partitioned tables)**

```sql
-- Create archive table
CREATE TABLE orders_archive LIKE orders;

-- Batch archive procedure
DELIMITER $$
CREATE PROCEDURE sp_archive_old_orders(
    IN p_archive_before_date DATE,
    IN p_batch_size INT
)
BEGIN
    DECLARE v_rows_affected INT DEFAULT 1;
    
    WHILE v_rows_affected > 0 DO
        -- Copy batch to archive
        INSERT INTO orders_archive
        SELECT * FROM orders
        WHERE order_date < p_archive_before_date
          AND status IN ('completed', 'cancelled')
        LIMIT p_batch_size;
        
        SET v_rows_affected = ROW_COUNT();
        
        -- Delete archived rows
        DELETE FROM orders
        WHERE order_date < p_archive_before_date
          AND status IN ('completed', 'cancelled')
        LIMIT p_batch_size;
        
        -- Pause between batches (reduce lock contention)
        SELECT SLEEP(0.5);
        
    END WHILE;
END$$
DELIMITER ;

-- Execute archiving
CALL sp_archive_old_orders('2023-01-01', 10000);
```

**Benefits:**
- Works without partitioning
- Small batches reduce locks
- Can run during business hours

---

**Strategy 3: Incremental archiving with staging**

```sql
-- Staging table (temporary)
CREATE TABLE orders_archive_staging (
    order_id BIGINT PRIMARY KEY,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 1: Identify orders to archive
INSERT INTO orders_archive_staging (order_id)
SELECT order_id
FROM orders
WHERE order_date < '2023-01-01'
  AND status IN ('completed', 'cancelled')
LIMIT 100000;

-- Step 2: Copy to archive (with progress tracking)
INSERT INTO orders_archive
SELECT o.*
FROM orders o
JOIN orders_archive_staging s ON o.order_id = s.order_id;

-- Step 3: Delete from active table in batches
DELIMITER $$
CREATE PROCEDURE sp_delete_archived_batches()
BEGIN
    DECLARE v_rows INT DEFAULT 1;
    WHILE v_rows > 0 DO
        DELETE o
        FROM orders o
        JOIN orders_archive_staging s ON o.order_id = s.order_id
        LIMIT 10000;
        
        SET v_rows = ROW_COUNT();
        SELECT SLEEP(1);
    END WHILE;
END$$
DELIMITER ;

CALL sp_delete_archived_batches();

-- Step 4: Cleanup staging
DROP TABLE orders_archive_staging;
```

---

**Strategy 4: Separate archive database**

```sql
-- Create archive database
CREATE DATABASE orders_archive_db;

-- Archive old data
INSERT INTO orders_archive_db.orders
SELECT * FROM production_db.orders
WHERE order_date < '2023-01-01';

-- Create compressed archive (MyISAM with row compression)
CREATE TABLE orders_archive_db.orders_compressed
ENGINE=MyISAM
ROW_FORMAT=COMPRESSED
AS SELECT * FROM production_db.orders
WHERE order_date < '2023-01-01';

-- Archive reduces size by 60-80%
```

---

**Best practices:**

| Practice | Why |
|----------|-----|
| **Small batches** | Avoid long locks (10K-100K rows) |
| **Off-peak hours** | Minimize production impact |
| **Sleep between batches** | Give other queries a chance |
| **Status filtering** | Only archive completed/final records |
| **Verify before delete** | Count rows in both tables |
| **Retention policy** | Keep 13-24 months active |
| **Compressed archive** | Save 60-80% storage |

```sql
-- Verify counts before deleting
SELECT COUNT(*) FROM orders WHERE order_date < '2023-01-01';
SELECT COUNT(*) FROM orders_archive WHERE order_date < '2023-01-01';
-- Must match!
```

</details>

---

## Query Optimization for Large Tables

### Question 3: Optimize Query Scanning Billions of Rows (Expert)
Given a table with 5 billion rows, optimize this query:

```sql
SELECT customer_id, COUNT(*), SUM(amount)
FROM transactions
WHERE transaction_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(amount) > 10000;
```

<details>
<summary>Click to see answer</summary>

**Answer:**

**Problem:** Full table scan of 5 billion rows is too slow.

---

**Optimization 1: Partition pruning**

```sql
-- Partition by month
CREATE TABLE transactions (
    transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    amount DECIMAL(10,2),
    transaction_date DATE
)
PARTITION BY RANGE (YEAR(transaction_date) * 100 + MONTH(transaction_date)) (
    PARTITION p202301 VALUES LESS THAN (202302),
    PARTITION p202302 VALUES LESS THAN (202303),
    -- ... monthly partitions ...
    PARTITION p202412 VALUES LESS THAN (202501),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Now query only scans 2024 partitions (12 partitions vs 60+)
SELECT customer_id, COUNT(*), SUM(amount)
FROM transactions
WHERE transaction_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(amount) > 10000;

-- Check partition pruning
EXPLAIN PARTITIONS
SELECT ...;
-- Should show: partitions: p202401,p202402,...,p202412
```

**Reduction:** 5 billion → ~400 million rows (12 months of 2024)

---

**Optimization 2: Covering index**

```sql
-- Index includes all needed columns
CREATE INDEX idx_txn_covering 
ON transactions(transaction_date, customer_id, amount);

-- Query uses index-only scan (no table access)
SELECT customer_id, COUNT(*), SUM(amount)
FROM transactions
WHERE transaction_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(amount) > 10000;

EXPLAIN shows: Extra: Using index
```

**Benefit:** Reads index blocks (~500 GB) instead of table blocks (~2 TB)

---

**Optimization 3: Summary tables (materialized aggregates)**

```sql
-- Pre-aggregate daily
CREATE TABLE daily_customer_summary (
    summary_date DATE,
    customer_id INT,
    transaction_count INT,
    total_amount DECIMAL(15,2),
    PRIMARY KEY (summary_date, customer_id)
);

-- Populate daily (via scheduled job)
INSERT INTO daily_customer_summary
SELECT 
    DATE(transaction_date),
    customer_id,
    COUNT(*),
    SUM(amount)
FROM transactions
WHERE DATE(transaction_date) = CURDATE() - INTERVAL 1 DAY
GROUP BY DATE(transaction_date), customer_id;

-- Query summary table (365 rows per customer vs millions)
SELECT 
    customer_id,
    SUM(transaction_count) AS total_transactions,
    SUM(total_amount) AS total_amount
FROM daily_customer_summary
WHERE summary_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(total_amount) > 10000;
```

**Reduction:** 400 million → 365 * 1 million customers = ~365 million (but smaller rows)

---

**Optimization 4: Incremental aggregation**

```sql
-- Running totals table
CREATE TABLE customer_running_totals (
    customer_id INT PRIMARY KEY,
    ytd_count INT,
    ytd_amount DECIMAL(15,2),
    last_updated DATE
);

-- Update incrementally
INSERT INTO customer_running_totals
SELECT 
    customer_id,
    COUNT(*),
    SUM(amount),
    CURDATE()
FROM transactions
WHERE DATE(transaction_date) = CURDATE()
GROUP BY customer_id
ON DUPLICATE KEY UPDATE
    ytd_count = ytd_count + VALUES(ytd_count),
    ytd_amount = ytd_amount + VALUES(ytd_amount),
    last_updated = VALUES(last_updated);

-- Query is instant (1 million rows, pre-aggregated)
SELECT customer_id, ytd_count, ytd_amount
FROM customer_running_totals
WHERE ytd_amount > 10000;
```

**Reduction:** 400 million → 1 million rows (one per customer)

---

**Optimization 5: Parallel query (MySQL 8.0.14+)**

```sql
-- Enable parallel execution
SET SESSION innodb_parallel_read_threads = 8;

-- Query uses multiple threads
SELECT customer_id, COUNT(*), SUM(amount)
FROM transactions
WHERE transaction_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(amount) > 10000;
```

**Benefit:** 8x faster on multi-core systems

---

**Optimization 6: Column store engine (MariaDB ColumnStore)**

```sql
-- Convert to columnar storage
ALTER TABLE transactions ENGINE=ColumnStore;

-- Columnar queries 10-100x faster for aggregates
SELECT customer_id, COUNT(*), SUM(amount)
FROM transactions
WHERE transaction_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(amount) > 10000;
```

**Benefit:** Only reads needed columns (transaction_date, customer_id, amount), skips others

---

**Performance comparison:**

| Approach | Rows Scanned | Time | Complexity |
|----------|--------------|------|------------|
| **Original** | 5 billion | 30+ minutes | Low |
| **Partitioning** | 400 million | 5 minutes | Medium |
| **+ Covering index** | 400 million (index) | 2 minutes | Medium |
| **Daily summary** | 365 million | 30 seconds | High |
| **Running totals** | 1 million | <1 second | High |
| **Parallel query** | 400 million | 40 seconds | Low |
| **Columnar** | 400 million (3 columns) | 15 seconds | Medium |

---

**Recommended strategy:**

1. **Partition** by month (RANGE)
2. **Covering index** on (transaction_date, customer_id, amount)
3. **Daily summary table** for reporting
4. **Running totals** for real-time dashboards

```sql
-- Final optimized architecture
CREATE TABLE transactions (
    -- fact table
) PARTITION BY RANGE (TO_DAYS(transaction_date)) (...);

CREATE INDEX idx_covering ON transactions(transaction_date, customer_id, amount);

CREATE TABLE daily_customer_summary (...);  -- Aggregated daily
CREATE TABLE customer_ytd_totals (...);     -- Current year totals
```

</details>

---

## Sharding

### Question 4: Horizontal Sharding Strategy (Hard)
Design a sharding strategy for a table with 10 billion users.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Sharding = Splitting data across multiple database servers**

---

**Approach 1: Hash-based sharding**

```sql
-- Shard by user_id hash (8 shards)
-- Shard = user_id % 8

-- Shard 0 (db_shard_0)
CREATE TABLE users (
    user_id BIGINT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(255),
    created_at TIMESTAMP
);
-- Contains user_ids: 0, 8, 16, 24, ...

-- Shard 1 (db_shard_1)
-- Contains user_ids: 1, 9, 17, 25, ...

-- ... (8 total shards)

-- Application routing logic
function get_shard_for_user(user_id) {
    shard_id = user_id % 8;
    return database_connections[shard_id];
}

// Query user
db = get_shard_for_user(12345);
user = db.query("SELECT * FROM users WHERE user_id = 12345");

// Insert user
user_id = generate_id();
db = get_shard_for_user(user_id);
db.execute("INSERT INTO users (user_id, ...) VALUES (?, ...)", user_id, ...);
```

**Benefits:**
- Even distribution
- Simple routing
- Scalable (add more shards)

**Drawbacks:**
- Cross-shard queries difficult
- Rebalancing requires data movement

---

**Approach 2: Range-based sharding**

```sql
-- Shard by user_id ranges
-- Shard 0: user_id 1 - 1,000,000,000
-- Shard 1: user_id 1,000,000,001 - 2,000,000,000
-- Shard 2: user_id 2,000,000,001 - 3,000,000,000
-- ...

-- Routing
function get_shard_for_user(user_id) {
    if (user_id <= 1000000000) return shard_0;
    if (user_id <= 2000000000) return shard_1;
    // ...
}
```

**Benefits:**
- Range queries easier
- Clear boundaries

**Drawbacks:**
- Uneven distribution (newer shards grow faster)
- Hotspots on recent data

---

**Approach 3: Geography-based sharding**

```sql
-- Shard by region
-- Shard US (db_us)
CREATE TABLE users (
    user_id BIGINT PRIMARY KEY,
    region VARCHAR(2) DEFAULT 'US',
    ...
);

-- Shard EU (db_eu)
-- Shard ASIA (db_asia)

-- Routing
function get_shard_for_user(user_id) {
    user_region = get_user_region(user_id);
    return shard_map[user_region];
}
```

**Benefits:**
- Data locality (GDPR compliance)
- Lower latency

**Drawbacks:**
- Uneven distribution
- Complex user migration

---

**Shard routing layer:**

```python
class ShardRouter:
    def __init__(self):
        self.shards = [
            mysql.connector.connect(host='shard0.db', ...),
            mysql.connector.connect(host='shard1.db', ...),
            # ... 8 shards
        ]
    
    def get_shard(self, user_id):
        shard_id = user_id % len(self.shards)
        return self.shards[shard_id]
    
    def query_user(self, user_id):
        db = self.get_shard(user_id)
        cursor = db.cursor()
        cursor.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        return cursor.fetchone()
    
    def query_all_shards(self, query):
        """Execute query on all shards (scatter-gather)"""
        results = []
        for db in self.shards:
            cursor = db.cursor()
            cursor.execute(query)
            results.extend(cursor.fetchall())
        return results

router = ShardRouter()
user = router.query_user(12345)  # Routes to correct shard
```

---

**Handling cross-shard queries:**

```sql
-- Bad: Join across shards (impossible)
SELECT u.username, o.total
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE u.user_id = 12345;

-- Good: Application-level join
// 1. Get user from user shard
user = user_shard.query("SELECT * FROM users WHERE user_id = 12345");

// 2. Get orders from order shard (same sharding key)
orders = order_shard.query("SELECT * FROM orders WHERE user_id = 12345");

// 3. Join in application
result = merge(user, orders);
```

---

**Rebalancing shards:**

```python
# Add new shard (8 → 16 shards)
# Old: shard_id = user_id % 8
# New: shard_id = user_id % 16

def rebalance():
    """
    Move data from old shards to new shards
    user_id % 8 == 0 → split into user_id % 16 == 0 and user_id % 16 == 8
    """
    for old_shard_id in range(8):
        old_db = get_db(f'shard_{old_shard_id}')
        
        # Users that stay in this shard (user_id % 16 == old_shard_id)
        # Users that move to new shard (user_id % 16 == old_shard_id + 8)
        
        new_shard_db = get_db(f'shard_{old_shard_id + 8}')
        
        # Copy users to new shard
        users = old_db.query(f"SELECT * FROM users WHERE user_id % 16 = {old_shard_id + 8}")
        new_shard_db.bulk_insert(users)
        
        # Delete moved users from old shard
        old_db.execute(f"DELETE FROM users WHERE user_id % 16 = {old_shard_id + 8}")
```

---

**Best practices:**

| Practice | Why |
|----------|-----|
| **Shard key = Primary key** | Ensures single-shard lookups |
| **Denormalize** | Avoid cross-shard joins |
| **Application routing** | Database doesn't know about shards |
| **Consistent hashing** | Easier rebalancing |
| **Monitor shard sizes** | Detect skew early |
| **Plan for growth** | Start with 2x needed shards |

</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 0 questions
- Medium: 1 question
- Hard: 2 questions
- Expert: 1 question

**Topics Covered:**
- ✅ Table partitioning (RANGE, LIST, HASH, KEY)
- ✅ Data archiving strategies
- ✅ Optimizing queries on billions of rows
- ✅ Horizontal sharding

**Key Takeaways:**
- Partition large tables by date
- Archive old data regularly
- Use summary tables for aggregates
- Shard by primary key for even distribution
- Plan for growth early

**Next Steps:**
- Chapter 18: SQL and Big Data
- Practice implementing partitioning
