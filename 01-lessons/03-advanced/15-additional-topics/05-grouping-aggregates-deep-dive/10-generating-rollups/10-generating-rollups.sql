/*
============================================================================
Lesson 08.10 - Generating Rollups and Subtotals
============================================================================

Description:
Master ROLLUP, CUBE, and GROUPING SETS to create subtotals, grand totals,
and multi-dimensional summaries for comprehensive reporting.

Topics Covered:
• ROLLUP operator
• CUBE operator
• GROUPING SETS
• GROUPING and GROUPING_ID functions
• Subtotal patterns

Prerequisites:
• Lessons 08.01-08.09

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding ROLLUP
============================================================================
ROLLUP creates hierarchical subtotals from right to left.
*/

-- Example 1.1: Basic ROLLUP
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    SUM(Price) AS TotalPrice
FROM Products
GROUP BY ROLLUP(CategoryID, SupplierID)
ORDER BY CategoryID, SupplierID;

/*
Generates these grouping levels:
1. (CategoryID, SupplierID) - Detail level
2. (CategoryID, NULL)       - Category subtotals
3. (NULL, NULL)             - Grand total
*/

-- Example 1.2: Three-column ROLLUP
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    CustomerID,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate), CustomerID)
ORDER BY Year, Month, CustomerID;

/*
Generates:
1. (Year, Month, CustomerID) - Most detailed
2. (Year, Month, NULL)       - Monthly subtotals
3. (Year, NULL, NULL)        - Yearly subtotals
4. (NULL, NULL, NULL)        - Grand total
*/

-- Example 1.3: Identifying subtotal rows with GROUPING()
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    GROUPING(CategoryID) AS IsCategorySubtotal,
    GROUPING(SupplierID) AS IsSupplierSubtotal,
    CASE 
        WHEN GROUPING(CategoryID) = 1 AND GROUPING(SupplierID) = 1 THEN 'Grand Total'
        WHEN GROUPING(SupplierID) = 1 THEN 'Category Subtotal'
        ELSE 'Detail'
    END AS RowType
FROM Products
GROUP BY ROLLUP(CategoryID, SupplierID)
ORDER BY CategoryID, SupplierID;

-- GROUPING() returns:
-- 0 = This column is part of the grouping
-- 1 = This column is NULL due to rollup (subtotal row)


/*
============================================================================
PART 2: Understanding CUBE
============================================================================
CUBE creates all possible combinations of grouping columns.
*/

-- Example 2.1: Basic CUBE
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CUBE(CategoryID, SupplierID)
ORDER BY CategoryID, SupplierID;

/*
Generates these grouping levels:
1. (CategoryID, SupplierID) - Detail level
2. (CategoryID, NULL)       - Category totals
3. (NULL, SupplierID)       - Supplier totals
4. (NULL, NULL)             - Grand total
*/

-- Example 2.2: CUBE with labeling
SELECT 
    ISNULL(CAST(CategoryID AS VARCHAR(10)), 'All Categories') AS Category,
    ISNULL(CAST(SupplierID AS VARCHAR(10)), 'All Suppliers') AS Supplier,
    COUNT(*) AS ProductCount,
    SUM(Price * Stock) AS InventoryValue,
    CASE 
        WHEN GROUPING(CategoryID) = 1 AND GROUPING(SupplierID) = 1 THEN 'Grand Total'
        WHEN GROUPING(CategoryID) = 1 THEN 'Supplier Total'
        WHEN GROUPING(SupplierID) = 1 THEN 'Category Total'
        ELSE 'Detail'
    END AS AggregationLevel
FROM Products
GROUP BY CUBE(CategoryID, SupplierID)
ORDER BY CategoryID, SupplierID;

-- Example 2.3: Three-column CUBE (generates 8 combinations)
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    CustomerID,
    COUNT(*) AS Orders,
    GROUPING_ID(YEAR(OrderDate), MONTH(OrderDate), CustomerID) AS GroupingID
FROM Orders
WHERE YEAR(OrderDate) = 2024  -- Limit data for clarity
GROUP BY CUBE(YEAR(OrderDate), MONTH(OrderDate), CustomerID)
ORDER BY GROUPING_ID(YEAR(OrderDate), MONTH(OrderDate), CustomerID), Year, Month, CustomerID;

