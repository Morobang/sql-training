/*
================================================================================
LESSON 16.4: RANKING
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use ROW_NUMBER() to assign unique sequential numbers
2. Understand when to use ROW_NUMBER() vs other ranking functions
3. Implement pagination with ROW_NUMBER()
4. Handle duplicate values appropriately
5. Create Top-N queries efficiently
6. Use ranking for deduplication strategies

Business Context:
-----------------
ROW_NUMBER() is one of the most versatile window functions. It's essential
for pagination, assigning unique identifiers, removing duplicates, and creating
sequential numbering schemes. Understanding ROW_NUMBER() is the foundation for
mastering all ranking functions.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: ROW_NUMBER() BASICS
================================================================================

ROW_NUMBER() assigns a unique sequential integer to rows within a partition,
starting at 1. Unlike RANK() and DENSE_RANK(), ties receive different numbers.
*/

-- Use existing tables from previous lessons
-- Example 1: Simple ROW_NUMBER without partition
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(ORDER BY SaleAmount DESC) AS RowNum
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY RowNum;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RowNum
------  ----------  -----------  ------
10      2024-04-10  12999.90     1
5       2024-03-05  10399.92     2
1       2024-01-15  6499.95      3
8       2024-04-01  2799.96      4
3       2024-02-10  2099.97      5
6       2024-03-10  1599.96      6
7       2024-03-20  449.85       7
2       2024-01-20  299.90       8
9       2024-04-05  299.94       9
4       2024-02-15  179.98       10

Unique sequential numbers, even for ties!
*/

-- Example 2: ROW_NUMBER() with PARTITION BY
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS RegionRowNum
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, RegionRowNum;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionRowNum
-------  ----------  -----------  ------------
Central  2024-04-10  12999.90     1
Central  2024-04-01  2799.96      2
Central  2024-04-05  299.94       3
East     2024-03-05  10399.92     1
East     2024-01-15  6499.95      2
East     2024-03-10  1599.96      3
East     2024-01-20  299.90       4
West     2024-02-10  2099.97      1
West     2024-03-20  449.85       2
West     2024-02-15  179.98       3

Numbering restarts for each partition!
*/

-- Example 3: Multiple orderings for different numbering schemes
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(ORDER BY SaleAmount DESC) AS RankByAmount,
    ROW_NUMBER() OVER(ORDER BY SaleDate) AS RankByDate,
    ROW_NUMBER() OVER(ORDER BY SaleID) AS RankByID
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleID;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RankByAmount  RankByDate  RankByID
------  ----------  -----------  ------------  ----------  --------
1       2024-01-15  6499.95      3             1           1
2       2024-01-20  299.90       8             2           2
3       2024-02-10  2099.97      5             3           3
4       2024-02-15  179.98       10            4           4
5       2024-03-05  10399.92     2             5           5
6       2024-03-10  1599.96      6             6           6
7       2024-03-20  449.85       7             7           7
8       2024-04-01  2799.96      4             8           8
9       2024-04-05  299.94       9             9           9
10      2024-04-10  12999.90     1             10          10

Different numbering schemes in same query!
*/

/*
================================================================================
PART 2: HANDLING TIES
================================================================================

ROW_NUMBER() always assigns unique numbers, even when values are identical.
The order for ties depends on your ORDER BY clause and is non-deterministic
if not fully specified.
*/

-- Insert some duplicate sale amounts for demonstration
INSERT INTO Sales (CustomerID, ProductID, SaleDate, Quantity, SaleAmount, Region) VALUES
    (1, 3, '2024-05-01', 10, 299.90, 'East'),  -- Same amount as another East sale
    (2, 4, '2024-05-02', 2, 179.98, 'West');   -- Same amount as another West sale
GO

-- Example 1: Ties with incomplete ORDER BY (non-deterministic)
SELECT 
    SaleID,
    SaleAmount,
    ROW_NUMBER() OVER(ORDER BY SaleAmount DESC) AS RowNum
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleAmount DESC, SaleID;
GO

/*
OUTPUT:
SaleID  SaleAmount   RowNum
------  -----------  ------
10      12999.90     1
5       10399.92     2
1       6499.95      3
8       2799.96      4
3       2099.97      5
6       1599.96      6
7       449.85       7
2       299.90       8      -- Tie: 299.90
9       299.94       9      -- Tie: 299.94
13      299.90       10     -- Tie: 299.90 (same as row 8)
4       179.98       11     -- Tie: 179.98
14      179.98       12     -- Tie: 179.98 (same as row 11)

For ties, row number assignment may vary between runs!
*/

