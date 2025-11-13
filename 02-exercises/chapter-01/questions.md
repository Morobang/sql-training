# Chapter 1: Background - Practice Questions

## Overview
Test your understanding of database fundamentals, relational model concepts, and SQL basics covered in Chapter 1.

---

## Multiple Choice Questions

### Question 1: Database Types (Easy)
Which of the following is an example of a **non-relational database**?
- A) MySQL
- B) PostgreSQL
- C) MongoDB
- D) Oracle

<details>
<summary>Click to see answer</summary>

**Answer: C) MongoDB**

Explanation: MongoDB is a document-based NoSQL database. MySQL, PostgreSQL, and Oracle are all relational databases that use SQL.
</details>

---

### Question 2: Relational Model (Easy)
In the relational model, data is organized into:
- A) Documents
- B) Tables (Relations)
- C) Key-Value pairs
- D) Graph nodes

<details>
<summary>Click to see answer</summary>

**Answer: B) Tables (Relations)**

Explanation: The relational model, proposed by E.F. Codd, organizes data into tables (also called relations) with rows and columns.
</details>

---

### Question 3: SQL Statement Classes (Medium)
Which SQL statement class is used to create, modify, or delete database objects like tables?
- A) DML (Data Manipulation Language)
- B) DDL (Data Definition Language)
- C) DCL (Data Control Language)
- D) TCL (Transaction Control Language)

<details>
<summary>Click to see answer</summary>

**Answer: B) DDL (Data Definition Language)**

Explanation: 
- **DDL**: CREATE, ALTER, DROP (structure)
- **DML**: SELECT, INSERT, UPDATE, DELETE (data)
- **DCL**: GRANT, REVOKE (permissions)
- **TCL**: COMMIT, ROLLBACK (transactions)
</details>

---

### Question 4: SQL Characteristics (Medium)
SQL is considered a **nonprocedural language**. What does this mean?
- A) You write procedures to manipulate data
- B) You specify what data you want, not how to get it
- C) You must define loops and conditions
- D) You need to write step-by-step instructions

<details>
<summary>Click to see answer</summary>

**Answer: B) You specify what data you want, not how to get it**

Explanation: SQL is declarative/nonprocedural. You describe the desired result (WHAT), and the database engine figures out HOW to retrieve it. For example:
```sql
SELECT name FROM customers WHERE age > 18;
```
You don't specify the algorithm to find these customers.
</details>

---

### Question 5: Primary Key (Medium)
What is the purpose of a **primary key** in a relational table?
- A) To sort the table
- B) To uniquely identify each row
- C) To create relationships with other tables
- D) To improve query performance

<details>
<summary>Click to see answer</summary>

**Answer: B) To uniquely identify each row**

Explanation: A primary key is a column (or set of columns) that uniquely identifies each row in a table. No two rows can have the same primary key value, and it cannot be NULL.
</details>

---

### Question 6: Foreign Key (Hard)
A **foreign key** in one table references which of the following in another table?
- A) Any column
- B) The primary key
- C) An index
- D) A unique constraint

<details>
<summary>Click to see answer</summary>

**Answer: B) The primary key**

Explanation: A foreign key creates a relationship by referencing the primary key of another table. This enforces referential integrity.

Example:
```sql
-- Parent table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- Child table with foreign key
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```
</details>

---

## True/False Questions

### Question 7: ACID Properties (Easy)
**True or False:** ACID stands for Atomicity, Consistency, Isolation, Durability.

<details>
<summary>Click to see answer</summary>

**Answer: True**

- **Atomicity**: All operations in a transaction succeed or all fail
- **Consistency**: Database moves from one valid state to another
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed changes survive system failures
</details>

---

### Question 8: SQL Standards (Medium)
**True or False:** SQL syntax is identical across all database systems (MySQL, SQL Server, PostgreSQL, Oracle).

<details>
<summary>Click to see answer</summary>

**Answer: False**

While SQL has ANSI/ISO standards, each database vendor implements extensions and variations. For example:
- **MySQL**: `LIMIT 10`
- **SQL Server**: `TOP 10`
- **Oracle**: `ROWNUM <= 10`
</details>

---

## Short Answer Questions

### Question 9: Explain Normalization (Medium)
What is **database normalization** and why is it important?

<details>
<summary>Click to see answer</summary>

**Answer:**

**Normalization** is the process of organizing data to reduce redundancy and improve data integrity.

**Goals:**
1. Eliminate duplicate data
2. Ensure data dependencies make sense
3. Reduce storage requirements
4. Improve update/delete efficiency

**Example of unnormalized data:**
```
| OrderID | CustomerName | CustomerEmail      | Product  | Price |
|---------|--------------|-------------------|----------|-------|
| 1       | John Doe     | john@email.com    | Laptop   | 1200  |
| 2       | John Doe     | john@email.com    | Mouse    | 25    |
```
Problem: Customer info is duplicated.

**Normalized (2 tables):**
```
Customers:
| CustomerID | Name     | Email          |
|------------|----------|----------------|
| 1          | John Doe | john@email.com |

Orders:
| OrderID | CustomerID | Product | Price |
|---------|------------|---------|-------|
| 1       | 1          | Laptop  | 1200  |
| 2       | 1          | Mouse   | 25    |
```
</details>

