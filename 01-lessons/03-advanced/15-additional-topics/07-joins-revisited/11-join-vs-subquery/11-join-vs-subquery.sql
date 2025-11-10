/*
============================================================================
Lesson 10.11 - Join vs Subquery
============================================================================

Description:
Learn when to use joins vs subqueries for optimal performance and
readability. Understand the trade-offs, best practices, and how SQL
Server optimizes each approach.

Topics Covered:
• Join vs subquery performance
• Readability and maintainability
• Scalar vs correlated vs derived table subqueries
• When each approach is better
• Optimization and execution plans
• Real-world decision criteria

Prerequisites:
• Lessons 10.01-10.10
• Chapter 09 (Subqueries)

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding the Options
============================================================================
*/

-- Scenario 1.1: Get customer names and their order counts
-- Using JOIN:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Using Correlated Subquery:
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) 
     FROM Orders o 
     WHERE o.CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;

-- Using Derived Table:
SELECT 
    c.CustomerID,
    c.CustomerName,
    ISNULL(oc.OrderCount, 0) AS OrderCount
FROM Customers c
LEFT JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
) oc ON c.CustomerID = oc.CustomerID;

/*
All three produce the same result!
Which is best? Let's analyze...
*/


/*
============================================================================
PART 2: Performance Comparison
============================================================================
*/

-- Performance 2.1: Simple lookups
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- JOIN approach:
SELECT 
    o.OrderID,
    o.OrderDate,
    c.CustomerName
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE o.OrderID <= 100;

-- Subquery approach:
SELECT 
    o.OrderID,
    o.OrderDate,
    (SELECT c.CustomerName 
     FROM Customers c 
     WHERE c.CustomerID = o.CustomerID) AS CustomerName
FROM Orders o
WHERE o.OrderID <= 100;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

/*
Result: JOIN is usually faster
• Single pass through data
• Better optimization
• Can use indexes efficiently
*/

-- Performance 2.2: Aggregations
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- JOIN with GROUP BY:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Multiple correlated subqueries:
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) AS OrderCount,
    (SELECT SUM(TotalAmount) FROM Orders o WHERE o.CustomerID = c.CustomerID) AS TotalSpent
FROM Customers c;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

/*
Result: Multiple subqueries are SLOWER
• Orders table accessed twice
• No optimization opportunity
• JOIN with GROUP BY is better
*/


/*
============================================================================
PART 3: When to Use JOIN
============================================================================
*/

-- Use JOIN 3.1: ✅ Retrieving columns from multiple tables
SELECT 
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01';
-- Clear, efficient, returns related data

-- Use JOIN 3.2: ✅ Multiple aggregations from same table
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    AVG(o.TotalAmount) AS AvgOrderValue,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;
-- One pass through Orders, all aggregates together

-- Use JOIN 3.3: ✅ Many-to-many relationships
SELECT 
    c.CustomerName,
    p.ProductName,
    od.Quantity,
    o.OrderDate
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE c.CustomerID = 1;
-- Natural way to navigate relationships

-- Use JOIN 3.4: ✅ Performance-critical queries
SELECT 
    o.OrderID,
    c.CustomerName,
    p.ProductName,
    od.Quantity
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderDate >= '2024-01-01';
-- Optimizer can create efficient execution plan


/*
============================================================================
PART 4: When to Use Subquery
============================================================================
*/

-- Use Subquery 4.1: ✅ Single value needed
SELECT 
    o.OrderID,
    o.TotalAmount,
    (SELECT AVG(TotalAmount) FROM Orders) AS OverallAverage,
    o.TotalAmount - (SELECT AVG(TotalAmount) FROM Orders) AS Difference
FROM Orders o
WHERE o.OrderID <= 10;
-- Clear intent: Compare to overall average

-- Use Subquery 4.2: ✅ Existence checks (semi-join/anti-join)
-- Find customers who have ordered:
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);
-- More efficient than JOIN + DISTINCT

-- Customers who have NOT ordered:
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);
-- Clearer than LEFT JOIN with NULL check

-- Use Subquery 4.3: ✅ Filtering based on aggregates
-- Orders above customer's average:
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
WHERE o.TotalAmount > (
    SELECT AVG(TotalAmount) 
    FROM Orders 
    WHERE CustomerID = o.CustomerID
);
-- Self-referencing comparison

-- Use Subquery 4.4: ✅ Derived tables for complex logic
SELECT 
    CustomerCategory,
    AVG(OrderCount) AS AvgOrdersPerCustomer
FROM (
    SELECT 
        c.CustomerID,
        CASE 
            WHEN COUNT(o.OrderID) >= 10 THEN 'High'
            WHEN COUNT(o.OrderID) >= 5 THEN 'Medium'
            ELSE 'Low'
        END AS CustomerCategory,
        COUNT(o.OrderID) AS OrderCount
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
) AS CustomerStats
GROUP BY CustomerCategory;
-- Breaks down complex logic into steps


