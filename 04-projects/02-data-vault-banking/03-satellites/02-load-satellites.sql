-- =============================================
-- Phase 3: Load Satellite Tables (SCD Type 2)
-- =============================================
-- Purpose: Load descriptive attributes with full history tracking
-- Pattern: Detect changes via hash_diff, end-date old records
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('satellite', '02-load-satellites.sql', 'running');
GO

-- =============================================
-- Helper: Hash Diff Function
-- =============================================
CREATE OR ALTER FUNCTION dbo.fn_GetHashDiff
(
    @Value1 NVARCHAR(MAX),
    @Value2 NVARCHAR(MAX) = '',
    @Value3 NVARCHAR(MAX) = '',
    @Value4 NVARCHAR(MAX) = '',
    @Value5 NVARCHAR(MAX) = ''
)
RETURNS CHAR(32)
AS
BEGIN
    DECLARE @CombinedValue NVARCHAR(MAX) = 
        ISNULL(@Value1, '') + '||' +
        ISNULL(@Value2, '') + '||' +
        ISNULL(@Value3, '') + '||' +
        ISNULL(@Value4, '') + '||' +
        ISNULL(@Value5, '');
    
    RETURN CONVERT(CHAR(32), HASHBYTES('MD5', @CombinedValue), 2);
END;
GO

PRINT 'Loading Satellite tables from raw data...';
PRINT '';

-- =============================================
-- LOAD SAT_CUSTOMER_DEMOGRAPHICS
-- =============================================
PRINT 'Loading dv_sat.sat_customer_demographics...';

INSERT INTO dv_sat.sat_customer_demographics (
    customer_hash_key, load_date, load_end_date,
    first_name, last_name, email, phone, address, city, state, zip_code, 
    date_of_birth, ssn_last4, record_source, hash_diff
)
SELECT 
    dbo.fn_GetHashKey(c.customer_id) AS customer_hash_key,
    GETDATE() AS load_date,
    NULL AS load_end_date,  -- NULL = current record
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.address,
    c.city,
    c.state,
    c.zip_code,
    c.date_of_birth,
    c.ssn_last4,
    'raw.customers' AS record_source,
    CONVERT(CHAR(32), HASHBYTES('MD5', 
        ISNULL(c.first_name, '') + ISNULL(c.last_name, '') + 
        ISNULL(c.email, '') + ISNULL(c.phone, '') + 
        ISNULL(c.address, '') + ISNULL(c.city, '') + 
        ISNULL(c.state, '') + ISNULL(c.zip_code, '')
    ), 2) AS hash_diff
FROM raw.customers c
WHERE EXISTS (
    SELECT 1 FROM dv_hub.hub_customer h 
    WHERE h.customer_hash_key = dbo.fn_GetHashKey(c.customer_id)
)
AND NOT EXISTS (
    SELECT 1 FROM dv_sat.sat_customer_demographics s
    WHERE s.customer_hash_key = dbo.fn_GetHashKey(c.customer_id)
      AND s.load_end_date IS NULL  -- Only check current records
);

DECLARE @cust_demo_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@cust_demo_count AS VARCHAR) + ' customer demographic records';
PRINT '';

-- =============================================
-- LOAD SAT_CUSTOMER_STATUS
-- =============================================
PRINT 'Loading dv_sat.sat_customer_status...';

INSERT INTO dv_sat.sat_customer_status (
    customer_hash_key, load_date, load_end_date,
    customer_since, customer_status, credit_score, record_source, hash_diff
)
SELECT 
    dbo.fn_GetHashKey(c.customer_id) AS customer_hash_key,
    GETDATE() AS load_date,
    NULL AS load_end_date,
    c.customer_since,
    c.customer_status,
    c.credit_score,
    'raw.customers' AS record_source,
    CONVERT(CHAR(32), HASHBYTES('MD5', 
        ISNULL(CAST(c.customer_since AS VARCHAR), '') + 
        ISNULL(c.customer_status, '') + 
        ISNULL(CAST(c.credit_score AS VARCHAR), '')
    ), 2) AS hash_diff
