# Chapter 02: Creating Databases and Tables# Chapter 02: Creating Database & Tables# Chapter 02: Creating Databases and Tables



## 📋 Chapter Overview



Welcome to Chapter 02! Now that you understand database concepts, it's time to build your own database from scratch.Learn how to create databases, tables, and manage data in SQL Server.Welcome to Chapter 02! Now that you understand database concepts, it's time to get hands-on and start creating databases and tables in SQL Server.



**What You'll Build:** A complete **RetailStore** database with 8 tables across 3 schemas:

- 🏪 **Inventory** - Products, Categories, Suppliers

- 💰 **Sales** - Customers, Orders, OrderDetails  ## 📚 Lesson Order---

- 👥 **HR** - Employees, Departments



**Estimated Time:** 3-4 hours  

**Difficulty:** Beginner  Complete these lessons in order:## 📋 Chapter Overview

**Prerequisites:** Chapter 01 completed



---

### **Part 1: Database Setup**This chapter teaches you how to design and build databases from scratch. You'll learn about data types, table design principles, and how to insert, update, and delete data.

## 🎯 Learning Objectives

1. **01-database-creation.sql** - Create RetailStore database and schemas (2 min)

By the end of this chapter, you will be able to:

2. **02-table-creation-basics.sql** - Create all 8 tables (5 min)**Estimated Time:** 4-5 hours  

✅ Create databases and schemas in SQL Server  

✅ Design tables with appropriate data types  **Difficulty:** Beginner to Intermediate  

✅ Add PRIMARY KEYs, FOREIGN KEYs, and constraints  

✅ Insert data into tables  ### **Part 2: Understanding Tables****Prerequisites:** Chapter 01 - Background

✅ Update existing records safely  

✅ Delete data with proper safeguards  3. **data-types.md** - Read this guide to understand INT, VARCHAR, DECIMAL, etc. (5 min)

✅ Understand table relationships and referential integrity  

4. **03-table-design-basics.sql** - Learn primary keys and relationships (3 min)---

---

5. **04-table-constraints.sql** - Understand NOT NULL, UNIQUE, CHECK, etc. (5 min)

## 📚 Lessons - Follow This Path!

6. **05-table-modification.sql** - Add, modify, drop columns (3 min)## 🎯 Learning Objectives

### 🏗️ Part 1: Database Foundation (15 min)



| # | Lesson | SQL Script | Guide | Time |

|---|--------|------------|-------|------|### **Part 3: Working with Data**By the end of this chapter, you will be able to:

| 1 | **Database Creation** | `01-database-creation.sql` | [`01-database-creation-guide.md`](./01-database-creation-guide.md) | 5 min |

| 2 | **Table Creation** | `02-table-creation-basics.sql` | [`02-table-creation-guide.md`](./02-table-creation-guide.md) | 10 min |7. **06-data-insertion.sql** - Insert sample data (5 min)



**Read First:** [`data-types.md`](./data-types.md) - Understand INT, VARCHAR, DECIMAL, etc.8. **07-data-updates.sql** - Update existing data (3 min)- ✅ Create databases and schemas in SQL Server



---9. **08-data-deletion.sql** - Delete data safely (3 min)- ✅ Choose appropriate data types for different scenarios



### 🔧 Part 2: Table Design & Constraints (20 min)10. **09-practice-exercises.sql** - Test your skills (10 min)- ✅ Design tables with proper constraints



| # | Lesson | SQL Script | Guide | Time |- ✅ Build normalized table structures

|---|--------|------------|-------|------|

| 3 | **Table Design Basics** | `03-table-design-basics.sql` | [`03-table-design-guide.md`](./03-table-design-guide.md) | 10 min |## 🎯 Learning Objectives- ✅ Insert, update, and delete data

| 4 | **Table Constraints** | `04-table-constraints.sql` | - | 5 min |

| 5 | **Table Modification** | `05-table-modification.sql` | - | 5 min |- ✅ Handle common errors and troubleshoot issues



---By the end of this chapter, you will:- ✅ Work with the Sakila sample database



### 📊 Part 3: Working with Data (20 min)- ✅ Create databases and schemas



| # | Lesson | SQL Script | Guide | Time |- ✅ Create tables with proper data types---

|---|--------|------------|-------|------|

| 6 | **Data Insertion** | `06-data-insertion.sql` | [`06-data-insertion-guide.md`](./06-data-insertion-guide.md) | 8 min |- ✅ Add constraints to enforce data quality

