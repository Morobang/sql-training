-- =============================================
-- Lesson 07: Set Operation Rules
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Understanding rules and requirements for set operations
-- Estimated Time: 20 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: Rule #1 - Column Count Must Match
-- =============================================

-- ✅ CORRECT: Both queries have 2 columns
SELECT ProductID, ProductName
FROM Products
UNION
SELECT CategoryID, CategoryName
FROM Categories;

-- ❌ ERROR: First has 3 columns, second has 2
/*
SELECT ProductID, ProductName, Price
FROM Products
UNION
SELECT CategoryID, CategoryName
FROM Categories;
-- ERROR: The queries must have the same number of result columns
*/

-- Fix: Add placeholder column
SELECT ProductID, ProductName, Price
FROM Products
UNION
SELECT CategoryID, CategoryName, NULL AS Price
FROM Categories;

-- =============================================
-- Part 2: Rule #2 - Data Types Must Be Compatible
-- =============================================

-- ✅ CORRECT: INT and INT
SELECT ProductID FROM Products
UNION
SELECT CategoryID FROM Categories;

-- ✅ CORRECT: VARCHAR and VARCHAR
SELECT ProductName FROM Products
UNION
SELECT CategoryName FROM Categories;

-- ✅ CORRECT: Compatible types (INT converts to VARCHAR)
SELECT CAST(ProductID AS VARCHAR(50)) FROM Products
UNION
SELECT ProductName FROM Products;

-- ❌ POTENTIAL ERROR: Incompatible types
/*
SELECT ProductID FROM Products  -- INT
UNION
SELECT ProductName FROM Products;  -- VARCHAR
-- May cause conversion error or unexpected results
*/

-- =============================================
-- Part 3: Column Order Matters
-- =============================================

-- These are DIFFERENT queries
SELECT ProductName, Price FROM Products
UNION
SELECT ProductName, Price FROM Products;
-- Result columns: ProductName, Price

SELECT Price, ProductName FROM Products
UNION
SELECT Price, ProductName FROM Products;
-- Result columns: Price, ProductName (different order!)

-- Column alignment must match
SELECT ProductID, ProductName FROM Products
UNION
SELECT CategoryName, CategoryID FROM Categories;
-- WARNING: ProductID matched with CategoryName (wrong!)

-- =============================================
-- Part 4: Column Names Come From First Query
-- =============================================

-- Column names taken from first SELECT
SELECT 
    ProductID AS ID,
    ProductName AS Name
FROM Products
UNION
SELECT 
    CategoryID AS CategoryIdentifier,  -- Name ignored!
    CategoryName AS CategoryTitle      -- Name ignored!
FROM Categories;

-- Result columns are named: ID, Name (from first query)

-- ORDER BY uses first query's names
SELECT ProductID AS ID, ProductName AS Name
FROM Products
UNION
SELECT CategoryID, CategoryName
FROM Categories
ORDER BY Name;  -- Uses 'Name' from first query

-- =============================================
-- Part 5: NULL Handling
-- =============================================

-- NULLs are treated as equal in set operations
DECLARE @Set1 TABLE (Val INT);
DECLARE @Set2 TABLE (Val INT);

INSERT INTO @Set1 VALUES (1), (NULL), (3);
INSERT INTO @Set2 VALUES (NULL), (3), (4);

-- UNION: NULL appears once
SELECT Val FROM @Set1
UNION
SELECT Val FROM @Set2;
-- Result: 1, NULL, 3, 4 (NULL from both sets treated as same)

-- INTERSECT: NULL in both = match
SELECT Val FROM @Set1
INTERSECT
SELECT Val FROM @Set2;
-- Result: NULL, 3

-- EXCEPT: NULL in both = excluded
SELECT Val FROM @Set1
EXCEPT
SELECT Val FROM @Set2;
-- Result: 1

-- =============================================
-- Part 6: Padding Columns to Match
-- =============================================

-- Add NULL columns to match count
SELECT 
    ProductID,
    ProductName,
    Price,
    NULL AS ExtraColumn
