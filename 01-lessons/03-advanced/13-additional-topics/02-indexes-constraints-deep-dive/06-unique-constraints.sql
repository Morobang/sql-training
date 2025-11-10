/*
================================================================================
LESSON 13.6: UNIQUE CONSTRAINTS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand unique constraints and their purpose
2. Create single-column and composite unique constraints
3. Differentiate between unique and primary key constraints
4. Handle NULLs in unique constraints
5. Use unique constraints with indexes
6. Manage and modify unique constraints
7. Apply unique constraints in real-world scenarios

Business Context:
-----------------
A company's database needs to ensure customer emails are unique, employee
badge numbers can't be duplicated, and product SKUs are one-of-a-kind.
While primary keys ensure row uniqueness, unique constraints enforce
uniqueness on other business-critical columns, maintaining data quality
and preventing duplicates.

Database: RetailStore
Complexity: Beginner to Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT IS A UNIQUE CONSTRAINT?
================================================================================

A UNIQUE constraint ensures all values in a column (or combination of columns)
are unique across the table.

CHARACTERISTICS:
----------------
1. ENFORCES UNIQUENESS: No duplicate values allowed
2. ALLOWS NULL: Can have multiple NULL values (unlike PRIMARY KEY)
3. MULTIPLE PER TABLE: Can have many unique constraints (unlike PK)
4. AUTO-INDEXED: Automatically creates a unique index
5. ALTERNATE KEY: Provides additional unique identifiers beyond PK

UNIQUE vs PRIMARY KEY:
----------------------
Feature               PRIMARY KEY          UNIQUE CONSTRAINT
------------------    ---------------      ------------------
Uniqueness            Yes                  Yes
Allows NULL           No                   Yes (multiple)
Quantity per table    1                    Unlimited
Auto-indexed          Yes (clustered)      Yes (nonclustered)
Purpose               Row identifier       Business uniqueness

Visual Representation:
----------------------
CustomerID (PK)  Email (UNIQUE)           Phone (UNIQUE)      SSN (UNIQUE)
--------------   ----------------------   -----------------   -------------
1                john@example.com ✅      555-1001 ✅         123-45-6789 ✅
2                jane@example.com ✅      555-1002 ✅         987-65-4321 ✅
3                john@example.com ❌      555-1001 ❌         NULL ✅
4                unique@example.com ✅    NULL ✅             NULL ✅
5                another@example.com ✅   NULL ✅             NULL ✅

- Email duplicates NOT allowed
- Phone duplicates NOT allowed
- Multiple NULLs ARE allowed (for Phone and SSN)

*/

-- Example: Customer table with unique constraints
DROP TABLE IF EXISTS Customer;
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    SSN CHAR(11),
    LoyaltyCardNumber VARCHAR(20),
    CONSTRAINT PK_Customer PRIMARY KEY (CustomerID),
    CONSTRAINT UQ_Customer_Email UNIQUE (Email),        -- Email must be unique
    CONSTRAINT UQ_Customer_Phone UNIQUE (Phone),        -- Phone must be unique
    CONSTRAINT UQ_Customer_SSN UNIQUE (SSN)             -- SSN must be unique
);
GO

-- Insert valid customers
INSERT INTO Customer (FirstName, LastName, Email, Phone, SSN, LoyaltyCardNumber)
VALUES 
    ('John', 'Doe', 'john@example.com', '555-1001', '123-45-6789', 'LC001'),
    ('Jane', 'Smith', 'jane@example.com', '555-1002', '987-65-4321', 'LC002'),
    ('Bob', 'Johnson', 'bob@example.com', NULL, NULL, 'LC003');  -- NULLs OK
GO

SELECT * FROM Customer;
GO

/*
OUTPUT:
CustomerID  FirstName  LastName  Email               Phone     SSN          LoyaltyCardNumber
----------  ---------  --------  ------------------  --------  -----------  -----------------
1           John       Doe       john@example.com    555-1001  123-45-6789  LC001
2           Jane       Smith     jane@example.com    555-1002  987-65-4321  LC002
3           Bob        Johnson   bob@example.com     NULL      NULL         LC003
*/

