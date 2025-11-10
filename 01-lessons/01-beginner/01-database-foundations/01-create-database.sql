-- ============================================
-- PHASE 1: DDL - Data Definition Language
-- LESSON 1.1: Create Database
-- ============================================
-- What You'll Learn:
-- - How to create a database
-- - How to drop a database
-- - How to use a database
-- ============================================

-- ============================================
-- STEP 1: Check if database exists
-- ============================================
-- Before creating a new database, it's good practice
-- to check if it already exists and remove it for a clean start

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'CompanyDB')
BEGIN
    PRINT 'Database CompanyDB already exists. Dropping it...';
    
    -- Close all connections to the database
    ALTER DATABASE CompanyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    -- Drop (delete) the database
    DROP DATABASE CompanyDB;
    
    PRINT '✓ Old CompanyDB removed';
END
ELSE
BEGIN
    PRINT 'No existing CompanyDB found. Creating new one...';
END
GO

-- ============================================
-- STEP 2: Create the database
-- ============================================
-- CREATE DATABASE is a DDL command
-- It creates a new database on the server

CREATE DATABASE CompanyDB;
GO

PRINT '✓ CompanyDB created successfully!';
GO

-- ============================================
-- STEP 3: Use the database
-- ============================================
-- The USE statement switches the context to CompanyDB
-- All future commands will run inside this database

USE CompanyDB;
GO

PRINT '✓ Now using CompanyDB';
PRINT '✓ Ready to create tables!';
GO

-- ============================================
-- VERIFICATION
-- ============================================
-- Let's verify the database was created

-- Query 1: Check database exists
SELECT 
    name AS DatabaseName,
    database_id AS ID,
    create_date AS CreatedOn,
    compatibility_level AS CompatibilityLevel
FROM sys.databases
WHERE name = 'CompanyDB';

-- Query 2: Confirm we're in the right database
SELECT DB_NAME() AS CurrentDatabase;

-- Query 3: Check database size
EXEC sp_spaceused;

-- ============================================
-- WHAT IS A DATABASE?
-- ============================================
-- A database is a container that holds:
-- - Tables (to store data)
-- - Views (saved queries)
-- - Stored Procedures (saved code)
-- - Functions (reusable logic)
-- - Indexes (for faster queries)
-- - And much more!
--
-- Think of it like a folder on your computer,
-- but specifically designed to store structured data.
-- ============================================

-- ============================================
-- KEY CONCEPTS
-- ============================================
-- DDL = Data Definition Language
-- - CREATE: Make new objects (database, table, etc.)
-- - ALTER: Modify existing objects
-- - DROP: Delete objects
-- - TRUNCATE: Remove all data from table
--
-- These commands define the STRUCTURE of your database
-- ============================================

-- ============================================
-- IMPORTANT NOTES
-- ============================================
-- 1. Database names are case-insensitive in SQL Server
--    (CompanyDB = companydb = COMPANYDB)
--
-- 2. The GO statement is a batch separator
--    It tells SQL Server to execute everything above it
--    before continuing
--
-- 3. Always use meaningful names for databases
--    Good: CompanyDB, SalesDB, InventoryDB
--    Bad: DB1, MyDatabase, Test
-- ============================================

-- ============================================
-- WHAT WE ACCOMPLISHED
-- ============================================
-- ✓ Learned what a database is
-- ✓ Created CompanyDB database
-- ✓ Switched context to CompanyDB
-- ✓ Verified database creation
-- ============================================

-- ============================================
-- NEXT: 02-understand-schemas.sql
-- We'll learn about schemas (organization within database)
-- ============================================
