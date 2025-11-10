/*
================================================================================
LESSON 16.5: RANKING FUNCTIONS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use RANK() to assign rankings with gaps
2. Apply DENSE_RANK() for continuous rankings
3. Use NTILE() to divide data into buckets
4. Compare all ranking functions
5. Choose the appropriate function for each scenario
6. Calculate percentiles and quartiles

Business Context:
-----------------
Different ranking functions serve different purposes. RANK() is great for
competition-style rankings (like sports), DENSE_RANK() for categories without
gaps, and NTILE() for dividing data into equal groups. Understanding when to
use each function is crucial for accurate analysis.

Database: RetailStore
Complexity: Intermediate to Advanced
Estimated Time: 60 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: RANK() - RANKING WITH GAPS
================================================================================

RANK() assigns rankings with gaps when there are ties. If two rows tie for
rank 2, the next rank is 4 (not 3).
*/

-- Example 1: Simple RANK()
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    RANK() OVER(ORDER BY SaleAmount DESC) AS SalesRank
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SalesRank;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   SalesRank
------  ----------  -----------  ---------
10      2024-04-10  12999.90     1
5       2024-03-05  10399.92     2
1       2024-01-15  6499.95      3
8       2024-04-01  2799.96      4
3       2024-02-10  2099.97      5
6       2024-03-10  1599.96      6
7       2024-03-20  449.85       7
9       2024-04-05  299.94       8
2       2024-01-20  299.90       9
13      2024-05-01  299.90       9      -- Tie: Same rank
4       2024-02-15  179.98       11     -- Gap: Skipped rank 10
14      2024-05-02  179.98       11     -- Tie: Same rank

Notice the gap from rank 9 to 11!
*/

-- Example 2: RANK() within partitions
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    RANK() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS RegionRank
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, RegionRank;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionRank
-------  ----------  -----------  ----------
Central  2024-04-10  12999.90     1
Central  2024-04-01  2799.96      2
Central  2024-04-05  299.94       3
East     2024-03-05  10399.92     1
East     2024-01-15  6499.95      2
East     2024-03-10  1599.96      3
East     2024-01-20  299.90       4
East     2024-05-01  299.90       4          -- Tie
West     2024-02-10  2099.97      1
West     2024-03-20  449.85       2
West     2024-02-15  179.98       3
West     2024-05-02  179.98       3          -- Tie

Ties get same rank, gaps appear after!
*/

-- Example 3: RANK() with multiple products per customer
SELECT 
    c.CustomerName,
    p.ProductName,
    s.SaleAmount,
    RANK() OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleAmount DESC
    ) AS ProductRank
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
ORDER BY c.CustomerName, ProductRank;
GO

/*
OUTPUT:
CustomerName    ProductName       SaleAmount   ProductRank
--------------  ----------------  -----------  -----------
Acme Corp       Laptop Pro        6499.95      1
Acme Corp       Mouse Wireless    299.90       2
Acme Corp       Mouse Wireless    299.90       2      -- Tie
Enterprise LLC  Laptop Pro        12999.90     1
...

Products ranked within each customer!
*/

/*
================================================================================
PART 2: DENSE_RANK() - CONTINUOUS RANKING
================================================================================

DENSE_RANK() assigns rankings without gaps. If two rows tie for rank 2,
the next rank is 3 (not 4).
*/

-- Example 1: DENSE_RANK() vs RANK()
SELECT 
    SaleID,
    SaleAmount,
    RANK() OVER(ORDER BY SaleAmount DESC) AS RankWithGaps,
    DENSE_RANK() OVER(ORDER BY SaleAmount DESC) AS DenseRank
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY DenseRank;
GO

/*
OUTPUT:
SaleID  SaleAmount   RankWithGaps  DenseRank
------  -----------  ------------  ---------
10      12999.90     1             1
5       10399.92     2             2
1       6499.95      3             3
8       2799.96      4             4
3       2099.97      5             5
6       1599.96      6             6
7       449.85       7             7
9       299.94       8             8
2       299.90       9             9
13      299.90       9             9          -- Tie
4       179.98       11            10         -- No gap in DENSE_RANK
14      179.98       11            10         -- No gap in DENSE_RANK

DENSE_RANK has no gaps!
*/

