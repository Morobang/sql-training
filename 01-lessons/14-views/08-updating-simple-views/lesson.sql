/*
================================================================================
LESSON 14.8: UPDATING SIMPLE VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Perform INSERT operations through simple views
2. Execute UPDATE operations through views
3. Perform DELETE operations through views
4. Understand data validation with WITH CHECK OPTION
5. Handle default values in view inserts
6. Troubleshoot common update issues
7. Apply best practices for view modifications

Business Context:
-----------------
Simple updatable views provide a controlled interface for data modification.
They allow you to restrict which columns users can modify while maintaining
data integrity through constraints and validation. This is essential for
security, abstraction, and enforcing business rules.

Database: RetailStore
Complexity: Beginner-Intermediate
Estimated Time: 35 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: INSERT OPERATIONS
================================================================================

INSERTing through a view adds rows to the underlying table.
*/

-- Create base table
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE),
    LastModified DATETIME DEFAULT GETDATE()
);
GO

-- Create simple view
CREATE VIEW ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    Quantity
FROM Product
WHERE IsActive = 1;
GO

-- Example 1: Basic INSERT through view
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
VALUES ('Wireless Mouse', 'Electronics', 29.99, 100);
GO

SELECT * FROM ActiveProducts WHERE ProductName = 'Wireless Mouse';
GO

/*
OUTPUT:
ProductID  ProductName      Category      Price  Quantity
---------  ---------------  ------------  -----  --------
1          Wireless Mouse   Electronics   29.99  100

Successfully inserted through view!
*/

-- Check underlying table (includes hidden columns)
SELECT ProductID, ProductName, IsActive, CreatedDate, LastModified
FROM Product
WHERE ProductName = 'Wireless Mouse';
GO

/*
OUTPUT:
ProductID  ProductName      IsActive  CreatedDate  LastModified
---------  ---------------  --------  -----------  -------------------
1          Wireless Mouse   1         2024-11-09   2024-11-09 10:30:00

Default values applied automatically!
*/

-- Example 2: Multiple row INSERT
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
VALUES 
    ('USB Keyboard', 'Electronics', 49.99, 75),
    ('Laptop Stand', 'Accessories', 39.99, 50),
    ('Monitor', 'Electronics', 299.99, 25);
GO

SELECT ProductID, ProductName, Category, Price FROM ActiveProducts;
GO

/*
OUTPUT:
ProductID  ProductName      Category      Price
---------  ---------------  ------------  -------
1          Wireless Mouse   Electronics   29.99
2          USB Keyboard     Electronics   49.99
3          Laptop Stand     Accessories   39.99
4          Monitor          Electronics   299.99
*/

-- Example 3: INSERT with SELECT
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
SELECT 'Combo: ' + ProductName, Category, Price * 0.9, Quantity
FROM ActiveProducts
WHERE Category = 'Electronics' AND Price < 100;
GO

SELECT ProductName, Price FROM ActiveProducts WHERE ProductName LIKE 'Combo:%';
GO

/*
OUTPUT:
ProductName                  Price
---------------------------  -----
Combo: Wireless Mouse        26.99
Combo: USB Keyboard          44.99

Created combo products!
*/

/*
================================================================================
PART 2: UPDATE OPERATIONS
================================================================================

UPDATE through views modifies the underlying table rows.
*/

-- Example 1: Simple UPDATE
UPDATE ActiveProducts
SET Price = 27.99
WHERE ProductName = 'Wireless Mouse';
GO

SELECT ProductName, Price FROM ActiveProducts WHERE ProductName = 'Wireless Mouse';
GO

/*
OUTPUT:
ProductName      Price
---------------  -----
Wireless Mouse   27.99

Price updated!
*/

-- Example 2: UPDATE with calculations
UPDATE ActiveProducts
SET Price = Price * 1.10  -- 10% price increase
WHERE Category = 'Electronics';
GO

SELECT ProductName, Category, Price 
FROM ActiveProducts 
WHERE Category = 'Electronics'
ORDER BY Price;
GO

