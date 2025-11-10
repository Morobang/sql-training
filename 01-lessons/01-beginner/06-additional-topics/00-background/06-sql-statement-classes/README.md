# SQL Statement Classes

## 🎯 Learning Objectives

- Understand the four main classes of SQL statements
- Learn DDL (Data Definition Language) commands
- Master DML (Data Manipulation Language) operations
- Explore DCL (Data Control Language) for security
- Understand TCL (Transaction Control Language) for data integrity

---

## SQL Statement Categories

SQL statements are organized into four main classes based on their purpose:

```
┌─────────────────────────────────────────────────────┐
│                    SQL STATEMENTS                   │
├─────────────┬──────────────┬──────────┬─────────────┤
│     DDL     │     DML      │   DCL    │     TCL     │
│  (Define)   │ (Manipulate) │ (Control)│ (Transact)  │
├─────────────┼──────────────┼──────────┼─────────────┤
│   CREATE    │    SELECT    │  GRANT   │   BEGIN     │
│   ALTER     │    INSERT    │  REVOKE  │   COMMIT    │
│   DROP      │    UPDATE    │  DENY    │   ROLLBACK  │
│   TRUNCATE  │    DELETE    │          │   SAVE      │
└─────────────┴──────────────┴──────────┴─────────────┘
```

---

## 1. DDL - Data Definition Language

**Purpose:** Define and modify database structure

**Key Commands:** CREATE, ALTER, DROP, TRUNCATE

### CREATE - Build Database Objects

**Create a Database:**
```sql
CREATE DATABASE CompanyDB;
```

**Create a Table:**
```sql
CREATE TABLE employees (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE DEFAULT GETDATE(),
    salary DECIMAL(10,2) CHECK (salary > 0),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
```

**Create an Index:**
```sql
CREATE INDEX idx_last_name ON employees(last_name);
```

**Create a View:**
```sql
CREATE VIEW active_employees AS
SELECT employee_id, first_name, last_name, email
FROM employees
WHERE status = 'Active';
```

---

### ALTER - Modify Existing Objects

**Add a Column:**
```sql
ALTER TABLE employees
ADD phone_number VARCHAR(20);
```

**Modify a Column:**
```sql
ALTER TABLE employees
ALTER COLUMN phone_number VARCHAR(30);
```

**Drop a Column:**
```sql
ALTER TABLE employees
DROP COLUMN phone_number;
```

**Add a Constraint:**
```sql
ALTER TABLE employees
ADD CONSTRAINT chk_email CHECK (email LIKE '%@%.%');
```

---

### DROP - Delete Database Objects

**Drop a Table:**
```sql
DROP TABLE old_employees;
```

**Drop a Database:**
```sql
DROP DATABASE OldCompanyDB;
```

**Drop an Index:**
```sql
DROP INDEX idx_last_name ON employees;
```

⚠️ **Warning:** DROP permanently deletes objects and their data!

---

### TRUNCATE - Remove All Rows

**Truncate a Table:**
```sql
TRUNCATE TABLE temp_data;
```

**Characteristics:**
- ✅ Faster than DELETE (no logging of individual rows)
- ✅ Resets IDENTITY counters
- ❌ Cannot be rolled back (in some systems)
- ❌ Cannot use WHERE clause
- ❌ Cannot use with foreign key references

**When to Use:**
- Clearing staging tables
- Resetting test data
- Emptying audit logs

---

## 2. DML - Data Manipulation Language

**Purpose:** Manipulate data within tables

**Key Commands:** SELECT, INSERT, UPDATE, DELETE

### SELECT - Retrieve Data ⭐ Most Used!

**Basic Query:**
```sql
SELECT first_name, last_name, salary
FROM employees
WHERE department_id = 5
ORDER BY salary DESC;
```

**With Joins:**
```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name,
    e.salary
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'IT';
```

**With Aggregation:**
```sql
SELECT 
    department_id,
    COUNT(*) AS employee_count,
    AVG(salary) AS average_salary,
    MAX(salary) AS max_salary
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5;
```

**With Subquery:**
```sql
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

---

### INSERT - Add New Data

**Insert Single Row:**
```sql
INSERT INTO employees (first_name, last_name, email, hire_date, salary, department_id)
VALUES ('John', 'Smith', 'john.smith@company.com', '2024-11-07', 75000.00, 3);
```

**Insert Multiple Rows:**
```sql
INSERT INTO employees (first_name, last_name, email, salary, department_id)
VALUES 
    ('Alice', 'Johnson', 'alice@company.com', 68000.00, 2),
    ('Bob', 'Williams', 'bob@company.com', 72000.00, 2),
    ('Carol', 'Davis', 'carol@company.com', 71000.00, 4);
```

**Insert from SELECT (Copy Data):**
```sql
INSERT INTO employees_archive
SELECT * 
FROM employees
WHERE hire_date < '2020-01-01';
```

**Insert with IDENTITY (SQL Server):**
```sql
-- employee_id is auto-generated
INSERT INTO employees (first_name, last_name, email)
VALUES ('Mike', 'Chen', 'mike@company.com');
```

---

### UPDATE - Modify Existing Data

**Update Single Column:**
```sql
UPDATE employees
SET salary = 80000.00
WHERE employee_id = 123;
```

**Update Multiple Columns:**
```sql
UPDATE employees
SET 
    salary = salary * 1.10,
    last_review_date = GETDATE()
