/*
================================================================================
LESSON 13.4: PRIMARY KEY CONSTRAINTS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand primary key characteristics and requirements
2. Create single-column and composite primary keys
3. Choose appropriate columns for primary keys
4. Work with auto-increment (IDENTITY) keys
5. Understand natural vs surrogate keys
6. Handle primary key violations and conflicts
7. Modify and manage primary key constraints

Business Context:
-----------------
Every database table needs a reliable way to uniquely identify each row.
Primary keys provide this foundation, ensuring data integrity and enabling
efficient relationships between tables. Choosing the right primary key
strategy is critical for database design.

Database: RetailStore
Complexity: Beginner to Intermediate
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT IS A PRIMARY KEY?
================================================================================

A PRIMARY KEY is a constraint that uniquely identifies each row in a table.

CHARACTERISTICS:
----------------
1. UNIQUENESS: No two rows can have the same primary key value
2. NOT NULL: Primary key columns cannot contain NULL values
3. ONE PER TABLE: Each table can have only ONE primary key
4. IMMUTABILITY: Primary key values should never change
5. AUTO-INDEXED: Automatically creates a unique index (usually clustered)

Visual Representation:
----------------------
CustomerID (PRIMARY KEY)  FirstName   LastName    Email
------------------------  ----------  ----------  -----------------
1 ✅ Unique               John        Doe         john@email.com
2 ✅ Unique               Jane        Smith       jane@email.com
3 ✅ Unique               Bob         Johnson     bob@email.com
NULL ❌ Not allowed
2 ❌ Duplicate not allowed

Primary key ensures each row has a unique, non-null identifier.

*/

-- Example 1: Creating table with primary key (single column)

DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT NOT NULL PRIMARY KEY,  -- Inline primary key declaration
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    DepartmentID INT,
    HireDate DATE DEFAULT GETDATE()
);
GO

-- Insert valid data
INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID)
VALUES 
    (1, 'John', 'Doe', 'john@company.com', 10),
    (2, 'Jane', 'Smith', 'jane@company.com', 20),
    (3, 'Bob', 'Johnson', 'bob@company.com', 10);
GO

SELECT * FROM Employee;
GO

/*
OUTPUT:
EmployeeID  FirstName  LastName  Email                DepartmentID  HireDate
----------  ---------  --------  ------------------   ------------  ----------
1           John       Doe       john@company.com     10            2024-01-15
2           Jane       Smith     jane@company.com     20            2024-01-15
3           Bob        Johnson   bob@company.com      10            2024-01-15
*/

-- Try to insert duplicate primary key
INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID)
VALUES (2, 'Mike', 'Williams', 'mike@company.com', 30);
GO

/*
ERROR:
Violation of PRIMARY KEY constraint 'PK__Employee__...'.
Cannot insert duplicate key in object 'dbo.Employee'.
The duplicate key value is (2).

EXPLANATION:
Primary key 2 already exists (Jane Smith).
SQL Server prevents duplicate primary keys.
*/

-- Try to insert NULL primary key
INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID)
VALUES (NULL, 'Mike', 'Williams', 'mike@company.com', 30);
GO

/*
ERROR:
Cannot insert the value NULL into column 'EmployeeID', table 'RetailStore.dbo.Employee';
column does not allow nulls. INSERT fails.

EXPLANATION:
Primary key columns automatically have NOT NULL constraint.
*/

-- Correct insert
INSERT INTO Employee (EmployeeID, FirstName, LastName, Email, DepartmentID)
VALUES (4, 'Mike', 'Williams', 'mike@company.com', 30);
GO

/*
SUCCESS: EmployeeID 4 is unique and not null.
*/

/*
================================================================================
PART 2: PRIMARY KEY DECLARATION SYNTAXES
================================================================================

There are multiple ways to declare a primary key.
*/

-- Method 1: Inline column constraint (already shown above)
DROP TABLE IF EXISTS Method1_Example;
GO

CREATE TABLE Method1_Example (
    ID INT PRIMARY KEY,  -- Simplest syntax
    Name NVARCHAR(50)
);
GO

-- Method 2: Inline column constraint with constraint name
DROP TABLE IF EXISTS Method2_Example;
GO

CREATE TABLE Method2_Example (
    ID INT CONSTRAINT PK_Method2_ID PRIMARY KEY,  -- Named constraint
    Name NVARCHAR(50)
);
GO

