# Lesson 06: EXCEPT Operator - Visual Guide

## What You'll Learn
- Finding differences between sets
- EXCEPT vs NOT IN vs NOT EXISTS
- Asymmetric nature of EXCEPT
- Real-world difference detection

---

## What is EXCEPT?

**EXCEPT** returns rows from the first query that are NOT in the second query.

```
┌────────────────────────────────────────────────────┐
│               EXCEPT Visualization                 │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A (All Products):  Set B (Ordered Products):  │
│  ┌───────────┐          ┌───────────┐            │
│  │ Laptop    │          │ Laptop    │            │
│  │ Mouse     │          │ Mouse     │            │
│  │ Monitor   │          │ Monitor   │            │
│  │ Keyboard  │          └───────────┘            │
│  │ Webcam    │                                     │
│  │ Headset   │                                     │
│  └───────────┘                                     │
│        ↓                      ↓                     │
│        └─────── EXCEPT ───────┘                    │
│                  ↓                                  │
│          ┌──────────┐                              │
│          │ Keyboard │ Never ordered!               │
│          │ Webcam   │                              │
│          │ Headset  │                              │
│          └──────────┘                              │
│                                                     │
│  A EXCEPT B = Items in A but NOT in B              │
└────────────────────────────────────────────────────┘
```

### Venn Diagram

```
┌────────────────────────────────────────────────────┐
│              EXCEPT Venn Diagram                   │
├────────────────────────────────────────────────────┤
│                                                     │
│        Set A              Set B                    │
│      ╭─────────╮       ╭─────────╮                │
│      │         │       │         │                │
│      │█████████│       │         │                │
│      │███A only│       │   B     │                │
│      │█████████│       │         │                │
│      ╰─────────╯       ╰─────────╯                │
│                                                     │
│  █ A only: RETURNED ✓                             │
│  ⚫ Overlap (A ∩ B): Discarded                    │
│  ⚫ B only: Discarded                              │
│                                                     │
│  A EXCEPT B ≠ B EXCEPT A                          │
│  (Order matters!)                                  │
└────────────────────────────────────────────────────┘
```

---

## EXCEPT is NOT Symmetric

**Critical:** A EXCEPT B ≠ B EXCEPT A

```
┌────────────────────────────────────────────────────┐
│             Asymmetric Behavior                    │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A = {1, 2, 3, 4}                             │
│  Set B = {3, 4, 5, 6}                             │
│                                                     │
│  A EXCEPT B:                                       │
│  ┌─────────────────────────────────┐              │
│  │ Items in A but NOT in B          │              │
│  │ Result: {1, 2}                   │              │
│  └─────────────────────────────────┘              │
│                                                     │
│  B EXCEPT A:                                       │
│  ┌─────────────────────────────────┐              │
│  │ Items in B but NOT in A          │              │
│  │ Result: {5, 6}                   │              │
│  └─────────────────────────────────┘              │
│                                                     │
│  Visual:                                           │
│        A              B                            │
│      ╭───╮         ╭───╮                          │
│      │ 1 │   3,4   │ 5 │                          │
│      │ 2 │   ∩     │ 6 │                          │
│      ╰───╯         ╰───╯                          │
│       ↑              ↑                              │
│   A EXCEPT B    B EXCEPT A                         │
│                                                     │
│  Different results!                                │
└────────────────────────────────────────────────────┘
```

### Customer Example

```
┌────────────────────────────────────────────────────┐
│          Customer Comparison Example               │
├────────────────────────────────────────────────────┤
│                                                     │
│  2024 Customers:        2025 Customers:            │
│  ┌─────────┐           ┌─────────┐               │
│  │ C001    │           │ C001    │               │
│  │ C002    │           │ C003    │               │
│  │ C003    │           │ C004    │               │
│  └─────────┘           └─────────┘               │
│                                                     │
│  2024 EXCEPT 2025 (Lost customers):                │
│  ┌─────────┐                                       │
│  │ C002    │ ← Ordered in 2024, NOT in 2025       │
│  └─────────┘                                       │
│                                                     │
│  2025 EXCEPT 2024 (New customers):                 │
│  ┌─────────┐                                       │
│  │ C004    │ ← Ordered in 2025, NOT in 2024       │
│  └─────────┘                                       │
│                                                     │
│  Completely different insights!                    │
└────────────────────────────────────────────────────┘
```

---

## Finding Missing Records

