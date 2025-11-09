/*
================================================================================
LESSON 14.1: WHAT ARE VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand what views are and how they work
2. Differentiate between views and physical tables
3. Create basic views with CREATE VIEW
4. Query views like regular tables
5. Understand view metadata and storage
6. Modify views with ALTER VIEW
7. Drop views with DROP VIEW

Business Context:
-----------------
Views are saved queries that act like virtual tables. They simplify
complex queries, provide security by limiting data access, and create
consistent interfaces for applications. Understanding views is essential
for building maintainable, secure database applications.

Database: RetailStore
Complexity: Beginner
Estimated Time: 30 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT IS A VIEW?
================================================================================

A VIEW is a virtual table based on a SELECT statement. It doesn't store
data itself - it stores the query definition. When you query a view,
SQL Server executes the underlying SELECT statement.

CHARACTERISTICS:
----------------
1. VIRTUAL TABLE: No data storage (except indexed views)
2. SAVED QUERY: Stores SELECT statement, not results
3. SECURITY: Can hide columns and filter rows
4. SIMPLIFICATION: Complex queries appear simple
5. CONSISTENCY: Same query logic everywhere

Visual Representation:
----------------------

PHYSICAL TABLE (Customer):
┌─────────────┬──────────────┬────────────────┬─────────┬────────┐
│ CustomerID  │ CustomerName │ Email          │ Salary  │ SSN    │
├─────────────┼──────────────┼────────────────┼─────────┼────────┤
│ 1           │ John Doe     │ john@email.com │ 75000   │ 123... │
│ 2           │ Jane Smith   │ jane@email.com │ 85000   │ 456... │
└─────────────┴──────────────┴────────────────┴─────────┴────────┘
                                    ↓
                            CREATE VIEW (filter)
                                    ↓
VIEW (CustomerPublicInfo):
┌─────────────┬──────────────┬────────────────┐
│ CustomerID  │ CustomerName │ Email          │  (Salary, SSN hidden)
├─────────────┼──────────────┼────────────────┤
│ 1           │ John Doe     │ john@email.com │
│ 2           │ Jane Smith   │ jane@email.com │
└─────────────┴──────────────┴────────────────┘

*/

-- Create sample tables
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    Salary DECIMAL(10,2),  -- Sensitive data
    SSN VARCHAR(11),  -- Sensitive data
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE)
);
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Category NVARCHAR(50),
    Price DECIMAL(10,2) NOT NULL,
    Cost DECIMAL(10,2),  -- Sensitive data
    Quantity INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID),
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    TotalAmount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending'
);
GO

-- Insert sample data
INSERT INTO Customer (CustomerName, Email, Phone, Salary, SSN, IsActive)
VALUES 
    ('John Doe', 'john@email.com', '555-0101', 75000, '123-45-6789', 1),
    ('Jane Smith', 'jane@email.com', '555-0102', 85000, '234-56-7890', 1),
    ('Bob Johnson', 'bob@email.com', '555-0103', 65000, '345-67-8901', 0),
    ('Alice Williams', 'alice@email.com', '555-0104', 95000, '456-78-9012', 1);
GO

INSERT INTO Product (ProductName, Category, Price, Cost, Quantity, IsActive)
VALUES 
    ('Laptop', 'Electronics', 999.99, 700.00, 50, 1),
    ('Mouse', 'Electronics', 29.99, 15.00, 200, 1),
    ('Keyboard', 'Electronics', 79.99, 45.00, 150, 1),
    ('Monitor', 'Electronics', 299.99, 180.00, 75, 1),
    ('Old Product', 'Electronics', 49.99, 30.00, 0, 0);
GO

INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status)
VALUES 
    (1, '2024-01-15', 1029.98, 'Completed'),
    (1, '2024-02-20', 79.99, 'Completed'),
    (2, '2024-01-18', 299.99, 'Completed'),
    (2, '2024-03-10', 999.99, 'Pending'),
    (4, '2024-03-15', 29.99, 'Shipped');
GO

