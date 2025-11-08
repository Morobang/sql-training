/*============================================
   LESSON 06: SUBQUERIES AS TABLES
   Using SELECT results as virtual tables
   
   Estimated Time: 20 minutes
   Difficulty: Intermediate
============================================*/

USE RetailStore;
GO

/*--------------------------------------------
   PART 1: WHAT ARE DERIVED TABLES?
   Subqueries in the FROM clause
--------------------------------------------*/

/*
   A derived table (also called inline view or subquery in FROM)
   is a SELECT statement used as a table in another query
   
   Instead of:
   FROM ActualTable
   
   You can use:
   FROM (SELECT ... FROM ActualTable) AS VirtualTable
   
   The subquery result becomes a temporary, virtual table
*/

/*--------------------------------------------
   PART 2: BASIC SYNTAX
   Simple derived table example
--------------------------------------------*/

-- Without derived table
SELECT ProductName, Price
FROM Inventory.Products
WHERE Price > 100;

-- With derived table (same result, demonstrates concept)
SELECT ProductName, Price
FROM (
    SELECT ProductID, ProductName, Price
    FROM Inventory.Products
    WHERE Price > 100
) AS ExpensiveProducts;

-- The subquery creates a virtual table called "ExpensiveProducts"

/*--------------------------------------------
   PART 3: WHY USE DERIVED TABLES?
   Common use cases
--------------------------------------------*/

/*
   Use derived tables to:
   1. Pre-aggregate data before joining
   2. Simplify complex queries
   3. Apply multiple levels of filtering
   4. Reuse calculated columns
   5. Create temporary result sets
*/

/*--------------------------------------------
   PART 4: PRE-AGGREGATION EXAMPLE
   Summarize before joining
--------------------------------------------*/

-- Get customer order summary, then filter
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    OrderSummary.OrderCount,
    OrderSummary.TotalSpent
FROM Sales.Customers c
INNER JOIN (
    -- Pre-aggregate orders by customer
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Sales.Orders
    GROUP BY CustomerID
) AS OrderSummary ON c.CustomerID = OrderSummary.CustomerID
WHERE OrderSummary.OrderCount >= 3
ORDER BY OrderSummary.TotalSpent DESC;

-- The derived table summarizes orders FIRST,
-- then we join to customers

/*--------------------------------------------
   PART 5: MULTIPLE AGGREGATION LEVELS
   Aggregate, then aggregate again
--------------------------------------------*/

-- Calculate average order value per customer, then find overall average
SELECT 
    AVG(AvgOrderValue) AS OverallAvgOrderValue,
    MAX(AvgOrderValue) AS HighestAvgOrderValue,
    MIN(AvgOrderValue) AS LowestAvgOrderValue
FROM (
    -- First aggregation: avg per customer
    SELECT 
        CustomerID,
        AVG(TotalAmount) AS AvgOrderValue
    FROM Sales.Orders
    GROUP BY CustomerID
) AS CustomerAverages;

/*--------------------------------------------
   PART 6: REUSING CALCULATED COLUMNS
   Calculate once, use multiple times
--------------------------------------------*/

-- Without derived table: Calculate LineTotal multiple times
SELECT 
    ProductName,
    Quantity * UnitPrice AS LineTotal,
    CASE 
        WHEN Quantity * UnitPrice > 500 THEN 'High'
        WHEN Quantity * UnitPrice > 100 THEN 'Medium'
        ELSE 'Low'
    END AS ValueCategory
FROM Sales.OrderDetails od
INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID;

-- With derived table: Calculate LineTotal once, reuse it
SELECT 
    ProductName,
    LineTotal,
    CASE 
        WHEN LineTotal > 500 THEN 'High'
        WHEN LineTotal > 100 THEN 'Medium'
        ELSE 'Low'
    END AS ValueCategory
FROM (
    SELECT 
        p.ProductName,
        od.Quantity * od.UnitPrice AS LineTotal
    FROM Sales.OrderDetails od
    INNER JOIN Inventory.Products p ON od.ProductID = p.ProductID
) AS OrderLines;

/*--------------------------------------------
   PART 7: TOP N PER GROUP
   Complex ranking scenarios
--------------------------------------------*/

