/*
============================================================================
Lesson 09.11 - Subqueries as Expression Generators
============================================================================

Description:
Master using subqueries in SELECT clauses, calculations, and as 
expression generators. Learn to create dynamic, calculated columns
using scalar and correlated subqueries.

Topics Covered:
• Subqueries in SELECT clause
• Scalar subqueries for calculations
• Correlated subqueries in SELECT
• Performance considerations
• Alternative approaches

Prerequisites:
• Lessons 09.01-09.10
• Understanding of expressions and calculations

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Scalar Subqueries in SELECT
============================================================================
*/

-- Example 1.1: Single value from subquery
SELECT 
    ProductID,
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS OverallAvgPrice,
    Price - (SELECT AVG(Price) FROM Products) AS PriceDifference
FROM Products
ORDER BY Price DESC;

-- Example 1.2: Multiple scalar subqueries
SELECT 
    ProductID,
    ProductName,
    Price,
    (SELECT MIN(Price) FROM Products) AS LowestPrice,
    (SELECT MAX(Price) FROM Products) AS HighestPrice,
    (SELECT AVG(Price) FROM Products) AS AveragePrice,
    Price / NULLIF((SELECT AVG(Price) FROM Products), 0) * 100 AS PercentOfAverage
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products);

-- Example 1.3: Subquery with aggregation
SELECT 
    CustomerID,
    CustomerName,
    Email,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalOrders,
    (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalSpent
FROM Customers c
ORDER BY TotalSpent DESC;

-- Example 1.4: Calculated expressions with subqueries
SELECT 
    CategoryID,
    CategoryName,
    (SELECT COUNT(*) FROM Products WHERE CategoryID = cat.CategoryID) AS ProductCount,
    (SELECT AVG(Price) FROM Products WHERE CategoryID = cat.CategoryID) AS AvgPrice,
    (SELECT COUNT(*) FROM Products WHERE CategoryID = cat.CategoryID) * 
    (SELECT AVG(Price) FROM Products WHERE CategoryID = cat.CategoryID) AS EstimatedValue
FROM Categories cat;


/*
============================================================================
PART 2: Correlated Subqueries in SELECT
============================================================================
*/

-- Example 2.1: Row-specific calculations
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    p.Price,
    (
        SELECT AVG(Price)
        FROM Products
        WHERE CategoryID = p.CategoryID
    ) AS CategoryAvgPrice,
    p.Price - (
        SELECT AVG(Price)
        FROM Products
        WHERE CategoryID = p.CategoryID
    ) AS DifferenceFromCategoryAvg
FROM Products p;

-- Example 2.2: Ranking within groups
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    (
        SELECT COUNT(*) + 1
        FROM Products
        WHERE CategoryID = p.CategoryID
        AND Price > p.Price
    ) AS PriceRankInCategory
FROM Products p
ORDER BY p.CategoryID, PriceRankInCategory;

-- Example 2.3: Latest related record
SELECT 
    c.CustomerID,
    c.CustomerName,
    (
        SELECT MAX(OrderDate)
        FROM Orders
        WHERE CustomerID = c.CustomerID
    ) AS LastOrderDate,
    (
        SELECT TotalAmount
        FROM Orders o
        WHERE o.CustomerID = c.CustomerID
        AND o.OrderDate = (
            SELECT MAX(OrderDate)
            FROM Orders
            WHERE CustomerID = c.CustomerID
        )
    ) AS LastOrderAmount
FROM Customers c;

-- Example 2.4: Percentage calculations
SELECT 
    o.OrderID,
    o.CustomerID,
    o.TotalAmount,
    (
        SELECT SUM(TotalAmount)
        FROM Orders
        WHERE CustomerID = o.CustomerID
    ) AS CustomerTotal,
    (o.TotalAmount / NULLIF((
        SELECT SUM(TotalAmount)
        FROM Orders
        WHERE CustomerID = o.CustomerID
    ), 0)) * 100 AS PercentOfCustomerTotal
FROM Orders o;


/*
============================================================================
PART 3: Conditional Logic with Subqueries
============================================================================
*/

-- Example 3.1: CASE with subqueries
SELECT 
    ProductID,
    ProductName,
    Price,
    Stock,
    CASE 
        WHEN Price > (SELECT AVG(Price) FROM Products) THEN 'Premium'
        WHEN Price < (SELECT AVG(Price) FROM Products) * 0.75 THEN 'Budget'
        ELSE 'Standard'
    END AS PriceCategory,
    CASE 
        WHEN Stock < (SELECT AVG(Stock) FROM Products) THEN 'Low'
        WHEN Stock > (SELECT AVG(Stock) FROM Products) * 1.5 THEN 'High'
        ELSE 'Normal'
    END AS StockLevel
FROM Products;

-- Example 3.2: Dynamic status calculation
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) = 0 
            THEN 'New Customer'
        WHEN (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID) < DATEADD(MONTH, -6, GETDATE())
            THEN 'Inactive'
        WHEN (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) > 10000
            THEN 'VIP'
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) > 10
            THEN 'Loyal'
        ELSE 'Active'
    END AS CustomerStatus
