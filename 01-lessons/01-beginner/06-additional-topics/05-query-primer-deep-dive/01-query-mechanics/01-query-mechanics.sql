/*============================================
   LESSON 01: QUERY MECHANICS
   How SQL queries actually work
   
   Estimated Time: 10 minutes
   Difficulty: Beginner
============================================*/

-- Make sure we're using the RetailStore database
USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS A QUERY?
   A query is a request for data from a database
--------------------------------------------*/

-- The simplest query: Get everything from a table
SELECT * FROM Inventory.Categories;

-- What just happened?
-- 1. SQL Server read the Categories table
-- 2. It retrieved ALL rows
-- 3. It retrieved ALL columns
-- 4. It sent the results to you


/*--------------------------------------------
   PART 2: QUERY EXECUTION FLOW
   Understanding how queries are processed
--------------------------------------------*/

-- Step-by-step execution:

-- STEP 1: SQL Server finds the table
SELECT * FROM Inventory.Products;

-- STEP 2: It reads the data
-- STEP 3: It applies any filters (WHERE - we'll learn this soon)
-- STEP 4: It selects the columns you asked for
-- STEP 5: It returns the results


/*--------------------------------------------
   PART 3: SELECTING SPECIFIC COLUMNS
   You don't always need ALL columns
--------------------------------------------*/

-- Get just product names
SELECT ProductName 
FROM Inventory.Products;

-- Get two columns
SELECT ProductName, Price 
FROM Inventory.Products;

-- Get multiple columns (readable format)
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Inventory.Products;


/*--------------------------------------------
   PART 4: LIMITING RESULTS WITH TOP
   Don't retrieve more data than you need
--------------------------------------------*/

-- Get first 5 products
SELECT TOP 5 * 
FROM Inventory.Products;

-- Get first 3 customers
SELECT TOP 3 
    FirstName,
    LastName,
    Email
FROM Sales.Customers;


/*--------------------------------------------
   PART 5: COLUMN ALIASES
   Give columns friendly names in results
--------------------------------------------*/

-- Use 'AS' to rename columns in output
SELECT 
    ProductName AS [Product],
    Price AS [Cost],
    StockQuantity AS [In Stock]
FROM Inventory.Products;

-- Without 'AS' (also works)
SELECT 
    FirstName [First Name],
    LastName [Last Name],
    Email [Email Address]
FROM Sales.Customers;


/*--------------------------------------------
   PART 6: BASIC CALCULATIONS
   You can do math in SELECT
--------------------------------------------*/

-- Calculate 15% tax on each product
SELECT 
    ProductName,
    Price,
    Price * 0.15 AS Tax,
    Price * 1.15 AS [Price With Tax]
FROM Inventory.Products;

-- Calculate total inventory value per product
SELECT 
    ProductName,
    Price,
    StockQuantity,
    Price * StockQuantity AS [Total Inventory Value]
FROM Inventory.Products;


/*--------------------------------------------
   PART 7: CONCATENATING TEXT
   Combine text columns together
--------------------------------------------*/

-- Combine first and last name
SELECT 
    FirstName + ' ' + LastName AS [Full Name],
    Email
FROM Sales.Customers;

-- Create formatted employee info
SELECT 
    FirstName + ' ' + LastName AS [Employee Name],
    'Department: ' + CAST(DepartmentID AS VARCHAR) AS [Dept Info],
    '$' + CAST(Salary AS VARCHAR) AS [Salary Info]
FROM HR.Employees;


/*--------------------------------------------
   PART 8: DISTINCT VALUES
   Remove duplicate results
--------------------------------------------*/

-- See all cities (with duplicates if customers share cities)
SELECT City 
FROM Sales.Customers;

-- See unique cities only
SELECT DISTINCT City 
FROM Sales.Customers;

-- See unique countries
SELECT DISTINCT Country 
FROM Sales.Customers;


/*--------------------------------------------
   PART 9: QUERY FORMATTING MATTERS
   Good formatting = readable queries
--------------------------------------------*/

-- BAD: Hard to read
SELECT ProductName,Price,StockQuantity FROM Inventory.Products WHERE CategoryID=1;

-- GOOD: Easy to read
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Inventory.Products
WHERE CategoryID = 1;


/*--------------------------------------------
   PART 10: PRACTICE - YOUR TURN!
   Try these on your own:
--------------------------------------------*/

-- 1. Get all suppliers (all columns)
-- Write your query here:


-- 2. Get just department names from HR.Departments
-- Write your query here:


-- 3. Get first 10 orders with OrderID and OrderDate
-- Write your query here:


-- 4. Show employee full names (FirstName + LastName) with their salary
-- Write your query here:


-- 5. Calculate a 20% discount on all products (show original and discounted price)
-- Write your query here:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ SELECT retrieves data from tables
   ✅ Use TOP to limit results
   ✅ Use AS to rename columns
   ✅ You can calculate in SELECT
   ✅ DISTINCT removes duplicates
   ✅ Format queries for readability
   
   NEXT: Lesson 02 - Query Clauses
============================================*/
