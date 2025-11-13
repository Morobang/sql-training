-- =============================================
-- Phase 4: Business Vault Views
-- =============================================
-- Purpose: Create query-friendly views for reporting and analytics
-- Pattern: Join Hubs + Links + Satellites for easy consumption
-- =============================================

USE SecureBank_DataVault;
GO

PRINT 'Creating Business Vault views...';
PRINT '';

-- =============================================
-- VIEW: Customer 360
-- =============================================
PRINT 'Creating business_vault.vw_customer_360...';
GO

CREATE OR ALTER VIEW business_vault.vw_customer_360 AS
SELECT 
    -- Hub
    h.customer_id,
    -- Demographics (current)
    d.first_name,
    d.last_name,
    d.first_name + ' ' + d.last_name AS full_name,
    d.email,
    d.phone,
    d.address,
    d.city,
    d.state,
    d.zip_code,
    d.date_of_birth,
    DATEDIFF(YEAR, d.date_of_birth, GETDATE()) AS age,
    d.ssn_last4,
    -- Status (current)
    s.customer_since,
    DATEDIFF(DAY, s.customer_since, GETDATE()) AS days_as_customer,
    s.customer_status,
    s.credit_score,
    -- Account Summary
    (SELECT COUNT(*) 
     FROM dv_link.link_customer_account lca 
     WHERE lca.customer_hash_key = h.customer_hash_key) AS total_accounts,
    (SELECT SUM(ad.balance) 
     FROM dv_link.link_customer_account lca
     JOIN dv_sat.sat_account_details ad ON lca.account_hash_key = ad.account_hash_key
     WHERE lca.customer_hash_key = h.customer_hash_key
       AND ad.load_end_date IS NULL) AS total_balance,
    -- Metadata
    h.load_date AS customer_onboarded
FROM dv_hub.hub_customer h
LEFT JOIN dv_sat.sat_customer_demographics d ON h.customer_hash_key = d.customer_hash_key AND d.load_end_date IS NULL
LEFT JOIN dv_sat.sat_customer_status s ON h.customer_hash_key = s.customer_hash_key AND s.load_end_date IS NULL;
GO

PRINT '✓ vw_customer_360 created';
PRINT '';

-- =============================================
-- VIEW: Account Details
-- =============================================
PRINT 'Creating business_vault.vw_account_details...';
GO

CREATE OR ALTER VIEW business_vault.vw_account_details AS
SELECT 
    -- Hub
    ha.account_number,
    -- Account Details (current)
    ad.account_type,
    ad.balance,
    ad.interest_rate,
    ad.open_date,
    ad.account_status,
    DATEDIFF(DAY, ad.open_date, GETDATE()) AS days_open,
    -- Customer Info
    hc.customer_id,
    cd.first_name + ' ' + cd.last_name AS customer_name,
    cd.email AS customer_email,
    cs.customer_status,
    -- Branch Info
    hb.branch_code,
    bi.branch_name,
    bi.city AS branch_city,
    bi.state AS branch_state,
    bi.region AS branch_region,
    -- Transaction Summary
    (SELECT COUNT(*) 
     FROM dv_link.link_account_transaction lat 
     WHERE lat.account_hash_key = ha.account_hash_key) AS total_transactions,
    (SELECT SUM(td.amount) 
     FROM dv_link.link_account_transaction lat
     JOIN dv_sat.sat_transaction_details td ON lat.transaction_hash_key = td.transaction_hash_key
     WHERE lat.account_hash_key = ha.account_hash_key
       AND td.load_end_date IS NULL
       AND td.amount > 0) AS total_deposits,
    (SELECT SUM(ABS(td.amount)) 
     FROM dv_link.link_account_transaction lat
     JOIN dv_sat.sat_transaction_details td ON lat.transaction_hash_key = td.transaction_hash_key
     WHERE lat.account_hash_key = ha.account_hash_key
       AND td.load_end_date IS NULL
       AND td.amount < 0) AS total_withdrawals,
    -- Metadata
    ha.load_date AS account_created
FROM dv_hub.hub_account ha
LEFT JOIN dv_sat.sat_account_details ad ON ha.account_hash_key = ad.account_hash_key AND ad.load_end_date IS NULL
LEFT JOIN dv_link.link_customer_account lca ON ha.account_hash_key = lca.account_hash_key
LEFT JOIN dv_hub.hub_customer hc ON lca.customer_hash_key = hc.customer_hash_key
LEFT JOIN dv_sat.sat_customer_demographics cd ON hc.customer_hash_key = cd.customer_hash_key AND cd.load_end_date IS NULL
LEFT JOIN dv_sat.sat_customer_status cs ON hc.customer_hash_key = cs.customer_hash_key AND cs.load_end_date IS NULL
LEFT JOIN dv_link.link_account_branch lab ON ha.account_hash_key = lab.account_hash_key
LEFT JOIN dv_hub.hub_branch hb ON lab.branch_hash_key = hb.branch_hash_key
LEFT JOIN dv_sat.sat_branch_info bi ON hb.branch_hash_key = bi.branch_hash_key AND bi.load_end_date IS NULL;
GO

