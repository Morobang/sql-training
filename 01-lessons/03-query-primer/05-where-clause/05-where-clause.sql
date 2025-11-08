/*============================================
   LESSON 05: WHERE CLAUSE
   Filtering data to get exactly what you need
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: BASIC WHERE CLAUSE
   Filter rows based on conditions
--------------------------------------------*/

-- Numeric comparison: Products over $100
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100;

-- Exact match: Products exactly $75.50
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price = 75.50;

-- Text match: Customers from USA
SELECT FirstName, LastName, Country
FROM Sales.Customers
WHERE Country = 'USA';


/*--------------------------------------------
   PART 2: COMPARISON OPERATORS
   Different ways to compare values
--------------------------------------------*/

-- Equal to
SELECT * FROM Inventory.Products WHERE Price = 100;

-- Not equal to (two ways)
SELECT * FROM Inventory.Products WHERE Price <> 100;
SELECT * FROM Inventory.Products WHERE Price != 100;

-- Greater than
SELECT * FROM Inventory.Products WHERE Price > 100;

-- Greater than or equal to
SELECT * FROM Inventory.Products WHERE Price >= 100;

-- Less than
SELECT * FROM Inventory.Products WHERE Price < 100;

-- Less than or equal to
SELECT * FROM Inventory.Products WHERE Price <= 100;


/*--------------------------------------------
   PART 3: COMBINING CONDITIONS WITH AND
   All conditions must be true
--------------------------------------------*/

-- Products between $50 and $200
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price >= 50 AND Price <= 200;

-- Products in Electronics category with high stock
SELECT ProductName, CategoryID, StockQuantity
FROM Inventory.Products
WHERE CategoryID = 1 AND StockQuantity > 50;

-- Three conditions
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE Price > 50 AND StockQuantity > 20 AND CategoryID = 1;


/*--------------------------------------------
   PART 4: COMBINING CONDITIONS WITH OR
   At least ONE condition must be true
--------------------------------------------*/

-- Products either cheap (under $30) OR expensive (over $1000)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 30 OR Price > 1000;

-- Products in Electronics OR Furniture categories
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 OR CategoryID = 2;

-- Multiple OR conditions
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 50 OR Price > 500 OR StockQuantity < 10;


/*--------------------------------------------
   PART 5: MIXING AND / OR WITH PARENTHESES
   Control the order of evaluation
--------------------------------------------*/

-- Cheap electronics OR any furniture
SELECT ProductName, CategoryID, Price
FROM Inventory.Products
WHERE (CategoryID = 1 AND Price < 100) OR CategoryID = 2;

-- Products that are either:
--   1. Electronics under $100, OR
--   2. Furniture over $200
SELECT ProductName, CategoryID, Price
FROM Inventory.Products
WHERE (CategoryID = 1 AND Price < 100) 
   OR (CategoryID = 2 AND Price > 200);

-- Without parentheses (different result!)
SELECT ProductName, CategoryID, Price
FROM Inventory.Products
WHERE CategoryID = 1 AND Price < 100 OR Price > 200;
-- This means: (Electronics under $100) OR (ANY product over $200)


/*--------------------------------------------
   PART 6: BETWEEN OPERATOR
   Shortcut for range checking
--------------------------------------------*/

-- Products between $50 and $500
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price BETWEEN 50 AND 500;

-- Same as:
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price >= 50 AND Price <= 500;

-- Date range
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';


/*--------------------------------------------
   PART 7: IN OPERATOR
   Match against a list of values
--------------------------------------------*/

-- Products in specific categories
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID IN (1, 2);

-- Same as:
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID = 1 OR CategoryID = 2;

-- Customers from specific countries
SELECT FirstName, LastName, Country
FROM Sales.Customers
WHERE Country IN ('USA', 'UK', 'Canada');

-- NOT IN (exclude values)
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID NOT IN (1, 2);


/*--------------------------------------------
   PART 8: LIKE OPERATOR - Pattern Matching
   Search for patterns in text
--------------------------------------------*/

-- Products starting with 'L'
SELECT ProductName
FROM Inventory.Products
WHERE ProductName LIKE 'L%';

-- Products ending with 'er'
SELECT ProductName
FROM Inventory.Products
WHERE ProductName LIKE '%er';

-- Products containing 'top'
SELECT ProductName
FROM Inventory.Products
WHERE ProductName LIKE '%top%';

-- Exact length: 4 characters
SELECT ProductName
FROM Inventory.Products
WHERE ProductName LIKE '____';  -- Four underscores

-- Pattern: Starts with 'S', ends with 't'
SELECT FirstName
FROM Sales.Customers
WHERE FirstName LIKE 'S%t';


/*--------------------------------------------
   PART 9: NULL HANDLING
   Finding or excluding missing values
--------------------------------------------*/

-- Find products WITHOUT a supplier
SELECT ProductName, SupplierID
FROM Inventory.Products
WHERE SupplierID IS NULL;

-- Find products WITH a supplier
SELECT ProductName, SupplierID
FROM Inventory.Products
WHERE SupplierID IS NOT NULL;

-- Common mistake: This DOESN'T WORK for NULL!
-- SELECT * FROM Products WHERE SupplierID = NULL;  ❌ Wrong!
-- Use IS NULL instead  ✅ Correct!


/*--------------------------------------------
   PART 10: NOT OPERATOR
   Reverse a condition
--------------------------------------------*/

-- Products NOT in Electronics category
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE NOT CategoryID = 1;

-- Same as:
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID <> 1;

-- NOT with LIKE
SELECT ProductName
FROM Inventory.Products
WHERE ProductName NOT LIKE '%top%';

-- NOT with BETWEEN
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price NOT BETWEEN 50 AND 500;


/*--------------------------------------------
   PART 11: DATE FILTERING
   Working with dates and times
--------------------------------------------*/

-- Orders on specific date
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate = '2025-01-15';

-- Orders after a date
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate > '2025-01-01';

-- Orders in date range
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';

-- Orders in current year (dynamic)
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE YEAR(OrderDate) = YEAR(GETDATE());

-- Orders in last 30 days
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE());


/*--------------------------------------------
   PART 12: WHERE WITH JOINS
   Filter joined tables
--------------------------------------------*/

-- Electronics products only
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Expensive products with category
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 200;

-- Multiple filters
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.StockQuantity
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics'
  AND p.Price > 50
  AND p.StockQuantity > 10;


/*--------------------------------------------
   PART 13: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Find products priced between $20 and $100
-- Write your query:


-- 2. Find customers from either USA or UK
-- Write your query:


-- 3. Find products with names starting with 'M' or 'K'
-- Write your query:


-- 4. Find products in Electronics category that are under $200
-- Write your query:


-- 5. Find orders placed in January 2025
-- Write your query:


-- 6. Find employees with salaries over $70,000 OR in department 1
-- Write your query:


-- 7. Find products with NULL supplier AND low stock (< 20)
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ WHERE filters rows before returning results
   ✅ Use AND when all conditions must be true
   ✅ Use OR when any condition can be true
   ✅ Use parentheses to control logic order
   ✅ BETWEEN for ranges, IN for lists, LIKE for patterns
   ✅ Use IS NULL / IS NOT NULL for missing values
   ✅ Comparison operators: = <> > < >= <=
   
   NEXT: Lesson 06 - GROUP BY & HAVING
============================================*/