-- Method 3: Table-level constraint (recommended for clarity)
DROP TABLE IF EXISTS Method3_Example;
GO

CREATE TABLE Method3_Example (
    ID INT NOT NULL,
    Name NVARCHAR(50),
    CONSTRAINT PK_Method3_ID PRIMARY KEY (ID)  -- Table-level declaration
);
GO

-- Method 4: Table-level constraint with options
DROP TABLE IF EXISTS Method4_Example;
GO

CREATE TABLE Method4_Example (
    ID INT NOT NULL,
    Name NVARCHAR(50),
    CONSTRAINT PK_Method4_ID PRIMARY KEY CLUSTERED (ID)  -- Explicit clustered
    WITH (FILLFACTOR = 90)  -- Index options
);
GO

/*
BEST PRACTICE:
- Use Method 3 or 4 for clarity and control
- Always name your constraints (easier to manage)
- Use table-level syntax for composite keys
- Specify CLUSTERED/NONCLUSTERED explicitly
*/

-- View primary key constraints
SELECT 
    t.name AS TableName,
    c.name AS ConstraintName,
    col.name AS ColumnName,
    i.type_desc AS IndexType
FROM sys.key_constraints c
INNER JOIN sys.tables t ON c.parent_object_id = t.object_id
INNER JOIN sys.index_columns ic ON c.parent_object_id = ic.object_id 
    AND c.unique_index_id = ic.index_id
INNER JOIN sys.columns col ON ic.object_id = col.object_id 
    AND ic.column_id = col.column_id
INNER JOIN sys.indexes i ON c.parent_object_id = i.object_id 
    AND c.unique_index_id = i.index_id
WHERE c.type = 'PK'
  AND t.name LIKE 'Method%'
ORDER BY t.name;
GO

/*
OUTPUT:
TableName         ConstraintName   ColumnName  IndexType
---------------   ---------------  ----------  ---------
Method1_Example   PK__Method1...   ID          CLUSTERED
Method2_Example   PK_Method2_ID    ID          CLUSTERED
Method3_Example   PK_Method3_ID    ID          CLUSTERED
Method4_Example   PK_Method4_ID    ID          CLUSTERED

All created clustered indexes by default.
*/

/*
================================================================================
PART 3: AUTO-INCREMENT PRIMARY KEYS (IDENTITY)
================================================================================

IDENTITY columns automatically generate sequential numbers.
Perfect for surrogate primary keys.

Syntax:
-------
column_name datatype IDENTITY(seed, increment)

seed: Starting value (default 1)
increment: Step value (default 1)
*/

-- Example: Auto-increment primary key
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) NOT NULL,  -- Starts at 1, increments by 1
    ProductName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2),
    CONSTRAINT PK_Product PRIMARY KEY (ProductID)
);
GO

-- Insert without specifying ProductID (auto-generated)
INSERT INTO Product (ProductName, Price)
VALUES 
    ('Laptop', 999.99),
    ('Mouse', 29.99),
    ('Keyboard', 79.99);
GO

SELECT * FROM Product;
GO

/*
OUTPUT:
ProductID  ProductName  Price
---------  -----------  ------
1          Laptop       999.99
2          Mouse        29.99
3          Keyboard     79.99

ProductID was automatically generated: 1, 2, 3
*/

-- Try to manually insert into IDENTITY column
INSERT INTO Product (ProductID, ProductName, Price)
VALUES (10, 'Monitor', 299.99);
GO

/*
ERROR:
Cannot insert explicit value for identity column in table 'Product'
when IDENTITY_INSERT is set to OFF.

EXPLANATION:
IDENTITY columns don't accept explicit values by default.
*/

-- To insert explicit values, use SET IDENTITY_INSERT
SET IDENTITY_INSERT Product ON;
GO

INSERT INTO Product (ProductID, ProductName, Price)
VALUES (10, 'Monitor', 299.99);
GO

SET IDENTITY_INSERT Product OFF;
GO

SELECT * FROM Product;
GO

/*
OUTPUT:
ProductID  ProductName  Price
---------  -----------  ------
1          Laptop       999.99
2          Mouse        29.99
3          Keyboard     79.99
10         Monitor      299.99

Manually inserted ProductID = 10
*/