| 7 | **Data Updates** | `07-data-updates.sql` | [`07-data-updates-guide.md`](./07-data-updates-guide.md) | 6 min |

| 8 | **Data Deletion** | `08-data-deletion.sql` | [`08-data-deletion-guide.md`](./08-data-deletion-guide.md) | 6 min |- ✅ Insert, update, and delete data## 📚 Lessons



---- ✅ Understand table relationships



### 🎓 Part 4: Practice & Assessment (15 min)### [01 - Creating a SQL Server Database](./01-creating-sqlserver-database/)



| # | Lesson | SQL Script | Time |## 🗂️ The RetailStore DatabaseLearn how to create databases in SQL Server.

|---|--------|------------|------|

| 9 | **Practice Exercises** | `09-practice-exercises.sql` | 15 min |



---You'll build a complete retail database with:**Topics:**



## 🗺️ Visual Learning Path- **Inventory**: Products, Categories, Suppliers- CREATE DATABASE syntax



```- **Sales**: Customers, Orders, OrderDetails- Database naming conventions

START HERE

    ↓- **HR**: Employees, Departments- Setting database options

📖 Read: data-types.md

    ↓- Using SSMS GUI vs T-SQL

1️⃣ CREATE Database & Schemas (Lesson 01)

    ↓## 💡 Tips- Best practices for database creation

2️⃣ CREATE Tables (Lesson 02)

    ↓

3️⃣ ADD Constraints (Lesson 03-04)

    ↓- Run scripts in order (01 through 09)**Time:** 20 minutes

4️⃣ ALTER Tables (Lesson 05)

    ↓- Each script builds on the previous one

5️⃣ INSERT Data (Lesson 06)

    ↓- Read `data-types.md` before running table creation---

6️⃣ UPDATE Data (Lesson 07)

    ↓- Try the practice exercises to reinforce learning

7️⃣ DELETE Data (Lesson 08)

    ↓### [02 - SQL Server Command-Line Tool](./02-sqlserver-command-line-tool/)

8️⃣ PRACTICE (Lesson 09)

    ↓## ⏭️ Next ChapterMaster the sqlcmd utility for command-line database management.

✅ COMPLETE!

    ↓

NEXT: Chapter 03 - Query Primer

```After completing this chapter, move to:**Topics:**



---**Chapter 03: Query Primer** - Learn SELECT queries, filtering, and sorting- sqlcmd basics



## 🗂️ The RetailStore Database Structure- Connecting to SQL Server



```---- Running queries from command line

🏢 RetailStore Database

│- Executing script files

├── 📂 Inventory Schema

│   ├── Categories (CategoryID, CategoryName, Description)**Total Time**: ~40 minutes- Interactive vs batch mode

│   ├── Suppliers (SupplierID, SupplierName, Contact Info)

│   └── Products (ProductID, Name, Price, Stock, etc.)

│       └── Links to Categories & Suppliers**Time:** 20 minutes

│

├── 📂 Sales Schema---

│   ├── Customers (CustomerID, Name, Email, etc.)

│   ├── Orders (OrderID, CustomerID, OrderDate, Status)### [03 - Data Types: Character](./03-data-types-character/)

│   │   └── Links to CustomersUnderstand character and string data types.

│   └── OrderDetails (DetailID, OrderID, ProductID, Quantity)

│       └── Links to Orders & Products**Topics:**

│- CHAR vs VARCHAR

└── 📂 HR Schema- NCHAR vs NVARCHAR (Unicode)

    ├── Departments (DepartmentID, Name, Location)- TEXT and NTEXT (legacy)

    └── Employees (EmployeeID, Name, Salary, etc.)- VARCHAR(MAX)

        └── Links to Departments- Choosing the right type

```- Storage considerations



---**Time:** 25 minutes



## 💡 How to Use This Chapter---



### For Each Lesson:### [04 - Data Types: Numeric](./04-data-types-numeric/)

Master numeric and mathematical data types.

1. **📖 Read the Guide** (`.md` file) - Understand concepts first

2. **💻 Run the SQL Script** (`.sql` file) - Execute the code**Topics:**

3. **🧪 Experiment** - Try modifying the examples- Integer types (TINYINT, SMALLINT, INT, BIGINT)

4. **✅ Verify** - Check your results- Decimal types (DECIMAL, NUMERIC)

