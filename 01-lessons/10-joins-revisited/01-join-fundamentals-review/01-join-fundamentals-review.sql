/*
============================================================================
Lesson 10.01 - Join Fundamentals Review
============================================================================

Description:
Review and strengthen your understanding of join fundamentals. Compare
ANSI and old-style syntax, understand join mechanics, and prepare for
advanced join techniques.

Topics Covered:
• Join syntax comparison
• Inner join mechanics
• Join execution order
• Cartesian products
• Best practices review

Prerequisites:
• Chapter 05 (Basic joins)
• Understanding of table relationships

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Join Syntax - ANSI vs Old-Style
============================================================================
*/

-- Example 1.1: ANSI-92 Standard (RECOMMENDED)
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 500;

-- Example 1.2: Old-Style WHERE Clause Join (AVOID)
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c, Orders o
WHERE c.CustomerID = o.CustomerID
  AND o.TotalAmount > 500;

/* 
Why ANSI-92 is better:
✓ Separates join logic (ON) from filters (WHERE)
✓ More readable and maintainable
✓ Supports outer joins clearly
✓ Industry standard
✓ Less prone to Cartesian products
*/

-- Example 1.3: Multiple joins comparison
-- ANSI style (clear structure):
SELECT 
    c.CustomerName,
    o.OrderID,
    p.ProductName,
    od.Quantity
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;

-- Old style (confusing):
SELECT 
    c.CustomerName,
    o.OrderID,
    p.ProductName,
    od.Quantity
FROM Customers c, Orders o, OrderDetails od, Products p
WHERE c.CustomerID = o.CustomerID
  AND o.OrderID = od.OrderID
  AND od.ProductID = p.ProductID;


/*
============================================================================
PART 2: Inner Join Mechanics
============================================================================
*/

-- Mechanic 2.1: Basic equi-join
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

/*
Execution steps:
1. SQL Server scans Customers table
2. For each customer, looks up matching orders
3. Creates result set of matched rows only
4. Groups and aggregates
*/

-- Mechanic 2.2: Join with multiple conditions
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    p1.Price
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID  -- Same category
    AND p1.Price = p2.Price            -- Same price
    AND p1.ProductID < p2.ProductID;   -- Avoid duplicates

-- Mechanic 2.3: Join with calculated condition
SELECT 
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND YEAR(o.OrderDate) = YEAR(GETDATE());  -- Current year only

-- Mechanic 2.4: Understanding NULL in joins
CREATE TABLE #Temp1 (ID INT, Value VARCHAR(20));
CREATE TABLE #Temp2 (ID INT, Value VARCHAR(20));

INSERT INTO #Temp1 VALUES (1, 'A'), (2, 'B'), (NULL, 'C');
INSERT INTO #Temp2 VALUES (1, 'X'), (2, 'Y'), (NULL, 'Z');

-- NULL = NULL is FALSE in SQL, so NULLs don't match
SELECT t1.Value, t2.Value
FROM #Temp1 t1
INNER JOIN #Temp2 t2 ON t1.ID = t2.ID;
-- Returns only rows 1 and 2, NOT the NULL row

DROP TABLE #Temp1, #Temp2;


/*
============================================================================
PART 3: Join Execution Order
============================================================================
*/

-- Example 3.1: Logical query processing order
SELECT 
    c.CustomerName,              -- 5. SELECT
    COUNT(o.OrderID) AS Orders   -- 5. SELECT (aggregate)
FROM Customers c                 -- 1. FROM
INNER JOIN Orders o              -- 2. JOIN
    ON c.CustomerID = o.CustomerID  -- 2. JOIN condition
WHERE o.OrderDate >= '2024-01-01'   -- 3. WHERE
GROUP BY c.CustomerName          -- 4. GROUP BY
HAVING COUNT(o.OrderID) > 3      -- 6. HAVING
ORDER BY Orders DESC;            -- 7. ORDER BY

/*
Processing order:
1. FROM - Identify tables
2. JOIN - Combine tables
3. WHERE - Filter rows
4. GROUP BY - Group rows
5. SELECT - Choose columns
6. HAVING - Filter groups
7. ORDER BY - Sort results
*/

-- Example 3.2: How join order affects results
-- All customers with their orders (if any):
SELECT c.CustomerName, o.OrderID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID;

-- All orders with customer info (same result as INNER JOIN):
SELECT c.CustomerName, o.OrderID
FROM Orders o
LEFT JOIN Customers c ON c.CustomerID = o.CustomerID;

-- Example 3.3: Multiple joins - order matters for outer joins
SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- Returns all customers, even those with no orders

-- Different result:
SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- Returns only customers with orders that have details


/*
============================================================================
PART 4: Cartesian Products (Cross Joins)
============================================================================
*/

-- Example 4.1: Intentional Cartesian product
SELECT 
    c.CustomerName,
    p.ProductName
FROM Customers c
CROSS JOIN Products p;
-- Returns every combination: Customers × Products

-- Example 4.2: Accidental Cartesian product (ERROR!)
-- ❌ Missing join condition:
SELECT c.CustomerName, o.OrderID
FROM Customers c, Orders o;
-- Returns way too many rows!

