-- ========================================
-- Dynamic Search: Flexible Query Building
-- ========================================

USE TechStore;
GO

-- =============================================
-- Example 1: Basic Optional Search Parameters
-- =============================================

CREATE OR ALTER PROCEDURE SearchProducts
    @ProductName NVARCHAR(100) = NULL,
    @Category NVARCHAR(50) = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @InStock BIT = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
        SELECT 
            ProductID,
            ProductName,
            Category,
            Price,
            StockQuantity
        FROM Products
        WHERE 1=1';  -- Trick: always true, makes adding conditions easier
    
    -- Add conditions only if parameters provided
    IF @ProductName IS NOT NULL
        SET @SQL = @SQL + ' AND ProductName LIKE ''%'' + @PName + ''%''';
    
    IF @Category IS NOT NULL
        SET @SQL = @SQL + ' AND Category = @Cat';
    
    IF @MinPrice IS NOT NULL
        SET @SQL = @SQL + ' AND Price >= @MinP';
    
    IF @MaxPrice IS NOT NULL
        SET @SQL = @SQL + ' AND Price <= @MaxP';
    
    IF @InStock IS NOT NULL
        SET @SQL = @SQL + ' AND (StockQuantity > 0) = @Stock';
    
    SET @SQL = @SQL + ' ORDER BY ProductName';
    
    -- Execute with all possible parameters
    EXEC sp_executesql 
        @SQL,
        N'@PName NVARCHAR(100), @Cat NVARCHAR(50), @MinP DECIMAL(10,2), @MaxP DECIMAL(10,2), @Stock BIT',
        @PName = @ProductName,
        @Cat = @Category,
        @MinP = @MinPrice,
        @MaxP = @MaxPrice,
        @Stock = @InStock;
END;
GO

-- Test the procedure
EXEC SearchProducts @Category = 'Electronics', @MinPrice = 200;
EXEC SearchProducts @ProductName = 'Laptop', @InStock = 1;
EXEC SearchProducts @MaxPrice = 100;

-- =============================================
-- Example 2: Advanced Customer Search
-- =============================================

CREATE OR ALTER PROCEDURE SearchCustomers
    @Name NVARCHAR(100) = NULL,
    @State NVARCHAR(50) = NULL,
    @MinPurchases INT = NULL,
    @MinSpent DECIMAL(10,2) = NULL,
    @SortBy NVARCHAR(50) = 'Name'  -- Name, State, TotalSpent
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
        SELECT 
            c.CustomerID,
            c.CustomerName,
            c.State,
            COUNT(s.SaleID) AS TotalOrders,
            ISNULL(SUM(s.TotalAmount), 0) AS TotalSpent
        FROM Customers c
        LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
        WHERE 1=1';
    
    IF @Name IS NOT NULL
        SET @SQL = @SQL + ' AND c.CustomerName LIKE ''%'' + @CName + ''%''';
    
    IF @State IS NOT NULL
        SET @SQL = @SQL + ' AND c.State = @CState';
    
    SET @SQL = @SQL + ' GROUP BY c.CustomerID, c.CustomerName, c.State';
    
    -- HAVING clause conditions (applied after GROUP BY)
    IF @MinPurchases IS NOT NULL
        SET @SQL = @SQL + ' HAVING COUNT(s.SaleID) >= @MinOrders';
    
    IF @MinSpent IS NOT NULL
    BEGIN
        IF @MinPurchases IS NOT NULL
            SET @SQL = @SQL + ' AND SUM(s.TotalAmount) >= @MinAmount';
        ELSE
            SET @SQL = @SQL + ' HAVING SUM(s.TotalAmount) >= @MinAmount';
    END;
    
    -- Dynamic ORDER BY
    IF @SortBy = 'State'
        SET @SQL = @SQL + ' ORDER BY c.State, c.CustomerName';
    ELSE IF @SortBy = 'TotalSpent'
        SET @SQL = @SQL + ' ORDER BY TotalSpent DESC';
    ELSE
        SET @SQL = @SQL + ' ORDER BY c.CustomerName';
    
    EXEC sp_executesql 
        @SQL,
        N'@CName NVARCHAR(100), @CState NVARCHAR(50), @MinOrders INT, @MinAmount DECIMAL(10,2)',
        @CName = @Name,
        @CState = @State,
        @MinOrders = @MinPurchases,
        @MinAmount = @MinSpent;
