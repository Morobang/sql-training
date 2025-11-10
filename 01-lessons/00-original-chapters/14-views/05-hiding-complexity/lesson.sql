/*
================================================================================
LESSON 14.5: HIDING COMPLEXITY WITH VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Simplify complex multi-table joins
2. Abstract business logic into views
3. Create user-friendly data interfaces
4. Hide database schema changes
5. Implement layered view architectures
6. Optimize complex query patterns
7. Apply best practices for abstraction

Business Context:
-----------------
Views hide database complexity, making it easier for users and applications
to access data. They abstract complex joins, calculations, and business rules
into simple SELECT statements. This improves developer productivity, reduces
errors, and makes schema changes less disruptive.

Database: RetailStore
Complexity: Intermediate-Advanced
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: SIMPLIFYING MULTI-TABLE JOINS
================================================================================

Complex queries with many joins are error-prone and hard to maintain.
Views encapsulate this complexity.
*/

-- Create sample schema (complex business model)
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS CustomerAddress;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS ProductCategory;
DROP TABLE IF EXISTS Warehouse;
DROP TABLE IF EXISTS Inventory;
GO

CREATE TABLE ProductCategory (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    ParentCategoryID INT NULL
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT FOREIGN KEY REFERENCES ProductCategory(CategoryID),
    UnitPrice DECIMAL(10,2) NOT NULL,
    IsDiscontinued BIT NOT NULL DEFAULT 0
);

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    CustomerType NVARCHAR(20) NOT NULL,
    CreditLimit DECIMAL(10,2) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE CustomerAddress (
    AddressID INT PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    AddressType NVARCHAR(20) NOT NULL,
    Street NVARCHAR(200),
    City NVARCHAR(100),
    State NVARCHAR(50),
    Country NVARCHAR(50),
    PostalCode NVARCHAR(20)
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL,
    ShippingAddressID INT FOREIGN KEY REFERENCES CustomerAddress(AddressID),
    Status NVARCHAR(20) NOT NULL,
    Notes NVARCHAR(MAX)
);

CREATE TABLE OrderItem (
    OrderItemID INT PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0
);

CREATE TABLE Warehouse (
    WarehouseID INT PRIMARY KEY,
    WarehouseName NVARCHAR(100) NOT NULL,
    City NVARCHAR(100),
    State NVARCHAR(50)
);

CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY,
    ProductID INT FOREIGN KEY REFERENCES Product(ProductID),
    WarehouseID INT FOREIGN KEY REFERENCES Warehouse(WarehouseID),
    QuantityOnHand INT NOT NULL,
    ReorderLevel INT NOT NULL
);
GO

-- Insert sample data
INSERT INTO ProductCategory VALUES 
    (1, 'Electronics', NULL),
    (2, 'Computers', 1),
    (3, 'Accessories', 1);

INSERT INTO Product VALUES
    (1, 'Laptop Pro', 2, 1299.99, 0),
    (2, 'Wireless Mouse', 3, 29.99, 0),
    (3, 'USB-C Hub', 3, 49.99, 0);

INSERT INTO Customer VALUES
    (1, 'TechCorp Inc', 'Enterprise', 50000.00, 1),
    (2, 'Small Business LLC', 'SMB', 10000.00, 1);

INSERT INTO CustomerAddress VALUES
    (1, 1, 'Billing', '123 Main St', 'New York', 'NY', 'USA', '10001'),
    (2, 1, 'Shipping', '456 Park Ave', 'New York', 'NY', 'USA', '10002'),
    (3, 2, 'Billing', '789 Oak Rd', 'Boston', 'MA', 'USA', '02101');

INSERT INTO [Order] VALUES
    (1, 1, '2024-11-01', 2, 'Completed', 'Rush order'),
    (2, 2, '2024-11-05', 3, 'Pending', NULL);

INSERT INTO OrderItem VALUES
    (1, 1, 1, 5, 1299.99, 0.10),
    (2, 1, 2, 10, 29.99, 0.00),
    (3, 2, 3, 20, 49.99, 0.05);

INSERT INTO Warehouse VALUES
    (1, 'East Coast DC', 'Newark', 'NJ'),
    (2, 'West Coast DC', 'Los Angeles', 'CA');

INSERT INTO Inventory VALUES
    (1, 1, 1, 50, 10),
    (2, 2, 1, 200, 50),
    (3, 3, 2, 150, 30);
GO

