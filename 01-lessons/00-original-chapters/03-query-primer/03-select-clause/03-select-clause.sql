/*============================================
   LESSON 03: SELECT CLAUSE DEEP DIVE
   Advanced SELECT techniques
   
   Estimated Time: 10 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: SELECT VARIATIONS
   Different ways to select columns
--------------------------------------------*/

-- All columns
SELECT * FROM Inventory.Products;

-- Specific columns (best practice)
SELECT 
    ProductName,
    Price,
    StockQuantity
FROM Inventory.Products;

-- First N rows only
SELECT TOP 5 
    ProductName,
    Price
FROM Inventory.Products;

-- Top with percentage
SELECT TOP 10 PERCENT
    ProductName,
    Price
FROM Inventory.Products
ORDER BY Price DESC;


/*--------------------------------------------
   PART 2: COLUMN ALIASES
   Renaming columns in output
--------------------------------------------*/

-- Using AS keyword (recommended)
SELECT 
    ProductName AS Product,
    Price AS Cost,
    StockQuantity AS [In Stock]
FROM Inventory.Products;

-- Without AS (also works)
SELECT 
    ProductName Product,
    Price Cost
FROM Inventory.Products;

-- Aliases with spaces (use brackets)
SELECT 
    FirstName + ' ' + LastName AS [Full Name],
    Email AS [Email Address]
FROM Sales.Customers;


/*--------------------------------------------
   PART 3: CALCULATIONS IN SELECT
   Perform math and operations
--------------------------------------------*/

-- Basic arithmetic
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS [Price + 15% Tax],
    Price * 0.85 AS [15% Discount Price]
FROM Inventory.Products;

-- Multiple calculations
SELECT 
    ProductName,
    Price,
    StockQuantity,
    Price * StockQuantity AS [Total Inventory Value],
    (Price * StockQuantity) * 0.10 AS [10% of Inventory Value]
FROM Inventory.Products;

-- Order matters with parentheses
SELECT 
    ProductName,
    Price,
    Price * 1.15 + 5 AS [Wrong: Tax then add],
    Price * (1.15 + 5) AS [Wrong: Add then multiply],
    (Price * 1.15) + 5 AS [Correct: Tax then shipping]
FROM Inventory.Products;


/*--------------------------------------------
   PART 4: STRING CONCATENATION
   Combining text columns
--------------------------------------------*/

-- Combine first and last name
SELECT 
    FirstName + ' ' + LastName AS FullName,
    Email
FROM Sales.Customers;

-- Create formatted strings
SELECT 
    'Customer: ' + FirstName + ' ' + LastName AS CustomerInfo,
    'Email: ' + Email AS EmailInfo
FROM Sales.Customers;

-- Combine multiple fields
SELECT 
    FirstName + ' ' + LastName + ' (' + Email + ')' AS [Complete Info],
    City + ', ' + Country AS Location
FROM Sales.Customers;


/*--------------------------------------------
   PART 5: CONVERTING DATA TYPES
   Change column types for concatenation
--------------------------------------------*/

-- CAST function
SELECT 
    ProductName,
    'Price: $' + CAST(Price AS VARCHAR(10)) AS PriceLabel
FROM Inventory.Products;

-- CONVERT function (SQL Server specific)
SELECT 
    ProductName,
    'Stock: ' + CONVERT(VARCHAR(10), StockQuantity) AS StockLabel
FROM Inventory.Products;

-- Formatting dates
SELECT 
    OrderID,
    'Order Date: ' + CONVERT(VARCHAR(20), OrderDate, 101) AS FormattedDate
FROM Sales.Orders;


/*--------------------------------------------
   PART 6: CASE EXPRESSIONS
   Conditional logic in SELECT
--------------------------------------------*/

-- Simple CASE: Categorize by price
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 200 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory
FROM Inventory.Products;

-- CASE with multiple conditions
SELECT 
    ProductName,
    Price,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'Out of Stock'
        WHEN StockQuantity < 10 THEN 'Low Stock'
        WHEN StockQuantity < 50 THEN 'Normal Stock'
        ELSE 'High Stock'
    END AS StockStatus
