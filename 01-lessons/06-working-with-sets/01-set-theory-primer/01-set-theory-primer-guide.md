# Lesson 01: Set Theory Primer - Visual Guide

## What You'll Learn
- Mathematical foundations of set theory
- How sets work in SQL
- Set properties and relationships
- Visual understanding of set concepts

---

## What is a Set?

A **set** is a collection of distinct elements.

```
┌────────────────────────────────────────────────────┐
│                  Set Visualization                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  Mathematical Set:                                 │
│  A = {1, 2, 3, 4, 5}                              │
│                                                     │
│  SQL Set (Query Result):                           │
│  ┌────────────┬─────────────┐                     │
│  │ ProductID  │ ProductName │                     │
│  ├────────────┼─────────────┤                     │
│  │     1      │   Laptop    │  ← Element 1       │
│  │     2      │   Mouse     │  ← Element 2       │
│  │     3      │   Monitor   │  ← Element 3       │
│  └────────────┴─────────────┘                     │
│                                                     │
│  Each row = one element in the set                 │
└────────────────────────────────────────────────────┘
```

---

## Set Properties

```
┌────────────────────────────────────────────────────┐
│           Three Key Set Properties                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  1. DISTINCT (No Duplicates)                       │
│     ┌─────────────┐                                │
│     │ 1, 2, 3, 3  │  ❌ Not a set (has duplicate)  │
│     │ 1, 2, 3     │  ✅ Valid set (all unique)     │
│     └─────────────┘                                │
│                                                     │
│  2. UNORDERED (Mathematically)                     │
│     {1, 2, 3} = {3, 2, 1} = {2, 3, 1}             │
│     All represent the SAME set                     │
│                                                     │
│  3. CAN BE EMPTY                                   │
│     ∅ = {} = Empty set (zero elements)            │
│                                                     │
└────────────────────────────────────────────────────┘
```

### In SQL

```sql
-- DISTINCT removes duplicates → creates proper set
SELECT DISTINCT CategoryID FROM Products;

-- Same data, different order = same set
SELECT ProductName FROM Products ORDER BY ProductName;
SELECT ProductName FROM Products ORDER BY Price;

-- Empty set
SELECT * FROM Products WHERE Price < 0;  -- No results = ∅
```

---

## Set Membership

An element either **IS** or **IS NOT** in a set.

```
┌────────────────────────────────────────────────────┐
│              Set Membership Check                  │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A = Products:                                 │
│  ┌────┬──────────┐                                 │
│  │ ID │   Name   │                                 │
│  ├────┼──────────┤                                 │
│  │ 1  │  Laptop  │ ← ProductID 1 ∈ A (in set)     │
│  │ 2  │  Mouse   │                                 │
│  │ 3  │  Monitor │                                 │
│  └────┴──────────┘                                 │
│                                                     │
│  Checks:                                           │
│  • ProductID 1 ∈ A? YES ✓                         │
│  • ProductID 999 ∈ A? NO ✗                        │
│                                                     │
│  SQL:                                              │
│  EXISTS (SELECT 1 FROM Products WHERE ID = 1)      │
│  → TRUE                                            │
│                                                     │
└────────────────────────────────────────────────────┘
```

---

## Subsets

A **subset** contains only elements that are in another set.

```
┌────────────────────────────────────────────────────┐
│                 Subset Concept                     │
├────────────────────────────────────────────────────┤
│                                                     │
│  Universal Set (All Products):                     │
│  ┌────────────────────────────────────┐           │
│  │  Laptop, Mouse, Monitor,           │           │
│  │  Novel, Cookbook, Shirt            │           │
│  └────────────────────────────────────┘           │
│            ↑                                        │
│            │                                        │
│  Subset (Electronics only):                        │
│  ┌────────────────────────────────────┐           │
│  │  Laptop, Mouse, Monitor            │ ⊆ Products│
│  └────────────────────────────────────┘           │
│                                                     │
│  Visual:                                           │
│     ╭─────────────────────╮                        │
│     │ All Products        │                        │
│     │  ╭──────────────╮   │                        │
│     │  │ Electronics  │   │ ← Subset              │
│     │  ╰──────────────╯   │                        │
│     ╰─────────────────────╯                        │
│                                                     │
│  Electronics ⊆ Products                            │
└────────────────────────────────────────────────────┘
```