-- BEFORE: Complex query users need to write
-- (8 tables joined, lots of complexity)
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    c.CustomerName,
    c.CustomerType,
    shipping.City AS ShippingCity,
    shipping.State AS ShippingState,
    p.ProductName,
    cat.CategoryName,
    parent.CategoryName AS ParentCategory,
    oi.Quantity,
    oi.UnitPrice,
    oi.Discount,
    oi.Quantity * oi.UnitPrice * (1 - oi.Discount) AS LineTotal,
    w.WarehouseName,
    inv.QuantityOnHand
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN CustomerAddress shipping ON o.ShippingAddressID = shipping.AddressID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
INNER JOIN ProductCategory cat ON p.CategoryID = cat.CategoryID
LEFT JOIN ProductCategory parent ON cat.ParentCategoryID = parent.CategoryID
INNER JOIN Inventory inv ON p.ProductID = inv.ProductID
INNER JOIN Warehouse w ON inv.WarehouseID = w.WarehouseID
WHERE o.Status = 'Completed';
GO

-- AFTER: Simple view encapsulates all complexity
CREATE VIEW OrderDetails AS
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.Notes,
    -- Customer info
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.CreditLimit,
    -- Shipping address
    shipping.City AS ShippingCity,
    shipping.State AS ShippingState,
    shipping.Country AS ShippingCountry,
    shipping.PostalCode AS ShippingPostalCode,
    -- Product info
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    parent.CategoryName AS ParentCategory,
    -- Order item details
    oi.OrderItemID,
    oi.Quantity,
    oi.UnitPrice,
    oi.Discount,
    oi.Quantity * oi.UnitPrice * (1 - oi.Discount) AS LineTotal,
    -- Inventory info
    w.WarehouseName,
    w.City AS WarehouseCity,
    inv.QuantityOnHand,
    inv.ReorderLevel
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN CustomerAddress shipping ON o.ShippingAddressID = shipping.AddressID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
INNER JOIN ProductCategory cat ON p.CategoryID = cat.CategoryID
LEFT JOIN ProductCategory parent ON cat.ParentCategoryID = parent.CategoryID
INNER JOIN Inventory inv ON p.ProductID = inv.ProductID
INNER JOIN Warehouse w ON inv.WarehouseID = w.WarehouseID;
GO

-- Now users query the view (simple!)
SELECT 
    OrderID,
    OrderDate,
    CustomerName,
    ProductName,
    CategoryName,
    Quantity,
    LineTotal
FROM OrderDetails
WHERE Status = 'Completed'
ORDER BY OrderDate, OrderID;
GO

/*
OUTPUT:
OrderID  OrderDate   CustomerName   ProductName      CategoryName  Quantity  LineTotal
-------  ----------  -------------  ---------------  ------------  --------  ---------
1        2024-11-01  TechCorp Inc   Laptop Pro       Computers     5         5849.96
1        2024-11-01  TechCorp Inc   Wireless Mouse   Accessories   10        299.90

Much simpler for users!
*/

/*
================================================================================
PART 2: ABSTRACTING BUSINESS LOGIC
================================================================================

Encapsulate business rules and calculations in views.
*/

-- Example 1: Customer classification logic
CREATE VIEW CustomerClassification AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.CreditLimit,
    c.IsActive,
    -- Business rule: Calculate total orders
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) AS TotalRevenue,
    -- Business rule: Customer status
    CASE 
        WHEN c.IsActive = 0 THEN 'Inactive'
        WHEN COUNT(DISTINCT o.OrderID) = 0 THEN 'New'
        WHEN SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) > 10000 THEN 'VIP'
        WHEN SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) > 5000 THEN 'Preferred'
        ELSE 'Standard'
    END AS CustomerStatus,
    -- Business rule: Credit utilization
    CASE 
        WHEN c.CreditLimit > 0 
        THEN (ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) / c.CreditLimit) * 100
        ELSE 0 
    END AS CreditUtilization,
    -- Business rule: Risk level
    CASE 
        WHEN c.IsActive = 0 THEN 'Not Applicable'
        WHEN c.CreditLimit > 0 AND (ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) / c.CreditLimit) > 0.9 THEN 'High Risk'
        WHEN c.CreditLimit > 0 AND (ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) / c.CreditLimit) > 0.7 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskLevel
FROM Customer c
LEFT JOIN [Order] o ON c.CustomerID = o.CustomerID
LEFT JOIN OrderItem oi ON o.OrderID = oi.OrderID
GROUP BY c.CustomerID, c.CustomerName, c.CustomerType, c.CreditLimit, c.IsActive;
GO

