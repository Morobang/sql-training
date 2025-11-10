-- ============================================================================
-- Lesson 05: Table Modification
-- ============================================================================
-- Learn: ALTER TABLE (add, modify, drop columns)
-- Prerequisites: Lesson 02 completed (all tables created)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- Adding Columns
-- ============================================================================

-- Add a new column to Products
ALTER TABLE Inventory.Products
ADD Weight DECIMAL(8,2);

-- Add column with default value
ALTER TABLE Inventory.Products
ADD IsFeatured BIT DEFAULT 0;

SELECT TOP 3 ProductID, ProductName, Weight, IsFeatured 
FROM Inventory.Products;

-- ============================================================================
-- Modifying Columns
-- ============================================================================

-- Change column size
ALTER TABLE Inventory.Suppliers
ALTER COLUMN Phone VARCHAR(30);

-- ============================================================================
-- Dropping Columns
-- ============================================================================

-- Remove columns we added
ALTER TABLE Inventory.Products
DROP COLUMN Weight;

ALTER TABLE Inventory.Products
DROP COLUMN IsFeatured;
GO

-- Verify changes
SELECT TOP 1 * FROM Inventory.Products;
GO
