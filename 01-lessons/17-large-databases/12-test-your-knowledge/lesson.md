# Lesson 17.12: Test Your Knowledge - Large Databases

## Overview

This comprehensive assessment tests your understanding of all topics covered in Chapter 17: Working with Large Databases. The test covers partitioning, clustering, sharding, big data concepts, Hadoop, NoSQL, and cloud computing.

**Total Points:** 250  
**Passing Score:** 175 (70%)  
**Time Estimate:** 90 minutes

---

## Section 1: Partitioning Concepts (40 points)

### Question 1 (10 points)
**Scenario:** You have a 500 GB Orders table with 200 million rows spanning 5 years. Most queries filter by OrderDate and retrieve data from the last 3 months.

**Part A (5 points):** Design a partitioning strategy. Specify:
- Partition function type (RANGE RIGHT or RANGE LEFT)
- Partition key
- Boundary values (monthly or yearly)
- Justification

**Part B (5 points):** Estimate the performance improvement for this query:
```sql
SELECT CustomerID, SUM(OrderAmount)
FROM Orders
WHERE OrderDate >= '2024-10-01' AND OrderDate < '2024-11-01'
GROUP BY CustomerID;
```

**Your Answer:**
```
Part A:




Part B:


```

---

### Question 2 (10 points)
**Explain the difference between partitioning and sharding. Provide a real-world scenario where you would use each.**

**Your Answer:**
```




```

---

### Question 3 (10 points)
**You created a partitioned table but queries are still slow. List 5 potential reasons why partition elimination might NOT be working.**

**Your Answer:**
```
1. 

2. 

3. 

4. 

5. 

```

---

### Question 4 (10 points)
**Write T-SQL to:**
- Create a partition function for quarterly partitions in 2024
- Create a partition scheme mapping to PRIMARY filegroup
- Create a SalesData table using this partition scheme

**Your Answer:**
```sql
-- Partition function:




-- Partition scheme:




-- Table:




```

---

## Section 2: Index Partitioning (30 points)

### Question 5 (10 points)
**Explain aligned vs non-aligned indexes. When would you intentionally create a non-aligned index?**

**Your Answer:**
```




```

---

### Question 6 (10 points)
**You have a partitioned table with 12 monthly partitions. The current month's partition has 30% fragmentation. The other partitions have < 5% fragmentation.**

**Part A (5 points):** Write the command to rebuild ONLY the fragmented partition.

**Part B (5 points):** Estimate the time savings compared to rebuilding all partitions.

**Your Answer:**
```sql
-- Part A:



-- Part B:


```

---

### Question 7 (10 points)
**Performance Comparison:** Complete this table comparing partitioned vs non-partitioned index maintenance:

| Operation | Non-Partitioned Time | Partitioned Time (1 of 12) | Savings |
|-----------|---------------------|---------------------------|---------|
| Rebuild index (1 TB) | 2 hours | ? | ? |
| Reorganize index | 1 hour | ? | ? |
| Update statistics | 30 minutes | ? | ? |

**Your Answer:**
```




```

---

## Section 3: Clustering and High Availability (35 points)

### Question 8 (15 points)
**Design a high availability solution for a global e-commerce platform:**

**Requirements:**
- Zero data loss in primary region
- Read-scale for reporting
- Disaster recovery in secondary region (15-minute RPO acceptable)
- 24/7 availability (99.99% SLA)

**Your Design:**
```
Technology: (FCI / Always On AG)

Primary Site:
- 

Secondary Site:
-

Synchronization Mode:
-

Read-Scale Strategy:
-

Justification:




```

---

### Question 9 (10 points)
**Compare Failover Cluster Instance (FCI) vs Always On Availability Groups:**

| Feature | FCI | Always On AG |
|---------|-----|--------------|
| Shared Storage Required | ? | ? |
| Read Replicas | ? | ? |
| Geographic Distribution | ? | ? |
| Automatic Failover | ? | ? |
| SQL Server Edition | ? | ? |

**Your Answer:**
```




```

---

### Question 10 (10 points)
**Your Always On AG primary replica failed. Describe the automatic failover process step-by-step (include timing).**

**Your Answer:**
```
1. 

2. 

3. 

4. 

5. 

Typical failover time: _____ seconds
```

---

## Section 4: Sharding (35 points)

### Question 11 (15 points)
**Design a sharding strategy for a multi-tenant SaaS application:**

**Requirements:**
- 10,000 tenants
- Largest tenant: 100 GB
- Smallest tenant: 1 GB
- Most queries filter by TenantID
- Need to isolate tenant data

**Your Design:**
```
Shard Key: 

Sharding Method: (Hash / Range / Directory)

Number of Shards:

Routing Logic:




Handling Large Tenants:




```

