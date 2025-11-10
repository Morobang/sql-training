# Lesson 09: Set Operation Precedence - Visual Guide

## What You'll Learn
- How SQL evaluates multiple set operations
- Using parentheses to control order
- Debugging complex queries
- Performance implications of precedence

---

## What is Precedence?

**Precedence** determines the order SQL evaluates operations when you combine multiple set operators.

```
┌────────────────────────────────────────────────────┐
│           Basic Precedence Concept                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  Mathematical Parallel:                            │
│  2 + 3 × 4 = ?                                     │
│                                                     │
│  Without precedence rules:                         │
│  (2 + 3) × 4 = 5 × 4 = 20  ❌ Wrong               │
│                                                     │
│  With precedence (× before +):                     │
│  2 + (3 × 4) = 2 + 12 = 14  ✓ Correct             │
│                                                     │
│  SQL Set Operations:                               │
│  A UNION B EXCEPT C = ?                            │
│                                                     │
│  Default (left to right):                          │
│  (A UNION B) EXCEPT C                              │
│                                                     │
│  With parentheses:                                 │
│  A UNION (B EXCEPT C)  ← Different result!        │
└────────────────────────────────────────────────────┘
```

---

## Default Precedence: Left to Right

SQL Server evaluates set operations **left to right** by default.

```
┌────────────────────────────────────────────────────┐
│           Left-to-Right Evaluation                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  Query: A UNION B EXCEPT C                         │
│                                                     │
│  Step 1: Evaluate A UNION B first                  │
│  ┌─────┐    ┌─────┐                               │
│  │  A  │    │  B  │                               │
│  │ {1} │ ∪  │ {2} │  = {1, 2}                     │
│  │ {2} │    │ {3} │                               │
│  └─────┘    └─────┘                               │
│       ↓                                             │
│  Step 2: Then EXCEPT C                             │
│  ┌─────────┐    ┌─────┐                           │
│  │ A ∪ B   │    │  C  │                           │
│  │ {1, 2}  │ \  │ {2} │  = {1}                    │
│  └─────────┘    └─────┘                           │
│                                                     │
│  Final Result: {1}                                 │
│                                                     │
│  Visual:                                           │
│  ((A UNION B) EXCEPT C)                            │
│   └────┬────┘                                      │
│     First     └─────┬─────┘                        │
│                   Second                            │
└────────────────────────────────────────────────────┘
```

### Example with Data

```
┌────────────────────────────────────────────────────┐
│        Practical Left-to-Right Example             │
├────────────────────────────────────────────────────┤
│                                                     │
│  January Orders: {C001, C002}                      │
│  February Orders: {C002, C003}                     │
│  March Orders: {C002, C004}                        │
│                                                     │
│  Query:                                            │
│  Jan UNION Feb EXCEPT Mar                          │
│                                                     │
│  Step 1: Jan UNION Feb                             │
│  ┌──────────────────┐                              │
│  │ {C001, C002, C003} │                            │
│  └──────────────────┘                              │
│                                                     │
│  Step 2: Result EXCEPT Mar                         │
│  ┌──────────────────┐    ┌─────────────┐          │
│  │{C001, C002, C003}│ \  │{C002, C004} │          │
│  └──────────────────┘    └─────────────┘          │
│           ↓                                         │
│  ┌──────────────┐                                  │
│  │{C001, C003}  │                                  │
│  └──────────────┘                                  │
│                                                     │
│  Result: Customers in Jan OR Feb, but NOT Mar      │
└────────────────────────────────────────────────────┘
```

---

## Using Parentheses to Control Order

Parentheses **override** default precedence.

```
┌────────────────────────────────────────────────────┐
│         Parentheses Change Everything!             │
├────────────────────────────────────────────────────┤
│                                                     │
│  Same data:                                        │
│  A = {1, 2}                                        │
│  B = {2, 3}                                        │
│  C = {2}                                           │
│                                                     │
│  Without Parentheses:                              │
│  A UNION B EXCEPT C                                │
│  = (A UNION B) EXCEPT C                            │
│  = {1, 2, 3} EXCEPT {2}                           │
│  = {1, 3}  ✓                                      │
│                                                     │
│  With Parentheses:                                 │
│  A UNION (B EXCEPT C)                              │
│  = A UNION ({2, 3} EXCEPT {2})                    │
│  = A UNION {3}                                     │
│  = {1, 2} UNION {3}                               │
│  = {1, 2, 3}  ✓ Different!                        │
│                                                     │
│  Visual Comparison:                                │
│  (A ∪ B) \ C  ≠  A ∪ (B \ C)                      │
│    {1, 3}          {1, 2, 3}                       │
└────────────────────────────────────────────────────┘
```

### Business Impact Example

