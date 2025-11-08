# Chapter 06: Working with Sets

## Overview

This chapter covers **set operations** in SQL - combining results from multiple queries using UNION, INTERSECT, and EXCEPT. You'll learn how to merge data from different sources, find common records, and identify differences between datasets.

---

## Learning Objectives

By the end of this chapter, you will be able to:

1. **Understand set theory** fundamentals in SQL context
2. **Combine query results** using UNION and UNION ALL
3. **Find common records** using INTERSECT
4. **Identify differences** using EXCEPT
5. **Apply set operation rules** correctly
6. **Sort compound results** effectively
7. **Handle precedence** in complex set operations
8. **Solve real-world problems** using set operations

---

## Chapter Structure

```
Chapter 06: Working with Sets
├─ Lesson 01: Set Theory Primer (15 min)
│  └─ Mathematical foundations, Venn diagrams, SQL context
│
├─ Lesson 02: Set Theory Practice (20 min)
│  └─ Hands-on exercises with basic set concepts
│
├─ Lesson 03: Set Operators Overview (15 min)
│  └─ UNION, INTERSECT, EXCEPT introduction
│
├─ Lesson 04: UNION Operator (25 min)
│  └─ UNION vs UNION ALL, combining results, duplicates
│
├─ Lesson 05: INTERSECT Operator (20 min)
│  └─ Finding common records, matching criteria
│
├─ Lesson 06: EXCEPT Operator (20 min)
│  └─ Finding differences, data comparison
│
├─ Lesson 07: Set Operation Rules (20 min)
│  └─ Column compatibility, data type matching, constraints
│
├─ Lesson 08: Sorting Compound Results (15 min)
│  └─ ORDER BY with set operations, sorting strategies
│
├─ Lesson 09: Set Operation Precedence (20 min)
│  └─ Multiple operations, parentheses, execution order
│
└─ Lesson 10: Test Your Knowledge (60 min)
   └─ Comprehensive exercises and real-world scenarios

Total Time: ~3.5 hours
```

---

## Visual Learning Path

```
START → Set Theory → Practice → Operators → UNION → INTERSECT → EXCEPT → Rules → Sorting → Precedence → TEST → COMPLETE
  ↓         ↓          ↓          ↓         ↓         ↓          ↓        ↓         ↓           ↓        ↓        ↓
 Math    Exercises  Overview  Combine   Common   Differences  Rules   ORDER BY  Multiple    Practice  Master   NEXT
Basics   Concepts   U/I/E      Data     Records     Find              Sorting   Operations  Problems  Sets   Chapter
```

---

## Set Operations Venn Diagrams

```
┌────────────────────────────────────────────────────────────┐
│              SQL Set Operations Visualization              │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  UNION (All records from both sets, no duplicates)         │
│  ┌─────────────────────────────────────────┐              │
│  │    Set A          Set B                 │              │
│  │    ╭─────╮     ╭─────╮                 │              │
│  │    │█████│█████│█████│                 │              │
│  │    │█████│█████│█████│                 │              │
│  │    ╰─────╯█████╰─────╯                 │              │
│  │           █████                          │              │
│  └─────────────────────────────────────────┘              │
│                                                             │
│  UNION ALL (All records, duplicates kept)                  │
│  ┌─────────────────────────────────────────┐              │
│  │    Set A + Set B (overlaps duplicated)  │              │
│  │    ╭─────╮     ╭─────╮                 │              │
│  │    │█████│█████│█████│                 │              │
│  │    │█████│████ │█████│  ← Overlap      │              │
│  │    ╰─────╯████ ╰─────╯    counted twice│              │
│  │           ████                           │              │
│  └─────────────────────────────────────────┘              │
│                                                             │
│  INTERSECT (Only records in BOTH sets)                     │
│  ┌─────────────────────────────────────────┐              │
│  │    Set A          Set B                 │              │
│  │    ╭─────╮     ╭─────╮                 │              │
│  │    │     │████ │     │                 │              │
│  │    │     │████ │     │  ← Only overlap │              │
│  │    ╰─────╯████ ╰─────╯                 │              │
│  │           ████                           │              │
│  └─────────────────────────────────────────┘              │
│                                                             │
│  EXCEPT (Records in Set A but NOT in Set B)                │
│  ┌─────────────────────────────────────────┐              │
│  │    Set A          Set B                 │              │
│  │    ╭─────╮     ╭─────╮                 │              │
│  │    │█████│     │     │                 │              │
│  │    │█████│     │     │  ← Only left    │              │
│  │    ╰─────╯     ╰─────╯    side         │              │
│  │                                          │              │
│  └─────────────────────────────────────────┘              │
└────────────────────────────────────────────────────────────┘
```

