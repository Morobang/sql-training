/*============================================
   LESSON 02: QUERY CLAUSES
   Understanding the complete SELECT statement
   
   Estimated Time: 10 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: THE COMPLETE SELECT STATEMENT
   All the clauses you can use
--------------------------------------------*/

-- The full SELECT syntax (you don't always need all parts):
SELECT 
    ProductName,
    Price
FROM Inventory.Products
WHERE Price > 100
ORDER BY Price DESC;

-- Breaking it down:
-- SELECT → What columns to show
-- FROM   → Which table(s)
-- WHERE  → Filter which rows
-- ORDER BY → Sort the results


/*--------------------------------------------
   PART 2: SELECT CLAUSE
   Choose which columns to display
--------------------------------------------*/

-- Select all columns
SELECT * FROM Inventory.Categories;

-- Select specific columns
SELECT CategoryName, Description 
FROM Inventory.Categories;

-- Select with calculations
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS PriceWithTax
FROM Inventory.Products;


/*--------------------------------------------
   PART 3: FROM CLAUSE
   Specify the table (or tables)
--------------------------------------------*/

-- Single table
SELECT * FROM Sales.Customers;

-- We can use table aliases (shorthand)
SELECT 
    p.ProductName,
    p.Price
FROM Inventory.Products p;  -- 'p' is alias for Products

-- Multiple tables (preview - we'll learn this in Lesson 04)
SELECT 
    p.ProductName,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;


/*--------------------------------------------
   PART 4: WHERE CLAUSE
   Filter which rows to include
--------------------------------------------*/

-- Basic filter: Products over $100
SELECT 
    ProductName,
    Price
FROM Inventory.Products
WHERE Price > 100;

-- Text filter: Customers from USA
SELECT 
    FirstName,
    LastName,
    Country
FROM Sales.Customers
WHERE Country = 'USA';

-- Multiple conditions with AND
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Inventory.Products
WHERE Price > 50 AND StockQuantity > 20;

-- Multiple conditions with OR
SELECT 
    ProductName,
    Price
FROM Inventory.Products
WHERE Price < 30 OR Price > 1000;


/*--------------------------------------------
   PART 5: ORDER BY CLAUSE
   Sort the results
--------------------------------------------*/

-- Sort by price (lowest first)
SELECT 
    ProductName,
    Price
FROM Inventory.Products
ORDER BY Price;

-- Sort by price (highest first)
SELECT 
    ProductName,
    Price
FROM Inventory.Products
ORDER BY Price DESC;

-- Sort by multiple columns
SELECT 
    FirstName,
    LastName,
    City
FROM Sales.Customers
ORDER BY City, LastName;


/*--------------------------------------------
   PART 6: GROUP BY CLAUSE
   Group rows for aggregation
--------------------------------------------*/

-- Count products in each category
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID;

-- Average price by category
SELECT 
    CategoryID,
    AVG(Price) AS AveragePrice
FROM Inventory.Products
GROUP BY CategoryID;

-- Total stock quantity by category
SELECT 
    CategoryID,
    SUM(StockQuantity) AS TotalStock
FROM Inventory.Products
GROUP BY CategoryID;


/*--------------------------------------------
   PART 7: HAVING CLAUSE
   Filter grouped results
--------------------------------------------*/

-- Categories with more than 2 products
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID
HAVING COUNT(*) > 2;

-- Categories where average price is over $100
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 100;


/*--------------------------------------------
   PART 8: PUTTING IT ALL TOGETHER
   Combine multiple clauses
--------------------------------------------*/

-- Complex query example:
-- Find products over $50, group by category, show only categories 
-- with more than 1 product, sort by product count
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AveragePrice,
    MIN(Price) AS LowestPrice,
    MAX(Price) AS HighestPrice
FROM Inventory.Products
WHERE Price > 50
GROUP BY CategoryID
HAVING COUNT(*) > 1
ORDER BY ProductCount DESC;


/*--------------------------------------------
   PART 9: EXECUTION ORDER
   How SQL Server actually processes your query
--------------------------------------------*/

-- You write this order:
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
WHERE Price > 100
GROUP BY CategoryID
HAVING COUNT(*) > 1
ORDER BY ProductCount DESC;

-- SQL Server processes in this order:
-- 1. FROM    → Get the Products table
-- 2. WHERE   → Filter to Price > 100
-- 3. GROUP BY → Group by CategoryID
-- 4. HAVING  → Keep groups with count > 1
-- 5. SELECT  → Calculate COUNT(*)
-- 6. ORDER BY → Sort by ProductCount


/*--------------------------------------------
   PART 10: COMMON CLAUSE COMBINATIONS
   Typical patterns you'll use
--------------------------------------------*/

-- Pattern 1: Filter + Sort
SELECT 
    ProductName,
    Price
FROM Inventory.Products
WHERE Price > 100
ORDER BY Price DESC;

-- Pattern 2: Join + Filter + Sort
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 50
ORDER BY c.CategoryName, p.Price;

-- Pattern 3: Group + Aggregate + Filter Groups + Sort
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 75
ORDER BY AvgPrice DESC;


/*--------------------------------------------
   PART 11: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Get products over $200, sorted by price (highest first)
-- Write your query:


-- 2. Count how many customers are in each city
-- Write your query:


-- 3. Get employees with salary > 60000, sorted by salary
-- Write your query:


-- 4. Find categories with average product price > $100
-- Write your query:


-- 5. Complex: Get products over $50, group by CategoryID,
--    show only categories with 2+ products, sort by count
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ SELECT = what columns
   ✅ FROM = which table(s)
   ✅ WHERE = filter rows
   ✅ GROUP BY = group for aggregation
   ✅ HAVING = filter grouped results
   ✅ ORDER BY = sort results
   
   Remember the execution order!
   FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
   
   NEXT: Lesson 03 - SELECT Clause Deep Dive
============================================*/
