/*
================================================================================
LESSON 14.10: TEST YOUR KNOWLEDGE - VIEWS
================================================================================

Comprehensive Assessment: Chapter 14 - Views
Database: RetailStore
Total Points: 400
Estimated Time: 90-120 minutes

Instructions:
-------------
1. Complete all exercises without looking at solutions first
2. Test your solutions thoroughly
3. Each exercise shows point value
4. Scoring: 360+ Excellent, 320-359 Good, 280-319 Fair, <280 Review chapter
5. Solutions provided at end - use only after attempting exercises

Topics Covered:
---------------
✓ Creating and managing views
✓ Security and data masking
✓ Aggregate views and indexed views
✓ Hiding complexity
✓ Partitioned views
✓ Updatable views and triggers
✓ Performance optimization
✓ Best practices

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
SETUP: CREATE DATABASE SCHEMA
================================================================================
*/

-- Clean up existing objects
DROP VIEW IF EXISTS OrderDetails, CustomerOrderSummary, ProductSalesSummary;
DROP TABLE IF EXISTS OrderItem, [Order], Customer, Product, Category, Employee, Department, AuditLog;
GO

-- Create core schema
CREATE TABLE Department (
    DepartmentID INT PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    Budget DECIMAL(12,2) NOT NULL,
    ManagerID INT NULL
);

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeName NVARCHAR(200) NOT NULL,
    DepartmentID INT FOREIGN KEY REFERENCES Department(DepartmentID),
    Title NVARCHAR(100),
    Salary DECIMAL(10,2) NOT NULL,
    Email NVARCHAR(200),
    SSN NVARCHAR(11),  -- Sensitive data
    HireDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Category (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    ParentCategoryID INT NULL,
    IsActive BIT DEFAULT 1
);

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT FOREIGN KEY REFERENCES Category(CategoryID),
    UnitPrice DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    ReorderLevel INT DEFAULT 10,
    IsActive BIT DEFAULT 1,
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE),
    ModifiedDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200),
    Phone NVARCHAR(20),
    Region NVARCHAR(50),
    CustomerType NVARCHAR(20),  -- Enterprise, SMB, Retail
    CreditLimit DECIMAL(10,2) DEFAULT 5000.00,
    IsActive BIT DEFAULT 1,
    JoinDate DATE DEFAULT CAST(GETDATE() AS DATE)
);

CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    EmployeeID INT FOREIGN KEY REFERENCES Employee(EmployeeID),
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ShipDate DATE NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',  -- Pending, Processing, Shipped, Delivered, Cancelled
    TotalAmount DECIMAL(12,2) DEFAULT 0
);

CREATE TABLE OrderItem (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0,
    LineTotal AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED
);

CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100),
    Operation NVARCHAR(20),
    RecordID INT,
    UserName NVARCHAR(100) DEFAULT SUSER_NAME(),
    LogDate DATETIME DEFAULT GETDATE(),
    Details NVARCHAR(MAX)
);
GO

-- Insert sample data
INSERT INTO Department VALUES
    (1, 'Sales', 500000.00, NULL),
    (2, 'IT', 750000.00, NULL),
    (3, 'Marketing', 400000.00, NULL),
    (4, 'HR', 300000.00, NULL);

INSERT INTO Employee (EmployeeName, DepartmentID, Title, Salary, Email, SSN, HireDate, IsActive) VALUES
    ('John Smith', 1, 'Sales Manager', 85000.00, 'john.smith@company.com', '123-45-6789', '2020-01-15', 1),
    ('Jane Doe', 1, 'Sales Rep', 65000.00, 'jane.doe@company.com', '234-56-7890', '2021-03-20', 1),
    ('Bob Johnson', 2, 'IT Manager', 95000.00, 'bob.johnson@company.com', '345-67-8901', '2019-06-10', 1),
    ('Alice Williams', 2, 'Developer', 80000.00, 'alice.williams@company.com', '456-78-9012', '2022-02-01', 1),
    ('Charlie Brown', 3, 'Marketing Lead', 75000.00, 'charlie.brown@company.com', '567-89-0123', '2021-09-15', 1),
    ('Eve Davis', 4, 'HR Manager', 70000.00, 'eve.davis@company.com', '678-90-1234', '2020-11-01', 1),
    ('Frank Miller', 1, 'Sales Rep', 60000.00, 'frank.miller@company.com', '789-01-2345', '2023-01-10', 0);

INSERT INTO Category VALUES
    (1, 'Electronics', NULL, 1),
    (2, 'Computers', 1, 1),
    (3, 'Accessories', 1, 1),
    (4, 'Furniture', NULL, 1),
    (5, 'Office', 4, 1);