```
┌────────────────────────────────────────────────────┐
│           Unsold Products Detection                │
├────────────────────────────────────────────────────┤
│                                                     │
│  All Products:          Sold Products:             │
│  ┌─────┬──────────┐    ┌─────┬──────────┐        │
│  │ ID  │   Name   │    │ ID  │   Name   │        │
│  ├─────┼──────────┤    ├─────┼──────────┤        │
│  │  1  │  Laptop  │    │  1  │  Laptop  │        │
│  │  2  │  Mouse   │    │  2  │  Mouse   │        │
│  │  3  │  Monitor │    │  5  │  Camera  │        │
│  │  4  │  Keyboard│    └─────┴──────────┘        │
│  │  5  │  Camera  │                                │
│  │  6  │  Webcam  │                                │
│  │  7  │  Headset │                                │
│  └─────┴──────────┘                                │
│        ↓                      ↓                     │
│        └─────── EXCEPT ───────┘                    │
│                  ↓                                  │
│     ┌─────┬──────────┐                            │
│     │ ID  │   Name   │                            │
│     ├─────┼──────────┤                            │
│     │  3  │  Monitor │ Never sold!                │
│     │  4  │  Keyboard│                            │
│     │  6  │  Webcam  │                            │
│     │  7  │  Headset │                            │
│     └─────┴──────────┘                            │
│                                                     │
│  Action: Discount or discontinue these products    │
└────────────────────────────────────────────────────┘
```

---

## Multi-Column EXCEPT

ALL columns must match to be excluded.

```
┌────────────────────────────────────────────────────┐
│         Multi-Column EXCEPT Example                │
├────────────────────────────────────────────────────┤
│                                                     │
│  All Customer-City Combos:                         │
│  ┌────────────┬──────────┐                        │
│  │ CustomerID │   City   │                        │
│  ├────────────┼──────────┤                        │
│  │    C001    │   NYC    │                        │
│  │    C001    │   LA     │                        │
│  │    C002    │   NYC    │                        │
│  │    C003    │   CHI    │                        │
│  └────────────┴──────────┘                        │
│                                                     │
│  Recently Ordered From:                            │
│  ┌────────────┬──────────┐                        │
│  │ CustomerID │   City   │                        │
│  ├────────────┼──────────┤                        │
│  │    C001    │   NYC    │ ← Exact match          │
│  │    C003    │   CHI    │ ← Exact match          │
│  └────────────┴──────────┘                        │
│                                                     │
│  EXCEPT Result (Inactive locations):               │
│  ┌────────────┬──────────┐                        │
│  │ CustomerID │   City   │                        │
│  ├────────────┼──────────┤                        │
│  │    C001    │   LA     │ No recent orders       │
│  │    C002    │   NYC    │ No recent orders       │
│  └────────────┴──────────┘                        │
│                                                     │
│  Why included?                                     │
│  • (C001, LA): Customer+City combo not in Set B   │
│  • (C002, NYC): Customer not in Set B at all      │
│  • (C001, NYC): EXCLUDED (in both sets)           │
│  • (C003, CHI): EXCLUDED (in both sets)           │
└────────────────────────────────────────────────────┘
```

---

## Temporal Queries with EXCEPT

Finding changes over time:

```
┌────────────────────────────────────────────────────┐
│            Finding Discontinued Products           │
├────────────────────────────────────────────────────┤
│                                                     │
│  Products Sold in Q1:   Products Sold in Q2:       │
│  ┌──────────┐          ┌──────────┐               │
│  │ Laptop   │          │ Laptop   │               │
│  │ Mouse    │          │ Mouse    │               │
│  │ Monitor  │          │ Tablet   │               │
│  │ Keyboard │          │ Webcam   │               │
│  │ Camera   │          └──────────┘               │
│  └──────────┘                                       │
│        ↓                      ↓                     │
│        └─────── EXCEPT ───────┘                    │
│                  ↓                                  │
│          ┌──────────┐                              │
│          │ Monitor  │ Sold Q1, not Q2              │
│          │ Keyboard │ → Discontinued?              │
│          │ Camera   │                              │
│          └──────────┘                              │
│                                                     │
│  Query:                                            │
│  SELECT DISTINCT ProductID                         │
│  FROM OrderDetails od                              │
│  JOIN Orders o ON od.OrderID = o.OrderID           │
│  WHERE o.OrderDate BETWEEN '2025-01-01'            │
│    AND '2025-03-31'                                │
│  EXCEPT                                            │
│  SELECT DISTINCT ProductID                         │
│  FROM OrderDetails od                              │
│  JOIN Orders o ON od.OrderID = o.OrderID           │
│  WHERE o.OrderDate BETWEEN '2025-04-01'            │
│    AND '2025-06-30'                                │
└────────────────────────────────────────────────────┘
```

