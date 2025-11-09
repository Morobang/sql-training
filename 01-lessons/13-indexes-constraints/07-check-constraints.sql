/*
================================================================================
LESSON 13.7: CHECK CONSTRAINTS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand check constraints and their purpose
2. Create simple and complex check constraints
3. Implement multi-column check constraints
4. Use expressions and functions in check constraints
5. Handle check constraint violations
6. Understand check constraint limitations
7. Apply check constraints in real-world scenarios

Business Context:
-----------------
A retail database needs to ensure data quality: prices must be positive,
quantities can't be negative, order dates can't be in the future, and
email addresses must contain an @ symbol. Check constraints enforce these
business rules at the database level, preventing invalid data from ever
entering the system.

Database: RetailStore
Complexity: Beginner to Intermediate
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: WHAT IS A CHECK CONSTRAINT?
================================================================================

A CHECK constraint validates data based on a logical expression.
It ensures values meet specific criteria before allowing INSERT or UPDATE.

CHARACTERISTICS:
----------------
1. ENFORCES BUSINESS RULES: Validates data against conditions
2. EXPRESSION-BASED: Uses Boolean expressions (returns TRUE/FALSE)
3. PREVENTS INVALID DATA: Rejects values that don't meet criteria
4. MULTIPLE PER TABLE: Can have many check constraints
5. COLUMN OR TABLE LEVEL: Can reference one or multiple columns

Visual Representation:
----------------------
Product Table with Check Constraints:

ProductID  Price     Quantity  Rating  Status
---------  --------  --------  ------  --------
1          99.99 ✅  50 ✅     4.5 ✅  Active ✅
2          -10.00 ❌ 100       5.0     Active     -- Negative price rejected
3          150.00    -5 ❌     3.8     Active     -- Negative quantity rejected
4          200.00    25        6.0 ❌  Active     -- Rating > 5 rejected
5          50.00     10        4.0     Invalid ❌ -- Invalid status rejected

Check Constraints:
- Price must be >= 0
- Quantity must be >= 0
- Rating must be between 0 and 5
- Status must be 'Active', 'Inactive', or 'Discontinued'

*/

-- Example: Product table with check constraints
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    Rating DECIMAL(3,2),
    Status VARCHAR(20) NOT NULL,
    -- Check constraints
    CONSTRAINT CK_Product_Price CHECK (Price >= 0),
    CONSTRAINT CK_Product_Quantity CHECK (Quantity >= 0),
    CONSTRAINT CK_Product_Rating CHECK (Rating >= 0 AND Rating <= 5),
    CONSTRAINT CK_Product_Status CHECK (Status IN ('Active', 'Inactive', 'Discontinued'))
);
GO

-- Insert valid data
INSERT INTO Product (ProductName, Price, Quantity, Rating, Status)
VALUES 
    ('Laptop', 999.99, 50, 4.5, 'Active'),
    ('Mouse', 29.99, 100, 4.8, 'Active'),
    ('Keyboard', 79.99, 75, 4.2, 'Inactive');
GO

SELECT * FROM Product;
GO

/*
OUTPUT:
ProductID  ProductName  Price    Quantity  Rating  Status
---------  -----------  -------  --------  ------  ----------
1          Laptop       999.99   50        4.5     Active
2          Mouse        29.99    100       4.8     Active
3          Keyboard     79.99    75        4.2     Inactive

All values satisfy check constraints.
*/

-- Try to insert negative price
INSERT INTO Product (ProductName, Price, Quantity, Rating, Status)
VALUES ('Monitor', -100.00, 25, 4.0, 'Active');
GO

/*
ERROR:
The INSERT statement conflicted with the CHECK constraint "CK_Product_Price".
The conflict occurred in database "RetailStore", table "dbo.Product", column 'Price'.

EXPLANATION:
Price -100.00 fails the check: Price >= 0
*/

