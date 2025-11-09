# Lesson 18.4: Querying MongoDB with Drill

## Learning Objectives

By the end of this lesson, you will be able to:
1. Configure Apache Drill to connect to MongoDB
2. Query MongoDB collections using standard SQL
3. Flatten nested documents and arrays
4. Join MongoDB data with files and relational databases
5. Understand performance considerations for NoSQL queries

## Business Context

**MongoDB stores 60% of NoSQL data** in modern applications. Apache Drill enables **SQL analysts to query MongoDB** without learning MongoDB query language—democratizing access to NoSQL data for traditional SQL teams.

**Time:** 50 minutes  
**Level:** Advanced

---

## Part 1: Connecting Drill to MongoDB

### Prerequisites

**MongoDB Running:**
```bash
# Verify MongoDB is accessible
mongosh

# Or Docker:
docker run -d --name mongodb -p 27017:27017 mongo:latest
```

### Configure MongoDB Storage Plugin

**Step 1: Access Drill Web UI**
```
Open browser: http://localhost:8047
Navigate to: Storage tab
Click: "+ Create" (or Update existing)
```

**Step 2: Create MongoDB Storage Plugin**

**Plugin Name:** `mongo`

**Configuration:**
```json
{
  "type": "mongo",
  "connection": "mongodb://localhost:27017/",
  "enabled": true
}
```

**With Authentication:**
```json
{
  "type": "mongo",
  "connection": "mongodb://username:password@localhost:27017/",
  "enabled": true,
  "authMechanism": "SCRAM-SHA-256"
}
```

**MongoDB Atlas (Cloud):**
```json
{
  "type": "mongo",
  "connection": "mongodb+srv://username:password@cluster.mongodb.net/",
  "enabled": true
}
```

**Step 3: Test Connection**
```sql
-- List databases
SHOW DATABASES;

-- You should see:
-- mongo        <-- Your MongoDB plugin!

-- Show collections
USE mongo;
SHOW TABLES;
```

---

## Part 2: Understanding MongoDB Documents

### Document Structure

**MongoDB stores documents (JSON-like):**
```json
{
  "_id": ObjectId("507f1f77bcf86cd799439011"),
  "customer_id": 1001,
  "name": "John Doe",
  "email": "john@example.com",
  "address": {
    "street": "123 Main St",
    "city": "Seattle",
    "state": "WA",
    "zip": "98101"
  },
  "orders": [
    {
      "order_id": 5001,
      "date": "2024-01-15",
      "total": 99.99
    },
    {
      "order_id": 5002,
      "date": "2024-01-20",
      "total": 149.99
    }
  ],
  "tags": ["premium", "loyal"],
  "active": true
}
```

**Characteristics:**
```
✓ Flexible schema (documents vary)
✓ Nested objects (address)
✓ Arrays (orders, tags)
✓ Mixed types
✗ Not flat like relational tables
```

### Sample MongoDB Data

**Create Sample Collection:**
```javascript
// In mongosh:
use ecommerce;

// Insert sample customers
db.customers.insertMany([
  {
    customer_id: 1001,
    name: "John Doe",
    email: "john@example.com",
    address: {
      street: "123 Main St",
      city: "Seattle",
      state: "WA",
      zip: "98101"
    },
    orders: [
      { order_id: 5001, date: "2024-01-15", total: 99.99 },
      { order_id: 5002, date: "2024-01-20", total: 149.99 }
    ],
    tags: ["premium", "loyal"],
    active: true
  },
  {
    customer_id: 1002,
    name: "Jane Smith",
    email: "jane@example.com",
    address: {
      street: "456 Oak Ave",
      city: "Portland",
      state: "OR",
      zip: "97201"
    },
    orders: [
      { order_id: 5003, date: "2024-01-18", total: 199.99 }
    ],
    tags: ["new"],
    active: true
  },
  {
    customer_id: 1003,
    name: "Bob Johnson",
    email: "bob@example.com",
    address: {
      street: "789 Pine Rd",
      city: "San Francisco",
      state: "CA",
      zip: "94102"
    },
    orders: [],
    tags: ["inactive"],
    active: false
  }
]);

// Verify
db.customers.find();
```

---

## Part 3: Querying MongoDB Collections

### Basic Queries

