-- ========================================
-- Project Setup: Create Database & Schemas
-- ========================================
-- Purpose: Set up dedicated database with schema-based layer separation
-- Best Practice: Use schemas to organize Bronze, Silver, and Gold layers
-- ========================================

-- ========================================
-- Step 1: Create Dedicated Database
-- ========================================

IF DB_ID('TechStore_Warehouse') IS NOT NULL
BEGIN
    PRINT 'Dropping existing TechStore_Warehouse database...';
    ALTER DATABASE TechStore_Warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TechStore_Warehouse;
END;
GO

PRINT 'Creating TechStore_Warehouse database...';
CREATE DATABASE TechStore_Warehouse;
GO

USE TechStore_Warehouse;
GO

PRINT 'Database created successfully!';
PRINT '';

-- ========================================
-- Step 2: Create Layer Schemas
-- ========================================

PRINT 'Creating layer schemas...';

-- Bronze Schema: Raw data landing zone
IF SCHEMA_ID('bronze') IS NULL
    EXEC('CREATE SCHEMA bronze AUTHORIZATION dbo');
GO

-- Silver Schema: Cleaned and validated data
IF SCHEMA_ID('silver') IS NULL
    EXEC('CREATE SCHEMA silver AUTHORIZATION dbo');
GO

-- Gold Schema: Business-ready analytics
IF SCHEMA_ID('gold') IS NULL
    EXEC('CREATE SCHEMA gold AUTHORIZATION dbo');
GO

-- Metadata Schema: Data lineage and quality tracking
IF SCHEMA_ID('metadata') IS NULL
    EXEC('CREATE SCHEMA metadata AUTHORIZATION dbo');
GO

PRINT 'Schemas created:';
PRINT '  ✓ bronze  - Raw data landing zone';
PRINT '  ✓ silver  - Cleaned and validated data';
PRINT '  ✓ gold    - Business-ready analytics';
PRINT '  ✓ metadata - Data lineage and quality tracking';
PRINT '';

-- ========================================
-- Step 3: Create Metadata Tables
-- ========================================

PRINT 'Creating metadata tracking tables...';

-- Track ETL execution
CREATE TABLE metadata.pipeline_runs (
    run_id INT IDENTITY(1,1) PRIMARY KEY,
    layer VARCHAR(20) NOT NULL,  -- bronze, silver, gold
    script_name VARCHAR(200),
    start_time DATETIME DEFAULT GETDATE(),
    end_time DATETIME,
    status VARCHAR(20),  -- running, success, failed
    rows_processed INT,
    error_message NVARCHAR(MAX)
);
GO

-- Track data quality issues
CREATE TABLE metadata.data_quality_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    layer VARCHAR(20),
    table_name VARCHAR(100),
    check_name VARCHAR(200),
    check_timestamp DATETIME DEFAULT GETDATE(),
    records_checked INT,
    records_failed INT,
    failure_rate DECIMAL(5,2),
    details NVARCHAR(MAX)
);
GO

-- Track data lineage
CREATE TABLE metadata.data_lineage (
    lineage_id INT IDENTITY(1,1) PRIMARY KEY,
    source_layer VARCHAR(20),
    source_table VARCHAR(100),
    target_layer VARCHAR(20),
    target_table VARCHAR(100),
    transformation_logic NVARCHAR(MAX),
    created_date DATETIME DEFAULT GETDATE()
);
GO

PRINT 'Metadata tables created!';
PRINT '';

-- ========================================
-- Step 4: Verification
-- ========================================

PRINT '========================================';
PRINT 'SETUP COMPLETE!';
PRINT '========================================';
PRINT '';
PRINT 'Database: TechStore_Warehouse';
PRINT '';
PRINT 'Schemas:';
SELECT 
    name AS schema_name,
    schema_id
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold', 'metadata')
ORDER BY name;
GO

PRINT '';
PRINT 'Metadata Tables:';
SELECT 
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'metadata'
ORDER BY t.name;
GO

PRINT '';
PRINT '========================================';
PRINT 'Next Steps:';
PRINT '1. Run 01-bronze/01-create-bronze-tables.sql';
PRINT '2. Run 01-bronze/02-generate-sample-data.sql';
PRINT '========================================';
GO
