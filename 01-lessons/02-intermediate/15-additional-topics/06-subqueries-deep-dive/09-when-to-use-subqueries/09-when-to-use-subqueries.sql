/*
============================================================================
Lesson 09.09 - When to Use Subqueries
============================================================================

Description:
Learn to make informed decisions about when to use subqueries versus
JOINs, CTEs, or other SQL techniques. Understand trade-offs in 
readability, performance, and maintainability.

Topics Covered:
• Subqueries vs JOINs
• Subqueries vs CTEs
• Performance comparison
• Readability factors
• Decision guidelines

Prerequisites:
• Lessons 09.01-09.08
• Chapter 05 (Joins)

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Subqueries vs JOINs - When to Choose
============================================================================
*/

-- Scenario 1.1: Finding customers with orders
-- Both approaches work, but JOIN is usually better:

-- ✅ JOIN approach (preferred)
SELECT DISTINCT c.CustomerID, c.CustomerName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- ⚠️ Subquery approach (works but slower)
SELECT CustomerID, CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID
);

/* Analysis:
   JOIN: Optimized by SQL Server, single scan of Orders
   Subquery: May execute for each row in Customers
   Winner: JOIN for this case
*/

-- Scenario 1.2: Finding customers WITHOUT orders
-- Here, subquery might be clearer:

-- ✅ Subquery approach (clearer intent)
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID
);

-- ✅ JOIN approach (also good)
SELECT c.CustomerID, c.CustomerName
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

/* Analysis:
   Subquery: Intent is clear - "customers not in orders"
   JOIN: Requires NULL check understanding
   Winner: Personal preference, both perform similarly
*/

-- Scenario 1.3: Filtering by aggregate
-- Subquery is cleaner:

-- ✅ Subquery approach (cleaner)
SELECT ProductID, ProductName, Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- ⚠️ JOIN approach (awkward)
SELECT p.ProductID, p.ProductName, p.Price
FROM Products p
CROSS JOIN (SELECT AVG(Price) AS AvgPrice FROM Products) avg
WHERE p.Price > avg.AvgPrice;

/* Analysis:
   Subquery: Natural and readable
   JOIN: Requires CROSS JOIN, less intuitive
   Winner: Subquery
*/


/*
============================================================================
PART 2: Use Subqueries WHEN...
============================================================================
*/

-- WHEN 2.1: ✅ You need a single scalar value
SELECT 
    ProductID,
    ProductName,
    Price,
    Price - (SELECT AVG(Price) FROM Products) AS PriceDifference,
    (Price / (SELECT AVG(Price) FROM Products)) * 100 AS PricePercentOfAvg
FROM Products;

-- WHEN 2.2: ✅ Checking existence/non-existence
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders 
    WHERE CustomerID = c.CustomerID
    AND OrderDate >= DATEADD(YEAR, -1, GETDATE())
);

-- WHEN 2.3: ✅ Filtering by aggregate conditions
SELECT CategoryID, AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID
HAVING AVG(Price) > (SELECT AVG(Price) FROM Products);

-- WHEN 2.4: ✅ Working with lists (IN operator)
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID 
    FROM Categories 
    WHERE CategoryName IN ('Electronics', 'Computers')
);

-- WHEN 2.5: ✅ Row-by-row comparison needed
SELECT 
    o.OrderID,
    o.TotalAmount,
    (
        SELECT AVG(TotalAmount)
        FROM Orders
        WHERE CustomerID = o.CustomerID
    ) AS CustomerAvg
FROM Orders o
WHERE o.TotalAmount > (
    SELECT AVG(TotalAmount)
    FROM Orders
    WHERE CustomerID = o.CustomerID
);


/*
============================================================================
PART 3: Use JOINs WHEN...
============================================================================
*/

