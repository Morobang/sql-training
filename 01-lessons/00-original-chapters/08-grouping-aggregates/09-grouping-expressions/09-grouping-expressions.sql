/*
============================================================================
Lesson 08.09 - Grouping with Expressions
============================================================================

Description:
Advanced grouping techniques using calculated columns, CASE expressions,
and complex logic to create sophisticated data summaries.

Topics Covered:
• Computed column grouping
• CASE in GROUP BY
• Complex expressions
• Bucketing strategies
• Dynamic categorization

Prerequisites:
• Lessons 08.01-08.08
• Lesson 08.05 (Using Expressions - review)

Estimated Time: 25 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Review - Simple Expression Grouping
============================================================================
*/

-- Example 1.1: Date part extraction
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS Orders
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Example 1.2: String manipulation
SELECT 
    LEFT(ProductName, 1) AS FirstLetter,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY LEFT(ProductName, 1)
ORDER BY FirstLetter;


/*
============================================================================
PART 2: Advanced CASE Expression Grouping
============================================================================
*/

-- Example 2.1: Multi-tier customer segmentation
SELECT 
    CASE 
        WHEN TotalSpent >= 10000 THEN '1-VIP'
        WHEN TotalSpent >= 5000 THEN '2-Premium'
        WHEN TotalSpent >= 1000 THEN '3-Regular'
        WHEN TotalSpent >= 100 THEN '4-Occasional'
        ELSE '5-Minimal'
    END AS CustomerTier,
    COUNT(*) AS Customers,
    MIN(TotalSpent) AS MinSpent,
    MAX(TotalSpent) AS MaxSpent,
    AVG(TotalSpent) AS AvgSpent
FROM (
    SELECT 
        CustomerID,
        SUM(TotalAmount) AS TotalSpent
    FROM Orders
    GROUP BY CustomerID
) CustomerTotals
GROUP BY 
    CASE 
        WHEN TotalSpent >= 10000 THEN '1-VIP'
        WHEN TotalSpent >= 5000 THEN '2-Premium'
        WHEN TotalSpent >= 1000 THEN '3-Regular'
        WHEN TotalSpent >= 100 THEN '4-Occasional'
        ELSE '5-Minimal'
    END
ORDER BY CustomerTier;

-- Example 2.2: Product lifecycle stage
SELECT 
    CASE 
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 30 THEN 'New'
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 180 THEN 'Growing'
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 365 THEN 'Mature'
        ELSE 'Legacy'
    END AS LifecycleStage,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    SUM(Stock) AS TotalStock
FROM Products
GROUP BY 
    CASE 
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 30 THEN 'New'
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 180 THEN 'Growing'
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 365 THEN 'Mature'
        ELSE 'Legacy'
    END
ORDER BY 
    CASE 
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 30 THEN 1
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 180 THEN 2
        WHEN DATEDIFF(DAY, CreatedDate, GETDATE()) <= 365 THEN 3
        ELSE 4
    END;

-- Example 2.3: Seasonal analysis
SELECT 
    YEAR(OrderDate) AS Year,
    CASE 
        WHEN MONTH(OrderDate) IN (12, 1, 2) THEN 'Q4-Winter'
        WHEN MONTH(OrderDate) IN (3, 4, 5) THEN 'Q1-Spring'
        WHEN MONTH(OrderDate) IN (6, 7, 8) THEN 'Q2-Summer'
        ELSE 'Q3-Fall'
    END AS Season,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY 
    YEAR(OrderDate),
    CASE 
        WHEN MONTH(OrderDate) IN (12, 1, 2) THEN 'Q4-Winter'
        WHEN MONTH(OrderDate) IN (3, 4, 5) THEN 'Q1-Spring'
        WHEN MONTH(OrderDate) IN (6, 7, 8) THEN 'Q2-Summer'
        ELSE 'Q3-Fall'
    END
ORDER BY Year, Season;


/*
============================================================================
PART 3: Dynamic Bucketing
============================================================================
*/

