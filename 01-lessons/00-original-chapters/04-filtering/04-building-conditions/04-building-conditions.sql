/*============================================
   LESSON 04: BUILDING CONDITIONS
   Constructing effective filter expressions
   
   Estimated Time: 15 minutes
   Difficulty: Beginner to Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: SIMPLE CONDITIONS
   Single-column comparisons
--------------------------------------------*/

-- Numeric comparisons
SELECT ProductName, Price FROM Inventory.Products WHERE Price = 100;
SELECT ProductName, Price FROM Inventory.Products WHERE Price > 100;
SELECT ProductName, Price FROM Inventory.Products WHERE Price < 100;
SELECT ProductName, Price FROM Inventory.Products WHERE Price >= 100;
SELECT ProductName, Price FROM Inventory.Products WHERE Price <= 100;
SELECT ProductName, Price FROM Inventory.Products WHERE Price <> 100;

-- String comparisons (case-insensitive in SQL Server by default)
SELECT FirstName, LastName FROM Sales.Customers WHERE LastName = 'Smith';
SELECT FirstName, LastName FROM Sales.Customers WHERE Country = 'USA';

-- Date comparisons
SELECT OrderID, OrderDate FROM Sales.Orders WHERE OrderDate = '2025-01-15';
SELECT OrderID, OrderDate FROM Sales.Orders WHERE OrderDate > '2025-01-01';
SELECT OrderID, OrderDate FROM Sales.Orders WHERE OrderDate >= '2025-01-01';


/*--------------------------------------------
   PART 2: COMPOUND CONDITIONS
   Combining multiple criteria
--------------------------------------------*/

-- Two conditions with AND
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE Price > 100 AND StockQuantity > 20;

-- Three conditions with AND
SELECT ProductName, Price, StockQuantity, CategoryID
FROM Inventory.Products
WHERE Price > 50 
  AND StockQuantity > 10 
  AND CategoryID = 1;

-- Two conditions with OR
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price < 30 OR Price > 1000;

-- Mixing AND and OR (use parentheses!)
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE (Price > 100 AND CategoryID = 1)
   OR (Price < 50 AND CategoryID = 2);


/*--------------------------------------------
   PART 3: RANGE CONDITIONS
   Checking if values fall within ranges
--------------------------------------------*/

-- Using AND for range
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price >= 50 AND Price <= 200;

-- Using BETWEEN (inclusive range)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price BETWEEN 50 AND 200;

-- NOT BETWEEN (outside range)
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price NOT BETWEEN 50 AND 200;

-- Date ranges
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';

-- Multiple ranges
SELECT ProductName, Price, StockQuantity
FROM Inventory.Products
WHERE (Price BETWEEN 50 AND 200)
  AND (StockQuantity BETWEEN 10 AND 100);


/*--------------------------------------------
   PART 4: LIST MEMBERSHIP
   Checking against multiple values
--------------------------------------------*/

-- IN operator (match any value in list)
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID IN (1, 2, 3);

-- NOT IN (exclude values)
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID NOT IN (1, 2);

-- String lists
SELECT FirstName, LastName, Country
FROM Sales.Customers
WHERE Country IN ('USA', 'UK', 'Canada', 'Australia');

-- Combining IN with other conditions
SELECT ProductName, Price, CategoryID
FROM Inventory.Products
WHERE CategoryID IN (1, 2)
  AND Price > 100;


/*--------------------------------------------
   PART 5: PATTERN MATCHING
   Searching text with wildcards
--------------------------------------------*/

-- LIKE with % (zero or more characters)
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE 'L%';      -- Starts with L
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%er';     -- Ends with er
SELECT ProductName FROM Inventory.Products WHERE ProductName LIKE '%top%';   -- Contains top

-- LIKE with _ (exactly one character)
SELECT FirstName FROM Sales.Customers WHERE FirstName LIKE 'J___';  -- 4-letter names starting with J

-- Combining patterns
SELECT ProductName
FROM Inventory.Products
WHERE ProductName LIKE '%Laptop%' OR ProductName LIKE '%Computer%';

