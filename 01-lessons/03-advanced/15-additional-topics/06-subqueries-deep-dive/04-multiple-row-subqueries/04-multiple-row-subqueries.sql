/*
============================================================================
Lesson 09.04 - Multiple-Row Subqueries
============================================================================

Description:
Master subqueries that return multiple rows and the operators that work
with them: IN, NOT IN, ANY, ALL, and SOME.

Topics Covered:
• IN and NOT IN operators
• ANY and SOME operators
• ALL operator
• Handling NULL values
• Performance optimization

Prerequisites:
• Lessons 09.01-09.03

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: IN Operator with Subqueries
============================================================================
*/

-- Example 1.1: Basic IN usage
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (1, 2, 3);  -- Hardcoded list

-- Example 1.2: IN with subquery (dynamic list)
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Categories
    WHERE Active = 1
);
-- Subquery returns: (1, 2, 3, 5, 7) - list of active category IDs

-- Example 1.3: IN is equivalent to multiple OR conditions
-- These are the same:
WHERE CategoryID IN (1, 2, 3)
WHERE CategoryID = 1 OR CategoryID = 2 OR CategoryID = 3

-- Example 1.4: Multi-level filtering
SELECT OrderID, CustomerID, TotalAmount
FROM Orders
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Customers
    WHERE Country IN ('USA', 'Canada', 'Mexico')
)
AND TotalAmount > 100;

-- Example 1.5: IN with aggregated subquery
SELECT ProductName, Price
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING AVG(Price) > 50
);
-- Products in categories with average price > 50


/*
============================================================================
PART 2: NOT IN Operator
============================================================================
*/

-- Example 2.1: Basic NOT IN
SELECT CustomerName
FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID
    FROM Orders
);
-- Customers who never placed an order

-- Example 2.2: Exclusion by criteria
SELECT ProductName
FROM Products
WHERE ProductID NOT IN (
    SELECT ProductID
    FROM OrderDetails
    WHERE Quantity > 10
);
-- Products never ordered in large quantities

-- Example 2.3: ⚠️ CRITICAL: NULL Problem with NOT IN
CREATE TABLE #Categories (CategoryID INT);
INSERT INTO #Categories VALUES (1), (2), (NULL);

-- This returns NO rows! (Even if CategoryID 3 exists)
SELECT ProductName
FROM Products
WHERE CategoryID NOT IN (SELECT CategoryID FROM #Categories);

/*
Why? NOT IN with NULL:
CategoryID NOT IN (1, 2, NULL)
Means: CategoryID <> 1 AND CategoryID <> 2 AND CategoryID <> NULL
The last comparison with NULL always returns UNKNOWN
AND with UNKNOWN returns UNKNOWN
Result: No rows!
*/

-- Example 2.4: ✅ FIX: Filter out NULL
SELECT ProductName
FROM Products
WHERE CategoryID NOT IN (
    SELECT CategoryID 
    FROM #Categories 
    WHERE CategoryID IS NOT NULL
);

DROP TABLE #Categories;

-- Example 2.5: ✅ Alternative: Use NOT EXISTS (safer)
SELECT c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
-- Same result as NOT IN, but handles NULL better


/*
============================================================================
PART 3: ANY Operator (or SOME)
============================================================================
*/

-- Syntax: column_name operator ANY (subquery)
-- Returns TRUE if comparison is true for AT LEAST ONE value

-- Example 3.1: Greater than ANY (> ANY)
SELECT ProductName, Price
FROM Products
WHERE Price > ANY (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1
);
-- Products more expensive than AT LEAST ONE product in category 1
-- Equivalent to: Price > MIN(prices in category 1)

-- Example 3.2: Less than ANY (< ANY)
SELECT ProductName, Price
FROM Products
WHERE Price < ANY (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1
);
-- Products cheaper than AT LEAST ONE product in category 1
-- Equivalent to: Price < MAX(prices in category 1)

-- Example 3.3: = ANY is same as IN
SELECT ProductName
FROM Products
WHERE CategoryID = ANY (
    SELECT CategoryID FROM Categories WHERE Active = 1
);
-- Same as: WHERE CategoryID IN (...)

-- Example 3.4: SOME is synonym for ANY
SELECT ProductName, Price
FROM Products
WHERE Price > SOME (
    SELECT Price FROM Products WHERE CategoryID = 1
);
-- SOME and ANY are interchangeable

-- Example 3.5: Practical use - find competitive prices
SELECT p1.ProductName, p1.Price, p1.CategoryID
FROM Products p1
WHERE p1.Price < ANY (
    SELECT AVG(Price)
    FROM Products
    GROUP BY CategoryID
);
-- Products cheaper than at least one category average


/*
============================================================================
PART 4: ALL Operator
============================================================================
*/

-- Syntax: column_name operator ALL (subquery)
-- Returns TRUE if comparison is true for ALL values

-- Example 4.1: Greater than ALL (> ALL)
SELECT ProductName, Price
FROM Products
WHERE Price > ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
);
-- Products more expensive than ALL products in category 1
-- Equivalent to: Price > MAX(prices in category 1)

