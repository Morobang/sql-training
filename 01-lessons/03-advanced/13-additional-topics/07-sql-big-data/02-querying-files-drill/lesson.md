# Lesson 18.2: Querying Files with Drill

## Learning Objectives

By the end of this lesson, you will be able to:
1. Query CSV files with Apache Drill
2. Query JSON files including nested structures
3. Query Parquet files efficiently
4. Handle complex data types (arrays, nested objects)
5. Apply file querying to real-world scenarios

## Business Context

**80% of enterprise data** lives in files (CSV, JSON, logs, Parquet). Apache Drill lets you query these files directly with SQL—no database loading required. This eliminates ETL delays and enables instant data access.

**Time:** 50 minutes  
**Level:** Advanced

---

## Part 1: Querying CSV Files

### Basic CSV Query

**Sample File: `customers.csv`**
```csv
customer_id,name,email,city,state,signup_date,lifetime_value
1001,John Doe,john@example.com,Seattle,WA,2023-01-15,2500.00
1002,Jane Smith,jane@example.com,Portland,OR,2023-02-20,1800.00
1003,Bob Johnson,bob@example.com,San Francisco,CA,2023-03-10,3200.00
1004,Alice Williams,alice@example.com,Seattle,WA,2023-04-05,1500.00
1005,Charlie Brown,charlie@example.com,Los Angeles,CA,2023-05-12,2100.00
```

**Query:**
```sql
-- View all data
SELECT * FROM dfs.`/data/customers.csv`;

-- Drill automatically:
-- ✓ Detects header row
-- ✓ Infers data types
-- ✓ Maps column names

-- Output:
┌─────────────┬────────────────┬────────────────────┬──────────────┬───────┬─────────────┬────────────────┐
│ customer_id │      name      │       email        │     city     │ state │ signup_date │ lifetime_value │
├─────────────┼────────────────┼────────────────────┼──────────────┼───────┼─────────────┼────────────────┤
│        1001 │ John Doe       │ john@example.com   │ Seattle      │ WA    │ 2023-01-15  │        2500.00 │
│        1002 │ Jane Smith     │ jane@example.com   │ Portland     │ OR    │ 2023-02-20  │        1800.00 │
│        1003 │ Bob Johnson    │ bob@example.com    │ San Fran...  │ CA    │ 2023-03-10  │        3200.00 │
│        1004 │ Alice Williams │ alice@example.com  │ Seattle      │ WA    │ 2023-04-05  │        1500.00 │
│        1005 │ Charlie Brown  │ charlie@example.com│ Los Angeles  │ CA    │ 2023-05-12  │        2100.00 │
└─────────────┴────────────────┴────────────────────┴──────────────┴───────┴─────────────┴────────────────┘
```

### Filtering CSV Data

```sql
-- Filter by state
SELECT name, city, lifetime_value
FROM dfs.`/data/customers.csv`
WHERE state = 'WA';

-- Output:
┌────────────────┬─────────┬────────────────┐
│      name      │  city   │ lifetime_value │
├────────────────┼─────────┼────────────────┤
│ John Doe       │ Seattle │        2500.00 │
│ Alice Williams │ Seattle │        1500.00 │
└────────────────┴─────────┴────────────────┘

-- Filter by value range
SELECT name, lifetime_value
FROM dfs.`/data/customers.csv`
WHERE lifetime_value > 2000
ORDER BY lifetime_value DESC;

-- Output:
┌─────────────┬────────────────┐
│    name     │ lifetime_value │
├─────────────┼────────────────┤
│ Bob Johnson │        3200.00 │
│ John Doe    │        2500.00 │
│ Charlie Brn │        2100.00 │
└─────────────┴────────────────┘
```

### Aggregating CSV Data

```sql
-- Count customers by state
SELECT 
    state,
    COUNT(*) AS customer_count,
    SUM(lifetime_value) AS total_value,
    AVG(lifetime_value) AS avg_value
FROM dfs.`/data/customers.csv`
GROUP BY state
ORDER BY total_value DESC;

-- Output:
┌───────┬────────────────┬─────────────┬───────────┐
│ state │ customer_count │ total_value │ avg_value │
├───────┼────────────────┼─────────────┼───────────┤
│ CA    │              2 │     5300.00 │   2650.00 │
│ WA    │              2 │     4000.00 │   2000.00 │
│ OR    │              1 │     1800.00 │   1800.00 │
└───────┴────────────────┴─────────────┴───────────┘
```

