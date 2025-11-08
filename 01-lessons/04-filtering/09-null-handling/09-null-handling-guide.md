# Lesson 09: NULL Handling - Visual Guide

## What You'll Learn
- What NULL really means
- Why NULL breaks normal comparisons
- Using IS NULL, ISNULL, COALESCE
- Avoiding NULL-related bugs

---

## What is NULL?

```
┌─────────────────────────────────────────────────────┐
│                  NULL = UNKNOWN                     │
│                                                      │
│  NULL is NOT:                                       │
│    • Zero (0)                                       │
│    • Empty string ('')                              │
│    • Space (' ')                                    │
│    • False                                          │
│                                                      │
│  NULL means:                                        │
│    • Value is missing                               │
│    • Value is unknown                               │
│    • Value is not applicable                        │
└─────────────────────────────────────────────────────┘
```

---

## The NULL Problem

### Why NULL = NULL is NOT TRUE!

```
Think of NULL as "I don't know"

Question: Does 5 equal NULL?
Answer: I don't know (NULL has unknown value)
Result: NULL

Question: Does NULL equal NULL?
Answer: I don't know = I don't know?  
        Can't tell if two unknowns are equal!
Result: NULL (not TRUE!)

┌──────────────────┬──────────────────┬──────────┐
│   Comparison     │   Verbal Logic   │  Result  │
├──────────────────┼──────────────────┼──────────┤
│  5 = 5           │  5 equals 5?     │   TRUE   │
│  5 = 10          │  5 equals 10?    │  FALSE   │
│  5 = NULL        │  5 equals ???    │   NULL   │
│  NULL = NULL     │  ??? equals ???  │   NULL   │
│  NULL <> NULL    │  ??? not equal?  │   NULL   │
└──────────────────┴──────────────────┴──────────┘
```

---

## NULL in Comparisons - Visual

```sql
-- Sample Data
┌────┬─────────┬───────┬────────────┐
│ ID │ Product │ Price │ SupplierID │
├────┼─────────┼───────┼────────────┤
│ 1  │ Laptop  │  800  │      1     │
│ 2  │ Mouse   │  25   │      2     │
│ 3  │ Monitor │  300  │     NULL   │  ← No supplier
│ 4  │ Cable   │  NULL │      1     │  ← No price yet
└────┴─────────┴───────┴────────────┘

-- Query: WHERE Price > 100
┌────┬─────────┬───────┬──────────────┬────────┐
│ ID │ Product │ Price │  Price > 100 │ Result │
├────┼─────────┼───────┼──────────────┼────────┤
│ 1  │ Laptop  │  800  │     TRUE     │   ✓    │
│ 2  │ Mouse   │  25   │    FALSE     │        │
│ 3  │ Monitor │  300  │     TRUE     │   ✓    │
│ 4  │ Cable   │  NULL │     NULL     │        │  ← Filtered out!
└────┴─────────┴───────┴──────────────┴────────┘

Row 4 returns NULL (not TRUE), so it's excluded from results!
```

---

## The WRONG Way to Check NULL

### ❌ WRONG: Using = NULL

```sql
WHERE SupplierID = NULL

┌────┬─────────┬────────────┬──────────────────┬────────┐
│ ID │ Product │ SupplierID │ SupplierID=NULL  │ Result │
├────┼─────────┼────────────┼──────────────────┼────────┤
│ 1  │ Laptop  │      1     │      NULL        │        │
│ 2  │ Mouse   │      2     │      NULL        │        │
│ 3  │ Monitor │     NULL   │      NULL        │        │  ← Still NULL!
│ 4  │ Cable   │      1     │      NULL        │        │
└────┴─────────┴────────────┴──────────────────┴────────┘

Returns ZERO rows! NULL = NULL is always NULL, never TRUE.
```

### ✅ CORRECT: Using IS NULL

```sql
WHERE SupplierID IS NULL

┌────┬─────────┬────────────┬────────────────────┬────────┐
│ ID │ Product │ SupplierID │ SupplierID IS NULL │ Result │
├────┼─────────┼────────────┼────────────────────┼────────┤
│ 1  │ Laptop  │      1     │       FALSE        │        │
│ 2  │ Mouse   │      2     │       FALSE        │        │
│ 3  │ Monitor │     NULL   │       TRUE         │   ✓    │
│ 4  │ Cable   │      1     │       FALSE        │        │
└────┴─────────┴────────────┴────────────────────┴────────┘

Returns Row 3! IS NULL properly checks for NULL.
```

