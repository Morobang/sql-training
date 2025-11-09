# Lesson 3: Query Data (SELECT)

**Timeline:** 22:33 - 01:32:31  
**Duration:** ~58 minutes  
**Level:** 🟢 Beginner

## Learning Objectives

By the end of this lesson, you will be able to:
1. Write SELECT statements to retrieve data
2. Use WHERE clause to filter rows
3. Sort results with ORDER BY
4. Select specific columns vs all columns
5. Use LIMIT/TOP to control result size
6. Combine multiple query clauses effectively
7. Understand query execution order

## Why SELECT Matters

**SELECT is the most important SQL command** - you'll use it constantly to:
```
✓ Retrieve customer information
✓ Generate reports
✓ Analyze business data
✓ Build dashboards
✓ Validate data quality
```

**Fun Fact:** 80% of SQL you write will be SELECT statements!

---

## Part 1: Basic SELECT

### The Simplest Query

```sql
-- Get all data from Customers table
SELECT * FROM Customers;
```

**What this does:**
```
* = all columns
FROM Customers = from the Customers table
Result: Every row, every column
```

**Example Output:**
```
CustomerID | FirstName | LastName | Email                | SignupDate
-----------|-----------|----------|----------------------|------------
1          | John      | Doe      | john.doe@email.com   | 2024-01-15
2          | Jane      | Smith    | jane.smith@email.com | 2024-02-20
3          | Bob       | Johnson  | bob.j@email.com      | 2024-03-10
```

### Select Specific Columns

**Better Practice:** Select only what you need

```sql
-- Get just names and emails
SELECT FirstName, LastName, Email
FROM Customers;
```

**Output:**
```
FirstName | LastName | Email
----------|----------|--------------------
John      | Doe      | john.doe@email.com
Jane      | Smith    | jane.smith@email.com
Bob       | Johnson  | bob.j@email.com
```

**Why select specific columns?**
```
✓ Faster queries (less data transferred)
✓ Clearer intent (shows what you need)
✓ Better performance on large tables
✓ Easier to read results
```

### Practice: Your First Queries

```sql
-- 1. Get all products
SELECT * FROM Products;

-- 2. Get just product names and prices
SELECT ProductName, Price FROM Products;

-- 3. Get customer emails only
SELECT Email FROM Customers;
```

---

## Part 2: Limiting Results

### Using TOP (SQL Server)

```sql
-- Get first 5 customers
SELECT TOP 5 * FROM Customers;

-- Get first 10 products
SELECT TOP 10 ProductName, Price
FROM Products;
```

### Using LIMIT (MySQL/PostgreSQL)

```sql
-- Get first 5 customers
SELECT * FROM Customers LIMIT 5;

-- Get first 10 products
SELECT ProductName, Price
FROM Products
LIMIT 10;
```

**When to use TOP/LIMIT:**
```
✓ Testing queries (preview data)
✓ Large tables (millions of rows)
✓ "Show me top 10 sellers"
✓ Pagination (show page 1, 2, 3...)
```

---

## Part 3: WHERE Clause (Filtering)

### What is WHERE?

**WHERE filters rows** - only return rows that match conditions.

```sql
-- Products over $100
SELECT ProductName, Price
FROM Products
WHERE Price > 100;
```

**Visual:**
```
All Products (Before WHERE):
┌──────────────┬────────┐
│ ProductName  │ Price  │
├──────────────┼────────┤
│ Laptop       │ 1200   │ ← Matches
│ Mouse        │ 25     │
│ Monitor      │ 350    │ ← Matches
│ Keyboard     │ 75     │
│ Tablet       │ 599    │ ← Matches
└──────────────┴────────┘

Filtered Results (After WHERE Price > 100):
┌──────────────┬────────┐
│ ProductName  │ Price  │
├──────────────┼────────┤
│ Laptop       │ 1200   │
│ Monitor      │ 350    │
│ Tablet       │ 599    │
└──────────────┴────────┘
```

### Comparison Operators

```sql
-- Equal to
SELECT * FROM Products WHERE Price = 100;

-- Not equal to
SELECT * FROM Products WHERE Price != 100;
SELECT * FROM Products WHERE Price <> 100;  -- Same as !=

-- Greater than
SELECT * FROM Products WHERE Price > 100;

-- Less than
SELECT * FROM Products WHERE Price < 100;

-- Greater than or equal
SELECT * FROM Products WHERE Price >= 100;

-- Less than or equal
SELECT * FROM Products WHERE Price <= 100;
```

### Text Filtering

