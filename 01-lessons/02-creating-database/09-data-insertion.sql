-- ============================================================================
-- Lesson 09: Data Insertion - Populating RetailStore
-- ============================================================================
-- Insert realistic data into all RetailStore tables
-- Prerequisites: Lessons 01-02 (RetailStore database and tables created)

USE RetailStore;
GO

PRINT 'Lesson 09: Populating RetailStore Database';
PRINT '==========================================';
PRINT '';
PRINT 'This lesson inserts data into all tables created in Lesson 02.';
PRINT 'Future lessons will query this data!';
PRINT '';

-- ============================================================================
-- Concept 1: INSERT Single Row
-- ============================================================================

PRINT 'Concept 1: INSERT Single Row';
PRINT '----------------------------';
PRINT '';

-- Insert one category
INSERT INTO Inventory.Categories (CategoryName, Description) 
VALUES ('Electronics', 'Computers, phones, and electronic devices');

SELECT * FROM Inventory.Categories WHERE CategoryName = 'Electronics';
PRINT '';

-- ============================================================================
-- Concept 2: INSERT Multiple Rows
-- ============================================================================

PRINT 'Concept 2: INSERT Multiple Rows';
PRINT '-------------------------------';
PRINT 'Insert multiple rows in a single statement (more efficient)';
PRINT '';

-- Insert remaining categories
INSERT INTO Inventory.Categories (CategoryName, Description) VALUES
    ('Furniture', 'Office and home furniture'),
    ('Stationery', 'Office supplies, paper, and writing tools'),
    ('Clothing', 'Business and casual apparel');

SELECT CategoryID, CategoryName FROM Inventory.Categories ORDER BY CategoryID;
PRINT '';

-- ============================================================================
-- Concept 3: INSERT with IDENTITY - Auto-Generated IDs
-- ============================================================================

PRINT 'Concept 3: IDENTITY Columns (Auto-Increment)';
PRINT '--------------------------------------------';
PRINT 'CategoryID is auto-generated - we did not specify it';
PRINT '';

-- Insert suppliers (SupplierID auto-generated)
INSERT INTO Inventory.Suppliers (SupplierName, ContactName, Email, Phone, City, Country) VALUES
    ('TechWorld Distributors', 'John Smith', 'john@techworld.com', '555-0100', 'Seattle', 'USA'),
    ('Office Plus Wholesale', 'Mary Johnson', 'mary@officeplus.com', '555-0200', 'Portland', 'USA'),
    ('Global Electronics Inc', 'Bob Lee', 'bob@globalelec.com', '555-0300', 'San Francisco', 'USA'),
    ('Furniture Depot', 'Alice Wong', 'alice@furnituredepot.com', '555-0400', 'Los Angeles', 'USA');

SELECT SupplierID, SupplierName, City FROM Inventory.Suppliers;
PRINT '';

-- ============================================================================
-- Concept 4: INSERT with Foreign Keys
-- ============================================================================

PRINT 'Concept 4: INSERT with Foreign Keys';
PRINT '-----------------------------------';
PRINT 'ProductID, CategoryID, and SupplierID must match existing records';
PRINT '';

-- Insert products (linked to categories and suppliers)
INSERT INTO Inventory.Products (ProductName, CategoryID, SupplierID, SKU, Price, Cost, QuantityInStock, ReorderLevel) VALUES
    -- Electronics (CategoryID = 1)
    ('Laptop Pro 15"', 1, 1, 'ELEC-LAP-001', 999.99, 700.00, 15, 5),
    ('Wireless Mouse', 1, 1, 'ELEC-MOU-001', 29.99, 15.00, 50, 20),
    ('Mechanical Keyboard', 1, 1, 'ELEC-KEY-001', 79.99, 40.00, 30, 10),
    ('27" Monitor', 1, 3, 'ELEC-MON-001', 299.99, 180.00, 20, 5),
    ('USB-C Hub', 1, 3, 'ELEC-HUB-001', 49.99, 25.00, 40, 15),
    
    -- Furniture (CategoryID = 2)
    ('Ergonomic Desk Chair', 2, 4, 'FURN-CHA-001', 199.99, 110.00, 25, 8),
    ('Standing Desk', 2, 4, 'FURN-DSK-001', 399.99, 220.00, 15, 5),
    ('Office Bookshelf', 2, 4, 'FURN-SHE-001', 149.99, 80.00, 12, 5),
    ('Filing Cabinet', 2, 4, 'FURN-CAB-001', 129.99, 70.00, 18, 6),
    
    -- Stationery (CategoryID = 3)
    ('Notebook Pack (5ct)', 3, 2, 'STAT-NOT-001', 12.99, 6.00, 100, 30),
    ('Ballpoint Pens (12ct)', 3, 2, 'STAT-PEN-001', 8.99, 4.00, 150, 50),
    ('Sticky Notes Set', 3, 2, 'STAT-STI-001', 6.99, 3.00, 200, 60),
    ('Desk Organizer', 3, 2, 'STAT-ORG-001', 24.99, 12.00, 35, 10),
    
    -- Clothing (CategoryID = 4)
    ('Business Shirt - Blue', 4, NULL, 'CLOT-SHI-001', 39.99, 18.00, 45, 15),
    ('Khaki Pants', 4, NULL, 'CLOT-PAN-001', 49.99, 22.00, 40, 15),
    ('Casual Sneakers', 4, NULL, 'CLOT-SHO-001', 69.99, 32.00, 30, 10);

