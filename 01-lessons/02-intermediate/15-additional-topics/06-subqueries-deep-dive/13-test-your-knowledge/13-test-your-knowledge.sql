/*
============================================================================
Lesson 09.13 - Test Your Knowledge
============================================================================

Description:
Comprehensive assessment covering all subquery concepts from Chapter 09.
Tests practical application, performance awareness, and best practices.

Format:
• Multiple choice questions
• Code writing exercises
• Performance analysis
• Debugging challenges
• Real-world scenarios

Total Points: 500
Time Limit: 90 minutes
Passing Score: 350/500 (70%)

Prerequisites:
• Complete all lessons 09.01 through 09.12
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
SECTION A: MULTIPLE CHOICE (100 points - 10 questions @ 10 points each)
============================================================================
*/

-- Question A1: Which subquery type returns a single value?
-- A) Table subquery
-- B) Scalar subquery
-- C) Column subquery
-- D) Row subquery
-- Your Answer: _____

-- Question A2: What's the best operator for checking existence in large tables?
-- A) IN
-- B) NOT IN
-- C) EXISTS
-- D) ANY
-- Your Answer: _____

-- Question A3: What happens if a scalar subquery returns no rows?
-- A) Error occurs
-- B) Returns empty string
-- C) Returns NULL
-- D) Returns 0
-- Your Answer: _____

-- Question A4: Which is faster for large datasets?
-- A) Correlated subquery in SELECT
-- B) Window function with OVER
-- C) Both are equal
-- D) Depends on data distribution
-- Your Answer: _____

-- Question A5: What's wrong with: WHERE CategoryID NOT IN (SELECT CategoryID FROM Categories)
-- A) Syntax error
-- B) NULL values cause unexpected results
-- C) Too slow
-- D) Nothing wrong
-- Your Answer: _____

-- Question A6: Where can subqueries NOT be used?
-- A) ORDER BY clause
-- B) GROUP BY clause
-- C) WHERE clause
-- D) Both A and B
-- Your Answer: _____

-- Question A7: What does EXISTS return?
-- A) The rows from the subquery
-- B) TRUE or FALSE
-- C) The count of matching rows
-- D) NULL if no match
-- Your Answer: _____

-- Question A8: Which requires MAXRECURSION option?
-- A) Correlated subquery
-- B) Recursive CTE
-- C) Nested subquery
-- D) Derived table
-- Your Answer: _____

-- Question A9: What's the main benefit of CTEs over derived tables?
-- A) Better performance
-- B) Better readability
-- C) Less memory usage
-- D) Faster execution
-- Your Answer: _____

-- Question A10: When should you use ALL operator?
-- A) To check if value equals all values
-- B) To compare against all values
-- C) To select all rows
-- D) To avoid NULL issues
-- Your Answer: _____


/*
============================================================================
SECTION B: CODE WRITING (150 points - 5 exercises @ 30 points each)
============================================================================
*/

-- Exercise B1: (30 points)
-- Write a query to find all products that cost more than the average price
-- in their category. Include product name, price, and category average.
-- Use a correlated subquery.

-- YOUR SOLUTION:




-- Exercise B2: (30 points)
-- Find customers who have placed more orders than the average customer.
-- Show customer name, order count, and the average order count.
-- Use a CTE.

-- YOUR SOLUTION:




-- Exercise B3: (30 points)
-- Get the top 2 most expensive products in each category.
-- Include category name, product name, and price.
-- Use a window function with CTE.

-- YOUR SOLUTION:




-- Exercise B4: (30 points)
-- Find all customers who have NEVER ordered products from category 'Electronics'.
-- Show only customer ID and name.
-- Use NOT EXISTS.

-- YOUR SOLUTION:




-- Exercise B5: (30 points)
-- Create a query showing each order with its percentage of the customer's
-- total spending. Include OrderID, TotalAmount, and PercentOfCustomerTotal.
-- Use correlated subqueries.

-- YOUR SOLUTION:




/*
============================================================================
SECTION C: PERFORMANCE ANALYSIS (100 points - 4 scenarios @ 25 points each)
============================================================================
*/

-- Scenario C1: (25 points)
-- Compare these two approaches and explain which is better and why:

-- Approach A:
SELECT CustomerID, CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;

-- Approach B:
SELECT c.CustomerID, c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Which is better? _____
-- Explain why:
-- _________________________________________________________________
-- _________________________________________________________________


