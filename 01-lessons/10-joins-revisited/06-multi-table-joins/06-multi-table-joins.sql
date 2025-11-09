/*
============================================================================
Lesson 10.06 - Multi-Table Joins
============================================================================

Description:
Master the art of joining 3, 4, or more tables in a single query.
Learn join order, mixed join types, complex relationships, and how
to maintain readability in multi-table queries.

Topics Covered:
• Joining 3+ tables
• Join execution order
• Mixed join types (INNER + LEFT)
• Complex relationships
• Query organization and readability
• Performance considerations

Prerequisites:
• Lessons 10.01-10.05
• Understanding of database schema

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Three-Table Joins
============================================================================
*/

-- Example 1.1: Basic 3-table join (Customer → Orders → OrderDetails)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    od.Quantity,
    od.UnitPrice
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE c.CustomerID = 1
ORDER BY o.OrderDate, od.ProductID;

-- Example 1.2: Three tables with aggregation
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(od.OrderDetailID) AS TotalItems,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalRevenue DESC;

-- Example 1.3: Three tables with filtering
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    od.Quantity
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE o.OrderDate >= '2024-01-01'
  AND od.Quantity > 5
ORDER BY o.OrderDate DESC;


/*
============================================================================
PART 2: Four-Table Joins
============================================================================
*/

-- Example 2.1: Complete order details (4 tables)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
ORDER BY o.OrderDate DESC, o.OrderID, p.ProductName;

-- Example 2.2: Adding category information (5 tables)
SELECT 
    c.CustomerName,
    o.OrderID,
    cat.CategoryName,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE c.CustomerID = 1
ORDER BY o.OrderDate DESC;

-- Example 2.3: Complex 4-table aggregation
SELECT 
    cat.CategoryName,
    p.ProductName,
    COUNT(DISTINCT o.OrderID) AS TimesOrdered,
    SUM(od.Quantity) AS TotalQuantity,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Categories cat
INNER JOIN Products p ON cat.CategoryID = p.CategoryID
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY cat.CategoryID, cat.CategoryName, p.ProductID, p.ProductName
HAVING COUNT(DISTINCT o.OrderID) > 3
ORDER BY TotalRevenue DESC;


/*
============================================================================
PART 3: Mixed Join Types
============================================================================
*/

-- Example 3.1: INNER + LEFT join combination
-- All customers, their orders (if any), and order details
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    od.ProductID,
    od.Quantity
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE c.CustomerID <= 5
ORDER BY c.CustomerID, o.OrderID;

-- Example 3.2: Finding customers with no orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- Example 3.3: Products never ordered
SELECT 
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    p.Price
FROM Categories cat
INNER JOIN Products p ON cat.CategoryID = p.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE od.ProductID IS NULL
ORDER BY cat.CategoryName, p.ProductName;

-- Example 3.4: Mixed joins with aggregation
-- All products with their sales (0 if never ordered)
SELECT 
    cat.CategoryName,
    p.ProductID,
    p.ProductName,
    COUNT(od.OrderDetailID) AS TimesOrdered,
    ISNULL(SUM(od.Quantity), 0) AS TotalQuantity,
    ISNULL(SUM(od.Quantity * od.UnitPrice), 0) AS TotalRevenue
FROM Categories cat
INNER JOIN Products p ON cat.CategoryID = p.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY cat.CategoryID, cat.CategoryName, p.ProductID, p.ProductName
ORDER BY cat.CategoryName, TotalRevenue DESC;


/*
============================================================================
PART 4: Join Execution Order
============================================================================
*/

-- Example 4.1: Join order matters for outer joins
-- Different results:

-- LEFT JOIN first (preserves all customers):
SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- Returns only customers with order details (INNER JOIN filters out NULLs)

-- INNER JOIN first:
SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
RIGHT JOIN Customers c ON o.CustomerID = c.CustomerID;
-- Same result as above

-- All customers preserved:
SELECT 
    c.CustomerName,
    o.OrderID,
    od.ProductID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID;
-- Returns all customers, even those with no orders

-- Example 4.2: Logical processing order
/*
FROM Customers c                           -- 1. Start with Customers
LEFT JOIN Orders o ...                     -- 2. Join Orders (preserve all Customers)
LEFT JOIN OrderDetails od ...              -- 3. Join OrderDetails (preserve all from previous)
WHERE ...                                  -- 4. Filter rows
GROUP BY ...                               -- 5. Group results
HAVING ...                                 -- 6. Filter groups
SELECT ...                                 -- 7. Choose columns
ORDER BY ...                               -- 8. Sort output
*/


/*
============================================================================
PART 5: Complex Relationships
============================================================================
*/

