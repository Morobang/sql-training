/*============================================
   LESSON 03: INNER JOINS
   Deep dive into matching rows
   
   Estimated Time: 20 minutes
   Difficulty: Beginner to Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: INNER JOIN DEFINITION
   Returns only matching rows from both tables
--------------------------------------------*/

/*
   INNER JOIN returns rows where there's a match in BOTH tables
   
   Products (5 rows)        Categories (3 rows)
   ┌────┬─────────┬────┐   ┌────┬──────────┐
   │ ID │  Name   │Cat │   │ ID │   Name   │
   ├────┼─────────┼────┤   ├────┼──────────┤
   │ 1  │ Laptop  │ 1  │───│ 1  │ Electron │
   │ 2  │ Mouse   │ 1  │───│ 2  │ Books    │
   │ 3  │ Novel   │ 2  │───│ 3  │ Clothing │
   │ 4  │ Shirt   │ 3  │   └────┴──────────┘
   │ 5  │ Camera  │NULL│  ← No category (excluded!)
   └────┴─────────┴────┘
   
   INNER JOIN result (4 rows):
   Only rows 1, 2, 3, 4 (row 5 excluded because CategoryID is NULL)
*/

/*--------------------------------------------
   PART 2: BASIC INNER JOIN SYNTAX
   The foundation
--------------------------------------------*/

-- Simple two-table join
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Breakdown:
-- FROM Products p          → Start with Products table
-- INNER JOIN Categories c  → Bring in Categories table
-- ON p.CategoryID = c.CategoryID → Match on CategoryID

/*--------------------------------------------
   PART 3: UNDERSTANDING THE ON CLAUSE
   How SQL finds matches
--------------------------------------------*/

-- The ON clause specifies the join condition
-- Format: table1.column = table2.column

-- Example: Products.CategoryID must equal Categories.CategoryID
SELECT 
    p.ProductName,
    p.CategoryID AS ProductCategory,
    c.CategoryID AS CategoryTableID,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Notice: ProductCategory always equals CategoryTableID (that's the match!)

/*--------------------------------------------
   PART 4: WHAT GETS EXCLUDED?
   Understanding INNER JOIN filtering
--------------------------------------------*/

-- Products WITH a category (INNER JOIN includes these)
SELECT 
    p.ProductName,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Products WITHOUT a category (INNER JOIN excludes these)
SELECT 
    p.ProductName,
    p.CategoryID
FROM Inventory.Products p
WHERE p.CategoryID IS NULL 
   OR p.CategoryID NOT IN (SELECT CategoryID FROM Inventory.Categories);

-- Compare row counts
SELECT 
    (SELECT COUNT(*) FROM Inventory.Products) AS AllProducts,
    (SELECT COUNT(*) FROM Inventory.Products p
     INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID) AS ProductsWithCategory;

/*--------------------------------------------
   PART 5: SELECTING COLUMNS
   Choosing what to display
--------------------------------------------*/

-- Select from both tables
SELECT 
    p.ProductName,      -- From Products
    p.Price,            -- From Products
    c.CategoryName      -- From Categories
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Use * carefully (gets ALL columns from BOTH tables)
SELECT *
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Better: Explicitly choose columns
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.StockQuantity,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

/*--------------------------------------------
   PART 6: ADDING WHERE CLAUSE
   Filtering joined results
--------------------------------------------*/

-- Join first, then filter
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;

-- Multiple filters
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.StockQuantity
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price BETWEEN 50 AND 500
  AND p.StockQuantity > 10;

-- Filter on joined table
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

/*--------------------------------------------
   PART 7: ORDER BY WITH JOINS
   Sorting joined results
--------------------------------------------*/

-- Sort by Products column
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY p.Price DESC;

-- Sort by Categories column
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY c.CategoryName, p.ProductName;

-- Multiple sort columns
SELECT 
    c.CategoryName,
    p.ProductName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY c.CategoryName ASC, p.Price DESC;

/*--------------------------------------------
   PART 8: AGGREGATES WITH JOINS
   Grouping and summarizing
--------------------------------------------*/

-- Count products per category
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount
FROM Inventory.Categories c
INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY ProductCount DESC;

-- Sum and average
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.Price) AS AvgPrice,
    MIN(p.Price) AS MinPrice,
    MAX(p.Price) AS MaxPrice,
    SUM(p.StockQuantity) AS TotalStock
