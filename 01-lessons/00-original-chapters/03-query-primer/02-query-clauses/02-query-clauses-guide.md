# 📋 Lesson 02: Query Clauses - The Complete SELECT Statement

## 📋 Overview

**Estimated Time:** 10 minutes  
**Difficulty:** Beginner  
**Prerequisites:** Lesson 01 completed  

**What You'll Learn:**
- All 6 main SQL clauses
- When to use each clause
- How clauses work together
- Query execution order

---

## 🎯 The Complete SELECT Statement

A full SELECT statement can have up to **6 main clauses**:

```sql
SELECT column1, column2          -- 1. What columns to show
FROM TableName                   -- 2. Which table(s)
WHERE condition                  -- 3. Filter rows
GROUP BY column                  -- 4. Group rows
HAVING aggregate_condition       -- 5. Filter groups
ORDER BY column;                 -- 6. Sort results
```

**You don't always need all of them!** Use what you need for each query.

---

## 📊 Visual: Query Clause Overview

```
┌──────────────────────────────────────────────────┐
│  SELECT ProductName, AVG(Price) AS AvgPrice      │ ← What to show
├──────────────────────────────────────────────────┤
│  FROM Inventory.Products                         │ ← Source table
├──────────────────────────────────────────────────┤
│  WHERE Price > 50                                │ ← Filter rows
├──────────────────────────────────────────────────┤
│  GROUP BY CategoryID                             │ ← Group for aggregates
├──────────────────────────────────────────────────┤
│  HAVING AVG(Price) > 100                         │ ← Filter groups
├──────────────────────────────────────────────────┤
│  ORDER BY AvgPrice DESC;                         │ ← Sort results
└──────────────────────────────────────────────────┘
```

---

## 1️⃣ SELECT Clause - Choose Columns

**Purpose:** Specify which columns to retrieve

### Basic Syntax:
```sql
SELECT column1, column2, column3
FROM TableName;
```

### Examples:

#### Get All Columns:
```sql
SELECT * FROM Inventory.Products;
```
**Result:**
```
ProductID | ProductName | CategoryID | Price   | StockQuantity | ...
----------|-------------|------------|---------|---------------|----
1         | Laptop      | 1          | 1200.00 | 25            | ...
2         | Mouse       | 1          | 25.99   | 150           | ...
```

#### Get Specific Columns:
```sql
SELECT ProductName, Price
FROM Inventory.Products;
```
**Result:**
```
ProductName | Price
------------|--------
Laptop      | 1200.00
Mouse       | 25.99
Keyboard    | 75.50
```

#### With Calculations:
```sql
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS PriceWithTax
FROM Inventory.Products;
```
**Result:**
```
ProductName | Price   | PriceWithTax
------------|---------|-------------
Laptop      | 1200.00 | 1380.00
Mouse       | 25.99   | 29.89
```

---

## 2️⃣ FROM Clause - Specify Tables

**Purpose:** Define which table(s) to query

### Basic Syntax:
```sql
SELECT columns
FROM SchemaName.TableName;
```

### Examples:

#### Single Table:
```sql
SELECT * FROM Sales.Customers;
```

#### With Table Alias:
```sql
SELECT 
    p.ProductName,
    p.Price
FROM Inventory.Products p;  -- 'p' = alias
```

**Why use aliases?**
- Shorter to type
- Required when joining multiple tables
- Makes queries more readable

#### Multiple Tables (Preview):
```sql
SELECT 
    p.ProductName,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;
```

---

## 3️⃣ WHERE Clause - Filter Rows

**Purpose:** Keep only rows that meet a condition

### Basic Syntax:
```sql
SELECT columns
FROM TableName
WHERE condition;
```

### Examples:

#### Numeric Filter:
```sql
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100;
```
**Result:**
```
ProductName | Price
------------|--------
Laptop      | 1200.00
Monitor     | 350.00
Tablet      | 599.99
```

#### Text Filter:
```sql
SELECT FirstName, LastName, Country
FROM Sales.Customers
WHERE Country = 'USA';
```
**Result:**
```
FirstName | LastName | Country
----------|----------|--------
John      | Doe      | USA
Jane      | Smith    | USA
```

#### Multiple Conditions (AND):
```sql
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE Price > 50 AND StockQuantity > 20;
```

#### Multiple Conditions (OR):
```sql
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 30 OR Price > 1000;
```

### Visual: WHERE Filtering

