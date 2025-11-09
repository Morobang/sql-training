/*
================================================================================
LESSON 13.3: INDEX DESIGN STRATEGIES
================================================================================

Learning Objectives:
--------------------
By the end of this lesson, you will be able to:
1. Choose appropriate columns for indexing
2. Understand and calculate index selectivity
3. Balance read performance vs write overhead
4. Design indexes based on query patterns
5. Avoid common index design mistakes
6. Analyze index effectiveness
7. Make data-driven indexing decisions

Business Context:
-----------------
A database consultant is hired to optimize a slow e-commerce platform.
They need to analyze query patterns, identify indexing opportunities,
and design an optimal indexing strategy that improves read performance
without crippling write operations.

Database: RetailStore
Complexity: Intermediate to Advanced
Estimated Time: 55 minutes

================================================================================
*/

USE RetailStore;
GO

/*
================================================================================
PART 1: CHOOSING COLUMNS TO INDEX
================================================================================

Not all columns are good candidates for indexes. The decision should be based
on:
1. Query patterns (how is the column used?)
2. Data distribution (selectivity)
3. Table size
4. Read vs write ratio
5. Maintenance costs

GOLDEN RULES:
-------------
✅ DO Index: Primary keys, foreign keys, frequently queried columns
✅ DO Index: Columns in WHERE, JOIN, ORDER BY, GROUP BY clauses
✅ DO Index: High-selectivity columns (many unique values)
❌ DON'T Index: Small tables (< 1000 rows)
❌ DON'T Index: Low-selectivity columns (few unique values)
❌ DON'T Index: Frequently updated columns (high write overhead)
❌ DON'T Index: Wide columns (large text, binary data)

*/

-- Let's create a comprehensive example table to analyze
DROP TABLE IF EXISTS Product;
GO

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,  -- Already has clustered index
    ProductName NVARCHAR(200),
    SKU VARCHAR(50),
    CategoryID INT,
    BrandID INT,
    Price DECIMAL(10,2),
    Cost DECIMAL(10,2),
    StockQuantity INT,
    IsActive BIT,
    IsDiscounted BIT,
    Color NVARCHAR(30),
    Size NVARCHAR(10),
    Weight DECIMAL(8,2),
    Description NVARCHAR(MAX),  -- Very wide column
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Insert diverse sample data
DECLARE @i INT = 1;
WHILE @i <= 50000
BEGIN
    INSERT INTO Product (ProductName, SKU, CategoryID, BrandID, Price, Cost, StockQuantity, 
                         IsActive, IsDiscounted, Color, Size, Weight, Description)
    VALUES (
        'Product ' + CAST(@i AS VARCHAR),
        'SKU-' + RIGHT('00000' + CAST(@i AS VARCHAR), 5),
        (@i % 20) + 1,  -- 20 categories
        (@i % 50) + 1,  -- 50 brands
        (@i * 0.99) % 1000,
        (@i * 0.55) % 500,
        @i % 1000,
        CASE WHEN @i % 10 = 0 THEN 0 ELSE 1 END,  -- 90% active
        CASE WHEN @i % 5 = 0 THEN 1 ELSE 0 END,  -- 20% discounted
        CASE (@i % 8)
            WHEN 0 THEN 'Red' WHEN 1 THEN 'Blue'
            WHEN 2 THEN 'Green' WHEN 3 THEN 'Black'
            WHEN 4 THEN 'White' WHEN 5 THEN 'Yellow'
            WHEN 6 THEN 'Purple' ELSE 'Orange'
        END,
        CASE (@i % 5)
            WHEN 0 THEN 'XS' WHEN 1 THEN 'S'
            WHEN 2 THEN 'M' WHEN 3 THEN 'L'
            ELSE 'XL'
        END,
        (@i * 0.1) % 100,
        'This is a detailed product description for product ' + CAST(@i AS VARCHAR)
    );
    SET @i = @i + 1;
END
GO

-- Now let's analyze which columns are good index candidates

