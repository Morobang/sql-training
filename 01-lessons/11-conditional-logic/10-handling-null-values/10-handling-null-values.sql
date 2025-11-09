/*
============================================================================
Lesson 11.10 - Handling NULL Values
============================================================================

Description:
Master NULL handling with CASE expressions, COALESCE, ISNULL, and NULLIF.
Learn NULL detection, replacement strategies, three-valued logic, and
best practices for working with unknown or missing data.

Topics Covered:
• NULL fundamentals and three-valued logic
• CASE for NULL detection
• COALESCE function
• ISNULL vs COALESCE
• NULLIF function
• NULL in calculations
• NULL in sorting
• Complex NULL scenarios

Prerequisites:
• Lessons 11.01-11.09

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: NULL Fundamentals
============================================================================
*/

-- Example 1.1: Understanding NULL
SELECT 
    NULL AS Value1,
    NULL = NULL AS Comparison1,      -- NULL (not TRUE!)
    NULL <> NULL AS Comparison2,     -- NULL (not FALSE!)
    NULL IS NULL AS Comparison3,     -- TRUE (correct way)
    NULL IS NOT NULL AS Comparison4; -- FALSE

/*
Three-Valued Logic:
• TRUE
• FALSE
• UNKNOWN (represented by NULL)

Key Points:
• NULL = NULL returns NULL (not TRUE)
• Use IS NULL or IS NOT NULL for NULL checks
• NULL in any comparison returns NULL
• NULL in boolean expression treated as FALSE
*/

-- Example 1.2: NULL in WHERE Clause
CREATE TABLE #TestData (
    ID INT,
    Value1 INT,
    Value2 INT
);

INSERT INTO #TestData VALUES
(1, 10, 20),
(2, NULL, 30),
(3, 40, NULL),
(4, NULL, NULL);

-- NULL comparisons don't work as expected
SELECT * FROM #TestData WHERE Value1 = NULL;  -- Returns nothing!
SELECT * FROM #TestData WHERE Value1 IS NULL; -- Correct way

-- NULL in calculations
SELECT 
    ID,
    Value1,
    Value2,
    Value1 + Value2 AS Sum,           -- NULL if either is NULL
    Value1 * Value2 AS Product        -- NULL if either is NULL
FROM #TestData;

/*
NULL in Arithmetic:
• Any operation with NULL returns NULL
• NULL + 10 = NULL
• NULL * 5 = NULL
• 100 / NULL = NULL
*/

DROP TABLE #TestData;


/*
============================================================================
PART 2: CASE for NULL Detection
============================================================================
*/

-- Example 2.1: Basic NULL Detection
SELECT 
    OrderID,
    ShipDate,
    DeliveryDate,
    CASE 
        WHEN DeliveryDate IS NULL THEN 'Not Delivered'
        ELSE 'Delivered'
    END AS DeliveryStatus,
    CASE 
        WHEN ShipDate IS NULL THEN 'Not Shipped'
        WHEN DeliveryDate IS NULL THEN 'In Transit'
        ELSE 'Completed'
    END AS OrderStatus
FROM Orders
WHERE OrderID <= 20;

-- Example 2.2: Multiple NULL Checks
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DeliveryDate,
    CASE 
        WHEN ShipDate IS NULL AND DeliveryDate IS NULL THEN 'Processing'
        WHEN ShipDate IS NOT NULL AND DeliveryDate IS NULL THEN 'Shipped'
        WHEN DeliveryDate IS NOT NULL THEN 'Delivered'
        ELSE 'Unknown'
    END AS Status,
    CASE 
        WHEN ShipDate IS NULL THEN 'No ship date recorded'
        WHEN DeliveryDate IS NULL THEN 'Awaiting delivery'
        ELSE 'Process complete'
    END AS Notes
FROM Orders
WHERE OrderID <= 15;

-- Example 2.3: NULL Categorization
SELECT 
    ProductID,
    ProductName,
    Price,
    UnitsInStock,
    ReorderLevel,
    CASE 
        WHEN Price IS NULL THEN 'Price Not Set'
        WHEN UnitsInStock IS NULL THEN 'Stock Unknown'
        WHEN ReorderLevel IS NULL THEN 'Reorder Level Not Set'
        WHEN Price IS NOT NULL AND UnitsInStock IS NOT NULL AND ReorderLevel IS NOT NULL 
            THEN 'Complete Data'
        ELSE 'Partial Data'
    END AS DataQuality
FROM Products
WHERE ProductID <= 15;


