/*
================================================================================
LESSON 13.5: FOREIGN KEY CONSTRAINTS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand referential integrity and foreign keys
2. Create foreign key relationships between tables
3. Use CASCADE options (DELETE, UPDATE)
4. Implement self-referencing foreign keys
5. Handle foreign key violations and errors
6. Modify and manage foreign key constraints
7. Design efficient foreign key strategies

Business Context:
-----------------
In a retail database, orders reference customers, order details reference
products, and employees reference departments. Foreign keys ensure these
relationships remain valid - you can't have an order for a non-existent
customer or a product reference pointing to nothing. This maintains data
integrity across the entire database.

Database: RetailStore
Complexity: Beginner to Intermediate
Estimated Time: 50 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT IS A FOREIGN KEY?
================================================================================

A FOREIGN KEY is a constraint that creates a relationship between two tables
by ensuring values in one table match values in another table's primary key.

CHARACTERISTICS:
----------------
1. REFERENTIAL INTEGRITY: Ensures related records exist in parent table
2. PREVENTS ORPHANS: Can't have child records without parent
3. CASCADE OPTIONS: Can automatically update/delete related records
4. MULTIPLE ALLOWED: Table can have many foreign keys
5. CAN BE NULL: Unless also marked NOT NULL
6. INDEXED AUTOMATICALLY: In some databases (not SQL Server - must create manually)

Visual Representation:
----------------------
PARENT TABLE (Customer)          CHILD TABLE (Order)
CustomerID (PK)  Name            OrderID (PK)  CustomerID (FK)  Amount
---------------  ------          ------------  ---------------  ------
1                John            100           1 ✅             $150
2                Jane            101           2 ✅             $200
3                Bob             102           1 ✅             $75
                                 103           99 ❌ ERROR!     $300

Order 103 references CustomerID 99, which doesn't exist in Customer table.
Foreign key constraint prevents this invalid reference.

*/

-- First, let's create parent and child tables
DROP TABLE IF EXISTS [Order];  -- Child table (must drop first due to FK)
DROP TABLE IF EXISTS Customer;  -- Parent table
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(20),
    CONSTRAINT PK_Customer PRIMARY KEY (CustomerID)
);
GO

CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) NOT NULL,
    CustomerID INT NOT NULL,  -- Foreign key column
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    Status VARCHAR(20),
    CONSTRAINT PK_Order PRIMARY KEY (OrderID),
    CONSTRAINT FK_Order_Customer FOREIGN KEY (CustomerID) 
        REFERENCES Customer(CustomerID)  -- Creates relationship
);
GO

-- Insert customers (parent records)
INSERT INTO Customer (FirstName, LastName, Email, Phone)
VALUES 
    ('John', 'Doe', 'john@example.com', '555-1001'),
    ('Jane', 'Smith', 'jane@example.com', '555-1002'),
    ('Bob', 'Johnson', 'bob@example.com', '555-1003');
GO

SELECT * FROM Customer;
GO

/*
OUTPUT:
CustomerID  FirstName  LastName  Email               Phone
----------  ---------  --------  ------------------  ---------
1           John       Doe       john@example.com    555-1001
2           Jane       Smith     jane@example.com    555-1002
3           Bob        Johnson   bob@example.com     555-1003
*/

-- Insert valid orders (CustomerID exists in Customer table)
INSERT INTO [Order] (CustomerID, TotalAmount, Status)
VALUES 
    (1, 150.00, 'Completed'),  -- References Customer 1 ✅
    (2, 200.00, 'Pending'),    -- References Customer 2 ✅
    (1, 75.00, 'Shipped');     -- References Customer 1 ✅
GO

SELECT * FROM [Order];
GO

/*
OUTPUT:
OrderID  CustomerID  OrderDate            TotalAmount  Status
-------  ----------  -------------------  -----------  ---------
1        1           2024-01-15 10:30:00  150.00       Completed
2        2           2024-01-15 10:30:00  200.00       Pending
3        1           2024-01-15 10:30:00  75.00        Shipped

All orders reference valid customers.
*/

-- Try to insert order with invalid CustomerID
INSERT INTO [Order] (CustomerID, TotalAmount, Status)
VALUES (99, 300.00, 'Pending');  -- Customer 99 doesn't exist!
GO

/*
ERROR:
The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Order_Customer".
The conflict occurred in database "RetailStore", table "dbo.Customer", column 'CustomerID'.

EXPLANATION:
Foreign key constraint prevents inserting an order for a non-existent customer.
This maintains referential integrity!
*/

