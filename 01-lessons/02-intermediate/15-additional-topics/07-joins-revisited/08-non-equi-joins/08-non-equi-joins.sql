/*
============================================================================
Lesson 10.08 - Non-Equi Joins
============================================================================

Description:
Explore joins that use inequality operators instead of equality.
Master range-based joins, BETWEEN conditions, date ranges, and other
non-equi join patterns essential for real-world SQL applications.

Topics Covered:
• Non-equi join definition
• Inequality operators (<, >, <=, >=, <>)
• BETWEEN in joins
• Date and time range joins
• Price tier assignments
• Overlapping intervals

Prerequisites:
• Lessons 10.01-10.07
• Understanding of comparison operators

Estimated Time: 35 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Non-Equi Join Fundamentals
============================================================================
*/

-- Example 1.1: Basic non-equi join (inequality)
-- Find products cheaper than a reference product
SELECT 
    p1.ProductName AS ReferenceProduct,
    p1.Price AS ReferencePrice,
    p2.ProductName AS CheaperProduct,
    p2.Price AS CheaperPrice
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID  -- Same category
    AND p2.Price < p1.Price            -- Non-equi condition
WHERE p1.ProductID = 1
ORDER BY p2.Price DESC;

/*
Execution Flow:
1. Take product 1
2. Find all products in same category
3. Filter to only cheaper products
4. Return with price comparison
*/

-- Example 1.2: Not equal (<>)
-- Find product pairs from the same category
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    p1.CategoryID
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.ProductID <> p2.ProductID  -- Different products
    AND p1.ProductID < p2.ProductID   -- Avoid duplicates (A-B vs B-A)
ORDER BY p1.CategoryID, p1.ProductName;

-- Example 1.3: Multiple inequality conditions
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS SimilarPricedProduct,
    p2.Price AS Price2,
    ABS(p1.Price - p2.Price) AS PriceDifference
FROM Products p1
INNER JOIN Products p2 
    ON p1.ProductID <> p2.ProductID
    AND p2.Price >= p1.Price * 0.9   -- Within 10% lower
    AND p2.Price <= p1.Price * 1.1   -- Within 10% higher
WHERE p1.ProductID = 1
ORDER BY PriceDifference;


/*
============================================================================
PART 2: BETWEEN in Joins
============================================================================
*/

-- Example 2.1: Price tier assignment
-- Create price tiers
CREATE TABLE #PriceTiers (
    TierID INT PRIMARY KEY,
    TierName VARCHAR(50),
    MinPrice DECIMAL(10,2),
    MaxPrice DECIMAL(10,2),
    DiscountPercent DECIMAL(5,2)
);

INSERT INTO #PriceTiers VALUES
(1, 'Budget', 0.00, 49.99, 5.00),
(2, 'Standard', 50.00, 99.99, 10.00),
(3, 'Premium', 100.00, 199.99, 15.00),
(4, 'Luxury', 200.00, 999999.99, 20.00);

-- Assign products to price tiers
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price,
    t.TierName,
    t.DiscountPercent,
    ROUND(p.Price * (1 - t.DiscountPercent/100), 2) AS DiscountedPrice
FROM Products p
INNER JOIN #PriceTiers t 
    ON p.Price BETWEEN t.MinPrice AND t.MaxPrice
ORDER BY p.Price;

-- Example 2.2: Age group classification
CREATE TABLE #AgeGroups (
    GroupID INT,
    GroupName VARCHAR(50),
    MinAge INT,
    MaxAge INT
);

INSERT INTO #AgeGroups VALUES
(1, 'Youth', 0, 17),
(2, 'Young Adult', 18, 35),
(3, 'Middle Age', 36, 55),
(4, 'Senior', 56, 120);

-- If you had a Customers table with age:
/*
SELECT 
    c.CustomerName,
    c.Age,
    ag.GroupName
FROM Customers c
INNER JOIN #AgeGroups ag 
    ON c.Age BETWEEN ag.MinAge AND ag.MaxAge;
*/

