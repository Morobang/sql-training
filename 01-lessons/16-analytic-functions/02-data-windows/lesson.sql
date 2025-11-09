/*
================================================================================
LESSON 16.2: DATA WINDOWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use PARTITION BY to divide data into windows
2. Apply ORDER BY within window specifications
3. Combine multiple window functions
4. Handle NULLs in window contexts
5. Create multi-column partitions
6. Understand window boundaries

Business Context:
-----------------
Data windows allow you to perform calculations on logical groups while
maintaining row-level detail. This is essential for comparative analysis,
regional breakdowns, category-level statistics, and time-based calculations.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 50 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: PARTITION BY BASICS
================================================================================

PARTITION BY divides the result set into partitions (groups) where the
window function operates independently on each partition.
*/

-- Create sample data
DROP TABLE IF EXISTS Sales;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;
GO

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    CustomerName NVARCHAR(200) NOT NULL,
    Region NVARCHAR(50),
    CustomerType NVARCHAR(20)
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100),
    UnitPrice DECIMAL(10,2)
);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    SaleDate DATE,
    Quantity INT,
    SaleAmount DECIMAL(12,2),
    Region NVARCHAR(50)
);
GO

-- Insert sample data
INSERT INTO Customers (CustomerName, Region, CustomerType) VALUES
    ('Acme Corp', 'East', 'Enterprise'),
    ('TechStart', 'West', 'SMB'),
    ('Global Inc', 'East', 'Enterprise'),
    ('Small Shop', 'West', 'SMB'),
    ('MidSize Co', 'Central', 'Mid-Market'),
    ('Enterprise LLC', 'Central', 'Enterprise');

INSERT INTO Products (ProductName, Category, UnitPrice) VALUES
    ('Laptop Pro', 'Electronics', 1299.99),
    ('Laptop Basic', 'Electronics', 699.99),
    ('Mouse Wireless', 'Accessories', 29.99),
    ('Keyboard Mech', 'Accessories', 89.99),
    ('Monitor 27"', 'Electronics', 399.99),
    ('USB Hub', 'Accessories', 49.99);

INSERT INTO Sales (CustomerID, ProductID, SaleDate, Quantity, SaleAmount, Region) VALUES
    (1, 1, '2024-01-15', 5, 6499.95, 'East'),
    (1, 3, '2024-01-20', 10, 299.90, 'East'),
    (2, 2, '2024-02-10', 3, 2099.97, 'West'),
    (2, 4, '2024-02-15', 2, 179.98, 'West'),
    (3, 1, '2024-03-05', 8, 10399.92, 'East'),
    (3, 5, '2024-03-10', 4, 1599.96, 'East'),
    (4, 3, '2024-03-20', 15, 449.85, 'West'),
    (5, 2, '2024-04-01', 4, 2799.96, 'Central'),
    (5, 6, '2024-04-05', 6, 299.94, 'Central'),
    (6, 1, '2024-04-10', 10, 12999.90, 'Central');
GO

-- Example 1: Simple window without partition (operates on entire result set)
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER() AS TotalSales,
    AVG(SaleAmount) OVER() AS AvgSale,
    COUNT(*) OVER() AS TotalSalesCount
FROM Sales
ORDER BY SaleID;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   TotalSales  AvgSale    TotalSalesCount
------  ----------  -----------  ----------  ---------  ---------------
1       2024-01-15  6499.95      37629.33    3762.93    10
2       2024-01-20  299.90       37629.33    3762.93    10
3       2024-02-10  2099.97      37629.33    3762.93    10
...

Window operates on ALL rows!
*/

-- Example 2: PARTITION BY single column (region)
SELECT 
    SaleID,
    Region,
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(PARTITION BY Region) AS RegionTotal,
    AVG(SaleAmount) OVER(PARTITION BY Region) AS RegionAvg,
    COUNT(*) OVER(PARTITION BY Region) AS RegionSalesCount
FROM Sales
ORDER BY Region, SaleID;
GO

/*
OUTPUT:
SaleID  Region   SaleDate    SaleAmount   RegionTotal  RegionAvg   RegionSalesCount
------  -------  ----------  -----------  -----------  ----------  ----------------
1       East     2024-01-15  6499.95      18799.73     4699.93     4
2       East     2024-01-20  299.90       18799.73     4699.93     4
5       East     2024-03-05  10399.92     18799.73     4699.93     4
6       East     2024-03-10  1599.96      18799.73     4699.93     4
8       Central  2024-04-01  2799.96      16099.80     5366.60     3
9       Central  2024-04-05  299.94       16099.80     5366.60     3
10      Central  2024-04-10  12999.90     16099.80     5366.60     3
3       West     2024-02-10  2099.97      2729.80      909.93      3
4       West     2024-02-15  179.98       2729.80      909.93      3
7       West     2024-03-20  449.85       2729.80      909.93      3

Each region calculated independently!
*/

