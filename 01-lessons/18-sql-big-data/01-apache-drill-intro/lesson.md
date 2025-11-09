# Lesson 18.1: Apache Drill Introduction

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand what Apache Drill is and when to use it
2. Compare schema-on-read vs schema-on-write approaches
3. Understand Drill's architecture and components
4. Set up Apache Drill environment
5. Execute basic Drill queries

## Business Context

**Apache Drill** enables you to query data wherever it lives—files, databases, NoSQL stores—using standard SQL without ETL or schema definition. This "schema-free" approach dramatically reduces time-to-insight and enables true self-service analytics.

**Time:** 45 minutes  
**Level:** Advanced

---

## Part 1: What is Apache Drill?

### Definition

**Apache Drill** = Open-source SQL query engine for big data exploration

**Key Characteristics:**
```
✓ Schema-free: Query data without defining schema first
✓ ANSI SQL: Use familiar SQL syntax
✓ Multi-source: Files, NoSQL, RDBMS in one query
✓ Distributed: Scales horizontally
✓ Fast: In-memory execution, columnar processing
```

### The Problem Drill Solves

**Traditional Approach (Schema-on-Write):**
```
Step 1: Define schema (weeks)
  CREATE TABLE customers (
    id INT,
    name VARCHAR(100),
    email VARCHAR(200)
  );

Step 2: ETL process (days-weeks)
  - Extract from source
  - Transform to schema
  - Load into database

Step 3: Query (minutes)
  SELECT * FROM customers;

Total Time: Weeks to first insight!
```

**Drill Approach (Schema-on-Read):**
```
Step 1: Query directly (minutes)
  SELECT * FROM dfs.`/data/customers.json`;

Total Time: Minutes to first insight!

Schema discovered automatically at query time
```

### Real-World Analogy

**Traditional Database (Library Catalog):**
```
All books catalogued before use
Every book has specific place
Fast to find (if catalogued)
Slow to add new books (must catalog first)
```

**Apache Drill (Warehouse):**
```
Items stored wherever convenient
Find by searching when needed
Slower to find individual items
Fast to add new items (just drop them in)
```

---

## Part 2: Schema-on-Read vs Schema-on-Write

### Schema-on-Write (Traditional RDBMS)

**Process:**
```
1. Design schema → 2. Create tables → 3. Load data → 4. Query

┌─────────────────────────────────────────┐
│  Data Source                             │
│  (CSV, JSON, etc.)                       │
└──────────────┬──────────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │   ETL Process        │
    │  - Parse structure   │
    │  - Transform         │
    │  - Validate          │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │   Database Table     │
    │  (Fixed Schema)      │
    └──────────┬───────────┘
               │
               ▼
         Query Data
```

**Pros:**
```
✓ Fast queries (indexed, optimized)
✓ Data quality enforced
✓ Consistent structure
✓ Mature tooling
```

**Cons:**
```
✗ Slow setup (design + ETL)
✗ Rigid schema (hard to change)
✗ Storage overhead (duplicate data)
✗ ETL maintenance
```

### Schema-on-Read (Apache Drill)

**Process:**
```
1. Query directly → 2. Schema discovered at runtime

┌─────────────────────────────────────────┐
│  Data Source                             │
│  (CSV, JSON, Parquet, MongoDB, etc.)    │
└──────────────┬──────────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │   Apache Drill       │
    │  - Detect schema     │
    │  - Parse on-the-fly  │
    │  - Execute query     │
    └──────────┬───────────┘
               │
               ▼
         Query Results
```

**Pros:**
```
✓ Instant access (no setup)
✓ Flexible (schema evolves)
✓ No data duplication
✓ No ETL needed
```

**Cons:**
```
✗ Slower queries (parse overhead)
✗ No data quality enforcement
✗ Inconsistent structure possible
✗ Limited optimization
```

### When to Use Each

**Use Schema-on-Write (Traditional DB):**
```
✓ Production transactional systems
✓ Data quality critical
✓ High-frequency queries (millions/day)
✓ Known, stable schema
✓ Millisecond latency required

Examples:
- E-commerce transactions
- Banking systems
- ERP applications
```

**Use Schema-on-Read (Drill):**
```
✓ Data exploration
✓ Ad-hoc analysis
✓ Rapidly changing data
✓ Unknown schema
✓ Multi-source integration

Examples:
- Log file analysis
- Data lake exploration
- Prototyping
- Self-service analytics
```