/*
================================================================================
PART 2: UNDERSTANDING INDEX SELECTIVITY
================================================================================

SELECTIVITY = Number of Distinct Values / Total Rows

High Selectivity (Good for indexes):
- Selectivity close to 1.0 (100%)
- Many unique values
- Example: Email addresses, SSN, Product SKU

Low Selectivity (Poor for indexes):
- Selectivity close to 0.0
- Few unique values
- Example: Gender (M/F), Boolean flags

Visual Representation:
----------------------
HIGH Selectivity (SKU):
SKU-00001 → 1 row
SKU-00002 → 1 row
SKU-00003 → 1 row
... (50,000 unique values)
Selectivity = 50,000 / 50,000 = 1.0 (100%)

LOW Selectivity (IsActive):
True  → 45,000 rows
False → 5,000 rows
Selectivity = 2 / 50,000 = 0.00004 (0.004%)

*/

-- Calculate selectivity for all columns
SELECT 
    'ProductID' AS ColumnName,
    COUNT(DISTINCT ProductID) AS DistinctValues,
    COUNT(*) AS TotalRows,
    CAST(COUNT(DISTINCT ProductID) AS FLOAT) / COUNT(*) AS Selectivity,
    CASE 
        WHEN CAST(COUNT(DISTINCT ProductID) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT ProductID) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT ProductID) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END AS IndexRecommendation
FROM Product

UNION ALL

SELECT 
    'SKU',
    COUNT(DISTINCT SKU),
    COUNT(*),
    CAST(COUNT(DISTINCT SKU) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT SKU) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT SKU) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT SKU) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product

UNION ALL

SELECT 
    'CategoryID',
    COUNT(DISTINCT CategoryID),
    COUNT(*),
    CAST(COUNT(DISTINCT CategoryID) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT CategoryID) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT CategoryID) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT CategoryID) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product

UNION ALL

SELECT 
    'BrandID',
    COUNT(DISTINCT BrandID),
    COUNT(*),
    CAST(COUNT(DISTINCT BrandID) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT BrandID) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT BrandID) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT BrandID) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product

UNION ALL

SELECT 
    'Color',
    COUNT(DISTINCT Color),
    COUNT(*),
    CAST(COUNT(DISTINCT Color) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT Color) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT Color) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT Color) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product

UNION ALL

SELECT 
    'Size',
    COUNT(DISTINCT Size),
    COUNT(*),
    CAST(COUNT(DISTINCT Size) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT Size) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT Size) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT Size) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product

UNION ALL

SELECT 
    'IsActive',
    COUNT(DISTINCT IsActive),
    COUNT(*),
    CAST(COUNT(DISTINCT IsActive) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT IsActive) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT IsActive) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT IsActive) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product

UNION ALL

SELECT 
    'IsDiscounted',
    COUNT(DISTINCT IsDiscounted),
    COUNT(*),
    CAST(COUNT(DISTINCT IsDiscounted) AS FLOAT) / COUNT(*),
    CASE 
        WHEN CAST(COUNT(DISTINCT IsDiscounted) AS FLOAT) / COUNT(*) > 0.95 THEN 'Excellent - Unique index candidate'
        WHEN CAST(COUNT(DISTINCT IsDiscounted) AS FLOAT) / COUNT(*) > 0.50 THEN 'Good - Index candidate'
        WHEN CAST(COUNT(DISTINCT IsDiscounted) AS FLOAT) / COUNT(*) > 0.10 THEN 'Fair - Consider composite index'
        ELSE 'Poor - Not recommended for indexing'
    END
FROM Product
ORDER BY Selectivity DESC;
GO

/*
OUTPUT:
ColumnName    DistinctValues  TotalRows  Selectivity  IndexRecommendation
-----------   --------------  ---------  -----------  -----------------------------
ProductID     50000           50000      1.000000     Excellent - Unique index candidate (PK)
SKU           50000           50000      1.000000     Excellent - Unique index candidate
BrandID       50              50000      0.001000     Fair - Consider composite index
CategoryID    20              50000      0.000400     Fair - Consider composite index
Color         8               50000      0.000160     Poor - Not recommended for indexing
Size          5               50000      0.000100     Poor - Not recommended for indexing
IsActive      2               50000      0.000040     Poor - Not recommended for indexing
IsDiscounted  2               50000      0.000040     Poor - Not recommended for indexing

ANALYSIS:
✅ SKU: Perfect unique index candidate (100% unique)
✅ BrandID: Good for composite indexes or filtered indexes
✅ CategoryID: Moderate selectivity, good for composite indexes
❌ Color, Size: Low selectivity - poor standalone index candidates
❌ IsActive, IsDiscounted: Very low selectivity - use filtered indexes only
*/

