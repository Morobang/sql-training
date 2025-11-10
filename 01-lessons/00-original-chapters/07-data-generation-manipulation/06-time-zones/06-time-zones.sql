/*
============================================================================
Lesson 07.06 - Time Zones
============================================================================

Description:
Master time zone handling in SQL Server using DATETIMEOFFSET and
AT TIME ZONE. Essential for global applications and distributed systems.

Topics Covered:
• DATETIMEOFFSET data type
• AT TIME ZONE syntax
• UTC conversion
• Time zone offset
• Daylight Saving Time (DST)
• SWITCHOFFSET function
• TODATETIMEOFFSET function
• Best practices for global apps

Prerequisites:
• Lesson 07.07 - Temporal Data Generation
• Understanding of dates and times

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Understanding Time Zones
============================================================================
DATETIME: No time zone awareness (assumes local server time)
DATETIMEOFFSET: Includes UTC offset (+/- hours:minutes)

Format: YYYY-MM-DD HH:MM:SS.fff +/-HH:MM
Example: 2025-01-15 14:30:00.000 -05:00 (EST)
*/

-- Example 1.1: Current time in different formats
SELECT 
    GETDATE() AS LocalDateTime,                    -- Server's local time
    GETUTCDATE() AS UTCDateTime,                   -- Universal Coordinated Time
    SYSDATETIMEOFFSET() AS DateTimeWithOffset;     -- Local time + offset

-- Example 1.2: Create DATETIMEOFFSET values
SELECT 
    CAST('2025-01-15 14:30:00 -05:00' AS DATETIMEOFFSET) AS Eastern,
    CAST('2025-01-15 14:30:00 -08:00' AS DATETIMEOFFSET) AS Pacific,
    CAST('2025-01-15 14:30:00 +00:00' AS DATETIMEOFFSET) AS UTC;

-- Example 1.3: Same moment, different offsets
DECLARE @SameMoment DATETIMEOFFSET = '2025-01-15 14:30:00 -05:00';

SELECT 
    @SameMoment AS OriginalEST,
    SWITCHOFFSET(@SameMoment, '-08:00') AS ConvertedPST,
    SWITCHOFFSET(@SameMoment, '+00:00') AS ConvertedUTC;
-- All represent the SAME moment in time!

-- Example 1.4: Extract offset information
DECLARE @DateTime DATETIMEOFFSET = '2025-01-15 14:30:00 -05:00';

SELECT 
    @DateTime AS FullDateTime,
    CAST(@DateTime AS DATETIME) AS WithoutOffset,
    DATEPART(TZOFFSET, @DateTime) AS OffsetMinutes,  -- -300 minutes
    DATEPART(HOUR, @DateTime) AS Hour,
    DATEPART(MINUTE, @DateTime) AS Minute;


/*
============================================================================
PART 2: AT TIME ZONE Clause
============================================================================
Convert between time zones using named time zones.
Syntax: datetime_value AT TIME ZONE 'time_zone_name'
*/

-- Example 2.1: Convert local time to specific time zone
DECLARE @LocalTime DATETIME = '2025-01-15 14:30:00';

SELECT 
    @LocalTime AS LocalTime,
    @LocalTime AT TIME ZONE 'Eastern Standard Time' AS EST,
    @LocalTime AT TIME ZONE 'Pacific Standard Time' AS PST,
    @LocalTime AT TIME ZONE 'UTC' AS UTC;

-- Example 2.2: Common time zone names
SELECT 
    name AS TimeZoneName,
    current_utc_offset AS CurrentOffset,
    is_currently_dst AS IsDaylightSaving
FROM sys.time_zone_info
WHERE name IN (
    'UTC',
    'Eastern Standard Time',
    'Central Standard Time',
    'Mountain Standard Time',
    'Pacific Standard Time'
)
ORDER BY current_utc_offset DESC;

-- Example 2.3: List all available time zones
SELECT 
    name,
    current_utc_offset,
    is_currently_dst
FROM sys.time_zone_info
ORDER BY current_utc_offset DESC;

