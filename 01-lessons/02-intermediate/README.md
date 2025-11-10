# Intermediate Level - SQL Mastery

**Level:** 🟡 Intermediate

## Overview

Master essential SQL techniques used in real-world applications. Build on beginner fundamentals by enhancing the TechStore database, modifying data, and writing complex queries to combine data from multiple tables using powerful built-in functions.

---

## 📚 Lessons

| # | Lesson | Topics Covered |
|---|--------|----------------|
| 01 | [Database Enhancement](./01-database-enhancement/) | ALTER TABLE, add columns, enhance TechStore with Products/Sales/Customers |
| 02 | [Data Modification](./02-data-modification/) | UPDATE, DELETE, TRUNCATE vs DELETE |
| 03 | [Filtering Data](./03-filtering-data/) | WHERE clause, comparison operators, AND/OR/NOT, IN/BETWEEN/LIKE, IS NULL |
| 04 | [Sorting Data](./04-sorting-data/) | ORDER BY, ASC/DESC, multi-column sorting |
| 05 | [SQL Joins - Basics](./05-sql-joins-basics/) | INNER JOIN, table aliases, multi-table joins, join conditions |
| 06 | [SQL Joins - Advanced](./06-sql-joins-advanced/) | LEFT/RIGHT/FULL OUTER JOIN, CROSS JOIN, self-joins |
| 07 | [Aggregate Functions](./07-aggregate-functions/) | COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING |
| 08 | [Set Operators](./08-set-operators/) | UNION, UNION ALL, INTERSECT, EXCEPT |
| 09 | [String Functions](./09-string-functions/) | UPPER/LOWER, SUBSTRING, CONCAT, LENGTH, TRIM, REPLACE |
| 10 | [Numeric Functions](./10-numeric-functions/) | ROUND, CEILING, FLOOR, ABS, POWER |
| 11 | [Date & Time Functions](./11-date-time-functions/) | GETDATE, DATEADD, DATEDIFF, DATE_FORMAT, EXTRACT |
| 12 | [NULL Functions](./12-null-functions/) | IS NULL, COALESCE, NULLIF, ISNULL, NULL handling |
| 13 | [CASE Expressions](./13-case-expressions/) | Simple CASE, searched CASE, CASE in SELECT/WHERE/ORDER BY |
| 14 | [Window Functions - Basics](./14-window-functions-basics/) | OVER clause, PARTITION BY, window frames |

**Total:** 14 lessons building on TechStore database from Beginner level

---

## 🎯 Learning Objectives

By completing the Intermediate level, you will be able to:

1. **Enhance and Modify Databases**
   - Alter existing tables with new columns
   - Update existing records with new values
   - Delete records selectively and safely
   - Understand TRUNCATE vs DELETE

2. **Filter and Sort Data Effectively**
   - Write complex WHERE conditions with multiple operators
   - Use pattern matching and wildcard searches
   - Handle NULL values properly in queries
   - Sort results by single or multiple columns

3. **Combine Data from Multiple Tables**
   - Join 2 or more tables using INNER, LEFT, RIGHT, FULL OUTER joins
   - Understand when to use each join type
   - Write self-joins and cross joins
   - Use table aliases for clarity

4. **Aggregate and Analyze Data**
   - Calculate totals, averages, counts, min/max
   - Group data for summary reports
   - Filter aggregated results with HAVING

5. **Work with Sets**
   - Combine results from multiple queries with UNION
   - Find common records with INTERSECT
   - Find differences with EXCEPT

6. **Transform Data with Functions**
   - Manipulate text with string functions
   - Perform calculations with numeric functions
   - Work with dates and times
   - Handle NULL values safely

7. **Conditional Logic**
   - Use CASE expressions for complex transformations
   - Implement if-then-else logic in queries

8. **Advanced Analytics with Window Functions**
   - Use OVER clause and PARTITION BY
   - Understand window frames and ordering
   - Perform basic analytical queries

---

## 📖 Learning Path

```
┌─────────────────────┐
│ BEGINNER Complete  │
│ TechStore Created  │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Database Enhancement│
│ (ALTER TABLE)       │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Data Modification   │
│ (UPDATE/DELETE)     │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Filtering Data      │
│ (Advanced WHERE)    │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Sorting Data        │
│ (ORDER BY)          │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ SQL Joins           │
│ Basics → Advanced   │
│ (Multi-table)       │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Aggregate Functions │
│ (GROUP BY/HAVING)   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Set Operators       │
│ (UNION/INTERSECT)   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Built-in Functions  │
│ String → Numeric →  │
│ Date/Time → NULL    │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ CASE Expressions    │
│ (Conditional Logic) │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ Window Functions    │
│ (Basics)            │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ INTERMEDIATE Done!  │
│ Ready for Advanced  │
└─────────────────────┘
```

---

## 💡 Key Concepts

### Database Enhancement
- **ALTER TABLE:** Add columns to existing tables
- **TechStore Evolution:** Build on beginner database
- **Products Table:** Enhanced with Category, Cost, StockQuantity, IsActive
- **Sales Table:** Track customer purchases with foreign keys
- **Customers Table:** Add location and purchase tracking

### Data Modification
- **UPDATE:** Change existing records
- **DELETE:** Remove specific rows
- **TRUNCATE:** Fast deletion of all rows (resets identity)
- **Safety:** Always use WHERE clause!

### Filtering Mastery
- **Comparison Operators:** =, <>, >, <, >=, <=
- **Logical Operators:** AND, OR, NOT
- **Special Operators:** IN, BETWEEN, LIKE, IS NULL
- **Pattern Matching:** % (any characters), _ (single character)

### Sorting Data
- **ORDER BY:** Control result order
- **ASC:** Ascending (default) - low to high
- **DESC:** Descending - high to low
- **Multi-column:** Sort by multiple columns with different directions

