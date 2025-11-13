# Chapter 9: Subqueries - Practice Questions

## Overview
Master scalar subqueries, column subqueries, row subqueries, table subqueries, correlated subqueries, and Common Table Expressions (CTEs).

---

## Scalar Subqueries

### Question 1: Scalar Subquery Basics (Easy)
What is a scalar subquery and where can it be used?

<details>
<summary>Click to see answer</summary>

**Answer: A scalar subquery returns exactly ONE value (1 row, 1 column) and can be used anywhere a single value is expected**

**Examples:**

```sql
-- In SELECT clause
SELECT 
    product_name,
    price,
    (SELECT AVG(price) FROM products) AS avg_price,
    price - (SELECT AVG(price) FROM products) AS price_vs_avg
FROM products;

-- In WHERE clause
SELECT *
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- In HAVING clause
SELECT 
    category,
    AVG(price) AS avg_category_price
FROM products
GROUP BY category
HAVING AVG(price) > (SELECT AVG(price) FROM products);

-- In ORDER BY
SELECT product_name, price
FROM products
ORDER BY ABS(price - (SELECT AVG(price) FROM products));
```

**⚠️ Must return exactly 1 value:**
```sql
-- ❌ ERROR: Subquery returns multiple rows
SELECT * 
FROM products
WHERE price > (SELECT price FROM products);

-- ✅ CORRECT: Returns one value
SELECT * 
FROM products
WHERE price > (SELECT MAX(price) FROM products WHERE category = 'Electronics');
```
</details>

---

### Question 2: Compare to Aggregate (Easy)
Find products priced above the average price in their category.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using correlated subquery
SELECT 
    p1.product_name,
    p1.category,
    p1.price,
    (SELECT AVG(p2.price) 
     FROM products p2 
     WHERE p2.category = p1.category) AS category_avg_price
FROM products p1
WHERE p1.price > (
    SELECT AVG(p2.price) 
    FROM products p2 
    WHERE p2.category = p1.category
)
ORDER BY p1.category, p1.price DESC;
```

**Alternative using JOIN:**
```sql
SELECT 
    p.product_name,
    p.category,
    p.price,
    cat_avg.avg_price AS category_avg_price
FROM products p
JOIN (
    SELECT category, AVG(price) AS avg_price
    FROM products
    GROUP BY category
) cat_avg ON p.category = cat_avg.category
WHERE p.price > cat_avg.avg_price
ORDER BY p.category, p.price DESC;
```
</details>

---

## Column Subqueries (IN, NOT IN)

### Question 3: IN Subquery (Medium)
Find customers who have placed orders.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Using IN
SELECT *
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders
);
```

**Alternatives:**

```sql
-- Using EXISTS (often faster)
SELECT *
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
);

-- Using JOIN
SELECT DISTINCT c.*
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```

**Performance comparison:**
- **EXISTS**: Stops at first match (fastest for large datasets)
- **IN**: Builds complete list first
- **JOIN**: Can return duplicates without DISTINCT

**⚠️ NULL handling with NOT IN:**
```sql
-- If subquery returns NULL, NOT IN returns no rows!
SELECT * 
FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id FROM orders  -- If any is NULL, returns nothing!
);

-- ✅ SAFE: Filter out NULLs
SELECT * 
FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id FROM orders WHERE customer_id IS NOT NULL
);

-- ✅ BETTER: Use NOT EXISTS
SELECT *
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```
</details>

---

### Question 4: NOT IN for Missing Data (Medium)
Find products that have never been ordered.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Method 1: NOT IN
SELECT *
FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id 
    FROM order_items 
    WHERE product_id IS NOT NULL
);

-- Method 2: NOT EXISTS (recommended)
SELECT *
FROM products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM order_items oi 
    WHERE oi.product_id = p.product_id
);

