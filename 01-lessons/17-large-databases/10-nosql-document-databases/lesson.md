# Lesson 17.10: NoSQL Document Databases

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand document database concepts and data models
2. Compare SQL vs NoSQL design patterns
3. Work with JSON documents in databases
4. Evaluate when to use document databases vs relational databases
5. Understand Azure Cosmos DB and MongoDB

## Business Context

**Document databases** store data as JSON/BSON documents rather than rows and columns. They excel at flexible schemas, hierarchical data, and rapid development. Understanding when to use document databases vs SQL databases is crucial for modern application architectures.

**Time:** 50 minutes  
**Level:** Advanced

---

## Part 1: Document Database Fundamentals

### What is a Document Database?

**Document Database** = NoSQL database that stores data as JSON-like documents

**Key Characteristics:**
```
✓ Schema-flexible (no rigid table structure)
✓ Hierarchical data (nested objects, arrays)
✓ Document-oriented (complete entity in one document)
✓ Horizontally scalable
✓ Denormalized design
```

### Document vs Relational Model

**Relational (SQL Server):**
```sql
-- Customer table
Customers:
┌────────────┬──────────┬──────────────────┐
│ CustomerID │ Name     │ Email            │
├────────────┼──────────┼──────────────────┤
│ 1          │ John Doe │ john@example.com │
└────────────┴──────────┴──────────────────┘

-- Orders table
Orders:
┌─────────┬────────────┬─────────────┬────────┐
│ OrderID │ CustomerID │ OrderDate   │ Amount │
├─────────┼────────────┼─────────────┼────────┤
│ 101     │ 1          │ 2024-01-15  │ 99.99  │
│ 102     │ 1          │ 2024-02-20  │ 149.99 │
└─────────┴────────────┴─────────────┴────────┘

-- OrderItems table
OrderItems:
┌─────────┬───────────┬──────────┬────────┐
│ ItemID  │ OrderID   │ Product  │ Qty    │
├─────────┼───────────┼──────────┼────────┤
│ 1       │ 101       │ Widget A │ 2      │
│ 2       │ 101       │ Widget B │ 1      │
│ 3       │ 102       │ Widget C │ 3      │
└─────────┴───────────┴──────────┴────────┘

-- Query requires 3 JOINs
SELECT c.Name, o.OrderDate, oi.Product, oi.Qty
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID;
```

**Document (MongoDB/Cosmos DB):**
```json
{
  "_id": "customer_1",
  "name": "John Doe",
  "email": "john@example.com",
  "orders": [
    {
      "orderId": 101,
      "orderDate": "2024-01-15",
      "amount": 99.99,
      "items": [
        {"product": "Widget A", "qty": 2, "price": 29.99},
        {"product": "Widget B", "qty": 1, "price": 40.01}
      ]
    },
    {
      "orderId": 102,
      "orderDate": "2024-02-20",
      "amount": 149.99,
      "items": [
        {"product": "Widget C", "qty": 3, "price": 49.99}
      ]
    }
  ]
}

// Query: Single document lookup (NO JOINS!)
db.customers.findOne({"_id": "customer_1"})
```

### When to Use Each Model

**Use SQL (Relational):**
```
✓ Complex relationships (many-to-many)
✓ ACID transactions critical
✓ Data integrity constraints
✓ Normalized data (avoid redundancy)
✓ Complex queries with multiple joins
✓ Structured, predictable schema

Examples:
- Financial transactions
- E-commerce order processing
- ERP systems
- Healthcare records (HIPAA)
```

**Use Document Database:**
```
✓ Flexible/evolving schema
✓ Hierarchical data (nested objects)
✓ Document-centric (blog posts, products)
✓ High write throughput
✓ Horizontal scaling needed
✓ Rapid development (no migrations)

Examples:
- Content management systems
- User profiles (social media)
- Product catalogs
- Mobile app backends
- Real-time analytics
```

---

## Part 2: Document Design Patterns

### Pattern 1: Embedding (Denormalization)

**Embed related data within document:**

```json
// Blog Post with embedded comments
{
  "_id": "post_12345",
  "title": "Introduction to NoSQL",
  "author": "Jane Smith",
  "content": "NoSQL databases offer...",
  "publishedDate": "2024-11-01",
  "tags": ["nosql", "database", "mongodb"],
  "comments": [
    {
      "commentId": 1,
      "author": "Bob Johnson",
      "text": "Great article!",
      "date": "2024-11-02"
    },
    {
      "commentId": 2,
      "author": "Alice Brown",
      "text": "Very informative.",
      "date": "2024-11-03"
    }
  ],
  "stats": {
    "views": 1250,
    "likes": 45,
    "shares": 12
  }
}
```

