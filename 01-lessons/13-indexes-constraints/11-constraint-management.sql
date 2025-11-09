/*
================================================================================
LESSON 13.11: CONSTRAINT MANAGEMENT
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Add constraints to existing tables
2. Drop constraints safely
3. Modify constraint definitions
4. Enable and disable constraints temporarily
5. Identify and fix constraint violations
6. Work with constraint metadata
7. Implement constraint management best practices

Business Context:
-----------------
Database requirements evolve over time. Tables created without constraints
need them added, business rules change requiring modifications, and data
migrations require temporarily disabling constraints. Proper constraint
management ensures data integrity while allowing necessary flexibility
for operations and maintenance.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: ADDING CONSTRAINTS TO EXISTING TABLES
================================================================================

When tables are created without constraints or business rules change,
you need to add constraints to existing tables.

PROCESS:
--------
1. Ensure data complies with constraint
2. Add constraint with ALTER TABLE
3. Name constraints explicitly
4. Test constraint enforcement

*/

-- Create table without constraints (initial version)
DROP TABLE IF EXISTS Product_V1;
GO

CREATE TABLE Product_V1 (
    ProductID INT IDENTITY(1,1),
    ProductName NVARCHAR(200),
    SKU VARCHAR(50),
    Price DECIMAL(10,2),
    Quantity INT,
    CategoryID INT,
    SupplierID INT,
    IsActive BIT,
    CreatedDate DATETIME
);
GO

-- Insert sample data
INSERT INTO Product_V1 (ProductName, SKU, Price, Quantity, CategoryID, SupplierID, IsActive, CreatedDate)
VALUES
    ('Laptop', 'LAP-001', 999.99, 50, 1, 101, 1, '2024-01-15'),
    ('Mouse', 'MOU-001', 29.99, 200, 1, 101, 1, '2024-01-15'),
    ('Keyboard', 'KEY-001', 79.99, 150, 1, 102, 1, '2024-01-15'),
    ('Monitor', 'MON-001', 299.99, 75, 1, 103, 1, '2024-01-15'),
    ('Headphones', 'HEAD-001', 149.99, 100, 2, 104, 1, '2024-01-15');
GO

-- Step 1: Add PRIMARY KEY constraint
ALTER TABLE Product_V1
ADD CONSTRAINT PK_Product_V1_ProductID PRIMARY KEY (ProductID);
GO

PRINT 'Primary key added successfully';
GO

-- Step 2: Add UNIQUE constraint
ALTER TABLE Product_V1
ADD CONSTRAINT UQ_Product_V1_SKU UNIQUE (SKU);
GO

PRINT 'Unique constraint added successfully';
GO

-- Step 3: Add CHECK constraints
ALTER TABLE Product_V1
ADD CONSTRAINT CK_Product_V1_Price CHECK (Price >= 0);
GO

ALTER TABLE Product_V1
ADD CONSTRAINT CK_Product_V1_Quantity CHECK (Quantity >= 0);
GO

PRINT 'Check constraints added successfully';
GO

-- Step 4: Add DEFAULT constraints
ALTER TABLE Product_V1
ADD CONSTRAINT DF_Product_V1_IsActive DEFAULT 1 FOR IsActive;
GO

ALTER TABLE Product_V1
ADD CONSTRAINT DF_Product_V1_CreatedDate DEFAULT GETDATE() FOR CreatedDate;
GO

PRINT 'Default constraints added successfully';
GO

-- Step 5: Add NOT NULL constraints
-- Note: Must ensure column has no NULLs first
UPDATE Product_V1 SET ProductName = 'Unknown' WHERE ProductName IS NULL;
UPDATE Product_V1 SET SKU = 'UNK-' + CAST(ProductID AS VARCHAR(10)) WHERE SKU IS NULL;
GO

ALTER TABLE Product_V1
ALTER COLUMN ProductName NVARCHAR(200) NOT NULL;
GO

ALTER TABLE Product_V1
ALTER COLUMN SKU VARCHAR(50) NOT NULL;
GO

