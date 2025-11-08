/*
============================================================================
Lesson 08.02 - Aggregate Functions
============================================================================

Description:
Master SQL's aggregate functions: COUNT, SUM, AVG, MIN, MAX, and statistical
functions. Learn how each function behaves and when to use them.

Topics Covered:
• COUNT function variants
• SUM for totals
• AVG for averages
• MIN and MAX
• Statistical functions (STDEV, VAR)
• STRING_AGG for concatenation
• Combining multiple aggregates

Prerequisites:
• Lesson 08.01 - Grouping Concepts

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: COUNT Function
============================================================================
*/

-- Example 1.1: COUNT(*) - Counts ALL rows (including NULLs)
SELECT COUNT(*) AS TotalRows
FROM Products;

-- Example 1.2: COUNT(column) - Counts NON-NULL values only
SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(Price) AS ProductsWithPrice,
    COUNT(*) - COUNT(Price) AS ProductsWithoutPrice
FROM Products;

-- Example 1.3: COUNT(DISTINCT column) - Counts unique non-NULL values
SELECT 
    COUNT(CategoryID) AS TotalReferences,
    COUNT(DISTINCT CategoryID) AS UniqueCategories
FROM Products;

-- Example 1.4: NULL behavior demonstration
CREATE TABLE #TestCount (
    ID INT,
    Value VARCHAR(50)
);

INSERT INTO #TestCount VALUES
(1, 'A'),
(2, 'B'),
(3, NULL),
(4, 'A'),
(5, NULL);

SELECT 
    COUNT(*) AS AllRows,              -- 5 (includes NULLs)
    COUNT(Value) AS NonNullValues,    -- 3 (excludes NULLs)
    COUNT(DISTINCT Value) AS UniqueValues;  -- 2 ('A' and 'B')

DROP TABLE #TestCount;


/*
============================================================================
PART 2: SUM Function
============================================================================
*/

-- Example 2.1: Basic SUM
SELECT 
    SUM(TotalAmount) AS TotalRevenue
FROM Orders;

-- Example 2.2: SUM with GROUP BY
SELECT 
    CustomerID,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

-- Example 2.3: SUM ignores NULLs
SELECT 
    SUM(Price) AS TotalPrice,
    SUM(Stock) AS TotalStock
FROM Products;

-- Example 2.4: Conditional SUM with CASE
SELECT 
    SUM(CASE WHEN Price > 100 THEN 1 ELSE 0 END) AS ExpensiveProducts,
    SUM(CASE WHEN Price <= 100 THEN 1 ELSE 0 END) AS AffordableProducts,
    SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) AS LowStockProducts
FROM Products;

-- Example 2.5: SUM with calculated columns
SELECT 
    SUM(Price * Stock) AS TotalInventoryValue
FROM Products;


/*
============================================================================
PART 3: AVG Function
============================================================================
*/

-- Example 3.1: Basic average
SELECT 
    AVG(Price) AS AveragePrice
FROM Products;

-- Example 3.2: AVG by group
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID;

-- Example 3.3: AVG vs SUM/COUNT
SELECT 
    AVG(TotalAmount) AS AvgMethod1,
    SUM(TotalAmount) / COUNT(*) AS AvgMethod2,
    SUM(TotalAmount) * 1.0 / COUNT(*) AS AvgMethod3  -- Ensures decimal
FROM Orders;

-- Example 3.4: AVG ignores NULLs (important!)
CREATE TABLE #TestAvg (Value INT);
INSERT INTO #TestAvg VALUES (10), (20), (NULL), (30);

SELECT 
    AVG(Value) AS Average,           -- 20 (30 total / 3 non-NULL values)
    SUM(Value) AS Total,             -- 60
    COUNT(Value) AS NonNullCount,    -- 3
    COUNT(*) AS AllRows;             -- 4

DROP TABLE #TestAvg;

-- Example 3.5: Rounded averages
SELECT 
    CategoryID,
    AVG(Price) AS RawAverage,
    CAST(AVG(Price) AS DECIMAL(10,2)) AS RoundedAverage
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 4: MIN and MAX Functions
============================================================================
*/

-- Example 4.1: Find extremes
SELECT 
    MIN(Price) AS CheapestProduct,
    MAX(Price) AS MostExpensive
FROM Products;

-- Example 4.2: MIN/MAX with dates
SELECT 
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS DaySpan
FROM Orders;

-- Example 4.3: MIN/MAX by group
SELECT 
    CategoryID,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice,
    MAX(Price) - MIN(Price) AS PriceRange
FROM Products
GROUP BY CategoryID;

-- Example 4.4: MIN/MAX with strings (alphabetical)
SELECT 
    MIN(ProductName) AS FirstAlphabetically,
    MAX(ProductName) AS LastAlphabetically
FROM Products;

-- Example 4.5: Finding the product with min/max price
-- Note: This shows the value, not which product has it
SELECT 
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products;

-- To get the actual products:
SELECT TOP 1 ProductName, Price
FROM Products
ORDER BY Price;  -- Cheapest

SELECT TOP 1 ProductName, Price
FROM Products
ORDER BY Price DESC;  -- Most expensive


/*
============================================================================
PART 5: Statistical Functions
============================================================================
*/

-- Example 5.1: Standard deviation and variance
SELECT 
    AVG(Price) AS AveragePrice,
    STDEV(Price) AS StandardDeviation,
    VAR(Price) AS Variance
FROM Products;

