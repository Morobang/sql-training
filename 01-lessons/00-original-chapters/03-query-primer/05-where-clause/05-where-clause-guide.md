# 🎯 Lesson 05: WHERE Clause - Filtering Data

## 📋 Overview

**Estimated Time:** 15 minutes  
**Difficulty:** Beginner  
**Prerequisites:** Lessons 01-04 completed  

**What You'll Learn:**
- Comparison operators (=, <>, >, <, >=, <=)
- Combining conditions (AND, OR, NOT)
- Range checks (BETWEEN)
- List matching (IN)
- Pattern matching (LIKE)
- NULL handling

---

## 🎯 What Is WHERE?

The **WHERE clause** filters rows BEFORE returning results. Think of it as a gatekeeper:

```
All Rows → WHERE Clause → Filtered Rows → Results
  (100)    (checks each)      (10)         (only 10 shown)
```

### Visual Example:

**Without WHERE:**
```sql
SELECT ProductName, Price FROM Products;
```
Returns ALL products (maybe thousands!)

**With WHERE:**
```sql
SELECT ProductName, Price FROM Products WHERE Price > 100;
```
Returns ONLY expensive products

---

## 🔢 Comparison Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal to | `WHERE Price = 100` |
| `<>` or `!=` | Not equal to | `WHERE Price <> 100` |
| `>` | Greater than | `WHERE Price > 100` |
| `<` | Less than | `WHERE Price < 100` |
| `>=` | Greater or equal | `WHERE Price >= 100` |
| `<=` | Less or equal | `WHERE Price <= 100` |

### Examples:

```sql
-- Exact match
SELECT * FROM Products WHERE Price = 99.99;

-- Not equal (two ways work)
SELECT * FROM Products WHERE Price <> 99.99;
SELECT * FROM Products WHERE Price != 99.99;

-- Greater than
SELECT * FROM Products WHERE Price > 100;

-- Range with two conditions
SELECT * FROM Products WHERE Price >= 50 AND Price <= 200;
```

---

## 🔗 Combining Conditions: AND

**AND** means ALL conditions must be true.

### Syntax:
```sql
SELECT columns
FROM table
WHERE condition1 AND condition2 AND condition3;
```

### Visual: AND Logic

```
Product: Laptop
Price: 1200
CategoryID: 1

WHERE Price > 100 AND CategoryID = 1
         ↓               ↓
       TRUE    AND    TRUE    = TRUE ✅ (included)

WHERE Price > 100 AND CategoryID = 2
         ↓               ↓
       TRUE    AND    FALSE   = FALSE ❌ (excluded)
```

### Examples:

```sql
-- Products between $50 and $200
SELECT ProductName, Price
FROM Products
WHERE Price >= 50 AND Price <= 200;

-- Electronics over $100
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 1 AND Price > 100;

-- Three conditions
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE Price > 50 
  AND StockQuantity > 20 
  AND CategoryID = 1;
```

**Truth Table for AND:**
```
Condition1 | Condition2 | Result
-----------|------------|--------
TRUE       | TRUE       | TRUE  ✅
TRUE       | FALSE      | FALSE ❌
FALSE      | TRUE       | FALSE ❌
FALSE      | FALSE      | FALSE ❌
```

---

## 🔀 Combining Conditions: OR

**OR** means AT LEAST ONE condition must be true.

### Syntax:
```sql
SELECT columns
FROM table
WHERE condition1 OR condition2 OR condition3;
```

### Visual: OR Logic

```
Product: Mouse
Price: 25
CategoryID: 1

WHERE Price < 30 OR Price > 1000
         ↓               ↓
       TRUE     OR    FALSE   = TRUE ✅ (included)

WHERE Price > 1000 OR CategoryID = 2
         ↓               ↓
       FALSE    OR    FALSE   = FALSE ❌ (excluded)
```

### Examples:

```sql
-- Cheap OR expensive products
SELECT ProductName, Price
FROM Products
WHERE Price < 30 OR Price > 1000;

-- Electronics OR Furniture
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID = 1 OR CategoryID = 2;
```

**Truth Table for OR:**
```
Condition1 | Condition2 | Result
-----------|------------|--------
TRUE       | TRUE       | TRUE  ✅
TRUE       | FALSE      | TRUE  ✅
FALSE      | TRUE       | TRUE  ✅
FALSE      | FALSE      | FALSE ❌
```

