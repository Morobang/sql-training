# Chapter 4: Filtering - Practice Questions

## Overview
Master advanced filtering techniques: condition evaluation, parentheses, NOT operator, range conditions, membership, pattern matching, and NULL handling.

---

## Condition Evaluation Questions

### Question 1: AND vs OR (Easy)
What's the difference between these two queries?

```sql
-- Query A
SELECT * FROM products
WHERE price > 100 AND category = 'Electronics';

-- Query B
SELECT * FROM products
WHERE price > 100 OR category = 'Electronics';
```

<details>
<summary>Click to see answer</summary>

**Answer:**

**Query A (AND):** Returns products that are BOTH expensive ($100+) AND in Electronics category
- More restrictive
- Fewer results
- Both conditions must be TRUE

**Query B (OR):** Returns products that are EITHER expensive OR in Electronics (or both)
- Less restrictive
- More results
- At least one condition must be TRUE

**Example Data:**
```
Product      | Price  | Category
Laptop       | 999    | Electronics    ← Both queries
Cheap Phone  | 50     | Electronics    ← Only Query B
Expensive Desk| 500   | Furniture      ← Only Query B
Cheap Pen    | 5      | Office         ← Neither query
```
</details>

---

### Question 2: Using Parentheses (Medium)
What results does this query return?

```sql
SELECT * FROM products
WHERE (category = 'Electronics' OR category = 'Computers')
  AND price < 500;
```

<details>
<summary>Click to see answer</summary>

**Answer: Products in Electronics OR Computers category with price under $500**

**Parentheses control evaluation order:**

```sql
-- WITH parentheses (correct grouping)
WHERE (category = 'Electronics' OR category = 'Computers')
  AND price < 500
-- Returns: (Electronics OR Computers) AND (price < 500)

-- WITHOUT parentheses (wrong!)
WHERE category = 'Electronics' OR category = 'Computers'
  AND price < 500
-- Returns: Electronics OR (Computers AND price < 500)
-- Due to AND having higher precedence than OR
```

**Example Results:**
```
Product      | Category      | Price  | Included?
Laptop       | Computers     | 450    | ✅ Yes
Mouse        | Electronics   | 25     | ✅ Yes
Server       | Computers     | 2000   | ❌ No (too expensive)
Phone        | Electronics   | 300    | ✅ Yes
Desk         | Furniture     | 200    | ❌ No (wrong category)
```
</details>

---

### Question 3: NOT Operator (Medium)
Write a query to find products NOT in 'Electronics', 'Computers', or 'Accessories' categories

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Method 1: NOT IN
SELECT * FROM products
WHERE category NOT IN ('Electronics', 'Computers', 'Accessories');

-- Method 2: NOT with OR
SELECT * FROM products
WHERE NOT (
    category = 'Electronics' 
    OR category = 'Computers' 
    OR category = 'Accessories'
);

-- Method 3: Multiple AND conditions
SELECT * FROM products
WHERE category != 'Electronics'
  AND category != 'Computers'
  AND category != 'Accessories';
```

**⚠️ Common mistake:**
```sql
-- ❌ WRONG - This returns nothing!
WHERE category != 'Electronics' OR category != 'Computers'
-- Because every product satisfies at least one !=
```
</details>

---

## Range Conditions

### Question 4: BETWEEN Operator (Easy)
Find all products with price between $50 and $200 (inclusive)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT * FROM products
WHERE price BETWEEN 50 AND 200;
```

**Equivalent to:**
```sql
WHERE price >= 50 AND price <= 200
```

**Important Notes:**
- BETWEEN is **inclusive** (includes 50 and 200)
- Order matters: `BETWEEN low AND high`
- Works with dates, numbers, strings

**NOT BETWEEN:**
```sql
-- Products under $50 or over $200
WHERE price NOT BETWEEN 50 AND 200
-- Equivalent to:
WHERE price < 50 OR price > 200
```

**Date range example:**
```sql
WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
```
</details>

---

