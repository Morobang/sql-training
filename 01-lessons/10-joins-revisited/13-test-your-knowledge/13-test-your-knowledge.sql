/*
============================================================================
Lesson 10.13 - Test Your Knowledge: Joins Revisited
============================================================================

COMPREHENSIVE ASSESSMENT

Time Limit: 90 minutes
Total Points: 500 points
Passing Score: 350 points (70%)

Topics Covered:
• All join types (INNER, LEFT, RIGHT, FULL, CROSS)
• Join conditions and filters
• Non-equi joins
• Semi-joins and anti-joins (EXISTS, NOT EXISTS)
• Join performance optimization
• CROSS APPLY and OUTER APPLY
• Complex multi-table joins

Instructions:
1. Read each question carefully
2. Write queries that produce correct results
3. Optimize for performance where indicated
4. Comment your approach for complex queries
5. Test your solutions before submitting

Database: RetailStore
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
SECTION 1: JOIN FUNDAMENTALS (100 points)
============================================================================
*/

-- Question 1.1 (15 points)
-- Write a query to show all customers with their orders.
-- Include: CustomerName, Email, OrderID, OrderDate, TotalAmount
-- Include only customers who have placed orders.
-- Sort by CustomerName, then OrderDate.

-- YOUR SOLUTION:






-- Question 1.2 (20 points)
-- Show all customers and their order counts.
-- Include: CustomerID, CustomerName, OrderCount
-- Include ALL customers (even those with no orders).
-- Customers with no orders should show 0 for OrderCount.
-- Sort by OrderCount DESC, then CustomerName.

-- YOUR SOLUTION:






-- Question 1.3 (20 points)
-- Find all products and show how many times they've been ordered.
-- Include: ProductID, ProductName, Price, TimesOrdered
-- Include ALL products (even never ordered).
-- Show 0 for TimesOrdered if product never ordered.
-- Sort by TimesOrdered DESC.

-- YOUR SOLUTION:






-- Question 1.4 (25 points)
-- Create a query showing all possible customer-product combinations
-- for customers with CustomerID <= 3 and products with ProductID <= 5.
-- Include: CustomerName, ProductName
-- How many rows should this return? ______
-- Sort by CustomerName, ProductName.

-- YOUR SOLUTION:






-- Question 1.5 (20 points)
-- Show customers with their first order date and last order date.
-- Include: CustomerID, CustomerName, FirstOrder, LastOrder
-- Include only customers who have placed orders.
-- Sort by CustomerName.

-- YOUR SOLUTION:







/*
============================================================================
SECTION 2: OUTER JOINS AND NULL HANDLING (75 points)
============================================================================
*/

-- Question 2.1 (25 points)
-- Find customers who have NEVER placed an order.
-- Include: CustomerID, CustomerName, Email
-- Use a LEFT JOIN approach.
-- Sort by CustomerName.

-- YOUR SOLUTION:






-- Question 2.2 (25 points)
-- Show all customers with their orders from 2024.
-- Include: CustomerName, OrderID, OrderDate, TotalAmount
-- Include ALL customers (even those without 2024 orders).
-- Customers without 2024 orders should show NULL for order columns.
-- Sort by CustomerName, OrderDate.

-- YOUR SOLUTION:






-- Question 2.3 (25 points)
-- Find all orders and show customer information.
-- If customer information is missing, still show the order.
-- Include: OrderID, OrderDate, CustomerName, CustomerEmail
-- Use appropriate NULL handling for customer columns.
-- Sort by OrderID.

-- YOUR SOLUTION:







/*
============================================================================
SECTION 3: JOIN CONDITIONS VS FILTERS (50 points)
============================================================================
*/

-- Question 3.1 (25 points)
-- Show all customers with their large orders (> $500).
-- VERSION A: Include ALL customers, show NULL if no large orders
-- VERSION B: Include only customers WITH large orders
-- Write BOTH queries and explain the difference in comments.

-- VERSION A (ALL customers):






-- VERSION B (Only customers with large orders):






-- Explain the key difference:
/*


*/


-- Question 3.2 (25 points)
-- Show all customers with their order counts by year.
-- Include: CustomerName, OrderYear, OrderCount
-- Filter: Only show data for years 2023 and 2024
-- Include ALL customers (even if no orders in those years)
-- How would you write this? Which clause for the year filter?

-- YOUR SOLUTION:







/*
============================================================================
SECTION 4: NON-EQUI JOINS (75 points)
============================================================================
*/