-- Example 5.2: Population vs sample statistics
SELECT 
    STDEV(Price) AS SampleStdDev,     -- Sample standard deviation
    STDEVP(Price) AS PopStdDev,       -- Population standard deviation
    VAR(Price) AS SampleVariance,
    VARP(Price) AS PopVariance
FROM Products;

-- Example 5.3: Statistical summary
SELECT 
    COUNT(*) AS Count,
    AVG(Price) AS Mean,
    STDEV(Price) AS StdDev,
    MIN(Price) AS Min,
    MAX(Price) AS Max,
    MAX(Price) - MIN(Price) AS Range
FROM Products;

-- Example 5.4: Coefficient of variation
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    STDEV(Price) AS StdDev,
    STDEV(Price) / NULLIF(AVG(Price), 0) * 100 AS CoefficientOfVariation
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 6: STRING_AGG Function (SQL Server 2017+)
============================================================================
*/

-- Example 6.1: Concatenate values
SELECT 
    CategoryID,
    STRING_AGG(ProductName, ', ') AS ProductList
FROM Products
GROUP BY CategoryID;

-- Example 6.2: With ORDER BY
SELECT 
    CategoryID,
    STRING_AGG(ProductName, ', ') WITHIN GROUP (ORDER BY ProductName) AS SortedList
FROM Products
GROUP BY CategoryID;

-- Example 6.3: Custom separators
SELECT 
    CategoryID,
    STRING_AGG(ProductName, ' | ') AS PipeDelimited,
    STRING_AGG(CAST(ProductID AS VARCHAR), ',') AS IDList
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 7: Combining Multiple Aggregates
============================================================================
*/

-- Example 7.1: Comprehensive summary
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    SUM(Stock) AS TotalStock,
    AVG(Stock) AS AvgStock,
    MIN(Stock) AS MinStock,
    MAX(Stock) AS MaxStock,
    SUM(Price * Stock) AS InventoryValue
FROM Products
GROUP BY CategoryID;

-- Example 7.2: Sales analysis
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue,
    MIN(TotalAmount) AS SmallestOrder,
    MAX(TotalAmount) AS LargestOrder
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Example 7.3: Customer metrics
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS CustomerLifetime,
    SUM(TotalAmount) AS TotalSpent,
    AVG(TotalAmount) AS AvgOrderValue,
    MAX(TotalAmount) AS LargestPurchase
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 1  -- Repeat customers only
ORDER BY TotalSpent DESC;


/*
============================================================================
PART 8: Aggregate Function Behavior
============================================================================
*/

-- Behavior 8.1: Aggregates ignore NULL
CREATE TABLE #TestNulls (
    ID INT,
    Value INT
);

INSERT INTO #TestNulls VALUES
(1, 10),
(2, 20),
(3, NULL),
(4, 30),
(5, NULL);

SELECT 
    COUNT(*) AS AllRows,           -- 5
    COUNT(Value) AS NonNullCount,  -- 3
    SUM(Value) AS Total,           -- 60 (NULLs ignored)
    AVG(Value) AS Average,         -- 20 (60/3, not 60/5)
    MIN(Value) AS Minimum,         -- 10
    MAX(Value) AS Maximum;         -- 30

DROP TABLE #TestNulls;

-- Behavior 8.2: Empty groups return NULL
SELECT 
    AVG(Price) AS AvgPrice
FROM Products
WHERE 1 = 0;  -- No rows match
-- Result: NULL

-- Behavior 8.3: COUNT(*) on empty set returns 0
SELECT 
    COUNT(*) AS Count
FROM Products
WHERE 1 = 0;
-- Result: 0 (COUNT(*) is special!)


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find total revenue and order count per customer
2. Calculate average price per category
3. Find product with highest stock
4. Count distinct categories
5. Get statistical summary of order amounts

Solutions below ↓
*/

-- Solution 1:
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalRevenue
FROM Orders
GROUP BY CustomerID
ORDER BY TotalRevenue DESC;

-- Solution 2:
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products
GROUP BY CategoryID;

-- Solution 3:
SELECT TOP 1
    ProductID,
    ProductName,
    Stock
FROM Products
ORDER BY Stock DESC;

-- Solution 4:
SELECT 
    COUNT(DISTINCT CategoryID) AS UniqueCategories
FROM Products;

-- Solution 5:
SELECT 
    COUNT(*) AS TotalOrders,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AvgOrder,
    STDEV(TotalAmount) AS StdDev,
    MIN(TotalAmount) AS SmallestOrder,
    MAX(TotalAmount) AS LargestOrder
FROM Orders;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ COUNT VARIATIONS:
  • COUNT(*): All rows (includes NULL)
  • COUNT(column): Non-NULL values only
  • COUNT(DISTINCT column): Unique non-NULL values

✓ NUMERIC AGGREGATES:
  • SUM: Total of values (ignores NULL)
  • AVG: Average (NULL values excluded from calculation)
  • MIN/MAX: Smallest/largest value

✓ STATISTICAL FUNCTIONS:
  • STDEV/VAR: Sample statistics
  • STDEVP/VARP: Population statistics
  • Used for data analysis and quality metrics

✓ NULL HANDLING:
  • All aggregates ignore NULL (except COUNT(*))
  • AVG = SUM / COUNT(non-NULL)
  • Empty set: Most return NULL, COUNT(*) returns 0

✓ BEST PRACTICES:
  • Use COUNT(*) for row counts
  • Use COUNT(column) to count non-NULL
  • Round AVG results for money
  • Combine aggregates for comprehensive analysis

============================================================================
NEXT: Lesson 08.03 - Implicit vs Explicit Groups
Understand group behavior and the all-or-nothing rule.
============================================================================
*/
