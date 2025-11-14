-- ============================================================================
-- Restore Historical Data (Rollback and Recovery)
-- ============================================================================
-- Techniques for recovering deleted or corrupted data from temporal tables
-- ============================================================================

USE TechStore_Temporal;
GO

PRINT '=================================================================';
PRINT 'DATA RESTORATION FROM TEMPORAL TABLES';
PRINT '=================================================================';
PRINT '';

/*
============================================================================
DATA RESTORATION SCENARIOS
============================================================================

COMMON RECOVERY SCENARIOS:

1. Accidental Deletion
   - User deleted important records
   - "Oops, I shouldn't have deleted that!"
   
2. Bad Update
   - Incorrect bulk update corrupted data
   - "We set all prices to $0 by mistake!"
   
3. Restore to Point in Time
   - Data was correct yesterday, broken now
   - "Rollback to yesterday 3 PM"
   
4. Recover Specific Columns
   - Only some columns were corrupted
   - "Restore just the price column"
   
5. Compare Before/After
   - Verify what changed during incident
   - "Show me what changed during the outage"

RESTORATION PROCESS:

1. Disable system versioning (required for manual edits)
2. Query history table to find correct version
3. INSERT/UPDATE restored data
4. Re-enable system versioning
5. Verify restoration

============================================================================
*/

-- ============================================================================
-- Setup: Create Scenario Data
-- ============================================================================

PRINT 'Setting up restoration scenarios...';
PRINT '';

-- Ensure we have a clean starting point
PRINT 'Current state before simulating issues:';
SELECT ProductID, ProductName, Price, StockQuantity
FROM Products
ORDER BY ProductID;

PRINT '';

-- ============================================================================
-- SCENARIO 1: Accidental Deletion Recovery
-- ============================================================================

PRINT '=================================================================';
PRINT 'SCENARIO 1: ACCIDENTAL DELETION RECOVERY';
PRINT '=================================================================';
PRINT '';

PRINT 'Step 1: Simulating accidental deletion...';

-- Remember the deleted product
DECLARE @deleted_product_id INT = 1;
DECLARE @deleted_product_name VARCHAR(100);

SELECT @deleted_product_name = ProductName 
FROM Products 
WHERE ProductID = @deleted_product_id;

-- Accidentally delete
DELETE FROM Products WHERE ProductID = @deleted_product_id;
PRINT '  ✗ Accidentally deleted: ' + @deleted_product_name;
PRINT '';

WAITFOR DELAY '00:00:01';

-- Verify deletion
PRINT 'Current Products (product missing):';
SELECT ProductID, ProductName, Price
FROM Products
ORDER BY ProductID;

PRINT '';

-- Step 2: Find in history
PRINT 'Step 2: Finding deleted product in history...';

SELECT 
    ProductID,
    ProductName,
    Price,
    StockQuantity,
    ValidFrom,
    ValidTo,
    CASE 
        WHEN ValidTo < '9999-12-31' THEN '🗑️ DELETED'
        ELSE 'Active'
    END AS Status
FROM Products FOR SYSTEM_TIME ALL
WHERE ProductID = @deleted_product_id
ORDER BY ValidFrom DESC;

PRINT '';

-- Step 3: Restore from history
PRINT 'Step 3: Restoring deleted product...';

-- Disable system versioning (required to manually modify table)
ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);
PRINT '  ⚠️ System versioning temporarily disabled';

-- Restore the deleted row
INSERT INTO Products (ProductID, ProductName, Category, Price, StockQuantity, Supplier, ModifiedBy)
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    StockQuantity,
    Supplier,
    'SYSTEM-RECOVERY'
FROM ProductsHistory
WHERE ProductID = @deleted_product_id
AND ValidTo = (
    SELECT MAX(ValidTo) 
    FROM ProductsHistory 
    WHERE ProductID = @deleted_product_id
);

PRINT '  ✓ Product restored from history';

-- Re-enable system versioning
ALTER TABLE Products SET (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
);
PRINT '  ✓ System versioning re-enabled';
PRINT '';

-- Verify restoration
PRINT 'Products after restoration:';
SELECT ProductID, ProductName, Price, StockQuantity
FROM Products
ORDER BY ProductID;