---

### Question 12 (10 points)
**Cross-Shard Challenge:** You need to query total revenue across ALL customers, but data is sharded by CustomerID across 4 shards.

**Part A (5 points):** Describe two approaches to solve this.

**Part B (5 points):** Which approach is better and why?

**Your Answer:**
```
Part A:
Approach 1:


Approach 2:


Part B:



```

---

### Question 13 (10 points)
**Identify the problems with this shard key design:**

```sql
-- Table: UserActivity (10 billion rows)
-- Shard Key: Region (values: 'North', 'South', 'East', 'West')
-- Sharding: 4 shards (one per region)
```

**List 3 problems and suggest a better shard key:**

**Your Answer:**
```
Problems:
1. 

2. 

3. 

Better Shard Key:


```

---

## Section 5: Big Data Concepts (30 points)

### Question 14 (10 points)
**Classify each use case as RDBMS, Big Data, or Hybrid:**

| Use Case | Technology | Justification |
|----------|-----------|---------------|
| Banking transactions (1M/day) | ? | ? |
| IoT sensor data (1B events/day) | ? | ? |
| E-commerce orders + clickstream | ? | ? |
| Social media analytics | ? | ? |
| Financial reporting | ? | ? |

**Your Answer:**
```




```

---

### Question 15 (10 points)
**Compare Data Warehouse vs Data Lake:**

| Aspect | Data Warehouse | Data Lake |
|--------|---------------|-----------|
| Data Types | ? | ? |
| Schema | ? | ? |
| Cost | ? | ? |
| Users | ? | ? |
| Query Speed | ? | ? |

**When would you use each?**

**Your Answer:**
```
Data Warehouse:


Data Lake:


```

---

### Question 16 (10 points)
**Explain the Lambda Architecture. Draw a diagram and explain why you might use it.**

**Your Answer:**
```
Diagram:






Explanation:




```

---

## Section 6: Hadoop Ecosystem (25 points)

### Question 17 (10 points)
**Explain how MapReduce works using the word count example. Include Map, Shuffle, and Reduce phases.**

**Your Answer:**
```
Input: "hello world hello hadoop"

Map Phase:




Shuffle Phase:




Reduce Phase:




Output:


```

---

### Question 18 (5 points)
**Why is Spark faster than MapReduce?**

**Your Answer:**
```



```

---

### Question 19 (10 points)
**You want to query Hadoop data from SQL Server. Write the T-SQL to:**
1. Create an external data source pointing to Hadoop
2. Create an external table mapping to HDFS file `/data/customers.csv`
3. Query the external table

**Your Answer:**
```sql
-- 1. External data source:




-- 2. External table:




-- 3. Query:



```

---

## Section 7: NoSQL Document Databases (30 points)

### Question 20 (15 points)
**Design document schema for a blog platform:**

**Requirements:**
- Blog posts with title, content, author
- Each post can have 0-1000 comments
- Each comment has author, text, date
- Need to query posts by author
- Need to query individual posts with comments

**Design embedding vs referencing strategy:**

**Your Answer:**
```json
// Post document:





// Comment document (if separate):





Strategy (embed vs reference):



Justification:




```

---

### Question 21 (10 points)
**When would you use SQL Server vs MongoDB? Provide 3 scenarios for each.**

**Your Answer:**
```
Use SQL Server:
1. 

2. 

3. 

Use MongoDB:
1. 

2. 

3. 

```

---

### Question 22 (5 points)
**Explain partition key selection in Cosmos DB. What makes a good partition key?**

**Your Answer:**
```




```

---

## Section 8: Cloud Computing (25 points)

### Question 23 (10 points)
**Cost Optimization:** You have 5 databases in Azure:

| Database | Current Setup | Monthly Cost |
|----------|--------------|--------------|
| Production | 8 vCores provisioned | $500 |
| Staging | 4 vCores provisioned | $250 |
| Dev | 4 vCores provisioned | $250 |
| QA | 2 vCores provisioned | $125 |
| Test | 2 vCores provisioned | $125 |
| **Total** | | **$1,250** |

**Optimize to reduce cost by 50%. Describe your strategy:**

**Your Answer:**
```




```

---

### Question 24 (10 points)
**Migration Planning:** You need to migrate a 2 TB SQL Server database from on-premises to Azure.

**Part A (5 points):** Choose migration approach (IaaS / Managed Instance / SQL Database) and justify.

**Part B (5 points):** Outline the migration steps.

**Your Answer:**
```
Part A:
Approach: 

Justification:



Part B:
Steps:
1. 

2. 

3. 

4. 

5. 

```

---

