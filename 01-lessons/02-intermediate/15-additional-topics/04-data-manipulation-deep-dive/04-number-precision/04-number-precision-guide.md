# Number Precision Guide

## Overview
Understanding numeric precision is **critical** for accurate calculations, especially with money and financial data. Wrong precision = wrong results = angry customers! 💸

---

## Understanding DECIMAL(precision, scale)

### The Format
```
DECIMAL(precision, scale)
         │           │
         │           └─ Digits AFTER decimal point
         └───────────── TOTAL digits (both sides)
```

### Visual Examples

#### DECIMAL(5, 2)
```
Maximum value: 999.99
                │││ ││
                │││ └┴─ 2 digits after decimal (scale)
                └┴┴──── 3 digits before decimal
Total: 5 digits (precision)
```

#### DECIMAL(10, 4)
```
Maximum value: 999999.9999
                │││││││││││
                └┴┴┴┴┴─ 5 digits before decimal
                      └┴┴┴─ 4 digits after decimal
Total: 10 digits (precision)
```

---

## Precision and Scale Impact

### Same Number, Different Precision

```sql
Value: 123.456789

DECIMAL(5, 2)  → 123.46      (rounded, loses precision)
DECIMAL(6, 3)  → 123.457     (rounded, keeps more)
DECIMAL(10, 4) → 123.4568    (rounded, high precision)
DECIMAL(10, 6) → 123.456789  (exact!)
```

### Scale = 0 (Integer)
```sql
Value: 99.999

DECIMAL(5, 0) → 100   (rounds to integer)
DECIMAL(3, 0) → 100
DECIMAL(2, 0) → ERROR (overflow! need 3 digits for 100)
```

---

## DECIMAL vs NUMERIC vs FLOAT

### Comparison Table

| Type | Storage | Precision | Use Case |
|------|---------|-----------|----------|
| **DECIMAL** | Exact | Fixed | 💰 Money, prices |
| **NUMERIC** | Exact | Fixed | 💰 Same as DECIMAL |
| **FLOAT** | Approximate | Variable | 🔬 Scientific data |
| **MONEY** | Exact | 4 decimals | 💵 Currency |

### The FLOAT Problem

**Why NEVER use FLOAT for money:**

```sql
-- Using FLOAT
0.1 + 0.2 = 0.30000000000000004  ❌ WRONG!

-- Using DECIMAL
0.1 + 0.2 = 0.30  ✅ CORRECT!
```

**Visual Example:**
```
Transaction 1: $19.99 × 3 items

FLOAT:
  19.99 × 3 = 59.97000000000001  ❌
  Customer charged: $59.97 (but system shows $59.97000000000001)

DECIMAL(10,2):
  19.99 × 3 = 59.97  ✅
  Perfect!
```

---

## Common Precision Choices

### For Money/Prices
```sql
DECIMAL(10, 2)   -- Typical prices ($999,999.99)
DECIMAL(19, 4)   -- High precision finance
MONEY            -- Built-in currency type (4 decimals)
```

**Example:**
```
Product Price:     DECIMAL(10, 2)  → $12,345.67
Exchange Rate:     DECIMAL(19, 4)  → 1.2345
Investment Value:  DECIMAL(19, 4)  → $1,234,567.8901
```

### For Percentages
```sql
DECIMAL(5, 2)    -- Percentages (999.99%)
DECIMAL(5, 4)    -- High precision (9.9999%)
```

**Example:**
```
Tax Rate:      DECIMAL(5, 2)  → 7.50%
Interest Rate: DECIMAL(5, 4)  → 0.0575 (5.75%)
```

### For Quantities
```sql
INT              -- Whole items only
DECIMAL(10, 2)   -- Fractional quantities (lbs, kg)
DECIMAL(18, 6)   -- High precision (scientific)
```

---

## The Integer Division Trap

### ⚠️ CRITICAL WARNING ⚠️

