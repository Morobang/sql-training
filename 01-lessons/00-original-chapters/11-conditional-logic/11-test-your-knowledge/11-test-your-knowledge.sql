/*
============================================================================
Lesson 11.11 - Test Your Knowledge
============================================================================

Chapter: 11 - Conditional Logic
Total Points: 400
Time Limit: 90 minutes
Passing Score: 320 (80%)

Instructions:
• Complete all questions in order
• Write queries in the space provided
• Test your solutions before submitting
• Partial credit available for partially correct answers
• Use RetailStore database

Topics Covered:
• CASE expressions (searched and simple)
• COALESCE, ISNULL, NULLIF functions
• Conditional logic in SELECT, WHERE, ORDER BY
• Result set transformations (pivoting)
• EXISTS for existence checks
• Division by zero handling
• Conditional updates
• NULL handling strategies

Good luck!
============================================================================
*/

USE RetailStore;
GO

/*
============================================================================
SECTION 1: CASE Expression Fundamentals (80 points)
============================================================================
*/

-- Question 1 (10 points)
-- Write a query to categorize all products based on price:
-- • 'Luxury' if price >= 200
-- • 'Premium' if price >= 100
-- • 'Standard' if price >= 50
-- • 'Economy' if price < 50
-- • 'Price Not Set' if price is NULL
-- Display: ProductName, Price, PriceCategory

-- YOUR ANSWER:




-- Question 2 (15 points)
-- Create a query showing order fulfillment status for all orders:
-- • 'Completed' if DeliveryDate is not NULL
-- • 'In Transit' if ShipDate is not NULL but DeliveryDate is NULL
-- • 'Processing' if both ShipDate and DeliveryDate are NULL
-- Display: OrderID, OrderDate, ShipDate, DeliveryDate, Status
-- Order by: Status, then OrderDate descending

-- YOUR ANSWER:




-- Question 3 (15 points)
-- Write a query to categorize customers by order frequency:
-- • 'VIP' if 10 or more orders
-- • 'Loyal' if 5-9 orders
-- • 'Regular' if 2-4 orders
-- • 'New' if exactly 1 order
-- • 'Inactive' if 0 orders
-- Display: CustomerName, OrderCount, CustomerSegment
-- Order by OrderCount descending

-- YOUR ANSWER:




-- Question 4 (20 points)
-- Create a grading system for products based on sales performance:
-- Calculate total quantity sold per product, then assign grades:
-- • 'A+' if sold >= 100 units
-- • 'A' if sold >= 75 units
-- • 'B' if sold >= 50 units
-- • 'C' if sold >= 25 units
-- • 'D' if sold >= 1 unit
-- • 'F' if never sold (0 or NULL)
-- Display: ProductName, TotalQuantitySold, Grade
-- Order by Grade, TotalQuantitySold descending

-- YOUR ANSWER:




-- Question 5 (20 points)
-- Write a query using SIMPLE CASE to convert month numbers to names.
-- For all orders, show the month name instead of number.
-- Display: OrderID, OrderDate, MonthNumber, MonthName
-- Order by OrderDate
-- Limit to orders from OrderID 1-30
-- Hint: Use MONTH(OrderDate) and SIMPLE CASE with IN clause

-- YOUR ANSWER:




/*
============================================================================
SECTION 2: COALESCE, ISNULL, and NULLIF (60 points)
============================================================================
*/

-- Question 6 (15 points)
-- Write a query showing customer contact information with fallbacks:
-- • PreferredContact: Show Email if available, else Phone, else 'No Contact'
-- • Location: Show City + ', ' + State if both available, else City, else State, else 'Unknown'
-- Display: CustomerID, CustomerName, PreferredContact, Location
-- Order by CustomerID

-- YOUR ANSWER:




-- Question 7 (15 points)
-- Calculate safe average order value per customer (handle division by zero):
-- • Use NULLIF to prevent division by zero
-- • Use COALESCE to display 0 instead of NULL for customers with no orders
-- Display: CustomerName, TotalSpent, OrderCount, AvgOrderValue
-- Order by AvgOrderValue descending

-- YOUR ANSWER:




-- Question 8 (15 points)
-- Write a query to calculate inventory value with NULL handling:
-- • InventoryValue = Price * UnitsInStock
-- • If either Price or UnitsInStock is NULL, show 0 for InventoryValue
-- • Add a DataQualityFlag: 'Complete' if both values present, 'Incomplete' if either is NULL
-- Display: ProductName, Price, UnitsInStock, InventoryValue, DataQualityFlag
-- Order by InventoryValue descending

-- YOUR ANSWER:




-- Question 9 (15 points)
-- Create a query that safely calculates profit margin percentage:
-- • Profit = Revenue - Cost
-- • ProfitMargin% = (Profit / Revenue) * 100
-- • Handle division by zero (return NULL)
-- • Handle NULL values in Revenue or Cost (treat as 0)
-- Use this test data:

CREATE TABLE #ProfitTest (
    ProductID INT,
    ProductName VARCHAR(50),
    Revenue DECIMAL(10,2),
    Cost DECIMAL(10,2)
);

INSERT INTO #ProfitTest VALUES
(1, 'Widget', 1000, 600),
(2, 'Gadget', 500, 400),
(3, 'Doohickey', 0, 50),
(4, 'Thingamajig', NULL, 100),
(5, 'Whatsit', 800, NULL);

-- Display: ProductName, Revenue, Cost, Profit, ProfitMarginPercent
-- YOUR ANSWER:




DROP TABLE #ProfitTest;


/*
============================================================================
SECTION 3: Result Set Transformations (60 points)
============================================================================
*/

-- Question 10 (20 points)
-- Create a pivot report showing total order amounts by quarter.
-- Use manual CASE-based pivot (not PIVOT operator).
-- Display: Year, Q1, Q2, Q3, Q4, YearTotal
-- Order by Year

-- YOUR ANSWER:




-- Question 11 (20 points)
-- Build a cross-tabulation showing order count by customer segment and order size:
-- Customer segments: VIP (10+ orders), Regular (5-9), Occasional (1-4), None (0)
-- Order sizes: Small (<$100), Medium ($100-$500), Large (>$500)
-- Display: CustomerSegment, Small_Orders, Medium_Orders, Large_Orders, Total_Orders
-- Hint: Use subquery or CTE to classify customers first

-- YOUR ANSWER:




-- Question 12 (20 points)
-- Create a report using the PIVOT operator to show:
-- Total sales amount by CategoryID and Year
-- Display: CategoryID, [2023], [2024], GrandTotal
-- Hint: You'll need to join Products, OrderDetails, and Orders

-- YOUR ANSWER:




/*
============================================================================
SECTION 4: Existence Checks (50 points)
============================================================================
*/

-- Question 13 (15 points)
-- Write a query to identify products that have never been ordered.
-- Use EXISTS/NOT EXISTS in a CASE expression.
-- Display: ProductName, Price, OrderStatus ('Has Orders' or 'Never Ordered')
-- Order by OrderStatus, ProductName

-- YOUR ANSWER:




-- Question 14 (20 points)
-- Create a customer engagement report with multiple existence checks:
-- For each customer, check:
-- • Ordered_Last_30_Days (Yes/No)
-- • Ordered_Last_90_Days (Yes/No)
-- • Has_Large_Orders (>$500) (Yes/No)
-- • Overall_Status: 'Highly Engaged' if all 3 are Yes,
--   'Engaged' if 2 are Yes, 'Low Engagement' if 1 is Yes, 'Inactive' if 0 are Yes
-- Display: CustomerName, Ordered_Last_30_Days, Ordered_Last_90_Days, 
--          Has_Large_Orders, Overall_Status
-- Order by Overall_Status

-- YOUR ANSWER:




-- Question 15 (15 points)
-- Find customers who have ordered from multiple categories (at least 3 different categories).
-- Use EXISTS with aggregation.
-- Display: CustomerName, CategoryCount, Status ('Diverse Buyer' or 'Limited Selection')
-- Order by CategoryCount descending

-- YOUR ANSWER:




/*
============================================================================
SECTION 5: Conditional Updates (50 points)
============================================================================
*/

-- Question 16 (25 points)
-- Create a temporary table and perform conditional updates:

CREATE TABLE #ProductUpdates (
    ProductID INT,
    ProductName VARCHAR(50),
    CurrentPrice DECIMAL(10,2),
    StockLevel INT,
    NewPrice DECIMAL(10,2),
    PriceChangeReason VARCHAR(100)
);

