# Lesson 01: Condition Evaluation - Visual Guide

## What You'll Learn
- How SQL evaluates TRUE/FALSE/NULL
- Understanding AND/OR logic
- How WHERE clause decides which rows to keep

---

## The Three Truth Values

SQL doesn't just have TRUE and FALSE - it has three possible values:

```
┌─────────┬──────────────────────────────┐
│  Value  │         Meaning              │
├─────────┼──────────────────────────────┤
│  TRUE   │  Condition is satisfied      │
│  FALSE  │  Condition is not satisfied  │
│  NULL   │  Unknown/Can't determine     │
└─────────┴──────────────────────────────┘
```

### Example: Comparing Numbers

```sql
-- TRUE example
5 > 3          → TRUE
100 = 100      → TRUE
50 <> 100      → TRUE

-- FALSE example
5 > 10         → FALSE
100 = 50       → FALSE

-- NULL example
NULL = 5       → NULL (unknown!)
NULL = NULL    → NULL (unknown!)
5 > NULL       → NULL (unknown!)
```

---

## How WHERE Works

```
┌─────────────────────────────────────────────┐
│          ALL ROWS IN TABLE                  │
│  ┌────┬─────────┬───────┬────────────┐     │
│  │ ID │ Product │ Price │  Category  │     │
│  ├────┼─────────┼───────┼────────────┤     │
│  │ 1  │ Laptop  │  800  │     1      │ ─┐  │
│  │ 2  │ Mouse   │   25  │     1      │  │  │
│  │ 3  │ Monitor │  300  │     2      │  │  │
│  │ 4  │ Keyboard│   75  │     1      │  │  │
│  └────┴─────────┴───────┴────────────┘  │  │
│                                          │  │
│              WHERE Price > 100           │  │
│                     ↓                    │  │
│              Evaluate Each Row           │  │
│                     ↓                    │  │
│  ┌─────────────────────────────────┐    │  │
│  │ Row 1: 800 > 100 → TRUE  ✓      │────┘  │
│  │ Row 2:  25 > 100 → FALSE ✗      │       │
│  │ Row 3: 300 > 100 → TRUE  ✓      │────┐  │
│  │ Row 4:  75 > 100 → FALSE ✗      │    │  │
│  └─────────────────────────────────┘    │  │
│                     ↓                    │  │
│          KEEP ONLY TRUE ROWS             │  │
│                     ↓                    ↓  │
│  ┌────┬─────────┬───────┬────────────┐     │
│  │ 1  │ Laptop  │  800  │     1      │     │
│  │ 3  │ Monitor │  300  │     2      │     │
│  └────┴─────────┴───────┴────────────┘     │
│              RESULT SET                     │
└─────────────────────────────────────────────┘
```

**Key Rule:** WHERE only keeps rows that evaluate to **TRUE**. FALSE and NULL rows are filtered out!

---

## Comparison Operators

```
┌──────────┬─────────────────────┬──────────────────┐
│ Operator │     Meaning         │     Example      │
├──────────┼─────────────────────┼──────────────────┤
│    =     │  Equal to           │  Price = 100     │
│   <> or !=│  Not equal to      │  Price <> 100    │
│    >     │  Greater than       │  Price > 100     │
│    <     │  Less than          │  Price < 100     │
│   >=     │  Greater or equal   │  Price >= 100    │
│   <=     │  Less or equal      │  Price <= 100    │
└──────────┴─────────────────────┴──────────────────┘
```

---

## AND Operator Truth Table

**AND requires BOTH conditions to be TRUE**

```
┌─────────────┬─────────────┬─────────────┐
│ Condition A │ Condition B │   A AND B   │
├─────────────┼─────────────┼─────────────┤
│    TRUE     │    TRUE     │    TRUE ✓   │
│    TRUE     │    FALSE    │    FALSE    │
│    TRUE     │    NULL     │    NULL     │
│    FALSE    │    TRUE     │    FALSE    │
│    FALSE    │    FALSE    │    FALSE    │
│    FALSE    │    NULL     │    FALSE    │
│    NULL     │    TRUE     │    NULL     │
│    NULL     │    FALSE    │    FALSE    │
│    NULL     │    NULL     │    NULL     │
└─────────────┴─────────────┴─────────────┘
```

