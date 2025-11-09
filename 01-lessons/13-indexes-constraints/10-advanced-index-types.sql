/*
================================================================================
LESSON 13.10: ADVANCED INDEX TYPES
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Create and use filtered indexes
2. Understand columnstore indexes for analytics
3. Implement full-text indexes for text searching
4. Work with spatial indexes for geographic data
5. Create XML indexes for XML columns
6. Understand covering indexes with INCLUDE clause
7. Choose appropriate index types for different scenarios

Business Context:
-----------------
Standard B-tree indexes don't fit every scenario. Filtered indexes
reduce storage for partial data, columnstore indexes accelerate
analytics, full-text indexes enable sophisticated text search,
and spatial indexes optimize location queries. Choosing the right
index type dramatically improves performance for specialized workloads.

Database: RetailStore
Complexity: Advanced
Estimated Time: 45 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: FILTERED INDEXES
================================================================================

FILTERED INDEXES are nonclustered indexes with a WHERE clause that
indexes only a subset of rows.

BENEFITS:
---------
1. SMALLER SIZE: Fewer rows = smaller index
2. FASTER QUERIES: Less to scan
3. REDUCED MAINTENANCE: Fewer rows to update
4. BETTER STATISTICS: More accurate for filtered data

WHEN TO USE:
------------
- Querying sparse columns (mostly NULL)
- Querying specific status values
- Archived vs active data separation
- Specific date ranges

Visual Representation:
----------------------
Full Index on Status (all 100,000 rows):
Status     RowCount  IndexSize
---------  --------  ---------
Active     80,000    50 MB
Inactive   15,000    
Archived   5,000     

Filtered Index WHERE Status = 'Active' (only 80,000 rows):
Status     RowCount  IndexSize
---------  --------  ---------
Active     80,000    40 MB  (20% smaller!)

*/

-- Example 1: Filtered index on active records
DROP TABLE IF EXISTS CustomerAccount;
GO

CREATE TABLE CustomerAccount (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Status VARCHAR(20) NOT NULL,  -- 'Active', 'Inactive', 'Suspended'
    Balance DECIMAL(10,2),
    LastActivityDate DATE,
    CreatedDate DATE DEFAULT CAST(GETDATE() AS DATE)
);
GO

-- Insert sample data
INSERT INTO CustomerAccount (CustomerName, Email, Status, Balance, LastActivityDate)
SELECT 
    'Customer ' + CAST(number AS VARCHAR(10)),
    'customer' + CAST(number AS VARCHAR(10)) + '@example.com',
    CASE 
        WHEN number % 10 = 0 THEN 'Suspended'
        WHEN number % 5 = 0 THEN 'Inactive'
        ELSE 'Active'
    END,
    CAST(ABS(CHECKSUM(NEWID())) % 10000 AS DECIMAL(10,2)),
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, CAST(GETDATE() AS DATE))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10000;
GO

-- Standard index (indexes all rows)
CREATE INDEX IX_CustomerAccount_Status 
ON CustomerAccount(Status);
GO

-- Filtered index (indexes only active accounts)
CREATE INDEX IX_CustomerAccount_Active 
ON CustomerAccount(Status, LastActivityDate)
WHERE Status = 'Active';  -- FILTER PREDICATE
GO

-- Compare sizes
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.page_count AS Pages,
    ips.record_count AS Records,
    (ips.page_count * 8.0 / 1024) AS SizeMB
FROM sys.indexes i
INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('CustomerAccount'), NULL, NULL, 'DETAILED') ips
    ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE i.name IN ('IX_CustomerAccount_Status', 'IX_CustomerAccount_Active')
ORDER BY i.name;
GO

/*
OUTPUT:
IndexName                      IndexType       Pages  Records  SizeMB
-----------------------------  --------------  -----  -------  ------
IX_CustomerAccount_Active      NONCLUSTERED    95     7,000    0.74
IX_CustomerAccount_Status      NONCLUSTERED    120    10,000   0.94

Filtered index is ~20% smaller (only Active records)!
*/

-- Query using filtered index
SELECT AccountID, CustomerName, Balance, LastActivityDate
FROM CustomerAccount
WHERE Status = 'Active'  -- Uses filtered index
    AND LastActivityDate >= '2023-01-01';
GO

-- Example 2: Filtered index on sparse columns (NULLs)
DROP TABLE IF EXISTS ProductReview;
GO

