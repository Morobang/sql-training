/*
============================================================================
Chapter 08 - Grouping and Aggregates
COMPREHENSIVE TEST
============================================================================

Total Points: 500
Passing Score: 350 (70%)
Estimated Time: 90 minutes

Topics Covered:
• Grouping concepts and GROUP BY syntax
• Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
• Implicit vs explicit groups
• COUNT(DISTINCT) and unique values
• Expressions in GROUP BY
• NULL handling in aggregates
• Single and multicolumn grouping
• HAVING clause and filtering
• ROLLUP, CUBE, and GROUPING SETS
• Real-world reporting scenarios

Instructions:
1. Read each question carefully
2. Write your solution query
3. Test your query to ensure it works
4. Compare with provided solutions
5. Award yourself points for correct answers

Database: RetailStore
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
SECTION 1: Basic Grouping and Aggregates (60 points)
============================================================================
*/

-- Question 1.1 (10 points)
-- Count the total number of orders in the database.
-- Expected columns: TotalOrders

-- YOUR SOLUTION:


-- Question 1.2 (10 points)
-- Count the number of orders per customer.
-- Expected columns: CustomerID, OrderCount
-- Sort by OrderCount descending

-- YOUR SOLUTION:


-- Question 1.3 (15 points)
-- Calculate total revenue, average order value, and order count for each year.
-- Expected columns: Year, TotalRevenue, AvgOrderValue, OrderCount
-- Sort by Year

-- YOUR SOLUTION:


-- Question 1.4 (15 points)
-- Find the minimum and maximum price for each product category.
-- Expected columns: CategoryID, MinPrice, MaxPrice, ProductCount

-- YOUR SOLUTION:


-- Question 1.5 (10 points)
-- Count how many unique customers placed orders.
-- Expected columns: UniqueCustomers

-- YOUR SOLUTION:



/*
============================================================================
SECTION 2: COUNT and DISTINCT (70 points)
============================================================================
*/

-- Question 2.1 (15 points)
-- Show the difference between COUNT(*), COUNT(ShippedDate), and 
-- COUNT(DISTINCT CustomerID) for all orders.
-- Expected columns: TotalOrders, ShippedOrders, UniqueCustomers

-- YOUR SOLUTION:


-- Question 2.2 (15 points)
-- Find products purchased by more than 5 unique customers.
-- Expected columns: ProductID, ProductName, UniqueCustomers, TimesPurchased
-- Sort by UniqueCustomers descending

-- YOUR SOLUTION:


-- Question 2.3 (20 points)
-- Count unique products sold each year and month.
-- Expected columns: Year, Month, UniqueProductsSold, TotalQuantitySold
-- Sort by Year, Month

-- YOUR SOLUTION:


-- Question 2.4 (20 points)
-- Find customers who have purchased from more than 2 different categories.
-- Expected columns: CustomerID, CategoriesPurchased, TotalOrders
-- Sort by CategoriesPurchased descending

-- YOUR SOLUTION:



/*
============================================================================
SECTION 3: Expressions in GROUP BY (60 points)
============================================================================
*/

-- Question 3.1 (15 points)
-- Group orders by quarter and year.
-- Expected columns: Year, Quarter, OrderCount, Revenue
-- Sort by Year, Quarter

-- YOUR SOLUTION:


-- Question 3.2 (20 points)
-- Categorize products by price range and count them:
-- Budget: < $25
-- Standard: $25 - $99.99
-- Premium: >= $100
-- Expected columns: PriceRange, ProductCount, AvgPrice

-- YOUR SOLUTION:


-- Question 3.3 (25 points)
-- Group orders by day of week and show which days are busiest.
-- Expected columns: DayOfWeek, DayNumber, OrderCount, AvgOrderValue
-- Sort by DayNumber

-- YOUR SOLUTION:



/*
============================================================================
SECTION 4: NULL Handling (50 points)
============================================================================
*/

-- Question 4.1 (15 points)
-- Count orders that have been shipped vs not shipped.
-- Expected columns: TotalOrders, ShippedOrders, UnshippedOrders, ShippedPercent

-- YOUR SOLUTION:


-- Question 4.2 (20 points)
-- For each category, show product count, products with price, and products without price.
-- Expected columns: CategoryID, TotalProducts, WithPrice, WithoutPrice