---

## NULL Propagation

**Any operation with NULL produces NULL!**

```
┌─────────────────────────┬──────────┐
│      Operation          │  Result  │
├─────────────────────────┼──────────┤
│  5 + NULL               │   NULL   │
│  100 * NULL             │   NULL   │
│  'Hello' + NULL         │   NULL   │
│  SQRT(NULL)             │   NULL   │
│  NULL / 10              │   NULL   │
│  NULL AND TRUE          │   NULL   │
│  NULL OR FALSE          │   NULL   │
└─────────────────────────┴──────────┘
```

### Visual Example: NULL in Calculations

```sql
SELECT Price * 1.15 AS PriceWithTax

┌────┬─────────┬───────┬───────────────┐
│ ID │ Product │ Price │ PriceWithTax  │
├────┼─────────┼───────┼───────────────┤
│ 1  │ Laptop  │  800  │    920.00     │
│ 2  │ Mouse   │   25  │     28.75     │
│ 3  │ Monitor │  300  │    345.00     │
│ 4  │ Cable   │  NULL │     NULL      │  ← NULL * 1.15 = NULL
└────┴─────────┴───────┴───────────────┘
```

---

## ISNULL Function

**Replace NULL with a specific value**

```sql
ISNULL(column, replacement_value)
```

### Visual Example

```sql
SELECT ISNULL(SupplierID, -1) AS SupplierIDOrDefault

┌────┬─────────┬────────────┬──────────────────────┐
│ ID │ Product │ SupplierID │ SupplierIDOrDefault  │
├────┼─────────┼────────────┼──────────────────────┤
│ 1  │ Laptop  │      1     │          1           │
│ 2  │ Mouse   │      2     │          2           │
│ 3  │ Monitor │     NULL   │         -1           │  ← Replaced!
│ 4  │ Cable   │      1     │          1           │
└────┴─────────┴────────────┴──────────────────────┘

NULL is replaced with -1
```

### String Concatenation with ISNULL

```sql
-- ❌ PROBLEM: NULL ruins concatenation
SELECT FirstName + ' ' + LastName AS FullName

┌───────────┬──────────┬───────────┐
│ FirstName │ LastName │  FullName │
├───────────┼──────────┼───────────┤
│ John      │ Smith    │ John Smith│
│ NULL      │ Johnson  │   NULL    │  ← Entire result is NULL!
│ Sarah     │ NULL     │   NULL    │  ← Entire result is NULL!
└───────────┴──────────┴───────────┘

-- ✅ FIX: Use ISNULL
SELECT ISNULL(FirstName, 'Unknown') + ' ' + ISNULL(LastName, 'Unknown') AS FullName

┌───────────┬──────────┬──────────────────┐
│ FirstName │ LastName │     FullName     │
├───────────┼──────────┼──────────────────┤
│ John      │ Smith    │   John Smith     │
│ NULL      │ Johnson  │ Unknown Johnson  │  ← Fixed!
│ Sarah     │ NULL     │ Sarah Unknown    │  ← Fixed!
└───────────┴──────────┴──────────────────┘
```

---

## COALESCE Function

**Return first non-NULL value from a list**

```sql
COALESCE(value1, value2, value3, ..., default)
```

### Visual Example

```sql
SELECT COALESCE(SupplierID, CategoryID, -1) AS FirstNonNull

┌────┬────────────┬────────────┬──────────────┐
│ ID │ SupplierID │ CategoryID │ FirstNonNull │
├────┼────────────┼────────────┼──────────────┤
│ 1  │      1     │      2     │       1      │  ← Supplier exists
│ 2  │     NULL   │      3     │       3      │  ← Use Category
│ 3  │     NULL   │     NULL   │      -1      │  ← Use default
│ 4  │      5     │     NULL   │       5      │  ← Supplier exists
└────┴────────────┴────────────┴──────────────┘

COALESCE checks values left-to-right, returns first non-NULL
```

### ISNULL vs COALESCE