CREATE TABLE ProductReview (
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating INT NOT NULL,
    ReviewText NVARCHAR(MAX),
    VerifiedPurchase BIT,
    ReviewDate DATE DEFAULT CAST(GETDATE() AS DATE),
    ModeratorNotes NVARCHAR(500)  -- Mostly NULL (sparse)
);
GO

-- Insert reviews (only 5% have moderator notes)
INSERT INTO ProductReview (ProductID, CustomerID, Rating, ReviewText, VerifiedPurchase, ModeratorNotes)
SELECT 
    ABS(CHECKSUM(NEWID())) % 100 + 1,
    ABS(CHECKSUM(NEWID())) % 1000 + 1,
    ABS(CHECKSUM(NEWID())) % 5 + 1,
    'This is a review...',
    CASE WHEN number % 2 = 0 THEN 1 ELSE 0 END,
    CASE WHEN number % 20 = 0 THEN 'Flagged for review' ELSE NULL END
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 5000;
GO

-- Filtered index only on reviews with moderator notes
CREATE INDEX IX_ProductReview_ModeratorNotes 
ON ProductReview(ReviewDate, ModeratorNotes)
WHERE ModeratorNotes IS NOT NULL;  -- Only ~5% of rows
GO

-- Query flagged reviews (uses filtered index)
SELECT ReviewID, ProductID, ReviewDate, ModeratorNotes
FROM ProductReview
WHERE ModeratorNotes IS NOT NULL
ORDER BY ReviewDate DESC;
GO

/*
FILTERED INDEX LIMITATIONS:
---------------------------
- Cannot be on computed columns
- Cannot reference columns from other tables
- Filter predicate must be deterministic
- Cannot use functions like GETDATE()
- Best for low selectivity (small subset)
*/

/*
================================================================================
PART 2: COLUMNSTORE INDEXES
================================================================================

COLUMNSTORE INDEXES store data by column instead of by row.
Optimized for analytical queries (aggregations, large scans).

ROW-ORIENTED (Traditional):
ID    Name      Price    Quantity
---   -------   ------   --------
1     Apple     1.50     100
2     Banana    0.75     200
3     Orange    2.00     150

COLUMN-ORIENTED (Columnstore):
ID: [1, 2, 3]
Name: [Apple, Banana, Orange]
Price: [1.50, 0.75, 2.00]
Quantity: [100, 200, 150]

BENEFITS:
---------
- 10x data compression (columnar storage)
- Faster aggregations (read only needed columns)
- Batch mode execution
- Ideal for data warehousing

TYPES:
------
1. CLUSTERED COLUMNSTORE (table storage)
2. NONCLUSTERED COLUMNSTORE (additional index)

*/

-- Example 1: Nonclustered columnstore for analytics
DROP TABLE IF EXISTS SalesHistory;
GO

CREATE TABLE SalesHistory (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate DATE NOT NULL,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    Region VARCHAR(50),
    SalesPersonID INT
);
GO

-- Insert large dataset (simulating historical sales)
INSERT INTO SalesHistory (SaleDate, ProductID, CustomerID, Quantity, UnitPrice, TotalAmount, Region, SalesPersonID)
SELECT 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 1095, CAST(GETDATE() AS DATE)),  -- Last 3 years
    ABS(CHECKSUM(NEWID())) % 500 + 1,
    ABS(CHECKSUM(NEWID())) % 10000 + 1,
    ABS(CHECKSUM(NEWID())) % 50 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 100 + 10 AS DECIMAL(10,2)),
    CAST((ABS(CHECKSUM(NEWID())) % 50 + 1) * (ABS(CHECKSUM(NEWID())) % 100 + 10) AS DECIMAL(10,2)),
    CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        ELSE 'West'
    END,
    ABS(CHECKSUM(NEWID())) % 50 + 1
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 2048;
GO 10  -- Repeat to get ~20,000 rows

-- Create nonclustered columnstore index for analytics
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesHistory_Analytics
ON SalesHistory (SaleDate, Region, ProductID, Quantity, TotalAmount);
GO

-- Analytical query (benefits from columnstore)
SELECT 
    YEAR(SaleDate) AS SaleYear,
    MONTH(SaleDate) AS SaleMonth,
    Region,
    COUNT(*) AS TotalSales,
    SUM(Quantity) AS TotalQuantity,
    SUM(TotalAmount) AS Revenue,
    AVG(TotalAmount) AS AvgSaleAmount
