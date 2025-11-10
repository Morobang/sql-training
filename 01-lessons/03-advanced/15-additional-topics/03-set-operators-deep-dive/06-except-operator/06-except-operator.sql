-- =============================================
-- Lesson 06: EXCEPT Operator
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Finding differences between two queries using EXCEPT
-- Estimated Time: 20 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: What is EXCEPT?
-- =============================================
-- EXCEPT returns rows from the first query that are NOT in the second query
-- Also called "set difference" or "minus" in some databases

-- Basic EXCEPT example
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 500;

/*
Visual:
Set A (CategoryID 1):      Set B (Price > 500):
┌──────────┐              ┌──────────┐
│ Laptop   │              │ Laptop   │
│ Mouse    │              └──────────┘
│ Keyboard │
└──────────┘
        ↓ EXCEPT ↓
┌──────────┐
│ Mouse    │  ← In A but NOT in B
│ Keyboard │
└──────────┘
*/

-- =============================================
-- Part 2: EXCEPT is NOT Symmetric
-- =============================================

-- A EXCEPT B
SELECT ProductName
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductName
FROM Products
WHERE Price > 100;
-- Returns: Products in Category 1 that cost ≤ $100

-- B EXCEPT A (opposite direction)
SELECT ProductName
FROM Products
WHERE Price > 100
EXCEPT
SELECT ProductName
FROM Products
WHERE CategoryID = 1;
-- Returns: Products > $100 that are NOT in Category 1

-- IMPORTANT: Order matters! A EXCEPT B ≠ B EXCEPT A

-- =============================================
-- Part 3: Find Missing Records
-- =============================================

-- Find customers who have NOT placed any orders
SELECT CustomerID, FirstName, LastName
FROM Customers
EXCEPT
SELECT c.CustomerID, c.FirstName, c.LastName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

/*
Visual:
All Customers:         Customers with Orders:
┌──────────┐          ┌──────────┐
│ C001     │          │ C001     │
│ C002     │          │ C003     │
│ C003     │          └──────────┘
│ C004     │
└──────────┘
        ↓ EXCEPT ↓
┌──────────┐
│ C002     │  ← Never ordered
│ C004     │
└──────────┘
*/

-- Cleaner version using NOT EXISTS
SELECT CustomerID, FirstName, LastName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);

-- =============================================
-- Part 4: Find Unsold Products
-- =============================================

-- Products that have NEVER been ordered
SELECT ProductID, ProductName, Price
FROM Products
EXCEPT
SELECT DISTINCT p.ProductID, p.ProductName, p.Price
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID;

-- Alternative with NOT EXISTS (more readable)
SELECT ProductID, ProductName, Price
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID
);

-- =============================================
-- Part 5: EXCEPT with Multiple Columns
-- =============================================

-- ALL columns must match for a row to be excluded
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 2;

-- If ProductID, ProductName, OR Price differ, row is included

-- Example: Find products with changed prices
SELECT ProductID, ProductName, Price
FROM ProductHistory  -- Historical prices
EXCEPT
SELECT ProductID, ProductName, Price
FROM Products;  -- Current prices

-- Returns products whose price changed

-- =============================================
-- Part 6: Removing Duplicates
-- =============================================

-- EXCEPT automatically removes duplicates
SELECT CategoryID
FROM Products
EXCEPT
SELECT CategoryID
FROM Products
WHERE ProductID = 999;  -- Product doesn't exist

-- Returns: All unique CategoryIDs from Products
-- (Since no product matches 999, nothing is excluded)

-- =============================================
-- Part 7: EXCEPT with Three Sets
-- =============================================

-- Products in Category 1, excluding those in Category 2, excluding those > $500
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 2
EXCEPT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 500;

-- Operations execute left to right:
-- Step 1: Category 1 EXCEPT Category 2
-- Step 2: Result EXCEPT Price > 500

-- =============================================
-- Part 8: Finding Data Discrepancies
-- =============================================

-- Find orders in system A but not in system B (data sync check)
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM OrdersSystemA
EXCEPT
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM OrdersSystemB;

-- Find customers in CRM but not in ordering system
SELECT CustomerID, Email
FROM CRM_Customers
EXCEPT
SELECT CustomerID, Email
FROM Customers;

-- Products in catalog but not in inventory
SELECT ProductID, ProductName
FROM ProductCatalog
EXCEPT
SELECT ProductID, ProductName
FROM InventoryProducts;

-- =============================================
-- Part 9: Temporal Queries
-- =============================================

-- Customers who ordered in 2024 but NOT in 2025
SELECT DISTINCT CustomerID
FROM Orders
WHERE YEAR(OrderDate) = 2024
EXCEPT
SELECT DISTINCT CustomerID
FROM Orders
WHERE YEAR(OrderDate) = 2025;

/*
Visual:
2024 Customers:    2025 Customers:
┌────────┐         ┌────────┐
│ C001   │         │ C001   │
│ C002   │         │ C003   │
│ C003   │         └────────┘
│ C004   │
└────────┘
     ↓ EXCEPT ↓
┌────────┐
│ C002   │  ← Lost customers (2024 only)
│ C004   │
└────────┘
*/

