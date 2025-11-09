/*
================================================================================
LESSON 16.3: LOCALIZED SORTING
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Sort data within partitions using ORDER BY
2. Use multiple sort columns within windows
3. Control sort direction (ASC/DESC) per column
4. Handle NULL values in sorted windows
5. Combine global and local sorting
6. Understand sort order impact on results

Business Context:
-----------------
Localized sorting allows you to order data within logical groups without
collapsing rows. This is essential for finding top performers per category,
chronological ordering within customers, and ranked lists per region.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: BASIC SORTING WITHIN PARTITIONS
================================================================================

ORDER BY within OVER() clause sorts rows within each partition independently.
*/

-- Use existing Sales, Products, Customers tables from Lesson 2
-- Example 1: Number rows within each region chronologically
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS SaleSequence,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate DESC
    ) AS ReverseSaleSequence
FROM Sales
WHERE Region IS NOT NULL
ORDER BY Region, SaleDate;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   SaleSequence  ReverseSaleSequence
-------  ----------  -----------  ------------  -------------------
Central  2024-04-01  2799.96      1             3
Central  2024-04-05  299.94       2             2
Central  2024-04-10  12999.90     3             1
East     2024-01-15  6499.95      1             4
East     2024-01-20  299.90       2             3
East     2024-03-05  10399.92     3             2
East     2024-03-10  1599.96      4             1
...

Each region numbered independently!
*/

-- Example 2: Rank products by sales within category
SELECT 
    p.Category,
    p.ProductName,
    SUM(s.SaleAmount) AS TotalSales,
    RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS CategoryRank
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.Category, p.ProductName
ORDER BY p.Category, CategoryRank;
GO

/*
OUTPUT:
Category      ProductName       TotalSales   CategoryRank
------------  ----------------  -----------  ------------
Accessories   Mouse Wireless    749.75       1
Accessories   Keyboard Mech     179.98       2
Accessories   USB Hub           299.94       3
Electronics   Laptop Pro        29899.77     1
Electronics   Monitor 27"       1599.96      2
Electronics   Laptop Basic      4899.93      3

Ranked within each category!
*/

/*
================================================================================
PART 2: MULTIPLE SORT COLUMNS
================================================================================

Use multiple columns in ORDER BY for tie-breaking and complex ordering.
*/

-- Example 1: Sort by amount, then by date for ties
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC, SaleDate
    ) AS RankByAmountThenDate
FROM Sales
WHERE Region IS NOT NULL
ORDER BY Region, RankByAmountThenDate;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RankByAmountThenDate
-------  ----------  -----------  --------------------
Central  2024-04-10  12999.90     1
Central  2024-04-01  2799.96      2
Central  2024-04-05  299.94       3
East     2024-03-05  10399.92     1
East     2024-01-15  6499.95      2
East     2024-03-10  1599.96      3
East     2024-01-20  299.90       4
...

Primary sort by amount, secondary by date!
*/

-- Example 2: Complex multi-column sorting
SELECT 
    c.CustomerType,
    s.Region,
    c.CustomerName,
    s.SaleDate,
    s.SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY c.CustomerType 
        ORDER BY s.Region, s.SaleDate DESC, s.SaleAmount DESC
    ) AS ComplexRank
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
ORDER BY c.CustomerType, ComplexRank;
GO

/*
OUTPUT:
CustomerType  Region   CustomerName    SaleDate    SaleAmount   ComplexRank
------------  -------  --------------  ----------  -----------  -----------
Enterprise    Central  Enterprise LLC  2024-04-10  12999.90     1
Enterprise    East     Global Inc      2024-03-10  1599.96      2
Enterprise    East     Global Inc      2024-03-05  10399.92     3
Enterprise    East     Acme Corp       2024-01-20  299.90       4
Enterprise    East     Acme Corp       2024-01-15  6499.95      5
...

Sorted by Region, then Date DESC, then Amount DESC within CustomerType!
*/