-- Correct insert
INSERT INTO [Order] (CustomerID, TotalAmount, Status)
VALUES (3, 300.00, 'Pending');  -- Customer 3 exists ✅
GO

/*
SUCCESS: Customer 3 (Bob Johnson) exists in Customer table.
*/

/*
================================================================================
PART 2: CREATING FOREIGN KEY CONSTRAINTS
================================================================================

Multiple syntaxes for creating foreign keys.
*/

-- Method 1: Inline column constraint
DROP TABLE IF EXISTS Method1_Child;
GO

CREATE TABLE Method1_Child (
    ChildID INT PRIMARY KEY,
    ParentID INT FOREIGN KEY REFERENCES Customer(CustomerID)  -- Inline FK
);
GO

-- Method 2: Inline column constraint with constraint name
DROP TABLE IF EXISTS Method2_Child;
GO

CREATE TABLE Method2_Child (
    ChildID INT PRIMARY KEY,
    ParentID INT CONSTRAINT FK_Method2_Parent 
        FOREIGN KEY REFERENCES Customer(CustomerID)  -- Named inline FK
);
GO

-- Method 3: Table-level constraint (RECOMMENDED)
DROP TABLE IF EXISTS Method3_Child;
GO

CREATE TABLE Method3_Child (
    ChildID INT PRIMARY KEY,
    ParentID INT NOT NULL,
    CONSTRAINT FK_Method3_Parent 
        FOREIGN KEY (ParentID) REFERENCES Customer(CustomerID)
);
GO

-- Method 4: Add foreign key to existing table
DROP TABLE IF EXISTS Method4_Child;
GO

CREATE TABLE Method4_Child (
    ChildID INT PRIMARY KEY,
    ParentID INT NOT NULL
);
GO

-- Add FK after table creation
ALTER TABLE Method4_Child
ADD CONSTRAINT FK_Method4_Parent 
    FOREIGN KEY (ParentID) REFERENCES Customer(CustomerID);
GO

/*
BEST PRACTICE:
- Use Method 3 or 4 (table-level constraint with name)
- Always name your foreign keys: FK_ChildTable_ParentTable
- Makes it easy to identify and manage relationships
*/

-- View all foreign keys
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) LIKE 'Method%'
   OR OBJECT_NAME(fk.parent_object_id) = 'Order'
ORDER BY ChildTable;
GO

/*
OUTPUT:
ForeignKeyName         ChildTable      ChildColumn  ParentTable  ParentColumn
--------------------   -------------   -----------  -----------  ------------
FK_Method1...          Method1_Child   ParentID     Customer     CustomerID
FK_Method2_Parent      Method2_Child   ParentID     Customer     CustomerID
FK_Method3_Parent      Method3_Child   ParentID     Customer     CustomerID
FK_Method4_Parent      Method4_Child   ParentID     Customer     CustomerID
FK_Order_Customer      Order           CustomerID   Customer     CustomerID
*/

/*
================================================================================
PART 3: FOREIGN KEY RESTRICTIONS
================================================================================

Foreign keys enforce referential integrity with restrictions on both
parent and child tables.
*/

-- Restriction 1: Can't delete parent row if child rows exist
DELETE FROM Customer WHERE CustomerID = 1;
GO

/*
ERROR:
The DELETE statement conflicted with the REFERENCE constraint "FK_Order_Customer".
The conflict occurred in database "RetailStore", table "dbo.Order", column 'CustomerID'.

EXPLANATION:
Customer 1 has orders (OrderID 1 and 3).
Can't delete customer while orders reference them.
*/

-- To delete parent, must delete children first
DELETE FROM [Order] WHERE CustomerID = 1;
DELETE FROM Customer WHERE CustomerID = 1;
GO

/*
SUCCESS: First deleted child records, then parent.
*/

-- Restore deleted data for next examples
INSERT INTO Customer (FirstName, LastName, Email, Phone)
VALUES ('John', 'Doe', 'john@example.com', '555-1001');

INSERT INTO [Order] (CustomerID, TotalAmount, Status)
VALUES 
    ((SELECT MAX(CustomerID) FROM Customer), 150.00, 'Completed'),
    ((SELECT MAX(CustomerID) FROM Customer), 75.00, 'Shipped');
GO

