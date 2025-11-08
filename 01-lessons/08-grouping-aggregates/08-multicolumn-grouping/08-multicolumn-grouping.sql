/*
============================================================================
Lesson 08.08 - Multicolumn Grouping
============================================================================

Description:
Learn to group by multiple columns to create hierarchical summaries
and analyze data across multiple dimensions simultaneously.

Topics Covered:
• Grouping by multiple columns
• Order matters in display
• Hierarchical grouping patterns
• Cross-tabulation concepts
• Multi-level analysis

Prerequisites:
• Lessons 08.01-08.07

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Basic Multicolumn Grouping
============================================================================
*/

-- Example 1.1: Group by two columns
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID, SupplierID
ORDER BY CategoryID, SupplierID;
-- One row per unique combination of CategoryID and SupplierID

-- Example 1.2: Understanding unique combinations
/*
Visual Representation:

CategoryID | SupplierID → One Group
-----------|------------
1          | 1         → [Group A]
1          | 2         → [Group B]
2          | 1         → [Group C]
2          | 2         → [Group D]

Each combination gets its own summary row.
*/

-- Example 1.3: Three columns
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate), CustomerID
ORDER BY Year, Month, CustomerID;
-- One row per Year + Month + CustomerID combination


/*
============================================================================
PART 2: Order Matters (for Display, Not Grouping)
============================================================================
*/

-- Example 2.1: Different ORDER BY, same grouping
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID, SupplierID
ORDER BY CategoryID, SupplierID;  -- Category first

-- Same data, different sort:
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID, SupplierID
ORDER BY SupplierID, CategoryID;  -- Supplier first

-- Example 2.2: GROUP BY order doesn't affect results
-- These produce identical groupings:
SELECT CategoryID, SupplierID, COUNT(*) 
FROM Products 
GROUP BY CategoryID, SupplierID;

SELECT CategoryID, SupplierID, COUNT(*) 
FROM Products 
GROUP BY SupplierID, CategoryID;  -- Same groups!


/*
============================================================================
PART 3: Hierarchical Grouping Patterns
============================================================================
*/

-- Example 3.1: Year > Month > Day hierarchy
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    DAY(OrderDate) AS Day,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DAY(OrderDate)
ORDER BY Year, Month, Day;

-- Example 3.2: Category > Product hierarchy
SELECT 
    p.CategoryID,
    c.CategoryName,
    p.ProductID,
    p.ProductName,
    COUNT(od.OrderDetailID) AS TimesSold,
    SUM(od.Quantity) AS TotalQuantity,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.CategoryID, c.CategoryName, p.ProductID, p.ProductName
ORDER BY p.CategoryID, Revenue DESC;

-- Example 3.3: Customer > Year > Quarter
SELECT 
    CustomerID,
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY CustomerID, YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY CustomerID, Year, Quarter;


/*
============================================================================
PART 4: Cross-Tabulation Concepts
============================================================================
*/

-- Example 4.1: Category by Year
SELECT 
    CategoryID,
    YEAR(o.OrderDate) AS Year,
    COUNT(DISTINCT od.OrderID) AS OrderCount,
    SUM(od.Quantity) AS TotalQuantity
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY CategoryID, YEAR(o.OrderDate)
ORDER BY CategoryID, Year;

-- Example 4.2: Product performance by time period
SELECT 
    p.ProductName,
    YEAR(o.OrderDate) AS Year,
    DATEPART(QUARTER, o.OrderDate) AS Quarter,
    COUNT(*) AS OrderCount,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName, YEAR(o.OrderDate), DATEPART(QUARTER, o.OrderDate)
ORDER BY p.ProductName, Year, Quarter;


/*
============================================================================
PART 5: Multi-Level Analysis
============================================================================
*/

-- Example 5.1: Customer segmentation by purchase behavior
SELECT 
    YEAR(OrderDate) AS Year,
    CASE 
        WHEN COUNT(*) = 1 THEN 'One-Time'
        WHEN COUNT(*) <= 5 THEN 'Occasional'
        WHEN COUNT(*) <= 10 THEN 'Regular'
        ELSE 'Frequent'
    END AS CustomerType,
    COUNT(DISTINCT CustomerID) AS Customers,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY 
    YEAR(OrderDate),
    CustomerID  -- First group by customer to count orders
