/*============================================
   LESSON 07: MEMBERSHIP CONDITIONS
   Testing set membership with IN
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: IN OPERATOR
   Check if value matches any in a list
--------------------------------------------*/

-- Simple IN
SELECT ProductName, CategoryID FROM Inventory.Products WHERE CategoryID IN (1, 2, 3);

-- Same as multiple OR conditions
SELECT ProductName, CategoryID FROM Inventory.Products 
WHERE CategoryID = 1 OR CategoryID = 2 OR CategoryID = 3;

-- String values
SELECT FirstName, LastName FROM Sales.Customers 
WHERE LastName IN ('Smith', 'Johnson', 'Williams');

/*--------------------------------------------
   PART 2: NOT IN OPERATOR
   Exclude values from a list
--------------------------------------------*/

-- Exclude specific values
SELECT ProductName, CategoryID FROM Inventory.Products WHERE CategoryID NOT IN (1, 2);

-- Same as:
SELECT ProductName, CategoryID FROM Inventory.Products 
WHERE CategoryID <> 1 AND CategoryID <> 2;

-- Exclude specific names
SELECT FirstName, LastName FROM Sales.Customers 
WHERE LastName NOT IN ('Smith', 'Johnson');

/*--------------------------------------------
   PART 3: IN WITH SUBQUERY
   Dynamic membership lists
--------------------------------------------*/

-- Find products in categories with specific names
SELECT ProductName FROM Inventory.Products
WHERE CategoryID IN (
    SELECT CategoryID FROM Inventory.Categories 
    WHERE CategoryName IN ('Electronics', 'Books')
);

-- Find customers who placed orders
SELECT FirstName, LastName FROM Sales.Customers
WHERE CustomerID IN (
    SELECT DISTINCT CustomerID FROM Sales.Orders
);

/*--------------------------------------------
   PART 4: NOT IN WITH SUBQUERY
   Find non-members
--------------------------------------------*/

-- Find customers who NEVER ordered
SELECT FirstName, LastName FROM Sales.Customers
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID FROM Sales.Orders WHERE CustomerID IS NOT NULL
);

-- Find products never sold
SELECT ProductName FROM Inventory.Products
WHERE ProductID NOT IN (
    SELECT DISTINCT ProductID FROM Sales.OrderDetails WHERE ProductID IS NOT NULL
);

/*--------------------------------------------
   PART 5: IN VS OR PERFORMANCE
   When to use each
--------------------------------------------*/

-- ✅ GOOD: Use IN for many values
SELECT * FROM Inventory.Products WHERE CategoryID IN (1,2,3,4,5,6,7,8,9,10);

-- ❌ BAD: Too many OR conditions
SELECT * FROM Inventory.Products 
WHERE CategoryID = 1 OR CategoryID = 2 OR CategoryID = 3 OR CategoryID = 4;

-- ✅ GOOD: Use OR for different columns
SELECT * FROM Inventory.Products 
WHERE CategoryID = 1 OR Price > 1000;

/*--------------------------------------------
   PART 6: NULL BEHAVIOR IN IN/NOT IN
   Critical NULL handling
--------------------------------------------*/

-- IN with NULL
SELECT ProductName FROM Inventory.Products WHERE CategoryID IN (1, 2, NULL);  -- NULL ignored

-- ⚠️ DANGER: NOT IN with NULL in subquery
-- This returns ZERO rows if subquery has any NULL!
SELECT FirstName, LastName FROM Sales.Customers
WHERE CustomerID NOT IN (SELECT CustomerID FROM Sales.Orders);  -- Fails if any NULL

-- ✅ FIX: Filter out NULLs
SELECT FirstName, LastName FROM Sales.Customers
WHERE CustomerID NOT IN (
    SELECT CustomerID FROM Sales.Orders WHERE CustomerID IS NOT NULL
);

-- ✅ BETTER: Use NOT EXISTS instead
SELECT FirstName, LastName FROM Sales.Customers c
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.Orders o WHERE o.CustomerID = c.CustomerID
);

/*--------------------------------------------
   PART 7: COMBINING IN WITH OTHER CONDITIONS
   Complex membership logic
--------------------------------------------*/

-- IN + range condition
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID IN (1, 2, 3)
  AND Price BETWEEN 50 AND 500;

-- Multiple IN conditions
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID IN (1, 2)
  AND Price IN (99.99, 149.99, 199.99);

-- IN with NOT
SELECT ProductName FROM Inventory.Products
WHERE CategoryID IN (1, 2)
  AND ProductID NOT IN (SELECT ProductID FROM Sales.OrderDetails);

/*--------------------------------------------
   PART 8: IN WITH EXPRESSIONS
   Calculated membership
--------------------------------------------*/

-- Match calculated values
SELECT ProductName, YEAR(CreatedDate) AS Year
FROM Inventory.Products
WHERE YEAR(CreatedDate) IN (2024, 2025);

-- Match rounded values
SELECT ProductName, Price
FROM Inventory.Products
WHERE ROUND(Price, 0) IN (100, 200, 300);

/*--------------------------------------------
   PART 9: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Sales report for specific regions
SELECT c.FirstName, c.LastName, o.OrderDate, o.TotalAmount
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE c.City IN ('New York', 'Los Angeles', 'Chicago');

-- Example 2: Products in multiple price ranges
SELECT ProductName, Price,
    CASE 
        WHEN Price IN (SELECT Price FROM Inventory.Products WHERE Price < 50) THEN 'Budget'
        WHEN Price IN (SELECT Price FROM Inventory.Products WHERE Price BETWEEN 50 AND 200) THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory
FROM Inventory.Products;

/*--------------------------------------------
   PART 10: PRACTICE
--------------------------------------------*/

-- 1. Find products in categories 1, 3, 5
-- 2. Find customers NOT in 'Smith', 'Jones', 'Brown'
-- 3. Find products in Electronics or Books categories (use subquery)
-- 4. Find employees who never managed a department
-- 5. Find orders from last 3 months

/*============================================
   NEXT: Lesson 08 - Matching Conditions
============================================*/