-- Question 4.1 (25 points)
-- Find all product pairs from the same category where one product
-- costs between $10 and $50 more than the other.
-- Include: Product1, Price1, Product2, Price2, PriceDifference
-- Avoid duplicate pairs (A-B and B-A).
-- Sort by PriceDifference DESC.

-- YOUR SOLUTION:






-- Question 4.2 (25 points)
-- Assign orders to quarterly periods for 2024.
-- Create a table with quarters:
--   Q1: Jan 1 - Mar 31
--   Q2: Apr 1 - Jun 30
--   Q3: Jul 1 - Sep 30
--   Q4: Oct 1 - Dec 31
-- Show: OrderID, OrderDate, QuarterName
-- Use BETWEEN in join condition.

-- YOUR SOLUTION:






-- Question 4.3 (25 points)
-- Find orders placed within 7 days of each other by the same customer.
-- Include: CustomerID, Order1ID, Order1Date, Order2ID, Order2Date, DaysBetween
-- Show each pair only once (avoid duplicates).
-- Sort by CustomerID, Order1Date.

-- YOUR SOLUTION:







/*
============================================================================
SECTION 5: SEMI-JOINS AND ANTI-JOINS (75 points)
============================================================================
*/

-- Question 5.1 (15 points)
-- Find all customers who have placed at least one order.
-- Use EXISTS (not JOIN).
-- Include: CustomerID, CustomerName, Email
-- Sort by CustomerName.

-- YOUR SOLUTION:






-- Question 5.2 (15 points)
-- Find all products that have NEVER been ordered.
-- Use NOT EXISTS.
-- Include: ProductID, ProductName, Price
-- Sort by ProductName.

-- YOUR SOLUTION:






-- Question 5.3 (20 points)
-- Find customers who ordered in 2023 but NOT in 2024.
-- Use EXISTS and NOT EXISTS.
-- Include: CustomerID, CustomerName
-- Sort by CustomerName.

-- YOUR SOLUTION:






-- Question 5.4 (25 points)
-- Find customers who have ordered Product 1 AND Product 2
-- (can be in different orders).
-- Use EXISTS (not JOIN).
-- Include: CustomerID, CustomerName
-- Sort by CustomerName.

-- YOUR SOLUTION:







/*
============================================================================
SECTION 6: PERFORMANCE AND OPTIMIZATION (50 points)
============================================================================
*/

-- Question 6.1 (25 points)
-- Write TWO versions of a query to find customers with orders:
-- Version A: Using JOIN
-- Version B: Using EXISTS
-- Include: CustomerID, CustomerName
-- Turn on STATISTICS IO and TIME to compare.
-- Which performs better? _________________

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Version A (JOIN):






-- Version B (EXISTS):






SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


-- Question 6.2 (25 points)
-- This query has performance problems. Identify THREE issues:
/*
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o 
    ON UPPER(c.CustomerID) = UPPER(o.CustomerID)
WHERE YEAR(o.OrderDate) = 2024;
*/

-- Issue 1:


-- Issue 2:


-- Issue 3:


-- Write the optimized version:







/*
============================================================================
SECTION 7: CROSS APPLY / OUTER APPLY (75 points)
============================================================================
*/

-- Question 7.1 (25 points)
-- For each customer, show their top 3 orders by TotalAmount.
-- Use CROSS APPLY.
-- Include: CustomerID, CustomerName, OrderID, OrderDate, TotalAmount
-- Sort by CustomerID, TotalAmount DESC.

-- YOUR SOLUTION:






-- Question 7.2 (25 points)
-- Show all customers with their most recent order.
-- Use OUTER APPLY (include customers with no orders).
-- Include: CustomerID, CustomerName, LastOrderDate, LastOrderAmount
-- Sort by CustomerName.

-- YOUR SOLUTION:






-- Question 7.3 (25 points)
-- For each product, find the 3 most similar products by price
-- (within same category, price difference < $30).
-- Use CROSS APPLY.
-- Include: ProductID, ProductName, Price, SimilarProduct, SimilarPrice
-- Limit to ProductID <= 5 for testing.

-- YOUR SOLUTION:







/*
============================================================================
SECTION 8: COMPLEX SCENARIOS (100 points - BONUS QUESTIONS)
============================================================================
*/

-- Question 8.1 (25 points)
-- Create a customer segmentation report:
-- Categories:
--   - VIP: 10+ orders
--   - Regular: 5-9 orders
--   - New: 1-4 orders
--   - Inactive: 0 orders
-- Include: CustomerName, OrderCount, TotalSpent, Segment
-- Sort by Segment, TotalSpent DESC.

