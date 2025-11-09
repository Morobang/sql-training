# Lesson 17.7: Sharding for Horizontal Scalability

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand sharding concepts and architecture
2. Design effective shard key strategies
3. Implement sharding patterns
4. Handle cross-shard queries and transactions
5. Evaluate when sharding is appropriate

## Business Context

**Sharding** enables horizontal scaling beyond single-server limits. When a database grows to billions of rows or thousands of transactions per second, vertical scaling (bigger server) becomes prohibitively expensive or impossible. Sharding distributes data across multiple database servers.

**Time:** 50 minutes  
**Level:** Advanced

---

## Part 1: What is Sharding?

### Definition

**Sharding** = Horizontal partitioning across multiple database servers

- **Partition:** Divides table within single server
- **Sharding:** Divides table across multiple servers
- Each shard = independent database instance
- Application logic routes requests to correct shard

### Real-World Analogy

**Library System:**
- **Non-sharded:** All books in one library (single server)
- **Sharded:** Books distributed across multiple libraries by category
  - Library A: Fiction (A-M)
  - Library B: Fiction (N-Z)
  - Library C: Non-Fiction (A-M)
  - Library D: Non-Fiction (N-Z)

**Finding a book:**
- Look up which library has it (routing logic)
- Go to that specific library (shard)
- Much faster than searching one massive library

---

## Part 2: Sharding vs Partitioning vs Replication

### Comparison Table

| Aspect | Partitioning | Sharding | Replication (AG) |
|--------|-------------|----------|------------------|
| **Servers** | Single | Multiple | Multiple |
| **Purpose** | Performance | Scalability | Availability |
| **Data Distribution** | Logical split | Physical split | Full copies |
| **Capacity** | Limited to 1 server | Sum of all shards | Same as primary |
| **Write Scaling** | No | Yes | No |
| **Read Scaling** | No | Yes | Yes |
| **Complexity** | Low | High | Medium |
| **Failover** | N/A | App handles | Automatic |
| **Cross-partition Queries** | Easy (same DB) | Difficult (multiple DBs) | Easy (one DB) |

### Visual Comparison

```
PARTITIONING (Single Server):
┌─────────────────────────────┐
│   Database Server           │
│  ┌──────┬──────┬──────┐    │
│  │Part 1│Part 2│Part 3│    │
│  │2022  │2023  │2024  │    │
│  └──────┴──────┴──────┘    │
└─────────────────────────────┘

SHARDING (Multiple Servers):
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Shard 1  │  │ Shard 2  │  │ Shard 3  │
│ Server A │  │ Server B │  │ Server C │
│  2022    │  │  2023    │  │  2024    │
└──────────┘  └──────────┘  └──────────┘

REPLICATION (Always On):
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Primary  │  │Secondary1│  │Secondary2│
│ ALL Data │  │ ALL Data │  │ ALL Data │
│ Read/Wrt │  │ Read Only│  │ Read Only│
└──────────┘  └──────────┘  └──────────┘
```

---

## Part 3: Shard Key Design

### What is a Shard Key?

**Shard Key** = Column(s) that determine which shard holds the data

Critical characteristics:
- **High cardinality:** Many unique values
- **Even distribution:** No hot shards
- **Immutable:** Cannot change after insert
- **Query-aligned:** Appears in most WHERE clauses

### Shard Key Strategies

#### Strategy 1: Range-Based Sharding

**Divide by value ranges:**

```
CustomerID ranges:
Shard 1: CustomerID 1 - 1,000,000
Shard 2: CustomerID 1,000,001 - 2,000,000
Shard 3: CustomerID 2,000,001 - 3,000,000
Shard 4: CustomerID 3,000,001+

Routing Logic:
IF CustomerID <= 1000000 THEN Shard1
ELSE IF CustomerID <= 2000000 THEN Shard2
ELSE IF CustomerID <= 3000000 THEN Shard3
ELSE Shard4
```

**Pros:**
```
✓ Simple to understand
✓ Easy to add shards (new ranges)
✓ Range queries efficient (may hit one shard)
✓ Sequential IDs work well
```

