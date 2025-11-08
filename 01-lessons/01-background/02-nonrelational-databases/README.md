# Non-Relational Databases

## 🎯 Learning Objectives

- Understand what NoSQL databases are
- Learn the different types of NoSQL databases
- Compare NoSQL vs relational databases
- Identify when to use NoSQL vs SQL databases
- Explore popular NoSQL database systems

---

## What are Non-Relational (NoSQL) Databases?

**NoSQL** stands for "Not Only SQL" (not "No SQL")

> NoSQL databases are non-relational database systems designed for specific data models and access patterns that don't fit well in traditional relational databases.

**Key Characteristics:**
- 🚀 **Flexible Schema** - No rigid table structure
- 📈 **Scalable** - Horizontal scaling across servers
- ⚡ **Fast** - Optimized for specific use cases
- 🌍 **Distributed** - Built for cloud environments
- 📊 **Varied Models** - Different data storage approaches

---

## Why NoSQL Emerged

### The Problem with Traditional RDBMS at Scale

In the 2000s, companies like Google, Facebook, and Amazon faced challenges:

**Volume Issues:**
- Billions of users generating massive data
- Petabytes of information
- Millions of concurrent requests

**Velocity Issues:**
- Real-time data processing
- Instant updates and reads
- High throughput requirements

**Variety Issues:**
- Unstructured data (posts, images, videos)
- Semi-structured data (JSON, XML)
- Constantly changing data formats

**Traditional RDBMS Limitations:**
- ❌ Difficult to scale horizontally
- ❌ Schema changes are expensive
- ❌ ACID properties slow at massive scale
- ❌ Not optimized for key-value lookups
- ❌ Expensive hardware (scale up vs scale out)

---

## Types of NoSQL Databases

### 1. Document Databases 📄

**Structure:** Store data as documents (JSON, BSON, XML)

**Popular Systems:**
- **MongoDB** (most popular)
- CouchDB
- RavenDB

**Data Model:**
```json
// Customer document
{
  "_id": "CUST001",
  "name": "John Smith",
  "email": "john@example.com",
  "addresses": [
    {
      "type": "home",
      "street": "123 Main St",
      "city": "Boston",
      "state": "MA"
    },
    {
      "type": "work",
      "street": "456 Business Ave",
      "city": "Boston",
      "state": "MA"
    }
  ],
  "orders": [
    {
      "orderId": "ORD001",
      "date": "2024-11-01",
      "total": 299.99
    }
  ]
}
```

**Advantages:**
- ✅ Flexible schema (add fields anytime)
- ✅ Natural fit for JSON/APIs
- ✅ Embed related data together
- ✅ No joins needed for nested data

**Best For:**
- Content management systems
- User profiles and preferences
- Product catalogs
- Mobile app backends

**Querying (MongoDB example):**
```javascript
// Find all customers in Boston
db.customers.find({ "addresses.city": "Boston" })

// Find customers with orders over $200
db.customers.find({ "orders.total": { $gt: 200 } })
```

---

### 2. Key-Value Stores 🔑

**Structure:** Simple key-value pairs (like a hash map)

**Popular Systems:**
- **Redis** (in-memory, very fast)
- Amazon DynamoDB
- Riak
- Memcached

**Data Model:**
```
Key                    Value
─────────────────────────────────────────────
"user:1001"        →  { "name": "John", "age": 30 }
"session:abc123"   →  { "userId": 1001, "expires": "2024-11-07" }
"cart:xyz789"      →  ["item1", "item2", "item3"]
"counter:visits"   →  15847
```

**Advantages:**
- ✅ Extremely fast (O(1) lookups)
- ✅ Simple to understand
- ✅ Highly scalable
- ✅ Great for caching

**Best For:**
- Session management
- Shopping carts
- User preferences
- Cache layers
- Real-time analytics
- Leaderboards

**Example (Redis):**
```redis
SET user:1001:name "John Smith"
GET user:1001:name
INCR pageviews:homepage
EXPIRE session:abc123 3600
```

---

### 3. Column-Family Databases 📊

**Structure:** Store data in column families, optimized for reads

**Popular Systems:**
- **Apache Cassandra**
- **HBase**
- Google Bigtable
- ScyllaDB

**Data Model:**
```
Row Key: user_001
┌────────────────┬──────────────┬─────────────┬──────────────┐
│ Column Family: │ profile      │ preferences │ activity     │
├────────────────┼──────────────┼─────────────┼──────────────┤
│ Columns:       │ name: "John" │ theme: dark │ login: today │
│                │ age: 30      │ lang: en    │ posts: 42    │
│                │ city: Boston │             │              │
└────────────────┴──────────────┴─────────────┴──────────────┘
```