-- WHEN 3.1: ✅ You need columns from multiple tables
-- Subquery ❌ (can't get Order details)
-- SELECT CustomerName FROM Customers WHERE CustomerID IN (SELECT CustomerID FROM Orders);

-- JOIN ✅
SELECT DISTINCT
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- WHEN 3.2: ✅ Aggregating across related data
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- WHEN 3.3: ✅ Many-to-many relationships
SELECT 
    c.CategoryName,
    p.ProductName,
    od.Quantity
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID;

-- WHEN 3.4: ✅ Performance critical queries
-- JOIN is usually faster for large datasets
SELECT c.CustomerName, o.OrderID, o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 500;


/*
============================================================================
PART 4: Subqueries vs CTEs (Common Table Expressions)
============================================================================
*/

-- Scenario 4.1: Complex nested subqueries
-- ❌ Hard to read nested subqueries:
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID IN (
    SELECT CategoryID
    FROM Products
    WHERE ProductID IN (
        SELECT ProductID
        FROM OrderDetails
        GROUP BY ProductID
        HAVING SUM(Quantity) > 100
    )
);

-- ✅ Clear CTE approach:
WITH HighVolumeProducts AS (
    SELECT ProductID
    FROM OrderDetails
    GROUP BY ProductID
    HAVING SUM(Quantity) > 100
),
RelevantCategories AS (
    SELECT DISTINCT CategoryID
    FROM Products
    WHERE ProductID IN (SELECT ProductID FROM HighVolumeProducts)
)
SELECT ProductID, ProductName
FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM RelevantCategories);

-- Scenario 4.2: Reusing subquery results
-- ❌ Repeated subquery:
SELECT 
    ProductID,
    ProductName,
    Price,
    Price - (SELECT AVG(Price) FROM Products) AS Difference,
    (Price / (SELECT AVG(Price) FROM Products)) * 100 AS Percentage
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- ✅ CTE (computed once):
WITH AvgPrice AS (
    SELECT AVG(Price) AS Avg FROM Products
)
SELECT 
    ProductID,
    ProductName,
    Price,
    Price - (SELECT Avg FROM AvgPrice) AS Difference,
    (Price / (SELECT Avg FROM AvgPrice)) * 100 AS Percentage
FROM Products
WHERE Price > (SELECT Avg FROM AvgPrice);