-- Continue auto-increment after manual insert
INSERT INTO Product (ProductName, Price)
VALUES ('Headphones', 149.99);
GO

SELECT * FROM Product;
GO

/*
OUTPUT:
ProductID  ProductName  Price
---------  -----------  ------
1          Laptop       999.99
2          Mouse        29.99
3          Keyboard     79.99
10         Monitor      299.99
11         Headphones   149.99

Next IDENTITY value was 11 (continues from highest value)
*/

-- Useful IDENTITY functions
SELECT 
    IDENT_CURRENT('Product') AS CurrentIdentityValue,  -- Last generated value
    IDENT_SEED('Product') AS SeedValue,  -- Starting value
    IDENT_INCR('Product') AS IncrementValue;  -- Step value
GO

/*
OUTPUT:
CurrentIdentityValue  SeedValue  IncrementValue
--------------------  ---------  --------------
11                    1          1
*/

-- Custom seed and increment
DROP TABLE IF EXISTS Invoice;
GO

CREATE TABLE Invoice (
    InvoiceID INT IDENTITY(1000, 5) NOT NULL PRIMARY KEY,  -- Start 1000, step by 5
    CustomerID INT,
    InvoiceDate DATE DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2)
);
GO

INSERT INTO Invoice (CustomerID, TotalAmount)
VALUES 
    (1, 150.00),
    (2, 275.50),
    (3, 89.99);
GO

SELECT * FROM Invoice;
GO

/*
OUTPUT:
InvoiceID  CustomerID  InvoiceDate  TotalAmount
---------  ----------  -----------  -----------
1000       1           2024-01-15   150.00
1005       2           2024-01-15   275.50
1010       3           2024-01-15   89.99

IDs: 1000, 1005, 1010 (increments by 5)
*/

/*
================================================================================
PART 4: COMPOSITE PRIMARY KEYS
================================================================================

A composite primary key consists of multiple columns.
The COMBINATION of column values must be unique.

Use Cases:
----------
- Junction tables (many-to-many relationships)
- Tables where no single column is unique
- Natural keys spanning multiple columns
*/

-- Example 1: Junction table (many-to-many)
DROP TABLE IF EXISTS EmployeeProject;
GO

CREATE TABLE EmployeeProject (
    EmployeeID INT NOT NULL,
    ProjectID INT NOT NULL,
    AssignedDate DATE DEFAULT GETDATE(),
    Role NVARCHAR(50),
    CONSTRAINT PK_EmployeeProject PRIMARY KEY (EmployeeID, ProjectID)
    -- Composite key: EmployeeID + ProjectID must be unique together
);
GO

-- Insert valid data
INSERT INTO EmployeeProject (EmployeeID, ProjectID, Role)
VALUES 
    (1, 100, 'Developer'),   -- Employee 1, Project 100
    (1, 101, 'Lead'),        -- Employee 1, Project 101 (different project, OK)
    (2, 100, 'Tester'),      -- Employee 2, Project 100 (different employee, OK)
    (2, 101, 'Developer');   -- Employee 2, Project 101
GO

SELECT * FROM EmployeeProject ORDER BY EmployeeID, ProjectID;
GO

/*
OUTPUT:
EmployeeID  ProjectID  AssignedDate  Role
----------  ---------  ------------  ---------
1           100        2024-01-15    Developer
1           101        2024-01-15    Lead
2           100        2024-01-15    Tester
2           101        2024-01-15    Developer

Each combination of (EmployeeID, ProjectID) is unique.
*/

-- Try to insert duplicate combination
INSERT INTO EmployeeProject (EmployeeID, ProjectID, Role)
VALUES (1, 100, 'Manager');  -- Same EmployeeID + ProjectID as row 1
GO

/*
ERROR:
Violation of PRIMARY KEY constraint 'PK_EmployeeProject'.
Cannot insert duplicate key in object 'dbo.EmployeeProject'.
The duplicate key value is (1, 100).

EXPLANATION:
(1, 100) already exists - combination must be unique!
*/

-- These inserts ARE allowed (different combinations)
INSERT INTO EmployeeProject (EmployeeID, ProjectID, Role)
VALUES 
    (3, 100, 'Manager'),   -- Different EmployeeID
    (1, 102, 'Analyst');   -- Different ProjectID
GO