FROM Inventory.Categories c
INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName;

-- Filter groups with HAVING
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.Price) AS AvgPrice
FROM Inventory.Categories c
INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
HAVING COUNT(p.ProductID) > 5;

/*--------------------------------------------
   PART 9: CALCULATED COLUMNS
   Creating new columns in joined results
--------------------------------------------*/

-- Concatenation
SELECT 
    p.ProductName + ' - ' + c.CategoryName AS ProductDescription,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Math calculations
SELECT 
    p.ProductName,
    p.Price,
    p.Price * 1.15 AS PriceWithTax,
    p.Price * 0.10 AS Commission
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- CASE expressions
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    CASE 
        WHEN p.Price < 50 THEN 'Budget'
        WHEN p.Price BETWEEN 50 AND 200 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

/*--------------------------------------------
   PART 10: PRODUCTS AND SUPPLIERS
   Another join example
--------------------------------------------*/

-- Basic join
SELECT 
    p.ProductName,
    p.Price,
    s.SupplierName,
    s.ContactName
FROM Inventory.Products p
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- With filtering
SELECT 
    p.ProductName,
    p.Price,
    s.SupplierName,
    s.Phone
FROM Inventory.Products p
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity < 20
ORDER BY p.StockQuantity ASC;

/*--------------------------------------------
   PART 11: CUSTOMERS AND ORDERS
   Sales schema joins
--------------------------------------------*/

-- Customer order history
SELECT 
    c.FirstName,
    c.LastName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.LastName, o.OrderDate;

-- Customer summary
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent,
    AVG(o.TotalAmount) AS AvgOrderValue,
    MAX(o.OrderDate) AS LastOrderDate
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

-- Recent orders
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    o.TotalAmount
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= DATEADD(MONTH, -3, GETDATE())
ORDER BY o.OrderDate DESC;

/*--------------------------------------------
   PART 12: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Inventory Report
SELECT 
    c.CategoryName,
    p.ProductName,
    p.StockQuantity,
    p.Price,
    p.StockQuantity * p.Price AS InventoryValue,
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity > 0
ORDER BY c.CategoryName, p.ProductName;

-- Example 2: Sales Performance
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS Revenue,
    MIN(o.OrderDate) AS FirstOrder,
    MAX(o.OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(o.OrderDate), MAX(o.OrderDate)) AS CustomerLifespanDays
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(o.OrderID) >= 2
ORDER BY Revenue DESC;

-- Example 3: Product Popularity
SELECT 
    p.ProductName,
    c.CategoryName,
    COUNT(od.OrderID) AS TimesSold,
    SUM(od.Quantity) AS TotalUnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName
ORDER BY TotalRevenue DESC;

/*--------------------------------------------
   PART 13: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. List all products with their category names, sorted by category then product name

-- 2. Show products that cost more than $200 with their supplier information

-- 3. Find customers who have placed orders, with order count and total spent

-- 4. Display products with low stock (< 15 units) including category and supplier

-- 5. Calculate average product price per category

-- 6. List all orders from the last 60 days with customer names

-- 7. Find the most expensive product in each category

-- 8. Show suppliers with the number of products they supply

/*============================================
   KEY CONCEPTS
============================================*/

/*
   INNER JOIN returns only matching rows
   
   Syntax:
   SELECT columns
   FROM table1 alias1
   INNER JOIN table2 alias2 ON alias1.column = alias2.column
   WHERE conditions
   GROUP BY columns
   HAVING conditions
   ORDER BY columns;
   
   ✅ Best Practices:
   • Use table aliases
   • Specify columns explicitly
   • Filter with WHERE after joining
   • Use meaningful join conditions
   • Test on small datasets first
*/

/*============================================
   NEXT: Lesson 04 - ANSI Join Syntax
   (Modern vs old-style joins)
============================================*/
