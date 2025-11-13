# Chapter 18: SQL and Big Data - Practice Questions

## Overview
Master SQL integration with big data platforms: Spark SQL, Hive, Presto, data lakes, distributed queries, and hybrid SQL/NoSQL architectures.

---

## Spark SQL

### Question 1: Spark SQL vs Traditional SQL (Easy)
What are the key differences between Spark SQL and MySQL?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Spark SQL** - Distributed query engine for big data
```python
from pyspark.sql import SparkSession

# Create Spark session
spark = SparkSession.builder \
    .appName("BigDataAnalysis") \
    .getOrCreate()

# Read data from various sources
df = spark.read \
    .option("header", "true") \
    .csv("hdfs://data/orders/*.csv")

# SQL query on distributed data
df.createOrReplaceTempView("orders")
result = spark.sql("""
    SELECT 
        customer_id,
        COUNT(*) as order_count,
        SUM(total_amount) as total_spent
    FROM orders
    WHERE order_date >= '2024-01-01'
    GROUP BY customer_id
""")

result.show()
```

**MySQL** - Traditional RDBMS
```sql
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
WHERE order_date >= '2024-01-01'
GROUP BY customer_id;
```

---

**Key Differences:**

| Feature | Spark SQL | MySQL |
|---------|-----------|-------|
| **Storage** | Distributed (HDFS, S3) | Single server |
| **Data Size** | Petabytes | Terabytes (max) |
| **Processing** | In-memory, parallel | Disk-based |
| **Schema** | Schema-on-read (flexible) | Schema-on-write (strict) |
| **Transactions** | No ACID (batch processing) | Full ACID |
| **Latency** | Seconds to minutes | Milliseconds |
| **Use Case** | Big data analytics | OLTP, small analytics |
| **SQL Support** | Subset (HiveQL compatible) | Full ANSI SQL |
| **Joins** | Distributed joins | Local joins |
| **UDFs** | Python, Scala, Java | SQL, C++ |

---

**When to use Spark SQL:**
- ✅ Analyzing logs (TB+ per day)
- ✅ ETL on massive datasets
- ✅ Machine learning data prep
- ✅ Historical data analysis
- ❌ Real-time transactions
- ❌ Small datasets (<1 GB)
- ❌ ACID requirements

**When to use MySQL:**
- ✅ Transactional applications
- ✅ Real-time queries (<100ms)
- ✅ ACID compliance needed
- ✅ Moderate data sizes (<10 TB)
- ❌ Petabyte-scale data
- ❌ Heavy ETL workloads

---

**Hybrid architecture:**
```
MySQL (OLTP) → Kafka → Spark (ETL) → Data Lake → Presto (Ad-hoc queries)
     ↓                                    ↓
   Real-time                          Historical
   transactions                        analytics
```

</details>

---

### Question 2: Spark SQL Query Optimization (Medium)
Optimize a Spark SQL query processing 1 billion rows.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Slow query:**
```python
# Read entire dataset (1 billion rows)
df = spark.read.parquet("s3://data/transactions/")

# Filter and aggregate
result = spark.sql("""
    SELECT 
        customer_id,
        DATE(transaction_date) as date,
        SUM(amount) as daily_total
    FROM transactions
    WHERE transaction_date >= '2024-01-01'
    GROUP BY customer_id, DATE(transaction_date)
""")

result.write.parquet("s3://output/daily_totals/")
```

**Problems:**
- Reads all partitions
- Shuffles all data for GROUP BY
- No caching for repeated queries

---

**Optimization 1: Partition pruning**
```python
# Partition data by date when writing
df.write \
    .partitionBy("year", "month", "day") \
    .parquet("s3://data/transactions_partitioned/")

# Now queries only scan needed partitions
df = spark.read.parquet("s3://data/transactions_partitioned/")
result = spark.sql("""
    SELECT customer_id, SUM(amount) as total
    FROM transactions
    WHERE year = 2024 AND month >= 1
    GROUP BY customer_id
""")

# Only reads 2024 partitions (1/5 of data if 5 years total)
```

---