-- Example 2: DENSE_RANK() for category levels
SELECT 
    p.ProductName,
    p.Category,
    SUM(s.SaleAmount) AS TotalSales,
    DENSE_RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SalesLevel
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName, p.Category
ORDER BY SalesLevel;
GO

/*
OUTPUT:
ProductName       Category      TotalSales   SalesLevel
----------------  ------------  -----------  ----------
Laptop Pro        Electronics   29899.77     1
Laptop Basic      Electronics   4899.93      2
Monitor 4K        Electronics   2099.97      3
Mouse Wireless    Accessories   1049.65      4
Keyboard Mech     Accessories   449.85       5
USB Hub           Accessories   299.94       6
Webcam HD         Electronics   179.98       7

Continuous levels 1-7 without gaps!
*/

/*
================================================================================
PART 3: NTILE() - BUCKETING DATA
================================================================================

NTILE(n) divides rows into n approximately equal groups. Perfect for
quartiles, deciles, percentiles.
*/

-- Example 1: Quartiles (4 groups)
SELECT 
    SaleID,
    SaleAmount,
    NTILE(4) OVER(ORDER BY SaleAmount DESC) AS Quartile
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Quartile, SaleAmount DESC;
GO

/*
OUTPUT:
SaleID  SaleAmount   Quartile
------  -----------  --------
10      12999.90     1        -- Top 25%
5       10399.92     1
1       6499.95      1
8       2799.96      2        -- Second 25%
3       2099.97      2
6       1599.96      2
7       449.85       3        -- Third 25%
9       299.94       3
2       299.90       3
13      299.90       4        -- Bottom 25%
4       179.98       4
14      179.98       4

Data divided into 4 equal groups!
*/

-- Example 2: Deciles (10 groups) for more granular distribution
SELECT 
    SaleID,
    SaleAmount,
    NTILE(10) OVER(ORDER BY SaleAmount DESC) AS Decile,
    CASE 
        WHEN NTILE(10) OVER(ORDER BY SaleAmount DESC) = 1 THEN 'Top 10%'
        WHEN NTILE(10) OVER(ORDER BY SaleAmount DESC) <= 3 THEN 'Top 30%'
        WHEN NTILE(10) OVER(ORDER BY SaleAmount DESC) <= 5 THEN 'Above Average'
        WHEN NTILE(10) OVER(ORDER BY SaleAmount DESC) <= 7 THEN 'Below Average'
        ELSE 'Bottom 30%'
    END AS PerformanceBand
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Decile;
GO

/*
OUTPUT:
SaleID  SaleAmount   Decile  PerformanceBand
------  -----------  ------  ----------------
10      12999.90     1       Top 10%
5       10399.92     2       Top 30%
1       6499.95      3       Top 30%
8       2799.96      4       Above Average
3       2099.97      5       Above Average
6       1599.96      6       Below Average
7       449.85       7       Below Average
9       299.94       8       Bottom 30%
2       299.90       9       Bottom 30%
13      299.90       10      Bottom 30%

Performance bands created from deciles!
*/

-- Example 3: NTILE() within partitions (region quartiles)
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    NTILE(4) OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS RegionQuartile
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, RegionQuartile;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionQuartile
-------  ----------  -----------  --------------
Central  2024-04-10  12999.90     1
Central  2024-04-01  2799.96      2
Central  2024-04-05  299.94       3
East     2024-03-05  10399.92     1
East     2024-01-15  6499.95      2
East     2024-03-10  1599.96      3
East     2024-01-20  299.90       4
East     2024-05-01  299.90       4
West     2024-02-10  2099.97      1
West     2024-03-20  449.85       2
West     2024-02-15  179.98       3
West     2024-05-02  179.98       4

Quartiles calculated per region!
*/

/*
================================================================================
PART 4: COMPARING ALL RANKING FUNCTIONS
================================================================================

Let's see ROW_NUMBER(), RANK(), DENSE_RANK(), and NTILE() side by side.
*/