### SQL Example

```sql
-- Universal set
SELECT ProductID, ProductName FROM Products;

-- Subset: Electronics only
SELECT ProductID, ProductName 
FROM Products 
WHERE CategoryID = 1;  -- ⊆ All Products
```

---

## Cardinality (Set Size)

**Cardinality** = number of elements in a set

```
┌────────────────────────────────────────────────────┐
│                   Cardinality                      │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A = {1, 2, 3, 4, 5}                          │
│  |A| = 5  (Cardinality is 5)                      │
│                                                     │
│  Empty Set:                                        │
│  ∅ = {}                                            │
│  |∅| = 0  (Cardinality is 0)                      │
│                                                     │
│  SQL Examples:                                     │
│  ┌──────────────────┬─────────────┐               │
│  │      Query       │ Cardinality │               │
│  ├──────────────────┼─────────────┤               │
│  │ SELECT * FROM    │     10      │               │
│  │ Products         │             │               │
│  ├──────────────────┼─────────────┤               │
│  │ SELECT DISTINCT  │      3      │               │
│  │ CategoryID       │             │               │
│  ├──────────────────┼─────────────┤               │
│  │ WHERE Price < 0  │      0      │               │
│  └──────────────────┴─────────────┘               │
└────────────────────────────────────────────────────┘
```

```sql
-- Count elements (cardinality)
SELECT COUNT(*) AS Cardinality FROM Products;

-- Cardinality of distinct set
SELECT COUNT(DISTINCT CategoryID) FROM Products;
```

---

## Venn Diagrams - The Visual Foundation

Venn diagrams show relationships between sets.

```
┌────────────────────────────────────────────────────┐
│              Basic Venn Diagrams                   │
├────────────────────────────────────────────────────┤
│                                                     │
│  Two Sets (A and B):                               │
│                                                     │
│      Set A          Set B                          │
│      ╭─────╮     ╭─────╮                          │
│      │     │     │     │                          │
│      │  A  │     │  B  │                          │
│      │     │     │     │                          │
│      ╰─────╯     ╰─────╯                          │
│                                                     │
│  Overlapping Sets:                                 │
│                                                     │
│      Set A          Set B                          │
│      ╭─────╮     ╭─────╮                          │
│      │     │█████│     │                          │
│      │  A  │█████│  B  │                          │
│      │     │█████│     │                          │
│      ╰─────╯█████╰─────╯                          │
│            Overlap                                 │
│         (A ∩ B)                                    │
│                                                     │
│  Three Regions:                                    │
│  1. Only in A (not in B)                          │
│  2. In both A and B (overlap)                     │
│  3. Only in B (not in A)                          │
└────────────────────────────────────────────────────┘
```

### SQL Example

```sql
-- Set A: Price > 100
SELECT ProductID FROM Products WHERE Price > 100;

-- Set B: CategoryID = 1
SELECT ProductID FROM Products WHERE CategoryID = 1;

-- Overlap (A ∩ B): Both conditions
SELECT ProductID 
FROM Products 
WHERE Price > 100 AND CategoryID = 1;
```

---

## Set Operations Preview

```
┌────────────────────────────────────────────────────┐
│          Three Main Set Operations                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  1. UNION (A ∪ B) - All from A or B               │
│     ╭─────╮     ╭─────╮                           │
│     │█████│█████│█████│                           │
│     │█████│█████│█████│                           │
│     ╰─────╯█████╰─────╯                           │
│            Everything                              │
│                                                     │
│  2. INTERSECT (A ∩ B) - Only in both              │
│     ╭─────╮     ╭─────╮                           │
│     │     │█████│     │                           │
│     │     │█████│     │                           │
│     ╰─────╯█████╰─────╯                           │
│            Overlap                                 │
│                                                     │
│  3. EXCEPT (A - B) - In A but not B               │
│     ╭─────╮     ╭─────╮                           │
│     │█████│     │     │                           │
│     │█████│     │     │                           │
│     ╰─────╯     ╰─────╯                           │
│       A only                                       │
└────────────────────────────────────────────────────┘
```

