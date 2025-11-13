# Chapter 13: Indexes and Constraints - Practice Questions

## Overview
Master index types, index optimization, constraint types, performance analysis, and query tuning strategies.

---

## Index Fundamentals

### Question 1: Index Types Comparison (Medium)
Compare B-Tree, Hash, and Full-Text indexes with use cases.

<details>
<summary>Click to see answer</summary>

**Answer:**

**B-Tree Index** - Default, most common
```sql
CREATE INDEX idx_customer_email ON customers(email);
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_product_price ON products(price);

-- Best for:
-- - Range queries (BETWEEN, <, >)
-- - Sorting (ORDER BY)
-- - Prefix matching (LIKE 'abc%')
-- - Equality (=)
```

**Use cases:**
```sql
-- Range query - B-Tree excels
SELECT * FROM orders 
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Sorting - Uses index
SELECT * FROM products ORDER BY price DESC LIMIT 10;

-- Prefix search - Uses index
SELECT * FROM customers WHERE email LIKE 'john%';
```

---

**Hash Index** - Memory tables only (MySQL MEMORY engine)
```sql
CREATE TABLE session_data (
    session_id VARCHAR(32) PRIMARY KEY,
    user_id INT,
    data TEXT
) ENGINE=MEMORY;

-- Hash index automatically created on PRIMARY KEY

-- Best for:
-- - Exact match lookups (=)
-- - IN clauses
```

**Use cases:**
```sql
-- Perfect for hash index
SELECT * FROM session_data WHERE session_id = 'abc123def456';

-- NOT good for hash (won't use index):
SELECT * FROM session_data WHERE session_id LIKE 'abc%';  -- No
SELECT * FROM session_data WHERE session_id > 'abc';      -- No
```

---

**Full-Text Index** - Text search
```sql
CREATE FULLTEXT INDEX idx_product_description 
ON products(name, description);

-- Best for:
-- - Natural language search
-- - Keyword matching
-- - Relevance ranking
```

**Use cases:**
```sql
-- Full-text search
SELECT *, MATCH(name, description) AGAINST('wireless bluetooth headphones') AS relevance
FROM products
WHERE MATCH(name, description) AGAINST('wireless bluetooth headphones')
ORDER BY relevance DESC;

-- Boolean mode
SELECT * FROM products
WHERE MATCH(description) AGAINST('+wireless +bluetooth -wired' IN BOOLEAN MODE);

-- With query expansion
SELECT * FROM articles
WHERE MATCH(title, content) AGAINST('database' WITH QUERY EXPANSION);
```

---

**Comparison Table:**

| Feature | B-Tree | Hash | Full-Text |
|---------|--------|------|-----------|
| **Equality (=)** | ✅ Good | ✅ Excellent | ❌ No |
| **Range (<, >)** | ✅ Excellent | ❌ No | ❌ No |
| **LIKE 'abc%'** | ✅ Yes | ❌ No | ❌ No |
| **ORDER BY** | ✅ Yes | ❌ No | ✅ Relevance |
| **Text Search** | ❌ Poor | ❌ No | ✅ Excellent |
| **Storage** | Disk | Memory | Disk |
| **Size** | Medium | Small | Large |

---

**Spatial Indexes** (Bonus)
```sql
CREATE SPATIAL INDEX idx_location ON stores(location);

-- Geographic queries
SELECT * FROM stores
WHERE ST_Distance_Sphere(location, POINT(-122.4194, 37.7749)) < 5000;  -- 5km radius
```

**Best practices:**
- Use B-Tree for most cases (default)
- Full-Text for search features
- Hash for in-memory exact lookups
- Spatial for geographic data
</details>

---

### Question 2: Composite Indexes (Medium)
Explain index column order and the leftmost prefix rule.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Column order matters!**

```sql
-- Create composite index
CREATE INDEX idx_customer_search ON customers(last_name, first_name, email);

-- This index can serve multiple queries:
```

