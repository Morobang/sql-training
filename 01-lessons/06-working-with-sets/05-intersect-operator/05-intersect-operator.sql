-- =============================================
-- Lesson 05: INTERSECT Operator
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Finding common records between two queries using INTERSECT
-- Estimated Time: 20 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: What is INTERSECT?
-- =============================================
-- INTERSECT returns only rows that appear in BOTH queries
-- Automatically removes duplicates

-- Basic INTERSECT example
-- Find products that are in CategoryID 1 AND have Price > 50
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 50;

/*
Visual:
Set A (CategoryID 1):      Set B (Price > 50):
┌──────────┐              ┌──────────┐
│ Laptop   │              │ Laptop   │
│ Mouse    │              │ Monitor  │
│ Keyboard │              └──────────┘
└──────────┘
        ↓ INTERSECT ↓
┌──────────┐
│ Laptop   │  ← Only in BOTH sets
└──────────┘
*/

-- =============================================
-- Part 2: INTERSECT vs AND
-- =============================================

-- Same result using AND
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1 AND Price > 50;

-- Using INTERSECT
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 50;

-- For simple conditions, AND is easier
-- INTERSECT is useful when queries involve different tables

-- =============================================
-- Part 3: INTERSECT with Different Tables
-- =============================================

-- Find customers who have placed orders in BOTH 2024 AND 2025
SELECT DISTINCT CustomerID
FROM Orders
WHERE YEAR(OrderDate) = 2024
INTERSECT
SELECT DISTINCT CustomerID
FROM Orders
WHERE YEAR(OrderDate) = 2025;

/*
Visual:
2024 Customers:    2025 Customers:
┌────────┐         ┌────────┐
│ C001   │         │ C001   │
│ C002   │         │ C003   │
│ C003   │         │ C004   │
└────────┘         └────────┘
     ↓ INTERSECT ↓
┌────────┐
│ C001   │  ← Ordered in both years
│ C003   │
└────────┘
*/

-- =============================================
-- Part 4: Find Common Elements
-- =============================================

-- Products that exist in both OrderDetails (been ordered)
-- AND Inventory (in stock)
SELECT ProductID
FROM OrderDetails
INTERSECT
SELECT ProductID
FROM Products;  -- All products in inventory

-- Customers who are ALSO suppliers (if such a relationship exists)
SELECT Email
FROM Customers
WHERE Email IS NOT NULL
INTERSECT
SELECT Email
FROM Suppliers
WHERE Email IS NOT NULL;

-- =============================================
-- Part 5: INTERSECT with Multiple Columns
-- =============================================

-- Find exact matches across all columns
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > 100;

-- Note: ALL columns must match for a row to be in result
-- ProductID AND ProductName AND Price must all match

-- Example with customer data
SELECT FirstName, LastName, Email
FROM Customers
WHERE FirstName LIKE 'J%'
INTERSECT
SELECT FirstName, LastName, Email
FROM Customers
WHERE Email LIKE '%@gmail.com';

-- Only customers whose name starts with 'J' AND have gmail email

-- =============================================
-- Part 6: Removing Duplicates
-- =============================================

-- INTERSECT automatically removes duplicates
SELECT CategoryID
FROM Products
INTERSECT
SELECT CategoryID
FROM Products;
-- Returns each CategoryID once, even if it appears multiple times

-- Equivalent to:
SELECT DISTINCT CategoryID
FROM Products;

-- =============================================
-- Part 7: INTERSECT with Three Sets
-- =============================================

-- Find customers who ordered in ALL three quarters
SELECT DISTINCT CustomerID
FROM Orders
WHERE MONTH(OrderDate) IN (1,2,3)  -- Q1
INTERSECT
SELECT DISTINCT CustomerID
FROM Orders
WHERE MONTH(OrderDate) IN (4,5,6)  -- Q2
INTERSECT
SELECT DISTINCT CustomerID
FROM Orders
WHERE MONTH(OrderDate) IN (7,8,9);  -- Q3

/*
Visual:
   Q1           Q2           Q3
┌──────┐    ┌──────┐    ┌──────┐
│ C001 │    │ C001 │    │ C001 │
│ C002 │    │ C001 │    │ C003 │
│ C003 │    │ C003 │    └──────┘
└──────┘    └──────┘
          ↓ INTERSECT ↓
          ┌──────┐
          │ C001 │  ← Ordered in all three quarters
          │ C003 │
          └──────┘
*/

-- =============================================
-- Part 8: INTERSECT with Subqueries
-- =============================================

-- Find products ordered by Customer 1 AND Customer 2
SELECT DISTINCT ProductID
FROM OrderDetails od
INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.CustomerID = 1
INTERSECT
SELECT DISTINCT ProductID
FROM OrderDetails od
INNER JOIN Orders o ON od.OrderID = o.OrderID
WHERE o.CustomerID = 2;

-- Products in same price range in two different categories
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 1 AND Price BETWEEN 50 AND 200
INTERSECT
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 2 AND Price BETWEEN 50 AND 200;

-- =============================================
-- Part 9: Real-World Use Cases
-- =============================================