**Before WHERE:**
```
All Products (8 rows)
┌─────────────┬─────────┐
│ ProductName │ Price   │
├─────────────┼─────────┤
│ Laptop      │ 1200.00 │ ← KEEP (> 100)
│ Mouse       │ 25.99   │ ← Remove
│ Keyboard    │ 75.50   │ ← Remove
│ Monitor     │ 350.00  │ ← KEEP (> 100)
│ Webcam      │ 89.99   │ ← Remove
│ Tablet      │ 599.99  │ ← KEEP (> 100)
│ Headphones  │ 45.00   │ ← Remove
│ Charger     │ 19.99   │ ← Remove
└─────────────┴─────────┘
```

**After WHERE Price > 100:**
```
Filtered Products (3 rows)
┌─────────────┬─────────┐
│ ProductName │ Price   │
├─────────────┼─────────┤
│ Laptop      │ 1200.00 │
│ Monitor     │ 350.00  │
│ Tablet      │ 599.99  │
└─────────────┴─────────┘
```

---

## 4️⃣ GROUP BY Clause - Aggregate Data

**Purpose:** Group rows to calculate aggregates (COUNT, SUM, AVG, etc.)

### Basic Syntax:
```sql
SELECT column, AGGREGATE_FUNCTION(column)
FROM TableName
GROUP BY column;
```

### Common Aggregate Functions:
- `COUNT(*)` - Count rows
- `SUM(column)` - Add values
- `AVG(column)` - Calculate average
- `MIN(column)` - Find minimum
- `MAX(column)` - Find maximum

### Examples:

#### Count Products per Category:
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID;
```
**Result:**
```
CategoryID | ProductCount
-----------|-------------
1          | 5
2          | 2
3          | 1
```

#### Average Price per Category:
```sql
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID;
```
**Result:**
```
CategoryID | AvgPrice
-----------|----------
1          | 358.19
2          | 275.00
3          | 45.00
```

### Visual: GROUP BY in Action

**Raw Data:**
```
CategoryID | ProductName | Price
-----------|-------------|--------
1          | Laptop      | 1200.00
1          | Mouse       | 25.99
1          | Keyboard    | 75.50
2          | Desk        | 350.00
2          | Chair       | 200.00
3          | T-Shirt     | 25.00
```

**After GROUP BY CategoryID:**
```
CategoryID | COUNT(*) | AVG(Price) | SUM(Price)
-----------|----------|------------|------------
1          | 3        | 433.83     | 1301.49
2          | 2        | 275.00     | 550.00
3          | 1        | 25.00      | 25.00
```

---

## 5️⃣ HAVING Clause - Filter Groups

**Purpose:** Filter aggregated results (like WHERE, but for groups)

### Basic Syntax:
```sql
SELECT column, AGGREGATE_FUNCTION(column)
FROM TableName
GROUP BY column
HAVING aggregate_condition;
```

### WHERE vs HAVING:
- **WHERE** filters individual rows BEFORE grouping
- **HAVING** filters groups AFTER aggregation

### Examples:

#### Categories with More Than 2 Products:
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID
HAVING COUNT(*) > 2;
```
**Result:**
```
CategoryID | ProductCount
-----------|-------------
1          | 5
```

#### Categories with High Average Price:
```sql
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 100;
```
**Result:**
```
CategoryID | AvgPrice
-----------|----------
1          | 358.19
2          | 275.00
```

### Visual: WHERE vs HAVING

```sql
-- WHERE: Filter ROWS before grouping
SELECT CategoryID, COUNT(*)
FROM Products
WHERE Price > 50        ← Filters individual products
GROUP BY CategoryID;

-- HAVING: Filter GROUPS after aggregation
SELECT CategoryID, COUNT(*)
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 2;    ← Filters groups
```

---

## 6️⃣ ORDER BY Clause - Sort Results

**Purpose:** Sort the final result set

### Basic Syntax:
```sql
SELECT columns
FROM TableName
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC];
```

- `ASC` = Ascending (default) - A to Z, 1 to 9
- `DESC` = Descending - Z to A, 9 to 1

### Examples:

#### Sort by Price (Lowest First):
```sql
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY Price;
```
**Result:**
```
ProductName | Price
------------|--------
Charger     | 19.99
Mouse       | 25.99
Headphones  | 45.00
Keyboard    | 75.50
...
```

#### Sort by Price (Highest First):
```sql
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY Price DESC;
```
**Result:**
```
ProductName | Price
------------|--------
Laptop      | 1200.00
Tablet      | 599.99
Monitor     | 350.00
...
```

#### Sort by Multiple Columns:
```sql
SELECT FirstName, LastName, City
FROM Sales.Customers
ORDER BY City, LastName;
```
**Result:**
```
FirstName | LastName | City
----------|----------|------------
Bob       | Johnson  | Chicago
Sarah     | Williams | Chicago
John      | Doe      | New York
Jane      | Smith    | New York
```

