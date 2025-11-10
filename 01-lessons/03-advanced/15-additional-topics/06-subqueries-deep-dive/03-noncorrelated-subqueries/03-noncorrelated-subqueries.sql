/*
============================================================================
Lesson 09.03 - Noncorrelated Subqueries
============================================================================

Description:
Master noncorrelated (independent) subqueries that execute once and
provide results to the outer query. These are simpler and often more
efficient than correlated subqueries.

Topics Covered:
• What makes a subquery noncorrelated
• Execution flow and performance
• Common use cases
• Multiple noncorrelated subqueries
• Best practices

Prerequisites:
• Lessons 09.01-09.02

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Noncorrelated Subqueries
============================================================================
*/

-- Definition:
-- NONCORRELATED = Subquery is INDEPENDENT of outer query
-- • Runs ONCE
-- • Returns result
-- • Outer query uses that result

-- Example 1.1: Classic noncorrelated subquery
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

/*
Execution Flow:
1. Inner query runs ONCE: SELECT AVG(Price) FROM Products → 55.75
2. Result substituted: WHERE Price > 55.75
3. Outer query executes with that value
*/

-- Example 1.2: Visualizing independence
-- The subquery does NOT reference the outer query
SELECT ProductName
FROM Products
WHERE CategoryID = (
    SELECT CategoryID
    FROM Categories
    WHERE CategoryName = 'Electronics'
);
-- Subquery has NO reference to Products table (outer query)

-- Example 1.3: Compare to variable approach
DECLARE @AvgPrice DECIMAL(10,2);
SET @AvgPrice = (SELECT AVG(Price) FROM Products);

SELECT ProductName, Price
FROM Products
WHERE Price > @AvgPrice;
-- A noncorrelated subquery works like this!


/*
============================================================================
PART 2: Common Patterns
============================================================================
*/

-- Pattern 2.1: Compare to aggregate value
SELECT ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

SELECT ProductName, Stock
FROM Products
WHERE Stock < (SELECT AVG(Stock) FROM Products);

-- Pattern 2.2: Find extreme values
SELECT ProductName, Price
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products);

SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE TotalAmount = (SELECT MIN(TotalAmount) FROM Orders);

-- Pattern 2.3: Filter by list (IN operator)
SELECT ProductName
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Categories
    WHERE Active = 1
);

-- Pattern 2.4: Exclusion (NOT IN)
SELECT CustomerName
FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID
    FROM Orders
    WHERE YEAR(OrderDate) = 2024
);
-- Customers who didn't order in 2024

-- Pattern 2.5: Greater than all values
SELECT ProductName, Price
FROM Products p1
WHERE Price > ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
);
-- Products more expensive than ALL products in category 1


/*
============================================================================
PART 3: Multiple Noncorrelated Subqueries
============================================================================
*/

-- Example 3.1: Multiple subqueries in WHERE
SELECT ProductName, Price, Stock
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products)
  AND Stock < (SELECT AVG(Stock) FROM Products);
-- Expensive but low-stock items

-- Example 3.2: Subqueries in SELECT clause
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS OverallAvg,
    Price - (SELECT AVG(Price) FROM Products) AS Difference,
    (SELECT MAX(Price) FROM Products) AS MaxPrice,
    (SELECT MIN(Price) FROM Products) AS MinPrice
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- Example 3.3: Range filtering with two subqueries
SELECT ProductName, Price
FROM Products
WHERE Price BETWEEN 
    (SELECT AVG(Price) FROM Products) - (SELECT STDEV(Price) FROM Products)
    AND
    (SELECT AVG(Price) FROM Products) + (SELECT STDEV(Price) FROM Products);
-- Products within one standard deviation of average


/*
============================================================================
PART 4: Subqueries with IN Operator
============================================================================
*/

-- Example 4.1: Basic IN subquery
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Categories
    WHERE CategoryName LIKE '%Tech%'
);

-- Example 4.2: Multiple level filtering
SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Customers
    WHERE Country = 'USA'
)
AND TotalAmount > (SELECT AVG(TotalAmount) FROM Orders);

