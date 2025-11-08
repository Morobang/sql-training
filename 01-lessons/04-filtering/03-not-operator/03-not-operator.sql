/*============================================
   LESSON 03: NOT OPERATOR
   Reversing conditions and excluding data
   
   Estimated Time: 5 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS NOT?
   Reversing TRUE/FALSE
--------------------------------------------*/

-- NOT reverses the result of a condition
-- NOT TRUE  = FALSE
-- NOT FALSE = TRUE
-- NOT NULL  = NULL

-- Example: Find products NOT in Electronics
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE NOT CategoryID = 1;

-- Same as:
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID <> 1;


/*--------------------------------------------
   PART 2: NOT WITH COMPARISON OPERATORS
   Alternative ways to express conditions
--------------------------------------------*/

-- NOT equal
SELECT ProductName, Price
FROM Inventory.Products
WHERE NOT Price = 100;
-- Same as: WHERE Price <> 100 or WHERE Price != 100

-- NOT greater than
SELECT ProductName, Price
FROM Inventory.Products
WHERE NOT Price > 100;
-- Same as: WHERE Price <= 100

-- NOT less than
SELECT ProductName, Price
FROM Inventory.Products
WHERE NOT Price < 50;
-- Same as: WHERE Price >= 50


/*--------------------------------------------
   PART 3: NOT IN
   Exclude multiple values
--------------------------------------------*/

-- Find products NOT in specific categories
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID NOT IN (1, 2);

-- Same as:
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID <> 1 AND CategoryID <> 2;

-- Find customers NOT from specific countries
SELECT FirstName, LastName, Country
FROM Sales.Customers
WHERE Country NOT IN ('USA', 'UK', 'Canada');


/*--------------------------------------------
   PART 4: NOT BETWEEN
   Exclude a range
--------------------------------------------*/

-- Products NOT in price range $50-$200
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price NOT BETWEEN 50 AND 200;

-- Same as:
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 50 OR Price > 200;

-- Another example
SELECT ProductName, Price
FROM Inventory.Products
WHERE NOT (Price >= 50 AND Price <= 200);


/*--------------------------------------------
   PART 5: NOT LIKE
   Exclude pattern matches
--------------------------------------------*/

-- Products NOT starting with 'L'
SELECT ProductName
FROM Inventory.Products
WHERE ProductName NOT LIKE 'L%';

-- Products NOT containing 'top'
SELECT ProductName
FROM Inventory.Products
WHERE ProductName NOT LIKE '%top%';

-- Products NOT ending with 'er'
SELECT ProductName
FROM Inventory.Products
WHERE ProductName NOT LIKE '%er';

-- Combine multiple NOT LIKE
SELECT ProductName
FROM Inventory.Products
WHERE ProductName NOT LIKE '%Laptop%'
  AND ProductName NOT LIKE '%Mouse%'
  AND ProductName NOT LIKE '%Keyboard%';


/*--------------------------------------------
   PART 6: NOT NULL
   Find non-missing values
--------------------------------------------*/

-- Products that HAVE a supplier
SELECT ProductName, SupplierID
FROM Inventory.Products
WHERE SupplierID IS NOT NULL;

-- Customers that HAVE an email
SELECT FirstName, LastName, Email
FROM Sales.Customers
WHERE Email IS NOT NULL;

-- Orders that HAVE been shipped
SELECT OrderID, OrderDate, ShipDate
FROM Sales.Orders
WHERE ShipDate IS NOT NULL;


/*--------------------------------------------
   PART 7: NOT EXISTS
   Exclude based on subquery
--------------------------------------------*/

-- Find products that have NEVER been ordered
SELECT ProductName, ProductID
FROM Inventory.Products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Sales.OrderDetails od 
    WHERE od.ProductID = p.ProductID
);

-- Find customers who have NEVER placed an order
SELECT FirstName, LastName, Email
FROM Sales.Customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Sales.Orders o 
    WHERE o.CustomerID = c.CustomerID
);


/*--------------------------------------------
   PART 8: NOT WITH AND/OR
   Complex combinations
--------------------------------------------*/

-- NOT with AND - Both must NOT be true
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE NOT (Price > 100 AND StockQuantity < 10);
-- Same as: WHERE Price <= 100 OR StockQuantity >= 10

-- NOT with OR - Neither can be true
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE NOT (CategoryID = 1 OR CategoryID = 2);
-- Same as: WHERE CategoryID <> 1 AND CategoryID <> 2

-- De Morgan's Laws:
-- NOT (A AND B) = (NOT A) OR (NOT B)
-- NOT (A OR B) = (NOT A) AND (NOT B)