/*
================================================================================
PART 2: CREATING YOUR FIRST VIEW
================================================================================
*/

-- Example 1: Simple view (hide sensitive columns)
CREATE VIEW CustomerPublicInfo AS
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Phone,
    IsActive,
    CreatedDate
FROM Customer;
-- Salary and SSN not included (security!)
GO

-- Query the view just like a table
SELECT * FROM CustomerPublicInfo;
GO

/*
OUTPUT:
CustomerID  CustomerName    Email              Phone       IsActive  CreatedDate
----------  --------------  -----------------  ----------  --------  -----------
1           John Doe        john@email.com     555-0101    1         2024-01-15
2           Jane Smith      jane@email.com     555-0102    1         2024-01-15
3           Bob Johnson     bob@email.com      555-0103    0         2024-01-15
4           Alice Williams  alice@email.com    555-0104    1         2024-01-15

Sensitive columns (Salary, SSN) are hidden!
*/

-- Example 2: View with filtering (row-level security)
CREATE VIEW ActiveCustomers AS
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Phone
FROM Customer
WHERE IsActive = 1;  -- Only active customers
GO

SELECT * FROM ActiveCustomers;
GO

/*
OUTPUT:
CustomerID  CustomerName    Email              Phone
----------  --------------  -----------------  ----------
1           John Doe        john@email.com     555-0101
2           Jane Smith      jane@email.com     555-0102
4           Alice Williams  alice@email.com    555-0104

Bob Johnson (IsActive = 0) is filtered out!
*/

-- Example 3: View with calculated columns
CREATE VIEW ProductWithMargin AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    Cost,
    (Price - Cost) AS Profit,
    CAST(((Price - Cost) / Price) * 100 AS DECIMAL(5,2)) AS MarginPercent
FROM Product;
GO

SELECT * FROM ProductWithMargin;
GO

/*
OUTPUT:
ProductID  ProductName  Category     Price    Cost    Profit  MarginPercent
---------  -----------  -----------  -------  ------  ------  -------------
1          Laptop       Electronics  999.99   700.00  299.99  30.00
2          Mouse        Electronics  29.99    15.00   14.99   50.00
3          Keyboard     Electronics  79.99    45.00   34.99   43.75
4          Monitor      Electronics  299.99   180.00  119.99  40.00
5          Old Product  Electronics  49.99    30.00   19.99   40.01

Calculated columns added on-the-fly!
*/

/*
================================================================================
PART 3: VIEWS VS TABLES
================================================================================

VIEWS:
------
✓ Virtual (no data storage*)
✓ Dynamic (always current data)
✓ Can simplify complex queries
✓ Security layer
✓ No indexes (except indexed views)
✗ Cannot have constraints
✗ May have performance overhead

TABLES:
-------
✓ Physical storage
✓ Can have indexes
✓ Can have constraints
✓ Direct data access
✗ Takes up disk space
✗ Must manage updates

*Except indexed/materialized views
*/

-- Demonstrate dynamic nature of views
PRINT 'Before INSERT:';
SELECT * FROM ActiveCustomers;
GO

-- Insert new customer
INSERT INTO Customer (CustomerName, Email, IsActive)
VALUES ('New Customer', 'new@email.com', 1);
GO

PRINT 'After INSERT:';
SELECT * FROM ActiveCustomers;
GO

/*
OUTPUT (After INSERT):
CustomerID  CustomerName    Email              Phone
----------  --------------  -----------------  ----------
1           John Doe        john@email.com     555-0101
2           Jane Smith      jane@email.com     555-0102
4           Alice Williams  alice@email.com    555-0104
5           New Customer    new@email.com      NULL

View automatically includes new data (no refresh needed)!
*/

/*
================================================================================
PART 4: VIEWING VIEW METADATA
================================================================================
*/

-- List all views in database
SELECT 
    name AS ViewName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.views
ORDER BY name;
GO

