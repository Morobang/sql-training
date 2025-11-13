# Chapter 10: Joins Revisited - Practice Questions

## Overview
Master advanced JOIN techniques: outer joins, cross joins, natural joins, self-joins, non-equi joins, and multiple join conditions.

---

## Outer Joins Advanced

### Question 1: FULL OUTER JOIN (Medium)
What does a FULL OUTER JOIN do, and when would you use it?

<details>
<summary>Click to see answer</summary>

**Answer: FULL OUTER JOIN returns all rows from both tables, matching where possible and showing NULLs where no match exists**

**Example:**

```sql
-- Find all customers and orders, including:
-- - Customers without orders
-- - Orders without customer records (orphaned)
SELECT 
    c.customer_id,
    c.name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;
```

**Result includes:**
- Customers with orders (matched)
- Customers without orders (NULL for order columns)
- Orphaned orders (NULL for customer columns)

**MySQL workaround (doesn't support FULL OUTER JOIN):**
```sql
-- Simulate FULL OUTER JOIN with UNION
SELECT 
    c.customer_id,
    c.name,
    o.order_id,
    o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id

UNION

SELECT 
    o.customer_id,
    NULL AS name,
    o.order_id,
    o.order_date
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

**Use cases:**
- Data quality audits (find orphaned records)
- Data reconciliation between systems
- Finding mismatches in related tables
</details>

---

### Question 2: Multiple Outer Joins (Hard)
Chain multiple LEFT JOINs while preserving all rows from the leftmost table.

Write a query showing:
- All customers
- Their orders (if any)
- Order items (if any)
- Product details (if any)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.customer_id,
    c.name AS customer_name,
    o.order_id,
    o.order_date,
    oi.order_item_id,
    oi.quantity,
    p.product_name,
    p.price
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
ORDER BY c.customer_id, o.order_id, oi.order_item_id;
```

**⚠️ Critical: All JOINs must be LEFT to preserve customers without orders**

**Common mistake:**
```sql
-- ❌ WRONG: Mixing INNER and LEFT JOIN
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id  -- This makes it effectively INNER!
-- Customers without orders are excluded

-- ✅ CORRECT: All LEFT
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
```

**With aggregates:**
```sql
SELECT 
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT oi.order_item_id) AS item_count,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;
```
</details>

---

## Non-Equi Joins

### Question 3: Range Joins (Medium)
Use non-equi joins to find overlapping date ranges or value ranges.

Find products within customer's price range preferences:
- customers (customer_id, name, min_price, max_price)
- products (product_id, product_name, price)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.min_price,
    c.max_price,
    p.product_id,
    p.product_name,
    p.price
FROM customers c
JOIN products p 
    ON p.price BETWEEN c.min_price AND c.max_price
ORDER BY c.customer_id, p.price;
```

**Date range overlap example:**
```sql
-- Find employees who worked during the same period
SELECT 
    e1.employee_name AS employee1,
    e1.start_date AS emp1_start,
    e1.end_date AS emp1_end,
    e2.employee_name AS employee2,
    e2.start_date AS emp2_start,
    e2.end_date AS emp2_end
FROM employment_history e1
JOIN employment_history e2 
    ON e1.employee_id < e2.employee_id  -- Avoid duplicates
    AND e1.start_date <= e2.end_date
    AND e1.end_date >= e2.start_date    -- Overlapping ranges
ORDER BY e1.employee_name, e2.employee_name;
```

**Price tier matching:**
```sql
-- Assign customers to price tiers
SELECT 
    c.customer_id,
    c.name,
    c.avg_order_value,
    t.tier_name,
    t.discount_pct
FROM customers c
JOIN price_tiers t 
    ON c.avg_order_value >= t.min_value 
    AND c.avg_order_value < t.max_value
ORDER BY c.avg_order_value DESC;
```
</details>

---

### Question 4: Inequality Joins (Hard)
Find all pairs of products where one is more expensive than the other in the same category.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Self-join with inequality
SELECT 
    p1.product_name AS cheaper_product,
    p1.price AS cheaper_price,
    p2.product_name AS expensive_product,
    p2.price AS expensive_price,
    p1.category,
    p2.price - p1.price AS price_difference
FROM products p1
JOIN products p2 
    ON p1.category = p2.category
    AND p1.price < p2.price  -- Inequality join
ORDER BY p1.category, price_difference DESC;
```

**Find products priced higher than category average:**
```sql
SELECT 
    p1.product_id,
    p1.product_name,
    p1.price,
    p1.category,
    AVG(p2.price) AS category_avg_price,
    p1.price - AVG(p2.price) AS price_vs_avg
FROM products p1
JOIN products p2 ON p1.category = p2.category
GROUP BY p1.product_id, p1.product_name, p1.price, p1.category
HAVING p1.price > AVG(p2.price)
ORDER BY price_vs_avg DESC;
```

**Find products with similar prices (within $10):**
```sql
SELECT 
    p1.product_name AS product1,
    p1.price AS price1,
    p2.product_name AS product2,
    p2.price AS price2,
    ABS(p1.price - p2.price) AS price_diff
FROM products p1
JOIN products p2 
    ON p1.product_id < p2.product_id  -- Avoid duplicates and self-match
    AND ABS(p1.price - p2.price) <= 10
ORDER BY price_diff;
```
</details>

---

## Multiple Join Conditions

### Question 5: Complex Join Criteria (Medium)
Join tables on multiple conditions beyond just foreign keys.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Join with multiple conditions
SELECT 
    c.customer_id,
    c.name,
    c.preferred_category,
    o.order_id,
    p.product_name,
    p.category
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
    AND o.order_date >= c.registration_date  -- Order after registration
JOIN order_items oi 
    ON o.order_id = oi.order_id
JOIN products p 
    ON oi.product_id = p.product_id
    AND p.category = c.preferred_category    -- Match preferred category
    AND p.price <= c.max_budget              -- Within budget
WHERE o.status = 'completed'
ORDER BY c.customer_id, o.order_date;
```

**Time-based joins:**
```sql
-- Join orders with active promotions at time of order
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    pr.promotion_name,
    pr.discount_pct
FROM orders o
LEFT JOIN promotions pr 
    ON o.order_date BETWEEN pr.start_date AND pr.end_date
    AND o.total_amount >= pr.min_order_amount
ORDER BY o.order_date;
```

**Conditional joins with CASE:**
```sql
-- Different join logic based on customer type
SELECT 
    c.customer_id,
    c.name,
    c.customer_type,
    CASE 
        WHEN c.customer_type = 'VIP' THEN vip.discount_pct
        WHEN c.customer_type = 'Regular' THEN reg.discount_pct
        ELSE 0
    END AS discount_rate
FROM customers c
LEFT JOIN vip_discounts vip 
    ON c.customer_id = vip.customer_id 
    AND c.customer_type = 'VIP'
LEFT JOIN regular_discounts reg 
    ON c.customer_id = reg.customer_id 
    AND c.customer_type = 'Regular';
```
</details>

---

## NATURAL JOIN

### Question 6: NATURAL JOIN Risks (Easy)
Why should you avoid NATURAL JOIN in production code?

<details>
<summary>Click to see answer</summary>

**Answer: NATURAL JOIN automatically joins on ALL columns with the same name, which is dangerous and unpredictable**

**Example:**

```sql
-- Tables
CREATE TABLE customers (
    customer_id INT,
    name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE orders (
    order_id INT,
    customer_id INT,
    city VARCHAR(50),  -- ⚠️ Same name as customers.city!
    total_amount DECIMAL(10,2)
);

-- NATURAL JOIN (dangerous!)
SELECT *
FROM customers
NATURAL JOIN orders;
-- Joins on BOTH customer_id AND city
-- May exclude valid orders if cities don't match!
```

**Problems:**
1. **Hidden join conditions** - Not explicit what's being joined
2. **Schema changes break queries** - Adding a column with same name changes behavior
3. **Unexpected results** - Joins on columns you didn't intend
4. **Hard to debug** - Not clear why rows are missing

**Always use explicit joins:**
```sql
-- ✅ CORRECT: Explicit join condition
SELECT 
    c.customer_id,
    c.name,
    c.city AS customer_city,
    o.order_id,
    o.city AS shipping_city,
    o.total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;
```
</details>

---

## Self-Joins Advanced

### Question 7: Complex Self-Join (Hard)
Find employees who earn more than their manager.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    e.employee_id,
    e.name AS employee_name,
    e.salary AS employee_salary,
    e.title AS employee_title,
    m.employee_id AS manager_id,
    m.name AS manager_name,
    m.salary AS manager_salary,
    e.salary - m.salary AS salary_difference
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary
ORDER BY salary_difference DESC;
```

**Find employees with same job hired in same year:**
```sql
SELECT 
    e1.name AS employee1,
    e2.name AS employee2,
    e1.title,
    YEAR(e1.hire_date) AS hire_year,
    e1.department
FROM employees e1
JOIN employees e2 
    ON e1.employee_id < e2.employee_id  -- Avoid duplicates
    AND e1.title = e2.title
    AND YEAR(e1.hire_date) = YEAR(e2.hire_date)
    AND e1.department = e2.department
ORDER BY hire_year DESC, e1.title;
```

**Find product price gaps (products with no other product between their prices):**
```sql
SELECT 
    p1.product_name AS lower_priced,
    p1.price AS lower_price,
    p2.product_name AS higher_priced,
    p2.price AS higher_price,
    p2.price - p1.price AS price_gap
FROM products p1
JOIN products p2 ON p1.price < p2.price
WHERE NOT EXISTS (
    SELECT 1 FROM products p3
    WHERE p3.price > p1.price AND p3.price < p2.price
)
ORDER BY price_gap DESC
LIMIT 10;
```
</details>

---

## Cross Join Patterns

### Question 8: Generate Combinations (Medium)
Use CROSS JOIN to generate all possible combinations.

Create all product-color-size combinations:
- Base products (product_name)
- Colors (color_name)
- Sizes (size_name)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Generate all product variants
SELECT 
    p.product_id,
    p.product_name,
    c.color_name,
    s.size_name,
    CONCAT(p.product_name, ' - ', c.color_name, ' - ', s.size_name) AS variant_name,
    p.base_price AS base_price
FROM base_products p
CROSS JOIN colors c
CROSS JOIN sizes s
ORDER BY p.product_name, c.color_name, s.size_name;
```

**Result (if 2 products, 3 colors, 3 sizes = 18 rows):**
```
product_name | color_name | size_name | variant_name
T-Shirt      | Red        | Small     | T-Shirt - Red - Small
T-Shirt      | Red        | Medium    | T-Shirt - Red - Medium
T-Shirt      | Red        | Large     | T-Shirt - Red - Large
T-Shirt      | Blue       | Small     | T-Shirt - Blue - Small
...
```

**Generate date series with CROSS JOIN:**
```sql
-- All days in a month for all products
WITH dates AS (
    SELECT DATE('2024-01-01') + INTERVAL n DAY AS sale_date
    FROM (
        SELECT a.n + b.n * 10 AS n
        FROM 
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a
        CROSS JOIN
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) b
    ) numbers
    WHERE n < 31
)
SELECT 
    d.sale_date,
    p.product_id,
    p.product_name,
    COALESCE(s.quantity_sold, 0) AS quantity_sold
FROM dates d
CROSS JOIN products p
LEFT JOIN daily_sales s 
    ON d.sale_date = s.sale_date 
    AND p.product_id = s.product_id
ORDER BY d.sale_date, p.product_id;
```

**Testing scenarios (all combinations):**
```sql
-- Generate test cases for all combinations
SELECT 
    tc.test_case,
    u.user_type,
    b.browser,
    d.device_type
FROM test_cases tc
CROSS JOIN user_types u
CROSS JOIN browsers b
CROSS JOIN device_types d;
```
</details>

---

## Join Performance

### Question 9: Join Optimization (Hard)
What are best practices for optimizing joins?

<details>
<summary>Click to see answer</summary>

**Answer:**

**1. Use proper indexes on join columns**
```sql
-- Create indexes on foreign keys
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Composite index for multi-column joins
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
```

**2. Filter before joining (reduce rows early)**
```sql
-- ❌ Slow: Join then filter
SELECT c.name, o.order_id
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01';

-- ✅ Fast: Filter in subquery first
SELECT c.name, filtered.order_id
FROM customers c
JOIN (
    SELECT customer_id, order_id
    FROM orders
    WHERE order_date >= '2024-01-01'  -- Filter reduces rows before join
) filtered ON c.customer_id = filtered.customer_id;
```

**3. Join order matters**
```sql
-- Start with smallest table
-- Join in order of selectivity (most filtering first)
FROM small_table s
JOIN medium_table m ON s.id = m.small_id
JOIN large_table l ON m.id = l.medium_id
```

**4. Use EXISTS instead of JOIN when only checking existence**
```sql
-- ❌ Slow: JOIN + DISTINCT
SELECT DISTINCT c.*
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

-- ✅ Fast: EXISTS (stops at first match)
SELECT c.*
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);
```

**5. Avoid functions on indexed columns in JOIN**
```sql
-- ❌ Slow: Function prevents index use
JOIN orders o ON DATE(o.order_date) = c.registration_date

