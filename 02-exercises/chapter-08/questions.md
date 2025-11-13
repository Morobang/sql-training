# Chapter 8: Grouping and Aggregates - Practice Questions

## Overview
Master GROUP BY, aggregate functions (COUNT, SUM, AVG, MIN, MAX), HAVING clause, and window functions basics.

---

## Basic Aggregates

### Question 1: COUNT Function (Easy)
What's the difference between COUNT(*), COUNT(column), and COUNT(DISTINCT column)?

<details>
<summary>Click to see answer</summary>

**Answer:**

**COUNT(*)**: Counts all rows (including NULLs)
**COUNT(column)**: Counts non-NULL values in specific column
**COUNT(DISTINCT column)**: Counts unique non-NULL values

**Example:**

```sql
-- Sample data
CREATE TABLE test (id INT, value VARCHAR(10));
INSERT INTO test VALUES (1, 'A'), (2, 'A'), (3, NULL), (4, 'B');
```

Results:
```sql
SELECT 
    COUNT(*) AS total_rows,              -- 4 (all rows)
    COUNT(value) AS non_null_values,     -- 3 (excludes NULL)
    COUNT(DISTINCT value) AS unique_vals -- 2 (A, B - unique only)
FROM test;
```

Output:
```
total_rows | non_null_values | unique_vals
4          | 3               | 2
```

**Common use cases:**
```sql
-- Total customers
SELECT COUNT(*) FROM customers;

-- Customers with phone numbers
SELECT COUNT(phone) FROM customers;

-- Unique cities
SELECT COUNT(DISTINCT city) FROM customers;

-- Multiple aggregates
SELECT 
    COUNT(*) AS total_customers,
    COUNT(phone) AS with_phone,
    COUNT(email) AS with_email,
    COUNT(DISTINCT city) AS unique_cities
FROM customers;
```
</details>

---

### Question 2: SUM and AVG (Easy)
Calculate total sales and average order value.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    -- Total revenue
    SUM(total_amount) AS total_revenue,
    
    -- Average order value
    AVG(total_amount) AS avg_order_value,
    
    -- Rounded average
    ROUND(AVG(total_amount), 2) AS avg_order_rounded,
    
    -- Number of orders
    COUNT(*) AS total_orders,
    
    -- Manual average calculation
    SUM(total_amount) / COUNT(*) AS manual_avg
FROM orders;
```

**⚠️ AVG ignores NULLs:**
```sql
-- Data: 10, 20, NULL, 40
SELECT 
    AVG(amount) AS avg_value,  -- 23.33 (70/3, not 70/4!)
    SUM(amount) / COUNT(*) AS manual_avg  -- 17.5 (70/4)
FROM test_data;
```

**Handling NULLs:**
```sql
SELECT 
    AVG(COALESCE(amount, 0)) AS avg_including_nulls,
    SUM(amount) / COUNT(*) AS avg_as_zero
FROM test_data;
```
</details>

---

## GROUP BY Basics

### Question 3: GROUP BY Single Column (Easy)
Count customers per city and show total in descending order.

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

**With percentage:**
```sql
SELECT 
    city,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS percentage
FROM customers
GROUP BY city
ORDER BY customer_count DESC;
```

**Top 10 cities:**
```sql
SELECT 
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC
LIMIT 10;
```
</details>

---

### Question 4: GROUP BY Multiple Columns (Medium)
Count customers by city and state combination.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    state,
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY state, city
ORDER BY state, customer_count DESC;
```

**With aggregates:**
```sql
SELECT 
    state,
    city,
    COUNT(*) AS customer_count,
    COUNT(phone) AS customers_with_phone,
    ROUND(AVG(DATEDIFF(CURRENT_DATE, registration_date) / 365), 1) AS avg_member_years
FROM customers
GROUP BY state, city
HAVING COUNT(*) >= 10  -- Cities with 10+ customers
ORDER BY state, customer_count DESC;
```

**Grouping sets (advanced):**
```sql
-- Subtotals by state, city, and grand total
SELECT 
    state,
    city,
    COUNT(*) AS customer_count
FROM customers
GROUP BY state, city WITH ROLLUP;  -- MySQL
-- Or GROUP BY ROLLUP(state, city);  -- SQL Server, Oracle
```
</details>

---

## HAVING Clause

### Question 5: HAVING vs WHERE (Medium)
Explain the difference and show when to use each.

