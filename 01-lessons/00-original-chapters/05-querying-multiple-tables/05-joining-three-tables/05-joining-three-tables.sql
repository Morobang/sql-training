/*============================================
   LESSON 05: JOINING THREE OR MORE TABLES
   Building complex multi-table queries
   
   Estimated Time: 20 minutes
   Difficulty: Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHY JOIN MULTIPLE TABLES?
   Real-world data is interconnected
--------------------------------------------*/

/*
   Common scenarios requiring 3+ table joins:
   
   1. Order Report:
      Customers → Orders → OrderDetails → Products
      
   2. Product Catalog:
      Products → Categories → Suppliers
      
   3. Employee Structure:
      Employees → Departments → Managers
      
   4. Sales Analysis:
      Orders → Customers → Products → Categories
*/

/*--------------------------------------------
   PART 2: JOINING THREE TABLES
   Basic pattern
--------------------------------------------*/

-- Products with Category and Supplier information
SELECT 
    p.ProductName,
    c.CategoryName,
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Pattern:
-- FROM table1
-- INNER JOIN table2 ON condition1
-- INNER JOIN table3 ON condition2
-- Each JOIN adds another table to the result

/*--------------------------------------------
   PART 3: UNDERSTANDING THE JOIN CHAIN
   How SQL processes multiple joins
--------------------------------------------*/

/*
   Join Execution Flow:
   
   Step 1: Products INNER JOIN Categories
           ↓
   Intermediate Result 1
           ↓
   Step 2: (Result 1) INNER JOIN Suppliers
           ↓
   Final Result
   
   Each join builds on the previous result
*/

-- Visualize the chain
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,          -- Links to Categories
    c.CategoryName,
    p.SupplierID,          -- Links to Suppliers
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

/*--------------------------------------------
   PART 4: FOUR TABLE JOIN
   Customer orders with product details
--------------------------------------------*/

-- Complete order information
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
ORDER BY o.OrderDate DESC, o.OrderID;

-- Join chain: Customers → Orders → OrderDetails → Products

/*--------------------------------------------
   PART 5: FIVE TABLE JOIN
   Maximum detail level
--------------------------------------------*/

-- Complete sales report with everything
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    od.UnitPrice,
    s.SupplierName
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
ORDER BY o.OrderDate DESC;

-- Join chain: Customers → Orders → OrderDetails → Products → Categories
--             (+ Products → Suppliers)

/*--------------------------------------------
   PART 6: JOIN ORDER MATTERS
   Different starting points
--------------------------------------------*/

-- Starting from Products
SELECT cat.CategoryName, p.ProductName, s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Starting from Categories
SELECT cat.CategoryName, p.ProductName, s.SupplierName
FROM Inventory.Categories cat
INNER JOIN Inventory.Products p ON cat.CategoryID = p.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Both work! Choose the starting table that makes sense for your query

/*--------------------------------------------
   PART 7: ADDING WHERE CLAUSE
   Filtering multi-table joins
--------------------------------------------*/

-- Filter on multiple tables
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
WHERE o.OrderDate >= '2025-01-01'                    -- Filter Orders
  AND cat.CategoryName = 'Electronics'                -- Filter Categories
  AND c.City = 'New York'                            -- Filter Customers
ORDER BY o.OrderDate DESC;

/*--------------------------------------------
   PART 8: AGGREGATES WITH MULTIPLE JOINS
   Grouping across tables
--------------------------------------------*/

-- Sales by category
SELECT 
    cat.CategoryName,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Inventory.Categories cat
INNER JOIN Inventory.Products p ON cat.CategoryID = p.CategoryID
INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Sales.Orders o ON od.OrderID = o.OrderID
GROUP BY cat.CategoryName
ORDER BY Revenue DESC;

-- Customer purchase patterns
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    cat.CategoryName,
    COUNT(DISTINCT o.OrderID) AS Orders,
    SUM(od.Quantity) AS Items,
    SUM(od.Quantity * od.UnitPrice) AS Spent
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY c.CustomerID, c.FirstName, c.LastName, cat.CategoryName
ORDER BY c.LastName, Spent DESC;

/*--------------------------------------------
   PART 9: BUILDING JOINS INCREMENTALLY
   Best practice approach
--------------------------------------------*/

