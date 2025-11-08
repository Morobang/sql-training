/*
============================================================================
Lesson 08.05 - Using Expressions in GROUP BY
============================================================================

Description:
Learn to group by calculated columns, derived values, and complex
expressions to create more flexible and powerful aggregations.

Topics Covered:
• GROUP BY with calculations
• Date part extraction
• CASE expressions in GROUP BY
• String manipulation in grouping
• Bucketing and ranges

Prerequisites:
• Lessons 08.01-08.04
• Chapter 07 (Data Generation and Manipulation)

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Basic Expressions in GROUP BY
============================================================================
*/

-- Example 1.1: Group by calculation
SELECT 
    YEAR(OrderDate) AS OrderYear,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;

-- Example 1.2: Group by mathematical expression
SELECT 
    ROUND(Price, -1) AS PriceRange,  -- Round to nearest 10
    COUNT(*) AS ProductCount
FROM Products
GROUP BY ROUND(Price, -1)
ORDER BY PriceRange;

-- Example 1.3: Group by concatenation
SELECT 
    UPPER(LEFT(ProductName, 1)) AS FirstLetter,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY UPPER(LEFT(ProductName, 1))
ORDER BY FirstLetter;


/*
============================================================================
PART 2: Date Part Grouping
============================================================================
*/

-- Example 2.1: Group by year and month
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Example 2.2: Group by quarter
SELECT 
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY Year, Quarter;

-- Example 2.3: Group by day of week
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    DATEPART(WEEKDAY, OrderDate) AS DayNumber,  -- For sorting
    COUNT(*) AS OrderCount,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY DayNumber;

-- Example 2.4: Group by date (no time)
SELECT 
    CAST(OrderDate AS DATE) AS OrderDate,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS DailyRevenue
FROM Orders
GROUP BY CAST(OrderDate AS DATE)
ORDER BY OrderDate DESC;


/*
============================================================================
PART 3: CASE Expressions in GROUP BY
============================================================================
*/

-- Example 3.1: Price categories
SELECT 
    CASE 
        WHEN Price < 20 THEN 'Budget'
        WHEN Price < 100 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceCategory,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products
GROUP BY 
    CASE 
        WHEN Price < 20 THEN 'Budget'
        WHEN Price < 100 THEN 'Mid-Range'
        ELSE 'Premium'
    END
ORDER BY 
    CASE 
        WHEN Price < 20 THEN 1
        WHEN Price < 100 THEN 2
        ELSE 3
    END;

-- Example 3.2: Order size segmentation
SELECT 
    CASE 
        WHEN TotalAmount < 50 THEN 'Small'
        WHEN TotalAmount < 200 THEN 'Medium'
        WHEN TotalAmount < 500 THEN 'Large'
        ELSE 'Very Large'
    END AS OrderSize,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY 
    CASE 
        WHEN TotalAmount < 50 THEN 'Small'
        WHEN TotalAmount < 200 THEN 'Medium'
        WHEN TotalAmount < 500 THEN 'Large'
        ELSE 'Very Large'
    END;

-- Example 3.3: Time of day grouping
SELECT 
    CASE 
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 0 AND 5 THEN 'Night (12AM-6AM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 6 AND 11 THEN 'Morning (6AM-12PM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-6PM)'
        ELSE 'Evening (6PM-12AM)'
    END AS TimeOfDay,
    COUNT(*) AS OrderCount,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY 
    CASE 
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 0 AND 5 THEN 'Night (12AM-6AM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 6 AND 11 THEN 'Morning (6AM-12PM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-6PM)'
        ELSE 'Evening (6PM-12AM)'
    END;


/*
============================================================================
PART 4: Bucketing and Ranges
============================================================================
*/

-- Example 4.1: Age ranges (if we had customer birthdate)
-- Simulating with OrderDate for demonstration
SELECT 
    CASE 
        WHEN DATEDIFF(YEAR, OrderDate, GETDATE()) = 0 THEN 'This Year'
        WHEN DATEDIFF(YEAR, OrderDate, GETDATE()) = 1 THEN 'Last Year'
        WHEN DATEDIFF(YEAR, OrderDate, GETDATE()) <= 3 THEN '2-3 Years Ago'
        ELSE 'More than 3 Years'
    END AS OrderAge,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY 
    CASE 
        WHEN DATEDIFF(YEAR, OrderDate, GETDATE()) = 0 THEN 'This Year'
        WHEN DATEDIFF(YEAR, OrderDate, GETDATE()) = 1 THEN 'Last Year'
        WHEN DATEDIFF(YEAR, OrderDate, GETDATE()) <= 3 THEN '2-3 Years Ago'
        ELSE 'More than 3 Years'
    END;

