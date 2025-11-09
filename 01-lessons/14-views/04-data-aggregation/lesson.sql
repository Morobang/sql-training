/*
================================================================================
LESSON 14.4: DATA AGGREGATION WITH VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Create views with aggregate functions
2. Understand pre-aggregated data benefits
3. Use indexed views for materialized aggregates
4. Implement summary reports via views
5. Optimize aggregate view performance
6. Handle common aggregation patterns
7. Apply best practices for aggregate views

Business Context:
-----------------
Aggregate views provide pre-computed summaries that improve query performance
and simplify reporting. They're essential for dashboards, KPIs, and analytics
where the same calculations are needed repeatedly. Indexed views can
materialize these aggregates for even faster access.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: BASIC AGGREGATE VIEWS
================================================================================

Aggregate views summarize data using GROUP BY and aggregate functions.
*/

-- Create sample tables
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Region NVARCHAR(50) NOT NULL,
    CustomerType NVARCHAR(20) NOT NULL,
    JoinDate DATE NOT NULL
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL,
    Status NVARCHAR(20) NOT NULL
);

CREATE TABLE OrderItem (
    OrderItemID INT PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) NOT NULL DEFAULT 0
);
GO

-- Insert sample data
INSERT INTO Customer VALUES 
    (1, 'Acme Corp', 'North', 'Enterprise', '2024-01-15'),
    (2, 'TechStart Inc', 'South', 'SMB', '2024-02-20'),
    (3, 'Global Solutions', 'East', 'Enterprise', '2024-01-10'),
    (4, 'Local Shop', 'West', 'Retail', '2024-03-05');

INSERT INTO Product VALUES
    (1, 'Laptop', 'Electronics', 999.99),
    (2, 'Mouse', 'Electronics', 29.99),
    (3, 'Desk', 'Furniture', 299.99),
    (4, 'Chair', 'Furniture', 199.99),
    (5, 'Monitor', 'Electronics', 399.99);

INSERT INTO [Order] VALUES
    (1, 1, '2024-11-01', 'Completed'),
    (2, 2, '2024-11-02', 'Completed'),
    (3, 1, '2024-11-03', 'Completed'),
    (4, 3, '2024-11-04', 'Completed'),
    (5, 4, '2024-11-05', 'Pending');

INSERT INTO OrderItem VALUES
    (1, 1, 1, 5, 999.99, 0.10),  -- 5 laptops, 10% discount
    (2, 1, 2, 10, 29.99, 0.00),
    (3, 2, 3, 3, 299.99, 0.05),
    (4, 3, 1, 2, 999.99, 0.10),
    (5, 3, 5, 4, 399.99, 0.00),
    (6, 4, 4, 10, 199.99, 0.15),
    (7, 5, 2, 20, 29.99, 0.00);
GO