-- Try to insert duplicate email
INSERT INTO Customer (FirstName, LastName, Email, Phone, SSN, LoyaltyCardNumber)
VALUES ('Mike', 'Williams', 'john@example.com', '555-1003', '111-22-3333', 'LC004');
GO

/*
ERROR:
Violation of UNIQUE KEY constraint 'UQ_Customer_Email'.
Cannot insert duplicate key in object 'dbo.Customer'.
The duplicate key value is (john@example.com).

EXPLANATION:
Email 'john@example.com' already exists for John Doe.
Unique constraint prevents duplicate emails.
*/

-- Try to insert duplicate phone
INSERT INTO Customer (FirstName, LastName, Email, Phone, SSN, LoyaltyCardNumber)
VALUES ('Mike', 'Williams', 'mike@example.com', '555-1001', '111-22-3333', 'LC004');
GO

/*
ERROR:
Violation of UNIQUE KEY constraint 'UQ_Customer_Phone'.
The duplicate key value is (555-1001).

EXPLANATION:
Phone '555-1001' already exists for John Doe.
*/

-- Valid insert with unique values
INSERT INTO Customer (FirstName, LastName, Email, Phone, SSN, LoyaltyCardNumber)
VALUES ('Mike', 'Williams', 'mike@example.com', '555-1003', '111-22-3333', 'LC004');
GO

/*
SUCCESS: All values are unique.
*/

/*
================================================================================
PART 2: UNIQUE CONSTRAINTS WITH NULL VALUES
================================================================================

SQL Server treats NULL values as unique for unique constraints.
This means you can have multiple NULL values in a unique column.

Important Note:
---------------
This behavior differs from the SQL standard, which states that NULL != NULL.
In SQL Server, multiple NULLs don't violate uniqueness.

*/

-- Multiple NULLs are allowed
INSERT INTO Customer (FirstName, LastName, Email, Phone, SSN, LoyaltyCardNumber)
VALUES 
    ('Alice', 'Brown', 'alice@example.com', NULL, NULL, 'LC005'),  -- NULL Phone & SSN
    ('Charlie', 'Davis', 'charlie@example.com', NULL, NULL, 'LC006');  -- Another NULL
GO

SELECT CustomerID, FirstName, LastName, Email, Phone, SSN
FROM Customer
WHERE Phone IS NULL OR SSN IS NULL;
GO

/*
OUTPUT:
CustomerID  FirstName  LastName  Email                  Phone  SSN
----------  ---------  --------  --------------------   -----  ----
3           Bob        Johnson   bob@example.com        NULL   NULL
5           Alice      Brown     alice@example.com      NULL   NULL
6           Charlie    Davis     charlie@example.com    NULL   NULL

Multiple NULLs allowed in Phone and SSN columns (all unique constraint columns).
*/

/*
WHAT IF YOU DON'T WANT MULTIPLE NULLs?

Use a filtered unique index instead of a unique constraint.
*/

-- Drop existing constraint
ALTER TABLE Customer
DROP CONSTRAINT UQ_Customer_Phone;
GO

-- Create filtered unique index (only indexes non-NULL values)
CREATE UNIQUE NONCLUSTERED INDEX UQ_Customer_Phone_NotNull
ON Customer(Phone)
WHERE Phone IS NOT NULL;  -- Only enforce uniqueness on non-NULL values
GO

/*
Now:
- Multiple NULLs allowed (not indexed)
- Non-NULL values must be unique
- Same practical effect as original constraint for non-NULL values
*/

/*
================================================================================
PART 3: COMPOSITE UNIQUE CONSTRAINTS
================================================================================

Unique constraints can span multiple columns.
The COMBINATION of values must be unique.

*/

