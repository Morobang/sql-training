/*
============================================================================
Lesson 09.12 - Subquery Wrap-Up
============================================================================

Description:
Comprehensive review of all subquery concepts. Best practices, common
patterns, performance tips, and a complete reference guide for when
to use which type of subquery.

Topics Covered:
• Complete subquery taxonomy
• Best practice summary
• Performance optimization guide
• Common patterns and recipes
• Troubleshooting guide

Prerequisites:
• Lessons 09.01-09.11 (all previous subquery lessons)

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Subquery Type Quick Reference
============================================================================
*/

-- 1.1 Scalar Subquery (Single Value)
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice
FROM Products;

-- 1.2 Row Subquery (Single Row, Multiple Columns)
SELECT *
FROM Products
WHERE (CategoryID, Price) = (
    SELECT CategoryID, MAX(Price)
    FROM Products
    GROUP BY CategoryID
    HAVING CategoryID = 1
);

-- 1.3 Column Subquery (Multiple Rows, Single Column)
SELECT ProductName
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Categories
    WHERE CategoryName LIKE '%Electronics%'
);

-- 1.4 Table Subquery (Multiple Rows and Columns)
SELECT *
FROM (
    SELECT 
        CategoryID,
        AVG(Price) AS AvgPrice,
        COUNT(*) AS ProductCount
    FROM Products
    GROUP BY CategoryID
) AS CategoryStats
WHERE ProductCount > 5;

-- 1.5 Correlated Subquery
SELECT 
    p.ProductName,
    p.Price,
    (SELECT AVG(Price) FROM Products WHERE CategoryID = p.CategoryID) AS CategoryAvg
FROM Products p;

-- 1.6 Noncorrelated Subquery
SELECT ProductName
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- 1.7 Nested Subquery
SELECT CustomerName
FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Orders
    WHERE OrderID IN (
        SELECT OrderID
        FROM OrderDetails
        WHERE Quantity > 10
    )
);


/*
============================================================================
PART 2: Subquery Location Matrix
============================================================================
*/

-- Location 2.1: WHERE clause
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- Location 2.2: HAVING clause
SELECT CategoryID, AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID
HAVING AVG(Price) > (SELECT AVG(Price) FROM Products);

-- Location 2.3: SELECT clause
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS OverallAvg
FROM Products;

-- Location 2.4: FROM clause
SELECT CategoryName, AvgPrice
FROM (
    SELECT c.CategoryName, AVG(p.Price) AS AvgPrice
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    GROUP BY c.CategoryName
) AS CategoryAverages;

-- Location 2.5: INSERT statement
CREATE TABLE #ProductBackup (ProductID INT, ProductName VARCHAR(100), Price DECIMAL(10,2));
INSERT INTO #ProductBackup
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);
DROP TABLE #ProductBackup;

-- Location 2.6: UPDATE statement
UPDATE Products
SET Price = Price * 1.1
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING AVG(Price) > 75
);

-- Location 2.7: DELETE statement
-- (Using temp table for safety)
CREATE TABLE #OrdersToClean (OrderID INT);
INSERT INTO #OrdersToClean SELECT OrderID FROM Orders;

DELETE FROM #OrdersToClean
WHERE OrderID IN (
    SELECT OrderID
    FROM Orders o
    WHERE NOT EXISTS (
        SELECT 1 FROM OrderDetails WHERE OrderID = o.OrderID
    )
);
DROP TABLE #OrdersToClean;


/*
============================================================================
PART 3: Operator Usage Guide
============================================================================
*/

-- 3.1 Comparison Operators (=, <, >, <=, >=, <>)
-- Use with scalar subqueries only
SELECT ProductName FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products);

-- 3.2 IN / NOT IN
-- Use with column subqueries (list of values)
SELECT CustomerName FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM Orders WHERE TotalAmount > 1000);