-- YOUR SOLUTION:






-- Question 8.2 (25 points)
-- Find "buying patterns": customers who ordered the same product
-- multiple times.
-- Include: CustomerID, CustomerName, ProductID, ProductName, PurchaseCount
-- Show only where PurchaseCount >= 2.
-- Sort by PurchaseCount DESC.

-- YOUR SOLUTION:






-- Question 8.3 (25 points)
-- Show month-over-month order growth:
-- Include: OrderMonth, OrderCount, PreviousMonthCount, GrowthPercent
-- Use self-join or window functions.
-- Sort by OrderMonth.

-- YOUR SOLUTION:






-- Question 8.4 (25 points)
-- Find "cross-sell opportunities": products frequently bought together.
-- Find product pairs that appear in the same order at least once.
-- Include: Product1, Product2, TimesBoughtTogether
-- Avoid duplicates (A-B and B-A should appear once).
-- Sort by TimesBoughtTogether DESC.

-- YOUR SOLUTION:







/*
============================================================================
ANSWER KEY AND GRADING RUBRIC
============================================================================

SECTION 1: JOIN FUNDAMENTALS (100 points)
------------------------------------------

Question 1.1 (15 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerName, o.OrderDate;

-- Grading:
-- 10 points: Correct join and columns
-- 3 points: Correct INNER JOIN (only customers with orders)
-- 2 points: Correct sorting

/*
Question 1.2 (20 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY OrderCount DESC, c.CustomerName;

-- Grading:
-- 8 points: LEFT JOIN (includes all customers)
-- 5 points: COUNT(o.OrderID) gives 0 for no orders
-- 4 points: GROUP BY correct columns
-- 3 points: Correct ORDER BY

/*
Question 1.3 (20 points):
*/
-- CORRECT SOLUTION:
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    COUNT(od.OrderDetailID) AS TimesOrdered
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName, p.Price
ORDER BY TimesOrdered DESC;

-- Grading:
-- 8 points: LEFT JOIN (includes all products)
-- 5 points: COUNT correctly shows 0 for never ordered
-- 4 points: GROUP BY includes all non-aggregated columns
-- 3 points: Correct ORDER BY

/*
Question 1.4 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerName,
    p.ProductName
FROM Customers c
CROSS JOIN Products p
WHERE c.CustomerID <= 3 
  AND p.ProductID <= 5
ORDER BY c.CustomerName, p.ProductName;

-- Answer: 15 rows (3 customers × 5 products)

-- Grading:
-- 10 points: CROSS JOIN used
-- 5 points: Correct WHERE filters
-- 5 points: Correct row count (15)
-- 5 points: Correct ORDER BY

/*
Question 1.5 (20 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    MIN(o.OrderDate) AS FirstOrder,
    MAX(o.OrderDate) AS LastOrder
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY c.CustomerName;

-- Grading:
-- 8 points: INNER JOIN (only customers with orders)
-- 6 points: MIN and MAX for dates
-- 4 points: GROUP BY correct
-- 2 points: ORDER BY correct


/*
SECTION 2: OUTER JOINS AND NULL HANDLING (75 points)
-----------------------------------------------------

Question 2.1 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL
ORDER BY c.CustomerName;

-- Grading:
-- 10 points: LEFT JOIN used
-- 10 points: WHERE checks for NULL (finds non-matching rows)
-- 3 points: Correct columns selected
-- 2 points: ORDER BY correct

/*
Question 2.2 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND YEAR(o.OrderDate) = 2024
ORDER BY c.CustomerName, o.OrderDate;

-- Alternative (also correct):
SELECT 
    c.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.OrderDate >= '2024-01-01'
    AND o.OrderDate < '2025-01-01'
ORDER BY c.CustomerName, o.OrderDate;

-- Grading:
-- 12 points: LEFT JOIN used
-- 10 points: Year filter in ON clause (not WHERE!)
-- 3 points: Correct result (all customers, nulls for non-2024)

/*
Question 2.3 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    c.Email AS CustomerEmail
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderID;

-- Alternative with NULL handling:
SELECT 
    o.OrderID,
    o.OrderDate,
    ISNULL(c.CustomerName, 'Unknown') AS CustomerName,
    ISNULL(c.Email, 'N/A') AS CustomerEmail
FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderID;

-- Grading:
-- 10 points: LEFT JOIN from Orders
-- 8 points: Shows all orders regardless of customer existence
-- 5 points: Handles NULLs appropriately (either allow or use ISNULL)
-- 2 points: ORDER BY correct


/*
SECTION 3: JOIN CONDITIONS VS FILTERS (50 points)
--------------------------------------------------

Question 3.1 (25 points):
*/
-- VERSION A (ALL customers):
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND o.TotalAmount > 500
ORDER BY c.CustomerName;

