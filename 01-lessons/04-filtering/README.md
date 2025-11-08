# Chapter 04: Filtering - Master the WHERE Clause

## 📋 Chapter Overview

Welcome to Chapter 04! This chapter takes your WHERE clause skills to the next level with advanced filtering techniques, complex conditions, and pattern matching.

**What You'll Learn:**
- 🎯 How SQL evaluates conditions
- 🔢 Building complex filter logic
- 📊 Range and membership conditions
- 🔍 Advanced pattern matching
- ❓ NULL value handling mastery

**Estimated Time:** 3-4 hours  
**Difficulty:** Beginner to Intermediate  
**Prerequisites:** Chapter 03 completed (basic WHERE clause knowledge)

---

## 🎯 Learning Objectives

By the end of this chapter, you will be able to:

✅ Understand how SQL evaluates filter conditions  
✅ Build complex conditions with AND, OR, NOT  
✅ Use parentheses to control logic order  
✅ Apply range conditions (BETWEEN, comparison operators)  
✅ Check membership (IN, NOT IN)  
✅ Master pattern matching (LIKE, wildcards)  
✅ Handle NULL values correctly  
✅ Write production-ready filter queries  

---

## 📚 Lessons - Follow This Path!

### 🎯 Part 1: Understanding Conditions (20 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 1 | **Condition Evaluation** | `01-condition-evaluation.sql` | `01-condition-evaluation-guide.md` | 10 min |
| 2 | **Using Parentheses** | `02-using-parentheses.sql` | `02-using-parentheses-guide.md` | 5 min |
| 3 | **NOT Operator** | `03-not-operator.sql` | `03-not-operator-guide.md` | 5 min |

---

### 🔧 Part 2: Building Conditions (30 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 4 | **Building Conditions** | `04-building-conditions.sql` | `04-building-conditions-guide.md` | 15 min |
| 5 | **Equality Conditions** | `05-equality-conditions.sql` | `05-equality-conditions-guide.md` | 15 min |

---

### 📊 Part 3: Advanced Filtering (45 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 6 | **Range Conditions** | `06-range-conditions.sql` | `06-range-conditions-guide.md` | 15 min |
| 7 | **Membership Conditions** | `07-membership-conditions.sql` | `07-membership-conditions-guide.md` | 15 min |
| 8 | **Matching Conditions** | `08-matching-conditions.sql` | `08-matching-conditions-guide.md` | 15 min |

---

### ❓ Part 4: NULL & Practice (25 min)

| # | Lesson | SQL Script | Guide | Time |
|---|--------|------------|-------|------|
| 9 | **NULL Handling** | `09-null-handling.sql` | `09-null-handling-guide.md` | 10 min |
| 10 | **Practice Exercises** | `10-test-your-knowledge.sql` | - | 15 min |

---

## 🗺️ Visual Learning Path

```
START HERE
    ↓
1️⃣ How Conditions Are Evaluated
    ↓
2️⃣ Control Logic with Parentheses
    ↓
3️⃣ Reverse Conditions with NOT
    ↓
4️⃣ Build Complex Conditions
    ↓
5️⃣ Equality Checks (=, <>, !=)
    ↓
6️⃣ Range Checks (BETWEEN, >, <)
    ↓
7️⃣ Membership (IN, NOT IN)
    ↓
8️⃣ Pattern Matching (LIKE, wildcards)
    ↓
9️⃣ Handle NULL Values
    ↓
🔟 PRACTICE: Master Filtering
    ↓
✅ COMPLETE!
    ↓
NEXT: Chapter 05 - Multi-Table Queries
```

---

## 🎓 Condition Evaluation Basics

### How SQL Evaluates WHERE:

```sql
SELECT * FROM Products
WHERE Price > 100 AND CategoryID = 1;
```

**Step-by-step:**
1. SQL reads each row from Products
2. For each row, evaluates: `Price > 100`
3. If TRUE, evaluates: `CategoryID = 1`
4. If BOTH are TRUE, includes the row
5. Returns all matching rows

### Truth Values:

```
TRUE     → Condition met, include row
FALSE    → Condition not met, exclude row
NULL     → Unknown result, exclude row (treated as FALSE)
```

---

## 🔗 Logical Operators Quick Reference

| Operator | Meaning | Example | Result |
|----------|---------|---------|--------|
| **AND** | All must be TRUE | `TRUE AND TRUE` | `TRUE` |
| **OR** | At least one TRUE | `TRUE OR FALSE` | `TRUE` |
| **NOT** | Reverse the result | `NOT TRUE` | `FALSE` |

### Truth Tables:

**AND:**
```
TRUE  AND TRUE  = TRUE
TRUE  AND FALSE = FALSE
FALSE AND TRUE  = FALSE
FALSE AND FALSE = FALSE
```