---

## 🎭 Mixing AND/OR with Parentheses

**Parentheses control the order of evaluation!**

### Without Parentheses (Dangerous):
```sql
WHERE CategoryID = 1 AND Price < 100 OR CategoryID = 2
```
**Interpreted as:**
```
(CategoryID = 1 AND Price < 100) OR (CategoryID = 2)
```
Returns: Cheap electronics OR ALL furniture

### With Parentheses (Clear):
```sql
WHERE CategoryID = 1 AND (Price < 100 OR CategoryID = 2)
```
**Interpreted as:**
```
CategoryID = 1 AND (Price < 100 OR CategoryID = 2)
```
Returns: Only category 1 that meets price condition

### Best Practice Example:
```sql
-- Clear intent: Cheap electronics OR expensive furniture
SELECT ProductName, CategoryID, Price
FROM Products
WHERE (CategoryID = 1 AND Price < 100) 
   OR (CategoryID = 2 AND Price > 200);
```

---

## 📏 BETWEEN - Range Checking

Shortcut for checking if a value is within a range.

### Syntax:
```sql
WHERE column BETWEEN low_value AND high_value
```

### Examples:

```sql
-- Products between $50 and $500
SELECT ProductName, Price
FROM Products
WHERE Price BETWEEN 50 AND 500;

-- Same as:
WHERE Price >= 50 AND Price <= 500;

-- Date range
SELECT OrderID, OrderDate
FROM Orders
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';

-- NOT BETWEEN
SELECT ProductName, Price
FROM Products
WHERE Price NOT BETWEEN 50 AND 500;
-- Returns products < 50 OR > 500
```

### Visual: BETWEEN

```
Price Range: 0 ─────────────────────────── 1000
                    ↓        ↓
                   50  BETWEEN  500
                    └──────────┘
                    This range is TRUE
```

---

## 📝 IN - List Matching

Check if a value matches ANY value in a list.

### Syntax:
```sql
WHERE column IN (value1, value2, value3, ...)
```

### Examples:

```sql
-- Products in specific categories
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (1, 2, 3);

-- Same as:
WHERE CategoryID = 1 OR CategoryID = 2 OR CategoryID = 3;

-- Customers from specific countries
SELECT FirstName, LastName, Country
FROM Customers
WHERE Country IN ('USA', 'UK', 'Canada');

-- NOT IN (exclude values)
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID NOT IN (1, 2);
```

### Visual: IN Operator

```
CategoryID = 2

IN (1, 2, 3)?
    ↓  ↓  ↓
    1  2  3
       ✅ Match found! → TRUE

IN (5, 6, 7)?
    ↓  ↓  ↓
    5  6  7
    ❌ No match → FALSE
```

---

## 🔍 LIKE - Pattern Matching

Search for patterns in text using wildcards.

### Wildcards:
- `%` = Any number of characters (0 or more)
- `_` = Exactly one character

### Syntax:
```sql
WHERE column LIKE 'pattern'
```

### Examples:

```sql
-- Starts with 'L'
WHERE ProductName LIKE 'L%'
-- Matches: Laptop, Lamp, Lock
-- Doesn't match: Mouse, Keyboard

-- Ends with 'er'
WHERE ProductName LIKE '%er'
-- Matches: Charger, Printer, Scanner
-- Doesn't match: Laptop, Mouse

-- Contains 'top'
WHERE ProductName LIKE '%top%'
-- Matches: Laptop, Desktop, Stopper
-- Doesn't match: Mouse, Keyboard

-- Exactly 4 characters
WHERE ProductName LIKE '____'  -- Four underscores
-- Matches: Desk, Lock, Lamp
-- Doesn't match: Laptop (6 chars), TV (2 chars)

-- Starts with 'S', ends with 't'
WHERE FirstName LIKE 'S%t'
-- Matches: Stuart, Scott
-- Doesn't match: Steve, Sam
```

### Visual: LIKE Patterns

```
Pattern: 'L%'
          L + any characters
          ↓   ↓
         Laptop     ✅
         Mouse      ❌
         Lamp       ✅

Pattern: '%top%'
         any + top + any
          ↓     ↓    ↓
         Laptop       ✅ (Lap-top)
         Desktop      ✅ (Desk-top)
         Mouse        ❌
```