-- Step 1: Start with one table
SELECT * FROM Sales.Customers;

-- Step 2: Add first join
SELECT c.*, o.*
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID;

-- Step 3: Add second join
SELECT c.*, o.*, od.*
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID;

-- Step 4: Add third join
SELECT c.*, o.*, od.*, p.*
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;

-- Step 5: Select only needed columns
SELECT 
    c.FirstName,
    c.LastName,
    o.OrderDate,
    p.ProductName,
    od.Quantity
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;

/*--------------------------------------------
   PART 10: COMMON PATTERNS
--------------------------------------------*/

-- Pattern 1: Hub and Spoke (Orders at center)
SELECT *
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID;

-- Pattern 2: Linear Chain (A→B→C→D)
SELECT *
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Pattern 3: Star Schema (Fact table with multiple dimensions)
SELECT *
FROM Sales.OrderDetails od                                    -- Fact
INNER JOIN Sales.Orders o ON od.OrderID = o.OrderID          -- Dimension
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID -- Dimension
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID; -- Dimension

/*--------------------------------------------
   PART 11: PERFORMANCE TIPS
--------------------------------------------*/

-- Tip 1: Join on indexed columns (usually PKs/FKs)
-- ✅ Good: Joining on primary/foreign keys
SELECT * FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID;

-- Tip 2: Filter early
-- ✅ Better: Filter before joining when possible
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;  -- Reduces rows before final result

-- Tip 3: Select only needed columns
-- ❌ Bad: SELECT *
-- ✅ Good: SELECT specific columns

/*--------------------------------------------
   PART 12: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Monthly Sales Report
SELECT 
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    cat.CategoryName,
    COUNT(DISTINCT o.OrderID) AS Orders,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Sales.Orders o
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
WHERE o.OrderDate >= DATEADD(MONTH, -12, GETDATE())
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), cat.CategoryName
ORDER BY Year DESC, Month DESC, Revenue DESC;

-- Example 2: Customer Lifetime Value
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    c.Email,
    MIN(o.OrderDate) AS FirstOrder,
    MAX(o.OrderDate) AS LastOrder,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT p.ProductID) AS UniqueProducts,
    SUM(od.Quantity * od.UnitPrice) AS LifetimeValue
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email
HAVING COUNT(DISTINCT o.OrderID) > 1
ORDER BY LifetimeValue DESC;

-- Example 3: Product Performance by Supplier
SELECT 
    s.SupplierName,
    cat.CategoryName,
    p.ProductName,
    COUNT(DISTINCT o.OrderID) AS TimesSold,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS Revenue,
    AVG(od.UnitPrice) AS AvgSellingPrice
FROM Inventory.Suppliers s
INNER JOIN Inventory.Products p ON s.SupplierID = p.SupplierID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Sales.Orders o ON od.OrderID = o.OrderID
WHERE o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
GROUP BY s.SupplierID, s.SupplierName, cat.CategoryName, p.ProductID, p.ProductName
HAVING SUM(od.Quantity) > 10
ORDER BY s.SupplierName, Revenue DESC;

/*--------------------------------------------
   PART 13: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. Join Customers, Orders, and OrderDetails to show all order line items

-- 2. Create a report showing Products, Categories, Suppliers, and current stock

-- 3. Find total revenue by customer and category (4-table join)

-- 4. Show all orders with customer info, product info, and category (5 tables)

-- 5. Calculate which supplier provides the most profitable products

-- 6. Find customers who bought products from specific categories

/*============================================
   KEY CONCEPTS
============================================*/

/*
   Joining Multiple Tables:
   
   1. Build incrementally (add one join at a time)
   2. Test each join before adding the next
   3. Use clear aliases
   4. Comment complex joins
   5. Format for readability
   
   Pattern:
   SELECT columns
   FROM table1 t1
   INNER JOIN table2 t2 ON t1.fk1 = t2.pk
   INNER JOIN table3 t3 ON t2.fk2 = t3.pk
   INNER JOIN table4 t4 ON t3.fk3 = t4.pk
   WHERE filters
   GROUP BY columns
   ORDER BY columns;
*/

/*============================================
   NEXT: Lesson 06 - Subqueries as Tables
   (Using SELECT results as virtual tables)
============================================*/