**OR:**
```
TRUE  OR TRUE  = TRUE
TRUE  OR FALSE = TRUE
FALSE OR TRUE  = TRUE
FALSE OR FALSE = FALSE
```

**NOT:**
```
NOT TRUE  = FALSE
NOT FALSE = TRUE
NOT NULL  = NULL
```

---

## 📊 Condition Types Overview

### 1. Equality Conditions
```sql
WHERE Price = 100
WHERE CategoryName = 'Electronics'
WHERE IsActive = 1
```

### 2. Range Conditions
```sql
WHERE Price BETWEEN 50 AND 200
WHERE Price > 100
WHERE OrderDate >= '2025-01-01'
```

### 3. Membership Conditions
```sql
WHERE CategoryID IN (1, 2, 3)
WHERE Country IN ('USA', 'UK', 'Canada')
WHERE ProductID NOT IN (SELECT ProductID FROM Discontinued)
```

### 4. Matching Conditions (Patterns)
```sql
WHERE ProductName LIKE 'Lap%'           -- Starts with
WHERE Email LIKE '%@gmail.com'          -- Ends with
WHERE ProductName LIKE '%top%'          -- Contains
WHERE Phone LIKE '555-____'             -- Exact pattern
```

### 5. NULL Conditions
```sql
WHERE SupplierID IS NULL
WHERE SupplierID IS NOT NULL
WHERE ISNULL(SupplierID, 0) = 0
```

---

## 🎨 Real-World Filtering Examples

### Example 1: E-commerce Product Search
```sql
-- Find laptops between $500-$1500, in stock, from specific brands
SELECT 
    ProductName,
    Price,
    StockQuantity,
    SupplierName
FROM Products p
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
WHERE ProductName LIKE '%Laptop%'
  AND Price BETWEEN 500 AND 1500
  AND StockQuantity > 0
  AND s.SupplierName IN ('Dell', 'HP', 'Lenovo')
ORDER BY Price;
```

### Example 2: Customer Segmentation
```sql
-- Find high-value customers from specific regions
SELECT 
    FirstName + ' ' + LastName AS CustomerName,
    Country,
    TotalSpent = (SELECT SUM(Quantity * UnitPrice) 
                  FROM OrderDetails od
                  JOIN Orders o ON od.OrderID = o.OrderID
                  WHERE o.CustomerID = c.CustomerID)
FROM Customers c
WHERE Country IN ('USA', 'UK', 'Canada', 'Australia')
  AND Email IS NOT NULL
  AND (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) >= 3
ORDER BY TotalSpent DESC;
```

### Example 3: Inventory Alert
```sql
-- Low stock items that need reordering
SELECT 
    ProductName,
    CategoryName,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'OUT OF STOCK - URGENT'
        WHEN StockQuantity < 10 THEN 'CRITICAL'
        WHEN StockQuantity < 30 THEN 'LOW'
    END AS AlertLevel
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE StockQuantity < 30
  AND p.SupplierID IS NOT NULL  -- Must have supplier
  AND p.ProductName NOT LIKE '%Discontinued%'
ORDER BY StockQuantity;
```

---

## 💡 Common Filtering Patterns

### Pattern 1: Date Ranges
```sql
-- Orders in last 30 days
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE())

-- Orders in specific month
WHERE YEAR(OrderDate) = 2025 AND MONTH(OrderDate) = 1

-- Orders in date range
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31'
```

### Pattern 2: Text Search
```sql
-- Case-insensitive search
WHERE LOWER(ProductName) LIKE LOWER('%laptop%')

-- Multiple keywords (any match)
WHERE ProductName LIKE '%laptop%' 
   OR ProductName LIKE '%notebook%'
   OR ProductName LIKE '%computer%'

-- Exclude certain words
WHERE ProductName LIKE '%phone%'
  AND ProductName NOT LIKE '%case%'
  AND ProductName NOT LIKE '%charger%'
```

### Pattern 3: Complex Business Logic
```sql
-- VIP customers: High spend OR many orders
WHERE (TotalSpent > 5000 OR OrderCount > 20)
  AND Country = 'USA'
  AND AccountStatus = 'Active'

-- Promotional eligibility
WHERE (LastOrderDate < DATEADD(MONTH, -6, GETDATE())  -- Inactive 6+ months
       OR OrderCount = 0)                             -- Never ordered
  AND Email IS NOT NULL                               -- Can be contacted
  AND OptOut = 0                                      -- Hasn't opted out
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: NULL Comparison
```sql
-- WRONG:
WHERE SupplierID = NULL

