/*
============================================================================
Lesson 10.02 - Outer Joins Deep Dive
============================================================================

Description:
Master LEFT, RIGHT, and FULL OUTER JOINs. Learn to preserve rows,
handle NULLs, find gaps and mismatches, and solve real-world problems
requiring complete data sets.

Topics Covered:
• LEFT OUTER JOIN mechanics
• RIGHT OUTER JOIN usage
• FULL OUTER JOIN applications
• NULL handling in outer joins
• Finding gaps and orphaned records
• ON vs WHERE with outer joins

Prerequisites:
• Lesson 10.01 (Join fundamentals)
• Understanding of NULL values

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: LEFT OUTER JOIN Fundamentals
============================================================================
*/

-- Example 1.1: Basic LEFT JOIN
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID;

/*
LEFT JOIN returns:
• ALL rows from left table (Customers)
• Matching rows from right table (Orders)
• NULL for right table columns when no match
*/

-- Example 1.2: Find customers with NO orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- Example 1.3: Count orders (including 0)
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY OrderCount DESC;

-- Example 1.4: Multiple LEFT JOINs
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    COUNT(DISTINCT od.ProductID) AS UniqueProducts
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CustomerName;


/*
============================================================================
PART 2: RIGHT OUTER JOIN
============================================================================
*/

-- Example 2.1: Basic RIGHT JOIN
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
RIGHT JOIN Orders o ON c.CustomerID = o.CustomerID;

/*
RIGHT JOIN returns:
• ALL rows from right table (Orders)
• Matching rows from left table (Customers)
• NULL for left table columns when no match

NOTE: RIGHT JOIN is rare - usually rewrite as LEFT JOIN
*/

-- Example 2.2: RIGHT JOIN rewritten as LEFT JOIN (preferred)
-- Same result as above:
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
LEFT JOIN Customers c ON c.CustomerID = o.CustomerID;

-- Example 2.3: When RIGHT JOIN makes sense (rarely)
-- All products with their order history
SELECT 
    od.ProductID,
    p.ProductName,
    od.Quantity
FROM OrderDetails od
RIGHT JOIN Products p ON od.ProductID = p.ProductID;

-- Better as LEFT JOIN:
SELECT 
    p.ProductID,
    p.ProductName,
    od.Quantity
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID;


/*
============================================================================
PART 3: FULL OUTER JOIN
============================================================================
*/

-- Example 3.1: FULL OUTER JOIN concept
-- Create temp tables to demonstrate
CREATE TABLE #Employees (EmployeeID INT, EmployeeName VARCHAR(50));
CREATE TABLE #Departments (DeptID INT, DeptName VARCHAR(50), ManagerID INT);

INSERT INTO #Employees VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Charlie');
INSERT INTO #Departments VALUES (1, 'Sales', 2), (2, 'IT', 99), (3, 'HR', 1);

-- FULL OUTER JOIN returns ALL rows from BOTH tables
SELECT 
    e.EmployeeID,
    e.EmployeeName,
    d.DeptID,
    d.DeptName
FROM #Employees e
FULL OUTER JOIN #Departments d ON e.EmployeeID = d.ManagerID;

/*
Results include:
• Employees who manage departments
• Employees who don't manage departments (NULL dept)
• Departments with no manager in Employees table (NULL employee)
*/

DROP TABLE #Employees, #Departments;

-- Example 3.2: Find all customers and products with order relationships
SELECT 
    c.CustomerName,
    p.ProductName,
    od.Quantity
FROM Customers c
FULL OUTER JOIN Orders o ON c.CustomerID = o.CustomerID
FULL OUTER JOIN OrderDetails od ON o.OrderID = od.OrderID
FULL OUTER JOIN Products p ON od.ProductID = p.ProductID
WHERE c.CustomerID = 1 OR p.ProductID = 1;

-- Example 3.3: Comparing two lists
CREATE TABLE #List1 (ID INT, Value VARCHAR(20));
CREATE TABLE #List2 (ID INT, Value VARCHAR(20));

INSERT INTO #List1 VALUES (1, 'Apple'), (2, 'Banana'), (3, 'Cherry');
INSERT INTO #List2 VALUES (2, 'Banana'), (3, 'Cherry'), (4, 'Date');