-- Products ordered in January but NOT in February
SELECT DISTINCT ProductID
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01'
EXCEPT
SELECT DISTINCT ProductID
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01';

-- =============================================
-- Part 10: EXCEPT vs NOT IN vs NOT EXISTS
-- =============================================

-- Method 1: EXCEPT
SELECT ProductID
FROM Products
EXCEPT
SELECT DISTINCT ProductID
FROM OrderDetails;

-- Method 2: NOT IN
SELECT ProductID
FROM Products
WHERE ProductID NOT IN (SELECT ProductID FROM OrderDetails);

-- Method 3: NOT EXISTS (usually fastest)
SELECT ProductID
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID
);

-- All three return same result: Products never ordered

-- Performance: NOT EXISTS > EXCEPT > NOT IN (usually)

-- =============================================
-- Part 11: EXCEPT with NULL Handling
-- =============================================

-- NULL values are treated as equal in EXCEPT
SELECT ProductID, CategoryID
FROM Products
WHERE ProductID IN (1, 2, 3);

EXCEPT

SELECT ProductID, CategoryID
FROM Products
WHERE ProductID IN (2, 3, 4);

-- If CategoryID is NULL for product 2 in both queries,
-- product 2 will be excluded (NULLs match)

-- This is different from WHERE CategoryID = NULL (which never matches)

-- =============================================
-- Part 12: Real-World Examples
-- =============================================

-- Example 1: Find inactive customers (no orders in last 90 days)
SELECT CustomerID, FirstName, LastName, Email
FROM Customers
EXCEPT
SELECT DISTINCT c.CustomerID, c.FirstName, c.LastName, c.Email
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= DATEADD(DAY, -90, GETDATE());

-- Example 2: Products discontinued (in old catalog, not in new)
SELECT ProductID, ProductName, CategoryID
FROM ProductCatalog2024
EXCEPT
SELECT ProductID, ProductName, CategoryID
FROM ProductCatalog2025;

-- Example 3: Email addresses in mailing list but not customers
SELECT Email
FROM MailingList
WHERE Email IS NOT NULL
EXCEPT
SELECT Email
FROM Customers
WHERE Email IS NOT NULL;

-- These are prospects who haven't purchased yet

-- =============================================
-- Part 13: EXCEPT Requirements
-- =============================================

-- ✅ CORRECT: Same number of columns
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 2;

-- ❌ ERROR: Different number of columns
/*
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 2;
-- ERROR: Column count mismatch
*/

-- ✅ CORRECT: Compatible data types
SELECT ProductID, ProductName
FROM Products
EXCEPT
SELECT CategoryID, CategoryName
FROM Categories;

-- =============================================
-- Part 14: Combining with ORDER BY
-- =============================================

-- ORDER BY at the end only
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 1
EXCEPT
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > 500
ORDER BY Price DESC;

-- Cannot have ORDER BY in individual queries before EXCEPT

-- =============================================
-- Summary
-- =============================================
/*
EXCEPT OPERATOR:

Concept:
┌────────────────────────────────────────┐
│  Set A - Set B = Elements in A only    │
│                                         │
│      A             B                    │
│    ╭───╮        ╭───╮                  │
│    │███│        │   │                  │
│    │███│        │   │                  │
│    ╰───╯        ╰───╯                  │
│   Only A                                │
└────────────────────────────────────────┘

Characteristics:
├─ Returns rows in first query NOT in second
├─ Order matters: A EXCEPT B ≠ B EXCEPT A
├─ Automatically removes duplicates
├─ Requires same column count
├─ Requires compatible data types
└─ NULL = NULL (treated as equal)

Use EXCEPT When:
├─ Finding missing records
├─ Identifying orphaned data
├─ Data validation/discrepancy checking
├─ Finding inactive/lost customers
└─ Comparing system data

Alternatives:
├─ NOT EXISTS (usually faster)
├─ NOT IN (watch for NULLs!)
└─ LEFT JOIN with IS NULL

Common Patterns:
├─ All Customers EXCEPT Customers with Orders = Never ordered
├─ All Products EXCEPT Ordered Products = Never sold
├─ 2024 Customers EXCEPT 2025 Customers = Lost customers
└─ Old Catalog EXCEPT New Catalog = Discontinued items

Performance:
├─ NOT EXISTS: Usually fastest
├─ EXCEPT: Good readability
├─ NOT IN: Watch for NULL issues
└─ LEFT JOIN IS NULL: Sometimes fastest

NEXT: Lesson 07 - Set Operation Rules
*/

-- =============================================
-- Practice Exercises
-- =============================================
/*
1. Find all products that have never been ordered
2. Find customers who ordered in January but not in February
3. Find products in CategoryID 1 but not in CategoryID 2
4. Compare A EXCEPT B vs B EXCEPT A with real data
5. Find emails in MailingList not in Customers table

Try these exercises before continuing!
*/