---

## Complement

The **complement** of set A = all elements NOT in A

```
┌────────────────────────────────────────────────────┐
│                   Complement                       │
├────────────────────────────────────────────────────┤
│                                                     │
│  Universal Set (U):                                │
│  ┌────────────────────────────────────────┐       │
│  │                                         │       │
│  │    Set A:                               │       │
│  │    ╭─────────╮                          │       │
│  │ ░░░│ A       │░░░░░░░░░░░░░░░░░░░░░░░░ │       │
│  │ ░░░│         │░░░░░░░░░░░░░░░░░░░░░░░░ │       │
│  │ ░░░╰─────────╯░░░░░░░░░░░░░░░░░░░░░░░░ │       │
│  │ ░░░░░░ NOT A (Complement) ░░░░░░░░░░░░ │       │
│  └────────────────────────────────────────┘       │
│                                                     │
│  Complement of A = U - A                           │
│  (Everything except A)                             │
└────────────────────────────────────────────────────┘
```

### SQL Example

```sql
-- Set A: Electronics
SELECT ProductID, ProductName 
FROM Products 
WHERE CategoryID = 1;

-- Complement: NOT Electronics
SELECT ProductID, ProductName 
FROM Products 
WHERE CategoryID <> 1 OR CategoryID IS NULL;
```

---

## Practical Example: Customer Sets

```
┌────────────────────────────────────────────────────┐
│         Customer Ordering Patterns                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set J = Customers who ordered in January:         │
│  {C001, C002, C003, C005}                         │
│                                                     │
│  Set F = Customers who ordered in February:        │
│  {C001, C003, C004, C006}                         │
│                                                     │
│  Venn Diagram:                                     │
│        J              F                            │
│      ╭─────╮       ╭─────╮                        │
│      │ C002│ C001  │ C004│                        │
│      │ C005│ C003  │ C006│                        │
│      ╰─────╯       ╰─────╯                        │
│         ↑      ↑       ↑                           │
│      Jan    Both    Feb                            │
│      only   months  only                           │
│                                                     │
│  Analysis:                                         │
│  • C001, C003: Ordered BOTH months (loyal)        │
│  • C002, C005: January only (at risk?)            │
│  • C004, C006: February only (new?)               │
└────────────────────────────────────────────────────┘
```

---

## Empty Set

The **empty set** (∅) contains zero elements.

```
┌────────────────────────────────────────────────────┐
│                    Empty Set                       │
├────────────────────────────────────────────────────┤
│                                                     │
│  Mathematical: ∅ = {}                              │
│                                                     │
│  SQL Empty Set Examples:                           │
│                                                     │
│  1. Impossible condition:                          │
│     SELECT * FROM Products WHERE 1 = 0;            │
│     Result: (empty) → ∅                            │
│                                                     │
│  2. No matching data:                              │
│     SELECT * FROM Products WHERE Price < 0;        │
│     Result: (empty) → ∅                            │
│                                                     │
│  3. Contradictory condition:                       │
│     WHERE ProductID IS NULL                        │
│       AND ProductID IS NOT NULL;                   │
│     Result: (empty) → ∅                            │
│                                                     │
│  Properties:                                       │
│  • |∅| = 0 (cardinality is zero)                  │
│  • ∅ ⊆ A for any set A (subset of everything)    │
│  • A ∪ ∅ = A (union with empty = original)       │
│  • A ∩ ∅ = ∅ (intersect with empty = empty)      │
└────────────────────────────────────────────────────┘
```

---

## Set Equality

Two sets are **equal** if they contain exactly the same elements.