-- Example 2.3: Commission tiers based on sales
CREATE TABLE #CommissionTiers (
    TierID INT,
    MinSales DECIMAL(10,2),
    MaxSales DECIMAL(10,2),
    CommissionRate DECIMAL(5,2)
);

INSERT INTO #CommissionTiers VALUES
(1, 0, 1000, 2.00),
(2, 1000.01, 5000, 3.50),
(3, 5000.01, 10000, 5.00),
(4, 10000.01, 999999, 7.00);

-- Calculate commission per order
SELECT 
    o.OrderID,
    o.TotalAmount,
    ct.CommissionRate,
    ROUND(o.TotalAmount * ct.CommissionRate / 100, 2) AS Commission
FROM Orders o
INNER JOIN #CommissionTiers ct 
    ON o.TotalAmount BETWEEN ct.MinSales AND ct.MaxSales
ORDER BY o.TotalAmount;


/*
============================================================================
PART 3: Date and Time Range Joins
============================================================================
*/

-- Example 3.1: Find orders within date ranges
CREATE TABLE #DateRanges (
    RangeID INT,
    RangeName VARCHAR(50),
    StartDate DATE,
    EndDate DATE
);

INSERT INTO #DateRanges VALUES
(1, 'Q1 2024', '2024-01-01', '2024-03-31'),
(2, 'Q2 2024', '2024-04-01', '2024-06-30'),
(3, 'Q3 2024', '2024-07-01', '2024-09-30'),
(4, 'Q4 2024', '2024-10-01', '2024-12-31');

SELECT 
    dr.RangeName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM #DateRanges dr
LEFT JOIN Orders o 
    ON o.OrderDate BETWEEN dr.StartDate AND dr.EndDate
ORDER BY dr.RangeID, o.OrderDate;

-- Example 3.2: Overlapping date ranges
CREATE TABLE #Promotions (
    PromotionID INT,
    PromotionName VARCHAR(50),
    StartDate DATE,
    EndDate DATE
);

INSERT INTO #Promotions VALUES
(1, 'New Year Sale', '2024-01-01', '2024-01-15'),
(2, 'Valentine Special', '2024-02-10', '2024-02-14'),
(3, 'Spring Sale', '2024-03-01', '2024-03-31');

-- Find orders during promotions
SELECT 
    p.PromotionName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders o
INNER JOIN #Promotions p 
    ON o.OrderDate BETWEEN p.StartDate AND p.EndDate
ORDER BY o.OrderDate;

-- Example 3.3: Time-based matching
-- Orders placed within 1 hour of each other
SELECT 
    o1.OrderID AS Order1,
    o1.OrderDate AS Time1,
    o2.OrderID AS Order2,
    o2.OrderDate AS Time2,
    DATEDIFF(MINUTE, o1.OrderDate, o2.OrderDate) AS MinutesBetween
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.OrderID < o2.OrderID
    AND o2.OrderDate > o1.OrderDate
    AND DATEDIFF(MINUTE, o1.OrderDate, o2.OrderDate) <= 60
ORDER BY o1.OrderDate;


/*
============================================================================
PART 4: Self-Joins with Inequality
============================================================================
*/

-- Example 4.1: Find next order per customer
SELECT 
    o1.OrderID AS CurrentOrder,
    o1.OrderDate AS CurrentDate,
    o1.TotalAmount AS CurrentAmount,
    MIN(o2.OrderID) AS NextOrder,
    MIN(o2.OrderDate) AS NextDate,
    MIN(o2.TotalAmount) AS NextAmount
FROM Orders o1
LEFT JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate > o1.OrderDate
WHERE o1.CustomerID = 1
GROUP BY o1.OrderID, o1.OrderDate, o1.TotalAmount
ORDER BY o1.OrderDate;

