# Chapter 07: Data Generation and Manipulation

## Overview
Learn how to generate, transform, and manipulate data in SQL. This chapter covers working with strings, numbers, and dates/times - essential skills for real-world data processing.

---

## Learning Objectives

By the end of this chapter, you will be able to:

1. **Generate and manipulate string data** using built-in functions
2. **Perform arithmetic operations** and understand precision
3. **Work with temporal data** (dates and times) effectively
4. **Convert between data types** safely and correctly
5. **Handle time zones** and temporal calculations
6. **Apply functions** to transform data in queries
7. **Combine multiple functions** for complex transformations
8. **Understand data type compatibility** and casting

---

## Chapter Structure

```
┌─────────────────────────────────────────────────────┐
│         Chapter 07 Learning Path                    │
│         (Estimated: 4 hours)                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Foundation (Strings)                                │
│  ├─ 01. String Generation        (20 min)          │
│  └─ 02. String Manipulation      (25 min)          │
│                                                      │
│  Numbers                                             │
│  ├─ 03. Arithmetic Functions     (20 min)          │
│  ├─ 04. Number Precision         (25 min)          │
│  └─ 05. Signed Data              (20 min)          │
│                                                      │
│  Temporal Data (Dates & Times)                      │
│  ├─ 06. Time Zones               (25 min)          │
│  ├─ 07. Temporal Generation      (25 min)          │
│  └─ 08. Temporal Manipulation    (30 min)          │
│                                                      │
│  Advanced                                            │
│  ├─ 09. Conversion Functions     (30 min)          │
│  └─ 10. Test Your Knowledge      (60 min)          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Database Schema

We'll continue using the **RetailStore** database:

```sql
/*
┌──────────────────────────────────────────────────┐
│              RetailStore Schema                  │
├──────────────────────────────────────────────────┤
│                                                   │
│  Categories                 Products              │
│  ├─ CategoryID (PK)        ├─ ProductID (PK)    │
│  ├─ CategoryName           ├─ ProductName        │
│  └─ Description            ├─ Description        │
│                             ├─ Price              │
│  Customers                  ├─ Stock              │
│  ├─ CustomerID (PK)        └─ CategoryID (FK)    │
│  ├─ FirstName                                     │
│  ├─ LastName               Orders                 │
│  ├─ Email                  ├─ OrderID (PK)       │
│  ├─ Phone                  ├─ CustomerID (FK)    │
│  ├─ City                   ├─ OrderDate          │
│  └─ State                  └─ TotalAmount         │
│                                                   │
│  OrderDetails              Employees              │
│  ├─ OrderDetailID (PK)     ├─ EmployeeID (PK)   │
│  ├─ OrderID (FK)           ├─ FirstName          │
│  ├─ ProductID (FK)         ├─ LastName           │
│  ├─ Quantity               ├─ HireDate           │
│  └─ UnitPrice              ├─ Salary             │
│                             └─ ManagerID (FK)     │
└──────────────────────────────────────────────────┘
*/
```

---

## Function Categories Overview

### String Functions

```sql
-- String Generation
'Hello' + ' ' + 'World'         → 'Hello World'
CONCAT('SQL', ' ', 'Server')    → 'SQL Server'
REPLICATE('*', 5)               → '*****'
SPACE(3)                        → '   '

-- String Manipulation
UPPER('hello')                  → 'HELLO'
LOWER('HELLO')                  → 'hello'
SUBSTRING('Hello', 1, 3)        → 'Hel'
LEN('Hello')                    → 5
TRIM('  text  ')                → 'text'
REPLACE('Hello', 'l', 'L')      → 'HeLLo'
```

### Arithmetic Functions

```sql
-- Basic Math
ABS(-10)                        → 10
ROUND(123.456, 2)               → 123.46
CEILING(4.3)                    → 5
FLOOR(4.9)                      → 4
POWER(2, 3)                     → 8
SQRT(16)                        → 4

-- Precision
CAST(10 AS DECIMAL(10,2))       → 10.00
CONVERT(DECIMAL(10,2), 10)      → 10.00
```

### Temporal Functions

```sql
-- Current Date/Time
GETDATE()                       → Current datetime
GETUTCDATE()                    → Current UTC datetime
SYSDATETIME()                   → High precision

-- Extraction
YEAR('2025-11-08')              → 2025
MONTH('2025-11-08')             → 11
DAY('2025-11-08')               → 8
DATEPART(HOUR, GETDATE())       → Current hour