/*--------------------------------------------
   PART 9: DOUBLE NEGATIVES
   NOT NOT = positive (avoid this!)
--------------------------------------------*/

-- Confusing (but works):
SELECT ProductName, Price
FROM Inventory.Products
WHERE NOT (NOT Price > 100);
-- Same as: WHERE Price > 100

-- Better to just write:
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100;

-- Another confusing example:
SELECT ProductName
FROM Inventory.Products
WHERE NOT ProductName NOT LIKE '%Laptop%';  -- Hard to read!

-- Better:
SELECT ProductName
FROM Inventory.Products
WHERE ProductName LIKE '%Laptop%';


/*--------------------------------------------
   PART 10: NOT WITH PARENTHESES
   Control negation scope
--------------------------------------------*/

-- NOT applies to the entire parenthesized expression
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE NOT (CategoryID = 1 AND Price > 100);
-- Returns: Everything EXCEPT expensive electronics

-- Different from:
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE NOT CategoryID = 1 AND Price > 100;
-- Returns: Non-electronics that are expensive
-- Because it's evaluated as: (NOT CategoryID = 1) AND (Price > 100)


-- Complex example:
SELECT ProductName, Price, CategoryID, StockQuantity
FROM Inventory.Products
WHERE NOT (
    (CategoryID = 1 AND Price > 100)
    OR
    (CategoryID = 2 AND StockQuantity < 10)
);
-- Returns: Everything EXCEPT (expensive electronics OR low-stock furniture)


/*--------------------------------------------
   PART 11: PRACTICAL NOT EXAMPLES
   Real-world usage
--------------------------------------------*/

-- Example 1: Exclude discontinued products
SELECT ProductName, Price
FROM Inventory.Products
WHERE ProductName NOT LIKE '%Discontinued%'
  AND StockQuantity > 0;

-- Example 2: Find active customers (have orders, valid email)
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Email
FROM Sales.Customers c
WHERE c.Email IS NOT NULL
  AND EXISTS (SELECT 1 FROM Sales.Orders WHERE CustomerID = c.CustomerID);

-- Example 3: Products needing attention (no supplier OR low stock)
SELECT 
    ProductName,
    SupplierID,
    StockQuantity,
    CASE 
        WHEN SupplierID IS NULL THEN 'No Supplier'
        WHEN StockQuantity < 10 THEN 'Low Stock'
    END AS Issue
FROM Inventory.Products
WHERE SupplierID IS NULL 
   OR StockQuantity < 10;

-- Example 4: Exclude test/sample data
SELECT OrderID, OrderDate, CustomerID
FROM Sales.Orders
WHERE CustomerID NOT IN (
    SELECT CustomerID 
    FROM Sales.Customers 
    WHERE Email LIKE '%@test.com'
       OR Email LIKE '%@example.com'
);


/*--------------------------------------------
   PART 12: NOT vs <> vs !=
   When to use each
--------------------------------------------*/

-- All three work for simple comparisons:

-- Style 1: NOT
WHERE NOT CategoryID = 1

-- Style 2: <>
WHERE CategoryID <> 1

-- Style 3: !=
WHERE CategoryID != 1

-- Recommendation: Use <> or != for simple inequality
-- Use NOT for:
--   - NOT IN
--   - NOT LIKE
--   - NOT BETWEEN
--   - NOT EXISTS
--   - Negating complex expressions


/*--------------------------------------------
   PART 13: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Find products NOT in category 1
-- Write your query:


-- 2. Find products with price NOT between 50 and 200
-- Write your query:


-- 3. Find products NOT starting with 'M' or 'K'
-- Write your query:


-- 4. Find products that have suppliers (SupplierID IS NOT NULL)
-- Write your query:


-- 5. Find products NOT in categories 1, 2, or 3
-- Write your query:


-- 6. Find customers who have NOT placed any orders
-- Write your query:


-- 7. Find products where NOT (Price > 100 AND StockQuantity < 10)
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ NOT reverses condition results
   ✅ NOT TRUE = FALSE, NOT FALSE = TRUE
   ✅ Use NOT with: IN, BETWEEN, LIKE, EXISTS
   ✅ NOT applies to entire parenthesized expression
   ✅ Avoid double negatives (confusing)
   
   Best Practices:
   - Use <> or != for simple inequality
   - Use NOT for complex exclusions
   - Use parentheses to clarify scope
   - Avoid NOT NOT (double negative)
   
   De Morgan's Laws:
   - NOT (A AND B) = (NOT A) OR (NOT B)
   - NOT (A OR B) = (NOT A) AND (NOT B)
   
   NEXT: Lesson 04 - Building Conditions
============================================*/
