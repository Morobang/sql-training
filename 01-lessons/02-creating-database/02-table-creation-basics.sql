-- ============================================================================-- ============================================================================

-- Lesson 02: Table Creation & Data Types-- Lesson 06: Table Creation Basics

-- ============================================================================-- ============================================================================

-- Create ALL tables for Retail Store database with data types explained-- Learn: CREATE TABLE syntax, column definitions, PRIMARY KEY

-- Prerequisites: Lesson 01 - RetailStore database created with schemas-- Prerequisites: 00-setup/01-database-setup-complete.sql



USE RetailStore;USE BookStore;

GOGO



PRINT 'Lesson 02: Creating RetailStore Tables';PRINT 'Lesson 06: Table Creation Basics';

PRINT '======================================';PRINT '================================';

PRINT '';PRINT '';

PRINT 'This lesson creates ALL tables used throughout the training course.';

PRINT 'We explain data types as we create each table.';-- ============================================================================

PRINT '';-- CONCEPT 1: Basic CREATE TABLE

-- ============================================================================

-- ============================================================================

-- PART 1: INVENTORY Schema - Categories TablePRINT 'Concept 1: Basic Table Creation';

-- ============================================================================PRINT '-------------------------------';



PRINT 'PART 1: Creating Inventory.Categories';-- Simple table

PRINT '======================================';CREATE TABLE Authors (

PRINT '';    AuthorID INT,

PRINT 'Data Types Used:';    FirstName NVARCHAR(50),

PRINT '  INT          - Whole numbers (-2.1B to 2.1B)';    LastName NVARCHAR(50),

PRINT '  IDENTITY(1,1) - Auto-increment starting at 1';    BirthYear INT

PRINT '  NVARCHAR(n)  - Variable Unicode text (supports all languages)';);

PRINT '';

INSERT INTO Authors VALUES (1, N'Jane', N'Austen', 1775);

CREATE TABLE Inventory.Categories (INSERT INTO Authors VALUES (2, N'Mark', N'Twain', 1835);

    CategoryID INT PRIMARY KEY IDENTITY(1,1),  -- Auto-increment ID

    CategoryName NVARCHAR(100) NOT NULL UNIQUE, -- Category name (Electronics, Furniture, etc.)SELECT * FROM Authors;

    Description NVARCHAR(500) NULL               -- Optional description

);DROP TABLE Authors;

PRINT '';

PRINT '✓ Inventory.Categories table created';

PRINT '';-- ============================================================================

-- CONCEPT 2: Column Data Types

-- ============================================================================-- ============================================================================

-- PART 2: INVENTORY Schema - Suppliers Table

-- ============================================================================PRINT 'Concept 2: Choosing Data Types';

PRINT '------------------------------';

PRINT 'PART 2: Creating Inventory.Suppliers';

PRINT '====================================';CREATE TABLE Products (

PRINT '';    ProductID INT,                          -- Whole numbers

PRINT 'New Data Types:';    ProductName NVARCHAR(100),              -- Variable-length text

PRINT '  VARCHAR(n)   - Variable text (ASCII only, smaller than NVARCHAR)';    Description NVARCHAR(MAX),              -- Large text

PRINT '  Use VARCHAR for emails, phone numbers (no special characters)';    Price DECIMAL(10,2),                    -- Money (10 digits, 2 decimal)

PRINT '';    InStock BIT,                            -- True/False (0/1)

    LaunchDate DATE,                        -- Date only

CREATE TABLE Inventory.Suppliers (    CreatedAt DATETIME2 DEFAULT SYSDATETIME()  -- Timestamp with default

    SupplierID INT PRIMARY KEY IDENTITY(1,1),);

    SupplierName NVARCHAR(200) NOT NULL,

    ContactName NVARCHAR(100),INSERT INTO Products (ProductID, ProductName, Price, InStock, LaunchDate)

    Email VARCHAR(100),                          -- ASCII text for emailVALUES (1, N'Laptop', 999.99, 1, '2025-01-15');

    Phone VARCHAR(20),                           -- ASCII text for phone

    Address NVARCHAR(200),SELECT * FROM Products;

    City NVARCHAR(100),

    Country NVARCHAR(100)DROP TABLE Products;

);PRINT '';