```
┌─────────────────────────────────────────────────────┐
│              ISNULL vs COALESCE                     │
├─────────────────────────────────────────────────────┤
│  ISNULL(value, replacement)                         │
│    • Takes exactly 2 arguments                      │
│    • SQL Server specific                            │
│    • Slightly faster                                │
│                                                      │
│  COALESCE(val1, val2, val3, ...)                    │
│    • Takes multiple arguments                       │
│    • ANSI standard (portable)                       │
│    • More flexible                                  │
└─────────────────────────────────────────────────────┘

-- ISNULL: Only 2 values
ISNULL(Price, 0)

-- COALESCE: Multiple fallbacks
COALESCE(DiscountPrice, RegularPrice, MSRP, 0)
```

---

## NULLIF Function

**Convert specific value to NULL**

```sql
NULLIF(value, value_to_nullify)
```

### Visual Example: Avoid Division by Zero

```sql
-- ❌ PROBLEM: Division by zero error
SELECT Price / StockQuantity

┌────┬───────┬───────┬─────────────┐
│ ID │ Price │ Stock │   Result    │
├────┼───────┼───────┼─────────────┤
│ 1  │  800  │  10   │    80.00    │
│ 2  │  300  │   0   │   ERROR!    │  ← Division by zero!
└────┴───────┴───────┴─────────────┘

-- ✅ FIX: Use NULLIF
SELECT Price / NULLIF(StockQuantity, 0)

┌────┬───────┬───────┬─────────────┐
│ ID │ Price │ Stock │   Result    │
├────┼───────┼───────┼─────────────┤
│ 1  │  800  │  10   │    80.00    │
│ 2  │  300  │   0   │    NULL     │  ← Safe!
└────┴───────┴───────┴─────────────┘

NULLIF(StockQuantity, 0) returns NULL when StockQuantity = 0
```

---

## NULL in AND/OR Logic

### Three-Valued Logic

```
┌─────────────────────────────────────────────────────┐
│               AND with NULL                         │
├───────────┬───────────┬─────────────────────────────┤
│     A     │     B     │        A AND B              │
├───────────┼───────────┼─────────────────────────────┤
│   TRUE    │   TRUE    │         TRUE                │
│   TRUE    │   FALSE   │        FALSE                │
│   TRUE    │   NULL    │         NULL                │
│   FALSE   │   NULL    │        FALSE  ← Important!  │
│   NULL    │   NULL    │         NULL                │
└───────────┴───────────┴─────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│               OR with NULL                          │
├───────────┬───────────┬─────────────────────────────┤
│     A     │     B     │         A OR B              │
├───────────┼───────────┼─────────────────────────────┤
│   TRUE    │   TRUE    │         TRUE                │
│   TRUE    │   FALSE   │         TRUE                │
│   TRUE    │   NULL    │         TRUE  ← Important!  │
│   FALSE   │   NULL    │         NULL                │
│   NULL    │   NULL    │         NULL                │
└───────────┴───────────┴─────────────────────────────┘
```

### Visual Example

```sql
WHERE Price > 100 AND SupplierID = 1

┌────┬───────┬────────────┬───────────┬─────────────┬────────┐
│ ID │ Price │ SupplierID │ Price>100 │ Supplier=1  │ Result │
├────┼───────┼────────────┼───────────┼─────────────┼────────┤
│ 1  │  800  │      1     │   TRUE    │    TRUE     │  TRUE✓ │
│ 2  │  150  │     NULL   │   TRUE    │    NULL     │  NULL  │
│ 3  │  NULL │      1     │   NULL    │    TRUE     │  NULL  │
│ 4  │   50  │     NULL   │   FALSE   │    NULL     │ FALSE  │
└────┴───────┴────────────┴───────────┴─────────────┴────────┘

Rows 2 & 3 are filtered out (NULL is not TRUE)
```

---

## NULL in Aggregates

**Most aggregate functions IGNORE NULL!**

