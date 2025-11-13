-- =============================================
-- Phase 1: Generate Sample Banking Data
-- =============================================
-- Purpose: Create realistic banking data for Data Vault loading
-- Tables: Customers, Accounts, Transactions, Branches
-- =============================================

USE SecureBank_DataVault;
GO

-- Log pipeline start
INSERT INTO metadata.pipeline_runs (layer, script_name, status)
VALUES ('raw', '02-generate-sample-data.sql', 'running');
GO

-- =============================================
-- Helper Functions
-- =============================================

-- Random date generator
CREATE OR ALTER FUNCTION dbo.fn_RandomDate
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS DATE
AS
BEGIN
    DECLARE @DaysDiff INT = DATEDIFF(DAY, @StartDate, @EndDate);
    IF @DaysDiff = 0 SET @DaysDiff = 1;
    
    DECLARE @RandomDays INT = ABS(CHECKSUM(NEWID())) % @DaysDiff;
    RETURN DATEADD(DAY, @RandomDays, @StartDate);
END;
GO

-- Random string generator
CREATE OR ALTER FUNCTION dbo.fn_RandomString
(
    @Length INT
)
RETURNS VARCHAR(100)
AS
BEGIN
    DECLARE @Result VARCHAR(100) = '';
    DECLARE @Chars VARCHAR(52) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    DECLARE @i INT = 0;
    
    WHILE @i < @Length
    BEGIN
        SET @Result = @Result + SUBSTRING(@Chars, ABS(CHECKSUM(NEWID())) % 52 + 1, 1);
        SET @i = @i + 1;
    END;
    
    RETURN @Result;
END;
GO

-- =============================================
-- Create Raw Staging Tables
-- =============================================
PRINT 'Creating raw staging tables...';

-- Raw Branches
IF OBJECT_ID('raw.branches', 'U') IS NOT NULL DROP TABLE raw.branches;
CREATE TABLE raw.branches (
    branch_code NVARCHAR(20) PRIMARY KEY,
    branch_name NVARCHAR(100),
    city NVARCHAR(50),
    state NVARCHAR(2),
    region NVARCHAR(50),
    created_date DATETIME DEFAULT GETDATE()
);

-- Raw Customers
IF OBJECT_ID('raw.customers', 'U') IS NOT NULL DROP TABLE raw.customers;
CREATE TABLE raw.customers (
    customer_id NVARCHAR(50) PRIMARY KEY,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    email NVARCHAR(100),
    phone NVARCHAR(20),
    address NVARCHAR(200),
    city NVARCHAR(50),
    state NVARCHAR(2),
    zip_code NVARCHAR(10),
    date_of_birth DATE,
    ssn_last4 NVARCHAR(4),
    credit_score INT,
    customer_since DATE,
    customer_status NVARCHAR(20),
    created_date DATETIME DEFAULT GETDATE()
);

-- Raw Accounts
IF OBJECT_ID('raw.accounts', 'U') IS NOT NULL DROP TABLE raw.accounts;
CREATE TABLE raw.accounts (
    account_number NVARCHAR(50) PRIMARY KEY,
    customer_id NVARCHAR(50),
    branch_code NVARCHAR(20),
    account_type NVARCHAR(50),
    balance DECIMAL(18,2),
    interest_rate DECIMAL(5,2),
    open_date DATE,
    account_status NVARCHAR(20),
    created_date DATETIME DEFAULT GETDATE()
);

-- Raw Transactions
IF OBJECT_ID('raw.transactions', 'U') IS NOT NULL DROP TABLE raw.transactions;
CREATE TABLE raw.transactions (
    transaction_id NVARCHAR(50) PRIMARY KEY,
    account_number NVARCHAR(50),
    transaction_date DATETIME,
    transaction_type NVARCHAR(50),
    amount DECIMAL(18,2),
    description NVARCHAR(200),
    merchant_name NVARCHAR(100),
    category NVARCHAR(50),
    created_date DATETIME DEFAULT GETDATE()
);

PRINT '✓ Raw staging tables created';
GO

-- =============================================
-- Generate Branch Data (50 branches)
-- =============================================
PRINT 'Generating branch data...';