### Join Types
```
INNER JOIN     → Only matching rows
LEFT JOIN      → All from left + matches from right
RIGHT JOIN     → All from right + matches from left
FULL OUTER JOIN → All rows from both tables
CROSS JOIN     → Cartesian product (all combinations)
SELF JOIN      → Table joined with itself
```

### Aggregate Functions
```
COUNT(*)       → Count all rows
COUNT(column)  → Count non-NULL values
SUM(column)    → Total of numeric column
AVG(column)    → Average value
MIN(column)    → Minimum value
MAX(column)    → Maximum value
GROUP BY       → Group rows for aggregation
HAVING         → Filter aggregated results
```

### Set Operations
```
UNION          → Combine results (no duplicates)
UNION ALL      → Combine results (keep duplicates)
INTERSECT      → Only common rows
EXCEPT         → Rows in first but not in second
```

### Function Categories
- **String:** Manipulate text (UPPER, LOWER, CONCAT, SUBSTRING, TRIM)
- **Numeric:** Math operations (ROUND, CEILING, FLOOR, ABS, POWER)
- **Date/Time:** Work with dates (GETDATE, DATEADD, DATEDIFF, YEAR, MONTH)
- **NULL:** Handle missing data (COALESCE, NULLIF, ISNULL, IS NULL)

### CASE Expressions
```
Simple CASE    → Compare single value to multiple options
Searched CASE  → Evaluate multiple conditions
Usage          → In SELECT, WHERE, ORDER BY, GROUP BY
```

### Window Functions
```
OVER() Clause     → Define the window
PARTITION BY      → Divide into groups
ORDER BY          → Sort within window
ROWS/RANGE        → Define frame boundaries
```

---

## ⏱️ Recommended Pace

**Suggested Timeline:** 4-6 weeks

- **Week 1:** Database Enhancement, Data Modification, Filtering (Lessons 1-3)
- **Week 2:** Sorting, Joins (Lessons 4-6)
- **Week 3:** Aggregates, Set Operators, Functions (Lessons 7-12)
- **Week 4-6:** CASE, Window Functions (Lessons 13-14)

**Daily Study:** 30-60 minutes  
**Practice:** Run all SQL files hands-on with TechStore database

---

## 🛠️ Prerequisites

Before starting Intermediate level:

✅ **Completed Beginner Level**
- Created TechStore database
- Created basic tables: Products, Customers, Departments, Employees
- Inserted sample data
- Understanding of basic SELECT queries
- Knowledge of Primary Keys and Foreign Keys

✅ **Environment Setup**
- SQL Server installed (or Docker container)
- Client tool ready (SSMS, Azure Data Studio, or VS Code)
- TechStore database ready from Beginner lessons

✅ **Basic SQL Concepts**
- Tables, rows, columns
- Primary keys, foreign keys
- Data types (VARCHAR, INT, DECIMAL, DATE)
- NULL values
- Basic INSERT statements

---

## 📊 Real-World Applications

### What You'll Build with TechStore

**1. Enhanced Product Catalog**
```sql
-- Show products with inventory status
SELECT 
    ProductName,
    Category,
    Price,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'Out of Stock'
        WHEN StockQuantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS Status
FROM Products
WHERE IsActive = 1
ORDER BY Category, ProductName;
```

**2. Customer Purchase Analysis**
```sql
-- Find top customers by total purchases
SELECT 
    c.CustomerName,
    c.City,
    c.State,
    COUNT(s.SaleID) AS OrderCount,
    SUM(s.TotalAmount) AS TotalSpent
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName, c.City, c.State
ORDER BY TotalSpent DESC;
```

**3. Sales Reporting**
```sql
-- Monthly sales summary
SELECT 
    YEAR(SaleDate) AS Year,
    MONTH(SaleDate) AS Month,
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Sales
GROUP BY YEAR(SaleDate), MONTH(SaleDate)
ORDER BY Year DESC, Month DESC;
```

---

## ✅ What You'll Master

After completing Intermediate level:

- ✓ Enhance existing databases with ALTER TABLE
- ✓ Modify data safely with UPDATE and DELETE
- ✓ Write complex multi-table queries with confidence
- ✓ Filter data using advanced conditions and pattern matching
- ✓ Sort results by multiple columns and directions
- ✓ Combine data from multiple tables with various JOIN types
- ✓ Perform aggregations and generate summary reports
- ✓ Combine results from multiple queries with set operators
- ✓ Transform data using built-in string, numeric, date, and NULL functions
- ✓ Implement conditional logic with CASE expressions
- ✓ Use basic window functions for analytics
- ✓ Handle real-world data quality issues
- ✓ Build on incremental database design
- ✓ Read and understand professional SQL code

---

## 🎓 Certification Readiness

Intermediate level prepares you for:
- **Microsoft Certified: Azure Data Fundamentals (DP-900)**
- **Oracle Database SQL Certified Associate**
- Mid-level data analyst positions
- Business intelligence developer roles

---

## 📚 Additional Resources

- **Practice Databases:** Northwind, AdventureWorks, WideWorldImporters
- **Online Practice:** SQLZoo, HackerRank, LeetCode SQL problems
- **Documentation:** Microsoft SQL Server T-SQL Reference
- **Community:** Stack Overflow SQL tag, Reddit r/SQL

---

## ➡️ Next Steps

**After Intermediate:**
- **[Advanced Level](../03-advanced/)** - Subqueries, CTEs, performance optimization
- **Practice Projects** - Build real-world applications
- **Certification** - Pursue SQL certifications

---

**Ready to level up your SQL skills? Start with [Lesson 1: Database Enhancement](./01-database-enhancement/)! 🚀**
