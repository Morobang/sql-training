-- =============================================
-- Lesson 03: Set Operators Overview
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Introduction to all three set operators: UNION, INTERSECT, EXCEPT
-- Estimated Time: 15 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: The Three Set Operators
-- =============================================

/*
SQL provides three main set operators:

1. UNION / UNION ALL
   └─ Combines results from both queries
   
2. INTERSECT
   └─ Returns only rows in BOTH queries
   
3. EXCEPT
   └─ Returns rows in first query NOT in second
*/

-- =============================================
-- Part 2: UNION Quick Demo
-- =============================================

-- Combine products from two categories
SELECT ProductID, ProductName, 'Electronics' AS Source
FROM Products
WHERE CategoryID = 1
UNION
SELECT ProductID, ProductName, 'Books' AS Source
FROM Products
WHERE CategoryID = 2;

-- Visual: All products from BOTH categories

-- =============================================
-- Part 3: INTERSECT Quick Demo
-- =============================================

-- Find customers who ordered in BOTH Q1 and Q2
SELECT DISTINCT CustomerID
FROM Orders
WHERE MONTH(OrderDate) IN (1,2,3)
INTERSECT
SELECT DISTINCT CustomerID
FROM Orders
WHERE MONTH(OrderDate) IN (4,5,6);

-- Visual: Only customers who appear in BOTH quarters

-- =============================================
-- Part 4: EXCEPT Quick Demo
-- =============================================

-- Find products that have NEVER been ordered
SELECT ProductID, ProductName
FROM Products
EXCEPT
SELECT DISTINCT p.ProductID, p.ProductName
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID;

-- Visual: Products in inventory but NOT in orders

-- =============================================
-- Part 5: Side-by-Side Comparison
-- =============================================

-- Define two sets for comparison
-- Set A: Products with Price > 100
-- Set B: Products with CategoryID = 1

-- UNION: Products with Price > 100 OR CategoryID = 1
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE Price > 100
UNION
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1;

-- INTERSECT: Products with Price > 100 AND CategoryID = 1
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE Price > 100
INTERSECT
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1;

-- EXCEPT: Products with Price > 100 but NOT in CategoryID = 1
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE Price > 100
EXCEPT
SELECT ProductID, ProductName, Price, CategoryID
FROM Products
WHERE CategoryID = 1;

-- =============================================
-- Part 6: Venn Diagram Visualization
-- =============================================

/*
Given Sets:
├─ Set A: {1, 2, 3, 4, 5}
└─ Set B: {4, 5, 6, 7, 8}

UNION (A ∪ B):
└─ Result: {1, 2, 3, 4, 5, 6, 7, 8}
   All unique values from both sets

INTERSECT (A ∩ B):
└─ Result: {4, 5}
   Only values in BOTH sets

EXCEPT (A - B):
└─ Result: {1, 2, 3}
   Values in A but NOT in B

EXCEPT (B - A):
└─ Result: {6, 7, 8}
   Values in B but NOT in A
*/

-- Practical example with test data
DECLARE @A TABLE (Val INT);
DECLARE @B TABLE (Val INT);

INSERT INTO @A VALUES (1), (2), (3), (4), (5);
INSERT INTO @B VALUES (4), (5), (6), (7), (8);

-- UNION
SELECT Val FROM @A
UNION
SELECT Val FROM @B;
-- Result: 1,2,3,4,5,6,7,8

-- INTERSECT
SELECT Val FROM @A
INTERSECT
SELECT Val FROM @B;
-- Result: 4,5

-- EXCEPT (A - B)
SELECT Val FROM @A
EXCEPT
SELECT Val FROM @B;
-- Result: 1,2,3

-- EXCEPT (B - A)
SELECT Val FROM @B
EXCEPT
SELECT Val FROM @A;
-- Result: 6,7,8

-- =============================================
-- Part 7: Common Requirements for All Operators
-- =============================================

-- All set operators require:
-- 1. Same number of columns
-- 2. Compatible data types
-- 3. Column order must match

