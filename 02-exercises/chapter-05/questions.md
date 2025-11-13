# Chapter 5: Querying Multiple Tables - Practice Questions

## Overview
Master JOINs: INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL JOIN, CROSS JOIN, and self-joins. Learn to combine data from multiple tables effectively.

---

## Basic JOIN Concepts

### Question 1: What is a JOIN? (Easy)
Explain what a JOIN does and why it's needed.

<details>
<summary>Click to see answer</summary>

**Answer: A JOIN combines rows from two or more tables based on a related column**

**Why we need JOINs:**
- Data is **normalized** (split across multiple tables to reduce redundancy)
- JOINs **reconstruct** the relationships for queries
- Avoids duplicating data

**Example:**

**Without normalization (bad):**
```
Orders table:
order_id | customer_name | customer_email      | product
1        | John Doe      | john@email.com     | Laptop
2        | John Doe      | john@email.com     | Mouse  ← Duplicate customer info!
```

**With normalization (good):**
```
Customers:
customer_id | name     | email
1           | John Doe | john@email.com

Orders:
order_id | customer_id | product
1        | 1           | Laptop
2        | 1           | Mouse
```

**JOIN to get complete info:**
```sql
SELECT 
    o.order_id,
    c.name AS customer_name,
    c.email,
    o.product
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;
```
</details>

---

### Question 2: INNER JOIN (Easy)
What does this query return?

```sql
SELECT 
    c.customer_id,
    c.name,
    o.order_id
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;
```

<details>
<summary>Click to see answer</summary>

**Answer: Only customers who have placed orders (and their order details)**

**INNER JOIN behavior:**
- Returns rows where the join condition is TRUE in **BOTH** tables
- Excludes customers with no orders
- Excludes orphaned orders (if any)

**Example Data:**

```
Customers:              Orders:
customer_id | name      order_id | customer_id
1          | Alice     101      | 1
2          | Bob       102      | 1
3          | Charlie   103      | 3
```

**Result:**
```
customer_id | name    | order_id
1          | Alice   | 101
1          | Alice   | 102
3          | Charlie | 103
```

**Note:** Bob (customer_id = 2) is excluded because he has no orders.

**Syntax variations:**
```sql
-- Explicit INNER JOIN
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id

-- Implicit (comma syntax - old style, avoid)
FROM customers c, orders o
WHERE c.customer_id = o.customer_id

-- Just "JOIN" (INNER is default)
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
```
</details>

---

## LEFT JOIN

### Question 3: LEFT JOIN vs INNER JOIN (Medium)
What's the difference between INNER JOIN and LEFT JOIN?

```sql
-- Query A: INNER JOIN
SELECT c.name, o.order_id
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- Query B: LEFT JOIN
SELECT c.name, o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
```

<details>
<summary>Click to see answer</summary>

**Answer:**

**INNER JOIN:** Only customers **with** orders
**LEFT JOIN:** **All** customers, even those without orders

**Example Data:**
```
Customers:              Orders:
customer_id | name      order_id | customer_id
1          | Alice     101      | 1
2          | Bob       102      | 1
3          | Charlie   (no orders)
```

**INNER JOIN result:**
```
name    | order_id
Alice   | 101
Alice   | 102
```
Charlie is excluded (no orders).

**LEFT JOIN result:**
```
name    | order_id
Alice   | 101
Alice   | 102
Charlie | NULL     ← Included with NULL for order_id
```

**Visualization:**
```
INNER JOIN:           LEFT JOIN:
┌─────────┐          ┌─────────┐
│    A    │          │    A    │
│  ┌──┐  │          │  ┌──┐   │
│  │AB│  │          │  │AB│ B │
│  └──┘  │          │  └──┘   │
│    B    │          └─────────┘
└─────────┘          
 Returns              Returns all
 overlap              from left +
 only                 overlap
```
</details>

---

### Question 4: Find Customers Without Orders (Medium)
Write a query to find customers who have **never** placed an order.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT c.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

**How it works:**
1. LEFT JOIN includes all customers
2. Customers without orders have NULL in order columns
3. WHERE filters to only NULL order_id (no orders)

