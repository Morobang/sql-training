# SQL Examples

## 🎯 Learning Objectives

- See practical SQL queries in action
- Understand common query patterns
- Preview what you'll learn in future chapters
- Build excitement for your SQL journey!

---

## Introduction

Now that you understand SQL concepts, let's see SQL in action! These examples preview what you'll master throughout this course.

**Don't worry if you don't understand everything yet** - these are just previews. We'll cover each topic in detail in later chapters.

---

## 1. Basic Data Retrieval

### Simple SELECT

**Get all columns from a table:**

```sql
SELECT * 
FROM employees;
```

**Result:**
```
employee_id | first_name | last_name | salary  | dept_id
------------|------------|-----------|---------|--------
1           | Alice      | Smith     | 75000   | 10
2           | Bob        | Jones     | 68000   | 10
3           | Carol      | Davis     | 82000   | 20
```

---

### Select Specific Columns

```sql
SELECT first_name, last_name, salary
FROM employees;
```

**Result:**
```
first_name | last_name | salary
-----------|-----------|--------
Alice      | Smith     | 75000
Bob        | Jones     | 68000
Carol      | Davis     | 82000
```

---

### With Filtering (WHERE)

```sql
SELECT first_name, last_name, salary
FROM employees
WHERE salary > 70000;
```

**Result:**
```
first_name | last_name | salary
-----------|-----------|--------
Alice      | Smith     | 75000
Carol      | Davis     | 82000
```

---

### With Sorting (ORDER BY)

```sql
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC;
```

**Result (highest salary first):**
```
first_name | last_name | salary
-----------|-----------|--------
Carol      | Davis     | 82000
Alice      | Smith     | 75000
Bob        | Jones     | 68000
```

---

## 2. Filtering Data

### Multiple Conditions (AND)

```sql
SELECT product_name, price, stock
FROM products
WHERE price < 100
  AND stock > 10
  AND category = 'Electronics';
```

---

### Either Condition (OR)

```sql
SELECT customer_name, city
FROM customers
WHERE city = 'Boston'
   OR city = 'New York'
   OR city = 'Chicago';
```

---

### Range of Values (BETWEEN)

```sql
SELECT product_name, price
FROM products
WHERE price BETWEEN 50 AND 200;
```

---

### List of Values (IN)

```sql
SELECT employee_name, department
FROM employees
WHERE department IN ('IT', 'Sales', 'Marketing');
```

---

### Pattern Matching (LIKE)

```sql
-- Names starting with 'J'
SELECT first_name, last_name
FROM employees
WHERE first_name LIKE 'J%';

-- Emails ending with @company.com
SELECT name, email
FROM users
WHERE email LIKE '%@company.com';
```

---

### NULL Values

```sql
-- Find employees without assigned departments
SELECT name, department_id
FROM employees
WHERE department_id IS NULL;

-- Find employees with email addresses
SELECT name, email
FROM employees
WHERE email IS NOT NULL;
```

---

## 3. Joining Tables

### INNER JOIN (Matching Records Only)

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
```

**Result:**
```
first_name | last_name | department_name
-----------|-----------|----------------
Alice      | Smith     | IT
Bob        | Jones     | IT
Carol      | Davis     | Sales
```

---

### LEFT JOIN (All from Left Table)

```sql
SELECT 
    c.customer_name,
    o.order_id,
    o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
```

**Result (includes customers without orders):**
```
customer_name | order_id | order_date
--------------|----------|------------
John Smith    | 101      | 2024-11-01
John Smith    | 102      | 2024-11-05
Jane Doe      | NULL     | NULL        ← No orders
Mike Johnson  | 103      | 2024-11-03
```

---

### Multiple Joins

```sql
SELECT 
    c.customer_name,
    o.order_id,
    p.product_name,
    oi.quantity
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= '2024-01-01';
```

---

## 4. Aggregation & Grouping

### Basic Aggregates

```sql
-- Count employees
SELECT COUNT(*) AS total_employees
FROM employees;

-- Average salary
SELECT AVG(salary) AS average_salary
FROM employees;

-- Min and Max
SELECT 
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employees;