-- Find items in either or both lists
SELECT 
    COALESCE(l1.ID, l2.ID) AS ID,
    COALESCE(l1.Value, l2.Value) AS Value,
    CASE 
        WHEN l1.ID IS NULL THEN 'Only in List 2'
        WHEN l2.ID IS NULL THEN 'Only in List 1'
        ELSE 'In Both'
    END AS Location
FROM #List1 l1
FULL OUTER JOIN #List2 l2 ON l1.ID = l2.ID;

DROP TABLE #List1, #List2;


/*
============================================================================
PART 4: NULL Handling in Outer Joins
============================================================================
*/

-- Example 4.1: ISNULL with aggregates
SELECT 
    c.CustomerName,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent,
    ISNULL(AVG(o.TotalAmount), 0) AS AvgOrderValue,
    COUNT(o.OrderID) AS OrderCount  -- COUNT ignores NULL
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;

-- Example 4.2: COALESCE for multiple NULLs
SELECT 
    c.CustomerID,
    c.CustomerName,
    COALESCE(o.TotalAmount, 0) AS OrderAmount,
    COALESCE(c.Email, 'No email') AS ContactEmail
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Example 4.3: NULL in calculations
SELECT 
    c.CustomerName,
    o.TotalAmount,
    o.TotalAmount * 0.1 AS Tax,  -- NULL if TotalAmount is NULL
    ISNULL(o.TotalAmount, 0) * 0.1 AS TaxSafe  -- Always returns number
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Example 4.4: IS NULL vs = NULL (common mistake!)
-- ❌ Wrong - never finds NULLs:
SELECT c.CustomerName
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID = NULL;  -- Always FALSE!

-- ✅ Correct:
SELECT c.CustomerName
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;


/*
============================================================================
PART 5: ON vs WHERE in Outer Joins
============================================================================
*/

-- Example 5.1: Filter in ON clause (preserves outer join)
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01';  -- Filter in ON

/*
Returns: ALL customers
• With orders from 2024+ (if they have any)
• With NULL for orders if no 2024 orders
*/

-- Example 5.2: Filter in WHERE clause (converts to inner join!)
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01';  -- Filter in WHERE

/*
Returns: ONLY customers with orders from 2024+
• WHERE clause filters out NULL OrderDate
• Effectively converts LEFT JOIN to INNER JOIN
*/

-- Example 5.3: Combining ON and WHERE correctly
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500  -- Only join large orders
WHERE c.Country = 'USA';      -- But include all USA customers

-- Example 5.4: Multiple conditions
SELECT 
    p.ProductName,
    od.Quantity,
    od.UnitPrice
FROM Products p
LEFT JOIN OrderDetails od 
    ON p.ProductID = od.ProductID
    AND od.Quantity > 5
    AND od.UnitPrice < p.Price  -- Sold at discount
WHERE p.CategoryID = 1;


/*
============================================================================
PART 6: Finding Gaps and Orphans
============================================================================
*/

-- Gap 6.1: Customers with no orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.SignupDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- Gap 6.2: Products never ordered
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.Stock
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL;

-- Gap 6.3: Customers with no recent orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS DaysSinceOrder
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING MAX(o.OrderDate) < DATEADD(MONTH, -6, GETDATE())
    OR MAX(o.OrderDate) IS NULL;

-- Gap 6.4: Orders without customer (orphaned records)
SELECT 
    o.OrderID,
    o.CustomerID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

-- Gap 6.5: Products in categories that don't exist
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryID IS NULL;


/*
============================================================================
PART 7: Complex Outer Join Scenarios
============================================================================
*/

-- Scenario 7.1: Customer order summary (all customers)
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent,
    ISNULL(AVG(o.TotalAmount), 0) AS AvgOrderValue,
    MAX(o.OrderDate) AS LastOrderDate,
    CASE 
        WHEN COUNT(o.OrderID) = 0 THEN 'No Orders'
        WHEN MAX(o.OrderDate) < DATEADD(MONTH, -3, GETDATE()) THEN 'Inactive'
        WHEN SUM(o.TotalAmount) > 10000 THEN 'VIP'
        ELSE 'Active'
    END AS CustomerStatus
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpent DESC;

-- Scenario 7.2: Product inventory analysis
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.Stock,
    ISNULL(SUM(od.Quantity), 0) AS TotalSold,
    COUNT(DISTINCT od.OrderID) AS TimesOrdered,
    CASE 
        WHEN SUM(od.Quantity) IS NULL THEN 'Never Sold'
        WHEN p.Stock = 0 THEN 'Out of Stock'
        WHEN p.Stock < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS StockStatus
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Price, p.Stock
ORDER BY TotalSold DESC;