---

## EXCEPT vs NOT IN vs NOT EXISTS

Three ways to find differences:

```
┌────────────────────────────────────────────────────┐
│      EXCEPT vs NOT IN vs NOT EXISTS                │
├────────────────────────────────────────────────────┤
│                                                     │
│  Goal: Products never ordered                      │
│                                                     │
│  Method 1: EXCEPT (Set-based)                      │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT ProductID FROM Products       │         │
│  │ EXCEPT                                │         │
│  │ SELECT ProductID FROM OrderDetails   │         │
│  │                                       │         │
│  │ Pros: Clean, readable                │         │
│  │ Cons: Slower for large sets          │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Method 2: NOT IN (Subquery)                       │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT ProductID FROM Products       │         │
│  │ WHERE ProductID NOT IN (              │         │
│  │   SELECT ProductID                    │         │
│  │   FROM OrderDetails                   │         │
│  │ )                                     │         │
│  │                                       │         │
│  │ Pros: Familiar syntax                │         │
│  │ Cons: NULL issues, slow              │         │
│  │ ⚠ NULL in subquery = no results!    │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Method 3: NOT EXISTS (Correlated)                 │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT p.ProductID                    │         │
│  │ FROM Products p                       │         │
│  │ WHERE NOT EXISTS (                    │         │
│  │   SELECT 1 FROM OrderDetails od       │         │
│  │   WHERE od.ProductID = p.ProductID    │         │
│  │ )                                     │         │
│  │                                       │         │
│  │ Pros: Fastest, handles NULLs         │         │
│  │ Cons: More complex syntax            │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  Performance (1M rows):                            │
│  ┌────────────┬──────────┐                        │
│  │   Method   │   Time   │                        │
│  ├────────────┼──────────┤                        │
│  │ NOT EXISTS │  0.8s    │ ← Fastest!             │
│  │ EXCEPT     │  2.1s    │                        │
│  │ NOT IN     │  4.5s    │ ← Slowest              │
│  └────────────┴──────────┘                        │
└────────────────────────────────────────────────────┘
```

---

## NULL Handling in EXCEPT

EXCEPT treats NULL = NULL (same as INTERSECT):

```
┌────────────────────────────────────────────────────┐
│             NULL Behavior in EXCEPT                │
├────────────────────────────────────────────────────┤
│                                                     │
│  Set A:                  Set B:                    │
│  ┌──────────┐          ┌──────────┐               │
│  │  Email   │          │  Email   │               │
│  ├──────────┤          ├──────────┤               │
│  │ john@co  │          │ sara@co  │               │
│  │ NULL     │          │ NULL     │               │
│  │ mike@co  │          └──────────┘               │
│  └──────────┘                                       │
│        ↓                      ↓                     │
│        └─────── EXCEPT ───────┘                    │
│                  ↓                                  │
│            ┌──────────┐                            │
│            │  Email   │                            │
│            ├──────────┤                            │
│            │ john@co  │                            │
│            │ mike@co  │                            │
│            └──────────┘                            │
│         NULLs matched and excluded!                │
│                                                     │
│  Comparison with NOT IN:                           │
│  ┌──────────────────────────────────────┐         │
│  │ SELECT Email FROM Customers          │         │
│  │ WHERE Email NOT IN (                 │         │
│  │   SELECT Email FROM Prospects        │         │
│  │ )                                     │         │
│  │                                       │         │
│  │ If Prospects has NULL Email:         │         │
│  │ → Returns ZERO rows! (NULL issue)    │         │
│  └──────────────────────────────────────┘         │
│                                                     │
│  EXCEPT handles NULLs correctly!                   │
└────────────────────────────────────────────────────┘
```

---

## Real-World Use Cases

### Use Case 1: Inactive Customers