SELECT * FROM CustomerClassification ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
CustomerID  CustomerName        CustomerType  CreditLimit  IsActive  TotalOrders  TotalRevenue  CustomerStatus  CreditUtilization  RiskLevel
----------  ------------------  ------------  -----------  --------  -----------  ------------  --------------  -----------------  ----------
1           TechCorp Inc        Enterprise    50000.00     1         1            6149.86       Preferred       12.30              Low Risk
2           Small Business LLC  SMB           10000.00     1         1            949.81        Standard        9.50               Low Risk

All business logic is centralized in the view!
*/

-- Example 2: Product profitability (complex calculation)
CREATE VIEW ProductProfitability AS
SELECT 
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    p.UnitPrice AS ListPrice,
    -- Business rule: Average selling price (with discounts)
    AVG(oi.UnitPrice * (1 - oi.Discount)) AS AvgSellingPrice,
    -- Business rule: Discount rate
    AVG(oi.Discount) * 100 AS AvgDiscountPct,
    -- Sales metrics
    COUNT(DISTINCT oi.OrderID) AS OrderCount,
    SUM(oi.Quantity) AS TotalSold,
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) AS TotalRevenue,
    -- Business rule: Revenue per order
    SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) / COUNT(DISTINCT oi.OrderID) AS RevenuePerOrder,
    -- Business rule: Profitability classification
    CASE 
        WHEN SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) > 5000 THEN 'High Value'
        WHEN SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)) > 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS ProfitabilityClass
FROM Product p
INNER JOIN ProductCategory cat ON p.CategoryID = cat.CategoryID
LEFT JOIN OrderItem oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, cat.CategoryName, p.UnitPrice;
GO

SELECT * FROM ProductProfitability ORDER BY TotalRevenue DESC;
GO

/*
================================================================================
PART 3: LAYERED VIEW ARCHITECTURE
================================================================================

Build complex views on top of simpler views (layer by layer).
*/

-- Layer 1: Base customer view
CREATE VIEW CustomerBase AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.CreditLimit,
    c.IsActive,
    billing.City AS BillingCity,
    billing.State AS BillingState,
    billing.Country AS Country
FROM Customer c
LEFT JOIN CustomerAddress billing ON c.CustomerID = billing.CustomerID 
    AND billing.AddressType = 'Billing';
GO

-- Layer 2: Customer metrics (builds on CustomerBase)
CREATE VIEW CustomerMetrics AS
SELECT 
    cb.*,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) AS TotalRevenue,
    ISNULL(AVG(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) AS AvgItemValue
FROM CustomerBase cb
LEFT JOIN [Order] o ON cb.CustomerID = o.CustomerID
LEFT JOIN OrderItem oi ON o.OrderID = oi.OrderID
GROUP BY 
    cb.CustomerID, cb.CustomerName, cb.CustomerType, cb.CreditLimit,
    cb.IsActive, cb.BillingCity, cb.BillingState, cb.Country;
GO

-- Layer 3: Customer insights (builds on CustomerMetrics)
CREATE VIEW CustomerInsights AS
SELECT 
    *,
    CASE 
        WHEN TotalRevenue > 10000 THEN 'VIP'
        WHEN TotalRevenue > 5000 THEN 'Preferred'
        WHEN TotalRevenue > 0 THEN 'Standard'
        ELSE 'New'
    END AS Tier,
    CASE 
        WHEN CreditLimit > 0 THEN (TotalRevenue / CreditLimit) * 100
        ELSE 0 
    END AS CreditUtilizationPct,
    CASE 
        WHEN TotalOrders > 0 THEN TotalRevenue / TotalOrders
        ELSE 0 
    END AS AvgOrderValue
FROM CustomerMetrics;
GO

-- Query top-level view (all layers combined)
SELECT 
    CustomerName,
    Country,
    Tier,
    TotalOrders,
    TotalRevenue,
    AvgOrderValue,
    CreditUtilizationPct
FROM CustomerInsights
WHERE IsActive = 1
ORDER BY TotalRevenue DESC;
GO

/*
OUTPUT:
CustomerName        Country  Tier       TotalOrders  TotalRevenue  AvgOrderValue  CreditUtilizationPct
------------------  -------  ---------  -----------  ------------  -------------  --------------------
TechCorp Inc        USA      Preferred  1            6149.86       6149.86        12.30
Small Business LLC  USA      Standard   1            949.81        949.81         9.50

Layered architecture keeps each view simple and focused!
*/

/*
================================================================================
PART 4: HIDING SCHEMA CHANGES
================================================================================

Views provide abstraction that protects applications from schema changes.
*/

-- Example: Original table structure
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200),
    Department NVARCHAR(100)
);

