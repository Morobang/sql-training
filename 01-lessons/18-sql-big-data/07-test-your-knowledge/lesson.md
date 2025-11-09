# Lesson 18.7: Test Your Knowledge

## Assessment Overview

This comprehensive assessment tests your understanding of **Chapter 18: SQL and Big Data**. It covers Apache Drill, querying files, federated queries, and modern SQL technologies.

**Total Points:** 150  
**Passing Score:** 105 (70%)  
**Time:** 45 minutes  
**Format:** Open-ended questions, practical scenarios, query writing

---

## Section 1: Apache Drill Fundamentals (25 points)

### Question 1.1 (8 points)
**Explain the difference between schema-on-write and schema-on-read approaches. Give an example of when you would use each.**

**Your Answer:**
```
Schema-on-Write:
[Your explanation here]

Schema-on-Read:
[Your explanation here]

Use Cases:
[Your examples here]
```

---

### Question 1.2 (7 points)
**List and explain THREE key components of Apache Drill's architecture.**

**Your Answer:**
```
1. [Component name]: [Explanation]

2. [Component name]: [Explanation]

3. [Component name]: [Explanation]
```

---

### Question 1.3 (10 points)
**When would you choose Apache Drill over Presto/Trino, and vice versa? Provide specific criteria.**

**Your Answer:**
```
Choose Drill when:
[Your criteria here]

Choose Presto/Trino when:
[Your criteria here]
```

---

## Section 2: Querying Files with Drill (30 points)

### Question 2.1 (10 points)
**Write a Drill SQL query to:**
- Query a CSV file located at `/data/sales/2024-Q1.csv`
- Filter for sales > $1000
- Group by product category
- Calculate total revenue and average sale amount per category
- Order by total revenue descending

**Your Answer:**
```sql
-- Write your query here


```

---

### Question 2.2 (10 points)
**Given this JSON file structure:**
```json
{
  "order_id": 1001,
  "customer": {
    "id": 5001,
    "name": "John Doe",
    "email": "john@example.com"
  },
  "items": [
    {"product": "Widget A", "qty": 2, "price": 29.99},
    {"product": "Widget B", "qty": 1, "price": 49.99}
  ],
  "total": 109.97
}
```

**Write TWO queries:**
1. Access nested customer email
2. Flatten items array and calculate total revenue per product

**Your Answer:**
```sql
-- Query 1: Access nested email



-- Query 2: Flatten and aggregate



```

---

### Question 2.3 (10 points)
**Explain why Parquet format is preferred over CSV for large datasets in data lakes. List at least FOUR specific advantages.**

**Your Answer:**
```
1. [Advantage and explanation]

2. [Advantage and explanation]

3. [Advantage and explanation]

4. [Advantage and explanation]
```

---

## Section 3: Database Integration (25 points)

### Question 3.1 (8 points)
**Describe the steps to configure Apache Drill to connect to a MySQL database. Include the storage plugin configuration JSON.**

**Your Answer:**
```
Steps:
1. [Step]
2. [Step]
3. [Step]
...

Configuration JSON:
{
  [Your JSON here]
}
```

---

### Question 3.2 (10 points)
**Write a federated query that:**
- Joins MySQL customer table (mysql.crm.customers) with CSV file (/data/customer_scores.csv)
- Filters for customers with score > 80
- Includes columns: customer_id, name, email from MySQL and score, segment from CSV
- Orders by score descending

**Your Answer:**
```sql
-- Write your federated query here



```

---

### Question 3.3 (7 points)
**What is "query pushdown" and why is it important for performance when querying MySQL through Drill?**

**Your Answer:**
```
Definition:
[Your explanation]

Why Important:
[Your explanation]

Example:
[Your example]
```

---

## Section 4: Querying MongoDB (20 points)

### Question 4.1 (10 points)
**Given this MongoDB document:**
```json
{
  "user_id": 5001,
  "name": "Alice Johnson",
  "orders": [
    {"order_id": 101, "total": 99.99, "date": "2024-01-15"},
    {"order_id": 102, "total": 149.99, "date": "2024-02-20"},
    {"order_id": 103, "total": 75.50, "date": "2024-03-10"}
  ],
  "loyalty_tier": "Gold"
}
```

**Write a Drill query to:**
- Flatten the orders array
- Calculate total number of orders and sum of order totals per user
- Filter for Gold tier users only

**Your Answer:**
```sql
-- Write your query here



```

---