PRINT '';
PRINT '✓ SCENARIO 1 COMPLETE: Product successfully recovered!';
PRINT '';

-- ============================================================================
-- SCENARIO 2: Bad Bulk Update Rollback
-- ============================================================================

PRINT '=================================================================';
PRINT 'SCENARIO 2: BAD BULK UPDATE ROLLBACK';
PRINT '=================================================================';
PRINT '';

PRINT 'Step 1: Recording current state...';

-- Save current prices
CREATE TABLE #OriginalPrices (
    ProductID INT,
    OriginalPrice DECIMAL(10,2)
);

INSERT INTO #OriginalPrices
SELECT ProductID, Price FROM Products;

PRINT '  ✓ Saved current prices';
PRINT '';

WAITFOR DELAY '00:00:01';

-- Step 2: Simulate bad update
PRINT 'Step 2: Simulating catastrophic pricing error...';
PRINT '  (Setting all prices to $0.00 - DISASTER!)';

UPDATE Products SET Price = 0.00;
PRINT '  ✗ All prices corrupted!';
PRINT '';

WAITFOR DELAY '00:00:01';

-- Show the damage
PRINT 'Products with corrupted prices:';
SELECT ProductID, ProductName, Price
FROM Products;

PRINT '';

-- Step 3: Identify the problem
PRINT 'Step 3: Comparing to history...';

SELECT 
    p.ProductID,
    p.ProductName,
    h.Price AS HistoricalPrice,
    p.Price AS CurrentPrice,
    h.Price - p.Price AS PriceDifference
FROM Products p
JOIN (
    SELECT 
        ProductID,
        Price,
        ValidFrom,
        ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY ValidFrom DESC) AS rn
    FROM ProductsHistory
) h ON p.ProductID = h.ProductID AND h.rn = 1;

PRINT '';

-- Step 4: Restore prices from history
PRINT 'Step 4: Restoring prices from history...';

ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);

-- Restore prices
UPDATE p
SET p.Price = h.Price
FROM Products p
JOIN (
    SELECT 
        ProductID,
        Price,
        ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY ValidFrom DESC) AS rn
    FROM ProductsHistory
) h ON p.ProductID = h.ProductID AND h.rn = 1;

ALTER TABLE Products SET (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
);

PRINT '  ✓ Prices restored from history';
PRINT '';

-- Verify restoration
PRINT 'Products after price restoration:';
SELECT 
    p.ProductID,
    p.ProductName,
    p.Price AS RestoredPrice,
    o.OriginalPrice,
    CASE 
        WHEN ABS(p.Price - o.OriginalPrice) < 0.01 THEN '✓ Match'
        ELSE '✗ Mismatch'
    END AS VerificationStatus
FROM Products p
JOIN #OriginalPrices o ON p.ProductID = o.ProductID
ORDER BY p.ProductID;

DROP TABLE #OriginalPrices;

PRINT '';
PRINT '✓ SCENARIO 2 COMPLETE: Prices successfully rolled back!';
PRINT '';

-- ============================================================================
-- SCENARIO 3: Point-in-Time Restoration
-- ============================================================================

PRINT '=================================================================';
PRINT 'SCENARIO 3: POINT-IN-TIME RESTORATION';
PRINT '=================================================================';
PRINT '';

PRINT 'Goal: Restore entire table to state from 5 seconds ago';
PRINT '';

-- Make some changes
WAITFOR DELAY '00:00:01';
UPDATE Products SET StockQuantity = 0 WHERE ProductID IN (2, 4);
PRINT '  Changed: Set stock to 0 for products 2 and 4';

WAITFOR DELAY '00:00:01';
UPDATE Products SET Price = 999.99 WHERE ProductID = 5;
PRINT '  Changed: Set price to $999.99 for product 5';

PRINT '';

-- Show current bad state
PRINT 'Current corrupted state:';
SELECT ProductID, ProductName, Price, StockQuantity
FROM Products
WHERE ProductID IN (2, 4, 5)
ORDER BY ProductID;

PRINT '';

-- Restore to 5 seconds ago
PRINT 'Restoring to 5 seconds ago...';

