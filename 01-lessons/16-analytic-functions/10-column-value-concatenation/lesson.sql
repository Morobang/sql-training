/*
================================================================================
LESSON 16.10: COLUMN VALUE CONCATENATION
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Use STRING_AGG() with OVER clause
2. Create ordered concatenated strings within windows
3. Build cumulative concatenation
4. Handle delimiters and formatting
5. Combine with other window functions
6. Solve practical string aggregation problems

Business Context:
-----------------
String aggregation within windows enables creating comma-separated lists,
building audit trails, generating reports with concatenated values, and
creating hierarchical displays. Essential for reporting, data export,
and user-friendly displays.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 45 minutes

Note: STRING_AGG with OVER is available in SQL Server 2022+
For earlier versions, we'll show alternative approaches.

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: STRING_AGG BASICS (WITHOUT OVER)
================================================================================

First, let's review STRING_AGG without window functions as a foundation.
*/

-- Example 1: Simple STRING_AGG
SELECT 
    Region,
    STRING_AGG(CAST(SaleID AS VARCHAR), ', ') AS SaleIDs
FROM Sales
WHERE Region IS NOT NULL
GROUP BY Region
ORDER BY Region;
GO

/*
OUTPUT:
Region   SaleIDs
-------  ------------------
Central  8, 9, 10
East     1, 2, 5, 6, 13
West     3, 4, 7, 14

Comma-separated list of SaleIDs per region!
*/

-- Example 2: STRING_AGG with ordering
SELECT 
    Region,
    STRING_AGG(CAST(SaleID AS VARCHAR), ', ') 
        WITHIN GROUP (ORDER BY SaleDate) AS SaleIDsByDate
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
GROUP BY Region
ORDER BY Region;
GO

/*
OUTPUT:
Region   SaleIDsByDate
-------  ------------------
Central  8, 9, 10
East     1, 2, 5, 6, 13
West     3, 4, 7, 14

Ordered by SaleDate within each group!
*/

/*
================================================================================
PART 2: STRING_AGG WITH OVER (SQL Server 2022+)
================================================================================

STRING_AGG with OVER allows window-based string aggregation.
Note: This requires SQL Server 2022 or later.
*/

-- Example 1: Cumulative product list per customer
-- This syntax requires SQL Server 2022+
/*
SELECT 
    c.CustomerName,
    s.SaleDate,
    p.ProductName,
    STRING_AGG(p.ProductName, ', ') OVER(
        PARTITION BY c.CustomerID 
        ORDER BY s.SaleDate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS ProductHistory
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, s.SaleDate;
*/