-- Try to insert negative quantity
INSERT INTO Product (ProductName, Price, Quantity, Rating, Status)
VALUES ('Monitor', 299.99, -10, 4.0, 'Active');
GO

/*
ERROR:
The INSERT statement conflicted with the CHECK constraint "CK_Product_Quantity".

EXPLANATION:
Quantity -10 fails the check: Quantity >= 0
*/

-- Try to insert invalid rating
INSERT INTO Product (ProductName, Price, Quantity, Rating, Status)
VALUES ('Monitor', 299.99, 25, 6.5, 'Active');
GO

/*
ERROR:
The INSERT statement conflicted with the CHECK constraint "CK_Product_Rating".

EXPLANATION:
Rating 6.5 fails the check: Rating >= 0 AND Rating <= 5
*/

-- Try to insert invalid status
INSERT INTO Product (ProductName, Price, Quantity, Rating, Status)
VALUES ('Monitor', 299.99, 25, 4.0, 'OutOfStock');
GO

/*
ERROR:
The INSERT statement conflicted with the CHECK constraint "CK_Product_Status".

EXPLANATION:
'OutOfStock' is not in the allowed list: ('Active', 'Inactive', 'Discontinued')
*/

-- Valid insert
INSERT INTO Product (ProductName, Price, Quantity, Rating, Status)
VALUES ('Monitor', 299.99, 25, 4.0, 'Active');
GO

/*
SUCCESS: All constraints satisfied.
*/

/*
================================================================================
PART 2: SIMPLE CHECK CONSTRAINTS
================================================================================

Simple check constraints validate a single column against a condition.
*/

-- Example 1: Age validation
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Age INT NOT NULL,
    Salary DECIMAL(10,2),
    HireDate DATE DEFAULT GETDATE(),
    CONSTRAINT CK_Employee_Age CHECK (Age >= 18 AND Age <= 75),
    CONSTRAINT CK_Employee_Salary CHECK (Salary > 0)
);
GO

-- Valid employees
INSERT INTO Employee (FirstName, LastName, Age, Salary)
VALUES 
    ('John', 'Doe', 30, 75000.00),
    ('Jane', 'Smith', 45, 95000.00);
GO

-- Invalid - too young
BEGIN TRY
    INSERT INTO Employee (FirstName, LastName, Age, Salary)
    VALUES ('Minor', 'Child', 16, 50000.00);
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Invalid - too old
BEGIN TRY
    INSERT INTO Employee (FirstName, LastName, Age, Salary)
    VALUES ('Senior', 'Citizen', 80, 50000.00);
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Invalid - negative salary
BEGIN TRY
    INSERT INTO Employee (FirstName, LastName, Age, Salary)
    VALUES ('Negative', 'Salary', 30, -1000.00);
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Example 2: Email format validation
DROP TABLE IF EXISTS Customer;
GO

CREATE TABLE Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20),
    CONSTRAINT CK_Customer_Email CHECK (Email LIKE '%@%'),  -- Must contain @
    CONSTRAINT CK_Customer_Phone CHECK (Phone LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')  -- Format: XXX-XXXX
);
GO

-- Valid customer
INSERT INTO Customer (FirstName, LastName, Email, Phone)
VALUES ('John', 'Doe', 'john@example.com', '555-1234');
GO

-- Invalid email (no @)
BEGIN TRY
    INSERT INTO Customer (FirstName, LastName, Email, Phone)
    VALUES ('Jane', 'Smith', 'jane.example.com', '555-5678');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Email must contain @ symbol';
END CATCH;
GO

-- Invalid phone format
BEGIN TRY
    INSERT INTO Customer (FirstName, LastName, Email, Phone)
    VALUES ('Bob', 'Johnson', 'bob@example.com', '1234567');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Phone must be in format XXX-XXXX';
END CATCH;
GO

-- Example 3: Date validation
DROP TABLE IF EXISTS [Order];
GO