-- Scenario C2: (25 points)
-- Identify the performance issue and rewrite for better performance:

SELECT 
    ProductID,
    ProductName,
    Price - (SELECT AVG(Price) FROM Products) AS Diff1,
    Price / (SELECT AVG(Price) FROM Products) AS Ratio1,
    (SELECT AVG(Price) FROM Products) AS Avg
FROM Products;

-- Issue: __________________________________________________________
-- YOUR IMPROVED SOLUTION:




-- Scenario C3: (25 points)
-- Which query would perform better and why?

-- Query A:
SELECT ProductName FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM Categories WHERE CategoryName = 'Electronics');

-- Query B:
SELECT ProductName FROM Products p
WHERE EXISTS (SELECT 1 FROM Categories c WHERE c.CategoryID = p.CategoryID AND c.CategoryName = 'Electronics');

-- Better choice: _____
-- Reasoning:
-- _________________________________________________________________
-- _________________________________________________________________


-- Scenario C4: (25 points)
-- Fix this slow query:

SELECT 
    o.OrderID,
    o.TotalAmount,
    (SELECT AVG(TotalAmount) FROM Orders WHERE CustomerID = o.CustomerID) AS CustomerAvg,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = o.CustomerID) AS CustomerOrderCount,
    (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = o.CustomerID) AS LastOrderDate
FROM Orders o;

-- YOUR OPTIMIZED SOLUTION:




/*
============================================================================
SECTION D: DEBUGGING (100 points - 5 problems @ 20 points each)
============================================================================
*/

-- Problem D1: (20 points)
-- This query has an error. Find and fix it.

/*
SELECT ProductName, Price
FROM Products
WHERE Price = (SELECT Price FROM Products WHERE CategoryID = 1);
*/

-- Error: __________________________________________________________
-- CORRECTED QUERY:




-- Problem D2: (20 points)
-- This query returns unexpected results. Fix it.

/*
SELECT CustomerName
FROM Customers
WHERE CustomerID NOT IN (SELECT CustomerID FROM Orders WHERE TotalAmount > 1000);
*/

-- Problem: _________________________________________________________
-- CORRECTED QUERY:




-- Problem D3: (20 points)
-- This query is syntactically correct but logically flawed. Fix it.

/*
SELECT 
    ProductName,
    (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID)
FROM Products p;
*/

-- Issue: __________________________________________________________
-- CORRECTED QUERY:




-- Problem D4: (20 points)
-- Fix this recursive CTE that causes an error:

/*
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM Numbers
)
SELECT * FROM Numbers;
*/

-- Error: __________________________________________________________
-- CORRECTED QUERY:




-- Problem D5: (20 points)
-- This query doesn't return expected results. Debug and fix:

/*
SELECT c.CategoryName, AVG(p.Price)
FROM Categories c
WHERE c.CategoryID IN (SELECT CategoryID FROM Products WHERE Price > 100)
GROUP BY c.CategoryName;
*/

-- Issue: __________________________________________________________
-- CORRECTED QUERY:




/*
============================================================================
SECTION E: REAL-WORLD SCENARIOS (50 points - 2 scenarios @ 25 points each)
============================================================================
*/

-- Scenario E1: (25 points)
-- Business requirement: Create a customer segmentation report showing:
-- - Customer name
-- - Total orders
-- - Total spent
-- - Segment (VIP: >$10,000, Gold: >$5,000, Silver: >$1,000, Bronze: rest)
-- - Whether they ordered in last 90 days (Yes/No)
-- 
-- Use appropriate subquery techniques. Optimize for performance.

-- YOUR SOLUTION:




-- Scenario E2: (25 points)
-- Business requirement: Product performance report showing:
-- - Product name
-- - Current price
-- - Category average price
-- - Total quantity sold
-- - Rank within category by sales
-- - Status: "Star" if top 3 in category by sales, "Standard" otherwise
--
-- Use efficient subquery/CTE approach.

-- YOUR SOLUTION:




/*
============================================================================
ANSWER KEY
============================================================================
*/

