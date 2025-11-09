/*
================================================================================
LESSON 13.8: DEFAULT CONSTRAINTS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand default constraints and their purpose
2. Create default constraints with static and dynamic values
3. Use functions in default constraints (GETDATE, NEWID, etc.)
4. Understand default vs NULL behavior
5. Manage and modify default constraints
6. Handle default constraints in INSERT statements
7. Apply default constraints in real-world scenarios

Business Context:
-----------------
When creating new records, many columns have sensible default values:
order status defaults to 'Pending', creation dates default to today,
active flags default to TRUE. Default constraints automate this,
reducing errors and simplifying data entry while ensuring consistency.

Database: RetailStore
Complexity: Beginner
Estimated Time: 35 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT IS A DEFAULT CONSTRAINT?
================================================================================

A DEFAULT constraint provides an automatic value for a column when no
value is specified during INSERT.

CHARACTERISTICS:
----------------
1. AUTO-POPULATES: Fills column if no value provided
2. OPTIONAL: Can still provide explicit value
3. STATIC OR DYNAMIC: Can be constant or function-based
4. ONE PER COLUMN: Each column can have one default
5. OVERRIDABLE: Explicit values override default

Visual Representation:
----------------------
Product Table with Defaults:

INSERT without defaults:
INSERT INTO Product (ProductName, Price, Quantity, CreatedDate, IsActive)
VALUES ('Laptop', 999.99, 50, '2024-01-15', 1);

INSERT with defaults:
INSERT INTO Product (ProductName, Price, Quantity)  -- CreatedDate and IsActive auto-filled
VALUES ('Laptop', 999.99, 50);

Result:
ProductID  ProductName  Price    Quantity  CreatedDate  IsActive
---------  -----------  -------  --------  -----------  --------
1          Laptop       999.99   50        2024-01-15   1        (auto-filled)

Default Constraints:
- CreatedDate DEFAULT GETDATE()
- IsActive DEFAULT 1

*/

-- Example: Product table with default constraints
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    SKU VARCHAR(50) NOT NULL UNIQUE,
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL DEFAULT 0,  -- Default to 0 if not specified
    IsActive BIT NOT NULL DEFAULT 1,  -- Default to active
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),  -- Default to current date/time
    CreatedBy NVARCHAR(50) DEFAULT 'System',  -- Default creator
    ModifiedDate DATETIME NULL
);
GO

-- Insert without specifying default columns
INSERT INTO Product (ProductName, SKU, Price)
VALUES ('Laptop', 'LAP-001', 999.99);
GO

SELECT * FROM Product;
GO

/*
OUTPUT:
ProductID  ProductName  SKU      Price    Quantity  IsActive  CreatedDate          CreatedBy  ModifiedDate
---------  -----------  -------  -------  --------  --------  -------------------  ---------  ------------
1          Laptop       LAP-001  999.99   0         1         2024-01-15 10:30:15  System     NULL

EXPLANATION:
- Quantity: Defaulted to 0
- IsActive: Defaulted to 1 (TRUE)
- CreatedDate: Defaulted to current date/time
- CreatedBy: Defaulted to 'System'
- ModifiedDate: NULL (no default specified)
*/

-- Insert with explicit values (overriding defaults)
INSERT INTO Product (ProductName, SKU, Price, Quantity, IsActive, CreatedDate, CreatedBy)
VALUES ('Mouse', 'MOU-001', 29.99, 100, 0, '2024-01-01', 'Admin');
GO

SELECT * FROM Product WHERE ProductID = 2;
GO

/*
OUTPUT:
ProductID  ProductName  SKU      Price   Quantity  IsActive  CreatedDate          CreatedBy  ModifiedDate
---------  -----------  -------  ------  --------  --------  -------------------  ---------  ------------
2          Mouse        MOU-001  29.99   100       0         2024-01-01 00:00:00  Admin      NULL

EXPLANATION:
Explicit values override defaults - all specified values used instead of defaults.
*/

