/*
================================================================================
LESSON 17.4: PARTITIONING METHODS
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Implement range partitioning for time-series data
2. Use list partitioning for categorical data
3. Apply hash partitioning for load distribution
4. Create composite partitioning strategies
5. Choose the right partitioning method for your scenario

Business Context:
-----------------
Different business scenarios require different partitioning approaches. This
lesson explores each method in detail with real-world examples to help you
choose and implement the right strategy.

Database: PartitioningDemo
Complexity: Advanced
Estimated Time: 50 minutes

================================================================================
*/

USE PartitioningDemo;
GO

/*
================================================================================
PART 1: RANGE PARTITIONING
================================================================================

RANGE PARTITIONING: Divides data based on ranges of values
- Most common method
- Perfect for time-series data
- Supports sliding windows
- Enables efficient archiving

BEST FOR:
- Historical data (dates, timestamps)
- Sequential IDs
- Data with natural ordering
*/

-- Example 1: Monthly range partitioning for high-volume logs
CREATE PARTITION FUNCTION pfMonthlyLogs (DATETIME2)
AS RANGE RIGHT FOR VALUES (
    '2024-01-01', '2024-02-01', '2024-03-01', '2024-04-01',
    '2024-05-01', '2024-06-01', '2024-07-01', '2024-08-01',
    '2024-09-01', '2024-10-01', '2024-11-01', '2024-12-01',
    '2025-01-01'
);
GO

CREATE PARTITION SCHEME psMonthlyLogs
AS PARTITION pfMonthlyLogs
ALL TO ([PRIMARY]);
GO

CREATE TABLE ApplicationLogs (
    LogID BIGINT IDENTITY(1,1),
    LogTimestamp DATETIME2 NOT NULL,
    LogLevel VARCHAR(20),
    LogMessage VARCHAR(MAX),
    UserID INT,
    SessionID VARCHAR(50),
    CONSTRAINT PK_ApplicationLogs PRIMARY KEY (LogID, LogTimestamp)
) ON psMonthlyLogs(LogTimestamp);
GO

-- Insert sample data across multiple months
INSERT INTO ApplicationLogs (LogTimestamp, LogLevel, LogMessage, UserID, SessionID) VALUES
    ('2024-01-15 10:30:00', 'INFO', 'User login', 101, 'SES001'),
    ('2024-02-20 14:45:00', 'ERROR', 'Database timeout', 102, 'SES002'),
    ('2024-03-10 09:15:00', 'WARN', 'Slow query detected', 103, 'SES003'),
    ('2024-06-05 16:20:00', 'INFO', 'Report generated', 104, 'SES004'),
    ('2024-09-12 11:30:00', 'ERROR', 'API failure', 105, 'SES005'),
    ('2024-12-25 08:00:00', 'INFO', 'Backup completed', 106, 'SES006');
GO

-- Query with partition elimination
SELECT 
    $PARTITION.pfMonthlyLogs(LogTimestamp) AS Partition,
    COUNT(*) AS LogCount,
    MIN(LogTimestamp) AS EarliestLog,
    MAX(LogTimestamp) AS LatestLog
FROM ApplicationLogs
GROUP BY $PARTITION.pfMonthlyLogs(LogTimestamp)
ORDER BY Partition;
GO

-- Example 2: Yearly range partitioning for orders
CREATE PARTITION FUNCTION pfYearlyOrders (DATE)
AS RANGE RIGHT FOR VALUES (
    '2020-01-01', '2021-01-01', '2022-01-01', 
    '2023-01-01', '2024-01-01', '2025-01-01'
);
GO

CREATE PARTITION SCHEME psYearlyOrders
AS PARTITION pfYearlyOrders
ALL TO ([PRIMARY]);
GO

CREATE TABLE HistoricalOrders (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT,
    TotalAmount DECIMAL(18,2),
    OrderStatus VARCHAR(20),
    CONSTRAINT PK_HistoricalOrders PRIMARY KEY (OrderID, OrderDate)
) ON psYearlyOrders(OrderDate);
GO

-- Range partitioning benefits for time-series queries
-- Query: Last 90 days
SELECT OrderID, OrderDate, TotalAmount
FROM HistoricalOrders
WHERE OrderDate >= DATEADD(DAY, -90, GETDATE());
-- Only scans recent partition(s)

-- Query: Specific year
SELECT 
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS MonthlyRevenue
FROM HistoricalOrders
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01'
GROUP BY MONTH(OrderDate)
ORDER BY OrderMonth;
-- Only scans 2024 partition