-- Example 1: All four functions together
SELECT 
    SaleID,
    SaleAmount,
    ROW_NUMBER() OVER(ORDER BY SaleAmount DESC) AS RowNum,
    RANK() OVER(ORDER BY SaleAmount DESC) AS RankNum,
    DENSE_RANK() OVER(ORDER BY SaleAmount DESC) AS DenseRankNum,
    NTILE(4) OVER(ORDER BY SaleAmount DESC) AS QuartileNum
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleAmount DESC;
GO

/*
OUTPUT:
SaleID  SaleAmount   RowNum  RankNum  DenseRankNum  QuartileNum
------  -----------  ------  -------  ------------  -----------
10      12999.90     1       1        1             1
5       10399.92     2       2        2             1
1       6499.95      3       3        3             1
8       2799.96      4       4        4             2
3       2099.97      5       5        5             2
6       1599.96      6       6        6             2
7       449.85       7       7        7             3
9       299.94       8       8        8             3
2       299.90       9       9        9             3
13      299.90       10      9        9             4      -- Note ties
4       179.98       11      11       10            4
14      179.98       12      11       10            4

Key Differences:
- RowNum: Always unique (9, 10, 11, 12)
- RankNum: Ties get same rank, gaps appear (9, 9, 11, 11)
- DenseRankNum: Ties get same rank, no gaps (9, 9, 10, 10)
- QuartileNum: Divides into groups (3, 4, 4, 4)
*/

-- Example 2: All functions within partitions
SELECT 
    Region,
    SaleAmount,
    ROW_NUMBER() OVER(PARTITION BY Region ORDER BY SaleAmount DESC) AS RowNum,
    RANK() OVER(PARTITION BY Region ORDER BY SaleAmount DESC) AS RankNum,
    DENSE_RANK() OVER(PARTITION BY Region ORDER BY SaleAmount DESC) AS DenseRankNum,
    NTILE(2) OVER(PARTITION BY Region ORDER BY SaleAmount DESC) AS Half
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleAmount DESC;
GO

/*
OUTPUT:
Region   SaleAmount   RowNum  RankNum  DenseRankNum  Half
-------  -----------  ------  -------  ------------  ----
Central  12999.90     1       1        1             1
Central  2799.96      2       2        2             2
Central  299.94       3       3        3             2
East     10399.92     1       1        1             1
East     6499.95      2       2        2             1
East     1599.96      3       3        3             2
East     299.90       4       4        4             2
East     299.90       5       4        4             2      -- Tie handling
West     2099.97      1       1        1             1
West     449.85       2       2        2             1
West     179.98       3       3        3             2
West     179.98       4       3        3             2      -- Tie handling

All functions restart per partition!
*/

/*
================================================================================
PART 5: PERCENTILES AND ADVANCED BUCKETING
================================================================================
*/

-- Example 1: Calculate percentile ranks
SELECT 
    p.ProductName,
    SUM(s.SaleAmount) AS TotalSales,
    PERCENT_RANK() OVER(ORDER BY SUM(s.SaleAmount)) AS PercentRank,
    CUME_DIST() OVER(ORDER BY SUM(s.SaleAmount)) AS CumulativeDistribution
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName
ORDER BY TotalSales DESC;
GO

/*
OUTPUT:
ProductName       TotalSales   PercentRank  CumulativeDistribution
----------------  -----------  -----------  ----------------------
Laptop Pro        29899.77     1.0          1.0
Laptop Basic      4899.93      0.833        0.857
Monitor 4K        2099.97      0.667        0.714
Mouse Wireless    1049.65      0.5          0.571
Keyboard Mech     449.85       0.333        0.428
USB Hub           299.94       0.167        0.285
Webcam HD         179.98       0.0          0.142

PERCENT_RANK: (rank - 1) / (total rows - 1)
CUME_DIST: rows <= current / total rows
*/

-- Example 2: Custom percentile buckets
SELECT 
    SaleID,
    SaleAmount,
    NTILE(100) OVER(ORDER BY SaleAmount DESC) AS Percentile,
    CASE 
        WHEN NTILE(100) OVER(ORDER BY SaleAmount DESC) <= 10 THEN 'Top 10%'
        WHEN NTILE(100) OVER(ORDER BY SaleAmount DESC) <= 25 THEN 'Top 25%'
        WHEN NTILE(100) OVER(ORDER BY SaleAmount DESC) <= 50 THEN 'Top 50%'
        WHEN NTILE(100) OVER(ORDER BY SaleAmount DESC) <= 75 THEN 'Top 75%'
        ELSE 'Bottom 25%'
    END AS PercentileBucket
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Percentile;
GO

