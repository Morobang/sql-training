/*
============================================================================
Lesson 08.03 - Implicit vs Explicit Groups
============================================================================

Description:
Understand the difference between implicit and explicit grouping, and
master the all-or-nothing rule that governs GROUP BY queries.

Topics Covered:
• Implicit groups (no GROUP BY)
• Explicit groups (with GROUP BY)
• The all-or-nothing rule
• Valid and invalid combinations
• Mixed aggregates and columns

Prerequisites:
• Lessons 08.01-08.02

Estimated Time: 20 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Implicit Groups
============================================================================
When you use aggregate functions WITHOUT GROUP BY, the entire table
becomes ONE implicit group.
*/

-- Example 1.1: Implicit group (entire table)
SELECT 
    COUNT(*) AS TotalProducts,
    AVG(Price) AS AvgPrice,
    SUM(Stock) AS TotalStock
FROM Products;
-- Result: ONE row summarizing ALL products

-- Example 1.2: Multiple aggregates, one implicit group
SELECT 
    COUNT(*) AS Count,
    MIN(Price) AS Cheapest,
    MAX(Price) AS MostExpensive,
    AVG(Price) AS Average
FROM Products;
-- Still ONE row for the whole table

-- Example 1.3: Implicit group with WHERE
SELECT 
    COUNT(*) AS ExpensiveProducts
FROM Products
WHERE Price > 100;
-- ONE row: count of products matching condition


/*
============================================================================
PART 2: Explicit Groups
============================================================================
When you use GROUP BY, you create EXPLICIT groups based on column values.
*/

-- Example 2.1: Explicit groups (one per category)
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;
-- Result: ONE row per CategoryID

-- Example 2.2: Multiple columns in output
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    SUM(Stock) AS TotalStock
FROM Products
GROUP BY CategoryID;
-- Still one row per CategoryID, multiple aggregates

-- Example 2.3: Visual comparison
/*
Implicit (no GROUP BY):
All Products → [One Big Group] → One Summary Row

Explicit (with GROUP BY CategoryID):
All Products → [Group 1] [Group 2] [Group 3] → Three Summary Rows
                Cat 1     Cat 2     Cat 3
*/


/*
============================================================================
PART 3: The All-or-Nothing Rule
============================================================================
CRITICAL RULE:
Every column in SELECT must be EITHER:
  1. In the GROUP BY clause, OR
  2. Inside an aggregate function (COUNT, SUM, AVG, etc.)

No exceptions!
*/

-- Example 3.1: ✅ VALID - All columns are aggregated (implicit group)
SELECT 
    COUNT(*) AS Total,
    AVG(Price) AS AvgPrice
FROM Products;

-- Example 3.2: ✅ VALID - All non-aggregated columns in GROUP BY
SELECT 
    CategoryID,          -- In GROUP BY ✓
    COUNT(*) AS Count    -- Aggregate ✓
FROM Products
GROUP BY CategoryID;

-- Example 3.3: ❌ INVALID - ProductName not in GROUP BY or aggregate
-- SELECT 
--     CategoryID,
--     ProductName,     -- ERROR! Not grouped or aggregated
--     COUNT(*)
-- FROM Products
-- GROUP BY CategoryID;
-- Error: Column 'ProductName' is invalid...

-- Example 3.4: ✅ VALID - Fix by adding to GROUP BY
SELECT 
    CategoryID,
    ProductName,         -- Now in GROUP BY ✓
    COUNT(*) AS Count
FROM Products
GROUP BY CategoryID, ProductName;

-- Example 3.5: ✅ VALID - Fix by aggregating
SELECT 
    CategoryID,
    COUNT(DISTINCT ProductName) AS UniqueProducts  -- Aggregated ✓
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 4: Why This Rule Exists
============================================================================
*/

-- Example 4.1: Understanding the ambiguity
/*
Scenario: Products table
ProductID | CategoryID | ProductName | Price
----------|------------|-------------|------
1         | 1          | Widget A    | 10
2         | 1          | Widget B    | 20
3         | 1          | Widget C    | 15

Query: 
SELECT CategoryID, ProductName, COUNT(*)
FROM Products
GROUP BY CategoryID;

Question: For CategoryID = 1, which ProductName should appear?
  - Widget A?
  - Widget B?
  - Widget C?

SQL doesn't know! Hence the error.
*/

-- Example 4.2: The solution - aggregate the ambiguous column
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    MIN(ProductName) AS FirstProduct,      -- Pick the first alphabetically
    MAX(ProductName) AS LastProduct,       -- Pick the last alphabetically
    COUNT(DISTINCT ProductName) AS Unique  -- Count unique names
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 5: Valid and Invalid Combinations
============================================================================
*/

-- Example 5.1: ✅ Multiple aggregates without GROUP BY
SELECT 
    COUNT(*) AS Total,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrder,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder
FROM Orders;

-- Example 5.2: ✅ Grouped column + aggregates
SELECT 
    CustomerID,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID;