-- Restriction 2: Can't update parent PK if child rows reference it
UPDATE Customer 
SET CustomerID = 999 
WHERE CustomerID = 2;
GO

/*
ERROR:
The UPDATE statement conflicted with the REFERENCE constraint "FK_Order_Customer".

EXPLANATION:
Customer 2 is referenced by Order 2.
Can't change parent key while children reference it.
*/

-- Restriction 3: Child FK value must exist in parent or be NULL
-- (We already saw this with INSERT)

-- NULL foreign keys ARE allowed (unless NOT NULL constraint)
DROP TABLE IF EXISTS OptionalParent;
GO

CREATE TABLE OptionalParent (
    ChildID INT PRIMARY KEY,
    ParentID INT NULL,  -- NULL allowed (optional relationship)
    CONSTRAINT FK_OptionalParent 
        FOREIGN KEY (ParentID) REFERENCES Customer(CustomerID)
);
GO

-- This works - ParentID can be NULL
INSERT INTO OptionalParent (ChildID, ParentID)
VALUES 
    (1, 2),     -- References Customer 2 ✅
    (2, NULL),  -- NULL is allowed ✅
    (3, NULL);  -- Multiple NULLs allowed ✅
GO

SELECT * FROM OptionalParent;
GO

/*
OUTPUT:
ChildID  ParentID
-------  --------
1        2
2        NULL
3        NULL

NULL foreign keys are valid (represents "no parent" or "unknown parent").
*/

/*
================================================================================
PART 4: CASCADE OPTIONS
================================================================================

CASCADE options automatically perform actions on child records when
parent records are modified or deleted.

Options:
--------
ON DELETE CASCADE: Automatically delete child rows when parent is deleted
ON UPDATE CASCADE: Automatically update child FK when parent PK changes
ON DELETE SET NULL: Set child FK to NULL when parent is deleted
ON UPDATE SET NULL: Set child FK to NULL when parent PK changes
ON DELETE SET DEFAULT: Set child FK to DEFAULT when parent is deleted
ON UPDATE SET DEFAULT: Set child FK to DEFAULT when parent PK changes
NO ACTION (default): Prevent parent modification if children exist

*/

-- Example 1: ON DELETE CASCADE
-- When customer is deleted, automatically delete their orders

DROP TABLE IF EXISTS OrderWithCascade;
GO

CREATE TABLE OrderWithCascade (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    CONSTRAINT FK_OrderCascade_Customer 
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON DELETE CASCADE  -- Automatically delete orders when customer deleted
);
GO

-- Insert test data
INSERT INTO Customer (FirstName, LastName, Email)
VALUES ('Test', 'User', 'test@example.com');

DECLARE @TestCustomerID INT = SCOPE_IDENTITY();

INSERT INTO OrderWithCascade (CustomerID, TotalAmount)
VALUES 
    (@TestCustomerID, 100.00),
    (@TestCustomerID, 200.00),
    (@TestCustomerID, 150.00);
GO

-- Check orders for test customer
SELECT * FROM OrderWithCascade WHERE CustomerID = (SELECT MAX(CustomerID) FROM Customer);
GO

/*
OUTPUT:
OrderID  CustomerID  OrderDate            TotalAmount
-------  ----------  -------------------  -----------
4        4           2024-01-15 11:00:00  100.00
5        4           2024-01-15 11:00:00  200.00
6        4           2024-01-15 11:00:00  150.00

Test customer (ID 4) has 3 orders.
*/

-- Delete customer - CASCADE will automatically delete orders!
DELETE FROM Customer WHERE FirstName = 'Test' AND LastName = 'User';
GO

-- Check if orders were automatically deleted
SELECT * FROM OrderWithCascade WHERE CustomerID = 4;
GO

/*
OUTPUT:
(0 rows)

AMAZING! All 3 orders were automatically deleted when customer was deleted.
This is the power of ON DELETE CASCADE!
*/

-- Example 2: ON DELETE SET NULL
-- When customer is deleted, set order's CustomerID to NULL (orphaned orders)

DROP TABLE IF EXISTS OrderWithSetNull;
GO

CREATE TABLE OrderWithSetNull (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NULL,  -- Must allow NULL for SET NULL to work
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    CONSTRAINT FK_OrderSetNull_Customer 
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON DELETE SET NULL  -- Set to NULL when customer deleted
);
GO

-- Insert test data
INSERT INTO Customer (FirstName, LastName, Email)
VALUES ('Another', 'Test', 'another@example.com');

