/*============================================
   LESSON 07: ORDER BY CLAUSE
   Sorting your query results
   
   Estimated Time: 10 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: BASIC SORTING
   Order results by a column
--------------------------------------------*/

-- Sort by price (lowest to highest)
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY Price;

-- Sort by price (highest to lowest)
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY Price DESC;

-- Sort by product name alphabetically
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY ProductName;

-- Sort by product name (reverse alphabetical)
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY ProductName DESC;


/*--------------------------------------------
   PART 2: ASC vs DESC
   Ascending and Descending order
--------------------------------------------*/

-- ASC = Ascending (default) - A to Z, 1 to 9, oldest to newest
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY Price ASC;  -- Same as just ORDER BY Price

-- DESC = Descending - Z to A, 9 to 1, newest to oldest
SELECT ProductName, Price
FROM Inventory.Products
ORDER BY Price DESC;


/*--------------------------------------------
   PART 3: SORTING BY MULTIPLE COLUMNS
   Primary sort, then secondary sort
--------------------------------------------*/

-- Sort by CategoryID first, then by Price
SELECT 
    ProductName,
    CategoryID,
    Price
FROM Inventory.Products
ORDER BY CategoryID, Price;

-- Sort by CategoryID (asc), then Price (desc)
SELECT 
    ProductName,
    CategoryID,
    Price
FROM Inventory.Products
ORDER BY CategoryID ASC, Price DESC;

-- Real example: Customers by Country, then City, then LastName
SELECT 
    FirstName,
    LastName,
    City,
    Country
FROM Sales.Customers
ORDER BY Country, City, LastName;


/*--------------------------------------------
   PART 4: SORTING BY COLUMN POSITION
   Reference columns by number (not recommended)
--------------------------------------------*/

-- Sort by 2nd column (Price)
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
ORDER BY 2;  -- Column 2 = Price

-- Sort by multiple positions
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
ORDER BY 2 DESC, 1 ASC;  -- Price desc, ProductName asc

-- Better: Use column names (more readable)
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
ORDER BY Price DESC, ProductName ASC;


/*--------------------------------------------
   PART 5: SORTING BY ALIAS
   Sort by calculated or aliased columns
--------------------------------------------*/

-- Sort by calculated column
SELECT 
    ProductName,
    Price,
    Price * 1.15 AS PriceWithTax
FROM Inventory.Products
ORDER BY PriceWithTax DESC;

-- Sort by concatenated column
SELECT 
    FirstName + ' ' + LastName AS FullName,
    Email
FROM Sales.Customers
ORDER BY FullName;

-- Sort by CASE result
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 200 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory
FROM Inventory.Products
ORDER BY PriceCategory;


/*--------------------------------------------
   PART 6: SORTING WITH TOP
   Get the first N results after sorting
--------------------------------------------*/

-- Top 5 most expensive products
SELECT TOP 5
    ProductName,
    Price
FROM Inventory.Products
ORDER BY Price DESC;

-- Top 3 cheapest products
SELECT TOP 3
    ProductName,
    Price
FROM Inventory.Products
ORDER BY Price ASC;

-- Top 10 newest orders
SELECT TOP 10
    OrderID,
    OrderDate,
    CustomerID
FROM Sales.Orders
ORDER BY OrderDate DESC;


/*--------------------------------------------
   PART 7: SORTING WITH PERCENTAGES
   Get top percentage of results
--------------------------------------------*/

-- Top 10% of products by price
SELECT TOP 10 PERCENT
    ProductName,
    Price
FROM Inventory.Products
ORDER BY Price DESC;

-- Top 25% of customers by order count
SELECT TOP 25 PERCENT
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY OrderCount DESC;


/*--------------------------------------------
   PART 8: SORTING NULL VALUES
   Where do NULLs appear in sorted results?
--------------------------------------------*/

-- NULLs appear FIRST in ascending order
SELECT ProductName, SupplierID
FROM Inventory.Products
ORDER BY SupplierID;

