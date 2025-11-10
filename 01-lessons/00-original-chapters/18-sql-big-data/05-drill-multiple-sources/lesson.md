# Lesson 18.5: Querying Multiple Sources with Drill

## Learning Objectives

By the end of this lesson, you will be able to:
1. Join data from three or more heterogeneous sources
2. Design federated query architectures
3. Optimize cross-source query performance
4. Apply federated patterns to real-world scenarios
5. Understand when to use federated queries vs ETL

## Business Context

**Modern enterprises have data everywhere**: legacy MySQL databases, MongoDB applications, CSV exports, Parquet data lakes, JSON logs. Apache Drill's **federated query capability** eliminates data silos by joining all sources in a single SQL query—**no ETL required**.

**Time:** 60 minutes  
**Level:** Advanced

---

## Part 1: Two-Source Joins

### CSV + MySQL

**Business Scenario:**
```
MySQL Database:   Customer master data (OLTP)
CSV File:         Customer segmentation (data science output)
Goal:             Enrich master data with ML predictions
```

**MySQL Table: `customers`**
```sql
SELECT customer_id, name, email, signup_date
FROM mysql.crm.customers
LIMIT 3;

┌─────────────┬────────────┬──────────────────┬─────────────┐
│ customer_id │    name    │      email       │ signup_date │
├─────────────┼────────────┼──────────────────┼─────────────┤
│        1001 │ John Doe   │ john@example.com │  2023-01-15 │
│        1002 │ Jane Smith │ jane@example.com │  2023-02-20 │
│        1003 │ Bob John.  │ bob@example.com  │  2023-03-10 │
└─────────────┴────────────┴──────────────────┴─────────────┘
```

**CSV File: `/data/customer_segments.csv`**
```csv
customer_id,segment,churn_probability,lifetime_value_prediction
1001,High Value,0.15,5200.00
1002,Medium Value,0.35,2800.00
1003,At Risk,0.75,950.00
```

**Federated Query:**
```sql
-- Join MySQL + CSV
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.signup_date,
    seg.segment,
    seg.churn_probability,
    seg.lifetime_value_prediction
FROM mysql.crm.customers c
JOIN dfs.`/data/customer_segments.csv` seg 
    ON c.customer_id = seg.customer_id
WHERE seg.segment = 'High Value'
ORDER BY seg.lifetime_value_prediction DESC;

-- Output:
┌─────────────┬──────────┬──────────────────┬─────────────┬────────────┬──────────────────┬─────────────────────────┐
│ customer_id │   name   │      email       │ signup_date │  segment   │ churn_probability│ lifetime_value_prediction│
├─────────────┼──────────┼──────────────────┼─────────────┼────────────┼──────────────────┼─────────────────────────┤
│        1001 │ John Doe │ john@example.com │  2023-01-15 │ High Value │             0.15 │                  5200.00│
└─────────────┴──────────┴──────────────────┴─────────────┴────────────┴──────────────────┴─────────────────────────┘
```

### JSON + MongoDB

**Business Scenario:**
```
MongoDB:      User profiles (application database)
JSON Logs:    User activity logs (web server)
Goal:         Correlate user attributes with behavior
```

**MongoDB Collection: `users`**
```json
{
  "user_id": 5001,
  "username": "johndoe",
  "email": "john@example.com",
  "plan": "premium",
  "signup_date": "2023-06-15"
}
```

**JSON File: `/data/activity_logs.json`**
```json
{"user_id": 5001, "action": "login", "timestamp": "2024-01-15T10:23:45Z", "page_views": 12}
{"user_id": 5001, "action": "purchase", "timestamp": "2024-01-15T11:05:20Z", "amount": 99.99}
{"user_id": 5002, "action": "login", "timestamp": "2024-01-15T14:12:30Z", "page_views": 5}
```

**Federated Query:**
```sql
-- Join MongoDB users with JSON activity logs
SELECT 
    u.user_id,
    u.username,
    u.plan,
    logs.action,
    logs.timestamp,
    logs.page_views,
    logs.amount
FROM mongo.app.users u
JOIN dfs.`/data/activity_logs.json` logs 
    ON u.user_id = logs.user_id
WHERE u.plan = 'premium'
  AND logs.action = 'purchase'
ORDER BY logs.timestamp DESC;

-- Identifies premium users making purchases
```

### MySQL + Parquet

**Business Scenario:**
```
MySQL:    Product catalog (transactional system)
Parquet:  Sales data (data lake)
Goal:     Product performance analysis
```

