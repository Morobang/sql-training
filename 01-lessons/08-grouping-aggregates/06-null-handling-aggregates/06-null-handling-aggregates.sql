/*
============================================================================
Lesson 08.06 - NULL Handling in Aggregates
============================================================================

Description:
Master how NULL values behave with aggregate functions and grouping,
and learn strategies to handle NULL appropriately in your queries.

Topics Covered:
• How aggregates treat NULL
• COUNT(*) vs COUNT(column)
• NULL in GROUP BY
• COALESCE and ISNULL strategies
• NULL vs zero distinction

Prerequisites:
• Lessons 08.01-08.05
• Chapter 04 (NULL handling basics)

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: How Aggregates Treat NULL
============================================================================
*/

-- Setup: Demo table with NULL values
CREATE TABLE #SalesData (
    ProductID INT,
    SalesAmount DECIMAL(10,2),
    Commission DECIMAL(10,2)  -- Some NULL values
);

INSERT INTO #SalesData VALUES
(1, 100.00, 10.00),
(2, 200.00, 20.00),
(3, 150.00, NULL),   -- No commission
(4, 180.00, 18.00),
(5, 220.00, NULL);   -- No commission

-- Example 1.1: COUNT behavior with NULL
SELECT 
    COUNT(*) AS TotalRows,              -- 5 (counts all rows)
    COUNT(SalesAmount) AS NonNullSales, -- 5 (all have values)
    COUNT(Commission) AS NonNullComm,   -- 3 (excludes NULL)
    COUNT(DISTINCT Commission) AS UniqueComm  -- 3 (excludes NULL)
FROM #SalesData;

-- Example 1.2: SUM ignores NULL
SELECT 
    SUM(SalesAmount) AS TotalSales,   -- 850.00 (all 5 values)
    SUM(Commission) AS TotalComm      -- 48.00 (only 3 non-NULL values)
FROM #SalesData;

-- Example 1.3: AVG ignores NULL (divides by non-NULL count)
SELECT 
    AVG(SalesAmount) AS AvgSales,     -- 170.00 (850 / 5)
    AVG(Commission) AS AvgComm,       -- 16.00 (48 / 3, not 48 / 5!)
    SUM(Commission) / COUNT(*) AS WrongAvg,  -- 9.60 (treats NULL as 0)
    SUM(Commission) / COUNT(Commission) AS CorrectAvg  -- 16.00
FROM #SalesData;

-- Example 1.4: MIN and MAX ignore NULL
SELECT 
    MIN(SalesAmount) AS MinSales,  -- 100.00
    MAX(SalesAmount) AS MaxSales,  -- 220.00
    MIN(Commission) AS MinComm,    -- 10.00 (ignores NULL)
    MAX(Commission) AS MaxComm     -- 20.00 (ignores NULL)
FROM #SalesData;

DROP TABLE #SalesData;


/*
============================================================================
PART 2: COUNT(*) vs COUNT(column)
============================================================================
*/

-- Example 2.1: The critical difference
SELECT 
    COUNT(*) AS AllOrders,                    -- Total rows
    COUNT(TotalAmount) AS OrdersWithAmount,   -- Non-NULL amounts
    COUNT(ShippedDate) AS ShippedOrders       -- Non-NULL ship dates
FROM Orders;

-- Example 2.2: Finding NULL values
SELECT 
    COUNT(*) - COUNT(ShippedDate) AS UnshippedOrders
FROM Orders;

-- Example 2.3: Percentage with NULL
SELECT 
    COUNT(*) AS Total,
    COUNT(ShippedDate) AS Shipped,
    COUNT(*) - COUNT(ShippedDate) AS NotShipped,
    CAST(COUNT(ShippedDate) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ShippedPercent
FROM Orders;


/*
============================================================================
PART 3: NULL in GROUP BY
============================================================================
*/

-- Setup: Demo table with NULL in grouped column
CREATE TABLE #CustomerOrders (
    CustomerID INT,
    OrderAmount DECIMAL(10,2)
);

INSERT INTO #CustomerOrders VALUES
(1, 100.00),
(1, 150.00),
(2, 200.00),
(NULL, 50.00),   -- Unknown customer
(NULL, 75.00),   -- Unknown customer
(3, 180.00);

-- Example 3.1: NULL becomes its own group
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalAmount
FROM #CustomerOrders
GROUP BY CustomerID
ORDER BY CustomerID;
-- Result includes one row where CustomerID IS NULL

-- Example 3.2: Handling NULL in groups
SELECT 
    COALESCE(CAST(CustomerID AS VARCHAR(10)), 'Unknown') AS Customer,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalAmount
FROM #CustomerOrders
GROUP BY CustomerID
ORDER BY CustomerID;