-- Example: Product variants (same product can have multiple sizes/colors)
DROP TABLE IF EXISTS ProductVariant;
GO

CREATE TABLE ProductVariant (
    VariantID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    Size VARCHAR(10),
    Color VARCHAR(30),
    SKU VARCHAR(50) NOT NULL,
    Price DECIMAL(10,2),
    StockQuantity INT,
    CONSTRAINT UQ_ProductVariant_Product_Size_Color 
        UNIQUE (ProductID, Size, Color),  -- Combination must be unique
    CONSTRAINT UQ_ProductVariant_SKU UNIQUE (SKU)  -- SKU also unique
);
GO

-- Insert valid variants
INSERT INTO ProductVariant (ProductID, Size, Color, SKU, Price, StockQuantity)
VALUES 
    (101, 'Small', 'Red', 'PRD101-S-RED', 29.99, 50),
    (101, 'Small', 'Blue', 'PRD101-S-BLU', 29.99, 45),    -- Same product, same size, different color ✅
    (101, 'Medium', 'Red', 'PRD101-M-RED', 29.99, 60),    -- Same product, different size ✅
    (102, 'Small', 'Red', 'PRD102-S-RED', 39.99, 30);     -- Different product ✅
GO

SELECT * FROM ProductVariant;
GO

/*
OUTPUT:
VariantID  ProductID  Size    Color  SKU              Price  StockQuantity
---------  ---------  ------  -----  ---------------  -----  -------------
1          101        Small   Red    PRD101-S-RED     29.99  50
2          101        Small   Blue   PRD101-S-BLU     29.99  45
3          101        Medium  Red    PRD101-M-RED     29.99  60
4          102        Small   Red    PRD102-S-RED     39.99  30

Each (ProductID, Size, Color) combination is unique.
*/

-- Try to insert duplicate combination
INSERT INTO ProductVariant (ProductID, Size, Color, SKU, Price, StockQuantity)
VALUES (101, 'Small', 'Red', 'PRD101-S-RED-DUP', 29.99, 10);  -- Duplicate combination!
GO

/*
ERROR:
Violation of UNIQUE KEY constraint 'UQ_ProductVariant_Product_Size_Color'.
The duplicate key value is (101, Small, Red).

EXPLANATION:
Combination (101, Small, Red) already exists.
*/

-- These ARE allowed (different combinations)
INSERT INTO ProductVariant (ProductID, Size, Color, SKU, Price, StockQuantity)
VALUES 
    (101, 'Large', 'Red', 'PRD101-L-RED', 29.99, 40),     -- Different size
    (101, 'Small', 'Green', 'PRD101-S-GRN', 29.99, 35);   -- Different color
GO

SELECT * FROM ProductVariant WHERE ProductID = 101;
GO

/*
OUTPUT:
VariantID  ProductID  Size    Color  SKU              Price  StockQuantity
---------  ---------  ------  -----  ---------------  -----  -------------
1          101        Small   Red    PRD101-S-RED     29.99  50
2          101        Small   Blue   PRD101-S-BLU     29.99  45
3          101        Medium  Red    PRD101-M-RED     29.99  60
5          101        Large   Red    PRD101-L-RED     29.99  40
6          101        Small   Green  PRD101-S-GRN     29.99  35

All combinations are unique.
*/

/*
USE CASES FOR COMPOSITE UNIQUE CONSTRAINTS:
--------------------------------------------
1. Product variants (product + size + color)
2. Time series data (sensor + timestamp)
3. Multi-tenant systems (tenant + email)
4. Geographic data (country + state + city + zip)
5. Scheduling (room + date + time slot)
*/

/*
================================================================================
PART 4: CREATING UNIQUE CONSTRAINTS
================================================================================

Multiple syntaxes for creating unique constraints.
*/

-- Method 1: Inline column constraint
DROP TABLE IF EXISTS Method1_Table;
GO

CREATE TABLE Method1_Table (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100) UNIQUE  -- Inline unique constraint
);
GO

