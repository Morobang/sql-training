/*
============================================================================
Lesson 07.08 - Temporal Data Manipulation
============================================================================

Description:
Extract, manipulate, and transform date and time components.
Master DATEDIFF, DATEPART, DATENAME, and date arithmetic for
powerful temporal queries.

Topics Covered:
• DATEDIFF function
• DATEPART function
• DATENAME function
• YEAR, MONTH, DAY functions
• Date arithmetic
• Business day calculations
• Age calculations
• Period-over-period analysis

Prerequisites:
• Lesson 07.07 - Temporal Data Generation
• Understanding of dates

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: DATEDIFF - Calculate Differences
============================================================================
DATEDIFF(datepart, startdate, enddate)
Returns: Integer number of boundaries crossed
*/

-- Example 1.1: Basic DATEDIFF
SELECT 
    DATEDIFF(DAY, '2025-01-01', '2025-01-10') AS DaysDiff,        -- 9
    DATEDIFF(MONTH, '2025-01-15', '2025-03-15') AS MonthsDiff,    -- 2
    DATEDIFF(YEAR, '2023-01-01', '2025-01-01') AS YearsDiff;      -- 2

-- Example 1.2: Different dateparts
DECLARE @Start DATETIME = '2025-01-15 08:30:00';
DECLARE @End DATETIME = '2025-01-17 16:45:00';

SELECT 
    DATEDIFF(SECOND, @Start, @End) AS Seconds,
    DATEDIFF(MINUTE, @Start, @End) AS Minutes,
    DATEDIFF(HOUR, @Start, @End) AS Hours,
    DATEDIFF(DAY, @Start, @End) AS Days,
    DATEDIFF(WEEK, @Start, @End) AS Weeks,
    DATEDIFF(MONTH, @Start, @End) AS Months;

-- Example 1.3: Negative differences (start > end)
SELECT 
    DATEDIFF(DAY, '2025-01-10', '2025-01-01') AS NegativeDays,  -- -9
    DATEDIFF(MONTH, '2025-03-01', '2025-01-01') AS NegativeMonths;  -- -2

-- Example 1.4: IMPORTANT - Boundary crossing, not exact intervals!
SELECT 
    DATEDIFF(MONTH, '2025-01-31', '2025-02-01') AS MonthBoundary,  -- 1 (crosses 1 boundary)
    DATEDIFF(YEAR, '2024-12-31', '2025-01-01') AS YearBoundary;    -- 1 (crosses 1 boundary)
-- Only 1 day apart, but crosses month/year boundary!

-- Example 1.5: Calculate age in years
DECLARE @BirthDate DATE = '1990-05-15';
DECLARE @Today DATE = GETDATE();

SELECT 
    @BirthDate AS BirthDate,
    @Today AS Today,
    DATEDIFF(YEAR, @BirthDate, @Today) AS AgeInYears,
    -- More accurate age (subtract 1 if birthday hasn't occurred this year):
    DATEDIFF(YEAR, @BirthDate, @Today) - 
        CASE 
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, @BirthDate, @Today), @BirthDate) > @Today 
            THEN 1 
            ELSE 0 
        END AS AccurateAge;


/*
============================================================================
PART 2: DATEPART - Extract Components
============================================================================
DATEPART(datepart, date)
Returns: Integer value of the specified part
*/

-- Example 2.1: Extract date components
DECLARE @DateTime DATETIME = '2025-01-15 14:30:45';

SELECT 
    DATEPART(YEAR, @DateTime) AS Year,
    DATEPART(MONTH, @DateTime) AS Month,
    DATEPART(DAY, @DateTime) AS Day,
    DATEPART(HOUR, @DateTime) AS Hour,
    DATEPART(MINUTE, @DateTime) AS Minute,
    DATEPART(SECOND, @DateTime) AS Second;

-- Example 2.2: Week-related parts
SELECT 
    DATEPART(WEEK, '2025-01-15') AS WeekOfYear,
    DATEPART(WEEKDAY, '2025-01-15') AS DayOfWeek,      -- 1=Sunday, 7=Saturday
    DATEPART(DAYOFYEAR, '2025-01-15') AS DayOfYear,
    DATEPART(QUARTER, '2025-01-15') AS Quarter;

-- Example 2.3: ISO week
SELECT 
    DATEPART(ISO_WEEK, '2025-01-01') AS ISOWeek,       -- ISO 8601 week
    DATEPART(WEEK, '2025-01-01') AS RegularWeek;

