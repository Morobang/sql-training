# Chapter 09: Subqueries

## Overview
Master the art of writing queries within queries to create powerful, flexible SQL statements that solve complex data retrieval problems.

**Estimated Time:** 6-7 hours  
**Difficulty:** Intermediate  
**Prerequisites:** Chapters 02-08 (especially filtering and grouping)

## What You'll Learn

### Core Concepts
- What subqueries are and when to use them
- Different types of subqueries
- Noncorrelated vs correlated subqueries
- Single-row vs multiple-row subqueries
- Subqueries in different clause positions

### Practical Skills
- Writing subqueries in WHERE, SELECT, FROM, and HAVING clauses
- Using IN, NOT IN, EXISTS, NOT EXISTS operators
- Creating derived tables and inline views
- Optimizing subquery performance
- Choosing between subqueries and joins

## Chapter Structure

| Lesson | Topic | Time | Key Concepts |
|--------|-------|------|--------------|
| 09.01 | What is a Subquery? | 20 min | Definition, basic examples, nested queries |
| 09.02 | Subquery Types | 25 min | Scalar, row, table subqueries |
| 09.03 | Noncorrelated Subqueries | 30 min | Independent subqueries, execution order |
| 09.04 | Multiple-Row Subqueries | 30 min | IN, NOT IN, ALL, ANY operators |
| 09.05 | Multicolumn Subqueries | 25 min | Tuple comparisons, multiple conditions |
| 09.06 | Correlated Subqueries | 35 min | Row-by-row execution, dependency |
| 09.07 | EXISTS Operator | 30 min | Existence checks, NOT EXISTS |
| 09.08 | Data Manipulation Subqueries | 30 min | INSERT, UPDATE, DELETE with subqueries |
| 09.09 | When to Use Subqueries | 25 min | Subqueries vs joins, performance |
| 09.10 | Subqueries as Data Sources | 30 min | Derived tables, inline views, WITH clause |
| 09.11 | Expression Generators | 25 min | Subqueries in SELECT, calculated columns |
| 09.12 | Subquery Wrap-Up | 20 min | Best practices, common patterns |
| 09.13 | Test Your Knowledge | 90 min | Comprehensive assessment |

## Learning Objectives

By the end of this chapter, you will be able to:

✅ **Understand Subquery Fundamentals**
- Define what a subquery is
- Identify when to use subqueries
- Understand execution order

✅ **Write Different Subquery Types**
- Scalar subqueries (return single value)
- Row subqueries (return single row)
- Table subqueries (return multiple rows/columns)

✅ **Master Noncorrelated Subqueries**
- Write independent subqueries
- Use subqueries in WHERE clause
- Filter with IN, NOT IN

✅ **Use Correlated Subqueries**
- Write row-dependent subqueries
- Understand performance implications
- Use EXISTS and NOT EXISTS

✅ **Apply Subqueries Everywhere**
- SELECT clause (calculated columns)
- FROM clause (derived tables)
- WHERE clause (filtering)
- HAVING clause (group filtering)
- INSERT, UPDATE, DELETE statements

## Key Concepts

### What is a Subquery?
```sql
-- Outer query
SELECT ProductName, Price
FROM Products
WHERE Price > (
    -- Inner query (subquery)
    SELECT AVG(Price)
    FROM Products
)
ORDER BY Price;
```

A **subquery** is a query nested inside another query. The inner query executes first, and its result is used by the outer query.

### Subquery Types

#### 1. **Scalar Subquery** (Returns single value)
```sql
SELECT ProductName, 
       Price - (SELECT AVG(Price) FROM Products) AS PriceDifference
FROM Products;
```

#### 2. **Row Subquery** (Returns single row, multiple columns)
```sql
SELECT * FROM Products
WHERE (Price, Stock) = (
    SELECT MAX(Price), MIN(Stock)
    FROM Products
);
```

#### 3. **Table Subquery** (Returns multiple rows)
```sql
SELECT ProductName FROM Products
WHERE CategoryID IN (
    SELECT CategoryID FROM Categories
    WHERE CategoryName LIKE '%Electronics%'
);
```

### Noncorrelated vs Correlated

#### **Noncorrelated** (Independent)
```sql
-- Subquery runs ONCE
SELECT ProductName, Price
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID FROM Categories
    WHERE CategoryName = 'Electronics'
);
```

