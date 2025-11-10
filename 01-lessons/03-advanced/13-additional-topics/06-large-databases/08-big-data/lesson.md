# Lesson 17.8: Big Data Concepts

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand big data characteristics (Volume, Velocity, Variety)
2. Distinguish between RDBMS and big data use cases
3. Understand data lakes vs data warehouses
4. Evaluate big data architectures (Lambda, Kappa)
5. Choose appropriate technology for your data scenario

## Business Context

**Big Data** refers to datasets so large or complex that traditional database systems cannot handle them efficiently. Understanding when to use big data technologies vs traditional SQL databases is critical for building scalable, cost-effective data solutions.

**Time:** 45 minutes  
**Level:** Advanced

---

## Part 1: The Three Vs of Big Data

### Volume - Scale of Data

**RDBMS Scale:**
```
Small:     < 100 GB        (single server, Standard Edition)
Medium:    100 GB - 1 TB   (enterprise server, partitioning)
Large:     1 TB - 10 TB    (high-end server, careful optimization)
Very Large: > 10 TB        (consider alternatives)
```

**Big Data Scale:**
```
Large:      10 TB - 100 TB     (distributed systems required)
Very Large: 100 TB - 1 PB      (Hadoop, cloud data warehouses)
Massive:    > 1 PB             (Google, Facebook, Amazon scale)
```

**Real-World Examples:**

| Organization | Data Volume | Technology |
|--------------|-------------|------------|
| Small E-commerce | 50 GB | SQL Server |
| Regional Retailer | 5 TB | SQL Server + Partitioning |
| National Retailer | 50 TB | Azure Synapse Analytics |
| Global E-commerce | 500 TB | Hadoop + Spark |
| Social Media Platform | 10 PB+ | Custom distributed systems |

### Velocity - Speed of Data

**Data Velocity Spectrum:**

```
Batch Processing (Hours/Days):
- Nightly ETL jobs
- Daily reports
- Monthly aggregations
- Traditional data warehousing
→ SQL Server, SSIS

Micro-Batch (Minutes):
- 15-minute reporting
- Hourly aggregations
- Near real-time dashboards
→ Azure Data Factory, Spark

Streaming (Seconds/Milliseconds):
- Real-time fraud detection
- Live dashboards
- IoT sensor processing
- Clickstream analytics
→ Kafka, Spark Streaming, Azure Stream Analytics

Real-Time (Microseconds):
- Trading systems
- Ad bidding
- Gaming leaderboards
→ In-memory databases, custom solutions
```

**Example: E-Commerce Platform**

```
BATCH (Nightly):
- Daily sales summary
- Customer lifetime value calculation
- Product recommendations training

NEAR REAL-TIME (Minutes):
- Inventory updates
- Sales dashboard
- Trending products

REAL-TIME (Seconds):
- Shopping cart updates
- Personalized recommendations
- Fraud detection alerts
```

### Variety - Types of Data

**Structured Data (Traditional SQL):**
```
✓ Fixed schema
✓ Rows and columns
✓ Data types enforced
✓ ACID transactions

Examples:
- Customer records
- Order transactions
- Financial data
- Inventory levels
```

**Semi-Structured Data (NoSQL, Big Data):**
```
✓ Flexible schema
✓ Nested structures
✓ Self-describing
✗ May lack consistency

Formats:
- JSON (web APIs, documents)
- XML (legacy systems, config files)
- Avro (Hadoop ecosystem)
- Parquet (columnar storage)

Examples:
- API responses
- Log files (JSON format)
- Configuration files
- IoT sensor data
```

**Unstructured Data (Big Data Systems):**
```
✗ No schema
✓ Arbitrary content
✓ Rich information

Types:
- Text documents
- Images
- Videos
- Audio files
- Social media posts
- Emails

Challenges:
- Cannot store in traditional tables
- Requires specialized processing
- Large storage requirements
```

**Data Variety in Practice:**

