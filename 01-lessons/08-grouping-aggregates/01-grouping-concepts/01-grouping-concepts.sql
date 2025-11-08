/*
============================================================================
Lesson 08.01 - Grouping Concepts
============================================================================

Description:
Understand the fundamental concept of grouping in SQL. Learn when and why
to use GROUP BY to transform detailed data into meaningful summaries.

Topics Covered:
• What is grouping
• Why group data
• GROUP BY syntax
• Grouping vs filtering
• The all-or-nothing rule
• Valid and invalid queries

Prerequisites:
• Chapter 03 - Query Primer
• Basic SELECT statements

Estimated Time: 20 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Grouping
============================================================================
Grouping collapses multiple rows into summary rows based on common values.
*/

-- Example 1.1: Data WITHOUT grouping (detail level)
SELECT 
    CustomerID,
    OrderDate,
    TotalAmount
FROM Orders
ORDER BY CustomerID;
-- Shows every individual order

-- Example 1.2: Data WITH grouping (summary level)
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
ORDER BY CustomerID;
-- Shows one row per customer with totals

/*
VISUAL COMPARISON:

Without GROUP BY (Detail):
CustomerID | OrderDate  | TotalAmount
-----------|------------|------------
1          | 2025-01-05 | 100.00
1          | 2025-01-10 | 150.00
1          | 2025-01-15 | 200.00
2          | 2025-01-06 | 75.00
2          | 2025-01-12 | 125.00

With GROUP BY (Summary):
CustomerID | OrderCount | TotalSpent
-----------|------------|------------
1          | 3          | 450.00
2          | 2          | 200.00
*/

-- Example 1.3: The transformation
-- From: Many rows per customer
-- To:   One row per customer with aggregated data


/*
============================================================================
PART 2: Why Group Data?
============================================================================
*/

-- Reason 2.1: Answer "How many?" questions
SELECT 
    COUNT(*) AS TotalOrders
FROM Orders;
-- Answer: Total number of orders

-- Reason 2.2: Answer "How much?" questions
SELECT 
    SUM(TotalAmount) AS TotalRevenue
FROM Orders;
-- Answer: Total revenue from all orders

-- Reason 2.3: Answer "How many per category?" questions
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;
-- Answer: Orders per year

-- Reason 2.4: Find patterns and trends
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    COUNT(*) AS OrderCount,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY DATEPART(WEEKDAY, OrderDate);
-- Answer: Which days have most orders?


/*
============================================================================
PART 3: GROUP BY Syntax
============================================================================
*/

-- Syntax 3.1: Basic GROUP BY
SELECT 
    column_to_group_by,
    aggregate_function(column)
FROM table
GROUP BY column_to_group_by;

-- Example 3.1: Group by category
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;

-- Example 3.2: Multiple aggregates
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products
GROUP BY CategoryID;

-- Example 3.3: With descriptive names
SELECT 
    CategoryID,
    COUNT(*) AS TotalProducts,
    SUM(Stock) AS TotalStock,
    AVG(Price) AS AveragePrice
FROM Products
GROUP BY CategoryID
ORDER BY CategoryID;


/*
============================================================================
PART 4: The All-or-Nothing Rule
============================================================================
CRITICAL RULE: Every column in SELECT must be either:
  1. In the GROUP BY clause, OR
  2. Inside an aggregate function

This is NOT optional - the query will ERROR otherwise!
*/

-- Example 4.1: ❌ WRONG - ProductName not aggregated or grouped
-- SELECT 
--     CategoryID,
--     ProductName,    -- ERROR! Not in GROUP BY
--     COUNT(*)
-- FROM Products
-- GROUP BY CategoryID;
-- Error: Column 'Products.ProductName' is invalid because it is not 
--        contained in either an aggregate function or the GROUP BY clause.

-- Example 4.2: ✅ CORRECT - All columns are in GROUP BY
SELECT 
    CategoryID,
    ProductName,
    COUNT(*) AS Cnt
FROM Products
GROUP BY CategoryID, ProductName;
-- Works! Both CategoryID and ProductName are in GROUP BY

-- Example 4.3: ✅ CORRECT - Non-grouped column is aggregated
SELECT 
    CategoryID,
    COUNT(DISTINCT ProductName) AS UniqueProducts
FROM Products
GROUP BY CategoryID;
-- Works! ProductName is inside aggregate function

-- Example 4.4: Visual explanation
/*
Think of GROUP BY as creating "buckets":

GROUP BY CategoryID creates buckets:
  Bucket 1 (CategoryID = 1):
    - Product A
    - Product B
    - Product C
  
  Bucket 2 (CategoryID = 2):
    - Product D
    - Product E

SQL must output ONE row per bucket.
Question: Which ProductName should go in that one row?
  - Product A? B? C?
  - SQL doesn't know! Hence the ERROR.

Solution: Use aggregate (COUNT, MAX, etc.) to collapse multiple values into one.
*/


/*
============================================================================
PART 5: Valid vs Invalid Queries
============================================================================
*/

-- Example 5.1: ✅ VALID - All non-aggregated in GROUP BY
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID;

