/*
============================================================================
Lesson 11.06 - Result Set Transformations
============================================================================

Description:
Master data pivoting and result set transformations using CASE expressions.
Learn to convert rows to columns (pivot), columns to rows (unpivot), create
cross-tabulation reports, conditional aggregation, and compare with PIVOT/UNPIVOT.

Topics Covered:
• Manual pivoting with CASE
• Cross-tabulation reports
• Conditional aggregation
• PIVOT operator
• UNPIVOT operator
• Dynamic pivot queries
• Sparse vs dense pivots

Prerequisites:
• Lessons 11.01-11.05

Estimated Time: 45 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Manual Pivoting with CASE
============================================================================
*/

-- Example 1.1: Basic Row-to-Column Transformation
-- Convert order data by month into columns
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(CASE WHEN MONTH(OrderDate) = 1 THEN TotalAmount ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(OrderDate) = 2 THEN TotalAmount ELSE 0 END) AS Feb,
    SUM(CASE WHEN MONTH(OrderDate) = 3 THEN TotalAmount ELSE 0 END) AS Mar,
    SUM(CASE WHEN MONTH(OrderDate) = 4 THEN TotalAmount ELSE 0 END) AS Apr,
    SUM(CASE WHEN MONTH(OrderDate) = 5 THEN TotalAmount ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(OrderDate) = 6 THEN TotalAmount ELSE 0 END) AS Jun,
    SUM(CASE WHEN MONTH(OrderDate) = 7 THEN TotalAmount ELSE 0 END) AS Jul,
    SUM(CASE WHEN MONTH(OrderDate) = 8 THEN TotalAmount ELSE 0 END) AS Aug,
    SUM(CASE WHEN MONTH(OrderDate) = 9 THEN TotalAmount ELSE 0 END) AS Sep,
    SUM(CASE WHEN MONTH(OrderDate) = 10 THEN TotalAmount ELSE 0 END) AS Oct,
    SUM(CASE WHEN MONTH(OrderDate) = 11 THEN TotalAmount ELSE 0 END) AS Nov,
    SUM(CASE WHEN MONTH(OrderDate) = 12 THEN TotalAmount ELSE 0 END) AS Dec
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

/*
Execution Flow:
1. Group orders by year
2. For each month, sum amounts where month matches
3. Non-matching months contribute 0
4. Result: one row per year, one column per month

Visual:
Original Data:          Pivoted Result:
Year | Month | Amount   Year | Jan | Feb | Mar ...
2024 | 1     | 100      2024 | 100 | 200 | 150 ...
2024 | 2     | 200
2024 | 3     | 150
*/

-- Example 1.2: Category Sales by Quarter
SELECT 
    c.CategoryName,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 1 THEN od.Quantity * od.Price ELSE 0 END) AS Q1_Sales,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 2 THEN od.Quantity * od.Price ELSE 0 END) AS Q2_Sales,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 3 THEN od.Quantity * od.Price ELSE 0 END) AS Q3_Sales,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 4 THEN od.Quantity * od.Price ELSE 0 END) AS Q4_Sales,
    SUM(od.Quantity * od.Price) AS Total_Sales
FROM Categories c
INNER JOIN Products p ON c.CategoryID = p.CategoryID
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY c.CategoryName
ORDER BY Total_Sales DESC;

-- Example 1.3: Count Pivot (Non-Numeric Aggregation)
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(CASE WHEN MONTH(OrderDate) = 1 THEN OrderID END) AS Jan_Orders,
    COUNT(CASE WHEN MONTH(OrderDate) = 2 THEN OrderID END) AS Feb_Orders,
    COUNT(CASE WHEN MONTH(OrderDate) = 3 THEN OrderID END) AS Mar_Orders,
    COUNT(CASE WHEN MONTH(OrderDate) = 4 THEN OrderID END) AS Apr_Orders,
    COUNT(CASE WHEN MONTH(OrderDate) = 5 THEN OrderID END) AS May_Orders,
    COUNT(CASE WHEN MONTH(OrderDate) = 6 THEN OrderID END) AS Jun_Orders,
    COUNT(*) AS Total_Orders
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

