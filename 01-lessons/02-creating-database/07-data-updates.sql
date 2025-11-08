-- ============================================================================
-- Lesson 07: Data Updates
-- ============================================================================
-- Learn: UPDATE statement
-- Prerequisites: Lesson 06 completed (data inserted)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- Basic UPDATE
-- ============================================================================

-- Update a single record
UPDATE Inventory.Products
SET Price = 899.99
WHERE ProductID = 1;

-- Verify
SELECT ProductID, ProductName, Price FROM Inventory.Products WHERE ProductID = 1;

-- ============================================================================
-- UPDATE Multiple Columns
-- ============================================================================

UPDATE Inventory.Products
SET Price = 34.99, QuantityInStock = 250
WHERE ProductID = 2;

SELECT ProductID, ProductName, Price, QuantityInStock FROM Inventory.Products WHERE ProductID = 2;

-- ============================================================================
-- UPDATE Multiple Rows
-- ============================================================================

-- Increase all Electronics prices by 10%
UPDATE Inventory.Products
SET Price = Price * 1.10
WHERE CategoryID = 1;

SELECT ProductName, Price FROM Inventory.Products WHERE CategoryID = 1;

-- ============================================================================
-- UPDATE with Calculations
-- ============================================================================

-- Mark low stock products as discontinued
UPDATE Inventory.Products
SET Discontinued = 1
WHERE QuantityInStock < 40;

SELECT ProductName, QuantityInStock, Discontinued FROM Inventory.Products;
GO