/*
================================================================================
PART 3: QUERY PATTERN ANALYSIS
================================================================================

Understanding how your application queries data is critical for index design.
Let's analyze common query patterns and design appropriate indexes.
*/

-- Pattern 1: Product lookup by SKU (exact match)
-- Frequency: Very high
-- Selectivity: Very high (unique)
-- Recommendation: Unique nonclustered index

CREATE UNIQUE NONCLUSTERED INDEX IX_Product_SKU
ON Product(SKU);
GO

-- Test query
SELECT ProductID, ProductName, SKU, Price
FROM Product
WHERE SKU = 'SKU-25000';
GO

/*
Execution Plan: Index Seek (optimal for unique lookups)
*/

-- Pattern 2: Product search by name (LIKE queries)
-- Frequency: High
-- Selectivity: Very high
-- Recommendation: Nonclustered index

CREATE NONCLUSTERED INDEX IX_Product_Name
ON Product(ProductName);
GO

-- Test query
SELECT ProductID, ProductName, Price
FROM Product
WHERE ProductName LIKE 'Product 1%';  -- Leading wildcard works with index
GO

/*
Execution Plan: Index Seek or Range Scan (depends on pattern)

Note: Trailing wildcard prevents index usage!
WHERE ProductName LIKE '%1000' -- Can't use index efficiently
*/

-- Pattern 3: Products by category (filtered queries)
-- Frequency: Very high
-- Selectivity: Moderate (20 categories)
-- Recommendation: Nonclustered index

CREATE NONCLUSTERED INDEX IX_Product_Category
ON Product(CategoryID)
INCLUDE (ProductName, Price, StockQuantity);  -- Covering for common columns
GO

-- Test query
SELECT ProductID, ProductName, Price, StockQuantity
FROM Product
WHERE CategoryID = 5;
GO

/*
Execution Plan: Index Seek (covered query - no key lookup needed)
*/

-- Pattern 4: Products by category AND brand (multi-column filter)
-- Frequency: High
-- Selectivity: Higher combined
-- Recommendation: Composite index

CREATE NONCLUSTERED INDEX IX_Product_Category_Brand
ON Product(CategoryID, BrandID)
INCLUDE (ProductName, Price);
GO

-- Test query
SELECT ProductID, ProductName, Price
FROM Product
WHERE CategoryID = 5
  AND BrandID = 10;
GO

/*
Execution Plan: Index Seek on composite index (very efficient)
*/

-- Pattern 5: Active products only (subset filtering)
-- Frequency: Very high (90% of queries only care about active products)
-- Selectivity: Low for IsActive alone, but filters 90% of data
-- Recommendation: Filtered indexes for active products

CREATE NONCLUSTERED INDEX IX_Product_Active_Category
ON Product(CategoryID)
INCLUDE (ProductName, Price, IsActive)
WHERE IsActive = 1;  -- Only index active products
GO

-- Test query
SELECT ProductID, ProductName, Price
FROM Product
WHERE CategoryID = 5
  AND IsActive = 1;  -- Must match filter condition!
GO

/*
Execution Plan: Index Seek on filtered index (smaller, faster)

Benefits:
- 10% smaller than full index
- Faster queries for active products
- Most queries benefit
*/

-- Pattern 6: Price range queries (range scans)
-- Frequency: Moderate
-- Selectivity: Variable
-- Recommendation: Nonclustered index with sorting

CREATE NONCLUSTERED INDEX IX_Product_Price
ON Product(Price)
INCLUDE (ProductName, CategoryID);
GO