-- ✅ Corrected with proper join:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Example 4.3: Partial Cartesian product
-- Every product paired with every category (even wrong ones):
SELECT p.ProductName, c.CategoryName
FROM Products p
CROSS JOIN Categories c
WHERE c.CategoryID = 1;  -- Still gets all products!

-- Example 4.4: Row count calculation
-- If Customers has 100 rows and Products has 50:
-- CROSS JOIN returns: 100 × 50 = 5,000 rows!
SELECT 
    (SELECT COUNT(*) FROM Customers) AS CustomerCount,
    (SELECT COUNT(*) FROM Products) AS ProductCount,
    (SELECT COUNT(*) FROM Customers) * (SELECT COUNT(*) FROM Products) AS CrossJoinCount,
    (SELECT COUNT(*) FROM Customers CROSS JOIN Products) AS ActualCount;


/*
============================================================================
PART 5: Join Performance Basics
============================================================================
*/

-- Performance 5.1: Index usage in joins
-- Check if indexes exist on join columns
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE c.name IN ('CustomerID', 'OrderID', 'ProductID', 'CategoryID')
ORDER BY t.name, i.name;

-- Performance 5.2: Execution statistics
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT c.CustomerName, COUNT(o.OrderID) AS OrderCount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Performance 5.3: Join hints (use sparingly!)
-- Force nested loop join:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER LOOP JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Force hash join:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER HASH JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Force merge join:
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER MERGE JOIN Orders o ON c.CustomerID = o.CustomerID;


/*
============================================================================
PART 6: Common Join Patterns
============================================================================
*/

-- Pattern 6.1: One-to-Many (Customer → Orders)
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.TotalAmount) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Pattern 6.2: Many-to-Many (Orders ↔ Products through OrderDetails)
SELECT 
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;

-- Pattern 6.3: One-to-One (conceptual - Product → ProductDetails if exists)
-- In RetailStore, we simulate with Products and Categories
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- Pattern 6.4: Self-referential (finding related products)
SELECT 
    p1.ProductName AS Product,
    p2.ProductName AS RelatedProduct,
    p1.Price AS ProductPrice,
    p2.Price AS RelatedPrice
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.ProductID <> p2.ProductID
WHERE p1.ProductID = 1;


/*
============================================================================
PART 7: Join Best Practices
============================================================================
*/

-- Best Practice 7.1: ✅ Always use table aliases
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Best Practice 7.2: ✅ Be explicit about join type
-- Good:
SELECT * FROM Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
-- Avoid:
-- SELECT * FROM Customers c JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Best Practice 7.3: ✅ Put complex conditions in ON clause
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01'
    AND o.TotalAmount > 100;

-- Best Practice 7.4: ✅ Use meaningful aliases
-- Good:
SELECT 
    cust.CustomerName,
    ord.OrderDate
FROM Customers cust
INNER JOIN Orders ord ON cust.CustomerID = ord.CustomerID;

-- Avoid single letters for complex queries:
-- SELECT x.CustomerName FROM Customers x...

-- Best Practice 7.5: ✅ Index foreign key columns
/*
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);
CREATE INDEX IX_Products_CategoryID ON Products(CategoryID);
*/


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Rewrite this old-style join using ANSI syntax:
   SELECT * FROM Customers c, Orders o WHERE c.CustomerID = o.CustomerID;

2. Write a join to find all products and their category names

3. Count how many orders each customer has (include customers with 0)

4. Find all orders with their product details (3-table join)

5. Explain why this creates a Cartesian product and fix it:
   SELECT * FROM Products, Categories;

Solutions below ↓
*/

-- Solution 1:
SELECT *
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Solution 2:
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- Solution 3:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Solution 4:
SELECT 
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID;

-- Solution 5:
-- Creates Cartesian product because no join condition
-- Every product paired with every category
-- Fix: Add join condition
SELECT *
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ JOIN SYNTAX:
  • Use ANSI-92 standard (JOIN ... ON)
  • Avoid old-style WHERE clause joins
  • Separate join logic (ON) from filters (WHERE)

✓ INNER JOIN:
  • Returns only matching rows
  • NULL values don't match
  • Most common join type
  • Filters out non-matches

✓ EXECUTION ORDER:
  1. FROM/JOIN - Combine tables
  2. WHERE - Filter rows
  3. GROUP BY - Group results
  4. SELECT - Choose columns
  5. HAVING - Filter groups
  6. ORDER BY - Sort output

✓ CARTESIAN PRODUCTS:
  • Missing join condition = huge result
  • Rows = Table1 × Table2
  • Intentional use: CROSS JOIN
  • Usually a mistake otherwise

✓ PERFORMANCE:
  • Index join columns (FK/PK)
  • Join order matters for outer joins
  • SQL Server optimizes inner join order
  • Use execution plans to analyze

✓ BEST PRACTICES:
  • Always use table aliases
  • Be explicit (INNER JOIN not just JOIN)
  • Meaningful alias names
  • Index foreign keys
  • Comment complex joins

✓ COMMON PATTERNS:
  • One-to-Many (Customer-Orders)
  • Many-to-Many (Orders-Products)
  • One-to-One (Product-Category)
  • Self-joins (related records)

============================================================================
NEXT: Lesson 10.02 - Outer Joins Deep Dive
Master LEFT, RIGHT, and FULL OUTER JOINs for complete data analysis.
============================================================================
*/