DECLARE @BranchCount INT = 1;
DECLARE @States TABLE (Code CHAR(2), Name NVARCHAR(50));
INSERT INTO @States VALUES 
    ('CA', 'California'), ('TX', 'Texas'), ('NY', 'New York'), 
    ('FL', 'Florida'), ('IL', 'Illinois'), ('PA', 'Pennsylvania'),
    ('OH', 'Ohio'), ('GA', 'Georgia'), ('NC', 'North Carolina'),
    ('MI', 'Michigan');

DECLARE @Cities TABLE (City NVARCHAR(50), State CHAR(2), Region NVARCHAR(50));
INSERT INTO @Cities VALUES
    ('Los Angeles', 'CA', 'West'), ('San Francisco', 'CA', 'West'),
    ('Houston', 'TX', 'South'), ('Dallas', 'TX', 'South'), ('Austin', 'TX', 'South'),
    ('New York', 'NY', 'Northeast'), ('Buffalo', 'NY', 'Northeast'),
    ('Miami', 'FL', 'South'), ('Orlando', 'FL', 'South'),
    ('Chicago', 'IL', 'Midwest'), ('Philadelphia', 'PA', 'Northeast'),
    ('Cleveland', 'OH', 'Midwest'), ('Atlanta', 'GA', 'South'),
    ('Charlotte', 'NC', 'South'), ('Detroit', 'MI', 'Midwest');

WHILE @BranchCount <= 50
BEGIN
    DECLARE @City NVARCHAR(50), @State CHAR(2), @Region NVARCHAR(50);
    
    SELECT TOP 1 @City = City, @State = State, @Region = Region
    FROM @Cities ORDER BY NEWID();
    
    INSERT INTO raw.branches (branch_code, branch_name, city, state, region)
    VALUES (
        'BR' + RIGHT('0000' + CAST(@BranchCount AS VARCHAR), 4),
        'SecureBank ' + @City + ' Branch',
        @City,
        @State,
        @Region
    );
    
    SET @BranchCount = @BranchCount + 1;
END;

PRINT '✓ Generated ' + CAST((SELECT COUNT(*) FROM raw.branches) AS VARCHAR) + ' branches';
GO

-- =============================================
-- Generate Customer Data (5,000 customers)
-- =============================================
PRINT 'Generating customer data...';

DECLARE @CustomerCount INT = 1;
DECLARE @FirstNames TABLE (Name NVARCHAR(50));
INSERT INTO @FirstNames VALUES 
    ('James'), ('Mary'), ('John'), ('Patricia'), ('Robert'), ('Jennifer'),
    ('Michael'), ('Linda'), ('William'), ('Elizabeth'), ('David'), ('Barbara'),
    ('Richard'), ('Susan'), ('Joseph'), ('Jessica'), ('Thomas'), ('Sarah'),
    ('Charles'), ('Karen'), ('Christopher'), ('Nancy'), ('Daniel'), ('Lisa');

DECLARE @LastNames TABLE (Name NVARCHAR(50));
INSERT INTO @LastNames VALUES
    ('Smith'), ('Johnson'), ('Williams'), ('Brown'), ('Jones'), ('Garcia'),
    ('Miller'), ('Davis'), ('Rodriguez'), ('Martinez'), ('Hernandez'), ('Lopez'),
    ('Gonzalez'), ('Wilson'), ('Anderson'), ('Thomas'), ('Taylor'), ('Moore');

