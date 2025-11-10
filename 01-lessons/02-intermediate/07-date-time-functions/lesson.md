# Lesson 7: Date & Time Functions

**Timeline:** 05:17:11 - 06:53:11  
**Duration:** ~96 minutes  
**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Work with GETDATE(), CURRENT_TIMESTAMP
2. Add/subtract dates with DATEADD and DATEDIFF
3. Extract parts of dates (YEAR, MONTH, DAY)
4. Format dates for presentation
5. Use safe date range filters for performance

---

## Part 1: Current Date & Time

```sql
SELECT GETDATE() AS Now, CURRENT_TIMESTAMP AS Now2;
```

**Note:** Functions differ slightly by RDBMS (GETDATE in SQL Server, NOW() in MySQL/Postgres)

---

## Part 2: DATEADD and DATEDIFF

```sql
-- Add 30 days
SELECT DATEADD(day, 30, GETDATE()) AS In30Days;

-- Difference in days
SELECT DATEDIFF(day, '2024-01-01', GETDATE()) AS DaysSince2024;
```

---

## Part 3: Extracting Parts

```sql
SELECT 
    OrderDate,
    YEAR(OrderDate) AS Yr,
    MONTH(OrderDate) AS Mth,
    DAY(OrderDate) AS Dy
FROM Orders;
```

---

## Part 4: Date Ranges & Best Practices

### Avoid functions on column in WHERE

```sql
-- BAD: prevents index use
WHERE YEAR(OrderDate) = 2024;

-- GOOD: range filter (sargable)
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01';
```

### Last N days

```sql
WHERE OrderDate >= DATEADD(day, -30, GETDATE());
```

---

## Part 5: Formatting Dates

```sql
-- SQL Server
SELECT FORMAT(OrderDate, 'yyyy-MM-dd') AS IsoDate FROM Orders;

-- MySQL/PG use DATE_FORMAT/TO_CHAR respectively
```

---

## Part 6: Time Zone & UTC Notes

- SQL Server stores DATETIME without timezone; use DATETIMEOFFSET for offsets
- For cross-server apps, store UTC and convert at display layer

---

## Part 7: Practical Examples

```sql
-- Orders in last 7 days
SELECT * FROM Orders WHERE OrderDate >= DATEADD(day, -7, CAST(GETDATE() AS DATE));

-- Monthly sales total for past 12 months
SELECT YEAR(OrderDate) AS Yr, MONTH(OrderDate) AS Mth, SUM(TotalAmount) AS MonthlyTotal
FROM Orders
WHERE OrderDate >= DATEADD(month, -12, GETDATE())
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Yr DESC, Mth DESC;
```

---

## Practice Exercises

1. Find users who signed up in the last 90 days.
2. Compute days between SignupDate and LastLogin.
3. Show revenue per quarter for the current year.

---

## Key Takeaways

- Use DATEADD/DATEDIFF for arithmetic
- Use range filters for sargability
- Store UTC for multi-timezone apps

---

## Next Lesson

Continue to [Lesson 8: NULL Functions](../08-null-functions/).