PRINT '✓ Inventory.Suppliers table created';-- ============================================================================

PRINT '';-- CONCEPT 3: PRIMARY KEY

-- ============================================================================

-- ============================================================================

-- PART 3: INVENTORY Schema - Products TablePRINT 'Concept 3: Primary Keys';

-- ============================================================================PRINT '----------------------';



PRINT 'PART 3: Creating Inventory.Products';-- Method 1: Inline constraint

PRINT '===================================';CREATE TABLE Customers (

PRINT '';    CustomerID INT PRIMARY KEY,

PRINT 'New Data Types:';    CustomerName NVARCHAR(100),

PRINT '  DECIMAL(10,2) - Exact decimal numbers (10 digits total, 2 after decimal)';    Email NVARCHAR(100)

PRINT '                  Example: 12345.67';);

PRINT '  BIT           - Boolean (0=False, 1=True)';

PRINT '  DATE          - Date only (no time)';-- Method 2: Named constraint

PRINT '';CREATE TABLE Orders (

PRINT 'Constraints:';    OrderID INT CONSTRAINT PK_Orders PRIMARY KEY,

PRINT '  FOREIGN KEY   - Links to another table';    OrderDate DATE,

PRINT '  CHECK         - Validates data (Price >= 0)';    TotalAmount DECIMAL(10,2)

PRINT '  DEFAULT       - Default value if not provided';);

PRINT '';

-- Method 3: Table-level constraint

CREATE TABLE Inventory.Products (CREATE TABLE Invoices (

    ProductID INT PRIMARY KEY IDENTITY(1,1),    InvoiceID INT,

    ProductName NVARCHAR(200) NOT NULL,    InvoiceDate DATE,

    CategoryID INT NOT NULL,                     -- Link to Categories    Amount DECIMAL(10,2),

    SupplierID INT,                              -- Link to Suppliers (nullable)    CONSTRAINT PK_Invoices PRIMARY KEY (InvoiceID)

    SKU VARCHAR(50) UNIQUE,                      -- Stock Keeping Unit (unique code));

    Price DECIMAL(10,2) NOT NULL CHECK (Price >= 0),  -- Price must be >= 0

    Cost DECIMAL(10,2) CHECK (Cost >= 0),        -- Supplier cost-- Try duplicate - will fail!

    QuantityInStock INT DEFAULT 0,               -- Default to 0 if not specifiedINSERT INTO Customers VALUES (1, N'John Doe', N'john@email.com');

    ReorderLevel INT DEFAULT 10,-- INSERT INTO Customers VALUES (1, N'Jane Doe', N'jane@email.com');  -- Error!

    Discontinued BIT DEFAULT 0,                  -- 0=Active, 1=Discontinued

    DateAdded DATE DEFAULT CAST(GETDATE() AS DATE),  -- Auto-set to current dateSELECT * FROM Customers;

    

    -- Foreign KeysDROP TABLE Customers;

    CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryID) DROP TABLE Orders;

        REFERENCES Inventory.Categories(CategoryID),DROP TABLE Invoices;

    CONSTRAINT FK_Products_Supplier FOREIGN KEY (SupplierID) PRINT '';

        REFERENCES Inventory.Suppliers(SupplierID)

);-- ============================================================================

-- CONCEPT 4: IDENTITY (Auto-increment)

PRINT '✓ Inventory.Products table created';-- ============================================================================

PRINT '  - Links to Categories via CategoryID';

PRINT '  - Links to Suppliers via SupplierID';PRINT 'Concept 4: Auto-incrementing IDs';

PRINT '  - Price/Cost must be >= 0';PRINT '--------------------------------';

PRINT '  - DateAdded auto-set to current date';

PRINT '';CREATE TABLE Employees (

    EmployeeID INT PRIMARY KEY IDENTITY(1,1),  -- Start at 1, increment by 1

-- ============================================================================    FirstName NVARCHAR(50),

-- PART 4: SALES Schema - Customers Table    LastName NVARCHAR(50),

-- ============================================================================    HireDate DATE

);