-- Example 1: Find loyal customers (ordered every month for 3 months)
SELECT DISTINCT CustomerID
FROM Orders
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01'
INTERSECT
SELECT DISTINCT CustomerID
FROM Orders
WHERE OrderDate >= '2025-02-01' AND OrderDate < '2025-03-01'
INTERSECT
SELECT DISTINCT CustomerID
FROM Orders
WHERE OrderDate >= '2025-03-01' AND OrderDate < '2025-04-01';

-- Example 2: Products that meet multiple criteria
-- (High-rated AND best-selling AND in-stock)
SELECT ProductID
FROM ProductReviews
WHERE Rating >= 4.5
GROUP BY ProductID
HAVING COUNT(*) >= 10
INTERSECT
SELECT ProductID
FROM OrderDetails
GROUP BY ProductID
HAVING SUM(Quantity) > 100
INTERSECT
SELECT ProductID
FROM Products
WHERE StockQuantity > 0;

-- Example 3: Customers in overlapping segments
SELECT CustomerID
FROM Customers
WHERE City = 'New York'
INTERSECT
SELECT CustomerID
FROM Orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 1000;

-- New York customers who spent > $1000

-- =============================================
-- Part 10: INTERSECT vs INNER JOIN
-- =============================================

-- INTERSECT approach
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 100;

-- INNER JOIN approach (more complex for this case)
SELECT DISTINCT p1.ProductID, p1.ProductName
FROM Products p1
INNER JOIN Products p2 
    ON p1.ProductID = p2.ProductID 
    AND p1.ProductName = p2.ProductName
WHERE p1.CategoryID = 1 
  AND p2.Price > 100;

-- INTERSECT is cleaner for "matching in both" scenarios

-- =============================================
-- Part 11: INTERSECT with NULL Handling
-- =============================================

-- NULL values are treated as equal in INTERSECT
SELECT ProductID, CategoryID
FROM Products
WHERE ProductID IN (1, 2, 3)
INTERSECT
SELECT ProductID, CategoryID
FROM Products
WHERE ProductID IN (2, 3, 4);

-- If CategoryID is NULL for product 2 in both queries,
-- it will still match (unlike WHERE col = NULL)

-- =============================================
-- Part 12: Performance Considerations
-- =============================================

-- INTERSECT performance
SET STATISTICS TIME ON;

-- INTERSECT version
SELECT ProductID
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID
FROM Products
WHERE Price > 50;

-- AND version (usually faster for same table)
SELECT ProductID
FROM Products
WHERE CategoryID = 1 AND Price > 50;

SET STATISTICS TIME OFF;

-- For single table: Use AND (faster)
-- For multiple tables or complex logic: Use INTERSECT (clearer)

-- =============================================
-- Part 13: INTERSECT Requirements
-- =============================================

-- ✅ CORRECT: Same number of columns
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 50;

-- ❌ ERROR: Different number of columns
/*
SELECT ProductID, ProductName, Price
FROM Products
WHERE CategoryID = 1
INTERSECT
SELECT ProductID, ProductName
FROM Products
WHERE Price > 50;
-- ERROR: First query has 3 columns, second has 2
*/

-- ✅ CORRECT: Compatible data types
SELECT ProductID, ProductName
FROM Products
INTERSECT
SELECT CategoryID, CategoryName
FROM Categories;

-- =============================================
-- Summary
-- =============================================
/*
INTERSECT OPERATOR:

Concept:
┌────────────────────────────────────────┐
│  Set A ∩ Set B = Common elements       │
│                                         │
│      A             B                    │
│    ╭───╮        ╭───╮                  │
│    │   │  ████  │   │                  │
│    │   │  ████  │   │                  │
│    ╰───╯  ████  ╰───╯                  │
│          Overlap                        │
└────────────────────────────────────────┘

Characteristics:
├─ Returns only rows in BOTH queries
├─ Automatically removes duplicates
├─ Requires same column count
├─ Requires compatible data types
└─ NULL = NULL (treated as equal)

Use INTERSECT When:
├─ Finding common customers/products
├─ Identifying overlaps between sets
├─ Matching records across time periods
└─ Finding items meeting multiple criteria

Alternatives:
├─ AND clause (for simple, same-table queries)
├─ INNER JOIN (for table relationships)
└─ EXISTS subquery (for checking existence)

Performance:
├─ Good for different tables/complex logic
├─ AND is faster for single table
└─ Automatically distinct (no duplicates)

NEXT: Lesson 06 - EXCEPT Operator
*/

-- =============================================
-- Practice Exercises
-- =============================================
/*
1. Find customers who ordered in both January AND February 2025
2. Find products in both CategoryID 1 AND CategoryID 2 
   (hint: this should return empty set unless product has multiple categories)
3. Find customers with orders > $100 AND who have ordered products from CategoryID 1
4. Find the intersection of three sets: cheap products (< $50), 
   electronics (CategoryID 1), and items that have been ordered
5. Compare INTERSECT performance vs AND for a single-table query

Try these before moving on!
*/
