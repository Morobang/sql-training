-- =============================================
-- Data Vault 2.0 - Database Setup
-- =============================================
-- Project: SecureBank Compliance Data Warehouse
-- Purpose: Create database with schema-based Data Vault organization
-- Architecture: Hubs → Links → Satellites → Business Vault
-- =============================================

-- =============================================
-- 1. CREATE DATABASE
-- =============================================
IF DB_ID('SecureBank_DataVault') IS NOT NULL
BEGIN
    PRINT 'Dropping existing SecureBank_DataVault database...';
    USE master;
    ALTER DATABASE SecureBank_DataVault SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SecureBank_DataVault;
END;
GO

PRINT 'Creating SecureBank_DataVault database...';
CREATE DATABASE SecureBank_DataVault;
GO

USE SecureBank_DataVault;
GO

-- =============================================
-- 2. CREATE SCHEMAS (Data Vault Organization)
-- =============================================
PRINT 'Creating Data Vault schemas...';

-- Raw staging area (landing zone for source data)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'raw')
    EXEC('CREATE SCHEMA raw');

-- Hub schema (business keys only)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dv_hub')
    EXEC('CREATE SCHEMA dv_hub');

-- Link schema (relationships between hubs)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dv_link')
    EXEC('CREATE SCHEMA dv_link');

-- Satellite schema (descriptive attributes that change over time)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dv_sat')
    EXEC('CREATE SCHEMA dv_sat');

-- Business Vault schema (query-friendly views for reporting)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'business_vault')
    EXEC('CREATE SCHEMA business_vault');

-- Metadata schema (pipeline tracking and audit)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'metadata')
    EXEC('CREATE SCHEMA metadata');

PRINT '✓ Schemas created: raw, dv_hub, dv_link, dv_sat, business_vault, metadata';
GO

-- =============================================
-- 3. CREATE METADATA TABLES
-- =============================================
PRINT 'Creating metadata tracking tables...';

-- Pipeline execution tracking
CREATE TABLE metadata.pipeline_runs (
    run_id INT IDENTITY(1,1) PRIMARY KEY,
    layer NVARCHAR(50) NOT NULL,           -- 'raw', 'hub', 'link', 'sat', 'business_vault'
    script_name NVARCHAR(200) NOT NULL,
    start_time DATETIME DEFAULT GETDATE(),
    end_time DATETIME NULL,
    status NVARCHAR(20) DEFAULT 'running',  -- 'running', 'success', 'failed'
    rows_processed INT NULL,
    error_message NVARCHAR(MAX) NULL
);

-- Data quality tracking
CREATE TABLE metadata.data_quality_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name NVARCHAR(100) NOT NULL,
    check_name NVARCHAR(100) NOT NULL,
    check_date DATETIME DEFAULT GETDATE(),
    issue_count INT NOT NULL,
    severity NVARCHAR(20),                  -- 'critical', 'warning', 'info'
    description NVARCHAR(500)
);

-- Data lineage tracking (transformation history)
CREATE TABLE metadata.data_lineage (
    lineage_id INT IDENTITY(1,1) PRIMARY KEY,
    target_table NVARCHAR(100) NOT NULL,
    source_table NVARCHAR(100) NOT NULL,
    transformation_type NVARCHAR(50),       -- 'hub_load', 'link_load', 'sat_load'
    created_date DATETIME DEFAULT GETDATE(),
    created_by NVARCHAR(100) DEFAULT SYSTEM_USER
);

-- Hash key registry (track all hash keys for debugging)
CREATE TABLE metadata.hash_key_registry (
    registry_id INT IDENTITY(1,1) PRIMARY KEY,
    hash_key CHAR(32) NOT NULL,             -- MD5 hash (32 chars)
    entity_type NVARCHAR(50) NOT NULL,      -- 'customer', 'account', 'transaction', etc.
    business_key NVARCHAR(200) NOT NULL,    -- Original business key value
    created_date DATETIME DEFAULT GETDATE()
);

CREATE INDEX idx_hash_key ON metadata.hash_key_registry(hash_key);
CREATE INDEX idx_business_key ON metadata.hash_key_registry(entity_type, business_key);

PRINT '✓ Metadata tables created: pipeline_runs, data_quality_log, data_lineage, hash_key_registry';
GO

-- =============================================
-- 4. CREATE HELPER FUNCTIONS
-- =============================================
PRINT 'Creating Data Vault helper functions...';
GO

-- Hash key generator (MD5 hash for business keys)
CREATE OR ALTER FUNCTION dbo.fn_GetHashKey
(
    @BusinessKey NVARCHAR(MAX)
)
RETURNS CHAR(32)
AS
BEGIN
    RETURN CONVERT(CHAR(32), HASHBYTES('MD5', UPPER(LTRIM(RTRIM(@BusinessKey)))), 2);
END;
GO

-- Composite hash key generator (for links with multiple business keys)
CREATE OR ALTER FUNCTION dbo.fn_GetCompositeHashKey
(
    @Key1 NVARCHAR(MAX),
    @Key2 NVARCHAR(MAX)
)
RETURNS CHAR(32)
AS
BEGIN
    DECLARE @CompositeKey NVARCHAR(MAX) = UPPER(LTRIM(RTRIM(@Key1))) + '||' + UPPER(LTRIM(RTRIM(@Key2)));
    RETURN CONVERT(CHAR(32), HASHBYTES('MD5', @CompositeKey), 2);
END;
GO

PRINT '✓ Helper functions created: fn_GetHashKey, fn_GetCompositeHashKey';
GO

-- =============================================
-- 5. VERIFICATION
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'Database Setup Complete!';
PRINT '========================================';
PRINT '';
PRINT 'Schemas Created:';
SELECT 
    name AS schema_name,
    CASE name
        WHEN 'raw' THEN 'Staging area for source data'
        WHEN 'dv_hub' THEN 'Business keys only (immutable)'
        WHEN 'dv_link' THEN 'Relationships between entities'
        WHEN 'dv_sat' THEN 'Descriptive attributes (temporal)'
        WHEN 'business_vault' THEN 'Query-friendly reporting views'
        WHEN 'metadata' THEN 'Pipeline tracking and audit'
        ELSE 'System schema'
    END AS description
FROM sys.schemas
WHERE name IN ('raw', 'dv_hub', 'dv_link', 'dv_sat', 'business_vault', 'metadata')
ORDER BY 
    CASE name
        WHEN 'raw' THEN 1
        WHEN 'dv_hub' THEN 2
        WHEN 'dv_link' THEN 3
        WHEN 'dv_sat' THEN 4
        WHEN 'business_vault' THEN 5
        WHEN 'metadata' THEN 6
    END;

PRINT '';
PRINT 'Metadata Tables:';
SELECT TABLE_SCHEMA + '.' + TABLE_NAME AS metadata_table
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'metadata'
ORDER BY TABLE_NAME;

PRINT '';
PRINT 'Helper Functions:';
SELECT ROUTINE_NAME AS function_name
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION'
  AND ROUTINE_NAME LIKE 'fn_%Hash%'
ORDER BY ROUTINE_NAME;

PRINT '';
PRINT '========================================';
PRINT 'Next Steps:';
PRINT '1. Run Phase 1 scripts to create Hub tables';
PRINT '2. Load business keys into Hubs';
PRINT '3. Create Links to connect entities';
PRINT '4. Create Satellites for temporal attributes';
PRINT '========================================';
GO