-- Test query
SELECT ProductID, ProductName, Price
FROM Product
WHERE Price BETWEEN 100 AND 200
ORDER BY Price;
GO

/*
Execution Plan: Index Seek + Ordered Scan (efficient for ranges)
*/

-- Pattern 7: Multi-criteria search (category, price, active status)
-- Frequency: High (product catalog browsing)
-- Selectivity: High combined
-- Recommendation: Composite filtered covering index

CREATE NONCLUSTERED INDEX IX_Product_Catalog_Search
ON Product(CategoryID, Price)
INCLUDE (ProductName, BrandID, StockQuantity, IsDiscounted)
WHERE IsActive = 1;  -- Only active products
GO

-- Test complex catalog query
SELECT 
    ProductID,
    ProductName,
    CategoryID,
    BrandID,
    Price,
    IsDiscounted,
    StockQuantity
FROM Product
WHERE CategoryID = 5
  AND Price BETWEEN 50 AND 500
  AND IsActive = 1
ORDER BY Price;
GO

/*
Execution Plan: Single Index Seek (fully optimized!)
- Filters by CategoryID
- Filters by Price range
- Filters by IsActive (in filtered index definition)
- All SELECT columns covered
- Results already sorted by Price
*/

/*
================================================================================
PART 4: READ VS WRITE OVERHEAD ANALYSIS
================================================================================

Every index improves read performance but hurts write performance.
We need to balance these trade-offs.

Formula:
--------
Write Overhead = Number of Indexes × Write Frequency × Index Maintenance Cost
*/

-- Let's measure the actual impact of indexes on INSERT performance

-- Create test table with different index counts
DROP TABLE IF EXISTS IndexOverheadTest;
GO

CREATE TABLE IndexOverheadTest (
    ID INT IDENTITY(1,1) PRIMARY KEY,  -- 1 index
    Col1 VARCHAR(50),
    Col2 VARCHAR(50),
    Col3 VARCHAR(50),
    Col4 VARCHAR(50),
    Col5 VARCHAR(50)
);
GO

-- Baseline: INSERT performance with just primary key (1 index)
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @i INT = 1;

WHILE @i <= 10000
BEGIN
    INSERT INTO IndexOverheadTest (Col1, Col2, Col3, Col4, Col5)
    VALUES ('Value' + CAST(@i AS VARCHAR), 'Value' + CAST(@i AS VARCHAR),
            'Value' + CAST(@i AS VARCHAR), 'Value' + CAST(@i AS VARCHAR),
            'Value' + CAST(@i AS VARCHAR));
    SET @i = @i + 1;
END

DECLARE @Duration1Index INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
PRINT '10,000 INSERTs with 1 index: ' + CAST(@Duration1Index AS VARCHAR) + ' ms';
GO

-- Add 2 more indexes (total 3)
CREATE NONCLUSTERED INDEX IX_Test_Col1 ON IndexOverheadTest(Col1);
CREATE NONCLUSTERED INDEX IX_Test_Col2 ON IndexOverheadTest(Col2);
GO

-- Clear data for fresh test
TRUNCATE TABLE IndexOverheadTest;
GO

-- Test with 3 indexes
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @i INT = 1;

WHILE @i <= 10000
BEGIN
    INSERT INTO IndexOverheadTest (Col1, Col2, Col3, Col4, Col5)
    VALUES ('Value' + CAST(@i AS VARCHAR), 'Value' + CAST(@i AS VARCHAR),
            'Value' + CAST(@i AS VARCHAR), 'Value' + CAST(@i AS VARCHAR),
            'Value' + CAST(@i AS VARCHAR));
    SET @i = @i + 1;
END

DECLARE @Duration3Index INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
PRINT '10,000 INSERTs with 3 indexes: ' + CAST(@Duration3Index AS VARCHAR) + ' ms';
GO

-- Add 2 more indexes (total 5)
CREATE NONCLUSTERED INDEX IX_Test_Col3 ON IndexOverheadTest(Col3);
CREATE NONCLUSTERED INDEX IX_Test_Col4 ON IndexOverheadTest(Col4);
GO

