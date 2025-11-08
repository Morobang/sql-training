/*============================================
   LESSON 06: GROUP BY & HAVING
   Aggregating and summarizing data
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHY GROUP BY?
   Answering summary questions
--------------------------------------------*/

-- How many products do we have? (No GROUP BY needed)
SELECT COUNT(*) AS TotalProducts
FROM Inventory.Products;

-- How many products per category? (Need GROUP BY)
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID;


/*--------------------------------------------
   PART 2: AGGREGATE FUNCTIONS
   Functions that calculate across rows
--------------------------------------------*/

-- COUNT: How many rows
SELECT COUNT(*) AS TotalProducts FROM Inventory.Products;

-- SUM: Add up values
SELECT SUM(StockQuantity) AS TotalInventory FROM Inventory.Products;

-- AVG: Calculate average
SELECT AVG(Price) AS AveragePrice FROM Inventory.Products;

-- MIN: Find minimum
SELECT MIN(Price) AS CheapestProduct FROM Inventory.Products;

-- MAX: Find maximum
SELECT MAX(Price) AS MostExpensive FROM Inventory.Products;

-- Multiple aggregates together
SELECT 
    COUNT(*) AS TotalProducts,
    SUM(StockQuantity) AS TotalStock,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Inventory.Products;


/*--------------------------------------------
   PART 3: BASIC GROUP BY
   Group rows by a column
--------------------------------------------*/

-- Count products by category
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

-- Total inventory value by category
SELECT 
    CategoryID,
    SUM(Price * StockQuantity) AS TotalValue
FROM Inventory.Products
GROUP BY CategoryID;


/*--------------------------------------------
   PART 4: GROUP BY WITH JOINS
   Show descriptive names instead of IDs
--------------------------------------------*/

-- Products per category (with category names)
SELECT 
    c.CategoryName,
    COUNT(*) AS ProductCount
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;

-- Average price per category (with names)
SELECT 
    c.CategoryName,
    AVG(p.Price) AS AvgPrice,
    MIN(p.Price) AS MinPrice,
    MAX(p.Price) AS MaxPrice
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName;


/*--------------------------------------------
   PART 5: MULTIPLE AGGREGATES
   Calculate several summaries at once
--------------------------------------------*/

SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    SUM(StockQuantity) AS TotalStock,
    AVG(Price) AS AvgPrice,
    SUM(Price * StockQuantity) AS TotalInventoryValue
FROM Inventory.Products
GROUP BY CategoryID;


/*--------------------------------------------
   PART 6: GROUP BY MULTIPLE COLUMNS
   Create sub-groups
--------------------------------------------*/

-- Count customers by city and country
SELECT 
    Country,
    City,
    COUNT(*) AS CustomerCount
FROM Sales.Customers
GROUP BY Country, City
ORDER BY Country, City;

-- Products by category and supplier
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
WHERE SupplierID IS NOT NULL
GROUP BY CategoryID, SupplierID;


/*--------------------------------------------
   PART 7: HAVING CLAUSE
   Filter AFTER grouping (like WHERE for groups)
--------------------------------------------*/

-- Categories with more than 2 products
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID
HAVING COUNT(*) > 2;

-- Categories with average price over $100
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 100;

-- Categories with total inventory value over $5000
SELECT 
    CategoryID,
    SUM(Price * StockQuantity) AS TotalValue
FROM Inventory.Products
GROUP BY CategoryID
HAVING SUM(Price * StockQuantity) > 5000;


/*--------------------------------------------
   PART 8: WHERE vs HAVING
   When to use each
--------------------------------------------*/

-- WHERE: Filter individual rows BEFORE grouping
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
WHERE Price > 50  -- Filter products first
GROUP BY CategoryID;

-- HAVING: Filter groups AFTER aggregation
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 100;  -- Filter categories

-- BOTH: Filter products, then filter groups
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Inventory.Products
WHERE Price > 50          -- Only products over $50
GROUP BY CategoryID
HAVING COUNT(*) > 2;      -- Only categories with 2+ products


/*--------------------------------------------
   PART 9: GROUP BY WITH ORDER BY
   Sort your grouped results
--------------------------------------------*/

-- Products per category, sorted by count (highest first)
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Inventory.Products
GROUP BY CategoryID
ORDER BY ProductCount DESC;

-- Average price by category, sorted by avg price
SELECT 
    c.CategoryName,
    AVG(p.Price) AS AvgPrice
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName
ORDER BY AvgPrice DESC;


/*--------------------------------------------
   PART 10: REAL-WORLD EXAMPLES
   Common reporting queries
--------------------------------------------*/

-- Total sales by customer
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(od.Quantity * od.UnitPrice) AS TotalSpent
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

-- Monthly order summary
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Sales.Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- Product performance report
SELECT 
    p.ProductName,
    COUNT(od.OrderDetailID) AS TimesSold,
    SUM(od.Quantity) AS TotalQuantitySold,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Inventory.Products p
LEFT JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalRevenue DESC;


/*--------------------------------------------
   PART 11: COUNT VARIATIONS
   Different ways to count
--------------------------------------------*/

-- Count all rows
SELECT COUNT(*) AS AllRows FROM Inventory.Products;

-- Count non-NULL values in a column
SELECT COUNT(SupplierID) AS WithSupplier FROM Inventory.Products;

-- Count distinct values
SELECT COUNT(DISTINCT CategoryID) AS UniqueCategories 
FROM Inventory.Products;

-- Compare different counts
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(SupplierID) AS WithSupplier,
    COUNT(*) - COUNT(SupplierID) AS WithoutSupplier,
    COUNT(DISTINCT CategoryID) AS UniqueCategories
FROM Inventory.Products;


/*--------------------------------------------
   PART 12: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Count how many products are in each category
-- Write your query:


-- 2. Find the total stock quantity by category
-- Write your query:


-- 3. Calculate average salary by department (with department names)
-- Write your query:


-- 4. Find categories with more than 3 products
-- Write your query:


-- 5. Find categories where average price is over $200
-- Write your query:


-- 6. Count orders per customer, show only customers with 2+ orders
-- Write your query:


-- 7. Find total revenue by product (only products sold at least once)
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ GROUP BY groups rows for aggregation
   ✅ Common aggregates: COUNT, SUM, AVG, MIN, MAX
   ✅ HAVING filters groups (after GROUP BY)
   ✅ WHERE filters rows (before GROUP BY)
   ✅ Can GROUP BY multiple columns
   ✅ Use JOIN to show names instead of IDs
   
   Execution Order:
   FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
   
   NEXT: Lesson 07 - ORDER BY Clause
============================================*/