-- 3.3 ANY / ALL
-- Use with column subqueries for comparisons
SELECT ProductName FROM Products
WHERE Price > ALL (SELECT Price FROM Products WHERE CategoryID = 1);

SELECT ProductName FROM Products
WHERE Price > ANY (SELECT Price FROM Products WHERE CategoryID = 1);

-- 3.4 EXISTS / NOT EXISTS
-- Best for checking existence, ignores actual values
SELECT CustomerName FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID);

SELECT CustomerName FROM Customers c
WHERE NOT EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID);


/*
============================================================================
PART 4: Common Patterns and Recipes
============================================================================
*/

-- Pattern 4.1: Top N per Group
WITH RankedProducts AS (
    SELECT 
        CategoryID,
        ProductName,
        Price,
        ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS rn
    FROM Products
)
SELECT CategoryID, ProductName, Price
FROM RankedProducts
WHERE rn <= 3;

-- Pattern 4.2: Find Duplicates
SELECT ProductName, COUNT(*) AS DuplicateCount
FROM Products
GROUP BY ProductName
HAVING COUNT(*) > 1;

-- Pattern 4.3: Find Gaps (Missing IDs)
WITH Numbers AS (
    SELECT (SELECT MIN(ProductID) FROM Products) AS n
    UNION ALL
    SELECT n + 1
    FROM Numbers
    WHERE n < (SELECT MAX(ProductID) FROM Products)
)
SELECT n AS MissingID
FROM Numbers
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = n)
OPTION (MAXRECURSION 10000);

-- Pattern 4.4: Running Total
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    (SELECT SUM(TotalAmount) 
     FROM Orders o2 
     WHERE o2.OrderDate <= o1.OrderDate) AS RunningTotal
FROM Orders o1
ORDER BY OrderDate;

-- Pattern 4.5: Median Calculation
WITH OrderedPrices AS (
    SELECT 
        Price,
        ROW_NUMBER() OVER (ORDER BY Price) AS RowNum,
        COUNT(*) OVER () AS TotalRows
    FROM Products
)
SELECT AVG(Price) AS MedianPrice
FROM OrderedPrices
WHERE RowNum IN ((TotalRows + 1) / 2, (TotalRows + 2) / 2);

-- Pattern 4.6: Exclude Outliers
WITH Stats AS (
    SELECT 
        AVG(Price) AS Mean,
        STDEV(Price) AS StdDev
    FROM Products
)
SELECT ProductID, ProductName, Price
FROM Products
CROSS JOIN Stats
WHERE Price BETWEEN Mean - (2 * StdDev) AND Mean + (2 * StdDev);

-- Pattern 4.7: Self-Join Alternative
-- Find products cheaper than at least one other product in same category
SELECT DISTINCT p1.ProductName, p1.Price
FROM Products p1
WHERE EXISTS (
    SELECT 1
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
    AND p2.Price < p1.Price
);

-- Pattern 4.8: Conditional Aggregation
SELECT 
    CategoryID,
    SUM(CASE WHEN Price > (SELECT AVG(Price) FROM Products) THEN 1 ELSE 0 END) AS AboveAvgCount,
    SUM(CASE WHEN Price <= (SELECT AVG(Price) FROM Products) THEN 1 ELSE 0 END) AS BelowAvgCount
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 5: Performance Best Practices
============================================================================
*/

-- 5.1: ✅ Use EXISTS instead of IN for large datasets
-- Faster (stops at first match):
SELECT CustomerName FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID);

-- Slower (builds entire list):
SELECT CustomerName FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM Orders);

-- 5.2: ✅ Use NOT EXISTS instead of NOT IN
-- NOT IN fails with NULL, NOT EXISTS doesn't
SELECT CustomerName FROM Customers c
WHERE NOT EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID);

-- 5.3: ✅ Cache scalar subqueries in CTE
-- Bad (calculated 3 times):
SELECT 
    ProductName,
    Price - (SELECT AVG(Price) FROM Products),
    Price / (SELECT AVG(Price) FROM Products),
    (SELECT AVG(Price) FROM Products)