### Visual Example

```sql
WHERE Price > 100 AND CategoryID = 1

┌────┬─────────┬───────┬────────┬─────────────┬──────────────┬────────┐
│ ID │ Product │ Price │  Cat   │  Price>100  │  CategoryID=1│ Result │
├────┼─────────┼───────┼────────┼─────────────┼──────────────┼────────┤
│ 1  │ Laptop  │  800  │   1    │    TRUE     │     TRUE     │  TRUE✓ │
│ 2  │ Mouse   │   25  │   1    │   FALSE     │     TRUE     │ FALSE  │
│ 3  │ Monitor │  300  │   2    │    TRUE     │    FALSE     │ FALSE  │
│ 4  │ Keyboard│   75  │   1    │   FALSE     │     TRUE     │ FALSE  │
└────┴─────────┴───────┴────────┴─────────────┴──────────────┴────────┘

Only Row 1 returns TRUE for BOTH conditions!
```

---

## OR Operator Truth Table

**OR requires AT LEAST ONE condition to be TRUE**

```
┌─────────────┬─────────────┬─────────────┐
│ Condition A │ Condition B │   A OR B    │
├─────────────┼─────────────┼─────────────┤
│    TRUE     │    TRUE     │    TRUE ✓   │
│    TRUE     │    FALSE    │    TRUE ✓   │
│    TRUE     │    NULL     │    TRUE ✓   │
│    FALSE    │    TRUE     │    TRUE ✓   │
│    FALSE    │    FALSE    │    FALSE    │
│    FALSE    │    NULL     │    NULL     │
│    NULL     │    TRUE     │    TRUE ✓   │
│    NULL     │    FALSE    │    NULL     │
│    NULL     │    NULL     │    NULL     │
└─────────────┴─────────────┴─────────────┘
```

### Visual Example

```sql
WHERE Price < 50 OR CategoryID = 1

┌────┬─────────┬───────┬────────┬────────────┬──────────────┬────────┐
│ ID │ Product │ Price │  Cat   │  Price<50  │  CategoryID=1│ Result │
├────┼─────────┼───────┼────────┼────────────┼──────────────┼────────┤
│ 1  │ Laptop  │  800  │   1    │   FALSE    │     TRUE     │  TRUE✓ │
│ 2  │ Mouse   │   25  │   1    │    TRUE    │     TRUE     │  TRUE✓ │
│ 3  │ Monitor │  300  │   2    │   FALSE    │    FALSE     │ FALSE  │
│ 4  │ Keyboard│   75  │   1    │   FALSE    │     TRUE     │  TRUE✓ │
└────┴─────────┴───────┴────────┴────────────┴──────────────┴────────┘

Rows 1, 2, and 4 have at least ONE TRUE condition!
```

---

## Evaluation Order

When you combine AND and OR, order matters:

```
Default Precedence (without parentheses):
1. Comparisons (=, <, >, etc.)
2. NOT
3. AND
4. OR
```

### Example: Without Parentheses

```sql
WHERE Price < 50 OR CategoryID = 1 AND StockQuantity > 10

-- SQL reads this as:
WHERE Price < 50 OR (CategoryID = 1 AND StockQuantity > 10)

     Price < 50
         OR
   ┌────────────────┐
   │  CategoryID=1  │
   │      AND       │
   │ StockQty > 10  │
   └────────────────┘
```

### Example: With Parentheses (More Clear!)

```sql
WHERE (Price < 50 OR CategoryID = 1) AND StockQuantity > 10

   ┌────────────────────┐
   │   Price < 50       │
   │       OR           │   AND   StockQty > 10
   │  CategoryID = 1    │
   └────────────────────┘
```

---

## NULL Behavior - CRITICAL!

```
┌──────────────────────────────────────────────────────┐
│         NULL in Comparisons = NULL                   │
│                                                       │
│  NULL = NULL    →  NULL (not TRUE!)                  │
│  NULL <> NULL   →  NULL (not TRUE!)                  │
│  NULL > 5       →  NULL                              │
│  5 + NULL       →  NULL                              │
│  'Hi' + NULL    →  NULL                              │
│                                                       │
│  ⚠️  WHERE filters out NULL results!                 │
└──────────────────────────────────────────────────────┘
```

