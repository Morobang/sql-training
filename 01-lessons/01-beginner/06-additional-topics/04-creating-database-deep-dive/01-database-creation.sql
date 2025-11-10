-- ============================================================================
-- Lesson 01: Database Creation
-- ============================================================================
-- Learn: CREATE DATABASE, CREATE SCHEMA
-- ============================================================================

-- Create the RetailStore database
CREATE DATABASE RetailStore;
GO

-- Switch to the new database
USE RetailStore;
GO

-- Create schemas to organize tables
CREATE SCHEMA Inventory;
CREATE SCHEMA Sales;
CREATE SCHEMA HR;
GO

-- Verify schemas created
SELECT name AS SchemaName 
FROM sys.schemas 
WHERE name IN ('Inventory', 'Sales', 'HR');
GO
