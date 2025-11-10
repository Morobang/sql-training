/*
============================================================================
Lesson 10.07 - Join Conditions and Filters
============================================================================

Description:
Master the critical differences between ON and WHERE clauses in joins.
Learn when to use each, how they affect results, and explore complex
join predicates and non-equi join conditions.

Topics Covered:
• ON vs WHERE clause
• Join conditions vs result filters
• Complex join predicates
• Multiple conditions in joins
• Non-equi join conditions
• Performance implications

Prerequisites:
• Lessons 10.01-10.06
• Understanding of boolean logic

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: ON vs WHERE - The Critical Difference
============================================================================
*/

-- Example 1.1: WHERE clause (filters results AFTER join)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01';

/*
Result: Only customers with orders from 2024+
The LEFT JOIN is effectively converted to INNER JOIN
because WHERE filters out NULLs
*/

-- Example 1.2: ON clause (filters DURING join)
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01';

/*
Result: ALL customers
• With their 2024+ orders (if any)
• With NULL for orders if no 2024 orders
Preserves LEFT JOIN behavior
*/

-- Example 1.3: Side-by-side comparison
-- Filter in WHERE:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 500
GROUP BY c.CustomerID, c.CustomerName;
-- Result: Only customers with orders > $500

-- Filter in ON:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS LargeOrderCount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500
GROUP BY c.CustomerID, c.CustomerName;
-- Result: ALL customers, count of their large orders (0 if none)


/*
============================================================================
PART 2: Complex Join Predicates
============================================================================
*/

-- Example 2.1: Multiple AND conditions
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01'
    AND o.TotalAmount > 100
    AND o.TotalAmount < 1000;

-- Example 2.2: OR conditions in ON clause
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND (o.TotalAmount > 1000 OR o.OrderDate >= DATEADD(MONTH, -1, GETDATE()));
-- Matches large orders OR recent orders

-- Example 2.3: Complex boolean logic
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND (
        (o.OrderDate >= '2024-01-01' AND o.TotalAmount > 500)
        OR
        (o.OrderDate >= '2023-01-01' AND o.TotalAmount > 1000)
    );

-- Example 2.4: NOT conditions
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.ProductID <> p2.ProductID  -- Not same product
    AND NOT (p1.Price = p2.Price)     -- Different prices
WHERE p1.ProductID < p2.ProductID;     -- Avoid duplicates


/*
============================================================================
PART 3: When to Use ON vs WHERE
============================================================================
*/

-- Guideline 3.1: LEFT/RIGHT JOIN filters
-- ✅ Use ON to filter right table (preserves left table):
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500;  -- Filter orders, keep all customers

-- ❌ Don't use WHERE for right table (breaks LEFT JOIN):
-- This returns only customers with large orders:
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 500;

-- Guideline 3.2: INNER JOIN - doesn't matter (usually)
-- These produce the same result:
SELECT * FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500;

SELECT * FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 500;

-- Guideline 3.3: Filter left table in WHERE
-- ✅ Always use WHERE to filter left table:
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.Country = 'USA';  -- Filter customers
-- Returns: USA customers with their orders (if any)


/*
============================================================================
PART 4: Multiple Conditions and Expressions
============================================================================
*/

-- Example 4.1: Calculated conditions
SELECT 
    o1.OrderID AS Order1,
    o2.OrderID AS Order2,
    o1.OrderDate,
    o2.OrderDate,
    DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DaysBetween
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate > o1.OrderDate
    AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) <= 30
WHERE o1.CustomerID = 1;

-- Example 4.2: CASE in ON clause
SELECT 
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND CASE 
        WHEN c.Country = 'USA' THEN o.TotalAmount > 100
        ELSE o.TotalAmount > 50
    END = 1;

-- Example 4.3: Date range conditions
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
INNER JOIN Orders ref 
    ON YEAR(o.OrderDate) = YEAR(ref.OrderDate)
    AND MONTH(o.OrderDate) = MONTH(ref.OrderDate)
    AND o.OrderID <> ref.OrderID
WHERE o.OrderID = 100;

-- Example 4.4: String matching in ON
SELECT 
    c1.CustomerName AS Customer1,
    c2.CustomerName AS Customer2
FROM Customers c1
INNER JOIN Customers c2 
    ON c1.CustomerID < c2.CustomerID
    AND SOUNDEX(c1.CustomerName) = SOUNDEX(c2.CustomerName);


