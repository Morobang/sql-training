/*
============================================================================
Lesson 09.07 - EXISTS Operator
============================================================================

Description:
Master the EXISTS and NOT EXISTS operators for efficient existence checking.
Learn when to use EXISTS instead of IN and understand performance benefits.

Topics Covered:
• EXISTS operator fundamentals
• NOT EXISTS for non-existence
• EXISTS vs IN comparison
• Performance advantages
• Common patterns and use cases

Prerequisites:
• Lessons 09.01-09.06

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding EXISTS
============================================================================
*/

-- Definition:
-- EXISTS = Returns TRUE if subquery returns ANY rows
-- Returns FALSE if subquery returns zero rows
-- Does NOT care about actual data, only whether rows exist

-- Example 1.1: Basic EXISTS
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1  -- Can be SELECT *, SELECT 1, SELECT NULL - doesn't matter!
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
-- Customers who have placed at least one order

/*
How EXISTS works:
1. For each customer in outer query
2. Run subquery with that CustomerID
3. If subquery returns ANY rows → EXISTS is TRUE → include customer
4. If subquery returns NO rows → EXISTS is FALSE → exclude customer

EXISTS stops searching as soon as it finds ONE row! (Efficient)
*/

-- Example 1.2: SELECT 1 vs SELECT *
-- These are IDENTICAL in functionality:
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)
WHERE EXISTS (SELECT * FROM Orders WHERE CustomerID = c.CustomerID)
WHERE EXISTS (SELECT 'X' FROM Orders WHERE CustomerID = c.CustomerID)
WHERE EXISTS (SELECT NULL FROM Orders WHERE CustomerID = c.CustomerID)

-- Convention: Use SELECT 1 (clearest intent)

-- Example 1.3: EXISTS is always correlated
-- EXISTS subquery almost always references outer query
SELECT ProductName
FROM Products p
WHERE EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID  -- ← Correlation
);
-- Products that have been ordered


/*
============================================================================
PART 2: NOT EXISTS
============================================================================
*/

-- Example 2.1: Basic NOT EXISTS
SELECT c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);
-- Customers who have NEVER ordered

-- Example 2.2: NOT EXISTS vs NOT IN
-- NOT EXISTS is SAFER with NULL values!

CREATE TABLE #TestCustomers (CustomerID INT);
INSERT INTO #TestCustomers VALUES (1), (2), (3);

CREATE TABLE #TestOrders (CustomerID INT);
INSERT INTO #TestOrders VALUES (1), (NULL);

-- ❌ NOT IN returns NO rows (NULL problem!):
SELECT CustomerID FROM #TestCustomers
WHERE CustomerID NOT IN (SELECT CustomerID FROM #TestOrders);
-- Returns 0 rows!

-- ✅ NOT EXISTS returns correct result:
SELECT c.CustomerID FROM #TestCustomers c
WHERE NOT EXISTS (
    SELECT 1 FROM #TestOrders o WHERE o.CustomerID = c.CustomerID
);
-- Returns 2, 3 (correct!)

DROP TABLE #TestCustomers, #TestOrders;

-- Example 2.3: Finding gaps/missing records
SELECT c.CategoryName
FROM Categories c
WHERE NOT EXISTS (
    SELECT 1
    FROM Products p
    WHERE p.CategoryID = c.CategoryID
);
-- Categories with no products


/*
============================================================================
PART 3: EXISTS vs IN Performance
============================================================================
*/

-- Performance 3.1: ✅ EXISTS stops at first match
WHERE EXISTS (
    SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID
)
-- As soon as one order found → stops searching, returns TRUE

-- Performance 3.2: IN must retrieve all values
WHERE CustomerID IN (
    SELECT CustomerID FROM Orders
)
-- Must get ALL CustomerIDs, then check membership

-- Performance 3.3: Benchmark example
/*
Table sizes:
- Customers: 10,000 rows
- Orders: 1,000,000 rows (avg 100 orders per customer)

EXISTS:
  For each customer, check if ANY order exists
  First order found → stop
  Avg checks: 1-2 per customer

IN:
  Get all 1,000,000 CustomerIDs from Orders (with duplicates removed)
  Then check each customer against that list
  
EXISTS is typically faster for large datasets!
*/

-- Performance 3.4: When IN might be faster
-- IN can be faster if subquery returns very few distinct values
WHERE CategoryID IN (1, 2, 3)  -- Just 3 values
-- vs
WHERE EXISTS (SELECT 1 FROM Categories WHERE CategoryID = p.CategoryID AND CategoryID IN (1,2,3))
-- IN is simpler here


/*
============================================================================
PART 4: Common Patterns
============================================================================
*/

-- Pattern 4.1: Has related records
SELECT p.ProductName
FROM Products p
WHERE EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);
-- Products that have been sold

