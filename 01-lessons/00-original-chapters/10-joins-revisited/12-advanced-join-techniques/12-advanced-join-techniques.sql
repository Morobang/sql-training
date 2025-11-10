/*
============================================================================
Lesson 10.12 - Advanced Join Techniques
============================================================================

Description:
Master advanced join techniques including CROSS APPLY, OUTER APPLY,
lateral joins, conditional joins, and complex multi-table patterns.
These powerful features enable sophisticated data access patterns.

Topics Covered:
• CROSS APPLY and OUTER APPLY
• Lateral joins (correlated table expressions)
• Conditional joins
• Table-valued functions with joins
• Complex multi-table patterns
• Advanced performance techniques

Prerequisites:
• Lessons 10.01-10.11
• Understanding of table-valued functions

Estimated Time: 40 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: CROSS APPLY Fundamentals
============================================================================
*/

/*
CROSS APPLY:
• Like INNER JOIN for table-valued expressions
• Right side can reference left side (correlated)
• Returns rows only when right side produces results
• Essential for table-valued functions
*/

-- Example 1.1: Basic CROSS APPLY with inline query
-- Top 3 orders per customer
SELECT 
    c.CustomerID,
    c.CustomerName,
    top_orders.OrderID,
    top_orders.OrderDate,
    top_orders.TotalAmount
FROM Customers c
CROSS APPLY (
    SELECT TOP 3
        OrderID,
        OrderDate,
        TotalAmount
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) AS top_orders
ORDER BY c.CustomerID, top_orders.TotalAmount DESC;

/*
Execution Flow:
1. For EACH customer (left table)
2. Execute the subquery using customer's ID
3. Return results only if subquery produces rows
4. Combine customer data with subquery results
*/

-- Example 1.2: CROSS APPLY vs traditional approach
-- Traditional (complex):
WITH RankedOrders AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID 
            ORDER BY TotalAmount DESC
        ) AS rn
    FROM Orders o
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    ro.OrderID,
    ro.TotalAmount
FROM Customers c
INNER JOIN RankedOrders ro ON c.CustomerID = ro.CustomerID
WHERE ro.rn <= 3;

-- CROSS APPLY (cleaner):
SELECT 
    c.CustomerID,
    c.CustomerName,
    top_orders.*
FROM Customers c
CROSS APPLY (
    SELECT TOP 3 * 
    FROM Orders 
    WHERE CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) top_orders;

-- Example 1.3: CROSS APPLY with aggregations
SELECT 
    c.CustomerID,
    c.CustomerName,
    order_stats.OrderCount,
    order_stats.TotalSpent,
    order_stats.AvgOrderValue
FROM Customers c
CROSS APPLY (
    SELECT 
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Orders
    WHERE CustomerID = c.CustomerID
) order_stats
WHERE order_stats.OrderCount > 5;


/*
============================================================================
PART 2: OUTER APPLY Fundamentals
============================================================================
*/

/*
OUTER APPLY:
• Like LEFT OUTER JOIN for table-valued expressions
• Returns left rows even if right side produces no results
• NULLs for right side columns when no match
• Preserves all left table rows
*/

-- Example 2.1: OUTER APPLY - Include customers with no orders
SELECT 
    c.CustomerID,
    c.CustomerName,
    top_orders.OrderID,
    top_orders.OrderDate,
    top_orders.TotalAmount
FROM Customers c
OUTER APPLY (
    SELECT TOP 3
        OrderID,
        OrderDate,
        TotalAmount
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) AS top_orders
ORDER BY c.CustomerID;
-- Returns ALL customers, with NULLs if no orders

-- Example 2.2: OUTER APPLY vs LEFT JOIN difference
-- LEFT JOIN (limited):
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID;
-- Returns ALL orders or NULL

-- OUTER APPLY (flexible):
SELECT 
    c.CustomerName,
    recent.OrderID,
    recent.TotalAmount
FROM Customers c
OUTER APPLY (
    SELECT TOP 1 OrderID, TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) recent;
-- Returns MOST RECENT order per customer (or NULL)

-- Example 2.3: OUTER APPLY with calculations
SELECT 
    c.CustomerID,
    c.CustomerName,
    ISNULL(stats.OrderCount, 0) AS OrderCount,
    stats.LastOrderDate,
    stats.TotalSpent