-- VERSION B (Only customers with large orders):
SELECT 
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalAmount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.TotalAmount > 500
ORDER BY c.CustomerName;

-- Explanation:
/*
VERSION A uses LEFT JOIN with filter in ON clause:
- Returns ALL customers
- Shows large orders for those who have them
- Shows NULL for customers without large orders

VERSION B uses WHERE clause:
- Returns only customers WITH large orders
- WHERE filters after join, removing rows with NULL
- LEFT JOIN would behave like INNER JOIN here
*/

-- Grading:
-- 10 points: Version A correct (LEFT JOIN, filter in ON)
-- 10 points: Version B correct (INNER JOIN or WHERE filter)
-- 5 points: Explanation shows understanding

/*
Question 3.2 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerName,
    YEAR(o.OrderDate) AS OrderYear,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
    AND YEAR(o.OrderDate) IN (2023, 2024)
GROUP BY c.CustomerID, c.CustomerName, YEAR(o.OrderDate)
ORDER BY c.CustomerName, OrderYear;

-- Alternative with WHERE (less correct - filters customers):
SELECT 
    c.CustomerName,
    YEAR(o.OrderDate) AS OrderYear,
    COUNT(o.OrderID) AS OrderCount
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE YEAR(o.OrderDate) IN (2023, 2024) OR o.OrderDate IS NULL
GROUP BY c.CustomerID, c.CustomerName, YEAR(o.OrderDate)
ORDER BY c.CustomerName, OrderYear;

-- Grading:
-- 12 points: Year filter in ON clause (preserves all customers)
-- 8 points: GROUP BY includes year
-- 5 points: Correct result structure


/*
SECTION 4: NON-EQUI JOINS (75 points)
--------------------------------------

Question 4.1 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    p2.Price - p1.Price AS PriceDifference
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p2.Price BETWEEN p1.Price + 10 AND p1.Price + 50
    AND p1.ProductID < p2.ProductID
ORDER BY PriceDifference DESC;

-- Grading:
-- 10 points: Correct join condition (price difference)
-- 8 points: Avoids duplicates (p1.ProductID < p2.ProductID)
-- 5 points: BETWEEN $10-$50 correctly
-- 2 points: ORDER BY correct

/*
Question 4.2 (25 points):
*/
-- CORRECT SOLUTION:
CREATE TABLE #Quarters (
    QuarterName VARCHAR(10),
    StartDate DATE,
    EndDate DATE
);

INSERT INTO #Quarters VALUES
('Q1 2024', '2024-01-01', '2024-03-31'),
('Q2 2024', '2024-04-01', '2024-06-30'),
('Q3 2024', '2024-07-01', '2024-09-30'),
('Q4 2024', '2024-10-01', '2024-12-31');

SELECT 
    o.OrderID,
    o.OrderDate,
    q.QuarterName
FROM Orders o
INNER JOIN #Quarters q 
    ON o.OrderDate BETWEEN q.StartDate AND q.EndDate
ORDER BY o.OrderDate;

DROP TABLE #Quarters;

-- Grading:
-- 10 points: Creates quarters table
-- 10 points: BETWEEN in join condition
-- 5 points: Correct date ranges

/*
Question 4.3 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    o1.CustomerID,
    o1.OrderID AS Order1ID,
    o1.OrderDate AS Order1Date,
    o2.OrderID AS Order2ID,
    o2.OrderDate AS Order2Date,
    DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DaysBetween
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o1.OrderID < o2.OrderID
    AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) BETWEEN 1 AND 7
ORDER BY o1.CustomerID, o1.OrderDate;

-- Grading:
-- 10 points: Self-join on same customer
-- 8 points: DATEDIFF within 7 days
-- 5 points: Avoids duplicates (o1.OrderID < o2.OrderID)
-- 2 points: ORDER BY correct


/*
SECTION 5: SEMI-JOINS AND ANTI-JOINS (75 points)
-------------------------------------------------

Question 5.1 (15 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Email
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
)
ORDER BY c.CustomerName;

-- Grading:
-- 10 points: EXISTS used correctly
-- 3 points: Correlated subquery
-- 2 points: ORDER BY

/*
Question 5.2 (15 points):
*/
-- CORRECT SOLUTION:
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price
FROM Products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM OrderDetails od 
    WHERE od.ProductID = p.ProductID
)
ORDER BY p.ProductName;