---

### Question 10: SQL vs NoSQL (Hard)
When would you choose a **relational database (SQL)** over a **NoSQL database**? Give 3 reasons.

<details>
<summary>Click to see answer</summary>

**Answer:**

**Choose SQL/Relational Database when:**

1. **ACID Compliance Required**
   - Banking, financial transactions
   - Where data consistency is critical
   - Example: Money transfers must be atomic

2. **Complex Relationships**
   - Data has many relationships
   - Need JOIN operations
   - Example: E-commerce (customers, orders, products, reviews)

3. **Structured Data with Fixed Schema**
   - Well-defined data structure
   - Schema changes are infrequent
   - Example: Employee records, inventory systems

**Choose NoSQL when:**
- Massive scale/horizontal scaling needed
- Flexible schema (changing data structure)
- High write throughput required
- Example: Social media feeds, IoT data, real-time analytics
</details>

---

## Practical Scenario Questions

### Question 11: Database Design (Hard)
You're designing a database for a **library system**. Identify:
1. At least 3 tables you would create
2. The primary key for each
3. One foreign key relationship

<details>
<summary>Click to see answer</summary>

**Answer:**

**Tables:**

1. **Books**
   - Primary Key: `book_id`
   - Columns: title, author, isbn, publication_year, category

2. **Members**
   - Primary Key: `member_id`
   - Columns: first_name, last_name, email, phone, join_date

3. **Loans**
   - Primary Key: `loan_id`
   - Columns: book_id (FK), member_id (FK), loan_date, due_date, return_date

**Foreign Key Relationships:**
- `Loans.book_id` → `Books.book_id`
- `Loans.member_id` → `Members.member_id`

**SQL:**
```sql
CREATE TABLE Books (
    book_id INT PRIMARY KEY,
    title VARCHAR(200),
    author VARCHAR(100),
    isbn VARCHAR(20)
);

CREATE TABLE Members (
    member_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE Loans (
    loan_id INT PRIMARY KEY,
    book_id INT,
    member_id INT,
    loan_date DATE,
    due_date DATE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id),
    FOREIGN KEY (member_id) REFERENCES Members(member_id)
);
```
</details>

---

## Challenge Question

### Question 12: Real-World Application (Expert)
A company is experiencing **data inconsistencies** where the same customer appears multiple times with slightly different spellings (e.g., "John Smith", "J. Smith", "John R. Smith"). 

1. What database concept would help prevent this?
2. How would you design the system to avoid duplicates?
3. If duplicates already exist, how would you identify and merge them?

<details>
<summary>Click to see answer</summary>

**Answer:**

**1. Prevention - Unique Constraints & Normalization**

Use composite unique constraint on multiple fields:
```sql
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    email VARCHAR(100) UNIQUE,  -- Prevent duplicate emails
    phone VARCHAR(20),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    CONSTRAINT unique_customer UNIQUE (email, phone)
);
```

**2. System Design to Avoid Duplicates**

- Use **unique business identifier** (email, SSN, phone)
- Implement **data validation** at application level
- Use **fuzzy matching** before insert
- Create **customer lookup** during registration
- Implement **master data management (MDM)**

**3. Identify & Merge Existing Duplicates**

```sql
-- Find potential duplicates (similar names)
SELECT 
    first_name, 
    last_name, 
    COUNT(*) as duplicate_count
FROM Customers
GROUP BY first_name, last_name
HAVING COUNT(*) > 1;

-- Find duplicates by email
SELECT email, COUNT(*) 
FROM Customers
GROUP BY email
HAVING COUNT(*) > 1;

-- Merge strategy (keep oldest record)
WITH Duplicates AS (
    SELECT 
        customer_id,
        email,
        ROW_NUMBER() OVER (PARTITION BY email ORDER BY created_date ASC) AS rn
    FROM Customers
)
-- Update foreign keys to point to master record
UPDATE Orders
SET customer_id = (SELECT customer_id FROM Duplicates WHERE rn = 1 AND email = 'john@email.com')
WHERE customer_id IN (SELECT customer_id FROM Duplicates WHERE rn > 1 AND email = 'john@email.com');

-- Delete duplicates
DELETE FROM Customers
WHERE customer_id IN (
    SELECT customer_id FROM Duplicates WHERE rn > 1
);
```

**Best Practice:**
Use tools like **Soundex** or **Levenshtein distance** for fuzzy matching:
```sql
-- SQL Server example
SELECT * FROM Customers
WHERE SOUNDEX(last_name) = SOUNDEX('Smith');
```
</details>

---

## Summary

**Difficulty Breakdown:**
- Easy: 4 questions (1, 2, 7, 8)
- Medium: 5 questions (3, 4, 5, 9, 10)
- Hard: 2 questions (6, 11)
- Expert: 1 question (12)

**Topics Covered:**
- ✅ Relational vs Non-relational databases
- ✅ SQL statement classes (DDL, DML, DCL)
- ✅ Primary and foreign keys
- ✅ Normalization
- ✅ ACID properties
- ✅ Database design principles
- ✅ Data quality and deduplication

**Next Steps:**
- Review Chapter 1 lessons if you struggled with any questions
- Move to Chapter 2 exercises (Creating Databases)
- Practice with the Sakila sample database
