/*============================================
   LESSON 04: ANSI JOIN SYNTAX
   Modern vs old-style join syntax
   
   Estimated Time: 15 minutes
   Difficulty: Beginner
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT IS ANSI JOIN SYNTAX?
   The modern standard
--------------------------------------------*/

/*
   ANSI (American National Standards Institute) JOIN syntax
   was introduced in SQL-92 standard
   
   Two styles exist:
   1. OLD STYLE (pre-SQL-92): Comma-separated tables with WHERE
   2. NEW STYLE (SQL-92+): Explicit INNER JOIN with ON
   
   Modern SQL uses ANSI JOIN syntax (NEW STYLE)
*/

/*--------------------------------------------
   PART 2: OLD STYLE vs NEW STYLE
   Side-by-side comparison
--------------------------------------------*/

-- ❌ OLD STYLE (avoid in new code)
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p, Inventory.Categories c
WHERE p.CategoryID = c.CategoryID;

-- ✅ NEW STYLE (preferred)
SELECT p.ProductName, c.CategoryName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

-- Both produce the same result, but NEW STYLE is better!

/*--------------------------------------------
   PART 3: WHY ANSI JOIN SYNTAX IS BETTER
   Advantages of modern syntax
--------------------------------------------*/

/*
   ✅ ADVANTAGES:
   
   1. CLARITY
      • Join conditions are separate from filter conditions
      • Easy to see which tables are being joined
      • More readable for complex queries
   
   2. SAFETY
      • Can't accidentally forget join condition (syntax error!)
      • Old style: Forgetting WHERE = Cartesian product (disaster!)
      • New style: Forgetting ON = Syntax error (caught immediately)
   
   3. FLEXIBILITY
      • Supports LEFT JOIN, RIGHT JOIN, FULL JOIN
      • Old style can't do these easily
   
   4. MAINTAINABILITY
      • Easier to modify and debug
      • Industry standard
      • Better tool support
*/

/*--------------------------------------------
   PART 4: CLARITY EXAMPLE
   Separating join logic from filtering
--------------------------------------------*/

-- ❌ OLD STYLE: Everything mixed in WHERE
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p, Inventory.Categories c, Inventory.Suppliers s
WHERE p.CategoryID = c.CategoryID      -- Join condition
  AND p.SupplierID = s.SupplierID      -- Join condition
  AND p.Price > 100                     -- Filter condition
  AND c.CategoryName = 'Electronics';   -- Filter condition

-- Hard to tell: Which are joins? Which are filters?

-- ✅ NEW STYLE: Joins separated from filters
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID      -- Join logic
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID       -- Join logic
WHERE p.Price > 100                     -- Filter logic
  AND c.CategoryName = 'Electronics';   -- Filter logic

-- Crystal clear: JOINs above, filters in WHERE

/*--------------------------------------------
   PART 5: SAFETY EXAMPLE
   Preventing accidental Cartesian products
--------------------------------------------*/

-- ❌ OLD STYLE: Forget one join condition = Disaster
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p, Inventory.Categories c, Inventory.Suppliers s
WHERE p.CategoryID = c.CategoryID;
-- Oops! Forgot p.SupplierID = s.SupplierID
-- Result: Products × Suppliers Cartesian product!
-- NO ERROR, just wrong results!

-- ✅ NEW STYLE: Forget ON clause = Syntax error
/*
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s;  -- ERROR! Missing ON clause
-- SQL Server catches this immediately
*/

/*--------------------------------------------
   PART 6: COMPLEX QUERY COMPARISON
   Multiple joins with filters
--------------------------------------------*/

-- ❌ OLD STYLE: Hard to read
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    od.UnitPrice
FROM Sales.Customers c,
     Sales.Orders o,
     Sales.OrderDetails od,
     Inventory.Products p,
     Inventory.Categories cat
WHERE c.CustomerID = o.CustomerID
  AND o.OrderID = od.OrderID
  AND od.ProductID = p.ProductID
  AND p.CategoryID = cat.CategoryID
  AND o.OrderDate >= '2025-01-01'
  AND cat.CategoryName IN ('Electronics', 'Books');

-- ✅ NEW STYLE: Clean and organized
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    od.UnitPrice
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
WHERE o.OrderDate >= '2025-01-01'
  AND cat.CategoryName IN ('Electronics', 'Books');

/*--------------------------------------------
   PART 7: WHEN OLD STYLE STILL APPEARS
   Legacy code and old habits
--------------------------------------------*/

/*
   You might see OLD STYLE in:
   • Legacy databases (pre-2000s code)
   • Old tutorials and books
   • Developers who learned SQL before 1992
   • Migrated code from older systems
   
   What to do:
   • Understand it (need to read old code)
   • Don't write new code this way
   • Refactor when safe to do so
*/

/*--------------------------------------------
   PART 8: REFACTORING OLD TO NEW
   Converting legacy queries
--------------------------------------------*/

-- Original OLD STYLE query
SELECT p.ProductName, c.CategoryName, p.Price
FROM Inventory.Products p, Inventory.Categories c
WHERE p.CategoryID = c.CategoryID
  AND p.Price > 50
