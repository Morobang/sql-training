# Lesson 1: Introduction to SQL

**Timeline:** 00:00 - 07:38  
**Duration:** ~15 minutes  
**Level:** 🟢 Beginner

## Learning Objectives

By the end of this lesson, you will be able to:
1. Explain what SQL is and why it's important
2. Understand the difference between databases and DBMS
3. Identify different types of database systems
4. Recognize SQL's role in data management
5. Understand basic SQL history and standards

## What is SQL?

**SQL (Structured Query Language)** is a standardized programming language used to manage and manipulate relational databases.

### Key Characteristics

```
✓ Declarative language (you specify WHAT, not HOW)
✓ Standard across database systems (with dialects)
✓ Used by millions worldwide
✓ 50+ years old and still dominant
✓ Essential skill for data professionals
```

### What Can You Do with SQL?

```sql
-- Retrieve data
SELECT name, email FROM customers;

-- Insert data
INSERT INTO customers (name, email) VALUES ('John Doe', 'john@example.com');

-- Update data
UPDATE customers SET email = 'newemail@example.com' WHERE id = 1;

-- Delete data
DELETE FROM customers WHERE id = 1;

-- Create structures
CREATE TABLE products (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2)
);
```

## Databases vs DBMS

### Database
A **database** is an organized collection of structured data stored electronically.

```
Example: Customer Database
┌─────────────────────────────┐
│ Tables:                     │
│  - customers                │
│  - orders                   │
│  - products                 │
│  - payments                 │
└─────────────────────────────┘
```

### DBMS (Database Management System)
A **DBMS** is software that manages databases.

**Popular DBMS:**
- **MySQL** - Open source, web applications
- **PostgreSQL** - Open source, advanced features
- **SQL Server** - Microsoft, enterprise
- **Oracle** - Enterprise, large scale
- **SQLite** - Embedded, mobile apps

## Types of Databases

### 1. Relational Databases (RDBMS)
Data stored in **tables** with relationships.

```
Customers Table          Orders Table
┌────┬──────────┐       ┌────┬─────────────┬─────┐
│ ID │   Name   │       │ ID │ Customer_ID │ ... │
├────┼──────────┤       ├────┼─────────────┼─────┤
│  1 │ John Doe │       │101 │      1      │ ... │
│  2 │ Jane Sm. │       │102 │      1      │ ... │
└────┴──────────┘       └────┴─────────────┴─────┘
                              ↑
                        Foreign Key Relationship
```

**Uses SQL:** ✅ Yes

### 2. NoSQL Databases
Data stored in flexible formats (documents, key-value, graphs).

```
MongoDB (Document Store):
{
  "name": "John Doe",
  "email": "john@example.com",
  "orders": [
    {"id": 101, "total": 99.99},
    {"id": 102, "total": 149.99}
  ]
}
```

**Uses SQL:** ❌ No (has own query languages)  
**Note:** Some NoSQL systems now support SQL-like queries!

### 3. Cloud Databases
Databases hosted in the cloud (AWS, Azure, Google Cloud).

```
Examples:
- Amazon RDS (relational)
- Azure SQL Database
- Google Cloud SQL
- Snowflake
```

**Uses SQL:** ✅ Yes

## Why Learn SQL?

### 1. Universal Skill
```
Job Roles Using SQL:
✓ Data Analyst
✓ Data Scientist
✓ Data Engineer
✓ Database Administrator
✓ Backend Developer
✓ Business Analyst
✓ Product Manager
```

### 2. High Demand
```
Statistics:
- 60% of data jobs require SQL
- Average salary: $80k - $150k+
- Used by 95% of Fortune 500 companies
```

### 3. Works Everywhere
```
Industries:
✓ Technology
✓ Finance/Banking
✓ Healthcare
✓ E-commerce
✓ Government
✓ Education
✓ Manufacturing
```

## SQL History (Brief)

**Timeline:**
```
1970: Edgar Codd publishes relational model paper
1974: IBM develops SEQUEL (later renamed SQL)
1986: ANSI standardizes SQL (SQL-86)
1992: SQL-92 standard (widely adopted)
2000s: SQL expands to big data, cloud
2020s: SQL on data lakes, streaming, ML integration
```

**Key Point:** SQL has been around for 50+ years and continues to evolve!

## SQL Standards vs Dialects

### SQL Standard (ANSI SQL)
Core SQL that works across all systems.

```sql
-- Standard SQL (works everywhere)
SELECT * FROM customers WHERE age > 18;
```

### SQL Dialects
Each DBMS has extensions/variations.

```sql
-- MySQL
SELECT * FROM customers LIMIT 10;

-- SQL Server
SELECT TOP 10 * FROM customers;

-- PostgreSQL
SELECT * FROM customers LIMIT 10;
```

**Good News:** 90% of SQL is the same across systems!

## Real-World Example

**Scenario:** E-commerce company needs to find best customers.

```sql
-- Find customers who spent over $1000 in 2024
SELECT 
    c.customer_id,
    c.name,
    c.email,
    SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE YEAR(o.order_date) = 2024
GROUP BY c.customer_id, c.name, c.email
HAVING SUM(o.total_amount) > 1000
ORDER BY total_spent DESC;
```

**This single query:**
- ✅ Joins two tables
- ✅ Filters by year
- ✅ Calculates totals
- ✅ Finds high-value customers
- ✅ Sorts results

**Without SQL, this would require complex programming!**

## SQL Categories

SQL commands are grouped into categories:

### 1. DQL (Data Query Language)
Retrieve data
```sql
SELECT * FROM customers;
```

### 2. DDL (Data Definition Language)
Define structures
```sql
CREATE TABLE customers (id INT, name VARCHAR(100));
```

### 3. DML (Data Manipulation Language)
Modify data
```sql
INSERT INTO customers VALUES (1, 'John Doe');
UPDATE customers SET name = 'Jane Doe' WHERE id = 1;
DELETE FROM customers WHERE id = 1;
```

### 4. DCL (Data Control Language)
Control access
```sql
GRANT SELECT ON customers TO analyst_role;
REVOKE DELETE ON customers FROM analyst_role;
```

### 5. TCL (Transaction Control Language)
Manage transactions
```sql
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
COMMIT;
```

## Key Takeaways

### What is SQL?
```
✓ Structured Query Language
✓ Manages relational databases
✓ Declarative (specify WHAT, not HOW)
✓ Industry standard for 50+ years
```

### Why Important?
```
✓ Universal data skill
✓ High-paying jobs
✓ Works across industries
✓ Foundation for data careers
```

### What's Next?
```
→ Setup your SQL environment
→ Write your first queries
→ Learn to create tables
→ Master data manipulation
```

---

## Quick Check

**Before moving to the next lesson, make sure you can:**
- [ ] Explain what SQL is in one sentence
- [ ] Name at least 3 database management systems
- [ ] Understand the difference between database and DBMS
- [ ] Know why SQL is important for data careers

---

## Next Lesson

**Continue to [Lesson 2: Setup Your Environment](../02-setup-environment/)**  
Learn how to install and configure your SQL development environment.

---

## Additional Resources

- **SQL Standard:** https://www.iso.org/standard/63555.html
- **SQL History:** https://en.wikipedia.org/wiki/SQL
- **DBMS Comparison:** https://db-engines.com/en/ranking

**Welcome to your SQL journey! 🚀**