WHILE @CustomerCount <= 5000
BEGIN
    DECLARE @FirstName NVARCHAR(50), @LastName NVARCHAR(50);
    
    SELECT TOP 1 @FirstName = Name FROM @FirstNames ORDER BY NEWID();
    SELECT TOP 1 @LastName = Name FROM @LastNames ORDER BY NEWID();
    
    DECLARE @CustomerID NVARCHAR(50) = 'CUST' + RIGHT('000000' + CAST(@CustomerCount AS VARCHAR), 6);
    DECLARE @Email NVARCHAR(100) = LOWER(@FirstName + '.' + @LastName + CAST(@CustomerCount AS VARCHAR) + '@email.com');
    
    -- Random customer status
    DECLARE @Status NVARCHAR(20) = CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'Inactive'
        WHEN 1 THEN 'Suspended'
        ELSE 'Active'
    END;
    
    INSERT INTO raw.customers (
        customer_id, first_name, last_name, email, phone, address, city, state, zip_code,
        date_of_birth, ssn_last4, credit_score, customer_since, customer_status
    )
    VALUES (
        @CustomerID,
        @FirstName,
        @LastName,
        @Email,
        '555-' + RIGHT('000' + CAST(ABS(CHECKSUM(NEWID())) % 1000 AS VARCHAR), 3) + '-' + 
                 RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4),
        CAST(ABS(CHECKSUM(NEWID())) % 9999 + 1 AS VARCHAR) + ' Main St',
        (SELECT TOP 1 City FROM @Cities ORDER BY NEWID()),
        (SELECT TOP 1 Code FROM @States ORDER BY NEWID()),
        RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR), 5),
        DATEADD(YEAR, -1 * (ABS(CHECKSUM(NEWID())) % 50 + 18), GETDATE()), -- Age 18-68
        RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR), 4),
        ABS(CHECKSUM(NEWID())) % 401 + 300, -- Credit score 300-700
        dbo.fn_RandomDate('2015-01-01', '2024-01-01'),
        @Status
    );
    
    SET @CustomerCount = @CustomerCount + 1;
END;

PRINT '✓ Generated ' + CAST((SELECT COUNT(*) FROM raw.customers) AS VARCHAR) + ' customers';
GO

-- =============================================
-- Generate Account Data (8,000 accounts)
-- =============================================
PRINT 'Generating account data...';

DECLARE @AccountCount INT = 1;

WHILE @AccountCount <= 8000
BEGIN
    DECLARE @AccountNumber NVARCHAR(50) = 'ACC' + RIGHT('00000000' + CAST(@AccountCount AS VARCHAR), 8);
    
    -- Random customer (some customers have multiple accounts)
    DECLARE @CustID NVARCHAR(50) = 'CUST' + RIGHT('000000' + CAST(ABS(CHECKSUM(NEWID())) % 5000 + 1 AS VARCHAR), 6);
    
    -- Random branch
    DECLARE @BranchCode NVARCHAR(20) = 'BR' + RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 50 + 1 AS VARCHAR), 4);
    
    -- Account type
    DECLARE @AcctType NVARCHAR(50) = CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN 'Checking'
        WHEN 1 THEN 'Savings'
        WHEN 2 THEN 'Money Market'
        WHEN 3 THEN 'CD'
        ELSE 'Business Checking'
    END;
    
    -- Account status
    DECLARE @AcctStatus NVARCHAR(20) = CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'Closed'
        WHEN 1 THEN 'Frozen'
        ELSE 'Active'
    END;
    
    -- Balance and interest
    DECLARE @Balance DECIMAL(18,2) = CAST(ABS(CHECKSUM(NEWID())) % 100000 AS DECIMAL(18,2)) + 100;
    DECLARE @InterestRate DECIMAL(5,2) = CAST((ABS(CHECKSUM(NEWID())) % 500) AS DECIMAL(5,2)) / 100; -- 0-5%
    
    INSERT INTO raw.accounts (
        account_number, customer_id, branch_code, account_type, balance, 
        interest_rate, open_date, account_status
    )
    VALUES (
        @AccountNumber,
        @CustID,
        @BranchCode,
        @AcctType,
        @Balance,
        @InterestRate,
        dbo.fn_RandomDate('2015-01-01', '2024-01-01'),
        @AcctStatus
    );
    
    SET @AccountCount = @AccountCount + 1;
END;

PRINT '✓ Generated ' + CAST((SELECT COUNT(*) FROM raw.accounts) AS VARCHAR) + ' accounts';
GO

-- =============================================
-- Generate Transaction Data (50,000 transactions)
-- =============================================
PRINT 'Generating transaction data...';

DECLARE @TransactionCount INT = 1;
DECLARE @Merchants TABLE (Name NVARCHAR(100), Category NVARCHAR(50));
INSERT INTO @Merchants VALUES
    ('Walmart', 'Retail'), ('Amazon', 'Online Shopping'), ('Starbucks', 'Dining'),
    ('Shell Gas', 'Gas'), ('Target', 'Retail'), ('McDonald''s', 'Dining'),
    ('Home Depot', 'Home Improvement'), ('CVS Pharmacy', 'Healthcare'),
    ('Kroger', 'Groceries'), ('Best Buy', 'Electronics');

