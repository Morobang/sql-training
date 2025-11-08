-- ============================================================================
-- Lesson 05: Temporal Data Types
-- ============================================================================
-- Learn to work with dates and times in SQL Server

USE BookStore;
GO

PRINT 'Lesson 05: Temporal Data Types';
PRINT '==============================';
PRINT '';

-- ============================================================================
-- Concept 1: Date and Time Types
-- ============================================================================

PRINT 'Concept 1: Date and Time Types';
PRINT '------------------------------';
PRINT 'DATE      - Date only (YYYY-MM-DD), 0001-01-01 to 9999-12-31';
PRINT 'TIME      - Time only (HH:MM:SS.nnnnnnn), 00:00:00 to 23:59:59.9999999';
PRINT 'DATETIME  - Date + Time, 1753-01-01 to 9999-12-31, 3.33ms precision';
PRINT 'DATETIME2 - Date + Time, 0001-01-01 to 9999-12-31, 100ns precision (preferred)';
PRINT 'SMALLDATETIME - Date + Time, 1900-01-01 to 2079-06-06, 1 min precision';
PRINT '';

CREATE TABLE TemporalExample (
    EventID INT IDENTITY(1,1),
    EventDate DATE,
    EventTime TIME,
    EventDateTime DATETIME,
    EventDateTime2 DATETIME2,
    EventSmallDateTime SMALLDATETIME
);

INSERT INTO TemporalExample (EventDate, EventTime, EventDateTime, EventDateTime2, EventSmallDateTime) VALUES
    ('2025-01-15', '14:30:45.123', '2025-01-15 14:30:45.123', '2025-01-15 14:30:45.1234567', '2025-01-15 14:30');

SELECT 
    EventDate,
    EventTime,
    EventDateTime,
    EventDateTime2,
    EventSmallDateTime
FROM TemporalExample;

DROP TABLE TemporalExample;
PRINT '';

-- ============================================================================
-- Concept 2: Getting Current Date/Time
-- ============================================================================

PRINT 'Concept 2: Current Date/Time Functions';
PRINT '--------------------------------------';
PRINT '';

SELECT 
    GETDATE() AS GetDate_DateTime,          -- DATETIME, includes time
    SYSDATETIME() AS SysDateTime_DateTime2,  -- DATETIME2, higher precision
    GETUTCDATE() AS GetUtcDate_UTC,          -- UTC time
    CURRENT_TIMESTAMP AS CurrentTimestamp,   -- ANSI standard, same as GETDATE()
    CAST(GETDATE() AS DATE) AS DateOnly,
    CAST(GETDATE() AS TIME) AS TimeOnly;

PRINT '';

-- ============================================================================
-- Concept 3: Date/Time Functions
-- ============================================================================

PRINT 'Concept 3: Date/Time Manipulation';
PRINT '---------------------------------';
PRINT '';

CREATE TABLE Events (
    EventID INT IDENTITY(1,1),
    EventName NVARCHAR(100),
    StartDateTime DATETIME2,
    EndDateTime DATETIME2
);

INSERT INTO Events (EventName, StartDateTime, EndDateTime) VALUES
    (N'Conference', '2025-03-15 09:00:00', '2025-03-17 17:00:00'),
    (N'Workshop', '2025-04-01 10:00:00', '2025-04-01 16:00:00');

-- DATEADD - Add/subtract time intervals
SELECT 
    EventName,
    StartDateTime,
    DATEADD(DAY, 7, StartDateTime) AS OneWeekLater,
    DATEADD(MONTH, -1, StartDateTime) AS OneMonthEarlier,
    DATEADD(HOUR, 3, StartDateTime) AS ThreeHoursLater
FROM Events;

-- DATEDIFF - Calculate difference between dates
SELECT 
    EventName,
    StartDateTime,
    EndDateTime,
    DATEDIFF(DAY, StartDateTime, EndDateTime) AS DurationDays,
    DATEDIFF(HOUR, StartDateTime, EndDateTime) AS DurationHours,
    DATEDIFF(MINUTE, StartDateTime, EndDateTime) AS DurationMinutes
FROM Events;