PRINT 'NOT NULL constraints added successfully';
GO

-- Verify all constraints
SELECT 
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('Product_V1')
    AND type IN ('PK', 'UQ', 'C', 'D', 'F')
ORDER BY type_desc, name;
GO

/*
OUTPUT:
TableName     ConstraintName                  ConstraintType
------------  ------------------------------  ----------------
Product_V1    CK_Product_V1_Price             CHECK_CONSTRAINT
Product_V1    CK_Product_V1_Quantity          CHECK_CONSTRAINT
Product_V1    DF_Product_V1_CreatedDate       DEFAULT_CONSTRAINT
Product_V1    DF_Product_V1_IsActive          DEFAULT_CONSTRAINT
Product_V1    PK_Product_V1_ProductID         PRIMARY_KEY_CONSTRAINT
Product_V1    UQ_Product_V1_SKU               UNIQUE_CONSTRAINT

All constraints successfully added!
*/

/*
================================================================================
PART 2: ADDING FOREIGN KEY CONSTRAINTS
================================================================================

Foreign keys require referenced table to exist first.
*/

-- Create referenced tables
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Supplier;
GO

CREATE TABLE Category (
    CategoryID INT PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE Supplier (
    SupplierID INT PRIMARY KEY,
    SupplierName NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(100)
);
GO

-- Insert reference data
INSERT INTO Category (CategoryID, CategoryName)
VALUES (1, 'Electronics'), (2, 'Accessories'), (3, 'Software');

INSERT INTO Supplier (SupplierID, SupplierName, ContactEmail)
VALUES 
    (101, 'TechSupply Inc', 'contact@techsupply.com'),
    (102, 'GlobalParts LLC', 'sales@globalparts.com'),
    (103, 'ElectroWorld', 'info@electroworld.com'),
    (104, 'AudioPro', 'orders@audiopro.com');
GO

-- Add foreign key constraints to Product_V1
ALTER TABLE Product_V1
ADD CONSTRAINT FK_Product_V1_Category 
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID);
GO

ALTER TABLE Product_V1
ADD CONSTRAINT FK_Product_V1_Supplier 
    FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID);
GO

PRINT 'Foreign key constraints added successfully';
GO

-- Test foreign key enforcement
BEGIN TRY
    INSERT INTO Product_V1 (ProductName, SKU, Price, Quantity, CategoryID, SupplierID)
    VALUES ('Invalid Product', 'INV-001', 99.99, 10, 999, 101);  -- Invalid CategoryID
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

/*
OUTPUT:
ERROR: The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Product_V1_Category"...

Foreign key working correctly!
*/

/*
================================================================================
PART 3: DROPPING CONSTRAINTS
================================================================================
*/

-- Drop CHECK constraint
ALTER TABLE Product_V1
DROP CONSTRAINT CK_Product_V1_Quantity;
GO

PRINT 'Check constraint dropped';
GO

-- Drop FOREIGN KEY constraint
ALTER TABLE Product_V1
DROP CONSTRAINT FK_Product_V1_Supplier;
GO

PRINT 'Foreign key constraint dropped';
GO

-- Drop DEFAULT constraint
ALTER TABLE Product_V1
DROP CONSTRAINT DF_Product_V1_IsActive;
GO

PRINT 'Default constraint dropped';
GO

-- Drop UNIQUE constraint
ALTER TABLE Product_V1
DROP CONSTRAINT UQ_Product_V1_SKU;
GO

PRINT 'Unique constraint dropped';
GO

-- Note: To drop PRIMARY KEY, must first drop dependent foreign keys
-- Cannot drop: ALTER TABLE Product_V1 DROP CONSTRAINT PK_Product_V1_ProductID;
-- unless all foreign keys referencing it are dropped first

/*
================================================================================
PART 4: MODIFYING CONSTRAINTS
================================================================================

Constraints cannot be modified directly - must drop and recreate.
*/

