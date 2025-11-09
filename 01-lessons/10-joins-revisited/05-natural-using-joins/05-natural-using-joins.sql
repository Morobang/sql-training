/*
============================================================================
Lesson 10.05 - Natural and Using Joins
============================================================================

Description:
Understand NATURAL JOIN and USING clause syntax. Learn why they're not
supported in T-SQL and what alternatives to use instead. Understand the
concepts for database portability.

Topics Covered:
• NATURAL JOIN concept
• USING clause explained
• T-SQL alternatives
• Why SQL Server doesn't support them
• Best practices for cross-platform SQL

Prerequisites:
• Lessons 10.01-10.04
• Understanding of column naming

Estimated Time: 20 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding NATURAL JOIN (Not in T-SQL)
============================================================================
*/

/*
NATURAL JOIN Concept:
• Automatically joins on columns with SAME NAME
• No ON clause needed
• Common in Oracle, MySQL, PostgreSQL
• NOT supported in SQL Server T-SQL

Example (in MySQL/PostgreSQL):
SELECT *
FROM Customers
NATURAL JOIN Orders;

Would join on any columns with matching names (like CustomerID)
*/

-- Example 1.1: T-SQL equivalent of NATURAL JOIN
-- If both tables have CustomerID column:
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

/*
Why NATURAL JOIN can be dangerous:
1. Implicit - not obvious what columns are being joined
2. Schema changes break queries silently
3. Can match unintended columns
4. Hard to maintain
*/

-- Example 1.2: Simulating NATURAL JOIN in T-SQL
-- Find common columns and join on them
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID;  -- Explicit is better!


/*
============================================================================
PART 2: Understanding USING Clause (Not in T-SQL)
============================================================================
*/

/*
USING Clause Concept:
• Alternative to ON for equi-joins
• Specifies column name(s) to join on
• Column must exist in both tables
• Common in Oracle, MySQL, PostgreSQL
• NOT supported in SQL Server T-SQL

Example (in MySQL/PostgreSQL):
SELECT *
FROM Customers
JOIN Orders USING (CustomerID);

Cleaner than ON for simple equi-joins
*/

-- Example 2.1: T-SQL equivalent of USING
-- USING (CustomerID) becomes ON c.CustomerID = o.CustomerID
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Example 2.2: Multiple column USING equivalent
-- USING (Col1, Col2) in other databases
-- In T-SQL:
CREATE TABLE #Table1 (ID1 INT, ID2 INT, Value1 VARCHAR(20));
CREATE TABLE #Table2 (ID1 INT, ID2 INT, Value2 VARCHAR(20));

INSERT INTO #Table1 VALUES (1, 1, 'A'), (1, 2, 'B'), (2, 1, 'C');
INSERT INTO #Table2 VALUES (1, 1, 'X'), (1, 2, 'Y'), (2, 2, 'Z');

-- Other databases: JOIN USING (ID1, ID2)
-- T-SQL equivalent:
SELECT 
    t1.ID1,
    t1.ID2,
    t1.Value1,
    t2.Value2
FROM #Table1 t1
INNER JOIN #Table2 t2 
    ON t1.ID1 = t2.ID1 
    AND t1.ID2 = t2.ID2;

DROP TABLE #Table1, #Table2;


/*
============================================================================
PART 3: Why SQL Server Doesn't Support Them
============================================================================
*/

/*
Reasons T-SQL doesn't have NATURAL JOIN or USING:

1. EXPLICITNESS:
   • T-SQL prefers explicit over implicit
   • ON clause shows exactly what's being joined
   • Reduces ambiguity and errors

2. MAINTAINABILITY:
   • Schema changes don't break queries silently
   • Clear intent for future developers
   • Easier to debug

3. FLEXIBILITY:
   • ON clause supports complex conditions
   • Can add additional predicates
   • Works with computed expressions

4. CONSISTENCY:
   • All joins use same syntax
   • No special cases to remember
   • Uniform across T-SQL
*/

-- Example 3.1: ON clause flexibility
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01'
    AND o.TotalAmount > 100;
-- Can't do this with NATURAL JOIN or simple USING!


/*
============================================================================
PART 4: Cross-Platform SQL Considerations
============================================================================
*/

-- Example 4.1: Writing portable SQL
-- Instead of database-specific syntax, use standard ANSI:

-- ✅ Portable (works everywhere):
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- ❌ MySQL/PostgreSQL only:
-- SELECT * FROM Customers NATURAL JOIN Orders;
-- SELECT * FROM Customers JOIN Orders USING (CustomerID);

-- Example 4.2: Consistent naming for easier joins
-- Good practice: Use same column names across related tables
CREATE TABLE #Departments (
    DepartmentID INT PRIMARY KEY,
    DepartmentName VARCHAR(50)
);

CREATE TABLE #Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(50),
    DepartmentID INT  -- Same name as in Departments
);

-- Now joins are clear:
SELECT 
    e.EmployeeName,
    d.DepartmentName
FROM #Employees e
INNER JOIN #Departments d ON e.DepartmentID = d.DepartmentID;

DROP TABLE #Employees, #Departments;


/*
============================================================================
PART 5: T-SQL Best Practices for Joins
============================================================================
*/

-- Best Practice 5.1: ✅ Always be explicit
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
-- Clear: joining on CustomerID

-- Best Practice 5.2: ✅ Use table aliases
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;
-- Not:
-- SELECT CustomerName, OrderID FROM Customers JOIN Orders ON...

