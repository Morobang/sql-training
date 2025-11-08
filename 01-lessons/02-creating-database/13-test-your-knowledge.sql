-- ============================================================================
-- Lesson 13: Test Your Knowledge - RetailStore Challenges
-- ============================================================================
-- Comprehensive exercises using the RetailStore database
-- Prerequisites: Lessons 01-12 completed

USE RetailStore;
GO

PRINT 'Lesson 13: Test Your Knowledge';
PRINT '==============================';
PRINT '';
PRINT 'Complete these challenges using the RetailStore database';
PRINT 'Solutions are provided at the bottom (try first!)';
PRINT '';

-- ============================================================================
-- CHALLENGE SET 1: Data Retrieval (SELECT)
-- ============================================================================

PRINT 'Challenge Set 1: Data Retrieval';
PRINT '================================';
PRINT '';
PRINT 'Challenge 1.1: List all products in the Electronics category with price > $50';
PRINT 'Challenge 1.2: Show all customers from Washington state (WA)';
PRINT 'Challenge 1.3: Find employees hired in 2020 or later';
PRINT 'Challenge 1.4: Display product name, price, and inventory value (price * qty)';
PRINT 'Challenge 1.5: Show products that need reordering (stock < reorder level)';
PRINT '';

-- ============================================================================
-- CHALLENGE SET 2: Calculations and Formatting
-- ============================================================================

PRINT 'Challenge Set 2: Calculations and Formatting';
PRINT '============================================';
PRINT '';
PRINT 'Challenge 2.1: Calculate profit margin for each product (Price - Cost) / Cost * 100';
PRINT 'Challenge 2.2: Show customer full names and complete addresses';
PRINT 'Challenge 2.3: Display employee tenure in years';
PRINT 'Challenge 2.4: Format product prices as currency with $ sign';
PRINT 'Challenge 2.5: Show order totals (sum of LineTotal from OrderDetails)';
PRINT '';

-- ============================================================================
-- CHALLENGE SET 3: Joining Tables
-- ============================================================================

PRINT 'Challenge Set 3: Joining Tables';
PRINT '================================';
PRINT '';
PRINT 'Challenge 3.1: Show products with their category and supplier names';
PRINT 'Challenge 3.2: List orders with customer names and employee names';
PRINT 'Challenge 3.3: Show order details with product names and prices';
PRINT 'Challenge 3.4: Display employees with their department names and managers';
PRINT 'Challenge 3.5: Create a complete sales report (orders + customers + products)';
PRINT '';

-- ============================================================================
-- CHALLENGE SET 4: Data Modification
-- ============================================================================

PRINT 'Challenge Set 4: Data Modification';
PRINT '==================================';
PRINT '';
PRINT 'Challenge 4.1: Insert a new product in the Furniture category';
PRINT 'Challenge 4.2: Update all Stationery products to give 5% discount';
PRINT 'Challenge 4.3: Increase stock by 20 for all products below reorder level';
PRINT 'Challenge 4.4: Change order status from Pending to Processing';
PRINT 'Challenge 4.5: Soft delete (IsActive = 0) for a specific customer';
PRINT '';

-- ============================================================================
-- CHALLENGE SET 5: Advanced Queries
-- ============================================================================

PRINT 'Challenge Set 5: Advanced Queries';
PRINT '==================================';
PRINT '';
PRINT 'Challenge 5.1: Find the top 3 most expensive products';
PRINT 'Challenge 5.2: Count how many products in each category';
PRINT 'Challenge 5.3: Calculate total sales amount per customer';
PRINT 'Challenge 5.4: Show products never ordered';
PRINT 'Challenge 5.5: Find customers who placed more than 1 order';
PRINT '';

-- ============================================================================
-- SOLUTIONS
-- ============================================================================

PRINT '';
PRINT '========================================';
PRINT 'SOLUTIONS (Scroll down, try first!)';
PRINT '========================================';
PRINT '';
PRINT '';
PRINT '';
PRINT '';
PRINT '';