**Benefits:**
```
✓ Single query retrieves all data
✓ No joins needed
✓ Atomic updates (entire document)
✓ Better performance for read-heavy workloads
```

**Drawbacks:**
```
✗ Data duplication
✗ Document size can grow large (16MB limit in MongoDB)
✗ Updating embedded data difficult if referenced elsewhere
✗ Cannot query embedded data efficiently across documents
```

**When to Embed:**
```
✓ One-to-few relationships (< 100 embedded items)
✓ Data accessed together
✓ Embedded data doesn't change often
✓ Read performance critical
```

### Pattern 2: Referencing (Normalization)

**Store references to related documents:**

```json
// Author document
{
  "_id": "author_001",
  "name": "Jane Smith",
  "email": "jane@example.com",
  "bio": "Tech blogger and developer"
}

// Blog Post document (references author)
{
  "_id": "post_12345",
  "title": "Introduction to NoSQL",
  "authorId": "author_001",  // Reference to author
  "content": "NoSQL databases offer...",
  "publishedDate": "2024-11-01",
  "tags": ["nosql", "database", "mongodb"]
}

// Query with population (similar to JOIN)
db.posts.aggregate([
  {
    $lookup: {
      from: "authors",
      localField: "authorId",
      foreignField: "_id",
      as: "author"
    }
  }
])
```

**Benefits:**
```
✓ No data duplication
✓ Easy to update referenced data
✓ Smaller document size
✓ Can query referenced collection independently
```

**Drawbacks:**
```
✗ Requires multiple queries or $lookup (like JOIN)
✗ No foreign key constraints
✗ Application must manage referential integrity
```

**When to Reference:**
```
✓ One-to-many (many > 100)
✓ Many-to-many relationships
✓ Referenced data changes frequently
✓ Need to query referenced data independently
```

### Pattern 3: Hybrid Approach

**Combine embedding and referencing:**

```json
// Product Catalog
{
  "_id": "product_xyz",
  "name": "Laptop Pro 2024",
  "price": 1299.99,
  
  // Embed: Small, frequently accessed data
  "specifications": {
    "cpu": "Intel i7",
    "ram": "16GB",
    "storage": "512GB SSD"
  },
  
  // Embed: Summary of related data
  "category": {
    "id": "cat_electronics",
    "name": "Electronics"
  },
  
  // Reference: Large or frequently changing data
  "reviewIds": [
    "review_001",
    "review_002",
    "review_003"
  ],
  
  // Embed: Aggregated stats (updated periodically)
  "stats": {
    "averageRating": 4.5,
    "reviewCount": 127,
    "lastUpdated": "2024-11-09"
  }
}

// Separate Reviews collection
{
  "_id": "review_001",
  "productId": "product_xyz",
  "userId": "user_12345",
  "rating": 5,
  "text": "Excellent laptop!",
  "date": "2024-10-15"
}
```

---

## Part 3: MongoDB Overview

### MongoDB Architecture

```
┌─────────────────────────────────────┐
│         MongoDB Cluster              │
├─────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐ │
│  │     Replica Set (HA)           │ │
│  │  ┌──────────┬──────────┬─────┐│ │
│  │  │ Primary  │Secondary │Sec. ││ │
│  │  │(Read/Wrt)│(ReadOnly)│ ... ││ │
│  │  └──────────┴──────────┴─────┘│ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │     Sharding (Scale)           │ │
│  │  ┌──────┬──────┬──────┬──────┐│ │
│  │  │Shard1│Shard2│Shard3│Shard4││ │
│  │  └──────┴──────┴──────┴──────┘│ │
│  └────────────────────────────────┘ │
│                                      │
└─────────────────────────────────────┘
```

### MongoDB Query Examples

**Insert:**
```javascript
// Insert single document
db.customers.insertOne({
  name: "John Doe",
  email: "john@example.com",
  age: 30,
  address: {
    street: "123 Main St",
    city: "Seattle",
    state: "WA"
  },
  orders: []
})

// Insert multiple
db.customers.insertMany([
  {name: "Alice", email: "alice@example.com"},
  {name: "Bob", email: "bob@example.com"}
])
```

**Query:**
```javascript
// Find all
db.customers.find({})

// Find with filter
db.customers.find({age: {$gte: 25}})

// Find nested field
db.customers.find({"address.city": "Seattle"})

// Find in array
db.customers.find({tags: "premium"})

// Projection (select specific fields)
db.customers.find(
  {age: {$gte: 25}},
  {name: 1, email: 1, _id: 0}
)
```