-- Method 3: LEFT JOIN + IS NULL
SELECT p.*
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- Method 4: EXCEPT (if supported)
SELECT product_id, product_name FROM products
EXCEPT
SELECT p.product_id, p.product_name 
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id;
```

**With additional info:**
```sql
SELECT 
    p.*,
    DATEDIFF(CURRENT_DATE, p.created_date) AS days_since_created,
    p.stock_quantity,
    p.price
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id
)
ORDER BY days_since_created DESC;
```
</details>

---

## Table Subqueries (FROM Clause)

### Question 5: Subquery in FROM (Medium)
Calculate average order value per customer, then find customers above overall average.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT *
FROM (
    SELECT 
        c.customer_id,
        c.name,
        COUNT(o.order_id) AS order_count,
        AVG(o.total_amount) AS avg_order_value,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
) customer_stats
WHERE avg_order_value > (
    SELECT AVG(total_amount) FROM orders
)
ORDER BY avg_order_value DESC;
```

**Using CTE (cleaner):**
```sql
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        c.name,
        COUNT(o.order_id) AS order_count,
        AVG(o.total_amount) AS avg_order_value,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT *
FROM customer_stats
WHERE avg_order_value > (SELECT AVG(total_amount) FROM orders)
ORDER BY avg_order_value DESC;
```
</details>

---

### Question 6: Multiple Subqueries in FROM (Hard)
Compare monthly sales between current year and previous year.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    cy.month,
    cy.current_year_sales,
    COALESCE(py.prev_year_sales, 0) AS prev_year_sales,
    cy.current_year_sales - COALESCE(py.prev_year_sales, 0) AS sales_change,
    ROUND(
        (cy.current_year_sales - COALESCE(py.prev_year_sales, 0)) 
        / COALESCE(py.prev_year_sales, 1) * 100,
        2
    ) AS pct_change
FROM (
    -- Current year sales
    SELECT 
        MONTH(order_date) AS month,
        SUM(total_amount) AS current_year_sales
    FROM orders
    WHERE YEAR(order_date) = YEAR(CURRENT_DATE)
    GROUP BY MONTH(order_date)
) cy
LEFT JOIN (
    -- Previous year sales
    SELECT 
        MONTH(order_date) AS month,
        SUM(total_amount) AS prev_year_sales
    FROM orders
    WHERE YEAR(order_date) = YEAR(CURRENT_DATE) - 1
    GROUP BY MONTH(order_date)
) py ON cy.month = py.month
ORDER BY cy.month;
```

**Using CTEs (more readable):**
```sql
WITH current_year AS (
    SELECT 
        MONTH(order_date) AS month,
        SUM(total_amount) AS sales
    FROM orders
    WHERE YEAR(order_date) = 2024
    GROUP BY MONTH(order_date)
),
previous_year AS (
    SELECT 
        MONTH(order_date) AS month,
        SUM(total_amount) AS sales
    FROM orders
    WHERE YEAR(order_date) = 2023
    GROUP BY MONTH(order_date)
)
SELECT 
    cy.month,
    cy.sales AS current_year_sales,
    COALESCE(py.sales, 0) AS prev_year_sales,
    cy.sales - COALESCE(py.sales, 0) AS change,
    ROUND((cy.sales - COALESCE(py.sales, 0)) / COALESCE(py.sales, 1) * 100, 2) AS pct_change
FROM current_year cy
LEFT JOIN previous_year py ON cy.month = py.month
ORDER BY cy.month;
```
</details>

---

## Correlated Subqueries

### Question 7: Correlated Subquery (Hard)
Find each customer's most recent order with details.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Method 1: Correlated subquery
SELECT 
    c.customer_id,
    c.name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date = (
    SELECT MAX(o2.order_date)
    FROM orders o2
    WHERE o2.customer_id = c.customer_id
)
ORDER BY c.customer_id;
```

**Method 2: Window function (better performance):**
```sql
WITH ranked_orders AS (
    SELECT 
        c.customer_id,
        c.name,
        o.order_id,
        o.order_date,
        o.total_amount,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date DESC) AS rn
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
)
SELECT 
    customer_id,
    name,
    order_id,
    order_date,
    total_amount
FROM ranked_orders
WHERE rn = 1;
```

**Method 3: JOIN to aggregated subquery:**
```sql
SELECT 
    c.customer_id,
    c.name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN (
    SELECT customer_id, MAX(order_date) AS latest_order_date
    FROM orders
    GROUP BY customer_id
) latest ON o.customer_id = latest.customer_id 
        AND o.order_date = latest.latest_order_date;
```
</details>

---