INSERT INTO Product (ProductName, CategoryID, UnitPrice, Cost, StockQuantity, ReorderLevel, IsActive) VALUES
    ('Laptop Pro', 2, 1299.99, 900.00, 50, 10, 1),
    ('Desktop Computer', 2, 899.99, 650.00, 30, 5, 1),
    ('Wireless Mouse', 3, 29.99, 15.00, 200, 50, 1),
    ('Keyboard', 3, 49.99, 25.00, 150, 30, 1),
    ('Monitor 24"', 1, 299.99, 200.00, 75, 20, 1),
    ('Office Desk', 4, 399.99, 250.00, 25, 5, 1),
    ('Office Chair', 4, 249.99, 150.00, 40, 10, 1),
    ('USB Hub', 3, 19.99, 8.00, 300, 75, 1),
    ('Webcam', 3, 79.99, 45.00, 60, 15, 1),
    ('Desk Lamp', 5, 39.99, 20.00, 100, 25, 1);

INSERT INTO Customer (CustomerName, Email, Phone, Region, CustomerType, CreditLimit, IsActive) VALUES
    ('Acme Corporation', 'contact@acme.com', '555-0101', 'North', 'Enterprise', 50000.00, 1),
    ('TechStart Inc', 'info@techstart.com', '555-0102', 'South', 'SMB', 10000.00, 1),
    ('Global Solutions', 'sales@globalsol.com', '555-0103', 'East', 'Enterprise', 75000.00, 1),
    ('Local Shop', 'owner@localshop.com', '555-0104', 'West', 'Retail', 5000.00, 1),
    ('Metro Services', 'contact@metro.com', '555-0105', 'North', 'SMB', 15000.00, 1),
    ('Small Business LLC', 'info@smallbiz.com', '555-0106', 'South', 'Retail', 3000.00, 1);

INSERT INTO [Order] (CustomerID, EmployeeID, OrderDate, ShipDate, Status, TotalAmount) VALUES
    (1, 1, '2024-11-01', '2024-11-03', 'Delivered', 7749.84),
    (2, 2, '2024-11-02', '2024-11-05', 'Shipped', 1799.96),
    (3, 1, '2024-11-03', NULL, 'Processing', 2599.96),
    (1, 2, '2024-11-04', '2024-11-06', 'Delivered', 1999.95),
    (4, 1, '2024-11-05', NULL, 'Pending', 649.98),
    (5, 2, '2024-11-06', NULL, 'Processing', 3249.90),
    (2, 1, '2024-11-07', NULL, 'Pending', 599.97),
    (3, 2, '2024-11-08', NULL, 'Processing', 1799.94);

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, Discount) VALUES
    -- Order 1
    (1, 1, 5, 1299.99, 0.10),
    (1, 3, 10, 29.99, 0.00),
    (1, 4, 5, 49.99, 0.00),
    -- Order 2
    (2, 2, 2, 899.99, 0.00),
    -- Order 3
    (3, 5, 5, 299.99, 0.10),
    (3, 7, 5, 249.99, 0.05),
    -- Order 4
    (4, 6, 5, 399.99, 0.00),
    -- Order 5
    (5, 8, 10, 19.99, 0.05),
    (5, 9, 5, 79.99, 0.10),
    -- Order 6
    (6, 1, 2, 1299.99, 0.15),
    (6, 4, 10, 49.99, 0.10),
    -- Order 7
    (7, 3, 20, 29.99, 0.00),
    -- Order 8
    (8, 10, 45, 39.99, 0.00);
GO

/*
================================================================================
EXERCISE 1: BASIC VIEW CREATION (40 points)
================================================================================

Create the following views with proper column selection and filtering:

A. ActiveProducts (10 points)
   - Show only active products
   - Include: ProductID, ProductName, CategoryName, UnitPrice, StockQuantity
   - Join with Category table
   - Use meaningful column aliases

B. EmployeeDirectory (10 points)
   - Show only active employees
   - Include: EmployeeName, Title, DepartmentName, Email
   - Hide SSN and Salary
   - Order conceptually makes sense

C. PendingOrders (10 points)
   - Show orders with Status = 'Pending'
   - Include: OrderID, OrderDate, CustomerName, EmployeeName, TotalAmount
   - Join all necessary tables

D. LowStockProducts (10 points)
   - Show products where StockQuantity <= ReorderLevel
   - Include: ProductName, Category, CurrentStock, ReorderLevel, Difference
   - Calculate how many units below reorder level
*/

-- Your solution for Exercise 1:











/*
================================================================================
EXERCISE 2: SECURITY VIEWS (50 points)
================================================================================

Create security views to protect sensitive data:

A. EmployeeSalaryMasked (15 points)
   - Show all employee information
   - Mask SSN (show only last 4 digits: ***-**-1234)
   - Mask Salary (show range instead of exact value:
     0-50K, 50K-75K, 75K-100K, 100K+)
   - Include DepartmentName

B. CustomerContactRestricted (15 points)
   - Show customers for specific region only (use parameter/filter)
   - Mask email (show only domain: ****@company.com)
   - Mask phone (show only area code: 555-*****)
   - Include all other customer info

C. OrderDetailsWithROLS (20 points)
   - Create view that filters orders by employee
   - Use SUSER_NAME() or SESSION_CONTEXT
   - Employees can only see their own orders
   - Include full order details
   - Bonus: Use WITH CHECK OPTION
*/

-- Your solution for Exercise 2:











/*
================================================================================
EXERCISE 3: AGGREGATE VIEWS (60 points)
================================================================================

Create aggregate views for reporting:

A. CustomerOrderSummary (15 points)
   - Group by customer
   - Include: CustomerName, Region, CustomerType
   - Calculate: TotalOrders, TotalRevenue, AvgOrderValue
   - Calculate: FirstOrderDate, LastOrderDate, DaysSinceLastOrder
   - Order by TotalRevenue descending

B. ProductPerformance (15 points)
   - Group by product
   - Include: ProductName, CategoryName
   - Calculate: TotalOrdered, TotalRevenue, AvgDiscount
   - Calculate: ProfitMargin (Revenue - Cost)
   - Only include products that have been ordered

C. DailySalesSummary (15 points)
   - Group by OrderDate
   - Include: Date, DayOfWeek, OrderCount, TotalRevenue
   - Include: UniqueCustomers, UniqueProducts, AvgOrderValue
   - Order by date

D. DepartmentPayroll (15 points)
   - Group by department
   - Include: DepartmentName, EmployeeCount, TotalPayroll, AvgSalary
   - Include: MinSalary, MaxSalary, PayrollPct (of total)
   - Only active employees
*/

-- Your solution for Exercise 3:











/*
================================================================================
EXERCISE 4: INDEXED VIEW (40 points)
================================================================================

Create a materialized aggregate view using indexed views:

Requirements:
- View name: ProductSalesMetrics
- Aggregate product sales data
- Include: ProductID, ProductName, CategoryID
- Calculate: TotalOrders, TotalQuantitySold, TotalRevenue
- Use WITH SCHEMABINDING
- Create clustered index on ProductID
- Create nonclustered index on TotalRevenue
- Use COUNT_BIG(*) for row count
- Only INNER JOINs
- Test query performance

Points breakdown:
- Correct view definition (15 points)
- Proper indexing (15 points)
- Performance test and comparison (10 points)
*/

-- Your solution for Exercise 4:











/*
================================================================================
EXERCISE 5: HIDING COMPLEXITY (50 points)
================================================================================

Create a complex view that simplifies querying:

View name: ComprehensiveOrderDetails
Requirements:
- Join Order, OrderItem, Product, Category, Customer, Employee, Department
- Include all relevant information from each table
- Calculate line totals, order totals
- Show profit per line (LineTotal - Cost * Quantity)
- Show employee and department information
- Use clear, descriptive column aliases
- Document with comments

Bonus (10 points):
- Create a simplified "summary" view on top of this view
- Show just: OrderID, OrderDate, CustomerName, TotalRevenue, TotalProfit
*/

-- Your solution for Exercise 5:











/*
================================================================================
EXERCISE 6: PARTITIONED VIEW (50 points)
================================================================================

Create a partitioned view for order history:

A. Create partition tables (20 points)
   - Orders_Current (orders from last 30 days)
   - Orders_Recent (orders 31-90 days old)
   - Orders_Archive (orders older than 90 days)
   - Each with appropriate CHECK constraints
   - Include OrderID, CustomerID, OrderDate, TotalAmount, Status

B. Create partitioned view (15 points)
   - Combine all three tables
   - Name: Orders_All
   - Ensure partition elimination works

C. Test and validate (15 points)
   - Insert sample data into partitions
   - Query specific time periods
   - Verify partition elimination
   - Show execution plan
*/

-- Your solution for Exercise 6:











/*
================================================================================
EXERCISE 7: UPDATABLE VIEWS (60 points)
================================================================================

Create updatable views with proper constraints:

A. Simple Updatable View (20 points)
   - View: ProductInventory
   - Based on Product table
   - Include: ProductID, ProductName, CategoryID, UnitPrice, StockQuantity
   - Filter: IsActive = 1
   - Use WITH CHECK OPTION
   - Test INSERT, UPDATE, DELETE

B. INSTEAD OF UPDATE Trigger (20 points)
   - View: EmployeeInfo (Employee JOIN Department)
   - Allow updating employee name, title, salary
   - Allow updating department name
   - Use transaction control
   - Validate salary > 0
   - Update ModifiedDate automatically

C. INSTEAD OF INSERT Trigger (20 points)
   - View: OrderEntry (Order JOIN Customer)
   - Auto-generate OrderID
   - Validate customer credit limit
   - Set OrderDate to current date
   - Insert into both tables
   - Log to AuditLog table
*/