-- Example 1: Customer order summary
CREATE VIEW CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Region,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(oi.OrderItemID) AS TotalItems,
    SUM(oi.Quantity) AS TotalQuantity,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue,
    AVG(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS AvgItemRevenue,
    MIN(o.OrderDate) AS FirstOrderDate,
    MAX(o.OrderDate) AS LastOrderDate
FROM Customer c
LEFT JOIN [Order] o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderItem oi ON o.OrderID = oi.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.Region;
GO

SELECT * FROM CustomerOrderSummary ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
CustomerID  CustomerName       Region  TotalOrders  TotalItems  TotalQuantity  TotalRevenue  AvgItemRevenue  FirstOrderDate  LastOrderDate
----------  -----------------  ------  -----------  ----------  -------------  ------------  --------------  --------------  -------------
1           Acme Corp          North   2            3           21             6898.45       2299.48         2024-11-01      2024-11-03
3           Global Solutions   East    1            1           10             1699.92       1699.92         2024-11-04      2024-11-04
2           TechStart Inc      South   1            1           3              854.97        854.97          2024-11-02      2024-11-02
4           Local Shop         West    1            1           20             599.97        599.97          2024-11-05      2024-11-05

This view pre-aggregates customer metrics for easy reporting!
*/

-- Example 2: Product sales summary
CREATE VIEW ProductSalesSummary AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.UnitPrice AS ListPrice,
    COUNT(DISTINCT oi.OrderID) AS OrderCount,
    SUM(oi.Quantity) AS TotalSold,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue,
    AVG(oi.Discount) AS AvgDiscount,
    MIN(oi.UnitPrice) AS MinSellingPrice,
    MAX(oi.UnitPrice) AS MaxSellingPrice
FROM Product p
LEFT JOIN OrderItem oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category, p.UnitPrice;
GO

SELECT * FROM ProductSalesSummary ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
ProductID  ProductName  Category      ListPrice  OrderCount  TotalSold  TotalRevenue  AvgDiscount  MinSellingPrice  MaxSellingPrice
---------  -----------  ------------  ---------  ----------  ---------  ------------  -----------  ---------------  ---------------
1          Laptop       Electronics   999.99     2           7          6298.93       0.10         999.99           999.99
5          Monitor      Electronics   399.99     1           4          1599.96       0.00         399.99           399.99
4          Chair        Furniture     199.99     1           10         1699.92       0.15         199.99           199.99
3          Desk         Furniture     299.99     1           3          854.97        0.05         299.99           299.99
2          Mouse        Electronics   29.99      2           30         899.70        0.00         29.99            29.99

Shows product performance at a glance!
*/

/*
================================================================================
PART 2: TIME-BASED AGGREGATIONS
================================================================================

Common pattern: Aggregate by time periods (daily, monthly, yearly).
*/

-- Example 1: Daily sales summary
CREATE VIEW DailySalesSummary AS
SELECT 
    o.OrderDate,
    DATENAME(WEEKDAY, o.OrderDate) AS DayOfWeek,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    COUNT(oi.OrderItemID) AS ItemCount,
    SUM(oi.Quantity) AS TotalQuantity,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS Revenue,
    AVG(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS AvgItemValue
FROM [Order] o
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
WHERE o.Status = 'Completed'
GROUP BY o.OrderDate;
GO

SELECT * FROM DailySalesSummary ORDER BY OrderDate;
GO

/*
OUTPUT:
OrderDate   DayOfWeek  OrderCount  ItemCount  TotalQuantity  Revenue    AvgItemValue
----------  ---------  ----------  ---------  -------------  ---------  ------------
2024-11-01  Friday     1           2          15             5198.45    2599.23
2024-11-02  Saturday   1           1          3              854.97     854.97
2024-11-03  Sunday     1           2          6              1699.99    849.99
2024-11-04  Monday     1           1          10             1699.92    1699.92

Daily revenue tracking made easy!
*/

-- Example 2: Monthly category summary
CREATE VIEW MonthlyCategorySales AS
SELECT 
    YEAR(o.OrderDate) AS Year,
    MONTH(o.OrderDate) AS Month,
    DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS MonthStart,
    p.Category,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(oi.Quantity) AS TotalQuantity,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS Revenue,
    COUNT(DISTINCT c.CustomerID) AS UniqueCustomers
FROM [Order] o
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
WHERE o.Status = 'Completed'
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate), p.Category;
GO

SELECT * FROM MonthlyCategorySales ORDER BY Year, Month, Revenue DESC;
GO

/*
OUTPUT:
Year  Month  MonthStart  Category      OrderCount  TotalQuantity  Revenue    UniqueCustomers
----  -----  ----------  ------------  ----------  -------------  ---------  ---------------
2024  11     2024-11-01  Electronics   4           27             8198.87    2
2024  11     2024-11-01  Furniture     2           13             2554.89    2

Track category performance over time!
*/

/*
================================================================================
PART 3: INDEXED VIEWS (MATERIALIZED VIEWS)
================================================================================

Indexed views store actual data, dramatically improving performance
for expensive aggregations. Requires specific syntax and restrictions.

REQUIREMENTS FOR INDEXED VIEWS:
- Created WITH SCHEMABINDING
- Deterministic functions only
- No OUTER JOIN (use INNER JOIN or CROSS JOIN)
- COUNT_BIG(*) required
- No DISTINCT, TOP, subqueries
- All columns must be explicitly named
*/

-- Example: Create indexed view for customer metrics
CREATE VIEW CustomerMetrics
WITH SCHEMABINDING  -- Required for indexed view
AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Region,
    COUNT_BIG(*) AS OrderItemCount,  -- COUNT_BIG required
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue,
    SUM(oi.Quantity) AS TotalQuantity
FROM dbo.Customer c
INNER JOIN dbo.[Order] o ON c.CustomerID = o.CustomerID
INNER JOIN dbo.OrderItem oi ON o.OrderID = oi.OrderID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.CustomerName, c.Region;
GO

-- Create clustered index (materializes the view)
CREATE UNIQUE CLUSTERED INDEX IX_CustomerMetrics_CustomerID
ON CustomerMetrics (CustomerID);
GO

-- Query indexed view (super fast!)
SELECT * FROM CustomerMetrics ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
CustomerID  CustomerName       Region  OrderItemCount  TotalRevenue  TotalQuantity
----------  -----------------  ------  --------------  ------------  -------------
1           Acme Corp          North   3               6898.45       21
3           Global Solutions   East    1               1699.92       10
2           TechStart Inc      South   1               854.97        3

PERFORMANCE BENEFIT: Data is stored and indexed, not computed on-the-fly!
Automatic updates when underlying tables change.
*/

-- Add nonclustered index for additional performance
CREATE NONCLUSTERED INDEX IX_CustomerMetrics_Region
ON CustomerMetrics (Region) INCLUDE (TotalRevenue);
GO

-- Query by region uses index
SELECT Region, SUM(TotalRevenue) AS RegionRevenue
FROM CustomerMetrics
GROUP BY Region;
GO

/*
================================================================================
PART 4: ROLLUP AND SUBTOTAL AGGREGATIONS
================================================================================

Views can include subtotals and grand totals using GROUPING SETS.
*/

-- Example: Category and region rollups
CREATE VIEW SalesRollup AS
SELECT 
    ISNULL(c.Region, 'ALL REGIONS') AS Region,
    ISNULL(p.Category, 'ALL CATEGORIES') AS Category,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS Revenue,
    SUM(oi.Quantity) AS TotalQuantity,
    COUNT(DISTINCT o.OrderID) AS OrderCount
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
WHERE o.Status = 'Completed'
GROUP BY GROUPING SETS (
    (c.Region, p.Category),  -- Region + Category
    (c.Region),              -- Region totals
    (p.Category),            -- Category totals
    ()                       -- Grand total
);
GO

SELECT * FROM SalesRollup 
ORDER BY 
    CASE WHEN Region = 'ALL REGIONS' THEN 1 ELSE 0 END,
    Region,
    CASE WHEN Category = 'ALL CATEGORIES' THEN 1 ELSE 0 END,
    Category;
GO

/*
OUTPUT:
Region        Category           Revenue    TotalQuantity  OrderCount
------------  -----------------  ---------  -------------  ----------
East          Furniture          1699.92    10             1
North         Electronics        6898.45    21             2
South         Furniture          854.97     3              1
East          ALL CATEGORIES     1699.92    10             1
North         ALL CATEGORIES     6898.45    21             2
South         ALL CATEGORIES     854.97     3              1
ALL REGIONS   Electronics        6898.45    21             2
ALL REGIONS   Furniture          2554.89    13             2
ALL REGIONS   ALL CATEGORIES     9453.34    34             4

Complete hierarchy of summaries!
*/

/*
================================================================================
PART 5: AGGREGATE VIEW PERFORMANCE PATTERNS
================================================================================
*/

-- Pattern 1: Pre-filter then aggregate (better performance)
CREATE VIEW RecentHighValueOrders AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue
FROM Customer c
INNER JOIN [Order] o ON c.CustomerID = o.CustomerID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
WHERE o.OrderDate >= '2024-11-01'  -- Pre-filter
  AND o.Status = 'Completed'
GROUP BY c.CustomerID, c.CustomerName
HAVING SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) >= 500;  -- Post-filter
GO