/*
================================================================================
PART 3: ASCENDING VS DESCENDING SORT
================================================================================

Control sort direction per column for precise ordering.
*/

-- Example 1: Mix ASC and DESC in same ORDER BY
SELECT 
    p.Category,
    p.ProductName,
    s.SaleDate,
    s.SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY p.Category 
        ORDER BY s.SaleDate ASC, s.SaleAmount DESC
    ) AS MixedSortRank
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
ORDER BY p.Category, MixedSortRank;
GO

/*
OUTPUT:
Category      ProductName       SaleDate    SaleAmount   MixedSortRank
------------  ----------------  ----------  -----------  -------------
Accessories   Mouse Wireless    2024-01-20  299.90       1
Accessories   Keyboard Mech     2024-02-15  179.98       2
Accessories   Mouse Wireless    2024-03-20  449.85       3
Accessories   USB Hub           2024-04-05  299.94       4
Electronics   Laptop Pro        2024-01-15  6499.95      1
Electronics   Laptop Basic      2024-02-10  2099.97      2
...

Date ascending, but amount descending for same date!
*/

-- Example 2: Top and bottom performers simultaneously
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    -- Highest amounts first
    RANK() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS HighestRank,
    -- Lowest amounts first
    RANK() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount ASC
    ) AS LowestRank
FROM Sales
WHERE Region IS NOT NULL
ORDER BY Region, SaleAmount DESC;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   HighestRank  LowestRank
-------  ----------  -----------  -----------  ----------
Central  2024-04-10  12999.90     1            3
Central  2024-04-01  2799.96      2            2
Central  2024-04-05  299.94       3            1
East     2024-03-05  10399.92     1            4
East     2024-01-15  6499.95      2            3
East     2024-03-10  1599.96      3            2
East     2024-01-20  299.90       4            1
...

Both top and bottom ranks in same query!
*/

/*
================================================================================
PART 4: HANDLING NULLs IN SORTED WINDOWS
================================================================================

NULL handling in ORDER BY affects ranking and sequencing.
*/

-- Add some records with NULL dates for demonstration
INSERT INTO Sales (CustomerID, ProductID, SaleDate, Quantity, SaleAmount, Region) VALUES
    (1, 3, NULL, 5, 149.95, 'East'),
    (2, 4, NULL, 1, 89.99, 'West');
GO

-- Example 1: NULLs in ORDER BY (default behavior)
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS RowNum,
    CASE 
        WHEN SaleDate IS NULL THEN 'NULL Date'
        ELSE CAST(SaleDate AS VARCHAR(10))
    END AS DateDisplay
FROM Sales
WHERE Region IN ('East', 'West')
ORDER BY Region, RowNum;
GO

/*
OUTPUT:
Region  SaleDate    SaleAmount  RowNum  DateDisplay
------  ----------  ----------  ------  ------------
East    NULL        149.95      1       NULL Date    -- NULLs sort first in SQL Server
East    2024-01-15  6499.95     2       2024-01-15
East    2024-01-20  299.90      3       2024-01-20
...

NULLs appear first by default!
*/

-- Example 2: Handling NULLs explicitly with COALESCE
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY COALESCE(SaleDate, '9999-12-31')  -- Push NULLs to end
    ) AS RowNum
FROM Sales
WHERE Region IN ('East', 'West')
ORDER BY Region, RowNum;
GO

/*
OUTPUT:
Region  SaleDate    SaleAmount  RowNum
------  ----------  ----------  ------
East    2024-01-15  6499.95     1
East    2024-01-20  299.90      2
East    2024-03-05  10399.92    3
East    2024-03-10  1599.96     4
East    NULL        149.95      5      -- NULL now sorts last
...

NULLs pushed to end with COALESCE!
*/

/*
================================================================================
PART 5: COMBINING GLOBAL AND LOCAL SORTING
================================================================================

Use both window ORDER BY and query ORDER BY for complete control.
*/

