# Chapter 03: Query Primer - Your First SELECT Statements

## 📋 Chapter Overview

Welcome to Chapter 03! This is where SQL gets exciting - you'll learn to **query data** and retrieve exactly what you need from your database.

**What You'll Learn:**
- 📊 SELECT statements - the foundation of SQL queries
- 🎯 Filtering data with WHERE
- 📈 Sorting results with ORDER BY
- 📑 Grouping data with GROUP BY
- 🔍 Joining tables together

**Estimated Time:** 4-5 hours  
**Difficulty:** Beginner  
**Prerequisites:** Chapter 02 completed (RetailStore database with data)

---

## 🎯 Learning Objectives

By the end of this chapter, you will be able to:

✅ Write SELECT statements to retrieve data  
✅ Use WHERE clause to filter results  
✅ Sort data with ORDER BY  
✅ Join multiple tables together  
✅ Group and aggregate data with GROUP BY  
✅ Filter grouped data with HAVING  
✅ Combine multiple query clauses effectively  

---

## 📚 Lessons - Follow This Path!

### 🔍 Part 1: SELECT Fundamentals (30 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 1 | **Query Mechanics** | `01-query-mechanics.sql` | `01-query-mechanics-guide.md` | 10 min |
| 2 | **Query Clauses** | `02-query-clauses.sql` | `02-query-clauses-guide.md` | 10 min |
| 3 | **SELECT Clause** | `03-select-clause.sql` | `03-select-clause-guide.md` | 10 min |

---

### 🎯 Part 2: Filtering & Joining (45 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 4 | **FROM Clause & Joins** | `04-from-clause.sql` | `04-from-clause-guide.md` | 15 min |
| 5 | **WHERE Clause** | `05-where-clause.sql` | `05-where-clause-guide.md` | 15 min |

---

### 📊 Part 3: Grouping & Sorting (30 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 6 | **GROUP BY & HAVING** | `06-group-by-having.sql` | `06-group-by-having-guide.md` | 15 min |
| 7 | **ORDER BY Clause** | `07-order-by-clause.sql` | `07-order-by-clause-guide.md` | 10 min |

---

### 🎓 Part 4: Practice & Assessment (20 min)

| # | Lesson | SQL Script | Time |
|---|--------|------------|------|
| 8 | **Practice Exercises** | `08-test-your-knowledge.sql` | 20 min |

---

## 🗺️ Visual Learning Path

```
START HERE
    ↓
1️⃣ How Queries Work (Query Mechanics)
    ↓
2️⃣ Query Structure (Clauses Overview)
    ↓
3️⃣ SELECT: Choose Columns
    ↓
4️⃣ FROM: Choose Tables & JOIN
    ↓
5️⃣ WHERE: Filter Rows
    ↓
6️⃣ GROUP BY: Aggregate Data
    ↓
7️⃣ ORDER BY: Sort Results
    ↓
8️⃣ PRACTICE: Combine Everything
    ↓
✅ COMPLETE!
    ↓
NEXT: Chapter 04 - Advanced Filtering
```

---

## 🔍 The SELECT Statement Anatomy

```sql
SELECT column1, column2          -- What columns to show
FROM TableName                   -- Which table(s)
WHERE condition                  -- Filter rows
GROUP BY column                  -- Group rows
HAVING aggregate_condition       -- Filter groups
ORDER BY column;                 -- Sort results
```

### Visual Breakdown:

```
┌─────────────────────────────────────────────┐
│  SELECT FirstName, LastName, Salary         │ ← Choose columns
├─────────────────────────────────────────────┤
│  FROM HR.Employees                          │ ← From which table
├─────────────────────────────────────────────┤
│  WHERE DepartmentID = 1                     │ ← Filter: Only Dept 1
├─────────────────────────────────────────────┤
│  ORDER BY Salary DESC;                      │ ← Sort: Highest first
└─────────────────────────────────────────────┘

Result:
┌───────────┬──────────┬─────────┐
│ FirstName │ LastName │ Salary  │
├───────────┼──────────┼─────────┤
│ Alice     │ Johnson  │ 85000   │
│ Bob       │ Smith    │ 72000   │
│ Carol     │ Williams │ 68000   │
└───────────┴──────────┴─────────┘
```

---

## 💡 How to Use This Chapter

### For Each Lesson:

1. **📖 Read the Guide** (`.md` file) - Understand the concept
2. **💻 Run the SQL Script** (`.sql` file) - See examples in action
3. **🧪 Modify Examples** - Change values and see what happens
4. **✅ Do Exercises** - Practice what you learned

### Example Workflow:

```
1. Read: 01-query-mechanics-guide.md
2. Open: 01-query-mechanics.sql in SSMS
3. Execute each query one-by-one (highlight and press F5)
4. Study the results
5. Try modifying: Change column names, add WHERE clauses
6. Move to next lesson when comfortable
```

---

## 📋 Quick Reference - Query Patterns

### Basic SELECT
```sql
SELECT * FROM Customers;                    -- All columns, all rows
SELECT FirstName, Email FROM Customers;     -- Specific columns
SELECT TOP 10 * FROM Products;              -- First 10 rows
```