SELECT COUNT(*) AS TotalProducts FROM Inventory.Products;
PRINT '';

-- ============================================================================
-- Concept 5: INSERT with DEFAULT values
-- ============================================================================

PRINT 'Concept 5: DEFAULT Values';
PRINT '-------------------------';
PRINT 'Some columns use DEFAULT if not specified';
PRINT '';

-- Insert customers (DateJoined, IsActive use defaults)
INSERT INTO Sales.Customers (FirstName, LastName, Email, Phone, Address, City, State, ZipCode) VALUES
    ('Alice', 'Johnson', 'alice.j@email.com', '555-1001', '123 Main St', 'Seattle', 'WA', '98101'),
    ('Bob', 'Smith', 'bob.smith@email.com', '555-1002', '456 Oak Ave', 'Portland', 'OR', '97201'),
    ('Carol', 'Williams', 'carol.w@email.com', '555-1003', '789 Pine Rd', 'Seattle', 'WA', '98102'),
    ('David', 'Brown', 'david.b@email.com', '555-1004', '321 Elm St', 'Tacoma', 'WA', '98401'),
    ('Eve', 'Davis', 'eve.davis@email.com', '555-1005', '654 Maple Dr', 'Vancouver', 'WA', '98660');

SELECT CustomerID, FirstName, LastName, Email, DateJoined, IsActive 
FROM Sales.Customers;
PRINT '';

-- ============================================================================
-- Concept 6: INSERT for Related Tables
-- ============================================================================

PRINT 'Concept 6: INSERT Related Data (Departments & Employees)';
PRINT '--------------------------------------------------------';
PRINT '';

-- Insert departments
INSERT INTO HR.Departments (DepartmentName, Location) VALUES
    ('Sales', 'Floor 1'),
    ('IT Support', 'Floor 2'),
    ('Management', 'Floor 3'),
    ('Warehouse', 'Warehouse Building');

-- Insert employees
INSERT INTO HR.Employees (FirstName, LastName, Email, JobTitle, DepartmentID, Salary, HireDate, BirthDate) VALUES
    ('John', 'Manager', 'john.m@retailstore.com', 'Store Manager', 3, 75000, '2020-01-15', '1985-05-20'),
    ('Sarah', 'Sales', 'sarah.s@retailstore.com', 'Sales Associate', 1, 35000, '2021-03-20', '1990-08-15'),
    ('Mike', 'Tech', 'mike.t@retailstore.com', 'IT Specialist', 2, 55000, '2019-06-10', '1988-12-05'),
    ('Lisa', 'Warehouse', 'lisa.w@retailstore.com', 'Warehouse Manager', 4, 45000, '2020-11-01', '1987-03-22'),
    ('Tom', 'Junior', 'tom.j@retailstore.com', 'Junior Sales', 1, 30000, '2023-01-15', '1995-09-10');

-- Update departments with managers
UPDATE HR.Departments SET ManagerID = 1 WHERE DepartmentName = 'Management';
UPDATE HR.Departments SET ManagerID = 2 WHERE DepartmentName = 'Sales';
UPDATE HR.Departments SET ManagerID = 3 WHERE DepartmentName = 'IT Support';
UPDATE HR.Departments SET ManagerID = 4 WHERE DepartmentName = 'Warehouse';

SELECT 
    d.DepartmentName,
    e.FirstName + ' ' + e.LastName AS Manager
FROM HR.Departments d
LEFT JOIN HR.Employees e ON d.ManagerID = e.EmployeeID;
PRINT '';

-- ============================================================================
-- Concept 7: INSERT Orders and OrderDetails
-- ============================================================================

