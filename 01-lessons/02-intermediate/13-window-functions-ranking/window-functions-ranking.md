# Lesson 13: Window Functions - Ranking & Pagination

**Level:** 🟡 Intermediate

## Learning Objectives

By the end of this lesson you'll be able to:
1. Use ROW_NUMBER, RANK, DENSE_RANK, NTILE
2. Understand the differences between ranking functions
3. Implement top-N per group queries
4. Perform pagination with ROW_NUMBER and OFFSET/FETCH
5. Use NTILE for quartiles and percentiles

---

## Part 1: ROW_NUMBER

Assigns a unique sequential number to each row within a partition.

```sql
SELECT 
    ProductName,
    CategoryID,
    Price,
    ROW_NUMBER() OVER(ORDER BY Price DESC) AS PriceRank
FROM Products;
```

### Top-N per group

```sql
-- Top 3 most expensive products per category
WITH Ranked AS (
    SELECT 
        ProductName,
        CategoryID,
        Price,
        ROW_NUMBER() OVER(PARTITION BY CategoryID ORDER BY Price DESC) AS Rank
    FROM Products
)
SELECT ProductName, CategoryID, Price
FROM Ranked
WHERE Rank <= 3;
```

---

## Part 2: RANK

Assigns rank with gaps for ties.

```sql
SELECT 
    ProductName,
    Price,
    RANK() OVER(ORDER BY Price DESC) AS Rank
FROM Products;

-- If two products have same price, they get same rank, and next rank is skipped
-- Example: 1, 2, 2, 4, 5 (rank 3 skipped)
```

---

## Part 3: DENSE_RANK

Assigns rank without gaps for ties.

```sql
SELECT 
    ProductName,
    Price,
    DENSE_RANK() OVER(ORDER BY Price DESC) AS DenseRank
FROM Products;

-- Example: 1, 2, 2, 3, 4 (no gaps)
```

---

## Part 4: Comparing Ranking Functions

```sql
SELECT 
    ProductName,
    Price,
    ROW_NUMBER() OVER(ORDER BY Price DESC) AS RowNum,
    RANK() OVER(ORDER BY Price DESC) AS Rank,
    DENSE_RANK() OVER(ORDER BY Price DESC) AS DenseRank
FROM Products;
```

| Function | Ties Handling | Sequential |
|----------|---------------|------------|
| ROW_NUMBER | Arbitrary order | Always 1,2,3,4... |
| RANK | Same rank, skip next | 1,2,2,4... (gaps) |
| DENSE_RANK | Same rank, no skip | 1,2,2,3... (no gaps) |

---

## Part 5: NTILE

Divides rows into N buckets (quartiles, deciles, etc.).

```sql
-- Divide products into 4 price quartiles
SELECT 
    ProductName,
    Price,
    NTILE(4) OVER(ORDER BY Price) AS PriceQuartile
FROM Products;
```

### Use cases

- ABC analysis (top 20%, middle 30%, bottom 50%)
- Performance tiers
- Distribution analysis

---

## Part 6: Pagination with ROW_NUMBER

```sql
-- Page 2, 10 rows per page
WITH Paginated AS (
    SELECT 
        ProductID,
        ProductName,
        ROW_NUMBER() OVER(ORDER BY ProductName) AS RowNum
    FROM Products
)
SELECT ProductID, ProductName
FROM Paginated
WHERE RowNum BETWEEN 11 AND 20;
```

### Using OFFSET/FETCH (SQL Server 2012+, PostgreSQL)

```sql
SELECT ProductID, ProductName
FROM Products
ORDER BY ProductName
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
```

---

## Part 7: Practical Examples

### Example 1: Top 5 Customers by Revenue

```sql
WITH CustomerRevenue AS (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS Revenue,
        ROW_NUMBER() OVER(ORDER BY SUM(TotalAmount) DESC) AS Rank
    FROM Orders
    GROUP BY CustomerID
)
SELECT CustomerID, Revenue
FROM CustomerRevenue
WHERE Rank <= 5;
```

### Example 2: Monthly Top Sellers

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        ProductID,
        SUM(Quantity * UnitPrice) AS Revenue,
        RANK() OVER(
            PARTITION BY YEAR(OrderDate), MONTH(OrderDate) 
            ORDER BY SUM(Quantity * UnitPrice) DESC
        ) AS MonthlyRank
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    GROUP BY YEAR(OrderDate), MONTH(OrderDate), ProductID
)
SELECT Year, Month, ProductID, Revenue
FROM MonthlySales
WHERE MonthlyRank = 1;
```

### Example 3: Employee Salary Quartiles

```sql
SELECT 
    EmployeeID,
    EmployeeName,
    Salary,
    NTILE(4) OVER(ORDER BY Salary) AS SalaryQuartile,
    CASE NTILE(4) OVER(ORDER BY Salary)
        WHEN 1 THEN 'Bottom 25%'
        WHEN 2 THEN 'Lower Middle 25%'
        WHEN 3 THEN 'Upper Middle 25%'
        WHEN 4 THEN 'Top 25%'
    END AS QuartileLabel
FROM Employees;
```

---

## Part 8: Deduplication with ROW_NUMBER

```sql
-- Remove duplicate emails, keeping most recent signup
WITH Duplicates AS (
    SELECT 
        Email,
        SignupDate,
        ROW_NUMBER() OVER(PARTITION BY Email ORDER BY SignupDate DESC) AS RowNum
    FROM Users
)
DELETE FROM Users
WHERE Email IN (SELECT Email FROM Duplicates WHERE RowNum > 1);

-- Or for SELECT
SELECT Email, SignupDate
FROM Duplicates
WHERE RowNum = 1;
```

---

## Part 9: Performance Considerations

- Ranking functions require sorting; index ORDER BY columns
- For large result sets, consider pagination at application layer
- ROW_NUMBER is often faster than RANK/DENSE_RANK if ties don't matter
- NTILE can be expensive on very large datasets

---

## Practice Exercises

1. Find the top 10 most expensive products using ROW_NUMBER.
2. Show products ranked by sales volume; handle ties with DENSE_RANK.
3. Divide customers into 5 tiers based on lifetime value using NTILE.
4. Implement pagination: show page 3 of orders (20 per page).

---

## Key Takeaways

- ROW_NUMBER = unique sequential (arbitrary for ties)
- RANK = gaps for ties
- DENSE_RANK = no gaps for ties
- NTILE = divide into N buckets
- Use with PARTITION BY for top-N per group

---

## Next Lesson

Continue to [Lesson 14: Window Functions - Value Functions](../14-window-functions-value/window-functions-value.md).
