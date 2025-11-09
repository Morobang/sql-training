/*
============================================================================
Lesson 10.03 - Self-Joins
============================================================================

Description:
Master the art of joining a table to itself. Learn to compare rows,
find relationships within the same table, handle hierarchical data,
and solve complex analytical problems using self-joins.

Topics Covered:
• Self-join fundamentals
• Comparing rows within a table
• Hierarchical relationships
• Finding duplicates
• Sequence and range analysis
• Performance considerations

Prerequisites:
• Lessons 10.01-10.02
• Understanding of table aliases

Estimated Time: 30 minutes
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
PART 1: Self-Join Fundamentals
============================================================================
*/

-- Example 1.1: Basic self-join concept
-- Find products in the same category
SELECT 
    p1.ProductID AS Product1ID,
    p1.ProductName AS Product1,
    p2.ProductID AS Product2ID,
    p2.ProductName AS Product2,
    p1.CategoryID
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID  -- Same category
    AND p1.ProductID < p2.ProductID;   -- Avoid duplicates

/*
Key points:
• Same table referenced twice with different aliases (p1, p2)
• Join condition relates rows within same table
• Additional condition (p1.ProductID < p2.ProductID) avoids:
  - Self-matching (product to itself)
  - Duplicate pairs (A-B and B-A)
*/

-- Example 1.2: Find products with similar prices
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    ABS(p1.Price - p2.Price) AS PriceDifference
FROM Products p1
INNER JOIN Products p2 
    ON p1.ProductID <> p2.ProductID  -- Different products
    AND ABS(p1.Price - p2.Price) < 10  -- Within $10
ORDER BY PriceDifference;

-- Example 1.3: Find all product pairs
SELECT 
    p1.ProductName AS Product1,
    p2.ProductName AS Product2
FROM Products p1
CROSS JOIN Products p2
WHERE p1.ProductID < p2.ProductID
ORDER BY p1.ProductName, p2.ProductName;


/*
============================================================================
PART 2: Comparing Rows
============================================================================
*/

-- Example 2.1: Compare orders by same customer
SELECT 
    c.CustomerName,
    o1.OrderID AS Order1,
    o1.OrderDate AS Date1,
    o1.TotalAmount AS Amount1,
    o2.OrderID AS Order2,
    o2.OrderDate AS Date2,
    o2.TotalAmount AS Amount2,
    DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DaysBetween
FROM Customers c
INNER JOIN Orders o1 ON c.CustomerID = o1.CustomerID
INNER JOIN Orders o2 
    ON c.CustomerID = o2.CustomerID
    AND o1.OrderID < o2.OrderID  -- Avoid duplicates
WHERE c.CustomerID = 1
ORDER BY o1.OrderDate, o2.OrderDate;

-- Example 2.2: Find consecutive orders
SELECT 
    o1.OrderID AS CurrentOrder,
    o1.OrderDate AS CurrentDate,
    o1.TotalAmount AS CurrentAmount,
    o2.OrderID AS NextOrder,
    o2.OrderDate AS NextDate,
    o2.TotalAmount AS NextAmount,
    o2.TotalAmount - o1.TotalAmount AS AmountChange
FROM Orders o1
LEFT JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate = (
        SELECT MIN(OrderDate)
        FROM Orders
        WHERE CustomerID = o1.CustomerID
        AND OrderDate > o1.OrderDate
    )
WHERE o1.CustomerID = 1
ORDER BY o1.OrderDate;

-- Example 2.3: Compare products within price ranges
SELECT 
    p1.ProductName AS LowerPriced,
    p1.Price AS Price1,
    p2.ProductName AS HigherPriced,
    p2.Price AS Price2
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.Price < p2.Price
    AND p2.Price - p1.Price < 50
ORDER BY p1.Price, p2.Price;


/*
============================================================================
PART 3: Hierarchical Data (Parent-Child Relationships)
============================================================================
*/

-- Example 3.1: Simulated employee hierarchy
CREATE TABLE #Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(50),
    ManagerID INT,
    Title VARCHAR(50),
    Salary DECIMAL(10,2)
);

INSERT INTO #Employees VALUES
(1, 'Alice Johnson', NULL, 'CEO', 150000),
(2, 'Bob Smith', 1, 'VP Sales', 120000),
(3, 'Charlie Brown', 1, 'VP Tech', 120000),
(4, 'David Lee', 2, 'Sales Manager', 90000),
(5, 'Eve Davis', 2, 'Sales Manager', 90000),
(6, 'Frank Wilson', 3, 'Dev Manager', 95000),
(7, 'Grace Miller', 4, 'Sales Rep', 60000),
(8, 'Henry Taylor', 4, 'Sales Rep', 60000),
(9, 'Iris Anderson', 6, 'Developer', 75000),
(10, 'Jack Thomas', 6, 'Developer', 75000);