FROM SalesHistory
GROUP BY YEAR(SaleDate), MONTH(SaleDate), Region
ORDER BY SaleYear, SaleMonth, Region;
GO

-- Example 2: Clustered columnstore (entire table)
DROP TABLE IF EXISTS FactSales;
GO

CREATE TABLE FactSales (
    SaleDate DATE NOT NULL,
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    QuantitySold INT NOT NULL,
    SalesAmount DECIMAL(10,2) NOT NULL,
    CostAmount DECIMAL(10,2) NOT NULL,
    Profit AS (SalesAmount - CostAmount)
);
GO

-- Create clustered columnstore index (table becomes columnstore)
CREATE CLUSTERED COLUMNSTORE INDEX CCI_FactSales
ON FactSales;
GO

-- Insert data (columnstore tables support INSERT, UPDATE, DELETE)
INSERT INTO FactSales (SaleDate, ProductKey, CustomerKey, QuantitySold, SalesAmount, CostAmount)
SELECT 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, CAST(GETDATE() AS DATE)),
    ABS(CHECKSUM(NEWID())) % 1000 + 1,
    ABS(CHECKSUM(NEWID())) % 50000 + 1,
    ABS(CHECKSUM(NEWID())) % 100 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 1000 + 50 AS DECIMAL(10,2)),
    CAST(ABS(CHECKSUM(NEWID())) % 500 + 20 AS DECIMAL(10,2))
FROM master..spt_values v1
CROSS JOIN (SELECT TOP 50 * FROM master..spt_values WHERE type = 'P') v2
WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 2048;
GO

-- Analytical query on columnstore table
SELECT 
    DATEPART(YEAR, SaleDate) AS Year,
    DATEPART(QUARTER, SaleDate) AS Quarter,
    COUNT(*) AS TotalTransactions,
    SUM(QuantitySold) AS TotalQuantity,
    SUM(SalesAmount) AS TotalRevenue,
    SUM(CostAmount) AS TotalCost,
    SUM(Profit) AS TotalProfit
FROM FactSales
GROUP BY DATEPART(YEAR, SaleDate), DATEPART(QUARTER, SaleDate)
ORDER BY Year, Quarter;
GO

/*
COLUMNSTORE BEST PRACTICES:
----------------------------
- Use for analytical workloads (aggregations)
- Batch inserts (>102,400 rows) for best compression
- Avoid for OLTP (row-by-row operations)
- Combine with partitioning for large tables
- Monitor rowgroup health with sys.dm_db_column_store_row_group_physical_stats
*/

/*
================================================================================
PART 3: FULL-TEXT INDEXES
================================================================================

FULL-TEXT INDEXES enable sophisticated text searching:
- Natural language queries
- Proximity searches
- Weighted searches
- Thesaurus support

Note: Requires Full-Text Search feature installed.
*/

-- Enable full-text search (if not already enabled)
-- This is typically done during SQL Server installation

-- Example: Full-text index on product descriptions
DROP TABLE IF EXISTS ProductCatalog;
GO

CREATE TABLE ProductCatalog (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    Specifications NVARCHAR(MAX),
    Category VARCHAR(50),
    Price DECIMAL(10,2)
);
GO

-- Insert sample products
INSERT INTO ProductCatalog (ProductName, Description, Specifications, Category, Price)
VALUES
    ('Wireless Bluetooth Headphones', 'High-quality wireless headphones with noise cancellation and premium sound quality. Perfect for music lovers and professionals.', 'Battery: 30 hours, Bluetooth 5.0, Active Noise Cancellation', 'Electronics', 199.99),
    ('Ergonomic Office Chair', 'Comfortable ergonomic chair designed for long hours of work. Adjustable height, lumbar support, and breathable mesh back.', 'Weight capacity: 300 lbs, Height adjustable, 5-year warranty', 'Furniture', 349.99),
    ('Stainless Steel Water Bottle', 'Insulated water bottle keeps drinks cold for 24 hours and hot for 12 hours. BPA-free and eco-friendly.', 'Capacity: 32 oz, Double-wall vacuum insulated', 'Home & Kitchen', 29.99),
    ('Professional Camera Lens', 'High-performance camera lens for professional photography. Wide aperture for low-light performance.', 'Focal length: 50mm, Aperture: f/1.4, Compatible with Canon EOS', 'Photography', 899.99),
    ('Organic Coffee Beans', 'Premium organic coffee beans sourced from sustainable farms. Rich, bold flavor with smooth finish.', 'Origin: Colombia, Roast: Medium, Fair Trade Certified', 'Food & Beverage', 24.99);