**Query Entire Collection:**
```sql
-- Syntax: mongo.[database].[collection]
SELECT * FROM mongo.ecommerce.customers;

-- Output (flattened view):
┌─────────────┬──────────┬───────────────────┬──────────┬────────────────┬─────────┐
│ customer_id │   name   │       email       │ address  │     orders     │  tags   │
├─────────────┼──────────┼───────────────────┼──────────┼────────────────┼─────────┤
│        1001 │ John Doe │ john@example.com  │ {...}    │ [{...},{...}]  │ [...]   │
│        1002 │ Jane Sm. │ jane@example.com  │ {...}    │ [{...}]        │ [...]   │
│        1003 │ Bob John │ bob@example.com   │ {...}    │ []             │ [...]   │
└─────────────┴──────────┴───────────────────┴──────────┴────────────────┴─────────┘
```

**Select Specific Fields:**
```sql
-- Select top-level fields
SELECT customer_id, name, email, active
FROM mongo.ecommerce.customers;

-- Output:
┌─────────────┬────────────┬──────────────────┬────────┐
│ customer_id │    name    │      email       │ active │
├─────────────┼────────────┼──────────────────┼────────┤
│        1001 │ John Doe   │ john@example.com │ true   │
│        1002 │ Jane Smith │ jane@example.com │ true   │
│        1003 │ Bob John.  │ bob@example.com  │ false  │
└─────────────┴────────────┴──────────────────┴────────┘
```

### Accessing Nested Fields

**Dot Notation for Nested Objects:**
```sql
-- Access nested address fields
SELECT 
    customer_id,
    name,
    t.address.city AS city,
    t.address.state AS state,
    t.address.zip AS zip
FROM mongo.ecommerce.customers t;

-- Output:
┌─────────────┬────────────┬───────────────┬───────┬───────┐
│ customer_id │    name    │     city      │ state │  zip  │
├─────────────┼────────────┼───────────────┼───────┼───────┤
│        1001 │ John Doe   │ Seattle       │ WA    │ 98101 │
│        1002 │ Jane Smith │ Portland      │ OR    │ 97201 │
│        1003 │ Bob John.  │ San Francisco │ CA    │ 94102 │
└─────────────┴────────────┴───────────────┴───────┴───────┘

-- Note: 't.' prefix required for nested field access
```

**Filter by Nested Field:**
```sql
-- Find customers in Washington state
SELECT name, t.address.city, t.address.state
FROM mongo.ecommerce.customers t
WHERE t.address.state = 'WA';

-- Output:
┌──────────┬─────────┬───────┐
│   name   │  city   │ state │
├──────────┼─────────┼───────┤
│ John Doe │ Seattle │ WA    │
└──────────┴─────────┴───────┘
```

---

## Part 4: Flattening Arrays

### FLATTEN Operator

**Problem: Arrays are not queryable directly**
```sql
-- This doesn't work well:
SELECT customer_id, orders
FROM mongo.ecommerce.customers;

-- orders appears as single value: [{...},{...}]
-- Can't aggregate, filter individual orders
```

**Solution: FLATTEN array into rows**
```sql
-- Flatten orders array
SELECT 
    t.customer_id,
    t.name,
    order_detail.order_id,
    order_detail.date AS order_date,
    order_detail.total AS order_total
FROM mongo.ecommerce.customers t,
LATERAL FLATTEN(t.orders) AS order_detail;

-- Output:
┌─────────────┬────────────┬──────────┬────────────┬─────────────┐
│ customer_id │    name    │ order_id │ order_date │ order_total │
├─────────────┼────────────┼──────────┼────────────┼─────────────┤
│        1001 │ John Doe   │     5001 │ 2024-01-15 │       99.99 │
│        1001 │ John Doe   │     5002 │ 2024-01-20 │      149.99 │
│        1002 │ Jane Smith │     5003 │ 2024-01-18 │      199.99 │
└─────────────┴────────────┴──────────┴────────────┴─────────────┘

-- Note: Bob Johnson (empty orders array) doesn't appear
```

**FLATTEN Explanation:**
```
Before FLATTEN:
┌─────────────┬────────────┬────────────────────────────────┐
│ customer_id │    name    │            orders              │
├─────────────┼────────────┼────────────────────────────────┤
│        1001 │ John Doe   │ [{5001,...}, {5002,...}]       │
└─────────────┴────────────┴────────────────────────────────┘

After FLATTEN:
┌─────────────┬────────────┬──────────┐
│ customer_id │    name    │ order_id │
├─────────────┼────────────┼──────────┤
│        1001 │ John Doe   │     5001 │
│        1001 │ John Doe   │     5002 │
└─────────────┴────────────┴──────────┘
```

### Aggregating Flattened Data

