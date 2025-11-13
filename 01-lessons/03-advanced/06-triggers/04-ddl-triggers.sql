-- ========================================
-- DDL Triggers (Schema-Level Triggers)
-- ========================================

USE TechStore;
GO

-- Drop existing triggers
DROP TRIGGER IF EXISTS trg_PreventTableDrop ON DATABASE;
DROP TRIGGER IF EXISTS trg_AuditDDLChanges ON DATABASE;
DROP TRIGGER IF EXISTS trg_BlockSchemaChanges ON DATABASE;
GO

-- Create DDL audit table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DDLAuditLog')
BEGIN
    CREATE TABLE DDLAuditLog (
        AuditID INT IDENTITY(1,1) PRIMARY KEY,
        EventType VARCHAR(100),
        ObjectName VARCHAR(200),
        ObjectType VARCHAR(50),
        SQLCommand NVARCHAR(MAX),
        LoginName VARCHAR(100),
        EventDate DATETIME
    );
END;
GO

-- =============================================
-- Example 1: Prevent Table Drops
-- =============================================

CREATE TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @TableName VARCHAR(200);
    
    -- Extract table name from event data
    SET @TableName = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(200)');
    
    -- Prevent dropping critical tables
    IF @TableName IN ('Products', 'Customers', 'Sales', 'Employees', 'Departments')
    BEGIN
        PRINT 'Cannot drop critical table: ' + @TableName;
        ROLLBACK;
    END
    ELSE
    BEGIN
        PRINT 'Table drop allowed: ' + @TableName;
    END;
END;
GO

-- Test table drop prevention
-- Try to drop critical table (should be prevented)
BEGIN TRY
    DROP TABLE Products;
END TRY
BEGIN CATCH
    PRINT 'Drop prevented: ' + ERROR_MESSAGE();
END CATCH;

-- Create and drop test table (should be allowed)
CREATE TABLE TestTable (ID INT);
DROP TABLE TestTable;
PRINT 'Test table dropped successfully';
GO

-- =============================================
-- Example 2: Audit All DDL Changes
-- =============================================

CREATE TRIGGER trg_AuditDDLChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, 
    CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE,
    CREATE_FUNCTION, ALTER_FUNCTION, DROP_FUNCTION,
    CREATE_VIEW, ALTER_VIEW, DROP_VIEW,
    CREATE_TRIGGER, ALTER_TRIGGER, DROP_TRIGGER
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO DDLAuditLog (EventType, ObjectName, ObjectType, SQLCommand, LoginName, EventDate)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(200)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'VARCHAR(50)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'VARCHAR(100)'),
        GETDATE()
    );
END;
GO

-- Test DDL auditing
CREATE TABLE TestAuditTable (ID INT, Name VARCHAR(50));
ALTER TABLE TestAuditTable ADD Description VARCHAR(200);
DROP TABLE TestAuditTable;

-- View audit log
SELECT 
    EventType,
    ObjectName,
    ObjectType,
    LoginName,
    EventDate
FROM DDLAuditLog
ORDER BY EventDate DESC;
GO

-- =============================================
-- Example 3: Block Schema Changes During Hours
-- =============================================

DROP TRIGGER IF EXISTS trg_BlockSchemaChanges ON DATABASE;
GO

CREATE TRIGGER trg_BlockSchemaChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentHour INT = DATEPART(HOUR, GETDATE());
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @EventType VARCHAR(100) = @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)');
    
    -- Block schema changes during business hours (9 AM - 5 PM)
    IF @CurrentHour BETWEEN 9 AND 17
    BEGIN
        DECLARE @Message VARCHAR(200) = 'Schema changes not allowed during business hours (9 AM - 5 PM). Current time: ' + 
                                         CONVERT(VARCHAR(20), GETDATE(), 120);
        PRINT @Message;
        ROLLBACK;
    END
    ELSE
    BEGIN
        PRINT @EventType + ' allowed outside business hours';
    END;
END;
GO

-- Test business hours restriction
-- This will succeed or fail depending on current time
BEGIN TRY
    CREATE TABLE BusinessHoursTest (ID INT);
    PRINT 'Table created (outside business hours)';
    DROP TABLE BusinessHoursTest;
END TRY
BEGIN CATCH
    PRINT 'Blocked: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Disable business hours restriction for examples
