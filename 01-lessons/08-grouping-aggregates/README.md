# Chapter 08: Grouping and Aggregates

## Overview
Master the power of GROUP BY and aggregate functions to summarize and analyze data. Learn to transform raw data into meaningful insights through grouping, counting, summing, and statistical analysis.

---

## What You'll Learn

By the end of this chapter, you will be able to:

1. **Understand grouping concepts** and when to use GROUP BY
2. **Use aggregate functions** (COUNT, SUM, AVG, MIN, MAX)
3. **Differentiate between implicit and explicit groups**
4. **Count distinct values** and handle duplicates
5. **Group by expressions and calculations**
6. **Handle NULL values** in aggregate functions
7. **Create single and multi-column groups**
8. **Generate rollups and subtotals**
9. **Filter groups** with HAVING clause
10. **Combine grouping with other clauses** for complex analysis

---

## Chapter Structure

### 📚 Lessons (12 lessons • ~5 hours)

| # | Lesson | Topics | Time |
|---|--------|--------|------|
| 01 | **Grouping Concepts** | What is grouping, when to group, GROUP BY basics | 20 min |
| 02 | **Aggregate Functions** | COUNT, SUM, AVG, MIN, MAX, statistical functions | 30 min |
| 03 | **Implicit vs Explicit Groups** | Understanding group behavior, all-or-nothing rule | 20 min |
| 04 | **Counting Distinct Values** | COUNT(DISTINCT), removing duplicates, unique counts | 25 min |
| 05 | **Using Expressions** | Grouping by calculations, derived columns | 25 min |
| 06 | **NULL Handling in Aggregates** | How NULLs affect results, COALESCE strategies | 25 min |
| 07 | **Single Column Grouping** | Group by one column, common patterns | 25 min |
| 08 | **Multi-Column Grouping** | Group by multiple columns, hierarchical grouping | 30 min |
| 09 | **Grouping Expressions** | CASE in GROUP BY, computed groups | 25 min |
| 10 | **Generating Rollups** | ROLLUP, CUBE, GROUPING SETS for subtotals | 35 min |
| 11 | **Group Filter Conditions** | HAVING clause, filtering aggregates, WHERE vs HAVING | 30 min |
| 12 | **Test Your Knowledge** | Comprehensive assessment | 60 min |

---

## Key Concepts

### Aggregate Functions
Transform multiple rows into a single summary value:
```sql
-- Count rows
COUNT(*)           → How many rows?

-- Sum values
SUM(Amount)        → What's the total?

-- Calculate average
AVG(Price)         → What's the average?

-- Find extremes
MIN(Date)          → What's the earliest?
MAX(Price)         → What's the highest?
```

### GROUP BY Clause
Organize rows into groups based on common values:
```sql
SELECT 
    Category,           -- Grouping column
    COUNT(*) AS Count,  -- Aggregate function
    SUM(Amount) AS Total
FROM Sales
GROUP BY Category;      -- Creates groups
```

### HAVING Clause
Filter groups after aggregation (like WHERE for groups):
```sql
SELECT 
    Category,
    COUNT(*) AS Count
FROM Sales
GROUP BY Category
HAVING COUNT(*) > 10;   -- Filter groups, not rows
```

---

## Common Use Cases

### Business Intelligence
- **Sales reports:** Total sales by product, region, or time period
- **Customer analysis:** Orders per customer, average order value
- **Inventory management:** Stock levels by category or warehouse
- **Performance metrics:** Average response time, error rates

### Statistical Analysis
- **Descriptive statistics:** Mean, median, mode, standard deviation
- **Trend analysis:** Growth over time, period-over-period changes
- **Distribution analysis:** Histogram data, value ranges

### Data Quality
- **Duplicate detection:** COUNT with GROUP BY to find duplicates
- **Completeness checks:** COUNT of NULL values
- **Outlier detection:** MIN/MAX to find extreme values

---

## The Grouping Mindset

### From Individual Rows to Summaries

**Before Grouping (Detail Level):**
```
OrderID | Customer | Amount
--------|----------|-------
1       | Alice    | 100
2       | Bob      | 150
3       | Alice    | 200
4       | Alice    | 75
5       | Bob      | 300
```

**After Grouping (Summary Level):**
```sql
SELECT 
    Customer,
    COUNT(*) AS OrderCount,
    SUM(Amount) AS TotalSpent
FROM Orders
GROUP BY Customer;
```