SELECT * FROM EmployeeProject ORDER BY EmployeeID, ProjectID;
GO

/*
OUTPUT:
EmployeeID  ProjectID  AssignedDate  Role
----------  ---------  ------------  ---------
1           100        2024-01-15    Developer
1           101        2024-01-15    Lead
1           102        2024-01-15    Analyst     ← New
2           100        2024-01-15    Tester
2           101        2024-01-15    Developer
3           100        2024-01-15    Manager     ← New
*/

-- Example 2: Composite natural key
DROP TABLE IF EXISTS CourseEnrollment;
GO

CREATE TABLE CourseEnrollment (
    StudentID INT NOT NULL,
    CourseCode VARCHAR(10) NOT NULL,
    Semester VARCHAR(20) NOT NULL,
    EnrollmentDate DATE DEFAULT GETDATE(),
    Grade CHAR(2),
    CONSTRAINT PK_Enrollment PRIMARY KEY (StudentID, CourseCode, Semester)
    -- Student can take same course in different semesters
);
GO

INSERT INTO CourseEnrollment (StudentID, CourseCode, Semester, Grade)
VALUES 
    (1001, 'CS101', 'Fall 2023', 'A'),
    (1001, 'CS101', 'Spring 2024', 'A'),  -- Same student, same course, different semester
    (1001, 'CS102', 'Fall 2023', 'B'),    -- Same student, different course
    (1002, 'CS101', 'Fall 2023', 'B+');   -- Different student
GO

SELECT * FROM CourseEnrollment ORDER BY StudentID, CourseCode, Semester;
GO

/*
OUTPUT:
StudentID  CourseCode  Semester      EnrollmentDate  Grade
---------  ----------  ------------  --------------  -----
1001       CS101       Fall 2023     2024-01-15      A
1001       CS101       Spring 2024   2024-01-15      A
1001       CS102       Fall 2023     2024-01-15      B
1002       CS101       Fall 2023     2024-01-15      B+

Each (StudentID, CourseCode, Semester) combination is unique.
*/

/*
================================================================================
PART 5: NATURAL KEYS VS SURROGATE KEYS
================================================================================

NATURAL KEY:
------------
A column or combination of columns that naturally exists in the data
and uniquely identifies a row.

Examples:
- Email address
- SSN (Social Security Number)
- ISBN (for books)
- License plate number

SURROGATE KEY:
--------------
An artificial key created solely for identification purposes,
typically an auto-incrementing integer.

Examples:
- CustomerID (auto-increment)
- OrderID (auto-increment)
- ProductID (auto-increment)

*/

-- Example: Natural Key (Email)
DROP TABLE IF EXISTS User_NaturalKey;
GO

CREATE TABLE User_NaturalKey (
    Email NVARCHAR(100) NOT NULL PRIMARY KEY,  -- Natural key
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    RegistrationDate DATETIME DEFAULT GETDATE()
);
GO

INSERT INTO User_NaturalKey (Email, FirstName, LastName)
VALUES 
    ('john@example.com', 'John', 'Doe'),
    ('jane@example.com', 'Jane', 'Smith');
GO

SELECT * FROM User_NaturalKey;
GO

/*
ADVANTAGES of Natural Keys:
✅ Meaningful (Email has business significance)
✅ No need for additional lookup
✅ Self-documenting

DISADVANTAGES of Natural Keys:
❌ Can change (user might change email)
❌ Can be wide (NVARCHAR(100) vs INT)
❌ Privacy concerns (exposing email in URLs)
❌ Slower joins (string comparison vs int)
*/

-- Example: Surrogate Key (Auto-increment ID)
DROP TABLE IF EXISTS User_SurrogateKey;
GO

CREATE TABLE User_SurrogateKey (
    UserID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- Surrogate key
    Email NVARCHAR(100) NOT NULL UNIQUE,  -- Natural key as unique constraint
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    RegistrationDate DATETIME DEFAULT GETDATE()
);
GO

INSERT INTO User_SurrogateKey (Email, FirstName, LastName)
VALUES 
    ('john@example.com', 'John', 'Doe'),
    ('jane@example.com', 'Jane', 'Smith');
GO

SELECT * FROM User_SurrogateKey;
GO

