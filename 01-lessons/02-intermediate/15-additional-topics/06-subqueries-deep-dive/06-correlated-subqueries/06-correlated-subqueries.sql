/*
============================================================================
Lesson 09.06 - Correlated Subqueries
============================================================================

Description:
Master correlated subqueries that reference the outer query and execute
once per row. Understand when to use them and their performance implications.

Topics Covered:
• What makes a subquery correlated
• Execution model (row-by-row)
• Common patterns and use cases
• Performance considerations
• Correlated vs noncorrelated comparison

Prerequisites:
• Lessons 09.01-09.05

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Correlated Subqueries
============================================================================
*/

-- Definition:
-- CORRELATED SUBQUERY = Subquery that REFERENCES the outer query
-- • Executes ONCE PER ROW of outer query
-- • Depends on values from outer query
-- • Cannot run independently

-- Example 1.1: Basic correlated subquery
SELECT p1.ProductName, p1.Price, p1.CategoryID
FROM Products p1
WHERE p1.Price > (
    SELECT AVG(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID  -- ← References outer query!
);
-- Products priced above their category average

/*
Execution Flow:
For EACH product in p1:
  1. Take that product's CategoryID
  2. Run subquery to get AVG price for that category
  3. Compare product's price to that average
  4. Include row if condition true

If 1000 products exist, subquery runs 1000 times!
*/

-- Example 1.2: Noncorrelated comparison (for contrast)
SELECT p1.ProductName, p1.Price
FROM Products p1
WHERE p1.Price > (
    SELECT AVG(Price)
    FROM Products  -- No reference to p1!
);
-- Subquery runs ONCE, not once per row


/*
============================================================================
PART 2: Correlated Subquery Patterns
============================================================================
*/

-- Pattern 2.1: Compare to group aggregate
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
);
-- Above category average

-- Pattern 2.2: Count related records
SELECT 
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;
-- Order count per customer (correlated in SELECT clause)

-- Pattern 2.3: Get related value
SELECT 
    p.ProductName,
    p.Price,
    (SELECT CategoryName FROM Categories WHERE CategoryID = p.CategoryID) AS CategoryName
FROM Products p;
-- Better done with JOIN, but demonstrates correlation

