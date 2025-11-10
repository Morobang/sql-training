# Lesson 1: Introduction to SQL

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

SQL lets you work with data in databases. Here are the main operations:

**1. Ask Questions (Query)**
```
"Show me all customer names"
"Find products under $50"
```

**2. Add New Information**
```
"Add a new customer named John"
"Record a new product"
```

**3. Update Information**
```
"Change customer's email address"
"Update product price"
```

**4. Remove Information**
```
"Delete old orders"
"Remove inactive customers"
```

**5. Organize Data**
```
"Create a new table for employees"
"Set up product categories"
```

**We'll learn to write SQL commands for all of these!**

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

**Scenario:** An online store tracks customer orders.

**Questions the business asks:**
- "How many orders did we get today?"
- "Which products are selling best?"
- "Who are our top customers?"
- "What's our total revenue this month?"

**SQL answers all of these questions quickly!**

Instead of manually counting through spreadsheets with thousands of rows, SQL can find the answer in seconds.

**Example Question:** "Show me all customers"

**SQL Answer:**
```sql
SELECT name, email FROM customers;
```

**Result:**
```
name          | email
--------------+----------------------
John Doe      | john@example.com
Jane Smith    | jane@example.com
Bob Johnson   | bob@example.com
```

That's it! One simple command retrieves the data you need.

## SQL Categories

SQL commands fall into different categories. Don't worry about memorizing these now - you'll learn them as we go!

### 1. **SELECT** - Ask Questions
Get data from the database
```sql
SELECT name FROM customers;
```
*"Show me customer names"*

### 2. **INSERT** - Add New Data
Put new information into the database
```sql
INSERT INTO customers (name) VALUES ('John');
```
*"Add a new customer"*

### 3. **UPDATE** - Change Data
Modify existing information
```sql
UPDATE customers SET email = 'new@email.com';
```
*"Update customer email"*

### 4. **DELETE** - Remove Data
Delete information from the database
```sql
DELETE FROM customers WHERE id = 5;
```
*"Remove a customer"*

### 5. **CREATE** - Build Structure
Make new tables to organize data
```sql
CREATE TABLE customers (id INT, name VARCHAR(100));
```
*"Create a place to store customer data"*

**We'll learn each of these step by step in the upcoming lessons!**

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

**Continue to [Lesson 2: Setup Your Environment](../02-setup-environment/setup-environment.md)**  
Learn how to install and configure your SQL development environment.

---

## Additional Resources

- **SQL Standard:** https://www.iso.org/standard/63555.html
- **SQL History:** https://en.wikipedia.org/wiki/SQL
- **DBMS Comparison:** https://db-engines.com/en/ranking

**Welcome to your SQL journey! 🚀**