INSERT INTO Employee VALUES
    (1, 'John Smith', 'john@company.com', 'Sales'),
    (2, 'Jane Doe', 'jane@company.com', 'Marketing');
GO

-- Create view with current structure
CREATE VIEW EmployeeInfo AS
SELECT 
    EmployeeID,
    FullName,
    Email,
    Department
FROM Employee;
GO

-- Applications query the view
SELECT * FROM EmployeeInfo;
GO

/*
NOW: Schema change required - split FullName into FirstName/LastName
*/

-- Add new columns
ALTER TABLE Employee ADD FirstName NVARCHAR(100), LastName NVARCHAR(100);
GO

-- Migrate data
UPDATE Employee SET 
    FirstName = LEFT(FullName, CHARINDEX(' ', FullName) - 1),
    LastName = SUBSTRING(FullName, CHARINDEX(' ', FullName) + 1, LEN(FullName));
GO

-- Remove old column
ALTER TABLE Employee DROP COLUMN FullName;
GO

-- Update view to maintain compatibility
ALTER VIEW EmployeeInfo AS
SELECT 
    EmployeeID,
    FirstName + ' ' + LastName AS FullName,  -- Reconstruct for backward compatibility
    Email,
    Department,
    FirstName,  -- Also expose new columns
    LastName
FROM Employee;
GO

-- Old queries still work!
SELECT EmployeeID, FullName, Email FROM EmployeeInfo;
GO