-- Insert using DEFAULT keyword explicitly
INSERT INTO Product (ProductName, SKU, Price, Quantity, IsActive, CreatedDate, CreatedBy)
VALUES ('Keyboard', 'KEY-001', 79.99, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
GO

SELECT * FROM Product WHERE ProductID = 3;
GO

/*
OUTPUT:
ProductID  ProductName  SKU      Price  Quantity  IsActive  CreatedDate          CreatedBy  ModifiedDate
---------  -----------  -------  -----  --------  --------  -------------------  ---------  ------------
3          Keyboard     KEY-001  79.99  0         1         2024-01-15 10:31:00  System     NULL

EXPLANATION:
Using DEFAULT keyword explicitly applies default values.
*/

/*
================================================================================
PART 2: STATIC DEFAULT VALUES
================================================================================

Static defaults are constant values that never change.
*/

-- Example 1: Numeric defaults
DROP TABLE IF EXISTS Customer;
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    LoyaltyPoints INT DEFAULT 0,  -- New customers start with 0 points
    CreditLimit DECIMAL(10,2) DEFAULT 1000.00,  -- Default credit limit
    IsVIP BIT DEFAULT 0,  -- Not VIP by default
    PreferredLanguage VARCHAR(10) DEFAULT 'English'  -- Default language
);
GO

-- Insert customer without specifying defaults
INSERT INTO Customer (FirstName, LastName, Email)
VALUES ('John', 'Doe', 'john@example.com');
GO

SELECT * FROM Customer;
GO

/*
OUTPUT:
CustomerID  FirstName  LastName  Email              LoyaltyPoints  CreditLimit  IsVIP  PreferredLanguage
----------  ---------  --------  -----------------  -------------  -----------  -----  -----------------
1           John       Doe       john@example.com   0              1000.00      0      English

All defaults applied automatically.
*/

-- Example 2: String defaults
DROP TABLE IF EXISTS [Order];
GO

CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'Pending',  -- Orders start as pending
    PaymentMethod VARCHAR(20) DEFAULT 'Credit Card',
    ShippingMethod VARCHAR(20) DEFAULT 'Standard',
    Currency CHAR(3) DEFAULT 'USD',
    Notes NVARCHAR(500) DEFAULT 'No special instructions'
);
GO

-- Insert order without specifying defaults
INSERT INTO [Order] (CustomerID)
VALUES (1);
GO

SELECT * FROM [Order];
GO

/*
OUTPUT:
OrderID  CustomerID  OrderDate            Status   PaymentMethod  ShippingMethod  Currency  Notes
-------  ----------  -------------------  -------  -------------  --------------  --------  --------------------------
1        1           2024-01-15 10:35:00  Pending  Credit Card    Standard        USD       No special instructions

All string defaults applied.
*/

/*
================================================================================
PART 3: DYNAMIC DEFAULT VALUES (FUNCTIONS)
================================================================================

Dynamic defaults use functions that generate values at INSERT time.
*/

-- Example 1: Date and time defaults
DROP TABLE IF EXISTS AuditLog;
GO

CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UserAction NVARCHAR(200) NOT NULL,
    ActionDate DATE DEFAULT CAST(GETDATE() AS DATE),  -- Current date only
    ActionTime TIME DEFAULT CAST(GETDATE() AS TIME),  -- Current time only
    ActionDateTime DATETIME DEFAULT GETDATE(),  -- Full date and time
    ActionDateTime2 DATETIME2 DEFAULT SYSDATETIME(),  -- More precise
    LoggedBy NVARCHAR(50) DEFAULT SUSER_SNAME()  -- Current database user
);
GO

-- Insert without specifying defaults
INSERT INTO AuditLog (UserAction)
VALUES ('User logged in');
GO

-- Wait a moment and insert another
WAITFOR DELAY '00:00:02';  -- Wait 2 seconds

INSERT INTO AuditLog (UserAction)
VALUES ('User updated profile');
GO

SELECT * FROM AuditLog;
GO

/*
OUTPUT:
LogID  UserAction            ActionDate   ActionTime     ActionDateTime       ActionDateTime2              LoggedBy
-----  --------------------  -----------  -------------  -------------------  ---------------------------  --------
1      User logged in        2024-01-15   10:40:15       2024-01-15 10:40:15  2024-01-15 10:40:15.1234567  dbo
2      User updated profile  2024-01-15   10:40:17       2024-01-15 10:40:17  2024-01-15 10:40:17.7654321  dbo

Each row gets current date/time when inserted (different values).
*/

-- Example 2: NEWID() for unique identifiers
DROP TABLE IF EXISTS Document;
GO

CREATE TABLE Document (
    DocumentID INT IDENTITY(1,1) PRIMARY KEY,
    DocumentGUID UNIQUEIDENTIFIER DEFAULT NEWID(),  -- Random GUID
    DocumentName NVARCHAR(200) NOT NULL,
    FileSize BIGINT,
    UploadDate DATETIME DEFAULT GETDATE(),
    Version INT DEFAULT 1
);
GO