-- Your solution for Exercise 7:











/*
================================================================================
EXERCISE 8: COMPLEX VIEW UPDATES (50 points)
================================================================================

Create a complex updatable view with full DML support:

View: OrderManagement
- Joins: Order, OrderItem, Product, Customer
- Show: All order and item details

Requirements:
A. INSTEAD OF INSERT (15 points)
   - Insert order and items
   - Validate stock availability
   - Update product stock
   - Calculate order total
   - Handle errors properly

B. INSTEAD OF UPDATE (15 points)
   - Update order status
   - Update item quantities
   - Adjust product stock for quantity changes
   - Prevent updates to shipped orders
   - Recalculate order total

C. INSTEAD OF DELETE (20 points)
   - Restore product stock
   - Delete order items
   - Delete order if no items remain
   - Log deletion to AuditLog
   - Use proper transaction control
*/

-- Your solution for Exercise 8:











/*
================================================================================
SCORING AND SOLUTIONS
================================================================================

SCORING RUBRIC:
---------------
Exercise 1: 40 points  - Basic Views
Exercise 2: 50 points  - Security Views
Exercise 3: 60 points  - Aggregate Views
Exercise 4: 40 points  - Indexed Views
Exercise 5: 50 points  - Hiding Complexity
Exercise 6: 50 points  - Partitioned Views
Exercise 7: 60 points  - Updatable Views
Exercise 8: 50 points  - Complex Updates
---------------
Total: 400 points

GRADING SCALE:
360-400: Excellent - Master level understanding
320-359: Good - Strong understanding
280-319: Fair - Adequate understanding
240-279: Needs work - Review chapter
< 240:   Review required - Re-study concepts


STOP HERE - ATTEMPT ALL EXERCISES BEFORE VIEWING SOLUTIONS
═══════════════════════════════════════════════════════════════════════════
*/
GO

PRINT 'Attempt all exercises before scrolling down to solutions!';
PRINT '';
PRINT 'Self-assess your solutions:';
PRINT '- Does it meet all requirements?';
PRINT '- Does it handle edge cases?';
PRINT '- Is it efficient?';
PRINT '- Is it well-documented?';
PRINT '';
PRINT 'Total your points and check the grading scale.';
GO

-- Force page break in output
RAISERROR('', 0, 1) WITH NOWAIT;
GO
RAISERROR('', 0, 1) WITH NOWAIT;
GO
RAISERROR('', 0, 1) WITH NOWAIT;
GO

/*
================================================================================
SOLUTIONS
================================================================================
*/

PRINT '========================================';
PRINT 'EXERCISE 1 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 1A: ActiveProducts (10 points)
CREATE VIEW ActiveProducts AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.UnitPrice,
    p.StockQuantity
FROM Product p
INNER JOIN Category c ON p.CategoryID = c.CategoryID
WHERE p.IsActive = 1;
GO

-- Test
SELECT * FROM ActiveProducts ORDER BY CategoryName, ProductName;
GO

-- Solution 1B: EmployeeDirectory (10 points)
CREATE VIEW EmployeeDirectory AS
SELECT 
    e.EmployeeName,
    e.Title,
    d.DepartmentName,
    e.Email
FROM Employee e
INNER JOIN Department d ON e.DepartmentID = d.DepartmentID
WHERE e.IsActive = 1;
GO

-- Test
SELECT * FROM EmployeeDirectory ORDER BY DepartmentName, EmployeeName;
GO

-- Solution 1C: PendingOrders (10 points)
CREATE VIEW PendingOrders AS
SELECT 
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    e.EmployeeName,
    o.TotalAmount
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN Employee e ON o.EmployeeID = e.EmployeeID
WHERE o.Status = 'Pending';
GO

-- Test
SELECT * FROM PendingOrders ORDER BY OrderDate;
GO

-- Solution 1D: LowStockProducts (10 points)
CREATE VIEW LowStockProducts AS
SELECT 
    p.ProductName,
    c.CategoryName AS Category,
    p.StockQuantity AS CurrentStock,
    p.ReorderLevel,
    p.ReorderLevel - p.StockQuantity AS UnitsBelow
FROM Product p
INNER JOIN Category c ON p.CategoryID = c.CategoryID
WHERE p.StockQuantity <= p.ReorderLevel
  AND p.IsActive = 1;
GO

-- Test
SELECT * FROM LowStockProducts ORDER BY UnitsBelow DESC;
GO

