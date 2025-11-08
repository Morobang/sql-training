# Test Your Knowledge - Chapter 01

## 🎯 Chapter 01 Review

Test your understanding of database fundamentals and SQL concepts before moving to Chapter 02!

---

## Part 1: Multiple Choice

### Question 1
What does DBMS stand for?

A) Database Maintenance System  
B) Database Management System  
C) Data Building Management System  
D) Digital Base Management Software

<details>
<summary>Show Answer</summary>

**B) Database Management System**

A DBMS is software that manages databases, providing an interface between users/applications and the physical data storage.
</details>

---

### Question 2
Which of the following is a characteristic of relational databases?

A) Data is stored in JSON format  
B) Data is organized in tables with rows and columns  
C) Data has no structure  
D) Data is stored in key-value pairs only

<details>
<summary>Show Answer</summary>

**B) Data is organized in tables with rows and columns**

Relational databases organize data in tables (relations) where each row represents a record and each column represents an attribute.
</details>

---

### Question 3
What is a primary key?

A) The first key created in a database  
B) A unique identifier for each row in a table  
C) A password for database access  
D) An index that speeds up queries

<details>
<summary>Show Answer</summary>

**B) A unique identifier for each row in a table**

A primary key uniquely identifies each row, must be unique, cannot be NULL, and should never change.
</details>

---

### Question 4
What does SQL stand for?

A) Standard Query Language  
B) Structured Question Language  
C) Structured Query Language  
D) Simple Query Language

<details>
<summary>Show Answer</summary>

**C) Structured Query Language**

SQL is the standard language for managing and manipulating relational databases.
</details>

---

### Question 5
Which type of NoSQL database would be best for storing social network connections?

A) Document database  
B) Key-value store  
C) Column-family database  
D) Graph database

<details>
<summary>Show Answer</summary>

**D) Graph database**

Graph databases (like Neo4j) are specifically designed for storing and querying relationships, making them ideal for social networks, recommendation engines, and fraud detection.
</details>

---

### Question 6
What is T-SQL?

A) A type of SQL Server  
B) Microsoft's implementation of SQL with procedural extensions  
C) A testing tool for SQL  
D) A table-based SQL variant

<details>
<summary>Show Answer</summary>

**B) Microsoft's implementation of SQL with procedural extensions**

T-SQL (Transact-SQL) is SQL Server's dialect that adds variables, control flow, error handling, and other procedural features to standard SQL.
</details>

---

### Question 7
Which SQL statement class is used to create tables?

A) DML (Data Manipulation Language)  
B) DDL (Data Definition Language)  
C) DCL (Data Control Language)  
D) TCL (Transaction Control Language)

<details>
<summary>Show Answer</summary>

**B) DDL (Data Definition Language)**

DDL includes CREATE, ALTER, DROP, and TRUNCATE - statements that define and modify database structure.
</details>

---

### Question 8
What does ACID stand for in database transactions?

A) Atomicity, Consistency, Isolation, Durability  
B) Access, Control, Integrity, Data  
C) Automatic, Complete, Instant, Database  
D) Absolute, Certain, Immediate, Definite

<details>
<summary>Show Answer</summary>

**A) Atomicity, Consistency, Isolation, Durability**

ACID properties ensure reliable transaction processing:
- **Atomicity**: All or nothing
- **Consistency**: Data remains valid
- **Isolation**: Transactions don't interfere
- **Durability**: Changes persist
</details>

---

### Question 9
What is a foreign key?

A) A key from another country  
B) A column that references a primary key in another table  
C) An alternative primary key  
D) A key used for encryption

<details>
<summary>Show Answer</summary>

**B) A column that references a primary key in another table**

Foreign keys establish relationships between tables and enforce referential integrity.
</details>

---

### Question 10
SQL is considered a __________ language.

A) Procedural  
B) Object-oriented  
C) Declarative  
D) Functional

<details>
<summary>Show Answer</summary>

**C) Declarative**

SQL is declarative (nonprocedural) - you specify WHAT you want, not HOW to get it. The database engine determines the execution plan.
</details>

---

## Part 2: True or False

### Question 11
SQL Server Developer Edition can be used in production environments.

<details>
<summary>Show Answer</summary>

**FALSE**

Developer Edition has all Enterprise features but is licensed only for development and testing, NOT production use. Use Express, Standard, or Enterprise for production.
</details>

---

### Question 12
NULL means the same as an empty string ('') or zero (0).

<details>
<summary>Show Answer</summary>

**FALSE**

NULL represents unknown or missing data. It is NOT:
- Empty string ''
- Zero 0  
- False

NULL requires special handling (IS NULL, IS NOT NULL).
</details>

---

### Question 13
A table can have multiple primary keys.

<details>
<summary>Show Answer</summary>

**FALSE**

A table can have only ONE primary key. However, that primary key can be composite (made of multiple columns).

A table CAN have multiple candidate keys (potential primary keys), but only one is chosen as THE primary key.
</details>

---

### Question 14
NoSQL databases never use SQL.

<details>
<summary>Show Answer</summary>

