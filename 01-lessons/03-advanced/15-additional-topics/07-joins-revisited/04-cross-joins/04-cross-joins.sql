/*
============================================================================
Lesson 10.04 - Cross Joins
============================================================================

Description:
Master the Cartesian product with cross joins. Learn when to use them
intentionally for generating combinations, calendar tables, test data,
and analytical queries.

Topics Covered:
• Cross join fundamentals
• Cartesian product explained
• Practical applications
• Generating combinations
• Calendar and time series
• Performance considerations

Prerequisites:
• Lessons 10.01-10.03
• Understanding of result set sizes

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Cross Join Fundamentals
============================================================================
*/

-- Example 1.1: Basic CROSS JOIN syntax
SELECT 
    c.CategoryName,
    p.ProductName
FROM Categories c
CROSS JOIN Products p;

/*
Cartesian Product:
• Returns EVERY combination
• If Categories has 5 rows and Products has 20 rows
• Result has 5 × 20 = 100 rows
• No ON clause needed
*/

-- Example 1.2: Row count demonstration
SELECT 
    (SELECT COUNT(*) FROM Categories) AS CategoryCount,
    (SELECT COUNT(*) FROM Products) AS ProductCount,
    (SELECT COUNT(*) FROM Categories) * (SELECT COUNT(*) FROM Products) AS ExpectedRows,
    COUNT(*) AS ActualRows
FROM Categories
CROSS JOIN Products;

-- Example 1.3: Cross join with WHERE (filters result)
SELECT 
    c.CategoryName,
    p.ProductName
FROM Categories c
CROSS JOIN Products p
WHERE c.CategoryID = 1;  -- Still cross join, but filtered

-- Example 1.4: Implicit cross join (old syntax)
SELECT c.CategoryName, p.ProductName
FROM Categories c, Products p;  -- Comma = implicit CROSS JOIN


/*
============================================================================
PART 2: Generating Combinations
============================================================================
*/

-- Example 2.1: All product pairs
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2
FROM Products p1
CROSS JOIN Products p2
WHERE p1.ProductID < p2.ProductID  -- Avoid duplicates and self-pairs
ORDER BY p1.ProductName, p2.ProductName;

-- Example 2.2: Product recommendations (cross-sell opportunities)
SELECT 
    p1.ProductName AS MainProduct,
    p1.Price AS MainPrice,
    p2.ProductName AS SuggestedProduct,
    p2.Price AS SuggestedPrice,
    p1.Price + p2.Price AS BundlePrice
FROM Products p1
CROSS JOIN Products p2
WHERE p1.CategoryID <> p2.CategoryID  -- Different categories
  AND p1.ProductID < p2.ProductID
  AND p1.Price + p2.Price < 200  -- Affordable bundle
ORDER BY BundlePrice;

-- Example 2.3: Customer-Product matrix
SELECT 
    c.CustomerName,
    p.ProductName,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Orders o
            JOIN OrderDetails od ON o.OrderID = od.OrderID
            WHERE o.CustomerID = c.CustomerID 
            AND od.ProductID = p.ProductID
        ) THEN 'Purchased'
        ELSE 'Not Purchased'
    END AS PurchaseStatus
FROM Customers c
CROSS JOIN Products p
WHERE c.CustomerID <= 5  -- Limit for readability
  AND p.ProductID <= 10
ORDER BY c.CustomerName, p.ProductName;

-- Example 2.4: Size and color combinations
CREATE TABLE #Sizes (SizeName VARCHAR(10));
CREATE TABLE #Colors (ColorName VARCHAR(20));

INSERT INTO #Sizes VALUES ('Small'), ('Medium'), ('Large'), ('XLarge');
INSERT INTO #Colors VALUES ('Red'), ('Blue'), ('Green'), ('Black'), ('White');

SELECT 
    s.SizeName,
    c.ColorName,
    CONCAT(c.ColorName, ' - ', s.SizeName) AS Variant
FROM #Sizes s
CROSS JOIN #Colors c
ORDER BY c.ColorName, s.SizeName;

DROP TABLE #Sizes, #Colors;


/*
============================================================================
PART 3: Calendar and Time Series
============================================================================
*/

-- Example 3.1: Generate date range with numbers table
CREATE TABLE #Numbers (Number INT);
INSERT INTO #Numbers VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT 
    DATEADD(DAY, n1.Number + (n2.Number * 10), '2024-01-01') AS CalendarDate