**Alternative methods:**

```sql
-- Method 2: NOT IN
SELECT * FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
);

-- Method 3: NOT EXISTS (usually fastest)
SELECT * FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- Method 4: EXCEPT (if supported)
SELECT customer_id FROM customers
EXCEPT
SELECT customer_id FROM orders;
```

**Performance comparison:**
- **NOT EXISTS**: Generally fastest (stops at first match)
- **LEFT JOIN + IS NULL**: Good, straightforward
- **NOT IN**: Can be slow, watch for NULLs
</details>

---

## RIGHT JOIN

### Question 5: RIGHT JOIN (Easy)
Rewrite this LEFT JOIN as a RIGHT JOIN:

```sql
SELECT c.name, o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
```

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT c.name, o.order_id
FROM orders o
RIGHT JOIN customers c ON o.customer_id = c.customer_id;
```

**Explanation:**
- LEFT JOIN keeps all from **left** table (customers)
- RIGHT JOIN keeps all from **right** table (customers)
- Just swap table order and change LEFT to RIGHT

**In practice:**
- Most developers use LEFT JOIN exclusively
- RIGHT JOIN can confuse readers
- Better to reorder tables and use LEFT JOIN

**Why avoid RIGHT JOIN:**
```sql
-- ❌ Confusing: RIGHT JOIN
FROM orders o
RIGHT JOIN customers c ON ...

-- ✅ Clear: LEFT JOIN
FROM customers c
LEFT JOIN orders o ON ...
```
</details>

---

## Multiple JOINs

### Question 6: Three-Table JOIN (Medium)
Write a query showing:
- Customer name
- Order date
- Product name

Tables:
- customers (customer_id, name)
- orders (order_id, customer_id, order_date)
- order_items (order_item_id, order_id, product_id)
- products (product_id, product_name)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.name AS customer_name,
    o.order_date,
    p.product_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY c.name, o.order_date;
```

**Join chain:**
1. customers → orders (via customer_id)
2. orders → order_items (via order_id)
3. order_items → products (via product_id)

**With additional details:**
```sql
SELECT 
    c.name AS customer_name,
    c.email,
    o.order_id,
    o.order_date,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
ORDER BY o.order_date DESC, c.name;
```
</details>

---

### Question 7: LEFT JOIN Chain (Hard)
Modify the query above to include customers even if they have no orders.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.name AS customer_name,
    o.order_date,
    p.product_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
ORDER BY c.name;
```

**Important:** All JOINs must be LEFT to preserve customers without orders!

**What happens with mixed JOINs?**
```sql
-- ❌ WRONG: INNER JOIN after LEFT JOIN
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
-- This becomes effectively an INNER JOIN!
-- Because NULL from orders can't match order_items

-- ✅ CORRECT: All LEFT
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
```

**Result will include:**
- Customers with orders and products
- Customers with orders but no products (NULL product_name)
- Customers with no orders at all (NULL everything)
</details>

---

## CROSS JOIN

### Question 8: CROSS JOIN (Medium)
What does a CROSS JOIN do? Give an example.

<details>
<summary>Click to see answer</summary>

**Answer: CROSS JOIN creates a Cartesian product - every row from table A combined with every row from table B**

**Example:**

```sql
-- Colors table
CREATE TABLE colors (color VARCHAR(20));
INSERT INTO colors VALUES ('Red'), ('Blue'), ('Green');

-- Sizes table
CREATE TABLE sizes (size VARCHAR(20));
INSERT INTO sizes VALUES ('Small'), ('Medium'), ('Large');

-- CROSS JOIN
SELECT c.color, s.size
FROM colors c
CROSS JOIN sizes s;
```

**Result (3 × 3 = 9 rows):**
```
color  | size
Red    | Small
Red    | Medium
Red    | Large
Blue   | Small
Blue   | Medium
Blue   | Large
Green  | Small
Green  | Medium
Green  | Large
```

**Syntax variations:**
```sql
-- Explicit CROSS JOIN
FROM colors c CROSS JOIN sizes s

-- Implicit (comma - old style)
FROM colors c, sizes s