PRINT '========================================';
PRINT 'EXERCISE 2 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 2A: EmployeeSalaryMasked (15 points)
CREATE VIEW EmployeeSalaryMasked AS
SELECT 
    e.EmployeeID,
    e.EmployeeName,
    d.DepartmentName,
    e.Title,
    e.Email,
    '***-**-' + RIGHT(e.SSN, 4) AS SSN_Masked,
    CASE 
        WHEN e.Salary < 50000 THEN '$0-$50K'
        WHEN e.Salary < 75000 THEN '$50K-$75K'
        WHEN e.Salary < 100000 THEN '$75K-$100K'
        ELSE '$100K+'
    END AS SalaryRange,
    e.HireDate,
    e.IsActive
FROM Employee e
INNER JOIN Department d ON e.DepartmentID = d.DepartmentID;
GO

-- Test
SELECT * FROM EmployeeSalaryMasked ORDER BY EmployeeName;
GO

-- Solution 2B: CustomerContactRestricted (15 points)
CREATE VIEW CustomerContactRestricted AS
SELECT 
    CustomerID,
    CustomerName,
    '****@' + SUBSTRING(Email, CHARINDEX('@', Email) + 1, LEN(Email)) AS Email_Masked,
    LEFT(Phone, 3) + '-*****' AS Phone_Masked,
    Region,
    CustomerType,
    CreditLimit,
    IsActive,
    JoinDate
FROM Customer
WHERE Region = 'North';  -- Can be parameterized or dynamic
GO

-- Test
SELECT * FROM CustomerContactRestricted;
GO

-- Solution 2C: OrderDetailsWithROLS (20 points)
CREATE VIEW OrderDetailsWithROLS AS
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.TotalAmount,
    c.CustomerName,
    e.EmployeeID,
    e.EmployeeName,
    oi.ProductID,
    p.ProductName,
    oi.Quantity,
    oi.UnitPrice,
    oi.Discount,
    oi.LineTotal
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN Employee e ON o.EmployeeID = e.EmployeeID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
WHERE e.Email = SUSER_NAME() + '@company.com'  -- Row-level security
   OR IS_MEMBER('db_owner') = 1  -- Admins see all
WITH CHECK OPTION;
GO

PRINT '========================================';
PRINT 'EXERCISE 3 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 3A: CustomerOrderSummary (15 points)
CREATE VIEW CustomerOrderSummary AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Region,
    c.CustomerType,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ISNULL(SUM(o.TotalAmount), 0) AS TotalRevenue,
    CASE 
        WHEN COUNT(DISTINCT o.OrderID) > 0 
        THEN SUM(o.TotalAmount) / COUNT(DISTINCT o.OrderID)
        ELSE 0 
    END AS AvgOrderValue,
    MIN(o.OrderDate) AS FirstOrderDate,
    MAX(o.OrderDate) AS LastOrderDate,
    DATEDIFF(DAY, MAX(o.OrderDate), CAST(GETDATE() AS DATE)) AS DaysSinceLastOrder
FROM Customer c
LEFT JOIN [Order] o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.Region, c.CustomerType;
GO

-- Test
SELECT * FROM CustomerOrderSummary ORDER BY TotalRevenue DESC;
GO

-- Solution 3B: ProductPerformance (15 points)
CREATE VIEW ProductPerformance AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    SUM(oi.Quantity) AS TotalOrdered,
    SUM(oi.LineTotal) AS TotalRevenue,
    AVG(oi.Discount) * 100 AS AvgDiscountPct,
    SUM(oi.LineTotal) - SUM(oi.Quantity * p.Cost) AS ProfitMargin
FROM Product p
INNER JOIN Category c ON p.CategoryID = c.CategoryID
INNER JOIN OrderItem oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Cost;
GO

-- Test
SELECT * FROM ProductPerformance ORDER BY ProfitMargin DESC;
GO

-- Solution 3C: DailySalesSummary (15 points)
CREATE VIEW DailySalesSummary AS
SELECT 
    o.OrderDate,
    DATENAME(WEEKDAY, o.OrderDate) AS DayOfWeek,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(o.TotalAmount) AS TotalRevenue,
    COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
    COUNT(DISTINCT oi.ProductID) AS UniqueProducts,
    AVG(o.TotalAmount) AS AvgOrderValue
FROM [Order] o
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
GROUP BY o.OrderDate;
GO

-- Test
SELECT * FROM DailySalesSummary ORDER BY OrderDate;
GO

-- Solution 3D: DepartmentPayroll (15 points)
CREATE VIEW DepartmentPayroll AS
SELECT 
    d.DepartmentName,
    COUNT(*) AS EmployeeCount,
    SUM(e.Salary) AS TotalPayroll,
    AVG(e.Salary) AS AvgSalary,
    MIN(e.Salary) AS MinSalary,
    MAX(e.Salary) AS MaxSalary,
    SUM(e.Salary) * 100.0 / (SELECT SUM(Salary) FROM Employee WHERE IsActive = 1) AS PayrollPct
