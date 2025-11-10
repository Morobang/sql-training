# Lesson 2: SQL Joins - Basics

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson, you will be able to:
1. Understand what joins are and why they're essential
2. Write INNER JOIN queries to combine data from multiple tables
3. Use table aliases effectively
4. Join three or more tables in a single query
5. Understand foreign key relationships
6. Write proper join conditions with the ON clause
7. Avoid common join mistakes

## Prerequisites

✅ Completed Beginner Level  
✅ Understanding of primary and foreign keys  
✅ Basic SELECT query skills

---

## Part 1: Why Joins Matter

### The Problem: Data is Split Across Tables

**Normalized Database:**
```
Products Table:
ProductID | ProductName | CategoryID | Price
----------|-------------|------------|-------
1         | Laptop      | 1          | 999
2         | Mouse       | 1          | 25
3         | Novel       | 2          | 15

Categories Table:
CategoryID | CategoryName
-----------|-------------
1          | Electronics
2          | Books
3          | Clothing
```

**The Question:**  
*"Show me product names WITH their category names"*

**The Solution:**  
**JOIN the tables!**

---

## Part 2: Understanding Foreign Keys

### Primary Key → Foreign Key Relationship

```
Categories Table:
┌────────────┬──────────────┐
│ CategoryID │ CategoryName │ ← Primary Key (unique identifier)
├────────────┼──────────────┤
│ 1          │ Electronics  │
│ 2          │ Books        │
└────────────┴──────────────┘
         ↑
         │ (referenced by)
         │
Products Table:
┌───────────┬─────────────┬────────────┐
│ ProductID │ ProductName │ CategoryID │ ← Foreign Key (references Categories)
├───────────┼─────────────┼────────────┤
│ 1         │ Laptop      │ 1          │ → Points to Electronics
│ 2         │ Mouse       │ 1          │ → Points to Electronics
│ 3         │ Novel       │ 2          │ → Points to Books
└───────────┴─────────────┴────────────┘
```

**Key Concept:**
```
Products.CategoryID = Foreign Key
Categories.CategoryID = Primary Key

Foreign Key → Primary Key = Relationship!
```

---

## Part 3: Your First INNER JOIN

### Basic Syntax

```sql
SELECT columns
FROM table1
INNER JOIN table2 ON table1.column = table2.column;
```

### Real Example

```sql
-- Join Products and Categories
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

**Result:**
```
ProductID | ProductName | CategoryName | Price
----------|-------------|--------------|-------
1         | Laptop      | Electronics  | 999
2         | Mouse       | Electronics  | 25
3         | Novel       | Books        | 15
```

### Breaking It Down

```sql
FROM Products p                      -- 1. Start with Products table (alias 'p')
INNER JOIN Categories c              -- 2. Join to Categories table (alias 'c')
ON p.CategoryID = c.CategoryID;      -- 3. Match where CategoryID equals
```

**What INNER JOIN does:**
```
Only returns rows WHERE the join condition matches!

Product CategoryID=1 → Matches Category CategoryID=1 ✅
Product CategoryID=2 → Matches Category CategoryID=2 ✅
Product CategoryID=99 → No Category 99 ❌ (excluded from results)
```

---

## Part 4: Table Aliases

### Why Use Aliases?

**Without aliases - VERBOSE:**
```sql
SELECT 
    Products.ProductID,
    Products.ProductName,
    Categories.CategoryName
FROM Products
INNER JOIN Categories ON Products.CategoryID = Categories.CategoryID;
```

**With aliases - CLEAN:**
```sql
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Alias Rules

```sql
-- Single letter (common for simple queries)
FROM Products p
FROM Customers c

-- Descriptive (better for complex queries)
FROM Products prod
FROM Customers cust

-- Multiple words (use for clarity)
FROM CustomerOrders custOrders
```

**Best Practice:**
```
✓ Short aliases (1-4 chars) for simple queries
✓ Descriptive aliases for complex queries
✓ Consistent naming (all short OR all descriptive)
✗ Don't mix styles randomly
```

---

## Part 5: INNER JOIN Visualized

### Venn Diagram

```
     Table A          Table B
   ┌─────────┐      ┌─────────┐
   │         │      │         │
   │    ┌────┼──────┼────┐    │
   │    │ INNER JOIN     │    │
   │    │  (Shaded)      │    │
   │    └────┼──────┼────┘    │
   │         │      │         │
   └─────────┘      └─────────┘
```

**INNER JOIN = Only the overlap (matching rows)**

### Data Flow Example