```sql
-- Exact match
SELECT * FROM Customers WHERE LastName = 'Smith';

-- Case-insensitive (depends on database settings)
SELECT * FROM Customers WHERE LastName = 'SMITH';  -- Usually same as 'Smith'
```

### Pattern Matching with LIKE

```sql
-- Names starting with 'J'
SELECT FirstName, LastName
FROM Customers
WHERE FirstName LIKE 'J%';

-- Emails from gmail
SELECT Email FROM Customers
WHERE Email LIKE '%@gmail.com';

-- Names containing 'son'
SELECT FirstName, LastName
FROM Customers
WHERE LastName LIKE '%son%';
```

**LIKE Wildcards:**
```
% = any characters (zero or more)
_ = exactly one character

Examples:
'J%'     → John, Jane, Jennifer
'%son'   → Johnson, Wilson, Jackson
'%son%'  → Johnson, Wilson, Samson
'J_n'    → Jan, Jon, Jin (not John - needs 4 letters)
```

### Multiple Conditions (AND, OR)

```sql
-- AND: Both conditions must be true
SELECT ProductName, Price
FROM Products
WHERE Price > 100 AND Price < 500;

-- OR: At least one condition must be true
SELECT ProductName, Price
FROM Products
WHERE Price < 50 OR Price > 1000;

-- Combining AND/OR (use parentheses!)
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE (Price > 100 AND StockQuantity > 10)
   OR (Price < 20 AND StockQuantity > 50);
```

### IN Operator

```sql
-- Multiple possible values
SELECT * FROM Customers
WHERE Country IN ('USA', 'Canada', 'Mexico');

-- Same as:
SELECT * FROM Customers
WHERE Country = 'USA' 
   OR Country = 'Canada' 
   OR Country = 'Mexico';

-- NOT IN
SELECT * FROM Customers
WHERE Country NOT IN ('USA', 'Canada');
```

### BETWEEN Operator

```sql
-- Price range
SELECT ProductName, Price
FROM Products
WHERE Price BETWEEN 100 AND 500;

-- Same as:
SELECT ProductName, Price
FROM Products
WHERE Price >= 100 AND Price <= 500;

-- Date range
SELECT * FROM Orders
WHERE OrderDate BETWEEN '2024-01-01' AND '2024-12-31';
```

### NULL Values

```sql
-- Find customers with no email
SELECT * FROM Customers
WHERE Email IS NULL;

-- Find customers with email
SELECT * FROM Customers
WHERE Email IS NOT NULL;

-- WRONG (doesn't work):
-- WHERE Email = NULL  ❌
```

**Important:** Use `IS NULL`, not `= NULL`

---

## Part 4: ORDER BY (Sorting)

### Basic Sorting

```sql
-- Sort by price (lowest to highest)
SELECT ProductName, Price
FROM Products
ORDER BY Price;

-- Sort by price (highest to lowest)
SELECT ProductName, Price
FROM Products
ORDER BY Price DESC;
```

**ASC vs DESC:**
```
ASC  = Ascending (default)  → 1, 2, 3... or A, B, C...
DESC = Descending           → 9, 8, 7... or Z, Y, X...
```

### Sort by Multiple Columns

```sql
-- Sort by country, then city, then last name
SELECT FirstName, LastName, City, Country
FROM Customers
ORDER BY Country, City, LastName;
```

**How it works:**
```
1. First, sort by Country (A-Z)
2. Within each country, sort by City (A-Z)
3. Within each city, sort by LastName (A-Z)

Result:
Country | City      | LastName
--------|-----------|----------
Canada  | Toronto   | Brown
Canada  | Toronto   | Smith
Canada  | Vancouver | Wilson
USA     | Boston    | Davis
USA     | Boston    | Johnson
USA     | New York  | Williams
```

### Mix ASC and DESC

```sql
-- Sort by country ascending, then price descending
SELECT ProductName, Country, Price
FROM Products
ORDER BY Country ASC, Price DESC;
```

---

## Part 5: Combining Everything

### Complete Query Example

```sql
-- Find expensive electronics, sorted by price
SELECT 
    ProductName,
    Category,
    Price,
    StockQuantity
FROM Products
WHERE Category = 'Electronics'
  AND Price > 200
  AND StockQuantity > 0
ORDER BY Price DESC;
```

**What this does:**
```
1. Look at Products table
2. Filter: Only Electronics
3. Filter: Only Price > $200
4. Filter: Only in stock (StockQuantity > 0)
5. Sort by price (highest first)
6. Return: ProductName, Category, Price, StockQuantity
```

### Query Execution Order

**What you write:**
```sql
SELECT columns
FROM table
WHERE condition
ORDER BY column;
```