-- Example 2.4: Convert between named time zones
DECLARE @NYTime DATETIME = '2025-01-15 14:30:00';

SELECT 
    @NYTime AS OriginalTime,
    @NYTime AT TIME ZONE 'Eastern Standard Time' AS NewYork,
    @NYTime AT TIME ZONE 'Eastern Standard Time' 
        AT TIME ZONE 'Pacific Standard Time' AS LosAngeles,
    @NYTime AT TIME ZONE 'Eastern Standard Time' 
        AT TIME ZONE 'UTC' AS Universal;


/*
============================================================================
PART 3: SWITCHOFFSET Function
============================================================================
Change the offset while keeping the same UTC moment.
*/

-- Example 3.1: Switch offsets
DECLARE @Original DATETIMEOFFSET = '2025-01-15 14:30:00 -05:00';

SELECT 
    @Original AS EST,
    SWITCHOFFSET(@Original, '-08:00') AS PST,
    SWITCHOFFSET(@Original, '+00:00') AS UTC,
    SWITCHOFFSET(@Original, '+09:00') AS Tokyo;

-- Example 3.2: All represent same moment
DECLARE @Moment DATETIMEOFFSET = '2025-01-15 12:00:00 -05:00';

SELECT 
    SWITCHOFFSET(@Moment, '-05:00') AS EST_Noon,
    SWITCHOFFSET(@Moment, '-06:00') AS CST_11AM,
    SWITCHOFFSET(@Moment, '-08:00') AS PST_9AM,
    SWITCHOFFSET(@Moment, '+00:00') AS UTC_5PM;
-- Same moment, different local times!

-- Example 3.3: Convert to UTC for storage
DECLARE @UserInput DATETIMEOFFSET = SYSDATETIMEOFFSET();

SELECT 
    @UserInput AS UserLocalTime,
    SWITCHOFFSET(@UserInput, '+00:00') AS StoredAsUTC;


/*
============================================================================
PART 4: TODATETIMEOFFSET Function
============================================================================
Add offset to DATETIME (assumes it's already in that time zone).
*/

-- Example 4.1: Add offset to datetime
DECLARE @DateTime DATETIME = '2025-01-15 14:30:00';

SELECT 
    @DateTime AS OriginalDateTime,
    TODATETIMEOFFSET(@DateTime, '-05:00') AS WithESTOffset,
    TODATETIMEOFFSET(@DateTime, '-08:00') AS WithPSTOffset;

-- Example 4.2: Different from SWITCHOFFSET
DECLARE @Base DATETIME = '2025-01-15 14:30:00';

SELECT 
    'TODATETIMEOFFSET' AS Method,
    TODATETIMEOFFSET(@Base, '-05:00') AS EST,
    TODATETIMEOFFSET(@Base, '-08:00') AS PST
UNION ALL
SELECT 
    'SWITCHOFFSET' AS Method,
    SWITCHOFFSET(TODATETIMEOFFSET(@Base, '-05:00'), '-05:00') AS EST,
    SWITCHOFFSET(TODATETIMEOFFSET(@Base, '-05:00'), '-08:00') AS PST;
-- TODATETIMEOFFSET: Different moments (local clocks show same time)
-- SWITCHOFFSET: Same moment (different local clocks)


/*
============================================================================
PART 5: UTC Best Practices
============================================================================
Store in UTC, display in user's time zone.
*/

-- Example 5.1: Store UTC, display local
CREATE TABLE #Events (
    EventID INT,
    EventName VARCHAR(100),
    EventTimeUTC DATETIMEOFFSET  -- Always store in UTC!
);

