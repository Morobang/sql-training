# Lesson 18.3: Querying MySQL with Drill

## Learning Objectives

By the end of this lesson, you will be able to:
1. Configure Apache Drill to connect to MySQL
2. Query MySQL tables using Drill
3. Join MySQL data with file-based data
4. Optimize cross-source queries
5. Apply federated query patterns to real-world scenarios

## Business Context

Many enterprises have **valuable data trapped in legacy MySQL databases**. Apache Drill enables you to query MySQL alongside files (CSV, JSON, Parquet) in a **single SQL query**—no data migration required. This unlocks powerful federated analytics.

**Time:** 45 minutes  
**Level:** Advanced

---

## Part 1: Connecting Drill to MySQL

### Prerequisites

**MySQL Database Running:**
```sql
-- Verify MySQL is accessible
mysql -h localhost -u root -p

-- Show databases
SHOW DATABASES;
```

### Configure MySQL Storage Plugin in Drill

**Step 1: Access Drill Web UI**
```
Open browser: http://localhost:8047
Navigate to: Storage tab
Click: "+ Create" (or Update existing)
```

**Step 2: Create MySQL Storage Plugin**

**Plugin Name:** `mysql`

**Configuration:**
```json
{
  "type": "jdbc",
  "driver": "com.mysql.cj.jdbc.Driver",
  "url": "jdbc:mysql://localhost:3306/",
  "username": "drill_user",
  "password": "drill_password",
  "enabled": true
}
```

**Configuration Explanation:**
```
type:     "jdbc" (JDBC-based plugin)
driver:   MySQL JDBC driver class
url:      MySQL connection string
          Format: jdbc:mysql://[host]:[port]/
username: MySQL user with read permissions
password: User password
enabled:  true (activate plugin)
```

**Alternative: Connection to Specific Database**
```json
{
  "type": "jdbc",
  "driver": "com.mysql.cj.jdbc.Driver",
  "url": "jdbc:mysql://localhost:3306/sakila?useSSL=false",
  "username": "drill_user",
  "password": "drill_password",
  "enabled": true
}
```

**Step 3: Add MySQL JDBC Driver**

**Download MySQL Connector/J:**
```bash
# Download from MySQL website
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.33.tar.gz

# Extract
tar -xzf mysql-connector-java-8.0.33.tar.gz

# Copy JAR to Drill
cp mysql-connector-java-8.0.33/mysql-connector-java-8.0.33.jar \
   /opt/drill/jars/3rdparty/
```

**Or use Docker volume:**
```bash
docker run -it --name drill-mysql \
  -p 8047:8047 \
  -v /path/to/mysql-connector.jar:/opt/drill/jars/3rdparty/mysql-connector.jar \
  apache/drill /bin/bash
```

**Step 4: Restart Drill**
```bash
# Embedded mode: Exit and restart
# Distributed mode:
/opt/drill/bin/drillbit.sh restart
```

**Step 5: Test Connection**
```sql
-- List databases
SHOW DATABASES;

-- You should see:
-- cp.default
-- dfs.default
-- mysql        <-- Your MySQL plugin!

-- Show tables in MySQL database
SHOW TABLES IN mysql.sakila;
```

---

## Part 2: Querying MySQL Tables

### Basic MySQL Queries

**Sample MySQL Database: Sakila**

**View Tables:**
```sql
-- List tables
SHOW TABLES IN mysql.sakila;

-- Output:
┌─────────────────┐
│   TABLE_NAME    │
├─────────────────┤
│ actor           │
│ address         │
│ category        │
│ city            │
│ country         │
│ customer        │
│ film            │
│ film_actor      │
│ film_category   │
│ inventory       │
│ language        │
│ payment         │
│ rental          │
│ staff           │
│ store           │
└─────────────────┘
```