-- Example 5.1: Many-to-many through junction table
-- Products ↔ Orders (many-to-many via OrderDetails)
SELECT 
    p.ProductName,
    COUNT(DISTINCT o.OrderID) AS UniqueOrders,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    SUM(od.Quantity) AS TotalQuantitySold
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalQuantitySold DESC;

-- Example 5.2: Complex filtering across multiple tables
SELECT 
    c.CustomerName,
    cat.CategoryName,
    COUNT(DISTINCT o.OrderID) AS Orders,
    SUM(od.Quantity) AS Quantity,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.CustomerID, c.CustomerName, cat.CategoryID, cat.CategoryName
HAVING SUM(od.Quantity * od.UnitPrice) > 500
ORDER BY Revenue DESC;

-- Example 5.3: Self-join combined with regular joins
-- Products with similar products in same order
SELECT DISTINCT
    o.OrderID,
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    p1.CategoryID
FROM Orders o
INNER JOIN OrderDetails od1 ON o.OrderID = od1.OrderID
INNER JOIN Products p1 ON od1.ProductID = p1.ProductID
INNER JOIN OrderDetails od2 ON o.OrderID = od2.OrderID
INNER JOIN Products p2 ON od2.ProductID = p2.ProductID
WHERE p1.CategoryID = p2.CategoryID
  AND p1.ProductID < p2.ProductID
ORDER BY o.OrderID;


/*
============================================================================
PART 6: Query Organization and Readability
============================================================================
*/

-- Example 6.1: ✅ Well-formatted multi-table join
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal
FROM Customers c
    INNER JOIN Orders o 
        ON c.CustomerID = o.CustomerID
    INNER JOIN OrderDetails od 
        ON o.OrderID = od.OrderID
    INNER JOIN Products p 
        ON od.ProductID = p.ProductID
WHERE o.OrderDate >= '2024-01-01'
ORDER BY c.CustomerName, o.OrderDate, p.ProductName;

-- Example 6.2: ✅ Using meaningful aliases
SELECT 
    cust.CustomerName,
    ord.OrderDate,
    prod.ProductName,
    detail.Quantity
FROM Customers cust
    INNER JOIN Orders ord ON cust.CustomerID = ord.CustomerID
    INNER JOIN OrderDetails detail ON ord.OrderID = detail.OrderID
    INNER JOIN Products prod ON detail.ProductID = prod.ProductID;

-- Example 6.3: ✅ Breaking complex queries into CTEs
WITH CustomerOrders AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        o.OrderID,
        o.OrderDate
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.OrderDate >= '2024-01-01'
),
OrderProducts AS (
    SELECT 
        od.OrderID,
        p.ProductName,
        od.Quantity,
        od.UnitPrice
    FROM OrderDetails od
    INNER JOIN Products p ON od.ProductID = p.ProductID
)
SELECT 
    co.CustomerName,
    co.OrderDate,
    op.ProductName,
    op.Quantity,
    op.UnitPrice
FROM CustomerOrders co
INNER JOIN OrderProducts op ON co.OrderID = op.OrderID
ORDER BY co.CustomerName, co.OrderDate;


/*
============================================================================
PART 7: Performance Optimization
============================================================================
*/

-- Performance 7.1: ✅ Filter early
-- Good (filter in WHERE after all joins):
SELECT 
    c.CustomerName,
    o.OrderID,
    p.ProductName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE c.Country = 'USA'
  AND o.OrderDate >= '2024-01-01';

-- Better (filter in ON clause to reduce join size):
SELECT 
    c.CustomerName,
    o.OrderID,
    p.ProductName
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01'
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
WHERE c.Country = 'USA';

-- Performance 7.2: ✅ Index foreign keys
/*
CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);
CREATE INDEX IX_Products_CategoryID ON Products(CategoryID);
*/

-- Performance 7.3: ⚠️ Be careful with DISTINCT on multi-table joins
-- Can be expensive if result set is large
SELECT DISTINCT
    c.CustomerName,
    cat.CategoryName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID;

-- Better: Use GROUP BY if possible
SELECT 
    c.CustomerName,
    cat.CategoryName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY c.CustomerID, c.CustomerName, cat.CategoryID, cat.CategoryName;


/*
============================================================================
PART 8: Real-World Examples
============================================================================
*/

-- Example 8.1: Complete order report
SELECT 
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    c.Email,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS LineTotal,
    SUM(od.Quantity * od.UnitPrice) OVER (PARTITION BY o.OrderID) AS OrderTotal
FROM Orders o
    INNER JOIN Customers c ON o.CustomerID = c.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
    INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
WHERE o.OrderDate >= DATEADD(MONTH, -1, GETDATE())
ORDER BY o.OrderDate DESC, o.OrderID, p.ProductName;