INSERT INTO #ProductUpdates
SELECT 
    ProductID, 
    ProductName, 
    Price, 
    UnitsInStock,
    Price,  -- NewPrice starts same as CurrentPrice
    NULL    -- No reason yet
FROM Products
WHERE ProductID <= 20;

-- Write an UPDATE statement that:
-- • Increases NewPrice by 20% if StockLevel < 10 (Reason: 'Low Stock Premium')
-- • Decreases NewPrice by 15% if StockLevel > 100 (Reason: 'Overstock Clearance')
-- • Increases NewPrice by 5% if StockLevel between 10 and 100 (Reason: 'Regular Adjustment')
-- • Updates both NewPrice and PriceChangeReason in a single UPDATE

-- YOUR ANSWER:




SELECT * FROM #ProductUpdates;
DROP TABLE #ProductUpdates;


-- Question 17 (25 points)
-- Implement a MERGE operation with conditional logic:

CREATE TABLE #TargetInventory (
    ProductID INT PRIMARY KEY,
    QuantityOnHand INT,
    Status VARCHAR(20)
);

INSERT INTO #TargetInventory VALUES
(1, 50, 'NORMAL'),
(2, 5, 'LOW'),
(3, 150, 'HIGH');

CREATE TABLE #InventoryAdjustments (
    ProductID INT,
    AdjustmentQty INT
);

INSERT INTO #InventoryAdjustments VALUES
(1, -10),   -- Sale
(2, 100),   -- Restock
(4, 25);    -- New product

-- Write a MERGE statement that:
-- WHEN MATCHED: 
--   • Updates QuantityOnHand by adding AdjustmentQty
--   • Sets Status based on new quantity:
--     'OUT_OF_STOCK' if result is 0
--     'LOW' if result is 1-20
--     'NORMAL' if result is 21-100
--     'HIGH' if result is >100
-- WHEN NOT MATCHED BY TARGET:
--   • Inserts new product with appropriate status
-- YOUR ANSWER:




SELECT * FROM #TargetInventory ORDER BY ProductID;
DROP TABLE #TargetInventory;
DROP TABLE #InventoryAdjustments;


/*
============================================================================
SECTION 6: Complex Scenarios (60 points)
============================================================================
*/

-- Question 18 (30 points)
-- Create a comprehensive customer scoring system:
-- Calculate a score (0-100) for each customer based on:
-- • Recency: 30 points if ordered in last 30 days, 20 if last 90 days, 10 if last year, 0 otherwise
-- • Frequency: 30 points if 10+ orders, 20 if 5-9, 10 if 2-4, 5 if 1, 0 if none
-- • Monetary: 40 points if spent $5000+, 30 if $2000+, 20 if $500+, 10 if $100+, 0 otherwise
-- 
-- Then categorize based on total score:
-- • 'Champion' if score >= 80
-- • 'Loyal' if score >= 60
-- • 'Potential' if score >= 40
-- • 'At Risk' if score >= 20
-- • 'Lost' if score < 20
--
-- Display: CustomerName, RecencyScore, FrequencyScore, MonetaryScore, 
--          TotalScore, Segment
-- Order by TotalScore descending

-- YOUR ANSWER:




-- Question 19 (30 points)
-- Create a dynamic pricing recommendation system:
-- For each product, calculate recommended price adjustments based on:
-- 
-- Sales velocity (last 30 days):
--   • Fast: >= 20 units sold
--   • Medium: 10-19 units sold
--   • Slow: 1-9 units sold
--   • None: 0 units sold
--
-- Stock situation:
--   • Critical: UnitsInStock = 0
--   • Low: UnitsInStock <= ReorderLevel
--   • Normal: UnitsInStock > ReorderLevel
--
-- Pricing recommendation logic:
--   • Fast + Critical: +25% ("High demand, create scarcity premium")
--   • Fast + Low: +15% ("High demand, limited supply")
--   • Fast + Normal: +10% ("Capitalize on demand")
--   • Medium + Critical: +10% ("Moderate demand, stock issue")
--   • Medium + Low: +5% ("Standard adjustment")
--   • Medium + Normal: 0% ("No change")
--   • Slow + Critical: 0% ("Don't raise price on non-seller")
--   • Slow + Low: -10% ("Clearance needed")
--   • Slow + Normal: -5% ("Gentle discount")
--   • None + Any: -20% ("Deep discount to move inventory")
--
-- Display: ProductName, CurrentPrice, SalesVelocity, StockSituation, 
--          AdjustmentPercent, RecommendedPrice, Reasoning
-- Order by AdjustmentPercent descending