-- Manipulation
DATEADD(DAY, 7, GETDATE())      → 7 days from now
DATEDIFF(DAY, '2025-01-01', GETDATE()) → Days since Jan 1
```

---

## Common Use Cases

### Use Case 1: Name Formatting

```sql
-- Format customer names
SELECT 
    CustomerID,
    UPPER(LEFT(FirstName, 1)) + LOWER(SUBSTRING(FirstName, 2, 100)) + ' ' +
    UPPER(LEFT(LastName, 1)) + LOWER(SUBSTRING(LastName, 2, 100)) AS FullName,
    -- john smith → John Smith
    CONCAT(
        SUBSTRING(FirstName, 1, 1),
        SUBSTRING(LastName, 1, 1)
    ) AS Initials
    -- John Smith → JS
FROM Customers;
```

### Use Case 2: Price Calculations

```sql
-- Calculate discounts and taxes
SELECT 
    ProductID,
    ProductName,
    Price AS OriginalPrice,
    ROUND(Price * 0.85, 2) AS DiscountedPrice,      -- 15% off
    ROUND(Price * 0.85 * 1.08, 2) AS FinalPrice,    -- + 8% tax
    CAST(ROUND(Price * 0.15, 2) AS DECIMAL(10,2)) AS Savings
FROM Products
WHERE Price > 100;
```

### Use Case 3: Date Calculations

```sql
-- Customer tenure and ordering patterns
SELECT 
    CustomerID,
    FirstName + ' ' + LastName AS CustomerName,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS DaysBetweenOrders,
    DATEDIFF(MONTH, MIN(OrderDate), GETDATE()) AS MonthsAsCustomer,
    COUNT(*) AS TotalOrders
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(*) >= 3;
```

---

## Performance Considerations

```
┌─────────────────────────────────────────────────┐
│          Function Performance Tips              │
├─────────────────────────────────────────────────┤
│                                                  │
│  ✓ DO:                                          │
│  • Filter before applying functions             │
│  • Use built-in functions over UDFs             │
│  • Cache complex calculations                   │
│  • Consider computed columns for frequent use   │
│                                                  │
│  ✗ AVOID:                                       │
│  • Functions in WHERE clause on indexed columns │
│  • Nested function calls without necessity      │
│  • String concatenation in tight loops          │
│  • CAST/CONVERT on millions of rows             │
│                                                  │
│  Example - BAD:                                 │
│  WHERE YEAR(OrderDate) = 2025                   │
│  → Can't use index on OrderDate                 │
│                                                  │
│  Example - GOOD:                                │
│  WHERE OrderDate >= '2025-01-01'                │
│    AND OrderDate < '2026-01-01'                 │
│  → Can use index on OrderDate                   │
└─────────────────────────────────────────────────┘
```

---

## Common Mistakes to Avoid

### Mistake 1: Integer Division

```sql
-- ❌ WRONG: Returns 0 (integer division)
SELECT 5 / 2;                   → 0

-- ✅ CORRECT: Convert to decimal first
SELECT 5.0 / 2;                 → 2.5
SELECT CAST(5 AS DECIMAL) / 2;  → 2.5
```

### Mistake 2: NULL Concatenation

```sql
-- ❌ WRONG: NULL + anything = NULL
SELECT FirstName + ' ' + MiddleName + ' ' + LastName
FROM Customers;
-- If MiddleName is NULL, entire result is NULL!

-- ✅ CORRECT: Handle NULLs
SELECT 
    FirstName + ' ' + 
    ISNULL(MiddleName + ' ', '') + 
    LastName
FROM Customers;
```

### Mistake 3: Date String Formats

```sql
-- ❌ RISKY: Format depends on server settings
SELECT * FROM Orders WHERE OrderDate = '11/08/2025';
-- Is this Nov 8 or Aug 11?

-- ✅ CORRECT: Use ISO format (YYYY-MM-DD)
SELECT * FROM Orders WHERE OrderDate = '2025-11-08';
-- Unambiguous!
```

### Mistake 4: Precision Loss

```sql
-- ❌ WRONG: Loses precision
DECLARE @price DECIMAL(10,2) = 19.99;
SELECT @price * 0.1;            → 1.99 (should be 1.999)

