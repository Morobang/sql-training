/*============================================
   LESSON 02: USING PARENTHESES
   Control the order of condition evaluation
   
   Estimated Time: 5 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHY PARENTHESES MATTER
   Order of operations in SQL
--------------------------------------------*/

-- SQL evaluates AND before OR (like * before + in math)
-- Without parentheses, results can be surprising!

-- Example without parentheses:
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 AND Price > 100 OR CategoryID = 2;

-- This is interpreted as:
-- (CategoryID = 1 AND Price > 100) OR CategoryID = 2
-- Returns: Expensive electronics OR ALL furniture


-- With parentheses (different result):
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 AND (Price > 100 OR CategoryID = 2);

-- This means:
-- CategoryID = 1 AND (Price > 100 OR CategoryID = 2)
-- Returns: Only Category 1 items (but the OR part doesn't make sense here)


/*--------------------------------------------
   PART 2: OPERATOR PRECEDENCE
   Default evaluation order
--------------------------------------------*/

-- Precedence (highest to lowest):
-- 1. Parentheses ()
-- 2. NOT
-- 3. AND
-- 4. OR

-- Example showing precedence:
SELECT ProductName, Price, CategoryID, StockQuantity
FROM Inventory.Products
WHERE CategoryID = 1 AND Price > 50 OR StockQuantity < 10;

-- Evaluated as:
-- (CategoryID = 1 AND Price > 50) OR StockQuantity < 10


/*--------------------------------------------
   PART 3: SIMPLE PARENTHESES EXAMPLES
   Clear intent with grouping
--------------------------------------------*/

-- Example 1: Group OR conditions
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE Price > 100 
  AND (CategoryID = 1 OR CategoryID = 2);
-- "Expensive items from Electronics OR Furniture"

-- Example 2: Group AND conditions
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE (Price > 100 AND StockQuantity > 10)
   OR (Price < 30 AND StockQuantity > 50);
-- "Expensive + In Stock OR Cheap + High Stock"

-- Example 3: Multiple levels
SELECT ProductName, Price, CategoryID, StockQuantity
FROM Inventory.Products
WHERE CategoryID = 1
  AND (
    (Price > 100 AND StockQuantity > 10)
    OR
    (Price < 50 AND StockQuantity < 5)
  );
-- "Electronics that are either (expensive + available) OR (cheap + rare)"


/*--------------------------------------------
   PART 4: WITHOUT VS WITH PARENTHESES
   Side-by-side comparison
--------------------------------------------*/

-- WITHOUT parentheses (ambiguous):
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE Price > 100 AND CategoryID = 1 OR CategoryID = 2;
-- Returns: (Expensive electronics) OR (All furniture)

-- WITH parentheses (clear intent - Option 1):
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE Price > 100 AND (CategoryID = 1 OR CategoryID = 2);
-- Returns: Expensive items from Electronics or Furniture

-- WITH parentheses (clear intent - Option 2):
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE (Price > 100 AND CategoryID = 1) OR CategoryID = 2;
-- Returns: (Expensive electronics) OR (All furniture)


/*--------------------------------------------
   PART 5: COMPLEX BUSINESS LOGIC
   Real-world filtering scenarios
--------------------------------------------*/

-- Scenario: Find products for promotion
-- Criteria: 
--   - (Low stock AND expensive) OR (High stock AND cheap)
SELECT 
    ProductName,
    Price,
    StockQuantity,
    CASE 
        WHEN StockQuantity < 10 AND Price > 200 THEN 'Clearance'
        WHEN StockQuantity > 100 AND Price < 50 THEN 'Volume Discount'
        ELSE 'Regular'
    END AS PromotionType
FROM Inventory.Products
WHERE (StockQuantity < 10 AND Price > 200)
   OR (StockQuantity > 100 AND Price < 50);


-- Scenario: Customer eligibility
-- Criteria:
--   - (USA AND high value) OR (Any country AND VIP)
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Country,
    COUNT(o.OrderID) AS OrderCount,
    SUM(od.Quantity * od.UnitPrice) AS TotalSpent
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Country
HAVING (c.Country = 'USA' AND SUM(od.Quantity * od.UnitPrice) > 1000)
    OR (COUNT(o.OrderID) > 5);  -- VIP threshold


/*--------------------------------------------
   PART 6: NESTED PARENTHESES
   Multiple levels of grouping
--------------------------------------------*/

-- Deep nesting for complex logic
SELECT ProductName, Price, CategoryID, StockQuantity, SupplierID
FROM Inventory.Products
WHERE (
        (CategoryID = 1 AND Price > 100)  -- Expensive electronics
        OR
        (CategoryID = 2 AND StockQuantity < 20)  -- Low stock furniture
      )
  AND SupplierID IS NOT NULL  -- Must have supplier
  AND Price > 0;  -- Must have price


-- Another example with 3 levels
SELECT ProductName, Price, CategoryID, StockQuantity
FROM Inventory.Products
WHERE (
        CategoryID = 1  -- Electronics
        AND (
            (Price > 500 AND StockQuantity > 10)  -- Premium + Available
            OR
            (Price < 100 AND StockQuantity < 5)  -- Budget + Rare
        )
      )
   OR (
        CategoryID = 2  -- Furniture
        AND Price BETWEEN 200 AND 500  -- Mid-range
      );


/*--------------------------------------------
   PART 7: FORMATTING FOR READABILITY
   Make complex conditions readable
--------------------------------------------*/

-- BAD: All on one line
SELECT * FROM Inventory.Products WHERE CategoryID = 1 AND Price > 100 OR CategoryID = 2 AND StockQuantity < 10 OR Price > 1000;

-- GOOD: Formatted with indentation
SELECT 
    ProductName,
    Price,
    CategoryID,
    StockQuantity
FROM Inventory.Products
WHERE (CategoryID = 1 AND Price > 100)
   OR (CategoryID = 2 AND StockQuantity < 10)
   OR (Price > 1000);

-- BETTER: Commented for clarity
SELECT 
    ProductName,
    Price,
    CategoryID,
    StockQuantity
FROM Inventory.Products
WHERE (CategoryID = 1 AND Price > 100)       -- Expensive electronics
   OR (CategoryID = 2 AND StockQuantity < 10) -- Low stock furniture
   OR (Price > 1000);                         -- Any premium items


/*--------------------------------------------
   PART 8: COMMON MISTAKES
   Avoiding logical errors
--------------------------------------------*/

-- MISTAKE 1: Forgetting parentheses with OR
-- WRONG (probably not what you want):
SELECT * FROM Inventory.Products
WHERE CategoryID = 1 AND Price > 100 OR Price < 30;
-- Returns: (Expensive electronics) OR (ANY cheap item)

-- CORRECT:
SELECT * FROM Inventory.Products
WHERE CategoryID = 1 AND (Price > 100 OR Price < 30);
-- Returns: Electronics that are expensive OR cheap


-- MISTAKE 2: Too many parentheses (confusing but not wrong)
SELECT * FROM Inventory.Products
WHERE ((((CategoryID = 1)))) AND ((Price > 100));
-- Works, but unnecessarily complex


-- MISTAKE 3: Mismatched parentheses
-- This will cause a syntax error:
-- SELECT * FROM Products WHERE (Price > 100 AND CategoryID = 1;
-- Missing closing )


/*--------------------------------------------
   PART 9: TESTING YOUR LOGIC
   Verify parentheses work as intended
--------------------------------------------*/

-- Add descriptive column to verify logic
SELECT 
    ProductName,
    Price,
    CategoryID,
    StockQuantity,
    CASE 
        WHEN CategoryID = 1 AND (Price > 100 OR Price < 30) 
            THEN 'MATCHES: Electronics extreme price'
        ELSE 'Does not match'
    END AS LogicTest
FROM Inventory.Products;

-- Count matches vs non-matches
SELECT 
    SUM(CASE WHEN CategoryID = 1 AND (Price > 100 OR Price < 30) THEN 1 ELSE 0 END) AS Matches,
    SUM(CASE WHEN NOT (CategoryID = 1 AND (Price > 100 OR Price < 30)) THEN 1 ELSE 0 END) AS NonMatches
FROM Inventory.Products;


/*--------------------------------------------
   PART 10: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Find products where (Price > 100 OR StockQuantity < 10) AND CategoryID = 1
-- Write your query:


-- 2. Find products where Price BETWEEN 50 AND 200 AND (CategoryID = 1 OR CategoryID = 2)
-- Write your query:


-- 3. Find products where (Price < 50 AND StockQuantity > 100) OR (Price > 500 AND StockQuantity > 10)
-- Write your query:


-- 4. Rewrite this to be more readable with better parentheses:
--    WHERE CategoryID = 1 AND Price > 100 OR CategoryID = 2 AND Price < 50 OR StockQuantity = 0
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ Parentheses control evaluation order
   ✅ Default precedence: () > NOT > AND > OR
   ✅ Use parentheses for clarity even when not required
   ✅ Format complex conditions with indentation
   ✅ Test your logic to verify it works as intended
   
   Best Practices:
   - Always use parentheses with mixed AND/OR
   - Indent for readability
   - Add comments for complex logic
   - Test with CASE to verify logic
   
   NEXT: Lesson 03 - NOT Operator
============================================*/