FROM Customers c
OUTER APPLY (
    SELECT 
        COUNT(*) AS OrderCount,
        MAX(OrderDate) AS LastOrderDate,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    WHERE CustomerID = c.CustomerID
      AND OrderDate >= DATEADD(YEAR, -1, GETDATE())
) stats;


/*
============================================================================
PART 3: Table-Valued Functions with APPLY
============================================================================
*/

-- Example 3.1: Create inline table-valued function
GO
CREATE OR ALTER FUNCTION dbo.GetCustomerTopOrders
(
    @CustomerID INT,
    @TopN INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN)
        OrderID,
        OrderDate,
        TotalAmount
    FROM Orders
    WHERE CustomerID = @CustomerID
    ORDER BY TotalAmount DESC
);
GO

-- Use with CROSS APPLY:
SELECT 
    c.CustomerID,
    c.CustomerName,
    orders.OrderID,
    orders.TotalAmount
FROM Customers c
CROSS APPLY dbo.GetCustomerTopOrders(c.CustomerID, 3) orders
ORDER BY c.CustomerID, orders.TotalAmount DESC;

-- Example 3.2: Multi-statement table-valued function
GO
CREATE OR ALTER FUNCTION dbo.GetCustomerOrderStats
(
    @CustomerID INT
)
RETURNS @Results TABLE
(
    OrderCount INT,
    TotalSpent DECIMAL(10,2),
    AvgOrder DECIMAL(10,2),
    FirstOrder DATE,
    LastOrder DATE
)
AS
BEGIN
    INSERT INTO @Results
    SELECT 
        COUNT(*),
        SUM(TotalAmount),
        AVG(TotalAmount),
        MIN(OrderDate),
        MAX(OrderDate)
    FROM Orders
    WHERE CustomerID = @CustomerID;
    
    RETURN;
END;
GO

-- Use with OUTER APPLY:
SELECT 
    c.CustomerID,
    c.CustomerName,
    stats.*
FROM Customers c
OUTER APPLY dbo.GetCustomerOrderStats(c.CustomerID) stats;