-- Method 2: Inline column constraint with name
DROP TABLE IF EXISTS Method2_Table;
GO

CREATE TABLE Method2_Table (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100) CONSTRAINT UQ_Method2_Email UNIQUE  -- Named
);
GO

-- Method 3: Table-level constraint (RECOMMENDED)
DROP TABLE IF EXISTS Method3_Table;
GO

CREATE TABLE Method3_Table (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Method3_Email UNIQUE (Email)  -- Table-level
);
GO

-- Method 4: Add unique constraint to existing table
DROP TABLE IF EXISTS Method4_Table;
GO

CREATE TABLE Method4_Table (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100) NOT NULL
);
GO

ALTER TABLE Method4_Table
ADD CONSTRAINT UQ_Method4_Email UNIQUE (Email);
GO

-- Method 5: Create unique index (alternative to constraint)
DROP TABLE IF EXISTS Method5_Table;
GO

CREATE TABLE Method5_Table (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100) NOT NULL
);
GO

CREATE UNIQUE INDEX IX_Method5_Email ON Method5_Table(Email);
GO

/*
BEST PRACTICE:
- Use Method 3 or 4 (named table-level constraints)
- Always name constraints: UQ_TableName_ColumnName
- For composite: UQ_TableName_Col1_Col2
*/

-- View all unique constraints
SELECT 
    OBJECT_NAME(kc.parent_object_id) AS TableName,
    kc.name AS ConstraintName,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.key_constraints kc
INNER JOIN sys.index_columns ic 
    ON kc.parent_object_id = ic.object_id 
    AND kc.unique_index_id = ic.index_id
WHERE kc.type = 'UQ'
  AND OBJECT_NAME(kc.parent_object_id) LIKE 'Method%'
ORDER BY TableName, kc.name;
GO

/*
OUTPUT:
TableName      ConstraintName      ColumnName
-------------  ------------------  ----------
Method1_Table  UQ__Method1...      Email
Method2_Table  UQ_Method2_Email    Email
Method3_Table  UQ_Method3_Email    Email
Method4_Table  UQ_Method4_Email    Email

Method 5 shows as a unique index, not a constraint.
*/

/*
================================================================================
PART 5: UNIQUE CONSTRAINT vs UNIQUE INDEX
================================================================================

Both enforce uniqueness, but there are subtle differences.

UNIQUE CONSTRAINT:
- Logical concept (integrity rule)
- Implemented using a unique index
- Shows in constraint metadata
- Preferred for data integrity

UNIQUE INDEX:
- Physical implementation
- Can have additional options (INCLUDE, filtered WHERE)
- More flexible
- Preferred for query performance

*/

-- Unique Constraint (creates index automatically)
DROP TABLE IF EXISTS TestConstraint;
GO

CREATE TABLE TestConstraint (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100),
    CONSTRAINT UQ_TestConstraint_Email UNIQUE (Email)
);
GO

-- Unique Index (no constraint, just index)
DROP TABLE IF EXISTS TestIndex;
GO

CREATE TABLE TestIndex (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100)
);
GO

CREATE UNIQUE INDEX IX_TestIndex_Email ON TestIndex(Email);
GO

-- Check constraints
SELECT 
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    type_desc
FROM sys.key_constraints
WHERE OBJECT_NAME(parent_object_id) IN ('TestConstraint', 'TestIndex');
GO

/*
OUTPUT:
TableName        ConstraintName          type_desc
---------------  ---------------------   -------------------
TestConstraint   PK__TestCons...         PRIMARY_KEY_CONSTRAINT
TestConstraint   UQ_TestConstraint_Email UNIQUE_CONSTRAINT

TestIndex has no unique constraint (only an index).
*/

-- Check indexes
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS IndexName,
    is_unique,
    type_desc
FROM sys.indexes
WHERE OBJECT_NAME(object_id) IN ('TestConstraint', 'TestIndex')
  AND is_primary_key = 0;  -- Exclude PK
