-- ========================================
-- DELETE Multiple Rows: Remove Inactive Products
-- ========================================

USE TechStore;

-- Before: See inactive products
SELECT * FROM Products WHERE IsActive = 0;

-- Delete all inactive products
DELETE FROM Products
WHERE IsActive = 0;

-- After: Verify inactive products are gone
SELECT * FROM Products WHERE IsActive = 0;
-- (Should return no rows)

-- All remaining products should be active
SELECT * FROM Products;