-- ============================================================================
-- SOLUTIONS: Challenge Set 1
-- ============================================================================

PRINT 'SOLUTIONS: Challenge Set 1 - Data Retrieval';
PRINT '===========================================';
PRINT '';

-- Challenge 1.1
PRINT 'Challenge 1.1: Electronics products > $50';
/*
SELECT 
    p.ProductName,
    p.Price,
    p.QuantityInStock
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics' AND p.Price > 50
ORDER BY p.Price DESC;
*/

-- Challenge 1.2
PRINT 'Challenge 1.2: Customers from Washington';
/*
SELECT 
    FirstName,
    LastName,
    City,
    Email
FROM Sales.Customers
WHERE State = 'WA'
ORDER BY City, LastName;
*/

-- Challenge 1.3
PRINT 'Challenge 1.3: Employees hired 2020 or later';
/*
SELECT 
    FirstName + ' ' + LastName AS EmployeeName,
    JobTitle,
    HireDate
FROM HR.Employees
WHERE YEAR(HireDate) >= 2020
ORDER BY HireDate;
*/

-- Challenge 1.4
PRINT 'Challenge 1.4: Products with inventory value';
/*
SELECT 
    ProductName,
    Price,
    QuantityInStock,
    Price * QuantityInStock AS InventoryValue
FROM Inventory.Products
WHERE QuantityInStock > 0
ORDER BY InventoryValue DESC;
*/

-- Challenge 1.5
PRINT 'Challenge 1.5: Products needing reorder';
/*
SELECT 
    ProductName,
    QuantityInStock AS CurrentStock,
    ReorderLevel,
    ReorderLevel - QuantityInStock AS UnitsNeeded
FROM Inventory.Products
WHERE QuantityInStock < ReorderLevel
ORDER BY UnitsNeeded DESC;
*/

PRINT '';

-- ============================================================================
-- SOLUTIONS: Challenge Set 2
-- ============================================================================

PRINT 'SOLUTIONS: Challenge Set 2 - Calculations';
PRINT '=========================================';
PRINT '';

-- Challenge 2.1
PRINT 'Challenge 2.1: Profit margin calculation';
/*
SELECT 
    ProductName,
    Price,
    Cost,
    Price - Cost AS Profit,
    ROUND((Price - Cost) / Cost * 100, 2) AS [Profit Margin %]
FROM Inventory.Products
WHERE Cost IS NOT NULL AND Cost > 0
ORDER BY [Profit Margin %] DESC;
*/

-- Challenge 2.2
PRINT 'Challenge 2.2: Customer full addresses';
/*
SELECT 
    FirstName + ' ' + LastName AS FullName,
    CONCAT(Address, ', ', City, ', ', State, ' ', ZipCode) AS FullAddress,
    Email
FROM Sales.Customers
ORDER BY LastName;
*/

-- Challenge 2.3
PRINT 'Challenge 2.3: Employee tenure';
/*
SELECT 
    FirstName + ' ' + LastName AS Employee,
    JobTitle,
    HireDate,
    DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsOfService,
    DATEDIFF(MONTH, HireDate, GETDATE()) % 12 AS AdditionalMonths
FROM HR.Employees
ORDER BY YearsOfService DESC;
*/

-- Challenge 2.4
PRINT 'Challenge 2.4: Formatted currency';
/*
SELECT 
    ProductName,
    '$' + CAST(Price AS VARCHAR(20)) AS PriceFormatted,
    FORMAT(Price, 'C', 'en-US') AS PriceCurrency
FROM Inventory.Products
ORDER BY Price DESC;
*/

-- Challenge 2.5
PRINT 'Challenge 2.5: Order totals';
/*
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    SUM(od.LineTotal) AS OrderTotal,
    FORMAT(SUM(od.LineTotal), 'C') AS FormattedTotal
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID, c.FirstName, c.LastName, o.OrderDate
ORDER BY OrderTotal DESC;
*/