### Case Sensitivity:
```sql
-- SQL Server: NOT case-sensitive by default
WHERE ProductName LIKE 'laptop'   -- Matches "Laptop", "LAPTOP", "laptop"

-- Make it case-sensitive (advanced)
WHERE ProductName COLLATE Latin1_General_CS_AS LIKE 'laptop'
```

---

## ❓ NULL Handling

**NULL = unknown/missing value**. It behaves differently!

### ⚠️ Common Mistake:
```sql
-- ❌ WRONG: This doesn't work!
WHERE SupplierID = NULL

-- ✅ CORRECT: Use IS NULL
WHERE SupplierID IS NULL
```

### Examples:

```sql
-- Find products WITHOUT a supplier
SELECT ProductName, SupplierID
FROM Products
WHERE SupplierID IS NULL;

-- Find products WITH a supplier
SELECT ProductName, SupplierID
FROM Products
WHERE SupplierID IS NOT NULL;
```

### Why = NULL Doesn't Work:

```
NULL means "unknown"

Is (unknown) equal to (unknown)?
Answer: We don't know! → NULL (not TRUE or FALSE)

That's why we use IS NULL
```

### Visual: NULL Behavior

```
Price = 100
Tax = NULL

Price + Tax = ?
100 + NULL = NULL  ← Any calculation with NULL = NULL

Price > NULL = ?
100 > NULL = NULL  ← Comparisons with NULL = NULL

Solution:
Price + ISNULL(Tax, 0) = 100 + 0 = 100
```

---

## 🚫 NOT Operator

Reverse a condition.

### Examples:

```sql
-- Not in Electronics
WHERE NOT CategoryID = 1
-- Same as:
WHERE CategoryID <> 1

-- Not starting with 'L'
WHERE ProductName NOT LIKE 'L%'

-- Not in list
WHERE CategoryID NOT IN (1, 2)

-- Not in range
WHERE Price NOT BETWEEN 50 AND 500
```

---

## 📅 Date Filtering

Working with dates and times.

### Examples:

```sql
-- Specific date
WHERE OrderDate = '2025-01-15'

-- After a date
WHERE OrderDate > '2025-01-01'

-- Date range
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31'

-- Current year (dynamic)
WHERE YEAR(OrderDate) = YEAR(GETDATE())

-- Last 30 days
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())

-- Specific month
WHERE MONTH(OrderDate) = 1 AND YEAR(OrderDate) = 2025
```

---

## 🔗 WHERE with JOINs

Filter joined tables.

### Examples:

```sql
-- Only Electronics products
SELECT p.ProductName, c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Expensive products with category
SELECT p.ProductName, c.CategoryName, p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 200;

-- Multiple filters
SELECT p.ProductName, c.CategoryName, p.Price
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics'
  AND p.Price > 50
  AND p.StockQuantity > 10;
```

---

## 🎯 Key Takeaways

| Operator | Purpose | Example |
|----------|---------|---------|
| `=` | Exact match | `WHERE Price = 100` |
| `<>` | Not equal | `WHERE Price <> 100` |
| `AND` | All conditions true | `WHERE Price > 50 AND Stock > 10` |
| `OR` | Any condition true | `WHERE Price < 30 OR Price > 1000` |
| `BETWEEN` | Range check | `WHERE Price BETWEEN 50 AND 500` |
| `IN` | List match | `WHERE CategoryID IN (1, 2, 3)` |
| `LIKE` | Pattern match | `WHERE Name LIKE 'L%'` |
| `IS NULL` | Check for NULL | `WHERE SupplierID IS NULL` |
| `NOT` | Reverse condition | `WHERE NOT CategoryID = 1` |

---

## 🚀 What's Next?

You now understand:
✅ All comparison operators  
✅ Combining conditions with AND/OR  
✅ Range and list checking  
✅ Pattern matching  
✅ NULL handling  

**Next Lesson:** [06-group-by-having-guide.md](../06-group-by-having/06-group-by-having-guide.md)  
Learn to aggregate and summarize data!

---

**Total Time:** 15 minutes  
**Next:** Lesson 06 - GROUP BY & HAVING