HAVING 1=1  -- Placeholder
-- Then group again:
-- (This requires a subquery/CTE for proper implementation)

-- Example 5.2: Better approach with CTE
WITH CustomerOrderCounts AS (
    SELECT 
        CustomerID,
        YEAR(OrderDate) AS Year,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID, YEAR(OrderDate)
)
SELECT 
    Year,
    CASE 
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount <= 5 THEN 'Occasional'
        WHEN OrderCount <= 10 THEN 'Regular'
        ELSE 'Frequent'
    END AS CustomerType,
    COUNT(*) AS Customers,
    SUM(TotalSpent) AS Revenue,
    AVG(TotalSpent) AS AvgPerCustomer
FROM CustomerOrderCounts
GROUP BY 
    Year,
    CASE 
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount <= 5 THEN 'Occasional'
        WHEN OrderCount <= 10 THEN 'Regular'
        ELSE 'Frequent'
    END
ORDER BY Year, CustomerType;


/*
============================================================================
PART 6: Combining Different Dimensions
============================================================================
*/

-- Example 6.1: Geography + Time
SELECT 
    c.Country,
    c.State,
    YEAR(o.OrderDate) AS Year,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(*) AS Orders,
    SUM(o.TotalAmount) AS Revenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.Country, c.State, YEAR(o.OrderDate)
ORDER BY c.Country, c.State, Year;

-- Example 6.2: Product + Customer + Time
SELECT 
    p.ProductName,
    c.CustomerID,
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    COUNT(*) AS PurchaseCount,
    SUM(od.Quantity) AS TotalQuantity,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY p.ProductID, p.ProductName, c.CustomerID, YEAR(o.OrderDate), MONTH(o.OrderDate)
HAVING COUNT(*) > 1  -- Only customers who bought same product multiple times
ORDER BY Revenue DESC;


/*
============================================================================
PART 7: Performance Considerations
============================================================================
*/

-- Example 7.1: Index support for multicolumn grouping
-- Composite index helps:
-- CREATE INDEX IX_Orders_CustomerDate ON Orders(CustomerID, OrderDate);

SELECT 
    CustomerID,
    CAST(OrderDate AS DATE) AS OrderDate,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS DailyTotal
FROM Orders
GROUP BY CustomerID, CAST(OrderDate AS DATE)
ORDER BY CustomerID, OrderDate;

-- Example 7.2: Reduce grouping levels when possible
-- ❌ Too many levels (slow):
SELECT 
    YEAR(OrderDate), MONTH(OrderDate), DAY(OrderDate), 
    DATEPART(HOUR, OrderDate), DATEPART(MINUTE, OrderDate),
    COUNT(*)
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DAY(OrderDate), 
         DATEPART(HOUR, OrderDate), DATEPART(MINUTE, OrderDate);

-- ✅ Group by date/time directly:
SELECT 
    CAST(OrderDate AS DATE) AS OrderDate,
    DATEPART(HOUR, OrderDate) AS Hour,
    COUNT(*) AS Orders
FROM Orders
GROUP BY CAST(OrderDate AS DATE), DATEPART(HOUR, OrderDate);


/*
============================================================================
PART 8: Common Patterns
============================================================================
*/

-- Pattern 8.1: Period-over-period comparison (requires self-join or window functions)
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    LAG(SUM(TotalAmount)) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS PrevMonthRevenue
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Pattern 8.2: Top N per group
WITH ProductSales AS (
    SELECT 
        p.CategoryID,
        p.ProductID,
        p.ProductName,
        COUNT(*) AS OrderCount,
        SUM(od.Quantity) AS TotalSold,
        ROW_NUMBER() OVER (PARTITION BY p.CategoryID ORDER BY SUM(od.Quantity) DESC) AS RankInCategory
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.CategoryID, p.ProductID, p.ProductName
)
SELECT CategoryID, ProductName, TotalSold, RankInCategory
FROM ProductSales
WHERE RankInCategory <= 3  -- Top 3 per category
ORDER BY CategoryID, RankInCategory;

