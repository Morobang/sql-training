-- ============================================
-- PHASE 1: DDL - Data Definition Language
-- LESSON 2.3: Create Products Table
-- ============================================
-- What You'll Learn:
-- - More data type variations
-- - BIT data type (True/False)
-- - DATETIME vs DATE
-- - DEFAULT values
-- ============================================
-- Prerequisites: Run previous table creation files!
-- ============================================

USE CompanyDB;
GO

-- ============================================
-- CREATE PRODUCTS TABLE
-- ============================================
-- Our tech company sells products
-- Let's track them in a database!

CREATE TABLE Products (
    ProductID INT NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    ProductCode NVARCHAR(20) NOT NULL,
    Description NVARCHAR(500),
    Category NVARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2),
    StockQuantity INT DEFAULT 0,
    ReorderLevel INT DEFAULT 10,
    IsActive BIT DEFAULT 1,
    LaunchDate DATE,
    LastUpdated DATETIME DEFAULT GETDATE()
);

PRINT '✓ Products table created';
GO

-- ============================================
-- NEW DATA TYPES INTRODUCED
-- ============================================

-- BIT
-- - Stores True/False, Yes/No, 1/0
-- - Uses only 1 bit of storage (very small!)
-- - Example: IsActive BIT
--   1 or TRUE  = Product is active
--   0 or FALSE = Product is discontinued
--
-- DATETIME
-- - Stores both date AND time
-- - Format: 'YYYY-MM-DD HH:MM:SS'
-- - Example: '2024-11-10 14:30:00'
-- - More precise than DATE
--
-- DATE vs DATETIME:
-- - DATE: '2024-11-10' (just the day)
-- - DATETIME: '2024-11-10 14:30:00' (day + time)
-- ============================================

-- ============================================
-- DEFAULT VALUES
-- ============================================
-- DEFAULT sets a value when you don't provide one
--
-- StockQuantity INT DEFAULT 0
-- ↓
-- If you don't specify stock, it automatically becomes 0
--
-- Example:
-- INSERT INTO Products (ProductID, ProductName, Price)
-- VALUES (1, 'Mouse', 29.99);
-- -- StockQuantity will be 0 (the default!)
-- -- IsActive will be 1 (the default!)
-- -- LastUpdated will be current date/time (GETDATE())
-- ============================================

-- ============================================
-- GETDATE() FUNCTION
-- ============================================
-- GETDATE() returns the current date and time
--
-- LastUpdated DATETIME DEFAULT GETDATE()
-- ↓
-- Automatically records when the row was created!
--
-- Try it:
SELECT GETDATE() AS CurrentDateTime;
-- Result: 2024-11-10 14:30:00.000 (current time)

-- ============================================
-- UNDERSTANDING EACH COLUMN
-- ============================================
-- ProductID
-- - Unique identifier (will become PRIMARY KEY later)
-- - INT, NOT NULL
--
-- ProductName
-- - Name of the product
-- - NVARCHAR(100) - up to 100 characters
-- - NOT NULL (every product needs a name!)
--
-- ProductCode
-- - Unique code like "WMP-001" for Wireless Mouse Pro
-- - NVARCHAR(20)
-- - NOT NULL (required for inventory)
--
-- Description
-- - Detailed description of the product
-- - NVARCHAR(500) - up to 500 characters
-- - Can be NULL (optional)
--
-- Category
-- - Product category (Accessories, Storage, Audio, etc.)
-- - Can be NULL
--
-- Price
-- - Selling price
-- - DECIMAL(10,2) - allows $99,999,999.99
-- - NOT NULL (must have a price!)
--
-- Cost
-- - What we paid for the product (cost basis)
-- - DECIMAL(10,2)
-- - Can be NULL (might not track costs)
--
-- StockQuantity
-- - How many units in stock
-- - INT, DEFAULT 0
-- - If not specified, starts at 0
--
-- ReorderLevel
-- - When to reorder more stock
-- - INT, DEFAULT 10
-- - Alert when stock drops below this!
--
-- IsActive
-- - Is product currently sold?
-- - BIT, DEFAULT 1 (true)
-- - 1 = Active, 0 = Discontinued
--
-- LaunchDate
-- - When product was first introduced
-- - DATE (no time needed)
-- - Can be NULL
--
-- LastUpdated
-- - When was this record last modified
-- - DATETIME, DEFAULT GETDATE()
-- - Automatically tracks changes!
-- ============================================