/*
OUTPUT:
ProductName              Category      Price
-----------------------  ------------  -------
Combo: Wireless Mouse    Electronics   29.69
Wireless Mouse           Electronics   30.79
Combo: USB Keyboard      Electronics   49.49
USB Keyboard             Electronics   54.99
Monitor                  Electronics   329.99

All electronics prices increased by 10%!
*/

-- Example 3: UPDATE with conditions
UPDATE ActiveProducts
SET Quantity = Quantity - 5
WHERE Quantity >= 50;
GO

SELECT ProductName, Quantity FROM ActiveProducts ORDER BY Quantity;
GO

/*
OUTPUT:
ProductName              Quantity
-----------------------  --------
Monitor                  20
Laptop Stand             45
USB Keyboard             70
Wireless Mouse           95
Combo: USB Keyboard      95
Combo: Wireless Mouse    95

Reduced quantity for products with >= 50 stock!
*/

-- Example 4: UPDATE with JOIN (single-table view)
-- First, add a discount column
ALTER TABLE Product ADD DiscountPct DECIMAL(5,2) DEFAULT 0;
GO

ALTER VIEW ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    Quantity,
    DiscountPct
FROM Product
WHERE IsActive = 1;
GO

-- Apply discounts based on quantity
UPDATE ActiveProducts
SET DiscountPct = 
    CASE 
        WHEN Quantity >= 90 THEN 15.00
        WHEN Quantity >= 50 THEN 10.00
        WHEN Quantity >= 20 THEN 5.00
        ELSE 0.00
    END;
GO

SELECT ProductName, Quantity, DiscountPct 
FROM ActiveProducts 
ORDER BY DiscountPct DESC, ProductName;
GO

/*
OUTPUT:
ProductName              Quantity  DiscountPct
-----------------------  --------  -----------
Combo: USB Keyboard      95        15.00
Combo: Wireless Mouse    95        15.00
Wireless Mouse           95        15.00
USB Keyboard             70        10.00
Laptop Stand             45        5.00
Monitor                  20        5.00

Tiered discounts applied!
*/

/*
================================================================================
PART 3: DELETE OPERATIONS
================================================================================

DELETE through views removes rows from the underlying table.
*/

-- Example 1: Simple DELETE
DELETE FROM ActiveProducts
WHERE ProductName LIKE 'Combo:%';
GO

PRINT 'Combo products deleted';
GO

SELECT ProductName FROM ActiveProducts ORDER BY ProductName;
GO

/*
OUTPUT:
Combo products deleted

ProductName
-----------------------
Laptop Stand
Monitor
USB Keyboard
Wireless Mouse

Combo products removed!
*/

-- Example 2: DELETE with condition
-- Add new low-stock products
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
VALUES ('Test Product 1', 'Test', 9.99, 2);
GO

-- Delete low-stock products
DELETE FROM ActiveProducts
WHERE Quantity < 10;
GO

PRINT 'Low-stock products deleted';
GO

-- Example 3: DELETE with TOP
-- Add some test data
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
VALUES 
    ('Test A', 'Test', 5.00, 100),
    ('Test B', 'Test', 6.00, 100),
    ('Test C', 'Test', 7.00, 100);
GO

-- Delete top 2 test products
DELETE TOP (2) FROM ActiveProducts
WHERE ProductName LIKE 'Test%';
GO

SELECT ProductName FROM ActiveProducts WHERE ProductName LIKE 'Test%';
GO

/*
OUTPUT:
ProductName
-----------
Test C

Only one test product remains!
*/

-- Cleanup
DELETE FROM ActiveProducts WHERE ProductName LIKE 'Test%';
GO

/*
================================================================================
PART 4: WITH CHECK OPTION
================================================================================

WITH CHECK OPTION ensures modifications don't violate the view's WHERE clause.
*/

-- Recreate view WITH CHECK OPTION
ALTER VIEW ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    Quantity,
    DiscountPct,
    IsActive
FROM Product
WHERE IsActive = 1
WITH CHECK OPTION;
GO

