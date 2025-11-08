-- ============================================================================
-- Lesson 08: Data Deletion
-- ============================================================================
-- Learn: DELETE statement, TRUNCATE TABLE
-- Prerequisites: Lesson 06 completed (data inserted)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- DELETE Single Row
-- ============================================================================

-- Delete a specific product
DELETE FROM Inventory.Products
WHERE ProductID = 1;

-- Verify
SELECT * FROM Inventory.Products;

-- ============================================================================
-- DELETE Multiple Rows
-- ============================================================================

-- Delete all discontinued products
DELETE FROM Inventory.Products
WHERE Discontinued = 1;

SELECT * FROM Inventory.Products;

-- ============================================================================
-- DELETE with Subquery
-- ============================================================================

-- Delete orders with no details (orphaned orders)
-- First, let's see if any exist
SELECT * FROM Sales.Orders 
WHERE OrderID NOT IN (SELECT OrderID FROM Sales.OrderDetails);

-- ============================================================================
-- TRUNCATE TABLE (removes all rows, faster than DELETE)
-- ============================================================================

-- Create a temporary table to demonstrate
CREATE TABLE #TempDemo (ID INT, Name NVARCHAR(50));
INSERT INTO #TempDemo VALUES (1, 'Test');

-- Remove all data
TRUNCATE TABLE #TempDemo;

SELECT * FROM #TempDemo;  -- Empty

DROP TABLE #TempDemo;
GO

-- WARNING: Always use WHERE clause with DELETE to avoid deleting all rows!
-- DELETE FROM TableName;  -- This deletes EVERYTHING (no WHERE clause)
