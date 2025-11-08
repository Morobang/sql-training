-- ============================================================================
-- Lesson 08: Table Modification
-- ============================================================================
-- Learn: ALTER TABLE, DROP TABLE, TRUNCATE TABLE
-- Prerequisites: 00-setup/01-database-setup-complete.sql

USE BookStore;
GO

PRINT 'Lesson 08: Table Modification';
PRINT '=============================';
PRINT '';

-- ============================================================================
-- CONCEPT 1: ALTER TABLE - Add Columns
-- ============================================================================

PRINT 'Concept 1: Adding Columns';
PRINT '-------------------------';

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100)
);

INSERT INTO Products (ProductName) VALUES (N'Laptop'), (N'Mouse');

-- Add single column
ALTER TABLE Products
ADD Price DECIMAL(10,2);

-- Add column with default
ALTER TABLE Products
ADD InStock BIT DEFAULT 1;

-- Add multiple columns
ALTER TABLE Products
ADD CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE),
    UpdatedDate DATETIME2;

SELECT * FROM Products;

DROP TABLE Products;
PRINT '';

-- ============================================================================
-- CONCEPT 2: ALTER TABLE - Modify Columns
-- ============================================================================

PRINT 'Concept 2: Modifying Columns';
PRINT '----------------------------';

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50),
    Salary INT
);

INSERT INTO Employees (FirstName, Salary) VALUES (N'John', 50000);

-- Change data type
ALTER TABLE Employees
ALTER COLUMN Salary DECIMAL(10,2);

-- Make column NOT NULL (must have no NULLs first)
ALTER TABLE Employees
ALTER COLUMN FirstName NVARCHAR(50) NOT NULL;

-- Increase column size
ALTER TABLE Employees
ALTER COLUMN FirstName NVARCHAR(100);

SELECT * FROM Employees;

DROP TABLE Employees;
PRINT '';

-- ============================================================================
-- CONCEPT 3: ALTER TABLE - Drop Columns
-- ============================================================================

PRINT 'Concept 3: Dropping Columns';
PRINT '---------------------------';

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    OrderDate DATE,
    TotalAmount DECIMAL(10,2),
    TempColumn NVARCHAR(50)
);

-- Drop single column
ALTER TABLE Orders
DROP COLUMN TempColumn;

-- Verify column removed
SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Orders';

DROP TABLE Orders;
PRINT '';

-- ============================================================================
-- CONCEPT 4: ALTER TABLE - Add/Drop Constraints
-- ============================================================================

PRINT 'Concept 4: Managing Constraints';
PRINT '-------------------------------';

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(100),
    Price DECIMAL(10,2),
    SKU NVARCHAR(50)
);

-- Add UNIQUE constraint
ALTER TABLE Products
ADD CONSTRAINT UQ_Products_SKU UNIQUE (SKU);

-- Add CHECK constraint
ALTER TABLE Products
ADD CONSTRAINT CK_Products_Price CHECK (Price > 0);

-- Add DEFAULT constraint
ALTER TABLE Products
ADD CONSTRAINT DF_Products_Price DEFAULT 0 FOR Price;

-- Insert test data
INSERT INTO Products (ProductName, SKU) VALUES (N'Laptop', N'LAP001');

-- Drop constraint
ALTER TABLE Products
DROP CONSTRAINT CK_Products_Price;

-- Add it back with different rule
ALTER TABLE Products
ADD CONSTRAINT CK_Products_Price CHECK (Price >= 0);

DROP TABLE Products;
PRINT '';

-- ============================================================================
-- CONCEPT 5: DROP TABLE vs TRUNCATE TABLE
-- ============================================================================

PRINT 'Concept 5: DROP vs TRUNCATE';
PRINT '---------------------------';

-- DROP TABLE: Removes table completely
CREATE TABLE TempTable1 (
    ID INT PRIMARY KEY,
    Data NVARCHAR(100)
);

INSERT INTO TempTable1 VALUES (1, N'Test');

DROP TABLE TempTable1;  -- Table no longer exists

-- TRUNCATE TABLE: Removes all data, keeps structure
CREATE TABLE TempTable2 (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Data NVARCHAR(100)
);

INSERT INTO TempTable2 (Data) VALUES (N'Row 1'), (N'Row 2'), (N'Row 3');
SELECT * FROM TempTable2;

TRUNCATE TABLE TempTable2;  -- All data removed, table still exists