WHILE @TransactionCount <= 50000
BEGIN
    DECLARE @TransactionID NVARCHAR(50) = 'TXN' + RIGHT('00000000' + CAST(@TransactionCount AS VARCHAR), 10);
    
    -- Random account
    DECLARE @AcctNum NVARCHAR(50) = 'ACC' + RIGHT('00000000' + CAST(ABS(CHECKSUM(NEWID())) % 8000 + 1 AS VARCHAR), 8);
    
    -- Transaction type
    DECLARE @TxnType NVARCHAR(50) = CASE ABS(CHECKSUM(NEWID())) % 6
        WHEN 0 THEN 'Deposit'
        WHEN 1 THEN 'Withdrawal'
        WHEN 2 THEN 'Transfer'
        WHEN 3 THEN 'Purchase'
        WHEN 4 THEN 'Fee'
        ELSE 'Interest'
    END;
    
    -- Amount
    DECLARE @Amount DECIMAL(18,2) = CAST(ABS(CHECKSUM(NEWID())) % 5000 AS DECIMAL(18,2)) + 0.01;
    IF @TxnType IN ('Withdrawal', 'Purchase', 'Fee')
        SET @Amount = @Amount * -1; -- Negative for debits
    
    -- Merchant and category
    DECLARE @Merchant NVARCHAR(100), @Category NVARCHAR(50);
    SELECT TOP 1 @Merchant = Name, @Category = Category FROM @Merchants ORDER BY NEWID();
    
    INSERT INTO raw.transactions (
        transaction_id, account_number, transaction_date, transaction_type,
        amount, description, merchant_name, category
    )
    VALUES (
        @TransactionID,
        @AcctNum,
        DATEADD(MINUTE, ABS(CHECKSUM(NEWID())) % 525600, dbo.fn_RandomDate('2024-01-01', '2024-11-13')), -- Random datetime in 2024
        @TxnType,
        @Amount,
        @TxnType + ' - ' + @Merchant,
        @Merchant,
        @Category
    );
    
    SET @TransactionCount = @TransactionCount + 1;
END;

PRINT '✓ Generated ' + CAST((SELECT COUNT(*) FROM raw.transactions) AS VARCHAR) + ' transactions';
GO

-- =============================================
-- Update Pipeline Status
-- =============================================
DECLARE @total_rows INT = (
    SELECT (SELECT COUNT(*) FROM raw.branches) +
           (SELECT COUNT(*) FROM raw.customers) +
           (SELECT COUNT(*) FROM raw.accounts) +
           (SELECT COUNT(*) FROM raw.transactions)
);

UPDATE metadata.pipeline_runs
SET end_time = GETDATE(),
    status = 'success',
    rows_processed = @total_rows
WHERE layer = 'raw' 
  AND script_name = '02-generate-sample-data.sql'
  AND status = 'running';
GO

-- Cleanup helper functions
DROP FUNCTION IF EXISTS dbo.fn_RandomDate;
DROP FUNCTION IF EXISTS dbo.fn_RandomString;
GO

-- =============================================
-- VERIFICATION
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'Sample Data Generation Complete!';
PRINT '========================================';
PRINT '';

SELECT 'raw.branches' AS table_name, COUNT(*) AS row_count FROM raw.branches
UNION ALL
SELECT 'raw.customers', COUNT(*) FROM raw.customers
UNION ALL
SELECT 'raw.accounts', COUNT(*) FROM raw.accounts
UNION ALL
SELECT 'raw.transactions', COUNT(*) FROM raw.transactions;

PRINT '';
PRINT 'Sample Data Preview:';
PRINT '';
PRINT '--- Branches ---';
SELECT TOP 5 * FROM raw.branches ORDER BY branch_code;

PRINT '';
PRINT '--- Customers ---';
SELECT TOP 5 customer_id, first_name, last_name, email, customer_status FROM raw.customers;

PRINT '';
PRINT '--- Accounts ---';
SELECT TOP 5 account_number, customer_id, account_type, balance, account_status FROM raw.accounts;

PRINT '';
PRINT '--- Transactions ---';
SELECT TOP 5 transaction_id, account_number, transaction_type, amount, merchant_name FROM raw.transactions ORDER BY transaction_date DESC;

PRINT '';
PRINT 'Next: Run 03-load-hubs.sql to load business keys into hub tables';
GO