### Question 4.2 (10 points)
**Explain the purpose of the FLATTEN operator in Apache Drill. When is it necessary, and what does it do to the result set?**

**Your Answer:**
```
Purpose:
[Your explanation]

When Necessary:
[Your explanation]

Effect on Result Set:
[Your explanation with example]
```

---

## Section 5: Multi-Source Federated Queries (30 points)

### Question 5.1 (15 points)
**Design a federated query combining THREE data sources:**

**Sources:**
- MySQL: `mysql.sales.orders` (columns: order_id, customer_id, product_id, amount, order_date)
- MongoDB: `mongo.app.customers` (fields: customer_id, name, email, segment)
- Parquet: `/datalake/products/*.parquet` (columns: product_id, product_name, category, price)

**Requirements:**
- Join all three sources
- Filter for orders in 2024
- Filter for "Premium" segment customers
- Calculate: customer_id, name, total_orders, total_spent, products_purchased (distinct count)
- Order by total_spent descending

**Your Answer:**
```sql
-- Write your three-way federated query here




```

---

### Question 5.2 (15 points)
**Scenario: You need to analyze customer behavior combining:**
- MySQL transactional orders (100K rows)
- MongoDB user profiles (50K documents)
- Parquet clickstream logs (10M rows)

**List FIVE specific optimization techniques you would apply and explain why each improves performance.**

**Your Answer:**
```
1. [Optimization technique]
   Why: [Explanation]

2. [Optimization technique]
   Why: [Explanation]

3. [Optimization technique]
   Why: [Explanation]

4. [Optimization technique]
   Why: [Explanation]

5. [Optimization technique]
   Why: [Explanation]
```

---

## Section 6: Modern SQL Technologies (20 points)

### Question 6.1 (10 points)
**Compare the following SQL engines. For each, describe the best use case:**

| Engine | Best Use Case | Why |
|--------|---------------|-----|
| Apache Drill | | |
| Presto/Trino | | |
| AWS Athena | | |
| BigQuery | | |

**Your Answer:**
[Fill in the table above]

---

### Question 6.2 (10 points)
**Explain what a "lakehouse" architecture is. Describe how it combines features of data lakes and data warehouses. Give an example of a lakehouse technology.**

**Your Answer:**
```
Definition:
[Your explanation]

Data Lake Features:
[List features]

Data Warehouse Features:
[List features]

How Combined:
[Your explanation]

Example Technology:
[Name and brief description]
```

---

## Answer Key & Scoring Guide

### Section 1: Apache Drill Fundamentals (25 points)

**Question 1.1 (8 points)**
```
Schema-on-Write (Traditional):
- Define schema before loading data (4 points)
- Fast queries, slow setup
- Example: RDBMS (CREATE TABLE, then INSERT)

Schema-on-Read (Drill):
- Discover schema at query time (4 points)
- Slow queries, instant access
- Example: Query CSV/JSON directly without table creation

Use Cases:
Schema-on-Write: Production OLTP, data quality critical
Schema-on-Read: Exploration, ad-hoc analysis, unknown schema
```

**Question 1.2 (7 points)**
```
1. Drillbit: Query execution node (2 points)
   - Parses SQL, executes queries, returns results
   
2. Storage Plugins: Connect to data sources (2.5 points)
   - File systems, databases, NoSQL
   
3. Query Optimizer: Optimizes execution (2.5 points)
   - Pushdown predicates, distributed processing
```

**Question 1.3 (10 points)**
```
Choose Drill when: (5 points)
- Schema unknown/evolving
- Multi-source exploration
- Data < 10 TB
- Ad-hoc queries
- Learning/prototyping

Choose Presto/Trino when: (5 points)
- Production analytics
- Data > 10 TB
- Performance critical
- Known schema
- High query volume
```

---

### Section 2: Querying Files with Drill (30 points)

**Question 2.1 (10 points)**
```sql
SELECT 
    category,
    SUM(sale_amount) AS total_revenue,      -- 3 points
    AVG(sale_amount) AS avg_sale_amount     -- 2 points
FROM dfs.`/data/sales/2024-Q1.csv`          -- 2 points
WHERE sale_amount > 1000                     -- 1 point
GROUP BY category                            -- 1 point
ORDER BY total_revenue DESC;                 -- 1 point
```

**Question 2.2 (10 points)**
```sql
-- Query 1: (4 points)
SELECT 
    order_id,
    t.customer.email AS customer_email
FROM dfs.`/data/orders.json` t;

-- Query 2: (6 points)
SELECT 
    item.product,
    SUM(item.qty * item.price) AS total_revenue
FROM dfs.`/data/orders.json` t,
LATERAL FLATTEN(t.items) AS item
GROUP BY item.product;
```