FROM Inventory.Products;

-- Multiple CASE expressions
SELECT 
    FirstName,
    LastName,
    CASE 
        WHEN Country = 'USA' THEN 'Domestic'
        ELSE 'International'
    END AS CustomerType,
    CASE 
        WHEN City = 'New York' THEN 'NY'
        WHEN City = 'Los Angeles' THEN 'LA'
        ELSE City
    END AS CityCode
FROM Sales.Customers;


/*--------------------------------------------
   PART 7: AGGREGATE FUNCTIONS
   Calculate summary values
--------------------------------------------*/

-- Count all rows
SELECT COUNT(*) AS TotalProducts
FROM Inventory.Products;

-- Count non-NULL values in a column
SELECT COUNT(SupplierID) AS ProductsWithSupplier
FROM Inventory.Products;

-- Sum
SELECT SUM(StockQuantity) AS TotalInventory
FROM Inventory.Products;

-- Average
SELECT AVG(Price) AS AveragePrice
FROM Inventory.Products;

-- Min and Max
SELECT 
    MIN(Price) AS CheapestProduct,
    MAX(Price) AS MostExpensive
FROM Inventory.Products;

-- Multiple aggregates
SELECT 
    COUNT(*) AS TotalProducts,
    SUM(StockQuantity) AS TotalStock,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Inventory.Products;


/*--------------------------------------------
   PART 8: DISTINCT VALUES
   Remove duplicates
--------------------------------------------*/

-- All cities (with duplicates)
SELECT City FROM Sales.Customers;

-- Unique cities only
SELECT DISTINCT City FROM Sales.Customers;

-- Distinct combinations
SELECT DISTINCT City, Country 
FROM Sales.Customers;

-- Count distinct values
SELECT COUNT(DISTINCT City) AS UniqueCities
FROM Sales.Customers;


/*--------------------------------------------
   PART 9: NULL HANDLING
   Working with missing values
--------------------------------------------*/

-- Find NULL values
SELECT 
    ProductName,
    SupplierID
FROM Inventory.Products
WHERE SupplierID IS NULL;

-- Replace NULL with default value (ISNULL)
SELECT 
    ProductName,
    ISNULL(SupplierID, 0) AS SupplierID
FROM Inventory.Products;

-- Replace NULL with default (COALESCE - more flexible)
SELECT 
    ProductName,
    COALESCE(SupplierID, 999) AS SupplierID
FROM Inventory.Products;


/*--------------------------------------------
   PART 10: SUBQUERIES IN SELECT
   Using queries within queries
--------------------------------------------*/

-- Compare each product to average price
SELECT 
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Inventory.Products) AS AvgPrice,
    Price - (SELECT AVG(Price) FROM Inventory.Products) AS DifferenceFromAvg
FROM Inventory.Products;

-- Count related records
SELECT 
    c.CategoryName,
    (SELECT COUNT(*) 
     FROM Inventory.Products p 
     WHERE p.CategoryID = c.CategoryID) AS ProductCount
FROM Inventory.Categories c;


/*--------------------------------------------
   PART 11: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Create a formatted product list with "Product: [Name] - Price: $[Price]"
-- Write your query:


-- 2. Categorize employees by salary:
--    < 60000 = 'Entry Level'
--    60000-80000 = 'Mid Level'  
--    > 80000 = 'Senior Level'
-- Write your query:


-- 3. Calculate inventory value for each product (Price * StockQuantity)
--    and show percentage of total inventory value
-- Write your query:


-- 4. Show customer info with NULL cities replaced with 'Unknown'
-- Write your query:


-- 5. List products with stock status:
--    'CRITICAL' if < 10
--    'LOW' if < 50
--    'GOOD' if >= 50
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ SELECT can do calculations, not just retrieve
   ✅ Use CASE for conditional logic
   ✅ Concatenate strings with +
   ✅ Use CAST/CONVERT to change data types
   ✅ Handle NULLs with ISNULL or COALESCE
   ✅ Aggregate functions: COUNT, SUM, AVG, MIN, MAX
   
   NEXT: Lesson 04 - FROM Clause & Joins
============================================*/
