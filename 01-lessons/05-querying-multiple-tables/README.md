# Chapter 05: Querying Multiple Tables

## Overview

Learn how to combine data from multiple tables using JOINs - one of the most powerful features in SQL. This chapter covers everything from basic JOIN concepts to complex multi-table queries and self-joins.

---

## Learning Objectives

By the end of this chapter, you will be able to:

1. ✅ Understand why JOINs are essential for relational databases
2. ✅ Explain what a Cartesian product is and why to avoid it
3. ✅ Write INNER JOIN queries to combine related data
4. ✅ Use modern ANSI JOIN syntax vs. old-style joins
5. ✅ Join three or more tables in a single query
6. ✅ Use subqueries as virtual tables
7. ✅ Reference the same table multiple times with aliases
8. ✅ Create self-joins to relate rows within a single table
9. ✅ Choose the right JOIN strategy for your data needs

---

## Chapter Structure

```
Chapter 05: Querying Multiple Tables (9 Lessons)
│
├── 01. What is a Join?              [15 min] ⭐ START HERE
│   └── Understanding relationships, foreign keys, JOIN basics
│
├── 02. Cartesian Product            [10 min]
│   └── What happens without JOIN conditions (and why it's bad!)
│
├── 03. Inner Joins                  [20 min] ⭐ MOST IMPORTANT
│   └── Matching rows between tables
│
├── 04. ANSI Join Syntax             [15 min]
│   └── Modern vs. old-style JOIN syntax
│
├── 05. Joining Three Tables         [20 min]
│   └── Multi-table queries, chaining JOINs
│
├── 06. Subqueries as Tables         [20 min]
│   └── Using SELECT results as virtual tables
│
├── 07. Using Same Table Twice       [15 min]
│   └── Table aliases, multiple references
│
├── 08. Self Joins                   [20 min]
│   └── Joining a table to itself
│
└── 09. Test Your Knowledge          [45 min]
    └── Comprehensive practice exercises

Total Time: ~3 hours
```

---

## Visual Learning Path

```
                    START HERE
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Why do we need JOINs?        │
        │  (Lesson 01)                  │
        └───────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  What NOT to do!              │
        │  Cartesian Product            │
        │  (Lesson 02)                  │
        └───────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  ⭐ INNER JOIN                │
        │  Matching rows                │
        │  (Lesson 03)                  │
        └───────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Modern Syntax                │
        │  ANSI JOIN vs Old Style       │
        │  (Lesson 04)                  │
        └───────────────────────────────┘
                        │
            ┌───────────┴───────────┐
            ▼                       ▼
    ┌─────────────┐         ┌─────────────┐
    │  3+ Tables  │         │  Subqueries │
    │  (Lesson 05)│         │  as Tables  │
    └─────────────┘         │  (Lesson 06)│
            │               └─────────────┘
            │                       │
            └───────────┬───────────┘
                        ▼
        ┌───────────────────────────────┐
        │  Advanced Techniques          │
        │  • Same table twice (L07)     │
        │  • Self-joins (L08)           │
        └───────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Practice & Test              │
        │  (Lesson 09)                  │
        └───────────────────────────────┘
```

---

## Why Learn JOINs?

### The Problem: Data is Split Across Tables

In a well-designed database, data is **normalized** (split into separate tables) to avoid redundancy:

```
❌ BAD DESIGN (All in one table):
┌────────┬─────────┬──────────┬──────────────┬───────────┐
│ OrderID│ Customer│ Product  │ CategoryName │ Price     │
├────────┼─────────┼──────────┼──────────────┼───────────┤
│   1    │  John   │  Laptop  │ Electronics  │   800     │
│   2    │  John   │  Mouse   │ Electronics  │    25     │
│   3    │  Sarah  │  Laptop  │ Electronics  │   800     │
└────────┴─────────┴──────────┴──────────────┴───────────┘
Problems:
• "Electronics" repeated 3 times (waste)
• "Laptop" data duplicated (inconsistency risk)
• Hard to update (change category name = update everywhere!)

✅ GOOD DESIGN (Normalized):

Orders Table:
┌────────┬────────────┬───────────┐
│ OrderID│ CustomerID │ ProductID │
├────────┼────────────┼───────────┤
│   1    │      1     │     1     │
│   2    │      1     │     2     │
│   3    │      2     │     1     │
└────────┴────────────┴───────────┘

Customers Table:              Products Table:
┌────────────┬─────────┐     ┌───────────┬──────────┬────────────┐
│ CustomerID │  Name   │     │ ProductID │   Name   │ CategoryID │
├────────────┼─────────┤     ├───────────┼──────────┼────────────┤
│      1     │  John   │     │     1     │  Laptop  │      1     │
│      2     │  Sarah  │     │     2     │  Mouse   │      1     │
└────────────┴─────────┘     └───────────┴──────────┴────────────┘

Categories Table:
┌────────────┬──────────────┐
│ CategoryID │     Name     │
├────────────┼──────────────┤
│      1     │ Electronics  │
└────────────┴──────────────┘

Benefits:
✓ No duplication
✓ Easy to update
✓ Data integrity
```

**But now we need JOINs to see the complete picture!**

---

## Join Types Overview

```
┌──────────────────────────────────────────────────────┐
│                   INNER JOIN                         │
│  Returns only rows that have matches in BOTH tables  │
│                                                       │
│  Table A          Table B          Result            │
│  ┌─────┐         ┌─────┐          ┌─────┐          │
│  │  A  │         │  B  │          │ A∩B │          │
│  │ ┌───┼─────────┼───┐ │          └─────┘          │
│  │ │ ∩ │         │ ∩ │ │    Only matching rows     │
│  │ └───┼─────────┼───┘ │                            │
│  │     │         │     │                            │
│  └─────┘         └─────┘                            │
│  Unmatched       Unmatched                          │
│  (excluded)      (excluded)                         │
└──────────────────────────────────────────────────────┘

This chapter focuses on INNER JOIN.
Other join types (LEFT, RIGHT, FULL) are covered in Chapter 10.
```

---

## Key Concepts

### 1. Foreign Key Relationships

```
Products.CategoryID → Categories.CategoryID
        ↑                      ↑
   Foreign Key            Primary Key

The foreign key in Products references 
the primary key in Categories
```

### 2. JOIN Syntax Components

```sql
SELECT columns
FROM table1
INNER JOIN table2 ON table1.column = table2.column
           ↑            ↑
       Join Type    Join Condition
```

### 3. Table Aliases

```sql
-- Without aliases (verbose)
SELECT Products.ProductName, Categories.CategoryName
FROM Products
INNER JOIN Categories ON Products.CategoryID = Categories.CategoryID

-- With aliases (cleaner)
SELECT p.ProductName, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
       ↑                        ↑
    Alias                   Use alias
```

---

## RetailStore Database Schema

This chapter uses the following tables:

```
┌─────────────────────────────────────────────────────────┐
│                   Inventory Schema                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Categories                    Products                 │
│  ┌────────────┐               ┌────────────┐           │
│  │ CategoryID │───────────────│ CategoryID │ (FK)      │
│  │ Name       │               │ ProductID  │           │
│  └────────────┘               │ Name       │           │
│                                │ Price      │           │
│                                │ SupplierID │──┐        │
│                                └────────────┘  │        │
│                                                 │        │
│  Suppliers                                      │        │
│  ┌────────────┐                                │        │
│  │ SupplierID │────────────────────────────────┘        │
│  │ Name       │                                         │
│  │ ContactName│                                         │
│  └────────────┘                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     Sales Schema                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Customers                    Orders                    │
│  ┌────────────┐               ┌────────────┐           │
│  │ CustomerID │───────────────│ CustomerID │ (FK)      │
│  │ FirstName  │               │ OrderID    │           │
│  │ LastName   │               │ OrderDate  │           │
│  │ Email      │               │ TotalAmount│           │
│  └────────────┘               └────────────┘           │
│                                      │                  │
│                                      │                  │
│  OrderDetails                        │                  │
│  ┌────────────┐                      │                  │
│  │ OrderID    │──────────────────────┘                  │
│  │ ProductID  │──────────┐                              │
│  │ Quantity   │          │                              │
│  │ UnitPrice  │          │                              │
│  └────────────┘          │                              │
│                          │                              │
│          ┌───────────────┘                              │
│          │                                               │
│  Products (from Inventory schema)                       │
│  ┌────────────┐                                         │
│  │ ProductID  │                                         │
│  │ Name       │                                         │
│  └────────────┘                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                      HR Schema                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Employees (Self-Referencing)                           │
│  ┌────────────┐                                         │
│  │ EmployeeID │───┐                                     │
│  │ FirstName  │   │                                     │
│  │ LastName   │   │                                     │
│  │ ManagerID  │───┘ (References EmployeeID)            │
│  │ Salary     │                                         │
│  └────────────┘                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Common JOIN Patterns

### Pattern 1: Simple Two-Table Join

```sql
-- Get product names with their category names
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;
```

### Pattern 2: Three-Table Join

```sql
-- Get orders with customer and product details
SELECT 
    c.FirstName,
    c.LastName,
    p.ProductName,
    od.Quantity
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;
```

### Pattern 3: Self-Join

```sql
-- Get employees with their managers
SELECT 
    e.FirstName AS Employee,
    m.FirstName AS Manager
FROM HR.Employees e
INNER JOIN HR.Employees m ON e.ManagerID = m.EmployeeID;
```

---

## Performance Tips

```
✅ DO:
  • Always use JOIN conditions (avoid Cartesian products!)
  • Use table aliases for readability
  • Join on indexed columns (usually foreign keys)
  • Filter early with WHERE clause
  • Use INNER JOIN when you only need matches

❌ DON'T:
  • Forget the ON clause
  • Use old-style comma joins (WHERE-based)
  • Join on unindexed columns without good reason
  • Join more tables than necessary
  • Use SELECT * in production queries
```

---

## Quick Reference

### Basic JOIN Syntax

```sql
-- Template
SELECT columns
FROM table1 alias1
INNER JOIN table2 alias2 ON alias1.column = alias2.column
WHERE conditions
ORDER BY columns;

-- Example
SELECT p.ProductName, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100
ORDER BY p.ProductName;
```

### Multiple JOINs

```sql
SELECT columns
FROM table1 t1
INNER JOIN table2 t2 ON t1.id = t2.id
INNER JOIN table3 t3 ON t2.id = t3.id
INNER JOIN table4 t4 ON t3.id = t4.id;
```

---

## Common Mistakes to Avoid

### Mistake 1: Missing ON clause (Cartesian Product)

```sql
-- ❌ WRONG: Returns every combination (1000 × 1000 = 1,000,000 rows!)
SELECT * FROM Products, Categories;

-- ✅ CORRECT: Only matching rows
SELECT * FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Mistake 2: Ambiguous column names

```sql
-- ❌ WRONG: Which table's ProductID?
SELECT ProductID FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID;

-- ✅ CORRECT: Specify table/alias
SELECT p.ProductID FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID;
```

### Mistake 3: Wrong JOIN conditions

```sql
-- ❌ WRONG: Joining on wrong columns
SELECT * FROM Products p
INNER JOIN Categories c ON p.ProductID = c.CategoryID;  -- Wrong match!

-- ✅ CORRECT: Join on related columns
SELECT * FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

---

## What You'll Build

By the end of this chapter, you'll be able to write complex queries like this:

```sql
-- Sales Report: Customer orders with product details
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    s.SupplierName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE o.OrderDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY o.OrderDate DESC, c.LastName;
```

---

## Ready to Start?

Begin with **[Lesson 01: What is a Join?](01-what-is-join/01-what-is-join.sql)** to understand the fundamentals of combining tables.

---

## Chapter Navigation

- **Previous:** [Chapter 04 - Filtering](../04-filtering/README.md)
- **Next:** [Chapter 06 - Working with Sets](../06-working-with-sets/README.md)

---

**Estimated Completion Time:** 3 hours  
**Difficulty:** Intermediate  
**Prerequisites:** Chapters 01-04 completed
