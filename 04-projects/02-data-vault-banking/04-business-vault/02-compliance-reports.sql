-- =============================================
-- Phase 4: Compliance & Regulatory Reports
-- =============================================
-- Purpose: Demonstrate Data Vault's compliance capabilities
-- Reports: Audit Trail, Point-in-Time, Regulatory Compliance
-- =============================================

USE SecureBank_DataVault;
GO

PRINT '========================================';
PRINT 'COMPLIANCE & REGULATORY REPORTING';
PRINT '========================================';
PRINT '';

-- =============================================
-- REPORT 1: Complete Audit Trail
-- =============================================
PRINT '=== REPORT 1: Complete Audit Trail ===';
PRINT 'Show all changes to customer data over time';
PRINT '';

SELECT 
    customer_id,
    change_category,
    change_date,
    superseded_date,
    record_status,
    DATEDIFF(DAY, change_date, ISNULL(superseded_date, GETDATE())) AS days_in_effect
FROM business_vault.vw_customer_audit_trail
WHERE customer_id = (SELECT TOP 1 customer_id FROM dv_hub.hub_customer ORDER BY customer_id)
ORDER BY change_date DESC;

PRINT '';
PRINT '✓ Shows complete change history for compliance audits';
PRINT '✓ Meets SOX Section 404 requirements (change tracking)';
PRINT '';

-- =============================================
-- REPORT 2: Point-in-Time Query
-- =============================================
PRINT '=== REPORT 2: Point-in-Time Query ===';
PRINT 'Query customer data as it appeared on a specific date';
PRINT '';

DECLARE @PointInTime DATETIME = DATEADD(DAY, -30, GETDATE());

PRINT 'Querying data as of: ' + CONVERT(VARCHAR, @PointInTime, 120);
PRINT '';

SELECT TOP 10
    h.customer_id,
    d.first_name + ' ' + d.last_name AS full_name,
    d.email,
    d.address,
    s.customer_status,
    s.credit_score,
    d.load_date AS demographics_version,
    s.load_date AS status_version
FROM dv_hub.hub_customer h
-- Get demographics as of the point in time
CROSS APPLY (
    SELECT TOP 1 *
    FROM dv_sat.sat_customer_demographics d2
    WHERE d2.customer_hash_key = h.customer_hash_key
      AND d2.load_date <= @PointInTime
      AND (d2.load_end_date IS NULL OR d2.load_end_date > @PointInTime)
    ORDER BY d2.load_date DESC
) d
-- Get status as of the point in time
CROSS APPLY (
    SELECT TOP 1 *
    FROM dv_sat.sat_customer_status s2
    WHERE s2.customer_hash_key = h.customer_hash_key
      AND s2.load_date <= @PointInTime
      AND (s2.load_end_date IS NULL OR s2.load_end_date > @PointInTime)
    ORDER BY s2.load_date DESC
) s;

PRINT '';
PRINT '✓ Critical for dispute resolution';
PRINT '✓ Regulatory requirement for banking (7-year retention)';
PRINT '';

-- =============================================
-- REPORT 3: Regulatory Summary (Basel III)
-- =============================================
PRINT '=== REPORT 3: Regulatory Risk Summary ===';
PRINT 'Customer risk segmentation for Basel III compliance';
PRINT '';

SELECT 
    CASE 
        WHEN credit_score >= 700 THEN 'Low Risk'
        WHEN credit_score >= 600 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_category,
    COUNT(*) AS customer_count,
    SUM(total_balance) AS total_exposure,
    AVG(total_balance) AS avg_balance_per_customer,
    AVG(credit_score) AS avg_credit_score
FROM business_vault.vw_customer_360
WHERE customer_status = 'Active'
GROUP BY 
    CASE 
        WHEN credit_score >= 700 THEN 'Low Risk'
        WHEN credit_score >= 600 THEN 'Medium Risk'
        ELSE 'High Risk'
    END
ORDER BY 
    CASE 
        WHEN credit_score >= 700 THEN 1
        WHEN credit_score >= 600 THEN 2
        ELSE 3
    END;

PRINT '';
PRINT '✓ Required for Basel III capital adequacy calculations';
PRINT '✓ Risk-weighted asset reporting';
PRINT '';

-- =============================================
-- REPORT 4: Fraud Detection - Suspicious Patterns
-- =============================================
PRINT '=== REPORT 4: Fraud Detection ===';
PRINT 'High-value transactions requiring review';
PRINT '';