-- Pattern 4.2: Has NO related records
SELECT p.ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);
-- Products never sold

-- Pattern 4.3: Exists with additional conditions
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    AND o.TotalAmount > 1000
);
-- Customers with at least one large order

-- Pattern 4.4: Multiple EXISTS conditions
SELECT p.ProductName
FROM Products p
WHERE EXISTS (
    SELECT 1 FROM OrderDetails WHERE ProductID = p.ProductID
)
AND NOT EXISTS (
    SELECT 1 FROM DiscontinuedProducts WHERE ProductID = p.ProductID
);
-- Products that are sold and not discontinued

-- Pattern 4.5: EXISTS in SELECT clause (less common)
SELECT 
    c.CustomerName,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)
        THEN 'Has Orders'
        ELSE 'No Orders'
    END AS Status
FROM Customers c;


/*
============================================================================
PART 5: Advanced EXISTS Patterns
============================================================================
*/

-- Pattern 5.1: Double negation (set difference)
SELECT p.ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM Categories c
    WHERE c.CategoryType = 'Premium'
    AND NOT EXISTS (
        SELECT 1
        FROM Products p2
        WHERE p2.CategoryID = c.CategoryID
        AND p2.ProductID = p.ProductID
    )
);

-- Pattern 5.2: For all (universal quantification)
-- Find customers who ordered ALL premium products
SELECT c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Products p
    WHERE p.Premium = 1
    AND NOT EXISTS (
        SELECT 1
        FROM Orders o
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        WHERE o.CustomerID = c.CustomerID
        AND od.ProductID = p.ProductID
    )
);
-- Read as: "No premium product exists that this customer hasn't ordered"

-- Pattern 5.3: Existence in date range
SELECT o1.OrderID, o1.OrderDate
FROM Orders o1
WHERE EXISTS (
    SELECT 1
    FROM Orders o2
    WHERE o2.CustomerID = o1.CustomerID
    AND o2.OrderDate < o1.OrderDate
    AND DATEDIFF(DAY, o2.OrderDate, o1.OrderDate) <= 30
);
-- Orders placed within 30 days of a previous order by same customer


/*
============================================================================
PART 6: EXISTS vs JOIN
============================================================================
*/

-- Comparison 6.1: Same result, different approaches

-- A) Using EXISTS:
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);

-- B) Using JOIN with DISTINCT:
SELECT DISTINCT c.CustomerName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID;

-- C) Using JOIN with GROUP BY:
SELECT c.CustomerName
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Comparison 6.2: When to use each
/*
EXISTS:
  ✅ Only checking existence (don't need order data)
  ✅ Cleaner for "has related records"
  ✅ Better performance for large related tables
  ✅ Safer with NULL values

JOIN:
  ✅ Need columns from related table
  ✅ Need to count/aggregate related records
  ✅ More familiar to some developers
*/

-- Comparison 6.3: Performance difference
-- Customers with orders:

-- EXISTS (fast - stops at first match):
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)

-- JOIN (slower - retrieves all matches, then DISTINCT):
FROM Customers c JOIN Orders o ON c.CustomerID = o.CustomerID
-- Then needs DISTINCT to remove duplicates


/*
============================================================================
PART 7: Real-World Scenarios
============================================================================
*/

-- Scenario 7.1: Active customers (ordered in last 90 days)
SELECT CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    AND o.OrderDate >= DATEADD(DAY, -90, GETDATE())
);

-- Scenario 7.2: Products in stock but never sold
SELECT ProductName, Stock
FROM Products p
WHERE Stock > 0
AND NOT EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);

-- Scenario 7.3: Customers who bought product A but not product B
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
    AND od.ProductID = 1  -- Product A
)
AND NOT EXISTS (
    SELECT 1
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
    AND od.ProductID = 2  -- Product B
);