```
┌────────────────────────────────────────────────────┐
│       Same Query, Different Parentheses            │
├────────────────────────────────────────────────────┤
│                                                     │
│  Data:                                             │
│  Premium = {C001, C002}                            │
│  Active = {C002, C003}                             │
│  Churned = {C002}                                  │
│                                                     │
│  Query 1: (Premium UNION Active) EXCEPT Churned    │
│                                                     │
│  Step 1: Premium ∪ Active = {C001, C002, C003}    │
│  Step 2: Result \ Churned = {C001, C003}          │
│                                                     │
│  Result: {C001, C003}                              │
│  Meaning: Premium OR Active, but NOT churned       │
│           → 2 customers                            │
│                                                     │
│  Query 2: Premium UNION (Active EXCEPT Churned)    │
│                                                     │
│  Step 1: Active \ Churned = {C003}                │
│  Step 2: Premium ∪ Result = {C001, C002, C003}    │
│                                                     │
│  Result: {C001, C002, C003}                        │
│  Meaning: Premium OR (Active and not churned)      │
│           → 3 customers                            │
│                                                     │
│  Different business insights!                      │
└────────────────────────────────────────────────────┘
```

---

## Complex Nested Operations

```
┌────────────────────────────────────────────────────┐
│          Multiple Parentheses Levels               │
├────────────────────────────────────────────────────┤
│                                                     │
│  Query: A UNION (B INTERSECT C) EXCEPT D           │
│                                                     │
│  Evaluation Tree:                                  │
│                                                     │
│              EXCEPT                                │
│             /      \                               │
│          UNION      D                              │
│         /     \                                    │
│        A   INTERSECT                               │
│             /    \                                 │
│            B      C                                │
│                                                     │
│  Step-by-Step:                                     │
│  1. B INTERSECT C     (innermost first)            │
│  2. A UNION (result)  (then union)                 │
│  3. (result) EXCEPT D (finally except)             │
│                                                     │
│  With Data:                                        │
│  A = {1, 2}                                        │
│  B = {2, 3, 4}                                     │
│  C = {3, 4, 5}                                     │
│  D = {1}                                           │
│                                                     │
│  Step 1: B ∩ C = {2, 3, 4} ∩ {3, 4, 5} = {3, 4}  │
│  Step 2: A ∪ {3, 4} = {1, 2, 3, 4}               │
│  Step 3: {1, 2, 3, 4} \ {1} = {2, 3, 4}          │
│                                                     │
│  Final: {2, 3, 4}                                  │
└────────────────────────────────────────────────────┘
```

---

## Mixing All Three Operators

```
┌────────────────────────────────────────────────────┐
│     UNION + INTERSECT + EXCEPT Together            │
├────────────────────────────────────────────────────┤
│                                                     │
│  Scenario: Customer Segmentation                   │
│                                                     │
│  HighValue = Customers who spent > $1000           │
│  Frequent = Ordered 10+ times                      │
│  Recent = Ordered in last 30 days                  │
│  Inactive = Not ordered in 90 days                 │
│                                                     │
│  Goal: (HighValue OR Frequent) AND Recent          │
│        but NOT Inactive                            │
│                                                     │
│  Query:                                            │
│  (                                                  │
│    (HighValue UNION Frequent)  -- All valuable     │
│    INTERSECT                                       │
│    Recent                      -- Who are active   │
│  )                                                 │
│  EXCEPT                                            │
│  Inactive                      -- Remove churned   │
│                                                     │
│  Venn Diagram:                                     │
│  ┌─────────────────────────────────────┐          │
│  │         ╭──────╮                    │          │
│  │        ╱HighVal╲   ╭────────╮      │          │
│  │       │    ╭────────╯Recent  │      │          │
│  │       │   ╱│███╲            │      │          │
│  │  ╭────────╯│███│╲ Frequent │      │          │
│  │  │Inactive│ │███│ ╲        │      │          │
│  │  │   ⚫   │ │███│  ╲───────╯      │          │
│  │  ╰────────╯  ╲██╱                  │          │
│  │               ╰──╯                  │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  █ = Target segment (kept)                        │
│  ⚫ = Inactive (removed)                           │
└────────────────────────────────────────────────────┘
```

---

## Debugging Complex Queries