**Update:**
```javascript
// Update single document
db.customers.updateOne(
  {email: "john@example.com"},
  {$set: {age: 31}}
)

// Update nested field
db.customers.updateOne(
  {email: "john@example.com"},
  {$set: {"address.city": "Portland"}}
)

// Add to array
db.customers.updateOne(
  {email: "john@example.com"},
  {$push: {orders: {orderId: 101, amount: 99.99}}}
)

// Increment counter
db.customers.updateOne(
  {email: "john@example.com"},
  {$inc: {orderCount: 1}}
)
```

**Aggregation Pipeline:**
```javascript
// Complex analytics (similar to SQL GROUP BY)
db.orders.aggregate([
  // Stage 1: Filter
  {$match: {status: "completed"}},
  
  // Stage 2: Group and aggregate
  {$group: {
    _id: "$customerId",
    totalSpent: {$sum: "$amount"},
    orderCount: {$sum: 1},
    avgOrderValue: {$avg: "$amount"}
  }},
  
  // Stage 3: Sort
  {$sort: {totalSpent: -1}},
  
  // Stage 4: Limit
  {$limit: 10}
])

// Result:
// Top 10 customers by spending
```

### Indexes in MongoDB

```javascript
// Create index (similar to SQL)
db.customers.createIndex({email: 1})

// Compound index
db.customers.createIndex({age: 1, city: 1})

// Text index (full-text search)
db.products.createIndex({description: "text"})

// Geospatial index
db.stores.createIndex({location: "2dsphere"})

// View indexes
db.customers.getIndexes()

// Query using index
db.customers.find({email: "john@example.com"})
// Uses email index for fast lookup
```

---

## Part 4: Azure Cosmos DB

### Cosmos DB Overview

**Azure Cosmos DB** = Globally distributed, multi-model database

**Key Features:**
```
✓ Multi-region replication (turnkey global distribution)
✓ Multiple APIs (MongoDB, SQL, Cassandra, Gremlin, Table)
✓ 99.999% SLA (five nines!)
✓ Single-digit millisecond latency
✓ Automatic indexing
✓ Serverless option
```

### Cosmos DB APIs

```
1. Core (SQL) API: JSON documents, SQL-like queries
2. MongoDB API: Compatible with MongoDB drivers
3. Cassandra API: Wide-column store
4. Gremlin API: Graph database
5. Table API: Key-value store
```

### Cosmos DB SQL API Example

**Query Cosmos DB with SQL-like syntax:**

```sql
-- Create container (similar to table)
-- (Done in Azure Portal or SDK)

-- Insert document
{
  "id": "customer_001",
  "name": "John Doe",
  "email": "john@example.com",
  "address": {
    "city": "Seattle",
    "state": "WA"
  },
  "orders": [
    {"orderId": 101, "amount": 99.99}
  ]
}

-- Query with SQL syntax
SELECT c.name, c.email, c.address.city
FROM customers c
WHERE c.address.city = "Seattle"

-- Aggregate
SELECT 
    c.address.city,
    COUNT(1) as customerCount,
    AVG(c.orderTotal) as avgOrderValue
FROM customers c
GROUP BY c.address.city

-- Join within document (array)
SELECT 
    c.name,
    o.orderId,
    o.amount
FROM customers c
JOIN o IN c.orders
WHERE o.amount > 100
```

### Partition Key in Cosmos DB

**Critical Design Decision:**

```json
// GOOD partition key: High cardinality, even distribution
{
  "id": "order_12345",
  "userId": "user_789",  // ✓ Good partition key
  "orderDate": "2024-11-09",
  "amount": 149.99
}

// Partition by userId:
// - Many unique values
// - Even distribution across users
// - Queries filter by userId

// BAD partition key: Low cardinality
{
  "id": "order_12345",
  "region": "West",  // ✗ Bad partition key (only 4 values)
  "orderDate": "2024-11-09",
  "amount": 149.99
}

// Only 4 partitions (North, South, East, West)
// Hot partition problem (uneven distribution)
```

### Cosmos DB Consistency Levels

**Tradeoff: Consistency vs Latency:**

```
1. Strong:
   ✓ Linearizability (like SQL ACID)
   ✗ Highest latency
   Use: Financial transactions

2. Bounded Staleness:
   ✓ Consistency within time/version lag
   ✓ Predictable staleness
   Use: Gaming leaderboards

3. Session:
   ✓ Consistent within user session
   ✓ Most common choice
   Use: Shopping cart

4. Consistent Prefix:
   ✓ Reads never see out-of-order writes
   Use: Social feeds

5. Eventual:
   ✓ Lowest latency
   ✗ May read stale data temporarily
   Use: Non-critical data
```

---

## Part 5: SQL Server with JSON