-- Example 1: Window sorting (for ranking) vs query sorting (for display)
SELECT 
    Region,
    p.Category,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC  -- Window sort: by amount
    ) AS RankByAmount
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY Region, SaleDate;  -- Query sort: by date for display
GO

/*
OUTPUT:
Region   Category      SaleDate    SaleAmount   RankByAmount
-------  ------------  ----------  -----------  ------------
Central  Electronics   2024-04-01  2799.96      2            -- Display order: by date
Central  Accessories   2024-04-05  299.94       3
Central  Electronics   2024-04-10  12999.90     1
East     Electronics   2024-01-15  6499.95      2
East     Accessories   2024-01-20  299.90       4
East     Electronics   2024-03-05  10399.92     1            -- Window order: by amount
East     Electronics   2024-03-10  1599.96      3
...

Window sort (for calculation) ≠ Display sort (for presentation)!
*/

-- Example 2: Multiple window orderings with single display order
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    -- Ranked by date
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS ChronologicalRank,
    -- Ranked by amount
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS AmountRank,
    -- Display in custom order
    CASE Region
        WHEN 'East' THEN 1
        WHEN 'West' THEN 2
        WHEN 'Central' THEN 3
    END AS DisplayOrder
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY DisplayOrder, SaleAmount DESC;  -- Display order
GO

/*
================================================================================
PART 6: PRACTICAL APPLICATIONS
================================================================================
*/

-- Application 1: Product sales ranking within categories
SELECT 
    p.Category,
    p.ProductName,
    SUM(s.SaleAmount) AS TotalSales,
    RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS CategoryRank,
    DENSE_RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS CategoryDenseRank,
    CONCAT(
        CAST(RANK() OVER(
            PARTITION BY p.Category 
            ORDER BY SUM(s.SaleAmount) DESC
        ) AS VARCHAR(5)),
        ' of ',
        CAST(COUNT(*) OVER(PARTITION BY p.Category) AS VARCHAR(5))
    ) AS RankDisplay
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.Category, p.ProductName
ORDER BY p.Category, TotalSales DESC;
GO

/*
OUTPUT:
Category      ProductName       TotalSales   CategoryRank  CategoryDenseRank  RankDisplay
------------  ----------------  -----------  ------------  -----------------  -----------
Accessories   Mouse Wireless    749.75       1             1                  1 of 3
Accessories   USB Hub           299.94       2             2                  2 of 3
Accessories   Keyboard Mech     179.98       3             3                  3 of 3
Electronics   Laptop Pro        29899.77     1             1                  1 of 3
Electronics   Laptop Basic      4899.93      2             2                  2 of 3
Electronics   Monitor 27"       1599.96      3             3                  3 of 3

Clear product rankings within categories!
*/

