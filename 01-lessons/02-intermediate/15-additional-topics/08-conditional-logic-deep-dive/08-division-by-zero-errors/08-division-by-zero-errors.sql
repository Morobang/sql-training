/*
============================================================================
Lesson 11.08 - Division by Zero Errors
============================================================================

Description:
Master techniques to prevent division by zero errors using CASE expressions,
NULLIF, and IIF functions. Learn safe calculation patterns, NULL handling,
and best practices for robust arithmetic operations.

Topics Covered:
• Division by zero fundamentals
• CASE for zero checking
• NULLIF function for division
• IIF function alternative
• Multiple denominator checks
• Percentage calculations
• NULL vs zero results
• Complex ratio calculations

Prerequisites:
• Lessons 11.01-11.07

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Division by Zero
============================================================================
*/

-- Example 1.1: Division by Zero Error
-- This will cause an error:
-- SELECT 10 / 0;
-- Error: Msg 8134, Divide by zero error encountered.

-- Example 1.2: Demonstration of the Problem
CREATE TABLE #SalesData (
    Region VARCHAR(20),
    TotalSales DECIMAL(10,2),
    TotalOrders INT
);

INSERT INTO #SalesData VALUES
('North', 50000, 100),
('South', 30000, 75),
('East', 0, 0),           -- Division by zero will occur here
('West', 25000, 50);

-- This query will fail:
-- SELECT 
--     Region,
--     TotalSales,
--     TotalOrders,
--     TotalSales / TotalOrders AS AvgOrderValue  -- Error on East region!
-- FROM #SalesData;

/*
Common Scenarios Causing Division by Zero:
1. Zero in denominator column
2. NULL converted to zero
3. Aggregate functions returning zero (COUNT, SUM)
4. Calculated denominators evaluating to zero
5. Empty groups in GROUP BY
*/


/*
============================================================================
PART 2: CASE for Zero Checking
============================================================================
*/

-- Example 2.1: Basic Zero Check with CASE
SELECT 
    Region,
    TotalSales,
    TotalOrders,
    CASE 
        WHEN TotalOrders = 0 THEN 0
        ELSE TotalSales / TotalOrders
    END AS AvgOrderValue
FROM #SalesData;

-- Example 2.2: Return NULL Instead of Zero
SELECT 
    Region,
    TotalSales,
    TotalOrders,
    CASE 
        WHEN TotalOrders = 0 THEN NULL
        ELSE TotalSales / TotalOrders
    END AS AvgOrderValue
FROM #SalesData;

/*
Design Decision: Return 0 or NULL?

Return 0:
✓ Easier for downstream calculations
✓ Clear "no value" indicator
✗ Can be misleading (0 sales vs no orders)

Return NULL:
✓ Semantically correct (no data)
✓ Distinguishes from actual zero
✗ Requires NULL handling downstream
✗ May break aggregations if not handled

Recommendation: Return NULL for missing data, use COALESCE later
*/

-- Example 2.3: Multiple Conditions
SELECT 
    Region,
    TotalSales,
    TotalOrders,
    CASE 
        WHEN TotalOrders IS NULL THEN NULL
        WHEN TotalOrders = 0 THEN NULL
        ELSE TotalSales / TotalOrders
    END AS AvgOrderValue,
    CASE 
        WHEN TotalOrders IS NULL THEN 'No Data'
        WHEN TotalOrders = 0 THEN 'No Orders'
        WHEN TotalSales / TotalOrders > 500 THEN 'High Value'
        WHEN TotalSales / TotalOrders > 300 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS ValueCategory
FROM #SalesData;

