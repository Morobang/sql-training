-- ========================================
-- Clustered Indexes
-- Physical Data Ordering
-- ========================================

USE TechStore;
GO

-- =============================================
-- Understanding Clustered Indexes
-- =============================================

-- View current indexes on Products table
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique AS IsUnique,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('Products')
ORDER BY i.index_id, ic.key_ordinal;
GO

-- =============================================
-- Example 1: Default Clustered Index on Primary Key
-- =============================================

-- Create table with clustered primary key (default behavior)
DROP TABLE IF EXISTS OrdersDemo;
GO

CREATE TABLE OrdersDemo (
    OrderID INT PRIMARY KEY,  -- Clustered index automatically created
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
);
GO

-- Insert sample data
INSERT INTO OrdersDemo (OrderID, CustomerID, OrderDate, TotalAmount)
VALUES 
    (5, 1, '2024-01-15', 150.00),
    (1, 2, '2024-01-10', 200.00),
    (3, 1, '2024-01-12', 75.50),
    (2, 3, '2024-01-11', 300.25),
    (4, 2, '2024-01-14', 125.00);
GO

-- Data is physically stored in OrderID order (1, 2, 3, 4, 5)
SELECT * FROM OrdersDemo;
-- Even though we inserted 5,1,3,2,4, they're returned in order
GO

-- View the clustered index
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('OrdersDemo');
GO

-- =============================================
-- Example 2: Nonclustered Primary Key
-- =============================================

-- Create table with nonclustered primary key
DROP TABLE IF EXISTS ProductsDemo;
GO

CREATE TABLE ProductsDemo (
    ProductID INT PRIMARY KEY NONCLUSTERED,  -- Explicit nonclustered
    Category VARCHAR(50),
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

-- Without clustered index, this creates a HEAP (unordered storage)
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('ProductsDemo');
-- Shows: HEAP (type = 0) and nonclustered index on ProductID
GO

-- =============================================
-- Example 3: Clustered Index on Different Column
-- =============================================

-- Create clustered index on frequently queried column
DROP TABLE IF EXISTS SalesDemo;
GO

CREATE TABLE SalesDemo (
    SaleID INT PRIMARY KEY NONCLUSTERED,  -- Nonclustered PK
    CustomerID INT,
    SaleDate DATE,
    ProductID INT,
    Quantity INT,
    TotalAmount DECIMAL(10,2)
);
GO

-- Create clustered index on SaleDate (frequently used for range queries)
CREATE CLUSTERED INDEX IX_SalesDemo_SaleDate ON SalesDemo(SaleDate);
GO

-- Insert data out of order
INSERT INTO SalesDemo (SaleID, CustomerID, SaleDate, ProductID, Quantity, TotalAmount)
VALUES 
    (5, 1, '2024-01-15', 1, 2, 100.00),
    (1, 2, '2024-01-10', 2, 1, 50.00),
    (3, 1, '2024-01-12', 1, 3, 150.00),
    (7, 3, '2024-01-18', 3, 1, 75.00),
    (2, 2, '2024-01-11', 2, 2, 100.00);
GO

-- Data physically ordered by SaleDate, not SaleID
SELECT SaleID, SaleDate, TotalAmount 
FROM SalesDemo;
-- Returns in SaleDate order: 2024-01-10, 2024-01-11, 2024-01-12, ...
GO

-- =============================================
-- Example 4: Performance - Clustered Index Range Query
-- =============================================

-- Query using clustered index (efficient range scan)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Efficient: Uses clustered index for range query
SELECT SaleID, SaleDate, TotalAmount
FROM SalesDemo
WHERE SaleDate BETWEEN '2024-01-11' AND '2024-01-15'
ORDER BY SaleDate;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
-- Notice: Clustered Index Seek or Scan
-- Data already in SaleDate order, no sorting needed
GO

-- =============================================
-- Example 5: Composite Clustered Index
-- =============================================

DROP TABLE IF EXISTS EmployeeAttendance;
GO

CREATE TABLE EmployeeAttendance (
    EmployeeID INT,
    AttendanceDate DATE,
    TimeIn TIME,
    TimeOut TIME,
    CONSTRAINT PK_EmployeeAttendance PRIMARY KEY CLUSTERED (EmployeeID, AttendanceDate)
);
GO

-- Insert sample data
INSERT INTO EmployeeAttendance (EmployeeID, AttendanceDate, TimeIn, TimeOut)
VALUES 
    (2, '2024-01-15', '09:00', '17:00'),
    (1, '2024-01-16', '08:30', '16:30'),
    (1, '2024-01-15', '09:00', '17:30'),
    (2, '2024-01-16', '08:45', '17:15'),
    (1, '2024-01-17', '09:15', '17:00');
GO

-- Data ordered first by EmployeeID, then by AttendanceDate
SELECT * FROM EmployeeAttendance;
-- Returns: (1, 2024-01-15), (1, 2024-01-16), (1, 2024-01-17), (2, 2024-01-15), (2, 2024-01-16)
GO

-- Efficient queries using leading column(s)
SELECT * FROM EmployeeAttendance WHERE EmployeeID = 1;  -- Uses clustered index
SELECT * FROM EmployeeAttendance WHERE EmployeeID = 1 AND AttendanceDate = '2024-01-15';  -- Uses clustered index
-- But: WHERE AttendanceDate = '2024-01-15' alone = Clustered Index Scan (not as efficient)
GO

-- =============================================
-- Example 6: Changing Clustered Index
-- =============================================

-- Current clustered index on Products is ProductID (from PK)
-- Change to cluster on Category (for analytics queries)

-- First, make PK nonclustered
DROP TABLE IF EXISTS ProductsClusteredDemo;
GO

CREATE TABLE ProductsClusteredDemo (
    ProductID INT,
    Category VARCHAR(50),
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    StockQuantity INT
);
GO

-- Add nonclustered unique constraint for ProductID
ALTER TABLE ProductsClusteredDemo ADD CONSTRAINT PK_ProductsClusteredDemo PRIMARY KEY NONCLUSTERED (ProductID);
GO

-- Create clustered index on Category
CREATE CLUSTERED INDEX IX_ProductsClusteredDemo_Category ON ProductsClusteredDemo(Category);
GO

-- Insert sample data
INSERT INTO ProductsClusteredDemo (ProductID, Category, ProductName, Price, StockQuantity)
VALUES 
    (5, 'Electronics', 'Laptop', 799.99, 10),
    (1, 'Books', 'SQL Guide', 49.99, 50),
    (3, 'Electronics', 'Mouse', 29.99, 100),
    (2, 'Books', 'Python Basics', 39.99, 30),
    (4, 'Clothing', 'T-Shirt', 19.99, 200);
GO

-- Data physically ordered by Category
SELECT ProductID, Category, ProductName
FROM ProductsClusteredDemo;
-- Returns grouped by category: Books, Books, Clothing, Electronics, Electronics
GO

-- Analytics query (efficient aggregation)
SELECT 
    Category,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice,
    SUM(StockQuantity) AS TotalStock
FROM ProductsClusteredDemo
GROUP BY Category;
-- Efficient because data already grouped by Category
GO

-- =============================================
-- Example 7: Identity Column with Clustered Index
-- =============================================

DROP TABLE IF EXISTS AuditLog;
GO

CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,  -- Ever-increasing clustered key
    EventType VARCHAR(50),
    EventDate DATETIME DEFAULT GETDATE(),
    UserName VARCHAR(100),
    Details VARCHAR(500)
);
GO

