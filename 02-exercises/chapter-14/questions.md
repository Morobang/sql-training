# Chapter 14: Views - Practice Questions

## Overview
Master view creation, updatable views, materialized views, view performance, and security applications.

---

## View Basics

### Question 1: Creating Basic Views (Easy)
Create a view for active customers with their order statistics.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Basic view definition
CREATE VIEW vw_active_customers AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.join_date,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.name, c.email, c.join_date;

-- Use the view
SELECT * FROM vw_active_customers
WHERE total_orders > 5
ORDER BY lifetime_value DESC
LIMIT 10;

-- View metadata
SHOW CREATE VIEW vw_active_customers;
DESC vw_active_customers;

-- Drop view
DROP VIEW IF EXISTS vw_active_customers;
```

**Benefits:**
- Simplifies complex queries
- Encapsulates business logic
- Provides consistent data access
- Hides underlying schema complexity

**Creating view with options:**
```sql
CREATE OR REPLACE VIEW vw_high_value_customers AS
SELECT 
    customer_id,
    name,
    email,
    lifetime_value
FROM vw_active_customers
WHERE lifetime_value > 10000;

-- OR REPLACE: Updates existing view without dropping
```

**Checking if view exists:**
```sql
-- MySQL
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'your_database'
  AND TABLE_NAME = 'vw_active_customers';

-- Create only if doesn't exist
CREATE VIEW IF NOT EXISTS vw_active_customers AS
SELECT ...;
```

</details>

---

### Question 2: View Security and Permissions (Medium)
How can views enhance database security?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Use Case 1: Hide Sensitive Columns**

```sql
-- Table with sensitive data
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    salary DECIMAL(10,2),          -- Sensitive
    ssn VARCHAR(11),               -- Sensitive
    performance_rating DECIMAL(3,2), -- Sensitive
    department VARCHAR(50),
    hire_date DATE
);

-- Public view (HR department)
CREATE VIEW vw_employee_directory AS
SELECT 
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    department,
    hire_date,
    YEAR(CURDATE()) - YEAR(hire_date) AS years_of_service
FROM employees;
-- Excludes: salary, SSN, performance rating

-- Grant access to view only
GRANT SELECT ON vw_employee_directory TO 'regular_users'@'%';
REVOKE ALL PRIVILEGES ON employees FROM 'regular_users'@'%';
```

---

**Use Case 2: Row-Level Security**

```sql
-- Multi-tenant application
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    tenant_id INT,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2)
);

-- View filtered by current user's tenant
CREATE VIEW vw_my_orders AS
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE tenant_id = (SELECT tenant_id FROM users WHERE username = CURRENT_USER());

-- Users only see their own tenant's data
GRANT SELECT ON vw_my_orders TO 'tenant_user'@'%';
```

---

**Use Case 3: Regional Data Isolation**

```sql
-- Sales data by region
CREATE VIEW vw_sales_us AS
SELECT 
    sale_id,
    customer_id,
    product_id,
    sale_date,
    amount
FROM sales
WHERE region = 'US';

CREATE VIEW vw_sales_eu AS
SELECT 
    sale_id,
    customer_id,
    product_id,
    sale_date,
    amount
FROM sales
WHERE region = 'EU';

-- Grant regional access
GRANT SELECT ON vw_sales_us TO 'us_sales_team'@'%';
GRANT SELECT ON vw_sales_eu TO 'eu_sales_team'@'%';

-- No access to full sales table
REVOKE ALL PRIVILEGES ON sales FROM 'us_sales_team'@'%';
REVOKE ALL PRIVILEGES ON sales FROM 'eu_sales_team'@'%';
```

---

**Use Case 4: Calculated Fields Only**

```sql
-- Financial data view for analysts
CREATE VIEW vw_financial_metrics AS
SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS month,
    category,
    SUM(amount) AS total_revenue,
    COUNT(*) AS transaction_count,
    AVG(amount) AS avg_transaction,
    -- No individual transaction details
    RANK() OVER (PARTITION BY category ORDER BY SUM(amount) DESC) AS revenue_rank
FROM transactions
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m'), category;

-- Analysts see aggregates, not individual transactions
GRANT SELECT ON vw_financial_metrics TO 'analyst_role'@'%';
```

---

**Use Case 5: Masked Data for Development**

```sql
-- Production-like data for testing
CREATE VIEW vw_customers_dev AS
SELECT 
    customer_id,
    CONCAT('Customer_', customer_id) AS name,           -- Fake name
    CONCAT('email', customer_id, '@example.com') AS email, -- Fake email
    LEFT(phone, 3) || '-XXX-XXXX' AS phone,            -- Masked phone
    city,
    state,
    -- Real: city, state for testing geo features
    -- Masked: name, email, phone for privacy
    registration_date