DECLARE @AnotherCustomerID INT = SCOPE_IDENTITY();

INSERT INTO OrderWithSetNull (CustomerID, TotalAmount)
VALUES 
    (@AnotherCustomerID, 250.00),
    (@AnotherCustomerID, 175.00);
GO

SELECT * FROM OrderWithSetNull;
GO

/*
OUTPUT:
OrderID  CustomerID  OrderDate            TotalAmount
-------  ----------  -------------------  -----------
1        5           2024-01-15 11:10:00  250.00
2        5           2024-01-15 11:10:00  175.00
*/

-- Delete customer
DELETE FROM Customer WHERE FirstName = 'Another';
GO

-- Check orders - CustomerID should be NULL now
SELECT * FROM OrderWithSetNull;
GO

/*
OUTPUT:
OrderID  CustomerID  OrderDate            TotalAmount
-------  ----------  -------------------  -----------
1        NULL        2024-01-15 11:10:00  250.00
2        NULL        2024-01-15 11:10:00  175.00

Orders still exist, but CustomerID set to NULL (orphaned orders).
Use this when you need to preserve historical records.
*/

-- Example 3: ON UPDATE CASCADE
-- When customer's ID changes, automatically update orders

DROP TABLE IF EXISTS OrderWithUpdateCascade;
GO

CREATE TABLE OrderWithUpdateCascade (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2),
    CONSTRAINT FK_OrderUpdateCascade_Customer 
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON UPDATE CASCADE  -- Update FK when parent PK changes
);
GO

-- Insert test data
INSERT INTO Customer (FirstName, LastName, Email)
VALUES ('Update', 'Test', 'update@example.com');

DECLARE @UpdateCustomerID INT = SCOPE_IDENTITY();

INSERT INTO OrderWithUpdateCascade (CustomerID, TotalAmount)
VALUES 
    (@UpdateCustomerID, 300.00),
    (@UpdateCustomerID, 400.00);
GO

SELECT 'Before Update' AS Stage, * FROM OrderWithUpdateCascade 
WHERE CustomerID = (SELECT MAX(CustomerID) FROM Customer);
GO

/*
OUTPUT:
Stage          OrderID  CustomerID  TotalAmount
-------------  -------  ----------  -----------
Before Update  1        6           300.00
Before Update  2        6           400.00

CustomerID is 6.
*/

-- Update customer's ID (not recommended in practice, but demonstrates cascade)
UPDATE Customer 
SET CustomerID = 1000 
WHERE FirstName = 'Update' AND LastName = 'Test';
GO

-- Check orders - CustomerID should be updated to 1000
SELECT 'After Update' AS Stage, * FROM OrderWithUpdateCascade 
WHERE CustomerID = 1000;
GO

/*
OUTPUT:
Stage         OrderID  CustomerID  TotalAmount
------------  -------  ----------  -----------
After Update  1        1000        300.00
After Update  2        1000        400.00

CustomerID automatically updated from 6 to 1000!
*/

/*
WARNING ABOUT UPDATE CASCADE:
While powerful, ON UPDATE CASCADE is rarely used in practice because:
- Primary keys should be immutable (never change)
- Changing PKs can cause performance issues
- Can lead to complex cascading updates across many tables

Use surrogate keys (IDENTITY) which never change instead!
*/

/*
================================================================================
PART 5: MULTI-COLUMN FOREIGN KEYS
================================================================================

Foreign keys can reference composite primary keys.
*/

-- Create parent table with composite primary key
DROP TABLE IF EXISTS ProductPrice;
GO

CREATE TABLE ProductPrice (
    ProductID INT NOT NULL,
    EffectiveDate DATE NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_ProductPrice PRIMARY KEY (ProductID, EffectiveDate)
);
GO

-- Create child table with multi-column foreign key
DROP TABLE IF EXISTS SalesTransaction;
GO

CREATE TABLE SalesTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    PriceEffectiveDate DATE NOT NULL,
    Quantity INT NOT NULL,
    TransactionDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Sales_ProductPrice 
        FOREIGN KEY (ProductID, PriceEffectiveDate)
        REFERENCES ProductPrice(ProductID, EffectiveDate)
);
GO

-- Insert product prices
INSERT INTO ProductPrice (ProductID, EffectiveDate, Price)
VALUES 
    (101, '2024-01-01', 29.99),
    (101, '2024-02-01', 34.99),  -- Price increase
    (102, '2024-01-01', 49.99);