GO

-- Create full-text catalog (container for full-text indexes)
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'ProductCatalog_FT')
BEGIN
    CREATE FULLTEXT CATALOG ProductCatalog_FT AS DEFAULT;
END
GO

-- Create full-text index
CREATE FULLTEXT INDEX ON ProductCatalog (
    ProductName,           -- Column to index
    Description,           -- Column to index
    Specifications         -- Column to index
)
KEY INDEX PK__ProductC__B40CC6ED12345678  -- Reference to primary key
ON ProductCatalog_FT
WITH CHANGE_TRACKING AUTO;  -- Automatically track changes
GO

-- Full-text search examples

-- Example 1: CONTAINS - exact phrase search
SELECT ProductID, ProductName, Price
FROM ProductCatalog
WHERE CONTAINS(Description, 'wireless');
GO

-- Example 2: FREETEXT - natural language search
SELECT ProductID, ProductName, Price
FROM ProductCatalog
WHERE FREETEXT(Description, 'comfortable chair for office work');
GO

-- Example 3: Proximity search (NEAR)
SELECT ProductID, ProductName, Price
FROM ProductCatalog
WHERE CONTAINS(Description, 'noise NEAR cancellation');
GO

-- Example 4: Weighted search (rank results)
SELECT 
    ProductID,
    ProductName,
    Price,
    FT_TBL.RANK AS Relevance
FROM ProductCatalog
INNER JOIN CONTAINSTABLE(ProductCatalog, (ProductName, Description), 'premium OR professional') AS FT_TBL
    ON ProductCatalog.ProductID = FT_TBL.[KEY]
ORDER BY FT_TBL.RANK DESC;
GO

/*
FULL-TEXT SEARCH PREDICATES:
-----------------------------
CONTAINS    - Boolean search (AND, OR, NOT)
FREETEXT    - Natural language
CONTAINSTABLE - Returns rank (relevance score)
FREETEXTTABLE - Natural language with rank

FULL-TEXT SEARCH OPERATORS:
----------------------------
AND         - Both words must exist
OR          - Either word exists
NEAR        - Words close to each other
"phrase"    - Exact phrase match
prefix*     - Word prefix
*/

/*
================================================================================
PART 4: SPATIAL INDEXES
================================================================================

SPATIAL INDEXES optimize queries on geography and geometry data types.
Used for location-based searches.

Note: Requires spatial data types support.
*/

-- Example: Store locations with spatial index
DROP TABLE IF EXISTS StoreLocation;
GO

CREATE TABLE StoreLocation (
    StoreID INT IDENTITY(1,1) PRIMARY KEY,
    StoreName NVARCHAR(100) NOT NULL,
    Address NVARCHAR(200),
    City NVARCHAR(50),
    State CHAR(2),
    Location GEOGRAPHY NOT NULL  -- Spatial data type
);
GO

-- Insert sample store locations
INSERT INTO StoreLocation (StoreName, Address, City, State, Location)
VALUES
    ('Downtown Store', '123 Main St', 'Seattle', 'WA', geography::Point(47.6062, -122.3321, 4326)),
    ('Eastside Store', '456 East Ave', 'Bellevue', 'WA', geography::Point(47.6101, -122.2015, 4326)),
    ('Airport Store', '789 Airport Way', 'SeaTac', 'WA', geography::Point(47.4502, -122.3088, 4326)),
    ('North Store', '321 North Blvd', 'Everett', 'WA', geography::Point(47.9790, -122.2021, 4326)),
    ('South Store', '654 South St', 'Tacoma', 'WA', geography::Point(47.2529, -122.4443, 4326));
GO

-- Create spatial index
CREATE SPATIAL INDEX SIX_StoreLocation_Location
ON StoreLocation(Location)
USING GEOGRAPHY_GRID
WITH (
    GRIDS = (LEVEL_1 = MEDIUM, LEVEL_2 = MEDIUM, LEVEL_3 = MEDIUM, LEVEL_4 = MEDIUM),
    CELLS_PER_OBJECT = 16
);
GO