PRINT 'Concept 7: INSERT Orders with Details';
PRINT '-------------------------------------';
PRINT '';

-- Order 1: Alice Johnson
INSERT INTO Sales.Orders (CustomerID, EmployeeID, OrderDate, RequiredDate, ShippingCost, Status) 
VALUES (1001, 2, '2025-01-15', '2025-01-20', 15.00, 'Shipped');

DECLARE @Order1 INT = SCOPE_IDENTITY();  -- Get last inserted OrderID

INSERT INTO Sales.OrderDetails (OrderID, ProductID, Quantity, UnitPrice, Discount) VALUES
    (@Order1, 1, 1, 999.99, 0),      -- Laptop
    (@Order1, 2, 2, 29.99, 10);      -- 2 Mice with 10% discount

-- Order 2: Bob Smith
INSERT INTO Sales.Orders (CustomerID, EmployeeID, OrderDate, RequiredDate, ShippingCost, Status) 
VALUES (1002, 2, '2025-01-16', '2025-01-22', 10.00, 'Delivered');

DECLARE @Order2 INT = SCOPE_IDENTITY();

INSERT INTO Sales.OrderDetails (OrderID, ProductID, Quantity, UnitPrice, Discount) VALUES
    (@Order2, 6, 1, 199.99, 0),      -- Desk Chair
    (@Order2, 10, 3, 12.99, 5),      -- 3 Notebook packs with 5% discount
    (@Order2, 11, 2, 8.99, 0);       -- 2 Pen packs

-- Order 3: Carol Williams
INSERT INTO Sales.Orders (CustomerID, EmployeeID, OrderDate, RequiredDate, ShippingCost, Status) 
VALUES (1003, 5, '2025-01-17', '2025-01-23', 20.00, 'Pending');

DECLARE @Order3 INT = SCOPE_IDENTITY();

INSERT INTO Sales.OrderDetails (OrderID, ProductID, Quantity, UnitPrice, Discount) VALUES
    (@Order3, 7, 1, 399.99, 0),      -- Standing Desk
    (@Order3, 4, 1, 299.99, 0),      -- Monitor
    (@Order3, 3, 1, 79.99, 0);       -- Keyboard

-- View orders
SELECT 
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS Customer,
    o.OrderDate,
    o.Status,
    (SELECT SUM(LineTotal) FROM Sales.OrderDetails WHERE OrderID = o.OrderID) AS OrderTotal
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderID;

PRINT '';

-- ============================================================================
-- VERIFICATION - Check All Tables
-- ============================================================================

PRINT '';
PRINT 'Database Population Summary';
PRINT '===========================';
PRINT '';

SELECT 'Categories' AS TableName, COUNT(*) AS RowCount FROM Inventory.Categories
UNION ALL
SELECT 'Suppliers', COUNT(*) FROM Inventory.Suppliers
UNION ALL
SELECT 'Products', COUNT(*) FROM Inventory.Products
UNION ALL
SELECT 'Customers', COUNT(*) FROM Sales.Customers
UNION ALL
SELECT 'Departments', COUNT(*) FROM HR.Departments
UNION ALL
SELECT 'Employees', COUNT(*) FROM HR.Employees
UNION ALL
SELECT 'Orders', COUNT(*) FROM Sales.Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM Sales.OrderDetails;

PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 09 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Data Inserted:';
PRINT '  ✓ 4 Categories (Electronics, Furniture, Stationery, Clothing)';
PRINT '  ✓ 4 Suppliers';
PRINT '  ✓ 16 Products across all categories';
PRINT '  ✓ 5 Customers';
PRINT '  ✓ 4 Departments with managers';
PRINT '  ✓ 5 Employees';
PRINT '  ✓ 3 Orders with multiple order details';
PRINT '';
PRINT 'INSERT Techniques Learned:';
PRINT '  ✓ INSERT single row';
PRINT '  ✓ INSERT multiple rows (more efficient)';
PRINT '  ✓ IDENTITY auto-increment (no need to specify ID)';
PRINT '  ✓ FOREIGN KEY relationships (CategoryID, SupplierID, etc.)';
PRINT '  ✓ DEFAULT values (DateJoined, IsActive, Status)';
PRINT '  ✓ SCOPE_IDENTITY() to get last inserted ID';
PRINT '';
PRINT 'Next: Lesson 10 - Data Retrieval (SELECT queries)';
PRINT '';
PRINT 'IMPORTANT: All tables now have data - lessons 10-13 will query this data!';
PRINT '';