-- Example 1: Valid INSERT (IsActive = 1)
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity, IsActive)
VALUES ('New Product', 'Electronics', 99.99, 50, 1);
GO

SELECT ProductName, IsActive FROM ActiveProducts WHERE ProductName = 'New Product';
GO

/*
OUTPUT:
ProductName   IsActive
------------  --------
New Product   1

Inserted successfully!
*/

-- Example 2: Invalid INSERT (IsActive = 0)
BEGIN TRY
    INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity, IsActive)
    VALUES ('Inactive Product', 'Electronics', 49.99, 10, 0);
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'WITH CHECK OPTION prevented insert of inactive product';
END CATCH;
GO

/*
OUTPUT:
ERROR: The attempted insert or update failed because the target view either specifies WITH CHECK OPTION...
WITH CHECK OPTION prevented insert of inactive product
*/

-- Example 3: Invalid UPDATE (would violate filter)
BEGIN TRY
    UPDATE ActiveProducts
    SET IsActive = 0
    WHERE ProductName = 'New Product';
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'WITH CHECK OPTION prevented deactivation';
END CATCH;
GO

/*
OUTPUT:
ERROR: The attempted insert or update failed because the target view either specifies WITH CHECK OPTION...
WITH CHECK OPTION prevented deactivation
*/

-- Example 4: Valid UPDATE (maintains IsActive = 1)
UPDATE ActiveProducts
SET Price = 89.99, Quantity = 75
WHERE ProductName = 'New Product';
GO

SELECT ProductName, Price, Quantity FROM ActiveProducts WHERE ProductName = 'New Product';
GO

/*
OUTPUT:
ProductName   Price  Quantity
------------  -----  --------
New Product   89.99  75

Update succeeded!
*/

/*
================================================================================
PART 5: HANDLING DEFAULT VALUES
================================================================================

Views can leverage default values defined in the base table.
*/

-- Create view that doesn't include all columns
CREATE VIEW ProductBasicInfo AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price
    -- Quantity, IsActive, CreatedDate have defaults
FROM Product;
GO

-- INSERT using defaults
INSERT INTO ProductBasicInfo (ProductName, Category, Price)
VALUES ('Simple Product', 'Office', 19.99);
GO

-- Check result in base table
SELECT ProductName, Price, Quantity, IsActive, CreatedDate
FROM Product
WHERE ProductName = 'Simple Product';
GO

/*
OUTPUT:
ProductName      Price  Quantity  IsActive  CreatedDate
---------------  -----  --------  --------  -----------
Simple Product   19.99  0         1         2024-11-09

Defaults applied automatically!
*/

/*
================================================================================
PART 6: COMMON PATTERNS AND BEST PRACTICES
================================================================================
*/

-- Pattern 1: Audit tracking with triggers
CREATE TRIGGER trg_ActiveProducts_Update
ON ActiveProducts
INSTEAD OF UPDATE AS
BEGIN
    UPDATE p
    SET 
        p.ProductName = i.ProductName,
        p.Category = i.Category,
        p.Price = i.Price,
        p.Quantity = i.Quantity,
        p.DiscountPct = i.DiscountPct,
        p.LastModified = GETDATE()  -- Auto-update timestamp
    FROM Product p
    INNER JOIN inserted i ON p.ProductID = i.ProductID;
    
    PRINT 'Updated ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' row(s)';
END;
GO

-- Test trigger
UPDATE ActiveProducts
SET Price = 25.99
WHERE ProductName = 'Wireless Mouse';
GO

SELECT ProductName, Price, LastModified 
FROM Product 
WHERE ProductName = 'Wireless Mouse';
GO

/*
OUTPUT:
Updated 1 row(s)

ProductName      Price  LastModified
---------------  -----  -------------------
Wireless Mouse   25.99  2024-11-09 11:00:00

Timestamp automatically updated!
*/