```
Traditional E-Commerce (90% Structured):
┌─────────────────────────┐
│  SQL Server Database    │
├─────────────────────────┤
│  Customers (table)      │
│  Orders (table)         │
│  Products (table)       │
│  Inventory (table)      │
└─────────────────────────┘

Modern E-Commerce (Mixed):
┌─────────────────────────────────────┐
│  Structured:                         │
│  - Customer/Order tables (SQL)      │
│                                      │
│  Semi-Structured:                    │
│  - Product catalog (JSON/MongoDB)   │
│  - User sessions (Redis)            │
│  - Clickstream (JSON logs)          │
│                                      │
│  Unstructured:                       │
│  - Product images (Blob Storage)    │
│  - Customer reviews (Text)          │
│  - Video demos (Video files)        │
└─────────────────────────────────────┘
```

---

## Part 2: RDBMS vs Big Data Systems

### When to Use RDBMS (SQL Server)

```
✓ Structured data with fixed schema
✓ ACID transactions required
✓ Complex joins needed
✓ Data size < 10 TB
✓ Low-latency queries (<100ms)
✓ Strong consistency critical
✓ Mature ecosystem/skills
✓ Regulatory compliance (audit trails)

Examples:
- Financial transactions
- E-commerce orders
- ERP systems
- CRM systems
- Healthcare records (HIPAA)
```

### When to Use Big Data Systems

```
✓ Data size > 10 TB
✓ Semi-structured or unstructured data
✓ High write throughput (>100K/sec)
✓ Batch analytics on large datasets
✓ Schemaless or evolving schema
✓ Distributed processing needed
✓ Cost-effective storage for historical data

Examples:
- Log aggregation (millions of logs/second)
- IoT sensor data (billions of events)
- Social media analytics
- Machine learning datasets
- Archival data (cold storage)
```

### Technology Comparison

| Aspect | SQL Server | Hadoop | NoSQL (MongoDB) | Data Warehouse (Synapse) |
|--------|-----------|--------|----------------|------------------------|
| **Data Model** | Relational | File-based | Document/Key-Value | Relational (MPP) |
| **Schema** | Strict | Schema-on-read | Flexible | Strict |
| **Transactions** | ACID | No | Limited | ACID |
| **Scale** | Vertical (up to point) | Horizontal (unlimited) | Horizontal | Horizontal |
| **Query Language** | SQL | Java/Python/SQL | Query API/MQL | SQL |
| **Latency** | Milliseconds | Seconds-Minutes | Milliseconds | Seconds |
| **Use Case** | OLTP | Batch processing | Real-time apps | Analytics |
| **Cost** | Medium-High | Low (commodity hardware) | Medium | High |

---

## Part 3: Data Lakes vs Data Warehouses

### Data Warehouse (Traditional)

**Structure:**
```
┌──────────────────────────────────────┐
│       Data Warehouse                  │
│  (Schema-on-Write - Structure First) │
├──────────────────────────────────────┤
│                                       │
│  ETL Process:                         │
│  1. Extract from sources              │
│  2. Transform (clean, conform)        │
│  3. Load into warehouse               │
│                                       │
│  Schema: Star/Snowflake              │
│  ┌──────────┐                        │
│  │   Fact   │                        │
│  │  Sales   │                        │
│  └────┬─────┘                        │
│       │                               │
│  ┌────┴────┬────────┬──────────┐    │
│  ▼         ▼        ▼          ▼    │
│ Dim       Dim      Dim        Dim   │
│ Date    Product  Customer   Store   │
│                                       │
│  Optimized for: SQL queries          │
│  Users: Business analysts            │
│  Tools: Power BI, Tableau            │
└──────────────────────────────────────┘
```

**Characteristics:**
```
✓ Structured data only
✓ Pre-defined schema (star/snowflake)
✓ High query performance
✓ Expensive storage
✓ Time-consuming ETL
✓ Business-ready data
✗ Limited flexibility
✗ Cannot store raw unstructured data
```

