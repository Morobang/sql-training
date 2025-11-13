# Chapter 3: Query Primer - Practice Questions

## Overview
Master SELECT statements, FROM, WHERE, GROUP BY, HAVING, and ORDER BY clauses.

---

## SELECT Clause Questions

### Question 1: Basic SELECT (Easy)
What does this query return?

```sql
SELECT * FROM customers;
```

<details>
<summary>Click to see answer</summary>

**Answer: All columns and all rows from the customers table**

**Best Practice - Avoid SELECT *:**
```sql
-- ❌ Bad: Returns unnecessary columns, slower
SELECT * FROM customers;

-- ✅ Good: Specify only needed columns
SELECT customer_id, first_name, last_name, email
FROM customers;
```

**Why avoid SELECT *?**
- Retrieves unused columns
- Slower performance
- Breaks if table structure changes
- Uses more network bandwidth
</details>

---

### Question 2: Column Aliases (Easy)
Write a query to select `first_name` and `last_name` from customers, displaying them as "First Name" and "Last Name"

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    first_name AS 'First Name',
    last_name AS 'Last Name'
FROM customers;
```

**Alternative syntax:**
```sql
-- Method 1: AS keyword with quotes (for spaces)
SELECT 
    first_name AS 'First Name',
    last_name AS 'Last Name'
FROM customers;

-- Method 2: AS keyword without quotes
SELECT 
    first_name AS FirstName,
    last_name AS LastName
FROM customers;

-- Method 3: Implicit alias (no AS)
SELECT 
    first_name FirstName,
    last_name LastName
FROM customers;
```
</details>

---

### Question 3: Calculated Columns (Medium)
Create a query showing `product_name`, `price`, and a calculated column for price with 20% tax added. Label it "Price with Tax".

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    product_name,
    price,
    price * 1.20 AS 'Price with Tax'
FROM products;
```

**Advanced - Formatted:**
```sql
SELECT 
    product_name,
    price AS original_price,
    ROUND(price * 1.20, 2) AS price_with_tax,
    ROUND(price * 0.20, 2) AS tax_amount,
    CONCAT('$', FORMAT(price * 1.20, 2)) AS formatted_price
FROM products;
```

**Output Example:**
```
product_name  | original_price | price_with_tax | tax_amount | formatted_price
Laptop        | 999.99        | 1199.99        | 200.00     | $1,199.99
Mouse         | 24.99         | 29.99          | 5.00       | $29.99
```
</details>

---

## FROM Clause Questions

### Question 4: Table Alias (Easy)
Rewrite using table alias `c` for customers:

```sql
SELECT customers.first_name, customers.last_name
FROM customers
WHERE customers.customer_id = 1;
```

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT c.first_name, c.last_name
FROM customers c
WHERE c.customer_id = 1;
```

**Alternative with AS:**
```sql
SELECT c.first_name, c.last_name
FROM customers AS c
WHERE c.customer_id = 1;
```

**When are aliases useful?**
- Joining multiple tables
- Self-joins
- Shorter, more readable code
</details>

---

## WHERE Clause Questions

### Question 5: Simple Filter (Easy)
Write a query to find all customers with last name 'Smith'

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT *
FROM customers
WHERE last_name = 'Smith';
```

**Case sensitivity depends on database:**
```sql
-- MySQL (default case-insensitive)
WHERE last_name = 'smith'  -- Matches 'Smith', 'SMITH', 'smith'

-- PostgreSQL (case-sensitive)
WHERE last_name = 'Smith'  -- Only matches exact case

-- Case-insensitive in PostgreSQL
WHERE LOWER(last_name) = LOWER('smith')
-- Or
WHERE last_name ILIKE 'smith'
```
</details>

---

### Question 6: Multiple Conditions (Medium)
Find customers whose last name is 'Smith' AND who registered after January 1, 2024

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT *
FROM customers
WHERE last_name = 'Smith'
  AND registration_date > '2024-01-01';
```

**Variations:**
```sql
-- Using >= to include January 1st
WHERE last_name = 'Smith'
  AND registration_date >= '2024-01-01'

-- Date range
WHERE last_name = 'Smith'
  AND registration_date BETWEEN '2024-01-01' AND '2024-12-31'

-- Multiple OR conditions with AND
WHERE last_name = 'Smith'
  AND (registration_date > '2024-01-01' OR city = 'New York')
```
</details>

---

### Question 7: IN Operator (Medium)
Find all products where category is 'Electronics', 'Computers', or 'Accessories'

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT *
FROM products
WHERE category IN ('Electronics', 'Computers', 'Accessories');
```