-- Scenario 4.3: Recursive operations
-- ✅ CTEs support recursion (subqueries don't):
-- Example: Employee hierarchy (if we had that table)
-- WITH EmployeeHierarchy AS (
--     SELECT EmployeeID, ManagerID, 1 AS Level
--     FROM Employees WHERE ManagerID IS NULL
--     UNION ALL
--     SELECT e.EmployeeID, e.ManagerID, Level + 1
--     FROM Employees e
--     JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
-- )
-- SELECT * FROM EmployeeHierarchy;


/*
============================================================================
PART 5: Performance Comparison
============================================================================
*/

-- Test 5.1: Simple filter
-- Turn on statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Subquery version
SELECT CustomerID, CustomerName
FROM Customers
WHERE CustomerID IN (SELECT CustomerID FROM Orders);

-- JOIN version
SELECT DISTINCT c.CustomerID, c.CustomerName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

/* Usually similar performance, but JOIN might be slightly faster */

-- Test 5.2: Correlated subquery vs JOIN
-- Correlated subquery (slower)
SELECT 
    o.OrderID,
    o.TotalAmount,
    (SELECT COUNT(*) FROM OrderDetails WHERE OrderID = o.OrderID) AS ItemCount
FROM Orders o;

-- JOIN with GROUP BY (faster)
SELECT 
    o.OrderID,
    o.TotalAmount,
    COUNT(od.OrderDetailID) AS ItemCount
FROM Orders o
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, o.TotalAmount;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


/*
============================================================================
PART 6: Decision Guidelines
============================================================================
*/

-- Guideline 6.1: Readability Matrix
/*
┌─────────────────────────┬──────────────┬─────────────────┐
│ Use Case                │ Best Choice  │ Reason          │
├─────────────────────────┼──────────────┼─────────────────┤
│ Single scalar value     │ Subquery     │ Simple, clear   │
│ Existence check         │ Subquery     │ Clear intent    │
│ Multi-table columns     │ JOIN         │ Only option     │
│ Aggregation across      │ JOIN         │ Natural fit     │
│ Complex nesting         │ CTE          │ Readable        │
│ Reused calculation      │ CTE          │ Efficient       │
│ Top N per group         │ CTE/Window   │ Modern approach │
└─────────────────────────┴──────────────┴─────────────────┘
*/

-- Guideline 6.2: Performance factors
/*
Consider using JOIN when:
✓ Large datasets (>100K rows)
✓ Multiple columns needed
✓ Indexed foreign keys
✓ Complex aggregations

Consider using Subquery when:
✓ Small reference tables
✓ Simple existence checks
✓ Single value comparisons
✓ Clearer intent
*/

-- Guideline 6.3: Maintenance considerations
/*
Prefer JOINs when:
✓ Schema might change
✓ Columns may be added
✓ Multiple developers
✓ Long-term maintenance

Prefer Subqueries when:
✓ Quick one-off queries
✓ Self-contained logic
✓ Temporary analysis
*/


/*
============================================================================
PART 7: Real-World Examples with Recommendations
============================================================================
*/

-- Example 7.1: Customer analysis
-- Goal: Find high-value customers
-- ✅ RECOMMENDED: JOIN
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING SUM(o.TotalAmount) > 5000
ORDER BY TotalSpent DESC;

-- Example 7.2: Product comparison
-- Goal: Products above average price in their category
-- ✅ RECOMMENDED: Correlated subquery
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.CategoryID = p1.CategoryID) AS CategoryAvg
FROM Products p1
WHERE Price > (
    SELECT AVG(Price) 
    FROM Products p2 
    WHERE p2.CategoryID = p1.CategoryID
);

-- Alternative: CTE for readability
WITH CategoryAverages AS (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
)
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    p.Price,
    ca.AvgPrice AS CategoryAvg
FROM Products p
JOIN CategoryAverages ca ON p.CategoryID = ca.CategoryID
WHERE p.Price > ca.AvgPrice;

-- Example 7.3: Order analysis
-- Goal: Orders with above-average item count
-- ✅ RECOMMENDED: CTE
WITH OrderItemCounts AS (
    SELECT OrderID, COUNT(*) AS ItemCount
    FROM OrderDetails
    GROUP BY OrderID
),
AvgItemCount AS (
    SELECT AVG(CAST(ItemCount AS FLOAT)) AS Avg
    FROM OrderItemCounts
)
SELECT 
    o.OrderID,
    o.OrderDate,
    oic.ItemCount
FROM Orders o
JOIN OrderItemCounts oic ON o.OrderID = oic.OrderID
CROSS JOIN AvgItemCount aic
WHERE oic.ItemCount > aic.Avg;

-- Example 7.4: Find gaps
-- Goal: Products never ordered
-- ✅ RECOMMENDED: NOT EXISTS subquery
SELECT ProductID, ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);


/*
============================================================================
PART 8: Common Mistakes to Avoid
============================================================================
*/

-- Mistake 8.1: ❌ Using IN with NULL values
-- Problem: NULL in subquery breaks IN
-- Bad:
SELECT * FROM Products
WHERE CategoryID IN (SELECT CategoryID FROM Categories); -- Can miss NULLs

-- Good:
SELECT * FROM Products
WHERE EXISTS (
    SELECT 1 FROM Categories WHERE CategoryID = Products.CategoryID
);

-- Mistake 8.2: ❌ Correlated subquery in SELECT with large tables
-- Slow:
SELECT 
    CustomerID,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;

-- Fast:
SELECT 
    c.CustomerID,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID;