-- Pattern 2.4: Find maximum related value
SELECT 
    c.CustomerName,
    (SELECT MAX(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS LargestOrder
FROM Customers c;


/*
============================================================================
PART 3: Correlated Subquery in WHERE Clause
============================================================================
*/

-- Example 3.1: Above average within group
SELECT ProductName, Price, Stock, CategoryID
FROM Products p1
WHERE Stock > (
    SELECT AVG(Stock)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
);
-- Products with above-average stock in their category

-- Example 3.2: Comparing to related records
SELECT o1.OrderID, o1.CustomerID, o1.TotalAmount, o1.OrderDate
FROM Orders o1
WHERE o1.TotalAmount > (
    SELECT AVG(o2.TotalAmount)
    FROM Orders o2
    WHERE o2.CustomerID = o1.CustomerID
      AND o2.OrderID <> o1.OrderID  -- Exclude current order
);
-- Orders above customer's own average

-- Example 3.3: Multiple correlations
SELECT p.ProductName, p.Price, p.Stock
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
)
AND p.Stock < (
    SELECT AVG(Stock)
    FROM Products
    WHERE CategoryID = p.CategoryID
);
-- Expensive but low-stock within category

-- Example 3.4: Nested correlation
SELECT p1.ProductName, p1.Price
FROM Products p1
WHERE p1.Price > (
    SELECT AVG(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
    AND p2.Price < (
        SELECT MAX(Price)
        FROM Products p3
        WHERE p3.CategoryID = p2.CategoryID
    )
);


/*
============================================================================
PART 4: Correlated Subquery in SELECT Clause
============================================================================
*/

-- Example 4.1: Single related value
SELECT 
    c.CustomerName,
    c.Country,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c;

-- Example 4.2: Multiple correlated columns
SELECT 
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS Orders,
    (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalSpent,
    (SELECT MAX(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS LargestOrder,
    (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID) AS LastOrderDate
FROM Customers c;

-- Example 4.3: ⚠️ Performance warning
-- Each subquery runs for EVERY customer!
-- With 100 customers and 4 subqueries = 400 subquery executions!

-- ✅ Better alternative: Use JOIN and GROUP BY
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) AS Orders,
    SUM(o.TotalAmount) AS TotalSpent,
    MAX(o.TotalAmount) AS LargestOrder,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;


/*
============================================================================
PART 5: Common Use Cases
============================================================================
*/

-- Use Case 5.1: Rank within group
SELECT 
    p.ProductName,
    p.Price,
    p.CategoryID,
    (SELECT COUNT(*) 
     FROM Products p2 
     WHERE p2.CategoryID = p.CategoryID 
     AND p2.Price > p.Price) + 1 AS PriceRank
FROM Products p
ORDER BY CategoryID, PriceRank;
-- Rank products by price within category

-- Use Case 5.2: Latest record per group
SELECT o1.OrderID, o1.CustomerID, o1.OrderDate, o1.TotalAmount
FROM Orders o1
WHERE o1.OrderDate = (
    SELECT MAX(o2.OrderDate)
    FROM Orders o2
    WHERE o2.CustomerID = o1.CustomerID
);
-- Most recent order for each customer

-- Use Case 5.3: Compare to peers
SELECT 
    p.ProductName,
    p.Price,
    (SELECT AVG(Price) FROM Products WHERE CategoryID = p.CategoryID) AS CategoryAvg,
    p.Price - (SELECT AVG(Price) FROM Products WHERE CategoryID = p.CategoryID) AS Difference
FROM Products p;

-- Use Case 5.4: Find records with no related records
SELECT c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
-- Customers with no orders (EXISTS is correlated!)


/*
============================================================================
PART 6: Performance Considerations
============================================================================
*/

-- Performance 6.1: Execution count matters
/*
Noncorrelated: Runs ONCE
Correlated: Runs ONCE PER OUTER ROW

Outer table has 1000 rows → Correlated subquery runs 1000 times!
*/

-- Performance 6.2: ❌ Slow example
SELECT 
    ProductName,
    (SELECT COUNT(*) FROM Orders o 
     JOIN OrderDetails od ON o.OrderID = od.OrderID 
     WHERE od.ProductID = p.ProductID) AS TimesSold
FROM Products p;  -- If 5000 products, subquery runs 5000 times!

-- ✅ Faster: JOIN and GROUP BY
SELECT 
    p.ProductName,
    COUNT(od.OrderDetailID) AS TimesSold
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName;

-- Performance 6.3: ✅ When correlated is OK
-- Small outer table (few rows)
SELECT 
    c.CategoryName,
    (SELECT AVG(Price) FROM Products WHERE CategoryID = c.CategoryID) AS AvgPrice
FROM Categories c;  -- Only 10-20 categories, acceptable

-- Performance 6.4: ⚠️ Nested correlated subqueries (very slow!)
SELECT p1.ProductName
FROM Products p1
WHERE p1.Price > (
    SELECT AVG(p2.Price)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
    AND p2.Stock > (
        SELECT AVG(Stock)
        FROM Products p3
        WHERE p3.CategoryID = p2.CategoryID
    )
);
-- Multiple levels of correlation = exponential slowdown!


/*
============================================================================
PART 7: Correlated vs Noncorrelated Comparison
============================================================================
*/

-- Comparison 7.1: Same result, different approaches

-- A) CORRELATED approach:
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
);

-- B) NONCORRELATED approach with JOIN:
SELECT p.ProductName, p.Price, p.CategoryID
FROM Products p
JOIN (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
) CategoryAvgs ON p.CategoryID = CategoryAvgs.CategoryID
WHERE p.Price > CategoryAvgs.AvgPrice;

-- B is usually faster!

-- Comparison 7.2: When each is appropriate
/*
NONCORRELATED:
  ✅ Generally faster
  ✅ Runs once
  ✅ Can be rewritten as JOIN
  ✅ Preferred for large datasets

CORRELATED:
  ✅ Sometimes more readable
  ✅ Useful for EXISTS/NOT EXISTS
  ✅ OK for small outer tables
  ✅ Necessary for some complex logic
*/


/*
============================================================================
PART 8: Advanced Patterns
============================================================================
*/

-- Pattern 8.1: Running totals (before window functions)
SELECT 
    o1.OrderID,
    o1.OrderDate,
    o1.TotalAmount,
    (SELECT SUM(o2.TotalAmount)
     FROM Orders o2
     WHERE o2.CustomerID = o1.CustomerID
     AND o2.OrderDate <= o1.OrderDate) AS RunningTotal
FROM Orders o1
ORDER BY o1.CustomerID, o1.OrderDate;

-- ✅ Modern alternative: Window function
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    SUM(TotalAmount) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
    ) AS RunningTotal