FROM Customers c;

-- Example 3.3: Multiple conditions
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM OrderDetails WHERE ProductID = p.ProductID)
            THEN 'Never Ordered'
        WHEN (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID) > 100
            THEN 'High Volume'
        WHEN (SELECT COUNT(DISTINCT OrderID) FROM OrderDetails WHERE ProductID = p.ProductID) > 20
            THEN 'Popular'
        ELSE 'Standard'
    END AS ProductStatus
FROM Products p;


/*
============================================================================
PART 4: Statistical Calculations
============================================================================
*/

-- Example 4.1: Percentile calculations
SELECT 
    ProductID,
    ProductName,
    Price,
    (
        SELECT COUNT(*)
        FROM Products p2
        WHERE p2.Price <= p1.Price
    ) * 100.0 / (SELECT COUNT(*) FROM Products) AS Percentile
FROM Products p1
ORDER BY Price;

-- Example 4.2: Z-score calculation
SELECT 
    ProductID,
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS Mean,
    (SELECT STDEV(Price) FROM Products) AS StdDev,
    (Price - (SELECT AVG(Price) FROM Products)) / 
        NULLIF((SELECT STDEV(Price) FROM Products), 0) AS ZScore
FROM Products
ORDER BY ZScore DESC;

-- Example 4.3: Moving averages
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    (
        SELECT AVG(TotalAmount)
        FROM Orders
        WHERE OrderDate BETWEEN DATEADD(DAY, -7, o.OrderDate) AND o.OrderDate
    ) AS SevenDayMovingAvg
FROM Orders o
ORDER BY o.OrderDate;

-- Example 4.4: Cumulative calculations
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    (
        SELECT SUM(Price)
        FROM Products p2
        WHERE p2.ProductID <= p.ProductID
    ) AS CumulativePrice
FROM Products p
ORDER BY p.ProductID;


/*
============================================================================
PART 5: Performance Considerations
============================================================================
*/