### Question 8: EXISTS vs IN (Medium)
When should you use EXISTS instead of IN?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Use EXISTS when:**
- Checking for existence (don't need actual values)
- Subquery returns many rows
- Subquery has multiple columns
- Better performance for large datasets (stops at first match)

**Use IN when:**
- Need to match against a list of values
- Subquery is small and returns single column
- More readable for simple cases

**Examples:**

```sql
-- ✅ EXISTS: Just checking existence
SELECT c.*
FROM customers c
WHERE EXISTS (
    SELECT 1  -- Don't need actual values
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.total_amount > 1000
);

-- ✅ IN: Matching specific list
SELECT *
FROM products
WHERE category IN ('Electronics', 'Computers', 'Accessories');

-- EXISTS: Better for large subqueries
SELECT c.*
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
);  -- Stops at first match

-- IN: Builds entire list first
SELECT c.*
FROM customers c
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM orders
);  -- Must complete entire subquery
```

**Performance test:**
```sql
-- EXISTS (faster for large datasets)
EXPLAIN SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- IN
EXPLAIN SELECT * FROM customers c
WHERE customer_id IN (SELECT customer_id FROM orders);
```

**NULL handling:**
```sql
-- EXISTS: Handles NULLs fine
WHERE EXISTS (SELECT 1 FROM orders WHERE customer_id = c.customer_id)

-- IN: Can have issues with NULL
WHERE customer_id IN (SELECT customer_id FROM orders)  -- If any NULL, may cause problems
```
</details>

---

## Common Table Expressions (CTEs)

### Question 9: CTE Basics (Medium)
Rewrite a complex query using CTEs for better readability.

Find customers who:
- Spent over $10,000 lifetime
- Have average order value > $500
- Made at least 5 orders

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Without CTE (hard to read)
SELECT *
FROM (
    SELECT 
        c.customer_id,
        c.name,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS lifetime_value,
        AVG(o.total_amount) AS avg_order_value
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
) customer_metrics
WHERE lifetime_value > 10000
  AND avg_order_value > 500
  AND order_count >= 5;
```

**With CTE (much clearer):**
```sql
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS lifetime_value,
        AVG(o.total_amount) AS avg_order_value,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name, c.email
)
SELECT 
    customer_id,
    name,
    email,
    order_count,
    ROUND(lifetime_value, 2) AS lifetime_value,
    ROUND(avg_order_value, 2) AS avg_order_value,
    first_order_date,
    last_order_date,
    DATEDIFF(last_order_date, first_order_date) AS customer_lifetime_days
FROM customer_metrics
WHERE lifetime_value > 10000
  AND avg_order_value > 500
  AND order_count >= 5
ORDER BY lifetime_value DESC;
```

**Multiple CTEs:**
```sql
WITH 
high_value_customers AS (
    SELECT customer_id, SUM(total_amount) AS lifetime_value
    FROM orders
    GROUP BY customer_id
    HAVING SUM(total_amount) > 10000
),
frequent_customers AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
    HAVING COUNT(*) >= 5
),
high_avg_customers AS (
    SELECT customer_id, AVG(total_amount) AS avg_value
    FROM orders
    GROUP BY customer_id
    HAVING AVG(total_amount) > 500
)
SELECT 
    c.customer_id,
    c.name,
    hv.lifetime_value,
    fc.order_count,
    ha.avg_value
FROM customers c
JOIN high_value_customers hv ON c.customer_id = hv.customer_id
JOIN frequent_customers fc ON c.customer_id = fc.customer_id
JOIN high_avg_customers ha ON c.customer_id = ha.customer_id
ORDER BY hv.lifetime_value DESC;
```
</details>

---

### Question 10: Recursive CTE (Expert)
Create an employee hierarchy showing all levels from CEO down.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Recursive CTE for organizational hierarchy
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Start with CEO (no manager)
    SELECT 
        employee_id,
        name,
        manager_id,
        title,
        1 AS level,
        name AS hierarchy_path,
        CAST(employee_id AS CHAR(1000)) AS sort_path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Find employees reporting to previous level
    SELECT 
        e.employee_id,
        e.name,
        e.manager_id,
        e.title,
        eh.level + 1,
        CONCAT(eh.hierarchy_path, ' > ', e.name) AS hierarchy_path,
        CONCAT(eh.sort_path, '-', LPAD(e.employee_id, 5, '0')) AS sort_path
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    name,
    title,
    manager_id,
    level,
    CONCAT(REPEAT('  ', level - 1), name) AS indented_name,
    hierarchy_path
FROM employee_hierarchy
ORDER BY sort_path;
```