SELECT * FROM TempTable2;  -- Empty, but structure remains

-- IDENTITY resets after TRUNCATE
INSERT INTO TempTable2 (Data) VALUES (N'New Row 1');
SELECT * FROM TempTable2;  -- ID starts at 1 again

DROP TABLE TempTable2;

PRINT '';
PRINT 'DROP vs TRUNCATE:';
PRINT '  DROP TABLE:';
PRINT '    • Removes table completely';
PRINT '    • Cannot be undone (unless in transaction)';
PRINT '    • Removes structure and data';
PRINT '';
PRINT '  TRUNCATE TABLE:';
PRINT '    • Removes all data';
PRINT '    • Keeps table structure';
PRINT '    • Resets IDENTITY counter';
PRINT '    • Faster than DELETE (no logging each row)';
PRINT '';

-- ============================================================================
-- CONCEPT 6: Complete Modification Example
-- ============================================================================

PRINT 'Concept 6: Complete Table Evolution';
PRINT '-----------------------------------';

-- Start with basic table
CREATE TABLE Articles (
    ArticleID INT PRIMARY KEY IDENTITY(1,1),
    Title NVARCHAR(200)
);

PRINT 'Step 1: Initial table created';

-- Add columns
ALTER TABLE Articles
ADD AuthorName NVARCHAR(100),
    PublishDate DATE,
    ViewCount INT;

PRINT 'Step 2: Columns added';

-- Add constraints
ALTER TABLE Articles
ADD CONSTRAINT DF_Articles_ViewCount DEFAULT 0 FOR ViewCount;

ALTER TABLE Articles
ADD CONSTRAINT CK_Articles_ViewCount CHECK (ViewCount >= 0);

PRINT 'Step 3: Constraints added';

-- Make column required
ALTER TABLE Articles
ALTER COLUMN Title NVARCHAR(200) NOT NULL;

PRINT 'Step 4: Title made required';

-- Add test data
INSERT INTO Articles (Title, AuthorName, PublishDate)
VALUES (N'Introduction to SQL', N'Jane Doe', '2025-01-15');

SELECT * FROM Articles;

-- Clean up column
ALTER TABLE Articles
DROP COLUMN ViewCount;

PRINT 'Step 5: ViewCount column removed';

SELECT * FROM Articles;

DROP TABLE Articles;
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT 'Practice Exercises:';
PRINT '==================';
PRINT '';
PRINT '1. Create table Students with StudentID and Name';
PRINT '2. Add column Email (NVARCHAR(100))';
PRINT '3. Add column GPA (DECIMAL(3,2)) with CHECK constraint (0-4.0)';
PRINT '4. Make Name column NOT NULL';
PRINT '5. Add UNIQUE constraint on Email';
PRINT '6. Insert 2 students';
PRINT '7. TRUNCATE the table';
PRINT '';

-- SOLUTIONS:
/*
-- Exercise 1
CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100)
);

-- Exercise 2
ALTER TABLE Students
ADD Email NVARCHAR(100);

-- Exercise 3
ALTER TABLE Students
ADD GPA DECIMAL(3,2);

ALTER TABLE Students
ADD CONSTRAINT CK_Students_GPA CHECK (GPA BETWEEN 0 AND 4.0);

-- Exercise 4
ALTER TABLE Students
ALTER COLUMN Name NVARCHAR(100) NOT NULL;

-- Exercise 5
ALTER TABLE Students
ADD CONSTRAINT UQ_Students_Email UNIQUE (Email);

-- Exercise 6
INSERT INTO Students (Name, Email, GPA) VALUES
    (N'Alice Johnson', N'alice@university.edu', 3.75),
    (N'Bob Smith', N'bob@university.edu', 3.50);

SELECT * FROM Students;

-- Exercise 7
TRUNCATE TABLE Students;
SELECT * FROM Students;  -- Empty

DROP TABLE Students;
*/

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 08 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  • ALTER TABLE ADD COLUMN adds new columns';
PRINT '  • ALTER TABLE ALTER COLUMN modifies existing columns';
PRINT '  • ALTER TABLE DROP COLUMN removes columns';
PRINT '  • ALTER TABLE ADD/DROP CONSTRAINT manages constraints';
PRINT '  • DROP TABLE removes entire table';
PRINT '  • TRUNCATE TABLE removes all data but keeps structure';
PRINT '';
PRINT 'Next: 09-data-insertion.sql (INSERT operations)';
PRINT '';