-- GROUPING_ID returns a bitmap:
-- 0 = (Year, Month, Customer) - 000 in binary
-- 1 = (Year, Month, NULL)     - 001 in binary
-- 2 = (Year, NULL, Customer)  - 010 in binary
-- etc.


/*
============================================================================
PART 3: GROUPING SETS (Custom Combinations)
============================================================================
*/

-- Example 3.1: Specific grouping combinations
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY GROUPING SETS (
    (CategoryID, SupplierID),  -- Detail level
    (CategoryID),               -- Category totals only
    ()                          -- Grand total only
)
ORDER BY CategoryID, SupplierID;

-- Example 3.2: Different dimensions (not hierarchical)
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    CustomerID,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY GROUPING SETS (
    (YEAR(OrderDate), MONTH(OrderDate)),  -- Monthly totals
    (CustomerID),                          -- Customer totals
    ()                                     -- Grand total
)
ORDER BY Year, Month, CustomerID;

-- Example 3.3: Complex custom groupings
SELECT 
    YEAR(o.OrderDate) AS Year,
    c.Country,
    p.CategoryID,
    COUNT(*) AS Orders,
    SUM(od.Quantity * od.UnitPrice) AS Revenue,
    CASE 
        WHEN GROUPING(YEAR(o.OrderDate)) = 0 AND GROUPING(c.Country) = 0 AND GROUPING(p.CategoryID) = 0 THEN 'Year + Country + Category'
        WHEN GROUPING(YEAR(o.OrderDate)) = 0 AND GROUPING(c.Country) = 0 THEN 'Year + Country'
        WHEN GROUPING(c.Country) = 0 AND GROUPING(p.CategoryID) = 0 THEN 'Country + Category'
        WHEN GROUPING(YEAR(o.OrderDate)) = 0 THEN 'Year Only'
        ELSE 'Grand Total'
    END AS GroupingLevel
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY GROUPING SETS (
    (YEAR(o.OrderDate), c.Country, p.CategoryID),
    (YEAR(o.OrderDate), c.Country),
    (c.Country, p.CategoryID),
    (YEAR(o.OrderDate)),
    ()
)
ORDER BY Year, Country, CategoryID;


/*
============================================================================
PART 4: ROLLUP vs CUBE vs GROUPING SETS
============================================================================
*/

-- Example 4.1: Comparison with two columns
-- All three produce different results

-- ROLLUP: Hierarchical (3 levels)
SELECT 'ROLLUP' AS Type, CategoryID, SupplierID, COUNT(*) AS Count
FROM Products
GROUP BY ROLLUP(CategoryID, SupplierID)

UNION ALL

-- CUBE: All combinations (4 levels)
SELECT 'CUBE', CategoryID, SupplierID, COUNT(*)
FROM Products
GROUP BY CUBE(CategoryID, SupplierID)

UNION ALL

-- GROUPING SETS: Custom (only detail and grand total)
SELECT 'GROUPING SETS', CategoryID, SupplierID, COUNT(*)
FROM Products
GROUP BY GROUPING SETS ((CategoryID, SupplierID), ())

ORDER BY Type, CategoryID, SupplierID;


/*
============================================================================
PART 5: Practical Reporting Examples
============================================================================
*/

-- Example 5.1: Sales report with subtotals
SELECT 
    ISNULL(CAST(YEAR(OrderDate) AS VARCHAR(10)), 'All Years') AS Year,
    ISNULL(CAST(MONTH(OrderDate) AS VARCHAR(10)), 'All Months') AS Month,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue,
    CASE 
        WHEN GROUPING(YEAR(OrderDate)) = 1 THEN 'GRAND TOTAL'
        WHEN GROUPING(MONTH(OrderDate)) = 1 THEN 'Year Subtotal'
        ELSE ''
    END AS Label
FROM Orders
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate))
ORDER BY 
    GROUPING(YEAR(OrderDate)),
    Year,
    GROUPING(MONTH(OrderDate)),
    Month;

-- Example 5.2: Product inventory report by category and supplier
SELECT 
    COALESCE(CAST(p.CategoryID AS VARCHAR(10)), 'All Categories') AS Category,
    COALESCE(CAST(p.SupplierID AS VARCHAR(10)), 'All Suppliers') AS Supplier,
    COUNT(DISTINCT p.ProductID) AS Products,
    SUM(p.Stock) AS TotalStock,
    SUM(p.Price * p.Stock) AS InventoryValue,
    CASE 
        WHEN GROUPING(p.CategoryID) = 1 AND GROUPING(p.SupplierID) = 1 THEN '== TOTAL =='
        WHEN GROUPING(p.SupplierID) = 1 THEN '= Category Total ='
        WHEN GROUPING(p.CategoryID) = 1 THEN '= Supplier Total ='
        ELSE ''
    END AS SummaryLevel