-- YOUR SOLUTION:


-- Question 4.3 (15 points)
-- Calculate average order value treating NULL as 0 vs ignoring NULL.
-- Compare both approaches.
-- Expected columns: AvgIgnoringNull, AvgTreatingNullAsZero

-- YOUR SOLUTION:



/*
============================================================================
SECTION 5: Multicolumn Grouping (60 points)
============================================================================
*/

-- Question 5.1 (15 points)
-- Group products by CategoryID and SupplierID.
-- Expected columns: CategoryID, SupplierID, ProductCount, AvgPrice

-- YOUR SOLUTION:


-- Question 5.2 (20 points)
-- Show monthly sales by year and month with running information.
-- Expected columns: Year, Month, OrderCount, MonthlyRevenue
-- Sort by Year, Month

-- YOUR SOLUTION:


-- Question 5.3 (25 points)
-- Create a report showing sales by Country, Year, and Quarter.
-- Expected columns: Country, Year, Quarter, UniqueCustomers, Orders, Revenue
-- Sort by Country, Year, Quarter

-- YOUR SOLUTION:



/*
============================================================================
SECTION 6: HAVING Clause (60 points)
============================================================================
*/

-- Question 6.1 (15 points)
-- Find customers who have placed more than 5 orders.
-- Expected columns: CustomerID, OrderCount, TotalSpent
-- Sort by OrderCount descending

-- YOUR SOLUTION:


-- Question 6.2 (20 points)
-- Find product categories with average price greater than $50.
-- Expected columns: CategoryID, ProductCount, AvgPrice, MaxPrice
-- Sort by AvgPrice descending

-- YOUR SOLUTION:


-- Question 6.3 (25 points)
-- Find products that have generated more than $1000 in total revenue.
-- Expected columns: ProductID, ProductName, TotalRevenue, UnitsSold
-- Sort by TotalRevenue descending

-- YOUR SOLUTION:



/*
============================================================================
SECTION 7: ROLLUP, CUBE, and GROUPING SETS (70 points)
============================================================================
*/

-- Question 7.1 (20 points)
-- Use ROLLUP to show product counts by CategoryID and SupplierID with subtotals.
-- Expected columns: CategoryID, SupplierID, ProductCount
-- Include a column to identify subtotal rows

-- YOUR SOLUTION:


-- Question 7.2 (25 points)
-- Use CUBE to analyze orders by Year and CustomerID.
-- Expected columns: Year, CustomerID, OrderCount, Revenue, RowType
-- Label each row type (Detail, Year Total, Customer Total, Grand Total)

-- YOUR SOLUTION:


-- Question 7.3 (25 points)
-- Use GROUPING SETS to create a custom report showing:
-- 1. Monthly totals (Year, Month)
-- 2. Customer totals (CustomerID)
-- 3. Grand total
-- Expected columns: Year, Month, CustomerID, Orders, Revenue

-- YOUR SOLUTION:



/*
============================================================================
SECTION 8: Real-World Scenarios (70 points)
============================================================================
*/

-- Question 8.1 (20 points)
-- Customer Segmentation: Categorize customers by order frequency
-- One-Time: 1 order
-- Occasional: 2-5 orders
-- Regular: 6-10 orders
-- Frequent: 11+ orders
-- Expected columns: CustomerSegment, CustomerCount, AvgRevenue

-- YOUR SOLUTION:


-- Question 8.2 (25 points)
-- Top 3 products per category by total revenue.
-- Expected columns: CategoryName, ProductName, TotalRevenue, RankInCategory
-- Use window functions with grouping

-- YOUR SOLUTION:


-- Question 8.3 (25 points)
-- Monthly revenue report with year-over-year comparison.
-- Show current year vs previous year revenue for each month.
-- Expected columns: Year, Month, Revenue, PrevYearRevenue, GrowthPercent
-- Hint: Use LAG() or self-join

-- YOUR SOLUTION:



/*
============================================================================
BONUS QUESTIONS (50 extra points)
============================================================================
*/

-- BONUS 1 (15 points)
-- Find customers who have purchased every product in at least one category.
-- (Customers who bought all products from a category)

-- YOUR SOLUTION:


-- BONUS 2 (20 points)
-- RFM Analysis: Segment customers by Recency, Frequency, and Monetary value.
-- Recency: Days since last order (< 30: Recent, < 90: Moderate, else: Dormant)
-- Frequency: Order count (>= 10: Frequent, >= 5: Regular, else: Occasional)
-- Monetary: Total spent (>= 5000: High, >= 1000: Medium, else: Low)
-- Expected columns: RecencyScore, FrequencyScore, MonetaryScore, CustomerCount

-- YOUR SOLUTION:


-- BONUS 3 (15 points)
-- Create a pivot-style report showing product count by Category and Price Range.
-- Price Ranges: <$25, $25-$50, $50-$100, $100+
-- Use conditional aggregation (not PIVOT operator)

-- YOUR SOLUTION:



/*
============================================================================
ANSWER KEY
============================================================================
*/

PRINT 'SECTION 1 SOLUTIONS:';
GO

-- Solution 1.1
SELECT COUNT(*) AS TotalOrders
FROM Orders;

-- Solution 1.2
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY CustomerID
ORDER BY OrderCount DESC;

-- Solution 1.3
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AvgOrderValue,
    COUNT(*) AS OrderCount
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Solution 1.4
SELECT 
    CategoryID,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice,
    COUNT(*) AS ProductCount
FROM Products
WHERE Price IS NOT NULL
GROUP BY CategoryID;

-- Solution 1.5
SELECT COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders;

GO
PRINT 'SECTION 2 SOLUTIONS:';
GO

-- Solution 2.1
SELECT 
    COUNT(*) AS TotalOrders,
    COUNT(ShippedDate) AS ShippedOrders,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM Orders;

-- Solution 2.2
SELECT 
    p.ProductID,
    p.ProductName,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(*) AS TimesPurchased
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(DISTINCT o.CustomerID) > 5
ORDER BY UniqueCustomers DESC;

-- Solution 2.3
SELECT 
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    COUNT(DISTINCT od.ProductID) AS UniqueProductsSold,
    SUM(od.Quantity) AS TotalQuantitySold
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY Year, Month;

-- Solution 2.4
SELECT 
    o.CustomerID,
    COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased,
    COUNT(*) AS TotalOrders
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY o.CustomerID
HAVING COUNT(DISTINCT p.CategoryID) > 2
ORDER BY CategoriesPurchased DESC;

GO
PRINT 'SECTION 3 SOLUTIONS:';
GO

-- Solution 3.1
SELECT 
    YEAR(OrderDate) AS Year,
    DATEPART(QUARTER, OrderDate) AS Quarter,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate)
ORDER BY Year, Quarter;

-- Solution 3.2
SELECT 
    CASE 
        WHEN Price < 25 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END AS PriceRange,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
WHERE Price IS NOT NULL
GROUP BY 
    CASE 
        WHEN Price < 25 THEN 'Budget'
        WHEN Price < 100 THEN 'Standard'
        ELSE 'Premium'
    END;

-- Solution 3.3
SELECT 
    DATENAME(WEEKDAY, OrderDate) AS DayOfWeek,
    DATEPART(WEEKDAY, OrderDate) AS DayNumber,
    COUNT(*) AS OrderCount,
    AVG(TotalAmount) AS AvgOrderValue
FROM Orders
GROUP BY DATENAME(WEEKDAY, OrderDate), DATEPART(WEEKDAY, OrderDate)
ORDER BY DayNumber;

GO
PRINT 'SECTION 4 SOLUTIONS:';
GO