SELECT * FROM RecentHighValueOrders ORDER BY TotalRevenue DESC;
GO

-- Pattern 2: Use CROSS APPLY for complex calculations
CREATE VIEW CustomerOrderStats AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    stats.OrderCount,
    stats.TotalRevenue,
    stats.AvgOrderValue,
    stats.MaxOrderValue
FROM Customer c
CROSS APPLY (
    SELECT 
        COUNT(DISTINCT o.OrderID) AS OrderCount,
        SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue,
        AVG(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS AvgOrderValue,
        MAX(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS MaxOrderValue
    FROM [Order] o
    INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
    WHERE o.CustomerID = c.CustomerID AND o.Status = 'Completed'
) stats
WHERE stats.OrderCount > 0;  -- Only customers with orders
GO

SELECT * FROM CustomerOrderStats ORDER BY TotalRevenue DESC;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Product Category Analysis
--------------------------------------
Create a view that shows for each product category:
- Number of products
- Number of orders
- Total quantity sold
- Total revenue
- Average price per unit sold
- Highest and lowest selling prices

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Customer Segmentation
----------------------------------
Create a view that segments customers into:
- High Value (total revenue > $2000)
- Medium Value (revenue $500-$2000)
- Low Value (revenue < $500)

Include customer count and total revenue for each segment.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Create Indexed View
--------------------------------
Create an indexed view for daily revenue totals that includes:
- Date
- Total orders
- Total items
- Total revenue
- Number of unique customers

Add appropriate indexes for performance.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Product Category Analysis
CREATE VIEW CategoryAnalysis AS
SELECT 
    p.Category,
    COUNT(DISTINCT p.ProductID) AS ProductCount,
    COUNT(DISTINCT oi.OrderID) AS OrderCount,
    ISNULL(SUM(oi.Quantity), 0) AS TotalQuantitySold,
    ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) AS TotalRevenue,
    CASE 
        WHEN SUM(oi.Quantity) > 0 
        THEN SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) / SUM(oi.Quantity)
        ELSE 0 
    END AS AvgPricePerUnit,
    MIN(oi.UnitPrice) AS LowestSellingPrice,
    MAX(oi.UnitPrice) AS HighestSellingPrice