**Use Both (Hybrid):**
```
✓ Start with Drill (explore)
✓ Identify valuable data
✓ Load into RDBMS (production)
✓ Keep raw data for flexibility

Example:
- Explore logs with Drill
- Identify important metrics
- ETL critical data to SQL Server
- Keep full logs in data lake
```

---

## Part 3: Apache Drill Architecture

### High-Level Architecture

```
┌────────────────────────────────────────────────────┐
│              Apache Drill Cluster                   │
├────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐ │
│  │           Drillbit (Query Node)              │ │
│  │  ┌────────────────────────────────────────┐ │ │
│  │  │  SQL Parser                            │ │ │
│  │  │  (Parse SQL → Query Plan)              │ │ │
│  │  └─────────────────┬──────────────────────┘ │ │
│  │                    │                         │ │
│  │  ┌─────────────────▼──────────────────────┐ │ │
│  │  │  Query Optimizer                       │ │ │
│  │  │  (Optimize, Pushdown)                  │ │ │
│  │  └─────────────────┬──────────────────────┘ │ │
│  │                    │                         │ │
│  │  ┌─────────────────▼──────────────────────┐ │ │
│  │  │  Execution Engine                      │ │ │
│  │  │  (Distributed, In-Memory)              │ │ │
│  │  └─────────────────┬──────────────────────┘ │ │
│  └────────────────────┼────────────────────────┘ │
└───────────────────────┼──────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
   ┌─────────┐    ┌─────────┐    ┌─────────┐
   │  Files  │    │MongoDB  │    │ MySQL   │
   │ (HDFS,  │    │(NoSQL)  │    │(RDBMS)  │
   │  S3)    │    │         │    │         │
   └─────────┘    └─────────┘    └─────────┘
```

### Components

**1. Drillbit (Query Node):**
```
- Receives SQL queries
- Parses and optimizes
- Executes queries
- Returns results
- Can run multiple Drillbits (distributed)
```

**2. Storage Plugins:**
```
Connect to data sources:
- File System (dfs): HDFS, S3, local
- MongoDB (mongo)
- MySQL (mysql)
- PostgreSQL (pg)
- Hive (hive)
- HBase (hbase)
- Kafka (kafka)
```

**3. Zookeeper (Optional):**
```
- Cluster coordination
- Service discovery
- High availability
- Required for multi-node clusters
```

### Query Execution Flow

```
1. USER SUBMITS QUERY:
   SELECT name, age FROM dfs.`/data/users.json` WHERE age > 25;

2. SQL PARSER:
   Parse SQL syntax
   Validate structure
   Build abstract syntax tree (AST)

3. QUERY PLANNER:
   Determine execution strategy
   Optimize query plan
   Identify data sources

4. SCHEMA DISCOVERY:
   Read sample of data
   Infer schema (column names, types)
   No schema definition needed!

5. QUERY PUSHDOWN:
   Push filters to data source when possible
   Example: Push "WHERE age > 25" to storage layer
   Reduces data transfer

6. DISTRIBUTED EXECUTION:
   Parallelize across Drillbits
   Process data in-memory
   Columnar processing for efficiency

7. RESULTS:
   Aggregate results
   Return to user
```

---

## Part 4: Setting Up Apache Drill

### Option 1: Docker (Recommended for Learning)

```bash
# Pull Apache Drill image
docker pull apache/drill

# Run Drill container
docker run -it --name drill-sandbox \
  -p 8047:8047 \
  -v /path/to/data:/data \
  apache/drill /bin/bash

# Start Drill in embedded mode (inside container)
/opt/drill/bin/drill-embedded

# You'll see:
# Apache Drill 1.20.0
# "drill baby drill"
# 0: jdbc:drill:zk=local>
```

### Option 2: Download and Install

```bash
# Download Drill
wget https://dlcdn.apache.org/drill/drill-1.20.3/apache-drill-1.20.3.tar.gz

# Extract
tar -xzf apache-drill-1.20.3.tar.gz
cd apache-drill-1.20.3

# Start embedded mode
bin/drill-embedded

# Or start distributed mode
bin/drillbit.sh start
```

### Option 3: Cloud Alternatives (No Installation)

