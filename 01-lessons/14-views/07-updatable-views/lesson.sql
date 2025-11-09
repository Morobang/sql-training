/*
================================================================================
LESSON 14.7: UPDATABLE VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand when views are updatable
2. Know the rules and restrictions for updatable views
3. Use WITH CHECK OPTION to enforce constraints
4. Handle single-table vs multi-table views
5. Understand INSTEAD OF triggers for complex updates
6. Apply best practices for updatable views
7. Troubleshoot common update issues

Business Context:
-----------------
Updatable views allow users to modify data through a simplified interface
without direct table access. This maintains security and abstraction while
enabling data modifications. Understanding when views are updatable is
critical for database design and application development.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 35 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: UPDATABLE VIEW FUNDAMENTALS
================================================================================

Not all views can be updated. SQL Server determines if a view is updatable
based on the view definition.

RULES FOR UPDATABLE VIEWS:
---------------------------
✓ SELECT from single base table
✓ No DISTINCT
✓ No GROUP BY or HAVING
✓ No aggregate functions (SUM, COUNT, etc.)
✓ No UNION, INTERSECT, EXCEPT
✓ No TOP clause (in some cases)
✓ All NOT NULL columns included (for INSERT)
✓ No derived columns (for UPDATE/INSERT)

*/

-- Create sample tables
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Category;
GO

CREATE TABLE Category (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL
);

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES Category(CategoryID),
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE)
);
GO

INSERT INTO Category VALUES (1, 'Electronics'), (2, 'Clothing'), (3, 'Books');

INSERT INTO Product (ProductName, CategoryID, Price, Quantity, IsActive)
VALUES 
    ('Laptop', 1, 999.99, 50, 1),
    ('Mouse', 1, 29.99, 200, 1),
    ('T-Shirt', 2, 19.99, 150, 1),
    ('Novel', 3, 14.99, 75, 1),
    ('Old Product', 1, 9.99, 0, 0);
GO

/*
================================================================================
PART 2: SIMPLE UPDATABLE VIEWS
================================================================================

Views that select from a single table without complex operations.
*/

-- Example 1: Simple updatable view
CREATE VIEW ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    Quantity
FROM Product
WHERE IsActive = 1;
GO

-- This view IS updatable
SELECT * FROM ActiveProducts;
GO

-- UPDATE through view
UPDATE ActiveProducts
SET Price = Price * 1.10  -- 10% price increase
WHERE ProductID = 1;
GO

SELECT ProductID, ProductName, Price FROM ActiveProducts WHERE ProductID = 1;
GO

/*
OUTPUT:
ProductID  ProductName  Price
---------  -----------  -------
1          Laptop       1099.99

Price updated successfully through view!
*/

-- INSERT through view
INSERT INTO ActiveProducts (ProductName, CategoryID, Price, Quantity)
VALUES ('New Keyboard', 1, 79.99, 100);
GO

SELECT * FROM ActiveProducts WHERE ProductName = 'New Keyboard';
GO

/*
OUTPUT:
ProductID  ProductName    CategoryID  Price  Quantity
---------  -------------  ----------  -----  --------
6          New Keyboard   1           79.99  100

Inserted through view!
Note: IsActive defaults to 1, so it appears in view
*/

-- DELETE through view
DELETE FROM ActiveProducts WHERE ProductID = 6;
GO

PRINT 'Row deleted through view';
GO

/*
================================================================================
PART 3: WITH CHECK OPTION
================================================================================

WITH CHECK OPTION ensures that modifications through the view don't
violate the view's WHERE clause.
*/

-- Recreate view WITH CHECK OPTION
ALTER VIEW ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    Quantity,
    IsActive
FROM Product
WHERE IsActive = 1
WITH CHECK OPTION;  -- Enforce filter
GO

-- This UPDATE works (keeps IsActive = 1)
UPDATE ActiveProducts
SET Price = 999.99
WHERE ProductID = 1;
GO

-- This UPDATE fails (would set IsActive = 0, violating view filter)
BEGIN TRY
    UPDATE ActiveProducts
    SET IsActive = 0
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'WITH CHECK OPTION prevents updates that violate WHERE clause';
END CATCH;
GO

/*
OUTPUT:
ERROR: The attempted insert or update failed because the target view either specifies WITH CHECK OPTION...
WITH CHECK OPTION prevents updates that violate WHERE clause

EXPLANATION: Cannot update IsActive to 0 because that would make the row
disappear from the view (WHERE IsActive = 1).
*/