CREATE TABLE [Order] (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE NOT NULL,
    ShipDate DATE,
    DeliveryDate DATE,
    TotalAmount DECIMAL(10,2),
    CONSTRAINT CK_Order_Date CHECK (OrderDate <= GETDATE()),  -- Can't be in future
    CONSTRAINT CK_Order_Amount CHECK (TotalAmount >= 0)
);
GO

-- Valid order
INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount)
VALUES (1, GETDATE(), 150.00);
GO

-- Invalid - future date
BEGIN TRY
    INSERT INTO [Order] (CustomerID, OrderDate, TotalAmount)
    VALUES (1, DATEADD(DAY, 1, GETDATE()), 200.00);
END TRY
BEGIN CATCH
    PRINT 'ERROR: Order date cannot be in the future';
END CATCH;
GO

/*
================================================================================
PART 3: MULTI-COLUMN CHECK CONSTRAINTS
================================================================================

Check constraints can reference multiple columns to enforce relationships
between them.
*/

-- Example 1: Date range validation
DROP TABLE IF EXISTS Project;
GO

CREATE TABLE Project (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName NVARCHAR(200) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Budget DECIMAL(12,2),
    ActualCost DECIMAL(12,2),
    CONSTRAINT CK_Project_Dates CHECK (EndDate >= StartDate),  -- End after start
    CONSTRAINT CK_Project_Budget CHECK (ActualCost <= Budget OR ActualCost IS NULL)  -- Can't exceed budget
);
GO

-- Valid project
INSERT INTO Project (ProjectName, StartDate, EndDate, Budget, ActualCost)
VALUES ('Website Redesign', '2024-01-01', '2024-06-30', 100000.00, 95000.00);
GO

-- Invalid - end date before start date
BEGIN TRY
    INSERT INTO Project (ProjectName, StartDate, EndDate, Budget, ActualCost)
    VALUES ('Invalid Project', '2024-06-01', '2024-01-01', 50000.00, NULL);
END TRY
BEGIN CATCH
    PRINT 'ERROR: End date must be >= Start date';
END CATCH;
GO

-- Invalid - actual cost exceeds budget
BEGIN TRY
    INSERT INTO Project (ProjectName, StartDate, EndDate, Budget, ActualCost)
    VALUES ('Over Budget Project', '2024-01-01', '2024-12-31', 50000.00, 75000.00);
END TRY
BEGIN CATCH
    PRINT 'ERROR: Actual cost cannot exceed budget';
END CATCH;
GO

-- Example 2: Discount validation
DROP TABLE IF EXISTS ProductDiscount;
GO

CREATE TABLE ProductDiscount (
    DiscountID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    RegularPrice DECIMAL(10,2) NOT NULL,
    DiscountPrice DECIMAL(10,2) NOT NULL,
    DiscountPercent AS (CAST((RegularPrice - DiscountPrice) * 100.0 / RegularPrice AS DECIMAL(5,2))) PERSISTED,
    CONSTRAINT CK_Discount_Price CHECK (DiscountPrice < RegularPrice),  -- Discount must be lower
    CONSTRAINT CK_Discount_Positive CHECK (RegularPrice > 0 AND DiscountPrice > 0)
);
GO

-- Valid discount
INSERT INTO ProductDiscount (ProductID, RegularPrice, DiscountPrice)
VALUES (1, 100.00, 80.00);  -- 20% discount
GO

SELECT * FROM ProductDiscount;
GO

/*
OUTPUT:
DiscountID  ProductID  RegularPrice  DiscountPrice  DiscountPercent
----------  ---------  ------------  -------------  ---------------
1           1          100.00        80.00          20.00
*/

-- Invalid - discount price higher than regular
BEGIN TRY
    INSERT INTO ProductDiscount (ProductID, RegularPrice, DiscountPrice)
    VALUES (2, 100.00, 150.00);