**Cons:**
```
✗ May create hot shards (recent data)
✗ Uneven distribution if data skewed
✗ Rebalancing difficult
```

**Best For:**
- Time-series data (OrderDate)
- Sequential IDs
- Append-only workloads

#### Strategy 2: Hash-Based Sharding

**Use hash function to distribute:**

```
Hash(CustomerID) % 4:

CustomerID 12345 → Hash = 987654 → 987654 % 4 = 2 → Shard 2
CustomerID 67890 → Hash = 123456 → 123456 % 4 = 0 → Shard 0
CustomerID 11111 → Hash = 555555 → 555555 % 4 = 3 → Shard 3

Routing Logic:
ShardID = Hash(CustomerID) % NumberOfShards
```

**Pros:**
```
✓ Even distribution
✓ No hot shards
✓ Predictable performance
✓ Works with any data type
```

**Cons:**
```
✗ Range queries hit all shards
✗ Adding shards requires resharding
✗ Hash function must be consistent
```

**Best For:**
- User data (UserID)
- Random access patterns
- Need even load distribution

#### Strategy 3: Geographic/Directory-Based Sharding

**Shard by geography or lookup table:**

```
Region-based:
Shard 1: North America
Shard 2: Europe
Shard 3: Asia
Shard 4: Latin America

Directory Table:
┌────────────┬──────────┐
│ Region     │ ShardID  │
├────────────┼──────────┤
│ US-East    │ 1        │
│ US-West    │ 1        │
│ UK         │ 2        │
│ Germany    │ 2        │
│ Japan      │ 3        │
│ Australia  │ 3        │
│ Brazil     │ 4        │
└────────────┴──────────┘

Routing Logic:
1. Lookup Region → ShardID in directory
2. Route to that shard
```

**Pros:**
```
✓ Clear data locality
✓ Compliance friendly (data residency)
✓ Easy to understand
✓ Regional queries very fast
```

**Cons:**
```
✗ May have uneven distribution
✗ Requires directory service
✗ Directory = single point of failure
✗ Cross-region queries expensive
```

**Best For:**
- Multi-tenant SaaS applications
- Geographic compliance requirements
- Regional data sovereignty

#### Strategy 4: Entity/Tenant-Based Sharding

**Shard by customer/tenant:**

```
SaaS Application:
Shard 1: Customers A-F (TenantID 1-500)
Shard 2: Customers G-L (TenantID 501-1000)
Shard 3: Customers M-R (TenantID 1001-1500)
Shard 4: Customers S-Z (TenantID 1501-2000)

Routing Logic:
ShardID = Lookup TenantID in directory
All data for tenant on same shard
```

**Pros:**
```
✓ Perfect tenant isolation
✓ All tenant data co-located
✓ No cross-shard queries per tenant
✓ Easy tenant migration
✓ Compliance/security benefits
```

**Cons:**
```
✗ Large tenants may overwhelm shard
✗ Small tenants waste resources
✗ Cross-tenant analytics difficult
```

**Best For:**
- Multi-tenant SaaS
- B2B applications
- Strong isolation requirements

### Choosing Shard Key: Decision Matrix

```
┌────────────────────────────────────────────────────────┐
│ YOUR QUERY PATTERNS                                    │
├────────────────────────────────────────────────────────┤
│                                                         │
│ Most queries filter by single customer/tenant?         │
│     YES → TENANT-BASED sharding                        │
│                                                         │
│ Data has strong geographic locality?                   │
│     YES → GEOGRAPHIC sharding                          │
│                                                         │
│ Need even load distribution?                           │
│     YES → HASH-BASED sharding                          │
│                                                         │
│ Time-series or sequential access?                      │
│     YES → RANGE-BASED sharding                         │
│                                                         │
│ Complex requirements?                                   │
│     YES → COMPOSITE (combine methods)                  │
│                                                         │
└────────────────────────────────────────────────────────┘
```

---

## Part 4: Sharding Architecture Patterns

### Pattern 1: Application-Level Sharding

**Application routes requests:**