-- This INSERT fails (would insert inactive product)
BEGIN TRY
    INSERT INTO ActiveProducts (ProductName, CategoryID, Price, Quantity, IsActive)
    VALUES ('Inactive Product', 1, 9.99, 10, 0);  -- IsActive = 0
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'Cannot insert inactive product into ActiveProducts view';
END CATCH;
GO

-- This INSERT works (IsActive = 1)
INSERT INTO ActiveProducts (ProductName, CategoryID, Price, Quantity, IsActive)
VALUES ('Valid Product', 1, 49.99, 25, 1);
GO

SELECT * FROM ActiveProducts WHERE ProductName = 'Valid Product';
GO

/*
================================================================================
PART 4: NON-UPDATABLE VIEWS
================================================================================

Views with certain characteristics cannot be updated directly.
*/

-- Example 1: View with JOIN (NOT directly updatable)
CREATE VIEW ProductWithCategory AS
SELECT 
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.Price,
    p.Quantity
FROM Product p
INNER JOIN Category c ON p.CategoryID = c.CategoryID;
GO

-- Attempt to update (works for Product columns, not Category columns)
UPDATE ProductWithCategory
SET Price = 899.99
WHERE ProductID = 1;  -- This works (updates Product table)
GO

BEGIN TRY
    UPDATE ProductWithCategory
    SET CategoryName = 'New Category'  -- This fails
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot update columns from joined table through view';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Example 2: View with GROUP BY (NOT updatable)
CREATE VIEW ProductCountByCategory AS
SELECT 
    CategoryID,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Product
GROUP BY CategoryID;
GO

-- Cannot update aggregate view
BEGIN TRY
    UPDATE ProductCountByCategory
    SET AvgPrice = 100
    WHERE CategoryID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot update view with GROUP BY';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Example 3: View with DISTINCT (NOT updatable)
CREATE VIEW DistinctCategories AS
SELECT DISTINCT CategoryID
FROM Product;
GO

-- Cannot update DISTINCT view
BEGIN TRY
    UPDATE DistinctCategories
    SET CategoryID = 5
    WHERE CategoryID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot update view with DISTINCT';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

/*
================================================================================
PART 5: INSTEAD OF TRIGGERS
================================================================================

For non-updatable views, use INSTEAD OF triggers to define custom logic.
*/

-- Example: Make ProductWithCategory updatable with trigger
CREATE TRIGGER trg_UpdateProductWithCategory
ON ProductWithCategory
INSTEAD OF UPDATE AS
BEGIN
    -- Custom update logic
    UPDATE p
    SET 
        p.ProductName = i.ProductName,
        p.Price = i.Price,
        p.Quantity = i.Quantity
    FROM Product p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    PRINT 'Updated through INSTEAD OF trigger';
END;
GO

-- Now can update through view
UPDATE ProductWithCategory
SET Price = 949.99, Quantity = 45
WHERE ProductID = 1;
GO

SELECT ProductID, ProductName, Price, Quantity 
FROM ProductWithCategory 
WHERE ProductID = 1;
GO

/*
OUTPUT:
Updated through INSTEAD OF trigger
ProductID  ProductName  Price    Quantity
---------  -----------  -------  --------
1          Laptop       949.99   45

Update worked via INSTEAD OF trigger!
*/

-- INSTEAD OF INSERT trigger
CREATE TRIGGER trg_InsertProductWithCategory
ON ProductWithCategory
INSTEAD OF INSERT AS
BEGIN
    INSERT INTO Product (ProductName, CategoryID, Price, Quantity)
    SELECT 
        i.ProductName,
        c.CategoryID,
        i.Price,
        i.Quantity
    FROM inserted i
    INNER JOIN Category c ON i.CategoryName = c.CategoryName;
    
    PRINT 'Inserted through INSTEAD OF trigger';
END;
GO

-- Insert with category name (trigger looks up CategoryID)
INSERT INTO ProductWithCategory (ProductName, CategoryName, Price, Quantity)
VALUES ('Headphones', 'Electronics', 149.99, 50);
GO

/*
OUTPUT:
Inserted through INSTEAD OF trigger
*/

/*
================================================================================
PART 6: RESTRICTIONS AND LIMITATIONS
================================================================================
*/

-- Restriction 1: Cannot update computed columns
CREATE VIEW ProductWithMarkup AS
SELECT 
    ProductID,
    ProductName,
    Price,
    Price * 1.20 AS PriceWithMarkup  -- Computed column
FROM Product;
GO

