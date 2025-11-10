/*
============================================================================
Lesson 09.10 - Subqueries as Data Sources
============================================================================

Description:
Master using subqueries in the FROM clause as derived tables and inline
views. Learn Common Table Expressions (CTEs) and table expressions for
building complex queries from intermediate result sets.

Topics Covered:
• Derived tables (subqueries in FROM)
• Inline views
• Common Table Expressions (CTEs)
• Multiple CTEs
• Recursive CTEs
• Best practices

Prerequisites:
• Lessons 09.01-09.09
• Understanding of JOINs

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Derived Tables - Subqueries in FROM Clause
============================================================================
*/

-- Example 1.1: Basic derived table
SELECT 
    OrderYear,
    TotalOrders,
    TotalRevenue
FROM (
    SELECT 
        YEAR(OrderDate) AS OrderYear,
        COUNT(*) AS TotalOrders,
        SUM(TotalAmount) AS TotalRevenue
    FROM Orders
    GROUP BY YEAR(OrderDate)
) AS YearlySummary
WHERE TotalOrders > 50;

-- Example 1.2: Derived table with JOIN
SELECT 
    c.CustomerName,
    cs.OrderCount,
    cs.TotalSpent
FROM Customers c
INNER JOIN (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
) AS cs ON c.CustomerID = cs.CustomerID
WHERE cs.TotalSpent > 1000;

-- Example 1.3: Multiple derived tables
SELECT 
    hp.ProductName AS HighPriceProduct,
    hp.Price AS HighPrice,
    lp.ProductName AS LowPriceProduct,
    lp.Price AS LowPrice
FROM (
    SELECT TOP 1 ProductID, ProductName, Price
    FROM Products
    ORDER BY Price DESC
) AS hp
CROSS JOIN (
    SELECT TOP 1 ProductID, ProductName, Price
    FROM Products
    ORDER BY Price ASC
) AS lp;

-- Example 1.4: Derived table from complex query
SELECT 
    CategoryName,
    AvgProductPrice,
    ProductCount
FROM (
    SELECT 
        c.CategoryName,
        AVG(p.Price) AS AvgProductPrice,
        COUNT(p.ProductID) AS ProductCount
    FROM Categories c
    LEFT JOIN Products p ON c.CategoryID = p.CategoryID
    GROUP BY c.CategoryID, c.CategoryName
) AS CategoryStats
WHERE ProductCount > 5;


/*
============================================================================
PART 2: Inline Views and Complex Filtering
============================================================================
*/

-- Example 2.1: Filter aggregated results
SELECT ProductID, ProductName, TotalSold
FROM (
    SELECT 
        p.ProductID,
        p.ProductName,
        ISNULL(SUM(od.Quantity), 0) AS TotalSold
    FROM Products p
    LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName
) AS ProductSales
WHERE TotalSold > 100
ORDER BY TotalSold DESC;

-- Example 2.2: Ranking within derived table
SELECT 
    CategoryName,
    ProductName,
    Price,
    PriceRank
FROM (
    SELECT 
        c.CategoryName,
        p.ProductName,
        p.Price,
        ROW_NUMBER() OVER (PARTITION BY c.CategoryID ORDER BY p.Price DESC) AS PriceRank
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
) AS RankedProducts
WHERE PriceRank <= 3;

-- Example 2.3: Calculate percentages from aggregates
SELECT 
    CustomerName,
    TotalSpent,
    (TotalSpent / GrandTotal) * 100 AS PercentOfTotal
FROM (
    SELECT 
        c.CustomerName,
        SUM(o.TotalAmount) AS TotalSpent,
        SUM(SUM(o.TotalAmount)) OVER () AS GrandTotal
    FROM Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
) AS CustomerSpending
ORDER BY TotalSpent DESC;


/*
============================================================================
PART 3: Common Table Expressions (CTEs)
============================================================================
*/