GO

/*
OUTPUT:
TableName        IndexName                is_unique  type_desc
---------------  -----------------------  ---------  -----------
TestConstraint   UQ_TestConstraint_Email  1          NONCLUSTERED
TestIndex        IX_TestIndex_Email       1          NONCLUSTERED

Both have unique nonclustered indexes.
*/

/*
WHEN TO USE WHAT:
-----------------
Use UNIQUE CONSTRAINT:
✅ Enforcing business rules (emails must be unique)
✅ Alternate keys (natural unique identifiers)
✅ Referential integrity (foreign keys can reference unique constraints)

Use UNIQUE INDEX:
✅ Performance optimization with uniqueness
✅ Need filtered index (unique for subset)
✅ Need included columns
✅ More control over index options
*/

/*
================================================================================
PART 6: REAL-WORLD SCENARIOS
================================================================================
*/

-- Scenario 1: User Registration System
-- Email must be unique, username must be unique

DROP TABLE IF EXISTS AppUser;
GO

CREATE TABLE AppUser (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    PasswordHash VARBINARY(64) NOT NULL,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_AppUser_Username UNIQUE (Username),
    CONSTRAINT UQ_AppUser_Email UNIQUE (Email)
);
GO

-- Insert users
INSERT INTO AppUser (Username, Email, PasswordHash, FirstName, LastName)
VALUES 
    ('johndoe', 'john@example.com', 0x1234, 'John', 'Doe'),
    ('janesmith', 'jane@example.com', 0x5678, 'Jane', 'Smith');
GO

-- Prevent duplicate username
BEGIN TRY
    INSERT INTO AppUser (Username, Email, PasswordHash, FirstName, LastName)
    VALUES ('johndoe', 'john2@example.com', 0xABCD, 'John', 'Doe Jr.');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Username already taken!';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Prevent duplicate email
BEGIN TRY
    INSERT INTO AppUser (Username, Email, PasswordHash, FirstName, LastName)
    VALUES ('johndoe2', 'john@example.com', 0xABCD, 'John', 'Doe Jr.');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Email already registered!';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Scenario 2: Inventory Management
-- Product SKU must be unique, barcode must be unique

DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    SKU VARCHAR(50) NOT NULL,
    Barcode VARCHAR(50),
    ProductName NVARCHAR(200) NOT NULL,
    Price DECIMAL(10,2),
    CONSTRAINT UQ_Product_SKU UNIQUE (SKU),
    CONSTRAINT UQ_Product_Barcode UNIQUE (Barcode)
);
GO

INSERT INTO Product (SKU, Barcode, ProductName, Price)
VALUES 
    ('SKU-001', '123456789012', 'Laptop', 999.99),
    ('SKU-002', '234567890123', 'Mouse', 29.99),
    ('SKU-003', NULL, 'Keyboard', 79.99);  -- NULL barcode OK
GO

-- Scenario 3: Employee Badge System
-- Badge number must be unique

DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    BadgeNumber VARCHAR(20) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50),
    HireDate DATE DEFAULT GETDATE(),
    CONSTRAINT UQ_Employee_Badge UNIQUE (BadgeNumber)
);
GO

INSERT INTO Employee (BadgeNumber, FirstName, LastName, Department)
VALUES 
    ('BADGE-001', 'Alice', 'Johnson', 'Engineering'),
    ('BADGE-002', 'Bob', 'Smith', 'Sales');
GO

-- Prevent duplicate badge
BEGIN TRY
    INSERT INTO Employee (BadgeNumber, FirstName, LastName, Department)
    VALUES ('BADGE-001', 'Charlie', 'Brown', 'Marketing');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Badge number already assigned!';
END CATCH;
GO

-- Scenario 4: Multi-Tenant System
-- Email unique per tenant (composite unique constraint)

DROP TABLE IF EXISTS TenantUser;
GO