### CSV Without Headers

**If CSV has no header row:**
```sql
-- Drill uses columns[0], columns[1], etc.
SELECT 
    columns[0] AS customer_id,
    columns[1] AS name,
    columns[2] AS email
FROM dfs.`/data/customers_no_header.csv`;
```

### CSV Configuration Options

```sql
-- Configure CSV format in storage plugin
{
  "type": "file",
  "connection": "file:///",
  "formats": {
    "csv": {
      "type": "text",
      "extensions": ["csv"],
      "delimiter": ",",
      "extractHeader": true,    -- Use first row as headers
      "skipFirstLine": false,   -- Don't skip first line (it's the header)
      "lineDelimiter": "\n"
    }
  }
}

-- For TSV (tab-separated):
"delimiter": "\t"

-- For pipe-delimited:
"delimiter": "|"
```

---

## Part 2: Querying JSON Files

### Simple JSON (One Object Per Line)

**Sample File: `orders.json` (JSONL format)**
```json
{"order_id": 1001, "customer_id": 5001, "product": "Widget A", "quantity": 2, "price": 29.99, "order_date": "2024-01-15"}
{"order_id": 1002, "customer_id": 5002, "product": "Widget B", "quantity": 1, "price": 49.99, "order_date": "2024-01-16"}
{"order_id": 1003, "customer_id": 5001, "product": "Widget C", "quantity": 3, "price": 19.99, "order_date": "2024-01-17"}
{"order_id": 1004, "customer_id": 5003, "product": "Widget A", "quantity": 1, "price": 29.99, "order_date": "2024-01-18"}
```

**Query:**
```sql
-- Query JSON file
SELECT * FROM dfs.`/data/orders.json`;

-- Filter
SELECT 
    order_id,
    product,
    quantity * price AS total_amount
FROM dfs.`/data/orders.json`
WHERE customer_id = 5001;

-- Output:
┌──────────┬──────────┬──────────────┐
│ order_id │ product  │ total_amount │
├──────────┼──────────┼──────────────┤
│     1001 │ Widget A │        59.98 │
│     1003 │ Widget C │        59.97 │
└──────────┴──────────┴──────────────┘
```

### Nested JSON Objects

**Sample File: `customers_nested.json`**
```json
{
  "customer_id": 5001,
  "name": "John Doe",
  "contact": {
    "email": "john@example.com",
    "phone": "206-555-0100",
    "address": {
      "street": "123 Main St",
      "city": "Seattle",
      "state": "WA",
      "zip": "98101"
    }
  },
  "account_status": "active"
}
```

**Query Nested Fields:**
```sql
-- Access nested object with dot notation
SELECT 
    customer_id,
    name,
    t.contact.email AS email,
    t.contact.phone AS phone,
    t.contact.address.city AS city,
    t.contact.address.state AS state
FROM dfs.`/data/customers_nested.json` t;

-- Output:
┌─────────────┬──────────┬───────────────────┬──────────────┬─────────┬───────┐
│ customer_id │   name   │       email       │    phone     │  city   │ state │
├─────────────┼──────────┼───────────────────┼──────────────┼─────────┼───────┤
│        5001 │ John Doe │ john@example.com  │ 206-555-0100 │ Seattle │ WA    │
└─────────────┴──────────┴───────────────────┴──────────────┴─────────┴───────┘
```

### JSON Arrays with FLATTEN

**Sample File: `orders_with_items.json`**
```json
{
  "order_id": 1001,
  "customer_id": 5001,
  "order_date": "2024-01-15",
  "items": [
    {"product": "Widget A", "quantity": 2, "price": 29.99},
    {"product": "Widget B", "quantity": 1, "price": 49.99}
  ],
  "total": 109.97
}
{
  "order_id": 1002,
  "customer_id": 5002,
  "order_date": "2024-01-16",
  "items": [
    {"product": "Widget C", "quantity": 3, "price": 19.99}
  ],
  "total": 59.97
}
```

