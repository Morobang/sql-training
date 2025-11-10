# Lesson 2: Common Table Expressions (CTEs)

**Timeline:** 14:12:29 - 15:04:29  
**Duration:** ~52 minutes  
**Level:** 🔴 Advanced

## Learning Objectives

By the end of this lesson you'll be able to:
1. Write CTEs with the WITH clause
2. Use multiple CTEs in a single query
3. Create recursive CTEs for hierarchical data
4. Understand when to use CTEs vs subqueries vs temp tables
5. Optimize CTE performance

---

## Part 1: CTE Basics

CTEs (Common Table Expressions) are named temporary result sets that exist only during query execution.

```sql
WITH HighPriceProducts AS (
    SELECT ProductID, ProductName, Price
    FROM Products
    WHERE Price > 100
)
SELECT *
FROM HighPriceProducts
WHERE ProductName LIKE 'A%';
```

---

## Part 2: Multiple CTEs

```sql
WITH 
CategoryAvg AS (
    SELECT CategoryID, AVG(Price) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
),
HighValueCategories AS (
    SELECT CategoryID
    FROM CategoryAvg
    WHERE AvgPrice > 50
)
SELECT p.ProductName, p.Price, ca.AvgPrice
FROM Products p
INNER JOIN CategoryAvg ca ON p.CategoryID = ca.CategoryID
INNER JOIN HighValueCategories hvc ON p.CategoryID = hvc.CategoryID;
```

---

## Part 3: CTEs for Readability

CTEs make complex queries more readable by breaking logic into named steps.

```sql
-- Without CTE (nested subqueries)
SELECT *
FROM (
    SELECT CustomerID, SUM(TotalAmount) AS Revenue
    FROM Orders
    GROUP BY CustomerID
) AS CustomerRevenue
WHERE Revenue > (
    SELECT AVG(Revenue)
    FROM (
        SELECT SUM(TotalAmount) AS Revenue
        FROM Orders
        GROUP BY CustomerID
    ) AS AvgRev
);

-- With CTEs (clearer)
WITH CustomerRevenue AS (
    SELECT CustomerID, SUM(TotalAmount) AS Revenue
    FROM Orders
    GROUP BY CustomerID
),
AvgRevenue AS (
    SELECT AVG(Revenue) AS AvgRev
    FROM CustomerRevenue
)
SELECT cr.CustomerID, cr.Revenue
FROM CustomerRevenue cr
CROSS JOIN AvgRevenue ar
WHERE cr.Revenue > ar.AvgRev;
```

---

## Part 4: Recursive CTEs

Recursive CTEs call themselves to process hierarchical or graph data.

### Syntax

```sql
WITH RecursiveCTE AS (
    -- Anchor member (base case)
    SELECT ...
    
    UNION ALL
    
    -- Recursive member (references RecursiveCTE)
    SELECT ...
    FROM RecursiveCTE
    WHERE ...
)
SELECT * FROM RecursiveCTE;
```

### Example: Employee Hierarchy

```sql
WITH EmployeeHierarchy AS (
    -- Anchor: top-level employees (no manager)
    SELECT EmployeeID, EmployeeName, ManagerID, 1 AS Level
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive: employees reporting to previous level
    SELECT e.EmployeeID, e.EmployeeName, e.ManagerID, eh.Level + 1
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT EmployeeID, EmployeeName, Level
FROM EmployeeHierarchy
ORDER BY Level, EmployeeName;
```

### Example: Number Series

```sql
WITH Numbers AS (
    SELECT 1 AS N
    UNION ALL
    SELECT N + 1
    FROM Numbers
    WHERE N < 100
)
SELECT N FROM Numbers;
```

**Warning:** Always include a termination condition to prevent infinite recursion.

---

## Part 5: Recursive CTE - Bill of Materials

```sql
-- Parts hierarchy (parent-child relationship)
WITH PartHierarchy AS (
    -- Anchor: top-level assemblies
    SELECT PartID, PartName, ParentPartID, 1 AS Level, CAST(PartName AS VARCHAR(1000)) AS Path
    FROM Parts
    WHERE ParentPartID IS NULL
    
    UNION ALL
    
    -- Recursive: sub-parts
    SELECT p.PartID, p.PartName, p.ParentPartID, ph.Level + 1, CAST(ph.Path + ' > ' + p.PartName AS VARCHAR(1000))
    FROM Parts p
    INNER JOIN PartHierarchy ph ON p.ParentPartID = ph.PartID
)
SELECT PartID, PartName, Level, Path
FROM PartHierarchy
ORDER BY Path;
```

---

## Part 6: CTEs vs Alternatives

| Scenario | Best Choice |
|----------|-------------|
| Single use, simple | Subquery |
| Multiple references | CTE or Temp Table |
| Recursive logic | Recursive CTE |
| Large intermediate results | Temp Table (materialized) |
| Cross-query use | Temp Table or Table Variable |

---

## Part 7: Performance Considerations

### CTEs are NOT materialized by default

CTEs are expanded inline; the optimizer may execute them multiple times if referenced multiple times.

```sql
-- CTE may execute twice
WITH ExpensiveCalc AS (
    SELECT ... -- Complex aggregation
)
SELECT *
FROM ExpensiveCalc e1
INNER JOIN ExpensiveCalc e2 ON e1.ID = e2.ParentID;
```

**Solution:** Use temp tables for expensive operations referenced multiple times.

```sql
-- Better for multiple references
SELECT ... INTO #ExpensiveCalc FROM ...;

SELECT *
FROM #ExpensiveCalc e1
INNER JOIN #ExpensiveCalc e2 ON e1.ID = e2.ParentID;
```

### Recursive CTE Performance

- Index columns used in joins and WHERE
- Set MAXRECURSION option if needed (default 100)

```sql
WITH EmployeeHierarchy AS (...)
SELECT * FROM EmployeeHierarchy
OPTION (MAXRECURSION 1000);
```

---

## Part 8: Practical Examples

### Example 1: Month-over-Month Growth

```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(TotalAmount) AS Revenue
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),
SalesWithPrevious AS (
    SELECT 
        Year, Month, Revenue,
        LAG(Revenue) OVER(ORDER BY Year, Month) AS PrevRevenue
    FROM MonthlySales
)
SELECT 
    Year, Month, Revenue, PrevRevenue,
    ((Revenue - PrevRevenue) * 100.0 / PrevRevenue) AS GrowthPercent
FROM SalesWithPrevious
WHERE PrevRevenue IS NOT NULL;
```

### Example 2: Recursive Date Range

```sql
DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-12-31';

WITH DateRange AS (
    SELECT @StartDate AS CalendarDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateRange
    WHERE CalendarDate < @EndDate
)
SELECT CalendarDate, DATENAME(WEEKDAY, CalendarDate) AS DayName
FROM DateRange
OPTION (MAXRECURSION 366);
```

---

## Practice Exercises

1. Write a CTE to find customers with above-average lifetime value.
2. Use multiple CTEs to calculate top 10 products by revenue in each category.
3. Create a recursive CTE to generate a Fibonacci sequence (first 20 numbers).
4. Build an organizational chart using recursive CTE on an Employees table with ManagerID.

---

## Key Takeaways

- CTEs improve readability and modularity
- Use WITH to define one or more CTEs
- Recursive CTEs handle hierarchies and graphs
- CTEs are NOT materialized; consider temp tables for multiple references
- Always include termination condition in recursive CTEs

---

## Next Lesson

Continue to [Lesson 3: Views](../03-views/).