```
┌────────────────────────────────────────────────────┐
│         Incremental Building Strategy              │
├────────────────────────────────────────────────────┤
│                                                     │
│  Complex Query:                                    │
│  (A UNION B) INTERSECT C EXCEPT D                  │
│                                                     │
│  Don't write all at once! Build incrementally:     │
│                                                     │
│  Step 1: Test A alone                              │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT * FROM SetA                   │         │
│  │ -- Result: 100 rows                  │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Step 2: Add UNION B                               │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT * FROM SetA                   │         │
│  │ UNION                                 │         │
│  │ SELECT * FROM SetB                   │         │
│  │ -- Result: 180 rows (20 duplicates)  │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Step 3: Add INTERSECT C                           │
│  ┌──────────────────────────────────────┐         │
│  │ (SELECT * FROM SetA                  │         │
│  │  UNION                                │         │
│  │  SELECT * FROM SetB)                 │         │
│  │ INTERSECT                             │         │
│  │ SELECT * FROM SetC                   │         │
│  │ -- Result: 45 rows                   │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Step 4: Add EXCEPT D                              │
│  ┌──────────────────────────────────────┐         │
│  │ ((SELECT * FROM SetA                 │         │
│  │   UNION                               │         │
│  │   SELECT * FROM SetB)                │         │
│  │  INTERSECT                            │         │
│  │  SELECT * FROM SetC)                 │         │
│  │ EXCEPT                                │         │
│  │ SELECT * FROM SetD                   │         │
│  │ -- Result: 38 rows                   │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Verify at each step!                              │
└────────────────────────────────────────────────────┘
```

---

## Performance Implications

```
┌────────────────────────────────────────────────────┐
│         Precedence Affects Performance             │
├────────────────────────────────────────────────────┤
│                                                     │
│  Scenario: Large datasets                          │
│  A = 1,000,000 rows                                │
│  B = 500,000 rows                                  │
│  C = 100 rows (small filter)                       │
│                                                     │
│  Bad Order (default):                              │
│  (A UNION B) EXCEPT C                              │
│  ┌─────────────────────────────────────┐          │
│  │ 1. A ∪ B → Process 1.5M rows        │          │
│  │    Time: 5 seconds                   │          │
│  │ 2. Result \ C → Compare to 100       │          │
│  │    Time: 3 seconds                   │          │
│  │ ─────────────────────────────────    │          │
│  │ Total: 8 seconds                     │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  Good Order (with parentheses):                    │
│  A UNION (B EXCEPT C)                              │
│  ┌─────────────────────────────────────┐          │
│  │ 1. B \ C → Filter 500K by 100        │          │
│  │    Time: 1 second (reduced set)      │          │
│  │ 2. A ∪ Result → Combine              │          │
│  │    Time: 2 seconds                   │          │
│  │ ─────────────────────────────────    │          │
│  │ Total: 3 seconds (62% faster!)       │          │
│  └─────────────────────────────────────┘          │
│                                                     │
│  Rule: Filter early, combine late!                 │
└────────────────────────────────────────────────────┘
```

---

## Common Mistakes

```
┌────────────────────────────────────────────────────┐
│              Precedence Pitfalls                   │
├────────────────────────────────────────────────────┤
│                                                     │
│  Mistake 1: Assuming INTERSECT has higher priority │
│  ❌ Some databases give INTERSECT precedence       │
│  ❌ SQL Server does NOT (left-to-right)            │
│  ✅ Always use parentheses for clarity             │
│                                                     │
│  Mistake 2: Forgetting parentheses                 │
│  ❌ A UNION B EXCEPT C                             │
│      (means ((A UNION B) EXCEPT C))                │
│  ✅ A UNION (B EXCEPT C)                           │
│      (explicit intent)                             │
│                                                     │
│  Mistake 3: Not testing intermediate results       │
│  ❌ Write entire complex query at once             │
│  ✅ Build step-by-step, verify each stage          │
│                                                     │
│  Mistake 4: Ignoring performance                   │
│  ❌ (BigTable UNION BigTable) INTERSECT Small      │
│  ✅ BigTable INTERSECT (Small ops)                 │
│                                                     │
│  Mistake 5: Inconsistent parentheses               │
│  ❌ Mixing styles in same query                    │
│  ✅ Always be explicit, even when not required     │
└────────────────────────────────────────────────────┘
```

---

## Best Practices

```
┌────────────────────────────────────────────────────┐
│           Set Precedence Best Practices            │
├────────────────────────────────────────────────────┤
│                                                     │
│  ✅ DO:                                            │
│  1. Always use parentheses                         │
│     • Even when not strictly required              │
│     • Makes intent crystal clear                   │
│     • Prevents confusion                           │
│                                                     │
│  2. Build queries incrementally                    │
│     • Start with smallest sets                     │
│     • Add operations one at a time                 │
│     • Verify each step                             │
│                                                     │
│  3. Filter early                                   │
│     • Apply WHERE before set operations            │
│     • Use EXCEPT with small sets first             │
│     • Reduce data volume early                     │
│                                                     │
│  4. Use meaningful CTEs                            │
│     WITH HighValue AS (...),                       │
│          Frequent AS (...),                        │
│          Recent AS (...)                           │
│     SELECT * FROM HighValue                        │
│     UNION                                          │
│     SELECT * FROM Frequent                         │
│     INTERSECT                                      │
│     SELECT * FROM Recent                           │
│                                                     │
│  5. Comment complex operations                     │
│     -- Get all valuable customers                  │
│     (HighValue UNION Frequent)                     │
│     -- Who are currently active                    │
│     INTERSECT Recent                               │
│                                                     │
│  ❌ DON'T:                                         │
│  • Rely on default left-to-right                   │
│  • Write complex queries without testing           │
│  • Ignore parentheses "because it works"           │
│  • Mix operations without clear structure          │
└────────────────────────────────────────────────────┘
```