-- Example 3: Compare individual sales to regional and overall totals
SELECT 
    s.SaleID,
    s.Region,
    s.SaleDate,
    s.SaleAmount,
    SUM(s.SaleAmount) OVER(PARTITION BY s.Region) AS RegionTotal,
    SUM(s.SaleAmount) OVER() AS CompanyTotal,
    100.0 * s.SaleAmount / SUM(s.SaleAmount) OVER(PARTITION BY s.Region) AS PctOfRegion,
    100.0 * s.SaleAmount / SUM(s.SaleAmount) OVER() AS PctOfTotal
FROM Sales s
ORDER BY s.Region, s.SaleAmount DESC;
GO

/*
OUTPUT:
SaleID  Region   SaleDate    SaleAmount   RegionTotal  CompanyTotal  PctOfRegion  PctOfTotal
------  -------  ----------  -----------  -----------  ------------  -----------  ----------
10      Central  2024-04-10  12999.90     16099.80     37629.33      80.74        34.54
8       Central  2024-04-01  2799.96      16099.80     37629.33      17.39        7.44
9       Central  2024-04-05  299.94       16099.80     37629.33      1.86         0.80
5       East     2024-03-05  10399.92     18799.73     37629.33      55.31        27.64
1       East     2024-01-15  6499.95      18799.73     37629.33      34.57        17.27
...

Both regional and overall percentages!
*/

/*
================================================================================
PART 2: MULTIPLE PARTITION COLUMNS
================================================================================

You can partition by multiple columns to create more granular windows.
*/

-- Example 1: Partition by Region AND Product Category
SELECT 
    s.Region,
    p.Category,
    p.ProductName,
    s.SaleAmount,
    SUM(s.SaleAmount) OVER(
        PARTITION BY s.Region, p.Category
    ) AS RegionCategoryTotal,
    COUNT(*) OVER(
        PARTITION BY s.Region, p.Category
    ) AS RegionCategoryCount
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
ORDER BY s.Region, p.Category, s.SaleAmount DESC;
GO

/*
OUTPUT:
Region   Category      ProductName      SaleAmount   RegionCategoryTotal  RegionCategoryCount
-------  ------------  ---------------  -----------  -------------------  -------------------
Central  Accessories   USB Hub          299.94       299.94               1
Central  Electronics   Laptop Pro       12999.90     15799.86             2
Central  Electronics   Laptop Basic     2799.96      15799.86             2
East     Accessories   Mouse Wireless   299.90       299.90               1
East     Electronics   Laptop Pro       6499.95      18499.83             3
East     Electronics   Laptop Pro       10399.92     18499.83             3
East     Electronics   Monitor 27"      1599.96      18499.83             3
...

Partitioned by BOTH Region AND Category!
*/

-- Example 2: Compare to multiple aggregation levels
SELECT 
    s.Region,
    p.Category,
    s.SaleAmount,
    -- By Region + Category
    SUM(s.SaleAmount) OVER(PARTITION BY s.Region, p.Category) AS RegionCatTotal,
    -- By Region only
    SUM(s.SaleAmount) OVER(PARTITION BY s.Region) AS RegionTotal,
    -- By Category only
    SUM(s.SaleAmount) OVER(PARTITION BY p.Category) AS CategoryTotal,
    -- Overall
    SUM(s.SaleAmount) OVER() AS GrandTotal
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
ORDER BY s.Region, p.Category;
GO

/*
OUTPUT:
Region   Category      SaleAmount   RegionCatTotal  RegionTotal  CategoryTotal  GrandTotal
-------  ------------  -----------  --------------  -----------  -------------  ----------
Central  Accessories   299.94       299.94          16099.80     1049.67        37629.33
Central  Electronics   12999.90     15799.86        16099.80     36579.66       37629.33
Central  Electronics   2799.96      15799.86        16099.80     36579.66       37629.33
East     Accessories   299.90       299.90          18799.73     1049.67        37629.33
East     Electronics   6499.95      18499.83        18799.73     36579.66       37629.33
...

Multiple aggregation levels in one query!
*/

/*
================================================================================
PART 3: ORDER BY IN WINDOW FUNCTIONS
================================================================================

ORDER BY defines the logical order of rows within each partition.
This is crucial for running totals, rankings, and offset functions.
*/