FROM customers;

GRANT SELECT ON vw_customers_dev TO 'developer_role'@'%';
```

---

**Best Practices:**

| Practice | Why |
|----------|-----|
| **Principle of Least Privilege** | Grant view access, not table access |
| **Hide Sensitive Columns** | PII, salaries, credentials |
| **Row-Level Filtering** | Multi-tenancy, regional data |
| **Audit Trail** | Log view access with triggers |
| **Read-Only Views** | Prevent accidental updates |
| **Parameterized Views** | Use CURRENT_USER() for filtering |

```sql
-- Check view permissions
SHOW GRANTS FOR 'username'@'localhost';

-- Revoke table access
REVOKE ALL PRIVILEGES ON database.* FROM 'username'@'localhost';

-- Grant view access
GRANT SELECT ON database.vw_* TO 'username'@'localhost';
```

</details>

---

## Updatable Views

### Question 3: When Are Views Updatable? (Hard)
What conditions make a view updatable? Provide examples.

<details>
<summary>Click to see answer</summary>

**Answer:**

**MySQL Updatable View Requirements:**

✅ **Updatable** - Must meet ALL criteria:
1. No DISTINCT
2. No GROUP BY or HAVING
3. No aggregate functions (SUM, COUNT, etc.)
4. No UNION or subqueries in FROM
5. No joins (for INSERT/DELETE)
6. References only base tables

---

**Example 1: Simple Updatable View**

```sql
-- Updatable view
CREATE VIEW vw_active_products AS
SELECT 
    product_id,
    product_name,
    price,
    stock_quantity
FROM products
WHERE status = 'active';

-- ✅ INSERT works
INSERT INTO vw_active_products (product_name, price, stock_quantity)
VALUES ('New Product', 99.99, 100);
-- Inserts into products table with status=NULL (check trigger needed)

-- ✅ UPDATE works
UPDATE vw_active_products
SET price = price * 1.10
WHERE product_id = 123;

-- ✅ DELETE works
DELETE FROM vw_active_products WHERE product_id = 999;
```

---

**Example 2: WITH CHECK OPTION**

```sql
-- View with CHECK OPTION
CREATE VIEW vw_premium_products AS
SELECT 
    product_id,
    product_name,
    price,
    category
FROM products
WHERE price > 100
WITH CHECK OPTION;

-- ✅ Allowed: Maintains view condition
UPDATE vw_premium_products SET price = 150 WHERE product_id = 1;

-- ❌ Error: Violates CHECK OPTION (price < 100)
UPDATE vw_premium_products SET price = 50 WHERE product_id = 1;
-- ERROR: CHECK OPTION failed 'db.vw_premium_products'

-- ❌ Error: Cannot insert product with price < 100
INSERT INTO vw_premium_products (product_name, price, category)
VALUES ('Cheap Product', 20, 'Budget');
-- ERROR: CHECK OPTION failed
```

**Types of CHECK OPTION:**
```sql
-- LOCAL: Checks only this view's condition
CREATE VIEW vw_level1 AS
SELECT * FROM products WHERE price > 50
WITH LOCAL CHECK OPTION;

-- CASCADED: Checks all views in chain (default)
CREATE VIEW vw_level2 AS
SELECT * FROM vw_level1 WHERE category = 'Electronics'
WITH CASCADED CHECK OPTION;
-- Checks both price > 50 AND category = 'Electronics'
```

---

**Example 3: Non-Updatable Views**

```sql
-- ❌ Not updatable: Contains aggregates
CREATE VIEW vw_category_stats AS
SELECT 
    category,
    COUNT(*) AS product_count,
    AVG(price) AS avg_price
FROM products
GROUP BY category;

UPDATE vw_category_stats SET avg_price = 100;  -- ERROR

---

-- ❌ Not updatable: Contains JOIN
CREATE VIEW vw_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    c.email
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

UPDATE vw_order_details SET customer_name = 'New Name';  -- ERROR
DELETE FROM vw_order_details WHERE order_id = 1;        -- ERROR

---

-- ❌ Not updatable: DISTINCT
CREATE VIEW vw_unique_cities AS
SELECT DISTINCT city FROM customers;

INSERT INTO vw_unique_cities VALUES ('New York');  -- ERROR

---

-- ❌ Not updatable: Subquery in SELECT
CREATE VIEW vw_customers_with_orders AS
SELECT 
    customer_id,
    name,
    (SELECT COUNT(*) FROM orders WHERE customer_id = c.customer_id) AS order_count
