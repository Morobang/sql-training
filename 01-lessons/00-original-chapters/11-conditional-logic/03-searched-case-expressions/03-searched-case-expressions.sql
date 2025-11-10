/*
============================================================================
Lesson 11.03 - Searched CASE Expressions
============================================================================

Description:
Master the most flexible and powerful CASE format. Learn to write complex
boolean conditions, handle ranges, combine multiple conditions, and
optimize performance of searched CASE expressions.

Topics Covered:
• Searched CASE syntax
• Complex boolean conditions
• Range checking and comparisons
• Combining conditions (AND, OR, NOT)
• NULL handling in conditions
• Performance optimization
• Real-world complex scenarios

Prerequisites:
• Lessons 11.01-11.02

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Searched CASE Syntax
============================================================================
*/

/*
SEARCHED CASE Format:

CASE
    WHEN boolean_condition1 THEN result1
    WHEN boolean_condition2 THEN result2
    [WHEN boolean_conditionN THEN resultN]
    [ELSE else_result]
END

Key Features:
• Each WHEN can have ANY boolean expression
• Can use <, >, <=, >=, =, <>, BETWEEN, IN, LIKE, IS NULL, EXISTS, etc.
• Most flexible format
• Can check different columns in each WHEN
*/

-- Example 1.1: Basic Searched CASE
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'No Price Set'
        WHEN Price = 0 THEN 'Free'
        WHEN Price < 50 THEN 'Budget'
        WHEN Price >= 50 AND Price < 100 THEN 'Mid-Range'
        WHEN Price >= 100 THEN 'Premium'
    END AS PriceCategory
FROM Products
WHERE ProductID <= 10;

-- Example 1.2: Different Columns in Each Condition
SELECT 
    ProductName,
    Price,
    InStock,
    CASE 
        WHEN Price > 200 THEN 'Expensive Item'
        WHEN InStock = 0 THEN 'Out of Stock'
        WHEN Price < 50 THEN 'Good Deal'
        ELSE 'Standard Item'
    END AS ProductStatus
FROM Products
WHERE ProductID <= 10;

-- Example 1.3: Complex Boolean Logic
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    ShipDate,
    CASE 
        WHEN OrderDate >= '2024-01-01' AND TotalAmount > 500 THEN 'Recent Large Order'
        WHEN OrderDate >= '2024-01-01' AND TotalAmount <= 500 THEN 'Recent Small Order'
        WHEN ShipDate IS NULL THEN 'Not Shipped Yet'
        ELSE 'Older Order'
    END AS OrderCategory
FROM Orders
WHERE OrderID <= 15;


/*
============================================================================
PART 2: Range Checking
============================================================================
*/

-- Method 2.1: Using Comparison Operators
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price < 25 THEN '$0-$24'
        WHEN Price < 50 THEN '$25-$49'
        WHEN Price < 75 THEN '$50-$74'
        WHEN Price < 100 THEN '$75-$99'
        ELSE '$100+'
    END AS PriceRange
FROM Products
WHERE ProductID <= 10;

-- Method 2.2: Using BETWEEN
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price BETWEEN 0 AND 24.99 THEN '$0-$24'
        WHEN Price BETWEEN 25 AND 49.99 THEN '$25-$49'
        WHEN Price BETWEEN 50 AND 74.99 THEN '$50-$74'
        WHEN Price BETWEEN 75 AND 99.99 THEN '$75-$99'
        ELSE '$100+'
    END AS PriceRange
FROM Products
WHERE ProductID <= 10;

-- Method 2.3: Date Ranges
SELECT 
    OrderID,
    OrderDate,
    CASE 
        WHEN OrderDate >= DATEADD(DAY, -7, GETDATE()) THEN 'Last 7 Days'
        WHEN OrderDate >= DATEADD(DAY, -30, GETDATE()) THEN 'Last 30 Days'
        WHEN OrderDate >= DATEADD(DAY, -90, GETDATE()) THEN 'Last 90 Days'
        WHEN OrderDate >= DATEADD(YEAR, -1, GETDATE()) THEN 'Last Year'
        ELSE 'Over 1 Year Ago'
    END AS OrderRecency