**Result:**
```
Customer | OrderCount | TotalSpent
---------|------------|------------
Alice    | 3          | 375
Bob      | 2          | 450
```

---

## Aggregate Function Categories

### Counting Functions
```sql
COUNT(*)              -- All rows (including NULLs)
COUNT(column)         -- Non-NULL values only
COUNT(DISTINCT column) -- Unique non-NULL values
```

### Numeric Aggregates
```sql
SUM(column)           -- Total of all values
AVG(column)           -- Average (mean)
MIN(column)           -- Minimum value
MAX(column)           -- Maximum value
```

### Statistical Functions
```sql
STDEV(column)         -- Standard deviation
VAR(column)           -- Variance
STDEVP(column)        -- Population standard deviation
VARP(column)          -- Population variance
```

### String Aggregates (SQL Server 2017+)
```sql
STRING_AGG(column, separator)  -- Concatenate values
```

---

## Query Execution Order

Understanding the order helps avoid common mistakes:

```
1. FROM       → Get the tables
2. WHERE      → Filter individual rows
3. GROUP BY   → Create groups
4. HAVING     → Filter groups
5. SELECT     → Choose columns (apply aggregates)
6. ORDER BY   → Sort results
```

**Important:** You can only reference:
- Grouped columns in SELECT
- Aggregate functions in SELECT
- Use HAVING (not WHERE) to filter aggregates

---

## Common Patterns

### Pattern 1: Top N per Group
```sql
-- Top 3 products per category by sales
SELECT Category, Product, Sales
FROM (
    SELECT 
        Category,
        Product,
        Sales,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Sales DESC) AS rn
    FROM Products
) ranked
WHERE rn <= 3;
```

### Pattern 2: Percentage of Total
```sql
-- Each category's percentage of total sales
SELECT 
    Category,
    SUM(Amount) AS CategoryTotal,
    SUM(Amount) * 100.0 / SUM(SUM(Amount)) OVER () AS PercentOfTotal
FROM Sales
GROUP BY Category;
```

### Pattern 3: Running Totals
```sql
-- Cumulative sales by date
SELECT 
    OrderDate,
    DailyTotal,
    SUM(DailyTotal) OVER (ORDER BY OrderDate) AS RunningTotal
FROM (
    SELECT 
        OrderDate,
        SUM(Amount) AS DailyTotal
    FROM Orders
    GROUP BY OrderDate
) daily;
```

---

## Performance Considerations

### Indexing for GROUP BY
```sql
-- Good: Index on grouped columns
CREATE INDEX IX_Sales_Category ON Sales(Category);

-- Better: Covering index (includes aggregated columns)
CREATE INDEX IX_Sales_Category_Amount ON Sales(Category, Amount);
```

### Filtering Before Grouping
```sql
-- ✅ GOOD: Filter rows early (WHERE)
SELECT Category, COUNT(*)
FROM Sales
WHERE OrderDate >= '2025-01-01'  -- Filter BEFORE grouping
GROUP BY Category;

-- ❌ LESS EFFICIENT: Filter after grouping
SELECT Category, COUNT(*)
FROM Sales
GROUP BY Category
HAVING MIN(OrderDate) >= '2025-01-01';  -- Filter AFTER grouping
```

### Avoid Unnecessary DISTINCT
```sql
-- ❌ Slower: DISTINCT with GROUP BY
SELECT DISTINCT Category, COUNT(*)
FROM Sales
GROUP BY Category;

-- ✅ Faster: GROUP BY already ensures unique categories
SELECT Category, COUNT(*)
FROM Sales
GROUP BY Category;
```

---

## Common Mistakes to Avoid

### Mistake 1: Non-Aggregated Columns in SELECT
```sql
-- ❌ ERROR: ProductName not in GROUP BY
SELECT 
    Category,
    ProductName,    -- ERROR!
    COUNT(*)
FROM Products
GROUP BY Category;

-- ✅ CORRECT: All non-aggregated columns must be in GROUP BY
SELECT 
    Category,
    ProductName,
    COUNT(*)
FROM Products
GROUP BY Category, ProductName;
```