**Advantages:**
- ✅ Excellent for time-series data
- ✅ High write throughput
- ✅ Compression-friendly
- ✅ Can query by column

**Best For:**
- IoT sensor data
- Financial tick data
- Log aggregation
- Analytics systems
- Time-series data

**Example (Cassandra CQL):**
```sql
-- Looks like SQL but isn't!
CREATE TABLE sensor_data (
    sensor_id text,
    timestamp timestamp,
    temperature decimal,
    humidity decimal,
    PRIMARY KEY (sensor_id, timestamp)
);

INSERT INTO sensor_data (sensor_id, timestamp, temperature, humidity)
VALUES ('SENSOR001', '2024-11-07 10:30:00', 72.5, 45.2);

SELECT * FROM sensor_data 
WHERE sensor_id = 'SENSOR001' 
AND timestamp > '2024-11-07';
```

---

### 4. Graph Databases 🕸️

**Structure:** Nodes (entities) and edges (relationships)

**Popular Systems:**
- **Neo4j** (most popular)
- Amazon Neptune
- ArangoDB
- JanusGraph

**Data Model:**
```
    (Alice)────friends with────>(Bob)
       │                          │
       │                          │
    works at                   works at
       │                          │
       ↓                          ↓
   (Company A)              (Company B)
       │
       │
    located in
       │
       ↓
   (Boston)
```

**Advantages:**
- ✅ Natural for connected data
- ✅ Fast relationship queries
- ✅ Flexible schema
- ✅ Great for pattern matching

**Best For:**
- Social networks
- Recommendation engines
- Fraud detection
- Knowledge graphs
- Network topology

**Example (Cypher - Neo4j):**
```cypher
// Create nodes and relationships
CREATE (alice:Person {name: 'Alice', age: 30})
CREATE (bob:Person {name: 'Bob', age: 32})
CREATE (alice)-[:FRIENDS_WITH]->(bob)

// Find friends of friends
MATCH (person:Person)-[:FRIENDS_WITH]->()-[:FRIENDS_WITH]->(fof)
WHERE person.name = 'Alice'
RETURN fof.name

// Shortest path
MATCH path = shortestPath(
  (alice:Person {name: 'Alice'})-[*]-(bob:Person {name: 'Bob'})
)
RETURN path
```

---

## NoSQL vs Relational Databases

### When to Use SQL (RDBMS)

✅ **Use SQL when you need:**
- **ACID compliance** - Banking, financial transactions
- **Complex queries** - Joins across many tables
- **Structured data** - Well-defined schema
- **Data integrity** - Strong constraints
- **Reporting** - Complex aggregations and analytics
- **Mature ecosystem** - Decades of tools and expertise

**Examples:**
- Banking systems
- ERP systems (SAP, Oracle)
- CRM applications
- E-commerce transactions
- Accounting systems

---

### When to Use NoSQL

✅ **Use NoSQL when you need:**
- **Horizontal scalability** - Millions of users
- **Flexible schema** - Rapidly changing data models
- **High throughput** - Massive read/write operations
- **Unstructured data** - JSON, documents, key-values
- **Distributed systems** - Cloud-native applications
- **Specific access patterns** - Key lookups, graphs

**Examples:**
- Social media feeds (Facebook, Twitter)
- Real-time analytics (user behavior)
- IoT data collection
- Gaming leaderboards
- Content management
- Caching layers

---

## Comparison Table

| Feature | SQL (RDBMS) | NoSQL |
|---------|-------------|-------|
| **Schema** | Fixed, predefined | Flexible, dynamic |
| **Scaling** | Vertical (bigger servers) | Horizontal (more servers) |
| **Data Model** | Tables with rows/columns | Document, key-value, graph, etc. |
| **Queries** | SQL (powerful, complex) | API calls (varies by system) |
| **Relationships** | Foreign keys, joins | Embedded or references |
| **Transactions** | Full ACID support | Eventually consistent (mostly) |
| **Best For** | Structured, relational data | Unstructured, hierarchical data |
| **Examples** | MySQL, PostgreSQL, SQL Server | MongoDB, Redis, Cassandra, Neo4j |
| **Learning Curve** | Steeper initially | Varies (Redis easy, Cassandra hard) |
| **Maturity** | 40+ years | 15+ years |

---

## Real-World Scenarios

### Scenario 1: E-Commerce Site

**SQL Use:**
```sql
-- Order processing (needs ACID)
BEGIN TRANSACTION;
INSERT INTO orders (customer_id, total) VALUES (123, 299.99);
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 456;
COMMIT;
```