**Alternative (less efficient):**
```sql
SELECT *
FROM products
WHERE category = 'Electronics'
   OR category = 'Computers'
   OR category = 'Accessories';
```

**With NOT IN:**
```sql
-- Find products NOT in these categories
SELECT *
FROM products
WHERE category NOT IN ('Electronics', 'Computers', 'Accessories');
```
</details>

---

### Question 8: LIKE Pattern Matching (Medium)
Find all customers whose email ends with '@gmail.com'

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT *
FROM customers
WHERE email LIKE '%@gmail.com';
```

**LIKE Wildcards:**
```sql
-- % = any number of characters
WHERE email LIKE '%@gmail.com'      -- Ends with @gmail.com
WHERE email LIKE 'john%'            -- Starts with john
WHERE email LIKE '%gmail%'          -- Contains gmail

-- _ = exactly one character
WHERE phone LIKE '___-___-____'     -- Format: 123-456-7890
WHERE name LIKE 'J_hn'              -- Matches John, Jean (4 chars)

-- Combined
WHERE email LIKE 'j%@%.com'         -- Starts with j, ends with .com
```

**Case-insensitive matching:**
```sql
-- MySQL
WHERE email LIKE '%@gmail.com'  -- Already case-insensitive

-- PostgreSQL
WHERE email ILIKE '%@gmail.com'  -- Case-insensitive
WHERE email LIKE '%@gmail.com'   -- Case-sensitive
```
</details>

---

### Question 9: NULL Handling (Hard)
Find all customers who have NOT provided a phone number

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT *
FROM customers
WHERE phone IS NULL;
```

**⚠️ Common mistakes:**
```sql
-- ❌ WRONG - doesn't work with NULL
WHERE phone = NULL

-- ✅ CORRECT
WHERE phone IS NULL

-- Find customers WITH phone
WHERE phone IS NOT NULL

-- Find NULL or empty string
WHERE phone IS NULL OR phone = ''
```

**Why NULL is special:**
```sql
-- NULL = unknown, not zero or empty
SELECT 
    NULL = NULL,      -- Returns NULL (not TRUE!)
    NULL <> NULL,     -- Returns NULL
    NULL > 5,         -- Returns NULL
    NULL + 10,        -- Returns NULL
    NULL IS NULL;     -- Returns TRUE
```

**Handling NULL in calculations:**
```sql
SELECT 
    first_name,
    COALESCE(phone, 'No phone') AS phone_number,
    IFNULL(email, 'No email') AS email_address
FROM customers;
```
</details>

---

## GROUP BY & HAVING Questions

### Question 10: Count Records (Easy)
Count how many customers are in the database

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT COUNT(*) AS total_customers
FROM customers;
```

**Variations:**
```sql
-- Count non-NULL values in specific column
SELECT COUNT(phone) AS customers_with_phone
FROM customers;

-- Count DISTINCT values
SELECT COUNT(DISTINCT city) AS unique_cities
FROM customers;

-- Multiple aggregates
SELECT 
    COUNT(*) AS total_customers,
    COUNT(phone) AS with_phone,
    COUNT(DISTINCT city) AS unique_cities
FROM customers;
```
</details>

---

### Question 11: GROUP BY (Medium)
Count how many customers are in each city

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;
```

**Detailed example:**
```sql
SELECT 
    city,
    COUNT(*) AS total_customers,
    COUNT(phone) AS customers_with_phone,
    ROUND(AVG(YEAR(CURDATE()) - YEAR(registration_date)), 1) AS avg_years_member
FROM customers
GROUP BY city
ORDER BY total_customers DESC;
```

**Multiple GROUP BY columns:**
```sql
SELECT 
    city,
    state,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city, state
ORDER BY state, city;
```
</details>

---

### Question 12: HAVING Clause (Hard)
Find cities with more than 10 customers

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city
HAVING COUNT(*) > 10
ORDER BY customer_count DESC;
```

**WHERE vs HAVING:**
```sql
-- ❌ WRONG - WHERE can't use aggregate functions
SELECT city, COUNT(*) AS customer_count
FROM customers
WHERE COUNT(*) > 10  -- ERROR!
GROUP BY city;

-- ✅ CORRECT - Use HAVING for aggregates
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
HAVING COUNT(*) > 10;

-- Use both WHERE (before grouping) and HAVING (after grouping)
SELECT 
    city,
    COUNT(*) AS customer_count
