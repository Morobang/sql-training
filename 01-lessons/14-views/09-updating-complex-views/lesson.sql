/*
================================================================================
LESSON 14.9: UPDATING COMPLEX VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand limitations of multi-table view updates
2. Create INSTEAD OF triggers for complex updates
3. Handle updates affecting multiple tables
4. Manage ambiguous column updates
5. Implement transaction control in triggers
6. Handle error conditions properly
7. Apply best practices for complex view updates

Business Context:
-----------------
Complex views joining multiple tables are often read-only by default.
INSTEAD OF triggers enable updates through these views by defining custom
logic for INSERT, UPDATE, and DELETE operations. This maintains the abstraction
while allowing controlled modifications to underlying tables.

Database: RetailStore
Complexity: Advanced
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: MULTI-TABLE VIEW UPDATE LIMITATIONS
================================================================================

Views joining multiple tables have restrictions on direct updates.
*/

-- Create schema for examples
DROP TABLE IF EXISTS OrderItem;
DROP TABLE IF EXISTS [Order];
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(200),
    CreditLimit DECIMAL(10,2) DEFAULT 5000.00
);

CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0
);

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status NVARCHAR(20) NOT NULL DEFAULT 'Pending',
    ShippingAddress NVARCHAR(500)
);

CREATE TABLE OrderItem (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES [Order](OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    Discount DECIMAL(5,2) DEFAULT 0
);
GO

-- Insert sample data
INSERT INTO Customer VALUES
    (1, 'Acme Corp', 'contact@acme.com', 10000.00),
    (2, 'TechStart', 'info@techstart.com', 5000.00);

INSERT INTO Product VALUES
    (1, 'Laptop', 'Electronics', 999.99, 50),
    (2, 'Mouse', 'Electronics', 29.99, 200),
    (3, 'Desk', 'Furniture', 299.99, 30);

INSERT INTO [Order] VALUES
    (1, 1, '2024-11-01', 'Pending', '123 Main St'),
    (2, 2, '2024-11-05', 'Shipped', '456 Oak Ave');

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, Discount)
VALUES
    (1, 1, 2, 999.99, 0.10),
    (1, 2, 5, 29.99, 0.00),
    (2, 3, 3, 299.99, 0.05);
GO

-- Create complex multi-table view
CREATE VIEW OrderDetails AS
SELECT 
    o.OrderID,
    o.OrderDate,
    o.Status,
    c.CustomerID,
    c.CustomerName,
    c.Email,
    oi.OrderItemID,
    p.ProductID,
    p.ProductName,
    p.Category,
    oi.Quantity,
    oi.UnitPrice,
    oi.Discount,
    oi.Quantity * oi.UnitPrice * (1 - oi.Discount) AS LineTotal
FROM [Order] o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
INNER JOIN Product p ON oi.ProductID = p.ProductID;
GO

SELECT * FROM OrderDetails;
GO

-- Attempt direct UPDATE (limited - can only update one table)
UPDATE OrderDetails
SET Status = 'Processing'  -- Updates Order table - works!
WHERE OrderID = 1;
GO

SELECT OrderID, Status FROM OrderDetails WHERE OrderID = 1;
GO

/*
OUTPUT:
OrderID  Status
-------  ----------
1        Processing
1        Processing

Updated successfully (Order table column)!
*/

-- Attempt to update columns from different tables (fails)
BEGIN TRY
    UPDATE OrderDetails
    SET Status = 'Shipped',          -- Order table
        CustomerName = 'New Name',    -- Customer table
        Quantity = 3                  -- OrderItem table
    WHERE OrderID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot update multiple base tables through join view';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

/*
OUTPUT:
ERROR: Cannot update multiple base tables through join view
View or function 'OrderDetails' is not updatable because the modification affects multiple base tables.
*/

/*
================================================================================
PART 2: INSTEAD OF UPDATE TRIGGER
================================================================================

INSTEAD OF triggers enable complex updates by defining custom logic.
*/