-- Get top 3 products by revenue in each category
SELECT CategoryName, ProductName, Revenue, RowNum
FROM (
    SELECT 
        c.CategoryName,
        p.ProductName,
        SUM(od.Quantity * od.UnitPrice) AS Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY c.CategoryID 
            ORDER BY SUM(od.Quantity * od.UnitPrice) DESC
        ) AS RowNum
    FROM Inventory.Categories c
    INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
    INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID, c.CategoryName, p.ProductID, p.ProductName
) AS RankedProducts
WHERE RowNum <= 3
ORDER BY CategoryName, RowNum;

/*--------------------------------------------
   PART 8: FILTERING AGGREGATES
   WHERE doesn't work on aggregates, but derived tables do
--------------------------------------------*/

-- ❌ This doesn't work: Can't use WHERE with aggregate
-- SELECT CategoryID, AVG(Price) AS AvgPrice
-- FROM Products
-- WHERE AVG(Price) > 100  -- ERROR!

-- ✅ Solution 1: Use HAVING
SELECT CategoryID, AVG(Price) AS AvgPrice
FROM Inventory.Products
GROUP BY CategoryID
HAVING AVG(Price) > 100;

-- ✅ Solution 2: Use derived table (more flexible)
SELECT *
FROM (
    SELECT 
        CategoryID,
        AVG(Price) AS AvgPrice,
        COUNT(*) AS ProductCount
    FROM Inventory.Products
    GROUP BY CategoryID
) AS CategoryStats
WHERE AvgPrice > 100 
  AND ProductCount > 5;

/*--------------------------------------------
   PART 9: JOINING MULTIPLE DERIVED TABLES
   Combine multiple aggregations
--------------------------------------------*/

-- Compare customer order stats with product stats
SELECT 
    CustomerStats.CustomerName,
    CustomerStats.OrderCount,
    ProductStats.UniqueProducts,
    CustomerStats.TotalSpent
FROM (
    -- Derived table 1: Customer order summary
    SELECT 
        c.CustomerID,
        c.FirstName + ' ' + c.LastName AS CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent
    FROM Sales.Customers c
    INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.FirstName, c.LastName
) AS CustomerStats
INNER JOIN (
    -- Derived table 2: Unique products per customer
    SELECT 
        o.CustomerID,
        COUNT(DISTINCT od.ProductID) AS UniqueProducts
    FROM Sales.Orders o
    INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
) AS ProductStats ON CustomerStats.CustomerID = ProductStats.CustomerID
ORDER BY CustomerStats.TotalSpent DESC;

/*--------------------------------------------
   PART 10: COMMON TABLE EXPRESSIONS (CTEs)
   Alternative to derived tables
--------------------------------------------*/

-- Derived table version
SELECT *
FROM (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount
    FROM Sales.Orders
    GROUP BY CustomerID
) AS OrderCounts
WHERE OrderCount > 5;

-- CTE version (same result, often more readable)
WITH OrderCounts AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount
    FROM Sales.Orders
    GROUP BY CustomerID
)
SELECT *
FROM OrderCounts
WHERE OrderCount > 5;

-- CTEs are covered in detail in Chapter 09 (Subqueries)

/*--------------------------------------------
   PART 11: NESTED DERIVED TABLES
   Derived table within derived table
--------------------------------------------*/

-- Complex nesting (use sparingly!)
SELECT 
    CategoryName,
    AvgProductPrice
FROM (
    SELECT 
        CategoryName,
        AVG(Price) AS AvgProductPrice
    FROM (
        SELECT 
            c.CategoryName,
            p.Price
        FROM Inventory.Categories c
        INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
        WHERE p.Price IS NOT NULL
    ) AS ProductsWithCategory
    GROUP BY CategoryName
) AS CategoryAverages
WHERE AvgProductPrice > 100;

-- Better: Use CTEs for readability
WITH ProductsWithCategory AS (
    SELECT c.CategoryName, p.Price
    FROM Inventory.Categories c
    INNER JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
    WHERE p.Price IS NOT NULL
),
CategoryAverages AS (
    SELECT 
        CategoryName,
        AVG(Price) AS AvgProductPrice
    FROM ProductsWithCategory
    GROUP BY CategoryName
)
SELECT *
FROM CategoryAverages
WHERE AvgProductPrice > 100;

