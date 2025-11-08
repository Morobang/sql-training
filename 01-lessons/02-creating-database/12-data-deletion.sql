-- ============================================================================
-- Lesson 12: Data Deletion (DELETE)
-- ============================================================================
-- Learn to remove data from RetailStore tables
-- Prerequisites: Lessons 01-02, 09 (Database, tables, and data created)

USE RetailStore;
GO

PRINT 'Lesson 12: Data Deletion (DELETE)';
PRINT '=================================';
PRINT '';
PRINT 'Remove data from RetailStore tables';
PRINT 'EXTREME WARNING: DELETE is permanent - always use WHERE clause!';
PRINT '';

-- ============================================================================
-- Concept 1: DELETE with WHERE Clause
-- ============================================================================

PRINT 'Concept 1: DELETE Specific Rows';
PRINT '-------------------------------';
PRINT 'CRITICAL: Always use WHERE clause to delete specific rows';
PRINT '';

-- First, let's add a test customer to delete
INSERT INTO Sales.Customers (FirstName, LastName, Email, City, State) 
VALUES ('Test', 'User', 'test@delete.com', 'TestCity', 'WA');

DECLARE @TestCustomerID INT = SCOPE_IDENTITY();

-- Verify it exists
SELECT * FROM Sales.Customers WHERE CustomerID = @TestCustomerID;

-- Delete the test customer
DELETE FROM Sales.Customers
WHERE CustomerID = @TestCustomerID;

-- Verify deleted
SELECT * FROM Sales.Customers WHERE CustomerID = @TestCustomerID;
PRINT 'Test customer deleted';
PRINT '';

-- ============================================================================
-- Concept 2: DELETE with Multiple Conditions
-- ============================================================================

PRINT 'Concept 2: DELETE with Multiple Conditions';
PRINT '------------------------------------------';
PRINT '';

-- Add test products
INSERT INTO Inventory.Products (ProductName, CategoryID, SKU, Price, Cost, QuantityInStock, Discontinued) VALUES
    ('Test Product 1', 1, 'TEST-001', 10.00, 5.00, 0, 1),
    ('Test Product 2', 1, 'TEST-002', 15.00, 7.00, 0, 1);

-- Delete discontinued products with 0 stock
DELETE FROM Inventory.Products
WHERE Discontinued = 1 AND QuantityInStock = 0 AND SKU LIKE 'TEST%';

PRINT 'Discontinued test products with 0 stock deleted';
PRINT '';

-- ============================================================================
-- Concept 3: DELETE with OUTPUT Clause
-- ============================================================================

PRINT 'Concept 3: OUTPUT Clause (See What Was Deleted)';
PRINT '-----------------------------------------------';
PRINT '';

-- Add test data
INSERT INTO Inventory.Products (ProductName, CategoryID, SKU, Price, Cost, QuantityInStock) 
VALUES ('Temp Item', 1, 'TEMP-001', 5.00, 2.00, 1);

-- Delete and see what was removed
DELETE FROM Inventory.Products
OUTPUT 
    deleted.ProductID,
    deleted.ProductName,
    deleted.Price,
    deleted.QuantityInStock
WHERE SKU = 'TEMP-001';

PRINT '';

-- ============================================================================
-- Concept 4: DELETE vs TRUNCATE
-- ============================================================================

PRINT 'Concept 4: DELETE vs TRUNCATE';
PRINT '-----------------------------';
PRINT '';
PRINT 'DELETE:';
PRINT '  • Removes specific rows (with WHERE)';
PRINT '  • Can be rolled back';
PRINT '  • Slower for large tables';
PRINT '  • Triggers fire';
PRINT '';
PRINT 'TRUNCATE:';
PRINT '  • Removes ALL rows (no WHERE clause)';
PRINT '  • Faster for large tables';
PRINT '  • Resets IDENTITY counter';
PRINT '  • Cannot truncate table with foreign key references';
PRINT '';

-- Example: Create temp table to demonstrate
CREATE TABLE #TempDemo (
    ID INT IDENTITY(1,1),
    Name NVARCHAR(50)
);

INSERT INTO #TempDemo (Name) VALUES ('Item 1'), ('Item 2'), ('Item 3');
SELECT * FROM #TempDemo;

-- TRUNCATE removes all rows and resets IDENTITY
TRUNCATE TABLE #TempDemo;
SELECT * FROM #TempDemo;

INSERT INTO #TempDemo (Name) VALUES ('New Item 1');
SELECT * FROM #TempDemo;  -- ID starts at 1 again

DROP TABLE #TempDemo;
PRINT '';

-- ============================================================================
-- Concept 5: CASCADE DELETE (Foreign Key Relationships)
-- ============================================================================