/*
Range Partitioning: Pros and Cons
----------------------------------
PROS:
✓ Natural for time-series data
✓ Easy to understand and maintain
✓ Supports sliding windows (archive old, add new)
✓ Excellent partition elimination
✓ Enables efficient archiving

CONS:
✗ Partitions may become unbalanced
✗ Recent partitions often larger (active data)
✗ Requires planning for boundary values
*/

/*
================================================================================
PART 2: LIST PARTITIONING
================================================================================

LIST PARTITIONING: Assigns specific values to partitions
- Explicit value lists
- Perfect for categorical data
- Fixed, known values
- Geographic regions, statuses, types

BEST FOR:
- Geographic distribution (regions, countries)
- Status codes (active, inactive, archived)
- Product categories
- Department codes
*/

-- Example 1: Regional list partitioning
-- Note: SQL Server doesn't have native LIST partitioning like Oracle
-- We simulate it using RANGE with surrogate keys

-- Create region mapping
CREATE TABLE RegionMapping (
    RegionCode VARCHAR(10) PRIMARY KEY,
    RegionID INT UNIQUE,
    RegionName VARCHAR(100)
);

INSERT INTO RegionMapping VALUES
    ('NA-EAST', 1, 'North America East'),
    ('NA-WEST', 2, 'North America West'),
    ('EMEA', 3, 'Europe, Middle East, Africa'),
    ('APAC', 4, 'Asia Pacific'),
    ('LATAM', 5, 'Latin America');
GO

-- Partition function using RegionID
CREATE PARTITION FUNCTION pfRegions (INT)
AS RANGE RIGHT FOR VALUES (2, 3, 4, 5);
GO

/*
Partitions created:
1: RegionID < 2   (NA-EAST)
2: RegionID >= 2 AND RegionID < 3 (NA-WEST)
3: RegionID >= 3 AND RegionID < 4 (EMEA)
4: RegionID >= 4 AND RegionID < 5 (APAC)
5: RegionID >= 5  (LATAM and future regions)
*/

CREATE PARTITION SCHEME psRegions
AS PARTITION pfRegions
ALL TO ([PRIMARY]);
GO

CREATE TABLE CustomersByRegion (
    CustomerID BIGINT IDENTITY(1,1),
    RegionID INT NOT NULL,
    CustomerName VARCHAR(200),
    AccountBalance DECIMAL(18,2),
    AccountStatus VARCHAR(20),
    CONSTRAINT PK_CustomersByRegion PRIMARY KEY (CustomerID, RegionID),
    CONSTRAINT FK_CustomersByRegion_Region FOREIGN KEY (RegionID) 
        REFERENCES RegionMapping(RegionID)
) ON psRegions(RegionID);
GO

-- Insert customers across regions
INSERT INTO CustomersByRegion (RegionID, CustomerName, AccountBalance, AccountStatus) VALUES
    (1, 'Acme Corp', 150000.00, 'Active'),
    (1, 'Tech Solutions', 75000.00, 'Active'),
    (2, 'West Coast Ventures', 200000.00, 'Active'),
    (3, 'European Enterprises', 300000.00, 'Active'),
    (3, 'London Trading', 125000.00, 'Active'),
    (4, 'Asia Innovations', 180000.00, 'Active'),
    (5, 'Latin Traders', 95000.00, 'Active');
GO

-- Query by region with partition elimination
SELECT 
    rm.RegionName,
    COUNT(*) AS CustomerCount,
    SUM(cb.AccountBalance) AS TotalBalance
FROM CustomersByRegion cb
INNER JOIN RegionMapping rm ON cb.RegionID = rm.RegionID
WHERE cb.RegionID = 3  -- EMEA only
GROUP BY rm.RegionName;
-- Only scans EMEA partition

-- View data distribution across partitions
SELECT 
    $PARTITION.pfRegions(RegionID) AS PartitionNum,
    rm.RegionName,
    COUNT(*) AS CustomerCount,
    SUM(AccountBalance) AS TotalBalance
FROM CustomersByRegion cb
INNER JOIN RegionMapping rm ON cb.RegionID = rm.RegionID
GROUP BY $PARTITION.pfRegions(RegionID), rm.RegionName
ORDER BY PartitionNum;
GO

-- Example 2: Status-based "list" partitioning
CREATE PARTITION FUNCTION pfOrderStatus (INT)
AS RANGE RIGHT FOR VALUES (2, 3, 4);
GO