**Output:**
```
employee_id | name         | title          | level | indented_name      | hierarchy_path
1          | Alice CEO     | CEO            | 1     | Alice CEO          | Alice CEO
2          | Bob VP        | VP Sales       | 2     |   Bob VP           | Alice CEO > Bob VP
5          | Eve Manager   | Sales Mgr      | 3     |     Eve Manager    | Alice CEO > Bob VP > Eve Manager
8          | Henry Rep     | Sales Rep      | 4     |       Henry Rep    | Alice CEO > Bob VP > Eve Manager > Henry Rep
```

**Find all subordinates of a specific manager:**
```sql
WITH RECURSIVE subordinates AS (
    -- Start with the manager
    SELECT employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE employee_id = 5  -- Eve Manager
    
    UNION ALL
    
    -- Find all direct and indirect reports
    SELECT e.employee_id, e.name, e.manager_id, s.level + 1
    FROM employees e
    JOIN subordinates s ON e.manager_id = s.employee_id
)
SELECT * FROM subordinates
WHERE employee_id != 5  -- Exclude the manager themselves
ORDER BY level, name;
```

**Count reports at each level:**
```sql
WITH RECURSIVE org_structure AS (
    SELECT employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    SELECT e.employee_id, e.name, e.manager_id, os.level + 1
    FROM employees e
    JOIN org_structure os ON e.manager_id = os.employee_id
)
SELECT 
    level,
    COUNT(*) AS employee_count
FROM org_structure
GROUP BY level
ORDER BY level;
```
</details>

---

## Subquery Performance

### Question 11: Subquery Optimization (Hard)
What are best practices for subquery performance?

<details>
<summary>Click to see answer</summary>

**Answer:**

**1. Use EXISTS instead of IN for large datasets**
```sql
-- ❌ Slower: IN with large subquery
SELECT * FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders);

-- ✅ Faster: EXISTS (stops at first match)
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);
```

**2. Avoid correlated subqueries in SELECT**
```sql
-- ❌ Slow: Runs subquery for every row
SELECT 
    c.name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count
FROM customers c;

-- ✅ Fast: JOIN once
SELECT 
    c.name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
```

**3. Use CTEs for readability and reusability**
```sql
-- ✅ Clear and can be referenced multiple times
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT c.*, co.order_count
FROM customers c
LEFT JOIN customer_orders co ON c.customer_id = co.customer_id;
```

**4. Filter early in subqueries**
```sql
-- ❌ Filters after joining everything
SELECT * FROM customers c
WHERE customer_id IN (
    SELECT customer_id FROM orders WHERE total_amount > 1000
);

-- ✅ Filter in subquery first
SELECT * FROM customers c
WHERE customer_id IN (
    SELECT customer_id 
    FROM orders 
    WHERE total_amount > 1000  -- Filter reduces rows early
);
```

**5. Use indexes on subquery columns**
```sql
-- Create indexes on columns used in subqueries
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_total_amount ON orders(total_amount);
```

**6. Check execution plans**
```sql
EXPLAIN SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);
-- Look for: Index usage, join type, rows examined
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 2 questions
- Medium: 5 questions
- Hard: 3 questions
- Expert: 1 question

**Topics Covered:**
- ✅ Scalar subqueries (single value)
- ✅ Column subqueries (IN, NOT IN)
- ✅ Table subqueries (FROM clause)
- ✅ Correlated subqueries
- ✅ EXISTS vs IN
- ✅ Common Table Expressions (CTEs)
- ✅ Recursive CTEs
- ✅ Subquery optimization

**Key Takeaways:**
- Scalar subquery = 1 row, 1 column
- EXISTS better than IN for large datasets
- CTEs improve readability
- Recursive CTEs for hierarchies
- Avoid correlated subqueries in SELECT when possible
- NOT IN dangerous with NULLs - use NOT EXISTS
- Use EXPLAIN to check performance

**Next Steps:**
- Chapter 10: Joins Revisited (Advanced JOIN techniques)
- Practice CTEs for complex queries
- Study recursive patterns for tree structures