GO

-- Insert valid sales transactions
INSERT INTO SalesTransaction (ProductID, PriceEffectiveDate, Quantity)
VALUES 
    (101, '2024-01-01', 5),  -- Valid: Product 101, price from 2024-01-01
    (101, '2024-02-01', 3),  -- Valid: Product 101, price from 2024-02-01
    (102, '2024-01-01', 2);  -- Valid: Product 102, price from 2024-01-01
GO

SELECT * FROM SalesTransaction;
GO

/*
OUTPUT:
TransactionID  ProductID  PriceEffectiveDate  Quantity  TransactionDate
-------------  ---------  ------------------  --------  -------------------
1              101        2024-01-01          5         2024-01-15 11:30:00
2              101        2024-02-01          3         2024-01-15 11:30:00
3              102        2024-01-01          2         2024-01-15 11:30:00

All transactions reference valid (ProductID, EffectiveDate) combinations.
*/

-- Try invalid combination
INSERT INTO SalesTransaction (ProductID, PriceEffectiveDate, Quantity)
VALUES (101, '2024-03-01', 10);  -- Price for this date doesn't exist
GO

/*
ERROR:
The INSERT statement conflicted with the FOREIGN KEY constraint.

EXPLANATION:
(101, '2024-03-01') doesn't exist in ProductPrice table.
*/

/*
================================================================================
PART 6: SELF-REFERENCING FOREIGN KEYS
================================================================================

A table can have a foreign key that references its own primary key.
Common for hierarchical data (organizational charts, categories, etc.)
*/

-- Example: Employee hierarchy (manager relationship)
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    ManagerID INT NULL,  -- References EmployeeID in same table
    Title NVARCHAR(50),
    CONSTRAINT FK_Employee_Manager 
        FOREIGN KEY (ManagerID) REFERENCES Employee(EmployeeID)
);
GO

-- Insert CEO (no manager)
INSERT INTO Employee (FirstName, LastName, ManagerID, Title)
VALUES ('Alice', 'CEO', NULL, 'Chief Executive Officer');  -- Top of hierarchy
GO

-- Insert managers reporting to CEO
INSERT INTO Employee (FirstName, LastName, ManagerID, Title)
VALUES 
    ('Bob', 'Manager1', 1, 'VP of Engineering'),  -- Reports to Alice (ID 1)
    ('Carol', 'Manager2', 1, 'VP of Sales');      -- Reports to Alice (ID 1)
GO

-- Insert employees reporting to managers
INSERT INTO Employee (FirstName, LastName, ManagerID, Title)
VALUES 
    ('David', 'Employee1', 2, 'Senior Developer'),  -- Reports to Bob (ID 2)
    ('Eve', 'Employee2', 2, 'Developer'),           -- Reports to Bob (ID 2)
    ('Frank', 'Employee3', 3, 'Sales Rep');         -- Reports to Carol (ID 3)
GO

-- View the hierarchy
SELECT 
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS EmployeeName,
    e.Title,
    e.ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName
FROM Employee e
LEFT JOIN Employee m ON e.ManagerID = m.EmployeeID
ORDER BY e.EmployeeID;
GO

/*
OUTPUT:
EmployeeID  EmployeeName    Title                   ManagerID  ManagerName
----------  --------------  ----------------------  ---------  -----------
1           Alice CEO       Chief Executive Officer NULL       NULL
2           Bob Manager1    VP of Engineering       1          Alice CEO
3           Carol Manager2  VP of Sales             1          Alice CEO
4           David Employee1 Senior Developer        2          Bob Manager1
5           Eve Employee2   Developer               2          Bob Manager1
6           Frank Employee3 Sales Rep               3          Carol Manager2

Visual Hierarchy:
Alice CEO (CEO)
├── Bob Manager1 (VP Engineering)
│   ├── David Employee1 (Senior Developer)
│   └── Eve Employee2 (Developer)
└── Carol Manager2 (VP Sales)
    └── Frank Employee3 (Sales Rep)
*/

-- Example: Category hierarchy
DROP TABLE IF EXISTS Category;
GO

CREATE TABLE Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL,
    ParentCategoryID INT NULL,  -- References CategoryID
    CONSTRAINT FK_Category_Parent 
        FOREIGN KEY (ParentCategoryID) REFERENCES Category(CategoryID)
);
GO

-- Insert root categories (no parent)
INSERT INTO Category (CategoryName, ParentCategoryID)
VALUES 
    ('Electronics', NULL),
    ('Clothing', NULL);