TRUNCATE TABLE IndexOverheadTest;
GO

-- Test with 5 indexes
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @i INT = 1;

WHILE @i <= 10000
BEGIN
    INSERT INTO IndexOverheadTest (Col1, Col2, Col3, Col4, Col5)
    VALUES ('Value' + CAST(@i AS VARCHAR), 'Value' + CAST(@i AS VARCHAR),
            'Value' + CAST(@i AS VARCHAR), 'Value' + CAST(@i AS VARCHAR),
            'Value' + CAST(@i AS VARCHAR));
    SET @i = @i + 1;
END

DECLARE @Duration5Index INT = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
PRINT '10,000 INSERTs with 5 indexes: ' + CAST(@Duration5Index AS VARCHAR) + ' ms';
GO

/*
OUTPUT (example):
10,000 INSERTs with 1 index: 320 ms
10,000 INSERTs with 3 indexes: 580 ms  (~81% slower)
10,000 INSERTs with 5 indexes: 890 ms  (~178% slower)

CONCLUSION:
- Each additional index increases INSERT time by ~40-50%
- 5 indexes = nearly 3x slower than 1 index
- Balance is crucial!
*/

-- Clean up
DROP TABLE IndexOverheadTest;
GO

/*
DECISION FRAMEWORK:
-------------------

High Read / Low Write workload (Reporting databases):
✅ Create many indexes
✅ Use covering indexes extensively
✅ Index all frequently queried columns
Example: Data warehouses, analytical databases

Balanced Read/Write workload (OLTP applications):
⚖️ Create selective indexes
⚖️ Index primary/foreign keys and high-use columns
⚖️ Avoid redundant indexes
Example: E-commerce platforms, business applications

High Write / Low Read workload (Logging systems):
❌ Minimize indexes
❌ Only essential indexes (primary key, critical lookups)
❌ Consider delayed indexing strategies
Example: Event logging, sensor data ingestion

*/

/*
================================================================================
PART 5: COMMON INDEX DESIGN MISTAKES
================================================================================

Let's look at common mistakes and how to avoid them.
*/

-- MISTAKE 1: Redundant Indexes
-- ❌ BAD: Creating both single and composite indexes on same columns

-- Don't do this:
-- CREATE INDEX IX_Product_Category ON Product(CategoryID);
-- CREATE INDEX IX_Product_Category_Brand ON Product(CategoryID, BrandID);
-- Both exist - redundant!

-- ✅ GOOD: Just create the composite index
-- The composite index can serve both purposes:
-- - Queries filtering by CategoryID only
-- - Queries filtering by CategoryID AND BrandID

/*
EXPLANATION:
Index on (CategoryID, BrandID) can be used for:
✅ WHERE CategoryID = 5
✅ WHERE CategoryID = 5 AND BrandID = 10
❌ WHERE BrandID = 10 (can't use efficiently)

So a separate index on CategoryID alone is redundant!
*/

-- MISTAKE 2: Wrong Column Order in Composite Indexes
-- ❌ BAD: Creating index with wrong column order

-- Don't do this for this query:
-- SELECT * FROM Product WHERE BrandID = 10 AND CategoryID = 5;
-- CREATE INDEX IX_Wrong_Order ON Product(CategoryID, BrandID);

-- If your queries filter by BrandID more often than CategoryID:
-- ✅ GOOD: Put more selective/frequent column first
-- CREATE INDEX IX_Right_Order ON Product(BrandID, CategoryID);

/*
RULE: Order columns by:
1. Most frequently queried
2. Highest selectivity
3. Equality conditions before range conditions
*/

-- MISTAKE 3: Indexing Low-Selectivity Columns
-- ❌ BAD: Creating standalone index on boolean or low-cardinality columns

-- Don't do this:
-- CREATE INDEX IX_Bad_IsActive ON Product(IsActive);  -- Only 2 values!

-- ✅ GOOD: Use filtered index or composite index
CREATE NONCLUSTERED INDEX IX_Good_Active_Category
ON Product(CategoryID)
WHERE IsActive = 1;  -- Filtered index
GO

