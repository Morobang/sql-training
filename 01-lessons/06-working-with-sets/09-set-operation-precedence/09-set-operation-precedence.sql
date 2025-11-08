-- =============================================
-- Lesson 09: Set Operation Precedence
-- Chapter 06: Working with Sets
-- =============================================
-- Description: Understanding execution order when mixing set operators
-- Estimated Time: 20 minutes
-- =============================================

USE RetailStore;
GO

-- =============================================
-- Part 1: Default Precedence (Left to Right)
-- =============================================

-- Set operations execute LEFT TO RIGHT (by default)
SELECT ProductID FROM Products WHERE CategoryID = 1  -- Query A
UNION
SELECT ProductID FROM Products WHERE CategoryID = 2  -- Query B
EXCEPT
SELECT ProductID FROM Products WHERE Price > 500;   -- Query C

/*
Execution Order:
Step 1: A UNION B → Result1
Step 2: Result1 EXCEPT C → Final Result
*/

-- Visual representation
/*
        A ∪ B              EXCEPT         C
    ┌─────────────┐                  ┌────────┐
    │  Products   │                  │ Expensive
    │  Cat 1 & 2  │      →  -  →     │ Products│
    └─────────────┘                  └────────┘
*/

-- =============================================
-- Part 2: Using Parentheses to Control Order
-- =============================================

-- Default: Left to right
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID FROM Products WHERE CategoryID = 2
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;
-- (A UNION B) INTERSECT C

-- With parentheses: Force different order
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION
(
    SELECT ProductID FROM Products WHERE CategoryID = 2
    INTERSECT
    SELECT ProductID FROM Products WHERE Price > 100
);
-- A UNION (B INTERSECT C)

-- Different results!

-- =============================================
-- Part 3: INTERSECT Has Higher Precedence
-- =============================================

-- In some databases, INTERSECT has higher precedence than UNION/EXCEPT
-- Best practice: Always use parentheses for clarity!

-- Without parentheses (relies on precedence rules)
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID FROM Products WHERE CategoryID = 2
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;

-- With parentheses (explicit and clear)
(SELECT ProductID FROM Products WHERE CategoryID = 1)
UNION
(SELECT ProductID FROM Products WHERE CategoryID = 2
 INTERSECT
 SELECT ProductID FROM Products WHERE Price > 100);

-- =============================================
-- Part 4: Practical Example - Understanding Order
-- =============================================

-- Create test sets for demonstration
-- Set A: Products 1, 2, 3
-- Set B: Products 2, 3, 4
-- Set C: Products 3, 4, 5

-- Scenario 1: (A UNION B) EXCEPT C
(
    SELECT ProductID FROM Products WHERE ProductID IN (1,2,3)  -- A
    UNION
    SELECT ProductID FROM Products WHERE ProductID IN (2,3,4)  -- B
)
EXCEPT
SELECT ProductID FROM Products WHERE ProductID IN (3,4,5);     -- C

/*
Step 1: A UNION B = {1,2,3,4}
Step 2: {1,2,3,4} EXCEPT C{3,4,5} = {1,2}
Final Result: {1, 2}
*/

-- Scenario 2: A UNION (B EXCEPT C)
SELECT ProductID FROM Products WHERE ProductID IN (1,2,3)      -- A
UNION
(
    SELECT ProductID FROM Products WHERE ProductID IN (2,3,4)  -- B
    EXCEPT
    SELECT ProductID FROM Products WHERE ProductID IN (3,4,5)  -- C
);

/*
Step 1: B EXCEPT C = {2,3,4} - {3,4,5} = {2}
Step 2: A UNION {2} = {1,2,3} ∪ {2} = {1,2,3}
Final Result: {1, 2, 3}
*/

-- Different results! Precedence matters!

-- =============================================
-- Part 5: Complex Nested Operations
-- =============================================

