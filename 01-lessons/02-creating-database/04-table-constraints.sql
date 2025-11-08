-- ============================================================================
-- Lesson 04: Table Constraints
-- ============================================================================
-- Learn: NOT NULL, UNIQUE, CHECK, DEFAULT, FOREIGN KEY
-- Prerequisites: Lesson 02 completed (all tables created)
-- ============================================================================

USE RetailStore;
GO

-- ============================================================================
-- NOT NULL Constraint
-- ============================================================================

-- Prevents empty values
-- Example: ProductName cannot be NULL
INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
VALUES ('Test Product', 1, 9.99);  -- OK

-- This would fail:
-- INSERT INTO Inventory.Products (CategoryID, Price) VALUES (1, 9.99);
-- Error: ProductName is required

-- ============================================================================
-- UNIQUE Constraint
-- ============================================================================

-- Prevents duplicate values
-- Example: Email must be unique in Customers table

INSERT INTO Sales.Customers (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@test.com');  -- OK

-- This would fail (duplicate email):
-- INSERT INTO Sales.Customers (FirstName, LastName, Email)
-- VALUES ('Jane', 'Doe', 'john@test.com');

-- Clean up
DELETE FROM Sales.Customers WHERE Email = 'john@test.com';

-- ============================================================================
-- CHECK Constraint
-- ============================================================================

-- Validates data
-- Example: Price must be >= 0

INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
VALUES ('Valid Product', 1, 19.99);  -- OK

-- This would fail (negative price):
-- INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
-- VALUES ('Invalid Product', 1, -10);

-- Clean up
DELETE FROM Inventory.Products WHERE ProductName LIKE 'Test%' OR ProductName LIKE 'Valid%';

-- ============================================================================
-- DEFAULT Constraint
-- ============================================================================

-- Provides automatic values
-- Example: Country defaults to 'USA'

INSERT INTO Sales.Customers (FirstName, LastName, Email)
VALUES ('Jane', 'Smith', 'jane@test.com');

SELECT FirstName, LastName, Country FROM Sales.Customers WHERE Email = 'jane@test.com';
-- Country will be 'USA' automatically

DELETE FROM Sales.Customers WHERE Email = 'jane@test.com';

-- ============================================================================
-- FOREIGN KEY Constraint
-- ============================================================================

-- Enforces relationships
-- Example: Products.CategoryID must exist in Categories

-- This would fail (CategoryID 999 doesn't exist):
-- INSERT INTO Inventory.Products (ProductName, CategoryID, Price)
-- VALUES ('Orphan Product', 999, 10);

-- Must insert valid CategoryID
SELECT CategoryID, CategoryName FROM Inventory.Categories;
GO