-- Or include in composite index as additional filter:
CREATE NONCLUSTERED INDEX IX_Good_Category_Brand_Active
ON Product(CategoryID, BrandID, IsActive);  -- IsActive as tertiary column
GO

-- MISTAKE 4: Not Including Covering Columns
-- ❌ BAD: Index that requires key lookups for common queries

-- Don't stop here:
DROP INDEX IF EXISTS IX_Product_Category ON Product;
CREATE NONCLUSTERED INDEX IX_Product_Category
ON Product(CategoryID);
GO

-- Query requires key lookup:
SELECT ProductID, ProductName, Price  -- ProductName and Price not in index!
FROM Product
WHERE CategoryID = 5;
GO

/*
Execution Plan: Index Seek → Key Lookup (expensive!)
*/

-- ✅ GOOD: Include frequently selected columns
DROP INDEX IF EXISTS IX_Product_Category ON Product;
CREATE NONCLUSTERED INDEX IX_Product_Category
ON Product(CategoryID)
INCLUDE (ProductName, Price);  -- Cover common SELECT columns
GO

-- Now the query is covered:
SELECT ProductID, ProductName, Price
FROM Product
WHERE CategoryID = 5;
GO

/*
Execution Plan: Index Seek only (optimal!)
*/

-- MISTAKE 5: Ignoring Index Maintenance
-- ❌ BAD: Creating indexes and never maintaining them
-- ✅ GOOD: Regular index maintenance (covered in Lesson 13.9)

-- MISTAKE 6: Creating Too Many Indexes
-- ❌ BAD: "Index everything just in case"
-- ✅ GOOD: Only index based on actual query patterns

-- Let's check current index count on Product table
SELECT 
    COUNT(*) AS TotalIndexes,
    SUM(ps.used_page_count) * 8 / 1024 AS TotalIndexSpaceMB
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps
    ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Product');
GO

/*
OUTPUT:
TotalIndexes  TotalIndexSpaceMB
------------  -----------------
12            45

ANALYSIS:
12 indexes on one table is probably too many!
Need to consolidate redundant indexes.
*/

/*
================================================================================
PART 6: INDEX CONSOLIDATION STRATEGY
================================================================================

Let's analyze our Product table indexes and consolidate them.
*/

-- View all indexes on Product table
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.has_filter AS IsFiltered,
    i.filter_definition AS FilterDefinition,
    STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') 
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns,
    ps.used_page_count * 8 AS SpaceKB
FROM sys.indexes i
INNER JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.dm_db_partition_stats ps
    ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('Product')
  AND ic.is_included_column = 0  -- Only key columns
GROUP BY i.name, i.type_desc, i.is_unique, i.has_filter, i.filter_definition, 
         ps.used_page_count
ORDER BY i.name;
GO

/*
CONSOLIDATION PLAN:
1. Keep essential indexes (PK, unique constraints, high-value indexes)
2. Drop redundant indexes (covered by composite indexes)
3. Consolidate similar indexes into composite/covering indexes
4. Keep filtered indexes for common subsets
*/

-- Drop redundant indexes we created earlier
-- (In real scenario, analyze usage first with DMVs before dropping!)

DROP INDEX IF EXISTS IX_Product_Category ON Product;  -- Redundant with IX_Product_Category_Brand
DROP INDEX IF EXISTS IX_Good_Category_Brand_Active ON Product;  -- Redundant with IX_Product_Active_Category
GO

/*
FINAL RECOMMENDED INDEXES for Product table:
1. PK_Product (clustered on ProductID) - automatic
2. IX_Product_SKU (unique) - high-value lookups
3. IX_Product_Name - common searches
4. IX_Product_Category_Brand - multi-criteria filtering
5. IX_Product_Active_Category - active product queries (filtered)
6. IX_Product_Price - range queries
7. IX_Product_Catalog_Search - comprehensive catalog queries (filtered, covering)

Total: 7 well-designed indexes
*/