-- Example: Change CHECK constraint from Price >= 0 to Price > 0
-- Step 1: Drop existing constraint
ALTER TABLE Product_V1
DROP CONSTRAINT CK_Product_V1_Price;
GO

-- Step 2: Create new constraint with new definition
ALTER TABLE Product_V1
ADD CONSTRAINT CK_Product_V1_Price CHECK (Price > 0);  -- Now > instead of >=
GO

PRINT 'Check constraint modified (dropped and recreated)';
GO

-- Test new constraint
BEGIN TRY
    INSERT INTO Product_V1 (ProductName, SKU, Price, Quantity, CategoryID)
    VALUES ('Free Product', 'FREE-001', 0.00, 10, 1);  -- Should fail (Price = 0)
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'Constraint correctly prevents Price = 0';
END CATCH;
GO

-- Example: Change DEFAULT constraint
ALTER TABLE Product_V1
DROP CONSTRAINT DF_Product_V1_CreatedDate;
GO

ALTER TABLE Product_V1
ADD CONSTRAINT DF_Product_V1_CreatedDate DEFAULT SYSDATETIME() FOR CreatedDate;
GO

PRINT 'Default constraint modified (now uses SYSDATETIME instead of GETDATE)';
GO

/*
================================================================================
PART 5: ENABLING AND DISABLING CONSTRAINTS
================================================================================

Temporarily disable constraints for bulk operations, then re-enable.

WHEN TO DISABLE:
----------------
- Bulk data imports
- Data migrations
- ETL processes
- Performance-critical operations

IMPORTANT: Always re-enable after operation!
*/

-- Create test table with constraints
DROP TABLE IF EXISTS OrderDetail;
GO

CREATE TABLE OrderDetail (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_OrderDetail_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_OrderDetail_UnitPrice CHECK (UnitPrice >= 0)
);
GO

-- Disable all CHECK constraints on table
ALTER TABLE OrderDetail
NOCHECK CONSTRAINT ALL;
GO

PRINT 'All constraints disabled';
GO

-- Now can insert data that violates constraints (for bulk import)
INSERT INTO OrderDetail (OrderID, ProductID, Quantity, UnitPrice)
VALUES 
    (1, 101, -5, 10.00),   -- Negative quantity (violates constraint)
    (2, 102, 10, -5.00);   -- Negative price (violates constraint)
GO

SELECT * FROM OrderDetail;
GO

/*
OUTPUT:
OrderDetailID  OrderID  ProductID  Quantity  UnitPrice
-------------  -------  ---------  --------  ---------
1              1        101        -5        10.00      (Violates CK_Quantity!)
2              2        102        10        -5.00      (Violates CK_UnitPrice!)

Constraints disabled - invalid data inserted!
*/

-- Re-enable constraints
ALTER TABLE OrderDetail
CHECK CONSTRAINT ALL;
GO

PRINT 'All constraints re-enabled';
GO

-- Try to insert more invalid data (should fail now)
BEGIN TRY
    INSERT INTO OrderDetail (OrderID, ProductID, Quantity, UnitPrice)
    VALUES (3, 103, -10, 20.00);  -- Should fail
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'Constraints working again!';
END CATCH;
GO

-- Disable specific constraint only
ALTER TABLE OrderDetail
NOCHECK CONSTRAINT CK_OrderDetail_Quantity;
GO

-- Re-enable specific constraint
ALTER TABLE OrderDetail
CHECK CONSTRAINT CK_OrderDetail_Quantity;
GO

/*
================================================================================
PART 6: IDENTIFYING CONSTRAINT VIOLATIONS
================================================================================

After re-enabling constraints, existing data may violate rules.
*/

-- Check which constraints are disabled
SELECT 
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType,
    is_disabled AS IsDisabled,
    is_not_trusted AS IsNotTrusted  -- Data may violate constraint
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('OrderDetail')
    AND type IN ('C', 'F')
ORDER BY name;
GO

