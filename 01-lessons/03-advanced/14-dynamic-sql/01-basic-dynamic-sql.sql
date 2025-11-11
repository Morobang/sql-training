-- ========================================
-- Basic Dynamic SQL with EXEC
-- ========================================

USE TechStore;

-- 1. Simple dynamic query
DECLARE @sql NVARCHAR(MAX);
SET @sql = 'SELECT ProductName, Price FROM Products WHERE Price > 100';
EXEC(@sql);

-- 2. Dynamic table name
DECLARE @tableName NVARCHAR(100) = 'Products';
DECLARE @query NVARCHAR(MAX);
SET @query = 'SELECT COUNT(*) AS RecordCount FROM ' + QUOTENAME(@tableName);
EXEC(@query);

-- 3. Dynamic ORDER BY
DECLARE @sortColumn NVARCHAR(50) = 'Price';
DECLARE @sortDirection NVARCHAR(4) = 'DESC';
DECLARE @sql2 NVARCHAR(MAX);

SET @sql2 = 'SELECT ProductName, Category, Price 
             FROM Products 
             ORDER BY ' + QUOTENAME(@sortColumn) + ' ' + @sortDirection;

-- Print to see the generated SQL
PRINT @sql2;

-- Execute it
EXEC(@sql2);

-- 4. Dynamic WHERE clause
DECLARE @category NVARCHAR(50) = 'Peripherals';
DECLARE @minPrice DECIMAL(10,2) = 50;
DECLARE @whereClause NVARCHAR(500);
DECLARE @sql3 NVARCHAR(MAX);

SET @whereClause = 'WHERE Category = ''' + @category + ''' AND Price >= ' + CAST(@minPrice AS NVARCHAR(20));
SET @sql3 = 'SELECT ProductName, Price FROM Products ' + @whereClause;

PRINT @sql3;
EXEC(@sql3);

-- 5. Dynamic column selection
DECLARE @columns NVARCHAR(500) = 'ProductName, Category, Price, StockQuantity';
DECLARE @sql4 NVARCHAR(MAX);

SET @sql4 = 'SELECT ' + @columns + ' FROM Products WHERE IsActive = 1';

PRINT @sql4;
EXEC(@sql4);

-- 💡 Note: EXEC() doesn't cache execution plans well
-- For better performance, use sp_executesql (next lesson)
