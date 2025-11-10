/*============================================
   LESSON 06: RANGE CONDITIONS
   Filtering within value ranges
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: GREATER THAN / LESS THAN
   Simple range boundaries
--------------------------------------------*/

-- Greater than
SELECT ProductName, Price FROM Inventory.Products WHERE Price > 100;

-- Less than
SELECT ProductName, Price FROM Inventory.Products WHERE Price < 50;

-- Greater than or equal
SELECT ProductName, Price FROM Inventory.Products WHERE Price >= 100;

-- Less than or equal
SELECT ProductName, Price FROM Inventory.Products WHERE Price <= 100;

/*--------------------------------------------
   PART 2: BETWEEN OPERATOR
   Inclusive range checking
--------------------------------------------*/

-- BETWEEN (includes both boundaries)
SELECT ProductName, Price FROM Inventory.Products WHERE Price BETWEEN 50 AND 200;

-- Same as:
SELECT ProductName, Price FROM Inventory.Products WHERE Price >= 50 AND Price <= 200;

-- NOT BETWEEN (outside range)
SELECT ProductName, Price FROM Inventory.Products WHERE Price NOT BETWEEN 50 AND 200;

-- Same as:
SELECT ProductName, Price FROM Inventory.Products WHERE Price < 50 OR Price > 200;

/*--------------------------------------------
   PART 3: DATE RANGES
   Temporal filtering
--------------------------------------------*/

-- Date range with BETWEEN
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';

-- Using >= and <
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE OrderDate >= '2025-01-01' AND OrderDate < '2025-02-01';

-- Last N days
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE());

-- Last N months
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE OrderDate >= DATEADD(MONTH, -6, GETDATE());

-- Specific year
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE YEAR(OrderDate) = 2025;

-- Specific month
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE YEAR(OrderDate) = 2025 AND MONTH(OrderDate) = 1;

/*--------------------------------------------
   PART 4: COMBINING RANGES
   Multiple range conditions
--------------------------------------------*/

-- Two ranges with AND
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE Price BETWEEN 50 AND 200
  AND StockQuantity BETWEEN 10 AND 100;

-- Two ranges with OR
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price BETWEEN 10 AND 50
   OR Price BETWEEN 200 AND 500;

/*--------------------------------------------
   PART 5: COMPLEX RANGE PATTERNS
   Advanced range logic
--------------------------------------------*/

-- Exclude middle range (keep extremes)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 50 OR Price > 200;

-- Multiple non-overlapping ranges
SELECT ProductName, Price
FROM Inventory.Products
WHERE (Price BETWEEN 10 AND 50)
   OR (Price BETWEEN 100 AND 150)
   OR (Price BETWEEN 300 AND 500);

/*--------------------------------------------
   PART 6: NUMERIC RANGES
   Different numeric patterns
--------------------------------------------*/

-- Integer ranges
SELECT FirstName, LastName FROM HR.Employees 
WHERE Salary BETWEEN 60000 AND 80000;

-- Decimal ranges
SELECT ProductName, Price FROM Inventory.Products 
WHERE Price BETWEEN 99.99 AND 199.99;

-- Small ranges (find exact values nearby)
SELECT ProductName, Price FROM Inventory.Products 
WHERE Price BETWEEN 99.50 AND 100.50;

/*--------------------------------------------
   PART 7: STRING RANGES
   Alphabetical ranges
--------------------------------------------*/

-- Names A-M
SELECT FirstName, LastName FROM Sales.Customers 
WHERE LastName BETWEEN 'A' AND 'M';

-- Names starting with A-C
SELECT FirstName, LastName FROM Sales.Customers 
WHERE LastName >= 'A' AND LastName < 'D';

/*--------------------------------------------
   PART 8: YEAR/MONTH/DAY RANGES
   Date part filtering
--------------------------------------------*/

-- Current year
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE YEAR(OrderDate) = YEAR(GETDATE());

-- Q1 (Jan-Mar)
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE MONTH(OrderDate) BETWEEN 1 AND 3;

-- Weekdays only (Mon-Fri)
SELECT OrderID, OrderDate FROM Sales.Orders 
WHERE DATEPART(WEEKDAY, OrderDate) BETWEEN 2 AND 6;

/*--------------------------------------------
   PART 9: PRACTICE
--------------------------------------------*/

-- 1. Products priced $50-$500
-- 2. Orders from January 2025
-- 3. Employees with salary $60k-$90k
-- 4. Products with stock 20-50 units
-- 5. Orders from last 90 days

/*============================================
   NEXT: Lesson 07 - Membership Conditions
============================================*/
