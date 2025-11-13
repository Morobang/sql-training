-- ========================================
-- sp_executesql: Parameterized Dynamic SQL
-- ========================================

USE TechStore;

-- =============================================
-- Why sp_executesql vs EXEC?
-- =============================================
-- ✅ sp_executesql: Parameterized, prevents SQL injection, plan reuse
-- ❌ EXEC: String concatenation, SQL injection risk, no plan reuse

-- =============================================
-- Example 1: Basic Parameterized Query
-- =============================================

-- ❌ BAD: Using EXEC with concatenation (SQL injection risk)
DECLARE @CategoryName NVARCHAR(50) = 'Electronics';
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = 'SELECT * FROM Products WHERE Category = ''' + @CategoryName + '''';
EXEC(@SQL);

-- ✅ GOOD: Using sp_executesql with parameters (safe)
DECLARE @CategoryName2 NVARCHAR(50) = 'Electronics';
DECLARE @SQL2 NVARCHAR(MAX);

SET @SQL2 = 'SELECT ProductID, ProductName, Category, Price 
             FROM Products 
             WHERE Category = @Cat';

EXEC sp_executesql 
    @SQL2,
    N'@Cat NVARCHAR(50)',
    @Cat = @CategoryName2;

-- =============================================
-- Example 2: Multiple Parameters
-- =============================================

DECLARE @MinPrice DECIMAL(10,2) = 100.00;
DECLARE @MaxPrice DECIMAL(10,2) = 500.00;
DECLARE @CategoryFilter NVARCHAR(50) = 'Electronics';
DECLARE @DynamicSQL NVARCHAR(MAX);

SET @DynamicSQL = '
    SELECT 
        ProductName,
        Category,
        Price,
        StockQuantity
    FROM Products
    WHERE Category = @Cat
        AND Price BETWEEN @MinP AND @MaxP
    ORDER BY Price DESC';

EXEC sp_executesql 
    @DynamicSQL,
    N'@Cat NVARCHAR(50), @MinP DECIMAL(10,2), @MaxP DECIMAL(10,2)',
    @Cat = @CategoryFilter,
    @MinP = @MinPrice,
    @MaxP = @MaxPrice;

-- =============================================
-- Example 3: OUTPUT Parameters
-- =============================================

DECLARE @TotalProducts INT;
DECLARE @AvgPrice DECIMAL(10,2);
DECLARE @QuerySQL NVARCHAR(MAX);

SET @QuerySQL = '
    SELECT 
        @Total = COUNT(*),
        @Avg = AVG(Price)
    FROM Products
    WHERE Category = @Cat';

EXEC sp_executesql 
    @QuerySQL,
    N'@Cat NVARCHAR(50), @Total INT OUTPUT, @Avg DECIMAL(10,2) OUTPUT',
    @Cat = 'Electronics',
    @Total = @TotalProducts OUTPUT,
    @Avg = @AvgPrice OUTPUT;

SELECT 
    @TotalProducts AS TotalProducts,
    @AvgPrice AS AveragePrice;

-- =============================================
-- Example 4: Dynamic Search with NULL Handling
-- =============================================

DECLARE @SearchName NVARCHAR(100) = NULL;  -- NULL means "show all"
DECLARE @SearchCategory NVARCHAR(50) = 'Clothing';
DECLARE @SearchSQL NVARCHAR(MAX);

SET @SearchSQL = '
    SELECT 
        ProductID,
        ProductName,
        Category,
        Price
    FROM Products
    WHERE (@Name IS NULL OR ProductName LIKE ''%'' + @Name + ''%'')
        AND (@Cat IS NULL OR Category = @Cat)
    ORDER BY ProductName';

EXEC sp_executesql 
    @SearchSQL,
    N'@Name NVARCHAR(100), @Cat NVARCHAR(50)',
    @Name = @SearchName,
    @Cat = @SearchCategory;

-- =============================================
-- Example 5: Building Complex Filters
-- =============================================

DECLARE @FilterSQL NVARCHAR(MAX);
DECLARE @State NVARCHAR(50) = 'CA';
DECLARE @MinPurchases INT = 3;

SET @FilterSQL = '
    SELECT 
        c.CustomerName,
        c.State,
        COUNT(s.SaleID) AS TotalOrders,
        SUM(s.TotalAmount) AS TotalSpent
    FROM Customers c
    LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
    WHERE c.State = @StateParam
    GROUP BY c.CustomerName, c.State
    HAVING COUNT(s.SaleID) >= @MinOrders
    ORDER BY TotalSpent DESC';

EXEC sp_executesql 
    @FilterSQL,
    N'@StateParam NVARCHAR(50), @MinOrders INT',
    @StateParam = @State,
    @MinOrders = @MinPurchases;

-- =============================================
-- Example 6: Performance Comparison
-- =============================================

-- This demonstrates plan reuse with sp_executesql

-- First execution (creates plan)
DECLARE @Cat1 NVARCHAR(50) = 'Electronics';
DECLARE @PlanSQL NVARCHAR(MAX) = 'SELECT COUNT(*) AS Total FROM Products WHERE Category = @C';

EXEC sp_executesql @PlanSQL, N'@C NVARCHAR(50)', @C = @Cat1;

-- Second execution (reuses plan - faster!)
DECLARE @Cat2 NVARCHAR(50) = 'Clothing';
EXEC sp_executesql @PlanSQL, N'@C NVARCHAR(50)', @C = @Cat2;

-- Compare with EXEC (creates NEW plan each time)
EXEC('SELECT COUNT(*) FROM Products WHERE Category = ''Electronics''');
EXEC('SELECT COUNT(*) FROM Products WHERE Category = ''Clothing''');

-- 💡 Key Takeaways:
-- - Always use sp_executesql for dynamic SQL with user input
-- - Parameters prevent SQL injection attacks
-- - Query plan reuse improves performance
-- - OUTPUT parameters allow returning values
-- - Handle NULL parameters for optional filters