-- Example 3.3: Split string function with APPLY
GO
CREATE OR ALTER FUNCTION dbo.SplitString
(
    @String VARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Results TABLE
(
    Value VARCHAR(100),
    Position INT
)
AS
BEGIN
    DECLARE @Pos INT = 1;
    DECLARE @NextPos INT;
    DECLARE @ValuePos INT = 1;
    
    WHILE @Pos <= LEN(@String)
    BEGIN
        SET @NextPos = CHARINDEX(@Delimiter, @String, @Pos);
        
        IF @NextPos = 0
            SET @NextPos = LEN(@String) + 1;
        
        INSERT INTO @Results
        VALUES (
            SUBSTRING(@String, @Pos, @NextPos - @Pos),
            @ValuePos
        );
        
        SET @Pos = @NextPos + 1;
        SET @ValuePos = @ValuePos + 1;
    END;
    
    RETURN;
END;
GO

-- Use to split comma-separated values:
DECLARE @Tags TABLE (ID INT, Tags VARCHAR(200));
INSERT INTO @Tags VALUES (1, 'electronics,gadgets,new');
INSERT INTO @Tags VALUES (2, 'clothing,sale');
INSERT INTO @Tags VALUES (3, 'food,organic,local');

SELECT 
    t.ID,
    split.Value AS Tag,
    split.Position
FROM @Tags t
CROSS APPLY dbo.SplitString(t.Tags, ',') split;


/*
============================================================================
PART 4: Conditional Joins
============================================================================
*/

-- Example 4.1: Join based on condition
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Country,
    related.*
FROM Customers c
OUTER APPLY (
    CASE 
        WHEN c.Country = 'USA' THEN
            -- For USA: Recent orders only
            (SELECT TOP 5 OrderID, OrderDate, TotalAmount
             FROM Orders
             WHERE CustomerID = c.CustomerID
               AND OrderDate >= DATEADD(MONTH, -3, GETDATE())
             ORDER BY OrderDate DESC)
        ELSE
            -- For others: All orders
            (SELECT TOP 5 OrderID, OrderDate, TotalAmount
             FROM Orders
             WHERE CustomerID = c.CustomerID
             ORDER BY OrderDate DESC)
    END
) related;
-- Different logic based on customer country

-- Example 4.2: Dynamic table selection
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    related_data.*
FROM Products p
OUTER APPLY (
    SELECT 
        CASE 
            WHEN p.CategoryID = 1 THEN 'Electronics'
            WHEN p.CategoryID = 2 THEN 'Clothing'
            ELSE 'Other'
        END AS CategoryName,
        (
            SELECT COUNT(*) 
            FROM OrderDetails 
            WHERE ProductID = p.ProductID
        ) AS TimesSold
) related_data;

-- Example 4.3: Conditional aggregation
SELECT 
    c.CustomerID,
    c.CustomerName,
    stats.*
FROM Customers c
CROSS APPLY (
    SELECT 
        COUNT(*) AS TotalOrders,
        SUM(CASE WHEN TotalAmount > 500 THEN 1 ELSE 0 END) AS LargeOrders,
        SUM(CASE WHEN OrderDate >= DATEADD(MONTH, -1, GETDATE()) THEN TotalAmount ELSE 0 END) AS RecentSpent
    FROM Orders
    WHERE CustomerID = c.CustomerID
) stats;


/*
============================================================================
PART 5: Complex Multi-Table Patterns
============================================================================
*/

-- Example 5.1: Nested APPLY for hierarchical data
SELECT 
    c.CustomerID,
    c.CustomerName,
    orders.OrderID,
    orders.OrderDate,
    order_details.ProductID,
    order_details.Quantity
FROM Customers c
CROSS APPLY (
    SELECT TOP 2 OrderID, OrderDate
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) orders
CROSS APPLY (
    SELECT ProductID, Quantity
    FROM OrderDetails
    WHERE OrderID = orders.OrderID
) order_details
WHERE c.CustomerID <= 3;
-- Top 2 orders per customer with all details

-- Example 5.2: APPLY with multiple sources
SELECT 
    c.CustomerID,
    c.CustomerName,
    first_order.OrderDate AS FirstOrderDate,
    last_order.OrderDate AS LastOrderDate,
    largest_order.TotalAmount AS LargestOrderAmount
FROM Customers c
OUTER APPLY (
    SELECT TOP 1 OrderDate
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate ASC
) first_order
OUTER APPLY (
    SELECT TOP 1 OrderDate
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) last_order
OUTER APPLY (
    SELECT TOP 1 TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) largest_order;

-- Example 5.3: APPLY with EXISTS pattern
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    similar_products.SimilarCount
FROM Products p
OUTER APPLY (
    SELECT COUNT(*) AS SimilarCount
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
      AND p2.ProductID <> p.ProductID
      AND ABS(p2.Price - p.Price) < 20
) similar_products
WHERE similar_products.SimilarCount > 0;


/*
============================================================================
PART 6: Performance Optimization
============================================================================
*/

-- Optimization 6.1: ✅ Use CROSS APPLY for Top N
-- Better than ROW_NUMBER for small N:
SET STATISTICS IO ON;

-- CROSS APPLY:
SELECT c.CustomerName, orders.*
FROM Customers c
CROSS APPLY (
    SELECT TOP 3 OrderID, TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) orders;

-- ROW_NUMBER (may be slower for small TOP):
WITH RankedOrders AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY TotalAmount DESC) AS rn
    FROM Orders o
)
SELECT c.CustomerName, ro.OrderID, ro.TotalAmount
FROM Customers c
INNER JOIN RankedOrders ro ON c.CustomerID = ro.CustomerID
WHERE ro.rn <= 3;

SET STATISTICS IO OFF;

-- Optimization 6.2: ✅ Index for APPLY operations
/*
-- Index the column used in WHERE clause:
CREATE INDEX IX_Orders_CustomerID_TotalAmount 
ON Orders(CustomerID, TotalAmount DESC);
-- Helps TOP N queries in APPLY
*/

-- Optimization 6.3: ⚠️ OUTER APPLY can be expensive
-- When possible, use LEFT JOIN:
-- Slower:
SELECT c.CustomerName, last_order.OrderDate
FROM Customers c
OUTER APPLY (
    SELECT TOP 1 OrderDate
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) last_order;