-- Insert documents
INSERT INTO Document (DocumentName, FileSize)
VALUES 
    ('Report Q1 2024.pdf', 2048576),
    ('Presentation.pptx', 5242880),
    ('Spreadsheet.xlsx', 1048576);
GO

SELECT DocumentID, DocumentGUID, DocumentName, Version, UploadDate
FROM Document;
GO

/*
OUTPUT:
DocumentID  DocumentGUID                          DocumentName           Version  UploadDate
----------  ------------------------------------  ---------------------  -------  -------------------
1           A3B5C7D9-1E2F-4A5B-8C9D-0E1F2A3B4C5D  Report Q1 2024.pdf     1        2024-01-15 10:45:00
2           B4C6D8E0-2F3A-5B6C-9D0E-1F2A3B4C5D6E  Presentation.pptx      1        2024-01-15 10:45:00
3           C5D7E9F1-3A4B-6C7D-0E1F-2A3B4C5D6E7F  Spreadsheet.xlsx       1        2024-01-15 10:45:00

Each document gets unique GUID automatically.
*/

-- Example 3: NEWSEQUENTIALID() for better performance
-- Note: NEWSEQUENTIALID() can ONLY be used in DEFAULT constraints, not elsewhere
DROP TABLE IF EXISTS Transaction;
GO

CREATE TABLE [Transaction] (
    TransactionID UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID() PRIMARY KEY,
    TransactionDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10,2) NOT NULL,
    Description NVARCHAR(200)
);
GO

-- Insert transactions
INSERT INTO [Transaction] (Amount, Description)
VALUES 
    (150.00, 'Purchase'),
    (75.50, 'Refund'),
    (200.00, 'Purchase');
GO

SELECT * FROM [Transaction];
GO

/*
OUTPUT:
TransactionID                         TransactionDate      Amount  Description
------------------------------------  -------------------  ------  -----------
00000001-0000-0000-0000-000000000000  2024-01-15 10:50:00  150.00  Purchase
00000002-0000-0000-0000-000000000000  2024-01-15 10:50:00  75.50   Refund
00000003-0000-0000-0000-000000000000  2024-01-15 10:50:00  200.00  Purchase

NEWSEQUENTIALID() generates sequential GUIDs (better index performance than NEWID).
*/

/*
================================================================================
PART 4: DEFAULT VS NULL
================================================================================

Understanding how defaults interact with NULL values.
*/

-- Example: NULL vs DEFAULT behavior
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50) DEFAULT 'Unassigned',  -- Has default
    HireDate DATE DEFAULT CAST(GETDATE() AS DATE),  -- Has default
    Salary DECIMAL(10,2),  -- No default, NULL allowed
    IsActive BIT NOT NULL DEFAULT 1  -- Has default, NOT NULL
);
GO

-- Scenario 1: Omit columns (defaults used)
INSERT INTO Employee (FirstName, LastName)
VALUES ('John', 'Doe');
GO

-- Scenario 2: Explicit NULL (overrides default if column allows NULL)
INSERT INTO Employee (FirstName, LastName, Department, HireDate, Salary)
VALUES ('Jane', 'Smith', NULL, NULL, NULL);
GO

-- Scenario 3: Explicit DEFAULT keyword
INSERT INTO Employee (FirstName, LastName, Department, HireDate, Salary)
VALUES ('Bob', 'Johnson', DEFAULT, DEFAULT, NULL);
GO

-- Scenario 4: Try to insert NULL into NOT NULL column with default
BEGIN TRY
    INSERT INTO Employee (FirstName, LastName, IsActive)
    VALUES ('Invalid', 'Employee', NULL);  -- IsActive is NOT NULL
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot insert NULL into NOT NULL column';
END CATCH;
GO

SELECT * FROM Employee;
GO

/*
OUTPUT:
EmployeeID  FirstName  LastName  Department  HireDate    Salary  IsActive
----------  ---------  --------  ----------  ----------  ------  --------
1           John       Doe       Unassigned  2024-01-15  NULL    1        (defaults used)
2           Jane       Smith     NULL        NULL        NULL    1        (NULLs override defaults)
3           Bob        Johnson   Unassigned  2024-01-15  NULL    1        (DEFAULT keyword)

KEY INSIGHT:
- Omitting column: Default is used
- Explicit NULL: NULL overrides default (if column allows NULL)
- DEFAULT keyword: Explicitly requests default
- NOT NULL + DEFAULT: Cannot insert NULL
*/