-- Example 4.3: NOT IN for exclusion
SELECT ProductName
FROM Products
WHERE ProductID NOT IN (
    SELECT DISTINCT ProductID
    FROM OrderDetails
);
-- Products never ordered

-- Example 4.4: ⚠️ WARNING: NOT IN with NULL
CREATE TABLE #TestData (ID INT);
INSERT INTO #TestData VALUES (1), (2), (NULL);

-- This returns NO rows! (NULL causes problem)
SELECT ProductID
FROM Products
WHERE ProductID NOT IN (SELECT ID FROM #TestData);

-- ✅ FIX: Filter out NULL
SELECT ProductID
FROM Products
WHERE ProductID NOT IN (
    SELECT ID FROM #TestData WHERE ID IS NOT NULL
);

DROP TABLE #TestData;


/*
============================================================================
PART 5: Subqueries with ANY and ALL
============================================================================
*/

-- Example 5.1: ANY operator (at least one match)
SELECT ProductName, Price
FROM Products
WHERE Price > ANY (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1
);
-- Greater than AT LEAST ONE product in category 1
-- Equivalent to: Price > MIN(prices in category 1)

-- Example 5.2: ALL operator (must match all)
SELECT ProductName, Price
FROM Products
WHERE Price > ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
);
-- Greater than ALL products in category 1
-- Equivalent to: Price > MAX(prices in category 1)

-- Example 5.3: Comparison: IN vs ANY vs ALL
/*
IN:    Value must exactly match one value in list
ANY:   Comparison true for at least one value
ALL:   Comparison true for every value

Examples:
WHERE Price = ANY(...)  ← Same as IN
WHERE Price > ANY(...)  ← Greater than minimum
WHERE Price < ALL(...)  ← Less than minimum
WHERE Price > ALL(...)  ← Greater than maximum
*/

-- Example 5.4: Practical ANY usage
SELECT ProductName, Stock
FROM Products
WHERE Stock < ANY (
    SELECT Stock
    FROM Products
    WHERE CategoryID = 1
);


/*
============================================================================
PART 6: Performance Considerations
============================================================================
*/

-- Performance 6.1: ✅ Noncorrelated subqueries are efficient
-- They run ONCE regardless of outer query size
SELECT ProductName
FROM Products  -- 1000 rows
WHERE Price > (SELECT AVG(Price) FROM Products);
-- Subquery runs exactly 1 time, not 1000 times!

-- Performance 6.2: ✅ Use IN for multiple values
SELECT ProductName
FROM Products
WHERE CategoryID IN (1, 2, 3);  -- Hardcoded

SELECT ProductName
FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM TopCategories);  -- Dynamic

-- Performance 6.3: ⚠️ Multiple subqueries in SELECT can be inefficient
-- Each subquery runs for every row
SELECT 
    ProductName,
    (SELECT AVG(Price) FROM Products) AS Avg1,  -- Same query
    (SELECT AVG(Price) FROM Products) AS Avg2,  -- Runs again
    (SELECT AVG(Price) FROM Products) AS Avg3   -- And again!
FROM Products;

-- ✅ Better: Calculate once
DECLARE @AvgPrice DECIMAL(10,2) = (SELECT AVG(Price) FROM Products);
SELECT 
    ProductName,
    @AvgPrice AS Avg1,
    @AvgPrice AS Avg2,
    @AvgPrice AS Avg3
FROM Products;

-- Performance 6.4: ✅ Index columns used in subqueries
-- If subquery filters on CategoryID, index it!
-- CREATE INDEX IX_Products_CategoryID ON Products(CategoryID);


/*
============================================================================
PART 7: Real-World Scenarios
============================================================================
*/

-- Scenario 7.1: Find high-value customers
SELECT CustomerID, CustomerName
FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Orders
    GROUP BY CustomerID
    HAVING SUM(TotalAmount) > (
        SELECT AVG(CustomerTotal)
        FROM (
            SELECT SUM(TotalAmount) AS CustomerTotal
            FROM Orders
            GROUP BY CustomerID
        ) AS CustomerTotals
    )
);