FROM Department d
INNER JOIN Employee e ON d.DepartmentID = e.DepartmentID
WHERE e.IsActive = 1
GROUP BY d.DepartmentName;
GO

-- Test
SELECT * FROM DepartmentPayroll ORDER BY TotalPayroll DESC;
GO

PRINT '========================================';
PRINT 'EXERCISE 4 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 4: Indexed View (40 points)
CREATE VIEW ProductSalesMetrics
WITH SCHEMABINDING
AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    COUNT_BIG(*) AS TotalOrders,
    SUM(oi.Quantity) AS TotalQuantitySold,
    SUM(oi.LineTotal) AS TotalRevenue
FROM dbo.Product p
INNER JOIN dbo.OrderItem oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, p.CategoryID;
GO

-- Create clustered index (materializes the view)
CREATE UNIQUE CLUSTERED INDEX IX_ProductSalesMetrics_ProductID
ON ProductSalesMetrics (ProductID);
GO

-- Create nonclustered index for revenue queries
CREATE NONCLUSTERED INDEX IX_ProductSalesMetrics_Revenue
ON ProductSalesMetrics (TotalRevenue DESC) 
INCLUDE (ProductName, TotalQuantitySold);
GO

-- Test performance
SET STATISTICS IO ON;
GO

-- Query indexed view
SELECT TOP 10 * FROM ProductSalesMetrics 
ORDER BY TotalRevenue DESC;
GO

SET STATISTICS IO OFF;
GO

PRINT '========================================';
PRINT 'EXERCISE 5 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 5: ComprehensiveOrderDetails (50 points)
/*
Comprehensive view joining all order-related tables for complete order information.
Includes customer, employee, department, product, and category data.
*/
CREATE VIEW ComprehensiveOrderDetails AS
SELECT 
    -- Order information
    o.OrderID,
    o.OrderDate,
    o.ShipDate,
    o.Status,
    o.TotalAmount AS OrderTotal,
    
    -- Customer information
    c.CustomerID,
    c.CustomerName,
    c.Region,
    c.CustomerType,
    c.Email AS CustomerEmail,
    
    -- Employee and Department information
    e.EmployeeID,
    e.EmployeeName AS SalesRep,
    d.DepartmentName,
    
    -- Order Item information
    oi.OrderItemID,
    oi.Quantity,
    oi.UnitPrice,
    oi.Discount,
    oi.LineTotal,
    
    -- Product information
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    p.Cost AS ProductCost,
    
    -- Calculated fields
    oi.LineTotal - (p.Cost * oi.Quantity) AS LineProfit,
    (oi.LineTotal - (p.Cost * oi.Quantity)) / NULLIF(oi.LineTotal, 0) * 100 AS ProfitMarginPct
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN Employee e ON o.EmployeeID = e.EmployeeID
INNER JOIN Department d ON e.DepartmentID = d.DepartmentID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
INNER JOIN Category cat ON p.CategoryID = cat.CategoryID;
GO

-- Bonus: Simplified summary view
CREATE VIEW OrderSummary AS
SELECT 
    OrderID,
    OrderDate,
    CustomerName,
    SUM(LineTotal) AS TotalRevenue,
    SUM(LineProfit) AS TotalProfit,
    COUNT(DISTINCT ProductID) AS ProductCount,
    SUM(Quantity) AS TotalItems
FROM ComprehensiveOrderDetails
GROUP BY OrderID, OrderDate, CustomerName;
GO

-- Test
SELECT TOP 5 * FROM ComprehensiveOrderDetails;
SELECT * FROM OrderSummary ORDER BY TotalProfit DESC;
GO

PRINT '========================================';
PRINT 'EXERCISE 6 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 6: Partitioned View (50 points)

-- Create partition tables
CREATE TABLE Orders_Current (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL 
        CHECK (OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))),
    TotalAmount DECIMAL(12,2),
    Status NVARCHAR(20)
);

CREATE TABLE Orders_Recent (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL 
        CHECK (OrderDate >= DATEADD(DAY, -90, CAST(GETDATE() AS DATE))
           AND OrderDate < DATEADD(DAY, -30, CAST(GETDATE() AS DATE))),
    TotalAmount DECIMAL(12,2),
    Status NVARCHAR(20)
);

CREATE TABLE Orders_Archive (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL 
        CHECK (OrderDate < DATEADD(DAY, -90, CAST(GETDATE() AS DATE))),
    TotalAmount DECIMAL(12,2),
    Status NVARCHAR(20)
);
GO