/*
============================================================================
PART 5: Readability Considerations
============================================================================
*/

-- Readability 5.1: JOIN for related data (clearer)
-- ✅ Easy to understand:
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.Country = 'USA';

-- ❌ Less clear:
SELECT 
    (SELECT CustomerName FROM Customers WHERE CustomerID = o.CustomerID),
    o.OrderID,
    o.OrderDate
FROM Orders o
WHERE (SELECT Country FROM Customers WHERE CustomerID = o.CustomerID) = 'USA';

-- Readability 5.2: Subquery for single lookup (sometimes clearer)
-- ✅ Intent is clear:
SELECT 
    OrderID,
    TotalAmount,
    (SELECT AVG(TotalAmount) FROM Orders) AS GlobalAverage
FROM Orders
WHERE OrderID <= 10;

-- ❌ Overkill with JOIN:
SELECT DISTINCT
    o.OrderID,
    o.TotalAmount,
    avg_orders.GlobalAverage
FROM Orders o
CROSS JOIN (
    SELECT AVG(TotalAmount) AS GlobalAverage FROM Orders
) avg_orders
WHERE o.OrderID <= 10;

-- Readability 5.3: CTE for complex queries (best of both)
WITH CustomerSummary AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
),
CustomerCategories AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN OrderCount >= 10 THEN 'VIP'
            WHEN OrderCount >= 5 THEN 'Regular'
            ELSE 'New'
        END AS Category
    FROM CustomerSummary
)
SELECT 
    c.CustomerName,
    cs.OrderCount,
    cs.TotalSpent,
    cc.Category
FROM Customers c
INNER JOIN CustomerSummary cs ON c.CustomerID = cs.CustomerID
INNER JOIN CustomerCategories cc ON c.CustomerID = cc.CustomerID;
-- Readable, maintainable, efficient


/*
============================================================================
PART 6: Optimizer Behavior
============================================================================
*/

-- Optimizer 6.1: Often produces same plan
SET STATISTICS TIME ON;
SET SHOWPLAN_TEXT OFF;

-- Approach 1: JOIN
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID = 1;

-- Approach 2: Subquery
SELECT c.CustomerName, 
       (SELECT o.OrderID FROM Orders o WHERE o.CustomerID = c.CustomerID) AS OrderID
FROM Customers c
WHERE c.CustomerID = 1;

-- Check execution plans - may be identical!

SET STATISTICS TIME OFF;

-- Optimizer 6.2: Derived tables often optimized well
-- This:
SELECT * FROM Customers c
INNER JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
) oc ON c.CustomerID = oc.CustomerID;

-- Often produces same plan as:
SELECT c.*, COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;  -- (plus all other columns)


/*
============================================================================
PART 7: Specific Scenarios
============================================================================
*/

-- Scenario 7.1: Top N per group (subquery better)
-- Top 2 orders per customer:
SELECT 
    o.CustomerID,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
WHERE o.OrderID IN (
    SELECT TOP 2 OrderID
    FROM Orders
    WHERE CustomerID = o.CustomerID
    ORDER BY TotalAmount DESC
)
ORDER BY o.CustomerID, o.TotalAmount DESC;

-- Alternative with ROW_NUMBER (often better):
WITH RankedOrders AS (
    SELECT 
        CustomerID,
        OrderID,
        OrderDate,
        TotalAmount,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY TotalAmount DESC) AS rn
    FROM Orders
)
SELECT CustomerID, OrderID, OrderDate, TotalAmount
FROM RankedOrders
WHERE rn <= 2
ORDER BY CustomerID, TotalAmount DESC;

-- Scenario 7.2: Complex filtering (EXISTS better)
-- Customers who ordered Product 1 AND Product 2:
SELECT c.CustomerID, c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID AND od.ProductID = 1
)
AND EXISTS (
    SELECT 1 FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID AND od.ProductID = 2
);

-- Scenario 7.3: Running totals (window functions best)
-- ❌ Slow correlated subquery:
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    (SELECT SUM(TotalAmount) 
     FROM Orders o2 
     WHERE o2.CustomerID = o1.CustomerID 
       AND o2.OrderDate <= o1.OrderDate) AS RunningTotal
FROM Orders o1
WHERE CustomerID = 1
ORDER BY OrderDate;

-- ✅ Fast window function:
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS RunningTotal
FROM Orders
WHERE CustomerID = 1
ORDER BY OrderDate;


/*
============================================================================
PART 8: Decision Framework
============================================================================
*/