-- Example 2.4: Safe Percentage Calculation
SELECT 
    Region,
    TotalSales,
    (SELECT SUM(TotalSales) FROM #SalesData) AS GrandTotal,
    CASE 
        WHEN (SELECT SUM(TotalSales) FROM #SalesData) = 0 THEN NULL
        ELSE ROUND(TotalSales * 100.0 / (SELECT SUM(TotalSales) FROM #SalesData), 2)
    END AS PercentOfTotal
FROM #SalesData;


/*
============================================================================
PART 3: NULLIF Function for Division
============================================================================
*/

-- Example 3.1: NULLIF Basics
-- NULLIF(expr1, expr2) returns NULL if expr1 = expr2, otherwise returns expr1
SELECT 
    NULLIF(10, 10) AS Result1,  -- NULL (10 = 10)
    NULLIF(10, 5) AS Result2,   -- 10 (10 ≠ 5)
    NULLIF(0, 0) AS Result3;    -- NULL (0 = 0)

-- Example 3.2: Division with NULLIF
SELECT 
    Region,
    TotalSales,
    TotalOrders,
    TotalSales / NULLIF(TotalOrders, 0) AS AvgOrderValue
FROM #SalesData;

/*
How NULLIF Works for Division:
1. NULLIF(TotalOrders, 0) returns NULL if TotalOrders = 0
2. Division by NULL returns NULL (not an error)
3. Result: Safe division that returns NULL for zero denominators

Advantage: Concise, readable, standard SQL
*/

-- Example 3.3: NULLIF with COALESCE
SELECT 
    Region,
    TotalSales,
    TotalOrders,
    COALESCE(TotalSales / NULLIF(TotalOrders, 0), 0) AS AvgOrderValue
FROM #SalesData;

/*
Pattern: COALESCE(division / NULLIF(denominator, 0), default_value)
• NULLIF converts zero to NULL
• Division by NULL returns NULL
• COALESCE converts NULL back to desired default (0, -1, etc.)
*/

-- Example 3.4: Real-World Example - Customer Metrics
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    -- Safe average order value
    SUM(o.TotalAmount) / NULLIF(COUNT(o.OrderID), 0) AS AvgOrderValue,
    -- With default value
    COALESCE(SUM(o.TotalAmount) / NULLIF(COUNT(o.OrderID), 0), 0) AS AvgOrderValue_Default
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 15
GROUP BY c.CustomerID, c.CustomerName
ORDER BY c.CustomerID;

DROP TABLE #SalesData;


/*
============================================================================
PART 4: IIF Function Alternative
============================================================================
*/

-- Example 4.1: IIF Basics
-- IIF(condition, true_value, false_value)
SELECT 
    IIF(1 = 1, 'True', 'False') AS Result1,  -- 'True'
    IIF(1 = 2, 'True', 'False') AS Result2;  -- 'False'

-- Example 4.2: Division with IIF
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    IIF(COUNT(o.OrderID) = 0, NULL, SUM(o.TotalAmount) / COUNT(o.OrderID)) AS AvgOrderValue
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 10
GROUP BY c.CustomerID, c.CustomerName
ORDER BY c.CustomerID;

-- Example 4.3: IIF vs CASE vs NULLIF Comparison
SELECT 
    p.ProductID,
    p.ProductName,
    p.UnitsInStock,
    p.ReorderLevel,
    
    -- Method 1: CASE
    CASE 
        WHEN p.ReorderLevel = 0 THEN NULL
        ELSE p.UnitsInStock * 1.0 / p.ReorderLevel
    END AS Ratio_CASE,
    
    -- Method 2: NULLIF
    p.UnitsInStock * 1.0 / NULLIF(p.ReorderLevel, 0) AS Ratio_NULLIF,
    
    -- Method 3: IIF
    IIF(p.ReorderLevel = 0, NULL, p.UnitsInStock * 1.0 / p.ReorderLevel) AS Ratio_IIF
FROM Products p
WHERE p.ProductID <= 10;

/*
Comparison:
┌────────────┬─────────────┬──────────────┬─────────────┐
│   Method   │  Readability│  Performance │  Standard   │
├────────────┼─────────────┼──────────────┼─────────────┤
│ CASE       │   Clear     │    Good      │   ANSI SQL  │
│ NULLIF     │   Concise   │    Good      │   ANSI SQL  │
│ IIF        │   Simple    │    Good      │   T-SQL     │
└────────────┴─────────────┴──────────────┴─────────────┘

Recommendation:
• NULLIF: Best for simple division by zero
• CASE: Best for complex conditions
• IIF: Best for T-SQL-only environments, simple conditions
*/


/*
============================================================================
PART 5: Multiple Denominator Checks
============================================================================
*/

-- Example 5.1: Compound Ratio with Multiple Denominators
CREATE TABLE #ProductMetrics (
    ProductID INT,
    ProductName VARCHAR(50),
    UnitsSold INT,
    UnitsReturned INT,
    TotalRevenue DECIMAL(10,2)
);

INSERT INTO #ProductMetrics VALUES
(1, 'Product A', 100, 5, 5000),
(2, 'Product B', 0, 0, 0),
(3, 'Product C', 50, 2, 2500),
(4, 'Product D', 200, 0, 10000);

SELECT 
    ProductName,
    UnitsSold,
    UnitsReturned,
    TotalRevenue,
    -- Return rate
    CASE 
        WHEN UnitsSold = 0 THEN NULL
        ELSE ROUND(UnitsReturned * 100.0 / UnitsSold, 2)
    END AS ReturnRate_Pct,
    -- Revenue per unit
    TotalRevenue / NULLIF(UnitsSold, 0) AS RevenuePerUnit,
    -- Net units (sold - returned)
    UnitsSold - UnitsReturned AS NetUnits,
    -- Revenue per net unit
    CASE 
        WHEN (UnitsSold - UnitsReturned) = 0 THEN NULL
        ELSE TotalRevenue / (UnitsSold - UnitsReturned)
    END AS RevenuePerNetUnit
FROM #ProductMetrics;

-- Example 5.2: Nested Division Safety
SELECT 
    ProductName,
    UnitsSold,
    TotalRevenue,
    -- Complex calculation: Revenue per unit, then categorize
    CASE 
        WHEN UnitsSold = 0 THEN 'No Sales'
        WHEN TotalRevenue / UnitsSold > 100 THEN 'Premium'
        WHEN TotalRevenue / UnitsSold > 50 THEN 'Standard'
        ELSE 'Budget'
    END AS PriceCategory,
    -- Safe version
    CASE 
        WHEN UnitsSold = 0 THEN 'No Sales'
        WHEN TotalRevenue / NULLIF(UnitsSold, 0) > 100 THEN 'Premium'
        WHEN TotalRevenue / NULLIF(UnitsSold, 0) > 50 THEN 'Standard'
        ELSE 'Budget'
    END AS PriceCategory_Safe
FROM #ProductMetrics;

DROP TABLE #ProductMetrics;

-- Example 5.3: Real-World - Order Efficiency Metrics
SELECT 
    YEAR(o.OrderDate) AS Year,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT CASE WHEN o.DeliveryDate IS NOT NULL THEN o.OrderID END) AS DeliveredOrders,
    SUM(o.TotalAmount) AS Revenue,
    
    -- Orders per month (safe division)
    COUNT(DISTINCT o.OrderID) / NULLIF(COUNT(DISTINCT MONTH(o.OrderDate)), 0) AS AvgOrdersPerMonth,
    
    -- Delivery rate
    ROUND(
        COUNT(DISTINCT CASE WHEN o.DeliveryDate IS NOT NULL THEN o.OrderID END) * 100.0 
        / NULLIF(COUNT(DISTINCT o.OrderID), 0), 
        2
    ) AS DeliveryRate_Pct,
    
    -- Revenue per order
    SUM(o.TotalAmount) / NULLIF(COUNT(DISTINCT o.OrderID), 0) AS AvgOrderValue
FROM Orders o
GROUP BY YEAR(o.OrderDate)
ORDER BY Year;


/*
============================================================================
PART 6: Percentage Calculations
============================================================================
*/

-- Example 6.1: Safe Percentage Pattern
WITH CategorySales AS (
    SELECT 
        c.CategoryName,
        SUM(od.Quantity * od.Price) AS CategoryRevenue
    FROM Categories c
    INNER JOIN Products p ON c.CategoryID = p.CategoryID
    INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryName
),
TotalSales AS (
    SELECT SUM(CategoryRevenue) AS GrandTotal
    FROM CategorySales
)
SELECT 
    cs.CategoryName,
    cs.CategoryRevenue,
    ts.GrandTotal,
    -- Safe percentage
    ROUND(cs.CategoryRevenue * 100.0 / NULLIF(ts.GrandTotal, 0), 2) AS PercentOfTotal
FROM CategorySales cs
CROSS JOIN TotalSales ts
ORDER BY PercentOfTotal DESC;

-- Example 6.2: Growth Rate Calculation
CREATE TABLE #QuarterlySales (
    Quarter VARCHAR(10),
    Sales DECIMAL(10,2)
);

INSERT INTO #QuarterlySales VALUES
('2023-Q1', 10000),
('2023-Q2', 12000),
('2023-Q3', 0),
('2023-Q4', 15000),
('2024-Q1', 18000);

SELECT 
    Quarter,
    Sales,
    LAG(Sales) OVER (ORDER BY Quarter) AS PreviousSales,
    -- Growth amount
    Sales - LAG(Sales) OVER (ORDER BY Quarter) AS Growth,
    -- Growth rate (safe)
    CASE 
        WHEN LAG(Sales) OVER (ORDER BY Quarter) = 0 OR LAG(Sales) OVER (ORDER BY Quarter) IS NULL 
            THEN NULL
        ELSE ROUND(
            (Sales - LAG(Sales) OVER (ORDER BY Quarter)) * 100.0 
            / LAG(Sales) OVER (ORDER BY Quarter), 
            2
        )
    END AS GrowthRate_Pct
FROM #QuarterlySales;

DROP TABLE #QuarterlySales;

-- Example 6.3: Market Share Calculation
WITH CustomerSales AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COALESCE(SUM(o.TotalAmount), 0) AS CustomerTotal
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    CustomerTotal,
    SUM(CustomerTotal) OVER () AS MarketTotal,
    ROUND(
        CustomerTotal * 100.0 / NULLIF(SUM(CustomerTotal) OVER (), 0),
        2
    ) AS MarketShare_Pct,
    CASE 
        WHEN CustomerTotal * 100.0 / NULLIF(SUM(CustomerTotal) OVER (), 0) >= 10 THEN 'Major'
        WHEN CustomerTotal * 100.0 / NULLIF(SUM(CustomerTotal) OVER (), 0) >= 5 THEN 'Significant'
        WHEN CustomerTotal > 0 THEN 'Minor'
        ELSE 'None'
    END AS MarketPosition
FROM CustomerSales
ORDER BY CustomerTotal DESC;


/*
============================================================================
PART 7: NULL vs Zero Results
============================================================================
*/

-- Example 7.1: Semantic Difference
CREATE TABLE #PerformanceData (
    Employee VARCHAR(50),
    CallsAttempted INT,
    CallsCompleted INT
);