CREATE TABLE StatusMapping (
    StatusCode VARCHAR(20) PRIMARY KEY,
    StatusID INT UNIQUE,
    StatusCategory VARCHAR(50)
);

INSERT INTO StatusMapping VALUES
    ('Active', 1, 'Active'),
    ('Pending', 2, 'Pending'),
    ('Completed', 3, 'Completed'),
    ('Cancelled', 4, 'Cancelled'),
    ('Archived', 5, 'Archived');
GO

CREATE PARTITION SCHEME psOrderStatus
AS PARTITION pfOrderStatus
ALL TO ([PRIMARY]);
GO

CREATE TABLE OrdersByStatus (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    StatusID INT NOT NULL,
    CustomerID INT,
    Amount DECIMAL(18,2),
    CONSTRAINT PK_OrdersByStatus PRIMARY KEY (OrderID, StatusID)
) ON psOrderStatus(StatusID);
GO

/*
List Partitioning: Pros and Cons
---------------------------------
PROS:
✓ Clear data separation by category
✓ Easy to understand partition mapping
✓ Good for multi-tenant applications
✓ Can isolate hot/cold data

CONS:
✗ Requires surrogate key in SQL Server
✗ Fixed number of categories
✗ May have unbalanced partitions
✗ Adding categories requires planning
*/

/*
================================================================================
PART 3: HASH PARTITIONING
================================================================================

HASH PARTITIONING: Distributes data evenly using hash function
- Even distribution
- Load balancing
- No hot partitions
- Good for parallelism

BEST FOR:
- User IDs, Customer IDs
- Random access patterns
- Load balancing across disks
- No natural partitioning key
*/

-- SQL Server doesn't have native hash partitioning
-- We can simulate it using computed column

-- Example 1: Hash partitioning for user data
CREATE TABLE Users (
    UserID BIGINT IDENTITY(1,1),
    UserIDHash AS (UserID % 8) PERSISTED,  -- Hash to 8 partitions
    Username VARCHAR(100),
    Email VARCHAR(200),
    RegistrationDate DATE,
    CONSTRAINT PK_Users PRIMARY KEY (UserID, UserIDHash)
);
GO

-- Create partition function for 8 partitions
CREATE PARTITION FUNCTION pfHash8 (INT)
AS RANGE RIGHT FOR VALUES (1, 2, 3, 4, 5, 6, 7);
GO

CREATE PARTITION SCHEME psHash8
AS PARTITION pfHash8
ALL TO ([PRIMARY]);
GO

-- Re-create table with partitioning
DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users (
    UserID BIGINT IDENTITY(1,1),
    UserIDHash AS (UserID % 8) PERSISTED,
    Username VARCHAR(100),
    Email VARCHAR(200),
    RegistrationDate DATE,
    LastLoginDate DATETIME2,
    CONSTRAINT PK_Users PRIMARY KEY (UserID, UserIDHash)
) ON psHash8(UserIDHash);
GO

-- Insert users (hash distributes automatically)
INSERT INTO Users (Username, Email, RegistrationDate) VALUES
    ('user001', 'user001@example.com', '2024-01-15'),
    ('user002', 'user002@example.com', '2024-01-16'),
    ('user003', 'user003@example.com', '2024-01-17'),
    ('user004', 'user004@example.com', '2024-01-18'),
    ('user005', 'user005@example.com', '2024-01-19'),
    ('user006', 'user006@example.com', '2024-01-20'),
    ('user007', 'user007@example.com', '2024-01-21'),
    ('user008', 'user008@example.com', '2024-01-22'),
    ('user009', 'user009@example.com', '2024-01-23'),
    ('user010', 'user010@example.com', '2024-01-24');
GO

-- View distribution across hash partitions
SELECT 
    $PARTITION.pfHash8(UserIDHash) AS PartitionNum,
    COUNT(*) AS UserCount
FROM Users
GROUP BY $PARTITION.pfHash8(UserIDHash)
ORDER BY PartitionNum;
GO

-- Example 2: Hash partitioning for transactions
CREATE TABLE Transactions (
    TransactionID BIGINT IDENTITY(1,1),
    TransactionHash AS (TransactionID % 16) PERSISTED,
    TransactionDate DATETIME2 NOT NULL,
    UserID BIGINT,
    Amount DECIMAL(18,2),
    TransactionType VARCHAR(50),
    CONSTRAINT PK_Transactions PRIMARY KEY (TransactionID, TransactionHash)
);
GO