-- YOUR ANSWER:




/*
============================================================================
SECTION 7: Performance and Best Practices (40 points)
============================================================================
*/

-- Question 20 (20 points)
-- Identify the performance issues in this query and rewrite it efficiently:

/*
PROBLEMATIC QUERY:

SELECT 
    c.CustomerName,
    CASE 
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) >= 10 
            THEN 'VIP'
        ELSE 'Regular'
    END AS Tier,
    CASE 
        WHEN (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) >= 10 
            THEN 25.0
        ELSE 10.0
    END AS DiscountPercent,
    (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) AS OrderCount
FROM Customers c
WHERE (SELECT COUNT(*) FROM Orders o WHERE o.CustomerID = c.CustomerID) > 0;
*/

-- Problems identified:
-- 1. 
-- 2.
-- 3.

-- Optimized version:
-- YOUR ANSWER:




-- Question 21 (20 points)
-- Write a query demonstrating proper NULL handling strategy.
-- Create a sales report that:
-- • Shows all products (even those never sold)
-- • Calculates average unit price (safe division)
-- • Shows total revenue (treating NULL as 0)
-- • Displays last sale date (showing 'Never Sold' for NULL)
-- • Indicates data quality issues
--
-- Display: ProductName, UnitsSold, Revenue, AvgUnitPrice, LastSaleDate, DataQuality
-- DataQuality should identify if there are any NULL or inconsistent values
--
-- YOUR ANSWER:




/*
============================================================================
ANSWER KEY
============================================================================
Solutions are provided below. Do not look until you've completed all questions!


*/
GO

-- SCROLL DOWN FOR ANSWERS

GO
GO
GO
GO
GO
GO
GO
GO
GO
GO

/*
============================================================================
SOLUTIONS
============================================================================
*/

-- Solution 1 (10 points)
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN Price IS NULL THEN 'Price Not Set'
        WHEN Price >= 200 THEN 'Luxury'
        WHEN Price >= 100 THEN 'Premium'
        WHEN Price >= 50 THEN 'Standard'
        ELSE 'Economy'
    END AS PriceCategory
FROM Products
ORDER BY Price DESC;

-- Solution 2 (15 points)
SELECT 
    OrderID,
    OrderDate,
    ShipDate,
    DeliveryDate,
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 'Completed'
        WHEN ShipDate IS NOT NULL THEN 'In Transit'
        ELSE 'Processing'
    END AS Status
FROM Orders
ORDER BY 
    CASE 
        WHEN DeliveryDate IS NOT NULL THEN 3
        WHEN ShipDate IS NOT NULL THEN 2
        ELSE 1
    END,
    OrderDate DESC;

-- Solution 3 (15 points)
SELECT 
    c.CustomerName,
    COUNT(o.OrderID) AS OrderCount,
    CASE 
        WHEN COUNT(o.OrderID) >= 10 THEN 'VIP'
        WHEN COUNT(o.OrderID) >= 5 THEN 'Loyal'
        WHEN COUNT(o.OrderID) >= 2 THEN 'Regular'
        WHEN COUNT(o.OrderID) = 1 THEN 'New'
        ELSE 'Inactive'
    END AS CustomerSegment
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY OrderCount DESC;

-- Solution 4 (20 points)
SELECT 
    p.ProductName,
    COALESCE(SUM(od.Quantity), 0) AS TotalQuantitySold,
    CASE 
        WHEN COALESCE(SUM(od.Quantity), 0) >= 100 THEN 'A+'
        WHEN COALESCE(SUM(od.Quantity), 0) >= 75 THEN 'A'
        WHEN COALESCE(SUM(od.Quantity), 0) >= 50 THEN 'B'
        WHEN COALESCE(SUM(od.Quantity), 0) >= 25 THEN 'C'
        WHEN COALESCE(SUM(od.Quantity), 0) >= 1 THEN 'D'
        ELSE 'F'
    END AS Grade
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY 
    CASE 
        WHEN COALESCE(SUM(od.Quantity), 0) >= 100 THEN 1
        WHEN COALESCE(SUM(od.Quantity), 0) >= 75 THEN 2
        WHEN COALESCE(SUM(od.Quantity), 0) >= 50 THEN 3
        WHEN COALESCE(SUM(od.Quantity), 0) >= 25 THEN 4
        WHEN COALESCE(SUM(od.Quantity), 0) >= 1 THEN 5
        ELSE 6
    END,
    TotalQuantitySold DESC;