PRINT 'PART 4: Creating Sales.Customers';

PRINT '================================';-- No need to specify EmployeeID

PRINT '';INSERT INTO Employees (FirstName, LastName, HireDate)

PRINT 'New Data Types:';VALUES 

PRINT '  DATETIME2     - Date and time with high precision';    (N'Alice', N'Smith', '2020-01-15'),

PRINT '';    (N'Bob', N'Johnson', '2021-03-20'),

    (N'Carol', N'Williams', '2022-06-10');

CREATE TABLE Sales.Customers (

    CustomerID INT PRIMARY KEY IDENTITY(1001,1),  -- Start at 1001SELECT * FROM Employees;

    FirstName NVARCHAR(100) NOT NULL,

    LastName NVARCHAR(100) NOT NULL,-- Get last inserted ID

    Email VARCHAR(150) UNIQUE NOT NULL,           -- Email must be uniqueSELECT SCOPE_IDENTITY() AS LastInsertedID;

    Phone VARCHAR(20),

    Address NVARCHAR(200),DROP TABLE Employees;

    City NVARCHAR(100),PRINT '';

    State VARCHAR(2),                             -- US state code (2 chars)

    ZipCode VARCHAR(10),-- ============================================================================

    Country NVARCHAR(100) DEFAULT 'USA',-- CONCEPT 5: Complete Table Example

    DateJoined DATETIME2 DEFAULT SYSDATETIME(),   -- Auto-set to current datetime-- ============================================================================

    IsActive BIT DEFAULT 1                        -- 1=Active customer

);PRINT 'Concept 5: Complete Table with Best Practices';

PRINT '---------------------------------------------';

PRINT '✓ Sales.Customers table created';

PRINT '  - CustomerID starts at 1001';CREATE TABLE Articles (

PRINT '  - Email must be unique';    ArticleID INT PRIMARY KEY IDENTITY(1,1),

PRINT '  - DateJoined auto-set to current datetime';    Title NVARCHAR(200) NOT NULL,

PRINT '';    Content NVARCHAR(MAX),

    AuthorName NVARCHAR(100) NOT NULL,

-- ============================================================================    PublishDate DATE DEFAULT CAST(GETDATE() AS DATE),

-- PART 5: HR Schema - Departments Table    ViewCount INT DEFAULT 0,

-- ============================================================================    IsPublished BIT DEFAULT 0,

    CreatedAt DATETIME2 DEFAULT SYSDATETIME(),

PRINT 'PART 5: Creating HR.Departments';    UpdatedAt DATETIME2 DEFAULT SYSDATETIME()

PRINT '===============================';);

PRINT '';

INSERT INTO Articles (Title, Content, AuthorName)

CREATE TABLE HR.Departments (VALUES 

    DepartmentID INT PRIMARY KEY IDENTITY(1,1),    (N'Getting Started with SQL', N'SQL is...', N'Jane Doe'),

    DepartmentName NVARCHAR(100) NOT NULL UNIQUE,    (N'Advanced Queries', N'Learn about...', N'John Smith');

    Location NVARCHAR(100),

    ManagerID INT NULL                            -- Will link to Employees laterSELECT 

);    ArticleID,

    Title,

PRINT '✓ HR.Departments table created';    AuthorName,

PRINT '';    PublishDate,

    ViewCount,

-- ============================================================================    IsPublished

-- PART 6: HR Schema - Employees TableFROM Articles;

-- ============================================================================

DROP TABLE Articles;

PRINT 'PART 6: Creating HR.Employees';PRINT '';

PRINT '=============================';

PRINT '';-- ============================================================================

PRINT 'New Data Types:';-- PRACTICE EXERCISES

PRINT '  MONEY         - Currency values (4 decimal places)';-- ============================================================================

PRINT '';

PRINT 'Practice Exercises:';