**Query:**
```sql
-- Join MySQL products with Parquet sales
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(s.sale_id) AS total_sales,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.sale_amount) AS total_revenue
FROM mysql.inventory.products p
LEFT JOIN dfs.`/datalake/sales/**/*.parquet` s 
    ON p.product_id = s.product_id
WHERE s.sale_date >= '2024-01-01'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 20;

-- Combines:
-- ✓ MySQL product details
-- ✓ Parquet sales transactions (data lake)
-- ✓ No data movement!
```

---

## Part 2: Three-Way Joins

### CSV + MySQL + MongoDB

**Business Scenario:**
```
CSV:       Customer demographics (imported data)
MySQL:     Order transactions (OLTP)
MongoDB:   Product reviews (NoSQL app)
Goal:      Customer 360 view
```

**CSV File: `/data/demographics.csv`**
```csv
customer_id,age,income_bracket,location
1001,35,75000-100000,Urban
1002,28,50000-75000,Suburban
1003,42,100000+,Urban
```

**MySQL Table: `orders`**
```sql
SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS total_spent
FROM mysql.sales.orders
GROUP BY customer_id;
```

**MongoDB Collection: `reviews`**
```json
{"customer_id": 1001, "product_id": 201, "rating": 5, "review_text": "Excellent product!"}
{"customer_id": 1001, "product_id": 202, "rating": 4, "review_text": "Good value"}
{"customer_id": 1002, "product_id": 201, "rating": 3, "review_text": "Average"}
```

**Three-Way Federated Query:**
```sql
-- Customer 360: demographics + transactions + sentiment
SELECT 
    demo.customer_id,
    demo.age,
    demo.income_bracket,
    demo.location,
    COALESCE(orders.order_count, 0) AS order_count,
    COALESCE(orders.total_spent, 0.00) AS total_spent,
    COALESCE(reviews.review_count, 0) AS review_count,
    COALESCE(reviews.avg_rating, 0.0) AS avg_rating
FROM dfs.`/data/demographics.csv` demo
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(total) AS total_spent
    FROM mysql.sales.orders
    GROUP BY customer_id
) orders ON demo.customer_id = orders.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) AS review_count,
        AVG(rating) AS avg_rating
    FROM mongo.app.reviews
    GROUP BY customer_id
) reviews ON demo.customer_id = reviews.customer_id
ORDER BY total_spent DESC;

-- Output: Complete customer profile from 3 sources!
┌─────────────┬─────┬────────────────┬──────────┬─────────────┬─────────────┬──────────────┬────────────┐
│ customer_id │ age │ income_bracket │ location │ order_count │ total_spent │ review_count │ avg_rating │
├─────────────┼─────┼────────────────┼──────────┼─────────────┼─────────────┼──────────────┼────────────┤
│        1001 │  35 │ 75000-100000   │ Urban    │          12 │     2450.00 │            2 │        4.5 │
│        1002 │  28 │ 50000-75000    │ Suburban │           5 │      850.00 │            1 │        3.0 │
│        1003 │  42 │ 100000+        │ Urban    │           0 │        0.00 │            0 │        0.0 │
└─────────────┴─────┴────────────────┴──────────┴─────────────┴─────────────┴──────────────┴────────────┘
```

### Files + MySQL + MongoDB (Real-World)

**E-Commerce Platform Architecture:**
```
┌──────────────────────────────────────────────────────┐
│              Apache Drill (Federated Layer)           │
└───────┬──────────────┬──────────────┬────────────────┘
        │              │              │
        ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌──────────────┐
│   MySQL     │ │  MongoDB    │ │ S3/Parquet   │
│ (Orders)    │ │ (Users)     │ │ (Clickstream)│
└─────────────┘ └─────────────┘ └──────────────┘
```

**MySQL: Order Transactions**
```sql
-- Orders table
SELECT order_id, user_id, total_amount, order_date
FROM mysql.ecommerce.orders;
```

**MongoDB: User Profiles**
```json
{
  "user_id": 5001,
  "name": "John Doe",
  "preferences": {
    "categories": ["Electronics", "Books"],
    "notifications": true
  },
  "loyalty_tier": "Gold"
}
```

**Parquet: Web Clickstream**
```
Files: s3://logs/clickstream/year=2024/month=01/*.parquet
Columns: user_id, session_id, page_url, timestamp, duration_seconds
```