/*
OUTPUT:
UserID  Email               FirstName  LastName  RegistrationDate
------  ------------------  ---------  --------  ----------------
1       john@example.com    John       Doe       2024-01-15
2       jane@example.com    Jane       Smith     2024-01-15

ADVANTAGES of Surrogate Keys:
✅ Immutable (never changes)
✅ Small size (4 bytes for INT)
✅ Fast joins (integer comparison)
✅ Privacy (can hide email)
✅ Clustered index friendly

DISADVANTAGES of Surrogate Keys:
❌ No business meaning
❌ Requires additional lookup by email
❌ Extra column storage
*/

/*
RECOMMENDATION:
---------------
For most modern applications, use SURROGATE keys as primary keys
and add UNIQUE constraints on natural keys.

This gives the best of both worlds:
✅ Fast, immutable primary key for relationships
✅ Enforce uniqueness on business-meaningful columns
✅ Flexibility to change natural key values if needed
*/

/*
================================================================================
PART 6: ADDING PRIMARY KEY TO EXISTING TABLE
================================================================================

Sometimes you need to add a primary key to a table that already exists.
*/

-- Create table without primary key
DROP TABLE IF EXISTS Category;
GO

CREATE TABLE Category (
    CategoryID INT NOT NULL,
    CategoryName NVARCHAR(50),
    Description NVARCHAR(200)
);
GO

-- Insert data
INSERT INTO Category (CategoryID, CategoryName, Description)
VALUES 
    (1, 'Electronics', 'Electronic devices'),
    (2, 'Clothing', 'Apparel and accessories'),
    (3, 'Books', 'Physical and digital books');
GO

-- Check for existing constraints
SELECT name AS ConstraintName, type_desc AS ConstraintType
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('Category');
GO

/*
OUTPUT:
(0 rows)

No primary key constraint exists.
*/

-- Add primary key to existing table
ALTER TABLE Category
ADD CONSTRAINT PK_Category PRIMARY KEY (CategoryID);
GO

/*
SUCCESS: Primary key added to existing table.
*/

-- Verify the primary key was added
SELECT name AS ConstraintName, type_desc AS ConstraintType
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('Category');
GO

/*
OUTPUT:
ConstraintName  ConstraintType
--------------  --------------
PK_Category     PRIMARY_KEY_CONSTRAINT
*/

-- What if data has duplicates? Let's test
DROP TABLE IF EXISTS TestDuplicates;
GO

CREATE TABLE TestDuplicates (
    ID INT NOT NULL,
    Value NVARCHAR(50)
);
GO

-- Insert duplicate IDs
INSERT INTO TestDuplicates (ID, Value)
VALUES (1, 'First'), (2, 'Second'), (1, 'Duplicate');  -- ID 1 appears twice!
GO

-- Try to add primary key
ALTER TABLE TestDuplicates
ADD CONSTRAINT PK_TestDuplicates PRIMARY KEY (ID);
GO

/*
ERROR:
Cannot define PRIMARY KEY constraint on table 'TestDuplicates'
with duplicate values in column 'ID'.

EXPLANATION:
Primary key requires all values to be unique.
Must remove duplicates first!
*/

-- Find and remove duplicates first
SELECT ID, COUNT(*) AS DuplicateCount
FROM TestDuplicates
GROUP BY ID
HAVING COUNT(*) > 1;
GO

/*
OUTPUT:
ID  DuplicateCount
--  --------------
1   2

ID 1 appears twice - need to resolve this.
*/

-- Remove duplicate (keep one)
DELETE FROM TestDuplicates
WHERE Value = 'Duplicate';  -- Remove the duplicate row
GO

-- Now add primary key
ALTER TABLE TestDuplicates
ADD CONSTRAINT PK_TestDuplicates PRIMARY KEY (ID);
GO

/*
SUCCESS: No duplicates, primary key added successfully.
*/

/*
================================================================================
PART 7: MODIFYING AND DROPPING PRIMARY KEYS
================================================================================

Sometimes you need to modify or remove a primary key.
*/

-- Dropping a primary key
ALTER TABLE TestDuplicates
DROP CONSTRAINT PK_TestDuplicates;
GO

/*
SUCCESS: Primary key dropped.

WARNING: This also drops the underlying index!
Foreign keys referencing this table will prevent dropping.
*/

-- Verify it's gone
SELECT name AS ConstraintName
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('TestDuplicates');
GO