-- Best Practice 5.3: ✅ Qualify all columns
SELECT 
    c.CustomerID,  -- From Customers
    c.CustomerName,
    o.OrderID,     -- From Orders
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Best Practice 5.4: ✅ Comment complex joins
SELECT 
    p.ProductName,
    c.CategoryName
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
    AND c.CategoryName <> 'Discontinued';  -- Only active categories

-- Best Practice 5.5: ✅ Consistent formatting
SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID,
    p.ProductName
FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID;


/*
============================================================================
PART 6: Simulating NATURAL JOIN Safely
============================================================================
*/

-- Example 6.1: Safe "natural join" pattern
-- Get matching columns explicitly:
SELECT 
    c.*,  -- All customer columns
    o.OrderID,
    o.OrderDate,
    o.TotalAmount  -- Only specific order columns
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Example 6.2: Using dynamic SQL (advanced, rarely needed)
-- This finds common columns programmatically
DECLARE @sql NVARCHAR(MAX);
SELECT @sql = 'SELECT c.*, o.OrderID, o.OrderDate, o.TotalAmount 
               FROM Customers c 
               INNER JOIN Orders o ON c.CustomerID = o.CustomerID';
-- EXEC sp_executesql @sql;


/*
============================================================================
PART 7: Comparison with Other Databases
============================================================================
*/

/*
JOIN Syntax Across Databases:

┌─────────────────┬──────────┬───────┬────────────┬───────────┐
│ Feature         │ T-SQL    │ MySQL │ PostgreSQL │ Oracle    │
├─────────────────┼──────────┼───────┼────────────┼───────────┤
│ INNER JOIN      │ ✓        │ ✓     │ ✓          │ ✓         │
│ LEFT JOIN       │ ✓        │ ✓     │ ✓          │ ✓         │
│ RIGHT JOIN      │ ✓        │ ✓     │ ✓          │ ✓         │
│ FULL JOIN       │ ✓        │ ✗     │ ✓          │ ✓         │
│ CROSS JOIN      │ ✓        │ ✓     │ ✓          │ ✓         │
│ NATURAL JOIN    │ ✗        │ ✓     │ ✓          │ ✓         │
│ USING clause    │ ✗        │ ✓     │ ✓          │ ✓         │
│ ON clause       │ ✓        │ ✓     │ ✓          │ ✓         │
└─────────────────┴──────────┴───────┴────────────┴───────────┘

Recommendation: Stick to ANSI-92 standard (ON clause) for portability
*/


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Rewrite this hypothetical NATURAL JOIN for T-SQL:
   NATURAL JOIN between Products and Categories

2. Rewrite this USING clause for T-SQL:
   JOIN OrderDetails USING (OrderID)

3. Join Orders and Customers explicitly (all columns from both tables)

4. Write a comment explaining why explicit joins are better

5. Create tables with consistent naming for easy joins

Solutions below ↓
*/

-- Solution 1:
-- Hypothetical: SELECT * FROM Products NATURAL JOIN Categories;
-- T-SQL equivalent:
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,  -- Common column
    p.Price,
    p.Stock,
    c.CategoryName,
    c.Description
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID;

-- Solution 2:
-- Hypothetical: SELECT * FROM Orders JOIN OrderDetails USING (OrderID);
-- T-SQL equivalent:
SELECT 
    o.*,
    od.OrderDetailID,
    od.ProductID,
    od.Quantity,
    od.UnitPrice
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;

-- Solution 3:
SELECT 
    c.*,  -- All customer columns
    o.*   -- All order columns (note: duplicate CustomerID)
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Or better, exclude duplicate:
SELECT 
    c.*,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Solution 4:
/*
Explicit joins are better because:
1. Clear intent - shows exactly what columns are being matched
2. Maintainable - schema changes don't silently break queries
3. Debuggable - easy to see join logic
4. Flexible - can add complex conditions to ON clause
5. Self-documenting - code explains itself
6. Safe - no accidental matches on unintended columns
*/

-- Solution 5:
CREATE TABLE #Authors (
    AuthorID INT PRIMARY KEY,
    AuthorName VARCHAR(100)
);

CREATE TABLE #Books (
    BookID INT PRIMARY KEY,
    BookTitle VARCHAR(100),
    AuthorID INT  -- Matches Authors.AuthorID
);

-- Easy to join:
SELECT 
    a.AuthorName,
    b.BookTitle
FROM #Authors a
INNER JOIN #Books b ON a.AuthorID = b.AuthorID;

DROP TABLE #Books, #Authors;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ NATURAL JOIN:
  • Joins on all matching column names
  • Not supported in T-SQL
  • Can be dangerous (implicit behavior)
  • Use explicit ON clause instead

✓ USING CLAUSE:
  • Shorthand for equi-joins
  • Not supported in T-SQL
  • Less flexible than ON clause
  • Use ON with column names instead

✓ T-SQL PHILOSOPHY:
  • Explicit over implicit
  • Clear intent
  • Maintainability
  • Flexibility

✓ CROSS-PLATFORM:
  • Use ANSI-92 syntax (ON clause)
  • Works in all major databases
  • Most portable approach
  • Future-proof

✓ BEST PRACTICES:
  • Always use ON clause
  • Explicitly name columns
  • Use table aliases
  • Qualify all columns
  • Comment complex joins
  • Consistent naming across tables

✓ NAMING CONVENTIONS:
  • Use same names for related columns
  • Makes joins obvious
  • TableName + ID for foreign keys
  • Consistent across schema

✓ WHY IT MATTERS:
  • Code readability
  • Easier maintenance
  • Fewer bugs
  • Better performance
  • Team collaboration

============================================================================
NEXT: Lesson 10.06 - Multi-Table Joins
Master joining 3, 4, or more tables in complex queries.
============================================================================
*/