/*
============================================================================
PART 3: COALESCE Function
============================================================================
*/

-- Example 3.1: COALESCE Basics
-- COALESCE returns first non-NULL value
SELECT 
    COALESCE(NULL, NULL, 'Third', 'Fourth') AS Result1,  -- 'Third'
    COALESCE(NULL, 'Second', 'Third') AS Result2,        -- 'Second'
    COALESCE('First', 'Second') AS Result3,              -- 'First'
    COALESCE(NULL, NULL, NULL) AS Result4;               -- NULL

-- Example 3.2: Providing Default Values
SELECT 
    OrderID,
    ShipDate,
    DeliveryDate,
    COALESCE(DeliveryDate, ShipDate, OrderDate) AS MostRecentDate,
    COALESCE(
        CONVERT(VARCHAR, DeliveryDate, 101), 
        CONVERT(VARCHAR, ShipDate, 101), 
        'Not Shipped'
    ) AS DisplayDate
FROM Orders
WHERE OrderID <= 10;

-- Example 3.3: NULL Replacement in Calculations
CREATE TABLE #SalesData (
    ProductID INT,
    ProductName VARCHAR(50),
    UnitsSold INT,
    UnitsReturned INT,
    Revenue DECIMAL(10,2)
);

INSERT INTO #SalesData VALUES
(1, 'Product A', 100, 5, 5000),
(2, 'Product B', NULL, NULL, NULL),
(3, 'Product C', 75, NULL, 3750);

SELECT 
    ProductName,
    UnitsSold,
    UnitsReturned,
    Revenue,
    -- Safe calculations with COALESCE
    COALESCE(UnitsSold, 0) AS UnitsSold_Safe,
    COALESCE(UnitsReturned, 0) AS UnitsReturned_Safe,
    COALESCE(UnitsSold, 0) - COALESCE(UnitsReturned, 0) AS NetSales,
    COALESCE(Revenue, 0) AS Revenue_Safe
FROM #SalesData;

DROP TABLE #SalesData;

-- Example 3.4: COALESCE for Display Formatting
SELECT 
    c.CustomerID,
    c.CustomerName,
    COALESCE(c.Phone, c.Email, 'No Contact Info') AS PreferredContact,
    COALESCE(c.City + ', ' + c.State, c.City, c.State, 'Unknown Location') AS Location,
    COUNT(o.OrderID) AS OrderCount,
    COALESCE(SUM(o.TotalAmount), 0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 10
GROUP BY c.CustomerID, c.CustomerName, c.Phone, c.Email, c.City, c.State;


/*
============================================================================
PART 4: ISNULL vs COALESCE
============================================================================
*/

-- Example 4.1: ISNULL Basics
-- ISNULL(expression, replacement) - returns replacement if expression is NULL
SELECT 
    ISNULL(NULL, 'Replacement') AS Result1,      -- 'Replacement'
    ISNULL('Value', 'Replacement') AS Result2,   -- 'Value'
    ISNULL(NULL, 0) AS Result3;                  -- 0

-- Example 4.2: ISNULL vs COALESCE Syntax
SELECT 
    ProductID,
    ProductName,
    Price,
    -- ISNULL: Only 2 arguments
    ISNULL(Price, 0) AS Price_ISNULL,
    -- COALESCE: Multiple arguments
    COALESCE(Price, 0) AS Price_COALESCE
FROM Products
WHERE ProductID <= 10;

-- Example 4.3: Data Type Differences
SELECT 
    -- ISNULL uses first argument's data type
    ISNULL(NULL, 1.5) AS ISNULL_Result,      -- INT: 1
    -- COALESCE uses highest precedence data type
    COALESCE(NULL, 1.5) AS COALESCE_Result;  -- DECIMAL: 1.5

/*
ISNULL vs COALESCE:

┌─────────────────┬──────────────┬────────────────┐
│   Feature       │   ISNULL     │   COALESCE     │
├─────────────────┼──────────────┼────────────────┤
│ Arguments       │ 2 only       │ 2 or more      │
│ Standard        │ T-SQL only   │ ANSI SQL       │
│ Data Type       │ First arg    │ Highest prec.  │
│ Evaluation      │ Once         │ Multiple times │
│ Readability     │ Simple       │ Flexible       │
└─────────────────┴──────────────┴────────────────┘

Recommendation:
• ISNULL: Simple 2-value replacement, T-SQL environment
• COALESCE: Multiple fallbacks, portability required
*/

-- Example 4.4: Multiple Fallbacks (COALESCE Advantage)
SELECT 
    OrderID,
    ShipDate,
    DeliveryDate,
    -- ISNULL: Nested for multiple values
    ISNULL(DeliveryDate, ISNULL(ShipDate, OrderDate)) AS Date_ISNULL,
    -- COALESCE: Clean multiple fallbacks
    COALESCE(DeliveryDate, ShipDate, OrderDate) AS Date_COALESCE
FROM Orders
WHERE OrderID <= 10;


/*
============================================================================
PART 5: NULLIF Function
============================================================================
*/

-- Example 5.1: NULLIF Basics
-- NULLIF(expr1, expr2) returns NULL if expr1 = expr2, else returns expr1
SELECT 
    NULLIF(10, 10) AS Result1,  -- NULL (values equal)
    NULLIF(10, 5) AS Result2,   -- 10 (values different)
    NULLIF('A', 'B') AS Result3; -- 'A' (values different)

-- Example 5.2: Division by Zero Prevention
SELECT 
    p.ProductID,
    p.ProductName,
    p.UnitsInStock,
    p.ReorderLevel,
    -- Safe division
    p.UnitsInStock / NULLIF(p.ReorderLevel, 0) AS StockRatio,
    -- With default value
    COALESCE(p.UnitsInStock / NULLIF(p.ReorderLevel, 0), 0) AS StockRatio_Safe
FROM Products
WHERE p.ProductID <= 10;

-- Example 5.3: Converting Specific Values to NULL
CREATE TABLE #EmployeeData (
    EmployeeID INT,
    EmployeeName VARCHAR(50),
    Salary DECIMAL(10,2),
    Department VARCHAR(50)
);

