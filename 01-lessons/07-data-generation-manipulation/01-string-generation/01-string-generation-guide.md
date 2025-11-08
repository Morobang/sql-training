# String Generation Guide

## Overview
Learn to create and build strings from scratch using SQL Server's string generation functions. This is essential for creating formatted output, generating codes, and building dynamic text.

---

## Key Concepts

### 1. String Concatenation

#### Using + Operator
```
'Hello' + ' ' + 'World'
→ 'Hello World'
```

**⚠️ WARNING: NULL Behavior**
```
'Hello' + NULL + 'World'
→ NULL  (entire result is NULL!)
```

#### Using CONCAT Function (NULL-Safe)
```
CONCAT('Hello', NULL, 'World')
→ 'HelloWorld'  (NULLs treated as empty strings)
```

**Visual Comparison:**
```
Input          | + Operator    | CONCAT()
---------------|---------------|-------------
'A', 'B'       | 'AB'         | 'AB'
'A', NULL, 'B' | NULL         | 'AB'  ✅
NULL, NULL     | NULL         | ''
```

---

### 2. REPLICATE Function

**Purpose:** Repeat a string N times

**Syntax:** `REPLICATE(string, count)`

**Examples:**
```sql
REPLICATE('*', 5)           → '*****'
REPLICATE('AB', 3)          → 'ABABAB'
REPLICATE('-', 20)          → '--------------------'
```

**Visual Pattern:**
```
REPLICATE('█', 1)  →  █
REPLICATE('█', 3)  →  ███
REPLICATE('█', 5)  →  █████
REPLICATE('█', 10) →  ██████████
```

**Common Uses:**
- Create divider lines
- Pad strings to fixed width
- Generate visual indicators (progress bars)
- Create patterns

---

### 3. SPACE Function

**Purpose:** Generate N spaces

**Syntax:** `SPACE(count)`

**Examples:**
```sql
'Name:' + SPACE(5) + 'John'
→ 'Name:     John'

'Left' + SPACE(10) + 'Right'
→ 'Left          Right'
```

**Alignment Example:**
```
Without SPACE:
NameJohn
AgeJohn
CityJohn

With SPACE(10):
Name      John
Age       John
City      John
```

---

### 4. CHAR Function

**Purpose:** Generate character from ASCII code

**Syntax:** `CHAR(ascii_code)`

**Common ASCII Codes:**
```
Code | Character | Description
-----|-----------|------------------
9    | Tab       | Horizontal tab
10   | LF        | Line feed (newline)
13   | CR        | Carriage return
32   | Space     | Space character
65   | 'A'       | Uppercase A
97   | 'a'       | Lowercase a
```

**Examples:**
```sql
CHAR(9)               → [TAB]
CHAR(10)              → [LINE FEED]
CHAR(65)              → 'A'
CHAR(65) + CHAR(66)   → 'AB'
```

**Newline Example:**
```sql
'Line 1' + CHAR(10) + 'Line 2'

Output:
Line 1
Line 2
```

---

## Combining Functions

### Example 1: Create Formatted Header
```sql
REPLICATE('=', 50) + CHAR(10) +
'  INVOICE #12345' + CHAR(10) +
REPLICATE('=', 50)
```

**Output:**
```
==================================================
  INVOICE #12345
==================================================
```

### Example 2: Format Name Badge
```sql
REPLICATE('-', 30) + CHAR(10) +
'Name:' + SPACE(5) + 'John Doe' + CHAR(10) +
'Title:' + SPACE(4) + 'Manager' + CHAR(10) +
REPLICATE('-', 30)
```

**Output:**
```
------------------------------
Name:     John Doe
Title:    Manager
------------------------------
```

### Example 3: Generate Barcode Pattern
```sql
REPLICATE('|', 1) + SPACE(1) + 
REPLICATE('|', 2) + SPACE(1) + 
REPLICATE('|', 1) + SPACE(1) + 
REPLICATE('|', 3)
```

**Output:**
```
| || | |||
```

---

## Practical Applications

### 1. Email Template
```sql
'Dear ' + FirstName + ',' + CHAR(10) + CHAR(10) +
'Thank you for your order!' + CHAR(10) + CHAR(10) +
'Order #: ' + OrderNumber + CHAR(10) +
'Total: $' + CAST(Total AS VARCHAR) + CHAR(10) + CHAR(10) +
'Best regards,' + CHAR(10) +
'Customer Service'
```

### 2. Progress Bar
```sql
-- Show 60% completion
REPLICATE('█', 6) + REPLICATE('░', 4) + ' 60%'
```

**Output:**
```
██████░░░░ 60%
```

### 3. Column Alignment
```sql
'ID' + SPACE(5) + 'Name' + SPACE(20) + 'Amount'
```

