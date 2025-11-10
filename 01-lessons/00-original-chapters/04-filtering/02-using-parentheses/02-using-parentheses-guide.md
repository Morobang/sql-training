# Lesson 02: Using Parentheses - Visual Guide

## What You'll Learn
- How to control evaluation order with parentheses
- Understanding operator precedence
- Writing clear, unambiguous conditions
- Avoiding common logic mistakes

---

## Why Parentheses Matter

Without parentheses, SQL follows strict precedence rules that may not match your intent!

### The Problem: Ambiguous Logic

```sql
-- What does this mean?
WHERE Price < 50 OR CategoryID = 1 AND StockQuantity > 10

-- Option 1:
WHERE Price < 50 OR (CategoryID = 1 AND StockQuantity > 10)

-- Option 2:
WHERE (Price < 50 OR CategoryID = 1) AND StockQuantity > 10

-- SQL chooses Option 1! (AND has higher precedence than OR)
```

---

## Operator Precedence (Order of Evaluation)

```
┌─────────────────────────────────────────────────┐
│         SQL Evaluation Order (Top → Bottom)     │
├─────────────────────────────────────────────────┤
│  1.  ( )          Parentheses (highest)         │
│  2.  NOT          Logical negation              │
│  3.  AND          Logical AND                   │
│  4.  OR           Logical OR (lowest)           │
└─────────────────────────────────────────────────┘

Remember: PNAO (Parentheses, NOT, AND, OR)
```

---

## Visual Example: Precedence Impact

### Without Parentheses

```sql
WHERE Price < 50 OR CategoryID = 1 AND StockQuantity > 10

Step 1: Evaluate AND first (higher precedence)
        CategoryID = 1 AND StockQuantity > 10
                         ↓
        WHERE Price < 50 OR (result)

┌────┬─────────┬───────┬────┬───────┬───────────┬─────────────┬────────┐
│ ID │ Product │ Price │Cat │ Stock │ Price<50  │ Cat=1&Stock │ Result │
├────┼─────────┼───────┼────┼───────┼───────────┼─────────────┼────────┤
│ 1  │ Mouse   │  25   │ 1  │  50   │   TRUE    │    TRUE     │  TRUE✓ │
│ 2  │ Laptop  │ 800   │ 1  │  30   │   FALSE   │    TRUE     │  TRUE✓ │
│ 3  │ Monitor │ 300   │ 2  │  15   │   FALSE   │    FALSE    │ FALSE  │
│ 4  │ Cable   │  15   │ 3  │   5   │   TRUE    │    FALSE    │  TRUE✓ │
└────┴─────────┴───────┴────┴───────┴───────────┴─────────────┴────────┘

Returns: Rows 1, 2, 4
```

### With Parentheses (Different Logic!)

```sql
WHERE (Price < 50 OR CategoryID = 1) AND StockQuantity > 10

Step 1: Evaluate ( ) first
        (Price < 50 OR CategoryID = 1)
                         ↓
        WHERE (result) AND StockQuantity > 10

┌────┬─────────┬───────┬────┬───────┬──────────────┬──────────┬────────┐
│ ID │ Product │ Price │Cat │ Stock │ Price<50|Cat │ Stock>10 │ Result │
├────┼─────────┼───────┼────┼───────┼──────────────┼──────────┼────────┤
│ 1  │ Mouse   │  25   │ 1  │  50   │     TRUE     │   TRUE   │  TRUE✓ │
│ 2  │ Laptop  │ 800   │ 1  │  30   │     TRUE     │   TRUE   │  TRUE✓ │
│ 3  │ Monitor │ 300   │ 2  │  15   │    FALSE     │   TRUE   │ FALSE  │
│ 4  │ Cable   │  15   │ 3  │   5   │     TRUE     │   FALSE  │ FALSE  │
└────┴─────────┴───────┴────┴───────┴──────────────┴──────────┴────────┘

Returns: Rows 1, 2 (DIFFERENT RESULTS!)
```

**Same conditions, different parentheses = DIFFERENT RESULTS!**

---

## Side-by-Side Comparison