**FALSE**

NoSQL means "Not Only SQL", not "No SQL". Many NoSQL databases offer SQL-like query languages:
- Cassandra has CQL (Cassandra Query Language)
- Many document databases support SQL-like queries
- Some graph databases use SQL-inspired syntax
</details>

---

### Question 15
In a one-to-many relationship, the foreign key goes in the "many" side table.

<details>
<summary>Show Answer</summary>

**TRUE**

Example: One department has many employees
- departments table has dept_id (PK)
- employees table has dept_id (FK) ← Foreign key in the "many" side

This prevents data duplication.
</details>

---

## Part 3: Fill in the Blank

### Question 16
The four main SQL statement classes are DDL, DML, ______, and ______.

<details>
<summary>Show Answer</summary>

**DCL (Data Control Language) and TCL (Transaction Control Language)**

- **DDL**: CREATE, ALTER, DROP, TRUNCATE
- **DML**: SELECT, INSERT, UPDATE, DELETE
- **DCL**: GRANT, REVOKE, DENY
- **TCL**: BEGIN, COMMIT, ROLLBACK
</details>

---

### Question 17
A ______ is a saved SQL query that can be used like a table.

<details>
<summary>Show Answer</summary>

**View**

Views are virtual tables created by saved SELECT statements. They don't store data themselves but provide a way to simplify complex queries and control access to data.
</details>

---

### Question 18
The process of organizing data to reduce redundancy is called ______.

<details>
<summary>Show Answer</summary>

**Normalization**

Normalization organizes data into tables according to rules (normal forms) to:
- Reduce redundancy
- Improve data integrity
- Make updates easier
- Prevent anomalies
</details>

---

### Question 19
In SQL Server, database files include .mdf (data file) and ______ (log file).

<details>
<summary>Show Answer</summary>

**.ldf (Log Data File)**

SQL Server database files:
- **.mdf**: Primary data file
- **.ndf**: Secondary data files (optional)
- **.ldf**: Transaction log file (required)
</details>

---

### Question 20
The four types of NoSQL databases are document, key-value, column-family, and ______.

<details>
<summary>Show Answer</summary>

**Graph**

The four main NoSQL types:
1. **Document**: MongoDB, CouchDB
2. **Key-Value**: Redis, DynamoDB
3. **Column-Family**: Cassandra, HBase
4. **Graph**: Neo4j, Amazon Neptune
</details>

---

## Part 4: Short Answer

### Question 21
Name three advantages of using databases over flat files.

<details>
<summary>Show Answer</summary>

**Any three of:**
1. **Data Integrity**: Constraints ensure data accuracy
2. **Concurrent Access**: Multiple users can access simultaneously
3. **Security**: Granular access control
4. **Backup & Recovery**: Built-in data protection
5. **Efficient Queries**: Optimized data retrieval
6. **Reduced Redundancy**: Normalized structure
7. **Relationships**: Connect related data
8. **Transaction Support**: ACID properties
</details>

---

### Question 22
Explain the difference between a natural key and a surrogate key.

<details>
<summary>Show Answer</summary>

**Natural Key:**
- Has business meaning (SSN, email, ISBN)
- Exists naturally in the data
- Can change over time
- May be sensitive information

**Surrogate Key:**
- Artificial identifier (auto-incrementing integer)
- No business meaning
- Never changes
- System-generated

**Best Practice:** Use surrogate keys as primary keys, make natural keys unique constraints.

Example:
```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY IDENTITY(1,1),  -- Surrogate
    email VARCHAR(100) UNIQUE NOT NULL           -- Natural (unique)
);
```
</details>

---

### Question 23
What is referential integrity and why is it important?

<details>
<summary>Show Answer</summary>

**Referential Integrity** ensures that foreign keys always reference valid primary keys in related tables.

**Importance:**
- Prevents orphaned records
- Maintains data consistency
- Enforces relationships
- Prevents invalid data

**Example:**
- Can't add an employee with dept_id = 99 if department 99 doesn't exist
- Can't delete a department that has employees (or must CASCADE/SET NULL)

**Implementation:**
```sql
FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
```
</details>

---

### Question 24
Describe what happens when you write a SQL query and press execute.

<details>
<summary>Show Answer</summary>

**Query Execution Process:**

1. **Parsing**
   - Checks SQL syntax
   - Validates table/column names
   - Converts to internal format

2. **Optimization**
   - Query optimizer analyzes the query
   - Considers indexes, statistics, table sizes
   - Generates multiple execution plans
   - Chooses the most efficient plan

3. **Execution**
   - Execution engine runs the plan
   - Reads data from disk/cache
   - Applies filters and joins
   - Sorts if needed
   - Returns results to client

**Key Point:** You specify WHAT you want (declarative), the database figures out HOW to get it efficiently.
</details>

---

### Question 25
Give an example of when you might use a many-to-many relationship and how you would implement it.

<details>
<summary>Show Answer</summary>

**Example: Students and Courses**

**Relationship:**
- One student takes many courses
- One course has many students
- This is many-to-many (M:N)

**Implementation:** Requires a junction (bridge) table