**Question 2.3 (10 points)**
```
1. Columnar storage: Only read needed columns (2.5 points)
2. Compression: 10x smaller files (2.5 points)
3. Predicate pushdown: Skip irrelevant row groups (2.5 points)
4. Embedded schema: No schema inference overhead (2.5 points)
```

---

### Section 3: Database Integration (25 points)

**Question 3.1 (8 points)**
```
Steps: (4 points)
1. Add MySQL JDBC driver to Drill
2. Create JDBC storage plugin in Web UI
3. Configure connection details
4. Test with SHOW TABLES

Configuration: (4 points)
{
  "type": "jdbc",
  "driver": "com.mysql.cj.jdbc.Driver",
  "url": "jdbc:mysql://localhost:3306/",
  "username": "drill_user",
  "password": "password",
  "enabled": true
}
```

**Question 3.2 (10 points)**
```sql
SELECT 
    c.customer_id,
    c.name,
    c.email,
    s.score,
    s.segment
FROM mysql.crm.customers c
JOIN dfs.`/data/customer_scores.csv` s 
    ON c.customer_id = s.customer_id
WHERE s.score > 80
ORDER BY s.score DESC;

-- Scoring: 2 points each for SELECT, FROM, JOIN, WHERE, ORDER BY
```

**Question 3.3 (7 points)**
```
Definition: (3 points)
Execute filters/operations in source database, not Drill

Why Important: (4 points)
- Reduces data transfer
- Leverages source indexes
- Faster execution
- Less memory in Drill
```

---

### Section 4: Querying MongoDB (20 points)

**Question 4.1 (10 points)**
```sql
SELECT 
    t.user_id,
    t.name,
    COUNT(order_detail.order_id) AS total_orders,
    SUM(order_detail.total) AS total_amount
FROM mongo.app.users t,
LATERAL FLATTEN(t.orders) AS order_detail
WHERE t.loyalty_tier = 'Gold'
GROUP BY t.user_id, t.name;

-- Scoring: FLATTEN (3 pts), aggregations (3 pts), 
--          WHERE (2 pts), GROUP BY (2 pts)
```

**Question 4.2 (10 points)**
```
Purpose: (3 points)
Convert array elements into separate rows

When Necessary: (3 points)
When need to aggregate/filter array elements

Effect: (4 points)
Before: 1 row with array [{...}, {...}]
After: Multiple rows, one per array element
```

---

### Section 5: Multi-Source Federated Queries (30 points)