CREATE TABLE TenantUser (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    TenantID INT NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Username VARCHAR(50) NOT NULL,
    IsActive BIT DEFAULT 1,
    CONSTRAINT UQ_TenantUser_Email UNIQUE (TenantID, Email),  -- Email unique per tenant
    CONSTRAINT UQ_TenantUser_Username UNIQUE (TenantID, Username)  -- Username unique per tenant
);
GO

-- Same email can exist in different tenants
INSERT INTO TenantUser (TenantID, Email, Username)
VALUES 
    (1, 'admin@example.com', 'admin'),  -- Tenant 1
    (2, 'admin@example.com', 'admin');  -- Tenant 2 - same email, different tenant ✅
GO

-- But can't duplicate within same tenant
BEGIN TRY
    INSERT INTO TenantUser (TenantID, Email, Username)
    VALUES (1, 'admin@example.com', 'admin2');  -- Tenant 1, duplicate email
END TRY
BEGIN CATCH
    PRINT 'ERROR: Email already exists for this tenant!';
END CATCH;
GO

/*
================================================================================
PART 7: MANAGING UNIQUE CONSTRAINTS
================================================================================
*/

-- Drop unique constraint
ALTER TABLE Customer
DROP CONSTRAINT UQ_Customer_Email;
GO

/*
SUCCESS: Unique constraint removed.
Email duplicates now allowed (dangerous!).
*/

-- Re-add unique constraint
ALTER TABLE Customer
ADD CONSTRAINT UQ_Customer_Email UNIQUE (Email);
GO

-- What if duplicate data exists?
DROP TABLE IF EXISTS TestDuplicates;
GO

CREATE TABLE TestDuplicates (
    ID INT PRIMARY KEY,
    Email NVARCHAR(100)
);
GO

-- Insert duplicates
INSERT INTO TestDuplicates (ID, Email)
VALUES (1, 'test@example.com'), (2, 'test@example.com');  -- Duplicate!
GO

-- Try to add unique constraint
BEGIN TRY
    ALTER TABLE TestDuplicates
    ADD CONSTRAINT UQ_TestDuplicates_Email UNIQUE (Email);
END TRY
BEGIN CATCH
    PRINT 'ERROR: Cannot create unique constraint - duplicate values exist!';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Find duplicates
SELECT Email, COUNT(*) AS DuplicateCount
FROM TestDuplicates
GROUP BY Email
HAVING COUNT(*) > 1;
GO

/*
OUTPUT:
Email                DuplicateCount
-------------------  --------------
test@example.com     2

Must remove duplicates before adding unique constraint!
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Single-Column Unique Constraints
--------------------------------------------
Create a Student table with unique constraints on StudentNumber and Email.
Insert data and test uniqueness enforcement.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Composite Unique Constraint
---------------------------------------
Create a CourseSchedule table where the combination of
(CourseCode, Semester, TimeSlot) must be unique.
(Same course can be offered in multiple semesters/times)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Unique Constraint with NULLs
----------------------------------------
Create a Vehicle table with unique constraint on LicensePlate.
Allow multiple NULL license plates (for new vehicles pending registration).

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Single-Column Unique Constraints
DROP TABLE IF EXISTS Student;
GO

CREATE TABLE Student (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentNumber VARCHAR(20) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Major NVARCHAR(100),
    EnrollmentDate DATE DEFAULT GETDATE(),
    CONSTRAINT UQ_Student_Number UNIQUE (StudentNumber),
    CONSTRAINT UQ_Student_Email UNIQUE (Email)
);
GO

-- Insert valid students
INSERT INTO Student (StudentNumber, Email, FirstName, LastName, Major)
VALUES 
    ('STU-001', 'student1@university.edu', 'Alice', 'Anderson', 'Computer Science'),
    ('STU-002', 'student2@university.edu', 'Bob', 'Brown', 'Mathematics'),
    ('STU-003', 'student3@university.edu', 'Carol', 'Clark', 'Physics');
GO

-- Test uniqueness - duplicate student number
BEGIN TRY
    INSERT INTO Student (StudentNumber, Email, FirstName, LastName, Major)
    VALUES ('STU-001', 'unique@university.edu', 'David', 'Davis', 'Biology');
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test uniqueness - duplicate email
BEGIN TRY
    INSERT INTO Student (StudentNumber, Email, FirstName, LastName, Major)
    VALUES ('STU-004', 'student1@university.edu', 'David', 'Davis', 'Biology');
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

SELECT * FROM Student;
GO

/*
OUTPUT:
StudentID  StudentNumber  Email                      FirstName  LastName  Major
---------  -------------  ------------------------   ---------  --------  ----------------
1          STU-001        student1@university.edu    Alice      Anderson  Computer Science
2          STU-002        student2@university.edu    Bob        Brown     Mathematics
3          STU-003        student3@university.edu    Carol      Clark     Physics

Uniqueness enforced on both StudentNumber and Email.
*/