**Execution:**
1. Inner query runs once: Gets CategoryID for Electronics
2. Outer query uses result: Filters products

#### **Correlated** (Dependent)
```sql
-- Subquery runs for EACH row
SELECT p1.ProductName, p1.Price
FROM Products p1
WHERE p1.Price > (
    SELECT AVG(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID  -- References outer query!
);
```

**Execution:**
1. For each product in p1
2. Subquery calculates average for that category
3. Compare product price to category average

### Common Operators with Subqueries

| Operator | Use Case | Example |
|----------|----------|---------|
| `=` | Single value comparison | `WHERE Price = (SELECT MAX(Price)...)` |
| `>`, `<`, `>=`, `<=` | Value comparison | `WHERE Price > (SELECT AVG(Price)...)` |
| `IN` | Multiple values | `WHERE CategoryID IN (SELECT...)` |
| `NOT IN` | Exclusion | `WHERE CustomerID NOT IN (SELECT...)` |
| `EXISTS` | Existence check | `WHERE EXISTS (SELECT 1...)` |
| `NOT EXISTS` | Non-existence | `WHERE NOT EXISTS (SELECT 1...)` |
| `ALL` | Compare to all values | `WHERE Price > ALL (SELECT...)` |
| `ANY` / `SOME` | Compare to any value | `WHERE Price > ANY (SELECT...)` |

## Real-World Use Cases

### 1. **Finding Above-Average Items**
```sql
-- Products priced above category average
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
);
```

### 2. **Customers Who Never Ordered**
```sql
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
```

### 3. **Top N per Group**
```sql
SELECT *
FROM (
    SELECT 
        ProductName,
        CategoryID,
        Price,
        ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS Rank
    FROM Products
) RankedProducts
WHERE Rank <= 3;
```

### 4. **Dynamic Filtering**
```sql
-- Orders above today's average
SELECT OrderID, TotalAmount
FROM Orders
WHERE TotalAmount > (
    SELECT AVG(TotalAmount)
    FROM Orders
    WHERE CAST(OrderDate AS DATE) = CAST(GETDATE() AS DATE)
);
```

## Subqueries vs Joins

### When to Use Subqueries
✅ Need to filter by aggregate (AVG, MAX, COUNT)  
✅ Checking existence/non-existence  
✅ Single value needed from another table  
✅ Code readability (sometimes clearer)  
✅ Derived tables for complex logic  

### When to Use Joins
✅ Need columns from multiple tables  
✅ Better performance (usually)  
✅ Multiple related tables  
✅ Set operations needed  

### Example Comparison
```sql
-- Using Subquery (filter only)
SELECT ProductName
FROM Products
WHERE CategoryID = (
    SELECT CategoryID FROM Categories
    WHERE CategoryName = 'Electronics'
);

-- Using Join (need category name too)
SELECT p.ProductName, c.CategoryName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';
```

## Performance Considerations

### ⚡ Fast Subqueries
```sql
-- Noncorrelated (runs once)
WHERE CategoryID IN (SELECT CategoryID FROM TopCategories)

-- EXISTS with early termination
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)
```

### 🐌 Slow Subqueries
```sql
-- Correlated in SELECT (runs for every row)
SELECT (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID)

-- NOT IN with NULL values (can cause issues)
WHERE ProductID NOT IN (SELECT ProductID FROM DiscontinuedProducts)
```

### Optimization Tips
1. **Use EXISTS instead of IN** when checking existence
2. **Avoid correlated subqueries in SELECT** clause when possible
3. **Index columns** used in subquery joins/filters
4. **Use CTEs** for complex subqueries (better readability)
5. **Test with EXPLAIN/EXECUTION PLAN** to check performance

## Common Patterns

### Pattern 1: Above Average
```sql
SELECT * FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);
```

### Pattern 2: Not In List
```sql
SELECT * FROM Customers
WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM Orders);
```

### Pattern 3: Exists Check
```sql
SELECT * FROM Products p
WHERE EXISTS (
    SELECT 1 FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);
```

### Pattern 4: Derived Table
```sql
SELECT CategoryName, AvgPrice
FROM (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
) CategoryAverages
JOIN Categories c ON CategoryAverages.CategoryID = c.CategoryID;
```

