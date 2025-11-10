# Lesson 17.9: Hadoop Ecosystem

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand Hadoop architecture (HDFS, MapReduce, YARN)
2. Work with Hadoop ecosystem components (Hive, HBase, Pig)
3. Integrate SQL Server with Hadoop using PolyBase
4. Evaluate when to use Hadoop vs cloud alternatives
5. Understand Hadoop's role in modern data architectures

## Business Context

**Hadoop** revolutionized big data processing by enabling distributed storage and processing on commodity hardware. While cloud services have replaced many Hadoop use cases, understanding Hadoop concepts remains valuable for working with large-scale data systems.

**Time:** 50 minutes  
**Level:** Advanced

---

## Part 1: Hadoop Core Components

### What is Hadoop?

**Apache Hadoop** = Open-source framework for distributed storage and processing of very large datasets

**Core Philosophy:**
- **Scale-out** (add more servers) vs **scale-up** (bigger server)
- **Commodity hardware** (cheap servers) vs expensive enterprise servers
- **Move computation to data** vs move data to computation
- **Fault-tolerant** (assume failures will happen)

### Hadoop Architecture

```
┌────────────────────────────────────────────────────┐
│              HADOOP ECOSYSTEM                       │
├────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐ │
│  │           YARN (Resource Manager)            │ │
│  │  Manages cluster resources & job scheduling  │ │
│  └──────────────────────────────────────────────┘ │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │MapReduce │  │  Spark   │  │  Other Engines   ││
│  │(Batch)   │  │(Fast)    │  │  (Flink, Tez)    ││
│  └──────────┘  └──────────┘  └──────────────────┘│
│                                                     │
│  ┌──────────────────────────────────────────────┐ │
│  │         HDFS (Distributed Storage)           │ │
│  │   Stores data across multiple servers        │ │
│  └──────────────────────────────────────────────┘ │
│                                                     │
└────────────────────────────────────────────────────┘
```

---

## Part 2: HDFS (Hadoop Distributed File System)

### HDFS Architecture

```
┌─────────────────────────────────────────────┐
│          NameNode (Master)                   │
│  - Metadata (file names, locations)         │
│  - Directory structure                       │
│  - Block mapping                             │
└────────┬────────────────────────────────────┘
         │
    ┌────┴────┬─────────┬─────────┐
    │         │         │         │
    ▼         ▼         ▼         ▼
┌────────┐┌────────┐┌────────┐┌────────┐
│DataNode││DataNode││DataNode││DataNode│
│Block 1 ││Block 2 ││Block 3 ││Block 1 │ (replica)
│Block 4 ││Block 5 ││Block 6 ││Block 2 │ (replica)
│Block 7 ││Block 8 ││Block 9 ││Block 3 │ (replica)
└────────┘└────────┘└────────┘└────────┘
```

### How HDFS Works

**1. File Storage:**
```
Large File: customer_data.csv (1 GB)

Split into blocks (128 MB each):
├─ Block 1: Rows 1-10,000,000
├─ Block 2: Rows 10,000,001-20,000,000
├─ Block 3: Rows 20,000,001-30,000,000
├─ Block 4: Rows 30,000,001-40,000,000
└─ ... (8 blocks total)

Each block replicated 3 times:
Block 1 → DataNode 1, DataNode 3, DataNode 5
Block 2 → DataNode 2, DataNode 4, DataNode 6
Block 3 → DataNode 1, DataNode 4, DataNode 7
...

Total storage: 1 GB × 3 replicas = 3 GB
```

**2. Reading a File:**
```
Client Request: Read customer_data.csv

1. Client asks NameNode: "Where is customer_data.csv?"
2. NameNode responds:
   - Block 1: DataNode 1, 3, 5 (choose closest)
   - Block 2: DataNode 2, 4, 6
   - Block 3: DataNode 1, 4, 7
   ...
3. Client reads blocks in parallel from DataNodes
4. Client assembles blocks into complete file
```

**3. Writing a File:**
```
Client Request: Write new_data.csv (500 MB)

1. Client asks NameNode: "Where should I write?"
2. NameNode allocates DataNodes:
   - Block 1 → DataNode 2, 4, 8
   - Block 2 → DataNode 1, 5, 9
   - Block 3 → DataNode 3, 6, 7
   ...
3. Client writes Block 1 to DataNode 2
4. DataNode 2 replicates to DataNode 4
5. DataNode 4 replicates to DataNode 8
6. Repeat for all blocks
7. NameNode updates metadata
```

### HDFS Characteristics

**Strengths:**
```
✓ Scalable (petabytes on commodity hardware)
✓ Fault-tolerant (replication)
✓ High throughput (parallel reads)
✓ Cost-effective (no expensive SAN)
✓ Write-once, read-many workloads
```