```
┌─────────────────────────────────────┐
│         Application Layer           │
│  ┌─────────────────────────────┐   │
│  │  Shard Routing Logic        │   │
│  │  - Parse query              │   │
│  │  - Extract shard key        │   │
│  │  - Route to correct shard   │   │
│  └─────────┬────────┬──────────┘   │
└────────────┼────────┼──────────────┘
             │        │
     ┌───────┘        └────────┐
     ▼                         ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Shard 1 │  │ Shard 2 │  │ Shard 3 │
│ DB 1    │  │ DB 2    │  │ DB 3    │
└─────────┘  └─────────┘  └─────────┘
```

**Implementation (C# example):**

```csharp
public class ShardRouter
{
    private Dictionary<int, string> _shardConnections;
    
    public ShardRouter()
    {
        _shardConnections = new Dictionary<int, string>
        {
            { 0, "Server=Shard1;Database=CustomerDB;" },
            { 1, "Server=Shard2;Database=CustomerDB;" },
            { 2, "Server=Shard3;Database=CustomerDB;" },
            { 3, "Server=Shard4;Database=CustomerDB;" }
        };
    }
    
    public int GetShardId(int customerId)
    {
        // Hash-based routing
        return customerId % 4;
    }
    
    public string GetConnection(int customerId)
    {
        int shardId = GetShardId(customerId);
        return _shardConnections[shardId];
    }
    
    public Customer GetCustomer(int customerId)
    {
        string connectionString = GetConnection(customerId);
        using (var conn = new SqlConnection(connectionString))
        {
            conn.Open();
            var cmd = new SqlCommand(
                "SELECT * FROM Customers WHERE CustomerID = @id", 
                conn
            );
            cmd.Parameters.AddWithValue("@id", customerId);
            // Execute and return customer
        }
    }
}
```

**Pros:**
```
✓ Full control over routing logic
✓ No additional infrastructure
✓ Can optimize per application needs
```

**Cons:**
```
✗ Application must handle all routing
✗ Code complexity increases
✗ Every app needs routing logic
```

### Pattern 2: Proxy-Based Sharding

**Middleware routes requests:**

```
┌─────────────────────────────────────┐
│         Application Layer           │
│  (Connects to proxy, shard-agnostic)│
└─────────────────┬───────────────────┘
                  │
        ┌─────────▼──────────┐
        │   Shard Proxy      │
        │  - Parse queries   │
        │  - Route to shards │
        │  - Merge results   │
        └─┬─────┬───────┬───┘
          │     │       │
     ┌────┘     │       └─────┐
     ▼          ▼             ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Shard 1 │ │ Shard 2 │ │ Shard 3 │
└─────────┘ └─────────┘ └─────────┘

Examples:
- Azure SQL Database Elastic Pools
- Vitess (MySQL)
- Citus (PostgreSQL)
- Custom proxy service
```

**Pros:**
```
✓ Application shard-agnostic
✓ Centralized routing logic
✓ Can handle cross-shard queries
✓ Easier to maintain
```

**Cons:**
```
✗ Proxy = single point of failure (need HA)
✗ Additional latency
✗ Infrastructure complexity
```

### Pattern 3: Federated Database

**Database federation layer:**

```
SQL Server Elastic Database Tools:
- Shard Map Manager
- Data-dependent routing
- Multi-shard querying
- Split-merge tool

Architecture:
┌────────────────────────────┐
│  Shard Map Manager DB      │
│  (Stores shard mappings)   │
└──────────┬─────────────────┘
           │
┌──────────▼──────────────────┐
│  Application with           │
│  Elastic Database Client    │
└──┬──────┬──────────┬────────┘
   │      │          │
   ▼      ▼          ▼
Shard1  Shard2   Shard3
```

---

## Part 5: Cross-Shard Challenges

### Challenge 1: Cross-Shard Queries

**Problem:** Data split across multiple databases

**Query Example:**
```sql
-- Get all orders > $1000 from all customers
-- Data on 4 shards!

-- NON-SHARDED (simple):
SELECT CustomerID, COUNT(*) as OrderCount, SUM(Amount) as Total
FROM Orders
WHERE Amount > 1000
GROUP BY CustomerID;

-- SHARDED (complex):
-- Must query each shard separately and merge results
```

**Solutions:**

**A) Fan-Out Query (Application merges):**
```csharp
public async Task<List<OrderSummary>> GetHighValueOrders()
{
    var tasks = new List<Task<List<OrderSummary>>>();
    
    // Query each shard in parallel
    for (int shardId = 0; shardId < 4; shardId++)
    {
        tasks.Add(QueryShard(shardId, 
            "SELECT CustomerID, COUNT(*) as OrderCount, SUM(Amount) as Total " +
            "FROM Orders WHERE Amount > 1000 GROUP BY CustomerID"
        ));
    }
    
    // Wait for all shards
    var allResults = await Task.WhenAll(tasks);
    
    // Merge results (aggregate across shards)
    return MergeResults(allResults);
}
```