/*
============================================================================
PART 5: Non-Equi Join Conditions
============================================================================
*/

-- Example 5.1: Greater than/less than
SELECT 
    p1.ProductName AS CheaperProduct,
    p1.Price AS Price1,
    p2.ProductName AS ExpensiveProduct,
    p2.Price AS Price2
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.Price < p2.Price
WHERE p1.ProductID = 1;

-- Example 5.2: BETWEEN in join condition
-- Create price ranges table
CREATE TABLE #PriceRanges (
    RangeID INT,
    RangeName VARCHAR(50),
    MinPrice DECIMAL(10,2),
    MaxPrice DECIMAL(10,2)
);

INSERT INTO #PriceRanges VALUES
(1, 'Budget', 0, 50),
(2, 'Standard', 50, 100),
(3, 'Premium', 100, 200),
(4, 'Luxury', 200, 999999);

SELECT 
    p.ProductName,
    p.Price,
    pr.RangeName
FROM Products p
INNER JOIN #PriceRanges pr 
    ON p.Price >= pr.MinPrice
    AND p.Price < pr.MaxPrice;

DROP TABLE #PriceRanges;

-- Example 5.3: NOT EQUAL
SELECT 
    p1.ProductName,
    p2.ProductName,
    p1.CategoryID
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.ProductID <> p2.ProductID
WHERE p1.ProductID <= 5;

-- Example 5.4: Date overlap
CREATE TABLE #Projects (
    ProjectID INT,
    ProjectName VARCHAR(50),
    StartDate DATE,
    EndDate DATE
);

INSERT INTO #Projects VALUES
(1, 'Project A', '2024-01-01', '2024-03-31'),
(2, 'Project B', '2024-02-15', '2024-05-15'),
(3, 'Project C', '2024-04-01', '2024-06-30');

-- Find overlapping projects
SELECT 
    p1.ProjectName AS Project1,
    p2.ProjectName AS Project2,
    p1.StartDate AS Start1,
    p1.EndDate AS End1,
    p2.StartDate AS Start2,
    p2.EndDate AS End2
FROM #Projects p1
INNER JOIN #Projects p2 
    ON p1.ProjectID < p2.ProjectID
    AND p1.StartDate <= p2.EndDate
    AND p2.StartDate <= p1.EndDate;

DROP TABLE #Projects;


/*
============================================================================
PART 6: Performance Implications
============================================================================
*/

-- Performance 6.1: ⚠️ Functions in ON clause hurt performance
-- Slow (function on join column):
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o 
    ON UPPER(c.CustomerID) = UPPER(o.CustomerID);  -- Bad!

-- Fast (direct comparison):
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o 
    ON c.CustomerID = o.CustomerID;

-- Performance 6.2: ✅ Filter in ON when possible (for LEFT JOIN)
-- Less efficient (large join then filter):
SELECT c.CustomerName, o.OrderID
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01' OR o.OrderDate IS NULL;

-- More efficient (filter during join):
SELECT c.CustomerName, o.OrderID
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01';

-- Performance 6.3: ✅ Complex conditions - test both ways
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Approach 1: Complex condition in ON
SELECT COUNT(*)
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate > o1.OrderDate
    AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) <= 30;

-- Approach 2: Simple ON, complex WHERE
SELECT COUNT(*)
FROM Orders o1
INNER JOIN Orders o2 ON o1.CustomerID = o2.CustomerID
WHERE o2.OrderDate > o1.OrderDate
  AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) <= 30;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


/*
============================================================================
PART 7: Real-World Scenarios
============================================================================
*/

-- Scenario 7.1: Customer segmentation with conditional joining
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS PremiumOrders,
    SUM(o.TotalAmount) AS PremiumRevenue
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500  -- Only count premium orders
    AND o.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY c.CustomerID, c.CustomerName
HAVING COUNT(o.OrderID) > 0  -- Customers with premium orders
ORDER BY PremiumRevenue DESC;

-- Scenario 7.2: Product recommendations (price-based)
SELECT 
    p1.ProductName AS CurrentProduct,
    p1.Price AS CurrentPrice,
    p2.ProductName AS SuggestedProduct,
    p2.Price AS SuggestedPrice,
    ABS(p1.Price - p2.Price) AS PriceDifference
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID <> p2.CategoryID  -- Different category
    AND ABS(p1.Price - p2.Price) < 20   -- Similar price
    AND p1.ProductID < p2.ProductID     -- Avoid duplicates