DECLARE @restore_point DATETIME2 = DATEADD(SECOND, -5, SYSDATETIME());

ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);

-- Restore specific products to historical state
UPDATE p
SET 
    p.Price = h.Price,
    p.StockQuantity = h.StockQuantity
FROM Products p
JOIN (
    SELECT * 
    FROM Products FOR SYSTEM_TIME AS OF @restore_point
) h ON p.ProductID = h.ProductID
WHERE p.ProductID IN (2, 4, 5);

ALTER TABLE Products SET (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
);

PRINT '  ✓ Restored products 2, 4, 5 to previous state';
PRINT '';

-- Verify
PRINT 'Products after point-in-time restoration:';
SELECT ProductID, ProductName, Price, StockQuantity
FROM Products
WHERE ProductID IN (2, 4, 5)
ORDER BY ProductID;

PRINT '';
PRINT '✓ SCENARIO 3 COMPLETE: Point-in-time restoration successful!';
PRINT '';

-- ============================================================================
-- SCENARIO 4: Selective Column Restoration
-- ============================================================================

PRINT '=================================================================';
PRINT 'SCENARIO 4: SELECTIVE COLUMN RESTORATION';
PRINT '=================================================================';
PRINT '';

PRINT 'Goal: Restore only Price column, keep other changes';
PRINT '';

-- Make mixed changes
PRINT 'Making changes to multiple columns...';
UPDATE Products 
SET Price = 1.00, 
    StockQuantity = 999,
    Supplier = 'BadSupplier'
WHERE ProductID = 1;

PRINT '  Changed product 1: price=$1.00, stock=999, supplier=BadSupplier';
PRINT '';

WAITFOR DELAY '00:00:01';

PRINT 'Current state:';
SELECT ProductID, ProductName, Price, StockQuantity, Supplier
FROM Products
WHERE ProductID = 1;

PRINT '';

-- Restore only Price column from history
PRINT 'Restoring ONLY the Price column from history...';
PRINT '(Keep the bad stock and supplier values for demo)';

ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);

UPDATE p
SET p.Price = h.Price  -- Only restore price!
FROM Products p
JOIN (
    SELECT ProductID, Price
    FROM ProductsHistory
    WHERE ProductID = 1
    AND ValidTo = (SELECT MAX(ValidTo) FROM ProductsHistory WHERE ProductID = 1)
) h ON p.ProductID = h.ProductID;

ALTER TABLE Products SET (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
);

PRINT '  ✓ Price column restored, other columns unchanged';
PRINT '';

PRINT 'State after selective restoration:';
SELECT 
    ProductID, 
    ProductName, 
    Price AS RestoredPrice, 
    StockQuantity AS KeptBadValue, 
    Supplier AS AlsoKeptBadValue
FROM Products
WHERE ProductID = 1;

PRINT '';
PRINT '✓ SCENARIO 4 COMPLETE: Selective column restoration!';
PRINT '';

-- ============================================================================
-- SCENARIO 5: Batch Restoration Procedure
-- ============================================================================

PRINT '=================================================================';
PRINT 'SCENARIO 5: AUTOMATED RESTORATION PROCEDURE';
PRINT '=================================================================';
PRINT '';

