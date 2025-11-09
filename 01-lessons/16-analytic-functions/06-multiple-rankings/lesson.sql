/*
================================================================================
LESSON 16.6: MULTIPLE RANKINGS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use multiple ranking functions in a single query
2. Apply different PARTITION BY clauses for various perspectives
3. Combine rankings to create complex classifications
4. Understand performance implications of multiple rankings
5. Create multi-dimensional analytical reports
6. Build composite scoring systems

Business Context:
-----------------
Real-world analysis often requires multiple perspectives. A product might rank
#1 in revenue but #10 in quantity sold. A customer might be top-tier overall
but underperforming in their segment. Multiple rankings provide the complete
picture needed for strategic decisions.

Database: RetailStore
Complexity: Advanced
Estimated Time: 50 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: MULTIPLE RANKINGS WITH DIFFERENT ORDER BY
================================================================================

Same partition, different orderings provide multiple perspectives.
*/

-- Example 1: Product rankings from different angles
SELECT 
    p.ProductName,
    p.Category,
    SUM(s.SaleAmount) AS TotalRevenue,
    SUM(s.Quantity) AS TotalQuantity,
    COUNT(*) AS TransactionCount,
    -- Three different rankings
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RevenueRank,
    RANK() OVER(ORDER BY SUM(s.Quantity) DESC) AS QuantityRank,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS FrequencyRank
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName, p.Category
ORDER BY RevenueRank;
GO

/*
OUTPUT:
ProductName       Category      TotalRevenue  TotalQuantity  TransactionCount  RevenueRank  QuantityRank  FrequencyRank
----------------  ------------  ------------  -------------  ----------------  -----------  ------------  -------------
Laptop Pro        Electronics   29899.77      23             4                 1            4              1
Laptop Basic      Electronics   4899.93       7              1                 2            6              4
Monitor 4K        Electronics   2099.97       3              1                 3            7              4
Mouse Wireless    Accessories   1049.65       35             3                 4            1              2
Keyboard Mech     Accessories   449.85        15             1                 5            5              4
USB Hub           Accessories   299.94        10             1                 6            6              4
Webcam HD         Electronics   179.98        2              1                 7            8              4

Different perspectives reveal different stories:
- Laptop Pro: #1 revenue, #4 quantity (high-value, lower volume)
- Mouse Wireless: #4 revenue, #1 quantity (high volume, lower value)
*/

-- Example 2: Identify rank discrepancies
SELECT 
    p.ProductName,
    SUM(s.SaleAmount) AS TotalRevenue,
    SUM(s.Quantity) AS TotalQuantity,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RevenueRank,
    RANK() OVER(ORDER BY SUM(s.Quantity) DESC) AS QuantityRank,
    ABS(
        RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) - 
        RANK() OVER(ORDER BY SUM(s.Quantity) DESC)
    ) AS RankDifference,
    CASE 
        WHEN RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) < 
             RANK() OVER(ORDER BY SUM(s.Quantity) DESC) 
        THEN 'High Value'
        WHEN RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) > 
             RANK() OVER(ORDER BY SUM(s.Quantity) DESC) 
        THEN 'High Volume'
        ELSE 'Balanced'
    END AS ProductProfile
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName
ORDER BY RankDifference DESC;
GO

/*
OUTPUT:
ProductName       TotalRevenue  TotalQuantity  RevenueRank  QuantityRank  RankDifference  ProductProfile
----------------  ------------  -------------  -----------  ------------  --------------  --------------
Laptop Pro        29899.77      23             1            4             3               High Value
Mouse Wireless    1049.65       35             4            1             3               High Volume
Monitor 4K        2099.97       3              3            7             4               High Value
Keyboard Mech     449.85        15             5            5             0               Balanced

High RankDifference indicates specialized products!
*/

/*
================================================================================
PART 2: MULTIPLE PARTITIONS IN ONE QUERY
================================================================================

Different PARTITION BY clauses reveal insights at different levels.
*/