-- Example 4.2: Running comparisons
-- Each order compared to all previous orders
SELECT 
    o1.OrderID AS CurrentOrder,
    o1.OrderDate,
    o1.TotalAmount AS CurrentAmount,
    COUNT(o2.OrderID) AS PreviousOrders,
    AVG(o2.TotalAmount) AS AvgPreviousAmount,
    CASE 
        WHEN o1.TotalAmount > AVG(o2.TotalAmount) THEN 'Above Average'
        ELSE 'Below Average'
    END AS Comparison
FROM Orders o1
LEFT JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate < o1.OrderDate
WHERE o1.CustomerID = 1
GROUP BY o1.OrderID, o1.OrderDate, o1.TotalAmount
ORDER BY o1.OrderDate;

-- Example 4.3: Product price rankings within category
SELECT 
    p1.ProductID,
    p1.ProductName,
    p1.CategoryID,
    p1.Price,
    COUNT(p2.ProductID) + 1 AS PriceRank
FROM Products p1
LEFT JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p2.Price > p1.Price
GROUP BY p1.ProductID, p1.ProductName, p1.CategoryID, p1.Price
ORDER BY p1.CategoryID, PriceRank;


/*
============================================================================
PART 5: Range-Based Business Logic
============================================================================
*/

-- Example 5.1: Customer loyalty tiers
CREATE TABLE #LoyaltyTiers (
    TierID INT,
    TierName VARCHAR(50),
    MinOrders INT,
    MaxOrders INT,
    BenefitDescription VARCHAR(100)
);

INSERT INTO #LoyaltyTiers VALUES
(1, 'Bronze', 0, 5, '5% discount'),
(2, 'Silver', 6, 15, '10% discount + free shipping'),
(3, 'Gold', 16, 30, '15% discount + priority support'),
(4, 'Platinum', 31, 999999, '20% discount + VIP perks');

-- Classify customers by order count
WITH CustomerOrderCounts AS (
    SELECT 
        CustomerID,
        COUNT(*) AS OrderCount
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    c.CustomerID,
    c.CustomerName,
    coc.OrderCount,
    lt.TierName,
    lt.BenefitDescription
FROM Customers c
INNER JOIN CustomerOrderCounts coc ON c.CustomerID = coc.CustomerID
INNER JOIN #LoyaltyTiers lt 
    ON coc.OrderCount BETWEEN lt.MinOrders AND lt.MaxOrders
ORDER BY coc.OrderCount DESC;

-- Example 5.2: Shipping cost calculation
CREATE TABLE #ShippingRates (
    RateID INT,
    MinWeight DECIMAL(10,2),
    MaxWeight DECIMAL(10,2),
    CostPerKg DECIMAL(10,2)
);

INSERT INTO #ShippingRates VALUES
(1, 0, 1, 5.00),
(2, 1.01, 5, 3.50),
(3, 5.01, 20, 2.50),
(4, 20.01, 999999, 1.50);

-- If you had OrderWeight column:
/*
SELECT 
    o.OrderID,
    o.OrderWeight,
    sr.CostPerKg,
    ROUND(o.OrderWeight * sr.CostPerKg, 2) AS ShippingCost
FROM Orders o
INNER JOIN #ShippingRates sr 
    ON o.OrderWeight BETWEEN sr.MinWeight AND sr.MaxWeight;
*/

-- Example 5.3: Dynamic pricing based on order size
CREATE TABLE #VolumeDiscounts (
    DiscountID INT,
    MinQuantity INT,
    MaxQuantity INT,
    DiscountPercent DECIMAL(5,2)
);

INSERT INTO #VolumeDiscounts VALUES
(1, 1, 10, 0),
(2, 11, 50, 5),
(3, 51, 100, 10),
(4, 101, 999999, 15);

-- Calculate discounts (conceptual - would need quantity data)
/*
SELECT 
    od.OrderDetailID,
    od.Quantity,
    vd.DiscountPercent,
    od.UnitPrice AS OriginalPrice,
    ROUND(od.UnitPrice * (1 - vd.DiscountPercent/100), 2) AS DiscountedPrice
FROM OrderDetails od
INNER JOIN #VolumeDiscounts vd 
    ON od.Quantity BETWEEN vd.MinQuantity AND vd.MaxQuantity;
*/


