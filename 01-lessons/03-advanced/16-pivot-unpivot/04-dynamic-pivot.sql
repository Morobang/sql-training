-- ========================================
-- Dynamic PIVOT: Building Column List at Runtime
-- ========================================

USE TechStore;
GO

-- =============================================
-- Problem with Static PIVOT
-- =============================================

-- Static PIVOT requires hardcoding column names:
/*
SELECT *
FROM SourceData
PIVOT (
    SUM(Amount)
    FOR Category IN ([Electronics], [Clothing], [Books])  -- Fixed list!
) AS PivotTable;
*/

-- What if you don't know all categories in advance?
-- What if categories change over time?

-- =============================================
-- Example 1: Dynamic PIVOT for Categories
-- =============================================

DECLARE @Columns NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);

-- Step 1: Build comma-separated list of categories
SELECT @Columns = STRING_AGG(QUOTENAME(Category), ', ')
FROM (SELECT DISTINCT Category FROM Products) AS Categories;

PRINT 'Pivot Columns: ' + @Columns;

-- Step 2: Build dynamic PIVOT query
SET @SQL = '
SELECT *
FROM (
    SELECT 
        CAST(s.SaleDate AS DATE) AS SaleDate,
        p.Category,
        s.TotalAmount
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Category IN (' + @Columns + ')
) AS PivotTable
ORDER BY SaleDate DESC';

-- Step 3: Execute dynamic SQL
EXEC sp_executesql @SQL;

-- =============================================
-- Example 2: Dynamic PIVOT for Payment Methods
-- =============================================

DECLARE @PaymentColumns NVARCHAR(MAX);
DECLARE @PaymentSQL NVARCHAR(MAX);

-- Build column list from actual data
SELECT @PaymentColumns = STRING_AGG(QUOTENAME(PaymentMethod), ', ')
FROM (SELECT DISTINCT PaymentMethod FROM Sales WHERE PaymentMethod IS NOT NULL) AS Methods;

SET @PaymentSQL = '
SELECT 
    CustomerName,
    ' + @PaymentColumns + '
FROM (
    SELECT 
        c.CustomerName,
        s.PaymentMethod,
        s.TotalAmount
    FROM Customers c
    INNER JOIN Sales s ON c.CustomerID = s.CustomerID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR PaymentMethod IN (' + @PaymentColumns + ')
) AS PivotTable
ORDER BY CustomerName';

EXEC sp_executesql @PaymentSQL;

-- =============================================
-- Example 3: Dynamic PIVOT with Date Ranges
-- =============================================

-- Pivot by month names
DECLARE @MonthColumns NVARCHAR(MAX);
DECLARE @MonthSQL NVARCHAR(MAX);

-- Get distinct months from sales data
SELECT @MonthColumns = STRING_AGG(QUOTENAME(Month), ', ')
FROM (
    SELECT DISTINCT DATENAME(MONTH, SaleDate) AS Month
    FROM Sales
) AS Months;

SET @MonthSQL = '
SELECT 
    Category,
    ' + @MonthColumns + '
FROM (
    SELECT 
        p.Category,
        DATENAME(MONTH, s.SaleDate) AS Month,
        s.TotalAmount
    FROM Products p
    INNER JOIN Sales s ON p.ProductID = s.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Month IN (' + @MonthColumns + ')
) AS PivotTable
ORDER BY Category';

EXEC sp_executesql @MonthSQL;

-- =============================================
-- Example 4: Dynamic PIVOT with Stored Procedure
-- =============================================

CREATE OR ALTER PROCEDURE DynamicPivotByColumn
    @PivotColumn NVARCHAR(50),      -- Column to pivot (e.g., 'Category', 'PaymentMethod')
    @SourceTable NVARCHAR(128),     -- Table name
    @AggregateColumn NVARCHAR(50),  -- Column to aggregate
    @AggregateFunction NVARCHAR(20) -- SUM, COUNT, AVG, etc.
AS
BEGIN
    DECLARE @ColumnList NVARCHAR(MAX);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Validate inputs
    IF @AggregateFunction NOT IN ('SUM', 'COUNT', 'AVG', 'MIN', 'MAX')
    BEGIN
        RAISERROR('Invalid aggregate function. Use: SUM, COUNT, AVG, MIN, MAX', 16, 1);
        RETURN;
    END;
    
    -- Build column list dynamically
    SET @SQL = '
    SELECT @Cols = STRING_AGG(QUOTENAME(' + QUOTENAME(@PivotColumn) + '), '', '')
    FROM (SELECT DISTINCT ' + QUOTENAME(@PivotColumn) + ' FROM ' + QUOTENAME(@SourceTable) + ') AS DistinctValues';
    
    EXEC sp_executesql @SQL, N'@Cols NVARCHAR(MAX) OUTPUT', @Cols = @ColumnList OUTPUT;
    
    -- Build and execute pivot query
    SET @SQL = '
    SELECT *
    FROM ' + QUOTENAME(@SourceTable) + '
    PIVOT (
        ' + @AggregateFunction + '(' + QUOTENAME(@AggregateColumn) + ')
        FOR ' + QUOTENAME(@PivotColumn) + ' IN (' + @ColumnList + ')
    ) AS PivotTable';
    
    PRINT 'Executing: ' + @SQL;
    EXEC sp_executesql @SQL;