-- Example 3.1: Percentile-based bucketing
WITH ProductPricePercentiles AS (
    SELECT 
        ProductID,
        Price,
        NTILE(4) OVER (ORDER BY Price) AS PriceQuartile
    FROM Products
    WHERE Price IS NOT NULL
)
SELECT 
    CASE PriceQuartile
        WHEN 1 THEN '1st Quartile (Cheapest 25%)'
        WHEN 2 THEN '2nd Quartile'
        WHEN 3 THEN '3rd Quartile'
        WHEN 4 THEN '4th Quartile (Most Expensive 25%)'
    END AS PriceBucket,
    COUNT(*) AS ProductCount,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice,
    AVG(Price) AS AvgPrice
FROM ProductPricePercentiles
GROUP BY PriceQuartile
ORDER BY PriceQuartile;

-- Example 3.2: Standard deviation bucketing
WITH PriceStats AS (
    SELECT 
        AVG(Price) AS AvgPrice,
        STDEV(Price) AS StdDev
    FROM Products
    WHERE Price IS NOT NULL
)
SELECT 
    CASE 
        WHEN p.Price < ps.AvgPrice - ps.StdDev THEN 'Below Average'
        WHEN p.Price > ps.AvgPrice + ps.StdDev THEN 'Above Average'
        ELSE 'Average'
    END AS PriceCategory,
    COUNT(*) AS ProductCount,
    MIN(p.Price) AS MinPrice,
    MAX(p.Price) AS MaxPrice,
    AVG(p.Price) AS AvgPrice
FROM Products p
CROSS JOIN PriceStats ps
WHERE p.Price IS NOT NULL
GROUP BY 
    CASE 
        WHEN p.Price < ps.AvgPrice - ps.StdDev THEN 'Below Average'
        WHEN p.Price > ps.AvgPrice + ps.StdDev THEN 'Above Average'
        ELSE 'Average'
    END;


/*
============================================================================
PART 4: Complex Multi-Expression Grouping
============================================================================
*/

-- Example 4.1: Combine time + value + geography
SELECT 
    YEAR(o.OrderDate) AS Year,
    CASE 
        WHEN o.TotalAmount < 100 THEN 'Small'
        WHEN o.TotalAmount < 500 THEN 'Medium'
        ELSE 'Large'
    END AS OrderSize,
    c.Country,
    COUNT(*) AS OrderCount,
    SUM(o.TotalAmount) AS Revenue,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
GROUP BY 
    YEAR(o.OrderDate),
    CASE 
        WHEN o.TotalAmount < 100 THEN 'Small'
        WHEN o.TotalAmount < 500 THEN 'Medium'
        ELSE 'Large'
    END,
    c.Country
ORDER BY Year, Country, OrderSize;

