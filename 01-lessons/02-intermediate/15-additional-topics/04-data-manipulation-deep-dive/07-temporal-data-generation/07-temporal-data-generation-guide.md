# Temporal Data Generation Guide

## Overview
Learn to generate and construct dates and times in SQL Server. Essential for scheduling, date ranges, calendar tables, and time-based calculations.

---

## Current Date/Time Functions

### Three Ways to Get "Now"

```sql
GETDATE()        → 2025-01-15 14:30:45.123
GETUTCDATE()     → 2025-01-15 19:30:45.123  (UTC)
SYSDATETIME()    → 2025-01-15 14:30:45.1234567  (more precision)
```

**Visual Timeline:**
```
Server Time (EST):     14:30:45
                        │
                        ├── GETDATE() ────────────┐
                        │                         │
UTC Time:              19:30:45                   │
                        │                         │
                        └── GETUTCDATE() ─────────┤
                                                  │
High Precision:        14:30:45.1234567          │
                        │                         │
                        └── SYSDATETIME() ────────┘
```

### When to Use Each

```
GETDATE():
  ✅ Local timestamps
  ✅ Most common use
  ✅ Backward compatible

GETUTCDATE():
  ✅ Global applications
  ✅ Time zone conversions
  ✅ Store in UTC, display local

SYSDATETIME():
  ✅ High precision needed
  ✅ Microsecond accuracy
  ✅ Performance measurements
```

---

## DATEADD Function

### Syntax
```sql
DATEADD(datepart, number, date)
         │         │       │
         │         │       └─ Starting date
         │         └───────── How many to add
         └─────────────────── What to add (DAY, MONTH, etc.)
```

### Common Dateparts

| Datepart | Abbreviation | Example |
|----------|--------------|---------|
| YEAR | yy, yyyy | Add years |
| QUARTER | qq, q | Add quarters |
| MONTH | mm, m | Add months |
| DAY | dd, d | Add days |
| WEEK | wk, ww | Add weeks |
| HOUR | hh | Add hours |
| MINUTE | mi, n | Add minutes |
| SECOND | ss, s | Add seconds |

### Visual Examples

#### Adding Days
```
Today: 2025-01-15

DATEADD(DAY, 7, Today)
  ↓
  │  Jan 2025
  │  S  M  T  W  T  F  S
  │           1  2  3  4
  │  5  6  7  8  9 10 11
  │ 12 13 14 [15]16 17 18
  │ 19 20 21 [22]23 24 25
  │ 26 27 28 29 30 31
  │           └──┘
  │        +7 days = Jan 22
  └────────────────────────→ 2025-01-22
```

#### Adding Months
```
2025-01-15
    │
    ├── DATEADD(MONTH, 1, ...)  → 2025-02-15
    ├── DATEADD(MONTH, 2, ...)  → 2025-03-15
    ├── DATEADD(MONTH, 6, ...)  → 2025-07-15
    └── DATEADD(MONTH, 12, ...) → 2026-01-15
```

#### Subtracting (Negative Numbers)
```
2025-01-15
    │
    ├── DATEADD(DAY, -7, ...)   → 2025-01-08  (last week)
    ├── DATEADD(MONTH, -1, ...) → 2024-12-15  (last month)
    └── DATEADD(YEAR, -1, ...)  → 2024-01-15  (last year)
```

---

## EOMONTH Function

### Purpose
Get the **last day** of the month (End Of MONTH)

### Syntax
```sql
EOMONTH(date, offset)
         │      │
         │      └─ Months to add (0 = current month)
         └──────── Starting date
```

### Visual Examples

#### Current Month
```sql
EOMONTH('2025-01-15', 0)  → 2025-01-31

  Jan 2025
  S  M  T  W  T  F  S
           1  2  3  4
  5  6  7  8  9 10 11
 12 13 14 [15]16 17 18
 19 20 21 22 23 24 25
 26 27 28 29 30 [31]
                 └── Last day!
```

#### With Offset
```sql
Date: 2025-01-15

EOMONTH(..., 0)   → 2025-01-31  (this month)
EOMONTH(..., 1)   → 2025-02-28  (next month)
EOMONTH(..., -1)  → 2024-12-31  (last month)
```

#### Handles Variable Month Lengths
```
Jan (31 days): EOMONTH('2025-01-15', 0) → 2025-01-31
Feb (28 days): EOMONTH('2025-02-15', 0) → 2025-02-28
Apr (30 days): EOMONTH('2025-04-15', 0) → 2025-04-30
```

---

## DATEFROMPARTS Function

### Build Dates from Components

### Syntax
```sql
DATEFROMPARTS(year, month, day)
               │     │      │
               │     │      └─ Day (1-31)
               │     └──────── Month (1-12)
               └────────────── Year (4 digits)
```

