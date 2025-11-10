/*
============================================================================
Lesson 10.09 - Semi-Joins and Anti-Joins
============================================================================

Description:
Master semi-joins (EXISTS, IN) and anti-joins (NOT EXISTS, NOT IN) for
efficient existence and non-existence checks. Learn when to use each
pattern and understand performance implications.

Topics Covered:
• Semi-join concept and syntax
• Anti-join concept and syntax
• EXISTS vs IN
• NOT EXISTS vs NOT IN
• Performance comparisons
• Real-world applications

Prerequisites:
• Lessons 10.01-10.08
• Understanding of subqueries

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Semi-Join Fundamentals
============================================================================
*/

/*
SEMI-JOIN Definition:
Returns rows from the LEFT table where a match exists in the RIGHT table.
Does NOT return columns from the right table.
Stops searching after first match (efficient).
*/

-- Example 1.1: Semi-join with EXISTS
-- Find customers who have placed orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);

/*
Execution Flow:
1. Scan Customers table
2. For each customer, check if order exists
3. Stop at first matching order (doesn't count all)
4. Return customer if match found
*/

-- Example 1.2: Semi-join with IN
-- Same result, different syntax
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE c.CustomerID IN (
    SELECT o.CustomerID 
    FROM Orders o
);

-- Example 1.3: Semi-join with additional conditions
-- Customers with orders over $500
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND o.TotalAmount > 500
);

-- Example 1.4: Multiple semi-join conditions
-- Customers with orders AND order details
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
)
AND EXISTS (
    SELECT 1 
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
);


/*
============================================================================
PART 2: Anti-Join Fundamentals
============================================================================
*/

/*
ANTI-JOIN Definition:
Returns rows from the LEFT table where NO match exists in the RIGHT table.
Finds missing relationships.
Identifies orphaned records.
*/

-- Example 2.1: Anti-join with NOT EXISTS
-- Find customers who have NEVER ordered
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.Country
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);

-- Example 2.2: Anti-join with NOT IN
-- Same result, different syntax
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE c.CustomerID NOT IN (
    SELECT o.CustomerID 
    FROM Orders o
    WHERE o.CustomerID IS NOT NULL  -- ⚠️ Critical for NOT IN!
);

-- Example 2.3: ⚠️ NOT IN with NULLs - DANGER!
-- This returns NO rows if subquery contains NULL
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE c.CustomerID NOT IN (
    SELECT o.CustomerID 
    FROM Orders o  -- If any NULL, entire query returns nothing!
);

-- Example 2.4: NOT EXISTS is NULL-safe
-- This works correctly even with NULLs
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);


/*
============================================================================
PART 3: EXISTS vs IN - When to Use Each
============================================================================
*/

-- Scenario 3.1: EXISTS - Better for correlated conditions
-- Find customers with large orders
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID  -- Correlated
      AND o.TotalAmount > 1000
);

-- Scenario 3.2: IN - Better for fixed lists
-- Find customers in specific IDs
SELECT c.CustomerName
FROM Customers c
WHERE c.CustomerID IN (1, 5, 10, 15);

-- Scenario 3.3: EXISTS - Better for multiple conditions
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND o.OrderDate >= '2024-01-01'
      AND o.TotalAmount > 500
);

-- Scenario 3.4: Performance comparison
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Using EXISTS:
SELECT COUNT(*)
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);

-- Using IN:
SELECT COUNT(*)
FROM Customers c
WHERE c.CustomerID IN (
    SELECT CustomerID 
    FROM Orders
);

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*
============================================================================
PART 4: NOT EXISTS vs NOT IN - Critical Differences
============================================================================
*/

-- Example 4.1: ✅ NOT EXISTS - Always safe
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM OrderDetails od 
    WHERE od.ProductID = p.ProductID
);
-- Returns products never ordered

-- Example 4.2: ⚠️ NOT IN - Dangerous with NULLs
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price
FROM Products p
WHERE p.ProductID NOT IN (
    SELECT ProductID 
    FROM OrderDetails
    WHERE ProductID IS NOT NULL  -- Must exclude NULLs!
);

-- Example 4.3: Why NOT IN fails with NULLs
/*
Conceptual explanation:

If subquery returns: (1, 2, NULL)
WHERE ProductID NOT IN (1, 2, NULL)

Expands to:
WHERE ProductID <> 1 
  AND ProductID <> 2 
  AND ProductID <> NULL  -- Always UNKNOWN!

Result: Nothing returned (UNKNOWN treated as FALSE)
*/