/*
============================================================================
PART 6: Overlapping Intervals
============================================================================
*/

-- Example 6.1: Find overlapping events
CREATE TABLE #Events (
    EventID INT,
    EventName VARCHAR(50),
    StartTime DATETIME,
    EndTime DATETIME
);

INSERT INTO #Events VALUES
(1, 'Meeting A', '2024-06-01 09:00', '2024-06-01 10:30'),
(2, 'Meeting B', '2024-06-01 10:00', '2024-06-01 11:00'),
(3, 'Meeting C', '2024-06-01 11:00', '2024-06-01 12:00'),
(4, 'Meeting D', '2024-06-01 14:00', '2024-06-01 15:00');

-- Find conflicting meetings
SELECT 
    e1.EventName AS Event1,
    e1.StartTime AS Start1,
    e1.EndTime AS End1,
    e2.EventName AS Event2,
    e2.StartTime AS Start2,
    e2.EndTime AS End2
FROM #Events e1
INNER JOIN #Events e2 
    ON e1.EventID < e2.EventID
    AND e1.StartTime < e2.EndTime
    AND e2.StartTime < e1.EndTime;

-- Example 6.2: Project resource conflicts
CREATE TABLE #ProjectAssignments (
    AssignmentID INT,
    EmployeeID INT,
    ProjectName VARCHAR(50),
    StartDate DATE,
    EndDate DATE
);

INSERT INTO #ProjectAssignments VALUES
(1, 101, 'Project Alpha', '2024-01-01', '2024-03-31'),
(2, 101, 'Project Beta', '2024-03-15', '2024-06-30'),
(3, 101, 'Project Gamma', '2024-07-01', '2024-09-30'),
(4, 102, 'Project Delta', '2024-02-01', '2024-04-30');

-- Find overlapping assignments per employee
SELECT 
    pa1.EmployeeID,
    pa1.ProjectName AS Project1,
    pa1.StartDate AS Start1,
    pa1.EndDate AS End1,
    pa2.ProjectName AS Project2,
    pa2.StartDate AS Start2,
    pa2.EndDate AS End2,
    DATEDIFF(DAY, 
        CASE WHEN pa1.StartDate > pa2.StartDate THEN pa1.StartDate ELSE pa2.StartDate END,
        CASE WHEN pa1.EndDate < pa2.EndDate THEN pa1.EndDate ELSE pa2.EndDate END
    ) + 1 AS OverlapDays
FROM #ProjectAssignments pa1
INNER JOIN #ProjectAssignments pa2 
    ON pa1.EmployeeID = pa2.EmployeeID
    AND pa1.AssignmentID < pa2.AssignmentID
    AND pa1.StartDate <= pa2.EndDate
    AND pa2.StartDate <= pa1.EndDate;


/*
============================================================================
PART 7: Advanced Non-Equi Patterns
============================================================================
*/

-- Example 7.1: Triangular joins (all combinations where A < B < C)
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2,
    p3.ProductName AS Product3
FROM Products p1
INNER JOIN Products p2 ON p1.ProductID < p2.ProductID
INNER JOIN Products p3 ON p2.ProductID < p3.ProductID
WHERE p1.CategoryID = p2.CategoryID 
  AND p2.CategoryID = p3.CategoryID
  AND p1.ProductID <= 3;  -- Limit results

-- Example 7.2: Price gap analysis
SELECT 
    p1.ProductID,
    p1.ProductName,
    p1.Price,
    MIN(p2.Price) AS NextHigherPrice,
    MIN(p2.Price) - p1.Price AS PriceGap
FROM Products p1
LEFT JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p2.Price > p1.Price
GROUP BY p1.ProductID, p1.ProductName, p1.Price
ORDER BY p1.CategoryID, p1.Price;