-- Example 3.1: Basic CTE
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(TotalAmount) AS MonthlyRevenue
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    OrderYear,
    OrderMonth,
    MonthlyRevenue
FROM MonthlySales
WHERE MonthlyRevenue > 5000
ORDER BY OrderYear, OrderMonth;

-- Example 3.2: CTE vs Derived Table comparison
-- Same query, different syntax

-- Derived table (nested, harder to read):
SELECT CategoryName, AvgPrice
FROM (
    SELECT 
        c.CategoryName,
        AVG(p.Price) AS AvgPrice
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    GROUP BY c.CategoryName
) AS CategoryPrices
WHERE AvgPrice > 75;

-- CTE (cleaner, reads top-to-bottom):
WITH CategoryPrices AS (
    SELECT 
        c.CategoryName,
        AVG(p.Price) AS AvgPrice
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    GROUP BY c.CategoryName
)
SELECT CategoryName, AvgPrice
FROM CategoryPrices
WHERE AvgPrice > 75;

-- Example 3.3: CTE with multiple references
WITH CustomerStats AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    c.CustomerName,
    cs.OrderCount,
    cs.TotalSpent,
    cs.AvgOrderValue,
    CASE 
        WHEN cs.TotalSpent >= 10000 THEN 'VIP'
        WHEN cs.TotalSpent >= 5000 THEN 'Gold'
        WHEN cs.TotalSpent >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerTier
FROM Customers c
JOIN CustomerStats cs ON c.CustomerID = cs.CustomerID
WHERE cs.OrderCount > 3
ORDER BY cs.TotalSpent DESC;


/*
============================================================================
PART 4: Multiple CTEs
============================================================================
*/

-- Example 4.1: Sequential CTEs
WITH ProductSales AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS TotalQuantity,
        SUM(Quantity * UnitPrice) AS TotalRevenue
    FROM OrderDetails
    GROUP BY ProductID
),
ProductInfo AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.CategoryID,
        p.Price,
        ps.TotalQuantity,
        ps.TotalRevenue
    FROM Products p
    LEFT JOIN ProductSales ps ON p.ProductID = ps.ProductID
),
CategoryStats AS (
    SELECT 
        CategoryID,
        AVG(TotalQuantity) AS AvgCategoryQuantity
    FROM ProductInfo
    GROUP BY CategoryID
)
SELECT 
    pi.ProductName,
    pi.TotalQuantity,
    cs.AvgCategoryQuantity,
    CASE 
        WHEN pi.TotalQuantity > cs.AvgCategoryQuantity THEN 'Above Average'
        ELSE 'Below Average'
    END AS Performance
FROM ProductInfo pi
JOIN CategoryStats cs ON pi.CategoryID = cs.CategoryID
WHERE pi.TotalQuantity IS NOT NULL
ORDER BY pi.TotalQuantity DESC;

-- Example 4.2: CTEs building on each other
WITH DailyOrders AS (
    SELECT 
        CAST(OrderDate AS DATE) AS OrderDate,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS DailyRevenue
    FROM Orders
    GROUP BY CAST(OrderDate AS DATE)
),
WeeklyAverages AS (
    SELECT 
        DATEPART(WEEK, OrderDate) AS WeekNumber,
        AVG(OrderCount) AS AvgOrdersPerDay,
        AVG(DailyRevenue) AS AvgRevenuePerDay
    FROM DailyOrders
    GROUP BY DATEPART(WEEK, OrderDate)
)
SELECT 
    WeekNumber,
    AvgOrdersPerDay,
    AvgRevenuePerDay,
    AvgRevenuePerDay / NULLIF(AvgOrdersPerDay, 0) AS AvgOrderValue
FROM WeeklyAverages
ORDER BY WeekNumber;

