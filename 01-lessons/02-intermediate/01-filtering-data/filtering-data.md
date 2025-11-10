# Lesson 1: Filtering Data

**Timeline:** 02:08:03 - 02:47:57  
**Duration:** ~40 minutes  
**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson, you will be able to:
1. Write complex filter conditions with multiple operators
2. Master AND, OR, and NOT logical operators
3. Use parentheses to control evaluation order
4. Apply range conditions with BETWEEN
5. Check membership with IN and NOT IN
6. Perform pattern matching with LIKE and wildcards
7. Handle NULL values correctly
8. Combine multiple filtering techniques effectively

## Prerequisites

✅ Completed Beginner Level  
✅ Understanding of basic SELECT queries  
✅ Familiarity with WHERE clause basics

---

## Part 1: Review - Comparison Operators

### Basic Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `=` | Equal to | `WHERE Price = 100` |
| `<>` or `!=` | Not equal | `WHERE Price <> 100` |
| `>` | Greater than | `WHERE Price > 100` |
| `<` | Less than | `WHERE Price < 100` |
| `>=` | Greater or equal | `WHERE Price >= 100` |
| `<=` | Less or equal | `WHERE Price <= 100` |

### Examples

```sql
-- Exact match
SELECT * FROM Products WHERE Price = 99.99;

-- Not equal (both work)
SELECT * FROM Products WHERE CategoryID <> 1;
SELECT * FROM Products WHERE CategoryID != 1;

-- Greater than
SELECT * FROM Orders WHERE TotalAmount > 1000;

-- Less than or equal
SELECT * FROM Products WHERE StockQuantity <= 10;
```

**Numeric comparisons:**
```
5 > 3   → TRUE
10 <= 10 → TRUE
15 <> 15 → FALSE
```

**Text comparisons (alphabetical):**
```
'Apple' < 'Banana'  → TRUE (A comes before B)
'Zebra' > 'Apple'   → TRUE (Z comes after A)
```

---

## Part 2: Logical Operators - AND

### What is AND?

**AND requires ALL conditions to be TRUE.**

```
Condition1 AND Condition2
    ↓           ↓
  TRUE       TRUE     → Result: TRUE
  TRUE       FALSE    → Result: FALSE
  FALSE      TRUE     → Result: FALSE
  FALSE      FALSE    → Result: FALSE
```

### Examples

```sql
-- Products in Electronics (CategoryID=1) AND over $100
SELECT ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1
  AND Price > 100;
```

**Visualization:**
```
All Products
├── CategoryID = 1 (Electronics)
│   ├── Price $50    ❌ (fails price check)
│   ├── Price $150   ✅ (both conditions met)
│   └── Price $250   ✅ (both conditions met)
├── CategoryID = 2 (Clothing)
│   ├── Price $120   ❌ (fails category check)
│   └── Price $200   ❌ (fails category check)
└── CategoryID = 3 (Books)
    └── Price $180   ❌ (fails category check)
```

### Multiple AND Conditions

```sql
-- Find premium electronics
SELECT ProductName, Price, StockQuantity, CategoryID
FROM Products
WHERE CategoryID = 1        -- Must be Electronics
  AND Price > 500           -- Must be expensive
  AND StockQuantity > 0     -- Must be in stock
  AND IsActive = 1;         -- Must be active
```

**All 4 conditions must be TRUE!**

---

## Part 3: Logical Operators - OR

### What is OR?

**OR requires AT LEAST ONE condition to be TRUE.**

```
Condition1 OR Condition2
    ↓          ↓
  TRUE       TRUE     → Result: TRUE
  TRUE       FALSE    → Result: TRUE
  FALSE      TRUE     → Result: TRUE
  FALSE      FALSE    → Result: FALSE
```

### Examples

```sql
-- Products under $50 OR over $500
SELECT ProductName, Price
FROM Products
WHERE Price < 50
   OR Price > 500;
```