-- Re-enable with data validation (will fail if violations exist)
BEGIN TRY
    ALTER TABLE OrderDetail
    WITH CHECK CHECK CONSTRAINT ALL;  -- Verify existing data
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot enable constraint - existing data violates rules';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Find violating rows
SELECT 
    OrderDetailID,
    Quantity,
    'Quantity must be > 0' AS ViolationReason
FROM OrderDetail
WHERE Quantity <= 0

UNION ALL

SELECT 
    OrderDetailID,
    UnitPrice,
    'UnitPrice must be >= 0' AS ViolationReason
FROM OrderDetail
WHERE UnitPrice < 0;
GO

/*
OUTPUT:
OrderDetailID  Quantity/Price  ViolationReason
-------------  --------------  -----------------------
1              -5              Quantity must be > 0
2              -5.00           UnitPrice must be >= 0
*/

-- Fix violations
UPDATE OrderDetail SET Quantity = ABS(Quantity) WHERE Quantity <= 0;
UPDATE OrderDetail SET UnitPrice = ABS(UnitPrice) WHERE UnitPrice < 0;
GO

-- Now can enable with validation
ALTER TABLE OrderDetail
WITH CHECK CHECK CONSTRAINT ALL;
GO

PRINT 'Constraints enabled and data validated';
GO

/*
================================================================================
PART 7: CONSTRAINT METADATA QUERIES
================================================================================
*/

-- View all constraints in database
SELECT 
    OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName,
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc AS ConstraintType,
    is_disabled AS IsDisabled,
    is_not_trusted AS IsNotTrusted,
    create_date AS CreatedDate
FROM sys.objects
WHERE type IN ('PK', 'UQ', 'C', 'D', 'F')
    AND OBJECT_NAME(parent_object_id) IN ('Product_V1', 'OrderDetail')
ORDER BY TableName, type_desc, name;
GO

-- View CHECK constraint definitions
SELECT 
    OBJECT_NAME(cc.parent_object_id) AS TableName,
    cc.name AS ConstraintName,
    cc.definition AS ConstraintDefinition,
    COL_NAME(cc.parent_object_id, cc.parent_column_id) AS ColumnName
FROM sys.check_constraints cc
WHERE OBJECT_NAME(cc.parent_object_id) IN ('Product_V1', 'OrderDetail')
ORDER BY TableName, ConstraintName;
GO

-- View DEFAULT constraint definitions
SELECT 
    OBJECT_NAME(dc.parent_object_id) AS TableName,
    dc.name AS ConstraintName,
    dc.definition AS DefaultValue,
    COL_NAME(dc.parent_object_id, dc.parent_column_id) AS ColumnName
FROM sys.default_constraints dc
WHERE OBJECT_NAME(dc.parent_object_id) = 'Product_V1'
ORDER BY ColumnName;
GO

-- View FOREIGN KEY constraints with referenced tables
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.name AS ForeignKeyName,
    COL_NAME(fk.parent_object_id, fkc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fk.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) = 'Product_V1'
ORDER BY fk.name;
GO

-- View PRIMARY KEY and UNIQUE constraints with columns
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS Columns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE OBJECT_NAME(i.object_id) = 'Product_V1'
    AND (i.is_primary_key = 1 OR i.is_unique_constraint = 1)
GROUP BY OBJECT_NAME(i.object_id), i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY i.is_primary_key DESC, i.name;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Add Constraints to Existing Table
----------------------------------------------
Create a table without constraints, then add:
- Primary key
- Unique constraint
- Check constraint
- Default constraint
- Foreign key

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Modify Constraint
------------------------------
Create a CHECK constraint, then modify it to be more restrictive.
Test before and after modification.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Handle Constraint Violations
-----------------------------------------
1. Disable constraints
2. Insert violating data
3. Identify violations
4. Fix violations
5. Re-enable constraints

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Add Constraints to Existing Table
DROP TABLE IF EXISTS Customer_New;
DROP TABLE IF EXISTS CustomerType;
GO

-- Create reference table first
CREATE TABLE CustomerType (
    TypeID INT PRIMARY KEY,
    TypeName NVARCHAR(50) NOT NULL
);