WHERE performance_rating = 'Excellent';
```

**Update with JOIN (SQL Server):**
```sql
UPDATE e
SET e.department_name = d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;
```

**Conditional Update:**
```sql
UPDATE employees
SET bonus = CASE
    WHEN salary < 50000 THEN salary * 0.10
    WHEN salary BETWEEN 50000 AND 100000 THEN salary * 0.05
    ELSE salary * 0.03
END;
```

⚠️ **Important:** Always use WHERE clause to avoid updating all rows!

---

### DELETE - Remove Data

**Delete Specific Rows:**
```sql
DELETE FROM employees
WHERE employee_id = 999;
```

**Delete with Condition:**
```sql
DELETE FROM employees
WHERE hire_date < '2015-01-01'
AND status = 'Inactive';
```

**Delete with Subquery:**
```sql
DELETE FROM employees
WHERE department_id IN (
    SELECT department_id 
    FROM departments 
    WHERE location = 'Closed Office'
);
```

**Delete All Rows (Use with Caution!):**
```sql
DELETE FROM temp_table;
-- Better: TRUNCATE TABLE temp_table;
```

⚠️ **Warning:** DELETE without WHERE removes all rows!

---

## 3. DCL - Data Control Language

**Purpose:** Control access to data

**Key Commands:** GRANT, REVOKE, DENY

### GRANT - Give Permissions

**Grant SELECT Permission:**
```sql
GRANT SELECT ON employees TO UserAccount;
```

**Grant Multiple Permissions:**
```sql
GRANT SELECT, INSERT, UPDATE ON employees TO AppUser;
```

**Grant All Permissions:**
```sql
GRANT ALL PRIVILEGES ON DATABASE::CompanyDB TO DatabaseAdmin;
```

**Grant with Grant Option (Can Grant to Others):**
```sql
GRANT SELECT ON employees TO ManagerUser WITH GRANT OPTION;
```

---

### REVOKE - Remove Permissions

**Revoke SELECT Permission:**
```sql
REVOKE SELECT ON employees FROM UserAccount;
```

**Revoke Multiple Permissions:**
```sql
REVOKE INSERT, UPDATE ON employees FROM AppUser;
```

---

### DENY - Explicitly Prohibit

**Deny DELETE Permission:**
```sql
DENY DELETE ON employees TO RestrictedUser;
```

**Permission Hierarchy:**
```
DENY > GRANT > No Permission
```

**Example:**
```sql
-- User is in role with SELECT permission
GRANT SELECT ON employees TO ReadOnlyRole;

-- But explicitly denied for this user
DENY SELECT ON employees TO SpecificUser;

-- Result: SpecificUser CANNOT select (DENY wins)
```

---

## 4. TCL - Transaction Control Language

**Purpose:** Manage database transactions

**Key Commands:** BEGIN TRANSACTION, COMMIT, ROLLBACK, SAVE

### What is a Transaction?

A **transaction** is a logical unit of work that must execute completely or not at all.

**ACID Properties:**
- **A**tomicity - All or nothing
- **C**onsistency - Data remains valid
- **I**solation - Transactions don't interfere
- **D**urability - Committed changes persist

---

### BEGIN TRANSACTION - Start a Transaction

```sql
BEGIN TRANSACTION;
-- Or simply:
BEGIN TRAN;
```

---

### COMMIT - Save Changes Permanently

```sql
BEGIN TRANSACTION;

UPDATE accounts
SET balance = balance - 100
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 100
WHERE account_id = 2;

COMMIT;  -- Both updates saved permanently
```

---

### ROLLBACK - Undo Changes

```sql
BEGIN TRANSACTION;

DELETE FROM employees WHERE department_id = 5;

-- Oh no! Wrong department!
ROLLBACK;  -- Undo the delete

-- Employees are safe!
```

---

### SAVEPOINT - Create Intermediate Points

```sql
BEGIN TRANSACTION;

INSERT INTO orders (customer_id, order_date) VALUES (1, GETDATE());
SAVE TRANSACTION SavePoint1;

INSERT INTO order_items (order_id, product_id, quantity) VALUES (SCOPE_IDENTITY(), 100, 5);
SAVE TRANSACTION SavePoint2;

INSERT INTO order_items (order_id, product_id, quantity) VALUES (SCOPE_IDENTITY(), 101, 3);

-- Error in last insert
ROLLBACK TRANSACTION SavePoint2;  -- Undo only the last insert

COMMIT;  -- Save order and first item
```

---

## Statement Class Examples

### DDL Example - Setting Up Structure

```sql
-- Create database
CREATE DATABASE EcommerceDB;
GO

USE EcommerceDB;
GO

-- Create tables
CREATE TABLE products (
    product_id INT PRIMARY KEY IDENTITY(1,1),
    product_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) CHECK (price > 0),
    stock_quantity INT DEFAULT 0
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    email VARCHAR(100) UNIQUE NOT NULL,
    created_date DATE DEFAULT GETDATE()
);