INSERT INTO #Events VALUES
(1, 'Product Launch', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00'));

-- Display in user's time zone:
SELECT 
    EventID,
    EventName,
    EventTimeUTC,
    SWITCHOFFSET(EventTimeUTC, '-05:00') AS EasternTime,
    SWITCHOFFSET(EventTimeUTC, '-08:00') AS PacificTime
FROM #Events;

DROP TABLE #Events;

-- Example 5.2: Convert user input to UTC for storage
DECLARE @UserTime DATETIME = '2025-01-15 14:30:00';
DECLARE @UserTimeZone VARCHAR(50) = 'Eastern Standard Time';

SELECT 
    @UserTime AS UserInput,
    @UserTime AT TIME ZONE @UserTimeZone AS WithOffset,
    @UserTime AT TIME ZONE @UserTimeZone 
        AT TIME ZONE 'UTC' AS ConvertedToUTC;

-- Example 5.3: Real-world scenario - Order timestamps
CREATE TABLE #Orders (
    OrderID INT,
    OrderTimestampUTC DATETIMEOFFSET
);

INSERT INTO #Orders VALUES
(1, '2025-01-15 19:30:00 +00:00'),  -- Stored in UTC
(2, '2025-01-15 20:45:00 +00:00');

-- Display for different regions:
SELECT 
    OrderID,
    OrderTimestampUTC AS UTC,
    SWITCHOFFSET(OrderTimestampUTC, '-05:00') AS NewYork,
    SWITCHOFFSET(OrderTimestampUTC, '-08:00') AS LosAngeles,
    SWITCHOFFSET(OrderTimestampUTC, '+01:00') AS London,
    SWITCHOFFSET(OrderTimestampUTC, '+09:00') AS Tokyo
FROM #Orders;

DROP TABLE #Orders;


/*
============================================================================
PART 6: Daylight Saving Time (DST)
============================================================================
AT TIME ZONE automatically handles DST transitions.
*/

-- Example 6.1: DST awareness
SELECT 
    CAST('2025-03-09 02:30:00' AS DATETIME) AT TIME ZONE 'Eastern Standard Time' AS SpringForward,
    CAST('2025-11-02 01:30:00' AS DATETIME) AT TIME ZONE 'Eastern Standard Time' AS FallBack;
-- SQL Server automatically adjusts for DST!

-- Example 6.2: Compare winter vs summer offsets
SELECT 
    CAST('2025-01-15 12:00:00' AS DATETIME) AT TIME ZONE 'Eastern Standard Time' AS WinterEST,
    CAST('2025-07-15 12:00:00' AS DATETIME) AT TIME ZONE 'Eastern Standard Time' AS SummerEDT;
-- Winter: -05:00 (EST)
-- Summer: -04:00 (EDT - Daylight Time)

-- Example 6.3: Check if DST is active
SELECT 
    name AS TimeZone,
    current_utc_offset AS CurrentOffset,
    is_currently_dst AS IsDST
FROM sys.time_zone_info
WHERE name = 'Eastern Standard Time';


/*
============================================================================
PART 7: Global Application Patterns
============================================================================
*/

-- Pattern 7.1: Multi-timezone event schedule
CREATE TABLE #GlobalMeetings (
    MeetingID INT,
    MeetingName VARCHAR(100),
    MeetingTimeUTC DATETIMEOFFSET
);

INSERT INTO #GlobalMeetings VALUES
(1, 'All-Hands Meeting', '2025-01-20 15:00:00 +00:00'),
(2, 'Product Demo', '2025-01-21 18:00:00 +00:00');

-- Show meeting times for global teams:
SELECT 
    MeetingName,
    MeetingTimeUTC AS UTC,
    FORMAT(SWITCHOFFSET(MeetingTimeUTC, '-05:00'), 'yyyy-MM-dd hh:mm tt') AS NewYork,
    FORMAT(SWITCHOFFSET(MeetingTimeUTC, '-08:00'), 'yyyy-MM-dd hh:mm tt') AS SanFrancisco,
    FORMAT(SWITCHOFFSET(MeetingTimeUTC, '+00:00'), 'yyyy-MM-dd hh:mm tt') AS London,
    FORMAT(SWITCHOFFSET(MeetingTimeUTC, '+08:00'), 'yyyy-MM-dd hh:mm tt') AS Singapore
FROM #GlobalMeetings;

DROP TABLE #GlobalMeetings;