-- Find stores within 20 miles (32,186 meters) of a location
DECLARE @SearchLocation GEOGRAPHY = geography::Point(47.6062, -122.3321, 4326);  -- Downtown Seattle

SELECT 
    StoreID,
    StoreName,
    City,
    Location.STDistance(@SearchLocation) / 1609.344 AS DistanceMiles  -- Convert meters to miles
FROM StoreLocation
WHERE Location.STDistance(@SearchLocation) <= 32186.9  -- 20 miles in meters
ORDER BY Location.STDistance(@SearchLocation);
GO

/*
OUTPUT:
StoreID  StoreName        City      DistanceMiles
-------  ---------------  --------  -------------
1        Downtown Store   Seattle   0.00
2        Eastside Store   Bellevue  8.52
3        Airport Store    SeaTac    12.73

Spatial index optimizes distance calculations!
*/

/*
================================================================================
PART 5: COVERING INDEXES WITH INCLUDE
================================================================================

COVERING INDEXES include all columns needed by a query, eliminating
lookups to the base table.

*/

-- Example: Covering index with INCLUDE clause
DROP TABLE IF EXISTS Employee;
GO

CREATE TABLE Employee (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Department NVARCHAR(50) NOT NULL,
    Salary DECIMAL(10,2) NOT NULL,
    HireDate DATE NOT NULL,
    Email NVARCHAR(100),
    Phone VARCHAR(20)
);
GO

-- Insert sample employees
INSERT INTO Employee (FirstName, LastName, Department, Salary, HireDate, Email, Phone)
SELECT 
    'FirstName' + CAST(number AS VARCHAR(10)),
    'LastName' + CAST(number AS VARCHAR(10)),
    CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN 'Sales'
        WHEN 1 THEN 'Marketing'
        WHEN 2 THEN 'Engineering'
        WHEN 3 THEN 'HR'
        ELSE 'Finance'
    END,
    CAST(ABS(CHECKSUM(NEWID())) % 100000 + 40000 AS DECIMAL(10,2)),
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 3650, CAST(GETDATE() AS DATE)),
    'employee' + CAST(number AS VARCHAR(10)) + '@company.com',
    '555-' + RIGHT('000' + CAST(number AS VARCHAR(4)), 4)
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 1000;
GO

-- Regular index (Department only)
CREATE INDEX IX_Employee_Department 
ON Employee(Department);
GO

-- Covering index (Department + included columns)
CREATE INDEX IX_Employee_Department_Covering 
ON Employee(Department)
INCLUDE (FirstName, LastName, Salary, HireDate);  -- Non-key columns
GO

-- Query 1: Uses regular index + Key Lookup (slower)
SELECT FirstName, LastName, Salary
FROM Employee WITH (INDEX(IX_Employee_Department))
WHERE Department = 'Sales';
GO

-- Query 2: Uses covering index (no lookup needed - faster!)
SELECT FirstName, LastName, Salary, HireDate
FROM Employee WITH (INDEX(IX_Employee_Department_Covering))
WHERE Department = 'Sales';
GO