CREATE OR ALTER PROCEDURE sp_RestoreProductToPointInTime
    @product_id INT,
    @restore_datetime DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '─────────────────────────────────────────────────────────────';
    PRINT 'Restoring ProductID ' + CAST(@product_id AS VARCHAR(10));
    PRINT 'To state as of: ' + CAST(@restore_datetime AS VARCHAR(30));
    PRINT '─────────────────────────────────────────────────────────────';
    
    -- Verify product exists in history at that time
    IF NOT EXISTS (
        SELECT 1 
        FROM Products FOR SYSTEM_TIME AS OF @restore_datetime
        WHERE ProductID = @product_id
    )
    BEGIN
        PRINT '✗ ERROR: Product did not exist at specified time';
        RETURN;
    END
    
    BEGIN TRY
        -- Show current state
        PRINT 'Current state:';
        SELECT ProductID, ProductName, Price, StockQuantity
        FROM Products
        WHERE ProductID = @product_id;
        
        -- Show target state
        PRINT '';
        PRINT 'Target state (from history):';
        SELECT ProductID, ProductName, Price, StockQuantity
        FROM Products FOR SYSTEM_TIME AS OF @restore_datetime
        WHERE ProductID = @product_id;
        
        -- Disable versioning
        ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF);
        
        -- Perform restoration
        UPDATE p
        SET 
            p.ProductName = h.ProductName,
            p.Category = h.Category,
            p.Price = h.Price,
            p.StockQuantity = h.StockQuantity,
            p.Supplier = h.Supplier,
            p.ModifiedBy = 'RESTORED-' + SYSTEM_USER
        FROM Products p
        JOIN (
            SELECT * 
            FROM Products FOR SYSTEM_TIME AS OF @restore_datetime
        ) h ON p.ProductID = h.ProductID
        WHERE p.ProductID = @product_id;
        
        -- Re-enable versioning
        ALTER TABLE Products SET (
            SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
        );
        
        PRINT '';
        PRINT '✓ Restoration complete!';
        
        -- Show final state
        PRINT '';
        PRINT 'Final state:';
        SELECT ProductID, ProductName, Price, StockQuantity, ModifiedBy
        FROM Products
        WHERE ProductID = @product_id;
        
    END TRY
    BEGIN CATCH
        -- Re-enable versioning if error
        IF EXISTS (
            SELECT 1 FROM sys.tables 
            WHERE name = 'Products' AND temporal_type = 0
        )
        BEGIN
            ALTER TABLE Products SET (
                SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ProductsHistory)
            );
        END
        
        PRINT '✗ ERROR: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT '✓ Created sp_RestoreProductToPointInTime procedure';
PRINT '';

-- Test the procedure
PRINT 'Testing automated restoration procedure...';
PRINT '';

DECLARE @five_sec_ago DATETIME2 = DATEADD(SECOND, -5, SYSDATETIME());
EXEC sp_RestoreProductToPointInTime @product_id = 1, @restore_datetime = @five_sec_ago;

PRINT '';
PRINT '=================================================================';
PRINT 'ALL RESTORATION SCENARIOS COMPLETE!';
PRINT '=================================================================';

/*
============================================================================
DATA RESTORATION SUMMARY
============================================================================

✅ SCENARIOS DEMONSTRATED:

1. Accidental Deletion Recovery
   - Find deleted row in history
   - Restore with last known values
   - Preserve audit trail

2. Bad Bulk Update Rollback
   - Identify corrupted data
   - Compare with history
   - Restore to previous state

3. Point-in-Time Restoration
   - Restore entire table to specific datetime
   - "Rewind" to known good state

4. Selective Column Restoration
   - Restore only specific columns
   - Keep other changes intact

5. Automated Restoration Procedure
   - Reusable stored procedure
   - Error handling
   - Verification steps

RESTORATION PROCESS:

1. ⚠️ Disable System Versioning
   ALTER TABLE Products SET (SYSTEM_VERSIONING = OFF)

2. 🔍 Query History
   SELECT * FROM Products FOR SYSTEM_TIME AS OF @datetime

3. 🔧 Restore Data
   UPDATE/INSERT/DELETE as needed

4. ✅ Re-enable System Versioning
   ALTER TABLE Products SET (SYSTEM_VERSIONING = ON (...))

5. ✓ Verify Restoration
   Compare before/after states

BEST PRACTICES:

✅ Always test restoration in dev environment first
✅ Document what was restored and why
✅ Verify data integrity after restoration
✅ Consider creating backup before major restoration
✅ Use transactions for multi-table restorations

❌ Don't truncate history table (permanent data loss!)
❌ Don't restore without understanding root cause
❌ Don't forget to re-enable system versioning
❌ Don't restore directly to production without testing

PRODUCTION CONSIDERATIONS:

1. Maintenance Window
   - Restoration requires exclusive access
   - Plan during low-traffic period

2. Backup First
   - Create backup before major restoration
   - Test restoration procedure

3. Change Control
   - Document restoration in change log
   - Notify stakeholders

4. Root Cause Analysis
   - Why did data corruption occur?
   - Prevent future incidents

NEXT STEPS:

Phase 3: Trigger-based CDC for complete control!

============================================================================
*/