INSERT INTO #PerformanceData VALUES
('Alice', 100, 85),
('Bob', 0, 0),       -- No calls attempted
('Charlie', 50, 0);  -- Attempted but none completed

SELECT 
    Employee,
    CallsAttempted,
    CallsCompleted,
    -- Return NULL for no attempts (can't calculate rate)
    CASE 
        WHEN CallsAttempted = 0 THEN NULL
        ELSE ROUND(CallsCompleted * 100.0 / CallsAttempted, 2)
    END AS CompletionRate_NULL,
    -- Return 0 for no attempts
    CASE 
        WHEN CallsAttempted = 0 THEN 0
        ELSE ROUND(CallsCompleted * 100.0 / CallsAttempted, 2)
    END AS CompletionRate_ZERO,
    -- Interpretation
    CASE 
        WHEN CallsAttempted = 0 THEN 'No Activity'
        WHEN CallsCompleted = 0 THEN 'No Success'
        WHEN CallsCompleted * 100.0 / CallsAttempted >= 80 THEN 'Excellent'
        WHEN CallsCompleted * 100.0 / CallsAttempted >= 60 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS Performance
FROM #PerformanceData;

DROP TABLE #PerformanceData;

-- Example 7.2: Aggregation Considerations
CREATE TABLE #MonthlyMetrics (
    Month INT,
    Revenue DECIMAL(10,2),
    Orders INT
);