-- Example 2.4: Practical - Find day of week
SELECT 
    OrderID,
    OrderDate,
    DATEPART(WEEKDAY, OrderDate) AS DayOfWeekNum,
    CASE DATEPART(WEEKDAY, OrderDate)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS DayName
FROM Orders;

-- Example 2.5: Filter by time of day
SELECT 
    OrderID,
    OrderDate,
    DATEPART(HOUR, OrderDate) AS Hour
FROM Orders
WHERE DATEPART(HOUR, OrderDate) BETWEEN 9 AND 17  -- Business hours
ORDER BY OrderDate;


/*
============================================================================
PART 3: DATENAME - Get Text Names
============================================================================
DATENAME(datepart, date)
Returns: String (e.g., "January", "Monday")
*/

-- Example 3.1: Get text names
DECLARE @Date DATETIME = '2025-01-15 14:30:00';

SELECT 
    DATENAME(MONTH, @Date) AS MonthName,           -- January
    DATENAME(WEEKDAY, @Date) AS WeekdayName,       -- Wednesday
    DATENAME(QUARTER, @Date) AS QuarterName,       -- 1
    DATENAME(YEAR, @Date) AS YearName;             -- 2025

-- Example 3.2: Format dates with names
SELECT 
    OrderID,
    OrderDate,
    DATENAME(MONTH, OrderDate) + ' ' + 
    CAST(DAY(OrderDate) AS VARCHAR) + ', ' + 
    CAST(YEAR(OrderDate) AS VARCHAR) AS FormattedDate
FROM Orders;

-- Example 3.3: Group by month name
SELECT 
    DATENAME(MONTH, OrderDate) AS Month,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSales
FROM Orders
GROUP BY DATENAME(MONTH, OrderDate), MONTH(OrderDate)
ORDER BY MONTH(OrderDate);


/*
============================================================================
PART 4: YEAR, MONTH, DAY Shortcuts
============================================================================
Convenient shortcuts for DATEPART
*/

-- Example 4.1: Shortcut functions
DECLARE @Date DATETIME = '2025-01-15 14:30:00';

SELECT 
    YEAR(@Date) AS Year,           -- Same as DATEPART(YEAR, @Date)
    MONTH(@Date) AS Month,         -- Same as DATEPART(MONTH, @Date)
    DAY(@Date) AS Day;             -- Same as DATEPART(DAY, @Date)

-- Example 4.2: Filter by year
SELECT 
    OrderID,
    OrderDate,
    TotalAmount
FROM Orders
WHERE YEAR(OrderDate) = 2025;

-- Example 4.3: Compare same period last year
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS TotalSales
FROM Orders
WHERE YEAR(OrderDate) IN (2024, 2025)
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY YEAR(OrderDate), MONTH(OrderDate);


/*
============================================================================
PART 5: Date Arithmetic
============================================================================
*/

-- Example 5.1: Add/subtract days
DECLARE @Today DATE = GETDATE();

SELECT 
    @Today AS Today,
    DATEADD(DAY, 7, @Today) AS OneWeekFromNow,
    DATEADD(DAY, -7, @Today) AS OneWeekAgo,
    DATEADD(DAY, 30, @Today) AS ThirtyDaysFromNow;

-- Example 5.2: First and last day of month
DECLARE @AnyDate DATE = '2025-01-15';

SELECT 
    @AnyDate AS GivenDate,
    DATEFROMPARTS(YEAR(@AnyDate), MONTH(@AnyDate), 1) AS FirstDayOfMonth,
    EOMONTH(@AnyDate) AS LastDayOfMonth,
    DATEADD(DAY, -DAY(@AnyDate), @AnyDate) AS AlternateFirstDay;

-- Example 5.3: First day of quarter
DECLARE @Date DATE = '2025-05-15';

SELECT 
    @Date AS CurrentDate,
    DATEFROMPARTS(YEAR(@Date), ((DATEPART(QUARTER, @Date) - 1) * 3) + 1, 1) AS FirstDayOfQuarter;

-- Example 5.4: Beginning and end of year
DECLARE @SomeDate DATE = '2025-06-15';

SELECT 
    @SomeDate AS GivenDate,
    DATEFROMPARTS(YEAR(@SomeDate), 1, 1) AS FirstDayOfYear,
    DATEFROMPARTS(YEAR(@SomeDate), 12, 31) AS LastDayOfYear;


