-- =============================================
-- Lesson 08: Sorting Compound Results
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Using ORDER BY with set operations effectively
-- Estimated Time: 15 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: Basic ORDER BY with Set Operations
-- =============================================

-- ORDER BY must come AFTER all set operations
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 1
UNION
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 2
ORDER BY Price DESC;

-- ❌ WRONG: ORDER BY before set operator
/*
SELECT ProductName, Price FROM Products ORDER BY Price
UNION
SELECT ProductName, Price FROM Products;
-- ERROR!
*/

-- =============================================
-- Part 2: Column Names in ORDER BY
-- =============================================

-- Use column names from FIRST query
SELECT 
    ProductID AS ID,
    ProductName AS Name,
    Price AS Cost
FROM Products
UNION
SELECT 
    CategoryID,
    CategoryName,
    NULL
FROM Categories
ORDER BY Name, Cost;  -- Use names from first SELECT

-- Second query's column names are IGNORED
SELECT 
    ProductID AS ProductIdentifier,
    ProductName AS ProductTitle
FROM Products
UNION
SELECT 
    CategoryID AS ID,  -- Ignored!
    CategoryName AS Title  -- Ignored!
FROM Categories
ORDER BY ProductIdentifier, ProductTitle;  -- These work (from first query)

-- =============================================
-- Part 3: ORDER BY with Column Position
-- =============================================

-- Use column position numbers (1-based)
SELECT ProductID, ProductName, Price
FROM Products
UNION
SELECT CategoryID, CategoryName, NULL
FROM Categories
ORDER BY 2;  -- Sort by 2nd column (Name)

-- Multiple columns by position
SELECT ProductID, ProductName, Price
FROM Products
UNION
SELECT CategoryID, CategoryName, NULL
FROM Categories
ORDER BY 3 DESC, 2 ASC;  -- Price desc, then Name asc

-- Mix of names and positions
SELECT ProductID AS ID, ProductName AS Name, Price
FROM Products
UNION
SELECT CategoryID, CategoryName, NULL
FROM Categories
ORDER BY 3 DESC, Name ASC;  -- Position 3, then column name

-- =============================================
-- Part 4: Sorting with Type Indicators
-- =============================================

-- Add type column for better sorting
SELECT 
    ProductID AS ID,
    ProductName AS Name,
    Price,
    'Product' AS Type
FROM Products
UNION
SELECT 
    CategoryID,
    CategoryName,
    NULL,
    'Category'
FROM Categories
ORDER BY Type, Name;  -- Group by type, then alphabetical

-- Sort type first, then by value
SELECT 
    CustomerID AS ID,
    FirstName + ' ' + LastName AS Name,
    'Customer' AS RecordType,
    Email AS Contact
FROM Customers
UNION ALL
SELECT 
    ProductID,
    ProductName,
    'Product',
    NULL
FROM Products
ORDER BY RecordType, Name;

-- =============================================
-- Part 5: Sorting NULL Values
-- =============================================

-- NULLs sort to beginning (or end depending on RDBMS)
SELECT ProductName, Price
FROM Products
UNION
SELECT CategoryName, NULL AS Price
FROM Categories
ORDER BY Price DESC;

-- Use ISNULL/COALESCE to control NULL sorting
SELECT ProductName, ISNULL(Price, 0) AS Price
FROM Products
UNION
SELECT CategoryName, 0
FROM Categories
ORDER BY Price DESC;

-- Sort with NULLs last
SELECT ProductName, Price
FROM Products
UNION
SELECT CategoryName, NULL
FROM Categories
ORDER BY 
    CASE WHEN Price IS NULL THEN 1 ELSE 0 END,  -- NULLs last
    Price DESC;

-- =============================================
-- Part 6: Complex Sorting Logic
-- =============================================

-- Sort with CASE expression
SELECT 
    ProductID AS ID,
    ProductName AS Name,
    Price,
    'Product' AS Type
FROM Products
UNION
SELECT 
    CustomerID,
    FirstName + ' ' + LastName,
    NULL,
    'Customer'
FROM Customers
ORDER BY 
    CASE Type 
        WHEN 'Customer' THEN 1 
        WHEN 'Product' THEN 2 
        ELSE 3 
    END,
    Name;

-- Sort by calculated value
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 1
UNION ALL
SELECT ProductName, Price
FROM Products
WHERE CategoryID = 2
ORDER BY Price * 1.1 DESC;  -- Sort by price + 10% markup

-- =============================================
-- Part 7: Sorting Multiple Set Operations
-- =============================================

-- ORDER BY applies to entire result
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID, ProductName FROM Products WHERE CategoryID = 2
INTERSECT
SELECT ProductID, ProductName FROM Products WHERE Price > 50
ORDER BY ProductName;

-- Use parentheses for clarity
(
    SELECT ProductID, ProductName FROM Products WHERE CategoryID = 1
    UNION
    SELECT ProductID, ProductName FROM Products WHERE CategoryID = 2
)
INTERSECT
SELECT ProductID, ProductName FROM Products WHERE Price > 50
ORDER BY ProductName;

-- =============================================
-- Part 8: Sorting with Derived Columns
-- =============================================

-- Cannot sort by column not in SELECT
/*
SELECT ProductName, Price
FROM Products
UNION
SELECT CategoryName, NULL
FROM Categories
ORDER BY CategoryID;  -- ERROR: CategoryID not in SELECT
*/