FROM #Numbers n1
CROSS JOIN #Numbers n2  -- 10 × 10 = 100 days
WHERE n1.Number + (n2.Number * 10) < 31  -- January only
ORDER BY CalendarDate;

DROP TABLE #Numbers;

-- Example 3.2: Hour-by-hour schedule
CREATE TABLE #Hours (HourNum INT);
INSERT INTO #Hours SELECT TOP 24 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1
FROM sys.objects;

CREATE TABLE #Days (DayName VARCHAR(10));
INSERT INTO #Days VALUES ('Monday'), ('Tuesday'), ('Wednesday'), ('Thursday'), ('Friday');

SELECT 
    d.DayName,
    h.HourNum,
    CONCAT(h.HourNum, ':00') AS TimeSlot,
    CONCAT(d.DayName, ' ', h.HourNum, ':00') AS Schedule
FROM #Days d
CROSS JOIN #Hours h
WHERE h.HourNum BETWEEN 9 AND 17  -- Business hours
ORDER BY 
    CASE d.DayName
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
    END,
    h.HourNum;

DROP TABLE #Hours, #Days;

-- Example 3.3: Month-Year combinations
CREATE TABLE #Months (MonthNum INT, MonthName VARCHAR(10));
INSERT INTO #Months VALUES 
(1,'January'),(2,'February'),(3,'March'),(4,'April'),
(5,'May'),(6,'June'),(7,'July'),(8,'August'),
(9,'September'),(10,'October'),(11,'November'),(12,'December');

CREATE TABLE #Years (YearNum INT);
INSERT INTO #Years VALUES (2022), (2023), (2024);

SELECT 
    y.YearNum,
    m.MonthNum,
    m.MonthName,
    DATEFROMPARTS(y.YearNum, m.MonthNum, 1) AS FirstDayOfMonth
FROM #Years y
CROSS JOIN #Months m
ORDER BY y.YearNum, m.MonthNum;

DROP TABLE #Months, #Years;


/*
============================================================================
PART 4: Data Analysis and Reporting
============================================================================
*/

-- Example 4.1: Sales by customer-category matrix
SELECT 
    c.CustomerName,
    cat.CategoryName,
    ISNULL(SUM(od.Quantity * od.UnitPrice), 0) AS TotalSales
FROM Customers c
CROSS JOIN Categories cat
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
LEFT JOIN Products p ON od.ProductID = p.ProductID AND p.CategoryID = cat.CategoryID
WHERE c.CustomerID <= 10  -- Limit for readability
GROUP BY c.CustomerID, c.CustomerName, cat.CategoryID, cat.CategoryName
ORDER BY c.CustomerName, cat.CategoryName;