-- 16-partition hash function
CREATE PARTITION FUNCTION pfHash16 (INT)
AS RANGE RIGHT FOR VALUES (
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
);
GO

CREATE PARTITION SCHEME psHash16
AS PARTITION pfHash16
ALL TO ([PRIMARY]);
GO

DROP TABLE IF EXISTS Transactions;
GO

CREATE TABLE Transactions (
    TransactionID BIGINT IDENTITY(1,1),
    TransactionHash AS (TransactionID % 16) PERSISTED,
    TransactionDate DATETIME2 NOT NULL,
    UserID BIGINT,
    Amount DECIMAL(18,2),
    TransactionType VARCHAR(50),
    CONSTRAINT PK_Transactions PRIMARY KEY (TransactionID, TransactionHash)
) ON psHash16(TransactionHash);
GO

/*
Hash Partitioning: Pros and Cons
---------------------------------
PROS:
✓ Even data distribution
✓ No hot partitions
✓ Good for parallel operations
✓ Automatic load balancing

CONS:
✗ No partition elimination for range queries
✗ Requires computed column in SQL Server
✗ Point lookups need hash value
✗ Cannot archive specific partitions
*/

/*
================================================================================
PART 4: COMPOSITE PARTITIONING
================================================================================

COMPOSITE PARTITIONING: Combines multiple partitioning methods
- First level: one method (e.g., range by date)
- Second level: another method (e.g., hash by ID)
- Maximum flexibility
- Complex to manage

BEST FOR:
- Very large datasets (billions of rows)
- Complex query patterns
- Need both time-based and distribution benefits
*/

-- Example: Range (by year) + Hash (by customer)
-- Note: SQL Server doesn't support true composite partitioning
-- We simulate with computed column combining both factors

CREATE TABLE CompositeOrders (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    -- Composite key: YearCode (2024 = 2024000) + CustomerHash (0-999)
    CompositeKey AS (
        YEAR(OrderDate) * 1000 + (CustomerID % 1000)
    ) PERSISTED,
    OrderAmount DECIMAL(18,2),
    CONSTRAINT PK_CompositeOrders PRIMARY KEY (OrderID, CompositeKey)
);
GO

-- Partition function for composite key
-- Creates partitions like: 2024000-2024999, 2025000-2025999
CREATE PARTITION FUNCTION pfComposite (INT)
AS RANGE RIGHT FOR VALUES (
    2024000, 2025000, 2026000
);
GO

CREATE PARTITION SCHEME psComposite
AS PARTITION pfComposite
ALL TO ([PRIMARY]);
GO

DROP TABLE IF EXISTS CompositeOrders;
GO

CREATE TABLE CompositeOrders (
    OrderID BIGINT IDENTITY(1,1),
    OrderDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    CompositeKey AS (YEAR(OrderDate) * 1000 + (CustomerID % 1000)) PERSISTED,
    OrderAmount DECIMAL(18,2),
    ProductID INT,
    CONSTRAINT PK_CompositeOrders PRIMARY KEY (OrderID, CompositeKey)
) ON psComposite(CompositeKey);
GO

/*
Benefits of composite partitioning:
1. Time-based archiving (year component)
2. Load distribution within year (hash component)
3. Best of both worlds
*/

/*
================================================================================
PART 5: CHOOSING THE RIGHT METHOD
================================================================================
*/

-- Decision Matrix
/*
┌─────────────────┬──────────────────┬─────────────────────────────────┐
│ SCENARIO        │ METHOD           │ REASON                          │
├─────────────────┼──────────────────┼─────────────────────────────────┤
│ Time-series     │ RANGE (Date)     │ Natural ordering, archiving     │
│ Logs, events    │                  │ Sliding window, partition elim  │
├─────────────────┼──────────────────┼─────────────────────────────────┤
│ Geographic data │ LIST (Region)    │ Clear separation by region      │
│ Multi-tenant    │                  │ Data isolation, compliance      │
├─────────────────┼──────────────────┼─────────────────────────────────┤
│ User profiles   │ HASH (UserID)    │ Even distribution               │
│ Random access   │                  │ Load balancing, parallelism     │
├─────────────────┼──────────────────┼─────────────────────────────────┤
│ Very large DB   │ COMPOSITE        │ Time archiving + distribution   │
│ Billions rows   │ (Date + Hash)    │ Maximum scalability             │
└─────────────────┴──────────────────┴─────────────────────────────────┘
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Implement Quarterly Range Partitioning
---------------------------------------------------
Create a partitioned table for quarterly financial data:
- Partition by quarter (Q1-Q4 for 2024)
- Table: QuarterlyRevenue
- Columns: RevenueID, TransactionDate, DepartmentID, Amount
- Insert data across all quarters
- Write query showing revenue per quarter

TRY IT YOURSELF!
*/