/*
Important: COUNT ignores NULL values
• CASE WHEN ... THEN OrderID END returns NULL when condition is false
• COUNT only counts non-NULL OrderIDs
• Don't use COUNT(CASE ... ELSE 0 END) - it counts the zeros!
*/


/*
============================================================================
PART 2: Cross-Tabulation Reports
============================================================================
*/

-- Example 2.1: Customer Segment by Order Value
WITH OrderSegments AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN TotalAmount < 100 THEN 'Small'
            WHEN TotalAmount < 500 THEN 'Medium'
            WHEN TotalAmount < 1000 THEN 'Large'
            ELSE 'VIP'
        END AS OrderSize
    FROM Orders
)
SELECT 
    CustomerID,
    COUNT(CASE WHEN OrderSize = 'Small' THEN 1 END) AS Small_Orders,
    COUNT(CASE WHEN OrderSize = 'Medium' THEN 1 END) AS Medium_Orders,
    COUNT(CASE WHEN OrderSize = 'Large' THEN 1 END) AS Large_Orders,
    COUNT(CASE WHEN OrderSize = 'VIP' THEN 1 END) AS VIP_Orders,
    COUNT(*) AS Total_Orders
FROM OrderSegments
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY Total_Orders DESC;

-- Example 2.2: Product Performance Matrix
SELECT 
    p.CategoryID,
    COUNT(DISTINCT p.ProductID) AS Total_Products,
    SUM(CASE WHEN p.Price < 50 THEN 1 ELSE 0 END) AS Budget_Products,
    SUM(CASE WHEN p.Price >= 50 AND p.Price < 150 THEN 1 ELSE 0 END) AS Mid_Products,
    SUM(CASE WHEN p.Price >= 150 THEN 1 ELSE 0 END) AS Premium_Products,
    AVG(CASE WHEN p.Price < 50 THEN p.Price END) AS Avg_Budget_Price,
    AVG(CASE WHEN p.Price >= 50 AND p.Price < 150 THEN p.Price END) AS Avg_Mid_Price,
    AVG(CASE WHEN p.Price >= 150 THEN p.Price END) AS Avg_Premium_Price
FROM Products p
GROUP BY p.CategoryID
ORDER BY p.CategoryID;

-- Example 2.3: Day of Week Analysis
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN TotalAmount < 100 THEN 1 ELSE 0 END) AS Small_Orders,
    SUM(CASE WHEN TotalAmount >= 100 AND TotalAmount < 500 THEN 1 ELSE 0 END) AS Medium_Orders,
    SUM(CASE WHEN TotalAmount >= 500 THEN 1 ELSE 0 END) AS Large_Orders,
    AVG(TotalAmount) AS Avg_Order_Value,
    SUM(TotalAmount) AS Total_Revenue
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY DATEPART(WEEKDAY, OrderDate);


/*
============================================================================
PART 3: Conditional Aggregation
============================================================================
*/

-- Example 3.1: Multi-Metric Pivot
SELECT 
    YEAR(o.OrderDate) AS Year,
    -- Counts
    COUNT(DISTINCT CASE WHEN MONTH(o.OrderDate) = 1 THEN o.OrderID END) AS Jan_Count,
    COUNT(DISTINCT CASE WHEN MONTH(o.OrderDate) = 2 THEN o.OrderID END) AS Feb_Count,
    -- Sums
    SUM(CASE WHEN MONTH(o.OrderDate) = 1 THEN o.TotalAmount ELSE 0 END) AS Jan_Sales,
    SUM(CASE WHEN MONTH(o.OrderDate) = 2 THEN o.TotalAmount ELSE 0 END) AS Feb_Sales,
    -- Averages
    AVG(CASE WHEN MONTH(o.OrderDate) = 1 THEN o.TotalAmount END) AS Jan_Avg,
    AVG(CASE WHEN MONTH(o.OrderDate) = 2 THEN o.TotalAmount END) AS Feb_Avg