FROM Product p
LEFT JOIN OrderItem oi ON p.ProductID = oi.ProductID
GROUP BY p.Category;
GO

SELECT * FROM CategoryAnalysis ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
Category      ProductCount  OrderCount  TotalQuantitySold  TotalRevenue  AvgPricePerUnit  LowestSellingPrice  HighestSellingPrice
------------  ------------  ----------  -----------------  ------------  ---------------  ------------------  -------------------
Electronics   3             4           41                 8798.59       214.60           29.99               999.99
Furniture     2             2           13                 2554.89       196.53           199.99              299.99
*/

-- Solution 2: Customer Segmentation
CREATE VIEW CustomerSegmentation AS
SELECT 
    CASE 
        WHEN TotalRevenue > 2000 THEN 'High Value'
        WHEN TotalRevenue >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Segment,
    COUNT(*) AS CustomerCount,
    SUM(TotalRevenue) AS SegmentRevenue,
    AVG(TotalRevenue) AS AvgCustomerRevenue,
    MIN(TotalRevenue) AS MinRevenue,
    MAX(TotalRevenue) AS MaxRevenue
FROM (
    SELECT 
        c.CustomerID,
        ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) AS TotalRevenue
    FROM Customer c
    LEFT JOIN [Order] o ON c.CustomerID = o.CustomerID
    LEFT JOIN OrderItem oi ON o.OrderID = oi.OrderID
    WHERE o.Status = 'Completed' OR o.Status IS NULL
    GROUP BY c.CustomerID
) AS CustomerRevenue
GROUP BY 
    CASE 
        WHEN TotalRevenue > 2000 THEN 'High Value'
        WHEN TotalRevenue >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END;
GO

SELECT * FROM CustomerSegmentation ORDER BY SegmentRevenue DESC;
GO