-- Self-join to show employee and their manager
SELECT 
    e.EmployeeID,
    e.EmployeeName AS Employee,
    e.Title AS EmployeeTitle,
    m.EmployeeName AS Manager,
    m.Title AS ManagerTitle
FROM #Employees e
LEFT JOIN #Employees m ON e.ManagerID = m.EmployeeID
ORDER BY e.EmployeeID;

-- Example 3.2: Find all direct reports for each manager
SELECT 
    m.EmployeeName AS Manager,
    COUNT(e.EmployeeID) AS DirectReports,
    STRING_AGG(e.EmployeeName, ', ') AS Employees
FROM #Employees m
LEFT JOIN #Employees e ON m.EmployeeID = e.ManagerID
GROUP BY m.EmployeeID, m.EmployeeName
HAVING COUNT(e.EmployeeID) > 0
ORDER BY DirectReports DESC;

-- Example 3.3: Compare employee salaries to their manager
SELECT 
    e.EmployeeName AS Employee,
    e.Salary AS EmployeeSalary,
    m.EmployeeName AS Manager,
    m.Salary AS ManagerSalary,
    m.Salary - e.Salary AS SalaryDifference,
    (e.Salary * 100.0 / m.Salary) AS PercentOfManager
FROM #Employees e
INNER JOIN #Employees m ON e.ManagerID = m.EmployeeID
ORDER BY e.Salary DESC;

-- Example 3.4: Find employees at same level (same manager)
SELECT 
    e1.EmployeeName AS Employee1,
    e2.EmployeeName AS Employee2,
    m.EmployeeName AS CommonManager,
    e1.Title,
    e1.Salary AS Salary1,
    e2.Salary AS Salary2
FROM #Employees e1
INNER JOIN #Employees e2 
    ON e1.ManagerID = e2.ManagerID
    AND e1.EmployeeID < e2.EmployeeID
INNER JOIN #Employees m ON e1.ManagerID = m.EmployeeID
ORDER BY m.EmployeeName, e1.EmployeeName;

DROP TABLE #Employees;


/*
============================================================================
PART 4: Finding Duplicates
============================================================================
*/

-- Example 4.1: Find duplicate product names
SELECT 
    p1.ProductID AS ID1,
    p2.ProductID AS ID2,
    p1.ProductName,
    p1.Price AS Price1,
    p2.Price AS Price2
FROM Products p1
INNER JOIN Products p2 
    ON p1.ProductName = p2.ProductName
    AND p1.ProductID < p2.ProductID;

-- Example 4.2: Find customers with similar names
SELECT 
    c1.CustomerID AS ID1,
    c1.CustomerName AS Name1,
    c2.CustomerID AS ID2,
    c2.CustomerName AS Name2
FROM Customers c1
INNER JOIN Customers c2 
    ON SOUNDEX(c1.CustomerName) = SOUNDEX(c2.CustomerName)
    AND c1.CustomerID < c2.CustomerID;

-- Example 4.3: Find orders on same date by same customer
SELECT 
    c.CustomerName,
    o1.OrderID AS Order1,
    o2.OrderID AS Order2,
    o1.OrderDate,
    o1.TotalAmount AS Amount1,
    o2.TotalAmount AS Amount2
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND CAST(o1.OrderDate AS DATE) = CAST(o2.OrderDate AS DATE)
    AND o1.OrderID < o2.OrderID
INNER JOIN Customers c ON o1.CustomerID = c.CustomerID;


/*
============================================================================
PART 5: Sequence and Range Analysis
============================================================================
*/

-- Example 5.1: Find gaps in order sequence
SELECT 
    o1.OrderID AS CurrentOrder,
    o2.OrderID AS NextOrder,
    o2.OrderID - o1.OrderID - 1 AS GapSize
FROM Orders o1
LEFT JOIN Orders o2 
    ON o2.OrderID = (
        SELECT MIN(OrderID)
        FROM Orders
        WHERE OrderID > o1.OrderID
    )
WHERE o2.OrderID - o1.OrderID > 1
ORDER BY o1.OrderID;

-- Example 5.2: Find overlapping date ranges
-- Create sample date ranges
CREATE TABLE #Promotions (
    PromotionID INT,
    PromotionName VARCHAR(50),
    StartDate DATE,
    EndDate DATE
);

INSERT INTO #Promotions VALUES
(1, 'Summer Sale', '2024-06-01', '2024-06-30'),
(2, 'Mid-Year Clearance', '2024-06-15', '2024-07-15'),
(3, 'Independence Day', '2024-07-01', '2024-07-07'),
(4, 'Back to School', '2024-08-01', '2024-08-31');