PRINT '';

-- ============================================================================
-- SOLUTIONS: Challenge Set 3
-- ============================================================================

PRINT 'SOLUTIONS: Challenge Set 3 - Joins';
PRINT '==================================';
PRINT '';

-- Challenge 3.1
PRINT 'Challenge 3.1: Products with category and supplier';
/*
SELECT 
    p.ProductName,
    c.CategoryName,
    ISNULL(s.SupplierName, 'No Supplier') AS Supplier,
    p.Price
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID
ORDER BY c.CategoryName, p.ProductName;
*/

-- Challenge 3.2
PRINT 'Challenge 3.2: Orders with customer and employee';
/*
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS Customer,
    e.FirstName + ' ' + e.LastName AS SalesPerson,
    o.OrderDate,
    o.Status
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN HR.Employees e ON o.EmployeeID = e.EmployeeID
ORDER BY o.OrderDate DESC;
*/

-- Challenge 3.3
PRINT 'Challenge 3.3: Order details with product info';
/*
SELECT 
    od.OrderID,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    od.Discount,
    od.LineTotal
FROM Sales.OrderDetails od
JOIN Inventory.Products p ON od.ProductID = p.ProductID
ORDER BY od.OrderID, p.ProductName;
*/

-- Challenge 3.4
PRINT 'Challenge 3.4: Employees with departments and managers';
/*
SELECT 
    e.FirstName + ' ' + e.LastName AS Employee,
    e.JobTitle,
    d.DepartmentName,
    m.FirstName + ' ' + m.LastName AS Manager
FROM HR.Employees e
JOIN HR.Departments d ON e.DepartmentID = d.DepartmentID
LEFT JOIN HR.Employees m ON d.ManagerID = m.EmployeeID
ORDER BY d.DepartmentName, e.LastName;
*/

-- Challenge 3.5
PRINT 'Challenge 3.5: Complete sales report';
/*
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS Customer,
    e.FirstName + ' ' + e.LastName AS SalesPerson,
    p.ProductName,
    cat.CategoryName,
    od.Quantity,
    od.UnitPrice,
    od.LineTotal,
    o.OrderDate
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
JOIN HR.Employees e ON o.EmployeeID = e.EmployeeID
JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
JOIN Inventory.Products p ON od.ProductID = p.ProductID
JOIN Inventory.Categories cat ON p.CategoryID = cat.CategoryID
ORDER BY o.OrderDate, o.OrderID;
*/

PRINT '';

-- ============================================================================
-- SOLUTIONS: Challenge Set 4
-- ============================================================================

PRINT 'SOLUTIONS: Challenge Set 4 - Data Modification';
PRINT '==============================================';
PRINT '';

-- Challenge 4.1
PRINT 'Challenge 4.1: Insert new furniture product';
/*
INSERT INTO Inventory.Products (ProductName, CategoryID, SupplierID, SKU, Price, Cost, QuantityInStock, ReorderLevel)
VALUES ('Executive Leather Chair', 2, 4, 'FURN-CHA-002', 349.99, 180.00, 10, 5);

SELECT * FROM Inventory.Products WHERE SKU = 'FURN-CHA-002';
*/

-- Challenge 4.2
PRINT 'Challenge 4.2: 5% discount on Stationery';
/*
UPDATE p
SET Price = Price * 0.95
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Stationery';

SELECT p.ProductName, p.Price
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Stationery';
*/

-- Challenge 4.3
PRINT 'Challenge 4.3: Increase stock for low inventory';
/*
UPDATE Inventory.Products
SET QuantityInStock = QuantityInStock + 20
WHERE QuantityInStock < ReorderLevel;

SELECT ProductName, QuantityInStock, ReorderLevel
FROM Inventory.Products
WHERE QuantityInStock < ReorderLevel + 20;
*/

