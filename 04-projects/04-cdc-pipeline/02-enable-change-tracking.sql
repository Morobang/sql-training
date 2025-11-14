-- ============================================================================
-- Enable SQL Server Change Tracking
-- ============================================================================
-- Built-in feature that tracks which rows changed (not what changed)
-- Lightweight, minimal storage overhead
-- ============================================================================

USE TechStore_Source;
GO

PRINT '=================================================================';
PRINT 'ENABLING SQL SERVER CHANGE TRACKING';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
WHAT IS SQL SERVER CHANGE TRACKING?
============================================================================

Built-in feature (SQL Server 2008+) that tracks row-level changes:
- Captures INSERT, UPDATE, DELETE operations
- Stores WHICH rows changed (not old/new values)
- Uses version numbers to track change sequence
- Minimal storage (just tracking info, not full data)

HOW IT WORKS:
1. Enable on database
2. Enable on specific tables
3. SQL Server maintains internal change tables
4. Query CHANGETABLE() function to get changes since last sync

COMPARED TO CDC (sys.sp_cdc_enable_table):
Change Tracking          vs          SQL Server CDC
- Lightweight                        - More overhead
- Which rows changed                 - What changed (old/new values)
- Minimal storage                    - Stores full change history
- Simpler setup                      - More complex
- Best for: Simple sync              - Best for: Audit trails

STORAGE IMPACT:
- Internal change table: ~10 bytes per changed row
- Retention: Configurable (default 3 days)
- Auto cleanup: Old changes purged automatically
============================================================================
*/

-- ============================================================================
-- STEP 1: Enable Change Tracking on Database
-- ============================================================================

-- Check if already enabled
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_databases 
    WHERE database_id = DB_ID('TechStore_Source')
)
BEGIN
    ALTER DATABASE TechStore_Source
    SET CHANGE_TRACKING = ON
    (
        CHANGE_RETENTION = 3 DAYS,      -- Keep changes for 3 days
        AUTO_CLEANUP = ON               -- Automatically purge old changes
    );
    
    PRINT '✓ Enabled Change Tracking on TechStore_Source database';
    PRINT '  - Retention: 3 days';
    PRINT '  - Auto cleanup: ON';
END
ELSE
BEGIN
    PRINT '✓ Change Tracking already enabled on database';
END
GO

-- ============================================================================
-- STEP 2: Enable Change Tracking on Tables
-- ============================================================================

USE TechStore_Source;
GO

-- Enable on Orders table
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_tables
    WHERE object_id = OBJECT_ID('Orders')
)
BEGIN
    ALTER TABLE Orders
    ENABLE CHANGE_TRACKING
    WITH (TRACK_COLUMNS_UPDATED = ON);  -- Track which columns changed
    
    PRINT '✓ Enabled Change Tracking on Orders table';
    PRINT '  - Track columns updated: ON';
END
ELSE
BEGIN
    PRINT '✓ Change Tracking already enabled on Orders';
END
GO

-- Enable on Customers table
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_tables
    WHERE object_id = OBJECT_ID('Customers')
)
BEGIN
    ALTER TABLE Customers
    ENABLE CHANGE_TRACKING
    WITH (TRACK_COLUMNS_UPDATED = ON);
    
    PRINT '✓ Enabled Change Tracking on Customers table';
END
ELSE
BEGIN
    PRINT '✓ Change Tracking already enabled on Customers';
END
GO

-- Enable on Products table
IF NOT EXISTS (
    SELECT 1 FROM sys.change_tracking_tables
    WHERE object_id = OBJECT_ID('Products')
)
BEGIN
    ALTER TABLE Products
    ENABLE CHANGE_TRACKING
    WITH (TRACK_COLUMNS_UPDATED = ON);
    
    PRINT '✓ Enabled Change Tracking on Products table';
END
ELSE
BEGIN
    PRINT '✓ Change Tracking already enabled on Products';
END
GO

-- ============================================================================
-- STEP 3: Get Current Change Tracking Version
-- ============================================================================

DECLARE @current_version BIGINT;
SET @current_version = CHANGE_TRACKING_CURRENT_VERSION();