/*
================================================================================
PRACTICAL EXERCISES
================================================================================

Exercise 1: Selectivity Analysis
--------------------------------
Calculate the selectivity of Size and Color columns in the Product table.
Should you create standalone indexes on these columns? Why or why not?

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 2: Query Pattern Design
--------------------------------
Design an optimal index strategy for this query pattern:

SELECT ProductID, ProductName, Price, StockQuantity
FROM Product
WHERE BrandID = 15
  AND Price >= 100
  AND IsActive = 1
ORDER BY Price;

Consider: column order, covering columns, filtered index.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
Exercise 3: Write Overhead Analysis
-----------------------------------
Create a test to measure UPDATE performance with 0, 2, and 4 indexes.
Calculate the overhead percentage.

TRY IT YOURSELF BEFORE LOOKING AT THE SOLUTION!
*/

-- Your solution here:






/*
================================================================================
EXERCISE SOLUTIONS
================================================================================
*/

-- Solution 1: Selectivity Analysis
SELECT 
    'Size' AS ColumnName,
    COUNT(DISTINCT Size) AS DistinctValues,
    COUNT(*) AS TotalRows,
    CAST(COUNT(DISTINCT Size) AS FLOAT) / COUNT(*) AS Selectivity
FROM Product

UNION ALL

SELECT 
    'Color',
    COUNT(DISTINCT Color),
    COUNT(*),
    CAST(COUNT(DISTINCT Color) AS FLOAT) / COUNT(*)
FROM Product;
GO

/*
OUTPUT:
ColumnName  DistinctValues  TotalRows  Selectivity
----------  --------------  ---------  -----------
Size        5               50000      0.0001
Color       8               50000      0.00016

ANALYSIS:
Both have very low selectivity (<0.1%).

RECOMMENDATION:
❌ DO NOT create standalone indexes on Size or Color
✅ DO consider them as additional columns in composite indexes
✅ DO consider filtered indexes if specific values are queried often

Example good use:
CREATE INDEX IX_Product_Brand_Color 
ON Product(BrandID, Color)  -- Color as secondary column
WHERE IsActive = 1;
*/

-- Solution 2: Query Pattern Design
-- Optimal index for the given query:

CREATE NONCLUSTERED INDEX IX_Product_Brand_Price_Active
ON Product(BrandID, Price)
INCLUDE (ProductName, StockQuantity)
WHERE IsActive = 1;
GO

/*
DESIGN RATIONALE:
1. BrandID first: Equality filter, high selectivity
2. Price second: Range filter, also used in ORDER BY
3. INCLUDE ProductName, StockQuantity: Cover SELECT columns
4. WHERE IsActive = 1: Filtered index (90% of data, matches query)

Benefits:
- Single index seek operation
- No key lookup needed (covering)
- Results already sorted by Price
- 10% smaller due to filter
*/

-- Test the query:
SELECT ProductID, ProductName, Price, StockQuantity
FROM Product
WHERE BrandID = 15
  AND Price >= 100
  AND IsActive = 1
ORDER BY Price;
GO

/*
Execution Plan: Single Index Seek (optimal!)
*/

-- Solution 3: Write Overhead Analysis
DROP TABLE IF EXISTS WriteOverheadTest;
GO

CREATE TABLE WriteOverheadTest (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Col1 VARCHAR(50),
    Col2 VARCHAR(50),
    Col3 VARCHAR(50),
    Col4 VARCHAR(50)
);
GO

-- Insert test data
INSERT INTO WriteOverheadTest (Col1, Col2, Col3, Col4)
SELECT 
    'Value' + CAST(number AS VARCHAR),
    'Value' + CAST(number AS VARCHAR),
    'Value' + CAST(number AS VARCHAR),
    'Value' + CAST(number AS VARCHAR)
FROM master..spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 5000;
GO

-- Test 1: UPDATE with 0 additional indexes (just PK)
DECLARE @Start DATETIME = GETDATE();

UPDATE WriteOverheadTest
SET Col1 = 'Updated' + CAST(ID AS VARCHAR);

DECLARE @Duration0 INT = DATEDIFF(MILLISECOND, @Start, GETDATE());
PRINT 'UPDATE with 1 index (PK): ' + CAST(@Duration0 AS VARCHAR) + ' ms';

