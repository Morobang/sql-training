-- ========================================
-- Security Best Practices for Dynamic SQL
-- ========================================

USE TechStore;
GO

-- =============================================
-- 🚨 DANGER: SQL Injection Examples
-- =============================================

-- ❌ VULNERABLE CODE - DO NOT USE
CREATE OR ALTER PROCEDURE VulnerableSearch
    @SearchTerm NVARCHAR(100)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    -- DANGER: User input directly concatenated
    SET @SQL = 'SELECT * FROM Products WHERE ProductName = ''' + @SearchTerm + '''';
    
    EXEC(@SQL);
END;
GO

-- Malicious input examples:
-- EXEC VulnerableSearch @SearchTerm = '''; DROP TABLE Products; --'
-- EXEC VulnerableSearch @SearchTerm = ''' OR 1=1; --'
-- Result: Could delete data or expose all records!

DROP PROCEDURE IF EXISTS VulnerableSearch;

-- =============================================
-- ✅ SAFE: Parameterized Query
-- =============================================

CREATE OR ALTER PROCEDURE SecureSearch
    @SearchTerm NVARCHAR(100)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    -- SAFE: Parameter placeholder
    SET @SQL = 'SELECT ProductID, ProductName, Price FROM Products WHERE ProductName = @Search';
    
    -- sp_executesql treats input as data, not code
    EXEC sp_executesql 
        @SQL,
        N'@Search NVARCHAR(100)',
        @Search = @SearchTerm;
END;
GO

-- Now safe from injection:
EXEC SecureSearch @SearchTerm = '''; DROP TABLE Products; --';
-- This will just search for the literal string, not execute DROP

DROP PROCEDURE IF EXISTS SecureSearch;

-- =============================================
-- ✅ Input Validation
-- =============================================

CREATE OR ALTER PROCEDURE ValidatedProductSearch
    @Category NVARCHAR(50),
    @SortColumn NVARCHAR(50) = 'ProductName',  -- User-controlled ORDER BY
    @SortOrder NVARCHAR(4) = 'ASC'
AS
BEGIN
    -- Validate inputs before using in dynamic SQL
    IF @SortOrder NOT IN ('ASC', 'DESC')
    BEGIN
        RAISERROR('Invalid sort order. Use ASC or DESC.', 16, 1);
        RETURN;
    END;
    
    -- Whitelist allowed columns for sorting
    IF @SortColumn NOT IN ('ProductName', 'Price', 'Category', 'StockQuantity')
    BEGIN
        RAISERROR('Invalid sort column. Allowed: ProductName, Price, Category, StockQuantity', 16, 1);
        RETURN;
    END;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Safe to use validated inputs in ORDER BY
    SET @SQL = '
        SELECT 
            ProductID,
            ProductName,
            Category,
            Price,
            StockQuantity
        FROM Products
        WHERE Category = @Cat
        ORDER BY ' + QUOTENAME(@SortColumn) + ' ' + @SortOrder;
    
    EXEC sp_executesql 
        @SQL,
        N'@Cat NVARCHAR(50)',
        @Cat = @Category;
END;
GO

-- Safe usage
EXEC ValidatedProductSearch @Category = 'Electronics', @SortColumn = 'Price', @SortOrder = 'DESC';

-- Blocked attacks
-- EXEC ValidatedProductSearch @Category = 'Electronics', @SortColumn = 'Price; DROP TABLE Products; --';
-- Result: Error - Invalid sort column

DROP PROCEDURE IF EXISTS ValidatedProductSearch;

-- =============================================
-- ✅ Using QUOTENAME for Identifiers
-- =============================================

CREATE OR ALTER PROCEDURE SecureDynamicTable
    @TableName NVARCHAR(128)
AS
BEGIN
    -- Validate table exists in current database
    IF NOT EXISTS (
        SELECT 1 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_NAME = @TableName 
            AND TABLE_SCHEMA = 'dbo'
    )
    BEGIN
        RAISERROR('Table does not exist or access denied.', 16, 1);
        RETURN;
    END;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    -- QUOTENAME prevents SQL injection in identifiers
    SET @SQL = 'SELECT TOP 10 * FROM ' + QUOTENAME(@TableName);
    
    EXEC(@SQL);
END;
GO

-- Safe usage
EXEC SecureDynamicTable @TableName = 'Products';

-- Blocked injection
-- EXEC SecureDynamicTable @TableName = 'Products; DROP TABLE Sales; --';
-- Result: Error - Table does not exist

DROP PROCEDURE IF EXISTS SecureDynamicTable;

-- =============================================
-- ✅ Least Privilege Principle
-- =============================================

-- Create limited user for application
-- CREATE USER AppUser WITHOUT LOGIN;
-- GRANT SELECT ON Products TO AppUser;
-- GRANT SELECT ON Sales TO AppUser;
-- DENY DELETE, UPDATE, INSERT ON Products TO AppUser;

-- Even if SQL injection occurs, damage is limited

-- =============================================
-- ✅ Logging and Monitoring
-- =============================================

CREATE TABLE DynamicSQLLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ExecutedSQL NVARCHAR(MAX),
    ExecutedBy NVARCHAR(128),
    ExecutedAt DATETIME DEFAULT GETDATE(),
    Parameters NVARCHAR(MAX)
);
GO

CREATE OR ALTER PROCEDURE MonitoredDynamicQuery
    @Category NVARCHAR(50)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @User NVARCHAR(128) = SUSER_NAME();
    
    SET @SQL = 'SELECT * FROM Products WHERE Category = @Cat';
    
    -- Log before execution
    INSERT INTO DynamicSQLLog (ExecutedSQL, ExecutedBy, Parameters)
    VALUES (@SQL, @User, '@Cat=' + @Category);
    
    -- Execute safely
    EXEC sp_executesql 
        @SQL,
        N'@Cat NVARCHAR(50)',
        @Cat = @Category;
END;
GO

EXEC MonitoredDynamicQuery @Category = 'Electronics';

-- Review logs
SELECT * FROM DynamicSQLLog ORDER BY ExecutedAt DESC;

DROP PROCEDURE IF EXISTS MonitoredDynamicQuery;
DROP TABLE IF EXISTS DynamicSQLLog;

-- =============================================
-- 🔐 SECURITY CHECKLIST
-- =============================================

/*
✅ Always use sp_executesql with parameters for user input
✅ Validate and whitelist all dynamic values (ORDER BY, table names)
✅ Use QUOTENAME() for dynamic identifiers
✅ Check table/column existence before building queries
✅ Apply least privilege (limited database permissions)
✅ Log dynamic SQL execution for auditing
✅ Never concatenate user input directly into SQL strings
✅ Sanitize inputs (trim, check length, remove special chars)
✅ Use TRY...CATCH for error handling
✅ Review execution plans for performance issues

❌ Don't trust any user input
❌ Don't use EXEC() with concatenated strings
❌ Don't expose error details to end users (info leakage)
❌ Don't allow dynamic queries on system tables
❌ Don't bypass validation for "trusted" users
*/

-- 💡 Golden Rule:
-- Treat ALL user input as malicious until proven otherwise