**Flatten Array:**
```sql
-- FLATTEN converts array into rows
SELECT 
    t.order_id,
    t.order_date,
    item.product,
    item.quantity,
    item.price,
    item.quantity * item.price AS line_total
FROM dfs.`/data/orders_with_items.json` t,
LATERAL FLATTEN(t.items) AS item;

-- Output:
┌──────────┬────────────┬──────────┬──────────┬───────┬────────────┐
│ order_id │ order_date │ product  │ quantity │ price │ line_total │
├──────────┼────────────┼──────────┼──────────┼───────┼────────────┤
│     1001 │ 2024-01-15 │ Widget A │        2 │ 29.99 │      59.98 │
│     1001 │ 2024-01-15 │ Widget B │        1 │ 49.99 │      49.99 │
│     1002 │ 2024-01-16 │ Widget C │        3 │ 19.99 │      59.97 │
└──────────┴────────────┴──────────┴──────────┴───────┴────────────┘

-- Aggregate after flattening
SELECT 
    item.product,
    SUM(item.quantity) AS total_quantity,
    SUM(item.quantity * item.price) AS total_revenue
FROM dfs.`/data/orders_with_items.json` t,
LATERAL FLATTEN(t.items) AS item
GROUP BY item.product
ORDER BY total_revenue DESC;
```

### Complex Nested Example

**Sample File: `customer_profile.json`**
```json
{
  "customer_id": 5001,
  "name": "John Doe",
  "tags": ["premium", "frequent_buyer", "email_subscriber"],
  "orders": [
    {"order_id": 1001, "total": 109.97, "date": "2024-01-15"},
    {"order_id": 1003, "total": 59.97, "date": "2024-01-17"}
  ],
  "preferences": {
    "newsletter": true,
    "sms": false,
    "categories": ["electronics", "books"]
  }
}
```

**Query:**
```sql
-- Access array elements
SELECT 
    customer_id,
    name,
    t.tags[0] AS first_tag,
    t.preferences.newsletter AS newsletter_pref,
    t.preferences.categories[0] AS favorite_category
FROM dfs.`/data/customer_profile.json` t;

-- Flatten multiple arrays
SELECT 
    t.customer_id,
    t.name,
    order_detail.order_id,
    order_detail.total
FROM dfs.`/data/customer_profile.json` t,
LATERAL FLATTEN(t.orders) AS order_detail
WHERE order_detail.total > 100;
```

---

## Part 3: Querying Parquet Files

### What is Parquet?

**Parquet = Columnar storage format optimized for analytics**

```
Row-Based (CSV):
Row 1: [id=1, name=John, age=30, city=Seattle]
Row 2: [id=2, name=Jane, age=25, city=Portland]
Row 3: [id=3, name=Bob, age=35, city=Seattle]

Columnar (Parquet):
Column id:   [1, 2, 3]
Column name: [John, Jane, Bob]
Column age:  [30, 25, 35]
Column city: [Seattle, Portland, Seattle]
```

**Benefits:**
```
✓ 10x smaller than CSV (compression)
✓ 10-100x faster queries (columnar)
✓ Predicate pushdown (skip irrelevant data)
✓ Schema embedded in file
✓ Industry standard (Hadoop, Spark, Drill)
```

### Basic Parquet Query

```sql
-- Query Parquet file (same syntax as CSV/JSON!)
SELECT * FROM dfs.`/data/customers.parquet`;

-- Drill benefits from Parquet optimizations:
-- ✓ Only reads queried columns
-- ✓ Skips row groups based on filters
-- ✓ Uses embedded schema (no inference needed)

-- Filter query (very fast)
SELECT name, city, lifetime_value
FROM dfs.`/data/customers.parquet`
WHERE state = 'WA' 
  AND lifetime_value > 2000;

-- Drill only reads:
-- - 'name', 'city', 'lifetime_value', 'state' columns
-- - Row groups where state might be 'WA'
-- - Does NOT read entire file!
```

### Parquet Performance Example

```sql
-- Same query on different formats:

-- CSV (slow - must scan entire file):
SELECT COUNT(*) 
FROM dfs.`/data/orders.csv` 
WHERE order_date = '2024-01-15';
-- Time: 5.2 seconds for 10M rows

-- Parquet (fast - predicate pushdown):
SELECT COUNT(*) 
FROM dfs.`/data/orders.parquet` 
WHERE order_date = '2024-01-15';
-- Time: 0.3 seconds for 10M rows
-- 17x faster!
```

### Partitioned Parquet Files

**Directory Structure:**
```
/data/sales/
  year=2023/
    month=01/
      part-0001.parquet
      part-0002.parquet
    month=02/
      part-0001.parquet
  year=2024/
    month=01/
      part-0001.parquet
```