```sql
-- Integer divided by integer = INTEGER (truncates!)
10 / 3 = 3  ❌ NOT 3.333...

-- At least one must be decimal:
10.0 / 3 = 3.333333...  ✅
10 / 3.0 = 3.333333...  ✅
CAST(10 AS DECIMAL(10,2)) / 3 = 3.33  ✅
```

### Real-World Disaster
```sql
-- Calculate average price
-- ❌ BAD: Integer division
SELECT SUM(Price) / COUNT(*) AS AvgPrice
FROM Products
WHERE Price is INT;
-- Result: Truncated (loses cents!)

-- ✅ GOOD: Decimal division
SELECT CAST(SUM(Price) AS DECIMAL(10,2)) / COUNT(*) AS AvgPrice
FROM Products;
```

---

## Overflow Errors

### When Precision is Too Small

```sql
-- DECIMAL(5, 2) maximum: 999.99

123.45  ✅ OK
999.99  ✅ OK (maximum)
1000.00 ❌ ERROR! Arithmetic overflow
```

**Visual:**
```
DECIMAL(5, 2) capacity:
  [_][_][_].[_][_]
   │  │  │  │  │
   └──┴──┴──┴──┴─ 5 total digits

Value: 1234.56
       [1][2][3][4].[5][6]
       └──┴──┴──┴────────┴─ 6 digits! OVERFLOW!
```

### Solution: Increase Precision
```sql
-- Too small
DECLARE @Value DECIMAL(5, 2) = 999.99;
SELECT @Value * 1000;  -- ❌ ERROR!

-- Correct size
DECLARE @Value DECIMAL(10, 2) = 999.99;
SELECT @Value * 1000;  -- ✅ 999990.00
```

---

## Rounding Strategies

### ROUND Function
```sql
ROUND(value, decimals, truncate_flag)
```

**Examples:**
```sql
Value: 123.456

ROUND(123.456, 2)      → 123.46  (rounds up)
ROUND(123.456, 2, 1)   → 123.45  (truncates)
ROUND(123.456, 0)      → 123     (rounds to integer)
ROUND(123.456, -1)     → 120     (rounds to 10s)
```

### Visual Rounding
```
Original: 123.456789

Round to:
  2 decimals → 123.46──────┐
  1 decimal  → 123.5───────┤ Increasingly
  0 decimals → 123─────────┤ less precise
  -1 (tens)  → 120─────────┤
  -2 (100s)  → 100─────────┘
```

### Other Rounding Functions
```sql
CEILING(123.1)  → 124  (always rounds UP)
FLOOR(123.9)    → 123  (always rounds DOWN)
CAST(123.9 AS INT) → 123  (truncates decimals)
```

**Visual:**
```
Value: 123.7

ROUND()   → 124  (rounds to nearest)
CEILING() → 124  (always up)
FLOOR()   → 123  (always down)
CAST()    → 123  (truncates)
```

---

## MONEY Data Type

### Overview
```
MONEY: Fixed precision (4 decimals)
Range: -922,337,203,685,477.5808 to 922,337,203,685,477.5807
Storage: 8 bytes
```

### MONEY vs DECIMAL
```sql
MONEY:
  - Fixed 4 decimals
  - 8 bytes storage
  - Faster calculations
  - Limited precision

DECIMAL(19, 4):
  - Flexible decimals
  - 9 bytes storage
  - More control
  - Higher precision
```

**When to Use:**
```
MONEY:
  ✅ Simple currency (most business apps)
  ✅ Performance-critical calculations
  ✅ Standard financial data

DECIMAL(19, 4):
  ✅ High precision required
  ✅ Financial instruments
  ✅ Exchange rates
  ✅ Need more than 4 decimals
```

---

## Precision Loss Examples

### Example 1: Chain Calculations
```sql
Original: 10.0

Step 1: 10.0 / 3    = 3.333333...
Step 2: 3.333333 * 3 = 9.999999...  ❌ Lost precision!

Expected: 10.0
Actual:   9.999999
```