/*
USE JOIN WHEN:
✓ Need columns from multiple tables
✓ Many-to-many relationships
✓ Multiple aggregations from same table
✓ Performance is critical
✓ Result naturally shows relationships
✓ Query is already complex with subqueries

USE SUBQUERY WHEN:
✓ Single scalar value needed
✓ Existence/non-existence check (EXISTS/NOT EXISTS)
✓ Self-referencing comparison
✓ Derived table for intermediate results
✓ Filtering on aggregates from same table
✓ Top N per group patterns

USE CTE WHEN:
✓ Complex multi-step logic
✓ Need to reference result multiple times
✓ Recursive queries
✓ Improve readability
✓ Debugging complex queries

USE WINDOW FUNCTIONS WHEN:
✓ Running totals/aggregates
✓ Ranking (ROW_NUMBER, RANK, DENSE_RANK)
✓ Moving averages
✓ Comparing to previous/next rows
*/


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Rewrite a correlated subquery as a JOIN and compare performance
2. Identify when EXISTS is better than JOIN + DISTINCT
3. Convert multiple scalar subqueries to a single JOIN
4. Compare execution plans for JOIN vs derived table
5. Rewrite a complex query using CTEs for readability

Solutions below ↓
*/

-- Solution 1:
-- Correlated subquery:
SET STATISTICS TIME ON;
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;

-- JOIN version:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;
SET STATISTICS TIME OFF;
-- JOIN is typically faster

-- Solution 2:
-- Need distinct customers who ordered:
-- ❌ Slower:
SELECT DISTINCT c.CustomerID, c.CustomerName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- ✅ Faster:
SELECT c.CustomerID, c.CustomerName
FROM Customers c
WHERE EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID);

-- Solution 3:
-- Multiple scalar subqueries:
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount,
    (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalSpent,
    (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID) AS LastOrder
FROM Customers c;

-- Single JOIN:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    MAX(o.OrderDate) AS LastOrder
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Solution 4:
SET SHOWPLAN_TEXT OFF;  -- Use graphical plan

-- JOIN:
SELECT c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Derived table:
SELECT c.CustomerName, ISNULL(oc.OrderCount, 0) AS OrderCount
FROM Customers c
LEFT JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
) oc ON c.CustomerID = oc.CustomerID;
-- Compare plans in SSMS

-- Solution 5:
-- Before (hard to read):
SELECT 
    c.CustomerName,
    o.OrderCount,
    o.TotalSpent,
    CASE 
        WHEN o.OrderCount >= 10 THEN 'VIP'
        WHEN o.OrderCount >= 5 THEN 'Regular'
        ELSE 'New'
    END AS Category
FROM Customers c
INNER JOIN (
    SELECT CustomerID, COUNT(*) AS OrderCount, SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
) o ON c.CustomerID = o.CustomerID
WHERE o.OrderCount > 0;

-- After (with CTE):
WITH CustomerStats AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
),
CustomerWithCategories AS (
    SELECT 
        cs.CustomerID,
        cs.OrderCount,
        cs.TotalSpent,
        CASE 
            WHEN cs.OrderCount >= 10 THEN 'VIP'
            WHEN cs.OrderCount >= 5 THEN 'Regular'
            ELSE 'New'
        END AS Category
    FROM CustomerStats cs
    WHERE cs.OrderCount > 0
)
SELECT 
    c.CustomerName,
    cwc.OrderCount,
    cwc.TotalSpent,
    cwc.Category
FROM Customers c
INNER JOIN CustomerWithCategories cwc ON c.CustomerID = cwc.CustomerID;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ PERFORMANCE:
  • JOIN usually faster for multi-column retrieval
  • Multiple scalar subqueries are slow
  • EXISTS better than JOIN for existence checks
  • Optimizer often produces same plan
  • Test with realistic data

✓ JOIN ADVANTAGES:
  • Natural for related data
  • One pass through tables
  • Better optimization
  • Multiple aggregations efficient
  • Clear execution plan

✓ SUBQUERY ADVANTAGES:
  • EXISTS/NOT EXISTS for filtering
  • Single scalar values
  • Self-referencing logic
  • Sometimes more readable
  • Derived tables for intermediate results

✓ READABILITY:
  • Use CTEs for complex logic
  • Break down multi-step queries
  • Choose pattern that shows intent
  • Consistent style in codebase
  • Comment complex queries

✓ BEST PRACTICES:
  • Default to JOIN for related data
  • Use EXISTS for existence checks
  • Avoid multiple scalar subqueries
  • Test performance with both
  • Check execution plans
  • Use CTEs for clarity

✓ WATCH OUT FOR:
  • Correlated subqueries in SELECT (slow)
  • Multiple subqueries on same table
  • NOT IN with NULLs
  • Unnecessary derived tables
  • Complex nesting (use CTEs)

✓ MODERN SQL:
  • Window functions > correlated subqueries
  • CTEs > deeply nested subqueries
  • EXISTS > IN for subqueries
  • NOT EXISTS > NOT IN (always)

============================================================================
NEXT: Lesson 10.12 - Advanced Join Techniques
Explore APPLY, lateral joins, and advanced patterns.
============================================================================
*/