<details>
<summary>Click to see answer</summary>

**Answer:**

**WHERE**: Filters rows BEFORE grouping
**HAVING**: Filters groups AFTER grouping

**Example:**

```sql
-- Find cities with 50+ customers who registered in 2024
SELECT 
    city,
    COUNT(*) AS customer_count
FROM customers
WHERE registration_date >= '2024-01-01'  -- Filter rows first
GROUP BY city
HAVING COUNT(*) >= 50  -- Filter groups after
ORDER BY customer_count DESC;
```

**Execution order:**
1. **FROM** - Get table
2. **WHERE** - Filter individual rows
3. **GROUP BY** - Group remaining rows
4. **HAVING** - Filter groups
5. **SELECT** - Calculate aggregates
6. **ORDER BY** - Sort results

**Common mistakes:**
```sql
-- ❌ WRONG: Can't use aggregate in WHERE
SELECT city, COUNT(*) 
FROM customers
WHERE COUNT(*) > 10  -- ERROR!
GROUP BY city;

-- ✅ CORRECT: Use HAVING
SELECT city, COUNT(*) 
FROM customers
GROUP BY city
HAVING COUNT(*) > 10;

-- ❌ WRONG: Filter after grouping when you could filter before
SELECT city, COUNT(*) 
FROM customers
GROUP BY city
HAVING city = 'New York';  -- Inefficient!

-- ✅ CORRECT: Use WHERE for non-aggregates
SELECT city, COUNT(*) 
FROM customers
WHERE city = 'New York'  -- Filter first (faster)
GROUP BY city;
```
</details>

---

## Advanced Aggregates

### Question 6: MIN and MAX (Medium)
Find the first and last order date for each customer.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    c.customer_id,
    c.name,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS customer_lifetime_days,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY lifetime_value DESC;
```

**Find customers who haven't ordered recently:**
```sql
SELECT 
    c.customer_id,
    c.name,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS days_since_last_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING MAX(o.order_date) < DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    OR MAX(o.order_date) IS NULL  -- Never ordered
ORDER BY days_since_last_order DESC;
```
</details>

---

### Question 7: Multiple Aggregates (Hard)
Create a sales summary showing:
- Total revenue
- Average order value
- Min/max order amount
- Standard deviation
- Number of orders

Group by month and product category.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    p.category,
    
    -- Count metrics
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    
    -- Revenue metrics
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    AVG(oi.quantity * oi.unit_price) AS avg_line_value,
    MIN(oi.quantity * oi.unit_price) AS min_line_value,
    MAX(oi.quantity * oi.unit_price) AS max_line_value,
    
    -- Quantity metrics
    SUM(oi.quantity) AS total_units_sold,
    AVG(oi.quantity) AS avg_units_per_order,
    
    -- Statistical metrics
    STDDEV(oi.quantity * oi.unit_price) AS revenue_stddev,
    VARIANCE(oi.quantity * oi.unit_price) AS revenue_variance
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
GROUP BY 
    DATE_FORMAT(o.order_date, '%Y-%m'),
    p.category
ORDER BY month DESC, total_revenue DESC;
```

**With ranking:**
```sql
SELECT 
    month,
    category,
    total_revenue,
    RANK() OVER (PARTITION BY month ORDER BY total_revenue DESC) AS category_rank
FROM monthly_sales
ORDER BY month DESC, category_rank;
```
</details>

---

## Conditional Aggregates