-- Fix: Add column to SELECT
SELECT ProductName, Price, CategoryID
FROM Products
UNION
SELECT CategoryName, NULL, CategoryID
FROM Categories
ORDER BY CategoryID, ProductName;

-- Or use subquery
SELECT Name, Price
FROM (
    SELECT ProductName AS Name, Price, CategoryID FROM Products
    UNION
    SELECT CategoryName, NULL, CategoryID FROM Categories
) AS Combined
ORDER BY CategoryID, Name;

-- =============================================
-- Part 9: TOP with Set Operations
-- =============================================

-- TOP applies to final result AFTER set operation
SELECT TOP 5 ProductName, Price
FROM Products
UNION
SELECT CategoryName, NULL
FROM Categories
ORDER BY Price DESC;

-- TOP with UNION ALL
SELECT TOP 10 
    CustomerID AS ID,
    FirstName + ' ' + LastName AS Name,
    'Customer' AS Type
FROM Customers
UNION ALL
SELECT ProductID, ProductName, 'Product'
FROM Products
ORDER BY Name;

-- TOP with each query (use subquery)
SELECT * FROM (
    SELECT TOP 5 ProductName, Price FROM Products ORDER BY Price DESC
) AS TopProducts
UNION ALL
SELECT * FROM (
    SELECT TOP 5 ProductName, Price FROM Products ORDER BY Price ASC
) AS BottomProducts
ORDER BY Price DESC;

-- =============================================
-- Part 10: Sorting Performance Tips
-- =============================================

-- Tip 1: Filter before sorting (smaller dataset)
SELECT ProductName, Price
FROM Products
WHERE Price > 10  -- Filter early
UNION
SELECT CategoryName, NULL
FROM Categories
WHERE CategoryID IN (1,2)  -- Filter early
ORDER BY Price DESC;

-- Tip 2: Use column position for complex expressions
SELECT 
    ProductName,
    Price,
    Price * 0.9 AS DiscountPrice
FROM Products
UNION ALL
SELECT 
    CategoryName,
    NULL,
    NULL
FROM Categories
ORDER BY 3 DESC;  -- Easier than repeating Price * 0.9

-- Tip 3: Add indexes on sort columns
-- CREATE INDEX IX_Products_Price ON Products(Price);
SELECT ProductName, Price
FROM Products
UNION
SELECT CategoryName, NULL
FROM Categories
ORDER BY Price DESC;  -- Benefits from index

-- =============================================
-- Part 11: Real-World Sorting Examples
-- =============================================

-- Example 1: Combined contact list sorted by type then name
SELECT 
    FirstName + ' ' + LastName AS ContactName,
    Email,
    'Customer' AS ContactType,
    1 AS SortOrder
FROM Customers
WHERE Email IS NOT NULL
UNION
SELECT 
    ContactName,
    Email,
    'Supplier',
    2
FROM Suppliers
WHERE Email IS NOT NULL
ORDER BY SortOrder, ContactName;

-- Example 2: Revenue report sorted by period
SELECT 
    'January 2025' AS Period,
    SUM(TotalAmount) AS Revenue,
    1 AS SortOrder
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01'
UNION ALL
SELECT 
    'February 2025',
    SUM(TotalAmount),
    2
FROM Orders
WHERE OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01'
UNION ALL
SELECT 
    'March 2025',
    SUM(TotalAmount),
    3
FROM Orders
WHERE OrderDate >= '2025-03-01' AND OrderDate < '2025-04-01'
ORDER BY SortOrder;

-- Example 3: Product catalog with categories sorted
SELECT 
    c.CategoryName AS GroupName,
    p.ProductName AS ItemName,
    p.Price,
    1 AS ItemType
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
UNION ALL
SELECT 
    'Uncategorized' AS GroupName,
    ProductName,
    Price,
    2
FROM Products
WHERE CategoryID IS NULL
ORDER BY ItemType, GroupName, Price DESC;

-- =============================================
-- Summary
-- =============================================
/*
SORTING WITH SET OPERATIONS:

Rules:
├─ ORDER BY must come AFTER all set operations
├─ Cannot use ORDER BY in individual queries
├─ Column names from FIRST query only
└─ Applies to entire combined result

Syntax Options:
├─ Column names: ORDER BY ProductName
├─ Column positions: ORDER BY 1, 2
├─ Mix: ORDER BY 1, ProductName
└─ Expressions: ORDER BY CASE... END

Tips:
1. Use Type/SortOrder columns for control
2. Handle NULLs explicitly with CASE or ISNULL
3. Filter before set operations (performance)
4. Use column positions for complex expressions
5. Add indexes on frequently sorted columns

Common Patterns:
├─ Type indicator + Name: ORDER BY Type, Name
├─ Sort order column: ORDER BY SortOrder, Value
├─ NULL handling: ORDER BY CASE WHEN col IS NULL...
└─ TOP with ORDER BY: SELECT TOP N ... ORDER BY ...

Performance:
✅ Filter early (smaller dataset to sort)
✅ Use indexes on sort columns
✅ Column positions for complex expressions
❌ Avoid sorting very large UNION ALL results

NEXT: Lesson 09 - Set Operation Precedence
*/

-- =============================================
-- Practice Exercises
-- =============================================
/*
1. Combine Products and Categories, sort by name
2. Create a report sorted by type, then value
3. Use TOP 10 with UNION and proper sorting
4. Sort with NULL values last
5. Create a complex sort with CASE expression

Try these exercises!
*/
