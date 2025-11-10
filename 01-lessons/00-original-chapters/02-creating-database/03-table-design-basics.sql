-- ============================================================================
-- Lesson 03: Table Design Basics
-- ============================================================================
-- Learn: PRIMARY KEY, FOREIGN KEY, constraints, relationships
-- Prerequisites: Lesson 02 completed (all tables created without constraints)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- STEP 1: Add Primary Keys to All Tables
-- ============================================================================
-- Primary keys uniquely identify each row in a table

ALTER TABLE Inventory.Categories
ADD CONSTRAINT PK_Categories PRIMARY KEY (CategoryID);

ALTER TABLE Inventory.Suppliers
ADD CONSTRAINT PK_Suppliers PRIMARY KEY (SupplierID);

ALTER TABLE Inventory.Products
ADD CONSTRAINT PK_Products PRIMARY KEY (ProductID);

ALTER TABLE Sales.Customers
ADD CONSTRAINT PK_Customers PRIMARY KEY (CustomerID);

ALTER TABLE Sales.Orders
ADD CONSTRAINT PK_Orders PRIMARY KEY (OrderID);

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT PK_OrderDetails PRIMARY KEY (OrderDetailID);

ALTER TABLE HR.Departments
ADD CONSTRAINT PK_Departments PRIMARY KEY (DepartmentID);

ALTER TABLE HR.Employees
ADD CONSTRAINT PK_Employees PRIMARY KEY (EmployeeID);
GO

-- ============================================================================
-- STEP 2: Add UNIQUE Constraints
-- ============================================================================
-- UNIQUE ensures no duplicate values in a column

ALTER TABLE Inventory.Categories
ADD CONSTRAINT UQ_CategoryName UNIQUE (CategoryName);

ALTER TABLE Inventory.Products
ADD CONSTRAINT UQ_SKU UNIQUE (SKU);

ALTER TABLE Sales.Customers
ADD CONSTRAINT UQ_CustomerEmail UNIQUE (Email);

ALTER TABLE HR.Departments
ADD CONSTRAINT UQ_DepartmentName UNIQUE (DepartmentName);

ALTER TABLE HR.Employees
ADD CONSTRAINT UQ_EmployeeEmail UNIQUE (Email);
GO

-- ============================================================================
-- STEP 3: Add CHECK Constraints
-- ============================================================================
-- CHECK validates data before allowing insert/update

ALTER TABLE Inventory.Products
ADD CONSTRAINT CK_Price CHECK (Price >= 0);

ALTER TABLE Inventory.Products
ADD CONSTRAINT CK_Cost CHECK (Cost >= 0);

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT CK_Quantity CHECK (Quantity > 0);

ALTER TABLE HR.Employees
ADD CONSTRAINT CK_Salary CHECK (Salary >= 0);
GO

-- ============================================================================
-- STEP 4: Add Foreign Keys (Relationships)
-- ============================================================================
-- Foreign keys link tables together and enforce referential integrity

-- INVENTORY Schema relationships
ALTER TABLE Inventory.Products
ADD CONSTRAINT FK_Products_Category 
    FOREIGN KEY (CategoryID) REFERENCES Inventory.Categories(CategoryID);

ALTER TABLE Inventory.Products
ADD CONSTRAINT FK_Products_Supplier 
    FOREIGN KEY (SupplierID) REFERENCES Inventory.Suppliers(SupplierID);

-- SALES Schema relationships
ALTER TABLE Sales.Orders
ADD CONSTRAINT FK_Orders_Customer 
    FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID);

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT FK_OrderDetails_Order 
    FOREIGN KEY (OrderID) REFERENCES Sales.Orders(OrderID);

ALTER TABLE Sales.OrderDetails
ADD CONSTRAINT FK_OrderDetails_Product 
    FOREIGN KEY (ProductID) REFERENCES Inventory.Products(ProductID);

-- HR Schema relationships
ALTER TABLE HR.Employees
ADD CONSTRAINT FK_Employees_Department 
    FOREIGN KEY (DepartmentID) REFERENCES HR.Departments(DepartmentID);
GO

-- ============================================================================
-- STEP 5: View All Constraints
-- ============================================================================

SELECT 
    OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName,
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM sys.objects
WHERE type_desc LIKE '%CONSTRAINT'
    AND OBJECT_SCHEMA_NAME(parent_object_id) IN ('Inventory', 'Sales', 'HR')
ORDER BY SchemaName, TableName, ConstraintType;
GO

-- ============================================================================
-- STEP 6: Test Relationships with Queries
-- ============================================================================

-- View products with their categories
SELECT 
    p.ProductName,
    c.CategoryName,
    s.SupplierName
FROM Inventory.Products p
INNER JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Inventory.Suppliers s ON p.SupplierID = s.SupplierID;

-- View customers with their order count
SELECT 
    c.FirstName + ' ' + c.LastName AS CustomerName,
    COUNT(o.OrderID) AS TotalOrders
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.FirstName, c.LastName;

-- View employees with their departments
SELECT 
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    d.DepartmentName,
    e.Salary
FROM HR.Employees e
LEFT JOIN HR.Departments d ON e.DepartmentID = d.DepartmentID;
GO