-- Pattern 7.2: Calculate duration across time zones
DECLARE @MeetingStart DATETIMEOFFSET = '2025-01-20 09:00:00 -05:00';  -- 9 AM EST
DECLARE @MeetingEnd DATETIMEOFFSET = '2025-01-20 10:30:00 -05:00';    -- 10:30 AM EST

SELECT 
    @MeetingStart AS StartEST,
    @MeetingEnd AS EndEST,
    DATEDIFF(MINUTE, @MeetingStart, @MeetingEnd) AS DurationMinutes,
    SWITCHOFFSET(@MeetingStart, '-08:00') AS StartPST,
    SWITCHOFFSET(@MeetingEnd, '-08:00') AS EndPST;
-- Duration is same regardless of time zone!

-- Pattern 7.3: Filter by local business hours
CREATE TABLE #Transactions (
    TransactionID INT,
    TransactionTimeUTC DATETIMEOFFSET
);

INSERT INTO #Transactions VALUES
(1, '2025-01-15 14:00:00 +00:00'),  -- 9 AM EST
(2, '2025-01-15 20:00:00 +00:00'),  -- 3 PM EST
(3, '2025-01-15 02:00:00 +00:00');  -- 9 PM EST (prev day)

-- Find transactions during EST business hours (9 AM - 5 PM):
SELECT 
    TransactionID,
    TransactionTimeUTC AS UTC,
    SWITCHOFFSET(TransactionTimeUTC, '-05:00') AS EST,
    DATEPART(HOUR, SWITCHOFFSET(TransactionTimeUTC, '-05:00')) AS ESTHour
FROM #Transactions
WHERE DATEPART(HOUR, SWITCHOFFSET(TransactionTimeUTC, '-05:00')) BETWEEN 9 AND 16;

DROP TABLE #Transactions;


/*
============================================================================
PART 8: Common Pitfalls and Solutions
============================================================================
*/

-- Pitfall 8.1: Comparing DATETIME to DATETIMEOFFSET
DECLARE @DateTime DATETIME = '2025-01-15 14:30:00';
DECLARE @DateTimeOffset DATETIMEOFFSET = '2025-01-15 14:30:00 -05:00';

-- ❌ This comparison might not work as expected:
-- WHERE @DateTime = @DateTimeOffset

-- ✅ Convert to same type:
SELECT 
    CASE 
        WHEN CAST(@DateTime AS DATETIMEOFFSET) = @DateTimeOffset 
        THEN 'Equal' 
        ELSE 'Different' 
    END AS Comparison1,
    CASE 
        WHEN @DateTime = CAST(@DateTimeOffset AS DATETIME) 
        THEN 'Equal' 
        ELSE 'Different' 
    END AS Comparison2;

-- Pitfall 8.2: Assuming server time zone
-- ❌ BAD: Relying on server's local time
SELECT GETDATE() AS AssumedLocal;

-- ✅ GOOD: Always specify or convert to known time zone
SELECT 
    GETUTCDATE() AS UTC,
    SYSDATETIMEOFFSET() AS LocalWithOffset;

-- Pitfall 8.3: Hardcoding offsets instead of names
-- ❌ BAD: Hardcoded offset (doesn't handle DST)
DECLARE @Bad DATETIME = '2025-07-15 12:00:00';
SELECT TODATETIMEOFFSET(@Bad, '-05:00') AS HardcodedOffset;

-- ✅ GOOD: Use named time zone (handles DST)
DECLARE @Good DATETIME = '2025-07-15 12:00:00';
SELECT @Good AT TIME ZONE 'Eastern Standard Time' AS NamedZone;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

Try these on your own:

1. Convert current time to 5 different time zones
2. Store order timestamp as UTC, display as EST and PST
3. Calculate meeting duration in minutes (works across zones)
4. Find all events happening "today" in Tokyo time zone
5. Create a world clock showing current time in major cities

Solutions below ↓
*/

-- Solution 1: Current time in multiple zones
SELECT 
    SYSDATETIMEOFFSET() AS ServerTime,
    SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00') AS UTC,
    SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00') AS NewYork,
    SWITCHOFFSET(SYSDATETIMEOFFSET(), '-08:00') AS LosAngeles,
    SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00') AS London,
    SWITCHOFFSET(SYSDATETIMEOFFSET(), '+09:00') AS Tokyo;

-- Solution 2: Store UTC, display local
CREATE TABLE #OrdersDemo (
    OrderID INT,
    OrderTimeUTC DATETIMEOFFSET
);