- Floating-point (FLOAT, REAL)

### Example Workflow for Lesson 01:- MONEY and SMALLMONEY

- When to use each type

```- Precision and scale

1. Open: 01-database-creation-guide.md

2. Read the diagrams and explanations**Time:** 25 minutes

3. Open: 01-database-creation.sql in SSMS

4. Execute the script (F5)---

5. Verify: Check that RetailStore database exists

6. Experiment: Try querying sys.schemas### [05 - Data Types: Temporal](./05-data-types-temporal/)

```Work with date, time, and datetime types.



---**Topics:**

- DATE, TIME, DATETIME

## 📋 Quick Reference - Common Commands- DATETIME2 (recommended)

- SMALLDATETIME

### Database Operations- DATETIMEOFFSET (timezone-aware)

```sql- Date formatting and functions

CREATE DATABASE RetailStore;      -- Create database- Working with time zones

USE RetailStore;                  -- Switch to database

DROP DATABASE RetailStore;        -- Delete database (careful!)**Time:** 25 minutes

```

---

### Table Operations

```sql### [06 - Table Creation: Design](./06-table-creation-design/)

CREATE TABLE schema.TableName (...);  -- Create tableLearn the principles of good table design.

ALTER TABLE TableName ADD ...;        -- Modify table

DROP TABLE TableName;                 -- Delete table**Topics:**

```- Identifying entities and attributes

- Choosing primary keys

### Data Operations (CRUD)- Planning relationships

```sql- Normalization principles

INSERT INTO Table VALUES (...);   -- Create data- Avoiding common design mistakes

SELECT * FROM Table;              -- Read data- Database diagrams

UPDATE Table SET col = val;       -- Update data

DELETE FROM Table WHERE ...;      -- Delete data**Time:** 30 minutes

```

---

---

### [07 - Table Creation: Refinement](./07-table-creation-refinement/)

## ⚠️ Important TipsRefine your table designs with constraints and defaults.



### ✅ DO:**Topics:**

- Run scripts in order (01 → 09)- NOT NULL constraints

- Read markdown guides before running SQL scripts- UNIQUE constraints

- Use transactions for UPDATE/DELETE operations- CHECK constraints

- Test with SELECT before running UPDATE/DELETE- DEFAULT values

- Keep backups of your database- IDENTITY columns

- Computed columns

### ❌ DON'T:

- Skip lessons - each builds on the previous**Time:** 25 minutes

- Run UPDATE/DELETE without WHERE clause

- Forget to use WHERE clause---

- Delete parent records before children (unless CASCADE)

- Run scripts on production databases (use test only!)### [08 - Building Schema Statements](./08-building-schema-statements/)

Write complete CREATE TABLE statements.

---

**Topics:**

## 🎓 Key Concepts Summary- Full CREATE TABLE syntax

- Adding constraints

| Concept | What It Does | Example |- Creating foreign keys

|---------|--------------|---------|- Naming conventions

| **PRIMARY KEY** | Unique identifier | `CustomerID` |- Documentation and comments

| **FOREIGN KEY** | Links tables | `Products.CategoryID → Categories.CategoryID` |- ALTER TABLE basics

| **UNIQUE** | No duplicates | `Email UNIQUE` |

| **CHECK** | Validates data | `Price >= 0` |**Time:** 30 minutes

| **DEFAULT** | Auto-fills value | `Country DEFAULT 'USA'` |

| **IDENTITY** | Auto-increment | `IDENTITY(1,1)` |---

| **NOT NULL** | Required field | `FirstName NOT NULL` |

### [09 - Inserting Data](./09-inserting-data/)

---Add data to your tables with INSERT statements.



## 🧪 Hands-On Practice**Topics:**

- INSERT syntax

Throughout this chapter, you'll:- Inserting single rows

- ✅ Create 1 database- Inserting multiple rows

- ✅ Create 3 schemas- INSERT with column list vs without

- ✅ Create 8 tables- INSERT INTO SELECT

- ✅ Add 20+ constraints- OUTPUT clause

- ✅ Insert sample data- Handling IDENTITY columns

- ✅ Update records

- ✅ Delete records safely**Time:** 25 minutes



**Remember:** Type every command yourself! Copying/pasting works, but typing helps you learn.---



---### [10 - Updating Data](./10-updating-data/)

Modify existing data with UPDATE statements.

