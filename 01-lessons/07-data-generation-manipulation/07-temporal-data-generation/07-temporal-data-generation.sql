/*
============================================================================
Lesson 07.07 - Temporal Data Generation
============================================================================

Description:
Learn to generate and construct date and time values in SQL Server.
Essential for creating reports, scheduling, and time-based calculations.

Topics Covered:
• GETDATE, GETUTCDATE, SYSDATETIME
• DATEADD function
• EOMONTH (end of month)
• DATEFROMPARTS, TIMEFROMPARTS
• Date literals and formats
• Generating date ranges
• Creating calendar tables

Prerequisites:
• Basic SELECT statements
• Understanding of date/time data types

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Current Date and Time Functions
============================================================================
*/

-- Example 1.1: GETDATE - Current date and time
SELECT GETDATE() AS CurrentDateTime;
-- Result: 2025-11-08 14:30:45.123 (example)

-- Example 1.2: GETUTCDATE - Current UTC time
SELECT 
    GETDATE() AS LocalTime,
    GETUTCDATE() AS UTCTime,
    DATEDIFF(HOUR, GETUTCDATE(), GETDATE()) AS TimeZoneOffset;

-- Example 1.3: SYSDATETIME - Higher precision (SQL Server 2008+)
SELECT 
    GETDATE() AS DateTime,         -- Precision: ~3.33ms
    SYSDATETIME() AS DateTime2;    -- Precision: 100 nanoseconds

-- Example 1.4: Current date only (no time)
SELECT 
    CAST(GETDATE() AS DATE) AS TodayDate,
    CONVERT(DATE, GETDATE()) AS AlsoToday;

-- Example 1.5: Current time only (no date)
SELECT 
    CAST(GETDATE() AS TIME) AS CurrentTime,
    CONVERT(TIME, GETDATE()) AS AlsoCurrentTime;


/*
============================================================================
PART 2: DATEADD - Add or Subtract Time Intervals
============================================================================
Adds a specified number of intervals to a date.

Syntax: DATEADD(datepart, number, date)

Common dateparts:
  YEAR, QUARTER, MONTH, WEEK, DAY
  HOUR, MINUTE, SECOND, MILLISECOND
*/

-- Example 2.1: Add days
SELECT 
    GETDATE() AS Today,
    DATEADD(DAY, 7, GETDATE()) AS NextWeek,
    DATEADD(DAY, -7, GETDATE()) AS LastWeek;

-- Example 2.2: Add months
SELECT 
    GETDATE() AS Today,
    DATEADD(MONTH, 1, GETDATE()) AS NextMonth,
    DATEADD(MONTH, -1, GETDATE()) AS LastMonth,
    DATEADD(MONTH, 12, GETDATE()) AS NextYear;

-- Example 2.3: Add years
SELECT 
    GETDATE() AS Today,
    DATEADD(YEAR, 1, GETDATE()) AS NextYear,
    DATEADD(YEAR, -5, GETDATE()) AS FiveYearsAgo;

-- Example 2.4: Add hours and minutes
SELECT 
    GETDATE() AS Now,
    DATEADD(HOUR, 2, GETDATE()) AS TwoHoursLater,
    DATEADD(MINUTE, 30, GETDATE()) AS ThirtyMinutesLater,
    DATEADD(SECOND, 90, GETDATE()) AS NinetySecondsLater;

-- Example 2.5: Calculate due dates
SELECT 
    OrderID,
    OrderDate,
    DATEADD(DAY, 3, OrderDate) AS EstimatedShipping,
    DATEADD(DAY, 7, OrderDate) AS EstimatedDelivery,
    DATEADD(DAY, 30, OrderDate) AS ReturnDeadline
FROM Orders
WHERE OrderID <= 5;

-- Example 2.6: Subscription renewal dates
SELECT 
    CustomerID,
    FirstName + ' ' + LastName AS CustomerName,
    MIN(OrderDate) AS FirstOrder,
    DATEADD(YEAR, 1, MIN(OrderDate)) AS AnnualRenewal,
    DATEADD(MONTH, 1, MIN(OrderDate)) AS MonthlyRenewal
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;


