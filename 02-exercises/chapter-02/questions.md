# Chapter 2: Creating and Populating a Database - Practice Questions

## Overview
Test your understanding of database creation, data types, table design, and data manipulation (INSERT, UPDATE, DELETE).

---

## Multiple Choice Questions

### Question 1: Database Creation (Easy)
Which SQL command creates a new database?

- A) CREATE DB library;
- B) CREATE DATABASE library;
- C) NEW DATABASE library;
- D) MAKE DATABASE library;

<details>
<summary>Click to see answer</summary>

**Answer: B) CREATE DATABASE library;**

```sql
CREATE DATABASE library;
USE library;
```
</details>

---

### Question 2: Data Types (Easy)
Which data type would you use to store someone's email address?

- A) INT
- B) VARCHAR(100)
- C) DATE
- D) DECIMAL

<details>
<summary>Click to see answer</summary>

**Answer: B) VARCHAR(100)**

VARCHAR is variable-length character data, perfect for text like emails. The number (100) specifies maximum length.

```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(100) NOT NULL UNIQUE
);
```
</details>

---

### Question 3: Numeric Data Types (Medium)
You need to store product prices like $19.99. Which data type is most appropriate?

- A) INT
- B) FLOAT
- C) DECIMAL(10,2)
- D) VARCHAR(10)

<details>
<summary>Click to see answer</summary>

**Answer: C) DECIMAL(10,2)**

**Explanation:**
- DECIMAL(10,2) = up to 10 digits total, 2 after decimal point
- Use DECIMAL for money (exact precision)
- FLOAT can have rounding errors
- Max value: 99,999,999.99

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2)  -- Stores $19.99 exactly
);
```
</details>

---

### Question 4: Temporal Data Types (Medium)
Which data type stores both date AND time?

- A) DATE
- B) TIME
- C) DATETIME
- D) YEAR

<details>
<summary>Click to see answer</summary>

**Answer: C) DATETIME**

**Data Type Differences:**
- DATE: '2024-01-15' (date only)
- TIME: '14:30:00' (time only)
- DATETIME: '2024-01-15 14:30:00' (both)
- TIMESTAMP: Like DATETIME but auto-updates
- YEAR: '2024' (year only)

```sql
CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_name VARCHAR(100),
    appointment_datetime DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
</details>

---

### Question 5: Primary Key Constraint (Medium)
What happens if you try to insert a duplicate value into a PRIMARY KEY column?

- A) The database automatically generates a new unique value
- B) The insert fails with an error
- C) The old row is updated
- D) Both rows are stored

<details>
<summary>Click to see answer</summary>

**Answer: B) The insert fails with an error**

```sql
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(50)
);

INSERT INTO employees VALUES (1, 'John');
INSERT INTO employees VALUES (1, 'Jane');  -- ERROR: Duplicate entry '1'
```

**Primary Key Rules:**
- Must be UNIQUE
- Cannot be NULL
- Only one per table (can be composite)
- Automatically creates index
</details>

---

## SQL Practice Questions

### Question 6: Create Table (Medium)
Write SQL to create a `customers` table with:
- customer_id (primary key, integer)
- first_name (up to 50 characters)
- last_name (up to 50 characters)
- email (unique, up to 100 characters)
- registration_date (date)

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    registration_date DATE DEFAULT CURRENT_DATE
);
```

**Alternative with AUTO_INCREMENT:**
```sql
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    registration_date DATE DEFAULT CURRENT_DATE
);
```
</details>

---

### Question 7: Insert Data (Easy)
Insert a customer into the table created above:
- Name: Alice Johnson
- Email: alice@email.com
- Registration date: 2024-01-15

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Method 1: Specify all columns
INSERT INTO customers (customer_id, first_name, last_name, email, registration_date)
VALUES (1, 'Alice', 'Johnson', 'alice@email.com', '2024-01-15');

-- Method 2: Let AUTO_INCREMENT handle ID, use DEFAULT for date
INSERT INTO customers (first_name, last_name, email)
VALUES ('Alice', 'Johnson', 'alice@email.com');

-- Method 3: Multiple rows at once
INSERT INTO customers (first_name, last_name, email) VALUES
('Alice', 'Johnson', 'alice@email.com'),
('Bob', 'Smith', 'bob@email.com'),
('Charlie', 'Brown', 'charlie@email.com');
```
</details>

---

### Question 8: Update Data (Medium)
Write SQL to update customer with ID 1 to change their email to 'alice.johnson@newmail.com'

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
UPDATE customers
SET email = 'alice.johnson@newmail.com'
WHERE customer_id = 1;
```

**⚠️ WARNING - Without WHERE clause:**
```sql
-- DANGER: Updates ALL rows!
UPDATE customers
SET email = 'alice.johnson@newmail.com';  -- Missing WHERE!
```

**Update multiple columns:**
```sql
UPDATE customers
SET 
    email = 'alice.johnson@newmail.com',
    first_name = 'Alicia'
WHERE customer_id = 1;
```
</details>

---

### Question 9: Delete Data (Medium)
Write SQL to delete the customer with email 'bob@email.com'

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
DELETE FROM customers
WHERE email = 'bob@email.com';
```

**⚠️ CRITICAL WARNING:**
```sql
-- DISASTER: Deletes ALL rows!
DELETE FROM customers;  -- Missing WHERE!
```

