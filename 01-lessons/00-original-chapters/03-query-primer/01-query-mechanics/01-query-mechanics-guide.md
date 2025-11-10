# 🔍 Lesson 01: Query Mechanics - How SQL Queries Work

## 📋 Overview

**Estimated Time:** 10 minutes  
**Difficulty:** Beginner  
**Prerequisites:** RetailStore database with sample data  

**What You'll Learn:**
- How SQL queries are executed
- Basic SELECT syntax
- Column selection and aliases
- Simple calculations
- DISTINCT for unique values

---

## 🎯 What Is a Query?

A **query** is a request for data from a database. Think of it like asking a librarian:
- "Show me all books" → `SELECT * FROM Books`
- "Show me just the titles" → `SELECT Title FROM Books`
- "Show me the first 5 books" → `SELECT TOP 5 Title FROM Books`

---

## 🔄 How Queries Are Executed

When you run a query, SQL Server follows this process:

```
┌─────────────────────────────────────────┐
│  1. PARSE: Check syntax                │
│     Is the SQL written correctly?       │
├─────────────────────────────────────────┤
│  2. VALIDATE: Check objects             │
│     Does the table exist?               │
├─────────────────────────────────────────┤
│  3. OPTIMIZE: Plan execution            │
│     What's the fastest way to get data? │
├─────────────────────────────────────────┤
│  4. EXECUTE: Run the query              │
│     Read data from disk/memory          │
├─────────────────────────────────────────┤
│  5. RETURN: Send results                │
│     Display data to you                 │
└─────────────────────────────────────────┘
```

### Visual Example:

```
You type:  SELECT ProductName FROM Products;
              ↓
SQL Server:  "Let me find the Products table..."
              ↓
SQL Server:  "Reading ProductName column..."
              ↓
Your screen: ProductName
             -----------
             Laptop
             Mouse
             Keyboard
             ...
```

---

## 📝 Basic SELECT Syntax

### Anatomy of a SELECT Statement:

```sql
SELECT column1, column2, ...
FROM SchemaName.TableName;
```

### Parts Explained:

```
┌────────────────────────────────────────────┐
│  SELECT ProductName, Price                 │ ← Columns to retrieve
├────────────────────────────────────────────┤
│  FROM Inventory.Products;                  │ ← Table to query
└────────────────────────────────────────────┘
         ↑              ↑
      Schema          Table
```

---

## 🎨 Example 1: Simple SELECT

### Query:
```sql
SELECT * FROM Inventory.Categories;
```

### What It Does:
- `SELECT *` → Get ALL columns
- `FROM Inventory.Categories` → From this table

### Result:
```
CategoryID | CategoryName  | Description
-----------|---------------|---------------------------
1          | Electronics   | Electronic devices
2          | Furniture     | Office and home furniture
3          | Clothing      | Apparel and accessories
```

### Better Approach (Specify Columns):
```sql
SELECT CategoryName, Description
FROM Inventory.Categories;
```

**Why?** Faster performance, clearer intent, less data transferred.

---

## 🔢 Example 2: Selecting Specific Columns

### Query:
```sql
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Inventory.Products;
```

### Result:
```
ProductName | Price   | StockQuantity
------------|---------|---------------
Laptop      | 1200.00 | 25
Mouse       | 25.99   | 150
Keyboard    | 75.50   | 80
Monitor     | 350.00  | 40
```

### Why This Format?
- Each column on its own line → **readable**
- Easier to add/remove columns
- Professional formatting

---

## 🏷️ Example 3: Column Aliases (Renaming)

Sometimes column names aren't user-friendly. Use **aliases** to rename them in results.

### Query:
```sql
SELECT 
    ProductName AS Product,
    Price AS Cost,
    StockQuantity AS [In Stock]
FROM Inventory.Products;
```

### Result:
```
Product  | Cost    | In Stock
---------|---------|----------
Laptop   | 1200.00 | 25
Mouse    | 25.99   | 150
Keyboard | 75.50   | 80
```

### Alias Syntax:
```sql
-- With AS keyword (recommended)
SELECT ProductName AS Product

-- Without AS (also works)
SELECT ProductName Product

-- Spaces require brackets
SELECT ProductName AS [Product Name]
```

---

## 🧮 Example 4: Calculations in SELECT

You can perform calculations directly in your query!

### Query:
```sql
SELECT 
    ProductName,
    Price,
    Price * 0.15 AS Tax,
    Price * 1.15 AS [Total with Tax]
FROM Inventory.Products;
```

### Result:
```
ProductName | Price   | Tax    | Total with Tax
------------|---------|--------|----------------
Laptop      | 1200.00 | 180.00 | 1380.00
Mouse       | 25.99   | 3.90   | 29.89
Keyboard    | 75.50   | 11.33  | 86.83
```

### Common Calculations:
```sql
-- Addition
Price + ShippingCost

-- Subtraction
Price - Discount

-- Multiplication
Price * Quantity

-- Division
TotalCost / Quantity

-- Percentage
Price * 0.20  -- 20% of price
```

---

## ✂️ Example 5: Text Concatenation

Combine text columns to create formatted output.

### Query:
```sql
SELECT 
    FirstName + ' ' + LastName AS [Customer Name],
    Email
FROM Sales.Customers;
```

### Result:
```
Customer Name  | Email
---------------|----------------------
John Doe       | john.doe@email.com
Jane Smith     | jane.smith@email.com
Mike Johnson   | mike.j@email.com
```