/*
================================================================================
PART 5: COMPLEX DEFAULT EXPRESSIONS
================================================================================

Defaults can use expressions and calculations.
*/

-- Example 1: Calculated defaults
DROP TABLE IF EXISTS ProductPrice;
GO

CREATE TABLE ProductPrice (
    PriceID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,
    Markup DECIMAL(5,2) DEFAULT 1.50,  -- 50% markup
    Price AS (Cost * Markup) PERSISTED,  -- Computed column
    EffectiveDate DATE DEFAULT CAST(GETDATE() AS DATE),
    ExpiryDate DATE DEFAULT DATEADD(YEAR, 1, CAST(GETDATE() AS DATE))  -- 1 year from today
);
GO

-- Insert with defaults
INSERT INTO ProductPrice (ProductID, Cost)
VALUES (1, 100.00);
GO

SELECT * FROM ProductPrice;
GO

/*
OUTPUT:
PriceID  ProductID  Cost    Markup  Price   EffectiveDate  ExpiryDate
-------  ---------  ------  ------  ------  -------------  ----------
1        1          100.00  1.50    150.00  2024-01-15     2025-01-15

Price calculated from Cost * Markup
ExpiryDate is 1 year from EffectiveDate
*/

-- Example 2: Conditional defaults (limited in DEFAULT constraints)
DROP TABLE IF EXISTS InventoryAlert;
GO

CREATE TABLE InventoryAlert (
    AlertID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    CurrentStock INT NOT NULL,
    AlertThreshold INT DEFAULT 10,
    AlertDate DATETIME DEFAULT GETDATE(),
    AlertType VARCHAR(20) DEFAULT 'LowStock',
    Priority VARCHAR(10) DEFAULT 'Medium'
);
GO

/*
Note: DEFAULT constraints cannot have complex CASE expressions.
For complex logic, use triggers or computed columns instead.
*/

/*
================================================================================
PART 6: MANAGING DEFAULT CONSTRAINTS
================================================================================
*/

-- Create table without defaults initially
DROP TABLE IF EXISTS TestDefaults;
GO

CREATE TABLE TestDefaults (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Status VARCHAR(20),
    CreatedDate DATETIME
);
GO

-- Add default constraint to existing table
ALTER TABLE TestDefaults
ADD CONSTRAINT DF_TestDefaults_Status DEFAULT 'Active' FOR Status;
GO

ALTER TABLE TestDefaults
ADD CONSTRAINT DF_TestDefaults_CreatedDate DEFAULT GETDATE() FOR CreatedDate;
GO

-- Test the defaults
INSERT INTO TestDefaults (ID, Name)
VALUES (1, 'Test Item');
GO

SELECT * FROM TestDefaults;
GO

/*
OUTPUT:
ID  Name       Status  CreatedDate
--  ---------  ------  -------------------
1   Test Item  Active  2024-01-15 11:00:00

Defaults added to existing table work correctly.
*/

-- Drop default constraint
ALTER TABLE TestDefaults
DROP CONSTRAINT DF_TestDefaults_Status;
GO

-- Re-add with different value
ALTER TABLE TestDefaults
ADD CONSTRAINT DF_TestDefaults_Status DEFAULT 'Pending' FOR Status;
GO

-- View all default constraints
SELECT 
    OBJECT_NAME(dc.parent_object_id) AS TableName,
    dc.name AS ConstraintName,
    COL_NAME(dc.parent_object_id, dc.parent_column_id) AS ColumnName,
    dc.definition AS DefaultValue
FROM sys.default_constraints dc
WHERE OBJECT_NAME(dc.parent_object_id) IN ('Product', 'Customer', 'Order', 'Employee')
ORDER BY TableName, ColumnName;
GO

/*
================================================================================
PART 7: REAL-WORLD SCENARIOS
================================================================================
*/

-- Scenario 1: User Registration System
DROP TABLE IF EXISTS AppUser;
GO