INSERT INTO CustomerType VALUES (1, 'Regular'), (2, 'Premium'), (3, 'VIP');
GO

-- Create main table without constraints
CREATE TABLE Customer_New (
    CustomerID INT IDENTITY(1,1),
    CustomerName NVARCHAR(100),
    Email NVARCHAR(100),
    Phone VARCHAR(20),
    CreditLimit DECIMAL(10,2),
    TypeID INT,
    IsActive BIT,
    RegistrationDate DATE
);
GO

-- Insert sample data
INSERT INTO Customer_New (CustomerName, Email, Phone, CreditLimit, TypeID, IsActive, RegistrationDate)
VALUES 
    ('John Doe', 'john@example.com', '555-0001', 5000.00, 1, 1, '2024-01-15'),
    ('Jane Smith', 'jane@example.com', '555-0002', 10000.00, 2, 1, '2024-01-16');
GO

-- Add primary key
ALTER TABLE Customer_New
ADD CONSTRAINT PK_Customer_New PRIMARY KEY (CustomerID);
GO

-- Add unique constraint
ALTER TABLE Customer_New
ADD CONSTRAINT UQ_Customer_New_Email UNIQUE (Email);
GO

-- Add check constraint
ALTER TABLE Customer_New
ADD CONSTRAINT CK_Customer_New_CreditLimit CHECK (CreditLimit >= 0 AND CreditLimit <= 50000);
GO

-- Add default constraint
ALTER TABLE Customer_New
ADD CONSTRAINT DF_Customer_New_IsActive DEFAULT 1 FOR IsActive;
GO

ALTER TABLE Customer_New
ADD CONSTRAINT DF_Customer_New_RegistrationDate DEFAULT CAST(GETDATE() AS DATE) FOR RegistrationDate;
GO

-- Add foreign key
ALTER TABLE Customer_New
ADD CONSTRAINT FK_Customer_New_CustomerType FOREIGN KEY (TypeID) REFERENCES CustomerType(TypeID);
GO

-- Verify constraints
SELECT 
    name AS ConstraintName,
    type_desc AS ConstraintType
FROM sys.objects
WHERE parent_object_id = OBJECT_ID('Customer_New')
    AND type IN ('PK', 'UQ', 'C', 'D', 'F')
ORDER BY type_desc;
GO

-- Solution 2: Modify Constraint
DROP TABLE IF EXISTS ProductInventory;
GO

CREATE TABLE ProductInventory (
    InventoryID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    ReorderLevel INT NOT NULL
);
GO

-- Initial check constraint (Quantity >= 0)
ALTER TABLE ProductInventory
ADD CONSTRAINT CK_ProductInventory_Quantity CHECK (Quantity >= 0);
GO

-- Test: Can insert 0
INSERT INTO ProductInventory (ProductID, Quantity, ReorderLevel)
VALUES (1, 0, 10);  -- Succeeds
GO

SELECT * FROM ProductInventory;
GO

-- Modify constraint to be more restrictive (Quantity > 0)
ALTER TABLE ProductInventory
DROP CONSTRAINT CK_ProductInventory_Quantity;
GO

ALTER TABLE ProductInventory
ADD CONSTRAINT CK_ProductInventory_Quantity CHECK (Quantity > 0);
GO

-- Test: Cannot insert 0 anymore
BEGIN TRY
    INSERT INTO ProductInventory (ProductID, Quantity, ReorderLevel)
    VALUES (2, 0, 10);  -- Should fail
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'Modified constraint working!';
END CATCH;
GO

-- Solution 3: Handle Constraint Violations
DROP TABLE IF EXISTS SalesOrder;
GO

CREATE TABLE SalesOrder (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    OrderTotal DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_SalesOrder_OrderTotal CHECK (OrderTotal > 0),
    CONSTRAINT CK_SalesOrder_CustomerID CHECK (CustomerID > 0)
);
GO

