/*
============================================================================
Lesson 08.07 - Single Column Grouping
============================================================================

Description:
Master single-column GROUP BY with practical patterns and real-world examples.
Learn common grouping scenarios and best practices.

Topics Covered:
• Basic single-column grouping
• Grouping by different data types
• Time-based grouping
• Common patterns
• Sorting grouped results

Prerequisites:
• Lessons 08.01-08.06

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Basic Single-Column Grouping
============================================================================
*/

-- Example 1.1: Group by category
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID
ORDER BY CategoryID;

-- Example 1.2: Group by customer
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

-- Example 1.3: Group by status
SELECT 
    Status,
    COUNT(*) AS Count
FROM Orders
GROUP BY Status;


/*
============================================================================
PART 2: Time-Based Grouping
============================================================================
*/

-- Example 2.1: Group by year
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Example 2.2: Group by month
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    DATENAME(MONTH, OrderDate) AS MonthName,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
WHERE YEAR(OrderDate) = 2025
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY Month;

-- Example 2.3: Group by day of week
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    COUNT(*) AS OrderCount,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY DATEPART(WEEKDAY, OrderDate);

-- Example 2.4: Group by date (no time)
SELECT 
    CAST(OrderDate AS DATE) AS OrderDay,
    COUNT(*) AS DailyOrders,
    SUM(TotalAmount) AS DailySales
FROM Orders
GROUP BY CAST(OrderDate AS DATE)
ORDER BY OrderDay DESC;


/*
============================================================================
PART 3: Grouping Different Data Types
============================================================================
*/

-- Example 3.1: Grouping strings
SELECT 
    City,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY City
ORDER BY CustomerCount DESC;

-- Example 3.2: Grouping numbers
SELECT 
    Stock,
    COUNT(*) AS ProductsWithThisStock
FROM Products
GROUP BY Stock
ORDER BY Stock;

-- Example 3.3: Grouping dates
SELECT 
    CAST(OrderDate AS DATE) AS Date,
    COUNT(*) AS Orders
FROM Orders
GROUP BY CAST(OrderDate AS DATE)
ORDER BY Date;


/*
============================================================================
PART 4: Common Patterns
============================================================================
*/

-- Pattern 4.1: Top N groups
SELECT TOP 10
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

-- Pattern 4.2: Groups meeting criteria
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 5
ORDER BY ProductCount DESC;

-- Pattern 4.3: Percentage of total
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS Percentage
FROM Products
GROUP BY CategoryID
ORDER BY ProductCount DESC;

-- Pattern 4.4: Running total by group
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(TotalAmount) AS YearlyRevenue,
    SUM(SUM(TotalAmount)) OVER (ORDER BY YEAR(OrderDate)) AS RunningTotal
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;


/*
============================================================================
PART 5: Sorting Grouped Results
============================================================================
*/

-- Example 5.1: Sort by grouped column
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
ORDER BY CategoryID;

-- Example 5.2: Sort by aggregate
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
ORDER BY ProductCount DESC;

-- Example 5.3: Multiple sort columns
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
ORDER BY OrderCount DESC, TotalSpent DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Count orders per customer, sorted by count
2. Find total sales per year
3. List categories with their average price
4. Count customers per city
5. Find busiest day of the week for orders

Solutions below ↓
*/

-- Solution 1:
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
ORDER BY OrderCount DESC;

-- Solution 2:
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(TotalAmount) AS TotalSales
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Solution 3:
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID
ORDER BY CategoryID;

-- Solution 4:
SELECT 
    City,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY City
ORDER BY CustomerCount DESC;

-- Solution 5:
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY OrderCount DESC;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ Single-column GROUP BY creates one group per unique value
✓ Time-based grouping reveals trends and patterns
✓ ORDER BY can use grouped columns or aggregates
✓ HAVING filters groups after aggregation
✓ Combine with window functions for advanced analysis

============================================================================
NEXT: Lesson 08.08 - Multi-Column Grouping
Learn to create hierarchical groups with multiple columns.
============================================================================
*/