INSERT INTO #OrdersDemo VALUES
(1, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00'));

SELECT 
    OrderID,
    OrderTimeUTC,
    SWITCHOFFSET(OrderTimeUTC, '-05:00') AS EasternTime,
    SWITCHOFFSET(OrderTimeUTC, '-08:00') AS PacificTime
FROM #OrdersDemo;

DROP TABLE #OrdersDemo;

-- Solution 3: Calculate duration
DECLARE @Start DATETIMEOFFSET = '2025-01-15 14:00:00 -05:00';
DECLARE @End DATETIMEOFFSET = '2025-01-15 16:30:00 -08:00';

SELECT 
    @Start AS StartTime,
    @End AS EndTime,
    DATEDIFF(MINUTE, @Start, @End) AS DurationMinutes,
    DATEDIFF(HOUR, @Start, @End) AS DurationHours;

-- Solution 4: Events "today" in Tokyo
CREATE TABLE #GlobalEvents (
    EventID INT,
    EventTimeUTC DATETIMEOFFSET
);

INSERT INTO #GlobalEvents VALUES
(1, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00'));

SELECT 
    EventID,
    EventTimeUTC,
    SWITCHOFFSET(EventTimeUTC, '+09:00') AS TokyoTime
FROM #GlobalEvents
WHERE CAST(SWITCHOFFSET(EventTimeUTC, '+09:00') AS DATE) = 
      CAST(SWITCHOFFSET(SYSDATETIMEOFFSET(), '+09:00') AS DATE);

DROP TABLE #GlobalEvents;

-- Solution 5: World clock
SELECT 
    'UTC' AS City, SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00') AS CurrentTime
UNION ALL
SELECT 'New York', SWITCHOFFSET(SYSDATETIMEOFFSET(), '-05:00')
UNION ALL
SELECT 'Chicago', SWITCHOFFSET(SYSDATETIMEOFFSET(), '-06:00')
UNION ALL
SELECT 'Los Angeles', SWITCHOFFSET(SYSDATETIMEOFFSET(), '-08:00')
UNION ALL
SELECT 'London', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+00:00')
UNION ALL
SELECT 'Paris', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+01:00')
UNION ALL
SELECT 'Dubai', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+04:00')
UNION ALL
SELECT 'Singapore', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+08:00')
UNION ALL
SELECT 'Tokyo', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+09:00')
UNION ALL
SELECT 'Sydney', SWITCHOFFSET(SYSDATETIMEOFFSET(), '+11:00');


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ DATA TYPES:
  • DATETIME: No time zone info
  • DATETIMEOFFSET: Includes UTC offset
  • Always store in UTC when possible

✓ FUNCTIONS:
  • AT TIME ZONE: Convert using named zones (handles DST)
  • SWITCHOFFSET: Change offset (same moment)
  • TODATETIMEOFFSET: Add offset to DATETIME
  • SYSDATETIMEOFFSET: Current time with offset

✓ BEST PRACTICES:
  • Store all times in UTC
  • Convert to user's zone for display
  • Use AT TIME ZONE for DST handling
  • Never hardcode offsets
  • Query sys.time_zone_info for available zones

✓ COMMON PATTERNS:
  • Store: SWITCHOFFSET(value, '+00:00')
  • Display: SWITCHOFFSET(utc_value, user_offset)
  • Compare: Always use same time zone
  • Duration: DATEDIFF works across zones

✓ AVOID:
  • Assuming server's local time zone
  • Hardcoding UTC offsets
  • Mixing DATETIME and DATETIMEOFFSET without conversion
  • Forgetting about Daylight Saving Time

============================================================================
NEXT: Lesson 07.08 - Temporal Data Manipulation
Learn to extract and manipulate date/time components.
============================================================================
*/