END TRY
BEGIN CATCH
    PRINT 'ERROR: Discount price must be less than regular price';
END CATCH;
GO

-- Example 3: Shipping validation
DROP TABLE IF EXISTS Shipment;
GO

CREATE TABLE Shipment (
    ShipmentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    OrderDate DATE NOT NULL,
    ShipDate DATE,
    DeliveryDate DATE,
    Weight DECIMAL(8,2),
    Dimensions VARCHAR(50),
    CONSTRAINT CK_Shipment_ShipDate CHECK (ShipDate >= OrderDate OR ShipDate IS NULL),
    CONSTRAINT CK_Shipment_DeliveryDate CHECK (DeliveryDate >= ShipDate OR DeliveryDate IS NULL),
    CONSTRAINT CK_Shipment_Weight CHECK (Weight > 0 OR Weight IS NULL)
);
GO

-- Valid shipment
INSERT INTO Shipment (OrderID, OrderDate, ShipDate, DeliveryDate, Weight)
VALUES 
    (1, '2024-01-10', '2024-01-11', '2024-01-15', 5.5),
    (2, '2024-01-12', NULL, NULL, 3.2);  -- Not yet shipped
GO

-- Invalid - ship date before order date
BEGIN TRY
    INSERT INTO Shipment (OrderID, OrderDate, ShipDate, DeliveryDate, Weight)
    VALUES (3, '2024-01-20', '2024-01-15', '2024-01-25', 10.0);
END TRY
BEGIN CATCH
    PRINT 'ERROR: Ship date cannot be before order date';
END CATCH;
GO

-- Invalid - delivery date before ship date
BEGIN TRY
    INSERT INTO Shipment (OrderID, OrderDate, ShipDate, DeliveryDate, Weight)
    VALUES (3, '2024-01-20', '2024-01-21', '2024-01-20', 10.0);
END TRY
BEGIN CATCH
    PRINT 'ERROR: Delivery date cannot be before ship date';
END CATCH;
GO

/*
================================================================================
PART 4: COMPLEX CHECK CONSTRAINTS
================================================================================

Check constraints can use complex expressions, functions, and logic.
*/

-- Example 1: Using CASE expressions
DROP TABLE IF EXISTS EmployeeContract;
GO

CREATE TABLE EmployeeContract (
    ContractID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    ContractType VARCHAR(20) NOT NULL,
    HourlyRate DECIMAL(8,2),
    AnnualSalary DECIMAL(10,2),
    CONSTRAINT CK_Contract_Compensation CHECK (
        (ContractType = 'Hourly' AND HourlyRate IS NOT NULL AND AnnualSalary IS NULL) OR
        (ContractType = 'Salary' AND AnnualSalary IS NOT NULL AND HourlyRate IS NULL) OR
        (ContractType = 'Commission' AND HourlyRate IS NULL AND AnnualSalary IS NULL)
    )
);
GO

-- Valid contracts
INSERT INTO EmployeeContract (EmployeeID, ContractType, HourlyRate, AnnualSalary)
VALUES 
    (1, 'Hourly', 25.00, NULL),     -- Hourly worker
    (2, 'Salary', NULL, 75000.00),  -- Salaried employee
    (3, 'Commission', NULL, NULL);  -- Commission-based
GO

-- Invalid - hourly with annual salary
BEGIN TRY
    INSERT INTO EmployeeContract (EmployeeID, ContractType, HourlyRate, AnnualSalary)
    VALUES (4, 'Hourly', 30.00, 50000.00);  -- Both rates specified
END TRY
BEGIN CATCH
    PRINT 'ERROR: Hourly contracts cannot have annual salary';
END CATCH;
GO

-- Invalid - salary with hourly rate
BEGIN TRY
    INSERT INTO EmployeeContract (EmployeeID, ContractType, HourlyRate, AnnualSalary)
    VALUES (5, 'Salary', 25.00, 75000.00);  -- Both rates specified