-- Create INSTEAD OF UPDATE trigger
CREATE TRIGGER trg_OrderDetails_Update
ON OrderDetails
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Update Order table
        UPDATE o
        SET 
            o.Status = i.Status,
            o.ShippingAddress = i.ShippingAddress
        FROM [Order] o
        INNER JOIN inserted i ON o.OrderID = i.OrderID
        WHERE UPDATE(Status) OR UPDATE(ShippingAddress);
        
        -- Update Customer table
        UPDATE c
        SET 
            c.CustomerName = i.CustomerName,
            c.Email = i.Email
        FROM Customer c
        INNER JOIN inserted i ON c.CustomerID = i.CustomerID
        WHERE UPDATE(CustomerName) OR UPDATE(Email);
        
        -- Update OrderItem table
        UPDATE oi
        SET 
            oi.Quantity = i.Quantity,
            oi.UnitPrice = i.UnitPrice,
            oi.Discount = i.Discount
        FROM OrderItem oi
        INNER JOIN inserted i ON oi.OrderItemID = i.OrderItemID
        WHERE UPDATE(Quantity) OR UPDATE(UnitPrice) OR UPDATE(Discount);
        
        COMMIT TRANSACTION;
        PRINT 'Multi-table update completed successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO

-- Now can update multiple tables simultaneously
UPDATE OrderDetails
SET 
    Status = 'Shipped',              -- Order table
    CustomerName = 'Acme Corporation',  -- Customer table
    Quantity = 3                     -- OrderItem table
WHERE OrderID = 1 AND ProductID = 1;
GO

/*
OUTPUT:
Multi-table update completed successfully
*/

-- Verify updates
SELECT 
    OrderID,
    Status,
    CustomerName,
    ProductName,
    Quantity
FROM OrderDetails
WHERE OrderID = 1 AND ProductID = 1;
GO

/*
OUTPUT:
OrderID  Status   CustomerName        ProductName  Quantity
-------  -------  ------------------  -----------  --------
1        Shipped  Acme Corporation    Laptop       3

All tables updated correctly!
*/

/*
================================================================================
PART 3: INSTEAD OF INSERT TRIGGER
================================================================================

Handle complex inserts affecting multiple tables.
*/

CREATE TRIGGER trg_OrderDetails_Insert
ON OrderDetails
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insert new customers if they don't exist
        INSERT INTO Customer (CustomerID, CustomerName, Email)
        SELECT DISTINCT i.CustomerID, i.CustomerName, i.Email
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM Customer c WHERE c.CustomerID = i.CustomerID
        );
        
        -- Insert new orders if they don't exist
        INSERT INTO [Order] (OrderID, CustomerID, OrderDate, Status)
        SELECT DISTINCT i.OrderID, i.CustomerID, i.OrderDate, i.Status
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM [Order] o WHERE o.OrderID = i.OrderID
        );
        
        -- Insert order items
        INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, Discount)
        SELECT i.OrderID, i.ProductID, i.Quantity, i.UnitPrice, i.Discount
        FROM inserted i;
        
        -- Update product stock
        UPDATE p
        SET p.StockQuantity = p.StockQuantity - i.Quantity
        FROM Product p
        INNER JOIN inserted i ON p.ProductID = i.ProductID;
        
        COMMIT TRANSACTION;
        PRINT 'Complex insert completed successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO

-- Insert through view (creates order + customer if needed + updates stock)
INSERT INTO OrderDetails (
    OrderID, CustomerID, CustomerName, Email, OrderDate, Status,
    ProductID, Quantity, UnitPrice, Discount
)
VALUES (
    3, 3, 'New Customer Inc', 'contact@newcustomer.com', '2024-11-09', 'Pending',
    2, 10, 29.99, 0.05
);
GO

/*
OUTPUT:
Complex insert completed successfully
*/