-- Solution 5 (20 points)
SELECT 
    OrderID,
    OrderDate,
    MONTH(OrderDate) AS MonthNumber,
    CASE MONTH(OrderDate)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END AS MonthName
FROM Orders
WHERE OrderID BETWEEN 1 AND 30
ORDER BY OrderDate;

-- Solution 6 (15 points)
SELECT 
    CustomerID,
    CustomerName,
    COALESCE(Email, Phone, 'No Contact') AS PreferredContact,
    COALESCE(
        CASE WHEN City IS NOT NULL AND State IS NOT NULL THEN City + ', ' + State END,
        City,
        State,
        'Unknown'
    ) AS Location
FROM Customers
ORDER BY CustomerID;

-- Solution 7 (15 points)
SELECT 
    c.CustomerName,
    COALESCE(SUM(o.TotalAmount), 0) AS TotalSpent,
    COUNT(o.OrderID) AS OrderCount,
    COALESCE(SUM(o.TotalAmount) / NULLIF(COUNT(o.OrderID), 0), 0) AS AvgOrderValue
FROM Customers c
LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY AvgOrderValue DESC;

-- Solution 8 (15 points)
SELECT 
    ProductName,
    Price,
    UnitsInStock,
    COALESCE(Price, 0) * COALESCE(UnitsInStock, 0) AS InventoryValue,
    CASE 
        WHEN Price IS NOT NULL AND UnitsInStock IS NOT NULL THEN 'Complete'
        ELSE 'Incomplete'
    END AS DataQualityFlag
FROM Products
ORDER BY InventoryValue DESC;

-- Solution 9 (15 points)
SELECT 
    ProductName,
    COALESCE(Revenue, 0) AS Revenue,
    COALESCE(Cost, 0) AS Cost,
    COALESCE(Revenue, 0) - COALESCE(Cost, 0) AS Profit,
    ROUND(
        (COALESCE(Revenue, 0) - COALESCE(Cost, 0)) * 100.0 / NULLIF(COALESCE(Revenue, 0), 0),
        2
    ) AS ProfitMarginPercent
FROM #ProfitTest;

-- Solution 10 (20 points)
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 1 THEN TotalAmount ELSE 0 END) AS Q1,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 2 THEN TotalAmount ELSE 0 END) AS Q2,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 3 THEN TotalAmount ELSE 0 END) AS Q3,
    SUM(CASE WHEN DATEPART(QUARTER, OrderDate) = 4 THEN TotalAmount ELSE 0 END) AS Q4,
    SUM(TotalAmount) AS YearTotal
FROM Orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;

-- Solution 11 (20 points)
WITH CustomerSegments AS (
    SELECT 
        c.CustomerID,
        CASE 
            WHEN COUNT(o.OrderID) >= 10 THEN 'VIP'
            WHEN COUNT(o.OrderID) >= 5 THEN 'Regular'
            WHEN COUNT(o.OrderID) >= 1 THEN 'Occasional'
            ELSE 'None'
        END AS CustomerSegment
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
)
SELECT 
    cs.CustomerSegment,
    SUM(CASE WHEN o.TotalAmount < 100 THEN 1 ELSE 0 END) AS Small_Orders,
    SUM(CASE WHEN o.TotalAmount >= 100 AND o.TotalAmount <= 500 THEN 1 ELSE 0 END) AS Medium_Orders,
    SUM(CASE WHEN o.TotalAmount > 500 THEN 1 ELSE 0 END) AS Large_Orders,
    COUNT(o.OrderID) AS Total_Orders
FROM CustomerSegments cs
LEFT JOIN Orders o ON cs.CustomerID = o.CustomerID
GROUP BY cs.CustomerSegment
ORDER BY Total_Orders DESC;