END;
GO

-- Test searches
EXEC SearchCustomers @State = 'CA', @SortBy = 'TotalSpent';
EXEC SearchCustomers @MinSpent = 500, @SortBy = 'TotalSpent';
EXEC SearchCustomers @Name = 'Smith';

-- =============================================
-- Example 3: Dynamic Column Selection
-- =============================================

CREATE OR ALTER PROCEDURE GetSalesReport
    @IncludeCustomer BIT = 1,
    @IncludeProduct BIT = 1,
    @IncludePayment BIT = 0,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(500) = 's.SaleID, s.SaleDate, s.TotalAmount';
    
    -- Build column list dynamically
    IF @IncludeCustomer = 1
        SET @Columns = @Columns + ', c.CustomerName, c.State';
    
    IF @IncludeProduct = 1
        SET @Columns = @Columns + ', p.ProductName, p.Category';
    
    IF @IncludePayment = 1
        SET @Columns = @Columns + ', s.PaymentMethod';
    
    -- Build base query
    SET @SQL = 'SELECT ' + @Columns + ' FROM Sales s';
    
    -- Add JOINs based on selected columns
    IF @IncludeCustomer = 1
        SET @SQL = @SQL + ' INNER JOIN Customers c ON s.CustomerID = c.CustomerID';
    
    IF @IncludeProduct = 1
        SET @SQL = @SQL + ' INNER JOIN Products p ON s.ProductID = p.ProductID';
    
    -- Add date filters
    SET @SQL = @SQL + ' WHERE 1=1';
    
    IF @StartDate IS NOT NULL
        SET @SQL = @SQL + ' AND s.SaleDate >= @Start';
    
    IF @EndDate IS NOT NULL
        SET @SQL = @SQL + ' AND s.SaleDate <= @End';
    
    SET @SQL = @SQL + ' ORDER BY s.SaleDate DESC';
    
    EXEC sp_executesql 
        @SQL,
        N'@Start DATE, @End DATE',
        @Start = @StartDate,
        @End = @EndDate;
END;
GO

-- Test different column combinations
EXEC GetSalesReport @IncludePayment = 1;
EXEC GetSalesReport @IncludeCustomer = 1, @IncludeProduct = 0;

-- =============================================
-- Example 4: Search with IN Clause (CSV values)
-- =============================================

CREATE OR ALTER PROCEDURE SearchByCategories
    @Categories NVARCHAR(500)  -- Comma-separated: 'Electronics,Clothing,Books'
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Build IN clause from CSV
    SET @SQL = '
        SELECT 
            ProductName,
            Category,
            Price,
            StockQuantity
        FROM Products
        WHERE Category IN (SELECT value FROM STRING_SPLIT(@Cats, '',''))
        ORDER BY Category, ProductName';
    
    EXEC sp_executesql 
        @SQL,
        N'@Cats NVARCHAR(500)',
        @Cats = @Categories;
END;
GO

-- Test with multiple categories
EXEC SearchByCategories @Categories = 'Electronics,Clothing';
EXEC SearchByCategories @Categories = 'Books';

-- =============================================
-- Clean up procedures
-- =============================================
DROP PROCEDURE IF EXISTS SearchProducts;
DROP PROCEDURE IF EXISTS SearchCustomers;
DROP PROCEDURE IF EXISTS GetSalesReport;
DROP PROCEDURE IF EXISTS SearchByCategories;

-- 💡 Key Patterns:
-- - Use WHERE 1=1 to simplify adding dynamic conditions
-- - Build column list and JOINs based on requirements
-- - Use HAVING for aggregate conditions
-- - Dynamic ORDER BY for flexible sorting
-- - STRING_SPLIT for CSV parameters (SQL Server 2016+)
