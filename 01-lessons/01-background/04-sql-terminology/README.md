# SQL Terminology

## 🎯 Learning Objectives

- Master essential SQL and database terminology
- Understand the vocabulary used in database contexts
- Learn the relationship between technical terms
- Build a foundation for communicating about databases

---

## Core Database Terms

### Database
A collection of organized data stored electronically.

**Example:**
```
CompanyDB (Database)
├── employees (Table)
├── departments (Table)
└── projects (Table)
```

---

### Table (Relation)
A collection of related data organized in rows and columns.

**Synonyms:** Relation, Entity

**Example:** `employees` table
```
┌──────────┬────────────┬───────────┬────────┐
│ emp_id   │ first_name │ last_name │ salary │
├──────────┼────────────┼───────────┼────────┤
│ 1        │ Alice      │ Smith     │ 75000  │
│ 2        │ Bob        │ Jones     │ 68000  │
└──────────┴────────────┴───────────┴────────┘
```

---

### Row (Record, Tuple)
A single entry in a table representing one entity.

**Synonyms:** Record, Tuple, Entry

**Example:** One employee
```
emp_id: 1, first_name: Alice, last_name: Smith, salary: 75000
```

---

### Column (Field, Attribute)
A specific piece of information stored in a table.

**Synonyms:** Field, Attribute, Property

**Example:** The `first_name` column contains employee first names

---

### Schema
The structure and organization of a database.

**Two meanings:**

**1. Database Schema (Structure):**
```sql
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    hire_date DATE
);
-- This CREATE statement defines the schema
```

**2. Schema (Namespace in SQL Server):**
```sql
-- Organize objects in logical groups
dbo.employees        -- Default schema
hr.employees         -- HR schema
sales.customers      -- Sales schema
```

---

### Instance
The actual data in a database at a specific point in time.

**Schema vs Instance:**
```
Schema (structure):     | Instance (data):
employees table has:    | Current values:
- emp_id (INT)         | 1, Alice, Smith
- first_name (VARCHAR) | 2, Bob, Jones
- last_name (VARCHAR)  | 3, Carol, Davis
```

---

## Key Terms

### Primary Key (PK)
A column (or combination of columns) that uniquely identifies each row.

**Rules:**
- Must be unique
- Cannot be NULL
- Should never change

**Example:**
```sql
CREATE TABLE students (
    student_id INT PRIMARY KEY,  -- Primary key
    name VARCHAR(100),
    email VARCHAR(100)
);
```

---

### Foreign Key (FK)
A column that references a primary key in another table.

**Purpose:** Establish relationships between tables

**Example:**
```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,  -- Foreign key
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

---

### Composite Key
A primary key made up of multiple columns.

**Example:**
```sql
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    grade CHAR(2),
    PRIMARY KEY (student_id, course_id)  -- Composite key
);
```

---

### Candidate Key
Any column(s) that could serve as a primary key.

**Example:**
```
Table: employees
Candidate keys:
- employee_id ✓ (chosen as primary key)
- email ✓ (unique)
- ssn ✓ (unique)
```

---

### Unique Key
A constraint ensuring all values in a column are different.

**Difference from Primary Key:**
- Can have NULLs
- Can have multiple unique keys per table

**Example:**
```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,  -- Unique key
    username VARCHAR(50) UNIQUE  -- Another unique key
);
```

---

## Constraint Terms

### Constraint
A rule enforced on data in a table.

**Types:**

**1. NOT NULL**
```sql
first_name VARCHAR(50) NOT NULL  -- Must have a value
```

**2. UNIQUE**
```sql
email VARCHAR(100) UNIQUE  -- No duplicates
```

**3. PRIMARY KEY**
```sql
employee_id INT PRIMARY KEY  -- Unique identifier
```

**4. FOREIGN KEY**
```sql
FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
```

**5. CHECK**
```sql
salary DECIMAL(10,2) CHECK (salary > 0)  -- Must be positive
```

**6. DEFAULT**
```sql
hire_date DATE DEFAULT GETDATE()  -- Default value
```

---

### Referential Integrity
The guarantee that foreign keys always reference valid primary keys.

**Example:**
```
departments table:
├── dept_id: 1 (IT)
├── dept_id: 2 (Sales)
└── dept_id: 3 (HR)