```
Products:                    Categories:
ProductID | CategoryID       CategoryID | CategoryName
----------|----------        -----------|--------------
1         | 1                1          | Electronics
2         | 1                2          | Books
3         | 2                3          | Clothing
4         | NULL             

INNER JOIN ON p.CategoryID = c.CategoryID

Result (only matches):
ProductID | CategoryID | CategoryName
----------|------------|---------------
1         | 1          | Electronics     ← Match!
2         | 1          | Electronics     ← Match!
3         | 2          | Books           ← Match!
4         | NULL       | (excluded)      ← No match (NULL)

Product 4 excluded (NULL doesn't match anything)
Category 3 not shown (no products in Clothing)
```

---

## Part 6: Multiple Columns in SELECT

### Specify Table/Alias for Each Column

```sql
-- ✅ GOOD: Clear which table each column comes from
SELECT 
    p.ProductID,        -- From Products
    p.ProductName,      -- From Products
    c.CategoryName,     -- From Categories
    p.Price             -- From Products
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### When Column Names are Ambiguous

```sql
-- ❌ ERROR: CategoryID exists in both tables!
SELECT 
    ProductID,
    ProductName,
    CategoryID,         -- Which one? Products.CategoryID or Categories.CategoryID?
    CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- ✅ CORRECT: Specify the table
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID AS ProductCategoryID,      -- From Products
    c.CategoryID AS CategoryCategoryID,     -- From Categories
    c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

---

## Part 7: Filtering with WHERE

### WHERE After JOIN

```sql
-- Get Electronics products only
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';
```

**Execution Order:**
```
1. FROM Products p                     -- Get Products table
2. INNER JOIN Categories c ON ...      -- Join Categories
3. WHERE c.CategoryName = 'Electronics' -- Filter results
4. SELECT columns                      -- Choose columns to show
```

### Multiple Filters

```sql
-- Electronics products over $100
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics'
  AND p.Price > 100
  AND p.StockQuantity > 0;
```

---

## Part 8: Joining Three Tables

### The Scenario

```
Customers → Orders → OrderDetails
    ↓           ↓          ↓
(who)       (when)     (what)
```

**Tables:**
```
Customers:                Orders:                   OrderDetails:
CustomerID | Name        OrderID | CustomerID      OrderDetailID | OrderID | ProductID
-----------|------       --------|------------     --------------|---------|----------
1          | John        1       | 1               1             | 1       | 101
2          | Jane        2       | 1               2             | 1       | 102
                         3       | 2               3             | 2       | 103
```

### Three-Table JOIN

```sql
-- Show: Customer name, Order date, Product details
SELECT 
    c.CustomerName,
    o.OrderDate,
    od.ProductID,
    od.Quantity
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;
```

**How it works:**
```
1. Start with Customers
2. Join Orders (match CustomerID)
3. Join OrderDetails (match OrderID)
4. Return combined result
```

**Visualization:**
```
Customers (c)
    │
    ├── JOIN Orders (o) ON c.CustomerID = o.CustomerID
    │       │
    │       └── JOIN OrderDetails (od) ON o.OrderID = od.OrderID
    │
Result: All three tables combined
```

---

## Part 9: Joining Four Tables

### Extended Example

```sql
-- Customer → Orders → OrderDetails → Products
SELECT 
    c.CustomerName,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderDate >= '2024-01-01'
ORDER BY c.CustomerName, o.OrderDate;
```

**Chain of Relationships:**
```
Customers.CustomerID → Orders.CustomerID
Orders.OrderID → OrderDetails.OrderID
OrderDetails.ProductID → Products.ProductID
```

---

## Part 10: Real-World Examples

### Example 1: E-Commerce Product Catalog

```sql
-- Show products with category and supplier info
SELECT 
    p.ProductName,
    c.CategoryName,
    s.SupplierName,
    p.Price,
    p.StockQuantity
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.IsActive = 1
ORDER BY c.CategoryName, p.ProductName;
```

### Example 2: Customer Order History

```sql
-- Customer purchase summary
SELECT 
    c.CustomerName,
    c.Email,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.CustomerName, c.Email
HAVING SUM(o.TotalAmount) > 1000
ORDER BY TotalSpent DESC;
```

### Example 3: Inventory Report

```sql
-- Products, categories, suppliers with stock alerts
SELECT 
    c.CategoryName,
    p.ProductName,
    s.SupplierName,
    s.ContactPhone,
    p.StockQuantity,
    p.ReorderLevel,
    CASE 
        WHEN p.StockQuantity = 0 THEN 'OUT OF STOCK'
        WHEN p.StockQuantity < p.ReorderLevel THEN 'LOW STOCK'
        ELSE 'OK'
    END AS StockStatus
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity < p.ReorderLevel
ORDER BY c.CategoryName, StockStatus;
```

---

## Part 11: Common Mistakes

### Mistake 1: Forgetting ON Clause