/*
============================================================================
PART 3: EOMONTH - End of Month
============================================================================
Returns the last day of the month for a given date.

Syntax: EOMONTH(start_date, [month_offset])
*/

-- Example 3.1: Current month end
SELECT 
    GETDATE() AS Today,
    EOMONTH(GETDATE()) AS EndOfCurrentMonth;

-- Example 3.2: Last day of next month
SELECT 
    GETDATE() AS Today,
    EOMONTH(GETDATE(), 1) AS EndOfNextMonth,
    EOMONTH(GETDATE(), -1) AS EndOfLastMonth;

-- Example 3.3: First day of month (use EOMONTH trick)
SELECT 
    GETDATE() AS Today,
    DATEADD(DAY, 1, EOMONTH(GETDATE(), -1)) AS FirstOfCurrentMonth,
    EOMONTH(GETDATE(), -1) AS EndOfLastMonth;

-- Example 3.4: Calculate month-end deadlines
SELECT 
    OrderID,
    OrderDate,
    EOMONTH(OrderDate) AS MonthEndDeadline,
    DATEDIFF(DAY, OrderDate, EOMONTH(OrderDate)) AS DaysUntilMonthEnd
FROM Orders
WHERE OrderID <= 5;

-- Example 3.5: Generate month-end dates for reporting
SELECT 
    EOMONTH(DATEADD(MONTH, number, '2025-01-01')) AS MonthEnd
FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11)) AS Months(number);


/*
============================================================================
PART 4: DATEFROMPARTS - Construct Dates from Components
============================================================================
Build a date from individual parts (year, month, day).

Syntax: DATEFROMPARTS(year, month, day)
Also: TIMEFROMPARTS, DATETIMEFROMPARTS, DATETIME2FROMPARTS
*/

-- Example 4.1: Build a date from parts
SELECT 
    DATEFROMPARTS(2025, 11, 8) AS ConstructedDate;

-- Example 4.2: Build dates dynamically
SELECT 
    DATEFROMPARTS(2025, 1, 1) AS NewYearsDay,
    DATEFROMPARTS(2025, 7, 4) AS IndependenceDay,
    DATEFROMPARTS(2025, 12, 25) AS Christmas;

-- Example 4.3: First day of current year
SELECT 
    GETDATE() AS Today,
    DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS FirstDayOfYear;

-- Example 4.4: Build time from parts
SELECT 
    TIMEFROMPARTS(14, 30, 0, 0, 0) AS AfternoonTime,  -- 2:30 PM
    TIMEFROMPARTS(0, 0, 0, 0, 0) AS Midnight;

-- Example 4.5: Build datetime from parts
SELECT 
    DATETIME2FROMPARTS(2025, 11, 8, 14, 30, 0, 0, 7) AS PreciseDateTime;
    -- year, month, day, hour, minute, second, fraction, precision

-- Example 4.6: Generate dates for each month
SELECT 
    DATEFROMPARTS(2025, MonthNum, 1) AS FirstOfMonth
FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS Months(MonthNum);


/*
============================================================================
PART 5: Date Literals and Formats
============================================================================
*/

-- Example 5.1: ISO format (YYYY-MM-DD) - ALWAYS SAFE!
SELECT 
    CAST('2025-11-08' AS DATE) AS ISOFormat,
    CAST('2025-11-08 14:30:00' AS DATETIME) AS ISODateTime;

-- Example 5.2: Be careful with other formats (language-dependent)
SELECT 
    CAST('11/08/2025' AS DATE) AS USFormat,      -- Nov 8 or Aug 11?
    CAST('08/11/2025' AS DATE) AS EuroFormat;    -- Depends on server!

-- Example 5.3: Use CONVERT with style codes
SELECT 
    CONVERT(DATE, '08/11/2025', 101) AS USFormat,       -- 101 = mm/dd/yyyy
    CONVERT(DATE, '08/11/2025', 103) AS BritishFormat;  -- 103 = dd/mm/yyyy

-- Example 5.4: Safe date construction
SELECT 
    '2025-11-08' AS SafeISO,                    -- ✓ Always works
    DATEFROMPARTS(2025, 11, 8) AS SafeParts,    -- ✓ Always works
    '11/08/2025' AS Risky;                      -- ❌ Ambiguous!