/*--------------------------------------------
   PART 12: REAL-WORLD EXAMPLES
--------------------------------------------*/

-- Example 1: Monthly sales trend
SELECT 
    SalesMonth.Year,
    SalesMonth.Month,
    SalesMonth.Revenue,
    SalesMonth.Revenue - LAG(SalesMonth.Revenue) OVER (ORDER BY SalesMonth.Year, SalesMonth.Month) AS RevenueChange
FROM (
    SELECT 
        YEAR(o.OrderDate) AS Year,
        MONTH(o.OrderDate) AS Month,
        SUM(od.Quantity * od.UnitPrice) AS Revenue
    FROM Sales.Orders o
    INNER JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
) AS SalesMonth
ORDER BY Year, Month;

-- Example 2: Customer segmentation
SELECT 
    CASE 
        WHEN TotalSpent >= 1000 THEN 'VIP'
        WHEN TotalSpent >= 500 THEN 'Premium'
        ELSE 'Standard'
    END AS Segment,
    COUNT(*) AS CustomerCount,
    AVG(TotalSpent) AS AvgSpent,
    AVG(OrderCount) AS AvgOrders
FROM (
    SELECT 
        c.CustomerID,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent
    FROM Sales.Customers c
    INNER JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
) AS CustomerStats
GROUP BY 
    CASE 
        WHEN TotalSpent >= 1000 THEN 'VIP'
        WHEN TotalSpent >= 500 THEN 'Premium'
        ELSE 'Standard'
    END;

-- Example 3: Product performance comparison
SELECT 
    ProductPerf.ProductName,
    ProductPerf.Revenue,
    CategoryPerf.CategoryRevenue,
    (ProductPerf.Revenue * 100.0 / CategoryPerf.CategoryRevenue) AS PercentOfCategory
FROM (
    -- Product revenue
    SELECT 
        p.ProductID,
        p.ProductName,
        p.CategoryID,
        SUM(od.Quantity * od.UnitPrice) AS Revenue
    FROM Inventory.Products p
    INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName, p.CategoryID
) AS ProductPerf
INNER JOIN (
    -- Category revenue
    SELECT 
        p.CategoryID,
        SUM(od.Quantity * od.UnitPrice) AS CategoryRevenue
    FROM Inventory.Products p
    INNER JOIN Sales.OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.CategoryID
) AS CategoryPerf ON ProductPerf.CategoryID = CategoryPerf.CategoryID
ORDER BY ProductPerf.Revenue DESC;

/*--------------------------------------------
   PART 13: BEST PRACTICES
--------------------------------------------*/

/*
   ✅ DO:
   • Always use an alias for derived tables (required!)
   • Use meaningful names for derived tables
   • Consider CTEs for complex queries
   • Comment what each derived table does
   • Test subqueries separately first
   
   ❌ DON'T:
   • Nest too deeply (hard to read/debug)
   • Create derived tables you don't need
   • Forget the alias (syntax error!)
   • Use SELECT * in derived tables
   • Make them too complex
*/

/*--------------------------------------------
   PART 14: PRACTICE EXERCISES
--------------------------------------------*/

-- 1. Create a derived table showing products with above-average prices

-- 2. Use a derived table to find customers with more than average orders

-- 3. Join a derived table of order summaries with the Customers table

-- 4. Create a query with two derived tables joined together

-- 5. Rewrite this using a CTE instead of derived table:
--    SELECT * FROM (SELECT CustomerID, COUNT(*) AS Cnt FROM Orders GROUP BY CustomerID) AS X

/*============================================
   KEY CONCEPTS
============================================*/

/*
   Derived Tables (Subqueries as Tables):
   
   Syntax:
   SELECT ...
   FROM (
       SELECT ...
       FROM ...
   ) AS AliasName
   
   When to use:
   • Pre-aggregate data
   • Calculate once, use multiple times
   • Multiple aggregation levels
   • Complex filtering
   
   Alternatives:
   • CTEs (WITH clause) - more readable
   • Temporary tables - better for large results
   • Views - reusable derived tables
*/

/*============================================
   NEXT: Lesson 07 - Using Same Table Twice
   (Table aliases for multiple references)
============================================*/