-- Pattern 2: Validation in INSTEAD OF trigger
CREATE TRIGGER trg_ActiveProducts_Insert
ON ActiveProducts
INSTEAD OF INSERT AS
BEGIN
    -- Validation: Price must be positive
    IF EXISTS (SELECT 1 FROM inserted WHERE Price <= 0)
    BEGIN
        RAISERROR('Price must be greater than 0', 16, 1);
        RETURN;
    END
    
    -- Validation: Quantity must be non-negative
    IF EXISTS (SELECT 1 FROM inserted WHERE Quantity < 0)
    BEGIN
        RAISERROR('Quantity cannot be negative', 16, 1);
        RETURN;
    END
    
    -- Insert with additional logic
    INSERT INTO Product (ProductName, Category, Price, Quantity, IsActive)
    SELECT ProductName, Category, Price, Quantity, ISNULL(IsActive, 1)
    FROM inserted;
    
    PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' row(s) with validation';
END;
GO

-- Test validation (invalid price)
BEGIN TRY
    INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
    VALUES ('Invalid Product', 'Test', -10.00, 50);
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

/*
OUTPUT:
ERROR: Price must be greater than 0
*/

-- Test validation (valid insert)
INSERT INTO ActiveProducts (ProductName, Category, Price, Quantity)
VALUES ('Valid Product', 'Electronics', 59.99, 30);
GO