-- Example 1: Running total by date (no partition)
SELECT 
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(ORDER BY SaleDate) AS RunningTotal,
    AVG(SaleAmount) OVER(ORDER BY SaleDate) AS RunningAverage
FROM Sales
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleDate    SaleAmount   RunningTotal  RunningAverage
----------  -----------  ------------  --------------
2024-01-15  6499.95      6499.95       6499.95
2024-01-20  299.90       6799.85       3399.93
2024-02-10  2099.97      8899.82       2966.61
2024-02-15  179.98       9079.80       2269.95
2024-03-05  10399.92     19479.72      3895.94
...

Running calculations based on date order!
*/

-- Example 2: Running total WITHIN each region
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    SUM(SaleAmount) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS RegionRunningTotal,
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
    ) AS RegionSaleSequence
FROM Sales
ORDER BY Region, SaleDate;
GO

/*
OUTPUT:
Region   SaleDate    SaleAmount   RegionRunningTotal  RegionSaleSequence
-------  ----------  -----------  ------------------  ------------------
Central  2024-04-01  2799.96      2799.96             1
Central  2024-04-05  299.94       3099.90             2
Central  2024-04-10  12999.90     16099.80            3
East     2024-01-15  6499.95      6499.95             1
East     2024-01-20  299.90       6799.85             2
East     2024-03-05  10399.92     17199.77            3
East     2024-03-10  1599.96      18799.73            4
West     2024-02-10  2099.97      2099.97             1
West     2024-02-15  179.98       2279.95             2
West     2024-03-20  449.85       2729.80             3

Running total resets for each region!
*/

-- Example 3: Multiple sort columns in ORDER BY
SELECT 
    Region,
    SaleDate,
    SaleAmount,
    -- Order by date first, then amount
    ROW_NUMBER() OVER(
        PARTITION BY Region 
        ORDER BY SaleDate, SaleAmount DESC
    ) AS RowNum,
    -- Order by amount only
    RANK() OVER(
        PARTITION BY Region 
        ORDER BY SaleAmount DESC
    ) AS AmountRank
FROM Sales
ORDER BY Region, SaleDate, SaleAmount DESC;
GO

/*
================================================================================
PART 4: COMBINING MULTIPLE WINDOW FUNCTIONS
================================================================================

You can use multiple window functions with different specifications in
the same query.
*/

-- Example 1: Different partitions and orderings
SELECT 
    s.Region,
    p.Category,
    s.SaleDate,
    s.SaleAmount,
    -- Rank within region by amount
    RANK() OVER(
        PARTITION BY s.Region 
        ORDER BY s.SaleAmount DESC
    ) AS RegionRank,
    -- Rank within category by amount
    RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY s.SaleAmount DESC
    ) AS CategoryRank,
    -- Running total by date (no partition)
    SUM(s.SaleAmount) OVER(
        ORDER BY s.SaleDate
    ) AS CompanyRunningTotal,
    -- Running total within region by date
    SUM(s.SaleAmount) OVER(
        PARTITION BY s.Region 
        ORDER BY s.SaleDate
    ) AS RegionRunningTotal
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
ORDER BY s.SaleDate;
GO

/*
OUTPUT:
Region   Category      SaleDate    SaleAmount   RegionRank  CategoryRank  CompanyRunningTotal  RegionRunningTotal
-------  ------------  ----------  -----------  ----------  ------------  -------------------  ------------------
East     Electronics   2024-01-15  6499.95      2           3             6499.95              6499.95
East     Accessories   2024-01-20  299.90       4           1             6799.85              6799.85
West     Electronics   2024-02-10  2099.97      1           5             8899.82              2099.97
West     Accessories   2024-02-15  179.98       3           2             9079.80              2279.95
...

Multiple rankings and running totals!
*/

-- Example 2: Combining different aggregate functions
SELECT 
    Region,
    ProductID,
    SaleDate,
    SaleAmount,
    -- Regional aggregates
    SUM(SaleAmount) OVER(PARTITION BY Region) AS RegionTotal,
    AVG(SaleAmount) OVER(PARTITION BY Region) AS RegionAvg,
    MIN(SaleAmount) OVER(PARTITION BY Region) AS RegionMin,
    MAX(SaleAmount) OVER(PARTITION BY Region) AS RegionMax,
    COUNT(*) OVER(PARTITION BY Region) AS RegionCount,
    -- Deviation from regional average
    SaleAmount - AVG(SaleAmount) OVER(PARTITION BY Region) AS DiffFromRegionAvg
