-- =============================================
-- Phase 2: Load Link Tables
-- =============================================
-- Purpose: Load relationships between hubs
-- Pattern: Generate composite hash from related business keys
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('link', '02-load-links.sql', 'running');
GO

PRINT 'Loading Link tables from raw data...';
PRINT '';

-- =============================================
-- LOAD LINK_CUSTOMER_ACCOUNT
-- =============================================
PRINT 'Loading dv_link.link_customer_account...';

INSERT INTO dv_link.link_customer_account (
    link_customer_account_hash_key,
    customer_hash_key,
    account_hash_key,
    load_date,
    record_source
)
SELECT DISTINCT
    dbo.fn_GetCompositeHashKey(a.customer_id, a.account_number) AS link_hash_key,
    dbo.fn_GetHashKey(a.customer_id) AS customer_hash_key,
    dbo.fn_GetHashKey(a.account_number) AS account_hash_key,
    GETDATE() AS load_date,
    'raw.accounts' AS record_source
FROM raw.accounts a
WHERE a.customer_id IS NOT NULL 
  AND a.account_number IS NOT NULL
  AND EXISTS (SELECT 1 FROM dv_hub.hub_customer c WHERE c.customer_hash_key = dbo.fn_GetHashKey(a.customer_id))
  AND EXISTS (SELECT 1 FROM dv_hub.hub_account ac WHERE ac.account_hash_key = dbo.fn_GetHashKey(a.account_number))
  AND NOT EXISTS (
      SELECT 1 FROM dv_link.link_customer_account l
      WHERE l.link_customer_account_hash_key = dbo.fn_GetCompositeHashKey(a.customer_id, a.account_number)
  );

DECLARE @link_ca_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@link_ca_count AS VARCHAR) + ' customer-account relationships';
PRINT '';

-- =============================================
-- LOAD LINK_ACCOUNT_TRANSACTION
-- =============================================
PRINT 'Loading dv_link.link_account_transaction...';

INSERT INTO dv_link.link_account_transaction (
    link_account_transaction_hash_key,
    account_hash_key,
    transaction_hash_key,
    load_date,
    record_source
)
SELECT DISTINCT
    dbo.fn_GetCompositeHashKey(t.account_number, t.transaction_id) AS link_hash_key,
    dbo.fn_GetHashKey(t.account_number) AS account_hash_key,
    dbo.fn_GetHashKey(t.transaction_id) AS transaction_hash_key,
    GETDATE() AS load_date,
    'raw.transactions' AS record_source
FROM raw.transactions t
WHERE t.account_number IS NOT NULL 
  AND t.transaction_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM dv_hub.hub_account a WHERE a.account_hash_key = dbo.fn_GetHashKey(t.account_number))
  AND EXISTS (SELECT 1 FROM dv_hub.hub_transaction tx WHERE tx.transaction_hash_key = dbo.fn_GetHashKey(t.transaction_id))
  AND NOT EXISTS (
      SELECT 1 FROM dv_link.link_account_transaction l
      WHERE l.link_account_transaction_hash_key = dbo.fn_GetCompositeHashKey(t.account_number, t.transaction_id)
  );

DECLARE @link_at_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@link_at_count AS VARCHAR) + ' account-transaction relationships';
PRINT '';

-- =============================================
-- LOAD LINK_ACCOUNT_BRANCH
-- =============================================
PRINT 'Loading dv_link.link_account_branch...';

INSERT INTO dv_link.link_account_branch (
    link_account_branch_hash_key,
    account_hash_key,
    branch_hash_key,
    load_date,
    record_source
)
SELECT DISTINCT
    dbo.fn_GetCompositeHashKey(a.account_number, a.branch_code) AS link_hash_key,
    dbo.fn_GetHashKey(a.account_number) AS account_hash_key,
    dbo.fn_GetHashKey(a.branch_code) AS branch_hash_key,
    GETDATE() AS load_date,
    'raw.accounts' AS record_source
FROM raw.accounts a
WHERE a.account_number IS NOT NULL 
  AND a.branch_code IS NOT NULL
  AND EXISTS (SELECT 1 FROM dv_hub.hub_account ac WHERE ac.account_hash_key = dbo.fn_GetHashKey(a.account_number))
  AND EXISTS (SELECT 1 FROM dv_hub.hub_branch b WHERE b.branch_hash_key = dbo.fn_GetHashKey(a.branch_code))
  AND NOT EXISTS (
      SELECT 1 FROM dv_link.link_account_branch l
      WHERE l.link_account_branch_hash_key = dbo.fn_GetCompositeHashKey(a.account_number, a.branch_code)
  );

DECLARE @link_ab_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@link_ab_count AS VARCHAR) + ' account-branch relationships';
PRINT '';

-- =============================================
-- Update Pipeline Status
-- =============================================
DECLARE @total_link_rows INT = @link_ca_count + @link_at_count + @link_ab_count;

UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = @total_link_rows
WHERE layer = 'link' 
  AND script_name = '02-load-links.sql'
  AND status = 'running';
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Link Loading Complete!';
PRINT '========================================';
PRINT '';

SELECT 
    'dv_link.link_customer_account' AS link_table,
    COUNT(*) AS relationship_count
FROM dv_link.link_customer_account
UNION ALL
SELECT 'dv_link.link_account_transaction', COUNT(*)
FROM dv_link.link_account_transaction
UNION ALL
SELECT 'dv_link.link_account_branch', COUNT(*)
FROM dv_link.link_account_branch;

PRINT '';
PRINT 'Sample Link Records:';
PRINT '';
SELECT TOP 5 
    link_customer_account_hash_key,
    customer_hash_key,
    account_hash_key,
    load_date
FROM dv_link.link_customer_account;

PRINT '';
PRINT 'Link Validation:';
PRINT '✓ All links reference valid hubs (foreign keys enforced)';
PRINT '✓ Composite hash keys prevent duplicates';
PRINT '✓ Relationships tracked with load timestamps';
PRINT '';
PRINT 'Next: Create and load satellite tables (Phase 3)';
GO