### JSON Support in SQL Server

**SQL Server can work with JSON documents:**

```sql
-- Store JSON in NVARCHAR column
CREATE TABLE CustomerProfiles (
    CustomerID INT PRIMARY KEY,
    ProfileData NVARCHAR(MAX)
);

-- Insert JSON document
INSERT INTO CustomerProfiles VALUES
(1, N'{
    "name": "John Doe",
    "email": "john@example.com",
    "preferences": {
        "newsletter": true,
        "theme": "dark"
    },
    "orders": [
        {"orderId": 101, "amount": 99.99},
        {"orderId": 102, "amount": 149.99}
    ]
}');

-- Query JSON with JSON_VALUE
SELECT 
    CustomerID,
    JSON_VALUE(ProfileData, '$.name') AS Name,
    JSON_VALUE(ProfileData, '$.email') AS Email,
    JSON_VALUE(ProfileData, '$.preferences.theme') AS Theme
FROM CustomerProfiles;

-- Query JSON array with OPENJSON
SELECT 
    CustomerID,
    o.orderId,
    o.amount
FROM CustomerProfiles
CROSS APPLY OPENJSON(ProfileData, '$.orders')
WITH (
    orderId INT '$.orderId',
    amount DECIMAL(10,2) '$.amount'
) AS o;

-- Update JSON property
UPDATE CustomerProfiles
SET ProfileData = JSON_MODIFY(
    ProfileData,
    '$.preferences.theme',
    'light'
)
WHERE CustomerID = 1;

-- Add item to JSON array
UPDATE CustomerProfiles
SET ProfileData = JSON_MODIFY(
    ProfileData,
    'append $.orders',
    JSON_QUERY('{"orderId": 103, "amount": 199.99}')
)
WHERE CustomerID = 1;
```

### When to Use SQL Server JSON vs Document DB

**Use SQL Server JSON:**
```
✓ Existing SQL Server infrastructure
✓ Mix of relational and document data
✓ ACID transactions required
✓ Complex joins between tables and JSON
✓ Small to medium JSON documents
```

**Use Document Database (MongoDB/Cosmos DB):**
```
✓ Large JSON documents (> 100KB)
✓ Primarily document-centric data
✓ Need horizontal scaling
✓ Flexible schema critical
✓ High write throughput
✓ Global distribution (Cosmos DB)
```

---

## Part 6: Migration Considerations

### SQL to Document Database Migration

**Challenges:**
```
1. Schema Design
   - Relational → Document model
   - Normalize → Denormalize
   - Joins → Embedding/Referencing

2. Queries
   - SQL → MongoDB query language / SQL API
   - JOINs → $lookup or embedding
   - Transactions → Document-level

3. Referential Integrity
   - Foreign keys → Application logic
   - Cascading deletes → Manual handling

4. Indexing
   - Similar concepts
   - Different syntax
   - Automatic in Cosmos DB
```

**Migration Pattern:**

```
Step 1: Analyze Relationships
- Identify entities
- Determine embedding vs referencing

Step 2: Design Document Schema
- Embed one-to-few
- Reference one-to-many
- Denormalize frequently accessed data

Step 3: Migrate Data
- ETL process
- Transform relational → JSON
- Validate data integrity

Step 4: Rewrite Queries
- SQL → Document query language
- Optimize for document model

Step 5: Test Performance
- Compare latency
- Load testing
- Optimize indexes
```

---

## Key Takeaways

### Document Database Concepts
```
1. JSON/BSON documents (not rows/columns)
2. Flexible schema (no ALTER TABLE)
3. Embedded vs referenced relationships
4. Denormalization common
5. Horizontal scaling built-in
```

### Design Patterns
```
EMBED:
✓ One-to-few (< 100 items)
✓ Data accessed together
✓ Read-heavy workloads

REFERENCE:
✓ One-to-many (> 100 items)
✓ Many-to-many
✓ Independent querying needed
```

### When to Use Document DB
```
✓ Flexible/evolving schema
✓ Hierarchical data
✓ Rapid development
✓ Horizontal scaling
✓ High write throughput
✗ Complex transactions
✗ Complex relationships
```

### Technologies
```
- MongoDB: Popular open-source
- Cosmos DB: Azure managed, global distribution
- SQL Server: JSON support (hybrid approach)
```

---

## Next Steps

**Continue to Lesson 17.11: Cloud Computing for Databases**  
Learn about Azure SQL, AWS RDS, scaling strategies, and cloud database options.

---

## Additional Resources

- **MongoDB University:** Free courses
- **Azure Cosmos DB Documentation**
- **SQL Server JSON functions**
- **Article:** SQL vs NoSQL decision guide