```sql
-- Total orders and revenue per customer
SELECT 
    t.customer_id,
    t.name,
    COUNT(order_detail.order_id) AS order_count,
    SUM(order_detail.total) AS total_revenue
FROM mongo.ecommerce.customers t,
LATERAL FLATTEN(t.orders) AS order_detail
GROUP BY t.customer_id, t.name
ORDER BY total_revenue DESC;

-- Output:
┌─────────────┬────────────┬─────────────┬───────────────┐
│ customer_id │    name    │ order_count │ total_revenue │
├─────────────┼────────────┼─────────────┼───────────────┤
│        1001 │ John Doe   │           2 │        249.98 │
│        1002 │ Jane Smith │           1 │        199.99 │
└─────────────┴────────────┴─────────────┴───────────────┘
```

### String Arrays (Simple Values)

**MongoDB Collection with String Array:**
```javascript
// In mongosh:
db.products.insertMany([
  {
    product_id: 101,
    name: "Laptop",
    categories: ["Electronics", "Computers", "Business"],
    price: 999.99
  },
  {
    product_id: 102,
    name: "Coffee Maker",
    categories: ["Home", "Kitchen"],
    price: 79.99
  }
]);
```

**Flatten String Array:**
```sql
-- Flatten categories
SELECT 
    t.product_id,
    t.name,
    category
FROM mongo.ecommerce.products t,
LATERAL FLATTEN(t.categories) AS category;

-- Output:
┌────────────┬──────────────┬──────────────┐
│ product_id │     name     │   category   │
├────────────┼──────────────┼──────────────┤
│        101 │ Laptop       │ Electronics  │
│        101 │ Laptop       │ Computers    │
│        101 │ Laptop       │ Business     │
│        102 │ Coffee Maker │ Home         │
│        102 │ Coffee Maker │ Kitchen      │
└────────────┴──────────────┴──────────────┘

-- Count products per category
SELECT 
    category,
    COUNT(DISTINCT t.product_id) AS product_count
FROM mongo.ecommerce.products t,
LATERAL FLATTEN(t.categories) AS category
GROUP BY category
ORDER BY product_count DESC;
```

---

## Part 5: Joining MongoDB with Other Sources

### MongoDB + CSV

**Scenario:**
```
MongoDB:  Customer documents (operational data)
CSV File: Customer satisfaction scores (survey data)
```

**CSV File: `/data/customer_satisfaction.csv`**
```csv
customer_id,satisfaction_score,survey_date
1001,4.5,2024-01-25
1002,3.8,2024-01-26
1003,2.1,2024-01-27
```

**Federated Query:**
```sql
-- Join MongoDB customers with CSV satisfaction data
SELECT 
    c.customer_id,
    c.name,
    c.address.city AS city,
    s.satisfaction_score,
    s.survey_date
FROM mongo.ecommerce.customers c
JOIN dfs.`/data/customer_satisfaction.csv` s 
    ON c.customer_id = s.customer_id
WHERE s.satisfaction_score < 3.0;

-- Output:
┌─────────────┬──────────────┬───────────────┬────────────────────┬─────────────┐
│ customer_id │     name     │     city      │ satisfaction_score │ survey_date │
├─────────────┼──────────────┼───────────────┼────────────────────┼─────────────┤
│        1003 │ Bob Johnson  │ San Francisco │                2.1 │  2024-01-27 │
└─────────────┴──────────────┴───────────────┴────────────────────┴─────────────┘

-- This identifies unhappy customers for follow-up!
```

### MongoDB + MySQL

**Scenario:**
```
MongoDB: Product catalog (flexible schema)
MySQL:   Order transactions (OLTP)
```

**Query:**
```sql
-- Join MySQL orders with MongoDB product details
SELECT 
    o.order_id,
    o.customer_id,
    o.product_id,
    p.name AS product_name,
    p.price AS unit_price,
    o.quantity,
    o.quantity * p.price AS line_total
FROM mysql.ecommerce.orders o
JOIN mongo.ecommerce.products p 
    ON o.product_id = p.product_id
WHERE o.order_date >= '2024-01-01';

-- This combines:
-- ✓ MySQL transactional data
-- ✓ MongoDB product catalog
-- ✓ No data duplication!
```

### Three-Way Join: MongoDB + MySQL + Parquet

**Scenario:**
```
MongoDB:    Customer profiles
MySQL:      Order transactions
Parquet:    Web analytics (clickstream data)
```