PRINT '';
PRINT 'Current Change Tracking Version: ' + CAST(@current_version AS VARCHAR(20));
PRINT '(This is your starting point for CDC queries)';

-- Update watermark with current version
USE TechStore_Target;
GO

UPDATE CDC_Watermark
SET LastSyncVersion = CHANGE_TRACKING_CURRENT_VERSION(),
    LastSyncTime = GETDATE(),
    LastRunStatus = 'Initialized'
WHERE TableName IN ('Orders', 'Customers', 'Products');

PRINT '✓ Updated watermark table with current version';

-- ============================================================================
-- STEP 4: Verify Change Tracking Setup
-- ============================================================================

USE TechStore_Source;
GO

PRINT '';
PRINT '=================================================================';
PRINT 'CHANGE TRACKING STATUS';
PRINT '=================================================================';

-- Database-level settings
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    is_auto_cleanup_on AS AutoCleanup,
    retention_period AS RetentionPeriod,
    retention_period_units_desc AS RetentionUnits
FROM sys.change_tracking_databases
WHERE database_id = DB_ID('TechStore_Source');

PRINT '';

-- Table-level settings
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    is_track_columns_updated_on AS TrackColumnsUpdated,
    min_valid_version AS MinValidVersion,
    CHANGE_TRACKING_MIN_VALID_VERSION(object_id) AS CurrentMinVersion
FROM sys.change_tracking_tables
WHERE object_id IN (
    OBJECT_ID('Orders'),
    OBJECT_ID('Customers'),
    OBJECT_ID('Products')
);

-- ============================================================================
-- STEP 5: Test Change Tracking
-- ============================================================================

PRINT '';
PRINT '=================================================================';
PRINT 'TESTING CHANGE TRACKING';
PRINT '=================================================================';

-- Get version before changes
DECLARE @version_before BIGINT;
SET @version_before = CHANGE_TRACKING_CURRENT_VERSION();
PRINT 'Version before changes: ' + CAST(@version_before AS VARCHAR(20));

-- Make some changes
PRINT '';
PRINT 'Making test changes...';

-- INSERT
INSERT INTO Orders (CustomerID, TotalAmount, OrderStatus, ShippingAddress)
VALUES (1, 299.99, 'Pending', '123 Main St, Seattle, WA 98101');
PRINT '  ✓ Inserted 1 order';

-- UPDATE
UPDATE Customers
SET LoyaltyTier = 'Platinum'
WHERE CustomerID = 3;
PRINT '  ✓ Updated customer #3 loyalty tier';

-- DELETE
DECLARE @product_to_delete INT = 5;
DELETE FROM Products WHERE ProductID = @product_to_delete;
PRINT '  ✓ Deleted product #5';

-- Get version after changes
DECLARE @version_after BIGINT;
SET @version_after = CHANGE_TRACKING_CURRENT_VERSION();
PRINT '';
PRINT 'Version after changes: ' + CAST(@version_after AS VARCHAR(20));
PRINT 'Version difference: ' + CAST(@version_after - @version_before AS VARCHAR(20));

-- ============================================================================
-- STEP 6: Query Changes Using CHANGETABLE()
-- ============================================================================

PRINT '';
PRINT '=================================================================';
PRINT 'QUERYING CHANGES';
PRINT '=================================================================';

-- Query changes to Orders table
PRINT '';
PRINT 'Changes to Orders table:';
SELECT 
    CT.OrderID,
    CT.SYS_CHANGE_VERSION,
    CT.SYS_CHANGE_OPERATION,
    CASE CT.SYS_CHANGE_OPERATION
        WHEN 'I' THEN 'INSERT'
        WHEN 'U' THEN 'UPDATE'
        WHEN 'D' THEN 'DELETE'
    END AS OperationType,
    O.CustomerID,
    O.TotalAmount,
    O.OrderStatus
FROM CHANGETABLE(CHANGES Orders, @version_before) AS CT
LEFT JOIN Orders O ON CT.OrderID = O.OrderID;