**AWS Athena:**
```
1. AWS Console → Athena
2. Upload CSV/JSON to S3
3. Create external table (schema required)
4. Query with SQL
5. Pay per query ($5/TB scanned)
```

**Azure Synapse Serverless:**
```
1. Azure Portal → Synapse Analytics
2. Upload data to Azure Blob Storage
3. Create external table or OPENROWSET
4. Query with T-SQL
5. Pay per query
```

### Web UI (After Starting Drill)

```
Open browser: http://localhost:8047

Tabs:
- Query: Execute SQL queries
- Profiles: Query execution details
- Storage: Configure data sources
- Metrics: Performance monitoring
- Options: System settings
```

---

## Part 5: Basic Drill Queries

### Example 1: Query Local JSON File

**Sample File: `/data/customers.json`**
```json
{"id": 1, "name": "John Doe", "email": "john@example.com", "age": 30}
{"id": 2, "name": "Jane Smith", "email": "jane@example.com", "age": 25}
{"id": 3, "name": "Bob Johnson", "email": "bob@example.com", "age": 35}
```

**Query:**
```sql
-- Query entire file
SELECT * FROM dfs.`/data/customers.json`;

-- Filter
SELECT name, age 
FROM dfs.`/data/customers.json` 
WHERE age > 25;

-- Aggregate
SELECT AVG(age) AS average_age
FROM dfs.`/data/customers.json`;

-- Output:
┌──────────┬─────┬──────────────────────┐
│   name   │ age │        email         │
├──────────┼─────┼──────────────────────┤
│ John Doe │  30 │ john@example.com     │
│ Bob John │  35 │ bob@example.com      │
└──────────┴─────┴──────────────────────┘
```

### Example 2: Query CSV File

**Sample File: `/data/sales.csv`**
```csv
order_id,customer_id,product,amount,order_date
1,101,Widget A,99.99,2024-01-15
2,102,Widget B,149.99,2024-01-16
3,101,Widget C,199.99,2024-01-17
```

**Query:**
```sql
-- Query CSV (auto-detect header)
SELECT * FROM dfs.`/data/sales.csv`;

-- Columns referenced by header names
SELECT product, amount 
FROM dfs.`/data/sales.csv` 
WHERE amount > 100;

-- Aggregate
SELECT 
    customer_id,
    COUNT(*) AS order_count,
    SUM(amount) AS total_spent
FROM dfs.`/data/sales.csv`
GROUP BY customer_id;
```

### Example 3: Query Directory (Multiple Files)

**Directory: `/data/logs/` containing multiple files**
```
/data/logs/2024-01.json
/data/logs/2024-02.json
/data/logs/2024-03.json
```