-- Result is the same
```

**Use cases:**
```sql
-- 1. Generate all product variants
SELECT 
    p.product_name,
    c.color,
    s.size
FROM base_products p
CROSS JOIN colors c
CROSS JOIN sizes s;

-- 2. Generate date series × categories
SELECT 
    d.date,
    c.category
FROM date_dimension d
CROSS JOIN categories c;

-- 3. Create test data combinations
```

**⚠️ Warning:** Be careful with large tables!
- 1,000 × 1,000 = 1,000,000 rows
- Can cause performance issues
</details>

---

## Self-Joins

### Question 9: Self-Join (Hard)
You have an employees table with employee_id and manager_id (which references employee_id). Write a query showing each employee with their manager's name.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    e.employee_id,
    e.name AS employee_name,
    m.name AS manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY e.employee_id;
```

**How it works:**
- Same table joined to itself
- Use different aliases (e, m)
- e.manager_id references m.employee_id

**Example data:**
```
employees table:
employee_id | name       | manager_id
1          | CEO Alice   | NULL
2          | Manager Bob | 1
3          | Dev Charlie | 2
4          | Dev Diana   | 2
```

**Result:**
```
employee_id | employee_name | manager_name
1          | CEO Alice     | NULL         ← CEO has no manager
2          | Manager Bob   | CEO Alice
3          | Dev Charlie   | Manager Bob
4          | Dev Diana     | Manager Bob
```

**Why LEFT JOIN?**
- CEO has NULL manager_id
- INNER JOIN would exclude CEO
- LEFT JOIN keeps all employees

**More complex example - hierarchy with levels:**
```sql
-- Show employee, manager, and manager's manager
SELECT 
    e.name AS employee,
    m1.name AS manager,
    m2.name AS director
FROM employees e
LEFT JOIN employees m1 ON e.manager_id = m1.employee_id
LEFT JOIN employees m2 ON m1.manager_id = m2.employee_id;
```
</details>

---

### Question 10: Find Hierarchies (Expert)
Find all employees who report to 'Manager Bob' (directly or indirectly).

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using recursive CTE (Common Table Expression)
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Start with Manager Bob
    SELECT employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE name = 'Manager Bob'
    
    UNION ALL
    
    -- Recursive case: Find employees reporting to previous level
    SELECT e.employee_id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    name,
    level,
    REPEAT('  ', level - 1) || name AS indented_name
FROM employee_hierarchy
WHERE level > 1  -- Exclude Manager Bob himself
ORDER BY level, name;
```

**Example hierarchy:**
```
1. CEO Alice
   2. Manager Bob ← Starting point
      3. Dev Charlie
      3. Dev Diana
      3. Lead Emma
         4. Junior Frank
         4. Junior Grace
```

**Result:**
```
employee_id | name         | level | indented_name
3          | Dev Charlie   | 2     |   Dev Charlie
4          | Dev Diana     | 2     |   Dev Diana
5          | Lead Emma     | 2     |   Lead Emma
6          | Junior Frank  | 3     |     Junior Frank
7          | Junior Grace  | 3     |     Junior Grace
```

**Alternative (without recursion - limited depth):**
```sql
-- Show up to 2 levels down
SELECT DISTINCT e2.name
FROM employees e1
JOIN employees e2 ON e2.manager_id = e1.employee_id
WHERE e1.name = 'Manager Bob'

UNION

SELECT DISTINCT e3.name
FROM employees e1
JOIN employees e2 ON e2.manager_id = e1.employee_id
JOIN employees e3 ON e3.manager_id = e2.employee_id
WHERE e1.name = 'Manager Bob';
```
</details>

---

## JOIN Conditions

### Question 11: Multiple Join Conditions (Medium)
Write a query to find order items where the product category matches the customer's preferred category.

Tables:
- customers (customer_id, name, preferred_category)
- orders (order_id, customer_id)
- order_items (order_id, product_id)
- products (product_id, product_name, category)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.name AS customer_name,
    c.preferred_category,
    p.product_name,
    p.category
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id 
               AND p.category = c.preferred_category  -- Additional condition!
ORDER BY c.name;
```