INSERT INTO #EmployeeData VALUES
(1, 'Alice', 50000, 'Sales'),
(2, 'Bob', 0, 'Unknown'),
(3, 'Charlie', -1, 'N/A');

-- Convert sentinel values to NULL
SELECT 
    EmployeeName,
    NULLIF(Salary, 0) AS Salary_Clean1,         -- Convert 0 to NULL
    NULLIF(NULLIF(Salary, 0), -1) AS Salary_Clean2,  -- Convert 0 and -1 to NULL
    NULLIF(Department, 'Unknown') AS Dept_Clean1,
    NULLIF(NULLIF(Department, 'Unknown'), 'N/A') AS Dept_Clean2
FROM #EmployeeData;

DROP TABLE #EmployeeData;

-- Example 5.4: Practical Use Cases
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalSpent,
    -- Average only if customer has orders (exclude 0)
    SUM(o.TotalAmount) / NULLIF(COUNT(o.OrderID), 0) AS AvgOrderValue,
    -- With COALESCE default
    COALESCE(
        SUM(o.TotalAmount) / NULLIF(COUNT(o.OrderID), 0),
        0
    ) AS AvgOrderValue_WithDefault
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 10
GROUP BY c.CustomerID, c.CustomerName;


/*
============================================================================
PART 6: NULL in Calculations
============================================================================
*/

-- Example 6.1: Arithmetic with NULL
SELECT 
    OrderID,
    TotalAmount,
    NULL AS Tax,
    TotalAmount + NULL AS GrandTotal,        -- NULL
    TotalAmount * NULL AS Doubled,           -- NULL
    COALESCE(TotalAmount + NULL, TotalAmount) AS Safe_Total
FROM Orders
WHERE OrderID <= 5;

-- Example 6.2: Aggregates and NULL
CREATE TABLE #ScoreData (
    StudentID INT,
    StudentName VARCHAR(50),
    Score INT
);

INSERT INTO #ScoreData VALUES
(1, 'Alice', 95),
(2, 'Bob', NULL),
(3, 'Charlie', 85),
(4, 'David', NULL);

SELECT 
    COUNT(*) AS Total_Students,
    COUNT(Score) AS Students_With_Scores,     -- Ignores NULLs
    SUM(Score) AS Total_Points,               -- Ignores NULLs
    AVG(Score) AS Average_Score,              -- Ignores NULLs
    AVG(COALESCE(Score, 0)) AS Average_Including_Zeros
FROM #ScoreData;

/*
Aggregate Functions and NULL:
• COUNT(*): Counts all rows including NULLs
• COUNT(column): Counts non-NULL values only
• SUM, AVG, MIN, MAX: Ignore NULL values
• Be careful: AVG(column) ≠ AVG(COALESCE(column, 0))
*/

DROP TABLE #ScoreData;