-- DATEPART and DATENAME
SELECT 
    EventName,
    StartDateTime,
    DATEPART(YEAR, StartDateTime) AS Year,
    DATEPART(MONTH, StartDateTime) AS MonthNumber,
    DATENAME(MONTH, StartDateTime) AS MonthName,
    DATEPART(DAY, StartDateTime) AS DayOfMonth,
    DATENAME(WEEKDAY, StartDateTime) AS DayName,
    DATEPART(HOUR, StartDateTime) AS Hour
FROM Events;

DROP TABLE Events;
PRINT '';

-- ============================================================================
-- Concept 4: Date Formatting
-- ============================================================================

PRINT 'Concept 4: Formatting Dates';
PRINT '---------------------------';
PRINT '';

DECLARE @Now DATETIME2 = SYSDATETIME();

SELECT 
    @Now AS Original,
    CONVERT(VARCHAR(20), @Now, 101) AS US_Format,          -- MM/DD/YYYY
    CONVERT(VARCHAR(20), @Now, 103) AS UK_Format,          -- DD/MM/YYYY
    CONVERT(VARCHAR(20), @Now, 120) AS ISO_Format,         -- YYYY-MM-DD HH:MI:SS
    FORMAT(@Now, 'yyyy-MM-dd') AS CustomFormat1,           -- 2025-01-15
    FORMAT(@Now, 'MMMM dd, yyyy') AS CustomFormat2,        -- January 15, 2025
    FORMAT(@Now, 'dddd, MMMM dd, yyyy') AS CustomFormat3,  -- Wednesday, January 15, 2025
    FORMAT(@Now, 'hh:mm tt') AS TimeFormat;                -- 02:30 PM

PRINT '';

-- ============================================================================
-- Concept 5: Date Ranges and Filtering
-- ============================================================================

PRINT 'Concept 5: Date Ranges and Queries';
PRINT '----------------------------------';
PRINT '';

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1),
    CustomerName NVARCHAR(100),
    OrderDate DATE,
    OrderTime TIME,
    OrderAmount DECIMAL(10, 2)
);

INSERT INTO Orders (CustomerName, OrderDate, OrderTime, OrderAmount) VALUES
    (N'Alice', '2025-01-01', '10:00', 150.00),
    (N'Bob', '2025-01-05', '14:30', 200.00),
    (N'Carol', '2025-01-15', '09:00', 75.00),
    (N'David', '2025-02-01', '16:00', 300.00);

-- Filter by date range
SELECT * FROM Orders
WHERE OrderDate BETWEEN '2025-01-01' AND '2025-01-31';

-- Orders this year
SELECT * FROM Orders
WHERE YEAR(OrderDate) = YEAR(GETDATE());

-- Orders in January
SELECT * FROM Orders
WHERE MONTH(OrderDate) = 1;

-- Orders from last 30 days
SELECT * FROM Orders
WHERE OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));

-- Morning orders (before noon)
SELECT * FROM Orders
WHERE DATEPART(HOUR, OrderTime) < 12;

DROP TABLE Orders;
PRINT '';

-- ============================================================================
-- Concept 6: Timezone Handling
-- ============================================================================

PRINT 'Concept 6: Timezone Awareness';
PRINT '-----------------------------';
PRINT 'DATETIMEOFFSET - Stores timezone offset';
PRINT '';

CREATE TABLE GlobalEvents (
    EventID INT IDENTITY(1,1),
    EventName NVARCHAR(100),
    EventTimeUTC DATETIME2,
    EventTimeLocal DATETIMEOFFSET
);

INSERT INTO GlobalEvents (EventName, EventTimeUTC, EventTimeLocal) VALUES
    (N'New York Event', '2025-03-15 14:00:00', '2025-03-15 09:00:00 -05:00'),
    (N'London Event', '2025-03-15 14:00:00', '2025-03-15 14:00:00 +00:00'),
    (N'Tokyo Event', '2025-03-15 14:00:00', '2025-03-15 23:00:00 +09:00');

SELECT 
    EventName,
    EventTimeUTC,
    EventTimeLocal,
    SWITCHOFFSET(EventTimeLocal, '+00:00') AS ConvertedToUTC
FROM GlobalEvents;