FROM Orders
WHERE OrderID <= 20
ORDER BY OrderDate DESC;

-- Method 2.4: Time-Based Ranges
SELECT 
    OrderID,
    OrderDate,
    DATEDIFF(DAY, OrderDate, ShipDate) AS DaysToShip,
    CASE 
        WHEN ShipDate IS NULL THEN 'Not Shipped'
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) = 0 THEN 'Same Day'
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) = 1 THEN 'Next Day'
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) <= 3 THEN '2-3 Days'
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) <= 7 THEN '4-7 Days'
        ELSE 'Over 1 Week'
    END AS ShippingSpeed
FROM Orders
WHERE OrderID <= 20;


/*
============================================================================
PART 3: Combining Multiple Conditions
============================================================================
*/

-- Pattern 3.1: AND Conditions
SELECT 
    ProductName,
    Price,
    CategoryID,
    InStock,
    CASE 
        WHEN CategoryID = 1 AND Price > 200 AND InStock = 1 THEN 'Premium Electronics - Available'
        WHEN CategoryID = 1 AND Price > 200 THEN 'Premium Electronics - Out of Stock'
        WHEN CategoryID = 1 AND InStock = 1 THEN 'Electronics - Available'
        WHEN CategoryID = 1 THEN 'Electronics - Out of Stock'
        ELSE 'Other Product'
    END AS ProductCategory
FROM Products
WHERE ProductID <= 10;

-- Pattern 3.2: OR Conditions
SELECT 
    OrderID,
    TotalAmount,
    CustomerID,
    CASE 
        WHEN TotalAmount > 1000 OR CustomerID IN (1, 2, 3) THEN 'High Priority'
        WHEN TotalAmount > 500 OR CustomerID IN (4, 5, 6) THEN 'Medium Priority'
        ELSE 'Standard Priority'
    END AS Priority
FROM Orders
WHERE OrderID <= 20;

-- Pattern 3.3: NOT Conditions
SELECT 
    ProductName,
    Price,
    CategoryID,
    CASE 
        WHEN NOT (Price > 100) THEN 'Affordable'
        WHEN NOT (CategoryID IN (1, 2)) THEN 'Other Category'
        ELSE 'Standard'
    END AS Classification
FROM Products
WHERE ProductID <= 10;

-- Pattern 3.4: Complex Combined Logic
SELECT 
    OrderID,
    OrderDate,
    TotalAmount,
    CustomerID,
    CASE 
        WHEN (OrderDate >= '2024-01-01' AND TotalAmount > 500) 
             OR (CustomerID IN (1, 2, 3) AND TotalAmount > 200) THEN 'Tier 1'
        WHEN (OrderDate >= '2023-01-01' AND TotalAmount > 300)
             OR TotalAmount > 800 THEN 'Tier 2'
        ELSE 'Tier 3'
    END AS OrderTier
FROM Orders
WHERE OrderID <= 20;


/*
============================================================================
PART 4: IN and NOT IN Conditions
============================================================================
*/

-- Example 4.1: IN with Values
SELECT 
    CustomerName,
    Country,
    CASE 
        WHEN Country IN ('USA', 'Canada', 'Mexico') THEN 'North America'
        WHEN Country IN ('UK', 'France', 'Germany', 'Spain') THEN 'Europe'
        WHEN Country IN ('China', 'Japan', 'India') THEN 'Asia'
        ELSE 'Other Region'
    END AS Region
FROM Customers
WHERE CustomerID <= 20;

-- Example 4.2: NOT IN
SELECT 
    ProductName,
    CategoryID,
    CASE 
        WHEN CategoryID NOT IN (1, 2) THEN 'Special Category'
        WHEN CategoryID = 1 THEN 'Electronics'
        WHEN CategoryID = 2 THEN 'Clothing'
    END AS Category
FROM Products
WHERE ProductID <= 10;