**Queries that USE the index:**
```sql
-- 1. All three columns
SELECT * FROM customers 
WHERE last_name = 'Smith' AND first_name = 'John' AND email = 'john@example.com';
-- ✅ Uses full index

-- 2. Leftmost column only
SELECT * FROM customers WHERE last_name = 'Smith';
-- ✅ Uses index (leftmost prefix)

-- 3. Leftmost two columns
SELECT * FROM customers WHERE last_name = 'Smith' AND first_name = 'John';
-- ✅ Uses index (leftmost prefix)
```

**Queries that DON'T use the index:**
```sql
-- 4. Skips leftmost column
SELECT * FROM customers WHERE first_name = 'John';
-- ❌ Cannot use index (doesn't start with last_name)

-- 5. Only rightmost column
SELECT * FROM customers WHERE email = 'john@example.com';
-- ❌ Cannot use index

-- 6. Middle and right columns
SELECT * FROM customers WHERE first_name = 'John' AND email = 'john@example.com';
-- ❌ Cannot use index
```

---

**Example: E-Commerce Queries**

```sql
-- Bad: Separate single-column indexes
CREATE INDEX idx_category ON products(category);
CREATE INDEX idx_brand ON products(brand);
CREATE INDEX idx_price ON products(price);

-- Query can only use ONE index
SELECT * FROM products
WHERE category = 'Electronics' AND brand = 'Apple' AND price < 1000;
-- MySQL picks best single index, ignores others

---

-- Good: Composite index based on query patterns
CREATE INDEX idx_product_search ON products(category, brand, price);

-- Now the query uses all three columns
SELECT * FROM products
WHERE category = 'Electronics' AND brand = 'Apple' AND price < 1000;
-- ✅ Uses entire index efficiently
```

---

**Column order strategy:**

**Rule 1: Put equality columns first, range columns last**
```sql
-- Good order: category (=), brand (=), price (range)
CREATE INDEX idx_products ON products(category, brand, price);

SELECT * FROM products
WHERE category = 'Electronics'  -- Equality
  AND brand = 'Apple'           -- Equality
  AND price < 1000;             -- Range
-- ✅ Optimal

-- Bad order: price first (range)
CREATE INDEX idx_products_bad ON products(price, category, brand);
-- Only uses price column, ignores category and brand
```

---

**Rule 2: High cardinality first**
```sql
-- Cardinality = number of distinct values

-- email: 1,000,000 distinct (high)
-- city: 500 distinct (medium)
-- gender: 2 distinct (low)

-- Good: High to low cardinality
CREATE INDEX idx_customers ON customers(email, city, gender);

-- Bad: Low to high cardinality
CREATE INDEX idx_customers_bad ON customers(gender, city, email);
-- gender='M' matches 500,000 rows (not selective)
```

---

**Rule 3: Order by most frequent query patterns**
```sql
-- If these are your common queries:
-- Q1: WHERE category = ? AND brand = ?           (90% of queries)
-- Q2: WHERE category = ? AND brand = ? AND price < ?  (9%)
-- Q3: WHERE category = ?                          (1%)

-- Optimize for Q1 and Q2:
CREATE INDEX idx_products ON products(category, brand, price);

-- All three queries can use this index:
-- Q1: Uses category + brand
-- Q2: Uses category + brand + price
-- Q3: Uses category only
```

---

**Index Merge (multiple indexes in one query):**
```sql
-- Sometimes MySQL can merge indexes
CREATE INDEX idx_category ON products(category);
CREATE INDEX idx_price ON products(price);

SELECT * FROM products
WHERE category = 'Electronics' OR price < 100;
-- May use index merge on both indexes

-- Check with EXPLAIN:
EXPLAIN SELECT * FROM products
WHERE category = 'Electronics' OR price < 100;
-- Look for "type: index_merge"
```

**Best practices:**
- Equality columns before range columns
- High cardinality before low cardinality
- Match your most common query patterns
- Don't create redundant indexes (leftmost prefix handles it)
- Use EXPLAIN to verify index usage
</details>