**Query:**
```sql
-- Customer 360 view
SELECT 
    c.customer_id,
    c.name,
    c.address.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    AVG(w.page_views) AS avg_page_views,
    AVG(w.session_duration_seconds) AS avg_session_duration
FROM mongo.ecommerce.customers c
LEFT JOIN mysql.ecommerce.orders o 
    ON c.customer_id = o.customer_id
LEFT JOIN dfs.`/data/web_analytics.parquet` w 
    ON c.customer_id = w.customer_id
GROUP BY c.customer_id, c.name, c.address.city
ORDER BY total_spent DESC
LIMIT 10;

-- Unified customer view from three sources!
```

---

## Part 6: Complex Nested Structures

### Nested Arrays of Objects

**Complex MongoDB Document:**
```json
{
  "order_id": 9001,
  "customer_id": 1001,
  "order_date": "2024-01-15",
  "shipping_address": {
    "street": "123 Main St",
    "city": "Seattle",
    "state": "WA"
  },
  "items": [
    {
      "product_id": 101,
      "product_name": "Laptop",
      "quantity": 1,
      "price": 999.99,
      "options": [
        {"option": "RAM", "value": "16GB"},
        {"option": "Storage", "value": "512GB SSD"}
      ]
    },
    {
      "product_id": 102,
      "product_name": "Mouse",
      "quantity": 2,
      "price": 29.99,
      "options": []
    }
  ],
  "total": 1059.97
}
```

**Query with Multiple FLATTEN:**
```sql
-- Flatten items array
SELECT 
    t.order_id,
    t.order_date,
    item.product_name,
    item.quantity,
    item.price
FROM mongo.ecommerce.orders t,
LATERAL FLATTEN(t.items) AS item;

-- Flatten nested options within items
SELECT 
    t.order_id,
    item.product_name,
    option.option AS option_name,
    option.value AS option_value
FROM mongo.ecommerce.orders t,
LATERAL FLATTEN(t.items) AS item,
LATERAL FLATTEN(item.options) AS option;

-- Output:
┌──────────┬──────────────┬─────────────┬──────────────┐
│ order_id │ product_name │ option_name │ option_value │
├──────────┼──────────────┼─────────────┼──────────────┤
│     9001 │ Laptop       │ RAM         │ 16GB         │
│     9001 │ Laptop       │ Storage     │ 512GB SSD    │
└──────────┴──────────────┴─────────────┴──────────────┘
```

---

## Part 7: Performance Considerations

### Query Pushdown Limitations

**MongoDB Query Pushdown:**
```sql
-- Simple filters push down (executed in MongoDB):
SELECT * FROM mongo.ecommerce.customers
WHERE customer_id = 1001;  -- ✓ Pushed to MongoDB

SELECT * FROM mongo.ecommerce.customers
WHERE active = true;  -- ✓ Pushed to MongoDB

-- Complex operations don't push down (executed in Drill):
SELECT * FROM mongo.ecommerce.customers
WHERE UPPER(name) LIKE '%JOHN%';  -- ✗ Not pushed (processed in Drill)
```

**Check Query Plan:**
```sql
EXPLAIN PLAN FOR
SELECT * FROM mongo.ecommerce.customers
WHERE customer_id = 1001;

-- Look for "MongoGroupScan" with filter information
```

### Indexes in MongoDB

**Create Indexes to Speed Up Queries:**
```javascript
// In mongosh:
db.customers.createIndex({ customer_id: 1 });
db.customers.createIndex({ "address.state": 1 });
db.orders.createIndex({ customer_id: 1, order_date: -1 });

// Drill benefits from MongoDB indexes via pushdown
```

**Query with Index:**
```sql
-- Fast (uses MongoDB index on customer_id):
SELECT * FROM mongo.ecommerce.customers
WHERE customer_id = 1001;

-- Slow (no index on email):
SELECT * FROM mongo.ecommerce.customers
WHERE email = 'john@example.com';
```

### Minimize Data Transfer

```sql
-- Bad: Select all nested fields
SELECT * FROM mongo.ecommerce.customers;
-- Transfers entire documents (including large arrays)

-- Good: Select only needed fields
SELECT customer_id, name, t.address.city
FROM mongo.ecommerce.customers t;
-- Transfers minimal data
```

### FLATTEN Performance