-- Solution 2: Composite Unique Constraint
DROP TABLE IF EXISTS CourseSchedule;
GO

CREATE TABLE CourseSchedule (
    ScheduleID INT IDENTITY(1,1) PRIMARY KEY,
    CourseCode VARCHAR(10) NOT NULL,
    Semester VARCHAR(20) NOT NULL,
    TimeSlot VARCHAR(20) NOT NULL,
    Instructor NVARCHAR(100),
    Room VARCHAR(20),
    CONSTRAINT UQ_CourseSchedule UNIQUE (CourseCode, Semester, TimeSlot)
);
GO

-- Insert valid schedules
INSERT INTO CourseSchedule (CourseCode, Semester, TimeSlot, Instructor, Room)
VALUES 
    ('CS101', 'Fall 2024', '9:00 AM', 'Dr. Smith', 'Room 101'),
    ('CS101', 'Fall 2024', '2:00 PM', 'Dr. Jones', 'Room 102'),   -- Same course, different time ✅
    ('CS101', 'Spring 2025', '9:00 AM', 'Dr. Smith', 'Room 101'), -- Same course, different semester ✅
    ('CS102', 'Fall 2024', '9:00 AM', 'Dr. Brown', 'Room 103');   -- Different course ✅
GO

-- Test uniqueness - duplicate combination
BEGIN TRY
    INSERT INTO CourseSchedule (CourseCode, Semester, TimeSlot, Instructor, Room)
    VALUES ('CS101', 'Fall 2024', '9:00 AM', 'Dr. Williams', 'Room 104');  -- Duplicate!
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

SELECT * FROM CourseSchedule ORDER BY CourseCode, Semester, TimeSlot;
GO

/*
OUTPUT:
ScheduleID  CourseCode  Semester      TimeSlot   Instructor  Room
----------  ----------  ------------  ---------  ----------  --------
1           CS101       Fall 2024     9:00 AM    Dr. Smith   Room 101
2           CS101       Fall 2024     2:00 PM    Dr. Jones   Room 102
3           CS101       Spring 2025   9:00 AM    Dr. Smith   Room 101
4           CS102       Fall 2024     9:00 AM    Dr. Brown   Room 103

Each (CourseCode, Semester, TimeSlot) combination is unique.
*/

-- Solution 3: Unique Constraint with NULLs
DROP TABLE IF EXISTS Vehicle;
GO

CREATE TABLE Vehicle (
    VehicleID INT IDENTITY(1,1) PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    LicensePlate VARCHAR(10),  -- Can be NULL for pending registration
    Make NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    Year INT NOT NULL,
    Color NVARCHAR(30),
    RegistrationDate DATE,
    CONSTRAINT UQ_Vehicle_VIN UNIQUE (VIN),
    CONSTRAINT UQ_Vehicle_LicensePlate UNIQUE (LicensePlate)
);
GO

