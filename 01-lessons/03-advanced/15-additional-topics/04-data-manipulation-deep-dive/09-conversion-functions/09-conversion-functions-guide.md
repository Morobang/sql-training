# Conversion Functions Guide

## Overview
Master data type conversions with CAST and CONVERT. Essential for handling user input, formatting output, cleaning data, and preventing errors.

---

## CAST vs CONVERT

### Quick Comparison

```
┌─────────────────────────────────────────────────────────┐
│                    CAST vs CONVERT                      │
├─────────────┬──────────────┬────────────────────────────┤
│ Feature     │ CAST         │ CONVERT                    │
├─────────────┼──────────────┼────────────────────────────┤
│ Standard    │ ANSI SQL ✅  │ SQL Server specific        │
│ Portability │ High         │ Low                        │
│ Style codes │ No           │ Yes ✅                     │
│ Date format │ Default only │ Many formats               │
│ Syntax      │ Simple       │ Flexible                   │
└─────────────┴──────────────┴────────────────────────────┘
```

### When to Use Each

```
Use CAST when:
  ✅ Portability matters (works on other databases)
  ✅ Simple conversions
  ✅ ANSI SQL compliance needed
  ✅ Default format is fine

Use CONVERT when:
  ✅ Need specific date/time formatting
  ✅ SQL Server only
  ✅ Style codes required
  ✅ More control over output
```

---

## CAST Function

### Syntax
```sql
CAST(expression AS data_type)
      │            │
      │            └─ Target type
      └────────────── Value to convert
```

### Common Conversions

#### Number to String
```sql
CAST(123 AS VARCHAR(10))  → '123'
CAST(123.45 AS VARCHAR)   → '123.45'
CAST(-99 AS VARCHAR(5))   → '-99'
```

**Visual:**
```
Number → String

123     → '123'
123.45  → '123.45'
-999    → '-999'
```

#### String to Number
```sql
CAST('123' AS INT)           → 123
CAST('123.45' AS DECIMAL(5,2)) → 123.45
CAST('99' AS FLOAT)          → 99.0
```

**Visual:**
```
String → Number

'123'    → 123
'123.45' → 123.45
'99.99'  → 99.99
```

#### String to Date
```sql
CAST('2025-01-15' AS DATE)              → 2025-01-15
CAST('2025-01-15 14:30:00' AS DATETIME) → 2025-01-15 14:30:00
```

#### Date to String
```sql
CAST(GETDATE() AS VARCHAR(20))  → '2025-01-15 14:30:45'
CAST(GETDATE() AS DATE)         → 2025-01-15
```

---

## CONVERT Function

### Syntax
```sql
CONVERT(data_type, expression [, style])
         │           │           │
         │           │           └─ Optional format code
         │           └───────────── Value to convert
         └───────────────────────── Target type
```

### Date Format Style Codes

#### Common Styles

```
Style | Format           | Example
------|------------------|-------------------
0     | mon dd yyyy      | Jan 15 2025
1     | mm/dd/yyyy       | 01/15/2025
101   | mm/dd/yyyy       | 01/15/2025
103   | dd/mm/yyyy       | 15/01/2025
105   | dd-mm-yyyy       | 15-01-2025
106   | dd mon yyyy      | 15 Jan 2025
107   | mon dd, yyyy     | Jan 15, 2025
110   | mm-dd-yyyy       | 01-15-2025
111   | yyyy/mm/dd       | 2025/01/15
112   | yyyymmdd         | 20250115
120   | yyyy-mm-dd       | 2025-01-15 14:30:45
126   | ISO8601          | 2025-01-15T14:30:45
```

### Visual Examples

```sql
DECLARE @Date DATETIME = '2025-01-15 14:30:45';

CONVERT(VARCHAR, @Date, 101)  → '01/15/2025'     USA
CONVERT(VARCHAR, @Date, 103)  → '15/01/2025'     UK
CONVERT(VARCHAR, @Date, 107)  → 'Jan 15, 2025'   Month DD, YYYY
CONVERT(VARCHAR, @Date, 112)  → '20250115'       Compact
CONVERT(VARCHAR, @Date, 120)  → '2025-01-15 14:30:45'  ODBC
```

**Visual Format Map:**
```
Same Date, Different Formats:

101 (USA):      01/15/2025
103 (UK):       15/01/2025
105 (Italian):  15-01-2025
106 (dd mon):   15 Jan 2025
107 (mon dd,):  Jan 15, 2025
110 (dashes):   01-15-2025
111 (Japan):    2025/01/15
112 (compact):  20250115
120 (ODBC):     2025-01-15 14:30:45
```

---

## TRY_CAST and TRY_CONVERT

### The Problem
```sql
-- ❌ This CRASHES your query!
SELECT CAST('Not a number' AS INT);
-- Error: Conversion failed when converting the varchar value 
--        'Not a number' to data type int.
```

### The Solution
```sql
-- ✅ Returns NULL instead of error
SELECT TRY_CAST('Not a number' AS INT);
-- Result: NULL (no error!)
```

