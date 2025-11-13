-- =============================================
-- Phase 3: Create Satellite Tables
-- =============================================
-- Purpose: Satellites store descriptive attributes that change over time
-- Pattern: Satellite = Hash Key (FK) + Attributes + Load Date + End Date
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('satellite', '01-create-satellites.sql', 'running');
GO

PRINT 'Creating Satellite tables...';
PRINT '';

-- =============================================
-- SAT_CUSTOMER_DEMOGRAPHICS (Customer profile info)
-- =============================================
PRINT 'Creating dv_sat.sat_customer_demographics...';

IF OBJECT_ID('dv_sat.sat_customer_demographics', 'U') IS NOT NULL 
    DROP TABLE dv_sat.sat_customer_demographics;

CREATE TABLE dv_sat.sat_customer_demographics (
    customer_hash_key CHAR(32) NOT NULL,               -- FK to hub_customer
    load_date DATETIME NOT NULL,                       -- When this version loaded
    load_end_date DATETIME NULL,                       -- When this version expired (NULL = current)
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    email NVARCHAR(100),
    phone NVARCHAR(20),
    address NVARCHAR(200),
    city NVARCHAR(50),
    state NVARCHAR(2),
    zip_code NVARCHAR(10),
    date_of_birth DATE,
    ssn_last4 NVARCHAR(4),
    record_source NVARCHAR(100) NOT NULL,
    hash_diff CHAR(32) NOT NULL,                       -- Hash of all attributes (detect changes)
    PRIMARY KEY (customer_hash_key, load_date),
    CONSTRAINT fk_sat_cust_demo FOREIGN KEY (customer_hash_key) 
        REFERENCES dv_hub.hub_customer(customer_hash_key)
);

CREATE INDEX idx_sat_cust_demo_end_date ON dv_sat.sat_customer_demographics(load_end_date);
CREATE INDEX idx_sat_cust_demo_hash_diff ON dv_sat.sat_customer_demographics(hash_diff);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_sat.sat_customer_demographics', 'raw.customers', 'sat_load');

PRINT '✓ sat_customer_demographics created';
PRINT '';

-- =============================================
-- SAT_CUSTOMER_STATUS (Customer status & credit info)
-- =============================================
PRINT 'Creating dv_sat.sat_customer_status...';

IF OBJECT_ID('dv_sat.sat_customer_status', 'U') IS NOT NULL 
    DROP TABLE dv_sat.sat_customer_status;

CREATE TABLE dv_sat.sat_customer_status (
    customer_hash_key CHAR(32) NOT NULL,
    load_date DATETIME NOT NULL,
    load_end_date DATETIME NULL,
    customer_since DATE,
    customer_status NVARCHAR(20),                      -- Active, Inactive, Suspended
    credit_score INT,
    record_source NVARCHAR(100) NOT NULL,
    hash_diff CHAR(32) NOT NULL,
    PRIMARY KEY (customer_hash_key, load_date),
    CONSTRAINT fk_sat_cust_status FOREIGN KEY (customer_hash_key) 
        REFERENCES dv_hub.hub_customer(customer_hash_key)
);