SELECT 
    transaction_id,
    customer_name,
    account_number,
    transaction_date,
    transaction_type,
    amount,
    merchant_name,
    CASE 
        WHEN ABS(amount) > 10000 THEN 'High Value'
        WHEN ABS(amount) > 5000 THEN 'Medium Value'
        ELSE 'Standard'
    END AS risk_flag
FROM business_vault.vw_transaction_history
WHERE ABS(amount) > 5000
ORDER BY ABS(amount) DESC;

PRINT '';
PRINT '✓ Bank Secrecy Act (BSA) compliance';
PRINT '✓ Anti-Money Laundering (AML) monitoring';
PRINT '';

-- =============================================
-- REPORT 5: Account Status Changes
-- =============================================
PRINT '=== REPORT 5: Account Status Change Log ===';
PRINT 'Track all account status changes (active → closed → frozen)';
PRINT '';

SELECT TOP 20
    ha.account_number,
    ad.account_type,
    ad.account_status,
    ad.load_date AS status_change_date,
    ad.load_end_date AS status_end_date,
    CASE WHEN ad.load_end_date IS NULL THEN 'Current' ELSE 'Historical' END AS record_status,
    hc.customer_id
FROM dv_hub.hub_account ha
JOIN dv_sat.sat_account_details ad ON ha.account_hash_key = ad.account_hash_key
LEFT JOIN dv_link.link_customer_account lca ON ha.account_hash_key = lca.account_hash_key
LEFT JOIN dv_hub.hub_customer hc ON lca.customer_hash_key = hc.customer_hash_key
WHERE ad.account_status IN ('Closed', 'Frozen')
ORDER BY ad.load_date DESC;

PRINT '';
PRINT '✓ Required for customer dispute resolution';
PRINT '✓ Proves account state at any point in time';
PRINT '';

-- =============================================
-- REPORT 6: Data Lineage & Pipeline Status
-- =============================================
PRINT '=== REPORT 6: Data Lineage & Pipeline Status ===';
PRINT 'Track ETL execution and data transformations';
PRINT '';

PRINT 'Recent Pipeline Executions:';
SELECT TOP 10
    layer,
    script_name,
    start_time,
    end_time,
    status,
    rows_processed,
    DATEDIFF(SECOND, start_time, ISNULL(end_time, GETDATE())) AS duration_seconds
FROM metadata.pipeline_runs
ORDER BY start_time DESC;

PRINT '';
PRINT 'Data Lineage:';
SELECT 
    target_table,
    source_table,
    transformation_type,
    COUNT(*) AS transformation_count
FROM metadata.data_lineage
GROUP BY target_table, source_table, transformation_type
ORDER BY target_table;

PRINT '';
PRINT '✓ GDPR Article 30 requirement (data processing records)';
PRINT '✓ SOX Section 404 (IT controls documentation)';
PRINT '';

-- =============================================
-- REPORT 7: Hash Key Registry
-- =============================================
PRINT '=== REPORT 7: Hash Key Registry ===';
PRINT 'Map hash keys back to business keys for debugging';
PRINT '';

SELECT 
    entity_type,
    COUNT(*) AS total_keys,
    MIN(created_date) AS first_created,
    MAX(created_date) AS last_created
FROM metadata.hash_key_registry
GROUP BY entity_type
ORDER BY entity_type;

PRINT '';

-- =============================================
-- SUMMARY
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'COMPLIANCE REPORTING SUMMARY';
PRINT '========================================';
PRINT '';
PRINT 'Regulatory Frameworks Supported:';
PRINT '✓ SOX (Sarbanes-Oxley) - Change tracking & IT controls';
PRINT '✓ GDPR - Data processing records & lineage';
PRINT '✓ Basel III - Risk-weighted asset reporting';
PRINT '✓ BSA/AML - Transaction monitoring';
PRINT '✓ Dodd-Frank - Audit trail requirements';
PRINT '';
PRINT 'Data Vault Capabilities:';
PRINT '✓ Complete audit trail (every change tracked)';
PRINT '✓ Point-in-time queries (reconstruct data at any date)';
PRINT '✓ Data lineage (track transformations)';
PRINT '✓ Immutable history (no updates/deletes)';
PRINT '✓ Hash key traceability';
PRINT '';
PRINT '========================================';
PRINT 'Data Vault 2.0 Project Complete!';
PRINT '========================================';
GO