**Query MySQL Table:**
```sql
-- Query actors table
SELECT * 
FROM mysql.sakila.actor 
LIMIT 5;

-- Output:
┌──────────┬────────────┬───────────┬─────────────────────┐
│ actor_id │ first_name │ last_name │   last_update       │
├──────────┼────────────┼───────────┼─────────────────────┤
│        1 │ PENELOPE   │ GUINESS   │ 2006-02-15 04:34:33 │
│        2 │ NICK       │ WAHLBERG  │ 2006-02-15 04:34:33 │
│        3 │ ED         │ CHASE     │ 2006-02-15 04:34:33 │
│        4 │ JENNIFER   │ DAVIS     │ 2006-02-15 04:34:33 │
│        5 │ JOHNNY     │ LOLLOBRI  │ 2006-02-15 04:34:33 │
└──────────┴────────────┴───────────┴─────────────────────┘

-- Note: Drill automatically maps MySQL data types to its own types
```

### Filtering MySQL Data

```sql
-- Filter by condition
SELECT first_name, last_name
FROM mysql.sakila.actor
WHERE last_name = 'GUINESS';

-- Output:
┌────────────┬───────────┐
│ first_name │ last_name │
├────────────┼───────────┤
│ PENELOPE   │ GUINESS   │
└────────────┴───────────┘

-- Filter with LIKE
SELECT first_name, last_name
FROM mysql.sakila.actor
WHERE last_name LIKE 'W%'
ORDER BY last_name, first_name;

-- Numeric filter
SELECT customer_id, amount, payment_date
FROM mysql.sakila.payment
WHERE amount > 10.00
ORDER BY amount DESC
LIMIT 10;
```

### Aggregating MySQL Data

```sql
-- Count customers by city
SELECT 
    ci.city,
    COUNT(cu.customer_id) AS customer_count
FROM mysql.sakila.customer cu
JOIN mysql.sakila.address a ON cu.address_id = a.address_id
JOIN mysql.sakila.city ci ON a.city_id = ci.city_id
GROUP BY ci.city
ORDER BY customer_count DESC
LIMIT 10;

-- Total payments by customer
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(p.payment_id) AS payment_count,
    SUM(p.amount) AS total_spent
FROM mysql.sakila.customer c
JOIN mysql.sakila.payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 10;
```

### Joins Within MySQL

```sql
-- Join multiple MySQL tables
SELECT 
    f.title AS film_title,
    c.name AS category,
    f.rental_rate,
    f.length AS duration_minutes
FROM mysql.sakila.film f
JOIN mysql.sakila.film_category fc ON f.film_id = fc.film_id
JOIN mysql.sakila.category c ON fc.category_id = c.category_id
WHERE c.name IN ('Action', 'Sci-Fi')
ORDER BY f.rental_rate DESC
LIMIT 10;

-- Output:
┌─────────────────────────┬──────────┬─────────────┬──────────────────┐
│      film_title         │ category │ rental_rate │ duration_minutes │
├─────────────────────────┼──────────┼─────────────┼──────────────────┤
│ UNFAITHFUL KILL         │ Sci-Fi   │        4.99 │              187 │
│ TROUBLE DATE            │ Action   │        4.99 │               61 │
│ TIMBERLAND SKY          │ Sci-Fi   │        4.99 │               69 │
│ ...                     │ ...      │         ... │              ... │
└─────────────────────────┴──────────┴─────────────┴──────────────────┘
```

---

## Part 3: Joining MySQL with Files

### Scenario: Enrich MySQL Data with File Data

**Business Problem:**
```
MySQL database:    Customer transactions (OLTP)
CSV file:          Customer lifetime value analysis (data science output)

Goal: Join MySQL transactional data with CSV analytics
```

**MySQL Table: `customer`**
```sql
SELECT customer_id, first_name, last_name, email
FROM mysql.sakila.customer
LIMIT 3;

┌─────────────┬────────────┬───────────┬──────────────────────────┐
│ customer_id │ first_name │ last_name │         email            │
├─────────────┼────────────┼───────────┼──────────────────────────┤
│           1 │ MARY       │ SMITH     │ mary.smith@sakilacust... │
│           2 │ PATRICIA   │ JOHNSON   │ patricia.johnson@saki... │
│           3 │ LINDA      │ WILLIAMS  │ linda.williams@sakila... │
└─────────────┴────────────┴───────────┴──────────────────────────┘
```