-- Example 4.2: Stock level buckets
SELECT 
    CASE 
        WHEN Stock = 0 THEN 'Out of Stock'
        WHEN Stock < 10 THEN 'Low Stock (1-9)'
        WHEN Stock < 50 THEN 'Normal Stock (10-49)'
        ELSE 'High Stock (50+)'
    END AS StockLevel,
    COUNT(*) AS ProductCount,
    SUM(Stock) AS TotalUnits,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY 
    CASE 
        WHEN Stock = 0 THEN 'Out of Stock'
        WHEN Stock < 10 THEN 'Low Stock (1-9)'
        WHEN Stock < 50 THEN 'Normal Stock (10-49)'
        ELSE 'High Stock (50+)'
    END;

-- Example 4.3: Revenue bands
SELECT 
    FLOOR(TotalAmount / 100) * 100 AS RevenueBand,  -- 0, 100, 200, 300, etc.
    COUNT(*) AS OrderCount,
    MIN(TotalAmount) AS MinAmount,
    MAX(TotalAmount) AS MaxAmount
FROM Orders
GROUP BY FLOOR(TotalAmount / 100) * 100
ORDER BY RevenueBand;


/*
============================================================================
PART 5: String Manipulation in Grouping
============================================================================
*/

-- Example 5.1: Group by first character
SELECT 
    LEFT(ProductName, 1) AS FirstLetter,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY LEFT(ProductName, 1)
ORDER BY FirstLetter;

-- Example 5.2: Group by word count
SELECT 
    LEN(ProductName) - LEN(REPLACE(ProductName, ' ', '')) + 1 AS WordCount,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY LEN(ProductName) - LEN(REPLACE(ProductName, ' ', '')) + 1
ORDER BY WordCount;

-- Example 5.3: Group by name length categories
SELECT 
    CASE 
        WHEN LEN(ProductName) <= 10 THEN 'Short'
        WHEN LEN(ProductName) <= 20 THEN 'Medium'
        ELSE 'Long'
    END AS NameLength,
    COUNT(*) AS ProductCount,
    AVG(LEN(ProductName)) AS AvgLength
FROM Products
GROUP BY 
    CASE 
        WHEN LEN(ProductName) <= 10 THEN 'Short'
        WHEN LEN(ProductName) <= 20 THEN 'Medium'
        ELSE 'Long'
    END;


/*
============================================================================
PART 6: Multiple Expressions
============================================================================
*/

-- Example 6.1: Combine date and CASE expressions
SELECT 
    YEAR(OrderDate) AS Year,
    CASE 
        WHEN TotalAmount < 100 THEN 'Small'
        WHEN TotalAmount < 500 THEN 'Medium'
        ELSE 'Large'
    END AS OrderSize,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY 
    YEAR(OrderDate),
    CASE 
        WHEN TotalAmount < 100 THEN 'Small'
        WHEN TotalAmount < 500 THEN 'Medium'
        ELSE 'Large'
    END
ORDER BY Year, OrderSize;

-- Example 6.2: Complex multi-expression grouping
SELECT 
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    CASE 
        WHEN TotalAmount < 50 THEN '1-Low'
        WHEN TotalAmount < 200 THEN '2-Med'
        ELSE '3-High'
    END AS ValueTier,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrder
FROM Orders
GROUP BY 
    YEAR(OrderDate),
    DATEPART(QUARTER, OrderDate),
    CASE 
        WHEN TotalAmount < 50 THEN '1-Low'
        WHEN TotalAmount < 200 THEN '2-Med'
        ELSE '3-High'
    END
ORDER BY Year, Quarter, ValueTier;


/*
============================================================================
PART 7: Best Practices and Performance
============================================================================
*/

-- Practice 7.1: ✅ Use same expression in SELECT and GROUP BY
SELECT 
    YEAR(OrderDate) AS Year,  -- Same expression
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY YEAR(OrderDate)      -- Same expression
ORDER BY Year;

-- Practice 7.2: ❌ Avoid different expressions
-- Don't do this (inconsistent):
-- SELECT YEAR(OrderDate)
-- GROUP BY DATEPART(YEAR, OrderDate)

-- Practice 7.3: Consider computed column for frequently used expressions
-- ALTER TABLE Orders ADD OrderYear AS YEAR(OrderDate);
-- CREATE INDEX IX_Orders_OrderYear ON Orders(OrderYear);
-- Then:
-- SELECT OrderYear, COUNT(*) FROM Orders GROUP BY OrderYear;

