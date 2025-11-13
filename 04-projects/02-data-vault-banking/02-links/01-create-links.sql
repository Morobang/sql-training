-- =============================================
-- Phase 2: Create Link Tables
-- =============================================
-- Purpose: Links connect hubs to track relationships
-- Pattern: Link = Composite Hash Key + Foreign Hash Keys + Metadata
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('link', '01-create-links.sql', 'running');
GO

PRINT 'Creating Link tables...';
PRINT '';

-- =============================================
-- LINK_CUSTOMER_ACCOUNT (Customer owns Account)
-- =============================================
PRINT 'Creating dv_link.link_customer_account...';

IF OBJECT_ID('dv_link.link_customer_account', 'U') IS NOT NULL 
    DROP TABLE dv_link.link_customer_account;

CREATE TABLE dv_link.link_customer_account (
    link_customer_account_hash_key CHAR(32) PRIMARY KEY,  -- Composite hash
    customer_hash_key CHAR(32) NOT NULL,                  -- FK to hub_customer
    account_hash_key CHAR(32) NOT NULL,                   -- FK to hub_account
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,
    CONSTRAINT fk_link_ca_customer FOREIGN KEY (customer_hash_key) 
        REFERENCES dv_hub.hub_customer(customer_hash_key),
    CONSTRAINT fk_link_ca_account FOREIGN KEY (account_hash_key) 
        REFERENCES dv_hub.hub_account(account_hash_key)
);

CREATE INDEX idx_link_ca_customer ON dv_link.link_customer_account(customer_hash_key);
CREATE INDEX idx_link_ca_account ON dv_link.link_customer_account(account_hash_key);
CREATE INDEX idx_link_ca_load_date ON dv_link.link_customer_account(load_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_link.link_customer_account', 'raw.accounts', 'link_load');

PRINT '✓ link_customer_account created';
PRINT '';

-- =============================================
-- LINK_ACCOUNT_TRANSACTION (Transaction belongs to Account)
-- =============================================
PRINT 'Creating dv_link.link_account_transaction...';

IF OBJECT_ID('dv_link.link_account_transaction', 'U') IS NOT NULL 
    DROP TABLE dv_link.link_account_transaction;

CREATE TABLE dv_link.link_account_transaction (
    link_account_transaction_hash_key CHAR(32) PRIMARY KEY,
    account_hash_key CHAR(32) NOT NULL,
    transaction_hash_key CHAR(32) NOT NULL,
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,
    CONSTRAINT fk_link_at_account FOREIGN KEY (account_hash_key) 
        REFERENCES dv_hub.hub_account(account_hash_key),
    CONSTRAINT fk_link_at_transaction FOREIGN KEY (transaction_hash_key) 
        REFERENCES dv_hub.hub_transaction(transaction_hash_key)
);

CREATE INDEX idx_link_at_account ON dv_link.link_account_transaction(account_hash_key);
CREATE INDEX idx_link_at_transaction ON dv_link.link_account_transaction(transaction_hash_key);
CREATE INDEX idx_link_at_load_date ON dv_link.link_account_transaction(load_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_link.link_account_transaction', 'raw.transactions', 'link_load');

PRINT '✓ link_account_transaction created';
PRINT '';

-- =============================================
-- LINK_ACCOUNT_BRANCH (Account opened at Branch)
-- =============================================
PRINT 'Creating dv_link.link_account_branch...';

IF OBJECT_ID('dv_link.link_account_branch', 'U') IS NOT NULL 
    DROP TABLE dv_link.link_account_branch;

CREATE TABLE dv_link.link_account_branch (
    link_account_branch_hash_key CHAR(32) PRIMARY KEY,
    account_hash_key CHAR(32) NOT NULL,
    branch_hash_key CHAR(32) NOT NULL,
    load_date DATETIME NOT NULL DEFAULT GETDATE(),
    record_source NVARCHAR(100) NOT NULL,
    CONSTRAINT fk_link_ab_account FOREIGN KEY (account_hash_key) 
        REFERENCES dv_hub.hub_account(account_hash_key),
    CONSTRAINT fk_link_ab_branch FOREIGN KEY (branch_hash_key) 
        REFERENCES dv_hub.hub_branch(branch_hash_key)
);

CREATE INDEX idx_link_ab_account ON dv_link.link_account_branch(account_hash_key);
CREATE INDEX idx_link_ab_branch ON dv_link.link_account_branch(branch_hash_key);
CREATE INDEX idx_link_ab_load_date ON dv_link.link_account_branch(load_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_link.link_account_branch', 'raw.accounts', 'link_load');

PRINT '✓ link_account_branch created';
PRINT '';

-- =============================================
-- Update Pipeline Status
-- =============================================
UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = 0
WHERE layer = 'link' 
  AND script_name = '01-create-links.sql'
  AND status = 'running';
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Link Tables Created Successfully!';
PRINT '========================================';
PRINT '';

SELECT 
    TABLE_SCHEMA + '.' + TABLE_NAME AS link_table,
    (SELECT COUNT(*) 
     FROM sys.columns 
     WHERE object_id = OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME)) AS column_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dv_link'
ORDER BY TABLE_NAME;

PRINT '';
PRINT 'Link Characteristics:';
PRINT '- Connects hubs together (relationships)';
PRINT '- Composite hash key = MD5(hub1_key || hub2_key)';
PRINT '- Foreign keys to hub tables';
PRINT '- Tracks when relationship was established';
PRINT '';
PRINT 'Next: Load link tables (02-load-links.sql)';
GO
