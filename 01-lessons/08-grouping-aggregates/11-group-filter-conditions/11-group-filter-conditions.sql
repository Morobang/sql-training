/*
============================================================================
Lesson 08.11 - Group Filter Conditions
============================================================================

Description:
Master the HAVING clause to filter groups after aggregation. Understand
the critical difference between WHERE and HAVING, and learn when to use each.

Topics Covered:
• WHERE vs HAVING
• Filtering aggregates with HAVING
• Combining WHERE and HAVING
• Common HAVING patterns
• Performance considerations
• Complex filter conditions

Prerequisites:
• Lessons 08.01-08.10

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: WHERE vs HAVING - Understanding the Difference
============================================================================
*/

-- Concept 1.1: Execution order
/*
1. FROM       → Get tables
2. WHERE      → Filter ROWS (before grouping)
3. GROUP BY   → Create groups
4. HAVING     → Filter GROUPS (after aggregation)
5. SELECT     → Apply aggregates
6. ORDER BY   → Sort results
*/

-- Example 1.2: WHERE filters rows BEFORE grouping
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
WHERE Price > 50          -- Filters individual products
GROUP BY CategoryID;
-- Only counts products with Price > 50

-- Example 1.3: HAVING filters groups AFTER aggregation
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 5;      -- Filters categories
-- Only shows categories with more than 5 products

-- Example 1.4: Visual comparison
/*
WHERE (filters rows):
  All Products (100 rows)
    ↓ WHERE Price > 50
  Filtered Products (60 rows)
    ↓ GROUP BY CategoryID
  Groups by Category

HAVING (filters groups):
  All Products (100 rows)
    ↓ GROUP BY CategoryID
  Groups by Category (10 groups)
    ↓ HAVING COUNT(*) > 5
  Filtered Groups (6 groups)
*/

-- Example 1.5: ❌ WRONG - Can't use aggregate in WHERE
-- SELECT CategoryID, COUNT(*) AS Count
-- FROM Products
-- WHERE COUNT(*) > 5    -- ERROR!
-- GROUP BY CategoryID;

-- ✅ CORRECT - Use HAVING for aggregates
SELECT 
    CategoryID,
    COUNT(*) AS Count
FROM Products
GROUP BY CategoryID
HAVING COUNT(*) > 5;      -- Works!


/*
============================================================================
PART 2: Basic HAVING Clauses
============================================================================
*/

-- Example 2.1: Filter by count
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 3
ORDER BY OrderCount DESC;

-- Example 2.2: Filter by sum
SELECT 
    CustomerID,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 1000
ORDER BY TotalSpent DESC;

-- Example 2.3: Filter by average
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING AVG(Price) > 100;

-- Example 2.4: Filter by min/max
SELECT 
    CategoryID,
    MIN(Stock) AS MinStock,
    MAX(Stock) AS MaxStock,
    MAX(Stock) - MIN(Stock) AS StockRange
FROM Products
GROUP BY CategoryID
HAVING MAX(Stock) - MIN(Stock) > 50;


/*
============================================================================
PART 3: Combining WHERE and HAVING
============================================================================
*/

-- Example 3.1: Both filters together
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
WHERE OrderDate >= '2024-01-01'   -- Filter: Only recent orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 500     -- Filter: Only big spenders
ORDER BY TotalSpent DESC;

/*
Execution:
1. Start with all orders
2. WHERE: Keep only orders from 2024+
3. GROUP BY: Group by customer
4. HAVING: Keep only groups with total > $500
5. SELECT: Calculate aggregates
*/

-- Example 3.2: Complex filtering
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrder
FROM Orders
WHERE Status = 'Completed'         -- Only completed orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
HAVING COUNT(*) >= 10              -- At least 10 orders
   AND SUM(TotalAmount) > 5000     -- Revenue > $5000
ORDER BY Year, Month;

-- Example 3.3: Filter rows and groups differently
SELECT 
    CategoryID,
    COUNT(*) AS ExpensiveProducts,
    AVG(Price) AS AvgPrice
FROM Products
WHERE Price > 100                  -- Individual row filter
GROUP BY CategoryID
HAVING COUNT(*) > 2                -- Group filter
ORDER BY AvgPrice DESC;


/*
============================================================================
PART 4: Common HAVING Patterns
============================================================================
*/

-- Pattern 4.1: Find duplicate values
SELECT 
    Email,
    COUNT(*) AS DuplicateCount
FROM Customers
GROUP BY Email
HAVING COUNT(*) > 1;
-- Shows emails used by multiple customers

-- Pattern 4.2: Find outliers (statistical)
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID
HAVING AVG(Price) > (
    SELECT AVG(Price) * 1.5
    FROM Products
);
-- Categories with average price > 150% of overall average

-- Pattern 4.3: Minimum group size
SELECT 
    City,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY City
HAVING COUNT(*) >= 5   -- Only cities with 5+ customers
ORDER BY CustomerCount DESC;

-- Pattern 4.4: Revenue thresholds
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(TotalAmount) AS Revenue,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY YEAR(OrderDate)
HAVING SUM(TotalAmount) > 10000
ORDER BY Revenue DESC;

-- Pattern 4.5: Multiple aggregate conditions
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent,
    AVG(TotalAmount) AS AvgOrder
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 5                -- At least 6 orders
   AND SUM(TotalAmount) > 1000     -- Total > $1000
   AND AVG(TotalAmount) > 100      -- Average > $100
ORDER BY TotalSpent DESC;


/*
============================================================================
PART 5: Complex HAVING Conditions
============================================================================
*/