-- Example 4.3: Multiple independent CTEs
WITH HighValueCustomers AS (
    SELECT CustomerID, SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
    HAVING SUM(TotalAmount) > 5000
),
FrequentCustomers AS (
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
    HAVING COUNT(*) > 10
),
RecentCustomers AS (
    SELECT DISTINCT CustomerID
    FROM Orders
    WHERE OrderDate >= DATEADD(MONTH, -3, GETDATE())
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    hv.TotalSpent,
    fc.OrderCount,
    CASE WHEN rc.CustomerID IS NOT NULL THEN 'Yes' ELSE 'No' END AS RecentlyActive
FROM Customers c
LEFT JOIN HighValueCustomers hv ON c.CustomerID = hv.CustomerID
LEFT JOIN FrequentCustomers fc ON c.CustomerID = fc.CustomerID
LEFT JOIN RecentCustomers rc ON c.CustomerID = rc.CustomerID
WHERE hv.CustomerID IS NOT NULL 
   OR fc.CustomerID IS NOT NULL 
   OR rc.CustomerID IS NOT NULL;


/*
============================================================================
PART 5: Recursive CTEs
============================================================================
*/

-- Example 5.1: Generate number sequence
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM Numbers
    WHERE n < 10
)
SELECT n FROM Numbers;

-- Example 5.2: Date range generation
WITH DateRange AS (
    SELECT CAST('2024-01-01' AS DATE) AS OrderDate
    UNION ALL
    SELECT DATEADD(DAY, 1, OrderDate)
    FROM DateRange
    WHERE OrderDate < '2024-01-31'
)
SELECT 
    dr.OrderDate,
    ISNULL(COUNT(o.OrderID), 0) AS OrderCount
FROM DateRange dr
LEFT JOIN Orders o ON CAST(o.OrderDate AS DATE) = dr.OrderDate
GROUP BY dr.OrderDate
ORDER BY dr.OrderDate;

-- Example 5.3: Hierarchical data (simulated)
-- If we had an employee table with ManagerID:
/*
WITH EmployeeHierarchy AS (
    -- Anchor: Top-level employees
    SELECT 
        EmployeeID,
        EmployeeName,
        ManagerID,
        0 AS Level,
        CAST(EmployeeName AS VARCHAR(MAX)) AS HierarchyPath
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive: Employees reporting to previous level
    SELECT 
        e.EmployeeID,
        e.EmployeeName,
        e.ManagerID,
        eh.Level + 1,
        CAST(eh.HierarchyPath + ' > ' + e.EmployeeName AS VARCHAR(MAX))
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
    WHERE eh.Level < 10  -- Prevent infinite loops
)
SELECT 
    REPLICATE('  ', Level) + EmployeeName AS OrgChart,
    Level,
    HierarchyPath
FROM EmployeeHierarchy
ORDER BY HierarchyPath;
*/


/*
============================================================================
PART 6: Practical Applications
============================================================================
*/

-- Application 6.1: Running totals with CTE
WITH OrderedSales AS (
    SELECT 
        CAST(OrderDate AS DATE) AS OrderDate,
        SUM(TotalAmount) AS DailyRevenue
    FROM Orders
    GROUP BY CAST(OrderDate AS DATE)
)
SELECT 
    OrderDate,
    DailyRevenue,
    SUM(DailyRevenue) OVER (ORDER BY OrderDate) AS RunningTotal
FROM OrderedSales
ORDER BY OrderDate;

-- Application 6.2: Gap analysis
WITH ExpectedDates AS (
    SELECT CAST('2024-01-01' AS DATE) AS ExpectedDate
    UNION ALL
    SELECT DATEADD(DAY, 1, ExpectedDate)
    FROM ExpectedDates
    WHERE ExpectedDate < '2024-12-31'
),
ActualOrders AS (
    SELECT DISTINCT CAST(OrderDate AS DATE) AS OrderDate
    FROM Orders
)
SELECT ed.ExpectedDate AS MissingDate
FROM ExpectedDates ed
LEFT JOIN ActualOrders ao ON ed.ExpectedDate = ao.OrderDate
WHERE ao.OrderDate IS NULL
  AND ed.ExpectedDate <= GETDATE()