**Multiple conditions in ON clause:**
```sql
-- Method 1: Multiple conditions in ON
JOIN products p ON oi.product_id = p.product_id 
               AND p.category = c.preferred_category

-- Method 2: Additional WHERE filter (same result for INNER JOIN)
JOIN products p ON oi.product_id = p.product_id
WHERE p.category = c.preferred_category

-- For LEFT JOIN, placement matters!
LEFT JOIN products p ON oi.product_id = p.product_id 
                    AND p.category = c.preferred_category  -- Filter before join
-- vs
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.category = c.preferred_category  -- Filter after join (becomes INNER!)
```
</details>

---

## Complex JOIN Scenarios

### Question 12: Aggregate with JOIN (Hard)
Find customers with total order value > $1,000. Show customer name and total spent.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name
HAVING SUM(oi.quantity * oi.unit_price) > 1000
ORDER BY total_spent DESC;
```

**Breakdown:**
1. JOIN tables to connect customers → orders → order_items
2. Calculate line total: quantity × unit_price
3. GROUP BY customer
4. SUM all line totals per customer
5. HAVING filters groups (total > $1,000)
6. ORDER BY amount spent

**Common mistake:**
```sql
-- ❌ WRONG: WHERE with aggregate
WHERE SUM(oi.quantity * oi.unit_price) > 1000  -- ERROR!

-- ✅ CORRECT: HAVING with aggregate
HAVING SUM(oi.quantity * oi.unit_price) > 1000
```

**Enhanced version:**
```sql
SELECT 
    c.customer_id,
    c.name,
    c.email,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_items,
    SUM(oi.quantity * oi.unit_price) AS total_spent,
    AVG(oi.quantity * oi.unit_price) AS avg_order_value,
    MAX(o.order_date) AS last_order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name, c.email
HAVING SUM(oi.quantity * oi.unit_price) > 1000
ORDER BY total_spent DESC;
```
</details>

---

### Question 13: Sales Report (Expert)
Create a comprehensive sales report showing:
- Product name
- Category
- Total quantity sold
- Total revenue
- Number of unique customers who bought it
- Average order quantity
- Only products sold to at least 5 different customers

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS total_quantity_sold,
    ROUND(AVG(oi.quantity), 2) AS avg_quantity_per_order,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price) / SUM(oi.quantity), 2) AS avg_price_per_unit
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_id, p.product_name, p.category
HAVING COUNT(DISTINCT o.customer_id) >= 5
ORDER BY total_revenue DESC;
```

**Output example:**
```
product_name | category    | unique_customers | total_orders | total_quantity_sold | avg_quantity_per_order | total_revenue | avg_price_per_unit
Laptop       | Electronics | 45               | 67           | 89                  | 1.33                   | 88,999.11    | 999.99
Mouse        | Accessories | 123              | 245          | 456                 | 1.86                   | 11,385.44    | 24.97
```

**Key techniques:**
- COUNT(DISTINCT ...) for unique counts
- Multiple aggregations in same query
- GROUP BY all non-aggregated columns
- HAVING with aggregate conditions
- Calculated columns (total_revenue, avg_price)
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 3 questions
- Medium: 5 questions
- Hard: 3 questions
- Expert: 2 questions

**Topics Covered:**
- ✅ INNER JOIN - intersection
- ✅ LEFT JOIN - all from left table
- ✅ RIGHT JOIN - all from right table
- ✅ CROSS JOIN - Cartesian product
- ✅ Self-joins - table joined to itself
- ✅ Multiple JOINs - chaining tables
- ✅ JOIN with aggregates
- ✅ Multiple join conditions
- ✅ Finding missing relationships

**Key Takeaways:**
- INNER JOIN = only matches
- LEFT JOIN = all from left + matches
- Use LEFT JOIN + IS NULL to find missing data
- Self-joins use same table with different aliases
- Recursive CTEs for hierarchies
- WHERE vs HAVING with aggregates

**Next Steps:**
- Chapter 6: Working with Sets (UNION, INTERSECT, EXCEPT)
- Practice with complex multi-table scenarios
- Build real-world reporting queries