```sql
-- FLATTEN can be expensive for large arrays
-- Consider filtering before FLATTEN:

-- Good:
SELECT 
    t.customer_id,
    order_detail.order_id
FROM mongo.ecommerce.customers t,
LATERAL FLATTEN(t.orders) AS order_detail
WHERE t.customer_id IN (1001, 1002);  -- Filter first!

-- Bad:
SELECT 
    t.customer_id,
    order_detail.order_id
FROM mongo.ecommerce.customers t,
LATERAL FLATTEN(t.orders) AS order_detail
WHERE t.customer_id IN (1001, 1002);  -- Filter after FLATTEN
```

---

## Part 8: Real-World Use Cases

### Use Case 1: SQL Reporting on MongoDB

**Problem:**
```
Application:   Uses MongoDB (flexible schema)
BI Team:       Knows SQL, not MongoDB query language
Requirement:   Enable SQL-based reporting
```

**Solution:**
```sql
-- SQL analysts query MongoDB directly
SELECT 
    t.address.state AS state,
    COUNT(DISTINCT customer_id) AS customer_count,
    SUM(CASE WHEN active THEN 1 ELSE 0 END) AS active_customers,
    ROUND(
        SUM(CASE WHEN active THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS active_percentage
FROM mongo.ecommerce.customers t
GROUP BY t.address.state
ORDER BY customer_count DESC;

-- No need to learn MongoDB query language!
```

### Use Case 2: Data Migration from MongoDB to Warehouse

**Problem:**
```
Migrate MongoDB data to SQL Data Warehouse
Need to flatten nested structures
Validate data before migration
```

**Solution:**
```sql
-- Create flattened view for migration
CREATE TABLE dfs.tmp.`customers_flat` AS
SELECT 
    customer_id,
    name,
    email,
    t.address.street AS address_street,
    t.address.city AS address_city,
    t.address.state AS address_state,
    t.address.zip AS address_zip,
    active
FROM mongo.ecommerce.customers t;

-- Validate record counts
SELECT 
    'MongoDB' AS source,
    COUNT(*) AS record_count
FROM mongo.ecommerce.customers

UNION ALL

SELECT 
    'Flattened' AS source,
    COUNT(*) AS record_count
FROM dfs.tmp.`customers_flat`;
```

### Use Case 3: Hybrid Analytics

**Problem:**
```
MongoDB:  Real-time operational data
MySQL:    Historical transactional data
Need:     Combined analytics
```

**Solution:**
```sql
-- Unified customer analytics
SELECT 
    c.customer_id,
    c.name,
    c.address.city AS current_city,
    hist.total_lifetime_orders,
    hist.total_lifetime_revenue,
    current_orders.recent_order_count,
    current_orders.recent_revenue
FROM mongo.ecommerce.customers c
LEFT JOIN mysql.warehouse.customer_history hist 
    ON c.customer_id = hist.customer_id
LEFT JOIN (
    SELECT 
        t.customer_id,
        COUNT(order_detail.order_id) AS recent_order_count,
        SUM(order_detail.total) AS recent_revenue
    FROM mongo.ecommerce.customers t,
    LATERAL FLATTEN(t.orders) AS order_detail
    WHERE order_detail.date >= '2024-01-01'
    GROUP BY t.customer_id
) current_orders ON c.customer_id = current_orders.customer_id
ORDER BY hist.total_lifetime_revenue DESC
LIMIT 100;
```

---

## Key Takeaways

### Configuration
```
1. Create MongoDB storage plugin
2. Provide connection string
3. Test with SHOW TABLES
```

### Querying
```
-- Collection syntax:
mongo.[database].[collection]

-- Nested fields:
t.field.nested_field

-- Arrays:
LATERAL FLATTEN(t.array_field) AS item
```

### Flattening
```
FLATTEN converts arrays into rows
Essential for aggregating array elements
Can be expensive for large arrays
```

### Joins
```
✓ Join MongoDB with CSV, JSON, Parquet
✓ Join MongoDB with MySQL, PostgreSQL
✓ Create unified views across sources
```

### Performance
```
✓ Create indexes in MongoDB
✓ Filter before FLATTEN
✓ Select only needed fields
✓ Verify query pushdown with EXPLAIN
```

---

## Next Steps

**Continue to Lesson 18.5: Querying Multiple Sources with Drill**  
Learn advanced federated query patterns combining files, RDBMS, and NoSQL.

---

## Practice Exercises

**Exercise 1:** Configure MongoDB plugin and query a sample collection.

**Exercise 2:** Flatten nested array of orders and calculate total revenue per customer.

**Exercise 3:** Join MongoDB customer data with CSV file containing additional metrics.

**Exercise 4:** Write three-way join: MongoDB + MySQL + Parquet.