ORDER BY ed.ExpectedDate
OPTION (MAXRECURSION 366);

-- Application 6.3: Pivot-like transformation
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(TotalAmount) AS Revenue
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    OrderYear,
    SUM(CASE WHEN OrderMonth = 1 THEN Revenue ELSE 0 END) AS Jan,
    SUM(CASE WHEN OrderMonth = 2 THEN Revenue ELSE 0 END) AS Feb,
    SUM(CASE WHEN OrderMonth = 3 THEN Revenue ELSE 0 END) AS Mar,
    SUM(CASE WHEN OrderMonth = 4 THEN Revenue ELSE 0 END) AS Apr,
    SUM(Revenue) AS YearTotal
FROM MonthlySales
GROUP BY OrderYear;

-- Application 6.4: Deduplication
WITH RankedOrders AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY CustomerID, OrderDate ORDER BY OrderID) AS rn
    FROM Orders
)
SELECT 
    OrderID,
    CustomerID,
    OrderDate,
    TotalAmount
FROM RankedOrders
WHERE rn = 1;  -- Keep only first order per customer per day


/*
============================================================================
PART 7: CTE vs Derived Table - When to Use Each
============================================================================
*/

-- Use CTE when:
-- ✅ Complex logic (readability)
-- ✅ Multiple references to same subquery
-- ✅ Recursive queries needed
-- ✅ Team collaboration (easier to understand)

-- Use Derived Table when:
-- ✅ Simple, one-time use
-- ✅ Very small queries
-- ✅ Legacy code compatibility
-- ✅ Inline with main query logic

-- Example showing why CTE is better for complex queries:

-- ❌ Derived table (hard to follow):
SELECT 
    a.CategoryName,
    a.AvgPrice,
    b.MaxPrice,
    c.ProductCount
FROM (
    SELECT CategoryID, AVG(Price) AS AvgPrice FROM Products GROUP BY CategoryID
) a
JOIN (
    SELECT CategoryID, MAX(Price) AS MaxPrice FROM Products GROUP BY CategoryID
) b ON a.CategoryID = b.CategoryID
JOIN (
    SELECT CategoryID, COUNT(*) AS ProductCount FROM Products GROUP BY CategoryID
) c ON a.CategoryID = c.CategoryID
JOIN Categories cat ON a.CategoryID = cat.CategoryID;

-- ✅ CTE (clear and maintainable):
WITH CategoryAvg AS (
    SELECT CategoryID, AVG(Price) AS AvgPrice 
    FROM Products 
    GROUP BY CategoryID
),
CategoryMax AS (
    SELECT CategoryID, MAX(Price) AS MaxPrice 
    FROM Products 
    GROUP BY CategoryID
),
CategoryCount AS (
    SELECT CategoryID, COUNT(*) AS ProductCount 
    FROM Products 
    GROUP BY CategoryID
)
SELECT 
    cat.CategoryName,
    ca.AvgPrice,
    cm.MaxPrice,
    cc.ProductCount
FROM Categories cat
JOIN CategoryAvg ca ON cat.CategoryID = ca.CategoryID
JOIN CategoryMax cm ON cat.CategoryID = cm.CategoryID
JOIN CategoryCount cc ON cat.CategoryID = cc.CategoryID;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a derived table showing products with above-average prices
2. Write a CTE to find customers who spent more than average
3. Use multiple CTEs to rank products by sales within each category
4. Create a recursive CTE to generate the first 20 Fibonacci numbers
5. Build a CTE that finds gaps in order IDs

Solutions below ↓
*/

-- Solution 1:
SELECT ProductID, ProductName, Price, AvgPrice
FROM (
    SELECT 
        ProductID,
        ProductName,
        Price,
        (SELECT AVG(Price) FROM Products) AS AvgPrice
    FROM Products
) AS ProductPrices
WHERE Price > AvgPrice;