**NoSQL Use:**
```javascript
// Product catalog (flexible schema)
{
  "productId": "PROD001",
  "name": "Laptop",
  "price": 999.99,
  "specs": {
    "cpu": "Intel i7",
    "ram": "16GB",
    "storage": "512GB SSD"
  },
  "reviews": [
    { "user": "john", "rating": 5, "comment": "Great!" }
  ]
}
```

**Hybrid Approach:** ⭐ Best solution!
- SQL for orders, payments, inventory (transactions)
- NoSQL for product catalog, user sessions, logs

---

### Scenario 2: Social Media Platform

**Better with NoSQL:**
```javascript
// User profile with posts (nested data)
{
  "userId": "user123",
  "name": "Alice",
  "followers": 1523,
  "posts": [
    {
      "postId": "post1",
      "text": "Hello world!",
      "timestamp": "2024-11-07T10:30:00Z",
      "likes": 42,
      "comments": [...]
    }
  ]
}
```

**Why NoSQL Wins:**
- Schema changes frequently (new post types)
- Needs massive scale (millions of users)
- Data naturally hierarchical
- Fast key-based lookups

---

### Scenario 3: Analytics Dashboard

**SQL Shines:**
```sql
-- Complex aggregation
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    category,
    COUNT(*) AS total_orders,
    SUM(amount) AS revenue,
    AVG(amount) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE order_date >= '2024-01-01'
GROUP BY month, category
ORDER BY revenue DESC;
```

**Why SQL Wins:**
- Complex joins and aggregations
- Ad-hoc reporting needs
- Data warehouse scenarios

---

## The "NoSQL" is Not Anti-SQL

**Important:** NoSQL doesn't mean "don't use SQL" — it means "Not Only SQL"

### Modern Approach: Polyglot Persistence

Use the right database for each job:

```
┌─────────────────────────────────────────┐
│         Modern Application              │
├─────────────────────────────────────────┤
│                                         │
│  SQL Server      →  Transactional data │
│  Redis           →  Caching/sessions   │
│  MongoDB         →  Product catalog    │
│  Elasticsearch   →  Search index       │
│  Cassandra       →  Time-series logs   │
│                                         │
└─────────────────────────────────────────┘
```

---

## Popular NoSQL Databases

### MongoDB (Document)
- Most popular NoSQL database
- JSON-like documents
- Rich query language
- Good developer experience

### Redis (Key-Value)
- In-memory (extremely fast)
- Used for caching, sessions
- Pub/sub messaging
- Data structures (lists, sets, sorted sets)

### Cassandra (Column-Family)
- Highly scalable writes
- No single point of failure
- Time-series data
- Used by Netflix, Apple, Spotify

### Neo4j (Graph)
- Relationships as first-class citizens
- Cypher query language
- Social networks, recommendations
- Fraud detection

---

## CAP Theorem

NoSQL databases often sacrifice consistency for availability/partition tolerance.

**CAP Theorem:** You can only have 2 of 3:
- **C**onsistency - All nodes see same data
- **A**vailability - System always responds
- **P**artition Tolerance - Works despite network failures

**SQL Databases:** Usually CP (consistency + partition tolerance)
**NoSQL Databases:** Usually AP (availability + partition tolerance)

**Example:**
- **MongoDB** - CP (consistent but may be unavailable)
- **Cassandra** - AP (available but eventually consistent)
- **Redis** - CP (consistent, single master)

---

## 🧠 Key Concepts to Remember

1. NoSQL = "Not Only SQL", not "No SQL"
2. Four main types: Document, Key-Value, Column-Family, Graph
3. NoSQL trades ACID compliance for scalability and flexibility
4. Use SQL for transactions and complex queries
5. Use NoSQL for scale, speed, and flexible schemas
6. Modern apps often use both (polyglot persistence)
7. NoSQL databases are specialized tools, not SQL replacements

---

## 📝 Check Your Understanding

1. What does NoSQL stand for?
2. Name the four main types of NoSQL databases
3. Give an example of when you'd use a document database
4. What is Redis best used for?
5. Why might a social media platform choose NoSQL over SQL?
6. What is the CAP theorem?
7. Can you use both SQL and NoSQL in the same application?
8. What type of NoSQL database would you use for a recommendation engine?

---

## ⏭️ Next Lesson

Continue with: **[03 - The Relational Model](../03-relational-model/)** - Deep dive into how relational databases organize data.

---

## 📚 Additional Resources

- [MongoDB University](https://university.mongodb.com/) - Free MongoDB courses
- [Redis Documentation](https://redis.io/documentation)
- [NoSQL Distilled (Book)](https://martinfowler.com/books/nosql.html)
- [CAP Theorem Explained](https://www.ibm.com/cloud/learn/cap-theorem)
