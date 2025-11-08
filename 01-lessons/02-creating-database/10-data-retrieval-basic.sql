-- ============================================================================
-- Lesson 10: Basic Data Retrieval (SELECT)
-- ============================================================================
-- Learn to query data from RetailStore tables
-- Prerequisites: Lessons 01-02, 09 (Database, tables, and data created)

USE RetailStore;
GO

PRINT 'Lesson 10: Basic Data Retrieval';
PRINT '===============================';
PRINT '';
PRINT 'Query the RetailStore data inserted in Lesson 09';
PRINT '';

-- ============================================================================
-- Concept 1: SELECT All Columns (*)
-- ============================================================================

PRINT 'Concept 1: SELECT All Columns (*)';
PRINT '---------------------------------';
PRINT 'SELECT * retrieves ALL columns from a table';
PRINT '';

-- View all products
SELECT * FROM Inventory.Products;

PRINT '';
PRINT 'Best Practices:';
PRINT '  • SELECT * is good for exploration and small tables';
PRINT '  • Avoid in production code (performance, unclear intent)';
PRINT '  • Specify exact columns needed in real applications';
PRINT '';

-- ============================================================================
-- Concept 2: SELECT Specific Columns
-- ============================================================================

PRINT 'Concept 2: SELECT Specific Columns';
PRINT '----------------------------------';
PRINT 'Choose only the columns you need';
PRINT '';

-- View product names and prices only
SELECT ProductName, Price, QuantityInStock
FROM Inventory.Products;

PRINT '';

-- Different column order
SELECT Price, ProductName, SKU
FROM Inventory.Products;

PRINT '';

-- Single column
SELECT ProductName FROM Inventory.Products;

PRINT '';

-- ============================================================================
-- Concept 3: Column Aliases with AS
-- ============================================================================

PRINT 'Concept 3: Column Aliases';
PRINT '------------------------';
PRINT 'Use AS to rename columns in results (more readable)';
PRINT '';

-- Simple aliases
SELECT 
    ProductID AS ID,
    ProductName AS Product,
    Price AS CurrentPrice,
    QuantityInStock AS InStock
FROM Inventory.Products;

PRINT '';

-- Alias without AS (optional, but less clear)
SELECT 
    ProductName Product,
    Price Amount
FROM Inventory.Products;

PRINT '';

-- Aliases with spaces (use brackets)
SELECT 
    ProductID AS [Product ID],
    ProductName AS [Product Name],
    Price AS [Unit Price],
    QuantityInStock AS [Qty In Stock]
FROM Inventory.Products;

PRINT '';

-- ============================================================================
-- Concept 4: Calculated Columns
-- ============================================================================

PRINT 'Concept 4: Calculated Columns';
PRINT '-----------------------------';
PRINT 'Perform calculations in SELECT statement';
PRINT '';

-- Calculate profit and inventory value
SELECT 
    ProductName,
    Price,
    Cost,
    Price - Cost AS Profit,
    ROUND((Price - Cost) / Cost * 100, 2) AS [Profit Margin %],
    QuantityInStock * Price AS [Inventory Value],
    QuantityInStock * Cost AS [Inventory Cost]
FROM Inventory.Products
WHERE Cost IS NOT NULL;

PRINT '';

-- ============================================================================
-- Concept 5: String Concatenation
-- ============================================================================

PRINT 'Concept 5: Combining Columns (Concatenation)';
PRINT '--------------------------------------------';
PRINT '';

-- Customer full names and locations
SELECT 
    FirstName + ' ' + LastName AS FullName,
    City + ', ' + State AS Location,
    Email
FROM Sales.Customers;

PRINT '';

-- Using CONCAT function (handles NULLs better)
SELECT 
    CONCAT(FirstName, ' ', LastName) AS FullName,
    CONCAT(Address, ', ', City, ', ', State, ' ', ZipCode) AS FullAddress
FROM Sales.Customers;

PRINT '';

-- ============================================================================
-- Concept 6: Working with Dates
-- ============================================================================

PRINT 'Concept 6: Date Calculations';
PRINT '----------------------------';
PRINT '';

-- Employee information with years of service
SELECT 
    FirstName + ' ' + LastName AS EmployeeName,
    JobTitle,
    HireDate,
    DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsOfService,
    DATEDIFF(DAY, HireDate, GETDATE()) AS DaysEmployed
FROM HR.Employees;

PRINT '';

-- Customer information
SELECT 
    FirstName + ' ' + LastName AS Customer,
    DateJoined,
    DATEDIFF(DAY, DateJoined, GETDATE()) AS DaysSinceJoined,
    CASE 
        WHEN IsActive = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS Status