**CSV File: `/data/customer_ltv.csv`**
```csv
customer_id,lifetime_value,churn_probability,segment
1,2500.00,0.15,High Value
2,1800.00,0.25,Medium Value
3,950.00,0.45,At Risk
4,3200.00,0.10,VIP
5,1200.00,0.30,Medium Value
```

**Federated Query (MySQL + CSV):**
```sql
-- Join MySQL customer table with CSV analytics file
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    ltv.lifetime_value,
    ltv.churn_probability,
    ltv.segment
FROM mysql.sakila.customer c
JOIN dfs.`/data/customer_ltv.csv` ltv 
    ON c.customer_id = ltv.customer_id
WHERE ltv.segment = 'High Value'
ORDER BY ltv.lifetime_value DESC;

-- Output:
┌─────────────┬────────────┬───────────┬─────────────────┬────────────────┬──────────────────┬────────────┐
│ customer_id │ first_name │ last_name │      email      │ lifetime_value │ churn_probability│  segment   │
├─────────────┼────────────┼───────────┼─────────────────┼────────────────┼──────────────────┼────────────┤
│           1 │ MARY       │ SMITH     │ mary.smith@...  │        2500.00 │             0.15 │ High Value │
└─────────────┴────────────┴───────────┴─────────────────┴────────────────┴──────────────────┴────────────┘

-- This query:
-- ✓ Reads from MySQL database
-- ✓ Reads from CSV file
-- ✓ Joins in Drill (federated)
-- ✓ No data duplication!
```

### Multi-Source Join: MySQL + JSON

**JSON File: `/data/customer_events.json`**
```json
{"customer_id": 1, "event_type": "login", "event_date": "2024-01-15", "page_views": 25}
{"customer_id": 1, "event_type": "purchase", "event_date": "2024-01-16", "page_views": 5}
{"customer_id": 2, "event_type": "login", "event_date": "2024-01-15", "page_views": 12}
{"customer_id": 3, "event_type": "login", "event_date": "2024-01-17", "page_views": 8}
```

**Query:**
```sql
-- Join MySQL customer with JSON events
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    e.event_type,
    e.event_date,
    e.page_views
FROM mysql.sakila.customer c
JOIN dfs.`/data/customer_events.json` e 
    ON c.customer_id = e.customer_id
WHERE e.event_type = 'purchase'
ORDER BY e.event_date DESC;

-- Aggregate events per customer
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(e.event_type) AS event_count,
    SUM(e.page_views) AS total_page_views
FROM mysql.sakila.customer c
LEFT JOIN dfs.`/data/customer_events.json` e 
    ON c.customer_id = e.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_page_views DESC
LIMIT 10;
```

### Three-Way Join: MySQL + CSV + Parquet

**Scenario:**
```
MySQL:   Customer master data
CSV:     Customer lifetime value
Parquet: Recent purchase history
```

**Query:**
```sql
-- Join three sources
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    ltv.lifetime_value,
    ltv.segment,
    p.recent_purchases,
    p.last_purchase_date
FROM mysql.sakila.customer c
JOIN dfs.`/data/customer_ltv.csv` ltv 
    ON c.customer_id = ltv.customer_id
JOIN dfs.`/data/recent_purchases.parquet` p 
    ON c.customer_id = p.customer_id
WHERE ltv.segment = 'VIP'
  AND p.recent_purchases > 5
ORDER BY p.last_purchase_date DESC;

-- This query combines:
-- 1. MySQL (transactional data)
-- 2. CSV (analytics data)
-- 3. Parquet (big data/logs)
-- All in ONE query!
```

---

## Part 4: Query Optimization

### Pushdown Optimization

**Query Pushdown = Execute filters in source system (not Drill)**

**Example:**
```sql
-- This query:
SELECT first_name, last_name
FROM mysql.sakila.actor
WHERE last_name = 'GUINESS';

-- Drill optimizes to:
-- 1. Push WHERE clause to MySQL
-- 2. MySQL executes: SELECT ... WHERE last_name = 'GUINESS'
-- 3. MySQL returns only matching rows (not all rows!)
-- 4. Drill receives minimal data

-- Without pushdown:
-- 1. MySQL returns ALL rows
-- 2. Drill filters in-memory
-- 3. Network transfers entire table (slow!)
```