/*
COVERING INDEX BENEFITS:
------------------------
- No key lookups (bookmark lookups)
- All data in index
- Faster query performance
- Reduced I/O

TRADE-OFFS:
-----------
- Larger index size
- More maintenance overhead
- Use selectively for critical queries
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Filtered Index
---------------------------
Create a filtered index for orders placed in the last 30 days
with status 'Pending'. Verify it's used by a query.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Columnstore Performance
-----------------------------------
Create a columnstore index on a sales fact table and compare
query performance for an aggregation query.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Covering Index
--------------------------
Create a covering index for a frequent query that searches
employees by department and returns name, salary, and hire date.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Filtered Index
DROP TABLE IF EXISTS OrderHeader;
GO

CREATE TABLE OrderHeader (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status VARCHAR(20) NOT NULL,
    TotalAmount DECIMAL(10,2)
);
GO

-- Insert orders
INSERT INTO OrderHeader (CustomerID, OrderDate, Status, TotalAmount)
SELECT 
    ABS(CHECKSUM(NEWID())) % 1000 + 1,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 90, CAST(GETDATE() AS DATE)),
    CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN 'Pending'
        WHEN 1 THEN 'Processing'
        WHEN 2 THEN 'Shipped'
        ELSE 'Delivered'
    END,
    CAST(ABS(CHECKSUM(NEWID())) % 1000 + 50 AS DECIMAL(10,2))
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 5000;
GO

-- Create filtered index for recent pending orders
CREATE INDEX IX_OrderHeader_RecentPending 
ON OrderHeader(OrderDate, CustomerID)
WHERE Status = 'Pending' 
    AND OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
GO

-- Query using filtered index
SELECT OrderID, CustomerID, OrderDate, TotalAmount
FROM OrderHeader
WHERE Status = 'Pending'
    AND OrderDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
ORDER BY OrderDate DESC;
GO

-- Solution 2: Columnstore Performance
DROP TABLE IF EXISTS SalesData;
GO

CREATE TABLE SalesData (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    SaleDate DATE NOT NULL,
    ProductID INT NOT NULL,
    StoreID INT NOT NULL,
    Quantity INT NOT NULL,
    Revenue DECIMAL(10,2) NOT NULL
);
GO

-- Insert large dataset
INSERT INTO SalesData (SaleDate, ProductID, StoreID, Quantity, Revenue)
SELECT 
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 730, CAST(GETDATE() AS DATE)),
    ABS(CHECKSUM(NEWID())) % 500 + 1,
    ABS(CHECKSUM(NEWID())) % 50 + 1,
    ABS(CHECKSUM(NEWID())) % 100 + 1,
    CAST(ABS(CHECKSUM(NEWID())) % 1000 + 10 AS DECIMAL(10,2))
FROM master..spt_values v1
CROSS JOIN (SELECT TOP 20 * FROM master..spt_values WHERE type = 'P') v2
WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 2048;
GO

-- Create columnstore index
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesData
ON SalesData (SaleDate, ProductID, StoreID, Quantity, Revenue);
GO

-- Analytical query (benefits from columnstore)
SELECT 
    YEAR(SaleDate) AS Year,
    MONTH(SaleDate) AS Month,
    COUNT(*) AS TotalSales,
    SUM(Quantity) AS TotalQuantity,
    SUM(Revenue) AS TotalRevenue,
    AVG(Revenue) AS AvgRevenue
FROM SalesData
GROUP BY YEAR(SaleDate), MONTH(SaleDate)
ORDER BY Year, Month;
GO

-- Solution 3: Covering Index
-- (Already created in Part 5 - see IX_Employee_Department_Covering example)

SELECT FirstName, LastName, Salary, HireDate
FROM Employee
WHERE Department = 'Engineering'
ORDER BY HireDate DESC;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. FILTERED INDEXES
   - Index subset of rows with WHERE clause
   - Smaller, faster, less maintenance
   - Perfect for sparse columns, specific statuses
   - Reduce storage and improve performance

2. COLUMNSTORE INDEXES
   - Store data by column (not row)
   - 10x compression
   - Ideal for analytics and aggregations
   - Clustered (entire table) or nonclustered
   - Avoid for OLTP workloads

3. FULL-TEXT INDEXES
   - Sophisticated text searching
   - CONTAINS, FREETEXT predicates
   - Proximity searches, ranking
   - Requires full-text catalog

4. SPATIAL INDEXES
   - Optimize geography/geometry queries
   - Distance calculations
   - Location-based searches
   - Grid-based indexing

5. COVERING INDEXES
   - Include all columns needed by query
   - Eliminate key lookups
   - Use INCLUDE clause for non-key columns
   - Balance size vs performance

6. CHOOSING INDEX TYPES
   - B-tree: General purpose (OLTP)
   - Filtered: Subset of data
   - Columnstore: Analytics (OLAP)
   - Full-text: Text search
   - Spatial: Geographic data
   - Covering: Eliminate lookups

7. BEST PRACTICES
   - Choose appropriate index type for workload
   - Monitor index usage and size
   - Balance performance vs overhead
   - Test before implementing in production
   - Document index purposes
   - Regular maintenance

================================================================================

NEXT STEPS:
-----------
In Lesson 13.11, we'll explore CONSTRAINT MANAGEMENT:
- Adding constraints to existing tables
- Dropping and modifying constraints
- Enabling and disabling constraints
- Checking constraint violations
- Best practices

Continue to: 11-constraint-management.sql

================================================================================
*/