-- Performance 5.1: ❌ SLOW - Repeated correlated subqueries
SELECT 
    CustomerID,
    CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount,
    (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalSpent,
    (SELECT AVG(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS AvgOrder,
    (SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID) AS LastOrder
FROM Customers c;
-- Scans Orders table 4 times per customer!

-- Performance 5.2: ✅ FAST - JOIN with GROUP BY
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    AVG(o.TotalAmount) AS AvgOrder,
    MAX(o.OrderDate) AS LastOrder
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName;
-- Single scan of Orders!

-- Performance 5.3: ❌ SLOW - Uncached scalar subquery
SELECT 
    ProductID,
    ProductName,
    Price,
    Price - (SELECT AVG(Price) FROM Products) AS Diff1,
    Price / (SELECT AVG(Price) FROM Products) AS Ratio1,
    CASE WHEN Price > (SELECT AVG(Price) FROM Products) THEN 'High' ELSE 'Low' END AS Category
FROM Products;

-- Performance 5.4: ✅ FAST - CTE caches the value
WITH AvgPrice AS (
    SELECT AVG(Price) AS Avg FROM Products
)
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.Price - ap.Avg AS Diff1,
    p.Price / ap.Avg AS Ratio1,
    CASE WHEN p.Price > ap.Avg THEN 'High' ELSE 'Low' END AS Category
FROM Products p
CROSS JOIN AvgPrice ap;


/*
============================================================================
PART 6: Alternative Approaches
============================================================================
*/

-- Alternative 6.1: Window functions instead of correlated subqueries
-- ❌ Correlated subquery:
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.CategoryID = p1.CategoryID) AS CategoryAvg
FROM Products p1;

-- ✅ Window function (faster):
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    AVG(Price) OVER (PARTITION BY CategoryID) AS CategoryAvg
FROM Products;

-- Alternative 6.2: CROSS APPLY for complex logic
-- ❌ Multiple correlated subqueries:
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount,
    (SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalSpent
FROM Customers c;

-- ✅ CROSS APPLY (cleaner, potentially faster):
SELECT 
    c.CustomerID,
    c.CustomerName,
    oa.OrderCount,
    oa.TotalSpent
FROM Customers c
CROSS APPLY (
    SELECT 
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    WHERE CustomerID = c.CustomerID
) oa;

-- Alternative 6.3: Derived table for non-correlated values
-- ❌ Repeated non-correlated subquery:
SELECT 
    ProductID,
    ProductName,
    Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    (SELECT MIN(Price) FROM Products) AS MinPrice,
    (SELECT MAX(Price) FROM Products) AS MaxPrice
FROM Products;

-- ✅ Derived table / CROSS JOIN:
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    stats.AvgPrice,
    stats.MinPrice,
    stats.MaxPrice
FROM Products p
CROSS JOIN (
    SELECT 
        AVG(Price) AS AvgPrice,
        MIN(Price) AS MinPrice,
        MAX(Price) AS MaxPrice
    FROM Products
) stats;


/*
============================================================================
PART 7: Real-World Examples
============================================================================
*/

-- Example 7.1: Customer segmentation
SELECT 
    CustomerID,
    CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount,
    (SELECT ISNULL(SUM(TotalAmount), 0) FROM Orders WHERE CustomerID = c.CustomerID) AS TotalSpent,
    CASE 
        WHEN (SELECT ISNULL(SUM(TotalAmount), 0) FROM Orders WHERE CustomerID = c.CustomerID) > 
             (SELECT AVG(CustomerTotal) FROM (SELECT SUM(TotalAmount) AS CustomerTotal FROM Orders GROUP BY CustomerID) ct)
            THEN 'High Value'
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) > 5
            THEN 'Frequent'
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) > 0
            THEN 'Regular'
        ELSE 'New'
    END AS Segment
FROM Customers c;

-- Example 7.2: Product performance metrics
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.Stock,
    (SELECT ISNULL(SUM(Quantity), 0) FROM OrderDetails WHERE ProductID = p.ProductID) AS TotalSold,
    (SELECT COUNT(DISTINCT OrderID) FROM OrderDetails WHERE ProductID = p.ProductID) AS TimesOrdered,
    (SELECT ISNULL(SUM(Quantity * UnitPrice), 0) FROM OrderDetails WHERE ProductID = p.ProductID) AS TotalRevenue,
    p.Stock * p.Price AS StockValue,
    CASE 
        WHEN (SELECT ISNULL(SUM(Quantity), 0) FROM OrderDetails WHERE ProductID = p.ProductID) = 0
            THEN 'Never Sold'
        WHEN p.Stock = 0
            THEN 'Out of Stock'
        WHEN p.Stock < (SELECT AVG(Stock) FROM Products)
            THEN 'Low Stock'
        ELSE 'In Stock'
    END AS Status
FROM Products p;

-- Example 7.3: Sales performance comparison
SELECT 
    o.OrderID,
    o.CustomerID,
    o.OrderDate,
    o.TotalAmount,
    (SELECT AVG(TotalAmount) FROM Orders) AS OverallAvg,
    (SELECT AVG(TotalAmount) FROM Orders WHERE YEAR(OrderDate) = YEAR(o.OrderDate)) AS YearAvg,
    (SELECT AVG(TotalAmount) FROM Orders WHERE MONTH(OrderDate) = MONTH(o.OrderDate)) AS MonthAvg,
    CASE 
        WHEN o.TotalAmount > (SELECT AVG(TotalAmount) FROM Orders WHERE YEAR(OrderDate) = YEAR(o.OrderDate)) * 1.5
            THEN 'Exceptional'
        WHEN o.TotalAmount > (SELECT AVG(TotalAmount) FROM Orders WHERE YEAR(OrderDate) = YEAR(o.OrderDate))
            THEN 'Above Average'
        ELSE 'Standard'
    END AS Performance
FROM Orders o;


/*
============================================================================
PART 8: Best Practices
============================================================================
*/

-- Practice 8.1: ✅ Use window functions when possible
-- Better than correlated subquery for rankings and running totals

-- Practice 8.2: ✅ Cache non-correlated values
WITH Constants AS (
    SELECT 
        AVG(Price) AS AvgPrice,
        STDEV(Price) AS StdPrice
    FROM Products
)
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    c.AvgPrice,
    c.StdPrice
FROM Products p
CROSS JOIN Constants c;

-- Practice 8.3: ⚠️ Limit subquery execution
-- Use WHERE to reduce outer query rows first
SELECT 
    p.ProductID,
    p.ProductName,
    (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID) AS TotalSold
FROM Products p
WHERE CategoryID = 1  -- Filter first!
ORDER BY TotalSold DESC;

-- Practice 8.4: ✅ Handle NULL appropriately
SELECT 
    c.CustomerID,
    c.CustomerName,
    ISNULL((SELECT SUM(TotalAmount) FROM Orders WHERE CustomerID = c.CustomerID), 0) AS TotalSpent,
    ISNULL((SELECT MAX(OrderDate) FROM Orders WHERE CustomerID = c.CustomerID), '1900-01-01') AS LastOrder
FROM Customers c;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Show each product with its price difference from category average
2. List customers with order count and whether they're above/below average
3. Calculate running total of prices for all products
4. Create a status field based on multiple subquery conditions
5. Compare each order to the monthly average using subqueries

Solutions below ↓
*/

-- Solution 1:
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    (SELECT AVG(Price) FROM Products p2 WHERE p2.CategoryID = p1.CategoryID) AS CategoryAvg,
    Price - (SELECT AVG(Price) FROM Products p2 WHERE p2.CategoryID = p1.CategoryID) AS Difference
FROM Products p1
ORDER BY CategoryID, Difference DESC;

-- Solution 2:
WITH AvgOrders AS (
    SELECT AVG(CAST(OrderCount AS FLOAT)) AS Avg
    FROM (SELECT CustomerID, COUNT(*) AS OrderCount FROM Orders GROUP BY CustomerID) oc
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) AS OrderCount,
    (SELECT Avg FROM AvgOrders) AS AvgOrderCount,
    CASE 
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) > (SELECT Avg FROM AvgOrders)
            THEN 'Above Average'
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) < (SELECT Avg FROM AvgOrders)
            THEN 'Below Average'
        ELSE 'Average'
    END AS Performance