/*
============================================================================
PART 6: Generating Date Ranges
============================================================================
*/

-- Example 6.1: Last 7 days
SELECT 
    DATEADD(DAY, -number, CAST(GETDATE() AS DATE)) AS DateValue
FROM (VALUES (0), (1), (2), (3), (4), (5), (6)) AS Numbers(number)
ORDER BY DateValue;

-- Example 6.2: Next 30 days
SELECT 
    DATEADD(DAY, number, CAST(GETDATE() AS DATE)) AS DateValue
FROM (
    SELECT TOP 30 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS number
    FROM sys.objects
) AS Numbers
ORDER BY DateValue;

-- Example 6.3: All dates in current month
SELECT 
    DATEADD(DAY, number, DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))) AS DateValue
FROM (
    SELECT TOP 31 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS number
    FROM sys.objects
) AS Numbers
WHERE MONTH(DATEADD(DAY, number, DATEADD(DAY, 1, EOMONTH(GETDATE(), -1)))) = MONTH(GETDATE())
ORDER BY DateValue;

-- Example 6.4: Business days (Mon-Fri) for next 2 weeks
SELECT 
    DateValue,
    DATENAME(WEEKDAY, DateValue) AS DayName
FROM (
    SELECT 
        DATEADD(DAY, number, CAST(GETDATE() AS DATE)) AS DateValue
    FROM (
        SELECT TOP 14 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS number
        FROM sys.objects
    ) AS Numbers
) AS Dates
WHERE DATEPART(WEEKDAY, DateValue) NOT IN (1, 7)  -- Exclude Sun(1) and Sat(7)
ORDER BY DateValue;


/*
============================================================================
PART 7: Practical Applications
============================================================================
*/

-- Application 7.1: Generate monthly report periods
SELECT 
    DATEFROMPARTS(2025, MonthNum, 1) AS PeriodStart,
    EOMONTH(DATEFROMPARTS(2025, MonthNum, 1)) AS PeriodEnd,
    DATENAME(MONTH, DATEFROMPARTS(2025, MonthNum, 1)) AS MonthName
FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS Months(MonthNum);

-- Application 7.2: Calculate aging buckets
SELECT 
    OrderID,
    OrderDate,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysOld,
    CASE 
        WHEN OrderDate >= DATEADD(DAY, -30, GETDATE()) THEN '0-30 days'
        WHEN OrderDate >= DATEADD(DAY, -60, GETDATE()) THEN '31-60 days'
        WHEN OrderDate >= DATEADD(DAY, -90, GETDATE()) THEN '61-90 days'
        ELSE '90+ days'
    END AS AgingBucket
FROM Orders
ORDER BY OrderDate DESC;

-- Application 7.3: Warranty expiration dates
SELECT 
    o.OrderID,
    o.OrderDate,
    p.ProductName,
    DATEADD(YEAR, 1, o.OrderDate) AS WarrantyExpires,
    DATEDIFF(DAY, GETDATE(), DATEADD(YEAR, 1, o.OrderDate)) AS DaysUntilExpiration,
    CASE 
        WHEN DATEADD(YEAR, 1, o.OrderDate) < GETDATE() THEN 'Expired'
        WHEN DATEADD(DAY, 30, GETDATE()) >= DATEADD(YEAR, 1, o.OrderDate) THEN 'Expiring Soon'
        ELSE 'Active'
    END AS WarrantyStatus
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
WHERE o.OrderID <= 10;

-- Application 7.4: Create a simple calendar table
SELECT 
    DateValue,
    YEAR(DateValue) AS Year,
    MONTH(DateValue) AS MonthNum,
    DAY(DateValue) AS DayNum,
    DATENAME(WEEKDAY, DateValue) AS DayName,
    DATENAME(MONTH, DateValue) AS MonthName,
    DATEPART(QUARTER, DateValue) AS Quarter,
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend
FROM (
    SELECT TOP 365
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, '2025-01-01') AS DateValue
    FROM sys.objects a
    CROSS JOIN sys.objects b
) AS Dates
WHERE YEAR(DateValue) = 2025
ORDER BY DateValue;


/*
============================================================================
PART 8: Combining Date Generation Functions
============================================================================
*/