END;
GO

-- Test the procedure (Note: This is a simplified example)
-- EXEC DynamicPivotByColumn 
--     @PivotColumn = 'Category',
--     @SourceTable = 'Products',
--     @AggregateColumn = 'Price',
--     @AggregateFunction = 'AVG';

DROP PROCEDURE DynamicPivotByColumn;

-- =============================================
-- Example 5: Dynamic PIVOT with Custom Formatting
-- =============================================

DECLARE @FormattedColumns NVARCHAR(MAX);
DECLARE @FormattedSQL NVARCHAR(MAX);

-- Build column list with aliases
SELECT @FormattedColumns = STRING_AGG(
    QUOTENAME(Category) + ' AS ' + QUOTENAME(REPLACE(Category, ' ', '_')),
    ', '
)
FROM (SELECT DISTINCT Category FROM Products) AS C;

SET @FormattedSQL = '
SELECT 
    SaleDate,
    ' + @FormattedColumns + '
FROM (
    SELECT 
        CAST(s.SaleDate AS DATE) AS SaleDate,
        p.Category,
        s.TotalAmount
    FROM Sales s
    INNER JOIN Products p ON s.ProductID = p.ProductID
) AS SourceData
PIVOT (
    SUM(TotalAmount)
    FOR Category IN (
        ' + (SELECT STRING_AGG(QUOTENAME(Category), ', ') 
            FROM (SELECT DISTINCT Category FROM Products) AS C2) + '
    )
) AS PivotTable
ORDER BY SaleDate DESC';

EXEC sp_executesql @FormattedSQL;

-- =============================================
-- Example 6: Dynamic PIVOT with Pre-SQL Server 2017
-- =============================================

-- If STRING_AGG not available, use FOR XML PATH

DECLARE @OldStyleColumns NVARCHAR(MAX);

SELECT @OldStyleColumns = STUFF((
    SELECT ', ' + QUOTENAME(Category)
    FROM (SELECT DISTINCT Category FROM Products) AS C
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

PRINT 'Columns (old style): ' + @OldStyleColumns;

-- Use @OldStyleColumns in dynamic PIVOT query same as before

-- =============================================
-- Example 7: Error Handling in Dynamic PIVOT
-- =============================================

DECLARE @SafeColumns NVARCHAR(MAX);
DECLARE @SafeSQL NVARCHAR(MAX);

BEGIN TRY
    -- Check if we have data to pivot
    IF NOT EXISTS (SELECT 1 FROM Sales)
    BEGIN
        RAISERROR('No sales data available for pivot', 16, 1);
        RETURN;
    END;
    
    -- Build column list
    SELECT @SafeColumns = STRING_AGG(QUOTENAME(Category), ', ')
    FROM (SELECT DISTINCT Category FROM Products WHERE Category IS NOT NULL) AS C;
    
    IF @SafeColumns IS NULL OR @SafeColumns = ''
    BEGIN
        RAISERROR('No categories found for pivot', 16, 1);
        RETURN;
    END;
    
    -- Build and execute query
    SET @SafeSQL = '
    SELECT *
    FROM (
        SELECT 
            CAST(s.SaleDate AS DATE) AS SaleDate,
            p.Category,
            s.TotalAmount
        FROM Sales s
        INNER JOIN Products p ON s.ProductID = p.ProductID
        WHERE p.Category IS NOT NULL
    ) AS SourceData
    PIVOT (
        SUM(TotalAmount)
        FOR Category IN (' + @SafeColumns + ')
    ) AS PivotTable
    ORDER BY SaleDate DESC';
    
    EXEC sp_executesql @SafeSQL;
    
END TRY
BEGIN CATCH
    PRINT 'Error in dynamic PIVOT: ' + ERROR_MESSAGE();
END CATCH;

-- 💡 Key Points:
-- - Use STRING_AGG to build column list dynamically (SQL Server 2017+)
-- - For older versions, use FOR XML PATH with STUFF
-- - Always use QUOTENAME for column names
-- - Validate inputs to prevent SQL injection
-- - Test with actual data to ensure columns exist
-- - Dynamic PIVOT is powerful but adds complexity
-- - Consider creating a reusable stored procedure