### Question 25 (5 points)
**Explain Azure SQL Serverless. When should you use it?**

**Your Answer:**
```




```

---

## Section 9: Comprehensive Scenario (50 points)

### Question 26 (50 points)
**Complete Architecture Design:**

**Scenario:** You are designing a data platform for a global retail chain:

**Requirements:**
- **Transactional Data:**
  - 5,000 stores worldwide
  - 50 million transactions/day
  - Need ACID guarantees
  - Real-time inventory updates

- **Analytics Data:**
  - Historical data: 5 years (10 TB)
  - Real-time dashboard for executives
  - Daily reports
  - Ad-hoc queries by analysts

- **Customer Data:**
  - 100 million customers
  - User profiles (flexible schema)
  - Personalization data
  - Privacy compliance (GDPR)

- **IoT Data:**
  - Store sensors (temperature, traffic)
  - 1 million sensor events/second
  - Anomaly detection
  - Historical analysis

**Design a complete architecture including:**

1. **Transactional Database** (10 points)
   - Technology choice
   - Scaling strategy
   - High availability

2. **Analytics Platform** (10 points)
   - Storage solution
   - Query engine
   - Real-time vs batch

3. **Customer Data** (10 points)
   - Database technology
   - Schema design
   - Compliance considerations

4. **IoT Pipeline** (10 points)
   - Ingestion layer
   - Processing layer
   - Storage strategy

5. **Overall Architecture Diagram** (10 points)
   - Draw complete architecture
   - Show data flows
   - Justify technology choices

**Your Answer:**
```
1. TRANSACTIONAL DATABASE:
Technology:

Scaling:

High Availability:




2. ANALYTICS PLATFORM:
Storage:

Query Engine:

Real-time Strategy:




3. CUSTOMER DATA:
Technology:

Schema Design:

Compliance:




4. IOT PIPELINE:
Ingestion:

Processing:

Storage:




5. ARCHITECTURE DIAGRAM:
[Draw or describe your architecture here]










TECHNOLOGY JUSTIFICATION:




```

---

## Answer Key (For Self-Assessment)

### Section 1: Partitioning (40 points)

**Question 1:**
- RANGE RIGHT partition function
- Partition key: OrderDate
- Monthly boundaries for last 12 months + yearly for older data
- Performance improvement: 90-95% (only scan 1 of 60+ partitions)

**Question 2:**
- Partitioning: Same server, logical split
- Sharding: Multiple servers, physical split
- Use partitioning for performance; sharding for scale beyond single server

**Question 3:**
1. Partition key not in WHERE clause
2. Functions applied to partition key (YEAR(OrderDate))
3. OR conditions spanning partitions
4. Non-aligned indexes
5. Implicit conversions on partition key

**Question 4:**
```sql
CREATE PARTITION FUNCTION pfQuarterly (DATE)
AS RANGE RIGHT FOR VALUES ('2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01');

CREATE PARTITION SCHEME psQuarterly
AS PARTITION pfQuarterly ALL TO ([PRIMARY]);

CREATE TABLE SalesData (...) ON psQuarterly(SaleDate);
```

### Section 2: Index Partitioning (30 points)

**Question 5:**
- Aligned: Same partition scheme as table
- Non-aligned: Different partition scheme
- Use non-aligned for: Global indexes, queries not aligned with table partitioning

**Question 6:**
```sql
-- Part A
ALTER INDEX IX_TableName ON TableName REBUILD PARTITION = 12;

-- Part B
~90% time savings (1/12 of work)
```

**Question 7:**
- Rebuild: ~10 minutes (10x faster)
- Reorganize: ~5 minutes (12x faster)
- Update stats: ~2.5 minutes (12x faster)

### Section 3: Clustering (35 points)

**Question 8:**
- Technology: Always On Availability Groups
- Primary: Primary + 2 synchronous secondaries (zero data loss, read-scale)
- Secondary: 1 asynchronous replica (DR, 15-min RPO acceptable)
- 99.99% SLA with automatic failover

**Question 9:**
| Feature | FCI | Always On |
|---------|-----|-----------|
| Shared Storage | Yes | No |
| Read Replicas | No | Yes |
| Geographic | Limited | Yes |
| Auto Failover | Yes | Yes |
| Edition | Standard+ | Enterprise |

**Question 10:**
1. WSFC detects failure (5-10 seconds)
2. Initiates failover to synchronous secondary (5 seconds)
3. Secondary becomes primary (10 seconds)
4. Applications reconnect (10 seconds)
5. Total: 20-30 seconds

### Section 4: Sharding (35 points)