FROM Sales.Customers;

PRINT '';

-- ============================================================================
-- Concept 7: Joining Tables for Complete Information
-- ============================================================================

PRINT 'Concept 7: Combining Related Data (JOIN - preview)';
PRINT '--------------------------------------------------';
PRINT 'Join Products with Categories to show category names';
PRINT '';

-- Products with category names
SELECT 
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.QuantityInStock
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID;

PRINT '';

-- Products with supplier information
SELECT 
    p.ProductName AS Product,
    p.Price,
    s.SupplierName AS Supplier,
    s.City AS [Supplier City]
FROM Inventory.Products p
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

PRINT '';

-- ============================================================================
-- Concept 8: Complete Real-World Query Examples
-- ============================================================================

PRINT 'Concept 8: Real-World Query Examples';
PRINT '------------------------------------';
PRINT '';

-- Example 1: Product Catalog Report
PRINT 'Product Catalog Report:';
SELECT 
    p.SKU AS [Product Code],
    p.ProductName AS Product,
    c.CategoryName AS Category,
    '$' + CAST(p.Price AS VARCHAR(20)) AS Price,
    CASE 
        WHEN p.QuantityInStock > 20 THEN 'In Stock'
        WHEN p.QuantityInStock > 0 THEN 'Low Stock'
        ELSE 'Out of Stock'
    END AS Availability
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE p.Discontinued = 0
ORDER BY c.CategoryName, p.ProductName;

PRINT '';

-- Example 2: Sales Summary
PRINT 'Sales Summary:';
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS Customer,
    e.FirstName + ' ' + e.LastName AS SalesPerson,
    FORMAT(o.OrderDate, 'yyyy-MM-dd') AS OrderDate,
    o.Status,
    (SELECT SUM(LineTotal) FROM Sales.OrderDetails WHERE OrderID = o.OrderID) AS OrderTotal
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN HR.Employees e ON o.EmployeeID = e.EmployeeID;

PRINT '';

-- Example 3: Employee Directory
PRINT 'Employee Directory:';
SELECT 
    e.EmployeeID AS ID,
    CONCAT(e.FirstName, ' ', e.LastName) AS Name,
    e.JobTitle AS Title,
    d.DepartmentName AS Department,
    e.Email,
    FORMAT(e.Salary, 'C') AS Salary
FROM HR.Employees e
JOIN HR.Departments d ON e.DepartmentID = d.DepartmentID
WHERE e.IsActive = 1
ORDER BY d.DepartmentName, e.LastName;

PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Practice Exercises';
PRINT '==================';
PRINT '';
PRINT 'Exercise 1: SELECT all customers from Seattle';
PRINT 'Exercise 2: SELECT product names and prices for Electronics category';
PRINT 'Exercise 3: Calculate total value of all inventory (Qty * Price)';
PRINT 'Exercise 4: Show employee names with their department and years of service';
PRINT 'Exercise 5: List all orders with customer names, formatted nicely';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
-- Exercise 1
SELECT FirstName, LastName, City, Email
FROM Sales.Customers
WHERE City = 'Seattle';

-- Exercise 2
SELECT 
    p.ProductName,
    p.Price,
    p.QuantityInStock
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Exercise 3
SELECT 
    SUM(QuantityInStock * Price) AS [Total Inventory Value]
FROM Inventory.Products;

-- Exercise 4
SELECT 
    FirstName + ' ' + LastName AS Employee,
    d.DepartmentName AS Department,
    DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsOfService
FROM HR.Employees e
JOIN HR.Departments d ON e.DepartmentID = d.DepartmentID
ORDER BY YearsOfService DESC;

-- Exercise 5
SELECT 
    o.OrderID AS [Order #],
    c.FirstName + ' ' + c.LastName AS Customer,
    FORMAT(o.OrderDate, 'MMM dd, yyyy') AS [Order Date],
    o.Status
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID;
*/

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 10 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  ✓ SELECT * retrieves all columns';
PRINT '  ✓ SELECT column1, column2 retrieves specific columns';
PRINT '  ✓ AS creates column aliases (readable names)';
PRINT '  ✓ Can calculate new columns (Price * Quantity)';
PRINT '  ✓ CONCAT or + combines strings';
PRINT '  ✓ JOIN combines data from multiple tables';
PRINT '  ✓ FORMAT and CAST make output more readable';
PRINT '';
PRINT 'Next: Lesson 11 - UPDATE (Modifying Data)';
PRINT '';