-- CORRECT:
WHERE SupplierID IS NULL
```

### ❌ Mistake 2: Missing Parentheses
```sql
-- WRONG (ambiguous):
WHERE Price > 100 AND CategoryID = 1 OR CategoryID = 2

-- CORRECT (clear intent):
WHERE Price > 100 AND (CategoryID = 1 OR CategoryID = 2)
```

### ❌ Mistake 3: LIKE Without Wildcards
```sql
-- WRONG (no wildcards = exact match):
WHERE ProductName LIKE 'Laptop'

-- CORRECT (finds "Laptop Pro", "Gaming Laptop", etc.):
WHERE ProductName LIKE '%Laptop%'
```

### ❌ Mistake 4: Date as String
```sql
-- RISKY (depends on server format):
WHERE OrderDate = '01/15/2025'

-- BETTER (ISO format always works):
WHERE OrderDate = '2025-01-15'

-- BEST (explicit conversion):
WHERE CAST(OrderDate AS DATE) = '2025-01-15'
```

---

## 🎯 Performance Tips

### ✅ DO:
```sql
-- Use indexed columns in WHERE
WHERE CustomerID = 123  -- Fast if CustomerID is indexed

-- Filter early
WHERE Price > 100  -- Filter before joining when possible

-- Use BETWEEN for ranges
WHERE Price BETWEEN 50 AND 200  -- Can use index

-- Use EXISTS for subqueries
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)
```

### ❌ DON'T:
```sql
-- Avoid functions on columns (prevents index use)
WHERE YEAR(OrderDate) = 2025  -- Slow on large tables

-- Better:
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2026-01-01'

-- Avoid LIKE with leading wildcard
WHERE ProductName LIKE '%laptop'  -- Can't use index

-- Avoid OR across different columns
WHERE FirstName = 'John' OR LastName = 'Smith'  -- Hard to optimize
```

---

## 📋 Quick Reference - Filter Operators

| Category | Operators | Example |
|----------|-----------|---------|
| **Comparison** | `=`, `<>`, `!=`, `>`, `<`, `>=`, `<=` | `Price > 100` |
| **Logical** | `AND`, `OR`, `NOT` | `Price > 100 AND Stock > 0` |
| **Range** | `BETWEEN`, `NOT BETWEEN` | `Price BETWEEN 50 AND 200` |
| **Membership** | `IN`, `NOT IN` | `CategoryID IN (1,2,3)` |
| **Pattern** | `LIKE`, `NOT LIKE` | `Name LIKE 'A%'` |
| **NULL** | `IS NULL`, `IS NOT NULL` | `SupplierID IS NULL` |
| **Existence** | `EXISTS`, `NOT EXISTS` | `EXISTS (SELECT 1...)` |

---

## 🧪 Wildcard Reference

| Wildcard | Meaning | Example | Matches |
|----------|---------|---------|---------|
| `%` | Zero or more characters | `'A%'` | Apple, Amazon, A |
| `_` | Exactly one character | `'A_'` | At, An (not A or App) |
| `[]` | Any character in brackets | `'[ABC]%'` | Apple, Banana, Cherry |
| `[^]` | NOT any character in brackets | `'[^ABC]%'` | Dog, Egg (not Apple) |
| `[-]` | Character range | `'[A-C]%'` | Apple, Banana, Cherry |

---

## ⏭️ What's Next?

After completing this chapter:

1. ✅ Practice writing 20+ filter queries
2. ✅ Complete all exercises in Lesson 10
3. ✅ Combine filtering with JOINs and GROUP BY
4. ➡️ Move to **Chapter 05: Querying Multiple Tables**

---

## 🎓 Chapter Difficulty Progression

```
Easy       ←→ Moderate ←→ Advanced
Lesson 1-3     Lesson 4-7     Lesson 8-10
Concepts       Techniques     Mastery
```

---

## 📚 Additional Resources

- **WHERE Clause Reference:** [Microsoft Docs](https://docs.microsoft.com/sql/t-sql/queries/where-transact-sql)
- **Pattern Matching:** [LIKE Documentation](https://docs.microsoft.com/sql/t-sql/language-elements/like-transact-sql)
- **NULL Handling:** [IS NULL Reference](https://docs.microsoft.com/sql/t-sql/queries/is-null-transact-sql)

---

## 🧪 Quick Self-Test

Before starting, can you answer:
- ✓ What's the difference between AND and OR?
- ✓ How do you check for NULL values?
- ✓ What does LIKE '%abc%' match?
- ✓ When should you use parentheses?

If unsure, the lessons will teach you!

---

**🚀 Ready to master filtering?** Begin with **Lesson 01: Condition Evaluation**!

**Total Chapter Time:** ~3-4 hours (includes practice)  
**Prerequisite:** Chapter 03 completed