-- Example 3.3: Filtering NULL groups
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(OrderAmount) AS TotalAmount
FROM #CustomerOrders
WHERE CustomerID IS NOT NULL  -- Exclude NULL before grouping
GROUP BY CustomerID
ORDER BY CustomerID;

DROP TABLE #CustomerOrders;


/*
============================================================================
PART 4: COALESCE and ISNULL Strategies
============================================================================
*/

-- Example 4.1: Replace NULL in aggregates with COALESCE
SELECT 
    CustomerID,
    COUNT(*) AS TotalOrders,
    COALESCE(SUM(TotalAmount), 0) AS Revenue,  -- 0 if all NULL
    COALESCE(AVG(TotalAmount), 0) AS AvgOrder
FROM Orders
GROUP BY CustomerID;

-- Example 4.2: ISNULL for individual values before aggregating
SELECT 
    AVG(ISNULL(Commission, 0)) AS AvgCommission  -- Treats NULL as 0
FROM (
    VALUES (10.00), (20.00), (NULL), (15.00)
) AS Sales(Commission);
-- Result: 11.25 (45 / 4, including NULL as 0)

-- Example 4.3: Different strategies, different results
CREATE TABLE #CommissionData (
    SaleID INT,
    Commission DECIMAL(10,2)
);

INSERT INTO #CommissionData VALUES
(1, 100), (2, 200), (3, NULL), (4, 150);

SELECT 
    'Strategy 1: Ignore NULL' AS Approach,
    AVG(Commission) AS Result  -- 150 (450 / 3)
FROM #CommissionData
UNION ALL
SELECT 
    'Strategy 2: NULL as Zero',
    AVG(ISNULL(Commission, 0))  -- 112.50 (450 / 4)