### Concatenation Operator:
```sql
-- Use + to join strings
FirstName + ' ' + LastName  -- Adds space between

-- Format text
'Customer: ' + FirstName + ' ' + LastName
-- Result: "Customer: John Doe"

-- Add symbols
'$' + CAST(Price AS VARCHAR)
-- Result: "$1200"
```

---

## 🎯 Example 6: TOP - Limiting Results

Don't retrieve more data than you need!

### Query:
```sql
SELECT TOP 5
    ProductName,
    Price
FROM Inventory.Products;
```

### Result (First 5 Rows Only):
```
ProductName | Price
------------|--------
Laptop      | 1200.00
Mouse       | 25.99
Keyboard    | 75.50
Monitor     | 350.00
Webcam      | 89.99
```

### TOP Syntax:
```sql
-- Get first 10 rows
SELECT TOP 10 * FROM Products;

-- Get first 5 customers
SELECT TOP 5 FirstName, LastName FROM Customers;

-- TOP with calculations
SELECT TOP 3 ProductName, Price * 1.15 AS TaxedPrice
FROM Products;
```

**When to Use TOP:**
- Testing queries on large tables
- Getting sample data
- Finding "top performers" (with ORDER BY - Lesson 7)

---

## 🌟 Example 7: DISTINCT - Unique Values

Remove duplicate values from results.

### Without DISTINCT:
```sql
SELECT City FROM Sales.Customers;
```
**Result:**
```
City
----------
New York
Los Angeles
New York     ← Duplicate
Chicago
Los Angeles  ← Duplicate
```

### With DISTINCT:
```sql
SELECT DISTINCT City FROM Sales.Customers;
```
**Result:**
```
City
----------
New York
Los Angeles
Chicago
```

### Use Cases:
```sql
-- All unique countries
SELECT DISTINCT Country FROM Customers;

-- All unique categories
SELECT DISTINCT CategoryID FROM Products;

-- Unique combinations
SELECT DISTINCT City, Country FROM Customers;
```

---

## 📊 Visual: Query Execution Flow

```
┌─────────────────────────────────────────────────┐
│ SELECT ProductName, Price                       │
│ FROM Inventory.Products;                        │
└─────────────────────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │  SQL Server Engine    │
        └───────────────────────┘
                    ↓
    ┌───────────────────────────────┐
    │ 1. Find Inventory schema      │
    │ 2. Find Products table        │
    │ 3. Open table for reading     │
    └───────────────────────────────┘
                    ↓
    ┌───────────────────────────────┐
    │ 4. Read ProductName column    │
    │ 5. Read Price column          │
    │ 6. Skip other columns         │
    └───────────────────────────────┘
                    ↓
    ┌───────────────────────────────┐
    │ 7. Return results to you      │
    └───────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │ Results Grid:         │
        │ ProductName | Price   │
        │ Laptop      | 1200.00 │
        │ Mouse       | 25.99   │
        │ ...                   │
        └───────────────────────┘
```

---

## ✅ Good vs ❌ Bad Query Formatting

### ❌ BAD: Hard to Read
```sql
SELECT ProductName,Price,StockQuantity FROM Inventory.Products WHERE CategoryID=1;
```

### ✅ GOOD: Clean and Readable
```sql
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Inventory.Products
WHERE CategoryID = 1;
```

### Best Practices:
1. **One clause per line** (SELECT, FROM, WHERE on separate lines)
2. **Indent columns** under SELECT
3. **Spaces around operators** (`=`, `>`, `<`)
4. **Use line breaks** for readability
5. **Add comments** for complex queries

---

## 🧪 Practice Exercises

Try these queries yourself:

### Exercise 1: Get All Suppliers
```sql
-- Show all columns from Suppliers table
-- Your answer:
```

### Exercise 2: Show Department Names
```sql
-- Get just DepartmentName from HR.Departments
-- Your answer:
```

### Exercise 3: First 10 Orders
```sql
-- Show OrderID and OrderDate for first 10 orders
-- Your answer:
```

### Exercise 4: Full Employee Names
```sql
-- Combine FirstName + LastName, show with Salary
-- Your answer:
```

### Exercise 5: Discounted Prices
```sql
-- Calculate 20% discount on all products
-- Show original price and discounted price
-- Your answer:
```

---

## 🎯 Key Takeaways

| Concept | What It Does | Example |
|---------|--------------|---------|
| **SELECT** | Specifies which columns to retrieve | `SELECT ProductName, Price` |
| **FROM** | Specifies which table to query | `FROM Inventory.Products` |
| **TOP** | Limits number of rows returned | `SELECT TOP 10 *` |
| **AS** | Creates column alias (rename) | `Price AS Cost` |
| **DISTINCT** | Returns only unique values | `SELECT DISTINCT City` |
| **Calculations** | Perform math in SELECT | `Price * 1.15` |
| **Concatenation** | Combine text columns | `FirstName + ' ' + LastName` |

---

## 🚀 What's Next?

You now understand:
✅ How queries are executed  
✅ How to select specific columns  
✅ How to limit and rename results  
✅ How to calculate and concatenate  

**Next Lesson:** [02-query-clauses-guide.md](../02-query-clauses/02-query-clauses-guide.md)  
You'll learn about all the different clauses (WHERE, GROUP BY, ORDER BY) and when to use them!

---

## 💡 Pro Tips

1. **Start simple:** `SELECT * FROM TableName` to see all data
2. **Then refine:** Add specific columns you need
3. **Test with TOP:** Use `TOP 10` when testing on large tables
4. **Format well:** Future you will thank you
5. **Use aliases:** Make results user-friendly

---

**Total Time:** 10 minutes  
**Next:** Lesson 02 - Query Clauses Overview