**Optimization 2: Predicate pushdown**
```python
# Push filter to storage layer (reads less data)
df = spark.read \
    .option("mergeSchema", "false") \
    .parquet("s3://data/transactions/") \
    .filter("transaction_date >= '2024-01-01'")  # Filter early

# Better: Use Parquet column statistics
# Parquet skips entire row groups if min/max dates don't match
```

---

**Optimization 3: Broadcast joins (small table)**
```python
# Small dimension table
customers_df = spark.read.parquet("s3://data/customers/")  # 1M rows

# Large fact table
transactions_df = spark.read.parquet("s3://data/transactions/")  # 1B rows

# Bad: Shuffle join (moves 1B rows across network)
result = transactions_df.join(customers_df, "customer_id")

# Good: Broadcast join (sends 1M rows to all executors)
from pyspark.sql.functions import broadcast
result = transactions_df.join(broadcast(customers_df), "customer_id")

# 100x faster (no shuffle)
```

---

**Optimization 4: Caching**
```python
# Cache intermediate results
df = spark.read.parquet("s3://data/transactions/")
df = df.filter("transaction_date >= '2024-01-01'")
df.cache()  # Keep in memory

# Query 1: Daily totals
daily = df.groupBy("transaction_date").sum("amount")
daily.show()

# Query 2: Customer totals (reuses cached df)
customer = df.groupBy("customer_id").sum("amount")
customer.show()

# Without cache, df would be read from S3 twice
```

---

**Optimization 5: Repartitioning**
```python
# Data skewed (some customers have 1M transactions, others 10)
df = spark.read.parquet("s3://data/transactions/")

# Bad: 200 partitions (default), but data skewed
result = df.groupBy("customer_id").sum("amount")  # Some tasks take 10x longer

# Good: Repartition by customer_id for even distribution
df = df.repartition(1000, "customer_id")
result = df.groupBy("customer_id").sum("amount")

# Or use salting for extreme skew
from pyspark.sql.functions import rand, concat
df = df.withColumn("salt", (rand() * 10).cast("int"))
df = df.withColumn("customer_id_salted", concat("customer_id", "salt"))
result = df.groupBy("customer_id_salted").sum("amount")
```

---

**Optimization 6: Columnar format (Parquet vs CSV)**
```python
# CSV: 1 TB, reads all columns, no compression
df_csv = spark.read.csv("s3://data/transactions.csv")

# Parquet: 200 GB, columnar, compressed, predicate pushdown
df_parquet = spark.read.parquet("s3://data/transactions.parquet")

# Query only reads needed columns
result = spark.sql("""
    SELECT customer_id, amount
    FROM transactions
    WHERE transaction_date = '2024-01-01'
""")
# Parquet only reads 2 columns (customer_id, amount) + predicate column
# CSV must read all 50 columns
```

---

**Performance comparison:**

| Optimization | Speedup | Complexity |
|--------------|---------|------------|
| **Partition pruning** | 5-10x | Low |
| **Predicate pushdown** | 2-5x | Low |
| **Broadcast join** | 10-100x | Low |
| **Caching** | 5-20x | Medium |
| **Repartitioning** | 2-5x | Medium |
| **Parquet vs CSV** | 5-10x | Low |

**Recommended:**
1. Store data in Parquet, partitioned by date
2. Use broadcast joins for small tables
3. Cache intermediate results
4. Monitor task skew, repartition if needed

</details>

---

## Hive and Data Lakes

### Question 3: Querying Data Lake with Hive (Medium)
Set up and query a data lake using Hive SQL.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Data Lake Architecture:**
```
Raw Data (S3)
    ↓
Hive External Tables (schema-on-read)
    ↓
SQL Queries (Hive, Presto, Spark)
```

---

**Create Hive external table:**
```sql
-- External table (data stays in S3)
CREATE EXTERNAL TABLE orders_raw (
    order_id BIGINT,
    customer_id BIGINT,
    order_date STRING,
    total_amount DECIMAL(10,2),
    status STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://data-lake/raw/orders/';

-- Hive doesn't load data, just creates schema metadata
```

---