-- Scenario 7.4: Categories with active products
SELECT c.CategoryName
FROM Categories c
WHERE EXISTS (
    SELECT 1
    FROM Products p
    WHERE p.CategoryID = c.CategoryID
    AND p.Active = 1
    AND p.Stock > 0
);

-- Scenario 7.5: Find duplicate email addresses
SELECT c1.CustomerName, c1.Email
FROM Customers c1
WHERE EXISTS (
    SELECT 1
    FROM Customers c2
    WHERE c2.Email = c1.Email
    AND c2.CustomerID <> c1.CustomerID
);


/*
============================================================================
PART 8: Best Practices
============================================================================
*/

-- Best Practice 8.1: ✅ Always use SELECT 1
WHERE EXISTS (SELECT 1 FROM ...)  -- Clear intent, conventional

-- Best Practice 8.2: ✅ Use NOT EXISTS instead of NOT IN when possible
-- Safer with NULL, often faster

-- Best Practice 8.3: ✅ Keep EXISTS subquery simple
-- Just enough to check existence
WHERE EXISTS (
    SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID
)
-- Don't SELECT unnecessary columns

-- Best Practice 8.4: ✅ Add indexes to support EXISTS
-- CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
-- Helps EXISTS find matching rows quickly

-- Best Practice 8.5: ✅ Use EXISTS for existence, JOIN when you need data
-- EXISTS:
WHERE EXISTS (SELECT 1 FROM Orders WHERE CustomerID = c.CustomerID)

-- JOIN (when you need order data):
SELECT c.CustomerName, o.OrderDate, o.TotalAmount
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find products that have been ordered
2. Find customers who have never placed an order
3. Find products in categories that have active products
4. Customers with orders over $500
5. Products sold but currently out of stock

Solutions below ↓
*/

-- Solution 1:
SELECT ProductName, ProductID
FROM Products p
WHERE EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);

-- Solution 2:
SELECT CustomerID, CustomerName, Email
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
);

-- Solution 3:
SELECT p.ProductName, p.CategoryID
FROM Products p
WHERE EXISTS (
    SELECT 1
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
    AND p2.Active = 1
);

-- Solution 4:
SELECT c.CustomerName, c.CustomerID
FROM Customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    AND o.TotalAmount > 500
);

-- Solution 5:
SELECT ProductName, Stock
FROM Products p
WHERE Stock = 0
AND EXISTS (
    SELECT 1
    FROM OrderDetails od
    WHERE od.ProductID = p.ProductID
);


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ EXISTS FUNDAMENTALS:
  • Returns TRUE if subquery has ANY rows
  • Returns FALSE if subquery has ZERO rows
  • Doesn't care about actual data values
  • Stops at first matching row (efficient!)

✓ NOT EXISTS:
  • Returns TRUE if NO rows found
  • Safer than NOT IN (NULL handling)
  • Perfect for "never" queries
  • Gap analysis and missing records

✓ SELECT 1 CONVENTION:
  • Use SELECT 1 (clearest)
  • SELECT * also works (not needed)
  • Only existence matters, not data

✓ PERFORMANCE:
  • ✅ Very efficient (stops at first match)
  • ✅ Usually faster than IN for large sets
  • ✅ No duplicate elimination needed
  • ✅ Works well with indexes

✓ EXISTS vs IN:
  • EXISTS: Checks existence only
  • IN: Retrieves all values, then checks
  • EXISTS safer with NULL
  • EXISTS stops early (faster)

✓ EXISTS vs JOIN:
  • EXISTS: Just checking existence
  • JOIN: Need related table columns
  • EXISTS cleaner for simple checks
  • JOIN when you need data

✓ COMMON PATTERNS:
  • Has related records: EXISTS
  • Has NO related records: NOT EXISTS
  • With conditions: EXISTS + WHERE
  • Multiple checks: Multiple EXISTS
  • Set difference: NOT EXISTS + NOT EXISTS

✓ BEST PRACTICES:
  • Use SELECT 1 for clarity
  • Prefer NOT EXISTS over NOT IN
  • Index correlation columns
  • Keep subquery simple
  • Use for existence, JOIN for data

============================================================================
NEXT: Lesson 09.08 - Data Manipulation with Subqueries
Learn to use subqueries in INSERT, UPDATE, and DELETE statements.
============================================================================
*/