FROM Orders o
GROUP BY YEAR(o.OrderDate)
ORDER BY Year;

-- Example 3.2: Conditional MIN/MAX
SELECT 
    CategoryID,
    MIN(CASE WHEN UnitsInStock > 0 THEN Price END) AS Lowest_InStock_Price,
    MAX(CASE WHEN UnitsInStock > 0 THEN Price END) AS Highest_InStock_Price,
    MIN(CASE WHEN UnitsInStock = 0 THEN Price END) AS Lowest_OutOfStock_Price,
    MAX(CASE WHEN UnitsInStock = 0 THEN Price END) AS Highest_OutOfStock_Price,
    AVG(CASE WHEN UnitsInStock > ReorderLevel THEN Price END) AS Avg_WellStocked_Price
FROM Products
GROUP BY CategoryID
ORDER BY CategoryID;

-- Example 3.3: Percentage Calculations with Conditional Aggregation
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN TotalAmount < 100 THEN 1 ELSE 0 END) AS Small_Orders,
    SUM(CASE WHEN TotalAmount >= 100 AND TotalAmount < 500 THEN 1 ELSE 0 END) AS Medium_Orders,
    SUM(CASE WHEN TotalAmount >= 500 THEN 1 ELSE 0 END) AS Large_Orders,
    -- Percentages
    ROUND(SUM(CASE WHEN TotalAmount < 100 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Pct_Small,
    ROUND(SUM(CASE WHEN TotalAmount >= 100 AND TotalAmount < 500 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Pct_Medium,
    ROUND(SUM(CASE WHEN TotalAmount >= 500 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Pct_Large
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;


/*
============================================================================
PART 4: PIVOT Operator
============================================================================
*/

-- Example 4.1: Basic PIVOT
SELECT *
FROM (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        TotalAmount
    FROM Orders
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS PivotTable
ORDER BY Year;

/*
PIVOT Syntax Breakdown:
1. SELECT * FROM (source_query) AS SourceData
   • Prepare data with: grouping column, pivot column, value column
2. PIVOT (aggregate_function(value_column) FOR pivot_column IN (values))
   • Specify aggregation and which values become columns
3. Column names in IN clause become actual column names
*/

-- Example 4.2: PIVOT with Aliases
SELECT 
    Year,
    [1] AS Jan, [2] AS Feb, [3] AS Mar, [4] AS Apr,
    [5] AS May, [6] AS Jun, [7] AS Jul, [8] AS Aug,
    [9] AS Sep, [10] AS Oct, [11] AS Nov, [12] AS Dec
FROM (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        TotalAmount
    FROM Orders
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS PivotTable
ORDER BY Year;

-- Example 4.3: PIVOT with Multiple Grouping Columns
SELECT 
    CategoryID,
    YEAR(OrderDate) AS Year,
    [1] AS Jan, [2] AS Feb, [3] AS Mar
FROM (
    SELECT 
        p.CategoryID,
        YEAR(o.OrderDate) AS OrderDate,
        MONTH(o.OrderDate) AS Month,
        od.Quantity * od.Price AS Sales
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
) AS SourceData
PIVOT (
    SUM(Sales)
    FOR Month IN ([1], [2], [3])
) AS PivotTable
ORDER BY CategoryID, Year;

-- Example 4.4: PIVOT with COUNT
SELECT 
    CustomerID,
    [Small] AS Small_Orders,
    [Medium] AS Medium_Orders,
    [Large] AS Large_Orders,
    [VIP] AS VIP_Orders
FROM (
    SELECT 
        CustomerID,
        CASE 
            WHEN TotalAmount < 100 THEN 'Small'
            WHEN TotalAmount < 500 THEN 'Medium'
            WHEN TotalAmount < 1000 THEN 'Large'
            ELSE 'VIP'
        END AS OrderSize,
        OrderID
    FROM Orders
) AS SourceData
PIVOT (
    COUNT(OrderID)
    FOR OrderSize IN ([Small], [Medium], [Large], [VIP])
) AS PivotTable
ORDER BY CustomerID;


/*
============================================================================
PART 5: UNPIVOT Operator
============================================================================
*/

-- Example 5.1: Create Pivoted Data First
CREATE TABLE #MonthlySales (
    Year INT,
    Jan DECIMAL(10,2),
    Feb DECIMAL(10,2),
    Mar DECIMAL(10,2),
    Apr DECIMAL(10,2)
);

INSERT INTO #MonthlySales VALUES
(2023, 10000, 12000, 11000, 13000),
(2024, 15000, 14000, 16000, 17000);

-- View pivoted data
SELECT * FROM #MonthlySales;

-- Example 5.2: UNPIVOT to Convert Columns to Rows
SELECT 
    Year,
    Month,
    Sales
FROM #MonthlySales
UNPIVOT (
    Sales FOR Month IN (Jan, Feb, Mar, Apr)
) AS UnpivotTable
ORDER BY Year, 
    CASE Month
        WHEN 'Jan' THEN 1
        WHEN 'Feb' THEN 2
        WHEN 'Mar' THEN 3
        WHEN 'Apr' THEN 4
    END;

/*
UNPIVOT Syntax:
UNPIVOT (
    value_column FOR pivot_column IN (column1, column2, ...)
)
• value_column: name for the values being unpivoted
• pivot_column: name for the column that identifies the source
• IN clause: list of columns to unpivot
*/

-- Example 5.3: UNPIVOT with Data Transformation
SELECT 
    Year,
    CASE Month
        WHEN 'Jan' THEN 1
        WHEN 'Feb' THEN 2
        WHEN 'Mar' THEN 3
        WHEN 'Apr' THEN 4
    END AS MonthNumber,
    Month AS MonthName,
    Sales,
    CASE 
        WHEN Sales > 15000 THEN 'Excellent'
        WHEN Sales > 12000 THEN 'Good'
        ELSE 'Fair'
    END AS Performance
FROM #MonthlySales
UNPIVOT (
    Sales FOR Month IN (Jan, Feb, Mar, Apr)
) AS UnpivotTable
ORDER BY Year, MonthNumber;

DROP TABLE #MonthlySales;


/*
============================================================================
PART 6: Dynamic Pivot Queries
============================================================================
*/

-- Example 6.1: Dynamic PIVOT with Variable Column List
DECLARE @Columns NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);

-- Build column list dynamically
SELECT @Columns = STRING_AGG(QUOTENAME(Month), ', ')
FROM (
    SELECT DISTINCT MONTH(OrderDate) AS Month
    FROM Orders
) AS Months;

-- Build and execute dynamic SQL
SET @SQL = '
SELECT Year, ' + @Columns + '
FROM (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        TotalAmount
    FROM Orders
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN (' + @Columns + ')
) AS PivotTable
ORDER BY Year';

-- View the generated SQL
PRINT @SQL;

-- Execute it
EXEC sp_executesql @SQL;

-- Example 6.2: Dynamic PIVOT with Category Names
DECLARE @CategoryColumns NVARCHAR(MAX);
DECLARE @CategorySQL NVARCHAR(MAX);

-- Get all category names
SELECT @CategoryColumns = STRING_AGG(QUOTENAME(CategoryName), ', ')
FROM Categories;

SET @CategorySQL = '
SELECT 
    YEAR(o.OrderDate) AS Year,
    ' + @CategoryColumns + '
FROM (
    SELECT 
        c.CategoryName,
        YEAR(o.OrderDate) AS OrderDate,
        od.Quantity * od.Price AS Sales
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
) AS SourceData
PIVOT (
    SUM(Sales)
    FOR CategoryName IN (' + @CategoryColumns + ')
) AS PivotTable
ORDER BY Year';

PRINT @CategorySQL;
EXEC sp_executesql @CategorySQL;


/*
============================================================================
PART 7: Sparse vs Dense Pivots
============================================================================
*/

-- Example 7.1: Sparse Pivot (with NULLs)
-- Not all customers have orders in all months
SELECT 
    CustomerID,
    [1] AS Jan, [2] AS Feb, [3] AS Mar, [4] AS Apr,
    [5] AS May, [6] AS Jun
FROM (
    SELECT 
        CustomerID,
        MONTH(OrderDate) AS Month,
        TotalAmount
    FROM Orders
    WHERE CustomerID <= 10
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1], [2], [3], [4], [5], [6])
) AS PivotTable
ORDER BY CustomerID;

-- Example 7.2: Dense Pivot (replacing NULLs)
SELECT 
    CustomerID,
    ISNULL([1], 0) AS Jan,
    ISNULL([2], 0) AS Feb,
    ISNULL([3], 0) AS Mar,
    ISNULL([4], 0) AS Apr,
    ISNULL([5], 0) AS May,
    ISNULL([6], 0) AS Jun
FROM (
    SELECT 
        CustomerID,
        MONTH(OrderDate) AS Month,
        TotalAmount
    FROM Orders
    WHERE CustomerID <= 10
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1], [2], [3], [4], [5], [6])
) AS PivotTable
ORDER BY CustomerID;

-- Example 7.3: Comparison - Manual CASE vs PIVOT Performance
-- Manual CASE method
SELECT 
    CustomerID,
    ISNULL(SUM(CASE WHEN MONTH(OrderDate) = 1 THEN TotalAmount END), 0) AS Jan,
    ISNULL(SUM(CASE WHEN MONTH(OrderDate) = 2 THEN TotalAmount END), 0) AS Feb,
    ISNULL(SUM(CASE WHEN MONTH(OrderDate) = 3 THEN TotalAmount END), 0) AS Mar
FROM Orders
WHERE CustomerID <= 10
GROUP BY CustomerID
ORDER BY CustomerID;

-- PIVOT method (same result)
SELECT 
    CustomerID,
    ISNULL([1], 0) AS Jan,
    ISNULL([2], 0) AS Feb,
    ISNULL([3], 0) AS Mar
FROM (
    SELECT CustomerID, MONTH(OrderDate) AS Month, TotalAmount
    FROM Orders
    WHERE CustomerID <= 10
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1], [2], [3])
) AS PivotTable
ORDER BY CustomerID;