-- Example 2: Deterministic tie-breaking with additional ORDER BY columns
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        ORDER BY SaleAmount DESC, SaleDate, SaleID
    ) AS DeterministicRowNum
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY DeterministicRowNum;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   DeterministicRowNum
------  ----------  -----------  -------------------
10      2024-04-10  12999.90     1
5       2024-03-05  10399.92     2
1       2024-01-15  6499.95      3
8       2024-04-01  2799.96      4
3       2024-02-10  2099.97      5
6       2024-03-10  1599.96      6
7       2024-03-20  449.85       7
9       2024-04-05  299.94       8
2       2024-01-20  299.90       9      -- Earlier date wins
13      2024-05-01  299.90       10     -- Later date, lower SaleID
4       2024-02-15  179.98       11     -- Earlier date
14      2024-05-02  179.98       12     -- Later date

Fully deterministic ordering!
*/

/*
================================================================================
PART 3: PAGINATION
================================================================================

ROW_NUMBER() is perfect for pagination - dividing results into pages.
*/

-- Example 1: Basic pagination - Page 2 of results (rows 6-10)
DECLARE @PageSize INT = 5;
DECLARE @PageNumber INT = 2;

SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    RowNum,
    CONCAT('Page ', CEILING(CAST(RowNum AS FLOAT) / @PageSize)) AS PageNumber
FROM (
    SELECT 
        SaleID,
        SaleDate,
        SaleAmount,
        ROW_NUMBER() OVER(ORDER BY SaleDate) AS RowNum
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
) numbered
WHERE RowNum BETWEEN (@PageNumber - 1) * @PageSize + 1 
                 AND @PageNumber * @PageSize
ORDER BY RowNum;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RowNum  PageNumber
------  ----------  -----------  ------  ----------
5       2024-03-05  10399.92     6       Page 2
6       2024-03-10  1599.96      7       Page 2
7       2024-03-20  449.85       8       Page 2
8       2024-04-01  2799.96      9       Page 2
9       2024-04-05  299.94       10      Page 2

Page 2 of results (5 rows per page)!
*/

-- Example 2: Pagination with page metadata
DECLARE @PageSize INT = 3;
DECLARE @PageNumber INT = 2;

SELECT 
    *,
    CEILING(TotalRows / CAST(@PageSize AS FLOAT)) AS TotalPages,
    @PageNumber AS CurrentPage
FROM (
    SELECT 
        SaleID,
        SaleDate,
        SaleAmount,
        Region,
        ROW_NUMBER() OVER(ORDER BY SaleDate) AS RowNum,
        COUNT(*) OVER() AS TotalRows
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
) numbered
WHERE RowNum BETWEEN (@PageNumber - 1) * @PageSize + 1 
                 AND @PageNumber * @PageSize
ORDER BY RowNum;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount  Region  RowNum  TotalRows  TotalPages  CurrentPage
------  ----------  ----------  ------  ------  ---------  ----------  -----------
4       2024-02-15  179.98      West    4       12         4           2
5       2024-03-05  10399.92    East    5       12         4           2
6       2024-03-10  1599.96     East    6       12         4           2

Page 2 of 4 (3 rows per page)!
*/

/*
================================================================================
PART 4: TOP-N QUERIES
================================================================================

ROW_NUMBER() excels at Top-N queries, especially Top-N per group.
*/

-- Example 1: Top 3 sales overall
SELECT TOP 3
    SaleID,
    SaleDate,
    SaleAmount
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleAmount DESC;
GO

-- Example 2: Top 2 sales per region using ROW_NUMBER()
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    RegionRank
FROM (
    SELECT 
        Region,
        SaleDate,
        SaleAmount,
        ROW_NUMBER() OVER(
            PARTITION BY Region 
            ORDER BY SaleAmount DESC
        ) AS RegionRank
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
) ranked
WHERE RegionRank <= 2
ORDER BY Region, RegionRank;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionRank
-------  ----------  -----------  ----------
Central  2024-04-10  12999.90     1
Central  2024-04-01  2799.96      2
East     2024-03-05  10399.92     1
East     2024-01-15  6499.95      2
West     2024-02-10  2099.97      1
West     2024-03-20  449.85       2

Top 2 sales per region!
*/

-- Example 3: Top 2 products per category
SELECT 
    Category,
    ProductName,
    TotalSales,
    CategoryRank
FROM (
    SELECT 
        p.Category,
        p.ProductName,
        SUM(s.SaleAmount) AS TotalSales,
        ROW_NUMBER() OVER(
            PARTITION BY p.Category 
            ORDER BY SUM(s.SaleAmount) DESC
        ) AS CategoryRank
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.Region IS NOT NULL
    GROUP BY p.Category, p.ProductName
) ranked
WHERE CategoryRank <= 2
ORDER BY Category, CategoryRank;
GO

