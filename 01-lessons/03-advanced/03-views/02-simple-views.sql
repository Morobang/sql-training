-- ========================================
-- Simple Views: Single Table
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Basic View - Active Products
-- =============================================

-- Drop existing views if they exist
DROP VIEW IF EXISTS vw_ActiveProducts;
DROP VIEW IF EXISTS vw_ProductProfitMargin;
DROP VIEW IF EXISTS vw_CustomerPublicInfo;
DROP VIEW IF EXISTS vw_HighValueCustomers;
DROP VIEW IF EXISTS vw_ProductInventory;
DROP VIEW IF EXISTS vw_Top10ExpensiveProducts;
DROP VIEW IF EXISTS vw_ProductPrices;
DROP VIEW IF EXISTS vw_AffordableProducts;
GO

CREATE VIEW vw_ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    StockQuantity
FROM Products
WHERE IsActive = 1;
GO

-- Query the view like a table
SELECT * FROM vw_ActiveProducts;

SELECT * FROM vw_ActiveProducts WHERE Category = 'Electronics';

SELECT Category, COUNT(*) AS ProductCount
FROM vw_ActiveProducts
GROUP BY Category;

-- =============================================
-- Example 2: View with Calculated Columns
-- =============================================

CREATE VIEW vw_ProductProfitMargin AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    Cost,
    Price - Cost AS Profit,
    CASE 
        WHEN Cost > 0 THEN CAST((Price - Cost) * 100.0 / Cost AS DECIMAL(5,2))
        ELSE 0
    END AS ProfitMarginPercent
FROM Products
WHERE IsActive = 1;
GO

SELECT * FROM vw_ProductProfitMargin
WHERE ProfitMarginPercent > 30
ORDER BY ProfitMarginPercent DESC;

-- =============================================
-- Example 3: Security View - Customer Public Info
-- =============================================

-- Hide sensitive customer data
CREATE VIEW vw_CustomerPublicInfo AS
SELECT 
    CustomerID,
    CustomerName,
    City,
    State
    -- Excludes: email, phone, SSN, payment info
FROM Customers;
GO

-- Safe to expose to reports/applications
SELECT * FROM vw_CustomerPublicInfo
WHERE State = 'CA';

-- =============================================
-- Example 4: Filtered View with Specific Criteria
-- =============================================

CREATE VIEW vw_HighValueCustomers AS
SELECT 
    CustomerID,
    CustomerName,
    State,
    TotalPurchases
FROM Customers
WHERE TotalPurchases >= 500;
GO

SELECT * FROM vw_HighValueCustomers
ORDER BY TotalPurchases DESC;

-- =============================================
-- Example 5: View with Column Aliases
-- =============================================

CREATE VIEW vw_ProductInventory AS
SELECT 
    ProductID AS ID,
    ProductName AS Product,
    Category,
    StockQuantity AS QtyOnHand,
    CASE 
        WHEN StockQuantity = 0 THEN 'OUT OF STOCK'
        WHEN StockQuantity < 10 THEN 'LOW STOCK'
        WHEN StockQuantity < 50 THEN 'ADEQUATE'
        ELSE 'WELL STOCKED'
    END AS StockStatus
FROM Products;
GO

SELECT * FROM vw_ProductInventory
WHERE StockStatus IN ('OUT OF STOCK', 'LOW STOCK')
ORDER BY QtyOnHand;

-- =============================================
-- Example 6: View with TOP
-- =============================================

CREATE VIEW vw_Top10ExpensiveProducts AS
SELECT TOP 10
    ProductID,
    ProductName,
    Category,
    Price
FROM Products
WHERE IsActive = 1
ORDER BY Price DESC;
GO

SELECT * FROM vw_Top10ExpensiveProducts;

-- =============================================
-- Example 7: Updatable Simple View
-- =============================================

-- Create updatable view (single table, no aggregations)
CREATE VIEW vw_ProductPrices AS
SELECT 
    ProductID,
    ProductName,
    Price
FROM Products
WHERE IsActive = 1;
GO

-- View current prices
SELECT * FROM vw_ProductPrices WHERE ProductID = 1;

-- UPDATE through view (allowed for simple views)
UPDATE vw_ProductPrices
SET Price = Price * 1.05
WHERE ProductID = 1;

-- Verify update
SELECT * FROM vw_ProductPrices WHERE ProductID = 1;

-- INSERT through view (if all required columns are in view)
-- INSERT INTO vw_ProductPrices (ProductName, Price) VALUES ('New Product', 99.99);
-- Note: This fails because required columns (Category, Cost, etc.) are missing

-- =============================================
-- Example 8: View with WITH CHECK OPTION
-- =============================================

CREATE VIEW vw_AffordableProducts AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price
FROM Products
WHERE Price <= 500
WITH CHECK OPTION;
GO

-- This UPDATE works (stays within Price <= 500)
UPDATE vw_AffordableProducts
SET Price = 450
WHERE ProductID = 1;

-- This UPDATE fails (violates Price <= 500 constraint)
BEGIN TRY
    UPDATE vw_AffordableProducts
    SET Price = 600
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'WITH CHECK OPTION prevents updates that violate view filter';
END CATCH;

-- =============================================
-- Example 9: View Metadata
-- =============================================

-- Get view definition
EXEC sp_helptext 'vw_ActiveProducts';

-- View information
SELECT 
    TABLE_NAME AS ViewName,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME LIKE 'vw_%'
ORDER BY TABLE_NAME;

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP VIEW IF EXISTS vw_ActiveProducts;
DROP VIEW IF EXISTS vw_ProductProfitMargin;
DROP VIEW IF EXISTS vw_CustomerPublicInfo;
DROP VIEW IF EXISTS vw_HighValueCustomers;
DROP VIEW IF EXISTS vw_ProductInventory;
DROP VIEW IF EXISTS vw_Top10ExpensiveProducts;
DROP VIEW IF EXISTS vw_ProductPrices;
DROP VIEW IF EXISTS vw_AffordableProducts;
*/

-- 💡 Key Points:
-- - Simple views based on single table
-- - Can include WHERE, calculated columns, TOP
-- - Often updatable (INSERT, UPDATE, DELETE allowed)
-- - WITH CHECK OPTION ensures updates satisfy view filter
-- - Use for security, simplification, and data abstraction
-- - Query views exactly like tables
