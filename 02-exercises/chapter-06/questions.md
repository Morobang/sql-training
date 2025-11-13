# Chapter 6: Working with Sets - Practice Questions

## Overview
Master set operations: UNION, INTERSECT, EXCEPT/MINUS. Learn to combine query results and understand set theory in SQL.

---

## UNION Operations

### Question 1: UNION Basics (Easy)
What's the difference between UNION and UNION ALL?

```sql
-- Query A: UNION
SELECT city FROM customers
UNION
SELECT city FROM suppliers;

-- Query B: UNION ALL
SELECT city FROM customers
UNION ALL
SELECT city FROM suppliers;
```

<details>
<summary>Click to see answer</summary>

**Answer:**

**UNION:** Removes duplicate rows (slower, requires sorting)
**UNION ALL:** Keeps all rows including duplicates (faster, no deduplication)

**Example Data:**
```
Customers:          Suppliers:
city                city
New York            New York
Boston              Chicago
New York            New York
```

**UNION Result (3 rows):**
```
city
Boston
Chicago
New York
```
Duplicates removed, sorted.

**UNION ALL Result (6 rows):**
```
city
New York
Boston
New York
New York
Chicago
New York
```
All rows kept, original order preserved.

**Performance:**
- UNION ALL is faster (no duplicate check)
- Use UNION when you need unique values
- Use UNION ALL when duplicates are impossible or acceptable

**Rules for UNION:**
1. Same number of columns in each query
2. Compatible data types
3. Column names from first query used
</details>

---

### Question 2: UNION Requirements (Easy)
Why does this UNION fail?

```sql
SELECT customer_id, first_name, last_name FROM customers
UNION
SELECT supplier_id, company_name FROM suppliers;
```

<details>
<summary>Click to see answer</summary>

**Answer: Column count mismatch - customers has 3 columns, suppliers has 2**

**Problem:**
- First query: 3 columns (customer_id, first_name, last_name)
- Second query: 2 columns (supplier_id, company_name)

**Fixed version:**
```sql
-- Option 1: Match column counts with NULL
SELECT customer_id AS id, first_name, last_name FROM customers
UNION
SELECT supplier_id AS id, company_name, NULL AS last_name FROM suppliers;

-- Option 2: Concatenate names
SELECT customer_id AS id, CONCAT(first_name, ' ', last_name) AS name FROM customers
UNION
SELECT supplier_id AS id, company_name AS name FROM suppliers;

-- Option 3: Use only matching columns
SELECT customer_id AS id FROM customers
UNION
SELECT supplier_id AS id FROM suppliers;
```

**UNION Rules:**
1. ✅ **Same number of columns**
2. ✅ **Compatible data types** (can be implicitly converted)
3. ✅ **Same column order**
4. Column names come from first SELECT
</details>

---

### Question 3: Combining Customer Types (Medium)
Create a unified list of all contacts (customers and suppliers) with:
- ID
- Name (full name for customers, company name for suppliers)
- Type ('Customer' or 'Supplier')
- Email

Tables:
- customers (customer_id, first_name, last_name, email)
- suppliers (supplier_id, company_name, contact_email)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    customer_id AS id,
    CONCAT(first_name, ' ', last_name) AS name,
    'Customer' AS type,
    email
FROM customers

UNION ALL

SELECT 
    supplier_id AS id,
    company_name AS name,
    'Supplier' AS type,
    contact_email AS email
FROM suppliers

ORDER BY type, name;
```

**Key points:**
- UNION ALL (assuming no overlap between customer and supplier IDs)
- Add literal 'Customer'/'Supplier' to distinguish
- Alias columns to match
- ORDER BY at the end (applies to combined result)

**Can't do:**
```sql
-- ❌ WRONG: ORDER BY in individual SELECTs
SELECT customer_id, name FROM customers ORDER BY name  -- Error!
UNION
SELECT supplier_id, name FROM suppliers ORDER BY name;