/*
================================================================================
PART 6: PRACTICAL APPLICATIONS
================================================================================
*/

-- Application 1: Product Performance Classification
SELECT 
    p.ProductName,
    p.Category,
    SUM(s.SaleAmount) AS TotalSales,
    SUM(s.Quantity) AS TotalQuantity,
    DENSE_RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SalesRank,
    NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS PerformanceTier,
    CASE 
        WHEN NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 THEN 'Star Product'
        WHEN NTILE(3) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 2 THEN 'Standard Product'
        ELSE 'Underperformer'
    END AS Classification
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName, p.Category
ORDER BY TotalSales DESC;
GO

-- Application 2: Customer Segmentation by Spending
SELECT 
    c.CustomerName,
    c.CustomerType,
    SUM(s.SaleAmount) AS TotalSpending,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SpendingRank,
    NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SpendingQuartile,
    CASE 
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 THEN 'VIP'
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 2 THEN 'High Value'
        WHEN NTILE(4) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 3 THEN 'Medium Value'
        ELSE 'Standard'
    END AS CustomerSegment
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerName, c.CustomerType
ORDER BY TotalSpending DESC;
GO

-- Application 3: Regional Performance Ranking
SELECT 
    Region,
    COUNT(*) AS TotalSales,
    SUM(SaleAmount) AS TotalRevenue,
    AVG(SaleAmount) AS AvgSaleAmount,
    RANK() OVER(ORDER BY SUM(SaleAmount) DESC) AS RevenueRank,
    RANK() OVER(ORDER BY COUNT(*) DESC) AS VolumeRank,
    RANK() OVER(ORDER BY AVG(SaleAmount) DESC) AS AvgTicketRank
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
GROUP BY Region
ORDER BY RevenueRank;
GO