-- Create index for performance
CREATE INDEX idx_product_name ON products(product_name);
```

---

### DML Example - Working with Data

```sql
-- Insert products
INSERT INTO products (product_name, price, stock_quantity)
VALUES 
    ('Laptop', 999.99, 50),
    ('Mouse', 29.99, 200),
    ('Keyboard', 79.99, 150);

-- Query products
SELECT product_name, price
FROM products
WHERE price < 100;

-- Update prices (10% discount)
UPDATE products
SET price = price * 0.90
WHERE stock_quantity > 100;

-- Delete out-of-stock products
DELETE FROM products
WHERE stock_quantity = 0;
```

---

### DCL Example - Access Control

```sql
-- Create user accounts
CREATE USER SalesUser WITHOUT LOGIN;
CREATE USER AdminUser WITHOUT LOGIN;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON products TO SalesUser;
GRANT ALL PRIVILEGES ON DATABASE::EcommerceDB TO AdminUser;

-- Deny destructive operations
DENY DELETE, DROP ON products TO SalesUser;
```

---

### TCL Example - Transaction Management

```sql
-- Transfer product between locations
BEGIN TRANSACTION;

DECLARE @ProductID INT = 42;
DECLARE @Quantity INT = 10;

-- Remove from warehouse A
UPDATE inventory
SET quantity = quantity - @Quantity
WHERE product_id = @ProductID AND warehouse_id = 1;

-- Add to warehouse B
UPDATE inventory
SET quantity = quantity + @Quantity
WHERE product_id = @ProductID AND warehouse_id = 2;

-- Check if both updates successful
IF @@ROWCOUNT = 2
    COMMIT;
ELSE
    ROLLBACK;
```

---

## Common Patterns & Best Practices

### DDL Best Practices

✅ **Always backup before ALTER/DROP**
```sql
BACKUP DATABASE CompanyDB TO DISK = 'C:\Backups\CompanyDB.bak';
```

✅ **Use IF EXISTS checks**
```sql
IF OBJECT_ID('employees', 'U') IS NOT NULL
    DROP TABLE employees;
```

✅ **Document schema changes**
```sql
-- CHANGE LOG: 2024-11-07 - Added phone_number column
ALTER TABLE employees ADD phone_number VARCHAR(20);
```

---

### DML Best Practices

✅ **Always use WHERE with UPDATE/DELETE**
```sql
-- Bad (updates all rows)
UPDATE employees SET salary = 50000;

-- Good (updates specific rows)
UPDATE employees SET salary = 50000 WHERE employee_id = 123;
```

✅ **Test SELECT before DELETE**
```sql
-- First, see what will be deleted
SELECT * FROM employees WHERE status = 'Terminated';

-- Then delete
DELETE FROM employees WHERE status = 'Terminated';
```

✅ **Use explicit column lists in INSERT**
```sql
-- Good (clear, maintainable)
INSERT INTO employees (first_name, last_name, email)
VALUES ('John', 'Doe', 'john@company.com');

-- Avoid (breaks if columns added)
INSERT INTO employees VALUES (...);
```

---

### TCL Best Practices

✅ **Keep transactions short**
```sql
-- Bad (locks for too long)
BEGIN TRAN;
SELECT * FROM large_table;  -- Don't include queries in transactions
UPDATE accounts SET balance = balance + 100;
COMMIT;

-- Good
BEGIN TRAN;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 123;
COMMIT;
```

✅ **Handle errors in transactions**
```sql
BEGIN TRY
    BEGIN TRANSACTION;
    -- Your operations here
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    SELECT ERROR_MESSAGE();
END CATCH;
```

---

## 🧠 Key Concepts to Remember

1. **DDL** defines structure (CREATE, ALTER, DROP, TRUNCATE)
2. **DML** manipulates data (SELECT, INSERT, UPDATE, DELETE)
3. **DCL** controls access (GRANT, REVOKE, DENY)
4. **TCL** manages transactions (BEGIN, COMMIT, ROLLBACK)
5. Always use WHERE clause with UPDATE and DELETE
6. Use transactions for related operations that must succeed or fail together
7. Test destructive operations with SELECT first

---

## 📝 Check Your Understanding

1. What is the difference between DDL and DML?
2. Which statement class would you use to create a new table?
3. What is the difference between DELETE and TRUNCATE?
4. What does ROLLBACK do?
5. Name three DML commands
6. What is the purpose of DCL statements?
7. Why should you use transactions?
8. What happens if you run UPDATE without a WHERE clause?

---

## ⏭️ Next Lesson

Continue with: **[07 - Nonprocedural Language](../07-nonprocedural-language/)** - Understand what makes SQL different from traditional programming languages.

---

## 📚 Additional Resources

- [T-SQL DML Statements](https://docs.microsoft.com/sql/t-sql/statements/statements)
- [Transaction Management](https://docs.microsoft.com/sql/t-sql/language-elements/transactions-transact-sql)
- [SQL Server Security](https://docs.microsoft.com/sql/relational-databases/security/)