CREATE TABLE AppUser (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,
    IsEmailVerified BIT DEFAULT 0,  -- Not verified initially
    IsActive BIT DEFAULT 1,  -- Active by default
    RegistrationDate DATETIME DEFAULT GETDATE(),
    LastLoginDate DATETIME NULL,
    FailedLoginAttempts INT DEFAULT 0,
    AccountLockedUntil DATETIME NULL,
    PreferredTheme VARCHAR(20) DEFAULT 'Light',
    TimeZone VARCHAR(50) DEFAULT 'UTC'
);
GO

INSERT INTO AppUser (Username, Email, PasswordHash)
VALUES ('john_doe', 'john@example.com', 0x1234567890ABCDEF);
GO

SELECT UserID, Username, IsEmailVerified, IsActive, RegistrationDate, FailedLoginAttempts, PreferredTheme
FROM AppUser;
GO

-- Scenario 2: E-commerce Order System
DROP TABLE IF EXISTS EcommerceOrder;
GO

CREATE TABLE EcommerceOrder (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber VARCHAR(20) DEFAULT 'ORD-' + CAST(NEWID() AS VARCHAR(36)),
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'Pending',
    PaymentStatus VARCHAR(20) DEFAULT 'Unpaid',
    ShippingMethod VARCHAR(30) DEFAULT 'Standard Shipping',
    Currency CHAR(3) DEFAULT 'USD',
    TaxRate DECIMAL(5,4) DEFAULT 0.0825,  -- 8.25% tax
    SubTotal DECIMAL(10,2),
    TaxAmount AS (SubTotal * TaxRate),
    ShippingCost DECIMAL(10,2) DEFAULT 0.00,
    TotalAmount AS (SubTotal + (SubTotal * TaxRate) + ShippingCost) PERSISTED,
    Notes NVARCHAR(500) DEFAULT 'No special instructions',
    IsGift BIT DEFAULT 0,
    RequiresSignature BIT DEFAULT 0
);
GO

-- Scenario 3: Inventory Management
DROP TABLE IF EXISTS InventoryItem;
GO

CREATE TABLE InventoryItem (
    ItemID INT IDENTITY(1,1) PRIMARY KEY,
    ItemCode VARCHAR(50) NOT NULL UNIQUE,
    ItemName NVARCHAR(200) NOT NULL,
    Quantity INT DEFAULT 0,
    MinimumStock INT DEFAULT 10,
    MaximumStock INT DEFAULT 1000,
    ReorderPoint INT DEFAULT 20,
    UnitCost DECIMAL(10,2),
    Location VARCHAR(50) DEFAULT 'Main Warehouse',
    LastStockCheck DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    IsDiscontinued BIT DEFAULT 0
);
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Static Defaults
---------------------------
Create a BlogPost table with default values for:
- Status (default 'Draft')
- ViewCount (default 0)
- AllowComments (default 1)
- IsFeatured (default 0)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Dynamic Defaults
----------------------------
Create an EventLog table with:
- EventDate (default current date)
- EventTime (default current time)
- EventGUID (default new GUID)
- LoggedByUser (default current user)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Complex Defaults
----------------------------
Create a Subscription table with:
- StartDate (default today)
- EndDate (default 1 year from today)
- TrialPeriodDays (default 30)
- TrialEndDate (default 30 days from today)
- Status (default 'Trial')

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Static Defaults
DROP TABLE IF EXISTS BlogPost;
GO

CREATE TABLE BlogPost (
    PostID INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    AuthorID INT NOT NULL,
    Status VARCHAR(20) DEFAULT 'Draft',
    ViewCount INT DEFAULT 0,
    AllowComments BIT DEFAULT 1,
    IsFeatured BIT DEFAULT 0,
    PublishedDate DATETIME NULL
);
GO

-- Test insert
INSERT INTO BlogPost (Title, Content, AuthorID)
VALUES ('My First Blog Post', 'This is the content...', 1);
GO

SELECT * FROM BlogPost;
GO

/*
OUTPUT:
PostID  Title               Content              AuthorID  Status  ViewCount  AllowComments  IsFeatured  PublishedDate
------  ------------------  -------------------  --------  ------  ---------  -------------  ----------  -------------
1       My First Blog Post  This is the content  1         Draft   0          1              0           NULL
*/

-- Solution 2: Dynamic Defaults
DROP TABLE IF EXISTS EventLog;
GO

CREATE TABLE EventLog (
    EventID INT IDENTITY(1,1) PRIMARY KEY,
    EventName NVARCHAR(100) NOT NULL,
    EventDate DATE DEFAULT CAST(GETDATE() AS DATE),
    EventTime TIME DEFAULT CAST(GETDATE() AS TIME),
    EventGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
    LoggedByUser NVARCHAR(50) DEFAULT SUSER_SNAME(),
    Details NVARCHAR(500)
);
GO