/*
OUTPUT:
ViewName               CreatedDate          ModifiedDate
---------------------  -------------------  -------------------
ActiveCustomers        2024-01-15 10:00:00  2024-01-15 10:00:00
CustomerPublicInfo     2024-01-15 09:55:00  2024-01-15 09:55:00
ProductWithMargin      2024-01-15 10:05:00  2024-01-15 10:05:00
*/

-- View columns
SELECT 
    TABLE_NAME AS ViewName,
    COLUMN_NAME AS ColumnName,
    DATA_TYPE AS DataType,
    IS_NULLABLE AS IsNullable
FROM INFORMATION_SCHEMA.VIEW_COLUMN_USAGE
WHERE TABLE_NAME = 'CustomerPublicInfo'
ORDER BY ORDINAL_POSITION;
GO

-- View definition (see the SELECT statement)
EXEC sp_helptext 'CustomerPublicInfo';
GO

/*
OUTPUT:
CREATE VIEW CustomerPublicInfo AS
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Phone,
    IsActive,
    CreatedDate
FROM Customer;
*/

-- Alternative: OBJECT_DEFINITION function
SELECT OBJECT_DEFINITION(OBJECT_ID('CustomerPublicInfo')) AS ViewDefinition;
GO

-- View dependencies (what tables does view use?)
SELECT 
    OBJECT_NAME(referencing_id) AS ViewName,
    OBJECT_NAME(referenced_id) AS ReferencedTable
FROM sys.sql_expression_dependencies
WHERE referencing_id = OBJECT_ID('CustomerPublicInfo');
GO

/*
OUTPUT:
ViewName            ReferencedTable
------------------  ---------------
CustomerPublicInfo  Customer
*/

/*
================================================================================
PART 5: MODIFYING VIEWS
================================================================================
*/

-- Alter existing view (change definition)
ALTER VIEW CustomerPublicInfo AS
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Phone,
    IsActive,
    CreatedDate,
    DATEDIFF(DAY, CreatedDate, CAST(GETDATE() AS DATE)) AS DaysSinceCreated  -- New column!
FROM Customer;
GO

-- Query modified view
SELECT * FROM CustomerPublicInfo;
GO

/*
OUTPUT:
CustomerID  CustomerName    Email              IsActive  CreatedDate  DaysSinceCreated
----------  --------------  -----------------  --------  -----------  ----------------
1           John Doe        john@email.com     1         2024-01-15   0
2           Jane Smith      jane@email.com     1         2024-01-15   0
...

New calculated column added!
*/

-- Create or alter (SQL Server 2016+)
CREATE OR ALTER VIEW ActiveProducts AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    Quantity
FROM Product
WHERE IsActive = 1;
GO

/*
================================================================================
PART 6: DROPPING VIEWS
================================================================================
*/

-- Drop a single view
DROP VIEW IF EXISTS ProductWithMargin;
GO

-- Drop multiple views
DROP VIEW IF EXISTS CustomerPublicInfo, ActiveCustomers, ActiveProducts;
GO

-- Verify views dropped
SELECT name FROM sys.views WHERE name IN ('CustomerPublicInfo', 'ActiveCustomers', 'ProductWithMargin');
GO

/*
OUTPUT:
(No rows - all views dropped)
*/

/*
================================================================================
PART 7: ADVANCED VIEW FEATURES (PREVIEW)
================================================================================
*/

-- WITH ENCRYPTION: Hide view definition
CREATE VIEW EmployeeSalaryInfo
WITH ENCRYPTION AS
SELECT 
    CustomerID,  -- Using Customer table as example
    CustomerName,
    Salary
FROM Customer;
GO

-- Try to view encrypted definition
EXEC sp_helptext 'EmployeeSalaryInfo';
GO

/*
OUTPUT:
The text for object 'EmployeeSalaryInfo' is encrypted.

Definition is hidden from users!
*/

-- WITH SCHEMABINDING: Bind view to schema
CREATE VIEW BoundCustomers
WITH SCHEMABINDING AS
SELECT 
    CustomerID,
    CustomerName,
    Email
FROM dbo.Customer;  -- Must use schema prefix with SCHEMABINDING
GO