FROM Products p
GROUP BY CUBE(p.CategoryID, p.SupplierID)
ORDER BY 
    GROUPING(p.CategoryID),
    p.CategoryID,
    GROUPING(p.SupplierID),
    p.SupplierID;

-- Example 5.3: Customer analysis by country and year
SELECT 
    COALESCE(c.Country, 'All Countries') AS Country,
    COALESCE(CAST(YEAR(o.OrderDate) AS VARCHAR(10)), 'All Years') AS Year,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(*) AS Orders,
    SUM(o.TotalAmount) AS Revenue,
    CASE GROUPING_ID(c.Country, YEAR(o.OrderDate))
        WHEN 0 THEN 'Detail'
        WHEN 1 THEN 'Country Total'
        WHEN 2 THEN 'Year Total'
        WHEN 3 THEN 'Grand Total'
    END AS RowType
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY CUBE(c.Country, YEAR(o.OrderDate))
HAVING GROUPING_ID(c.Country, YEAR(o.OrderDate)) IN (0, 1, 3)  -- Exclude year-only totals
ORDER BY 
    GROUPING(c.Country),
    Country,
    GROUPING(YEAR(o.OrderDate)),
    Year;


/*
============================================================================
PART 6: Advanced Techniques
============================================================================
*/

-- Example 6.1: Partial ROLLUP (some columns outside rollup)
SELECT 
    CategoryID,  -- Always grouped
    YEAR(CreatedDate) AS Year,
    MONTH(CreatedDate) AS Month,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID, ROLLUP(YEAR(CreatedDate), MONTH(CreatedDate))
-- Creates rollup only for Year and Month, not CategoryID
ORDER BY CategoryID, Year, Month;

-- Example 6.2: Combining ROLLUP and expressions
SELECT 
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceRange,
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    CASE 
        WHEN GROUPING(CategoryID) = 1 THEN '** Total **'
        ELSE ''
    END AS Label
FROM Products
GROUP BY 
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END,
    ROLLUP(CategoryID)
ORDER BY PriceRange, CategoryID;

-- Example 6.3: Using GROUPING for conditional formatting
SELECT 
    CASE WHEN GROUPING(CategoryID) = 1 THEN '*** TOTAL ***' 
         ELSE CAST(CategoryID AS VARCHAR(10)) END AS Category,
    CASE WHEN GROUPING(SupplierID) = 1 THEN '** All **' 
         ELSE CAST(SupplierID AS VARCHAR(10)) END AS Supplier,
    COUNT(*) AS ProductCount,
    FORMAT(SUM(Price * Stock), 'C', 'en-US') AS InventoryValue
FROM Products
GROUP BY ROLLUP(CategoryID, SupplierID)
ORDER BY 
    CASE WHEN GROUPING(CategoryID) = 1 THEN 9999 ELSE CategoryID END,
    CASE WHEN GROUPING(SupplierID) = 1 THEN 9999 ELSE SupplierID END;


/*
============================================================================
PART 7: Performance Considerations
============================================================================
*/

-- Example 7.1: ROLLUP is more efficient than UNION ALL
-- ❌ LESS EFFICIENT:
SELECT CategoryID, SupplierID, COUNT(*) FROM Products GROUP BY CategoryID, SupplierID
UNION ALL
SELECT CategoryID, NULL, COUNT(*) FROM Products GROUP BY CategoryID
UNION ALL
SELECT NULL, NULL, COUNT(*) FROM Products;

-- ✅ MORE EFFICIENT:
SELECT CategoryID, SupplierID, COUNT(*)
FROM Products
GROUP BY ROLLUP(CategoryID, SupplierID);

-- Example 7.2: CUBE can be expensive with many columns
-- Each column doubles the number of grouping combinations!
-- 2 columns = 4 combinations (2^2)
-- 3 columns = 8 combinations (2^3)
-- 4 columns = 16 combinations (2^4)
-- Use GROUPING SETS for specific combinations instead


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a sales report with ROLLUP by Year and Month
2. Use CUBE to analyze products by Category and Price Range
3. Use GROUPING SETS for custom Year and Customer analysis
4. Identify subtotal rows using GROUPING()
5. Create formatted report with proper labels

