/*============================================
   LESSON 05: EQUALITY CONDITIONS
   Exact match filtering
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: BASIC EQUALITY
   Exact value matching
--------------------------------------------*/

-- Numeric equality
SELECT ProductName, Price FROM Inventory.Products WHERE Price = 100;
SELECT ProductName, Price FROM Inventory.Products WHERE Price = 75.50;

-- String equality (case-insensitive by default)
SELECT FirstName, LastName FROM Sales.Customers WHERE LastName = 'Smith';
SELECT ProductName FROM Inventory.Products WHERE ProductName = 'Laptop';

-- Integer equality
SELECT ProductName, CategoryID FROM Inventory.Products WHERE CategoryID = 1;
SELECT * FROM Sales.Orders WHERE CustomerID = 1;

/*--------------------------------------------
   PART 2: INEQUALITY
   Not equal to
--------------------------------------------*/

-- Using <>
SELECT ProductName, CategoryID FROM Inventory.Products WHERE CategoryID <> 1;

-- Using != (same as <>)
SELECT ProductName, CategoryID FROM Inventory.Products WHERE CategoryID != 1;

-- Multiple inequalities
SELECT ProductName, Price FROM Inventory.Products 
WHERE Price <> 100 AND Price <> 200;

/*--------------------------------------------
   PART 3: MULTIPLE EQUALITY CONDITIONS
   Exact matches on multiple columns
--------------------------------------------*/

-- AND (all must match)
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE Price = 100 AND CategoryID = 1;

-- OR (any can match)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price = 100 OR Price = 200 OR Price = 300;

-- Better: Use IN for multiple OR equality checks
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price IN (100, 200, 300);

/*--------------------------------------------
   PART 4: DATE EQUALITY
   Exact date matching
--------------------------------------------*/

-- Exact date match
SELECT OrderID, OrderDate FROM Sales.Orders WHERE OrderDate = '2025-01-15';

-- Date without time
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE CAST(OrderDate AS DATE) = '2025-01-15';

-- Specific date and time
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE OrderDate = '2025-01-15 14:30:00';

/*--------------------------------------------
   PART 5: BOOLEAN EQUALITY
   True/False checks
--------------------------------------------*/

-- Assuming we add IsActive column
SELECT ProductName FROM Inventory.Products WHERE StockQuantity = 0;  -- Out of stock
SELECT ProductName FROM Inventory.Products WHERE StockQuantity > 0;  -- In stock

-- Explicit TRUE/FALSE (if column is BIT type)
-- WHERE IsActive = 1  -- TRUE
-- WHERE IsActive = 0  -- FALSE

/*--------------------------------------------
   PART 6: CASE SENSITIVITY
   Controlling exact match behavior
--------------------------------------------*/

-- Default: Case-insensitive
SELECT FirstName FROM Sales.Customers WHERE FirstName = 'JOHN';  -- Matches 'John', 'JOHN', 'john'

-- Force case-sensitive
SELECT FirstName FROM Sales.Customers 
WHERE FirstName COLLATE Latin1_General_CS_AS = 'John';  -- Only 'John'

-- Case-insensitive guarantee
SELECT ProductName FROM Inventory.Products 
WHERE LOWER(ProductName) = LOWER('LAPTOP');

/*--------------------------------------------
   PART 7: NULL EQUALITY
   Special NULL handling
--------------------------------------------*/

-- ❌ WRONG: NULL = NULL is always NULL (not TRUE!)
SELECT ProductName FROM Inventory.Products WHERE SupplierID = NULL;  -- Returns nothing

-- ✅ CORRECT: Use IS NULL
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NULL;

-- ✅ CORRECT: Use IS NOT NULL
SELECT ProductName FROM Inventory.Products WHERE SupplierID IS NOT NULL;

/*--------------------------------------------
   PART 8: EQUALITY IN JOINS
   Matching across tables
--------------------------------------------*/

-- Simple join equality
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Multiple join conditions
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

/*--------------------------------------------
   PART 9: EQUALITY WITH CALCULATIONS
   Matching calculated values
--------------------------------------------*/

-- Match specific calculation result
SELECT ProductName, Price, Price * 1.15 AS PriceWithTax
FROM Inventory.Products
WHERE Price * 1.15 = 115;

-- Match rounded values
SELECT ProductName, Price
FROM Inventory.Products
WHERE ROUND(Price, 0) = 100;

/*--------------------------------------------
   PART 10: PRACTICE
--------------------------------------------*/

-- 1. Find products with exact price of $99.99
-- 2. Find customers with last name 'Johnson'
-- 3. Find products NOT in category 1
-- 4. Find products with price exactly 75.50 OR 150.00
-- 5. Find orders on January 15, 2025

/*============================================
   NEXT: Lesson 06 - Range Conditions
============================================*/