-- Example 6.3: Conditional Calculations with NULL
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    p.UnitsInStock,
    CASE 
        WHEN p.Price IS NULL OR p.UnitsInStock IS NULL THEN NULL
        ELSE p.Price * p.UnitsInStock
    END AS InventoryValue,
    -- Alternative with NULLIF
    (COALESCE(p.Price, 0) * COALESCE(p.UnitsInStock, 0)) AS InventoryValue_Safe
FROM Products
WHERE p.ProductID <= 10;


/*
============================================================================
PART 7: NULL in Sorting
============================================================================
*/

-- Example 7.1: Default NULL Sorting
SELECT 
    OrderID,
    ShipDate,
    DeliveryDate
FROM Orders
WHERE OrderID <= 20
ORDER BY ShipDate;  -- NULLs first by default

-- Example 7.2: NULLs Last
SELECT 
    OrderID,
    ShipDate,
    DeliveryDate
FROM Orders
WHERE OrderID <= 20
ORDER BY 
    CASE WHEN ShipDate IS NULL THEN 1 ELSE 0 END,  -- NULLs last
    ShipDate;

-- Example 7.3: Custom NULL Sorting
SELECT 
    ProductID,
    ProductName,
    Price
FROM Products
WHERE ProductID <= 15
ORDER BY 
    CASE 
        WHEN Price IS NULL THEN 3      -- NULLs last
        WHEN Price > 100 THEN 1        -- High prices first
        ELSE 2                          -- Low prices middle
    END,
    Price DESC;

-- Example 7.4: COALESCE for Sorting
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DeliveryDate,
    COALESCE(DeliveryDate, ShipDate, OrderDate) AS SortDate
FROM Orders
WHERE OrderID <= 15
ORDER BY SortDate DESC;


/*
============================================================================
PART 8: Complex NULL Scenarios
============================================================================
*/

-- Example 8.1: NULL in Joins
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    CASE 
        WHEN COUNT(o.OrderID) = 0 THEN 'No Orders'
        WHEN COUNT(o.OrderID) < 5 THEN 'Few Orders'
        ELSE 'Regular Customer'
    END AS CustomerType,
    COALESCE(SUM(o.TotalAmount), 0) AS TotalSpent
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.CustomerID <= 10
GROUP BY c.CustomerID, c.CustomerName;

-- Example 8.2: NULL Handling in Subqueries
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    (SELECT AVG(Price) FROM Products) AS AvgPrice,
    CASE 
        WHEN p.Price IS NULL THEN 'Price Not Set'
        WHEN p.Price > (SELECT AVG(Price) FROM Products) THEN 'Above Average'
        ELSE 'Below Average'
    END AS PricePosition
FROM Products p
WHERE p.ProductID <= 15;

-- Example 8.3: Comprehensive NULL Strategy
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        c.Email,
        c.Phone,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE c.CustomerID <= 15
    GROUP BY c.CustomerID, c.CustomerName, c.Email, c.Phone
)
SELECT 
    CustomerName,
    COALESCE(Email, Phone, 'No Contact') AS Contact,
    COALESCE(OrderCount, 0) AS Orders,
    COALESCE(TotalSpent, 0) AS Spent,
    COALESCE(CONVERT(VARCHAR, LastOrderDate, 101), 'Never') AS LastOrder,
    CASE 
        WHEN OrderCount IS NULL OR OrderCount = 0 THEN 'Never Purchased'
        WHEN LastOrderDate IS NULL THEN 'Data Error'
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) > 180 THEN 'Inactive'
        ELSE 'Active'
    END AS Status,
    COALESCE(
        TotalSpent / NULLIF(OrderCount, 0),
        0
    ) AS AvgOrderValue
FROM CustomerMetrics
ORDER BY Status, Orders DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Handle NULL values in a product catalog with price, stock, and category
2. Calculate completion rates with NULL-safe division
3. Create a customer contact preference system handling NULLs
4. Build a data quality report identifying NULL patterns
5. Design a NULL replacement strategy for a sales report

Solutions below ↓
*/

-- Solution 1: Product Catalog NULL Handling
SELECT 
    ProductID,
    ProductName,
    COALESCE(CAST(Price AS VARCHAR), 'TBD') AS DisplayPrice,
    COALESCE(UnitsInStock, 0) AS Stock,
    ISNULL(CategoryID, 0) AS Category,
    CASE 
        WHEN Price IS NULL THEN 'Incomplete: No Price'
        WHEN UnitsInStock IS NULL THEN 'Incomplete: No Stock Info'
        WHEN CategoryID IS NULL THEN 'Incomplete: No Category'
        ELSE 'Complete'
    END AS DataQuality