-- Example 4.2: Less than ALL (< ALL)
SELECT ProductName, Price
FROM Products
WHERE Price < ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
);
-- Products cheaper than ALL products in category 1
-- Equivalent to: Price < MIN(prices in category 1)

-- Example 4.3: Not equal to ALL (<> ALL)
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID <> ALL (1, 2, 3);
-- Products NOT in categories 1, 2, or 3
-- Same as: NOT IN (1, 2, 3)

-- Example 4.4: Practical use - premium products
SELECT ProductName, Price
FROM Products p1
WHERE Price >= ALL (
    SELECT Price
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID AND p2.Price IS NOT NULL
);
-- Most expensive product in each category

-- Example 4.5: Finding outliers
SELECT OrderID, TotalAmount
FROM Orders
WHERE TotalAmount > ALL (
    SELECT AVG(TotalAmount)
    FROM Orders
    GROUP BY YEAR(OrderDate)
);
-- Orders larger than ALL yearly averages


/*
============================================================================
PART 5: Comparison: IN vs ANY vs ALL
============================================================================
*/

-- Comparison 5.1: Summary table
/*
Operator | Meaning                          | Equivalent
---------|----------------------------------|------------------
= ANY    | Equal to at least one           | IN
<> ALL   | Not equal to any                | NOT IN
> ANY    | Greater than minimum            | > MIN(...)
< ANY    | Less than maximum               | < MAX(...)
> ALL    | Greater than maximum            | > MAX(...)
< ALL    | Less than minimum               | < MIN(...)
*/

-- Comparison 5.2: Same query, different operators
-- Find products priced above $50:

-- Using hardcoded value:
WHERE Price > 50

-- Using IN (exact match):
WHERE Price IN (SELECT Price FROM Products WHERE Price > 50)

-- Using > ANY (greater than at least one):
WHERE Price > ANY (SELECT Price FROM Products WHERE Price > 50)
-- True if price > at least one product over $50

-- Using > ALL (greater than all):
WHERE Price > ALL (SELECT Price FROM Products WHERE Price <= 50)
-- True if price > all products $50 or less

-- Comparison 5.3: Practical demonstration
CREATE TABLE #TestPrices (Price DECIMAL(10,2));
INSERT INTO #TestPrices VALUES (10.00), (20.00), (30.00);

SELECT 
    'Greater than ANY (>10, >20, or >30)' AS Test,
    COUNT(*) AS MatchCount
