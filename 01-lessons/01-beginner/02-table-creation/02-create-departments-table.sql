-- ============================================
-- PHASE 1: DDL - Data Definition Language
-- LESSON 2.2: Create Departments Table
-- ============================================
-- What You'll Learn:
-- - Create a second table
-- - More data type examples
-- - Relationship planning (not implementing yet!)
-- ============================================
-- Prerequisites: Run 01-create-employees-table.sql first!
-- ============================================

USE CompanyDB;
GO

-- ============================================
-- CREATE DEPARTMENTS TABLE
-- ============================================
-- Every employee works in a department
-- Let's create a table to track departments

CREATE TABLE Departments (
    DepartmentID INT NOT NULL,
    DepartmentName NVARCHAR(50) NOT NULL,
    Location NVARCHAR(100),
    ManagerID INT,
    Budget DECIMAL(12,2),
    EstablishedDate DATE
);

PRINT '✓ Departments table created';
GO

-- ============================================
-- UNDERSTANDING THIS TABLE
-- ============================================
-- DepartmentID
-- - Unique identifier for each department
-- - INT type (whole number)
-- - NOT NULL (required)
--
-- DepartmentName
-- - Name of the department (IT, Sales, HR, etc.)
-- - NVARCHAR(50) - up to 50 characters
-- - NOT NULL (every department needs a name!)
--
-- Location
-- - Where the department is located
-- - Can be NULL (some departments might be remote)
--
-- ManagerID
-- - Will link to an Employee who manages this department
-- - For now, just a number (we'll add relationships later!)
-- - Can be NULL (department might not have a manager yet)
--
-- Budget
-- - Department's annual budget
-- - DECIMAL(12,2) - up to $9,999,999,999.99
-- - Can be NULL (budget might not be set yet)
--
-- EstablishedDate
-- - When the department was created
-- - Can be NULL (might not know historical data)
-- ============================================

-- ============================================
-- VIEW THE TABLE STRUCTURE
-- ============================================

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Departments'
ORDER BY ORDINAL_POSITION;

-- ============================================
-- HOW TABLES RELATE (Concept Only)
-- ============================================
-- Think about the relationship:
--
-- Departments Table          Employees Table
-- ┌─────────────────┐       ┌──────────────────┐
-- │ DepartmentID: 1 │◄──────│ DepartmentID: 1  │
-- │ Name: IT        │       │ Name: John Smith │
-- └─────────────────┘       └──────────────────┘
--                           ┌──────────────────┐
--                           │ DepartmentID: 1  │
--                           │ Name: Sarah Lee  │
--                           └──────────────────┘
--
-- Multiple employees can work in ONE department
-- We'll connect them with Foreign Keys in Lesson 3!
-- ============================================

-- ============================================
-- VIEW ALL TABLES IN DATABASE
-- ============================================

-- See all tables we've created so far
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Should show:
-- - Departments
-- - Employees

-- ============================================
-- COMPARING DECIMAL SIZES
-- ============================================
-- Why DECIMAL(12,2) for Budget vs DECIMAL(10,2) for Salary?
--
-- Salary: DECIMAL(10,2)
-- - Max: $99,999,999.99 (99 million)
-- - Enough for individual salaries
--
-- Budget: DECIMAL(12,2)
-- - Max: $9,999,999,999.99 (9 billion)
-- - Departments handle more money than individuals!
--
-- Choose size based on your data needs!
-- ============================================

-- ============================================
-- WHAT ABOUT MANAGERID?
-- ============================================
-- Notice: ManagerID is just INT for now
-- Later we'll add a constraint that says:
-- "ManagerID must be a valid EmployeeID"
--
-- This is called a FOREIGN KEY
-- We'll learn about it in Lesson 3.2!
-- ============================================

-- ============================================
-- PRACTICE QUESTIONS
-- ============================================

-- Question 1: How many NOT NULL columns in Departments?
-- Answer: 2 (DepartmentID, DepartmentName)

-- Question 2: Which column will link to Employees table?
-- Answer: ManagerID (links to EmployeeID)

-- Question 3: What's the maximum budget a department can have?
-- Answer: $9,999,999,999.99

-- Question 4: Can a department exist without a location?
-- Answer: Yes! Location allows NULL

-- ============================================
-- TABLE DESIGN TIPS
-- ============================================
-- 1. Use meaningful names
--    ✓ DepartmentName
--    ❌ Dept or D_Name
--
-- 2. Make key columns NOT NULL
--    ✓ DepartmentID NOT NULL
--    ✓ DepartmentName NOT NULL
--
-- 3. Allow NULL for optional data
--    ✓ Location can be NULL
--    ✓ Budget can be NULL
--
-- 4. Use appropriate data types
--    ✓ Budget: DECIMAL (needs precision)
--    ❌ Budget: INT (loses cents!)
-- ============================================

-- ============================================
-- WHAT WE ACCOMPLISHED
-- ============================================
-- ✓ Created Departments table
-- ✓ Used appropriate data types
-- ✓ Planned relationships (to implement later)
-- ✓ Now have 2 tables in CompanyDB
-- ============================================

-- ============================================
-- CURRENT DATABASE STRUCTURE
-- ============================================
-- CompanyDB
-- ├── Employees (no primary key yet)
-- └── Departments (no primary key yet)
--
-- Coming next:
-- - More tables (Products)
-- - Primary keys
-- - Foreign keys
-- - Relationships!
-- ============================================

-- ============================================
-- NEXT: 03-create-products-table.sql
-- We'll add a Products table for our tech company!
-- ============================================