DISABLE TRIGGER trg_BlockSchemaChanges ON DATABASE;
GO

-- =============================================
-- Example 4: Prevent Unauthorized Users
-- =============================================

DROP TRIGGER IF EXISTS trg_AuthorizeSchemaChanges ON DATABASE;
GO

CREATE TRIGGER trg_AuthorizeSchemaChanges
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LoginName VARCHAR(100) = ORIGINAL_LOGIN();
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @EventType VARCHAR(100) = @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)');
    
    -- Allow only specific users to make schema changes
    -- (In production, use database roles instead)
    IF @LoginName NOT IN ('sa', 'dbo', SUSER_SNAME())  -- Add authorized users here
    BEGIN
        DECLARE @Message VARCHAR(200) = 'User ' + @LoginName + ' is not authorized to perform ' + @EventType;
        PRINT @Message;
        ROLLBACK;
    END;
END;
GO

-- Disable for testing
DISABLE TRIGGER trg_AuthorizeSchemaChanges ON DATABASE;
GO

-- =============================================
-- Example 5: Naming Convention Enforcement
-- =============================================

DROP TRIGGER IF EXISTS trg_EnforceNamingConvention ON DATABASE;
GO

CREATE TRIGGER trg_EnforceNamingConvention
ON DATABASE
FOR CREATE_PROCEDURE, CREATE_FUNCTION, CREATE_VIEW
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName VARCHAR(200) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(200)');
    DECLARE @ObjectType VARCHAR(50) = @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'VARCHAR(50)');
    
    DECLARE @Prefix VARCHAR(10);
    
    -- Define required prefixes
    IF @ObjectType = 'PROCEDURE' SET @Prefix = 'usp_';
    IF @ObjectType = 'FUNCTION' SET @Prefix = 'fn_';
    IF @ObjectType = 'VIEW' SET @Prefix = 'vw_';
    
    -- Check naming convention
    IF LEFT(@ObjectName, LEN(@Prefix)) <> @Prefix
    BEGIN
        DECLARE @Message VARCHAR(200) = @ObjectType + ' must start with ' + @Prefix + '. Invalid name: ' + @ObjectName;
        PRINT @Message;
        ROLLBACK;
    END;
END;
GO

-- Test naming convention (should fail)
BEGIN TRY
    EXEC('CREATE PROCEDURE BadProcedureName AS BEGIN SELECT 1; END;');
END TRY
BEGIN CATCH
    PRINT 'Naming convention violation: ' + ERROR_MESSAGE();
END CATCH;

-- Test naming convention (should succeed)
EXEC('CREATE PROCEDURE usp_GoodProcedureName AS BEGIN SELECT 1; END;');
GO

DROP PROCEDURE usp_GoodProcedureName;
GO

DISABLE TRIGGER trg_EnforceNamingConvention ON DATABASE;
GO

-- =============================================
-- Example 6: Database-Level Event Monitoring
-- =============================================

DROP TRIGGER IF EXISTS trg_MonitorAllDDL ON DATABASE;
GO

CREATE TRIGGER trg_MonitorAllDDL
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    -- Log all database-level events
    INSERT INTO DDLAuditLog (EventType, ObjectName, ObjectType, SQLCommand, LoginName, EventDate)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(200)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'VARCHAR(50)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'VARCHAR(100)'),
        GETDATE()
    );
    
    -- Send alert for specific events (in production, use email/logging)
    DECLARE @EventType VARCHAR(100) = @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)');
    
    IF @EventType LIKE 'DROP_%'
    BEGIN
        PRINT 'ALERT: Drop operation detected - ' + @EventType;
    END;
END;
GO

-- Test monitoring
CREATE TABLE MonitoringTest (ID INT);
ALTER TABLE MonitoringTest ADD Name VARCHAR(50);
DROP TABLE MonitoringTest;

-- View monitored events
SELECT TOP 5
    EventType,
    ObjectName,
    LoginName,
    EventDate
FROM DDLAuditLog
ORDER BY EventDate DESC;
GO

-- =============================================
-- Managing DDL Triggers
-- =============================================

-- List all DDL triggers in database
SELECT 
    name AS TriggerName,
    is_disabled AS IsDisabled,
    create_date AS CreateDate,
    modify_date AS ModifyDate