GO

-- Insert subcategories
INSERT INTO Category (CategoryName, ParentCategoryID)
VALUES 
    ('Computers', 1),    -- Under Electronics
    ('Smartphones', 1),  -- Under Electronics
    ('Men', 2),          -- Under Clothing
    ('Women', 2);        -- Under Clothing
GO

-- Insert sub-subcategories
INSERT INTO Category (CategoryName, ParentCategoryID)
VALUES 
    ('Laptops', 3),      -- Under Computers
    ('Desktops', 3),     -- Under Computers
    ('Shirts', 5),       -- Under Men
    ('Pants', 5);        -- Under Men
GO

-- View hierarchy
SELECT 
    c.CategoryID,
    c.CategoryName,
    c.ParentCategoryID,
    p.CategoryName AS ParentCategoryName
FROM Category c
LEFT JOIN Category p ON c.ParentCategoryID = p.CategoryID
ORDER BY c.CategoryID;
GO

/*
OUTPUT:
CategoryID  CategoryName  ParentCategoryID  ParentCategoryName
----------  ------------  ----------------  ------------------
1           Electronics   NULL              NULL
2           Clothing      NULL              NULL
3           Computers     1                 Electronics
4           Smartphones   1                 Electronics
5           Men           2                 Clothing
6           Women         2                 Clothing
7           Laptops       3                 Computers
8           Desktops      3                 Computers
9           Shirts        5                 Men
10          Pants         5                 Men

Visual Hierarchy:
Electronics
├── Computers
│   ├── Laptops
│   └── Desktops
└── Smartphones
Clothing
├── Men
│   ├── Shirts
│   └── Pants
└── Women
*/

/*
================================================================================
PART 7: MANAGING FOREIGN KEY CONSTRAINTS
================================================================================

Adding, dropping, disabling, and enabling foreign keys.
*/

-- Drop foreign key
ALTER TABLE [Order]
DROP CONSTRAINT FK_Order_Customer;
GO

/*
SUCCESS: Foreign key constraint removed.
Now Order table can reference non-existent customers (dangerous!).
*/

-- Re-add foreign key
ALTER TABLE [Order]
ADD CONSTRAINT FK_Order_Customer 
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID);
GO

-- Disable foreign key (temporarily suspend enforcement)
ALTER TABLE [Order]
NOCHECK CONSTRAINT FK_Order_Customer;
GO

/*
FK is disabled - can insert invalid data!
Useful for bulk data loads.
*/

-- Insert invalid data while FK is disabled
INSERT INTO [Order] (CustomerID, TotalAmount, Status)
VALUES (9999, 500.00, 'Invalid');  -- Customer 9999 doesn't exist!
GO

/*
SUCCESS (but data is invalid!)
*/

-- Re-enable foreign key
ALTER TABLE [Order]
CHECK CONSTRAINT FK_Order_Customer;
GO

/*
ERROR:
The ALTER TABLE statement conflicted with the FOREIGN KEY constraint.

EXPLANATION:
Can't re-enable FK because invalid data exists (CustomerID 9999).
Must fix data first!
*/

-- Remove invalid data
DELETE FROM [Order] WHERE CustomerID = 9999;
GO

-- Now re-enable FK
ALTER TABLE [Order]
CHECK CONSTRAINT FK_Order_Customer;
GO

/*
SUCCESS: FK re-enabled, all data is valid.
*/

-- Disable all constraints on a table
ALTER TABLE [Order]
NOCHECK CONSTRAINT ALL;
GO

-- Re-enable all constraints
ALTER TABLE [Order]
CHECK CONSTRAINT ALL;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Basic Foreign Key Relationship
------------------------------------------
Create tables for Authors and Books with a foreign key relationship.
Insert data and test referential integrity.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: CASCADE Options
---------------------------
Create tables for Teams and Players with ON DELETE CASCADE.
Test that deleting a team automatically deletes all players.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Self-Referencing Foreign Key
----------------------------------------
Create a table for Tasks with a ParentTaskID (self-referencing).
Build a 3-level hierarchy of tasks.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Basic Foreign Key Relationship
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Author;
GO

CREATE TABLE Author (
    AuthorID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Country NVARCHAR(50)
);
GO

CREATE TABLE Book (
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    AuthorID INT NOT NULL,
    PublishedYear INT,
    Price DECIMAL(10,2),
    CONSTRAINT FK_Book_Author 
        FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID)
);
GO

