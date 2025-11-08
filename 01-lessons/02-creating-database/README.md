# Chapter 02: Creating Databases and Tables

Welcome to Chapter 02! Now that you understand database concepts, it's time to get hands-on and start creating databases and tables in SQL Server.

---

## 📋 Chapter Overview

This chapter teaches you how to design and build databases from scratch. You'll learn about data types, table design principles, and how to insert, update, and delete data.

**Estimated Time:** 4-5 hours  
**Difficulty:** Beginner to Intermediate  
**Prerequisites:** Chapter 01 - Background

---

## 🎯 Learning Objectives

By the end of this chapter, you will be able to:

- ✅ Create databases and schemas in SQL Server
- ✅ Choose appropriate data types for different scenarios
- ✅ Design tables with proper constraints
- ✅ Build normalized table structures
- ✅ Insert, update, and delete data
- ✅ Handle common errors and troubleshoot issues
- ✅ Work with the Sakila sample database

---

## 📚 Lessons

### [01 - Creating a SQL Server Database](./01-creating-sqlserver-database/)
Learn how to create databases in SQL Server.

**Topics:**
- CREATE DATABASE syntax
- Database naming conventions
- Setting database options
- Using SSMS GUI vs T-SQL
- Best practices for database creation

**Time:** 20 minutes

---

### [02 - SQL Server Command-Line Tool](./02-sqlserver-command-line-tool/)
Master the sqlcmd utility for command-line database management.

**Topics:**
- sqlcmd basics
- Connecting to SQL Server
- Running queries from command line
- Executing script files
- Interactive vs batch mode

**Time:** 20 minutes

---

### [03 - Data Types: Character](./03-data-types-character/)
Understand character and string data types.

**Topics:**
- CHAR vs VARCHAR
- NCHAR vs NVARCHAR (Unicode)
- TEXT and NTEXT (legacy)
- VARCHAR(MAX)
- Choosing the right type
- Storage considerations

**Time:** 25 minutes

---

### [04 - Data Types: Numeric](./04-data-types-numeric/)
Master numeric and mathematical data types.

**Topics:**
- Integer types (TINYINT, SMALLINT, INT, BIGINT)
- Decimal types (DECIMAL, NUMERIC)
- Floating-point (FLOAT, REAL)
- MONEY and SMALLMONEY
- When to use each type
- Precision and scale

**Time:** 25 minutes

---

### [05 - Data Types: Temporal](./05-data-types-temporal/)
Work with date, time, and datetime types.

**Topics:**
- DATE, TIME, DATETIME
- DATETIME2 (recommended)
- SMALLDATETIME
- DATETIMEOFFSET (timezone-aware)
- Date formatting and functions
- Working with time zones

**Time:** 25 minutes

---

### [06 - Table Creation: Design](./06-table-creation-design/)
Learn the principles of good table design.

**Topics:**
- Identifying entities and attributes
- Choosing primary keys
- Planning relationships
- Normalization principles
- Avoiding common design mistakes
- Database diagrams

**Time:** 30 minutes

---

### [07 - Table Creation: Refinement](./07-table-creation-refinement/)
Refine your table designs with constraints and defaults.

**Topics:**
- NOT NULL constraints
- UNIQUE constraints
- CHECK constraints
- DEFAULT values
- IDENTITY columns
- Computed columns

**Time:** 25 minutes

---

### [08 - Building Schema Statements](./08-building-schema-statements/)
Write complete CREATE TABLE statements.

**Topics:**
- Full CREATE TABLE syntax
- Adding constraints
- Creating foreign keys
- Naming conventions
- Documentation and comments
- ALTER TABLE basics

**Time:** 30 minutes

---

### [09 - Inserting Data](./09-inserting-data/)
Add data to your tables with INSERT statements.

**Topics:**
- INSERT syntax
- Inserting single rows
- Inserting multiple rows
- INSERT with column list vs without
- INSERT INTO SELECT
- OUTPUT clause
- Handling IDENTITY columns

**Time:** 25 minutes

---

### [10 - Updating Data](./10-updating-data/)
Modify existing data with UPDATE statements.

**Topics:**
- UPDATE syntax
- Updating single and multiple rows
- UPDATE with WHERE clause
- UPDATE with JOIN
- Updating multiple columns
- Common pitfalls
- Testing updates safely

**Time:** 25 minutes

---

### [11 - Deleting Data](./11-deleting-data/)
Remove data from tables with DELETE statements.

**Topics:**
- DELETE syntax
- DELETE vs TRUNCATE
- DELETE with WHERE clause
- DELETE with JOIN
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