/*
Now cannot drop or alter Customer table without dropping view first!
Ensures view won't break.
*/

-- WITH CHECK OPTION: Enforce WHERE clause on updates
CREATE VIEW HighValueCustomers AS
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Salary
FROM Customer
WHERE Salary > 70000
WITH CHECK OPTION;  -- Prevents updates that violate WHERE clause
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Create Simple View
-------------------------------
Create a view named 'ProductCatalog' that shows:
- ProductID
- ProductName
- Category
- Price
- Availability status (In Stock if Quantity > 0, else Out of Stock)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: View with Filtering
--------------------------------
Create a view named 'RecentOrders' that shows orders from the last 30 days
Include: OrderID, CustomerName, OrderDate, TotalAmount, Status

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Modify View
-----------------------
Alter the 'RecentOrders' view to also include the number of days since order

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Create Simple View
CREATE VIEW ProductCatalog AS
SELECT 
    ProductID,
    ProductName,
    Category,
    Price,
    CASE 
        WHEN Quantity > 0 THEN 'In Stock'
        ELSE 'Out of Stock'
    END AS AvailabilityStatus
FROM Product;
GO

SELECT * FROM ProductCatalog;
GO

/*
OUTPUT:
ProductID  ProductName  Category     Price    AvailabilityStatus
---------  -----------  -----------  -------  ------------------
1          Laptop       Electronics  999.99   In Stock
2          Mouse        Electronics  29.99    In Stock
3          Keyboard     Electronics  79.99    In Stock
4          Monitor      Electronics  299.99   In Stock
5          Old Product  Electronics  49.99    Out of Stock
*/

-- Solution 2: View with Filtering
CREATE VIEW RecentOrders AS
SELECT 
    o.OrderID,
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount,
    o.Status
FROM Orders o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
GO

SELECT * FROM RecentOrders;
GO

-- Solution 3: Modify View
ALTER VIEW RecentOrders AS
SELECT 
    o.OrderID,
    c.CustomerName,
    o.OrderDate,
    o.TotalAmount,
    o.Status,
    DATEDIFF(DAY, o.OrderDate, CAST(GETDATE() AS DATE)) AS DaysSinceOrder
FROM Orders o
INNER JOIN Customer c ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
GO

SELECT * FROM RecentOrders ORDER BY DaysSinceOrder;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. WHAT ARE VIEWS?
   - Virtual tables (saved SELECT statements)
   - No data storage (except indexed views)
   - Always show current data
   - Query like regular tables

2. CREATING VIEWS
   - CREATE VIEW viewname AS SELECT...
   - Can filter rows (WHERE clause)
   - Can hide columns
   - Can add calculated columns

3. MODIFYING VIEWS
   - ALTER VIEW to change definition
   - DROP VIEW to remove
   - CREATE OR ALTER for flexibility

4. VIEW METADATA
   - sys.views - list all views
   - sp_helptext - view definition
   - OBJECT_DEFINITION - get definition
   - sys.sql_expression_dependencies - dependencies

5. VIEWS VS TABLES
   - Views: Virtual, dynamic, no storage
   - Tables: Physical, static, disk storage
   - Views ideal for security and simplification

6. ADVANCED OPTIONS
   - WITH ENCRYPTION: Hide definition
   - WITH SCHEMABINDING: Lock schema
   - WITH CHECK OPTION: Enforce WHERE on updates

7. BEST PRACTICES
   - Use views for security
   - Simplify complex queries
   - Provide consistent interfaces
   - Don't over-nest views (2-3 levels max)
   - Name clearly (vw_ prefix optional)

8. WHEN TO USE VIEWS
   - Hide sensitive columns
   - Filter rows for security
   - Simplify complex joins
   - Provide consistent data access
   - Support legacy applications

================================================================================

NEXT STEPS:
-----------
In Lesson 14.2, we'll explore WHY USE VIEWS:
- Simplifying complex queries
- Supporting multiple perspectives
- Enhancing maintainability
- Real-world use cases

Continue to: 02-why-use-views.md

================================================================================
*/