-- Example 7.3: Cumulative aggregations
SELECT 
    o1.OrderID,
    o1.OrderDate,
    o1.TotalAmount,
    SUM(o2.TotalAmount) AS RunningTotal,
    AVG(o2.TotalAmount) AS RunningAverage
FROM Orders o1
INNER JOIN Orders o2 
    ON o2.OrderDate <= o1.OrderDate
    AND o2.CustomerID = o1.CustomerID
WHERE o1.CustomerID = 1
GROUP BY o1.OrderID, o1.OrderDate, o1.TotalAmount
ORDER BY o1.OrderDate;

-- Example 7.4: Find gaps in sequences
WITH NumberedOrders AS (
    SELECT 
        OrderID,
        OrderDate,
        ROW_NUMBER() OVER (ORDER BY OrderDate) AS RowNum
    FROM Orders
    WHERE CustomerID = 1
)
SELECT 
    o1.OrderID AS Order1,
    o1.OrderDate AS Date1,
    o2.OrderID AS Order2,
    o2.OrderDate AS Date2,
    DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DayGap
FROM NumberedOrders o1
INNER JOIN NumberedOrders o2 
    ON o1.RowNum + 1 = o2.RowNum
WHERE DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) > 30;


/*
============================================================================
PART 8: Performance Considerations
============================================================================
*/

-- Performance 8.1: ⚠️ Non-equi joins can be slow
-- Without proper indexing, this scans all combinations:
SELECT COUNT(*)
FROM Products p1
INNER JOIN Products p2 
    ON p2.Price > p1.Price;
-- Result: Can be slow on large tables

-- Performance 8.2: ✅ Add filters to reduce combinations
SELECT COUNT(*)
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID  -- Equi condition first
    AND p2.Price > p1.Price           -- Then non-equi
WHERE p1.ProductID <= 10;              -- Limit scope

-- Performance 8.3: ✅ Use BETWEEN when possible
-- Better:
SELECT * FROM Orders o
INNER JOIN #PriceTiers pt 
    ON o.TotalAmount BETWEEN pt.MinPrice AND pt.MaxPrice;

-- Slower:
SELECT * FROM Orders o
INNER JOIN #PriceTiers pt 
    ON o.TotalAmount >= pt.MinPrice
    AND o.TotalAmount < pt.MaxPrice;


-- Clean up
DROP TABLE #PriceTiers;
DROP TABLE #AgeGroups;
DROP TABLE #CommissionTiers;
DROP TABLE #DateRanges;
DROP TABLE #Promotions;
DROP TABLE #LoyaltyTiers;
DROP TABLE #ShippingRates;
DROP TABLE #VolumeDiscounts;
DROP TABLE #Events;
DROP TABLE #ProjectAssignments;


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Create a table of salary ranges and assign employees to ranges
2. Find all product pairs where price difference is between $5 and $20
3. Identify orders placed on consecutive days by the same customer
4. Create a commission structure and calculate commission for each order
5. Find overlapping date ranges in a promotions table

Solutions below ↓
*/

-- Solution 1:
CREATE TABLE #Ex1Ranges (
    RangeID INT,
    RangeName VARCHAR(20),
    MinSalary DECIMAL(10,2),
    MaxSalary DECIMAL(10,2)
);
INSERT INTO #Ex1Ranges VALUES
(1, 'Entry', 0, 40000),
(2, 'Mid', 40000.01, 70000),
(3, 'Senior', 70000.01, 100000),
(4, 'Executive', 100000.01, 999999);

-- Would need Employee table with Salary column:
/*
SELECT 
    e.EmployeeName,
    e.Salary,
    r.RangeName
FROM Employees e
INNER JOIN #Ex1Ranges r ON e.Salary BETWEEN r.MinSalary AND r.MaxSalary;
*/

DROP TABLE #Ex1Ranges;

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
    AND ABS(p1.Price - p2.Price) BETWEEN 5 AND 20
