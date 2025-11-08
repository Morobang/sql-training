/*============================================
   LESSON 02: CARTESIAN PRODUCT
   What NOT to do when joining tables
   
   Estimated Time: 10 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS A CARTESIAN PRODUCT?
   Every row matched with every row
--------------------------------------------*/

/*
   A Cartesian Product occurs when you join tables WITHOUT a join condition.
   Result: Every row from Table A paired with EVERY row from Table B
   
   Example:
   Table A (3 rows)     Table B (2 rows)
   ┌────┐               ┌────┐
   │ A1 │               │ B1 │
   │ A2 │               │ B2 │
   │ A3 │               └────┘
   └────┘
   
   Cartesian Product = 3 × 2 = 6 rows:
   ┌────┬────┐
   │ A1 │ B1 │
   │ A1 │ B2 │  ← A1 paired with EVERY B row
   │ A2 │ B1 │
   │ A2 │ B2 │  ← A2 paired with EVERY B row
   │ A3 │ B1 │
   │ A3 │ B2 │  ← A3 paired with EVERY B row
   └────┴────┘
   
   If Table A has 1,000 rows and Table B has 1,000 rows:
   Cartesian Product = 1,000 × 1,000 = 1,000,000 rows! 😱
*/

/*--------------------------------------------
   PART 2: ACCIDENTAL CARTESIAN PRODUCT
   Common mistakes that cause this
--------------------------------------------*/

-- ❌ MISTAKE 1: Old-style join WITHOUT WHERE clause
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p, Inventory.Categories c;  -- DANGER!

-- This returns EVERY product paired with EVERY category!
-- If you have 50 products and 5 categories = 250 rows (should be ~50)

-- Check the row counts
SELECT 
    (SELECT COUNT(*) FROM Inventory.Products) AS Products,
    (SELECT COUNT(*) FROM Inventory.Categories) AS Categories,
    (SELECT COUNT(*) FROM Inventory.Products) * 
    (SELECT COUNT(*) FROM Inventory.Categories) AS CartesianProductRows;

/*--------------------------------------------
   PART 3: DEMONSTRATING THE PROBLEM
   See the explosion of rows
--------------------------------------------*/

-- Count products
SELECT COUNT(*) AS ProductCount FROM Inventory.Products;

-- Count categories
SELECT COUNT(*) AS CategoryCount FROM Inventory.Categories;

-- Cartesian product (no join condition)
SELECT COUNT(*) AS CartesianRows
FROM Inventory.Products p, Inventory.Categories c;

-- Notice: CartesianRows = ProductCount × CategoryCount

/*--------------------------------------------
   PART 4: VISUALIZING CARTESIAN PRODUCT
   Small example to see the duplication
--------------------------------------------*/

-- Let's see it with actual data (limited to see the pattern)
SELECT TOP 10
    p.ProductID,
    p.ProductName,
    p.CategoryID AS ProductCategoryID,
    c.CategoryID AS CategoryTableID,
    c.CategoryName
FROM Inventory.Products p, Inventory.Categories c
ORDER BY p.ProductID, c.CategoryID;

-- Notice: Each product appears multiple times,
-- paired with EVERY category (even wrong ones!)

/*--------------------------------------------
   PART 5: THE CORRECT WAY
   Using proper JOIN condition
--------------------------------------------*/

-- ✅ CORRECT: INNER JOIN with ON clause
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY p.ProductID;

-- Each product appears ONCE with its CORRECT category

/*--------------------------------------------
   PART 6: PERFORMANCE IMPACT
   Why Cartesian products are dangerous
--------------------------------------------*/

/*
   Real-world impact:
   
   Small tables (100 × 100):
   • Cartesian: 10,000 rows
   • Proper JOIN: ~100 rows
   • Wasted: 9,900 rows (99% waste!)
   
   Medium tables (10,000 × 10,000):
   • Cartesian: 100,000,000 rows
   • Proper JOIN: ~10,000 rows
   • Result: Database timeout, server crash!
   
   Large tables (1,000,000 × 1,000,000):
   • Cartesian: 1,000,000,000,000 rows
   • Result: Server meltdown, fired developer! 🔥
*/

-- Example: Check execution time difference
SET STATISTICS TIME ON;

-- Cartesian product (SLOW - commented out for safety!)
-- SELECT COUNT(*) FROM Inventory.Products, Inventory.Categories;

-- Proper join (FAST)
SELECT COUNT(*) 
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

SET STATISTICS TIME OFF;

/*--------------------------------------------
   PART 7: OLD-STYLE JOIN SYNTAX
   Why it's risky
--------------------------------------------*/

-- ❌ OLD STYLE: Comma-separated tables with WHERE
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p, Inventory.Categories c
WHERE p.CategoryID = c.CategoryID;  -- Join condition in WHERE

-- This works, BUT:
-- • Easy to forget WHERE clause (Cartesian product!)
-- • Mixes join logic with filtering logic
-- • Harder to read
-- • Not recommended in modern SQL