**Examples:**
- Azure Synapse Analytics
- Amazon Redshift
- Google BigQuery
- Snowflake
- Teradata

### Data Lake (Modern)

**Structure:**
```
┌──────────────────────────────────────┐
│         Data Lake                     │
│  (Schema-on-Read - Store Everything) │
├──────────────────────────────────────┤
│                                       │
│  Raw Zone:                            │
│  ├─ Logs (JSON)                      │
│  ├─ Images (PNG/JPG)                 │
│  ├─ Videos (MP4)                     │
│  ├─ CSV files                        │
│  └─ Database dumps                   │
│                                       │
│  Processed Zone:                      │
│  ├─ Cleaned data (Parquet)           │
│  ├─ Aggregated data                  │
│  └─ Feature engineering              │
│                                       │
│  Curated Zone:                        │
│  ├─ Analytics-ready datasets         │
│  └─ ML training datasets             │
│                                       │
│  Optimized for: Flexibility          │
│  Users: Data scientists, engineers   │
│  Tools: Spark, Python, R             │
└──────────────────────────────────────┘
```

**Characteristics:**
```
✓ Any data type (structured, semi, unstructured)
✓ Store raw data (no upfront transformation)
✓ Low-cost storage
✓ Schema flexibility
✓ Support for ML/AI workloads
✓ Exploratory analysis
✗ Slower queries (no indexing)
✗ Requires technical skills
✗ Risk of becoming "data swamp"
```

**Examples:**
- Azure Data Lake Storage
- Amazon S3 + AWS Glue
- Google Cloud Storage
- HDFS (Hadoop)

### Lakehouse Architecture (Best of Both)

**Modern Approach: Combine Lake + Warehouse**

```
┌────────────────────────────────────────────────┐
│              LAKEHOUSE                          │
├────────────────────────────────────────────────┤
│                                                 │
│  Storage Layer: Data Lake (cheap, scalable)   │
│  ├─ Parquet/Delta Lake format                 │
│  └─ ACID transactions on lake                 │
│                                                 │
│  Metadata Layer: Catalog                       │
│  ├─ Schema management                          │
│  ├─ Data lineage                               │
│  └─ Access control                             │
│                                                 │
│  Compute Layer: Multiple engines               │
│  ├─ SQL queries (Synapse, Databricks)         │
│  ├─ Spark jobs (big data processing)          │
│  └─ ML workloads (Python, R)                  │
│                                                 │
│  Benefits:                                      │
│  ✓ Store everything (like lake)               │
│  ✓ Query performance (like warehouse)         │
│  ✓ ACID transactions                           │
│  ✓ Cost-effective                              │
└────────────────────────────────────────────────┘

Technologies:
- Delta Lake (Databricks)
- Apache Iceberg
- Apache Hudi
```

### Comparison Table

| Aspect | Data Warehouse | Data Lake | Lakehouse |
|--------|---------------|-----------|-----------|
| **Data Types** | Structured | All types | All types |
| **Schema** | Schema-on-write | Schema-on-read | Both |
| **Storage Cost** | High ($$$) | Low ($) | Low ($) |
| **Query Performance** | Fast | Slow-Medium | Fast |
| **Users** | Business Analysts | Data Scientists | Both |
| **Use Cases** | BI, Reporting | ML, Exploration | Everything |
| **Transactions** | Yes | No | Yes |
| **Maturity** | Mature (40+ years) | Mature (10 years) | Emerging (5 years) |

---

## Part 4: Big Data Architectures

### Lambda Architecture

**Pattern: Batch + Speed Layer**