-- Insert vehicles
INSERT INTO Vehicle (VIN, LicensePlate, Make, Model, Year, Color)
VALUES 
    ('1HGBH41JXMN109186', 'ABC-1234', 'Honda', 'Accord', 2020, 'Blue'),
    ('1FTFW1EF5DFC10312', 'XYZ-5678', 'Ford', 'F-150', 2021, 'White'),
    ('1G1JC5SH4D4123456', NULL, 'Chevrolet', 'Cruze', 2022, 'Red'),        -- Pending registration
    ('5UXWX7C56F0D12345', NULL, 'BMW', 'X5', 2023, 'Black');               -- Pending registration
GO

SELECT * FROM Vehicle;
GO

/*
OUTPUT:
VehicleID  VIN                LicensePlate  Make       Model   Year  Color
---------  -----------------  ------------  ---------  ------  ----  -----
1          1HGBH41JXMN109186  ABC-1234      Honda      Accord  2020  Blue
2          1FTFW1EF5DFC10312  XYZ-5678      Ford       F-150   2021  White
3          1G1JC5SH4D4123456  NULL          Chevrolet  Cruze   2022  Red
4          5UXWX7C56F0D12345  NULL          BMW        X5      2023  Black

Multiple NULL license plates allowed (pending registration).
*/

-- Test uniqueness - duplicate license plate
BEGIN TRY
    INSERT INTO Vehicle (VIN, LicensePlate, Make, Model, Year, Color)
    VALUES ('NEW-VIN-123456789', 'ABC-1234', 'Toyota', 'Camry', 2024, 'Silver');
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Update vehicle with license plate (complete registration)
UPDATE Vehicle
SET LicensePlate = 'NEW-1111', RegistrationDate = GETDATE()
WHERE VehicleID = 3;
GO

SELECT * FROM Vehicle WHERE VehicleID = 3;
GO

/*
OUTPUT:
VehicleID  VIN                LicensePlate  Make       Model  Year  Color  RegistrationDate
---------  -----------------  ------------  ---------  -----  ----  -----  ----------------
3          1G1JC5SH4D4123456  NEW-1111      Chevrolet  Cruze  2022  Red    2024-01-15

Registration completed with unique license plate.
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. UNIQUE CONSTRAINT BASICS
   - Enforces uniqueness on columns
   - Allows multiple NULL values
   - Can have multiple unique constraints per table
   - Automatically creates unique index
   - Used for alternate keys

2. UNIQUE vs PRIMARY KEY
   - PK: One per table, no NULLs, row identifier
   - UNIQUE: Multiple per table, allows NULLs, business uniqueness
   - Both enforce uniqueness
   - Both create indexes

3. NULL HANDLING
   - SQL Server allows multiple NULLs in unique columns
   - Use filtered unique index to prevent multiple NULLs
   - NULL represents "unknown" - each is considered unique

4. COMPOSITE UNIQUE CONSTRAINTS
   - Combination of columns must be unique
   - Order matters for index performance
   - Common for multi-column natural keys
   - Use cases: product variants, scheduling, multi-tenant

5. CONSTRAINT vs INDEX
   - Unique constraint: Logical integrity rule
   - Unique index: Physical implementation
   - Constraint preferred for data integrity
   - Index preferred for performance with flexibility

6. REAL-WORLD APPLICATIONS
   - Email addresses (user accounts)
   - SKU/Barcode (products)
   - Employee badge numbers
   - License plates
   - Social Security Numbers
   - Phone numbers

7. BEST PRACTICES
   - Always name constraints: UQ_TableName_ColumnName
   - Use NOT NULL for required unique columns
   - Index foreign keys that reference unique columns
   - Document business rules for uniqueness
   - Handle constraint violations gracefully in applications
   - Remove duplicates before adding unique constraints

================================================================================

NEXT STEPS:
-----------
In Lesson 13.7, we'll explore CHECK CONSTRAINTS:
- Data validation rules
- Simple and complex checks
- Multi-column checks
- Check constraint limitations

Continue to: 07-check-constraints.sql

================================================================================
*/