-- May be faster with windowing:
SELECT DISTINCT
    c.CustomerName,
    FIRST_VALUE(o.OrderDate) OVER (
        PARTITION BY c.CustomerID 
        ORDER BY o.OrderDate DESC
    ) AS LastOrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID;


/*
============================================================================
PART 7: Real-World Applications
============================================================================
*/

-- Application 7.1: Product recommendations
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    recommendations.RecommendedProduct,
    recommendations.RecommendedPrice
FROM Products p
CROSS APPLY (
    SELECT TOP 3
        p2.ProductName AS RecommendedProduct,
        p2.Price AS RecommendedPrice
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
      AND p2.ProductID <> p.ProductID
      AND ABS(p2.Price - p.Price) < 50
    ORDER BY ABS(p2.Price - p.Price)
) recommendations
WHERE p.ProductID <= 5;

-- Application 7.2: Customer purchase patterns
SELECT 
    c.CustomerID,
    c.CustomerName,
    patterns.TotalOrders,
    patterns.AvgDaysBetweenOrders,
    patterns.FavoriteCategory
FROM Customers c
CROSS APPLY (
    SELECT 
        COUNT(*) AS TotalOrders,
        AVG(DATEDIFF(DAY, 
            LAG(o.OrderDate) OVER (ORDER BY o.OrderDate),
            o.OrderDate
        )) AS AvgDaysBetweenOrders,
        (
            SELECT TOP 1 cat.CategoryName
            FROM Orders o2
            INNER JOIN OrderDetails od ON o2.OrderID = od.OrderID
            INNER JOIN Products p ON od.ProductID = p.ProductID
            INNER JOIN Categories cat ON p.CategoryID = cat.CategoryID
            WHERE o2.CustomerID = c.CustomerID
            GROUP BY cat.CategoryName
            ORDER BY COUNT(*) DESC
        ) AS FavoriteCategory
    FROM Orders o
    WHERE o.CustomerID = c.CustomerID
) patterns
WHERE patterns.TotalOrders >= 3;

-- Application 7.3: Dynamic date ranges
DECLARE @DateRanges TABLE (
    RangeName VARCHAR(50),
    DaysBack INT
);

INSERT INTO @DateRanges VALUES 
('Last 7 Days', 7),
('Last 30 Days', 30),
('Last 90 Days', 90);

SELECT 
    dr.RangeName,
    order_stats.OrderCount,
    order_stats.TotalRevenue,
    order_stats.AvgOrderValue
FROM @DateRanges dr
CROSS APPLY (
    SELECT 
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalRevenue,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Orders
    WHERE OrderDate >= DATEADD(DAY, -dr.DaysBack, GETDATE())
) order_stats;


/*
============================================================================
PART 8: Advanced Patterns
============================================================================
*/

-- Pattern 8.1: Unpivot with APPLY
DECLARE @CustomerStats TABLE (
    CustomerID INT,
    OrderCount INT,
    TotalSpent DECIMAL(10,2),
    AvgOrder DECIMAL(10,2)
);

INSERT INTO @CustomerStats
SELECT 
    CustomerID,
    COUNT(*),
    SUM(TotalAmount),
    AVG(TotalAmount)
FROM Orders
GROUP BY CustomerID;

-- Unpivot using CROSS APPLY:
SELECT 
    cs.CustomerID,
    metrics.MetricName,
    metrics.MetricValue
FROM @CustomerStats cs
CROSS APPLY (
    VALUES 
        ('OrderCount', CAST(cs.OrderCount AS DECIMAL(10,2))),
        ('TotalSpent', cs.TotalSpent),
        ('AvgOrder', cs.AvgOrder)
) metrics(MetricName, MetricValue);

-- Pattern 8.2: Generate series with APPLY
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    dates.ReportDate
FROM Customers c
CROSS APPLY (
    SELECT DATEADD(MONTH, -n.n, GETDATE()) AS ReportDate
    FROM Numbers n
) dates
WHERE c.CustomerID <= 2;