/*
Manual CASE vs PIVOT:

CASE Method:
✓ More flexible (can use complex conditions)
✓ Works with older SQL Server versions
✓ Easier to debug
✓ Can combine different aggregations easily
✗ More verbose
✗ Harder to maintain with many columns

PIVOT Method:
✓ More concise
✓ Clearer intent
✓ Standard SQL (somewhat)
✗ Requires exact column values
✗ Less flexible
✗ Harder with dynamic columns (requires dynamic SQL)
*/


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a quarterly sales report by category using manual CASE
2. Build a customer purchase frequency matrix (low/medium/high value orders)
3. Use PIVOT to show product sales by day of week
4. Create an UNPIVOT query to normalize a wide table
5. Write a dynamic PIVOT for customer sales by year

Solutions below ↓
*/

-- Solution 1: Quarterly Sales by Category (Manual CASE)
SELECT 
    c.CategoryName,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 1 THEN od.Quantity * od.Price ELSE 0 END) AS Q1,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 2 THEN od.Quantity * od.Price ELSE 0 END) AS Q2,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 3 THEN od.Quantity * od.Price ELSE 0 END) AS Q3,
    SUM(CASE WHEN DATEPART(QUARTER, o.OrderDate) = 4 THEN od.Quantity * od.Price ELSE 0 END) AS Q4,
    SUM(od.Quantity * od.Price) AS Total