-- Step 1: Disable constraints
ALTER TABLE SalesOrder NOCHECK CONSTRAINT ALL;
GO

-- Step 2: Insert violating data (bulk import simulation)
INSERT INTO SalesOrder (OrderDate, CustomerID, OrderTotal)
VALUES 
    ('2024-01-15', 100, 500.00),    -- Valid
    ('2024-01-16', -50, 300.00),    -- Invalid CustomerID
    ('2024-01-17', 200, -100.00),   -- Invalid OrderTotal
    ('2024-01-18', -10, -50.00);    -- Both invalid
GO

-- Step 3: Identify violations
SELECT 
    OrderID,
    CustomerID,
    OrderTotal,
    CASE 
        WHEN CustomerID <= 0 AND OrderTotal <= 0 THEN 'Both fields invalid'
        WHEN CustomerID <= 0 THEN 'Invalid CustomerID'
        WHEN OrderTotal <= 0 THEN 'Invalid OrderTotal'
        ELSE 'Valid'
    END AS ViolationType
FROM SalesOrder
WHERE CustomerID <= 0 OR OrderTotal <= 0;
GO

/*
OUTPUT:
OrderID  CustomerID  OrderTotal  ViolationType
-------  ----------  ----------  ---------------------
2        -50         300.00      Invalid CustomerID
3        200         -100.00     Invalid OrderTotal
4        -10         -50.00      Both fields invalid
*/

-- Step 4: Fix violations
UPDATE SalesOrder SET CustomerID = ABS(CustomerID) WHERE CustomerID <= 0;
UPDATE SalesOrder SET OrderTotal = ABS(OrderTotal) WHERE OrderTotal <= 0;
GO

-- Step 5: Re-enable with validation
ALTER TABLE SalesOrder WITH CHECK CHECK CONSTRAINT ALL;
GO

PRINT 'Constraints re-enabled successfully!';
GO

-- Verify all data now valid
SELECT * FROM SalesOrder;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. ADDING CONSTRAINTS
   - Use ALTER TABLE ADD CONSTRAINT
   - Name constraints explicitly
   - Ensure data complies before adding
   - Add in logical order (PK, then FK)

2. DROPPING CONSTRAINTS
   - Use ALTER TABLE DROP CONSTRAINT
   - Drop dependent FKs before dropping PKs
   - Cannot drop constraints with dependencies

3. MODIFYING CONSTRAINTS
   - Cannot modify directly
   - Must drop and recreate
   - Ensure no data violations after recreation
   - Test new constraint definition

4. ENABLING/DISABLING
   - NOCHECK CONSTRAINT - disable temporarily
   - CHECK CONSTRAINT - re-enable
   - ALL keyword for all constraints
   - Always re-enable after bulk operations

5. CONSTRAINT VIOLATIONS
   - WITH CHECK validates existing data
   - Find violations with SELECT queries
   - Fix violations before enabling
   - Use is_not_trusted to identify untrusted constraints

6. METADATA QUERIES
   - sys.objects - all constraints
   - sys.check_constraints - CHECK definitions
   - sys.default_constraints - DEFAULT definitions
   - sys.foreign_keys - FK relationships
   - sys.indexes - PK and UNIQUE constraints

7. BEST PRACTICES
   - Name constraints explicitly
   - Document constraint purposes
   - Test constraints before production
   - Use transactions for multiple changes
   - Monitor constraint violations
   - Keep constraints enabled unless necessary
   - Validate data after re-enabling

8. COMMON SCENARIOS
   - Adding constraints to legacy tables
   - Bulk data imports (disable/enable)
   - Data migrations
   - Changing business rules
   - Performance tuning
   - Schema refactoring

================================================================================

NEXT STEPS:
-----------
In Lesson 13.12, we'll explore PERFORMANCE CONSIDERATIONS:
- Index overhead on DML operations
- Missing index suggestions
- Execution plan analysis
- Index statistics
- Query optimization with indexes

Continue to: 12-performance-considerations.sql

================================================================================
*/