-- Practice 7.4: Filter before grouping when possible
SELECT 
    CASE 
        WHEN Price < 50 THEN 'Budget'
        ELSE 'Premium'
    END AS Category,
    COUNT(*) AS ProductCount
FROM Products
WHERE Stock > 0  -- Filter first (more efficient)
GROUP BY 
    CASE 
        WHEN Price < 50 THEN 'Budget'
        ELSE 'Premium'
    END;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Group products by price ranges (0-25, 25-50, 50-100, 100+)
2. Show orders by season (Winter, Spring, Summer, Fall)
3. Categorize orders by size (use TotalAmount)
4. Group products by first letter of name
5. Create age buckets for orders (days since order)

Solutions below ↓
*/

-- Solution 1:
SELECT 
    CASE 
        WHEN Price < 25 THEN '$0-$25'
        WHEN Price < 50 THEN '$25-$50'
        WHEN Price < 100 THEN '$50-$100'
        ELSE '$100+'
    END AS PriceRange,
    COUNT(*) AS ProductCount,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM Products
GROUP BY 
    CASE 
        WHEN Price < 25 THEN '$0-$25'
        WHEN Price < 50 THEN '$25-$50'
        WHEN Price < 100 THEN '$50-$100'
        ELSE '$100+'
    END;

-- Solution 2:
SELECT 
    CASE 
        WHEN MONTH(OrderDate) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(OrderDate) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(OrderDate) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS Season,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY 
    CASE 
        WHEN MONTH(OrderDate) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(OrderDate) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(OrderDate) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END;

-- Solution 3:
SELECT 
    CASE 
        WHEN TotalAmount < 50 THEN 'XS'
        WHEN TotalAmount < 100 THEN 'S'
        WHEN TotalAmount < 250 THEN 'M'
        WHEN TotalAmount < 500 THEN 'L'
        ELSE 'XL'
    END AS OrderSize,
    COUNT(*) AS Count,
    AVG(TotalAmount) AS AvgValue
FROM Orders
GROUP BY 
    CASE 
        WHEN TotalAmount < 50 THEN 'XS'
        WHEN TotalAmount < 100 THEN 'S'
        WHEN TotalAmount < 250 THEN 'M'
        WHEN TotalAmount < 500 THEN 'L'
        ELSE 'XL'
    END;

-- Solution 4:
SELECT 
    UPPER(LEFT(ProductName, 1)) AS FirstLetter,
    COUNT(*) AS ProductCount,
    MIN(ProductName) AS FirstProduct,
    MAX(ProductName) AS LastProduct
FROM Products
GROUP BY UPPER(LEFT(ProductName, 1))
ORDER BY FirstLetter;

-- Solution 5:
SELECT 
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 7 THEN 'Last Week'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 30 THEN 'Last Month'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 90 THEN 'Last Quarter'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 365 THEN 'Last Year'
        ELSE 'Over 1 Year'
    END AS OrderAge,
    COUNT(*) AS OrderCount,
    MIN(OrderDate) AS OldestOrder,
    MAX(OrderDate) AS NewestOrder
FROM Orders
GROUP BY 
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 7 THEN 'Last Week'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 30 THEN 'Last Month'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 90 THEN 'Last Quarter'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 365 THEN 'Last Year'
        ELSE 'Over 1 Year'
    END;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ EXPRESSIONS IN GROUP BY:
  • Can use calculations, functions, CASE
  • Must match exactly between SELECT and GROUP BY
  • Or use column alias in SQL Server 2022+

✓ COMMON PATTERNS:
  • Date parts (YEAR, MONTH, QUARTER)
  • CASE for categories and buckets
  • String functions (LEFT, LEN, SUBSTRING)
  • Math functions (ROUND, FLOOR, CEILING)

✓ BEST PRACTICES:
  • Keep expressions simple and readable
  • Use same expression in SELECT and GROUP BY
  • Consider computed columns for frequent use
  • Filter with WHERE before GROUP BY

✓ PERFORMANCE:
  • Complex expressions can slow queries
  • Index computed columns when possible
  • Filter early to reduce rows processed

✓ COMMON USE CASES:
  • Price ranges and categories
  • Time period analysis
  • Customer segmentation
  • Product categorization

============================================================================
NEXT: Lesson 08.06 - NULL Handling in Aggregates
Learn how NULL values affect aggregate functions and grouping.
============================================================================
*/