-- Insert authors
INSERT INTO Author (FirstName, LastName, Country)
VALUES 
    ('J.K.', 'Rowling', 'UK'),
    ('George', 'Orwell', 'UK'),
    ('Ernest', 'Hemingway', 'USA');
GO

-- Insert books
INSERT INTO Book (Title, AuthorID, PublishedYear, Price)
VALUES 
    ('Harry Potter and the Philosopher''s Stone', 1, 1997, 19.99),
    ('1984', 2, 1949, 14.99),
    ('Animal Farm', 2, 1945, 12.99),
    ('The Old Man and the Sea', 3, 1952, 15.99);
GO

-- Test referential integrity - try invalid AuthorID
BEGIN TRY
    INSERT INTO Book (Title, AuthorID, PublishedYear, Price)
    VALUES ('Invalid Book', 999, 2024, 9.99);
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- View books with authors
SELECT 
    b.BookID,
    b.Title,
    a.FirstName + ' ' + a.LastName AS AuthorName,
    b.PublishedYear,
    b.Price
FROM Book b
INNER JOIN Author a ON b.AuthorID = a.AuthorID
ORDER BY b.BookID;
GO

/*
OUTPUT:
BookID  Title                                    AuthorName          PublishedYear  Price
------  --------------------------------------   ------------------  -------------  -----
1       Harry Potter and the Philosopher's Stone J.K. Rowling        1997           19.99
2       1984                                     George Orwell       1949           14.99
3       Animal Farm                              George Orwell       1945           12.99
4       The Old Man and the Sea                  Ernest Hemingway    1952           15.99
*/

-- Solution 2: CASCADE Options
DROP TABLE IF EXISTS Player;
DROP TABLE IF EXISTS Team;
GO

CREATE TABLE Team (
    TeamID INT IDENTITY(1,1) PRIMARY KEY,
    TeamName NVARCHAR(100) NOT NULL,
    City NVARCHAR(50),
    EstablishedYear INT
);
GO

CREATE TABLE Player (
    PlayerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    TeamID INT NOT NULL,
    Position NVARCHAR(50),
    JerseyNumber INT,
    CONSTRAINT FK_Player_Team 
        FOREIGN KEY (TeamID) REFERENCES Team(TeamID)
        ON DELETE CASCADE  -- Auto-delete players when team deleted
);
GO

-- Insert teams
INSERT INTO Team (TeamName, City, EstablishedYear)
VALUES 
    ('Lakers', 'Los Angeles', 1947),
    ('Warriors', 'San Francisco', 1946);
GO

-- Insert players
INSERT INTO Player (FirstName, LastName, TeamID, Position, JerseyNumber)
VALUES 
    ('LeBron', 'James', 1, 'Forward', 23),
    ('Anthony', 'Davis', 1, 'Forward', 3),
    ('Stephen', 'Curry', 2, 'Guard', 30),
    ('Klay', 'Thompson', 2, 'Guard', 11);
GO

SELECT 'Before Delete' AS Stage, * FROM Player;
GO

-- Delete a team - should automatically delete players
DELETE FROM Team WHERE TeamName = 'Lakers';
GO

SELECT 'After Delete' AS Stage, * FROM Player;
GO

/*
OUTPUT Before Delete:
PlayerID  FirstName  LastName  TeamID  Position  JerseyNumber
--------  ---------  --------  ------  --------  ------------
1         LeBron     James     1       Forward   23
2         Anthony    Davis     1       Forward   3
3         Stephen    Curry     2       Guard     30
4         Klay       Thompson  2       Guard     11

OUTPUT After Delete:
PlayerID  FirstName  LastName  TeamID  Position  JerseyNumber
--------  ---------  --------  ------  --------  ------------
3         Stephen    Curry     2       Guard     30
4         Klay       Thompson  2       Guard     11

SUCCESS! Players for Lakers (TeamID 1) were automatically deleted.
*/

-- Solution 3: Self-Referencing Foreign Key
DROP TABLE IF EXISTS Task;
GO

CREATE TABLE Task (
    TaskID INT IDENTITY(1,1) PRIMARY KEY,
    TaskName NVARCHAR(200) NOT NULL,
    ParentTaskID INT NULL,
    Priority INT,
    Status VARCHAR(20),
    CONSTRAINT FK_Task_Parent 
        FOREIGN KEY (ParentTaskID) REFERENCES Task(TaskID)
);
GO

