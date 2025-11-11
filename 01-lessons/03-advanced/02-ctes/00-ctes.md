# Common Table Expressions (CTEs)

## 📚 Overview

CTEs (Common Table Expressions) are temporary named result sets that exist only during query execution. They make complex queries more readable and maintainable by breaking them into logical, reusable parts.

---

## 🎯 What You'll Learn

- Basic CTE syntax with WITH clause
- Multiple CTEs in one query
- Recursive CTEs for hierarchical data
- When to use CTEs vs subqueries
- Performance considerations
- Practical applications with TechStore

---

## 💡 Key Concepts

### **Basic CTE Syntax:**
```sql
WITH CTE_Name AS (
    -- Your SELECT statement here
    SELECT Column1, Column2
    FROM Table
    WHERE Condition
)
SELECT *
FROM CTE_Name;
```

### **Multiple CTEs:**
```sql
WITH 
CTE1 AS (SELECT...),
CTE2 AS (SELECT...),
CTE3 AS (SELECT...)
SELECT *
FROM CTE1
JOIN CTE2 ON...
JOIN CTE3 ON...;
```

### **Recursive CTE:**
```sql
WITH RecursiveCTE AS (
    -- Anchor member
    SELECT...
    UNION ALL
    -- Recursive member
    SELECT...
    FROM RecursiveCTE
    WHERE...
)
SELECT * FROM RecursiveCTE;
```

---

## 🔄 CTEs vs Subqueries

| Feature | CTE | Subquery |
|---------|-----|----------|
| **Readability** | ✅ Very clear | ❌ Can get messy |
| **Reusability** | ✅ Reference multiple times | ❌ Must repeat |
| **Recursion** | ✅ Supported | ❌ Not supported |
| **Performance** | Similar to subquery | Similar to CTE |
| **Debugging** | ✅ Easy to test parts | ❌ Harder to isolate |

---

## 🎯 When to Use CTEs

✅ **Use CTEs when:**
- Query has multiple subqueries
- Need to reference same result set multiple times
- Working with hierarchical data (recursive)
- Want to improve code readability
- Debugging complex queries

❌ **Use subqueries when:**
- Simple, one-time operation
- Single use inline value
- Very small result set

---

## 📊 Real-World Applications

### Sales Analysis
```sql
WITH MonthlySales AS (
    SELECT 
        YEAR(SaleDate) AS Year,
        MONTH(SaleDate) AS Month,
        SUM(TotalAmount) AS Revenue
    FROM Sales
    GROUP BY YEAR(SaleDate), MONTH(SaleDate)
)
SELECT 
    Year,
    Month,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year, Month) AS PrevMonthRevenue,
    Revenue - LAG(Revenue) OVER (ORDER BY Year, Month) AS Growth
FROM MonthlySales;
```

### Customer Segmentation
```sql
WITH CustomerStats AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalSpent
    FROM Sales
    GROUP BY CustomerID
)
SELECT 
    c.CustomerName,
    cs.OrderCount,
    cs.TotalSpent,
    CASE 
        WHEN cs.TotalSpent >= 1000 THEN 'VIP'
        WHEN cs.TotalSpent >= 500 THEN 'Gold'
        ELSE 'Standard'
    END AS Tier
FROM Customers c
INNER JOIN CustomerStats cs ON c.CustomerID = cs.CustomerID;
```

---

## 🔗 Practice Files

Work through these SQL files in order:

1. `01-basic-cte.sql` - Simple CTE examples
2. `02-multiple-ctes.sql` - Multiple CTEs in one query
3. `03-recursive-cte.sql` - Hierarchical data traversal
4. `04-cte-vs-subquery.sql` - Comparison examples
5. `05-practical-ctes.sql` - Real-world TechStore applications

---

## 💡 Pro Tips

- Name CTEs descriptively (e.g., `MonthlyRevenue`, `TopCustomers`)
- Break complex logic into multiple CTEs
- Use CTEs to improve query debugging
- Recursive CTEs need MAXRECURSION option for deep hierarchies
- CTEs are optimized similar to subqueries (not always materialized)

---

**Ready to master CTEs? Start with `01-basic-cte.sql`! 🚀**
