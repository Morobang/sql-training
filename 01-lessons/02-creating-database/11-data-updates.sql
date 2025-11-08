-- ============================================================================
-- Lesson 11: Data Updates (UPDATE)
-- ============================================================================
-- Learn to modify existing data in RetailStore tables
-- Prerequisites: Lessons 01-02, 09 (Database, tables, and data created)

USE RetailStore;
GO

PRINT 'Lesson 11: Data Updates (UPDATE)';
PRINT '================================';
PRINT '';
PRINT 'Modify existing data in RetailStore tables';
PRINT 'WARNING: Always use WHERE clause to avoid updating ALL rows!';
PRINT '';

-- ============================================================================
-- Concept 1: UPDATE Single Column
-- ============================================================================

PRINT 'Concept 1: UPDATE Single Column';
PRINT '-------------------------------';
PRINT '';

-- Check current price
SELECT ProductName, Price FROM Inventory.Products WHERE ProductID = 1;

-- Update laptop price
UPDATE Inventory.Products
SET Price = 899.99
WHERE ProductID = 1;

-- Verify update
SELECT ProductName, Price FROM Inventory.Products WHERE ProductID = 1;
PRINT '';

-- ============================================================================
-- Concept 2: UPDATE Multiple Columns
-- ============================================================================

PRINT 'Concept 2: UPDATE Multiple Columns';
PRINT '----------------------------------';
PRINT '';

-- Update product with multiple changes
UPDATE Inventory.Products
SET 
    Price = 949.99,
    QuantityInStock = 20,
    ReorderLevel = 8
WHERE ProductID = 1;

SELECT ProductName, Price, QuantityInStock, ReorderLevel 
FROM Inventory.Products WHERE ProductID = 1;
PRINT '';

-- ============================================================================
-- Concept 3: UPDATE with Calculations
-- ============================================================================

PRINT 'Concept 3: UPDATE with Calculations';
PRINT '-----------------------------------';
PRINT 'Increase all Electronics prices by 10%';
PRINT '';

-- Check before
SELECT ProductName, Price 
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Increase Electronics prices by 10%
UPDATE p
SET Price = Price * 1.10
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';

-- Check after
SELECT ProductName, Price 
FROM Inventory.Products p
JOIN Inventory.Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName = 'Electronics';
PRINT '';

-- ============================================================================
-- Concept 4: UPDATE with WHERE Conditions
-- ============================================================================

PRINT 'Concept 4: UPDATE with WHERE Conditions';
PRINT '---------------------------------------';
PRINT 'Update only rows matching specific criteria';
PRINT '';

-- Increase stock for low-stock items
UPDATE Inventory.Products
SET QuantityInStock = QuantityInStock + 50
WHERE QuantityInStock < ReorderLevel;

SELECT ProductName, QuantityInStock, ReorderLevel
FROM Inventory.Products
WHERE QuantityInStock < ReorderLevel + 50;
PRINT '';

-- ============================================================================
-- Concept 5: UPDATE with OUTPUT Clause
-- ============================================================================

PRINT 'Concept 5: OUTPUT Clause (See What Changed)';
PRINT '-------------------------------------------';
PRINT '';

-- Update order status and see changes
UPDATE Sales.Orders
SET Status = 'Delivered'
OUTPUT 
    deleted.OrderID,
    deleted.Status AS OldStatus,
    inserted.Status AS NewStatus
WHERE Status = 'Shipped';

PRINT '';

-- ============================================================================
-- Concept 6: UPDATE Best Practices
-- ============================================================================

PRINT 'Concept 6: UPDATE Best Practices';
PRINT '--------------------------------';
PRINT '';

-- BEST PRACTICE 1: Always SELECT first!
PRINT 'PRACTICE 1: SELECT first to verify which rows will be updated';
SELECT CustomerID, FirstName, LastName, City
FROM Sales.Customers
WHERE City = 'Seattle';

-- Then UPDATE
UPDATE Sales.Customers
SET City = 'Seattle',
    State = 'WA'
WHERE City = 'Seattle';

PRINT '';

-- BEST PRACTICE 2: Use transactions for safety
PRINT 'PRACTICE 2: Use transactions for important updates';
BEGIN TRANSACTION;

UPDATE Inventory.Products
SET Price = Price * 0.90  -- 10% discount
WHERE CategoryID = 3;  -- Stationery

-- Check if correct
SELECT ProductName, Price FROM Inventory.Products WHERE CategoryID = 3;

-- If good: COMMIT; If bad: ROLLBACK;
ROLLBACK;  -- Undo the changes
PRINT 'Changes rolled back (demo purposes)';
PRINT '';

-- ============================================================================
-- PRACTICE EXERCISES
-- ============================================================================

PRINT '';
PRINT 'Practice Exercises';
PRINT '==================';
PRINT '';
PRINT 'Exercise 1: Update a specific customer email address';
PRINT 'Exercise 2: Give all employees in Sales department a 5% raise';
PRINT 'Exercise 3: Mark products with 0 stock as discontinued';
PRINT 'Exercise 4: Update all Pending orders to Processing status';
PRINT '';

-- SOLUTIONS (uncomment to run):
/*
-- Exercise 1
UPDATE Sales.Customers
SET Email = 'alice.johnson@newemail.com'
WHERE CustomerID = 1001;

SELECT FirstName, LastName, Email FROM Sales.Customers WHERE CustomerID = 1001;

-- Exercise 2
UPDATE e
SET Salary = Salary * 1.05
FROM HR.Employees e
JOIN HR.Departments d ON e.DepartmentID = d.DepartmentID
WHERE d.DepartmentName = 'Sales';

SELECT FirstName, LastName, Salary 
FROM HR.Employees e
JOIN HR.Departments d ON e.DepartmentID = d.DepartmentID
WHERE d.DepartmentName = 'Sales';

-- Exercise 3
UPDATE Inventory.Products
SET Discontinued = 1
WHERE QuantityInStock = 0;

SELECT ProductName, QuantityInStock, Discontinued 
FROM Inventory.Products
WHERE Discontinued = 1;

-- Exercise 4
UPDATE Sales.Orders
SET Status = 'Processing'
OUTPUT 
    inserted.OrderID,
    deleted.Status AS OldStatus,
    inserted.Status AS NewStatus
WHERE Status = 'Pending';
*/

PRINT '';
PRINT '====================================';
PRINT '✓ Lesson 11 Complete!';
PRINT '====================================';
PRINT '';
PRINT 'Key Takeaways:';
PRINT '  ✓ UPDATE tablename SET column = value WHERE condition';
PRINT '  ✓ ALWAYS use WHERE clause (or update ALL rows!)';
PRINT '  ✓ Can update multiple columns at once';
PRINT '  ✓ Can use calculations (Price = Price * 1.10)';
PRINT '  ✓ OUTPUT clause shows what changed';
PRINT '  ✓ SELECT first to verify which rows will update';
PRINT '  ✓ Use transactions for safety (BEGIN TRAN, COMMIT, ROLLBACK)';
PRINT '';
PRINT 'Next: Lesson 12 - DELETE (Removing Data)';
PRINT '';
