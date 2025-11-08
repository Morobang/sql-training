/*
============================================================================
Lesson 09.01 - What is a Subquery?
============================================================================

Description:
Introduction to subqueries - queries nested inside other queries. Learn
the fundamentals, syntax, and basic usage patterns.

Topics Covered:
• Subquery definition and purpose
• Basic syntax and structure
• Execution order
• Simple examples
• When to use subqueries

Prerequisites:
• Chapters 03-04 (SELECT and WHERE basics)
• Chapter 08 (Aggregates)

Estimated Time: 20 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: What is a Subquery?
============================================================================
*/

-- Definition:
-- A SUBQUERY is a query nested inside another SQL statement.
-- Also called: Inner query, Nested query, Subselect

-- Example 1.1: Simple subquery
SELECT ProductName, Price
FROM Products
WHERE Price > (
    SELECT AVG(Price)    -- This is the SUBQUERY (inner query)
    FROM Products
);
-- Finds products priced above the average

/*
Visual Breakdown:

OUTER QUERY:
    SELECT ProductName, Price
    FROM Products
    WHERE Price > (???)
                   ↑
                   |
    INNER QUERY (SUBQUERY):
        SELECT AVG(Price)
        FROM Products
        
The subquery runs FIRST, returns a value, then the outer query uses it.
*/

-- Example 1.2: Without subquery (requires knowing the average)
-- Step 1: Find average manually
SELECT AVG(Price) AS AvgPrice FROM Products;
-- Result: 55.75 (for example)

-- Step 2: Use that value
SELECT ProductName, Price
FROM Products
WHERE Price > 55.75;  -- Hard-coded value

-- Subquery does this in ONE statement!


/*
============================================================================
PART 2: Basic Syntax
============================================================================
*/

-- Syntax 2.1: Subquery in WHERE clause (most common)
SELECT column_list
FROM table_name
WHERE column_name operator (
    SELECT column
    FROM other_table
    WHERE condition
);

-- Example 2.2: Find products in a specific category
SELECT ProductName, Price
FROM Products
WHERE CategoryID = (
    SELECT CategoryID
    FROM Categories
    WHERE CategoryName = 'Electronics'
);

-- Example 2.3: Subquery must return appropriate number of values
-- ✅ VALID: Subquery returns single value
SELECT ProductName
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products);

-- ❌ ERROR: Subquery returns multiple values
-- SELECT ProductName
-- FROM Products
-- WHERE Price = (SELECT Price FROM Products);  -- ERROR!
-- Fix: Use IN instead of =


/*
============================================================================
PART 3: Execution Order
============================================================================
*/

-- Example 3.1: Understanding execution
SELECT ProductName, Price
FROM Products
WHERE Price > (
    SELECT AVG(Price) FROM Products
);

/*
Execution Steps:
1. INNER QUERY runs first:
   SELECT AVG(Price) FROM Products
   Result: 55.75

2. OUTER QUERY uses that result:
   SELECT ProductName, Price
   FROM Products
   WHERE Price > 55.75
*/

-- Example 3.2: Visualizing with variables (conceptual)
DECLARE @AvgPrice DECIMAL(10,2);
SET @AvgPrice = (SELECT AVG(Price) FROM Products);

SELECT ProductName, Price
FROM Products
WHERE Price > @AvgPrice;
-- This is essentially what a subquery does automatically!


/*
============================================================================
PART 4: Simple Use Cases
============================================================================
*/

-- Use Case 4.1: Find maximum value items
SELECT ProductName, Price
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products);

-- Use Case 4.2: Find minimum value items
SELECT OrderID, TotalAmount
FROM Orders
WHERE TotalAmount = (SELECT MIN(TotalAmount) FROM Orders);

-- Use Case 4.3: Compare to average
SELECT 
    ProductName, 
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Products) AS Difference
FROM Products
ORDER BY Difference DESC;

-- Use Case 4.4: Count related records
SELECT 
    CustomerID,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;


/*
============================================================================
PART 5: Subquery Locations
============================================================================
*/

-- Location 5.1: WHERE clause (filtering)
SELECT ProductName
FROM Products
WHERE CategoryID = (SELECT CategoryID FROM Categories WHERE CategoryName = 'Books');

-- Location 5.2: SELECT clause (calculated column)
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice
FROM Products;

-- Location 5.3: FROM clause (derived table - covered in later lesson)
SELECT *
FROM (
    SELECT ProductName, Price, Stock
    FROM Products
    WHERE Stock > 0
) AS InStockProducts
WHERE Price < 100;

-- Location 5.4: HAVING clause (group filtering)
SELECT CategoryID, COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > (SELECT AVG(ProductCount) 
                   FROM (SELECT COUNT(*) AS ProductCount 
                         FROM Products 
                         GROUP BY CategoryID) AS Counts);


/*
============================================================================
PART 6: Why Use Subqueries?
============================================================================
*/

-- Reason 6.1: Dynamic filtering (no hard-coded values)
-- ❌ Without subquery:
SELECT ProductName FROM Products WHERE Price > 75.50;  -- What if average changes?