ORDER BY p.Price;

-- Refactored to NEW STYLE:
-- Step 1: Identify join conditions in WHERE
--         p.CategoryID = c.CategoryID → This is the join

-- Step 2: Move join to INNER JOIN ON
SELECT p.ProductName, c.CategoryName, p.Price
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Price > 50
ORDER BY p.Price;

-- Step 3: Keep remaining WHERE conditions as filters

/*--------------------------------------------
   PART 9: MULTIPLE TABLE REFACTORING
--------------------------------------------*/

-- OLD STYLE: Three tables
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p, 
     Inventory.Categories c, 
     Inventory.Suppliers s
WHERE p.CategoryID = c.CategoryID
  AND p.SupplierID = s.SupplierID
  AND p.StockQuantity < 20;

-- NEW STYLE: Same query
SELECT p.ProductName, c.CategoryName, s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
INNER JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity < 20;

/*--------------------------------------------
   PART 10: ANSI SYNTAX WITH OUTER JOINS
   Why old style fails here
--------------------------------------------*/

-- NEW STYLE: LEFT JOIN (gets all products, even without suppliers)
SELECT p.ProductName, s.SupplierName
FROM Inventory.Products p
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- OLD STYLE: Cannot easily do LEFT JOIN!
-- This is one of the biggest reasons to use ANSI syntax
-- (We'll cover LEFT JOIN in Chapter 10)

/*--------------------------------------------
   PART 11: BEST PRACTICES
--------------------------------------------*/

/*
   ✅ DO:
   • Use ANSI JOIN syntax (INNER JOIN ... ON)
   • Put JOIN conditions in ON clause
   • Put filter conditions in WHERE clause
   • Use clear, descriptive table aliases
   • Format for readability (line breaks, indentation)
   
   ❌ DON'T:
   • Use comma-separated tables in new code
   • Mix joins and filters in WHERE clause
   • Use cryptic aliases (a, b, c...)
   • Put everything on one line
*/

/*--------------------------------------------
   PART 12: FORMATTING GUIDELINES
--------------------------------------------*/

-- ❌ BAD: All on one line
SELECT c.FirstName,o.OrderDate,p.ProductName FROM Sales.Customers c INNER JOIN Sales.Orders o ON c.CustomerID=o.CustomerID INNER JOIN Sales.OrderDetails od ON o.OrderID=od.OrderID INNER JOIN Inventory.Products p ON od.ProductID=p.ProductID;

-- ✅ GOOD: Readable formatting
SELECT 
    c.FirstName,
    o.OrderDate,
    p.ProductName
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;

-- ✅ EVEN BETTER: With comments
SELECT 
    c.FirstName,
    o.OrderDate,
    p.ProductName
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID           -- Customer to Order
INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID         -- Order to Details
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;     -- Details to Products

/*--------------------------------------------
   PART 13: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Customer Order Report (ANSI Style)
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    c.Email,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent,
    MAX(o.OrderDate) AS LastOrderDate
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email
HAVING COUNT(o.OrderID) >= 3
ORDER BY TotalSpent DESC;

-- Example 2: Product Inventory Report (ANSI Style)
SELECT 
    cat.CategoryName,
    p.ProductName,
    p.Price,
    p.StockQuantity,
    ISNULL(s.SupplierName, 'No Supplier') AS Supplier,
    CASE 
        WHEN p.StockQuantity = 0 THEN 'Out of Stock'
        WHEN p.StockQuantity < 20 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus
FROM Inventory.Products p
INNER JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
ORDER BY cat.CategoryName, p.ProductName;

/*--------------------------------------------
   PART 14: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. Rewrite this OLD STYLE query using ANSI syntax:
--    SELECT * FROM Products p, Categories c WHERE p.CategoryID = c.CategoryID;

-- 2. Identify what's wrong with this query:
--    SELECT * FROM Products p, Categories c;

-- 3. Convert this to ANSI syntax:
--    SELECT p.ProductName, s.SupplierName
--    FROM Products p, Suppliers s
--    WHERE p.SupplierID = s.SupplierID AND p.Price > 100;

-- 4. Why is separating JOIN and WHERE conditions beneficial?

-- 5. Write a query using ANSI syntax joining Customers, Orders, and OrderDetails

/*============================================
   KEY TAKEAWAYS
============================================*/

/*
   ANSI JOIN Syntax (SQL-92):
   • Use INNER JOIN with ON clause
   • Separates join logic from filtering
   • Safer (prevents accidental Cartesian products)
   • Industry standard
   • Required for outer joins
   
   OLD Style (Pre-SQL-92):
   • Comma-separated tables
   • Join conditions in WHERE
   • Risky (easy to forget conditions)
   • Limited (can't do outer joins well)
   • Deprecated in modern SQL
   
   Always use ANSI syntax in new code!
*/

/*============================================
   NEXT: Lesson 05 - Joining Three Tables
   (Building complex multi-table queries)
============================================*/