-- Example 4.3: IN with Subquery
SELECT 
    c.CustomerName,
    c.CustomerID,
    CASE 
        WHEN c.CustomerID IN (SELECT CustomerID FROM Orders WHERE TotalAmount > 1000) 
            THEN 'High Value Customer'
        WHEN c.CustomerID IN (SELECT CustomerID FROM Orders WHERE TotalAmount > 500) 
            THEN 'Medium Value Customer'
        ELSE 'Standard Customer'
    END AS CustomerSegment
FROM Customers c
WHERE c.CustomerID <= 10;


/*
============================================================================
PART 5: NULL Handling
============================================================================
*/

-- Pattern 5.1: IS NULL / IS NOT NULL
SELECT 
    OrderID,
    ShipDate,
    DeliveryDate,
    CASE 
        WHEN ShipDate IS NULL THEN 'Order Not Shipped'
        WHEN DeliveryDate IS NULL THEN 'Shipped, Not Delivered'
        WHEN DeliveryDate IS NOT NULL THEN 'Delivered'
    END AS OrderStatus
FROM Orders
WHERE OrderID <= 20;

-- Pattern 5.2: NULL in Comparisons
-- ⚠️ NULL comparisons are always UNKNOWN (not TRUE or FALSE)
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'Price Not Set'
        WHEN Price = 0 THEN 'Free Product'
        WHEN Price > 0 THEN 'For Sale'
    END AS PriceStatus
FROM Products
WHERE ProductID <= 10;

-- Pattern 5.3: COALESCE in Conditions
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN COALESCE(Price, 0) = 0 THEN 'No Price or Free'
        WHEN COALESCE(Price, 0) < 50 THEN 'Budget'
        ELSE 'Regular Price'
    END AS PriceInfo
FROM Products
WHERE ProductID <= 10;

-- Pattern 5.4: Multiple NULL Checks
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DeliveryDate,
    CASE 
        WHEN OrderDate IS NULL THEN 'Invalid Order'
        WHEN ShipDate IS NULL AND DATEDIFF(DAY, OrderDate, GETDATE()) > 7 THEN 'Delayed'
        WHEN ShipDate IS NULL THEN 'Processing'
        WHEN DeliveryDate IS NULL AND DATEDIFF(DAY, ShipDate, GETDATE()) > 5 THEN 'Delivery Issue'
        WHEN DeliveryDate IS NULL THEN 'In Transit'
        ELSE 'Complete'
    END AS Status
FROM Orders
WHERE OrderID <= 20;


/*
============================================================================
PART 6: LIKE and Pattern Matching
============================================================================
*/

-- Example 6.1: LIKE Patterns
SELECT 
    CustomerName,
    Email,
    CASE 
        WHEN Email LIKE '%@gmail.com' THEN 'Gmail User'
        WHEN Email LIKE '%@yahoo.com' THEN 'Yahoo User'
        WHEN Email LIKE '%@hotmail.com' THEN 'Hotmail User'
        WHEN Email LIKE '%@%.com' THEN 'Other .com Email'
        ELSE 'Non-.com Email'
    END AS EmailProvider
FROM Customers
WHERE CustomerID <= 20;

-- Example 6.2: Multiple LIKE Conditions
SELECT 
    ProductName,
    CASE 
        WHEN ProductName LIKE 'Pro%' THEN 'Professional Series'
        WHEN ProductName LIKE '%Plus%' THEN 'Plus Edition'
        WHEN ProductName LIKE '%Mini%' OR ProductName LIKE '%Small%' THEN 'Compact Version'
        ELSE 'Standard Product'
    END AS ProductLine
FROM Products
WHERE ProductID <= 10;


/*
============================================================================
PART 7: EXISTS and Subqueries
============================================================================
*/

-- Example 7.1: EXISTS in CASE
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM Orders 
            WHERE CustomerID = c.CustomerID 
            AND TotalAmount > 1000
        ) THEN 'Has Large Orders'
        WHEN EXISTS (
            SELECT 1 FROM Orders 
            WHERE CustomerID = c.CustomerID
        ) THEN 'Has Small Orders Only'
        ELSE 'No Orders'
    END AS OrderHistory
FROM Customers c
WHERE c.CustomerID <= 10;