-- Example 5.1: HAVING with CASE
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) AS LowStockCount
FROM Products
GROUP BY CategoryID
HAVING SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) > 0
ORDER BY LowStockCount DESC;

-- Example 5.2: HAVING with calculations
SELECT 
    CategoryID,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice,
    MAX(Price) - MIN(Price) AS PriceRange
FROM Products
GROUP BY CategoryID
HAVING MAX(Price) - MIN(Price) > 100
ORDER BY PriceRange DESC;

-- Example 5.3: HAVING with percentage
SELECT 
    CategoryID,
    COUNT(*) AS Total,
    SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) AS LowStock,
    CAST(SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS LowStockPct
FROM Products
GROUP BY CategoryID
HAVING CAST(SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) > 25
ORDER BY LowStockPct DESC;


/*
============================================================================
PART 6: HAVING vs WHERE Performance
============================================================================
*/

-- Example 6.1: ✅ EFFICIENT - Filter early with WHERE
SELECT 
    CustomerID,
    COUNT(*) AS RecentOrders
FROM Orders
WHERE OrderDate >= DATEADD(MONTH, -6, GETDATE())  -- Filter rows first
GROUP BY CustomerID
HAVING COUNT(*) > 3;

-- Example 6.2: ❌ LESS EFFICIENT - Filter late with HAVING
SELECT 
    CustomerID,
    COUNT(*) AS RecentOrders
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 3
   AND MIN(OrderDate) >= DATEADD(MONTH, -6, GETDATE());  -- Filters after grouping

/*
Performance tip:
- Use WHERE to eliminate rows BEFORE expensive operations
- Use HAVING only for conditions that require aggregation
*/


/*
============================================================================
PART 7: Real-World Scenarios
============================================================================
*/

-- Scenario 7.1: Find loyal customers
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS CustomerLifetime
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) >= 5                              -- At least 5 orders
   AND DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) > 365  -- Active for 1+ year
ORDER BY TotalSpent DESC;

-- Scenario 7.2: Inventory alerts by category
SELECT 
    CategoryID,
    COUNT(*) AS TotalProducts,
    SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) AS CriticalStock,
    AVG(Stock) AS AvgStock
FROM Products
GROUP BY CategoryID
HAVING SUM(CASE WHEN Stock < 10 THEN 1 ELSE 0 END) > 0
ORDER BY CriticalStock DESC;

-- Scenario 7.3: High-value customer segments
SELECT 
    CASE 
        WHEN SUM(TotalAmount) >= 5000 THEN 'VIP'
        WHEN SUM(TotalAmount) >= 2000 THEN 'Premium'
        WHEN SUM(TotalAmount) >= 500 THEN 'Regular'
        ELSE 'Basic'
    END AS CustomerTier,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    AVG(SUM(TotalAmount)) AS AvgTotalSpent
FROM Orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > 0;

-- Wait, this won't work! Need subquery:
SELECT 
    CustomerTier,
    COUNT(*) AS CustomerCount,
    AVG(TotalSpent) AS AvgSpent
FROM (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS TotalSpent,
        CASE 
            WHEN SUM(TotalAmount) >= 5000 THEN 'VIP'
            WHEN SUM(TotalAmount) >= 2000 THEN 'Premium'
            WHEN SUM(TotalAmount) >= 500 THEN 'Regular'
            ELSE 'Basic'
        END AS CustomerTier
    FROM Orders
    GROUP BY CustomerID
) CustomerTiers
GROUP BY CustomerTier
ORDER BY AvgSpent DESC;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find customers with more than 10 orders
2. Find categories with average price > $50
3. Find years with total revenue > $10,000
4. Find cities with at least 3 customers
5. Find customers who spent more than average

Solutions below ↓
*/

-- Solution 1:
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 10
ORDER BY OrderCount DESC;

-- Solution 2:
SELECT 
    CategoryID,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY CategoryID
HAVING AVG(Price) > 50
ORDER BY AvgPrice DESC;

-- Solution 3:
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate)
HAVING SUM(TotalAmount) > 10000
ORDER BY Year;

-- Solution 4:
SELECT 
    City,
    COUNT(*) AS CustomerCount
FROM Customers
GROUP BY City
HAVING COUNT(*) >= 3
ORDER BY CustomerCount DESC;

-- Solution 5:
SELECT 
    CustomerID,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > (
    SELECT AVG(CustomerTotal)
    FROM (
        SELECT SUM(TotalAmount) AS CustomerTotal
        FROM Orders
        GROUP BY CustomerID
    ) Totals
)
ORDER BY TotalSpent DESC;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ WHERE VS HAVING:
  • WHERE: Filters ROWS before grouping
  • HAVING: Filters GROUPS after aggregation
  • Use WHERE for row-level conditions
  • Use HAVING for aggregate conditions

✓ EXECUTION ORDER:
  1. FROM → 2. WHERE → 3. GROUP BY → 4. HAVING → 5. SELECT → 6. ORDER BY

✓ PERFORMANCE:
  • Filter early with WHERE when possible
  • Use HAVING only for aggregate conditions
  • Indexes help WHERE, but not HAVING

✓ COMMON PATTERNS:
  • Find duplicates: HAVING COUNT(*) > 1
  • Minimum thresholds: HAVING SUM(...) > value
  • Multiple conditions: HAVING cond1 AND cond2

✓ BEST PRACTICES:
  • Use WHERE to reduce data before grouping
  • Use HAVING for post-aggregation filters
  • Combine both for powerful filtering
  • Keep conditions readable and maintainable

============================================================================
NEXT: Lesson 08.12 - Test Your Knowledge
Comprehensive assessment of grouping and aggregates!
============================================================================
*/