**How SQL executes:**
```
1. FROM    → Get the table
2. WHERE   → Filter rows
3. SELECT  → Choose columns
4. ORDER BY → Sort results
```

**Important:** SQL executes in different order than you write!

---

## Part 6: Column Aliases

### Renaming Columns

```sql
-- Use AS to rename columns in results
SELECT 
    FirstName AS 'First Name',
    LastName AS 'Last Name',
    Email AS 'Email Address'
FROM Customers;
```

**Output:**
```
First Name | Last Name | Email Address
-----------|-----------|-------------------
John       | Doe       | john.doe@email.com
```

### Calculated Columns

```sql
-- Calculate total value of inventory
SELECT 
    ProductName,
    Price,
    StockQuantity,
    Price * StockQuantity AS TotalValue
FROM Products;
```

**Output:**
```
ProductName | Price | StockQuantity | TotalValue
------------|-------|---------------|------------
Laptop      | 1200  | 5             | 6000
Mouse       | 25    | 100           | 2500
Monitor     | 350   | 15            | 5250
```

### String Concatenation

```sql
-- Combine first and last name
SELECT 
    FirstName + ' ' + LastName AS FullName,
    Email
FROM Customers;

-- Output:
-- FullName      | Email
-- --------------|--------------------
-- John Doe      | john.doe@email.com
-- Jane Smith    | jane.smith@email.com
```

---

## Part 7: DISTINCT

### Remove Duplicates

```sql
-- Get unique countries (no duplicates)
SELECT DISTINCT Country
FROM Customers;
```

**Example:**
```
Before DISTINCT:
Country
-------
USA
Canada
USA
Mexico
Canada
USA

After DISTINCT:
Country
-------
Canada
Mexico
USA
```

### DISTINCT with Multiple Columns

```sql
-- Unique combinations of city and country
SELECT DISTINCT City, Country
FROM Customers;
```

---

## Part 8: Real-World Examples

### Example 1: E-Commerce

```sql
-- Find high-value orders from this year
SELECT 
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount
FROM Orders
WHERE OrderDate >= '2024-01-01'
  AND TotalAmount > 500
ORDER BY TotalAmount DESC;
```

### Example 2: Customer Analysis

```sql
-- Find US customers who signed up recently
SELECT 
    FirstName,
    LastName,
    Email,
    SignupDate
FROM Customers
WHERE Country = 'USA'
  AND SignupDate >= '2024-01-01'
ORDER BY SignupDate DESC;
```

### Example 3: Inventory Management

```sql
-- Find low-stock expensive items
SELECT TOP 10
    ProductName,
    Price,
    StockQuantity,
    Price * StockQuantity AS InventoryValue
FROM Products
WHERE StockQuantity < 10
  AND Price > 100
ORDER BY InventoryValue DESC;
```

### Example 4: Product Search

```sql
-- Search products by name
SELECT 
    ProductID,
    ProductName,
    Price,
    StockQuantity
FROM Products
WHERE ProductName LIKE '%laptop%'
  AND Price BETWEEN 500 AND 2000
  AND StockQuantity > 0
ORDER BY Price;
```

---

## Part 9: Common Patterns

### Pattern 1: Top N Items

```sql
-- Top 5 most expensive products
SELECT TOP 5
    ProductName,
    Price
FROM Products
ORDER BY Price DESC;
```

### Pattern 2: Date Range

```sql
-- Orders from last 30 days
SELECT *
FROM Orders
WHERE OrderDate >= DATEADD(day, -30, GETDATE());
```

### Pattern 3: Text Search

```sql
-- Find customers by name or email
SELECT FirstName, LastName, Email
FROM Customers
WHERE FirstName LIKE '%john%'
   OR LastName LIKE '%john%'
   OR Email LIKE '%john%';
```

### Pattern 4: Category Filter

```sql
-- Products in specific categories
SELECT ProductName, Category, Price
FROM Products
WHERE Category IN ('Electronics', 'Computers', 'Accessories')
ORDER BY Category, Price;
```

---

## Part 10: Performance Tips

### DO: Be Specific

```sql
-- ✅ Good: Select only needed columns
SELECT CustomerID, FirstName, Email
FROM Customers
WHERE Country = 'USA';

-- ✅ Good: Use TOP/LIMIT for testing
SELECT TOP 100 * FROM Orders;

-- ✅ Good: Filter early with WHERE
SELECT * FROM Products WHERE Price > 100;
```

### DON'T: Be Wasteful

