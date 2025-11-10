-- ============================================================================
-- Lesson 02: Table Creation Basics
-- ============================================================================
-- Learn: CREATE TABLE syntax with all 8 RetailStore tables
-- Prerequisites: Lesson 01 completed (RetailStore database exists)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- INVENTORY SCHEMA - Product Management Tables
-- ============================================================================

CREATE TABLE Inventory.Categories (
    CategoryID INT IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500)
);

CREATE TABLE Inventory.Suppliers (
    SupplierID INT IDENTITY(1,1),
    SupplierName NVARCHAR(200) NOT NULL,
    ContactName NVARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(20),
    City NVARCHAR(100),
    Country NVARCHAR(100)
);

CREATE TABLE Inventory.Products (
    ProductID INT IDENTITY(1,1),
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NOT NULL,
    SupplierID INT,
    SKU VARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2),
    QuantityInStock INT DEFAULT 0,
    Discontinued BIT DEFAULT 0
);

-- ============================================================================
-- SALES SCHEMA - Customer and Order Tables
-- ============================================================================

CREATE TABLE Sales.Customers (
    CustomerID INT IDENTITY(1001,1),
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL,
    Phone VARCHAR(20),
    City NVARCHAR(100),
    Country NVARCHAR(100) DEFAULT 'USA',
    DateJoined DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE Sales.Orders (
    OrderID INT IDENTITY(1000,1),
    CustomerID INT NOT NULL,
    OrderDate DATETIME2 DEFAULT SYSDATETIME(),
    TotalAmount DECIMAL(10,2),
    Status NVARCHAR(20) DEFAULT 'Pending'
);

CREATE TABLE Sales.OrderDetails (
    OrderDetailID INT IDENTITY(1,1),
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
);

-- ============================================================================
-- HR SCHEMA - Employee and Department Tables
-- ============================================================================

CREATE TABLE HR.Departments (
    DepartmentID INT IDENTITY(1,1),
    DepartmentName NVARCHAR(100) NOT NULL,
    Location NVARCHAR(100)
);

CREATE TABLE HR.Employees (
    EmployeeID INT IDENTITY(1,1),
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL,
    DepartmentID INT,
    Salary MONEY,
    HireDate DATE NOT NULL
);
GO

-- ============================================================================
-- Verification Query
-- ============================================================================

SELECT 
    SCHEMA_NAME(schema_id) AS [Schema],
    name AS TableName
FROM sys.tables
WHERE SCHEMA_NAME(schema_id) IN ('Inventory', 'Sales', 'HR')
ORDER BY [Schema], TableName;
GO