---

## Index Optimization

### Question 3: Covering Indexes (Hard)
What is a covering index? When should you use it?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Covering Index = Index contains ALL columns needed by query**
- No need to access table data
- Faster query execution
- "Index-only scan"

```sql
-- Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    status VARCHAR(20),
    -- other columns...
) ENGINE=InnoDB;

-- Common query
SELECT customer_id, order_date, total_amount
FROM orders
WHERE status = 'completed'
ORDER BY order_date DESC;
```

---

**Without covering index:**
```sql
CREATE INDEX idx_status ON orders(status);

-- Query execution:
-- 1. Use index to find rows with status='completed'
-- 2. For each row, access table to get customer_id, order_date, total_amount
-- 3. Sort by order_date

EXPLAIN SELECT customer_id, order_date, total_amount
FROM orders
WHERE status = 'completed'
ORDER BY order_date DESC;

-- Extra: Using filesort (needs to access table and sort)
```

---

**With covering index:**
```sql
CREATE INDEX idx_orders_covering ON orders(status, order_date, customer_id, total_amount);

-- Query execution:
-- 1. Scan index (all data is in index)
-- 2. No table access needed!
-- 3. Already sorted by order_date

EXPLAIN SELECT customer_id, order_date, total_amount
FROM orders
WHERE status = 'completed'
ORDER BY order_date DESC;

-- Extra: Using index; Using where (no filesort!)
```

---

**Performance comparison:**
```sql
-- Without covering: ~1000ms (table access for 100k rows)
-- With covering: ~50ms (index-only scan)
```

---

**Real-world example: Analytics Query**

```sql
-- Query: Monthly sales by product category
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    category,
    COUNT(*) AS order_count,
    SUM(amount) AS total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE order_date >= '2024-01-01'
GROUP BY DATE_FORMAT(order_date, '%Y-%m'), category;

-- Covering index for order_items
CREATE INDEX idx_orderitems_covering ON order_items(order_date, product_id, amount);

-- Covering index for products
CREATE INDEX idx_products_covering ON products(product_id, category);

-- Both joins use covering indexes, no table access needed
```

---

**When to use covering indexes:**

✅ **Good use cases:**
```sql
-- 1. Reporting queries (same columns selected repeatedly)
CREATE INDEX idx_report ON sales(region, product_category, sale_date, amount);

-- 2. API endpoints (specific columns always returned)
CREATE INDEX idx_api_users ON users(user_id, username, email, created_at);

-- 3. Aggregation queries
CREATE INDEX idx_metrics ON orders(customer_id, order_date, total_amount);

-- 4. Pagination
CREATE INDEX idx_pagination ON posts(status, created_at, id, title);
SELECT id, title FROM posts WHERE status = 'published' 
ORDER BY created_at DESC LIMIT 20 OFFSET 40;
```

❌ **Bad use cases:**
```sql
-- 1. Too many columns (index becomes huge)
CREATE INDEX idx_too_big ON customers(
    email, first_name, last_name, phone, address, city, state, zip, 
    country, created_at, updated_at
);  -- Index larger than table!

-- 2. Columns frequently updated (index maintenance overhead)
CREATE INDEX idx_volatile ON inventory(
    product_id, quantity, reserved, available, last_updated
);  -- Rebuilt on every stock change

-- 3. Low-selectivity WHERE columns
CREATE INDEX idx_poor ON orders(status, customer_id, total, created_at);
WHERE status IN ('pending', 'shipped', 'delivered')  -- 99% of rows
```

---

**Trade-offs:**

| Aspect | Benefit | Cost |
|--------|---------|------|
| **Query Speed** | ✅ Much faster (no table access) | |
| **Disk Space** | | ❌ Larger indexes |
| **Write Speed** | | ❌ Slower INSERTs/UPDATEs |
| **Index Maintenance** | | ❌ More index rebuilds |

---