### Question 5: Date Filtering (Medium)
Find all orders placed in January 2024

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Method 1: BETWEEN
SELECT * FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31';

-- Method 2: >= and <
SELECT * FROM orders
WHERE order_date >= '2024-01-01' 
  AND order_date < '2024-02-01';

-- Method 3: YEAR and MONTH functions
SELECT * FROM orders
WHERE YEAR(order_date) = 2024 
  AND MONTH(order_date) = 1;

-- Method 4: DATE_FORMAT
SELECT * FROM orders
WHERE DATE_FORMAT(order_date, '%Y-%m') = '2024-01';
```

**⚠️ Time component matters:**
```sql
-- If order_date includes time (2024-01-31 23:59:59)
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'
-- Might miss 2024-01-31 23:59:59

-- Better:
WHERE order_date >= '2024-01-01' 
  AND order_date < '2024-02-01'
```
</details>

---

## Membership Conditions

### Question 6: IN with Subquery (Hard)
Find customers who have placed at least one order

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using IN with subquery
SELECT * FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders
);

-- Alternative: EXISTS (often faster)
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- Alternative: JOIN with DISTINCT
SELECT DISTINCT c.*
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

**Performance comparison:**
- **EXISTS**: Stops at first match (fastest for large datasets)
- **IN**: Builds full list first
- **JOIN**: May return duplicates without DISTINCT
</details>

---

## Pattern Matching

### Question 7: LIKE Wildcards (Medium)
Find customers whose:
1. Last name starts with 'Sm'
2. Email contains 'gmail'
3. Phone number matches pattern (###) ###-####

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- 1. Last name starts with 'Sm'
SELECT * FROM customers
WHERE last_name LIKE 'Sm%';

-- 2. Email contains 'gmail'
SELECT * FROM customers
WHERE email LIKE '%gmail%';

-- 3. Phone matches (###) ###-####
SELECT * FROM customers
WHERE phone LIKE '(___) ___-____';
```

**Wildcard Cheat Sheet:**
```sql
-- % = Zero or more characters
LIKE 'a%'        -- Starts with 'a'
LIKE '%z'        -- Ends with 'z'
LIKE '%mid%'     -- Contains 'mid'
LIKE 'a%z'       -- Starts with 'a', ends with 'z'

-- _ = Exactly one character
LIKE 'J_hn'      -- John, Jean, Jahn
LIKE '___'       -- Exactly 3 characters
LIKE 'A___%'     -- Starts with A, at least 4 chars

-- Escape special characters
LIKE '50\%'      -- Literal 50%
LIKE 'test\_'    -- Literal test_
```

**Complex patterns:**
```sql
-- Email validation (basic)
WHERE email LIKE '%@%.%'

-- Postal code (US ZIP)
WHERE zip LIKE '_____' OR zip LIKE '_____-____'

-- Product code (2 letters + 4 digits)
WHERE product_code LIKE '__[0-9][0-9][0-9][0-9]'  -- SQL Server
WHERE product_code REGEXP '^[A-Z]{2}[0-9]{4}$'    -- MySQL
```
</details>

---

### Question 8: Regular Expressions (Hard)
Find products where product_code matches pattern: 2 uppercase letters followed by 4 digits (e.g., 'AB1234')

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- MySQL
SELECT * FROM products
WHERE product_code REGEXP '^[A-Z]{2}[0-9]{4}$';

-- PostgreSQL
SELECT * FROM products
WHERE product_code ~ '^[A-Z]{2}[0-9]{4}$';

-- SQL Server (no built-in regex, use LIKE with pattern)
SELECT * FROM products
WHERE product_code LIKE '[A-Z][A-Z][0-9][0-9][0-9][0-9]'
  AND LEN(product_code) = 6;
```

**Regex Pattern Breakdown:**
```
^         = Start of string
[A-Z]     = One uppercase letter
{2}       = Exactly 2 times
[0-9]     = One digit
{4}       = Exactly 4 times
$         = End of string
```

**More REGEXP examples:**
```sql
-- Valid email (basic)
WHERE email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'