-- Mistake 8.3: ❌ Multiple identical subqueries
-- Inefficient:
SELECT ProductName,
    Price - (SELECT AVG(Price) FROM Products),
    Price / (SELECT AVG(Price) FROM Products) * 100
FROM Products;

-- Efficient:
WITH AvgPrice AS (SELECT AVG(Price) AS Avg FROM Products)
SELECT 
    ProductName,
    Price - Avg,
    Price / Avg * 100
FROM Products CROSS JOIN AvgPrice;

-- Mistake 8.4: ❌ Using subquery when CASE would work
-- Overcomplicated:
SELECT 
    ProductName,
    (SELECT 'High' WHERE Price > 100
     UNION ALL
     SELECT 'Low' WHERE Price <= 100) AS PriceCategory
FROM Products;

-- Simple:
SELECT 
    ProductName,
    CASE WHEN Price > 100 THEN 'High' ELSE 'Low' END AS PriceCategory
FROM Products;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

For each scenario, choose the best approach and explain why:

1. Get all customers and their total order counts (including 0)
2. Find products that cost more than the average in their category
3. List orders where item count exceeds the overall average
4. Find customers who have never placed an order
5. Calculate each product's price as a percentage of category average

Solutions and recommendations below ↓
*/

-- Solution 1: JOIN (need customer columns + aggregation)
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Solution 2: Correlated subquery (row-by-row comparison)
SELECT ProductID, ProductName, Price
FROM Products p
WHERE Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
);

-- Solution 3: CTE (complex calculation, reusability)
WITH OrderCounts AS (
    SELECT OrderID, COUNT(*) AS Items
    FROM OrderDetails
    GROUP BY OrderID
),
AvgCount AS (
    SELECT AVG(CAST(Items AS FLOAT)) AS Avg FROM OrderCounts
)
SELECT o.OrderID, o.OrderDate, oc.Items
FROM Orders o
JOIN OrderCounts oc ON o.OrderID = oc.OrderID
CROSS JOIN AvgCount ac
WHERE oc.Items > ac.Avg;

-- Solution 4: NOT EXISTS subquery (checking non-existence)
SELECT CustomerID, CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID
);

-- Solution 5: JOIN with subquery (efficient calculation)
WITH CategoryAvg AS (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
)
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    (p.Price / ca.AvgPrice) * 100 AS PctOfCategoryAvg
FROM Products p
JOIN CategoryAvg ca ON p.CategoryID = ca.CategoryID;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ USE SUBQUERIES FOR:
  • Single scalar values
  • Existence checks (EXISTS)
  • Simple filtering (IN, ANY, ALL)
  • Clear intent on simple queries
  • Quick ad-hoc analysis

✓ USE JOINS FOR:
  • Multiple table columns
  • Aggregations across tables
  • Large datasets (performance)
  • Many-to-many relationships
  • Production queries

✓ USE CTEs FOR:
  • Complex nested logic
  • Reused calculations
  • Improved readability
  • Recursive queries
  • Temporary result sets

✓ PERFORMANCE RULES:
  • JOIN usually faster than correlated subquery
  • EXISTS faster than IN for large datasets
  • CTEs avoid repeated calculations
  • Consider indexes on join/subquery columns

✓ READABILITY WINS:
  • Clear code > clever code
  • Consistent patterns
  • Comments for complex logic
  • Think about maintenance

✓ DECISION PROCESS:
  1. What columns do I need? (JOIN if multiple tables)
  2. Is it existence check? (EXISTS/NOT EXISTS)
  3. Is it complex? (Consider CTE)
  4. What's clearest? (Favor readability)
  5. What's fastest? (Profile if unsure)

✓ BEST PRACTICES:
  • Test both approaches if unsure
  • Use STATISTICS IO/TIME
  • Consider team conventions
  • Document your reasoning
  • Optimize only when needed

============================================================================
NEXT: Lesson 09.10 - Subqueries as Data Sources
Learn to use derived tables and inline views.
============================================================================
*/