-- SECTION A ANSWERS (Multiple Choice)
/*
A1: B - Scalar subquery returns a single value
A2: C - EXISTS is best for checking existence, stops at first match
A3: C - Returns NULL when no rows returned
A4: B - Window functions are generally faster than correlated subqueries
A5: B - NULL values in subquery cause NOT IN to fail
A6: D - Subqueries not allowed in ORDER BY or GROUP BY (with exceptions)
A7: B - EXISTS returns TRUE/FALSE (boolean)
A8: B - Recursive CTE requires MAXRECURSION to prevent infinite loops
A9: B - CTEs provide better readability (performance similar)
A10: B - ALL compares value against all values in set
*/

-- SECTION B ANSWERS (Code Writing)

-- B1 Solution:
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.CategoryID = p1.CategoryID) AS CategoryAvg
FROM Products p1
WHERE Price > (
    SELECT AVG(Price) 
    FROM Products p2 
    WHERE p2.CategoryID = p1.CategoryID
);

-- B2 Solution:
WITH CustomerOrderCounts AS (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
),
AvgOrderCount AS (
    SELECT AVG(CAST(OrderCount AS FLOAT)) AS Avg
    FROM CustomerOrderCounts
)
SELECT 
    c.CustomerName,
    coc.OrderCount,
    aoc.Avg AS AvgOrderCount
FROM Customers c
JOIN CustomerOrderCounts coc ON c.CustomerID = coc.CustomerID
CROSS JOIN AvgOrderCount aoc
WHERE coc.OrderCount > aoc.Avg;

-- B3 Solution:
WITH RankedProducts AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        p.Price,
        ROW_NUMBER() OVER (PARTITION BY c.CategoryID ORDER BY p.Price DESC) AS PriceRank
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
)
SELECT CategoryName, ProductName, Price
FROM RankedProducts
WHERE PriceRank <= 2;

-- B4 Solution:
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Categories cat ON p.CategoryID = cat.CategoryID
    WHERE o.CustomerID = c.CustomerID
    AND cat.CategoryName = 'Electronics'
);

-- B5 Solution:
SELECT 
    OrderID,
    TotalAmount,
    (TotalAmount / NULLIF((
        SELECT SUM(TotalAmount)
        FROM Orders o2
        WHERE o2.CustomerID = o1.CustomerID
    ), 0)) * 100 AS PercentOfCustomerTotal
FROM Orders o1;


-- SECTION C ANSWERS (Performance Analysis)

-- C1 Answer:
-- Better: Approach B
-- Reason: JOIN with GROUP BY is faster than correlated subquery in SELECT.
-- The correlated subquery executes once per customer row, while JOIN
-- performs a single pass with aggregation.

-- C2 Solution:
-- Issue: Average calculated 3 times (inefficient)
WITH AvgPrice AS (
    SELECT AVG(Price) AS Avg FROM Products
)
SELECT 
    ProductID,
    ProductName,
    Price - Avg AS Diff1,
    Price / Avg AS Ratio1,
    Avg
FROM Products CROSS JOIN AvgPrice;

-- C3 Answer:
-- Better: Query A (for small result sets) or Query B (for large tables)
-- Reason: For small Categories table, IN is fine. For large tables or
-- when NULL is possible, EXISTS is safer and potentially faster.
-- EXISTS can short-circuit, IN builds entire list.

-- C4 Solution:
SELECT 
    o.OrderID,
    o.TotalAmount,
    stats.CustomerAvg,
    stats.CustomerOrderCount,
    stats.LastOrderDate
FROM Orders o
CROSS APPLY (
    SELECT 
        AVG(TotalAmount) AS CustomerAvg,
        COUNT(*) AS CustomerOrderCount,
        MAX(OrderDate) AS LastOrderDate
    FROM Orders
    WHERE CustomerID = o.CustomerID
) stats;


-- SECTION D ANSWERS (Debugging)

-- D1 Solution:
-- Error: Subquery returns multiple rows
SELECT ProductName, Price
FROM Products
WHERE Price IN (SELECT Price FROM Products WHERE CategoryID = 1);
-- OR:
SELECT ProductName, Price
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products WHERE CategoryID = 1);

-- D2 Solution:
-- Problem: NOT IN fails with NULL values in Orders.CustomerID
SELECT CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders 
    WHERE CustomerID = c.CustomerID 
    AND TotalAmount > 1000
);

-- D3 Solution:
-- Issue: NULL not handled (products never ordered return NULL)
SELECT 
    ProductName,
    ISNULL((SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID), 0) AS TotalSold
FROM Products p;