/*
============================================================================
PART 6: Age and Tenure Calculations
============================================================================
*/

-- Example 6.1: Calculate exact age
CREATE FUNCTION dbo.CalculateAge (@BirthDate DATE, @AsOfDate DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @BirthDate, @AsOfDate) - 
        CASE 
            WHEN MONTH(@BirthDate) > MONTH(@AsOfDate) THEN 1
            WHEN MONTH(@BirthDate) = MONTH(@AsOfDate) AND DAY(@BirthDate) > DAY(@AsOfDate) THEN 1
            ELSE 0
        END;
END;
GO

-- Test the function
SELECT 
    dbo.CalculateAge('1990-05-15', '2025-01-15') AS Age1,
    dbo.CalculateAge('1990-05-15', '2025-06-15') AS Age2;

DROP FUNCTION dbo.CalculateAge;

-- Example 6.2: Employee tenure in years and months
DECLARE @HireDate DATE = '2020-03-15';
DECLARE @Today DATE = GETDATE();

SELECT 
    @HireDate AS HireDate,
    @Today AS Today,
    DATEDIFF(MONTH, @HireDate, @Today) / 12 AS Years,
    DATEDIFF(MONTH, @HireDate, @Today) % 12 AS Months,
    CONCAT(
        DATEDIFF(MONTH, @HireDate, @Today) / 12, ' years, ',
        DATEDIFF(MONTH, @HireDate, @Today) % 12, ' months'
    ) AS Tenure;

-- Example 6.3: Days until event
DECLARE @EventDate DATE = '2025-12-25';

SELECT 
    @EventDate AS EventDate,
    GETDATE() AS Today,
    DATEDIFF(DAY, GETDATE(), @EventDate) AS DaysUntil,
    CASE 
        WHEN DATEDIFF(DAY, GETDATE(), @EventDate) < 0 THEN 'Event has passed'
        WHEN DATEDIFF(DAY, GETDATE(), @EventDate) = 0 THEN 'Event is today!'
        WHEN DATEDIFF(DAY, GETDATE(), @EventDate) <= 7 THEN 'Event is this week'
        ELSE 'Event is upcoming'
    END AS Status;


/*
============================================================================
PART 7: Business Day Calculations
============================================================================
*/

-- Example 7.1: Detect weekend
SELECT 
    OrderID,
    OrderDate,
    DATENAME(WEEKDAY, OrderDate) AS DayName,
    CASE 
        WHEN DATEPART(WEEKDAY, OrderDate) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType
FROM Orders;

-- Example 7.2: Count business days between dates
DECLARE @StartDate DATE = '2025-01-01';
DECLARE @EndDate DATE = '2025-01-31';

;WITH DateRange AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < @EndDate
)
SELECT 
    COUNT(*) AS TotalDays,
    SUM(CASE WHEN DATEPART(WEEKDAY, DateValue) NOT IN (1, 7) THEN 1 ELSE 0 END) AS BusinessDays,
    SUM(CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END) AS WeekendDays
FROM DateRange
OPTION (MAXRECURSION 365);

-- Example 7.3: Add business days
-- Add 5 business days to a date (simplified - doesn't account for holidays)
DECLARE @Start DATE = '2025-01-15';
DECLARE @DaysToAdd INT = 5;

;WITH BusinessDays AS (
    SELECT 
        @Start AS DateValue,
        CASE WHEN DATEPART(WEEKDAY, @Start) NOT IN (1, 7) THEN 1 ELSE 0 END AS IsBusinessDay,
        0 AS BusinessDaysAdded
    UNION ALL
    SELECT 
        DATEADD(DAY, 1, DateValue),
        CASE WHEN DATEPART(WEEKDAY, DATEADD(DAY, 1, DateValue)) NOT IN (1, 7) THEN 1 ELSE 0 END,
        BusinessDaysAdded + CASE WHEN DATEPART(WEEKDAY, DATEADD(DAY, 1, DateValue)) NOT IN (1, 7) THEN 1 ELSE 0 END
    FROM BusinessDays
    WHERE BusinessDaysAdded < @DaysToAdd
)
SELECT TOP 1
    @Start AS StartDate,
    DateValue AS ResultDate,
    BusinessDaysAdded AS BusinessDaysAdded
FROM BusinessDays
ORDER BY DateValue DESC
OPTION (MAXRECURSION 100);


/*
============================================================================
PART 8: Period-Over-Period Analysis
============================================================================
*/

-- Example 8.1: Compare to same period last year
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS Sales
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY YEAR(OrderDate), MONTH(OrderDate);

-- Example 8.2: Year-over-year growth
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(TotalAmount) AS Sales
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    curr.Year,
    curr.Month,
    curr.Sales AS CurrentYearSales,
    prev.Sales AS PreviousYearSales,
    curr.Sales - prev.Sales AS Difference,
    CASE 
        WHEN prev.Sales > 0 
        THEN CAST((curr.Sales - prev.Sales) / prev.Sales * 100 AS DECIMAL(10,2))
        ELSE NULL
    END AS PercentChange
FROM MonthlySales curr
LEFT JOIN MonthlySales prev 
    ON curr.Month = prev.Month 
    AND curr.Year = prev.Year + 1
ORDER BY curr.Year, curr.Month;

-- Example 8.3: Quarter-over-quarter comparison
SELECT 
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSales,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate);


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own:

1. Find all orders placed on weekends
2. Calculate customer age from birthdate
3. Get orders from Q1 2025
4. Calculate days since last order for each customer
5. Find busiest day of week for orders

Solutions below ↓
*/

-- Solution 1: Weekend orders
SELECT 
    OrderID,
    OrderDate,
    DATENAME(WEEKDAY, OrderDate) AS DayName
FROM Orders
WHERE DATEPART(WEEKDAY, OrderDate) IN (1, 7)
ORDER BY OrderDate;

-- Solution 2: Customer age (if we had birthdate column)
-- SELECT 
--     CustomerID,
--     FirstName,
--     LastName,
--     BirthDate,
--     DATEDIFF(YEAR, BirthDate, GETDATE()) -
--         CASE 
--             WHEN MONTH(BirthDate) > MONTH(GETDATE()) THEN 1
--             WHEN MONTH(BirthDate) = MONTH(GETDATE()) AND DAY(BirthDate) > DAY(GETDATE()) THEN 1
--             ELSE 0
--         END AS Age
-- FROM Customers;

-- Solution 3: Q1 2025 orders
SELECT 
    OrderID,
    OrderDate,
    TotalAmount
FROM Orders
WHERE YEAR(OrderDate) = 2025
  AND DATEPART(QUARTER, OrderDate) = 1
ORDER BY OrderDate;

-- Solution 4: Days since last order
SELECT 
    CustomerID,
    MAX(OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(OrderDate), GETDATE()) AS DaysSinceLastOrder,
    CASE 
        WHEN DATEDIFF(DAY, MAX(OrderDate), GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(DAY, MAX(OrderDate), GETDATE()) <= 90 THEN 'Recent'
        WHEN DATEDIFF(DAY, MAX(OrderDate), GETDATE()) <= 180 THEN 'Inactive'
        ELSE 'Lost'
    END AS CustomerStatus
FROM Orders
GROUP BY CustomerID
ORDER BY DaysSinceLastOrder;

-- Solution 5: Busiest day of week
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    DATEPART(WEEKDAY, OrderDate) AS DayNum,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSales
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY DATEPART(WEEKDAY, OrderDate);


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ DATEDIFF:
  • Calculates boundary crossings, not exact intervals
  • Returns negative if start > end
  • Use for age, tenure, time until event
  • Careful with MONTH and YEAR (not exact durations)

✓ DATEPART:
  • Extracts integer components
  • WEEKDAY: 1=Sunday, 7=Saturday
  • QUARTER: 1-4
  • ISO_WEEK for international week numbers

✓ DATENAME:
  • Returns text names (January, Monday, etc.)
  • Good for reports and formatting
  • Use with GROUP BY for readable results

✓ SHORTCUTS:
  • YEAR(), MONTH(), DAY() are convenient
  • Use in WHERE clauses and GROUP BY
  • More readable than DATEPART

✓ DATE ARITHMETIC:
  • DATEADD for adding intervals
  • EOMONTH for month boundaries
  • DATEFROMPARTS to construct dates
  • Combine functions for complex calculations

✓ BEST PRACTICES:
  • Use DATEADD instead of direct arithmetic
  • Be aware of boundary-crossing behavior
  • Account for leap years and varying month lengths
  • Test edge cases (month/year boundaries)
  • Consider time zones for global apps

============================================================================
NEXT: Lesson 07.09 - Conversion Functions
Master CAST, CONVERT, and type transformations.
============================================================================
*/