FROM #CommissionData
UNION ALL
SELECT 
    'Strategy 3: NULL as Average',
    AVG(COALESCE(Commission, (SELECT AVG(Commission) FROM #CommissionData)))
FROM #CommissionData;

DROP TABLE #CommissionData;


/*
============================================================================
PART 5: NULL vs Zero Distinction
============================================================================
*/

-- Example 5.1: NULL means "unknown", 0 means "zero"
CREATE TABLE #ProductSales (
    ProductID INT,
    SalesLastMonth DECIMAL(10,2)
);

INSERT INTO #ProductSales VALUES
(1, 1000.00),  -- Sold $1000
(2, 0.00),     -- Sold nothing (tracked but zero)
(3, NULL);     -- Not tracked (unknown/new product)

SELECT 
    ProductID,
    ISNULL(SalesLastMonth, -1) AS Sales,  -- Use -1 to distinguish NULL
    CASE 
        WHEN SalesLastMonth IS NULL THEN 'Not Tracked'
        WHEN SalesLastMonth = 0 THEN 'No Sales'
        ELSE 'Has Sales'
    END AS Status
FROM #ProductSales;

DROP TABLE #ProductSales;

-- Example 5.2: Counting zeros vs NULL
CREATE TABLE #Inventory (
    ProductID INT,
    Stock INT
);

INSERT INTO #Inventory VALUES
(1, 50), (2, 0), (3, NULL), (4, 25), (5, 0), (6, NULL);

SELECT 
    COUNT(*) AS TotalProducts,
    COUNT(Stock) AS TrackedProducts,
    COUNT(*) - COUNT(Stock) AS UntrackedProducts,
    SUM(CASE WHEN Stock = 0 THEN 1 ELSE 0 END) AS OutOfStock,
    SUM(CASE WHEN Stock > 0 THEN 1 ELSE 0 END) AS InStock
FROM #Inventory;

DROP TABLE #Inventory;


/*
============================================================================
PART 6: Practical NULL Handling Patterns
============================================================================
*/

-- Pattern 6.1: Default values for display
SELECT 
    CategoryID,
    COALESCE(AVG(Price), 0) AS AvgPrice,
    COALESCE(MIN(Price), 0) AS MinPrice,
    COALESCE(MAX(Price), 0) AS MaxPrice,
    COUNT(*) AS ProductCount,
    COUNT(Price) AS ProductsWithPrice
FROM Products
GROUP BY CategoryID;

-- Pattern 6.2: Handling NULL in calculations
SELECT 
    ProductID,
    Price,
    Stock,
    -- Multiply only if both are non-NULL
    CASE 
        WHEN Price IS NOT NULL AND Stock IS NOT NULL 
        THEN Price * Stock 
        ELSE NULL 
    END AS InventoryValue,
    -- Use 0 for NULL in sum
    ISNULL(Price, 0) * ISNULL(Stock, 0) AS InventoryValueZero
FROM Products;

-- Pattern 6.3: Conditional aggregation with NULL
SELECT 
    CategoryID,
    COUNT(*) AS AllProducts,
    COUNT(Price) AS ProductsWithPrice,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS ProductsWithoutPrice,
    AVG(CASE WHEN Price < 50 THEN Price END) AS AvgBudgetPrice,  -- NULL if no match
    AVG(CASE WHEN Price >= 50 THEN Price ELSE NULL END) AS AvgPremiumPrice
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PART 7: Common Mistakes and Fixes
============================================================================
*/

-- Mistake 7.1: ❌ Assuming NULL = 0
-- SELECT AVG(Commission) FROM Sales;  
-- This IGNORES NULL, not treats it as 0!

-- ✅ Fix: Be explicit about what you want
SELECT 
    AVG(Commission) AS AvgOfNonNull,
    AVG(ISNULL(Commission, 0)) AS AvgTreatingNullAsZero
FROM (VALUES (100.00), (200.00), (NULL)) AS Sales(Commission);

-- Mistake 7.2: ❌ Using COUNT(column) when you want COUNT(*)
-- SELECT CategoryID, COUNT(Price) FROM Products GROUP BY CategoryID;
-- This counts only products WITH a price!

-- ✅ Fix: Use COUNT(*) for all rows
SELECT 
    CategoryID, 
    COUNT(*) AS AllProducts,
    COUNT(Price) AS WithPrice,
    COUNT(*) - COUNT(Price) AS WithoutPrice
FROM Products
GROUP BY CategoryID;

-- Mistake 7.3: ❌ Not handling NULL in GROUP BY display
SELECT 
    CategoryID,  -- Shows NULL as empty/NULL
    COUNT(*) AS Count
FROM Products
GROUP BY CategoryID;

-- ✅ Fix: Replace NULL for display
SELECT 
    COALESCE(CAST(CategoryID AS VARCHAR(10)), 'Uncategorized') AS Category,
    COUNT(*) AS Count
FROM Products
GROUP BY CategoryID;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Count orders with and without ShippedDate
2. Calculate average order value, treating NULL as 0
3. Group by CategoryID, showing "No Category" for NULL
4. Find products where Price IS NULL
5. Compare AVG with NULL ignored vs NULL as zero

Solutions below ↓
*/

-- Solution 1:
SELECT 
    COUNT(*) AS TotalOrders,
    COUNT(ShippedDate) AS Shipped,
    COUNT(*) - COUNT(ShippedDate) AS NotShipped,
    CAST(COUNT(ShippedDate) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ShippedPercent
FROM Orders;

-- Solution 2:
SELECT 
    AVG(TotalAmount) AS AvgIgnoringNull,
    AVG(ISNULL(TotalAmount, 0)) AS AvgWithNullAsZero,
    SUM(ISNULL(TotalAmount, 0)) AS TotalRevenue
FROM Orders;

-- Solution 3:
SELECT 
    ISNULL(CAST(CategoryID AS VARCHAR(10)), 'No Category') AS Category,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID
ORDER BY CategoryID;

-- Solution 4:
SELECT 
    ProductID,
    ProductName,
    Stock,
    CASE 
        WHEN Price IS NULL THEN 'Price Not Set'
        ELSE CAST(Price AS VARCHAR(20))
    END AS PriceStatus
FROM Products
WHERE Price IS NULL;

-- Solution 5:
WITH TestData AS (
    SELECT Commission FROM (VALUES (100.00), (200.00), (NULL), (150.00)) AS T(Commission)
)
SELECT 
    'Ignore NULL' AS Strategy,
    AVG(Commission) AS Average,
    SUM(Commission) AS Total,
    COUNT(Commission) AS CountUsed
FROM TestData
UNION ALL
SELECT 
    'NULL as Zero',
    AVG(ISNULL(Commission, 0)),
    SUM(ISNULL(Commission, 0)),
    COUNT(*)
FROM TestData;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ AGGREGATE FUNCTIONS AND NULL:
  • COUNT(*): Counts all rows (includes NULL)
  • COUNT(column): Counts non-NULL values only
  • SUM, AVG, MIN, MAX: Ignore NULL values
  • AVG divides by non-NULL count, not total rows

✓ GROUP BY AND NULL:
  • NULL values form their own group
  • Use COALESCE/ISNULL to handle display
  • Filter with WHERE to exclude NULL groups

✓ NULL vs ZERO:
  • NULL = unknown/not applicable
  • 0 = known value of zero
  • Don't treat them the same!

✓ BEST PRACTICES:
  • Be explicit about NULL handling
  • Use COUNT(*) for total rows
  • Use COUNT(column) for non-NULL count
  • COALESCE for default values
  • Document your NULL strategy

✓ COMMON PATTERNS:
  • COALESCE(aggregate, 0) for default
  • COUNT(*) - COUNT(column) for NULL count
  • ISNULL(column, 0) before aggregation
  • CASE WHEN column IS NULL for grouping

============================================================================
NEXT: Lesson 08.08 - Multicolumn Grouping
Learn to group by multiple columns for hierarchical analysis.
============================================================================
*/
