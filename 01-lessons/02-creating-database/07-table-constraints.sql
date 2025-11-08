-- ============================================================================
-- Lesson 07: Table Constraints & Relationships
-- ============================================================================
-- Learn: FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT, CHECK constraints
-- Prerequisites: 00-setup/01-database-setup-complete.sql

USE BookStore;
GO

PRINT 'Lesson 07: Table Constraints & Relationships';
PRINT '============================================';
PRINT '';

-- ============================================================================
-- CONCEPT 1: FOREIGN KEY Constraints
-- ============================================================================

PRINT 'Concept 1: Foreign Key Relationships';
PRINT '------------------------------------';

-- Parent table
CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY IDENTITY(1,1),
    AuthorName NVARCHAR(100) NOT NULL
);

-- Child table with foreign key
CREATE TABLE Books (
    BookID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200) NOT NULL,
    AuthorID INT,
    CONSTRAINT FK_Books_Authors FOREIGN KEY (AuthorID) 
        REFERENCES Authors(AuthorID)
);

-- Insert data
INSERT INTO Authors (AuthorName) VALUES (N'George Orwell'), (N'Jane Austen');
INSERT INTO Books (Title, AuthorID) VALUES 
    (N'1984', 1),
    (N'Animal Farm', 1),
    (N'Pride and Prejudice', 2);

-- Try invalid foreign key - will fail!
-- INSERT INTO Books (Title, AuthorID) VALUES (N'Unknown Book', 999);  -- Error!

SELECT 
    b.BookID,
    b.Title,
    a.AuthorName
FROM Books b
JOIN Authors a ON b.AuthorID = a.AuthorID;

DROP TABLE Books;
DROP TABLE Authors;
PRINT '';

-- ============================================================================
-- CONCEPT 2: UNIQUE Constraints
-- ============================================================================

PRINT 'Concept 2: Unique Constraints';
PRINT '-----------------------------';

CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) UNIQUE,           -- Method 1: Inline
    Email NVARCHAR(100),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)  -- Method 2: Named constraint
);

INSERT INTO Users (Username, Email) VALUES 
    (N'john_doe', N'john@email.com'),
    (N'jane_doe', N'jane@email.com');

-- Try duplicate username - will fail!
-- INSERT INTO Users (Username, Email) VALUES (N'john_doe', N'other@email.com');  -- Error!

-- Try duplicate email - will fail!
-- INSERT INTO Users (Username, Email) VALUES (N'other_user', N'john@email.com');  -- Error!

SELECT * FROM Users;

DROP TABLE Users;
PRINT '';

-- ============================================================================
-- CONCEPT 3: NOT NULL Constraints
-- ============================================================================

PRINT 'Concept 3: NOT NULL Constraints';
PRINT '-------------------------------';

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100) NOT NULL,     -- Required field
    Description NVARCHAR(MAX),              -- Optional field
    Price DECIMAL(10,2) NOT NULL,           -- Required field
    SKU NVARCHAR(50) NOT NULL               -- Required field
);

INSERT INTO Products (ProductName, Price, SKU)
VALUES (N'Laptop', 999.99, N'LAP001');

-- Try NULL in required field - will fail!
-- INSERT INTO Products (ProductName, Price) VALUES (N'Mouse', 29.99);  -- Error! SKU required

SELECT * FROM Products;

DROP TABLE Products;
PRINT '';

-- ============================================================================
-- CONCEPT 4: DEFAULT Constraints
-- ============================================================================

PRINT 'Concept 4: Default Values';
PRINT '-------------------------';

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    OrderDate DATE DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(20) DEFAULT N'Pending',
    TotalAmount DECIMAL(10,2) DEFAULT 0.00,
    IsRushOrder BIT DEFAULT 0
);

-- Insert without specifying defaults
INSERT INTO Orders (TotalAmount) VALUES (150.00);
INSERT INTO Orders (TotalAmount, Status) VALUES (200.00, N'Shipped');

SELECT * FROM Orders;

DROP TABLE Orders;
PRINT '';

-- ============================================================================
-- CONCEPT 5: CHECK Constraints
-- ============================================================================

PRINT 'Concept 5: Check Constraints';
PRINT '----------------------------';

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Age INT CHECK (Age >= 18 AND Age <= 100),
    Salary DECIMAL(10,2) CHECK (Salary > 0),
    Email NVARCHAR(100) CHECK (Email LIKE '%@%.%'),
    Department NVARCHAR(50) CHECK (Department IN (N'Sales', N'IT', N'HR', N'Marketing'))
);