-- Solution 4.1
SELECT 
    COUNT(*) AS TotalOrders,
    COUNT(ShippedDate) AS ShippedOrders,
    COUNT(*) - COUNT(ShippedDate) AS UnshippedOrders,
    CAST(COUNT(ShippedDate) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ShippedPercent
FROM Orders;

-- Solution 4.2
SELECT 
    CategoryID,
    COUNT(*) AS TotalProducts,
    COUNT(Price) AS WithPrice,
    COUNT(*) - COUNT(Price) AS WithoutPrice
FROM Products
GROUP BY CategoryID;

-- Solution 4.3
SELECT 
    AVG(TotalAmount) AS AvgIgnoringNull,
    AVG(ISNULL(TotalAmount, 0)) AS AvgTreatingNullAsZero
FROM Orders;

GO
PRINT 'SECTION 5 SOLUTIONS:';
GO

-- Solution 5.1
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY CategoryID, SupplierID
ORDER BY CategoryID, SupplierID;

-- Solution 5.2
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS MonthlyRevenue
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

-- Solution 5.3
SELECT 
    c.Country,
    YEAR(o.OrderDate) AS Year,
    DATEPART(QUARTER, o.OrderDate) AS Quarter,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(*) AS Orders,
    SUM(o.TotalAmount) AS Revenue
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.Country, YEAR(o.OrderDate), DATEPART(QUARTER, o.OrderDate)
ORDER BY c.Country, Year, Quarter;

GO
PRINT 'SECTION 6 SOLUTIONS:';
GO

-- Solution 6.1
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Orders
GROUP BY CustomerID
HAVING COUNT(*) > 5
ORDER BY OrderCount DESC;

-- Solution 6.2
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    MAX(Price) AS MaxPrice
FROM Products
WHERE Price IS NOT NULL
GROUP BY CategoryID
HAVING AVG(Price) > 50
ORDER BY AvgPrice DESC;

-- Solution 6.3
SELECT 
    p.ProductID,
    p.ProductName,
    SUM(od.Quantity * od.UnitPrice) AS TotalRevenue,
    SUM(od.Quantity) AS UnitsSold
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
HAVING SUM(od.Quantity * od.UnitPrice) > 1000
ORDER BY TotalRevenue DESC;

GO
PRINT 'SECTION 7 SOLUTIONS:';
GO

-- Solution 7.1
SELECT 
    CategoryID,
    SupplierID,
    COUNT(*) AS ProductCount,
    CASE 
        WHEN GROUPING(CategoryID) = 1 AND GROUPING(SupplierID) = 1 THEN 'Grand Total'
        WHEN GROUPING(SupplierID) = 1 THEN 'Category Subtotal'
        ELSE 'Detail'
    END AS RowType
FROM Products
GROUP BY ROLLUP(CategoryID, SupplierID)
ORDER BY CategoryID, SupplierID;

-- Solution 7.2
SELECT 
    YEAR(OrderDate) AS Year,
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS Revenue,
    CASE GROUPING_ID(YEAR(OrderDate), CustomerID)
        WHEN 0 THEN 'Detail'
        WHEN 1 THEN 'Year Total'
        WHEN 2 THEN 'Customer Total'
        WHEN 3 THEN 'Grand Total'
    END AS RowType
FROM Orders
GROUP BY CUBE(YEAR(OrderDate), CustomerID)
ORDER BY Year, CustomerID;

-- Solution 7.3
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    CustomerID,
    COUNT(*) AS Orders,
    SUM(TotalAmount) AS Revenue
FROM Orders
GROUP BY GROUPING SETS (
    (YEAR(OrderDate), MONTH(OrderDate)),
    (CustomerID),
    ()
)
ORDER BY Year, Month, CustomerID;

GO
PRINT 'SECTION 8 SOLUTIONS:';
GO

-- Solution 8.1
WITH CustomerOrders AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount,
        SUM(TotalAmount) AS TotalRevenue
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    CASE 
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount <= 5 THEN 'Occasional'
        WHEN OrderCount <= 10 THEN 'Regular'
        ELSE 'Frequent'
    END AS CustomerSegment,
    COUNT(*) AS CustomerCount,
    AVG(TotalRevenue) AS AvgRevenue
FROM CustomerOrders
GROUP BY 
    CASE 
        WHEN OrderCount = 1 THEN 'One-Time'
        WHEN OrderCount <= 5 THEN 'Occasional'
        WHEN OrderCount <= 10 THEN 'Regular'
        ELSE 'Frequent'
    END;

-- Solution 8.2
WITH ProductRevenue AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        SUM(od.Quantity * od.UnitPrice) AS TotalRevenue,
        ROW_NUMBER() OVER (PARTITION BY c.CategoryName ORDER BY SUM(od.Quantity * od.UnitPrice) DESC) AS RankInCategory
    FROM Categories c
    JOIN Products p ON c.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY c.CategoryID, c.CategoryName, p.ProductID, p.ProductName
)
SELECT CategoryName, ProductName, TotalRevenue, RankInCategory
FROM ProductRevenue
WHERE RankInCategory <= 3
ORDER BY CategoryName, RankInCategory;