-- ✅ CORRECT: ORDER BY after UNION
SELECT customer_id, name FROM customers
UNION
SELECT supplier_id, name FROM suppliers
ORDER BY name;
```
</details>

---

## INTERSECT Operations

### Question 4: INTERSECT Basics (Medium)
What does INTERSECT return?

```sql
SELECT city FROM customers
INTERSECT
SELECT city FROM suppliers;
```

<details>
<summary>Click to see answer</summary>

**Answer: Cities that appear in BOTH customers and suppliers tables**

**Example Data:**
```
Customers:          Suppliers:
city                city
New York            New York
Boston              Chicago
Seattle             New York
New York            Miami
```

**INTERSECT Result:**
```
city
New York
```

**How it works:**
- Returns only rows present in BOTH queries
- Automatically removes duplicates (like UNION, not UNION ALL)
- Set theory: A ∩ B (intersection)

**Equivalent using JOIN:**
```sql
SELECT DISTINCT c.city
FROM (SELECT DISTINCT city FROM customers) c
JOIN (SELECT DISTINCT city FROM suppliers) s
  ON c.city = s.city;
```

**MySQL Alternative (doesn't support INTERSECT):**
```sql
-- Method 1: IN with subquery
SELECT DISTINCT city FROM customers
WHERE city IN (SELECT city FROM suppliers);

-- Method 2: EXISTS
SELECT DISTINCT c.city
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM suppliers s WHERE s.city = c.city
);
```
</details>

---

### Question 5: Find Common Products (Medium)
Find products that are both:
- Ordered in 2024
- Currently in stock (stock_quantity > 0)

Tables:
- products (product_id, product_name, stock_quantity)
- order_items (order_item_id, product_id, order_date)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using INTERSECT (PostgreSQL, SQL Server)
SELECT product_id, product_name
FROM products
WHERE stock_quantity > 0

INTERSECT

SELECT p.product_id, p.product_name
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE YEAR(oi.order_date) = 2024;
```

**MySQL Alternative:**
```sql
SELECT DISTINCT p.product_id, p.product_name
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.stock_quantity > 0
  AND YEAR(oi.order_date) = 2024;
```

**Or using IN:**
```sql
SELECT product_id, product_name
FROM products
WHERE stock_quantity > 0
  AND product_id IN (
      SELECT DISTINCT product_id 
      FROM order_items 
      WHERE YEAR(order_date) = 2024
  );
```
</details>

---

## EXCEPT/MINUS Operations

### Question 6: EXCEPT Basics (Medium)
What does EXCEPT return?

```sql
SELECT city FROM customers
EXCEPT
SELECT city FROM suppliers;
```

<details>
<summary>Click to see answer</summary>

**Answer: Cities in customers but NOT in suppliers**

**Example Data:**
```
Customers:          Suppliers:
city                city
New York            New York
Boston              Chicago
Seattle             Miami
New York
Boston
```

**EXCEPT Result:**
```
city
Boston
Seattle
```

**How it works:**
- Returns rows in first query NOT in second query
- Automatically removes duplicates
- Set theory: A - B (difference)
- Order matters! (A EXCEPT B ≠ B EXCEPT A)

**Database differences:**
- PostgreSQL, SQL Server: `EXCEPT`
- Oracle: `MINUS`
- MySQL: Neither (use workarounds)

**MySQL Alternative:**
```sql
-- Method 1: NOT IN
SELECT DISTINCT city FROM customers
WHERE city NOT IN (SELECT city FROM suppliers);

-- Method 2: NOT EXISTS
SELECT DISTINCT c.city
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM suppliers s WHERE s.city = c.city
);

-- Method 3: LEFT JOIN + IS NULL
SELECT DISTINCT c.city
FROM customers c
LEFT JOIN suppliers s ON c.city = s.city
WHERE s.city IS NULL;
```
</details>

---

### Question 7: Find Customers Without Orders (Hard)
Find customers who have NEVER placed an order using EXCEPT.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using EXCEPT
SELECT customer_id, name
FROM customers

EXCEPT

SELECT c.customer_id, c.name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