END TRY
BEGIN CATCH
    PRINT 'ERROR: Salaried contracts cannot have hourly rate';
END CATCH;
GO

-- Example 2: Using mathematical functions
DROP TABLE IF EXISTS GeographicCoordinate;
GO

CREATE TABLE GeographicCoordinate (
    CoordinateID INT IDENTITY(1,1) PRIMARY KEY,
    LocationName NVARCHAR(100),
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    CONSTRAINT CK_Coord_Latitude CHECK (Latitude >= -90 AND Latitude <= 90),
    CONSTRAINT CK_Coord_Longitude CHECK (Longitude >= -180 AND Longitude <= 180)
);
GO

-- Valid coordinates
INSERT INTO GeographicCoordinate (LocationName, Latitude, Longitude)
VALUES 
    ('New York City', 40.7128, -74.0060),
    ('London', 51.5074, -0.1278),
    ('Tokyo', 35.6762, 139.6503);
GO

-- Invalid latitude
BEGIN TRY
    INSERT INTO GeographicCoordinate (LocationName, Latitude, Longitude)
    VALUES ('Invalid Location', 100.0, 50.0);  -- Latitude out of range
END TRY
BEGIN CATCH
    PRINT 'ERROR: Latitude must be between -90 and 90';
END CATCH;
GO

-- Example 3: String validation with patterns
DROP TABLE IF EXISTS UserAccount;
GO

CREATE TABLE UserAccount (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    PostalCode VARCHAR(10),
    CONSTRAINT CK_User_Username CHECK (
        LEN(Username) >= 3 AND 
        LEN(Username) <= 20 AND 
        Username NOT LIKE '%[^a-zA-Z0-9_]%'  -- Only letters, numbers, underscore
    ),
    CONSTRAINT CK_User_Email CHECK (
        Email LIKE '%@%.%' AND 
        LEN(Email) >= 5
    ),
    CONSTRAINT CK_User_PostalCode CHECK (
        PostalCode LIKE '[0-9][0-9][0-9][0-9][0-9]' OR  -- US ZIP
        PostalCode LIKE '[A-Z][0-9][A-Z] [0-9][A-Z][0-9]'  -- Canadian
    )
);
GO

-- Valid users
INSERT INTO UserAccount (Username, Email, PostalCode)
VALUES 
    ('john_doe', 'john@example.com', '12345'),
    ('jane_smith', 'jane@example.com', 'A1B 2C3');
GO

-- Invalid username (too short)
BEGIN TRY
    INSERT INTO UserAccount (Username, Email, PostalCode)
    VALUES ('ab', 'test@example.com', '12345');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Username must be 3-20 characters';
END CATCH;
GO

-- Invalid username (special characters)
BEGIN TRY
    INSERT INTO UserAccount (Username, Email, PostalCode)
    VALUES ('user@name', 'test@example.com', '12345');
END TRY
BEGIN CATCH
    PRINT 'ERROR: Username can only contain letters, numbers, and underscore';
END CATCH;
GO

/*
================================================================================
PART 5: CHECK CONSTRAINT LIMITATIONS
================================================================================

Check constraints have some important limitations to be aware of.
*/

-- LIMITATION 1: Cannot reference other tables
-- This will NOT work:

/*
CREATE TABLE OrderLine (
    OrderLineID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT,
    -- This is INVALID - can't reference Product table
    CONSTRAINT CK_Invalid CHECK (ProductID IN (SELECT ProductID FROM Product))
);
*/

-- Solution: Use FOREIGN KEY instead
DROP TABLE IF EXISTS OrderLine;
GO

CREATE TABLE OrderLine (
    OrderLineID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    Quantity INT NOT NULL,
    CONSTRAINT FK_OrderLine_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID),
    CONSTRAINT CK_OrderLine_Quantity CHECK (Quantity > 0)
);
GO