---

## Real-World Example

```
┌────────────────────────────────────────────────────┐
│        Marketing Campaign Target List              │
├────────────────────────────────────────────────────┤
│                                                     │
│  Goal: Find customers for reactivation campaign    │
│                                                     │
│  Include:                                          │
│  • Previously high-value OR frequent buyers        │
│  • Who ordered in last year                        │
│  • But NOT in last 90 days                         │
│  • And NOT already in current campaign             │
│                                                     │
│  Query with Proper Precedence:                     │
│  ┌──────────────────────────────────────┐         │
│  │ WITH                                  │         │
│  │   HighValue AS (                      │         │
│  │     SELECT CustomerID FROM Orders     │         │
│  │     GROUP BY CustomerID               │         │
│  │     HAVING SUM(TotalAmount) > 5000    │         │
│  │   ),                                  │         │
│  │   Frequent AS (                       │         │
│  │     SELECT CustomerID FROM Orders     │         │
│  │     GROUP BY CustomerID               │         │
│  │     HAVING COUNT(*) >= 20             │         │
│  │   ),                                  │         │
│  │   LastYear AS (                       │         │
│  │     SELECT DISTINCT CustomerID        │         │
│  │     FROM Orders                        │         │
│  │     WHERE OrderDate >= DATEADD(YEAR,-1,GETDATE())│
│  │   ),                                  │         │
│  │   Recent AS (                         │         │
│  │     SELECT DISTINCT CustomerID        │         │
│  │     FROM Orders                        │         │
│  │     WHERE OrderDate >= DATEADD(DAY,-90,GETDATE())│
│  │   ),                                  │         │
│  │   InCampaign AS (                     │         │
│  │     SELECT CustomerID FROM CampaignList│         │
│  │   )                                   │         │
│  │                                       │         │
│  │ -- Build target list with precedence  │         │
│  │ (                                     │         │
│  │   (                                   │         │
│  │     (HighValue UNION Frequent)        │         │
│  │     INTERSECT                         │         │
│  │     LastYear                          │         │
│  │   )                                   │         │
│  │   EXCEPT                              │         │
│  │   Recent                              │         │
│  │ )                                     │         │
│  │ EXCEPT                                │         │
│  │ InCampaign                            │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Result: Perfectly targeted customer list!         │
└────────────────────────────────────────────────────┘
```

---

## Key Takeaways

```
✅ Precedence Basics:
  • SQL Server: left-to-right by default
  • Parentheses override default order
  • Different order = different results
  • Be explicit, always use ()

✅ Performance:
  • Filter early with EXCEPT/WHERE
  • Small sets before large sets
  • Parentheses can improve speed
  • Test with STATISTICS TIME ON

✅ Debugging:
  • Build queries incrementally
  • Test each operation separately
  • Verify row counts at each step
  • Use CTEs for complex logic

✅ Best Practices:
  • Always use parentheses
  • Add comments for clarity
  • Use meaningful CTE names
  • Consider readability vs brevity
```

---

## Quick Reference

```sql
-- Default (left-to-right)
A UNION B EXCEPT C
-- Same as:
(A UNION B) EXCEPT C

-- Override with parentheses
A UNION (B EXCEPT C)
-- Different result!

-- Complex nesting
(
  (A UNION B)
  INTERSECT
  (C UNION D)
)
EXCEPT
E

-- Incremental building
-- Step 1:
SELECT * FROM A;
-- Step 2:
SELECT * FROM A UNION SELECT * FROM B;
-- Step 3:
(SELECT * FROM A UNION SELECT * FROM B) INTERSECT SELECT * FROM C;
-- Step 4: Add final EXCEPT...

-- Performance optimization
-- BAD (big operation first):
(BigTable UNION AnotherBigTable) INTERSECT SmallFilter

-- GOOD (filter early):
BigTable INTERSECT (SmallFilter UNION ...)
```

---

**Next:** [Lesson 10 - Test Your Knowledge](../10-test-your-knowledge/10-test-your-knowledge.sql)