```
┌────────────────────────────────────────────────┐
│            DATA SOURCES                         │
│  (Clickstreams, Logs, Transactions, IoT)       │
└──────────────────┬─────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌──────────────┐    ┌──────────────────┐
│ BATCH LAYER  │    │  SPEED LAYER     │
│ (Hadoop)     │    │  (Spark Stream)  │
│              │    │                  │
│ - Complete   │    │ - Recent data    │
│ - Accurate   │    │ - Approximate    │
│ - Slow       │    │ - Fast           │
│              │    │                  │
│ Process:     │    │ Process:         │
│ Hours/Days   │    │ Seconds/Minutes  │
└──────┬───────┘    └────────┬─────────┘
       │                     │
       └──────────┬──────────┘
                  ▼
        ┌─────────────────┐
        │  SERVING LAYER  │
        │  (Merge views)  │
        │                 │
        │  Batch View +   │
        │  Real-time View │
        └────────┬────────┘
                 │
                 ▼
          ┌──────────────┐
          │  QUERY API   │
          └──────────────┘
```

**Example: E-Commerce Analytics**

```
BATCH LAYER:
- Process all historical orders (years of data)
- Compute accurate metrics
- Run nightly
- Output: Total sales, customer segments, trends

SPEED LAYER:
- Process last hour of orders
- Compute approximate metrics
- Run continuously
- Output: Current sales, active users

SERVING LAYER:
- Merge batch + speed results
- User query: "Sales today"
  → Batch (yesterday) + Speed (today so far)
```

**Pros & Cons:**

```
PROS:
✓ Handles both batch and real-time
✓ Fault-tolerant (reprocess batch if needed)
✓ Accurate historical data

CONS:
✗ Complex (maintain 2 code paths)
✗ Data processed twice
✗ Challenging to debug
```

### Kappa Architecture

**Pattern: Streaming Only**

```
┌────────────────────────────────────┐
│         DATA SOURCES                │
└──────────────┬─────────────────────┘
               │
               ▼
        ┌─────────────┐
        │   KAFKA     │
        │  (Event Log)│
        └──────┬──────┘
               │
               ▼
     ┌──────────────────┐
     │  STREAM PROCESS  │
     │  (Spark Streaming│
     │   or Flink)      │
     │                  │
     │  - All data      │
     │  - Single code   │
     │  - Reprocess old │
     │    from Kafka    │
     └─────────┬────────┘
               │
               ▼
        ┌─────────────┐
        │  SERVING DB │
        └─────────────┘
```

**Simpler than Lambda:**
- One processing pipeline (streaming)
- Kafka retains all events (replay capability)
- No separate batch layer
- Reprocess from Kafka if needed

**Pros & Cons:**

```
PROS:
✓ Simpler (one code path)
✓ True real-time
✓ Easy to reprocess (replay Kafka)

CONS:
✗ Kafka storage costs
✗ Streaming framework required
✗ Not suitable for massive batch jobs
```

---

## Part 5: Choosing the Right Technology

### Decision Tree

```
START: What are you building?

├─ OLTP Application (Orders, Customers)
│  └─→ SQL Server / PostgreSQL
│
├─ Analytics / Reporting (<10TB)
│  └─→ SQL Server / Azure SQL
│
├─ Analytics / Reporting (>10TB)
│  └─→ Azure Synapse / Snowflake
│
├─ Real-Time Analytics
│  ├─ Low latency (<1s)
│  │  └─→ Clickhouse / TimescaleDB
│  └─ Streaming (seconds)
│     └─→ Spark Streaming / Flink
│
├─ Document Storage
│  └─→ MongoDB / Cosmos DB
│
├─ Log Aggregation / IoT
│  └─→ Elasticsearch / Time-Series DB
│
├─ Machine Learning
│  ├─ Training data
│  │  └─→ Data Lake (Parquet)
│  └─ Feature store
│     └─→ Databricks Feature Store
│
└─ Massive Scale (>100TB)
   └─→ Hadoop / Spark / Cloud Data Warehouse
```

### Use Case Matrix