-- Create partitioned view
CREATE VIEW Orders_All AS
SELECT OrderID, CustomerID, OrderDate, TotalAmount, Status, 'Current' AS Partition
FROM Orders_Current
UNION ALL
SELECT OrderID, CustomerID, OrderDate, TotalAmount, Status, 'Recent' AS Partition
FROM Orders_Recent
UNION ALL
SELECT OrderID, CustomerID, OrderDate, TotalAmount, Status, 'Archive' AS Partition
FROM Orders_Archive;
GO

-- Insert test data
INSERT INTO Orders_Current VALUES 
    (1001, 1, DATEADD(DAY, -5, CAST(GETDATE() AS DATE)), 1000.00, 'Pending');

INSERT INTO Orders_Recent VALUES 
    (1002, 2, DATEADD(DAY, -45, CAST(GETDATE() AS DATE)), 1500.00, 'Delivered');

INSERT INTO Orders_Archive VALUES 
    (1003, 3, DATEADD(DAY, -120, CAST(GETDATE() AS DATE)), 2000.00, 'Delivered');
GO

-- Test partition elimination
SELECT * FROM Orders_All 
WHERE OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
-- Should only scan Orders_Current

SELECT * FROM Orders_All 
WHERE OrderDate < DATEADD(DAY, -90, CAST(GETDATE() AS DATE));
-- Should only scan Orders_Archive
GO

PRINT '========================================';
PRINT 'EXERCISE 7 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 7A: ProductInventory (20 points)
CREATE VIEW ProductInventory AS
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    UnitPrice,
    StockQuantity,
    IsActive
FROM Product
WHERE IsActive = 1
WITH CHECK OPTION;
GO

-- Test INSERT
INSERT INTO ProductInventory (ProductName, CategoryID, UnitPrice, StockQuantity, IsActive)
VALUES ('Test Product', 1, 99.99, 50, 1);
GO

-- Test UPDATE
UPDATE ProductInventory 
SET StockQuantity = 75 
WHERE ProductName = 'Test Product';
GO

-- Test DELETE
DELETE FROM ProductInventory WHERE ProductName = 'Test Product';
GO

-- Solution 7B: EmployeeInfo with UPDATE trigger (20 points)
CREATE VIEW EmployeeInfo AS
SELECT 
    e.EmployeeID,
    e.EmployeeName,
    e.Title,
    e.Salary,
    d.DepartmentID,
    d.DepartmentName
FROM Employee e
INNER JOIN Department d ON e.DepartmentID = d.DepartmentID;
GO

CREATE TRIGGER trg_EmployeeInfo_Update
ON EmployeeInfo
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate salary
    IF EXISTS (SELECT 1 FROM inserted WHERE Salary <= 0)
    BEGIN
        RAISERROR('Salary must be greater than 0', 16, 1);
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
    -- Update Employee
    UPDATE e
    SET 
        e.EmployeeName = i.EmployeeName,
        e.Title = i.Title,
        e.Salary = i.Salary
    FROM Employee e
    INNER JOIN inserted i ON e.EmployeeID = i.EmployeeID;
    
    -- Update Department
    UPDATE d
    SET d.DepartmentName = i.DepartmentName
    FROM Department d
    INNER JOIN inserted i ON d.DepartmentID = i.DepartmentID;
    
    -- Update modified date
    ALTER TABLE Product ADD ModifiedDate DATETIME DEFAULT GETDATE();
    
    COMMIT TRANSACTION;
    PRINT 'Employee and department updated successfully';
END;
GO

-- Solution 7C: OrderEntry with INSERT trigger (20 points)
CREATE VIEW OrderEntry AS
SELECT 
    o.OrderID,
    o.CustomerID,
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID;
GO

CREATE TRIGGER trg_OrderEntry_Insert
ON OrderEntry
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount, Status)
    SELECT 
        CustomerID,
        ISNULL(OrderDate, CAST(GETDATE() AS DATE)),
        ISNULL(TotalAmount, 0),
        'Pending'
    FROM inserted;
    
    -- Log to audit
    INSERT INTO AuditLog (TableName, Operation, RecordID, Details)
    SELECT 
        'Order',
        'INSERT',
        SCOPE_IDENTITY(),
        'Order created for customer: ' + CustomerName
    FROM inserted;
    
    COMMIT TRANSACTION;
    PRINT 'Order created and logged';
END;
GO

PRINT '========================================';
PRINT 'EXERCISE 8 SOLUTIONS';
PRINT '========================================';
GO

-- Solution 8: OrderManagement (50 points)
CREATE VIEW OrderManagement AS
SELECT 
    o.OrderID,
    o.CustomerID,
    c.CustomerName,
    o.OrderDate,
    o.Status,
    oi.OrderItemID,
    oi.ProductID,
    p.ProductName,
    oi.Quantity,
    oi.UnitPrice,
    oi.Discount,
    oi.LineTotal,
    p.StockQuantity
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID;
GO