**Visual:**
```
Price Range:
├── $25    ✅ (< 50)
├── $100   ❌ (neither condition)
├── $300   ❌ (neither condition)
├── $600   ✅ (> 500)
└── $999   ✅ (> 500)
```

### Multiple OR Conditions

```sql
-- Orders from specific months
SELECT OrderID, OrderDate
FROM Orders
WHERE MONTH(OrderDate) = 1   -- January
   OR MONTH(OrderDate) = 7   -- July
   OR MONTH(OrderDate) = 12; -- December
```

---

## Part 4: Mixing AND/OR with Parentheses

### Why Parentheses Matter

**Without parentheses - WRONG result:**
```sql
SELECT ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1 AND Price < 100 OR Price > 500;
```

**How SQL reads this:**
```
(CategoryID = 1 AND Price < 100) OR (Price > 500)
                ↓
Result: Cheap electronics OR any expensive product
```

**With parentheses - CORRECT:**
```sql
SELECT ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1 
  AND (Price < 100 OR Price > 500);
```

**How SQL reads this:**
```
CategoryID = 1 AND (Price < 100 OR Price > 500)
                          ↓
Result: Electronics that are either cheap OR expensive
```

### Complex Example

```sql
-- Premium products: (High-end electronics) OR (Luxury clothing)
SELECT ProductName, CategoryID, Price
FROM Products
WHERE (CategoryID = 1 AND Price > 1000)   -- High-end electronics
   OR (CategoryID = 2 AND Price > 500);   -- Luxury clothing
```

**Visualization:**
```
Match if:
  Electronics AND Price > $1000
  OR
  Clothing AND Price > $500

CategoryID=1, Price=$1500  ✅ (first group matches)
CategoryID=1, Price=$300   ❌ (price too low)
CategoryID=2, Price=$600   ✅ (second group matches)
CategoryID=2, Price=$100   ❌ (price too low)
CategoryID=3, Price=$2000  ❌ (wrong categories)
```

### Best Practice: Always Use Parentheses

```sql
-- ✅ CLEAR: Easy to understand
WHERE (Price > 100 AND StockQuantity > 0)
   OR (CategoryID = 5);

-- ❌ CONFUSING: Hard to understand intent
WHERE Price > 100 AND StockQuantity > 0 OR CategoryID = 5;
```

---

## Part 5: NOT Operator

### Reversing Conditions

**NOT reverses TRUE/FALSE:**
```
NOT TRUE  = FALSE
NOT FALSE = TRUE
```

### Examples

```sql
-- Products NOT in Electronics (CategoryID NOT 1)
SELECT ProductName, CategoryID
FROM Products
WHERE NOT CategoryID = 1;

-- Same as:
WHERE CategoryID <> 1;
WHERE CategoryID != 1;
```

### NOT with Other Operators

```sql
-- NOT IN
SELECT * FROM Products
WHERE CategoryID NOT IN (1, 2, 3);

-- NOT LIKE
SELECT * FROM Customers
WHERE Email NOT LIKE '%@gmail.com';

-- NOT BETWEEN
SELECT * FROM Products
WHERE Price NOT BETWEEN 100 AND 500;

-- NOT NULL
SELECT * FROM Products
WHERE SupplierID IS NOT NULL;
```

### Complex NOT

```sql
-- Products NOT (cheap AND out of stock)
SELECT ProductName, Price, StockQuantity
FROM Products
WHERE NOT (Price < 50 AND StockQuantity = 0);

-- This matches:
-- - Expensive products (any stock)
-- - Cheap products with stock
-- Does NOT match:
-- - Cheap products with no stock
```

---

## Part 6: BETWEEN - Range Conditions

### BETWEEN Syntax

```sql
WHERE column BETWEEN value1 AND value2
```

**Equivalent to:**
```sql
WHERE column >= value1 AND column <= value2
```

### Numeric Ranges

```sql
-- Products between $50 and $200 (inclusive)
SELECT ProductName, Price
FROM Products
WHERE Price BETWEEN 50 AND 200;

-- Same as:
WHERE Price >= 50 AND Price <= 200;
```