/*
OUTPUT:
Inserted 1 row(s) with validation
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Create and Use Simple View
---------------------------------------
Create a table for Orders with: OrderID, CustomerID, OrderDate, Status, Total.
Create a view showing only 'Pending' orders.
INSERT 3 orders through the view (all pending).
UPDATE one order's total.
DELETE one order.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: WITH CHECK OPTION
------------------------------
Create a view for products priced between $10 and $100.
Use WITH CHECK OPTION.
Try to INSERT a product at $5 (should fail).
Try to INSERT a product at $50 (should succeed).
Try to UPDATE a product to $150 (should fail).

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: INSTEAD OF Trigger
-------------------------------
Create a view for customers.
Create INSTEAD OF INSERT trigger that:
  - Validates email format (must contain @)
  - Auto-generates customer code
  - Sets registration date to current date
Test with valid and invalid data.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Create and Use Simple View
CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    Total DECIMAL(10,2) NOT NULL
);
GO

CREATE VIEW PendingOrders AS
SELECT OrderID, CustomerID, OrderDate, Status, Total
FROM [Order]
WHERE Status = 'Pending';
GO

-- INSERT orders
INSERT INTO PendingOrders (CustomerID, Total, Status)
VALUES 
    (1, 250.00, 'Pending'),
    (2, 500.00, 'Pending'),
    (3, 175.00, 'Pending');
GO

SELECT * FROM PendingOrders;
GO

-- UPDATE order
UPDATE PendingOrders
SET Total = 275.00
WHERE OrderID = 1;
GO

-- DELETE order
DELETE FROM PendingOrders WHERE OrderID = 3;
GO

SELECT * FROM PendingOrders;
GO

-- Solution 2: WITH CHECK OPTION
CREATE VIEW ReasonablyPricedProducts AS
SELECT ProductID, ProductName, Category, Price, Quantity
FROM Product
WHERE Price BETWEEN 10.00 AND 100.00
WITH CHECK OPTION;
GO

-- Try $5 (fails)
BEGIN TRY
    INSERT INTO ReasonablyPricedProducts (ProductName, Category, Price, Quantity)
    VALUES ('Cheap Item', 'Test', 5.00, 10);
END TRY
BEGIN CATCH
    PRINT 'Correctly rejected $5 product: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Try $50 (succeeds)
INSERT INTO ReasonablyPricedProducts (ProductName, Category, Price, Quantity)
VALUES ('Mid-Price Item', 'Test', 50.00, 25);
PRINT 'Successfully inserted $50 product';
GO

-- Try UPDATE to $150 (fails)
BEGIN TRY
    UPDATE ReasonablyPricedProducts
    SET Price = 150.00
    WHERE ProductName = 'Mid-Price Item';
END TRY
BEGIN CATCH
    PRINT 'Correctly rejected UPDATE to $150: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Solution 3: INSTEAD OF Trigger
CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode NVARCHAR(20) NOT NULL UNIQUE,
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200) NOT NULL,
    RegistrationDate DATE NOT NULL
);
GO

CREATE VIEW CustomerRegistration AS
SELECT CustomerID, CustomerName, Email
FROM Customer;
GO

CREATE TRIGGER trg_CustomerRegistration_Insert
ON CustomerRegistration
INSTEAD OF INSERT AS
BEGIN
    -- Validate email
    IF EXISTS (SELECT 1 FROM inserted WHERE Email NOT LIKE '%@%')
    BEGIN
        RAISERROR('Invalid email format - must contain @', 16, 1);
        RETURN;
    END
    
    -- Generate customer code and insert
    INSERT INTO Customer (CustomerCode, CustomerName, Email, RegistrationDate)
    SELECT 
        'CUST' + RIGHT('00000' + CAST(NEXT VALUE FOR CustomerCodeSeq AS VARCHAR(5)), 5),
        CustomerName,
        Email,
        CAST(GETDATE() AS DATE)
    FROM inserted;
    
    PRINT 'Customer registered with auto-generated code';
END;
GO

-- Create sequence for codes
CREATE SEQUENCE CustomerCodeSeq START WITH 1 INCREMENT BY 1;
GO

-- Test invalid email
BEGIN TRY
    INSERT INTO CustomerRegistration (CustomerName, Email)
    VALUES ('Invalid Customer', 'bademail');
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test valid email
INSERT INTO CustomerRegistration (CustomerName, Email)
VALUES ('Valid Customer', 'customer@example.com');
GO

SELECT * FROM Customer;
GO

/*
OUTPUT:
CustomerID  CustomerCode  CustomerName    Email                    RegistrationDate
----------  ------------  --------------  -----------------------  ----------------
1           CUST00001     Valid Customer  customer@example.com     2024-11-09

Auto-generated code and date!
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. INSERT THROUGH VIEWS
   - Adds rows to underlying table
   - Must include all NOT NULL columns (or they need defaults)
   - Can use VALUES, SELECT, or multiple rows
   - Default values applied automatically
   - View columns map to table columns

2. UPDATE THROUGH VIEWS
   - Modifies underlying table rows
   - Can update any visible columns
   - Supports calculations and expressions
   - WHERE clause filters which rows to update
   - Can use JOIN syntax (for single-table views)

3. DELETE THROUGH VIEWS
   - Removes rows from underlying table
   - WHERE clause specifies rows to delete
   - Supports TOP clause
   - Use carefully - data is permanently deleted
   - Cannot delete from multi-table views directly

4. WITH CHECK OPTION
   - Enforces view's WHERE clause on modifications
   - Prevents INSERT/UPDATE that violates filter
   - Essential for data integrity
   - Use on all filtered updatable views
   - Catches logic errors

5. DEFAULT VALUES
   - Table defaults apply through views
   - Columns not in view use their defaults
   - Explicit DEFAULT keyword works
   - Identity columns auto-increment
   - Timestamp columns auto-update

6. INSTEAD OF TRIGGERS
   - Custom INSERT/UPDATE/DELETE logic
   - Validation before modification
   - Data transformation
   - Audit logging
   - Complex business rules

7. BEST PRACTICES
   - Always use WITH CHECK OPTION on filtered views
   - Document which views are updatable
   - Test all DML operations
   - Use triggers for complex validation
   - Consider security implications
   - Provide helpful error messages
   - Log modifications for audit

8. COMMON PITFALLS
   - Missing NOT NULL columns in INSERT
   - Violating view filter without WITH CHECK OPTION
   - Attempting to update computed columns
   - Forgetting INSTEAD OF trigger returns no rows
   - Not handling errors properly

================================================================================

NEXT STEPS:
-----------
In Lesson 14.9, we'll explore UPDATING COMPLEX VIEWS:
- Multi-table view updates
- INSTEAD OF triggers for complex scenarios
- Handling ambiguous updates
- Advanced update patterns

Continue to: 09-updating-complex-views/lesson.sql

================================================================================
*/