FROM Products;

-- Good (calculated once):
WITH AvgPrice AS (SELECT AVG(Price) AS Avg FROM Products)
SELECT 
    ProductName,
    Price - Avg,
    Price / Avg,
    Avg
FROM Products CROSS JOIN AvgPrice;

-- 5.4: ✅ Use indexes on subquery columns
-- CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
-- CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);

-- 5.5: ✅ Consider JOIN instead of correlated subquery
-- Slow correlated:
SELECT 
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;

-- Fast JOIN:
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- 5.6: ✅ Use window functions instead of subqueries when possible
-- Slow:
SELECT 
    ProductID,
    Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.CategoryID = p1.CategoryID) AS CategoryAvg
FROM Products p1;

-- Fast:
SELECT 
    ProductID,
    Price,
    AVG(Price) OVER (PARTITION BY CategoryID) AS CategoryAvg
FROM Products;


/*
============================================================================
PART 6: Common Mistakes and Solutions
============================================================================
*/

-- Mistake 6.1: ❌ Subquery returns multiple rows with = operator
-- Error: Subquery returned more than 1 value
-- SELECT * FROM Products WHERE Price = (SELECT Price FROM Products WHERE CategoryID = 1);

-- ✅ Solutions:
-- Use IN:
SELECT * FROM Products WHERE Price IN (SELECT Price FROM Products WHERE CategoryID = 1);
-- Or ensure single value:
SELECT * FROM Products WHERE Price = (SELECT MAX(Price) FROM Products WHERE CategoryID = 1);

-- Mistake 6.2: ❌ NULL handling with IN
-- Won't return expected results if subquery contains NULL
-- SELECT * FROM Products WHERE CategoryID NOT IN (SELECT CategoryID FROM Categories);

-- ✅ Use NOT EXISTS:
SELECT * FROM Products p
WHERE NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = p.CategoryID);

-- Mistake 6.3: ❌ Correlated subquery in SELECT on large table
-- Very slow on 100K+ rows
-- SELECT CustomerID, (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) FROM Customers c;

-- ✅ Use JOIN:
SELECT c.CustomerID, COUNT(o.OrderID)
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID;

-- Mistake 6.4: ❌ Forgetting DISTINCT in subquery
-- May return duplicates
-- SELECT * FROM Products WHERE CategoryID IN (SELECT CategoryID FROM Products WHERE Price > 100);

-- ✅ Use DISTINCT or EXISTS:
SELECT * FROM Products WHERE CategoryID IN (SELECT DISTINCT CategoryID FROM Products WHERE Price > 100);
-- Or:
SELECT * FROM Products p1
WHERE EXISTS (SELECT 1 FROM Products p2 WHERE p2.CategoryID = p1.CategoryID AND p2.Price > 100);

-- Mistake 6.5: ❌ Subquery in SELECT without NULL handling
-- Can return unexpected NULLs
-- SELECT ProductID, (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID) FROM Products p;

-- ✅ Use ISNULL/COALESCE:
SELECT ProductID, ISNULL((SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID), 0)
FROM Products p;


/*
============================================================================
PART 7: Decision Tree
============================================================================
*/