BEGIN TRY
    UPDATE ProductWithMarkup
    SET PriceWithMarkup = 1200  -- Cannot update computed column
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot update computed column';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- But can update base column
UPDATE ProductWithMarkup
SET Price = 1000  -- This works
WHERE ProductID = 1;
GO

-- Restriction 2: Cannot INSERT if view doesn't include all NOT NULL columns
CREATE VIEW ProductBasicInfo AS
SELECT 
    ProductID,
    ProductName,
    Price
    -- CategoryID (NOT NULL) not included
FROM Product;
GO

BEGIN TRY
    INSERT INTO ProductBasicInfo (ProductName, Price)
    VALUES ('Invalid Product', 99.99);  -- Missing CategoryID
END TRY
BEGIN CATCH
    PRINT 'ERROR: Missing required column CategoryID';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

/*
================================================================================
PART 7: BEST PRACTICES
================================================================================
*/

-- Practice 1: Always use WITH CHECK OPTION for filtered views
CREATE VIEW ExpensiveProducts AS
SELECT 
    ProductID,
    ProductName,
    Price,
    Quantity
FROM Product
WHERE Price >= 100
WITH CHECK OPTION;  -- Ensures Price stays >= 100
GO

-- This fails (would violate filter)
BEGIN TRY
    UPDATE ExpensiveProducts
    SET Price = 50  -- Below 100
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'WITH CHECK OPTION protected data integrity';
END CATCH;
GO

-- Practice 2: Document updatable views
EXEC sp_addextendedproperty 
    @name = N'MS_Description',
    @value = N'Updatable view for active products only. Uses WITH CHECK OPTION to prevent inactive products.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'VIEW', @level1name = N'ActiveProducts';
GO

-- Practice 3: Test update behavior before deployment
-- Create test script
PRINT 'Testing ActiveProducts view updates...';

BEGIN TRANSACTION;

-- Test UPDATE
UPDATE ActiveProducts SET Price = Price * 1.05 WHERE ProductID = 2;
PRINT 'UPDATE test passed';

-- Test INSERT
INSERT INTO ActiveProducts (ProductName, CategoryID, Price, Quantity, IsActive)
VALUES ('Test Product', 1, 19.99, 10, 1);
PRINT 'INSERT test passed';

-- Test DELETE
DELETE FROM ActiveProducts WHERE ProductName = 'Test Product';
PRINT 'DELETE test passed';

ROLLBACK TRANSACTION;
PRINT 'All tests completed (rolled back)';
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Create Updatable View
----------------------------------
Create a view showing products with Quantity > 0 (in stock).
Use WITH CHECK OPTION to prevent quantity from going negative.
Test INSERT, UPDATE, DELETE operations.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Handle Non-Updatable View
--------------------------------------
Create a view joining Product and Category.
Create INSTEAD OF triggers to make it updatable.
Test updates to both Product and Category data.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Complex Validation
-------------------------------
Create a view for products priced between $10 and $1000.
Use WITH CHECK OPTION.
Test boundary conditions ($9.99, $10.00, $1000.00, $1000.01).

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Create Updatable View
CREATE VIEW InStockProducts AS
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    Quantity
FROM Product
WHERE Quantity > 0
WITH CHECK OPTION;
GO

-- Test UPDATE
UPDATE InStockProducts
SET Quantity = Quantity + 10
WHERE ProductID = 1;

SELECT ProductID, ProductName, Quantity FROM InStockProducts WHERE ProductID = 1;

-- Test INSERT (valid - Quantity > 0)
INSERT INTO InStockProducts (ProductName, CategoryID, Price, Quantity)
VALUES ('In Stock Item', 1, 29.99, 5);

-- Test INSERT (invalid - Quantity = 0)
BEGIN TRY
    INSERT INTO InStockProducts (ProductName, CategoryID, Price, Quantity)
    VALUES ('Out of Stock Item', 1, 29.99, 0);
END TRY
BEGIN CATCH
    PRINT 'Correctly prevented inserting out-of-stock product';
END CATCH;

-- Test UPDATE (invalid - would set Quantity = 0)
BEGIN TRY
    UPDATE InStockProducts
    SET Quantity = 0
    WHERE ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'Correctly prevented setting Quantity to 0';
END CATCH;

-- Test DELETE
DELETE FROM InStockProducts WHERE ProductName = 'In Stock Item';
GO

-- Solution 2: Handle Non-Updatable View
CREATE VIEW ProductCategoryView AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    c.CategoryName,
    p.Price,
    p.Quantity