-- Pattern 8.3: Percentage of parent group
SELECT 
    CategoryID,
    ProductID,
    COUNT(*) AS SalesCount,
    SUM(COUNT(*)) OVER (PARTITION BY CategoryID) AS CategoryTotal,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY CategoryID) AS DECIMAL(5,2)) AS PctOfCategory
FROM OrderDetails od
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY CategoryID, ProductID
ORDER BY CategoryID, SalesCount DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Group orders by Year, Quarter, and Month
2. Show product sales by Category and Year
3. Customer purchase patterns by Country and Year
4. Find top selling products per category per year
5. Calculate revenue by State and Month

Solutions below ↓
*/

-- Solution 1:
SELECT 
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate), MONTH(OrderDate)
ORDER BY Year, Quarter, Month;

-- Solution 2:
SELECT 
    c.CategoryName,
    YEAR(o.OrderDate) AS Year,
    COUNT(DISTINCT od.OrderID) AS OrderCount,
    SUM(od.Quantity) AS UnitsSold,
    SUM(od.Quantity * od.UnitPrice) AS Revenue
FROM Categories c
JOIN Products p ON c.CategoryID = p.CategoryID
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY c.CategoryID, c.CategoryName, YEAR(o.OrderDate)
ORDER BY c.CategoryName, Year;

-- Solution 3:
SELECT 
    c.Country,
    YEAR(o.OrderDate) AS Year,
    COUNT(DISTINCT c.CustomerID) AS UniqueCustomers,
    COUNT(*) AS TotalOrders,
    SUM(o.TotalAmount) AS Revenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.Country, YEAR(o.OrderDate)
ORDER BY c.Country, Year;

-- Solution 4:
WITH ProductYearlySales AS (
    SELECT 
        p.CategoryID,
        c.CategoryName,
        YEAR(o.OrderDate) AS Year,
        p.ProductID,
        p.ProductName,
        SUM(od.Quantity) AS TotalSold,
        ROW_NUMBER() OVER (
            PARTITION BY p.CategoryID, YEAR(o.OrderDate) 
            ORDER BY SUM(od.Quantity) DESC
        ) AS Rank
    FROM Products p
    JOIN Categories c ON p.CategoryID = c.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    GROUP BY p.CategoryID, c.CategoryName, YEAR(o.OrderDate), p.ProductID, p.ProductName
)
SELECT CategoryName, Year, ProductName, TotalSold, Rank
FROM ProductYearlySales
WHERE Rank <= 5
ORDER BY CategoryName, Year, Rank;

-- Solution 5:
SELECT 
    c.State,
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    COUNT(*) AS Orders,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    SUM(o.TotalAmount) AS Revenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.State IS NOT NULL
GROUP BY c.State, YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY c.State, Year, Month;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ MULTICOLUMN GROUPING:
  • Creates unique combination groups
  • One row per unique combination
  • All columns must be in GROUP BY or aggregated

✓ ORDER CONSIDERATIONS:
  • GROUP BY order doesn't affect grouping
  • ORDER BY determines display hierarchy
  • Use meaningful sort for hierarchical display

✓ HIERARCHICAL ANALYSIS:
  • Year > Quarter > Month > Day
  • Country > State > City
  • Category > Subcategory > Product

✓ PERFORMANCE:
  • Indexes on grouped columns help
  • Fewer grouping levels = faster queries
  • Filter with WHERE before GROUP BY

✓ COMMON PATTERNS:
  • Time-based hierarchies
  • Geographic breakdowns
  • Product categorization
  • Customer segmentation
  • Top N per group

✓ BEST PRACTICES:
  • Group at appropriate granularity
  • Use CTEs for multi-level analysis
  • Consider window functions for advanced patterns
  • Index composite columns used in GROUP BY

============================================================================
NEXT: Lesson 08.09 - Grouping with Expressions
Advanced grouping with calculated columns and complex logic.
============================================================================
*/