FROM sys.triggers
WHERE parent_class_desc = 'DATABASE'
ORDER BY name;
GO

-- Enable/Disable specific trigger
-- ENABLE TRIGGER trg_PreventTableDrop ON DATABASE;
-- DISABLE TRIGGER trg_PreventTableDrop ON DATABASE;

-- Enable/Disable all DDL triggers
-- ENABLE TRIGGER ALL ON DATABASE;
-- DISABLE TRIGGER ALL ON DATABASE;

-- View trigger definition
-- sp_helptext 'trg_AuditDDLChanges';

-- =============================================
-- Server-Level DDL Trigger Example
-- =============================================

-- Note: Requires ALTER ANY DATABASE permission
-- Creates trigger at server level (all databases)

/*
CREATE TRIGGER trg_ServerLevelAudit
ON ALL SERVER
FOR CREATE_DATABASE, ALTER_DATABASE, DROP_DATABASE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    -- Log to master database or dedicated audit database
    -- INSERT INTO AuditDB.dbo.ServerDDLLog (...)
    
    PRINT 'Server-level event: ' + @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)');
END;
GO
*/

-- Manage server-level triggers
-- DROP TRIGGER trg_ServerLevelAudit ON ALL SERVER;
-- ENABLE TRIGGER trg_ServerLevelAudit ON ALL SERVER;
-- DISABLE TRIGGER trg_ServerLevelAudit ON ALL SERVER;

-- =============================================
-- EVENTDATA() XML Structure Reference
-- =============================================

/*
<EVENT_INSTANCE>
    <EventType>CREATE_TABLE</EventType>
    <PostTime>2024-01-15T10:30:00</PostTime>
    <SPID>52</SPID>
    <ServerName>SERVER01</ServerName>
    <LoginName>DOMAIN\User</LoginName>
    <UserName>dbo</UserName>
    <DatabaseName>TechStore</DatabaseName>
    <SchemaName>dbo</SchemaName>
    <ObjectName>TestTable</ObjectName>
    <ObjectType>TABLE</ObjectType>
    <TSQLCommand>
        <SetOptions ... />
        <CommandText>CREATE TABLE TestTable ...</CommandText>
    </TSQLCommand>
</EVENT_INSTANCE>
*/

-- Extract values from EVENTDATA()
/*
DECLARE @EventData XML = EVENTDATA();

SELECT 
    @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)') AS EventType,
    @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(200)') AS ObjectName,
    @EventData.value('(/EVENT_INSTANCE/ObjectType)[1]', 'VARCHAR(50)') AS ObjectType,
    @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'VARCHAR(100)') AS LoginName,
    @EventData.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'VARCHAR(100)') AS DatabaseName,
    @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)') AS Command;
*/

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DISABLE TRIGGER ALL ON DATABASE;

DROP TRIGGER IF EXISTS trg_PreventTableDrop ON DATABASE;
DROP TRIGGER IF EXISTS trg_AuditDDLChanges ON DATABASE;
DROP TRIGGER IF EXISTS trg_BlockSchemaChanges ON DATABASE;
DROP TRIGGER IF EXISTS trg_AuthorizeSchemaChanges ON DATABASE;
DROP TRIGGER IF EXISTS trg_EnforceNamingConvention ON DATABASE;
DROP TRIGGER IF EXISTS trg_MonitorAllDDL ON DATABASE;

DROP TABLE IF EXISTS DDLAuditLog;
*/

-- 💡 Key Points:
-- - DDL triggers fire on schema changes (CREATE, ALTER, DROP)
-- - Created at DATABASE or SERVER level (not on tables)
-- - Use EVENTDATA() XML to get event details
-- - Common uses: audit logging, prevent unwanted changes, enforce standards
-- - Can ROLLBACK to prevent the DDL operation
-- - FOR vs AFTER: FOR is same as AFTER for DDL triggers
-- - Use DISABLE/ENABLE to temporarily turn off
-- - List with sys.triggers WHERE parent_class_desc = 'DATABASE'
-- - Server-level triggers require higher permissions
-- - Be careful not to block yourself out with restrictive triggers!
-- - Test thoroughly before deploying to production
-- - Keep trigger logic simple and fast
-- - Consider business hours, authorized users, naming conventions