```sql
-- ❌ ERROR: Missing ON clause
SELECT *
FROM Products p
INNER JOIN Categories c;

-- ✅ CORRECT: Always include ON
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Mistake 2: Wrong Join Condition

```sql
-- ❌ WRONG: Joining on unrelated columns
SELECT *
FROM Products p
INNER JOIN Categories c ON p.ProductID = c.CategoryID;

-- ✅ CORRECT: Join on foreign key → primary key
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Mistake 3: Ambiguous Column Names

```sql
-- ❌ ERROR: CategoryID exists in both tables
SELECT CategoryID, ProductName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- ✅ CORRECT: Specify which table
SELECT p.CategoryID, p.ProductName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

### Mistake 4: Cartesian Product (Accidental)

```sql
-- ❌ DISASTER: Creates every possible combination!
SELECT *
FROM Products, Categories;  -- Old style, no join condition
-- 100 products × 10 categories = 1000 rows!

-- ✅ CORRECT: Use proper join with ON
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

---

## Part 12: Best Practices

### Format for Readability

```sql
-- ✅ GOOD: Each join on its own line, indented
SELECT 
    c.CustomerName,
    o.OrderDate,
    p.ProductName
FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderDate >= '2024-01-01';

-- ❌ BAD: Everything on one line
SELECT c.CustomerName, o.OrderDate FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
```

### Use Meaningful Aliases

```sql
-- ✅ GOOD: Descriptive aliases for complex queries
FROM Customers cust
INNER JOIN Orders ord ON cust.CustomerID = ord.CustomerID
INNER JOIN OrderDetails detail ON ord.OrderID = detail.OrderID;

-- ⚠️ OK: Short aliases for simple queries
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- ❌ CONFUSING: Random letters
FROM Customers a
INNER JOIN Orders b ON a.CustomerID = b.CustomerID;
```

### Select Specific Columns

```sql
-- ✅ GOOD: Explicit column list
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- ❌ BAD: SELECT * in production
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;
```

---

## Practice Exercises

### Exercise 1: Basic Join
```sql
-- Join Products and Suppliers
-- Show: ProductName, SupplierName, Price
-- Filter: Products over $100
-- Order: By ProductName

-- Write your solution:
```

### Exercise 2: Three-Table Join
```sql
-- Join Orders, Customers, and OrderDetails
-- Show: CustomerName, OrderDate, ProductID, Quantity
-- Filter: Orders from last 30 days
-- Order: By CustomerName, then OrderDate

-- Write your solution:
```

### Exercise 3: Four-Table Join with Aggregation
```sql
-- Join Customers, Orders, OrderDetails, Products
-- Show: CustomerName, ProductName, TotalQuantityOrdered
-- Group by: Customer and Product
-- Having: Total quantity > 10
-- Order: By CustomerName

-- Write your solution:
```

---

## Key Takeaways

### INNER JOIN Basics
```
INNER JOIN = Only matching rows from both tables
Foreign Key → Primary Key = Join condition
Use ON clause to specify how tables relate
Only returns rows WHERE join condition is TRUE
```

### Syntax Template
```sql
SELECT columns
FROM table1 alias1
INNER JOIN table2 alias2 ON alias1.fk = alias2.pk
INNER JOIN table3 alias3 ON alias2.fk = alias3.pk
WHERE filter_conditions
ORDER BY columns;
```

### Table Aliases
```
Why: Shorter, clearer queries
How: FROM TableName alias
Use: alias.ColumnName in SELECT/WHERE/ORDER BY
```

### Best Practices
```
✓ Always use ON clause with JOIN
✓ Use table aliases for readability
✓ Specify table/alias for all columns
✓ Join on indexed columns (usually foreign keys)
✓ Format: one join per line
✓ Use INNER JOIN (not old comma syntax)
✗ Don't forget ON clause
✗ Don't use SELECT * in production
✗ Don't join unrelated columns
```

---

## Quick Reference

```sql
-- Basic 2-table join
SELECT p.ProductName, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- 3-table join
SELECT c.CustomerName, o.OrderDate, p.ProductName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;

-- With WHERE filter
SELECT p.ProductName, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;

-- With aggregation
SELECT c.CategoryName, COUNT(*) AS ProductCount
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;
```

---

## Next Lesson

**Continue to [Lesson 3: SQL Joins - Advanced](../03-sql-joins-advanced/sql-joins-advanced.md)**  
Learn about LEFT, RIGHT, FULL OUTER, CROSS, and SELF joins.

---

## Additional Resources

- **INNER JOIN:** https://docs.microsoft.com/sql/t-sql/queries/from-inner-join
- **Join Fundamentals:** https://docs.microsoft.com/sql/relational-databases/performance/joins
- **Table Aliases:** https://docs.microsoft.com/sql/t-sql/queries/from

**Great work! You've mastered INNER JOIN - the most common join type! 🔗**