**MySQL Alternative:**
```sql
-- Method 1: NOT IN
SELECT customer_id, name
FROM customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
);

-- Method 2: NOT EXISTS (usually fastest)
SELECT customer_id, name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- Method 3: LEFT JOIN + IS NULL
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

**Performance comparison:**
- NOT EXISTS: Generally fastest
- LEFT JOIN + IS NULL: Good for readability
- NOT IN: Can be slow, careful with NULLs
- EXCEPT: Clean syntax but not widely supported
</details>

---

## Complex Set Operations

### Question 8: Multiple Set Operations (Hard)
Find cities that are:
- In customers OR suppliers
- But NOT in employees

Use set operations.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using parentheses for operation order
(
    SELECT city FROM customers
    UNION
    SELECT city FROM suppliers
)
EXCEPT
SELECT city FROM employees;
```

**Breakdown:**
1. UNION combines customers and suppliers cities
2. EXCEPT removes cities that appear in employees

**Alternative approach:**
```sql
-- Step by step with CTEs
WITH contact_cities AS (
    SELECT city FROM customers
    UNION
    SELECT city FROM suppliers
)
SELECT city FROM contact_cities
EXCEPT
SELECT city FROM employees;
```

**MySQL version:**
```sql
WITH contact_cities AS (
    SELECT DISTINCT city FROM customers
    UNION
    SELECT DISTINCT city FROM suppliers
)
SELECT c.city
FROM contact_cities c
WHERE c.city NOT IN (SELECT city FROM employees);
```

**Set theory visualization:**
```
(Customers ∪ Suppliers) - Employees
```
</details>

---

### Question 9: Product Analysis (Expert)
Create a report showing products in different categories:
1. High value items (price > $500) sold in 2024
2. Low stock items (stock < 10) never ordered
3. Bestsellers (ordered more than 100 times)

Use set operations to create separate lists.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- High value items sold in 2024
SELECT 
    p.product_id,
    p.product_name,
    'High Value - 2024' AS category
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.price > 500
  AND YEAR(oi.order_date) = 2024

UNION ALL

-- Low stock items never ordered
SELECT 
    p.product_id,
    p.product_name,
    'Low Stock - No Orders' AS category
FROM products p
WHERE p.stock_quantity < 10
  AND p.product_id NOT IN (
      SELECT DISTINCT product_id FROM order_items
  )

UNION ALL

-- Bestsellers
SELECT 
    p.product_id,
    p.product_name,
    'Bestseller' AS category
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(*) > 100

ORDER BY category, product_name;
```

**Using UNION ALL because:**
- Products can't be in multiple categories simultaneously
- Faster than UNION (no duplicate check needed)
- Category label makes each row unique anyway

**Enhanced with counts:**
```sql
WITH high_value AS (
    SELECT DISTINCT p.product_id, p.product_name, p.price
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    WHERE p.price > 500 AND YEAR(oi.order_date) = 2024
),
low_stock_unordered AS (
    SELECT product_id, product_name, stock_quantity
    FROM products
    WHERE stock_quantity < 10
      AND product_id NOT IN (SELECT DISTINCT product_id FROM order_items)
),
bestsellers AS (
    SELECT p.product_id, p.product_name, COUNT(*) AS order_count
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name
    HAVING COUNT(*) > 100
)
SELECT 'High Value 2024' AS category, COUNT(*) AS product_count
FROM high_value
UNION ALL
SELECT 'Low Stock Unordered', COUNT(*) FROM low_stock_unordered
UNION ALL
SELECT 'Bestsellers', COUNT(*) FROM bestsellers;
```
</details>

---

## Combining JOINs and Set Operations

### Question 10: Customer Segmentation (Hard)
Create customer segments:
- VIP: Total orders > $10,000
- Regular: Total orders $1,000-$10,000
- Inactive: Registered but never ordered

Use UNION to combine segments.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- VIP Customers
SELECT 
    c.customer_id,
    c.name,
    'VIP' AS segment,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.total_amount) > 10000

UNION ALL

-- Regular Customers
SELECT 
    c.customer_id,
    c.name,
    'Regular' AS segment,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING SUM(o.total_amount) BETWEEN 1000 AND 10000

UNION ALL

-- Inactive Customers
SELECT 
    c.customer_id,
    c.name,
    'Inactive' AS segment,
    0 AS lifetime_value
FROM customers c
WHERE c.customer_id NOT IN (
    SELECT DISTINCT customer_id FROM orders
)

ORDER BY 
    CASE segment
        WHEN 'VIP' THEN 1
        WHEN 'Regular' THEN 2
        WHEN 'Inactive' THEN 3
    END,
    lifetime_value DESC;
```