PRINT 'Concept 5: CASCADE DELETE';
PRINT '------------------------';
PRINT 'When FK has ON DELETE CASCADE, deleting parent deletes children';
PRINT '';
PRINT 'RetailStore Example:';
PRINT '  Sales.OrderDetails has ON DELETE CASCADE';
PRINT '  Deleting an Order automatically deletes its OrderDetails';
PRINT '';

-- Show order with details
SELECT o.OrderID, COUNT(od.OrderDetailID) AS DetailCount
FROM Sales.Orders o
JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
WHERE o.OrderID = 1000
GROUP BY o.OrderID;

-- Delete the order (will CASCADE delete OrderDetails)
DELETE FROM Sales.Orders WHERE OrderID = 1000;

-- Verify OrderDetails also deleted
SELECT * FROM Sales.OrderDetails WHERE OrderID = 1000;
PRINT 'Order 1000 and all its details deleted (CASCADE)';
PRINT '';

-- ============================================================================
-- Concept 6: DELETE Best Practices
-- ============================================================================

PRINT 'Concept 6: DELETE Best Practices';
PRINT '--------------------------------';
PRINT '';

-- PRACTICE 1: Always SELECT first!
PRINT 'PRACTICE 1: SELECT first to verify which rows will be deleted';
SELECT OrderID, Status FROM Sales.Orders WHERE Status = 'Cancelled';

-- Then DELETE (uncomment to execute)
-- DELETE FROM Sales.Orders WHERE Status = 'Cancelled';

PRINT '';

-- PRACTICE 2: Use transactions
PRINT 'PRACTICE 2: Use transactions for safety';
BEGIN TRANSACTION;

DELETE FROM Sales.Orders WHERE Status = 'Cancelled';

-- Check if correct
SELECT COUNT(*) AS CancelledOrders FROM Sales.Orders WHERE Status = 'Cancelled';

-- If good: COMMIT; If bad: ROLLBACK;
ROLLBACK;
PRINT 'Changes rolled back (demo purposes)';
PRINT '';

-- PRACTICE 3: Consider soft deletes instead
PRINT 'PRACTICE 3: Consider "Soft Delete" (marking as deleted instead)';
PRINT '';
PRINT 'Instead of:';
PRINT '  DELETE FROM Customers WHERE CustomerID = 1;';
PRINT '';
PRINT 'Use:';
PRINT '  UPDATE Customers SET IsActive = 0, DeletedDate = GETDATE() WHERE CustomerID = 1;';
PRINT '';
PRINT 'Benefits:';
PRINT '  • Can recover data';
PRINT '  • Maintains referential integrity';
PRINT '  • Audit trail';
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Practice Exercises';
PRINT '==================';
PRINT '';
PRINT 'Exercise 1: Delete all inactive customers (IsActive = 0)';
PRINT 'Exercise 2: Delete products that are discontinued AND have 0 stock';
PRINT 'Exercise 3: Delete orders older than 1 year with status Delivered';
PRINT 'Exercise 4: Soft delete a customer (set IsActive = 0 instead of DELETE)';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
-- Exercise 1 (SELECT first!)
SELECT * FROM Sales.Customers WHERE IsActive = 0;
DELETE FROM Sales.Customers WHERE IsActive = 0;

-- Exercise 2
SELECT * FROM Inventory.Products WHERE Discontinued = 1 AND QuantityInStock = 0;
DELETE FROM Inventory.Products WHERE Discontinued = 1 AND QuantityInStock = 0;

-- Exercise 3
SELECT * FROM Sales.Orders 
WHERE Status = 'Delivered' AND OrderDate < DATEADD(YEAR, -1, GETDATE());

DELETE FROM Sales.Orders 
WHERE Status = 'Delivered' AND OrderDate < DATEADD(YEAR, -1, GETDATE());

-- Exercise 4 (Soft Delete - RECOMMENDED)
UPDATE Sales.Customers
SET IsActive = 0
WHERE CustomerID = 1001;

SELECT * FROM Sales.Customers WHERE CustomerID = 1001;
*/

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 12 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  ✓ DELETE FROM table WHERE condition';
PRINT '  ✓ ALWAYS use WHERE clause (or delete ALL rows!)';
PRINT '  ✓ SELECT first to verify which rows will delete';
PRINT '  ✓ OUTPUT clause shows what was deleted';
PRINT '  ✓ TRUNCATE is faster but removes ALL rows';
PRINT '  ✓ CASCADE DELETE automatically deletes related rows';
PRINT '  ✓ Use transactions for safety';
PRINT '  ✓ Consider soft deletes (IsActive = 0) instead of hard deletes';
PRINT '';
PRINT 'Next: Lesson 13 - Test Your Knowledge (Practice Exercises)';
PRINT '';