-- Example 5.3: ✅ Multiple grouped columns + aggregates
SELECT 
    CustomerID,
    YEAR(OrderDate) AS Year,
    COUNT(*) AS Orders
FROM Orders
GROUP BY CustomerID, YEAR(OrderDate);

-- Example 5.4: ❌ Grouped + non-grouped columns
-- SELECT 
--     CategoryID,      -- Grouped ✓
--     Price            -- ERROR! Not grouped or aggregated
-- FROM Products
-- GROUP BY CategoryID;

-- Example 5.5: ❌ Aggregate without GROUP BY + non-aggregated column
-- SELECT 
--     CategoryID,      -- ERROR! Not aggregated
--     COUNT(*) AS Total
-- FROM Products;
-- No GROUP BY means implicit group - ALL columns must be aggregated!


/*
============================================================================
PART 6: Mixing Implicit and Explicit Groups
============================================================================
*/

-- Example 6.1: ❌ WRONG - Can't mix implicit and explicit
-- SELECT 
--     COUNT(*) AS TotalProducts,           -- Implicit (whole table)
--     CategoryID                            -- ERROR!
-- FROM Products;
-- If you want CategoryID, you MUST use GROUP BY

-- Example 6.2: ✅ CORRECT - Explicit grouping
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;

-- Example 6.3: Calculating percentage of total
SELECT 
    CategoryID,
    COUNT(*) AS CategoryCount,
    (SELECT COUNT(*) FROM Products) AS TotalProducts,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Products) AS DECIMAL(5,2)) AS Percentage
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 7: Common Mistakes
============================================================================
*/

-- Mistake 7.1: Forgetting to group by all non-aggregated columns
-- ❌ WRONG:
-- SELECT 
--     CustomerID,
--     OrderDate,       -- ERROR! Must be in GROUP BY
--     COUNT(*)
-- FROM Orders
-- GROUP BY CustomerID;

-- ✅ CORRECT:
SELECT 
    CustomerID,
    OrderDate,
    COUNT(*) AS Count
FROM Orders
GROUP BY CustomerID, OrderDate;

-- Mistake 7.2: Using columns from SELECT in WHERE
-- ❌ WRONG:
-- SELECT 
--     CategoryID,
--     COUNT(*) AS ProductCount
-- FROM Products
-- WHERE ProductCount > 5   -- ERROR! Can't use alias
-- GROUP BY CategoryID;

-- ✅ CORRECT - Use HAVING:
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 5;

-- Mistake 7.3: Aggregating already aggregated values
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    -- Can't do: SUM(AVG(Price))  -- ERROR!
    SUM(Price) / COUNT(*) AS AlsoAvgPrice  -- This works
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Get total count of all orders (implicit group)
2. Count orders per customer (explicit group)
3. Show which query is invalid and fix it
4. Calculate average order value per year
5. Identify the error in a given query

Solutions below ↓
*/

-- Solution 1: Implicit group
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders;

-- Solution 2: Explicit group
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID;

-- Solution 3: Invalid query and fix
-- ❌ INVALID:
-- SELECT CategoryID, ProductName, COUNT(*)
-- FROM Products
-- GROUP BY CategoryID;

-- ✅ FIXED:
SELECT 
    CategoryID,
    ProductName,
    COUNT(*) AS Count
FROM Products
GROUP BY CategoryID, ProductName;

-- Solution 4: Average per year
SELECT 
    YEAR(OrderDate) AS Year,
    AVG(TotalAmount) AS AvgOrderValue,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY YEAR(OrderDate);

-- Solution 5: Find the error
-- ❌ ERROR:
-- SELECT CustomerID, OrderDate, SUM(TotalAmount)
-- FROM Orders
-- GROUP BY CustomerID;
-- Problem: OrderDate not in GROUP BY

-- ✅ FIXED:
SELECT 
    CustomerID,
    OrderDate,
    SUM(TotalAmount) AS Total
FROM Orders
GROUP BY CustomerID, OrderDate;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ IMPLICIT GROUPS:
  • No GROUP BY = one group (entire table)
  • ALL columns must be aggregated
  • Returns exactly ONE row

✓ EXPLICIT GROUPS:
  • With GROUP BY = multiple groups
  • One group per unique value combination
  • Returns one row per group

✓ ALL-OR-NOTHING RULE:
  • Every SELECT column must be:
    1. In GROUP BY, OR
    2. Inside aggregate function
  • No exceptions to this rule!

✓ WHY THE RULE:
  • Prevents ambiguity
  • SQL needs ONE value per group
  • Multiple values need aggregation

✓ COMMON FIXES:
  • Add column to GROUP BY
  • Wrap column in aggregate (MIN, MAX, COUNT, etc.)
  • Use HAVING instead of WHERE for aggregates

============================================================================
NEXT: Lesson 08.04 - Counting Distinct Values
Learn to count unique values and handle duplicates.
============================================================================
*/