**Check if query uses covering index:**
```sql
EXPLAIN SELECT customer_id, order_date, total_amount
FROM orders
WHERE status = 'completed'
ORDER BY order_date DESC;

-- Look for:
-- Extra: "Using index" ← Covering index used!
-- Extra: "Using where; Using index" ← Covering + filter
-- Extra: "Using filesort" ← Not fully covered

-- MySQL 8.0+: Use EXPLAIN FORMAT=TREE
EXPLAIN FORMAT=TREE
SELECT customer_id, order_date FROM orders WHERE status = 'completed';
-- Shows "index scan on idx_orders_covering"
```

**Best practices:**
- Use for frequent, performance-critical queries
- Include WHERE, JOIN, ORDER BY, SELECT columns
- Monitor index size vs query improvement
- Consider partial indexes if only some rows need coverage
- Balance read speed vs write overhead
</details>

---

## Constraints

### Question 4: Constraint Types (Easy)
Explain PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, and DEFAULT constraints.

<details>
<summary>Click to see answer</summary>

**Answer:**

**PRIMARY KEY** - Unique identifier for each row
```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(100)
);

-- Composite primary key
CREATE TABLE order_items (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id)
);

-- Rules:
-- - Only ONE primary key per table
-- - Cannot be NULL
-- - Must be unique
-- - Automatically creates clustered index (InnoDB)
```

---

**FOREIGN KEY** - Referential integrity
```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE          -- Delete orders when customer deleted
        ON UPDATE CASCADE          -- Update order customer_id when customer_id changes
);

-- Common ON DELETE options:
-- CASCADE: Delete child rows
-- SET NULL: Set foreign key to NULL
-- RESTRICT: Prevent deletion (default)
-- NO ACTION: Same as RESTRICT
-- SET DEFAULT: Set to default value

-- Example: Preserve history
CREATE TABLE order_history (
    order_id INT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE SET NULL  -- Keep order history even if customer deleted
);
```

---

**UNIQUE** - No duplicate values (NULL allowed)
```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(255) UNIQUE,         -- One unique email per user
    username VARCHAR(50) UNIQUE,
    ssn VARCHAR(11) UNIQUE
);

-- Composite unique constraint
CREATE TABLE inventory (
    warehouse_id INT,
    product_id INT,
    quantity INT,
    UNIQUE (warehouse_id, product_id)  -- Each product appears once per warehouse
);

-- Difference from PRIMARY KEY:
-- - Can have multiple UNIQUE constraints
-- - UNIQUE allows NULL values
-- - PRIMARY KEY doesn't allow NULL
```

---

**CHECK** - Validate data
```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2) CHECK (price >= 0),              -- No negative prices
    discount_pct INT CHECK (discount_pct BETWEEN 0 AND 100),
    stock_quantity INT CHECK (stock_quantity >= 0),
    status ENUM('active', 'discontinued', 'coming_soon')
);

-- Multiple conditions
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    birth_date DATE,
    hire_date DATE,
    salary DECIMAL(10,2),
    CHECK (hire_date >= birth_date),           -- Hired after birth
    CHECK (hire_date >= '1900-01-01'),         -- Reasonable hire date
    CHECK (salary > 0 AND salary < 1000000)    -- Salary range
);

-- Named constraint
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    balance DECIMAL(15,2),
    account_type VARCHAR(20),
    CONSTRAINT chk_balance_positive CHECK (balance >= 0),
    CONSTRAINT chk_account_type CHECK (account_type IN ('checking', 'savings', 'credit'))
);

-- Drop constraint by name
ALTER TABLE accounts DROP CONSTRAINT chk_balance_positive;
```

---