-- Verify all tables were updated
SELECT * FROM Customer WHERE CustomerID = 3;
SELECT * FROM [Order] WHERE OrderID = 3;
SELECT * FROM OrderItem WHERE OrderID = 3;
SELECT ProductID, ProductName, StockQuantity FROM Product WHERE ProductID = 2;
GO

/*
OUTPUT (Customer):
CustomerID  CustomerName        Email
----------  ------------------  ------------------------
3           New Customer Inc    contact@newcustomer.com

OUTPUT (Order):
OrderID  CustomerID  OrderDate   Status
-------  ----------  ----------  -------
3        3           2024-11-09  Pending

OUTPUT (OrderItem):
OrderItemID  OrderID  ProductID  Quantity  UnitPrice  Discount
-----------  -------  ---------  --------  ---------  --------
4            3        2          10        29.99      0.05

OUTPUT (Product):
ProductID  ProductName  StockQuantity
---------  -----------  -------------
2          Mouse        190

All tables updated, stock reduced!
*/

/*
================================================================================
PART 4: INSTEAD OF DELETE TRIGGER
================================================================================

Handle cascading deletes and business logic.
*/

CREATE TRIGGER trg_OrderDetails_Delete
ON OrderDetails
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Restore product stock
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + d.Quantity
        FROM Product p
        INNER JOIN deleted d ON p.ProductID = d.ProductID;
        
        -- Delete order items
        DELETE oi
        FROM OrderItem oi
        INNER JOIN deleted d ON oi.OrderItemID = d.OrderItemID;
        
        -- Delete orders if no items remain
        DELETE o
        FROM [Order] o
        WHERE NOT EXISTS (
            SELECT 1 FROM OrderItem oi WHERE oi.OrderID = o.OrderID
        )
        AND o.OrderID IN (SELECT DISTINCT OrderID FROM deleted);
        
        -- Note: Don't delete customers (business rule)
        
        COMMIT TRANSACTION;
        PRINT 'Complex delete completed with stock restoration';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO

-- Delete through view
DELETE FROM OrderDetails
WHERE OrderID = 3;
GO

/*
OUTPUT:
Complex delete completed with stock restoration
*/

-- Verify deletion and stock restoration
SELECT COUNT(*) AS OrderItemsRemaining FROM OrderItem WHERE OrderID = 3;
SELECT COUNT(*) AS OrdersRemaining FROM [Order] WHERE OrderID = 3;
SELECT ProductID, StockQuantity FROM Product WHERE ProductID = 2;
GO

/*
OUTPUT:
OrderItemsRemaining
-------------------
0

OrdersRemaining
---------------
0

ProductID  StockQuantity
---------  -------------
2          200

Order and items deleted, stock restored to original 200!
*/

/*
================================================================================
PART 5: ADVANCED VALIDATION AND BUSINESS RULES
================================================================================
*/