-- Scenario 7.2: Products to restock
SELECT ProductName, Stock, Price
FROM Products
WHERE Stock < (SELECT AVG(Stock) FROM Products WHERE Stock > 0)
  AND Price > (SELECT AVG(Price) FROM Products)
ORDER BY Stock;
-- Low stock but high value items

-- Scenario 7.3: Above-average orders from this month
SELECT OrderID, OrderDate, TotalAmount
FROM Orders
WHERE YEAR(OrderDate) = YEAR(GETDATE())
  AND MONTH(OrderDate) = MONTH(GETDATE())
  AND TotalAmount > (
      SELECT AVG(TotalAmount)
      FROM Orders
      WHERE YEAR(OrderDate) = YEAR(GETDATE())
        AND MONTH(OrderDate) = MONTH(GETDATE())
  );

-- Scenario 7.4: Products in popular categories
SELECT p.ProductName, p.CategoryID, p.Price
FROM Products p
WHERE p.CategoryID IN (
    SELECT TOP 3 CategoryID
    FROM (
        SELECT CategoryID, COUNT(*) AS OrderCount
        FROM OrderDetails od
        JOIN Products p ON od.ProductID = p.ProductID
        GROUP BY CategoryID
    ) CategoryOrders
    ORDER BY OrderCount DESC
);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find products cheaper than the average price
2. List customers who have never placed an order
3. Find products in categories with more than 10 products
4. Show orders larger than the average order from USA customers
5. Find products more expensive than all products in category 1

Solutions below ↓
*/

-- Solution 1:
SELECT ProductName, Price
FROM Products
WHERE Price < (SELECT AVG(Price) FROM Products)
ORDER BY Price;

-- Solution 2:
SELECT CustomerID, CustomerName, Email
FROM Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID
    FROM Orders
    WHERE CustomerID IS NOT NULL
);

-- Solution 3:
SELECT ProductName, CategoryID
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    GROUP BY CategoryID
    HAVING COUNT(*) > 10
);

-- Solution 4:
SELECT OrderID, CustomerID, TotalAmount
FROM Orders
WHERE TotalAmount > (
    SELECT AVG(o.TotalAmount)
    FROM Orders o
    JOIN Customers c ON o.CustomerID = c.CustomerID
    WHERE c.Country = 'USA'
)
ORDER BY TotalAmount DESC;

-- Solution 5:
SELECT ProductName, Price, CategoryID
FROM Products
WHERE Price > ALL (
    SELECT Price
    FROM Products
    WHERE CategoryID = 1 AND Price IS NOT NULL
)
ORDER BY Price;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ NONCORRELATED DEFINITION:
  • Independent of outer query
  • Runs ONCE
  • No reference to outer query tables
  • Result used by outer query

✓ EXECUTION FLOW:
  1. Subquery executes first (once)
  2. Returns result
  3. Outer query uses that result
  4. Much like using a variable

✓ COMMON PATTERNS:
  • Compare to aggregate (AVG, MAX, MIN)
  • Filter by list (IN, NOT IN)
  • Compare to all (ALL operator)
  • Compare to any (ANY operator)

✓ OPERATORS:
  • IN / NOT IN: Match against list
  • = / <> / > / < etc.: Single value
  • ANY: True for at least one
  • ALL: True for all values

✓ PERFORMANCE:
  • Very efficient (runs once)
  • Index columns used in subqueries
  • Avoid repeating same subquery
  • Watch for NULL in NOT IN

✓ BEST PRACTICES:
  • Use for independent calculations
  • Filter NULL in NOT IN
  • Consider JOIN as alternative
  • Index appropriately
  • Use variables for repeated subqueries

✓ WHEN TO USE:
  • Need dynamic filtering value
  • Compare to aggregate
  • Filter by derived list
  • Simpler than join logic

============================================================================
NEXT: Lesson 09.04 - Multiple-Row Subqueries
Deep dive into IN, ANY, ALL operators and handling multiple values.
============================================================================
*/
