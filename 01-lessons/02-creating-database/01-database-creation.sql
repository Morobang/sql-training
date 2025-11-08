-- ============================================================================
-- Lesson 01: Database Creation - RetailStore
-- ============================================================================
-- Create the RetailStore database used throughout this training course
-- This database will contain all tables for a multi-department retail business

PRINT 'Lesson 01: Creating RetailStore Database';
PRINT '=========================================';
PRINT '';
PRINT 'This lesson creates the foundation database for all upcoming lessons.';
PRINT 'We will build a complete retail store database with multiple departments.';
PRINT '';

-- ============================================================================
-- Concept 1: CREATE DATABASE
-- ============================================================================

PRINT 'Concept 1: CREATE DATABASE Statement';
PRINT '------------------------------------';
PRINT 'Creates a new database on the SQL Server instance';
PRINT '';

-- Always start from master database
USE master;
GO

-- Drop if exists (for clean re-runs)
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'RetailStore')
BEGIN
    PRINT 'Dropping existing RetailStore database...';
    ALTER DATABASE RetailStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RetailStore;
    PRINT 'Existing database dropped.';
END
GO

-- Create the RetailStore database
CREATE DATABASE RetailStore;
GO

PRINT 'RetailStore database created successfully!';
PRINT '';

-- Verify it was created
SELECT 
    name AS DatabaseName,
    database_id AS ID,
    create_date AS Created,
    state_desc AS State
FROM sys.databases 
WHERE name = 'RetailStore';

PRINT '';

-- ============================================================================
-- Concept 2: USE Database
-- ============================================================================

PRINT 'Concept 2: USE Statement - Switch Database Context';
PRINT '--------------------------------------------------';
PRINT '';

USE RetailStore;
GO

PRINT 'Now working in RetailStore database';
SELECT DB_NAME() AS CurrentDatabase;
PRINT '';

-- ============================================================================
-- Concept 3: CREATE SCHEMA (Organize Database Objects)
-- ============================================================================

PRINT 'Concept 3: CREATE SCHEMA for Organization';
PRINT '-----------------------------------------';
PRINT 'Schemas group related tables logically';
PRINT '';

-- Sales Schema: Customer orders, transactions
CREATE SCHEMA Sales;
GO
PRINT 'Schema [Sales] created - for orders, customers, transactions';

-- Inventory Schema: Products, stock, suppliers
CREATE SCHEMA Inventory;
GO
PRINT 'Schema [Inventory] created - for products, categories, suppliers';

-- HR Schema: Employees, departments, payroll
CREATE SCHEMA HR;
GO
PRINT 'Schema [HR] created - for employees, departments';

PRINT '';
PRINT 'Schemas organize tables into logical groups:';
PRINT '  • Sales.Orders, Sales.Customers';
PRINT '  • Inventory.Products, Inventory.Categories';
PRINT '  • HR.Employees, HR.Departments';
PRINT '';

-- View all schemas
SELECT 
    schema_name AS SchemaName,
    schema_id AS ID
FROM sys.schemas
WHERE schema_name IN ('Sales', 'Inventory', 'HR')
ORDER BY schema_name;

PRINT '';

-- ============================================================================
-- Concept 4: Database Structure Overview
-- ============================================================================

PRINT 'Concept 4: RetailStore Database Structure';
PRINT '-----------------------------------------';
PRINT '';
PRINT 'Our RetailStore will contain:';
PRINT '';
PRINT 'SALES Schema:';
PRINT '  • Sales.Customers    - Customer information';
PRINT '  • Sales.Orders       - Order headers';
PRINT '  • Sales.OrderDetails - Individual order items';
PRINT '';
PRINT 'INVENTORY Schema:';
PRINT '  • Inventory.Categories - Product categories (Electronics, Furniture, etc.)';
PRINT '  • Inventory.Products   - All products in the store';
PRINT '  • Inventory.Suppliers  - Product suppliers';
PRINT '';
PRINT 'HR Schema:';
PRINT '  • HR.Departments - Store departments';
PRINT '  • HR.Employees   - Employee records';
PRINT '';
PRINT 'Note: Tables will be created in Lesson 06 - Table Creation Basics';
PRINT '';

-- ============================================================================
-- Concept 5: Viewing Database Information
-- ============================================================================

PRINT 'Concept 5: Database Information Queries';
PRINT '---------------------------------------';
PRINT '';

-- List all user databases
SELECT 
    name AS DatabaseName,
    database_id AS ID,
    create_date AS Created,
    state_desc AS State,
    recovery_model_desc AS RecoveryModel,
    (SELECT SUM(size) * 8.0 / 1024 FROM sys.master_files WHERE database_id = d.database_id) AS SizeMB
FROM sys.databases d
WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')
ORDER BY name;

PRINT '';

-- ============================================================================
-- Concept 6: DROP DATABASE (Cleanup)
-- ============================================================================

PRINT 'Concept 6: DROP DATABASE';
PRINT '-----------------------';
PRINT 'WARNING: DROP DATABASE permanently deletes everything!';
PRINT '';
PRINT 'To drop RetailStore database:';
PRINT '  USE master;';
PRINT '  DROP DATABASE RetailStore;';
PRINT '';
PRINT 'Do NOT run this now - we need RetailStore for upcoming lessons!';
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Practice Exercises';
PRINT '==================';
PRINT '';
PRINT 'Exercise 1: Create a test database named "TestDB"';
PRINT 'Exercise 2: Switch to TestDB';
PRINT 'Exercise 3: Create a schema called "Testing"';
PRINT 'Exercise 4: Verify TestDB exists using sys.databases';
PRINT 'Exercise 5: Drop TestDB (practice cleanup)';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
-- Exercise 1
USE master;
GO
CREATE DATABASE TestDB;
GO

-- Exercise 2
USE TestDB;
GO

-- Exercise 3
CREATE SCHEMA Testing;
GO

SELECT schema_name FROM sys.schemas WHERE schema_name = 'Testing';

-- Exercise 4
SELECT name, create_date FROM sys.databases WHERE name = 'TestDB';

-- Exercise 5
USE master;
GO
DROP DATABASE IF EXISTS TestDB;
GO

PRINT 'TestDB dropped successfully';
*/

-- ============================================================================
-- SUMMARY
-- ============================================================================

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 01 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'What we created:';
PRINT '  ✓ RetailStore database';
PRINT '  ✓ Sales schema (orders, customers)';
PRINT '  ✓ Inventory schema (products, categories)';
PRINT '  ✓ HR schema (employees, departments)';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  • CREATE DATABASE creates a new database';
PRINT '  • USE DatabaseName switches context';
PRINT '  • CREATE SCHEMA organizes tables logically';
PRINT '  • Schemas use dot notation: Sales.Orders, Inventory.Products';
PRINT '  • DROP DATABASE permanently deletes everything (use carefully!)';
PRINT '';
PRINT 'Next: Lesson 02 - SQL Server Command Line Tools (sqlcmd)';
PRINT '';
PRINT 'IMPORTANT: Keep RetailStore database - all future lessons use it!';
PRINT '';