CREATE INDEX idx_sat_cust_status_end_date ON dv_sat.sat_customer_status(load_end_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_sat.sat_customer_status', 'raw.customers', 'sat_load');

PRINT '✓ sat_customer_status created';
PRINT '';

-- =============================================
-- SAT_ACCOUNT_DETAILS (Account attributes)
-- =============================================
PRINT 'Creating dv_sat.sat_account_details...';

IF OBJECT_ID('dv_sat.sat_account_details', 'U') IS NOT NULL 
    DROP TABLE dv_sat.sat_account_details;

CREATE TABLE dv_sat.sat_account_details (
    account_hash_key CHAR(32) NOT NULL,
    load_date DATETIME NOT NULL,
    load_end_date DATETIME NULL,
    account_type NVARCHAR(50),
    balance DECIMAL(18,2),
    interest_rate DECIMAL(5,2),
    open_date DATE,
    account_status NVARCHAR(20),                       -- Active, Closed, Frozen
    record_source NVARCHAR(100) NOT NULL,
    hash_diff CHAR(32) NOT NULL,
    PRIMARY KEY (account_hash_key, load_date),
    CONSTRAINT fk_sat_acct_details FOREIGN KEY (account_hash_key) 
        REFERENCES dv_hub.hub_account(account_hash_key)
);

CREATE INDEX idx_sat_acct_details_end_date ON dv_sat.sat_account_details(load_end_date);
CREATE INDEX idx_sat_acct_details_status ON dv_sat.sat_account_details(account_status);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_sat.sat_account_details', 'raw.accounts', 'sat_load');

PRINT '✓ sat_account_details created';
PRINT '';

-- =============================================
-- SAT_TRANSACTION_DETAILS (Transaction attributes)
-- =============================================
PRINT 'Creating dv_sat.sat_transaction_details...';

IF OBJECT_ID('dv_sat.sat_transaction_details', 'U') IS NOT NULL 
    DROP TABLE dv_sat.sat_transaction_details;

CREATE TABLE dv_sat.sat_transaction_details (
    transaction_hash_key CHAR(32) NOT NULL,
    load_date DATETIME NOT NULL,
    load_end_date DATETIME NULL,
    transaction_date DATETIME,
    transaction_type NVARCHAR(50),
    amount DECIMAL(18,2),
    description NVARCHAR(200),
    merchant_name NVARCHAR(100),
    category NVARCHAR(50),
    record_source NVARCHAR(100) NOT NULL,
    hash_diff CHAR(32) NOT NULL,
    PRIMARY KEY (transaction_hash_key, load_date),
    CONSTRAINT fk_sat_txn_details FOREIGN KEY (transaction_hash_key) 
        REFERENCES dv_hub.hub_transaction(transaction_hash_key)
);

CREATE INDEX idx_sat_txn_details_end_date ON dv_sat.sat_transaction_details(load_end_date);
CREATE INDEX idx_sat_txn_details_date ON dv_sat.sat_transaction_details(transaction_date);
CREATE INDEX idx_sat_txn_details_type ON dv_sat.sat_transaction_details(transaction_type);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_sat.sat_transaction_details', 'raw.transactions', 'sat_load');

PRINT '✓ sat_transaction_details created';
PRINT '';

-- =============================================
-- SAT_BRANCH_INFO (Branch information)
-- =============================================
PRINT 'Creating dv_sat.sat_branch_info...';

IF OBJECT_ID('dv_sat.sat_branch_info', 'U') IS NOT NULL 
    DROP TABLE dv_sat.sat_branch_info;

CREATE TABLE dv_sat.sat_branch_info (
    branch_hash_key CHAR(32) NOT NULL,
    load_date DATETIME NOT NULL,
    load_end_date DATETIME NULL,
    branch_name NVARCHAR(100),
    city NVARCHAR(50),
    state NVARCHAR(2),
    region NVARCHAR(50),
    record_source NVARCHAR(100) NOT NULL,
    hash_diff CHAR(32) NOT NULL,
    PRIMARY KEY (branch_hash_key, load_date),
    CONSTRAINT fk_sat_branch_info FOREIGN KEY (branch_hash_key) 
        REFERENCES dv_hub.hub_branch(branch_hash_key)
);

CREATE INDEX idx_sat_branch_info_end_date ON dv_sat.sat_branch_info(load_end_date);

INSERT INTO metadata.data_lineage (target_table, source_table, transformation_type)
VALUES ('dv_sat.sat_branch_info', 'raw.branches', 'sat_load');

PRINT '✓ sat_branch_info created';
PRINT '';

-- =============================================
-- Update Pipeline Status
-- =============================================
UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = 0
WHERE layer = 'satellite' 
  AND script_name = '01-create-satellites.sql'
  AND status = 'running';
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Satellite Tables Created Successfully!';
PRINT '========================================';
PRINT '';

SELECT 
    TABLE_SCHEMA + '.' + TABLE_NAME AS satellite_table,
    (SELECT COUNT(*) 
     FROM sys.columns 
     WHERE object_id = OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME)) AS column_count
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dv_sat'
ORDER BY TABLE_NAME;

PRINT '';
PRINT 'Satellite Characteristics:';
PRINT '- Stores descriptive attributes that change over time';
PRINT '- Composite PK = (hash_key, load_date)';
PRINT '- load_end_date = NULL means current version';
PRINT '- hash_diff = Hash of all attributes (detect changes)';
PRINT '- Enables point-in-time queries';
PRINT '';
PRINT 'Next: Load satellite tables (02-load-satellites.sql)';
GO