-- Solution 12 (20 points)
SELECT 
    CategoryID,
    ISNULL([2023], 0) AS [2023],
    ISNULL([2024], 0) AS [2024],
    ISNULL([2023], 0) + ISNULL([2024], 0) AS GrandTotal
FROM (
    SELECT 
        p.CategoryID,
        YEAR(o.OrderDate) AS Year,
        od.Quantity * od.Price AS Sales
    FROM OrderDetails od
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
) AS SourceData
PIVOT (
    SUM(Sales)
    FOR Year IN ([2023], [2024])
) AS PivotTable
ORDER BY CategoryID;

-- Solution 13 (15 points)
SELECT 
    ProductName,
    Price,
    CASE 
        WHEN EXISTS (SELECT 1 FROM OrderDetails od WHERE od.ProductID = p.ProductID) 
            THEN 'Has Orders'
        ELSE 'Never Ordered'
    END AS OrderStatus
FROM Products p
ORDER BY OrderStatus, ProductName;

-- Solution 14 (20 points)
SELECT 
    c.CustomerName,
    CASE WHEN EXISTS (
        SELECT 1 FROM Orders o 
        WHERE o.CustomerID = c.CustomerID 
        AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())
    ) THEN 'Yes' ELSE 'No' END AS Ordered_Last_30_Days,
    CASE WHEN EXISTS (
        SELECT 1 FROM Orders o 
        WHERE o.CustomerID = c.CustomerID 
        AND o.OrderDate >= DATEADD(DAY, -90, GETDATE())
    ) THEN 'Yes' ELSE 'No' END AS Ordered_Last_90_Days,
    CASE WHEN EXISTS (
        SELECT 1 FROM Orders o 
        WHERE o.CustomerID = c.CustomerID 
        AND o.TotalAmount > 500
    ) THEN 'Yes' ELSE 'No' END AS Has_Large_Orders,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -30, GETDATE()))
         AND EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -90, GETDATE()))
         AND EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.TotalAmount > 500)
            THEN 'Highly Engaged'
        WHEN (CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())) THEN 1 ELSE 0 END +
              CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -90, GETDATE())) THEN 1 ELSE 0 END +
              CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.TotalAmount > 500) THEN 1 ELSE 0 END) = 2
            THEN 'Engaged'
        WHEN (CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -30, GETDATE())) THEN 1 ELSE 0 END +
              CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.OrderDate >= DATEADD(DAY, -90, GETDATE())) THEN 1 ELSE 0 END +
              CASE WHEN EXISTS (SELECT 1 FROM Orders o WHERE o.CustomerID = c.CustomerID AND o.TotalAmount > 500) THEN 1 ELSE 0 END) = 1
            THEN 'Low Engagement'
        ELSE 'Inactive'
    END AS Overall_Status
FROM Customers c
ORDER BY Overall_Status;

-- Solution 15 (15 points)
SELECT 
    c.CustomerName,
    COUNT(DISTINCT p.CategoryID) AS CategoryCount,
    CASE 
        WHEN COUNT(DISTINCT p.CategoryID) >= 3 THEN 'Diverse Buyer'
        ELSE 'Limited Selection'
    END AS Status
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
INNER JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY CategoryCount DESC;

-- Solution 16 (25 points)
UPDATE #ProductUpdates
SET 
    NewPrice = CASE 
        WHEN StockLevel < 10 THEN CurrentPrice * 1.20
        WHEN StockLevel > 100 THEN CurrentPrice * 0.85
        ELSE CurrentPrice * 1.05
    END,
    PriceChangeReason = CASE 
        WHEN StockLevel < 10 THEN 'Low Stock Premium'
        WHEN StockLevel > 100 THEN 'Overstock Clearance'
        ELSE 'Regular Adjustment'
    END;