-- NOT LIKE (exclude patterns)
SELECT ProductName
FROM Inventory.Products
WHERE ProductName NOT LIKE '%Discontinued%';


/*--------------------------------------------
   PART 6: NULL HANDLING
   Working with missing values
--------------------------------------------*/

-- Find NULL values
SELECT ProductName, SupplierID
FROM Inventory.Products
WHERE SupplierID IS NULL;

-- Find non-NULL values
SELECT ProductName, SupplierID
FROM Inventory.Products
WHERE SupplierID IS NOT NULL;

-- Combining NULL checks with other conditions
SELECT ProductName, SupplierID, StockQuantity
FROM Inventory.Products
WHERE SupplierID IS NULL
   OR StockQuantity < 10;

-- Using ISNULL to provide defaults
SELECT 
    ProductName,
    ISNULL(SupplierID, 0) AS SupplierID,
    StockQuantity
FROM Inventory.Products
WHERE ISNULL(SupplierID, 0) = 0;


/*--------------------------------------------
   PART 7: CALCULATED CONDITIONS
   Filtering on calculated values
--------------------------------------------*/

-- Filter on calculation
SELECT ProductName, Price, Price * 1.15 AS PriceWithTax
FROM Inventory.Products
WHERE Price * 1.15 > 100;

-- Filter on inventory value
SELECT ProductName, Price, StockQuantity, Price * StockQuantity AS InventoryValue
FROM Inventory.Products
WHERE Price * StockQuantity > 5000;

-- Filter on date calculations
SELECT OrderID, OrderDate
FROM Sales.Orders
WHERE OrderDate >= DATEADD(DAY, -30, GETDATE());

-- Filter on string functions
SELECT FirstName, LastName, Email
FROM Sales.Customers
WHERE LEN(FirstName) > 5;


/*--------------------------------------------
   PART 8: SUBQUERY CONDITIONS
   Filtering based on subqueries
--------------------------------------------*/

-- Compare to subquery result
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > (SELECT AVG(Price) FROM Inventory.Products);

-- IN with subquery
SELECT ProductName, CategoryID
FROM Inventory.Products
WHERE CategoryID IN (
    SELECT CategoryID 
    FROM Inventory.Categories 
    WHERE CategoryName LIKE '%Electronic%'
);

-- EXISTS (check for related data)
SELECT c.FirstName, c.LastName
FROM Sales.Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Sales.Orders o 
    WHERE o.CustomerID = c.CustomerID
);

-- NOT EXISTS (check for absence of data)
SELECT p.ProductName
FROM Inventory.Products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM Sales.OrderDetails od 
    WHERE od.ProductID = p.ProductID
);


/*--------------------------------------------
   PART 9: CASE-SENSITIVE FILTERING
   Controlling case sensitivity
--------------------------------------------*/

-- Default (case-insensitive in SQL Server)
SELECT FirstName, LastName
FROM Sales.Customers
WHERE LastName = 'SMITH';  -- Matches 'Smith', 'SMITH', 'smith'

-- Force case-sensitive comparison
SELECT FirstName, LastName
FROM Sales.Customers
WHERE LastName COLLATE Latin1_General_CS_AS = 'Smith';  -- Only exact case

-- Case-insensitive search with LOWER
SELECT ProductName
FROM Inventory.Products
WHERE LOWER(ProductName) LIKE LOWER('%LAPTOP%');


/*--------------------------------------------
   PART 10: DATE/TIME FILTERING
   Working with temporal data
--------------------------------------------*/

-- Specific date
SELECT * FROM Sales.Orders WHERE OrderDate = '2025-01-15';

-- Date range
SELECT * FROM Sales.Orders WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';

-- Year filter
SELECT * FROM Sales.Orders WHERE YEAR(OrderDate) = 2025;

-- Month filter
SELECT * FROM Sales.Orders WHERE YEAR(OrderDate) = 2025 AND MONTH(OrderDate) = 1;