ORDER BY Difference;

-- Solution 3:
SELECT 
    o1.CustomerID,
    o1.OrderID AS Order1,
    o1.OrderDate AS Date1,
    o2.OrderID AS Order2,
    o2.OrderDate AS Date2
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o1.OrderID < o2.OrderID
    AND DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) = 1
ORDER BY o1.CustomerID, o1.OrderDate;

-- Solution 4:
CREATE TABLE #Ex4Commission (
    MinAmount DECIMAL(10,2),
    MaxAmount DECIMAL(10,2),
    Rate DECIMAL(5,2)
);
INSERT INTO #Ex4Commission VALUES
(0, 500, 1.0),
(500.01, 1000, 2.5),
(1000.01, 999999, 5.0);

SELECT 
    o.OrderID,
    o.TotalAmount,
    c.Rate,
    ROUND(o.TotalAmount * c.Rate / 100, 2) AS Commission
FROM Orders o
INNER JOIN #Ex4Commission c 
    ON o.TotalAmount BETWEEN c.MinAmount AND c.MaxAmount
ORDER BY o.TotalAmount;

DROP TABLE #Ex4Commission;

-- Solution 5:
CREATE TABLE #Ex5Promos (
    PromoID INT,
    PromoName VARCHAR(50),
    StartDate DATE,
    EndDate DATE
);
INSERT INTO #Ex5Promos VALUES
(1, 'New Year', '2024-01-01', '2024-01-15'),
(2, 'Winter', '2024-01-10', '2024-02-28'),
(3, 'Spring', '2024-03-01', '2024-05-31');

SELECT 
    p1.PromoName AS Promo1,
    p1.StartDate AS Start1,
    p1.EndDate AS End1,
    p2.PromoName AS Promo2,
    p2.StartDate AS Start2,
    p2.EndDate AS End2
FROM #Ex5Promos p1
INNER JOIN #Ex5Promos p2 
    ON p1.PromoID < p2.PromoID
    AND p1.StartDate <= p2.EndDate
    AND p2.StartDate <= p1.EndDate;

DROP TABLE #Ex5Promos;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ NON-EQUI JOINS:
  • Use inequality operators: <, >, <=, >=, <>
  • Not based on equality (=)
  • Common for ranges and comparisons
  • Often slower than equi-joins

✓ BETWEEN PATTERN:
  • Perfect for range assignments
  • Price tiers, age groups, date ranges
  • Clean, readable syntax
  • ON value BETWEEN min AND max

✓ COMMON USE CASES:
  • Price tier classification
  • Commission calculations
  • Date range matching
  • Overlapping intervals
  • Sequential analysis
  • Ranking and comparisons

✓ DATE RANGES:
  • BETWEEN for inclusive ranges
  • Overlaps: start1 <= end2 AND start2 <= end1
  • Gaps: Large DATEDIFF values
  • Consecutive: DATEDIFF = 1

✓ SELF-JOIN PATTERNS:
  • Next/previous row: date > current
  • Running calculations: date <= current
  • Rankings: COUNT(higher values)
  • Gaps: Missing sequences

✓ PERFORMANCE:
  • Non-equi joins can be expensive
  • Add equi conditions when possible
  • Filter early with WHERE
  • Index appropriately
  • BETWEEN often better than >= AND <

✓ BEST PRACTICES:
  • Combine with equi conditions
  • Use BETWEEN for readability
  • Add filters to limit scope
  • Test performance on large data
  • Consider indexes on range columns
  • Document complex logic

✓ WATCH OUT FOR:
  • Cartesian product potential
  • Large result sets
  • Missing indexes
  • Overlapping ranges (multiple matches)
  • NULL handling in ranges
  • Exclusive vs inclusive boundaries

============================================================================
NEXT: Lesson 10.09 - Semi-Joins and Anti-Joins
Learn efficient patterns for existence and non-existence checks.
============================================================================
*/