**Check Query Plan:**
```sql
-- View execution plan
EXPLAIN PLAN FOR
SELECT first_name, last_name
FROM mysql.sakila.actor
WHERE last_name = 'GUINESS';

-- Look for:
-- "JdbcPrel" with "filters=[[=($1, 'GUINESS')]]"
-- This confirms pushdown!
```

### Join Optimization

**Small Table to Big Table:**
```sql
-- Good: MySQL (small) JOIN File (big)
SELECT *
FROM mysql.sakila.customer c      -- 599 customers (small)
JOIN dfs.`/data/events.parquet` e  -- 10M events (big)
    ON c.customer_id = e.customer_id;

-- Drill:
-- 1. Reads small MySQL table fully (fast)
-- 2. Uses hash join with big Parquet file
-- 3. Efficient execution

-- Bad: File (big) JOIN MySQL (small) with wrong order
-- Drill may choose broadcast join (less efficient)
```

**Filter Before Join:**
```sql
-- Good: Filter early
SELECT *
FROM mysql.sakila.customer c
JOIN dfs.`/data/events.parquet` e 
    ON c.customer_id = e.customer_id
WHERE e.event_date >= '2024-01-01'  -- Filter pushed to Parquet
  AND c.active = 1;                 -- Filter pushed to MySQL

-- Bad: Filter after join
SELECT *
FROM (
    SELECT * FROM mysql.sakila.customer c
    JOIN dfs.`/data/events.parquet` e 
        ON c.customer_id = e.customer_id
) subquery
WHERE event_date >= '2024-01-01';  -- Filter too late!
```

### Use Indexes in MySQL

```sql
-- Ensure MySQL tables have indexes on join columns
-- Run in MySQL:
CREATE INDEX idx_customer_id ON payment(customer_id);
CREATE INDEX idx_date ON payment(payment_date);

-- Drill queries benefit from MySQL indexes via pushdown
SELECT *
FROM mysql.sakila.payment
WHERE customer_id = 123;  -- Uses MySQL index (fast!)
```

### Limit Data Transfer

```sql
-- Bad: Select all columns
SELECT *
FROM mysql.sakila.film f
JOIN dfs.`/data/ratings.csv` r ON f.film_id = r.film_id;

-- Good: Select only needed columns
SELECT 
    f.film_id,
    f.title,
    r.rating,
    r.review_count
FROM mysql.sakila.film f
JOIN dfs.`/data/ratings.csv` r ON f.film_id = r.film_id;

-- Reduces:
-- - Network data transfer
-- - Memory usage
-- - Processing time
```

---

## Part 5: Real-World Use Cases

### Use Case 1: Legacy System Integration

**Problem:**
```
Old System:    MySQL database (can't modify)
New System:    Data lake (Parquet files in S3)
Requirement:   Unified reporting without ETL
```

**Solution:**
```sql
-- Query legacy MySQL + modern data lake
SELECT 
    legacy.customer_id,
    legacy.customer_name,
    legacy.account_number,
    datalake.total_orders_2024,
    datalake.lifetime_value,
    datalake.predicted_churn
FROM mysql.legacy_system.customers legacy
LEFT JOIN dfs.`s3://datalake/customer_analytics/*.parquet` datalake
    ON legacy.customer_id = datalake.customer_id
WHERE datalake.predicted_churn > 0.7;

-- Benefits:
-- ✓ No data migration from MySQL
-- ✓ No ETL pipeline maintenance
-- ✓ Instant insights
-- ✓ MySQL remains unchanged
```

### Use Case 2: Ad-Hoc Analytics

**Problem:**
```
Data Team:     Needs quick analysis combining multiple sources
MySQL:         Customer, orders, products
CSV Files:     Marketing campaign data
JSON Files:    Web analytics
```

**Solution:**
```sql
-- Campaign effectiveness analysis
SELECT 
    c.campaign_name,
    c.start_date,
    c.budget,
    COUNT(DISTINCT o.customer_id) AS customers_acquired,
    SUM(o.total_amount) AS revenue_generated,
    SUM(o.total_amount) / c.budget AS roi
