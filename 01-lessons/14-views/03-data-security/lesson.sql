/*
================================================================================
LESSON 14.3: DATA SECURITY WITH VIEWS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Implement column-level security with views
2. Implement row-level security with views
3. Create user-specific views
4. Hide sensitive data effectively
5. Apply security best practices
6. Understand view permissions
7. Implement multi-tenant data isolation

Business Context:
-----------------
Data security is critical in modern applications. Views provide a powerful
mechanism to control what data users can see without modifying application
code or using complex permission schemes. This is essential for compliance
(GDPR, HIPAA, SOX) and protecting sensitive business information.

Database: RetailStore
Complexity: Intermediate
Estimated Time: 40 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: COLUMN-LEVEL SECURITY
================================================================================

Hide sensitive columns by selecting only non-sensitive data in views.

SCENARIO: Employee table contains sensitive information (SSN, Salary)
GOAL: Public directory shows only basic info
*/

-- Create Employee table with sensitive data
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone VARCHAR(20),
    Department NVARCHAR(50),
    Title NVARCHAR(100),
    Salary DECIMAL(10,2),  -- SENSITIVE
    SSN VARCHAR(11),  -- SENSITIVE
    BankAccount VARCHAR(20),  -- SENSITIVE
    HireDate DATE,
    ManagerID INT
);
GO

-- Insert sample data
INSERT INTO Employee (FirstName, LastName, Email, Phone, Department, Title, Salary, SSN, BankAccount, HireDate, ManagerID)
VALUES 
    ('John', 'Doe', 'john.doe@company.com', '555-0101', 'Engineering', 'Senior Engineer', 95000, '123-45-6789', '1234567890', '2020-01-15', NULL),
    ('Jane', 'Smith', 'jane.smith@company.com', '555-0102', 'Sales', 'Sales Manager', 85000, '234-56-7890', '2345678901', '2019-03-20', NULL),
    ('Bob', 'Johnson', 'bob.johnson@company.com', '555-0103', 'Engineering', 'Junior Engineer', 65000, '345-67-8901', '3456789012', '2021-06-10', 1),
    ('Alice', 'Williams', 'alice.williams@company.com', '555-0104', 'Sales', 'Sales Rep', 55000, '456-78-9012', '4567890123', '2022-01-05', 2);
GO

-- PUBLIC VIEW: Hide all sensitive columns
CREATE VIEW EmployeeDirectory AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Phone,
    Department,
    Title
    -- Salary, SSN, BankAccount NOT included
FROM Employee;
GO

-- Users can query directory
SELECT * FROM EmployeeDirectory;
GO

/*
OUTPUT:
EmployeeID  FirstName  LastName  Email                   Phone      Department    Title
----------  ---------  --------  ----------------------  ---------  ------------  ----------------
1           John       Doe       john.doe@company.com    555-0101   Engineering   Senior Engineer
2           Jane       Smith     jane.smith@company.com  555-0102   Sales         Sales Manager
3           Bob        Johnson   bob.johnson@company.com 555-0103   Engineering   Junior Engineer
4           Alice      Williams  alice.williams@co...    555-0104   Sales         Sales Rep

Sensitive data hidden!
*/

-- HR VIEW: Include salary for HR department
CREATE VIEW EmployeeHRView AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Department,
    Title,
    Salary,  -- HR needs this
    HireDate,
    ManagerID
    -- SSN, BankAccount still hidden
FROM Employee;
GO

-- PAYROLL VIEW: Include bank account for payroll
CREATE VIEW EmployeePayrollView AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Salary,
    BankAccount  -- Payroll needs this
FROM Employee;
GO

/*
================================================================================
PART 2: ROW-LEVEL SECURITY
================================================================================

Filter rows based on user context or data attributes.
*/

-- Example 1: Show only active employees
CREATE VIEW ActiveEmployees AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Department,
    Title
FROM Employee
WHERE ManagerID IS NOT NULL  -- Exclude top executives
    OR EmployeeID NOT IN (1, 2);  -- Example filter
GO

-- Example 2: Department-specific views
CREATE VIEW EngineeringEmployees AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Title
FROM Employee
WHERE Department = 'Engineering';
GO

CREATE VIEW SalesEmployees AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Title
FROM Employee
WHERE Department = 'Sales';
GO

-- Example 3: Manager sees only their team
CREATE VIEW MyTeamMembers AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Department,
    Title,
    HireDate
FROM Employee
WHERE ManagerID = CONVERT(INT, SESSION_CONTEXT(N'CurrentManagerID'));
GO