-- Query changes to Customers table
PRINT '';
PRINT 'Changes to Customers table:';
SELECT 
    CT.CustomerID,
    CT.SYS_CHANGE_VERSION,
    CASE CT.SYS_CHANGE_OPERATION
        WHEN 'I' THEN 'INSERT'
        WHEN 'U' THEN 'UPDATE'
        WHEN 'D' THEN 'DELETE'
    END AS OperationType,
    C.FirstName,
    C.LastName,
    C.LoyaltyTier
FROM CHANGETABLE(CHANGES Customers, @version_before) AS CT
LEFT JOIN Customers C ON CT.CustomerID = C.CustomerID;

-- Query changes to Products table
PRINT '';
PRINT 'Changes to Products table:';
SELECT 
    CT.ProductID,
    CT.SYS_CHANGE_VERSION,
    CASE CT.SYS_CHANGE_OPERATION
        WHEN 'I' THEN 'INSERT'
        WHEN 'U' THEN 'UPDATE'
        WHEN 'D' THEN 'DELETE'
    END AS OperationType,
    P.ProductName,
    P.Price
FROM CHANGETABLE(CHANGES Products, @version_before) AS CT
LEFT JOIN Products P ON CT.ProductID = P.ProductID;

-- ============================================================================
-- STEP 7: Check Which Columns Changed
-- ============================================================================

PRINT '';
PRINT '=================================================================';
PRINT 'COLUMN-LEVEL CHANGE TRACKING';
PRINT '=================================================================';

-- For updated rows, check which columns changed
SELECT 
    CT.CustomerID,
    C.FirstName,
    C.LastName,
    CHANGE_TRACKING_IS_COLUMN_IN_MASK(
        COLUMNPROPERTY(OBJECT_ID('Customers'), 'LoyaltyTier', 'ColumnId'),
        CT.SYS_CHANGE_COLUMNS
    ) AS LoyaltyTier_Changed,
    CHANGE_TRACKING_IS_COLUMN_IN_MASK(
        COLUMNPROPERTY(OBJECT_ID('Customers'), 'Email', 'ColumnId'),
        CT.SYS_CHANGE_COLUMNS
    ) AS Email_Changed,
    C.LoyaltyTier AS NewValue
FROM CHANGETABLE(CHANGES Customers, @version_before) AS CT
JOIN Customers C ON CT.CustomerID = C.CustomerID
WHERE CT.SYS_CHANGE_OPERATION = 'U';  -- Only UPDATEs

PRINT '';
PRINT '=================================================================';
PRINT 'CHANGE TRACKING ENABLED AND TESTED!';
PRINT '=================================================================';
PRINT '';
PRINT 'NEXT: Run 03-capture-changes.sql to build incremental load queries';
PRINT '';

/*
============================================================================
CHANGE TRACKING COMPLETE!
============================================================================

✅ Enabled Change Tracking on database
✅ Enabled on Orders, Customers, Products tables
✅ Set retention period (3 days)
✅ Tested with INSERT, UPDATE, DELETE

HOW TO USE CHANGETABLE():

1. Get last sync version from watermark table
2. Query changes since that version:

   SELECT * FROM CHANGETABLE(CHANGES TableName, @last_version) AS CT

3. Join to source table to get current values:

   SELECT CT.*, T.*
   FROM CHANGETABLE(CHANGES TableName, @last_version) AS CT
   LEFT JOIN TableName T ON CT.PrimaryKey = T.PrimaryKey

4. SYS_CHANGE_OPERATION tells you what happened:
   - 'I' = INSERT (new row)
   - 'U' = UPDATE (row changed)
   - 'D' = DELETE (row removed)

5. For DELETEs, T.* will be NULL (row doesn't exist anymore)

BEST PRACTICES:

✓ Store sync version in watermark table (not timestamp)
✓ Set appropriate retention period (match CDC schedule)
✓ Monitor CHANGE_TRACKING_MIN_VALID_VERSION() 
  (if last sync version < min valid, need full refresh)
✓ Use TRACK_COLUMNS_UPDATED to detect which fields changed
✓ Handle DELETEs with soft delete flag in target

PERFORMANCE TIPS:

- Change tracking adds minimal overhead (~1-2%)
- Internal change tables are automatically indexed
- Auto cleanup removes old changes (no maintenance needed)
- For high-volume tables, consider shorter retention

Next file will show how to build a complete incremental load!
============================================================================
*/