-- Example 4.2: Fill gaps in data
-- Show all days even if no orders
WITH DateRange AS (
    SELECT CAST('2024-01-01' AS DATE) AS OrderDate
    UNION ALL
    SELECT DATEADD(DAY, 1, OrderDate)
    FROM DateRange
    WHERE OrderDate < '2024-01-31'
)
SELECT 
    dr.OrderDate,
    COUNT(o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalRevenue
FROM DateRange dr
LEFT JOIN Orders o ON CAST(o.OrderDate AS DATE) = dr.OrderDate
GROUP BY dr.OrderDate
ORDER BY dr.OrderDate
OPTION (MAXRECURSION 31);

-- Example 4.3: Product availability matrix
SELECT 
    p.ProductName,
    c.CategoryName,
    CASE 
        WHEN p.CategoryID = c.CategoryID THEN 'Yes'
        ELSE 'No'
    END AS InCategory,
    p.Price,
    p.Stock
FROM Products p
CROSS JOIN Categories c
WHERE p.ProductID <= 5  -- Limit output
ORDER BY p.ProductName, c.CategoryName;


/*
============================================================================
PART 5: Test Data Generation
============================================================================
*/

-- Example 5.1: Generate test scenarios
CREATE TABLE #Scenarios (ScenarioName VARCHAR(50));
CREATE TABLE #TestData (TestValue INT);

INSERT INTO #Scenarios VALUES ('Low Load'), ('Medium Load'), ('High Load');
INSERT INTO #TestData VALUES (10), (100), (1000), (10000);

SELECT 
    s.ScenarioName,
    t.TestValue,
    CONCAT(s.ScenarioName, ' - ', t.TestValue, ' records') AS TestCase
FROM #Scenarios s
CROSS JOIN #TestData t
ORDER BY s.ScenarioName, t.TestValue;

DROP TABLE #Scenarios, #TestData;

-- Example 5.2: Combinatorial testing
CREATE TABLE #Browsers (BrowserName VARCHAR(20));
CREATE TABLE #OS (OSName VARCHAR(20));
CREATE TABLE #Resolutions (Resolution VARCHAR(20));

INSERT INTO #Browsers VALUES ('Chrome'), ('Firefox'), ('Safari'), ('Edge');
INSERT INTO #OS VALUES ('Windows'), ('MacOS'), ('Linux');
INSERT INTO #Resolutions VALUES ('1920x1080'), ('1366x768'), ('2560x1440');

SELECT 
    b.BrowserName,
    o.OSName,
    r.Resolution,
    CONCAT(b.BrowserName, ' on ', o.OSName, ' at ', r.Resolution) AS TestConfiguration
FROM #Browsers b
CROSS JOIN #OS o
CROSS JOIN #Resolutions r
ORDER BY b.BrowserName, o.OSName, r.Resolution;

DROP TABLE #Browsers, #OS, #Resolutions;


/*
============================================================================
PART 6: Performance and Optimization
============================================================================
*/

-- Performance 6.1: ⚠️ Understand the cost
-- Small tables:
SELECT COUNT(*) AS SmallCrossJoinRows
FROM (SELECT TOP 10 * FROM Customers) c
CROSS JOIN (SELECT TOP 10 * FROM Products) p;
-- Result: 100 rows (manageable)

-- Large tables (demonstration only - don't run on production!):
-- SELECT COUNT(*) FROM Customers CROSS JOIN Products;
-- If Customers = 1000 and Products = 500: Result = 500,000 rows!

-- Performance 6.2: ✅ Use WHERE to filter early
-- Bad (generates then filters):
SELECT c.CustomerName, p.ProductName
FROM Customers c
CROSS JOIN Products p
WHERE c.CustomerID = 1;

-- Better (filter first with subquery):
SELECT c.CustomerName, p.ProductName
FROM (SELECT * FROM Customers WHERE CustomerID = 1) c
CROSS JOIN Products p;

-- Performance 6.3: ✅ Limit result set
SELECT TOP 100
    c.CustomerName,
    p.ProductName
FROM Customers c
CROSS JOIN Products p;

-- Performance 6.4: ⚠️ Avoid accidental cross joins!
-- Missing join condition:
-- SELECT * FROM Orders o, OrderDetails od, Products p;  -- Huge result!

-- Correct:
SELECT *
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID;


/*
============================================================================
PART 7: Real-World Applications
============================================================================
*/

-- Application 7.1: Product bundle suggestions
SELECT TOP 10
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    ROUND(p1.Price + p2.Price, 2) AS BundlePrice,
    ROUND((p1.Price + p2.Price) * 0.85, 2) AS DiscountedPrice,
    ROUND((p1.Price + p2.Price) * 0.15, 2) AS Savings
FROM Products p1
CROSS JOIN Products p2
WHERE p1.CategoryID <> p2.CategoryID
  AND p1.ProductID < p2.ProductID
  AND p1.Price + p2.Price BETWEEN 50 AND 150
ORDER BY Savings DESC;

-- Application 7.2: Appointment scheduling
CREATE TABLE #TimeSlots (SlotTime TIME);
CREATE TABLE #Consultants (ConsultantName VARCHAR(50));

INSERT INTO #TimeSlots VALUES 
('09:00'), ('10:00'), ('11:00'), ('13:00'), ('14:00'), ('15:00'), ('16:00');
INSERT INTO #Consultants VALUES ('Dr. Smith'), ('Dr. Jones'), ('Dr. Williams');

SELECT 
    c.ConsultantName,
    t.SlotTime,
    CONCAT(c.ConsultantName, ' - ', CAST(t.SlotTime AS VARCHAR(5))) AS Appointment,
    'Available' AS Status
FROM #Consultants c
CROSS JOIN #TimeSlots t
ORDER BY c.ConsultantName, t.SlotTime;

DROP TABLE #TimeSlots, #Consultants;

-- Application 7.3: Feature matrix
CREATE TABLE #Products2 (ProductName VARCHAR(50));
CREATE TABLE #Features (FeatureName VARCHAR(50));

INSERT INTO #Products2 VALUES ('Basic'), ('Pro'), ('Enterprise');
INSERT INTO #Features VALUES 
('Email Support'), ('Phone Support'), ('API Access'), ('Custom Reports'), ('Dedicated Manager');

SELECT 
    p.ProductName,
    f.FeatureName,
    CASE 
        WHEN p.ProductName = 'Enterprise' THEN 'Yes'
        WHEN p.ProductName = 'Pro' AND f.FeatureName IN ('Email Support', 'Phone Support', 'API Access') THEN 'Yes'
        WHEN p.ProductName = 'Basic' AND f.FeatureName = 'Email Support' THEN 'Yes'
        ELSE 'No'
    END AS Included
FROM #Products2 p
CROSS JOIN #Features f
ORDER BY p.ProductName, f.FeatureName;

DROP TABLE #Products2, #Features;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Generate all possible combinations of 3 colors and 4 sizes
2. Create a date range for the first 10 days of January 2024
3. Show every customer paired with every category
4. Find the top 5 product pairs with total price under $100
5. Generate hourly time slots for a week

Solutions below ↓
*/

-- Solution 1:
CREATE TABLE #Ex1Colors (Color VARCHAR(20));
CREATE TABLE #Ex1Sizes (Size VARCHAR(10));
INSERT INTO #Ex1Colors VALUES ('Red'), ('Blue'), ('Green');
INSERT INTO #Ex1Sizes VALUES ('S'), ('M'), ('L'), ('XL');

SELECT c.Color, s.Size
FROM #Ex1Colors c CROSS JOIN #Ex1Sizes s
ORDER BY c.Color, s.Size;

DROP TABLE #Ex1Colors, #Ex1Sizes;

-- Solution 2:
CREATE TABLE #Ex2Numbers (N INT);
INSERT INTO #Ex2Numbers VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

SELECT DATEADD(DAY, N, '2024-01-01') AS DateValue
FROM #Ex2Numbers
WHERE N < 10
ORDER BY DateValue;

DROP TABLE #Ex2Numbers;

-- Solution 3:
SELECT 
    c.CustomerName,
    cat.CategoryName
FROM Customers c
CROSS JOIN Categories cat
ORDER BY c.CustomerName, cat.CategoryName;

-- Solution 4:
SELECT TOP 5
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    p1.Price + p2.Price AS TotalPrice
FROM Products p1
CROSS JOIN Products p2
WHERE p1.ProductID < p2.ProductID
  AND p1.Price + p2.Price < 100
ORDER BY TotalPrice DESC;

-- Solution 5:
CREATE TABLE #Ex5Days (DayNum INT, DayName VARCHAR(10));
CREATE TABLE #Ex5Hours (HourNum INT);

INSERT INTO #Ex5Days VALUES (1,'Mon'),(2,'Tue'),(3,'Wed'),(4,'Thu'),(5,'Fri'),(6,'Sat'),(7,'Sun');
INSERT INTO #Ex5Hours 
SELECT TOP 24 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1
FROM sys.objects;

SELECT 
    d.DayName,
    CONCAT(RIGHT('0' + CAST(h.HourNum AS VARCHAR(2)), 2), ':00') AS TimeSlot
FROM #Ex5Days d
CROSS JOIN #Ex5Hours h
ORDER BY d.DayNum, h.HourNum;

DROP TABLE #Ex5Days, #Ex5Hours;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CROSS JOIN BASICS:
  • Cartesian product of two tables
  • No ON clause needed
  • Result rows = Table1 rows × Table2 rows
  • Can create very large results

✓ WHEN TO USE:
  • Generate combinations
  • Calendar/time series
  • Test data
  • Fill gaps in data
  • Feature matrices

✓ COMMON PATTERNS:
  • Product bundles
  • Scheduling grids
  • Size/color variants
  • Date ranges
  • Test scenarios

✓ PERFORMANCE:
  • Result set grows multiplicatively
  • Filter early with WHERE
  • Limit output with TOP
  • Be cautious with large tables
  • Avoid accidental cross joins

✓ ALTERNATIVES:
  • Recursive CTEs (date ranges)
  • GENERATE_SERIES (some databases)
  • Tally/numbers tables
  • Cursor loops (avoid if possible)

✓ BEST PRACTICES:
  • Understand row count impact
  • Use intentionally, not accidentally
  • Add WHERE clause to filter
  • Comment why cross join is needed
  • Test with small datasets first

✓ COMMON MISTAKES:
  • Forgetting join condition (accidental)
  • Not limiting result size
  • Using on production tables carelessly
  • Missing WHERE filters

============================================================================
NEXT: Lesson 10.05 - Natural and Using Joins
Learn alternative join syntaxes (limited in T-SQL).
============================================================================
*/