### Visual Comparison

```
Regular CAST/CONVERT:
Input: 'ABC'  →  CAST('ABC' AS INT)  →  💥 ERROR!

Safe TRY_CAST/TRY_CONVERT:
Input: 'ABC'  →  TRY_CAST('ABC' AS INT)  →  NULL ✅
```

### Data Validation Pattern

```sql
SELECT 
    InputValue,
    TRY_CAST(InputValue AS INT) AS ConvertedValue,
    CASE 
        WHEN TRY_CAST(InputValue AS INT) IS NOT NULL 
        THEN 'Valid ✅'
        ELSE 'Invalid ❌'
    END AS Status
FROM UserInput;
```

**Example Results:**
```
InputValue | ConvertedValue | Status
-----------|----------------|----------
'123'      | 123           | Valid ✅
'456'      | 456           | Valid ✅
'ABC'      | NULL          | Invalid ❌
'12.34'    | NULL          | Invalid ❌
''         | NULL          | Invalid ❌
```

---

## Common Conversion Scenarios

### Scenario 1: Clean Currency Strings

```sql
-- Input: '$1,234.56'
-- Goal: 1234.56

SELECT 
    '$1,234.56' AS Original,
    REPLACE(REPLACE('$1,234.56', '$', ''), ',', '') AS Step1,
    CAST(REPLACE(REPLACE('$1,234.56', '$', ''), ',', '') AS DECIMAL(10,2)) AS Final;
```

**Visual Steps:**
```
Step 1: Remove $
  '$1,234.56'  →  '1,234.56'

Step 2: Remove commas
  '1,234.56'   →  '1234.56'

Step 3: Convert to number
  '1234.56'    →  1234.56
```

### Scenario 2: Parse Phone Numbers

```sql
-- Input: '(555) 123-4567'
-- Goal: 5551234567

SELECT 
    '(555) 123-4567' AS Original,
    TRY_CAST(
        REPLACE(REPLACE(REPLACE(REPLACE(
            '(555) 123-4567', 
            '(', ''), ')', ''), '-', ''), ' ', ''
        ) AS BIGINT
    ) AS PhoneNumber;
```

**Visual Steps:**
```
'(555) 123-4567'
  ↓ Remove (
'555) 123-4567'
  ↓ Remove )
'555 123-4567'
  ↓ Remove -
'555 1234567'
  ↓ Remove spaces
'5551234567'
  ↓ Convert to BIGINT
5551234567
```

### Scenario 3: Ambiguous Date Formats

```sql
-- Same string, different interpretations!

SELECT 
    TRY_CONVERT(DATE, '01/02/2025', 101) AS USA_Format,    -- Jan 2
    TRY_CONVERT(DATE, '01/02/2025', 103) AS UK_Format;     -- Feb 1
```

**Visual:**
```
'01/02/2025'
      ↓
      ├── Style 101 (mm/dd/yyyy) → January 2, 2025
      └── Style 103 (dd/mm/yyyy) → February 1, 2025

Different dates! This is why ISO format is safer!
```

---

## FORMAT Function (SQL Server 2012+)

### Number Formatting

```sql
FORMAT(1234567.89, 'N0')   → '1,234,568'      (no decimals)
FORMAT(1234567.89, 'N2')   → '1,234,567.89'   (2 decimals)
FORMAT(1234567.89, 'C')    → '$1,234,567.89'  (currency)
FORMAT(0.85, 'P0')         → '85 %'           (percentage)
```

**Visual:**
```
Value: 1234567.89

Format N0:  1,234,568        (rounded, no decimals)
Format N2:  1,234,567.89     (with decimals)
Format C:   $1,234,567.89    (currency symbol)
Format C0:  $1,234,568       (currency, no decimals)
```

### Custom Patterns

```sql
FORMAT(123, '000000')        → '000123'      (pad with zeros)
FORMAT(1234.5, '0000.00')    → '1234.50'     (fixed width)
FORMAT(1234567, '#,##0')     → '1,234,567'   (thousands separator)
```

**Visual Padding:**
```
Value: 42

'000000'  →  000042  (6 digits, pad left with zeros)
'00000'   →  00042   (5 digits)
'0000'    →  0042    (4 digits)
```

---

## Implicit vs Explicit Conversion

### Implicit (Automatic)

```sql
-- SQL Server automatically converts
SELECT '100' + 200;          → 300 (string becomes number)
SELECT 100 + '200';          → 300 (string becomes number)
```

**But beware:**
```sql
-- ❌ ERROR: Can't convert 'ABC' to number
SELECT '100' + 'ABC';
```

### Explicit (Manual)

```sql
-- ✅ Clear and safe
SELECT CAST('100' AS INT) + CAST('200' AS INT);  → 300
```

### The String Concatenation Trap

```sql
-- Different operators, different results!

'100' + '200'           → '100200'    (string concat)
100 + 200               → 300         (addition)
'100' + 200             → 300         (implicit conversion!)
CONCAT('100', '200')    → '100200'    (explicit string concat)
```

