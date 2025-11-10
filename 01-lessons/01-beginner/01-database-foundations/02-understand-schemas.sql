-- ============================================
-- PHASE 1: DDL - Data Definition Language
-- LESSON 1.2: Understand Schemas
-- ============================================
-- What You'll Learn:
-- - What is a schema?
-- - Why use schemas?
-- - How to create and use schemas
-- ============================================
-- Prerequisites: Run 01-create-database.sql first!
-- ============================================

USE CompanyDB;
GO

-- ============================================
-- WHAT IS A SCHEMA?
-- ============================================
-- A schema is a CONTAINER inside a database
-- It groups related objects together
--
-- Think of it like folders within a folder:
--
-- CompanyDB (Database)
-- ├── dbo (Schema - default)
-- │   ├── Employees (Table)
-- │   └── Departments (Table)
-- ├── Sales (Schema)
-- │   ├── Orders (Table)
-- │   └── Customers (Table)
-- └── HR (Schema)
--     ├── Benefits (Table)
--     └── Payroll (Table)
-- ============================================

-- ============================================
-- DEFAULT SCHEMA: dbo
-- ============================================
-- When you create a table without specifying a schema,
-- it goes into the 'dbo' schema (database owner)

-- These are the same:
-- CREATE TABLE Employees (...)
-- CREATE TABLE dbo.Employees (...)

PRINT 'Understanding the dbo (default) schema...';
GO

-- ============================================
-- WHY USE SCHEMAS?
-- ============================================
-- 1. ORGANIZATION
--    - Group related tables together
--    - Keep your database clean and organized
--
-- 2. SECURITY
--    - Grant permissions to entire schemas
--    - Control who can see what data
--
-- 3. MULTIPLE TEAMS
--    - Sales team has Sales schema
--    - HR team has HR schema
--    - No naming conflicts!
--
-- 4. CLARITY
--    - Sales.Orders vs HR.Orders (different purposes!)
-- ============================================

-- ============================================
-- EXAMPLE: Create Custom Schemas
-- ============================================

-- Create a Sales schema
CREATE SCHEMA Sales;
PRINT '✓ Sales schema created';
GO

-- Create an HR schema
CREATE SCHEMA HR;
PRINT '✓ HR schema created';
GO

-- Create an Inventory schema
CREATE SCHEMA Inventory;
PRINT '✓ Inventory schema created';
GO

-- ============================================
-- VIEW ALL SCHEMAS
-- ============================================
-- See all schemas in the database

SELECT 
    schema_name AS SchemaName,
    schema_id AS SchemaID
FROM INFORMATION_SCHEMA.SCHEMATA
ORDER BY schema_name;

-- Or use system catalog:
SELECT name AS SchemaName
FROM sys.schemas
WHERE name NOT IN ('db_owner', 'db_accessadmin', 'db_securityadmin', 
                   'db_ddladmin', 'db_backupoperator', 'db_datareader', 
                   'db_datawriter', 'db_denydatareader', 'db_denydatawriter')
ORDER BY name;

-- ============================================
-- FOR THIS COURSE: We'll use dbo (simple approach)
-- ============================================
-- To keep things simple for beginners, we'll put
-- all our tables in the default 'dbo' schema.
--
-- You don't need to type 'dbo.' before table names,
-- SQL Server will assume it automatically.
--
-- EXAMPLE:
-- ✓ SELECT * FROM Employees
-- ✓ SELECT * FROM dbo.Employees  (same thing!)
-- ============================================

PRINT '';
PRINT '============================================';
PRINT 'For this beginner course:';
PRINT '- We use the default dbo schema';
PRINT '- No need to type dbo. before table names';
PRINT '- Focus on learning SQL fundamentals!';
PRINT '============================================';
GO

-- ============================================
-- ADVANCED: Using Custom Schemas (Optional)
-- ============================================
-- If you wanted to use custom schemas, here's how:

-- Example 1: Create table in Sales schema
-- CREATE TABLE Sales.Customers (
--     CustomerID INT PRIMARY KEY,
--     CustomerName NVARCHAR(100)
-- );

-- Example 2: Query table in Sales schema
-- SELECT * FROM Sales.Customers;

-- Example 3: Create table in HR schema
-- CREATE TABLE HR.Employees (
--     EmployeeID INT PRIMARY KEY,
--     FullName NVARCHAR(100)
-- );

-- ============================================
-- DROP SCHEMA (Clean up our examples)
-- ============================================
-- We created these schemas for demonstration
-- Let's remove them since we won't use them

DROP SCHEMA Sales;
DROP SCHEMA HR;
DROP SCHEMA Inventory;

PRINT '✓ Example schemas removed (we use dbo)';
GO

-- ============================================
-- KEY TAKEAWAYS
-- ============================================
-- 1. A schema is a container for database objects
-- 2. 'dbo' is the default schema
-- 3. Schemas help organize large databases
-- 4. For this course, we use dbo (simple!)
-- 5. In real projects, you might use multiple schemas
-- ============================================

-- ============================================
-- WHAT WE ACCOMPLISHED
-- ============================================
-- ✓ Learned what schemas are
-- ✓ Understood why they're useful
-- ✓ Decided to use dbo for simplicity
-- ✓ Ready to create tables!
-- ============================================

-- ============================================
-- NEXT: 02-table-creation/01-create-employees-table.sql
-- We'll create our first table!
-- ============================================