/*
To use this view, set context first:
EXEC sp_set_session_context @key = N'CurrentManagerID', @value = 1;
SELECT * FROM MyTeamMembers;
*/

-- Example 4: Hierarchical security (see up to 2 levels down)
CREATE VIEW MyTeamHierarchy AS
SELECT 
    e.EmployeeID,
    e.FirstName,
    e.LastName,
    e.Department,
    e.Title,
    e.ManagerID
FROM Employee e
WHERE e.ManagerID = CONVERT(INT, SESSION_CONTEXT(N'CurrentManagerID'))
   OR e.EmployeeID IN (
       SELECT e2.EmployeeID 
       FROM Employee e2
       WHERE e2.ManagerID IN (
           SELECT e3.EmployeeID 
           FROM Employee e3 
           WHERE e3.ManagerID = CONVERT(INT, SESSION_CONTEXT(N'CurrentManagerID'))
       )
   );
GO

/*
================================================================================
PART 3: MULTI-TENANT DATA ISOLATION
================================================================================

In SaaS applications, each tenant should see only their data.
*/

-- Create multi-tenant tables
DROP TABLE IF EXISTS TenantCustomer;
GO

CREATE TABLE TenantCustomer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    TenantID INT NOT NULL,  -- Identifies which tenant owns this customer
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100),
    Phone VARCHAR(20),
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE)
);
GO

-- Insert sample data for multiple tenants
INSERT INTO TenantCustomer (TenantID, CustomerName, Email, Phone)
VALUES 
    (1, 'Acme Corp Customer 1', 'customer1@acme.com', '555-1001'),
    (1, 'Acme Corp Customer 2', 'customer2@acme.com', '555-1002'),
    (2, 'GlobalTech Customer 1', 'customer1@global.com', '555-2001'),
    (2, 'GlobalTech Customer 2', 'customer2@global.com', '555-2002'),
    (3, 'StartupXYZ Customer 1', 'customer1@startup.com', '555-3001');
GO

-- Tenant-specific view (current tenant only)
CREATE VIEW MyCustomers AS
SELECT 
    CustomerID,
    CustomerName,
    Email,
    Phone,
    CreatedDate
FROM TenantCustomer
WHERE TenantID = CONVERT(INT, SESSION_CONTEXT(N'TenantID'));
GO

-- Application sets tenant context at login
EXEC sp_set_session_context @key = N'TenantID', @value = 1;
GO

-- Query sees only Tenant 1 data
SELECT * FROM MyCustomers;
GO

/*
OUTPUT:
CustomerID  CustomerName           Email                  Phone      CreatedDate
----------  ---------------------  ---------------------  ---------  -----------
1           Acme Corp Customer 1   customer1@acme.com     555-1001   2024-01-15
2           Acme Corp Customer 2   customer2@acme.com     555-1002   2024-01-15

Only Tenant 1's customers visible!
*/

-- Switch to Tenant 2
EXEC sp_set_session_context @key = N'TenantID', @value = 2;
GO

SELECT * FROM MyCustomers;
GO

/*
OUTPUT:
CustomerID  CustomerName             Email                    Phone      CreatedDate
----------  -----------------------  -----------------------  ---------  -----------
3           GlobalTech Customer 1    customer1@global.com     555-2001   2024-01-15
4           GlobalTech Customer 2    customer2@global.com     555-2002   2024-01-15

Now sees Tenant 2's data!
*/

/*
================================================================================
PART 4: MASKING SENSITIVE DATA
================================================================================

Show partial data instead of complete hiding.
*/

-- Create view with masked data
CREATE VIEW EmployeePartialInfo AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email,
    Department,
    -- Mask SSN (show last 4 digits)
    'XXX-XX-' + RIGHT(SSN, 4) AS MaskedSSN,
    -- Mask salary (show range)
    CASE 
        WHEN Salary < 50000 THEN '<$50K'
        WHEN Salary < 75000 THEN '$50K-$75K'
        WHEN Salary < 100000 THEN '$75K-$100K'
        ELSE '>$100K'
    END AS SalaryRange,
    -- Mask bank account (show last 4 digits)
    '******' + RIGHT(BankAccount, 4) AS MaskedBankAccount
FROM Employee;
GO

SELECT * FROM EmployeePartialInfo;
GO

/*
OUTPUT:
EmployeeID  FirstName  LastName  Department   MaskedSSN      SalaryRange    MaskedBankAccount
----------  ---------  --------  -----------  -------------  -------------  -----------------
1           John       Doe       Engineering  XXX-XX-6789    $75K-$100K     ******7890
2           Jane       Smith     Sales        XXX-XX-7890    $75K-$100K     ******8901
3           Bob        Johnson   Engineering  XXX-XX-8901    $50K-$75K      ******9012
4           Alice      Williams  Sales        XXX-XX-9012    $50K-$75K      ******0123

Partial information visible for legitimate business needs!
*/