-- Example 8.1: Quarter boundaries
SELECT 
    QuarterNum,
    DATEFROMPARTS(2025, (QuarterNum - 1) * 3 + 1, 1) AS QuarterStart,
    EOMONTH(DATEFROMPARTS(2025, QuarterNum * 3, 1)) AS QuarterEnd
FROM (VALUES (1), (2), (3), (4)) AS Quarters(QuarterNum);

-- Example 8.2: Fiscal year (July-June)
SELECT 
    CASE 
        WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE())
        ELSE YEAR(GETDATE()) - 1
    END AS FiscalYear,
    DATEFROMPARTS(
        CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) ELSE YEAR(GETDATE()) - 1 END,
        7, 1
    ) AS FiscalYearStart,
    DATEFROMPARTS(
        CASE WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1 ELSE YEAR(GETDATE()) END,
        6, 30
    ) AS FiscalYearEnd;

-- Example 8.3: Payment schedule (monthly)
DECLARE @StartDate DATE = '2025-01-15';
DECLARE @Payments INT = 12;

SELECT 
    PaymentNum,
    DATEADD(MONTH, PaymentNum - 1, @StartDate) AS PaymentDate,
    100.00 AS PaymentAmount
FROM (
    SELECT TOP 12 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS PaymentNum
    FROM sys.objects
) AS Payments;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own before checking solutions below:

1. Get the last day of the current quarter
2. Generate all Mondays in the next 60 days
3. Calculate 90 days from each order date
4. Create the first day of each quarter in 2025
5. Find orders from exactly 6 months ago

Solutions below ↓
*/

-- Solution 1: Last day of current quarter
SELECT 
    GETDATE() AS Today,
    DATEPART(QUARTER, GETDATE()) AS CurrentQuarter,
    EOMONTH(DATEFROMPARTS(YEAR(GETDATE()), DATEPART(QUARTER, GETDATE()) * 3, 1)) AS QuarterEnd;

-- Solution 2: All Mondays in next 60 days
SELECT DateValue
FROM (
    SELECT TOP 60 DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), GETDATE()) AS DateValue
    FROM sys.objects
) AS Dates
WHERE DATEPART(WEEKDAY, DateValue) = 2  -- Monday
ORDER BY DateValue;

-- Solution 3: 90 days from order date
SELECT 
    OrderID,
    OrderDate,
    DATEADD(DAY, 90, OrderDate) AS After90Days
FROM Orders;

-- Solution 4: First day of each quarter 2025
SELECT 
    QuarterNum,
    DATEFROMPARTS(2025, (QuarterNum - 1) * 3 + 1, 1) AS QuarterStart
FROM (VALUES (1), (2), (3), (4)) AS Quarters(QuarterNum);

-- Solution 5: Orders from 6 months ago
SELECT 
    OrderID,
    OrderDate
FROM Orders
WHERE OrderDate BETWEEN 
    DATEADD(MONTH, -6, DATEADD(DAY, -DAY(GETDATE()) + 1, GETDATE()))
    AND EOMONTH(DATEADD(MONTH, -6, GETDATE()));


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ CURRENT DATE/TIME:
  • GETDATE() - Local datetime
  • GETUTCDATE() - UTC datetime
  • SYSDATETIME() - Higher precision
  • CAST AS DATE/TIME to extract components

✓ DATE ARITHMETIC:
  • DATEADD(datepart, number, date) - Add/subtract intervals
  • EOMONTH(date, [offset]) - Month boundaries
  • Negative numbers subtract time

✓ DATE CONSTRUCTION:
  • DATEFROMPARTS(year, month, day) - Build dates
  • Use ISO format 'YYYY-MM-DD' for literals
  • Avoid ambiguous formats like '11/08/2025'

✓ PRACTICAL USES:
  • Calculate due dates and deadlines
  • Generate date ranges for reports
  • Create calendar tables
  • Age analysis and bucketing

✓ BEST PRACTICES:
  • Always use ISO format for date literals
  • CAST to DATE to remove time component
  • Test for month-end edge cases
  • Consider time zones for UTC storage

============================================================================
NEXT: Lesson 07.08 - Temporal Data Manipulation
Learn DATEDIFF, DATEPART, and extracting date components.
============================================================================
*/