-- ✅ CORRECT: Use appropriate precision
DECLARE @price DECIMAL(10,2) = 19.99;
SELECT CAST(@price * 0.1 AS DECIMAL(10,3));  → 1.999
```

---

## Data Type Quick Reference

### String Types

```sql
CHAR(n)         -- Fixed-length (pads with spaces)
VARCHAR(n)      -- Variable-length (up to n chars)
VARCHAR(MAX)    -- Variable-length (up to 2GB)
NCHAR(n)        -- Unicode fixed-length
NVARCHAR(n)     -- Unicode variable-length
TEXT            -- Legacy (avoid, use VARCHAR(MAX))
```

### Numeric Types

```sql
INT             -- Integers: -2,147,483,648 to 2,147,483,647
BIGINT          -- Large integers: -9 quintillion to +9 quintillion
SMALLINT        -- Small integers: -32,768 to 32,767
TINYINT         -- Tiny integers: 0 to 255
DECIMAL(p,s)    -- Exact numeric: p=precision, s=scale
NUMERIC(p,s)    -- Same as DECIMAL
FLOAT(n)        -- Approximate numeric (avoid for money!)
REAL            -- Smaller float
MONEY           -- Currency: 4 decimal places
```

### Temporal Types

```sql
DATE            -- Date only: YYYY-MM-DD
TIME            -- Time only: HH:MM:SS.nnnnnnn
DATETIME        -- Date + time (precision: 3.33ms)
DATETIME2       -- Date + time (precision: 100ns) ← Prefer this
DATETIMEOFFSET  -- Date + time + timezone offset
SMALLDATETIME   -- Less precise datetime
```

---

## Practice Exercises Preview

In Lesson 10, you'll practice:

1. **String Transformations**: Format names, emails, phone numbers
2. **Mathematical Calculations**: Discounts, taxes, percentages, rounding
3. **Date Arithmetic**: Age calculations, tenure, time differences
4. **Type Conversions**: Safe casting between types
5. **Combined Functions**: Complex multi-step transformations
6. **Real-World Scenarios**: Reports, data cleaning, formatting

---

## Learning Tips

```
💡 TIPS FOR SUCCESS:

1. Experiment in Small Steps
   • Test each function individually
   • Combine gradually
   • Verify results at each step

2. Use SELECT for Testing
   • No need for tables initially
   • SELECT 'Hello' + 'World'
   • SELECT GETDATE()
   • SELECT ROUND(123.456, 2)

3. Read Error Messages
   • "Conversion failed" → Check data types
   • "Arithmetic overflow" → Result too large
   • "Invalid length" → Check function syntax

4. Reference Documentation
   • Each function has specific syntax
   • Optional parameters vary
   • Return types differ

5. Practice with Real Data
   • Use RetailStore database
   • Experiment with customer names
   • Calculate real prices and dates
```

---

## What's Next?

After completing this chapter, you'll be able to:

- ✅ Transform raw data into usable formats
- ✅ Perform complex calculations with confidence
- ✅ Work with dates and times effectively
- ✅ Build professional reports and summaries
- ✅ Clean and standardize data
- ✅ Prepare for advanced aggregation (Chapter 08)

---

## Chapter Summary

| Lesson | Topic | Key Functions | Time |
|--------|-------|---------------|------|
| 01 | String Generation | CONCAT, REPLICATE, SPACE | 20 min |
| 02 | String Manipulation | UPPER, LOWER, SUBSTRING, REPLACE, TRIM | 25 min |
| 03 | Arithmetic Functions | ABS, ROUND, CEILING, FLOOR, POWER | 20 min |
| 04 | Number Precision | DECIMAL, NUMERIC, CAST, Rounding | 25 min |
| 05 | Signed Data | Positive/Negative, ABS, SIGN | 20 min |
| 06 | Time Zones | GETUTCDATE, DATETIMEOFFSET, AT TIME ZONE | 25 min |
| 07 | Temporal Generation | GETDATE, DATEADD, Date construction | 25 min |
| 08 | Temporal Manipulation | DATEDIFF, DATEPART, YEAR, MONTH, DAY | 30 min |
| 09 | Conversion Functions | CAST, CONVERT, TRY_CAST, Format codes | 30 min |
| 10 | Test Your Knowledge | Comprehensive exercises | 60 min |

**Total Time**: ~4 hours

---

**Ready to start?** Begin with [Lesson 01 - String Generation](01-string-generation/01-string-generation.sql)

---

**Need Help?**

- Each lesson has detailed comments and examples
- Test your understanding as you go
- The final test includes an answer key
- Build on what you learned in previous chapters

Happy learning! 🚀