**Query with Partition Pruning:**
```sql
-- Query specific partition (extremely fast)
SELECT product, SUM(amount) AS total_sales
FROM dfs.`/data/sales/year=2024/month=01/*.parquet`
GROUP BY product;

-- Drill only reads January 2024 files!
-- Ignores all other partitions

-- Query across partitions with filter
SELECT 
    year,
    month,
    SUM(amount) AS total_sales
FROM dfs.`/data/sales/**/*.parquet`
WHERE year = 2024
GROUP BY year, month;

-- Partition pruning: Only reads 2024 directories
-- Skips 2023 entirely (never touches disk)
```

---

## Part 4: Querying Multiple Files

### Directory Queries

```sql
-- Query all CSV files in directory
SELECT * FROM dfs.`/data/customers/*.csv`;

-- Query all JSON files
SELECT * FROM dfs.`/data/logs/*.json`;

-- Recursive directory scan
SELECT * FROM dfs.`/data/sales/**/*.parquet`;
```

### File Metadata

```sql
-- Get filename for each row
SELECT 
    filename,
    customer_id,
    name
FROM dfs.`/data/customers/*.csv`;

-- Useful for tracking data source
```

### Union Multiple File Types

```sql
-- Combine CSV and JSON (if compatible schema)
SELECT customer_id, name, email
FROM dfs.`/data/customers.csv`

UNION ALL

SELECT customer_id, name, contact.email AS email
FROM dfs.`/data/customers_json/*.json`;
```

---

## Part 5: Real-World Scenarios

### Scenario 1: Web Server Log Analysis

**Log File: `webserver.json` (100K log entries)**
```json
{"timestamp": "2024-01-15T10:23:45Z", "method": "GET", "path": "/api/products", "status_code": 200, "response_time_ms": 45, "user_agent": "Mozilla/5.0..."}
{"timestamp": "2024-01-15T10:23:46Z", "method": "POST", "path": "/api/orders", "status_code": 201, "response_time_ms": 120, "user_agent": "Chrome/120..."}
{"timestamp": "2024-01-15T10:23:47Z", "method": "GET", "path": "/api/products/123", "status_code": 404, "response_time_ms": 20, "user_agent": "Mozilla/5.0..."}
```

**Analysis Queries:**
```sql
-- Error rate analysis
SELECT 
    CASE 
        WHEN status_code < 400 THEN 'Success'
        WHEN status_code < 500 THEN 'Client Error'
        ELSE 'Server Error'
    END AS status_category,
    COUNT(*) AS request_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dfs.`/logs/webserver.json`
GROUP BY status_category;

-- Output:
┌────────────────┬───────────────┬────────────┐
│ status_category│ request_count │ percentage │
├────────────────┼───────────────┼────────────┤
│ Success        │         95234 │      95.23 │
│ Client Error   │          4012 │       4.01 │
│ Server Error   │           754 │       0.75 │
└────────────────┴───────────────┴────────────┘

-- Slow endpoints
SELECT 
    path,
    COUNT(*) AS request_count,
    AVG(response_time_ms) AS avg_response_time,
    MAX(response_time_ms) AS max_response_time
FROM dfs.`/logs/webserver.json`
WHERE status_code = 200
GROUP BY path
HAVING AVG(response_time_ms) > 100
ORDER BY avg_response_time DESC
LIMIT 10;

-- Traffic by hour
SELECT 
    SUBSTRING(timestamp, 12, 2) AS hour,
    COUNT(*) AS requests,
    SUM(CASE WHEN status_code >= 500 THEN 1 ELSE 0 END) AS errors
FROM dfs.`/logs/webserver.json`
WHERE timestamp LIKE '2024-01-15%'
GROUP BY hour
ORDER BY hour;
```

### Scenario 2: Sales Data Analytics

**Files:**
```
/data/sales/2024-01.csv (10K rows)
/data/sales/2024-02.csv (12K rows)
/data/sales/2024-03.csv (15K rows)
```

**Query:**
```sql
-- Monthly sales trends
SELECT 
    SUBSTRING(filename, -10, 7) AS month,
    COUNT(*) AS order_count,
    SUM(amount) AS total_revenue,
    AVG(amount) AS avg_order_value
FROM dfs.`/data/sales/*.csv`
GROUP BY month
ORDER BY month;

-- Top products across all files
SELECT 
    product_name,
    SUM(quantity) AS total_quantity_sold,
    SUM(amount) AS total_revenue
FROM dfs.`/data/sales/*.csv`
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 10;
```

### Scenario 3: Data Lake Exploration

**Data Lake Structure:**
```
s3://company-datalake/
  raw/
    customers/customers.parquet (100K rows)
    orders/year=2024/month=01/*.parquet (500K rows)
    products/products.json (10K products)
  logs/
    application/2024-01/*.json (10M log entries)
```

**Exploration Queries:**
```sql
-- Understand data without schema documentation
SELECT * FROM dfs.`s3://company-datalake/raw/customers/*.parquet` LIMIT 5;

-- Count records
SELECT COUNT(*) FROM dfs.`s3://company-datalake/raw/orders/**/*.parquet`;

-- Sample data quality check
SELECT 
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS non_null_customer_id,
    COUNT(DISTINCT customer_id) AS unique_customers,
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order
FROM dfs.`s3://company-datalake/raw/orders/**/*.parquet`;
```

### Scenario 4: ETL Validation

**Before building ETL pipeline, validate with Drill:**
```sql
-- Check source data quality
SELECT 
    'customers.csv' AS file,
    COUNT(*) AS row_count,
    COUNT(DISTINCT customer_id) AS unique_ids,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS missing_emails,
    SUM(CASE WHEN email NOT LIKE '%@%' THEN 1 ELSE 0 END) AS invalid_emails