-- ✅ With subquery:
SELECT ProductName FROM Products WHERE Price > (SELECT AVG(Price) FROM Products);

-- Reason 6.2: Logical organization
-- Find customers who placed orders above the average order value
SELECT DISTINCT c.CustomerName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > (
    SELECT AVG(TotalAmount) FROM Orders
);

-- Reason 6.3: Avoiding multiple queries
-- Instead of:
-- Query 1: SELECT AVG(Price) FROM Products;  -- Get result: 55.75
-- Query 2: SELECT * FROM Products WHERE Price > 55.75;

-- One query:
SELECT * FROM Products WHERE Price > (SELECT AVG(Price) FROM Products);

-- Reason 6.4: Complex comparisons
-- Products more expensive than ANY product in category 1
SELECT ProductName, Price
FROM Products
WHERE Price > ANY (SELECT Price FROM Products WHERE CategoryID = 1);


/*
============================================================================
PART 7: Subquery Characteristics
============================================================================
*/

-- Characteristic 7.1: Must be enclosed in parentheses
-- ❌ ERROR:
-- SELECT * FROM Products WHERE Price > SELECT AVG(Price) FROM Products;

-- ✅ CORRECT:
SELECT * FROM Products WHERE Price > (SELECT AVG(Price) FROM Products);

-- Characteristic 7.2: Usually returns a single value (for =, >, <, etc.)
SELECT ProductName FROM Products 
WHERE Price = (SELECT MAX(Price) FROM Products);

-- Characteristic 7.3: Can return multiple values (with IN, ANY, ALL)
SELECT ProductName FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM Categories WHERE Active = 1);

-- Characteristic 7.4: Can be nested multiple levels
SELECT ProductName FROM Products
WHERE CategoryID = (
    SELECT CategoryID FROM Categories
    WHERE CategoryName = (
        SELECT TopCategory FROM Settings WHERE SettingName = 'Featured'
    )
);


/*
============================================================================
PART 8: First Glimpse at Subquery Types
============================================================================
*/

-- Type 8.1: SCALAR subquery (returns single value)
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);  -- Returns one number

-- Type 8.2: ROW subquery (returns single row, multiple columns)
SELECT ProductName
FROM Products
WHERE (Price, Stock) = (SELECT MAX(Price), MIN(Stock) FROM Products);

-- Type 8.3: TABLE subquery (returns multiple rows)
SELECT ProductName
FROM Products
WHERE CategoryID IN (  -- Subquery returns multiple CategoryIDs
    SELECT CategoryID 
    FROM Categories 
    WHERE CategoryName LIKE '%Tech%'
);

-- Type 8.4: CORRELATED subquery (references outer query - advanced)
SELECT p.ProductName, p.Price
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID  -- References outer query's CategoryID!
);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find all products cheaper than the average price
2. Find the order with the highest total amount
3. List products that cost more than the most expensive product in category 1
4. Show customers with their total order count (using subquery in SELECT)
5. Find products in categories that have more than 5 products

Solutions below ↓
*/

-- Solution 1:
SELECT ProductName, Price
FROM Products
WHERE Price < (SELECT AVG(Price) FROM Products)
ORDER BY Price DESC;

-- Solution 2:
SELECT OrderID, CustomerID, TotalAmount, OrderDate
FROM Orders
WHERE TotalAmount = (SELECT MAX(TotalAmount) FROM Orders);

-- Solution 3:
SELECT ProductName, Price, CategoryID
FROM Products
WHERE Price > (
    SELECT MAX(Price) 
    FROM Products 
    WHERE CategoryID = 1
)
ORDER BY Price;

-- Solution 4:
SELECT 
    CustomerID,
    CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c
ORDER BY OrderCount DESC;

-- Solution 5:
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING COUNT(*) > 5
)
ORDER BY CategoryID;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ DEFINITION:
  • Subquery = Query inside another query
  • Also called inner query, nested query
  • Enclosed in parentheses

✓ EXECUTION ORDER:
  • Inner query runs FIRST
  • Outer query uses the result
  • Think: "Replace subquery with its result"

✓ BASIC SYNTAX:
  SELECT ... WHERE column operator (SELECT ...)
  • Most common in WHERE clause
  • Can appear in SELECT, FROM, HAVING

✓ SIMPLE USES:
  • Compare to average (AVG)
  • Find maximum/minimum (MAX/MIN)
  • Dynamic filtering
  • Avoid hard-coded values

✓ TYPES (Preview):
  • Scalar: Returns single value
  • Row: Returns one row
  • Table: Returns multiple rows
  • Correlated: References outer query

✓ REQUIREMENTS:
  • Must be in parentheses
  • Must return appropriate number of values
  • = requires single value
  • IN allows multiple values

✓ WHY USE THEM:
  • Dynamic queries
  • Logical organization
  • One statement vs multiple
  • Complex comparisons

============================================================================
NEXT: Lesson 09.02 - Subquery Types
Deep dive into scalar, row, and table subqueries.
============================================================================
*/