-- Alternative for SQL Server 2019 and earlier using FOR XML PATH
SELECT 
    c.CustomerName,
    s.SaleDate,
    p.ProductName,
    STUFF((
        SELECT ', ' + p2.ProductName
        FROM Sales s2
        INNER JOIN Products p2 ON s2.ProductID = p2.ProductID
        WHERE s2.CustomerID = c.CustomerID 
          AND s2.SaleDate <= s.SaleDate
          AND s2.Region IS NOT NULL
        ORDER BY s2.SaleDate
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ProductHistory
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
ORDER BY c.CustomerName, s.SaleDate;
GO

/*
OUTPUT:
CustomerName    SaleDate    ProductName       ProductHistory
--------------  ----------  ----------------  ---------------------------------------
Acme Corp       2024-01-15  Laptop Pro        Laptop Pro
Acme Corp       2024-01-20  Mouse Wireless    Laptop Pro, Mouse Wireless
Acme Corp       2024-05-01  Mouse Wireless    Laptop Pro, Mouse Wireless, Mouse Wireless
...

Cumulative product list!
*/

/*
================================================================================
PART 3: PRACTICAL STRING AGGREGATION PATTERNS
================================================================================
*/

-- Example 1: Product categories purchased per customer
SELECT DISTINCT
    c.CustomerID,
    c.CustomerName,
    (
        SELECT STRING_AGG(DISTINCT p.Category, ', ') 
            WITHIN GROUP (ORDER BY p.Category)
        FROM Sales s2
        INNER JOIN Products p ON s2.ProductID = p.ProductID
        WHERE s2.CustomerID = c.CustomerID 
          AND s2.Region IS NOT NULL
    ) AS CategoriesPurchased,
    (
        SELECT COUNT(DISTINCT p.Category)
        FROM Sales s2
        INNER JOIN Products p ON s2.ProductID = p.ProductID
        WHERE s2.CustomerID = c.CustomerID 
          AND s2.Region IS NOT NULL
    ) AS CategoryCount
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL
ORDER BY c.CustomerName;
GO

/*
OUTPUT:
CustomerID  CustomerName    CategoriesPurchased           CategoryCount
----------  --------------  ----------------------------  -------------
1           Acme Corp       Accessories, Electronics      2
3           Enterprise LLC  Electronics                   1
4           Global Traders  Electronics                   1
...

Categories concatenated per customer!
*/

-- Example 2: Regional sales summary with amounts
SELECT 
    Region,
    STRING_AGG(
        CONCAT(
            FORMAT(SaleDate, 'yyyy-MM-dd'), 
            ': $', 
            FORMAT(SaleAmount, 'N2')
        ), 
        '; '
    ) WITHIN GROUP (ORDER BY SaleDate) AS SalesDetails,
    COUNT(*) AS SalesCount,
    SUM(SaleAmount) AS TotalAmount
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
GROUP BY Region
ORDER BY Region;
GO

/*
OUTPUT:
Region   SalesDetails                                                            SalesCount  TotalAmount
-------  ----------------------------------------------------------------------  ----------  -----------
Central  2024-04-01: $2,799.96; 2024-04-05: $299.94; 2024-04-10: $12,999.90    3           16099.80
East     2024-01-15: $6,499.95; 2024-01-20: $299.90; ...                        5           19099.63
West     2024-02-10: $2,099.97; 2024-02-15: $179.98; ...                        4           2909.78

Formatted sales details per region!
*/

-- Example 3: Customer purchase timeline
SELECT 
    c.CustomerName,
    STRING_AGG(
        CONCAT(
            FORMAT(s.SaleDate, 'MMM dd'), 
            ': ', 
            p.ProductName, 
            ' ($', 
            FORMAT(s.SaleAmount, 'N0'), 
            ')'
        ),
        ' | '
    ) WITHIN GROUP (ORDER BY s.SaleDate) AS PurchaseTimeline
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY c.CustomerName;
GO

/*
OUTPUT:
CustomerName    PurchaseTimeline
--------------  -------------------------------------------------------------------------
Acme Corp       Jan 15: Laptop Pro ($6,500) | Jan 20: Mouse Wireless ($300) | May 01: Mouse Wireless ($300)
Enterprise LLC  Apr 10: Laptop Pro ($13,000)
...

Human-readable purchase timeline!
*/

/*
================================================================================
PART 4: BUILDING HIERARCHICAL DISPLAYS
================================================================================
*/

-- Example 1: Products grouped by category
SELECT 
    Category,
    STRING_AGG(
        CONCAT(ProductName, ' ($', FORMAT(UnitPrice, 'N2'), ')'),
        ', '
    ) WITHIN GROUP (ORDER BY UnitPrice DESC) AS ProductsInCategory,
    COUNT(*) AS ProductCount,
    AVG(UnitPrice) AS AvgPrice
FROM Products
GROUP BY Category
ORDER BY Category;
GO

/*
OUTPUT:
Category      ProductsInCategory                                           ProductCount  AvgPrice
------------  -----------------------------------------------------------  ------------  --------
Accessories   Keyboard Mech ($29.99), Mouse Wireless ($29.99), USB Hub... 3             23.32
Electronics   Laptop Pro ($1,299.99), Laptop Basic ($699.99), Monitor...  4             568.74

Products listed per category!
*/

-- Example 2: Sales summary by month with customer list
SELECT 
    YEAR(SaleDate) AS SaleYear,
    MONTH(SaleDate) AS SaleMonth,
    DATENAME(MONTH, SaleDate) AS MonthName,
    STRING_AGG(DISTINCT c.CustomerName, ', ') 
        WITHIN GROUP (ORDER BY c.CustomerName) AS Customers,
    COUNT(*) AS SalesCount,
    SUM(s.SaleAmount) AS MonthTotal
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY YEAR(SaleDate), MONTH(SaleDate), DATENAME(MONTH, SaleDate)
ORDER BY SaleYear, SaleMonth;
GO

/*
OUTPUT:
SaleYear  SaleMonth  MonthName  Customers                           SalesCount  MonthTotal
--------  ---------  ---------  ----------------------------------  ----------  ----------
2024      1          January    Acme Corp                           2           6799.85
2024      2          February   Global Traders, Tech Start          2           2279.95
2024      3          March      Acme Solutions, Innovate Inc        3           12449.73
2024      4          April      Enterprise LLC, Tech Start, ...     3           16099.80

Customers who purchased each month!
*/

/*
================================================================================
PART 5: ADVANCED CONCATENATION TECHNIQUES
================================================================================
*/

-- Example 1: Limiting string length
SELECT 
    Region,
    CASE 
        WHEN LEN(STRING_AGG(CAST(SaleID AS VARCHAR), ', ') 
                WITHIN GROUP (ORDER BY SaleDate)) > 50 
        THEN LEFT(STRING_AGG(CAST(SaleID AS VARCHAR), ', ') 
                  WITHIN GROUP (ORDER BY SaleDate), 47) + '...'
        ELSE STRING_AGG(CAST(SaleID AS VARCHAR), ', ') 
             WITHIN GROUP (ORDER BY SaleDate)
    END AS SaleIDsList,
    COUNT(*) AS SalesCount
FROM Sales
WHERE Region IS NOT NULL AND SaleDate IS NOT NULL
GROUP BY Region
ORDER BY Region;
GO

/*
OUTPUT:
Region   SaleIDsList                SalesCount
-------  -------------------------  ----------
Central  8, 9, 10                   3
East     1, 2, 5, 6, 13             5
West     3, 4, 7, 14                4

Long lists truncated with ellipsis!
*/

-- Example 2: Conditional concatenation
SELECT 
    c.CustomerName,
    STRING_AGG(
        CASE 
            WHEN s.SaleAmount >= 1000 
            THEN CONCAT('★ ', p.ProductName, ' ($', FORMAT(s.SaleAmount, 'N0'), ')')
            ELSE CONCAT(p.ProductName, ' ($', FORMAT(s.SaleAmount, 'N0'), ')')
        END,
        ' | '
    ) WITHIN GROUP (ORDER BY s.SaleDate) AS ProductList
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY c.CustomerName;
GO

/*
OUTPUT:
CustomerName    ProductList
--------------  ------------------------------------------------------------------------
Acme Corp       ★ Laptop Pro ($6,500) | Mouse Wireless ($300) | Mouse Wireless ($300)
Enterprise LLC  ★ Laptop Pro ($13,000)

High-value purchases marked with star!
*/

-- Example 3: Multi-column concatenation
SELECT 
    Region,
    STRING_AGG(
        CONCAT(
            '[',
            FORMAT(SaleDate, 'MM/dd'),
            '] ',
            LEFT(p.ProductName, 15),
            ': ',
            FORMAT(s.SaleAmount, 'C0')
        ),
        CHAR(13) + CHAR(10)  -- Newline
    ) WITHIN GROUP (ORDER BY s.SaleDate) AS FormattedSales
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY Region;
GO

/*
================================================================================
PART 6: PRACTICAL APPLICATIONS
================================================================================
*/

-- Application 1: Order summary report
SELECT 
    c.CustomerName,
    COUNT(DISTINCT s.SaleID) AS OrderCount,
    SUM(s.SaleAmount) AS TotalSpent,
    STRING_AGG(
        CONCAT(
            FORMAT(s.SaleDate, 'yyyy-MM-dd'),
            ': ',
            p.ProductName,
            ' (Qty: ',
            s.Quantity,
            ', $',
            FORMAT(s.SaleAmount, 'N2'),
            ')'
        ),
        '; '
    ) WITHIN GROUP (ORDER BY s.SaleDate) AS OrderHistory
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpent DESC;
GO

-- Application 2: Product cross-sell analysis
SELECT 
    p1.ProductName AS AnchorProduct,
    STRING_AGG(DISTINCT p2.ProductName, ', ') 
        WITHIN GROUP (ORDER BY p2.ProductName) AS FrequentlyPurchasedWith,
    COUNT(DISTINCT s1.CustomerID) AS CustomersWhoBoughtBoth
FROM Sales s1
INNER JOIN Products p1 ON s1.ProductID = p1.ProductID
INNER JOIN Sales s2 ON s1.CustomerID = s2.CustomerID AND s1.SaleID <> s2.SaleID
INNER JOIN Products p2 ON s2.ProductID = p2.ProductID
WHERE s1.Region IS NOT NULL AND s2.Region IS NOT NULL
GROUP BY p1.ProductID, p1.ProductName
HAVING COUNT(DISTINCT s2.ProductID) > 0
ORDER BY p1.ProductName;
GO

-- Application 3: Regional product mix
SELECT 
    Region,
    STRING_AGG(
        CONCAT(
            p.Category,
            ': ',
            COUNT(*),
            ' sales, ',
            FORMAT(SUM(s.SaleAmount), 'C0')
        ),
        ' | '
    ) WITHIN GROUP (ORDER BY SUM(s.SaleAmount) DESC) AS CategoryMix
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY Region
ORDER BY Region;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Customer Activity Summary
--------------------------------------
For each customer, create a summary showing:
- Customer name
- Comma-separated list of all products purchased (distinct)
- Comma-separated list of all regions purchased from
- Total purchase count and amount
- Format: "ProductName (CategoryName)"

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Monthly Sales Report
---------------------------------
Create a monthly report with:
- Year, month, month name
- List of products sold (format: "ProductName: Qty")
- Total sales amount
- List of regions that had sales
- Limit product list to 100 characters

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Product Journey Report
-----------------------------------
For each product, show:
- Product name and category
- Chronological list of sales (format: "MM/DD - CustomerName")
- Total quantity sold across all sales
- Number of unique customers
- Average sale amount

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Customer Activity Summary
SELECT 
    c.CustomerName,
    STRING_AGG(
        DISTINCT CONCAT(p.ProductName, ' (', p.Category, ')'),
        ', '
    ) WITHIN GROUP (ORDER BY p.ProductName) AS ProductsPurchased,
    STRING_AGG(DISTINCT s.Region, ', ') 
        WITHIN GROUP (ORDER BY s.Region) AS RegionsPurchasedFrom,
    COUNT(*) AS TotalPurchases,
    SUM(s.SaleAmount) AS TotalSpent
FROM Sales s
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpent DESC;
GO

-- Solution 2: Monthly Sales Report
SELECT 
    YEAR(s.SaleDate) AS SaleYear,
    MONTH(s.SaleDate) AS SaleMonth,
    DATENAME(MONTH, s.SaleDate) AS MonthName,
    CASE 
        WHEN LEN(STRING_AGG(
            CONCAT(p.ProductName, ': ', SUM(s.Quantity)),
            ', '
        ) WITHIN GROUP (ORDER BY SUM(s.SaleAmount) DESC)) > 100
        THEN LEFT(STRING_AGG(
            CONCAT(p.ProductName, ': ', SUM(s.Quantity)),
            ', '
        ) WITHIN GROUP (ORDER BY SUM(s.SaleAmount) DESC), 97) + '...'
        ELSE STRING_AGG(
            CONCAT(p.ProductName, ': ', SUM(s.Quantity)),
            ', '
        ) WITHIN GROUP (ORDER BY SUM(s.SaleAmount) DESC)
    END AS ProductsSold,
    SUM(s.SaleAmount) AS TotalSales,
    STRING_AGG(DISTINCT s.Region, ', ') 
        WITHIN GROUP (ORDER BY s.Region) AS RegionsWithSales
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate), DATENAME(MONTH, s.SaleDate)
ORDER BY SaleYear, SaleMonth;
GO

-- Solution 3: Product Journey Report
SELECT 
    p.ProductName,
    p.Category,
    STRING_AGG(
        CONCAT(
            FORMAT(s.SaleDate, 'MM/dd'),
            ' - ',
            c.CustomerName
        ),
        '; '
    ) WITHIN GROUP (ORDER BY s.SaleDate) AS SalesJourney,
    SUM(s.Quantity) AS TotalQuantitySold,
    COUNT(DISTINCT s.CustomerID) AS UniqueCustomers,
    AVG(s.SaleAmount) AS AvgSaleAmount
FROM Sales s
INNER JOIN Products p ON s.ProductID = p.ProductID
INNER JOIN Customers c ON s.CustomerID = c.CustomerID
WHERE s.Region IS NOT NULL AND s.SaleDate IS NOT NULL
GROUP BY p.ProductID, p.ProductName, p.Category
ORDER BY TotalQuantitySold DESC;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. STRING_AGG BASICS
   - Aggregates strings into single delimited value
   - WITHIN GROUP (ORDER BY ...) controls ordering
   - Delimiter can be any string
   - Works in GROUP BY queries

2. STRING_AGG WITH OVER (SQL Server 2022+)
   - Allows window-based string aggregation
   - Can create cumulative concatenations
   - Supports PARTITION BY and ORDER BY
   - Enables row-by-row string building

3. FORMATTING TECHNIQUES
   - Use CONCAT for multi-column values
   - FORMAT for dates and numbers
   - CASE for conditional inclusion
   - LEFT/SUBSTRING for length limits

4. COMMON PATTERNS
   Product List:
     STRING_AGG(ProductName, ', ') WITHIN GROUP (ORDER BY ProductName)
   
   Formatted Details:
     STRING_AGG(CONCAT(Date, ': ', Product, ' ($', Amount, ')'), '; ')
   
   With Limit:
     LEFT(STRING_AGG(...), 100) + '...'

5. ALTERNATIVES FOR OLDER VERSIONS
   - FOR XML PATH('') technique
   - Recursive CTEs
   - STUFF function
   - Custom CLR aggregates

6. BEST PRACTICES
   - Always use WITHIN GROUP for deterministic results
   - Consider string length limits (NVARCHAR(MAX))
   - Test with large datasets
   - Format consistently
   - Document delimiter choices
   - Handle NULL values appropriately

7. PERFORMANCE CONSIDERATIONS
   - STRING_AGG can be memory intensive
   - Limit result set before aggregating
   - Consider length limits for very large sets
   - Index columns used in WHERE/GROUP BY
   - Test with production data volumes

================================================================================

NEXT STEPS:
-----------
In Lesson 16.11, we'll complete the chapter with TEST YOUR KNOWLEDGE:
- Comprehensive exercises covering all analytic functions
- Real-world scenarios
- Performance challenges
- Best practices review

Continue to: 11-test-your-knowledge/lesson.md

================================================================================
*/