-- LIMITATION 2: Cannot use non-deterministic functions
-- These functions are NOT allowed in check constraints:
-- - GETDATE()
-- - NEWID()
-- - RAND()
-- - @@CONNECTIONS, @@CPU_BUSY, etc.

/*
-- This is INVALID:
CREATE TABLE InvalidTable (
    ID INT PRIMARY KEY,
    CreatedDate DATE,
    CONSTRAINT CK_Invalid_Date CHECK (CreatedDate <= GETDATE())  -- NOT allowed!
);
*/

-- Solution: Use DEFAULT constraint or triggers instead
DROP TABLE IF EXISTS ValidTable;
GO

CREATE TABLE ValidTable (
    ID INT PRIMARY KEY,
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE),  -- Use DEFAULT
    ModifiedDate DATE
);
GO

-- LIMITATION 3: Cannot reference computed columns
-- Complex validation may require triggers

-- LIMITATION 4: Performance impact
-- Complex check constraints are evaluated on every INSERT/UPDATE
-- Keep them simple for better performance

/*
================================================================================
PART 6: MANAGING CHECK CONSTRAINTS
================================================================================
*/

-- Add check constraint to existing table
DROP TABLE IF EXISTS Invoice;
GO

CREATE TABLE Invoice (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(20) NOT NULL
);
GO

-- Add check constraint after table creation
ALTER TABLE Invoice
ADD CONSTRAINT CK_Invoice_Amount CHECK (TotalAmount >= 0);
GO

ALTER TABLE Invoice
ADD CONSTRAINT CK_Invoice_Status CHECK (Status IN ('Draft', 'Sent', 'Paid', 'Cancelled'));
GO

-- Insert test data
INSERT INTO Invoice (InvoiceDate, TotalAmount, Status)
VALUES (GETDATE(), 1500.00, 'Sent');
GO

-- Drop check constraint
ALTER TABLE Invoice
DROP CONSTRAINT CK_Invoice_Status;
GO

-- Re-add with modified values
ALTER TABLE Invoice
ADD CONSTRAINT CK_Invoice_Status CHECK (Status IN ('Draft', 'Sent', 'Paid', 'Cancelled', 'Overdue'));
GO

-- Disable check constraint (for bulk operations)
ALTER TABLE Invoice
NOCHECK CONSTRAINT CK_Invoice_Amount;
GO

-- Now can insert invalid data (not recommended!)
INSERT INTO Invoice (InvoiceDate, TotalAmount, Status)
VALUES (GETDATE(), -500.00, 'Draft');  -- Negative amount allowed while disabled
GO

-- Re-enable constraint (with checking existing data)
ALTER TABLE Invoice
WITH CHECK CHECK CONSTRAINT CK_Invoice_Amount;
GO

/*
ERROR: Cannot enable constraint because existing data violates it.
Must fix data first!
*/

-- Fix the invalid data
DELETE FROM Invoice WHERE TotalAmount < 0;
GO

-- Now can re-enable
ALTER TABLE Invoice
WITH CHECK CHECK CONSTRAINT CK_Invoice_Amount;
GO

-- View all check constraints
SELECT 
    OBJECT_NAME(cc.parent_object_id) AS TableName,
    cc.name AS ConstraintName,
    cc.definition AS CheckDefinition,
    cc.is_disabled AS IsDisabled
FROM sys.check_constraints cc
WHERE OBJECT_NAME(cc.parent_object_id) IN ('Product', 'Employee', 'Invoice', 'Project')
ORDER BY TableName, ConstraintName;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Simple Check Constraints
------------------------------------
Create a StudentGrade table with check constraints for:
- Score must be between 0 and 100
- LetterGrade must be A, B, C, D, or F
- Credits must be positive

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Multi-Column Check Constraint
-----------------------------------------
Create a RoomBooking table with check constraints ensuring:
- CheckOutDate >= CheckInDate
- NumberOfGuests > 0
- TotalCharge >= 0

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Complex Check Constraint
------------------------------------
Create a EmployeeBonus table where:
- If BonusType is 'Fixed', FixedAmount must be NOT NULL and Percentage must be NULL
- If BonusType is 'Percentage', Percentage must be NOT NULL (0-100) and FixedAmount must be NULL

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Simple Check Constraints
DROP TABLE IF EXISTS StudentGrade;
GO