FROM customers c;

UPDATE vw_customers_with_orders SET name = 'Updated';  -- ERROR
```

---

**Example 4: INSTEAD OF Triggers (SQL Server)**

```sql
-- SQL Server: Make any view updatable with triggers
CREATE VIEW vw_customer_summary AS
SELECT 
    c.customer_id,
    c.name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

-- CREATE INSTEAD OF trigger
CREATE TRIGGER trg_update_customer_summary
ON vw_customer_summary
INSTEAD OF UPDATE
AS
BEGIN
    UPDATE customers
    SET name = (SELECT name FROM inserted)
    WHERE customer_id = (SELECT customer_id FROM inserted);
END;

-- Now updates work (routed through trigger)
UPDATE vw_customer_summary SET name = 'New Name' WHERE customer_id = 1;
```

---

**Checking if view is updatable:**

```sql
-- MySQL
SELECT 
    TABLE_NAME,
    IS_UPDATABLE
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'your_database';

-- Example output:
-- vw_active_products    | YES
-- vw_category_stats     | NO
-- vw_order_details      | NO
```

---

**Best Practices:**

| Scenario | Recommendation |
|----------|----------------|
| **Simple filtering** | Use WITH CHECK OPTION |
| **Security views** | Read-only, no updates |
| **Complex aggregates** | Never updatable |
| **Joined views** | Use INSTEAD OF triggers (if needed) |
| **Data entry forms** | Updatable views with defaults |

**When to allow updates:**
- ✅ Simple filtering views (status, region)
- ✅ Column subsetting (hiding sensitive fields)
- ❌ Aggregated data
- ❌ Complex joins
- ❌ Calculated fields

</details>

---

## Materialized Views

### Question 4: Materialized Views Simulation (Expert)
MySQL doesn't support materialized views. How would you implement one?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Materialized View = Stored query result that's periodically refreshed**

---

**Method 1: Table + Event Scheduler**

```sql
-- Create materialized view table
CREATE TABLE mv_daily_sales_summary (
    summary_date DATE PRIMARY KEY,
    total_sales DECIMAL(15,2),
    order_count INT,
    avg_order_value DECIMAL(10,2),
    unique_customers INT,
    last_refreshed TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Initial population
INSERT INTO mv_daily_sales_summary
SELECT 
    DATE(order_date) AS summary_date,
    SUM(total_amount) AS total_sales,
    COUNT(*) AS order_count,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers,
    NOW() AS last_refreshed
FROM orders
WHERE order_date >= CURDATE() - INTERVAL 365 DAY
GROUP BY DATE(order_date);

-- Refresh procedure
DELIMITER $$
CREATE PROCEDURE sp_refresh_daily_sales()
BEGIN
    -- Full refresh (simple approach)
    TRUNCATE TABLE mv_daily_sales_summary;
    
    INSERT INTO mv_daily_sales_summary
    SELECT 
        DATE(order_date),
        SUM(total_amount),
        COUNT(*),
        AVG(total_amount),
        COUNT(DISTINCT customer_id),
        NOW()
    FROM orders
    WHERE order_date >= CURDATE() - INTERVAL 365 DAY
    GROUP BY DATE(order_date);
END$$
DELIMITER ;

-- Schedule refresh (every hour)
CREATE EVENT evt_refresh_daily_sales
ON SCHEDULE EVERY 1 HOUR
DO CALL sp_refresh_daily_sales();

-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- Query materialized view (fast!)
SELECT * FROM mv_daily_sales_summary
WHERE summary_date >= '2024-01-01'
ORDER BY summary_date;
```

---

**Method 2: Incremental Refresh**

```sql
-- Track last refresh time
CREATE TABLE mv_refresh_log (
    view_name VARCHAR(100) PRIMARY KEY,
    last_refresh TIMESTAMP
);

INSERT INTO mv_refresh_log VALUES ('mv_daily_sales_summary', '1900-01-01');

-- Incremental refresh procedure
DELIMITER $$
CREATE PROCEDURE sp_refresh_incremental()
BEGIN
    DECLARE last_refresh TIMESTAMP;
    
    -- Get last refresh time
    SELECT last_refresh INTO last_refresh
    FROM mv_refresh_log
    WHERE view_name = 'mv_daily_sales_summary';
    
    -- Delete changed dates
    DELETE FROM mv_daily_sales_summary
    WHERE summary_date IN (
        SELECT DISTINCT DATE(order_date)
        FROM orders
        WHERE updated_at > last_refresh OR created_at > last_refresh
    );
    
    -- Re-insert changed dates
    INSERT INTO mv_daily_sales_summary
    SELECT 
        DATE(order_date),
        SUM(total_amount),
        COUNT(*),
        AVG(total_amount),
        COUNT(DISTINCT customer_id),
        NOW()
    FROM orders
    WHERE updated_at > last_refresh OR created_at > last_refresh
    GROUP BY DATE(order_date);
    
    -- Update refresh log
    UPDATE mv_refresh_log 
    SET last_refresh = NOW()
    WHERE view_name = 'mv_daily_sales_summary';
END$$
DELIMITER ;
```

---

**Method 3: Trigger-Based Maintenance**

```sql
-- Create materialized view with trigger updates
CREATE TABLE mv_product_inventory (
    product_id INT PRIMARY KEY,
    total_in_stock INT,
    total_reserved INT,
    available INT,
    last_updated TIMESTAMP
);

-- Initial load
INSERT INTO mv_product_inventory
SELECT 
    product_id,
    stock_quantity,
    reserved_quantity,
    stock_quantity - reserved_quantity,
    NOW()
FROM products;

-- Trigger to maintain MV
DELIMITER $$
CREATE TRIGGER trg_update_inventory_mv
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.stock_quantity != OLD.stock_quantity OR 
       NEW.reserved_quantity != OLD.reserved_quantity THEN
        
        INSERT INTO mv_product_inventory (product_id, total_in_stock, total_reserved, available, last_updated)
        VALUES (NEW.product_id, NEW.stock_quantity, NEW.reserved_quantity, 
                NEW.stock_quantity - NEW.reserved_quantity, NOW())
        ON DUPLICATE KEY UPDATE
            total_in_stock = NEW.stock_quantity,
            total_reserved = NEW.reserved_quantity,
            available = NEW.stock_quantity - NEW.reserved_quantity,
            last_updated = NOW();
    END IF;
END$$
DELIMITER ;

-- Query is instant (pre-computed)
SELECT * FROM mv_product_inventory WHERE available > 0;
```

---

**Method 4: Application-Level Caching**

```python
# Python application with Redis caching
import redis
import mysql.connector
from datetime import timedelta

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def get_sales_summary(date):
    """Get sales summary with caching"""
    cache_key = f"sales_summary:{date}"
    
    # Check cache
    cached = redis_client.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Query database
    conn = mysql.connector.connect(...)
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT 
            DATE(order_date) as date,
            SUM(total_amount) as total_sales,
            COUNT(*) as order_count
        FROM orders
        WHERE DATE(order_date) = %s
    """, (date,))
    
    result = cursor.fetchone()
    
    # Cache for 1 hour
    redis_client.setex(cache_key, timedelta(hours=1), json.dumps(result))
    
    return result

# Invalidate cache on updates
def place_order(order_data):
    # Insert order...
    
    # Invalidate today's summary
    cache_key = f"sales_summary:{datetime.now().date()}"
    redis_client.delete(cache_key)
```

---

**Comparison:**

| Method | Pros | Cons | Use Case |
|--------|------|------|----------|
| **Event Scheduler** | Simple, automatic | Stale data between refreshes | Hourly/daily reports |
| **Incremental** | Efficient, faster refresh | Complex logic | Large datasets |
| **Triggers** | Always current | Write overhead | Critical real-time data |
| **App Cache** | Very fast, flexible | Requires application changes | API responses |

---

**PostgreSQL Materialized Views (reference):**
```sql
-- Native support in PostgreSQL
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT 
    DATE(order_date) AS summary_date,
    SUM(total_amount) AS total_sales
FROM orders
GROUP BY DATE(order_date);

-- Refresh
REFRESH MATERIALIZED VIEW mv_daily_sales;

-- Concurrent refresh (allows queries during refresh)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;
```

**Best practices:**
- Use for expensive aggregations
- Schedule refreshes during off-peak hours
- Add indexes to materialized tables
- Monitor staleness
- Document refresh frequency
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 1 question
- Medium: 1 question
- Hard: 1 question
- Expert: 1 question

**Topics Covered:**
- ✅ View creation and usage
- ✅ Security and permissions
- ✅ Updatable views with CHECK OPTION
- ✅ Materialized view implementation

**Key Takeaways:**
- Views simplify complex queries
- Use views for security (hide columns/rows)
- WITH CHECK OPTION enforces constraints
- Updatable views have strict requirements
- MySQL needs manual materialized view implementation

**Next Steps:**
- Chapter 15: Metadata
- Practice view-based security patterns