-- Your solution here:






/*
Exercise 2: Multi-Tenant List Partitioning
-------------------------------------------
Simulate list partitioning for multi-tenant SaaS application:
- Partition by TenantID (5 tenants)
- Table: TenantData
- Show data distribution across tenants
- Query single tenant with partition elimination

TRY IT YOURSELF!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Quarterly Range Partitioning
CREATE PARTITION FUNCTION pfQuarterly2024 (DATE)
AS RANGE RIGHT FOR VALUES (
    '2024-01-01', '2024-04-01', '2024-07-01', '2024-10-01'
);
GO

CREATE PARTITION SCHEME psQuarterly2024
AS PARTITION pfQuarterly2024
ALL TO ([PRIMARY]);
GO

CREATE TABLE QuarterlyRevenue (
    RevenueID BIGINT IDENTITY(1,1),
    TransactionDate DATE NOT NULL,
    DepartmentID INT,
    Amount DECIMAL(18,2),
    CONSTRAINT PK_QuarterlyRevenue PRIMARY KEY (RevenueID, TransactionDate)
) ON psQuarterly2024(TransactionDate);
GO

INSERT INTO QuarterlyRevenue (TransactionDate, DepartmentID, Amount) VALUES
    ('2024-02-15', 101, 50000),  -- Q1
    ('2024-05-20', 102, 75000),  -- Q2
    ('2024-08-10', 101, 60000),  -- Q3
    ('2024-11-05', 103, 80000);  -- Q4
GO

SELECT 
    DATEPART(QUARTER, TransactionDate) AS Quarter,
    SUM(Amount) AS QuarterlyRevenue
FROM QuarterlyRevenue
WHERE TransactionDate >= '2024-01-01' AND TransactionDate < '2025-01-01'
GROUP BY DATEPART(QUARTER, TransactionDate)
ORDER BY Quarter;
GO

-- Solution 2: Multi-Tenant Partitioning
CREATE PARTITION FUNCTION pfTenants (INT)
AS RANGE RIGHT FOR VALUES (2, 3, 4, 5);
GO

CREATE PARTITION SCHEME psTenants
AS PARTITION pfTenants
ALL TO ([PRIMARY]);
GO

CREATE TABLE TenantData (
    DataID BIGINT IDENTITY(1,1),
    TenantID INT NOT NULL,
    DataValue VARCHAR(MAX),
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT PK_TenantData PRIMARY KEY (DataID, TenantID)
) ON psTenants(TenantID);
GO

INSERT INTO TenantData (TenantID, DataValue) VALUES
    (1, 'Tenant 1 Data'), (2, 'Tenant 2 Data'),
    (3, 'Tenant 3 Data'), (4, 'Tenant 4 Data'),
    (5, 'Tenant 5 Data');
GO

-- Distribution
SELECT 
    $PARTITION.pfTenants(TenantID) AS Partition,
    COUNT(*) AS RecordCount
FROM TenantData
GROUP BY $PARTITION.pfTenants(TenantID);
GO

-- Single tenant query
SELECT * FROM TenantData WHERE TenantID = 3;
-- Only scans partition 3
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. RANGE PARTITIONING
   - Best for time-series data
   - Supports sliding windows
   - Excellent for archiving
   - Most common method

2. LIST PARTITIONING
   - Best for categorical data
   - Clear data separation
   - Requires surrogate key in SQL Server
   - Good for multi-tenant

3. HASH PARTITIONING
   - Even data distribution
   - Load balancing
   - Requires computed column
   - No range query benefits

4. COMPOSITE PARTITIONING
   - Combines multiple methods
   - Maximum flexibility
   - Complex to implement
   - For very large datasets

5. CHOOSING METHOD
   - Consider query patterns
   - Evaluate data characteristics
   - Think about maintenance needs
   - Plan for growth

================================================================================

NEXT STEPS:
-----------
Continue to Lesson 17.5: Partitioning Benefits
Learn how to measure and optimize partition performance.

================================================================================
*/