/*
OUTPUT:
(0 rows)

Primary key successfully removed.
*/

-- Changing primary key column requires:
-- 1. Drop existing primary key
-- 2. Add new primary key

DROP TABLE IF EXISTS ChangeKeyExample;
GO

CREATE TABLE ChangeKeyExample (
    OldID INT NOT NULL,
    NewID INT NOT NULL,
    Data NVARCHAR(50),
    CONSTRAINT PK_Old PRIMARY KEY (OldID)
);
GO

-- Change primary key from OldID to NewID
ALTER TABLE ChangeKeyExample
DROP CONSTRAINT PK_Old;
GO

ALTER TABLE ChangeKeyExample
ADD CONSTRAINT PK_New PRIMARY KEY (NewID);
GO

/*
SUCCESS: Primary key changed from OldID to NewID.

CAUTION:
- This is a schema change that can impact foreign keys
- Consider impact on dependent objects
- Test thoroughly before deploying to production
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Single-Column Primary Key with IDENTITY
---------------------------------------------------
Create a table called Department with:
- DepartmentID as auto-incrementing primary key (start at 100, increment by 10)
- DepartmentName
- ManagerID
Insert 3 departments and verify the IDs are 100, 110, 120.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Composite Primary Key
----------------------------------
Create a table for student course registrations with composite primary key
on (StudentID, CourseID, Semester). Insert data to demonstrate:
- Same student can take different courses
- Same student can take same course in different semesters
- Different students can take same course

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Natural vs Surrogate Key
------------------------------------
Create two versions of a Book table:
1. Using ISBN as natural primary key
2. Using BookID as surrogate primary key with ISBN as unique constraint
Compare the approaches.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Single-Column Primary Key with IDENTITY
DROP TABLE IF EXISTS Department;
GO

CREATE TABLE Department (
    DepartmentID INT IDENTITY(100, 10) NOT NULL,  -- Start 100, increment 10
    DepartmentName NVARCHAR(50) NOT NULL,
    ManagerID INT,
    CONSTRAINT PK_Department PRIMARY KEY (DepartmentID)
);
GO

INSERT INTO Department (DepartmentName, ManagerID)
VALUES 
    ('Engineering', 1),
    ('Marketing', 2),
    ('Sales', 3);
GO

SELECT * FROM Department;
GO

/*
OUTPUT:
DepartmentID  DepartmentName  ManagerID
------------  --------------  ---------
100           Engineering     1
110           Marketing       2
120           Sales           3

IDs correctly generated: 100, 110, 120 (increment by 10)
*/

-- Solution 2: Composite Primary Key
DROP TABLE IF EXISTS StudentCourse;
GO

CREATE TABLE StudentCourse (
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    Semester VARCHAR(20) NOT NULL,
    Grade CHAR(2),
    EnrollmentDate DATE DEFAULT GETDATE(),
    CONSTRAINT PK_StudentCourse PRIMARY KEY (StudentID, CourseID, Semester)
);
GO

INSERT INTO StudentCourse (StudentID, CourseID, Semester, Grade)
VALUES 
    -- Same student (1), different courses
    (1, 101, 'Fall 2023', 'A'),
    (1, 102, 'Fall 2023', 'B'),
    
    -- Same student (1), same course (101), different semester
    (1, 101, 'Spring 2024', 'A-'),
    
    -- Different student (2), same course (101)
    (2, 101, 'Fall 2023', 'B+'),
    (2, 102, 'Fall 2023', 'A');
GO

SELECT * FROM StudentCourse ORDER BY StudentID, CourseID, Semester;
GO

/*
OUTPUT:
StudentID  CourseID  Semester      Grade  EnrollmentDate
---------  --------  ------------  -----  --------------
1          101       Fall 2023     A      2024-01-15
1          101       Spring 2024   A-     2024-01-15
1          102       Fall 2023     B      2024-01-15
2          101       Fall 2023     B+     2024-01-15
2          102       Fall 2023     A      2024-01-15

Demonstrates all scenarios successfully!
*/

-- Solution 3: Natural vs Surrogate Key
-- Version 1: Natural key (ISBN)
DROP TABLE IF EXISTS Book_Natural;
GO

CREATE TABLE Book_Natural (
    ISBN VARCHAR(13) NOT NULL PRIMARY KEY,  -- Natural key
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100),
    PublishedYear INT,
    Price DECIMAL(10,2)
);
GO