/*
┌─────────────────────────────────────────────────────────────────┐
│                    SUBQUERY DECISION TREE                       │
└─────────────────────────────────────────────────────────────────┘

What do you need?

1. Single value (average, max, count, etc.)
   → Scalar subquery in WHERE/SELECT
   → (SELECT AVG(Price) FROM Products)

2. Check if exists / not exists
   → EXISTS / NOT EXISTS
   → WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)

3. Match against list of values
   → IN / NOT IN (small lists)
   → EXISTS / NOT EXISTS (large lists, better with NULL)

4. Compare to any/all values
   → ANY / ALL operators
   → WHERE Price > ALL (SELECT Price FROM Products WHERE CategoryID = 1)

5. Filter by aggregated data
   → Subquery in HAVING
   → HAVING AVG(Price) > (SELECT AVG(Price) FROM Products)

6. Create derived/temporary result set
   → FROM clause (derived table)
   → CTE (if reusing or complex)

7. Row-by-row calculated column
   → Correlated subquery in SELECT (simple)
   → Window function (better performance)
   → CROSS/OUTER APPLY (multiple values)

8. Data manipulation
   → INSERT...SELECT
   → UPDATE with subquery
   → DELETE with EXISTS/IN

9. Complex multi-step logic
   → Multiple CTEs
   → Break into manageable pieces

10. Recursive/hierarchical data
    → Recursive CTE
    → WITH RECURSIVE
*/


/*
============================================================================
PART 8: Troubleshooting Guide
============================================================================
*/

-- Issue 8.1: "Subquery returned more than 1 value"
-- Cause: Using = with multi-row subquery
-- Fix: Use IN, EXISTS, ANY, or ensure single row (MAX, MIN, TOP 1)

-- Issue 8.2: Query is very slow
-- Diagnosis: Check if correlated subquery in SELECT
-- Fix: Use JOIN, window function, or CROSS APPLY

-- Issue 8.3: NOT IN returns no rows unexpectedly
-- Cause: NULL values in subquery
-- Fix: Use NOT EXISTS or filter NULL in subquery

-- Issue 8.4: Results missing expected rows
-- Cause: Comparison with NULL
-- Fix: Handle NULL explicitly (ISNULL, IS NULL checks)

-- Issue 8.5: Infinite recursion error
-- Cause: Recursive CTE without proper termination
-- Fix: Add proper WHERE condition, set MAXRECURSION

-- Issue 8.6: Subquery returns NULL unexpectedly
-- Cause: No matching rows
-- Fix: Use ISNULL/COALESCE with default value


/*
============================================================================
PRACTICE EXERCISES - COMPREHENSIVE REVIEW
============================================================================

Choose the best approach for each scenario:

1. Find all customers who have never placed an order
2. Get products with price above their category average
3. List top 3 most expensive products per category
4. Calculate running total of order amounts by date
5. Find customers with above-average order frequency
6. Get the latest order for each customer
7. Find products that have never been ordered
8. Calculate percentage of total sales for each product
9. Find duplicate customer names
10. Get orders with more items than the average order

Solutions and explanations below ↓
*/

-- Solution 1: NOT EXISTS (best for non-existence check)
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID
);

-- Solution 2: Correlated subquery (row-specific comparison)
SELECT ProductID, ProductName, CategoryID, Price
FROM Products p
WHERE Price > (
    SELECT AVG(Price) FROM Products WHERE CategoryID = p.CategoryID
);

-- Solution 3: Window function with CTE (modern approach)
WITH RankedProducts AS (
    SELECT 
        CategoryID,
        ProductName,
        Price,
        ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS rn
    FROM Products
)
SELECT CategoryID, ProductName, Price
FROM RankedProducts
WHERE rn <= 3;

-- Solution 4: Window function (efficient for running totals)
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER (ORDER BY OrderDate, OrderID) AS RunningTotal
FROM Orders
ORDER BY OrderDate, OrderID;

-- Solution 5: CTE with comparison
WITH CustomerOrderCounts AS (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
),
AvgOrderCount AS (
    SELECT AVG(CAST(OrderCount AS FLOAT)) AS Avg FROM CustomerOrderCounts
)
SELECT c.CustomerName, coc.OrderCount
FROM Customers c
JOIN CustomerOrderCounts coc ON c.CustomerID = coc.CustomerID
CROSS JOIN AvgOrderCount aoc
WHERE coc.OrderCount > aoc.Avg;

-- Solution 6: Correlated subquery (latest per group)
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT TOP 1 OrderID FROM Orders WHERE CustomerID = c.CustomerID ORDER BY OrderDate DESC) AS LatestOrderID,
    (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID) AS LatestOrderDate
FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID);

-- Solution 7: NOT EXISTS (non-existence check)
SELECT ProductID, ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails WHERE ProductID = p.ProductID
);

-- Solution 8: Window function (percentage calculation)
WITH ProductRevenue AS (
    SELECT 
        ProductID,
        SUM(Quantity * UnitPrice) AS Revenue
    FROM OrderDetails
    GROUP BY ProductID
)
SELECT 
    p.ProductName,
    pr.Revenue,
    pr.Revenue * 100.0 / SUM(pr.Revenue) OVER () AS PercentOfTotal
FROM Products p
JOIN ProductRevenue pr ON p.ProductID = pr.ProductID
ORDER BY PercentOfTotal DESC;

-- Solution 9: GROUP BY with HAVING (duplicate detection)
SELECT CustomerName, COUNT(*) AS DuplicateCount
FROM Customers
GROUP BY CustomerName
HAVING COUNT(*) > 1;

-- Solution 10: CTE with comparison
WITH OrderItemCounts AS (
    SELECT OrderID, COUNT(*) AS ItemCount
    FROM OrderDetails
    GROUP BY OrderID
),
AvgItemCount AS (
    SELECT AVG(CAST(ItemCount AS FLOAT)) AS Avg FROM OrderItemCounts
)
SELECT o.OrderID, o.OrderDate, oic.ItemCount
FROM Orders o
JOIN OrderItemCounts oic ON o.OrderID = oic.OrderID
CROSS JOIN AvgItemCount aic
WHERE oic.ItemCount > aic.Avg;


/*
============================================================================
KEY TAKEAWAYS - COMPLETE SUMMARY
============================================================================

✓ SUBQUERY FUNDAMENTALS:
  • Query within a query
  • Enclosed in parentheses
  • Can be scalar, row, column, or table
  • Can be correlated or noncorrelated

✓ WHERE TO USE:
  • WHERE clause - filtering
  • HAVING clause - group filtering
  • SELECT clause - calculated columns
  • FROM clause - derived tables
  • INSERT/UPDATE/DELETE - data manipulation

✓ OPERATORS:
  • = < > <= >= <> - scalar comparisons
  • IN / NOT IN - list membership
  • EXISTS / NOT EXISTS - existence checks
  • ANY / ALL - quantified comparisons

✓ PERFORMANCE HIERARCHY (Fast → Slow):
  1. JOIN with indexes
  2. Window functions
  3. EXISTS/NOT EXISTS
  4. IN with small list
  5. Correlated subquery (small outer)
  6. Correlated subquery (large outer)

✓ WHEN TO USE SUBQUERIES:
  • Scalar value lookups
  • Existence checks
  • List filtering (IN)
  • Step-by-step logic (CTEs)
  • One-off calculations

✓ WHEN NOT TO USE:
  • Need multiple columns → JOIN
  • Large datasets + correlated → JOIN/window
  • Repeated calculations → CTE
  • Complex aggregation → derived table/CTE

✓ BEST PRACTICES:
  • EXISTS over IN for large datasets
  • Handle NULL explicitly
  • Cache scalar values in CTE
  • Use window functions when possible
  • Index subquery columns
  • Test with SELECT before DELETE/UPDATE
  • Comment complex logic
  • Consider readability

✓ COMMON PATTERNS:
  • Top N per group
  • Running totals
  • Gaps and islands
  • Duplicate detection
  • Existence/non-existence
  • Above/below average
  • Latest/oldest per group

✓ ALTERNATIVES:
  • Window functions (OVER clause)
  • CTEs (WITH clause)
  • JOINs
  • CROSS/OUTER APPLY
  • Temporary tables

============================================================================
NEXT: Lesson 09.13 - Test Your Knowledge
Comprehensive assessment of all subquery concepts.
============================================================================
*/
