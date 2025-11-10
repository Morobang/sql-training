-- ============================================
-- PHASE 1: DDL - Data Definition Language  
-- LESSON 2.1: Create Employees Table
-- ============================================
-- What You'll Learn:
-- - CREATE TABLE syntax
-- - Basic column definitions
-- - NOT NULL constraint
-- - Table without primary key (we'll add it later!)
-- ============================================
-- Prerequisites: Run all files in 01-database-foundations/
-- ============================================

USE CompanyDB;
GO

-- ============================================
-- CREATE EMPLOYEES TABLE (Simple Version)
-- ============================================
-- We'll start simple and improve it later
-- No primary key yet - just basic structure!

CREATE TABLE Employees (
    EmployeeID INT NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    PhoneNumber NVARCHAR(20),
    HireDate DATE NOT NULL,
    Salary DECIMAL(10,2),
    JobTitle NVARCHAR(100)
);

PRINT '✓ Employees table created (basic structure)';
GO

-- ============================================
-- UNDERSTANDING THE SYNTAX
-- ============================================
-- CREATE TABLE TableName (
--     ColumnName DataType [NULL | NOT NULL],
--     ColumnName DataType [NULL | NOT NULL],
--     ...
-- );
--
-- Parts explained:
-- - EmployeeID INT NOT NULL
--   └─ Column name: EmployeeID
--   └─ Data type: INT (whole numbers)
--   └─ Constraint: NOT NULL (must have value)
-- ============================================

-- ============================================
-- VIEW TABLE STRUCTURE
-- ============================================

-- Method 1: Using INFORMATION_SCHEMA
SELECT 
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    IS_NULLABLE AS AllowsNull
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Employees'
ORDER BY ORDINAL_POSITION;

-- Method 2: Using sp_help (shorter!)
EXEC sp_help 'Employees';

-- Method 3: Using sp_columns
EXEC sp_columns 'Employees';

-- ============================================
-- WHY NO PRIMARY KEY YET?
-- ============================================
-- We're learning step by step:
-- 1. First, create basic table structure (THIS LESSON)
-- 2. Then, learn about Primary Keys (Lesson 3.1)
-- 3. Then, add Foreign Keys (Lesson 3.2)
-- 4. Then, add other constraints (Lesson 3.3)
--
-- This progressive approach helps you understand
-- what each piece does!
-- ============================================

-- ============================================
-- DATA TYPES USED
-- ============================================
-- INT
-- - Whole numbers from -2,147,483,648 to 2,147,483,647
-- - Used for: IDs, quantities, years
-- - Example: 1, 42, 1000
--
-- NVARCHAR(n)
-- - Text with up to n characters
-- - N = Unicode (supports all languages: 中文, العربية, Español)
-- - Used for: names, addresses, emails
-- - Example: 'John', 'john@company.com'
--
-- DATE
-- - Date only (no time)
-- - Format: 'YYYY-MM-DD'
-- - Example: '2024-01-15'
--
-- DECIMAL(10,2)
-- - Numbers with decimals
-- - (10,2) = 10 total digits, 2 after decimal
-- - Used for: money, prices, percentages
-- - Example: 75000.00, 99.99
-- ============================================

-- ============================================
-- NOT NULL CONSTRAINT
-- ============================================
-- NOT NULL means the column MUST have a value
--
-- EmployeeID INT NOT NULL
-- ↓
-- This will WORK:
--   INSERT INTO Employees (EmployeeID, ...) VALUES (1, ...)
--
-- This will FAIL:
--   INSERT INTO Employees (EmployeeID, ...) VALUES (NULL, ...)
--   Error: Cannot insert NULL into EmployeeID
--
-- Columns WITHOUT NOT NULL can be empty (NULL)
-- ============================================

-- ============================================
-- CHECK IF TABLE EXISTS
-- ============================================

-- Query 1: Check table exists
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'Employees';

-- Query 2: Count tables in database
SELECT COUNT(*) AS TotalTables
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- ============================================
-- WHAT IS NULL?
-- ============================================
-- NULL means "no value" or "unknown"
-- It's NOT the same as:
-- - Empty string ('')
-- - Zero (0)
-- - False
--
-- Example:
-- - Email = NULL      → We don't know the email
-- - Email = ''        → Email is empty string
-- - PhoneNumber = NULL → No phone number provided
-- ============================================

-- ============================================
-- PRACTICE UNDERSTANDING
-- ============================================

-- Question 1: Which columns are required (NOT NULL)?
-- Answer: EmployeeID, FirstName, LastName, HireDate

-- Question 2: Which columns can be empty?
-- Answer: Email, PhoneNumber, Salary, JobTitle

-- Question 3: What data type is used for names?
-- Answer: NVARCHAR(50)

-- Question 4: What data type is used for salary?
-- Answer: DECIMAL(10,2)

-- ============================================
-- COMMON MISTAKES TO AVOID
-- ============================================
-- ❌ CREATE TABLE employees (...)  -- lowercase
-- ✓ CREATE TABLE Employees (...)   -- clear naming
--
-- ❌ FirstName VARCHAR(50)         -- no Unicode support
-- ✓ FirstName NVARCHAR(50)         -- supports all languages
--
-- ❌ Salary INT                    -- no decimals!
-- ✓ Salary DECIMAL(10,2)           -- supports $75,000.50
-- ============================================

-- ============================================
-- WHAT WE ACCOMPLISHED
-- ============================================
-- ✓ Created Employees table
-- ✓ Used INT, NVARCHAR, DATE, DECIMAL data types
-- ✓ Applied NOT NULL constraints
-- ✓ Learned how to view table structure
-- ✓ Table has NO primary key yet (intentional!)
-- ============================================

-- ============================================
-- NEXT: 02-create-departments-table.sql
-- We'll create the Departments table!
-- ============================================