**Federated Analytics Query:**
```sql
-- Customer journey analysis: clicks → profile → purchase
SELECT 
    u.user_id,
    u.name,
    u.loyalty_tier,
    click_data.total_sessions,
    click_data.total_page_views,
    click_data.avg_session_duration,
    order_data.order_count,
    order_data.total_spent,
    ROUND(order_data.total_spent / NULLIF(click_data.total_sessions, 0), 2) AS revenue_per_session
FROM mongo.ecommerce.users u
LEFT JOIN (
    -- Aggregate clickstream from Parquet
    SELECT 
        user_id,
        COUNT(DISTINCT session_id) AS total_sessions,
        COUNT(*) AS total_page_views,
        AVG(duration_seconds) AS avg_session_duration
    FROM dfs.`s3://logs/clickstream/year=2024/**/*.parquet`
    WHERE timestamp >= '2024-01-01'
    GROUP BY user_id
) click_data ON u.user_id = click_data.user_id
LEFT JOIN (
    -- Aggregate orders from MySQL
    SELECT 
        user_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM mysql.ecommerce.orders
    WHERE order_date >= '2024-01-01'
    GROUP BY user_id
) order_data ON u.user_id = order_data.user_id
WHERE u.loyalty_tier IN ('Gold', 'Platinum')
ORDER BY revenue_per_session DESC
LIMIT 100;

-- This query combines:
-- ✓ MongoDB user profiles (flexible schema)
-- ✓ Parquet clickstream logs (big data)
-- ✓ MySQL transactional orders (OLTP)
-- All in ONE federated query!
```

---

## Part 3: Four+ Source Joins

### Complex Federated Architecture

**Business Scenario: Financial Services**
```
Data Sources:
1. MySQL:     Account transactions (OLTP)
2. MongoDB:   Customer profiles (application DB)
3. Parquet:   Market data feed (data lake)
4. CSV:       Regulatory compliance data (imported)
5. JSON:      Fraud detection alerts (ML pipeline output)
```

**Federated Query:**
```sql
-- Comprehensive risk analysis
SELECT 
    cust.customer_id,
    cust.name,
    cust.risk_profile,
    acct.account_count,
    acct.total_balance,
    market.portfolio_value,
    market.ytd_return_pct,
    compliance.kyc_status,
    compliance.last_review_date,
    fraud.alert_count,
    fraud.risk_score
FROM mongo.banking.customers cust
LEFT JOIN (
    -- Account summary from MySQL
    SELECT 
        customer_id,
        COUNT(DISTINCT account_id) AS account_count,
        SUM(balance) AS total_balance
    FROM mysql.banking.accounts
    GROUP BY customer_id
) acct ON cust.customer_id = acct.customer_id
LEFT JOIN (
    -- Portfolio performance from Parquet
    SELECT 
        customer_id,
        SUM(current_value) AS portfolio_value,
        AVG(ytd_return_pct) AS ytd_return_pct
    FROM dfs.`/datalake/market_data/**/*.parquet`
    WHERE as_of_date = CURRENT_DATE
    GROUP BY customer_id
) market ON cust.customer_id = market.customer_id
LEFT JOIN dfs.`/data/compliance.csv` compliance 
    ON cust.customer_id = compliance.customer_id
LEFT JOIN (
    -- Fraud alerts from JSON
    SELECT 
        customer_id,
        COUNT(*) AS alert_count,
        MAX(risk_score) AS risk_score
    FROM dfs.`/ml_output/fraud_alerts.json`
    WHERE alert_date >= CURRENT_DATE - INTERVAL '30' DAY
    GROUP BY customer_id
) fraud ON cust.customer_id = fraud.customer_id
WHERE cust.risk_profile = 'High Net Worth'
  AND (fraud.risk_score > 70 OR compliance.kyc_status != 'Current')
ORDER BY fraud.risk_score DESC, acct.total_balance DESC;

-- 5 data sources joined for comprehensive risk view!
```

---

## Part 4: Performance Optimization

### Optimization Strategy 1: Filter Early

```sql
-- Bad: Filter after joining (processes all data)
SELECT *
FROM (
    SELECT *
    FROM mysql.sales.orders o
    JOIN dfs.`/data/customers.csv` c ON o.customer_id = c.customer_id
    JOIN mongo.app.products p ON o.product_id = p.product_id
) subquery
WHERE order_date >= '2024-01-01';

-- Good: Filter in each source (minimal data transfer)
SELECT *
FROM (
    SELECT * FROM mysql.sales.orders WHERE order_date >= '2024-01-01'
) o
JOIN dfs.`/data/customers.csv` c ON o.customer_id = c.customer_id
JOIN mongo.app.products p ON o.product_id = p.product_id;
```

### Optimization Strategy 2: Select Minimal Columns

```sql
-- Bad: SELECT * (transfers all columns)
SELECT *
FROM mysql.large_table m
JOIN dfs.`/data/big_file.parquet` p ON m.id = p.id;