/*
================================================================================
PART 5: SECURITY BEST PRACTICES
================================================================================
*/

-- Practice 1: Use WITH CHECK OPTION
CREATE VIEW HighSalaryEmployees AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Department,
    Salary
FROM Employee
WHERE Salary > 70000
WITH CHECK OPTION;  -- Prevents updates that violate WHERE clause
GO

-- This works
UPDATE HighSalaryEmployees
SET Salary = 95000
WHERE EmployeeID = 1;
GO

-- This fails (would move employee out of view)
BEGIN TRY
    UPDATE HighSalaryEmployees
    SET Salary = 50000  -- Below 70000
    WHERE EmployeeID = 1;
END TRY
BEGIN CATCH
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'WITH CHECK OPTION prevents updating Salary below 70000!';
END CATCH;
GO

-- Practice 2: Schema binding for security views
CREATE VIEW SecureEmployeeView
WITH SCHEMABINDING AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Email
FROM dbo.Employee;  -- Must use schema prefix
GO

/*
Now cannot drop or alter Employee table without dropping view first.
Ensures security layer cannot be bypassed.
*/

/*
================================================================================
PART 6: VIEW PERMISSIONS
================================================================================

Grant permissions on views, not base tables.
*/

-- Create limited user
-- (Example - actual implementation requires server-level permissions)
/*
CREATE USER LimitedUser WITHOUT LOGIN;

-- Deny access to base table
DENY SELECT ON Employee TO LimitedUser;

-- Grant access to view only
GRANT SELECT ON EmployeeDirectory TO LimitedUser;

-- User can query view but not table
EXECUTE AS USER = 'LimitedUser';
SELECT * FROM EmployeeDirectory;  -- Works
SELECT * FROM Employee;  -- Fails (permission denied)
REVERT;
*/

PRINT 'View permissions control access - users see only what view exposes';
GO

/*
================================================================================
PART 7: AUDIT AND COMPLIANCE
================================================================================

Views help with compliance (GDPR, HIPAA, SOX) by controlling data access.
*/

-- Create audit-friendly view
CREATE VIEW EmployeeAuditView AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Department,
    HireDate,
    SUSER_SNAME() AS AccessedBy,  -- Who queried the view
    GETDATE() AS AccessedAt  -- When
FROM Employee;
GO

SELECT * FROM EmployeeAuditView;
GO

/*
OUTPUT:
EmployeeID  FirstName  LastName  Department   HireDate    AccessedBy  AccessedAt
----------  ---------  --------  -----------  ----------  ----------  -------------------
1           John       Doe       Engineering  2020-01-15  dbo         2024-01-15 14:30:00
...

Every query logs who accessed and when!
*/

-- Compliance view (GDPR - right to be forgotten)
CREATE VIEW GDPRCompliantEmployees AS
SELECT 
    EmployeeID,
    CASE 
        WHEN Employee.DeletedDate IS NOT NULL THEN 'REDACTED'
        ELSE FirstName
    END AS FirstName,
    CASE 
        WHEN Employee.DeletedDate IS NOT NULL THEN 'REDACTED'
        ELSE LastName
    END AS LastName,
    CASE 
        WHEN Employee.DeletedDate IS NOT NULL THEN 'REDACTED'
        ELSE Email
    END AS Email
FROM (
    SELECT 
        EmployeeID,
        FirstName,
        LastName,
        Email,
        NULL AS DeletedDate  -- Placeholder for deleted flag
    FROM Employee
) AS Employee;
GO

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Healthcare Privacy (HIPAA)
---------------------------------------
Create a Patient table with sensitive health information.
Create views for:
1. Receptionist (name, contact only)
2. Doctor (full medical info)
3. Billing (name, insurance info)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Financial Data (SOX Compliance)
--------------------------------------------
Create Transaction table with financial data.
Create views for:
1. Teller (current day transactions only)
2. Auditor (all transactions, read-only)
3. Customer (own transactions only, masked account numbers)

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Multi-Tenant SaaS
------------------------------
Create an Order table for multi-tenant system.
Implement tenant isolation with views and session context.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Healthcare Privacy
DROP TABLE IF EXISTS Patient;
GO