-- Last N days
SELECT * FROM Sales.Orders WHERE OrderDate >= DATEADD(DAY, -30, GETDATE());

-- Last N months
SELECT * FROM Sales.Orders WHERE OrderDate >= DATEADD(MONTH, -6, GETDATE());

-- Future dates
SELECT * FROM Sales.Orders WHERE OrderDate > GETDATE();

-- Date parts
SELECT * FROM Sales.Orders WHERE DATEPART(WEEKDAY, OrderDate) = 2;  -- Mondays


/*--------------------------------------------
   PART 11: MULTI-TABLE CONDITIONS
   Filtering with JOINs
--------------------------------------------*/

-- Filter on joined table
SELECT p.ProductName, c.CategoryName, p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Multiple table filters
SELECT 
    p.ProductName,
    c.CategoryName,
    s.SupplierName,
    p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE c.CategoryName IN ('Electronics', 'Furniture')
  AND p.Price > 100
  AND s.SupplierName IS NOT NULL;

-- Complex join conditions
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(od.Quantity * od.UnitPrice) AS TotalSpent
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
WHERE c.Country = 'USA'
  AND o.OrderDate >= '2025-01-01'
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING SUM(od.Quantity * od.UnitPrice) > 500;


/*--------------------------------------------
   PART 12: COMBINING EVERYTHING
   Complex real-world examples
--------------------------------------------*/

-- Example 1: Product search with multiple criteria
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.StockQuantity,
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE (
        -- Option 1: Electronics in price range
        (c.CategoryName = 'Electronics' AND p.Price BETWEEN 100 AND 500)
        OR
        -- Option 2: Furniture with good stock
        (c.CategoryName = 'Furniture' AND p.StockQuantity > 20)
      )
  AND p.ProductName NOT LIKE '%Discontinued%'
  AND s.SupplierID IS NOT NULL
ORDER BY c.CategoryName, p.Price;


-- Example 2: Customer analysis
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    c.Email,
    c.Country,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.Quantity * od.UnitPrice) AS TotalSpent,
    MAX(o.OrderDate) AS LastOrderDate
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
WHERE c.Email IS NOT NULL
  AND c.Country IN ('USA', 'UK', 'Canada')
  AND (
        -- Active recent customers
        o.OrderDate >= DATEADD(MONTH, -6, GETDATE())
        OR
        -- OR high-value but inactive
        (SELECT SUM(od2.Quantity * od2.UnitPrice)
         FROM Sales.OrderDetails od2
         JOIN Sales.Orders o2 ON od2.OrderID = o2.OrderID
         WHERE o2.CustomerID = c.CustomerID) > 1000
      )
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email, c.Country
HAVING COUNT(DISTINCT o.OrderID) > 0
ORDER BY TotalSpent DESC;


/*--------------------------------------------
   PART 13: PRACTICE - YOUR TURN!
--------------------------------------------*/

-- 1. Find products with price between 50 and 200 AND stock > 10
-- Write your query:


-- 2. Find customers from USA, UK, or Canada with valid email
-- Write your query:


-- 3. Find products starting with 'L' or 'M' with price > 100
-- Write your query:


-- 4. Find products where (price > 200 AND stock > 20) OR (price < 50 AND stock > 100)
-- Write your query:


-- 5. Find orders from last 60 days with total value > 500
-- Write your query:


/*============================================
   KEY TAKEAWAYS:
   
   ✅ Build conditions incrementally (simple → complex)
   ✅ Use parentheses for clarity
   ✅ Combine operators: AND, OR, NOT, IN, BETWEEN, LIKE
   ✅ Handle NULLs explicitly
   ✅ Filter on calculations and subqueries
   ✅ Format for readability
   
   Condition Types:
   - Equality: = <> != 
   - Range: > < >= <= BETWEEN
   - Membership: IN NOT IN
   - Pattern: LIKE NOT LIKE
   - NULL: IS NULL IS NOT NULL
   - Existence: EXISTS NOT EXISTS
   
   NEXT: Lesson 05 - Equality Conditions
============================================*/