-- Clean up functions
DROP FUNCTION IF EXISTS dbo.GetCustomerTopOrders;
DROP FUNCTION IF EXISTS dbo.GetCustomerOrderStats;
DROP FUNCTION IF EXISTS dbo.SplitString;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Use CROSS APPLY to get top 2 products per category by price
2. Use OUTER APPLY to show all customers with their most recent order (or NULL)
3. Create a table-valued function and use it with APPLY
4. Compare performance of CROSS APPLY vs ROW_NUMBER for Top 5
5. Use nested APPLY to get customers → orders → order details

Solutions below ↓
*/

-- Solution 1:
SELECT 
    cat.CategoryID,
    cat.CategoryName,
    top_products.ProductName,
    top_products.Price
FROM Categories cat
CROSS APPLY (
    SELECT TOP 2 ProductName, Price
    FROM Products
    WHERE CategoryID = cat.CategoryID
    ORDER BY Price DESC
) top_products
ORDER BY cat.CategoryID, top_products.Price DESC;

-- Solution 2:
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email,
    recent.OrderID,
    recent.OrderDate,
    recent.TotalAmount
FROM Customers c
OUTER APPLY (
    SELECT TOP 1 OrderID, OrderDate, TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) recent;

-- Solution 3:
GO
CREATE FUNCTION dbo.GetProductsByCategory(@CategoryID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE CategoryID = @CategoryID
);
GO

SELECT cat.CategoryName, prods.*
FROM Categories cat
CROSS APPLY dbo.GetProductsByCategory(cat.CategoryID) prods;

DROP FUNCTION dbo.GetProductsByCategory;
GO

-- Solution 4:
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- CROSS APPLY:
SELECT c.CustomerName, top5.*
FROM Customers c
CROSS APPLY (
    SELECT TOP 5 OrderID, TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) top5;

-- ROW_NUMBER:
WITH Ranked AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) AS rn
    FROM Orders o
)
SELECT c.CustomerName, r.OrderID, r.TotalAmount
FROM Customers c
INNER JOIN Ranked r ON c.CustomerID = r.CustomerID
WHERE r.rn <= 5;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- Solution 5:
SELECT 
    c.CustomerID,
    c.CustomerName,
    orders.OrderID,
    orders.OrderDate,
    details.ProductID,
    details.Quantity
FROM Customers c
CROSS APPLY (
    SELECT TOP 2 OrderID, OrderDate
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) orders
CROSS APPLY (
    SELECT ProductID, Quantity
    FROM OrderDetails
    WHERE OrderID = orders.OrderID
) details
WHERE c.CustomerID <= 3;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CROSS APPLY:
  • Like INNER JOIN for table expressions
  • Right side can reference left side
  • Returns rows only when match exists
  • Perfect for Top N per group
  • Works with table-valued functions

✓ OUTER APPLY:
  • Like LEFT JOIN for table expressions
  • Preserves left rows (NULLs if no match)
  • Essential for optional correlated data
  • More flexible than regular LEFT JOIN

✓ ADVANTAGES:
  • Top N per group (cleaner than ROW_NUMBER)
  • Lateral correlation (reference outer table)
  • Works with table-valued functions
  • Dynamic/conditional logic
  • Multiple separate queries per row

✓ TABLE-VALUED FUNCTIONS:
  • Inline TVFs (best performance)
  • Multi-statement TVFs (more flexible)
  • Reusable logic
  • Can have parameters from outer query

✓ PERFORMANCE:
  • Index columns in WHERE clause
  • CROSS APPLY often faster than ROW_NUMBER for small TOP
  • OUTER APPLY can be expensive
  • Test with execution plans
  • Consider window functions as alternative

✓ USE CASES:
  • Top N per group
  • Most recent/oldest per group
  • Table-valued functions
  • Split string operations
  • Dynamic/conditional joins
  • Hierarchical data access
  • Unpivoting data

✓ BEST PRACTICES:
  • Use CROSS APPLY for Top N
  • Prefer inline TVFs
  • Index appropriately
  • Test performance vs alternatives
  • Use when correlation needed
  • Comment complex APPLY logic

✓ ALTERNATIVES:
  • ROW_NUMBER + WHERE rn <= N
  • Window functions (FIRST_VALUE, LAST_VALUE)
  • Regular JOIN when no correlation needed
  • CTEs for readability

============================================================================
NEXT: Lesson 10.13 - Test Your Knowledge
Comprehensive assessment of all join concepts.
============================================================================
*/