### Visual Construction
```
Components:
  Year:  2025
  Month: 1 (January)
  Day:   15

DATEFROMPARTS(2025, 1, 15)
       │       │    │  │
       │       │    │  └── Day = 15
       │       │    └───── Month = 1
       │       └────────── Year = 2025
       └────────────────── Result: 2025-01-15
```

### Practical Examples

#### First Day of Year
```sql
DATEFROMPARTS(2025, 1, 1)  → 2025-01-01
               │    │  │
               │    │  └─ Day 1
               │    └──── January
               └───────── Year 2025
```

#### Dynamic First Day of Month
```sql
DECLARE @SomeDate DATE = '2025-06-15';

DATEFROMPARTS(YEAR(@SomeDate), MONTH(@SomeDate), 1)
              └──── 2025        └───── 6          └─ 1
                    
Result: 2025-06-01
```

---

## Related FROMPARTS Functions

### Complete Family

```sql
-- Date only
DATEFROMPARTS(2025, 1, 15)
  → 2025-01-15

-- Time only
TIMEFROMPARTS(14, 30, 0, 0, 0)
  → 14:30:00

-- DateTime2 (most precise)
DATETIME2FROMPARTS(2025, 1, 15, 14, 30, 0, 0, 7)
  → 2025-01-15 14:30:00.0000000

-- DateTime
DATETIMEFROMPARTS(2025, 1, 15, 14, 30, 0, 0)
  → 2025-01-15 14:30:00.000
```

---

## Date Literals and Formats

### ⚠️ IMPORTANT: Always Use ISO Format

### ISO 8601 Format (Best Practice)
```sql
'YYYY-MM-DD'         -- Date only
'YYYY-MM-DD HH:MM:SS' -- With time
```

**Why ISO Format?**
```
Ambiguous formats:
'01/02/2025'
  ├── USA:  January 2, 2025
  └── UK:   February 1, 2025
  
  Different dates! 😱

ISO format (unambiguous):
'2025-01-02' ✅
  └── Always January 2, 2025 (everywhere!)
```

### Format Comparison

```
Format          | Example      | Ambiguous? | Safe?
----------------|--------------|------------|------
ISO 8601        | 2025-01-15   | No ✅      | Yes ✅
USA             | 01/15/2025   | Maybe ⚠️   | No ❌
UK              | 15/01/2025   | Maybe ⚠️   | No ❌
Compact         | 20250115     | No ✅      | Yes ✅
Text            | Jan 15, 2025 | No ✅      | Maybe ⚠️
```

---

## Generating Date Ranges

### Method 1: Recursive CTE

```sql
-- Generate 30 days starting from today
WITH DateRange AS (
    SELECT CAST(GETDATE() AS DATE) AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < DATEADD(DAY, 29, CAST(GETDATE() AS DATE))
)
SELECT DateValue FROM DateRange;
```

**Visual:**
```
Start: 2025-01-15
  │
  ├── Day 1:  2025-01-15
  ├── Day 2:  2025-01-16
  ├── Day 3:  2025-01-17
  │   ...
  ├── Day 29: 2025-02-12
  └── Day 30: 2025-02-13
```

### Method 2: Numbers Table
```sql
-- Generate all days in 2025
SELECT DATEADD(DAY, n, '2025-01-01') AS DateValue
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.objects
) Numbers
WHERE n < 365;
```

---

## Calendar Table Creation

### Why Create a Calendar Table?
```
Benefits:
  ✅ Pre-calculate business days
  ✅ Mark holidays
  ✅ Fast date lookups
  ✅ Join-friendly
  ✅ One-time creation
```

### Basic Calendar Table

```sql
CREATE TABLE Calendar (
    CalendarDate DATE PRIMARY KEY,
    Year INT,
    Quarter INT,
    Month INT,
    Day INT,
    DayOfWeek INT,
    DayName VARCHAR(10),
    IsWeekend BIT,
    IsHoliday BIT
);

-- Populate for 10 years
WITH DateRange AS (
    SELECT CAST('2020-01-01' AS DATE) AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < '2029-12-31'
)
INSERT INTO Calendar (CalendarDate, Year, Quarter, Month, Day, 
                      DayOfWeek, DayName, IsWeekend)
SELECT 
    DateValue,
    YEAR(DateValue),
    DATEPART(QUARTER, DateValue),
    MONTH(DateValue),
    DAY(DateValue),
    DATEPART(WEEKDAY, DateValue),
    DATENAME(WEEKDAY, DateValue),
    CASE WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1 ELSE 0 END
FROM DateRange
OPTION (MAXRECURSION 4000);
```