**Visual:**
```
Price Range [50 - 200]:

$25    ❌ (too low)
$50    ✅ (at minimum)
$100   ✅ (in range)
$200   ✅ (at maximum)
$300   ❌ (too high)
```

### Date Ranges

```sql
-- Orders from Q1 2024
SELECT * FROM Orders
WHERE OrderDate BETWEEN '2024-01-01' AND '2024-03-31';

-- Last 30 days
SELECT * FROM Orders
WHERE OrderDate BETWEEN DATEADD(DAY, -30, GETDATE()) AND GETDATE();
```

### NOT BETWEEN

```sql
-- Products NOT in mid-price range
SELECT ProductName, Price
FROM Products
WHERE Price NOT BETWEEN 100 AND 500;

-- Gets: Price < 100 OR Price > 500
```

---

## Part 7: IN - Membership Conditions

### IN Syntax

```sql
WHERE column IN (value1, value2, value3, ...)
```

**Equivalent to multiple ORs:**
```sql
WHERE column = value1 OR column = value2 OR column = value3
```

### Examples

```sql
-- Products in specific categories
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (1, 2, 3);

-- Same as:
WHERE CategoryID = 1 
   OR CategoryID = 2 
   OR CategoryID = 3;
```

**Much cleaner than OR!**

### Text Lists

```sql
-- Customers from specific countries
SELECT FirstName, LastName, Country
FROM Customers
WHERE Country IN ('USA', 'UK', 'Canada', 'Australia');

-- Orders with specific statuses
SELECT OrderID, Status
FROM Orders
WHERE Status IN ('Pending', 'Processing', 'Shipped');
```

### NOT IN

```sql
-- Exclude specific categories
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID NOT IN (1, 2);

-- Exclude test customers
SELECT * FROM Customers
WHERE Email NOT IN (
    'test@example.com',
    'admin@example.com',
    'demo@example.com'
);
```

### IN with Subquery

```sql
-- Customers who have placed orders
SELECT * FROM Customers
WHERE CustomerID IN (
    SELECT DISTINCT CustomerID FROM Orders
);

-- Products never ordered
SELECT * FROM Products
WHERE ProductID NOT IN (
    SELECT ProductID FROM OrderDetails
);
```

---

## Part 8: LIKE - Pattern Matching

### Wildcards

| Wildcard | Meaning | Example |
|----------|---------|---------|
| `%` | Zero or more characters | `'%laptop%'` |
| `_` | Exactly one character | `'_at'` → cat, bat, hat |

### Starts With

```sql
-- Products starting with 'Lap'
SELECT ProductName FROM Products
WHERE ProductName LIKE 'Lap%';

-- Results: Laptop, Laptop Pro, Lapton
```

### Ends With

```sql
-- Products ending with 'phone'
SELECT ProductName FROM Products
WHERE ProductName LIKE '%phone';

-- Results: iPhone, Smartphone, Headphone
```

### Contains

```sql
-- Products containing 'top'
SELECT ProductName FROM Products
WHERE ProductName LIKE '%top%';

-- Results: Laptop, Desktop, Stop Sign, Topaz
```

### Exact Length

```sql
-- Product codes exactly 4 characters
SELECT ProductCode FROM Products
WHERE ProductCode LIKE '____';  -- 4 underscores

-- Matches: A123, XYZW, 4567
-- Doesn't match: AB1, ABCDE
```

### Combine Wildcards

```sql
-- Product names: starts with L, ends with top
SELECT ProductName FROM Products
WHERE ProductName LIKE 'L%top';

-- Matches: Laptop, Limitedtop
-- Doesn't match: Desktop (doesn't start with L)
```

### NOT LIKE

```sql
-- Products NOT containing 'test'
SELECT ProductName FROM Products
WHERE ProductName NOT LIKE '%test%';

-- Exclude email domains
SELECT Email FROM Customers
WHERE Email NOT LIKE '%@test.com'
  AND Email NOT LIKE '%@example.com';
```