-- Grading:
-- 10 points: NOT EXISTS used correctly
-- 3 points: Correct correlated subquery
-- 2 points: ORDER BY

/*
Question 5.3 (20 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND YEAR(o.OrderDate) = 2023
)
AND NOT EXISTS (
    SELECT 1 
    FROM Orders o 
    WHERE o.CustomerID = c.CustomerID
      AND YEAR(o.OrderDate) = 2024
)
ORDER BY c.CustomerName;

-- Grading:
-- 8 points: EXISTS for 2023 orders
-- 8 points: NOT EXISTS for 2024 orders
-- 4 points: Correct result (ordered in 2023, not 2024)

/*
Question 5.4 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
      AND od.ProductID = 1
)
AND EXISTS (
    SELECT 1 
    FROM Orders o
    INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE o.CustomerID = c.CustomerID
      AND od.ProductID = 2
)
ORDER BY c.CustomerName;

-- Grading:
-- 10 points: First EXISTS for Product 1
-- 10 points: Second EXISTS for Product 2
-- 5 points: Correct logic (both products ordered)


/*
SECTION 6: PERFORMANCE AND OPTIMIZATION (50 points)
----------------------------------------------------

Question 6.1 (25 points):
*/
-- Version A (JOIN):
SELECT DISTINCT
    c.CustomerID,
    c.CustomerName
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID;

-- Version B (EXISTS):
SELECT 
    c.CustomerID,
    c.CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID
);

-- Answer: EXISTS typically performs better (no DISTINCT needed, stops at first match)

-- Grading:
-- 10 points: Both queries correct
-- 10 points: Performance comparison done
-- 5 points: Correct answer about which is faster

/*
Question 6.2 (25 points):
*/
-- Issues:
-- 1. Function on join columns (UPPER) prevents index usage
-- 2. Function on OrderDate (YEAR) prevents index usage  
-- 3. Data type conversion on CustomerID (if INT to VARCHAR)

-- Optimized version:
SELECT 
    c.CustomerName,
    o.OrderID
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= '2024-01-01' 
  AND o.OrderDate < '2025-01-01';

-- Grading:
-- 5 points per issue identified (15 total)
-- 10 points: Optimized version correct


/*
SECTION 7: CROSS APPLY / OUTER APPLY (75 points)
-------------------------------------------------

Question 7.1 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    top3.OrderID,
    top3.OrderDate,
    top3.TotalAmount
FROM Customers c
CROSS APPLY (
    SELECT TOP 3
        OrderID,
        OrderDate,
        TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY TotalAmount DESC
) top3
ORDER BY c.CustomerID, top3.TotalAmount DESC;

-- Grading:
-- 12 points: CROSS APPLY used correctly
-- 8 points: TOP 3 with ORDER BY
-- 5 points: Correct correlation (WHERE CustomerID = c.CustomerID)

/*
Question 7.2 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    recent.OrderDate AS LastOrderDate,
    recent.TotalAmount AS LastOrderAmount
FROM Customers c
OUTER APPLY (
    SELECT TOP 1
        OrderDate,
        TotalAmount
    FROM Orders
    WHERE CustomerID = c.CustomerID
    ORDER BY OrderDate DESC
) recent
ORDER BY c.CustomerName;

-- Grading:
-- 12 points: OUTER APPLY used (includes all customers)
-- 8 points: TOP 1 with ORDER BY DESC
-- 5 points: Correct result (most recent order or NULL)

/*
Question 7.3 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    similar.ProductName AS SimilarProduct,
    similar.Price AS SimilarPrice
FROM Products p
CROSS APPLY (
    SELECT TOP 3
        ProductName,
        Price
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
      AND p2.ProductID <> p.ProductID
      AND ABS(p2.Price - p.Price) < 30
    ORDER BY ABS(p2.Price - p.Price)
) similar
WHERE p.ProductID <= 5
ORDER BY p.ProductID;

-- Grading:
-- 10 points: CROSS APPLY with TOP 3
-- 8 points: Correct filters (same category, different product, price < $30)
-- 7 points: ORDER BY price difference


/*
SECTION 8: COMPLEX SCENARIOS (100 BONUS points)
------------------------------------------------

Question 8.1 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalSpent,
    CASE 
        WHEN COUNT(o.OrderID) >= 10 THEN 'VIP'
        WHEN COUNT(o.OrderID) >= 5 THEN 'Regular'
        WHEN COUNT(o.OrderID) >= 1 THEN 'New'
        ELSE 'Inactive'
    END AS Segment
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY 
    CASE 
        WHEN COUNT(o.OrderID) >= 10 THEN 1
        WHEN COUNT(o.OrderID) >= 5 THEN 2
        WHEN COUNT(o.OrderID) >= 1 THEN 3
        ELSE 4
    END,
    TotalSpent DESC;

/*
Question 8.2 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    c.CustomerID,
    c.CustomerName,
    p.ProductID,
    p.ProductName,
    COUNT(*) AS PurchaseCount
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, p.ProductID, p.ProductName
HAVING COUNT(*) >= 2
ORDER BY PurchaseCount DESC;

/*
Question 8.3 (25 points):
*/
-- CORRECT SOLUTION:
WITH MonthlyOrders AS (
    SELECT 
        FORMAT(OrderDate, 'yyyy-MM') AS OrderMonth,
        COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY FORMAT(OrderDate, 'yyyy-MM')
)
SELECT 
    m1.OrderMonth,
    m1.OrderCount,
    m2.OrderCount AS PreviousMonthCount,
    CASE 
        WHEN m2.OrderCount IS NULL THEN NULL
        ELSE ROUND(((m1.OrderCount - m2.OrderCount) * 100.0 / m2.OrderCount), 2)
    END AS GrowthPercent