-- Multiple levels of nesting
(
    (
        SELECT ProductID FROM Products WHERE CategoryID = 1
        UNION
        SELECT ProductID FROM Products WHERE CategoryID = 2
    )
    INTERSECT
    SELECT ProductID FROM Products WHERE Price > 50
)
EXCEPT
SELECT ProductID FROM Products WHERE ProductID IN (
    SELECT ProductID FROM OrderDetails
);

/*
Execution Order:
1. Innermost: CategoryID 1 UNION CategoryID 2
2. Next level: Result INTERSECT Price > 50
3. Outermost: Result EXCEPT Products in OrderDetails
*/

-- =============================================
-- Part 6: Mixing All Three Operators
-- =============================================

-- Example: Products that meet complex criteria
-- Want: (Electronics OR Books) AND (Price > 50) BUT NOT (Already Ordered)

(
    SELECT ProductID, ProductName FROM Products WHERE CategoryID IN (1, 2)
)
INTERSECT
(
    SELECT ProductID, ProductName FROM Products WHERE Price > 50
)
EXCEPT
(
    SELECT DISTINCT p.ProductID, p.ProductName 
    FROM Products p
    INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
);

-- Clearer with nested parentheses
(
    (
        SELECT ProductID, ProductName FROM Products WHERE CategoryID IN (1, 2)
        INTERSECT
        SELECT ProductID, ProductName FROM Products WHERE Price > 50
    )
    EXCEPT
    (
        SELECT DISTINCT p.ProductID, p.ProductName 
        FROM Products p
        INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
    )
);

-- =============================================
-- Part 7: UNION ALL in Mixed Operations
-- =============================================

-- UNION ALL with other operations
(
    SELECT ProductID FROM Products WHERE CategoryID = 1
    UNION ALL
    SELECT ProductID FROM Products WHERE CategoryID = 1  -- Duplicates kept
)
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;

-- Note: INTERSECT still removes duplicates from final result

-- Multiple UNION ALL
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION ALL
SELECT ProductID FROM Products WHERE CategoryID = 2
UNION ALL
SELECT ProductID FROM Products WHERE CategoryID = 3;
-- All duplicates kept

-- =============================================
-- Part 8: Real-World Complex Query
-- =============================================

-- Find customers who:
-- - Ordered in Q1 OR Q2
-- - AND spent > $500 total
-- - BUT NOT customers who complained

(
    (
        SELECT DISTINCT CustomerID FROM Orders 
        WHERE MONTH(OrderDate) IN (1,2,3)
        UNION
        SELECT DISTINCT CustomerID FROM Orders 
        WHERE MONTH(OrderDate) IN (4,5,6)
    )
    INTERSECT
    (
        SELECT CustomerID 
        FROM Orders 
        GROUP BY CustomerID 
        HAVING SUM(TotalAmount) > 500
    )
)
EXCEPT
(
    SELECT CustomerID FROM Complaints
);

-- =============================================
-- Part 9: Performance Implications
-- =============================================

-- Order can affect performance

-- Version 1: Filter last (slower)
(
    SELECT ProductID FROM Products  -- All products
    UNION
    SELECT ProductID FROM Products  -- All products again
)
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;  -- Filter

-- Version 2: Filter early (faster)
(
    SELECT ProductID FROM Products WHERE Price > 100  -- Filter first
)
INTERSECT
(
    SELECT ProductID FROM Products WHERE Price > 100  -- Filter first
);

-- Always filter as early as possible!

-- =============================================
-- Part 10: Debugging Complex Queries
-- =============================================

-- Strategy: Build incrementally

-- Step 1: Test individual queries
SELECT ProductID FROM Products WHERE CategoryID = 1;
SELECT ProductID FROM Products WHERE CategoryID = 2;
SELECT ProductID FROM Products WHERE Price > 100;

-- Step 2: Test first operation
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID FROM Products WHERE CategoryID = 2;

-- Step 3: Add next operation
(
    SELECT ProductID FROM Products WHERE CategoryID = 1
    UNION
    SELECT ProductID FROM Products WHERE CategoryID = 2
)
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;