INSERT INTO #MonthlyMetrics VALUES
(1, 10000, 50),
(2, 0, 0),
(3, 15000, 75);

-- AVG ignores NULLs
SELECT 
    'With NULL' AS Method,
    AVG(Revenue / NULLIF(Orders, 0)) AS AvgOrderValue
FROM #MonthlyMetrics
UNION ALL
-- AVG includes zeros
SELECT 
    'With ZERO' AS Method,
    AVG(CASE WHEN Orders = 0 THEN 0 ELSE Revenue / Orders END) AS AvgOrderValue
FROM #MonthlyMetrics;

/*
Result:
With NULL: (10000/50 + 15000/75) / 2 = (200 + 200) / 2 = 200
With ZERO: (10000/50 + 0 + 15000/75) / 3 = (200 + 0 + 200) / 3 = 133.33

Choose based on business requirement:
• NULL: "Average when orders exist"
• ZERO: "Average including no-order periods"
*/

DROP TABLE #MonthlyMetrics;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Calculate profit margin percentage with zero revenue handling
2. Compute customer retention rate with safe division
3. Build inventory turnover ratio with zero stock handling
4. Calculate year-over-year growth rates safely
5. Create conversion funnel metrics with multiple division points

Solutions below ↓
*/

-- Solution 1: Profit Margin
CREATE TABLE #ProfitData (ProductID INT, Revenue DECIMAL(10,2), Cost DECIMAL(10,2));
INSERT INTO #ProfitData VALUES (1, 1000, 600), (2, 0, 50), (3, 500, 400);