FROM raw.customers c
WHERE EXISTS (
    SELECT 1 FROM dv_hub.hub_customer h 
    WHERE h.customer_hash_key = dbo.fn_GetHashKey(c.customer_id)
)
AND NOT EXISTS (
    SELECT 1 FROM dv_sat.sat_customer_status s
    WHERE s.customer_hash_key = dbo.fn_GetHashKey(c.customer_id)
      AND s.load_end_date IS NULL
);

DECLARE @cust_status_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@cust_status_count AS VARCHAR) + ' customer status records';
PRINT '';

-- =============================================
-- LOAD SAT_ACCOUNT_DETAILS
-- =============================================
PRINT 'Loading dv_sat.sat_account_details...';

INSERT INTO dv_sat.sat_account_details (
    account_hash_key, load_date, load_end_date,
    account_type, balance, interest_rate, open_date, account_status,
    record_source, hash_diff
)
SELECT 
    dbo.fn_GetHashKey(a.account_number) AS account_hash_key,
    GETDATE() AS load_date,
    NULL AS load_end_date,
    a.account_type,
    a.balance,
    a.interest_rate,
    a.open_date,
    a.account_status,
    'raw.accounts' AS record_source,
    CONVERT(CHAR(32), HASHBYTES('MD5', 
        ISNULL(a.account_type, '') + 
        ISNULL(CAST(a.balance AS VARCHAR), '') + 
        ISNULL(CAST(a.interest_rate AS VARCHAR), '') + 
        ISNULL(a.account_status, '')
    ), 2) AS hash_diff
FROM raw.accounts a
WHERE EXISTS (
    SELECT 1 FROM dv_hub.hub_account h 
    WHERE h.account_hash_key = dbo.fn_GetHashKey(a.account_number)
)
AND NOT EXISTS (
    SELECT 1 FROM dv_sat.sat_account_details s
    WHERE s.account_hash_key = dbo.fn_GetHashKey(a.account_number)
      AND s.load_end_date IS NULL
);

DECLARE @acct_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@acct_count AS VARCHAR) + ' account detail records';
PRINT '';

-- =============================================
-- LOAD SAT_TRANSACTION_DETAILS
-- =============================================
PRINT 'Loading dv_sat.sat_transaction_details...';

INSERT INTO dv_sat.sat_transaction_details (
    transaction_hash_key, load_date, load_end_date,
    transaction_date, transaction_type, amount, description, merchant_name, category,
    record_source, hash_diff
)
SELECT 
    dbo.fn_GetHashKey(t.transaction_id) AS transaction_hash_key,
    GETDATE() AS load_date,
    NULL AS load_end_date,
    t.transaction_date,
    t.transaction_type,
    t.amount,
    t.description,
    t.merchant_name,
    t.category,
    'raw.transactions' AS record_source,
    CONVERT(CHAR(32), HASHBYTES('MD5', 
        ISNULL(CAST(t.transaction_date AS VARCHAR), '') + 
        ISNULL(t.transaction_type, '') + 
        ISNULL(CAST(t.amount AS VARCHAR), '') + 
        ISNULL(t.merchant_name, '')
    ), 2) AS hash_diff
FROM raw.transactions t
WHERE EXISTS (
    SELECT 1 FROM dv_hub.hub_transaction h 
    WHERE h.transaction_hash_key = dbo.fn_GetHashKey(t.transaction_id)
)
AND NOT EXISTS (
    SELECT 1 FROM dv_sat.sat_transaction_details s
    WHERE s.transaction_hash_key = dbo.fn_GetHashKey(t.transaction_id)
      AND s.load_end_date IS NULL
);

DECLARE @txn_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@txn_count AS VARCHAR) + ' transaction detail records';
PRINT '';

