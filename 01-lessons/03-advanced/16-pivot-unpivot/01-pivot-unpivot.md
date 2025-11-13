# PIVOT and UNPIVOT

## 📚 Overview

PIVOT transforms rows into columns (cross-tab reports), while UNPIVOT does the reverse. These powerful operators let you reshape data for reporting and analysis without complex CASE statements.

---

## 🎯 What You'll Learn

- PIVOT syntax and usage
- UNPIVOT syntax and usage
- Dynamic PIVOT with dynamic column lists
- When to use PIVOT vs CASE
- Practical reporting with TechStore
- Performance considerations

---

## 💡 Key Concepts

### **PIVOT - Rows to Columns:**
```sql
-- Before PIVOT:
-- Category    | Price
-- Peripherals | 49.99
-- Peripherals | 129.99
-- Storage     | 199.99

-- After PIVOT:
-- Category    | MinPrice | MaxPrice | AvgPrice
-- Peripherals | 49.99    | 129.99   | 89.99
-- Storage     | 199.99   | 199.99   | 199.99

SELECT Category, [MinPrice], [MaxPrice], [AvgPrice]
FROM (
    SELECT Category, Price
    FROM Products
) AS SourceData
PIVOT (
    AVG(Price)
    FOR Category IN ([Peripherals], [Storage], [Audio])
) AS PivotTable;
```

### **UNPIVOT - Columns to Rows:**
```sql
-- Before UNPIVOT:
-- Product  | Q1    | Q2    | Q3
-- Mouse    | 100   | 150   | 200

-- After UNPIVOT:
-- Product  | Quarter | Sales
-- Mouse    | Q1      | 100
-- Mouse    | Q2      | 150
-- Mouse    | Q3      | 200

SELECT Product, Quarter, Sales
FROM QuarterlySales
UNPIVOT (
    Sales FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS UnpivotTable;
```

---

## 🔄 PIVOT vs CASE Statement

### Using CASE (Traditional):
```sql
SELECT 
    YEAR(SaleDate) AS Year,
    SUM(CASE WHEN MONTH(SaleDate) = 1 THEN TotalAmount ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(SaleDate) = 2 THEN TotalAmount ELSE 0 END) AS Feb,
    SUM(CASE WHEN MONTH(SaleDate) = 3 THEN TotalAmount ELSE 0 END) AS Mar
FROM Sales
GROUP BY YEAR(SaleDate);
```

### Using PIVOT (Cleaner):
```sql
SELECT Year, [1] AS Jan, [2] AS Feb, [3] AS Mar
FROM (
    SELECT YEAR(SaleDate) AS Year, MONTH(SaleDate) AS Month, TotalAmount
    FROM Sales
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1], [2], [3])
) AS PivotTable;
```

---

## 📊 Real-World Applications

### **Sales by Month Report:**
```sql
-- Show revenue per month for each year
SELECT *
FROM (
    SELECT 
        YEAR(SaleDate) AS Year,
        MONTH(SaleDate) AS Month,
        TotalAmount
    FROM Sales
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
) AS MonthlyRevenue
ORDER BY Year;
```

### **Products by Category:**
```sql
-- Count products in each category
SELECT *
FROM (
    SELECT Category, ProductName
    FROM Products
) AS SourceData
PIVOT (
    COUNT(ProductName)
    FOR Category IN ([Peripherals], [Storage], [Audio], [Accessories])
) AS CategoryCount;
```

---

## 🎯 When to Use PIVOT

### ✅ **Use PIVOT when:**
- Creating cross-tab reports
- Known fixed columns
- Simple aggregations (SUM, AVG, COUNT)
- Need cleaner syntax than CASE

### ❌ **Use CASE when:**
- Dynamic column lists
- Complex calculations
- Multiple aggregations
- Conditional logic needed

---

## 💡 Dynamic PIVOT

For unknown columns at design time:

```sql
DECLARE @columns NVARCHAR(MAX);
DECLARE @sql NVARCHAR(MAX);

-- Get column list dynamically
SELECT @columns = STRING_AGG(QUOTENAME(Category), ',')
FROM (SELECT DISTINCT Category FROM Products) AS Categories;

-- Build dynamic PIVOT query
SET @sql = N'
SELECT *
FROM (
    SELECT Category, ProductName
    FROM Products
) AS SourceData
PIVOT (
    COUNT(ProductName)
    FOR Category IN (' + @columns + ')
) AS PivotTable';

EXEC sp_executesql @sql;
```

---

## 🔗 Practice Files

Work through these SQL files in order:

1. `01-basic-pivot.sql` - Simple PIVOT examples
2. `02-pivot-aggregations.sql` - Different aggregate functions
3. `03-unpivot.sql` - Converting columns to rows
4. `04-dynamic-pivot.sql` - Dynamic column lists
5. `05-practical-pivot.sql` - Real-world TechStore reports

---

## 💡 Pro Tips

- Source query for PIVOT must return exactly 3 columns
- NULL values are ignored in aggregation
- Use ISNULL() to replace NULLs with 0
- Dynamic PIVOT requires dynamic SQL
- Consider using window functions instead for complex scenarios
- Test with small datasets first

---

**Ready to master data reshaping? Start with `01-basic-pivot.sql`! 🚀**