CREATE TABLE StudentGrade (
    GradeID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseCode VARCHAR(10) NOT NULL,
    Score DECIMAL(5,2) NOT NULL,
    LetterGrade CHAR(1) NOT NULL,
    Credits INT NOT NULL,
    Semester VARCHAR(20) NOT NULL,
    CONSTRAINT CK_StudentGrade_Score CHECK (Score >= 0 AND Score <= 100),
    CONSTRAINT CK_StudentGrade_Letter CHECK (LetterGrade IN ('A', 'B', 'C', 'D', 'F')),
    CONSTRAINT CK_StudentGrade_Credits CHECK (Credits > 0)
);
GO

-- Test valid data
INSERT INTO StudentGrade (StudentID, CourseCode, Score, LetterGrade, Credits, Semester)
VALUES 
    (1001, 'CS101', 95.5, 'A', 3, 'Fall 2024'),
    (1002, 'MATH201', 82.0, 'B', 4, 'Fall 2024'),
    (1003, 'ENG101', 70.5, 'C', 3, 'Fall 2024');
GO

-- Test invalid score
BEGIN TRY
    INSERT INTO StudentGrade (StudentID, CourseCode, Score, LetterGrade, Credits, Semester)
    VALUES (1004, 'PHYS101', 105.0, 'A', 3, 'Fall 2024');
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: Score out of range';
END CATCH;
GO

-- Test invalid letter grade
BEGIN TRY
    INSERT INTO StudentGrade (StudentID, CourseCode, Score, LetterGrade, Credits, Semester)
    VALUES (1004, 'PHYS101', 85.0, 'X', 3, 'Fall 2024');
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: Invalid letter grade';
END CATCH;
GO

SELECT * FROM StudentGrade;
GO

-- Solution 2: Multi-Column Check Constraint
DROP TABLE IF EXISTS RoomBooking;
GO

CREATE TABLE RoomBooking (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    RoomNumber VARCHAR(10) NOT NULL,
    GuestName NVARCHAR(100) NOT NULL,
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    NumberOfGuests INT NOT NULL,
    TotalCharge DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_RoomBooking_Dates CHECK (CheckOutDate >= CheckInDate),
    CONSTRAINT CK_RoomBooking_Guests CHECK (NumberOfGuests > 0),
    CONSTRAINT CK_RoomBooking_Charge CHECK (TotalCharge >= 0)
);
GO

-- Test valid bookings
INSERT INTO RoomBooking (RoomNumber, GuestName, CheckInDate, CheckOutDate, NumberOfGuests, TotalCharge)
VALUES 
    ('101', 'John Doe', '2024-01-15', '2024-01-17', 2, 450.00),
    ('102', 'Jane Smith', '2024-01-16', '2024-01-16', 1, 150.00),  -- Same day
    ('103', 'Bob Johnson', '2024-01-20', '2024-01-25', 4, 1200.00);
GO

-- Test invalid dates (checkout before checkin)
BEGIN TRY
    INSERT INTO RoomBooking (RoomNumber, GuestName, CheckInDate, CheckOutDate, NumberOfGuests, TotalCharge)
    VALUES ('104', 'Invalid Booking', '2024-01-20', '2024-01-15', 2, 300.00);
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: CheckOut before CheckIn';
END CATCH;
GO

-- Test invalid guest count
BEGIN TRY
    INSERT INTO RoomBooking (RoomNumber, GuestName, CheckInDate, CheckOutDate, NumberOfGuests, TotalCharge)
    VALUES ('104', 'No Guests', '2024-01-20', '2024-01-22', 0, 300.00);
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: NumberOfGuests must be positive';
END CATCH;
GO