-- Example 4.4: The fix - Always filter NULLs in NOT IN
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE c.CustomerID NOT IN (
    SELECT CustomerID 
    FROM Orders
    WHERE CustomerID IS NOT NULL  -- Critical!
);


/*
============================================================================
PART 5: Real-World Applications
============================================================================
*/

-- Application 5.1: Find inactive customers
-- Customers with no orders in last 6 months
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
);

-- Application 5.2: Products without inventory
-- (Conceptual - would need Inventory table)
/*
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Inventory i 
    WHERE i.ProductID = p.ProductID
      AND i.Quantity > 0
);
*/

-- Application 5.3: Customers who bought Product A but not Product B
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    -- Bought Product 1
    SELECT 1 
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
      AND od.ProductID = 1
)
AND NOT EXISTS (
    -- Did NOT buy Product 2
    SELECT 1 
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
      AND od.ProductID = 2
);

-- Application 5.4: Find gaps in sequences
-- Order IDs with no details
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
WHERE NOT EXISTS (
    SELECT 1 
    FROM OrderDetails od 
    WHERE od.OrderID = o.OrderID
);

-- Application 5.5: Customers in all regions
-- Customers who ordered from every category
WITH CategoryCount AS (
    SELECT COUNT(DISTINCT CategoryID) AS TotalCategories
    FROM Categories
)
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
CROSS JOIN CategoryCount cc
WHERE NOT EXISTS (
    -- Find a category they DIDN'T order from
    SELECT 1 
    FROM Categories cat
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Orders o
        INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
        INNER JOIN Products p ON od.ProductID = p.ProductID
        WHERE o.CustomerID = c.CustomerID
          AND p.CategoryID = cat.CategoryID
    )
);


/*
============================================================================
PART 6: Advanced Patterns
============================================================================
*/

-- Pattern 6.1: Double negative for "all"
-- Customers who ordered ALL products in category 1
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    -- Find a product in category 1 they didn't order
    SELECT 1 
    FROM Products p
    WHERE p.CategoryID = 1
      AND NOT EXISTS (
        SELECT 1 
        FROM Orders o
        INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
        WHERE o.CustomerID = c.CustomerID
          AND od.ProductID = p.ProductID
    )
);

-- Pattern 6.2: Existence with aggregation
-- Customers with more than 5 orders
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
    HAVING COUNT(*) > 5
);

-- Pattern 6.3: Multiple anti-joins
-- Products never ordered AND never reviewed (conceptual)
SELECT 
    p.ProductID,
    p.ProductName
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID
)
AND NOT EXISTS (
    SELECT 1 FROM Reviews r WHERE r.ProductID = p.ProductID
);

-- Pattern 6.4: Complex conditions in semi-join
-- Customers with consecutive day orders
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o1
    INNER JOIN Orders o2 
        ON o1.CustomerID = o2.CustomerID
        AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) = 1
    WHERE o1.CustomerID = c.CustomerID
);


/*
============================================================================
PART 7: Performance Optimization
============================================================================
*/

-- Optimization 7.1: ✅ SELECT 1 vs SELECT *
-- Both work the same, but SELECT 1 is clearer
SELECT c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1   -- Clear intent: just checking existence
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);

-- Optimization 7.2: ✅ Early termination
-- EXISTS stops at first match
SET STATISTICS IO ON;

SELECT COUNT(*)
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);
-- Stops after finding first order per customer

SET STATISTICS IO OFF;

-- Optimization 7.3: ⚠️ Avoid NOT IN with subquery
-- Slow (especially with NULLs):
SELECT c.CustomerName
FROM Customers c
WHERE c.CustomerID NOT IN (
    SELECT CustomerID FROM Orders WHERE CustomerID IS NOT NULL
);

-- Faster:
SELECT c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);

-- Optimization 7.4: ✅ Index supporting columns
-- Ensure foreign key columns are indexed
/*
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);
*/


/*
============================================================================
PART 8: Common Patterns Summary
============================================================================
*/

-- Pattern 8.1: Has relationship
SELECT * FROM TableA a
WHERE EXISTS (
    SELECT 1 FROM TableB b WHERE b.FK = a.PK
);