FROM Products
UNION
SELECT 
    OrderID,
    CAST(OrderDate AS VARCHAR(50)),
    TotalAmount,
    CAST(CustomerID AS VARCHAR(50))
FROM Orders;

-- Add literal values
SELECT 
    CustomerID AS ID,
    FirstName AS Name,
    'Customer' AS Type,
    Email AS Contact
FROM Customers
UNION ALL
SELECT 
    ProductID,
    ProductName,
    'Product' AS Type,
    NULL
FROM Products;

-- =============================================
-- Part 7: Data Type Compatibility Matrix
-- =============================================

/*
Compatible Type Combinations:

INT + INT               → INT         ✅
BIGINT + INT            → BIGINT      ✅
INT + VARCHAR           → VARCHAR     ✅ (with conversion)
VARCHAR(50) + VARCHAR(100) → VARCHAR(100)  ✅
DATE + DATETIME         → DATETIME    ✅
DECIMAL(5,2) + DECIMAL(10,4) → DECIMAL(10,4) ✅

Incompatible:
VARCHAR + BINARY        → ERROR       ❌
UNIQUEIDENTIFIER + INT  → ERROR       ❌
XML + VARCHAR           → ERROR       ❌
*/

-- Example: Mixing numeric types
SELECT ProductID FROM Products  -- INT
UNION
SELECT OrderID FROM Orders;     -- INT
-- Result type: INT

-- Example: Mixing varchar lengths
SELECT ProductName FROM Products  -- VARCHAR(100)
UNION
SELECT Email FROM Customers;      -- VARCHAR(255)
-- Result type: VARCHAR(255)

-- =============================================
-- Part 8: DISTINCT Behavior
-- =============================================

-- All set operators except UNION ALL remove duplicates

-- UNION removes duplicates
SELECT CategoryID FROM Products  -- May have 1,1,1,2,2,3
UNION
SELECT CategoryID FROM Products
-- Result: 1,2,3 (unique only)

-- Explicit DISTINCT not needed (redundant)
SELECT DISTINCT CategoryID FROM Products
UNION
SELECT DISTINCT CategoryID FROM Products;
-- DISTINCT is redundant (UNION already does it)

-- UNION ALL is only operator that keeps duplicates
SELECT CategoryID FROM Products
UNION ALL
SELECT CategoryID FROM Products;
-- Duplicates kept

-- =============================================
-- Part 9: ORDER BY Placement Rules
-- =============================================

-- ❌ WRONG: ORDER BY in individual queries
/*
SELECT ProductName FROM Products WHERE CategoryID = 1 ORDER BY ProductName
UNION
SELECT ProductName FROM Products WHERE CategoryID = 2 ORDER BY ProductName;
-- ERROR: ORDER BY not allowed before set operator
*/

-- ✅ CORRECT: ORDER BY after all set operations
SELECT ProductName FROM Products WHERE CategoryID = 1
UNION
SELECT ProductName FROM Products WHERE CategoryID = 2
ORDER BY ProductName;

-- ORDER BY with column position
SELECT ProductID AS ID, ProductName AS Name, Price
FROM Products
UNION
SELECT CategoryID, CategoryName, NULL
FROM Categories
ORDER BY 2;  -- Sort by second column (Name)

-- ORDER BY with expression (use column from first query)
SELECT ProductName, Price
FROM Products
UNION
SELECT CategoryName, NULL
FROM Categories
ORDER BY ProductName DESC;

-- =============================================
-- Part 10: Mixing Set Operators
-- =============================================

-- Multiple set operations in one query
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID FROM Products WHERE CategoryID = 2
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;

-- Execution order: LEFT TO RIGHT (unless parentheses used)
-- Step 1: UNION of CategoryID 1 and 2
-- Step 2: INTERSECT result with Price > 100

-- Use parentheses for clarity
(
    SELECT ProductID FROM Products WHERE CategoryID = 1
    UNION
    SELECT ProductID FROM Products WHERE CategoryID = 2
)
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;

-- =============================================
-- Part 11: Common Errors and Fixes
-- =============================================