**DEFAULT** - Default value when not specified
```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,       -- Auto timestamp
    status VARCHAR(20) DEFAULT 'pending',                -- Default status
    shipping_country VARCHAR(2) DEFAULT 'US',
    is_gift BOOLEAN DEFAULT FALSE,
    tax_rate DECIMAL(5,4) DEFAULT 0.0825                -- 8.25% tax
);

INSERT INTO orders (customer_id) VALUES (123);
-- order_date = NOW(), status = 'pending', is_gift = FALSE, etc.

-- DEFAULT with expressions (MySQL 8.0+)
CREATE TABLE logs (
    log_id INT PRIMARY KEY,
    log_message TEXT,
    created_at DATETIME DEFAULT (NOW()),
    created_by VARCHAR(50) DEFAULT (USER()),
    day_of_week VARCHAR(10) DEFAULT (DAYNAME(NOW()))
);
```

---

**Combining constraints:**
```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE CHECK (LENGTH(username) >= 3),
    email VARCHAR(255) NOT NULL UNIQUE CHECK (email LIKE '%_@_%._%'),
    age INT CHECK (age >= 18 AND age <= 120),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    credits DECIMAL(10,2) DEFAULT 0.00 CHECK (credits >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (referred_by) REFERENCES users(user_id) ON DELETE SET NULL
);
```

**Best practices:**
- PRIMARY KEY on every table (business key or surrogate)
- FOREIGN KEY for referential integrity (prevents orphaned records)
- UNIQUE for natural keys (email, username, SSN)
- CHECK for business rules (age >= 18, price >= 0)
- DEFAULT for sensible defaults (status, timestamps)
- Name constraints for easier management
</details>

---

## Performance Analysis

### Question 5: Reading EXPLAIN Output (Hard)
Analyze this EXPLAIN and identify performance issues:

```sql
EXPLAIN SELECT c.name, COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'US'
GROUP BY c.customer_id
HAVING COUNT(o.order_id) > 5
ORDER BY order_count DESC
LIMIT 10;
```

<details>
<summary>Click to see answer</summary>

**Answer:**

**EXPLAIN output columns:**

| Column | Meaning | Good Value | Bad Value |
|--------|---------|------------|-----------|
| **type** | Join type | const, eq_ref, ref | ALL, index |
| **possible_keys** | Indexes considered | Multiple options | NULL |
| **key** | Index actually used | Index name | NULL |
| **key_len** | Bytes of index used | Higher (more columns) | - |
| **ref** | Column compared | const, column | - |
| **rows** | Estimated rows scanned | Low | High |
| **filtered** | % of rows filtered | High (90%+) | Low (<10%) |
| **Extra** | Additional info | Using index | Using filesort, Using temporary |

---

**Example bad EXPLAIN:**
```sql
+----+-------------+-------+------+---------------+------+---------+------+--------+----------------------------------------------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows   | Extra                                              |
+----+-------------+-------+------+---------------+------+---------+------+--------+----------------------------------------------------+
|  1 | SIMPLE      | c     | ALL  | NULL          | NULL | NULL    | NULL | 500000 | Using where; Using temporary; Using filesort       |
|  1 | SIMPLE      | o     | ALL  | NULL          | NULL | NULL    | NULL | 200000 | Using where; Using join buffer (Block Nested Loop) |
+----+-------------+-------+------+---------------+------+---------+------+--------+----------------------------------------------------+
```

**Problems identified:**
1. ❌ **type = ALL** - Full table scan on both tables
2. ❌ **key = NULL** - No indexes used
3. ❌ **rows = 500,000** - Scanning entire customers table
4. ❌ **Extra: Using temporary** - Creating temp table for GROUP BY
5. ❌ **Extra: Using filesort** - Sorting results (slow)
6. ❌ **Extra: Using join buffer** - No index for join

---

**Optimization steps:**

**Step 1: Add index on WHERE condition**
```sql
CREATE INDEX idx_customers_country ON customers(country);

-- New EXPLAIN:
-- type: ref (better!)
-- key: idx_customers_country
-- rows: 250,000 (half of table)
```

---

**Step 2: Add index on JOIN column**
```sql
CREATE INDEX idx_orders_customer ON orders(customer_id);

-- New EXPLAIN:
-- type: ref (uses index for join)
-- No more "Using join buffer"
```

---