```sql
-- ❌ Bad: SELECT * on huge tables
SELECT * FROM Orders;  -- If millions of rows

-- ❌ Bad: No WHERE on large tables
SELECT * FROM Transactions;  -- Gets everything!

-- ❌ Bad: Complex calculations without filter
SELECT *, Price * 1.15 * 1.08 * TaxRate FROM Products;
```

---

## Part 11: Common Mistakes

### Mistake 1: Wrong NULL Check

```sql
-- ❌ WRONG
SELECT * FROM Customers WHERE Email = NULL;

-- ✅ CORRECT
SELECT * FROM Customers WHERE Email IS NULL;
```

### Mistake 2: Case Sensitivity

```sql
-- Check your database settings
SELECT * FROM Customers WHERE Country = 'usa';
SELECT * FROM Customers WHERE Country = 'USA';

-- Might be same or different depending on database!
```

### Mistake 3: String vs Number

```sql
-- ❌ WRONG (treating number as text)
SELECT * FROM Products WHERE Price = '100';

-- ✅ CORRECT
SELECT * FROM Products WHERE Price = 100;
```

### Mistake 4: Forgetting ORDER BY

```sql
-- ❌ Without ORDER BY: Random order
SELECT TOP 10 * FROM Products;

-- ✅ With ORDER BY: Predictable order
SELECT TOP 10 * FROM Products ORDER BY Price DESC;
```

---

## Part 12: Practice Exercises

### Exercise 1: Basic Queries
```sql
-- 1. Get all customers
-- Write your query:


-- 2. Get product names and prices only
-- Write your query:


-- 3. Get first 5 orders
-- Write your query:
```

### Exercise 2: Filtering
```sql
-- 4. Find products under $50
-- Write your query:


-- 5. Find customers from Canada
-- Write your query:


-- 6. Find products with 'phone' in the name
-- Write your query:
```

### Exercise 3: Sorting
```sql
-- 7. List products by price (cheapest first)
-- Write your query:


-- 8. List customers by last name alphabetically
-- Write your query:


-- 9. Show top 10 most expensive products
-- Write your query:
```

### Exercise 4: Combined
```sql
-- 10. Find US customers who signed up in 2024, sorted by signup date
-- Write your query:


-- 11. Find in-stock electronics under $1000, sorted by price
-- Write your query:


-- 12. Find orders over $500 from last 90 days, show top 20 by amount
-- Write your query:
```

---

## Key Takeaways

### Essential Commands
```sql
SELECT     → Choose columns
FROM       → Specify table
WHERE      → Filter rows
ORDER BY   → Sort results
TOP/LIMIT  → Limit results
```

### Comparison Operators
```
=    Equal to
!=   Not equal (also <>)
>    Greater than
<    Less than
>=   Greater or equal
<=   Less or equal
```

### Special Operators
```
LIKE        → Pattern matching
IN          → Multiple values
BETWEEN     → Range
IS NULL     → Check for NULL
IS NOT NULL → Check for not NULL
```

### Wildcards
```
%  → Any characters
_  → Single character
```

### Logical Operators
```
AND → Both conditions true
OR  → At least one true
NOT → Negate condition
```

### Best Practices
```
✓ SELECT specific columns (not *)
✓ Use WHERE to filter
✓ Use TOP/LIMIT for testing
✓ Always ORDER BY with TOP
✓ Use aliases for clarity
✗ Don't SELECT * on large tables
✗ Don't forget WHERE on big tables
```

---

## Quick Reference Card

```sql
-- Template query
SELECT column1, column2
FROM table_name
WHERE condition
ORDER BY column1 DESC
LIMIT 10;

-- Common patterns
WHERE Price > 100
WHERE Name LIKE 'A%'
WHERE Status IN ('Active', 'Pending')
WHERE Date BETWEEN '2024-01-01' AND '2024-12-31'
WHERE Email IS NOT NULL
WHERE (Price > 100 AND Stock > 0) OR Featured = 1

-- Sorting
ORDER BY Price              -- Ascending (default)
ORDER BY Price DESC         -- Descending
ORDER BY Country, City      -- Multiple columns
```

---

## Next Lesson

**Continue to [Lesson 4: DDL Commands](../04-ddl-commands/)**  
Learn to create and modify database structures with CREATE, ALTER, and DROP.

---

## Additional Resources

- **SQL SELECT Documentation:** https://docs.microsoft.com/sql/t-sql/queries/select
- **WHERE Clause:** https://docs.microsoft.com/sql/t-sql/queries/where
- **ORDER BY:** https://docs.microsoft.com/sql/t-sql/queries/select-order-by

**Congratulations! You've learned the foundation of SQL querying! 🎉**