### Example 2: Multiplication Growth
```sql
DECIMAL(5, 2): 123.45
DECIMAL(5, 2): 67.89

Multiply: 123.45 × 67.89 = 8379.6405

Problem: Result has 4 decimals, but input only had 2!
Solution: Store result in DECIMAL(10, 4) or round to (10, 2)
```

---

## Best Practices

### ✅ DO:
```sql
-- Always specify precision
DECLARE @Price DECIMAL(10, 2);  ✅

-- Use DECIMAL for money
DECLARE @Amount DECIMAL(10, 2) = 19.99;  ✅

-- Round at calculation time
SELECT ROUND(Price * Quantity, 2) AS Total;  ✅

-- Use appropriate size
DECIMAL(10, 2)  -- Most prices
DECIMAL(19, 4)  -- High precision finance
DECIMAL(5, 2)   -- Percentages
```

### ❌ DON'T:
```sql
-- Don't rely on defaults
DECLARE @Price DECIMAL;  ❌ (defaults to DECIMAL(18,0)!)

-- Don't use FLOAT for money
DECLARE @Price FLOAT = 19.99;  ❌

-- Don't ignore overflow risk
DECIMAL(5, 2) * 1000  ❌ (likely overflow)

-- Don't forget precision in division
10 / 3  ❌ (integer division = 3)
```

---

## Common Calculations

### Tax Calculation
```sql
-- Price with 8% tax
DECLARE @Price DECIMAL(10, 2) = 100.00;

SELECT 
    @Price AS Price,
    ROUND(@Price * 0.08, 2) AS Tax,
    @Price + ROUND(@Price * 0.08, 2) AS Total;

Result:
Price:  100.00
Tax:      8.00
Total:  108.00
```

### Discount Calculation
```sql
-- 15% discount
DECLARE @Price DECIMAL(10, 2) = 49.99;

SELECT 
    @Price AS OriginalPrice,
    ROUND(@Price * 0.15, 2) AS Discount,
    ROUND(@Price * 0.85, 2) AS SalePrice;

Result:
Original:  49.99
Discount:   7.50
Sale:      42.49
```

---

## Storage Sizes

| Precision | Storage |
|-----------|---------|
| 1-9       | 5 bytes |
| 10-19     | 9 bytes |
| 20-28     | 13 bytes |
| 29-38     | 17 bytes |

**Right-Size Your Precision:**
```sql
-- Overkill (wastes 4 bytes per row)
ProductPrice DECIMAL(38, 2)  ❌

-- Appropriate
ProductPrice DECIMAL(10, 2)  ✅
```

---

## Quick Reference

| Type | Precision | Use For | Example |
|------|-----------|---------|---------|
| `DECIMAL(10,2)` | Standard | Prices | $12,345.67 |
| `DECIMAL(19,4)` | High | Finance | $1,234,567.8901 |
| `DECIMAL(5,2)` | Small | Percentages | 99.99% |
| `MONEY` | Fixed 4 | Currency | $12,345.6789 |
| `FLOAT` | Approximate | Science | ❌ NOT money! |
| `INT` | Integer | Counts | 12345 |

---

## Summary

### Critical Points:
1. **Never use FLOAT for money** (0.1 + 0.2 ≠ 0.3)
2. **Always specify precision** (don't rely on defaults)
3. **Watch integer division** (10/3 = 3, not 3.33)
4. **Choose appropriate size** (balance precision vs storage)
5. **Round at calculation time** (not just at display)

### Golden Rules:
- 💰 **Money:** `DECIMAL(10, 2)` or `DECIMAL(19, 4)`
- 📊 **Percentages:** `DECIMAL(5, 2)`
- 🔢 **Counts:** `INT`
- ⚠️ **Never:** `FLOAT` for currency

---

**Master precision = Master accurate calculations!** 🎯