---

## Database Schema

This chapter uses the **RetailStore** database:

```
RetailStore Database:
├─ Products (10 rows)
│  ├─ ProductID (PK)
│  ├─ ProductName
│  ├─ CategoryID (FK)
│  └─ Price
│
├─ Categories (3 rows)
│  ├─ CategoryID (PK)
│  └─ CategoryName
│
├─ Customers (8 rows)
│  ├─ CustomerID (PK)
│  ├─ FirstName
│  ├─ LastName
│  └─ Email
│
├─ Orders (12 rows)
│  ├─ OrderID (PK)
│  ├─ CustomerID (FK)
│  ├─ OrderDate
│  └─ TotalAmount
│
└─ OrderDetails (25 rows)
   ├─ OrderDetailID (PK)
   ├─ OrderID (FK)
   ├─ ProductID (FK)
   └─ Quantity
```

---

## Key Concepts

### Set Operations Comparison

```
┌─────────────┬──────────────────────┬──────────────────────┬─────────────┐
│  Operation  │      Description     │    Venn Diagram      │  Duplicates │
├─────────────┼──────────────────────┼──────────────────────┼─────────────┤
│ UNION       │ All from A or B      │ ███████████          │  Removed    │
│             │ (no duplicates)      │                      │             │
├─────────────┼──────────────────────┼──────────────────────┼─────────────┤
│ UNION ALL   │ All from A and B     │ ███████████          │  Kept       │
│             │ (keep duplicates)    │ (overlap counted 2x) │             │
├─────────────┼──────────────────────┼──────────────────────┼─────────────┤
│ INTERSECT   │ Only in both A & B   │     ████             │  Removed    │
│             │ (overlap)            │   (overlap only)     │             │
├─────────────┼──────────────────────┼──────────────────────┼─────────────┤
│ EXCEPT      │ In A but not in B    │ ████                 │  Removed    │
│             │ (left only)          │ (left side only)     │             │
└─────────────┴──────────────────────┴──────────────────────┴─────────────┘
```

### Set Operation Rules

```
✅ Required Conditions:
  1. Same number of columns in both queries
  2. Compatible data types (column by column)
  3. Column order must match
  4. Column names come from first query

❌ Not Required:
  • Same table names
  • Same column names
  • Same table structure
```

---

## Common Use Cases

```
UNION:
├─ Combine data from multiple sources
├─ Merge historical and current data
├─ Consolidate regional databases
└─ Create master lists

UNION ALL:
├─ Performance (faster than UNION)
├─ Keep all records including duplicates
├─ Audit trails
└─ Data migrations

INTERSECT:
├─ Find common customers
├─ Match records between systems
├─ Data validation
└─ Overlap analysis

EXCEPT:
├─ Find missing records
├─ Data discrepancies
├─ Orphaned records
└─ What changed between datasets
```

---

## Real-World Examples

### Example 1: Customer Consolidation

```sql
-- Merge customers from two regions (remove duplicates)
SELECT CustomerID, FirstName, LastName, Email
FROM CustomersEast
UNION
SELECT CustomerID, FirstName, LastName, Email
FROM CustomersWest;
```

### Example 2: Find Active Customers

```sql
-- Customers who ordered in 2024 AND 2025
SELECT DISTINCT CustomerID FROM Orders WHERE YEAR(OrderDate) = 2024
INTERSECT
SELECT DISTINCT CustomerID FROM Orders WHERE YEAR(OrderDate) = 2025;
```

### Example 3: Find Inactive Products

```sql
-- Products in catalog but never ordered
SELECT ProductID FROM Products
EXCEPT
SELECT DISTINCT ProductID FROM OrderDetails;
```

---

## Performance Considerations