**Partitioned external table:**
```sql
-- Partition by year and month (for query pruning)
CREATE EXTERNAL TABLE orders_partitioned (
    order_id BIGINT,
    customer_id BIGINT,
    total_amount DECIMAL(10,2),
    status STRING
)
PARTITIONED BY (year INT, month INT)
STORED AS PARQUET
LOCATION 's3://data-lake/processed/orders/';

-- Add partitions (manual or auto-discovery)
ALTER TABLE orders_partitioned 
ADD PARTITION (year=2024, month=1) 
LOCATION 's3://data-lake/processed/orders/year=2024/month=1/';

-- Or auto-discover partitions
MSCK REPAIR TABLE orders_partitioned;
```

---

**Query data lake:**
```sql
-- Query raw data (schema-on-read)
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders_raw
WHERE order_date >= '2024-01-01'
GROUP BY customer_id
HAVING SUM(total_amount) > 10000;

-- Hive compiles to MapReduce/Tez/Spark jobs
```

---

**ETL: Raw → Processed (Parquet)**
```sql
-- Convert CSV to Parquet for better performance
CREATE TABLE orders_processed
STORED AS PARQUET
AS
SELECT 
    order_id,
    customer_id,
    CAST(order_date AS DATE) as order_date,
    total_amount,
    status,
    YEAR(CAST(order_date AS DATE)) as year,
    MONTH(CAST(order_date AS DATE)) as month
FROM orders_raw;

-- Parquet is 10x smaller and 5x faster to query
```

---

**Complex Hive query (joins, window functions):**
```sql
-- Top 10 customers by revenue per region
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        c.region,
        c.customer_name,
        SUM(o.total_amount) as total_revenue,
        COUNT(o.order_id) as order_count,
        ROW_NUMBER() OVER (
            PARTITION BY c.region 
            ORDER BY SUM(o.total_amount) DESC
        ) as rank_in_region
    FROM orders_partitioned o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.year = 2024
    GROUP BY c.customer_id, c.region, c.customer_name
)
SELECT 
    region,
    customer_name,
    total_revenue,
    order_count
FROM customer_revenue
WHERE rank_in_region <= 10
ORDER BY region, rank_in_region;
```

---

**Hive optimization:**
```sql
-- Enable dynamic partitioning
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

-- Insert with dynamic partitions
INSERT OVERWRITE TABLE orders_partitioned PARTITION(year, month)
SELECT 
    order_id,
    customer_id,
    total_amount,
    status,
    YEAR(order_date) as year,
    MONTH(order_date) as month
FROM orders_raw;

-- Enable vectorization (10x faster)
SET hive.vectorized.execution.enabled = true;

-- Enable Tez engine (faster than MapReduce)
SET hive.execution.engine = tez;

-- Enable cost-based optimizer
SET hive.cbo.enable = true;
```

---

**Data formats comparison:**

| Format | Size | Read Speed | Write Speed | Use Case |
|--------|------|------------|-------------|----------|
| **CSV** | 1.0x | 1.0x | 1.0x | Raw ingestion |
| **Parquet** | 0.2x | 5.0x | 0.8x | Analytics (columnar) |
| **ORC** | 0.15x | 6.0x | 0.7x | Hive optimized |
| **Avro** | 0.5x | 2.0x | 3.0x | Schema evolution |

**Recommendation: Parquet for data lakes**

</details>

---

## Presto for Ad-Hoc Queries

### Question 4: Federated Queries with Presto (Hard)
Query multiple data sources (MySQL, S3, MongoDB) in a single query.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Presto** - Distributed SQL query engine for heterogeneous data sources

---

**Architecture:**
```
Presto Coordinator
    ↓
Presto Workers (distributed query execution)
    ↓
Connectors: MySQL | PostgreSQL | S3 | MongoDB | Cassandra | ...
```

---

**Configure connectors:**

**1. MySQL connector** (`mysql.properties`)
```properties
connector.name=mysql
connection-url=jdbc:mysql://mysql-server:3306
connection-user=presto
connection-password=secret
```

**2. Hive/S3 connector** (`hive.properties`)
```properties
connector.name=hive-hadoop2
hive.metastore.uri=thrift://hive-metastore:9083
hive.s3.aws-access-key=...
hive.s3.aws-secret-key=...
```