-- ✅ VALID: Same column count and types
SELECT ProductID, ProductName FROM Products
UNION
SELECT CategoryID, CategoryName FROM Categories;

-- ❌ INVALID: Different column counts
/*
SELECT ProductID, ProductName, Price FROM Products
UNION
SELECT CategoryID, CategoryName FROM Categories;
-- ERROR!
*/

-- =============================================
-- Part 8: Duplicate Handling
-- =============================================

-- UNION removes duplicates
SELECT CategoryID FROM Products
UNION
SELECT CategoryID FROM Products;
-- Returns: Each CategoryID once

-- UNION ALL keeps duplicates
SELECT CategoryID FROM Products
UNION ALL
SELECT CategoryID FROM Products;
-- Returns: Each CategoryID twice

-- INTERSECT removes duplicates
SELECT CategoryID FROM Products
INTERSECT
SELECT CategoryID FROM Products;
-- Returns: Each CategoryID once

-- EXCEPT removes duplicates
SELECT CategoryID FROM Products
EXCEPT
SELECT CategoryID FROM Products WHERE 1 = 0;  -- Empty set
-- Returns: Each CategoryID once

-- =============================================
-- Part 9: Performance Comparison
-- =============================================

SET STATISTICS TIME ON;

-- UNION (slowest - removes duplicates)
SELECT ProductID FROM Products
UNION
SELECT ProductID FROM Products;

-- UNION ALL (fastest - keeps duplicates)
SELECT ProductID FROM Products
UNION ALL
SELECT ProductID FROM Products;

-- INTERSECT
SELECT ProductID FROM Products
INTERSECT
SELECT ProductID FROM Products;

-- EXCEPT
SELECT ProductID FROM Products
EXCEPT
SELECT ProductID FROM Products WHERE 1 = 0;

SET STATISTICS TIME OFF;

/*
Performance Ranking (Fastest → Slowest):
1. UNION ALL (no duplicate removal)
2. EXCEPT
3. INTERSECT
4. UNION (sorts to remove duplicates)
*/

-- =============================================
-- Part 10: Real-World Use Cases
-- =============================================

-- UNION: Consolidate regional data
SELECT CustomerID, FirstName, LastName FROM CustomersEast
UNION
SELECT CustomerID, FirstName, LastName FROM CustomersWest;

-- INTERSECT: Find common customers
SELECT CustomerID FROM Orders WHERE YEAR(OrderDate) = 2024
INTERSECT
SELECT CustomerID FROM Orders WHERE YEAR(OrderDate) = 2025;

-- EXCEPT: Find missing records
SELECT ProductID FROM Catalog
EXCEPT
SELECT ProductID FROM Inventory;

-- =============================================
-- Summary
-- =============================================
/*
SET OPERATORS COMPARISON:

┌─────────────┬──────────────────────┬──────────────┬─────────────┐
│  Operator   │    What It Does      │  Duplicates  │  Use Case   │
├─────────────┼──────────────────────┼──────────────┼─────────────┤
│ UNION       │ All from A or B      │  Removed     │ Combine all │
│ UNION ALL   │ All from A and B     │  Kept        │ Faster merge│
│ INTERSECT   │ Only in both A & B   │  Removed     │ Find common │
│ EXCEPT      │ In A but not in B    │  Removed     │ Find missing│
└─────────────┴──────────────────────┴──────────────┴─────────────┘

All Operators Require:
✅ Same number of columns
✅ Compatible data types
✅ Same column order

Key Differences:
├─ UNION: Combines everything (OR logic)
├─ INTERSECT: Only overlaps (AND logic)
└─ EXCEPT: Differences (NOT logic)

Performance:
├─ UNION ALL: Fastest
├─ EXCEPT: Fast
├─ INTERSECT: Medium
└─ UNION: Slowest (sorts for DISTINCT)

NEXT LESSONS:
├─ Lesson 04: UNION Operator (detailed)
├─ Lesson 05: INTERSECT Operator (detailed)
└─ Lesson 06: EXCEPT Operator (detailed)
*/