-- ✅ Fast: Keep column raw
JOIN orders o ON o.order_date >= c.registration_date 
              AND o.order_date < DATE_ADD(c.registration_date, INTERVAL 1 DAY)
```

**6. Use EXPLAIN to analyze**
```sql
EXPLAIN SELECT c.name, COUNT(o.order_id)
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
-- Look for: index usage, join type, rows examined
```

**7. Consider denormalization for read-heavy workloads**
```sql
-- Store frequently joined data together
ALTER TABLE orders ADD COLUMN customer_name VARCHAR(100);
UPDATE orders o
JOIN customers c ON o.customer_id = c.customer_id
SET o.customer_name = c.name;
-- Eliminates join for read queries
```
</details>

---

## Real-World Join Scenarios

### Question 10: Complex Business Query (Expert)
Build a customer 360 view joining multiple tables:
- Customer demographics
- Order history with aggregates
- Product preferences
- Geographic data
- Lifetime value calculations

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(total_amount) AS lifetime_value,
        AVG(total_amount) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MAX(order_date), MIN(order_date)) AS customer_lifetime_days
    FROM orders
    GROUP BY customer_id
),
customer_products AS (
    SELECT 
        o.customer_id,
        p.category,
        COUNT(DISTINCT p.product_id) AS products_purchased,
        SUM(oi.quantity) AS total_units,
        SUM(oi.quantity * oi.unit_price) AS category_spend
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.customer_id, p.category
),
top_categories AS (
    SELECT 
        customer_id,
        category AS favorite_category,
        category_spend,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY category_spend DESC) AS rn
    FROM customer_products
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.city,
    c.state,
    c.registration_date,
    TIMESTAMPDIFF(YEAR, c.registration_date, CURRENT_DATE) AS member_years,
    
    -- Order metrics
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.lifetime_value, 0) AS lifetime_value,
    COALESCE(co.avg_order_value, 0) AS avg_order_value,
    co.first_order_date,
    co.last_order_date,
    DATEDIFF(CURRENT_DATE, co.last_order_date) AS days_since_last_order,
    
    -- Product preferences
    tc.favorite_category,
    tc.category_spend AS favorite_category_spend,
    
    -- Segmentation
    CASE 
        WHEN COALESCE(co.lifetime_value, 0) >= 10000 THEN 'VIP'
        WHEN COALESCE(co.lifetime_value, 0) >= 5000 THEN 'Premium'
        WHEN COALESCE(co.lifetime_value, 0) >= 1000 THEN 'Regular'
        WHEN COALESCE(co.total_orders, 0) > 0 THEN 'Occasional'
        ELSE 'Inactive'
    END AS customer_segment,
    
    -- Churn risk
    CASE 
        WHEN co.last_order_date IS NULL THEN 'Never Ordered'
        WHEN DATEDIFF(CURRENT_DATE, co.last_order_date) > 365 THEN 'High Risk'
        WHEN DATEDIFF(CURRENT_DATE, co.last_order_date) > 180 THEN 'Medium Risk'
        WHEN DATEDIFF(CURRENT_DATE, co.last_order_date) > 90 THEN 'Low Risk'
        ELSE 'Active'
    END AS churn_risk
    
FROM customers c
LEFT JOIN customer_orders co ON c.customer_id = co.customer_id
LEFT JOIN top_categories tc ON c.customer_id = tc.customer_id AND tc.rn = 1
ORDER BY lifetime_value DESC;
```

**Performance view creation:**
```sql
CREATE VIEW vw_customer_360 AS
-- Above query
-- Then query the view instead of running complex joins repeatedly

-- Usage
SELECT * FROM vw_customer_360
WHERE customer_segment = 'VIP'
ORDER BY lifetime_value DESC;
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 5 questions
- Hard: 3 questions
- Expert: 1 question

**Topics Covered:**
- ✅ FULL OUTER JOIN
- ✅ Multiple outer joins
- ✅ Non-equi joins (range, inequality)
- ✅ Multiple join conditions
- ✅ NATURAL JOIN (and why to avoid it)
- ✅ Advanced self-joins
- ✅ CROSS JOIN patterns
- ✅ Join optimization techniques
- ✅ Real-world complex queries

**Key Takeaways:**
- FULL OUTER JOIN = all from both tables
- All JOINs must be LEFT to preserve outer rows
- Non-equi joins use <, >, BETWEEN
- Avoid NATURAL JOIN (implicit, unpredictable)
- Index join columns for performance
- Filter before joining when possible
- EXISTS faster than JOIN for existence checks
- Use EXPLAIN to optimize

**Next Steps:**
- Chapter 11: Conditional Logic
- Practice with complex business queries
- Build customer 360 views