-- ============================================
-- VIEW TABLE STRUCTURE
-- ============================================

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Products'
ORDER BY ORDINAL_POSITION;

-- Notice the DEFAULT values appear in COLUMN_DEFAULT!

-- ============================================
-- VIEW ALL TABLES
-- ============================================

SELECT TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Should show:
-- - Departments
-- - Employees
-- - Products

PRINT '';
PRINT '✓ We now have 3 tables in CompanyDB!';
GO

-- ============================================
-- COMPARING DATA TYPES ACROSS TABLES
-- ============================================
--
-- Table          | ID Type | Name Type       | Money Type
-- ---------------+---------+-----------------+-------------
-- Employees      | INT     | NVARCHAR(50)    | DECIMAL(10,2)
-- Departments    | INT     | NVARCHAR(50)    | DECIMAL(12,2)
-- Products       | INT     | NVARCHAR(100)   | DECIMAL(10,2)
--
-- Notice:
-- - All IDs are INT (consistency!)
-- - Products.ProductName is longer (100 vs 50)
-- - Department.Budget is bigger (12 digits vs 10)
-- ============================================

-- ============================================
-- WHY USE BIT INSTEAD OF INT FOR IsActive?
-- ============================================
-- You could do this:
--   IsActive INT  (0 or 1)
--
-- But BIT is better because:
-- 1. Uses less storage (1 bit vs 32 bits)
-- 2. Clearly indicates True/False purpose
-- 3. Prevents invalid values (can't be 2, 3, 100, etc.)
--
-- BIT is the right tool for boolean (yes/no) data!
-- ============================================

-- ============================================
-- PRACTICE QUESTIONS
-- ============================================

-- Question 1: Which columns have DEFAULT values?
-- Answer: StockQuantity (0), ReorderLevel (10), IsActive (1), LastUpdated (GETDATE())

-- Question 2: What's the difference between DATE and DATETIME?
-- Answer: DATE = date only, DATETIME = date + time

-- Question 3: What does BIT data type store?
-- Answer: True/False values (1 or 0)

-- Question 4: What does GETDATE() do?
-- Answer: Returns current date and time

-- Question 5: Why is ProductCode NOT NULL?
-- Answer: Every product needs a unique code for tracking

-- ============================================
-- DEFAULT VALUE DEMONSTRATION
-- ============================================

-- Example of how defaults work (don't run yet - just read!)
/*
-- When you insert with defaults:
INSERT INTO Products (ProductID, ProductName, ProductCode, Price)
VALUES (1, 'Wireless Mouse', 'WMP-001', 49.99);

-- Result:
-- ProductID: 1
-- ProductName: 'Wireless Mouse'
-- ProductCode: 'WMP-001'
-- Price: 49.99
-- StockQuantity: 0 (DEFAULT!)
-- ReorderLevel: 10 (DEFAULT!)
-- IsActive: 1 (DEFAULT!)
-- LastUpdated: 2024-11-10 14:30:00 (GETDATE()!)
-- Other columns: NULL
*/

-- ============================================
-- WHAT WE ACCOMPLISHED
-- ============================================
-- ✓ Created Products table
-- ✓ Learned BIT data type (True/False)
-- ✓ Learned DATETIME vs DATE
-- ✓ Used DEFAULT values
-- ✓ Used GETDATE() function
-- ✓ Now have 3 tables in CompanyDB
-- ============================================

-- ============================================
-- CURRENT PROGRESS
-- ============================================
-- CompanyDB
-- ├── Employees    (8 columns, no PK yet)
-- ├── Departments  (6 columns, no PK yet)
-- └── Products     (12 columns, no PK yet)
--
-- Next up:
-- - Learn more about data types
-- - Then add Primary Keys!
-- - Then add Foreign Keys!
-- ============================================

-- ============================================
-- NEXT: 04-understand-data-types.sql
-- Deep dive into SQL Server data types!
-- ============================================