/*
OUTPUT:
EmployeeID  FullName    Email
----------  ----------  ------------------
1           John Smith  john@company.com
2           Jane Doe    jane@company.com

Applications using FullName continue to work despite schema change!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Simplify Complex Join
----------------------------------
Create a view that joins all order-related tables and includes:
- Order information
- Customer details (with billing address)
- Product details (with full category hierarchy)
- Calculated total for each order

Make it easy to query without knowing the schema.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Business Logic Abstraction
---------------------------------------
Create a view that implements this business logic:
- Products are "High Demand" if sold > 15 units total
- Products are "Regular Demand" if sold 5-15 units
- Products are "Low Demand" if sold < 5 units
- Include product name, category, total sold, and demand classification

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Layered Architecture
---------------------------------
Create a 3-layer view architecture for products:
Layer 1: ProductBase (product + category info)
Layer 2: ProductSales (Layer 1 + sales metrics)
Layer 3: ProductAnalysis (Layer 2 + classifications and insights)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Simplify Complex Join
CREATE VIEW ComprehensiveOrderView AS
SELECT 
    -- Order info
    o.OrderID,
    o.OrderDate,
    o.Status,
    o.Notes,
    -- Customer info
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    billing.Street AS BillingStreet,
    billing.City AS BillingCity,
    billing.State AS BillingState,
    billing.PostalCode AS BillingPostalCode,
    -- Product info
    p.ProductID,
    p.ProductName,
    p.UnitPrice AS ProductListPrice,
    cat.CategoryName,
    parent.CategoryName AS ParentCategory,
    -- Order item details
    oi.Quantity,
    oi.UnitPrice AS SellingPrice,
    oi.Discount,
    -- Calculated fields
    oi.Quantity * oi.UnitPrice * (1 - oi.Discount) AS LineTotal
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
LEFT JOIN CustomerAddress billing ON c.CustomerID = billing.CustomerID 
    AND billing.AddressType = 'Billing'
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID
INNER JOIN ProductCategory cat ON p.CategoryID = cat.CategoryID
LEFT JOIN ProductCategory parent ON cat.ParentCategoryID = parent.CategoryID;
GO

-- Simple query for users
SELECT OrderID, CustomerName, ProductName, Quantity, LineTotal
FROM ComprehensiveOrderView
WHERE Status = 'Completed'
ORDER BY OrderID;
GO

-- Solution 2: Business Logic Abstraction
CREATE VIEW ProductDemandAnalysis AS
SELECT 
    p.ProductID,
    p.ProductName,
    cat.CategoryName,
    ISNULL(SUM(oi.Quantity), 0) AS TotalSold,
    CASE 
        WHEN ISNULL(SUM(oi.Quantity), 0) > 15 THEN 'High Demand'
        WHEN ISNULL(SUM(oi.Quantity), 0) >= 5 THEN 'Regular Demand'
        ELSE 'Low Demand'
    END AS DemandClassification,
    COUNT(DISTINCT oi.OrderID) AS OrderCount,
    CASE 
        WHEN ISNULL(SUM(oi.Quantity), 0) > 0 
        THEN ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) / SUM(oi.Quantity)
        ELSE 0 
    END AS AvgPricePerUnit
FROM Product p
INNER JOIN ProductCategory cat ON p.CategoryID = cat.CategoryID
LEFT JOIN OrderItem oi ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName, cat.CategoryName;
GO

SELECT * FROM ProductDemandAnalysis ORDER BY TotalSold DESC;
GO

-- Solution 3: Layered Architecture
-- Layer 1: Base product information
CREATE VIEW ProductBase_Layered AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.UnitPrice,
    p.IsDiscontinued,
    cat.CategoryID,
    cat.CategoryName,
    parent.CategoryName AS ParentCategory
FROM Product p
INNER JOIN ProductCategory cat ON p.CategoryID = cat.CategoryID
LEFT JOIN ProductCategory parent ON cat.ParentCategoryID = parent.CategoryID;
GO

-- Layer 2: Add sales metrics
CREATE VIEW ProductSales_Layered AS
SELECT 
    pb.*,
    COUNT(DISTINCT oi.OrderID) AS OrderCount,
    ISNULL(SUM(oi.Quantity), 0) AS TotalSold,
    ISNULL(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.Discount)), 0) AS TotalRevenue,
    ISNULL(AVG(oi.Discount), 0) AS AvgDiscount
FROM ProductBase_Layered pb
LEFT JOIN OrderItem oi ON pb.ProductID = oi.ProductID
GROUP BY 
    pb.ProductID, pb.ProductName, pb.UnitPrice, pb.IsDiscontinued,
    pb.CategoryID, pb.CategoryName, pb.ParentCategory;
GO

-- Layer 3: Add classifications and insights
CREATE VIEW ProductAnalysis_Layered AS
SELECT 
    *,
    CASE 
        WHEN TotalSold > 15 THEN 'High Demand'
        WHEN TotalSold >= 5 THEN 'Regular Demand'
        ELSE 'Low Demand'
    END AS DemandClass,
    CASE 
        WHEN TotalRevenue > 5000 THEN 'Top Performer'
        WHEN TotalRevenue > 1000 THEN 'Good Performer'
        WHEN TotalRevenue > 0 THEN 'Average Performer'
        ELSE 'No Sales'
    END AS PerformanceClass,
    CASE 
        WHEN OrderCount > 0 THEN TotalRevenue / OrderCount
        ELSE 0 
    END AS RevenuePerOrder,
    AvgDiscount * 100 AS AvgDiscountPct
FROM ProductSales_Layered;
GO

-- Query top layer
SELECT 
    ProductName,
    CategoryName,
    TotalSold,
    TotalRevenue,
    DemandClass,
    PerformanceClass
FROM ProductAnalysis_Layered
WHERE IsDiscontinued = 0
ORDER BY TotalRevenue DESC;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. COMPLEXITY HIDING BENEFITS
   - Simpler queries for users
   - Reduced errors
   - Consistent data access
   - Easier maintenance
   - Better security

2. MULTI-TABLE JOIN ABSTRACTION
   - Encapsulate complex joins in views
   - Expose only needed columns
   - Include helpful calculated fields
   - Use meaningful column aliases
   - Document join relationships

3. BUSINESS LOGIC CENTRALIZATION
   - CASE statements for classifications
   - Calculations in one place
   - Consistent business rules
   - Easier to change logic
   - Self-documenting

4. LAYERED ARCHITECTURE
   - Build views on views
   - Each layer adds complexity
   - Keep each layer focused
   - Easier to understand and maintain
   - Promotes reusability

5. SCHEMA CHANGE PROTECTION
   - Views provide abstraction layer
   - Applications query views, not tables
   - Schema changes hidden from apps
   - Backward compatibility maintained
   - Migrations easier

6. PERFORMANCE CONSIDERATIONS
   - Views add abstraction, not computation
   - SQL Server optimizes view queries
   - Be careful with view-on-view performance
   - Consider indexed views for complex logic
   - Test performance regularly

7. BEST PRACTICES
   - Document complex logic
   - Use meaningful view names
   - Keep views focused (single responsibility)
   - Avoid too many layers (3-4 max)
   - Consider indexed views for performance
   - Test with realistic data volumes
   - Version control view definitions

8. WHEN TO USE
   - Complex multi-table joins used repeatedly
   - Business logic applied consistently
   - Schema evolution expected
   - User-friendly interfaces needed
   - Data abstraction required

================================================================================

NEXT STEPS:
-----------
In Lesson 14.6, we'll explore JOINING PARTITIONED DATA:
- Partitioned views
- Distributed partitioned views
- UNION ALL views
- Cross-server queries

Continue to: 06-joining-partitioned-data/lesson.sql

================================================================================
*/