FROM Product p
INNER JOIN Category c ON p.CategoryID = c.CategoryID;
GO

-- INSTEAD OF UPDATE trigger
CREATE TRIGGER trg_UpdateProductCategoryView
ON ProductCategoryView
INSTEAD OF UPDATE AS
BEGIN
    -- Update Product table
    UPDATE p
    SET 
        p.ProductName = i.ProductName,
        p.Price = i.Price,
        p.Quantity = i.Quantity,
        p.CategoryID = i.CategoryID
    FROM Product p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    -- Note: Not updating Category table (would require more complex logic)
    PRINT 'Product updated via trigger';
END;
GO

-- Test update
UPDATE ProductCategoryView
SET Price = 899.99, Quantity = 40
WHERE ProductID = 1;

SELECT * FROM ProductCategoryView WHERE ProductID = 1;
GO

-- Solution 3: Complex Validation
CREATE VIEW ReasonablyPricedProducts AS
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    Price,
    Quantity
FROM Product
WHERE Price >= 10.00 AND Price <= 1000.00
WITH CHECK OPTION;
GO

-- Test boundary: $9.99 (invalid)
BEGIN TRY
    INSERT INTO ReasonablyPricedProducts (ProductName, CategoryID, Price, Quantity)
    VALUES ('Too Cheap', 1, 9.99, 10);
END TRY
BEGIN CATCH
    PRINT 'Correctly rejected $9.99 (below minimum)';
END CATCH;

-- Test boundary: $10.00 (valid)
INSERT INTO ReasonablyPricedProducts (ProductName, CategoryID, Price, Quantity)
VALUES ('Minimum Price', 1, 10.00, 10);
PRINT 'Accepted $10.00 (at minimum)';

-- Test boundary: $1000.00 (valid)
INSERT INTO ReasonablyPricedProducts (ProductName, CategoryID, Price, Quantity)
VALUES ('Maximum Price', 1, 1000.00, 5);
PRINT 'Accepted $1000.00 (at maximum)';

-- Test boundary: $1000.01 (invalid)
BEGIN TRY
    INSERT INTO ReasonablyPricedProducts (ProductName, CategoryID, Price, Quantity)
    VALUES ('Too Expensive', 1, 1000.01, 3);
END TRY
BEGIN CATCH
    PRINT 'Correctly rejected $1000.01 (above maximum)';
END CATCH;

-- Cleanup
DELETE FROM ReasonablyPricedProducts WHERE ProductName IN ('Minimum Price', 'Maximum Price');
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. UPDATABLE VIEW RULES
   - Single table (no JOINs for direct updates)
   - No DISTINCT, GROUP BY, or aggregates
   - No UNION or set operations
   - Include all NOT NULL columns for INSERT

2. WITH CHECK OPTION
   - Enforces view's WHERE clause on modifications
   - Prevents updates that violate filter
   - Essential for data integrity
   - Use on all filtered updatable views

3. INSTEAD OF TRIGGERS
   - Make non-updatable views updatable
   - Define custom update logic
   - Handle complex scenarios (JOINs, aggregates)
   - Can INSERT, UPDATE, DELETE

4. RESTRICTIONS
   - Cannot update computed columns
   - Cannot update aggregate results
   - Cannot update DISTINCT views
   - Must include required columns for INSERT

5. SINGLE TABLE VIEWS
   - Fully updatable (INSERT, UPDATE, DELETE)
   - Direct pass-through to base table
   - WITH CHECK OPTION recommended
   - Simplest and most reliable

6. MULTI-TABLE VIEWS
   - Limited updatability
   - Can update one table at a time
   - INSTEAD OF triggers for full control
   - More complex to manage

7. BEST PRACTICES
   - Always use WITH CHECK OPTION on filtered views
   - Test all DML operations (INSERT, UPDATE, DELETE)
   - Document updatable views
   - Use INSTEAD OF triggers for complex views
   - Validate data integrity
   - Consider security implications

8. WHEN TO USE
   - Simplify data modification interface
   - Enforce business rules via views
   - Provide abstraction layer
   - Control what users can modify
   - Maintain backward compatibility

================================================================================

NEXT STEPS:
-----------
In Lesson 14.8, we'll explore UPDATING SIMPLE VIEWS:
- Detailed INSERT examples
- UPDATE patterns and best practices
- DELETE operations through views
- Practical real-world scenarios

Continue to: 08-updating-simple-views/lesson.sql

================================================================================
*/
