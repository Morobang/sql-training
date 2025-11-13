-- =============================================
-- Phase 1: Load Hubs from Raw Data
-- =============================================
-- Purpose: Load business keys into hub tables
-- Pattern: Extract unique business keys + generate hash keys
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('hub', '03-load-hubs.sql', 'running');
GO

PRINT 'Loading Hub tables from raw data...';
PRINT '';

-- =============================================
-- LOAD HUB_CUSTOMER
-- =============================================
PRINT 'Loading dv_hub.hub_customer...';

INSERT INTO dv_hub.hub_customer (customer_hash_key, customer_id, load_date, record_source)
SELECT DISTINCT
    dbo.fn_GetHashKey(customer_id) AS customer_hash_key,
    customer_id,
    GETDATE() AS load_date,
    'raw.customers' AS record_source
FROM raw.customers
WHERE customer_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dv_hub.hub_customer h 
      WHERE h.customer_hash_key = dbo.fn_GetHashKey(raw.customers.customer_id)
  );

DECLARE @customer_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@customer_count AS VARCHAR) + ' customers into hub_customer';

-- Register hash keys
INSERT INTO metadata.hash_key_registry (hash_key, entity_type, business_key)
SELECT DISTINCT
    dbo.fn_GetHashKey(customer_id),
    'customer',
    customer_id
FROM raw.customers
WHERE NOT EXISTS (
    SELECT 1 FROM metadata.hash_key_registry r
    WHERE r.hash_key = dbo.fn_GetHashKey(raw.customers.customer_id)
);

PRINT '';

-- =============================================
-- LOAD HUB_ACCOUNT
-- =============================================
PRINT 'Loading dv_hub.hub_account...';

INSERT INTO dv_hub.hub_account (account_hash_key, account_number, load_date, record_source)
SELECT DISTINCT
    dbo.fn_GetHashKey(account_number) AS account_hash_key,
    account_number,
    GETDATE() AS load_date,
    'raw.accounts' AS record_source
FROM raw.accounts
WHERE account_number IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dv_hub.hub_account h 
      WHERE h.account_hash_key = dbo.fn_GetHashKey(raw.accounts.account_number)
  );

DECLARE @account_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@account_count AS VARCHAR) + ' accounts into hub_account';

INSERT INTO metadata.hash_key_registry (hash_key, entity_type, business_key)
SELECT DISTINCT
    dbo.fn_GetHashKey(account_number),
    'account',
    account_number
FROM raw.accounts
WHERE NOT EXISTS (
    SELECT 1 FROM metadata.hash_key_registry r
    WHERE r.hash_key = dbo.fn_GetHashKey(raw.accounts.account_number)
);

PRINT '';

-- =============================================
-- LOAD HUB_TRANSACTION
-- =============================================
PRINT 'Loading dv_hub.hub_transaction...';

INSERT INTO dv_hub.hub_transaction (transaction_hash_key, transaction_id, load_date, record_source)
SELECT DISTINCT
    dbo.fn_GetHashKey(transaction_id) AS transaction_hash_key,
    transaction_id,
    GETDATE() AS load_date,
    'raw.transactions' AS record_source
FROM raw.transactions
WHERE transaction_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dv_hub.hub_transaction h 
      WHERE h.transaction_hash_key = dbo.fn_GetHashKey(raw.transactions.transaction_id)
  );

DECLARE @transaction_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@transaction_count AS VARCHAR) + ' transactions into hub_transaction';

INSERT INTO metadata.hash_key_registry (hash_key, entity_type, business_key)
SELECT DISTINCT
    dbo.fn_GetHashKey(transaction_id),
    'transaction',
    transaction_id
FROM raw.transactions
WHERE NOT EXISTS (
    SELECT 1 FROM metadata.hash_key_registry r
    WHERE r.hash_key = dbo.fn_GetHashKey(raw.transactions.transaction_id)
);

PRINT '';

-- =============================================
-- LOAD HUB_BRANCH
-- =============================================
PRINT 'Loading dv_hub.hub_branch...';

INSERT INTO dv_hub.hub_branch (branch_hash_key, branch_code, load_date, record_source)
SELECT DISTINCT
    dbo.fn_GetHashKey(branch_code) AS branch_hash_key,
    branch_code,
    GETDATE() AS load_date,
    'raw.branches' AS record_source
FROM raw.branches
WHERE branch_code IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dv_hub.hub_branch h 
      WHERE h.branch_hash_key = dbo.fn_GetHashKey(raw.branches.branch_code)
  );

DECLARE @branch_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@branch_count AS VARCHAR) + ' branches into hub_branch';

INSERT INTO metadata.hash_key_registry (hash_key, entity_type, business_key)
SELECT DISTINCT
    dbo.fn_GetHashKey(branch_code),
    'branch',
    branch_code
FROM raw.branches
WHERE NOT EXISTS (
    SELECT 1 FROM metadata.hash_key_registry r
    WHERE r.hash_key = dbo.fn_GetHashKey(raw.branches.branch_code)
);

PRINT '';

-- =============================================
-- Update Pipeline Status
-- =============================================
DECLARE @total_hub_rows INT = @customer_count + @account_count + @transaction_count + @branch_count;

UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = @total_hub_rows
WHERE layer = 'hub' 
  AND script_name = '03-load-hubs.sql'
  AND status = 'running';
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Hub Loading Complete!';
PRINT '========================================';
PRINT '';

SELECT 
    'dv_hub.hub_customer' AS hub_table,
    COUNT(*) AS record_count,
    MIN(load_date) AS first_load,
    MAX(load_date) AS last_load
FROM dv_hub.hub_customer
UNION ALL
SELECT 'dv_hub.hub_account', COUNT(*), MIN(load_date), MAX(load_date)
FROM dv_hub.hub_account
UNION ALL
SELECT 'dv_hub.hub_transaction', COUNT(*), MIN(load_date), MAX(load_date)
FROM dv_hub.hub_transaction
UNION ALL
SELECT 'dv_hub.hub_branch', COUNT(*), MIN(load_date), MAX(load_date)
FROM dv_hub.hub_branch;

PRINT '';
PRINT 'Sample Hub Records:';
PRINT '';
SELECT TOP 5 
    customer_hash_key, 
    customer_id, 
    load_date,
    record_source
FROM dv_hub.hub_customer;

PRINT '';
PRINT 'Hub Characteristics:';
PRINT '✓ Only business keys loaded (no descriptive data)';
PRINT '✓ Hash keys generated using MD5(business_key)';
PRINT '✓ Records are immutable (no updates/deletes)';
PRINT '✓ Duplicate prevention via hash key lookup';
PRINT '';
PRINT 'Next: Create and load link tables (Phase 2)';
GO