-- Example 4.2: RFM Analysis (Recency, Frequency, Monetary)
WITH CustomerMetrics AS (
    SELECT 
        CustomerID,
        DATEDIFF(DAY, MAX(OrderDate), GETDATE()) AS Recency,
        COUNT(*) AS Frequency,
        SUM(TotalAmount) AS Monetary
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    CASE 
        WHEN Recency <= 30 THEN 'Recent'
        WHEN Recency <= 90 THEN 'Moderate'
        ELSE 'Dormant'
    END AS RecencyScore,
    CASE 
        WHEN Frequency >= 10 THEN 'Frequent'
        WHEN Frequency >= 5 THEN 'Regular'
        ELSE 'Occasional'
    END AS FrequencyScore,
    CASE 
        WHEN Monetary >= 5000 THEN 'High Value'
        WHEN Monetary >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS MonetaryScore,
    COUNT(*) AS CustomerCount,
    AVG(Recency) AS AvgRecency,
    AVG(Frequency) AS AvgFrequency,
    AVG(Monetary) AS AvgMonetary
FROM CustomerMetrics
GROUP BY 
    CASE 
        WHEN Recency <= 30 THEN 'Recent'
        WHEN Recency <= 90 THEN 'Moderate'
        ELSE 'Dormant'
    END,
    CASE 
        WHEN Frequency >= 10 THEN 'Frequent'
        WHEN Frequency >= 5 THEN 'Regular'
        ELSE 'Occasional'
    END,
    CASE 
        WHEN Monetary >= 5000 THEN 'High Value'
        WHEN Monetary >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY RecencyScore, FrequencyScore, MonetaryScore;


/*
============================================================================
PART 5: Mathematical Expression Grouping
============================================================================
*/

-- Example 5.1: Round to nearest value
SELECT 
    ROUND(Price, -1) AS PriceRounded,  -- Nearest $10
    COUNT(*) AS ProductCount,
    MIN(Price) AS MinActualPrice,
    MAX(Price) AS MaxActualPrice
FROM Products
GROUP BY ROUND(Price, -1)
ORDER BY PriceRounded;

-- Example 5.2: Floor/Ceiling grouping
SELECT 
    FLOOR(Price / 50) * 50 AS PriceBand,  -- 0, 50, 100, 150, etc.
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY FLOOR(Price / 50) * 50
ORDER BY PriceBand;

-- Example 5.3: Modulo grouping (e.g., even/odd)
SELECT 
    CASE 
        WHEN ProductID % 2 = 0 THEN 'Even'
        ELSE 'Odd'
    END AS IDType,
    COUNT(*) AS ProductCount
FROM Products
GROUP BY ProductID % 2;


/*
============================================================================
PART 6: Conditional Aggregation within Groups
============================================================================
*/

-- Example 6.1: Different aggregates for different conditions
SELECT 
    CategoryID,
    COUNT(*) AS TotalProducts,
    SUM(CASE WHEN Price < 50 THEN 1 ELSE 0 END) AS BudgetProducts,
    SUM(CASE WHEN Price BETWEEN 50 AND 100 THEN 1 ELSE 0 END) AS MidRangeProducts,
    SUM(CASE WHEN Price > 100 THEN 1 ELSE 0 END) AS PremiumProducts,
    AVG(CASE WHEN Stock > 0 THEN Price END) AS AvgPriceInStock,
    AVG(CASE WHEN Stock = 0 THEN Price END) AS AvgPriceOutOfStock
FROM Products
GROUP BY CategoryID;

-- Example 6.2: Ratio calculations
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN TotalAmount > 500 THEN 1 ELSE 0 END) AS LargeOrders,
    CAST(SUM(CASE WHEN TotalAmount > 500 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS LargeOrderPercent,
    SUM(CASE WHEN TotalAmount > 500 THEN TotalAmount ELSE 0 END) AS LargeOrderRevenue,
    SUM(TotalAmount) AS TotalRevenue,
    CAST(SUM(CASE WHEN TotalAmount > 500 THEN TotalAmount ELSE 0 END) * 100.0 / SUM(TotalAmount) AS DECIMAL(5,2)) AS LargeOrderRevenuePercent
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;


/*
============================================================================
PART 7: Best Practices
============================================================================
*/

-- Practice 7.1: ✅ Keep expressions consistent
SELECT 
    CASE 
        WHEN Price < 50 THEN 'Budget'
        ELSE 'Premium'
    END AS Category,
    COUNT(*) AS Count
FROM Products
GROUP BY 
    CASE 
        WHEN Price < 50 THEN 'Budget'
        ELSE 'Premium'
    END;  -- Same expression!

-- Practice 7.2: ✅ Use CTEs for complex expressions
WITH ProductCategories AS (
    SELECT 
        ProductID,
        ProductName,
        CASE 
            WHEN Price < 25 THEN 'Budget'
            WHEN Price < 100 THEN 'Standard'
            ELSE 'Premium'
        END AS PriceCategory
    FROM Products
)
SELECT 
    PriceCategory,
    COUNT(*) AS ProductCount
FROM ProductCategories
GROUP BY PriceCategory;

-- Practice 7.3: ✅ Consider computed columns for frequent expressions
-- ALTER TABLE Products ADD PriceCategory AS 
--   CASE WHEN Price < 50 THEN 'Budget' ELSE 'Premium' END;
-- Then simply:
-- SELECT PriceCategory, COUNT(*) FROM Products GROUP BY PriceCategory;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create age buckets for orders (0-30 days, 31-90, 91-365, 365+)
2. Segment customers by order frequency
3. Categorize products by stock levels (Critical, Low, Normal, High)
4. Time-of-day analysis (Morning, Afternoon, Evening, Night)
5. Revenue contribution tiers

Solutions below ↓
*/

-- Solution 1:
SELECT 
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 30 THEN '0-30 days'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 90 THEN '31-90 days'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 365 THEN '91-365 days'
        ELSE '365+ days'
    END AS OrderAge,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY 
    CASE 
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 30 THEN '0-30 days'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 90 THEN '31-90 days'
        WHEN DATEDIFF(DAY, OrderDate, GETDATE()) <= 365 THEN '91-365 days'
        ELSE '365+ days'
    END;

-- Solution 2:
WITH CustomerFrequency AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    CASE 
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount <= 3 THEN 'Infrequent (2-3)'
        WHEN OrderCount <= 10 THEN 'Regular (4-10)'
        ELSE 'Frequent (10+)'
    END AS CustomerSegment,
    COUNT(*) AS Customers
FROM CustomerFrequency
GROUP BY 
    CASE 
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount <= 3 THEN 'Infrequent (2-3)'
        WHEN OrderCount <= 10 THEN 'Regular (4-10)'
        ELSE 'Frequent (10+)'
    END;

-- Solution 3:
SELECT 
    CASE 
        WHEN Stock = 0 THEN 'Critical (Out of Stock)'
        WHEN Stock < 10 THEN 'Low (1-9)'
        WHEN Stock < 50 THEN 'Normal (10-49)'
        ELSE 'High (50+)'
    END AS StockStatus,
    COUNT(*) AS ProductCount,
    SUM(Stock) AS TotalUnits
FROM Products
GROUP BY 
    CASE 
        WHEN Stock = 0 THEN 'Critical (Out of Stock)'
        WHEN Stock < 10 THEN 'Low (1-9)'
        WHEN Stock < 50 THEN 'Normal (10-49)'
        ELSE 'High (50+)'
    END
ORDER BY 
    CASE 
        WHEN Stock = 0 THEN 1
        WHEN Stock < 10 THEN 2
        WHEN Stock < 50 THEN 3
        ELSE 4
    END;

-- Solution 4:
SELECT 
    CASE 
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 6 AND 11 THEN 'Morning (6AM-12PM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-6PM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 18 AND 23 THEN 'Evening (6PM-12AM)'
        ELSE 'Night (12AM-6AM)'
    END AS TimeOfDay,
    COUNT(*) AS OrderCount,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY 
    CASE 
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 6 AND 11 THEN 'Morning (6AM-12PM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 12 AND 17 THEN 'Afternoon (12PM-6PM)'
        WHEN DATEPART(HOUR, OrderDate) BETWEEN 18 AND 23 THEN 'Evening (6PM-12AM)'
        ELSE 'Night (12AM-6AM)'
    END;

-- Solution 5:
WITH ProductRevenue AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY p.ProductID, p.ProductName
)
SELECT 
    CASE 
        WHEN TotalRevenue >= 10000 THEN 'Tier 1 (Top)'
        WHEN TotalRevenue >= 5000 THEN 'Tier 2 (High)'
        WHEN TotalRevenue >= 1000 THEN 'Tier 3 (Medium)'
        ELSE 'Tier 4 (Low)'
    END AS RevenueTier,
    COUNT(*) AS ProductCount,
    SUM(TotalRevenue) AS TierRevenue,
    AVG(TotalRevenue) AS AvgProductRevenue
FROM ProductRevenue
GROUP BY 
    CASE 
        WHEN TotalRevenue >= 10000 THEN 'Tier 1 (Top)'
        WHEN TotalRevenue >= 5000 THEN 'Tier 2 (High)'
        WHEN TotalRevenue >= 1000 THEN 'Tier 3 (Medium)'
        ELSE 'Tier 4 (Low)'
    END;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ EXPRESSION GROUPING:
  • Use CASE for categories and buckets
  • Keep expressions identical in SELECT and GROUP BY
  • Consider CTEs for complex logic

✓ BUCKETING STRATEGIES:
  • Fixed ranges (0-25, 25-50, etc.)
  • Percentiles (quartiles, deciles)
  • Statistical (standard deviation)
  • Mathematical (FLOOR, ROUND, CEILING)

✓ BEST PRACTICES:
  • Use consistent expressions
  • CTEs for readability
  • Computed columns for frequent use
  • Meaningful category names
  • Proper sort order

✓ PERFORMANCE:
  • Simple expressions are faster
  • Index computed columns
  • Filter with WHERE first
  • Avoid redundant calculations

✓ COMMON PATTERNS:
  • Customer segmentation (RFM)
  • Price categorization
  • Time-based analysis
  • Stock level monitoring
  • Revenue tiers

============================================================================
NEXT: Lesson 08.10 - Generating Rollups
Learn ROLLUP, CUBE, and GROUPING SETS for subtotals and cross-tabs.
============================================================================
*/
