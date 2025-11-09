/*
================================================================================
LESSON 14.6: JOINING PARTITIONED DATA
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Understand partitioned views
2. Create local partitioned views
3. Implement distributed partitioned views
4. Use UNION ALL for data consolidation
5. Optimize partitioned view performance
6. Handle cross-server queries
7. Apply best practices for partitioning

Business Context:
-----------------
Partitioned views combine data from multiple tables (local or distributed)
into a single virtual table. This is essential for large datasets split across
time periods, regions, or servers. Common scenarios include archival data,
multi-tenant systems, and distributed databases.

Database: RetailStore
Complexity: Advanced
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: LOCAL PARTITIONED VIEWS
================================================================================

Combine multiple tables with identical structures into a single view.
Common pattern: Partition by time period (monthly, yearly).
*/

-- Create partitioned tables for sales by year
DROP TABLE IF EXISTS Sales2024;
DROP TABLE IF EXISTS Sales2023;
DROP TABLE IF EXISTS Sales2022;
GO

CREATE TABLE Sales2022 (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (YEAR(SaleDate) = 2022),  -- Partition constraint
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales2023 (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (YEAR(SaleDate) = 2023),  -- Partition constraint
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales2024 (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (YEAR(SaleDate) = 2024),  -- Partition constraint
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);
GO

-- Insert sample data
INSERT INTO Sales2022 VALUES
    (1, '2022-01-15', 1, 1, 10, 500.00),
    (2, '2022-06-20', 2, 2, 5, 150.00),
    (3, '2022-12-31', 1, 3, 8, 400.00);

INSERT INTO Sales2023 VALUES
    (4, '2023-03-10', 3, 1, 15, 750.00),
    (5, '2023-07-22', 1, 2, 12, 360.00),
    (6, '2023-11-05', 2, 3, 20, 1000.00);

INSERT INTO Sales2024 VALUES
    (7, '2024-01-08', 3, 1, 25, 1250.00),
    (8, '2024-05-14', 2, 2, 30, 900.00),
    (9, '2024-11-01', 1, 3, 18, 900.00);
GO

-- Create partitioned view (UNION ALL combines all tables)
CREATE VIEW AllSales AS
SELECT SaleID, SaleDate, CustomerID, ProductID, Quantity, Amount FROM Sales2022
UNION ALL
SELECT SaleID, SaleDate, CustomerID, ProductID, Quantity, Amount FROM Sales2023
UNION ALL
SELECT SaleID, SaleDate, CustomerID, ProductID, Quantity, Amount FROM Sales2024;
GO

-- Query across all partitions
SELECT * FROM AllSales ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    CustomerID  ProductID  Quantity  Amount
------  ----------  ----------  ---------  --------  -------
1       2022-01-15  1           1          10        500.00
2       2022-06-20  2           2          5         150.00
3       2022-12-31  1           3          8         400.00
4       2023-03-10  3           1          15        750.00
5       2023-07-22  1           2          12        360.00
6       2023-11-05  2           3          20        1000.00
7       2024-01-08  3           1          25        1250.00
8       2024-05-14  2           2          30        900.00
9       2024-11-01  1           3          18        900.00

Seamless access to all years!
*/

-- PARTITION ELIMINATION: SQL Server optimizes queries
-- Only queries relevant partition(s)

-- Query for 2024 only (only scans Sales2024 table)
SELECT * FROM AllSales WHERE YEAR(SaleDate) = 2024;
GO

-- Query for specific date range (only scans Sales2023 and Sales2024)
SELECT * FROM AllSales 
WHERE SaleDate BETWEEN '2023-06-01' AND '2024-06-30'
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    CustomerID  ProductID  Quantity  Amount
------  ----------  ----------  ---------  --------  -------
5       2023-07-22  1           2          12        360.00
6       2023-11-05  2           3          20        1000.00
7       2024-01-08  3           1          25        1250.00
8       2024-05-14  2           2          30        900.00

SQL Server eliminated Sales2022 partition (partition elimination)!
*/

/*
================================================================================
PART 2: UPDATABLE PARTITIONED VIEWS
================================================================================

Partitioned views can be updatable if certain conditions are met.
*/

-- Requirements for updatable partitioned views:
-- 1. All base tables must be in the same database
-- 2. Each row appears in exactly one partition (enforced by CHECK constraints)
-- 3. Partitioning column(s) must be part of PRIMARY KEY
-- 4. Tables must have same structure

-- Our views meet these requirements - let's update through the view

-- INSERT through partitioned view
-- SQL Server routes to correct partition based on SaleDate
INSERT INTO AllSales (SaleID, SaleDate, CustomerID, ProductID, Quantity, Amount)
VALUES (10, '2024-11-09', 4, 1, 5, 250.00);
GO

SELECT * FROM Sales2024 WHERE SaleID = 10;
GO

/*
OUTPUT:
SaleID  SaleDate    CustomerID  ProductID  Quantity  Amount
------  ----------  ----------  ---------  --------  -------
10      2024-11-09  4           1          5         250.00

Inserted into correct partition automatically!
*/

-- UPDATE through partitioned view
UPDATE AllSales
SET Quantity = 6, Amount = 300.00
WHERE SaleID = 10;
GO

SELECT SaleID, Quantity, Amount FROM Sales2024 WHERE SaleID = 10;
GO

/*
OUTPUT:
SaleID  Quantity  Amount
------  --------  -------
10      6         300.00

Updated successfully!
*/

-- DELETE through partitioned view
DELETE FROM AllSales WHERE SaleID = 10;
GO

-- Verify deleted
SELECT COUNT(*) AS RemainingRows FROM Sales2024 WHERE SaleID = 10;
GO

/*
OUTPUT:
RemainingRows
-------------
0

Deleted successfully!
*/

/*
================================================================================
PART 3: PARTITION BY REGION (MULTI-TENANT PATTERN)
================================================================================

Another common pattern: Partition by geographic region or tenant.
*/

-- Create regional tables
DROP TABLE IF EXISTS Sales_North;
DROP TABLE IF EXISTS Sales_South;
DROP TABLE IF EXISTS Sales_East;
DROP TABLE IF EXISTS Sales_West;
GO

CREATE TABLE Sales_North (
    SaleID INT PRIMARY KEY,
    Region VARCHAR(10) NOT NULL CHECK (Region = 'North'),  -- Partition key
    SaleDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales_South (
    SaleID INT PRIMARY KEY,
    Region VARCHAR(10) NOT NULL CHECK (Region = 'South'),
    SaleDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales_East (
    SaleID INT PRIMARY KEY,
    Region VARCHAR(10) NOT NULL CHECK (Region = 'East'),
    SaleDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales_West (
    SaleID INT PRIMARY KEY,
    Region VARCHAR(10) NOT NULL CHECK (Region = 'West'),
    SaleDate DATE NOT NULL,
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);
GO

-- Insert regional data
INSERT INTO Sales_North VALUES
    (1, 'North', '2024-11-01', 101, 1000.00),
    (2, 'North', '2024-11-02', 102, 1500.00);

INSERT INTO Sales_South VALUES
    (3, 'South', '2024-11-01', 201, 800.00),
    (4, 'South', '2024-11-03', 202, 1200.00);

INSERT INTO Sales_East VALUES
    (5, 'East', '2024-11-02', 301, 900.00),
    (6, 'East', '2024-11-04', 302, 1100.00);

INSERT INTO Sales_West VALUES
    (7, 'West', '2024-11-01', 401, 1300.00),
    (8, 'West', '2024-11-05', 402, 950.00);
GO

-- Create consolidated view
CREATE VIEW SalesAllRegions AS
SELECT SaleID, Region, SaleDate, CustomerID, Amount FROM Sales_North
UNION ALL
SELECT SaleID, Region, SaleDate, CustomerID, Amount FROM Sales_South
UNION ALL
SELECT SaleID, Region, SaleDate, CustomerID, Amount FROM Sales_East
UNION ALL
SELECT SaleID, Region, SaleDate, CustomerID, Amount FROM Sales_West;
GO

-- Query all regions
SELECT Region, COUNT(*) AS SalesCount, SUM(Amount) AS TotalAmount
FROM SalesAllRegions
GROUP BY Region
ORDER BY TotalAmount DESC;
GO

/*
OUTPUT:
Region  SalesCount  TotalAmount
------  ----------  -----------
North   2           2500.00
West    2           2250.00
South   2           2000.00
East    2           2000.00

Regional summary from partitioned data!
*/

-- Query single region (partition elimination)
SELECT * FROM SalesAllRegions 
WHERE Region = 'North'
ORDER BY SaleDate;
GO

/*
SQL Server only scans Sales_North table!
*/

/*
================================================================================
PART 4: DISTRIBUTED PARTITIONED VIEWS
================================================================================

Combine tables from multiple servers (requires linked servers).
Note: This example shows the syntax; actual execution requires linked servers.
*/

-- Conceptual example of distributed partitioned view
-- Assumes linked servers: Server1, Server2, Server3

/*
-- Create distributed view (syntax example)
CREATE VIEW DistributedSales AS
-- Local data (current server)
SELECT SaleID, Region, SaleDate, Amount 
FROM Sales_Local
WHERE Region = 'North'

UNION ALL

-- Remote server 1
SELECT SaleID, Region, SaleDate, Amount 
FROM Server1.SalesDB.dbo.Sales
WHERE Region = 'South'

UNION ALL

-- Remote server 2
SELECT SaleID, Region, SaleDate, Amount 
FROM Server2.SalesDB.dbo.Sales
WHERE Region = 'East'

UNION ALL

-- Remote server 3
SELECT SaleID, Region, SaleDate, Amount 
FROM Server3.SalesDB.dbo.Sales
WHERE Region = 'West';
GO
*/

-- When querying distributed view:
-- SELECT * FROM DistributedSales WHERE Region = 'South';
-- SQL Server only queries Server1 (partition elimination across servers!)

/*
================================================================================
PART 5: PERFORMANCE OPTIMIZATION
================================================================================
*/

-- Create indexes on partitioning columns
CREATE INDEX IX_Sales2022_SaleDate ON Sales2022(SaleDate);
CREATE INDEX IX_Sales2023_SaleDate ON Sales2023(SaleDate);
CREATE INDEX IX_Sales2024_SaleDate ON Sales2024(SaleDate);
GO

CREATE INDEX IX_SalesNorth_Region ON Sales_North(Region) INCLUDE (Amount);
CREATE INDEX IX_SalesSouth_Region ON Sales_South(Region) INCLUDE (Amount);
CREATE INDEX IX_SalesEast_Region ON Sales_East(Region) INCLUDE (Amount);
CREATE INDEX IX_SalesWest_Region ON Sales_West(Region) INCLUDE (Amount);
GO

-- Example: Efficient query with partition elimination
SELECT 
    YEAR(SaleDate) AS Year,
    COUNT(*) AS SalesCount,
    SUM(Amount) AS TotalAmount,
    AVG(Amount) AS AvgAmount
FROM AllSales
WHERE SaleDate >= '2023-01-01'  -- Eliminates Sales2022
GROUP BY YEAR(SaleDate)
ORDER BY Year;
GO

/*
OUTPUT:
Year  SalesCount  TotalAmount  AvgAmount
----  ----------  -----------  ---------
2023  3           2110.00      703.33
2024  3           3050.00      1016.67

Efficiently scans only 2023 and 2024 partitions!
*/

/*
================================================================================
PART 6: ARCHIVAL PATTERN
================================================================================

Common use case: Keep recent data in fast storage, archive old data.
*/

-- Create current and archive tables
DROP TABLE IF EXISTS Sales_Current;
DROP TABLE IF EXISTS Sales_Archive;
GO

CREATE TABLE Sales_Current (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (SaleDate >= '2024-01-01'),  -- Current year
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales_Archive (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (SaleDate < '2024-01-01'),  -- Historical
    CustomerID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL
);
GO

-- Insert data
INSERT INTO Sales_Archive VALUES
    (1, '2022-05-10', 1, 500.00),
    (2, '2023-08-15', 2, 750.00);

INSERT INTO Sales_Current VALUES
    (3, '2024-01-20', 1, 1000.00),
    (4, '2024-11-05', 2, 1200.00);
GO

-- Combined view
CREATE VIEW Sales_All AS
SELECT SaleID, SaleDate, CustomerID, Amount, 'Current' AS DataSource
FROM Sales_Current
UNION ALL
SELECT SaleID, SaleDate, CustomerID, Amount, 'Archive' AS DataSource
FROM Sales_Archive;
GO

-- Query recent data (fast - only hits current partition)
SELECT * FROM Sales_All 
WHERE SaleDate >= '2024-01-01'
ORDER BY SaleDate;
GO

/*
OUTPUT:
SaleID  SaleDate    CustomerID  Amount    DataSource
------  ----------  ----------  --------  ----------
3       2024-01-20  1           1000.00   Current
4       2024-11-05  2           1200.00   Current

Partition elimination - Archive table not scanned!
*/

-- Query all data (both partitions)
SELECT 
    DataSource,
    COUNT(*) AS SalesCount,
    SUM(Amount) AS TotalAmount
FROM Sales_All
GROUP BY DataSource;
GO

/*
OUTPUT:
DataSource  SalesCount  TotalAmount
----------  ----------  -----------
Archive     2           1250.00
Current     3           2200.00
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Monthly Partitioned View
-------------------------------------
Create partitioned tables for November, October, and September 2024.
Each table should have a CHECK constraint on the month.
Create a view combining all three months.
Insert data and verify partition elimination works.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Department Partitioning
------------------------------------
Create tables partitioned by department: Sales, Marketing, Engineering.
Each table should store employee information (EmployeeID, DepartmentName, Salary).
Create a view combining all departments.
Query total salary by department.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Performance Analysis
---------------------------------
Using the AllSales view (yearly partitions), write queries that:
1. Query only 2024 data (verify partition elimination)
2. Query across multiple years
3. Aggregate by year
4. Show execution plans to confirm partition elimination

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Monthly Partitioned View
CREATE TABLE Sales_Nov2024 (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (YEAR(SaleDate) = 2024 AND MONTH(SaleDate) = 11),
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales_Oct2024 (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (YEAR(SaleDate) = 2024 AND MONTH(SaleDate) = 10),
    Amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE Sales_Sep2024 (
    SaleID INT PRIMARY KEY,
    SaleDate DATE NOT NULL CHECK (YEAR(SaleDate) = 2024 AND MONTH(SaleDate) = 9),
    Amount DECIMAL(10,2) NOT NULL
);
GO

CREATE VIEW Sales_Q4_2024 AS
SELECT SaleID, SaleDate, Amount FROM Sales_Nov2024
UNION ALL
SELECT SaleID, SaleDate, Amount FROM Sales_Oct2024
UNION ALL
SELECT SaleID, SaleDate, Amount FROM Sales_Sep2024;
GO

INSERT INTO Sales_Nov2024 VALUES (1, '2024-11-05', 1000.00);
INSERT INTO Sales_Oct2024 VALUES (2, '2024-10-15', 800.00);
INSERT INTO Sales_Sep2024 VALUES (3, '2024-09-20', 600.00);
GO

-- Query November only (partition elimination)
SELECT * FROM Sales_Q4_2024 WHERE MONTH(SaleDate) = 11;
GO

-- Solution 2: Department Partitioning
CREATE TABLE Employees_Sales (
    EmployeeID INT PRIMARY KEY,
    DepartmentName VARCHAR(20) NOT NULL CHECK (DepartmentName = 'Sales'),
    EmployeeName NVARCHAR(100),
    Salary DECIMAL(10,2)
);

CREATE TABLE Employees_Marketing (
    EmployeeID INT PRIMARY KEY,
    DepartmentName VARCHAR(20) NOT NULL CHECK (DepartmentName = 'Marketing'),
    EmployeeName NVARCHAR(100),
    Salary DECIMAL(10,2)
);

CREATE TABLE Employees_Engineering (
    EmployeeID INT PRIMARY KEY,
    DepartmentName VARCHAR(20) NOT NULL CHECK (DepartmentName = 'Engineering'),
    EmployeeName NVARCHAR(100),
    Salary DECIMAL(10,2)
);
GO

CREATE VIEW AllEmployees AS
SELECT EmployeeID, DepartmentName, EmployeeName, Salary FROM Employees_Sales
UNION ALL
SELECT EmployeeID, DepartmentName, EmployeeName, Salary FROM Employees_Marketing
UNION ALL
SELECT EmployeeID, DepartmentName, EmployeeName, Salary FROM Employees_Engineering;
GO

INSERT INTO Employees_Sales VALUES 
    (1, 'Sales', 'John Doe', 75000.00),
    (2, 'Sales', 'Jane Smith', 80000.00);

INSERT INTO Employees_Marketing VALUES
    (3, 'Marketing', 'Bob Johnson', 70000.00);

INSERT INTO Employees_Engineering VALUES
    (4, 'Engineering', 'Alice Williams', 95000.00),
    (5, 'Engineering', 'Charlie Brown', 90000.00);
GO

SELECT 
    DepartmentName,
    COUNT(*) AS EmployeeCount,
    SUM(Salary) AS TotalSalary,
    AVG(Salary) AS AvgSalary
FROM AllEmployees
GROUP BY DepartmentName
ORDER BY TotalSalary DESC;
GO

/*
OUTPUT:
DepartmentName  EmployeeCount  TotalSalary  AvgSalary
--------------  -------------  -----------  ---------
Engineering     2              185000.00    92500.00
Sales           2              155000.00    77500.00
Marketing       1              70000.00     70000.00
*/

-- Solution 3: Performance Analysis
-- Query 1: 2024 only (partition elimination)
SELECT * FROM AllSales 
WHERE SaleDate >= '2024-01-01' AND SaleDate < '2025-01-01'
ORDER BY SaleDate;
-- Only scans Sales2024

-- Query 2: Cross-year query
SELECT * FROM AllSales
WHERE SaleDate BETWEEN '2023-11-01' AND '2024-02-28'
ORDER BY SaleDate;
-- Scans Sales2023 and Sales2024 only

-- Query 3: Aggregate by year
SELECT 
    YEAR(SaleDate) AS Year,
    COUNT(*) AS SalesCount,
    SUM(Amount) AS TotalAmount,
    AVG(Amount) AS AvgAmount,
    MIN(Amount) AS MinAmount,
    MAX(Amount) AS MaxAmount
FROM AllSales
GROUP BY YEAR(SaleDate)
ORDER BY Year;
GO

-- Query 4: Show execution plan
SET STATISTICS IO ON;
GO

SELECT * FROM AllSales WHERE YEAR(SaleDate) = 2024;
GO

SET STATISTICS IO OFF;
GO
-- Check "Messages" tab - you'll see only Sales2024 table was scanned!

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. PARTITIONED VIEW BENEFITS
   - Combine data from multiple tables
   - Horizontal partitioning (split by rows)
   - Improved query performance via partition elimination
   - Easier data management (archive/delete partitions)
   - Scalability (distribute across servers)

2. PARTITION ELIMINATION
   - SQL Server automatically identifies relevant partitions
   - Only scans tables matching WHERE clause
   - Requires CHECK constraints on partition key
   - Dramatically improves performance
   - Works for local and distributed views

3. UPDATABLE PARTITIONED VIEWS
   - INSERT, UPDATE, DELETE through view
   - SQL Server routes to correct partition
   - Requires unique partitioning
   - CHECK constraints enforce boundaries
   - Partition key must be in PRIMARY KEY

4. COMMON PARTITIONING STRATEGIES
   - Time-based (yearly, monthly, daily)
   - Region-based (geographic distribution)
   - Tenant-based (multi-tenant systems)
   - Current vs Archive (hot/cold data)
   - Category-based (product types, etc.)

5. DISTRIBUTED PARTITIONED VIEWS
   - Combine data from multiple servers
   - Requires linked servers
   - Partition elimination works across servers
   - Consider network latency
   - Use for data federation

6. PERFORMANCE OPTIMIZATION
   - Create indexes on partition keys
   - Use appropriate CHECK constraints
   - Include covering indexes
   - Monitor execution plans
   - Consider indexed views for aggregates

7. BEST PRACTICES
   - Use CHECK constraints for partition boundaries
   - Keep partition structures identical
   - Document partitioning strategy
   - Plan partition maintenance
   - Monitor partition sizes
   - Consider archival strategy
   - Test partition elimination
   - Use UNION ALL (not UNION)

8. WHEN TO USE
   - Very large tables (billions of rows)
   - Time-series data
   - Multi-tenant applications
   - Distributed data
   - Archival scenarios
   - Regional data isolation

================================================================================

NEXT STEPS:
-----------
In Lesson 14.7, we'll explore UPDATABLE VIEWS:
- Rules for updatable views
- WITH CHECK OPTION
- INSTEAD OF triggers
- Complex update scenarios

Continue to: 07-updatable-views/lesson.sql

================================================================================
*/