### Case Sensitivity

```sql
-- SQL Server: NOT case-sensitive by default
WHERE ProductName LIKE 'laptop'  -- Matches: Laptop, LAPTOP, LaPtOp

-- Make case-sensitive (if needed)
WHERE ProductName COLLATE Latin1_General_CS_AS LIKE 'laptop'
```

---

## Part 9: NULL Handling

### What is NULL?

**NULL = unknown or missing value**

```
NULL is NOT:
  ❌ Zero (0)
  ❌ Empty string ('')
  ❌ FALSE
  
NULL is: Unknown/Missing data
```

### IS NULL

```sql
-- Products with no supplier
SELECT ProductName, SupplierID
FROM Products
WHERE SupplierID IS NULL;

-- Customers with no email
SELECT FirstName, LastName, Email
FROM Customers
WHERE Email IS NULL;
```

### IS NOT NULL

```sql
-- Products that HAVE a supplier
SELECT ProductName, SupplierID
FROM Products
WHERE SupplierID IS NOT NULL;

-- Customers with email addresses
SELECT * FROM Customers
WHERE Email IS NOT NULL;
```

### Common Mistake

```sql
-- ❌ WRONG (doesn't work with NULL)
WHERE SupplierID = NULL

-- ✅ CORRECT
WHERE SupplierID IS NULL
```

**Why? NULL comparisons always return UNKNOWN, not TRUE/FALSE.**

### NULL in Conditions

```sql
-- NULL AND TRUE = NULL (excluded from results)
-- NULL OR TRUE = TRUE (included in results)

SELECT ProductName, SupplierID
FROM Products
WHERE SupplierID = 5 OR SupplierID IS NULL;
```

---

## Part 10: Real-World Examples

### Example 1: E-Commerce Product Search

```sql
-- Find available electronics under $1000
SELECT 
    ProductName,
    Price,
    StockQuantity,
    CategoryID
FROM Products
WHERE CategoryID = 1              -- Electronics
  AND Price < 1000                -- Under $1000
  AND StockQuantity > 0           -- In stock
  AND IsActive = 1                -- Active listings
  AND SupplierID IS NOT NULL;     -- Has supplier
```

### Example 2: Customer Segmentation

```sql
-- Find VIP customers: USA/UK, high spending, recent activity
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Country,
    TotalSpent,
    LastOrderDate
FROM Customers
WHERE Country IN ('USA', 'UK')
  AND TotalSpent > 10000
  AND LastOrderDate >= DATEADD(MONTH, -6, GETDATE())
  AND Email IS NOT NULL;
```

### Example 3: Inventory Alerts

```sql
-- Low stock OR expensive out-of-stock items
SELECT 
    ProductName,
    Price,
    StockQuantity,
    ReorderLevel
FROM Products
WHERE (StockQuantity < ReorderLevel AND StockQuantity > 0)  -- Low stock
   OR (StockQuantity = 0 AND Price > 500);                  -- Expensive out-of-stock
```

### Example 4: Order Status Report

```sql
-- Recent orders NOT shipped yet
SELECT 
    OrderID,
    OrderDate,
    Status,
    TotalAmount
FROM Orders
WHERE OrderDate >= DATEADD(DAY, -7, GETDATE())  -- Last 7 days
  AND Status NOT IN ('Shipped', 'Delivered', 'Cancelled')
  AND TotalAmount > 100
ORDER BY OrderDate DESC;
```

---

## Part 11: Performance Tips

### DO: Use Indexed Columns

```sql
-- ✅ GOOD: CustomerID likely indexed
WHERE CustomerID = 123;

-- ✅ GOOD: OrderDate with index scan
WHERE OrderDate >= '2024-01-01';
```

### DON'T: Functions on Columns