-- Good: Select only needed columns
SELECT 
    m.id,
    m.name,
    p.metric_value,
    p.timestamp
FROM mysql.large_table m
JOIN dfs.`/data/big_file.parquet` p ON m.id = p.id;
```

### Optimization Strategy 3: Use Partitioning

```sql
-- Parquet partitioned by date
-- Directory: /datalake/sales/year=2024/month=01/*.parquet

-- Good: Partition pruning (reads only Jan 2024)
SELECT *
FROM mysql.products p
JOIN dfs.`/datalake/sales/year=2024/month=01/*.parquet` s 
    ON p.product_id = s.product_id;

-- Bad: No partition filter (reads all partitions)
SELECT *
FROM mysql.products p
JOIN dfs.`/datalake/sales/**/*.parquet` s 
    ON p.product_id = s.product_id;
```

### Optimization Strategy 4: Pre-Aggregate Before Joining

```sql
-- Good: Aggregate first, then join (smaller datasets)
SELECT 
    p.product_name,
    sales_summary.total_sales,
    reviews_summary.avg_rating
FROM mysql.products p
JOIN (
    SELECT 
        product_id,
        SUM(amount) AS total_sales
    FROM dfs.`/data/sales.parquet`
    GROUP BY product_id
) sales_summary ON p.product_id = sales_summary.product_id
JOIN (
    SELECT 
        product_id,
        AVG(rating) AS avg_rating
    FROM mongo.app.reviews
    GROUP BY product_id
) reviews_summary ON p.product_id = reviews_summary.product_id;

-- Bad: Join first, aggregate later (larger intermediate results)
SELECT 
    p.product_name,
    SUM(s.amount) AS total_sales,
    AVG(r.rating) AS avg_rating
FROM mysql.products p
JOIN dfs.`/data/sales.parquet` s ON p.product_id = s.product_id
JOIN mongo.app.reviews r ON p.product_id = r.product_id
GROUP BY p.product_name;
```

### Optimization Strategy 5: Use Query Profiling

```sql
-- Enable query profiling
ALTER SESSION SET `planner.enable_profile` = true;

-- Run query
SELECT ...;

-- View profile in Drill Web UI
-- http://localhost:8047 → Profiles
-- Analyze:
-- - Execution time per operator
-- - Data scanned per source
-- - Memory usage
-- - Identify bottlenecks
```

---

## Part 5: Real-World Case Study

### Scenario: E-Commerce Analytics Platform

**Business Requirement:**
```
Combine data from multiple systems to build comprehensive analytics dashboard
No ETL (real-time access needed)
Support for data science team
```

**Architecture:**
```
┌─────────────────────────────────────────────────────┐
│        Apache Drill (Federated SQL Layer)           │
│            (Queries run on-demand)                   │
└────────┬──────────┬──────────┬──────────────────────┘
         │          │          │
         ▼          ▼          ▼
    ┌────────┐ ┌────────┐ ┌──────────────┐
    │ MySQL  │ │ MongoDB│ │ S3 Data Lake │
    │(Orders)│ │(Users) │ │  (Logs)      │
    └────────┘ └────────┘ └──────────────┘
```

**Data Sources:**

**1. MySQL: Transactional Orders**
```sql
-- Table: orders
-- Columns: order_id, user_id, product_id, quantity, amount, order_date, status
```

**2. MongoDB: User Profiles**
```json
{
  "user_id": 5001,
  "name": "John Doe",
  "email": "john@example.com",
  "segment": "High Value",
  "preferences": {...}
}
```

**3. S3 Parquet: Web Clickstream**
```
Path: s3://logs/clickstream/year=2024/month=01/*.parquet
Columns: user_id, session_id, page_url, event_type, timestamp
```

**4. CSV: Product Catalog Updates**
```csv
product_id,category,new_price,effective_date
101,Electronics,299.99,2024-01-15
102,Books,19.99,2024-01-20
```

**Key Analytics Queries:**

**Query 1: Customer Lifetime Value**
```sql
SELECT 
    u.user_id,
    u.name,
    u.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.amount) AS lifetime_value,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS days_since_last_order
FROM mongo.ecommerce.users u
LEFT JOIN mysql.ecommerce.orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.name, u.segment
ORDER BY lifetime_value DESC
LIMIT 100;
```