```sql
-- Sample Data
┌────┬───────┐
│ ID │ Price │
├────┼───────┤
│ 1  │  100  │
│ 2  │  200  │
│ 3  │  NULL │
│ 4  │  300  │
│ 5  │  NULL │
└────┴───────┘

-- Aggregate Results
┌────────────────────┬─────────┬─────────────────────┐
│     Function       │ Result  │     Explanation     │
├────────────────────┼─────────┼─────────────────────┤
│  COUNT(*)          │    5    │  All rows           │
│  COUNT(Price)      │    3    │  Non-NULL only      │
│  SUM(Price)        │   600   │  100+200+300        │
│  AVG(Price)        │   200   │  600/3 (not 600/5!) │
│  MAX(Price)        │   300   │  Ignores NULL       │
│  MIN(Price)        │   100   │  Ignores NULL       │
└────────────────────┴─────────┴─────────────────────┘

⚠️  AVG ignores NULL: 600/3 = 200 (not 600/5 = 120)
```

---

## NULL in ORDER BY

```sql
-- Sample Data
┌────┬─────────┬────────────┐
│ ID │ Product │ SupplierID │
├────┼─────────┼────────────┤
│ 1  │ Laptop  │      3     │
│ 2  │ Mouse   │      1     │
│ 3  │ Monitor │     NULL   │
│ 4  │ Cable   │      2     │
│ 5  │ Keyboard│     NULL   │
└────┴─────────┴────────────┘

-- ORDER BY SupplierID ASC (NULLs first)
┌────┬──────────┬────────────┐
│ ID │ Product  │ SupplierID │
├────┼──────────┼────────────┤
│ 3  │ Monitor  │    NULL    │  ← NULLs first
│ 5  │ Keyboard │    NULL    │  ← NULLs first
│ 2  │ Mouse    │      1     │
│ 4  │ Cable    │      2     │
│ 1  │ Laptop   │      3     │
└────┴──────────┴────────────┘

-- ORDER BY SupplierID DESC (NULLs last)
┌────┬──────────┬────────────┐
│ ID │ Product  │ SupplierID │
├────┼──────────┼────────────┤
│ 1  │ Laptop   │      3     │
│ 4  │ Cable    │      2     │
│ 2  │ Mouse    │      1     │
│ 3  │ Monitor  │    NULL    │  ← NULLs last
│ 5  │ Keyboard │    NULL    │  ← NULLs last
└────┴──────────┴────────────┘
```

---

## Common NULL Mistakes

### Mistake #1: Using = NULL

```sql
-- ❌ WRONG
WHERE SupplierID = NULL      -- Returns nothing!

-- ✅ CORRECT
WHERE SupplierID IS NULL
```

### Mistake #2: Forgetting NULL in concatenation

```sql
-- ❌ WRONG
SELECT FirstName + ' ' + LastName    -- NULL if either is NULL

-- ✅ CORRECT
SELECT CONCAT(FirstName, ' ', LastName)  -- CONCAT treats NULL as empty
-- OR
SELECT ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')
```

### Mistake #3: NOT IN with NULL

```sql
-- ❌ DANGEROUS: Returns ZERO rows if subquery has any NULL!
SELECT * FROM Customers 
WHERE CustomerID NOT IN (SELECT CustomerID FROM Orders)

-- ✅ FIX 1: Filter NULLs
SELECT * FROM Customers 
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Orders WHERE CustomerID IS NOT NULL
)

-- ✅ FIX 2: Use NOT EXISTS (better!)
SELECT * FROM Customers c
WHERE NOT EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID)
```

---

## Key Takeaways

```
✅ DO:
  • Use IS NULL / IS NOT NULL (never = NULL)
  • Use ISNULL or COALESCE for defaults
  • Remember aggregates ignore NULL
  • Test for NULL separately in conditions
  • Use CONCAT for NULL-safe concatenation

❌ DON'T:
  • Use = NULL or <> NULL
  • Forget NULL propagation in calculations
  • Use NOT IN with potentially NULL subqueries
  • Assume NULL = 0 or NULL = ''
  • Ignore NULL in business logic
```

---

## Quick Reference

```sql
-- Check for NULL
WHERE column IS NULL
WHERE column IS NOT NULL

-- Replace NULL
ISNULL(column, default)
COALESCE(col1, col2, col3, default)

-- Convert to NULL
NULLIF(column, value_to_nullify)

-- NULL-safe operations
CONCAT(col1, col2)           -- Treats NULL as empty string
ISNULL(col1, '') + col2      -- Manual replacement
```

---

**Next:** [Lesson 10 - Test Your Knowledge](../10-test-your-knowledge/10-test-your-knowledge.sql)