-- Phone number (US format)
WHERE phone REGEXP '^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$'

-- URL starting with http:// or https://
WHERE url REGEXP '^https?://'

-- Contains any digit
WHERE description REGEXP '[0-9]'
```
</details>

---

## NULL Handling

### Question 9: NULL Comparison (Medium)
Find customers who either have no phone number OR have no email

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT * FROM customers
WHERE phone IS NULL OR email IS NULL;
```

**Common NULL scenarios:**
```sql
-- No phone number
WHERE phone IS NULL

-- Has phone number
WHERE phone IS NOT NULL

-- No phone AND no email
WHERE phone IS NULL AND email IS NULL

-- No phone OR no email
WHERE phone IS NULL OR email IS NULL

-- Has BOTH phone and email
WHERE phone IS NOT NULL AND email IS NOT NULL
```

**⚠️ NULL behavior:**
```sql
-- These DON'T work with NULL
WHERE phone = NULL     -- Always returns no rows
WHERE phone != NULL    -- Always returns no rows

-- NULL in calculations
SELECT 
    price,
    discount,
    price - discount AS final_price  -- NULL if discount is NULL
FROM products;

-- Use COALESCE to handle NULL
SELECT 
    price,
    discount,
    price - COALESCE(discount, 0) AS final_price
FROM products;
```
</details>

---

### Question 10: COALESCE Function (Hard)
Write a query showing customer contact info. If phone is NULL, show email. If email is also NULL, show 'No contact info'.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    customer_id,
    first_name,
    last_name,
    COALESCE(phone, email, 'No contact info') AS contact_method
FROM customers;
```

**COALESCE explained:**
- Returns first non-NULL value
- Can accept multiple arguments
- Useful for default values

**Examples:**
```sql
-- Provide default for NULL
SELECT 
    product_name,
    COALESCE(discount_price, regular_price) AS selling_price
FROM products;

-- Multiple fallbacks
SELECT 
    COALESCE(mobile_phone, home_phone, work_phone, 'No phone') AS contact_number
FROM customers;

-- Calculate with NULL handling
SELECT 
    product_name,
    price,
    COALESCE(discount, 0) AS discount_amount,
    price - COALESCE(discount, 0) AS final_price
FROM products;
```

**Similar functions:**
```sql
-- IFNULL (MySQL) - only 2 arguments
SELECT IFNULL(phone, 'No phone') FROM customers;

-- ISNULL (SQL Server) - only 2 arguments
SELECT ISNULL(phone, 'No phone') FROM customers;

-- NULLIF - returns NULL if values are equal
SELECT NULLIF(current_price, original_price) FROM products;
-- Returns NULL if prices are the same
```
</details>

---

## Complex Filtering

### Question 11: Multiple Condition Types (Hard)
Find orders that meet ALL these criteria:
- Order date in 2024
- Total amount between $100 and $1,000
- Status is 'shipped' or 'delivered'
- Customer is NOT from specific cities: 'New York', 'Los Angeles'

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT o.*
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE YEAR(o.order_date) = 2024
  AND o.total_amount BETWEEN 100 AND 1000
  AND o.status IN ('shipped', 'delivered')
  AND c.city NOT IN ('New York', 'Los Angeles');
```

**Breaking down the conditions:**
```sql
-- Date range
WHERE YEAR(o.order_date) = 2024
-- Or:
WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'

-- Amount range
AND o.total_amount BETWEEN 100 AND 1000
-- Or:
AND o.total_amount >= 100 AND o.total_amount <= 1000

-- Membership
AND o.status IN ('shipped', 'delivered')
-- Or:
AND (o.status = 'shipped' OR o.status = 'delivered')

-- Exclusion
AND c.city NOT IN ('New York', 'Los Angeles')
-- Or:
AND c.city != 'New York' AND c.city != 'Los Angeles'
```
</details>

---