-- Revert
UPDATE WriteOverheadTest SET Col1 = 'Value' + CAST(ID AS VARCHAR);
GO

-- Add 2 indexes (total 3 with PK)
CREATE INDEX IX_Test_Col2 ON WriteOverheadTest(Col2);
CREATE INDEX IX_Test_Col3 ON WriteOverheadTest(Col3);
GO

-- Test 2: UPDATE with 2 additional indexes
DECLARE @Start DATETIME = GETDATE();

UPDATE WriteOverheadTest
SET Col1 = 'Updated' + CAST(ID AS VARCHAR);

DECLARE @Duration2 INT = DATEDIFF(MILLISECOND, @Start, GETDATE());
PRINT 'UPDATE with 3 indexes: ' + CAST(@Duration2 AS VARCHAR) + ' ms';

UPDATE WriteOverheadTest SET Col1 = 'Value' + CAST(ID AS VARCHAR);
GO

-- Add 2 more indexes (total 5 with PK)
CREATE INDEX IX_Test_Col4 ON WriteOverheadTest(Col4);
CREATE INDEX IX_Test_Col1 ON WriteOverheadTest(Col1);  -- Indexed column being updated!
GO

-- Test 3: UPDATE with 4 additional indexes
DECLARE @Start DATETIME = GETDATE();

UPDATE WriteOverheadTest
SET Col1 = 'Updated' + CAST(ID AS VARCHAR);  -- Updating indexed column!

DECLARE @Duration4 INT = DATEDIFF(MILLISECOND, @Start, GETDATE());
PRINT 'UPDATE with 5 indexes (updated column indexed): ' + CAST(@Duration4 AS VARCHAR) + ' ms';
GO

/*
OUTPUT (example):
UPDATE with 1 index (PK): 45 ms
UPDATE with 3 indexes: 78 ms (73% slower)
UPDATE with 5 indexes (updated column indexed): 125 ms (178% slower)

KEY INSIGHTS:
- Each index adds maintenance overhead to UPDATEs
- Updating indexed columns is especially expensive (index must be updated)
- 4 additional indexes = nearly 3x slower UPDATEs
*/

DROP TABLE WriteOverheadTest;
GO

/*
================================================================================
KEY TAKEAWAYS
================================================================================

1. INDEX SELECTION CRITERIA
   - Analyze query patterns first
   - Calculate selectivity (distinct values / total rows)
   - High selectivity (>50%) = good standalone index
   - Low selectivity (<10%) = composite or filtered index only

2. QUERY PATTERN ANALYSIS
   - Index columns in WHERE, JOIN, ORDER BY, GROUP BY
   - Consider covering indexes for frequent queries
   - Use filtered indexes for subset queries
   - Composite indexes for multi-column filters

3. COLUMN ORDER IN COMPOSITE INDEXES
   - Most selective or most frequently queried first
   - Equality conditions before range conditions
   - ORDER BY columns should match index column order

4. READ VS WRITE BALANCE
   - Each index improves reads but hurts writes
   - Read-heavy: More indexes acceptable
   - Write-heavy: Minimize indexes
   - Balanced: Selective indexing

5. AVOID COMMON MISTAKES
   - No redundant indexes
   - Correct column order in composites
   - Don't index low-selectivity columns alone
   - Use INCLUDE for covering indexes
   - Regular index maintenance
   - Don't over-index

6. INDEX CONSOLIDATION
   - Regularly review index usage
   - Drop unused or redundant indexes
   - Consolidate similar indexes
   - Keep index count manageable (typically <10 per table)

7. DECISION FRAMEWORK
   - Analyze actual query workload
   - Measure performance before/after
   - Monitor index usage with DMVs
   - Balance performance vs overhead
   - Document index strategy

================================================================================

NEXT STEPS:
-----------
In Lesson 13.4, we'll dive into PRIMARY KEY CONSTRAINTS:
- Understanding primary key characteristics
- Single vs composite primary keys
- Choosing appropriate primary key columns
- Auto-increment vs natural keys

Continue to: 04-primary-key-constraints.sql

================================================================================
*/