-- Error 1: Column count mismatch
-- ❌ Wrong
/*
SELECT ProductID, ProductName FROM Products
UNION
SELECT CategoryID FROM Categories;
*/
-- ✅ Fix
SELECT ProductID, ProductName FROM Products
UNION
SELECT CategoryID, CategoryName FROM Categories;

-- Error 2: Type mismatch
-- ❌ Wrong (may fail)
/*
SELECT ProductID FROM Products  -- INT
UNION
SELECT Email FROM Customers;    -- VARCHAR
*/
-- ✅ Fix
SELECT CAST(ProductID AS VARCHAR(100)) FROM Products
UNION
SELECT Email FROM Customers;

-- Error 3: ORDER BY in wrong place
-- ❌ Wrong
/*
SELECT ProductName FROM Products ORDER BY ProductName
UNION
SELECT CategoryName FROM Categories;
*/
-- ✅ Fix
SELECT ProductName FROM Products
UNION
SELECT CategoryName FROM Categories
ORDER BY ProductName;

-- =============================================
-- Part 12: Best Practices
-- =============================================

-- Practice 1: Use meaningful column aliases
SELECT 
    ProductID AS ID,
    ProductName AS Name,
    'Product' AS Type
FROM Products
UNION
SELECT 
    CategoryID,
    CategoryName,
    'Category'
FROM Categories
ORDER BY Type, Name;

-- Practice 2: Make types explicit
SELECT 
    CAST(ProductID AS VARCHAR(50)) AS Identifier,
    ProductName AS DisplayName
FROM Products
UNION
SELECT 
    CAST(CategoryID AS VARCHAR(50)),
    CategoryName
FROM Categories;

-- Practice 3: Use parentheses for complex queries
(
    SELECT CustomerID FROM Customers WHERE City = 'New York'
    UNION
    SELECT CustomerID FROM Customers WHERE City = 'Los Angeles'
)
EXCEPT
(
    SELECT CustomerID FROM Orders WHERE OrderDate < '2024-01-01'
);

-- Practice 4: Filter before set operations (performance)
SELECT ProductID, ProductName 
FROM Products 
WHERE Price > 50  -- Filter early
UNION
SELECT CategoryID, CategoryName 
FROM Categories 
WHERE CategoryID IN (1,2);  -- Filter early

-- =============================================
-- Summary
-- =============================================
/*
SET OPERATION RULES:

REQUIRED:
1. Column Count
   └─ Must be identical in all queries

2. Data Type Compatibility
   ├─ Column-by-column must be compatible
   ├─ Result type = most general type
   └─ Use CAST for explicit conversion

3. Column Order
   └─ Must match across all queries

OPTIONAL:
• Column names (taken from first query)
• Table names (can be different)
• WHERE clauses (can differ)

DUPLICATE HANDLING:
├─ UNION: Removes duplicates
├─ UNION ALL: Keeps duplicates
├─ INTERSECT: Removes duplicates
└─ EXCEPT: Removes duplicates

NULL BEHAVIOR:
├─ NULL = NULL (treated as equal)
├─ Unlike WHERE clause (NULL <> NULL)
└─ Appears once in UNION

ORDER BY:
├─ Only at END of query
├─ Cannot appear before set operator
├─ Use column names from first query
└─ Can use column position (ORDER BY 1, 2)

BEST PRACTICES:
✅ Use clear column aliases
✅ Make data types explicit (CAST)
✅ Filter early (before set operation)
✅ Use parentheses for complex queries
✅ Comment for clarity

NEXT: Lesson 08 - Sorting Compound Results
*/

-- =============================================
-- Practice Exercises
-- =============================================
/*
1. Fix this query:
   SELECT ProductID, ProductName, Price FROM Products
   UNION
   SELECT CategoryID, CategoryName FROM Categories;

2. Combine Products and Categories with proper type casting

3. Create a query with proper column names from first SELECT

4. Use ORDER BY correctly with set operations

5. Mix UNION, INTERSECT, and EXCEPT with parentheses

Try these exercises!
*/