**Question 5.1 (15 points)**
```sql
SELECT 
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.amount) AS total_spent,
    COUNT(DISTINCT o.product_id) AS products_purchased
FROM mongo.app.customers c
JOIN mysql.sales.orders o 
    ON c.customer_id = o.customer_id
JOIN dfs.`/datalake/products/*.parquet` p 
    ON o.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
  AND c.segment = 'Premium'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- Scoring: 3 JOINs (6 pts), WHERE filters (3 pts), 
--          Aggregations (3 pts), GROUP BY/ORDER (3 pts)
```

**Question 5.2 (15 points)**
```
Each optimization worth 3 points (technique + explanation):

1. Filter early: WHERE clauses pushed to each source
   Reduces data transfer before joining

2. Select minimal columns: Only needed fields
   Less network transfer, less memory

3. Partition pruning: Filter Parquet by partition
   Skip entire directories/files

4. Pre-aggregate: Aggregate before joining
   Smaller datasets in JOIN operation

5. Use indexes: Ensure MySQL/MongoDB indexed
   Faster source queries via pushdown
```

---

### Section 6: Modern SQL Technologies (20 points)

**Question 6.1 (10 points - 2.5 points each)**
```
Apache Drill:
- Best: Schema-free exploration, multi-source
- Why: No schema definition, instant access

Presto/Trino:
- Best: Production analytics, petabyte-scale
- Why: Mature, fast, proven at scale

AWS Athena:
- Best: AWS workloads, S3 data
- Why: Serverless, pay-per-query, S3 native

BigQuery:
- Best: Google Cloud, massive datasets
- Why: Serverless, petabyte-scale, built-in ML
```

**Question 6.2 (10 points)**
```
Definition: (2 points)
Data lake + data warehouse features combined

Data Lake Features: (2 points)
- Cheap storage
- Flexible schema
- All data types

Data Warehouse Features: (2 points)
- ACID transactions
- Fast queries
- Schema enforcement

How Combined: (2 points)
Store data in files (Parquet) with transaction layer
(Delta Lake, Iceberg)

Example: (2 points)
Delta Lake - ACID on Parquet files in S3/ADLS
```

---

## Scoring Guide

**Total Points: 150**

| Score Range | Grade | Assessment |
|-------------|-------|------------|
| 135-150 | Excellent | Expert-level understanding |
| 120-134 | Very Good | Strong grasp of concepts |
| 105-119 | Good (Pass) | Solid understanding |
| 90-104 | Fair | Review recommended |
| Below 90 | Needs Work | Revisit lessons |

---

## Review Recommendations by Section

**If scored < 70% in Section 1:**
- Revisit Lesson 18.1: Apache Drill Introduction
- Review schema-on-read vs schema-on-write
- Practice Drill architecture concepts

**If scored < 70% in Section 2:**
- Revisit Lesson 18.2: Querying Files with Drill
- Practice CSV, JSON, Parquet queries
- Master FLATTEN operator

**If scored < 70% in Section 3:**
- Revisit Lesson 18.3: Querying MySQL with Drill
- Practice JDBC plugin configuration
- Review query pushdown concepts

**If scored < 70% in Section 4:**
- Revisit Lesson 18.4: Querying MongoDB with Drill
- Practice nested document queries
- Master MongoDB FLATTEN patterns

**If scored < 70% in Section 5:**
- Revisit Lesson 18.5: Querying Multiple Sources
- Practice three-way joins
- Review optimization techniques

**If scored < 70% in Section 6:**
- Revisit Lesson 18.6: The Future of SQL
- Review modern SQL engine comparison
- Study lakehouse architecture

---

## Hands-On Practice Projects

**Project 1: Multi-Source Analytics (Beginner)**
```
Setup:
- MySQL sample database (Sakila or similar)
- CSV file with customer data
- JSON log files

Task:
Write federated queries combining all three sources
```

**Project 2: Data Lake Exploration (Intermediate)**
```
Setup:
- Parquet files in S3/local directory
- Apache Drill installed

Task:
Query Parquet files, analyze performance vs CSV
Implement partitioning strategy
```

**Project 3: Real-Time Dashboard (Advanced)**
```
Setup:
- MySQL transactional database
- MongoDB application database
- Parquet data lake files

Task:
Build federated queries for dashboard KPIs
Optimize query performance
Document architecture
```

---

## Congratulations!

**You've completed Chapter 18: SQL and Big Data!**

**You've completed the ENTIRE SQL Training Curriculum!**

You now have comprehensive SQL expertise spanning:
- **Fundamentals** (SELECT, JOIN, filtering, aggregation)
- **Advanced SQL** (subqueries, window functions, CTEs)
- **Database Design** (normalization, indexes, constraints)
- **Performance** (optimization, execution plans)
- **Large Databases** (partitioning, sharding, cloud)
- **Big Data** (Apache Drill, federated queries, lakehouse)

### Next Steps in Your SQL Journey

**Immediate (Next Week):**
- Set up Apache Drill or cloud SQL engine (Athena/BigQuery)
- Practice federated queries on sample data
- Build a multi-source analytics project

**Short Term (Next Month):**
- Earn SQL certifications (Microsoft, Oracle, AWS)
- Contribute to open-source SQL projects
- Share knowledge (blog, presentations)

**Long Term (Career):**
- Specialize: Data Engineer, Analytics Engineer, DBA
- Master cloud data platforms (Databricks, Snowflake)
- Stay current with SQL evolution (streaming, ML)

**You're now equipped to handle any SQL challenge in modern data environments!**

---

## Final Resources

**Communities:**
- r/SQL (Reddit)
- SQL Server Central
- Stack Overflow [sql] tag
- Apache Drill mailing lists

**Certifications:**
- Microsoft: Azure Data Engineer Associate
- AWS: Database Specialty
- Google: Professional Data Engineer
- Databricks: Lakehouse Fundamentals

**Books:**
- "Designing Data-Intensive Applications" (Martin Kleppmann)
- "The Data Warehouse Toolkit" (Ralph Kimball)
- "SQL Performance Explained" (Markus Winand)

**Practice Platforms:**
- SQLZoo
- LeetCode SQL
- HackerRank SQL
- Mode Analytics SQL Tutorial

---

**Thank you for completing this comprehensive SQL training! Keep querying! 🚀**
