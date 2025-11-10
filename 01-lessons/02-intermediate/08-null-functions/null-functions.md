# Lesson 8: NULL Handling & Functions

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Understand NULL behavior in SQL (three-valued logic)
2. Use IS NULL and IS NOT NULL correctly
3. Apply COALESCE and ISNULL/IFNULL for default values
4. Handle NULLs in calculations and comparisons
5. Use NULLIF to prevent division by zero

---

## Part 1: Understanding NULL

NULL represents missing or unknown data. It's NOT the same as zero, empty string, or false.

```sql
-- NULL comparisons return NULL (unknown), not true/false
SELECT * FROM Products WHERE Price = NULL; -- Returns nothing (incorrect)
SELECT * FROM Products WHERE Price IS NULL; -- Correct
```

### Three-valued logic

- true, false, **unknown** (NULL)
- NULL AND true = NULL
- NULL OR true = true
- NOT NULL = NULL

---

## Part 2: IS NULL and IS NOT NULL

```sql
-- Find products without a description
SELECT ProductID, ProductName
FROM Products
WHERE Description IS NULL;

-- Find products with a description
SELECT ProductID, ProductName
FROM Products
WHERE Description IS NOT NULL;
```

---

## Part 3: COALESCE

Returns the first non-NULL value in the list.

```sql
-- Use backup email if primary is NULL
SELECT 
    CustomerID,
    COALESCE(Email, BackupEmail, 'no-email@example.com') AS ContactEmail
FROM Customers;

-- Default zero for NULL prices
SELECT ProductName, COALESCE(Price, 0) AS Price
FROM Products;
```

---

## Part 4: ISNULL (SQL Server) / IFNULL (MySQL)

```sql
-- SQL Server
SELECT ProductName, ISNULL(Price, 0) AS Price FROM Products;

-- MySQL
SELECT ProductName, IFNULL(Price, 0) AS Price FROM Products;
```

**Note:** COALESCE is ANSI standard and accepts multiple arguments; ISNULL/IFNULL are vendor-specific and accept only two.

---

## Part 5: NULLIF

Returns NULL if two expressions are equal; otherwise returns the first expression.

```sql
-- Prevent division by zero
SELECT 
    TotalRevenue,
    TotalOrders,
    TotalRevenue / NULLIF(TotalOrders, 0) AS AvgOrderValue
FROM SalesStats;
```

---

## Part 6: NULL in Calculations

NULL in arithmetic makes the whole expression NULL.

```sql
-- If Discount is NULL, FinalPrice becomes NULL
SELECT Price * (1 - Discount) AS FinalPrice FROM Products; -- BAD

-- Handle NULL explicitly
SELECT Price * (1 - COALESCE(Discount, 0)) AS FinalPrice FROM Products; -- GOOD
```

---

## Part 7: NULL in Aggregates

Most aggregate functions ignore NULL values (except COUNT(*)).

```sql
SELECT 
    COUNT(*) AS TotalRows,
    COUNT(Email) AS RowsWithEmail, -- Ignores NULLs
    AVG(Price) AS AvgPrice -- Ignores NULL prices
FROM Products;
```

---

## Part 8: NULL in ORDER BY

NULL sorting behavior varies by RDBMS:
- SQL Server: NULLs first (ascending)
- MySQL/Postgres: NULLs last (ascending) by default

```sql
-- Force NULLs last (SQL Server)
ORDER BY CASE WHEN Price IS NULL THEN 1 ELSE 0 END, Price;
```

---

## Part 9: Practical Examples

```sql
-- Find customers with incomplete profiles
SELECT CustomerID, FirstName, LastName
FROM Customers
WHERE Email IS NULL OR Phone IS NULL;

-- Safe concatenation handling NULLs
SELECT CONCAT(FirstName, ' ', COALESCE(MiddleName, ''), ' ', LastName) AS FullName
FROM Customers;

-- Calculate percentage with NULL protection
SELECT 
    CategoryName,
    TotalSales,
    PreviousSales,
    CASE 
        WHEN PreviousSales IS NULL OR PreviousSales = 0 THEN NULL
        ELSE ((TotalSales - PreviousSales) / NULLIF(PreviousSales, 0.0)) * 100
    END AS GrowthPercent
FROM CategoryStats;
```

---

## Practice Exercises

1. Find all orders where ShippingAddress is NULL but BillingAddress is NOT NULL.
2. Use COALESCE to show ProductName, or if NULL, show 'Unnamed Product'.
3. Calculate average rating, treating NULL ratings as 0 using COALESCE.

---

## Key Takeaways

- Use IS NULL, not = NULL
- COALESCE returns first non-NULL
- NULLIF prevents division by zero
- NULL in calculations propagates
- Aggregates ignore NULL (except COUNT(*))

---

## Next Lesson

Continue to [Lesson 9: CASE Expressions](../09-case-expressions/09-case-expressions.md).