```
┌────────────────────────────────────────────────────┐
│                  Set Equality                      │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A = {1, 2, 3}                                │
│  Set B = {3, 2, 1}  (different order)             │
│  Set C = {1, 2, 3}                                │
│                                                     │
│  A = B? YES ✓ (same elements, order doesn't matter)│
│  A = C? YES ✓ (identical)                         │
│  B = C? YES ✓ (same elements)                     │
│                                                     │
│  Set D = {1, 2}                                   │
│  A = D? NO ✗ (D missing element 3)                │
│                                                     │
│  SQL Example:                                      │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT ProductID FROM Products       │         │
│  │ WHERE CategoryID = 1                 │         │
│  │ ORDER BY ProductID;                  │         │
│  │ → {1, 2, 5}                          │         │
│  │                                       │         │
│  │ SELECT ProductID FROM Products       │         │
│  │ WHERE CategoryID = 1                 │         │
│  │ ORDER BY Price DESC;                 │         │
│  │ → {5, 2, 1}  (different order)       │         │
│  │                                       │         │
│  │ Same set! Order doesn't matter       │         │
│  └──────────────────────────────────────┘         │
└────────────────────────────────────────────────────┘
```

---

## Real-World Set Example

```
┌────────────────────────────────────────────────────┐
│           Product Ordering Analysis                │
├────────────────────────────────────────────────────┤
│                                                     │
│  Universal Set: All Products (10 items)            │
│  ┌────────────────────────────────────────────┐   │
│  │                                             │   │
│  │  Ordered Products (7 items)                │   │
│  │  ╭────────────────────────────╮            │   │
│  │  │ Laptop, Mouse, Monitor,    │            │   │
│  │  │ Novel, Cookbook, Camera,   │  ░░░░░░░   │   │
│  │  │ Desk                       │  ░ Never ░ │   │
│  │  ╰────────────────────────────╯  ░Ordered░ │   │
│  │                                  ░░░░░░░   │   │
│  │  (Shirt, Lamp, Chair)                      │   │
│  └────────────────────────────────────────────┘   │
│                                                     │
│  Sets:                                             │
│  • All Products = Universal set (10)              │
│  • Ordered = Subset (7)                           │
│  • Never Ordered = Complement (3)                 │
│                                                     │
│  Queries:                                          │
│  • Ordered: SELECT p.* FROM Products p             │
│             WHERE EXISTS (SELECT 1 FROM            │
│             OrderDetails od WHERE od.ProductID     │
│             = p.ProductID)                         │
│                                                     │
│  • Never Ordered: SELECT p.* FROM Products p       │
│                   WHERE NOT EXISTS (...)           │
└────────────────────────────────────────────────────┘
```

---

## Key Takeaways

```
✅ SET BASICS:
  • Set = Collection of distinct elements
  • Each row in query result = one element
  • Sets have no duplicates (use DISTINCT)
  • Order doesn't matter (mathematically)

✅ IMPORTANT CONCEPTS:
  • Membership: element ∈ set or ∉ set
  • Cardinality: |A| = number of elements
  • Subset: A ⊆ B (all A's elements in B)
  • Complement: NOT A (everything except A)
  • Empty set: ∅ (zero elements)

✅ VENN DIAGRAMS:
  • Show set relationships visually
  • Overlap = elements in both sets
  • Outside = elements in neither set
  • Foundation for understanding operations

✅ SQL CONNECTIONS:
  • Query result = set of rows
  • DISTINCT = remove duplicates
  • COUNT(*) = cardinality
  • EXISTS = membership check
  • WHERE = define set conditions
```

---

## Quick Reference

### Set Theory Symbols

```
∈  "element of"           5 ∈ {1,2,3,4,5}
∉  "not element of"       9 ∉ {1,2,3,4,5}
⊆  "subset of"            {1,2} ⊆ {1,2,3}
∪  "union"                {1,2} ∪ {2,3} = {1,2,3}
∩  "intersection"         {1,2} ∩ {2,3} = {2}
−  "difference"           {1,2,3} − {2,3} = {1}
∅  "empty set"            {} or ∅
|A| "cardinality"         |{1,2,3}| = 3
```

### SQL Equivalents

```sql
-- Membership
EXISTS (SELECT 1 FROM Table WHERE condition)

-- Cardinality
SELECT COUNT(*) FROM Table

-- Subset
SELECT * FROM Table WHERE condition  -- ⊆ All rows

-- Complement
SELECT * FROM Table WHERE NOT condition

-- Empty set
SELECT * FROM Table WHERE 1 = 0
```

---

**Next:** [Lesson 02 - Set Theory Practice](../02-set-theory-practice/02-set-theory-practice.sql)