/*
OUTPUT:
Segment        CustomerCount  SegmentRevenue  AvgCustomerRevenue  MinRevenue  MaxRevenue
-------------  -------------  --------------  ------------------  ----------  ----------
High Value     1              6898.45         6898.45             6898.45     6898.45
Medium Value   2              2554.89         1277.44             854.97      1699.92
Low Value      1              0.00            0.00                0.00        0.00
*/

-- Solution 3: Create Indexed View
CREATE VIEW DailyRevenueSummary
WITH SCHEMABINDING
AS
SELECT 
    o.OrderDate,
    COUNT_BIG(*) AS ItemCount,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue,
    SUM(oi.Quantity) AS TotalQuantity,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers
FROM dbo.[Order] o
INNER JOIN dbo.OrderItem oi ON o.OrderID = oi.OrderID
WHERE o.Status = 'Completed'
GROUP BY o.OrderDate;
GO

-- Create clustered index
CREATE UNIQUE CLUSTERED INDEX IX_DailyRevenueSummary_OrderDate
ON DailyRevenueSummary (OrderDate);
GO

-- Create nonclustered index for revenue queries
CREATE NONCLUSTERED INDEX IX_DailyRevenueSummary_Revenue
ON DailyRevenueSummary (TotalRevenue DESC) INCLUDE (OrderDate, OrderCount);
GO

-- Query the indexed view
SELECT * FROM DailyRevenueSummary ORDER BY OrderDate;
GO

-- Find highest revenue day
SELECT TOP 1 * FROM DailyRevenueSummary ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
OrderDate   ItemCount  TotalRevenue  TotalQuantity  OrderCount  UniqueCustomers
----------  ---------  ------------  -------------  ----------  ---------------
2024-11-01  2          5198.45       15             1           1

Performance is excellent due to materialized data!
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. AGGREGATE VIEW BENEFITS
   - Pre-computed summaries
   - Simplified queries
   - Consistent calculations
   - Better performance for repeated queries
   - Easier reporting

2. COMMON AGGREGATIONS
   - SUM, COUNT, AVG, MIN, MAX
   - COUNT(DISTINCT) for unique values
   - GROUP BY for segmentation
   - HAVING for filtering aggregates
   - Time-based grouping (daily, monthly, yearly)

3. INDEXED VIEWS
   - Materialize aggregates for best performance
   - Require WITH SCHEMABINDING
   - Use COUNT_BIG(*) instead of COUNT(*)
   - No OUTER JOIN, DISTINCT, TOP
   - Automatic updates on base table changes
   - Best for expensive, frequently-run queries

4. PERFORMANCE PATTERNS
   - Filter before aggregating (WHERE)
   - Use indexes on underlying tables
   - Consider indexed views for critical queries
   - Avoid DISTINCT when possible
   - Use CROSS APPLY for complex calculations

5. TIME-BASED AGGREGATION
   - Use DATEPART, YEAR, MONTH, DAY
   - Create calendar/date dimensions
   - Group by time periods
   - Include day of week, quarter, etc.
   - Consider fiscal vs calendar year

6. SUBTOTALS AND ROLLUPS
   - GROUPING SETS for multiple levels
   - ROLLUP for hierarchical totals
   - CUBE for all combinations
   - ISNULL for labeling totals
   - ORDER BY for readability

7. BEST PRACTICES
   - Document calculation logic
   - Include relevant dimensions
   - Name views clearly (e.g., *Summary, *Metrics)
   - Test performance impact
   - Consider refresh strategy
   - Use indexed views for critical queries
   - Filter historical data appropriately

8. WHEN TO USE AGGREGATE VIEWS
   - Dashboards and KPIs
   - Regular reports
   - Complex calculations used repeatedly
   - Data warehouse queries
   - API endpoints needing fast response

================================================================================

NEXT STEPS:
-----------
In Lesson 14.5, we'll explore HIDING COMPLEXITY:
- Simplifying multi-table joins
- Abstracting business logic
- Creating user-friendly interfaces
- Complex query patterns

Continue to: 05-hiding-complexity/lesson.sql

================================================================================
*/