```sql
-- Students table
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100)
);

-- Courses table
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100)
);

-- Junction table
CREATE TABLE enrollments (
    student_id INT,
    course_id INT,
    grade CHAR(2),
    semester VARCHAR(20),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
```

**Other examples:**
- Products ↔ Orders (order_items)
- Actors ↔ Movies (cast)
- Authors ↔ Books (book_authors)
</details>

---

## Part 5: Scenario Questions

### Question 26
You need to track employees, departments, and projects. An employee belongs to one department, but can work on multiple projects. A project can have multiple employees. Design the table structure.

<details>
<summary>Show Answer</summary>

**Table Design:**

```sql
-- Departments (1:N with employees)
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100)
);

-- Employees (belongs to ONE department)
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Projects
CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100),
    start_date DATE,
    end_date DATE
);

-- Junction table (M:N relationship)
CREATE TABLE employee_projects (
    emp_id INT,
    project_id INT,
    role VARCHAR(50),
    hours_allocated INT,
    PRIMARY KEY (emp_id, project_id),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);
```

**Relationships:**
- Department → Employees (1:N)
- Employees ↔ Projects (M:N via junction table)
</details>

---

### Question 27
A query that normally takes 2 seconds is now taking 2 minutes. What might be causing this and how would you investigate?

<details>
<summary>Show Answer</summary>

**Possible Causes:**

1. **Missing Indexes**
   - Table scans instead of index seeks
   - Check WHERE clause columns

2. **Data Growth**
   - Table has millions more rows than before
   - Query not optimized for scale

3. **Outdated Statistics**
   - Query optimizer using old information
   - Making poor execution plan choices

4. **Blocking/Locking**
   - Other transactions holding locks
   - Concurrent access issues

5. **Parameter Sniffing**
   - Cached plan optimized for different parameters

**Investigation Steps:**

1. **Check Execution Plan**
   ```sql
   -- Enable actual execution plan
   SET STATISTICS TIME ON;
   SET STATISTICS IO ON;
   -- Run your query
   ```

2. **Look for Table Scans**
   - Should see Index Seeks, not Table Scans

3. **Check for Missing Indexes**
   ```sql
   -- SQL Server suggests missing indexes
   -- Look in execution plan
   ```

4. **Update Statistics**
   ```sql
   UPDATE STATISTICS table_name;
   ```

5. **Check for Blocking**
   ```sql
   sp_who2
   -- or Activity Monitor in SSMS
   ```
</details>

---

### Question 28
Your manager asks for "a list of our best customers." What questions should you ask before writing any SQL?

<details>
<summary>Show Answer</summary>

**Critical Questions:**

**1. Define "Best"**
- Highest total revenue?
- Most orders?
- Highest average order value?
- Most recent activity?
- Highest profit margin?
- Combination of factors?

**2. Time Period**
- All time?
- Last 12 months?
- Last quarter?
- This year?

**3. Quantity**
- Top 10?
- Top 100?
- All above certain threshold?
- Specific percentage (top 20%)?

**4. Output Format**
- What information to show?
  - Name, contact info?
  - Purchase history?
  - Revenue numbers?
  - Customer category?

**5. Update Frequency**
- One-time report?
- Daily/weekly/monthly?
- Real-time dashboard?
- Historical tracking?

**6. Business Rules**
- Include inactive customers?
- Minimum purchase requirement?
- Specific product categories?
- Geographic filters?

**Why This Matters:**
- Different definitions = completely different queries
- Clarifying requirements prevents rework
- Ensures you solve the actual business problem
</details>

---

## Scoring Guide

### Excellent (24-28 correct)
🎉 **Outstanding!** You have a solid understanding of database fundamentals. Ready for Chapter 02!

### Good (20-23 correct)
👍 **Well done!** You understand most concepts. Review the questions you missed before continuing.

### Fair (15-19 correct)
📖 **Not bad!** Review the chapter lessons, especially areas where you struggled. Consider re-reading key sections.

### Needs Improvement (Below 15)
🔄 **Keep learning!** Go back through Chapter 01 lessons. Focus on:
- Database terminology
- SQL statement classes
- Keys and relationships
- SQL fundamentals

---

## 🎓 Chapter 01 Complete!

Congratulations on completing Chapter 01: Background!

**You now understand:**
- ✅ What databases are and why we use them
- ✅ Relational vs non-relational databases
- ✅ The relational model (tables, keys, relationships)
- ✅ SQL terminology and concepts
- ✅ SQL as a declarative language
- ✅ SQL statement classes (DDL, DML, DCL, TCL)
- ✅ SQL Server basics

---

## ⏭️ Ready for Chapter 02?

Move on to: **[Chapter 02: Creating Databases](../../02-creating-database/)** - Start building databases and writing SQL!

---

## 📚 Need More Practice?

- Re-read sections you found challenging
- Try the SQL Unplugged exercises again
- Set up SQL Server and explore
- Draw database diagrams for real-world scenarios
- Join SQL communities and forums

**Remember:** Understanding concepts deeply now will make everything else easier!