FROM Sales
ORDER BY Region, SaleAmount DESC;
GO

/*
================================================================================
PART 5: HANDLING NULLs IN WINDOWS
================================================================================

Understanding how NULLs behave in window functions.
*/

-- Add some NULL values for demonstration
INSERT INTO Sales (CustomerID, ProductID, SaleDate, Quantity, SaleAmount, Region) VALUES
    (1, 1, '2024-05-01', 2, 2599.98, NULL),  -- NULL region
    (2, 2, NULL, 1, 699.99, 'West');         -- NULL date
GO

-- Example 1: NULLs in PARTITION BY
SELECT 
    SaleID,
    Region,
    SaleAmount,
    COUNT(*) OVER(PARTITION BY Region) AS RegionCount,
    SUM(SaleAmount) OVER(PARTITION BY Region) AS RegionTotal
FROM Sales
ORDER BY Region, SaleID;
GO

/*
OUTPUT:
SaleID  Region   SaleAmount   RegionCount  RegionTotal
------  -------  -----------  -----------  -----------
8       Central  2799.96      3            16099.80
9       Central  299.94       3            16099.80
10      Central  12999.90     3            16099.80
1       East     6499.95      4            18799.73
2       East     299.90       4            18799.73
...
11      NULL     2599.98      1            2599.98     -- NULL region gets own partition
3       West     2099.97      4            3429.79
...

NULLs create separate partition!
*/

-- Example 2: NULLs in ORDER BY
SELECT 
    SaleID,
    SaleDate,
    SaleAmount,
    ROW_NUMBER() OVER(ORDER BY SaleDate) AS RowNum,
    SUM(SaleAmount) OVER(ORDER BY SaleDate) AS RunningTotal
FROM Sales
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    SaleAmount   RowNum  RunningTotal
------  ----------  -----------  ------  ------------
12      NULL        699.99       1       699.99           -- NULLs sort first (SQL Server default)
1       2024-01-15  6499.95      2       7199.94
2       2024-01-20  299.90       3       7499.84
...

NULLs sorted first by default!
*/

/*
================================================================================
PART 6: PRACTICAL SCENARIOS
================================================================================
*/

-- Scenario 1: Sales performance analysis
SELECT 
    s.Region,
    c.CustomerName,
    s.SaleDate,
    s.SaleAmount,
    -- Customer's total in region
    SUM(s.SaleAmount) OVER(
        PARTITION BY s.Region, s.CustomerID
    ) AS CustomerRegionTotal,
    -- Customer's rank in region
    DENSE_RANK() OVER(
        PARTITION BY s.Region 
        ORDER BY SUM(s.SaleAmount) OVER(PARTITION BY s.Region, s.CustomerID) DESC
    ) AS CustomerRegionRank,
    -- Percentage of region total
    100.0 * s.SaleAmount / NULLIF(SUM(s.SaleAmount) OVER(PARTITION BY s.Region), 0) AS PctOfRegion
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
ORDER BY s.Region, s.SaleDate;
GO