| Use Case | Volume | Velocity | Variety | Recommended Technology |
|----------|--------|----------|---------|----------------------|
| **E-Commerce Transactions** | Medium | Real-time | Structured | SQL Server |
| **Customer Analytics** | Medium | Batch | Structured | SQL Server + SSAS |
| **Clickstream Analysis** | High | Streaming | Semi-structured | Kafka + Spark |
| **IoT Sensor Data** | Very High | Streaming | Semi-structured | Time-series DB + Data Lake |
| **Social Media Analytics** | Very High | Streaming | Unstructured | Hadoop + Spark + NoSQL |
| **Financial Reporting** | Medium | Batch | Structured | SQL Data Warehouse |
| **Machine Learning** | High | Batch | Mixed | Data Lake + Spark |
| **Log Aggregation** | High | Streaming | Semi-structured | Elasticsearch |
| **Real-Time Dashboards** | Medium | Streaming | Structured | Stream Analytics + Power BI |
| **Archive/Compliance** | Very High | Batch | Mixed | Data Lake (cold storage) |

---

## Part 6: Practical Scenarios

### Scenario 1: Retail Analytics

**Requirements:**
- Daily sales: 10 million transactions
- Historical data: 5 years (18 billion transactions)
- Queries: Sales reports, customer analytics, inventory
- Real-time dashboard for store managers

**Solution:**

```
TRANSACTIONAL (OLTP):
- SQL Server (current data: 1 year)
- Handles point-of-sale transactions
- 10M transactions/day
- Size: ~500 GB

ANALYTICS (OLAP):
- Azure Synapse Analytics
- Historical data: 5 years
- Nightly ETL from SQL Server
- Star schema (optimized for BI)
- Size: ~5 TB

REAL-TIME:
- Azure Stream Analytics
- Process sales stream
- Update Power BI dashboard
- 1-minute latency

ARCHIVE:
- Azure Data Lake (Parquet)
- Data older than 5 years
- Low-cost storage
- Accessible for ML/special analysis
```

### Scenario 2: IoT Platform

**Requirements:**
- 1 million sensors
- 100 events/second per sensor = 100M events/sec
- Store all data for ML
- Real-time anomaly detection

**Solution:**

```
INGESTION:
- Kafka (buffer incoming events)
- Partition by sensor ID
- Retention: 7 days

STREAM PROCESSING:
- Spark Streaming
- Anomaly detection (ML model)
- Aggregation (1-minute windows)

HOT STORAGE (Recent):
- Time-series database (InfluxDB)
- Last 30 days
- Fast queries for dashboards

COLD STORAGE (Historical):
- Data Lake (Parquet)
- All historical data
- For ML model training
- Size: Petabytes

ANALYTICS:
- Databricks (Spark)
- Train ML models
- Historical analysis
```

---

## Key Takeaways

### Big Data Characteristics
```
VOLUME: Scale beyond single server
VELOCITY: Speed of data generation/processing
VARIETY: Multiple data types/formats
```

### Technology Selection
```
SQL Database:
✓ < 10 TB
✓ Structured data
✓ ACID transactions
✓ Low latency

Big Data:
✓ > 10 TB
✓ Mixed data types
✓ Batch analytics
✓ Cost-effective scale
```

### Architectures
```
Data Warehouse: BI, reporting, structured
Data Lake: ML, exploration, all data types
Lakehouse: Best of both worlds
Lambda: Batch + real-time (complex)
Kappa: Streaming only (simpler)
```

### Best Practices
```
1. Start with RDBMS (simplest)
2. Move to big data when necessary
3. Don't over-engineer
4. Consider cloud managed services
5. Design for data lifecycle
6. Plan for both batch and real-time
```

---

## Next Steps

**Continue to Lesson 17.9: Hadoop Ecosystem**  
Deep dive into Hadoop, HDFS, MapReduce, and big data processing frameworks.

---

## Additional Resources

- **Microsoft:** Azure Data Architecture Guide
- **Book:** "Designing Data-Intensive Applications" by Martin Kleppmann
- **Article:** CAP Theorem in distributed systems
- **Course:** Big Data Specialization (Coursera)