ORDER BY p1.ProductName, PriceDifference;

-- Scenario 7.3: Sequential order analysis
SELECT 
    o1.OrderID AS CurrentOrder,
    o1.OrderDate AS CurrentDate,
    o1.TotalAmount AS CurrentAmount,
    o2.OrderID AS NextOrder,
    o2.OrderDate AS NextDate,
    o2.TotalAmount AS NextAmount,
    DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DaysBetween,
    o2.TotalAmount - o1.TotalAmount AS AmountChange
FROM Orders o1
LEFT JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate > o1.OrderDate
    AND o2.OrderDate = (
        SELECT MIN(OrderDate)
        FROM Orders
        WHERE CustomerID = o1.CustomerID
        AND OrderDate > o1.OrderDate
    )
WHERE o1.CustomerID = 1
ORDER BY o1.OrderDate;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find all customers and their orders over $500 (include customers with no large orders)
2. Join products to themselves where price difference is less than $10
3. Find orders placed within 7 days of each other by the same customer
4. Show products with their price range category using BETWEEN
5. List customers with orders, filtered by country in WHERE vs ON

Solutions below ↓
*/

-- Solution 1:
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500
ORDER BY c.CustomerName, o.TotalAmount DESC;

-- Solution 2:
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    ABS(p1.Price - p2.Price) AS Difference
FROM Products p1
INNER JOIN Products p2 
    ON p1.ProductID < p2.ProductID
    AND ABS(p1.Price - p2.Price) < 10
ORDER BY Difference;

-- Solution 3:
SELECT 
    o1.OrderID AS Order1,
    o1.OrderDate AS Date1,
    o2.OrderID AS Order2,
    o2.OrderDate AS Date2,
    DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DaysBetween
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o1.OrderID < o2.OrderID
    AND o2.OrderDate > o1.OrderDate
    AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) <= 7
ORDER BY o1.CustomerID, o1.OrderDate;

-- Solution 4:
CREATE TABLE #Ex4Ranges (Range VARCHAR(20), Min DECIMAL(10,2), Max DECIMAL(10,2));
INSERT INTO #Ex4Ranges VALUES ('Low', 0, 50), ('Medium', 50, 100), ('High', 100, 999999);

SELECT 
    p.ProductName,
    p.Price,
    r.Range AS PriceRange
FROM Products p
INNER JOIN #Ex4Ranges r 
    ON p.Price >= r.Min
    AND p.Price < r.Max
ORDER BY p.Price;

DROP TABLE #Ex4Ranges;

-- Solution 5:
-- Filter in WHERE (only USA customers):
SELECT c.CustomerName, o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.Country = 'USA';

-- Filter in ON (shows different results for outer join):
SELECT c.CustomerName, o.OrderID
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND c.Country = 'USA';  -- Wrong! Filters nothing
-- Use WHERE for left table filtering


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ ON VS WHERE:
  • ON: Join conditions (when to match rows)
  • WHERE: Result filters (which rows to keep)
  • Critical difference for outer joins
  • Same result for inner joins (usually)

✓ LEFT/RIGHT JOIN RULES:
  • Filter right table in ON (preserves left)
  • Filter left table in WHERE
  • WHERE on right table breaks outer join
  • Multiple conditions: use AND/OR in ON

✓ COMPLEX CONDITIONS:
  • AND, OR, NOT supported
  • Calculations allowed
  • CASE expressions work
  • Be careful with functions (performance)

✓ NON-EQUI JOINS:
  • <, >, <=, >=, <>
  • BETWEEN for ranges
  • Date overlaps
  • Price comparisons

✓ PERFORMANCE:
  • Avoid functions on join columns
  • Index join columns
  • Filter early when possible
  • Test complex conditions both ways

✓ BEST PRACTICES:
  • Be explicit about intent
  • Comment complex conditions
  • Use parentheses for clarity
  • Test with small datasets first
  • Understand ON vs WHERE impact

✓ COMMON PATTERNS:
  • Date ranges (BETWEEN)
  • Price tiers (>=, <)
  • Sequence analysis (>, DATEDIFF)
  • Self-comparisons (<>, <)
  • Conditional matching (CASE)

============================================================================
NEXT: Lesson 10.08 - Non-Equi Joins
Deep dive into inequality and range-based joins.
============================================================================
*/