FROM customers
WHERE registration_date >= '2024-01-01'  -- Filter rows first
GROUP BY city
HAVING COUNT(*) > 10  -- Filter groups second
ORDER BY customer_count DESC;
```
</details>

---

## ORDER BY Questions

### Question 13: Sort Results (Easy)
List all products sorted by price from lowest to highest

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT product_name, price
FROM products
ORDER BY price ASC;  -- ASC is default, can be omitted
```

**Variations:**
```sql
-- Descending (highest first)
ORDER BY price DESC

-- Multiple columns
ORDER BY category ASC, price DESC

-- By column position (not recommended)
SELECT product_name, price
FROM products
ORDER BY 2;  -- Orders by 2nd column (price)

-- By calculated column
SELECT 
    product_name,
    price,
    price * 0.20 AS tax
FROM products
ORDER BY tax DESC;
```
</details>

---

## Complex Query Questions

### Question 14: Complete Query (Hard)
Write a query to find:
- Products in 'Electronics' category
- With price between $50 and $500
- Sort by price descending
- Show only product name and price

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    product_name,
    price
FROM products
WHERE category = 'Electronics'
  AND price BETWEEN 50 AND 500
ORDER BY price DESC;
```

**With additional details:**
```sql
SELECT 
    product_name,
    price,
    stock_quantity,
    CASE 
        WHEN stock_quantity = 0 THEN 'Out of Stock'
        WHEN stock_quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS availability
FROM products
WHERE category = 'Electronics'
  AND price BETWEEN 50 AND 500
ORDER BY price DESC;
```
</details>

---

### Question 15: Sales Report (Expert)
Create a sales report showing:
- Each product name
- Total quantity sold
- Total revenue
- Only products with revenue > $1,000
- Sorted by revenue (highest first)

Assume tables:
- products (product_id, product_name, price)
- order_items (order_item_id, product_id, quantity)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * p.price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.quantity * p.price) > 1000
ORDER BY total_revenue DESC;
```

**Enhanced version with formatting:**
```sql
SELECT 
    p.product_name,
    p.price AS unit_price,
    SUM(oi.quantity) AS total_quantity_sold,
    CONCAT('$', FORMAT(SUM(oi.quantity * p.price), 2)) AS total_revenue,
    ROUND(SUM(oi.quantity * p.price) / SUM(oi.quantity), 2) AS avg_order_value
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.price
HAVING SUM(oi.quantity * p.price) > 1000
ORDER BY total_revenue DESC
LIMIT 10;  -- Top 10 products
```

**Output Example:**
```
product_name | unit_price | total_quantity_sold | total_revenue | avg_order_value
Laptop       | 999.99     | 45                  | $44,999.55   | 999.99
Monitor      | 299.99     | 78                  | $23,399.22   | 299.99
```
</details>

---

## Query Execution Order

### Question 16: Understanding Query Order (Hard)
SQL queries are written in one order but executed in a different order. What is the execution order?

```sql
SELECT product_name, SUM(quantity) AS total
FROM order_items
WHERE quantity > 0
GROUP BY product_name
HAVING SUM(quantity) > 100
ORDER BY total DESC
LIMIT 10;
```

<details>
<summary>Click to see answer</summary>

**Answer: Execution Order**

1. **FROM** - Get data from tables
2. **WHERE** - Filter individual rows
3. **GROUP BY** - Group rows
4. **HAVING** - Filter groups
5. **SELECT** - Choose columns & calculate
6. **ORDER BY** - Sort results
7. **LIMIT** - Limit number of rows

**Written Order vs Execution Order:**

```
Written Order:        Execution Order:
1. SELECT            1. FROM
2. FROM              2. WHERE
3. WHERE             3. GROUP BY
4. GROUP BY          4. HAVING
5. HAVING            5. SELECT
6. ORDER BY          6. ORDER BY
7. LIMIT             7. LIMIT
```

**Why this matters:**
- Can't use column alias in WHERE
- Can use alias in ORDER BY
- HAVING happens after GROUP BY
- WHERE happens before GROUP BY
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 5 questions
- Medium: 6 questions
- Hard: 4 questions
- Expert: 1 question

**Topics Covered:**
- ✅ SELECT clause & column aliases
- ✅ FROM clause & table aliases
- ✅ WHERE conditions (=, >, <, BETWEEN, IN, LIKE)
- ✅ NULL handling (IS NULL, IS NOT NULL)
- ✅ Aggregate functions (COUNT, SUM, AVG)
- ✅ GROUP BY & HAVING
- ✅ ORDER BY (ASC, DESC)
- ✅ Query execution order

**Next Steps:**
- Move to Chapter 4 (Advanced Filtering)
- Practice with Sakila database
- Build complex multi-table queries