-- ✅ MODERN STYLE: Explicit INNER JOIN with ON
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- This is better because:
-- • Join condition is explicit and clear
-- • Can't forget it (syntax error without ON)
-- • Separates join logic from filtering
-- • Industry best practice

/*--------------------------------------------
   PART 8: MULTIPLE TABLE CARTESIAN PRODUCT
   Gets worse with more tables!
--------------------------------------------*/

-- ❌ THREE tables without join conditions
-- Products (50) × Categories (5) × Suppliers (10) = 2,500 rows!
-- SELECT * FROM Products, Categories, Suppliers;  -- DANGER!

-- ✅ CORRECT: Proper joins
SELECT 
    p.ProductName,
    c.CategoryName,
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Formula: 
-- Cartesian = Table1 × Table2 × Table3 × ...
-- Proper Join = SUM of matching rows

/*--------------------------------------------
   PART 9: HOW TO DETECT CARTESIAN PRODUCTS
   Warning signs
--------------------------------------------*/

-- Warning Sign 1: Row count explosion
-- If you expect ~100 rows but get 10,000+ → likely Cartesian product

-- Warning Sign 2: Duplicate data everywhere
-- Same row repeated many times with different combinations

-- Warning Sign 3: Query takes forever
-- Cartesian products process millions of unnecessary rows

-- How to check:
-- 1. Count expected rows
SELECT COUNT(*) FROM Inventory.Products;  -- Expected result size

-- 2. Count actual rows
SELECT COUNT(*) 
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- 3. If actual >> expected, investigate!

/*--------------------------------------------
   PART 10: WHEN CARTESIAN PRODUCTS ARE INTENTIONAL
   Rare valid use cases
--------------------------------------------*/

-- Sometimes you WANT all combinations (rare!)

-- Example: Generate all possible product-category pairs for analysis
SELECT 
    p.ProductName,
    c.CategoryName,
    CASE 
        WHEN p.CategoryID = c.CategoryID THEN 'Current Category'
        ELSE 'Alternative Category'
    END AS Relationship
FROM Inventory.Products p
CROSS JOIN Inventory.Categories c  -- Explicit Cartesian product
WHERE p.ProductID = 1;  -- Limited to one product for demo

-- CROSS JOIN explicitly says "I want all combinations"
-- Use this instead of comma syntax when intentional

/*--------------------------------------------
   PART 11: COMMON SCENARIOS THAT CAUSE CARTESIAN PRODUCTS
--------------------------------------------*/

-- Scenario 1: Missing join condition
-- SELECT * FROM Products p INNER JOIN Categories c;  -- ERROR (good!)
-- SELECT * FROM Products p, Categories c;  -- NO ERROR (bad!)

-- Scenario 2: Wrong join condition
SELECT COUNT(*) FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.ProductID = c.CategoryID;  -- WRONG columns!
-- Still runs, but produces garbage results

-- Scenario 3: Forgetting a join in multi-table query
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p, 
     Inventory.Categories c, 
     Inventory.Suppliers s
WHERE p.CategoryID = c.CategoryID;  -- Missing Supplier join!
-- Products × Suppliers Cartesian product!

-- ✅ CORRECT: All joins present
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

/*--------------------------------------------
   PART 12: DEBUGGING TIPS
--------------------------------------------*/

-- Tip 1: Build queries incrementally
-- Start with one join, verify, then add more

-- Step 1: One table
SELECT COUNT(*) FROM Inventory.Products;

-- Step 2: Add first join
SELECT COUNT(*) FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Step 3: Add second join
SELECT COUNT(*) FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- If row count explodes at any step, you found the problem!

/*--------------------------------------------
   PART 13: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. Write a query that produces a Cartesian product between Products and Categories
--    (Then fix it with proper JOIN)

-- 2. Calculate how many rows would result from a Cartesian product of:
--    Products, Categories, and Suppliers (without actually running it)

-- 3. Find and fix the Cartesian product in this query:
--    SELECT * FROM Products p, Orders o, Customers c
--    WHERE o.CustomerID = c.CustomerID;

-- 4. Why is INNER JOIN ON better than comma-separated tables?

-- 5. When would you intentionally use CROSS JOIN?

/*============================================
   KEY TAKEAWAYS
============================================*/

/*
   ✅ DO:
   • Use INNER JOIN with ON clause
   • Verify row counts make sense
   • Test queries on small datasets first
   • Build multi-table queries incrementally
   
   ❌ DON'T:
   • Use comma-separated tables without WHERE
   • Forget join conditions
   • Ignore unexpected row count increases
   • Use old-style join syntax in new code
   
   Remember: Cartesian Product = Every row × Every row = DISASTER!
*/

/*============================================
   NEXT: Lesson 03 - Inner Joins
   (Deep dive into proper join syntax)
============================================*/