**Output:**
```
ID     Name                    Amount
```

---

## Common Patterns

### Pattern 1: Fixed-Width Fields
```sql
-- Create fixed 10-character field
ProductCode + SPACE(10 - LEN(ProductCode))
```

**Example:**
```
Input    | Output (10 chars)
---------|------------------
'ABC'    | 'ABC       '
'ABCDEF' | 'ABCDEF    '
```

### Pattern 2: Separator Lines
```sql
REPLICATE('-', 50)  -- Simple line
REPLICATE('=', 50)  -- Double line
REPLICATE('*', 50)  -- Star line
```

### Pattern 3: Padding Numbers
```sql
-- Pad invoice number to 6 digits
'INV-' + REPLICATE('0', 6 - LEN(CAST(InvoiceNum AS VARCHAR))) + 
CAST(InvoiceNum AS VARCHAR)
```

**Example:**
```
1     → 'INV-000001'
42    → 'INV-000042'
12345 → 'INV-012345'
```

---

## Performance Tips

### ✅ DO:
```sql
-- Use CONCAT for NULL safety
CONCAT(FirstName, ' ', MiddleName, ' ', LastName)

-- Use SPACE instead of multiple spaces
'Text' + SPACE(10) + 'More'  -- Good
```

### ❌ DON'T:
```sql
-- Avoid + with possible NULLs
FirstName + ' ' + MiddleName + ' ' + LastName  -- Bad if NULL

-- Don't use literal spaces
'Text' + '          ' + 'More'  -- Hard to count, maintain
```

---

## Quick Reference

| Function | Purpose | Example | Result |
|----------|---------|---------|--------|
| `+` | Concatenate | `'A' + 'B'` | `'AB'` |
| `CONCAT()` | Safe concat | `CONCAT('A', NULL, 'B')` | `'AB'` |
| `REPLICATE()` | Repeat string | `REPLICATE('X', 3)` | `'XXX'` |
| `SPACE()` | Generate spaces | `SPACE(5)` | `'     '` |
| `CHAR()` | ASCII to char | `CHAR(65)` | `'A'` |

---

## Common Mistakes

### Mistake 1: Forgetting NULL Handling
```sql
-- ❌ BAD: Returns NULL if any part is NULL
FirstName + ' ' + MiddleName + ' ' + LastName

-- ✅ GOOD: Handles NULLs gracefully
CONCAT(FirstName, ' ', MiddleName, ' ', LastName)
```

### Mistake 2: Not Counting Spaces
```sql
-- ❌ BAD: Hard to count
'Name:' + '          ' + Value

-- ✅ GOOD: Explicit count
'Name:' + SPACE(10) + Value
```

### Mistake 3: Wrong CHAR Code
```sql
-- ❌ BAD: Creates unexpected character
CHAR(7)   -- Bell character (beep!)

-- ✅ GOOD: Use correct codes
CHAR(10)  -- Line feed (newline)
CHAR(13)  -- Carriage return
```

---

## Practice Exercises

### Exercise 1: Create Receipt Header
Create a formatted receipt header with:
- Top border (40 equals signs)
- "RECEIPT" centered
- Bottom border (40 equals signs)

**Solution:**
```sql
REPLICATE('=', 40) + CHAR(10) +
SPACE(16) + 'RECEIPT' + SPACE(17) + CHAR(10) +
REPLICATE('=', 40)
```

### Exercise 2: Format Product Code
Pad product number to 8 digits with leading zeros.

**Solution:**
```sql
'PROD-' + 
REPLICATE('0', 8 - LEN(CAST(ProductID AS VARCHAR))) + 
CAST(ProductID AS VARCHAR)
```

### Exercise 3: Create Table Border
Generate a table border pattern: `+-----+-----+-----+`

**Solution:**
```sql
'+' + REPLICATE('-', 5) + 
'+' + REPLICATE('-', 5) + 
'+' + REPLICATE('-', 5) + '+'
```

---

## Summary

### Key Takeaways:
1. **Use CONCAT()** for NULL-safe concatenation
2. **REPLICATE()** creates patterns and padding
3. **SPACE()** is clearer than literal spaces
4. **CHAR()** generates special characters (newlines, tabs)
5. **Combine functions** for complex formatting

### When to Use Each:
- **+** operator: When you're sure no NULLs exist
- **CONCAT()**: When NULLs are possible (safer)
- **REPLICATE()**: For patterns, borders, padding
- **SPACE()**: For alignment and spacing
- **CHAR()**: For special characters (newlines, tabs)

### Next Steps:
Proceed to **String Manipulation** to learn how to transform and extract parts of existing strings!

---

**Ready to manipulate strings?** → Continue to Lesson 02: String Manipulation