-- NULLs appear LAST in descending order
SELECT ProductName, SupplierID
FROM Inventory.Products
ORDER BY SupplierID DESC;

-- Sort with NULLs explicitly handled
SELECT 
    ProductName,
    ISNULL(SupplierID, 9999) AS SupplierID
FROM Inventory.Products
ORDER BY SupplierID;


/*--------------------------------------------
   PART 9: SORTING WITH JOINS
   Sort results from joined tables
--------------------------------------------*/

-- Products with categories, sorted by category then price
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY c.CategoryName, p.Price DESC;

-- Customer orders sorted by customer name, then date
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderID,
    o.OrderDate
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
ORDER BY CustomerName, o.OrderDate DESC;


/*--------------------------------------------
   PART 10: SORTING GROUPED RESULTS
   ORDER BY with GROUP BY
--------------------------------------------*/

-- Products per category, sorted by count
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID
ORDER BY ProductCount DESC;

-- Average price by category, sorted by average
SELECT 
    c.CategoryName,
    AVG(p.Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName
ORDER BY AvgPrice DESC;


/*--------------------------------------------
   PART 11: COMPLEX SORTING SCENARIOS
   Advanced sorting patterns
--------------------------------------------*/

-- Custom sort order with CASE
SELECT 
    ProductName,
    CategoryID,
    Price
FROM Inventory.Products
ORDER BY 
    CASE CategoryID
        WHEN 1 THEN 1  -- Electronics first
        WHEN 2 THEN 2  -- Furniture second
        ELSE 3         -- Everything else last
    END,
    Price DESC;

-- Sort by calculation
SELECT 
    ProductName,
    Price,
    StockQuantity,
    Price * StockQuantity AS InventoryValue
FROM Inventory.Products
ORDER BY InventoryValue DESC;

-- Multi-level sorting with different directions
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price,
    p.StockQuantity
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY 
    c.CategoryName ASC,      -- Category A-Z
    p.Price DESC,            -- Price high-low within category
    p.ProductName ASC;       -- Name A-Z for same price


/*--------------------------------------------
   PART 12: SORTING DATES AND TIMES
   Common date sorting patterns
--------------------------------------------*/

-- Orders from oldest to newest
SELECT OrderID, OrderDate
FROM Sales.Orders
ORDER BY OrderDate ASC;

-- Orders from newest to oldest (most common)
SELECT OrderID, OrderDate
FROM Sales.Orders
ORDER BY OrderDate DESC;

-- Sort by year, then month
SELECT 
    OrderID,
    OrderDate,
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth
FROM Sales.Orders
ORDER BY YEAR(OrderDate) DESC, MONTH(OrderDate) DESC;


/*--------------------------------------------
   PART 13: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Show all products sorted by price (cheapest first)
-- Write your query:


-- 2. Show top 10 most expensive products
-- Write your query:


-- 3. Show customers sorted by country, then city, then last name
-- Write your query:


-- 4. Show products with categories, sorted by category name, then product name
-- Write your query:


-- 5. Show categories with product counts, sorted by count (highest first)
-- Write your query:


-- 6. Show products sorted by inventory value (Price * StockQuantity) descending
-- Write your query:


-- 7. Show most recent 5 orders
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ ORDER BY sorts query results
   ✅ ASC = ascending (default), DESC = descending
   ✅ Can sort by multiple columns
   ✅ ORDER BY happens LAST in query execution
   ✅ Can sort by aliases and calculated columns
   ✅ TOP works with ORDER BY to limit results
   ✅ NULLs sort first (ASC) or last (DESC)
   
   Common Patterns:
   - ORDER BY Price DESC          → Most expensive first
   - ORDER BY OrderDate DESC      → Most recent first
   - ORDER BY LastName            → Alphabetical
   - ORDER BY Category, Price     → Group, then sort within
   
   NEXT: Lesson 08 - Practice Exercises
============================================*/