-- Example 8.2: Customer purchase history by category
SELECT 
    c.CustomerName,
    cat.CategoryName,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.Quantity) AS ItemsPurchased,
    SUM(od.Quantity * od.UnitPrice) AS TotalSpent,
    AVG(od.UnitPrice) AS AvgPrice
FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
    INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY c.CustomerID, c.CustomerName, cat.CategoryID, cat.CategoryName
HAVING SUM(od.Quantity * od.UnitPrice) > 100
ORDER BY c.CustomerName, TotalSpent DESC;

-- Example 8.3: Product performance across customers
SELECT 
    p.ProductName,
    cat.CategoryName,
    COUNT(DISTINCT c.CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT o.OrderID) AS UniqueOrders,
    SUM(od.Quantity) AS TotalQuantity,
    MIN(od.UnitPrice) AS MinPrice,
    MAX(od.UnitPrice) AS MaxPrice,
    AVG(od.UnitPrice) AS AvgPrice,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
FROM Products p
    INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    LEFT JOIN Orders o ON od.OrderID = o.OrderID
    LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY p.ProductID, p.ProductName, cat.CategoryID, cat.CategoryName
ORDER BY TotalRevenue DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Join Customers, Orders, OrderDetails, and Products to show complete order info
2. Find customers who have ordered from at least 3 different categories
3. Show products that have been ordered by more than 5 different customers
4. Create a sales report by category and customer
5. Find orders containing products from multiple categories

Solutions below ↓
*/

-- Solution 1:
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Quantity * od.UnitPrice AS Total
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
ORDER BY c.CustomerName, o.OrderDate;

-- Solution 2:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(DISTINCT cat.CategoryID) AS CategoryCount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT cat.CategoryID) >= 3
ORDER BY CategoryCount DESC;

-- Solution 3:
SELECT 
    p.ProductID,
    p.ProductName,
    COUNT(DISTINCT c.CustomerID) AS UniqueCustomers
FROM Products p
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(DISTINCT c.CustomerID) > 5
ORDER BY UniqueCustomers DESC;

-- Solution 4:
SELECT 
    cat.CategoryName,
    c.CustomerName,
    COUNT(DISTINCT o.OrderID) AS Orders,
    SUM(od.Quantity) AS Quantity,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Categories cat
INNER JOIN Products p ON cat.CategoryID = p.CategoryID
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY cat.CategoryID, cat.CategoryName, c.CustomerID, c.CustomerName
ORDER BY cat.CategoryName, Revenue DESC;

-- Solution 5:
SELECT 
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    COUNT(DISTINCT cat.CategoryID) AS CategoryCount,
    STRING_AGG(DISTINCT cat.CategoryName, ', ') AS Categories
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY o.OrderID, o.OrderDate, c.CustomerID, c.CustomerName
HAVING COUNT(DISTINCT cat.CategoryID) > 1
ORDER BY CategoryCount DESC, o.OrderDate DESC;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ MULTI-TABLE JOINS:
  • Chain joins using ON clauses
  • Each join builds on previous result
  • Can join 3, 4, 5+ tables
  • Common in normalized databases

✓ JOIN ORDER:
  • Matters for outer joins (LEFT/RIGHT)
  • Doesn't matter for inner joins (optimizer decides)
  • LEFT JOIN then INNER JOIN filters results
  • Keep all LEFT JOINs together when possible

✓ MIXED JOIN TYPES:
  • Can combine INNER and LEFT joins
  • LEFT JOIN preserves left table rows
  • INNER JOIN after LEFT can filter nulls
  • Order is crucial

✓ READABILITY:
  • Use clear table aliases
  • Indent joins consistently
  • One join per line
  • Comment complex logic
  • Consider CTEs for very complex queries

✓ PERFORMANCE:
  • Index all foreign keys
  • Filter early (in ON or WHERE)
  • Avoid SELECT * with many joins
  • Use execution plans
  • Consider denormalization for reporting

✓ COMMON PATTERNS:
  • Customer → Orders → OrderDetails → Products
  • Many-to-many through junction table
  • Hierarchical data with self-joins
  • Aggregate across multiple tables

✓ BEST PRACTICES:
  • Qualify all column names
  • Use meaningful aliases
  • Format for readability
  • Test incrementally (add one join at a time)
  • Document business logic

✓ TROUBLESHOOTING:
  • Build query one join at a time
  • Check row counts at each step
  • Verify join conditions
  • Watch for Cartesian products
  • Use SELECT COUNT(*) to test

============================================================================
NEXT: Lesson 10.07 - Join Conditions and Filters
Learn the critical differences between ON and WHERE clauses.
============================================================================
*/
