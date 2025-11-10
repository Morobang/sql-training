/*============================================
   LESSON 04: FROM CLAUSE & JOINS
   Combining data from multiple tables
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: SINGLE TABLE QUERIES (Review)
   The FROM clause with one table
--------------------------------------------*/

-- Simple FROM clause
SELECT * FROM Inventory.Products;

-- With table alias
SELECT 
    p.ProductName,
    p.Price
FROM Inventory.Products p;  -- 'p' is the alias

-- Why use aliases? Makes queries shorter and clearer
SELECT 
    p.ProductName,
    p.Price,
    p.StockQuantity
FROM Inventory.Products AS p;


/*--------------------------------------------
   PART 2: WHY JOIN TABLES?
   Data is stored in separate tables for efficiency
--------------------------------------------*/

-- Products table has CategoryID (just a number)
SELECT 
    ProductName,
    CategoryID  -- Just a number like 1, 2, 3
FROM Inventory.Products;

-- Categories table has CategoryName
SELECT 
    CategoryID,
    CategoryName  -- The actual name like 'Electronics'
FROM Inventory.Categories;

-- We need to JOIN them to see both!


/*--------------------------------------------
   PART 3: INNER JOIN - Most Common Join
   Returns only matching rows from both tables
--------------------------------------------*/

-- Basic INNER JOIN syntax
SELECT 
    p.ProductName,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- With more columns
SELECT 
    p.ProductName,
    p.Price,
    c.CategoryName,
    c.Description
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Join condition explained:
-- ON p.CategoryID = c.CategoryID
--    ↑ Products.CategoryID matches Categories.CategoryID


/*--------------------------------------------
   PART 4: INNER JOIN - Multiple Columns
   Show various information from both tables
--------------------------------------------*/

SELECT 
    p.ProductName,
    p.Price,
    p.StockQuantity,
    c.CategoryName,
    s.SupplierName,
    s.ContactEmail
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;


/*--------------------------------------------
   PART 5: LEFT JOIN (LEFT OUTER JOIN)
   Returns all rows from left table, matching from right
--------------------------------------------*/

-- Get ALL products, even those without a supplier
SELECT 
    p.ProductName,
    p.Price,
    s.SupplierName
FROM Inventory.Products p
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Products without supplier will show NULL for SupplierName


/*--------------------------------------------
   PART 6: RIGHT JOIN (RIGHT OUTER JOIN)
   Returns all rows from right table, matching from left
--------------------------------------------*/

-- Get ALL suppliers, even those with no products
SELECT 
    s.SupplierName,
    p.ProductName
FROM Inventory.Products p
RIGHT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- Suppliers without products will show NULL for ProductName


/*--------------------------------------------
   PART 7: FULL OUTER JOIN
   Returns all rows from both tables
--------------------------------------------*/

-- Get ALL products and ALL suppliers
SELECT 
    p.ProductName,
    s.SupplierName
FROM Inventory.Products p
FULL OUTER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;


/*--------------------------------------------
   PART 8: JOINING THREE TABLES
   Common pattern: connecting related data
--------------------------------------------*/

-- Products → Categories → AND → Suppliers
SELECT 
    p.ProductName,
    p.Price,
    c.CategoryName,
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;


/*--------------------------------------------
   PART 9: ORDERS EXAMPLE - Real-World Join
   Customers → Orders → OrderDetails → Products
--------------------------------------------*/

-- Simple: Orders with Customer names
SELECT 
    o.OrderID,
    o.OrderDate,
    c.FirstName + ' ' + c.LastName AS CustomerName
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID;

-- Complex: Order details with everything
SELECT 
    o.OrderID,
    o.OrderDate,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;


/*--------------------------------------------
   PART 10: CROSS JOIN (Cartesian Product)
   Every row from table 1 × every row from table 2
--------------------------------------------*/

-- WARNING: Creates MANY rows (use carefully!)
SELECT 
    c.CategoryName,
    s.SupplierName
FROM Inventory.Categories c
CROSS JOIN Inventory.Suppliers s;

-- If 3 categories × 4 suppliers = 12 rows


/*--------------------------------------------
   PART 11: SELF JOIN
   Join a table to itself
--------------------------------------------*/

-- Find employees and their managers
SELECT 
    emp.FirstName + ' ' + emp.LastName AS Employee,
    mgr.FirstName + ' ' + mgr.LastName AS Manager
FROM HR.Employees emp
LEFT JOIN HR.Employees mgr ON emp.ManagerID = mgr.EmployeeID;


/*--------------------------------------------
   PART 12: JOIN WITH WHERE
   Combine joins with filtering
--------------------------------------------*/

-- Products in Electronics category
SELECT 
    p.ProductName,
    p.Price,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Expensive products with category info
SELECT 
    p.ProductName,
    p.Price,
    c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 100;


/*--------------------------------------------
   PART 13: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Get all products with their category names
-- Write your query:


-- 2. Get all orders with customer full names and order dates
-- Write your query:


-- 3. Get products with category and supplier info (use LEFT JOIN for supplier)
-- Write your query:


-- 4. Get order details: OrderID, CustomerName, ProductName, Quantity, Total
-- Write your query:


-- 5. Find all products in 'Furniture' category
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ INNER JOIN = only matching rows
   ✅ LEFT JOIN = all from left + matches from right
   ✅ RIGHT JOIN = all from right + matches from left
   ✅ FULL JOIN = all from both tables
   ✅ Join condition: ON table1.column = table2.column
   ✅ Use aliases to keep queries readable
   
   NEXT: Lesson 05 - WHERE Clause (Filtering)
============================================*/