FROM MonthlyOrders m1
LEFT JOIN MonthlyOrders m2 
    ON m2.OrderMonth = FORMAT(DATEADD(MONTH, -1, CAST(m1.OrderMonth + '-01' AS DATE)), 'yyyy-MM')
ORDER BY m1.OrderMonth;

/*
Question 8.4 (25 points):
*/
-- CORRECT SOLUTION:
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    COUNT(DISTINCT od1.OrderID) AS TimesBoughtTogether
FROM OrderDetails od1
INNER JOIN OrderDetails od2 
    ON od1.OrderID = od2.OrderID
    AND od1.ProductID < od2.ProductID
INNER JOIN Products p1 ON od1.ProductID = p1.ProductID
INNER JOIN Products p2 ON od2.ProductID = p2.ProductID
GROUP BY p1.ProductName, p2.ProductName
ORDER BY TimesBoughtTogether DESC;


/*
============================================================================
SCORING SUMMARY
============================================================================

Section 1: JOIN Fundamentals................... 100 points
Section 2: Outer Joins and NULL Handling........ 75 points
Section 3: Join Conditions vs Filters........... 50 points
Section 4: Non-Equi Joins...................... 75 points
Section 5: Semi-Joins and Anti-Joins........... 75 points
Section 6: Performance and Optimization......... 50 points
Section 7: CROSS APPLY / OUTER APPLY............ 75 points
Section 8: Complex Scenarios (BONUS)........... 100 points
                                               ___________
TOTAL POSSIBLE:................................. 500 points
BONUS POSSIBLE:................................. 100 points

GRADING SCALE:
450-500 points (90%+): Excellent - Master level
400-449 points (80-89%): Very Good - Advanced level
350-399 points (70-79%): Good - Pass
300-349 points (60-69%): Fair - Review needed
Below 300 (< 60%): Needs significant review

============================================================================
SELF-ASSESSMENT CHECKLIST
============================================================================

After completing this test, you should be able to:

✓ Write queries with all join types (INNER, LEFT, RIGHT, FULL, CROSS)
✓ Understand when to use each join type
✓ Use ON vs WHERE clauses correctly
✓ Handle NULL values in outer joins
✓ Write non-equi joins (BETWEEN, <, >, etc.)
✓ Use EXISTS and NOT EXISTS for semi/anti-joins
✓ Avoid NOT IN with NULL issues
✓ Optimize join performance
✓ Read and analyze execution plans
✓ Use CROSS APPLY and OUTER APPLY
✓ Write complex multi-table joins
✓ Apply joins to real-world scenarios

If you scored below 70%, review:
• Lessons 10.01-10.06 for join fundamentals
• Lessons 10.07-10.08 for conditions and non-equi joins
• Lesson 10.09 for EXISTS/NOT EXISTS
• Lesson 10.10 for performance
• Lessons 10.11-10.12 for advanced techniques

============================================================================
*/