CREATE TABLE HR.Employees (PRINT '==================';

    EmployeeID INT PRIMARY KEY IDENTITY(1,1),PRINT '';

    FirstName NVARCHAR(100) NOT NULL,PRINT '1. Create a Books table with: BookID (PK, auto-increment), Title, ISBN, Price';

    LastName NVARCHAR(100) NOT NULL,PRINT '2. Create a Members table with: MemberID (PK), Name, Email, JoinDate (default today)';

    Email VARCHAR(150) UNIQUE NOT NULL,PRINT '3. Insert 3 books into the Books table';

    Phone VARCHAR(20),PRINT '4. Insert 2 members into the Members table';

    JobTitle NVARCHAR(100),PRINT '';

    DepartmentID INT,

    Salary MONEY CHECK (Salary >= 0),             -- MONEY type for currency-- SOLUTIONS:

    HireDate DATE NOT NULL,/*

    BirthDate DATE,-- Exercise 1

    IsActive BIT DEFAULT 1,CREATE TABLE Books (

        BookID INT PRIMARY KEY IDENTITY(1,1),

    CONSTRAINT FK_Employees_Department FOREIGN KEY (DepartmentID)     Title NVARCHAR(200),

        REFERENCES HR.Departments(DepartmentID)    ISBN NVARCHAR(20),

);    Price DECIMAL(10,2)

);

PRINT '✓ HR.Employees table created';

PRINT '  - Salary uses MONEY data type';-- Exercise 2

PRINT '  - Links to Departments via DepartmentID';CREATE TABLE Members (

PRINT '';    MemberID INT PRIMARY KEY,

    Name NVARCHAR(100),

-- Now add ManagerID foreign key to Departments    Email NVARCHAR(100),

ALTER TABLE HR.Departments    JoinDate DATE DEFAULT CAST(GETDATE() AS DATE)

ADD CONSTRAINT FK_Departments_Manager FOREIGN KEY (ManagerID) );

    REFERENCES HR.Employees(EmployeeID);

-- Exercise 3

PRINT '✓ Departments.ManagerID now links to Employees';INSERT INTO Books (Title, ISBN, Price) VALUES

PRINT '';    (N'1984', N'978-0451524935', 15.99),

    (N'To Kill a Mockingbird', N'978-0061120084', 18.99),

-- ============================================================================    (N'The Great Gatsby', N'978-0743273565', 14.99);

-- PART 7: SALES Schema - Orders Table

-- ============================================================================-- Exercise 4

INSERT INTO Members (MemberID, Name, Email) VALUES

PRINT 'PART 7: Creating Sales.Orders';    (1, N'Alice Johnson', N'alice@email.com'),

PRINT '=============================';    (2, N'Bob Smith', N'bob@email.com');

PRINT '';

SELECT * FROM Books;

CREATE TABLE Sales.Orders (SELECT * FROM Members;

    OrderID INT PRIMARY KEY IDENTITY(1000,1),     -- Start at 1000

    CustomerID INT NOT NULL,DROP TABLE Books;

    EmployeeID INT,                                -- Sales personDROP TABLE Members;

    OrderDate DATETIME2 DEFAULT SYSDATETIME(),*/

    RequiredDate DATE,

    ShippedDate DATE,PRINT '';

    ShippingCost DECIMAL(10,2) DEFAULT 0,PRINT '====================================';

    TaxAmount DECIMAL(10,2) DEFAULT 0,PRINT '✓ Lesson 06 Complete!';

    TotalAmount DECIMAL(10,2),PRINT '====================================';

    Status NVARCHAR(20) DEFAULT 'Pending',        -- Pending, Shipped, Delivered, CancelledPRINT '';

    PRINT 'Key Takeaways:';

    CONSTRAINT FK_Orders_Customer FOREIGN KEY (CustomerID) PRINT '  • CREATE TABLE defines table structure';

        REFERENCES Sales.Customers(CustomerID),PRINT '  • Choose appropriate data types for columns';

    CONSTRAINT FK_Orders_Employee FOREIGN KEY (EmployeeID) PRINT '  • PRIMARY KEY ensures unique identification';

        REFERENCES HR.Employees(EmployeeID)PRINT '  • IDENTITY auto-generates IDs';

);PRINT '  • DEFAULT provides automatic values';

