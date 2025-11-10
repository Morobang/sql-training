/*============================================
   LESSON 01: WHAT IS A JOIN?
   Understanding table relationships
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: THE PROBLEM - DATA IN SEPARATE TABLES
   Why do we need JOINs?
--------------------------------------------*/

-- Products table has CategoryID, not CategoryName
SELECT ProductID, ProductName, CategoryID FROM Inventory.Products;

-- Categories table has CategoryName
SELECT CategoryID, CategoryName FROM Inventory.Categories;

-- We want BOTH ProductName AND CategoryName in one result!
-- That's where JOINs come in...

/*--------------------------------------------
   PART 2: WHAT IS A JOIN?
   Combining rows from two or more tables
--------------------------------------------*/

/*
   A JOIN combines rows from two tables based on a related column.
   
   Products Table:          Categories Table:
   ┌────┬─────────┬────┐   ┌────┬──────────────┐
   │ ID │  Name   │Cat │   │ ID │     Name     │
   ├────┼─────────┼────┤   ├────┼──────────────┤
   │ 1  │ Laptop  │ 1  │───│ 1  │ Electronics  │
   │ 2  │ Mouse   │ 1  │───│ 2  │ Books        │
   │ 3  │ Novel   │ 2  │   │ 3  │ Clothing     │
   └────┴─────────┴────┘   └────┴──────────────┘
                ↑                 ↑
           Foreign Key      Primary Key
           
   JOIN ON Products.CategoryID = Categories.CategoryID
   
   Result:
   ┌────┬─────────┬────┬──────────────┐
   │ ID │  Name   │Cat │ CategoryName │
   ├────┼─────────┼────┼──────────────┤
   │ 1  │ Laptop  │ 1  │ Electronics  │
   │ 2  │ Mouse   │ 1  │ Electronics  │
   │ 3  │ Novel   │ 2  │ Books        │
   └────┴─────────┴────┴──────────────┘
*/

/*--------------------------------------------
   PART 3: YOUR FIRST JOIN
   Combining Products and Categories
--------------------------------------------*/

-- Basic JOIN syntax
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Let's break it down:
-- FROM Products p              ← Main table with alias 'p'
-- INNER JOIN Categories c      ← Join to Categories with alias 'c'
-- ON p.CategoryID = c.CategoryID  ← Match condition (how tables relate)

/*--------------------------------------------
   PART 4: WHY USE TABLE ALIASES?
   Making queries shorter and clearer
--------------------------------------------*/

-- WITHOUT aliases (verbose and repetitive)
SELECT 
    Products.ProductID,
    Products.ProductName,
    Categories.CategoryName
FROM Inventory.Products
INNER JOIN Inventory.Categories ON Products.CategoryID = Categories.CategoryID;

-- WITH aliases (clean and readable)
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

/*--------------------------------------------
   PART 5: UNDERSTANDING FOREIGN KEYS
   How tables relate to each other
--------------------------------------------*/

-- Products.CategoryID is a FOREIGN KEY
-- It references Categories.CategoryID (PRIMARY KEY)

-- View the relationship
SELECT 
    p.ProductName,
    p.CategoryID AS 'Foreign Key in Products',
    c.CategoryID AS 'Primary Key in Categories',
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

/*--------------------------------------------
   PART 6: JOIN WITH SUPPLIERS
   Another relationship example
--------------------------------------------*/

-- Products → Suppliers relationship
SELECT 
    p.ProductName,
    p.Price,
    s.SupplierName,
    s.ContactName
FROM Inventory.Products p
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Notice: Only products WITH a supplier are shown
-- Products with NULL SupplierID are excluded (INNER JOIN behavior)

/*--------------------------------------------
   PART 7: INNER JOIN BEHAVIOR
   Only returns matching rows
--------------------------------------------*/

-- INNER JOIN only returns rows where there's a match in BOTH tables

-- Example: If a product has no supplier (SupplierID = NULL)
-- it won't appear in the result

-- Count all products
SELECT COUNT(*) AS TotalProducts FROM Inventory.Products;

-- Count products with suppliers
SELECT COUNT(*) AS ProductsWithSuppliers 
FROM Inventory.Products p
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- The difference = products without suppliers

/*--------------------------------------------
   PART 8: SELECTING SPECIFIC COLUMNS
   Choose what to display
--------------------------------------------*/

-- Only show what you need
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Add WHERE clause to filter
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;

-- Add ORDER BY to sort
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100
ORDER BY p.Price DESC;

/*--------------------------------------------
   PART 9: CUSTOMERS AND ORDERS
   Sales schema relationships
--------------------------------------------*/

-- Customers → Orders relationship
SELECT 
    c.FirstName,
    c.LastName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID;

-- With filtering and sorting
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2025-01-01'
ORDER BY o.OrderDate DESC;

/*--------------------------------------------
   PART 10: COMMON JOIN MISTAKES
   What NOT to do
--------------------------------------------*/

-- ❌ MISTAKE 1: Forgetting the ON clause
-- SELECT * FROM Products p INNER JOIN Categories c;  -- ERROR!

-- ❌ MISTAKE 2: Ambiguous column names
-- SELECT ProductID FROM Products p 
-- INNER JOIN OrderDetails od ON p.ProductID = od.ProductID;  -- Which ProductID?

-- ✅ CORRECT: Always specify table/alias
SELECT p.ProductID FROM Inventory.Products p 
INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID;

-- ❌ MISTAKE 3: Wrong join condition
-- SELECT * FROM Products p 
-- INNER JOIN Categories c ON p.ProductID = c.CategoryID;  -- Wrong columns!

-- ✅ CORRECT: Join on related columns
SELECT * FROM Inventory.Products p 
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

/*--------------------------------------------
   PART 11: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Product Catalog with Categories
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price,
    p.StockQuantity
FROM Inventory.Categories c
INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
ORDER BY c.CategoryName, p.ProductName;

-- Example 2: Customer Order History
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

-- Example 3: Products and Suppliers with Contact Info
SELECT 
    p.ProductName,
    p.Price,
    s.SupplierName,
    s.ContactName,
    s.Phone
FROM Inventory.Products p
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity < 20
ORDER BY p.ProductName;

/*--------------------------------------------
   PART 12: KEY CONCEPTS SUMMARY
--------------------------------------------*/

/*
   1. JOIN combines rows from multiple tables
   2. INNER JOIN returns only matching rows
   3. JOIN ON specifies how tables relate
   4. Foreign Key → Primary Key relationship
   5. Use aliases for cleaner queries
   6. Always specify table/alias for columns
   
   Basic Syntax:
   SELECT columns
   FROM table1 alias1
   INNER JOIN table2 alias2 ON alias1.fk = alias2.pk
   WHERE conditions
   ORDER BY columns;
*/

/*--------------------------------------------
   PART 13: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. List all products with their category names

-- 2. Show customers who have placed orders

-- 3. Display products with their supplier names (only products that have suppliers)

-- 4. Find all orders with customer names, ordered by date

-- 5. Show products priced over $200 with category and supplier information

/*============================================
   NEXT: Lesson 02 - Cartesian Product
   (What happens when you forget ON!)
============================================*/