### Question 12: Case-Insensitive Search (Medium)
Find products where name contains 'laptop' (case-insensitive)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- MySQL (default case-insensitive)
SELECT * FROM products
WHERE product_name LIKE '%laptop%';

-- PostgreSQL (case-sensitive by default, use ILIKE)
SELECT * FROM products
WHERE product_name ILIKE '%laptop%';

-- SQL Server (usually case-insensitive by default)
SELECT * FROM products
WHERE product_name LIKE '%laptop%';

-- Universal solution (convert to lowercase)
SELECT * FROM products
WHERE LOWER(product_name) LIKE LOWER('%laptop%');
```

**Forcing case sensitivity:**
```sql
-- MySQL (force case-sensitive)
WHERE product_name LIKE '%laptop%' COLLATE utf8mb4_bin

-- PostgreSQL (force case-insensitive)
WHERE LOWER(product_name) LIKE LOWER('%laptop%')
-- Or:
WHERE product_name ILIKE '%laptop%'
```
</details>

---

## Real-World Scenario

### Question 13: Product Search Filters (Expert)
Build a flexible product search with these optional filters:
- Category (if provided)
- Price range (min/max)
- Keyword in name or description
- In stock only (optional)
- Exclude out-of-stock items

Write a query handling all combinations.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    product_id,
    product_name,
    category,
    price,
    stock_quantity,
    description
FROM products
WHERE 1=1  -- Trick: Always true, makes AND chains easier
  AND (@category IS NULL OR category = @category)
  AND (@min_price IS NULL OR price >= @min_price)
  AND (@max_price IS NULL OR price <= @max_price)
  AND (@keyword IS NULL OR 
       product_name LIKE CONCAT('%', @keyword, '%') OR
       description LIKE CONCAT('%', @keyword, '%'))
  AND (@in_stock_only = 0 OR stock_quantity > 0)
ORDER BY 
    CASE 
        WHEN @sort_by = 'price_asc' THEN price
    END ASC,
    CASE 
        WHEN @sort_by = 'price_desc' THEN price
    END DESC,
    CASE 
        WHEN @sort_by = 'name' THEN product_name
    END ASC,
    product_id;  -- Default sort
```

**Example usage:**
```sql
-- Search: Electronics, $50-$500, "gaming", in stock only
SET @category = 'Electronics';
SET @min_price = 50;
SET @max_price = 500;
SET @keyword = 'gaming';
SET @in_stock_only = 1;
SET @sort_by = 'price_asc';

-- Execute search (reuse query above)

-- Search: All products, any price, "laptop", include out-of-stock
SET @category = NULL;
SET @min_price = NULL;
SET @max_price = NULL;
SET @keyword = 'laptop';
SET @in_stock_only = 0;
SET @sort_by = 'name';
```

**Alternative: Dynamic SQL (if needed):**
```sql
SET @sql = 'SELECT * FROM products WHERE 1=1';

IF @category IS NOT NULL THEN
    SET @sql = CONCAT(@sql, ' AND category = ''', @category, '''');
END IF;

IF @min_price IS NOT NULL THEN
    SET @sql = CONCAT(@sql, ' AND price >= ', @min_price);
END IF;

-- ... continue building query

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 2 questions
- Medium: 7 questions
- Hard: 3 questions
- Expert: 1 question

**Topics Covered:**
- ✅ AND, OR, NOT operators
- ✅ Parentheses for condition grouping
- ✅ BETWEEN for range conditions
- ✅ IN and NOT IN
- ✅ LIKE pattern matching (%, _)
- ✅ Regular expressions (REGEXP)
- ✅ NULL handling (IS NULL, COALESCE)
- ✅ Case-insensitive searching
- ✅ Complex multi-condition filters

**Key Takeaways:**
- Always use parentheses for clarity
- BETWEEN is inclusive
- Can't use = or != with NULL
- Use COALESCE for default values
- LIKE is simpler, REGEXP is more powerful

**Next Steps:**
- Chapter 5: Querying Multiple Tables (JOINs)
- Practice combining multiple filter types
- Build a search feature for a real application