---

## 🔄 Query Execution Order

**CRITICAL:** SQL Server doesn't execute your query in the order you write it!

### What You Write:
```
1. SELECT
2. FROM
3. WHERE
4. GROUP BY
5. HAVING
6. ORDER BY
```

### How SQL Server Executes:
```
1. FROM      → Get the table(s)
2. WHERE     → Filter individual rows
3. GROUP BY  → Group rows
4. HAVING    → Filter groups
5. SELECT    → Choose columns and calculate
6. ORDER BY  → Sort final results
```

### Why This Matters:

```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount  -- 5. Calculated here
FROM Inventory.Products       -- 1. Table loaded first
WHERE Price > 50              -- 2. Rows filtered
GROUP BY CategoryID           -- 3. Rows grouped
HAVING COUNT(*) > 2           -- 4. Groups filtered
ORDER BY ProductCount DESC;   -- 6. Results sorted
```

**Example Impact:**
```sql
-- ❌ This FAILS - PriceWithTax doesn't exist yet in WHERE
SELECT 
    ProductName,
    Price * 1.15 AS PriceWithTax
FROM Products
WHERE PriceWithTax > 100;  -- Error! Calculated in SELECT (later)

-- ✅ This WORKS - Use original column in WHERE
SELECT 
    ProductName,
    Price * 1.15 AS PriceWithTax
FROM Products
WHERE Price * 1.15 > 100;  -- Repeat the calculation
```

---

## 🎨 Common Query Patterns

### Pattern 1: Filter + Sort
**Use Case:** Find specific items in order
```sql
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100
ORDER BY Price DESC;
```

### Pattern 2: Join + Filter + Sort
**Use Case:** Combine tables, filter, and sort
```sql
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 50
ORDER BY c.CategoryName, p.Price;
```

### Pattern 3: Group + Aggregate + Filter + Sort
**Use Case:** Summary reports
```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 75
ORDER BY AvgPrice DESC;
```

---

## 📊 Complete Example Walkthrough

**Question:** Find categories with more than 2 expensive products (>$50), show average price, sorted by count.

```sql
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AveragePrice
FROM Inventory.Products
WHERE Price > 50
GROUP BY CategoryID
HAVING COUNT(*) > 2
ORDER BY ProductCount DESC;
```

**Execution Steps:**

1. **FROM:** Load `Inventory.Products`
2. **WHERE:** Keep only `Price > 50`
3. **GROUP BY:** Group by `CategoryID`
4. **HAVING:** Keep groups with `COUNT(*) > 2`
5. **SELECT:** Calculate `COUNT(*)` and `AVG(Price)`
6. **ORDER BY:** Sort by `ProductCount DESC`

**Result:**
```
CategoryID | ProductCount | AveragePrice
-----------|--------------|-------------
1          | 4            | 456.25
```

---

## 🧪 Practice Exercises

### Exercise 1: Filter + Sort
Get all products over $200, sorted by price (highest first)
```sql
-- Your answer:
```

### Exercise 2: GROUP BY + COUNT
Count how many customers are in each city
```sql
-- Your answer:
```

### Exercise 3: WHERE + ORDER BY
Get employees with salary > $60,000, sorted by salary
```sql
-- Your answer:
```

### Exercise 4: GROUP BY + HAVING
Find categories with average product price > $100
```sql
-- Your answer:
```

### Exercise 5: Complete Query
Get products over $50, group by CategoryID, show only categories with 2+ products, sort by product count
```sql
-- Your answer:
```

---

## 🎯 Key Takeaways

| Clause | Purpose | When to Use |
|--------|---------|-------------|
| **SELECT** | Choose columns | Always required |
| **FROM** | Specify table(s) | Always required |
| **WHERE** | Filter rows | When you need specific data |
| **GROUP BY** | Group for aggregation | When calculating totals, averages, counts |
| **HAVING** | Filter groups | After GROUP BY, to filter aggregates |
| **ORDER BY** | Sort results | When order matters |

### Remember:
✅ Not all clauses are always needed  
✅ Execution order ≠ writing order  
✅ WHERE filters rows, HAVING filters groups  
✅ ORDER BY always comes last  

---

## 🚀 What's Next?

You now understand:
✅ All 6 main query clauses  
✅ When to use each clause  
✅ Query execution order  
✅ Common query patterns  

**Next Lesson:** [03-select-clause-guide.md](../03-select-clause/03-select-clause-guide.md)  
Deep dive into the SELECT clause with advanced techniques!

---

**Total Time:** 10 minutes  
**Next:** Lesson 03 - SELECT Clause Deep Dive