-- Solution 17 (25 points)
MERGE #TargetInventory AS target
USING #InventoryAdjustments AS source
ON target.ProductID = source.ProductID
WHEN MATCHED THEN
    UPDATE SET 
        QuantityOnHand = target.QuantityOnHand + source.AdjustmentQty,
        Status = CASE 
            WHEN target.QuantityOnHand + source.AdjustmentQty = 0 THEN 'OUT_OF_STOCK'
            WHEN target.QuantityOnHand + source.AdjustmentQty <= 20 THEN 'LOW'
            WHEN target.QuantityOnHand + source.AdjustmentQty <= 100 THEN 'NORMAL'
            ELSE 'HIGH'
        END
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ProductID, QuantityOnHand, Status)
    VALUES (
        source.ProductID,
        source.AdjustmentQty,
        CASE 
            WHEN source.AdjustmentQty = 0 THEN 'OUT_OF_STOCK'
            WHEN source.AdjustmentQty <= 20 THEN 'LOW'
            WHEN source.AdjustmentQty <= 100 THEN 'NORMAL'
            ELSE 'HIGH'
        END
    );

-- Solution 18 (30 points)
WITH CustomerMetrics AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT 
    CustomerName,
    CASE 
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 30
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 20
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 365 THEN 10
        ELSE 0
    END AS RecencyScore,
    CASE 
        WHEN OrderCount >= 10 THEN 30
        WHEN OrderCount >= 5 THEN 20
        WHEN OrderCount >= 2 THEN 10
        WHEN OrderCount >= 1 THEN 5
        ELSE 0
    END AS FrequencyScore,
    CASE 
        WHEN TotalSpent >= 5000 THEN 40
        WHEN TotalSpent >= 2000 THEN 30
        WHEN TotalSpent >= 500 THEN 20
        WHEN TotalSpent >= 100 THEN 10
        ELSE 0
    END AS MonetaryScore,
    CASE 
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 30
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 20
        WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 365 THEN 10
        ELSE 0
    END +
    CASE 
        WHEN OrderCount >= 10 THEN 30
        WHEN OrderCount >= 5 THEN 20
        WHEN OrderCount >= 2 THEN 10
        WHEN OrderCount >= 1 THEN 5
        ELSE 0
    END +
    CASE 
        WHEN TotalSpent >= 5000 THEN 40
        WHEN TotalSpent >= 2000 THEN 30
        WHEN TotalSpent >= 500 THEN 20
        WHEN TotalSpent >= 100 THEN 10
        ELSE 0
    END AS TotalScore,
    CASE 
        WHEN (CASE 
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 30
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 20
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 365 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN OrderCount >= 10 THEN 30
            WHEN OrderCount >= 5 THEN 20
            WHEN OrderCount >= 2 THEN 10
            WHEN OrderCount >= 1 THEN 5
            ELSE 0
        END +
        CASE 
            WHEN TotalSpent >= 5000 THEN 40
            WHEN TotalSpent >= 2000 THEN 30
            WHEN TotalSpent >= 500 THEN 20
            WHEN TotalSpent >= 100 THEN 10
            ELSE 0
        END) >= 80 THEN 'Champion'
        WHEN (CASE 
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 30
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 20
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 365 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN OrderCount >= 10 THEN 30
            WHEN OrderCount >= 5 THEN 20
            WHEN OrderCount >= 2 THEN 10
            WHEN OrderCount >= 1 THEN 5
            ELSE 0
        END +
        CASE 
            WHEN TotalSpent >= 5000 THEN 40
            WHEN TotalSpent >= 2000 THEN 30
            WHEN TotalSpent >= 500 THEN 20
            WHEN TotalSpent >= 100 THEN 10
            ELSE 0
        END) >= 60 THEN 'Loyal'
        WHEN (CASE 
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 30
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 20
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 365 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN OrderCount >= 10 THEN 30
            WHEN OrderCount >= 5 THEN 20
            WHEN OrderCount >= 2 THEN 10
            WHEN OrderCount >= 1 THEN 5
            ELSE 0
        END +
        CASE 
            WHEN TotalSpent >= 5000 THEN 40
            WHEN TotalSpent >= 2000 THEN 30
            WHEN TotalSpent >= 500 THEN 20
            WHEN TotalSpent >= 100 THEN 10
            ELSE 0
        END) >= 40 THEN 'Potential'
        WHEN (CASE 
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 30 THEN 30
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 90 THEN 20
            WHEN DATEDIFF(DAY, LastOrderDate, GETDATE()) <= 365 THEN 10
            ELSE 0
        END +
        CASE 
            WHEN OrderCount >= 10 THEN 30
            WHEN OrderCount >= 5 THEN 20
            WHEN OrderCount >= 2 THEN 10
            WHEN OrderCount >= 1 THEN 5
            ELSE 0
        END +
        CASE 
            WHEN TotalSpent >= 5000 THEN 40
            WHEN TotalSpent >= 2000 THEN 30
            WHEN TotalSpent >= 500 THEN 20
            WHEN TotalSpent >= 100 THEN 10
            ELSE 0
        END) >= 20 THEN 'At Risk'
        ELSE 'Lost'
    END AS Segment