**B) Pre-Aggregation Table:**
```sql
-- Materialized view across all shards
-- Updated periodically

CREATE TABLE OrderSummary_Global (
    CustomerID INT,
    OrderCount INT,
    TotalAmount DECIMAL(18,2),
    LastUpdated DATETIME
);

-- Batch job merges from all shards
```

**C) Reporting Database:**
```
ETL Pipeline:
Shard 1 ──┐
Shard 2 ──┤
Shard 3 ──┼──→ Extract → Transform → Load → Reporting DB
Shard 4 ──┘

Reporting DB has all data (not sharded)
Use for analytics, not transactional queries
```

### Challenge 2: Cross-Shard Transactions

**Problem:** ACID transactions across multiple shards

**Scenario:**
```sql
-- Transfer money between customers on different shards
BEGIN TRANSACTION
    -- Customer A on Shard 1
    UPDATE Accounts SET Balance = Balance - 100 
    WHERE CustomerID = 12345;
    
    -- Customer B on Shard 3
    UPDATE Accounts SET Balance = Balance + 100 
    WHERE CustomerID = 67890;
COMMIT;

-- Traditional transaction doesn't work across databases!
```

**Solution 1: Two-Phase Commit (2PC)**
```
Phase 1: PREPARE
- Shard 1: Can you commit? (VOTE)
- Shard 3: Can you commit? (VOTE)

Phase 2: COMMIT
- If all YES → COMMIT on all shards
- If any NO → ROLLBACK on all shards

Problems:
✗ Slow (network round-trips)
✗ Blocking (holds locks)
✗ Not available in Azure SQL
```

**Solution 2: Saga Pattern (Eventual Consistency)**
```
Step 1: Debit Account A (Shard 1)
    → Success → Continue
    → Failure → Return error

Step 2: Credit Account B (Shard 3)
    → Success → Done!
    → Failure → COMPENSATE (refund Account A)

Compensation:
- Undo previous steps
- Credit back to Account A
- Log failure

Pros: No distributed transaction
Cons: Eventual consistency, more complex
```

**Solution 3: Avoid Cross-Shard Transactions**
```
✓ Design shard key so related data co-located
✓ Use entity-based sharding (all customer data together)
✓ Denormalize to keep data on same shard
✓ Accept eventual consistency where possible
```

### Challenge 3: Shard Rebalancing

**Problem:** Adding/removing shards

**Scenario: Add 5th shard to 4-shard system:**

```
Before (Hash % 4):
Customer 1 → Shard 1
Customer 2 → Shard 2
Customer 3 → Shard 3
Customer 4 → Shard 0
Customer 5 → Shard 1
...

After (Hash % 5):
Customer 1 → Shard 1 ✓ (same)
Customer 2 → Shard 2 ✓ (same)
Customer 3 → Shard 3 ✓ (same)
Customer 4 → Shard 4 ✗ (MOVED!)
Customer 5 → Shard 0 ✗ (MOVED!)
...

Problem: 80% of data moves shards!
```

**Solution: Consistent Hashing**
```
Virtual Shards:
- Create 100 virtual shards
- Map 25 virtual shards → Shard 1
- Map 25 virtual shards → Shard 2
- Map 25 virtual shards → Shard 3
- Map 25 virtual shards → Shard 4

Add Shard 5:
- Only remap 20 virtual shards to Shard 5
- 80% of data stays in place
- Minimal data movement
```