INSERT INTO Book_Natural (ISBN, Title, Author, PublishedYear, Price)
VALUES 
    ('978-0-13-468599-1', 'Clean Code', 'Robert Martin', 2008, 39.99),
    ('978-0-13-235088-4', 'Clean Architecture', 'Robert Martin', 2017, 34.99);
GO

-- Version 2: Surrogate key (BookID)
DROP TABLE IF EXISTS Book_Surrogate;
GO

CREATE TABLE Book_Surrogate (
    BookID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- Surrogate key
    ISBN VARCHAR(13) NOT NULL UNIQUE,  -- Natural key as unique constraint
    Title NVARCHAR(200) NOT NULL,
    Author NVARCHAR(100),
    PublishedYear INT,
    Price DECIMAL(10,2)
);
GO

INSERT INTO Book_Surrogate (ISBN, Title, Author, PublishedYear, Price)
VALUES 
    ('978-0-13-468599-1', 'Clean Code', 'Robert Martin', 2008, 39.99),
    ('978-0-13-235088-4', 'Clean Architecture', 'Robert Martin', 2017, 34.99);
GO

-- Compare the tables
SELECT * FROM Book_Natural;
SELECT * FROM Book_Surrogate;
GO

/*
COMPARISON:

Book_Natural (Natural Key):
ISBN              Title              Author         PublishedYear  Price
----------------  ----------------   -------------  -------------  -----
978-0-13-468599-1 Clean Code         Robert Martin  2008           39.99
978-0-13-235088-4 Clean Architecture Robert Martin  2017           34.99

Book_Surrogate (Surrogate Key):
BookID  ISBN              Title              Author         PublishedYear  Price
------  ----------------  ----------------   -------------  -------------  -----
1       978-0-13-468599-1 Clean Code         Robert Martin  2008           39.99
2       978-0-13-235088-4 Clean Architecture Robert Martin  2017           34.99

ANALYSIS:
Natural Key:
- ✅ ISBN is meaningful
- ✅ No extra column
- ❌ Wide key (13 bytes vs 4)
- ❌ Slower joins

Surrogate Key:
- ✅ Small, fast (4 bytes)
- ✅ Immutable
- ✅ Fast joins
- ✅ Still enforces ISBN uniqueness
- ❌ Extra column
- ❌ Need to query by ISBN for lookups

RECOMMENDATION: Use surrogate key (Book_Surrogate approach) for better performance.
*/

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. PRIMARY KEY BASICS
   - Uniquely identifies each row
   - Automatically NOT NULL
   - Only ONE per table
   - Creates unique index (usually clustered)
   - Values should never change

2. IDENTITY (AUTO-INCREMENT)
   - Perfect for surrogate keys
   - IDENTITY(seed, increment)
   - Use SET IDENTITY_INSERT ON to insert explicit values
   - IDENT_CURRENT() to get last value

3. SINGLE VS COMPOSITE KEYS
   - Single column: Most common, simplest
   - Composite: Multiple columns, combination must be unique
   - Use composite for junction tables and natural keys

4. NATURAL VS SURROGATE KEYS
   - Natural: Meaningful business data (Email, SSN)
   - Surrogate: Artificial identifier (auto-increment ID)
   - Best practice: Surrogate as PK + UNIQUE on natural key

5. ADDING/MODIFYING PRIMARY KEYS
   - Can add to existing table with ALTER TABLE
   - Must remove duplicates first
   - Dropping PK also drops underlying index
   - Changing PK requires drop then add

6. NAMING CONVENTIONS
   - Name constraints explicitly: PK_TableName
   - Use descriptive column names: TableNameID
   - Be consistent across schema

7. BEST PRACTICES
   - Always use primary keys (no exceptions!)
   - Prefer surrogate keys for performance
   - Keep primary keys small and immutable
   - Document your key choice rationale
   - Test uniqueness before adding PK to existing data

================================================================================

NEXT STEPS:
-----------
In Lesson 13.5, we'll explore FOREIGN KEY CONSTRAINTS:
- Referential integrity
- Creating foreign key relationships
- CASCADE options (DELETE, UPDATE)
- Self-referencing foreign keys

Continue to: 05-foreign-key-constraints.sql

================================================================================
*/