PRINT '';

PRINT '✓ Sales.Orders table created';PRINT 'Next: 07-table-constraints.sql (FOREIGN KEY, UNIQUE, NOT NULL)';

PRINT '  - OrderID starts at 1000';PRINT '';

PRINT '  - Links to Customers and Employees';
PRINT '  - OrderDate auto-set to current datetime';
PRINT '';

-- ============================================================================
-- PART 8: SALES Schema - OrderDetails Table
-- ============================================================================

PRINT 'PART 8: Creating Sales.OrderDetails';
PRINT '===================================';
PRINT '';
PRINT 'This table uses COMPOSITE PRIMARY KEY (OrderID + ProductID)';
PRINT '';

CREATE TABLE Sales.OrderDetails (
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),   -- Must order at least 1
    UnitPrice DECIMAL(10,2) NOT NULL,             -- Price at time of order
    Discount DECIMAL(5,2) DEFAULT 0 CHECK (Discount >= 0 AND Discount <= 100),  -- Discount %
    LineTotal AS (Quantity * UnitPrice * (1 - Discount/100)) PERSISTED,  -- Computed column
    
    CONSTRAINT FK_OrderDetails_Order FOREIGN KEY (OrderID) 
        REFERENCES Sales.Orders(OrderID) ON DELETE CASCADE,  -- Delete details when order deleted
    CONSTRAINT FK_OrderDetails_Product FOREIGN KEY (ProductID) 
        REFERENCES Inventory.Products(ProductID)
);

PRINT '✓ Sales.OrderDetails table created';
PRINT '  - LineTotal is a COMPUTED COLUMN (auto-calculated)';
PRINT '  - CASCADE DELETE: deleting order deletes all details';
PRINT '  - Discount must be 0-100%';
PRINT '';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

PRINT '';
PRINT 'Verifying All Tables Created';
PRINT '============================';
PRINT '';

SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id = t.object_id) AS ColumnCount
FROM sys.tables t
WHERE SCHEMA_NAME(t.schema_id) IN ('Sales', 'Inventory', 'HR')
ORDER BY SchemaName, TableName;

PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 02 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Created 8 Tables:';
PRINT '  INVENTORY Schema:';
PRINT '    ✓ Categories (product categories)';
PRINT '    ✓ Suppliers (product suppliers)';
PRINT '    ✓ Products (store inventory)';
PRINT '  SALES Schema:';
PRINT '    ✓ Customers (customer records)';
PRINT '    ✓ Orders (order headers)';
PRINT '    ✓ OrderDetails (order line items)';
PRINT '  HR Schema:';
PRINT '    ✓ Departments (company departments)';
PRINT '    ✓ Employees (employee records)';
PRINT '';
PRINT 'Data Types Learned:';
PRINT '  ✓ INT, IDENTITY - Auto-increment integers';
PRINT '  ✓ NVARCHAR, VARCHAR - Text (Unicode vs ASCII)';
PRINT '  ✓ DECIMAL(p,s) - Exact numbers (prices, money)';
PRINT '  ✓ MONEY - Currency type';
PRINT '  ✓ BIT - Boolean (0/1)';
PRINT '  ✓ DATE - Date only';
PRINT '  ✓ DATETIME2 - Date and time';
PRINT '';
PRINT 'Constraints Learned:';
PRINT '  ✓ PRIMARY KEY - Unique identifier';
PRINT '  ✓ FOREIGN KEY - Relationships between tables';
PRINT '  ✓ UNIQUE - No duplicate values';
PRINT '  ✓ NOT NULL - Required field';
PRINT '  ✓ CHECK - Data validation';
PRINT '  ✓ DEFAULT - Default value';
PRINT '  ✓ COMPUTED COLUMN - Auto-calculated';
PRINT '';
PRINT 'Next: Lesson 03 - Character Data Types (deep dive)';
PRINT '';
PRINT 'IMPORTANT: Tables are now ready for data insertion in Lesson 09!';
PRINT '';