FROM Categories c
INNER JOIN Products p ON c.CategoryID = p.CategoryID
INNER JOIN OrderDetails od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY c.CategoryName
ORDER BY Total DESC;

-- Solution 2: Customer Purchase Frequency Matrix
WITH OrderCategories AS (
    SELECT 
        CustomerID,
        CASE 
            WHEN TotalAmount < 100 THEN 'Low'
            WHEN TotalAmount < 500 THEN 'Medium'
            ELSE 'High'
        END AS ValueCategory
    FROM Orders
)
SELECT 
    CustomerID,
    COUNT(*) AS Total_Orders,
    SUM(CASE WHEN ValueCategory = 'Low' THEN 1 ELSE 0 END) AS Low_Value,
    SUM(CASE WHEN ValueCategory = 'Medium' THEN 1 ELSE 0 END) AS Medium_Value,
    SUM(CASE WHEN ValueCategory = 'High' THEN 1 ELSE 0 END) AS High_Value
FROM OrderCategories
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY Total_Orders DESC;

-- Solution 3: Product Sales by Day of Week (PIVOT)
SELECT 
    ProductID,
    ISNULL([Monday], 0) AS Mon,
    ISNULL([Tuesday], 0) AS Tue,
    ISNULL([Wednesday], 0) AS Wed,
    ISNULL([Thursday], 0) AS Thu,
    ISNULL([Friday], 0) AS Fri,
    ISNULL([Saturday], 0) AS Sat,
    ISNULL([Sunday], 0) AS Sun
