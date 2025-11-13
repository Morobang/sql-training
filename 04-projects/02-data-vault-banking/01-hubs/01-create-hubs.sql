-- =============================================
-- Phase 1: Create Hub Tables
-- =============================================
-- Purpose: Hubs store only business keys (immutable)
-- Pattern: Hub = Hash Key + Business Key + Metadata
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('hub', '01-create-hubs.sql', 'running');
GO

PRINT 'Creating Hub tables...';
PRINT '';

-- =============================================
-- HUB_CUSTOMER (Unique Customers)
-- =============================================
PRINT 'Creating dv_hub.hub_customer...';

IF OBJECT_ID('dv_hub.hub_customer', 'U') IS NOT NULL 
    DROP TABLE dv_hub.hub_customer;

CREATE TABLE dv_hub.hub_customer (
    customer_hash_key CHAR(32) PRIMARY KEY,     -- MD5 hash of customer_id
    customer_id NVARCHAR(50) NOT NULL UNIQUE,   -- Business key
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,       -- Source system name
    CONSTRAINT chk_customer_hash CHECK (LEN(customer_hash_key) = 32)
);

CREATE INDEX idx_customer_id ON dv_hub.hub_customer(customer_id);
CREATE INDEX idx_load_date ON dv_hub.hub_customer(load_date);

-- Log lineage
INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_hub.hub_customer', 'raw.customers', 'hub_load');

PRINT '✓ hub_customer created';
PRINT '';

-- =============================================
-- HUB_ACCOUNT (Unique Bank Accounts)
-- =============================================
PRINT 'Creating dv_hub.hub_account...';

IF OBJECT_ID('dv_hub.hub_account', 'U') IS NOT NULL 
    DROP TABLE dv_hub.hub_account;

CREATE TABLE dv_hub.hub_account (
    account_hash_key CHAR(32) PRIMARY KEY,
    account_number NVARCHAR(50) NOT NULL UNIQUE,    -- Business key
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,
    CONSTRAINT chk_account_hash CHECK (LEN(account_hash_key) = 32)
);

CREATE INDEX idx_account_number ON dv_hub.hub_account(account_number);
CREATE INDEX idx_account_load_date ON dv_hub.hub_account(load_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_hub.hub_account', 'raw.accounts', 'hub_load');

PRINT '✓ hub_account created';
PRINT '';

-- =============================================
-- HUB_TRANSACTION (Unique Transactions)
-- =============================================
PRINT 'Creating dv_hub.hub_transaction...';

IF OBJECT_ID('dv_hub.hub_transaction', 'U') IS NOT NULL 
    DROP TABLE dv_hub.hub_transaction;

CREATE TABLE dv_hub.hub_transaction (
    transaction_hash_key CHAR(32) PRIMARY KEY,
    transaction_id NVARCHAR(50) NOT NULL UNIQUE,   -- Business key
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,
    CONSTRAINT chk_transaction_hash CHECK (LEN(transaction_hash_key) = 32)
);

CREATE INDEX idx_transaction_id ON dv_hub.hub_transaction(transaction_id);
CREATE INDEX idx_transaction_load_date ON dv_hub.hub_transaction(load_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_hub.hub_transaction', 'raw.transactions', 'hub_load');

PRINT '✓ hub_transaction created';
PRINT '';

-- =============================================
-- HUB_BRANCH (Unique Bank Branches)
-- =============================================
PRINT 'Creating dv_hub.hub_branch...';

IF OBJECT_ID('dv_hub.hub_branch', 'U') IS NOT NULL 
    DROP TABLE dv_hub.hub_branch;

CREATE TABLE dv_hub.hub_branch (
    branch_hash_key CHAR(32) PRIMARY KEY,
    branch_code NVARCHAR(20) NOT NULL UNIQUE,      -- Business key
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,
    CONSTRAINT chk_branch_hash CHECK (LEN(branch_hash_key) = 32)
);

CREATE INDEX idx_branch_code ON dv_hub.hub_branch(branch_code);
CREATE INDEX idx_branch_load_date ON dv_hub.hub_branch(load_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_hub.hub_branch', 'raw.branches', 'hub_load');

PRINT '✓ hub_branch created';
PRINT '';

-- =============================================
-- Update Pipeline Status
-- =============================================
UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = 0
WHERE layer = 'hub' 
  AND script_name = '01-create-hubs.sql'
  AND status = 'running';
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Hub Tables Created Successfully!';
PRINT '========================================';
PRINT '';

SELECT 
    TABLE_SCHEMA + '.' + TABLE_NAME AS hub_table,
    (SELECT COUNT(*) 
     FROM sys.columns 
     WHERE object_id = OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME)) AS column_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dv_hub'
ORDER BY TABLE_NAME;

PRINT '';
PRINT 'Hub Characteristics:';
PRINT '- Stores only business keys (no descriptive data)';
PRINT '- Immutable (never UPDATE or DELETE)';
PRINT '- Hash key = MD5(business_key)';
PRINT '- One record per unique business entity';
PRINT '';
PRINT 'Next: Load data into hubs (02-load-sample-data.sql)';
GO