-- Solution 8.3
SELECT 
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS Month,
    SUM(TotalAmount) AS Revenue,
    LAG(SUM(TotalAmount), 12) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS PrevYearRevenue,
    CASE 
        WHEN LAG(SUM(TotalAmount), 12) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) IS NOT NULL
        THEN CAST((SUM(TotalAmount) - LAG(SUM(TotalAmount), 12) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate))) * 100.0 / 
                  LAG(SUM(TotalAmount), 12) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS DECIMAL(5,2))
        ELSE NULL
    END AS GrowthPercent
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Year, Month;

GO
PRINT 'BONUS SOLUTIONS:';
GO

-- Bonus Solution 1
WITH CategoryProducts AS (
    SELECT CategoryID, COUNT(DISTINCT ProductID) AS ProductCount
    FROM Products
    GROUP BY CategoryID
),
CustomerCategoryPurchases AS (
    SELECT 
        o.CustomerID,
        p.CategoryID,
        COUNT(DISTINCT od.ProductID) AS ProductsPurchased
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY o.CustomerID, p.CategoryID
)
SELECT DISTINCT ccp.CustomerID
FROM CustomerCategoryPurchases ccp
JOIN CategoryProducts cp ON ccp.CategoryID = cp.CategoryID
WHERE ccp.ProductsPurchased = cp.ProductCount;

-- Bonus Solution 2
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
        WHEN Monetary >= 5000 THEN 'High'
        WHEN Monetary >= 1000 THEN 'Medium'
        ELSE 'Low'
    END AS MonetaryScore,
    COUNT(*) AS CustomerCount
FROM CustomerMetrics
GROUP BY 
    CASE WHEN Recency <= 30 THEN 'Recent' WHEN Recency <= 90 THEN 'Moderate' ELSE 'Dormant' END,
    CASE WHEN Frequency >= 10 THEN 'Frequent' WHEN Frequency >= 5 THEN 'Regular' ELSE 'Occasional' END,
    CASE WHEN Monetary >= 5000 THEN 'High' WHEN Monetary >= 1000 THEN 'Medium' ELSE 'Low' END;

-- Bonus Solution 3
SELECT 
    CategoryID,
    SUM(CASE WHEN Price < 25 THEN 1 ELSE 0 END) AS [Under $25],
    SUM(CASE WHEN Price BETWEEN 25 AND 50 THEN 1 ELSE 0 END) AS [$25-$50],
    SUM(CASE WHEN Price BETWEEN 50 AND 100 THEN 1 ELSE 0 END) AS [$50-$100],
    SUM(CASE WHEN Price >= 100 THEN 1 ELSE 0 END) AS [$100+]
FROM Products
WHERE Price IS NOT NULL
GROUP BY CategoryID;

GO

/*
============================================================================
SCORING GUIDE
============================================================================

SECTION 1: Basic Grouping and Aggregates          /60
SECTION 2: COUNT and DISTINCT                     /70
SECTION 3: Expressions in GROUP BY                /60
SECTION 4: NULL Handling                          /50
SECTION 5: Multicolumn Grouping                   /60
SECTION 6: HAVING Clause                          /60
SECTION 7: ROLLUP, CUBE, GROUPING SETS            /70
SECTION 8: Real-World Scenarios                   /70
                                        SUBTOTAL: /500

BONUS QUESTIONS                                   /50
                                   TOTAL POSSIBLE: /550

Grading Scale:
490-550: Expert (A+)
420-489: Advanced (A)
350-419: Proficient (B)
280-349: Developing (C)
Below 280: Review needed

============================================================================
CONGRATULATIONS!
============================================================================

You've completed the Chapter 08 comprehensive test on Grouping and 
Aggregates. These skills are fundamental to data analysis and reporting.

Key Skills Mastered:
✓ GROUP BY and aggregate functions
✓ Counting and distinct values
✓ Expression-based grouping
✓ NULL handling strategies
✓ Multi-dimensional analysis
✓ Filtering groups with HAVING
✓ Subtotals with ROLLUP/CUBE
✓ Real-world reporting scenarios

Next Chapter: 09 - Subqueries
Learn to write queries within queries for powerful data retrieval.

============================================================================
*/