```
┌────────────────────────────────────────────────────┐
│          Finding Inactive Customers                │
├────────────────────────────────────────────────────┤
│                                                     │
│  Goal: Customers who stopped ordering              │
│                                                     │
│  All Customers:         Recent Customers:          │
│  ┌─────────┐           ┌─────────┐               │
│  │ C001    │           │ C001    │               │
│  │ C002    │           │ C003    │               │
│  │ C003    │           └─────────┘               │
│  │ C004    │                                       │
│  │ C005    │                                       │
│  └─────────┘                                       │
│        ↓                      ↓                     │
│        └─────── EXCEPT ───────┘                    │
│                  ↓                                  │
│          ┌─────────┐                               │
│          │ C002    │ No orders in 90 days          │
│          │ C004    │ → Send reactivation email     │
│          │ C005    │                               │
│          └─────────┘                               │
│                                                     │
│  Query:                                            │
│  SELECT DISTINCT CustomerID                        │
│  FROM Customers                                    │
│  EXCEPT                                            │
│  SELECT DISTINCT CustomerID                        │
│  FROM Orders                                       │
│  WHERE OrderDate >= DATEADD(DAY, -90, GETDATE())   │
│                                                     │
│  Action: Targeted marketing campaign               │
└────────────────────────────────────────────────────┘
```

### Use Case 2: Feature Gaps

```
┌────────────────────────────────────────────────────┐
│       Missing Product Features Analysis            │
├────────────────────────────────────────────────────┤
│                                                     │
│  All Required Features: Features We Have:          │
│  ┌──────────────┐      ┌──────────────┐          │
│  │ WiFi         │      │ WiFi         │          │
│  │ Bluetooth    │      │ Bluetooth    │          │
│  │ USB-C        │      │ HDMI         │          │
│  │ HDMI         │      └──────────────┘          │
│  │ 4K Display   │                                  │
│  │ Touchscreen  │                                  │
│  └──────────────┘                                  │
│        ↓                      ↓                     │
│        └─────── EXCEPT ───────┘                    │
│                  ↓                                  │
│          ┌──────────────┐                          │
│          │ USB-C        │ Missing features         │
│          │ 4K Display   │ → R&D priorities         │
│          │ Touchscreen  │                          │
│          └──────────────┘                          │
│                                                     │
│  Query identifies product gaps for development     │
└────────────────────────────────────────────────────┘
```

---

## Common Patterns

### Pattern 1: Data Validation

```sql
-- Find records in staging that aren't in production
SELECT OrderID, CustomerID, OrderDate
FROM StagingOrders
EXCEPT
SELECT OrderID, CustomerID, OrderDate
FROM ProductionOrders;

-- Result: New orders to migrate
```

### Pattern 2: Audit Changes

```sql
-- Find customers who updated their info
SELECT CustomerID, Email, Phone
FROM Customers_2025
EXCEPT
SELECT CustomerID, Email, Phone
FROM Customers_2024;

-- Result: Changed customer records
```

### Pattern 3: Missing Inventory

```sql
-- Products we should have but don't
SELECT ProductID, ProductName
FROM ProductCatalog
EXCEPT
SELECT ProductID, ProductName
FROM InventoryOnHand
WHERE Quantity > 0;

-- Result: Out of stock items
```

---

## Key Takeaways

```
✅ EXCEPT Basics:
  • Returns rows in first set NOT in second
  • Removes duplicates automatically
  • ALL columns must match to exclude
  • NULL = NULL (matches and excludes)

✅ Critical Concepts:
  • NOT symmetric: A-B ≠ B-A
  • Order matters greatly
  • First query defines output columns
  • Can chain multiple EXCEPTs

✅ Use Cases:
  • Finding missing records
  • Inactive customers/products
  • Data discrepancies
  • Temporal changes
  • Audit trails

✅ Performance:
  • NOT EXISTS usually fastest
  • EXCEPT middle ground
  • NOT IN slowest + NULL issues
  • Filter early for best speed
```

---

## Quick Reference

```sql
-- Basic EXCEPT
SELECT columns FROM table1 WHERE condition1
EXCEPT
SELECT columns FROM table2 WHERE condition2;

-- Lost customers (ordered before, not now)
SELECT CustomerID FROM Orders WHERE Year = 2024
EXCEPT
SELECT CustomerID FROM Orders WHERE Year = 2025;

-- New customers (ordered now, not before)
SELECT CustomerID FROM Orders WHERE Year = 2025
EXCEPT
SELECT CustomerID FROM Orders WHERE Year = 2024;

-- Multi-column difference
SELECT ProductID, CategoryID, Price FROM Products_Old
EXCEPT
SELECT ProductID, CategoryID, Price FROM Products_New;

-- Alternative with NOT EXISTS (faster)
SELECT p.ProductID
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);
```

---

**Next:** [Lesson 07 - Set Operation Rules](../07-set-operation-rules/07-set-operation-rules.sql)