**3. MongoDB connector** (`mongodb.properties`)
```properties
connector.name=mongodb
mongodb.seeds=mongo-server:27017
mongodb.credentials=user:password@database
```

---

**Federated query (join across sources):**
```sql
-- Join MySQL customers with S3 logs and MongoDB events
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,                              -- from MySQL
    COUNT(DISTINCT l.session_id) as sessions,  -- from S3/Hive
    SUM(e.purchase_amount) as total_purchases  -- from MongoDB
FROM mysql.production.customers c
LEFT JOIN hive.logs.web_sessions l 
    ON c.customer_id = l.customer_id
    AND l.event_date >= DATE '2024-01-01'
LEFT JOIN mongodb.analytics.purchases e 
    ON c.customer_id = e.customer_id
WHERE c.created_at >= DATE '2024-01-01'
GROUP BY c.customer_id, c.customer_name, c.email
ORDER BY total_purchases DESC
LIMIT 100;

-- Presto executes distributed join across 3 different data sources!
```

---

**Query S3 data lake directly (no Hive metastore):**
```sql
-- Query Parquet files in S3
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM hive.default.orders
WHERE year = 2024 AND month = 6
GROUP BY customer_id;

-- Or query directly with external location
CREATE TABLE orders_external (
    customer_id BIGINT,
    order_date DATE,
    total_amount DOUBLE
)
WITH (
    external_location = 's3://data-lake/orders/',
    format = 'PARQUET'
);
```

---

**Complex analytics (window functions, CTEs):**
```sql
WITH daily_metrics AS (
    -- Aggregate from S3 data lake
    SELECT 
        DATE(order_timestamp) as order_date,
        customer_id,
        SUM(total_amount) as daily_spent,
        COUNT(*) as daily_orders
    FROM hive.warehouse.orders
    WHERE year = 2024
    GROUP BY DATE(order_timestamp), customer_id
),
customer_segments AS (
    -- Join with MySQL for customer attributes
    SELECT 
        c.customer_id,
        c.customer_tier,
        c.region,
        AVG(dm.daily_spent) as avg_daily_spent,
        SUM(dm.daily_orders) as total_orders,
        -- Window function
        RANK() OVER (
            PARTITION BY c.region 
            ORDER BY SUM(dm.daily_spent) DESC
        ) as rank_in_region
    FROM mysql.production.customers c
    JOIN daily_metrics dm ON c.customer_id = dm.customer_id
    GROUP BY c.customer_id, c.customer_tier, c.region
)
SELECT 
    region,
    customer_tier,
    COUNT(*) as customer_count,
    AVG(avg_daily_spent) as avg_spending,
    SUM(total_orders) as total_orders
FROM customer_segments
WHERE rank_in_region <= 100
GROUP BY region, customer_tier
ORDER BY region, customer_tier;
```

---

**Presto advantages:**

| Feature | Presto | Hive | Spark SQL |
|---------|--------|------|-----------|
| **Latency** | Seconds | Minutes | Seconds-Minutes |
| **Interactivity** | Interactive | Batch | Batch/Interactive |
| **Connectors** | 20+ sources | Hadoop only | Limited |
| **Federation** | ✅ Yes | ❌ No | ❌ No |
| **Memory** | In-memory | Disk | In-memory |
| **Use Case** | Ad-hoc queries | ETL | ETL + ML |

---

**Performance tuning:**
```sql
-- Broadcast join for small tables
SELECT /*+ BROADCAST(customers) */
    o.order_id,
    c.customer_name
FROM hive.warehouse.orders o
JOIN mysql.production.customers c 
    ON o.customer_id = c.customer_id;

-- Partition pruning
SELECT * FROM hive.warehouse.orders
WHERE year = 2024 AND month = 6 AND day = 15;
-- Only scans 1 partition

-- Limit data scanned
SELECT customer_id, total_amount
FROM hive.warehouse.orders
WHERE year = 2024
  AND total_amount > 1000
LIMIT 10000;
```

---