FROM (
    SELECT 
        od.ProductID,
        DATENAME(WEEKDAY, o.OrderDate) AS DayOfWeek,
        od.Quantity * od.Price AS Sales
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    WHERE od.ProductID <= 10
) AS SourceData
PIVOT (
    SUM(Sales)
    FOR DayOfWeek IN ([Monday], [Tuesday], [Wednesday], [Thursday], [Friday], [Saturday], [Sunday])
) AS PivotTable
ORDER BY ProductID;

-- Solution 4: (see lesson content)
-- Solution 5: (requires dynamic SQL - see Example 6.1)


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ MANUAL PIVOTING WITH CASE:
  • Use SUM(CASE WHEN ... THEN value ELSE 0 END) for sums
  • Use COUNT(CASE WHEN ... THEN 1 END) for counts (no ELSE!)
  • More flexible than PIVOT operator
  • Works with complex conditions

✓ CROSS-TABULATION:
  • Create matrix-style reports
  • Combine multiple dimensions
  • Use conditional aggregation
  • Calculate percentages and ratios

✓ PIVOT OPERATOR:
  • More concise than manual CASE
  • Requires source query with 3 columns (group, pivot, value)
  • Column values must be known at query time
  • Less flexible but clearer intent

✓ UNPIVOT OPERATOR:
  • Converts columns to rows
  • Normalizes wide tables
  • Useful for data import/export
  • Opposite of PIVOT

✓ DYNAMIC PIVOT:
  • Use STRING_AGG to build column lists
  • Requires dynamic SQL (sp_executesql)
  • More maintainable for changing data
  • Be cautious of SQL injection

✓ SPARSE VS DENSE:
  • Sparse: NULLs for missing combinations
  • Dense: Use ISNULL/COALESCE for 0 or defaults
  • Choose based on reporting requirements

✓ PERFORMANCE:
  • Manual CASE: single table scan
  • PIVOT: also single scan
  • Choose based on readability and maintenance
  • Dynamic SQL has compilation overhead

✓ WHEN TO USE WHICH:
  • Manual CASE: complex conditions, older SQL versions
  • PIVOT: simple pivots, clear structure
  • Dynamic PIVOT: unknown column values
  • UNPIVOT: normalizing imported data

============================================================================
NEXT: Lesson 11.07 - Checking for Existence
Learn to use CASE with EXISTS for conditional logic.
============================================================================
*/