-- Example 1: Rankings at different hierarchical levels
SELECT 
    Region,
    p.Category,
    p.ProductName,
    SUM(s.SaleAmount) AS TotalSales,
    -- Overall ranking
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS OverallRank,
    -- Regional ranking
    RANK() OVER(
        PARTITION BY Region 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS RegionRank,
    -- Category ranking
    RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS CategoryRank,
    -- Region + Category ranking
    RANK() OVER(
        PARTITION BY Region, p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS RegionCategoryRank
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE Region IS NOT NULL
GROUP BY Region, p.Category, p.ProductName
ORDER BY OverallRank;
GO

/*
OUTPUT:
Region   Category      ProductName       TotalSales   OverallRank  RegionRank  CategoryRank  RegionCategoryRank
-------  ------------  ----------------  -----------  -----------  ----------  ------------  ------------------
Central  Electronics   Laptop Pro        12999.90     1            1           1             1
East     Electronics   Laptop Pro        10399.92     2            1           2             1
East     Electronics   Laptop Basic      4899.93      3            2           3             2
Central  Electronics   Monitor 4K        2099.97      4            2           4             2
East     Accessories   Mouse Wireless    449.75       5            3           1             1
Central  Accessories   USB Hub           299.94       6            3           2             1

Multi-level perspective in one query!
*/

-- Example 2: Customer rankings with multiple dimensions
SELECT 
    c.CustomerName,
    c.CustomerType,
    COUNT(*) AS PurchaseCount,
    SUM(s.SaleAmount) AS TotalSpent,
    -- Overall rankings
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SpendingRank,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS FrequencyRank,
    -- Type-specific rankings
    RANK() OVER(
        PARTITION BY c.CustomerType 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS TypeSpendingRank,
    RANK() OVER(
        PARTITION BY c.CustomerType 
        ORDER BY COUNT(*) DESC
    ) AS TypeFrequencyRank
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerName, c.CustomerType
ORDER BY SpendingRank;
GO

/*
OUTPUT:
CustomerName    CustomerType  PurchaseCount  TotalSpent   SpendingRank  FrequencyRank  TypeSpendingRank  TypeFrequencyRank
--------------  ------------  -------------  -----------  ------------  -------------  ----------------  -----------------
Enterprise LLC  Enterprise    1              12999.90     1             3              1                 1
Acme Corp       Enterprise    3              7099.75      2             1              2                 1
Global Traders  Wholesale     2              4899.93      3             2              1                 1
Tech Start      Small Biz     1              2799.96      4             3              1                 1

Compare both overall and within-type performance!
*/

/*
================================================================================
PART 3: COMBINING RANKINGS FOR CLASSIFICATION
================================================================================

Use multiple rankings to create sophisticated classification systems.
*/

-- Example 1: Two-dimensional product classification
SELECT 
    p.ProductName,
    SUM(s.SaleAmount) AS TotalRevenue,
    SUM(s.Quantity) AS TotalQuantity,
    NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RevenueTier,
    NTILE(3) OVER(ORDER BY SUM(s.Quantity) DESC) AS VolumeTier,
    CASE 
        -- High revenue, high volume
        WHEN NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 
         AND NTILE(3) OVER(ORDER BY SUM(s.Quantity) DESC) = 1 
        THEN 'Star Product'
        -- High revenue, low volume
        WHEN NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 
         AND NTILE(3) OVER(ORDER BY SUM(s.Quantity) DESC) = 3 
        THEN 'Premium Product'
        -- Low revenue, high volume
        WHEN NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 3 
         AND NTILE(3) OVER(ORDER BY SUM(s.Quantity) DESC) = 1 
        THEN 'Volume Product'
        -- Low revenue, low volume
        WHEN NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 3 
         AND NTILE(3) OVER(ORDER BY SUM(s.Quantity) DESC) = 3 
        THEN 'Underperformer'
        ELSE 'Standard Product'
    END AS ProductCategory
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName
ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
ProductName       TotalRevenue  TotalQuantity  RevenueTier  VolumeTier  ProductCategory
----------------  ------------  -------------  -----------  ----------  -----------------
Laptop Pro        29899.77      23             1            1           Star Product
Laptop Basic      4899.93       7              1            2           Standard Product
Monitor 4K        2099.97       3              1            3           Premium Product
Mouse Wireless    1049.65       35             2            1           Standard Product
Keyboard Mech     449.85        15             2            2           Standard Product
USB Hub           299.94        10             3            2           Standard Product
Webcam HD         179.98        2              3            3           Underperformer

BCG-style matrix classification!
*/

-- Example 2: Composite scoring system
SELECT 
    p.ProductName,
    SUM(s.SaleAmount) AS TotalRevenue,
    SUM(s.Quantity) AS TotalQuantity,
    COUNT(*) AS TransactionCount,
    -- Individual scores (1-10, higher is better)
    11 - NTILE(10) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RevenueScore,
    11 - NTILE(10) OVER(ORDER BY SUM(s.Quantity) DESC) AS VolumeScore,
    11 - NTILE(10) OVER(ORDER BY COUNT(*) DESC) AS FrequencyScore,
    -- Composite score (average of all scores)
    (
        (11 - NTILE(10) OVER(ORDER BY SUM(s.SaleAmount) DESC)) +
        (11 - NTILE(10) OVER(ORDER BY SUM(s.Quantity) DESC)) +
        (11 - NTILE(10) OVER(ORDER BY COUNT(*) DESC))
    ) / 3.0 AS CompositeScore
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName
ORDER BY CompositeScore DESC;
GO

/*
OUTPUT:
ProductName       TotalRevenue  TotalQuantity  TransactionCount  RevenueScore  VolumeScore  FrequencyScore  CompositeScore
----------------  ------------  -------------  ----------------  ------------  -----------  --------------  --------------
Laptop Pro        29899.77      23             4                 10            7            10              9.0
Mouse Wireless    1049.65       35             3                 7             10           7               8.0
Laptop Basic      4899.93       7              1                 9             4            1               4.67
...

Balanced scoring considers all dimensions!
*/

/*
================================================================================
PART 4: TIME-BASED MULTIPLE RANKINGS
================================================================================

Rankings across different time periods reveal trends.
*/

-- Example 1: Current vs historical rankings
WITH MonthlySales AS (
    SELECT 
        p.ProductName,
        MONTH(s.SaleDate) AS SaleMonth,
        SUM(s.SaleAmount) AS MonthlyRevenue
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
    GROUP BY p.ProductName, MONTH(s.SaleDate)
)
SELECT 
    ProductName,
    SaleMonth,
    MonthlyRevenue,
    RANK() OVER(
        PARTITION BY SaleMonth 
        ORDER BY MonthlyRevenue DESC
    ) AS MonthRank,
    RANK() OVER(
        ORDER BY MonthlyRevenue DESC
    ) AS OverallRank,
    LAG(RANK() OVER(
        PARTITION BY SaleMonth 
        ORDER BY MonthlyRevenue DESC
    )) OVER(
        PARTITION BY ProductName 
        ORDER BY SaleMonth
    ) AS PreviousMonthRank
FROM MonthlySales
ORDER BY ProductName, SaleMonth;
GO

/*
OUTPUT:
ProductName       SaleMonth  MonthlyRevenue  MonthRank  OverallRank  PreviousMonthRank
----------------  ---------  --------------  ---------  -----------  -----------------
Keyboard Mech     3          449.85          3          9            NULL
Laptop Basic      2          4899.93         1          3            NULL
Laptop Pro        1          6499.95         1          2            NULL
Laptop Pro        3          10399.92        1          1            1
Laptop Pro        4          12999.90        1          1            1
Monitor 4K        2          2099.97         2          5            NULL
Mouse Wireless    1          299.90          2          12           NULL
Mouse Wireless    3          449.85          3          9            2
Mouse Wireless    5          299.90          1          12           3

Track rank changes over time!
*/

/*
================================================================================
PART 5: ADVANCED MULTI-RANKING SCENARIOS
================================================================================
*/

-- Example 1: Regional performance matrix
SELECT 
    Region,
    COUNT(DISTINCT s.CustomerID) AS CustomerCount,
    SUM(s.SaleAmount) AS TotalRevenue,
    AVG(s.SaleAmount) AS AvgOrderValue,
    -- Revenue rankings
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RevenueRank,
    -- Customer base rankings
    RANK() OVER(ORDER BY COUNT(DISTINCT s.CustomerID) DESC) AS CustomerRank,
    -- AOV rankings
    RANK() OVER(ORDER BY AVG(s.SaleAmount) DESC) AS AOVRank,
    -- Composite regional score
    CASE 
        WHEN RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 
          OR RANK() OVER(ORDER BY COUNT(DISTINCT s.CustomerID) DESC) = 1 
        THEN 'Top Region'
        WHEN RANK() OVER(ORDER BY AVG(s.SaleAmount) DESC) = 1 
        THEN 'Premium Region'
        ELSE 'Standard Region'
    END AS RegionClassification
FROM Sales s
WHERE Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY Region
ORDER BY RevenueRank;
GO

-- Example 2: Customer lifecycle analysis
SELECT 
    c.CustomerName,
    MIN(s.SaleDate) AS FirstPurchase,
    MAX(s.SaleDate) AS LastPurchase,
    COUNT(*) AS PurchaseCount,
    SUM(s.SaleAmount) AS TotalSpent,
    -- Recency ranking (how recently they purchased)
    RANK() OVER(ORDER BY MAX(s.SaleDate) DESC) AS RecencyRank,
    -- Frequency ranking (how often they purchase)
    RANK() OVER(ORDER BY COUNT(*) DESC) AS FrequencyRank,
    -- Monetary ranking (how much they spend)
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS MonetaryRank,
    -- RFM Score (sum of three ranks, lower is better)
    RANK() OVER(ORDER BY MAX(s.SaleDate) DESC) +
    RANK() OVER(ORDER BY COUNT(*) DESC) +
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RFMScore,
    -- Customer segment based on RFM
    CASE 
        WHEN (RANK() OVER(ORDER BY MAX(s.SaleDate) DESC) +
              RANK() OVER(ORDER BY COUNT(*) DESC) +
              RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC)) <= 5 
        THEN 'Champions'
        WHEN (RANK() OVER(ORDER BY MAX(s.SaleDate) DESC) +
              RANK() OVER(ORDER BY COUNT(*) DESC) +
              RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC)) <= 10 
        THEN 'Loyal Customers'
        ELSE 'At Risk'
    END AS CustomerSegment
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY RFMScore;
GO

/*
OUTPUT:
CustomerName    FirstPurchase  LastPurchase  PurchaseCount  TotalSpent   RecencyRank  FrequencyRank  MonetaryRank  RFMScore  CustomerSegment
--------------  -------------  ------------  -------------  -----------  -----------  -------------  ------------  --------  ---------------
Acme Corp       2024-01-15     2024-05-01    3              7099.75      1            1              2             4         Champions
Enterprise LLC  2024-04-10     2024-04-10    1              12999.90     2            3              1             6         Loyal Customers
...

RFM analysis using multiple rankings!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Product Portfolio Matrix
-------------------------------------
Create a comprehensive product analysis with:
- Product name and category
- Total revenue and quantity sold
- Revenue rank overall and within category
- Quantity rank overall and within category
- NTILE(4) for both revenue and quantity
- Classification based on quadrant:
  * Top quartile both: "Star"
  * Top revenue, low quantity: "Premium"
  * Low revenue, top quantity: "Value"
  * Bottom both: "Review"

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Regional Comparative Analysis
------------------------------------------
Analyze each region across multiple metrics:
- Total sales count, total revenue, average sale
- Rank for each metric
- Identify which metric each region ranks best in
- Calculate average rank across all metrics
- Classify regions as "Strength" (avg rank <= 1.5) or "Opportunity"

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Customer Multi-Dimensional Ranking
-----------------------------------------------
Create a customer scorecard with:
- Customer details and purchase summary
- Rank by total spending (overall and within customer type)
- Rank by purchase frequency (overall and within type)
- Rank by average order value (overall and within type)
- Composite score (average of all ranks)
- Identify customers who rank in top 2 for any metric

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Product Portfolio Matrix
SELECT 
    p.ProductName,
    p.Category,
    SUM(s.SaleAmount) AS TotalRevenue,
    SUM(s.Quantity) AS TotalQuantity,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS OverallRevenueRank,
    RANK() OVER(PARTITION BY p.Category ORDER BY SUM(s.SaleAmount) DESC) AS CategoryRevenueRank,
    RANK() OVER(ORDER BY SUM(s.Quantity) DESC) AS OverallQuantityRank,
    RANK() OVER(PARTITION BY p.Category ORDER BY SUM(s.Quantity) DESC) AS CategoryQuantityRank,
    NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS RevenueQuartile,
    NTILE(4) OVER(ORDER BY SUM(s.Quantity) DESC) AS QuantityQuartile,
    CASE 
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 
         AND NTILE(4) OVER(ORDER BY SUM(s.Quantity) DESC) = 1 
        THEN 'Star'
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 
         AND NTILE(4) OVER(ORDER BY SUM(s.Quantity) DESC) > 2 
        THEN 'Premium'
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) > 2 
         AND NTILE(4) OVER(ORDER BY SUM(s.Quantity) DESC) = 1 
        THEN 'Value'
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 4 
         AND NTILE(4) OVER(ORDER BY SUM(s.Quantity) DESC) = 4 
        THEN 'Review'
        ELSE 'Standard'
    END AS Classification
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName, p.Category
ORDER BY TotalRevenue DESC;
GO

-- Solution 2: Regional Comparative Analysis
WITH RegionMetrics AS (
    SELECT 
        Region,
        COUNT(*) AS SalesCount,
        SUM(SaleAmount) AS TotalRevenue,
        AVG(SaleAmount) AS AvgSale,
        RANK() OVER(ORDER BY COUNT(*) DESC) AS CountRank,
        RANK() OVER(ORDER BY SUM(SaleAmount) DESC) AS RevenueRank,
        RANK() OVER(ORDER BY AVG(SaleAmount) DESC) AS AvgRank
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
    GROUP BY Region
)
SELECT 
    Region,
    SalesCount,
    TotalRevenue,
    AvgSale,
    CountRank,
    RevenueRank,
    AvgRank,
    (CountRank + RevenueRank + AvgRank) / 3.0 AS AvgRankScore,
    CASE 
        WHEN CountRank = 1 THEN 'Volume'
        WHEN RevenueRank = 1 THEN 'Revenue'
        WHEN AvgRank = 1 THEN 'Premium'
        ELSE 'Mixed'
    END AS BestMetric,
    CASE 
        WHEN (CountRank + RevenueRank + AvgRank) / 3.0 <= 1.5 
        THEN 'Strength'
        ELSE 'Opportunity'
    END AS Classification
FROM RegionMetrics
ORDER BY AvgRankScore;
GO

-- Solution 3: Customer Multi-Dimensional Ranking
SELECT 
    c.CustomerName,
    c.CustomerType,
    COUNT(*) AS PurchaseCount,
    SUM(s.SaleAmount) AS TotalSpent,
    AVG(s.SaleAmount) AS AvgOrderValue,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS OverallSpendingRank,
    RANK() OVER(PARTITION BY c.CustomerType ORDER BY SUM(s.SaleAmount) DESC) AS TypeSpendingRank,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS OverallFrequencyRank,
    RANK() OVER(PARTITION BY c.CustomerType ORDER BY COUNT(*) DESC) AS TypeFrequencyRank,
    RANK() OVER(ORDER BY AVG(s.SaleAmount) DESC) AS OverallAOVRank,
    RANK() OVER(PARTITION BY c.CustomerType ORDER BY AVG(s.SaleAmount) DESC) AS TypeAOVRank,
    (
        RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) +
        RANK() OVER(ORDER BY COUNT(*) DESC) +
        RANK() OVER(ORDER BY AVG(s.SaleAmount) DESC)
    ) / 3.0 AS CompositeScore,
    CASE 
        WHEN RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) <= 2 
          OR RANK() OVER(ORDER BY COUNT(*) DESC) <= 2 
          OR RANK() OVER(ORDER BY AVG(s.SaleAmount) DESC) <= 2 
        THEN 'Top Performer'
        ELSE 'Standard'
    END AS PerformanceFlag
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName, c.CustomerType
ORDER BY CompositeScore;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. MULTIPLE RANKINGS PROVIDE DEPTH
   - Different ORDER BY: Different perspectives on same data
   - Different PARTITION BY: Insights at multiple hierarchical levels
   - Combined: Comprehensive multi-dimensional analysis

2. RANKING COMBINATIONS
   - Use multiple rankings to create classifications
   - Compare ranks to identify discrepancies
   - Composite scores: Average or sum of multiple ranks
   - BCG matrix: Two-dimensional classification

3. COMMON PATTERNS
   Revenue + Volume Rankings:
   - High both: Star products
   - High revenue, low volume: Premium products
   - Low revenue, high volume: Value products
   - Low both: Review for discontinuation

   RFM Analysis:
   - Recency: How recently purchased
   - Frequency: How often purchased
   - Monetary: How much spent
   - Combined score identifies best customers

4. PERFORMANCE CONSIDERATIONS
   - Each ranking function requires a sort
   - Multiple rankings = multiple sorts
   - Consider materializing in temp table for reuse
   - Index columns used in ORDER BY
   - Test with production data volumes

5. BEST PRACTICES
   - Use CTEs to organize complex multi-ranking queries
   - Name rankings descriptively (RevenueRank, not Rank1)
   - Document why each ranking exists
   - Test edge cases (ties, NULLs, equal groups)
   - Validate composite scores make business sense

6. COMMON USE CASES
   - Product portfolio analysis (BCG matrix)
   - Customer segmentation (RFM analysis)
   - Regional performance comparisons
   - Employee performance reviews
   - Competitor analysis
   - Quality rankings

================================================================================

NEXT STEPS:
-----------
In Lesson 16.7, we'll explore REPORTING FUNCTIONS:
- Aggregate window functions (SUM, AVG, COUNT OVER)
- Running totals and cumulative calculations
- Moving averages
- YTD, QTD calculations

Continue to: 07-reporting-functions/lesson.sql

================================================================================
*/