-- Scenario 7.3: Category performance (including empty categories)
SELECT 
    c.CategoryID,
    c.CategoryName,
    COUNT(DISTINCT p.ProductID) AS ProductCount,
    COUNT(DISTINCT od.OrderID) AS OrderCount,
    ISNULL(SUM(od.Quantity * od.UnitPrice), 0) AS TotalRevenue
FROM Categories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY TotalRevenue DESC;

-- Scenario 7.4: Time-based gap analysis
WITH DateRange AS (
    SELECT CAST('2024-01-01' AS DATE) AS OrderDate
    UNION ALL
    SELECT DATEADD(DAY, 1, OrderDate)
    FROM DateRange
    WHERE OrderDate < '2024-01-31'
)
SELECT 
    dr.OrderDate,
    COUNT(o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalAmount), 0) AS DailyRevenue
FROM DateRange dr
LEFT JOIN Orders o ON CAST(o.OrderDate AS DATE) = dr.OrderDate
GROUP BY dr.OrderDate
ORDER BY dr.OrderDate
OPTION (MAXRECURSION 31);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find all products and show how many times each was ordered (include 0)
2. List customers with their last order date (include customers with no orders)
3. Find all categories and count products in each (include empty categories)
4. Identify products that exist but have never been in an order
5. Show orders with customer info, including orphaned orders (if any)

Solutions below ↓
*/

-- Solution 1:
SELECT 
    p.ProductID,
    p.ProductName,
    COUNT(od.OrderID) AS TimesOrdered,
    ISNULL(SUM(od.Quantity), 0) AS TotalQuantity
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TimesOrdered DESC;

-- Solution 2:
SELECT 
    c.CustomerID,
    c.CustomerName,
    MAX(o.OrderDate) AS LastOrderDate,
    CASE 
        WHEN MAX(o.OrderDate) IS NULL THEN 'Never Ordered'
        ELSE CAST(DATEDIFF(DAY, MAX(o.OrderDate), GETDATE()) AS VARCHAR) + ' days ago'
    END AS LastOrderInfo
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY LastOrderDate DESC;

-- Solution 3:
SELECT 
    c.CategoryID,
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount
FROM Categories c
LEFT JOIN Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY ProductCount DESC;

-- Solution 4:
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.Stock
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL
ORDER BY p.ProductName;

-- Solution 5:
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    c.CustomerName,
    CASE 
        WHEN c.CustomerID IS NULL THEN 'Orphaned Order'
        ELSE 'Valid Order'
    END AS OrderStatus
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY OrderStatus, o.OrderDate;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ LEFT OUTER JOIN:
  • Preserves ALL left table rows
  • NULL for unmatched right table columns
  • Most common outer join
  • Use for "include all, match if possible"

✓ RIGHT OUTER JOIN:
  • Preserves ALL right table rows
  • Rarely used (rewrite as LEFT JOIN)
  • Same logic as LEFT, opposite direction

✓ FULL OUTER JOIN:
  • Preserves ALL rows from BOTH tables
  • NULL for unmatched columns from either side
  • Use for "everything from both" scenarios
  • Great for comparing two datasets

✓ NULL HANDLING:
  • Use ISNULL/COALESCE for defaults
  • COUNT() ignores NULL
  • SUM(NULL) returns NULL (use ISNULL)
  • Always use IS NULL, not = NULL

✓ ON vs WHERE:
  • ON: Join conditions (can filter right table in outer join)
  • WHERE: Result filters (can convert outer join to inner)
  • Be careful mixing them!

✓ FINDING GAPS:
  • LEFT JOIN + WHERE IS NULL
  • Finds missing relationships
  • Identifies orphaned records
  • Useful for data quality checks

✓ COMMON PATTERNS:
  • All customers with order counts (including 0)
  • Products never ordered
  • Orphaned records detection
  • Gap analysis in sequences
  • Comparing two lists

✓ BEST PRACTICES:
  • LEFT JOIN more readable than RIGHT
  • Always handle NULL in outer joins
  • Put filters in correct clause (ON vs WHERE)
  • Use meaningful names for clarity
  • Comment complex outer join logic

============================================================================
NEXT: Lesson 10.03 - Self-Joins
Learn to join a table to itself for comparing rows and hierarchical data.
============================================================================
*/