-- Example 5.2: ✅ VALID - Multiple grouping columns
SELECT 
    CustomerID,
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID, YEAR(OrderDate);

-- Example 5.3: ❌ INVALID - OrderDate not in GROUP BY or aggregate
-- SELECT 
--     CustomerID,
--     OrderDate,      -- ERROR!
--     COUNT(*)
-- FROM Orders
-- GROUP BY CustomerID;

-- Example 5.4: ✅ VALID - OrderDate is aggregated
SELECT 
    CustomerID,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID;


/*
============================================================================
PART 6: Grouping vs Filtering
============================================================================
WHERE filters ROWS (before grouping)
HAVING filters GROUPS (after grouping)
*/

-- Example 6.1: WHERE filters rows first
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
WHERE OrderDate >= '2025-01-01'  -- Filter ROWS first
GROUP BY CustomerID;
-- Only counts orders from 2025

-- Example 6.2: HAVING filters groups after aggregation
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 5;  -- Filter GROUPS after counting
-- Only shows customers with more than 5 orders

-- Example 6.3: Combining WHERE and HAVING
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
WHERE OrderDate >= '2024-01-01'    -- Filter: Only 2024+ orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 1000     -- Filter: Only big spenders
ORDER BY TotalSpent DESC;

/*
EXECUTION ORDER:
1. FROM Orders         → Get all order rows
2. WHERE ...           → Filter rows (keep only 2024+)
3. GROUP BY ...        → Create groups by customer
4. HAVING ...          → Filter groups (keep only > $1000)
5. SELECT ...          → Calculate aggregates
6. ORDER BY ...        → Sort results
*/


/*
============================================================================
PART 7: Common Grouping Patterns
============================================================================
*/

-- Pattern 7.1: Count by category
SELECT 
    CategoryID,
    COUNT(*) AS Count
FROM Products
GROUP BY CategoryID;

-- Pattern 7.2: Sum by period
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS MonthlySales
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Pattern 7.3: Average by group
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    AVG(Stock) AS AvgStock
FROM Products
GROUP BY CategoryID;

-- Pattern 7.4: Min/Max by group
SELECT 
    CategoryID,
    MIN(Price) AS CheapestProduct,
    MAX(Price) AS MostExpensive,
    MAX(Price) - MIN(Price) AS PriceRange
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 8: When NOT to Use GROUP BY
============================================================================
*/

-- Example 8.1: Getting a single aggregate (no grouping needed)
SELECT 
    COUNT(*) AS TotalProducts,
    AVG(Price) AS OverallAvgPrice
FROM Products;
-- No GROUP BY because we want ONE row for entire table

-- Example 8.2: Filtering without aggregating
SELECT 
    ProductID,
    ProductName,
    Price
FROM Products
WHERE Price > 100
ORDER BY Price DESC;
-- No GROUP BY - we want individual product rows

-- Example 8.3: Joining tables without summarizing
SELECT 
    o.OrderID,
    o.OrderDate,
    c.FirstName,
    c.LastName
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID;
-- No GROUP BY - showing order details, not summaries


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own before checking solutions:

1. Count products in each category
2. Find total sales amount per customer
3. Calculate average order value by year
4. Find the date range (min/max) of orders per customer
5. Count orders per month in 2025

Solutions below ↓
*/

-- Solution 1: Products per category
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
ORDER BY ProductCount DESC;

-- Solution 2: Total sales per customer
SELECT 
    CustomerID,
    SUM(TotalAmount) AS TotalSales,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
ORDER BY TotalSales DESC;

-- Solution 3: Average order value by year
SELECT 
    YEAR(OrderDate) AS Year,
    AVG(TotalAmount) AS AvgOrderValue,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Solution 4: Order date range per customer
SELECT 
    CustomerID,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS DaysBetween
FROM Orders
GROUP BY CustomerID;

-- Solution 5: Orders per month in 2025
SELECT 
    MONTH(OrderDate) AS Month,
    DATENAME(MONTH, OrderDate) AS MonthName,
    COUNT(*) AS OrderCount
FROM Orders
WHERE YEAR(OrderDate) = 2025
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY Month;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ GROUPING PURPOSE:
  • Transforms detail rows into summary rows
  • Answers "how many" and "how much" questions
  • Reveals patterns and trends

✓ THE ALL-OR-NOTHING RULE:
  • Every SELECT column must be in GROUP BY OR in aggregate
  • This is mandatory, not optional
  • Violating this causes errors

✓ BASIC SYNTAX:
  SELECT 
      grouping_column,
      AGGREGATE(column)
  FROM table
  GROUP BY grouping_column;

✓ WHERE VS HAVING:
  • WHERE: Filters rows BEFORE grouping
  • HAVING: Filters groups AFTER aggregation

✓ WHEN TO GROUP:
  • Need summaries (counts, sums, averages)
  • Analyzing by category, time period, etc.
  • Finding patterns in data

✓ WHEN NOT TO GROUP:
  • Want individual row details
  • Single overall aggregate
  • Simple filtering without summarizing

============================================================================
NEXT: Lesson 08.02 - Aggregate Functions
Learn COUNT, SUM, AVG, MIN, MAX, and statistical functions in depth.
============================================================================
*/