-- Create enhanced update trigger with validation
ALTER TRIGGER trg_OrderDetails_Update
ON OrderDetails
INSTEAD OF UPDATE AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validation: Cannot change order after shipping
        IF EXISTS (
            SELECT 1 
            FROM deleted d
            INNER JOIN inserted i ON d.OrderItemID = i.OrderItemID
            WHERE d.Status = 'Shipped' 
            AND (d.Quantity <> i.Quantity OR d.UnitPrice <> i.UnitPrice)
        )
        BEGIN
            RAISERROR('Cannot modify shipped orders', 16, 1);
            RETURN;
        END
        
        -- Validation: Quantity must be positive
        IF EXISTS (SELECT 1 FROM inserted WHERE Quantity <= 0)
        BEGIN
            RAISERROR('Quantity must be greater than 0', 16, 1);
            RETURN;
        END
        
        -- Validation: Check stock availability
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN Product p ON i.ProductID = p.ProductID
            INNER JOIN deleted d ON i.OrderItemID = d.OrderItemID
            WHERE i.Quantity > d.Quantity + p.StockQuantity
        )
        BEGIN
            RAISERROR('Insufficient stock for quantity increase', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Adjust stock for quantity changes
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + (d.Quantity - i.Quantity)
        FROM Product p
        INNER JOIN inserted i ON p.ProductID = i.ProductID
        INNER JOIN deleted d ON i.OrderItemID = d.OrderItemID
        WHERE i.Quantity <> d.Quantity;
        
        -- Update Order table
        UPDATE o
        SET o.Status = i.Status
        FROM [Order] o
        INNER JOIN inserted i ON o.OrderID = i.OrderID
        WHERE UPDATE(Status);
        
        -- Update Customer table
        UPDATE c
        SET c.CustomerName = i.CustomerName, c.Email = i.Email
        FROM Customer c
        INNER JOIN inserted i ON c.CustomerID = i.CustomerID
        WHERE UPDATE(CustomerName) OR UPDATE(Email);
        
        -- Update OrderItem table
        UPDATE oi
        SET 
            oi.Quantity = i.Quantity,
            oi.UnitPrice = i.UnitPrice,
            oi.Discount = i.Discount
        FROM OrderItem oi
        INNER JOIN inserted i ON oi.OrderItemID = i.OrderItemID;
        
        COMMIT TRANSACTION;
        PRINT 'Validated update completed successfully';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END;
GO

-- Test validation: Try to modify shipped order
BEGIN TRY
    UPDATE OrderDetails
    SET Quantity = 10
    WHERE OrderID = 2;  -- Shipped order
END TRY
BEGIN CATCH
    PRINT 'Validation error: ' + ERROR_MESSAGE();
END CATCH;
GO

/*
OUTPUT:
Validation error: Cannot modify shipped orders
*/

-- Test validation: Try negative quantity
BEGIN TRY
    UPDATE OrderDetails
    SET Quantity = -5
    WHERE OrderID = 1 AND ProductID = 1;
END TRY
BEGIN CATCH
    PRINT 'Validation error: ' + ERROR_MESSAGE();
END CATCH;
GO

/*
OUTPUT:
Validation error: Quantity must be greater than 0
*/

-- Test valid update with stock adjustment
UPDATE OrderDetails
SET Quantity = 4  -- Increase from 3 to 4
WHERE OrderID = 1 AND ProductID = 1;
GO

-- Verify stock was adjusted
SELECT ProductID, ProductName, StockQuantity 
FROM Product 
WHERE ProductID = 1;
GO

/*
OUTPUT:
Validated update completed successfully

ProductID  ProductName  StockQuantity
---------  -----------  -------------
1          Laptop       49

Stock decreased by 1 (from 50 to 49)!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Create Updatable Multi-Table View
----------------------------------------------
Create tables: Department, Employee (with DepartmentID FK).
Create view joining both tables.
Create INSTEAD OF UPDATE trigger to allow updating both tables.
Test by updating employee name and department name simultaneously.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Complex INSERT with Validation
-------------------------------------------
Using the OrderDetails view, enhance the INSERT trigger to:
- Validate customer credit limit
- Ensure product stock is sufficient
- Calculate and validate total order amount
- Rollback if any validation fails

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Cascading DELETE
-----------------------------
Create view joining Customer, Order, OrderItem.
Create INSTEAD OF DELETE trigger that:
- Deletes order items
- Deletes orders with no remaining items
- Marks customer as inactive (don't delete)
- Logs deletion for audit

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Create Updatable Multi-Table View
CREATE TABLE Department (
    DepartmentID INT PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    Budget DECIMAL(12,2)
);

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(200) NOT NULL,
    DepartmentID INT FOREIGN KEY REFERENCES Department(DepartmentID),
    Salary DECIMAL(10,2)
);
GO

INSERT INTO Department VALUES (1, 'Sales', 500000.00), (2, 'IT', 750000.00);
INSERT INTO Employee VALUES (1, 'John Doe', 1, 75000.00), (2, 'Jane Smith', 2, 85000.00);
GO

CREATE VIEW EmployeeDetails AS
SELECT 
    e.EmployeeID,
    e.EmployeeName,
    e.Salary,
    d.DepartmentID,
    d.DepartmentName,
    d.Budget
FROM Employee e
INNER JOIN Department d ON e.DepartmentID = d.DepartmentID;
GO

CREATE TRIGGER trg_EmployeeDetails_Update
ON EmployeeDetails
INSTEAD OF UPDATE AS
BEGIN
    -- Update Employee
    UPDATE e
    SET e.EmployeeName = i.EmployeeName, e.Salary = i.Salary
    FROM Employee e
    INNER JOIN inserted i ON e.EmployeeID = i.EmployeeID;
    
    -- Update Department
    UPDATE d
    SET d.DepartmentName = i.DepartmentName, d.Budget = i.Budget
    FROM Department d
    INNER JOIN inserted i ON d.DepartmentID = i.DepartmentID;
    
    PRINT 'Updated employee and department';
END;
GO

-- Test
UPDATE EmployeeDetails
SET EmployeeName = 'John Smith', DepartmentName = 'Sales & Marketing'
WHERE EmployeeID = 1;
GO

SELECT * FROM EmployeeDetails WHERE EmployeeID = 1;
GO

-- Solution 2: Complex INSERT with Validation
ALTER TRIGGER trg_OrderDetails_Insert
ON OrderDetails
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validation: Check stock
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            INNER JOIN Product p ON i.ProductID = p.ProductID
            WHERE i.Quantity > p.StockQuantity
        )
        BEGIN
            RAISERROR('Insufficient stock', 16, 1);
            RETURN;
        END
        
        -- Calculate order totals
        DECLARE @OrderTotals TABLE (CustomerID INT, OrderTotal DECIMAL(12,2));
        
        INSERT INTO @OrderTotals
        SELECT 
            i.CustomerID,
            SUM(i.Quantity * i.UnitPrice * (1 - i.Discount))
        FROM inserted i
        GROUP BY i.CustomerID;
        
        -- Validation: Check credit limit
        IF EXISTS (
            SELECT 1 
            FROM @OrderTotals ot
            INNER JOIN Customer c ON ot.CustomerID = c.CustomerID
            WHERE ot.OrderTotal > c.CreditLimit
        )
        BEGIN
            RAISERROR('Order exceeds customer credit limit', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Insert customers if needed
        INSERT INTO Customer (CustomerID, CustomerName, Email)
        SELECT DISTINCT i.CustomerID, i.CustomerName, i.Email
        FROM inserted i
        WHERE NOT EXISTS (SELECT 1 FROM Customer c WHERE c.CustomerID = i.CustomerID);
        
        -- Insert orders
        INSERT INTO [Order] (OrderID, CustomerID, OrderDate, Status)
        SELECT DISTINCT i.OrderID, i.CustomerID, i.OrderDate, i.Status
        FROM inserted i
        WHERE NOT EXISTS (SELECT 1 FROM [Order] o WHERE o.OrderID = i.OrderID);
        
        -- Insert order items
        INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice, Discount)
        SELECT i.OrderID, i.ProductID, i.Quantity, i.UnitPrice, i.Discount
        FROM inserted i;
        
        -- Update stock
        UPDATE p
        SET p.StockQuantity = p.StockQuantity - i.Quantity
        FROM Product p
        INNER JOIN inserted i ON p.ProductID = i.ProductID;
        
        COMMIT TRANSACTION;
        PRINT 'Validated insert completed';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH;
END;
GO

-- Test: Valid insert within credit limit
INSERT INTO OrderDetails (OrderID, CustomerID, CustomerName, Email, OrderDate, Status, ProductID, Quantity, UnitPrice, Discount)
VALUES (4, 1, 'Acme Corp', 'contact@acme.com', '2024-11-09', 'Pending', 1, 2, 999.99, 0);
GO

-- Solution 3: Cascading DELETE
CREATE TABLE DeletionLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    DeletedTable NVARCHAR(50),
    DeletedID INT,
    DeletedDate DATETIME DEFAULT GETDATE(),
    DeletedBy NVARCHAR(100) DEFAULT SUSER_NAME()
);

ALTER TABLE Customer ADD IsActive BIT DEFAULT 1;
GO

ALTER TRIGGER trg_OrderDetails_Delete
ON OrderDetails
INSTEAD OF DELETE AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    -- Log order items
    INSERT INTO DeletionLog (DeletedTable, DeletedID)
    SELECT 'OrderItem', OrderItemID FROM deleted;
    
    -- Restore stock
    UPDATE p
    SET p.StockQuantity = p.StockQuantity + d.Quantity
    FROM Product p
    INNER JOIN deleted d ON p.ProductID = d.ProductID;
    
    -- Delete order items
    DELETE oi
    FROM OrderItem oi
    INNER JOIN deleted d ON oi.OrderItemID = d.OrderItemID;
    
    -- Delete orders with no items
    DELETE o
    FROM [Order] o
    WHERE NOT EXISTS (SELECT 1 FROM OrderItem oi WHERE oi.OrderID = o.OrderID)
    AND o.OrderID IN (SELECT DISTINCT OrderID FROM deleted);
    
    -- Log deleted orders
    INSERT INTO DeletionLog (DeletedTable, DeletedID)
    SELECT 'Order', OrderID FROM deleted
    WHERE NOT EXISTS (SELECT 1 FROM [Order] o WHERE o.OrderID = deleted.OrderID);
    
    -- Mark customers inactive (don't delete)
    UPDATE c
    SET c.IsActive = 0
    FROM Customer c
    WHERE NOT EXISTS (SELECT 1 FROM [Order] o WHERE o.CustomerID = c.CustomerID)
    AND c.CustomerID IN (SELECT DISTINCT CustomerID FROM deleted);
    
    COMMIT TRANSACTION;
    PRINT 'Cascading delete with audit log completed';
END;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. MULTI-TABLE VIEW LIMITATIONS
   - Cannot directly update multiple base tables
   - Can update one table at a time
   - Complex scenarios need INSTEAD OF triggers
   - Ambiguous updates fail
   - JOIN views have restrictions

2. INSTEAD OF TRIGGERS
   - Define custom INSERT/UPDATE/DELETE logic
   - Handle multi-table modifications
   - Implement validation and business rules
   - Control transaction scope
   - Replace default behavior completely

3. TRANSACTION CONTROL
   - Wrap multi-table changes in transactions
   - ROLLBACK on validation failures
   - Use TRY/CATCH for error handling
   - Check @@TRANCOUNT before rollback
   - Ensure atomicity (all or nothing)

4. VALIDATION PATTERNS
   - Check constraints before modification
   - Validate stock availability
   - Enforce credit limits
   - Prevent invalid state transitions
   - Provide meaningful error messages

5. STOCK MANAGEMENT
   - Update inventory on INSERT/UPDATE/DELETE
   - Restore stock on delete
   - Validate availability before commit
   - Handle quantity changes correctly
   - Maintain data integrity

6. CASCADING OPERATIONS
   - Delete child records first
   - Handle orphaned records
   - Implement soft deletes (IsActive flag)
   - Log deletions for audit
   - Preserve referential integrity

7. BEST PRACTICES
   - Always use transactions
   - Implement thorough validation
   - Handle errors gracefully
   - Log significant operations
   - Test edge cases
   - Document trigger logic
   - Consider performance impact
   - Use SET NOCOUNT ON

8. WHEN TO USE
   - Multi-table view updates required
   - Complex business logic on modifications
   - Need validation before changes
   - Cascading operations needed
   - Audit trail required
   - Stock/inventory management
   - Soft delete patterns

================================================================================

NEXT STEPS:
-----------
In Lesson 14.10, we'll complete the chapter with TEST YOUR KNOWLEDGE:
- Comprehensive exercises
- Real-world scenarios
- Performance challenges
- Best practices review

Continue to: 10-test-your-knowledge/lesson.sql

================================================================================
*/