-- Scenario 2: Product category performance by region
SELECT 
    s.Region,
    p.Category,
    COUNT(*) AS SalesCount,
    SUM(s.SaleAmount) AS CategorySales,
    SUM(SUM(s.SaleAmount)) OVER(PARTITION BY s.Region) AS RegionTotal,
    100.0 * SUM(s.SaleAmount) / 
        NULLIF(SUM(SUM(s.SaleAmount)) OVER(PARTITION BY s.Region), 0) AS PctOfRegionSales,
    RANK() OVER(
        PARTITION BY s.Region 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS CategoryRankInRegion
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY s.Region, p.Category
ORDER BY s.Region, CategorySales DESC;
GO

/*
OUTPUT:
Region   Category      SalesCount  CategorySales  RegionTotal  PctOfRegionSales  CategoryRankInRegion
-------  ------------  ----------  -------------  -----------  ----------------  --------------------
Central  Electronics   2           15799.86       16099.80     98.14             1
Central  Accessories   1           299.94         16099.80     1.86              2
East     Electronics   3           18499.83       18799.73     98.41             1
East     Accessories   1           299.90         18799.73     1.59              2
West     Electronics   2           2279.95        3429.79      66.48             1
West     Accessories   2           1149.84        3429.79      33.52             2

Category performance within each region!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Customer Analysis
------------------------------
Create a query showing each customer's sales with:
- Customer's total sales
- Customer's average sale amount
- Customer's rank by total sales
- Percentage of company total
- Number of purchases

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Time-Based Analysis
--------------------------------
For each sale, show:
- Sale details (date, amount, region)
- Running total for the year
- Running total within the region
- Days since previous sale in region
- Cumulative sales count in region

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Multi-Level Partitioning
-------------------------------------
Create a query with these calculations:
- Total sales by Region AND Category
- Rank of each product within its category
- Percentage of category total
- Percentage of region total
- Overall percentage

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Customer Analysis
SELECT 
    c.CustomerName,
    COUNT(*) AS PurchaseCount,
    SUM(s.SaleAmount) AS TotalSales,
    AVG(s.SaleAmount) AS AvgSale,
    RANK() OVER(ORDER BY SUM(s.SaleAmount) DESC) AS SalesRank,
    100.0 * SUM(s.SaleAmount) / SUM(SUM(s.SaleAmount)) OVER() AS PctOfTotal
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerName
ORDER BY TotalSales DESC;
GO

-- Solution 2: Time-Based Analysis
SELECT 
    SaleID,
    SaleDate,
    Region,
    SaleAmount,
    SUM(SaleAmount) OVER(
        ORDER BY SaleDate 
        ROWS UNBOUNDED PRECEDING
    ) AS YearRunningTotal,
    SUM(SaleAmount) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
        ROWS UNBOUNDED PRECEDING
    ) AS RegionRunningTotal,
    DATEDIFF(DAY, 
        LAG(SaleDate) OVER(PARTITION BY Region ORDER BY SaleDate),
        SaleDate
    ) AS DaysSinceLastRegionSale,
    COUNT(*) OVER(
        PARTITION BY Region 
        ORDER BY SaleDate
        ROWS UNBOUNDED PRECEDING
    ) AS CumulativeRegionSales
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
ORDER BY SaleDate;
GO

-- Solution 3: Multi-Level Partitioning
SELECT 
    s.Region,
    p.Category,
    p.ProductName,
    SUM(s.SaleAmount) AS ProductSales,
    SUM(SUM(s.SaleAmount)) OVER(
        PARTITION BY s.Region, p.Category
    ) AS RegionCategoryTotal,
    RANK() OVER(
        PARTITION BY p.Category 
        ORDER BY SUM(s.SaleAmount) DESC
    ) AS ProductRankInCategory,
    100.0 * SUM(s.SaleAmount) / NULLIF(
        SUM(SUM(s.SaleAmount)) OVER(PARTITION BY p.Category), 0
    ) AS PctOfCategoryTotal,
    100.0 * SUM(s.SaleAmount) / NULLIF(
        SUM(SUM(s.SaleAmount)) OVER(PARTITION BY s.Region), 0
    ) AS PctOfRegionTotal,
    100.0 * SUM(s.SaleAmount) / NULLIF(
        SUM(SUM(s.SaleAmount)) OVER(), 0
    ) AS PctOfGrandTotal
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY s.Region, p.Category, p.ProductName
ORDER BY s.Region, p.Category, ProductSales DESC;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. PARTITION BY BASICS
   - Divides result set into independent windows
   - Similar to GROUP BY but preserves row detail
   - Optional - omit for whole result set
   - Can use multiple columns

2. ORDER BY IN WINDOWS
   - Defines logical order within partitions
   - Affects running calculations
   - Required for ranking and offset functions
   - Can use multiple columns with ASC/DESC

3. MULTIPLE WINDOW FUNCTIONS
   - Can use different partitions in same query
   - Can use different orderings
   - Efficient - SQL Server optimizes multiple windows
   - Each OVER() clause is independent

4. NULL HANDLING
   - NULLs create separate partition in PARTITION BY
   - NULLs sort first/last in ORDER BY (database dependent)
   - Use COALESCE or ISNULL to handle NULLs explicitly
   - Consider filtering NULLs with WHERE clause

5. PERFORMANCE
   - Index PARTITION BY and ORDER BY columns
   - Same window specification = shared computation
   - Filter before windowing when possible
   - Be aware of sorting costs

6. BEST PRACTICES
   - Start simple - add complexity gradually
   - Use meaningful window specifications
   - Comment complex window functions
   - Test with representative data volumes
   - Consider readability vs performance

================================================================================

NEXT STEPS:
-----------
In Lesson 16.3, we'll explore LOCALIZED SORTING:
- Sorting within partitions
- Multi-level sort orders
- Controlling sort direction
- Advanced ordering techniques

Continue to: 03-localized-sorting/lesson.sql

================================================================================
*/