**Question 11:**
- Shard Key: TenantID
- Method: Directory-based (handle variable tenant sizes)
- Shards: 16 (allows growth)
- Large tenants: Dedicated shard if needed

**Question 12:**
- Approach 1: Fan-out query, application merges
- Approach 2: Reporting database (ETL from all shards)
- Better: Approach 2 for recurring queries; Approach 1 for ad-hoc

**Question 13:**
- Problems: Low cardinality, hot shards, uneven distribution
- Better: UserID (hash-based) for even distribution

### Section 5: Big Data (30 points)

**Question 14:**
- Banking: RDBMS (ACID required)
- IoT: Big Data (volume, velocity)
- E-commerce: Hybrid (SQL for orders, big data for clickstream)
- Social media: Big Data (unstructured, massive scale)
- Financial reporting: RDBMS or Data Warehouse

**Question 15:**
- Warehouse: Structured, schema-on-write, high cost, analysts, fast
- Lake: All types, schema-on-read, low cost, data scientists, variable speed

**Question 16:**
- Batch Layer: Complete, accurate, slow
- Speed Layer: Recent, approximate, fast
- Serving Layer: Merge both views
- Use: When need both historical accuracy and real-time

### Section 6: Hadoop (25 points)

**Question 17:**
- Map: [("hello", 1), ("world", 1), ("hello", 1), ("hadoop", 1)]
- Shuffle: Group by key
- Reduce: Sum per key
- Output: hello:2, world:1, hadoop:1

**Question 18:**
- In-memory processing (vs disk I/O)
- 100x faster for iterative algorithms

**Question 19:**
```sql
CREATE EXTERNAL DATA SOURCE HadoopSource
WITH (TYPE = HADOOP, LOCATION = 'hdfs://namenode:8020');

CREATE EXTERNAL TABLE ext_Customers (...)
WITH (LOCATION='/data/customers.csv', DATA_SOURCE=HadoopSource, ...);

SELECT * FROM ext_Customers;
```

### Section 7: NoSQL (30 points)

**Question 20:**
- Embed comments if typically < 100 per post
- Reference if posts can have 1000+ comments
- Index on authorId for querying posts by author

**Question 21:**
- SQL: Transactions, complex relationships, ACID
- MongoDB: Flexible schema, hierarchical data, rapid development

**Question 22:**
- High cardinality, even distribution, query-aligned
- Example: UserID (good), Region (bad - low cardinality)

### Section 8: Cloud (25 points)

**Question 23:**
- Production: Reserved instance (40% savings = $300)
- Staging: Serverless ($100)
- Dev/QA/Test: Elastic pool shared ($200 total)
- New total: ~$600 (52% savings)

**Question 24:**
- Approach: Managed Instance (99% compatibility)
- Steps: Assessment, schema migration, data sync, testing, cutover

**Question 25:**
- Auto-pause when idle, pay per use
- Use for: Dev/test, variable workload, cost optimization

### Section 9: Comprehensive (50 points)

**Question 26:**
- **Transactional:** Azure SQL Database (sharded by StoreID), Always On for HA
- **Analytics:** Azure Synapse (DWH) + Data Lake, Lambda architecture
- **Customer:** Cosmos DB (flexible schema, global distribution, GDPR compliance)
- **IoT:** Event Hubs (ingest) → Stream Analytics → Time-series DB + Data Lake

---

## Scoring Guide

- **225-250 points:** Excellent - Expert level understanding
- **200-224 points:** Very Good - Strong grasp of concepts
- **175-199 points:** Good - Passing, solid understanding
- **150-174 points:** Fair - Review weak areas
- **Below 150 points:** Need more study - Revisit lessons

---

## Review Recommendations

**If you scored below 70% in any section:**

- **Partitioning:** Review Lessons 17.1-17.5
- **Clustering:** Review Lesson 17.6
- **Sharding:** Review Lesson 17.7
- **Big Data:** Review Lesson 17.8
- **Hadoop:** Review Lesson 17.9
- **NoSQL:** Review Lesson 17.10
- **Cloud:** Review Lesson 17.11

---

## Congratulations!

You have completed Chapter 17: Working with Large Databases!

**Next Steps:**
- Continue to Chapter 18: SQL and Big Data
- Review any weak areas
- Practice implementing these concepts in real projects
- Explore cloud database services hands-on

**Key Takeaway:**
Large database management requires understanding multiple technologies and choosing the right tool for each use case. There is no one-size-fits-all solution!

---

## Additional Practice

**Hands-On Projects:**
1. Set up partitioned table with real data (1M+ rows)
2. Configure Always On Availability Group (lab environment)
3. Migrate on-premises database to Azure SQL
4. Design multi-tenant sharding strategy
5. Build data lake with batch and streaming data