**Step 3: Create covering index for customers**
```sql
-- Query needs: country (WHERE), customer_id (GROUP BY), name (SELECT)
CREATE INDEX idx_customers_covering ON customers(country, customer_id, name);

-- New EXPLAIN:
-- Extra: Using index (covering index!)
```

---

**Step 4: Covering index for orders (aggressive optimization)**
```sql
CREATE INDEX idx_orders_covering ON orders(customer_id, order_id);

-- Now both tables use covering indexes
```

---

**Optimized EXPLAIN:**
```sql
+----+-------------+-------+-------+-----------------------+-----------------------+---------+-----------+-------+----------------------------------------------+
| id | select_type | table | type  | possible_keys         | key                   | key_len | ref       | rows  | Extra                                        |
+----+-------------+-------+-------+-----------------------+-----------------------+---------+-----------+-------+----------------------------------------------+
|  1 | SIMPLE      | c     | ref   | idx_customers_covering| idx_customers_covering| 10      | const     | 250K  | Using where; Using index                     |
|  1 | SIMPLE      | o     | ref   | idx_orders_covering   | idx_orders_covering   | 4       | c.cust_id | 5     | Using index                                  |
+----+-------------+-------+-------+-----------------------+-----------------------+---------+-----------+-------+----------------------------------------------+

-- Improvements:
-- ✅ type: ref (index lookup)
-- ✅ key: Uses indexes
-- ✅ Using index (covering)
-- ✅ rows: Much lower
-- ❌ Still has: Using temporary, Using filesort (unavoidable for GROUP BY + ORDER BY)
```

---

**Further optimization: Rewrite query**
```sql
-- Original query requires GROUP BY + ORDER BY on aggregated results
-- Can't avoid temporary table and filesort entirely

-- But we can reduce data early:
WITH us_customers AS (
    SELECT customer_id, name
    FROM customers
    WHERE country = 'US'
),
customer_orders AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    WHERE customer_id IN (SELECT customer_id FROM us_customers)
    GROUP BY customer_id
    HAVING COUNT(*) > 5
)
SELECT c.name, co.order_count
FROM us_customers c
JOIN customer_orders co ON c.customer_id = co.customer_id
ORDER BY co.order_count DESC
LIMIT 10;

-- Or use subquery for pre-filtering:
SELECT c.name, COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'US'
  AND c.customer_id IN (
      SELECT customer_id 
      FROM orders 
      GROUP BY customer_id 
      HAVING COUNT(*) > 5
  )
GROUP BY c.customer_id
ORDER BY order_count DESC
LIMIT 10;
```

---

**EXPLAIN tips:**

```sql
-- Detailed EXPLAIN (MySQL 8.0+)
EXPLAIN ANALYZE
SELECT ...;
-- Shows actual execution time, not just estimates

-- Visual EXPLAIN (MySQL Workbench)
EXPLAIN FORMAT=TREE
SELECT ...;

-- JSON format (full details)
EXPLAIN FORMAT=JSON
SELECT ...;
```

**What to look for:**
1. **type**: Aim for const > eq_ref > ref > range. Avoid ALL, index.
2. **key**: Should use appropriate index
3. **rows**: Lower is better
4. **Extra**:
   - ✅ Good: "Using index", "Using where"
   - ⚠️ Caution: "Using filesort", "Using temporary"
   - ❌ Bad: "Using join buffer (Block Nested Loop)"

</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 2 questions
- Hard: 2 questions

**Topics Covered:**
- ✅ Index types (B-Tree, Hash, Full-Text)
- ✅ Composite indexes and leftmost prefix
- ✅ Covering indexes
- ✅ All constraint types
- ✅ EXPLAIN analysis

**Key Takeaways:**
- B-Tree for most scenarios
- Column order matters in composite indexes
- Covering indexes eliminate table access
- Constraints enforce data integrity
- EXPLAIN reveals performance bottlenecks

**Next Steps:**
- Chapter 14: Views
- Practice creating optimal indexes for real queries
