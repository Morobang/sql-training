-- ========================================
-- Table Variables (@table)
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Basic Table Variable Usage
-- =============================================

-- Declare table variable
DECLARE @CategoryStats TABLE (
    Category NVARCHAR(50),
    ProductCount INT,
    AvgPrice DECIMAL(10,2)
);

-- Insert data
INSERT INTO @CategoryStats (Category, ProductCount, AvgPrice)
SELECT 
    Category,
    COUNT(*) AS ProductCount,
    AVG(Price) AS AvgPrice
FROM Products
GROUP BY Category;

-- Query the variable
SELECT * FROM @CategoryStats ORDER BY ProductCount DESC;

-- Table variables have limited scope (batch or procedure)
-- Cannot be referenced outside this batch

-- =============================================
-- Example 2: Table Variables in Stored Procedures
-- =============================================

CREATE OR ALTER PROCEDURE GetTopProductsByCategory
    @MinPrice DECIMAL(10,2)
AS
BEGIN
    -- Table variable exists only within procedure
    DECLARE @TopProducts TABLE (
        ProductID INT,
        ProductName NVARCHAR(100),
        Category NVARCHAR(50),
        Price DECIMAL(10,2),
        Rank INT
    );
    
    -- Populate table variable
    INSERT INTO @TopProducts
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price,
        ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Price DESC) AS Rank
    FROM Products
    WHERE Price >= @MinPrice;
    
    -- Return only top 3 per category
    SELECT 
        ProductName,
        Category,
        Price,
        Rank
    FROM @TopProducts
    WHERE Rank <= 3
    ORDER BY Category, Rank;
END;
GO

EXEC GetTopProductsByCategory @MinPrice = 100;

DROP PROCEDURE GetTopProductsByCategory;

-- =============================================
-- Example 3: Table Variable vs Temp Table
-- =============================================

-- Scenario: Processing small dataset

-- Method 1: Table Variable (better for small datasets)
DECLARE @SmallDataset TABLE (
    CustomerID INT,
    OrderCount INT,
    TotalSpent DECIMAL(10,2)
);

INSERT INTO @SmallDataset
SELECT TOP 20
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Sales
GROUP BY CustomerID
ORDER BY COUNT(*) DESC;

SELECT * FROM @SmallDataset WHERE TotalSpent > 200;

-- Method 2: Temp Table (better for large datasets)
CREATE TABLE #LargeDataset (
    CustomerID INT,
    OrderCount INT,
    TotalSpent DECIMAL(10,2)
);

INSERT INTO #LargeDataset
SELECT 
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalAmount) AS TotalSpent
FROM Sales
GROUP BY CustomerID;

SELECT * FROM #LargeDataset WHERE TotalSpent > 200;

DROP TABLE #LargeDataset;

-- =============================================
-- Example 4: Table Variables with PRIMARY KEY
-- =============================================

DECLARE @UniqueCustomers TABLE (
    CustomerID INT PRIMARY KEY,
    CustomerName NVARCHAR(100),
    State NVARCHAR(50),
    TotalOrders INT
);

INSERT INTO @UniqueCustomers
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.State,
    COUNT(s.SaleID) AS TotalOrders
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName, c.State;

-- Primary key provides fast lookups
SELECT * FROM @UniqueCustomers WHERE CustomerID = 5;

-- =============================================
-- Example 5: When to Use Table Variables
-- =============================================

-- ✅ Use @table when:
-- - Small datasets (< 100 rows typically)
-- - Temporary storage within stored procedure
-- - No need for indexes beyond primary key
-- - Simple operations (INSERT, SELECT)
-- - Scope limited to batch/procedure

-- ❌ Avoid @table when:
-- - Large datasets (use #temp)
-- - Need multiple indexes
-- - Require statistics for optimization
-- - Used in multiple queries (optimizer issues)
-- - Need explicit transaction control

-- Example: Perfect use case for table variable
DECLARE @DailyTotals TABLE (
    SaleDate DATE,
    DailyRevenue DECIMAL(10,2)
);

INSERT INTO @DailyTotals
SELECT 
    CAST(SaleDate AS DATE) AS SaleDate,
    SUM(TotalAmount) AS DailyRevenue
FROM Sales
GROUP BY CAST(SaleDate AS DATE);

-- Simple aggregation on small result
SELECT 
    AVG(DailyRevenue) AS AvgDailyRevenue,
    MAX(DailyRevenue) AS BestDay,
    MIN(DailyRevenue) AS WorstDay
FROM @DailyTotals;

-- =============================================
-- Example 6: Table Variables in Functions
-- =============================================

CREATE OR ALTER FUNCTION GetProductsByPriceRange
(
    @MinPrice DECIMAL(10,2),
    @MaxPrice DECIMAL(10,2)
)
RETURNS @ProductList TABLE (
    ProductID INT,
    ProductName NVARCHAR(100),
    Category NVARCHAR(50),
    Price DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @ProductList
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price
    FROM Products
    WHERE Price BETWEEN @MinPrice AND @MaxPrice;
    
    RETURN;
END;
GO

-- Use the function
SELECT * FROM dbo.GetProductsByPriceRange(100, 500)
ORDER BY Price DESC;

DROP FUNCTION GetProductsByPriceRange;

-- =============================================
-- Example 7: Limitations of Table Variables
-- =============================================

-- Limitation 1: No statistics
-- SQL Server assumes 1 row, leading to poor execution plans for large data

-- Limitation 2: Cannot alter structure after declaration
DECLARE @TestTable TABLE (ID INT, Name NVARCHAR(50));
-- ALTER TABLE @TestTable ADD NewColumn INT; -- ERROR!

-- Limitation 3: No explicit indexing (except constraints)
DECLARE @Indexed TABLE (
    ID INT PRIMARY KEY,           -- Allowed: clustered index
    Email NVARCHAR(100) UNIQUE    -- Allowed: unique constraint creates index
    -- INDEX IX_Name (Name)       -- NOT allowed: explicit CREATE INDEX
);

-- Limitation 4: Scope limited to batch
DECLARE @OutOfScope TABLE (ID INT, Value NVARCHAR(50));
INSERT INTO @OutOfScope VALUES (1, 'Test');
GO

-- SELECT * FROM @OutOfScope; -- ERROR: Variable not defined

-- 💡 Key Points:
-- - Table variables exist only within batch or procedure
-- - Great for small, temporary datasets
-- - Less overhead than temp tables for small data
-- - Limited indexing (PRIMARY KEY, UNIQUE only)
-- - No statistics = poor plans for large data
-- - Cannot be used across batches or sessions
-- - Ideal for functions returning table results