CREATE TABLE Patient (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    DOB DATE,
    Phone VARCHAR(20),
    Email NVARCHAR(100),
    SSN VARCHAR(11),  -- Sensitive
    MedicalHistory NVARCHAR(MAX),  -- Sensitive
    Medications NVARCHAR(MAX),  -- Sensitive
    InsuranceProvider NVARCHAR(100),
    InsurancePolicyNumber VARCHAR(50)
);
GO

-- Receptionist view (scheduling only)
CREATE VIEW ReceptionistPatientView AS
SELECT 
    PatientID,
    FirstName,
    LastName,
    Phone,
    Email
FROM Patient;
GO

-- Doctor view (full medical access)
CREATE VIEW DoctorPatientView AS
SELECT 
    PatientID,
    FirstName,
    LastName,
    DOB,
    Phone,
    MedicalHistory,
    Medications
FROM Patient;
GO

-- Billing view (insurance info)
CREATE VIEW BillingPatientView AS
SELECT 
    PatientID,
    FirstName,
    LastName,
    InsuranceProvider,
    InsurancePolicyNumber
FROM Patient;
GO

-- Solution 2: Financial Data
DROP TABLE IF EXISTS BankTransaction;
GO

CREATE TABLE BankTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountNumber VARCHAR(20),
    CustomerID INT,
    TransactionDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10,2),
    TransactionType VARCHAR(20),
    ProcessedBy NVARCHAR(50)
);
GO

-- Teller view (today only)
CREATE VIEW TellerTransactionView AS
SELECT 
    TransactionID,
    '****' + RIGHT(AccountNumber, 4) AS MaskedAccountNumber,
    TransactionDate,
    Amount,
    TransactionType
FROM BankTransaction
WHERE CAST(TransactionDate AS DATE) = CAST(GETDATE() AS DATE);
GO

-- Auditor view (everything)
CREATE VIEW AuditorTransactionView AS
SELECT 
    TransactionID,
    AccountNumber,
    CustomerID,
    TransactionDate,
    Amount,
    TransactionType,
    ProcessedBy
FROM BankTransaction;
GO

-- Customer view (own transactions, masked)
CREATE VIEW CustomerTransactionView AS
SELECT 
    TransactionID,
    '****' + RIGHT(AccountNumber, 4) AS MaskedAccountNumber,
    TransactionDate,
    Amount,
    TransactionType
FROM BankTransaction
WHERE CustomerID = CONVERT(INT, SESSION_CONTEXT(N'CustomerID'));
GO

-- Solution 3: Multi-Tenant SaaS
DROP TABLE IF EXISTS TenantOrder;
GO

CREATE TABLE TenantOrder (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    TenantID INT NOT NULL,
    OrderDate DATE DEFAULT CAST(GETDATE() AS DATE),
    CustomerName NVARCHAR(100),
    TotalAmount DECIMAL(10,2),
    Status VARCHAR(20)
);
GO

CREATE VIEW CurrentTenantOrders AS
SELECT 
    OrderID,
    OrderDate,
    CustomerName,
    TotalAmount,
    Status
FROM TenantOrder
WHERE TenantID = CONVERT(INT, SESSION_CONTEXT(N'TenantID'));
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. COLUMN-LEVEL SECURITY
   - Hide sensitive columns in views
   - Different views for different roles
   - Mask data instead of completely hiding

2. ROW-LEVEL SECURITY
   - Filter rows with WHERE clause
   - User-specific views with SESSION_CONTEXT
   - Hierarchical security with self-joins

3. MULTI-TENANT ISOLATION
   - Use TenantID in WHERE clause
   - Set tenant context at login
   - Ensure complete isolation

4. DATA MASKING
   - Show partial information
   - Salary ranges instead of exact values
   - Last 4 digits of sensitive numbers

5. SECURITY BEST PRACTICES
   - WITH CHECK OPTION for updatable views
   - SCHEMABINDING to lock schema
   - Grant permissions on views, not tables
   - Audit access with SUSER_SNAME()

6. COMPLIANCE
   - GDPR: Right to be forgotten
   - HIPAA: Patient privacy
   - SOX: Financial data controls
   - PCI DSS: Credit card masking

7. PERMISSION MODEL
   - Deny access to base tables
   - Grant access to views only
   - Role-based view access
   - Audit view usage

8. IMPLEMENTATION TIPS
   - Test security thoroughly
   - Document security requirements
   - Regular security audits
   - Monitor view usage

================================================================================

NEXT STEPS:
-----------
In Lesson 14.4, we'll explore DATA AGGREGATION:
- Pre-aggregated summary views
- Performance considerations
- Indexed views in SQL Server
- Materialized view concepts

Continue to: 04-data-aggregation/lesson.sql

================================================================================
*/