Solutions below ↓
*/

-- Solution 1:
SELECT 
    COALESCE(CAST(YEAR(OrderDate) AS VARCHAR(10)), 'TOTAL') AS Year,
    COALESCE(CAST(MONTH(OrderDate) AS VARCHAR(10)), 'All') AS Month,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrder
FROM Orders
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate))
ORDER BY Year, Month;

-- Solution 2:
SELECT 
    COALESCE(CAST(CategoryID AS VARCHAR(10)), 'All Categories') AS Category,
    COALESCE(
        CASE 
            WHEN Price < 50 THEN 'Budget'
            WHEN Price < 100 THEN 'Standard'
            ELSE 'Premium'
        END, 
        'All Prices'
    ) AS PriceRange,
    COUNT(*) AS Products,
    AVG(Price) AS AvgPrice,
    SUM(Stock) AS TotalStock
FROM Products
GROUP BY CUBE(
    CategoryID,
    CASE 
        WHEN Price < 50 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END
)
ORDER BY Category, PriceRange;

-- Solution 3:
SELECT 
    YEAR(OrderDate) AS Year,
    CustomerID,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    CASE GROUPING_ID(YEAR(OrderDate), CustomerID)
        WHEN 0 THEN 'Detail'
        WHEN 1 THEN 'Year Total'
        WHEN 2 THEN 'Customer Total'
        WHEN 3 THEN 'Grand Total'
    END AS Level
FROM Orders
GROUP BY GROUPING SETS (
    (YEAR(OrderDate), CustomerID),
    (YEAR(OrderDate)),
    (CustomerID),
    ()
)
ORDER BY Year, CustomerID;

-- Solution 4:
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    GROUPING(CategoryID) AS IsSubtotal,
    CASE WHEN GROUPING(CategoryID) = 1 THEN 'YES' ELSE 'NO' END AS SubtotalRow
FROM Products
GROUP BY ROLLUP(CategoryID)
ORDER BY CategoryID;

-- Solution 5:
SELECT 
    CASE WHEN GROUPING(YEAR(OrderDate)) = 1 THEN '=== GRAND TOTAL ===' 
         ELSE CAST(YEAR(OrderDate) AS VARCHAR(20)) END AS Year,
    CASE WHEN GROUPING(MONTH(OrderDate)) = 1 AND GROUPING(YEAR(OrderDate)) = 0 
         THEN '** Year Subtotal **'
         WHEN GROUPING(MONTH(OrderDate)) = 1 THEN ''
         ELSE DATENAME(MONTH, DATEFROMPARTS(2000, MONTH(OrderDate), 1)) END AS Month,
    FORMAT(COUNT(*), 'N0') AS Orders,
    FORMAT(SUM(TotalAmount), 'C', 'en-US') AS Revenue,
    FORMAT(AVG(TotalAmount), 'C', 'en-US') AS AvgOrder
FROM Orders
GROUP BY ROLLUP(YEAR(OrderDate), MONTH(OrderDate))
ORDER BY 
    GROUPING(YEAR(OrderDate)),
    YEAR(OrderDate),
    GROUPING(MONTH(OrderDate)),
    MONTH(OrderDate);


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ ROLLUP:
  • Creates hierarchical subtotals (right to left)
  • N columns = N+1 grouping levels
  • Use for year > month > day hierarchies

✓ CUBE:
  • All possible combinations
  • N columns = 2^N grouping levels
  • Use for cross-tabulation analysis

✓ GROUPING SETS:
  • Specify exact combinations you want
  • More efficient than UNION ALL
  • Use when you don't need all combinations

✓ GROUPING() FUNCTION:
  • Returns 0 if column is grouped
  • Returns 1 if column is NULL due to rollup
  • Use to identify subtotal rows

✓ GROUPING_ID() FUNCTION:
  • Returns bitmap of GROUPING() values
  • Unique number for each grouping level
  • Use for complex level identification

✓ BEST PRACTICES:
  • Use COALESCE/CASE for readable labels
  • Order by GROUPING() for logical display
  • Consider performance with CUBE
  • Format subtotals for clarity

============================================================================
NEXT: Lesson 08.12 - Test Your Knowledge
Comprehensive assessment of grouping and aggregate concepts.
============================================================================
*/