**Alternative: Single query with CASE:**
```sql
SELECT 
    c.customer_id,
    c.name,
    CASE 
        WHEN COALESCE(SUM(o.total_amount), 0) > 10000 THEN 'VIP'
        WHEN COALESCE(SUM(o.total_amount), 0) >= 1000 THEN 'Regular'
        ELSE 'Inactive'
    END AS segment,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY lifetime_value DESC;
```

**UNION approach benefits:**
- Clearer logic for each segment
- Can apply different filters per segment
- Easier to modify individual segments

**Single query benefits:**
- Better performance (one scan)
- Simpler maintenance
- Easier to add calculated fields
</details>

---

## Set Operations vs JOINs

### Question 11: When to Use What? (Medium)
Explain when to use:
1. UNION vs JOIN
2. INTERSECT vs INNER JOIN
3. EXCEPT vs LEFT JOIN + IS NULL

<details>
<summary>Click to see answer</summary>

**Answer:**

### **1. UNION vs JOIN**

**Use UNION when:**
- Combining rows from similar tables (vertically stacking)
- Creating a unified list from different sources
- Results have same structure

```sql
-- UNION: Stack customers and suppliers
SELECT name, email FROM customers
UNION
SELECT company_name, contact_email FROM suppliers;
```

**Use JOIN when:**
- Combining columns from related tables (horizontally expanding)
- Showing relationships between data
- Need data from multiple tables per row

```sql
-- JOIN: Show customer with their orders
SELECT c.name, o.order_date, o.total
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

---

### **2. INTERSECT vs INNER JOIN**

**Use INTERSECT when:**
- Finding matching rows across complete datasets
- Both queries return same columns
- Want distinct values

```sql
-- INTERSECT: Cities in both lists
SELECT city FROM customers
INTERSECT
SELECT city FROM suppliers;
```

**Use INNER JOIN when:**
- Need columns from both tables
- Working with relationships (foreign keys)
- Need all matches (not just distinct)

```sql
-- INNER JOIN: Customer orders (with details from both tables)
SELECT c.name, o.order_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;
```

---

### **3. EXCEPT vs LEFT JOIN + IS NULL**

**Use EXCEPT when:**
- Finding difference between two similar queries
- Clean, set-theory approach
- Database supports it (not MySQL)

```sql
-- EXCEPT: Customers without orders
SELECT customer_id FROM customers
EXCEPT
SELECT customer_id FROM orders;
```

**Use LEFT JOIN + IS NULL when:**
- Need columns from left table
- More flexible filtering
- Works in all databases

```sql
-- LEFT JOIN: Customers without orders (with details)
SELECT c.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

**Performance note:** LEFT JOIN + IS NULL often faster than EXCEPT.

---

### **Quick Reference:**

| Task | Best Approach |
|------|---------------|
| Stack similar tables | UNION / UNION ALL |
| Combine related data | JOIN |
| Find common values | INTERSECT or IN |
| Find differences | EXCEPT or NOT IN |
| Find missing relationships | LEFT JOIN + IS NULL |
| Combine with calculations | JOIN |

</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 2 questions
- Medium: 5 questions
- Hard: 3 questions
- Expert: 1 question

**Topics Covered:**
- ✅ UNION vs UNION ALL
- ✅ UNION requirements and rules
- ✅ INTERSECT (common elements)
- ✅ EXCEPT/MINUS (differences)
- ✅ Combining set operations
- ✅ Set operations vs JOINs
- ✅ Customer segmentation
- ✅ Product analysis

**Key Takeaways:**
- UNION removes duplicates, UNION ALL doesn't
- All queries must have same number of columns
- INTERSECT = both sets (AND logic)
- EXCEPT = first set only (NOT logic)
- Order matters for EXCEPT
- Set operations are vertical, JOINs are horizontal
- MySQL doesn't support INTERSECT/EXCEPT (use alternatives)

**Next Steps:**
- Chapter 7: Data Generation and Manipulation
- Practice combining set operations with JOINs
- Build customer segmentation reports