/*
OUTPUT:
Category      ProductName       TotalSales   CategoryRank
------------  ----------------  -----------  ------------
Accessories   Mouse Wireless    749.75       1
Accessories   USB Hub           299.94       2
Electronics   Laptop Pro        29899.77     1
Electronics   Laptop Basic      4899.93      2

Top 2 products per category!
*/

/*
================================================================================
PART 5: DEDUPLICATION
================================================================================

ROW_NUMBER() is excellent for identifying and removing duplicates.
*/

-- Create a table with duplicates for demonstration
DROP TABLE IF EXISTS SalesDuplicates;
GO

SELECT 
    CustomerID,
    ProductID,
    SaleDate,
    Quantity,
    SaleAmount,
    Region
INTO SalesDuplicates
FROM Sales
WHERE SaleID IN (1, 2, 3);

-- Insert duplicates
INSERT INTO SalesDuplicates
SELECT CustomerID, ProductID, SaleDate, Quantity, SaleAmount, Region
FROM SalesDuplicates;
GO

-- Example 1: Identify duplicates
SELECT 
    *,
    ROW_NUMBER() OVER(
        PARTITION BY CustomerID, ProductID, SaleDate, SaleAmount 
        ORDER BY (SELECT NULL)
    ) AS DuplicateNum
FROM SalesDuplicates
ORDER BY CustomerID, ProductID, SaleDate, DuplicateNum;
GO

/*
OUTPUT:
CustomerID  ProductID  SaleDate    Quantity  SaleAmount  Region  DuplicateNum
----------  ---------  ----------  --------  ----------  ------  ------------
1           1          2024-01-15  5         6499.95     East    1
1           1          2024-01-15  5         6499.95     East    2
1           3          2024-01-20  10        299.90      East    1
1           3          2024-01-20  10        299.90      East    2
2           2          2024-02-10  3         2099.97     West    1
2           2          2024-02-10  3         2099.97     West    2

DuplicateNum shows which copies!
*/

-- Example 2: Keep only first occurrence (delete duplicates)
WITH DuplicateCTE AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY CustomerID, ProductID, SaleDate, SaleAmount 
            ORDER BY (SELECT NULL)
        ) AS RowNum
    FROM SalesDuplicates
)
SELECT * FROM DuplicateCTE WHERE RowNum = 1;
-- To actually delete: DELETE FROM DuplicateCTE WHERE RowNum > 1;
GO

/*
================================================================================
PART 6: PRACTICAL APPLICATIONS
================================================================================
*/

-- Application 1: Sequential customer purchase numbering
SELECT 
    c.CustomerName,
    s.SaleDate,
    p.ProductName,
    s.SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate, s.SaleID
    ) AS PurchaseSequence,
    COUNT(*) OVER(PARTITION BY c.CustomerID) AS TotalPurchases
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, PurchaseSequence;
GO

/*
OUTPUT:
CustomerName    SaleDate    ProductName      SaleAmount   PurchaseSequence  TotalPurchases
--------------  ----------  ---------------  -----------  ----------------  --------------
Acme Corp       2024-01-15  Laptop Pro       6499.95      1                 3
Acme Corp       2024-01-20  Mouse Wireless   299.90       2                 3
Acme Corp       2024-05-01  Mouse Wireless   299.90       3                 3
Enterprise LLC  2024-04-10  Laptop Pro       12999.90     1                 1
...

Purchase sequence for each customer!
*/

-- Application 2: First and last purchase per customer
SELECT 
    CustomerName,
    FirstPurchaseDate,
    FirstProduct,
    FirstAmount,
    LastPurchaseDate,
    LastProduct,
    LastAmount,
    TotalPurchases