### Mistake 2: WHERE Instead of HAVING
```sql
-- ❌ ERROR: Can't use aggregate in WHERE
SELECT Category, COUNT(*) AS Total
FROM Sales
GROUP BY Category
WHERE COUNT(*) > 10;  -- ERROR!

-- ✅ CORRECT: Use HAVING for aggregates
SELECT Category, COUNT(*) AS Total
FROM Sales
GROUP BY Category
HAVING COUNT(*) > 10;
```

### Mistake 3: Forgetting COUNT(*) vs COUNT(column)
```sql
-- COUNT(*) includes NULLs, COUNT(column) doesn't!
SELECT 
    COUNT(*) AS AllRows,        -- 100 rows
    COUNT(Email) AS HasEmail    -- 85 rows (15 are NULL)
FROM Customers;
```

---

## Real-World Examples

### Example 1: Sales Dashboard
```sql
-- Daily sales summary
SELECT 
    CAST(OrderDate AS DATE) AS SaleDate,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS DailySales,
    AVG(TotalAmount) AS AvgOrderValue,
    MIN(TotalAmount) AS SmallestOrder,
    MAX(TotalAmount) AS LargestOrder
FROM Orders
WHERE OrderDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY CAST(OrderDate AS DATE)
ORDER BY SaleDate DESC;
```

### Example 2: Customer Segmentation
```sql
-- RFM Analysis (Recency, Frequency, Monetary)
SELECT 
    CustomerID,
    DATEDIFF(DAY, MAX(OrderDate), GETDATE()) AS DaysSinceLastOrder,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY CustomerID
ORDER BY TotalSpent DESC;
```

### Example 3: Inventory Alerts
```sql
-- Products low in stock by category
SELECT 
    Category,
    COUNT(*) AS ProductCount,
    SUM(Stock) AS TotalStock,
    AVG(Stock) AS AvgStock,
    COUNT(CASE WHEN Stock < ReorderLevel THEN 1 END) AS LowStockCount
FROM Products
GROUP BY Category
HAVING COUNT(CASE WHEN Stock < ReorderLevel THEN 1 END) > 0
ORDER BY LowStockCount DESC;
```

---

## Learning Path

### Beginner Focus
1. Start with simple COUNT and SUM
2. Master single-column GROUP BY
3. Understand WHERE vs HAVING
4. Practice with real datasets

### Intermediate Skills
1. Multi-column grouping
2. Complex expressions in GROUP BY
3. Combining aggregates
4. Window functions for running totals

### Advanced Techniques
1. ROLLUP and CUBE
2. GROUPING SETS
3. Recursive aggregation
4. Performance optimization

---

## Practice Strategy

### For Each Lesson:
1. **Read** the lesson content carefully
2. **Run** all example queries
3. **Modify** examples to test understanding
4. **Complete** practice exercises
5. **Review** key takeaways

### Build Your Skills:
- Start with simple single-column groups
- Gradually add complexity
- Practice with your own data
- Compare different approaches
- Focus on understanding, not memorization

---

## Prerequisites

Before starting this chapter, you should understand:
- ✅ Basic SELECT statements (Chapter 03)
- ✅ WHERE clause filtering (Chapter 04)
- ✅ ORDER BY sorting (Chapter 03)
- ✅ Data types (Chapter 02)

---

## What's Next?

After mastering grouping and aggregates, you'll be ready for:
- **Chapter 09:** Subqueries (using aggregates in subqueries)
- **Chapter 10:** Joins Revisited (combining joins with aggregates)
- **Chapter 16:** Analytic Functions (advanced window functions)

---

## Quick Reference

### Essential Aggregates
```sql
COUNT(*)              -- Count all rows
COUNT(column)         -- Count non-NULL values
SUM(column)           -- Sum of values
AVG(column)           -- Average value
MIN(column)           -- Minimum value
MAX(column)           -- Maximum value
```

### Basic GROUP BY Template
```sql
SELECT 
    grouping_column,
    COUNT(*) AS count,
    SUM(value_column) AS total
FROM table_name
WHERE row_filter_condition
GROUP BY grouping_column
HAVING aggregate_filter_condition
ORDER BY grouping_column;
```

---

## Ready to Begin?

Start with **Lesson 01: Grouping Concepts** to build your foundation!

**Remember:** 
- Grouping transforms detail into summary
- Aggregates answer "how many" and "how much"
- Practice makes perfect!

Let's turn data into insights! 📊