```sql
-- ❌ BAD: Function prevents index use
WHERE YEAR(OrderDate) = 2024;

-- ✅ GOOD: Allows index use
WHERE OrderDate >= '2024-01-01' 
  AND OrderDate < '2025-01-01';
```

### DON'T: Leading Wildcards

```sql
-- ❌ BAD: Can't use index
WHERE ProductName LIKE '%laptop';

-- ✅ GOOD: Can use index
WHERE ProductName LIKE 'laptop%';
```

### DO: Filter Early

```sql
-- ✅ GOOD: Filter before expensive operations
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 1  -- Filter first
  AND Price > 100;

-- Process fewer rows = faster
```

---

## Practice Exercises

### Exercise 1: Basic Filtering
```sql
-- 1. Find products priced between $50 and $200
-- 2. Find customers from USA, Canada, or Mexico
-- 3. Find products containing 'phone' in the name
-- 4. Find products with NULL supplier

-- Write your solutions:
```

### Exercise 2: Complex Conditions
```sql
-- 5. Find electronics (CategoryID=1) under $500 OR clothing (CategoryID=2) over $100
-- 6. Find products NOT in categories 1, 2, or 3
-- 7. Find customers whose email does NOT end with '@gmail.com' or '@yahoo.com'

-- Write your solutions:
```

### Exercise 3: Real-World Scenario
```sql
-- Create a query to find:
-- - Active products (IsActive=1)
-- - Either:
--   * In stock (StockQuantity > 0) AND price under $100
--   * OR out of stock (StockQuantity = 0) AND priority reorder (ReorderLevel > 50)
-- - NOT discontinued
-- - With valid supplier (SupplierID IS NOT NULL)

-- Write your solution:
```

---

## Key Takeaways

### Logical Operators
```
AND  → ALL conditions must be TRUE
OR   → AT LEAST ONE condition must be TRUE
NOT  → Reverses TRUE/FALSE
```

### Special Operators
```
BETWEEN       → Range (inclusive)
IN            → List membership
LIKE          → Pattern matching
IS NULL       → Check for NULL
IS NOT NULL   → Check for non-NULL
```

### Wildcards
```
%  → Zero or more characters
_  → Exactly one character
```

### Best Practices
```
✓ Always use parentheses with AND/OR
✓ Use IS NULL, not = NULL
✓ Use IN for multiple values (not multiple ORs)
✓ Use BETWEEN for ranges
✓ Put most restrictive filters first
✗ Don't use functions on indexed columns
✗ Don't use leading wildcards (LIKE '%value')
```

---

## Quick Reference

```sql
-- Comparison
WHERE Price = 100
WHERE Price <> 100
WHERE Price > 100
WHERE Price BETWEEN 50 AND 200

-- Logical
WHERE Price > 100 AND StockQuantity > 0
WHERE CategoryID = 1 OR CategoryID = 2
WHERE NOT CategoryID = 1

-- Membership
WHERE CategoryID IN (1, 2, 3)
WHERE CategoryID NOT IN (4, 5)

-- Pattern
WHERE ProductName LIKE 'Lap%'          -- Starts with
WHERE ProductName LIKE '%top'          -- Ends with
WHERE ProductName LIKE '%top%'         -- Contains

-- NULL
WHERE SupplierID IS NULL
WHERE Email IS NOT NULL

-- Complex
WHERE (Price > 500 AND CategoryID = 1)
   OR (Price > 1000 AND CategoryID = 2);
```

---

## Next Lesson

**Continue to [Lesson 2: SQL Joins - Basics](../02-sql-joins-basics/)**  
Learn to combine data from multiple tables using INNER JOIN.

---

## Additional Resources

- **WHERE Clause:** https://docs.microsoft.com/sql/t-sql/queries/where
- **Logical Operators:** https://docs.microsoft.com/sql/t-sql/language-elements/logical-operators
- **LIKE:** https://docs.microsoft.com/sql/t-sql/language-elements/like

**Excellent work! You've mastered advanced filtering techniques! 🎯**