-- Solution 2:
WITH CustomerTotals AS (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
),
AverageSpending AS (
    SELECT AVG(TotalSpent) AS AvgSpent
    FROM CustomerTotals
)
SELECT 
    c.CustomerName,
    ct.TotalSpent,
    asp.AvgSpent
FROM Customers c
JOIN CustomerTotals ct ON c.CustomerID = ct.CustomerID
CROSS JOIN AverageSpending asp
WHERE ct.TotalSpent > asp.AvgSpent
ORDER BY ct.TotalSpent DESC;

-- Solution 3:
WITH ProductSales AS (
    SELECT 
        ProductID,
        SUM(Quantity) AS TotalSold
    FROM OrderDetails
    GROUP BY ProductID
),
RankedProducts AS (
    SELECT 
        p.CategoryID,
        p.ProductName,
        ps.TotalSold,
        ROW_NUMBER() OVER (PARTITION BY p.CategoryID ORDER BY ps.TotalSold DESC) AS SalesRank
    FROM Products p
    JOIN ProductSales ps ON p.ProductID = ps.ProductID
)
SELECT 
    c.CategoryName,
    rp.ProductName,
    rp.TotalSold,
    rp.SalesRank
FROM RankedProducts rp
JOIN Categories c ON rp.CategoryID = c.CategoryID
WHERE rp.SalesRank <= 5
ORDER BY c.CategoryName, rp.SalesRank;

-- Solution 4:
WITH Fibonacci AS (
    SELECT 1 AS n, 0 AS Fib, 1 AS NextFib
    UNION ALL
    SELECT n + 1, NextFib, Fib + NextFib
    FROM Fibonacci
    WHERE n < 20
)
SELECT n, Fib AS FibonacciNumber
FROM Fibonacci
OPTION (MAXRECURSION 20);

-- Solution 5:
WITH OrderIDs AS (
    SELECT MIN(OrderID) AS MinID, MAX(OrderID) AS MaxID
    FROM Orders
),
AllNumbers AS (
    SELECT MinID AS n, MaxID
    FROM OrderIDs
    UNION ALL
    SELECT n + 1, MaxID
    FROM AllNumbers
    WHERE n < MaxID
)
SELECT an.n AS MissingOrderID
FROM AllNumbers an
LEFT JOIN Orders o ON an.n = o.OrderID
WHERE o.OrderID IS NULL
OPTION (MAXRECURSION 10000);


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ DERIVED TABLES:
  • Subqueries in FROM clause
  • Must have alias
  • Single-use result sets
  • Nested can be hard to read

✓ COMMON TABLE EXPRESSIONS:
  • WITH clause defines temporary result
  • Better readability than derived tables
  • Can reference multiple times
  • Supports recursion
  • Top-to-bottom logic flow

✓ MULTIPLE CTEs:
  • Comma-separated after WITH
  • Can reference earlier CTEs
  • Build complex logic step-by-step
  • Excellent for debugging

✓ RECURSIVE CTEs:
  • Anchor + recursive member
  • UNION ALL required
  • MAXRECURSION option prevents infinite loops
  • Great for hierarchies, sequences, dates

✓ WHEN TO USE EACH:
  • CTE: Complex, reusable, recursive
  • Derived: Simple, one-time, inline
  • Temp table: Multi-query, large data

✓ PERFORMANCE:
  • CTEs not materialized (like views)
  • Optimizer treats similar to derived tables
  • Consider indexes on base tables
  • Recursive CTEs need MAXRECURSION

✓ BEST PRACTICES:
  • Descriptive CTE names
  • One logical step per CTE
  • Comment complex logic
  • Test incrementally
  • Consider temp tables for large intermediate results

============================================================================
NEXT: Lesson 09.11 - Subqueries as Expression Generators
Learn to use subqueries in SELECT lists and calculations.
============================================================================
*/