-- Step 4: Add final operation and verify

-- =============================================
-- Part 11: Common Mistakes
-- =============================================

-- Mistake 1: Assuming AND/OR behavior
-- This is NOT the same as AND/OR in WHERE clause!

-- Set operations
SELECT ProductID FROM Products WHERE CategoryID = 1
INTERSECT
SELECT ProductID FROM Products WHERE Price > 100;

-- WHERE clause (usually simpler and faster)
SELECT ProductID FROM Products 
WHERE CategoryID = 1 AND Price > 100;

-- Use WHERE clause when possible!

-- Mistake 2: Not using parentheses
-- Ambiguous
SELECT ProductID FROM Products WHERE CategoryID = 1
UNION
SELECT ProductID FROM Products WHERE CategoryID = 2
EXCEPT
SELECT ProductID FROM Products WHERE Price > 500;

-- Clear
(
    SELECT ProductID FROM Products WHERE CategoryID = 1
    UNION
    SELECT ProductID FROM Products WHERE CategoryID = 2
)
EXCEPT
SELECT ProductID FROM Products WHERE Price > 500;

-- =============================================
-- Part 12: Best Practices
-- =============================================

-- Practice 1: Always use parentheses for multiple operations
(
    SELECT columns FROM table1
    UNION
    SELECT columns FROM table2
)
INTERSECT
(
    SELECT columns FROM table3
);

-- Practice 2: Comment complex queries
-- Get customers who ordered in Q1 or Q2
(
    SELECT CustomerID FROM Orders WHERE MONTH(OrderDate) IN (1,2,3)
    UNION
    SELECT CustomerID FROM Orders WHERE MONTH(OrderDate) IN (4,5,6)
)
INTERSECT
-- But only if they spent > $500
(
    SELECT CustomerID FROM Orders GROUP BY CustomerID HAVING SUM(TotalAmount) > 500
);

-- Practice 3: Build and test incrementally
-- Test each subquery separately before combining

-- Practice 4: Consider alternatives
-- Is a JOIN or subquery clearer?
SELECT DISTINCT p.ProductID
FROM Products p
WHERE p.CategoryID IN (1,2)
  AND p.Price > 50
  AND NOT EXISTS (SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID);

-- Often clearer than multiple set operations!

-- =============================================
-- Summary
-- =============================================
/*
SET OPERATION PRECEDENCE:

Default Order:
├─ Left to right (most SQL databases)
├─ INTERSECT may have higher precedence (database-specific)
└─ Always use parentheses for clarity!

Execution:
(A UNION B) EXCEPT C
   Step 1      Step 2

A UNION (B EXCEPT C)
          Step 1  Step 2

Parentheses Control:
├─ Override default precedence
├─ Make intent explicit
├─ Essential for complex queries
└─ Improve readability

Performance Tips:
├─ Filter early (smaller datasets)
├─ Use indexes on filter columns
├─ Consider WHERE clause instead of set operations
└─ Test subqueries independently

Best Practices:
✅ Use parentheses always
✅ Comment complex logic
✅ Build incrementally
✅ Test each part separately
✅ Consider JOIN/subquery alternatives
✅ Filter as early as possible

Common Pattern:
(
    (Query A OP1 Query B)
    OP2
    (Query C OP3 Query D)
)

Remember:
• Set operations ≠ AND/OR in WHERE
• WHERE clause often simpler
• Precedence rules vary by database
• Parentheses = clarity

NEXT: Lesson 10 - Test Your Knowledge
*/

-- =============================================
-- Practice Exercises
-- =============================================
/*
1. Write (A UNION B) INTERSECT C with real data
2. Write A UNION (B INTERSECT C) and compare results
3. Build a 4-level nested query with parentheses
4. Rewrite a complex set operation as JOIN/WHERE
5. Create a query that filters early for performance

Try these before the test!
*/