### With WHERE (Filter)
```sql
SELECT * FROM Products WHERE Price > 100;
SELECT * FROM Customers WHERE Country = 'USA';
SELECT * FROM Orders WHERE OrderDate >= '2025-01-01';
```

### With ORDER BY (Sort)
```sql
SELECT * FROM Products ORDER BY Price;           -- Ascending
SELECT * FROM Products ORDER BY Price DESC;      -- Descending
SELECT * FROM Customers ORDER BY LastName, FirstName;
```

### With JOIN (Multiple Tables)
```sql
SELECT p.ProductName, c.CategoryName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### With GROUP BY (Aggregate)
```sql
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;
```

---

## 🎓 Key Concepts You'll Master

| Concept | What It Does | Example |
|---------|--------------|---------|
| **SELECT** | Choose which columns to display | `SELECT FirstName, LastName` |
| **FROM** | Specify which table(s) to query | `FROM Customers` |
| **WHERE** | Filter which rows to include | `WHERE Price > 100` |
| **JOIN** | Combine data from multiple tables | `INNER JOIN Categories ON...` |
| **GROUP BY** | Group rows for aggregation | `GROUP BY CategoryID` |
| **HAVING** | Filter grouped results | `HAVING COUNT(*) > 5` |
| **ORDER BY** | Sort the results | `ORDER BY Price DESC` |

---

## 🎨 Real-World Query Examples

### Example 1: Find Expensive Products
```sql
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 500
ORDER BY Price DESC;
```

### Example 2: Customer Order Count
```sql
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.FirstName, c.LastName
ORDER BY TotalOrders DESC;
```

### Example 3: Products by Category
```sql
SELECT 
    cat.CategoryName,
    p.ProductName,
    p.Price
FROM Inventory.Categories cat
INNER JOIN Inventory.Products p ON cat.CategoryID = p.CategoryID
ORDER BY cat.CategoryName, p.Price DESC;
```

---

## ⚠️ Important Tips

### ✅ DO:
- Start simple and add complexity gradually
- Use aliases for table names (makes queries shorter)
- Format queries for readability (use line breaks)
- Test queries on small datasets first
- Comment complex queries to remember what they do

### ❌ DON'T:
- Use `SELECT *` in production code (specify columns)
- Forget WHERE when you need filtering
- Join tables without understanding the relationship
- Ignore NULL values (they behave differently)
- Skip the ORDER BY if order matters

---

## 🧪 Sample Dataset Reminder

You'll be querying the **RetailStore** database from Chapter 02:

```
Available Tables:
├── Inventory.Categories
├── Inventory.Suppliers  
├── Inventory.Products
├── Sales.Customers
├── Sales.Orders
├── Sales.OrderDetails
├── HR.Departments
└── HR.Employees
```

**Make sure you have data in these tables!** If not, run the INSERT scripts from Chapter 02, Lesson 06.

---

## 📊 Query Execution Order

**What you write:**
```sql
SELECT column
FROM table
WHERE condition
GROUP BY column
HAVING condition
ORDER BY column;
```

**How SQL Server processes it:**
```
1. FROM      → Get the table(s)
2. WHERE     → Filter rows
3. GROUP BY  → Group rows
4. HAVING    → Filter groups
5. SELECT    → Choose columns
6. ORDER BY  → Sort results
```

This order matters when understanding how queries work!

---

## 🎯 Query Performance Tips

### Fast Queries:
```sql
-- ✅ Filter early with WHERE
SELECT * FROM Products WHERE CategoryID = 1;

-- ✅ Only select needed columns
SELECT ProductName, Price FROM Products;

-- ✅ Use TOP to limit results
SELECT TOP 100 * FROM Orders ORDER BY OrderDate DESC;
```

### Slow Queries (Avoid):
```sql
-- ❌ SELECT * from huge tables
SELECT * FROM Orders;  -- If millions of rows

-- ❌ No WHERE on large tables
SELECT * FROM Products;  -- Gets everything

-- ❌ Complex calculations on all rows
SELECT *, Price * 1.15 * TaxRate * ... FROM Products;
```

---

## ⏭️ Next Steps

After completing this chapter:

1. ✅ Practice writing 10+ queries on your own
2. ✅ Complete all exercises in Lesson 08
3. ✅ Try joining 3+ tables together
4. ➡️ Move to **Chapter 04: Advanced Filtering**

---

## 📚 Additional Resources

- **SELECT Reference:** [Microsoft Docs - SELECT](https://docs.microsoft.com/sql/t-sql/queries/select-transact-sql)
- **JOIN Types:** [Understanding JOINs](https://docs.microsoft.com/sql/relational-databases/performance/joins)
- **Query Performance:** [Query Optimization](https://docs.microsoft.com/sql/relational-databases/query-processing-architecture-guide)

---

## 🧪 Quick Self-Test

Before starting, make sure you can answer:
- ✓ What does SELECT do?
- ✓ How do you filter rows?
- ✓ What's the difference between WHERE and HAVING?
- ✓ How do you join two tables?

If unsure, the guides will teach you everything!

---

**🚀 Ready to start querying?** Begin with **Lesson 01: Query Mechanics**!

**Total Chapter Time:** ~2-3 hours (includes practice)