**Query All Files:**
```sql
-- Query entire directory (all JSON files)
SELECT * 
FROM dfs.`/data/logs/*.json`
WHERE status_code = 500;

-- Drill automatically reads all files matching pattern
```

### Example 4: Nested JSON

**Sample File: `/data/orders.json`**
```json
{
  "order_id": 1,
  "customer": {
    "name": "John Doe",
    "email": "john@example.com"
  },
  "items": [
    {"product": "Widget A", "qty": 2, "price": 29.99},
    {"product": "Widget B", "qty": 1, "price": 39.99}
  ],
  "total": 99.97
}
```

**Query Nested Fields:**
```sql
-- Access nested object
SELECT 
    order_id,
    t.customer.name AS customer_name,
    t.customer.email AS customer_email,
    total
FROM dfs.`/data/orders.json` t;

-- Flatten array with FLATTEN()
SELECT 
    order_id,
    item.product,
    item.qty,
    item.price
FROM dfs.`/data/orders.json` t,
LATERAL FLATTEN(t.items) AS item;
```

---

## Part 6: When to Use Apache Drill

### Perfect Use Cases

**1. Data Lake Exploration:**
```
Scenario: Data science team exploring new data sources
- Unknown schema
- Multiple formats (CSV, JSON, Parquet)
- Need quick insights

Drill Benefits:
✓ No schema definition needed
✓ Query immediately
✓ Iterate rapidly
```

**2. Log File Analysis:**
```
Scenario: Troubleshoot production issues
- Web server logs (JSON)
- Application logs (JSON)
- Millions of log entries

Drill Benefits:
✓ Query logs directly (no import)
✓ Join logs from multiple sources
✓ Ad-hoc filtering
```

**3. Federated Queries:**
```
Scenario: Join data from MySQL + MongoDB + CSV files
- Customer data in MySQL
- Orders in MongoDB
- Product catalog in CSV

Drill Benefits:
✓ Single SQL query across all sources
✓ No data movement
✓ Unified view
```

**4. Prototyping:**
```
Scenario: Proof-of-concept for new analytics
- Test queries before building ETL
- Validate data quality
- Estimate value

Drill Benefits:
✓ Fast iteration
✓ Low cost (no infrastructure)
✓ Easy to abandon if not valuable
```

### When NOT to Use Drill

**Avoid Drill for:**
```
✗ High-frequency OLTP (use RDBMS)
✗ Real-time transactional queries
✗ Guaranteed sub-second latency
✗ 100+ TB datasets (use Presto/Trino)
✗ Complex window functions (limited support)
✗ Production reporting (use optimized DWH)
```

**Better Alternatives:**
```
Transactions → SQL Server, PostgreSQL
Real-time → Redis, Cassandra
Huge scale → Presto, Trino, BigQuery
Production BI → Snowflake, Synapse, Redshift
```

---

## Part 7: Drill vs Alternatives

### Technology Comparison

| Feature | Apache Drill | Presto/Trino | AWS Athena | Traditional DB |
|---------|--------------|--------------|------------|----------------|
| **Schema** | Schema-free | Schema required | Schema required | Fixed schema |
| **Setup Time** | Minutes | Hours | Minutes | Days-Weeks |
| **Data Sources** | Many | Many | S3 only | One |
| **Performance** | Good | Excellent | Good | Excellent |
| **Scale** | Medium | Very Large | Very Large | Limited |
| **Cost** | Free | Free | Pay/query | License + HW |
| **Best For** | Exploration | Production | AWS workloads | OLTP |

### Decision Matrix

```
┌─────────────────────────────────────────────────┐
│ CHOOSE DRILL IF:                                 │
├─────────────────────────────────────────────────┤
│ ✓ Schema unknown or evolving                   │
│ ✓ Ad-hoc exploration                            │
│ ✓ Multiple heterogeneous sources               │
│ ✓ Data size < 10 TB                            │
│ ✓ Learning/experimentation                     │
│ ✓ On-premises or any cloud                     │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CHOOSE PRESTO/TRINO IF:                         │
├─────────────────────────────────────────────────┤
│ ✓ Production analytics                          │
│ ✓ Data size > 10 TB                            │
│ ✓ Performance critical                          │
│ ✓ Known schema                                  │
│ ✓ Need maturity and ecosystem                  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CHOOSE CLOUD SERVERLESS IF:                     │
├─────────────────────────────────────────────────┤
│ ✓ Cloud-first strategy                          │
│ ✓ No infrastructure management wanted          │
│ ✓ Variable/bursty workload                     │
│ ✓ Pay-per-query model acceptable               │
└─────────────────────────────────────────────────┘
```

---

## Key Takeaways

### Core Concepts
```
1. Apache Drill = Schema-free SQL on any data
2. Schema-on-read = Discover schema at query time
3. Multi-source = Query files, NoSQL, RDBMS together
4. Fast setup = Query in minutes, not weeks
5. Flexibility = Schema evolves without migration
```

### When to Use
```
✓ Data exploration
✓ Unknown schema
✓ Multi-source integration
✓ Ad-hoc analysis
✓ Rapid prototyping
```

### Architecture
```
- Drillbit: Query execution node
- Storage Plugins: Connect to data sources
- Distributed: Scale horizontally
- In-memory: Fast processing
```

### Best Practices
```
1. Use for exploration, not production OLTP
2. Organize files by partitions (date, region)
3. Use columnar formats (Parquet) for performance
4. Monitor query profiles
5. Transition valuable workloads to optimized systems
```

---

## Next Steps

**Continue to Lesson 18.2: Querying Files with Drill**  
Hands-on practice querying CSV, JSON, and Parquet files with detailed examples.

---

## Additional Resources

- **Apache Drill Documentation:** https://drill.apache.org/docs/
- **Drill Tutorial:** https://drill.apache.org/docs/drill-in-10-minutes/
- **Drill Community:** https://drill.apache.org/community/
- **GitHub:** https://github.com/apache/drill