-- INSTEAD OF INSERT
CREATE TRIGGER trg_OrderManagement_Insert
ON OrderManagement
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate stock
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN Product p ON i.ProductID = p.ProductID
            WHERE i.Quantity > p.StockQuantity
        )
        BEGIN
            RAISERROR('Insufficient stock', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Insert order
        INSERT INTO [Order] (CustomerID, OrderDate, Status, TotalAmount)
        SELECT DISTINCT 
            CustomerID,
            ISNULL(OrderDate, CAST(GETDATE() AS DATE)),
            ISNULL(Status, 'Pending'),
            0
        FROM inserted;
        
        DECLARE @OrderID INT = SCOPE_IDENTITY();
        
        -- Insert items
        INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, Discount)
        SELECT @OrderID, ProductID, Quantity, UnitPrice, ISNULL(Discount, 0)
        FROM inserted;
        
        -- Update stock
        UPDATE p
        SET p.StockQuantity = p.StockQuantity - i.Quantity
        FROM Product p
        INNER JOIN inserted i ON p.ProductID = i.ProductID;
        
        -- Update order total
        UPDATE [Order]
        SET TotalAmount = (SELECT SUM(LineTotal) FROM OrderItem WHERE OrderID = @OrderID)
        WHERE OrderID = @OrderID;
        
        COMMIT TRANSACTION;
        PRINT 'Order created successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- INSTEAD OF UPDATE
CREATE TRIGGER trg_OrderManagement_Update
ON OrderManagement
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Prevent updates to shipped orders
        IF EXISTS (
            SELECT 1 FROM deleted 
            WHERE Status IN ('Shipped', 'Delivered')
        )
        BEGIN
            RAISERROR('Cannot modify shipped/delivered orders', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Adjust stock for quantity changes
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + (d.Quantity - i.Quantity)
        FROM Product p
        INNER JOIN inserted i ON p.ProductID = i.ProductID
        INNER JOIN deleted d ON i.OrderItemID = d.OrderItemID;
        
        -- Update order
        UPDATE o
        SET o.Status = i.Status
        FROM [Order] o
        INNER JOIN inserted i ON o.OrderID = i.OrderID;
        
        -- Update items
        UPDATE oi
        SET 
            oi.Quantity = i.Quantity,
            oi.UnitPrice = i.UnitPrice,
            oi.Discount = i.Discount
        FROM OrderItem oi
        INNER JOIN inserted i ON oi.OrderItemID = i.OrderItemID;
        
        -- Recalculate order totals
        UPDATE o
        SET o.TotalAmount = (
            SELECT SUM(LineTotal) 
            FROM OrderItem 
            WHERE OrderID = o.OrderID
        )
        FROM [Order] o
        WHERE o.OrderID IN (SELECT DISTINCT OrderID FROM inserted);
        
        COMMIT TRANSACTION;
        PRINT 'Order updated successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- INSTEAD OF DELETE
CREATE TRIGGER trg_OrderManagement_Delete
ON OrderManagement
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    -- Restore stock
    UPDATE p
    SET p.StockQuantity = p.StockQuantity + d.Quantity
    FROM Product p
    INNER JOIN deleted d ON p.ProductID = d.ProductID;
    
    -- Log deletion
    INSERT INTO AuditLog (TableName, Operation, RecordID, Details)
    SELECT 
        'OrderItem',
        'DELETE',
        OrderItemID,
        'Deleted order item for Order ' + CAST(OrderID AS VARCHAR(10))
    FROM deleted;
    
    -- Delete items
    DELETE oi
    FROM OrderItem oi
    INNER JOIN deleted d ON oi.OrderItemID = d.OrderItemID;
    
    -- Delete orders with no items
    DELETE o
    FROM [Order] o
    WHERE NOT EXISTS (SELECT 1 FROM OrderItem WHERE OrderID = o.OrderID)
    AND o.OrderID IN (SELECT DISTINCT OrderID FROM deleted);
    
    COMMIT TRANSACTION;
    PRINT 'Order items deleted and stock restored';
END;
GO

/*
================================================================================
ASSESSMENT COMPLETE
================================================================================

Congratulations on completing the Views chapter assessment!

Review your solutions:
1. Compare with provided solutions
2. Note any differences in approach
3. Test edge cases
4. Consider performance implications
5. Document lessons learned

Key takeaways from this chapter:
- Views provide abstraction and security
- Indexed views improve query performance
- Partitioned views scale large datasets
- INSTEAD OF triggers enable complex updates
- Proper design prevents common pitfalls
- Always consider security and performance

Next Chapter: 15 - Metadata
Continue your SQL mastery journey!

================================================================================
*/