```
┌──────────────────────────────────────────────────────────────┐
│  WITHOUT Parentheses (AND evaluated first)                   │
│  Price < 50  OR  (CategoryID = 1 AND StockQuantity > 10)     │
│                                                               │
│  Matches if:                                                  │
│  • Price is cheap (< $50)  OR                                │
│  • Product is in Category 1 AND has stock > 10               │
│                                                               │
│  "Cheap items OR well-stocked Category 1 items"              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│  WITH Parentheses (OR evaluated first)                       │
│  (Price < 50 OR CategoryID = 1)  AND  StockQuantity > 10     │
│                                                               │
│  Matches if:                                                  │
│  • (Price is cheap OR in Category 1) AND has stock > 10      │
│                                                               │
│  "Cheap or Category 1 items that ALSO have good stock"       │
└──────────────────────────────────────────────────────────────┘
```

---

## Complex Business Logic Example

### Requirement:
"Find products that are:
- (Budget: under $50 AND in stock) OR
- (Premium: over $500 AND top-rated)"

### ❌ WRONG: Without proper parentheses

```sql
WHERE Price < 50 AND StockQuantity > 0 OR Price > 500 AND Rating = 5

-- SQL reads as:
WHERE Price < 50 AND StockQuantity > 0 OR (Price > 500 AND Rating = 5)

This is WRONG! Missing the grouping logic.
```

### ✅ CORRECT: With parentheses

```sql
WHERE (Price < 50 AND StockQuantity > 0) 
   OR (Price > 500 AND Rating = 5)

Visual breakdown:

     ┌─────────────────────────┐         ┌──────────────────────────┐
     │   Budget Products       │   OR    │   Premium Products       │
     │                         │         │                          │
     │  Price < 50             │         │  Price > 500             │
     │      AND                │         │      AND                 │
     │  StockQuantity > 0      │         │  Rating = 5              │
     └─────────────────────────┘         └──────────────────────────┘
```

---

## Nested Parentheses

You can nest parentheses for even more complex logic!

```sql
WHERE ((Price < 50 OR Price > 1000) AND CategoryID IN (1,2))
   OR (Price BETWEEN 100 AND 500 AND StockQuantity > 50)

Evaluation order:
1. Innermost ( ): Price < 50 OR Price > 1000
2. Next level:    (result from #1) AND CategoryID IN (1,2)
3. Second group:  Price BETWEEN 100 AND 500 AND StockQuantity > 50
4. Final OR:      (result from #2) OR (result from #3)
```

### Visual Breakdown

```
                          FINAL OR
                             │
              ┌──────────────┴──────────────┐
              │                             │
      ┌───────────────┐            ┌────────────────┐
      │  LEFT SIDE    │            │  RIGHT SIDE    │
      │               │            │                │
      │  (Low OR High)│            │  Mid-Range     │
      │      AND      │            │     AND        │
      │   Category    │            │  High Stock    │
      └───────────────┘            └────────────────┘
           │                              │
    ┌──────┴─────┐                       │
    │   Price    │                  Price: 100-500
    │  < 50 OR   │                  Stock: > 50
    │  > 1000    │
    └────────────┘
```

---

## Formatting for Readability

### ❌ BAD: Everything on one line

```sql
WHERE Price < 50 OR CategoryID = 1 AND StockQuantity > 10 OR Price > 1000 AND Rating = 5
```

### ✅ GOOD: Use line breaks and indentation

```sql
WHERE (Price < 50 OR CategoryID = 1) 
  AND StockQuantity > 10 
   OR (Price > 1000 AND Rating = 5)
```

### ✅ BETTER: Group related conditions

```sql
WHERE 
    -- Budget items in stock
    (Price < 50 AND StockQuantity > 10)
    OR 
    -- Premium items with high rating
    (Price > 1000 AND Rating = 5)
```

---

## Common Mistakes

### Mistake #1: Forgetting parentheses with OR

```sql
-- ❌ WRONG: Intended to find Category 1 or 2 with price > 100
WHERE CategoryID = 1 OR CategoryID = 2 AND Price > 100

-- SQL reads as:
WHERE CategoryID = 1 OR (CategoryID = 2 AND Price > 100)

-- Returns:
-- • ALL Category 1 items (any price)
-- • Category 2 items with Price > 100

-- ✅ CORRECT:
WHERE (CategoryID = 1 OR CategoryID = 2) AND Price > 100
```

### Mistake #2: Too many parentheses (confusing but harmless)