-- Application 2: Customer purchase sequence analysis
SELECT 
    c.CustomerName,
    s.SaleDate,
    p.ProductName,
    s.SaleAmount,
    ROW_NUMBER() OVER(
        PARTITION BY c.CustomerName 
        ORDER BY s.SaleDate, s.SaleID
    ) AS PurchaseNumber,
    SUM(s.SaleAmount) OVER(
        PARTITION BY c.CustomerName 
        ORDER BY s.SaleDate, s.SaleID
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeSpending,
    LAG(s.SaleDate) OVER(
        PARTITION BY c.CustomerName 
        ORDER BY s.SaleDate, s.SaleID
    ) AS PreviousPurchaseDate,
    DATEDIFF(DAY,
        LAG(s.SaleDate) OVER(
            PARTITION BY c.CustomerName 
            ORDER BY s.SaleDate, s.SaleID
        ),
        s.SaleDate
    ) AS DaysSinceLastPurchase
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, PurchaseNumber;
GO

/*
OUTPUT:
CustomerName   SaleDate    ProductName      SaleAmount   PurchaseNumber  CumulativeSpending  PreviousPurchaseDate  DaysSinceLastPurchase
-------------  ----------  ---------------  -----------  --------------  ------------------  --------------------  ---------------------
Acme Corp      2024-01-15  Laptop Pro       6499.95      1               6499.95             NULL                  NULL
Acme Corp      2024-01-20  Mouse Wireless   299.90       2               6799.85             2024-01-15            5
Enterprise LLC 2024-04-10  Laptop Pro       12999.90     1               12999.90            NULL                  NULL
Global Inc     2024-03-05  Laptop Pro       10399.92     1               10399.92            NULL                  NULL
Global Inc     2024-03-10  Monitor 27"      1599.96      2               11999.88            2024-03-05            5
...

Purchase sequence with cumulative spending and gaps!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Regional Performance
---------------------------------
Create a query showing sales ranked by region and date:
- Show sale details
- Rank by amount within region (highest first)
- Rank by date within region (earliest first)
- Show which quartile each sale falls into by amount
- Display in region, date order

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Product Performance Timeline
-----------------------------------------
For each product category, show:
- Products sorted by total sales (highest first)
- Cumulative sales total within category
- Percentage of category total
- Rank within category
- Only show products with sales

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Customer Segmentation
----------------------------------
Create a customer analysis with:
- Customer name and type
- Total sales per customer
- Rank within customer type (by sales)
- Rank overall
- Gap between customer rank and type rank

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Regional Performance
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    RANK() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS AmountRank,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS ChronologicalRank,
    NTILE(4) OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount
    ) AS AmountQuartile
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY Region, SaleDate;
GO

-- Solution 2: Product Performance Timeline
SELECT 
    p.Category,
    p.ProductName,
    SUM(s.SaleAmount) AS TotalSales,
    SUM(SUM(s.SaleAmount)) OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeCategorySales,
    100.0 * SUM(s.SaleAmount) / 
        SUM(SUM(s.SaleAmount)) OVER(PARTITION BY p.Category) AS PctOfCategory,
    RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS CategoryRank
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY p.Category, p.ProductName
ORDER BY p.Category, TotalSales DESC;
GO

-- Solution 3: Customer Segmentation
SELECT 
    c.CustomerName,
    c.CustomerType,
    SUM(s.SaleAmount) AS TotalSales,
    RANK() OVER(
        PARTITION BY c.CustomerType 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS RankInType,
    RANK() OVER(
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS OverallRank,
    RANK() OVER(
        ORDER BY SUM(s.SaleAmount) DESC
    ) - RANK() OVER(
        PARTITION BY c.CustomerType 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS RankGap
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerName, c.CustomerType
ORDER BY TotalSales DESC;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. WINDOW ORDER BY
   - Sorts rows within each partition
   - Independent of query ORDER BY
   - Required for rankings and running totals
   - Affects window function results

2. MULTIPLE SORT COLUMNS
   - Primary, secondary, tertiary ordering
   - Useful for tie-breaking
   - Each column can have ASC/DESC
   - More specific = more deterministic results

3. ASC VS DESC
   - ASC: lowest to highest (default)
   - DESC: highest to lowest
   - Mix in same ORDER BY clause
   - Affects rank assignments

4. NULL HANDLING
   - NULLs sort first by default (SQL Server)
   - Use COALESCE to control NULL position
   - Consider filtering NULLs with WHERE
   - Test NULL behavior in your database

5. WINDOW VS QUERY SORTING
   - Window ORDER BY: for calculations
   - Query ORDER BY: for display
   - Can be different
   - Window sort doesn't affect display

6. BEST PRACTICES
   - Use meaningful sort orders
   - Handle NULLs explicitly when important
   - Test with ties in data
   - Document complex sorting logic
   - Consider performance of multi-column sorts

================================================================================

NEXT STEPS:
-----------
In Lesson 16.4, we'll explore RANKING:
- ROW_NUMBER() function
- Handling duplicates
- Pagination techniques
- Top-N queries

Continue to: 04-ranking/lesson.sql

================================================================================
*/