-- Pattern 8.2: Lacks relationship
SELECT * FROM TableA a
WHERE NOT EXISTS (
    SELECT 1 FROM TableB b WHERE b.FK = a.PK
);

-- Pattern 8.3: Has relationship with condition
SELECT * FROM TableA a
WHERE EXISTS (
    SELECT 1 
    FROM TableB b 
    WHERE b.FK = a.PK AND b.Status = 'Active'
);

-- Pattern 8.4: Has A but not B
SELECT * FROM TableA a
WHERE EXISTS (
    SELECT 1 FROM TableB b WHERE b.FK = a.PK
)
AND NOT EXISTS (
    SELECT 1 FROM TableC c WHERE c.FK = a.PK
);

-- Pattern 8.5: Has all (double negative)
SELECT * FROM TableA a
WHERE NOT EXISTS (
    SELECT 1 
    FROM RequiredItems r
    WHERE NOT EXISTS (
        SELECT 1 
        FROM TableB b 
        WHERE b.FK = a.PK AND b.ItemID = r.ItemID
    )
);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find customers who have never placed an order
2. Find products that have been ordered at least once
3. Find customers who ordered in 2023 but not in 2024
4. Find categories with no products
5. Find customers who ordered ALL products in category 1

Solutions below ↓
*/

-- Solution 1:
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
);

-- Solution 2:
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price
FROM Products p
WHERE EXISTS (
    SELECT 1 
    FROM OrderDetails od 
    WHERE od.ProductID = p.ProductID
);

-- Solution 3:
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    -- Ordered in 2023
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND YEAR(o.OrderDate) = 2023
)
AND NOT EXISTS (
    -- Did NOT order in 2024
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND YEAR(o.OrderDate) = 2024
);

-- Solution 4:
SELECT 
    cat.CategoryID,
    cat.CategoryName
FROM Categories cat
WHERE NOT EXISTS (
    SELECT 1 
    FROM Products p 
    WHERE p.CategoryID = cat.CategoryID
);

-- Solution 5:
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE NOT EXISTS (
    -- Find a product in category 1 they didn't order
    SELECT 1 
    FROM Products p
    WHERE p.CategoryID = 1
      AND NOT EXISTS (
        SELECT 1 
        FROM Orders o
        INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
        WHERE o.CustomerID = c.CustomerID
          AND od.ProductID = p.ProductID
    )
);


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SEMI-JOIN (EXISTS/IN):
  • Returns rows WHERE relationship exists
  • Doesn't return right table columns
  • Stops at first match (efficient)
  • Use for "has ordered", "has relationship"

✓ ANTI-JOIN (NOT EXISTS/NOT IN):
  • Returns rows WHERE relationship doesn't exist
  • Finds missing/orphaned records
  • Use for "never ordered", "lacks relationship"

✓ EXISTS vs IN:
  • EXISTS: Better for correlated conditions
  • EXISTS: Better performance (usually)
  • IN: Good for fixed value lists
  • IN: Simpler for single column checks

✓ NOT EXISTS vs NOT IN:
  • NOT EXISTS: ALWAYS SAFE (even with NULLs)
  • NOT IN: DANGEROUS with NULLs
  • Prefer NOT EXISTS in production code
  • If using NOT IN, ALWAYS filter NULLs

✓ PERFORMANCE:
  • EXISTS stops at first match
  • Faster than JOIN + DISTINCT (often)
  • Index foreign key columns
  • NOT IN with NULLs is slowest

✓ COMMON PATTERNS:
  • Has relationship: EXISTS
  • Lacks relationship: NOT EXISTS
  • Has A but not B: EXISTS + NOT EXISTS
  • Has all: Double negative (NOT EXISTS + NOT EXISTS)

✓ BEST PRACTICES:
  • Prefer EXISTS over IN for subqueries
  • ALWAYS use NOT EXISTS (not NOT IN)
  • Use SELECT 1 in EXISTS (clarity)
  • Index join columns
  • Test with NULL data

✓ USE CASES:
  • Inactive customers
  • Orphaned records
  • Gap analysis
  • Complex filtering
  • "All" conditions (division)
  • Existence checks

✓ WATCH OUT FOR:
  • NULL in NOT IN subquery
  • Missing indexes
  • Complex correlated subqueries
  • Cartesian products
  • Testing only with clean data

============================================================================
NEXT: Lesson 10.10 - Join Performance Optimization
Learn to analyze and optimize join performance.
============================================================================
*/