### Question 8: Filtered Aggregates (Hard)
Calculate metrics separately for different customer segments in one query.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    
    -- Total metrics
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_revenue,
    
    -- New customers (first order)
    COUNT(CASE WHEN is_first_order = 1 THEN 1 END) AS new_customer_orders,
    SUM(CASE WHEN is_first_order = 1 THEN total_amount END) AS new_customer_revenue,
    
    -- Repeat customers
    COUNT(CASE WHEN is_first_order = 0 THEN 1 END) AS repeat_orders,
    SUM(CASE WHEN is_first_order = 0 THEN total_amount END) AS repeat_revenue,
    
    -- High value orders (>$500)
    COUNT(CASE WHEN total_amount > 500 THEN 1 END) AS high_value_orders,
    SUM(CASE WHEN total_amount > 500 THEN total_amount END) AS high_value_revenue,
    
    -- By status
    COUNT(CASE WHEN status = 'completed' THEN 1 END) AS completed_orders,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) AS cancelled_orders,
    
    -- Percentages
    ROUND(
        COUNT(CASE WHEN is_first_order = 1 THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS new_customer_pct
FROM orders
WHERE order_date >= '2024-01-01'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month DESC;
```

**Alternative with FILTER (PostgreSQL):**
```sql
SELECT 
    month,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_first_order = 1) AS new_customer_orders,
    SUM(total_amount) FILTER (WHERE is_first_order = 1) AS new_customer_revenue
FROM orders
GROUP BY month;
```
</details>

---

## GROUP BY with JOINs

### Question 9: Multi-Table Aggregation (Hard)
Find top-selling products with customer demographics.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    
    -- Sales metrics
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    ROUND(AVG(oi.unit_price), 2) AS avg_selling_price,
    
    -- Customer metrics
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.quantity) / COUNT(DISTINCT o.customer_id), 2) AS avg_units_per_customer,
    
    -- Geographic distribution
    COUNT(DISTINCT c.city) AS cities_sold_in,
    COUNT(DISTINCT c.state) AS states_sold_in,
    
    -- Time metrics
    MIN(o.order_date) AS first_sale_date,
    MAX(o.order_date) AS last_sale_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS days_on_market
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY p.product_id, p.product_name, p.category
HAVING total_units_sold >= 100  -- Minimum threshold
ORDER BY total_revenue DESC
LIMIT 20;
```

**Common pitfall - double counting:**
```sql
-- ❌ WRONG: Will overcount due to multiple order items
SELECT 
    c.customer_id,
    COUNT(o.order_id) AS order_count  -- Wrong if order has multiple items!
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id;

-- ✅ CORRECT: Use DISTINCT
SELECT 
    c.customer_id,
    COUNT(DISTINCT o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id;
```
</details>

---

## Window Functions Preview

### Question 10: Running Totals (Expert)
Calculate running total of daily sales and compare to previous day.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
SELECT 
    order_date,
    daily_revenue,
    
    -- Running total (cumulative sum)
    SUM(daily_revenue) OVER (ORDER BY order_date) AS running_total,
    
    -- Previous day revenue
    LAG(daily_revenue, 1) OVER (ORDER BY order_date) AS prev_day_revenue,
    
    -- Day-over-day change
    daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date) AS daily_change,
    
    -- Percentage change
    ROUND(
        (daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY order_date)) 
        / LAG(daily_revenue, 1) OVER (ORDER BY order_date) * 100,
        2
    ) AS pct_change,
    
    -- 7-day moving average
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7d,
    
    -- Rank by revenue
    RANK() OVER (ORDER BY daily_revenue DESC) AS revenue_rank
FROM (
    SELECT 
        DATE(order_date) AS order_date,
        SUM(total_amount) AS daily_revenue
    FROM orders
    GROUP BY DATE(order_date)
) daily_sales
ORDER BY order_date;
```

**Window functions vs GROUP BY:**
- **GROUP BY**: Reduces rows (aggregation)
- **Window functions**: Keeps all rows, adds calculations

**Example output:**
```
order_date | daily_revenue | running_total | prev_day | daily_change | moving_avg_7d | rank
2024-01-01 | 5000         | 5000          | NULL     | NULL         | 5000.00       | 15
2024-01-02 | 7500         | 12500         | 5000     | 2500         | 6250.00       | 8
2024-01-03 | 6200         | 18700         | 7500     | -1300        | 6233.33       | 12
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 3 questions
- Medium: 3 questions
- Hard: 3 questions
- Expert: 1 question

**Topics Covered:**
- ✅ Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- ✅ GROUP BY single and multiple columns
- ✅ HAVING clause for filtering groups
- ✅ WHERE vs HAVING
- ✅ Conditional aggregates with CASE
- ✅ Multi-table aggregation with JOINs
- ✅ Statistical functions (STDDEV, VARIANCE)
- ✅ Window functions introduction

**Key Takeaways:**
- COUNT(*) counts all, COUNT(col) excludes NULLs
- AVG ignores NULL values
- WHERE filters before grouping, HAVING after
- Use DISTINCT in aggregates carefully (can be slow)
- Conditional aggregates: SUM(CASE WHEN ... THEN 1 END)
- Window functions keep all rows
- Watch for double-counting with JOINs

**Next Steps:**
- Chapter 9: Subqueries
- Practice with real sales data
- Build dashboards using aggregates