**Monitoring queries:**
```sql
-- View running queries
SELECT 
    query_id,
    state,
    elapsed_time_millis / 1000.0 as elapsed_seconds,
    query
FROM system.runtime.queries
WHERE state = 'RUNNING'
ORDER BY create_time DESC;

-- Kill slow query
CALL system.runtime.kill_query('20240615_123456_00001_abcde');
```

</details>

---

## Hybrid SQL/NoSQL

### Question 5: Polyglot Persistence Architecture (Expert)
Design a system using MySQL, Redis, MongoDB, and Elasticsearch together.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Architecture: E-commerce platform**

```
┌─────────────────────────────────────────────────────┐
│                  Application Layer                   │
└──────────┬──────────┬──────────┬──────────┬─────────┘
           │          │          │          │
      ┌────▼────┐ ┌──▼───┐ ┌────▼────┐ ┌───▼────────┐
      │  MySQL  │ │ Redis│ │ MongoDB │ │Elasticsearch│
      │  (OLTP) │ │(Cache)│ │ (Logs) │ │  (Search)  │
      └─────────┘ └──────┘ └─────────┘ └────────────┘
```

---

**MySQL - Transactional data (ACID required)**
```sql
-- Core business entities
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    total_amount DECIMAL(10,2),
    status ENUM('pending', 'paid', 'shipped', 'delivered'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

-- Transaction: Create order (ACID)
START TRANSACTION;
INSERT INTO orders (customer_id, total_amount, status) 
VALUES (123, 99.99, 'pending');
UPDATE inventory SET stock = stock - 1 WHERE product_id = 456;
COMMIT;
```

---

**Redis - Caching and session management**
```python
import redis
r = redis.Redis(host='localhost', port=6379)

# Cache expensive MySQL query
cache_key = "top_products:today"
cached = r.get(cache_key)

if cached:
    top_products = json.loads(cached)
else:
    # Query MySQL
    top_products = db.execute("""
        SELECT product_id, SUM(quantity) as total_sold
        FROM order_items
        WHERE DATE(created_at) = CURDATE()
        GROUP BY product_id
        ORDER BY total_sold DESC
        LIMIT 10
    """)
    
    # Cache for 5 minutes
    r.setex(cache_key, 300, json.dumps(top_products))

# Session storage
r.setex(f"session:{session_id}", 3600, json.dumps(user_data))

# Real-time counters
r.incr(f"page_views:{product_id}")

# Shopping cart (hash)
r.hset(f"cart:{user_id}", product_id, quantity)
cart = r.hgetall(f"cart:{user_id}")
```

---

**MongoDB - Logs and semi-structured data**
```python
from pymongo import MongoClient
client = MongoClient('mongodb://localhost:27017/')
db = client.analytics

# Store user activity logs (flexible schema)
db.user_events.insert_one({
    "user_id": 123,
    "event_type": "product_view",
    "product_id": 456,
    "timestamp": datetime.utcnow(),
    "session_id": "abc123",
    "metadata": {
        "referrer": "google.com",
        "device": "mobile",
        "location": {"country": "US", "city": "NYC"}
    }
})

# Query logs
recent_views = db.user_events.find({
    "user_id": 123,
    "event_type": "product_view",
    "timestamp": {"$gte": datetime.now() - timedelta(days=7)}
}).sort("timestamp", -1).limit(50)

# Aggregate analytics
pipeline = [
    {"$match": {"event_type": "purchase"}},
    {"$group": {
        "_id": "$product_id",
        "total_purchases": {"$sum": 1},
        "total_revenue": {"$sum": "$amount"}
    }},
    {"$sort": {"total_revenue": -1}},
    {"$limit": 10}
]
top_products = list(db.user_events.aggregate(pipeline))
```

---