FROM Products
WHERE ProductID <= 15;

-- Solution 2: Completion Rates
CREATE TABLE #TaskData (TaskID INT, Attempted INT, Completed INT);
INSERT INTO #TaskData VALUES (1, 100, 85), (2, 0, 0), (3, NULL, NULL);

SELECT 
    TaskID,
    COALESCE(Attempted, 0) AS Attempted,
    COALESCE(Completed, 0) AS Completed,
    COALESCE(
        ROUND(Completed * 100.0 / NULLIF(Attempted, 0), 2),
        0
    ) AS CompletionRate_Pct,
    CASE 
        WHEN Attempted IS NULL THEN 'No Data'
        WHEN Attempted = 0 THEN 'Not Started'
        WHEN Completed * 100.0 / Attempted >= 80 THEN 'Excellent'
        WHEN Completed * 100.0 / Attempted >= 60 THEN 'Good'
        ELSE 'Poor'
    END AS Performance
FROM #TaskData;

DROP TABLE #TaskData;

-- Solution 3: Contact Preference
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Phone,
    CASE 
        WHEN Email IS NOT NULL AND Phone IS NOT NULL THEN 'Both Available'
        WHEN Email IS NOT NULL THEN 'Email Only'
        WHEN Phone IS NOT NULL THEN 'Phone Only'
        ELSE 'No Contact Info'
    END AS ContactAvailability,
    COALESCE(Email, Phone, 'No contact on file') AS PreferredContact
FROM Customers
WHERE CustomerID <= 10;

-- Solution 4: Data Quality Report
SELECT 
    'Products' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS Price_Nulls,
    SUM(CASE WHEN UnitsInStock IS NULL THEN 1 ELSE 0 END) AS Stock_Nulls,
    SUM(CASE WHEN CategoryID IS NULL THEN 1 ELSE 0 END) AS Category_Nulls,
    ROUND(
        SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS Price_NULL_Pct
FROM Products;

-- Solution 5: (see Example 8.3 in lesson)


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ NULL FUNDAMENTALS:
  • NULL represents unknown or missing data
  • Three-valued logic: TRUE, FALSE, UNKNOWN
  • NULL = NULL returns NULL (not TRUE)
  • Use IS NULL and IS NOT NULL for checks
  • NULL in arithmetic returns NULL

✓ CASE FOR NULL:
  • CASE WHEN column IS NULL THEN ... END
  • Explicit NULL handling
  • Multiple NULL checks with AND/OR
  • Custom NULL replacement logic

✓ COALESCE:
  • Returns first non-NULL value
  • Multiple arguments (2+)
  • ANSI SQL standard (portable)
  • Data type: highest precedence
  • Best for multiple fallbacks

✓ ISNULL:
  • Returns replacement if NULL
  • Exactly 2 arguments
  • T-SQL specific
  • Data type: first argument
  • Best for simple replacement

✓ NULLIF:
  • Converts specific value to NULL
  • NULLIF(expr, value_to_nullify)
  • Essential for division by zero
  • Sentinel value cleanup

✓ NULL IN CALCULATIONS:
  • Any arithmetic with NULL = NULL
  • COUNT(*) includes NULLs
  • COUNT(column) excludes NULLs
  • SUM, AVG, MIN, MAX ignore NULLs
  • Use COALESCE for safe math

✓ NULL IN SORTING:
  • NULLs first by default
  • Use CASE for custom sort
  • COALESCE for substitute values

✓ BEST PRACTICES:
  • Decide: NULL or default value?
  • Document NULL handling strategy
  • Be consistent across application
  • Test NULL edge cases
  • Consider database constraints
  • Use NOT NULL when possible
  • Validate data quality

✓ COMMON PATTERNS:
  • Division: expr / NULLIF(denom, 0)
  • Default: COALESCE(expr, default)
  • Multiple fallbacks: COALESCE(a, b, c, d)
  • Cleanup: NULLIF(column, sentinel_value)
  • Display: CASE WHEN x IS NULL THEN 'N/A' END

✓ PERFORMANCE:
  • NULL checks are fast (indexed)
  • COALESCE evaluated left-to-right
  • Avoid unnecessary NULL conversions
  • Consider computed columns
  • Index NULL-able columns carefully

============================================================================
NEXT: Lesson 11.11 - Test Your Knowledge
Comprehensive assessment of conditional logic concepts.
============================================================================
*/