FROM Products
WHERE Price > ANY (SELECT Price FROM #TestPrices)  -- > 10
UNION ALL
SELECT 
    'Greater than ALL (>10 AND >20 AND >30)',
    COUNT(*)
FROM Products
WHERE Price > ALL (SELECT Price FROM #TestPrices);  -- > 30

DROP TABLE #TestPrices;


/*
============================================================================
PART 6: Handling NULL Values
============================================================================
*/

-- Example 6.1: NULL in IN (works as expected)
SELECT ProductName
FROM Products
WHERE CategoryID IN (1, 2, NULL);
-- Matches CategoryID 1 or 2, ignores NULL

-- Example 6.2: NULL in NOT IN (PROBLEM!)
CREATE TABLE #TestNull (ID INT);
INSERT INTO #TestNull VALUES (1), (NULL);

SELECT COUNT(*) AS RowCount
FROM Products
WHERE ProductID NOT IN (SELECT ID FROM #TestNull);
-- Returns 0! NULL causes all rows to be filtered out

-- ✅ Solution 1: Filter NULL
SELECT COUNT(*) AS RowCount
FROM Products
WHERE ProductID NOT IN (
    SELECT ID FROM #TestNull WHERE ID IS NOT NULL
);

-- ✅ Solution 2: Use NOT EXISTS
SELECT COUNT(*) AS RowCount
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM #TestNull t WHERE t.ID = p.ProductID
);

DROP TABLE #TestNull;

-- Example 6.3: NULL with ANY (safer)
SELECT ProductName, Price
FROM Products
WHERE Price > ANY (SELECT Price FROM Products WHERE Price IS NOT NULL);
-- ANY ignores NULL more gracefully

-- Example 6.4: NULL with ALL (filter NULL)
SELECT ProductName, Price
FROM Products
WHERE Price > ALL (
    SELECT Price 
    FROM Products 
    WHERE CategoryID = 1 AND Price IS NOT NULL  -- Always filter NULL!
);


/*
============================================================================
PART 7: Performance Optimization
============================================================================
*/

-- Optimization 7.1: Index columns in subquery
-- CREATE INDEX IX_Products_CategoryID ON Products(CategoryID);
SELECT ProductName
FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM TopCategories);

-- Optimization 7.2: Use EXISTS instead of IN for large subqueries
-- ❌ Slower with large results:
WHERE CustomerID IN (SELECT CustomerID FROM LargeOrdersTable)

-- ✅ Faster:
WHERE EXISTS (SELECT 1 FROM LargeOrdersTable WHERE CustomerID = c.CustomerID)

-- Optimization 7.3: Limit subquery result set
-- ❌ Subquery returns all rows:
WHERE CategoryID IN (SELECT CategoryID FROM Categories)

-- ✅ Better: Filter in subquery
WHERE CategoryID IN (SELECT CategoryID FROM Categories WHERE Active = 1)

-- Optimization 7.4: Use JOIN when you need columns from both tables
-- ❌ Subquery when you need category name:
SELECT 
    ProductName,
    (SELECT CategoryName FROM Categories WHERE CategoryID = p.CategoryID)
FROM Products p;

-- ✅ JOIN is better:
SELECT p.ProductName, c.CategoryName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find products in categories with more than 5 products (use IN)
2. Find customers who never ordered (use NOT IN, handle NULL)
3. Find products more expensive than ANY product in category 1 (use ANY)
4. Find products cheaper than ALL products in category 1 (use ALL)
5. Find orders larger than any average monthly order (use > ANY)

Solutions below ↓
*/

-- Solution 1:
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING COUNT(*) > 5
);

-- Solution 2:
SELECT CustomerID, CustomerName
FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID
    FROM Orders
    WHERE CustomerID IS NOT NULL
);
-- OR safer with NOT EXISTS:
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);

-- Solution 3:
SELECT ProductName, Price, CategoryID
FROM Products
WHERE Price > ANY (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
)
ORDER BY Price;

-- Solution 4:
SELECT ProductName, Price, CategoryID
FROM Products
WHERE Price < ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
)
ORDER BY Price;

-- Solution 5:
SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE TotalAmount > ANY (
    SELECT AVG(TotalAmount)
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
ORDER BY TotalAmount DESC;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ IN OPERATOR:
  • Matches value against list
  • Equivalent to multiple OR
  • Works well with subqueries
  • Ignores NULL in list

✓ NOT IN OPERATOR:
  • Excludes values in list
  • ⚠️ DANGER: Returns no rows if NULL in subquery!
  • Always filter NULL: WHERE col IS NOT NULL
  • Consider NOT EXISTS as safer alternative

✓ ANY / SOME OPERATORS:
  • True if condition met for AT LEAST ONE value
  • = ANY is same as IN
  • > ANY means > MIN(values)
  • < ANY means < MAX(values)
  • SOME is synonym for ANY

✓ ALL OPERATOR:
  • True if condition met for ALL values
  • > ALL means > MAX(values)
  • < ALL means < MIN(values)
  • <> ALL is same as NOT IN

✓ NULL HANDLING:
  • IN: Ignores NULL (safe)
  • NOT IN: NULL causes problems (filter it!)
  • ANY: Handles NULL better
  • ALL: Filter NULL explicitly

✓ PERFORMANCE:
  • Index columns used in subqueries
  • EXISTS often faster than IN for large sets
  • Filter early in subquery
  • Consider JOIN if you need columns

✓ WHEN TO USE:
  • IN: Membership testing, small lists
  • NOT IN: Exclusion (watch for NULL!)
  • ANY: Flexible comparisons
  • ALL: Strict comparisons
  • EXISTS: Large datasets, NULL safety

============================================================================
NEXT: Lesson 09.05 - Multicolumn Subqueries
Learn to compare multiple columns simultaneously with subqueries.
============================================================================
*/