**Visual:**
```
String + String = String
  '100' + '200' = '100200'

Number + Number = Number
  100 + 200 = 300

String + Number = Number (implicit conversion!)
  '100' + 200 = 300

CONCAT always returns String
  CONCAT('100', 200) = '100200'
```

---

## Conversion Best Practices

### ✅ DO:

```sql
-- Use TRY_* for user input
TRY_CAST(UserInput AS INT)  ✅

-- Always specify precision
CAST(Value AS DECIMAL(10,2))  ✅

-- Use ISO date format
'2025-01-15'  ✅

-- Be explicit
CAST(10 AS DECIMAL(10,2)) / 3  ✅
```

### ❌ DON'T:

```sql
-- Don't trust user input
CAST(UserInput AS INT)  ❌ (might error)

-- Don't forget precision
CAST(Value AS DECIMAL)  ❌ (defaults to 18,0)

-- Don't use ambiguous dates
'01/02/2025'  ❌ (Jan 2 or Feb 1?)

-- Don't rely on implicit conversion
10 / 3  ❌ (integer division = 3)
```

---

## Data Quality Validation

### Pattern: Validate Before Import

```sql
CREATE TABLE #ImportData (
    RecordID INT,
    NumericField VARCHAR(50),
    DateField VARCHAR(50),
    AmountField VARCHAR(50)
);

-- Check data quality
SELECT 
    RecordID,
    NumericField,
    CASE WHEN TRY_CAST(NumericField AS INT) IS NOT NULL 
         THEN '✅ Valid' 
         ELSE '❌ Invalid' 
    END AS NumericStatus,
    DateField,
    CASE WHEN TRY_CONVERT(DATE, DateField) IS NOT NULL 
         THEN '✅ Valid' 
         ELSE '❌ Invalid' 
    END AS DateStatus,
    AmountField,
    CASE WHEN TRY_CAST(AmountField AS DECIMAL(10,2)) IS NOT NULL 
         THEN '✅ Valid' 
         ELSE '❌ Invalid' 
    END AS AmountStatus
FROM #ImportData;
```

**Sample Output:**
```
RecordID | NumericField | Status      | DateField  | Status
---------|--------------|-------------|------------|--------
1        | '123'        | ✅ Valid    | '2025-01-15'| ✅ Valid
2        | 'ABC'        | ❌ Invalid  | '2025-01-16'| ✅ Valid
3        | '456'        | ✅ Valid    | 'Bad Date' | ❌ Invalid
```

---

## Common Conversion Errors

### Error 1: Precision Too Small
```sql
-- ❌ ERROR: Arithmetic overflow
CAST(12345.67 AS DECIMAL(5,2))  -- Needs at least (7,2)

-- ✅ CORRECT:
CAST(12345.67 AS DECIMAL(7,2))  → 12345.67
```

### Error 2: Invalid Date Format
```sql
-- ❌ ERROR: Conversion failed
CAST('2025-13-45' AS DATE)  -- No 13th month!

-- ✅ USE TRY_CAST:
TRY_CAST('2025-13-45' AS DATE)  → NULL
```

### Error 3: Non-Numeric String
```sql
-- ❌ ERROR: Conversion failed
CAST('Not a number' AS INT)

-- ✅ USE TRY_CAST:
TRY_CAST('Not a number' AS INT)  → NULL
```

---

## Quick Reference Card

### String ↔ Number
```sql
-- String to Number
CAST('123' AS INT)
TRY_CAST('123' AS DECIMAL(10,2))

-- Number to String
CAST(123 AS VARCHAR)
FORMAT(123.45, 'N2')  → '123.45'
```

### String ↔ Date
```sql
-- String to Date (ISO format)
CAST('2025-01-15' AS DATE)
TRY_CONVERT(DATE, '01/15/2025', 101)

-- Date to String
CONVERT(VARCHAR, GETDATE(), 101)  → '01/15/2025'
CONVERT(VARCHAR, GETDATE(), 120)  → '2025-01-15'
```

### Safe Conversions
```sql
-- Returns NULL on error (no crash!)
TRY_CAST(value AS type)
TRY_CONVERT(type, value, style)
```

---

## Summary

### Key Functions:
1. **CAST** - Standard, portable conversions
2. **CONVERT** - SQL Server specific, with style codes
3. **TRY_CAST** - Safe CAST (returns NULL on error)
4. **TRY_CONVERT** - Safe CONVERT (returns NULL on error)
5. **FORMAT** - Number/date formatting

### Critical Rules:
- ✅ Use **TRY_CAST/TRY_CONVERT** for user input
- ✅ Always specify **DECIMAL precision**
- ✅ Use **ISO date format** ('YYYY-MM-DD')
- ✅ Be **explicit** > implicit
- ✅ **Validate** before converting

### Style Code Favorites:
- **101**: `mm/dd/yyyy` (USA)
- **103**: `dd/mm/yyyy` (UK)
- **120**: `yyyy-mm-dd` (ODBC/ISO)
- **126**: ISO8601 with T

---

**Master conversions = Clean data + No errors!** 🎯