FROM dfs.`/data/campaigns.csv` c
LEFT JOIN dfs.`/data/web_events.json` e 
    ON c.campaign_id = e.campaign_id
LEFT JOIN mysql.production.orders o 
    ON e.customer_id = o.customer_id
WHERE o.order_date BETWEEN c.start_date AND c.end_date
GROUP BY c.campaign_name, c.start_date, c.budget
ORDER BY roi DESC;

-- No ETL needed for one-time analysis!
```

### Use Case 3: Data Migration Planning

**Problem:**
```
Migrate from MySQL to Cloud Data Warehouse
Need to validate data before migration
```

**Solution:**
```sql
-- Compare MySQL source with Parquet staging
SELECT 
    'Row Count Difference' AS check_name,
    (SELECT COUNT(*) FROM mysql.old_db.customers) AS mysql_count,
    (SELECT COUNT(*) FROM dfs.`/staging/customers.parquet`) AS parquet_count,
    ABS((SELECT COUNT(*) FROM mysql.old_db.customers) - 
        (SELECT COUNT(*) FROM dfs.`/staging/customers.parquet`)) AS difference;

-- Identify missing records
SELECT m.customer_id
FROM mysql.old_db.customers m
LEFT JOIN dfs.`/staging/customers.parquet` p 
    ON m.customer_id = p.customer_id
WHERE p.customer_id IS NULL;

-- Validate data integrity
SELECT 
    m.customer_id,
    m.total_orders AS mysql_total,
    p.total_orders AS parquet_total
FROM mysql.old_db.customer_summary m
JOIN dfs.`/staging/customer_summary.parquet` p 
    ON m.customer_id = p.customer_id
WHERE m.total_orders != p.total_orders;
```

---

## Part 6: Best Practices

### Connection Management

```
✓ Use dedicated MySQL user for Drill (read-only)
✓ Limit permissions (SELECT only on needed tables)
✓ Use connection pooling (JDBC pool settings)
✓ Monitor active connections
✗ Don't use root/admin accounts
✗ Don't grant write permissions
```

### Query Performance

```
✓ Filter early (WHERE clauses pushed down)
✓ Select only needed columns
✓ Use MySQL indexes on join columns
✓ Partition file-based data
✓ Use Parquet instead of CSV for large files
✗ Don't SELECT *
✗ Don't filter after joins
✗ Don't query unindexed columns in WHERE
```

### Security

```
✓ Encrypt MySQL connections (SSL/TLS)
✓ Rotate passwords regularly
✓ Audit Drill query logs
✓ Restrict network access
✗ Don't store passwords in plain text
✗ Don't expose Drill Web UI publicly
```

---

## Key Takeaways

### Configuration
```
1. Add MySQL JDBC driver to Drill
2. Create JDBC storage plugin
3. Configure connection string, credentials
4. Test with SHOW TABLES
```

### Querying
```
-- MySQL table syntax:
mysql.[database].[table]

-- Join with files:
SELECT ... FROM mysql.db.table m
JOIN dfs.`/path/file.csv` f ON m.id = f.id
```

### Optimization
```
✓ Query pushdown (filters to MySQL)
✓ Index usage (via pushdown)
✓ Select minimal columns
✓ Filter before joining
```

### Use Cases
```
✓ Legacy system integration
✓ Federated analytics
✓ Ad-hoc reporting
✓ Data migration validation
```

---

## Next Steps

**Continue to Lesson 18.4: Querying MongoDB with Drill**  
Learn to query NoSQL document databases with SQL using Apache Drill.

---

## Practice Exercises

**Exercise 1:** Configure MySQL plugin and query a sample database.

**Exercise 2:** Join MySQL customer table with CSV file containing additional attributes.

**Exercise 3:** Write federated query combining MySQL + JSON + Parquet data.

**Exercise 4:** Use EXPLAIN PLAN to verify query pushdown to MySQL.