**Limitations:**
```
✗ High latency (not for real-time)
✗ Small files inefficient (metadata overhead)
✗ Not for random writes (append-only)
✗ NameNode = single point of failure (pre-HA)
✗ Not POSIX-compliant (can't use as regular filesystem)
```

### HDFS vs SQL Server Storage

| Aspect | HDFS | SQL Server |
|--------|------|-----------|
| **File Size** | Large files (GB-TB) | Structured data (MB-GB) |
| **Access Pattern** | Sequential (batch) | Random (OLTP) |
| **Latency** | Seconds | Milliseconds |
| **Updates** | Append-only | In-place updates |
| **Replication** | 3x by default | Mirroring/AG |
| **Cost** | Very low (commodity) | High (enterprise SAN) |
| **Best For** | Big data batch jobs | Transactional workloads |

---

## Part 3: MapReduce Programming Model

### What is MapReduce?

**MapReduce** = Programming model for processing large datasets in parallel

**Concept:**
1. **Map:** Transform each input record independently
2. **Shuffle:** Group by key
3. **Reduce:** Aggregate grouped records

### MapReduce Example: Word Count

**Input:** Large text files (10 GB of web pages)

**Problem:** Count frequency of each word

**MapReduce Solution:**

```
INPUT FILES:
File 1: "hello world"
File 2: "hello hadoop"
File 3: "world of hadoop"

┌─────────────────────────────┐
│        MAP PHASE            │
│ (Run on each DataNode)      │
└─────────────────────────────┘

Mapper 1 (File 1):
  Input: "hello world"
  Output:
    ("hello", 1)
    ("world", 1)

Mapper 2 (File 2):
  Input: "hello hadoop"
  Output:
    ("hello", 1)
    ("hadoop", 1)

Mapper 3 (File 3):
  Input: "world of hadoop"
  Output:
    ("world", 1)
    ("of", 1)
    ("hadoop", 1)

┌─────────────────────────────┐
│      SHUFFLE PHASE          │
│ (Group by key)              │
└─────────────────────────────┘

"hello": [1, 1]
"world": [1, 1]
"hadoop": [1, 1]
"of": [1]

┌─────────────────────────────┐
│      REDUCE PHASE           │
│ (Sum counts per word)       │
└─────────────────────────────┘

Reducer 1 ("hello"):
  Input: [1, 1]
  Output: ("hello", 2)

Reducer 2 ("world"):
  Input: [1, 1]
  Output: ("world", 2)

Reducer 3 ("hadoop"):
  Input: [1, 1]
  Output: ("hadoop", 2)

Reducer 4 ("of"):
  Input: [1]
  Output: ("of", 1)

FINAL OUTPUT:
hello: 2
world: 2
hadoop: 2
of: 1
```

### MapReduce Pseudocode

```python
# Map Function (runs in parallel on each data block)
def map(input_key, input_value):
    # input_key: file name
    # input_value: line of text
    words = input_value.split()
    for word in words:
        emit(word, 1)  # Emit (key, value) pair

# Reduce Function (runs after shuffle)
def reduce(key, values):
    # key: word
    # values: list of counts [1, 1, 1, ...]
    total = sum(values)
    emit(key, total)
```

### Real-World MapReduce Use Cases

**1. Log Analysis:**
```
Map: Extract (IP_address, 1) from each log line
Reduce: Count unique visitors per IP

Input: 100 GB of web server logs
Output: Visitor count by IP address
```

**2. Sales Analytics:**
```
Map: Extract (product_id, sale_amount) from transactions
Reduce: Sum sales per product

Input: 1 TB of transaction data
Output: Total revenue per product
```

**3. Recommendation System:**
```
Map: Extract (user_id, [purchased_products])
Reduce: Find common products across users

Input: Millions of user purchase histories
Output: "Users who bought X also bought Y"
```

### MapReduce Limitations

```
✗ Slow (disk I/O between map and reduce)
✗ Not suitable for iterative algorithms (ML)
✗ No built-in SQL (must write Java/Python)
✗ Overkill for small data
✗ Being replaced by Spark
```

---

## Part 4: Hadoop Ecosystem Components

### Apache Hive (SQL on Hadoop)

**What:** SQL-like querying over Hadoop data

```sql
-- Create table in Hive (maps to HDFS files)
CREATE TABLE customers (
    customer_id INT,
    name STRING,
    email STRING,
    region STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/customers';

-- Query with SQL
SELECT region, COUNT(*) as customer_count
FROM customers
GROUP BY region;

-- Hive translates to MapReduce jobs!
```