PRINT '✓ vw_account_details created';
PRINT '';

-- =============================================
-- VIEW: Transaction History
-- =============================================
PRINT 'Creating business_vault.vw_transaction_history...';
GO

CREATE OR ALTER VIEW business_vault.vw_transaction_history AS
SELECT 
    -- Transaction
    ht.transaction_id,
    td.transaction_date,
    td.transaction_type,
    td.amount,
    td.description,
    td.merchant_name,
    td.category,
    -- Account
    ha.account_number,
    ad.account_type,
    ad.balance AS current_account_balance,
    -- Customer
    hc.customer_id,
    cd.first_name + ' ' + cd.last_name AS customer_name,
    cd.email AS customer_email,
    -- Metadata
    ht.load_date AS transaction_loaded
FROM dv_hub.hub_transaction ht
LEFT JOIN dv_sat.sat_transaction_details td ON ht.transaction_hash_key = td.transaction_hash_key AND td.load_end_date IS NULL
LEFT JOIN dv_link.link_account_transaction lat ON ht.transaction_hash_key = lat.transaction_hash_key
LEFT JOIN dv_hub.hub_account ha ON lat.account_hash_key = ha.account_hash_key
LEFT JOIN dv_sat.sat_account_details ad ON ha.account_hash_key = ad.account_hash_key AND ad.load_end_date IS NULL
LEFT JOIN dv_link.link_customer_account lca ON ha.account_hash_key = lca.account_hash_key
LEFT JOIN dv_hub.hub_customer hc ON lca.customer_hash_key = hc.customer_hash_key
LEFT JOIN dv_sat.sat_customer_demographics cd ON hc.customer_hash_key = cd.customer_hash_key AND cd.load_end_date IS NULL;
GO

PRINT '✓ vw_transaction_history created';
PRINT '';

-- =============================================
-- VIEW: Audit Trail (Change History)
-- =============================================
PRINT 'Creating business_vault.vw_customer_audit_trail...';
GO

CREATE OR ALTER VIEW business_vault.vw_customer_audit_trail AS
SELECT 
    h.customer_id,
    'Demographics' AS change_category,
    d.load_date AS change_date,
    d.load_end_date AS superseded_date,
    CASE WHEN d.load_end_date IS NULL THEN 'Current' ELSE 'Historical' END AS record_status,
    d.email,
    d.phone,
    d.address,
    d.city,
    d.state,
    d.record_source
FROM dv_hub.hub_customer h
JOIN dv_sat.sat_customer_demographics d ON h.customer_hash_key = d.customer_hash_key

UNION ALL

SELECT 
    h.customer_id,
    'Status' AS change_category,
    s.load_date AS change_date,
    s.load_end_date AS superseded_date,
    CASE WHEN s.load_end_date IS NULL THEN 'Current' ELSE 'Historical' END AS record_status,
    NULL AS email,
    NULL AS phone,
    s.customer_status AS address,  -- Reusing columns for status info
    CAST(s.credit_score AS NVARCHAR) AS city,
    NULL AS state,
    s.record_source
FROM dv_hub.hub_customer h
JOIN dv_sat.sat_customer_status s ON h.customer_hash_key = s.customer_hash_key;
GO

PRINT '✓ vw_customer_audit_trail created';
PRINT '';

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '========================================';
PRINT 'Business Vault Views Created!';
PRINT '========================================';
PRINT '';

SELECT 
    TABLE_NAME AS view_name,
    VIEW_DEFINITION AS definition_preview
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'business_vault'
ORDER BY TABLE_NAME;

PRINT '';
PRINT 'Sample Queries:';
PRINT '';
PRINT '-- Customer 360 View';
SELECT TOP 5 customer_id, full_name, email, customer_status, total_accounts, total_balance
FROM business_vault.vw_customer_360
ORDER BY total_balance DESC;

PRINT '';
PRINT '-- Account Details';
SELECT TOP 5 account_number, account_type, balance, customer_name, branch_name, total_transactions
FROM business_vault.vw_account_details
WHERE account_status = 'Active'
ORDER BY balance DESC;

PRINT '';
PRINT '-- Transaction History';
SELECT TOP 5 transaction_id, transaction_date, transaction_type, amount, customer_name, merchant_name
FROM business_vault.vw_transaction_history
ORDER BY transaction_date DESC;

PRINT '';
PRINT 'Business Vault Benefits:';
PRINT '✓ Simplified querying (no complex joins needed)';
PRINT '✓ Current state only (load_end_date IS NULL filter built-in)';
PRINT '✓ Business-friendly column names';
PRINT '✓ Pre-calculated metrics and aggregations';
PRINT '';
PRINT 'Next: Run compliance reports (02-compliance-reports.sql)';
GO