FROM CustomerMetrics
ORDER BY TotalScore DESC;

-- Solution 19 (30 points) - See lesson for detailed solution

-- Solution 20 (20 points)
-- Problems:
-- 1. Repeated subqueries (same subquery executed 4 times per row)
-- 2. Correlated subquery in WHERE clause
-- 3. No use of aggregation or joins

-- Optimized:
WITH CustomerOrders AS (
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS OrderCount
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID, c.CustomerName
    HAVING COUNT(o.OrderID) > 0
)
SELECT 
    CustomerName,
    CASE 
        WHEN OrderCount >= 10 THEN 'VIP'
        ELSE 'Regular'
    END AS Tier,
    CASE 
        WHEN OrderCount >= 10 THEN 25.0
        ELSE 10.0
    END AS DiscountPercent,
    OrderCount
FROM CustomerOrders;

-- Solution 21 (20 points)
SELECT 
    p.ProductName,
    COALESCE(SUM(od.Quantity), 0) AS UnitsSold,
    COALESCE(SUM(od.Quantity * od.Price), 0) AS Revenue,
    SUM(od.Quantity * od.Price) / NULLIF(SUM(od.Quantity), 0) AS AvgUnitPrice,
    COALESCE(CONVERT(VARCHAR, MAX(o.OrderDate), 101), 'Never Sold') AS LastSaleDate,
    CASE 
        WHEN p.Price IS NULL THEN 'Missing Price'
        WHEN NOT EXISTS (SELECT 1 FROM OrderDetails WHERE ProductID = p.ProductID) THEN 'Never Sold'
        ELSE 'OK'
    END AS DataQuality
FROM Products p
LEFT JOIN OrderDetails od ON p.ProductID = od.ProductID
LEFT JOIN Orders o ON od.OrderID = o.OrderID
GROUP BY p.ProductID, p.ProductName, p.Price
ORDER BY Revenue DESC;

/*
============================================================================
SCORING RUBRIC
============================================================================

SECTION 1: CASE Expression Fundamentals (80 points)
  Q1:  10 points - All price categories correct
  Q2:  15 points - Status logic + sorting
  Q3:  15 points - Customer segments with aggregation
  Q4:  20 points - Product grading with LEFT JOIN and COALESCE
  Q5:  20 points - SIMPLE CASE for month names

SECTION 2: COALESCE, ISNULL, NULLIF (60 points)
  Q6:  15 points - Multiple COALESCE fallbacks
  Q7:  15 points - NULLIF for division by zero
  Q8:  15 points - NULL handling in calculations
  Q9:  15 points - Safe profit margin calculation

SECTION 3: Result Set Transformations (60 points)
  Q10: 20 points - Manual pivot with CASE
  Q11: 20 points - Cross-tabulation report
  Q12: 20 points - PIVOT operator usage

SECTION 4: Existence Checks (50 points)
  Q13: 15 points - Basic EXISTS check
  Q14: 20 points - Multiple existence checks
  Q15: 15 points - EXISTS with aggregation

SECTION 5: Conditional Updates (50 points)
  Q16: 25 points - UPDATE with CASE
  Q17: 25 points - MERGE with conditional logic

SECTION 6: Complex Scenarios (60 points)
  Q18: 30 points - RFM scoring system
  Q19: 30 points - Dynamic pricing logic

SECTION 7: Performance and Best Practices (40 points)
  Q20: 20 points - Query optimization
  Q21: 20 points - Comprehensive NULL handling

TOTAL: 400 points

Grading Scale:
  360-400 (90-100%): Excellent - Mastery of conditional logic
  320-359 (80-89%):  Good - Solid understanding
  280-319 (70-79%):  Satisfactory - Needs more practice
  Below 280 (<70%):  Review material and retake

============================================================================
END OF TEST
============================================================================
*/