**Behind the Scenes:**
```
Hive SQL → Query Plan → MapReduce Jobs → Execute on Hadoop
```

**Use Cases:**
- Data warehousing on Hadoop
- Ad-hoc queries on large datasets
- ETL transformations
- Migration from traditional data warehouses

**Pros & Cons:**
```
PROS:
✓ Familiar SQL syntax
✓ No Java/Python needed
✓ Mature ecosystem
✓ Integrates with BI tools

CONS:
✗ Slow (MapReduce overhead)
✗ Not for real-time queries
✗ Limited SQL features
✗ Being replaced by Spark SQL
```

### Apache HBase (NoSQL on HDFS)

**What:** Distributed column-family database on HDFS

```
Table: user_profiles

Row Key: user_id_12345
  ├─ personal:name = "John Doe"
  ├─ personal:email = "john@example.com"
  ├─ personal:age = 30
  ├─ activity:last_login = "2024-11-09 10:30"
  ├─ activity:page_views = 1250
  └─ activity:purchases = 15

Row Key: user_id_67890
  ├─ personal:name = "Jane Smith"
  └─ ... (more columns)
```

**Use Cases:**
- Real-time read/write access to big data
- Sparse data (many columns, not all populated)
- Time-series data
- Web indexing (e.g., Google's Bigtable)

**HBase vs SQL Server:**

| Feature | HBase | SQL Server |
|---------|-------|-----------|
| **Data Model** | Column-family | Relational |
| **Schema** | Flexible | Fixed |
| **Scale** | Petabytes | Terabytes |
| **Transactions** | Row-level | ACID |
| **Queries** | Key-based | SQL (complex) |
| **Latency** | Milliseconds | Milliseconds |

### Apache Pig (Data Flow Language)

**What:** High-level language for data transformations

```pig
-- Load data
customers = LOAD '/data/customers.csv' USING PigStorage(',')
    AS (customer_id:int, name:chararray, region:chararray);

orders = LOAD '/data/orders.csv' USING PigStorage(',')
    AS (order_id:int, customer_id:int, amount:double);

-- Join
joined = JOIN customers BY customer_id, orders BY customer_id;

-- Group and aggregate
grouped = GROUP joined BY region;
result = FOREACH grouped GENERATE 
    group AS region, 
    SUM(joined.amount) AS total_sales;

-- Store results
STORE result INTO '/output/sales_by_region';
```

**Pig vs Hive:**
- **Pig:** Procedural (data flow)
- **Hive:** Declarative (SQL)
- Both compile to MapReduce

### Apache Spark (Replacement for MapReduce)

**Why Spark > MapReduce:**
```
MapReduce:
Map → Disk → Reduce → Disk (slow!)

Spark:
Map → Memory → Reduce → Memory (100x faster!)
```

**Spark SQL Example:**

```python
# Load data
df = spark.read.csv('/data/customers.csv', header=True)

# SQL query (100x faster than Hive/MapReduce)
result = spark.sql("""
    SELECT region, COUNT(*) as customer_count
    FROM customers
    GROUP BY region
""")

result.show()
```

**Spark vs Hadoop:**

| Aspect | MapReduce | Spark |
|--------|-----------|-------|
| **Speed** | Slow (disk I/O) | Fast (in-memory) |
| **Ease of Use** | Java/Python (verbose) | Python/Scala/SQL |
| **Iterative** | No (each job from scratch) | Yes (cache data) |
| **ML** | Difficult | Built-in (MLlib) |
| **Streaming** | No | Yes (Spark Streaming) |
| **Status** | Legacy | Current standard |

---

## Part 5: SQL Server Integration with Hadoop

### PolyBase (Query Hadoop from SQL Server)

**What:** Query HDFS data using T-SQL

**Architecture:**
```
┌─────────────────────────┐
│    SQL Server           │
│  ┌──────────────────┐  │
│  │   T-SQL Query    │  │
│  └────────┬─────────┘  │
│           │             │
│  ┌────────▼─────────┐  │
│  │    PolyBase      │  │
│  │  Query Engine    │  │
│  └────────┬─────────┘  │
└───────────┼─────────────┘
            │
    ┌───────┴────────┐
    │                │
    ▼                ▼
┌────────┐     ┌──────────┐
│ Hadoop │     │ Azure    │
│ (HDFS) │     │ Blob     │
└────────┘     └──────────┘
```

**Setup PolyBase:**

```sql
-- 1. Enable PolyBase
EXEC sp_configure 'polybase enabled', 1;
RECONFIGURE;
GO

-- 2. Create master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
GO

-- 3. Create credential for Hadoop
CREATE DATABASE SCOPED CREDENTIAL HadoopCredential
WITH IDENTITY = 'hadoop_user', SECRET = 'password';
GO

-- 4. Create external data source
CREATE EXTERNAL DATA SOURCE HadoopCluster
WITH (
    TYPE = HADOOP,
    LOCATION = 'hdfs://hadoop-namenode:8020',
    CREDENTIAL = HadoopCredential
);
GO

-- 5. Create external file format
CREATE EXTERNAL FILE FORMAT CSVFileFormat
WITH (
    FORMAT_TYPE = DELIMITEDTEXT,
    FORMAT_OPTIONS (
        FIELD_TERMINATOR = ',',
        STRING_DELIMITER = '"',
        FIRST_ROW = 2  -- Skip header
    )
);
GO

-- 6. Create external table (maps to HDFS file)
CREATE EXTERNAL TABLE ext_Customers (
    CustomerID INT,
    CustomerName VARCHAR(200),
    Region VARCHAR(50),
    TotalPurchases DECIMAL(18,2)
)
WITH (
    LOCATION = '/data/customers/',
    DATA_SOURCE = HadoopCluster,
    FILE_FORMAT = CSVFileFormat
);
GO

-- 7. Query external table (feels like regular SQL!)
SELECT Region, COUNT(*) as CustomerCount, SUM(TotalPurchases) as TotalRevenue
FROM ext_Customers
GROUP BY Region
ORDER BY TotalRevenue DESC;
GO

-- 8. Join SQL Server table with Hadoop data
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Amount,
    c.CustomerName,
    c.Region
FROM Orders o  -- SQL Server table
INNER JOIN ext_Customers c  -- Hadoop external table
    ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= '2024-01-01';
GO
```

**Use Cases:**
```
✓ Query historical data in Hadoop from SQL Server
✓ Join SQL Server data with big data
✓ Archive old data to Hadoop (cheaper storage)
✓ Hybrid analytics (SQL + Hadoop)
```

**Performance Considerations:**
```
✗ Slower than native SQL queries
✗ Network latency (data movement)
✓ Use for large aggregations (push down to Hadoop)
✗ Avoid for small, frequent queries
```

---

## Part 6: Hadoop vs Cloud Alternatives

### Cloud Services Replacing Hadoop

```
Traditional Hadoop:
- HDFS → Azure Data Lake Storage / AWS S3
- MapReduce → Azure Data Factory / AWS Glue
- Hive → Azure Synapse / AWS Athena
- HBase → Azure Cosmos DB / AWS DynamoDB
- Spark → Azure Databricks / AWS EMR

Benefits of Cloud:
✓ Managed (no infrastructure)
✓ Elastic scaling (pay per use)
✓ Faster time to value
✓ Integrated ecosystem
✗ Cost (more expensive at scale)
```

### When to Use Hadoop

```
USE HADOOP:
✓ On-premises requirement (data sovereignty)
✓ Very large scale (petabytes)
✓ Existing Hadoop investment
✓ Cost-sensitive (own hardware cheaper long-term)
✓ Batch processing workloads

USE CLOUD:
✓ Starting new project
✓ Variable workload (bursty)
✓ Need quick setup
✓ Small team (no Hadoop admins)
✓ Integration with cloud services
```

---

## Key Takeaways

### Hadoop Core
```
1. HDFS: Distributed file system (scale-out storage)
2. MapReduce: Parallel processing model (being replaced by Spark)
3. YARN: Resource management (cluster scheduler)
```

### Ecosystem Components
```
- Hive: SQL on Hadoop (data warehousing)
- HBase: Real-time NoSQL database
- Pig: Data flow language
- Spark: Fast in-memory processing (current standard)
```

### SQL Server Integration
```
- PolyBase: Query Hadoop from T-SQL
- External tables: Hadoop data looks like SQL tables
- Hybrid analytics: Combine SQL + big data
```

### Modern Landscape
```
- Hadoop: Mature but declining (legacy systems)
- Cloud: Growing (Azure, AWS, GCP managed services)
- Spark: Current standard for big data processing
- Containers: Kubernetes replacing YARN
```

### Best Practices
```
1. Use cloud for new projects (faster, easier)
2. Use PolyBase for SQL + Hadoop integration
3. Migrate to Spark from MapReduce
4. Consider data lake instead of on-prem Hadoop
5. Design for cloud-first (portable containers)
```

---

## Next Steps

**Continue to Lesson 17.10: NoSQL Document Databases**  
Learn about MongoDB, Cosmos DB, and when to use document databases vs SQL.

---

## Additional Resources

- **Apache Hadoop Documentation**
- **Microsoft PolyBase Guide**
- **Book:** "Hadoop: The Definitive Guide"
- **Course:** Big Data with Hadoop (Coursera)