-- Challenge 4.4
PRINT 'Challenge 4.4: Update order status';
/*
UPDATE Sales.Orders
SET Status = 'Processing'
OUTPUT 
    inserted.OrderID,
    deleted.Status AS OldStatus,
    inserted.Status AS NewStatus
WHERE Status = 'Pending';
*/

-- Challenge 4.5
PRINT 'Challenge 4.5: Soft delete customer';
/*
UPDATE Sales.Customers
SET IsActive = 0
WHERE CustomerID = 1005;  -- Or specific customer

SELECT FirstName, LastName, Email, IsActive
FROM Sales.Customers
WHERE CustomerID = 1005;
*/

PRINT '';

-- ============================================================================
-- SOLUTIONS: Challenge Set 5
-- ============================================================================

PRINT 'SOLUTIONS: Challenge Set 5 - Advanced Queries';
PRINT '=============================================';
PRINT '';

-- Challenge 5.1
PRINT 'Challenge 5.1: Top 3 most expensive products';
/*
SELECT TOP 3
    ProductName,
    Price,
    c.CategoryName
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
ORDER BY Price DESC;
*/

-- Challenge 5.2
PRINT 'Challenge 5.2: Product count per category';
/*
SELECT 
    c.CategoryName,
    COUNT(p.ProductID) AS ProductCount,
    AVG(p.Price) AS AvgPrice,
    SUM(p.QuantityInStock) AS TotalStock
FROM Inventory.Categories c
LEFT JOIN Inventory.Products p ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryName
ORDER BY ProductCount DESC;
*/

-- Challenge 5.3
PRINT 'Challenge 5.3: Total sales per customer';
/*
SELECT 
    c.CustomerID,
    c.FirstName + ' ' + c.LastName AS Customer,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(od.LineTotal) AS TotalSpent,
    FORMAT(SUM(od.LineTotal), 'C') AS FormattedTotal
FROM Sales.Customers c
JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;
*/

-- Challenge 5.4
PRINT 'Challenge 5.4: Products never ordered';
/*
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.QuantityInStock
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE NOT EXISTS (
    SELECT 1 FROM Sales.OrderDetails od WHERE od.ProductID = p.ProductID
)
ORDER BY c.CategoryName, p.ProductName;
*/

-- Challenge 5.5
PRINT 'Challenge 5.5: Customers with multiple orders';
/*
SELECT 
    c.FirstName + ' ' + c.LastName AS Customer,
    c.Email,
    COUNT(o.OrderID) AS OrderCount
FROM Sales.Customers c
JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.Email
HAVING COUNT(o.OrderID) > 1
ORDER BY OrderCount DESC;
*/

PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 13 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Congratulations! You have completed Chapter 02: Database Fundamentals!';
PRINT '';
PRINT 'Skills Mastered:';
PRINT '  ✓ Database creation and schemas';
PRINT '  ✓ Table design with proper data types';
PRINT '  ✓ Primary keys, foreign keys, constraints';
PRINT '  ✓ INSERT data (single, multiple, with relationships)';
PRINT '  ✓ SELECT queries (columns, filters, joins)';
PRINT '  ✓ UPDATE data (single, multiple, with calculations)';
PRINT '  ✓ DELETE data (soft delete vs hard delete)';
PRINT '  ✓ Data calculations and formatting';
PRINT '  ✓ Multi-table queries with JOINs';
PRINT '';
PRINT 'RetailStore Database Stats:';
SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS RowCount
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE SCHEMA_NAME(t.schema_id) IN ('Sales', 'Inventory', 'HR')
  AND p.index_id IN (0,1)
GROUP BY SCHEMA_NAME(t.schema_id), t.name
ORDER BY SchemaName, TableName;

PRINT '';
PRINT 'Next Chapter: Advanced Queries (WHERE, ORDER BY, GROUP BY, HAVING)';
PRINT '';