-- Find overlapping promotions
SELECT 
    p1.PromotionName AS Promotion1,
    p1.StartDate AS Start1,
    p1.EndDate AS End1,
    p2.PromotionName AS Promotion2,
    p2.StartDate AS Start2,
    p2.EndDate AS End2,
    CASE 
        WHEN p1.StartDate <= p2.StartDate THEN p2.StartDate
        ELSE p1.StartDate
    END AS OverlapStart,
    CASE 
        WHEN p1.EndDate <= p2.EndDate THEN p1.EndDate
        ELSE p2.EndDate
    END AS OverlapEnd
FROM #Promotions p1
INNER JOIN #Promotions p2 
    ON p1.PromotionID < p2.PromotionID
    AND p1.StartDate <= p2.EndDate
    AND p2.StartDate <= p1.EndDate;

DROP TABLE #Promotions;

-- Example 5.3: Find orders within 30 days of each other
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
    AND o2.OrderDate <= DATEADD(DAY, 30, o1.OrderDate)
WHERE o1.CustomerID = 1
ORDER BY o1.OrderDate, o2.OrderDate;


/*
============================================================================
PART 6: Advanced Self-Join Patterns
============================================================================
*/

-- Pattern 6.1: Running comparison (vs previous row)
SELECT 
    o1.OrderID,
    o1.OrderDate,
    o1.TotalAmount,
    o2.OrderID AS PrevOrderID,
    o2.TotalAmount AS PrevAmount,
    o1.TotalAmount - ISNULL(o2.TotalAmount, 0) AS AmountChange,
    CASE 
        WHEN o2.TotalAmount IS NULL THEN 'First Order'
        WHEN o1.TotalAmount > o2.TotalAmount THEN 'Increased'
        WHEN o1.TotalAmount < o2.TotalAmount THEN 'Decreased'
        ELSE 'Same'
    END AS Trend
FROM Orders o1
LEFT JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND o2.OrderDate = (
        SELECT MAX(OrderDate)
        FROM Orders
        WHERE CustomerID = o1.CustomerID
        AND OrderDate < o1.OrderDate
    )
WHERE o1.CustomerID = 1
ORDER BY o1.OrderDate;

-- Pattern 6.2: Find "sandwich" patterns (A-B-A)
-- Products ordered, then not ordered, then ordered again
WITH ProductOrders AS (
    SELECT DISTINCT
        od.ProductID,
        CAST(o.OrderDate AS DATE) AS OrderDate
    FROM OrderDetails od
    JOIN Orders o ON od.OrderID = o.OrderID
)
SELECT DISTINCT
    po1.ProductID,
    p.ProductName,
    po1.OrderDate AS FirstOrder,
    po2.OrderDate AS LastOrder,
    DATEDIFF(DAY, po1.OrderDate, po2.OrderDate) AS DaysGap
FROM ProductOrders po1
INNER JOIN ProductOrders po2 
    ON po1.ProductID = po2.ProductID
    AND po2.OrderDate > po1.OrderDate
WHERE NOT EXISTS (
    SELECT 1
    FROM ProductOrders po3
    WHERE po3.ProductID = po1.ProductID
    AND po3.OrderDate > po1.OrderDate
    AND po3.OrderDate < po2.OrderDate
)
AND DATEDIFF(DAY, po1.OrderDate, po2.OrderDate) > 30;

-- Pattern 6.3: Rank items against each other
SELECT 
    p1.ProductName,
    p1.Price,
    COUNT(p2.ProductID) + 1 AS PriceRank
FROM Products p1
LEFT JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p2.Price > p1.Price
WHERE p1.CategoryID = 1
GROUP BY p1.ProductID, p1.ProductName, p1.Price
ORDER BY PriceRank;


/*
============================================================================
PART 7: Performance Considerations
============================================================================
*/

-- Performance 7.1: ⚠️ Self-joins can be expensive
-- Careful with large tables!
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT p1.ProductName, p2.ProductName
FROM Products p1
CROSS JOIN Products p2  -- Creates N² rows!
WHERE p1.ProductID < p2.ProductID;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Performance 7.2: ✅ Use indexes on join columns
/*
CREATE INDEX IX_Orders_CustomerID_OrderDate 
ON Orders(CustomerID, OrderDate);

CREATE INDEX IX_Products_CategoryID_Price 
ON Products(CategoryID, Price);
*/

-- Performance 7.3: ✅ Limit self-join scope
-- Bad (compares ALL orders to ALL orders):
-- SELECT * FROM Orders o1 JOIN Orders o2 ON o1.CustomerID = o2.CustomerID;