**Safe practices:**
```sql
-- 1. Check before deleting
SELECT * FROM customers WHERE email = 'bob@email.com';

-- 2. Use transaction for safety
START TRANSACTION;
DELETE FROM customers WHERE email = 'bob@email.com';
SELECT * FROM customers;  -- Verify
COMMIT;  -- or ROLLBACK to undo
```
</details>

---

## Advanced Questions

### Question 10: Table Constraints (Hard)
Create an `orders` table with:
- order_id (primary key)
- customer_id (foreign key to customers)
- order_date (defaults to current date)
- total_amount (must be > 0)
- status (must be 'pending', 'shipped', or 'delivered')

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount > 0),
    status ENUM('pending', 'shipped', 'delivered') DEFAULT 'pending',
    
    CONSTRAINT fk_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT  -- Prevent deleting customer with orders
        ON UPDATE CASCADE   -- Update order if customer_id changes
);
```

**Constraint Types Explained:**

1. **PRIMARY KEY**: Unique identifier
2. **FOREIGN KEY**: Links to customers table
3. **CHECK**: Ensures total_amount > 0
4. **ENUM**: Restricts status to specific values
5. **DEFAULT**: Sets default values
6. **NOT NULL**: Prevents null values
7. **ON DELETE RESTRICT**: Can't delete parent row
8. **ON UPDATE CASCADE**: Updates propagate to child rows
</details>

---

### Question 11: Alter Table (Hard)
The `customers` table needs a phone number column. Add it as VARCHAR(20), allowing NULL values.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- Add new column
ALTER TABLE customers
ADD COLUMN phone VARCHAR(20);

-- Add with constraint
ALTER TABLE customers
ADD COLUMN phone VARCHAR(20) UNIQUE;

-- Drop column if needed
ALTER TABLE customers
DROP COLUMN phone;

-- Modify existing column
ALTER TABLE customers
MODIFY COLUMN email VARCHAR(150);  -- Increase size

-- Add constraint to existing column
ALTER TABLE customers
ADD CONSTRAINT chk_email CHECK (email LIKE '%@%');
```
</details>

---

## Real-World Scenario

### Question 12: E-Commerce Database Design (Expert)
Design a minimal e-commerce database with tables for:
1. Products (id, name, price, stock_quantity)
2. Customers (id, name, email)
3. Orders (id, customer_id, order_date, total)
4. Order_Items (links orders to products with quantity)

Write the CREATE TABLE statements with appropriate constraints.

<details>
<summary>Click to see answer</summary>

**Answer:**

```sql
-- 1. Products table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Customers table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_email (email)  -- Speed up email lookups
);

-- 3. Orders table
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') 
        DEFAULT 'pending',
    
    CONSTRAINT fk_order_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    INDEX idx_customer (customer_id),
    INDEX idx_order_date (order_date)
);

-- 4. Order_Items junction table (many-to-many)
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    
    CONSTRAINT fk_item_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(order_id)
        ON DELETE CASCADE,  -- Delete items if order deleted
    
    CONSTRAINT fk_item_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
        ON DELETE RESTRICT,  -- Can't delete product in orders
    
    INDEX idx_order (order_id),
    INDEX idx_product (product_id)
);
```

**Sample Data:**

```sql
-- Insert products
INSERT INTO products (name, price, stock_quantity) VALUES
('Laptop', 999.99, 50),
('Mouse', 24.99, 200),
('Keyboard', 79.99, 150);

-- Insert customer
INSERT INTO customers (first_name, last_name, email) VALUES
('John', 'Doe', 'john@email.com');

-- Insert order
INSERT INTO orders (customer_id, total_amount) VALUES
(1, 1104.97);  -- Laptop + Mouse + Keyboard

-- Insert order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 999.99),   -- 1 Laptop
(1, 2, 2, 24.99),    -- 2 Mice
(1, 3, 1, 79.99);    -- 1 Keyboard

-- Query: View order details
SELECT 
    o.order_id,
    c.first_name,
    c.last_name,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_id = 1;
```
</details>

---

## Common Errors & Fixes

### Question 13: Debugging (Hard)
What's wrong with this CREATE TABLE statement?

```sql
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    employee_id INT  -- Duplicate column!
);
```

<details>
<summary>Click to see answer</summary>

**Problems:**

1. **Duplicate column name** `employee_id` appears twice
2. **Missing NOT NULL constraints** for critical fields
3. **No DEFAULT or AUTO_INCREMENT** for primary key
4. **No CHECK constraint** on salary (could be negative)

**Fixed version:**

```sql
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL CHECK (salary >= 0),
    hire_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 3 questions
- Medium: 7 questions  
- Hard: 3 questions
- Expert: 1 question

**Topics Covered:**
- ✅ CREATE DATABASE & USE
- ✅ Data types (VARCHAR, INT, DECIMAL, DATE, DATETIME)
- ✅ CREATE TABLE with constraints
- ✅ INSERT, UPDATE, DELETE operations
- ✅ PRIMARY KEY & FOREIGN KEY
- ✅ ALTER TABLE statements
- ✅ CHECK constraints & ENUM types
- ✅ Real-world database design

**Next Steps:**
- Practice with the Sakila database
- Move to Chapter 3 (Query Primer)
- Build your own small database project