## ⏭️ Next Steps

**Topics:**

After completing this chapter:- UPDATE syntax

- Updating single and multiple rows

1. ✅ Verify all 8 tables exist in your database- UPDATE with WHERE clause

2. ✅ Complete the practice exercises (Lesson 09)- UPDATE with JOIN

3. ✅ Review any concepts you found difficult- Updating multiple columns

4. ➡️ Move to **Chapter 03: Query Primer** to learn SELECT statements- Common pitfalls

- Testing updates safely

---

**Time:** 25 minutes

## 📚 Additional Resources

---

- **T-SQL Reference:** [Microsoft Docs - T-SQL](https://docs.microsoft.com/sql/t-sql/)

- **Data Types:** [SQL Server Data Types](https://docs.microsoft.com/sql/t-sql/data-types/)### [11 - Deleting Data](./11-deleting-data/)

- **Best Practices:** [Database Design Guide](https://docs.microsoft.com/sql/relational-databases/tables/tables)Remove data from tables with DELETE statements.



---**Topics:**

- DELETE syntax

**🚀 Ready to start?** Begin with **Lesson 01: Database Creation**!- DELETE vs TRUNCATE

- DELETE with WHERE clause

**Total Chapter Time:** ~3-4 hours (at a comfortable learning pace)- DELETE with JOIN

- Cascading deletes
- Soft deletes vs hard deletes
- Recovery considerations

**Time:** 20 minutes

---

### [12 - Common Errors](./12-common-errors/)
Learn to recognize and fix common SQL errors.

**Topics:**
- Syntax errors
- Constraint violations
- Foreign key errors
- Data type mismatches
- NULL handling errors
- Reading error messages
- Debugging strategies

**Time:** 25 minutes

---

### [13 - The Sakila Database](./13-sakila-database/)
Explore the Sakila sample database structure.

**Topics:**
- Sakila database overview
- Table structure and relationships
- Key entities (film, actor, customer, rental)
- Business rules in Sakila
- Practice queries
- Using Sakila for learning

**Time:** 30 minutes

---

### [14 - Test Your Knowledge](./14-test-your-knowledge/)
Assess your understanding with quiz questions and hands-on exercises.

**Topics:**
- Multiple choice questions
- CREATE TABLE exercises
- Data manipulation practice
- Error troubleshooting
- Design challenges

**Time:** 30 minutes

---

## 🎓 Chapter Summary

After completing this chapter, you'll have:
- ✅ Created databases and tables in SQL Server
- ✅ Mastered all major data types
- ✅ Designed normalized table structures
- ✅ Inserted, updated, and deleted data
- ✅ Handled constraints and defaults
- ✅ Worked with the Sakila database
- ✅ Debugged common errors

---

## 📝 Key Takeaways

1. **Choose data types carefully** - They affect storage, performance, and data integrity
2. **Always use constraints** - They prevent bad data from entering your database
3. **Test with SELECT first** - Before UPDATE or DELETE, verify what you're changing
4. **Use explicit column lists** - Makes INSERT statements clearer and more maintainable
5. **Normalize your design** - Reduce redundancy, improve data integrity
6. **Document your schema** - Future you (and others) will thank you

---

## 🛠️ Hands-On Practice

Throughout this chapter, you'll create:
- A **Company** database with employees and departments
- A **Store** database with products and orders
- Tables in the **Sakila** database
- Various practice schemas

**Remember:** The best way to learn SQL is by doing! Type every example, experiment with variations, and break things (in your test database!).

---

## ⏭️ Next Steps

Once you've completed this chapter:
1. Take the knowledge test to verify understanding
2. Practice creating your own database designs
3. Move on to [Chapter 03: Query Primer](../03-query-primer/)
4. Keep the Sakila database - you'll use it throughout the course

---

## 📚 Additional Resources

- [T-SQL Data Types Reference](https://docs.microsoft.com/sql/t-sql/data-types/)
- [CREATE TABLE Documentation](https://docs.microsoft.com/sql/t-sql/statements/create-table-transact-sql)
- [Database Design Best Practices](https://docs.microsoft.com/sql/relational-databases/tables/tables)
- [Sakila Database GitHub](https://github.com/jOOQ/jOOQ/tree/main/jOOQ-examples/Sakila)

---

**Ready to build databases?** Start with [01 - Creating a SQL Server Database](./01-creating-mysql-database/)!