-- Good (limit to specific customer or date range):
SELECT *
FROM Orders o1
JOIN Orders o2 ON o1.CustomerID = o2.CustomerID
WHERE o1.CustomerID = 1
  AND o1.OrderDate >= '2024-01-01';


/*
============================================================================
PRACTICE EXERCISES
============================================================================

1. Find all products that have the same price
2. List customers who placed orders on consecutive days
3. Find products in the same category with price difference < $20
4. Identify gaps in product IDs (missing IDs in sequence)
5. Compare each order to the customer's average order amount

Solutions below ↓
*/

-- Solution 1:
SELECT 
    p1.ProductID AS ID1,
    p1.ProductName AS Product1,
    p2.ProductID AS ID2,
    p2.ProductName AS Product2,
    p1.Price
FROM Products p1
INNER JOIN Products p2 
    ON p1.Price = p2.Price
    AND p1.ProductID < p2.ProductID
ORDER BY p1.Price, p1.ProductName;

-- Solution 2:
SELECT DISTINCT
    c.CustomerName,
    o1.OrderDate AS Day1,
    o2.OrderDate AS Day2
FROM Orders o1
INNER JOIN Orders o2 
    ON o1.CustomerID = o2.CustomerID
    AND CAST(o2.OrderDate AS DATE) = DATEADD(DAY, 1, CAST(o1.OrderDate AS DATE))
INNER JOIN Customers c ON o1.CustomerID = c.CustomerID
ORDER BY c.CustomerName, o1.OrderDate;

-- Solution 3:
SELECT 
    p1.ProductName AS Product1,
    p1.Price AS Price1,
    p2.ProductName AS Product2,
    p2.Price AS Price2,
    ABS(p1.Price - p2.Price) AS Difference
FROM Products p1
INNER JOIN Products p2 
    ON p1.CategoryID = p2.CategoryID
    AND p1.ProductID < p2.ProductID
    AND ABS(p1.Price - p2.Price) < 20
ORDER BY Difference;

-- Solution 4:
SELECT 
    p1.ProductID AS CurrentID,
    p2.ProductID AS NextID,
    p2.ProductID - p1.ProductID - 1 AS GapSize
FROM Products p1
LEFT JOIN Products p2 
    ON p2.ProductID = (
        SELECT MIN(ProductID)
        FROM Products
        WHERE ProductID > p1.ProductID
    )
WHERE p2.ProductID - p1.ProductID > 1
ORDER BY p1.ProductID;

-- Solution 5:
WITH CustomerAverages AS (
    SELECT 
        CustomerID,
        AVG(TotalAmount) AS AvgAmount
    FROM Orders
    GROUP BY CustomerID
)
SELECT 
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    ca.AvgAmount AS CustomerAvg,
    o.TotalAmount - ca.AvgAmount AS Difference,
    CASE 
        WHEN o.TotalAmount > ca.AvgAmount THEN 'Above Average'
        WHEN o.TotalAmount < ca.AvgAmount THEN 'Below Average'
        ELSE 'Average'
    END AS Comparison
FROM Orders o
INNER JOIN CustomerAverages ca ON o.CustomerID = ca.CustomerID
ORDER BY o.CustomerID, o.OrderDate;


/*
============================================================================
KEY TAKEAWAYS
============================================================================

✓ SELF-JOIN BASICS:
  • Join table to itself using different aliases
  • Compare rows within same table
  • Requires meaningful join condition
  • Use < or <> to avoid duplicates

✓ COMMON USE CASES:
  • Hierarchical data (employees/managers)
  • Finding duplicates
  • Comparing sequential rows
  • Range overlaps
  • Product recommendations

✓ KEY PATTERNS:
  • p1.ID < p2.ID (avoid duplicates)
  • p1.ID <> p2.ID (different rows)
  • Parent-child (e.ManagerID = m.EmployeeID)
  • Sequential (find next/previous row)

✓ HIERARCHICAL DATA:
  • Employee → Manager relationship
  • Parent → Child categories
  • Multi-level reporting
  • Organization charts

✓ PERFORMANCE:
  • Can create large result sets (N²)
  • Index join columns
  • Limit scope with WHERE
  • Consider alternatives (window functions)

✓ BEST PRACTICES:
  • Use meaningful aliases (emp, mgr not e1, e2)
  • Add conditions to prevent duplicates
  • Test on small dataset first
  • Comment complex logic
  • Consider performance impact

✓ ALTERNATIVES:
  • Window functions (LAG, LEAD)
  • Recursive CTEs (hierarchies)
  • ROW_NUMBER for ranking
  • EXISTS for existence checks

============================================================================
NEXT: Lesson 10.04 - Cross Joins
Master Cartesian products and learn when cross joins are useful.
============================================================================
*/