-- Insert test data
INSERT INTO AuditLog (EventType, UserName, Details)
VALUES 
    ('LOGIN', 'User1', 'Successful login'),
    ('QUERY', 'User1', 'SELECT * FROM Products'),
    ('UPDATE', 'User2', 'Updated product price'),
    ('LOGIN', 'User3', 'Successful login');
GO

-- IDENTITY + Clustered Index = Sequential inserts (very efficient)
-- New rows always added at END of index (no page splits)
SELECT * FROM AuditLog;
GO

-- =============================================
-- Example 8: Clustered Index Pros/Cons
-- =============================================

/*
✅ GOOD for Clustered Index:
- Primary key (if small, unique, static)
- IDENTITY columns (sequential inserts)
- Date columns (time-series data, range queries)
- Columns frequently used in ORDER BY
- Columns used in range queries (BETWEEN, >, <)

❌ BAD for Clustered Index:
- Frequently updated columns (causes row movement)
- Wide keys (many columns or large data types)
- Columns with random values (GUIDs without NEWSEQUENTIALID)
- Low selectivity columns (few distinct values)
*/

-- =============================================
-- Example 9: View Index Fragmentation
-- =============================================

-- Check fragmentation of clustered indexes
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount,
    ips.avg_page_space_used_in_percent AS AvgPageFullness
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE i.type_desc = 'CLUSTERED'
    AND OBJECT_NAME(ips.object_id) LIKE '%Demo'
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- =============================================
-- Example 10: Rebuild Clustered Index
-- =============================================

-- Rebuild clustered index (also rebuilds all nonclustered indexes)
ALTER INDEX IX_SalesDemo_SaleDate ON SalesDemo REBUILD;
GO

-- Rebuild with options
ALTER INDEX IX_SalesDemo_SaleDate ON SalesDemo REBUILD 
WITH (
    FILLFACTOR = 90,  -- Leave 10% free space for future inserts
    SORT_IN_TEMPDB = ON,  -- Use tempdb for sort operations
    STATISTICS_NORECOMPUTE = OFF  -- Update statistics after rebuild
);
GO

-- =============================================
-- Cleanup (optional)
-- =============================================
/*
DROP TABLE IF EXISTS OrdersDemo;
DROP TABLE IF EXISTS ProductsDemo;
DROP TABLE IF EXISTS SalesDemo;
DROP TABLE IF EXISTS EmployeeAttendance;
DROP TABLE IF EXISTS ProductsClusteredDemo;
DROP TABLE IF EXISTS AuditLog;
*/

-- 💡 Key Takeaways:
-- - Only ONE clustered index per table (physical data ordering)
-- - Primary key creates clustered index by default
-- - Clustered index = data pages (leaf level is the data itself)
-- - Excellent for range queries and sequential access
-- - Identity columns make great clustered keys (sequential inserts)
-- - Rebuilding clustered index also rebuilds ALL nonclustered indexes
-- - Choose clustered key wisely (static, unique, narrow, used in queries)
-- - Date columns often better than random GUIDs for clustered keys
-- - Consider query patterns: range queries vs point lookups
-- - Avoid wide clustered keys (nonclustered indexes duplicate them)