-- Valid inserts
INSERT INTO Employees (FirstName, LastName, Age, Salary, Email, Department)
VALUES 
    (N'John', N'Doe', 30, 50000, N'john@company.com', N'IT'),
    (N'Jane', N'Smith', 25, 45000, N'jane@company.com', N'Sales');

-- Invalid inserts - will fail!
-- INSERT INTO Employees (FirstName, LastName, Age, Salary, Email, Department)
-- VALUES (N'Young', N'Person', 15, 30000, N'young@company.com', N'IT');  -- Age < 18

-- INSERT INTO Employees (FirstName, LastName, Age, Salary, Email, Department)
-- VALUES (N'Bad', N'Email', 30, 40000, N'bademail', N'IT');  -- Invalid email format

SELECT * FROM Employees;

DROP TABLE Employees;
PRINT '';

-- ============================================================================
-- CONCEPT 6: Complete Example with All Constraints
-- ============================================================================

PRINT 'Concept 6: Complete Table with All Constraints';
PRINT '----------------------------------------------';

-- Parent table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(100) NOT NULL UNIQUE,
    CustomerName NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    JoinDate DATE DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(20) DEFAULT N'Active' CHECK (Status IN (N'Active', N'Inactive', N'Suspended'))
);

-- Child table
CREATE TABLE CustomerOrders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    OrderDate DATE DEFAULT CAST(GETDATE() AS DATE),
    TotalAmount DECIMAL(10,2) NOT NULL CHECK (TotalAmount >= 0),
    ShippingFee DECIMAL(10,2) DEFAULT 5.99 CHECK (ShippingFee >= 0),
    OrderStatus NVARCHAR(20) DEFAULT N'Pending' 
        CHECK (OrderStatus IN (N'Pending', N'Processing', N'Shipped', N'Delivered', N'Cancelled')),
    CONSTRAINT FK_CustomerOrders_Customers FOREIGN KEY (CustomerID) 
        REFERENCES Customers(CustomerID)
);

-- Insert test data
INSERT INTO Customers (Email, CustomerName, Phone) VALUES
    (N'alice@email.com', N'Alice Johnson', N'555-0101'),
    (N'bob@email.com', N'Bob Smith', N'555-0102');

INSERT INTO CustomerOrders (CustomerID, TotalAmount) VALUES
    (1, 150.00),
    (1, 75.50),
    (2, 200.00);

-- Query with relationship
SELECT 
    c.CustomerName,
    c.Email,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount,
    o.ShippingFee,
    o.TotalAmount + o.ShippingFee AS GrandTotal,
    o.OrderStatus
FROM Customers c
JOIN CustomerOrders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerName, o.OrderDate;

DROP TABLE CustomerOrders;
DROP TABLE Customers;
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT 'Practice Exercises:';
PRINT '==================';
PRINT '';
PRINT '1. Create Departments table with DeptID (PK) and DeptName (UNIQUE, NOT NULL)';
PRINT '2. Create Staff table with foreign key to Departments';
PRINT '3. Add CHECK constraint: Salary between 20000 and 200000';
PRINT '4. Add DEFAULT constraint: HireDate = today';
PRINT '';

-- SOLUTIONS:
/*
-- Exercise 1
CREATE TABLE Departments (
    DeptID INT PRIMARY KEY IDENTITY(1,1),
    DeptName NVARCHAR(100) NOT NULL UNIQUE
);

-- Exercise 2 & 3 & 4
CREATE TABLE Staff (
    StaffID INT PRIMARY KEY IDENTITY(1,1),
    StaffName NVARCHAR(100) NOT NULL,
    DeptID INT NOT NULL,
    Salary DECIMAL(10,2) CHECK (Salary BETWEEN 20000 AND 200000),
    HireDate DATE DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT FK_Staff_Departments FOREIGN KEY (DeptID) 
        REFERENCES Departments(DeptID)
);

-- Test data
INSERT INTO Departments (DeptName) VALUES (N'Engineering'), (N'Sales');
INSERT INTO Staff (StaffName, DeptID, Salary) VALUES
    (N'Alice', 1, 75000),
    (N'Bob', 2, 65000);

SELECT * FROM Staff;

DROP TABLE Staff;
DROP TABLE Departments;
*/

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 07 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  • FOREIGN KEY creates relationships between tables';
PRINT '  • UNIQUE ensures no duplicate values';
PRINT '  • NOT NULL makes fields required';
PRINT '  • DEFAULT provides automatic values';
PRINT '  • CHECK validates data against conditions';
PRINT '';
PRINT 'Next: 08-table-modification.sql (ALTER TABLE, DROP, TRUNCATE)';
PRINT '';