-- Total sales
SELECT SUM(order_total) AS total_revenue
FROM orders;
```

---

### GROUP BY

```sql
-- Count employees per department
SELECT 
    dept_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;
```

**Result:**
```
dept_id | employee_count | avg_salary
--------|----------------|------------
10      | 25             | 72500.00
20      | 18             | 68300.00
30      | 32             | 75800.00
```

---

### HAVING (Filter Groups)

```sql
-- Departments with more than 20 employees
SELECT 
    dept_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 20;
```

---

### Complex Aggregation

```sql
-- Sales summary by category
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS total_items_sold,
    SUM(oi.quantity * oi.price) AS total_revenue,
    AVG(oi.price) AS avg_price
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
INNER JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= '2024-01-01'
GROUP BY p.category
ORDER BY total_revenue DESC;
```

---

## 5. Subqueries

### Scalar Subquery (Single Value)

```sql
-- Employees earning more than average
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

---

### Subquery with IN

```sql
-- Customers who placed orders in November
SELECT customer_name, email
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE MONTH(order_date) = 11
);
```

---

### Correlated Subquery

```sql
-- Employees earning more than their department average
SELECT 
    e.name,
    e.salary,
    e.dept_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.dept_id = e.dept_id
);
```

---

## 6. Data Modification

### INSERT

**Single row:**
```sql
INSERT INTO customers (customer_name, email, city)
VALUES ('John Doe', 'john@example.com', 'Boston');
```

**Multiple rows:**
```sql
INSERT INTO products (product_name, price, stock)
VALUES 
    ('Laptop', 999.99, 50),
    ('Mouse', 29.99, 200),
    ('Keyboard', 79.99, 150);
```

---

### UPDATE

**Update specific rows:**
```sql
UPDATE employees
SET salary = salary * 1.10
WHERE performance_rating = 'Excellent';
```

**Update based on another table:**
```sql
UPDATE e
SET e.bonus = e.salary * 0.05
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Sales';
```

---

### DELETE

```sql
DELETE FROM orders
WHERE order_date < '2020-01-01'
  AND status = 'Cancelled';
```

---

## 7. Advanced Features

### Common Table Expression (CTE)

```sql
WITH high_earners AS (
    SELECT 
        dept_id,
        AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
    HAVING AVG(salary) > 70000
)
SELECT 
    d.dept_name,
    he.avg_salary
FROM high_earners he
INNER JOIN departments d ON he.dept_id = d.dept_id
ORDER BY he.avg_salary DESC;
```

---

### Window Functions

```sql
-- Rank employees by salary within each department
SELECT 
    first_name,
    last_name,
    dept_id,
    salary,
    RANK() OVER (
        PARTITION BY dept_id 
        ORDER BY salary DESC
    ) AS salary_rank
FROM employees;
```

**Result:**
```
first_name | dept_id | salary  | salary_rank
-----------|---------|---------|------------
Carol      | 10      | 85000   | 1
Alice      | 10      | 75000   | 2
Bob        | 10      | 68000   | 3
Mike       | 20      | 92000   | 1
Sarah      | 20      | 78000   | 2
```

---

### CASE Expression

```sql
SELECT 
    product_name,
    price,
    CASE 
        WHEN price < 50 THEN 'Budget'
        WHEN price BETWEEN 50 AND 200 THEN 'Mid-range'
        ELSE 'Premium'
    END AS price_category
FROM products;
```

---

### Running Totals

```sql
SELECT 
    order_date,
    order_total,
    SUM(order_total) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders;
```

---

## 8. Real-World Scenarios

### E-Commerce: Top Selling Products

```sql
SELECT 
    p.product_name,
    p.category,
    COUNT(oi.order_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.price) AS total_revenue
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
INNER JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= DATEADD(MONTH, -3, GETDATE())
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

### HR: Department Salary Analysis

```sql
SELECT 
    d.dept_name,
    COUNT(e.employee_id) AS employee_count,
    MIN(e.salary) AS min_salary,
    AVG(e.salary) AS avg_salary,
    MAX(e.salary) AS max_salary,
    SUM(e.salary) AS total_payroll
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_payroll DESC;
```

---

### Customer Analytics: Lifetime Value

```sql
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.join_date,
        COUNT(o.order_id) AS total_orders,
        SUM(o.order_total) AS lifetime_value,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.join_date
)
SELECT 
    customer_name,
    total_orders,
    lifetime_value,
    CASE 
        WHEN days_since_last_order <= 30 THEN 'Active'
        WHEN days_since_last_order <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END AS customer_status
