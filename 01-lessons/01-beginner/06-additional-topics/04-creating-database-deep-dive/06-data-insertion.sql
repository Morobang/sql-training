-- ============================================================================
-- Lesson 06: Data Insertion
-- ============================================================================
-- Learn: INSERT INTO statement
-- Prerequisites: Lesson 02 completed (all tables created)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- Insert Categories
-- ============================================================================

INSERT INTO Inventory.Categories (CategoryName, Description)
VALUES 
    ('Electronics', 'Electronic devices and accessories'),
    ('Furniture', 'Home and office furniture'),
    ('Clothing', 'Apparel and accessories');

-- ============================================================================
-- Insert Suppliers
-- ============================================================================

INSERT INTO Inventory.Suppliers (SupplierName, Email, Phone, City, Country)
VALUES 
    ('Tech Supply Co', 'sales@techsupply.com', '555-0101', 'Seattle', 'USA'),
    ('Furniture Plus', 'orders@furnitureplus.com', '555-0102', 'Portland', 'USA');

-- ============================================================================
-- Insert Products
-- ============================================================================

INSERT INTO Inventory.Products (ProductName, CategoryID, SupplierID, SKU, Price, Cost, QuantityInStock)
VALUES 
    ('Laptop', 1, 1, 'LAP001', 999.99, 750.00, 50),
    ('Wireless Mouse', 1, 1, 'MOU001', 29.99, 15.00, 200),
    ('Office Desk', 2, 2, 'DSK001', 299.99, 180.00, 30),
    ('Office Chair', 2, 2, 'CHR001', 199.99, 120.00, 45);

-- ============================================================================
-- Insert Customers
-- ============================================================================

INSERT INTO Sales.Customers (FirstName, LastName, Email, Phone, City, Country)
VALUES 
    ('Sarah', 'Johnson', 'sarah.j@email.com', '555-1001', 'New York', 'USA'),
    ('Mike', 'Williams', 'mike.w@email.com', '555-1002', 'Los Angeles', 'USA'),
    ('Emily', 'Brown', 'emily.b@email.com', '555-1003', 'Chicago', 'USA');

-- ============================================================================
-- Insert Departments
-- ============================================================================

INSERT INTO HR.Departments (DepartmentName, Location)
VALUES 
    ('Sales', 'Building A'),
    ('IT', 'Building B'),
    ('HR', 'Building A');

-- ============================================================================
-- Insert Employees
-- ============================================================================

INSERT INTO HR.Employees (FirstName, LastName, Email, DepartmentID, Salary, HireDate)
VALUES 
    ('John', 'Smith', 'john.smith@company.com', 1, 55000, '2023-01-15'),
    ('Lisa', 'Davis', 'lisa.davis@company.com', 2, 65000, '2023-02-01'),
    ('Tom', 'Wilson', 'tom.wilson@company.com', 1, 52000, '2023-03-10');

-- ============================================================================
-- Insert Orders
-- ============================================================================

INSERT INTO Sales.Orders (CustomerID, OrderDate, TotalAmount, Status)
VALUES 
    (1001, '2024-01-15', 1029.98, 'Shipped'),
    (1002, '2024-01-16', 499.98, 'Delivered'),
    (1003, '2024-01-17', 299.99, 'Pending');

-- ============================================================================
-- Insert Order Details
-- ============================================================================

INSERT INTO Sales.OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
VALUES 
    (1000, 1, 1, 999.99),  -- Order 1000: 1 Laptop
    (1000, 2, 1, 29.99),   -- Order 1000: 1 Mouse
    (1001, 2, 2, 29.99),   -- Order 1001: 2 Mice
    (1001, 4, 2, 199.99),  -- Order 1001: 2 Chairs
    (1002, 3, 1, 299.99);  -- Order 1002: 1 Desk

GO

-- Verify data inserted
SELECT 'Categories' AS TableName, COUNT(*) AS RecordCount FROM Inventory.Categories
UNION ALL
SELECT 'Products', COUNT(*) FROM Inventory.Products
UNION ALL
SELECT 'Customers', COUNT(*) FROM Sales.Customers
UNION ALL
SELECT 'Orders', COUNT(*) FROM Sales.Orders
UNION ALL
SELECT 'Employees', COUNT(*) FROM HR.Employees;
GO