### Pattern 5: Scalar in SELECT
```sql
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS OverallAvg,
    Price - (SELECT AVG(Price) FROM Products) AS Difference
FROM Products;
```

## Common Mistakes to Avoid

### ❌ Mistake 1: Returning Multiple Values When Expecting One
```sql
-- ERROR if subquery returns multiple rows
SELECT * FROM Products
WHERE Price = (SELECT Price FROM Products WHERE Stock > 0);
```
✅ **Fix:** Use IN or add TOP 1
```sql
WHERE Price IN (SELECT Price FROM Products WHERE Stock > 0)
```

### ❌ Mistake 2: NOT IN with NULL
```sql
-- Returns no rows if subquery has NULL!
WHERE ProductID NOT IN (SELECT ProductID FROM Table WHERE ...)
```
✅ **Fix:** Use NOT EXISTS or filter NULL
```sql
WHERE NOT EXISTS (SELECT 1 FROM Table WHERE ProductID = p.ProductID)
-- OR
WHERE ProductID NOT IN (SELECT ProductID FROM Table WHERE ProductID IS NOT NULL)
```

### ❌ Mistake 3: Correlated Subquery in SELECT for Large Tables
```sql
-- Slow! Runs for every row
SELECT 
    CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;
```
✅ **Fix:** Use JOIN or window function
```sql
SELECT c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;
```

## Study Tips

1. **Start Simple:** Master noncorrelated subqueries first
2. **Practice Execution Order:** Understand what runs when
3. **Use Comments:** Label your subqueries for clarity
4. **Test Performance:** Compare subqueries vs joins
5. **Learn CTEs:** Common Table Expressions (WITH clause) are cleaner
6. **Visualize:** Draw execution flow for correlated subqueries
7. **Check for NULLs:** Always consider NULL behavior

## Prerequisites Check

Before starting this chapter, ensure you understand:
- ✅ Basic SELECT statements (Chapter 03)
- ✅ WHERE clause filtering (Chapter 04)
- ✅ Joins (Chapter 05)
- ✅ Aggregate functions (Chapter 08)
- ✅ GROUP BY and HAVING (Chapter 08)

## What's Next?

After mastering subqueries, you'll learn:
- **Chapter 10:** Joins Revisited - Advanced join techniques
- **Chapter 11:** Conditional Logic - CASE expressions and IIF
- **Chapter 12:** Transactions - Data integrity and ACID

## Additional Resources

### Practice Datasets
- RetailStore database (used in examples)
- Sakila sample database
- AdventureWorks database

### Tools
- SQL Server Management Studio (SSMS)
- Azure Data Studio
- DBeaver (cross-platform)

### Further Reading
- SQL Performance Explained (Markus Winand)
- Microsoft SQL Server documentation
- Execution plan analysis guides

---

## Quick Reference Card

### Subquery Positions
```sql
-- WHERE clause (filtering)
SELECT * FROM Products WHERE Price > (SELECT AVG(Price) FROM Products);

-- SELECT clause (calculated column)
SELECT ProductName, (SELECT COUNT(*) FROM Orders) AS TotalOrders FROM Products;

-- FROM clause (derived table)
SELECT * FROM (SELECT * FROM Products WHERE Stock > 0) InStockProducts;

-- HAVING clause (group filter)
SELECT CategoryID, COUNT(*) FROM Products GROUP BY CategoryID
HAVING COUNT(*) > (SELECT AVG(ProductCount) FROM CategoryStats);

-- INSERT statement
INSERT INTO Archive SELECT * FROM Products WHERE Discontinued = 1;

-- UPDATE statement
UPDATE Products SET Price = Price * 1.1
WHERE CategoryID IN (SELECT CategoryID FROM Categories WHERE Premium = 1);

-- DELETE statement
DELETE FROM Products WHERE ProductID IN (SELECT ProductID FROM Discontinued);
```

### Key Operators
- `IN` / `NOT IN` - Multiple value matching
- `EXISTS` / `NOT EXISTS` - Existence checking
- `ANY` / `SOME` - At least one match
- `ALL` - All values match
- `=`, `>`, `<`, `>=`, `<=`, `<>` - Single value comparison

---

**Ready to dive deep into subqueries? Let's start with Lesson 09.01!** 🚀