DROP TABLE GlobalEvents;
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Practice Exercises';
PRINT '==================';
PRINT '';
PRINT 'Exercise 1: Create Appointments table with date/time tracking';
PRINT 'Exercise 2: Calculate age from birth date';
PRINT 'Exercise 3: Find upcoming events in next 7 days';
PRINT 'Exercise 4: Format dates in different styles';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
-- Exercise 1
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    PatientName NVARCHAR(100),
    AppointmentDate DATE,
    AppointmentTime TIME,
    CreatedDate DATETIME2 DEFAULT SYSDATETIME()
);

INSERT INTO Appointments (PatientName, AppointmentDate, AppointmentTime) VALUES
    (N'John Smith', '2025-02-01', '10:00'),
    (N'Mary Johnson', '2025-02-05', '14:30'),
    (N'Bob Williams', '2025-02-10', '09:00');

SELECT 
    PatientName,
    AppointmentDate,
    AppointmentTime,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), AppointmentDate) AS DaysUntil,
    CASE 
        WHEN AppointmentDate < CAST(GETDATE() AS DATE) THEN 'PAST'
        WHEN AppointmentDate = CAST(GETDATE() AS DATE) THEN 'TODAY'
        ELSE 'UPCOMING'
    END AS Status
FROM Appointments;

DROP TABLE Appointments;

-- Exercise 2
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeName NVARCHAR(100),
    BirthDate DATE,
    HireDate DATE
);

INSERT INTO Employees (EmployeeName, BirthDate, HireDate) VALUES
    (N'Alice Johnson', '1985-05-15', '2015-03-01'),
    (N'Bob Smith', '1990-08-20', '2018-07-15'),
    (N'Carol Williams', '1982-12-10', '2010-01-20');

SELECT 
    EmployeeName,
    BirthDate,
    DATEDIFF(YEAR, BirthDate, GETDATE()) AS Age,
    HireDate,
    DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsEmployed,
    DATEDIFF(DAY, HireDate, GETDATE()) / 365.25 AS YearsEmployedPrecise
FROM Employees;

DROP TABLE Employees;

-- Exercise 3
CREATE TABLE UpcomingEvents (
    EventID INT PRIMARY KEY IDENTITY(1,1),
    EventName NVARCHAR(100),
    EventDate DATE
);

INSERT INTO UpcomingEvents (EventName, EventDate) VALUES
    (N'Team Meeting', DATEADD(DAY, 2, CAST(GETDATE() AS DATE))),
    (N'Product Launch', DATEADD(DAY, 5, CAST(GETDATE() AS DATE))),
    (N'Training Session', DATEADD(DAY, 10, CAST(GETDATE() AS DATE)));

SELECT 
    EventName,
    EventDate,
    DATEDIFF(DAY, CAST(GETDATE() AS DATE), EventDate) AS DaysAway
FROM UpcomingEvents
WHERE EventDate BETWEEN CAST(GETDATE() AS DATE) 
                    AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
ORDER BY EventDate;

DROP TABLE UpcomingEvents;

-- Exercise 4
DECLARE @SampleDate DATETIME2 = '2025-03-15 14:30:45';

SELECT 
    @SampleDate AS Original,
    FORMAT(@SampleDate, 'MM/dd/yyyy') AS US_Style,
    FORMAT(@SampleDate, 'dd/MM/yyyy') AS UK_Style,
    FORMAT(@SampleDate, 'yyyy-MM-dd') AS ISO_Style,
    FORMAT(@SampleDate, 'MMMM dd, yyyy') AS Long_Style,
    FORMAT(@SampleDate, 'ddd, MMM dd') AS Short_Style,
    FORMAT(@SampleDate, 'hh:mm tt') AS Time_12hr,
    FORMAT(@SampleDate, 'HH:mm:ss') AS Time_24hr;
*/

-- ============================================================================
-- CLEANUP
-- ============================================================================

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 05 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  • DATE for dates only, TIME for times only';
PRINT '  • DATETIME2 preferred over DATETIME for new applications';
PRINT '  • GETDATE() for current datetime, SYSDATETIME() for higher precision';
PRINT '  • DATEADD/DATEDIFF for date arithmetic';
PRINT '  • FORMAT for custom date formatting';
PRINT '  • DATETIMEOFFSET for timezone-aware applications';
PRINT '';
PRINT 'Next: Lesson 06 - Table Creation Basics';
PRINT '';