**Visual Structure:**
```
Calendar Table:
CalendarDate | Year | Quarter | Month | Day | DayOfWeek | DayName   | IsWeekend
-------------|------|---------|-------|-----|-----------|-----------|----------
2025-01-15   | 2025 | 1       | 1     | 15  | 4         | Wednesday | 0
2025-01-16   | 2025 | 1       | 1     | 16  | 5         | Thursday  | 0
2025-01-17   | 2025 | 1       | 1     | 17  | 6         | Friday    | 0
2025-01-18   | 2025 | 1       | 1     | 18  | 7         | Saturday  | 1 ✓
```

---

## Practical Applications

### Application 1: Warranty Expiration
```sql
-- Product purchased today, 1-year warranty
SELECT 
    GETDATE() AS PurchaseDate,
    DATEADD(YEAR, 1, GETDATE()) AS WarrantyExpires;

Result:
Purchase: 2025-01-15
Expires:  2026-01-15
```

### Application 2: Payment Due Dates
```sql
-- Invoice due in 30 days
SELECT 
    GETDATE() AS InvoiceDate,
    DATEADD(DAY, 30, GETDATE()) AS DueDate,
    DATEADD(DAY, 60, GETDATE()) AS OverdueDate;

Result:
Invoice:  2025-01-15
Due:      2025-02-14
Overdue:  2025-03-16
```

### Application 3: Age Buckets
```sql
-- Categorize orders by age
SELECT 
    OrderID,
    OrderDate,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysOld,
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 30 THEN 'Current'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 60 THEN '30-60 Days'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 90 THEN '60-90 Days'
        ELSE 'Over 90 Days'
    END AS AgeBucket
FROM Orders;
```

---

## Common Patterns

### Pattern 1: First and Last Day of Month
```sql
DECLARE @AnyDate DATE = '2025-06-15';

SELECT 
    DATEFROMPARTS(YEAR(@AnyDate), MONTH(@AnyDate), 1) AS FirstDay,
    EOMONTH(@AnyDate) AS LastDay;

Result:
FirstDay: 2025-06-01
LastDay:  2025-06-30
```

### Pattern 2: Same Day Next Month
```sql
DECLARE @Today DATE = '2025-01-15';

SELECT DATEADD(MONTH, 1, @Today) AS NextMonth;

Result: 2025-02-15
```

### Pattern 3: N Months from Now
```sql
SELECT 
    GETDATE() AS Today,
    DATEADD(MONTH, 3, GETDATE()) AS ThreeMonths,
    DATEADD(MONTH, 6, GETDATE()) AS SixMonths,
    DATEADD(MONTH, 12, GETDATE()) AS OneYear;
```

---

## Quick Reference

| Function | Purpose | Example | Result |
|----------|---------|---------|--------|
| `GETDATE()` | Current local time | `GETDATE()` | `2025-01-15 14:30:45` |
| `GETUTCDATE()` | Current UTC time | `GETUTCDATE()` | `2025-01-15 19:30:45` |
| `DATEADD()` | Add/subtract interval | `DATEADD(DAY, 7, date)` | 7 days later |
| `EOMONTH()` | Last day of month | `EOMONTH(date, 0)` | `2025-01-31` |
| `DATEFROMPARTS()` | Build date | `DATEFROMPARTS(2025,1,15)` | `2025-01-15` |

---

## Common Mistakes

### Mistake 1: Wrong Date Format
```sql
-- ❌ BAD: Ambiguous
CAST('01/02/2025' AS DATE)  -- Jan 2 or Feb 1?

-- ✅ GOOD: ISO format
CAST('2025-01-02' AS DATE)  -- Always Jan 2
```

### Mistake 2: Forgetting Month Boundaries
```sql
-- ❌ BAD: Jan 31 + 1 month = ?
DATEADD(MONTH, 1, '2025-01-31')  -- 2025-02-28 (not 31!)

-- ✅ GOOD: Use EOMONTH if you want last day
EOMONTH(DATEADD(MONTH, 1, '2025-01-31'))  -- 2025-02-28
```

### Mistake 3: Not Handling Leap Years
```sql
-- 2024 is a leap year
DATEFROMPARTS(2024, 2, 29)  -- ✅ Valid

-- 2025 is NOT a leap year
DATEFROMPARTS(2025, 2, 29)  -- ❌ ERROR!
```

---

## Summary

### Key Functions:
1. **GETDATE()** - Current local time
2. **DATEADD()** - Add/subtract intervals
3. **EOMONTH()** - Last day of month
4. **DATEFROMPARTS()** - Build dates from parts

### Best Practices:
- ✅ Always use ISO format (`YYYY-MM-DD`)
- ✅ Use GETUTCDATE() for global apps
- ✅ Create calendar tables for complex queries
- ✅ Handle month boundaries carefully
- ✅ Test with leap years

### Common Uses:
- 📅 Expiration dates (warranties, subscriptions)
- 💰 Payment schedules (due dates, billing)
- 📊 Date ranges (reports, analytics)
- 🗓️ Calendar generation (scheduling)

---

**Master date generation = Master time-based logic!** ⏰