FROM customer_stats
WHERE lifetime_value > 1000
ORDER BY lifetime_value DESC;
```

---

### Inventory Management: Low Stock Alert

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.stock_quantity,
    p.reorder_level,
    (p.reorder_level - p.stock_quantity) AS units_to_order,
    COALESCE(v.vendor_name, 'No Vendor') AS vendor,
    COALESCE(v.lead_time_days, 0) AS lead_time
FROM products p
LEFT JOIN vendors v ON p.vendor_id = v.vendor_id
WHERE p.stock_quantity < p.reorder_level
  AND p.is_active = 1
ORDER BY units_to_order DESC;
```

---

## 9. Database Objects

### Create View

```sql
CREATE VIEW active_employees AS
SELECT 
    employee_id,
    first_name,
    last_name,
    email,
    dept_id,
    salary
FROM employees
WHERE status = 'Active';

-- Use it like a table
SELECT * FROM active_employees WHERE dept_id = 10;
```

---

### Create Stored Procedure

```sql
CREATE PROCEDURE GetCustomerOrders
    @CustomerID INT,
    @StartDate DATE = NULL
AS
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        o.order_total,
        COUNT(oi.item_id) AS item_count
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
      AND (@StartDate IS NULL OR o.order_date >= @StartDate)
    GROUP BY o.order_id, o.order_date, o.order_total
    ORDER BY o.order_date DESC;
END;

-- Execute it
EXEC GetCustomerOrders @CustomerID = 123, @StartDate = '2024-01-01';
```

---

## 10. Transaction Example

```sql
BEGIN TRANSACTION;

-- Deduct from inventory
UPDATE products
SET stock_quantity = stock_quantity - 5
WHERE product_id = 101;

-- Create order
INSERT INTO orders (customer_id, order_date, order_total)
VALUES (123, GETDATE(), 499.95);

DECLARE @OrderID INT = SCOPE_IDENTITY();

-- Add order items
INSERT INTO order_items (order_id, product_id, quantity, price)
VALUES (@OrderID, 101, 5, 99.99);

-- If everything succeeded, commit
COMMIT;
-- If there was an error, it would ROLLBACK
```

---

## 🎯 What You'll Master

By the end of this course, you'll be able to write all these queries and more!

**You'll learn:**
- ✅ Basic SELECT queries (Chapter 3)
- ✅ Filtering with WHERE (Chapter 4)
- ✅ Joining tables (Chapter 5)
- ✅ Aggregation & GROUP BY (Chapter 8)
- ✅ Subqueries (Chapter 9)
- ✅ Window functions (Chapter 16)
- ✅ Data modification (Chapter 2)
- ✅ Performance optimization (Chapter 13)
- ✅ And much more!

---

## 🧠 Key Takeaways

1. SQL is powerful yet readable
2. Complex operations can be expressed simply
3. Joins connect related data
4. Aggregations summarize data
5. Subqueries enable sophisticated logic
6. Window functions provide advanced analytics
7. Real-world queries combine multiple concepts

---

## 📝 Try It Yourself

Once you've set up your database (Chapter 2), try modifying these queries:
- Change the WHERE conditions
- Add different columns to SELECT
- Try different ORDER BY criteria
- Experiment with GROUP BY
- Build your own queries!

---

## ⏭️ Next Lesson

Continue with: **[09 - What is SQL Server?](../09-what-is-mysql/)** - Learn about Microsoft SQL Server and its ecosystem.

---

## 📚 Additional Resources

- [SQL Zoo - Interactive Tutorial](https://sqlzoo.net/)
- [W3Schools SQL Tutorial](https://www.w3schools.com/sql/)
- [SQL Fiddle - Test Queries Online](http://sqlfiddle.com/)
- [SQL Server Sample Databases](https://docs.microsoft.com/sql/samples/)