FROM (
    SELECT 
        c.CustomerName,
        s.SaleDate,
        p.ProductName,
        s.SaleAmount,
        ROW_NUMBER() OVER(
            PARTITION BY c.CustomerID 
            ORDER BY s.SaleDate, s.SaleID
        ) AS PurchaseNum,
        ROW_NUMBER() OVER(
            PARTITION BY c.CustomerID 
            ORDER BY s.SaleDate DESC, s.SaleID DESC
        ) AS ReversePurchaseNum,
        COUNT(*) OVER(PARTITION BY c.CustomerID) AS TotalPurchases
    FROM Sales s
    INNER JOIN Customers c ON s.CustomerID = c.CustomerID
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.SaleDate IS NOT NULL
) purchases
PIVOT (
    MAX(SaleDate) FOR PurchaseNum IN ([1])
) pvt1
PIVOT (
    MAX(ProductName) FOR PurchaseNum IN ([1])
) pvt2
PIVOT (
    MAX(SaleAmount) FOR PurchaseNum IN ([1])
) pvt3
WHERE PurchaseNum = 1 OR ReversePurchaseNum = 1;
-- Note: Simplified - full implementation would use different approach
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Customer Ranking
-----------------------------
Create a query that shows:
- Customer name and total sales
- Overall rank by sales
- Rank within customer type
- Sequential customer number (by first purchase date)
- Include only customers with purchases

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Product Inventory Report
-------------------------------------
For each product, show:
- Product details
- Total quantity sold
- Rank by quantity (overall)
- Rank by quantity (within category)
- Row number for pagination (10 per page)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Regional Sales Timeline
------------------------------------
Create a paginated report showing:
- Sales details with region
- Sequential sale number within region
- Days since previous sale in region
- Page number (5 sales per page per region)
- Filter for page 1 only

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Customer Ranking
SELECT 
    c.CustomerName,
    c.CustomerType,
    SUM(s.SaleAmount) AS TotalSales,
    ROW_NUMBER() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS OverallRank,
    ROW_NUMBER() OVER(
        PARTITION BY c.CustomerType 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS TypeRank,
    ROW_NUMBER() OVER(
        ORDER BY MIN(s.SaleDate)
    ) AS CustomerSequence
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.SaleDate IS NOT NULL
GROUP BY c.CustomerName, c.CustomerType
ORDER BY OverallRank;
GO

-- Solution 2: Product Inventory Report
SELECT 
    p.ProductName,
    p.Category,
    p.UnitPrice,
    SUM(s.Quantity) AS TotalQuantitySold,
    ROW_NUMBER() OVER(ORDER BY SUM(s.Quantity) DESC) AS OverallRank,
    ROW_NUMBER() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.Quantity) DESC
    ) AS CategoryRank,
    ROW_NUMBER() OVER(ORDER BY p.ProductID) AS PageRowNum,
    CEILING(ROW_NUMBER() OVER(ORDER BY p.ProductID) / 10.0) AS PageNumber
FROM Products p
INNER JOIN Sales s ON p.ProductID = s.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.ProductID, p.ProductName, p.Category, p.UnitPrice
ORDER BY PageRowNum;
GO

-- Solution 3: Regional Sales Timeline
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    SaleNum,
    DaysSincePrevious,
    PageNum
FROM (
    SELECT 
        Region,
        SaleDate,
        SaleAmount,
        ROW_NUMBER() OVER(
            PARTITION BY Region 
            ORDER BY SaleDate
        ) AS SaleNum,
        DATEDIFF(DAY,
            LAG(SaleDate) OVER(PARTITION BY Region ORDER BY SaleDate),
            SaleDate
        ) AS DaysSincePrevious,
        CEILING(ROW_NUMBER() OVER(
            PARTITION BY Region 
            ORDER BY SaleDate
        ) / 5.0) AS PageNum
    FROM Sales
    WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
) timeline
WHERE PageNum = 1
ORDER BY Region, SaleNum;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. ROW_NUMBER() FUNDAMENTALS
   - Assigns unique sequential integers
   - Starts at 1 within each partition
   - Always unique, even for ties
   - Requires ORDER BY clause

2. TIE HANDLING
   - Ties get different numbers
   - Order is non-deterministic without full ORDER BY
   - Always include tie-breaker columns for deterministic results
   - Use SaleID or other unique column as final tie-breaker

3. PAGINATION
   - Perfect for dividing results into pages
   - Calculate page boundaries with simple math
   - Include total count for metadata
   - Efficient for web applications

4. TOP-N QUERIES
   - Excellent for Top-N per group
   - Filter WHERE RowNum <= N
   - More flexible than TOP clause
   - Partition for group-wise Top-N

5. DEDUPLICATION
   - Identify duplicates with PARTITION BY all columns
   - Keep first (RowNum = 1) or last occurrence
   - Use CTE for DELETE operations
   - Consider what defines a duplicate

6. BEST PRACTICES
   - Always use deterministic ORDER BY for consistency
   - Include unique column as final sort
   - Use meaningful partition columns
   - Test with duplicate data
   - Consider performance on large datasets

================================================================================

NEXT STEPS:
-----------
In Lesson 16.5, we'll explore other RANKING FUNCTIONS:
- RANK() - Ranking with gaps
- DENSE_RANK() - Continuous ranking
- NTILE() - Bucketing data
- Comparing all ranking functions

Continue to: 05-ranking-functions/lesson.sql

================================================================================
*/