FROM dfs.`/data/customers.csv`

UNION ALL

SELECT 
    'orders.json' AS file,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS unique_ids,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN total <= 0 THEN 1 ELSE 0 END) AS invalid_totals
FROM dfs.`/data/orders.json`;

-- If data quality good → build ETL
-- If data quality poor → fix sources first
```

---

## Part 6: Performance Tips

### Tip 1: Use Parquet for Large Datasets

```sql
-- Convert CSV to Parquet (one-time)
CREATE TABLE dfs.tmp.`customers_parquet` AS
SELECT * FROM dfs.`/data/customers.csv`;

-- Future queries use Parquet (10x faster)
SELECT * FROM dfs.tmp.`customers_parquet` WHERE state = 'WA';
```

### Tip 2: Partition Large Files

```sql
-- Create partitioned output
CREATE TABLE dfs.tmp.`sales_partitioned` 
PARTITION BY (year, month) AS
SELECT 
    *,
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month
FROM dfs.`/data/sales.csv`;

-- Queries automatically use partitions
SELECT * 
FROM dfs.tmp.`sales_partitioned`
WHERE year = 2024 AND month = 1;
-- Only reads January 2024 partition!
```

### Tip 3: Filter Early

```sql
-- Bad (reads entire file):
SELECT * FROM dfs.`/data/large_file.parquet`;
SELECT * FROM subquery WHERE important_column = 'value';

-- Good (filter pushdown):
SELECT * 
FROM dfs.`/data/large_file.parquet`
WHERE important_column = 'value';
```

### Tip 4: Select Only Needed Columns

```sql
-- Bad (reads all columns):
SELECT * FROM dfs.`/data/wide_table.parquet`;

-- Good (reads only 2 columns):
SELECT customer_id, order_total 
FROM dfs.`/data/wide_table.parquet`;
```

---

## Key Takeaways

### File Formats
```
CSV:    ✓ Human-readable  ✗ Slow  ✗ Large
JSON:   ✓ Flexible        ✗ Slow  ✗ Large
Parquet: ✓ Fast           ✓ Small ✓ Optimized
```

### Query Patterns
```
SELECT * FROM dfs.`/path/file.csv`     -- Single CSV
SELECT * FROM dfs.`/path/*.json`       -- All JSON in dir
SELECT * FROM dfs.`/path/**/*.parquet` -- Recursive Parquet
```

### Nested Data
```
t.field.nested_field           -- Nested object
t.array_field[0]               -- Array element
FLATTEN(t.array_field)         -- Array to rows
```

### Performance
```
1. Use Parquet for large datasets
2. Partition by common filters
3. Filter early (predicate pushdown)
4. Select only needed columns
```

---

## Next Steps

**Continue to Lesson 18.3: Querying MySQL with Drill**  
Learn to connect Drill to MySQL and join relational data with files.

---

## Practice Exercises

**Exercise 1:** Query `sales.csv` to find total revenue by product.

**Exercise 2:** Flatten `orders_with_items.json` and calculate total revenue per product.

**Exercise 3:** Query `logs/**/*.json` to find error rate by hour.

**Exercise 4:** Compare query performance between CSV and Parquet for same data (10K+ rows).