employees table:
├── emp_id: 101, dept_id: 1  ✓ Valid (IT exists)
├── emp_id: 102, dept_id: 2  ✓ Valid (Sales exists)
└── emp_id: 103, dept_id: 99 ✗ Invalid! (dept 99 doesn't exist)
```

---

### Domain
The set of allowed values for a column.

**Examples:**
```sql
-- Domain: 0 to 120
age INT CHECK (age >= 0 AND age <= 120)

-- Domain: Specific values
status VARCHAR(20) CHECK (status IN ('Active', 'Inactive', 'Pending'))

-- Domain: Email format
email VARCHAR(100) CHECK (email LIKE '%@%.%')
```

---

## Query Terms

### Query
A request to retrieve or manipulate data.

**Example:**
```sql
SELECT first_name, last_name 
FROM employees 
WHERE salary > 70000;
```

---

### Subquery (Nested Query)
A query within another query.

**Example:**
```sql
SELECT name, salary
FROM employees
WHERE salary > (
    SELECT AVG(salary) FROM employees  -- Subquery
);
```

---

### Predicate
A condition that evaluates to TRUE or FALSE.

**Example:**
```sql
SELECT * FROM products
WHERE price > 100  -- Predicate
AND stock > 0;     -- Another predicate
```

---

### Clause
A component of a SQL statement.

**Common Clauses:**
```sql
SELECT first_name, last_name     -- SELECT clause
FROM employees                   -- FROM clause
WHERE dept_id = 5               -- WHERE clause
ORDER BY last_name;             -- ORDER BY clause
```

---

### Expression
A combination of values, operators, and functions that produces a value.

**Examples:**
```sql
-- Arithmetic expression
salary * 1.10

-- String expression
first_name + ' ' + last_name

-- Conditional expression
CASE WHEN salary > 100000 THEN 'High' ELSE 'Normal' END
```

---

## Relationship Terms

### Cardinality
The number of rows that relate between two tables.

**Types:**

**One-to-One (1:1)**
```
One employee → One parking spot
```

**One-to-Many (1:N)** ← Most common
```
One department → Many employees
```

**Many-to-Many (M:N)**
```
Many students ↔ Many courses
(Requires junction table)
```

---

### Join
Combining rows from two or more tables based on related columns.

**Example:**
```sql
SELECT e.name, d.department_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

---

### Normalization
The process of organizing data to reduce redundancy.

**Normal Forms:**
- 1NF: Atomic values, no repeating groups
- 2NF: Remove partial dependencies
- 3NF: Remove transitive dependencies

---

### Denormalization
Intentionally adding redundancy for performance.

**Example:**
```sql
-- Normalized (requires join)
orders → customers (to get customer name)

-- Denormalized (faster, redundant)
orders table includes customer_name directly
```

---

## Data Manipulation Terms

### CRUD
The four basic operations on data:

- **C**reate (INSERT)
- **R**ead (SELECT)
- **U**pdate (UPDATE)
- **D**elete (DELETE)

---

### Transaction
A logical unit of work that must completely succeed or completely fail.

**Example:**
```sql
BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
COMMIT;
```

---

### ACID
Properties of reliable transactions:

- **A**tomicity - All or nothing
- **C**onsistency - Data remains valid
- **I**solation - Transactions don't interfere
- **D**urability - Changes persist

---

### Rollback
Undoing changes made in a transaction.

```sql
BEGIN TRANSACTION;
    DELETE FROM employees WHERE dept_id = 5;
    -- Oops, wrong department!
ROLLBACK;  -- Undo the delete
```

---

### Commit
Permanently saving changes made in a transaction.

```sql
BEGIN TRANSACTION;
    INSERT INTO orders (customer_id, total) VALUES (123, 99.99);
COMMIT;  -- Save permanently
```

---

## Performance Terms

### Index
A data structure that speeds up data retrieval.

**Analogy:** Like a book index

**Example:**
```sql
CREATE INDEX idx_last_name ON employees(last_name);
```

---

### View
A saved query that acts like a virtual table.

**Example:**
```sql
CREATE VIEW high_earners AS
SELECT * FROM employees WHERE salary > 100000;

-- Use it like a table
SELECT * FROM high_earners;
```

---

### Stored Procedure
A saved SQL program that can be executed.

**Example:**
```sql
CREATE PROCEDURE GetEmployeesByDept @DeptID INT
AS
BEGIN
    SELECT * FROM employees WHERE dept_id = @DeptID;
END;
```

---

### Trigger
Code that automatically executes when certain events occur.

**Example:**
```sql
CREATE TRIGGER audit_employee_changes
ON employees
AFTER UPDATE
AS
BEGIN
    INSERT INTO audit_log (table_name, change_date)
    VALUES ('employees', GETDATE());
END;
```

---

## NULL Terminology

### NULL
Represents missing or unknown data.

**Important:** NULL is NOT:
- Empty string ''
- Zero 0
- False

**Example:**
```sql
-- Employee without assigned department
INSERT INTO employees (emp_id, name, dept_id)
VALUES (123, 'Alice', NULL);  -- dept_id is NULL
```

---

### IS NULL / IS NOT NULL
Check for NULL values.

```sql
SELECT * FROM employees WHERE dept_id IS NULL;
SELECT * FROM employees WHERE email IS NOT NULL;
```

---

## Aggregate Terms

### Aggregate Function
A function that performs calculation on multiple rows.

**Common Aggregates:**
```sql
COUNT(*)          -- Number of rows
SUM(salary)       -- Total of all salaries
AVG(salary)       -- Average salary
MIN(salary)       -- Lowest salary
MAX(salary)       -- Highest salary
```

---

### Group By
Group rows for aggregation.

```sql
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;
```

---

### Having
Filter groups (WHERE filters rows).

```sql
SELECT dept_id, COUNT(*) AS emp_count
FROM employees
GROUP BY dept_id
HAVING COUNT(*) > 10;  -- Only departments with >10 employees
```

---

## System Terms

### RDBMS
Relational Database Management System

**Examples:** SQL Server, MySQL, PostgreSQL, Oracle

---

### DBMS
Database Management System (more general term)

---

### Database Engine
The core software that stores, processes, and secures data.

---

### Connection
A session between a client and database server.

---

### Query Optimizer
Database component that determines the most efficient way to execute queries.

---

### Execution Plan
The strategy the database uses to execute a query.

---

## SQL Server Specific Terms

### T-SQL
Transact-SQL - Microsoft's implementation of SQL.

---

### Instance
A complete SQL Server installation running on a server.

---

### Server
The computer running SQL Server.

---

### Database File
Physical files storing database data:
- **.mdf** - Primary data file
- **.ldf** - Log file
- **.ndf** - Secondary data files

---

### Collation
Rules for how strings are compared and sorted.

```sql
Latin1_General_CI_AS
-- CI = Case Insensitive
-- AS = Accent Sensitive
```

---

## 🧠 Key Concepts to Remember

1. **Table** = Relation, contains rows and columns
2. **Row** = Record/Tuple, one entity
3. **Column** = Attribute/Field, one piece of info
4. **Primary Key** = Unique identifier
5. **Foreign Key** = Reference to another table
6. **Schema** = Structure of database
7. **NULL** = Missing/unknown value
8. **CRUD** = Create, Read, Update, Delete
9. **ACID** = Transaction properties
10. **Index** = Performance optimization

---

## 📝 Terminology Exercise

Match the terms:
1. Row → **Record/Tuple**
2. Column → **Attribute/Field**
3. Foreign Key → **Reference to primary key**
4. NULL → **Unknown value**
5. CRUD → **Create, Read, Update, Delete**

---

## ⏭️ Next Lesson

Continue with: **[05 - What is SQL?](../05-what-is-sql/)** - Learn about the SQL language, its history, and purpose.

---

## 📚 Glossary Quick Reference

| Term | Simple Definition |
|------|------------------|
| Table | Collection of related data |
| Row | One entry/record |
| Column | One piece of information |
| Primary Key | Unique identifier |
| Foreign Key | Link to another table |
| Schema | Database structure |
| Query | Request for data |
| Index | Speed up searches |
| View | Saved query |
| Trigger | Automatic code execution |
| Transaction | Group of operations |
| NULL | Missing data |
| Join | Combine tables |
| Aggregate | Calculate across rows |