```
┌────────────────────────────────────────────────────────┐
│           Set Operations Performance                   │
├────────────────────────────────────────────────────────┤
│                                                         │
│  UNION vs UNION ALL:                                   │
│  ├─ UNION ALL: Faster (no duplicate removal)          │
│  └─ UNION: Slower (sorts and removes duplicates)      │
│                                                         │
│  Tips:                                                  │
│  ├─ Use UNION ALL when duplicates don't matter        │
│  ├─ Filter BEFORE set operation (WHERE in each query)  │
│  ├─ Index columns used in sorting/comparison           │
│  └─ Consider temp tables for very large sets          │
│                                                         │
│  Speed Ranking (Fastest to Slowest):                   │
│  1. UNION ALL                                          │
│  2. EXCEPT                                             │
│  3. INTERSECT                                          │
│  4. UNION                                              │
└────────────────────────────────────────────────────────┘
```

---

## Common Mistakes to Avoid

```
❌ Mistake #1: Column Count Mismatch
SELECT Name, Email FROM Customers
UNION
SELECT ProductName FROM Products;  -- ERROR: 2 columns vs 1 column

✅ Fix: Match column counts
SELECT Name, Email FROM Customers
UNION
SELECT ProductName, NULL AS Email FROM Products;

❌ Mistake #2: Data Type Mismatch
SELECT CustomerID FROM Customers  -- INT
UNION
SELECT Email FROM Customers;  -- VARCHAR (ERROR)

✅ Fix: Use compatible types
SELECT CAST(CustomerID AS VARCHAR(50)) FROM Customers
UNION
SELECT Email FROM Customers;

❌ Mistake #3: ORDER BY in Wrong Place
SELECT Name FROM Customers ORDER BY Name  -- ERROR
UNION
SELECT Name FROM Suppliers;

✅ Fix: ORDER BY at end
SELECT Name FROM Customers
UNION
SELECT Name FROM Suppliers
ORDER BY Name;

❌ Mistake #4: Using UNION When UNION ALL Is Better
-- If you know there are no duplicates, use UNION ALL
SELECT * FROM January2025Orders
UNION  -- Slower, unnecessary duplicate check
SELECT * FROM February2025Orders;

✅ Fix: Use UNION ALL for better performance
SELECT * FROM January2025Orders
UNION ALL  -- Faster
SELECT * FROM February2025Orders;
```

---

## Quick Reference

### Basic Syntax

```sql
-- UNION (removes duplicates)
SELECT columns FROM table1
UNION
SELECT columns FROM table2;

-- UNION ALL (keeps duplicates)
SELECT columns FROM table1
UNION ALL
SELECT columns FROM table2;

-- INTERSECT (common records)
SELECT columns FROM table1
INTERSECT
SELECT columns FROM table2;

-- EXCEPT (in first, not in second)
SELECT columns FROM table1
EXCEPT
SELECT columns FROM table2;

-- Multiple operations with ORDER BY
SELECT columns FROM table1
UNION
SELECT columns FROM table2
INTERSECT
SELECT columns FROM table3
ORDER BY column1;  -- At the end only
```

---

## Practice Strategy

```
1. Start with Lesson 01: Understand set theory basics
2. Practice with Lesson 02: Hands-on exercises
3. Learn operators: UNION → INTERSECT → EXCEPT
4. Master rules: Column count, data types, ordering
5. Practice sorting and precedence
6. Complete Test Your Knowledge (Lesson 10)

Key Focus Areas:
├─ Column compatibility
├─ Duplicate handling
├─ Performance (UNION vs UNION ALL)
└─ Real-world applications
```

---

## Prerequisites

Before starting this chapter, you should understand:

- ✅ Basic SELECT statements (Chapter 03)
- ✅ Filtering with WHERE (Chapter 04)
- ✅ Joining tables (Chapter 05)
- ✅ Aggregate functions (covered in future chapters)

---

## What's Next?

After completing this chapter, you'll be ready for:

- **Chapter 07:** Data Generation and Manipulation
- **Chapter 08:** Grouping and Aggregates
- **Chapter 09:** Subqueries

---

## Tips for Success

```
✅ DO:
  • Draw Venn diagrams to visualize operations
  • Test queries with COUNT(*) first
  • Use UNION ALL when possible (faster)
  • Match column counts and types carefully
  • Practice with small datasets first

❌ DON'T:
  • Forget column count must match
  • Ignore data type compatibility
  • Put ORDER BY in individual queries
  • Use UNION when UNION ALL works
  • Skip the practice exercises
```

---

**Ready to begin? Start with [Lesson 01: Set Theory Primer](01-set-theory-primer/01-set-theory-primer.sql)**

---

*Last Updated: November 2025*
*Chapter Difficulty: ⭐⭐⭐ (Intermediate)*
*Estimated Completion Time: 3.5 hours*