-- Example 7.2: NOT EXISTS
SELECT 
    p.ProductID,
    p.ProductName,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM OrderDetails 
            WHERE ProductID = p.ProductID
        ) THEN 'Never Ordered'
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID 
            AND o.OrderDate >= DATEADD(MONTH, -3, GETDATE())
        ) THEN 'Recently Ordered'
        ELSE 'Ordered (Not Recently)'
    END AS OrderStatus
FROM Products p
WHERE p.ProductID <= 10;

-- Example 7.3: Scalar Subquery in Condition
SELECT 
    c.CustomerID,
    c.CustomerName,
    CASE 
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) >= 10 
            THEN 'Frequent Customer'
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) >= 5 
            THEN 'Regular Customer'
        WHEN (SELECT COUNT(*) FROM Orders WHERE CustomerID = c.CustomerID) > 0 
            THEN 'Occasional Customer'
        ELSE 'New Customer'
    END AS CustomerType
FROM Customers c
WHERE c.CustomerID <= 10;


/*
============================================================================
PART 8: Performance Optimization
============================================================================
*/

-- Optimization 8.1: ✅ Order Conditions by Frequency
-- Put most common conditions first
SELECT 
    OrderID,
    TotalAmount,
    CASE 
        WHEN TotalAmount < 100 THEN 'Small'      -- Most common (80%)
        WHEN TotalAmount < 500 THEN 'Medium'     -- Common (15%)
        WHEN TotalAmount < 1000 THEN 'Large'     -- Rare (4%)
        ELSE 'Extra Large'                       -- Very rare (1%)
    END AS OrderSize
FROM Orders;

-- Optimization 8.2: ⚠️ Avoid Functions on Indexed Columns
-- ❌ Slow (function prevents index usage):
SELECT ProductName
FROM Products
WHERE CASE 
        WHEN UPPER(ProductName) LIKE 'PRO%' THEN 1
        ELSE 0
      END = 1;

-- ✅ Better (no function on column):
SELECT ProductName
FROM Products
WHERE CASE 
        WHEN ProductName LIKE 'Pro%' THEN 1
        WHEN ProductName LIKE 'PRO%' THEN 1
        WHEN ProductName LIKE 'pro%' THEN 1
        ELSE 0
      END = 1;

-- Optimization 8.3: ✅ Simplify Complex CASE
-- ❌ Overly complex:
SELECT 
    ProductName,
    CASE 
        WHEN Price > 100 AND Price <= 200 THEN 'Range 1'
        WHEN Price > 200 AND Price <= 300 THEN 'Range 2'
        WHEN Price > 300 AND Price <= 400 THEN 'Range 3'
        ELSE 'Other'
    END AS PriceRange
FROM Products;

-- ✅ Simpler (mutually exclusive conditions):
SELECT 
    ProductName,
    CASE 
        WHEN Price <= 200 THEN 'Range 1'
        WHEN Price <= 300 THEN 'Range 2'
        WHEN Price <= 400 THEN 'Range 3'
        ELSE 'Other'
    END AS PriceRange
FROM Products;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a query categorizing customers by region (North America, Europe, Asia, Other)
2. Write CASE showing order urgency based on days since order and shipping status
3. Use EXISTS to classify products as Popular, Moderate, or Unpopular
4. Create complex category based on price AND stock AND category
5. Use LIKE to categorize emails by domain type

Solutions below ↓
*/

-- Solution 1:
SELECT 
    CustomerName,
    Country,
    CASE 
        WHEN Country IN ('USA', 'Canada', 'Mexico') THEN 'North America'
        WHEN Country IN ('UK', 'Germany', 'France', 'Spain', 'Italy') THEN 'Europe'
        WHEN Country IN ('China', 'Japan', 'India', 'Singapore') THEN 'Asia'
        ELSE 'Other'
    END AS Region
FROM Customers;

-- Solution 2:
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DATEDIFF(DAY, OrderDate, GETDATE()) AS DaysSinceOrder,
    CASE 
        WHEN ShipDate IS NULL AND DATEDIFF(DAY, OrderDate, GETDATE()) > 7 THEN 'CRITICAL - Not Shipped'
        WHEN ShipDate IS NULL AND DATEDIFF(DAY, OrderDate, GETDATE()) > 3 THEN 'HIGH - Delayed'
        WHEN ShipDate IS NULL THEN 'NORMAL - Processing'
        WHEN DATEDIFF(DAY, ShipDate, GETDATE()) > 10 THEN 'CHECK - Long Transit'
        ELSE 'OK'
    END AS Urgency