FROM Customers c;

-- Solution 3:
SELECT 
    p1.ProductID,
    p1.ProductName,
    p1.Price,
    (SELECT SUM(Price) FROM Products p2 WHERE p2.ProductID <= p1.ProductID) AS RunningTotal
FROM Products p1
ORDER BY p1.ProductID;

-- Solution 4:
SELECT 
    ProductID,
    ProductName,
    Price,
    Stock,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM OrderDetails WHERE ProductID = p.ProductID)
            THEN 'Unsold'
        WHEN Stock = 0
            THEN 'Out of Stock'
        WHEN Stock < (SELECT AVG(Stock) FROM Products)
            AND (SELECT SUM(Quantity) FROM OrderDetails WHERE ProductID = p.ProductID) > 100
            THEN 'Reorder - High Demand'
        WHEN Stock < (SELECT AVG(Stock) FROM Products)
            THEN 'Low Stock'
        WHEN Price > (SELECT AVG(Price) FROM Products) * 1.5
            THEN 'Premium Item'
        ELSE 'Standard'
    END AS Status
FROM Products p;

-- Solution 5:
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    (
        SELECT AVG(TotalAmount)
        FROM Orders
        WHERE YEAR(OrderDate) = YEAR(o.OrderDate)
        AND MONTH(OrderDate) = MONTH(o.OrderDate)
    ) AS MonthlyAvg,
    TotalAmount - (
        SELECT AVG(TotalAmount)
        FROM Orders
        WHERE YEAR(OrderDate) = YEAR(o.OrderDate)
        AND MONTH(OrderDate) = MONTH(o.OrderDate)
    ) AS DifferenceFromMonthlyAvg
FROM Orders o
ORDER BY OrderDate;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SCALAR SUBQUERIES:
  • Return single value
  • Can be used in calculations
  • Must return one column, one row
  • NULL if no rows returned

✓ CORRELATED IN SELECT:
  • Execute for each outer row
  • Access outer table columns
  • Useful for row-specific calculations
  • Can be slow on large datasets

✓ PERFORMANCE:
  • Correlated = potentially slow
  • Consider window functions
  • Cache non-correlated values
  • Use CROSS APPLY for multiple values

✓ ALTERNATIVES:
  • Window functions (AVG OVER, etc.)
  • JOINs with GROUP BY
  • CTEs for reused calculations
  • CROSS/OUTER APPLY

✓ WHEN TO USE:
  • Simple scalar lookups
  • Row-specific comparisons
  • Conditional logic
  • One-off calculations

✓ WHEN NOT TO USE:
  • Large datasets (use JOIN/window)
  • Multiple related calculations (use APPLY)
  • Repeated values (use CTE)
  • Complex aggregations (use derived table)

✓ BEST PRACTICES:
  • Always handle NULL
  • Cache constants
  • Use ISNULL/COALESCE
  • Test performance
  • Consider alternatives
  • Comment complex logic

============================================================================
NEXT: Lesson 09.12 - Subquery Wrap-Up
Comprehensive review and best practices.
============================================================================
*/