-- D4 Solution:
-- Error: No termination condition, infinite recursion
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 
    FROM Numbers
    WHERE n < 100  -- Add termination
)
SELECT * FROM Numbers
OPTION (MAXRECURSION 100);

-- D5 Solution:
-- Issue: Missing JOIN, can't use AVG in SELECT with WHERE + GROUP BY
SELECT 
    c.CategoryName, 
    AVG(p.Price) AS AvgPrice
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
WHERE p.Price > 100
GROUP BY c.CategoryName;


-- SECTION E ANSWERS (Real-World Scenarios)

-- E1 Solution:
WITH CustomerStats AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS TotalOrders,
        ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    TotalOrders,
    TotalSpent,
    CASE 
        WHEN TotalSpent > 10000 THEN 'VIP'
        WHEN TotalSpent > 5000 THEN 'Gold'
        WHEN TotalSpent > 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS Segment,
    CASE 
        WHEN LastOrderDate >= DATEADD(DAY, -90, GETDATE()) THEN 'Yes'
        ELSE 'No'
    END AS OrderedLast90Days
FROM CustomerStats
ORDER BY TotalSpent DESC;

-- E2 Solution:
WITH ProductSales AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS TotalSold
    FROM OrderDetails
    GROUP BY ProductID
),
RankedProducts AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Price,
        p.CategoryID,
        c.CategoryName,
        ISNULL(ps.TotalSold, 0) AS TotalSold,
        AVG(p.Price) OVER (PARTITION BY p.CategoryID) AS CategoryAvgPrice,
        ROW_NUMBER() OVER (PARTITION BY p.CategoryID ORDER BY ISNULL(ps.TotalSold, 0) DESC) AS SalesRank
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN ProductSales ps ON p.ProductID = ps.ProductID
)
SELECT 
    ProductName,
    Price,
    CategoryAvgPrice,
    TotalSold,
    SalesRank,
    CASE WHEN SalesRank <= 3 THEN 'Star' ELSE 'Standard' END AS Status
FROM RankedProducts
ORDER BY CategoryName, SalesRank;


/*
============================================================================
SCORING RUBRIC
============================================================================

SECTION A: Multiple Choice (100 points)
- Each correct answer: 10 points
- Partial credit: None

SECTION B: Code Writing (150 points)
- Correct solution: 30 points
- Partially correct: 15 points
- Incorrect approach: 0 points

SECTION C: Performance Analysis (100 points)
- Correct identification + explanation: 25 points
- Correct identification only: 15 points
- Partial understanding: 10 points

SECTION D: Debugging (100 points)
- Correct fix + explanation: 20 points
- Correct fix only: 15 points
- Partial fix: 10 points

SECTION E: Real-World Scenarios (50 points)
- Optimal solution: 25 points
- Working solution: 20 points
- Partially working: 10 points

TOTAL: 500 points
PASSING: 350 points (70%)

GRADE SCALE:
- 450-500: Excellent (A)
- 400-449: Very Good (B)
- 350-399: Good (C)
- 300-349: Needs Improvement (D)
- Below 300: Fail (F)

============================================================================
SELF-ASSESSMENT CHECKLIST
============================================================================

After completing this test, you should be able to:

✓ Identify and use all subquery types (scalar, row, column, table)
✓ Choose appropriate operators (IN, EXISTS, ANY, ALL)
✓ Understand correlated vs noncorrelated subqueries
✓ Use subqueries in all SQL clauses (WHERE, HAVING, SELECT, FROM)
✓ Write and optimize CTEs
✓ Create recursive CTEs for hierarchical data
✓ Make informed decisions: subquery vs JOIN vs window function
✓ Handle NULL values correctly in subqueries
✓ Debug common subquery errors
✓ Optimize subquery performance
✓ Apply subqueries to real-world business problems

If you scored below 70%, review the lessons where you struggled:
- Section A: Lessons 09.01-09.03 (Fundamentals)
- Section B: Lessons 09.04-09.07 (Types and Operators)
- Section C: Lesson 09.09 (When to Use)
- Section D: Lessons 09.06-09.08 (Correlated and Data Manipulation)
- Section E: Lessons 09.10-09.12 (Advanced Applications)

============================================================================
CONGRATULATIONS!
You have completed Chapter 09 - Subqueries!

Next Chapter: Chapter 10 - Joins Revisited
Advanced join techniques, outer joins, self-joins, and cross joins.
============================================================================
*/