FROM Orders
WHERE OrderID <= 30;

-- Solution 3:
SELECT 
    p.ProductID,
    p.ProductName,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od
            INNER JOIN Orders o ON od.OrderID = o.OrderID
            WHERE od.ProductID = p.ProductID
            AND o.OrderDate >= DATEADD(MONTH, -1, GETDATE())
            GROUP BY od.ProductID
            HAVING COUNT(*) >= 5
        ) THEN 'Popular'
        WHEN EXISTS (
            SELECT 1 FROM OrderDetails od
            WHERE od.ProductID = p.ProductID
        ) THEN 'Moderate'
        ELSE 'Unpopular'
    END AS Popularity
FROM Products p;

-- Solution 4:
SELECT 
    ProductName,
    Price,
    InStock,
    CategoryID,
    CASE 
        WHEN CategoryID = 1 AND Price > 200 AND InStock = 1 THEN 'Premium Electronics - In Stock'
        WHEN CategoryID = 1 AND Price > 200 THEN 'Premium Electronics - OUT OF STOCK'
        WHEN CategoryID = 1 AND InStock = 1 THEN 'Standard Electronics - In Stock'
        WHEN CategoryID = 1 THEN 'Standard Electronics - OUT OF STOCK'
        WHEN CategoryID = 2 AND Price > 100 AND InStock = 1 THEN 'Designer Clothing - In Stock'
        WHEN CategoryID = 2 AND InStock = 1 THEN 'Regular Clothing - In Stock'
        WHEN InStock = 0 THEN 'OUT OF STOCK'
        ELSE 'Other Product - In Stock'
    END AS DetailedCategory
FROM Products;

-- Solution 5:
SELECT 
    CustomerName,
    Email,
    CASE 
        WHEN Email LIKE '%@gmail.%' THEN 'Google'
        WHEN Email LIKE '%@yahoo.%' OR Email LIKE '%@ymail.%' THEN 'Yahoo'
        WHEN Email LIKE '%@hotmail.%' OR Email LIKE '%@outlook.%' THEN 'Microsoft'
        WHEN Email LIKE '%@%.edu' THEN 'Educational'
        WHEN Email LIKE '%@%.gov' THEN 'Government'
        WHEN Email LIKE '%@%.org' THEN 'Organization'
        ELSE 'Other/Business'
    END AS EmailType
FROM Customers;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SEARCHED CASE:
  • Most flexible CASE format
  • Any boolean condition allowed
  • Can check different columns per WHEN
  • Use for complex logic

✓ CONDITION TYPES:
  • Comparisons: <, >, <=, >=, =, <>
  • Ranges: BETWEEN, multiple conditions
  • Lists: IN, NOT IN
  • Patterns: LIKE
  • NULL: IS NULL, IS NOT NULL
  • Existence: EXISTS, NOT EXISTS

✓ COMBINING CONDITIONS:
  • AND: All must be true
  • OR: Any can be true
  • NOT: Negates condition
  • Parentheses for grouping

✓ NULL HANDLING:
  • NULL comparisons are UNKNOWN
  • Use IS NULL / IS NOT NULL
  • COALESCE for defaults
  • Check NULL before other conditions

✓ PERFORMANCE:
  • Order by frequency (common first)
  • Avoid functions on indexed columns
  • Simplify complex conditions
  • Test with execution plans

✓ BEST PRACTICES:
  • Put specific conditions before general
  • Use BETWEEN for ranges
  • Handle NULL explicitly
  • Comment complex logic
  • Test all branches
  • Keep conditions readable

✓ WHEN TO USE:
  • Complex conditions
  • Different columns per condition
  • Range checking
  • Pattern matching
  • Existence checks

============================================================================
NEXT: Lesson 11.04 - Simple CASE Expressions
Learn the concise equality-based CASE format.
============================================================================
*/