SELECT * FROM RoomBooking;
GO

-- Solution 3: Complex Check Constraint
DROP TABLE IF EXISTS EmployeeBonus;
GO

CREATE TABLE EmployeeBonus (
    BonusID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    BonusType VARCHAR(20) NOT NULL,
    FixedAmount DECIMAL(10,2),
    Percentage DECIMAL(5,2),
    BonusYear INT NOT NULL,
    CONSTRAINT CK_EmployeeBonus_Type CHECK (BonusType IN ('Fixed', 'Percentage')),
    CONSTRAINT CK_EmployeeBonus_Values CHECK (
        (BonusType = 'Fixed' AND FixedAmount IS NOT NULL AND Percentage IS NULL) OR
        (BonusType = 'Percentage' AND Percentage IS NOT NULL AND FixedAmount IS NULL AND Percentage >= 0 AND Percentage <= 100)
    )
);
GO

-- Test valid bonuses
INSERT INTO EmployeeBonus (EmployeeID, BonusType, FixedAmount, Percentage, BonusYear)
VALUES 
    (101, 'Fixed', 5000.00, NULL, 2024),
    (102, 'Percentage', NULL, 10.5, 2024),
    (103, 'Fixed', 7500.00, NULL, 2024);
GO

-- Test invalid - Fixed with Percentage
BEGIN TRY
    INSERT INTO EmployeeBonus (EmployeeID, BonusType, FixedAmount, Percentage, BonusYear)
    VALUES (104, 'Fixed', 5000.00, 15.0, 2024);
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: Fixed bonus cannot have percentage';
END CATCH;
GO

-- Test invalid - Percentage out of range
BEGIN TRY
    INSERT INTO EmployeeBonus (EmployeeID, BonusType, FixedAmount, Percentage, BonusYear)
    VALUES (104, 'Percentage', NULL, 150.0, 2024);
END TRY
BEGIN CATCH
    PRINT 'Caught expected error: Percentage must be 0-100';
END CATCH;
GO

SELECT * FROM EmployeeBonus;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. CHECK CONSTRAINT BASICS
   - Validates data against Boolean expression
   - Prevents invalid data from entering table
   - Enforces business rules at database level
   - Multiple check constraints per table allowed

2. SIMPLE CHECK CONSTRAINTS
   - Single column validation
   - Range checks (age, price, quantity)
   - Pattern matching (email, phone)
   - Value lists (status, category)

3. MULTI-COLUMN CONSTRAINTS
   - Validate relationships between columns
   - Date ranges (end >= start)
   - Budget validation (actual <= budget)
   - Conditional logic across columns

4. COMPLEX CONSTRAINTS
   - CASE expressions for conditional logic
   - String pattern validation
   - Mathematical validations
   - Multiple conditions with AND/OR

5. LIMITATIONS
   - Cannot reference other tables (use FK instead)
   - Cannot use non-deterministic functions
   - Cannot reference computed columns in some cases
   - Performance impact on INSERT/UPDATE

6. MANAGEMENT
   - Can add/drop constraints with ALTER TABLE
   - Can disable/enable for bulk operations
   - Must fix invalid data before re-enabling
   - Always name constraints for easier management

7. BEST PRACTICES
   - Keep constraints simple for performance
   - Use meaningful constraint names: CK_Table_Column
   - Document business rules
   - Test edge cases
   - Handle violations gracefully in applications
   - Consider triggers for complex validation

================================================================================

NEXT STEPS:
-----------
In Lesson 13.8, we'll explore DEFAULT CONSTRAINTS:
- Setting default values for columns
- Dynamic defaults (GETDATE, NEWID)
- Default vs NULL handling
- Managing default constraints

Continue to: 08-default-constraints.sql

================================================================================
*/