SELECT 
    ProductID,
    Revenue,
    Cost,
    Revenue - Cost AS Profit,
    ROUND((Revenue - Cost) * 100.0 / NULLIF(Revenue, 0), 2) AS ProfitMargin_Pct,
    CASE 
        WHEN Revenue = 0 THEN 'No Revenue'
        WHEN (Revenue - Cost) * 100.0 / Revenue >= 40 THEN 'High Margin'
        WHEN (Revenue - Cost) * 100.0 / Revenue >= 20 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS MarginCategory
FROM #ProfitData;

DROP TABLE #ProfitData;

-- Solution 2: Customer Retention Rate
WITH YearlyCustomers AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        COUNT(DISTINCT CustomerID) AS Customers
    FROM Orders
    GROUP BY YEAR(OrderDate)
)
SELECT 
    y1.Year,
    y1.Customers AS Current_Year_Customers,
    y2.Customers AS Previous_Year_Customers,
    ROUND(
        y1.Customers * 100.0 / NULLIF(y2.Customers, 0),
        2
    ) AS RetentionRate_Pct
FROM YearlyCustomers y1
LEFT JOIN YearlyCustomers y2 ON y1.Year = y2.Year + 1
ORDER BY y1.Year;

-- Solution 3: Inventory Turnover
SELECT 
    p.ProductID,
    p.ProductName,
    p.UnitsInStock,
    COALESCE(SUM(od.Quantity), 0) AS UnitsSold,
    -- Inventory turnover ratio
    COALESCE(SUM(od.Quantity), 0) * 1.0 / NULLIF(p.UnitsInStock, 0) AS TurnoverRatio,
    CASE 
        WHEN p.UnitsInStock = 0 THEN 'Out of Stock'
        WHEN COALESCE(SUM(od.Quantity), 0) * 1.0 / p.UnitsInStock >= 5 THEN 'Fast Moving'
        WHEN COALESCE(SUM(od.Quantity), 0) * 1.0 / p.UnitsInStock >= 2 THEN 'Moderate'
        ELSE 'Slow Moving'
    END AS MovementSpeed
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
WHERE p.ProductID <= 10
GROUP BY p.ProductID, p.ProductName, p.UnitsInStock
ORDER BY TurnoverRatio DESC;

-- Solution 4: (see lesson content - Example 6.2)
-- Solution 5: (see lesson content - multiple examples)


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ DIVISION BY ZERO:
  • SQL Server throws error on division by zero
  • Common in ratios, percentages, averages
  • Must be handled proactively
  • Check both explicit zeros and NULL values

✓ CASE METHOD:
  • Most explicit and readable
  • Full control over return value
  • Can handle complex conditions
  • Best for multiple conditions

✓ NULLIF FUNCTION:
  • Concise: NULLIF(denominator, 0)
  • Returns NULL if denominator is zero
  • Division by NULL returns NULL (no error)
  • Pattern: expr / NULLIF(denominator, 0)

✓ IIF FUNCTION:
  • Simple ternary operator
  • IIF(denominator = 0, default, division)
  • T-SQL specific (not ANSI SQL)
  • Good for simple conditions

✓ COALESCE COMBO:
  • COALESCE(expr / NULLIF(denom, 0), default)
  • Converts NULL back to desired default
  • Most robust pattern
  • Handles both zero and NULL

✓ NULL VS ZERO:
  • NULL: "Cannot calculate" (semantically correct)
  • ZERO: "Calculated as zero" (may be misleading)
  • Choose based on business meaning
  • Consider downstream aggregations (AVG, SUM)

✓ PERCENTAGE CALCULATIONS:
  • Always multiply by 100.0 (force decimal)
  • Use NULLIF or CASE for denominator
  • ROUND to appropriate precision
  • Consider edge cases (zero total)

✓ BEST PRACTICES:
  • Use NULLIF for simple division by zero
  • Use CASE for complex business logic
  • Return NULL for missing data, not zero
  • Use COALESCE to convert NULL to default
  • Multiply by 1.0 to force decimal division
  • Document zero-handling strategy
  • Test edge cases (zero, NULL, negative)

✓ PERFORMANCE:
  • All methods have similar performance
  • Choose based on readability
  • Avoid repeated calculations (use CTE)
  • Consider computed columns for frequent use

============================================================================
NEXT: Lesson 11.09 - Conditional Updates
Learn to use CASE in UPDATE statements for conditional data modifications.
============================================================================
*/