-- =============================================
-- LOAD SAT_BRANCH_INFO
-- =============================================
PRINT 'Loading dv_sat.sat_branch_info...';

INSERT INTO dv_sat.sat_branch_info (
    branch_hash_key, load_date, load_end_date,
    branch_name, city, state, region, record_source, hash_diff
)
SELECT 
    dbo.fn_GetHashKey(b.branch_code) AS branch_hash_key,
    GETDATE() AS load_date,
    NULL AS load_end_date,
    b.branch_name,
    b.city,
    b.state,
    b.region,
    'raw.branches' AS record_source,
    CONVERT(CHAR(32), HASHBYTES('MD5', 
        ISNULL(b.branch_name, '') + 
        ISNULL(b.city, '') + 
        ISNULL(b.state, '') + 
        ISNULL(b.region, '')
    ), 2) AS hash_diff
FROM raw.branches b
WHERE EXISTS (
    SELECT 1 FROM dv_hub.hub_branch h 
    WHERE h.branch_hash_key = dbo.fn_GetHashKey(b.branch_code)
)
AND NOT EXISTS (
    SELECT 1 FROM dv_sat.sat_branch_info s
    WHERE s.branch_hash_key = dbo.fn_GetHashKey(b.branch_code)
      AND s.load_end_date IS NULL
);

DECLARE @branch_count INT = @@ROWCOUNT;
PRINT '✓ Loaded ' + CAST(@branch_count AS VARCHAR) + ' branch info records';
PRINT '';

-- =============================================
-- Update Pipeline Status
-- =============================================
DECLARE @total_sat_rows INT = @cust_demo_count + @cust_status_count + @acct_count + @txn_count + @branch_count;

UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = @total_sat_rows
WHERE layer = 'satellite' 
  AND script_name = '02-load-satellites.sql'
  AND status = 'running';
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Satellite Loading Complete!';
PRINT '========================================';
PRINT '';

SELECT 
    'dv_sat.sat_customer_demographics' AS satellite_table,
    COUNT(*) AS record_count,
    SUM(CASE WHEN load_end_date IS NULL THEN 1 ELSE 0 END) AS current_records,
    SUM(CASE WHEN load_end_date IS NOT NULL THEN 1 ELSE 0 END) AS historical_records
FROM dv_sat.sat_customer_demographics
UNION ALL
SELECT 'dv_sat.sat_customer_status', COUNT(*), 
       SUM(CASE WHEN load_end_date IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN load_end_date IS NOT NULL THEN 1 ELSE 0 END)
FROM dv_sat.sat_customer_status
UNION ALL
SELECT 'dv_sat.sat_account_details', COUNT(*), 
       SUM(CASE WHEN load_end_date IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN load_end_date IS NOT NULL THEN 1 ELSE 0 END)
FROM dv_sat.sat_account_details
UNION ALL
SELECT 'dv_sat.sat_transaction_details', COUNT(*), 
       SUM(CASE WHEN load_end_date IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN load_end_date IS NOT NULL THEN 1 ELSE 0 END)
FROM dv_sat.sat_transaction_details
UNION ALL
SELECT 'dv_sat.sat_branch_info', COUNT(*), 
       SUM(CASE WHEN load_end_date IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN load_end_date IS NOT NULL THEN 1 ELSE 0 END)
FROM dv_sat.sat_branch_info;

PRINT '';
PRINT 'Sample Satellite Record:';
SELECT TOP 1 * FROM dv_sat.sat_customer_demographics WHERE load_end_date IS NULL;

PRINT '';
PRINT 'Satellite Features:';
PRINT '✓ SCD Type 2 implementation (full history)';
PRINT '✓ Current records have load_end_date = NULL';
PRINT '✓ Hash diff detects attribute changes';
PRINT '✓ Enables point-in-time queries';
PRINT '';
PRINT 'Next: Create Business Vault views (Phase 4)';
GO