-- Level 1: Main project tasks (no parent)
INSERT INTO Task (TaskName, ParentTaskID, Priority, Status)
VALUES 
    ('Website Redesign', NULL, 1, 'In Progress'),
    ('Mobile App Development', NULL, 2, 'Planning');
GO

-- Level 2: Subtasks
INSERT INTO Task (TaskName, ParentTaskID, Priority, Status)
VALUES 
    ('Homepage Design', 1, 1, 'In Progress'),
    ('Product Pages', 1, 2, 'Not Started'),
    ('iOS Development', 2, 1, 'Planning');
GO

-- Level 3: Sub-subtasks
INSERT INTO Task (TaskName, ParentTaskID, Priority, Status)
VALUES 
    ('Hero Section', 3, 1, 'Completed'),
    ('Navigation Menu', 3, 2, 'In Progress'),
    ('Product List View', 4, 1, 'Not Started'),
    ('Product Detail View', 4, 2, 'Not Started');
GO

-- View hierarchy
SELECT 
    t.TaskID,
    REPLICATE('  ', 
        CASE 
            WHEN t.ParentTaskID IS NULL THEN 0
            WHEN p.ParentTaskID IS NULL THEN 1
            ELSE 2
        END
    ) + t.TaskName AS TaskName,
    t.Priority,
    t.Status,
    t.ParentTaskID,
    p.TaskName AS ParentTaskName
FROM Task t
LEFT JOIN Task p ON t.ParentTaskID = p.TaskID
ORDER BY 
    COALESCE(p.ParentTaskID, t.TaskID), 
    t.ParentTaskID, 
    t.TaskID;
GO

/*
OUTPUT:
TaskID  TaskName                      Priority  Status        ParentTaskID  ParentTaskName
------  ----------------------------  --------  ------------  ------------  ------------------
1       Website Redesign              1         In Progress   NULL          NULL
3         Homepage Design             1         In Progress   1             Website Redesign
6           Hero Section              1         Completed     3             Homepage Design
7           Navigation Menu           2         In Progress   3             Homepage Design
4         Product Pages               2         Not Started   1             Website Redesign
8           Product List View         1         Not Started   4             Product Pages
9           Product Detail View       2         Not Started   4             Product Pages
2       Mobile App Development        2         Planning      NULL          NULL
5         iOS Development             1         Planning      2             Mobile App Development

3-Level Hierarchy:
Website Redesign
├── Homepage Design
│   ├── Hero Section
│   └── Navigation Menu
└── Product Pages
    ├── Product List View
    └── Product Detail View
Mobile App Development
└── iOS Development
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. FOREIGN KEY BASICS
   - Enforces referential integrity
   - Prevents orphaned records
   - Can be NULL (optional relationship)
   - Multiple FKs allowed per table
   - Always name constraints: FK_ChildTable_ParentTable

2. CASCADE OPTIONS
   - ON DELETE CASCADE: Auto-delete children
   - ON UPDATE CASCADE: Auto-update FK values (rarely used)
   - ON DELETE SET NULL: Orphan children (set FK to NULL)
   - NO ACTION (default): Prevent parent changes

3. SELF-REFERENCING FKs
   - Table references its own PK
   - Perfect for hierarchies (org charts, categories)
   - ParentID column references own table's ID

4. MULTI-COLUMN FKs
   - Reference composite primary keys
   - All columns must match parent PK
   - Used for complex relationships

5. MANAGING FKs
   - Can be added/dropped with ALTER TABLE
   - Can be disabled (NOCHECK) for bulk loads
   - Must fix invalid data before re-enabling
   - Drop child FKs before dropping parent tables

6. BEST PRACTICES
   - Always create indexes on FK columns (SQL Server doesn't auto-create)
   - Use CASCADE carefully (can cause unintended deletes)
   - Name constraints for easier management
   - Document FK relationships
   - Consider impact on performance

7. PERFORMANCE
   - Index ALL foreign key columns
   - Large cascade deletes can be slow
   - Disabled FKs speed up bulk loads
   - Monitor FK constraint violations

================================================================================

NEXT STEPS:
-----------
In Lesson 13.6, we'll explore UNIQUE CONSTRAINTS:
- Enforcing uniqueness beyond primary keys
- Unique vs primary key differences
- Composite unique constraints
- Nullable unique constraints

Continue to: 06-unique-constraints.sql

================================================================================
*/