**Elasticsearch - Full-text search**
```python
from elasticsearch import Elasticsearch
es = Elasticsearch(['http://localhost:9200'])

# Index product catalog
es.index(index='products', id=456, body={
    "product_id": 456,
    "name": "Wireless Bluetooth Headphones",
    "description": "Premium noise-canceling headphones with 30-hour battery",
    "category": "Electronics",
    "price": 199.99,
    "tags": ["wireless", "bluetooth", "audio", "headphones"]
})

# Full-text search
search_results = es.search(index='products', body={
    "query": {
        "multi_match": {
            "query": "wireless headphones",
            "fields": ["name^3", "description", "tags^2"]  # Boost name and tags
        }
    },
    "size": 20
})

# Faceted search (filters + aggregations)
search_results = es.search(index='products', body={
    "query": {
        "bool": {
            "must": [{"match": {"description": "bluetooth"}}],
            "filter": [
                {"range": {"price": {"gte": 50, "lte": 200}}},
                {"term": {"category": "Electronics"}}
            ]
        }
    },
    "aggs": {
        "price_ranges": {
            "range": {
                "field": "price",
                "ranges": [
                    {"to": 50},
                    {"from": 50, "to": 100},
                    {"from": 100, "to": 200},
                    {"from": 200}
                ]
            }
        },
        "categories": {
            "terms": {"field": "category"}
        }
    }
})
```

---

**Data flow:**

```
1. User creates order
   ├─→ MySQL: Insert order (ACID transaction)
   ├─→ Redis: Invalidate cache (top_products)
   ├─→ MongoDB: Log event (order_placed)
   └─→ Elasticsearch: (no action)

2. User searches for "bluetooth headphones"
   ├─→ MySQL: (not used for search)
   ├─→ Redis: Check search cache
   ├─→ MongoDB: (not used)
   └─→ Elasticsearch: Full-text search

3. User views product page
   ├─→ MySQL: Get product details (if not cached)
   ├─→ Redis: Cache product data (5 min TTL)
   ├─→ MongoDB: Log view event
   └─→ Elasticsearch: Get related products (more like this)

4. Analytics dashboard
   ├─→ MySQL: Sales summary (aggregates)
   ├─→ Redis: Dashboard cache (30 sec TTL)
   ├─→ MongoDB: User behavior analytics
   └─→ Elasticsearch: Search analytics (trending queries)
```

---

**When to use each:**

| Database | Use Case | Why |
|----------|----------|-----|
| **MySQL** | Orders, payments, inventory | ACID, foreign keys, transactions |
| **Redis** | Cache, sessions, counters | Microsecond latency, in-memory |
| **MongoDB** | Logs, events, flexible data | Schema-less, easy denormalization |
| **Elasticsearch** | Search, autocomplete, analytics | Full-text, facets, relevance ranking |

---

**Consistency strategy:**

```python
# Eventual consistency pattern
def create_order(user_id, items):
    # 1. MySQL (source of truth)
    order_id = mysql_db.execute("""
        INSERT INTO orders (customer_id, total) 
        VALUES (%s, %s)
    """, (user_id, calculate_total(items)))
    
    # 2. MongoDB (async logging) - fire and forget
    mongodb.user_events.insert_one({
        "event": "order_created",
        "order_id": order_id,
        "user_id": user_id,
        "timestamp": datetime.utcnow()
    })
    
    # 3. Redis (cache invalidation)
    redis.delete(f"user_orders:{user_id}")
    
    # 4. Elasticsearch (async indexing via change data capture)
    # Kafka streams MySQL binlog → Elasticsearch
    
    return order_id
```

**Change Data Capture (CDC) for sync:**
```
MySQL binlog → Debezium → Kafka → Elasticsearch/MongoDB
(Real-time sync from MySQL to other systems)
```

</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 2 questions
- Hard: 1 question
- Expert: 1 question

**Topics Covered:**
- ✅ Spark SQL for big data processing
- ✅ Hive and data lakes
- ✅ Presto for federated queries
- ✅ Polyglot persistence (MySQL + Redis + MongoDB + ES)

**Key Takeaways:**
- Spark SQL for batch processing (TB-PB scale)
- Hive for data lake SQL interface
- Presto for ad-hoc cross-source queries
- Use right database for right job
- Eventual consistency in distributed systems

**Congratulations!**
You've completed all 18 chapters covering:
- SQL fundamentals → Advanced topics → Big data integration
- From basic SELECT to distributed query engines
- Total: 150+ practice questions with detailed solutions

**Next Steps:**
- Practice on real datasets
- Build projects using learned concepts
- Explore cloud data warehouses (Snowflake, BigQuery, Redshift)