FROM Orders;

-- Pattern 8.2: Top N per group
SELECT p1.ProductName, p1.Price, p1.CategoryID
FROM Products p1
WHERE (
    SELECT COUNT(*)
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
    AND p2.Price > p1.Price
) < 3
ORDER BY CategoryID, Price DESC;
-- Top 3 most expensive products per category

-- ✅ Modern alternative: ROW_NUMBER()
SELECT ProductName, Price, CategoryID
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY Price DESC) AS rn
    FROM Products
) Ranked
WHERE rn <= 3;

-- Pattern 8.3: Self-exclusion comparison
SELECT p1.ProductName, p1.Price
FROM Products p1
WHERE p1.Price > ALL (
    SELECT p2.Price
    FROM Products p2
    WHERE p2.CategoryID = p1.CategoryID
    AND p2.ProductID <> p1.ProductID  -- Exclude self
);
-- Most expensive product in each category


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find products priced above their category average
2. Show customers with their order count (correlated SELECT)
3. Find orders above customer's average (excluding current order)
4. Get products with above-average stock in their category
5. Compare correlated vs JOIN approach for same result

Solutions below ↓
*/

-- Solution 1:
SELECT ProductName, Price, CategoryID
FROM Products p
WHERE Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
);

-- Solution 2:
SELECT 
    CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount
FROM Customers c
ORDER BY OrderCount DESC;

-- Solution 3:
SELECT OrderID, CustomerID, TotalAmount, OrderDate
FROM Orders o1
WHERE TotalAmount > (
    SELECT AVG(TotalAmount)
    FROM Orders o2
    WHERE o2.CustomerID = o1.CustomerID
    AND o2.OrderID <> o1.OrderID
);

-- Solution 4:
SELECT ProductName, Stock, CategoryID
FROM Products p
WHERE Stock > (
    SELECT AVG(Stock)
    FROM Products
    WHERE CategoryID = p.CategoryID AND Stock IS NOT NULL
);

-- Solution 5:
-- A) Correlated:
SELECT p.ProductName, p.Price
FROM Products p
WHERE p.Price > (
    SELECT AVG(Price)
    FROM Products
    WHERE CategoryID = p.CategoryID
);

-- B) JOIN (usually faster):
SELECT p.ProductName, p.Price
FROM Products p
JOIN (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
) Avgs ON p.CategoryID = Avgs.CategoryID
WHERE p.Price > Avgs.AvgPrice;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CORRELATED DEFINITION:
  • References outer query
  • Executes once per outer row
  • Depends on outer query values
  • Cannot run independently

✓ EXECUTION MODEL:
  • For each row in outer query:
    - Pass values to subquery
    - Execute subquery with those values
    - Use result for comparison
  • Performance = Outer rows × Subquery cost

✓ COMMON LOCATIONS:
  • WHERE clause (filtering)
  • SELECT clause (calculated columns)
  • HAVING clause (group filtering)

✓ USE CASES:
  • Compare to group aggregate
  • Count related records
  • Find latest/max related value
  • Row-by-row comparisons

✓ PERFORMANCE:
  • ⚠️ Can be slow with large outer tables
  • ✅ OK for small outer tables
  • ✅ Consider JOIN alternative
  • ✅ Use window functions when possible

✓ ALTERNATIVES:
  • JOIN with GROUP BY (faster)
  • Window functions (modern)
  • Derived tables
  • CTEs for readability

✓ WHEN TO USE:
  • Small outer table
  • EXISTS/NOT EXISTS checks
  • Complex row-level logic
  • When readability matters more than speed

✓ WHEN TO AVOID:
  • Large outer tables
  • Multiple correlated subqueries in SELECT
  • Nested correlated subqueries
  • When JOIN works equally well

============================================================================
NEXT: Lesson 09.07 - EXISTS Operator
Master the EXISTS operator for efficient existence checking.
============================================================================
*/