---

## Part 6: When to Shard (and When NOT to)

### When to Shard

```
✓ Database > 1TB and growing
✓ Write throughput exceeds single server (>10K TPS)
✓ Read throughput exceeds vertical scaling
✓ Clear shard key exists
✓ Data naturally partitionable
✓ Budget for complexity (engineering time)
✓ Can accept eventual consistency
```

### When NOT to Shard

```
✗ Database < 500GB
✗ Vertical scaling still affordable
✗ Heavy cross-shard queries
✗ ACID transactions critical
✗ Small engineering team
✗ Frequent schema changes
✗ No clear shard key
```

### Alternatives to Sharding

| Alternative | Best For | Complexity |
|-------------|----------|------------|
| **Vertical Scaling** | < 1TB, moderate load | Low |
| **Read Replicas** | Read-heavy workload | Medium |
| **Caching (Redis)** | Hot data access | Medium |
| **Partitioning** | Large tables, single server | Medium |
| **CQRS** | Different read/write patterns | High |
| **Cloud Auto-scale** | Variable workload | Low-Medium |

---

## Practical Exercise

### Exercise: Design Sharding Strategy

**Scenario:** Social media platform

- **Users:** 500 million
- **Posts:** 50 billion
- **Writes:** 100K posts/second
- **Reads:** 1M reads/second
- **Query patterns:**
  - User timeline (posts by UserID)
  - Global trending (all posts)
  - User profile (all user data)

**Design Challenge:**

1. **Choose shard key for Users table**
2. **Choose shard key for Posts table**
3. **How many shards?**
4. **Handle "trending posts" query**

**Solution:**

```
USERS TABLE:
Shard Key: UserID (Hash-based)
Sharding: Hash(UserID) % 16 shards
Reasoning:
- Even distribution (no hot users)
- All user data co-located
- Profile queries hit one shard

POSTS TABLE:
Shard Key: UserID (NOT PostID!)
Sharding: Hash(UserID) % 16 shards
Reasoning:
- User timeline = single shard query
- Co-located with user data
- Accept cross-shard for trending

NUMBER OF SHARDS:
16 shards initially
Reasoning:
- 500M users / 16 = ~31M users per shard
- 50B posts / 16 = ~3B posts per shard
- Room to grow to 32 shards with consistent hashing

TRENDING POSTS:
Solution: Separate Analytics Database
- Stream posts to Kafka
- Process in real-time (Spark/Flink)
- Aggregate to Redis cache
- Don't query shards for trending
```

---

## Key Takeaways

### Core Concepts
```
1. Sharding = Horizontal partitioning across servers
2. Enables scale beyond single server limits
3. Shard key is critical design decision
4. Application must handle routing
5. Cross-shard operations are expensive
```

### Shard Key Selection
```
✓ High cardinality
✓ Even distribution
✓ Query-aligned
✓ Immutable
✗ Low cardinality (few values)
✗ Skewed distribution
✗ Rarely in WHERE clause
```

### Challenges
```
1. Cross-shard queries → Fan-out + merge
2. Cross-shard transactions → Saga pattern
3. Schema changes → Coordinate across shards
4. Rebalancing → Consistent hashing
5. Monitoring → Each shard separately
```

### Best Practices
```
1. Shard only when necessary (> 1TB)
2. Design shard key carefully (hard to change)
3. Avoid cross-shard transactions
4. Use proxy/middleware for routing
5. Plan for rebalancing from day 1
6. Monitor each shard independently
7. Automate shard management
```

---

## Next Steps

**Continue to Lesson 17.8: Big Data Concepts**  
Learn about handling massive datasets with big data technologies beyond traditional RDBMS.

---

## Additional Resources

- **Azure SQL Database Elastic Scale**
- **Vitess:** MySQL sharding (YouTube)
- **Citus:** PostgreSQL sharding
- **Consistent Hashing:** Distributed systems patterns