**Query 2: Conversion Funnel**
```sql
SELECT 
    clicks.date,
    clicks.unique_visitors,
    orders.unique_buyers,
    orders.total_orders,
    ROUND(orders.unique_buyers * 100.0 / clicks.unique_visitors, 2) AS conversion_rate
FROM (
    SELECT 
        CAST(timestamp AS DATE) AS date,
        COUNT(DISTINCT user_id) AS unique_visitors
    FROM dfs.`s3://logs/clickstream/**/*.parquet`
    GROUP BY CAST(timestamp AS DATE)
) clicks
LEFT JOIN (
    SELECT 
        CAST(order_date AS DATE) AS date,
        COUNT(DISTINCT user_id) AS unique_buyers,
        COUNT(*) AS total_orders
    FROM mysql.ecommerce.orders
    WHERE status = 'completed'
    GROUP BY CAST(order_date AS DATE)
) orders ON clicks.date = orders.date
ORDER BY clicks.date DESC;
```

**Query 3: Product Performance**
```sql
SELECT 
    p.product_id,
    p.category,
    p.new_price AS current_price,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(o.quantity) AS units_sold,
    SUM(o.amount) AS revenue,
    COUNT(DISTINCT o.user_id) AS unique_customers
FROM dfs.`/data/products.csv` p
LEFT JOIN mysql.ecommerce.orders o ON p.product_id = o.product_id
WHERE o.order_date >= p.effective_date
GROUP BY p.product_id, p.category, p.new_price
ORDER BY revenue DESC
LIMIT 50;
```

**Query 4: User Segmentation with Behavior**
```sql
SELECT 
    u.segment,
    COUNT(DISTINCT u.user_id) AS user_count,
    AVG(order_metrics.order_count) AS avg_orders_per_user,
    AVG(order_metrics.avg_order_value) AS avg_order_value,
    AVG(click_metrics.sessions) AS avg_sessions,
    AVG(click_metrics.page_views) AS avg_page_views
FROM mongo.ecommerce.users u
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) AS order_count,
        AVG(amount) AS avg_order_value
    FROM mysql.ecommerce.orders
    GROUP BY user_id
) order_metrics ON u.user_id = order_metrics.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(DISTINCT session_id) AS sessions,
        COUNT(*) AS page_views
    FROM dfs.`s3://logs/clickstream/**/*.parquet`
    GROUP BY user_id
) click_metrics ON u.user_id = click_metrics.user_id
GROUP BY u.segment
ORDER BY user_count DESC;
```

---

## Part 6: Federated Queries vs ETL

### When to Use Federated Queries

```
✓ Ad-hoc analysis (one-time or irregular)
✓ Rapidly changing schemas
✓ Real-time/near-real-time access needed
✓ Low data volume (< 10 TB)
✓ Exploratory data analysis
✓ Prototyping analytics
✓ No infrastructure for ETL
```

### When to Use ETL

```
✓ High-frequency queries (thousands/day)
✓ Complex transformations needed
✓ Performance critical (sub-second)
✓ Large data volumes (> 10 TB)
✓ Production dashboards
✓ Data quality enforcement
✓ Historical snapshots needed
```

### Hybrid Approach (Best of Both)

```
1. Explore with Drill (federated)
2. Identify valuable queries
3. Build ETL for high-value workloads
4. Keep Drill for ad-hoc analysis

Example:
- Daily executive dashboard → ETL to warehouse
- Data science exploration → Drill federated queries
```

---

## Key Takeaways

### Federated Query Capabilities
```
✓ Join 2, 3, 4+ data sources
✓ Files + RDBMS + NoSQL in one query
✓ No data movement required
✓ Real-time access to source data
```

### Supported Combinations
```
✓ CSV + MySQL + MongoDB
✓ JSON + Parquet + PostgreSQL
✓ MongoDB + MySQL + S3 files
✓ Any combination of storage plugins
```

### Performance Optimization
```
1. Filter early (push to sources)
2. Select minimal columns
3. Use partitioning
4. Pre-aggregate before joining
5. Monitor with query profiles
```

### Use Cases
```
✓ Customer 360 views
✓ Legacy system integration
✓ Real-time analytics
✓ Data migration validation
✓ Ad-hoc cross-source analysis
```

---

## Next Steps

**Continue to Lesson 18.6: The Future of SQL**  
Explore emerging SQL technologies, lakehouse architectures, and the evolution of SQL in big data.

---

## Practice Exercises

**Exercise 1:** Join MySQL orders + CSV customers + MongoDB products in a single query.

**Exercise 2:** Build customer 360 view combining data from 3+ sources.

**Exercise 3:** Optimize slow federated query using profiling and best practices.

**Exercise 4:** Compare federated query performance vs ETL approach for your use case.