```sql
-- ❌ Confusing (but works):
WHERE (((Price > 100) AND (CategoryID = 1)) OR ((Stock > 50)))

-- ✅ Clearer:
WHERE (Price > 100 AND CategoryID = 1) OR Stock > 50
```

### Mistake #3: Mismatched parentheses

```sql
-- ❌ SYNTAX ERROR: Missing closing )
WHERE (Price > 100 AND CategoryID = 1

-- ❌ SYNTAX ERROR: Extra closing )
WHERE (Price > 100 AND CategoryID = 1))
```

---

## Testing Your Logic

Always test complex conditions by breaking them down:

### Step 1: Test each part separately

```sql
-- Test part 1
SELECT * FROM Products WHERE Price < 50;

-- Test part 2
SELECT * FROM Products WHERE CategoryID = 1;

-- Test part 3
SELECT * FROM Products WHERE StockQuantity > 10;
```

### Step 2: Combine with AND

```sql
SELECT * FROM Products 
WHERE Price < 50 AND CategoryID = 1;
```

### Step 3: Add OR logic

```sql
SELECT * FROM Products 
WHERE (Price < 50 AND CategoryID = 1)
   OR StockQuantity > 10;
```

### Step 4: Verify with explicit checks

```sql
SELECT 
    ProductName,
    Price,
    CategoryID,
    StockQuantity,
    CASE 
        WHEN (Price < 50 AND CategoryID = 1) OR StockQuantity > 10 
        THEN 'MATCH' 
        ELSE 'NO MATCH' 
    END AS Result
FROM Products;
```

---

## Decision Tree for Parentheses

```
Do you have multiple conditions?
    │
    ├─ NO → Parentheses not needed
    │       WHERE Price > 100
    │
    └─ YES → Do you mix AND/OR?
            │
            ├─ NO → Parentheses optional (but clearer)
            │       WHERE Price > 100 AND Stock > 10 AND CategoryID = 1
            │
            └─ YES → USE PARENTHESES!
                    WHERE (Price < 50 OR CategoryID = 1) AND Stock > 10
```

---

## Real-World Examples

### Example 1: E-commerce Product Filter

```sql
-- Find products that match customer criteria:
-- • Cheap AND in stock, OR
-- • Premium AND highly rated

WHERE 
    (Price < 100 AND StockQuantity > 0)
    OR 
    (Price > 500 AND Rating >= 4.5)
```

### Example 2: Customer Segmentation

```sql
-- Find VIP customers:
-- • High spenders (> $10k) OR
-- • Frequent buyers (> 20 orders) with recent activity

WHERE 
    TotalSpent > 10000
    OR 
    (OrderCount > 20 AND LastOrderDate > DATEADD(MONTH, -6, GETDATE()))
```

### Example 3: Inventory Management

```sql
-- Find products needing attention:
-- • Low stock items that are popular, OR
-- • Overstocked slow movers

WHERE 
    (StockQuantity < 10 AND SalesLastMonth > 50)
    OR 
    (StockQuantity > 500 AND SalesLastMonth < 5)
```

---

## Key Takeaways

```
✅ DO:
  • Use parentheses when mixing AND/OR
  • Group related conditions together
  • Format for readability (line breaks, indentation)
  • Test complex logic step-by-step
  • Add comments to explain business logic

❌ DON'T:
  • Rely on precedence rules (use explicit parentheses!)
  • Write everything on one line
  • Forget to test your logic
  • Over-complicate with unnecessary parentheses
```

---

## Quick Reference

### Precedence Order
```
1. ( )     ← Highest (evaluated first)
2. NOT
3. AND
4. OR      ← Lowest (evaluated last)
```

### Common Patterns
```sql
-- Pattern 1: (A OR B) AND C
WHERE (Price < 50 OR CategoryID = 1) AND StockQuantity > 10

-- Pattern 2: A AND (B OR C)
WHERE Price > 100 AND (CategoryID = 1 OR CategoryID = 2)

-- Pattern 3: (A AND B) OR (C AND D)
WHERE (Price < 50 AND Stock > 10) OR (Price > 500 AND Rating = 5)

-- Pattern 4: Nested
WHERE ((A OR B) AND C) OR (D AND E)
```

---

**Next:** [Lesson 03 - NOT Operator](../03-not-operator/03-not-operator-guide.md)