-- Test insert
INSERT INTO EventLog (EventName, Details)
VALUES ('Application Started', 'User logged into system');
GO

WAITFOR DELAY '00:00:01';

INSERT INTO EventLog (EventName, Details)
VALUES ('Data Updated', 'User modified record ID 123');
GO

SELECT * FROM EventLog;
GO

/*
OUTPUT:
EventID  EventName            EventDate   EventTime    EventGUID                             LoggedByUser  Details
-------  -------------------  ----------  -----------  ------------------------------------  ------------  ------------------------
1        Application Started  2024-01-15  11:30:15     A1B2C3D4-E5F6-7890-ABCD-EF1234567890  dbo           User logged into system
2        Data Updated         2024-01-15  11:30:16     B2C3D4E5-F6A7-8901-BCDE-F12345678901  dbo           User modified record...
*/

-- Solution 3: Complex Defaults
DROP TABLE IF EXISTS Subscription;
GO

CREATE TABLE Subscription (
    SubscriptionID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    PlanName VARCHAR(50) NOT NULL,
    StartDate DATE DEFAULT CAST(GETDATE() AS DATE),
    EndDate DATE DEFAULT DATEADD(YEAR, 1, CAST(GETDATE() AS DATE)),
    TrialPeriodDays INT DEFAULT 30,
    TrialEndDate DATE DEFAULT DATEADD(DAY, 30, CAST(GETDATE() AS DATE)),
    Status VARCHAR(20) DEFAULT 'Trial',
    MonthlyPrice DECIMAL(10,2),
    AutoRenew BIT DEFAULT 1
);
GO

-- Test insert
INSERT INTO Subscription (UserID, PlanName, MonthlyPrice)
VALUES (101, 'Premium', 19.99);
GO

SELECT 
    SubscriptionID,
    UserID,
    PlanName,
    StartDate,
    EndDate,
    TrialPeriodDays,
    TrialEndDate,
    Status,
    MonthlyPrice
FROM Subscription;
GO

/*
OUTPUT:
SubscriptionID  UserID  PlanName  StartDate   EndDate     TrialPeriodDays  TrialEndDate  Status  MonthlyPrice
--------------  ------  --------  ----------  ----------  ---------------  ------------  ------  ------------
1               101     Premium   2024-01-15  2025-01-15  30               2024-02-14    Trial   19.99

All date-based defaults calculated correctly!
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. DEFAULT CONSTRAINT BASICS
   - Provides automatic value when none specified
   - Optional - can override with explicit value
   - One default per column
   - Applied only during INSERT (not UPDATE)

2. STATIC DEFAULTS
   - Constant values (numbers, strings, dates)
   - Same value for every row
   - Simple and efficient
   - Examples: 0, 'Active', 1000.00

3. DYNAMIC DEFAULTS
   - Function-based values
   - Different for each row
   - Common functions:
     * GETDATE() - current date/time
     * NEWID() - random GUID
     * NEWSEQUENTIALID() - sequential GUID
     * SUSER_SNAME() - current user

4. DEFAULT VS NULL
   - Omit column: Default applies
   - Explicit NULL: Overrides default (if NULL allowed)
   - DEFAULT keyword: Explicitly requests default
   - NOT NULL + DEFAULT: Forces default, rejects NULL

5. MANAGEMENT
   - Add to existing tables with ALTER TABLE
   - Drop and recreate to modify
   - Named constraints recommended
   - View in sys.default_constraints

6. BEST PRACTICES
   - Use for common, sensible defaults
   - Document default behavior
   - Consider business logic
   - Test NULL vs DEFAULT behavior
   - Use NOT NULL for required defaults
   - Avoid complex expressions (use computed columns)

7. COMMON USE CASES
   - Status flags (Active/Inactive)
   - Timestamps (created date, modified date)
   - Counters (view count, login attempts)
   - Configuration (language, theme, timezone)
   - Financial (currency, tax rates)

================================================================================

NEXT STEPS:
-----------
In Lesson 13.9, we'll explore INDEX MAINTENANCE:
- Index fragmentation
- Rebuilding and reorganizing indexes
- Updating statistics
- Monitoring with DMVs

Continue to: 09-index-maintenance.sql

================================================================================
*/