/*
OUTPUT:
Region   TotalSales  TotalRevenue  AvgSaleAmount  RevenueRank  VolumeRank  AvgTicketRank
-------  ----------  ------------  -------------  -----------  ----------  -------------
Central  3           16099.80      5366.60        1            2           1
East     5           18799.68      3759.94        2            1           2
West     4           2909.78       727.45         3            2           3

Central: Best revenue & average, but fewer sales
East: Most sales, good revenue
West: Lower performance across all metrics
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Sales Performance Analysis
---------------------------------------
Create a comprehensive ranking report showing:
- Sale details (ID, Date, Amount, Region)
- Overall sales rank (RANK)
- Dense rank within region
- Quartile within region (NTILE)
- Row number for pagination (ordered by date)
- Label top 3 sales per region as "Top Performer"

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Product Portfolio Analysis
---------------------------------------
For each product, calculate:
- Total sales amount
- Total quantity sold
- Rank by sales amount (with gaps)
- Dense rank by quantity (no gaps)
- Decile by sales amount
- Classification based on decile:
  * Decile 1-2: "Premium"
  * Decile 3-5: "Standard"
  * Decile 6-10: "Budget"

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Customer Value Segmentation
----------------------------------------
Segment customers using all ranking functions:
- Customer name and total purchases
- ROW_NUMBER for unique customer ID
- RANK by total spending
- DENSE_RANK by number of purchases
- NTILE(5) for quintile segmentation
- PERCENT_RANK for percentile position
- Assign segment labels based on quintile

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Sales Performance Analysis
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    Region,
    RANK() OVER(ORDER BY SaleAmount DESC) AS OverallRank,
    DENSE_RANK() OVER(PARTITION BY Region ORDER BY SaleAmount DESC) AS RegionDenseRank,
    NTILE(4) OVER(PARTITION BY Region ORDER BY SaleAmount DESC) AS RegionQuartile,
    ROW_NUMBER() OVER(ORDER BY SaleDate) AS PageRowNum,
    CASE 
        WHEN DENSE_RANK() OVER(PARTITION BY Region ORDER BY SaleAmount DESC) <= 3 
        THEN 'Top Performer'
        ELSE 'Standard'
    END AS PerformanceLabel
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, RegionDenseRank;
GO

-- Solution 2: Product Portfolio Analysis
SELECT 
    p.ProductName,
    p.Category,
    SUM(s.SaleAmount) AS TotalSales,
    SUM(s.Quantity) AS TotalQuantity,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SalesRank,
    DENSE_RANK() OVER(ORDER BY SUM(s.Quantity) DESC) AS QuantityDenseRank,
    NTILE(10) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SalesDecile,
    CASE 
        WHEN NTILE(10) OVER(ORDER BY SUM(s.SaleAmount) DESC) <= 2 THEN 'Premium'
        WHEN NTILE(10) OVER(ORDER BY SUM(s.SaleAmount) DESC) <= 5 THEN 'Standard'
        ELSE 'Budget'
    END AS Classification
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductName, p.Category
ORDER BY TotalSales DESC;
GO

-- Solution 3: Customer Value Segmentation
SELECT 
    c.CustomerName,
    COUNT(*) AS TotalPurchases,
    SUM(s.SaleAmount) AS TotalSpending,
    ROW_NUMBER() OVER(ORDER BY c.CustomerID) AS UniqueCustomerID,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SpendingRank,
    DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS PurchaseDenseRank,
    NTILE(5) OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SpendingQuintile,
    PERCENT_RANK() OVER(ORDER BY SUM(s.SaleAmount)) AS PercentilePosition,
    CASE 
        WHEN NTILE(5) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 1 THEN 'Diamond'
        WHEN NTILE(5) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 2 THEN 'Platinum'
        WHEN NTILE(5) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 3 THEN 'Gold'
        WHEN NTILE(5) OVER(ORDER BY SUM(s.SaleAmount) DESC) = 4 THEN 'Silver'
        ELSE 'Bronze'
    END AS CustomerSegment
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpending DESC;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. CHOOSING THE RIGHT FUNCTION

   ROW_NUMBER():
   - Unique sequential numbers
   - Use for: Pagination, deduplication, unique IDs
   - Ties: Get different numbers (non-deterministic without full ORDER BY)

   RANK():
   - Ranking with gaps
   - Use for: Competition-style rankings, showing "true" position
   - Ties: Get same rank, next rank skips
   - Example: 1, 2, 2, 4, 5

   DENSE_RANK():
   - Ranking without gaps
   - Use for: Continuous levels, categories
   - Ties: Get same rank, next rank continuous
   - Example: 1, 2, 2, 3, 4

   NTILE(n):
   - Divide into n buckets
   - Use for: Quartiles, percentiles, segmentation
   - Creates approximately equal groups
   - Example: NTILE(4) creates quartiles

2. TIE HANDLING
   - ROW_NUMBER: Ties broken by ORDER BY (or arbitrary)
   - RANK: Ties get same rank, gaps follow
   - DENSE_RANK: Ties get same rank, no gaps
   - NTILE: Distributes ties across buckets

3. COMMON USE CASES
   - Top-N per group: All functions work
   - Pagination: ROW_NUMBER() only
   - Competition rankings: RANK()
   - Category levels: DENSE_RANK()
   - Segmentation: NTILE()
   - Deduplication: ROW_NUMBER()

4. PERCENTILE FUNCTIONS
   - PERCENT_RANK(): (rank - 1) / (total - 1)
   - CUME_DIST(): rows <= current / total
   - NTILE(100): Approximate percentiles

5. BEST PRACTICES
   - Choose function based on tie behavior needed
   - Use PARTITION BY for group-wise rankings
   - Include full ORDER BY for deterministic results
   - Test with data containing ties
   - Consider performance on large datasets
   - Document why you chose each function

6. PERFORMANCE TIPS
   - Ranking functions can be expensive
   - Use WHERE before ranking when possible
   - Consider indexed columns in ORDER BY
   - Limit partitions to necessary columns
   - Test with production-sized data

================================================================================

NEXT STEPS:
-----------
In Lesson 16.6, we'll explore MULTIPLE RANKINGS:
- Using multiple ranking functions together
- Different partitions and orderings
- Complex analytical scenarios
- Combining rankings for advanced insights

Continue to: 06-multiple-rankings/lesson.sql

================================================================================
*/