### Visual NULL Example

```sql
WHERE Price = NULL  -- ❌ WRONG! Returns ZERO rows

┌────┬─────────┬───────┬──────────────┬────────┐
│ ID │ Product │ Price │  Price=NULL  │ Result │
├────┼─────────┼───────┼──────────────┼────────┤
│ 1  │ Laptop  │  800  │     NULL     │  NULL  │
│ 2  │ Mouse   │  NULL │     NULL     │  NULL  │
│ 3  │ Monitor │  300  │     NULL     │  NULL  │
└────┴─────────┴───────┴──────────────┴────────┘

No rows are TRUE, so nothing is returned!
```

```sql
WHERE Price IS NULL  -- ✅ CORRECT!

┌────┬─────────┬───────┬────────────────┬────────┐
│ ID │ Product │ Price │  Price IS NULL │ Result │
├────┼─────────┼───────┼────────────────┼────────┤
│ 1  │ Laptop  │  800  │     FALSE      │  FALSE │
│ 2  │ Mouse   │  NULL │     TRUE       │  TRUE✓ │
│ 3  │ Monitor │  300  │     FALSE      │  FALSE │
└────┴─────────┴───────┴────────────────┴────────┘

Row 2 is returned!
```

---

## Step-by-Step Evaluation

Let's trace how SQL evaluates this query:

```sql
WHERE Price > 100 AND CategoryID = 1 OR StockQuantity < 10
```

**Step 1:** Evaluate comparisons

```
Row 1: Laptop, Price=800, Cat=1, Stock=50
  → 800 > 100 = TRUE
  → 1 = 1 = TRUE
  → 50 < 10 = FALSE
  
Row 2: Mouse, Price=25, Cat=1, Stock=5
  → 25 > 100 = FALSE
  → 1 = 1 = TRUE
  → 5 < 10 = TRUE
```

**Step 2:** Apply AND (higher precedence)

```
Row 1: TRUE AND TRUE OR FALSE
     → TRUE OR FALSE
     
Row 2: FALSE AND TRUE OR TRUE
     → FALSE OR TRUE
```

**Step 3:** Apply OR

```
Row 1: TRUE OR FALSE = TRUE ✓
Row 2: FALSE OR TRUE = TRUE ✓
```

---

## Key Takeaways

```
✅ DO:
  • Understand TRUE/FALSE/NULL
  • Use IS NULL for NULL checks
  • Remember AND needs BOTH true
  • Remember OR needs AT LEAST ONE true
  • Test your conditions separately

❌ DON'T:
  • Use = NULL (use IS NULL instead)
  • Forget about NULL results
  • Ignore evaluation order
  • Mix AND/OR without parentheses
```

---

## Quick Reference

| Condition | Returns |
|-----------|---------|
| `5 > 3` | TRUE |
| `5 < 3` | FALSE |
| `NULL = 5` | NULL |
| `TRUE AND TRUE` | TRUE |
| `TRUE AND FALSE` | FALSE |
| `TRUE OR FALSE` | TRUE |
| `FALSE OR FALSE` | FALSE |
| `TRUE AND NULL` | NULL |
| `FALSE OR NULL` | NULL |

---

## Practice Tips

1. **Test each condition separately first**
   ```sql
   -- Instead of:
   WHERE Price > 100 AND CategoryID = 1
   
   -- Test separately:
   WHERE Price > 100        -- See results
   WHERE CategoryID = 1     -- See results
   WHERE Price > 100 AND CategoryID = 1  -- Combine
   ```

2. **Use SELECT to test logic**
   ```sql
   SELECT 
       Price,
       CategoryID,
       Price > 100 AS PriceCheck,
       CategoryID = 1 AS CategoryCheck,
       CASE WHEN Price > 100 AND CategoryID = 1 
            THEN 'MATCH' ELSE 'NO MATCH' END AS Result
   FROM Products;
   ```

3. **Watch for NULL!**
   ```sql
   -- Always check for NULL separately
   WHERE Price IS NOT NULL AND Price > 100
   ```

---

**Next:** [Lesson 02 - Using Parentheses](../02-using-parentheses/02-using-parentheses-guide.md)
